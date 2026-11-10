# AdventureWorks Sales Analysis (SQL, PostgreSQL)

The SQL version of my [Excel analysis](https://github.com/robertmwawasi/adventureworks-excel-analysis) of a fictional bicycle company's online sales. I built a PostgreSQL database from the practice data, then repeated the analysis in SQL and checked every result against the Excel workbook.

## About the project

- **Data:** Microsoft's AdventureWorks practice dataset (internet sales, July 2005 to July 2008)
- **Size:** 60,398 items sold, 27,659 orders, 18,484 customers
- **Headline numbers:** $29.4M revenue, $12.1M profit, 41.1% margin
- **Tools:** PostgreSQL 18, pgAdmin 4

## What is in this repository

| File | What it is |
|---|---|
| [create_tables.sql](create_tables.sql) | Builds the six tables, with primary keys and foreign keys |
| [queries.sql](queries.sql) | All analysis queries, grouped by topic, with expected results |

The data files are not included. See "How to reproduce" below.

## The database

It is a star schema: one sales table in the middle, linked to product, customer, calendar and sales territory tables (customers link to geography, and geography to territory).

| Table | Rows |
|---|---|
| sales | 60,398 |
| product | 606 |
| customer | 18,484 |
| geography | 655 |
| calendar | 2,191 |
| sales_territory | 11 |

## What the queries cover

1. **Sales over time:** revenue, profit and margin by year, month and fiscal year
2. **Products:** best and worst sellers, and how cheap accessories changed the average order
3. **Geography:** revenue, share and margin by country and region
4. **Customers:** average and median spend, big-ticket buyers versus accessories-only, and spend by occupation
5. **Seasonality:** weekday, fiscal-year change and monthly share of the year
6. **Customer groups (RFM):** scoring and naming segments, and their share of revenue
7. **Repeat buying (cohorts):** gaps between orders, reorder rates, and a fair comparison between cohorts

## SQL skills shown

Joins and LEFT JOINs, GROUP BY and aggregates, CASE, subqueries, CTEs (WITH), window functions (LAG, ROW_NUMBER, SUM OVER with PARTITION BY), FILTER, percentile_cont for medians, date arithmetic, primary and foreign keys, NULL handling, and reconciling results to a second source.

## Checks I made along the way

- Row counts and the $29,358,677 revenue total match the Excel workbook.
- Every query was compared with the Excel result for the same question.
- I looked for traps in the data: missing values stored as NULL in some columns and as the text "NA" in others, stray spaces in the product line codes, and delivery dates with no variation, which is why delivery is not analysed.
- Groups were compared on equal terms (equal observation windows and a common starting date).

## How to reproduce

1. Create a database: `CREATE DATABASE adventureworks WITH ENCODING 'UTF8' TEMPLATE template0;`
2. Run `create_tables.sql`.
3. Load your own copy of the AdventureWorks internet sales data into the six tables with `\copy` (one CSV per table, with a header row).
4. Run the queries in `queries.sql`, one at a time.

## Limits

- This is a practice dataset, not a real company's records.
- The data has no product-category table, so "bike versus accessory" is approximated by price (under $100).
- 2005 and 2008 are partial years, and July 2008 is almost empty.
- Repeat purchases only begin on 1 July 2007, so reorder timing before then cannot be studied.
- The patterns are associations, not proof of cause.

## Data source

The data comes from Microsoft's AdventureWorks sample databases, which describe a fictional bicycle company. Microsoft publishes its SQL samples under the MIT license: https://learn.microsoft.com/en-us/sql/samples

I worked from an Excel version of the data downloaded from: https://selar.com/235xdv3727

## About me

**Robert Mwawasi**, learning data analysis and building a portfolio. Next steps: Power BI and Power Query on the same dataset.

LinkedIn: https://www.linkedin.com/in/robert-mwawasi
