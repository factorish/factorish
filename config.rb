# Setting for VirtualBox VMs
#$vb_gui = false
$vb_memory = 512
$vb_cpus = 1

# Core OS Channel
# beta, alpha, production
$coreos_channel = 'beta'

# Size of the CoreOS cluster created by Vagrant
$num_instances=3

# Expose Docker / ETCD ports.
# If there ar more than one VM, will autocorrect to avoid conflicts.
$expose_docker_tcp=4243
$expose_etcd_tcp=4001
$expose_registry=5000

# Expose custom application ports.
# array of ports to be exposed for your applications.
$expose_ports=[8080]

# Mode to start in.
# `develop` will build images from scratch
# `test` will try to download from registry
$mode = ENV['mode'] ||= 'develop' # develop|test

$core01_start_registry=<<-EOF
  echo Creating a Private Registry
  if [[ -e /home/core/share/registry/registry.tgz ]]; then
    docker images registry | grep registry > /dev/null || docker load < /home/core/share/registry/registry.tgz
  else
    docker pull registry > /dev/null
    docker save registry > /home/core/share/registry/registry.tgz
  fi
  curl -s 10.0.2.2:5000 || docker run -d -p 5000:5000 -e GUNICORN_OPTS=[--preload] -e search_backend= -v /home/core/share/registry:/tmp/registry registry
  sleep 10
EOF

$core01_build_image=<<-EOF
  echo Building application image
  docker pull 10.0.2.2:5000/paulczar/example > /dev/null || \
    docker build -t 10.0.2.2:5000/paulczar/example /home/core/share && \
    docker push 10.0.2.2:5000/paulczar/example && \
    docker tag 10.0.2.2:5000/paulczar/example paulczar/example
EOF

$core01_fetch_image=<<-EOF
  echo Fetching applocation image
    docker pull 10.0.2.2:5000/paulczar/example > /dev/null || \
    docker pull paulczar/example > /dev/null && \
    docker tag paulczar/example 10.0.2.2:5000/paulczar/example && \
    docker push 10.0.2.2:5000/paulczar/example
EOF

$fetch_image=<<-EOF
  echo fetching images.  This may take some time.
  echo - example ...
  docker pull 10.0.2.2:5000/paulczar/example > /dev/null && \
    docker tag 10.0.2.2:5000/paulczar/example paulczar/example
EOF

$run_image=<<-EOF
  eval `cat /etc/environment | sed "s/^/export /"`
  echo "Running example"
  docker run  -d  -p 8080:8080 -e PUBLISH=8080 \
    -e HOST=$COREOS_PRIVATE_IPV4 --name example paulczar/example || \
  echo is it already running?
EOF

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