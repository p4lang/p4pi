import subprocess
import json
import socketio
import signal
import pty
import eventlet
import select
import subprocess
import struct
import fcntl
import termios
import os

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

from terminal.views import sio

task = None
stop = False

def forward_service_output():
    global stop
    global proc

    invoc = subprocess.check_output(["/bin/sh", "-c", "if [ $(systemctl show -p InvocationID --value t4p4s.service | head -c1 | wc -l) -eq 0 ]; then systemctl show -p InvocationID --value t4p4s.service; else systemctl show -p InvocationID --value bmv2.service; fi"])
    proc = subprocess.Popen(["journalctl", "-f", "-n", "all", "-o", "cat", "SYSLOG_IDENTIFIER=t4p4s-start", "SYSLOG_IDENTIFIER=bmv2-start", "--no-pager", f"_SYSTEMD_INVOCATION_ID={invoc.decode().rstrip()}"], stdout=subprocess.PIPE)

    stop = False
    while True:
        sio.sleep(0.01)
        if stop:
            proc.kill()
            return

        (data_ready, _, _) = select.select([proc.stdout], [], [], 0)
        if data_ready:
            line = proc.stdout.readline().decode()
            if line == '' and proc.stdout.at_eof():
                break
            sio.emit("switch_output", {"output": line})

@sio.event
def page_loaded(sid):
    global task
    global stop
    if task:
        stop = True
        task.join()
    task = sio.start_background_task(target=forward_service_output)

@login_required(login_url="/login")
def switch(request):
    html_template = loader.get_template('index.html')
    context = {'segment': 'p4-compiler', 'errors': []}

    if request.method == 'GET':
        return HttpResponse(html_template.render(context, request))

    if request.method == 'POST':
        post_data = json.loads(request.body.decode("utf-8"))
        for field in ['compiler', 'program', 'src']:
            if field not in post_data:
                return JsonResponse({'success': False, 'message': f'Missing {field} filed'})

        examples = ['l2switch', 'calc', 'reflector', 'traffic_filter', 'stateful_firewall', 'basic_mirror', 'arp_icmp']
        if post_data['compiler']=='T4P4S':
            if post_data['program'] in examples:
                utils.set_t4p4s_switch(post_data['program'])
                utils.restart_t4p4s_service()
                page_loaded(0)

            elif post_data['program'] == 'custom':
                utils.update_t4p4s_opts_dpdk(
                    eal_opts='-c 0x01 -n 4 --no-pci --vdev net_pcap0,iface=veth0 --vdev net_pcap1,iface=veth1',
                    cmd_opts='-p 0x0 --config "\"(0,0,0),(1,0,0)\""'
                )

                utils.update_t4p4s_examples(
                    'arch=dpdk hugepages=1024 model=v1model smem vethmode pieal piports'
                )

                utils.upload_p4_program(post_data['src'], 'T4P4S')
            elif post_data['program'] == 'kill_service':
                utils.stop_t4p4s_service()
                utils.stop_bmv2_service()
            else:
                return JsonResponse({'success': False, 'message': 'Not recognized T4P4S example'})
        else:
            if post_data['program'] in examples:
                utils.set_t4p4s_switch(post_data['program'])
                utils.restart_bmv2_service()
                page_loaded(0)

            elif post_data['program'] == 'custom':
                utils.upload_p4_program(post_data['src'], 'BMv2')
            elif post_data['program'] == 'kill_service':
                utils.stop_bmv2_service()
                utils.stop_t4p4s_service()
            else:
                return JsonResponse({'success': False, 'message': 'Not recognized BMv2 example'})

    return JsonResponse({'success': True})

def get_database_data(name):
    import sqlite3
    sqliteConnection = sqlite3.connect('db.sqlite3')
    cursor = sqliteConnection.cursor()
    sqlite_query = "SELECT value FROM dashboard_statistics WHERE name = '"+name+"' ORDER BY time LIMIT 10"
    cursor.execute(sqlite_query)
    return [i[0] for i in cursor.fetchall()]

def get_database_timestamps():
    import sqlite3
    sqliteConnection = sqlite3.connect('db.sqlite3')
    cursor = sqliteConnection.cursor()
    sqlite_query = "SELECT time FROM dashboard_statistics WHERE name = 'cpu_temp' ORDER BY time LIMIT 10"
    cursor.execute(sqlite_query)
    return [i[0] for i in cursor.fetchall()]

@login_required(login_url="/login")
def statistics(request):
    html_template = loader.get_template('statistics.html')
    context = {'segment': 'statistics', 'errors': []}

    if request.method == 'GET':
        context['cpu_temp'] = get_database_data("cpu_temp")
        context['cpu_usage'] = get_database_data("cpu_usage")
        context['hdd_percent'] = get_database_data("hdd_percent")
        context['used_mem'] = get_database_data("used_mem")
        context['percent_mem'] = get_database_data("perecent_mem")
        context['timestamps'] = get_database_timestamps()
        context['wifi_up'] = get_database_data("wifi_up")
        context['wifi_down'] = get_database_data("wifi_down")
        context['eth_up'] = get_database_data("eth_up")
        context['eth_down'] = get_database_data("eth_down")
        return HttpResponse(html_template.render(context, request))

@login_required(login_url="/login")
def entries(request):
    html_template = loader.get_template('entries.html')
    context = {'segment': 'entries', 'errors': []}

    if request.method == 'GET':
        import socket
        import pickle
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('localhost',12345))

        if request.GET.getlist('mode') != []:
            print (request.GET.getlist('mode'))
            action = {}
            action['name'] = request.GET.getlist('name')[0]
            action['match'] = request.GET.getlist('match')[0]
            action['mask'] = request.GET.getlist('mask')[0]
            action['action'] = request.GET.getlist('action')[0]
            action['params'] = request.GET.getlist('params')[0]
            action['mode'] = request.GET.getlist('mode')[0]
            sock.send(pickle.dumps(action))
        else:
            sock.send(pickle.dumps({'mode':'query'}))

        context['tables'] = pickle.loads(sock.recv(1024))
        context['entries'] = []
        for i in range(len(context['tables'])):
            context['tables'][i]['entries'] = pickle.loads(sock.recv(1024))
        sock.close()
        return HttpResponse(html_template.render(context, request))


@login_required(login_url="/login")
def access_point_settings(request):
    html_template = loader.get_template('access-point.html')
    context = {'segment': 'access-point', 'errors': []}

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

            utils.restart_web_service()

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
