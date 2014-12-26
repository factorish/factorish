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

$applications = [
  {
    name: "confd_example_app",
    repository: "paulczar/confd_example_app",
    docker_options: "-p 8080:8080 -e PUBLISH=8080 -e HOST=$COREOS_PRIVATE_IPV4",
    dockerfile: "/home/core/share"
  }
]

def core01_start_registry()
  $core01_start_registry=<<-EOF
    echo Creating a Private Registry
    curl -s 10.0.2.2:5000 > /dev/null 2>&1
    if [ $? == 0 ]; then
      echo "Looks like you already have a registry running"
    else
      if [[ -e /home/core/share/registry/registry.tgz ]]; then
        docker images registry | grep registry > /dev/null || \
          docker load < /home/core/share/registry/registry.tgz > /dev/null 2>&1
      else
        docker pull registry > /dev/null
        docker save registry > /home/core/share/registry/registry.tgz
      fi
      curl -s 10.0.2.2:5000 || docker run -d -p 5000:5000 -e GUNICORN_OPTS=[--preload] \
        -e search_backend= -v /home/core/share/registry:/tmp/registry registry
      sleep 10
    fi
  EOF
end

def core01_build_image(app)
  $core01_build_image=<<-EOF
    echo Building application image
    docker pull 10.0.2.2:5000/#{app[:repository]} > /dev/null || \
      docker build -t 10.0.2.2:5000/#{app[:repository]} #{app[:dockerfile]} && \
      docker push 10.0.2.2:5000/#{app[:repository]} && \
      docker tag 10.0.2.2:5000/#{app[:repository]} #{app[:repository]}
  EOF
end

def core01_fetch_image(app)
  $core01_fetch_image=<<-EOF
    echo Fetching application image
      docker pull 10.0.2.2:5000/#{app[:repository]} > /dev/null || \
      docker pull #{app[:repository]} > /dev/null && \
      docker tag #{app[:repository]} 10.0.2.2:5000/#{app[:repository]} && \
      docker push 10.0.2.2:5000/#{app[:repository]}
  EOF
end

def fetch_image(app)
  $fetch_image=<<-EOF
    echo fetching images.  This may take some time.
    echo - example ...
    docker pull 10.0.2.2:5000/#{app[:repository]} > /dev/null && \
      docker tag 10.0.2.2:5000/#{app[:repository]} #{app[:repository]}
  EOF
end

def run_image(app)
  $run_image=<<-EOF
    eval `cat /etc/environment | sed "s/^/export /"`
    echo "Running example"
    docker run  -d  #{app[:docker_options]} --name #{app[:name]} #{app[:repository]} || \
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