[[ -z "${VHOST_DIR:-}" ]] && \
 declare -r VHOST_DIR=/etc/nginx/vhost.d
[[ -z "${START_HEADER:-}" ]] && \
 declare -r START_HEADER='## Start of configuration add by letsencrypt container'
[[ -z "${END_HEADER:-}" ]] && \
 declare -r END_HEADER='## End of configuration add by letsencrypt container'

add_location_configuration() {
    local domain="${1:-}"
    [[ -z "$domain" || ! -f "${VHOST_DIR}/${domain}" ]] && domain=default
    [[ -f "${VHOST_DIR}/${domain}" && \
       -n $(sed -n "/$START_HEADER/,/$END_HEADER/p" "${VHOST_DIR}/${domain}") ]] && return 0
    echo "$START_HEADER" > "${VHOST_DIR}/${domain}".new
    cat /app/nginx_location.conf >> "${VHOST_DIR}/${domain}".new
    echo "$END_HEADER" >> "${VHOST_DIR}/${domain}".new
    [[ -f "${VHOST_DIR}/${domain}" ]] && cat "${VHOST_DIR}/${domain}" >> "${VHOST_DIR}/${domain}".new
    mv -f "${VHOST_DIR}/${domain}".new "${VHOST_DIR}/${domain}"
    return 1
}

remove_all_location_configurations() {
    local old_shopt_options=$(shopt -p) # Backup shopt options
    shopt -s nullglob
    for file in "${VHOST_DIR}"/*; do
        [[ -n $(sed -n "/$START_HEADER/,/$END_HEADER/p" "$file") ]] && \
         sed -i "/$START_HEADER/,/$END_HEADER/d" "$file"
    done
    eval "$old_shopt_options" # Restore shopt options
}
##Setup new certs
setup_certs() {
#Create cert link  and add dhparam key
local dom="${1:-}"
local certname="${2:-}"
if [  -e /etc/letsencrypt/live/$certname/privkey.pem ] && [ -e /etc/letsencrypt/live/$certname/fullchain.pem ]; then
    ln -sf /etc/letsencrypt/live/$certname/privkey.pem /etc/nginx/certs/$dom.key
    ln -sf /etc/letsencrypt/live/$certname/fullchain.pem /etc/nginx/certs/$dom.crt
    ln -sf /etc/letsencrypt/dhparam.pem /etc/nginx/certs/$dom.dhparam.pem
fi

}


## Nginx
reload_nginx() {
#Delete file to avoid looping problem
rm -f /etc/nginx/conf.d/default.conf
#Rerun rancher-gen to recreate a new nginx config file 
rancher-gen --onetime --notify-cmd="nginx -s reload" --check-cmd="nginx -t " /app/nginx.tmpl /etc/nginx/conf.d/default.conf
}

# Convert argument to lowercase (bash 4 only)
function lc() {
	echo "${@,,}"
}


create_link() {
    local readonly target=${1?missing target argument}
    local readonly source=${2?missing source argument}
    [[ -f "$target" ]] && return 1
    ln -sf "$source" "$target"
}

create_links() {
    local readonly base_domain=${1?missing base_domain argument}
    local readonly domain=${2?missing base_domain argument}
    if [[ ! -f "/etc/nginx/certs/$base_domain"/fullchain.pem || \
          ! -f "/etc/nginx/certs/$base_domain"/key.pem ]]; then
        return 1
    fi
    local return_code=1
    create_link "/etc/nginx/certs/$domain".crt "./$base_domain"/fullchain.pem
    return_code=$(( $return_code & $? ))
    create_link "/etc/nginx/certs/$domain".key "./$base_domain"/key.pem
    return_code=$(( $return_code & $? ))
    if [[ -f "/etc/nginx/certs/dhparam.pem" ]]; then
        create_link "/etc/nginx/certs/$domain".dhparam.pem ./dhparam.pem
        return_code=$(( $return_code & $? ))
    fi
    return $return_code
}
