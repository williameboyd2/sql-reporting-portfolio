/* ============================================================
   Active Promo Offers Report — Sanitized Portfolio Version

   Portfolio version:
     - One row per promo code/source number
     - Includes Pricing Rules and Mode of Sale Offers
     - Combines related pricing rules and performances
     - Converts performance numbers to readable names
     - Identifies offers valid for all performances of a production
     - Combines sales channels
     - Replaces displayed NULL values with "-"
   ============================================================ */

DECLARE @AsOfDate datetime = GETDATE();
DECLARE @Today date = CAST(@AsOfDate AS date);


/* ============================================================
   Active pricing rules
   ============================================================ */

;WITH PricingRuleBase AS
(
    SELECT DISTINCT
        ws.promo_code,
        ws.source_no,

        pr.id AS setup_number,
        pr.description AS offer_name,

        rt.description AS offer_type,
        rc.description AS rule_category,

        pr.start_dt,
        pr.end_dt,
        pr.max_seats,

        pr.qualifying_performance,
        pr.qualifying_prod_season,
        pr.result_performance,
        pr.result_prod_season,

        pr.discount_amt,
        pr.discount_is_percent_ind,
        pr.discount_price_type,
        pr.rule_action,

        pt.description AS discounted_price_type,

        CASE
            WHEN rt.description = 'Buy One Get One'
                 AND pr.discount_is_percent_ind = 'Y'
                 AND pr.discount_amt = 100
            THEN 'Buy One, Get One Free'

            WHEN rt.description = 'Buy One Get One'
                 AND pr.discount_is_percent_ind = 'Y'
            THEN CONCAT(
                    'Buy One, Get One ',
                    FORMAT(pr.discount_amt, '0.##'),
                    '% Off'
                 )

            WHEN pr.rule_action = -1
                 AND pr.discount_is_percent_ind = 'Y'
            THEN CONCAT(
                    FORMAT(pr.discount_amt, '0.##'),
                    '% Off'
                 )

            WHEN pr.rule_action = -1
                 AND ISNULL(pr.discount_is_percent_ind, 'N') <> 'Y'
                 AND ISNULL(pr.discount_amt, 0) > 0
            THEN CONCAT(
                    '$',
                    FORMAT(pr.discount_amt, '0.00'),
                    ' Off'
                 )

            WHEN pr.rule_action = -2
                 AND pt.description IS NOT NULL
            THEN CONCAT(
                    'Applies Price Type: ',
                    pt.description
                 )

            ELSE pr.description
        END AS offer_description

    FROM dbo.T_PRICING_RULE AS pr

    INNER JOIN dbo.TR_WEB_SOURCE_NO AS ws
        ON
        (
            CHARINDEX(
                ',' + CONVERT(varchar(20), ws.source_no) + ',',
                ',' + REPLACE(ISNULL(pr.sources, ''), ' ', '') + ','
            ) > 0

            OR

            CHARINDEX(
                ',' + CONVERT(varchar(20), ws.source_no) + ',',
                ',' + REPLACE(
                    ISNULL(pr.promoted_sources, ''),
                    ' ',
                    ''
                ) + ','
            ) > 0
        )

    LEFT JOIN dbo.TR_PRICING_RULE_TYPE AS rt
        ON rt.id = pr.rule_type

    LEFT JOIN dbo.TR_PRICING_RULE_CATEGORY AS rc
        ON rc.id = pr.rule_category

    LEFT JOIN dbo.TR_PRICE_TYPE AS pt
        ON pt.id = pr.discount_price_type

    WHERE
        ISNULL(pr.inactive, 'N') <> 'Y'
        AND ISNULL(ws.inactive, 'N') <> 'Y'

        AND NULLIF(LTRIM(RTRIM(ws.promo_code)), '') IS NOT NULL

        AND
        (
            pr.start_dt IS NULL
            OR pr.start_dt <= @AsOfDate
        )

        AND
        (
            pr.end_dt IS NULL
            OR pr.end_dt >= @AsOfDate
        )

        AND pr.rule_action IN (-1, -2)

),

/* ============================================================
   Determine the applicable performance IDs for pricing rules

   Result performances are preferred. When result performances
   are blank, qualifying performances are used.
   ============================================================ */

PricingRulePerformanceNumbers AS
(
    /* Explicit result performances */
    SELECT DISTINCT
        pr.promo_code,
        pr.source_no,
        pr.setup_number,
        TRY_CONVERT(int, LTRIM(RTRIM(s.value))) AS perf_no

    FROM PricingRuleBase AS pr

    CROSS APPLY STRING_SPLIT(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(pr.result_performance)), '') IS NOT NULL
                THEN pr.result_performance
            ELSE pr.qualifying_performance
        END,
        ','
    ) AS s

    WHERE
        TRY_CONVERT(int, LTRIM(RTRIM(s.value))) IS NOT NULL
),

PricingRuleProductionSeasonNumbers AS
(
    /* Result production seasons, or qualifying seasons */
    SELECT DISTINCT
        pr.promo_code,
        pr.source_no,
        pr.setup_number,
        TRY_CONVERT(int, LTRIM(RTRIM(s.value))) AS prod_season_no

    FROM PricingRuleBase AS pr

    CROSS APPLY STRING_SPLIT(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(pr.result_prod_season)), '') IS NOT NULL
                THEN pr.result_prod_season
            ELSE pr.qualifying_prod_season
        END,
        ','
    ) AS s

    WHERE
        TRY_CONVERT(int, LTRIM(RTRIM(s.value))) IS NOT NULL
),

PricingRuleEligiblePerformances AS
(
    /* Explicit performance selections */
    SELECT DISTINCT
        pp.promo_code,
        pp.source_no,
        pd.perf_no

    FROM PricingRulePerformanceNumbers AS pp

    INNER JOIN BI.VT_PERFORMANCE_DETAIL AS pd
        ON pd.perf_no = pp.perf_no

    WHERE pd.perf_dt >= @Today

    UNION

    /* Expand production-season selections to performances */
    SELECT DISTINCT
        ps.promo_code,
        ps.source_no,
        pd.perf_no

    FROM PricingRuleProductionSeasonNumbers AS ps

    INNER JOIN BI.VT_PERFORMANCE_DETAIL AS pd
        ON pd.prod_season_no = ps.prod_season_no

    WHERE pd.perf_dt >= @Today
),

/* ============================================================
   Active Mode of Sale offers
   ============================================================ */

ModeOfSaleBase AS
(
    SELECT DISTINCT
        ws.promo_code,
        mo.source_no,

        mo.id AS setup_number,

        mo.perf_no,
        mo.pkg_no,

        mo.price_type,
        pt.description AS discounted_price_type,

        mo.mos,
        m.description AS sales_channel,

        mo.start_dt,
        mo.end_dt,
        mo.max_seats,
        mo.terms

    FROM dbo.T_MOS_OFFERS AS mo

    INNER JOIN dbo.TR_WEB_SOURCE_NO AS ws
        ON ws.source_no = mo.source_no
        AND ISNULL(ws.inactive, 'N') <> 'Y'

    INNER JOIN dbo.TR_MOS AS m
        ON m.id = mo.mos

    INNER JOIN dbo.TR_PRICE_TYPE AS pt
        ON pt.id = mo.price_type

    LEFT JOIN dbo.T_PERF AS p
        ON p.perf_no = mo.perf_no

    WHERE
        NULLIF(LTRIM(RTRIM(ws.promo_code)), '') IS NOT NULL

        AND
        (
            mo.start_dt IS NULL
            OR mo.start_dt <= @AsOfDate
        )

        AND
        (
            mo.end_dt IS NULL
            OR mo.end_dt >= @AsOfDate
        )


        /* Keep current/future performance or package offers */
        AND
        (
            ISNULL(mo.pkg_no, 0) > 0
            OR p.perf_dt >= @Today
        )
),

ModeOfSaleEligiblePerformances AS
(
    SELECT DISTINCT
        mos.promo_code,
        mos.source_no,
        mos.perf_no

    FROM ModeOfSaleBase AS mos

    WHERE ISNULL(mos.perf_no, 0) > 0
),

/* ============================================================
   Combine eligible performances from both setup methods
   ============================================================ */

EligiblePerformanceNumbers AS
(
    SELECT
        promo_code,
        source_no,
        perf_no
    FROM PricingRuleEligiblePerformances

    UNION

    SELECT
        promo_code,
        source_no,
        perf_no
    FROM ModeOfSaleEligiblePerformances
),

EligiblePerformanceDetail AS
(
    SELECT DISTINCT
        ep.promo_code,
        ep.source_no,

        pd.perf_no,
        pd.perf_desc,
        pd.perf_dt,

        pd.prod_season_no,
        pd.prod_season_desc,

        pd.production_no,
        pd.production_desc,

        pd.season_no,
        pd.season_desc

    FROM EligiblePerformanceNumbers AS ep

    INNER JOIN BI.VT_PERFORMANCE_DETAIL AS pd
        ON pd.perf_no = ep.perf_no
),

/* ============================================================
   Determine whether every remaining performance of a
   production is included in the promo
   ============================================================ */

ProductionCoverage AS
(
    SELECT
        ep.promo_code,
        ep.source_no,

        ep.prod_season_no,
        ep.prod_season_desc,

        COUNT(DISTINCT ep.perf_no) AS eligible_performance_count,

        (
            SELECT COUNT(DISTINCT allperf.perf_no)
            FROM BI.VT_PERFORMANCE_DETAIL AS allperf
            WHERE
                allperf.prod_season_no = ep.prod_season_no
                AND allperf.perf_dt >= @Today
        ) AS total_performance_count

    FROM EligiblePerformanceDetail AS ep

    GROUP BY
        ep.promo_code,
        ep.source_no,
        ep.prod_season_no,
        ep.prod_season_desc
),

/* ============================================================
   Create readable applicability items
   ============================================================ */

ApplicabilityItems AS
(
    /* Entire production is eligible */
    SELECT DISTINCT
        pc.promo_code,
        pc.source_no,

        CONCAT(
            pc.prod_season_desc,
            ' (all performances)'
        ) AS applicability_item,

        1 AS entire_production_ind

    FROM ProductionCoverage AS pc

    WHERE
        pc.eligible_performance_count = pc.total_performance_count
        AND pc.total_performance_count > 0

    UNION ALL

    /* Only selected performances are eligible */
    SELECT DISTINCT
        ep.promo_code,
        ep.source_no,

        CONCAT(
            ep.perf_desc,
            ' (',
            CONVERT(varchar(10), ep.perf_dt, 101),
            ')'
        ) AS applicability_item,

        0 AS entire_production_ind

    FROM EligiblePerformanceDetail AS ep

    INNER JOIN ProductionCoverage AS pc
        ON pc.promo_code = ep.promo_code
        AND pc.source_no = ep.source_no
        AND pc.prod_season_no = ep.prod_season_no

    WHERE
        pc.eligible_performance_count <> pc.total_performance_count
        OR pc.total_performance_count = 0
),

ApplicabilitySummary AS
(
    SELECT
        ai.promo_code,
        ai.source_no,

        COUNT(*) AS applicability_item_count,

        SUM(ai.entire_production_ind) AS entire_production_count,

        STRING_AGG(
            CONVERT(varchar(max), ai.applicability_item),
            '; '
        ) WITHIN GROUP
        (
            ORDER BY ai.applicability_item
        ) AS applicability_list

    FROM ApplicabilityItems AS ai

    GROUP BY
        ai.promo_code,
        ai.source_no
),

/* ============================================================
   Normalize both setup methods into one structure
   ============================================================ */

CombinedOfferRows AS
(
    SELECT DISTINCT
        pr.promo_code,
        pr.source_no,

        'Pricing Rule' AS setup_type,

        CONVERT(varchar(20), pr.setup_number) AS setup_number,

        pr.offer_name,
        pr.offer_type,
        pr.rule_category,
        pr.offer_description,

        pr.start_dt,
        pr.end_dt,
        pr.max_seats,

        pr.discounted_price_type,

        CAST(NULL AS varchar(255)) AS sales_channel

    FROM PricingRuleBase AS pr

    UNION ALL

    SELECT DISTINCT
        mos.promo_code,
        mos.source_no,

        'Mode of Sale Offer' AS setup_type,

        CONVERT(varchar(20), mos.setup_number) AS setup_number,

        mos.promo_code AS offer_name,

        'Discounted Price Type' AS offer_type,

        CAST(NULL AS varchar(255)) AS rule_category,

        CASE
            WHEN NULLIF(LTRIM(RTRIM(mos.terms)), '') IS NOT NULL
                THEN mos.terms
            ELSE CONCAT(
                    'Unlocks Price Type: ',
                    mos.discounted_price_type
                 )
        END AS offer_description,

        mos.start_dt,
        mos.end_dt,
        mos.max_seats,

        mos.discounted_price_type,

        mos.sales_channel

    FROM ModeOfSaleBase AS mos
),

/* ============================================================
   Distinct values before STRING_AGG
   ============================================================ */

DistinctSetupTypes AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        setup_type
    FROM CombinedOfferRows
),

SetupTypeSummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), setup_type),
            ' + '
        ) WITHIN GROUP
        (
            ORDER BY setup_type
        ) AS setup_types

    FROM DistinctSetupTypes

    GROUP BY
        promo_code,
        source_no
),

DistinctSetupNumbers AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        setup_number
    FROM CombinedOfferRows
    WHERE setup_number IS NOT NULL
),

SetupNumberSummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), setup_number),
            ', '
        ) WITHIN GROUP
        (
            ORDER BY setup_number
        ) AS setup_numbers

    FROM DistinctSetupNumbers

    GROUP BY
        promo_code,
        source_no
),

DistinctOfferNames AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        offer_name
    FROM CombinedOfferRows
    WHERE NULLIF(LTRIM(RTRIM(offer_name)), '') IS NOT NULL
),

OfferNameSummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), offer_name),
            '; '
        ) WITHIN GROUP
        (
            ORDER BY offer_name
        ) AS offer_names

    FROM DistinctOfferNames

    GROUP BY
        promo_code,
        source_no
),

DistinctOfferTypes AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        offer_type
    FROM CombinedOfferRows
    WHERE NULLIF(LTRIM(RTRIM(offer_type)), '') IS NOT NULL
),

OfferTypeSummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), offer_type),
            '; '
        ) WITHIN GROUP
        (
            ORDER BY offer_type
        ) AS offer_types

    FROM DistinctOfferTypes

    GROUP BY
        promo_code,
        source_no
),

DistinctRuleCategories AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        rule_category
    FROM CombinedOfferRows
    WHERE NULLIF(LTRIM(RTRIM(rule_category)), '') IS NOT NULL
),

RuleCategorySummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), rule_category),
            '; '
        ) WITHIN GROUP
        (
            ORDER BY rule_category
        ) AS rule_categories

    FROM DistinctRuleCategories

    GROUP BY
        promo_code,
        source_no
),

DistinctDescriptions AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        offer_description
    FROM CombinedOfferRows
    WHERE NULLIF(LTRIM(RTRIM(offer_description)), '') IS NOT NULL
),

DescriptionSummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), offer_description),
            '; '
        ) WITHIN GROUP
        (
            ORDER BY offer_description
        ) AS offer_descriptions

    FROM DistinctDescriptions

    GROUP BY
        promo_code,
        source_no
),

DistinctPriceTypes AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        discounted_price_type
    FROM CombinedOfferRows
    WHERE NULLIF(LTRIM(RTRIM(discounted_price_type)), '') IS NOT NULL
),

PriceTypeSummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), discounted_price_type),
            '; '
        ) WITHIN GROUP
        (
            ORDER BY discounted_price_type
        ) AS discounted_price_types

    FROM DistinctPriceTypes

    GROUP BY
        promo_code,
        source_no
),

DistinctSalesChannels AS
(
    SELECT DISTINCT
        promo_code,
        source_no,
        sales_channel
    FROM CombinedOfferRows
    WHERE NULLIF(LTRIM(RTRIM(sales_channel)), '') IS NOT NULL
),

SalesChannelSummary AS
(
    SELECT
        promo_code,
        source_no,

        STRING_AGG(
            CONVERT(varchar(max), sales_channel),
            ', '
        ) WITHIN GROUP
        (
            ORDER BY sales_channel
        ) AS sales_channels

    FROM DistinctSalesChannels

    GROUP BY
        promo_code,
        source_no
),

/* ============================================================
   One base row per promo code/source
   ============================================================ */

PromoCodeSummary AS
(
    SELECT
        cor.promo_code,
        cor.source_no,

        MIN(cor.start_dt) AS start_dt,

        CASE
            /* Any open-ended setup makes the combined code open-ended */
            WHEN COUNT(*) <> COUNT(cor.end_dt) THEN NULL
            ELSE MAX(cor.end_dt)
        END AS end_dt,

        MAX(cor.max_seats) AS maximum_seats

    FROM CombinedOfferRows AS cor

    GROUP BY
        cor.promo_code,
        cor.source_no
)

/* ============================================================
   Final report
   ============================================================ */

SELECT
    COALESCE(
        sts.setup_types,
        '-'
    ) AS [Offer Setup Type],

    COALESCE(
        sns.setup_numbers,
        '-'
    ) AS [Setup Numbers],

    COALESCE(
        ons.offer_names,
        pcs.promo_code,
        '-'
    ) AS [Offer Name],

    COALESCE(
        ots.offer_types,
        '-'
    ) AS [Offer Type],

    COALESCE(
        rcs.rule_categories,
        '-'
    ) AS [Rule Category],

    COALESCE(
        pcs.promo_code,
        '-'
    ) AS [Promo Code],

    COALESCE(
        CONVERT(varchar(20), pcs.source_no),
        '-'
    ) AS [Source Number],

    COALESCE(
        ds.offer_descriptions,
        '-'
    ) AS [Offer Description],

    CASE
        WHEN aps.applicability_list IS NULL
            THEN '-'

        WHEN aps.applicability_item_count = 1
             AND aps.entire_production_count = 1
        THEN CONCAT(
                'Valid for all performances of ',
                REPLACE(
                    aps.applicability_list,
                    ' (all performances)',
                    ''
                )
             )

        WHEN aps.applicability_item_count =
             aps.entire_production_count
        THEN CONCAT(
                'Valid for all performances of: ',
                REPLACE(
                    aps.applicability_list,
                    ' (all performances)',
                    ''
                )
             )

        ELSE CONCAT(
                'Valid for: ',
                aps.applicability_list
             )
    END AS [Valid For],

    COALESCE(
        CONVERT(varchar(19), pcs.start_dt, 120),
        '-'
    ) AS [Start Date],

    COALESCE(
        CONVERT(varchar(19), pcs.end_dt, 120),
        '-'
    ) AS [End Date],

    COALESCE(
        CONVERT(varchar(20), pcs.maximum_seats),
        '-'
    ) AS [Maximum Seats],

    COALESCE(
        pts.discounted_price_types,
        '-'
    ) AS [Discounted Price Type],

    COALESCE(
        scs.sales_channels,
        '-'
    ) AS [Sales Channels]

FROM PromoCodeSummary AS pcs

LEFT JOIN SetupTypeSummary AS sts
    ON sts.promo_code = pcs.promo_code
    AND sts.source_no = pcs.source_no

LEFT JOIN SetupNumberSummary AS sns
    ON sns.promo_code = pcs.promo_code
    AND sns.source_no = pcs.source_no

LEFT JOIN OfferNameSummary AS ons
    ON ons.promo_code = pcs.promo_code
    AND ons.source_no = pcs.source_no

LEFT JOIN OfferTypeSummary AS ots
    ON ots.promo_code = pcs.promo_code
    AND ots.source_no = pcs.source_no

LEFT JOIN RuleCategorySummary AS rcs
    ON rcs.promo_code = pcs.promo_code
    AND rcs.source_no = pcs.source_no

LEFT JOIN DescriptionSummary AS ds
    ON ds.promo_code = pcs.promo_code
    AND ds.source_no = pcs.source_no

LEFT JOIN PriceTypeSummary AS pts
    ON pts.promo_code = pcs.promo_code
    AND pts.source_no = pcs.source_no

LEFT JOIN SalesChannelSummary AS scs
    ON scs.promo_code = pcs.promo_code
    AND scs.source_no = pcs.source_no

LEFT JOIN ApplicabilitySummary AS aps
    ON aps.promo_code = pcs.promo_code
    AND aps.source_no = pcs.source_no

ORDER BY
    CASE
        WHEN pcs.end_dt IS NULL THEN 1
        ELSE 0
    END,
    pcs.end_dt,
    pcs.promo_code,
    pcs.source_no;

