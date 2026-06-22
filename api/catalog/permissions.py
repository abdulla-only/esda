from rest_framework.permissions import SAFE_METHODS, BasePermission


class IsDeckOwnerOrReadOnly(BasePermission):
    """Read shared/own decks; write only your own (owner NULL = shared/read-only)."""

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.owner_id == request.user.id


class IsCardDeckOwnerOrReadOnly(BasePermission):
    """Write a card only if you own its deck."""

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.deck.owner_id == request.user.id
