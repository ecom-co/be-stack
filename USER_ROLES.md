# User Roles & Permissions

## Overview
The development environment uses role-based access control with two main user types:

## 🔴 Admin Users
**Full administrative access to all services**

### PostgreSQL Admin (`ecom_admin`)
- **Permissions:** Full database access, create/drop databases, manage users
- **Use case:** Database migrations, schema changes, user management
- **Connection:** Use admin credentials for critical operations

### Redis Admin (`default` user)
- **Permissions:** All Redis commands including dangerous ones
- **Use case:** Cache management, configuration changes, monitoring
- **Commands:** All commands including FLUSHDB, FLUSHALL, CONFIG

### RabbitMQ Admin (`ecom_admin`)
- **Permissions:** Full management access, user management, monitoring
- **Use case:** Queue management, user creation, system monitoring
- **Management UI:** Full access to RabbitMQ Management interface

### Elasticsearch Admin (`elastic_admin`)
- **Permissions:** Cluster management, index operations, security settings
- **Use case:** Index management, cluster configuration, monitoring

## 🟢 Developer Users
**Limited access for daily development work**

### PostgreSQL Developer (`ecom_dev`)
- **Permissions:** CRUD operations on application tables, no user management
- **Use case:** Application development, testing, data manipulation
- **Restrictions:** Cannot create users, modify system tables

### Redis Developer (`ecom_dev`)
- **Permissions:** Most Redis commands except dangerous operations
- **Use case:** Application caching, session management
- **Restrictions:** Cannot use FLUSHDB, FLUSHALL, SHUTDOWN, CONFIG commands

### RabbitMQ Developer (`ecom_dev`)
- **Permissions:** Publish/consume messages, basic monitoring
- **Use case:** Message queue operations for application
- **Restrictions:** Cannot manage users or system configuration

### Elasticsearch Developer (`elastic_dev`)
- **Permissions:** Search, index documents, basic operations
- **Use case:** Application search functionality, data indexing
- **Restrictions:** Cannot modify cluster settings or security

## 🔧 Usage Guidelines

### For API Development
Use developer credentials in your application:
```env
DB_USER=${DEFAULT_DB_USER}
DB_PASSWORD=${DEFAULT_DB_PASSWORD}
REDIS_PASSWORD=${DEFAULT_REDIS_PASSWORD}
RABBITMQ_USER=${DEFAULT_RABBITMQ_USER}
RABBITMQ_PASS=${DEFAULT_RABBITMQ_PASS}
```

### For Database Migrations
Use admin credentials for schema changes:
```env
DB_USER=${POSTGRES_ADMIN_USER}
DB_PASSWORD=${POSTGRES_ADMIN_PASSWORD}
```

### For System Maintenance
Use admin credentials for:
- Database backups/restores
- Cache clearing
- Queue management
- Index management

## 🛡️ Security Benefits

1. **Principle of Least Privilege:** Applications run with minimal required permissions
2. **Separation of Concerns:** Development vs administrative operations
3. **Audit Trail:** Different users for different operations
4. **Risk Mitigation:** Limited blast radius if credentials are compromised
5. **Environment Consistency:** Same role structure across dev/staging/prod