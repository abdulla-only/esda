from django.contrib import admin

from .models import Card, Deck, Language


@admin.register(Language)
class LanguageAdmin(admin.ModelAdmin):
    list_display = ("code", "name")
    search_fields = ("code", "name")


class CardInline(admin.TabularInline):
    model = Card
    extra = 1
    fields = ("order", "front", "back", "part_of_speech")
    ordering = ("order",)


@admin.register(Deck)
class DeckAdmin(admin.ModelAdmin):
    list_display = ("name", "language", "owner", "parent", "slug", "order")
    list_filter = ("language", "owner")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}
    autocomplete_fields = ("parent", "owner")
    inlines = [CardInline]


@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ("front", "back", "deck", "part_of_speech", "order")
    list_filter = ("deck__language", "part_of_speech", "deck")
    search_fields = ("front", "back", "description", "example")
    autocomplete_fields = ("deck",)
