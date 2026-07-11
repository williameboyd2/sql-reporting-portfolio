/*
    Project: Performance Schedule Export

    Purpose:
        Produce an Excel-friendly list of performances within a selected
        date range, with an optional venue filter and ticketing-specific
        scheduling notes.

    Portfolio note:
        Transactional results and organization-specific configuration
        values have been excluded. The keyword view name may be
        generalized for public presentation.
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT
    DATENAME(WEEKDAY, p.perf_dt) AS [Day of Week],

    CONVERT(
        varchar(10),
        CAST(p.perf_dt AS date),
        101
    ) AS [Performance Date],

    FORMAT(
        p.perf_dt,
        'h:mm tt'
    ) AS [Performance Time],

    ISNULL(
        p.perf_desc,
        p.perf_code
    ) AS [Performance Name],

    ISNULL(
        p.facility_desc,
        'Unknown'
    ) AS [Venue],

    ISNULL(
        p.perf_type_desc,
        ''
    ) AS [Performance Type],

    ISNULL(
        p.perf_status_desc,
        ''
    ) AS [Performance Status],

    ISNULL(
        scheduling.TicketingSchedulingNotes,
        ''
    ) AS [Ticketing Scheduling Notes]

FROM BI.VT_PERFORMANCE_DETAIL AS p

OUTER APPLY
(
    SELECT
        STUFF
        (
            (
                SELECT DISTINCT
                    ', ' + keywords.keyword

                FROM dbo.LV_ETL_VT_PERFORMANCE_KEYWORDS AS keywords

                WHERE keywords.perf_no = p.perf_no
                  AND keywords.category = 'ticketing_scheduling'

                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'),
            1,
            2,
            ''
        ) AS TicketingSchedulingNotes
) AS scheduling

WHERE p.perf_dt >= CAST(@StartDate AS date)

  -- The exclusive upper boundary includes all performance times
  -- occurring on the selected end date.
  AND p.perf_dt < DATEADD
  (
      DAY,
      1,
      CAST(@EndDate AS date)
  )

  -- Blank or zero returns all venues.
  AND
  (
      @FacilityNo IS NULL
      OR @FacilityNo = 0
      OR p.facility_no = @FacilityNo
  )

ORDER BY
    p.perf_dt,
    ISNULL(p.perf_desc, p.perf_code);
