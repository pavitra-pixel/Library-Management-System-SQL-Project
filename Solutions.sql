SELECT * FROM book;
SELECT * FROM branch;
SELECT * FROM issue_return;
SELECT * FROM employee;
SELECT * FROM member;

/*
Q1. Which category has the most books?
*/

SELECT 
	category,
	COUNT(isbn) AS total_books
FROM book
GROUP BY category
ORDER BY total_books DESC;

/*
Q2. Which books have never been borrowed?
*/

SELECT
	b.isbn,
	b.book_title,
	b.category
FROM book b
LEFT JOIN issue_return isr
ON b.isbn = isr.isbn
WHERE isr.isbn IS NULL;

/*
Q3. Which members have never borrowed a book?
*/

SELECT 
	m.member_id, 
	m.member_name, 
	m.member_address, 
	m.reg_date
FROM member m
LEFT JOIN issue_return isr 
ON m.member_id = isr.member_id
WHERE isr.member_id IS NULL;

/*
Q4. Which books are currently overdue?
*/

SELECT
	isr.issued_id,
	isr.member_id,
	m.member_name,
	b.book_title,
	(CURRENT_DATE - isr.due_date) AS days_overdue
FROM book b
JOIN issue_return isr
ON b.isbn = isr.isbn
JOIN member m
ON isr.member_id = m.member_id
WHERE (isr.return_date IS NULL) AND (CURRENT_DATE > isr.due_date)
ORDER BY days_overdue DESC;

/*
Q5. How much could each category earn if every copy were rented out?
*/

SELECT 
	category,
	SUM(b.rental_price * b.total_copies) AS potential_income
FROM book b
GROUP BY category
ORDER BY potential_income DESC;

/*
Q6. How much money has the library earned in total?
*/

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

/*
Q7. How much money has each category earned?
*/

SELECT 
	b.category,
	SUM(
		CASE
			WHEN (isr.return_date IS NOT NULL) AND (isr.return_date>isr.due_date)
			THEN b.rental_price + ((isr.return_date - isr.due_date) * 2)
			WHEN isr.return_date IS NOT NULL
			THEN b.rental_price
			ELSE 0
		END
	) AS total_revenue
FROM book b
JOIN issue_return isr
ON b.isbn = isr.isbn
GROUP BY b.category
ORDER BY total_revenue DESC;

/*
Q8. How much money has each branch earned?
*/

SELECT
	br.branch_id,
	br.branch_address,
	br.contact_no,
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
ON b.isbn = isr.isbn
JOIN employee e
ON isr.emp_id = e.emp_id
JOIN branch br
ON br.branch_id = e.branch_id
GROUP BY br.branch_id, br.branch_address, br.contact_no
ORDER BY total_revenue DESC;

/*
Q9. What's the average, highest, and lowest rental price in each category?
*/

SELECT 
	category,
	ROUND(AVG(rental_price)::NUMERIC,2) AS avg_rental_price,
	MAX(rental_price) AS max_price,
	MIN(rental_price) AS min_price
FROM book
GROUP BY category
ORDER BY avg_rental_price DESC;

/*
Q10. Who are the top 3 members that borrow the most?
*/

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

/*
Q11. Who are the top 3 employees that issue the most books?
*/

SELECT *
FROM (
	SELECT
		isr.emp_id,
		e.emp_name,
		e.branch_id,
		COUNT(isr.issued_id) AS books_issued,
		DENSE_RANK () OVER(ORDER BY COUNT(isr.issued_id) DESC) AS rnk
	FROM issue_return isr 
	JOIN employee e
	ON e.emp_id = isr.emp_id
	GROUP BY isr.emp_id, e.emp_name, e.branch_id
	) t
WHERE rnk <= 3
ORDER BY rnk;

/*
Q12. What are the top 3 most-borrowed books?
*/
SELECT *
FROM(
	SELECT 
		b.isbn,
		b.book_title,
		b.category,
		COUNT(isr.issued_id) AS times_issued,
		DENSE_RANK() OVER(ORDER BY COUNT(isr.issued_id) DESC) AS rnk
	FROM book b
	JOIN issue_return isr
	ON b.isbn = isr.isbn
	GROUP BY b.isbn, b.book_title, b.category
) t
WHERE rnk<=3
ORDER BY rnk;

/*
Q13. How much money has each member generated?
*/

SELECT
	isr.member_id,
	m.member_name,
	SUM(
		CASE
			WHEN isr.return_date IS NOT NULL AND isr.return_date > isr.due_date
			THEN b.rental_price + ((isr.return_date - isr.due_date)*2)
			WHEN isr.return_date IS NOT NULL
			THEN b.rental_price
			ELSE 0
		END
	) AS revenue_generated
FROM issue_return isr
JOIN member m
ON isr.member_id = m.member_id
JOIN book b
ON isr.isbn = b.isbn
GROUP BY isr.member_id, m.member_name
ORDER BY revenue_generated DESC;

/*
Q14. Branch wise employee's performance.
*/
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

/* 
Q15. How many books were borrowed each month?
*/

SELECT 
	TO_CHAR(issued_date, 'YYYY-MM') AS month,
	COUNT(issued_id) AS total_books_issued
FROM issue_return
GROUP BY TO_CHAR(issued_date, 'YYYY-MM')
ORDER BY month;

/* 
Q16. On average, how many days does it take to return a book, by category?
*/

SELECT
	b.category,
	ROUND(AVG(isr.return_date-isr.issued_date),1) AS avg_return_days
FROM book b
JOIN issue_return isr
ON b.isbn = isr.isbn
WHERE isr.return_date IS NOT NULL
GROUP BY b.category
ORDER BY avg_return_days DESC;

/* 
Q17. Which members have returned books late more than twice?
*/

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

/* 
Q18. Which books are more than 60 days overdue?
*/

SELECT
	isr.issued_id,
	m.member_name,
	m.member_address,
	b.book_title,
	b.rental_price,
	isr.due_date,
	(CURRENT_DATE - isr.due_date) AS days_overdue,
	(CURRENT_DATE - isr.due_date)*2 AS fine
FROM issue_return isr
JOIN book b 
ON b.isbn = isr.isbn
JOIN member m
ON m.member_id = isr.member_id
WHERE (isr.return_date IS NULL) AND (CURRENT_DATE - isr.due_date) >= 60
ORDER BY days_overdue DESC;

/*
Q19. Which members still haven't returned a book, and what's their fine?
*/

SELECT 
	isr.member_id,
	m.member_name,
	m.member_address,
	isr.issued_id,
	b.book_title,
	(CURRENT_DATE - isr.due_date)*2 AS fine
FROM issue_return isr
JOIN member m
ON isr.member_id = m.member_id
JOIN book b
ON isr.isbn = b.isbn
WHERE isr.return_date IS NULL
ORDER BY fine DESC;

/* 
Q20. Create procedure to issue a book (checks availability, issues it, updates the count)
*/

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

CALL issue_book(212, 103, 9780743247224);

SELECT * FROM issue_return
WHERE issued_id = 1041

/* 
Q21. Create procedure to return a book (checks it's not already returned, marks it returned, adds the copy back)
*/

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
CALL return_book(1041);