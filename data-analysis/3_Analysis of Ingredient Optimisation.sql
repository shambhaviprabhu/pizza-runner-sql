-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?

USE pizza_runner;

create view  pizza_recipe_clean as
( 
 With recursive cte_toppings as
(
Select 
	pizza_id,
    trim(substring_index(toppings,',', 1)) as Toppings,
    Substring(toppings,length(substring_index(toppings,',', 1))+2) as Rest
from    pizza_recipes     

Union All

Select  
	pizza_id,
	trim(substring_index(Rest,',', 1)) ,
    Substring(Rest,length(substring_index(Rest,',', 1))+2)          
from    cte_toppings
where rest is not null
	And rest <> '' )

Select 
	Pizza_id,
    Toppings
from     cte_toppings 
order by Pizza_id );


Select
	pn.pizza_name,
    GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS ingredients
from pizza_recipe_clean pr
join pizza_toppings pt on pr.toppings = pt.topping_id
join pizza_names pn on pn.pizza_id = pr.pizza_id
Group by pn.pizza_name
order by pn.pizza_name;

-- 2.What was the most commonly added extra?   

With cte_topping_count as
(
Select 
	pt.topping_id,
	pt.topping_name,
	count(co.toppings) as Topping_count,
    rank()over( order by count(co.toppings) desc) as rnk
from final_customer_orders    co
join pizza_toppings pt on pt.topping_id = co.toppings
where co.type = 'extra'
group by pt.topping_id,pt.topping_name)
Select
	Topping_id,
	Topping_name,    
	Topping_count
from     cte_topping_count
where rnk =1;

-- 3. What was the most common exclusion?
With cte_Exclusion_count as
(
Select
	pt.topping_id,
    pt.topping_name,
    count(co.toppings) as Topping_count,
    rank()over(order by count(co.toppings) desc) as rnk
from    final_customer_orders co
join 	pizza_toppings pt on pt.topping_id = co.toppings
where type = 'exclusion'
group by pt.topping_id,pt.topping_name)

Select 
	Topping_id,
    Topping_name,
	Topping_count
from     cte_Exclusion_count 
where rnk =1;


-- 4 .Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers , Meat Lovers - Exclude Beef ,Meat Lovers - Extra Bacon , Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


With Cte_exclusion as
(
Select 
	co.Order_id,
	co.pizza_id,
    group_concat(Distinct co.toppings ORDER BY co.toppings separator ', ') as Exclusions,
    group_concat(Distinct pt.topping_name ORDER BY co.toppings separator ', ') as Exclusions_name
From final_customer_orders co
left join pizza_toppings pt on  pt.topping_id = co. toppings
Where co.type = 'exclusion'
Group by co.order_id ,co.pizza_id
),
Cte_extra as
(
Select 
	co.Order_id,
    co.pizza_id,
    group_concat(Distinct co.toppings ORDER BY co.toppings separator ', ') as Extra,
    group_concat(Distinct pt.topping_name ORDER BY co.toppings separator ', ') as Extra_name
From final_customer_orders co
left join pizza_toppings pt on  pt.topping_id = co. toppings
Where co.type = 'extra'
Group by co.order_id ,co.pizza_id
)
Select 
	co.Order_id,
    Concat ( pn.pizza_name,
 Case 
	When e.exclusions_name IS NOT NULL 
	Then CONCAT(' - Exclude ', e.exclusions_name)
	ELSE ''
	END,

Case 
	When x.extra_name IS NOT NULL 
	Then CONCAT(' - Extra ', x.extra_name)
	ELSE ''
	END)
    AS order_item
from   v_customer_orders_clean co 

left join pizza_names pn
 on pn.pizza_id = co.pizza_id

left join Cte_exclusion e
 on e.order_id = co.order_id
AND e.pizza_id = co.pizza_id

left join Cte_extra x 
on x.order_id = co.order_id
 AND x.pizza_id = co.pizza_id ;



-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order
-- from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH base AS (
    SELECT
        co.order_id,
        pn.pizza_name,
        pt.topping_name
    FROM final_customer_orders co
    JOIN pizza_names pn
        ON pn.pizza_id = co.pizza_id
    JOIN pizza_recipe_clean pr
        ON pr.pizza_id = co.pizza_id
    JOIN pizza_toppings pt
        ON pt.topping_id = pr.toppings
)

SELECT
    b.order_id,
    b.pizza_name,

    GROUP_CONCAT(

        CASE
            WHEN EXISTS (
                SELECT 1
                FROM final_customer_orders co2
                JOIN pizza_toppings pt2
                    ON pt2.topping_id = co2.toppings

                WHERE co2.order_id = b.order_id
                  AND co2.type = 'extra'
                  AND pt2.topping_name = b.topping_name
            )

            THEN CONCAT('2x', b.topping_name)

            ELSE b.topping_name
        END

        ORDER BY b.topping_name
        SEPARATOR ', '

    ) AS Pizza_Ingredients

FROM base b

GROUP BY
    b.order_id,
    b.pizza_name;
    
    
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


With cte_base_ingredients as
(    
Select 
	co.order_id,	
    co.pizza_id,
    pt.topping_name
from  final_customer_orders co
left join final__runner_orders ro on co.order_id = ro.order_id
left join pizza_recipe_clean pr on pr.pizza_id = co.pizza_id
left join pizza_toppings pt on pt.topping_id = pr.toppings
where cancellation_clean is null and pickup_time_clean is not null
AND NOT EXISTS (
        SELECT 1
        FROM final_customer_orders co2
        WHERE co2.order_id = co.order_id
          AND co2.type = 'exclusion'
          AND co2.toppings = pr.toppings
)),
 
 cte_extra_toppings as 
 (
 Select 
	co.order_id,	
    co.pizza_id,
	pt.topping_name
    
from  final_customer_orders co
left join final__runner_orders ro on co.order_id = ro.order_id
left join pizza_toppings pt on pt.topping_id = co.toppings
where cancellation_clean is null and pickup_time_clean is not null
and co.type = 'extra'
),


cte_total_ingredients as
 (
Select * from   cte_base_ingredients 
Union All
Select * from cte_extra_toppings )

Select 
	Topping_name,
	count(*) as Total_Quantity
from     cte_total_ingredients
group by topping_name
order by Total_Quantity desc;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    