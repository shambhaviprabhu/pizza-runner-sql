# SQL Pizza Runner Queries

This repository contains SQL scripts for the Pizza Runner dataset. The files are organized into subfolders for schema setup, data cleaning, analysis, and simple select queries.

## Folder Overview

### `schema/`
- `create table_insert_pizza.sql`
  - Creates the `pizza_runner` database and defines all base tables:
    - `runners`
    - `customer_orders`
    - `runner_orders`
    - `pizza_names`
    - `pizza_recipes`
    - `pizza_toppings`
    - `pizza_ratings`
  - Inserts sample rows for each table.
  - Includes schema for a ratings table and example rating records for successful deliveries.

### `select-queries/`
- `select-pizza.sql`
  - Simple `SELECT *` queries for the main tables in the dataset.
  - Useful for verifying the imported base data and schema contents.

### `data-cleaning/`
- `1_Data_cleaning_transforming.sql`
  - Cleans raw customer and runner order data.
  - Creates views:
    - `v_customer_orders_clean`
    - `v_runner_orders_clean`
    - `fact_orders`
    - `dim_customer`
    - `dim_runner`
    - `dim_pizza`
    - `dim_toppings`
    - `Final_Customer_Orders`
  - Standardizes raw string values like `null`, blank text, and unit formatting.
  - Builds a cleaned fact table and dimension views for analysis.

### `data-analysis/`
Contains four analytical query scripts.

#### `2_Quering the Pizza_Runner_Dataset.sql`
- Basic pizza order metrics:
  - total pizzas ordered
  - unique customer orders
  - successful deliveries by runner
  - counts of each pizza type delivered
  - customer-level totals for Vegetarian and Meatlovers pizzas
  - maximum pizzas in a single delivered order
  - counts of changed vs unchanged pizzas
  - count of pizzas with both exclusions and extras
  - hourly order volume
  - weekday order volume

#### `3_Analysis of Ingredient Optimisation.sql`
- Ingredient / recipe-focused analysis:
  - normalize pizza recipes into a clean ingredient view
  - list standard ingredients for each pizza
  - most commonly added extra topping
  - most common topping exclusion
  - create order item labels such as `Meat Lovers - Exclude Beef` or `Meat Lovers - Extra Bacon`
  - generate alphabetically ordered ingredient lists per order with `2x` indicators for extras
  - compute total ingredient usage across delivered pizzas

#### `4_Analysis of Runner and Customer Experience.sql`
- Runner and delivery performance metrics:
  - weekly runner signup counts
  - average pickup time per runner
  - relationship between pizza count and order preparation time
  - average delivery distance per customer
  - difference between longest and shortest delivery duration
  - average speed per runner per delivery
  - delivery success percentage for each runner

#### `5_Pricing and Ratings.sql`
- Revenue and rating analysis:
  - total revenue from Meat Lovers and Vegetarian pizzas at fixed prices
  - revenue including a $1 extra charge for cheese
  - sample `pizza_ratings` table design and rating data for successful orders
  - join orders, runner details, ratings, and timing metrics for successful deliveries
  - compute net revenue after paying runners $0.30 per kilometer

## Usage Notes

- Run `schema/create table_insert_pizza.sql` first to build the sample dataset.
- Use `data-cleaning/1_Data_cleaning_transforming.sql` to generate cleaned views and facts needed by the analysis scripts.
- The `data-analysis` scripts assume the existence of the cleaned views and final order tables created in the data cleaning step.
- `select-queries/select-pizza.sql` is a quick sanity check to inspect raw table contents.




