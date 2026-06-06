from django.db import models
from django.conf import settings


class MoodEntry(models.Model):
    MOOD_HAPPY = 'happy'
    MOOD_NEUTRAL = 'neutral'
    MOOD_SAD = 'sad'
    MOOD_ANGRY = 'angry'
    MOOD_STRESSED = 'stressed'

    MOOD_CHOICES = [
        (MOOD_HAPPY, '😊 Happy'),
        (MOOD_NEUTRAL, '😐 Neutral'),
        (MOOD_SAD, '😔 Sad'),
        (MOOD_ANGRY, '😡 Angry'),
        (MOOD_STRESSED, '😰 Stressed'),
    ]

    MOOD_SCORES = {
        MOOD_HAPPY: 5,
        MOOD_NEUTRAL: 3,
        MOOD_SAD: 2,
        MOOD_ANGRY: 1,
        MOOD_STRESSED: 2,
    }

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='moods')
    relationship = models.ForeignKey(
        'relationships.Relationship',
        on_delete=models.CASCADE,
        related_name='mood_entries',
    )
    mood = models.CharField(max_length=10, choices=MOOD_CHOICES)
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    date = models.DateField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ('user', 'relationship', 'date')

    def __str__(self):
        return f'{self.user.email} — {self.mood} ({self.date})'

    @property
    def score(self):
        return self.MOOD_SCORES.get(self.mood, 3)


class ConnectionScore(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='connection_scores')
    relationship = models.ForeignKey(
        'relationships.Relationship',
        on_delete=models.CASCADE,
        related_name='connection_scores',
    )
    score = models.PositiveSmallIntegerField(choices=[(i, i) for i in range(1, 11)])
    date = models.DateField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        unique_together = ('user', 'relationship', 'date')

    def __str__(self):
        return f'{self.user.email} — connection {self.score}/10 ({self.date})'
