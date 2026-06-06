from django import forms
from .models import Relationship, Event, ConflictEntry


class RelationshipForm(forms.ModelForm):
    class Meta:
        model = Relationship
        fields = ['relationship_type']


class EventForm(forms.ModelForm):
    class Meta:
        model = Event
        fields = ['event_type', 'title', 'date', 'notes', 'is_recurring']
        widgets = {'date': forms.DateInput(attrs={'type': 'date'})}


class ConflictForm(forms.ModelForm):
    class Meta:
        model = ConflictEntry
        fields = ['category', 'description', 'severity']
