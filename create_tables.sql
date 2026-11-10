-- AdventureWorks internet sales: table definitions for PostgreSQL
-- Run order matters: tables that other tables point to are created first.
--
-- Optional reset (remove the leading -- from the next line to wipe and start over):
-- DROP TABLE IF EXISTS sales, customer, product, calendar, geography, sales_territory;

CREATE TABLE sales_territory (
    sales_territory_key           INTEGER PRIMARY KEY,
    sales_territory_alternate_key INTEGER,
    region                        TEXT,
    country                       TEXT,
    territory_group               TEXT
);

CREATE TABLE geography (
    geography_key       INTEGER PRIMARY KEY,
    city                TEXT,
    state_province_code TEXT,
    state_province_name TEXT,
    country_region_code TEXT,
    country_name        TEXT,
    postal_code         TEXT,
    sales_territory_key INTEGER REFERENCES sales_territory (sales_territory_key)
);

CREATE TABLE calendar (
    date_key             INTEGER PRIMARY KEY,
    full_date            DATE,
    day_number_of_week   SMALLINT,
    day_name             TEXT,
    day_number_of_month  SMALLINT,
    day_number_of_year   SMALLINT,
    week_number_of_year  SMALLINT,
    month_name           TEXT,
    month_number_of_year SMALLINT,
    calendar_quarter     SMALLINT,
    calendar_year        SMALLINT,
    calendar_semester    SMALLINT,
    fiscal_quarter       SMALLINT,
    fiscal_year          SMALLINT,
    fiscal_semester      SMALLINT
);

CREATE TABLE product (
    product_key              INTEGER PRIMARY KEY,
    product_alternate_key    TEXT,
    product_subcategory_key  INTEGER,
    product_name             TEXT,
    standard_cost            NUMERIC(14,4),
    color                    TEXT,
    list_price               NUMERIC(14,4),
    size                     TEXT,
    size_range               TEXT,
    weight                   NUMERIC(10,3),
    days_to_manufacture      SMALLINT,
    product_line             TEXT,
    dealer_price             NUMERIC(14,4),
    class                    TEXT,
    style                    TEXT,
    model_name               TEXT,
    start_date               DATE,
    end_date                 DATE,
    status                   TEXT
);

CREATE TABLE customer (
    customer_key            INTEGER PRIMARY KEY,
    geography_key           INTEGER REFERENCES geography (geography_key),
    birth_date              DATE,
    marital_status          TEXT,
    gender                  TEXT,
    yearly_income           NUMERIC(12,2),
    total_children          SMALLINT,
    number_children_at_home SMALLINT,
    education               TEXT,
    occupation              TEXT,
    house_owner_flag        SMALLINT,
    number_cars_owned       SMALLINT,
    date_first_purchase     DATE,
    commute_distance        TEXT
);

CREATE TABLE sales (
    sales_order_number      TEXT,
    sales_order_line_number SMALLINT,
    product_key             INTEGER REFERENCES product (product_key),
    customer_key            INTEGER REFERENCES customer (customer_key),
    sales_territory_key     INTEGER REFERENCES sales_territory (sales_territory_key),
    order_date_key          INTEGER REFERENCES calendar (date_key),
    due_date_key            INTEGER REFERENCES calendar (date_key),
    ship_date_key           INTEGER REFERENCES calendar (date_key),
    order_date              DATE,
    due_date                DATE,
    ship_date               DATE,
    order_quantity          SMALLINT,
    unit_price              NUMERIC(14,4),
    extended_amount         NUMERIC(14,4),
    unit_price_discount_pct NUMERIC(6,4),
    discount_amount         NUMERIC(14,4),
    product_standard_cost   NUMERIC(14,4),
    total_product_cost      NUMERIC(14,4),
    sales_amount            NUMERIC(14,4),
    tax_amt                 NUMERIC(14,4),
    freight                 NUMERIC(14,4),
    PRIMARY KEY (sales_order_number, sales_order_line_number)
);
