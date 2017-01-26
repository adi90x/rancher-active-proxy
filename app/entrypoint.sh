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
    unset LETSENCRYPT_CONTAINERS
    source /app/functions.sh

    [[ $DEBUG == true ]] && set -x
    check_writable_directory '/etc/nginx/certs'
    check_writable_directory '/etc/letsencrypt'
    check_writable_directory '/etc/nginx/vhost.d'
    check_writable_directory '/usr/share/nginx/html'
    check_dh_group
    
    #Recreating needed certs
    rancher-gen --onetime /app/letsencrypt.tmpl /app/letsencrypt.conf

    source /app/letsencrypt.conf

    if [[ -s /app/letsencrypt.conf ]] && [[ ${LETSENCRYPT_CONTAINERS:-"EMPTY"} != "EMPTY" ]]; then

    for cid in "${LETSENCRYPT_CONTAINERS[@]}"; do
    
    host_varname="LETSENCRYPT_${cid}_HOST"
    hosts_array=$host_varname[@]
    hosts_array_expanded=("${!hosts_array}")
    base_domain="${hosts_array_expanded[0]}"
    listdomain=${base_domain//;/$'\n'}
    domarray=( $listdomain )
	certname=${domarray[0]}
	for dom in $listdomain; do
		setup_certs $dom $certname
	done
	domainparam=""
    done
    
    fi
    
    #Deleting default.conf if it is there
    rm -f /etc/nginx/conf.d/default.conf
    
    #Setting up crontab value 
    rm /etc/crontabs/root
    : ${CRON="0 2 * * *"}
    (crontab -l 2>/dev/null; echo "$CRON /app/letsencrypt.sh") | crontab -
	
	exec "$@"
