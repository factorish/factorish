FROM google/golang:latest

RUN apt-get -yqq update && apt-get -yqq install bc ssh vim

RUN cd /root && \
  git clone https://github.com/coreos/fleet.git && \
  cd fleet && \
  git checkout v0.5.0 && \
  ./build && \
  mv bin/fleetctl /usr/bin/fleetctl

RUN cd /root && \
  git clone https://github.com/coreos/etcdctl.git && \
  cd etcdctl && \
  ./build && \
  mv bin/etcdctl /usr/bin/etcdctl

ADD . /installer

RUN chmod +x /installer/install

CMD /installer/install

