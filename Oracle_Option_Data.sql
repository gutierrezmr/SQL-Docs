SELECT TOP 1000
    UniqueID
    ,eventdatetime
    ,execid
    ,acctno
    ,buysellcode
    ,CASE WHEN buysellcode = 10000 THEN 'B' ELSE 'S' END as Buy_Sell
    ,symbol
    ,SUBSTRING(symbol, CHARINDEX('+', symbol) + 1, CHARINDEX('-',symbol) - CHARINDEX('+', symbol) -1) as OPtion_Root
    ,'20' || SUBSTRING(symbol, CHARINDEX('-', symbol) + 1, 2) || '-' || SUBSTRING(symbol, CHARINDEX('-', symbol) + 3, 2) || '-' || SUBSTRING(symbol, CHARINDEX('-', symbol) + 5, 2) as expiration_date
    ,price
    ,volume
    ,eventtype
    ,*
    FROM ai.mb_clienttrading_orderdata
    WHERE eventtype = 'E'       --executions only
    AND LEFT(Symbol, 1) = '+'   --options only
    AND processdate >= ' """ acct_num[i] """'
    AND Acctno = '""" symbols[i] """'
    AND Symbol LIKE '%""" exp_date[i] """%'
    AND Price = '""" premium[i]
