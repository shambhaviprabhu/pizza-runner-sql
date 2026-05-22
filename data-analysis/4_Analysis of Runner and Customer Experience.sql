-- Analysis for Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

Select

	FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) + 1 AS week_number,
    count(runner_id) as no_of_runners
from  runners
group by week_number ;  


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

Select 
	runner_id,
    round(avg(duration_mins),2) as Avg_mins_taken
from final__runner_orders 
where cancellation_clean is null 
	and pickup_time_clean is not  null
group by runner_id
order by  runner_id;   


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

Select 
	co.order_id,
    Date(co.order_time) as Order_Day,
    Time(co.order_time) as Order_time,
    Time(ro.pickup_time_clean)  as Pickup_time,
    TIMESTAMPDIFF(MINUTE, order_time, pickup_time_clean)as Pizza_Prep_Time_mins,
    count(co.pizza_id) as Pizza_Counts
from   v_customer_orders_clean   co
join  v_runner_orders_clean ro on co.order_id = ro.order_id
where cancellation_clean is null 
	and pickup_time_clean is not  null 
group by co.order_id,  co.order_time , ro.pickup_time_clean;


-- 4.What was the average distance travelled for each customer?

With cte_distance as
(
Select 
		co.order_id,
        co.customer_id,
        ro.distance_kms
from final_customer_orders co
join final__runner_orders ro on co.order_id = ro.order_id
where cancellation_clean is Null And pickup_time_clean is not Null
GROUP BY co.order_id, co.customer_id, ro.distance_kms)

Select 
	customer_id as Customers,
	round(avg(distance_kms),2) as Avg_Distance
    
from     cte_distance 
group by customer_id ;


-- 5. What was the difference between the longest and shortest delivery times for all orders?

Select 
	Max(duration_mins) Max_Delivery_time,
    Min(duration_mins) Min_Delivery_time ,
	Max(duration_mins) - Min(duration_mins) as Diff_Longest_Shortest_time 
from final__runner_orders
where cancellation_clean is Null And pickup_time_clean is Not Null
	AND duration_mins IS NOT NULL;
    
    
-- What was the average speed for each runner for each delivery and do you notice any trend for these values?  

Select 
	runner_id,
	order_id,
    round(avg(distance_Kms/duration_mins*60),2) as Avg_speed_km_hr
from     final__runner_orders
where cancellation_clean is Null 
	And pickup_time_clean is Not Null
	AND duration_mins IS NOT NULL
group by   runner_id ,order_id
order by runner_id   ;


-- 7.What is the successful delivery percentage for each runner?
  
Select 
	runner_id,
    ROUND(
        SUM(CASE 
                WHEN cancellation_clean IS NULL THEN 1 
                ELSE 0 
            END) * 100.0 / COUNT(*),
    0) AS successful_delivery_percent
from final__runner_orders
group by runner_id ;    








