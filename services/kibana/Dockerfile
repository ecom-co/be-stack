FROM docker.elastic.co/kibana/kibana:8.13.4

# Switch to root to install dependencies and setup scripts
USER root

# Install curl and jq for health checks and JSON parsing
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create init directory for setup scripts
RUN mkdir -p /usr/share/kibana/init

# Copy initialization scripts
COPY init/ /usr/share/kibana/init/

# Make scripts executable
RUN chmod +x /usr/share/kibana/init/*.sh

# Copy custom entrypoint
COPY init/entrypoint.sh /usr/local/bin/kibana-entrypoint.sh
RUN chmod +x /usr/local/bin/kibana-entrypoint.sh

# Switch back to kibana user
USER kibana

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/kibana-entrypoint.sh"]
