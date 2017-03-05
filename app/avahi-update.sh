#! /bin/sh

# Remove blank lines from generated file.
cp /app/avahi-generated.hosts /etc/avahi/hosts

# Reload avahi daemon.
avahi-daemon --reload
