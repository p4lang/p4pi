import subprocess
import json

from django.http.response import JsonResponse
from django.contrib.auth import authenticate
from django.contrib.auth import login
from django.contrib.auth import update_session_auth_hash
from django.contrib import messages
from django.shortcuts import render
from django.shortcuts import redirect
from django.contrib.auth.decorators import login_required
from django.template import loader
from django.http import HttpResponse
from django import template

from .forms import LoginForm, SignUpForm, CustomPasswordChangeForm
from .forms import AccessPointSettingsForm
from . import utils


@login_required(login_url="/login")
def switch(request):
    html_template = loader.get_template('index.html')
    context = {'segment': 'ap', 'errors': []}

    if request.method == 'GET':
        return HttpResponse(html_template.render(context, request))

    if request.method == 'POST':
        post_data = json.loads(request.body.decode("utf-8"))
        for field in ['compiler', 'program', 'code']:
            if field not in post_data:
                return JsonResponse({'success': False, 'message': f'Missing {field} filed'})

        examples = ['l2switch', 'calc', 'reflector', 'firewall', 'stateful', 'basic_mirror', 'arp_icmp']
        if post_data['program'] in examples:
            utils.set_t4p4s_switch(post_data['program'])
            utils.restart_t4p4s_service()
        elif post_data['program'] == 'custom':
            utils.update_t4p4s_opts_dpdk(
                eal_opts='-c 0x01 -n 4 --no-pci --vdev net_pcap0,iface=veth0 --vdev net_pcap1,iface=veth1',
                cmd_opts='-p 0x0 --config "\"(0,0,0),(1,0,0)\""'
            )

            utils.update_t4p4s_examples(
                'arch=dpdk hugepages=1024 model=v1model smem vethmode pieal piports'
            )

            utils.upload_p4_program(post_data['code'])
        else:
            return JsonResponse({'success': False, 'message': 'Not recognized T4P4S example'})
    return JsonResponse({'success': True})


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
                context['errors'].append('Failed to save dhcpd configuration')

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


@login_required(login_url="/login")
def password_change(request):
    html_template = loader.get_template('accounts/password_change.html')
    context = {'errors': []}

    if request.method == 'POST':
        form = CustomPasswordChangeForm(user=request.user, data=request.POST)
        context['form'] = form
        if form.is_valid():
            form.save()
            update_session_auth_hash(request, form.user)
            messages.success(
                request,
                'Your password has been successfully updated.'
            )
            return redirect("/")
    else:
        context['form'] = CustomPasswordChangeForm(user=request.user)

    return HttpResponse(html_template.render(context, request))
