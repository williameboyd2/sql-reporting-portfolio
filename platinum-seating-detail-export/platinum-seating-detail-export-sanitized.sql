/*
    Platinum Seating Detail Export — Sanitized Portfolio Version

    Purpose:
        Returns one row per seat currently assigned to a Platinum price zone.

        - Sold seats use the actual historical sold price by pricing layer.
        - Open and held seats use the current Platinum price by pricing layer.
        - Current inventory is simplified to Sold, Hold, or Open.
        - Blank renter-entry columns are included for requested changes.

    Before running:
        Replace the example performance number and Platinum price type ID
        with valid values from the target Tessitura environment.
*/

DECLARE @PerfNo INT = 10000;                 -- Example performance number
DECLARE @AsOfDate DATETIME = GETDATE();
DECLARE @PlatinumPriceTypeNo SMALLINT = 999; -- Example configuration ID

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


/*==============================================================
  CURRENT PLATINUM PRICE BY ZONE

  Used for seats that are currently open or held.

  Included layers:
      Single Ticket
      Facility Fee
      Platinum Lift
==============================================================*/

WITH CurrentPriceRows AS
(
    SELECT
        pp.zone_no,
        plt.description AS price_layer,

        CAST
        (
            COALESCE(pe.price, pp.start_price)
            AS MONEY
        ) AS current_price

    FROM dbo.T_PERF_PRICE pp

    INNER JOIN dbo.T_PERF_PRICE_TYPE ppt
        ON ppt.id = pp.perf_price_type

    INNER JOIN dbo.T_PERF_PRICE_LAYER ppl
        ON ppl.id = ppt.perf_price_layer

    INNER JOIN dbo.TR_PRICE_LAYER_TYPE plt
        ON plt.id = ppl.price_layer_type

    OUTER APPLY
    (
        SELECT TOP (1)
            pe1.price,
            pe1.enabled,
            pe1.start_dt

        FROM dbo.T_PRICE_EVENT pe1

        WHERE pe1.perf_price_no = pp.id
          AND pe1.start_dt <= @AsOfDate

        ORDER BY
            pe1.start_dt DESC,
            pe1.id DESC
    ) pe

    WHERE ppl.perf_no = @PerfNo
      AND ppt.price_type = @PlatinumPriceTypeNo
      AND plt.description IN
      (
          'Single Ticket',
          'Facility Fee',
          'Platinum Lift'
      )
),


/*==============================================================
  TURN THE THREE PRICE-LAYER ROWS INTO ONE ROW PER ZONE
==============================================================*/

CurrentPriceByZone AS
(
    SELECT
        zone_no,

        MAX
        (
            CASE
                WHEN price_layer = 'Single Ticket'
                THEN current_price
            END
        ) AS base_price,

        MAX
        (
            CASE
                WHEN price_layer = 'Facility Fee'
                THEN current_price
            END
        ) AS facility_fee,

        MAX
        (
            CASE
                WHEN price_layer = 'Platinum Lift'
                THEN current_price
            END
        ) AS platinum_lift

    FROM CurrentPriceRows

    GROUP BY
        zone_no
),


/*==============================================================
  ACTUAL SOLD PRICE BY INDIVIDUAL SEAT

  Sold seats use the actual amount charged at the time of sale
  rather than the price currently configured on the performance.
==============================================================*/

SoldPriceBySeat AS
(
    SELECT
        d.perf_no,
        d.seat_no,
        d.sli_no,
        d.order_no,

        MAX(d.price_type_no) AS sold_price_type_no,
        MAX(d.price_type_desc) AS sold_price_type,

        SUM
        (
            CASE
                WHEN d.detail_price_layer_type_desc = 'Single Ticket'
                THEN ISNULL(d.detail_due_amt, 0)
                ELSE 0
            END
        ) AS sold_base_price,

        SUM
        (
            CASE
                WHEN d.detail_price_layer_type_desc = 'Facility Fee'
                THEN ISNULL(d.detail_due_amt, 0)
                ELSE 0
            END
        ) AS sold_facility_fee,

        SUM
        (
            CASE
                WHEN d.detail_price_layer_type_desc = 'Platinum Lift'
                THEN ISNULL(d.detail_due_amt, 0)
                ELSE 0
            END
        ) AS sold_platinum_lift

    FROM BI.VT_ORDER_DETAIL_AT_PRICE_LAYER d

    WHERE d.perf_no = @PerfNo
      AND d.seat_no IS NOT NULL
      AND d.detail_price_layer_type_desc IN
      (
          'Single Ticket',
          'Facility Fee',
          'Platinum Lift'
      )

    GROUP BY
        d.perf_no,
        d.seat_no,
        d.sli_no,
        d.order_no
)


/*==============================================================
  FINAL RESULT

  One row per individual Platinum seat.
==============================================================*/

SELECT
    p.perf_no AS [Performance Number],
    p.perf_desc AS [Performance],
    p.perf_dt AS [Performance Date],

    ISNULL(sec.description, '') AS [Section],
    LTRIM(RTRIM(s.seat_row)) AS [Row],
    LTRIM(RTRIM(s.seat_num)) AS [Seat],

    LTRIM(RTRIM(z.description)) AS [Price Zone],


    /* Simplified renter-facing inventory status */

    CASE
        WHEN ps.sli_no IS NOT NULL
            THEN 'Sold'

        WHEN hc.hc_no IS NOT NULL
            THEN 'Hold'

        WHEN ps.seat_status = 0
             OR LTRIM(RTRIM(ISNULL(ss.description, ''))) = 'Available'
            THEN 'Open'

        ELSE LTRIM(RTRIM(ISNULL(ss.description, 'Other')))
    END AS [Status],


    /* Cleaned Tessitura status */

    CASE
        WHEN LTRIM(RTRIM(ISNULL(ss.description, ''))) IN
             (
                 'Ticketed',
                 'Reserved, Paid'
             )
            THEN 'Sold'

        ELSE LTRIM(RTRIM(ISNULL(ss.description, '')))
    END AS [Tessitura Status],


    /* Price type */

    CASE
        WHEN ps.sli_no IS NOT NULL
             AND sp.sli_no IS NOT NULL
            THEN ISNULL(sp.sold_price_type, '')

        ELSE 'Platinum'
    END AS [Price Type],


    /* Base ticket price */

    CAST
    (
        CASE
            WHEN ps.sli_no IS NOT NULL
                 AND sp.sli_no IS NOT NULL
                THEN sp.sold_base_price

            ELSE cp.base_price
        END
        AS MONEY
    ) AS [Base Price],


    /* Facility fee */

    CAST
    (
        CASE
            WHEN ps.sli_no IS NOT NULL
                 AND sp.sli_no IS NOT NULL
                THEN sp.sold_facility_fee

            ELSE cp.facility_fee
        END
        AS MONEY
    ) AS [Facility Fee],


    /* Platinum lift */

    CAST
    (
        CASE
            WHEN ps.sli_no IS NOT NULL
                 AND sp.sli_no IS NOT NULL
                THEN sp.sold_platinum_lift

            ELSE cp.platinum_lift
        END
        AS MONEY
    ) AS [Platinum Lift],


    /* Total ticket price */

    CAST
    (
          ISNULL
          (
              CASE
                  WHEN ps.sli_no IS NOT NULL
                       AND sp.sli_no IS NOT NULL
                      THEN sp.sold_base_price

                  ELSE cp.base_price
              END,
              0
          )

        + ISNULL
          (
              CASE
                  WHEN ps.sli_no IS NOT NULL
                       AND sp.sli_no IS NOT NULL
                      THEN sp.sold_facility_fee

                  ELSE cp.facility_fee
              END,
              0
          )

        + ISNULL
          (
              CASE
                  WHEN ps.sli_no IS NOT NULL
                       AND sp.sli_no IS NOT NULL
                      THEN sp.sold_platinum_lift

                  ELSE cp.platinum_lift
              END,
              0
          )

        AS MONEY
    ) AS [Total Ticket Price],


    /*==========================================================
      BLANK COLUMNS FOR THE RENTER TO COMPLETE
    ==========================================================*/

    CAST('' AS VARCHAR(30)) AS [Requested Status],

    CAST('' AS VARCHAR(20)) AS [Requested Hold Code],

    CAST(NULL AS DECIMAL(12, 2))
        AS [Requested Total Ticket Price],

    CAST('' AS VARCHAR(500)) AS [Renter Notes]


FROM dbo.TX_PERF_SEAT ps

INNER JOIN BI.VT_PERFORMANCE_DETAIL p
    ON p.perf_no = ps.perf_no

INNER JOIN dbo.T_SEAT s
    ON s.seat_no = ps.seat_no

LEFT JOIN dbo.TR_SECTION sec
    ON sec.id = s.section

INNER JOIN dbo.T_ZONE z
    ON z.zmap_no = ps.zmap_no
   AND z.zone_no = ps.zone_no

LEFT JOIN dbo.TR_SEAT_STATUS ss
    ON ss.id = ps.seat_status

LEFT JOIN CurrentPriceByZone cp
    ON cp.zone_no = ps.zone_no

LEFT JOIN SoldPriceBySeat sp
    ON sp.perf_no = ps.perf_no
   AND sp.seat_no = ps.seat_no
   AND sp.sli_no = ps.sli_no


/*==============================================================
  FIND THE CURRENT ACTIVE HOLD CODE FOR STATUS DETERMINATION

  Hold details are used internally but are not displayed.
==============================================================*/

OUTER APPLY
(
    SELECT TOP (1)
        h.hc_no

    FROM dbo.TX_PERF_HC phc

    INNER JOIN dbo.T_HC h
        ON h.hc_no = phc.hc_no

    WHERE phc.perf_no = ps.perf_no
      AND phc.seat_no = ps.seat_no

      AND
      (
          phc.start_dt IS NULL
          OR phc.start_dt <= @AsOfDate
      )

      AND
      (
          phc.end_dt IS NULL
          OR phc.end_dt > @AsOfDate
      )

    ORDER BY
        phc.priority
) hc


/*==============================================================
  ONLY INDIVIDUAL SEATS CURRENTLY ASSIGNED TO PLATINUM ZONES
==============================================================*/

WHERE ps.perf_no = @PerfNo
  AND ps.pkg_no = 0
  AND ISNULL(s.is_seat, 1) = 1

  AND
  (
       LOWER(ISNULL(z.description, '')) LIKE '%plat%'
    OR LOWER(ISNULL(z.short_desc, '')) LIKE '%plat%'
    OR LOWER(ISNULL(z.abbrev, '')) LIKE '%plat%'
  )


/*==============================================================
  SEATING ORDER
==============================================================*/

ORDER BY
    ISNULL(sec.description, ''),
    ps.logical_seat_row,
    ps.logical_seat_num,
    s.seat_row,
    s.seat_num;
