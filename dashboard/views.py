from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import redirect
from django.views.generic import TemplateView

from relationships.models import Relationship
from moods.models import MoodEntry, ConnectionScore


class HomeView(LoginRequiredMixin, TemplateView):
    template_name = 'pages/dashboard.jinja'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        user = self.request.user
        relationships = Relationship.objects.filter(
            creator=user, status=Relationship.STATUS_ACTIVE
        ) | Relationship.objects.filter(
            partner=user, status=Relationship.STATUS_ACTIVE
        )
        ctx['relationships'] = relationships.order_by('-updated_at')
        ctx['pending_invites'] = Relationship.objects.filter(
            partner=user, status=Relationship.STATUS_PENDING
        )
        ctx['mood_today'] = MoodEntry.objects.filter(
            user=user
        ).select_related('relationship').order_by('-created_at')[:5]
        return ctx


class LandingView(TemplateView):
    template_name = 'pages/landing.jinja'

    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            return redirect('dashboard:home')
        return super().dispatch(request, *args, **kwargs)
