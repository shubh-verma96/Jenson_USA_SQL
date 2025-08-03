# 📊 Jenson USA Data Insights via SQL  
**By Shubham Verma**

# 📌 Overview
Analyzed retail sales data using MySQL Workbench to uncover insights on customer behavior, sales patterns, and product performance. The project included data cleaning, exploration, and advanced SQL queries.

## 🧰 Tools & Techniques  
- **MySQL Workbench**
- Joins & Subqueries  
- Aggregations & Window Functions  
- CTEs & EXISTS filtering  

## 🔍 Key Business Questions:
1️⃣ Find the total number of products sold by each store along with the store name.
```sql
select stores.store_name, 
sum(order_items.quantity) as Total_quantity from 
stores join orders 
using(Store_id) 
join order_items 
using(order_id)
group by stores.store_name
```


2️⃣ Calculate the cumulative sum of quantities sold for each product over time.

```sql
with a as
( Select products.product_id, products.product_name, orders.order_date,
sum(order_items.quantity) as Quantity
from products
join order_items using (product_id)
join orders using (order_id)
group by products.product_id, products.product_name, orders.order_date )
Select *, sum(quantity) over (partition by product_id order by order_date) as Cumulative_Quantity from a ;

```
3️⃣ Find the product with the highest total sales (quantity * price) for each category.

```sql
with a as
(
Select products.product_id, products.product_name, products.category_id,
sum(order_items.quantity * order_items.List_price) as Sales
from products join order_items using (product_id)
group by products.product_id, products.product_name, products.category_id
)
Select product_name from
(
Select*, rank() over (partition by category_id order by sales desc ) rnk from a
) b
where rnk = 1;
```
4️⃣ Find the customer who spent the most money on orders.
```sql
with a as
(
select customers.customer_id, concat(customers.first_name, " " ,customers.last_name) as full_name,
sum(order_items.quantity * order_items.list_price) as sales
from customers join orders using(customer_id) join order_items using (order_id)
group by customers.customer_id, full_name
)
select customer_id, full_name from a
where sales = (select max(Sales) from a );
```
5️⃣ Find the highest-priced product for each category name.

```sql
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
where rnk = 1 ;

```
6️⃣ Find the total number of orders placed by each customer per store.

```sql
select customers.customer_id,
concat(customers.first_name, " " , customers.last_name) as full_name, stores.store_name,
count(orders.order_id) as total_orders
from customers
left join orders using(Customer_id)
left join stores using (store_id)
group by customers.customer_id, full_name, stores.store_name ;
```
7️⃣ Find the names of staff members who have not made any sales.

```sql
select * from staffs
where staff_id not in (select staff_id from orders)
```
  
8️⃣ Find the top 3 most sold products in terms of quantity.

```sql
select product_name, sum(quantity) as total_quantity_sold
from order_items
join products using(product_id)
group by product_name
order by total_quantity_sold desc
limit 3 ;
```
9️⃣  Find the median value of the price list.


```sql
with a as (
select list_price, row_number() over (order by list_price) as pos,
count(*) over() as n from order_items
)
select case
when n% 2 = 0 then ( select avg(list_price) from a where pos in ((n/2), (n/2)+1) )
else ( select list_price from a where pos = (n+1)/2 )
end as Median from a limit 1 ;
```
🔟 List all products that have never been ordered.(use Exists)

```sql
select product_id, product_name from products
where not exists
(
select product_id from order_items
where products.product_id = order_items.product_id
)
```
1️⃣1️⃣ List the names of staff members who have made more sales than the average number of sales by all staff
members.

```sql
with a as
( select staffs.staff_id, concat(staffs.first_name , " " , staffs.last_name) as Full_Name,
coalesce(sum(order_items.list_price * order_items.quantity) ,0) Sales
from staffs left join orders using (staff_id)
left join order_items using (order_id)
group by staffs.staff_id, Full_Name
)
select * from a
where sales > (Select avg (sales) from a );
```
1️⃣2️⃣Identify the customers who have ordered all types of products (i.e., from every category).

```sql
select customers.customer_id, count(order_items.order_id)
from customers
join orders using (customer_id)
join order_items using (order_id)
join products using (product_id)
group by customers.customer_id
having count(distinct products.category_id) = (select count(category_id) from categories);
```
