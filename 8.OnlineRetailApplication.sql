USE OnlineRetailApplication;

------------------------------------------------------------
-- ✅ FUNCTIONS
------------------------------------------------------------

-- 1️⃣ Get Full Customer Name
DELIMITER //
CREATE FUNCTION fn_customer_fullname(custId INT)
RETURNS VARCHAR(150)
DETERMINISTIC
BEGIN
    DECLARE fullName VARCHAR(150);
    SELECT CONCAT(first_name, ' ', last_name) INTO fullName
    FROM customers
    WHERE customer_id = custId;
    RETURN fullName;
END //
DELIMITER ;

-- 2️⃣ Get Product Stock
DELIMITER //
CREATE FUNCTION fn_product_stock(prodId INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE qty INT;
    SELECT stock_quantity INTO qty
    FROM products
    WHERE product_id = prodId;
    RETURN IFNULL(qty, 0);
END //
DELIMITER ;

-- 3️⃣ Check Order Exists
DELIMITER //
CREATE FUNCTION fn_order_exists(oId INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE cnt INT;
    SELECT COUNT(*) INTO cnt
    FROM orders
    WHERE order_id = oId;
    RETURN cnt > 0;
END //
DELIMITER ;

-- 4️⃣ Count Reviews for a Product
DELIMITER //
CREATE FUNCTION fn_review_count(prodId INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total
    FROM reviews
    WHERE product_id = prodId;
    RETURN IFNULL(total, 0);
END //
DELIMITER ;

-- 5️⃣ Get Customer Total Orders
DELIMITER //
CREATE FUNCTION fn_customer_orders(custId INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total
    FROM orders
    WHERE customer_id = custId;
    RETURN IFNULL(total, 0);
END //
DELIMITER ;

-- 6️⃣ Calculate Total Order Quantity
DELIMITER //
CREATE FUNCTION fn_order_quantity(oId INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE qty INT;
    SELECT SUM(quantity) INTO qty
    FROM order_items
    WHERE order_id = oId;
    RETURN IFNULL(qty, 0);
END //
DELIMITER ;

-- 7️⃣ Get Customer Lifetime Spending
DELIMITER //
CREATE FUNCTION fn_customer_spending(custId INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE spend DECIMAL(12,2);
    SELECT SUM(amount) INTO spend
    FROM payments p
    JOIN orders o ON p.order_id = o.order_id
    WHERE o.customer_id = custId
      AND p.status = 'Completed';
    RETURN IFNULL(spend, 0.00);
END //
DELIMITER ;

-- 8️⃣ Calculate Order Total from Items Table
DELIMITER //
CREATE FUNCTION fn_order_total(oId INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(12,2);
    SELECT SUM(quantity * unit_price) INTO total
    FROM order_items
    WHERE order_id = oId;
    RETURN IFNULL(total, 0.00);
END //
DELIMITER ;

-- 9️⃣ Category Revenue Function
DELIMITER //
CREATE FUNCTION fn_category_revenue(catId INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE revenue DECIMAL(12,2);
    SELECT SUM(oi.quantity * oi.unit_price) INTO revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.category_id = catId;
    RETURN IFNULL(revenue, 0.00);
END //
DELIMITER ;



------------------------------------------------------------
-- ✅ STORED PROCEDURES
------------------------------------------------------------

-- 1️⃣ Show All Products
DELIMITER //
CREATE PROCEDURE sp_all_products()
BEGIN
    SELECT product_id, product_name, price, stock_quantity
    FROM products;
END //
DELIMITER ;

-- 2️⃣ Get Customer Details
DELIMITER //
CREATE PROCEDURE sp_customer_details(IN custId INT)
BEGIN
    SELECT *
    FROM customers
    WHERE customer_id = custId;
END //
DELIMITER ;

-- 3️⃣ List Orders by Status
DELIMITER //
CREATE PROCEDURE sp_orders_by_status(IN statusVal VARCHAR(20))
BEGIN
    SELECT *
    FROM orders
    WHERE status = statusVal;
END //
DELIMITER ;

-- 4️⃣ Reduce Product Stock After Purchase
DELIMITER //
CREATE PROCEDURE sp_update_stock(IN prodId INT, IN qty INT)
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity - qty
    WHERE product_id = prodId;
END //
DELIMITER ;

-- 6️⃣ Get Latest Customer Orders
DELIMITER //
CREATE PROCEDURE sp_latest_orders(IN custId INT, IN limitCount INT)
BEGIN
    SELECT order_id, order_date, total_amount, status
    FROM orders
    WHERE customer_id = custId
    ORDER BY order_date DESC
    LIMIT limitCount;
END //
DELIMITER ;

-- 7️⃣ Insert Review with Validation
DELIMITER //
CREATE PROCEDURE sp_add_review(
    IN custId INT,
    IN prodId INT,
    IN rate INT,
    IN reviewTxt TEXT
)
BEGIN
    IF rate NOT BETWEEN 1 AND 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;

    INSERT INTO reviews(customer_id, product_id, rating, comment)
    VALUES (custId, prodId, rate, reviewTxt);
END //
DELIMITER ;

-- 8️⃣ Customer Purchase Summary Report
DELIMITER //
CREATE PROCEDURE sp_customer_summary(IN custId INT)
BEGIN
    SELECT c.first_name, c.last_name,
           COUNT(DISTINCT o.order_id) AS total_orders,
           SUM(oi.quantity) AS total_items,
           SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE c.customer_id = custId
    GROUP BY c.customer_id;
END //
DELIMITER ;

-- 9️⃣ Top Selling Products Report
DELIMITER //
CREATE PROCEDURE sp_top_products(IN limitCount INT)
BEGIN
    SELECT p.product_name,
           SUM(oi.quantity) AS units_sold
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
    ORDER BY units_sold DESC
    LIMIT limitCount;
END //
DELIMITER ;

-- calling functions
SELECT fn_customer_fullname(1);
SELECT fn_product_stock(5);
SELECT fn_order_exists(10);

SELECT fn_review_count(3);
SELECT fn_customer_orders(1);
SELECT fn_order_quantity(7);

SELECT fn_customer_spending(1);
SELECT fn_order_total(8);
SELECT fn_category_revenue(2);

-- calling procedures
CALL sp_all_products();
CALL sp_customer_details(1);
CALL sp_orders_by_status('Pending');

CALL sp_update_stock(4, 2);
CALL sp_latest_orders(1, 5);

CALL sp_add_review(1, 3, 5, 'Excellent quality product!');
CALL sp_customer_summary(1);
CALL sp_top_products(10);
