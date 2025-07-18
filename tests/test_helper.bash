#!/usr/bin/env bash

# Set the path to the BATS helpers
export BATS_HELPER_PATH="${BATS_TEST_DIRNAME}/test_helper"

# Load BATS helper libraries
load "${BATS_HELPER_PATH}/bats-support/load.bash"
load "${BATS_HELPER_PATH}/bats-assert/load.bash"
load "${BATS_HELPER_PATH}/bats-file/load.bash"

# Setup function that runs before each test
setup() {
  # Add any test setup code here
  :
}

# Teardown function that runs after each test
teardown() {
  # Add any test teardown code here
  :
}
