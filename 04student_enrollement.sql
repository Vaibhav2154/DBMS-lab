DROP DATABASE IF EXISTS enrollment;
CREATE DATABASE enrollment;
USE enrollment;

CREATE TABLE Student (
    regno VARCHAR(13) PRIMARY KEY,
    name VARCHAR(25) NOT NULL,
    major VARCHAR(25) NOT NULL,
    bdate DATE NOT NULL
);

CREATE TABLE Course (
    course INT PRIMARY KEY,
    cname VARCHAR(30) NOT NULL,
    dept VARCHAR(100) NOT NULL
);

CREATE TABLE Enroll (
    regno VARCHAR(13),
    course INT,
    sem INT NOT NULL,
    marks INT NOT NULL,
    FOREIGN KEY (regno) REFERENCES Student(regno) ON DELETE CASCADE,
    FOREIGN KEY (course) REFERENCES Course(course) ON DELETE CASCADE
);

CREATE TABLE TextBook (
    bookIsbn INT PRIMARY KEY,
    book_title VARCHAR(40) NOT NULL,
    publisher VARCHAR(25) NOT NULL,
    author VARCHAR(25) NOT NULL
);

CREATE TABLE BookAdoption (
    course INT NOT NULL,
    sem INT NOT NULL,
    bookIsbn INT NOT NULL,
    FOREIGN KEY (bookIsbn) REFERENCES TextBook(bookIsbn) ON DELETE CASCADE,
    FOREIGN KEY (course) REFERENCES Course(course) ON DELETE CASCADE
);

INSERT INTO Student VALUES
("01HF235", "Student_1", "CSE", "2001-05-15"),
("01HF354", "Student_2", "Literature", "2002-06-10"),
("01HF254", "Student_3", "Philosophy", "2000-04-04"),
("01HF653", "Student_4", "History", "2003-10-12"),
("01HF234", "Student_5", "Computer Economics", "2001-10-10");

INSERT INTO Course VALUES
(1, "DBMS", "CS"),
(2, "Literature", "English"),
(3, "Philosophy", "Philosphy"),
(4, "History", "Social Science"),
(5, "Computer Economics", "CS");

INSERT INTO Enroll VALUES
("01HF235", 1, 5, 85),
("01HF354", 2, 6, 87),
("01HF254", 3, 3, 95),
("01HF653", 4, 3, 80),
("01HF234", 5, 5, 75);

INSERT INTO TextBook VALUES
(241563, "Operating Systems", "Pearson", "Silberschatz"),
(532678, "Complete Works of Shakesphere", "Oxford", "Shakesphere"),
(453723, "Immanuel Kant", "Delphi Classics", "Immanuel Kant"),
(278345, "History of the world", "The Times", "Richard Overy"),
(426784, "Behavioural Economics", "Pearson", "David Orrel");

INSERT INTO BookAdoption VALUES
(1, 5, 241563),
(2, 6, 532678),
(3, 3, 453723),
(4, 3, 278345),
(1, 6, 426784);

-- Add a new textbook and adopt it
INSERT INTO TextBook VALUES
(123456, "Chandan The Autobiography", "Pearson", "Chandan");

INSERT INTO BookAdoption VALUES
(1, 5, 123456);

-- Textbooks (Course#, ISBN, Title) for CS courses using more than two books
SELECT c.course, t.bookIsbn, t.book_title
FROM Course c
JOIN BookAdoption ba ON c.course = ba.course
JOIN TextBook t ON ba.bookIsbn = t.bookIsbn
WHERE c.dept = 'CS'
AND (
    SELECT COUNT(*)
    FROM BookAdoption b
    WHERE b.course = c.course
) > 2
ORDER BY t.book_title;

-- Departments where all adopted books are from a specific publisher (PEARSON)
SELECT DISTINCT c.dept
FROM Course c
WHERE c.dept IN (
    SELECT c1.dept
    FROM Course c1
    JOIN BookAdoption b1 ON c1.course = b1.course
    JOIN TextBook t1 ON t1.bookIsbn = b1.bookIsbn
    WHERE t1.publisher = 'Pearson'
)
AND c.dept NOT IN (
    SELECT c2.dept
    FROM Course c2
    JOIN BookAdoption b2 ON c2.course = b2.course
    JOIN TextBook t2 ON t2.bookIsbn = b2.bookIsbn
    WHERE t2.publisher <> 'Pearson'
);

-- Students with maximum marks in DBMS
SELECT s.name
FROM Student s
JOIN Enroll e ON s.regno = e.regno
JOIN Course c ON e.course = c.course
WHERE c.cname = 'DBMS'
AND e.marks = (
    SELECT MAX(e1.marks)
    FROM Enroll e1
    JOIN Course c1 ON e1.course = c1.course
    WHERE c1.cname = 'DBMS'
);

-- View showing courses opted by a student along with marks
CREATE VIEW CoursesOptedByStudent AS
SELECT c.cname, e.marks
FROM Course c
JOIN Enroll e ON c.course = e.course
WHERE e.regno = '01HF235';

-- Trigger to prevent enrollment if marks are below threshold
DELIMITER //
CREATE OR REPLACE TRIGGER PreventEnrollment
BEFORE INSERT ON Enroll
FOR EACH ROW
BEGIN
    IF NEW.marks < 40 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Marks below threshold';
    END IF;
END;
//
DELIMITER ;
