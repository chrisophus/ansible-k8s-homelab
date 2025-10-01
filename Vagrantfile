# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = ">= 20220423.0.0"

  # Common configuration
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # Control plane nodes
  (1..3).each do |i|
    config.vm.define "cp#{i}" do |node|
      node.vm.hostname = "cp#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{10 + i - 1}"

      # Provision with basic setup
      node.vm.provision "shell", inline: <<-SHELL
        # Update system
        apt-get update

        # Create ubuntu user if it doesn't exist
        if ! id "ubuntu" &>/dev/null; then
          useradd -m -s /bin/bash ubuntu
          echo "ubuntu:ubuntu" | chpasswd
          usermod -aG sudo ubuntu
          echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        fi

        # Enable password authentication for initial bootstrap
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        systemctl restart ssh

        # Set timezone
        timedatectl set-timezone UTC
      SHELL
    end
  end

  # Optional worker nodes
  (1..2).each do |i|
    config.vm.define "worker#{i}", autostart: false do |node|
      node.vm.hostname = "worker#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{13 + i - 1}"

      node.vm.provision "shell", inline: <<-SHELL
        apt-get update

        if ! id "ubuntu" &>/dev/null; then
          useradd -m -s /bin/bash ubuntu
          echo "ubuntu:ubuntu" | chpasswd
          usermod -aG sudo ubuntu
          echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        fi

        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        systemctl restart ssh

        timedatectl set-timezone UTC
      SHELL
    end
  end
end