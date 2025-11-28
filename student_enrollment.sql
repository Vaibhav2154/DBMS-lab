/* ---------------------------------------------------------
   STUDENT ENROLLMENT DATABASE - FULL SCRIPT
--------------------------------------------------------- */

DROP DATABASE IF EXISTS student_enrollment;
CREATE DATABASE student_enrollment;
USE student_enrollment;

/* ---------------------------------------------------------
   1. TABLE CREATION
--------------------------------------------------------- */

CREATE TABLE student (
    regno VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    major VARCHAR(50),
    bdate DATE
);

CREATE TABLE course (
    course_no INT PRIMARY KEY,
    cname VARCHAR(100),
    dept VARCHAR(50)
);

CREATE TABLE enroll (
    regno VARCHAR(20),
    course_no INT,
    sem INT,
    marks INT,
    PRIMARY KEY (regno, course_no, sem),

    FOREIGN KEY (regno) REFERENCES student(regno) ON DELETE CASCADE,
    FOREIGN KEY (course_no) REFERENCES course(course_no) ON DELETE CASCADE
);

CREATE TABLE text (
    book_isbn INT PRIMARY KEY,
    book_title VARCHAR(200),
    publisher VARCHAR(100),
    author VARCHAR(100)
);

CREATE TABLE book_adoption (
    course_no INT,
    sem INT,
    book_isbn INT,

    PRIMARY KEY (course_no, sem, book_isbn),

    FOREIGN KEY (course_no) REFERENCES course(course_no) ON DELETE CASCADE,
    FOREIGN KEY (book_isbn) REFERENCES text(book_isbn) ON DELETE CASCADE
);

/* ---------------------------------------------------------
   2. INSERTING SAMPLE DATA (5 TUPLES EACH)
--------------------------------------------------------- */

INSERT INTO student VALUES
('S101', 'Alice', 'CSE', '2003-04-11'),
('S102', 'Bob', 'ECE', '2002-09-19'),
('S103', 'Charlie', 'ME', '2003-12-05'),
('S104', 'David', 'CSE', '2002-02-28'),
('S105', 'Eva', 'ISE', '2003-07-21');

INSERT INTO course VALUES
(101, 'DBMS', 'CSE'),
(102, 'Operating Systems', 'CSE'),
(103, 'Data Structures', 'CSE'),
(201, 'Signals & Systems', 'ECE'),
(202, 'Digital Logic', 'ECE');

INSERT INTO enroll VALUES
('S101', 101, 3, 85),
('S102', 103, 4, 77),
('S103', 201, 3, 65),
('S104', 101, 3, 90),
('S105', 202, 2, 88);

INSERT INTO text VALUES
(1111, 'Database System Concepts', 'McGraw Hill', 'Silberschatz'),
(2222, 'Operating System Concepts', 'Wiley', 'Silberschatz'),
(3333, 'Data Structures in C', 'Pearson', 'Reema Thareja'),
(4444, 'Signals and Systems', 'TMH', 'Oppenheim'),
(5555, 'Digital Logic Design', 'Pearson', 'Morris Mano');

INSERT INTO book_adoption VALUES
(101, 3, 1111),
(102, 4, 2222),
(103, 4, 3333),
(201, 3, 4444),
(202, 2, 5555);

/* ---------------------------------------------------------
   3. ALTER TABLE – ADD & DROP COLUMN
--------------------------------------------------------- */

ALTER TABLE student ADD phone VARCHAR(15);

ALTER TABLE student DROP COLUMN phone;

/* ---------------------------------------------------------
   4. ADD & DROP CONSTRAINTS
--------------------------------------------------------- */

ALTER TABLE enroll
ADD CONSTRAINT chk_marks CHECK (marks >= 0 AND marks <= 100);

ALTER TABLE enroll
DROP CONSTRAINT chk_marks;

/* ---------------------------------------------------------
   5. UPDATE & DELETE OPERATIONS
--------------------------------------------------------- */

UPDATE enroll
SET marks = 95
WHERE regno = 'S101' AND course_no = 101;

DELETE FROM enroll
WHERE regno = 'S103' AND course_no = 201;

/* ---------------------------------------------------------
   6. CREATE VIEW
--------------------------------------------------------- */

CREATE VIEW StudentCourseView AS
SELECT s.regno, s.name, c.cname, e.sem, e.marks
FROM student s
JOIN enroll e ON s.regno = e.regno
JOIN course c ON e.course_no = c.course_no;

SELECT * FROM StudentCourseView;

/* ---------------------------------------------------------
   7. TRIGGER – LIMIT ENROLLMENT
--------------------------------------------------------- */

DELIMITER //

CREATE TRIGGER LimitCourseEnrollment
BEFORE INSERT ON enroll
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*)
        FROM enroll
        WHERE regno = NEW.regno AND sem = NEW.sem) >= 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student cannot enroll in more than 5 courses per semester';
    END IF;
END//

DELIMITER ;

/* ---------------------------------------------------------
   TEST TRIGGER (WILL THROW ERROR IF MORE THAN 5)
--------------------------------------------------------- */
/*
INSERT INTO enroll VALUES ('S101', 102, 3, 80);
INSERT INTO enroll VALUES ('S101', 103, 3, 75);
INSERT INTO enroll VALUES ('S101', 201, 3, 70);
INSERT INTO enroll VALUES ('S101', 202, 3, 88);
INSERT INTO enroll VALUES ('S101', 203, 3, 90);  <-- 5th
INSERT INTO enroll VALUES ('S101', 204, 3, 92);  <-- ERROR on 6th
*/

