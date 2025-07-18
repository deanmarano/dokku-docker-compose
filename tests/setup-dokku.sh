#!/bin/bash
set -e

# Install dependencies
apt-get update
apt-get install -y ssh-client netcat

# Wait for Dokku to be ready
echo "Waiting for Dokku to be ready..."
until nc -z localhost 2222; do
  sleep 1
done

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
  mkdir -p ~/.ssh
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/*
fi

# Configure SSH
eval "$(ssh-agent -s)"
ssh-keyscan -p 2222 -t rsa localhost >> ~/.ssh/known_hosts

# Create SSH config
cat > ~/.ssh/config << 'EOL'
Host dokku-test
  HostName localhost
  Port 2222
  User root
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentityFile ~/.ssh/id_rsa
EOL

# Install required plugins
echo "Installing Dokku plugins..."
ssh -T dokku-test "\
  dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres && \
  dokku plugin:install https://github.com/dokku/dokku-redis.git redis && \
  dokku plugin:install https://github.com/dokku/dokku-mysql.git mysql"

echo "Dokku test environment is ready!"
