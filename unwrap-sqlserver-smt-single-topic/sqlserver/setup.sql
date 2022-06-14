-- Create the database that we'll use to populate data
CREATE DATABASE inventory;
GO

-- Switch to this database
USE inventory;
GO

-- Create and populate our products using a single insert with many rows
CREATE TABLE products (
  id INTEGER NOT NULL IDENTITY(101, 1) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(512),
  weight FLOAT
);

INSERT INTO products
VALUES ('scooter','Small 2-wheel scooter',3.14),
       ('car battery','12V car battery',8.1),
       ('12-pack drill bits','12-pack of drill bits with sizes ranging from #40 to #3',0.8),
       ('hammer','12oz carpenter''s hammer',0.75),
       ('hammer','14oz carpenter''s hammer',0.875),
       ('hammer','16oz carpenter''s hammer',1.0),
       ('rocks','box of assorted rocks',5.3),
       ('jacket','water resistent black wind breaker',0.1),
       ('spare tire','24 inch spare tire',22.2);

-- Create and populate the products on hand using multiple inserts
CREATE TABLE products_on_hand (
  product_id INTEGER NOT NULL PRIMARY KEY,
  quantity INTEGER NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO products_on_hand VALUES (101,3);
INSERT INTO products_on_hand VALUES (102,8);
INSERT INTO products_on_hand VALUES (103,18);
INSERT INTO products_on_hand VALUES (104,4);
INSERT INTO products_on_hand VALUES (105,5);
INSERT INTO products_on_hand VALUES (106,0);
INSERT INTO products_on_hand VALUES (107,44);
INSERT INTO products_on_hand VALUES (108,2);
INSERT INTO products_on_hand VALUES (109,5);

-- Create some customers ...
CREATE TABLE customers (
  id INTEGER NOT NULL IDENTITY(1001, 1) PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE
);


INSERT INTO customers
VALUES ('Sally','Thomas','sally.thomas@acme.com'),
       ('George','Bailey','gbailey@foobar.com'),
       ('Edward','Walker','ed@walker.com'),
       ('Anne','Kretchmar','annek@noanswer.org');

-- Create some fake addresses
CREATE TABLE addresses (
  id INTEGER NOT NULL IDENTITY(10, 1) PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  street VARCHAR(255) NOT NULL,
  city VARCHAR(255) NOT NULL,
  state VARCHAR(255) NOT NULL,
  zip VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL CHECK (type IN('SHIPPING','BILLING','LIVING')),
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

INSERT INTO addresses
VALUES (1001,'3183 Moore Avenue','Euless','Texas','76036','SHIPPING'),
       (1001,'2389 Hidden Valley Road','Harrisburg','Pennsylvania','17116','BILLING'),
       (1002,'281 Riverside Drive','Augusta','Georgia','30901','BILLING'),
       (1003,'3787 Brownton Road','Columbus','Mississippi','39701','SHIPPING'),
       (1003,'2458 Lost Creek Road','Bethlehem','Pennsylvania','18018','SHIPPING'),
       (1003,'4800 Simpson Square','Hillsdale','Oklahoma','73743','BILLING'),
       (1004,'1289 University Hill Road','Canehill','Arkansas','72717','LIVING');

-- Create some very simple orders
CREATE TABLE orders (
  order_number INTEGER NOT NULL IDENTITY(10001, 1) PRIMARY KEY,
  order_date DATE NOT NULL,
  purchaser INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  FOREIGN KEY (purchaser) REFERENCES customers(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO orders
VALUES ('2016-01-16', 1001, 1, 102),
       ('2016-01-17', 1002, 2, 105),
       ('2016-02-19', 1002, 2, 106),
       ('2016-02-21', 1003, 1, 107);

-- Create table with Spatial/Geometry type
CREATE TABLE geom (
	id INTEGER NOT NULL IDENTITY PRIMARY KEY,
	g GEOMETRY NOT NULL,
	h GEOMETRY);

INSERT INTO geom
VALUES(geometry::STGeomFromText('POINT(1 1)', 0), NULL),
      (geometry::STGeomFromText('LINESTRING(2 1, 6 6)', 0), NULL),
      (geometry::STGeomFromText('POLYGON((0 5, 2 5, 2 7, 0 7, 0 5))', 0), NULL);

GO

-- Enable CDC on the database
EXEC sys.sp_cdc_enable_db;
GO

-- Enable CDC on the tables
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'products', @role_name = NULL, @supports_net_changes = 0;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'products_on_hand', @role_name = NULL, @supports_net_changes = 0;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customers', @role_name = NULL, @supports_net_changes = 0;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'addresses', @role_name = NULL, @supports_net_changes = 0;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'orders', @role_name = NULL, @supports_net_changes = 0;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'geom', @role_name = NULL, @supports_net_changes = 0;
GO
