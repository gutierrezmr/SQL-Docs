drop table Z_MGUTIERREZ.all_accounts;
CREATE TABLE Z_MGUTIERREZ.all_accounts as (
SELECT accountnumber, opendate, closedate, accounttype From securities.accounts
Union all
SELECT accountnumber, opendate, closedate, accounttype  From advisor.accounts
);
 
drop table z_mgutierrez.loginjoin;
create table z_mgutierrez.loginjoin as (
SELECT a.*, b.loginname from Z_MGUTIERREZ.all_accounts a
LEFT JOIN lookup.accountloginmap b on a.accountnumber = b.accountnumber);
 
drop table z_mgutierrez.acmjoin2;
create table z_mgutierrez.acmjoin2 as (
SELECT * from z_mgutierrez.loginjoin a
LEFT JOIN ai.ally_acm b on a.loginname = b.scivantage and b.processdate = '2021-09-30');
--processdate join here too, processdate = yesterday
 
 
drop table z_mgutierrez.final_join;
create table z_mgutierrez.final_join as (
SELECT a.accountnumber, last_day(a.opendate) as openmonth, last_day(a.closedate) as closemonth, a.accounttype,
a.loginname, a.cif, a.scivantage, last_day(a.processdate) as processmonth, b.generation from z_mgutierrez.acmjoin2 a LEFT JOIN sd_mp_bday b on a.accountnumber = b.accountnumber);
 
--not needed
drop table z_mgutierrez.cross_sell_join;
create table z_mgutierrez.cross_sell_join as (
SELECT a.*, b.current_relationship from z_mgutierrez.final_join a LEFT JOIN z_zluetkehans.cross_sell_ongoing b
on accountnumber = acct_num and processmonth = b.data_date::date);
 
--not needed
drop table z_mgutierrez.balance_join;
create table z_mgutierrez.balance_join as (
SELECT a.total_equity, a.processmonth as month, b.* from ai.balance_monthlyflow a LEFT JOIN z_mgutierrez.cross_sell_join b 
on a.accountnumber = b.accountnumber);
 
--Generation
create table sd_mp_bday as (SELECT case     WHEN birthdate<'01-01-1900' THEN ''
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
         
 
 
 
--Invest IRA ONly accounts
--Invest IRA Customer with other Ally Invest accounts
--Invest IRA Customer with Bank IRA accounts
--Invest IRA Customer with other Bank account type (Taxable)
--Invest IRA with a (Mortgage, Lending, Auto account)
 
with accounts as
(
SELECT accountnumber, opendate, closedate
From securities.accounts
Where lower(accounttype) LIKE '%ira%'
and closedate is null
Union All
SELECT accountnumber, opendate, closedate
From advisor.accounts
Where lower(accounttype) LIKE '%ira%'
and closedate is null
),
  
non_ira_accounts as
(
SELECT accountnumber, opendate, closedate
From securities.accounts
Where lower(accounttype) not LIKE '%ira%'
and closedate is null
Union All
SELECT accountnumber, opendate, closedate
From advisor.accounts
Where lower(accounttype) not LIKE '%ira%'
and closedate is null
),
  
non_ira_base as(
SELECT distinct loginname
From non_ira_accounts A
LEFT JOIN lookup.accountloginmap B
ON A.accountnumber=B.accountnumber
),
  
base_list as(
SELECT
COALESCE(loginname,A.accountnumber) as loginname,
A.accountnumber
From accounts A
LEFT JOIN lookup.accountloginmap B
ON A.accountnumber=B.accountnumber
),
 
final_list as(
SELECT
distinct
A.loginname,
cif,
CASE WHEN balance LIKE '' THEN null else balance end ::float as bank_balance,
CASE WHEN C.loginname is not null THEN 1 else 0 end as non_ira_flag,
MAX(CASE WHEN lower(current_relationship) LIKE '%mortgage%' or lower(current_relationship) LIKE '%auto%' or
lower(current_relationship) LIKE '%insurance%' THEN 1 else 0 end) as relation
From base_list A
LEFT JOIN ai.ally_acm B
ON A.loginname=B.scivantage and B.processdate='2021-10-01'
LEFT JOIN non_ira_base C
ON A.loginname=C.loginname
LEFT JOIN z_zluetkehans.cross_sell d on a.loginname = d.scivantageuserid
group by a.loginname, b.cif, b.balance, c.loginname)
 
SELECT * from final_list a LEFT JOIN z_zluetkehans.bank_ira b on a.cif = b.customer_id
;
 
 
--Average value of an IRA Invest account
create table z_mgutierrez.ira_balances as (
SELECT accountnumber, opendate, closedate
From securities.accounts
Where lower(accounttype) LIKE '%ira%'
and closedate is null
Union All
SELECT accountnumber, opendate, closedate
From advisor.accounts
Where lower(accounttype) LIKE '%ira%'
and closedate is null);
 
SELECT avg(total_equity), processmonth from z_mgutierrez.ira_balances a
LEFT JOIN ai.balance_monthlyflow b on a.accountnumber = b.accountnumber
where processmonth >= '2021-06-30' group by 2 order by processmonth desc;
 
create table z_mgutierrez.generation_join as (
SELECT a.*, b.fundedind from z_mgutierrez.final_join a LEFT JOIN ai.balance_monthlyflow b on a.accountnumber = b.accountnumber where b.processmonth > '2020-08-31');
 
 
--Avg number of accounts opened but not funded
SELECT COUNT(DISTINCT loginname), openmonth from z_mgutierrez.generation_join where fundedind LIKE 0 and openmonth > '2020-08-31' and openmonth < '2021-09-30' and lower(accounttype) LIKE '%ira%' group by openmonth order by openmonth desc;
 
 
--Average Account Openings per month
SELECT COUNT(DISTINCT loginname), openmonth from z_mgutierrez.generation_join where openmonth > '2020-08-31' and openmonth < '2021-09-30' and lower(accounttype) LIKE '%ira%' group by openmonth order by openmonth desc;
 
 
--What is the generational profile of customers opening
SELECT COUNT(DISTINCT loginname), generation, openmonth from z_mgutierrez.generation_join where openmonth > '2020-08-31' and openmonth < '2021-09-30' and lower(accounttype) LIKE '%ira%' group by openmonth, generation order by openmonth desc;
 
--What is the generational profile of customers closing
SELECT COUNT(DISTINCT loginname), generation, closemonth from z_mgutierrez.generation_join where closemonth > '2020-08-31' and closemonth < '2021-09-30' and lower(accounttype) LIKE '%ira%' group by closemonth, generation order by closemonth desc;
 
--Customer Profile for Invest IRA Accounts (Generational)
SELECT COUNT(DISTINCT loginname), generation from z_mgutierrez.generation_join where lower(accounttype) LIKE '%ira%' group by generation;
