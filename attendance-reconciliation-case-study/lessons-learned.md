# Lessons Learned

## What I learned from this project

- Ticket history tables can overcount purchased tickets if historical rows are not filtered correctly.
- Matching report totals requires understanding the business rules behind the data, not just writing a query.
- Attendance scan date and performance date are not always the same thing.
- Voucher-style tickets require special handling because they may be sold for one event but redeemed at another.
- Complimentary admissions are more useful when broken out by reason.
- Validating SQL output against an existing production report is an important part of report development.

## Skills practiced

- SQL Server
- T-SQL
- Temporary tables
- Aggregate reporting
- Report validation
- Business rule analysis
- Data reconciliation
- Report design
