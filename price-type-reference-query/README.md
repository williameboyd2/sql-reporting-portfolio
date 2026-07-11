# Price Type Reference Query

## Project Overview

The Price Type Reference Query is a reusable T-SQL utility that produces a clean reference list of the ticket price types configured in Tessitura.

Price types are commonly used to identify customer eligibility, discounts, complimentary ticket categories, promotions, and other ticket-pricing classifications.

The query allows ticketing and CRM staff to quickly retrieve the internal ID and configuration details associated with each price type.

## Business Problem

Ticketing reports, imports, troubleshooting tasks, and system configuration work frequently require a price type’s internal ID.

The user-facing description may be familiar to staff, but the numeric ID is often needed when:

* Writing SQL queries
* Troubleshooting ticket transactions
* Configuring reports
* Reviewing ticketing setup
* Creating imports or data extracts
* Comparing web and internal descriptions
* Identifying inactive configuration records

Looking up these values individually within the application can be inefficient, especially when reviewing many price types at once.

The goal was to create a simple administrative query that returns all important price type identifiers and configuration fields in one list.

## Data Source

The query reads from the Tessitura price type reference table:

```sql
dbo.TR_PRICE_TYPE
```

This table contains the primary configuration record for each ticket price type.

## Report Output

The query returns:

* Price Type ID
* Description
* Short Description
* Web Alias
* Price Type Category ID
* Price Type Group ID
* Status
* Attendance Category ID
* Benefit Requirement Indicator
* Pay-What-You-Wish Indicator

The most important field is **Price Type ID**, which can be used when researching ticket records or building other SQL reports.

## Web Alias

The `alias_description` field is presented as **Web Alias**.

This value may be used as an alternate customer-facing description in web sales or other configured Tessitura workflows.

A blank value is returned when no web alias has been configured.

## Active and Inactive Records

The query converts the underlying inactive indicator into a readable status:

* Active
* Inactive

Inactive records remain in the output because they may still be associated with historical ticket transactions.

Including both active and inactive records makes the query more useful for historical research and troubleshooting.

## Technical Approach

This is intentionally a straightforward reference query.

It focuses on:

* Clear column aliases
* Readable status values
* Null handling
* Whitespace cleanup
* Stable sorting
* Reusable configuration output

The results are sorted by status, description, and Price Type ID so that active records appear first and similarly named records remain easy to compare.

## SQL Techniques Demonstrated

* Reference-table querying
* `CASE` expressions
* `ISNULL`
* `NULLIF`
* `LTRIM`
* `RTRIM`
* Clean output aliases
* Configuration-data reporting
* Active and inactive record handling
* Reusable administrative query design

## Business Value

The query provides a quick configuration reference for ticketing, CRM, and reporting staff.

It can support:

* SQL report development
* Ticket transaction research
* Price type audits
* Web-sales troubleshooting
* Historical reporting
* Report parameter setup
* Data imports and exports
* Staff reference documentation

It also reduces the risk of using the wrong internal price type ID in another query or configuration task.

## Design Decisions

### Include Internal IDs

Internal IDs are included prominently because they are often the values required by SQL queries, report parameters, and system configuration.

### Preserve Inactive Records

Inactive price types are retained because historical ticket records may still reference them.

Excluding inactive records could make older transactions more difficult to interpret.

### Display Readable Status Values

The database indicator is translated into **Active** or **Inactive** so the output can be understood without knowledge of the underlying stored value.

### Retain Category and Group IDs

Price type category and group identifiers are included because they provide additional configuration context and may be useful when developing more detailed reports.

## Validation

The output was reviewed to confirm that:

* Price Type IDs matched the configured records
* Descriptions were displayed correctly
* Web aliases were returned when configured
* Category and group IDs were included
* Inactive records were clearly identified
* Blank optional values did not display as null
* Results were sorted consistently

The query produced the configuration reference needed for ticketing and reporting work.

## Skills Demonstrated

* Microsoft SQL Server
* T-SQL
* Tessitura CRM administration
* Reference-table exploration
* Configuration reporting
* Data cleanup
* Null handling
* Administrative utility development
* Reusable SQL design

## Project Status

**Completed and validated.**

This is a smaller administrative utility project intended to complement the portfolio’s more complex operational and analytical case studies.

## Privacy and Sanitization

The price type structure shown in this project contains system configuration information rather than customer data.

The public portfolio does not include:

* Customer information
* Ticket transactions
* Order data
* Internal server information
* Credentials
* Organization-specific query results

The SQL demonstrates the reusable query structure without publishing the organization’s configured price type list.
