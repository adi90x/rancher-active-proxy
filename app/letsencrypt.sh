#!/bin/bash

source /app/functions.sh

update_certs() {

    [[ ! -f /app/letsencrypt.conf ]] && return

    # Load relevant container settings
    unset LETSENCRYPT_CONTAINERS
    source /app/letsencrypt.conf

    for cid in "${LETSENCRYPT_CONTAINERS[@]}"; do

	# Derive host and email variable names
        host_varname="LETSENCRYPT_${cid}_HOST"

        # Array variable indirection hack: http://stackoverflow.com/a/25880676/350221
        hosts_array=$host_varname[@]
        email_varname="LETSENCRYPT_${cid}_EMAIL"
        test_certificate_varname="LETSENCRYPT_${cid}_TEST"

        if [[ $(lc "${!test_certificate_varname:-}") == true ]]; then
            acme_server="--staging"
        else
            acme_server=""
        fi
        
        echo "Using Acme server $acme_server"
        
        debug=""
        [[ $DEBUG == true ]] && debug+=" -v"

        hosts_array_expanded=("${!hosts_array}")

        # First domain will be our base domain
        base_domain="${hosts_array_expanded[0]}"

	#Just in case
	mkdir -p /etc/nginx/vhost.d && mkdir -p /usr/share/nginx/html
	
    # Add location configuration for the domain
    add_location_configuration "$domain"

	#Reload Nginx once location added
	reload_nginx

    echo "Creating/renewal $base_domain certificates... (${hosts_array_expanded[*]})"

	certbot certonly --agree-tos $debug $acme_server  \
		-m ${!email_varname} -n -d $base_domain \
		--webroot -w /usr/share/nginx/html
	    
	 echo " "

	setup_certs $base_domain		
    done
	
    reload_nginx
}

update_certs

