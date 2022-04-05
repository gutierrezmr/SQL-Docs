With logins_raw as(
SELECT
pty.tk_ceqv_admin_client_id,
login_dt,
ip_address,
login_success,
tm,
channel,
app_or_browser

 

from (

 


SELECT
uid,
substr(to_date(aap_rsa_date_time),1,7) as tm,
aap_rsa_date_time as login_dt,
case 
WHEN action='ALLOW' THEN 1 
WHEN action='CHALLENGE' and challenge_success='Y' THEN 1 else 0 end as login_success,
channel,
channel_desc,
app_or_browser,
ip_address,
user_agent
FROM consume_deposits.vw_rsa_event_details
where transaction_type='SESSION_SIGNIN' and rule_fired<>'IPONGoldList' and 
rule_fired not LIKE '%Alexa%' and to_date(aap_rsa_date_time)>='XDate'

 


) login

 

inner join

 

(
SELECT 
a.last_update_dt,
a.party_id,
a.dep_ceqv_admin_client_id,
a.idm_ceqv_admin_client_id,
a.tk_ceqv_admin_client_id

 

from consume_acm.vw_acm_customer_view a
inner join 

 

(

 

SELECT 
MAX(last_update_dt) as mx_date,
idm_ceqv_admin_client_id
from consume_acm.vw_acm_customer_view
group by 2
) x
on a.last_update_dt=x.mx_date and a.idm_ceqv_admin_client_id=x.idm_ceqv_admin_client_id

 

) pty

 

on login.uid=pty.idm_ceqv_admin_client_id
where pty.tk_ceqv_admin_client_id is not null
and login_success=1
),

 

user_level as(
SELECT 
tk_ceqv_admin_client_id, 
tm,
SUM(CASE WHEN channel='WEB' THEN login_success else 0 end) as web_logins,
SUM(CASE WHEN channel='MOBILE' and app_or_browser='MOBILE APP' THEN login_success else 0 end) as mobile_app_logins,
SUM(CASE WHEN channel='MOBILE' and app_or_browser='MOBILE BROWSER' THEN login_success else 0 end) as mobile_browser_logins
From logins_raw
Where login_dt>='XDate' 
and login_dt<'YDate'
Group by 1,2
)

 

SELECT * From user_level
