# Dokku Docker Compose Plugin

A Dokku plugin for importing Docker Compose files into Dokku applications.

## Features

- Import `docker-compose.yml` files into Dokku
- Map Compose services to Dokku apps
- Handle volumes, networks, and environment variables
- Support for Docker Compose v2 and v3 formats
- Integration with existing Dokku plugins

## Installation

```bash
# On your dokku server
sudo dokku plugin:install https://github.com/deanmarano/dokku-docker-compose.git docker-compose
```

## Usage

### Import a Docker Compose file

```bash
# In a directory containing docker-compose.yml
dokku docker-compose:import

# Or specify a custom compose file
dokku docker-compose:import -f docker-compose.prod.yml

# Dry run to see what will be created
dokku docker-compose:import --dry-run
```

### Help

```bash
# Show help
dokku docker-compose:help

# Show version
dokku docker-compose:version
```

## Development

### Prerequisites

- Bash 4.0+
- Dokku 0.30.0+
- Docker
- Docker Compose or Docker Compose Plugin

### Running Tests

```bash
# Install test dependencies
bats_install="https://git.io/bats-install"
curl -sSL $bats_install | bash

# Run tests
bats tests
```

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Author

Dean Marano
