# Performance Schedule Export

## Project Overview

The Performance Schedule Export is a custom SQL Server Reporting Services report designed to produce a clean, Excel-friendly list of upcoming performances.

The report gives ticketing and operational teams a centralized schedule containing performance dates, times, venues, statuses, and internal scheduling notes.

## Business Problem

Performance information existed in the CRM, but creating a practical scheduling document required staff to gather and reorganize information from multiple sources.

The team needed a report that could:

* Return performances for a selected date range
* Optionally filter the schedule to one venue
* Display the day of the week
* Separate the performance date and time
* Include performance type and status
* Include ticketing-specific scheduling notes
* Export cleanly to Microsoft Excel

The final report was designed around the way the scheduling information would actually be used rather than simply exposing every available database field.

## Report Parameters

The report includes three user-facing parameters:

* **Start Date** — the first performance date included in the report
* **End Date** — the final performance date included in the report
* **Venue** — an optional venue selection

Leaving the Venue parameter blank returns performances from all venues. Selecting a venue limits the results to that facility.

## Report Output

The exported schedule includes:

* Day of Week
* Performance Date
* Performance Time
* Performance Name
* Venue
* Performance Type
* Performance Status
* Ticketing Scheduling Notes

Internal identifiers such as performance number, performance code, and facility number were intentionally excluded from the final output because they were not needed by the report’s users.

## Scheduling Notes

A dedicated keyword category was created for ticketing scheduling information.

Keywords associated with each performance are combined into a single comma-separated field called **Ticketing Scheduling Notes**.

This allows scheduling information to be maintained within the CRM while still appearing in the exported report.

Examples of scheduling notes might include:

* Additional staffing required
* Special ticketing setup
* On-sale preparation
* Group sales considerations
* Event-specific operational reminders

## Technical Approach

The report uses a performance-detail reporting view as its primary data source.

An `OUTER APPLY` operation retrieves any scheduling keywords associated with each performance. Because a performance can contain multiple applicable keywords, the query combines them into one display value using XML-based string aggregation.

The date filter uses an inclusive start date and an exclusive upper boundary:

```sql
p.perf_dt >= @StartDate
AND p.perf_dt < DATEADD(DAY, 1, @EndDate)
```

This ensures that all performances occurring on the selected end date are included, regardless of their performance time.

The optional venue filter allows three conditions:

* The parameter is blank
* The parameter contains the all-venues value
* The performance matches the selected venue

## SQL Techniques Demonstrated

* Parameterized T-SQL
* Date-range filtering
* Optional filter parameters
* `OUTER APPLY`
* Correlated subqueries
* XML string aggregation
* `STUFF`
* `FOR XML PATH`
* Null handling with `ISNULL`
* Date and time formatting
* Sorting by datetime
* Reporting-view analysis

## SSRS Implementation

The completed SQL query was incorporated into a custom SSRS report.

The SSRS implementation includes:

* Start Date and End Date parameters
* An optional Venue dropdown
* Tessitura session and security context
* A tabular report layout
* Eight report columns
* Excel-oriented formatting
* Production deployment through Visual Studio
* Configuration within the CRM reporting menu

The report is intended primarily as a data export rather than a presentation-style printed report.

## Design Decisions

Several fields available in the underlying reporting view were removed from the final report.

Performance number, performance code, and facility number were useful during development but did not provide value to the staff using the exported schedule.

This reflects an important reporting principle: a useful operational report should include the information its users need without overwhelming them with unnecessary system fields.

## Business Value

The report provides a consistent schedule that can be used for:

* Ticketing staff planning
* Interdepartmental communication
* Performance setup review
* Operational scheduling
* Staffing discussions
* Excel-based planning documents

Because the scheduling notes are maintained as CRM keywords, users can update the underlying information without modifying the SQL query or SSRS report.

## Skills Demonstrated

* Microsoft SQL Server
* T-SQL
* SQL Server Reporting Services
* Visual Studio Reporting Services Projects
* CRM reporting
* Parameterized report design
* Excel-oriented reporting
* Optional dropdown filters
* Keyword-data aggregation
* Operational requirements analysis
* Report deployment
* Translating user feedback into report revisions

## Project Status

**Completed and deployed.**

The SQL query, report parameters, venue dropdown, scheduling keyword integration, SSRS layout, production deployment, and CRM report configuration have been completed.

## Privacy and Sanitization

The portfolio version does not include organizational credentials, server addresses, proprietary performance data, or internal report URLs.

Some database-object names and sample values may be generalized while preserving the SQL techniques and business logic demonstrated by the project.
