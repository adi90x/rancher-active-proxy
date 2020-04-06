![nginx latest](https://img.shields.io/badge/nginx-latest-brightgreen.svg)[![build status](https://img.shields.io/gitlab/pipeline/adi90x/rancher-active-proxy/master)](https://gitlab.com/adi90x/rancher-active-proxy)  ![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)   [![Docker Pulls](https://img.shields.io/docker/pulls/adi90x/rancher-active-proxy.svg)](https://hub.docker.com/r/adi90x/rancher-active-proxy/)  [![Docker Automated buil](https://img.shields.io/docker/automated/adi90x/rancher-active-proxy.svg)](https://hub.docker.com/r/adi90x/rancher-active-proxy/)

If you look for a Kubernetes version : Have a look to [Kube Active Proxy](https://github.com/adi90x/kube-active-proxy)

## Rancher Active Proxy

Rancher Active Proxy is an all-in-one reverse proxy for [Rancher](http://rancher.com), supporting Letsencrypt out of the box !

Rancher Active Proxy is based on the excellent idea of [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy).

Rancher Active Proxy replace docker-gen by Rancher-gen-rap [adi90x/rancher-gen-rap](https://github.com/adi90x/rancher-gen-rap) ( a fork of the also excellent [janeczku/go-rancher-gen](https://github.com/janeczku/go-rancher-gen) adding some more function )

Rancher Active Proxy use label instead of environmental value.

I would recommend to use latest image from DockerHub or you can use tag versions. Keep in mind that branch are mostly development features and could not work as expected.

### Easy Setup with catalog

Add `https://github.com/adi90x/rancher-active-proxy.git` to your custom catalog list( Rancher > Admin > Settings ).

Then go to catalog and install Rancher Active Proxy !

### Usage

Minimal Params To run it:

    $ docker run -d -p 80:80  adi90x/rancher-active-proxy

Then start any containers you want proxied with a label `rap.host=subdomain.youdomain.com`

    $ docker run -l rap.host=foo.bar.com  ...

The containers being proxied must [expose](https://docs.docker.com/engine/reference/run/#expose-incoming-ports) the port to be proxied, either by using the `EXPOSE` directive in their `Dockerfile` or by using the `--expose` flag to `docker run` or `docker create`.

Provided your DNS is setup to forward foo.bar.com to the a host running `rancher-active-proxy`, the request will be routed to a container with the `rap.host` label set.

#### Summary of available labels for proxied containers.


|       Label                |            Description         |
| ---------------------------|------------------------------- |
| `rap.host`                 | Virtual host to use ( several value could be separate by `,` )
| `rap.port`                 | Port of the container to use ( only needed if several port are exposed ). Default `Expose Port` or `80`
| `rap.proto`                | Protocol used to contact container ( http,https,uwsgi ). Default : `http`
| `rap.timeout`              | Timeout for reading from this container ( in seconds ). Default : nginx default (60s)
| `rap.cert_name`            | Certificate name to use for the virtual host. Default `rap.host`
| `rap.https_method`         | Https method (redirect, noredirect, nohttps). Default : `redirect`
| `rap.le_host`              | Certificate to create/renew with Letsencrypt
| `rap.le_email`             | Email to use for Letsencrypt
| `rap.le_test  `            | Set to true to use stagging letsencrypt server
| `rap.le_bypass`            | Set to true to create a special bypass to use LE
| `rap.http_listen_ports`    | External Port you want Rancher-Active-Proxy to listen to http for this server ( Default : `80` )
| `rap.https_listen_ports`   | External Port you want Rancher-Active-Proxy to listen to https for this server ( Default : `443` )
| `rap.server_tokens`    	 | Enable to specify the server_token value per container
| `rap.client_max_body_size` | Enable to specify the client_max_body_size directive per container
| `rap.rap_name`             | If `RAP_NAME` is specified for a RAP instance only container with label value matching `RAP_NAME` value will be publish

#### Summary of environment variable available for Rancher Active Proxy.

|       Label        |            Description         |
| ------------------ | ------------------------------ |
| `DEBUG`            | Set to `true` to enable more output. Default : `False`
| `CRON`             | Cron like expression to define when certs are renew. Default : `0 2 * * *`
| `DEFAULT_HOST`     | Default Nginx host.
| `DEFAULT_EMAIL`    | Default Email for Letsencrypt.
| `RAP_DEBUG` 		 | Define Rancher-Gen-Rap verbosity (Valid values: "debug", "info", "warn", and "error"). Default: `info`
| `DEFAULT_PORT` 	 | Default port use for containers ( Default : `80` )
| `SPECIFIC_HOST` 	 | Limit RAP to only containers of a specific host name
| `RAP_NAME` 	     | If specify RAP will only publish service with `rap.rap_name = RAP_NAME`
| `ACME_INTERNAL` 	 | Enable passing ACME request to another RAP instance ( check PR #48)

#### Quick Summary of interesting volume to mount.

|       Path            |            Description         |
| --------------------- | ------------------------------ |
| `/etc/letsencrypt`    | Folder with all certificates used for https and Letsencrypt parameters
| `/etc/nginx/htpasswd` | Basic Authentication Support ( file should be `rap.host`)
| `/etc/nginx/vhost.d`  | Specifc vhost configuration ( file should be `rap.host`) . Location configuration should end with `_location`

#### Special Attention for standalone containers

Rancher Active Proxy is also able to work for standalone containers on the host it is launched.

There is only one limit to this : You should not use the same host name ( `rap.host` label ) for a standalone container and for a service.

This feature even enables you to proxy rancher-server, just start it with something like that :

`docker run -d --restart=unless-stopped -p 8080:8080 --name=rancher-server -l rap.host=admin.foo.com -l rap.port=8080 -l rap.le_host=admin.foo.com -l  rap.le_email=foo@bar.com -l io.rancher.container.pull_image=always rancher/server`

In this case `admin.foo.com` will enable you to acces rancher administration, but it is better to keep port 8080 exposed and use `http://foo.com:8080` as the host registration URL.

#### Let's Encrypt support out of box

Rancher Active Proxy is using `certbot` from Let's Encrypt in order to automatically get SSL certificates for containers.

In order to enable that feature you need to add `rap.le_host` label to the container ( you probably want it to be equal to `rap.host`)

And you should either start Rancher Active Proxy with environment variable `DEFAULT_EMAIL` or specify `rap.le_email` as a container label.

If you are developing I recommend to add `rap.le_test=true` to the container in order to use Let's Encrypt staging environment and to not exceed limits.

#### SAN certificates

Rancher Active Proxy support SAN certifcates ( one certificate for several domains ).

To create a SAN certificate you need to separate hostnames with ";" ( instead of "," for separate domains)

`rap.le_host=admin.foo.com;api.foo.com;mail.foo.com`

This will create a single certificate matching : admin.foo.com, api.foo.com, mail.foo.com .
The certificate created will be named `admin.foo.com` but symlink will be create to match all domains.


### Multiple Ports

If your container exposes multiple ports, Rancher Active Proxy will use `rap.port` label, then use the exposed port if there is only one port exposed, or default to `DEFAULT_PORT` environmental variable ( which is set by default to `80` ).
Or you can try your hand at the [Advanced `rap.host` syntax](#advanced-raphost-syntax).

### Special ByPass for Let's Encrypt

If your container uses its own letsencrypt process to get some certificates
Set `rap.le_bypass` to `true` to add a location to the http server block to forward `/.well-known/acme-certificate/` to upstream through http instead of redirecting it to https

### Advanced `rap.host` syntax

Using the Advanced `rap.host` syntax you can specify multiple host names to each go to their own backend port.
Basically this provides support for `rap.host`, `rap.port`, and `rap.proto` all in one field.

For example, given the following:

```
rap.host=api.example.com=>http:80,api-admin.example.com=>http:8001,secure.example.com=>https:8443
```

This would yield 3 different server/upstream configurations...

 1. Requests for api.example.com would route to this container's port 80 via http
 2. Requests for api-admin.example.com would route to this containers port 8001 via http
 3. Requests for secure.example.com would route to this containers port 8443 via https


### Multiple Listening Port

If needed you can use Rancher-Active-Proxy to listen for different ports.

`docker run -d -p 8081:8081 -p 81:81  adi90x/rancher-active-proxy`

In this case, you can specify on which port Rancher Active Proxy should listen for a specific hostname :

`docker run -d -l rap.host=foo.bar.com -l rap.http_listen_ports="81,8081" -l rap.port="53" containerexposing/port53`

In this situation Rancher Active Proxy will listen for request matching `rap.host` on both port `81` and `8081` of your host
and route those request to port `53` of your container.

Likewise, `rap.https_listen_ports` will work for https requests.

If you are not using port `80` and `443` at all you won't be able to use Let's Encrypt Automatic certificates.

### Specific Host Name

Using environmental value `SPECIFIC_HOST` you can limit Rancher Active Proxy to containers running on a single host.

Just start Rancher Active Proxy like that : `docker run -d -p 80:80 -e SPECIFIC_HOST=Hostnameofthehost adi90x/rancher-active-proxy`

### Remove Script

Rancher Active Proxy provides an easy script to revoke/delete a certificate.

You can run it : `docker run adi90x/rancher-active-proxy /app/remove DomainCertToRemove`

Script is adding '*' at the end of the command therefore `/app/remove foo` will delete `foo.bar.com , foo.bar.org, foo.bar2.com ..`

_Special attention_: If you are using it with SAN certificates you need to be careful and run it for each domain in the SAN certificate.

Do not forget to delete the label on the container before using that script or it will be recreated on next update.

If you are starting it with Rancher do not forget to set Auto Restart : Never (Start Once)

### Per-host server configuration

If you want to 100% personalize your server section on a per-`rap.host` basis, add your server configuration in a file under `/etc/nginx/vhost.d`
The file should use the suffix `_server`.

For example, if you have a virtual host named `app.example.com` and you have configured a proxy_cache `my-cache` in another custom file, you could tell it to use a proxy cache as follows:

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/vhost.d:/etc/nginx/vhost.d:ro adi90x/rancher-active-proxy

You should therefore have a file `app.example.com_server` in the `/etc/nginx/vhost.d` folder that contains the whole server block you want to use :

```
server {
        server_name app.example.com
        listen 80;
        access_log /var/log/nginx/access.log vhost;

        location / {
                proxy_pass http://app.example.com;
        }
}

```

If you are using multiple hostnames for a single container (e.g. `rap.host=example.com,www.example.com`), the virtual host configuration file must exist for each hostname.
If you would like to use the same configuration for multiple virtual host names, you can use a symlink.

### Per-host server default configuration

If you want most of your virtual hosts to use a default single `server` block configuration and then override it on a few specific ones, add a `/etc/nginx/vhost.d/default_server` file.
This file will be used on any virtual host which does not have a `/etc/nginx/vhost.d/{rap.host}_server` file associated with it.

### Limit RAP to some containers

If you want a RAP instance to only publish some specific containers/services, you can start the RAP container with environment variable `RAP_NAME = example`
In that situation, all containers to be published by this instance of RAP should have a label `rap.rap_name = example`
If a container should be published by several RAP instances just use a label matching regex like `rap.rap_name = internal,external` to be published by RAP instance named `internal` or `external`

***

The below part is mostly taken from jwilder/nginx-proxy [README](https://github.com/jwilder/nginx-proxy/blob/master/README.md) and modified to reflect Rancher Active Proxy

### Multiple Hosts

If you need to support multiple virtual hosts for a container, you can separate each entry with commas.  For example, `foo.bar.com,baz.bar.com,bar.com` and each host will be setup the same.

### Wildcard Hosts

You can also use wildcards at the beginning and the end of host name, like `*.bar.com` or `foo.bar.*`. Or even a regular expression, which can be very useful in conjunction with a wildcard DNS service like [xip.io](http://xip.io), using `~^foo\.bar\..*\.xip\.io` will match `foo.bar.127.0.0.1.xip.io`, `foo.bar.10.0.2.2.xip.io` and all other given IPs. More information about this topic can be found in the nginx documentation about [`server_names`](http://nginx.org/en/docs/http/server_names.html).

### SSL Backends

If you would like the reverse proxy to connect to your backend using HTTPS instead of HTTP
set `rap.proto=https` on the backend container.

### uWSGI Backends

If you would like to connect to uWSGI backend, set `rap.proto=uwsgi` on the backend container.
Your backend container should than listen on a port rather than a socket and expose that port.

### Default Host

To set the default host for nginx use the env var `DEFAULT_HOST=foo.bar.com` for example :

    $ docker run -d -p 80:80 -e DEFAULT_HOST=foo.bar.com adi90x/rancher-active-proxy

### SSL Support

SSL is supported using single host, wildcard and SNI certificates using naming conventions for certificates
or optionally specifying a cert name (for SNI) as an environment variable.

To enable SSL:

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/certs:/etc/nginx/certs  adi90x/rancher-active-proxy

The contents of `/path/to/certs` should contain the certificates and private keys for any virtual
hosts in use.  The certificate and keys should be named after the virtual host with a `.crt` and
`.key` extension.  For example, a container with label `rap.host=foo.bar.com` should have a
`foo.bar.com.crt` and `foo.bar.com.key` file in the certs directory.

If you are running the container in a virtualized environment (Hyper-V, VirtualBox, etc...),
`/path/to/certs` must exist in that environment or be made accessible to that environment.
By default, Docker is not able to mount directories on the host machine to containers running in a virtual machine.

### Diffie-Hellman Groups

If you have Diffie-Hellman groups enabled, the files should be named after the virtual host with a
`dhparam` suffix and `.pem` extension. For example, a container with `rap.host=foo.bar.com`
should have a `foo.bar.com.dhparam.pem` file in the certs directory.

### Wildcard Certificates

Wildcard certificates and keys should be named after the domain name with a `.crt` and `.key` extension.
For example `rap.host=foo.bar.com` would use cert name `bar.com.crt` and `bar.com.key`.

### SNI

If your certificate(s) supports multiple domain names, you can start a container with `rap.cert_name=<name>`
to identify the certificate to be used.  For example, a certificate for `*.foo.com` and `*.bar.com`
could be named `shared.crt` and `shared.key`.  A container running with `rap.host=foo.bar.com`
and `rap.cert_name=shared` will then use this shared cert.

### How SSL Support Works

The SSL cipher configuration is based on [mozilla nginx intermediate profile](https://wiki.mozilla.org/Security/Server_Side_TLS#Nginx) which
should provide compatibility with clients back to Firefox 1, Chrome 1, IE 7, Opera 5, Safari 1,
Windows XP IE8, Android 2.3, Java 7.  The configuration also enables HSTS, and SSL
session caches.

The default behavior for the proxy when port 80 and 443 are exposed is as follows:

* If a container has a usable cert, port 80 will redirect to 443 for that container so that HTTPS
is always preferred when available.
* If the container does not have a usable cert, a 503 will be returned.

Note that in the latter case, a browser may get an connection error as no certificate is available
to establish a connection.  A self-signed or generic cert named `default.crt` and `default.key`
will allow a client browser to make a SSL connection (likely w/ a warning) and subsequently receive
a 503.

To serve traffic in both SSL and non-SSL modes without redirecting to SSL, you can include the
label  `rap.https_method=noredirect` (the default is `rap.https_method=redirect`).  You can also
disable the non-SSL site entirely with `rap.https_method=nohttp`. `rap.https_method` must be specified
on each container for which you want to override the default behavior.  If `rap.https_method=noredirect` is
used, Strict Transport Security (HSTS) is disabled to prevent HTTPS users from being redirected by the
client.  If you cannot get to the HTTP site after changing this setting, your browser has probably cached
the HSTS policy and is automatically redirecting you back to HTTPS.  You will need to clear your browser's
HSTS cache or use an incognito window / different browser.

### Basic Authentication Support

In order to be able to secure your virtual host, you have to create a file named as its equivalent `rap.host` label on directory
/etc/nginx/htpasswd/`rap.host`

```
$ docker run -d -p 80:80 -p 443:443 \
    -v /path/to/htpasswd:/etc/nginx/htpasswd \
    -v /path/to/certs:/etc/nginx/certs \
    adi90x/rancher-active-proxy
```

You'll need apache2-utils on the machine where you plan to create the htpasswd file.
Or you can use an nginx container to create the file ( using OpenSSL as explained in [Nginx Readme](http://wiki.nginx.org/Faq#How_do_I_generate_an_.htpasswd_file_without_having_Apache_tools_installed.3F) )

`docker run -it nginx printf "Username_to_use:$(openssl passwd -crypt Password_to_use)\n" >> /path/to/htpasswd/{rap.host}`

A default htpasswd can be used to secure all hosts using this proxy. Good for development environments to keep prying eyes out. To use, create the htpasswd file named 'default' here: `/etc/nginx/htpasswd/default`.

### Custom Nginx Configuration

If you need to configure Nginx beyond what is possible using environment variables, you can provide custom configuration files on either a proxy-wide or per-`rap.host` basis.

### Replacing default proxy settings

If you want to replace the default proxy settings for the nginx container, add a configuration file at `/etc/nginx/proxy.conf`. A file with the default settings would
look like this:

```Nginx
# HTTP 1.1 support
proxy_http_version 1.1;
proxy_buffering off;
proxy_set_header Host $http_host;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $proxy_connection;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
proxy_set_header X-Forwarded-Port $proxy_x_forwarded_port;

# Mitigate httpoxy attack (see README for details)
proxy_set_header Proxy "";
```

***NOTE***: If you provide this file it will replace the defaults; you may want to check the nginx.tmpl file to make sure you have all of the needed options.

***NOTE***: The default configuration blocks the `Proxy` HTTP request header from being sent to downstream servers.  This prevents attackers from using the so-called [httpoxy attack](http://httpoxy.org).  There is no legitimate reason for a client to send this header, and there are many vulnerable languages / platforms (`CVE-2016-5385`, `CVE-2016-5386`, `CVE-2016-5387`, `CVE-2016-5388`, `CVE-2016-1000109`, `CVE-2016-1000110`, `CERT-VU#797896`).

### Proxy-wide

To add settings on a proxy-wide basis, add your configuration file under `/etc/nginx/conf.d` using a name ending in `.conf`.

This can be done in a derived image by creating the file in a `RUN` command or by `COPY`ing the file into `conf.d`:

```Dockerfile
FROM adi90x/rancher-active-proxy
RUN { \
      echo 'server_tokens off;'; \
      echo 'client_max_body_size 100m;'; \
    } > /etc/nginx/conf.d/my_proxy.conf
```

Or it can be done by mounting in your custom configuration in your `docker run` command:

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/my_proxy.conf:/etc/nginx/conf.d/my_proxy.conf:ro adi90x/rancher-active-proxy

### Per-VIRTUAL_HOST

To add settings on a per-`rap.host` basis, add your configuration file under `/etc/nginx/vhost.d`. Unlike in the proxy-wide case, which allows multiple config files with any name ending in `.conf`, the per-`rap.host` file must be named exactly after the `rap.host`.

In order to allow virtual hosts to be dynamically configured as backends are added and removed, it makes the most sense to mount an external directory as `/etc/nginx/vhost.d` as opposed to using derived images or mounting individual configuration files.

For example, if you have a virtual host named `app.example.com`, you could provide a custom configuration for that host as follows:

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/vhost.d:/etc/nginx/vhost.d:ro adi90x/rancher-active-proxy
    $ { echo 'server_tokens off;'; echo 'client_max_body_size 100m;'; } > /path/to/vhost.d/app.example.com

If you are using multiple hostnames for a single container (e.g. `rap.host=example.com,www.example.com`), the virtual host configuration file must exist for each hostname. If you would like to use the same configuration for multiple virtual host names, you can use a symlink:

    $ { echo 'server_tokens off;'; echo 'client_max_body_size 100m;'; } > /path/to/vhost.d/www.example.com
    $ ln -s /path/to/vhost.d/www.example.com /path/to/vhost.d/example.com

### Per-VIRTUAL_HOST default configuration

If you want most of your virtual hosts to use a default single configuration and then override on a few specific ones, add those settings to the `/etc/nginx/vhost.d/default` file. This file
will be used on any virtual host which does not have a `/etc/nginx/vhost.d/{rap.host}` file associated with it.

### Per-VIRTUAL_HOST location configuration

To add settings to the "location" block on a per-`rap.host` basis, add your configuration file under `/etc/nginx/vhost.d`
just like the previous section except with the suffix `_location`.

For example, if you have a virtual host named `app.example.com` and you have configured a proxy_cache `my-cache` in another custom file, you could tell it to use a proxy cache as follows:

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/vhost.d:/etc/nginx/vhost.d:ro adi90x/rancher-active-proxy
    $ { echo 'proxy_cache my-cache;'; echo 'proxy_cache_valid  200 302  60m;'; echo 'proxy_cache_valid  404 1m;' } > /path/to/vhost.d/app.example.com_location

If you are using multiple hostnames for a single container (e.g. `rap.host=example.com,www.example.com`), the virtual host configuration file must exist for each hostname. If you would like to use the same configuration for multiple virtual host names, you can use a symlink:

    $ { echo 'proxy_cache my-cache;'; echo 'proxy_cache_valid  200 302  60m;'; echo 'proxy_cache_valid  404 1m;' } > /path/to/vhost.d/app.example.com_location
    $ ln -s /path/to/vhost.d/www.example.com /path/to/vhost.d/example.com

### Per-VIRTUAL_HOST location default configuration

If you want most of your virtual hosts to use a default single `location` block configuration and then override on a few specific ones, add those settings to the `/etc/nginx/vhost.d/default_location` file. This file
will be used on any virtual host which does not have a `/etc/nginx/vhost.d/{rap.host}` file associated with it.

## Contributing

Do not hesitate to send issues or pull requests !

Automated Gitlab CI is used to build Rancher Active Proxy therefore send any pull request/issues to [Rancher Active Proxy on Gitlab.com](https://gitlab.com/adi90x/rancher-active-proxy/)
