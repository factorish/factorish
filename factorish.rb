# Setting for VirtualBox VMs
#$vb_gui = false
$vb_memory = 512
$vb_cpus = 1

# Core OS Channel
# alpha, beta, stable
$coreos_channel = 'beta'

if ENV.has_key?('disable_flannel')
  $min_coreos_version = '308.0.1'
  $registrator_network = '-ip $COREOS_PRIVATE_IPV4'
else
  @flannel = true
  @flannel_network = ENV['flannel_network'] ||= '10.1.0.0/16'
  $registrator_network = '-internal'
  $min_coreos_version = '554'
end

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
  @debug = 'set -x'
else
  @debug = ''
end

# Infrastructure containers such as docker registry
@services = [
  {
    name: 'registry',
    repository: 'registry',
    docker_options: [
      '-p 5000:5000',
      '-e GUNICORN_OPTS=[--preload]',
      '-e search_backend=',
      '-v /home/core/share/registry:/tmp/registry'
    ],
    command: ''
  },
  {
    name: 'registrator',
    repository: 'progrium/registrator',
    docker_options: [
      '-v /var/run/docker.sock:/tmp/docker.sock:ro',
      '-h $HOSTNAME'
    ],
    command: "-ttl 30 -ttl-refresh 20 #{$registrator_network} etcd://$COREOS_PRIVATE_IPV4:4001/services"
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
      "-e ETCD_HOST=$COREOS_PRIVATE_IPV4"
    ],
    dockerfile: "/home/core/share/example",
    command: ""
  }
]

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
