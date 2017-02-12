#! /bin/sh

# Remove blank lines from generated file.
sed -i '/^\s*$/d' /app/avahi-generated.service

# Split file by xml root tag.
csplit -z -s -b '%02d.service' -f '/etc/avahi/services/service-' /app/avahi-generated.service '/<?xml version="1.0" standalone="no"?>/' {*}

# Reload avahi daemon.
avahi-daemon --reload
