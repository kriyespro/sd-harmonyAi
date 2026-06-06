from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('sd/', admin.site.urls),
    path('admin/', include('control.urls', namespace='control')),
    path('auth/', include('users.urls', namespace='users')),
    path('', include('dashboard.urls', namespace='dashboard')),
    path('relationships/', include('relationships.urls', namespace='relationships')),
    path('moods/', include('moods.urls', namespace='moods')),
    path('api/v1/', include('api.urls', namespace='api')),
    path('ai/', include('ai_engine.urls', namespace='ai_engine')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
