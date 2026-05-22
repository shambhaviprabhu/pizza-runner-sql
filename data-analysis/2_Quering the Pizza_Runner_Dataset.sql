-- A. Pizza Metrics
-- How many pizzas were ordered?

SELECT COUNT(pizza_id) AS total_pizzas_ordered
FROM customer_orders;


-- How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id, order_id) AS customer_orders
FROM customer_orders;


-- How many successful orders were delivered by each runner?

Select 
	runner_id,
    Count(distinct order_id) Total_Orders_Delivered
from final__runner_orders
where cancellation_clean is null
and time is not  null
group by runner_id ;



-- How many of each type of pizza was delivered?

Select 
	co.pizza_id,
    pn.pizza_name,
    Count(co.order_id) as Count_Of_Pizzas
from final_customer_orders co
join pizza_names pn on co.pizza_id=pn.pizza_id
join final__runner_orders ro on ro.order_id = co.order_id
where ro.cancellation_clean is null and pickup_time_clean is not  null
Group by co.pizza_id, pn.pizza_name ;

-- How many Vegetarian and Meatlovers were ordered by each customer?


SELECT 
    co.Customer_id,
    SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS Meatlovers,
    SUM(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS Vegetarian
FROM final_customer_orders co
JOIN pizza_names pn 
  ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id;
   
   
   
-- What was the maximum number of pizzas delivered in a single order?

With cte_Pizza_Count As
(
Select 
	co.order_id ,
    count(co.pizza_id) as Pizzas_delivered
from   final_customer_orders  co
join  final__runner_orders    ro on co.order_id=ro.order_id
where cancellation_clean is null and pickup_time_clean is not null
group by co.order_id )

Select * 
from     cte_Pizza_Count
where Pizzas_delivered = (Select Max( Pizzas_delivered) from cte_Pizza_Count) ;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?


Select 
	co.customer_id,
    count(co.pizza_id) as Total_Pizza_ordered,
	sum(case When co.exclusions_clean is null and co.extras_clean is null then 1 else 0 end ) as Count__of_Pizzas_UnChanged ,
	sum(case When co.exclusions_clean is null and co.extras_clean is null then 0 else 1 end)  as Count__of_Pizzas_Changed
from v_customer_orders_clean co
join final__runner_orders ro on co.order_id = ro.order_id 
where cancellation_clean is null and pickup_time_clean is not null
Group by co.customer_id
order by co.customer_id;


-- How many pizzas were delivered that had both exclusions and extras?

Select count(*) as Pizza_with_excl_extra
from v_customer_orders_clean co
join final__runner_orders ro on co.order_id = ro.order_id
where cancellation_clean is null and pickup_time_clean is not null
and exclusions_clean is not null and extras_clean is not null;


-- What was the total volume of pizzas ordered for each hour of the day?

Select
	lpad(hour(order_time),2,0) as Hours,
	Count(pizza_id) as Pizzas_ordered
from v_customer_orders_clean 
group by  lpad(hour(order_time),2,0) 
order by lpad(hour(order_time),2,0)  ;

-- What was the volume of orders for each day of the week?

Select
	dayname(order_time) as Days_of_Week,
	Count(distinct order_id) as Pizzas_ordered
from v_customer_orders_clean 
group by DAYOFWEEK(order_time), dayname(order_time) 
order by  DAYOFWEEK(order_time);





   