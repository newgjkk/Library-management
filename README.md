# Library Management System using SQL 

## Project Overview

**Project Title**: Library Management System  
**Database**: `library_db`

This project demonstrates the implementation of a Library Management System using SQL. It includes creating and managing tables, performing CRUD operations, and executing advanced SQL queries. The goal is to showcase skills in database design, manipulation, and querying.

![Library_project](https://github.com/newgjkk/Library-management/blob/main/library.jpg)

## Objectives

1. **Set up the Library Management System Database**: Create and populate the database with tables for branches, employees, members, books, issued status, and return status.
2. **CRUD Operations**: Perform Create, Read, Update, and Delete operations on the data.
3. **CTAS (Create Table As Select)**: Utilize CTAS to create new tables based on query results.
4. **Advanced SQL Queries**: Develop complex queries to analyze and retrieve specific data.

## Project Structure

### 1. Database Setup
![ERD](https://github.com/newgjkk/Library-management/blob/main/library_erd.png)

- **Database Creation**: Created a database named `library_db`.

```sql
CREATE DATABASE library_db;

------ Creating Branch tables ------
DROP TABLE IF EXISTS branch;
CREATE TABLE branch(
	branch_id		VARCHAR(25) PRIMARY KEY,
	manager_id		VARCHAR(20),
	branch_address	VARCHAR(80),
	contact_no 		VARCHAR(20)
);

DROP TABLE IF EXISTS employees;
CREATE TABLE employees(
	emp_id 		VARCHAR(25) PRIMARY KEY,
	emp_name 	VARCHAR(25),
	position	VARCHAR(25),
	salary		INT,
	branch_id   VARCHAR(25)
);

DROP TABLE IF EXISTS books;
CREATE TABLE books(
isbn			VARCHAR(35) PRIMARY KEY,
book_title		VARCHAR(80),
category		VARCHAR(25),
rental_price	FLOAT,
status			VARCHAR(15),
author			VARCHAR(25),
publisher  		VARCHAR(65)
);

DROP TABLE IF EXISTS members;
CREATE TABLE members(
member_id		VARCHAR(25) PRIMARY KEY,
member_name		VARCHAR(25),
member_address	VARCHAR(55),
reg_date		DATE
);


DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status(
issued_id			VARCHAR(25) PRIMARY KEY,
issued_member_id	VARCHAR(25),
issued_book_name	VARCHAR(55),
issued_date			DATE,
issued_book_isbn	VARCHAR(35),
issued_emp_id		VARCHAR(25)
);

DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status(
return_id			VARCHAR(25) PRIMARY KEY,
issued_id			VARCHAR(25),
return_book_name	VARCHAR(10),
return_date			DATE,
return_book_isbn	VARCHAR(35)
);

----- FOREGIN KEY DEFINE --------
ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id) REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id);

ALTER TABLE employees
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id) REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id);

```

### 2. CRUD Operations

- **Create**: Inserted sample records into the `books` table.
- **Read**: Retrieved and displayed data from various tables.
- **Update**: Updated records in the `employees` table.
- **Delete**: Removed records from the `members` table as needed.

** Insert missing New Book Record**
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

```sql
INSERT INTO books
(isbn,book_title,category,rental_price,status,author,publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

```
**Update an Existing Member's Address**

```sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C101';
```

**Delete a Record from the Issued Status Table**
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

**Retrieve All Books Issued by a Specific Employee**
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
```sql
SELECT * 
FROM issued_status
WHERE issued_emp_id = 'E101';
```


**Members Who Have Issued More Than Two Book**
-- Objective: Use GROUP BY to find members who have issued more than one book.

```sql
SELECT issued_emp_id, count(*) as num_of_book_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 2;
```

### 3. CTAS (Create Table As Select)

- **Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

```sql
CREATE TABLE book_issued_cnt AS
	SELECT b.isbn,
			b.book_title,
			COUNT(ist.issued_id) AS issue_count
	
	FROM issued_status as ist
	JOIN books as b
			ON ist.issued_book_isbn = b.isbn
	GROUP BY b.isbn, b.book_title;
```


### 4. Data Analysis & Findings

The following SQL queries were used to address specific questions:

**Retrieve All Books in a Specific Category**:

```sql
SELECT * 
FROM books
WHERE category = 'Classic';
```

Find Total Rental Income by Category**:

```sql
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
```

**List Members Who Registered in the Last 180 Days**:
```sql
SELECT member_id,
		member_name,
		reg_date
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';
```

**List of Employees by Branch Manager's name and Branch Details**:

```sql
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
```

**Create a Table of books with Rental price above $7**:
```sql
CREATE TABLE expensive_books AS
	SELECT * 
	FROM books
	WHERE rental_price > 7.00;
```
## Advanced SQL Operations
 
**Retrieve LIST OF BOOKS THAT IS NOT RETURNED**
```sql
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
```

**LIST OF MEMBERS WITH OVERDUE BOOKS**

```sql
SELECT 
	lt.member_id,
	member_name as customer_name,
	issued_date as rent_date,
	issued_book_name as book_name
FROM vw_late lt
	JOIN members mb ON lt.member_id = mb.member_id;
```


**Update Book Status on Return**  
Query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

```sql

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

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');

```
** Brief over view of business**  
Query to find the Number of book issued, number of book returned, total revenue

```sql
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

SELECT * FROM over_view;

```
**Find Employees with the Most Book Issues Processed**  
Query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

```sql
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
```

**Branch Performance Report**  
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

```sql
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
GROUP BY 1, 2;

SELECT * FROM branch_reports
ORDER BY branch_id;
```




## Reports

- **Database Schema**: The branch table includes fields such as branch_id, manager_id, number_book_issued, number_of_book_return, and total_revenue, which detail the operations of each library branch and its performance metrics.
- **Data Analysis**: Insights include the total number of books issued and returned across branches, highlighting branch performance. For instance, branch B001 has issued 17 books, with 8 returned, leading to a total revenue of $111.50. Conversely, branches like B002 and B003 show low activity with only 2 books issued.
- **Summary Reports**: Aggregated data indicates high-demand branches and those needing performance improvement. For example, B001 stands out as a high-demand branch, while B002 and B003 may require strategies to increase book circulation.

## Conclusion

This project has provided valuable insights into the operations of a library management system, highlighting key performance metrics and trends that can be utilized for strategic decision-making. By analyzing data related to book circulation, branch performance, and member interactions, we can make informed predictions about future library operations.

**Predictive Insights**:
Book Demand Trends: The analysis indicates which books are frequently issued, allowing the library to forecast demand and manage inventory more effectively. This information can guide purchasing decisions and help maintain an up-to-date collection that meets member needs.

**Branch Performance Evaluation**: Insights into the performance of different branches can identify high-performing locations and those requiring additional resources or marketing efforts. This can lead to targeted initiatives to enhance engagement and circulation in underperforming branches.

**Practical Applications**:
Resource Allocation: Understanding which branches and books are in high demand can help library management allocate resources more efficiently, ensuring that popular books are readily available and that staff can focus on improving services in high-traffic areas.

**Member Engagement Strategies**: The data can inform strategies to increase member participation, such as targeted promotions for popular books or events that encourage visits to underutilized branches.

**Future Implications**:
The findings from this project serve as a foundation for ongoing analysis and improvements within the library management system. By continuously monitoring data and adapting strategies accordingly, libraries can enhance their operations, improve member satisfaction, and foster a more engaged community.

Thank you for your interest in this project!
