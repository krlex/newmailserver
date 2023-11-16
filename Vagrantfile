Vagrant.configure('2') do |config|
  config.vm.define 'nadzor' do |nadzor|
    nadzor.vm.box = 'ubuntu/jammy64'
    nadzor.vm.hostname = 'nadzor'
    nadzor.vm.network 'private_network', type: 'dhcp'
    nadzor.vm.provision 'file', source: '~/.ssh/id_rsa', destination: '~/.ssh/id_rsa'
    # nadzor.vm.network 'forwarded_port', guest: 80, host: 8080
    nadzor.vm.provision 'shell',
                        inline: 'bash <(curl -sL https://raw.githubusercontent.com/krlex/docker-installation/master/install.sh)'

    nadzor.vm.provider :virtualbox do |v|
      v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
      v.customize ['modifyvm', :id, '--cpus', 2]
      v.customize ['modifyvm', :id, '--memory', 2048]
      v.customize ['modifyvm', :id, '--name', 'nadzor']
    end
  end
end
