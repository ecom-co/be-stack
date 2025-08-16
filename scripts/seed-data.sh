#!/bin/bash

# Load environment variables
source .env

echo "🌱 Seeding E-commerce Development Data..."
echo "========================================"

# Create sample tables and data
PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h localhost -p 5443 -U $POSTGRES_ADMIN_USER -d $POSTGRES_DB << 'EOF'

-- Create sample e-commerce tables
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category_id INTEGER REFERENCES categories(id),
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Clothing', 'Fashion and apparel'),
('Books', 'Books and educational materials'),
('Home & Garden', 'Home improvement and gardening')
ON CONFLICT DO NOTHING;

INSERT INTO products (name, description, price, category_id, stock_quantity) VALUES
('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 1, 50),
('Wireless Headphones', 'Premium noise-canceling headphones', 299.99, 1, 100),
('Cotton T-Shirt', 'Comfortable cotton t-shirt', 29.99, 2, 200),
('Programming Book', 'Learn modern web development', 49.99, 3, 75),
('Garden Tools Set', 'Complete set of gardening tools', 89.99, 4, 30)
ON CONFLICT DO NOTHING;

INSERT INTO users (email, first_name, last_name) VALUES
('john.doe@example.com', 'John', 'Doe'),
('jane.smith@example.com', 'Jane', 'Smith'),
('developer@example.com', 'Dev', 'User')
ON CONFLICT DO NOTHING;

-- Grant permissions to developer user
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dev_ecom;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dev_ecom;

EOF

echo "✅ Database seeded with sample e-commerce data!"

# Seed Redis with sample cache data
echo "🔴 Seeding Redis cache..."
redis-cli -h localhost -p 6390 -a $REDIS_ADMIN_PASSWORD << 'EOF'
SET "product:1:views" 150
SET "product:2:views" 89
SET "user:session:12345" "john.doe@example.com"
HSET "cart:user:1" "product:1" 2 "product:3" 1
EXPIRE "user:session:12345" 3600
EOF

echo "✅ Redis seeded with sample cache data!"

# Create sample Elasticsearch index
echo "🔍 Creating Elasticsearch product index..."
curl -X PUT "localhost:9201/products" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "name": { "type": "text", "analyzer": "standard" },
      "description": { "type": "text" },
      "price": { "type": "float" },
      "category": { "type": "keyword" },
      "tags": { "type": "keyword" }
    }
  }
}'

# Index sample products
curl -X POST "localhost:9201/products/_doc/1" -H 'Content-Type: application/json' -d'
{
  "name": "Laptop Pro",
  "description": "High-performance laptop for professionals",
  "price": 1299.99,
  "category": "Electronics",
  "tags": ["laptop", "computer", "professional"]
}'

curl -X POST "localhost:9201/products/_doc/2" -H 'Content-Type: application/json' -d'
{
  "name": "Wireless Headphones",
  "description": "Premium noise-canceling headphones",
  "price": 299.99,
  "category": "Electronics",
  "tags": ["headphones", "audio", "wireless"]
}'

echo "✅ Elasticsearch seeded with product index!"

echo ""
echo "🎉 Sample data created successfully!"
echo "📊 You can now:"
echo "   - Query products: SELECT * FROM products;"
echo "   - Check Redis cache: redis-cli -h localhost -p 6390 -a $REDIS_DEV_PASSWORD"
echo "   - Search products: curl 'localhost:9201/products/_search?q=laptop'"