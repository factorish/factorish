12Fakter
========

About
-----

`12fakter` is a project I developed to make it easier to take legacy applications and make them behave like a [12factor](http://12factor.net) application.

The framework for it was based on the work by the opdemand folks on [deis](https://github.com/deis/deis) which I adapted for my [docker-percona_galera](https://github.com/paulczar/docker-percona_galera) project which aims to set up automagically clustering MySQL servers and then slowly morphed into this.

I have included a small example hello world python app which simply reads a config file and prints out the value for a field in there.   This config file is written by confd based on environment variables (by default) or etcd keys ( with a few minor changes).

You can find a good example of using this (although a much less refined version) framework to build a multi-tier application [here](https://github.com/paulczar/docker-elk_confd) and an example of making [wordpress 12fackter](https://github.com/paulczar/12fakter-wordpress)

What does it do?
----------------

`12fakter` is a is mainly a very opinionated `Vagrantfile` which spins up a development environment consisting of a number of CoreOS servers (that form an `etcd` cluster) and a helper `12fakter.rb` which contains some modifiable default variables and functions for building and launching applications which are defined in a fairly simple hash.

Launching a 12fakter development environment is as simple as running `vagrant up`.   The default cluster size is 3 VMs and as the first VM provisions it will start a private docker registry which it will use to host your images so that you only have to build or download them once.   It will then build your application as defined in the `12fakter.rb` file and will launch it on each VM.

The registry and its images are persisted on your host in `registry/` if you want `vagrant up` to automatically rebuild them you should clean that directory out by running `./clean_registry`.

If you set the mode ( either via environment variable, or setting $mode in `12fakter.rb` ) to `test` it will not try to built the Applications docker image but will instead try to download it from the docker registry.

The included example application will now be available via a port mapping so that you can interact with it:

The startup script uses a default of `father` for the environment variable of `SERVICES_EXAMPLE_TEXT` if you have not specified one.  To change the config option simply restart the docker container and set `-e SERVICES_EXAMPLE_TEXT=bacon`.

```
$ curl localhost:8080
Luke, I am your father
```

with etcd enabled you can change values live:

$ curl localhost:8080
Luke, I am your father
$ etcdctl set /service/example/text bacon
bacon
$ curl localhost:8080
Luke, I am your bacon
```

A bunch of functions are also made available to you via some userdata magic based on your application definitions which can be run inside any of the VMs.

* `start_<app name>` - start the application container
* `stop_<app_name>` - stop the application container
* `build_<app_name>` - rebuild the application image
* `<app_name>` - get a `bash` prompt inside the running container
* `cleanup` - clean up the `/services/ etcd namespace.

Example Application
===================

The example app not only gives you an easy way to check out the tooling itself, but it also provides a framework in which you can port legacy applications easily to the CoreOS/Docker ecosystem using `confd` and `etcd` to build out configs etc.

Framework
---------

* A `Dockerfile` exists which adds `etcdctl`, `confd`, and `supervisor` to the `python:2` base image and copies the local filesystem into the container as `/app` and builds the python app ready to be run.

* `confd.toml` is a config file for `confd` which tells `confd` to look at `./conf.d` and `./templates` for the templates and their metadata for configuring the application.

* `templates/supervisor.conf` is a template that `confd` writes out for `supervisor` to be able to run the application as well as `confd` itself and `bin/publish_etcd`

* `supervisor` is a lightweight python based process supervisor.  Each app that it is configured to run will send its logs/output to `stdout` of supervisor which means that you get all the benefits of a process supervisor but still keep the 12 factor style logging to stdout through to the docker logging subsystems.

* `bin/boot` the startup script for the example application.   It sets up a bunch of environment variables which can be passed in via the `docker run` comamnd to affect how the application runs,  It then runs `confd` once to do an initial configuration before running `supervisor` to start your application and other componments.

* `bin/publish_etcd` is a small script that ensures that the application is running by checking via netstat that it is listening on the expected port.  It publishes this information to `etcd` with a short TTL.  If the application fails to respond it will quickly time out and the container will destroy itself allowing for reliable service discovery of your application to other systems.

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
