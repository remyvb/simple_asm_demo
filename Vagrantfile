# rubocop: disable Metrics/LineLength
require 'yaml'

VAGRANTFILE_API_VERSION = '2'.freeze

unless Vagrant.has_plugin?('vagrant-triggers')
  raise 'vagrant-triggers is not installed, please run: vagrant plugin install vagrant-triggers'
end

add_timestamp = false
if add_timestamp
  def $stdout.write(string)
    log_datas = string
    if log_datas.gsub(/\r?\n/, '') != ''
      log_datas = ::Time.now.strftime('%d-%m-%Y %T') + ' ' + log_datas.gsub(/\r\n/, '\n')
    end
    super log_datas
  end

  def $stderr.write(string)
    log_datas = string
    if log_datas.gsub(/\r?\n/, '') != ''
      log_datas = ::Time.now.strftime('%d-%m-%Y %T') + ' ' + log_datas.gsub(/\r\n/, '\n')
    end
    super log_datas
  end
end

# Read YAML file with box details
servers = YAML.load_file('servers.yaml')
pe_puppet_user_id  = 495
pe_puppet_group_id = 496
vagrant_root = File.dirname(__FILE__)
home = ENV['HOME']
#
# Choose your version of Puppet Enterprise
#
# puppet_installer = 'puppet-enterprise-2015.3.0-el-6-x86_64/puppet-enterprise-installer'
# puppet_installer = 'puppet-enterprise-2015.2.2-el-6-x86_64/puppet-enterprise-installer'
# puppet_installer = 'puppet-enterprise-2016.1.2-el-7-x86_64/puppet-enterprise-installer'
# puppet_installer = 'puppet-enterprise-2016.4.0-el-7-x86_64/puppet-enterprise-installer'
# puppet_installer = 'puppet-enterprise-2016.5.1-el-7-x86_64/puppet-enterprise-installer'
puppet_installer = 'puppet-enterprise-2017.3.5-el-7-x86_64/puppet-enterprise-installer'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false
  servers.each do |name, server|
    config.vm.define name do |srv|
      srv.vm.box = ENV['BASE_IMAGE'] ? (ENV['BASE_IMAGE']).to_s : server['box']
      hostname = name.split('-').last # First part contains type of node
      srv.vm.hostname = "#{hostname}.example.com"
      srv.vm.network 'private_network', ip: server['public_ip']
      srv.vm.network 'private_network', ip: server['private_ip'], virtualbox__intnet: true
      srv.vm.synced_folder '.', '/vagrant', type: :virtualbox

      config.trigger.before :up do
        if File.file?("#{home}/.netrc") && !File.file?("#{vagrant_root}/.netrc")
          info "Copy #{home}/.netrc to #{vagrant_root}/.netrc"
          FileUtils.copy_file("#{home}/.netrc", "#{vagrant_root}/.netrc")
        end
      end
      config.trigger.after :up do
        unless File.file?(".#{hostname}.txt")
          info "Creating file .#{hostname}.txt"
          File.open(".#{hostname}.txt", 'w') { |f| f.write(hostname) }
          if server['needs_storage'] == 'enabled'
            server['disks'].each do |disk|
              disk_name = disk.first
              disk_uuid = disk.last['uuid']
              if !File.file?(".#{disk_name}.txt") && File.file?("#{disk_name}.vdi")
                info "Creating file .#{disk_name}.txt"
                File.open(".#{disk_name}.txt", 'w') { |f| f.write("00000000-0000-0000-0000-0000000000#{disk_uuid}") }
              end
            end
          end
        end
      end
      config.trigger.after :destroy do
        if File.file?(".#{hostname}.txt")
          info "Removing file .#{hostname}.txt"
          run "rm .#{hostname}.txt"
          if server['needs_storage'] == 'enabled'
            server['disks'].each do |disk|
              disk_name = disk.first
              if File.file?(".#{disk_name}.txt")
                info "Removing file .#{disk_name}.txt"
                run "rm .#{disk_name}.txt"
              end
            end
          end
        end
      end

      case server['type']
      when 'masterless'
        srv.vm.box = 'enterprisemodules/centos-7.2-x86_64-puppet' unless server['box']
        unless File.file?(".#{hostname}.txt")
          srv.vm.provision :shell, inline: <<-EOD
cat > /etc/hosts<< "EOF"
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
192.168.254.10 master.example.com puppet master asmmaster asmmaster.example.com
#{server['public_ip']} #{hostname}.example.com #{hostname}
EOF
EOD
          srv.vm.provision :shell, path: 'vm-scripts/setup_puppet.sh'
        end
        srv.vm.provision :shell, inline: 'puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp --test'
      when 'pe-master'
        srv.vm.box = 'puppetlabs/centos-7.2-64-nocm' unless server['box']
        srv.vm.synced_folder '.', '/vagrant', owner: pe_puppet_user_id, group: pe_puppet_group_id
        srv.vm.provision :shell, inline: "/vagrant/modules/software/files/#{puppet_installer} -c /vagrant/pe.conf -y"
        #
        # For this vagrant setup, we make sure all nodes in the domain examples.com are autosigned. In production
        # you'dd want to explicitly confirm every node.
        #
        srv.vm.provision :shell, inline: "echo '*.example.com' > /etc/puppetlabs/puppet/autosign.conf"
        #
        # For now we stop the firewall. In the future we will add a nice puppet setup to the ports needed
        # for Puppet Enterprise to work correctly.
        #
        srv.vm.provision :shell, inline: 'systemctl stop firewalld.service'
        srv.vm.provision :shell, inline: 'systemctl disable firewalld.service'
        #
        # This script make's sure the vagrant paths's are symlinked to the places Puppet Enterprise looks for specific
        # modules, manifests and hiera data. This makes it easy to change these files on your host operating system.
        #
        srv.vm.provision :shell, path: 'vm-scripts/setup_puppet.sh'
        #
        # Make sure all plugins are synced to the puppetserver before exiting and stating
        # any agents
        #
        srv.vm.provision :shell, inline: 'systemctl restart pe-puppetserver.service'
        srv.vm.provision :shell, inline: 'puppet agent -t || true'
      when 'pe-agent'
        srv.vm.box = 'enterprisemodules/centos-7.2-x86_64-nocm' unless server['box']
        #
        # First we need to instal the agent.
        #
        unless File.file?(".#{hostname}.txt")
          srv.vm.provision :shell, inline: 'curl -k https://master.example.com:8140/packages/current/install.bash | sudo bash'
        end
        #
        # The agent installation also automatically start's it. In production, this is what you want. For now we
        # want the first run to be interactive, so we see the output. Therefore, we stop the agent and wait
        # for it to be stopped before we start the interactive run
        #
        srv.vm.provision :shell, inline: 'pkill -9 -f "puppet.*agent.*"'
        srv.vm.provision :shell, inline: 'puppet agent -t; exit 0'
        #
        # After the interactive run is done, we restart the agent in a normal way.
        #
        srv.vm.provision :shell, inline: 'systemctl start puppet'
      end

      config.vm.provider :virtualbox do |vb|
        vb.gui = false
        vb.cpus = server['cpucount'] || 1
        vb.memory = server['ram'] || 4096
        vb.customize ['modifyvm', :id, '--ioapic', 'on']
        vb.customize ['modifyvm', :id, '--name', name]
        if server['virtualboxorafix'] == 'enable'
          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/Leaf', '0x4']
          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/SubLeaf', '0x4']
          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/eax', '0']
          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/ebx', '0']
          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/ecx', '0']
          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/edx', '0']
          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/SubLeafMask', '0xffffffff']
        end
        if server['needs_storage'] == 'enabled'
          disks = server['disks'] || {}
          unless File.file?(".#{hostname}.txt")
            vb.customize [
              'storagectl', :id,
              '--name', 'SATA Controller',
              '--add', 'sata',
              '--portcount', disks.size
            ]
          end
          disks.each_with_index do |disk, i|
            disk_name = disk.first
            disk_size = disk.last['size']
            disk_uuid = disk.last['uuid']
            if File.file?("#{disk_name}.vdi")
              if File.file?(".#{disk_name}.txt")
                file = File.open(".#{disk_name}.txt", 'r')
                current_uuid = file.read
                file.close
              else
                current_uuid = '0'
              end
            else
              vb.customize [
                'createhd',
                '--filename', "#{disk_name}.vdi",
                '--size', disk_size.to_s,
                '--variant', 'Standard'
              ]
              current_uuid = '0'
            end
            if current_uuid.include? disk_uuid
              vb.customize [
                'storageattach', :id,
                '--storagectl', 'SATA Controller',
                '--port', (i + 1).to_s,
                '--device', 0,
                '--type', 'hdd',
                '--medium', "#{disk_name}.vdi"
              ]
            else
              vb.customize [
                'storageattach', :id,
                '--storagectl', 'SATA Controller',
                '--port', (i + 1).to_s,
                '--device', 0,
                '--type', 'hdd',
                '--medium', "#{disk_name}.vdi",
                '--setuuid', "00000000-0000-0000-0000-00000000000#{disk_uuid}"
              ]
            end
          end
        end
      end
    end
  end
end
