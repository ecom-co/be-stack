FROM postgres:16-alpine

# Copy initialization scripts
COPY init/ /docker-entrypoint-initdb.d/

# Set executable permissions on shell scripts
RUN chmod +x /docker-entrypoint-initdb.d/*.sh

# Use the default postgres entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
