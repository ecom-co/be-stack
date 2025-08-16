# Connection URLs & Environment Variables

## 🔗 Database Connection URLs

### PostgreSQL

**Admin Connection (Full Access):**
```bash
# Connection URL
postgresql://ecom_admin:admin_secure_123@localhost:5443/ecommerce_db

# Environment Variables
POSTGRES_URL=postgresql://ecom_admin:admin_secure_123@localhost:5443/ecommerce_db
DATABASE_URL=postgresql://ecom_admin:admin_secure_123@localhost:5443/ecommerce_db
```

**Developer Connection (Limited Access):**
```bash
# Connection URL  
postgresql://ecom_dev:dev_secure_123@localhost:5443/ecommerce_db

# Environment Variables
POSTGRES_URL=postgresql://ecom_dev:dev_secure_123@localhost:5443/ecommerce_db
DATABASE_URL=postgresql://ecom_dev:dev_secure_123@localhost:5443/ecommerce_db
```

### Redis

**Admin Connection:**
```bash
# Connection URL
redis://:redis_admin_123@localhost:6390

# Environment Variables
REDIS_URL=redis://:redis_admin_123@localhost:6390
REDIS_CONNECTION_STRING=redis://:redis_admin_123@localhost:6390
```

**Developer Connection:**
```bash
# Connection URL
redis://ecom_dev:redis_dev_123@localhost:6390

# Environment Variables  
REDIS_URL=redis://ecom_dev:redis_dev_123@localhost:6390
REDIS_CONNECTION_STRING=redis://ecom_dev:redis_dev_123@localhost:6390
```

### RabbitMQ

**Admin Connection:**
```bash
# Connection URL
amqp://ecom_admin:rabbit_admin_123@localhost:5683/

# Environment Variables
RABBITMQ_URL=amqp://ecom_admin:rabbit_admin_123@localhost:5683/
AMQP_URL=amqp://ecom_admin:rabbit_admin_123@localhost:5683/
```

**Developer Connection:**
```bash
# Connection URL
amqp://ecom_dev:rabbit_dev_123@localhost:5683/

# Environment Variables
RABBITMQ_URL=amqp://ecom_dev:rabbit_dev_123@localhost:5683/
AMQP_URL=amqp://ecom_dev:rabbit_dev_123@localhost:5683/
```

### Elasticsearch

**Admin Connection:**
```bash
# Connection URL (No Auth - Development)
http://localhost:9201

# Environment Variables
ELASTICSEARCH_URL=http://localhost:9201
ELASTIC_URL=http://localhost:9201
```

**Developer Connection:**
```bash
# Connection URL (No Auth - Development)
http://localhost:9201

# Environment Variables
ELASTICSEARCH_URL=http://localhost:9201
ELASTIC_URL=http://localhost:9201
```

## 🌐 Web Interface URLs

### Management Interfaces
```bash
# RabbitMQ Management (Admin: ecom_admin/rabbit_admin_123)
http://localhost:15683

# Kibana Dashboard
http://localhost:5602

# PgAdmin (admin@example.com/pgadmin_secure_123)
http://localhost:8081

# Elasticsearch API
http://localhost:9201
```

## 📝 Complete Environment Variables

### For API Development (Recommended - Developer Credentials)
```env
# Database
DATABASE_URL=postgresql://ecom_dev:dev_secure_123@localhost:5443/ecommerce_db
DB_HOST=localhost
DB_PORT=5443
DB_NAME=ecommerce_db
DB_USER=ecom_dev
DB_PASSWORD=dev_secure_123

# Redis
REDIS_URL=redis://ecom_dev:redis_dev_123@localhost:6390
REDIS_HOST=localhost
REDIS_PORT=6390
REDIS_USERNAME=ecom_dev
REDIS_PASSWORD=redis_dev_123

# RabbitMQ
RABBITMQ_URL=amqp://ecom_dev:rabbit_dev_123@localhost:5683/
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5683
RABBITMQ_USER=ecom_dev
RABBITMQ_PASSWORD=rabbit_dev_123
RABBITMQ_VHOST=/

# Elasticsearch
ELASTICSEARCH_URL=http://localhost:9201
ELASTICSEARCH_HOST=localhost
ELASTICSEARCH_PORT=9201
```

### For Admin Operations (Migrations, Maintenance)
```env
# Database Admin
DATABASE_URL=postgresql://ecom_admin:admin_secure_123@localhost:5443/ecommerce_db
DB_ADMIN_USER=ecom_admin
DB_ADMIN_PASSWORD=admin_secure_123

# Redis Admin
REDIS_URL=redis://:redis_admin_123@localhost:6390
REDIS_ADMIN_PASSWORD=redis_admin_123

# RabbitMQ Admin
RABBITMQ_URL=amqp://ecom_admin:rabbit_admin_123@localhost:5683/
RABBITMQ_ADMIN_USER=ecom_admin
RABBITMQ_ADMIN_PASSWORD=rabbit_admin_123
```

## 🔧 CLI Connection Examples

### PostgreSQL
```bash
# Admin connection
psql postgresql://ecom_admin:admin_secure_123@localhost:5443/ecommerce_db

# Developer connection
psql postgresql://ecom_dev:dev_secure_123@localhost:5443/ecommerce_db
```

### Redis
```bash
# Admin connection
redis-cli -h localhost -p 6390 -a redis_admin_123

# Developer connection
redis-cli -h localhost -p 6390 --user ecom_dev --pass redis_dev_123
```

### RabbitMQ
```bash
# Check queues (admin)
rabbitmqctl -p / list_queues

# Management API (admin)
curl -u ecom_admin:rabbit_admin_123 http://localhost:15683/api/overview
```

## 🐳 Docker Internal URLs (Container to Container)

### For Applications Running Inside Docker Network
```env
# Database
DATABASE_URL=postgresql://ecom_dev:dev_secure_123@postgres:5432/ecommerce_db

# Redis  
REDIS_URL=redis://ecom_dev:redis_dev_123@redis:6379

# RabbitMQ
RABBITMQ_URL=amqp://ecom_dev:rabbit_dev_123@rabbitmq:5672/

# Elasticsearch
ELASTICSEARCH_URL=http://elasticsearch:9200
```