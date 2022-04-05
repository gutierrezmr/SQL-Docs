SELECT * from ai.balance_monthlyflow limit 10;
 
drop table tk_join;
create temporary table tk_join as (
SELECT accountnumber, tk_ceqv_admin_client_id, last_day(tm_date::date) as Month, web_logins + mobile_browser_logins as web, mobile_app_logins from z_mgutierrez.mobile_request a
LEFT JOIN lookup.accountloginmap b on a.tk_ceqv_admin_client_id = b.loginname);
 
 
SELECT * from tk_join limit 10;
 
drop table logins;
create temporary table logins as (
SELECT a.accountnumber, a.tk_ceqv_admin_client_id, a.Month, b.total_equity,
sum (CASE WHEN web >=1 and mobile_app_logins = 0 THEN web else 0 end) as web_only_logins,
sum (CASE WHEN mobile_app_logins >=1 and web = 0 THEN mobile_app_logins else 0 end) as mobile_app_only_logins,
sum (CASE WHEN mobile_app_logins >=1 and web >=1 THEN mobile_app_logins + web else 0 end) as both_logins,
sum (CASE WHEN mobile_app_logins =0 and web = 0 THEN 1 else 0 end) as no_logins
from tk_join a LEFT JOIN ai.balance_monthlyflow b on a.accountnumber = b.accountnumber and a.Month = b.processmonth group by 1,2,3,4);
 
SELECT * from logins limit 10;
 
SELECT 
month, SUM(total_equity) / COUNT(DISTINCT tk_ceqv_admin_client_id) as web_only_avg_bal from logins where web_only_logins >= 1 group by month;
 
SELECT 
month, SUM(total_equity) / COUNT(DISTINCT tk_ceqv_admin_client_id) as mobile_only_avg_bal from logins where mobile_app_only_logins >= 1 group by month;
 
SELECT 
month, SUM(total_equity) / COUNT(DISTINCT tk_ceqv_admin_client_id) as both_avg_bal from logins where both_logins >= 1 group by month;
 
 
SELECT 
processmonth, SUM(total_equity) / COUNT(DISTINCT loginname) as no_login_avg_bal from no_logins group by processmonth;
