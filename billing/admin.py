from django.contrib import admin
from .models import Subscription, AIUsage


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ['user', 'plan', 'status', 'current_period_end', 'created_at']
    list_filter = ['plan', 'status']
    search_fields = ['user__email']


@admin.register(AIUsage)
class AIUsageAdmin(admin.ModelAdmin):
    list_display = ['user', 'month', 'analyze_count', 'pattern_count', 'report_count', 'coach_count']
    list_filter = ['month']
    search_fields = ['user__email']
