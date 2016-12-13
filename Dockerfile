FROM nginx:1.11.6-alpine
MAINTAINER Adrien M amaurel90@gmail.com

RUN apk add --no-cache ca-certificates
RUN apk add --no-cache curl
RUN apk add --no-cache unzip
RUN apk add --no-cache bash
 
# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

ARG TOKEN_RANCHER_GEN

RUN curl --header "PRIVATE-TOKEN: $TOKEN_RANCHER_GEN" "https://gitlab.com/api/v3/projects/2130165/builds/artifacts/master/download?job=compile-go" > /tmp/rancher-gen-rap.zip \
	&& unzip /tmp/rancher-gen-rap.zip -d /usr/local/bin \
	&& chmod +x /usr/local/bin/rancher-gen
	
COPY . /app/
WORKDIR /app/

VOLUME ["/etc/nginx/certs"]

CMD ["forego", "start", "-r"]
