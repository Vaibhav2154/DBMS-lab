DROP DATABASE IF EXISTS company;
CREATE DATABASE company;
USE company;

CREATE TABLE IF NOT EXISTS Employee (
    ssn VARCHAR(35) PRIMARY KEY,
    name VARCHAR(35) NOT NULL,
    address VARCHAR(255) NOT NULL,
    sex VARCHAR(7) NOT NULL,
    salary INT NOT NULL,
    super_ssn VARCHAR(35),
    d_no INT,
    FOREIGN KEY (super_ssn) REFERENCES Employee(ssn) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS Department (
    d_no INT PRIMARY KEY,
    dname VARCHAR(100) NOT NULL,
    mgr_ssn VARCHAR(35),
    mgr_start_date DATE,
    FOREIGN KEY (mgr_ssn) REFERENCES Employee(ssn) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS DLocation (
    d_no INT NOT NULL,
    d_loc VARCHAR(100) NOT NULL,
    FOREIGN KEY (d_no) REFERENCES Department(d_no) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Project (
    p_no INT PRIMARY KEY,
    p_name VARCHAR(25) NOT NULL,
    p_loc VARCHAR(25) NOT NULL,
    d_no INT NOT NULL,
    FOREIGN KEY (d_no) REFERENCES Department(d_no) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS WorksOn (
    ssn VARCHAR(35) NOT NULL,
    p_no INT NOT NULL,
    hours INT NOT NULL DEFAULT 0,
    FOREIGN KEY (ssn) REFERENCES Employee(ssn) ON DELETE CASCADE,
    FOREIGN KEY (p_no) REFERENCES Project(p_no) ON DELETE CASCADE
);

INSERT INTO Employee VALUES
("01NB235", "Chandan_Krishna", "Siddartha Nagar, Mysuru", "Male", 1500000, "01NB235", 5),
("01NB354", "Employee_2", "Lakshmipuram, Mysuru", "Female", 1200000, "01NB235", 2),
("02NB254", "Employee_3", "Pune, Maharashtra", "Male", 1000000, "01NB235", 4),
("03NB653", "Employee_4", "Hyderabad, Telangana", "Male", 2500000, "01NB354", 5),
("04NB234", "Employee_5", "JP Nagar, Bengaluru", "Female", 1700000, "01NB354", 1);

INSERT INTO Department VALUES
(1, "Human Resources", "01NB235", "2020-10-21"),
(2, "Quality Assesment", "03NB653", "2020-10-19"),
(3, "System assesment", "04NB234", "2020-10-27"),
(4, "Accounts", "01NB354", "2020-09-04"),
(5, "Production", "02NB254", "2020-08-16");

INSERT INTO DLocation VALUES
(1, "Jaynagar, Bengaluru"),
(2, "Vijaynagar, Mysuru"),
(3, "Chennai, Tamil Nadu"),
(4, "Mumbai, Maharashtra"),
(5, "Kuvempunagar, Mysuru");

INSERT INTO Project VALUES
(241563, "System Testing", "Mumbai, Maharashtra", 4),
(532678, "IOT", "JP Nagar, Bengaluru", 1),
(453723, "Product Optimization", "Hyderabad, Telangana", 5),
(278345, "Yeild Increase", "Kuvempunagar, Mysuru", 5),
(426784, "Product Refinement", "Saraswatipuram, Mysuru", 2);

INSERT INTO WorksOn VALUES
("01NB235", 278345, 5),
("01NB354", 426784, 6),
("04NB234", 532678, 3),
("02NB254", 241563, 3),
("03NB653", 453723, 6);

-- Projects involving an employee with last name 'Krishna'
SELECT p.p_no, p.p_name, e.name
FROM Project p
JOIN Employee e ON p.d_no = e.d_no
WHERE e.name LIKE "%Krishna%";

-- Salary hike for employees working on IoT project
-- SELECT w.ssn, e.name, e.salary AS old_salary, e.salary * 1.1 AS new_salary
-- FROM WorksOn w
-- JOIN Employee e ON w.ssn = e.ssn
-- WHERE w.p_no = (
--     SELECT p_no FROM Project WHERE p_name = "IOT"
-- );
-- Simplified by joining to Project by name
SELECT w.ssn, e.name, e.salary AS old_salary, e.salary * 1.1 AS new_salary
FROM WorksOn AS w
JOIN Employee AS e ON w.ssn = e.ssn
JOIN Project AS p ON p.p_no = w.p_no
WHERE p.p_name = 'IOT';

-- Salary statistics for Accounts department
SELECT
    SUM(e.salary) AS sal_sum,
    MAX(e.salary) AS sal_max,
    MIN(e.salary) AS sal_min,
    AVG(e.salary) AS sal_avg
FROM Employee e
JOIN Department d ON e.d_no = d.d_no
WHERE d.dname = "Accounts";

-- Employees who work on all projects of department 1
-- SELECT e.ssn, e.name, e.d_no
-- FROM Employee e
-- WHERE NOT EXISTS (
--     SELECT p.p_no
--     FROM Project p
--     WHERE p.d_no = 1
--       AND p.p_no NOT IN (
--           SELECT w.p_no
--           FROM WorksOn w
--           WHERE w.ssn = e.ssn
--       )
-- );
-- Simplified using GROUP BY/HAVING to perform division
SELECT e.ssn, e.name, e.d_no
FROM Employee AS e
JOIN WorksOn AS w ON w.ssn = e.ssn
JOIN Project AS p ON p.p_no = w.p_no AND p.d_no = 1
GROUP BY e.ssn, e.name, e.d_no
HAVING COUNT(DISTINCT p.p_no) = (
    SELECT COUNT(*) FROM Project p2 WHERE p2.d_no = 1
);

-- Departments with more than one employee earning above 6,00,000
SELECT d.d_no, COUNT(*) AS emp_count
FROM Department d
JOIN Employee e ON e.d_no = d.d_no
WHERE e.salary > 600000
GROUP BY d.d_no
HAVING COUNT(*) > 1;

-- View for employee details
-- CREATE VIEW emp_details AS
-- SELECT e.name, d.dname, dl.d_loc
-- FROM Employee e
-- JOIN Department d ON e.d_no = d.d_no
-- JOIN DLocation dl ON d.d_no = dl.d_no;
CREATE OR REPLACE VIEW emp_details AS
SELECT e.name, d.dname, dl.d_loc
FROM Employee AS e
JOIN Department AS d ON e.d_no = d.d_no
JOIN DLocation AS dl ON d.d_no = dl.d_no;

-- Trigger to prevent deletion of projects with assigned employees
DELIMITER //
CREATE TRIGGER PreventDelete
BEFORE DELETE ON Project
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM WorksOn WHERE p_no = OLD.p_no) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This project has an employee assigned';
    END IF;
END;
//
DELIMITER ;
