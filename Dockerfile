FROM nginx:1.11.6-alpine
MAINTAINER Adrien M amaurel90@gmail.com

RUN apk add --no-cache ca-certificates curl unzip bash procps jq tar

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

RUN wget "https://gitlab.com/adi90x/rancher-gen-rap/builds/artifacts/master/download?job=compile-go" > /tmp/rancher-gen-rap.zip \
	&& unzip /tmp/rancher-gen-rap.zip -d /usr/local/bin \
	&& chmod +x /usr/local/bin/rancher-gen \
	&& rm -f /tmp/rancher-gen-rap.zip
	
COPY . /app/
COPY /app/ /app/
WORKDIR /app/

RUN chmod +x /app/start.sh && chmod +x /app/update_certs && chmod +x /app/letsencrypt_service


# Install simp_le program
COPY /install_simp_le.sh /app/install_simp_le.sh
RUN chmod +rx /app/install_simp_le.sh && sync && /app/install_simp_le.sh && rm -f /app/install_simp_le.sh

VOLUME ["/etc/nginx/certs"]

ENV DEBUG=true              \
	DOCKER_GEN_VERSION=0.7.3 \
	DOCKER_HOST=unix:///var/run/docker.sock

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh" ]
CMD ["forego", "start", "-r"]
