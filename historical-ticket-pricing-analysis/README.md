# Historical Ticket Pricing Analysis

## Project Overview

The Historical Ticket Pricing Analysis is a T-SQL report that compares ticket sales and purchasing behavior across multiple production seasons of a recurring annual production.

The report summarizes ticket volume, revenue, average ticket price, order volume, and average tickets purchased per order for each seating price zone.

It also provides production-season totals so that users can compare individual price zones with the overall results for each year.

## Business Problem

When preparing pricing for an upcoming production season, the ticketing team needed a concise view of how previous years had performed.

Existing reports contained much of the underlying sales information, but they did not present the historical data in the structure needed for pricing analysis.

The team needed to answer questions such as:

* How many tickets were sold in each price zone?
* How much ticket revenue was generated in each zone?
* What was the average amount paid per ticket?
* How many orders included tickets in each zone?
* How many tickets did customers purchase per order?
* How did each price zone compare with the overall production season?
* How did purchasing behavior change across multiple years?

The analysis was created to provide a practical historical reference for future pricing discussions.

## Scope

The validated analysis compared three production seasons of the same recurring production.

The public portfolio version uses generalized production-season identifiers rather than the organization's internal values.

The report focuses specifically on ticket-price revenue. Fees and other non-ticket price components are excluded.

## Data Source

The query uses a reporting view containing order-detail information at the individual price-layer level.

This view provides the fields needed to connect:

* Production seasons
* Tickets
* Orders
* Price zones
* Price categories
* Paid amounts

Because one ticket may be represented by multiple price-layer records, the query first consolidates the qualifying records into one ticket-level result before calculating totals.

## Fee Exclusion

The report filters the price-layer records to:

```sql
detail_price_category_desc = 'Ticket Price'
```

This excludes service charges, facility fees, delivery charges, and other non-ticket price components from the revenue calculations.

As a result, the report reflects the amount paid for the ticket itself rather than the total order cost.

## Report Output

The final output includes the following price-zone metrics:

* Production Season ID
* Production Season
* Price Zone ID
* Price Zone
* Tickets Sold
* Orders
* Average Tickets per Order
* Gross Ticket Revenue
* Average Paid per Ticket in Zone

The report also includes production-season totals:

* Total Tickets Sold for Year
* Total Orders for Year
* Average Tickets per Order for Year
* Total Gross Ticket Revenue for Year
* Overall Average Paid per Ticket for Year

Currency fields are formatted as U.S. currency in the final presentation output.

## Technical Approach

The query uses three common table expressions to separate the analysis into logical stages.

### TicketBase

The first common table expression consolidates the source data into one row per:

* Production season
* Ticket
* Order
* Price zone

The paid ticket-price components are summed at the ticket level.

This prevents a ticket with more than one applicable price-layer record from being counted as multiple tickets.

Records without a ticket number are excluded.

### ZoneBreakdown

The second common table expression groups the ticket-level records by production season and price zone.

It calculates:

* Ticket count
* Distinct order count
* Average tickets per order
* Gross ticket revenue
* Average paid per ticket

The average tickets-per-order metric is calculated using the number of tickets divided by the number of distinct orders represented in the price zone.

### YearTotals

The third common table expression summarizes all qualifying tickets within each production season.

It calculates the same core measures at the full-year level:

* Total tickets
* Total distinct orders
* Average tickets per order
* Total ticket revenue
* Overall average paid per ticket

### Final Output

The price-zone results are joined to the production-season totals.

This allows each row to show both:

* The performance of one individual price zone
* The overall performance of the production season

## Calculation Definitions

### Tickets Sold

The number of consolidated ticket records represented in the grouping.

### Orders

The number of distinct orders containing at least one qualifying ticket in the grouping.

### Average Tickets per Order

```text
Tickets Sold ÷ Distinct Orders
```

This metric provides insight into how many tickets were typically purchased together.

The metric is calculated separately for each price zone and for the production season overall.

### Gross Ticket Revenue

The sum of the paid amounts associated specifically with the ticket-price category.

Fees are not included.

### Average Paid per Ticket

```text
Gross Ticket Revenue ÷ Tickets Sold
```

The report calculates this measure for each price zone and for the production season overall.

## SQL Techniques Demonstrated

* Microsoft SQL Server
* T-SQL
* Common table expressions
* Ticket-level data consolidation
* Multi-level aggregation
* `COUNT`
* `COUNT DISTINCT`
* `SUM`
* `NULLIF`
* Decimal conversion
* Currency formatting
* Price-layer analysis
* Production-season comparisons
* Price-zone reporting
* Order-level purchasing analysis
* Financial reporting
* Exclusion of non-ticket revenue
* Defensive divide-by-zero handling

## Validation

The results were reviewed against the underlying production-season sales data.

Validation focused on confirming that:

* Only the selected production seasons were included
* Each ticket was counted once
* Fees were excluded
* Price zones matched the configured seating zones
* Ticket counts were grouped correctly by season and zone
* Distinct order counts were accurate
* Average tickets per order used order count rather than household count
* Revenue fields reflected paid ticket amounts
* Year-level totals matched the sum of the price-zone results
* Currency fields displayed correctly

The completed output was confirmed to provide the historical comparison needed for pricing review.

## Design Decisions

### Price Zones Rather Than Individual Price Types

The analysis groups tickets by seating price zone because those zones represented the pricing tiers used in the business discussion.

Price types may describe customer eligibility or discount categories, while price zones describe the seating and pricing structure being evaluated.

### Average per Order

Average tickets per order was selected as the purchasing-behavior metric.

This provides a consistent, transaction-based measure and avoids additional assumptions that would be required for a household-level calculation.

### Ticket Revenue Rather Than Total Order Revenue

The analysis intentionally excludes fees.

This makes comparisons between seasons more meaningful because the results focus on the price paid for admission rather than changes in service charges or other order components.

### Separate Numeric Calculations and Display Formatting

The common table expressions retain numeric values for calculations.

Currency formatting is applied only in the final output, preserving the accuracy of the underlying aggregations.

## Business Value

The report provides a concise historical reference for future pricing decisions.

It allows ticketing and management teams to evaluate:

* Which price zones sold the most tickets
* Which zones generated the most revenue
* Differences in average ticket value
* Customer purchasing volume by order
* Changes in ticket-buying behavior between years
* The relationship between individual pricing tiers and overall results

The same query structure can be reused for other recurring productions by changing the selected production-season values.

## Skills Demonstrated

* Microsoft SQL Server
* T-SQL
* Tessitura CRM reporting
* Ticketing revenue analysis
* Price-zone analysis
* Historical sales comparisons
* Order behavior analysis
* Business requirements gathering
* Financial aggregation
* Data validation
* Reusable query design
* Translating pricing questions into measurable report output

## Project Status

**SQL logic completed and validated.**

The query successfully produced ticket counts, order averages, ticket revenue, and average ticket prices by price zone and production season.

## Privacy and Sanitization

The public portfolio version does not contain:

* Customer information
* Order-level results
* Actual ticket numbers
* Internal server information
* Credentials
* Transactional exports
* Internal production-season identifiers
* Proprietary revenue totals

Example production-season values are used in the SQL file. These values must be replaced with the appropriate local identifiers before the query is executed.
