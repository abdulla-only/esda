from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from catalog.models import Card, Deck, Language

from .models import Review, ReviewLog
from .services import get_study_queue, grade_review

User = get_user_model()


class SrsTestBase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="s@e.com", password="pw1234567")
        self.lang = Language.objects.create(code="en", name="English")
        self.deck = Deck.objects.create(
            language=self.lang, owner=self.user, name="A1", slug="a1"
        )
        self.cards = [
            Card.objects.create(deck=self.deck, front=f"w{i}", back=f"t{i}", order=i)
            for i in range(5)
        ]


class GradeServiceTests(SrsTestBase):
    def test_first_grade_transitions_from_new(self):
        review = Review.objects.create(user=self.user, card=self.cards[0])
        self.assertEqual(review.state, Review.State.NEW)
        grade_review(review, 3)  # Good
        review.refresh_from_db()
        self.assertNotEqual(review.state, Review.State.NEW)
        self.assertEqual(review.reps, 1)
        self.assertEqual(review.lapses, 0)
        self.assertEqual(ReviewLog.objects.filter(review=review).count(), 1)

    def test_again_records_a_lapse(self):
        review = Review.objects.create(user=self.user, card=self.cards[0])
        grade_review(review, 3)
        grade_review(review, 1)  # Again -> lapse
        review.refresh_from_db()
        self.assertEqual(review.reps, 2)
        self.assertEqual(review.lapses, 1)

    def test_invalid_rating_raises(self):
        review = Review.objects.create(user=self.user, card=self.cards[0])
        with self.assertRaises(ValueError):
            grade_review(review, 5)


class StudyQueueServiceTests(SrsTestBase):
    def test_new_cards_capped_by_daily_limit(self):
        queue = get_study_queue(self.user, new_limit=2)
        self.assertEqual(len(queue["new_cards"]), 2)
        self.assertEqual(len(queue["due_cards"]), 0)

    def test_graded_card_not_returned_as_new(self):
        review = Review.objects.create(user=self.user, card=self.cards[0])
        grade_review(review, 4)  # Easy -> due in the future
        queue = get_study_queue(self.user, new_limit=10)
        new_ids = {c.id for c in queue["new_cards"]}
        self.assertNotIn(self.cards[0].id, new_ids)


class StudyEndpointTests(SrsTestBase):
    def test_queue_requires_auth(self):
        self.assertEqual(self.client.get("/api/v1/study/queue").status_code, 401)

    def test_queue_returns_enveloped_results(self):
        self.client.force_authenticate(self.user)
        body = self.client.get("/api/v1/study/queue?limit=3").json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["count"], len(body["data"]["results"]))

    def test_grade_endpoint(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/study/grade", {"card": self.cards[0].id, "rating": 3}, format="json"
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["data"]["reps"], 1)

    def test_grade_invalid_rating_is_validation_error(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/study/grade", {"card": self.cards[0].id, "rating": 9}, format="json"
        )
        self.assertEqual(res.status_code, 400)
        body = res.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["error"]["code"], "validation_error")

    def test_grade_unknown_card_is_404(self):
        self.client.force_authenticate(self.user)
        res = self.client.post(
            "/api/v1/study/grade", {"card": 999999, "rating": 3}, format="json"
        )
        self.assertEqual(res.status_code, 404)
        self.assertEqual(res.json()["error"]["code"], "not_found")
