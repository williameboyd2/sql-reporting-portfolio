# Platinum Seating Detail Export

## Project Overview

The Platinum Seating Detail Export is a parameterized T-SQL report designed to produce a seat-level inventory and pricing worksheet for performances using Platinum or dynamically priced seating zones.

The report combines current seat inventory with two different pricing perspectives:

* **Sold seats** use the actual historical price charged at the time of sale.
* **Open and held seats** use the current configured Platinum price.

The output is designed for operational use and includes blank request fields that a renter or presenting partner can complete when requesting inventory or pricing changes.

## Business Problem

Platinum inventory can change throughout an event's sales cycle. A useful worksheet needs to answer several questions at the individual-seat level:

* Which seats are currently assigned to a Platinum price zone?
* Is each seat sold, held, or open?
* What price was actually charged for a sold seat?
* What is the current configured price for an unsold seat?
* How much of the ticket price is base price, facility fee, and Platinum lift?
* What changes is the renter requesting?

A simple current-price query does not accurately represent sold inventory because prices may have changed after the sale. A simple sales query also does not provide current pricing for seats that remain open or held.

The goal was to combine both views into one clean export.

## Report Parameters

The query uses:

* **Performance Number** — the selected performance
* **Platinum Price Type ID** — the configured Platinum price type in the target Tessitura environment

## Report Output

The final report returns one row per individual seat currently assigned to a Platinum price zone.

The output includes:

* Performance number
* Performance name
* Performance date
* Section
* Row
* Seat
* Price zone
* Simplified status
* Tessitura status
* Price type
* Base price
* Facility fee
* Platinum lift
* Total ticket price
* Requested status
* Requested hold code
* Requested total ticket price
* Renter notes

## Status Logic

The operational status is simplified into three primary values:

* **Sold** — the seat is assigned to an active ticket line item
* **Hold** — the seat has a current active hold code
* **Open** — the seat is available and not sold or held

The report also retains a cleaned Tessitura status for additional context. Tessitura values such as `Ticketed` and `Reserved, Paid` are displayed as `Sold` to make the export easier for non-technical users to interpret.

## Technical Approach

### Current Platinum Price by Zone

The first common table expression retrieves the current configured price for each Platinum zone and pricing layer.

It evaluates the latest applicable price event as of the report run time using `OUTER APPLY` and falls back to the starting price when no later price event is available.

The included price layers are:

* Single Ticket
* Facility Fee
* Platinum Lift

A second common table expression pivots those layer rows into one price record per zone.

### Historical Sold Price by Seat

Sold seats use historical order-detail data at the pricing-layer level.

The query groups the actual charged amounts by performance, seat, line item, and order. It separately calculates:

* Sold base price
* Sold facility fee
* Sold Platinum lift

This prevents later price changes from overwriting the amount that was actually charged when the seat was sold.

### Current Seat Inventory

The final query begins with the performance-seat inventory and joins seating, section, zone, and seat-status reference data.

Only individual seats currently assigned to a zone whose configured name identifies it as Platinum are included.

### Active Hold Identification

An `OUTER APPLY` retrieves the current active hold for each seat based on the hold's start and end dates.

Hold information is used to determine operational status, but detailed internal hold data is not exposed in the renter-facing output.

### Renter Request Fields

The export includes intentionally blank columns for:

* Requested status
* Requested hold code
* Requested total ticket price
* Renter notes

These fields turn the SQL output into a working inventory-change document rather than a read-only report.

## Key Design Decisions

### Historical Pricing for Sold Seats

Sold inventory must reflect the amount charged at the time of sale, not the price currently configured for that zone.

Using pricing-layer order detail preserves the historical base price, fee, and Platinum lift.

### Current Pricing for Open and Held Seats

Unsold inventory does not have historical sales detail. The report therefore uses the latest applicable configured price event for those seats.

### One Row per Seat

A seat-level result allows operations staff and renters to identify exact inventory and requested changes without relying on aggregate totals.

### Simplified External Output

Internal fields such as order number, line-item number, seat-number keys, hold priority, detailed hold descriptions, and price-source diagnostics were useful during development but removed from the final renter-facing export.

## SQL Techniques Demonstrated

* Parameterized T-SQL
* Common table expressions
* `OUTER APPLY`
* Effective-date price selection
* Current and historical data reconciliation
* Pricing-layer aggregation
* Conditional status logic
* Seat-level inventory reporting
* Null handling
* Financial calculations
* Operational output design
* Data sanitization

## Validation

The report was tested on a selected performance containing sold, held, and open Platinum inventory.

Validation confirmed that:

* Each qualifying seat appeared once
* Sold seats used historical charged amounts
* Open and held seats used current configured prices
* Base price, facility fee, and Platinum lift combined into the total ticket price
* Active holds were identified correctly
* Ticketed and paid Tessitura statuses were presented as sold
* Internal diagnostic fields were excluded from the final renter-facing output

## Business Value

The report creates a single worksheet for reviewing Platinum inventory and communicating requested changes.

It reduces manual research across seat maps, orders, price events, holds, and pricing layers while preserving the difference between historical sold pricing and current unsold pricing.

## Project Status

**SQL logic completed and validated.**

The query is currently designed as an Excel-oriented operational export. An SSRS version may be developed later if recurring report delivery is needed.

## Privacy and Sanitization

The public portfolio version contains query logic only.

It does not include:

* Customer information
* Actual order or line-item numbers
* Transactional results
* Internal server names
* Credentials
* Organization-specific performance numbers
* Organization-specific configuration IDs

Example parameter values must be replaced with valid values from the target Tessitura environment.

## Files

* [`platinum-seating-detail-export-sanitized.sql`](platinum-seating-detail-export-sanitized.sql) — generalized portfolio version of the completed query
