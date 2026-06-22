from django.contrib.auth import get_user_model
from django.test.utils import CaptureQueriesContext
from django.db import connection
from rest_framework.test import APITestCase

from .models import Card, Deck, Language

User = get_user_model()


class CatalogTestBase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="u@e.com", password="pw1234567")
        self.admin = User.objects.create_superuser(email="admin@e.com", password="pw1234567")
        self.lang = Language.objects.create(code="en", name="English")
        self.a1 = Deck.objects.create(language=self.lang, name="A1", slug="a1", order=0)
        self.a1_nouns = Deck.objects.create(
            language=self.lang, parent=self.a1, name="Nouns", slug="nouns", order=0
        )
        for i in range(3):
            Card.objects.create(deck=self.a1, front=f"w{i}", back=f"t{i}", order=i)
        Card.objects.create(deck=self.a1_nouns, front="cat", back="кот", order=0)


class DeckTreeTests(CatalogTestBase):
    url = "/api/v1/decks/tree"

    def test_requires_auth(self):
        self.assertEqual(self.client.get(self.url).status_code, 401)

    def test_returns_nested_tree_with_counts(self):
        self.client.force_authenticate(self.user)
        body = self.client.get(self.url).json()
        self.assertTrue(body["success"])
        roots = body["data"]
        self.assertEqual(len(roots), 1)
        self.assertEqual(roots[0]["name"], "A1")
        self.assertEqual(roots[0]["card_count"], 3)
        self.assertEqual(roots[0]["children"][0]["name"], "Nouns")
        self.assertEqual(roots[0]["children"][0]["card_count"], 1)

    def test_tree_has_no_n_plus_one(self):
        self.client.force_authenticate(self.user)
        with CaptureQueriesContext(connection) as ctx:
            self.client.get(self.url)
        baseline = len(ctx.captured_queries)
        # Adding more decks must not increase the query count.
        for i in range(5):
            Deck.objects.create(language=self.lang, name=f"D{i}", slug=f"d{i}", order=i + 1)
        with CaptureQueriesContext(connection) as ctx2:
            self.client.get(self.url)
        self.assertEqual(len(ctx2.captured_queries), baseline)


class CardListTests(CatalogTestBase):
    def test_list_is_paginated(self):
        for i in range(25):
            Card.objects.create(deck=self.a1, front=f"x{i}", back=f"y{i}", order=100 + i)
        self.client.force_authenticate(self.user)
        body = self.client.get("/api/v1/cards").json()
        self.assertTrue(body["success"])
        self.assertEqual(len(body["data"]["results"]), 20)  # PAGE_SIZE
        self.assertEqual(body["data"]["count"], Card.objects.count())

    def test_filter_by_deck(self):
        self.client.force_authenticate(self.user)
        body = self.client.get(f"/api/v1/cards?deck={self.a1_nouns.id}").json()
        self.assertEqual(body["data"]["count"], 1)


class DeckOwnershipTests(CatalogTestBase):
    def test_create_deck_sets_owner(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/decks", {"language": self.lang.id, "name": "My English"}, format="json"
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()["data"]
        self.assertEqual(data["owner"], self.user.id)
        self.assertTrue(data["slug"])
        mine = self.client.get("/api/v1/decks?owner=me").json()["data"]["results"]
        self.assertEqual([d["name"] for d in mine], ["My English"])

    def test_cannot_edit_shared_deck(self):
        self.client.force_authenticate(self.user)
        res = self.client.patch(
            f"/api/v1/decks/{self.a1.id}", {"name": "Hacked"}, format="json"
        )
        self.assertEqual(res.status_code, 403)

    def test_cannot_touch_other_users_deck(self):
        other = User.objects.create_user(email="other@e.com", password="pw1234567")
        d = Deck.objects.create(language=self.lang, owner=other, name="Theirs", slug="theirs")
        self.client.force_authenticate(self.user)
        ids = [x["id"] for x in self.client.get("/api/v1/decks?owner=me").json()["data"]["results"]]
        self.assertNotIn(d.id, ids)
        self.assertEqual(self.client.patch(f"/api/v1/decks/{d.id}", {"name": "x"}, format="json").status_code, 404)
        self.assertEqual(self.client.delete(f"/api/v1/decks/{d.id}").status_code, 404)

    def test_owner_can_rename_and_delete(self):
        self.client.force_authenticate(self.user)
        d = Deck.objects.create(language=self.lang, owner=self.user, name="Mine", slug="mine")
        self.assertEqual(
            self.client.patch(f"/api/v1/decks/{d.id}", {"name": "Renamed"}, format="json").status_code,
            200,
        )
        self.assertEqual(self.client.delete(f"/api/v1/decks/{d.id}").status_code, 204)


class CardOwnershipTests(CatalogTestBase):
    def setUp(self):
        super().setUp()
        self.my_deck = Deck.objects.create(
            language=self.lang, owner=self.user, name="Mine", slug="mine"
        )

    def test_create_card_in_own_deck(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/cards", {"deck": self.my_deck.id, "front": "dog", "back": "it"}, format="json"
        )
        self.assertEqual(res.status_code, 201)

    def test_cannot_add_card_to_shared_deck(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/cards", {"deck": self.a1.id, "front": "x", "back": "y"}, format="json"
        )
        self.assertEqual(res.status_code, 400)

    def test_cannot_touch_other_users_card(self):
        other = User.objects.create_user(email="o2@e.com", password="pw1234567")
        od = Deck.objects.create(language=self.lang, owner=other, name="od", slug="od")
        oc = Card.objects.create(deck=od, front="x", back="y")
        self.client.force_authenticate(self.user)
        self.assertEqual(
            self.client.patch(f"/api/v1/cards/{oc.id}", {"front": "z"}, format="json").status_code, 404
        )
        self.assertEqual(self.client.delete(f"/api/v1/cards/{oc.id}").status_code, 404)
