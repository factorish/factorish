FACTORISH_SETTINGS = ENV['FACTORISH_SETTINGS'] || 'factorish.yml'

SETTINGS = YAML.load_file(FACTORISH_SETTINGS)['factorish']

# Setting for VirtualBox VMs
#$vb_gui = false
$vb_memory = SETTINGS['memory']
$vb_cpus = SETTINGS['cpus']

# Core OS Channel
# alpha, beta, stable
$coreos_channel = SETTINGS['coreos']['channel']
$min_coreos_version = SETTINGS['coreos']['min_version']

if !!SETTINGS['coreos']['flannel']['enabled']
  @flannel = true
  @flannel_network = SETTINGS['coreos']['flannel']['network']
  $registrator_network = '-internal'
else
  $registrator_network = '-ip $COREOS_PRIVATE_IPV4'
end

if SETTINGS['applications'].has_key?('registrator')
  SETTINGS['applications']['registrator']['command'].insert(0, "#{$registrator_network} ")
end

puts SETTINGS['applications'] if $debug

# Size of the CoreOS cluster created by Vagrant
$num_instances = SETTINGS['instances']

# Expose Docker / ETCD ports.
# If there ar more than one VM, will autocorrect to avoid conflicts.
$expose_docker_tcp = 4243 if !!SETTINGS['expose_docker']
$expose_etcd_tcp = 4001 if !!SETTINGS['expose_etcd']
$expose_registry = 5000 if !!SETTINGS['expose_registry']

# Expose custom application ports.
# array of ports to be exposed for your applications.
$expose_ports = SETTINGS['export_ports']

# Mode to start in.
# `develop` will build images from scratch
# `test` will try to download from registry
$mode = ENV['mode'] ||= SETTINGS['mode'] # develop|test

$debug = ENV['DEBUG']

if $debug
  @debug = 'set -x'
else
  @debug = ''
end

# Describe your applications in this hash
@applications = SETTINGS['applications']

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

