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
