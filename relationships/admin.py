from django.contrib import admin
from .models import Relationship, Event, ConflictEntry


@admin.register(Relationship)
class RelationshipAdmin(admin.ModelAdmin):
    list_display = ('creator', 'partner', 'relationship_type', 'status', 'created_at')
    list_filter = ('relationship_type', 'status')


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ('title', 'event_type', 'date', 'relationship')
    list_filter = ('event_type',)


@admin.register(ConflictEntry)
class ConflictAdmin(admin.ModelAdmin):
    list_display = ('relationship', 'category', 'severity', 'resolved', 'created_at')
    list_filter = ('category', 'resolved')
