FROM nginx:1.11.6-alpine
MAINTAINER Adrien M amaurel90@gmail.com

# Install wget and install/updates certificates
#RUN apt-get update \
# && apt-get install -y -q --no-install-recommends \
#    ca-certificates \
#	unzip \
#    curl \
# && apt-get clean \
# && rm -r /var/lib/apt/lists/*

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

ENV DOCKER_GEN_VERSION 0.7.3

#RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
# && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
# && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

RUN curl --header "PRIVATE-TOKEN: pVnt_WmN-qYp7TZUKiyo" "https://gitlab.com/api/v3/projects/2130165/builds/artifacts/master/download?job=compile-go" > /tmp/rancher-gen-rap.zip \
	&& unzip /tmp/rancher-gen-rap.zip -d /usr/local/bin \
	&& chmod +x /usr/local/bin/rancher-gen
	
COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs"]

#ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
