#!/bin/bash

# Wait for RabbitMQ to start
sleep 10

# Create developer user with limited permissions
rabbitmqctl add_user ${RABBITMQ_DEV_USER} ${RABBITMQ_DEV_PASS}

# Set permissions for developer user
# - configure: can declare exchanges, queues, bindings
# - write: can publish messages
# - read: can consume messages
rabbitmqctl set_permissions -p ${RABBITMQ_DEFAULT_VHOST} ${RABBITMQ_DEV_USER} ".*" ".*" ".*"

# Set user tags (developer gets monitoring tag for basic monitoring)
rabbitmqctl set_user_tags ${RABBITMQ_DEV_USER} monitoring
rabbitmqctl set_user_tags ${RABBITMQ_ADMIN_USER} administrator

echo "RabbitMQ users configured successfully"