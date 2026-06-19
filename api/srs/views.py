from django.db import connection
from django.utils import timezone
from rest_framework import status
from rest_framework.exceptions import NotFound
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from catalog.models import Card

from .models import Review
from .serializers import GradeSerializer, ReviewSerializer, StudyCardSerializer
from .services import get_study_queue, grade_review


class HealthView(APIView):
    """GET /health — liveness + DB connectivity check."""

    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "health"

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        except Exception:
            return Response(
                {
                    "success": False,
                    "error": {"code": "service_unavailable", "message": "Database unavailable"},
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response({"status": "ok", "database": True})


class StudyQueueView(APIView):
    """GET /study/queue — due cards then new cards (?deck= &limit= &new_limit=)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        deck_id = request.query_params.get("deck")
        limit = int(request.query_params.get("limit", 50))
        new_limit = request.query_params.get("new_limit")
        queue = get_study_queue(
            request.user,
            deck_id=int(deck_id) if deck_id else None,
            limit=limit,
            new_limit=int(new_limit) if new_limit is not None else None,
        )
        cards = queue["due_cards"] + queue["new_cards"]
        return Response(
            {
                "count": len(cards),
                "due_count": len(queue["due_cards"]),
                "new_count": len(queue["new_cards"]),
                "results": StudyCardSerializer(cards, many=True).data,
            }
        )


class GradeView(APIView):
    """POST /study/grade — grade a card with FSRS ({card, rating 1..4})."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = GradeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            card = Card.objects.get(pk=serializer.validated_data["card"])
        except Card.DoesNotExist as exc:
            raise NotFound("Card not found") from exc

        review, _created = Review.objects.get_or_create(
            user=request.user,
            card=card,
            defaults={"due": timezone.now(), "state": Review.State.NEW},
        )
        review = grade_review(review, serializer.validated_data["rating"])
        return Response(ReviewSerializer(review).data)
