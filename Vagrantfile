VAGRANT_DEFAULT_PROVIDER = 'docker'

# ------------------------------------------------------------------------------
# Admin/Bastion hosts
# ------------------------------------------------------------------------------
envfile = '.env'
load envfile if File.exists?(envfile)

# Trick to add personal pub key to the guests
ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip

# Trying to load .env before defining guests
Vagrant.configure("2") do |config|
#  load_env.hostmanager.enabled = true
#  load_env.hostmanager.manage_host = true
#  load_env.hostmanager.manage_guest = true
#  load_env.hostmanager.ignore_private_ip = false
#  load_env.hostmanager.include_offline = true
  config.ssh.extra_args = ["-t", "cd /vagrant; bash -l"]
  # Create networks beforehand so we can define containers interfaces names
  # Hack to circumvent Vagrant not supporting several scoped options of the same
  # type. See https://github.com/hashicorp/vagrant/issues/13269
  # Note: IP used to create the network is immediately freed as the dummy
  #  container is transient
  config.vm.define "networks" do |net|
    net.vm.network :private_network,
      docker_network__opt: "com.docker.network.bridge.name=br-#{ADM_NET_NAME}",
      ip: "#{ADM_NET_ROOT}.#{ADM_NET_IPMAX}", netmask: "#{ADM_NET_CIDR}"
    net.vm.network :private_network,
      docker_network__opt: "com.docker.network.bridge.name=br-#{STO_NET_NAME}",
      ip: "#{STO_NET_ROOT}.#{STO_NET_IPMAX}", netmask: "#{STO_NET_CIDR}"
    net.vm.network :private_network,
      docker_network__opt: "com.docker.network.bridge.name=br-#{DBA_NET_NAME}",
      ip: "#{DBA_NET_ROOT}.#{DBA_NET_IPMAX}", netmask: "#{DBA_NET_CIDR}"
    net.vm.network :private_network,
      docker_network__opt: "com.docker.network.bridge.name=br-#{APP_NET_NAME}",
      ip: "#{APP_NET_ROOT}.#{APP_NET_IPMAX}", netmask: "#{APP_NET_CIDR}"
    net.vm.network :private_network,
      docker_network__opt: "com.docker.network.bridge.name=br-#{PXY_NET_NAME}",
      ip: "#{PXY_NET_ROOT}.#{PXY_NET_IPMAX}", netmask: "#{PXY_NET_CIDR}"
    net.vm.provider "docker" do |dkr|
      dkr.image="williamyeh/dummy"
      # dkr.has_ssh = true
      dkr.privileged = true
      dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
      dkr.name = "net_dummy"
      dkr.remains_running = false
    end
  end
end


# ------------------------------------------------------------------------------
# Admin/Bastion hosts
# ------------------------------------------------------------------------------
if ADM_HOSTS_NUM != 0
  (1..ADM_HOSTS_NUM).each do |i|
    Vagrant.configure("2") do |config|
      config.env.enable # enable the vagrant-env plugin
      #puts "Helloo"
      adm_host_name = "#{ADM_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{ADM_NET_IPMIN.to_i + i}"
      adm_ssh_hport = ADM_SSH_BPORT.to_i + ADM_NET_IPMIN.to_i + i

      config.vm.define "#{adm_host_name}" do |adm|
        adm.vm.hostname = "#{adm_host_name}"
        adm.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        adm.vm.network :forwarded_port,
          host: "#{adm_ssh_hport}",# host_ip: "#{HOST_IP}",
          guest: "#{ADM_SSH_GPORT}", guest_ip: "#{adm_net_ip}"
        adm.vm.provider "docker" do |dkr|
          dkr.image="silopolis:base"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
          dkr.name = "#{adm_host_name}"
        end
      end
    end
  end
end

# ------------------------------------------------------------------------------
# Storage hosts
# ------------------------------------------------------------------------------
# TODO
if STO_HOSTS_NUM != 0
  (1..STO_HOSTS_NUM).each do |i|
    Vagrant.configure("2") do |config|
      config.env.enable # enable the vagrant-env plugin
      db_host_name = "#{STO_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{STO_NET_IPMIN.to_i + i}"
      sto_host_ip = "#{STO_NET_ROOT}.#{STO_NET_IPMIN.to_i + i}"

      config.vm.define "#{db_host_name}" do |db|
        db.vm.hostname = "#{db_host_name}"
        db.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        db.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{STO_NET_NAME}",
          ip: "#{sto_host_ip}", netmask: "#{STO_NET_CIDR}"
        #db.vm.network :forwarded_port,
        #  host: "#{STO_PORT01_HOST}",
        #  guest: "#{STO_PORT01_GUEST}"
        db.vm.provider "docker" do |dkr|
          dkr.image = "silopolis:storage"
          dkr.name = "#{db_host_name}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
        end

        db.vm.provision "secure-install", type: "shell",
          inline: "/bin/sh /vagrant/mariadb-secure-install.sh",
          run: "never"
        db.vm.provision "database-setup", type: "shell",
          inline: "/bin/sh /vagrant/mariadb-setup-db.sh",
          run: "never"
      end
    end
  end
end


# ------------------------------------------------------------------------------
# DB hosts
# ------------------------------------------------------------------------------
# FIXME ONLY ONE DB host supported
if DBA_HOSTS_NUM != 0
  (1..DBA_HOSTS_NUM).each do |i|
    Vagrant.configure("2") do |config|
      config.env.enable # enable the vagrant-env plugin
      db_host_name = "#{DBA_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{DBA_NET_IPMIN.to_i + i}"
      db_host_ip = "#{DBA_NET_ROOT}.#{DBA_NET_IPMIN.to_i + i}"

      config.vm.define "#{db_host_name}" do |db|
        db.vm.hostname = "#{db_host_name}"
        db.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        db.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{DBA_NET_NAME}",
          ip: "#{db_host_ip}", netmask: "#{DBA_NET_CIDR}"
        #db.vm.network :forwarded_port,
        #  host: "#{DBA_PORT01_HOST}",
        #  guest: "#{DBA_PORT01_GUEST}"
        db.vm.provider "docker" do |dkr|
          dkr.image = "silopolis:mariadb"
          dkr.name = "#{db_host_name}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
        end
        db.vm.synced_folder "data/#{db_host_name}/#{DBA_DATA_DIR}", "/var/lib/mysql",
          mount_options: ["uid=106", "gid=107"]
          #owner: "mysql", group: "mysql"

        db.vm.provision "install-db", type: "shell",
          inline: "/bin/bash /vagrant/mariadb-install-db.sh"
          #run: "never"
        db.vm.provision "secure-install", type: "shell",
          inline: "/bin/bash /vagrant/mariadb-secure-install.sh"# #{db_host_ip}"
          #run: "never"
        db.vm.provision "database-setup", type: "shell",
          inline: "/bin/bash /vagrant/mariadb-setup-db.sh"
          #run: "never"
      end
    end
  end
end


# ------------------------------------------------------------------------------
# App hosts
# ------------------------------------------------------------------------------
if APP_HOSTS_NUM != 0
  (1..APP_HOSTS_NUM).each do |i|
    Vagrant.configure("2") do |config|
      config.env.enable # enable the vagrant-env plugin
      app_host_name = "#{APP_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{APP_NET_IPMIN.to_i + i}"
      #dba_net_ip = "#{DBA_NET_ROOT}.#{DBA_NET_IPMIN.to_i + DBA_HOSTS_NUM.to_i + i}"
      dba_net_ip = "#{DBA_NET_ROOT}.#{APP_NET_IPMIN.to_i + i}"
      app_net_ip = "#{APP_NET_ROOT}.#{APP_NET_IPMIN.to_i + i}"

      config.vm.define "#{app_host_name}" do |app|
        app.vm.hostname = "#{app_host_name}"
        app.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        app.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{DBA_NET_NAME}",
          ip: "#{dba_net_ip}", netmask: "#{DBA_NET_CIDR}"
        app.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{APP_NET_NAME}",
          ip: "#{app_net_ip}", netmask: "#{APP_NET_CIDR}"
        #app.vm.network :forwarded_port,
        #  host: "#{APP_PORT01_HOST}",
        #  guest: "#{APP_PORT01_GUEST}"
        app.vm.provider "docker" do |dkr|
          dkr.image = "silopolis:lemp"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
          dkr.name = "#{app_host_name}"
        end

        app.vm.provision "wp-setup",
          type: "shell",
          inline: "/bin/bash /vagrant/wp_setup.sh"
        app.vm.provision "letsencrypt",
          type: "shell",
          inline: "/bin/bash /vagrant/letsencrypt-setup.sh",
          run: "never"

        app.vm.synced_folder "data/#{app_host_name}/#{APP_SVC_NAME}", "/var/www/wordpress"
      end
    end
  end
end


# ------------------------------------------------------------------------------
# Reverse-proxy hosts
# ------------------------------------------------------------------------------
if PXY_HOSTS_NUM != 0
  (1..PXY_HOSTS_NUM).each do |i|
    Vagrant.configure("2") do |config|
      config.env.enable # enable the vagrant-env plugin
      pxy_host_name = "#{PXY_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{PXY_NET_IPMIN.to_i + i}"
      app_net_ip = "#{APP_NET_ROOT}.#{PXY_NET_IPMIN.to_i + i}"
      pxy_net_ip = "#{PXY_NET_ROOT}.#{PXY_NET_IPMIN.to_i + i}"

      config.vm.define "#{pxy_host_name}" do |proxy|
        proxy.vm.hostname = "#{pxy_host_name}"
        proxy.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        proxy.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{APP_NET_NAME}",
          ip: "#{app_net_ip}", netmask: "#{APP_NET_CIDR}"
        proxy.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{PXY_NET_NAME}",
          ip: "#{pxy_net_ip}", netmask: "#{PXY_NET_CIDR}"
        proxy.vm.network :forwarded_port,
          host: "#{PXY_PORT01_HOST}", host_ip: "#{HOST_IP}",
          guest: "#{PXY_PORT01_GUEST}", guest_ip: "#{pxy_net_ip}"
        proxy.vm.network :forwarded_port,
          host: "#{PXY_PORT02_HOST}", host_ip: "#{HOST_IP}",
          guest: "#{PXY_PORT02_GUEST}", guest_ip: "#{pxy_net_ip}"
        proxy.vm.provider "docker" do |dkr|
          dkr.image="silopolis:nginx"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
          dkr.name = "#{pxy_host_name}"
        end

        #proxy.vm.synced_folder "homepage", "/var/www/homepage"
        #proxy.vm.provision "file", source: "nginx.conf", destination: "/etc/nginx/nginx.conf"
        proxy.vm.provision "nginx_proxy-setup",
          type: "shell",
          inline: "/bin/bash /vagrant/nginx-proxy-setup.sh"
      end
    end
  end
end

# ------------------------------------------------------------------------------
## PHP hosts
# ------------------------------------------------------------------------------
#Vagrant.configure("2") do |config|
#  config.env.enable # enable the vagrant-env plugin
#  config.vm.define "php" do |php|
#    php.vm.hostname = "php"
#    # php.vm.network :private_network, type: "static", subnet: "172.20.128.0/24"
#    php.vm.network :private_network, ip: "192.168.10.#{10+clients+2}", netmask: 24
#    php.vm.network "forwarded_port", guest: 80, host: 8080
#    php.vm.provider "docker" do |dkr|
#      #dkr.build_dir = "."
#      dkr.image = "silopolis:nginx_php"
#      dkr.has_ssh = true
#      dkr.privileged = true
#      dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
#      dkr.name = "php"
#    end
#    php.vm.provision "shell", inline: "/bin/sh /vagrant/php-setup.sh"
#  end
#end

# ------------------------------------------------------------------------------
#clients=2
# ------------------------------------------------------------------------------
#(1..clients).each do |i|
#  Vagrant.configure("2") do |config|
#    config.vm.define "client#{i}" do |client|
#      client.vm.hostname = "client#{i}"
#      client.vm.network "private_network", type: "static", ip: "192.168.10.#{10+i}"
#      client.vm.provider "docker" do |dkr|
#        #dkr.build_dir = "."
#        dkr.image = "silopolis:base"
#        dkr.has_ssh = true
#        dkr.privileged = true
#        dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
#        dkr.name = "client#{i}"
#      end
#    end
#  end
#end
