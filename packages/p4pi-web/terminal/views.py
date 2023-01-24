import os
import socketio
import pty
import select
import subprocess
import struct
import fcntl
import termios
import signal
import eventlet

from django.shortcuts import render
from django.template import loader
from django.http import HttpResponse
from django.contrib.auth.decorators import login_required


sio = socketio.Server(async_mode="eventlet")

# will be used as global variables
fd = None
child_pid = None

@login_required(login_url="/login")
def terminal(request):
    html_template = loader.get_template('terminal.html')
    context = {'segment': 'terminal', 'errors': []}

    if request.method == 'GET':
        return HttpResponse(html_template.render(context, request))

# changes the size reported to TTY-aware applications like vim
def set_winsize(fd, row, col, xpix=0, ypix=0):
    winsize = struct.pack("HHHH", row, col, xpix, ypix)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, winsize)


def read_and_forward_pty_output():
    global fd
    max_read_bytes = 1024 * 20
    while True:
        sio.sleep(0.01)
        if fd:
            timeout_sec = 0
            (data_ready, _, _) = select.select([fd], [], [], timeout_sec)
            if data_ready:
                output = os.read(fd, max_read_bytes).decode()
                sio.emit("pty_output", {"output": output})
        else:
            print("process killed")
            return

@sio.event
def resize(sid, message):
    if fd:
        set_winsize(fd, message["rows"], message["cols"])

@sio.event
def pty_input(sid, message):
    if fd:
        os.write(fd, message["input"].encode())

@sio.event
def disconnect_request(sid):
    sio.disconnect(sid)

@sio.event
def connect(sid, environ):
    global fd
    global child_pid

    if child_pid:
        # already started child process, don't start another
        # write a new line so that when a client refresh the shell prompt is printed
        os.write(fd, "\n".encode())
        return

    # create child process attached to a pty we can read from and write to
    (child_pid, fd) = pty.fork()

    if child_pid == 0:
        # this is the child process fork.
        # anything printed here will show up in the pty, including the output
        # of this subprocess
        subprocess.run('bash')

    else:
        # this is the parent process fork.
        sio.start_background_task(target=read_and_forward_pty_output)

@sio.event
def disconnect(sid):

    global fd
    global child_pid

    # kill pty process
    os.kill(child_pid,signal.SIGKILL)
    os.waitpid(child_pid, 0)

    # reset the variables
    fd = None
    child_pid = None
    print('Client disconnected')
