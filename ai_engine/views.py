import json
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import get_object_or_404, render
from django.http import HttpResponse
from django.views import View
from django.db.models import Q

from relationships.models import Relationship, ConflictEntry
from .models import AIInsight, ChatMessage
from . import services


def _get_relationship_or_403(user, rel_pk):
    return get_object_or_404(
        Relationship,
        Q(creator=user) | Q(partner=user),
        pk=rel_pk,
        status=Relationship.STATUS_ACTIVE,
    )


class ConflictAnalyzeView(LoginRequiredMixin, View):
    def get(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        conflicts = ConflictEntry.objects.filter(relationship=rel, resolved=False).order_by('-created_at')
        past_analyses = AIInsight.objects.filter(
            relationship=rel, insight_type=AIInsight.TYPE_CONFLICT
        )[:5]
        return render(request, 'ai_engine/analyze.jinja', {
            'relationship': rel,
            'conflicts': conflicts,
            'past_analyses': past_analyses,
        })

    def post(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        conflict_id = request.POST.get('conflict_id')
        conflict = get_object_or_404(ConflictEntry, pk=conflict_id, relationship=rel)

        result = services.analyze_conflict(conflict)

        AIInsight.objects.create(
            relationship=rel,
            requested_by=request.user,
            insight_type=AIInsight.TYPE_CONFLICT,
            input_summary=f'{conflict.category}: {conflict.description[:200]}',
            content=json.dumps(result),
        )

        return render(request, 'ai_engine/partials/_analysis_result.jinja', {
            'result': result,
            'conflict': conflict,
        })


class PatternDetectView(LoginRequiredMixin, View):
    def post(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        result = services.detect_patterns(rel, request.user)

        AIInsight.objects.create(
            relationship=rel,
            requested_by=request.user,
            insight_type=AIInsight.TYPE_PATTERN,
            content=json.dumps(result),
        )

        return render(request, 'ai_engine/partials/_pattern_result.jinja', {
            'result': result,
            'relationship': rel,
        })


class WeeklyReportView(LoginRequiredMixin, View):
    def get(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        last_report = AIInsight.objects.filter(
            relationship=rel, insight_type=AIInsight.TYPE_WEEKLY
        ).first()
        report_data = json.loads(last_report.content) if last_report else None
        return render(request, 'ai_engine/report.jinja', {
            'relationship': rel,
            'report': report_data,
            'generated_at': last_report.created_at if last_report else None,
        })

    def post(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        result = services.generate_weekly_report(rel, request.user)

        AIInsight.objects.create(
            relationship=rel,
            requested_by=request.user,
            insight_type=AIInsight.TYPE_WEEKLY,
            content=json.dumps(result),
        )

        return render(request, 'ai_engine/partials/_weekly_report.jinja', {
            'report': result,
            'relationship': rel,
        })


class CoachChatView(LoginRequiredMixin, View):
    def get(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        history = ChatMessage.objects.filter(relationship=rel, user=request.user)
        return render(request, 'ai_engine/coach.jinja', {
            'relationship': rel,
            'history': history,
        })

    def post(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        message = request.POST.get('message', '').strip()
        if not message:
            return HttpResponse('')

        ChatMessage.objects.create(
            relationship=rel, user=request.user,
            role=ChatMessage.ROLE_USER, content=message,
        )

        history_qs = ChatMessage.objects.filter(relationship=rel, user=request.user).order_by('-created_at')[:16]
        history = [{'role': m.role, 'content': m.content} for m in reversed(list(history_qs))]

        reply = services.chat_with_coach(rel, request.user, message, history=history[:-1])

        ChatMessage.objects.create(
            relationship=rel, user=request.user,
            role=ChatMessage.ROLE_ASSISTANT, content=reply,
        )

        return render(request, 'ai_engine/partials/_chat_messages.jinja', {
            'user_message': message,
            'assistant_reply': reply,
        })

    def delete(self, request, rel_pk):
        rel = _get_relationship_or_403(request.user, rel_pk)
        ChatMessage.objects.filter(relationship=rel, user=request.user).delete()
        return HttpResponse('<div class="text-gray-400 text-sm text-center py-4">Conversation cleared.</div>')
