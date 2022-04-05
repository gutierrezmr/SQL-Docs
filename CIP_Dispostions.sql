
SELECT
datepart('week', createddate::date) as created_week,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' and subject LIKE '%Chat' THEN id ELSE NULL END) cip_chat,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' and subject LIKE '%Phone%' THEN id ELSE NULL END) cip_phone,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' and subject LIKE '%Email'  THEN id ELSE NULL END) cip_email,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' THEN id ELSE NULL END) cip
From z_zluetkehans.dispositions
Group by 1;
 
SELECT datepart('week', opendate::date) as created_week, COUNT(DISTINCT accountnumber) as security_count
from securities.accounts
where opendate LIKE '2020%'
group by 1;
 
SELECT datepart('week', opendate::date) as created_week, COUNT(DISTINCT accountnumber) as advisor_count
from advisor.accounts
where opendate LIKE '2020%'
group by 1;
 
----------
 
SELECT
createddate,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' and subject LIKE '%Chat' THEN id ELSE NULL END) cip_chat,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' and subject LIKE '%Phone%' THEN id ELSE NULL END) cip_phone,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' and subject LIKE '%Email'  THEN id ELSE NULL END) cip_email,
COUNT(DISTINCT CASE WHEN contact_reason LIKE 'CIP%' THEN id ELSE NULL END) cip
From TABLE
Group by 1;
 
SELECT opendate, COUNT(DISTINCT accountnumber) as security_count
from securities.accounts
where opendate LIKE '2020%'
group by 1;
 
SELECT opendate, COUNT(DISTINCT accountnumber) as advisor_count
from advisor.accounts
where opendate LIKE '2020%'
group by 1;
