/*
    Performance Inventory Status Summary — Sanitized Portfolio Version

    Purpose:
        Returns a one-row inventory snapshot for a selected performance.

        Sold:
            Ticketed
            Reserved, Paid

        Shopping Cart:
            Locked
            Reserved, Unpaid

        Open:
            Available

        All other seat statuses are intentionally excluded.

    Before running:
        Replace the example performance number with a valid value from
        the target Tessitura environment.
*/

DECLARE @PerfNo INT = 10000; -- Example performance number

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT
    p.perf_no AS [Performance Number],
    p.perf_desc AS [Performance],
    p.perf_dt AS [Performance Date],

    SUM
    (
        CASE
            WHEN LTRIM(RTRIM(ss.description)) IN
                 (
                     'Ticketed',
                     'Reserved, Paid'
                 )
                THEN 1
            ELSE 0
        END
    ) AS [Sold],

    SUM
    (
        CASE
            WHEN LTRIM(RTRIM(ss.description)) IN
                 (
                     'Locked',
                     'Reserved, Unpaid'
                 )
                THEN 1
            ELSE 0
        END
    ) AS [Shopping Cart],

    SUM
    (
        CASE
            WHEN LTRIM(RTRIM(ss.description)) = 'Available'
                THEN 1
            ELSE 0
        END
    ) AS [Open],

    COUNT(*) AS [Total Included Inventory]

FROM dbo.TX_PERF_SEAT ps

INNER JOIN BI.VT_PERFORMANCE_DETAIL p
    ON p.perf_no = ps.perf_no

INNER JOIN dbo.TR_SEAT_STATUS ss
    ON ss.id = ps.seat_status

WHERE ps.perf_no = @PerfNo
  AND ps.pkg_no = 0
  AND LTRIM(RTRIM(ss.description)) IN
      (
          'Ticketed',
          'Reserved, Paid',
          'Locked',
          'Reserved, Unpaid',
          'Available'
      )

GROUP BY
    p.perf_no,
    p.perf_desc,
    p.perf_dt;

