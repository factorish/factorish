# This file creates a container that runs Database (Percona) with Galera Replication.
#
# Author: Paul Czarkowski
# Date: 08/16/2014

FROM python:2
MAINTAINER Paul Czarkowski "paul@paulcz.net"

# Define working directory.
WORKDIR /app

# Define default command.
CMD ["/app/bin/boot"]

# Expose ports.
EXPOSE 8080

# Base Deps
RUN \
  apt-get update && apt-get install -yq \
  make \
  ca-certificates \
  net-tools \
  sudo \
  wget \
  curl \
  vim \
  strace \
  lsof \
  netcat \
  lsb-release \
  locales \
  socat \
  runit \
  --no-install-recommends && \
  locale-gen en_US.UTF-8 && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# install etcdctl and confd
RUN \
  curl -sSL -o /usr/local/bin/etcdctl https://s3-us-west-2.amazonaws.com/opdemand/etcdctl-v0.4.6 \
  && chmod +x /usr/local/bin/etcdctl \
  && curl -sSL -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v0.7.1/confd-0.7.1-linux-amd64 \
  && chmod +x /usr/local/bin/confd

ADD . /app

RUN \
  useradd -d /app -c 'application' -s '/bin/false' app && \
  chmod +x /app/bin/* && \
  pip install -r /app/example/requirements.txt

