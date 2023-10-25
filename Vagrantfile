VAGRANT_DEFAULT_PROVIDER = 'docker'

# ------------------------------------------------------------------------------
# Global configuration
# ------------------------------------------------------------------------------
envfile = '.env'
load envfile if File.exists?(envfile)

# Trick to add personal pub key to the guests
#ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip

# FIXME Add DNS management
# FIXME Containers ifaces naming stopped working !?

Vagrant.configure("2") do |config|
#  load_env.hostmanager.enabled = true
#  load_env.hostmanager.manage_host = true
#  load_env.hostmanager.manage_guest = true
#  load_env.hostmanager.ignore_private_ip = false
#  load_env.hostmanager.include_offline = true
  config.ssh.extra_args = ["-t", "cd /vagrant; bash -l"]

  # ------------------------------------------------------------------------------
  # Networks
  # ------------------------------------------------------------------------------
  # Create networks beforehand so we can define containers interfaces names
  # Hack to circumvent Vagrant not supporting several scoped options of the same
  # type. See https://github.com/hashicorp/vagrant/issues/13269
  # Note: IP used to create the network is immediately freed as the dummy
  # container is transient
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

  # ------------------------------------------------------------------------------
  # Admin/Bastion host(s)
  # ------------------------------------------------------------------------------
  # TODO Allow SSH only on Vagrant and public ifaces
  # TODO Add brute force protection
  # TODO Add one time login support
  if ADM_HOSTS_NUM != 0
    (1..ADM_HOSTS_NUM).each do |i|
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
          dkr.image="#{ADM_CT_IMAGE}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
          dkr.name = "#{adm_host_name}"

        log_host_ip = "#{ADM_NET_ROOT}.#{LOG_NET_IPMIN.to_i + i}"
        log_prov_dir = "/vagrant/#{PROV_DIR}/common"
        adm.vm.provision "adm-log-config", type: "shell",
          inline: "/bin/bash #{log_prov_dir}/log-config.sh $*",
          args: "#{adm_host_name} #{log_host_ip}"
          #run: "never"
        end
      end
    end
  end


  # ------------------------------------------------------------------------------
  # Log host(s)
  # ------------------------------------------------------------------------------
  # TODO Allow SSH only on Vagrant and public ifaces
  # TODO Add brute force protection
  # TODO Add one time login support
  if LOG_HOSTS_NUM != 0
    (1..LOG_HOSTS_NUM).each do |i|
      log_host_name = "#{LOG_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{LOG_NET_IPMIN.to_i + i}"
      log_host_ip = adm_net_ip
      log_prov_dir = "/vagrant/#{PROV_DIR}/common"

      config.vm.define "#{log_host_name}" do |log|
        log.vm.hostname = "#{log_host_name}"
        log.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"

        log.vm.provider "docker" do |dkr|
          dkr.image="#{LOG_CT_IMAGE}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
          dkr.name = "#{log_host_name}"

        log.vm.synced_folder "#{LOG_DATA_DIR}", "#{LOG_ROOT_DIR}",
          mount_options: ["uid=105", "gid=4"]
          #owner: "syslog", group: "adm"

        log.vm.provision "adm-log-config", type: "shell",
          inline: "/bin/bash #{log_prov_dir}/log-config.sh $*",
          args: "#{log_host_name} #{log_host_ip}"
          #run: "never"
        end
      end
    end
  end


  # ------------------------------------------------------------------------------
  # Storage host(s)
  # ------------------------------------------------------------------------------
  # TODO Add NFS/Gluster shared storage support
  if STO_HOSTS_NUM != 0
    (1..STO_HOSTS_NUM).each do |i|
      sto_host_name = "#{STO_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{STO_NET_IPMIN.to_i + i}"
      sto_host_ip = "#{STO_NET_ROOT}.#{STO_NET_IPMIN.to_i + i}"

      config.vm.define "#{sto_host_name}" do |sto|
        sto.vm.hostname = "#{sto_host_name}"
        sto.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        sto.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{STO_NET_NAME}",
          ip: "#{sto_host_ip}", netmask: "#{STO_NET_CIDR}"

        sto.vm.provider "docker" do |dkr|
          dkr.image = "#{STO_CT_IMAGE}"
          dkr.name = "#{sto_host_name}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
        end

      log_host_ip = "#{ADM_NET_ROOT}.#{LOG_NET_IPMIN.to_i + i}"
      log_prov_dir = "/vagrant/#{PROV_DIR}/common"
      sto.vm.provision "adm-log-config", type: "shell",
          inline: "/bin/bash #{log_prov_dir}/log-config.sh $*",
          args: "#{sto_host_name} #{log_host_ip}"
          #run: "never"
        # sto.vm.provision "secure-install", type: "shell",
        #   inline: "/bin/sh /vagrant/mariadb-secure-install.sh",
        #   run: "never"
        # sto.vm.provision "database-setup", type: "shell",
        #   inline: "/bin/sh /vagrant/mariadb-setup-db.sh",
        #   run: "never"
      end
    end
  end


  # ------------------------------------------------------------------------------
  # Database host(s)
  # ------------------------------------------------------------------------------
  # FIXME ONLY ONE DB host supported
  # TODO Allow dbadmin from remote (admin network) ?
  if DBA_HOSTS_NUM != 0
    (1..DBA_HOSTS_NUM).each do |i|
      dba_host_name = "#{DBA_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{DBA_NET_IPMIN.to_i + i}"
      dba_host_ip = "#{DBA_NET_ROOT}.#{DBA_NET_IPMIN.to_i + i}"
      dba_prov_dir = "/vagrant/#{PROV_DIR}/dba"

      config.vm.define "#{dba_host_name}" do |dba|
        dba.vm.hostname = "#{dba_host_name}"
        dba.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        dba.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{DBA_NET_NAME}",
          ip: "#{dba_host_ip}", netmask: "#{DBA_NET_CIDR}"

        dba.vm.provider "docker" do |dkr|
          dkr.image = "#{DBA_CT_IMAGE}"
          dkr.name = "#{dba_host_name}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
        end

        dba.vm.synced_folder "#{DBA_DATA_DIR}", "#{DBA_ROOT_DIR}",
          mount_options: ["uid=106", "gid=107"]
          #owner: "mysql", group: "mysql"

        log_host_ip = "#{ADM_NET_ROOT}.#{LOG_NET_IPMIN.to_i + i}"
        log_prov_dir = "/vagrant/#{PROV_DIR}/common"
        dba.vm.provision "adm-log-config", type: "shell",
            inline: "/bin/bash #{log_prov_dir}/log-config.sh $*",
            args: "#{dba_host_name} #{log_host_ip}"
            #run: "never"
        dba.vm.provision "dba-db-install", type: "shell",
          inline: "/bin/bash #{dba_prov_dir}/#{DBA_SVC_TYPE}-db-install.sh"
          #run: "never"
        dba.vm.provision "dba-db-sec_install", type: "shell",
          inline: "/bin/bash #{dba_prov_dir}/#{DBA_SVC_TYPE}-db-sec_install.sh",
          args: "#{dba_host_ip}"
          #run: "never"
        dba.vm.provision "dba-db-add", type: "shell",
          inline: "/bin/bash #{dba_prov_dir}/#{DBA_SVC_TYPE}-db-add.sh"
          #run: "never"
      end
    end
  end


  # ------------------------------------------------------------------------------
  # App host(s)
  # ------------------------------------------------------------------------------
  if APP_HOSTS_NUM != 0
    (1..APP_HOSTS_NUM).each do |i|
      app_host_name = "#{APP_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{APP_NET_IPMIN.to_i + i}"
      dba_net_ip = "#{DBA_NET_ROOT}.#{APP_NET_IPMIN.to_i + i}"
      app_net_ip = "#{APP_NET_ROOT}.#{APP_NET_IPMIN.to_i + i}"
      app_prov_dir = "/vagrant/#{PROV_DIR}/app"
      app_data_dir = "data/#{APP_SVC_NAME}"
      app_root_dir = "#{APPS_ROOT}/#{APP_SVC_NAME}"

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

        app.vm.provider "docker" do |dkr|
          dkr.image = "#{APP_CT_IMAGE}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
          dkr.name = "#{app_host_name}"
        end

        app.vm.synced_folder "#{app_data_dir}", "#{app_root_dir}",
          mount_options: ["uid=33", "gid=33"]
          #owner: "www-data", group: "www-data"

        log_host_ip = "#{ADM_NET_ROOT}.#{LOG_NET_IPMIN.to_i + i}"
        log_prov_dir = "/vagrant/#{PROV_DIR}/common"
        app.vm.provision "adm-log-config", type: "shell",
            inline: "/bin/bash #{log_prov_dir}/log-config.sh $*",
            args: "#{app_host_name} #{log_host_ip}"
            #run: "never"
        app.vm.provision "app-#{APP_SVC_NAME}-install",
          type: "shell",
          inline: "/bin/bash #{app_prov_dir}/#{APP_SVC_TYPE}-install.sh $*",
          args: "#{app_host_name} --clean"
        app.vm.provision "app-#{APP_SVC_NAME}-config",
          type: "shell",
          inline: "/bin/bash #{app_prov_dir}/#{APP_SVC_TYPE}-config.sh $*",
          args: "#{app_host_name}"
      end
    end
  end


  # ------------------------------------------------------------------------------
  # Reverse-proxy/Load-balancer hosts
  # ------------------------------------------------------------------------------
  if PXY_HOSTS_NUM != 0
    (1..PXY_HOSTS_NUM).each do |i|
      pxy_host_name = "#{PXY_HOSTS_NAME}#{i}"
      adm_net_ip = "#{ADM_NET_ROOT}.#{PXY_NET_IPMIN.to_i + i}"
      app_net_ip = "#{APP_NET_ROOT}.#{PXY_NET_IPMIN.to_i + i}"
      pxy_net_ip = "#{PXY_NET_ROOT}.#{PXY_NET_IPMIN.to_i + i}"
      pxy_prov_dir = "/vagrant/#{PROV_DIR}/pxy"
      ssl_prov_dir = "/vagrant/#{PROV_DIR}/ssl"

      config.vm.define "#{pxy_host_name}" do |pxy|
        pxy.vm.hostname = "#{pxy_host_name}"
        pxy.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{ADM_NET_NAME}",
          ip: "#{adm_net_ip}", netmask: "#{ADM_NET_CIDR}"
        pxy.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{APP_NET_NAME}",
          ip: "#{app_net_ip}", netmask: "#{APP_NET_CIDR}"
        pxy.vm.network :private_network,
          docker_network__opt: "com.docker.network.container_iface_prefix=#{PXY_NET_NAME}",
          ip: "#{pxy_net_ip}", netmask: "#{PXY_NET_CIDR}"
        pxy.vm.network :forwarded_port,
          host: "#{PXY_PORT01_HOST}", host_ip: "#{HOST_IP}",
          guest: "#{PXY_PORT01_GUEST}", guest_ip: "#{pxy_net_ip}"
        pxy.vm.network :forwarded_port,
          host: "#{PXY_PORT02_HOST}", host_ip: "#{HOST_IP}",
          guest: "#{PXY_PORT02_GUEST}", guest_ip: "#{pxy_net_ip}"
        pxy.vm.provider "docker" do |dkr|
          dkr.image="#{PXY_CT_IMAGE}"
          dkr.has_ssh = true
          dkr.privileged = true
          dkr.create_args = ["-v", "/sys/fs/cgroup:/sys/fs/cgroup:ro"]
          dkr.name = "#{pxy_host_name}"
        end

        log_host_ip = "#{ADM_NET_ROOT}.#{LOG_NET_IPMIN.to_i + i}"
        log_prov_dir = "/vagrant/#{PROV_DIR}/common"
        pxy.vm.provision "adm-log-config", type: "shell",
            inline: "/bin/bash #{log_prov_dir}/log-config.sh $*",
            args: "#{pxy_host_name} #{log_host_ip}"
            #run: "never"
        if IS_TRUE.include?(PXY_SSL_ON)    
          pxy.vm.synced_folder "#{SSL_DATA_DIR}", "#{SSL_ROOT_DIR}"

          pxy.vm.provision "ssl-certbot-setup",
            type: "shell",
            inline: "/bin/bash #{ssl_prov_dir}/certbot-setup.sh $*",
            args: "#{pxy_host_name}"
          pxy.vm.provision "ssl-cert-create",
            type: "shell",
            inline: "/bin/bash #{ssl_prov_dir}/cert-create.sh $*",
            args: "#{pxy_host_name}"
          pxy.vm.provision "ssl-cert-install",
            type: "shell",
            inline: "/bin/bash #{ssl_prov_dir}/cert-install.sh $*",
            args: "#{pxy_host_name}"
          pxy.vm.provision "ssl-cert-renew",
            type: "shell",
            inline: "/bin/bash #{ssl_prov_dir}/cert-renew.sh $*",
            args: "#{pxy_host_name}",
            run: "never"
          pxy.vm.provision "ssl-cert-uninstall",
            type: "shell",
            inline: "/bin/bash #{ssl_prov_dir}/cert-uninstall.sh $*",
            args: "#{pxy_host_name}",
            run: "never"
          pxy.vm.provision "ssl-cert-revoke",
            type: "shell",
            inline: "/bin/bash #{ssl_prov_dir}/cert-revoke.sh $*",
            args: "#{pxy_host_name}",
            run: "never"
        end
        pxy.vm.provision "pxy-#{PXY_SVC_TYPE}-setup",
          type: "shell",
          inline: "/bin/bash #{pxy_prov_dir}/#{PXY_SVC_TYPE}-setup.sh $*",
          args: "#{pxy_host_name}"
      end
    end
  end

end
