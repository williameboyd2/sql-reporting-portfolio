# Performance Inventory Status Summary

## Project Overview

The Performance Inventory Status Summary is a parameterized T-SQL utility that provides a concise, real-time overview of seat inventory for a selected performance.

It translates detailed Tessitura seat statuses into three operational categories:

* **Sold**
* **Shopping Cart**
* **Open**

The result gives ticketing staff a quick snapshot of how much inventory has sold, how much is temporarily tied up in active online transactions, and how much remains available for purchase.

## Business Problem

During an on-sale or inventory review, staff may need a quick answer to three questions:

* How many seats have been sold?
* How many seats are currently locked in shopping carts?
* How many seats remain openly available?

The underlying CRM stores several distinct seat statuses. Although those statuses are useful inside the system, reviewing them individually is slower than presenting the totals in clear business categories.

The goal was to create a lightweight query that produces an immediately usable performance-level summary.

## Report Parameter

The query uses one parameter:

* **Performance Number** — the performance whose current inventory will be summarized

The public portfolio version uses a fictional example value that must be replaced before the query is run.

## Status Mapping

The query applies the following business rules:

| Summary Category | Tessitura Seat Status |
| --- | --- |
| Sold | Ticketed; Reserved, Paid |
| Shopping Cart | Locked; Reserved, Unpaid |
| Open | Available |

Seats in other statuses are intentionally omitted. Held inventory is not counted as open inventory.

## Report Output

The query returns one row for the selected performance containing:

* Performance number
* Performance name
* Performance date
* Sold seats
* Seats in shopping carts
* Open seats
* Total included inventory

The total represents only the three included operational categories. It is not intended to represent every seat or status configured on the performance.

## Technical Approach

The query begins with current performance-seat inventory and joins the seat-status and performance-detail records needed for readable output.

Conditional aggregation converts individual seat records into summary columns. Each qualifying seat contributes to exactly one category based on its current Tessitura status.

A filtering condition limits the source rows to the five statuses relevant to the report. Package-level records are excluded so the result reflects individual performance inventory.

## SQL Techniques Demonstrated

* Parameterized T-SQL
* Conditional aggregation
* `SUM` and `CASE`
* Status normalization
* Performance-level grouping
* Current inventory reporting
* Business-rule filtering
* Null-safe totals
* Operational query design

## Validation

The query was tested against a selected performance and reviewed to confirm that:

* Ticketed and Reserved, Paid seats were counted as sold
* Locked and Reserved, Unpaid seats were counted as shopping-cart inventory
* Available seats were counted as open
* Held and unrelated statuses were excluded
* The category totals matched the underlying current seat statuses
* The result returned one concise row for the selected performance

## Business Value

This report gives ticketing staff a fast inventory snapshot without requiring manual counting or interpretation of multiple system statuses.

It can support:

* On-sale monitoring
* Shopping-cart activity checks
* Performance inventory reviews
* Quick availability updates
* Troubleshooting discrepancies between sold and available inventory

## Project Status

**SQL logic completed and validated.**

This project is intentionally smaller than the portfolio's full analytical reports. It demonstrates the ability to translate a straightforward operational question into a focused, reusable query.

## Privacy and Sanitization

The public portfolio version contains no customer, order, payment, or organizational data.

The example performance number is fictional and must be replaced with a valid value from the target Tessitura environment.

## Files

* [`performance-inventory-status-summary.sql`](performance-inventory-status-summary.sql) — sanitized portfolio version of the query

