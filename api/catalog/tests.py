from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from .models import Card, Deck, Language

User = get_user_model()


class CatalogTestBase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="u@e.com", password="pw1234567")
        self.other = User.objects.create_user(email="other@e.com", password="pw1234567")
        self.lang = Language.objects.create(code="en", name="English")
        # The user's own deck + cards.
        self.deck = Deck.objects.create(
            language=self.lang, owner=self.user, name="A1", slug="a1"
        )
        for i in range(3):
            Card.objects.create(deck=self.deck, front=f"w{i}", back=f"t{i}", order=i)


class CardListTests(CatalogTestBase):
    def test_list_is_paginated(self):
        for i in range(25):
            Card.objects.create(deck=self.deck, front=f"x{i}", back=f"y{i}", order=100 + i)
        self.client.force_authenticate(self.user)
        body = self.client.get("/api/v1/cards").json()
        self.assertTrue(body["success"])
        self.assertEqual(len(body["data"]["results"]), 20)  # PAGE_SIZE
        self.assertEqual(body["data"]["count"], Card.objects.filter(deck__owner=self.user).count())

    def test_filter_by_deck(self):
        self.client.force_authenticate(self.user)
        body = self.client.get(f"/api/v1/cards?deck={self.deck.id}").json()
        self.assertEqual(body["data"]["count"], 3)

    def test_only_own_cards_visible(self):
        od = Deck.objects.create(language=self.lang, owner=self.other, name="od", slug="od")
        Card.objects.create(deck=od, front="secret", back="x")
        self.client.force_authenticate(self.user)
        fronts = [c["front"] for c in self.client.get("/api/v1/cards").json()["data"]["results"]]
        self.assertNotIn("secret", fronts)


class DeckCrudTests(CatalogTestBase):
    def test_list_requires_auth(self):
        self.assertEqual(self.client.get("/api/v1/decks").status_code, 401)

    def test_create_deck_sets_owner(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/decks", {"language": self.lang.id, "name": "My English"}, format="json"
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()["data"]
        self.assertEqual(data["owner"], self.user.id)
        self.assertTrue(data["slug"])

    def test_list_shows_only_own_decks(self):
        Deck.objects.create(language=self.lang, owner=self.other, name="Theirs", slug="theirs")
        self.client.force_authenticate(self.user)
        names = [d["name"] for d in self.client.get("/api/v1/decks").json()["data"]["results"]]
        self.assertIn("A1", names)
        self.assertNotIn("Theirs", names)

    def test_owner_can_rename_and_delete(self):
        self.client.force_authenticate(self.user)
        d = Deck.objects.create(language=self.lang, owner=self.user, name="Mine", slug="mine")
        self.assertEqual(
            self.client.patch(f"/api/v1/decks/{d.id}", {"name": "Renamed"}, format="json").status_code,
            200,
        )
        self.assertEqual(self.client.delete(f"/api/v1/decks/{d.id}").status_code, 204)

    def test_cannot_touch_other_users_deck(self):
        d = Deck.objects.create(language=self.lang, owner=self.other, name="Theirs", slug="theirs")
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.patch(f"/api/v1/decks/{d.id}", {"name": "x"}, format="json").status_code, 404)
        self.assertEqual(self.client.delete(f"/api/v1/decks/{d.id}").status_code, 404)


class CardCrudTests(CatalogTestBase):
    def test_create_card_in_own_deck(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/cards", {"deck": self.deck.id, "front": "dog", "back": "it"}, format="json"
        )
        self.assertEqual(res.status_code, 201)

    def test_cannot_add_card_to_other_users_deck(self):
        od = Deck.objects.create(language=self.lang, owner=self.other, name="od", slug="od")
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/cards", {"deck": od.id, "front": "x", "back": "y"}, format="json"
        )
        self.assertEqual(res.status_code, 400)

    def test_cannot_touch_other_users_card(self):
        od = Deck.objects.create(language=self.lang, owner=self.other, name="od", slug="od")
        oc = Card.objects.create(deck=od, front="x", back="y")
        self.client.force_authenticate(self.user)
        self.assertEqual(
            self.client.patch(f"/api/v1/cards/{oc.id}", {"front": "z"}, format="json").status_code, 404
        )
        self.assertEqual(self.client.delete(f"/api/v1/cards/{oc.id}").status_code, 404)
