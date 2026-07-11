/*
    Project:
        Possible Reseller Review

    Purpose:
        Identify customers whose ticket-purchasing activity for one
        selected performance may require additional staff review.

    Important:
        This query is a review tool. A returned result does not establish
        that a customer is a reseller or has committed fraud.

    Portfolio notes:
        - Customer results are not included.
        - Some customer and attribute column names have been generalized.
        - Replace generalized fields with the corresponding local BI fields.
        - In SSRS, the variables below would normally be report parameters.
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


/*==============================================================
    EXAMPLE REPORT PARAMETERS
==============================================================*/

DECLARE @PerfNo                  int     = 12345;
DECLARE @TicketLimit             int     = 4;
DECLARE @MinimumPerformanceCount int     = 3;
DECLARE @HomeState               char(2) = 'OH';


;WITH SelectedPerformanceTickets AS
(
    /*
        One row per customer and order for the selected performance.

        Status 3  = Seated, Paid
        Status 12 = Ticketed, Paid
    */
    SELECT
        od.customer_no,
        od.order_no,
        MIN(od.order_dt) AS order_dt,
        COUNT(*) AS active_ticket_count

    FROM BI.VT_ORDER_DETAIL AS od

    WHERE od.perf_no = @PerfNo
      AND od.line_type_desc = 'Perf'
      AND od.sli_status_no IN (3, 12)

    GROUP BY
        od.customer_no,
        od.order_no
),


SelectedOrderCounts AS
(
    /*
        Summarize the selected performance activity to one row
        per customer.
    */
    SELECT
        spt.customer_no,
        COUNT(*) AS active_order_count,
        SUM(spt.active_ticket_count) AS active_ticket_count,
        MAX(spt.active_ticket_count) AS largest_individual_order,
        MIN(spt.order_dt) AS first_order_dt,
        MAX(spt.order_dt) AS most_recent_order_dt

    FROM SelectedPerformanceTickets AS spt

    GROUP BY
        spt.customer_no
),


SelectedPerformanceSummary AS
(
    SELECT
        soc.customer_no,
        soc.active_ticket_count,
        soc.active_order_count,
        soc.largest_individual_order,
        soc.first_order_dt,
        soc.most_recent_order_dt

    FROM SelectedOrderCounts AS soc
),


CandidateCustomers AS
(
    /*
        Begin with customers who currently hold an active paid
        ticket for the selected performance.

        The final WHERE clause determines which customers have
        one or more review indicators.
    */
    SELECT
        sps.customer_no

    FROM SelectedPerformanceSummary AS sps
),


SelectedOrderList AS
(
    /*
        Produce a readable list showing how the selected-performance
        tickets are distributed across orders.
    */
    SELECT
        spt.customer_no,

        STRING_AGG
        (
            CAST
            (
                CONCAT
                (
                    'Order ',
                    spt.order_no,
                    ': ',
                    spt.active_ticket_count,
                    CASE
                        WHEN spt.active_ticket_count = 1
                            THEN ' ticket'
                        ELSE ' tickets'
                    END
                )
                AS nvarchar(max)
            ),
            N'; '
        ) WITHIN GROUP
        (
            ORDER BY
                spt.order_dt,
                spt.order_no
        ) AS selected_performance_order_details

    FROM SelectedPerformanceTickets AS spt

    GROUP BY
        spt.customer_no
),


FuturePerformanceDistinct AS
(
    /*
        Reduce upcoming activity to one row per customer and
        performance before calculating customer-level totals.
    */
    SELECT
        od.customer_no,
        od.perf_no,
        p.perf_dt,

        ISNULL
        (
            p.perf_desc,
            p.perf_code
        ) AS performance_name,

        ISNULL
        (
            p.facility_desc,
            'Unknown Venue'
        ) AS facility_name,

        COUNT(*) AS active_ticket_count

    FROM BI.VT_ORDER_DETAIL AS od

    INNER JOIN CandidateCustomers AS cc
        ON cc.customer_no = od.customer_no

    INNER JOIN BI.VT_PERFORMANCE_DETAIL AS p
        ON p.perf_no = od.perf_no

    WHERE od.line_type_desc = 'Perf'
      AND od.sli_status_no IN (3, 12)
      AND p.perf_dt >= CAST(GETDATE() AS date)

    GROUP BY
        od.customer_no,
        od.perf_no,
        p.perf_dt,
        ISNULL(p.perf_desc, p.perf_code),
        ISNULL(p.facility_desc, 'Unknown Venue')
),


FuturePerformanceSummary AS
(
    /*
        Calculate the number of distinct upcoming performances
        and create a readable performance list.
    */
    SELECT
        fpd.customer_no,
        COUNT(*) AS active_upcoming_performance_count,
        SUM(fpd.active_ticket_count) AS active_upcoming_ticket_count,

        STRING_AGG
        (
            CAST
            (
                CONCAT
                (
                    fpd.performance_name,
                    ' — ',
                    CONVERT(varchar(10), fpd.perf_dt, 101),
                    ' — ',
                    fpd.facility_name,
                    ' — ',
                    fpd.active_ticket_count,
                    CASE
                        WHEN fpd.active_ticket_count = 1
                            THEN ' ticket'
                        ELSE ' tickets'
                    END
                )
                AS nvarchar(max)
            ),
            N'; '
        ) WITHIN GROUP
        (
            ORDER BY
                fpd.perf_dt,
                fpd.performance_name
        ) AS upcoming_performance_list

    FROM FuturePerformanceDistinct AS fpd

    GROUP BY
        fpd.customer_no
),


RedFlagDistinct AS
(
    /*
        The production version reads the organization's configured
        customer-attribute value field.

        Replace attribute_value below with the appropriate local
        attribute or keyword-description column when necessary.
    */
    SELECT DISTINCT
        a.customer_no,
        LTRIM(RTRIM(a.attribute_value)) AS red_flag_attribute

    FROM BI.VT_ATTRIBUTE AS a

    INNER JOIN CandidateCustomers AS cc
        ON cc.customer_no = a.customer_no

    WHERE LTRIM(RTRIM(a.attribute_value)) IN
    (
        '3rd Party Seller',
        'Banned',
        'Fraud'
    )
),


RedFlagSummary AS
(
    /*
        Combine multiple applicable attributes into one
        customer-level value.
    */
    SELECT
        rfd.customer_no,
        COUNT(*) AS red_flag_attribute_count,

        STRING_AGG
        (
            CAST(rfd.red_flag_attribute AS nvarchar(max)),
            N'; '
        ) WITHIN GROUP
        (
            ORDER BY
                rfd.red_flag_attribute
        ) AS red_flag_attributes

    FROM RedFlagDistinct AS rfd

    GROUP BY
        rfd.customer_no
),


SelectedPerformance AS
(
    /*
        Retrieve the descriptive information for the performance
        being reviewed.
    */
    SELECT TOP (1)
        p.perf_no,

        ISNULL
        (
            p.perf_desc,
            p.perf_code
        ) AS performance_name,

        p.perf_dt,

        ISNULL
        (
            p.facility_desc,
            'Unknown Venue'
        ) AS facility_name

    FROM BI.VT_PERFORMANCE_DETAIL AS p

    WHERE p.perf_no = @PerfNo
),


CandidateBase AS
(
    /*
        Combine ticket activity, customer information, attributes,
        and upcoming-performance activity.

        The customer fields below are generalized for the public
        portfolio version.
    */
    SELECT
        sp.perf_no,
        sp.performance_name,
        sp.perf_dt,
        sp.facility_name,

        sps.customer_no,

        ISNULL
        (
            c.customer_name,
            CONCAT('Customer ', sps.customer_no)
        ) AS customer_name,

        ISNULL(c.email, '') AS email,

        CONCAT_WS
        (
            ', ',
            NULLIF(c.street1, ''),
            NULLIF(c.city, ''),
            NULLIF(c.state, ''),
            NULLIF(c.postal_code, '')
        ) AS mailing_address,

        NULLIF(LTRIM(RTRIM(c.state)), '') AS customer_state,

        sps.active_ticket_count,
        sps.active_order_count,
        sps.largest_individual_order,
        sps.first_order_dt,
        sps.most_recent_order_dt,

        @TicketLimit AS ticket_limit,

        ISNULL
        (
            sol.selected_performance_order_details,
            ''
        ) AS selected_performance_order_details,

        ISNULL
        (
            fps.active_upcoming_performance_count,
            0
        ) AS active_upcoming_performance_count,

        ISNULL
        (
            fps.active_upcoming_ticket_count,
            0
        ) AS active_upcoming_ticket_count,

        ISNULL
        (
            fps.upcoming_performance_list,
            ''
        ) AS upcoming_performance_list,

        ISNULL
        (
            rfs.red_flag_attribute_count,
            0
        ) AS red_flag_attribute_count,

        ISNULL
        (
            rfs.red_flag_attributes,
            ''
        ) AS red_flag_attributes

    FROM SelectedPerformanceSummary AS sps

    INNER JOIN BI.VT_CUSTOMER AS c
        ON c.customer_no = sps.customer_no

    CROSS JOIN SelectedPerformance AS sp

    LEFT JOIN SelectedOrderList AS sol
        ON sol.customer_no = sps.customer_no

    LEFT JOIN FuturePerformanceSummary AS fps
        ON fps.customer_no = sps.customer_no

    LEFT JOIN RedFlagSummary AS rfs
        ON rfs.customer_no = sps.customer_no
),


CandidateEvaluation AS
(
    /*
        Assign each review indicator independently so staff can
        understand exactly why the customer was returned.
    */
    SELECT
        cb.*,

        CASE
            WHEN cb.active_order_count > 1
                THEN 1
            ELSE 0
        END AS multiple_order_flag,

        CASE
            WHEN cb.active_order_count > 1
             AND cb.active_ticket_count > cb.ticket_limit
                THEN 1
            ELSE 0
        END AS ticket_limit_bypass_flag,

        CASE
            WHEN cb.red_flag_attribute_count > 0
                THEN 1
            ELSE 0
        END AS red_flag_attribute_flag,

        CASE
            WHEN cb.customer_state IS NOT NULL
             AND UPPER(cb.customer_state) <> UPPER(@HomeState)
             AND cb.active_upcoming_performance_count
                    >= @MinimumPerformanceCount
                THEN 1
            ELSE 0
        END AS out_of_state_activity_flag

    FROM CandidateBase AS cb
)


SELECT
    ce.perf_no AS [Performance Number],
    ce.performance_name AS [Performance Name],
    ce.perf_dt AS [Performance Date],
    ce.facility_name AS [Venue],

    ce.customer_no AS [Customer Number],
    ce.customer_name AS [Customer Name],
    ce.email AS [Email],
    ce.mailing_address AS [Mailing Address],

    ce.active_ticket_count AS [Active Tickets],
    ce.active_order_count AS [Active Orders],
    ce.largest_individual_order AS [Largest Individual Order],
    ce.ticket_limit AS [Ticket Limit],

    ce.first_order_dt AS [First Order Date],
    ce.most_recent_order_dt AS [Most Recent Order Date],

    ce.selected_performance_order_details
        AS [Selected Performance Order Details],

    ce.active_upcoming_performance_count
        AS [Active Upcoming Performances],

    ce.active_upcoming_ticket_count
        AS [Active Upcoming Tickets],

    ce.upcoming_performance_list
        AS [Upcoming Performance List],

    ce.red_flag_attributes
        AS [Red Flag Attributes],

    ce.multiple_order_flag
        AS [Multiple Order Flag],

    ce.ticket_limit_bypass_flag
        AS [Possible Ticket Limit Bypass Flag],

    ce.red_flag_attribute_flag
        AS [Red Flag Attribute Flag],

    ce.out_of_state_activity_flag
        AS [Out-of-State Activity Flag],

    ce.multiple_order_flag
        + ce.ticket_limit_bypass_flag
        + ce.red_flag_attribute_flag
        + ce.out_of_state_activity_flag
        AS [Risk Indicator Count],

    CONCAT_WS
    (
        '; ',

        CASE
            WHEN ce.multiple_order_flag = 1
                THEN CONCAT
                (
                    ce.active_order_count,
                    ' active orders for the selected performance'
                )
        END,

        CASE
            WHEN ce.ticket_limit_bypass_flag = 1
                THEN CONCAT
                (
                    ce.active_ticket_count,
                    ' active tickets across multiple orders exceed the ',
                    ce.ticket_limit,
                    '-ticket limit'
                )
        END,

        CASE
            WHEN ce.red_flag_attribute_flag = 1
                THEN CONCAT
                (
                    'Configured customer attribute: ',
                    ce.red_flag_attributes
                )
        END,

        CASE
            WHEN ce.out_of_state_activity_flag = 1
                THEN CONCAT
                (
                    'Customer state is ',
                    ce.customer_state,
                    ' and the account has active tickets for ',
                    ce.active_upcoming_performance_count,
                    ' upcoming performances'
                )
        END
    ) AS [Review Reasons]

FROM CandidateEvaluation AS ce

WHERE ce.multiple_order_flag = 1
   OR ce.red_flag_attribute_flag = 1
   OR ce.out_of_state_activity_flag = 1

ORDER BY
    (
        ce.multiple_order_flag
        + ce.ticket_limit_bypass_flag
        + ce.red_flag_attribute_flag
        + ce.out_of_state_activity_flag
    ) DESC,

    ce.active_ticket_count DESC,
    ce.customer_name;
