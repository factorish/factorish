Docker ETCD App
===============

The purpose of this repo is to provide a skeleton framework for making existing apps use
etcd/confd to automatically configure themselves with minimal user interaction.

It is based on the work by the opdemand folks on [deis](https://github.com/deis/deis) which uses similar concepts to set up its infrastructure.

Framework
=========

Infrastructure
--------------

* A base Dockerfile is included which will build a simple Ubuntu image with some extra tooling to support etcd and confd.
* A Vagrantfile is included to help build a CoreOS cluster for testing your app against.
* An application startup script is provided in `bin/boot` as well some some function files to help.

ETCD
----

ETCD is used to store key:value pairs that can be used by the startup script and confd.

CONFD
-----

ConfD is a templating language that can build configs for your app based on data found in ETCD ( or Consul ).

Templates are put in `templates/` and confd config for each template is stored in `conf.d/`.



Development
-----------

You can use vagrant in developer mode which will install the service but not run it.  it will also enable debug mode on the start script, share the local path into `/home/coreos/share` via `nfs` and build the image locally.   This takes quite a while as it builds the image on each VM, but once its up further rebuilds should be quick thanks to the caches.

    $ dev=1 vagrant up
    $ vagrant ssh core-01


Author(s)
======

Paul Czarkowski (paul@paulcz.net)

License
=======

Copyright 2014 Paul Czarkowski

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
