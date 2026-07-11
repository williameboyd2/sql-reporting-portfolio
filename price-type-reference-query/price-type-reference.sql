/*
    Project:
        Price Type Reference Query

    Purpose:
        Produce a reusable reference list of configured Tessitura
        ticket price types and their internal identifiers.

    Portfolio notes:
        - No customer or transactional information is returned.
        - Organization-specific query results are not included.
        - Both active and inactive records are retained because
          historical ticket transactions may reference inactive
          price types.
*/

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SELECT
    pt.id
        AS [Price Type ID],

    ISNULL
    (
        NULLIF
        (
            LTRIM(RTRIM(pt.description)),
            ''
        ),
        'Unnamed Price Type'
    ) AS [Description],

    ISNULL
    (
        NULLIF
        (
            LTRIM(RTRIM(pt.short_desc)),
            ''
        ),
        ''
    ) AS [Short Description],

    ISNULL
    (
        NULLIF
        (
            LTRIM(RTRIM(pt.alias_description)),
            ''
        ),
        ''
    ) AS [Web Alias],

    pt.price_type_category
        AS [Price Type Category ID],

    pt.price_type_group
        AS [Price Type Group ID],

    CASE
        WHEN UPPER
        (
            ISNULL
            (
                LTRIM(RTRIM(pt.inactive)),
                'N'
            )
        ) IN ('Y', '1')
            THEN 'Inactive'

        ELSE 'Active'
    END AS [Status],

    pt.attendance_category_no
        AS [Attendance Category ID],

    ISNULL
    (
        NULLIF
        (
            LTRIM(RTRIM(pt.requires_benefit_ind)),
            ''
        ),
        'N'
    ) AS [Requires Benefit],

    ISNULL
    (
        NULLIF
        (
            LTRIM(RTRIM(pt.pay_what_you_wish_ind)),
            ''
        ),
        'N'
    ) AS [Pay What You Wish]

FROM dbo.TR_PRICE_TYPE AS pt

ORDER BY
    CASE
        WHEN UPPER
        (
            ISNULL
            (
                LTRIM(RTRIM(pt.inactive)),
                'N'
            )
        ) IN ('Y', '1')
            THEN 1

        ELSE 0
    END,

    ISNULL
    (
        NULLIF
        (
            LTRIM(RTRIM(pt.description)),
            ''
        ),
        'Unnamed Price Type'
    ),

    pt.id;
