#!/bin/sh
apt list --upgradable
apt update
apt install -y ruby-full ruby-bundler build-essential
