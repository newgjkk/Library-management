---------- CREATING NEW BOOK RECORD ---------
INSERT INTO books
(isbn,book_title,category,rental_price,status,author,publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

--------- UPDATING EXISTING MEMBER's ADDRESS -------
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C101';

--------- DELETING RECORD OF ISSUED STATUS TABLE -------
DELETE FROM issued_status
WHERE issued_id = 'IS121';

--------- RETRIVE ALL BOOKS ISSUSED BY emp_id E101 ------
SELECT * 
FROM issued_status
WHERE issued_emp_id = 'E101';

-------- MEMBERS WHO HAVE ISSUED MORE THAN TWO BOOK -----
SELECT issued_emp_id, count(*) as num_of_book_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 2;

------------------- CTAS ---------------------------
-------- CREATING TABLE how many each isbn were issued and Its title -----------------
CREATE TABLE book_issued_cnt AS
	SELECT b.isbn,
			b.book_title,
			COUNT(ist.issued_id) AS issue_count
	
	FROM issued_status as ist
	JOIN books as b
			ON ist.issued_book_isbn = b.isbn
	GROUP BY b.isbn, b.book_title;

--------------------------------------------------------
-------------DATA ANALYSIS & FINDING -------------------
--------------------------------------------------------


---------- RETRIVING ALL BOOKS CLASSIC CATEGORY ------------
SELECT * 
FROM books
WHERE category = 'Classic';


--------- Total Rental Income by Category --------------
CREATE VIEW vw_income AS
	SELECT b.category,
			sum(b.rental_price) as rental_income,
			COUNT(*) as rents
	
	FROM books as b 
	JOIN issued_status as ist
			ON  b.isbn = ist.issued_book_isbn
	
	GROUP BY category;

SELECT * 
FROM vw_income
ORDER BY rents DESC;

----------- CUSTOMER WHO REGISTERED IN LAST 180 DAYS ----------
SELECT member_id,
		member_name,
		reg_date
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

---------- EMPLOYEES by Branch Manager's name and Branch Details ----------
SELECT em1.emp_id,
		em1.emp_name,
		bh.manager_id,
		em2.emp_name as manager,
		bh.branch_id,
		bh.branch_address as branch_address
FROM employees em1
	LEFT JOIN branch bh
	ON em1.branch_id = bh.branch_id
	LEFT JOIN employees em2 
	ON bh.manager_id = em2.emp_id
;
-------- Table of books with Rental price above $7 -----------
CREATE TABLE expensive_books AS
	SELECT * 
	FROM books
	WHERE rental_price > 7.00;

--------- LIST OF BOOKS THAT IS NOT RETURNED ---------
CREATE VIEW vw_late AS
	SELECT  isu.issued_id AS issued_id,  
	    isu.issued_member_id as member_id, 
	    isu.issued_book_name, 
	    isu.issued_date, 
	    ret.return_id 
	FROM 
	    issued_status isu
	LEFT JOIN 
	    return_status ret ON isu.issued_id = ret.issued_id
	WHERE 
	    ret.return_id IS NULL;
	
SELECT 
	issued_book_name, 
	issued_date as rent_date
FROM vw_late;
--------- LIST OF MEMBERS WITH OVERDUE BOOKS -------
SELECT 
	lt.member_id,
	member_name as customer_name,
	issued_date as rent_date,
	issued_book_name as book_name
FROM vw_late lt
	JOIN members mb ON lt.member_id = mb.member_id;

---- Query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table)---

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * 
FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * 
FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * 
FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');



------------------------------ PERFROMANCE -----------------------
---- Number of book issued, number of book returned, total revenue 
CREATE TABLE over_view(
SELECT
	(SELECT COUNT(*) FROM issued_status) as total_book_rented,
	(SELECT COUNT(*) FROM vw_late) as total_book_not_returned,
	ROUND(
		(CAST((SELECT COUNT(*) FROM vw_late)AS numeric)		  -- view created to find un returend books
		/ CAST((SELECT COUNT(*) FROM issued_status)AS numeric)
		)*100,2) || '%' as return_rate,
	'$' || (SELECT SUM(rental_income) FROM vw_income AS total_rental_income)as total_revenue
);


--  Employees with the Most Book Issues Processed
SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
    JOIN
    employees as e
    ON e.emp_id = ist.issued_emp_id
JOIN
    branch as b
    ON e.branch_id = b.branch_id
GROUP BY 1, 2;

------------------ Branch Performance Report -----------------------
CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

SELECT * FROM branch_reports
ORDER BY branch_id;


