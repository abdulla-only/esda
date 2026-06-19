from rest_framework import serializers

from catalog.models import Card

from .models import Review, ReviewLog


class StudyCardSerializer(serializers.ModelSerializer):
    """A card plus this user's scheduling state, as returned by the study queue."""

    review = serializers.SerializerMethodField()

    class Meta:
        model = Card
        fields = (
            "id",
            "deck",
            "front",
            "back",
            "description",
            "example",
            "part_of_speech",
            "review",
        )

    def get_review(self, card):
        review = getattr(card, "_user_review", None)
        if review is None:
            return {"is_new": True, "state": Review.State.NEW, "due": None}
        return {
            "is_new": review.state == Review.State.NEW,
            "state": review.state,
            "due": review.due,
            "reps": review.reps,
            "lapses": review.lapses,
        }


class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = (
            "id",
            "card",
            "due",
            "stability",
            "difficulty",
            "state",
            "step",
            "reps",
            "lapses",
            "last_review",
        )
        read_only_fields = fields


class GradeSerializer(serializers.Serializer):
    card = serializers.IntegerField()
    rating = serializers.IntegerField(min_value=1, max_value=4)


class ReviewLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewLog
        fields = ("id", "review", "rating", "reviewed_at")
