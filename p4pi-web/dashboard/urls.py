from django.urls import path, re_path
from django.contrib.auth.views import LogoutView

from . import views


urlpatterns = [
    path('', views.switch, name='switch'),
    path('upload_program', views.switch, name='upload_program'),

    path('login', views.login_view, name='login'),
    path('register', views.register_user, name='register'),
    path('password_change', views.password_change, name='password_change'),
    path('logout', LogoutView.as_view(), name='logout'),

    path('ap', views.access_point_settings, name='access_point_settings'),

    # Matches any html file
    re_path(r'^.*\.*', views.pages, name='pages'),
]
