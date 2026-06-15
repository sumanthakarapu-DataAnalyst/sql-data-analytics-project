-- ============================================================
-- LEVEL 1: BASIC
-- ============================================================

-- Q1. Customers by segment
-- Concept: GROUP BY + COUNT

SELECT segment, COUNT(*) AS total_customers
FROM customers
GROUP BY segment
ORDER BY total_customers DESC;

/*
Result:
Regular | 491
New     | 316
VIP     | 193
*/


-- ============================================================
-- Q2. Orders by status
-- Concept: GROUP BY + COUNT

SELECT status, COUNT(*) AS total_orders
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

/*
Result:
Delivered | 2322
Shipped   | 226
Cancelled | 169
Pending   | 168
Returned  | 115
*/


-- ============================================================
-- Q3. Revenue by category
-- Concept: JOIN + GROUP BY + SUM

SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

/*
Result (top 3):
Electronics | 47,529,822
Furniture   | 24,117,350
Appliances  | 22,506,808
*/


-- ============================================================
-- Q4. Top 10 customers by spend (after discount, Delivered only)
-- Concept: Multi-table JOIN + discount math + LIMIT

SELECT 
    c.customer_name,
    c.segment,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS net_spend
FROM orders o
JOIN customers c    ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY net_spend DESC
LIMIT 10;

/*
Result (top 3):
Kavya Kumar  | Regular | 682,514.55
Pooja Rao    | New     | 640,394.40
Sunita Naidu | New     | 639,739.30
*/


-- ============================================================
-- Q5. Yearly revenue (Delivered orders)
-- Concept: Date extraction + GROUP BY

SELECT 
    YEAR(o.order_date) AS yr,                       
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY yr
ORDER BY yr;

/*
Result:
2022 | 28,139,884.80
2023 | 24,952,752.05
2024 | 32,208,247.30
*/


-- ============================================================
-- Q6. Top 5 cities by revenue
-- Concept: 3-table JOIN + GROUP BY + LIMIT

SELECT 
    c.city,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS revenue
FROM orders o
JOIN customers c    ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY c.city
ORDER BY revenue DESC
LIMIT 5;

/*
Result:
Kolkata    | 4,568,199.75
Dehradun   | 4,566,097.15
Nagpur     | 4,421,178.75
Delhi      | 4,019,308.25
Chandigarh | 3,995,420.70
*/


-- ============================================================
-- Q7. Average Order Value (AOV) by payment mode
-- Concept: COUNT DISTINCT + SUM / COUNT

SELECT 
    o.payment_mode,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY o.payment_mode
ORDER BY avg_order_value DESC;




/*
Result:
Net Banking | 132 orders | AOV 47,645.47
Debit Card  | 370 orders | AOV 42,401.84
Credit Card | 505 orders | AOV 41,395.13
COD         | 317 orders | AOV 41,224.04
UPI         | 998 orders | AOV 37,806.93

Insight: Net Banking users place fewer but higher-value orders
*/



-- ============================================================
-- Q8. Detect duplicate customer emails
-- Concept: GROUP BY + HAVING COUNT > 1

SELECT 
    email,
    COUNT(*) AS occurrences
FROM customers
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

/*
Result (sample - 5 duplicates found):
suresh.pillai628@gmail.com  | 2
sunita.rao849@outlook.com   | 2
shreya.nair621@gmail.com    | 2
ritika.singh888@hotmail.com | 2
pallavi.khan81@hotmail.com  | 2


*/



-- ============================================================
-- Q9. Customers active in 2023 but NOT in 2024 (churned)
-- Concept: NOT IN subquery with date filters

SELECT COUNT(*) AS churned_customers
FROM (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE YEAR(order_date) = 2023
      AND customer_id NOT IN (
          SELECT customer_id FROM orders WHERE YEAR(order_date) = 2024
      )
) AS churned;


-- Result: 222 customers
/*
To list them instead of counting, just SELECT customer_id 
and JOIN to customers table.
*/


-- ============================================================
-- Q10. Profit margin classification + count
-- Concept: CASE WHEN inside subquery + GROUP BY

SELECT 
    margin_label,
    COUNT(*) AS product_count
FROM (
    SELECT 
        product_name,
        CASE 
            WHEN ((selling_price - cost_price) / selling_price) * 100 > 40 THEN 'High'
            WHEN ((selling_price - cost_price) / selling_price) * 100 >= 20 THEN 'Medium'
            ELSE 'Low'
        END AS margin_label
    FROM products
) AS labeled
GROUP BY margin_label
ORDER BY product_count DESC;

/*
Result:
Medium | 121 products
High   | 101 products
Low    |  28 products
*/


-- ============================================================
-- Q11. Customers who never returned a product
-- Concept: NOT IN with JOIN-based subquery

SELECT COUNT(DISTINCT c.customer_id) AS never_returned
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT o.customer_id 
    FROM orders o 
    JOIN returns r ON o.order_id = r.order_id
); 

/*
Result: 759 customers out of 1,000 never returned anything
(i.e., ~24% of customers have returned at least one item)
*/




-- ============================================================
-- Q12. Quarter-wise revenue for 2023
-- Concept: CASE WHEN for quarter bucketing + date filter

SELECT 
    YEAR(o.order_date) AS yr,
    CASE 
        WHEN MONTH(o.order_date) IN (1,2,3)  THEN 'Q1'
        WHEN MONTH(o.order_date) IN (4,5,6)  THEN 'Q2'
        WHEN MONTH(o.order_date) IN (7,8,9)  THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered' AND YEAR(o.order_date) = 2023
GROUP BY yr, quarter
ORDER BY quarter;

/*
Result:
2023 Q1 | 6,389,074.60
2023 Q2 | 5,896,109.40
2023 Q3 | 7,243,681.20
2023 Q4 | 5,423,886.85

Insight: Q3 2023 was the strongest quarter — possibly 
festive season (Aug-Sep in India: Independence Day, 
Ganesh Chaturthi, early Diwali sales)
*/


