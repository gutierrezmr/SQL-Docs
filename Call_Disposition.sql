with calls as (   
SELECT 
distinct
segstart as call_start_datetime,
segstop as call_end_datetime,
ech.source_aap_partition,
description,
supplier,
int_ext,
call_area,
call_type,
IVR_XFR,
callid,
calling_pty,
call_disp,
duration,
acwtime,
ansholdtime,
consulttime,
disptime,
talktime,
netintime,
origholdtime,
queuetime,
ringtime,
split1,
dispvdn
  
from consume_enterprise_analytics.unified_avaya_ech ECH , enterprise_analytics_workbench.avaya_vdn_lkup  vdn   
where    
-- source_aap_partition='internal' and
ECH.dispvdn=vdn.vdn    
--and vdn.exclusion <>'x'   
and  ECH.call_disp in (2,3) --abandoned and handled   
-- and (split1>-1 or dispsplit > 0 )
and( source_aap_partition<>'internal' and dispsplit >0 or
      source_aap_partition='internal' and to_date(ech.segstop)<='2020-08-15' and split1>-1 or 
      source_aap_partition='internal' and to_date(ech.segstop)>'2020-08-15' and dispsplit >0)
and to_date(ech.segstop)>='2018-01-01'   
and  IVR_XFR='IVR' AND
lob='INVEST'   
 
)

SELECT 
* FROM calls a 
Where call_end_datetime>='XDate'
and call_end_datetime<'YDate'
