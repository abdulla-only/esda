from django.contrib import admin

from .models import Review, ReviewLog


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ("user", "card", "state", "due", "reps", "lapses")
    list_filter = ("state",)
    search_fields = ("user__email", "card__front", "card__back")
    autocomplete_fields = ("user", "card")
    readonly_fields = ("created_at", "updated_at")


@admin.register(ReviewLog)
class ReviewLogAdmin(admin.ModelAdmin):
    list_display = ("review", "rating", "reviewed_at")
    list_filter = ("rating",)
