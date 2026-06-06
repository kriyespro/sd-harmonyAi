from django import forms
from .models import MoodEntry, ConnectionScore


class MoodForm(forms.ModelForm):
    class Meta:
        model = MoodEntry
        fields = ['mood', 'note']
        widgets = {'note': forms.Textarea(attrs={'rows': 2})}


class ConnectionScoreForm(forms.ModelForm):
    class Meta:
        model = ConnectionScore
        fields = ['score']
