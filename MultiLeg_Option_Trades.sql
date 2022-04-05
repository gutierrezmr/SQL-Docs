drop table options;
create table options as (
SELECT A.*, B.*, C.source
From securities.trades B
LEFT JOIN
(
SELECT trailer as trail, COUNT(DISTINCT tradedetailid) as leg_count
From securities.trades
Where securitytype='Option'
and tradedate>='2021-01-01'
and trailer is not null
Group by 1
) A
ON A.trail=B.trailer
LEFT JOIN ( SELECT source, RIGHT(orderid, LEN(orderid) - 4) as orderid_trimmed from firm.orders) C on C.orderid_trimmed = A.trail
Where securitytype='Option'
and tradedate>='2021-01-01')
;
 
SELECT * from options 
limit 10;
 
SELECT count (DISTINCT trailer) as trailer_count, count (DISTINCT tradedetailid) as id_count,
leg_count, source, trademonth from options group by 3,4,5;
