#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Helper function to run dokku commands
run_dokku() {
  ssh -T dokku-test "$@"
}

setup() {
  # Set up test app with unique name
  export TEST_APP="testapp-$(date +%s)"
  export TEST_DB="${TEST_APP}-db"
  export TEST_REDIS="${TEST_APP}-redis"
  
  # Create test app
  run_dokku "apps:create $TEST_APP"
}

teardown() {
  # Clean up
  run_dokku "--force apps:destroy $TEST_APP" || true
  run_dokku "postgres:destroy --force $TEST_DB" || true
  run_dokku "redis:destroy --force $TEST_REDIS" || true
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
  # Create postgres service
  run run_dokku "postgres:create $TEST_DB"
  assert_success
  
  # Link service to app
  run run_dokku "postgres:link $TEST_DB $TEST_APP"
  assert_success
  
  # Verify link exists
  run run_dokku "postgres:info $TEST_DB --do-export"
  assert_success
  assert_output --partial "$TEST_APP"
}

@test "can create and link redis service" {
  # Create redis service
  run run_dokku "redis:create $TEST_REDIS"
  assert_success
  
  # Link service to app
  run run_dokku "redis:link $TEST_REDIS $TEST_APP"
  assert_success
  
  # Verify link exists
  run run_dokku "redis:info $TEST_REDIS --do-export"
  assert_success
  assert_output --partial "$TEST_APP"
}
