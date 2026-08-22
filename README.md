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

- A branch has one manager, and that manager is an employee — so *branch* and *employee* point to each other. Both tables are created first, and the connection between them is added afterward, so there's no "which one comes first" problem.
- The database itself blocks bad data — for example, it won't let *available_copies* be a negative number or be higher than *total_copies*, and it won't let a due date be earlier than the issue date.

## Tools Used

- **PostgreSQL** — the database itself
- **PL/pgSQL** — used to write the two automated commands (procedures) for issuing and returning books
- **CSV files** — the actual data, loaded into the tables

## All 21 Questions

Full SQL code for every single one of these is in sql/Solutions.sql.
