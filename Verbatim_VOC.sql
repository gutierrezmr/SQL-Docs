drop table z_mgutierrez.verbatims;
create table z_mgutierrez.verbatims as
(
SELECT
A.*,
COALESCE(B.scivantage,C.scivantage) as scivantage
From z_zluetkehans.research_voc A
LEFT JOIN ai.ally_acm B
ON A.guid=B.guid and B.processdate='2021-11-16' and trim(B.guid) not LIKE ''
LEFT JOIN ai.ally_acm C
ON A.cif=C.cif and C.processdate='2021-11-16' and trim(C.cif) not LIKE ''
);
 
 
 
drop table z_mgutierrez.account_balances;
create table z_mgutierrez.account_balances as (
SELECT
distinct
verbatim_id,
data_date::date as data_date,
cif,
guid,
scivantage,
B.accountnumber,
total_equity,
fundedind
From z_mgutierrez.verbatims A
LEFT JOIN lookup.accountloginmap B
ON A.scivantage=B.loginname
LEFT JOIN ai.balance_dailyflow C
ON B.accountnumber=C.accountnumber and C.processdate='2021-11-16'
Where A.scivantage is not null
);
 
 
 
drop table z_mgutierrez.sd_mp_bday;
create table z_mgutierrez.sd_mp_bday as (SELECT CASE WHEN birthdate<'01-01-1900' THEN ''
         WHEN birthdate<'01-01-1927' THEN 'Pre-Silent Generation'
         WHEN birthdate>='01-01-1927' and birthdate<'01-01-1946' THEN 'Silent Generation'
         WHEN birthdate>='01-01-1945' and birthdate<'01-01-1965' THEN 'Baby Boomer'
         WHEN birthdate>='01-01-1964' and birthdate<'01-01-1981' THEN 'Gen X'
         WHEN birthdate>='01-01-1980' and birthdate<'01-01-1997' THEN 'Millennial'
         WHEN birthdate>='01-01-1997' and birthdate<'01-01-2013' THEN 'Gen Z'
         WHEN birthdate>='01-01-2013' and birthdate is not null THEN 'Gen Alpha'
         else 'Null'
        end as generation, accountnumber from securities.accounts union all
SELECT case     WHEN birthdate<'01-01-1900' THEN ''
         WHEN birthdate<'01-01-1927' THEN 'Pre-Silent Generation'
         WHEN birthdate>='01-01-1927' and birthdate<'01-01-1946' THEN 'Silent Generation'
         WHEN birthdate>='01-01-1945' and birthdate<'01-01-1965' THEN 'Baby Boomer'
         WHEN birthdate>='01-01-1964' and birthdate<'01-01-1981' THEN 'Gen X'
         WHEN birthdate>='01-01-1980' and birthdate<'01-01-1997' THEN 'Millennial'
         WHEN birthdate>='01-01-1997' and birthdate<'01-01-2013' THEN 'Gen Z'
         WHEN birthdate>='01-01-2013' and birthdate is not null THEN 'Gen Alpha'
         else 'Null'
        end as generation, accountnumber from advisor.applications);
  
drop table z_mgutierrez.join1;
create table z_mgutierrez.join1 as(
SELECT a.*, b.generation from z_mgutierrez.account_balances a LEFT JOIN z_mgutierrez.sd_mp_bday b on a.accountnumber = b.accountnumber);
 
 
 
drop table z_mgutierrez.account_trades;
create table z_mgutierrez.account_trades as (
SELECT
accountnumber,
--last_day(tradedate) as trade_month,
COUNT(DISTINCT tradedetailid) as trades
From securities.trades A
Where tradedate>='2021-08-17' and tradedate < '2021-11-17'
and cancelind != 'Y'
Group by 1);
 
drop table z_mgutierrez.option_account_trades;
create table z_mgutierrez.option_account_trades as(
SELECT
A.accountnumber,
COUNT(DISTINCT tradedetailid) as option_trades
From securities.trades A
Where tradedate>='2021-08-17' and tradedate < '2021-11-17'
and cancelind != 'Y'
and securitytype = 'Option'
Group by 1);
 
 
 
drop table z_mgutierrez.join2;
create table z_mgutierrez.join2 as(
SELECT a.*, b.trades, d.option_trades,
MAX(CASE WHEN lower(current_relationship) LIKE '%deposits%' THEN 1 else 0 end) as deposits_invest
from z_mgutierrez.join1 a LEFT JOIN z_mgutierrez.account_trades b on
 a.accountnumber = b.accountnumber LEFT JOIN z_mgutierrez.option_account_trades d on a.accountnumber = d.accountnumber
LEFT JOIN z_zluetkehans.cross_sell C on A.accountnumber = C.acct_num  group by 1,2,3,4,5,6,7,8,9,10,11
 
);
 
 
SELECT verbatim_id, SUM(trades) as trades, SUM(option_trades) as option_trades, MAX(deposits_invest) as deposits_invest, MAX(generation) as generation,
MAX(fundedind) as fundedind, SUM(total_equity) as equity from z_mgutierrez.join2 group by 1;
