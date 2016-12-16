FROM nginx:1.11.6-alpine
MAINTAINER Adrien M amaurel90@gmail.com

RUN apk add --no-cache ca-certificates curl unzip bash wget

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

RUN wget "https://gitlab.com/adi90x/rancher-gen-rap/builds/artifacts/master/download?job=compile-go" -O /tmp/rancher-gen-rap.zip \
	&& unzip /tmp/rancher-gen-rap.zip -d /usr/local/bin \
	&& chmod +x /usr/local/bin/rancher-gen \
	&& rm -f /tmp/rancher-gen-rap.zip
	
COPY . /app/
WORKDIR /app/

VOLUME ["/etc/nginx/certs"]

CMD ["forego", "start", "-r"]
