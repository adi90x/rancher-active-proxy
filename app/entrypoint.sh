#!/bin/bash

set -u

function check_writable_directory {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Error: can't access to '$dir' directory !" >&2
        echo "Check that '$dir' directory is declared has a writable volume." >&2
        exit 1
    fi
    touch $dir/.check_writable 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "Error: can't write to the '$dir' directory !" >&2
        echo "Check that '$dir' directory is export as a writable volume." >&2
        exit 1
    fi
    rm -f $dir/.check_writable
}

function check_dh_group {
    if [[ ! -f /etc/nginx/certs/dhparam.pem ]]; then
        echo "Creating Diffie-Hellman group (can take several minutes...)"
        openssl dhparam -out /etc/nginx/certs/.dhparam.pem.tmp 4096
        mv /etc/nginx/certs/.dhparam.pem.tmp /etc/nginx/certs/dhparam.pem || exit 1
    fi
}

    source /app/functions.sh

    [[ $DEBUG == true ]] && set -x
    check_writable_directory '/etc/nginx/certs'
    check_writable_directory '/etc/letsencrypt'
    check_writable_directory '/etc/nginx/vhost.d'
    check_writable_directory '/usr/share/nginx/html'
    check_dh_group
    
    #Running letsencrypt once to renew existing cert and recreate link
    #Should be replace by something just copying link ! 
    rancher-gen --onetime --notify-cmd="/app/letsencrypt.sh" /app/letsencrypt.tmpl /app/letsencrypt.conf



