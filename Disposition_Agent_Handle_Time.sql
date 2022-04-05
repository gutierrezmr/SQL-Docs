With Dispositions as(
SELECT *, createddate::date as date_created, left(right(createddate_time,13),8) as time_created
From z_zluetkehans.dispositions
Where subject LIKE '%Phone Call%'
and scivantage is not null and scivantage not LIKE '' and scivantage not LIKE 'MISSING_SCIVANTAGE_ID'
),
 
  
 
Disposition_timestamp as(
SELECT *, cast(date_created||' '||time_created as timestamp) as timestamp_created From dispositions
),
 
  
 
disposition_converted as(
SELECT
distinct
id,
contact_reason,
contact_type,
scivantage,
timestamp_created,
convert_timezone('America/New_York',timestamp_created) as time_converted,
dateadd('hour',1,time_converted) as upper_time,
dateadd('hour',-1,time_converted) as lower_time,
time_converted::date as date_time
From Disposition_timestamp
),
 
  
 
Combined as(
SELECT *,
talktime+acwtime+ansholdtime as handle_time,
CASE WHEN call_disp = '2' THEN 'handled' WHEN call_disp = '3' THEN 'abandoned' ELSE '' END as call_disp_handled
From z_zluetkehans.call_data A
LEFT JOIN z_zluetkehans.call_contacts B
ON A.calling_pty=B.phone
LEFT JOIN disposition_converted C
ON B.loginname=C.scivantage
and upper_time>=call_end_datetime and lower_time<=call_start_datetime
--and date_time=call_end_datetime::date
Where id is not null and call_disp = '2'
),
 
  
 
Multiple_queue_check as(
SELECT upper_time, lower_time, scivantage, COUNT(DISTINCT supplier) as queue_count
From Combined
Group by 1,2,3
),
 
  
 
Multiple_call_check as(
SELECT upper_time, lower_time, scivantage, COUNT(DISTINCT callid) as call_count
From Combined
Group by 1,2,3
),
 
  
 
Combined_Reduced as(
SELECT A.*
From Combined A
LEFT JOIN Multiple_queue_check B
ON A.upper_time=B.upper_time and A.lower_time=B.lower_time and A.scivantage=B.scivantage
LEFT JOIN Multiple_call_check C
ON A.upper_time=C.upper_time and A.lower_time=C.lower_time and A.scivantage=C.scivantage
Where B.queue_count=1 and C.call_count=1
),
 
  
 
Multiple_Users_Check as(
SELECT callid, COUNT(DISTINCT scivantage) as user_count
From combined_reduced
Group by 1
),
 
  
 
Final_Dispos as(
SELECT distinct A.*
From combined_reduced A
LEFT JOIN Multiple_Users_Check B
ON A.callid=B.callid
Where user_count=1
),
 
  
 
outbound_final as(
SELECT
distinct
A.call_start_datetime,
A.call_end_datetime,
A.supplier,
A.description,
A.call_area,
A.call_type,
A.callid,
A.calling_pty,
A.duration,
A.scivantage,
A.handle_time,
A.contact_type,
A.contact_reason,
transfer_location,
MAX(CASE WHEN C.lic_flag is not null THEN C.lic_flag::float else 0 end) as lic_inbound_flag,
MAX(CASE WHEN D.lic_flag is not null THEN D.lic_flag::float else 0 end) as lic_transfer_flag,
MAX(CASE WHEN B.callid is not null THEN 1 else 0 end) as outbound_transfer_flag,
SUM(COALESCE(B.duration::float,0)) as transfer_duration
From final_dispos A
LEFT JOIN z_zluetkehans.alorica_outbound B
ON A.callid=B.callid and B.call_disp!='2'
LEFT JOIN z_zluetkehans.licensed_inbound C
ON A.callid=C.callid
LEFT JOIN z_zluetkehans.licensed_transfer D
ON A.callid=D.callid
Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14
)
 
  
 
 
SELECT
supplier,
call_type,
contact_reason,
contact_type,
outbound_transfer_flag,
COALESCE(transfer_location,'NO TRANSFER') as transfer_location,
COUNT(DISTINCT callid) as unique_calls,
SUM(handle_time) as handle_time,
SUM(transfer_duration) as transfer_duration,
lic_inbound_flag
From outbound_final
Group by 1,2,3,4,5,6,10;
  
---------------------------------
 
With calls as(
SELECT *,
talktime+acwtime+ansholdtime as handle_time,
CASE WHEN call_disp = '2' THEN 'handled' WHEN call_disp = '3' THEN 'abandoned' ELSE '' END as call_disp_handled
From z_zluetkehans.call_data A
LEFT JOIN z_zluetkehans.call_contacts B
ON A.calling_pty=B.phone
),
 
  
 
user_count as (
SELECT callid, COUNT(DISTINCT loginname) as users_tied
From calls
Group by callid
),
 
  
 
testing as(
SELECT
distinct
A.*,
talktime+acwtime+ansholdtime as handle_time,
CASE WHEN call_disp = '2' THEN 'handled' WHEN call_disp = '3' THEN 'abandoned' ELSE '' END as call_disp_handled,
CASE WHEN users_tied>1 THEN 'Multiple_Users' else loginname end as loginname
From z_zluetkehans.call_data A
LEFT JOIN z_zluetkehans.call_contacts B
ON A.calling_pty=B.phone
LEFT JOIN user_count C
ON A.callid=C.callid
)
 
  
 
SELECT COUNT(*), COUNT(DISTINCT callid) from testing;
