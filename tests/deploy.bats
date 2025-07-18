#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
  # Set up test app with unique name
  export TEST_APP="nodeapp-$(date +%s)"
  export TEST_DIR="/tmp/${TEST_APP}"
  
  # Create test app
  mkdir -p "${TEST_DIR}"
  cp -r tests/test-apps/simple-nodejs/* "${TEST_DIR}/"
  
  # Initialize git repo
  cd "${TEST_DIR}" || exit 1
  git init
  git config user.name "Test User"
  git config user.email "test@example.com"
  git add .
  git commit -m "Initial commit"
  
  # Create Dokku app
  ssh -T dokku-test "apps:create ${TEST_APP}"
}

teardown() {
  # Clean up
  cd /tmp || true
  rm -rf "${TEST_DIR}" || true
  ssh -T dokku-test "--force apps:destroy ${TEST_APP}" || true
}

@test "can deploy a Node.js app" {
  # Add Dokku remote
  cd "${TEST_DIR}" || exit 1
  git remote add dokku "dokku@localhost:${TEST_APP}"
  
  # Push to Dokku
  run git push dokku main:master
  assert_success
  
  # Verify app is running
  sleep 5  # Give it time to start
  run curl -s "http://localhost:8080"
  assert_success
  assert_output --partial "Hello from Node.js app!"
}
