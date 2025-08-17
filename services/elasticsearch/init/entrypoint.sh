#!/bin/bash
set -e

echo "🚀 Starting Elasticsearch with custom user setup..."

# Function to log with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Start Elasticsearch in background
log "Starting Elasticsearch server..."

# Use the original Elasticsearch entrypoint in background
/usr/local/bin/docker-entrypoint.sh elasticsearch &
ES_PID=$!

# Wait for Elasticsearch to be ready
log "Waiting for Elasticsearch to be ready..."
timeout=180
counter=0

while [ $counter -lt $timeout ]; do
    # Check if Elasticsearch is responding
    if curl -s -f "http://localhost:9200" >/dev/null 2>&1; then
        log "✅ Elasticsearch is ready (no security)!"
        break
    elif curl -s -o /dev/null -w "%{http_code}" "http://localhost:9200" 2>/dev/null | grep -q "401"; then
        log "✅ Elasticsearch is ready (security enabled)!"
        break
    fi
    
    # Check if the process is still running
    if ! kill -0 $ES_PID 2>/dev/null; then
        log "❌ Elasticsearch process died"
        exit 1
    fi
    
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    log "❌ Timeout waiting for Elasticsearch to start"
    exit 1
fi

# Run user setup script
log "Running user setup script..."
if [ -f "/usr/share/elasticsearch/setup-users.sh" ]; then
    bash /usr/share/elasticsearch/setup-users.sh
    if [ $? -eq 0 ]; then
        log "✅ User setup completed successfully"
    else
        log "⚠️ User setup had issues, but continuing..."
    fi
else
    log "⚠️ Setup script not found, skipping user setup"
fi

log "🎉 Elasticsearch startup complete!"

# Keep the main process running
wait $ES_PID