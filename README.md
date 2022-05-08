# M1kH61l_infra
M1kH61l Infra repository

ssh -i ~/.ssh/appuser -A -t appuser@51.250.65.56 ssh 10.128.0.14

sudo nano /etc/hosts
51.250.65.56 bastion
10.128.0.14 someinternalhost

host someinternalhost
        ProxyJump appuser@bastion
        IdentityFile ~/.ssh/appuser
        User appuser
        Port 22

bastion_IP = 51.250.65.56
someinternalhost_IP = 10.128.0.14

testapp_IP = 51.250.5.137
testapp_port = 9292


=================================

Terraform 1

=================================

Скачайте версию Terraform для Ubuntu:

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

Проверить установку Terraform можно командой: 
terraform -v

Создайте директорию terraform внутри вашего проекта:
cd terraform/

Внутри директории terraform создайте пустой файл: main.tf
nano main.tf

В корне репозитория создайте файл .gitignore с содержимым
nano .gitignore
	*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
	
Провайдеры Terraform являются загружаемыми модулями, начиная с версии 0.10. Для того чтобы загрузить провайдер и начать его использовать выполните следующую команду в директории terraform:

terraform init

Чтобы не мешать выходные переменные с основной конфигурацией наших ресурсов, создадим их в отдельном файле, который назовем outputs.tf:

output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}

Где 
yandex_compute_instance.app - инициализируем ресурс, указывая его тип и имя 
network_interface.0.nat_ip_address - указываем нужные атрибуты ресурса 


Копируем секцию провижинера типа file, который позволяет копировать содержимое файла на удаленную машину:

provisioner "file" { source = "files/puma.service" destination = "/tmp/puma.service" }

Создадим директорию files внутри директории terraform и создадим внутри нее файл puma.service с содержимым:
[Unit]
Description=Puma HTTP Server
After=network.target
[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always
[Install]
WantedBy=multi-user.target

Добавим еще один провиженер для запуска скрипта деплоя приложения на создаваемом инстансе. 

provisioner "remote-exec" { script = "files/deploy.sh" } 

Создадим файл deploy.sh в директории terraform/files
#!/bin/bash
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a
sudo apt update
set -e
APP_DIR=${1:-$HOME}
sudo apt-get install -y git
sudo git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit
cd $APP_DIR/reddit
bundle install
sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma


Определим параметры подключения провиженеров к VM
  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)

Определим переменные в файле variables.tf

variable "cloud_id" {
  description = "Cloud"
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable "private_key_path" {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}
variable "public_key_path" {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable "image_id" {
  description = "Disk image"
}
variable "subnet_id" {
  description = "Subnet"
}
variable "service_account_key_file" {
  description = "key .json"
}
variable "name_yc_id" {
  description = "resource yandex_compute_instance app"
}


Определим переменные terraform.tfvars

cloud_id                 = "b1 gut"
folder_id                = "b1gab q7e"
zone                     = "ru-central1-a"
image_id                 = "fd8 m1f"
public_key_path          = "~/.ssh/z.pub"
private_key_path         = "~/.ssh/z"
subnet_id                = "e91ajd"
service_account_key_file = "AQAufKLN4M"
name_yc_id               = "reddit-app-terraform"

Определим соответствующие параметры ресурсов main.tf через переменные:

provider "yandex" {
  token     = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
resource "yandex_compute_instance" "app" {
  name = var.name_yc_id

  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.image_id
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}



Удалим ранее созданные ресурсы:
Terraform destroy

Затем создадим ресурсы вновь:
terraform plan 
terraform apply

Проверяем результат http://XX.XX.XX.XX:9292


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
|============================================================

|= Terraform 2

|============================================================

Зададим IP для инстанса с приложением в виде внешнего ресурса. Для этого определим ресурсы yandex_vpc_network и yandex_vpc_subnet в конфигурационном файле main.tf.

nano main.tf

resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}
resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}



Удалим созданные до этого ресурсы (если они не были удалены до этого):

terraform destroy

Создадим их вновь:

terraform apply 

yandex_compute_instance.app: Creating...
yandex_vpc_network.app-network: Creating...
yandex_compute_instance.app: Still creating... [10s elapsed]
yandex_compute_instance.app: Still creating... [20s elapsed]
yandex_compute_instance.app: Still creating... [30s elapsed]
yandex_compute_instance.app: Still creating... [40s elapsed]
yandex_compute_instance.app: Provisioning with 'file'...
yandex_compute_instance.app: Still creating... [50s elapsed]


Error:
yandex_compute_instance.app: Creation complete after 2m17s [id=fhmon9hqi4mtnacto4s2]
╷
│ Error: Error while requesting API to create network: server-request-id = 07abaedd-e376-4fed-af9c-a6dc6faa516d server-trace-id = 419901aaa5573822:425cf19c23a9a602:419901aaa5573822:1 client-request-id = 835daa41-b381-4807-a778-35c25bdfb433 client-trace-id = 5aeaad0a-d47c-43a8-a7c0-2ffe644c8f52 rpc error: code = ResourceExhausted desc = Quota limit vpc.networks.count exceeded
│ 
│   with yandex_vpc_network.app-network,
│   on main.tf line 15, in resource "yandex_vpc_network" "app-network":
│   15: resource "yandex_vpc_network" "app-network" {


Решение, запрос в поддержку яндекса по увеличению квоты vpc до 3

Удалим созданные до этого ресурсы (если они не были удалены до этого):

terraform destroy

Создадим их вновь:

terraform apply 

yandex_compute_instance.app (remote-exec):     All plugins need to be explicitly installed with install_plugin.
yandex_compute_instance.app (remote-exec):     Please see README.md

yandex_compute_instance.app (remote-exec): Created symlink from /etc/systemd/system/multi-user.target.wants/puma.service to /etc/systemd/system/puma.service.
yandex_compute_instance.app: Creation complete after 1m57s [id=fhm6a14adbb0amhvg7ha]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.79.87"

--------------------------------------------------
Для того чтобы использовать созданный IP адрес в нашем ресурсе VM нам необходимо сослаться на атрибуты ресурса, который этот IP создает, внутри конфигурации ресурса VM. В конфигурации ресурса VM определите, IP адрес для создаваемого инстанса.

 network_interface {
    # Указан id подсети default-ru-central1-a
    # subnet_id = var.subnet_id
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true


-----------------------------------------------------
Видим, что ресурс VM начал создаваться только после завершения создания IP адреса в результате неявной зависимости этих ресурсов.
$ terraform destroy 
$ terraform plan 
$ terraform apply

yandex_vpc_network.app-network: Creating...
yandex_vpc_network.app-network: Creation complete after 1s [id=enpkbjpabbu5ggcff3n6]
yandex_vpc_subnet.app-subnet: Creating...
yandex_vpc_subnet.app-subnet: Creation complete after 2s [id=e9bplj4o680g2rhljhe9]
yandex_compute_instance.app: Creating...
yandex_compute_instance.app: Still creating... [10s elapsed]

--------------------------------------------

Смотрим ubuntu16.json

{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `keyfile`}}",
            "folder_id": "{{user `folder`}}",
            "source_image_family": "{{user `srcimage`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "disk_size_gb": "15",
            "zone": "{{user `zone`}}",
            "subnet_id": "{{user `subnet`}}",
            "instance_cores": "2",
            "instance_mem_gb": "2",
            "use_ipv4_nat": true,
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]

}


Через шаблон db.json собирется образ VM, содержащий установленную MongoDB. 
nano  db.json

{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `keyfile`}}",
            "folder_id": "{{user `folder`}}",
            "source_image_family": "{{user `srcimage`}}",
            "image_name": "reddit-base-mongodb-{{timestamp}}",
            "image_family": "reddit-base-mongodb",
            "ssh_username": "ubuntu",
            "disk_size_gb": "15",
            "zone": "{{user `zone`}}",
            "subnet_id": "{{user `subnet`}}",
            "instance_cores": "2",
            "instance_mem_gb": "2",
            "use_ipv4_nat": true,
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]

}

Результат

Build 'yandex' finished after 2 minutes 23 seconds.

==> Wait completed after 2 minutes 23 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-base-mongo-1650697412 (id: fd895d15t8a5lqsigj13) with family name reddit-base-mongo



Через шаблон app.json собирется образ VM, содержащий установленную Ruby. 

nano app.json

{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `keyfile`}}",
            "folder_id": "{{user `folder`}}",
            "source_image_family": "{{user `srcimage`}}",
            "image_name": "reddit-base-ruby-{{timestamp}}",
            "image_family": "reddit-base-ruby",
            "ssh_username": "ubuntu",
            "disk_size_gb": "15",
            "zone": "{{user `zone`}}",
            "subnet_id": "{{user `subnet`}}",
            "instance_cores": "2",
            "instance_mem_gb": "2",
            "use_ipv4_nat": true,
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        }  
  ]

}


Результат:

Build 'yandex' finished after 3 minutes 21 seconds.

==> Wait completed after 3 minutes 21 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-base-ruby-1650697035 (id: fd84b3ha80n3v29rhe78) with family name reddit-base-ruby


===========================================

Создадим две VM
Для этого создадим файл конфигурации app.tf:

resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  labels = {
    tags = "reddit-app"
  }
  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.app_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }


Для этого создадим файл конфигурации db.tf:

resource "yandex_compute_instance" "db" {
  name = "reddit-db"

  labels = {
    tags = "reddit-db"
  }
  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

Добавляем переменные в variables.tf:

variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-db-base"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}

Добавляем переменные в terraform.tfvars
db_disk_image                 = "fd895d15t8a5lqsigj13"
app_disk_image                 = "fd84b3ha80n3v29rhe78"


Создадим файл vpc.tf, в который вынесем кофигурацию сети и подсети, которое применимо для всех инстансов нашей сети

resource "yandex_vpc_network" "app-network" {
  name = "app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}

Добавляем nat адреса инстансов в outputs переменные 

output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}




=====================

Результат выполнения Terraform apply

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.74.244"
external_ip_address_db = "51.250.73.5"

========================

=  Модули

========================

Внутри директории terraform создаём директорию modules

mkdir modules - db 
		|
		app
создаём три привычных нам файла main.tf, variables.tf, outputs.tf

========================
=   DB modules
========================
nano main.tf

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
resource "yandex_compute_instance" "db" {
  name = "reddit-db-terraform-2"

  labels = {
    tags = "reddit-db-terraform-2"
  }
  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}


nano variables.tf
variable "public_key_path" {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable "subnet_id" {
  description = "Subnet"
}
variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-db-base"
}

nano outputs.tf
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}




========================
=   APP modules
========================

Создаём по аналогии с DB main.tf  outputs.tf  terraform.tfvars  variables.tf


Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "51.250.82.218"
external_ip_address_db = "51.250.64.237"
VirtualBox:~/Documents/M1kH61l_infra/terraform$ ssh ubuntu@51.250.82.218
The authenticity of host '51.250.82.218 (51.250.82.218)' can't be established.
ECDSA key fingerprint is SHA256:S89f2sAG1b6NGY.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '51.250.82.218' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

ubuntu@fhmbulhctv5cp1tvdvun:~$ 


==========================
= Stage & Prod
==========================

В директории terrafrom создал две директории: stage и prod и скопировал файлы main.tf, variables.tf, outputs.tf, terraform.tfvars, key.json из директории terraform в каждую из созданных директорий.


-------------------------------------------------------------------------


++++++++++++++++++++++++++++++++++++++++
+++ ANSIBLE - 1
++++++++++++++++++++++++++++++++++++++++

Устанавливаем Ansible
	- Создаем дирикторию ansible с файлом requirements.txt
	- устанавливаем pip
	sudo apt-get install pip
	- устанавливаем ansible
	pip install -r requirements.txt
	Successfully built ansible ansible-core
	Installing collected packages: pyparsing, packaging, resolvelib, ansible-core, ansible
	Killed
	
	- Поднимаем инфраструктуру описанную в stage:
	terraform apply
	Для дальнейшей настроек возьмём адрес сервера 
	reddit-db-terraform-2 - 51.250.14.42

	- Создадим inventory файл с настройками:
	appserver ansible_host=35.195.186.154 ansible_user=appuser (пользователь по ДЗ terraform-2 был ubuntu, меняю в настройках) \ ansible_private_key_file=~/.ssh/appuser
	- Убедимся, что Ansible может управлять нашим хостом. Используем команду ansible для вызова модуля ping из командной строки:
	ansible dbserver -i ./inventory -m ping
	результат
	appserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "ping": "pong"
	}
	
	- повторяем для app сервера 51.250.77.42
	oem@oem-VirtualBox:~/Documents/Git_infra/M1kH61l_infra/ansible$ ansible appserver -i ./inventory -m ping
	The authenticity of host '51.250.77.42 (51.250.77.42)' can't be established.
	ECDSA key fingerprint is SHA256:RicPgSqxifI8t6Dwu7hlBO4zkMEVpj+1UmhN/Umc63A.
	Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
	appserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "ping": "pong"
	
	================================================
	
	=  Параметры ansible.cfg
	
	================================================
	
	Создаем файл конфигурации ansible.cfg
	[defaults]
inventory = ./inventory
remote_user = appuser (заменил на ubuntu)
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
	
	
	изменил inventory
	
	dbserver ansible_host=51.250.14.42
	appserver ansible_host=51.250.77.42
	
	Проверим работу
	
	ansible dbserver -m command -a uptime
	dbserver | CHANGED | rc=0 >>
	 20:21:21 up  1:32,  1 user,  load average: 0.00, 0.00, 0.00
	
	ansible appserver -m command -a uptime
	appserver | CHANGED | rc=0 >>
	 20:22:04 up  1:33,  1 user,  load average: 0.00, 0.00, 0.00
	
	============================================
	
	= Работа с группами
	
	============================================
	
	[db]
	dbserver ansible_host=51.250.14.42
	[app]
	appserver ansible_host=51.250.77.42
	
	проверим работу
	
	ansible app -m ping
	appserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "ping": "pong"
	}
	
	ansible db -m ping
	dbserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "ping": "pong"
	}
	
	=====================================
	= использование YAML inventory
	=====================================
	
	Скопируем данные из inventory в inventory.yml
	
	проверим работу:
	
	ansible all -m ping -i inventory.yml
	appserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "ping": "pong"
	}
	dbserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "ping": "pong"
	}
	
	
	===============================
	= Выполнение команд
	===============================
	
	выполним команды:
	
	ansible app -m command -a 'ruby -v'
	appserver | CHANGED | rc=0 >>
	ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
	
	ansible app -m command -a 'bundler -v'
	appserver | CHANGED | rc=0 >>
	Bundler version 1.11.2
	
	
	ansible app -m command -a 'ruby -v; bundler -v'
	appserver | FAILED | rc=1 >>
	ruby: invalid option -;  (-h will show valid options) (RuntimeError)non-zero return code
	oem@oem-VirtualBox:~/Documents/Git_infra/M1kH61l_infra/ansible$  ansible app -m shell -a 'ruby -v; bundler -v'
	appserver | CHANGED | rc=0 >>
	ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
	Bundler version 1.11.2
	
	
	------------------------------------
	
	ansible db -m command -a 'systemctl status mongod'
	
	dbserver | CHANGED | rc=0 >>
	● mongod.service - High-performance, schema-free document-oriented database
	   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
	   Active: active (running) since Sun 2022-04-24 18:48:49 UTC; 2 days ago
	     Docs: https://docs.mongodb.org/manual
	 Main PID: 644 (mongod)
	   CGroup: /system.slice/mongod.service
	           └─644 /usr/bin/mongod --quiet --config /etc/mongod.conf
	
	Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
	
	ansible db -m systemd -a name=mongod
	dbserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "name": "mongod",
	    "status": {
	        "ActiveEnterTimestamp": "Sun 2022-04-24 18:48:49 UTC",
	        "ActiveEnterTimestampMonotonic": "15652838",
	        "ActiveExitTimestampMonotonic": "0",
	        "ActiveState": "active",
	        "After": "network.target basic.target systemd-journald.socket sysinit.target system.slice",
	        "AllowIsolate": "no",
	
	ansible db -m service -a name=mongod
	dbserver | SUCCESS => {
	    "ansible_facts": {
	        "discovered_interpreter_python": "/usr/bin/python3"
	    },
	    "changed": false,
	    "name": "mongod",
	    "status": {
	
	Нпмшем play book ansible/clone.yml
	- name: Clone
	 hosts: app
	 tasks:
	 - name: Clone repo
	 git:
	 repo: https://github.com/express42/reddit.git
	 dest: /home/appuser/reddit
	
	Выполним ansible-playbook clone.yml
	PLAY RECAP *********************************************************************
	appserver                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
	
	
	
	Выпоню ansible app -m command -a 'rm -rf ~/reddit'
	и повторно ansible-playbook clone.yml
	
	PLAY RECAP *********************************************************************
appserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
