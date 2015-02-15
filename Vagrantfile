# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'

CLOUD_CONFIG_PATH = './user-data'

require_relative 'factorish.rb'

Vagrant.configure('2') do |config|
  config.vm.box = "coreos-#{$coreos_channel}"
  config.vm.box_version = ">= #{$min_coreos_version}"
  config.vm.box_url = "http://storage.core-os.net/coreos/amd64-usr/#{$coreos_channel}/coreos_production_vagrant.json"
  config.vm.provider :vmware_fusion do |_, override|
    override.vm.box_url = "http://storage.core-os.net/coreos/amd64-usr/#{$coreos_channel}/coreos_production_vagrant_vmware_fusion.json"
  end

  # plugin conflict
  config.vbguest.auto_update = false if Vagrant.has_plugin?('vagrant-vbguest')

  (1..$num_instances).each do |i|
    config.vm.define vm_name = format('core-%02d', i) do |c|
      c.vm.hostname = vm_name

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), 'log')
        FileUtils.mkdir_p(logdir)

        serial_file = File.join(logdir, format('%s-serial.txt', vm_name))
        FileUtils.touch(serial_file)

        c.vm.provider :vmware_fusion do |v, _|
          v.vmx['serial0.present'] = 'TRUE'
          v.vmx['serial0.fileType'] = 'file'
          v.vmx['serial0.fileName'] = serialFile
          v.vmx['serial0.tryNoRxLoss'] = 'FALSE'
        end

        c.vm.provider :virtualbox do |vb, _|
          vb.customize ['modifyvm', :id, '--uart1', '0x3F8', '4']
          vb.customize ['modifyvm', :id, '--uartmode1', serialFile]
        end
      end

      c.vm.network 'forwarded_port', guest: $expose_docker_tcp, host: $expose_docker_tcp, auto_correct: true if $expose_docker_tcp
      c.vm.network 'forwarded_port', guest: $expose_etcd_tcp, host: $expose_etcd_tcp, auto_correct: true if $expose_etcd_tcp

      c.vm.provider :virtualbox do |vb|
        vb.gui = $vb_gui
        vb.memory = $vb_memory
        vb.cpus = $vb_cpus
      end

      ip = "172.17.8.#{i + 100}"
      c.vm.network :private_network, ip: ip

      c.vm.synced_folder '.', '/home/core/share', id: 'core', nfs: true, mount_options: ['nolock,vers=3,udp']

      if File.exist?(CLOUD_CONFIG_PATH)
        c.vm.provision :file, source: "#{CLOUD_CONFIG_PATH}", destination: '/tmp/vagrantfile-user-data'
        c.vm.provision :shell, inline: 'mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/', privileged: true
      end

      c.vm.provision :shell, inline: 'echo use systemctl and journalctl to view progress of startup'

    end
  end
end
