-- Find the total number of products sold by each store along with the store name.
select stores.store_name, 
sum(order_items.quantity) as Total_quantity from 
stores join orders 
using(Store_id) 
join order_items 
using(order_id)
group by stores.store_name


-- Calculate the cumulative sum of quantities sold for each product over time.
with a as ( select products.product_id, 
products.product_name, 
orders.order_date,  
sum(order_items.quantity) Quantity from products join order_items using(product_id) join orders using (order_id)
group by  products.product_id, products.product_name,  orders.order_date 
)
select *, sum(quantity) over (partition by product_id order by order_date) as Cumulative_Quantity from a 


-- Find the product with the highest total sales (quantity * price) for each category.
with a as ( select products.product_id, products.product_name, products.category_id,
sum(order_items.quantity * order_items.List_price) as Sales
from products join order_items using (product_id)
group by products.product_id, products.product_name, products.category_id
)
select product_name from (
 select *, rank() over (partition by category_id order by sales desc ) rnk from a
) b
where rnk = 1;


-- Find the customer who spent the most money on orders.
with a as (select customers.customer_id, concat(customers.first_name," " ,customers.last_name) as full_name,
sum(order_items.quantity * order_items.list_price) as sales from customers join orders using(customer_id) join order_items using (order_id)
group by customers.customer_id, full_name
)
select customer_id, full_name from a 
where sales = (Select max(Sales) from a );


-- Find the highest-priced product for each category name.
with a as 
( 
select categories.category_name, products.product_name, products.list_price, 
rank() over (partition by products.category_id order by products.list_price desc) 
as rnk 
from products 
join categories using(category_id)
)
select category_name, product_name, list_price 
from a 
where rnk = 1;


-- Find the total number of orders placed by each customer per store.
select customers.customer_id, concat(customers.first_name," " ,customers.last_name) as full_name,
stores.store_name, count(orders.order_id) as total_orders
from customers left join orders using(Customer_id) left join stores using (store_id)
group by customers.customer_id, full_name,
stores.store_name


--  Find the names of staff members who have not made any sales.
select * from staffs
where staff_id not in (Select staff_id from orders)
OR 
select * from staffs
where not exists (Select staff_id from orders
where orders.staff_id = staffs.staff_id)


--  Find the top 3 most sold products in terms of quantity.
select 
  product_name,
  sum(quantity) as total_quantity_sold
from order_items
join products using(product_id)
group by product_name
order by total_quantity_sold desc
limit 3;


--  Find the median value of the price list.
With a as 
(
Select list_price,
row_number() over (order by list_price) as pos,
count(*) over() n from order_items )
select case
			when n% 2 = 0 then (select avg(list_price) from a where pos in ((n/2), (n/2)+1))
            else (select list_price from  a where pos = (n+1)/2)
            end as Median from a limit 1


--  List all products that have never been ordered.(use Exists)
select product_id, product_name from products
where not exists (Select product_id from order_items where products.product_id = order_items.product_id);


--  List the names of staff members who have made more sales than the average number of sales by all staff members.
With a as
(
Select staffs.staff_id, concat(staffs.first_name , " " , staffs.last_name) as Full_Name, 
coalesce(sum(order_items.list_price * order_items.quantity),0) Sales  from 
staffs left join orders using  (staff_id) left join order_items using (order_id)
group by staffs.staff_id, Full_Name

)
select * from a where sales > (Select avg(sales) from a );


--  Identify the customers who have ordered all types of products (i.e., from every category).
select customers.customer_id,
count(order_items.order_id)
from customers 
join orders using(customer_id) 
join order_items using (order_id) 
join products on (order_items.product_id = products.product_id)
group by customers.customer_id
having count(distinct products.category_id) = (select count(category_id) from categories);