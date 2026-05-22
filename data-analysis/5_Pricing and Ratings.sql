-- Pricing and Ratings

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes -
--  how much money has Pizza Runner made so far if there are no delivery fees?


WITH cte_Pizza_Sold AS (
    SELECT
        pn.pizza_name,
        COUNT(co.pizza_id) AS Pizzas_Sold,
        SUM(CASE 
            WHEN pn.pizza_name = 'MeatLovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
        END) AS Total_revenue
    FROM v_customer_orders_clean co
    JOIN final__runner_orders ro ON co.order_id = ro.order_id
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id    
    WHERE ro.cancellation_clean IS NULL 
      AND ro.pickup_time_clean IS NOT NULL
    GROUP BY pn.pizza_name
)
SELECT 
    pizza_name,
    Pizzas_Sold,
    Total_revenue
FROM cte_Pizza_Sold 
UNION ALL
SELECT 
    'TOTAL' AS pizza_name,
    SUM(Pizzas_Sold) AS Pizzas_Sold,
    SUM(Total_revenue) AS Total_revenue
FROM cte_Pizza_Sold;


-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra


With Cte_Extra_Cheese_cost as
(
Select 	
	sum(case
			When co.type = 'extra' and co.toppings = 4 then 1
            else 0
            end) As Extra_Cheese_price
	
from  final_customer_orders  co
join   final__runner_orders   ro on ro.order_id = co.order_id
where cancellation_clean is null and pickup_time_clean is not null ),


cte_Base_Pizza_cost AS (
    SELECT
      
        SUM(CASE 
            WHEN co.pizza_id = 1 THEN 12
            WHEN co.pizza_id = 2 THEN 10
            Else 0
        END) AS Base_Pizza_cost
    FROM v_customer_orders_clean co
    JOIN final__runner_orders ro ON co.order_id = ro.order_id
    WHERE ro.cancellation_clean IS NULL 
      AND ro.pickup_time_clean IS NOT NULL)
      
 Select  
	Extra_Cheese_price ,
    Base_Pizza_cost,
    (Base_Pizza_cost + Extra_Cheese_price ) as Total_Pizza_Cost
from  Cte_Extra_Cheese_cost
 cross join  cte_Base_Pizza_cost;
 
 
 -- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
 -- how would you design an additional table for this new dataset - 
 -- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

        
 Select order_id ,runner_id 
 from final__runner_orders 
 where cancellation_clean is null and pickup_time_clean is not null;
 


-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information
-- for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas


Select 
	co.customer_id,
	co.order_id,
    ro.runner_id,
    pr.ratings,
    co.order_time,
    ro.pickup_time_clean as pickup_time,
	timestampdiff(minute ,co.order_time,ro.pickup_time_clean )as Time_Between_Order_n_Pickup_Time_mins,
    ro.duration_mins as Delivery_duration_mins,
    round((distance_Kms/duration_mins*60),2) as Average_speed_kmh,
    count(co.pizza_id)  as Total_number_Of_Pizzas
    
from v_customer_orders_clean co 
join v_runner_orders_clean ro on co.order_id = ro.order_id
join pizza_ratings pr on pr.order_id = ro.order_id
where ro.cancellation_clean is null and pickup_time_clean is not null
Group by
	co.customer_id,
	co.order_id,
	ro.runner_id,
	pr.ratings,
    co.order_time,
	ro.pickup_time_clean,
	ro.duration_mins,
	ro.distance_kms
order by co.order_id;

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
-- and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

With cte_Total_Revenue as
(
Select
	Sum(
		Case When co.pizza_id = 1 then 12
			When  co.pizza_id = 2 then 10
			Else 0
    End) as Total_Revenue_$
from     v_customer_orders_clean co
join final__runner_orders ro on ro.order_id = co.order_id
where ro.cancellation_clean is null and ro.pickup_time_clean is not null),

Runner_expenditure as
(
Select 
    sum(distance_Kms * 0.30) as Payments_to_runner_$
from    final__runner_orders  
where cancellation_clean is null and pickup_time_clean is not null )

Select 	
	Total_Revenue_$ ,
    Payments_to_runner_$,
    Total_Revenue_$ - Payments_to_runner_$ as Dollar_bal_after_Deliveries_$
from   cte_Total_Revenue
cross join    Runner_expenditure ;





		
		



