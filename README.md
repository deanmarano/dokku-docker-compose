# Dokku Docker Compose Plugin

A Dokku plugin for importing and managing Docker Compose files in Dokku.

## Features

- **Docker Compose Support**: Full support for Docker Compose v2 and v3 files
- **Service Discovery**: Automatically detects and imports all services from your compose file
- **Dependency Resolution**: Handles service dependencies and deploys in the correct order
- **Plugin Integration**: Automatically detects and configures Dokku plugins for known services (PostgreSQL, Redis, etc.)
- **Resource Mapping**: Converts Docker Compose resources to Dokku equivalents:
  - Services → Dokku apps
  - Environment variables → Dokku config
  - Volumes → Dokku storage
  - Ports → Dokku proxy settings
- **Dry Run Mode**: Preview changes before applying them
- **Logging**: Comprehensive logging with multiple verbosity levels

## Installation

### Prerequisites

- Dokku 0.30.0 or later
- `yq` (for YAML parsing) - install with your package manager:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install yq
  
  # RHEL/CentOS
  sudo dnf install yq
  
  # macOS (Homebrew)
  brew install yq
  ```

### Install the Plugin

```bash
# Install from GitHub
dokku plugin:install https://github.com/deanmarano/dokku-docker-compose.git docker-compose
```

## Usage

### Import a Docker Compose File

```bash
# Import default docker-compose.yml in current directory
dokku docker-compose:import

# Specify a custom compose file
dokku docker-compose:import -f docker-compose.prod.yml

# Specify a project name (prefix for all created resources)
dokku docker-compose:import -p myproject

# Dry run (show what would be done without making changes)
dokku docker-compose:import --dry-run

# Show verbose output
dokku docker-compose:import -v
```

### Other Commands

```bash
# Show help
dokku docker-compose:help

# Show version information
dokku docker-compose:version

# Install the plugin (if not installed via git)
dokku docker-compose:plugin:install

# Uninstall the plugin
dokku docker-compose:plugin:uninstall
```

## How It Works

The plugin parses your Docker Compose file and maps the services to Dokku resources:

1. **Services** are converted to Dokku apps
2. **Environment variables** are set using `dokku config:set`
3. **Volumes** are created using Dokku's storage management
4. **Ports** are configured using Dokku's proxy settings
5. **Dependencies** between services are resolved and deployed in the correct order
6. **Plugins** are automatically detected and configured for known services

### Supported Docker Compose Features

- [x] Service definitions
- [x] Environment variables
- [x] Volumes (named, anonymous, and host paths)
- [x] Port mappings
- [x] Service dependencies
- [x] Networks (basic support)
- [ ] Build contexts
- [ ] Healthchecks
- [ ] Resource limits
- [ ] Secrets

### Plugin Integration

The plugin automatically detects and configures Dokku plugins for these services:

- PostgreSQL (`postgres`)
- MySQL (`mysql`)
- MariaDB (`mariadb`)
- Redis (`redis`)
- Memcached (`memcached`)
- MongoDB (`mongodb`)
- And more...

## Examples

### Basic Example

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    environment:
      - DEBUG=true
    depends_on:
      - db

  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: example
```

Running `dokku docker-compose:import` will:
1. Create a Dokku app for the `web` service
2. Create a PostgreSQL service for the `db` service
3. Link the PostgreSQL service to the web app
4. Configure the web app with the specified environment variables and ports

## Development

### Prerequisites

- Bash 4.0 or later
- Docker
- Docker Compose
- yq (for YAML parsing)
- BATS (for testing)

### Running Tests

```bash
# Install test dependencies
bats --version || (echo "Installing BATS..." && git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local)

# Run all tests
make test

# Run a specific test file
bats tests/parser.bats
```

## Configuration

You can configure the plugin using environment variables:

```bash
# Set log level (debug, info, warn, error, fatal)
export DOKKU_DOCKER_COMPOSE_LOG_LEVEL=info

# Set maximum number of retries for operations
export DOKKU_DOCKER_COMPOSE_MAX_RETRIES=3

# Set timeout in seconds for operations
export DOKKU_DOCKER_COMPOSE_TIMEOUT=300
```

## License

MIT

## Contributing

1. Fork the repository
2. Create a new branch for your feature
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Author

Dean Marano
