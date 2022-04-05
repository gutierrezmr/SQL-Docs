With base_ola as(
SELECT
A.processdate,
A.daycount,
CASE WHEN opendate<'2020-06-15' THEN 'OLA' else 'Non-OLA' end as OLA_Flag,
SUM(brokershare::float) as total_brokershare,
SUM(collateral::float) as total_collateral,
SUM(totalincome::float) as total_income,
SUM(customershare::float) as total_customershare
From lookup.tradedays A
LEFT JOIN apex_ext.ext996_fully_funded_detail B
ON A.processdate=B.processdate::date
LEFT JOIN securities.accounts C
ON B.accountnumber=C.accountnumber
Group by 1,2,3
),
base as(
SELECT
A.processdate,
A.daycount,
SUM(brokershare::float) as brokershare
From lookup.tradedays A
LEFT JOIN apex_ext.ext996_fully_funded_detail B
ON A.processdate=B.processdate::date
LEFT JOIN securities.accounts C
ON B.accountnumber=C.accountnumber
Group by 1,2
),
base_two as(
SELECT
A.*,
MAX(B.processdate) as last_trade_date
From base A
LEFT JOIN
(
SELECT
distinct
processdate
From lookup.tradedays
Where daycount>0
)B
ON A.processdate::date>=B.processdate
Group by 1,2,3
)
SELECT A.processdate, b.OLA_Flag, b.total_brokershare, b.total_income, b.total_collateral, b.total_customershare
From base_two A
LEFT JOIN base_ola B
ON B.processdate::date=A.last_trade_date and B.ola_flag='Non-OLA'
LEFT JOIN base_ola C
ON C.processdate::date=A.last_trade_date and C.ola_flag='OLA';
