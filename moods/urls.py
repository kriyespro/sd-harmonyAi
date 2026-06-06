from django.urls import path
from . import views

app_name = 'moods'

urlpatterns = [
    path('<int:rel_pk>/checkin/', views.MoodCheckInView.as_view(), name='checkin'),
    path('<int:rel_pk>/connection/', views.ConnectionScoreView.as_view(), name='connection'),
]
