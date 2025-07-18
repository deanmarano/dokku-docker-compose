#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
section() {
  echo -e "\n${GREEN}### $1 ###${NC}"
}

# Start the test environment
section "Starting test environment"
docker-compose -f docker-compose.test.yml up -d

# Wait for Dokku to be ready
section "Waiting for Dokku to be ready"
sleep 10

# Set up SSH access
section "Setting up SSH access"
chmod +x tests/setup-dokku.sh
./tests/setup-dokku.sh

# Run unit tests
section "Running unit tests"
if ! bats tests/parser.bats; then
  echo -e "${RED}Unit tests failed!${NC}"
  docker-compose -f docker-compose.test.yml down
  exit 1
fi

# Run integration tests
section "Running integration tests"
if ! bats tests/integration.bats; then
  echo -e "${RED}Integration tests failed!${NC}"
  docker-compose -f docker-compose.test.yml down
  exit 1
fi

# Run deployment tests
section "Running deployment tests"
if ! bats tests/deploy.bats; then
  echo -e "${RED}Deployment tests failed!${NC}"
  docker-compose -f docker-compose.test.yml down
  exit 1
fi

# Clean up
section "Tests completed successfully!"
docker-compose -f docker-compose.test.yml down

echo -e "\n${GREEN}All tests passed!${NC}"
