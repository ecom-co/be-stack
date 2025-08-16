FROM docker.elastic.co/elasticsearch/elasticsearch:8.13.4

# Copy all necessary files from init folder
COPY init/setup-users.sh /usr/share/elasticsearch/setup-users.sh
COPY init/entrypoint.sh /usr/share/elasticsearch/entrypoint.sh
COPY elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml

# Set executable permissions
USER root
RUN chmod +x /usr/share/elasticsearch/setup-users.sh
RUN chmod +x /usr/share/elasticsearch/entrypoint.sh
USER elasticsearch

# Use custom entrypoint that auto-creates users
ENTRYPOINT ["/usr/share/elasticsearch/entrypoint.sh"]
