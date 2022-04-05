WITH closed_account_lookup AS
(
SELECT DISTINCT a.accountnumber, b.loginname as scivantage, opendate, closedate, 'self directed' as sd_managed
FROM securities.accounts a
JOIN lookup.accountloginmap b
ON a.accountnumber = b.accountnumber
---WHERE closedate IS NOT NULL
UNION ALL
SELECT DISTINCT a.accountnumber, b.loginname as scivantage, opendate, closedate, 'managed' as sd_managed
FROM advisor.accounts a
JOIN lookup.accountloginmap b
ON a.accountnumber = b.accountnumber
--WHERE closedate IS NOT NULL
),
login_rollup as(
SELECT scivantage, MAX(CASE WHEN closedate is null THEN 1 else 0 end) as open_account_flag, MAX(closedate) as most_recent_close
From closed_account_lookup
Group by 1
),
closed_logins as(
SELECT *
From login_rollup
Where open_account_flag=0
)
SELECT a.*
FROM login_rollup a
JOIN ai.ally_acm b
ON a.scivantage = b.scivantage
WHERE b.cif IS NULL AND b.processdate = (SELECT MAX(processdate) FROM ai.ally_acm)
OR b.cif = '' AND b.processdate = (SELECT MAX(processdate) FROM ai.ally_acm);
