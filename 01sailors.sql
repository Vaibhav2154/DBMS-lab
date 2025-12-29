DROP DATABASE IF EXISTS sailors;
CREATE DATABASE sailors;
USE sailors;

CREATE TABLE IF NOT EXISTS Sailors (
    sid INT PRIMARY KEY,
    sname VARCHAR(35) NOT NULL,
    rating FLOAT NOT NULL,
    age INT NOT NULL
);

CREATE TABLE IF NOT EXISTS Boat (
    bid INT PRIMARY KEY,
    bname VARCHAR(35) NOT NULL,
    color VARCHAR(25) NOT NULL
);

CREATE TABLE IF NOT EXISTS reserves (
    sid INT NOT NULL,
    bid INT NOT NULL,
    sdate DATE NOT NULL,
    FOREIGN KEY (sid) REFERENCES Sailors(sid) ON DELETE CASCADE,
    FOREIGN KEY (bid) REFERENCES Boat(bid) ON DELETE CASCADE
);

INSERT INTO Sailors VALUES
(1, "Albert", 5.0, 40),
(2, "Nakul", 5.0, 49),
(3, "Darshan", 9, 18),
(4, "Astorm Gowda", 2, 68),
(5, "Armstormin", 7, 19);

INSERT INTO Boat VALUES
(1, "Boat_1", "Green"),
(2, "Boat_2", "Red"),
(103, "Boat_3", "Blue"),
(104, "Boat_4", "Pink");

INSERT INTO reserves VALUES
(1, 103, "2023-01-01"),
(1, 2, "2023-02-01"),
(2, 1, "2023-02-05"),
(3, 2, "2023-03-06"),
(5, 103, "2023-03-06"),
(1, 1, "2023-03-06"),
(1, 104, "2023-12-12");

-- Find the colours of the boats reserved by Albert
SELECT b.color
FROM Sailors s, Boat b, reserves r
WHERE s.sid = r.sid
  AND b.bid = r.bid
  AND s.sname = "Albert";

-- Find all the sailor sids who have rating at least 8 or reserved boat 103
(SELECT sid
 FROM Sailors
 WHERE rating >= 8)
UNION
(SELECT sid
 FROM reserves
 WHERE bid = 103);

-- Find the names of the sailors who have not reserved a boat whose name contains "storm"
-- Order the name in ascending order
SELECT s.sname
FROM Sailors s
WHERE s.sid NOT IN (
    SELECT s1.sid
    FROM Sailors s1, reserves r1
    WHERE r1.sid = s1.sid
      AND s1.sname LIKE "%storm%"
)
AND s.sname LIKE "%storm%"
ORDER BY s.sname ASC;

-- Find the name of the sailors who have reserved all boats
SELECT s.sname
FROM Sailors s
WHERE NOT EXISTS (
    SELECT *
    FROM Boat b
    WHERE NOT EXISTS (
        SELECT *
        FROM reserves r
        WHERE r.sid = s.sid
          AND r.bid = b.bid
    )
);

-- Find the name and age of the oldest sailor
SELECT sname, age
FROM Sailors
WHERE age = (SELECT MAX(age) FROM Sailors);

-- For each boat reserved by at least 2 sailors with age >= 40,
-- find the bid and average age of such sailors
SELECT b.bid, AVG(s.age) AS average_age
FROM Sailors s, Boat b, reserves r
WHERE r.sid = s.sid
  AND r.bid = b.bid
  AND s.age >= 40
GROUP BY b.bid
HAVING COUNT(DISTINCT r.sid) >= 2;

-- Create a view showing names and colours of boats reserved by sailors with rating = 5
CREATE VIEW ReservedBoatsWithRatedSailor AS
SELECT DISTINCT b.bname, b.color
FROM Sailors s, Boat b, reserves r
WHERE s.sid = r.sid
  AND b.bid = r.bid
  AND s.rating = 5;

-- Trigger to prevent deletion of boats with active reservations
DELIMITER //
CREATE OR REPLACE TRIGGER CheckAndDelete
BEFORE DELETE ON Boat
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM reserves WHERE bid = OLD.bid) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Boat is reserved and hence cannot be deleted';
    END IF;
END;
//
DELIMITER ;

-- Example delete (will fail if boat is reserved)
DELETE FROM Boat WHERE bid = 103;
