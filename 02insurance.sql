DROP DATABASE IF EXISTS insurance;
CREATE DATABASE insurance;
USE insurance;

CREATE TABLE IF NOT EXISTS person (
    driver_id VARCHAR(255) NOT NULL,
    driver_name TEXT NOT NULL,
    address TEXT NOT NULL,
    PRIMARY KEY (driver_id)
);

CREATE TABLE IF NOT EXISTS car (
    reg_no VARCHAR(255) NOT NULL,
    model TEXT NOT NULL,
    c_year INTEGER,
    PRIMARY KEY (reg_no)
);

CREATE TABLE IF NOT EXISTS accident (
    report_no INTEGER NOT NULL,
    accident_date DATE,
    location TEXT,
    PRIMARY KEY (report_no)
);

CREATE TABLE IF NOT EXISTS owns (
    driver_id VARCHAR(255) NOT NULL,
    reg_no VARCHAR(255) NOT NULL,
    FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON DELETE CASCADE,
    FOREIGN KEY (reg_no) REFERENCES car(reg_no) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS participated (
    driver_id VARCHAR(255) NOT NULL,
    reg_no VARCHAR(255) NOT NULL,
    report_no INTEGER NOT NULL,
    damage_amount FLOAT NOT NULL,
    FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON DELETE CASCADE,
    FOREIGN KEY (reg_no) REFERENCES car(reg_no) ON DELETE CASCADE,
    FOREIGN KEY (report_no) REFERENCES accident(report_no)
);

INSERT INTO person VALUES
("D111", "Driver_1", "Kuvempunagar, Mysuru"),
("D222", "Smith", "JP Nagar, Mysuru"),
("D333", "Driver_3", "Udaygiri, Mysuru"),
("D444", "Driver_4", "Rajivnagar, Mysuru"),
("D555", "Driver_5", "Vijayanagar, Mysore");

INSERT INTO car VALUES
("KA-20-AB-4223", "Swift", 2020),
("KA-20-BC-5674", "Mazda", 2017),
("KA-21-AC-5473", "Alto", 2015),
("KA-21-BD-4728", "Triber", 2019),
("KA-09-MA-1234", "Tiago", 2018);

INSERT INTO accident VALUES
(43627, "2020-04-05", "Nazarbad, Mysuru"),
(56345, "2019-12-16", "Gokulam, Mysuru"),
(63744, "2020-05-14", "Vijaynagar, Mysuru"),
(54634, "2019-08-30", "Kuvempunagar, Mysuru"),
(65738, "2021-01-21", "JSS Layout, Mysuru"),
(66666, "2021-01-21", "JSS Layout, Mysuru");

INSERT INTO owns VALUES
("D111", "KA-20-AB-4223"),
("D222", "KA-20-BC-5674"),
("D333", "KA-21-AC-5473"),
("D444", "KA-21-BD-4728"),
("D222", "KA-09-MA-1234");

INSERT INTO participated VALUES
("D111", "KA-20-AB-4223", 43627, 20000),
("D222", "KA-20-BC-5674", 56345, 49500),
("D333", "KA-21-AC-5473", 63744, 15000),
("D444", "KA-21-BD-4728", 54634, 5000),
("D222", "KA-09-MA-1234", 65738, 25000);

-- Total number of people who owned a car involved in accidents in 2021
-- SELECT COUNT(DISTINCT p.driver_id)
-- FROM participated p
-- JOIN accident a ON p.report_no = a.report_no
-- WHERE a.accident_date LIKE '2021%';
-- Simplified to use YEAR() instead of string LIKE on date
SELECT COUNT(DISTINCT pt.driver_id)
FROM participated pt
JOIN accident a ON pt.report_no = a.report_no
WHERE YEAR(a.accident_date) = 2021;

-- Number of accidents involving cars belonging to Smith
-- SELECT COUNT(DISTINCT a.report_no)
-- FROM accident a
-- WHERE EXISTS (
--     SELECT 1
--     FROM person p
--     JOIN participated pt ON p.driver_id = pt.driver_id
--     WHERE p.driver_name = "Smith"
--       AND pt.report_no = a.report_no
-- );
-- Simplified by replacing EXISTS with direct joins
-- SELECT COUNT(DISTINCT a.report_no)
-- FROM accident a
-- JOIN participated pt ON pt.report_no = a.report_no
-- JOIN person p ON p.driver_id = pt.driver_id
-- WHERE p.driver_name = 'Smith';

SELECT COUNT(DISTINCT pt.report_no)
FROM participated pt
JOIN person p ON p.driver_id = pt.driver_id
WHERE p.driver_name = 'Smith';

-- Add a new accident
INSERT INTO accident VALUES
(45562, "2024-04-05", "Mandya");

INSERT INTO participated VALUES
("D222", "KA-21-BD-4728", 45562, 50000);

-- Delete the Mazda belonging to Smith
-- DELETE FROM car
-- WHERE model = "Mazda"
-- AND reg_no IN (
--     SELECT o.reg_no
--     FROM person p
--     JOIN owns o ON p.driver_id = o.driver_id
--     WHERE p.driver_name = "Smith"
-- );
-- Simplified using multi-table DELETE with joins
DELETE c
FROM car AS c
JOIN owns AS o ON o.reg_no = c.reg_no
JOIN person AS p ON p.driver_id = o.driver_id
WHERE p.driver_name = 'Smith'
    AND c.model = 'Mazda';

-- Update damage amount
UPDATE participated
SET damage_amount = 10000
WHERE report_no = 65738
  AND reg_no = "KA-09-MA-1234";

-- View showing models and years of cars involved in accidents
-- CREATE VIEW CarsInAccident AS
-- SELECT DISTINCT c.model, c.c_year
-- FROM car c
-- JOIN participated p ON c.reg_no = p.reg_no;
-- Use OR REPLACE so script is idempotent
CREATE OR REPLACE VIEW CarsInAccident AS
SELECT DISTINCT c.model, c.c_year
FROM car AS c
JOIN participated AS pt ON c.reg_no = pt.reg_no;

-- Trigger preventing a driver from participating in more than 2 accidents
DELIMITER //
CREATE TRIGGER PreventParticipation
BEFORE INSERT ON participated
FOR EACH ROW
BEGIN
    IF (
        SELECT COUNT(*)
        FROM participated
        WHERE driver_id = NEW.driver_id
    ) >= 2 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Driver has already participated in 2 accidents';
    END IF;
END;
//
DELIMITER ;
