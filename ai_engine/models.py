from django.db import models
from django.conf import settings


class AIInsight(models.Model):
    TYPE_CONFLICT = 'conflict'
    TYPE_PATTERN = 'pattern'
    TYPE_WEEKLY = 'weekly'

    TYPE_CHOICES = [
        (TYPE_CONFLICT, 'Conflict Analysis'),
        (TYPE_PATTERN, 'Pattern Detection'),
        (TYPE_WEEKLY, 'Weekly Report'),
    ]

    relationship = models.ForeignKey(
        'relationships.Relationship',
        on_delete=models.CASCADE,
        related_name='ai_insights',
    )
    requested_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='ai_insights',
    )
    insight_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    input_summary = models.TextField(blank=True)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.insight_type} insight for {self.relationship} ({self.created_at.date()})'


class ChatMessage(models.Model):
    ROLE_USER = 'user'
    ROLE_ASSISTANT = 'assistant'

    ROLE_CHOICES = [
        (ROLE_USER, 'User'),
        (ROLE_ASSISTANT, 'Assistant'),
    ]

    relationship = models.ForeignKey(
        'relationships.Relationship',
        on_delete=models.CASCADE,
        related_name='chat_messages',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_messages',
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'{self.role}: {self.content[:60]}'
