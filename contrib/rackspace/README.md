Deploying to Rackspace OnMetal
==============================

Install Heat
------------

Ensure you have heat installed:

```console
$ sudo pip install python-heatclient
```

Set up your environment:

```console
export OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
export OS_AUTH_SYSTEM=rackspace
export OS_REGION_NAME=IAD
export OS_USERNAME=????
export OS_TENANT_NAME=????
export NOVA_RAX_AUTH=1
export OS_PASSWORD=?????
export OS_PROJECT_ID=${OS_TENANT_NAME}
export OS_TENANT_ID=${OS_TENANT_NAME}
export OS_NO_CACHE=1
export HEAT_URL="https://iad.orchestration.api.rackspacecloud.com/v1/${OS_TENANT_ID}"

```

Deploy from Heat Template
-------------------------

Deploy a three node MySQL onto Rackspace OnMetal IO flavor:

```console
$ heat stack-create MySQL --template-file=contrib/rackspace/heat-vm.yaml \
 -P count=3 -P etcd_discovery=$(curl -s https://discovery.etcd.io/new)
```

Deploy a three node MySQL onto Rackspace VM flavor:

```console
$ heat stack-create MySQL --template-file=contrib/rackspace/heat-onmetal-io.yaml \
 -P count=3 -P etcd_discovery=$(curl -s https://discovery.etcd.io/new)
```

Log into CoreOS
---------------

```console
$ eval `ssh-agent`
$ echo $(heat output-show MySQL private_key | sed 's/"//g') | ssh-add -
$ export LB=$(heat output-show MySQL loadbalancer | sed 's/"//g') && echo $LB
$ mysql -h $LB -u admin -padmin -e "show status like 'wsrep_cluster%'"
```
