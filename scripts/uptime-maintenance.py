#!/usr/bin/env python3

# This script is used to toggle the Uptime API and Transaction tests
# during deployment so that we don't generate spurious alarms when
# deploying check-api updates to Live.
#
# Usage:
# 1.) Set the UPTIME_TOKEN environment variable.
#     See https://uptime.com/api/tokens for instructions.
# 2.) Call ./uptime-maintenance.py on
#       [ deployment performed here ]
# 3.) Call ./uptime-maintenance.py off
#
# NOTE: exit status always zero as we don't want to fail builds if
#       the Uptime check pause fails.
#
import os
import sys
import requests

def usage():
    print("Usage: %s [on|off]" % (sys.argv[0]))
    print("Environment variable UPTIME_TOKEN must also be set.")
    exit(0)

def bad_resp():
    print("Received unsuccessful response from Uptime API.")
    print("Check your UPTIME_TOKEN value.")
    exit(0)

def set_pause(state):
    pause_status = 'false'
    if state == 'on':
        pause_status = 'true'

    my_headers = {'Authorization' : 'Token %s' % (os.environ.get('UPTIME_TOKEN'))}

    current_page = 'https://uptime.com/api/v1/checks/'
    while current_page != None:
        response = requests.get(current_page, headers=my_headers)
        if response.status_code != 200:
            bad_resp()

        rdata = response.json()
        current_page = rdata.get('next')

        for row in rdata['results']:
            if row['check_type'] == 'TRANSACTION' or row['check_type'] == 'API':
                row['is_paused'] = pause_status
                print("Updating check %s ..." % (row['name']))
                mresp = requests.put(row['url'], headers=my_headers, data=row)
                rdata = response.json()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        usage()

    token = os.environ.get('UPTIME_TOKEN')
    if token == None or len(token) < 40:
        usage()

    cmd = sys.argv[1]
    if cmd == "on" or cmd == "off":
        set_pause(cmd)
    else:
        usage()

    exit(0)
