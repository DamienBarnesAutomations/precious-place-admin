--- Run as postgres superuser
CREATE DATABASE custom_orders OWNER custom_orders_user;

-- Switch context to the new database
\c custom_orders

-- Standardize the public schema for the new owner
ALTER SCHEMA public OWNER TO custom_orders_user;

-- Grant explicit rights
GRANT ALL ON SCHEMA public TO custom_orders_user;

-- Ensure future tables created by any user are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO custom_orders_user;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO custom_orders_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO custom_orders_user;

CREATE TYPE order_status AS ENUM (
  'Pending',
  'Confirmed',
  'In Progress',
  'Ready',
  'Delivered'
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL,
    client_name TEXT NOT NULL,
    client_phone TEXT,
    notes TEXT,
    attachment_url TEXT,
    raw_message TEXT,
    status order_status DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Trigger to automatically update updated_at on row change
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
