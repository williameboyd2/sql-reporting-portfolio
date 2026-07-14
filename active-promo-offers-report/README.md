# Active Promo Offers Report

## Project Overview

The Active Promo Offers Report is a T-SQL administrative audit that consolidates current promotional offers configured through two different Tessitura setup methods:

* Pricing Rules
* Mode of Sale Offers

The report produces one readable row per promo code and source number, combining related offer configuration, applicable performances, discounted price types, sales channels, date ranges, limits, and descriptive terms.

## Business Problem

Promotional offers can be configured in different areas of the CRM. Staff reviewing an active promo code may otherwise need to inspect several configuration screens and manually determine:

* Whether the offer is currently active
* Which setup method created it
* Which performances or productions it applies to
* Which discounted price type it unlocks
* Which sales channels can use it
* Whether it has maximum-seat or date restrictions
* Whether multiple records belong to the same public promo code

The goal was to create one administrative report that brings those details together and presents them in business-friendly language.

## Report Timing

The query evaluates offers as of the time it is run.

An offer is treated as current when:

* Its start date is blank or has already occurred
* Its end date is blank or has not passed
* The associated source remains active
* Its applicable performances are current or future performances

Open-ended offers remain visible even when no end date is configured.

## Two Offer-Setup Methods

### Pricing Rules

The pricing-rule portion retrieves active discount and price-type actions connected to web sources.

It interprets common rule structures into readable descriptions such as:

* Percentage discounts
* Fixed-dollar discounts
* Buy-one-get-one offers
* Offers that apply a configured price type

Pricing rules may identify individual performances, production seasons, or both.

### Mode of Sale Offers

The mode-of-sale portion retrieves current offers that connect a source to:

* A performance or package
* A discounted price type
* A sales channel
* Start and end dates
* Maximum-seat restrictions
* Configured terms

Both setup methods are normalized into a shared structure before the final aggregation.

## Performance Applicability

The report converts internal performance and production-season identifiers into readable applicability descriptions.

When every remaining performance in a production is included, the output summarizes the offer as valid for all performances of that production. Otherwise, the report lists the individual eligible performances and dates.

This prevents staff from having to interpret comma-separated internal identifiers.

## Report Output

The final report includes:

* Offer setup type
* Setup numbers
* Offer name
* Offer type
* Rule category
* Promo code
* Source number
* Offer description
* Valid-for description
* Start date
* End date
* Maximum seats
* Discounted price type
* Sales channels

Blank display values are replaced with a hyphen so the report remains readable when optional configuration is not present.

## Technical Approach

The query uses a series of common table expressions to separate the process into logical stages:

1. Retrieve active pricing rules and their associated sources.
2. Parse comma-separated performance and production-season identifiers with `STRING_SPLIT`.
3. Expand production seasons to their current and future performances.
4. Retrieve active mode-of-sale offers.
5. Normalize both configuration methods into one shared structure.
6. Determine whether an offer covers all remaining performances of a production.
7. Deduplicate descriptive values before aggregation.
8. Combine related values using ordered `STRING_AGG`.
9. Return one administrative summary row per promo code and source number.

## SQL Techniques Demonstrated

* Parameterized date evaluation
* Common table expressions
* Multi-source configuration analysis
* `STRING_SPLIT`
* `STRING_AGG`
* `CROSS APPLY`
* Conditional business logic
* Current and future date filtering
* Identifier-to-description translation
* Production-level coverage calculations
* Deduplication before aggregation
* Null handling
* Human-readable administrative output

## Validation

The report was tested against current promotional configurations and reviewed to confirm that:

* Active pricing rules were included
* Active mode-of-sale offers were included
* Expired configurations were excluded
* Inactive sources were excluded
* Promo codes were grouped correctly by source number
* Performance and production applicability was translated correctly
* Full-production coverage was identified correctly
* Discounted price types and sales channels were combined without duplication
* Open-ended offers displayed correctly
* Displayed null values were replaced with hyphens

## Business Value

The report provides ticketing, marketing, and CRM staff with a centralized audit of active promotional offers.

It can support:

* Promo-code troubleshooting
* Offer expiration review
* On-sale preparation
* Marketing campaign verification
* Discount and price-type audits
* Sales-channel review
* Cleanup of outdated or duplicate configuration
* Staff reference documentation

## Project Status

**SQL logic completed and validated.**

The query is designed as an administrative SQL report and can be adapted for SSRS or scheduled delivery if recurring distribution is needed.

## Privacy and Sanitization

The public portfolio version contains query logic only.

It does not include customer data, transaction results, credentials, internal server names, real promo codes, organization-specific exclusions, or proprietary offer output.

## Files

* [`active-promo-offers-report-sanitized.sql`](active-promo-offers-report-sanitized.sql) — generalized portfolio version of the completed query

