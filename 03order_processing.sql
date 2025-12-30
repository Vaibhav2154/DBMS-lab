DROP DATABASE IF EXISTS order_processing;
CREATE DATABASE order_processing;
USE order_processing;

CREATE TABLE IF NOT EXISTS Customers (
    cust_id INT PRIMARY KEY,
    cname VARCHAR(35) NOT NULL,
    city VARCHAR(35) NOT NULL
);

CREATE TABLE IF NOT EXISTS Orders (
    order_id INT PRIMARY KEY,
    odate DATE NOT NULL,
    cust_id INT,
    order_amt INT NOT NULL,
    FOREIGN KEY (cust_id) REFERENCES Customers(cust_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Items (
    item_id INT PRIMARY KEY,
    unitprice INT NOT NULL
);

CREATE TABLE IF NOT EXISTS OrderItems (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    qty INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES Items(item_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Warehouses (
    warehouse_id INT PRIMARY KEY,
    city VARCHAR(35) NOT NULL
);

CREATE TABLE IF NOT EXISTS Shipments (
    order_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    ship_date DATE NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id) ON DELETE CASCADE
);

INSERT INTO Customers VALUES
(1, "Customer_1", "Mysuru"),
(2, "Customer_2", "Bengaluru"),
(3, "Kumar", "Mumbai"),
(4, "Customer_4", "Dehli"),
(5, "Customer_5", "Bengaluru");

INSERT INTO Orders VALUES
(1, "2020-01-14", 1, 2000),
(2, "2021-04-13", 2, 500),
(3, "2019-10-02", 3, 2500),
(4, "2019-05-12", 5, 1000),
(5, "2020-12-23", 4, 1200);

INSERT INTO Items VALUES
(1, 400),
(2, 200),
(3, 1000),
(4, 100),
(5, 500);

INSERT INTO Warehouses VALUES
(1, "Mysuru"),
(2, "Bengaluru"),
(3, "Mumbai"),
(4, "Dehli"),
(5, "Chennai");

INSERT INTO OrderItems VALUES
(1, 1, 5),
(2, 5, 1),
(3, 5, 5),
(4, 3, 1),
(5, 4, 12);

INSERT INTO Shipments VALUES
(1, 2, "2020-01-16"),
(2, 1, "2021-04-14"),
(3, 4, "2019-10-07"),
(4, 3, "2019-05-16"),
(5, 5, "2020-12-23");

-- Orders shipped from warehouse 0001
SELECT order_id, ship_date
FROM Shipments
WHERE warehouse_id = 1;

-- Warehouses supplying orders of customer "Kumar"
-- SELECT s.order_id, s.warehouse_id
-- FROM Shipments s
-- WHERE s.order_id IN (
--     SELECT o.order_id
--     FROM Orders o
--     WHERE o.cust_id = (
--         SELECT c.cust_id
--         FROM Customers c
--         WHERE c.cname = "Kumar"
--     )
-- );
-- Simplified via joins
SELECT s.order_id, s.warehouse_id
FROM Shipments AS s
JOIN Orders AS o ON o.order_id = s.order_id
JOIN Customers AS c ON c.cust_id = o.cust_id
WHERE c.cname = 'Kumar';

-- Customer order statistics
SELECT c.cname,
       COUNT(o.order_id) AS no_of_orders,
       AVG(o.order_amt) AS avg_order_amt
FROM Customers c
JOIN Orders o ON c.cust_id = o.cust_id
GROUP BY c.cname;

-- Delete all orders for customer "Kumar"
-- DELETE FROM Orders
-- WHERE cust_id = (
--     SELECT cust_id
--     FROM Customers
--     WHERE cname = "Kumar"
-- );
-- Simplified using join-delete
DELETE o
FROM Orders AS o
JOIN Customers AS c ON c.cust_id = o.cust_id
WHERE c.cname = 'Kumar';

-- Item with maximum unit price
SELECT MAX(unitprice)
FROM Items;

-- Trigger to update order amount after inserting order items
DELIMITER $$
CREATE TRIGGER UpdateOrderAmt
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET order_amt = NEW.qty * (
        SELECT unitprice
        FROM Items
        WHERE item_id = NEW.item_id
    )
    WHERE order_id = NEW.order_id;
END$$
DELIMITER ;

INSERT INTO Orders VALUES
(6, "2020-12-23", 4, 1200);

INSERT INTO OrderItems VALUES
(6, 1, 5);

-- View for shipments from warehouse 5
-- CREATE VIEW ShipmentDatesFromWarehouse5 AS
-- SELECT order_id, ship_date
-- FROM Shipments
-- WHERE warehouse_id = 5;
CREATE OR REPLACE VIEW ShipmentDatesFromWarehouse5 AS
SELECT order_id, ship_date
FROM Shipments
WHERE warehouse_id = 5;
