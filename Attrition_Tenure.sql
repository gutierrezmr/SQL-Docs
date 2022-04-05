SELECT accountnumber, networth from securities.applications union all SELECT accountnumber, networth from advisor.applications
);
 
create temporary table attrition_tenure as (
SELECT accountnumber, closedate from securities.accounts union all
SELECT accountnumber, closedate from advisor.accounts);
 
SELECT count ( distinct accountnumber ) from attrition_tenure;
 
drop table all_attrition_tenure;
create temporary table all_attrition_tenure as (
SELECT A.accountnumber, firstfundeddate, product, closedate, last_day(closedate::date) as attrition_month, current_relationship,
CASE WHEN datediff(day,firstfundeddate, closedate) > 0 and datediff(day,firstfundeddate, closedate) <= 31 THEN '< 1 Month'
WHEN datediff(day,firstfundeddate, closedate) > 31 and datediff(day,firstfundeddate, closedate) <= 365 THEN '2 Months - 1 Year'
WHEN datediff(day,firstfundeddate, closedate) > 365 and datediff(day,firstfundeddate, closedate) <= 1095 THEN '1 - 3 Years'
WHEN datediff(day,firstfundeddate, closedate) > 1095 and datediff(day,firstfundeddate, closedate) <= 1825 THEN '3 - 5 Years'
WHEN datediff(day,firstfundeddate, closedate) > 0 THEN '> 5 Years'
else 'Unfunded' end as tenure_at_attrition
from ai.balance_dailyflow A
LEFT JOIN attrition_tenure B on A.accountnumber = B.accountnumber
LEFT JOIN z_zluetkehans.cross_sell_ongoing C on A.accountnumber = C.acct_num where closedate is not null) ;
 
SELECT count (DISTINCT accountnumber), last_day(closedate::date) as attrition_month, current_relationship
from all_attrition_tenure where (current_relationship LIKE 'Deposits' or current_relationship 
LIKE 'Invest' or current_relationship LIKE 'Deposits+Invest') and attrition_month >= '2021-01-31' group by 2,3;
