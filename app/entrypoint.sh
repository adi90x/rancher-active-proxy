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
    if [[ ! -f /etc/letsencrypt/dhparam.pem ]]; then
        echo "Creating Diffie-Hellman group (can take several minutes...)"
        openssl dhparam -dsaparam -out /etc/letsencrypt/.dhparam.pem.tmp 4096
        mv /etc/letsencrypt/.dhparam.pem.tmp /etc/letsencrypt/dhparam.pem || exit 1
    fi
}

    source /app/functions.sh

    [[ $DEBUG == true ]] && set -x
    check_writable_directory '/etc/nginx/certs'
    check_writable_directory '/etc/letsencrypt'
    check_writable_directory '/etc/nginx/vhost.d'
    check_writable_directory '/usr/share/nginx/html'
    check_dh_group
    
    #Recreating existing certs link
    if [[ -d "/etc/letsencrypt/live/" ]]; then
    for dom in $(find /etc/letsencrypt/live/* -type d); do
        setup_certs `basename ${dom}`
    done
    fi
    
    #Setting up crontab value 
    rm /etc/crontabs/root
    : ${CRON="0 2 * * *"}
    (crontab -l 2>/dev/null; echo "$CRON /app/letsencrypt.sh") | crontab -

