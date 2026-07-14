# SQL Reporting Portfolio

T-SQL, SSRS, and CRM reporting case studies focused on performing arts ticketing, attendance reconciliation, operational reporting, and data analysis.

All examples in this repository have been generalized and anonymized to protect organizational and customer information while demonstrating the underlying reporting techniques, business logic, and problem-solving process.

## About Me

Hi, I'm William Boyd.

I'm a Ticketing Manager with experience in performing arts CRM systems, ticketing operations, SQL Server, SSRS, data reporting, event setup, inventory management, and business process improvement.

I enjoy translating operational questions into useful reporting solutions. My work focuses on understanding how ticketing and CRM data behaves, validating results against real business processes, and building reports that help teams make better decisions.

## Featured Projects

### [Attendance Reconciliation by Scan Date](attendance-reconciliation-case-study/)

A custom attendance reconciliation report designed for general admission events where voucher-style tickets may be redeemed across multiple performance dates.

The report combines:

* Tickets sold
* Tickets scanned
* Single-ticket no-shows
* Voucher and movie-strip admissions
* Complimentary admissions by reason
* Staff and volunteer admissions
* Report-level totals

**Key skills:** T-SQL, SSRS, temporary tables, aggregate reporting, ticket-history analysis, data reconciliation, business-rule validation, and report deployment.

**Status:** Completed, validated, and deployed as a custom SSRS report.

---

### [Platinum Seating Detail Export](platinum-seating-detail-export/)

A seat-level inventory and pricing export for performances using Platinum or dynamically priced seating zones.

The report combines:

* Current sold, held, and open seat inventory
* Historical pricing for sold seats
* Current configured pricing for open and held seats
* Base price, facility fee, and Platinum lift detail
* Simplified renter-facing statuses
* Blank request columns for inventory and pricing changes

**Key skills:** T-SQL, common table expressions, `OUTER APPLY`, effective-date pricing, historical and current data reconciliation, pricing-layer aggregation, seat inventory, and operational workflow design.

**Status:** SQL logic completed and validated.

---

### [Performance Schedule Export](performance-schedule-export/)

An Excel-oriented scheduling report that produces a clean list of upcoming performances for ticketing and operational planning.

The report includes:

* Day of week
* Performance date and time
* Performance name
* Venue
* Performance type
* Performance status
* Ticketing scheduling notes

Users can filter the report by date range and optionally select a venue. Scheduling notes are maintained through a dedicated performance keyword category.

**Key skills:** T-SQL, SSRS, parameterized reporting, `OUTER APPLY`, XML string aggregation, date filtering, keyword data, and Excel-ready report design.

**Status:** Completed and deployed as a custom SSRS report.

---

### [Possible Reseller Review](possible-reseller-review/)

A risk-review query that identifies customers who may require additional investigation for reseller or fraudulent ticket-purchasing activity.

The query evaluates several indicators:

* Multiple orders for the same performance
* Possible ticket-limit circumvention
* Customer risk attributes
* Out-of-state customers with activity across multiple upcoming performances
* Active ticket and order totals
* Upcoming performance activity
* Human-readable review reasons

The report is designed as a review tool rather than an automated determination of customer intent.

**Key skills:** T-SQL, CTEs, conditional business logic, customer-level aggregation, risk indicators, `STRING_AGG`, and multi-source CRM analysis.

**Status:** SQL logic completed and validated.

---

### [Historical Ticket Pricing Analysis](historical-ticket-pricing-analysis/)

A historical sales analysis that compares ticket purchasing behavior across multiple production seasons.

The report summarizes:

* Tickets sold by price level and price zone
* Ticket revenue excluding fees
* Average amount paid per ticket
* Number of orders
* Average tickets purchased per order
* Season-level totals and averages

**Key skills:** T-SQL, financial aggregation, CTEs, order analysis, price-zone reporting, seasonal comparisons, and formatted business output.

**Status:** SQL logic completed and validated.

---

### [Price Type Reference Query](price-type-reference-query/)

A reusable administrative query that produces a reference list of configured ticket price types.

The output includes:

* Price Type ID
* Description
* Price Type Category ID
* Price Type Group ID
* Web alias
* Active or inactive status

**Key skills:** SQL Server reference-table exploration, system configuration reporting, clean aliases, and reusable administrative queries.

**Status:** Completed.

## Technical Skills Demonstrated

* Microsoft SQL Server
* T-SQL
* SQL Server Reporting Services
* Visual Studio Reporting Services Projects
* Tessitura CRM reporting
* Parameterized queries
* Common table expressions
* Temporary tables
* `OUTER APPLY`
* XML and string aggregation
* Aggregate reporting
* Data reconciliation
* Financial analysis
* Pricing-layer analysis
* Seat inventory reporting
* Customer and order analysis
* Report deployment
* Excel-oriented report design
* Business-rule validation
* Data anonymization

## Portfolio Approach

Each project begins with a real operational or reporting problem rather than a predetermined SQL exercise.

My process generally includes:

1. Defining the business question and expected output.
2. Identifying the appropriate CRM tables and reporting views.
3. Testing assumptions about ticket, order, attendance, and historical data.
4. Comparing query results with existing reports or manually verified totals.
5. Investigating discrepancies and refining the business logic.
6. Designing the final output for the people who will use it.
7. Documenting and sanitizing the solution for this portfolio.

## Data Privacy

No customer information, credentials, internal server addresses, or proprietary transactional results are included in this repository. Sample values and outputs are fictionalized or generalized where necessary.

## Current Focus

I am continuing to develop my skills in T-SQL, SSRS, CRM administration, data analytics, and business intelligence while pursuing opportunities involving Tessitura, ticketing technology, CRM systems, and performing arts administration.
