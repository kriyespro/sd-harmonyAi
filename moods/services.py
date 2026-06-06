from django.utils import timezone
from datetime import timedelta
from .models import MoodEntry, ConnectionScore


def log_mood(user, relationship, mood, note=''):
    today = timezone.now().date()
    entry, created = MoodEntry.objects.update_or_create(
        user=user,
        relationship=relationship,
        date=today,
        defaults={'mood': mood, 'note': note},
    )
    return entry, created


def log_connection_score(user, relationship, score):
    today = timezone.now().date()
    entry, created = ConnectionScore.objects.update_or_create(
        user=user,
        relationship=relationship,
        date=today,
        defaults={'score': score},
    )
    return entry, created


def get_mood_trend(user, relationship, days=14):
    since = timezone.now() - timedelta(days=days)
    return MoodEntry.objects.filter(
        user=user,
        relationship=relationship,
        created_at__gte=since,
    ).order_by('date')


def checked_in_today(user, relationship):
    today = timezone.now().date()
    return MoodEntry.objects.filter(user=user, relationship=relationship, date=today).exists()
