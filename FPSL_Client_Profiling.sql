create temporary table accounts as(
SELECT A.accountnumber, A.clientid, closedate, opendate, marginind, stockexperience, firstfundeddate
From securities.accounts A
LEFT JOIN securities.firstfundeddate B
ON A.accountnumber=B.accountnumber
Union All
SELECT A.accountnumber, A.clientid, closedate, opendate, marginind, stockexperience, firstfundeddate
From advisor.accounts A
LEFT JOIN advisor.firstfundeddate B
ON A.accountnumber=B.accountnumber
);



create temporary table first_funded as
(
SELECT clientid, min(firstfundeddate) as first_funded_date
From accounts
Group by 1
);



create temporary table first_funded_amount as
(
SELECT
A.clientid,
first_funded_date,
MAX(COALESCE(C.total_equity,D.balance,E.balance)) as first_funded_amount
From accounts A
Inner Join first_funded B
ON A.clientid=B.clientid
LEFT JOIN ai.balance_dailyflow C
ON A.accountnumber=C.accountnumber and B.first_funded_date=C.processdate
LEFT JOIN securities.balancehistory D
ON A.accountnumber=D.accountnumber and B.first_funded_date=D.processdate
LEFT JOIN advisor.balancehistory E
ON A.accountnumber=E.accountnumber and B.first_funded_date=E.processdate
Group by 1,2
);




create temporary table base as (
SELECT
distinct
A.clientid,
taxidnumber,
D.first_funded_date,
first_funded_amount
From accounts A
LEFT JOIN ai.balance_dailyflow B
ON B.processdate=(current_date-1) and A.accountnumber=B.accountnumber
LEFT JOIN apex_ext.ext765_namebase C
ON ((year||'-'||month||'-'||day)::date)=(current_date-1) and C.accountnumber=A.accountnumber
LEFT JOIN first_funded_amount D
ON A.clientid=D.clientid
Where B.fundedind=1
);



create temporary table balances as(
SELECT
clientid,
SUM(CASE WHEN product='SD' THEN fundedind else 0 end) as funded_sd,
SUM(CASE WHEN product='MP' THEN fundedind else 0 end) as funded_mp,
SUM(CASE WHEN product='SD' THEN total_equity else 0 end) as balance_SD,
SUM(CASE WHEN product='MP' THEN total_equity else 0 end) as balance_MP,
SUM(CASE WHEN product='SD' THEN settled_free_cash + settled_money_mkt else 0 end) as cash_SD,
SUM(CASE WHEN product='MP' THEN settled_free_cash + settled_money_mkt else 0 end) as cash_MP,
SUM(CASE WHEN product='SD' THEN settled_margin_debit else 0 end) as margin_SD,
SUM(CASE WHEN product='MP' THEN settled_margin_debit else 0 end) as margin_MP
from ai.balance_dailyflow A
LEFT JOIN accounts B
ON A.accountnumber=B.accountnumber
Where processdate=(current_date-1)
Group by 1
);




create temporary table margin as(
SELECT clientid, MAX(CASE WHEN marginind='Y' THEN 1 else 0 end) as margin_enabled
From accounts
Group by 1
);



create temporary table stock_experience as (
SELECT
clientid,
MAX(CASE WHEN stockexperience LIKE 'Limited' THEN 1
WHEN stockexperience LIKE 'Good' THEN 2
WHEN stockexperience LIKE 'Extensive' THEN 3
ELSE NULL END) as stockexperience
From accounts
Group by 1
);



create temporary table last_twelve_trades as
(
SELECT
clientid,
COUNT(DISTINCT tradedetailid) as trades_twelve_mos,
COUNT(DISTINCT CASE WHEN securitytype='Equity' and price>=2 THEN tradedetailid ELSE NULL END) as non_penny_equity_trades_twelve_mos,
SUM(CASE WHEN securitytype='Equity' and price>=2 THEN commission ELSE NULL END) as non_penny_equity_commission_twelve_mos,
SUM(CASE WHEN securitytype='Equity' and price>=2 THEN ABS(quantity) ELSE NULL END) as non_penny_equity_shares_twelve_mos,
COUNT(DISTINCT CASE WHEN securitytype='Equity' and price<2 THEN tradedetailid ELSE NULL END) as penny_equity_trades_twelve_mos,
SUM(CASE WHEN securitytype='Equity' and price<2 THEN commission ELSE NULL END) as penny_equity_commission_twelve_mos,
SUM(CASE WHEN securitytype='Equity' and price<2 THEN ABS(quantity) ELSE NULL END) as penny_equity_shares_twelve_mos,
COUNT(DISTINCT CASE WHEN securitytype='Option' THEN tradedetailid ELSE NULL END) as option_trades_twelve_mos,
SUM(CASE WHEN securitytype='Option' THEN commission ELSE NULL END) as option_commission_twelve_mos,
SUM(CASE WHEN securitytype='Option' THEN ABS(quantity) ELSE NULL END) as option_contracts_twelve_mos,
COUNT(DISTINCT CASE WHEN securitytype='Mutual Fund' THEN tradedetailid ELSE NULL END) as mfund_trades_twelve_mos,
SUM(CASE WHEN securitytype='Mutual Fund' THEN commission ELSE NULL END) as mfund_commission_twelve_mos,
COUNT(DISTINCT CASE WHEN securitytype='Bond' THEN tradedetailid ELSE NULL END) as bond_trades_twelve_mos,
SUM(CASE WHEN securitytype='Bond' THEN commission ELSE NULL END) as bond_commission_twelve_mos,
COUNT(DISTINCT CASE WHEN order_source='Live' THEN tradedetailid ELSE NULL END) as live_trades_twelve_mos,
COUNT(DISTINCT CASE WHEN order_source='Classic' THEN tradedetailid ELSE NULL END) as classic_trades_twelve_mos,
COUNT(DISTINCT CASE WHEN order_source='Mobile' THEN tradedetailid ELSE NULL END) as mobile_trades_twelve_mos,
COUNT(DISTINCT CASE WHEN order_source='API' THEN tradedetailid ELSE NULL END) as api_trades_twelve_mos
From securities.trades A
LEFT JOIN accounts B
ON A.accountnumber=B.accountnumber
LEFT JOIN
(
SELECT
cl_ord_id,
MAX(CASE WHEN custom_6 LIKE '%partnerID=TKI%' THEN 'Mobile'
WHEN custom_6 LIKE '%partnerID=Live%' THEN 'Live'
WHEN custom_6 LIKE '%partnerID=TKA%' THEN 'API' else 'Classic' end) as order_source
From middleware.oms_oms_order
Group by 1
)C
ON CONCAT('SVI-', A.trailer)=C.cl_ord_id
Where tradedate<=(current_date-1) and tradedate>=(current_date-365)
and cancelind!='Y'
Group by 1
);



create temporary table fpsl_enrolled as(
SELECT
clientid,
MAX(fpsl_enrolled::float) as sip_enrolled_flag
from middleware.tkiods_act_fpsl_settings A
LEFT JOIN accounts B
ON A.acct_no=B.accountnumber
Where ((year||'-'||month||'-'||day)::date)=(current_date-1)
Group by 1
);

create temporary table last_twelve_fpsl_income as(
SELECT
clientid,
SUM(brokershare::float) as sip_income_share_twelve_mos
From apex_ext.ext996_fully_funded_detail A
LEFT JOIN accounts B
ON A.accountnumber=B.accountnumber
Where (processdate::date)<=(current_date-1) and (processdate::date)>=(current_date-365)
Group by 1
);




SELECT
A.clientid,
taxidnumber,
first_funded_date,
first_funded_amount,
funded_sd,
funded_mp,
balance_SD,
balance_MP,
cash_SD,
cash_MP,
margin_SD,
margin_MP,
margin_enabled,
stockexperience,
COALESCE(trades_twelve_mos,0) as trades_twelve_mos,
COALESCE(non_penny_equity_trades_twelve_mos,0) as non_penny_equity_trades_twelve_mos,
COALESCE(non_penny_equity_commission_twelve_mos,0) as non_penny_equity_commission_twelve_mos,
COALESCE(non_penny_equity_shares_twelve_mos,0) as non_penny_equity_shares_twelve_mos,
COALESCE(penny_equity_trades_twelve_mos,0) as penny_equity_trades_twelve_mos,
COALESCE(penny_equity_commission_twelve_mos,0) as penny_equity_commission_twelve_mos,
COALESCE(penny_equity_shares_twelve_mos,0) as equity_shares_twelve_mos,
COALESCE(option_trades_twelve_mos,0) as option_trades_twelve_mos,
COALESCE(option_commission_twelve_mos,0) as option_commission_twelve_mos,
COALESCE(option_contracts_twelve_mos,0) as option_contracts_twelve_mos,
COALESCE(mfund_trades_twelve_mos,0) as mfund_trades_twelve_mos,
COALESCE(mfund_commission_twelve_mos,0) as mfund_commission_twelve_mos,
COALESCE(bond_trades_twelve_mos,0) as bond_trades_twelve_mos,
COALESCE(bond_commission_twelve_mos,0) as bond_commission_twelve_mos,
COALESCE(live_trades_twelve_mos,0) as live_trades_twelve_mos,
COALESCE(classic_trades_twelve_mos,0) as classic_trades_twelve_mos,
COALESCE(mobile_trades_twelve_mos,0) as mobile_trades_twelve_mos,
COALESCE(api_trades_twelve_mos,0) as api_trades_twelve_mos,
COALESCE(sip_enrolled_flag,0) as sip_enrolled_flag,
COALESCE(sip_income_share_twelve_mos,0) as sip_income_share_twelve_mos
From base A
LEFT JOIN balances B
ON A.clientid=B.clientid
LEFT JOIN margin C
ON A.clientid=C.clientid
LEFT JOIN last_twelve_trades D
ON A.clientid=D.clientid
LEFT JOIN fpsl_enrolled E
ON A.clientid=E.clientid
LEFT JOIN last_twelve_fpsl_income F
ON A.clientid=F.clientid
LEFT JOIN stock_experience G
ON A.clientid=G.clientid
