# Attendance Reconciliation by Scan Date

## Business Problem
The standard attendance report did not fully answer our operational need for reconciling general admission events where voucher-style tickets could be redeemed across multiple performances.

## Goal
Build a report that shows:
- Tickets sold
- Tickets scanned
- No-shows
- Voucher admissions
- Complimentary admissions by reason
- Staff and volunteer admissions
- Grand totals

## Investigation
Initial testing showed that ticket history data overcounted purchased tickets. I compared SQL results against the standard attendance report and investigated the discrepancy.

## Key Findings
- Ticket history tables can contain multiple historical rows for the same ticket.
- Purchased ticket counts need to reflect current valid ticket state.
- Attendance scans need to be grouped by scan date, not just performance date.
- Complimentary admissions should be broken out by reason for operational clarity.

## Final Result
The final query matched the standard report’s purchased counts while adding scan-date reconciliation and comp-reason detail not available in the standard report.

## Skills Demonstrated
- SQL Server
- T-SQL
- Data reconciliation
- CTEs and temporary tables
- Aggregate reporting
- Business rule validation
- Report design
- Tessitura/CRM reporting logic
