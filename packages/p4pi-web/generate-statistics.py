#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sqlite3

def insert(name,time,value):
    try:
        sqliteConnection = sqlite3.connect('db.sqlite3')
        cursor = sqliteConnection.cursor()
        sqlite_insert_query = """INSERT INTO dashboard_statistics
                              (name, time, value)
                               VALUES
                              ('"""+name+"','"+time+"',"+str(value)+""");"""
        count = cursor.execute(sqlite_insert_query)
        sqliteConnection.commit()
        print("Record inserted successfully into Statistics table ", cursor.rowcount)
        cursor.close()

    except sqlite3.Error as error:
        print("Failed to insert data into sqlite table", error)
    finally:
        if sqliteConnection:
            sqliteConnection.close()


import random, json, subprocess, psutil
from datetime import datetime
import time

def get_timestamp():
    now = datetime.now()
    current_time = now.strftime("%H:%M:%S")
    return current_time

def cpu_usage():
    cpu_usage = psutil.cpu_percent(interval=2)
    insert('cpu_usage',get_timestamp(),cpu_usage)

def cpu_temp():
    cpu_comm = "sensors |grep 'temp1'| head -1 |awk '{print $2}'|sed 's/\+//g;s/°C//g'"
    cpu_value = subprocess.check_output(cpu_comm, shell=True)
    insert('cpu_temp',get_timestamp(),float(cpu_value))

def disk_percent():
    cmd_uptime = "df -h |grep '/dev/root\|/dev/sda5'| awk '{print $5}'| sed 's/%//g'"
    hdd_data = subprocess.check_output(cmd_uptime, shell=True)
    insert('hdd_percent',get_timestamp(),float(hdd_data))

def used_mem():
    #mem_cmd = "free -m |egrep 'cache|Mem' |grep -v used|awk '{print $3}'"
    mem_used = psutil.virtual_memory()
    insert('used_mem',get_timestamp(),mem_used.total >> 20)

def percent_mem():
    mem_percent = psutil.virtual_memory().percent
    insert('perecent_mem',get_timestamp(),mem_percent)

def wifi_stat():
    is_wifi_cmd = "ip address show | grep wlan0"
    is_wifi = True
    try:
        subprocess.check_output(is_wifi_cmd, shell=True)
    except subprocess.CalledProcessError:
        is_wifi = False
    if not is_wifi:
        return
    wifi_up = "ifstat -i wlan0 -b -n 1 1 | awk 'NR>2 {print $1}'"
    w_up = subprocess.check_output(wifi_up, shell=True)
    wifi_down = "ifstat -i wlan0 -b -n 1 1 | awk 'NR>2 {print $2}'"
    w_down = subprocess.check_output(wifi_down, shell=True)
    insert('wifi_up',get_timestamp(),float(w_up)/1000.0)
    insert('wifi_down',get_timestamp(),float(w_down)/1000.0)

def eth_stat():
    is_eth_cmd = "ip address show | grep eth0"
    eth = "eth0"
    try:
        subprocess.check_output(is_eth_cmd, shell=True)
    except subprocess.CalledProcessError:
        eth = "enp1s0"
    eth_up = f"ifstat -i {eth} -b -n 1 1 | awk 'NR>2 {{print $1}}'"
    e_up = subprocess.check_output(eth_up, shell=True)
    eth_down = f"ifstat -i {eth} -b -n 1 1 | awk 'NR>2 {{print $2}}'"
    e_down = subprocess.check_output(eth_down, shell=True)
    insert('eth_up',get_timestamp(),float(e_up)/1000.0)
    insert('eth_down',get_timestamp(),float(e_down)/1000.0)

start_from_fresh = True
if __name__ == "__main__":
    i=0;
    while True:
        cpu_usage()
        cpu_temp()
        disk_percent()
        used_mem()
        percent_mem()
        wifi_stat()
        eth_stat()

        time.sleep(30)
