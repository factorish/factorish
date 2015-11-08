# This file creates a container that runs Database (Percona) with Galera Replication.
#
# Author: Paul Czarkowski
# Date: 08/16/2014

FROM alpine
MAINTAINER Paul Czarkowski "paul@paulcz.net"

# Define working directory.
WORKDIR /app

# Define default command.
CMD ["/app/bin/boot"]

# Expose ports.
EXPOSE 8080

# Base Deps
RUN \
    apk upgrade && \
    apk update && \
    apk add runit bash curl python \ 
        --update-cache \
        --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
        --allow-untrusted && \
    mkdir -pv /etc/sv && \ 
    mkdir -pv /etc/service && \
    ln -sv /etc/service /service && \
    adduser -D app && \
  curl -sSL https://bootstrap.pypa.io/get-pip.py | python

# install etcdctl and confd
RUN \
  curl -sSL -o /usr/local/bin/etcdctl https://s3-us-west-2.amazonaws.com/opdemand/etcdctl-v0.4.6 \
  && chmod +x /usr/local/bin/etcdctl \
  && curl -sSL -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v0.7.1/confd-0.7.1-linux-amd64 \
  && chmod +x /usr/local/bin/confd 
  

ADD . /app

RUN \
  chmod +x /app/bin/* && \
  pip install -r /app/example/requirements.txt

