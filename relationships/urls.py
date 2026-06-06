from django.urls import path
from . import views

app_name = 'relationships'

urlpatterns = [
    path('', views.RelationshipListView.as_view(), name='list'),
    path('create/', views.RelationshipCreateView.as_view(), name='create'),
    path('<int:pk>/invite/', views.RelationshipInviteView.as_view(), name='invite'),
    path('<int:pk>/', views.RelationshipDetailView.as_view(), name='detail'),
    path('<int:pk>/events/add/', views.AddEventView.as_view(), name='add_event'),
    path('<int:pk>/conflicts/add/', views.AddConflictView.as_view(), name='add_conflict'),
    path('conflicts/<int:pk>/resolve/', views.ResolveConflictView.as_view(), name='resolve_conflict'),
    path('accept/<uuid:token>/', views.AcceptInviteView.as_view(), name='accept_invite'),
    path('decline/<uuid:token>/', views.DeclineInviteView.as_view(), name='decline_invite'),
]
