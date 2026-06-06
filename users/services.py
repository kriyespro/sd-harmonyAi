from .models import User, Profile


def create_user(email, password, first_name, last_name=''):
    user = User.objects.create_user(
        email=email,
        password=password,
        first_name=first_name,
        last_name=last_name,
    )
    Profile.objects.create(user=user)
    return user


def get_or_create_profile(user):
    profile, _ = Profile.objects.get_or_create(user=user)
    return profile
