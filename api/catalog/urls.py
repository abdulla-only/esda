from rest_framework.routers import DefaultRouter

from .views import CardViewSet, DeckViewSet, LanguageViewSet

# trailing_slash=False keeps catalog endpoints consistent with the auth/study
# endpoints (which are plain paths without a trailing slash).
router = DefaultRouter(trailing_slash=False)
router.register("languages", LanguageViewSet, basename="language")
router.register("decks", DeckViewSet, basename="deck")
router.register("cards", CardViewSet, basename="card")

urlpatterns = router.urls
