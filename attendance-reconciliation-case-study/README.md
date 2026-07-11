# Attendance Reconciliation by Scan Date

## Project Overview

This project began with an attendance-reporting problem involving general admission events and voucher-style tickets.

The standard attendance report associated activity primarily with the ticket's performance. That did not fully answer the operational question because some tickets could be sold against one performance record but redeemed on a different event date.

The report therefore needed to reconcile attendance using the **actual scan date**.

## Business Problem

The ticketing team needed a report that could clearly show:

* How many single-event tickets were sold
* How many tickets were scanned
* How many single-event tickets were not scanned
* How many voucher-style tickets were redeemed
* How complimentary admissions were distributed by reason
* How many staff and volunteer admissions occurred
* Overall attendance totals for the selected date and venue

The primary challenge was that ticket sales, ticket-history records, and attendance scans did not all represent the same type of activity.

## Report Parameters

The completed SSRS report uses two primary parameters:

* **Scan Date** — the calendar date on which attendance activity occurred
* **Venue** — the facility associated with the event activity

## Investigation

Initial versions of the query produced incorrect totals because ticket-history tables could contain multiple records representing changes to the same ticket.

Simply counting rows from ticket history caused purchased-ticket totals to be overstated.

The investigation showed that:

* Historical ticket rows cannot automatically be treated as unique active tickets.
* Current ticket state and ticket history serve different reporting purposes.
* Scan date and performance date are not always equivalent.
* Voucher-style tickets require separate business logic.
* Complimentary admissions need additional classification to be operationally useful.
* Existing report totals are an important validation source, but they do not always provide the complete breakdown needed by the business.

## Technical Approach

The report separates the attendance process into several logical components:

1. Identify the requested scan date and venue.
2. Retrieve valid sold single-event tickets.
3. Retrieve attendance activity using the actual scan timestamp.
4. Identify voucher-style admissions separately from regular sold tickets.
5. categorize complimentary admissions using their associated reason.
6. Calculate unscanned single-event tickets.
7. Combine the results into a unified report output.
8. Produce report-level totals.

The query uses T-SQL techniques including:

* Temporary tables
* Aggregate functions
* Conditional categorization
* Null handling
* Date conversion
* Ticket-history lookups
* Attendance aggregation
* Multiple result categories combined into a single report dataset

## Report Output

The final report includes categories such as:

* Standard tickets
* Student and senior tickets
* Movie strips or vouchers
* Single-event complimentary tickets
* General complimentary admissions
* Development complimentary admissions
* Donor complimentary admissions
* Marketing complimentary admissions
* Staff admissions
* Volunteer admissions
* Other configured complimentary reasons

The report presents:

* Tickets sold
* Tickets scanned
* No-shows
* Category totals
* Grand totals

Voucher admissions are counted as scanned admissions but are not treated as single-event ticket sales. No-shows are calculated only for applicable single-event tickets.

## Validation

The final query was tested against:

* Existing standard report totals
* Manually verified attendance counts
* Known voucher-redemption activity
* Complimentary admission breakdowns
* Individual event-day reconciliation results

The completed report matched the expected purchased-ticket and attendance totals while also providing scan-date and complimentary-reason details that were not available together in the standard report.

## SSRS Implementation

After the SQL logic was validated, the report was developed in SQL Server Reporting Services.

The implementation included:

* A custom SSRS report layout
* Scan Date and Venue parameters
* Tessitura session and security context
* Report totals
* Production deployment through Visual Studio
* Configuration in the Tessitura Reports menu

The report was deployed to the production SSRS environment and added to the Ticketing Box Office report category.

## Skills Demonstrated

* Microsoft SQL Server
* T-SQL
* SQL Server Reporting Services
* Attendance reconciliation
* Ticket-history analysis
* Temporary tables
* Aggregate reporting
* Conditional business logic
* Parameterized reports
* Report validation
* Troubleshooting data discrepancies
* Visual Studio report deployment
* Tessitura CRM reporting
* Translating operational requirements into a technical solution

## Project Status

**Completed and deployed.**

The SQL logic, SSRS report design, report parameters, production deployment, and Tessitura report configuration have been completed and validated.

## Privacy and Sanitization

The public portfolio version of this project excludes customer-level information, organizational credentials, internal server addresses, and proprietary transactional data.

Table structures and sample outputs are presented only to demonstrate the reporting approach and technical concepts.

