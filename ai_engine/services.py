import json
import anthropic
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
from django.db.models import Avg

MODEL = 'claude-opus-4-8'


def _client():
    return anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)


def _call(system_prompt, user_message, max_tokens=1024):
    msg = _client().messages.create(
        model=MODEL,
        max_tokens=max_tokens,
        system=system_prompt,
        messages=[{'role': 'user', 'content': user_message}],
    )
    return msg.content[0].text


def _parse_json(text):
    try:
        start = text.find('{')
        end = text.rfind('}') + 1
        return json.loads(text[start:end])
    except Exception:
        return None


def analyze_conflict(conflict):
    rel = conflict.relationship
    system = (
        'You are HarmonyAI, a compassionate relationship intelligence assistant. '
        'Analyze conflicts objectively. Return ONLY valid JSON, no markdown fences.'
    )
    user_msg = f"""Analyze this relationship conflict and return a JSON object:
{{
  "root_causes": ["cause 1", "cause 2", "cause 3"],
  "person_a_perspective": "Empathetic explanation of the conflict-starter's view (2-3 sentences)",
  "person_b_perspective": "Empathetic explanation of the other person's view (2-3 sentences)",
  "action_steps": ["Concrete step 1", "Concrete step 2", "Concrete step 3"],
  "resolution_timeframe": "short_term OR medium_term OR long_term",
  "watch_out": "One warning sign to avoid in resolving this"
}}

Conflict details:
- Relationship type: {rel.get_relationship_type_display()}
- Category: {conflict.get_category_display()}
- Severity: {conflict.severity}/5
- Description: {conflict.description}"""

    text = _call(system, user_msg, max_tokens=800)
    data = _parse_json(text)
    if not data:
        return {'error': 'AI analysis unavailable. Try again shortly.', 'raw': text}
    return data


def detect_patterns(relationship, user):
    from moods.models import MoodEntry, ConnectionScore
    from relationships.models import ConflictEntry

    thirty_days_ago = timezone.now() - timedelta(days=30)
    fifteen_days_ago = timezone.now() - timedelta(days=15)

    moods_all = MoodEntry.objects.filter(relationship=relationship, created_at__gte=thirty_days_ago)
    moods_recent = moods_all.filter(created_at__gte=fifteen_days_ago)
    moods_older = moods_all.filter(created_at__lt=fifteen_days_ago)

    conn_all = ConnectionScore.objects.filter(relationship=relationship, created_at__gte=thirty_days_ago)
    conn_recent = conn_all.filter(created_at__gte=fifteen_days_ago)
    conn_older = conn_all.filter(created_at__lt=fifteen_days_ago)

    conflicts = ConflictEntry.objects.filter(relationship=relationship, created_at__gte=thirty_days_ago)

    mood_recent_avg = moods_recent.aggregate(a=Avg('mood'))['a'] or 3
    mood_older_avg = moods_older.aggregate(a=Avg('mood'))['a'] or 3
    conn_recent_avg = conn_recent.aggregate(a=Avg('score'))['a'] or 5
    conn_older_avg = conn_older.aggregate(a=Avg('score'))['a'] or 5

    top_conflict_cats = (
        conflicts.values('category')
        .annotate(n=__import__('django.db.models', fromlist=['Count']).Count('id'))
        .order_by('-n')[:3]
    )

    system = (
        'You are HarmonyAI. Analyze relationship data patterns. '
        'Return ONLY valid JSON, no markdown fences.'
    )
    user_msg = f"""Analyze 30-day patterns for a {relationship.get_relationship_type_display()} relationship:

Data (scale 1-5 for mood, 1-10 for connection):
- Mood avg (last 15 days): {round(mood_recent_avg, 1)} vs (prior 15 days): {round(mood_older_avg, 1)}
- Connection avg (last 15 days): {round(conn_recent_avg, 1)} vs (prior 15 days): {round(conn_older_avg, 1)}
- Total conflicts (30 days): {conflicts.count()}
- Resolved conflicts: {conflicts.filter(resolved=True).count()}
- Top conflict categories: {', '.join(c['category'] for c in top_conflict_cats) or 'none'}
- Total check-ins: {moods_all.count()}

Return:
{{
  "mood_trend": "improving OR declining OR stable",
  "connection_trend": "improving OR declining OR stable",
  "primary_concern": "One sentence about the most important issue",
  "positive_patterns": ["positive pattern 1", "positive pattern 2"],
  "risk_factors": ["risk 1", "risk 2"],
  "weekly_focus": "One actionable focus for the next 7 days"
}}"""

    text = _call(system, user_msg, max_tokens=600)
    data = _parse_json(text)
    if not data:
        return {'error': 'Pattern analysis unavailable.', 'raw': text}
    return data


def generate_weekly_report(relationship, user):
    from moods.models import MoodEntry, ConnectionScore
    from relationships.models import ConflictEntry, Event

    now = timezone.now()
    this_week_start = now - timedelta(days=7)
    last_week_start = now - timedelta(days=14)

    this_moods = MoodEntry.objects.filter(relationship=relationship, created_at__gte=this_week_start)
    last_moods = MoodEntry.objects.filter(relationship=relationship, created_at__gte=last_week_start, created_at__lt=this_week_start)

    this_conn = ConnectionScore.objects.filter(relationship=relationship, created_at__gte=this_week_start)
    last_conn = ConnectionScore.objects.filter(relationship=relationship, created_at__gte=last_week_start, created_at__lt=this_week_start)

    this_conflicts = ConflictEntry.objects.filter(relationship=relationship, created_at__gte=this_week_start)
    this_resolved = this_conflicts.filter(resolved=True).count()

    upcoming = Event.objects.filter(
        relationship=relationship,
        date__range=(now.date(), (now + timedelta(days=14)).date()),
    ).values_list('title', 'date')[:3]

    this_mood_avg = this_moods.aggregate(a=Avg('mood'))['a'] or 3
    last_mood_avg = last_moods.aggregate(a=Avg('mood'))['a'] or 3
    this_conn_avg = this_conn.aggregate(a=Avg('score'))['a'] or 5
    last_conn_avg = last_conn.aggregate(a=Avg('score'))['a'] or 5

    mood_change = round(((this_mood_avg - last_mood_avg) / max(last_mood_avg, 0.1)) * 100)
    conn_change = round(((this_conn_avg - last_conn_avg) / max(last_conn_avg, 0.1)) * 100)

    system = (
        'You are HarmonyAI. Generate warm, honest, actionable weekly relationship reports. '
        'Return ONLY valid JSON, no markdown fences.'
    )
    user_msg = f"""Generate a weekly report for a {relationship.get_relationship_type_display()} relationship:

This week vs last week:
- Mood change: {mood_change:+d}% (this week avg: {round(this_mood_avg, 1)}/5)
- Connection change: {conn_change:+d}% (this week avg: {round(this_conn_avg, 1)}/10)
- New conflicts: {this_conflicts.count()}
- Conflicts resolved: {this_resolved}
- Check-in streak (days this week): {this_moods.count()}
- Upcoming events (14 days): {', '.join(f'{t} on {d}' for t, d in upcoming) or 'none'}

Return:
{{
  "headline": "One punchy sentence summarizing the week",
  "mood_summary": "2 sentences about mood trend",
  "connection_summary": "2 sentences about connection trend",
  "highlights": ["positive highlight 1", "positive highlight 2"],
  "areas_to_watch": ["concern 1"],
  "this_week_focus": "One specific, actionable focus (max 20 words)",
  "affirmation": "A warm, genuine closing affirmation (1 sentence)"
}}"""

    text = _call(system, user_msg, max_tokens=700)
    data = _parse_json(text)
    if not data:
        return {'error': 'Report generation failed.', 'raw': text}
    return data


def chat_with_coach(relationship, user, message, history=None):
    from moods.models import MoodEntry
    from relationships.models import ConflictEntry

    recent_moods = MoodEntry.objects.filter(
        relationship=relationship, user=user
    ).order_by('-date')[:7]
    recent_conflicts = ConflictEntry.objects.filter(
        relationship=relationship
    ).order_by('-created_at')[:3]

    mood_summary = ', '.join(m.mood for m in recent_moods) if recent_moods else 'no recent data'
    conflict_summary = (
        '; '.join(f'{c.category} (severity {c.severity})' for c in recent_conflicts)
        if recent_conflicts else 'no recent conflicts'
    )

    system = f"""You are HarmonyAI, a compassionate relationship coach. You are warm, practical, and non-judgmental.

Relationship context:
- Type: {relationship.get_relationship_type_display()}
- User's recent mood (last 7 days): {mood_summary}
- Recent conflicts: {conflict_summary}

Rules:
- Keep responses under 120 words
- Be specific and actionable, not generic
- Reference the relationship context when relevant
- Never diagnose or prescribe; always suggest professional help for serious issues"""

    messages = []
    if history:
        for h in history[-8:]:
            messages.append({'role': h['role'], 'content': h['content']})
    messages.append({'role': 'user', 'content': message})

    msg = _client().messages.create(
        model=MODEL,
        max_tokens=300,
        system=system,
        messages=messages,
    )
    return msg.content[0].text
