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

![Library ERD]()
