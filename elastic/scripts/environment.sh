#!/bin/bash
set -e

echo "Setup environment"
sudo mkdir -p /etc/service
sudo mv /tmp/elastic-environment /etc/service/elastic-environment
chmod 0644 /etc/service/elastic-environment

echo "Installing Upstart service..."
sudo mv /tmp/upstart.conf /etc/init/elasticsearch.conf
