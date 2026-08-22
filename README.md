# 📚 Library Management System — SQL Project
## Overview

A small database project that stores information for a library with multiple branches — books, branches, staff, members, and every time a book is borrowed or returned. Built in PostgreSQL, with 21 questions answered using SQL, plus two automated commands to issue and return books.

## Problem Statement

A library with paper records or a plain spreadsheet can't easily answer everyday questions like "which members keep returning books late?" or "how much money did Branch 2 make this month?". The data is scattered, nothing is connected, and even simple questions take a long time to work out by hand.

## Objective

Build a proper database for a multi-branch library that can:

- Store books, branches, staff, members, and every borrow/return event in one connected place
- Stop bad data from getting in, using rules built into the database itself (like blocking a negative copy count)
- Instantly answer 21 real questions a library manager would actually ask
- Automate the two most repeated tasks — issuing and returning a book — with ready-made commands, instead of doing several manual steps every time

## Database Design

Diagram of how the tables connect:

![Library ERD](https://github.com/pavitra-pixel/Library-Management-System-SQL-Project/blob/main/ERD.png)

A couple of small but important design details:

- A branch has one manager, and that manager is an employee — so `branch` and `employee` point to each other. Both tables are created first, and the connection between them is added afterward, so there's no "which one comes first" problem.
- The database itself blocks bad data — for example, it won't let `available_copies` be a negative number or be higher than `total_copies`, and it won't let a due date be earlier than the issue date.

## Tools Used

- **PostgreSQL** — the database itself
- **PL/pgSQL** — used to write the two automated commands (procedures) for issuing and returning books
- **CSV files** — the actual data, loaded into the tables

## All 21 Questions

Full SQL code for every single one of these is in ![Solutions.sql](https://github.com/pavitra-pixel/Library-Management-System-SQL-Project/blob/main/Solutions.sql)

## Questions

1. Which category has the most books?
2. Which books have never been borrowed?
3. Which members have never borrowed a book?
4. Which books are currently overdue?
5. How much could each category earn if every copy were rented out?
6. How much money has the library earned in total?
7. How much money has each category earned?
8. How much money has each branch earned?
9. What's the average, highest, and lowest rental price in each category?
10. Who are the top 3 members that borrow the most?
11. Who are the top 3 employees that issue the most books?
12. What are the top 3 most-borrowed books?
13. How much money has each member generated?
14. Branch wise employee's performance.
15. How many books were borrowed each month?
16. On average, how many days does it take to return a book, by category?
17. Which members have returned books late more than twice?
18. Which books are more than 60 days overdue?
19. Which members still haven't returned a book, and what's their fine?
20. Create procedure to issue a book (checks availability, issues it, updates the count)
21. Create procedure to return a book (checks it's not already returned, marks it returned, adds the copy back)

## A Closer Look of the Queries

These 6 queries shows the widest range of SQL skills in the project — the rest follow the same patterns.

**Q6. How much money has the library earned in total?**

*Uses if-then logic to add a late fee only when a book came back late.*

```sql
SELECT
	SUM(
		CASE
			WHEN (isr.return_date IS NOT NULL) AND (isr.return_date > isr.due_date)
			THEN b.rental_price + ((isr.return_date - isr.due_date) * 2)
			WHEN isr.return_date IS NOT NULL
			THEN b.rental_price
			ELSE 0
		END
	) AS total_revenue
FROM book b
JOIN issue_return isr
ON isr.isbn = b.isbn;
```

**Q10. Who are the top 3 members that borrow the most?**

*Uses `DENSE_RANK()` to rank members without skipping numbers when there's a tie.*

```sql
SELECT *
FROM (
	SELECT 
		isr.member_id,
		m.member_name,
		m.member_address,
		COUNT(isr.issued_id) AS books_issued_by_member,
		DENSE_RANK() OVER(ORDER BY COUNT(isr.issued_id) DESC) AS rnk
	FROM issue_return isr
	JOIN member m
	ON m.member_id = isr.member_id
	GROUP BY isr.member_id, m.member_name, m.member_address
	) t
WHERE rnk <= 3
ORDER BY rnk;
```

**Q14. Branch wise employee's performance.**

*Uses `PARTITION BY` so the ranking restarts for each branch, instead of ranking everyone company-wide.*

```sql
SELECT 
	branch_id,
	emp_name,
	books_issued,
	DENSE_RANK() OVER(PARTITION BY branch_id ORDER BY books_issued DESC) AS rnk
FROM(
	SELECT 
		e.branch_id,
		e.emp_name,
		COUNT(issued_id) AS books_issued
	FROM employee e
	LEFT JOIN issue_return isr
	ON isr.emp_id = e.emp_id
	GROUP BY e.branch_id, e.emp_name
	) t
ORDER BY branch_id, rnk;
```

**Q17. Which members have returned books late more than twice?**

*Uses `HAVING` to filter on a count that's calculated inside the query itself.*

```sql
SELECT 
	isr.member_id,
	m.member_name,
	COUNT(isr.issued_id) AS late_returns
FROM issue_return isr
JOIN member m 
ON isr.member_id = m.member_id
WHERE (isr.return_date IS NOT NULL) AND (isr.return_date > isr.due_date) 
GROUP BY isr.member_id, m.member_name
HAVING COUNT(isr.issued_id) > 2;
```

**Q20. Create procedure to issue a book**

*Checks a copy is free, issues it, and updates the count — all in one safe command.*

```sql
CREATE PROCEDURE issue_book(p_member_id INT, p_emp_id INT, p_isbn BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
	v_issued_id INT;
BEGIN
	IF EXISTS(
		SELECT 1
		FROM book b
		WHERE (b.isbn = p_isbn) AND available_copies > 0
	)
	
	THEN
		INSERT INTO issue_return(member_id, emp_id, isbn, issued_date, due_date)
		VALUES (p_member_id, p_emp_id, p_isbn, CURRENT_DATE, CURRENT_DATE + 30)
		RETURNING issued_id
		INTO v_issued_id;
		
		UPDATE book
		SET available_copies = available_copies - 1
		WHERE isbn = p_isbn;
		
		RAISE NOTICE 'BOOK ISSUED SUCCESSFULLY WITH ISSUED ID: %', v_issued_id;
	ELSE 
		RAISE NOTICE 'BOOK NOT AVAILABLE';
		
	END IF;
END;
$$
```
Used like this: `CALL issue_book(212, 103, 9780743247224);`

**Q21. Create procedure to return a book**

*Checks it isn't already returned, marks it returned, and adds the copy back*

```sql
CREATE PROCEDURE return_book(p_issued_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
	v_isbn BIGINT;
BEGIN
	IF EXISTS(
				SELECT 1 
				FROM issue_return
				WHERE (issued_id = p_issued_id) AND (return_date IS NULL)
			)
			
	THEN 
		SELECT isbn INTO v_isbn
		FROM issue_return
		WHERE issued_id = p_issued_id;
		
		UPDATE issue_return
		SET return_date = CURRENT_DATE
		WHERE issued_id = p_issued_id;
		
		UPDATE book
		SET available_copies = available_copies + 1
		WHERE isbn = v_isbn;
			
		RAISE NOTICE 'BOOK RETURNED SUCCESSFULLY';
	ELSE 
		RAISE NOTICE 'BOOK IS NOT ISSUED YET OR ALREADY RETURNED';
	END IF;
END;
$$
```
Used like this: `CALL return_book(1041);`

## Problems Found and Fixed While Building This

- **Two people borrowing at the exact same time could get the same ID number.** Early versions figured out the next ID by finding the highest existing one and adding 1 — but two requests happening together could both pick the same number. Fixed by letting PostgreSQL generate the ID automatically and safely instead.

- **IDs got out of sync after loading the CSV files.** When existing data is loaded straight from a CSV, the database doesn't know new IDs should start counting after the highest one already in the file. This was fixed with a small command at the bottom of *Schema.sql* that tells the database where to continue counting from.

- **A few small typos and logic mistakes** in the two automated commands (issue/return) were found and corrected while testing them.

## Conclusion

This project takes a library's scattered records and turns them into one connected database. Instead of taking time to work things out by hand, questions like "which books are popular?" or "which members return late?" can now be answered in seconds with a single query. Building it also meant designing the tables from scratch, writing real SQL queries, and creating automated commands to keep the data accurate.
