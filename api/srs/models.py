from django.conf import settings
from django.db import models
from django.utils import timezone


class Review(models.Model):
    """
    Per-(user, card) FSRS scheduling state.

    The FSRS algorithm itself has only three states (Learning/Review/
    Relearning); we add ``NEW`` for a card the user has never graded. ``reps``
    and ``lapses`` are tracked here because py-fsrs does not keep them on its
    Card object. ``step`` and ``card_uid`` let us round-trip a py-fsrs Card.
    """

    class State(models.IntegerChoices):
        NEW = 0, "New"
        LEARNING = 1, "Learning"
        REVIEW = 2, "Review"
        RELEARNING = 3, "Relearning"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reviews"
    )
    card = models.ForeignKey(
        "catalog.Card", on_delete=models.CASCADE, related_name="reviews"
    )

    due = models.DateTimeField(default=timezone.now)
    stability = models.FloatField(null=True, blank=True)
    difficulty = models.FloatField(null=True, blank=True)
    state = models.IntegerField(choices=State.choices, default=State.NEW)
    step = models.IntegerField(null=True, blank=True)
    reps = models.PositiveIntegerField(default=0)
    lapses = models.PositiveIntegerField(default=0)
    last_review = models.DateTimeField(null=True, blank=True)

    # py-fsrs Card.card_id; stable per Review so logs/cards round-trip.
    card_uid = models.BigIntegerField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("user", "card")
        indexes = [models.Index(fields=["user", "due"])]

    def __str__(self):
        return f"{self.user} · {self.card} ({self.get_state_display()})"


class ReviewLog(models.Model):
    """Immutable record of a single grading event."""

    review = models.ForeignKey(
        Review, on_delete=models.CASCADE, related_name="logs"
    )
    rating = models.PositiveSmallIntegerField()  # 1=Again .. 4=Easy
    reviewed_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ("-reviewed_at",)

    def __str__(self):
        return f"{self.review_id} rated {self.rating} @ {self.reviewed_at:%Y-%m-%d %H:%M}"
