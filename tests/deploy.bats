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
  
  # Ensure we're on the master branch
  git branch -M master
  
  # Create Dokku app
  ssh -T dokku-test "dokku apps:create ${TEST_APP}"
}

teardown() {
  # Clean up
  cd /tmp || true
  rm -rf "${TEST_DIR}" || true
  ssh -T dokku-test "dokku --force apps:destroy ${TEST_APP}" || true
}

@test "can deploy a simple web app" {
  # Skip this test in CI environment as it requires Docker
  if [ -n "$CI" ]; then
    skip "Skipping deployment test in CI environment"
  fi
  
  # Find an available port
  local test_port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()' 2>/dev/null || echo "8083")
  
  # Create a temporary directory for the test
  local temp_dir=$(mktemp -d)
  cd "${temp_dir}" || exit 1
  
  # Create a simple index.html file
  mkdir -p html
  echo "<html><body><h1>Test Page</h1></body></html>" > html/index.html
  
  # Create a simple Dockerfile for the app
  cat > Dockerfile << EOL
FROM nginx:alpine
COPY html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOL
  
  # Build the Docker image
  docker build -t ${TEST_APP} .
  
  # Run the container
  container_id=$(docker run -d -p ${test_port}:80 --name ${TEST_APP} ${TEST_APP})
  
  # Wait for the container to start
  sleep 5
  
  # Check if the container is running
  run docker ps --filter "name=${TEST_APP}" --format '{{.Status}}'
  assert_success
  assert_output --partial "Up"
  
  # Test if the web server is responding
  run curl -s -o /dev/null -w "%{http_code}" "http://localhost:${test_port}"
  assert_success
  assert_output "200"
  
  # Test if the content is correct
  run curl -s "http://localhost:${test_port}"
  assert_success
  assert_output --partial "Test Page"
  
  # Clean up
  docker stop ${TEST_APP} || true
  docker rm -f ${TEST_APP} || true
  docker rmi -f ${TEST_APP} || true
  cd /tmp
  rm -rf "${temp_dir}"
}
