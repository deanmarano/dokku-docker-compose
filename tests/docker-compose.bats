#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

# Set up test environment
setup() {
  # Create a temporary directory for tests
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR" || exit 1
  
  # Create a simple docker-compose.yml for testing
  cat > docker-compose.yml <<EOF
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: example
EOF
}

# Clean up after tests
teardown() {
  if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

@test "plugin is installed" {
  run dokku plugin:installed docker-compose
  assert_success
}

@test "help command works" {
  run dokku docker-compose:help
  assert_success
  assert_output --partial "Manage Docker Compose deployments in Dokku"
}

@test "version command works" {
  run dokku docker-compose:version
  assert_success
  assert_output --partial "dokku-docker-compose"
}

@test "import command with dry run" {
  run dokku docker-compose:import --dry-run
  assert_success
  assert_output --partial "Dry run: Would import"
}

@test "fails with invalid compose file" {
  echo "invalid yaml" > docker-compose.yml
  run dokku docker-compose:import
  assert_failure
  assert_output --partial "Invalid compose file"
}
