# Setting for VirtualBox VMs
#$vb_gui = false
$vb_memory = 512
$vb_cpus = 1

# Core OS Channel
# alpha, beta, stable
$coreos_channel = 'beta'

# Size of the CoreOS cluster created by Vagrant
if ENV['instances']
  $num_instances = ENV['instances'].to_i
else
  $num_instances = 3
end

# Expose Docker / ETCD ports.
# If there ar more than one VM, will autocorrect to avoid conflicts.
$expose_docker_tcp = 4243
$expose_etcd_tcp = 4001
$expose_registry = 5000

# Expose custom application ports.
# array of ports to be exposed for your applications.
$expose_ports=[8080]

# Mode to start in.
# `develop` will build images from scratch
# `test` will try to download from registry
$mode = ENV['mode'] ||= 'develop' # develop|test

if ENV['DEBUG']
  @debug = "set -x"
else
  @debug = ""
end

# Infrastructure containers such as docker registry
@services = [
  {
    name: "registrator",
    repository: "progrium/registrator",
    docker_options: [
      "-v /var/run/docker.sock:/tmp/docker.sock:ro",
      "-h $HOSTNAME",
      "--name registrator"
    ],
    command: "-ttl 30 -ttl-refresh 20 -ip $COREOS_PRIVATE_IPV4 etcd://$COREOS_PRIVATE_IPV4:4001/services"
  }
]


# Describe your applications in this hash
@applications = [
  {
    name: "example",
    repository: "factorish/example",
    docker_options: [
      "-p 8080:8080",
      "-e PUBLISH=8080",
      "-e HOST=$COREOS_PRIVATE_IPV4"
    ],
    dockerfile: "/home/core/share/example",
    command: ""
  }
]


def core01_start_registry()
  $core01_start_registry=<<-EOF
    #{@debug}
    echo Creating a Private Registry
    if [[ -n $(netstat -lnt | grep ":5000 ") ]]; then
      echo - Looks like you already have a registry running
    else
      if [[ -e /home/core/share/registry/registry.tgz ]]; then
        echo - Loading registry from host cache...
        docker images registry | grep registry > /dev/null || \
          docker load < /home/core/share/registry/registry.tgz > /dev/null 2>&1
      else
        echo - Pulling registry from docker hub...
        docker pull registry > /dev/null
        docker save registry > /home/core/share/registry/registry.tgz
      fi
      docker run -d -p 5000:5000 -e GUNICORN_OPTS=[--preload] --name registry \
        -e search_backend= -v /home/core/share/registry:/tmp/registry registry
      sleep 10
    fi
  EOF
end

def core01_build_image(app)
  $core01_build_image=<<-EOF
    #{@debug}
    echo Building #{app[:repository]} image
    docker pull 10.0.2.2:5000/#{app[:repository]} > /dev/null 2>&1
    if [[ $? != 0 ]]; then
      docker build -t 10.0.2.2:5000/#{app[:repository]} #{app[:dockerfile]}
      docker push 10.0.2.2:5000/#{app[:repository]}
    else
      echo - #{app[:repository]} pulled from private registry.
      echo - run ./clean_registry if you expected this to rebuild.
    fi
    docker tag 10.0.2.2:5000/#{app[:repository]} #{app[:repository]}
  EOF
end

def core01_fetch_image(app)
  $core01_fetch_image=<<-EOF
    #{@debug}
    echo Fetching #{app[:repository]} This may take some time.
      docker pull 10.0.2.2:5000/#{app[:repository]} > /dev/null 2>&1
      if [[ $? != 0 ]]; then
        if [[ -e /home/core/share/registry/#{app[:name]}.tgz ]]; then
          echo - Loading #{app[:repository]} from host cache...
          docker images #{app[:repository]} | grep '#{app[:repository]}' > /dev/null || \
            docker load < /home/core/share/registry/#{app[:name]}.tgz > /dev/null 2>&1
        else
          echo - Pulling #{app[:repository]} from docker hub...
          docker pull #{app[:repository]} > /dev/null
          docker save #{app[:repository]} > /home/core/share/registry/#{app[:name]}.tgz
        fi
        docker tag #{app[:repository]} 10.0.2.2:5000/#{app[:repository]} > /dev/null
        docker push 10.0.2.2:5000/#{app[:repository]} > /dev/null
      else
        docker tag 10.0.2.2:5000/#{app[:repository]} #{app[:repository]}
      fi
  EOF
end

def fetch_image(app)
  $fetch_image=<<-EOF
    #{@debug}
    echo fetching #{app[:repository]}.  This may take some time.
    docker pull 10.0.2.2:5000/#{app[:repository]} > /dev/null && \
      docker tag 10.0.2.2:5000/#{app[:repository]} #{app[:repository]}
  EOF
end

def run_image(app)
  $run_image=<<-EOF
    #{@debug}
    eval `cat /etc/environment | sed "s/^/export /"`
    echo "Running #{app[:repository]}"
    docker run  -d  #{app[:docker_options].join(' ')} --name #{app[:name]} #{app[:repository]} #{app[:command]} || \
    echo is it already running?
  EOF
end

def write_user_data(num_instances)
  require 'erb'
  require 'net/http'
  require 'uri'
  if $num_instances == 1
    @etcd_discovery = '# single node no discovery needed.'
  else
    @etcd_discovery = "discovery: #{Net::HTTP.get(URI.parse('http://discovery.etcd.io/new'))}"
  end
  template = File.join(File.dirname(__FILE__), 'user-data.erb')
  target = File.join(File.dirname(__FILE__), 'user-data')
  content = ERB.new File.new(template).read
  File.open(target, 'w') { |f| f.write(content.result(binding)) }
end

unless ENV['nodisco']
  if ARGV.include? 'up'
    puts 'rewriting userdata'
    write_user_data($num_instances)
  end
end