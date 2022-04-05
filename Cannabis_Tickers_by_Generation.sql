with table_1 as(
SELECT weed.symbol, accountnumber, isselling, processdate, tradequantity, marketvalue from z_zluetkehans.cannibas_tickers as weed
join ai.apex_positionbreakoutstrategyovernight as positions
on upper(trim(weed.symbol)) = upper(trim(positions.symbol))
),
 
table_2 as (
 
/*market value, num of positions (account - symbols) - remeber to add the date filter, current state & possible growth from a year */
SELECT
CASE
WHEN date_part(year, birthdate)<=1927  THEN 'Pre-Silent Generation'
WHEN date_part(year, birthdate)>1927 and date_part(year, birthdate)<=1945  THEN 'Silent Generation'
WHEN date_part(year, birthdate)>1945 and date_part(year, birthdate)<=1964  THEN 'Baby Boom'
WHEN date_part(year, birthdate)>1964 and date_part(year, birthdate)<=1980  THEN 'Gen X'
WHEN date_part(year, birthdate)>1980 and date_part(year, birthdate)<=2004  THEN 'Millennial'
WHEN date_part(year, birthdate)>2004 and date_part(year, birthdate) <= date_part(year,getdate())  THEN 'Post Millennial'
ELSE 'unknown'
end as generation, table_1.symbol, isselling, birthdate, table_1.processdate as pd, tradequantity, marketvalue, table_1.accountnumber, processdate from securities.accounts as accounts
join table_1 on table_1.accountnumber = accounts.accountnumber)
 
SELECT datepart('week', processdate) as created_month, symbol, generation, COUNT(*) as count_pos,  SUM(tradequantity) as quant, SUM(marketvalue) as value from table_2
where (datepart(year, processdate)) = 2020
group by 1, generation, symbol
