-- Attendance Reconciliation by Scan Date
-- Sanitized portfolio version
-- Demonstrates logic for reconciling:
-- 1. Tickets sold
-- 2. Tickets scanned
-- 3. No-shows
-- 4. Voucher admissions
-- 5. Complimentary admissions by reason

DECLARE @ScanDate DATE = 'YYYY-MM-DD';
DECLARE @FacilityNo INT = 000;

-- Step 1: Identify performances for the scan date/facility
-- Step 2: Pull valid sold tickets
-- Step 3: Pull scanned tickets by scan date
-- Step 4: Categorize ticket types and comp reasons
-- Step 5: Combine sold/scanned/no-show totals
-- Step 6: Return grand totals
