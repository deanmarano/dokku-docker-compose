# Testing Strategy for Dokku Docker Compose Plugin

## Test Types

### 1. Plugin Integration Tests
**Purpose**: Test integration with various Dokku plugins
**Location**: `tests/integration/plugins/`
**What to test**:
- Plugin detection and selection
- Configuration mapping from docker-compose to plugin
- Service linking with plugins
- Fallback behavior when plugins are not available
- Version-specific plugin features

### 2. Unit Tests
**Purpose**: Test individual functions in isolation
**Tools**: [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System)
**Location**: `tests/unit/`
**What to test**:
- Small, pure functions
- Input validation
- Output formatting
- Error conditions

Example test file structure:
```
tests/unit/
  ├── test_helpers.bats
  ├── test_validation.bats
  └── test_parser.bats
```

### 3. Integration Tests
**Purpose**: Test interactions between components
**Tools**: bats-core, Docker-in-Docker (DinD)
**Location**: `tests/integration/`
**What to test**:
- Component interactions
- File system operations
- Command execution
- Docker API interactions

### 4. End-to-End (E2E) Tests
**Purpose**: Test the plugin in a real Dokku environment
**Tools**: 
- [Dokku Test Suite](http://dokku.viewdocs.io/dokku/development/testing/)
- Docker Compose test environments
**Location**: `tests/e2e/`
**What to test**:
- Full plugin commands
- Real Dokku app creation
- Network and volume handling
- Multi-service scenarios

## Test Environment

### Plugin-Specific Test Setup
For testing with different Dokku plugins, we'll use a matrix approach:

```yaml
# .github/workflows/test-plugins.yml
name: Test with Dokku Plugins

on: [push, pull_request]

jobs:
  test-plugins:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        plugin: [postgres, redis, memcached, mysql, mariadb, mongo]
    steps:
      - uses: actions/checkout@v3
      - name: Set up Dokku
        run: |
          wget https://raw.githubusercontent.com/dokku/dokku/v0.30.0/bootstrap.sh
          sudo DOKKU_TAG=v0.30.0 bash bootstrap.sh
      - name: Install ${{ matrix.plugin }} plugin
        run: |
          sudo dokku plugin:install https://github.com/dokku/dokku-${{ matrix.plugin }}.git ${{ matrix.plugin }}
      - name: Run plugin tests
        run: |
          PLUGIN=${{ matrix.plugin }} bats tests/integration/plugins/
```

### Prerequisites
- Docker
- Docker Compose
- bats-core (`brew install bats-core` on macOS)
- yq (`brew install yq`)
- jq (`brew install jq`)

### Setup
1. Clone the repository
2. Run `make test-deps` to install test dependencies
3. Run `make test` to execute all tests

## Test Structure

### Test Data
Sample Docker Compose files for testing:
```
testdata/
  ├── simple/
  │   ├── docker-compose.yml
  │   └── expected/
  ├── multi-service/
  │   ├── docker-compose.yml
  │   └── expected/
  └── edge-cases/
      ├── invalid-yaml.yml
      └── unsupported-version.yml
```

### Test Helpers
Create reusable test utilities in `tests/test_helper.bash`:
```bash
#!/usr/bin/env bash

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    
    # Set up test environment
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR" || exit 1
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_DIR"
}

# Helper functions...
```

## Writing Plugin Integration Tests

### Example Plugin Test
```bash
@test "import with postgres plugin" {
    # Setup
    local test_dir="$(mktemp -d)"
    cd "$test_dir" || exit 1
    
    # Create test compose file
    cat > docker-compose.yml <<EOL
version: '3.8'
services:
  app:
    image: nginx:alpine
    environment:
      - DB_URL=postgres://user:pass@db:5432/mydb
    depends_on:
      - db
  db:
    image: postgres:13
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
EOL

    # Run import
    run dokku docker-compose:import docker-compose.yml
    assert_success
    
    # Verify postgres plugin was used
    run dokku postgres:list
    assert_success
    assert_output --partial "app-db"
    
    # Verify linking
    run dokku postgres:linked app
    assert_success
    assert_output --partial "app-db"
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"
}
```

### Testing Plugin Installation Instructions

```bash
@test "show installation instructions when plugin is missing" {
    # Setup
    local test_dir="$(mktemp -d)"
    cd "$test_dir" || exit 1
    
    # Create test compose file
    cat > docker-compose.yml <<EOL
version: '3.8'
services:
  db:
    image: postgres:13
EOL

    # Mock dokku command to simulate missing plugin
    dokku() {
        if [[ "$1" == "plugin:list" ]]; then
            echo "  00_dokku-standard    0.30.0 enabled    dokku core standard plugin"
            return 0
        fi
        return 1
    }
    export -f dokku
    
    # Run import and capture output
    run dokku docker-compose:import docker-compose.yml
    
    # Assert
    assert_failure
    assert_output --partial "Required plugin 'postgres' is not installed"
    assert_output --regexp "To install.*dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres"
    assert_output --partial "Use --skip-plugin=postgres to continue without this plugin"
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"
}

@test "continue with --skip-plugin flag" {
    # Setup
    local test_dir="$(mktemp -d)"
    cd "$test_dir" || exit 1
    
    # Create test compose file
    cat > docker-compose.yml <<EOL
version: '3.8'
services:
  app:
    image: nginx:alpine
    depends_on:
      - db
  db:
    image: postgres:13
EOL

    # Mock dokku command to simulate missing plugin
    dokku() {
        if [[ "$1" == "plugin:list" ]]; then
            echo "  00_dokku-standard    0.30.0 enabled    dokku core standard plugin"
            return 0
        fi
        # Allow other dokku commands to pass through
        command dokku "$@"
    }
    export -f dokku
    
    # Run import with skip plugin flag
    run dokku docker-compose:import --skip-plugin=postgres docker-compose.yml
    
    # Assert
    assert_success
    assert_output --partial "Skipping postgres plugin as requested"
    assert_output --partial "Using container for service: db"
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"
}

### Testing Fallback Behavior
```bash
@test "fallback to container when plugin not available" {
    # Setup
    local test_dir="$(mktemp -d)"
    cd "$test_dir" || exit 1
    
    # Create test compose file
    cat > docker-compose.yml <<EOL
version: '3.8'
services:
  app:
    image: nginx:alpine
    depends_on:
      - db
  db:
    image: postgres:13
EOL

    # Uninstall postgres plugin if installed
    if dokku plugin:installed postgres; then
        skip "Postgres plugin is installed"
    fi
    
    # Run import
    run dokku docker-compose:import docker-compose.yml
    assert_success
    
    # Verify container was created instead of using plugin
    run docker ps --format '{{.Names}}' | grep app-db
    assert_success
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"
}
```

## Writing Tests

### Example Unit Tests for Plugin Detection

```bash
@test "get_plugin_installation_command returns correct command" {
    # Test with postgres
    run get_plugin_installation_command postgres
    assert_success
    assert_output "dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres"
    
    # Test with redis
    run get_plugin_installation_command redis
    assert_success
    assert_output "dokku plugin:install https://github.com/dokku/dokku-redis.git redis"
}

@test "check_plugin_installed detects missing plugin" {
    # Mock dokku command for missing plugin
    dokku() {
        if [[ "$1" == "plugin:list" ]]; then
            echo "  00_dokku-standard    0.30.0 enabled    dokku core standard plugin"
            return 0
        fi
        return 1
    }
    export -f dokku
    
    run check_plugin_installed postgres
    assert_failure
    assert_output --partial "postgres plugin is not installed"
}

@test "generate_skip_plugins_option generates correct flags" {
    # Test single plugin
    run generate_skip_plugins_option "postgres"
    assert_success
    assert_output "--skip-plugin=postgres"
    
    # Test multiple plugins
    run generate_skip_plugins_option "postgres redis"
    assert_success
    assert_output "--skip-plugin=postgres --skip-plugin=redis"
}
```

### Example Plugin Unit Test
```bash
@test "detect_postgres_plugin" {
    # Mock dokku command
    dokku() {
        if [[ "$1" == "plugin:list" ]]; then
            echo "  00_dokku-standard    0.30.0 enabled    dokku core standard plugin"
            echo "  postgres            1.15.0 enabled    dokku postgres service plugin"
            return 0
        fi
        return 1
    }
    export -f dokku

    # Run test
    run detect_plugin 'postgres:13'
    
    # Assert
    assert_success
    assert_output "postgres"
}

@test "map_postgres_config" {
    # Setup test data
    local service_config=$(cat <<EOL
{
    "image": "postgres:13",
    "environment": {
        "POSTGRES_USER": "user",
        "POSTGRES_PASSWORD": "pass",
        "POSTGRES_DB": "mydb"
    },
    "volumes": ["pgdata:/var/lib/postgresql/data"]
}
EOL
    )

    # Run test
    run map_plugin_config "postgres" "$service_config"
    
    # Assert
    assert_success
    assert_line "--config-opt POSTGRES_USER=user"
    assert_line "--config-opt POSTGRES_PASSWORD=pass"
    assert_line "--config-opt POSTGRES_DB=mydb"
}
```

### Example Unit Test
```bash
#!/usr/bin/env bats

load 'test_helper'

@test "validate_compose_file with valid file" {
    # Setup
    cat > docker-compose.yml <<EOL
version: '3.8'
services:
  web:
    image: nginx:alpine
EOL
    
    # Execute
    run validate_compose_file "docker-compose.yml"
    
    # Assert
    assert_success
    assert_output --partial "Valid compose file"
}
```

### Example Integration Test
```bash
@test "import creates dokku apps from compose file" {
    # Setup test compose file
    # ...
    
    # Execute import
    run dokku docker-compose:import docker-compose.yml
    
    # Assert apps were created
    run dokku apps:list
    assert_success
    assert_output --partial "web"
    assert_output --partial "db"
}
```

## Continuous Integration

### GitHub Actions
Example workflow (`.github/workflows/test.yml`):
```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      docker:
        image: docker:dind
        options: >-
          --privileged
          --network=host
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker
        run: |
          docker --version
          docker-compose --version
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y bats jq
          sudo pip install yq
      
      - name: Run unit tests
        run: make test-unit
      
      - name: Run integration tests
        run: make test-integration
        
      - name: Run e2e tests
        run: make test-e2e
```

## Test Coverage

### Coverage Reporting
Use `kcov` for code coverage:
```bash
# Install kcov
brew install kcov

# Run tests with coverage
make coverage
```

### Coverage Reports
- HTML reports in `coverage/`
- Publish to codecov.io or similar service

## Best Practices

1. **Test Isolation**: Each test should be independent
2. **Descriptive Names**: Use clear, descriptive test names
3. **Minimal Fixtures**: Keep test data minimal and focused
4. **Test Edge Cases**: Include tests for error conditions
5. **Fast Feedback**: Keep tests fast for quick iteration

## Debugging Tests

Run a single test file:
```bash
bats tests/unit/test_parser.bats
```

Run with debug output:
```bash
bats --tap tests/
```

## Performance Testing

For large compose files, add performance benchmarks:
```bash
@test "import handles large compose files quickly" {
    # Generate large compose file
    # ...
    
    # Time the import
    run time dokku docker-compose:import large-compose.yml
    
    # Assert it completes within time limit
    assert_success
    assert_output --regexp 'real\s+0:[0-4]\d\.[0-9]s'  # Less than 5 seconds
}
```

## Mocking

For testing without real Dokku/Docker:

1. Create mocks in `tests/mocks/`
2. Override commands in test setup:
   ```bash
   dokku() {
       echo "[MOCK] dokku $*" >> "$TEST_MOCK_LOG"
       case "$1" in
           apps:exists)
               return 1  # App doesn't exist
               ;;
           --version)
               echo "0.30.0"
               ;;
           *)
               echo "Unexpected dokku command: $*"
               return 1
               ;;
       esac
   }
   export -f dokku
   ```

## Test Maintenance

1. Update tests when adding new features
2. Review test failures carefully
3. Keep test data up-to-date
4. Document test cases in pull requests
