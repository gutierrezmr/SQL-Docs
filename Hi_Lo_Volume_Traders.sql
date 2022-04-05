create table z_mgutierrez.trades_weekly_sd as (
 
SELECT accountnumber, COUNT(DISTINCT tradedetailid) as trades, DATEPART(week, processdate) as processweek, processdate, last_day(processdate) as month_join, 
COUNT(DISTINCT CASE WHEN securitytype='Option' THEN tradedetailid ELSE NULL END) as option_trades
From securities.trades
Where cancelind!='Y' and DATEPART(year, processdate) in('2021')
Group by 1,3,4;
 
SELECT * from securities.trades limit 10;
 
--+- 35 trades a month for standard vs high volume equity traders
 
create table z_mgutierrez.trades_weekly_sd as (
SELECT accountnumber, COUNT(DISTINCT tradedetailid) as trades, trademonth
From securities.trades
Where cancelind!='Y' and (DATEPART(year, processdate) in('2021'))
Group by 1,3);
 
SELECT * from z_mgutierrez.trades_weekly_sd where trades > 35;
 
SELECT * from securities.trades limit 10;
 
SELECT
CASE WHEN firstfundeddate<'2020-01-01' THEN '2019'
WHEN firstfundeddate<'2020-04-01' THEN 'Q1 2020'
WHEN firstfundeddate<'2020-06-01' THEN 'April-May 2020'
WHEN firstfundeddate<'2020-09-01' THEN 'June-Aug 2020'
else 'Post Aug 2020' end as funding_period,
datediff('month',firstfundeddate, processmonth) as months_since_funding,
SUM(fundedind) as funded_accounts,
SUM(fundedind_pp) as previously_funded_accounts,
COUNT(DISTINCT CASE WHEN last_day(firstfundeddate)=processmonth THEN accountnumber ELSE NULL END) as starting_month_accounts
From ai.balance_monthlyflow
Where product='MP' and firstfundeddate>='2019-01-01'
and datediff('month',firstfundeddate, processmonth)>=0
and processmonth<='2021-03-31'
Group by 1,2;                          
 
create table z_mgutierrez.weekly_attrition as(
SELECT
    distinct accountnumber,
  DATE(metrics_weekly.processweek ) as "metrics_weekly.process_week",
    CASE WHEN (metrics_weekly.status = 'Attrition') THEN 1 ELSE NULL END as "metrics_weekly.accounts_attrited"
FROM securities.weekly_changes  as metrics_weekly
 
WHERE
    (((metrics_weekly.processweek ) >= ((DATEADD(week,-30, DATE_TRUNC('week', DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/New_York', GETDATE()))) )))
    AND (metrics_weekly.processweek ) < ((DATEADD(week,30, DATEADD(week,-30, DATE_TRUNC('week', DATE_TRUNC('day',CONVERT_TIMEZONE('UTC', 'America/New_York', GETDATE()))) ) )))))
    and (metrics_weekly.status = 'Attrition')
GROUP BY 1,2,3
ORDER BY 2 DESC);
 
SELECT * from z_mgutierrez.weekly_attrition;
 
drop table z_mgutierrez.trade_counts;
create table z_mgutierrez.trade_counts as (
SELECT b.accountnumber, COUNT(DISTINCT tradedetailid) as trades, trademonth
From securities.trades as a
inner join z_mgutierrez.weekly_attrition as b on a.accountnumber = b.accountnumber
Where cancelind!='Y' and (processdate > '2020-08-30')
Group by 1,3);
 
SELECT accountnumber from z_mgutierrez.trade_counts where trades > 35;
