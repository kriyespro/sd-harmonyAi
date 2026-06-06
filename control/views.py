from django.contrib.admin.views.decorators import staff_member_required
from django.utils.decorators import method_decorator
from django.views.generic import TemplateView, ListView

from users.models import User


@method_decorator(staff_member_required, name='dispatch')
class DashboardView(TemplateView):
    template_name = 'control/dashboard.jinja'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['total_users'] = User.objects.count()
        ctx['recent_users'] = User.objects.order_by('-date_joined')[:10]
        return ctx


@method_decorator(staff_member_required, name='dispatch')
class UserListView(ListView):
    template_name = 'control/users.jinja'
    model = User
    context_object_name = 'users'
    paginate_by = 50

    def get_queryset(self):
        qs = super().get_queryset().order_by('-date_joined')
        q = self.request.GET.get('q')
        if q:
            qs = qs.filter(email__icontains=q) | qs.filter(first_name__icontains=q)
        return qs
