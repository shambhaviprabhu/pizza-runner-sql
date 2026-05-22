-- sum and count of exclusions and null
SELECT 
    COUNT(*) AS total_count,
    SUM(exclusions IS NULL) AS null_count,
    SUM(TRIM(exclusions) = '') AS blank_or_space_count,
    SUM(exclusions = '') AS empty_count,
    SUM(LOWER(exclusions) = 'null') AS text_null_count
    
FROM customer_orders;

-- Clean customer_orders 
-- Goal: Standardize messy raw data without touching original tables

CREATE VIEW v_customer_orders_clean AS
SELECT 
	ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_time)
    AS pizza_sequence,
    order_id,
    customer_id,
    pizza_id,
    Case
        When LOWER(TRIM(exclusions)) in  ('', 'null', ' ') Then NULL
        Else TRIM(exclusions)
    END AS exclusions_clean,
    Case 
		When lower(trim(extras)) in ('',' ','null') Then NULL 
        else trim(extras) 
        end as extras_clean,
order_time
from customer_orders;

        

-- Clean runner_orders
        

create view v_runner_orders_clean as
Select 
	order_id,
    runner_id,
    Case 
        When pickup_time = 'null' THEN NULL
        ELSE STR_TO_DATE(pickup_time, '%Y-%m-%d %H:%i:%s')
    END AS pickup_time_clean,
    Case
		When distance = 'null' Then NULL 
        When distance LIKE '%km%' THEN REPLACE(distance, 'km', '')
        else distance
        end as distance_Kms,
    Case
		When duration is null or lower(duration) = 'null' Then Null 
        When duration like '%min%' Then Replace(Replace(Replace(duration,'mins' ,''),'minutes',''),'minute' ,'')
        else duration
        end as duration_mins,
    Case
		When lower(trim(cancellation)) in ('',' ','null') Then  NULL 
        else cancellation
        end as cancellation_clean
from runner_orders;        



-- Fact Table (core table) (Build from the clean views)

CREATE VIEW fact_orders AS
SELECT 
    co.order_id,
    co.customer_id,
    co.pizza_id,
    ro.runner_id,
    co.order_time,
    ro.pickup_time_clean,
    ro.distance_kms,
    ro.duration_mins,
    ro.cancellation_clean
FROM v_customer_orders_clean co
LEFT JOIN v_runner_orders_clean ro
ON co.order_id = ro.order_id;
			

-- dim_customer 

CREATE VIEW dim_customer AS
SELECT DISTINCT customer_id
FROM customer_orders;



-- dim runners
Create view dim_runner as
Select distinct runner_id
from runners;


-- dim_pizza

CREATE VIEW dim_pizza AS
SELECT * FROM pizza_names;


-- dim_toppings

CREATE VIEW dim_toppings AS
SELECT * FROM pizza_toppings;


-- Created a completely cleaned up Customer_orders view as Completely_Clean_Customer_Orders
Create view Final_Customer_Orders as
WITH RECURSIVE cte_exclusion_split AS (
    SELECT 
		pizza_sequence,
        order_id,
        pizza_id,
        TRIM(SUBSTRING_INDEX(exclusions_clean, ',', 1)) AS Toppings,
        SUBSTRING(exclusions_clean, LENGTH(SUBSTRING_INDEX(exclusions_clean, ',', 1)) + 2) AS rest
    FROM v_customer_orders_clean
    WHERE exclusions_clean IS NOT NULL
    
    UNION ALL
    
    SELECT 
		pizza_sequence,
        order_id,
        pizza_id,
        TRIM(SUBSTRING_INDEX(rest, ',', 1)),
        SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2)
    FROM cte_exclusion_split
    WHERE rest IS NOT NULL AND rest <> ''
),
cte_extra_split AS (
    SELECT 
		pizza_sequence,
        order_id,
        pizza_id,
        TRIM(SUBSTRING_INDEX(extras_clean, ',', 1)) AS Toppings,
        SUBSTRING(extras_clean, LENGTH(SUBSTRING_INDEX(extras_clean, ',', 1)) + 2) AS rest
    FROM v_customer_orders_clean
    WHERE extras_clean IS NOT NULL
    
    UNION ALL
    
    SELECT 
		pizza_sequence,
        order_id,
        pizza_id,
        TRIM(SUBSTRING_INDEX(rest, ',', 1)),
        SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2)
    FROM cte_extra_split
    WHERE rest IS NOT NULL AND rest <> ''
),
combined AS (
    SELECT pizza_sequence,order_id, pizza_id, toppings, 'exclusion' AS type FROM cte_exclusion_split
    UNION ALL  -- Use UNION ALL since these are separate topping types
    SELECT pizza_sequence,order_id, pizza_id, toppings, 'extra' AS type FROM cte_extra_split
)
SELECT Distinct
	cc.pizza_sequence,
    cc.order_id,
    cc.customer_id,
    cc.pizza_id, 
	c.toppings,
    c.type,
    DATE(cc.order_time) AS Date,
    TIME(cc.order_time) AS Time
FROM v_customer_orders_clean cc
LEFT JOIN combined c ON c.order_id = cc.order_id
and c.pizza_sequence = cc.pizza_sequence;


 -- Creating final runner_orders view
Create view
	Final__runner_orders As
 Select 
	order_id ,
    runner_id,
    pickup_time_clean,
    Date(pickup_time_clean) as Date,
    time (pickup_time_clean) as Time,
    distance_Kms,
    duration_mins,
    cancellation_clean
from v_runner_orders_clean;    


