# Dokku Docker Compose Plugin Requirements

## Overview
This document defines the requirements for a Dokku plugin that imports `docker-compose.yml` files and creates corresponding Dokku applications for each service. The plugin will support both simple deployments and complex multi-service applications with dependencies.

### Definitions
- **Compose File**: A YAML file (typically `docker-compose.yml`) defining services, networks, and volumes
- **Service**: A single container definition within the compose file
- **Dokku App**: A deployed application instance in Dokku
- **Plugin**: The `dokku-docker-compose` plugin being specified
- **Resource Limits**: CPU, memory, and other constraints applied to containers

## Core Functionality

### 1. Plugin Initialization
- [ ] Create a new Dokku plugin named `docker-compose`
- [ ] Register plugin commands under `dokku docker-compose:*`
- [ ] Implement basic help and version information

### 2. Docker Compose File Parsing
- [ ] Support reading and parsing `docker-compose.yml` (and `docker-compose.yaml`)
- [ ] Support both Compose v2 and v3 file formats
- [ ] Validate required fields in the compose file
- [ ] Handle YAML anchors and references

### 3. Service to Dokku App Mapping
- [ ] For each service in the compose file, create a corresponding Dokku app with these transformations:
  - Convert service names to lowercase
  - Replace underscores (`_`) with hyphens (`-`)
  - Remove any other invalid characters (anything not matching `[a-z0-9-]`)
  - Truncate to 30 characters while preserving uniqueness
- [ ] Support custom app name prefixes/suffixes via command-line flags:
  - `--prefix <string>`: Add prefix to all generated app names
  - `--suffix <string>`: Add suffix to all generated app names
  - `--separator <char>`: Character to separate prefix/suffix from name (default: `-`)
- [ ] Ensure generated app names are unique within the Dokku instance

### 4. Resource Configuration
- [ ] Map Docker Compose resources to Dokku equivalents with the following specifications:
  - **CPU/Memory Limits**:
    - Convert `deploy.resources.limits.cpus` to Dokku CPU shares
    - Convert `deploy.resources.limits.memory` to Dokku memory limits
    - Support both v2 (`mem_limit`) and v3 (`deploy.resources`) syntax
  - **Environment Variables**:
    - Transfer all `environment` and `env_file` entries to Dokku config
    - Support variable substitution in environment values
    - Preserve the order of variable definitions
  - **Volumes**:
    - Map `volumes` to Dokku persistent storage
    - Support both named volumes and host paths
    - Convert volume permissions (e.g., `:ro`, `:rw`)
  - **Networks**:
    - Create Dokku networks matching compose networks
    - Handle `aliases` and `ipv4_address`/`ipv6_address`
    - Support custom network drivers and options
  - **Ports**:
    - Map `ports` to Dokku proxy configuration
    - Support both short (`"8080:80"`) and long syntax
    - Handle protocol specification (tcp/udp)
  - **Health Checks**:
    - Convert `healthcheck` to Dokku CHECKS
    - Support all healthcheck parameters (test, interval, timeout, retries)
  - **Restart Policies**:
    - Map `restart` to Dokku process management
    - Support all restart policies (no, always, on-failure, unless-stopped)

### 5. Build and Deployment
- [ ] Support building from Dockerfile if specified
- [ ] Support building from image if specified
- [ ] Handle build arguments and context paths
- [ ] Support multi-stage builds

### 6. Service Dependencies
- [ ] Detect and handle service dependencies (depends_on) with the following behaviors:

#### Create Operation
- [ ] **Dependency Resolution**:
  - Build a dependency graph from `depends_on` and service links
  - Detect and report circular dependencies
  - Support all `depends_on` conditions: `service_started`, `service_healthy`, `service_completed_successfully`

- [ ] **Execution Order**:
  - Process services in dependency order (dependencies first)
  - Parallelize independent services when possible
  - Respect `depends_on` conditions before starting dependent services

- [ ] **Error Handling**:
  - If a dependency fails to start, stop and clean up dependent services
  - Provide clear error messages about dependency failures
  - Support `--ignore-dependency-errors` flag to continue on dependency failures

#### Update Operation
- [ ] **Dependency Analysis**:
  - Compare current and desired states
  - Identify services that need updating based on configuration changes
  - Determine if dependency changes require recreation of dependent services

- [ ] **Update Strategy**:
  - Default to rolling updates (one service at a time)
  - Support `--parallel` flag for concurrent updates of independent services
  - Preserve data volumes unless explicitly configured otherwise

- [ ] **Rollback**:
  - Maintain previous service versions for rollback
  - Support `--rollback` flag to revert to previous state
  - Automatically roll back if health checks fail after update

#### Destroy Operation
- [ ] **Dependency Handling**:
  - Process services in reverse dependency order (dependents first)
  - Prevent destruction of services that are dependencies of other services unless `--force` is specified
  - Support `--cascade` flag to automatically destroy all dependents

- [ ] **Data Management**:
  - By default, preserve volumes to prevent data loss
  - Support `--volumes` flag to remove associated volumes
  - Prompt for confirmation before destroying services with persistent data

- [ ] **Cleanup**:
  - Remove all service links and dependencies
  - Clean up any temporary resources
  - Remove network configurations if no longer referenced

### 7. Network Configuration
- [ ] Create necessary Dokku networks
- [ ] Map Docker Compose networks to Dokku networks
- [ ] Handle custom network configurations

### 8. Volume Management
- [ ] Map Docker Compose volumes to Dokku volumes
- [ ] Support named volumes and bind mounts
- [ ] Handle volume permissions

### 9. Environment Variables
- [ ] Transfer environment variables from compose file to Dokku config
- [ ] Handle environment file includes
- [ ] Support variable substitution

### 10. Health Checks
- [ ] Convert Docker Compose healthcheck to Dokku checks
- [ ] Support custom health check configurations

### 11. Dokku Plugin Integration
- [ ] Detect and utilize existing Dokku plugins for common services with the following behavior:
  - **Plugin Detection**:
    - Match service image names against known plugin patterns (e.g., `postgres:*` → `dokku-postgres`)
    - Support custom plugin mappings via configuration
  - **Installation Handling**:
    - Check for required plugins using `dokku plugin:installed`
    - If missing, provide exact installation command:
      ```
      dokku plugin:install https://github.com/dokku/dokku-<service>.git <service>
      ```
    - Support `--skip-plugin=<service>` to bypass installation
  - **Service Configuration**:
    - Map environment variables to plugin-specific configuration
    - Handle version specifications from image tags
    - Support plugin-specific parameters via labels or environment variables
  - **Service Linking**:
    - Automatically link services using `dokku <plugin>:link`
    - Set appropriate environment variables in the target app
  - **Supported Plugins**:
    - **Databases**:
      - [ ] postgres (`postgres:*`)
      - [ ] mysql (`mysql:*`)
      - [ ] mariadb (`mariadb:*`)
      - [ ] mongo (`mongo:*`)
      - [ ] redis (`redis:*`)
    - **Caches**:
      - [ ] redis (`redis:*`)
      - [ ] memcached (`memcached:*`)
    - **Search**:
      - [ ] elasticsearch (`elasticsearch:*`)
    - **Message Brokers**:
      - [ ] rabbitmq (`rabbitmq:*`)
    - **Object Storage**:
      - [ ] minio (`minio/minio:*`)
    - **Key-Value Stores**:
      - [ ] etcd (`etcd:*`)

### 12. Logging and Monitoring
- [ ] Provide detailed logging of the import process
- [ ] Support dry-run mode
- [ ] Generate a summary report after import

## Non-Functional Requirements

### 1. Performance
- [ ] Handle compose files with up to 50 services
- [ ] Process each service in parallel where possible
- [ ] Provide real-time progress feedback including:
  - Current operation
  - Progress percentage
  - Estimated time remaining
  - Resource usage
- [ ] Complete processing of a 10-service compose file in under 2 minutes on average hardware

### 2. Error Handling
- [ ] Comprehensive error messages
- [ ] Graceful rollback on failure
- [ ] Input validation

### 3. Security
- [ ] Handle sensitive information appropriately
- [ ] Validate input to prevent injection attacks
- [ ] Follow Dokku's security best practices

### 4. Documentation
- [ ] Comprehensive CLI documentation covering:
  - All commands and options
  - Environment variables
  - Configuration files
  - Exit codes and their meanings
- [ ] Examples for:
  - Basic single-service deployment
  - Multi-service application with dependencies
  - Custom resource allocation
  - Plugin integration examples
- [ ] Troubleshooting guide covering:
  - Common error messages and resolutions
  - Debugging techniques
  - Log file locations
  - Recovery procedures

## Update Process

### 1. Change Detection
- [ ] **Configuration Comparison**:
  - Compare current and desired states for each service
  - Track changes in:
    - Image versions
    - Environment variables
    - Resource limits
    - Volume mounts
    - Network configurations
    - Health checks
    - Dependencies
- [ ] **Change Classification**:
  - **No Change**: No action needed
  - **Configuration Change**: Update service configuration
  - **Image Change**: Rebuild/redeploy service
  - **Dependency Change**: May require recreation of dependent services
  - **Breaking Change**: Requires explicit confirmation or flag

### 2. Update Strategies
- [ ] **Default Strategy (Rolling Update)**:
  - Update one service at a time
  - Wait for health checks to pass before proceeding
  - Automatic rollback on failure
  - Minimal downtime

- [ ] **Parallel Update**:
  - Update multiple independent services concurrently
  - Controlled by `--parallel` flag with optional concurrency limit
  - Example: `--parallel=3` for up to 3 concurrent updates

- [ ] **Recreate Strategy**:
  - Stop old containers before starting new ones
  - Triggered by `--recreate` flag
  - Useful for changes requiring complete service restart

### 3. State Management
- [ ] **State Storage**:
  - Store original docker-compose.yml in Dokku app config
  - Track checksums of configuration files
  - Maintain version history of applied configurations

- [ ] **Dry Run**:
  - Support `--dry-run` flag to preview changes
  - Show what would be updated without making changes
  - Include change summary and impact analysis

### 4. Handling Specific Changes
- [ ] **Image Updates**:
  - Pull new images
  - Recreate containers with new images
  - Support `--pull` flag to force image refresh

- [ ] **Configuration Changes**:
  - Update environment variables
  - Adjust resource limits
  - Apply new health check configurations
  - Restart services if needed

- [ ] **Volume Changes**:
  - Preserve existing volumes by default
  - Support `--recreate-volumes` for volume recreation
  - Handle volume permission changes

- [ ] **Network Changes**:
  - Update network configurations
  - Handle IP address changes
  - Manage network aliases

### 5. Rollback Mechanism
- [ ] **Automatic Rollback**:
  - Trigger on health check failures
  - Configurable timeout for health checks
  - Limit number of rollback attempts

- [ ] **Manual Rollback**:
  - Support `--rollback` flag to revert to previous version
  - Show rollback preview before executing
  - Support rollback to specific version

### 6. Dependency Handling
- [ ] **Dependency Analysis**:
  - Rebuild dependency graph
  - Identify services affected by changes
  - Determine update order based on dependencies

- [ ] **Dependent Updates**:
  - Update dependent services when needed
  - Support `--no-dependents` to skip dependent updates
  - Show impact analysis before proceeding

## Future Enhancements

### 1. Export Functionality
- [ ] Export existing Dokku apps to docker-compose format

### 2. Update Support
- [ ] Update existing Dokku apps from modified compose files

### 3. Plugin System
- [ ] Allow extensions for custom service types
- [ ] Support for Docker Compose extensions

### 4. Integration Tests
- [ ] Test suite with various docker-compose configurations
- [ ] CI/CD pipeline

## Dependencies

### Required
- Docker
- Docker Compose
- Dokku
- Bash (for the plugin)
- yq (for YAML parsing in bash)

### Optional
- jq (for advanced JSON processing)
- parallel (for faster processing)

## Implementation Notes
- The plugin should be written in Bash to match Dokku's existing plugin system
- Use temporary directories for build contexts
- Implement proper cleanup of temporary resources
- Follow Dokku's plugin development guidelines
- Include comprehensive logging for debugging

## Usage Examples

### Basic Import
```bash
dokku docker-compose:import /path/to/docker-compose.yml
```

### Import with Custom Prefix
```bash
dokku docker-compose:import --prefix myapp- /path/to/docker-compose.yml
```

### Dry Run
```bash
dokku docker-compose:import --dry-run /path/to/docker-compose.yml
```
