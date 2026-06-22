"""
FSRS grading service.

Bridges our :class:`~srs.models.Review` rows and the py-fsrs scheduler. A
Review stores the scheduling state in plain columns; here we hydrate a
``fsrs.Card`` from those columns, grade it, and write the result back.
"""
from __future__ import annotations

from datetime import datetime, timezone

from django.conf import settings
from django.db import transaction
from django.utils import timezone as dj_timezone
from fsrs import Card, Rating, Scheduler

from catalog.models import Card as CatalogCard

from .models import Review, ReviewLog

MAX_QUEUE_LIMIT = 100

# One shared scheduler with default (well-tuned) parameters.
_scheduler = Scheduler()

# Map our integer rating (1..4) to the FSRS Rating enum.
_RATING = {
    1: Rating.Again,
    2: Rating.Hard,
    3: Rating.Good,
    4: Rating.Easy,
}


def _card_from_review(review: Review) -> Card:
    """Build an fsrs.Card from a Review, or a fresh one if never reviewed."""
    if review.state == Review.State.NEW or review.card_uid is None:
        return Card()
    return Card.from_dict(
        {
            "card_id": review.card_uid,
            "state": int(review.state),
            "step": review.step,
            "stability": review.stability,
            "difficulty": review.difficulty,
            "due": review.due.astimezone(timezone.utc).isoformat(),
            "last_review": (
                review.last_review.astimezone(timezone.utc).isoformat()
                if review.last_review
                else None
            ),
        }
    )


@transaction.atomic
def grade_review(review: Review, rating: int) -> Review:
    """
    Apply ``rating`` (1=Again .. 4=Easy) to ``review`` using FSRS, persist the
    updated schedule, and append a ReviewLog. Returns the saved Review.
    """
    if rating not in _RATING:
        raise ValueError(f"rating must be 1..4, got {rating!r}")

    now = datetime.now(timezone.utc)
    card = _card_from_review(review)
    card, _log = _scheduler.review_card(card, _RATING[rating], review_datetime=now)

    review.card_uid = card.card_id
    review.due = card.due
    review.stability = card.stability
    review.difficulty = card.difficulty
    review.state = int(card.state)
    review.step = card.step
    review.last_review = card.last_review or now
    review.reps += 1
    if rating == 1:  # Again => a lapse
        review.lapses += 1
    review.save()

    ReviewLog.objects.create(review=review, rating=rating, reviewed_at=now)
    return review


def get_study_queue(
    user,
    deck_id: int | None = None,
    limit: int = 50,
    new_limit: int | None = None,
) -> dict:
    """Due cards (existing reviews past due) followed by new cards.

    New cards are capped by the remaining daily allowance (DAILY_NEW_LIMIT minus
    reviews already created today). Returns due/new card lists, each card
    carrying its `_user_review` (or None) for the serializer to shape.
    """
    now = dj_timezone.now()
    limit = max(1, min(limit, MAX_QUEUE_LIMIT))
    daily_new_limit = settings.DAILY_NEW_LIMIT if new_limit is None else new_limit

    due_reviews = (
        Review.objects.filter(user=user, due__lte=now)
        .exclude(state=Review.State.NEW)
        .select_related("card")
        .order_by("due")
    )
    if deck_id:
        due_reviews = due_reviews.filter(card__deck_id=deck_id)
    due_reviews = list(due_reviews[:limit])

    due_cards = []
    for review in due_reviews:
        review.card._user_review = review
        due_cards.append(review.card)

    introduced_today = Review.objects.filter(
        user=user, created_at__date=now.date()
    ).count()
    remaining_new = max(0, daily_new_limit - introduced_today)
    new_take = min(remaining_new, max(0, limit - len(due_cards)))

    new_cards = []
    if new_take:
        # Only the user's own cards (no shared catalog).
        new_qs = (
            CatalogCard.objects.filter(deck__owner=user)
            .exclude(reviews__user=user)
            .order_by("deck", "order")
        )
        if deck_id:
            new_qs = new_qs.filter(deck_id=deck_id)
        new_cards = list(new_qs[:new_take])

    return {"due_cards": due_cards, "new_cards": new_cards}
