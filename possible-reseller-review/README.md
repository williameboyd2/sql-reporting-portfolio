# Possible Reseller Review

## Project Overview

The Possible Reseller Review is a parameterized T-SQL report designed to identify customers whose ticket-purchasing activity may require additional staff review.

The report evaluates several risk indicators for one selected performance, including multiple active orders, possible ticket-limit circumvention, configured customer risk attributes, and unusual activity across multiple upcoming performances.

The report is intended to support human review. It does not automatically classify a customer as a reseller or determine fraudulent intent.

## Business Problem

High-demand performances may have ticket limits intended to provide fair access to inventory.

A customer may require additional review when they:

* Place multiple separate orders for the same performance
* Purchase more active tickets than the established ticket limit across multiple orders
* Have an existing reseller, banned, or fraud-related customer attribute
* Live outside the organization's home state and have active tickets for several upcoming performances

Reviewing these factors manually required staff to search through customer accounts, orders, ticket statuses, attributes, and future performance activity.

The goal was to combine those indicators into one customer-level report.

## Report Parameters

The query uses the following parameters:

* **Performance Number** — the performance being reviewed
* **Ticket Limit** — the established ticket limit for that performance
* **Minimum Performance Count** — the number of active upcoming performances required for the out-of-state activity indicator
* **Home State** — the organization's home state used for comparison

The validated version used a minimum upcoming-performance count of three.

## Active Ticket Definition

Only active paid ticket records are included.

The production query uses the following ticket status values:

* `3` — Seated, Paid
* `12` — Ticketed, Paid

Cancelled, released, returned, or otherwise inactive ticket records are excluded.

## Risk Indicators

### Multiple Orders

The report identifies customers with more than one active order for the selected performance.

Multiple orders do not automatically indicate inappropriate activity, but they may require review when a performance has a published ticket limit.

### Possible Ticket-Limit Circumvention

A separate indicator is assigned when:

* The customer has multiple active orders for the selected performance, and
* The total active ticket count exceeds the specified ticket limit

This distinguishes customers who simply placed multiple orders from customers whose combined orders may have exceeded the intended limit.

### Customer Risk Attributes

The query searches customer attributes for configured values associated with account review.

The production configuration included values representing:

* Third-party seller activity
* Banned accounts
* Fraud concerns

The portfolio query treats these as configurable values rather than universal definitions.

### Out-of-State Activity

An additional indicator is assigned when:

* The customer's primary state differs from the organization's home state, and
* The customer has active tickets for at least the specified number of upcoming performances

This indicator is not treated as evidence by itself. It is intended to identify broader purchasing patterns that may deserve review.

## Report Output

The customer-level output includes:

* Selected performance number
* Performance name
* Performance date
* Venue
* Customer number
* Customer name
* Email address
* Mailing address
* Active tickets for the selected performance
* Active orders for the selected performance
* Largest individual order
* Ticket limit
* First order date
* Most recent order date
* Selected-performance order details
* Number of active upcoming performances
* Number of active upcoming tickets
* Upcoming performance list
* Configured risk attributes
* Multiple-order indicator
* Possible ticket-limit circumvention indicator
* Customer risk-attribute indicator
* Out-of-state activity indicator
* Total risk-indicator count
* Human-readable review reasons

## Technical Approach

The query uses a series of common table expressions to separate the analysis into logical stages.

### Selected Performance Tickets

Active ticket rows for the selected performance are grouped by customer and order.

This produces one record per customer order containing:

* Order number
* Order date
* Active ticket count

### Selected Performance Summary

The order-level results are summarized to the customer level.

The query calculates:

* Total active tickets
* Number of active orders
* Largest individual order
* First order date
* Most recent order date

### Selected Order List

`STRING_AGG` combines the selected-performance orders into a readable summary.

This allows staff to see the distribution of tickets across the customer's orders without opening each order individually.

### Upcoming Performance Activity

Active ticket records are grouped into distinct customer and performance combinations.

The report then calculates:

* Number of active upcoming performances
* Number of active upcoming tickets
* A readable list of upcoming performances

### Customer Attributes

Relevant customer attributes are deduplicated and combined into one field using `STRING_AGG`.

### Candidate Evaluation

The customer, order, attribute, address, and upcoming-performance results are combined into one evaluation dataset.

Conditional logic assigns the individual risk indicators and constructs a readable explanation of why each customer appears in the report.

## SQL Techniques Demonstrated

* Parameterized T-SQL
* Common table expressions
* Customer-level aggregation
* Order-level aggregation
* Conditional business logic
* `CASE` expressions
* `STRING_AGG`
* `CONCAT`
* `CONCAT_WS`
* Distinct-record staging
* Date filtering
* Active-status filtering
* Multi-source CRM analysis
* Human-readable exception reporting
* Risk-indicator scoring
* Null handling
* Data validation

## Validation

The report was tested against manually reviewed customer and order activity.

One validated test returned nine unique customers:

* Seven customers were returned because they had multiple active orders for the selected performance
* Two customers were returned because they had configured risk attributes

The results were reviewed to confirm that:

* Each customer appeared only once
* Active ticket counts matched the underlying order activity
* Multiple orders were correctly summarized
* Attribute-based customers were included even when they did not have multiple orders
* Inactive ticket records were excluded
* Review reasons matched the indicator columns

## Design Decisions

### Customer-Level Output

The report returns one row per customer rather than one row per ticket or order.

This makes the results easier for staff to review while preserving detailed order and performance information in aggregated fields.

### Separate Multiple-Order and Ticket-Limit Indicators

Multiple orders and exceeding a ticket limit are related but not identical.

Keeping them as separate fields allows staff to distinguish between:

* Customers who placed more than one order
* Customers whose combined active tickets exceeded the specified limit

### Review Tool Rather Than Automated Enforcement

The report intentionally uses language such as **Possible Reseller Review** and **Review Reasons**.

Purchasing patterns may have legitimate explanations. The report organizes relevant information so that staff can make an informed decision rather than treating a database flag as a final conclusion.

## Business Value

The report reduces the amount of time required to review purchasing activity for high-demand performances.

It provides staff with a consistent process for:

* Reviewing possible ticket-limit circumvention
* Identifying previously flagged accounts
* Evaluating broader upcoming-performance activity
* Documenting why a customer was selected for review
* Prioritizing accounts with multiple risk indicators

## Skills Demonstrated

* Microsoft SQL Server
* T-SQL
* CRM and ticketing data analysis
* Customer-level reporting
* Order analysis
* Business-rule development
* Risk-indicator design
* Data deduplication
* Multi-table reporting
* Operational requirements analysis
* Report validation
* Responsible presentation of analytical results

## Project Status

**SQL logic completed and validated.**

The portfolio version has been generalized and sanitized. Customer results and proprietary transactional data are not included.

## Privacy and Sanitization

The public repository contains query logic only.

It does not contain:

* Customer names
* Customer email addresses
* Customer mailing addresses
* Actual order numbers
* Actual performance numbers
* Internal server information
* Credentials
* Transactional query results

Some view and column names have been generalized to demonstrate the reporting approach without exposing organization-specific database configuration.
