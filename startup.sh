#!/bin/bash

adduser yc-user
mkdir -p /home/yc-user/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCMOg1hBlT4noPkjo27us7MqFD1VUVFvm7Q8sAyu3ULVMehxbz8oLIQkWShdU5zXQnB+6YU4iOsz3MrMVwlTM0rcnmuMq7fQXKtcN3f3bAS4G1NOKi5oseHEdxeoJ7vegjYswhINQS01nHAdplWpLgpbMCt5QuOX1Tb+IDZqlIwoIPYhGfvQhwNPp1EuHlXw3aUyZH6Gx14FYUbE1wsgDMfetF3WcZswsQN0zmBu8aZf9lYjT3cyfoBg47d7ni13f53uowOFr+KYVKSyaCCoiftbFFeGbYfvvLsq5FrU6VL2dixNuzwYlOlnW0ylvqXB20iN4NFwyLKOYTIbQxfYLptpmjTkktN/VsN3W/uuD9a38= appuser' > /home/yc-user/.ssh/authorized_keys
echo 'yc-user  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

sudo apt update

sudo apt install -y ruby-full ruby-bundler build-essential

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -

echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

sudo apt update

sudo apt-get install -y mongodb-org

sudo systemctl start mongod
sudo systemctl enable mongod

sudo apt install -y git

cd /home/yc-user

git clone -b monolith https://github.com/express42/reddit.git

cd reddit && bundle install

puma -d
