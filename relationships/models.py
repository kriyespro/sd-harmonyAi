import uuid
from django.db import models
from django.conf import settings


class Relationship(models.Model):
    TYPE_COUPLE = 'couple'
    TYPE_PARENT_CHILD = 'parent_child'
    TYPE_FRIENDS = 'friends'
    TYPE_BUSINESS = 'business'

    TYPE_CHOICES = [
        (TYPE_COUPLE, 'Couple'),
        (TYPE_PARENT_CHILD, 'Parent / Child'),
        (TYPE_FRIENDS, 'Friends'),
        (TYPE_BUSINESS, 'Business Partners'),
    ]

    STATUS_PENDING = 'pending'
    STATUS_ACTIVE = 'active'
    STATUS_INACTIVE = 'inactive'

    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_ACTIVE, 'Active'),
        (STATUS_INACTIVE, 'Inactive'),
    ]

    creator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_relationships',
    )
    partner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='partner_relationships',
    )
    relationship_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default=TYPE_COUPLE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    invite_token = models.UUIDField(default=uuid.uuid4, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        partner_name = self.partner.get_full_name() if self.partner else 'Pending'
        return f'{self.creator.get_full_name()} ↔ {partner_name} ({self.relationship_type})'

    def get_other_user(self, user):
        return self.partner if self.creator == user else self.creator


class Event(models.Model):
    TYPE_BIRTHDAY = 'birthday'
    TYPE_ANNIVERSARY = 'anniversary'
    TYPE_PROMISE = 'promise'
    TYPE_VACATION = 'vacation'
    TYPE_FAMILY = 'family'
    TYPE_OTHER = 'other'

    TYPE_CHOICES = [
        (TYPE_BIRTHDAY, 'Birthday'),
        (TYPE_ANNIVERSARY, 'Anniversary'),
        (TYPE_PROMISE, 'Promise'),
        (TYPE_VACATION, 'Vacation'),
        (TYPE_FAMILY, 'Family Event'),
        (TYPE_OTHER, 'Other'),
    ]

    relationship = models.ForeignKey(Relationship, on_delete=models.CASCADE, related_name='events')
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    event_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    title = models.CharField(max_length=200)
    date = models.DateField()
    notes = models.TextField(blank=True)
    is_recurring = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date']

    def __str__(self):
        return f'{self.title} ({self.date})'


class ConflictEntry(models.Model):
    CATEGORY_MONEY = 'money'
    CATEGORY_TIME = 'time'
    CATEGORY_WORK = 'work'
    CATEGORY_FAMILY = 'family'
    CATEGORY_TRUST = 'trust'
    CATEGORY_COMMUNICATION = 'communication'
    CATEGORY_OTHER = 'other'

    CATEGORY_CHOICES = [
        (CATEGORY_MONEY, 'Money'),
        (CATEGORY_TIME, 'Time'),
        (CATEGORY_WORK, 'Work'),
        (CATEGORY_FAMILY, 'Family'),
        (CATEGORY_TRUST, 'Trust'),
        (CATEGORY_COMMUNICATION, 'Communication'),
        (CATEGORY_OTHER, 'Other'),
    ]

    relationship = models.ForeignKey(Relationship, on_delete=models.CASCADE, related_name='conflicts')
    logged_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    description = models.TextField()
    severity = models.PositiveSmallIntegerField(choices=[(i, i) for i in range(1, 6)])
    resolved = models.BooleanField(default=False)
    resolution_note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.category} conflict (severity {self.severity})'
