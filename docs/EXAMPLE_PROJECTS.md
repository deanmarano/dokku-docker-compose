# Example Projects for Testing

This document lists various projects with Docker Compose files of increasing complexity, which will be used to test the Dokku Docker Compose plugin.

## Difficulty: Beginner (Single Service)

### 1. Nginx Web Server
**Description**: Basic Nginx web server with a custom HTML page
**Key Features**:
- Single service
- Volume mount for static content
- Port mapping

```yaml
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

### 2. Redis Cache
**Description**: Simple Redis instance
**Key Features**:
- Single service
- Volume for data persistence
- Custom configuration

```yaml
version: '3.8'
services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --requirepass yourpassword

volumes:
  redis_data:
```

## Difficulty: Intermediate (Multiple Services)

### 3. WordPress with MySQL
**Description**: WordPress with a separate MySQL database
**Key Features**:
- Multi-service
- Environment variables
- Volume mounts
- Service dependencies

```yaml
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8000:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    depends_on:
      - db
    volumes:
      - wordpress_data:/var/www/html

  db:
    image: mysql:5.7
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db_data:/var/lib/mysql

volumes:
  wordpress_data:
  db_data:
```

### 4. Node.js App with MongoDB
**Description**: Simple Node.js application with MongoDB
**Key Features**:
- Multi-service
- Build context
- Environment variables
- Network configuration

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - MONGODB_URI=mongodb://mongo:27017/mydb
    depends_on:
      - mongo
    networks:
      - app-network

  mongo:
    image: mongo:latest
    volumes:
      - mongo_data:/data/db
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  mongo_data:
```

## Difficulty: Advanced (Complex Applications)

### 5. Nextcloud
**Description**: Self-hosted productivity platform
**Key Features**:
- Multiple interconnected services
- Database and caching
- Volume mounts for persistence
- Environment configuration
- Health checks
- Complex networking

```yaml
version: '3.8'
services:
  db:
    image: mariadb:10.6
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=db_root_password
      - MYSQL_PASSWORD=db_password
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
    volumes:
      - db:/var/lib/mysql

  redis:
    image: redis:alpine
    restart: always

  app:
    image: nextcloud:apache
    restart: always
    ports:
      - 8080:80
    links:
      - db
      - redis
    environment:
      - MYSQL_PASSWORD=db_password
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db
      - REDIS_HOST=redis
      - OVERWRITEPROTOCOL=https
    volumes:
      - nextcloud:/var/www/html
    depends_on:
      - db
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/status.php"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  db:
  nextcloud:
```

### 6. Plane (Project Management)
**Description**: Open-source project management tool
**Key Features**:
- Multiple microservices
- Database and cache
- File storage
- Background workers
- Environment variables
- Health checks

```yaml
version: '3.8'
services:
  web:
    image: planepowers/plane-web:latest
    environment:
      - NEXT_PUBLIC_API_BASE_URL=${API_BASE_URL}
      - NEXT_PUBLIC_WS_BASE_URL=${WS_BASE_URL}
    ports:
      - "3000:3000"
    depends_on:
      - api
    restart: unless-stopped

  api:
    image: planepowers/plane-api:latest
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
      - CORS_ORIGINS=${CORS_ORIGINS}
    depends_on:
      - db
      - redis
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health/"]
      interval: 30s
      timeout: 10s
      retries: 3

  worker:
    image: planepowers/plane-worker:latest
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:13-alpine
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    restart: unless-stopped

  minio:
    image: minio/minio:latest
    volumes:
      - minio_data:/data
    environment:
      - MINIO_ROOT_USER=${MINIO_ACCESS_KEY}
      - MINIO_ROOT_PASSWORD=${MINIO_SECRET_KEY}
    command: server /data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  minio_data:
```

## Difficulty: Expert (Enterprise-Grade)

### 7. GitLab CE
**Description**: Complete DevOps platform
**Key Features**:
- Multiple interconnected services
- Database, cache, and search
- File storage
- Background processing
- Complex networking
- Resource limits
- Health checks

```yaml
version: '3.8'
services:
  gitlab:
    image: 'gitlab/gitlab-ce:latest'
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.example.com'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    shm_size: '256m'
    healthcheck:
      test: ['CMD', '/opt/gitlab/bin/gitlab-healthcheck', '--fail']
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5m
```

### 8. Jitsi Meet
**Description**: Secure, Simple and Scalable Video Conferences
**Key Features**:
- Multiple real-time services
- WebRTC configuration
- TURN/STUN servers
- Authentication
- Custom networking
- Environment configuration

```yaml
version: '3.8'
services:
  # Frontend
  web:
    image: jitsi/web:latest
    ports:
      - '${HTTP_PORT}:80'
      - '${HTTPS_PORT}:443'
    volumes:
      - '${CONFIG}/web:/config'
      - '${CONFIG}/web/letsencrypt:/etc/letsencrypt'
      - '${CONFIG}/transcripts:/usr/share/jitsi-meet/transcripts'
    environment:
      - ENABLE_AUTH
      - ENABLE_RECORDING
      - ENABLE_LETSCENCRYPT
      - LETSENCRYPT_DOMAIN
      - LETSENCRYPT_EMAIL
      - PUBLIC_URL
      - XMPP_DOMAIN
      - XMPP_AUTH_DOMAIN
      - XMPP_GUEST_DOMAIN
      - XMPP_MUC_DOMAIN
      - XMPP_INTERNAL_MUC_DOMAIN
      - XMPP_MODULES
      - XMPP_MUC_MODULES
      - XMPP_INTERNAL_MUC_MODULES
      - JVB_ADDRESS
      - ENABLE_COLIBRI_WEBSOCKET
      - ENABLE_XMPP_WEBSOCKET
      - COLIBRI_REST_ENDPOINT
      - ENABLE_LOBBY
      - ENABLE_IPV6
    networks:
      meet.jitsi:
      meet.jitsi.2:
        ipv4_address: 172.28.1.1
    restart: unless-stopped

  # XMPP server
  prosody:
    image: jitsi/prosody:latest
    volumes:
      - '${CONFIG}/prosody/config:/config'
      - '${CONFIG}/prosody/prosody-plugins-custom:/prosody-plugins-custom'
    environment:
      - AUTH_TYPE
      - ENABLE_AUTH
      - ENABLE_GUESTS
      - GLOBAL_MODULES
      - GLOBAL_CONFIG
      - LDAP_URL
      - LDAP_BASE
      - LDAP_BINDDN
      - LDAP_BINDPW
      - LDAP_FILTER
      - LDAP_AUTH_METHOD
      - LDAP_VERSION
      - LDAP_USE_TLS
      - LDAP_TLS_CIPHERS
      - LDAP_TLS_CHECK_PEER
      - LDAP_TLS_CACERT_FILE
      - LDAP_TLS_CACERT_DIR
      - LDAP_START_TLS
      - XMPP_DOMAIN
      - XMPP_AUTH_DOMAIN
      - XMPP_GUEST_DOMAIN
      - XMPP_MUC_DOMAIN
      - XMPP_INTERNAL_MUC_DOMAIN
      - XMPP_MODULES
      - XMPP_MUC_MODULES
      - XMPP_INTERNAL_MUC_MODULES
      - XMPP_RECORDER_DOMAIN
      - JICOFO_COMPONENT_SECRET
      - JICOFO_AUTH_USER
      - JVB_AUTH_USER
      - JIGASI_XMPP_USER
      - JIBRI_XMPP_USER
      - JIBRI_RECORDER_USER
      - JIBRI_RECORDING_DIR
      - JIBRI_FINALIZE_RECORDING_SCRIPT_PATH
      - JIBRI_XMPP_PASSWORD
      - JIBRI_RECORDER_PASSWORD
      - JWT_APP_ID
      - JWT_APP_SECRET
      - JWT_ACCEPTED_ISSUERS
      - JWT_ACCEPTED_AUDIENCES
      - JWT_ASAP_KEYSERVER
      - JWT_ALLOW_EMPTY
      - JWT_AUTH_TYPE
      - JWT_TOKEN_AUTH_MODULE
      - LOG_LEVEL
      - TZ
    networks:
      meet.jitsi:
      meet.jitsi.2:
        ipv4_address: 172.28.1.2
    restart: unless-stopped

  # Video bridge
  jvb:
    image: jitsi/jvb:latest
    ports:
      - '${JVB_PORT}:${JVB_PORT}/udp'
      - '${JVB_TCP_PORT}:${JVB_TCP_PORT}'
    volumes:
      - '${CONFIG}/jvb:/config'
    environment:
      - DOCKER_HOST_ADDRESS
      - XMPP_AUTH_DOMAIN
      - XMPP_INTERNAL_MUC_DOMAIN
      - XMPP_SERVER
      - JVB_AUTH_USER
      - JVB_AUTH_PASSWORD
      - JVB_BREWERY_MUC
      - JVB_PORT
      - JVB_TCP_PORT
      - JVB_TCP_ENABLED
      - JVB_TCP_PORT
      - JVB_STUN_SERVERS
      - JVB_ENABLE_APIS
      - JVB_WS_DOMAIN
      - JVB_WS_SERVER_ID
      - JVB_WS_REGION
      - PUBLIC_URL
      - TZ
    depends_on:
      - prosody
    networks:
      meet.jitsi:
      meet.jitsi.2:
        ipv4_address: 172.28.1.3
    restart: unless-stopped

  # Jicofo - the conference focus component
  jicofo:
    image: jitsi/jicofo:latest
    volumes:
      - '${CONFIG}/jicofo:/config'
    environment:
      - ENABLE_AUTH
      - XMPP_DOMAIN
      - XMPP_AUTH_DOMAIN
      - XMPP_INTERNAL_MUC_DOMAIN
      - XMPP_SERVER
      - JICOFO_COMPONENT_SECRET
      - JICOFO_AUTH_USER
      - JICOFO_AUTH_PASSWORD
      - JICOFO_RESERVATION_REST_BASE_URL
      - JVB_BREWERY_MUC
      - JIGASI_BREWERY_MUC
      - JIGASI_RECORDER_BREWERY_MUC
      - JIBRI_BREWERY_MUC
      - JIBRI_PENDING_TIMEOUT
      - TZ
    depends_on:
      - prosody
    networks:
      meet.jitsi:
      meet.jitsi.2:
        ipv4_address: 172.28.1.4
    restart: unless-stopped

networks:
  meet.jitsi:
  meet.jitsi.2:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: meet.jitsi.2
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
          gateway: 172.28.0.1
        - subnet: 2001:db8:4001:1::/64
          gateway: 2001:db8:4001::1
```

## Testing Strategy

1. **Start Simple**: Begin with the basic examples and ensure they work
2. **Progressive Complexity**: Move to more complex examples
3. **Edge Cases**: Test with different configurations and edge cases
4. **Real-world Scenarios**: Test with actual applications like Nextcloud and Plane
5. **Performance Testing**: Measure resource usage and optimize as needed

## Adding New Examples

When adding new examples, please:
1. Categorize by difficulty level
2. Include a brief description
3. List key features
4. Ensure the example is complete and runnable
5. Add any necessary environment variables or setup instructions

## Contributing

Contributions of additional examples are welcome! Please ensure that any contributed examples:
- Are well-documented
- Follow best practices
- Include all necessary configuration
- Are tested and working
