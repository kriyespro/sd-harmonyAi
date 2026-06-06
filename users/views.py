from django.contrib.auth import login, logout
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import redirect
from django.views import View
from django.views.generic import FormView, TemplateView

from .forms import RegisterForm, LoginForm, ProfileForm
from .services import create_user, get_or_create_profile


class RegisterView(FormView):
    template_name = 'auth/register.jinja'
    form_class = RegisterForm

    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            return redirect('dashboard:home')
        return super().dispatch(request, *args, **kwargs)

    def form_valid(self, form):
        user = create_user(
            email=form.cleaned_data['email'],
            password=form.cleaned_data['password'],
            first_name=form.cleaned_data['first_name'],
            last_name=form.cleaned_data['last_name'],
        )
        login(self.request, user)
        return redirect('dashboard:home')

    def form_invalid(self, form):
        return self.render_to_response(self.get_context_data(form=form))


class LoginView(FormView):
    template_name = 'auth/login.jinja'
    form_class = LoginForm

    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            return redirect('dashboard:home')
        return super().dispatch(request, *args, **kwargs)

    def form_valid(self, form):
        login(self.request, form.get_user())
        return redirect(self.request.GET.get('next', 'dashboard:home'))

    def form_invalid(self, form):
        return self.render_to_response(self.get_context_data(form=form))


class LogoutView(LoginRequiredMixin, View):
    def post(self, request):
        logout(request)
        return redirect('users:login')


class ProfileView(LoginRequiredMixin, TemplateView):
    template_name = 'pages/profile.jinja'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['profile'] = get_or_create_profile(self.request.user)
        ctx['form'] = ProfileForm(instance=ctx['profile'])
        return ctx

    def post(self, request):
        profile = get_or_create_profile(request.user)
        form = ProfileForm(request.POST, request.FILES, instance=profile)
        if form.is_valid():
            form.save()
            return redirect('users:profile')
        return self.render_to_response(self.get_context_data(form=form))
