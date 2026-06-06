from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views
from billing import views as billing_views

app_name = 'api'

urlpatterns = [
    # Auth
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/login/', views.LoginView.as_view(), name='login'),
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Profile
    path('profile/', views.ProfileView.as_view(), name='profile'),

    # Relationships
    path('relationships/', views.RelationshipListCreateView.as_view(), name='relationships'),
    path('relationships/<int:pk>/', views.RelationshipDetailView.as_view(), name='relationship_detail'),
    path('relationships/accept/<uuid:token>/', views.AcceptInviteAPIView.as_view(), name='accept_invite'),
    path('relationships/<int:pk>/health/', views.HealthScoreView.as_view(), name='health_score'),

    # Events
    path('relationships/<int:rel_pk>/events/', views.EventListCreateView.as_view(), name='events'),

    # Conflicts
    path('relationships/<int:rel_pk>/conflicts/', views.ConflictListCreateView.as_view(), name='conflicts'),

    # Moods
    path('relationships/<int:rel_pk>/mood/', views.MoodCheckInView.as_view(), name='mood_checkin'),
    path('relationships/<int:rel_pk>/mood/history/', views.MoodHistoryView.as_view(), name='mood_history'),
    path('relationships/<int:rel_pk>/connection/', views.ConnectionScoreView.as_view(), name='connection_score'),

    # AI Engine
    path('relationships/<int:rel_pk>/ai/analyze/', views.AIConflictAnalyzeView.as_view(), name='ai_analyze'),
    path('relationships/<int:rel_pk>/ai/patterns/', views.AIPatternDetectView.as_view(), name='ai_patterns'),
    path('relationships/<int:rel_pk>/ai/report/', views.AIWeeklyReportView.as_view(), name='ai_report'),
    path('relationships/<int:rel_pk>/ai/coach/', views.AICoachChatView.as_view(), name='ai_coach'),

    # Billing
    path('billing/status/', billing_views.BillingStatusView.as_view(), name='billing_status'),
    path('billing/create-order/', billing_views.CreateOrderView.as_view(), name='billing_create_order'),
    path('billing/verify/', billing_views.VerifyPaymentView.as_view(), name='billing_verify'),
    path('billing/cancel/', billing_views.CancelSubscriptionView.as_view(), name='billing_cancel'),
    path('billing/activate-test/', billing_views.ActivateTestPremiumView.as_view(), name='billing_activate_test'),
]
