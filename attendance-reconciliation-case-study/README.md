# Attendance Reconciliation by Scan Date

## Business Problem
The standard attendance report did not fully answer the operational need for reconciling general admission events where voucher-style tickets could be redeemed across multiple performances.

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

## Sample Output

The final report returns:

| Ticket Category | Tickets Sold | Tickets Scanned | No Shows |
|---|---:|---:|---:|
| Standard | 304 | 282 | 22 |
| Student/Senior | 108 | 92 | 16 |
| Movie Strip | - | 301 | - |
| Single-Event Comp | 1 | - | 1 |
| General Comp | - | 1 | - |
| Development Comp | - | 21 | - |
| Donor Comp | - | 2 | - |
| Marketing Comp | - | 15 | - |
| Staff Comp | - | 2 | - |
| Voucher Comp | - | 28 | - |
| Volunteer | - | 8 | - |

| Total Tickets Sold | Total Tickets Scanned | Total No Shows |
|---:|---:|---:|
| 413 | 752 | 39 |

## Skills Demonstrated
- SQL Server
- T-SQL
- Data reconciliation
- CTEs and temporary tables
- Aggregate reporting
- Business rule validation
- Report design
- Tessitura/CRM reporting logic

## Project Status

Version 1.0 SQL logic completed.  
SSRS report layout and deployment pending.
