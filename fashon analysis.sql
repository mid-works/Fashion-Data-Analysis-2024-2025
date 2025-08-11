CREATE DATABASE fashion_europe_2025 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
FLUSH PRIVILEGES;
USE fashion_europe_2025;
show databases;

-- dim_products
CREATE TABLE dim_products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(255),
  category VARCHAR(100),
  brand VARCHAR(100),
  color VARCHAR(50),
  size VARCHAR(20),
  catalog_price DECIMAL(10,2),
  cost_price DECIMAL(10,2),
  gender ENUM('Male','Female','Unisex','Unknown') DEFAULT 'Unknown'
);

-- dim_channels (normalize channel names and assign channel_id)
CREATE TABLE dim_channels (
  channel_id INT AUTO_INCREMENT PRIMARY KEY,
  channel_name VARCHAR(100) UNIQUE
);

-- dim_campaigns
CREATE TABLE dim_campaigns (
  campaign_id INT AUTO_INCREMENT PRIMARY KEY,
  campaign_name VARCHAR(255) UNIQUE
);

-- fact_sales
CREATE TABLE fact_sales (
  sale_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id VARCHAR(64),
  product_id INT,
  quantity INT NOT NULL DEFAULT 1,
  original_price DECIMAL(10,2),
  unit_price DECIMAL(10,2),
  item_total DECIMAL(12,2),
  channel_id INT,
  campaign_id INT,
  sale_date DATE,
  country VARCHAR(50),
  customer_id VARCHAR(64),
  returned_flag TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
  FOREIGN KEY (channel_id) REFERENCES dim_channels(channel_id),
  FOREIGN KEY (campaign_id) REFERENCES dim_campaigns(campaign_id)
);

CREATE TABLE stg_products (
  product_id INT,
  product_name TEXT,
  category TEXT,
  brand TEXT,
  color TEXT,
  size TEXT,
  catalog_price DECIMAL(10,2),
  cost_price DECIMAL(10,2),
  gender TEXT
);

CREATE TABLE stg_sales (
  quantity INT,
  original_price DECIMAL(10,2),
  unit_price DECIMAL(10,2),
  item_total DECIMAL(12,2),
  channel VARCHAR(255),
  channel_campaigns VARCHAR(255)
);

LOAD DATA LOCAL INFILE '/home/midhun/train/sql/productitems.csv'
INTO TABLE stg_products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, product_name, category, brand, color, size, catalog_price, cost_price, gender);

LOAD DATA LOCAL INFILE '/home/midhun/train/sql/salesietm.csv'
INTO TABLE stg_sales
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(quantity, original_price, unit_price, item_total, channel, channel_campaigns);


-- Clean & Standardize the Staging Data

-- Clean product data
UPDATE stg_products
SET product_name = TRIM(product_name),
    category = TRIM(category),
    brand = TRIM(brand),
    color = TRIM(color),
    size = TRIM(size),
    gender = TRIM(gender);

-- Clean sales data
UPDATE stg_sales
SET channel = TRIM(channel),
    channel_campaigns = TRIM(channel_campaigns);
    
-- Populate Dimension Tables

-- Products
INSERT INTO dim_products (product_id, product_name, category, brand, color, size, catalog_price, cost_price, gender)
SELECT DISTINCT product_id, product_name, category, brand, color, size, catalog_price, cost_price, gender
FROM stg_products
ON DUPLICATE KEY UPDATE 
    product_name = VALUES(product_name),
    category = VALUES(category),
    brand = VALUES(brand),
    color = VALUES(color),
    size = VALUES(size),
    catalog_price = VALUES(catalog_price),
    cost_price = VALUES(cost_price),
    gender = VALUES(gender);
    
--  Channels

INSERT INTO dim_channels (channel_name)
SELECT new_vals.channel
FROM (
    SELECT DISTINCT channel
    FROM stg_sales
    WHERE channel IS NOT NULL
) AS new_vals
ON DUPLICATE KEY UPDATE channel_name = new_vals.channel;

--  Campaigns

INSERT INTO dim_campaigns (campaign_name)
SELECT new_vals.channel_campaigns
FROM (
    SELECT DISTINCT channel_campaigns
    FROM stg_sales
    WHERE channel_campaigns IS NOT NULL
) AS new_vals
ON DUPLICATE KEY UPDATE campaign_name = new_vals.channel_campaigns;


-- Load Fact Table

INSERT INTO fact_sales (
    product_id,
    quantity,
    original_price,
    unit_price,
    item_total,
    channel_id,
    campaign_id
)
SELECT
    p.product_id,
    s.quantity,
    s.original_price,
    s.unit_price,
    s.item_total,
    c.channel_id,
    cmp.campaign_id
FROM stg_sales s
LEFT JOIN dim_products p
    ON ROUND(p.catalog_price, 2) = ROUND(s.unit_price, 2)
LEFT JOIN dim_channels c
    ON s.channel = c.channel_name
LEFT JOIN dim_campaigns cmp
    ON s.channel_campaigns = cmp.campaign_name;

SELECT COUNT(*) FROM fact_sales;

SELECT COUNT(*) AS unmatched_sales
FROM fact_sales
WHERE product_id IS NULL;

UPDATE fact_sales fs
JOIN stg_sales s
    ON fs.product_id IS NULL
   AND fs.quantity = s.quantity
   AND fs.unit_price = s.unit_price
   AND fs.item_total = s.item_total
JOIN dim_products p
    ON ROUND(p.catalog_price, 2) IN (ROUND(s.unit_price, 2), ROUND(s.original_price, 2))
SET fs.product_id = p.product_id;

SELECT COUNT(*) AS unmatched_sales_after
FROM fact_sales
WHERE product_id IS NULL;

-- First KPI & Trend

-- Total Revenue & Units Sold
SELECT 
    SUM(item_total) AS total_revenue,
    SUM(quantity) AS total_units_sold
FROM fact_sales;

-- Top 10 Products by Revenue
SELECT 
    p.product_name,
    p.brand,
    SUM(f.item_total) AS revenue,
    SUM(f.quantity) AS units_sold
FROM fact_sales f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_name, p.brand
ORDER BY revenue DESC
LIMIT 10;

-- Revenue by Category
SELECT 
    p.category,
    SUM(f.item_total) AS revenue,
    SUM(f.quantity) AS units_sold
FROM fact_sales f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Gross Margin by Brand

SELECT 
    p.brand,
    SUM(f.item_total) - SUM(p.cost_price * f.quantity) AS gross_profit,
    ROUND(
        (SUM(f.item_total) - SUM(p.cost_price * f.quantity)) / SUM(f.item_total) * 100, 
        2
    ) AS gross_margin_pct
FROM fact_sales f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.brand
ORDER BY gross_profit DESC;

-- Channel Performance

SELECT 
    c.channel_name,
    SUM(f.item_total) AS revenue,
    SUM(f.quantity) AS units_sold,
    ROUND(AVG(f.item_total), 2) AS avg_sale_value
FROM fact_sales f
JOIN dim_channels c ON f.channel_id = c.channel_id
GROUP BY c.channel_name
ORDER BY revenue DESC;

SELECT 
    c.channel_name,
    SUM(f.item_total) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(SUM(f.item_total) / COUNT(*), 2) AS avg_order_value
FROM fact_sales f
JOIN dim_channels c ON f.channel_id = c.channel_id
GROUP BY c.channel_name
ORDER BY total_revenue DESC;

-- Campaign Performance

SELECT 
    camp.campaign_name,
    SUM(f.item_total) AS revenue,
    SUM(f.quantity) AS units_sold,
    ROUND(AVG(f.item_total), 2) AS avg_sale_value
FROM fact_sales f
JOIN dim_campaigns camp ON f.campaign_id = camp.campaign_id
GROUP BY camp.campaign_name
ORDER BY revenue DESC;

-- Top Product Performance

SELECT 
    p.product_name,
    SUM(f.item_total) AS revenue,
    SUM(f.quantity) AS units_sold,
    ROUND(AVG(f.unit_price), 2) AS avg_price
FROM fact_sales f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- Discount Impact

SELECT 
    p.product_name,
    SUM(f.quantity) AS units_sold,
    ROUND(AVG(f.original_price), 2) AS avg_original_price,
    ROUND(AVG(f.unit_price), 2) AS avg_selling_price,
    ROUND(((AVG(f.original_price) - AVG(f.unit_price)) / AVG(f.original_price)) * 100, 2) AS avg_discount_pct
FROM fact_sales f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_name
ORDER BY avg_discount_pct DESC
LIMIT 10;

-- Price Band Analysis 

SELECT 
    CASE 
        WHEN unit_price < 50 THEN 'Under 50'
        WHEN unit_price BETWEEN 50 AND 99.99 THEN '50-99.99'
        WHEN unit_price BETWEEN 100 AND 199.99 THEN '100-199.99'
        ELSE '200+'
    END AS price_band,
    SUM(quantity) AS units_sold,
    SUM(item_total) AS revenue
FROM fact_sales
GROUP BY price_band
ORDER BY revenue DESC;

-- Margin Contribution Analysis 

SELECT 
    CASE 
        WHEN unit_price < 50 THEN 'Under 50'
        WHEN unit_price BETWEEN 50 AND 99.99 THEN '50-99.99'
        WHEN unit_price BETWEEN 100 AND 199.99 THEN '100-199.99'
        ELSE '200+'
    END AS price_band,
    SUM(item_total - (quantity * original_price * 0.6)) AS margin, -- assuming 60% cost ratio
    ROUND(AVG(item_total - (quantity * original_price * 0.6)), 2) AS avg_margin_per_sale
FROM fact_sales
GROUP BY price_band
ORDER BY margin DESC;

show databases;


