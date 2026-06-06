from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.views import View

from relationships.models import Relationship
from .forms import MoodForm, ConnectionScoreForm
from . import services


class MoodCheckInView(LoginRequiredMixin, View):
    def post(self, request, rel_pk):
        rel = get_object_or_404(Relationship, pk=rel_pk)
        form = MoodForm(request.POST)
        if form.is_valid():
            services.log_mood(
                user=request.user,
                relationship=rel,
                mood=form.cleaned_data['mood'],
                note=form.cleaned_data.get('note', ''),
            )
        # HTMX partial response
        checked_in = services.checked_in_today(request.user, rel)
        return HttpResponse(
            f'<div class="text-green-600 text-sm font-medium py-2">✓ Mood logged for today</div>'
            if checked_in else
            f'<div class="text-red-500 text-sm">Failed — try again</div>'
        )


class ConnectionScoreView(LoginRequiredMixin, View):
    def post(self, request, rel_pk):
        rel = get_object_or_404(Relationship, pk=rel_pk)
        form = ConnectionScoreForm(request.POST)
        if form.is_valid():
            services.log_connection_score(
                user=request.user,
                relationship=rel,
                score=form.cleaned_data['score'],
            )
        return HttpResponse(
            '<div class="text-green-600 text-sm font-medium py-2">✓ Connection score saved</div>'
        )
