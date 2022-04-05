create temporary table thirty_trades as (
SELECT
id,
scivantage,
createddate::date,
COUNT(DISTINCT tradedetailid) as thirty_day_trades,
SUM(commission) as commissions
From z_zluetkehans.dispositions A
LEFT JOIN lookup.accountloginmap C
ON A.scivantage=C.loginname
LEFT JOIN securities.trades B
ON C.accountnumber=B.accountnumber and B.tradedate<=(A.createddate::date) and B.tradedate>=((A.createddate::date)-29)
Where cancelind!='Y'
Group by 1,2,3);
 
  
 
 
create temporary table sd_mp_bday as (SELECT case     WHEN birthdate<'01-01-1900' THEN ''
         WHEN birthdate<'01-01-1927' THEN 'Pre-Silent Generation'
         WHEN birthdate>='01-01-1927' and birthdate<'01-01-1946' THEN 'Silent Generation'
         WHEN birthdate>='01-01-1945' and birthdate<'01-01-1965' THEN 'Baby Boomer'
         WHEN birthdate>='01-01-1964' and birthdate<'01-01-1981' THEN 'Gen X'
         WHEN birthdate>='01-01-1980' and birthdate<'01-01-1997' THEN 'Millennial'
         WHEN birthdate>='01-01-1997' and birthdate<'01-01-2013' THEN 'Gen Z'
         WHEN birthdate>='01-01-2013' and birthdate is not null THEN 'Gen Alpha'
         else 'Null'
        end as generation, accountnumber, annualincome, birthdate from securities.accounts union all
SELECT case     WHEN birthdate<'01-01-1900' THEN ''
         WHEN birthdate<'01-01-1927' THEN 'Pre-Silent Generation'
         WHEN birthdate>='01-01-1927' and birthdate<'01-01-1946' THEN 'Silent Generation'
         WHEN birthdate>='01-01-1945' and birthdate<'01-01-1965' THEN 'Baby Boomer'
         WHEN birthdate>='01-01-1964' and birthdate<'01-01-1981' THEN 'Gen X'
         WHEN birthdate>='01-01-1980' and birthdate<'01-01-1997' THEN 'Millennial'
         WHEN birthdate>='01-01-1997' and birthdate<'01-01-2013' THEN 'Gen Z'
         WHEN birthdate>='01-01-2013' and birthdate is not null THEN 'Gen Alpha'
         else 'Null'
        end as generation, accountnumber, annualincome, birthdate from advisor.applications);
 
  
 
  
 
Create Temporary Table lookup as(
SELECT
a.id,
subject,
contact_reason,
contact_type,
generation,
a.scivantage,
a.createddate::date as createddate,
b.accountnumber
from z_zluetkehans.dispositions a LEFT JOIN lookup.accountloginmap b on a.scivantage = b.loginname
LEFT JOIN sd_mp_bday c on b.accountnumber = c.accountnumber
);
--joining balances on (only equity for now for speed) make sure join on createddate too but cast as date, if we don't have equity field THEN account probably no longer w us, bc 0 does show up in balance
 
  
 
Create Temporary Table lookup_two as (
SELECT
A.*,
c.total_equity,
c.cash_position,
c.total_market_value,
c.positions,
c.product,
c.firstfundeddate
From lookup A
LEFT JOIN ai.balance_dailyflow c
on c.accountnumber = A.accountnumber and a.createddate::date = c.processdate
where C.total_equity is not null
);
 
 
 
Create Temporary Table final as(
SELECT
A.*,
d.thirty_day_trades,
d.commissions
From lookup_two A
LEFT JOIN z_zluetkehans.thirty_trades d on d.id = a.id
);
 
create temporary table networth as (
SELECT accountnumber, networth from securities.applications union all SELECT accountnumber, networth from advisor.applications
);
 
drop table z_zluetkehans.dispo_testing;
Create Table z_zluetkehans.dispo_testing as(
SELECT DATEDIFF(day,firstfundeddate, '2021-05-31') as tenure, A.*, B.networth,
CASE WHEN subject LIKE '%email%' THEN 'Interaction Log - Email'
WHEN  subject LIKE '%phone call%' THEN 'Interaction Log - Phone Call'
From final A
LEFT JOIN networth B on A.accountnumber = B.accountnumber
);
