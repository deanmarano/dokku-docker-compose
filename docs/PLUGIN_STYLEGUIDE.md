# Dokku Plugin Style Guide

This document outlines the best practices and conventions for developing high-quality Dokku plugins, based on the patterns used in popular official plugins like dokku-postgres, dokku-redis, dokku-letsencrypt, and others.

## Plugin Types

Dokku plugins generally fall into three main categories, each with its own patterns and considerations:

### 1. Service Plugins (e.g., dokku-postgres, dokku-redis)
- Manage long-running services (databases, caches, etc.)
- Include full lifecycle management (create, destroy, backup, restore)
- Handle data persistence and migrations
- Support linking to applications
- Examples: PostgreSQL, Redis, MySQL, MongoDB

### 2. Utility Plugins (e.g., dokku-letsencrypt, dokku-http-auth)
- Add specific functionality to Dokku
- Often integrate with external services
- May run on schedules or triggers
- Examples: SSL certificates, authentication, monitoring

### 3. Core Plugins (e.g., dokku-postgres, dokku-redis)
- Provide fundamental infrastructure services
- Often bundled with Dokku
- Handle core functionality like networking, storage, etc.
- Examples: Network, Storage, Scheduler

## Table of Contents

1. [Project Structure](#project-structure)
2. [File Organization](#file-organization)
3. [Code Style](#code-style)
4. [Testing](#testing)
5. [Documentation](#documentation)
6. [Versioning](#versioning)
7. [CI/CD](#cicd)
8. [Common Patterns](#common-patterns)
9. [Best Practices](#best-practices)

## Project Structure

Dokku plugins follow a consistent structure that varies slightly based on the plugin type. Here's a comprehensive directory structure that covers all plugin types:

```
.
├── .github/                   # GitHub-specific files
│   ├── workflows/            # GitHub Actions workflows
│   │   ├── ci.yml           # Continuous Integration
│   │   └── release.yml      # Release automation
│   └── dependabot.yml       # Dependency updates
│
├── docs/                     # Documentation
│   ├── README.md            # Main documentation
│   ├── commands/            # Command references
│   └── examples/            # Usage examples
│
├── scripts/                  # Utility scripts (optional)
│   └── setup_*.sh           # Setup/configuration scripts
│
├── subcommands/             # Plugin subcommands (one file per subcommand)
│   ├── create              # Service creation
│   ├── destroy             # Service teardown
│   ├── backup              # Data backup
│   └── ...                 # Other commands
│
├── tests/                   # Test files
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   ├── test_helper.bash    # Test utilities
│   └── setup.sh            # Test setup
│
├── templates/               # Configuration templates (optional)
│   └── *.conf.sigil        # Sigil templates for configs
│
├── .editorconfig           # Editor configuration
├── .gitignore             # Git ignore rules
├── Dockerfile             # Development container
├── Makefile               # Build and test tasks
├── plugin.toml            # Plugin metadata
├── commands               # Plugin command definitions
├── common-functions       # Shared shell functions
├── help-functions         # Help text generation
└── README.md             # Project overview
```

### Key Files Explained:

1. **plugin.toml**
   - Required for all plugins
   - Defines plugin metadata and configuration
   - Example:
     ```toml
     [plugin]
     description = "Postgres service plugin"
     version = "1.0.0"
     
     [plugin.config]
     # Default configuration values
     "docker-options" = "--restart=on-failure:10"
     ```

2. **commands**
   - Defines the main plugin commands
   - Maps commands to their implementations
   - Example:
     ```
     postgres:create  postgres-create
     postgres:destroy postgres-destroy
     ```

3. **subcommands/**
   - One file per subcommand
   - Naming: `plugin-command` (e.g., `postgres-create`)
   - Each file should be executable and include help text

4. **tests/**
   - BATS test files
   - Mirror the command structure
   - Include both unit and integration tests

## File Organization

### Core Files

1. **plugin.toml**
   - Contains plugin metadata and configuration
   - Defines plugin name, version, and dependencies
   - Example:
     ```toml
     [plugin]
     description = "Postgres service plugin"
     version = "1.15.0"
     [plugin.config]
     "docker-options" = "--restart=on-failure:10"
     ```

2. **Makefile**
   - Standard build and test targets
   - Common targets: `build`, `test`, `lint`, `install`
   - Example:
     ```makefile
     .PHONY: test
     test:
     	@bats tests/
     ```

3. **Dockerfile**
   - Defines the development environment
   - Includes all necessary build tools and dependencies

### Subcommands

- Each subcommand is a separate file in the `subcommands/` directory
- Naming convention: `subcommands/<command>-<subcommand>`
- Example: `subcommands/service-create`, `subcommands/service-logs`

### Documentation

- Comprehensive README.md with:
  - Installation instructions
  - Basic usage examples
  - Available commands
  - Configuration options
  - Troubleshooting

## Code Style

### Shell Scripting

- Use `#!/usr/bin/env bash` for portability
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use `local` for function-scoped variables
- Quote all variables to prevent word splitting
- Use `[[` for tests instead of `[`
- Example:
  ```bash
  #!/usr/bin/env bash
  
  set -eo pipefail
  
  my_function() {
      local var1="value1"
      local var2="value2"
      
      if [[ "$var1" == "$var2" ]]; then
          echo "Values are equal"
      fi
  }
  ```

### Error Handling

- Use `set -eo pipefail` at the start of scripts
- Provide meaningful error messages
- Use `trap` for cleanup operations
- Example:
  ```bash
  cleanup() {
      rm -f "$TEMP_FILE"
  }
  trap cleanup EXIT
  ```

## Testing

### Test Structure

- Use [bats-core](https://github.com/bats-core/bats-core) for testing
- Organize tests by functionality
- Follow naming convention: `tests/<feature>_test.bats`
- Example test file:
  ```bash
  #!/usr/bin/env bats
  
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  
  setup() {
      # Test setup code
  }
  
  teardown() {
      # Test teardown code
  }
  
  @test "service create should succeed" {
      run dokku postgres:create test-db
      assert_success
      assert_output --partial "PostgreSQL container created: test-db"
  }
  ```

### Test Coverage

- Test all subcommands
- Include error cases
- Test edge cases
- Mock external dependencies
- Use test fixtures for complex data

## Documentation

### Command Help

- Include help text for all commands
- Use `dokku <plugin>:help <command>` pattern
- Document all options and arguments
- Example:
  ```bash
  help() {
      cat <<EOF
  Usage: dokku postgres:create <name> [options]
  
  Create a new PostgreSQL service.
  
  Options:
      --config-opt KEY=VALUE  Set configuration option
      --image IMAGE         Use custom Docker image
  EOF
  }
  ```

### Man Pages

- Include man pages for complex commands
- Use `ronn` or similar tool to generate man pages from markdown
- Example: `docs/man/dokku-postgres-create.1.ronn`

## Versioning

- Follow [Semantic Versioning](https://semver.org/)
- Update version in `plugin.toml`
- Create GitHub releases with changelog
- Tag releases with `v` prefix (e.g., `v1.0.0`)

## CI/CD

### GitHub Actions

- Run tests on push and pull requests
- Lint shell scripts with ShellCheck
- Build and test on multiple platforms
- Example workflow:
  ```yaml
  name: CI
  on: [push, pull_request]
  jobs:
    test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - name: Run tests
          run: make test
        - name: Lint shell scripts
          run: shellcheck -x scripts/*
  ```

### Release Process

1. Update version in `plugin.toml`
2. Update `CHANGELOG.md`
3. Create git tag
4. Push tag to trigger release
5. GitHub Actions will publish the release

## Common Patterns

### Service Management

```bash
# Start service
dokku postgres:start my-db

# Stop service
dokku postgres:stop my-db

# View logs
dokku postgres:logs my-db
```

### Data Management

```bash
# Create backup
dokku postgres:backup my-db

# Restore from backup
dokku postgres:restore my-db < backup.dump

# Export data
dokku postgres:export my-db > data.sql
```

### Linking Services

```bash
# Link service to app
dokku postgres:link my-db my-app

# Unlink service
dokku postgres:unlink my-db my-app
```

## Best Practices

### Core Principles
1. **Idempotency**: All commands should be idempotent (running them multiple times has the same effect as running them once)
2. **Error Handling**: 
   - Provide clear, actionable error messages
   - Include error codes for programmatic handling
   - Clean up resources on failure
3. **Documentation**: 
   - Document all commands with examples
   - Keep README and help text up-to-date
   - Include troubleshooting guides

### Code Quality
4. **Testing**: 
   - Maintain high test coverage (aim for 80%+)
   - Test edge cases and error conditions
   - Include both unit and integration tests
5. **Security**: 
   - Never log sensitive data
   - Validate all inputs
   - Follow principle of least privilege
6. **Performance**: 
   - Optimize for speed and resource usage
   - Minimize external command calls
   - Cache expensive operations when possible

### Plugin Architecture
7. **Compatibility**: 
   - Maintain backward compatibility within major versions
   - Use feature detection for optional functionality
   - Document version requirements
8. **Logging**: 
   - Use appropriate log levels (DEBUG, INFO, WARN, ERROR)
   - Include timestamps and context in logs
   - Support structured logging for machine processing
9. **Resource Management**: 
   - Clean up temporary files and resources
   - Handle signals and shutdown gracefully
   - Implement timeouts for long-running operations

### Plugin-Specific Guidelines
10. **Service Plugins**: 
    - Implement full lifecycle management
    - Support backup/restore operations
    - Handle data persistence and migrations
11. **Utility Plugins**: 
    - Focus on single responsibility
    - Support dry-run mode
    - Include validation for all inputs
12. **Core Plugins**: 
    - Follow established patterns from official plugins
    - Document all configuration options
    - Include upgrade paths for existing users

### Development Workflow
13. **Version Control**:
    - Use semantic versioning
    - Create meaningful commit messages
    - Use feature branches and pull requests
14. **CI/CD**:
    - Automate testing and releases
    - Run linters and static analysis
    - Generate changelogs automatically
15. **Community**:
    - Document contribution guidelines
    - Include a code of conduct
    - Be responsive to issues and PRs

## Example Plugins

### Service Plugin: dokku-postgres
- **Repository**: [dokku/dokku-postgres](https://github.com/dokku/dokku-postgres)
- **Key Features**:
  - Full database lifecycle management
  - Backup/restore functionality
  - User and permission management
  - SSL configuration
- **Notable Patterns**:
  - Well-structured subcommands
  - Comprehensive test suite
  - Detailed documentation

### Utility Plugin: dokku-letsencrypt
- **Repository**: [dokku/dokku-letsencrypt](https://github.com/dokku/dokku-letsencrypt)
- **Key Features**:
  - Automatic SSL certificate management
  - Certificate renewal
  - Nginx configuration
- **Notable Patterns**:
  - Cron-based scheduling
  - Template-based configuration
  - Clean error handling

### Core Plugin: dokku-redis
- **Repository**: [dokku/dokku-redis](https://github.com/dokku/dokku-redis)
- **Key Features**:
  - Redis instance management
  - Data persistence
  - Service linking
- **Notable Patterns**:
  - Consistent command structure
  - Integration with Dokku networking
  - Clear user feedback

## Plugin Development Checklist

When developing a new Dokku plugin, ensure you've covered these aspects:

### Core Functionality
- [ ] Implement all required lifecycle hooks
- [ ] Support all standard commands (create, destroy, info, etc.)
- [ ] Handle errors gracefully
- [ ] Validate all inputs

### User Experience
- [ ] Provide clear help text for all commands
- [ ] Include usage examples
- [ ] Document configuration options
- [ ] Support common environment variables

### Testing
- [ ] Write unit tests for core functions
- [ ] Include integration tests
- [ ] Test error conditions
- [ ] Verify plugin uninstallation

### Documentation
- [ ] Complete README
- [ ] Command reference
- [ ] Installation instructions
- [ ] Upgrade guides

### Deployment
- [ ] CI/CD pipeline
- [ ] Version management
- [ ] Release process
- [ ] Changelog generation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
