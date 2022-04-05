drop table ticker_accounts;
create temporary table ticker_accounts as (
WITH positions_monthly as (SELECT *
          from ai.apex_positionbreakoutstrategyovernight
            where processdate = last_day(processdate)
            or processdate=(CURRENT_DATE-1)
            and accountnumber in (SELECT distinct accountnumber from securities.accounts))
SELECT
    case 'y' WHEN 'y'
            THEN positions_monthly.accountnumber
          else md5(positions_monthly.accountnumber)
         end  as "account_number"
FROM positions_monthly
 
WHERE (positions_monthly.processdate  >= TIMESTAMP 'DATE') AND (positions_monthly.symbol = 'Ticker')
GROUP BY 1
ORDER BY 1);
 
 
SELECT distinct account_number, emailaddress from apex_ext.ext989_ecommunication_preference a 
inner join fb_accounts b on a.accountnumber = b.account_number where year = 'SAME' and month = 'AS' and day = 'DATE';
