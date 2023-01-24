entry1 = [{'match':'0xffeeddcc', 'action':'nop', 'params':''}, {'match':'0x11002233','action':'fwd', 'params':'1'}]
entry2 = [{'match':'127.0.0.0', 'mask':'8', 'action':'nop', 'params':''}, {'match':'192.0.0.0', 'mask':'16', 'action':'fwd', 'params':'1'}]
entry3 = [{'match':'127.0.0.0', 'mask':'8', 'action':'nop', 'params':''}, {'match':'192.0.0.0', 'mask':'16', 'action':'fwd', 'params':'1'}]

entries = [entry1, entry2, entry3]

tab = {'name':'l2tab', 'type':'exact', 'editable':True}
tab2 = {'name':'l3tab', 'type':'lpm', 'editable':False}
tab3 = {'name':'l3tabedit', 'type':'lpm', 'editable':True}
tables = [tab, tab2, tab3]

import socket
import pickle

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind(('localhost',12345))
sock.listen()
while True:
    cli, addr = sock.accept();
    request = pickle.loads(cli.recv(1024))
    print(request)
    if request['mode'] == 'add':
        i=-1
        for table in tables:
            print(table)
            i=i+1
            if table['name'] == request['name']:
                request.pop('mode')
                request.pop('name')
                entries[i].append(request)
                break
    elif request['mode'] == 'delete':
        i=-1
        for table in tables:
            print(table)
            i=i+1
            if table['name'] == request['name']:
                request.pop('mode')
                request.pop('name')
                try:
                    entries[i].remove(request)
                except:
                    pass
                break

    cli.send(pickle.dumps(tables));
    import time
    time.sleep(0.05)
    cli.send(pickle.dumps(entries[0]));
    time.sleep(0.05)
    cli.send(pickle.dumps(entries[1]));
    time.sleep(0.05)
    cli.send(pickle.dumps(entries[2]));
    cli.close();

