# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"
    config.vm.provision "shell", inline: "chmod 0600 /home/vagrant/.ssh/id_rsa"
    config.vm.provision :shell, path: "scripts/preinstall.sh"

    config.vm.define "database" do |database|
		database.vm.box = "ubuntu/xenial64"
		database.vm.hostname = "database"
		database.vm.network "private_network", ip: "192.168.10.10"
        database.vm.network "forwarded_port", guest: 22, host: 10010, id: "ssh"
        database.vm.network "forwarded_port", guest: 3306, host: 3306, id: "mysql"
		database.vm.synced_folder "files", "/vagrant"
        database.vm.provision :shell, path: "scripts/bashrc.sh"
		database.vm.provision :shell, path: "scripts/database.sh"
        database.vm.provision :shell, path: "scripts/hosts.sh", env: {
            "HOST" => "127.0.1.1    database.local"
        }
        database.trigger.after :up, name: "Database", info: "Machine is up!"

		database.vm.provider :virtualbox do |vb|
            vb.name = "database"
            vb.customize [
                "modifyvm", :id,
                "--memory", 512,
                "--cpus", 1,
                "--natdnshostresolver1", "on"
            ]
        end
	end

    config.vm.define "redis" do |redis|
		redis.vm.box = "ubuntu/xenial64"
		redis.vm.hostname = "redis"
		redis.vm.network "private_network", ip: "192.168.10.15"
        redis.vm.network "forwarded_port", guest: 22, host: 10015, id: "ssh"
		redis.vm.synced_folder "files", "/vagrant"
        redis.vm.provision :shell, path: "scripts/bashrc.sh"
		redis.vm.provision :shell, path: "scripts/redis.sh"
        redis.vm.provision :shell, path: "scripts/hosts.sh", env: {
            "HOST" => "127.0.1.1    redis.local"
        }
        redis.trigger.after :up, name: "Redis", info: "Machine is up!"

		redis.vm.provider :virtualbox do |vb|
            vb.name = "redis"
            vb.customize [
                "modifyvm", :id,
                "--memory", 512,
                "--cpus", 1,
                "--natdnshostresolver1", "on"
            ]
        end
	end

    config.vm.define "web", autostart: false do |web|
        web.vm.box = "ubuntu/xenial64"
        web.vm.hostname = "web"
        web.vm.network "private_network", ip: "192.168.10.100"
        web.vm.network "forwarded_port", guest: 22, host: 10100, id: "ssh"
        web.vm.synced_folder "files", "/vagrant"
        web.vm.synced_folder "src/malijunaki.si", "/var/www/malijunaki.si"
        web.vm.provision :shell, path: "scripts/bashrc.sh"
        web.vm.provision :shell, path: "scripts/database.sh"
        web.vm.provision :shell, path: "scripts/hosts.sh", env: {
            "HOST" => "127.0.1.1    malijunaki.local"
        }
        web.vm.provision :shell, path: "scripts/php.sh", env: {
            "VERSION" => "7.0",
            "XDEBUG_REMOTE_PORT" => "9100"
        }
        web.vm.provision :shell, path: "scripts/apache.sh", env: {
            "SERVER_NAME" => "malijunaki"
        }
		web.vm.provision :shell, path: "scripts/composer.sh"
        web.trigger.after :up, name: "Web", info: "Machine is up!"

        web.vm.provider "virtualbox" do |vb|
            vb.name = "web"
            vb.customize [
				"modifyvm", :id,
				"--memory", 2048,
				"--cpus", 1,
                "--natdnshostresolver1", "on"
			]
            vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", 1]
        end
    end

    config.vm.define "cloud" do |cloud|
        cloud.vm.box = "ubuntu/xenial64"
        cloud.vm.hostname = "cloud"
        cloud.vm.network "private_network", ip: "192.168.10.21"
        cloud.vm.network "forwarded_port", guest: 22, host: 10021, id: "ssh"
        cloud.vm.network "forwarded_port", guest: 80, host: 80, id: "http"
        cloud.vm.synced_folder "files", "/vagrant"
        cloud.vm.synced_folder "src/cloudfs", "/opt/cloudfs", create: true
        cloud.vm.synced_folder "src/malijunaki-web.si", "/var/www/malijunaki-web.si", create: true
        cloud.vm.synced_folder "src/nebuchadnezzar", "/var/www/nebuchadnezzar", create: true
        cloud.vm.synced_folder "src/versatrans", "/versatrans"
        cloud.vm.provision :shell, path: "scripts/bashrc.sh"
        cloud.vm.provision :shell, path: "scripts/upgrade.sh"
        cloud.vm.provision :shell, path: "scripts/php.sh", env: {
            "VERSION" => "7.3",
            "XDEBUG_REMOTE_PORT" => "9021"
        }
        cloud.vm.provision :shell, path: "scripts/apache.sh", env: {
            "SERVER_NAME" => "malijunaki-web"
        }
        cloud.vm.provision :shell, path: "scripts/hosts.sh", env: {
            "HOST" => "127.0.1.1    malijunaki-web.local"
        }
		cloud.vm.provision :shell, path: "scripts/composer.sh"
        cloud.trigger.after :up, name: "Cloud", info: "Machine is up!"

        cloud.vm.provider "virtualbox" do |vb|
            vb.name = "cloud"
            vb.customize [
				"modifyvm", :id,
				"--memory", 2048,
				"--cpus", 1,
                "--natdnshostresolver1", "on"
			]
            vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
        end
    end

	config.vm.define "admin" do |admin|
        admin.vm.box = "ubuntu/xenial64"
        admin.vm.hostname = "admin"
        admin.vm.network "private_network", ip: "192.168.10.31"
        admin.vm.network "forwarded_port", guest: 22, host: 10031, id: "ssh"
        admin.vm.synced_folder "files", "/vagrant"
        admin.vm.synced_folder "src/cloudfs", "/opt/cloudfs", create: true
        admin.vm.synced_folder "src/malijunaki-admin.si", "/var/www/malijunaki-admin.si", create: true
        admin.vm.synced_folder "src/nebuchadnezzar", "/var/www/nebuchadnezzar", create: true
        admin.vm.synced_folder "src/versatrans", "/versatrans"
        admin.vm.provision :shell, path: "scripts/bashrc.sh"
        admin.vm.provision :shell, path: "scripts/upgrade.sh"
        admin.vm.provision :shell, path: "scripts/php.sh", env: {
            "VERSION" => "7.3",
            "XDEBUG_REMOTE_PORT" => "9031"
        }
        admin.vm.provision :shell, path: "scripts/apache.sh", env: {
            "SERVER_NAME" => "malijunaki-admin"
        }
        admin.vm.provision :shell, path: "scripts/hosts.sh", env: {
            "HOST" => "127.0.1.1    malijunaki-admin.local"
        }
		admin.vm.provision :shell, path: "scripts/composer.sh"
        admin.vm.provision :shell, path: "scripts/storage.sh"
        admin.trigger.after :up, name: "Admin", info: "Machine is up!"

        admin.vm.provider "virtualbox" do |vb|
            vb.name = "admin"
            vb.customize [
				"modifyvm", :id,
				"--memory", 2048,
				"--cpus", 1,
                "--natdnshostresolver1", "on"
			]
            vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
        end
    end

	config.vm.define "worker_loadbalancer", autostart: false do |worker_loadbalancer|
		worker_loadbalancer.vm.box = "ubuntu/xenial64"
		worker_loadbalancer.vm.hostname = "worker_loadbalancer"
		worker_loadbalancer.vm.network "private_network", ip: "192.168.10.40"
        worker_loadbalancer.vm.network "forwarded_port", guest: 22, host: 10040, id: "ssh"
		worker_loadbalancer.vm.synced_folder "files", "/vagrant"
        worker_loadbalancer.vm.provision :shell, path: "scripts/bashrc.sh"
		worker_loadbalancer.vm.provision :shell, path: "scripts/loadbalancer.sh"
        worker_loadbalancer.vm.provision :shell, path: "scripts/hosts.sh", env: {
            "HOST" => "127.0.1.1    worker-loadbalancer.local"
        }
        worker_loadbalancer.trigger.after :up, name: "Worker Loadbalancer", info: "Machine is up!"

		worker_loadbalancer.vm.provider :virtualbox do |vb|
            vb.name = "worker_loadbalancer"
            vb.customize [
                "modifyvm", :id,
                "--memory", 512,
                "--cpus", 1,
                "--natdnshostresolver1", "on"
            ]
        end
	end

    config.vm.define "worker" do |worker|
        worker.vm.box = "ubuntu/xenial64"
        worker.vm.hostname = "worker"
        worker.vm.network "private_network", ip: "192.168.10.41"
        worker.vm.network "forwarded_port", guest: 22, host: 10041, id: "ssh"
        worker.vm.synced_folder "files", "/vagrant"
        worker.vm.synced_folder 'src/cloudfs', '/opt/cloudfs', create: true
        worker.vm.synced_folder "src/agent.smith", "/var/www/agent.smith"
        worker.vm.synced_folder "src/nebuchadnezzar", "/var/www/nebuchadnezzar", create: true
        worker.vm.synced_folder "src/versatrans", "/versatrans"
        worker.vm.provision :shell, path: "scripts/bashrc.sh"
        worker.vm.provision :shell, path: "scripts/upgrade.sh"
        worker.vm.provision :shell, path: "scripts/apache.sh", env: {
            "SERVER_NAME" => "worker"
        }
        worker.vm.provision :shell, path: "scripts/hosts.sh", env: {
            "HOST" => "127.0.1.1    worker.local"
        }
        worker.vm.provision :shell, path: "scripts/php.sh", env: {
            "VERSION" => "7.3",
            "XDEBUG_REMOTE_PORT" => "9041"
        }
		worker.vm.provision :shell, path: "scripts/composer.sh"
        worker.vm.provision :shell, path: "scripts/storage.sh"
        worker.trigger.after :up, name: "Worker ", info: "Machine is up!"

        worker.vm.provider "virtualbox" do |vb|
            vb.name = "worker"
            vb.customize [
				"modifyvm", :id,
                "--memory", 1024,
				"--cpus", 1,
                "--natdnshostresolver1", "on"
			]
            vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
        end
    end
end
