/*
    Project:
        Historical Ticket Pricing Analysis

    Purpose:
        Compare ticket sales, ticket-price revenue, average ticket
        value, and purchasing behavior across multiple production
        seasons of a recurring production.

    Portfolio notes:
        - Production-season IDs have been generalized.
        - Customer and transactional results are not included.
        - Fees are excluded by limiting the source records to the
          Ticket Price category.
        - Replace the example production-season IDs with valid
          local values before executing the query.
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


/*==============================================================
    SELECTED PRODUCTION SEASONS

    The validated internal report compared three production seasons.
    The values below are fictional portfolio examples.
==============================================================*/

DECLARE @ProductionSeasons TABLE
(
    prod_season_no int PRIMARY KEY
);

INSERT INTO @ProductionSeasons
(
    prod_season_no
)
VALUES
    (1001),
    (1002),
    (1003);


/*==============================================================
    TICKET BASE

    Consolidate the qualifying price-layer rows into one record
    per ticket, order, production season, and price zone.

    Filtering detail_price_category_desc to Ticket Price excludes
    fees and other non-ticket components.
==============================================================*/

;WITH TicketBase AS
(
    SELECT
        d.prod_season_no,
        d.prod_season_desc,

        d.ticket_no,
        d.order_no,

        d.zone_no,

        ISNULL
        (
            NULLIF(LTRIM(RTRIM(d.zone_desc)), ''),
            'Unknown Price Zone'
        ) AS zone_desc,

        SUM
        (
            CAST
            (
                ISNULL(d.detail_paid_amt, 0)
                AS decimal(19, 4)
            )
        ) AS ticket_paid_amount

    FROM BI.VT_ORDER_DETAIL_AT_PRICE_LAYER AS d

    INNER JOIN @ProductionSeasons AS selected_season
        ON selected_season.prod_season_no = d.prod_season_no

    WHERE d.ticket_no IS NOT NULL
      AND d.detail_price_category_desc = 'Ticket Price'

    GROUP BY
        d.prod_season_no,
        d.prod_season_desc,
        d.ticket_no,
        d.order_no,
        d.zone_no,

        ISNULL
        (
            NULLIF(LTRIM(RTRIM(d.zone_desc)), ''),
            'Unknown Price Zone'
        )
),


/*==============================================================
    PRICE-ZONE BREAKDOWN

    Calculate the ticket, order, revenue, and average metrics for
    each production season and price zone.
==============================================================*/

ZoneBreakdown AS
(
    SELECT
        tb.prod_season_no,
        tb.prod_season_desc,
        tb.zone_no,
        tb.zone_desc,

        COUNT(*) AS tickets_sold,

        COUNT
        (
            DISTINCT tb.order_no
        ) AS orders,

        CAST
        (
            COUNT(*) * 1.0
            /
            NULLIF
            (
                COUNT(DISTINCT tb.order_no),
                0
            )
            AS decimal(12, 2)
        ) AS avg_tickets_per_order,

        SUM
        (
            tb.ticket_paid_amount
        ) AS gross_paid_amount,

        CAST
        (
            SUM(tb.ticket_paid_amount)
            /
            NULLIF(COUNT(*), 0)
            AS decimal(19, 2)
        ) AS avg_paid_per_ticket_in_zone

    FROM TicketBase AS tb

    GROUP BY
        tb.prod_season_no,
        tb.prod_season_desc,
        tb.zone_no,
        tb.zone_desc
),


/*==============================================================
    PRODUCTION-SEASON TOTALS

    Calculate the same primary metrics across all price zones for
    each production season.
==============================================================*/

YearTotals AS
(
    SELECT
        tb.prod_season_no,
        tb.prod_season_desc,

        COUNT(*) AS total_tickets_sold_for_year,

        COUNT
        (
            DISTINCT tb.order_no
        ) AS total_orders_for_year,

        CAST
        (
            COUNT(*) * 1.0
            /
            NULLIF
            (
                COUNT(DISTINCT tb.order_no),
                0
            )
            AS decimal(12, 2)
        ) AS avg_tickets_per_order_for_year,

        SUM
        (
            tb.ticket_paid_amount
        ) AS total_gross_paid_for_year,

        CAST
        (
            SUM(tb.ticket_paid_amount)
            /
            NULLIF(COUNT(*), 0)
            AS decimal(19, 2)
        ) AS overall_avg_paid_per_ticket_for_year

    FROM TicketBase AS tb

    GROUP BY
        tb.prod_season_no,
        tb.prod_season_desc
)


/*==============================================================
    FINAL REPORT OUTPUT

    Money fields are formatted in the final SELECT so the values
    display as currency while the CTE calculations remain numeric.
==============================================================*/

SELECT
    zb.prod_season_no
        AS [Production Season ID],

    zb.prod_season_desc
        AS [Production Season],

    zb.zone_no
        AS [Price Zone ID],

    zb.zone_desc
        AS [Price Zone],

    zb.tickets_sold
        AS [Tickets Sold],

    zb.orders
        AS [Orders],

    zb.avg_tickets_per_order
        AS [Average Tickets per Order],

    FORMAT
    (
        zb.gross_paid_amount,
        'C',
        'en-US'
    ) AS [Gross Ticket Revenue],

    FORMAT
    (
        zb.avg_paid_per_ticket_in_zone,
        'C',
        'en-US'
    ) AS [Average Paid per Ticket in Zone],

    yt.total_tickets_sold_for_year
        AS [Total Tickets Sold for Year],

    yt.total_orders_for_year
        AS [Total Orders for Year],

    yt.avg_tickets_per_order_for_year
        AS [Average Tickets per Order for Year],

    FORMAT
    (
        yt.total_gross_paid_for_year,
        'C',
        'en-US'
    ) AS [Total Gross Ticket Revenue for Year],

    FORMAT
    (
        yt.overall_avg_paid_per_ticket_for_year,
        'C',
        'en-US'
    ) AS [Overall Average Paid per Ticket for Year]

FROM ZoneBreakdown AS zb

INNER JOIN YearTotals AS yt
    ON yt.prod_season_no = zb.prod_season_no

ORDER BY
    zb.prod_season_desc,
    zb.zone_no,
    zb.zone_desc;
