from django.db.models import Avg, Count, Q
from django.utils import timezone
from datetime import timedelta

from .models import Relationship, Event, ConflictEntry
from moods.models import MoodEntry, ConnectionScore


def get_user_relationships(user):
    return Relationship.objects.filter(
        Q(creator=user) | Q(partner=user),
        status=Relationship.STATUS_ACTIVE,
    ).select_related('creator', 'partner')


def create_relationship(user, relationship_type):
    return Relationship.objects.create(
        creator=user,
        relationship_type=relationship_type,
        status=Relationship.STATUS_PENDING,
    )


def accept_invite(relationship, user):
    relationship.partner = user
    relationship.status = Relationship.STATUS_ACTIVE
    relationship.save()
    return relationship


def decline_invite(relationship):
    relationship.delete()


def get_upcoming_events(relationship, days=30):
    today = timezone.now().date()
    future = today + timedelta(days=days)
    return Event.objects.filter(
        relationship=relationship,
        date__range=(today, future),
    ).order_by('date')


def calculate_health_score(relationship):
    thirty_days_ago = timezone.now() - timedelta(days=30)

    moods = MoodEntry.objects.filter(
        relationship=relationship,
        created_at__gte=thirty_days_ago,
    )
    connections = ConnectionScore.objects.filter(
        relationship=relationship,
        created_at__gte=thirty_days_ago,
    )
    conflicts = ConflictEntry.objects.filter(
        relationship=relationship,
        created_at__gte=thirty_days_ago,
    )

    mood_avg = moods.aggregate(avg=Avg('mood'))['avg'] or 3
    mood_score = (mood_avg / 5) * 100

    conn_avg = connections.aggregate(avg=Avg('score'))['avg'] or 5
    conn_score = (conn_avg / 10) * 100

    conflict_count = conflicts.count()
    resolved_count = conflicts.filter(resolved=True).count()
    if conflict_count == 0:
        conflict_score = 90
    else:
        conflict_score = max(20, 90 - (conflict_count * 10) + (resolved_count * 5))

    overall = round((mood_score * 0.35) + (conn_score * 0.40) + (conflict_score * 0.25))

    return {
        'overall': min(100, overall),
        'mood_score': round(mood_score),
        'connection_score': round(conn_score),
        'conflict_score': round(conflict_score),
        'label': _health_label(overall),
        'color': _health_color(overall),
    }


def _health_label(score):
    if score >= 80:
        return 'Strong'
    if score >= 60:
        return 'Good'
    if score >= 40:
        return 'Needs Attention'
    return 'At Risk'


def _health_color(score):
    if score >= 80:
        return 'green'
    if score >= 60:
        return 'blue'
    if score >= 40:
        return 'yellow'
    return 'red'


def get_conflict_patterns(relationship):
    from django.db.models import Count
    return (
        ConflictEntry.objects.filter(relationship=relationship)
        .values('category')
        .annotate(count=Count('id'))
        .order_by('-count')[:3]
    )
