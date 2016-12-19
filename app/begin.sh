#!/bin/sh

#Lets go ! 

#Copying Default location needed for Letsencrypt to Nginx

mkdir -p /etc/vhost
cp /app/nginx_location.conf /etc/vhost/default
