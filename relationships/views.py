from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import get_object_or_404, redirect
from django.views import View
from django.views.generic import FormView, DetailView, ListView

from .forms import RelationshipForm, EventForm, ConflictForm
from .models import Relationship, Event, ConflictEntry
from . import services


class RelationshipListView(LoginRequiredMixin, ListView):
    template_name = 'relationships/list.jinja'
    context_object_name = 'relationships'

    def get_queryset(self):
        return services.get_user_relationships(self.request.user)


class RelationshipCreateView(LoginRequiredMixin, FormView):
    template_name = 'relationships/create.jinja'
    form_class = RelationshipForm

    def form_valid(self, form):
        rel = services.create_relationship(
            user=self.request.user,
            relationship_type=form.cleaned_data['relationship_type'],
        )
        return redirect('relationships:invite', pk=rel.pk)

    def form_invalid(self, form):
        return self.render_to_response(self.get_context_data(form=form))


class RelationshipInviteView(LoginRequiredMixin, DetailView):
    template_name = 'relationships/invite.jinja'
    context_object_name = 'relationship'

    def get_queryset(self):
        return Relationship.objects.filter(creator=self.request.user)


class AcceptInviteView(View):
    def get(self, request, token):
        rel = get_object_or_404(Relationship, invite_token=token, status=Relationship.STATUS_PENDING)
        if request.user.is_authenticated:
            if rel.creator == request.user:
                return redirect('dashboard:home')
            services.accept_invite(rel, request.user)
            return redirect('relationships:detail', pk=rel.pk)
        return redirect(f'/auth/login/?next=/relationships/accept/{token}/')


class DeclineInviteView(LoginRequiredMixin, View):
    def post(self, request, token):
        rel = get_object_or_404(Relationship, invite_token=token, partner=request.user)
        services.decline_invite(rel)
        return redirect('dashboard:home')


class RelationshipDetailView(LoginRequiredMixin, View):
    template_name = 'relationships/detail.jinja'

    def get(self, request, pk):
        rel = get_object_or_404(
            Relationship,
            pk=pk,
            status=Relationship.STATUS_ACTIVE,
        )
        if rel.creator != request.user and rel.partner != request.user:
            return redirect('dashboard:home')

        health = services.calculate_health_score(rel)
        patterns = services.get_conflict_patterns(rel)
        upcoming = services.get_upcoming_events(rel)
        conflicts = ConflictEntry.objects.filter(relationship=rel).order_by('-created_at')[:10]
        event_form = EventForm()
        conflict_form = ConflictForm()

        from django.shortcuts import render
        return render(request, self.template_name, {
            'relationship': rel,
            'other_user': rel.get_other_user(request.user),
            'health': health,
            'patterns': patterns,
            'upcoming_events': upcoming,
            'conflicts': conflicts,
            'event_form': event_form,
            'conflict_form': conflict_form,
        })


class AddEventView(LoginRequiredMixin, View):
    def post(self, request, pk):
        rel = get_object_or_404(Relationship, pk=pk)
        form = EventForm(request.POST)
        if form.is_valid():
            event = form.save(commit=False)
            event.relationship = rel
            event.created_by = request.user
            event.save()
        return redirect('relationships:detail', pk=pk)


class AddConflictView(LoginRequiredMixin, View):
    def post(self, request, pk):
        rel = get_object_or_404(Relationship, pk=pk)
        form = ConflictForm(request.POST)
        if form.is_valid():
            conflict = form.save(commit=False)
            conflict.relationship = rel
            conflict.logged_by = request.user
            conflict.save()
        return redirect('relationships:detail', pk=pk)


class ResolveConflictView(LoginRequiredMixin, View):
    def post(self, request, pk):
        conflict = get_object_or_404(ConflictEntry, pk=pk)
        conflict.resolved = True
        conflict.resolution_note = request.POST.get('resolution_note', '')
        conflict.save()
        return redirect('relationships:detail', pk=conflict.relationship.pk)
