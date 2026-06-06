from django.db import models
from django.conf import settings
from django.utils import timezone


class Subscription(models.Model):
    PLAN_FREE = 'free'
    PLAN_PREMIUM = 'premium'
    PLAN_CHOICES = [(PLAN_FREE, 'Free'), (PLAN_PREMIUM, 'Premium ₹199/mo')]

    STATUS_ACTIVE = 'active'
    STATUS_CANCELLED = 'cancelled'
    STATUS_EXPIRED = 'expired'
    STATUS_CHOICES = [
        (STATUS_ACTIVE, 'Active'),
        (STATUS_CANCELLED, 'Cancelled'),
        (STATUS_EXPIRED, 'Expired'),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='subscription',
    )
    plan = models.CharField(max_length=20, choices=PLAN_CHOICES, default=PLAN_FREE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_ACTIVE)
    razorpay_order_id = models.CharField(max_length=120, blank=True)
    razorpay_payment_id = models.CharField(max_length=120, blank=True)
    amount_paise = models.PositiveIntegerField(default=19900)
    current_period_start = models.DateTimeField(null=True, blank=True)
    current_period_end = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.user.email} — {self.plan}'

    @property
    def is_active_premium(self):
        if self.plan != self.PLAN_PREMIUM:
            return False
        if self.status != self.STATUS_ACTIVE:
            return False
        if self.current_period_end and self.current_period_end < timezone.now():
            return False
        return True


class AIUsage(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='ai_usages',
    )
    month = models.CharField(max_length=7)  # YYYY-MM
    analyze_count = models.PositiveSmallIntegerField(default=0)
    pattern_count = models.PositiveSmallIntegerField(default=0)
    report_count = models.PositiveSmallIntegerField(default=0)
    coach_count = models.PositiveSmallIntegerField(default=0)

    class Meta:
        unique_together = [('user', 'month')]

    def __str__(self):
        return f'{self.user.email} — {self.month}'
