import subprocess
from django.shortcuts import render
from django.contrib.auth import authenticate, login
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.template import loader
from django.http import HttpResponse
from django import template

from .forms import LoginForm, SignUpForm
from .forms import AccessPointSettingsForm
from . import utils


@login_required(login_url="/login")
def index(request):

    context = {}
    context['segment'] = 'index'

    html_template = loader.get_template( 'index.html' )
    return HttpResponse(html_template.render(context, request))


@login_required(login_url="/login")
def access_point_settings(request):
    html_template = loader.get_template('access-point.html')
    context = {'segment': 'ap', 'errors': []}

    if request.method == 'GET':
        context['form'] = AccessPointSettingsForm()
        return HttpResponse(html_template.render(context, request))

    if request.method == 'POST':
        form = AccessPointSettingsForm(request.POST)
        context['form'] = form

        if form.is_valid():
            try:
                utils.update_dhcpcd_config(
                    static_ip_address=form.cleaned_data["static_ip_address"]
                )
            except Exception:
                context['errors'].append(
                    'Failed to save dhcpd configuration')

            if not context['errors']:
                try:
                    utils.update_dnsmasq_config(
                        range_min=form.cleaned_data['range_min'],
                        range_max=form.cleaned_data['range_max'],
                        lease=form.cleaned_data['lease']
                    )
                except Exception:
                    context['errors'].append('Failed to save dnsmasq configuration')

            if not context['errors']:
                try:
                    utils.update_hostapd_config(
                        country_code=form.cleaned_data['country_code'],
                        ssid=form.cleaned_data['ssid'],
                        passphrase=form.cleaned_data['passphrase'],
                        channel=form.cleaned_data['channel']
                    )
                except Exception:
                    context['errors'].append('Failed to save hostapd configuration')

            if not context['errors']:
                try:
                    subprocess.check_call(['systemctl', 'restart', 'hostapd'])
                except subprocess.CalledProcessError:
                    context['errors'].append('Failed to restart hostapd service')

        return HttpResponse(html_template.render(context, request))


@login_required(login_url="/login")
def pages(request):
    context = {}
    try:
        load_template = request.path.split('/')[-1]
        context['segment'] = load_template
        html_template = loader.get_template( load_template )
        return HttpResponse(html_template.render(context, request))
    except template.TemplateDoesNotExist:
        html_template = loader.get_template( 'page-404.html' )
        return HttpResponse(html_template.render(context, request))

    except Exception:
        html_template = loader.get_template('page-500.html')
        return HttpResponse(html_template.render(context, request))


def login_view(request):
    msg = None
    form = LoginForm(request.POST or None)
    if request.method == "POST":
        if not form.is_valid():
            msg = 'Error validating the form'
        else:
            username = form.cleaned_data.get("username")
            password = form.cleaned_data.get("password")
            user = authenticate(username=username, password=password)
            if user is None:
                msg = 'Invalid credentials'
            else:
                login(request, user)
                return redirect("/")
    return render(request, "accounts/login.html", {"form": form, "msg": msg})


def register_user(request):
    msg = None
    success = False
    if request.method == "POST":
        form = SignUpForm(request.POST)
        if not form.is_valid():
            msg = 'Form is not valid'
        else:
            form.save()
            username = form.cleaned_data.get("username")
            raw_password = form.cleaned_data.get("password1")
            authenticate(username=username, password=raw_password)
            return redirect("/login")
    else:
        form = SignUpForm()
    return render(request, "accounts/register.html", {"form": form, "msg": msg, "success" : success })
