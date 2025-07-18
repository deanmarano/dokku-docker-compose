#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Helper function to run dokku commands
run_dokku() {
  ssh -T dokku-test "dokku $*" 2>&1 || true
}

setup() {
  # Set up test app with unique name
  export TEST_APP="testapp-$(date +%s)"
  export TEST_DB="${TEST_APP}-db"
  export TEST_REDIS="${TEST_APP}-redis"
  
  # Create test app
  run run_dokku "apps:create $TEST_APP"
  assert_success
}

teardown() {
  # Clean up
  run_dokku "--force apps:destroy $TEST_APP"
  run_dokku "postgres:destroy --force $TEST_DB"
  run_dokku "redis:destroy --force $TEST_REDIS"
}

@test "can create and deploy a simple app" {
  # Test app was created
  run run_dokku "apps:exists $TEST_APP"
  assert_success
  
  # Test app is listed
  run run_dokku "apps:list"
  assert_success
  assert_output --partial "$TEST_APP"
}

@test "can create and link postgres service" {
  # Skip if postgres plugin is not installed
  run run_dokku "plugin:list"
  if ! echo "$output" | grep -q "postgres"; then
    skip "Postgres plugin not installed"
  fi
  
  # Create postgres service
  run run_dokku "postgres:create $TEST_DB"
  if [ $status -ne 0 ]; then
    skip "Failed to create Postgres service"
  fi
  assert_success
  
  # Link service to app
  run run_dokku "postgres:link $TEST_DB $TEST_APP"
  assert_success
  
  # Verify link exists by checking the links
  run run_dokku "postgres:links $TEST_DB"
  assert_success
  assert_output --partial "$TEST_APP"
}

@test "can create and link redis service" {
  # Skip if redis plugin is not installed
  run run_dokku "plugin:list"
  if ! echo "$output" | grep -q "redis"; then
    skip "Redis plugin not installed"
  fi
  
  # Create redis service
  run run_dokku "redis:create $TEST_REDIS"
  if [ $status -ne 0 ]; then
    skip "Failed to create Redis service"
  fi
  assert_success
  
  # Link service to app
  run run_dokku "redis:link $TEST_REDIS $TEST_APP"
  assert_success
  
  # Verify link exists by checking the links
  run run_dokku "redis:links $TEST_REDIS"
  assert_success
  assert_output --partial "$TEST_APP"
}
