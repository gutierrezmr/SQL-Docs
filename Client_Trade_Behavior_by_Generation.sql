drop table clients1;
create table clients1 as(
SELECT accountnumber, closedate, clientid from securities.accounts
);
  
drop table clients2;
create table clients2 as(
SELECT
A.accountnumber,
clientid,
processmonth,
SUM(total_equity) as equity
From ai.balance_monthlyflow A
LEFT JOIN clients1 B
ON A.accountnumber=B.accountnumber
Where processmonth>='2020-09-30' and processmonth <= '2021-11-01'
and fundedind=1 and (closedate is null or closedate>processmonth) and product LIKE 'SD'
Group by 1,2,3
);
  
drop table clients3;
create table clients3 as(
SELECT
A.accountnumber,
last_day(tradedate) as trade_month,
COUNT(DISTINCT tradedetailid) as trades
From securities.trades A
Where tradedate>='2020-09-30' and tradedate < '2021-11-01'
and cancelind != 'Y'
Group by 1,2);
 
drop table clients4;
create table clients4 as(
SELECT
A.accountnumber,
A.clientid,
A.processmonth,
A.equity,
B.trades
From clients2 A
LEFT JOIN clients3 B
ON A.accountnumber=B.accountnumber and processmonth=trade_month
);
 
 
drop table clients5;
create  table clients5 as(
SELECT
A.clientid,
A.processmonth,
SUM(A.equity) as equity,
SUM(A.trades) as trades,
MAX(CASE WHEN lower(current_relationship) LIKE '%deposits%' THEN 1 else 0 end) as deposits_invest
from clients4 A LEFT JOIN z_zluetkehans.cross_sell_ongoing  B on A.accountnumber = B.acct_num and A.processmonth = B.data_date::date group by 1,2);
 
--first
drop table clients6;
create  table clients6 as(
SELECT
processmonth,
SUM(deposits_invest) as deposits_invest,
CASE WHEN coalesce (trades,0) > 0 and coalesce (trades,0) <= 1 THEN 'Infrequent'
WHEN coalesce (trades,0) >= 2 and coalesce (trades,0) <= 5 THEN 'Casual'
WHEN coalesce (trades,0) > 5 and coalesce (trades,0) <= 30 THEN 'Active'
WHEN coalesce (trades,0) > 30 THEN 'Day Trader'
else 'Inactive'
end as trader_type,
COUNT(DISTINCT clientid) as clients,
SUM(equity) as equity 
from clients5 group by 1,3);
 
 
SELECT trader_type, avg(deposits_invest) as avg_dep_inv, avg(clients) as avg_clients,
SUM(equity) / SUM(clients) as avg_equity from clients6 group by 1;
 
 
drop table z_mgutierrez.client_sd_bday;
create table z_mgutierrez.client_sd_bday as (SELECT max (CASE     WHEN birthdate<'01-01-1900' THEN ''
         WHEN birthdate<'01-01-1927' THEN 'Pre-Silent Generation'
         WHEN birthdate>='01-01-1927' and birthdate<'01-01-1946' THEN 'Silent Generation'
         WHEN birthdate>='01-01-1945' and birthdate<'01-01-1965' THEN 'Baby Boomer'
         WHEN birthdate>='01-01-1964' and birthdate<'01-01-1981' THEN 'Gen X'
         WHEN birthdate>='01-01-1980' and birthdate<'01-01-1997' THEN 'Millennial'
         WHEN birthdate>='01-01-1997' and birthdate<'01-01-2013' THEN 'Gen Z'
         WHEN birthdate>='01-01-2013' and birthdate is not null THEN 'Gen Alpha'
         else 'Null'
        end) as generation, clientid from securities.accounts group by clientid
    
);
 
SELECT * from client7 where generation LIKE '';
--second
drop table client7;
create table client7 as (
SELECT processmonth, generation, COUNT(DISTINCT a.clientid) as clients, SUM(coalesce (trades, 0)::float) as sum_trades,
SUM(equity) as sum_equity, SUM(deposits_invest) as deposits_invest from clients5 a
LEFT JOIN z_mgutierrez.client_sd_mp_bday b on a.clientid = b.clientid group by 1,2);
 
 
 
 
SELECT generation, avg(deposits_invest) as avg_dep_inv, avg(clients) as avg_clients, SUM(sum_equity) / SUM(clients) as avg_equity,
SUM(sum_trades) / SUM(clients) as avg_trades from client7 group by 1;
