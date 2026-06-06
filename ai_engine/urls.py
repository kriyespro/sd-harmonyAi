from django.urls import path
from . import views

app_name = 'ai_engine'

urlpatterns = [
    path('relationships/<int:rel_pk>/analyze/', views.ConflictAnalyzeView.as_view(), name='analyze'),
    path('relationships/<int:rel_pk>/patterns/', views.PatternDetectView.as_view(), name='patterns'),
    path('relationships/<int:rel_pk>/report/', views.WeeklyReportView.as_view(), name='report'),
    path('relationships/<int:rel_pk>/coach/', views.CoachChatView.as_view(), name='coach'),
]
