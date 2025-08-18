FROM alpine:latest

# Install required tools for all services
RUN apk add --no-cache \
    bash \
    curl \
    postgresql-client \
    redis \
    rabbitmq-c

# Create directories for scripts and data
RUN mkdir -p /scripts /services /data

# Copy all setup scripts (only .sh files, preserving directory structure)
COPY scripts/ /tmp/scripts/
COPY services/ /tmp/services/

# Copy only .sh files to final destinations, preserving directory structure
RUN cd /tmp/scripts && find . -name "*.sh" | while read file; do \
        mkdir -p "/scripts/$(dirname "$file")" && \
        cp "$file" "/scripts/$file"; \
    done && \
    cd /tmp/services && find . -name "*.sh" | while read file; do \
        mkdir -p "/services/$(dirname "$file")" && \
        cp "$file" "/services/$file"; \
    done && \
    rm -rf /tmp/scripts /tmp/services

# Make all scripts executable
RUN find /scripts -name "*.sh" -exec chmod +x {} \; && \
    find /services -name "*.sh" -exec chmod +x {} \;

# Set working directory
WORKDIR /scripts

# Default command
CMD ["./setup-all-services.sh", "setup-all"]
