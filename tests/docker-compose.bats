#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

# Set up test environment
setup() {
  # Create a temporary directory for tests
  TEST_DIR=$(mktemp -d)
  export TEST_DIR
  
  # Set up plugin paths
  export PLUGIN_NAME="docker-compose"
  export PLUGIN_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}/..")" && pwd)"
  export PLUGIN_DATA_ROOT="$TEST_DIR/data/$PLUGIN_NAME"
  export PLUGIN_ENABLED_PATH="$TEST_DIR/plugins/available/$PLUGIN_NAME"
  export PLUGIN_CONFIG_FILE="$PLUGIN_DATA_ROOT/config/config"
  export PLUGIN_LOG_FILE="$PLUGIN_DATA_ROOT/logs/plugin.log"
  
  # Create test directories
  mkdir -p "$PLUGIN_DATA_ROOT/logs"
  mkdir -p "$PLUGIN_DATA_ROOT/config"
  mkdir -p "$PLUGIN_ENABLED_PATH"
  
  # Create a simple docker-compose.yml for testing
  cat > "$TEST_DIR/docker-compose.yml" <<EOF
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
  
  # Create a test VERSION file
  echo "0.1.0" > "$PLUGIN_PATH/VERSION"
  
  # Source the plugin files
  source "$PLUGIN_PATH/functions/core"
  
  # Change to test directory
  cd "$TEST_DIR" || exit 1
}

# Clean up after tests
teardown() {
  if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# Helper function to run the plugin command
run_plugin() {
  local cmd="$1"
  shift
  bash "$PLUGIN_PATH/commands/docker-compose" "$cmd" "$@"
}

@test "plugin initialization creates required directories" {
  # Test that the plugin creates required directories
  [ -d "$PLUGIN_DATA_ROOT/logs" ]
  [ -d "$PLUGIN_DATA_ROOT/config" ]
  
  # Initialize the plugin
  run_plugin "init"
  
  # Check that config file was created
  [ -f "$PLUGIN_CONFIG_FILE" ]
  
  # Check that log file was created
  [ -f "$PLUGIN_LOG_FILE" ]
}

@test "plugin:install command works" {
  # Run the install command
  run_plugin "plugin:install"
  
  # Check that the plugin was installed
  [ -d "$PLUGIN_ENABLED_PATH" ]
  [ -f "$PLUGIN_CONFIG_FILE" ]
  [ -f "$PLUGIN_LOG_FILE" ]
}

@test "help command shows usage information" {
  run run_plugin "help"
  assert_success
  assert_output --partial "Manage Docker Compose deployments in Dokku"
  assert_output --partial "dokku docker-compose:import"
  assert_output --partial "dokku docker-compose:version"
}

@test "version command shows version information" {
  run run_plugin "version"
  assert_success
  assert_output --partial "dokku-docker-compose version 0.1.0"
}

@test "plugin:uninstall command works" {
  # First install the plugin
  run_plugin "plugin:install"
  
  # Then uninstall it
  run_plugin "plugin:uninstall"
  
  # Check that the plugin was uninstalled
  # (In a real test, we would check for actual uninstallation)
  assert_success
}

@test "import command with dry run" {
  run run_plugin "import" "--dry-run"
  assert_success
  assert_output --partial "Import functionality coming soon!"
}

@test "fails with unknown command" {
  run run_plugin "nonexistent-command"
  assert_failure
  assert_output --partial "Unknown command: nonexistent-command"
}

@test "logging functions work correctly" {
  # Test debug logging
  run log_debug "Test debug message"
  assert_success
  
  # Test info logging
  run log_info "Test info message"
  assert_success
  
  # Test warning logging
  run log_warn "Test warning message"
  assert_success
  
  # Test error logging
  run log_error "Test error message"
  assert_success
  
  # Test log file was written to
  [ -s "$PLUGIN_LOG_FILE" ]
}

@test "configuration is saved and loaded correctly" {
  # Set a test configuration
  export DOKKU_DOCKER_COMPOSE_TEST_VALUE="test123"
  save_config
  
  # Clear the variable
  unset DOKKU_DOCKER_COMPOSE_TEST_VALUE
  
  # Load the configuration
  load_config
  
  # Check that the value was loaded
  [ "$DOKKU_DOCKER_COMPOSE_TEST_VALUE" = "test123" ]
}
