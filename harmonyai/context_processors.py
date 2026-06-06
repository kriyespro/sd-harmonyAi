from django.middleware.csrf import get_token
from django.utils.safestring import mark_safe


def csrf(request):
    token = get_token(request)
    return {
        'csrf_input': mark_safe(
            f'<input type="hidden" name="csrfmiddlewaretoken" value="{token}">'
        ),
        'csrf_token': token,
    }
