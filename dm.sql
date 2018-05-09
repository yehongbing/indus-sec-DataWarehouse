CREATE PROCEDURE dm.P_ACC_CPTL_ACC(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 资金账户信息维表
  编写者: DCY
  创建日期: 2017-11-20
  简介：清洗资金账户各个常用的属性信息，每日更新，每月存储
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
  DECLARE @V_MAX_DATE INT;
  
    SET @V_OUT_FLAG = -1;  --初始清洗赋值-1

  --PART0 删除当月数据
  DELETE FROM DM.T_ACC_CPTL_ACC WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
   --变量赋值:得到私财自己维护表（QUERY_SKB.YUNYING_07）的最后日期    
  SET @V_MAX_DATE=(SELECT MAX(LOAD_DT) FROM QUERY_SKB.YUNYING_07);
  
  --PART0 将解析出来的佣金率放入一张临时表
  SELECT 
   FARE_KIND
  ,MIN(CASE WHEN EXCHANGE_TYPE='1' THEN BALANCE_RATIO  END) AS SH_BALANCE_RATIO --沪市佣金率
  ,MIN(CASE WHEN EXCHANGE_TYPE='2' THEN BALANCE_RATIO  END) AS SZ_BALANCE_RATIO --深市佣金率
  ,MIN(BALANCE_RATIO) AS OI_BALANCE_RATIO --普通佣金率
    
  INTO #TEMP_BALANCE_RATIO
	-- SELECT *
  FROM DBA.T_ODS_UF2_BFARE2
    WHERE FARE_TYPE='0'
  GROUP BY FARE_KIND
  ;
  
  --PART1 将每日采集的数据放入临时表
 
	SELECT
	 OUF.FUND_ACCOUNT      AS CPTL_ACCT    --资金账号
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --年
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --月
	,OUF.CLIENT_ID         AS CUST_ID      --客户编码
	,DOH.PK_ORG            AS WH_ORG_ID    --仓库机构编码 
	,CONVERT(VARCHAR,OUF.BRANCH_NO) AS HS_ORG_ID  --恒生机构编码
	,CASE WHEN OUF.MAIN_FLAG='1' THEN '主账' ELSE '副帐' END AS MAINSUB_FLAG --主副标志
	,UF.BANK_NO            AS DEPO_BANK --存管银行
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=UF.BANK_NO AND OUS.DICT_ENTRY=1601) AS DEPO_BANK_NAME    --存管银行名称
	,OUF.FUNDACCT_STATUS   AS CPTL_ACC_STAT --资金账户状态
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUF.FUNDACCT_STATUS AND OUS.DICT_ENTRY=1000) AS CPTL_ACC_STAT_NAME    --资金账户状态名称
	,OUF.ASSET_PROP        AS CPTL_ACC_TYPE --资金账户类型
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUF.ASSET_PROP AND OUS.DICT_ENTRY=3002) AS CPTL_ACC_TYPE_NAME    --资金账户类型名称
	,CONVERT(VARCHAR,OUF.CLIENT_GROUP)  AS CPTL_ACC_GROUP --资金账户分组
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUF.CLIENT_GROUP) AND OUS.DICT_ENTRY=1051) AS CPTL_ACC_GROUP_NAME    --资金账户分组名称
	,CASE WHEN YY.ZJZH IS NULL THEN 0 ELSE YY.ZHLX END AS IF_SPCA_ACCT --是否特殊账号 即0：非特殊账户、1：特殊、2：私募、3：定向
	,ISNULL(TBR.SH_BALANCE_RATIO ,0) AS ODI_CMS_RATE --普通佣金率，用沪市普通佣金率填充（张琦）
	,ISNULL(TBR.SH_BALANCE_RATIO ,0) AS SH_ODI_CMS_RATE --沪市普通佣金率
	,ISNULL(TBR.SZ_BALANCE_RATIO ,0) AS SZ_ODI_CMS_RATE --深市普通佣金率
	,ISNULL(TBR2.SH_BALANCE_RATIO,0) AS CREDIT_CMS_RATE --融资融券佣金率，用沪市信用佣金率填充 
	,ISNULL(TBR2.SH_BALANCE_RATIO,0) AS SH_CRED_CMS_RATE --沪市信用佣金率
	,ISNULL(TBR2.SZ_BALANCE_RATIO,0) AS SZ_CRED_CMS_RATE --深市信用佣金率
	,ISNULL(TBR3.OI_BALANCE_RATIO,0) AS GGT_CMS_RATE     --港股通佣金率   
	,ISNULL(TBR4.OI_BALANCE_RATIO,0) AS OFFUND_CMS_RATE  --场内基金佣金率 
	,ISNULL(TBR5.OI_BALANCE_RATIO,0) AS WRNT_CMS_RATE    --权证佣金率 
	,ISNULL(TBR6.OI_BALANCE_RATIO,0) AS BGDL_CMS_RATE    --大宗交易佣金率 
	,OUF.OPEN_DATE         AS OACT_DT   --开户日期
	,OUF.CANCEL_DATE       AS CANCEL_DT --注销日期
	,@V_BIN_DATE           AS LOAD_DT   --清洗日期
	
	INTO #TEMP_CPTL_ACC
	
	FROM DBA.T_EDW_UF2_FUNDACCOUNT OUF
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUF.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL AND DOH.HR_NAME IS NOT NULL
    LEFT JOIN (--查出存管银行
				SELECT DISTINCT FUND_ACCOUNT,BANK_NO FROM DBA.T_ODS_UF2_FUND
				WHERE MONEY_TYPE='0' --人民币类型
				)UF ON OUF.FUND_ACCOUNT=UF.FUND_ACCOUNT
	LEFT JOIN QUERY_SKB.YUNYING_07 YY  ON YY.LOAD_DT=@V_MAX_DATE AND OUF.FUND_ACCOUNT=YY.ZJZH              --是否特殊账号
	LEFT JOIN #TEMP_BALANCE_RATIO TBR  ON SUBSTR(OUF.FARE_KIND_STR,5,4)= CONVERT(VARCHAR,TBR.FARE_KIND)    --普通佣金率  
	LEFT JOIN #TEMP_BALANCE_RATIO TBR2 ON SUBSTR(OUF.FARE_KIND_STR,34,4)= CONVERT(VARCHAR,TBR2.FARE_KIND)  --信用佣金率
    LEFT JOIN #TEMP_BALANCE_RATIO TBR3 ON SUBSTR(OUF.FARE_KIND_STR,62,4)= CONVERT(VARCHAR,TBR3.FARE_KIND) --港股通佣金率    
    LEFT JOIN #TEMP_BALANCE_RATIO TBR4 ON SUBSTR(OUF.FARE_KIND_STR,13,4)= CONVERT(VARCHAR,TBR4.FARE_KIND) --场内基金佣金率	
    LEFT JOIN #TEMP_BALANCE_RATIO TBR5 ON SUBSTR(OUF.FARE_KIND_STR,25,4)= CONVERT(VARCHAR,TBR5.FARE_KIND) --权证佣金率	
    LEFT JOIN #TEMP_BALANCE_RATIO TBR6 ON SUBSTR(OUF.FARE_KIND_STR,29,4)= CONVERT(VARCHAR,TBR6.FARE_KIND) --大宗交易佣金率
    WHERE OUF.LOAD_DT=@V_BIN_DATE	
	;
	COMMIT;
	
	
	
	--2 最后将当天客户插入进来,第二天同月的会先删除，上一月的没有删掉即保留了
	INSERT INTO DM.T_ACC_CPTL_ACC
	(
	 CPTL_ACCT           --资金账号
    ,YEAR                --年
    ,MTH                 --月
    ,CUST_ID             --客户编码
    ,WH_ORG_ID           --仓库机构编码
    ,HS_ORG_ID           --恒生机构编码
    ,MAINSUB_FLAG        --主副标志
    ,DEPO_BANK           --存管银行
    ,DEPO_BANK_NAME      --存管银行名称
    ,CPTL_ACC_STAT       --资金账户状态
    ,CPTL_ACC_STAT_NAME  --资金账户状态名称
    ,CPTL_ACC_TYPE       --资金账户类型
    ,CPTL_ACC_TYPE_NAME  --资金账户类型名称
    ,CPTL_ACC_GROUP      --资金账户分组
    ,CPTL_ACC_GROUP_NAME --资金账户分组名称
    ,IF_SPCA_ACCT        --是否特殊账号
    ,ODI_CMS_RATE        --普通佣金率
    ,SH_ODI_CMS_RATE     --沪市普通佣金率
    ,SZ_ODI_CMS_RATE     --深市普通佣金率
    ,CREDIT_CMS_RATE     --融资融券佣金率
    ,SH_CRED_CMS_RATE    --沪市信用佣金率
    ,SZ_CRED_CMS_RATE    --深市信用佣金率
    ,GGT_CMS_RATE        --港股通佣金率
    ,OFFUND_CMS_RATE     --场内基金佣金率
    ,WRNT_CMS_RATE       --权证佣金率
    ,BGDL_CMS_RATE       --大宗交易佣金率
    ,OACT_DT             --开户日期
    ,CANCEL_DT           --注销日期
    ,LOAD_DT             --清洗日期
	)
	SELECT
	 DISTINCT CPTL_ACCT           --资金账号
    ,YEAR                --年
    ,MTH                 --月
    ,CUST_ID             --客户编码
    ,WH_ORG_ID           --仓库机构编码
    ,HS_ORG_ID           --恒生机构编码
    ,MAINSUB_FLAG        --主副标志
    ,DEPO_BANK           --存管银行
    ,DEPO_BANK_NAME      --存管银行名称
    ,CPTL_ACC_STAT       --资金账户状态
    ,CPTL_ACC_STAT_NAME  --资金账户状态名称
    ,CPTL_ACC_TYPE       --资金账户类型
    ,CPTL_ACC_TYPE_NAME  --资金账户类型名称
    ,CPTL_ACC_GROUP      --资金账户分组
    ,CPTL_ACC_GROUP_NAME --资金账户分组名称
    ,IF_SPCA_ACCT        --是否特殊账号
    ,ODI_CMS_RATE        --普通佣金率
    ,SH_ODI_CMS_RATE     --沪市普通佣金率
    ,SZ_ODI_CMS_RATE     --深市普通佣金率
    ,CREDIT_CMS_RATE     --融资融券佣金率
    ,SH_CRED_CMS_RATE    --沪市信用佣金率
    ,SZ_CRED_CMS_RATE    --深市信用佣金率
    ,GGT_CMS_RATE        --港股通佣金率
    ,OFFUND_CMS_RATE     --场内基金佣金率
    ,WRNT_CMS_RATE       --权证佣金率
    ,BGDL_CMS_RATE       --大宗交易佣金率
    ,OACT_DT             --开户日期
    ,CANCEL_DT           --注销日期
    ,LOAD_DT             --清洗日期
	FROM #TEMP_CPTL_ACC  TOC
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_ACC_CPTL_ACC TO query_dev
GO
GRANT EXECUTE ON dm.P_ACC_CPTL_ACC TO xydc
GO
CREATE PROCEDURE dm.P_ACC_ITC_SECU_ACC(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 场内证券账户信息维表
  编写者: DCY
  创建日期: 2017-11-28
  简介：清洗场内证券账户信息维表的各个常用的属性信息
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
  
    --PART0 删除当月数据
  DELETE FROM DM.T_ACC_ITC_SECU_ACC WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
  --PART1 将每日采集的数据放入临时表
 
	SELECT
	 TEUS.STOCK_ACCOUNT                AS SECU_ACCT     --证券账号
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --年
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --月
	,TEUS.EXCHANGE_TYPE                AS MKT_TYPE      --市场类型
	,TEUS.OPEN_DATE                    AS OACT_DT       --开户日期
	,TEUS.CLIENT_ID                    AS CUST_ID       --客户编码	
	,TEUS.FUND_ACCOUNT                 AS CPTL_ACCT     --资金账号
	,DOH.PK_ORG                        AS WH_ORG_ID     --仓库机构编码 
	,CONVERT(VARCHAR,TEUS.BRANCH_NO)   AS HS_ORG_ID     --恒生机构编码
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUS.EXCHANGE_TYPE 
	  AND OUS.DICT_ENTRY=1301) AS MKT_TYPE_NAME         --市场类型名称 
	,TEUS.HOLDER_KIND                  AS ITC_SECU_ACC_TYPE        --场内证券账户类型
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUS.HOLDER_KIND 
	  AND OUS.DICT_ENTRY=1208)         AS ITC_SECU_ACC_TYPE_NAME   --场内证券账户类型名称 
	,TEUS.SEAT_NO                      AS SEAT_NO       --席位编号
	,TEUS.HOLDER_STATUS                AS ITC_SECU_ACC_STAT        --场内证券账户状态
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUS.HOLDER_STATUS 
	  AND OUS.DICT_ENTRY=1000)         AS ITC_SECU_ACC_STAT_NAME    --场内证券账户状态名称
	,TEUS.ACODE_ACCOUNT                AS YMT_ACCT                  --一码通账号
	,@V_BIN_DATE                       AS LOAD_DT  --清洗日期
	
	INTO #TMP_ITC_SECU_ACC
	
	FROM DBA.T_EDW_UF2_STOCKHOLDER TEUS
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,TEUS.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL AND DOH.HR_NAME IS NOT NULL
    WHERE TEUS.LOAD_DT=@V_BIN_DATE AND TEUS.BRANCH_NO !=44 --排除总部（只有几个），不然数据会重复
	;
	COMMIT;
	
	--2 最后将当天新增的客户插入进来
	INSERT INTO DM.T_ACC_ITC_SECU_ACC
	(
	 SECU_ACCT               --证券账号
    ,YEAR                    --年
    ,MTH                     --月
	,MKT_TYPE                --市场类型
	,OACT_DT                 --开户日期
	,CUST_ID                 --客户编码
	,CPTL_ACCT               --资金账号
	,WH_ORG_ID               --仓库机构编码
	,HS_ORG_ID               --恒生机构编码
	,MKT_TYPE_NAME           --市场类型名称
	,ITC_SECU_ACC_TYPE       --场内证券账户类型
	,ITC_SECU_ACC_TYPE_NAME  --场内证券账户类型名称
	,SEAT_NO                 --席位编号
	,ITC_SECU_ACC_STAT       --场内证券账户状态
	,ITC_SECU_ACC_STAT_NAME  --场内证券账户状态名称
	,YMT_ACCT                --一码通账号
	,LOAD_DT                 --清洗日期
	)
	SELECT
	 SECU_ACCT               --证券账号
    ,YEAR                    --年
    ,MTH                     --月
	,MKT_TYPE                --市场类型
	,OACT_DT                 --开户日期
	,CUST_ID                 --客户编码
	,CPTL_ACCT               --资金账号
	,WH_ORG_ID               --仓库机构编码
	,HS_ORG_ID               --恒生机构编码
	,MKT_TYPE_NAME           --市场类型名称
	,ITC_SECU_ACC_TYPE       --场内证券账户类型
	,ITC_SECU_ACC_TYPE_NAME  --场内证券账户类型名称
	,SEAT_NO                 --席位编号
	,ITC_SECU_ACC_STAT       --场内证券账户状态
	,ITC_SECU_ACC_STAT_NAME  --场内证券账户状态名称
	,YMT_ACCT                --一码通账号
	,LOAD_DT                 --清洗日期
	FROM #TMP_ITC_SECU_ACC  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_ACC_ITC_SECU_ACC TO query_dev
GO
GRANT EXECUTE ON dm.P_ACC_ITC_SECU_ACC TO xydc
GO
CREATE PROCEDURE dm.P_ACC_OTC_SECU_CHRM_ACC(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 场外证券理财账户信息维表
  编写者: DCY
  创建日期: 2017-11-29
  简介：清洗场外证券理财账户信息维表的各个常用的属性信息
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
              
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
  
  --PART0 删除当月数据
  DELETE FROM DM.T_ACC_OTC_SECU_CHRM_ACC WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
  --PART1 将每日采集的数据放入临时表
 
	SELECT
	 TEUP.SECUM_ACCOUNT                 AS SECU_CHRM_ACCT     --证券理财账号
	,TEUP.PRODTA_NO                    AS PRODTA_ID     --产品TA编码
	,TEUP.TRANS_ACCOUNT                AS TRD_ACCT      --交易账号
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --年
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --月
	,TEUP.CLIENT_ID                    AS CUST_ID       --客户编码	
	,TEUP.FUND_ACCOUNT                 AS CPTL_ACCT     --资金账号
	,DOH.PK_ORG                        AS WH_ORG_ID     --仓库机构编码 
	,CONVERT(VARCHAR,TEUP.BRANCH_NO)   AS HS_ORG_ID     --恒生机构编码
	,TEUP.PRODHOLDER_KIND              AS OTC_CHRM_ACC_TYPE  --场外理财账户类型
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUP.PRODHOLDER_KIND 
	  AND OUS.DICT_ENTRY=41100)        AS OTC_CHRM_ACC_TYPE_NAME    --场外理财账户类型名称 
	,TEUP.ID_KIND                      AS ID_TYPE       --证件类别
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUP.ID_KIND 
	  AND OUS.DICT_ENTRY=1041)         AS ID_TYPE_NAME  --证件类别名称 
	,TEUP.ID_NO                        AS ID_NO         --证件编号	
	
	,TEUP.PRODHOLDER_STATUS            AS PROD_ACC_STAT --产品账户状态
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUP.PRODHOLDER_STATUS 
	  AND OUS.DICT_ENTRY=41101)        AS PROD_ACC_STAT_NAME    --产品账户状态名称
	,TEUP.OPEN_DATE                    AS OACT_DT       --开户日期	
	,TEUP.DIVIDEND_WAY                 AS BONS_MODE     --分红方式
	,TEUP.SEAT_NO                      AS SEAT_NO       --席位编号
	,TEUP.BANK_NO                      AS BANK_NO       --银行编号
	,TEUP.PAY_KIND                     AS PAY_MODE      --支付方式
	,TEUP.PAY_ACCOUNT                  AS PAY_ACCT      --支付账号
	,@V_BIN_DATE                       AS LOAD_DT  --清洗日期
	
	INTO #TMP_OTC_SECU_ACC
	
	FROM DBA.T_EDW_UF2_PRODSECUMHOLDER   TEUP
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,TEUP.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL AND DOH.HR_NAME IS NOT NULL
    WHERE TEUP.LOAD_DT=@V_BIN_DATE 
	;
	COMMIT;
	
	--2 最后将当天新增的客户插入进来
	INSERT INTO DM.T_ACC_OTC_SECU_CHRM_ACC
	(
	 SECU_CHRM_ACCT        --证券理财账号
	,PRODTA_ID             --产品TA编码
	,TRD_ACCT              --交易账号
	,YEAR                  --年
	,MTH                   --月
	,CUST_ID               --客户编码
	,CPTL_ACCT             --资金账号
	,WH_ORG_ID             --仓库机构编码
	,HS_ORG_ID             --恒生机构编码
	,OTC_CHRM_ACC_TYPE     --场外理财账户类型
	,OTC_CHRM_ACC_TYPE_NAME --场外理财账户类型名称
	,ID_TYPE               --证件类别
	,ID_TYPE_NAME          --证件类别名称
	,ID_NO                 --证件编号
	,PROD_ACC_STAT         --产品账户状态
	,PROD_ACC_STAT_NAME    --产品账户状态名称
	,OACT_DT               --开户日期
	,BONS_MODE             --分红方式
	,SEAT_NO               --席位编号
	,BANK_NO               --银行编号
	,PAY_MODE              --支付方式
	,PAY_ACCT              --支付账号
	,LOAD_DT               --清洗日期
	)
	SELECT
	 SECU_CHRM_ACCT        --证券理财账号
	,PRODTA_ID             --产品TA编码
	,TRD_ACCT              --交易账号
	,YEAR                  --年
	,MTH                   --月
	,CUST_ID               --客户编码
	,CPTL_ACCT             --资金账号
	,WH_ORG_ID             --仓库机构编码
	,HS_ORG_ID             --恒生机构编码
	,OTC_CHRM_ACC_TYPE     --场外理财账户类型
	,OTC_CHRM_ACC_TYPE_NAME --场外理财账户类型名称
	,ID_TYPE               --证件类别
	,ID_TYPE_NAME          --证件类别名称
	,ID_NO                 --证件编号
	,PROD_ACC_STAT         --产品账户状态
	,PROD_ACC_STAT_NAME    --产品账户状态名称
	,OACT_DT               --开户日期
	,BONS_MODE             --分红方式
	,SEAT_NO               --席位编号
	,BANK_NO               --银行编号
	,PAY_MODE              --支付方式
	,PAY_ACCT              --支付账号
	,LOAD_DT               --清洗日期
	FROM #TMP_OTC_SECU_ACC  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_ACC_OTC_SECU_CHRM_ACC TO query_dev
GO
GRANT EXECUTE ON dm.P_ACC_OTC_SECU_CHRM_ACC TO xydc
GO
CREATE PROCEDURE dm.P_AGT_APPTBUYB_AGMT(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 约定购回合同
  编写者: DCY
  创建日期: 2017-11-22
  简介：清洗约定购回合同信息
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
  
  --PART0 删除要回洗的数据
  DELETE FROM DM.T_AGT_APPTBUYB_AGMT WHERE OCCUR_DT=@V_BIN_DATE;
  
  INSERT INTO DM.T_AGT_APPTBUYB_AGMT
  (
    CTR_NO                 --合同号
   ,OCCUR_DT               --业务日期
   ,CUST_ID                --客户编码
   ,CPTL_ACCT              --资金账号
   ,WH_ORG_NO              --仓库机构编号
   ,HS_ORG_NO              --恒生机构编号
   ,SECU_CD                --证券代码
   ,SECU_ACCT              --证券账号
   ,RELA_CTR_NO            --关联合同号
   ,WRITT_CTR_NO           --书面合同编号
   ,APPT_CTR_TYPE          --约定合同类型
   ,TRD_TYPE               --交易类别
   ,MATU_RCKON_RETN        --到期年收益率
   ,ORDR_VOL               --委托数量
   ,ORDR_AMT               --委托金额
   ,BUYB_AMT               --购回金额
   ,TFR_IN_DT              --转入日期
   ,ORDR_DT                --委托日期
   ,ORDR_NO                --委托编号
   ,ACTL_BUYB_AMT          --实际购回金额
   ,ACTL_BUYB_DT           --实际购回日期
   ,ACTL_BUYB_INTR         --实际购回利率
   ,APPT_CTR_STAT          --约定合同状态
   ,SUBSCR_DT              --签约日期
   ,RSTK_VOL               --红股数量
   ,BONUS_AMT              --红利金额
   ,CLR_DT                 --清算日期
   ,MEMO                   --备注
   ,LOAD_DT                --清洗日期
  )
  SELECT
    TEA.CONTRACT_ID            --合同号                
   ,@V_BIN_DATE                 --业务日期           
   ,TEA.CLIENT_ID              --客户编码              
   ,CONVERT(VARCHAR,TEA.FUND_ACCOUNT)           --资金账号                 
   ,DOH.PK_ORG                  --仓库机构编号          
   ,CONVERT(VARCHAR,TEA.BRANCH_NO)              --恒生机构编号              
   ,TEA.STOCK_CODE             --证券代码               
   ,TEA.STOCK_ACCOUNT          --证券账号                  
   ,TEA.JOIN_CONTRACT_ID       --关联合同号                     
   ,TEA.PAPERCONT_ID           --书面合同编号                 
   ,TEA.ARP_CONTRACT_TYPE      --约定合同类型                                        
   ,TEA.EXCHANGE_TYPE          --交易类别                  
   ,TEA.EXPIRE_YEAR_RATE       --到期年收益率                     
   ,TEA.ENTRUST_AMOUNT         --委托数量                   
   ,TEA.ENTRUST_BALANCE        --委托金额                    
   ,TEA.BACK_BALANCE           --购回金额                 
   ,TEA.DATE_BACK              --转入日期              
   ,TEA.ENTRUST_DATE           --委托日期                 
   ,CONVERT(VARCHAR,TEA.ENTRUST_NO)             --委托编号               
   ,TEA.REAL_BACK_BALANCE      --实际购回金额                      
   ,TEA.REAL_DATE_BACK         --实际购回日期                   
   ,TEA.REAL_YEAR_RATE         --实际购回利率                   
   ,TEA.CONTRACT_STATUS    --约定合同状态                        
   ,TEA.SIGN_DATE              --签约日期                                
   ,TEA.BONUS_AMOUNT           --红股数量                 
   ,TEA.BONUS_BALANCE          --红利金额                                     
   ,TEA.DATE_CLEAR             --清算日期                              
   ,TEA.REMARK                 --备注           
   ,CONVERT(NUMERIC(8,0),CONVERT(VARCHAR(8),GETDATE(),112))    --清洗日期                        

  FROM DBA.T_EDW_ARPCONTRACT  TEA  --DBA.T_ODS_UF2_ARPCONTRACT TEA
  LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,TEA.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL 
  WHERE TEA.LOAD_DT=@V_BIN_DATE
  ;
   
   COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AGT_APPTBUYB_AGMT TO query_dev
GO
GRANT EXECUTE ON dm.P_AGT_APPTBUYB_AGMT TO xydc
GO
CREATE PROCEDURE dm.P_AGT_CREDIT_AGMT(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 融资融券合约
  编写者: DCY
  创建日期: 2017-11-22
  简介：清洗两融合约信息
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
    --PART0 删除要回洗的数据
  DELETE FROM DM.T_AGT_CREDIT_AGMT WHERE OCCUR_DT=@V_BIN_DATE;
  
  INSERT INTO DM.T_AGT_CREDIT_AGMT
  (
    CONT_NO              --合约编号
   ,OCCUR_DT             --业务日期
   ,CUST_ID              --客户编码
   ,CPTL_ACCT            --资金账号
   ,WH_ORG_NO            --仓库机构编号
   ,HS_ORG_NO            --恒生机构编号
   ,SECU_CD              --证券代码
   ,SECU_ACCT            --证券账号
   ,CTR_NO               --合同号
   ,ORDR_MODE            --委托方式
   ,TRD_TYPE             --交易类别
   ,SECU_TYPE            --证券类别
   ,SECU_TYPE_NAME       --证券类别名称
   ,CCY_TYPE             --币种类别
   ,CONT_TYPE            --合约类别
   ,CONT_TYPE_NAME       --合约类别名称 
   ,ORDR_PRC             --委托价格
   ,ORDR_VOL             --委托数量
   ,CCB_ORDR_ROUG_AMT    --融资买入委托在途金额
   ,CSS_ORDR_ROUG_VOL    --融券卖出委托在途数量
   ,FIN_USED_AMT         --融资占用金额
   ,CRDT_STK_USED_VOL    --融券占用数量
   ,MTCH_PRC             --成交价格
   ,MTCH_VOL             --成交数量
   ,MTCH_AMT             --成交金额
   ,MTCH_CHAG_AMT        --成交手续费金额
   ,STR_CONT_AMT         --期初合约金额
   ,STR_CONT_VOL         --期初合约数量
   ,STR_CONT_TRD_CHAG    --期初合约交易手续费
   ,DAY_REAL_CONT_AMT    --日间实时合约金额
   ,DAY_REAL_CONT_VOL    --日间实时合约数量
   ,DAY_REAL_CONT_CHAG   --日间实时合约手续费
   ,DAY_REAL_INTR_AMT    --日间实时利息金额
   ,CONT_AMT             --合约金额
   ,CONT_VOL             --合约数量
   ,TRD_CHAG             --交易手续费
   ,RTNED_INTR           --已还利息
   ,RCDINFO_STRT_DT      --记息开始日期
   ,EXT_INTA_DAYS        --延迟计息天数
   ,YEAR_INTR            --年利率
   ,MARG_RATE            --保证金比率
   ,CONT_INTR_ARRG       --合约利息积数
   ,CONT_INTR_AMT        --合约利息金额
   ,PNL_INT_ARRG         --罚息积数
   ,PNL_INT_STRT_DT      --罚息开始日期
   ,PNL_INT_INTR         --罚息利率
   ,INTR_DT              --利息日期
   ,INTL_MODE            --利息了结方式
   ,RTN_END_DAY          --归还截止日
   ,DELY_RTN_DAY         --延期归还日
   ,POSTN_NO             --头寸编号
   ,ORDR_NO              --委托编号
   ,CONT_STAT            --合约状态
   ,CONT_SRC             --合约来源
   ,CRT_DT               --创建日期
   ,RTN_DT               --归还日期
   ,CLR_DT               --清算日期
   ,MEMO                 --备注
   ,LOAD_DT              --清洗日期
   )
   SELECT 
    URC.COMPACT_ID                      AS  CONT_NO              --合约编号
   ,@V_BIN_DATE                         AS  OCCUR_DT             --业务日期
   ,URC.CLIENT_ID                       AS  CUST_ID              --客户编码
   ,URC.FUND_ACCOUNT                    AS  CPTL_ACCT            --资金账号
   ,DOH.PK_ORG                          AS  WH_ORG_NO            --仓库机构编号
   ,CONVERT(VARCHAR,URC.BRANCH_NO)      AS  HS_ORG_NO            --恒生机构编号
   ,URC.STOCK_CODE                      AS  SECU_CD              --证券代码
   ,URC.STOCK_ACCOUNT                   AS  SECU_ACCT            --证券账号
   ,URC.CONTRACT_ID                     AS  CTR_NO               --合同号
   ,URC.OP_ENTRUST_WAY                  AS  ORDR_MODE            --委托方式
   ,URC.EXCHANGE_TYPE                   AS  TRD_TYPE             --交易类别
   ,URC.STOCK_TYPE                      AS  SECU_TYPE            --证券类别
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=URC.STOCK_TYPE AND OUS.DICT_ENTRY=1206) AS SECU_TYPE_NAME   --证券类别名称  
   ,URC.MONEY_TYPE                      AS  CCY_TYPE             --币种类别
   ,URC.COMPACT_TYPE                    AS  CONT_TYPE            --合约类别
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=URC.COMPACT_TYPE AND OUS.DICT_ENTRY=31000) AS CONT_TYPE_NAME   --合约类别名称  
   ,URC.ENTRUST_PRICE                   AS  ORDR_PRC             --委托价格
   ,URC.ENTRUST_AMOUNT                  AS  ORDR_VOL             --委托数量
   ,URC.REAL_OCCUPED_BALANCE            AS  CCB_ORDR_ROUG_AMT    --融资买入委托在途金额
   ,URC.REAL_OCCUPED_AMOUNT             AS  CSS_ORDR_ROUG_VOL    --融券卖出委托在途数量
   ,URC.OCCUPED_BALANCE                 AS  FIN_USED_AMT         --融资占用金额
   ,URC.OCCUPED_AMOUNT                  AS  CRDT_STK_USED_VOL    --融券占用数量
   ,URC.BUSINESS_PRICE                  AS  MTCH_PRC             --成交价格
   ,URC.BUSINESS_AMOUNT                 AS  MTCH_VOL             --成交数量
   ,URC.BUSINESS_BALANCE                AS  MTCH_AMT             --成交金额
   ,URC.BUSINESS_FARE                   AS  MTCH_CHAG_AMT        --成交手续费金额
   ,URC.BEGIN_COMPACT_BALANCE           AS  STR_CONT_AMT         --期初合约金额
   ,URC.BEGIN_COMPACT_AMOUNT            AS  STR_CONT_VOL         --期初合约数量
   ,URC.BEGIN_COMPACT_FARE              AS  STR_CONT_TRD_CHAG    --期初合约交易手续费
   ,URC.REAL_COMPACT_BALANCE            AS  DAY_REAL_CONT_AMT    --日间实时合约金额
   ,URC.REAL_COMPACT_AMOUNT             AS  DAY_REAL_CONT_VOL    --日间实时合约数量
   ,URC.REAL_COMPACT_FARE               AS  DAY_REAL_CONT_CHAG   --日间实时合约手续费
   ,URC.REAL_COMPACT_INTEREST           AS  DAY_REAL_INTR_AMT    --日间实时利息金额
   ,URC.COMPACT_BALANCE                 AS  CONT_AMT             --合约金额
   ,URC.COMPACT_AMOUNT                  AS  CONT_VOL             --合约数量
   ,URC.COMPACT_FARE                    AS  TRD_CHAG             --交易手续费
   ,URC.REPAID_INTEREST                 AS  RTNED_INTR           --已还利息
   ,URC.INTEREST_BEGIN_DATE             AS  RCDINFO_STRT_DT      --记息开始日期
   ,URC.DEFERED_DAYS                    AS  EXT_INTA_DAYS        --延迟计息天数
   ,URC.YEAR_RATE                       AS  YEAR_INTR            --年利率
   ,URC.CRDT_RATIO                      AS  MARG_RATE            --保证金比率
   ,URC.COMPACT_INTEGRAL                AS  CONT_INTR_ARRG       --合约利息积数
   ,URC.COMPACT_INTEREST                AS  CONT_INTR_AMT        --合约利息金额
   ,URC.FINE_INTEGRAL                   AS  PNL_INT_ARRG         --罚息积数
   ,URC.FINE_BEGIN_DATE                 AS  PNL_INT_STRT_DT      --罚息开始日期
   ,URC.FINE_RATE                       AS  PNL_INT_INTR         --罚息利率
   ,URC.INTEREST_DATE                   AS  INTR_DT              --利息日期
   ,URC.CRDTINT_MODE                    AS  INTL_MODE            --利息了结方式
   ,URC.RET_END_DATE                    AS  RTN_END_DAY          --归还截止日
   ,URC.DELAY_RET_DATE                  AS  DELY_RTN_DAY         --延期归还日
   ,CONVERT(VARCHAR,URC.CASHGROUP_NO)   AS  POSTN_NO             --头寸编号
   ,CONVERT(VARCHAR,URC.ENTRUST_NO)     AS  ORDR_NO              --委托编号
   ,URC.COMPACT_STATUS                  AS  CONT_STAT            --合约状态
   ,URC.COMPACT_SOURCE                  AS  CONT_SRC             --合约来源
   ,URC.CREATE_DATE                     AS  CRT_DT               --创建日期
   ,URC.REPAID_DATE                     AS  RTN_DT               --归还日期
   ,URC.DATE_CLEAR                      AS  CLR_DT               --清算日期
   ,URC.REMARK                          AS  MEMO                 --备注
   ,CONVERT(NUMERIC(8,0),CONVERT(VARCHAR(8),GETDATE(),112)) AS LOAD_DT    --清洗日期

   
   FROM DBA.T_EDW_UF2_RZRQ_COMPACT URC
   LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,URC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL 
   WHERE URC.LOAD_DT=@V_BIN_DATE
   ;
   
   COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AGT_CREDIT_AGMT TO query_dev
GO
GRANT EXECUTE ON dm.P_AGT_CREDIT_AGMT TO xydc
GO
CREATE PROCEDURE dm.P_AGT_STKPLG_AGMT(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 股票质押合同
  编写者: DCY
  创建日期: 2017-11-22
  简介：清洗股票质押合同信息
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
      --PART0 删除要回洗的数据
  DELETE FROM DM.T_AGT_STKPLG_AGMT WHERE OCCUR_DT=@V_BIN_DATE;
  
  INSERT INTO DM.T_AGT_STKPLG_AGMT
  (
    CTR_NO                   --合同号
   ,OCCUR_DT                 --业务日期
   ,CUST_ID                  --客户编码
   ,CPTL_ACCT                --资金账号
   ,WH_ORG_NO                --仓库机构编号
   ,HS_ORG_NO                --恒生机构编号
   ,SECU_CD                  --证券代码
   ,SECU_ACCT                --证券账号
   ,RELA_CTR_NO              --关联合同号
   ,WRITT_CTR_NO             --书面合同编号
   ,CTR_TYPE                 --合同类型
   ,CTR_TYPE_NAME            --合同类型名称
   ,TRD_TYPE                 --交易类别
   ,SECU_TYPE                --证券类别
   ,SECU_TYPE_NAME           --证券类别名称
   ,CCY_TYPE                 --币种类别
   ,ORDR_VOL                 --委托数量
   ,MATU_RCKON_RETN          --到期年收益率
   ,ORDR_AMT                 --委托金额
   ,BUYB_AMT                 --购回金额
   ,TFR_IN_DT                --转入日期
   ,ACTL_BUYB_INTR           --实际购回利率
   ,ACTL_BUYB_AMT            --实际购回金额
   ,ACTL_BUYB_DT             --实际购回日期
   ,CTR_STAT                 --合同状态
   ,CTR_STAT_NAME            --合同状态名称
   ,CLR_DT                   --清算日期
   ,SUBSCR_DT                --签约日期
   ,ORDR_DT                  --委托日期
   --,ORDR_NO                  --委托编号
   --,MTCH_NO                  --成交编号
   ,CPTL_USES                --资金用途
   ,GUAR_CNVR_PRIC           --担保折算价
   ,AGT_ORDR_FLAG            --代理委托标志
   ,FINAC_OUT_SIDE_NO        --融出方编号
   ,FINAC_OUT_SIDE_NAME        --融出方名称
   ,FINAC_OUT_SIDE_TYPE        --融出方类型
   ,FINAC_OUT_SIDE_TYPE_NAME   --融出方类型名称
   ,INTR_MODE                --利率方式
   ,RSTK_VOL                 --红股数量
   ,BONUS_AMT                --红利金额
   ,BUYB_TYPE                --购回类型
   ,BUYB_TYPE_NAME           --购回类型名称
   ,PTTT_STAT                --预处理状态
   ,CUM_POR_UNPLG_VOL        --累计部分解押数量
   ,CUM_POR_UNPLG_BONUS      --累计部分解押红利
   ,SHAR_CHAR                --股份性质
   ,LAB_DT                   --解禁日期
   ,RTNED_AMT                --已还金额
   ,ALDY_INTR                --已结利息
   ,OTC_REPY_UNCKOT_INTR     --场外偿还未结利息
   ,REP_CTR_SEQ              --申报合同序号
   ,PLG_NO                   --质押编号
   ,LAL_FLAG                 --高管标志
   ,NOTS_TRANSF_PRC          --限售股转让价格
   ,NOTS_ORIG_VAL            --限售股原值
   ,GUAR_CNVR_RATE           --担保折算率
   ,CONCERN_GUAR_PROT_RATE   --关注履约保障比
   ,WARN_GUAR_PROT_RATE      --警告履约保障比
   ,DEAL_GUAR_PROT_RATE      --处置履约保障比
   ,INTR_ARRG                --利息积数
   --,ARRG_MDF_DT              --积数更改日期
   --,LST_INTL_DT              --上次结息日期
   --,BATCH_UNCKOT_INTR        --批量未结利息
   --,STKPLG_PROD_TYPE         --股票质押产品类型
   --,FIN_PURS_PRE_FRZ_INTR    --融资申购预冻利息
   --,FIN_PURS_PRE_FRZ_FEE     --融资申购预冻费用
   --,APP_BUYB_DT              --申请购回日期
   --,APP_BUYB_AMT             --申请购回金额
   ,MEMO                     --备注
   ,LOAD_DT                  --清洗日期
 )
 SELECT 
    GOHS.CONTRACT_ID             --合同号                    
   ,@V_BIN_DATE                  --业务日期                    
   ,GOHS.CLIENT_ID               --客户编码                  
   ,CONVERT(VARCHAR,GOHS.FUND_ACCOUNT)            --资金账号                     
   ,DOH.PK_ORG                   --仓库机构编号               
   ,CONVERT(VARCHAR,GOHS.BRANCH_NO)              --恒生机构编号                  
   ,GOHS.STOCK_CODE              --证券代码                   
   ,GOHS.STOCK_ACCOUNT           --证券账号                      
   ,GOHS.JOIN_CONTRACT_ID        --关联合同号                         
   ,GOHS.PAPERCONT_ID            --书面合同编号                     
   ,GOHS.SRP_CONTRACT_TYPE       --合同类型  
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.SRP_CONTRACT_TYPE AND OUS.DICT_ENTRY=1278) AS CTR_TYPE_NAME   --合同类型名称     
   ,GOHS.EXCHANGE_TYPE           --交易类别                      
   ,GOHS.STOCK_TYPE              --证券类别 
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.STOCK_TYPE AND OUS.DICT_ENTRY=1206) AS SECU_TYPE_NAME   --证券类别名称      
   ,GOHS.MONEY_TYPE              --币种类别                   
   ,GOHS.ENTRUST_AMOUNT          --委托数量                       
   ,GOHS.EXPIRE_YEAR_RATE        --到期年收益率                         
   ,GOHS.ENTRUST_BALANCE         --委托金额                        
   ,GOHS.BACK_BALANCE            --购回金额                     
   ,GOHS.DATE_BACK               --转入日期                  
   ,GOHS.REAL_YEAR_RATE          --实际购回利率                       
   ,GOHS.REAL_BACK_BALANCE       --实际购回金额                          
   ,GOHS.REAL_DATE_BACK          --实际购回日期                       
   ,GOHS.SRP_CONTRACT_STATUS     --合同状态  
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.SRP_CONTRACT_STATUS AND OUS.DICT_ENTRY=1288) AS CTR_STAT_NAME   --合同状态名称 
   ,GOHS.DATE_CLEAR              --清算日期                   
   ,GOHS.SIGN_DATE               --签约日期                  
   ,GOHS.ENTRUST_DATE            --委托日期                     
   --,GOHS.ENTRUST_NO              --委托编号                   
   --,GOHS.CBP_BUSINESS_ID         --成交编号                        
   ,GOHS.FUND_USAGE              --资金用途                   
   ,GOHS.ASSURE_PRICE            --担保折算价                     
   ,GOHS.SRP_AGENT_FLAG          --代理委托标志                       
   ,CONVERT(VARCHAR,GOHS.FUNDER_NO)               --融出方编号  
   ,TOUS.FUNDER_NAME             --融出方名称
   ,TOUS.FUNDER_TYPE             --融出方类型
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TOUS.FUNDER_TYPE AND OUS.DICT_ENTRY=1289) AS FINAC_OUT_SIDE_TYPE_NAME   --融出方类型名称 
   ,GOHS.RATE_MODE               --利率方式                  
   ,GOHS.BONUS_AMOUNT            --红股数量                     
   ,GOHS.BONUS_BALANCE           --红利金额                      
   ,GOHS.BACK_TYPE               --购回类型                  
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.BACK_TYPE AND OUS.DICT_ENTRY=1284) AS BUYB_TYPE_NAME   --购回类型名称 
   ,GOHS.PREV_STATUS             --预处理状态                    
   ,GOHS.SUM_BACK_AMOUNT         --累计部分解押数量                        
   ,GOHS.SUM_BACK_BALANCE        --累计部分解押红利                         
   ,GOHS.STOCK_PROPERTY          --股份性质                       
   ,GOHS.LIFT_DATE               --解禁日期                  
   ,GOHS.REPAID_BALANCE          --已还金额                       
   ,GOHS.SETTLE_INTEREST         --已结利息                        
   ,GOHS.UNSETTLE_INTEREST       --场外偿还未结利息                          
   ,GOHS.REPORT_ID               --申报合同序号                  
   ,GOHS.IMPAWN_ID               --质押编号                  
   ,GOHS.EXECUTIVES_FLAG         --高管标志                        
   ,GOHS.LIMIT_TRANSFER_PRICE    --限售股转让价格                             
   ,GOHS.LIMIT_ORIG_VALUE        --限售股原值                         
   ,GOHS.ASSURE_RATIO            --担保折算率                     
   ,GOHS.MARGIN_FOCUS_RATIO      --关注履约保障比                           
   ,GOHS.MARGIN_ALERT_RATIO      --警告履约保障比                           
   ,GOHS.MARGIN_TREAT_RATIO      --处置履约保障比                           
   ,GOHS.INTEGRAL_BALANCE        --利息积数                         
   --,GOHS.INTEGRAL_UPDATE         --积数更改日期                        
   --,GOHS.LAST_INTEREST_DATE      --上次结息日期                           
   --,GOHS.BATCH_UNSETTLE_INTEREST --批量未结利息                                
   --,GOHS.SRP_KIND                --股票质押产品类型                 
   --,GOHS.IPO_PRE_INTEREST        --融资申购预冻利息                         
   --,GOHS.IPO_PRE_FARE            --融资申购预冻费用                     
   --,GOHS.ASK_DATE_BACK           --申请购回日期                      
   --,GOHS.ASK_BACK_BALANCE        --申请购回金额                         
   ,GOHS.REMARK                  --备注                             
   ,CONVERT(NUMERIC(8,0),CONVERT(VARCHAR(8),GETDATE(),112))      --清洗日期                           

   FROM DBA.GT_ODS_HS06_SRPCONTRACT  GOHS  --DBA.T_ODS_UF2_SRPCONTRACT
   LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,GOHS.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL 
   LEFT JOIN DBA.T_ODS_UF2_SRPFUNDER TOUS ON GOHS.FUNDER_NO=TOUS.FUNDER_NO
   WHERE GOHS.LOAD_DT=@V_BIN_DATE
   ;
   
   COMMIT;
   
   UPDATE dm.T_AGT_STKPLG_AGMT
	SET cptl_uses=REPLACE(REPLACE(REPLACE(cptl_uses,'/',''),'\',''),'|',''),     --客户名称 ,变灰色是由于\引起，不会影响SQL运行
	    memo=REPLACE(REPLACE(REPLACE(memo,'/',''),'\',''),'|','')
		;  
   COMMIT;
   
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AGT_STKPLG_AGMT TO query_dev
GO
GRANT EXECUTE ON dm.P_AGT_STKPLG_AGMT TO xydc
GO
CREATE PROCEDURE dm.P_AST_APPTBUYB(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_资产：约定购回资产
      编写者：chenhu
      创建日期：2017-11-23
      简介：
        客户参与约定购回业务资产
    *********************************************************************/

    COMMIT;
    
    --删除当日数据
    DELETE FROM DM.T_AST_APPTBUYB WHERE OCCUR_DT = @V_IN_DATE;
    
    --插入当日数据
    INSERT INTO DM.T_AST_APPTBUYB
        (CUST_ID,OCCUR_DT,GUAR_SECU_MVAL,APPTBUYB_BAL,SH_GUAR_SECU_MVAL,SZ_GUAR_SECU_MVAL,SH_NOTS_GUAR_SECU_MVAL,SZ_NOTS_GUAR_SECU_MVAL,PROP_FINAC_OUT_SIDE_BAL,ASSM_FINAC_OUT_SIDE_BAL,SM_LOAN_FINAC_OUT_BAL,LOAD_DT)
    SELECT KHBH_HS AS CUST_ID  --客户编码
        ,RQ AS OCCUR_DT         --业务日期
        ,DYZQSZ AS GUAR_SECU_MVAL  --担保证券市值
        ,FZ AS APPTBUYB_BAL  -- 约定购回余额
        ,NULL AS SH_GUAR_SECU_MVAL  --上海担保证券市值，默认为null，后续更新
        ,NULL AS SZ_GUAR_SECU_MVAL  --深圳担保证券市值，默认为null，后续更新
        /*限售股不能做约定购回交易*/
        ,0 AS SH_NOTS_GUAR_SECU_MVAL  --上海限售股担保证券市值
        ,0 AS SZ_NOTS_GUAR_SECU_MVAL  --深圳限售股担保证券市值
        /*融出方为证券公司，无资管等*/
        ,FZ AS PROP_FINAC_OUT_SIDE_BAL  --自营融出方余额
        ,0 AS ASSM_FINAC_OUT_SIDE_BAL  --资管融出方余额
        ,0 AS SM_LOAN_FINAC_OUT_BAL  --小额贷融出余额
        ,RQ AS LOAD_DT  --清洗日期
    FROM DBA.T_DDW_YDSGH_D
    WHERE RQ = @V_IN_DATE;
    
    --更新担保证券市值
    UPDATE DM.T_AST_APPTBUYB
        SET SH_GUAR_SECU_MVAL = COALESCE(BB.SH_GUAR_SECU_MVAL,0)
            ,SZ_GUAR_SECU_MVAL = COALESCE(BB.SZ_GUAR_SECU_MVAL,0)
    FROM DM.T_AST_APPTBUYB AA
    LEFT JOIN (
        SELECT AP.LOAD_DT AS OCCUR_DT    --业务日期
            ,AP.CLIENT_ID AS CUST_ID      --客户编号  
            ,SUM(CASE WHEN AP.EXCHANGE_TYPE = '1' THEN AP.ENTRUST_AMOUNT*HQ.LAST_PRICE ELSE 0 END) AS SH_GUAR_SECU_MVAL --上海担保证券市值
            ,SUM(CASE WHEN AP.EXCHANGE_TYPE = '2' THEN AP.ENTRUST_AMOUNT*HQ.LAST_PRICE ELSE 0 END) AS SZ_GUAR_SECU_MVAL --深圳担保证券市值
        FROM DBA.T_EDW_ARPCONTRACT AP
        LEFT JOIN DBA.T_EDW_UF2_HIS_PRICE HQ
        ON AP.LOAD_DT = HQ.LOAD_DT
        AND AP.EXCHANGE_TYPE = HQ.EXCHANGE_TYPE
        AND AP.STOCK_CODE = HQ.STOCK_CODE
        GROUP BY AP.LOAD_DT,AP.CLIENT_ID
    ) BB
    ON AA.CUST_ID = BB.CUST_ID
    AND AA.OCCUR_DT = BB.OCCUR_DT
    WHERE AA.OCCUR_DT = @V_IN_DATE;
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_APPTBUYB TO xydc
GO
CREATE PROCEDURE dm.P_AST_APPTBUYB_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建约定购回资产月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：约定购回资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --自然日_月末
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --交易日_月初
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --交易日_月末
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --交易日_年初
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --自然天数_月
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --交易天数_月
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --自然天数_年
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --交易天数_年


    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
 

--PART0 删除当月数据
  DELETE FROM DM.T_AST_APPTBUYB_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    INSERT INTO DM.T_AST_APPTBUYB_M_D 
    (
	 CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,GUAR_SECU_MVAL_FINAL
	,APPTBUYB_BAL_FINAL
	,SH_GUAR_SECU_MVAL_FINAL
	,SZ_GUAR_SECU_MVAL_FINAL
	,SH_NOTS_GUAR_SECU_MVAL_FINAL
	,SZ_NOTS_GUAR_SECU_MVAL_FINAL
	,PROP_FINAC_OUT_SIDE_BAL_FINAL
	,ASSM_FINAC_OUT_SIDE_BAL_FINAL
	,SM_LOAN_FINAC_OUT_BAL_FINAL
	,GUAR_SECU_MVAL_MDA
	,APPTBUYB_BAL_MDA
	,SH_GUAR_SECU_MVAL_MDA
	,SZ_GUAR_SECU_MVAL_MDA
	,SH_NOTS_GUAR_SECU_MVAL_MDA
	,SZ_NOTS_GUAR_SECU_MVAL_MDA
	,PROP_FINAC_OUT_SIDE_BAL_MDA
	,ASSM_FINAC_OUT_SIDE_BAL_MDA
	,SM_LOAN_FINAC_OUT_BAL_MDA
	,GUAR_SECU_MVAL_YDA
	,APPTBUYB_BAL_YDA
	,SH_GUAR_SECU_MVAL_YDA
	,SZ_GUAR_SECU_MVAL_YDA
	,SH_NOTS_GUAR_SECU_MVAL_YDA
	,SZ_NOTS_GUAR_SECU_MVAL_YDA
	,PROP_FINAC_OUT_SIDE_BAL_YDA
	,ASSM_FINAC_OUT_SIDE_BAL_YDA
	,SM_LOAN_FINAC_OUT_BAL_YDA
	,LOAD_DT
	)
select
	t1.CUST_ID   as 客户编码
    ,@V_BIN_DATE AS OCCUR_DT
	,t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码		
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end) 			as 担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.APPTBUYB_BAL,0) else 0 end)		 		as 约定购回余额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SH_GUAR_SECU_MVAL,0) else 0 end) 		as 上海担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SZ_GUAR_SECU_MVAL,0) else 0 end) 		as 深圳担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0) else 0 end) 	as 上海限售股担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0) else 0 end) 	as 深圳限售股担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0) else 0 end) 	as 自营融出方余额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0) else 0 end) 	as 资管融出方余额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0) else 0 end) 	as 小额贷融出余额_期末

	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 			as 担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_BAL,0) else 0 end)/t_rq.自然天数_月 			as 约定购回余额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SH_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 		as 上海担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SZ_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 		as 深圳担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 	as 上海限售股担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 	as 深圳限售股担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0) else 0 end)/t_rq.自然天数_月 as 自营融出方余额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0) else 0 end)/t_rq.自然天数_月 as 资管融出方余额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0) else 0 end)/t_rq.自然天数_月 	as 小额贷融出余额_月日均

	,sum(COALESCE(t1.GUAR_SECU_MVAL,0))/t_rq.自然天数_年 			as 担保证券市值_年日均
	,sum(COALESCE(t1.APPTBUYB_BAL,0))/t_rq.自然天数_年 				as 约定购回余额_年日均
	,sum(COALESCE(t1.SH_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 		as 上海担保证券市值_年日均
	,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 		as 深圳担保证券市值_年日均
	,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 	as 上海限售股担保证券市值_年日均
	,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 	as 深圳限售股担保证券市值_年日均
	,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0))/t_rq.自然天数_年 	as 自营融出方余额_年日均
	,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0))/t_rq.自然天数_年 	as 资管融出方余额_年日均
	,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0))/t_rq.自然天数_年 	as 小额贷融出余额_年日均
	,@V_BIN_DATE
from
(
	select
		@V_BIN_YEAR as 年
		,@V_BIN_MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,@V_BIN_NATRE_DAY_MTHBEG    as 自然日_月初
		,@V_BIN_NATRE_DAY_MTHEND    as 自然日_月末
		,@V_BIN_TRD_DAY_MTHBEG      as 交易日_月初
		,@V_BIN_TRD_DAY_MTHEND      as 交易日_月末
		,@V_BIN_NATRE_DAY_YEARBGN   as 自然日_年初
		,@V_BIN_TRD_DAY_YEARBGN     as 交易日_年初
		,@V_BIN_NATRE_DAYS_MTH      as 自然天数_月
		,@V_BIN_TRD_DAYS_MTH        as 交易天数_月
		,@V_BIN_NATRE_DAYS_YEAR     as 自然天数_年
		,@V_BIN_TRD_DAYS_YEAR       as 交易天数_年
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
left join DM.T_AST_APPTBUYB t1 on t_rq.交易日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.p_ast_cptl_chg(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能: 资产变动表
  编写者: rengz
  创建日期: 2017-11-21
  简介：客户资金变动数据，日更新
        主要数据来自于：T_DDW_F00_KHMRZJZHHZ_D 日报 普通账户资金 及市值流入流出
                        tmp_ddw_khqjt_m_m     融资融券客户资金流入 流出

  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180315                 rengz              修订市值流入流出
  *********************************************************************/
 
    --declare @v_bin_date numeric(8); 
    
    set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date;
	
    --生成衍生变量
    --set @v_b_date=(select min(rq) from dba.t_ddw_d_rq where nian=substring(@V_BIN_DATE,1,4) and yue=substring(@V_BIN_DATE,5,2) and sfjrbz='1' ); 
   
    --删除计算期数据
    delete from dm.t_ast_cptl_chg where load_dt =@v_bin_date;
    commit;
     
------------------------
  -- 生成每日客户清单
------------------------  
    select distinct fund_account, client_id, asset_prop, main_flag
      into #t_client
      from dba.t_edw_uf2_fundaccount
     where load_dt = @v_bin_date
       and fundacct_status = '0';
    commit;
     
    insert into dm.t_ast_cptl_chg(OCCUR_DT,CUST_ID, MAIN_CPTL_ACCT,CRED_CPTL_ACCT,LOAD_DT)
    select @v_bin_date as occur_dt,a.client_id,b.fund_account as zjzh_pt,c.fund_account as zjzh_xy,@v_bin_date as load_dt
    from (select distinct client_id from #t_client where  main_flag = '1')     a
    left join (select distinct client_id,fund_account from #t_client where asset_prop='0' and main_flag = '1') b on a.client_id=b.client_id
    left join (select distinct client_id,fund_account from #t_client where asset_prop='7' and main_flag = '1') c on a.client_id=c.client_id
    where a.client_id not in ('448999999'); ----剔除1户“专项头寸账户自动生成”。疑似公司自有账户，client_id下无普通账户，仅有23个信用账户且均为主资金户

   commit;

------------------------
  -- 普通资金账号资金流入 资金流出
------------------------
 
  select c.client_id as cust_id,
         sum(a.zjlr * b.turn_rmb / b.turn_rate) as ptzjlr,
         sum(a.zjlc * b.turn_rmb / b.turn_rate) as ptzjlc,
         ptzjlr - ptzjlc as ptzjjlr
    into #t_pt_zjld
    from dba.t_ddw_f00_khzjhz_d a
    left join dba.T_EDW_T06_YEAR_EXCHANGE_RATE b
      on a.tjrq between b.star_dt and b.end_dt
     and a.bzlb = b.curr_type_cd
    left join (select distinct client_id, fund_account
                 from #t_client
                where asset_prop = '0') c
      on a.zjzh = c.fund_account
   where a.load_dt = @v_bin_date
   group by cust_id;

  commit;

 
   update dm.t_ast_cptl_chg  
   set ODI_CPTL_INFLOW         =coalesce(b.ptzjlr,0) ,----普通资金流入
       ODI_CPTL_OUTFLOW        =coalesce(b.ptzjlc,0), ----普通资金流出
       ODI_ACC_CPTL_NET_INFLOW =coalesce(b.ptzjjlr,0) ----普通资金净流入
   from  dm.t_ast_cptl_chg a
   left join    #t_pt_zjld b on a.cust_id       =b.cust_id
   where a.OCCUR_DT      =@v_bin_date ;
   commit;
 

------------------------
  -- 普通资金账号市值流入 市值流出
------------------------
  select c.client_id as cust_id,
       --每日市值流入 = 转托管转入市值＋指定转入市值 + 部分特殊业务(3410---新股上市到账)
       SUM((COALESCE(a.ztgzrsz, 0) + COALESCE(a.zdzrsz, 0)) +
           (COALESCE(case when a.busi_type_cd = '3410' and a.zqlx in ('10', '18') and a.sclx = '05' then a.qsje else 0 end, 0)) * b.turn_rmb / b.turn_rate) as mrszlr,
       --每日市值流出 = 转托管转出市值＋指定转出市值
       SUM((COALESCE(a.ztgzcsz, 0) + COALESCE(a.zdzcsz, 0)) * b.turn_rmb / b.turn_rate) as mrszlc
  into #t_pt_szld
  from dba.T_DDW_F00_KHZQHZ_D a
  left join dba.T_EDW_T06_YEAR_EXCHANGE_RATE b on a.tjrq between b.star_dt and b.end_dt and a.bzlb = b.curr_type_cd
    left join (select distinct client_id, fund_account
                 from #t_client
                where asset_prop = '0') c
      on a.zjzh = c.fund_account
  where a.load_dt = @v_bin_date 
 group by cust_id;


   update dm.t_ast_cptl_chg 
   set ODI_MVAL_INFLOW  =coalesce(b.mrszlr,0) ,----普通市值流入
       ODI_MVAL_OUTFLOW =coalesce(b.mrszlc,0)  ----普通市值流出            ---20180315 修订流出
   from  dm.t_ast_cptl_chg a
   left join    #t_pt_szld b on a.cust_id       =b.cust_id
   where a.OCCUR_DT      =@v_bin_date ;
   commit;


 
------------------------
  -- 信用账号资金流入 资金流出
------------------------
     select client_id as cust_id,
            SUM(case when business_flag = 2041 then ABS(occur_balance) else 0 end) as zjlr_rzrq_d, -- 当日资金转入_融资融券系统
            SUM(case when business_flag = 2042 then ABS(occur_balance) else 0 end) as zjlc_rzrq_d, -- 当日资金转出_融资融券系统
            zjlr_rzrq_d - zjlc_rzrq_d as zjjlr_rzrq_d  -- 当日资金净流入_融资融券系统
     into #t_rzrq_zjld
       from dba.t_edw_rzrq_hisfundjour as a
      where a.load_dt=@v_bin_date
        and a.business_flag in (2041, 2042)
      group by cust_id;
 
 commit;


   update dm.t_ast_cptl_chg  
   set CREDIT_CPTL_INFLOW     =coalesce(b.zjlr_rzrq_d,0) ,----两融资金流入
       CREDIT_CPTL_OUTFLOW    =coalesce(b.zjlc_rzrq_d,0) ,----两融资金流出
       CREDIT_CPTL_NET_INFLOW =coalesce(b.zjjlr_rzrq_d,0) ----两融资金净流入 
   from  dm.t_ast_cptl_chg a
   left join  #t_rzrq_zjld b on a.CUST_ID =b.cust_id
   where a.OCCUR_DT=@v_bin_date ;

commit;

  set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 

end
GO
GRANT EXECUTE ON dm.p_ast_cptl_chg TO query_dev
GO
GRANT EXECUTE ON dm.p_ast_cptl_chg TO xydc
GO
CREATE PROCEDURE dm.P_AST_CPTL_CHG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建资产变动月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：资产变动月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --自然日_月末
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --交易日_月初
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --交易日_月末
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --交易日_年初
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --自然天数_月
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --交易天数_月
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --自然天数_年
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --交易天数_年


    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
 
--PART0 删除当月数据
  DELETE FROM DM.T_AST_CPTL_CHG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_AST_CPTL_CHG_M_D 
	(
	CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,ODI_CPTL_INFLOW_MTD
	,ODI_CPTL_OUTFLOW_MTD
	,ODI_MVAL_INFLOW_MTD
	,ODI_MVAL_OUTFLOW_MTD
	,CREDIT_CPTL_INFLOW_MTD
	,CREDIT_CPTL_OUTFLOW_MTD
	,ODI_ACC_CPTL_NET_INFLOW_MTD
	,CREDIT_CPTL_NET_INFLOW_MTD
	,ODI_CPTL_INFLOW_YTD
	,ODI_CPTL_OUTFLOW_YTD
	,ODI_MVAL_INFLOW_YTD
	,ODI_MVAL_OUTFLOW_YTD
	,CREDIT_CPTL_INFLOW_YTD
	,CREDIT_CPTL_OUTFLOW_YTD
	,ODI_ACC_CPTL_NET_INFLOW_YTD
	,CREDIT_CPTL_NET_INFLOW_YTD
	,LOAD_DT
	)
select		
	t1.CUST_ID as 客户编码
    ,@V_BIN_DATE AS OCCUR_DT	
	,t_rq.年
	,t_rq.月		
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_CPTL_INFLOW else 0 end) 			as 普通资金流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_CPTL_OUTFLOW else 0 end) 		as 普通资金流出_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_MVAL_INFLOW else 0 end) 			as 普通市值流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_MVAL_OUTFLOW else 0 end) 		as 普通市值流出_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.CREDIT_CPTL_INFLOW else 0 end) 		as 两融资金流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.CREDIT_CPTL_OUTFLOW else 0 end) 		as 两融资金流出_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_ACC_CPTL_NET_INFLOW else 0 end) 	as 普通账户资金净流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.CREDIT_CPTL_NET_INFLOW else 0 end) 	as 两融资金净流入_月累计

	,sum(t1.ODI_CPTL_INFLOW) 			as 普通资金流入_年累计
	,sum(t1.ODI_CPTL_OUTFLOW) 			as 普通资金流出_年累计
	,sum(t1.ODI_MVAL_INFLOW) 			as 普通市值流入_年累计
	,sum(t1.ODI_MVAL_OUTFLOW) 			as 普通市值流出_年累计
	,sum(t1.CREDIT_CPTL_INFLOW) 		as 两融资金流入_年累计
	,sum(t1.CREDIT_CPTL_OUTFLOW) 		as 两融资金流出_年累计
	,sum(t1.ODI_ACC_CPTL_NET_INFLOW)	as 普通账户资金净流入_年累计
	,sum(t1.CREDIT_CPTL_NET_INFLOW) 	as 两融资金净流入_年累计
	,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as 年
		,@V_BIN_MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,@V_BIN_NATRE_DAY_MTHBEG    as 自然日_月初
		,@V_BIN_NATRE_DAY_MTHEND    as 自然日_月末
		,@V_BIN_TRD_DAY_MTHBEG      as 交易日_月初
		,@V_BIN_TRD_DAY_MTHEND      as 交易日_月末
		,@V_BIN_NATRE_DAY_YEARBGN   as 自然日_年初
		,@V_BIN_TRD_DAY_YEARBGN     as 交易日_年初
		,@V_BIN_NATRE_DAYS_MTH      as 自然天数_月
		,@V_BIN_TRD_DAYS_MTH        as 交易天数_月
		,@V_BIN_NATRE_DAYS_YEAR     as 自然天数_年
		,@V_BIN_TRD_DAYS_YEAR       as 交易天数_年
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
--资产变动不填充
left join DM.T_AST_CPTL_CHG t1 on t_rq.交易日期=t1.OCCUR_DT	
group by
	t_rq.年
	,t_rq.月		
	,t1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.P_AST_CREDIT(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_资产：融资融券资产负债
      编写者：chenhu
      创建日期：2017-11-22
      简介：
        两融客户数据的资产与负债
    *********************************************************************
   修订记录： 修订日期       版本号    修订人             修改内容简要说明
              20180412                 rengz              增加A股市值
   *********************************************************************/

    --删除当日数据
    DELETE FROM DM.T_AST_CREDIT WHERE OCCUR_DT = @V_IN_DATE;
    
    INSERT INTO DM.T_AST_CREDIT
        (CUST_ID,OCCUR_DT,TOT_AST,TOT_LIAB,NET_AST,CRED_MARG,GUAR_SECU_MVAL,FIN_LIAB,CRDT_STK_LIAB,INTR_LIAB,FEE_LIAB,OTH_LIAB,LOAD_DT)
    SELECT CLIENT_ID    AS CUST_ID          --客户编号
        ,INIT_DATE      AS OCCUR_DT         --业务日期
        ,ASSURE_CLOSE_BALANCE   AS TOT_AST  --总资产
        ,COALESCE(FIN_CLOSE_BALANCE, 0) + COALESCE(SLO_CLOSE_BALANCE, 0) + COALESCE(FARE_CLOSE_DEBIT, 0) + COALESCE(OTHER_CLOSE_DEBIT, 0) + 
         COALESCE(FIN_CLOSE_INTEREST, 0) + COALESCE(SLO_CLOSE_INTEREST, 0) + COALESCE(FARE_CLOSE_INTEREST, 0) + COALESCE(OTHER_CLOSE_INTEREST, 0) +
         COALESCE(FIN_CLOSE_FINE_INTEREST, 0) + COALESCE(SLO_CLOSE_FINE_INTEREST, 0) + COALESCE(OTHER_CLOSE_FINE_INTEREST, 0) + COALESCE(REFCOST_CLOSE_FARE, 0) AS TOT_LIAB     --总负债
        ,TOT_AST - TOT_LIAB     AS NET_AST          --净资产
        ,CURRENT_BALANCE        AS CRED_MARG        --信用保证金
        ,MARKET_CLOSE_VALUE     AS GUAR_SECU_MVAL   --担保证券市值
        ,FIN_CLOSE_BALANCE      AS FIN_LIAB         --融资负债
        ,SLO_CLOSE_BALANCE      AS CRDT_STK_LIAB    --融券负债
        ,COALESCE(FIN_CLOSE_INTEREST, 0) + COALESCE(SLO_CLOSE_INTEREST, 0) + COALESCE(FARE_CLOSE_INTEREST, 0) + COALESCE(OTHER_CLOSE_INTEREST, 0)               AS INTR_LIAB    --利息负债
        ,FARE_CLOSE_DEBIT       AS FEE_LIAB         --费用负债
        ,OTHER_CLOSE_DEBIT      AS OTH_LIAB         --其他负债
        ,INIT_DATE              AS LOAD_DT          --清洗日期
    FROM DBA.T_EDW_UF2_RZRQ_ASSETDEBIT
    WHERE INIT_DATE = @V_IN_DATE;    
    
    COMMIT;

    --信用账户A股市值
     select client_id,sum(a.current_amount*b.trad_price) as A_SHR_MVAL 
     into #t_xysz
      from   dba.t_edw_rzrq_stock  a
     left join dba.t_edw_t06_stock_maket_info  b on a.load_dt=b.load_dt and a.STOCK_CODE=b.stock_cd  and b.stock_type_cd in ('10','A1')
     where a.load_dt=@V_IN_DATE
     group by a.client_id;

    update DM.T_AST_CREDIT 
    set  A_SHR_MVAL=coalesce(b.A_SHR_MVAL,0)
    from DM.T_AST_CREDIT a 
    left join #t_xysz    b on a.cust_id=b.client_id
    where a.OCCUR_DT=@V_IN_DATE;
    
    commit;

END
GO
GRANT EXECUTE ON dm.P_AST_CREDIT TO xydc
GO
CREATE PROCEDURE dm.P_AST_CREDIT_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建融资融券资产月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：融资融券资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --自然日_月末
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --交易日_月初
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --交易日_月末
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --交易日_年初
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --自然天数_月
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --交易天数_月
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --自然天数_年
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --交易天数_年


    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 删除当月数据
  DELETE FROM DM.T_AST_CREDIT_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_AST_CREDIT_M_D 
	(
	CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,TOT_LIAB_FINAL
	,NET_AST_FINAL
	,CRED_MARG_FINAL
	,GUAR_SECU_MVAL_FINAL
	,FIN_LIAB_FINAL
	,CRDT_STK_LIAB_FINAL
	,INTR_LIAB_FINAL
	,FEE_LIAB_FINAL
	,OTH_LIAB_FINAL
	,TOT_AST_FINAL
	,A_SHR_MVAL_FINAL
	,TOT_LIAB_MDA
	,NET_AST_MDA
	,CRED_MARG_MDA
	,GUAR_SECU_MVAL_MDA
	,FIN_LIAB_MDA
	,CRDT_STK_LIAB_MDA
	,INTR_LIAB_MDA
	,FEE_LIAB_MDA
	,OTH_LIAB_MDA
	,TOT_AST_MDA
	,A_SHR_MVAL_MDA
	,TOT_LIAB_YDA
	,NET_AST_YDA
	,CRED_MARG_YDA
	,GUAR_SECU_MVAL_YDA
	,FIN_LIAB_YDA
	,CRDT_STK_LIAB_YDA
	,INTR_LIAB_YDA
	,FEE_LIAB_YDA
	,OTH_LIAB_YDA
	,TOT_AST_YDA
	,A_SHR_MVAL_YDA
	,LOAD_DT
	)
select
    t1.CUST_ID as 客户编码	
	,@V_BIN_DATE AS OCCUR_DT
	,t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编号
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.TOT_LIAB,0) else 0 end) 		as 总负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.NET_AST,0) else 0 end) 		as 净资产_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CRED_MARG,0) else 0 end) 	as 信用保证金_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end) as 担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.FIN_LIAB,0) else 0 end) 		as 融资负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CRDT_STK_LIAB,0) else 0 end) as 融券负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.INTR_LIAB,0) else 0 end) 	as 利息负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.FEE_LIAB,0) else 0 end) 		as 费用负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTH_LIAB,0) else 0 end) 		as 其他负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.TOT_AST,0) else 0 end) 		as 总资产_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.A_SHR_MVAL,0) else 0 end) 

	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.TOT_LIAB,0) else 0 end)/t_rq.自然天数_月 		as 总负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.NET_AST,0) else 0 end)/t_rq.自然天数_月 		as 净资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRED_MARG,0) else 0 end)/t_rq.自然天数_月 		as 信用保证金_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 	as 担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_LIAB,0) else 0 end)/t_rq.自然天数_月 		as 融资负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_LIAB,0) else 0 end)/t_rq.自然天数_月 	as 融券负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.INTR_LIAB,0) else 0 end)/t_rq.自然天数_月 		as 利息负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FEE_LIAB,0) else 0 end)/t_rq.自然天数_月		as 费用负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTH_LIAB,0) else 0 end)/t_rq.自然天数_月 		as 其他负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.TOT_AST,0) else 0 end)/t_rq.自然天数_月 		as 总资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.A_SHR_MVAL,0) else 0 end)/t_rq.自然天数_月 

	,sum(COALESCE(t1.TOT_LIAB,0))/t_rq.自然天数_年 			as 总负债_年日均
	,sum(COALESCE(t1.NET_AST,0))/t_rq.自然天数_年 			as 净资产_年日均
	,sum(COALESCE(t1.CRED_MARG,0))/t_rq.自然天数_年 		as 信用保证金_年日均
	,sum(COALESCE(t1.GUAR_SECU_MVAL,0))/t_rq.自然天数_年 	as 担保证券市值_年日均
	,sum(COALESCE(t1.FIN_LIAB,0))/t_rq.自然天数_年 			as 融资负债_年日均
	,sum(COALESCE(t1.CRDT_STK_LIAB,0))/t_rq.自然天数_年 	as 融券负债_年日均
	,sum(COALESCE(t1.INTR_LIAB,0))/t_rq.自然天数_年 as 利息负债_年日均
	,sum(COALESCE(t1.FEE_LIAB,0))/t_rq.自然天数_年 	as 费用负债_年日均
	,sum(COALESCE(t1.OTH_LIAB,0))/t_rq.自然天数_年 	as 其他负债_年日均
	,sum(COALESCE(t1.TOT_AST,0))/t_rq.自然天数_年 	as 总资产_年日均
	,sum(COALESCE(t1.A_SHR_MVAL,0))/t_rq.自然天数_年
    ,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as 年
		,@V_BIN_MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,@V_BIN_NATRE_DAY_MTHBEG    as 自然日_月初
		,@V_BIN_NATRE_DAY_MTHEND    as 自然日_月末
		,@V_BIN_TRD_DAY_MTHBEG      as 交易日_月初
		,@V_BIN_TRD_DAY_MTHEND      as 交易日_月末
		,@V_BIN_NATRE_DAY_YEARBGN   as 自然日_年初
		,@V_BIN_TRD_DAY_YEARBGN     as 交易日_年初
		,@V_BIN_NATRE_DAYS_MTH      as 自然天数_月
		,@V_BIN_TRD_DAYS_MTH        as 交易天数_月
		,@V_BIN_NATRE_DAYS_YEAR     as 自然天数_年
		,@V_BIN_TRD_DAYS_YEAR       as 交易天数_年
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
left join DM.T_AST_CREDIT t1 on t_rq.交易日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.P_AST_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部资产（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-10
  简介：营业部维度的客户资产表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_AST_D_BRH WHERE OCCUR_DT = @V_DATE;

	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--员工编码
		,A.PK_ORG 		AS 		BRH_ID			--营业部编码
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  	  	AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	CREATE TABLE #TMP_T_AST_D_BRH(
	    OCCUR_DT             numeric(8,0) 	NOT NULL,
		EMP_ID               varchar(30) 	NOT NULL,
		BRH_ID		  		 varchar(30) 	NOT NULL,
		TOT_AST              numeric(38,8) NULL,
		SCDY_MVAL            numeric(38,8) NULL,
		STKF_MVAL            numeric(38,8) NULL,
		A_SHR_MVAL           numeric(38,8) NULL,
		NOTS_MVAL            numeric(38,8) NULL,
		OFFUND_MVAL          numeric(38,8) NULL,
		OPFUND_MVAL          numeric(38,8) NULL,
		SB_MVAL              numeric(38,8) NULL,
		IMGT_PD_MVAL         numeric(38,8) NULL,
		BANK_CHRM_MVAL       numeric(38,8) NULL,
		SECU_CHRM_MVAL       numeric(38,8) NULL,
		PSTK_OPTN_MVAL       numeric(38,8) NULL,
		B_SHR_MVAL           numeric(38,8) NULL,
		OUTMARK_MVAL         numeric(38,8) NULL,
		CPTL_BAL             numeric(38,8) NULL,
		NO_ARVD_CPTL         numeric(38,8) NULL,
		PTE_FUND_MVAL        numeric(38,8) NULL,
		CPTL_BAL_RMB         numeric(38,8) NULL,
		CPTL_BAL_HKD         numeric(38,8) NULL,
		CPTL_BAL_USD         numeric(38,8) NULL,
		FUND_SPACCT_MVAL     numeric(38,8) NULL,
		HGT_MVAL             numeric(38,8) NULL,
		SGT_MVAL             numeric(38,8) NULL,
		TOT_AST_CONTAIN_NOTS numeric(38,8) NULL,
		BOND_MVAL            numeric(38,8) NULL,
		REPO_MVAL            numeric(38,8) NULL,
		TREA_REPO_MVAL       numeric(38,8) NULL,
		REPQ_MVAL            numeric(38,8) NULL,
		PO_FUND_MVAL         numeric(38,8) NULL,
		APPTBUYB_PLG_MVAL    numeric(38,8) NULL,
		OTH_PROD_MVAL        numeric(38,8) NULL,
		STKT_FUND_MVAL       numeric(38,8) NULL,
		OTH_AST_MVAL         numeric(38,8) NULL,
		CREDIT_MARG          numeric(38,8) NULL,
		CREDIT_NET_AST       numeric(38,8) NULL,
		PROD_TOT_MVAL        numeric(38,8) NULL,
		JQL9_MVAL            numeric(38,8) NULL,
		STKPLG_GUAR_SECMV    numeric(38,8) NULL,
		STKPLG_FIN_BAL       numeric(38,8) NULL,
		APPTBUYB_BAL         numeric(38,8) NULL,
		CRED_MARG            numeric(38,8) NULL,
		INTR_LIAB            numeric(38,8) NULL,
		FEE_LIAB             numeric(38,8) NULL,
		OTHLIAB              numeric(38,8) NULL,
		FIN_LIAB             numeric(38,8) NULL,
		CRDT_STK_LIAB        numeric(38,8) NULL,
		CREDIT_TOT_AST       numeric(38,8) NULL,
		CREDIT_TOT_LIAB      numeric(38,8) NULL,
		APPTBUYB_GUAR_SECMV  numeric(38,8) NULL,
		CREDIT_GUAR_SECMV    numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_AST_D_BRH(
		 OCCUR_DT            		--发生日期	
		,EMP_ID              		--员工编号
		,BRH_ID		  		 		--营业部编号	
		,TOT_AST             		--总资产	
		,SCDY_MVAL           		--二级市值	
		,STKF_MVAL           		--股基市值	
		,A_SHR_MVAL          		--A股市值	
		,NOTS_MVAL           		--限售股市值	
		,OFFUND_MVAL         		--场内基金市值	
		,OPFUND_MVAL         		--场外基金市值	
		,SB_MVAL             		--三板市值	
		,IMGT_PD_MVAL        		--资管产品市值	
		,BANK_CHRM_MVAL      		--银行理财市值	
		,SECU_CHRM_MVAL      		--证券理财市值	
		,PSTK_OPTN_MVAL      		--个股期权市值	
		,B_SHR_MVAL          		--B股市值	
		,OUTMARK_MVAL        		--体外市值	
		,CPTL_BAL            		--资金余额	
		,NO_ARVD_CPTL        		--未到账资金	
		,PTE_FUND_MVAL       		--私募基金市值	
		,CPTL_BAL_RMB        		--资金余额人民币	
		,CPTL_BAL_HKD        		--资金余额港币	
		,CPTL_BAL_USD        		--资金余额美元	
		,FUND_SPACCT_MVAL    		--基金专户	
		,HGT_MVAL            		--沪港通市值	
		,SGT_MVAL            		--深港通市值	
		,TOT_AST_CONTAIN_NOTS		--总资产_含限售股	
		,BOND_MVAL           		--债券市值	
		,REPO_MVAL           		--回购市值	
		,TREA_REPO_MVAL      		--国债回购市值	
		,REPQ_MVAL           		--报价回购市值	
		,PO_FUND_MVAL        		--公募基金市值	
		,APPTBUYB_PLG_MVAL   		--约定购回质押市值	
		,OTH_PROD_MVAL       		--其他产品市值	
		,STKT_FUND_MVAL      		--股票型基金市值	
		,OTH_AST_MVAL        		--其他资产市值	
		,CREDIT_MARG         		--融资融券保证金	
		,CREDIT_NET_AST      		--融资融券净资产	
		,PROD_TOT_MVAL       		--产品总市值	
		,JQL9_MVAL           		--金麒麟9市值	
		,STKPLG_GUAR_SECMV   		--股票质押担保证券市值
		,STKPLG_FIN_BAL      		--股票质押融资余额	
		,APPTBUYB_BAL        		--约定购回余额	
		,CRED_MARG           		--信用保证金	
		,INTR_LIAB           		--利息负债	
		,FEE_LIAB            		--费用负债	
		,OTHLIAB             		--其他负债	
		,FIN_LIAB            		--融资负债	
		,CRDT_STK_LIAB       		--融券负债	
		,CREDIT_TOT_AST      		--融资融券总资产	
		,CREDIT_TOT_LIAB     		--融资融券总负债	
		,APPTBUYB_GUAR_SECMV 		--约定购回担保证券市值
		,CREDIT_GUAR_SECMV   		--融资融券担保证券市值
	)
	SELECT 
		 T.OCCUR_DT            			AS  	OCCUR_DT            		--发生日期	
		,T.EMP_ID              			AS  	EMP_ID              		--员工编号
		,T1.BRH_ID		  		 		AS  	BRH_ID		  		 		--营业部编号	
		,T.TOT_AST             			AS  	TOT_AST             		--总资产	
		,T.SCDY_MVAL           			AS  	SCDY_MVAL           		--二级市值	
		,T.STKF_MVAL           			AS  	STKF_MVAL           		--股基市值	
		,T.A_SHR_MVAL          			AS  	A_SHR_MVAL          		--A股市值	
		,T.NOTS_MVAL           			AS  	NOTS_MVAL           		--限售股市值	
		,T.OFFUND_MVAL         			AS  	OFFUND_MVAL         		--场内基金市值	
		,T.OPFUND_MVAL         			AS  	OPFUND_MVAL         		--场外基金市值	
		,T.SB_MVAL             			AS  	SB_MVAL             		--三板市值	
		,T.IMGT_PD_MVAL        			AS  	IMGT_PD_MVAL        		--资管产品市值	
		,T.BANK_CHRM_MVAL      			AS  	BANK_CHRM_MVAL      		--银行理财市值	
		,T.SECU_CHRM_MVAL      			AS  	SECU_CHRM_MVAL      		--证券理财市值	
		,T.PSTK_OPTN_MVAL      			AS  	PSTK_OPTN_MVAL      		--个股期权市值	
		,T.B_SHR_MVAL          			AS  	B_SHR_MVAL          		--B股市值	
		,T.OUTMARK_MVAL        			AS  	OUTMARK_MVAL        		--体外市值	
		,T.CPTL_BAL            			AS  	CPTL_BAL            		--资金余额	
		,T.NO_ARVD_CPTL        			AS  	NO_ARVD_CPTL        		--未到账资金	
		,T.PTE_FUND_MVAL       			AS  	PTE_FUND_MVAL       		--私募基金市值	
		,T.CPTL_BAL_RMB        			AS  	CPTL_BAL_RMB        		--资金余额人民币	
		,T.CPTL_BAL_HKD        			AS  	CPTL_BAL_HKD        		--资金余额港币	
		,T.CPTL_BAL_USD        			AS  	CPTL_BAL_USD        		--资金余额美元	
		,T.FUND_SPACCT_MVAL    			AS  	FUND_SPACCT_MVAL    		--基金专户	
		,T.HGT_MVAL            			AS  	HGT_MVAL            		--沪港通市值	
		,T.SGT_MVAL            			AS  	SGT_MVAL            		--深港通市值	
		,T.TOT_AST_CONTAIN_NOTS			AS  	TOT_AST_CONTAIN_NOTS		--总资产_含限售股	
		,T.BOND_MVAL           			AS  	BOND_MVAL           		--债券市值	
		,T.REPO_MVAL           			AS  	REPO_MVAL           		--回购市值	
		,T.TREA_REPO_MVAL      			AS  	TREA_REPO_MVAL      		--国债回购市值	
		,T.REPQ_MVAL           			AS  	REPQ_MVAL           		--报价回购市值	
		,T.PO_FUND_MVAL        			AS  	PO_FUND_MVAL        		--公募基金市值	
		,T.APPTBUYB_PLG_MVAL   			AS  	APPTBUYB_PLG_MVAL   		--约定购回质押市值	
		,T.OTH_PROD_MVAL       			AS  	OTH_PROD_MVAL       		--其他产品市值	
		,T.STKT_FUND_MVAL      			AS  	STKT_FUND_MVAL      		--股票型基金市值	
		,T.OTH_AST_MVAL        			AS  	OTH_AST_MVAL        		--其他资产市值	
		,T.CREDIT_MARG         			AS  	CREDIT_MARG         		--融资融券保证金	
		,T.CREDIT_NET_AST      			AS  	CREDIT_NET_AST      		--融资融券净资产	
		,T.PROD_TOT_MVAL       			AS  	PROD_TOT_MVAL       		--产品总市值	
		,T.JQL9_MVAL           			AS  	JQL9_MVAL           		--金麒麟9市值	
		,T.STKPLG_GUAR_SECMV   			AS  	STKPLG_GUAR_SECMV   		--股票质押担保证券市
		,T.STKPLG_FIN_BAL      			AS  	STKPLG_FIN_BAL      		--股票质押融资余额	
		,T.APPTBUYB_BAL        			AS  	APPTBUYB_BAL        		--约定购回余额	
		,T.CRED_MARG           			AS  	CRED_MARG           		--信用保证金	
		,T.INTR_LIAB           			AS  	INTR_LIAB           		--利息负债	
		,T.FEE_LIAB            			AS  	FEE_LIAB            		--费用负债	
		,T.OTHLIAB             			AS  	OTHLIAB             		--其他负债	
		,T.FIN_LIAB            			AS  	FIN_LIAB            		--融资负债	
		,T.CRDT_STK_LIAB       			AS  	CRDT_STK_LIAB       		--融券负债	
		,T.CREDIT_TOT_AST      			AS  	CREDIT_TOT_AST      		--融资融券总资产	
		,T.CREDIT_TOT_LIAB     			AS  	CREDIT_TOT_LIAB     		--融资融券总负债	
		,T.APPTBUYB_GUAR_SECMV 			AS  	APPTBUYB_GUAR_SECMV 		--约定购回担保证券市
		,T.CREDIT_GUAR_SECMV   			AS  	CREDIT_GUAR_SECMV   		--融资融券担保证券市
	FROM DM.T_AST_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	  AND T1.BRH_ID IS NOT NULL;
	
	--将临时表的按营业部维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_AST_D_BRH (
			 OCCUR_DT            		--发生日期	
			,BRH_ID              		--营业部编号	
			,TOT_AST             		--总资产	
			,SCDY_MVAL           		--二级市值	
			,STKF_MVAL           		--股基市值	
			,A_SHR_MVAL          		--A股市值	
			,NOTS_MVAL           		--限售股市值	
			,OFFUND_MVAL         		--场内基金市值	
			,OPFUND_MVAL         		--场外基金市值	
			,SB_MVAL             		--三板市值	
			,IMGT_PD_MVAL        		--资管产品市值	
			,BANK_CHRM_MVAL      		--银行理财市值	
			,SECU_CHRM_MVAL      		--证券理财市值	
			,PSTK_OPTN_MVAL      		--个股期权市值	
			,B_SHR_MVAL          		--B股市值	
			,OUTMARK_MVAL        		--体外市值	
			,CPTL_BAL            		--资金余额	
			,NO_ARVD_CPTL        		--未到账资金	
			,PTE_FUND_MVAL       		--私募基金市值	
			,CPTL_BAL_RMB        		--资金余额人民币	
			,CPTL_BAL_HKD        		--资金余额港币	
			,CPTL_BAL_USD        		--资金余额美元	
			,FUND_SPACCT_MVAL    		--基金专户	
			,HGT_MVAL            		--沪港通市值	
			,SGT_MVAL            		--深港通市值	
			,TOT_AST_CONTAIN_NOTS		--总资产_含限售股	
			,BOND_MVAL           		--债券市值	
			,REPO_MVAL           		--回购市值	
			,TREA_REPO_MVAL      		--国债回购市值	
			,REPQ_MVAL           		--报价回购市值	
			,PO_FUND_MVAL        		--公募基金市值	
			,APPTBUYB_PLG_MVAL   		--约定购回质押市值	
			,OTH_PROD_MVAL       		--其他产品市值	
			,STKT_FUND_MVAL      		--股票型基金市值	
			,OTH_AST_MVAL        		--其他资产市值	
			,CREDIT_MARG         		--融资融券保证金	
			,CREDIT_NET_AST      		--融资融券净资产	
			,PROD_TOT_MVAL       		--产品总市值	
			,JQL9_MVAL           		--金麒麟9市值	
			,STKPLG_GUAR_SECMV   		--股票质押担保证券市值	
			,STKPLG_FIN_BAL      		--股票质押融资余额	
			,APPTBUYB_BAL        		--约定购回余额	
			,CRED_MARG           		--信用保证金	
			,INTR_LIAB           		--利息负债	
			,FEE_LIAB            		--费用负债	
			,OTHLIAB             		--其他负债	
			,FIN_LIAB            		--融资负债	
			,CRDT_STK_LIAB       		--融券负债	
			,CREDIT_TOT_AST      		--融资融券总资产	
			,CREDIT_TOT_LIAB     		--融资融券总负债	
			,APPTBUYB_GUAR_SECMV 		--约定购回担保证券市值	
			,CREDIT_GUAR_SECMV   		--融资融券担保证券市值
		)
		SELECT 
			 OCCUR_DT 						AS      OCCUR_DT                 --发生日期	 
			,BRH_ID		  		 			AS  	BRH_ID		  		 	 --营业部编号	
			,SUM(TOT_AST)             		AS      TOT_AST                  --总资产	 	
			,SUM(SCDY_MVAL)           		AS      SCDY_MVAL                --二级市值	 	
			,SUM(STKF_MVAL)          		AS      STKF_MVAL                --股基市值	 	
			,SUM(A_SHR_MVAL)          		AS      A_SHR_MVAL               --A股市值	 	
			,SUM(NOTS_MVAL)           		AS      NOTS_MVAL                --限售股市值	 	
			,SUM(OFFUND_MVAL)         		AS      OFFUND_MVAL              --场内基金市值	 	
			,SUM(OPFUND_MVAL)         		AS      OPFUND_MVAL              --场外基金市值	 	
			,SUM(SB_MVAL)             		AS      SB_MVAL                  --三板市值	 	
			,SUM(IMGT_PD_MVAL)        		AS      IMGT_PD_MVAL             --资管产品市值	 	
			,SUM(BANK_CHRM_MVAL)      		AS      BANK_CHRM_MVAL           --银行理财市值	 	
			,SUM(SECU_CHRM_MVAL)      		AS      SECU_CHRM_MVAL           --证券理财市值	 	
			,SUM(PSTK_OPTN_MVAL)      		AS      PSTK_OPTN_MVAL           --个股期权市值	 	
			,SUM(B_SHR_MVAL)          		AS      B_SHR_MVAL               --B股市值	 	
			,SUM(OUTMARK_MVAL)        		AS      OUTMARK_MVAL             --体外市值	 	
			,SUM(CPTL_BAL)            		AS      CPTL_BAL                 --资金余额	 	
			,SUM(NO_ARVD_CPTL)        		AS      NO_ARVD_CPTL             --未到账资金	 	
			,SUM(PTE_FUND_MVAL)       		AS      PTE_FUND_MVAL            --私募基金市值	 	
			,SUM(CPTL_BAL_RMB)        		AS      CPTL_BAL_RMB             --资金余额人民币	 	
			,SUM(CPTL_BAL_HKD)        		AS      CPTL_BAL_HKD             --资金余额港币	 	
			,SUM(CPTL_BAL_USD)        		AS      CPTL_BAL_USD             --资金余额美元	 	
			,SUM(FUND_SPACCT_MVAL)    		AS      FUND_SPACCT_MVAL         --基金专户	 	
			,SUM(HGT_MVAL)            		AS      HGT_MVAL                 --沪港通市值	 	
			,SUM(SGT_MVAL)            		AS      SGT_MVAL                 --深港通市值	 	
			,SUM(TOT_AST_CONTAIN_NOTS)		AS      TOT_AST_CONTAIN_NOTS     --总资产_含限售股	 	
			,SUM(BOND_MVAL)           		AS      BOND_MVAL                --债券市值	 	
			,SUM(REPO_MVAL)           		AS      REPO_MVAL                --回购市值	 	
			,SUM(TREA_REPO_MVAL)      		AS      TREA_REPO_MVAL           --国债回购市值	 	
			,SUM(REPQ_MVAL)           		AS      REPQ_MVAL                --报价回购市值	 	
			,SUM(PO_FUND_MVAL)        		AS      PO_FUND_MVAL             --公募基金市值	 	
			,SUM(APPTBUYB_PLG_MVAL)   		AS      APPTBUYB_PLG_MVAL        --约定购回质押市值	 	
			,SUM(OTH_PROD_MVAL)       		AS      OTH_PROD_MVAL            --其他产品市值	 	
			,SUM(STKT_FUND_MVAL)      		AS      STKT_FUND_MVAL           --股票型基金市值	 	
			,SUM(OTH_AST_MVAL)        		AS      OTH_AST_MVAL             --其他资产市值	 	
			,SUM(CREDIT_MARG)         		AS      CREDIT_MARG              --融资融券保证金	 	
			,SUM(CREDIT_NET_AST)      		AS      CREDIT_NET_AST           --融资融券净资产	 	
			,SUM(PROD_TOT_MVAL)       		AS      PROD_TOT_MVAL            --产品总市值	 	
			,SUM(JQL9_MVAL)           		AS      JQL9_MVAL                --金麒麟9市值	 	
			,SUM(STKPLG_GUAR_SECMV)   		AS      STKPLG_GUAR_SECMV        --股票质押担保证券市值 	
			,SUM(STKPLG_FIN_BAL)      		AS      STKPLG_FIN_BAL           --股票质押融资余额	 	
			,SUM(APPTBUYB_BAL)        		AS      APPTBUYB_BAL             --约定购回余额	 	
			,SUM(CRED_MARG)           		AS      CRED_MARG                --信用保证金	 	
			,SUM(INTR_LIAB)           		AS      INTR_LIAB                --利息负债	 	
			,SUM(FEE_LIAB)            		AS      FEE_LIAB                 --费用负债	 	
			,SUM(OTHLIAB)             		AS      OTHLIAB                  --其他负债	 	
			,SUM(FIN_LIAB)            		AS      FIN_LIAB                 --融资负债	 	
			,SUM(CRDT_STK_LIAB)       		AS      CRDT_STK_LIAB            --融券负债	 	
			,SUM(CREDIT_TOT_AST)      		AS      CREDIT_TOT_AST           --融资融券总资产	 	
			,SUM(CREDIT_TOT_LIAB)     		AS      CREDIT_TOT_LIAB          --融资融券总负债	 	
			,SUM(APPTBUYB_GUAR_SECMV) 		AS      APPTBUYB_GUAR_SECMV      --约定购回担保证券市值 	
			,SUM(CREDIT_GUAR_SECMV)   		AS      CREDIT_GUAR_SECMV        --融资融券担保证券市值 	
		FROM #TMP_T_AST_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_AST_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工资产（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-09
  简介：员工维度的客户资产表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	CREATE TABLE #TMP_T_AST_D_EMP(
	    OCCUR_DT             numeric(8,0)  NOT NULL,
		EMP_ID               varchar(30)   NOT NULL,
		MAIN_CPTL_ACCT		 varchar(30)   NOT NULL,
		CUST_ID				 varchar(30)   NOT NULL,
		TOT_AST              numeric(38,8) NULL,
		SCDY_MVAL            numeric(38,8) NULL,
		STKF_MVAL            numeric(38,8) NULL,
		A_SHR_MVAL           numeric(38,8) NULL,
		NOTS_MVAL            numeric(38,8) NULL,
		OFFUND_MVAL          numeric(38,8) NULL,
		OPFUND_MVAL          numeric(38,8) NULL,
		SB_MVAL              numeric(38,8) NULL,
		IMGT_PD_MVAL         numeric(38,8) NULL,
		BANK_CHRM_MVAL       numeric(38,8) NULL,
		SECU_CHRM_MVAL       numeric(38,8) NULL,
		PSTK_OPTN_MVAL       numeric(38,8) NULL,
		B_SHR_MVAL           numeric(38,8) NULL,
		OUTMARK_MVAL         numeric(38,8) NULL,
		CPTL_BAL             numeric(38,8) NULL,
		NO_ARVD_CPTL         numeric(38,8) NULL,
		PTE_FUND_MVAL        numeric(38,8) NULL,
		CPTL_BAL_RMB         numeric(38,8) NULL,
		CPTL_BAL_HKD         numeric(38,8) NULL,
		CPTL_BAL_USD         numeric(38,8) NULL,
		FUND_SPACCT_MVAL     numeric(38,8) NULL,
		HGT_MVAL             numeric(38,8) NULL,
		SGT_MVAL             numeric(38,8) NULL,
		TOT_AST_CONTAIN_NOTS  numeric(38,8) NULL,
		BOND_MVAL            numeric(38,8) NULL,
		REPO_MVAL            numeric(38,8) NULL,
		TREA_REPO_MVAL       numeric(38,8) NULL,
		REPQ_MVAL            numeric(38,8) NULL,
		PO_FUND_MVAL         numeric(38,8) NULL,
		APPTBUYB_PLG_MVAL    numeric(38,8) NULL,
		OTH_PROD_MVAL        numeric(38,8) NULL,
		STKT_FUND_MVAL       numeric(38,8) NULL,
		OTH_AST_MVAL         numeric(38,8) NULL,
		CREDIT_MARG          numeric(38,8) NULL,
		CREDIT_NET_AST       numeric(38,8) NULL,
		PROD_TOT_MVAL        numeric(38,8) NULL,
		JQL9_MVAL            numeric(38,8) NULL,
		STKPLG_GUAR_SECMV    numeric(38,8) NULL,
		STKPLG_FIN_BAL       numeric(38,8) NULL,
		APPTBUYB_BAL         numeric(38,8) NULL,
		CRED_MARG            numeric(38,8) NULL,
		INTR_LIAB            numeric(38,8) NULL,
		FEE_LIAB             numeric(38,8) NULL,
		OTHLIAB              numeric(38,8) NULL,
		FIN_LIAB             numeric(38,8) NULL,
		CRDT_STK_LIAB        numeric(38,8) NULL,
		CREDIT_TOT_AST        numeric(38,8) NULL,
		CREDIT_TOT_LIAB      numeric(38,8) NULL,
		APPTBUYB_GUAR_SECMV  numeric(38,8) NULL,
		CREDIT_GUAR_SECMV    numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_AST_D_EMP(
		 OCCUR_DT					
		,EMP_ID						
		,MAIN_CPTL_ACCT
		,CUST_ID
	)			
	SELECT 
		 @V_DATE AS OCCUR_DT			--发生日期
		,A.AFATWO_YGH AS EMP_ID			--员工编码
		,A.ZJZH AS MAIN_CPTL_ACCT		--资金账号
		,A.KHBH_HS AS CUST_ID 			--客户编号
	FROM DBA.T_DDW_SERV_RELATION_D A
	WHERE A.RQ=@V_DATE
		AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  		   ,A.ZJZH
  		   ,A.KHBH_HS;


	-- 基于责权分配表统计（员工-客户）绩效分配比例

  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,A.KHBH_HS AS CUST_ID 		
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
  		AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH
  	          ,A.KHBH_HS;





	--更新分配后的各项指标
	UPDATE #TMP_T_AST_D_EMP
		SET 
				 TOT_AST             	= 	COALESCE(B1.TOT_AST             ,0)		*    C.PERFM_RATIO_1		--总资产
				,SCDY_MVAL           	= 	COALESCE(B1.SCDY_MVAL           ,0)		*    C.PERFM_RATIO_1		--二级市值
				,STKF_MVAL           	= 	COALESCE(B1.STKF_MVAL           ,0)		*    C.PERFM_RATIO_1		--股基市值
				,A_SHR_MVAL          	= 	COALESCE(B1.A_SHR_MVAL          ,0)		*    C.PERFM_RATIO_1		--A股市值
				,NOTS_MVAL           	= 	COALESCE(B1.NOTS_MVAL           ,0)		*    C.PERFM_RATIO_1		--限售股市值
				,OFFUND_MVAL         	= 	COALESCE(B1.OFFUND_MVAL         ,0)		*    C.PERFM_RATIO_1		--场内基金市值
				,OPFUND_MVAL         	= 	COALESCE(B1.OPFUND_MVAL         ,0)		*    C.PERFM_RATIO_1		--场外基金市值
				,SB_MVAL             	= 	COALESCE(B1.SB_MVAL             ,0)		*    C.PERFM_RATIO_1		--三板市值
				,IMGT_PD_MVAL        	= 	COALESCE(B1.IMGT_PD_MVAL        ,0)		*    C.PERFM_RATIO_6		--资管产品市值
				,BANK_CHRM_MVAL      	= 	COALESCE(B1.BANK_CHRM_MVAL      ,0)		*    C.PERFM_RATIO_1		--银行理财市值
				,SECU_CHRM_MVAL      	= 	COALESCE(B1.SECU_CHRM_MVAL      ,0)		*    C.PERFM_RATIO_1		--证券理财市值
				,PSTK_OPTN_MVAL      	= 	COALESCE(B1.PSTK_OPTN_MVAL      ,0)		*    C.PERFM_RATIO_1		--个股期权市值
				,B_SHR_MVAL          	= 	COALESCE(B1.B_SHR_MVAL          ,0)		*    C.PERFM_RATIO_1		--B股市值
				,OUTMARK_MVAL        	= 	COALESCE(B1.OUTMARK_MVAL        ,0)		*    C.PERFM_RATIO_1		--体外市值
				,CPTL_BAL            	= 	COALESCE(B1.CPTL_BAL            ,0)		*    C.PERFM_RATIO_1		--资金余额
				,NO_ARVD_CPTL        	= 	COALESCE(B1.NO_ARVD_CPTL        ,0)		*    C.PERFM_RATIO_1		--未到账资金
				,PTE_FUND_MVAL       	= 	COALESCE(B1.PTE_FUND_MVAL       ,0)		*    C.PERFM_RATIO_7		--私募基金市值
				,CPTL_BAL_RMB        	= 	COALESCE(B1.CPTL_BAL_RMB        ,0)		*    C.PERFM_RATIO_1		--资金余额人民币
				,CPTL_BAL_HKD        	= 	COALESCE(B1.CPTL_BAL_HKD        ,0)		*    C.PERFM_RATIO_1		--资金余额港币
				,CPTL_BAL_USD        	= 	COALESCE(B1.CPTL_BAL_USD        ,0)		*    C.PERFM_RATIO_1		--资金余额美元
				,FUND_SPACCT_MVAL    	= 	COALESCE(B1.FUND_SPACCT_MVAL    ,0)		*    C.PERFM_RATIO_1		--基金专户
				,HGT_MVAL            	= 	COALESCE(B1.HGT_MVAL            ,0)		*    C.PERFM_RATIO_1		--沪港通市值
				,SGT_MVAL            	= 	COALESCE(B1.SGT_MVAL            ,0)		*    C.PERFM_RATIO_1		--深港通市值
				,TOT_AST_CONTAIN_NOTS	= 	COALESCE(B1.TOT_AST_CONTAIN_NOTS,0)		*    C.PERFM_RATIO_1		--总资产_含限售股
				,BOND_MVAL           	= 	COALESCE(B1.BOND_MVAL           ,0)		*    C.PERFM_RATIO_1		--债券市值
				,REPO_MVAL           	= 	COALESCE(B1.REPO_MVAL           ,0)		*    C.PERFM_RATIO_1		--回购市值
				,TREA_REPO_MVAL      	= 	COALESCE(B1.TREA_REPO_MVAL      ,0)		*    C.PERFM_RATIO_1		--国债回购市值
				,REPQ_MVAL           	= 	COALESCE(B1.REPQ_MVAL           ,0)		*    C.PERFM_RATIO_1		--报价回购市值
				,PO_FUND_MVAL        	= 	COALESCE(B1.PO_FUND_MVAL        ,0)		*    C.PERFM_RATIO_1		--公募基金市值
				,APPTBUYB_PLG_MVAL   	= 	COALESCE(B1.APPTBUYB_PLG_MVAL   ,0)		*    C.PERFM_RATIO_1		--约定购回质押市值
				,OTH_PROD_MVAL       	= 	COALESCE(B1.OTH_PROD_MVAL       ,0)		*    C.PERFM_RATIO_1		--其他产品市值
				,STKT_FUND_MVAL      	= 	COALESCE(B1.STKT_FUND_MVAL      ,0)		*    C.PERFM_RATIO_1		--股票型基金市值
				,OTH_AST_MVAL        	= 	COALESCE(B1.OTH_AST_MVAL        ,0)		*    C.PERFM_RATIO_1		--其他资产市值
				,CREDIT_MARG         	= 	COALESCE(B2.CREDIT_MARG         ,0)		*    C.PERFM_RATIO_9		--融资融券保证金
				,CREDIT_NET_AST      	= 	COALESCE(B2.CREDIT_NET_AST      ,0)		*    C.PERFM_RATIO_9		--融资融券净资产
				,PROD_TOT_MVAL       	= 	COALESCE(B1.PROD_TOT_MVAL       ,0)		*    C.PERFM_RATIO_1		--产品总市值
				,JQL9_MVAL           	= 	COALESCE(B5.JQL9_MVAL           ,0)		*    C.PERFM_RATIO_1		--金麒麟9市值
				,STKPLG_GUAR_SECMV   	= 	COALESCE(B3.STKPLG_GUAR_SECMV   ,0)		*    C.PERFM_RATIO_1		--股票质押担保证券市值
				,STKPLG_FIN_BAL      	= 	COALESCE(B3.STKPLG_FIN_BAL      ,0)		*    C.PERFM_RATIO_1		--股票质押融资余额	
				,APPTBUYB_BAL        	= 	COALESCE(B4.APPTBUYB_BAL        ,0)		*    C.PERFM_RATIO_1		--约定购回余额
				,CRED_MARG           	= 	COALESCE(B2.CRED_MARG           ,0)		*    C.PERFM_RATIO_9		--信用保证金	
				,INTR_LIAB           	= 	COALESCE(B2.INTR_LIAB           ,0)		*    C.PERFM_RATIO_9		--利息负债	
				,FEE_LIAB            	= 	COALESCE(B2.FEE_LIAB            ,0)		*    C.PERFM_RATIO_9		--费用负债	
				,OTHLIAB             	= 	COALESCE(B2.OTHLIAB             ,0)		*    C.PERFM_RATIO_9		--其他负债	
				,FIN_LIAB            	= 	COALESCE(B2.FIN_LIAB            ,0)		*    C.PERFM_RATIO_9		--融资负债	
				,CRDT_STK_LIAB       	= 	COALESCE(B2.CRDT_STK_LIAB       ,0)		*    C.PERFM_RATIO_9		--融券负债	
				,CREDIT_TOT_AST      	= 	COALESCE(B2.CREDIT_TOT_AST      ,0)		*    C.PERFM_RATIO_9		--融资融券总资产
				,CREDIT_TOT_LIAB     	= 	COALESCE(B2.CREDIT_TOT_LIAB     ,0)		*    C.PERFM_RATIO_9		--融资融券总负债
				,APPTBUYB_GUAR_SECMV 	= 	COALESCE(B4.APPTBUYB_GUAR_SECMV ,0)		*    C.PERFM_RATIO_4		--约定购回担保证券市值
				,CREDIT_GUAR_SECMV   	= 	COALESCE(B2.CREDIT_GUAR_SECMV   ,0)		*    C.PERFM_RATIO_9		--融资融券担保证券市值
		FROM #TMP_T_AST_D_EMP A
		--普通资产
		LEFT JOIN (
				SELECT 
					T.MAIN_CPTL_ACCT	  			AS 		MAIN_CPTL_ACCT			--资金账号			
					,T.TOT_AST_N_CONTAIN_NOTS		AS      TOT_AST              	--总资产
					,T.SCDY_MVAL					AS      SCDY_MVAL            	--二级市值
					,T.STKF_MVAL 					AS      STKF_MVAL            	--股基市值
					,T.A_SHR_MVAL					AS      A_SHR_MVAL           	--A股市值
					,T.NOTS_MVAL					AS      NOTS_MVAL            	--限售股市值
					,T.OFFUND_MVAL					AS      OFFUND_MVAL          	--场内基金市值
					,T.OPFUND_MVAL					AS      OPFUND_MVAL          	--场外基金市值
					,T.SB_MVAL						AS      SB_MVAL              	--三板市值
					,T.IMGT_PD_MVAL					AS      IMGT_PD_MVAL         	--资管产品市值
					,T.BANK_CHRM_MVAL				AS      BANK_CHRM_MVAL       	--银行理财市值
					,T.SECU_CHRM_MVAL				AS      SECU_CHRM_MVAL       	--证券理财市值
					,T.PSTK_OPTN_MVAL				AS      PSTK_OPTN_MVAL       	--个股期权市值
					,T.B_SHR_MVAL					AS      B_SHR_MVAL           	--B股市值
					,T.OUTMARK_MVAL					AS      OUTMARK_MVAL         	--体外市值
					,T.CPTL_BAL 					AS      CPTL_BAL             	--资金余额
					,T.NO_ARVD_CPTL					AS      NO_ARVD_CPTL         	--未到账资金
					,T.PTE_FUND_MVAL				AS      PTE_FUND_MVAL        	--私募基金市值
					,T.CPTL_BAL_RMB					AS      CPTL_BAL_RMB         	--资金余额人民币
					,T.CPTL_BAL_HKD					AS      CPTL_BAL_HKD         	--资金余额港币
					,T.CPTL_BAL_USD					AS      CPTL_BAL_USD         	--资金余额美元
					,T.FUND_SPACCT_MVAL				AS      FUND_SPACCT_MVAL     	--基金专户
					,T.HGT_MVAL						AS      HGT_MVAL             	--沪港通市值
					,T.SGT_MVAL						AS      SGT_MVAL             	--深港通市值
					,T.TOT_AST_CONTAIN_NOTS 		AS      TOT_AST_CONTAIN_NOTS 	--总资产_含限售股
					,T.BOND_MVAL					AS      BOND_MVAL            	--债券市值
					,T.REPO_MVAL 					AS      REPO_MVAL            	--回购市值
					,T.TREA_REPO_MVAL				AS      TREA_REPO_MVAL       	--国债回购市值
					,T.REPQ_MVAL					AS      REPQ_MVAL            	--报价回购市值
					,T.PO_FUND_MVAL					AS      PO_FUND_MVAL         	--公募基金市值
					,T.APPTBUYB_PLG_MVAL			AS      APPTBUYB_PLG_MVAL    	--约定购回质押市值
					,T.OTH_PROD_MVAL				AS      OTH_PROD_MVAL        	--其他产品市值
					,T.STKT_FUND_MVAL				AS      STKT_FUND_MVAL       	--股票型基金市值
					,T.OTH_AST_MVAL					AS      OTH_AST_MVAL         	--其他资产市值
					,T.PROD_TOT_MVAL				AS      PROD_TOT_MVAL        	--产品总市值
					--,0								AS      JQL9_MVAL            	--金麒麟9市值
				FROM DM.T_AST_ODI T
				WHERE T.OCCUR_DT = @V_DATE
			) B1 ON A.MAIN_CPTL_ACCT=B1.MAIN_CPTL_ACCT
		--融资融券资产
		LEFT JOIN (
				SELECT 
					 T.CUST_ID	  					AS 		CUST_ID					--客户编号			
					,T.CRED_MARG					AS      CREDIT_MARG          	--融资融券保证金
					,T.NET_AST						AS      CREDIT_NET_AST       	--融资融券净资产
					,T.CRED_MARG					AS      CRED_MARG            	--信用保证金	
					,T.INTR_LIAB					AS      INTR_LIAB            	--利息负债	
					,T.FEE_LIAB						AS      FEE_LIAB             	--费用负债
					,T.OTH_LIAB						AS      OTHLIAB              	--其他负债
					,T.FIN_LIAB						AS      FIN_LIAB             	--融资负债	
					,T.CRDT_STK_LIAB				AS      CRDT_STK_LIAB        	--融券负债	
					,T.TOT_AST						AS      CREDIT_TOT_AST       	--融资融券总资产
					,T.TOT_LIAB						AS      CREDIT_TOT_LIAB      	--融资融券总负债
					,T.GUAR_SECU_MVAL				AS      CREDIT_GUAR_SECMV    	--融资融券担保证券市值
				FROM DM.T_AST_CREDIT T
				WHERE T.OCCUR_DT = @V_DATE
			) B2 ON A.CUST_ID=B2.CUST_ID
		--股票质押资产(股票质押资产的客户编号可能对应多个合同编号，因此基于客户维度汇总所有合同的指标金额)
		LEFT JOIN (
				SELECT 
					 T.CUST_ID	  					AS 		CUST_ID					--客户编号			
					,SUM(T.GUAR_SECU_MVAL)			AS      STKPLG_GUAR_SECMV    	--股票质押担保证券市值
					,SUM(T.STKPLG_FIN_BAL)			AS      STKPLG_FIN_BAL       	--股票质押融资余额	
				FROM DM.T_AST_STKPLG T
				WHERE T.OCCUR_DT = @V_DATE
				GROUP BY T.CUST_ID
			) B3 ON A.CUST_ID=B3.CUST_ID
		--约定购回资产
		LEFT JOIN (
				SELECT 
					 T.CUST_ID	  					AS 		CUST_ID					--客户编号			
					,T.APPTBUYB_BAL					AS      APPTBUYB_BAL         	--约定购回余额
					,T.GUAR_SECU_MVAL				AS      APPTBUYB_GUAR_SECMV  	--约定购回担保证券市值
				FROM DM.T_AST_APPTBUYB T
				WHERE T.OCCUR_DT = @V_DATE
			) B4 ON A.CUST_ID=B4.CUST_ID
		--金麒麟9市值
		LEFT JOIN (
				SELECT 
					 T.MAIN_CPTL_ACCT	  			AS 		MAIN_CPTL_ACCT		    --资金账号		 
					,SUM(T.OTC_RETAIN_AMT)	        AS      JQL9_MVAL            	--金麒麟市值
				FROM DM.T_EVT_PROD_TRD_D_D T
				WHERE T.OCCUR_DT = @V_DATE
                GROUP BY T.MAIN_CPTL_ACCT
			) B5 ON B5.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.CUST_ID = A.CUST_ID
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--将临时表的按员工维度汇总各项指标金额并插入到目标表
	DELETE FROM DM.T_AST_D_EMP WHERE OCCUR_DT = @V_DATE;
	INSERT INTO DM.T_AST_D_EMP (
			 OCCUR_DT            		--发生日期	
			,EMP_ID              		--员工编号	
			,TOT_AST             		--总资产	
			,SCDY_MVAL           		--二级市值	
			,STKF_MVAL           		--股基市值	
			,A_SHR_MVAL          		--A股市值	
			,NOTS_MVAL           		--限售股市值	
			,OFFUND_MVAL         		--场内基金市值	
			,OPFUND_MVAL         		--场外基金市值	
			,SB_MVAL             		--三板市值	
			,IMGT_PD_MVAL        		--资管产品市值	
			,BANK_CHRM_MVAL      		--银行理财市值	
			,SECU_CHRM_MVAL      		--证券理财市值	
			,PSTK_OPTN_MVAL      		--个股期权市值	
			,B_SHR_MVAL          		--B股市值	
			,OUTMARK_MVAL        		--体外市值	
			,CPTL_BAL            		--资金余额	
			,NO_ARVD_CPTL        		--未到账资金	
			,PTE_FUND_MVAL       		--私募基金市值	
			,CPTL_BAL_RMB        		--资金余额人民币	
			,CPTL_BAL_HKD        		--资金余额港币	
			,CPTL_BAL_USD        		--资金余额美元	
			,FUND_SPACCT_MVAL    		--基金专户	
			,HGT_MVAL            		--沪港通市值	
			,SGT_MVAL            		--深港通市值	
			,TOT_AST_CONTAIN_NOTS		--总资产_含限售股	
			,BOND_MVAL           		--债券市值	
			,REPO_MVAL           		--回购市值	
			,TREA_REPO_MVAL      		--国债回购市值	
			,REPQ_MVAL           		--报价回购市值	
			,PO_FUND_MVAL        		--公募基金市值	
			,APPTBUYB_PLG_MVAL   		--约定购回质押市值	
			,OTH_PROD_MVAL       		--其他产品市值	
			,STKT_FUND_MVAL      		--股票型基金市值	
			,OTH_AST_MVAL        		--其他资产市值	
			,CREDIT_MARG         		--融资融券保证金	
			,CREDIT_NET_AST      		--融资融券净资产	
			,PROD_TOT_MVAL       		--产品总市值	
			,JQL9_MVAL           		--金麒麟9市值	
			,STKPLG_GUAR_SECMV   		--股票质押担保证券市值	
			,STKPLG_FIN_BAL      		--股票质押融资余额	
			,APPTBUYB_BAL        		--约定购回余额	
			,CRED_MARG           		--信用保证金	
			,INTR_LIAB           		--利息负债	
			,FEE_LIAB            		--费用负债	
			,OTHLIAB             		--其他负债	
			,FIN_LIAB            		--融资负债	
			,CRDT_STK_LIAB       		--融券负债	
			,CREDIT_TOT_AST      		--融资融券总资产	
			,CREDIT_TOT_LIAB     		--融资融券总负债	
			,APPTBUYB_GUAR_SECMV 		--约定购回担保证券市值	
			,CREDIT_GUAR_SECMV   		--融资融券担保证券市值
		)
		SELECT 
			 OCCUR_DT 						AS      OCCUR_DT                 --发生日期	 
			,EMP_ID   						AS      EMP_ID                   --员工编号	 
			,SUM(TOT_AST)             		AS      TOT_AST                  --总资产	 	
			,SUM(SCDY_MVAL)           		AS      SCDY_MVAL                --二级市值	 	
			,SUM(STKF_MVAL)          		AS      STKF_MVAL                --股基市值	 	
			,SUM(A_SHR_MVAL)          		AS      A_SHR_MVAL               --A股市值	 	
			,SUM(NOTS_MVAL)           		AS      NOTS_MVAL                --限售股市值	 	
			,SUM(OFFUND_MVAL)         		AS      OFFUND_MVAL              --场内基金市值	 	
			,SUM(OPFUND_MVAL)         		AS      OPFUND_MVAL              --场外基金市值	 	
			,SUM(SB_MVAL)             		AS      SB_MVAL                  --三板市值	 	
			,SUM(IMGT_PD_MVAL)        		AS      IMGT_PD_MVAL             --资管产品市值	 	
			,SUM(BANK_CHRM_MVAL)      		AS      BANK_CHRM_MVAL           --银行理财市值	 	
			,SUM(SECU_CHRM_MVAL)      		AS      SECU_CHRM_MVAL           --证券理财市值	 	
			,SUM(PSTK_OPTN_MVAL)      		AS      PSTK_OPTN_MVAL           --个股期权市值	 	
			,SUM(B_SHR_MVAL)          		AS      B_SHR_MVAL               --B股市值	 	
			,SUM(OUTMARK_MVAL)        		AS      OUTMARK_MVAL             --体外市值	 	
			,SUM(CPTL_BAL)            		AS      CPTL_BAL                 --资金余额	 	
			,SUM(NO_ARVD_CPTL)        		AS      NO_ARVD_CPTL             --未到账资金	 	
			,SUM(PTE_FUND_MVAL)       		AS      PTE_FUND_MVAL            --私募基金市值	 	
			,SUM(CPTL_BAL_RMB)        		AS      CPTL_BAL_RMB             --资金余额人民币	 	
			,SUM(CPTL_BAL_HKD)        		AS      CPTL_BAL_HKD             --资金余额港币	 	
			,SUM(CPTL_BAL_USD)        		AS      CPTL_BAL_USD             --资金余额美元	 	
			,SUM(FUND_SPACCT_MVAL)    		AS      FUND_SPACCT_MVAL         --基金专户	 	
			,SUM(HGT_MVAL)            		AS      HGT_MVAL                 --沪港通市值	 	
			,SUM(SGT_MVAL)            		AS      SGT_MVAL                 --深港通市值	 	
			,SUM(TOT_AST_CONTAIN_NOTS)		AS      TOT_AST_CONTAIN_NOTS     --总资产_含限售股	 	
			,SUM(BOND_MVAL)           		AS      BOND_MVAL                --债券市值	 	
			,SUM(REPO_MVAL)           		AS      REPO_MVAL                --回购市值	 	
			,SUM(TREA_REPO_MVAL)      		AS      TREA_REPO_MVAL           --国债回购市值	 	
			,SUM(REPQ_MVAL)           		AS      REPQ_MVAL                --报价回购市值	 	
			,SUM(PO_FUND_MVAL)        		AS      PO_FUND_MVAL             --公募基金市值	 	
			,SUM(APPTBUYB_PLG_MVAL)   		AS      APPTBUYB_PLG_MVAL        --约定购回质押市值	 	
			,SUM(OTH_PROD_MVAL)       		AS      OTH_PROD_MVAL            --其他产品市值	 	
			,SUM(STKT_FUND_MVAL)      		AS      STKT_FUND_MVAL           --股票型基金市值	 	
			,SUM(OTH_AST_MVAL)        		AS      OTH_AST_MVAL             --其他资产市值	 	
			,SUM(CREDIT_MARG)         		AS      CREDIT_MARG              --融资融券保证金	 	
			,SUM(CREDIT_NET_AST)      		AS      CREDIT_NET_AST           --融资融券净资产	 	
			,SUM(PROD_TOT_MVAL)       		AS      PROD_TOT_MVAL            --产品总市值	 	
			,SUM(JQL9_MVAL)           		AS      JQL9_MVAL                --金麒麟9市值	 	
			,SUM(STKPLG_GUAR_SECMV)   		AS      STKPLG_GUAR_SECMV        --股票质押担保证券市值 	
			,SUM(STKPLG_FIN_BAL)      		AS      STKPLG_FIN_BAL           --股票质押融资余额	 	
			,SUM(APPTBUYB_BAL)        		AS      APPTBUYB_BAL             --约定购回余额	 	
			,SUM(CRED_MARG)           		AS      CRED_MARG                --信用保证金	 	
			,SUM(INTR_LIAB)           		AS      INTR_LIAB                --利息负债	 	
			,SUM(FEE_LIAB)            		AS      FEE_LIAB                 --费用负债	 	
			,SUM(OTHLIAB)             		AS      OTHLIAB                  --其他负债	 	
			,SUM(FIN_LIAB)            		AS      FIN_LIAB                 --融资负债	 	
			,SUM(CRDT_STK_LIAB)       		AS      CRDT_STK_LIAB            --融券负债	 	
			,SUM(CREDIT_TOT_AST)      		AS      CREDIT_TOT_AST           --融资融券总资产	 	
			,SUM(CREDIT_TOT_LIAB)     		AS      CREDIT_TOT_LIAB          --融资融券总负债	 	
			,SUM(APPTBUYB_GUAR_SECMV) 		AS      APPTBUYB_GUAR_SECMV      --约定购回担保证券市值 	
			,SUM(CREDIT_GUAR_SECMV)   		AS      CREDIT_GUAR_SECMV        --融资融券担保证券市值 	
		FROM #TMP_T_AST_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_APPTBUYB_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户约定购回月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户约定购回月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
  
      --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4);    
    DECLARE @V_BIN_MTH  VARCHAR(2);   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

  --PART0 删除当月数据
    DELETE FROM DM.T_AST_EMPCUS_APPTBUYB_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

  
    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;

	 --业务数据临时表
	 SELECT 
	 T1.YEAR AS 年
	,T1.MTH AS 月
	,T1.OCCUR_DT
	,T1.NATRE_DAYS_MTH AS 自然天数_月
	,T1.NATRE_DAYS_YEAR AS 自然天数_年
	,T1.NATRE_DAY_MTHBEG AS 自然日_月初
	,T1.CUST_ID AS 客户编码
	,T1.YEAR_MTH AS 年月
	,T1.YEAR_MTH_CUST_ID AS 年月客户编码
	,T1.GUAR_SECU_MVAL_FINAL AS 担保证券市值_期末
	,T1.APPTBUYB_BAL_FINAL AS 约定购回余额_期末
	,T1.SH_GUAR_SECU_MVAL_FINAL AS 上海担保证券市值_期末
	,T1.SZ_GUAR_SECU_MVAL_FINAL AS 深圳担保证券市值_期末
	,T1.SH_NOTS_GUAR_SECU_MVAL_FINAL AS 上海限售股担保证券市值_期末
	,T1.SZ_NOTS_GUAR_SECU_MVAL_FINAL AS 深圳限售股担保证券市值_期末
	,T1.PROP_FINAC_OUT_SIDE_BAL_FINAL AS 自营融出方余额_期末
	,T1.ASSM_FINAC_OUT_SIDE_BAL_FINAL AS 资管融出方余额_期末
	,T1.SM_LOAN_FINAC_OUT_BAL_FINAL AS 小额贷融出余额_期末
	,T1.GUAR_SECU_MVAL_MDA AS 担保证券市值_月日均
	,T1.APPTBUYB_BAL_MDA AS 约定购回余额_月日均
	,T1.SH_GUAR_SECU_MVAL_MDA AS 上海担保证券市值_月日均
	,T1.SZ_GUAR_SECU_MVAL_MDA AS 深圳担保证券市值_月日均
	,T1.SH_NOTS_GUAR_SECU_MVAL_MDA AS 上海限售股担保证券市值_月日均
	,T1.SZ_NOTS_GUAR_SECU_MVAL_MDA AS 深圳限售股担保证券市值_月日均
	,T1.PROP_FINAC_OUT_SIDE_BAL_MDA AS 自营融出方余额_月日均
	,T1.ASSM_FINAC_OUT_SIDE_BAL_MDA AS 资管融出方余额_月日均
	,T1.SM_LOAN_FINAC_OUT_BAL_MDA AS 小额贷融出余额_月日均
	,T1.GUAR_SECU_MVAL_YDA AS 担保证券市值_年日均
	,T1.APPTBUYB_BAL_YDA AS 约定购回余额_年日均
	,T1.SH_GUAR_SECU_MVAL_YDA AS 上海担保证券市值_年日均
	,T1.SZ_GUAR_SECU_MVAL_YDA AS 深圳担保证券市值_年日均
	,T1.SH_NOTS_GUAR_SECU_MVAL_YDA AS 上海限售股担保证券市值_年日均
	,T1.SZ_NOTS_GUAR_SECU_MVAL_YDA AS 深圳限售股担保证券市值_年日均
	,T1.PROP_FINAC_OUT_SIDE_BAL_YDA AS 自营融出方余额_年日均
	,T1.ASSM_FINAC_OUT_SIDE_BAL_YDA AS 资管融出方余额_年日均
	,T1.SM_LOAN_FINAC_OUT_BAL_YDA AS 小额贷融出余额_年日均
 	INTO #TEMP_T1
 	FROM DM.T_AST_APPTBUYB_M_D T1
 	WHERE T1.OCCUR_DT=@V_BIN_DATE 
 	      AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
		   AND T1.CUST_ID NOT IN ('448999999',
					'440000001',
					'999900000001',
					'440000011',
					'440000015');--20180314 排除"总部专用账户"

	INSERT INTO DM.T_AST_EMPCUS_APPTBUYB_M_D 
	(
		 YEAR                           --年
		,MTH                            --月
		,OCCUR_DT                       --业务日期
		,CUST_ID                        --客户编码
		,AFA_SEC_EMPID                  --AFA_二期员工号
		,YEAR_MTH                       --年月
		,YEAR_MTH_CUST_ID               --年月客户编码
		,YEAR_MTH_PSN_JNO               --年月员工号
		,WH_ORG_ID_CUST                 --仓库机构编码_客户
		,WH_ORG_ID_EMP                  --仓库机构编码_员工
		,PERFM_RATI9_CREDIT             --绩效比例9_融资融券
		,GUAR_SECU_MVAL_FINAL           --担保证券市值_期末
		,APPTBUYB_BAL_FINAL             --约定购回余额_期末
		,SH_GUAR_SECU_MVAL_FINAL        --上海担保证券市值_期末
		,SZ_GUAR_SECU_MVAL_FINAL        --深圳担保证券市值_期末
		,SH_NOTS_GUAR_SECU_MVAL_FINAL   --上海限售股担保证券市值_期末
		,SZ_NOTS_GUAR_SECU_MVAL_FINAL   --深圳限售股担保证券市值_期末
		,PROP_FINAC_OUT_SIDE_BAL_FINAL  --自营融出方余额_期末
		,ASSM_FINAC_OUT_SIDE_BAL_FINAL  --资管融出方余额_期末
		,SM_LOAN_FINAC_OUT_BAL_FINAL    --小额贷融出余额_期末
		,GUAR_SECU_MVAL_MDA             --担保证券市值_月日均
		,APPTBUYB_BAL_MDA               --约定购回余额_月日均
		,SH_GUAR_SECU_MVAL_MDA          --上海担保证券市值_月日均
		,SZ_GUAR_SECU_MVAL_MDA          --深圳担保证券市值_月日均
		,SH_NOTS_GUAR_SECU_MVAL_MDA     --上海限售股担保证券市值_月日均
		,SZ_NOTS_GUAR_SECU_MVAL_MDA     --深圳限售股担保证券市值_月日均
		,PROP_FINAC_OUT_SIDE_BAL_MDA    --自营融出方余额_月日均
		,ASSM_FINAC_OUT_SIDE_BAL_MDA    --资管融出方余额_月日均
		,SM_LOAN_FINAC_OUT_BAL_MDA      --小额贷融出余额_月日均
		,GUAR_SECU_MVAL_YDA             --担保证券市值_年日均
		,APPTBUYB_BAL_YDA               --约定购回余额_年日均
		,SH_GUAR_SECU_MVAL_YDA          --上海担保证券市值_年日均
		,SZ_GUAR_SECU_MVAL_YDA          --深圳担保证券市值_年日均
		,SH_NOTS_GUAR_SECU_MVAL_YDA     --上海限售股担保证券市值_年日均
		,SZ_NOTS_GUAR_SECU_MVAL_YDA     --深圳限售股担保证券市值_年日均
		,PROP_FINAC_OUT_SIDE_BAL_YDA    --自营融出方余额_年日均
		,ASSM_FINAC_OUT_SIDE_BAL_YDA    --资管融出方余额_年日均
		,SM_LOAN_FINAC_OUT_BAL_YDA      --小额贷融出余额_年日均
		,LOAD_DT                        --清洗日期
	)
SELECT
	 T2.YEAR
	,T2.MTH
	,@V_BIN_DATE 		AS OCCUR_DT
	,T2.HS_CUST_ID
	,T2.AFA_SEC_EMPID 	AS AFA_二期员工号	
	,T2.YEAR||T2.MTH 	AS 年月
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID 	AS 年月客户编码
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID  AS 年月员工号

	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工
	,T2.PERFM_RATI9 AS 绩效比例9_融资融券
	
	,COALESCE(T1.担保证券市值_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 担保证券市值_期末
	,COALESCE(T1.约定购回余额_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回余额_期末
	,COALESCE(T1.上海担保证券市值_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 上海担保证券市值_期末
	,COALESCE(T1.深圳担保证券市值_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 深圳担保证券市值_期末
	,COALESCE(T1.上海限售股担保证券市值_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 上海限售股担保证券市值_期末
	,COALESCE(T1.深圳限售股担保证券市值_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 深圳限售股担保证券市值_期末
	,COALESCE(T1.自营融出方余额_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 自营融出方余额_期末
	,COALESCE(T1.资管融出方余额_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 资管融出方余额_期末
	,COALESCE(T1.小额贷融出余额_期末,0)*COALESCE(T2.PERFM_RATI9,0) AS 小额贷融出余额_期末	
	
	,COALESCE(T1.担保证券市值_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 担保证券市值_月日均
	,COALESCE(T1.约定购回余额_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回余额_月日均
	,COALESCE(T1.上海担保证券市值_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 上海担保证券市值_月日均
	,COALESCE(T1.深圳担保证券市值_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 深圳担保证券市值_月日均
	,COALESCE(T1.上海限售股担保证券市值_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 上海限售股担保证券市值_月日均
	,COALESCE(T1.深圳限售股担保证券市值_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 深圳限售股担保证券市值_月日均
	,COALESCE(T1.自营融出方余额_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 自营融出方余额_月日均
	,COALESCE(T1.资管融出方余额_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 资管融出方余额_月日均
	,COALESCE(T1.小额贷融出余额_月日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 小额贷融出余额_月日均
	
	,COALESCE(T1.担保证券市值_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 担保证券市值_年日均
	,COALESCE(T1.约定购回余额_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回余额_年日均
	,COALESCE(T1.上海担保证券市值_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 上海担保证券市值_年日均
	,COALESCE(T1.深圳担保证券市值_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 深圳担保证券市值_年日均
	,COALESCE(T1.上海限售股担保证券市值_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 上海限售股担保证券市值_年日均
	,COALESCE(T1.深圳限售股担保证券市值_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 深圳限售股担保证券市值_年日均
	,COALESCE(T1.自营融出方余额_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 自营融出方余额_年日均
	,COALESCE(T1.资管融出方余额_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 资管融出方余额_年日均
	,COALESCE(T1.小额贷融出余额_年日均,0)*COALESCE(T2.PERFM_RATI9,0) AS 小额贷融出余额_年日均
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2 
LEFT JOIN #TEMP_T1 T1 
	ON T1.OCCUR_DT = T2.OCCUR_DT 
	AND T1.客户编码 = T2.HS_CUST_ID
;

END
GO
GRANT EXECUTE ON dm.P_AST_EMPCUS_APPTBUYB_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_CPTL_CHG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户资产变动月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户资产变动月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

   --PART0 删除当月数据
    DELETE FROM DM.T_AST_EMPCUS_CPTL_CHG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
   ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;


	 --业务数据临时表
	SELECT 
		T1.YEAR AS 年
		,T1.MTH AS 月
		,T1.OCCUR_DT 
		,T1.CUST_ID AS 客户编码
		,T1.YEAR_MTH AS 年月
		,T1.YEAR_MTH_CUST_ID AS 年月客户编码
		,T1.ODI_CPTL_INFLOW_MTD AS 普通资金流入_月累计
		,T1.ODI_CPTL_OUTFLOW_MTD AS 普通资金流出_月累计
		,T1.ODI_MVAL_INFLOW_MTD AS 普通市值流入_月累计
		,T1.ODI_MVAL_OUTFLOW_MTD AS 普通市值流出_月累计
		,T1.CREDIT_CPTL_INFLOW_MTD AS 两融资金流入_月累计
		,T1.CREDIT_CPTL_OUTFLOW_MTD AS 两融资金流出_月累计
		,T1.ODI_ACC_CPTL_NET_INFLOW_MTD AS 普通账户资金净流入_月累计
		,T1.CREDIT_CPTL_NET_INFLOW_MTD AS 两融资金净流入_月累计
		,T1.ODI_CPTL_INFLOW_YTD AS 普通资金流入_年累计
		,T1.ODI_CPTL_OUTFLOW_YTD AS 普通资金流出_年累计
		,T1.ODI_MVAL_INFLOW_YTD AS 普通市值流入_年累计
		,T1.ODI_MVAL_OUTFLOW_YTD AS 普通市值流出_年累计
		,T1.CREDIT_CPTL_INFLOW_YTD AS 两融资金流入_年累计
		,T1.CREDIT_CPTL_OUTFLOW_YTD AS 两融资金流出_年累计
		,T1.ODI_ACC_CPTL_NET_INFLOW_YTD AS 普通账户资金净流入_年累计
		,T1.CREDIT_CPTL_NET_INFLOW_YTD AS 两融资金净流入_年累计
		,T1.LOAD_DT AS 清洗日期、
	INTO #TEMP_T1
	FROM DM.T_AST_CPTL_CHG_M_D T1
	WHERE T1.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	   AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015');--20180314 排除"总部专用账户"


	INSERT INTO DM.T_AST_EMPCUS_CPTL_CHG_M_D 
	(
	 YEAR                        --年
	,MTH                         --月
	,OCCUR_DT                    --业务日期
	,CUST_ID                     --客户编码
	,AFA_SEC_EMPID               --AFA_二期员工号
	,YEAR_MTH                    --年月
	,YEAR_MTH_CUST_ID            --年月客户编码
	,YEAR_MTH_PSN_JNO            --年月员工号
	,WH_ORG_ID_CUST              --仓库机构编码_客户
	,WH_ORG_ID_EMP               --仓库机构编码_员工
	,PERFM_RATI1_SCDY_AST        --绩效比例1_二级资产
	,PERFM_RATI9_CREDIT          --绩效比例9_融资融券
	,ODI_CPTL_INFLOW_MTD         --普通资金流入_月累计
	,ODI_CPTL_OUTFLOW_MTD        --普通资金流出_月累计
	,ODI_MVAL_INFLOW_MTD         --普通市值流入_月累计
	,ODI_MVAL_OUTFLOW_MTD        --普通市值流出_月累计
	,CREDIT_CPTL_INFLOW_MTD      --两融资金流入_月累计
	,CREDIT_CPTL_OUTFLOW_MTD     --两融资金流出_月累计
	,ODI_ACC_CPTL_NET_INFLOW_MTD --普通账户资金净流入_月累计
	,CREDIT_CPTL_NET_INFLOW_MTD  --两融资金净流入_月累计
	,ODI_CPTL_INFLOW_YTD         --普通资金流入_年累计
	,ODI_CPTL_OUTFLOW_YTD        --普通资金流出_年累计
	,ODI_MVAL_INFLOW_YTD         --普通市值流入_年累计
	,ODI_MVAL_OUTFLOW_YTD        --普通市值流出_年累计
	,CREDIT_CPTL_INFLOW_YTD      --两融资金流入_年累计
	,CREDIT_CPTL_OUTFLOW_YTD     --两融资金流出_年累计
	,ODI_ACC_CPTL_NET_INFLOW_YTD --普通账户资金净流入_年累计
	,CREDIT_CPTL_NET_INFLOW_YTD  --两融资金净流入_年累计
	,LOAD_DT                     --清洗日期

)
SELECT
	T2.YEAR
	,T2.MTH
	,T2.OCCUR_DT
	,T2.HS_CUST_ID
	,T2.AFA_SEC_EMPID AS AFA_二期员工号
	,T2.YEAR||T2.MTH
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID AS 年月客户编号
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS 年月员工号
	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工
	,T2.PERFM_RATI1 AS 绩效比例1_二级资产
	,T2.PERFM_RATI9 AS 绩效比例9_融资融券
	
	,COALESCE(T1.普通资金流入_月累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通资金流入_月累计
	,COALESCE(T1.普通资金流出_月累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通资金流出_月累计
	,COALESCE(T1.普通市值流入_月累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通市值流入_月累计
	,COALESCE(T1.普通市值流出_月累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通市值流出_月累计
	,COALESCE(T1.两融资金流入_月累计,0) * COALESCE(T2.PERFM_RATI9,0) AS 两融资金流入_月累计
	,COALESCE(T1.两融资金流出_月累计,0) * COALESCE(T2.PERFM_RATI9,0) AS 两融资金流出_月累计
	,COALESCE(T1.普通账户资金净流入_月累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通账户资金净流入_月累计
	,COALESCE(T1.两融资金净流入_月累计,0) * COALESCE(T2.PERFM_RATI9,0) AS 两融资金净流入_月累计
	
	,COALESCE(T1.普通资金流入_年累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通资金流入_年累计
	,COALESCE(T1.普通资金流出_年累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通资金流出_年累计
	,COALESCE(T1.普通市值流入_年累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通市值流入_年累计
	,COALESCE(T1.普通市值流出_年累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通市值流出_年累计
	,COALESCE(T1.两融资金流入_年累计,0) * COALESCE(T2.PERFM_RATI9,0) AS 两融资金流入_年累计
	,COALESCE(T1.两融资金流出_年累计,0) * COALESCE(T2.PERFM_RATI9,0) AS 两融资金流出_年累计
	,COALESCE(T1.普通账户资金净流入_年累计,0) * COALESCE(T2.PERFM_RATI1,0) AS 普通账户资金净流入_年累计
	,COALESCE(T1.两融资金净流入_年累计,0) * COALESCE(T2.PERFM_RATI9,0) AS 两融资金净流入_年累计
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2 
LEFT JOIN #TEMP_T1 T1 
	ON T1.OCCUR_DT = T2.OCCUR_DT 
		AND T1.客户编码 = T2.HS_CUST_ID
;

END
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_CREDIT_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户融资融券月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户融资融券月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

   --PART0 删除当月数据
  DELETE FROM DM.T_AST_EMPCUS_CREDIT_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
   ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;

	 --业务数据临时表
	select 
	t1.YEAR as 年
	,t1.MTH as 月
	,T1.OCCUR_DT
	,t1.NATRE_DAYS_MTH as 自然天数_月
	,t1.NATRE_DAYS_YEAR as 自然天数_年
	,t1.NATRE_DAY_MTHBEG as 自然日_月初
	,t1.CUST_ID as 客户编码
	,t1.YEAR_MTH as 年月
	,t1.YEAR_MTH_CUST_ID as 年月客户编码
	,t1.TOT_LIAB_FINAL as 总负债_期末
	,t1.NET_AST_FINAL as 净资产_期末
	,t1.CRED_MARG_FINAL as 信用保证金_期末
	,t1.GUAR_SECU_MVAL_FINAL as 担保证券市值_期末
	,t1.FIN_LIAB_FINAL as 融资负债_期末
	,t1.CRDT_STK_LIAB_FINAL as 融券负债_期末
	,t1.INTR_LIAB_FINAL as 利息负债_期末
	,t1.FEE_LIAB_FINAL as 费用负债_期末
	,t1.OTH_LIAB_FINAL as 其他负债_期末
	,t1.TOT_AST_FINAL as 总资产_期末
	,t1.TOT_LIAB_MDA as 总负债_月日均
	,t1.NET_AST_MDA as 净资产_月日均
	,t1.CRED_MARG_MDA as 信用保证金_月日均
	,t1.GUAR_SECU_MVAL_MDA as 担保证券市值_月日均
	,t1.FIN_LIAB_MDA as 融资负债_月日均
	,t1.CRDT_STK_LIAB_MDA as 融券负债_月日均
	,t1.INTR_LIAB_MDA as 利息负债_月日均
	,t1.FEE_LIAB_MDA as 费用负债_月日均
	,t1.OTH_LIAB_MDA as 其他负债_月日均
	,t1.TOT_AST_MDA as 总资产_月日均
	,t1.TOT_LIAB_YDA as 总负债_年日均
	,t1.NET_AST_YDA as 净资产_年日均
	,t1.CRED_MARG_YDA as 信用保证金_年日均
	,t1.GUAR_SECU_MVAL_YDA as 担保证券市值_年日均
	,t1.FIN_LIAB_YDA as 融资负债_年日均
	,t1.CRDT_STK_LIAB_YDA as 融券负债_年日均
	,t1.INTR_LIAB_YDA as 利息负债_年日均
	,t1.FEE_LIAB_YDA as 费用负债_年日均
	,t1.OTH_LIAB_YDA as 其他负债_年日均
	,t1.TOT_AST_YDA as 总资产_年日均
	,t1.LOAD_DT as 清洗日期
	INTO #TEMP_T1
	 from DM.T_AST_CREDIT_M_D t1
	 WHERE T1.OCCUR_DT=@V_BIN_DATE
	 AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015');--20180314 排除"总部专用账户"

	INSERT INTO DM.T_AST_EMPCUS_CREDIT_M_D 
	(
	   YEAR                  --年
	  ,MTH                   --月
	  ,OCCUR_DT              --业务日期
	  ,CUST_ID               --客户编码
	  ,AFA_SEC_EMPID         --AFA_二期员工号
	  ,YEAR_MTH              --年月
	  ,YEAR_MTH_CUST_ID      --年月客户编号
	  ,YEAR_MTH_PSN_JNO      --年月员工编号
	  ,WH_ORG_ID_CUST        --仓库机构编码_客户
	  ,WH_ORG_ID_EMP         --仓库机构编码_员工
	  ,PERFM_RATI9_CREDIT    --绩效比例9_融资融券
	  ,TOT_LIAB_FINAL        --总负债_期末
	  ,NET_AST_FINAL         --净资产_期末
	  ,CRED_MARG_FINAL       --信用保证金_期末
	  ,GUAR_SECU_MVAL_FINAL  --担保证券市值_月日均
	  ,FIN_LIAB_FINAL        --融资负债_期末
	  ,CRDT_STK_LIAB_FINAL   --融券负债_期末
	  ,INTR_LIAB_FINAL       --利息负债_期末
	  ,FEE_LIAB_FINAL        --费用负债_期末
	  ,OTH_LIAB_FINAL        --其他负债_期末
	  ,TOT_AST_FINAL         --总资产_期末
	  ,TOT_LIAB_MDA          --总负债_月日均
	  ,NET_AST_MDA           --净资产_月日均
	  ,CRED_MARG_MDA         --信用保证金_月日均
	  ,GUAR_SECU_MVAL_MDA    --担保证券市值_月日均
	  ,FIN_LIAB_MDA          --融资负债_月日均
	  ,CRDT_STK_LIAB_MDA     --融券负债_月日均
	  ,INTR_LIAB_MDA         --利息负债_月日均
	  ,FEE_LIAB_MDA          --费用负债_月日均
	  ,OTH_LIAB_MDA          --其他负债_月日均
	  ,TOT_AST_MDA           --总资产_月日均
	  ,TOT_LIAB_YDA          --总负债_年日均
	  ,NET_AST_YDA           --净资产_年日均
	  ,CRED_MARG_YDA         --信用保证金_年日均
	  ,GUAR_SECU_MVAL_YDA    --担保证券市值_年日均
	  ,FIN_LIAB_YDA          --融资负债_年日均
	  ,CRDT_STK_LIAB_YDA     --融券负债_年日均
	  ,INTR_LIAB_YDA         --利息负债_年日均
	  ,FEE_LIAB_YDA          --费用负债_年日均
	  ,OTH_LIAB_YDA          --其他负债_年日均
	  ,TOT_AST_YDA           --总资产_年日均
	  ,LOAD_DT               --清洗日期
	)
	select
	 t2.YEAR
	,t2.MTH
	,T2.OCCUR_DT
	,t2.HS_CUST_ID
	,t2.AFA_SEC_EMPID as AFA_二期员工号
	,t2.YEAR||t2.MTH as 年月
	,t2.YEAR||t2.MTH||t2.HS_CUST_ID as 年月客户编号
	,t2.YEAR||t2.MTH||t2.AFA_SEC_EMPID as 年月员工编号
	,t2.WH_ORG_ID_CUST as 仓库机构编码_客户
	,t2.WH_ORG_ID_EMP as 仓库机构编码_员工
	,t2.PERFM_RATI9 as 绩效比例9_融资融券
	
	,COALESCE(t1.总负债_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 总负债_期末
	,COALESCE(t1.净资产_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 净资产_期末
	,COALESCE(t1.信用保证金_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 信用保证金_期末
	,COALESCE(t1.担保证券市值_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 担保证券市值_期末
	,COALESCE(t1.融资负债_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 融资负债_期末
	,COALESCE(t1.融券负债_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 融券负债_期末
	,COALESCE(t1.利息负债_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 利息负债_期末
	,COALESCE(t1.费用负债_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 费用负债_期末
	,COALESCE(t1.其他负债_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 其他负债_期末
	,COALESCE(t1.总资产_期末,0)*COALESCE(t2.PERFM_RATI9,0) as 总资产_期末

	,COALESCE(t1.总负债_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 总负债_月日均
	,COALESCE(t1.净资产_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 净资产_月日均
	,COALESCE(t1.信用保证金_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 信用保证金_月日均
	,COALESCE(t1.担保证券市值_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 担保证券市值_月日均
	,COALESCE(t1.融资负债_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 融资负债_月日均
	,COALESCE(t1.融券负债_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 融券负债_月日均
	,COALESCE(t1.利息负债_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 利息负债_月日均
	,COALESCE(t1.费用负债_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 费用负债_月日均
	,COALESCE(t1.其他负债_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 其他负债_月日均
	,COALESCE(t1.总资产_月日均,0)*COALESCE(t2.PERFM_RATI9,0) as 总资产_月日均

	,COALESCE(t1.总负债_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 总负债_年日均
	,COALESCE(t1.净资产_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 净资产_年日均
	,COALESCE(t1.信用保证金_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 信用保证金_年日均
	,COALESCE(t1.担保证券市值_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 担保证券市值_年日均
	,COALESCE(t1.融资负债_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 融资负债_年日均
	,COALESCE(t1.融券负债_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 融券负债_年日均
	,COALESCE(t1.利息负债_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 利息负债_年日均
	,COALESCE(t1.费用负债_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 费用负债_年日均
	,COALESCE(t1.其他负债_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 其他负债_年日均
	,COALESCE(t1.总资产_年日均,0)*COALESCE(t2.PERFM_RATI9,0) as 总资产_年日均
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2
LEFT JOIN #TEMP_T1 T1
		ON T1.occur_dt=t2.occur_dt 
		 AND T1.客户编码=T2.HS_CUST_ID 
;

END
GO
GRANT EXECUTE ON dm.P_AST_EMPCUS_CREDIT_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_ODI_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户普通资产月表
  编写者: DCY
  创建日期: 2018-03-01
  简介：员工客户普通资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 删除当月数据
  DELETE FROM DM.T_AST_EMPCUS_ODI_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
  
    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;

	 --业务数据临时表
	 select
				t1.YEAR
				,t1.MTH
				,T1.OCCUR_DT
				,t1.CUST_ID
				--股票质押担保证券市值
				,sum(t1.GUAR_SECU_MVAL_FINAL) as GUAR_SECU_MVAL_FINAL
				,sum(t1.GUAR_SECU_MVAL_MDA)   as GUAR_SECU_MVAL_MDA
				,sum(t1.GUAR_SECU_MVAL_YDA)   as GUAR_SECU_MVAL_YDA
	 into #temp_t_gpzy
	 from DM.T_AST_STKPLG_M_D t1
	 group by 
	 	t1.YEAR
	 	,t1.MTH
	 	,T1.OCCUR_DT
	 	,t1.CUST_ID;


	INSERT INTO DM.T_AST_EMPCUS_ODI_M_D 
	(
		year                                   ,
		mth                                    ,
		OCCUR_DT                               ,
		cust_id                                ,
		year_mth                               ,
		year_mth_cust_id                       ,
		AFA_SEC_EMPID                          ,
		wh_org_id_emp                          ,
		year_mth_psn_jno                       ,
		scdy_mval_final                        ,
		stkf_mval_final                        ,
		a_shr_mval_final                       ,
		nots_mval_final                        ,
		offund_mval_final                      ,
		opfund_mval_final                      ,
		sb_mval_final                          ,
		imgt_pd_mval_final                     ,
		bank_chrm_mval_final                   ,
		secu_chrm_mval_final                   ,
		pstk_optn_mval_final                   ,
		b_shr_mval_final                       ,
		outmark_mval_final                     ,
		cptl_bal_final                         ,
		no_arvd_cptl_final                     ,
		pte_fund_mval_final                    ,
		oversea_tot_ast_final                  ,
		futr_tot_ast_final                     ,
		cptl_bal_rmb_final                     ,
		cptl_bal_hkd_final                     ,
		cptl_bal_usd_final                     ,
		low_risk_tot_ast_final                 ,
		fund_spacct_mval_final                 ,
		hgt_mval_final                         ,
		sgt_mval_final                         ,
		net_ast_final                          ,
		tot_ast_contain_nots_final             ,
		tot_ast_n_contain_nots_final           ,
		bond_mval_final                        ,
		repo_mval_final                        ,
		trea_repo_mval_final                   ,
		repq_mval_final                        ,
		scdy_mval_mda                          ,
		stkf_mval_mda                          ,
		a_shr_mval_mda                         ,
		nots_mval_mda                          ,
		offund_mval_mda                        ,
		opfund_mval_mda                        ,
		sb_mval_mda                            ,
		imgt_pd_mval_mda                       ,
		bank_chrm_mval_mda                     ,
		secu_chrm_mval_mda                     ,
		pstk_optn_mval_mda                     ,
		b_shr_mval_mda                         ,
		outmark_mval_mda                       ,
		cptl_bal_mda                           ,
		no_arvd_cptl_mda                       ,
		pte_fund_mval_mda                      ,
		oversea_tot_ast_mda                    ,
		futr_tot_ast_mda                       ,
		cptl_bal_rmb_mda                       ,
		cptl_bal_hkd_mda                       ,
		cptl_bal_usd_mda                       ,
		low_risk_tot_ast_mda                   ,
		fund_spacct_mval_mda                   ,
		hgt_mval_mda                           ,
		sgt_mval_mda                           ,
		net_ast_mda                            ,
		tot_ast_contain_nots_mda               ,
		tot_ast_n_contain_nots_mda             ,
		bond_mval_mda                          ,
		repo_mval_mda                          ,
		trea_repo_mval_mda                     ,
		repq_mval_mda                          ,
		scdy_mval_yda                          ,
		stkf_mval_yda                          ,
		a_shr_mval_yda                         ,
		nots_mval_yda                          ,
		offund_mval_yda                        ,
		opfund_mval_yda                        ,
		sb_mval_yda                            ,
		imgt_pd_mval_yda                       ,
		bank_chrm_mval_yda                     ,
		secu_chrm_mval_yda                     ,
		pstk_optn_mval_yda                     ,
		b_shr_mval_yda                         ,
		outmark_mval_yda                       ,
		cptl_bal_yda                           ,
		no_arvd_cptl_yda                       ,
		pte_fund_mval_yda                      ,
		oversea_tot_ast_yda                    ,
		futr_tot_ast_yda                       ,
		cptl_bal_rmb_yda                       ,
		cptl_bal_hkd_yda                       ,
		cptl_bal_usd_yda                       ,
		low_risk_tot_ast_yda                   ,
		fund_spacct_mval_yda                   ,
		hgt_mval_yda                           ,
		sgt_mval_yda                           ,
		net_ast_yda                            ,
		tot_ast_contain_nots_yda               ,
		tot_ast_n_contain_nots_yda             ,
		bond_mval_yda                          ,
		repo_mval_yda                          ,
		trea_repo_mval_yda                     ,
		repq_mval_yda                          ,
		po_fund_mval_final                     ,
		po_fund_mval_mda                       ,
		po_fund_mval_yda                       ,
		stkt_fund_mval_final                   ,
		oth_prod_mval_final                    ,
		oth_ast_mval_final                     ,
		apptbuyb_plg_mval_final                ,
		stkt_fund_mval_mda                     ,
		oth_prod_mval_mda                      ,
		oth_ast_mval_mda                       ,
		apptbuyb_plg_mval_mda                  ,
		stkt_fund_mval_yda                     ,
		oth_prod_mval_yda                      ,
		oth_ast_mval_yda                       ,
		apptbuyb_plg_mval_yda                  ,
		credit_net_ast_final                   ,
		credit_marg_final                      ,
		credit_bal_final                       ,
		credit_net_ast_mda                     ,
		credit_marg_mda                        ,
		credit_bal_mda                         ,
		credit_net_ast_yda                     ,
		credit_marg_yda                        ,
		credit_bal_yda                         ,
		credit_tot_liab_final                  ,
		credit_tot_liab_mda                    ,
		credit_tot_liab_yda                    ,
		credit_tot_ast_final                   ,
		credit_tot_ast_mda                     ,
		credit_tot_ast_yda                     ,
		apptbuyb_bal_final                     ,
		apptbuyb_bal_mda                       ,
		apptbuyb_bal_yda                       ,
		prod_tot_mval_final                    ,
		prod_tot_mval_mda                      ,
		prod_tot_mval_yda                      ,
		tot_ast_final                          ,
		tot_ast_mda                            ,
		tot_ast_yda                            ,
		stkplg_guar_secu_mval_final_scdy_deduct,
		stkplg_guar_secu_mval_mda_scdy_deduct  ,
		stkplg_guar_secu_mval_yda_scdy_deduct  ,
		stkplg_liab_final                      ,
		stkplg_liab_mda                        ,
		stkplg_liab_yda                        ,
		stkplg_guar_secu_mval_final            ,
		stkplg_guar_secu_mval_mda              ,
		stkplg_guar_secu_mval_yda
	)
	select 
	 t2.YEAR 			as 年
	,t2.MTH 			as 月
	,T2.OCCUR_DT
	,t2.HS_CUST_ID 		as 客户编码
	,t2.YEAR||t2.MTH 	as 年月
	,t2.YEAR||t2.MTH||t2.HS_CUST_ID as 年月客户编码

	,t2.AFA_SEC_EMPID as AFA二期员工号
	,t2.WH_ORG_ID_EMP as 仓库机构编码_员工
	,t2.YEAR||t2.MTH||t2.AFA_SEC_EMPID as 年月员工号

	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_FINAL,0) as 二级市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_FINAL,0) as 股基市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_FINAL,0) as A股市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_FINAL,0) as 限售股市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_FINAL,0) as 场内基金市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_FINAL,0) as 场外基金市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_FINAL,0) as 三板市值_期末
	,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0) as 资管产品市值_期末
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0) as 银行理财市值_期末
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0) as 证券理财市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0) as 个股期权市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_FINAL,0) as B股市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_FINAL,0) as 体外市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_FINAL,0) as 资金余额_期末
	--修正未到账
	,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_FINAL,0)+COALESCE(t1.STKPLG_LIAB_FINAL,0)) as 未到账资金_期末
	,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0) as 私募基金市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_FINAL,0) as 海外总资产_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_FINAL,0) as 期货总资产_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_FINAL,0) as 资金余额人民币_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_FINAL,0) as 资金余额港币_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_FINAL,0) as 资金余额美元_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_FINAL,0) as 低风险总资产_期末
	,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0) as 基金专户市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_FINAL,0) as 沪港通市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_FINAL,0) as 深港通市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_FINAL,0) as 净资产_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_FINAL,0) as 总资产_含限售股_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_FINAL,0) as 总资产_不含限售股_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_FINAL,0) as 债券市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_FINAL,0) as 回购市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_FINAL,0) as 国债回购市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_FINAL,0) as 报价回购市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_MDA,0) as 二级市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_MDA,0) as 股基市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_MDA,0) as A股市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_MDA,0) as 限售股市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_MDA,0) as 场内基金市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_MDA,0) as 场外基金市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_MDA,0) as 三板市值_月日均
	,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0) as 资管产品市值_月日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0) as 银行理财市值_月日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0) as 证券理财市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_MDA,0) as 个股期权市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_MDA,0) as B股市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_MDA,0) as 体外市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_MDA,0) as 资金余额_月日均
	--修正未到账资金
	,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_MDA,0)+COALESCE(t1.STKPLG_LIAB_MDA,0)) as 未到账资金_月日均
	,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0) as 私募基金市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_MDA,0) as 海外总资产_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_MDA,0) as 期货总资产_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_MDA,0) as 资金余额人民币_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_MDA,0) as 资金余额港币_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_MDA,0) as 资金余额美元_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_MDA,0) as 低风险总资产_月日均
	,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0) as 基金专户市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_MDA,0) as 沪港通市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_MDA,0) as 深港通市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_MDA,0) as 净资产_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_MDA,0) as 总资产_含限售股_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_MDA,0) as 总资产_不含限售股_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_MDA,0) as 债券市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_MDA,0) as 回购市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_MDA,0) as 国债回购市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_MDA,0) as 报价回购市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_YDA,0) as 二级市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_YDA,0) as 股基市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_YDA,0) as A股市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_YDA,0) as 限售股市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_YDA,0) as 场内基金市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_YDA,0) as 场外基金市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_YDA,0) as 三板市值_年日均
	,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0) as 资管产品市值_年日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0) as 银行理财市值_年日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0) as 证券理财市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_YDA,0) as 个股期权市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_YDA,0) as B股市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_YDA,0) as 体外市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_YDA,0) as 资金余额_年日均
	--修正未到账资金
	,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_YDA,0)+COALESCE(t1.STKPLG_LIAB_YDA,0))  as 未到账资金_年日均
	,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0) as 私募基金市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_YDA,0) as 海外总资产_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_YDA,0) as 期货总资产_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_YDA,0) as 资金余额人民币_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_YDA,0) as 资金余额港币_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_YDA,0) as 资金余额美元_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_YDA,0) as 低风险总资产_年日均
	,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0) as 基金专户市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_YDA,0) as 沪港通市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_YDA,0) as 深港通市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_YDA,0) as 净资产_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_YDA,0) as 总资产_含限售股_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_YDA,0) as 总资产_不含限售股_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_YDA,0) as 债券市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_YDA,0) as 回购市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_YDA,0) as 国债回购市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_YDA,0) as 报价回购市值_年日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0) as 公募基金市值_期末
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0) as 公募基金市值_月日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0) as 公募基金市值_年日均

	--补充更新
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_FINAL,0) as 股票型基金市值_期末
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0) as 其他产品市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_FINAL,0) as 其他资产市值_期末
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0) as 约定购回质押市值_期末
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_MDA,0) as 股票型基金市值_月日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0) as 其他产品市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_MDA,0) as 其他资产市值_月日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0) as 约定购回质押市值_月日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_YDA,0) as 股票型基金市值_年日均
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0) as 其他产品市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_YDA,0) as 其他资产市值_年日均
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0) as 约定购回质押市值_年日均

	--补充融资融券数据
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_FINAL,0) as 融资融券净资产_期末
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_FINAL,0) as 融资融券保证金_期末
	,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_FINAL,0)+COALESCE(t3.CRDT_STK_LIAB_FINAL,0)) as 融资融券余额_期末
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_MDA,0) as 融资融券净资产_月日均
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_MDA,0) as 融资融券保证金_月日均
	,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_MDA,0)+COALESCE(t3.CRDT_STK_LIAB_MDA,0)) as 融资融券余额_月日均
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_YDA,0) as 融资融券净资产_年日均
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_YDA,0) as 融资融券保证金_年日均
	,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_YDA,0)+COALESCE(t3.CRDT_STK_LIAB_YDA,0)) as 融资融券余额_年日均

	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_FINAL,0) as 融资融券总负债_期末
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_MDA,0) as 融资融券总负债_月日均
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_YDA,0) as 融资融券总负债_年日均

	--20180412：增加融资融券总资产
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_FINAL,0) as 融资融券总资产_期末
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_MDA,0) as 融资融券总资产_月日均
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_YDA,0) as 融资融券总资产_年日均
	--20180416：增加约定购回余额，用于计算净资产
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_FINAL,0) as 约定购回余额_期末
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_MDA,0) as 约定购回余额_月日均
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_YDA,0) as 约定购回余额_年日均


	--产品总市值：公募基金市值+基金专户市值+资管产品市值+私募基金市值+银行理财市值+证券理财市值+其他产品市值
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0) 			--公募基金市值_期末
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0) 	--基金专户市值_期末
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0) 		--资管产品市值_期末
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0) 		--私募基金市值_期末
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0) 	--银行理财市值_期末
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0) 	--证券理财市值_期末
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0)		--其他产品市值_期末
	as 产品总市值_期末
,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0) 			--公募基金市值_月日均
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0) 	--基金专户市值_月日均
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0) 		--资管产品市值_月日均
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0) 		--私募基金市值_月日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0) 		--银行理财市值_月日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0) 		--证券理财市值_月日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0)		--其他产品市值_月日均
	as 产品总市值_月日均
,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0) 			--公募基金市值_年日均
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0) 	--基金专户市值_年日均
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0) 		--资管产品市值_年日均
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0) 		--私募基金市值_年日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0) 		--银行理财市值_年日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0) 		--证券理财市值_年日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0)		--其他产品市值_年日均
	as 产品总市值_年日均	
	
--总资产：股基市值+资金余额+债券市值+回购市值+产品总市值+其他资产+未到账资金+股票质押负债+融资融券总资产+约定购回质押市值+限售股市值
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_FINAL,0) 				--股基市值_期末
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_FINAL,0) 			--资金余额_期末
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_FINAL,0) 			--债券市值_期末
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_FINAL,0) 			--回购市值_期末
	
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0) 		--公募基金市值_期末
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0) 	--基金专户市值_期末
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0) 		--资管产品市值_期末
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0) 		--私募基金市值_期末
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0) 	--银行理财市值_期末
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0) 	--证券理财市值_期末
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0)		--其他产品市值_期末
	
	--20180412修正
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_FINAL,0) 		--其他资产市值_期末
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_FINAL,0) 		--未到账资金_期末
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_FINAL,0) 		--股票质押负债_期末（用于冲抵未到账资金，所以使用二级资产的责权比例处理）
	+COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_FINAL,0) 			--融资融券总资产_期末
	
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0) 	--约定购回质押市值_期末
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_FINAL,0) 			--限售股市值_期末
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0) 	--个股期权市值_期末
	
	--扣减股票质押担保证券市值
	-COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_FINAL,0) --股票质押担保证券市值_期末
	as 总资产_期末
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_MDA,0) 				--股基市值_月日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_MDA,0) 			--资金余额_月日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_MDA,0) 			--债券市值_月日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_MDA,0) 			--回购市值_月日均
	
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0) 		--公募基金市值_月日均
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0) 	--基金专户市值_月日均
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0) 		--资管产品市值_月日均
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0) 		--私募基金市值_月日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0) 		--银行理财市值_月日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0) 		--证券理财市值_月日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0)		--其他产品市值_月日均
	
	--20180412修正
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_MDA,0) 		--其他资产市值_月日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_MDA,0) 		--未到账资金_月日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_MDA,0) 			--股票质押负债_月日均（用于冲抵未到账资金，所以使用二级资产的责权比例处理）
	+COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_MDA,0) 				--融资融券总资产_月日均
	
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0) 	--约定购回质押市值_月日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_MDA,0) 			--限售股市值_月日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_MDA,0) 		--个股期权市值_月日均
	
	--扣减股票质押担保证券市值
	-COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_MDA,0) 	--股票质押担保证券市值_月日均
	as 总资产_月日均
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_YDA,0) 				--股基市值_年日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_YDA,0) 			--资金余额_年日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_YDA,0) 			--债券市值_年日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_YDA,0) 			--回购市值_年日均
	
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0) 		--公募基金市值_年日均
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0) 	--基金专户市值_年日均
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0) 		--资管产品市值_年日均
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0) 		--私募基金市值_年日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0) 		--银行理财市值_年日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0) 		--证券理财市值_年日均
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0)		--其他产品市值_年日均
	
	--20180412修正
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_YDA,0) 		--其他资产市值_年日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_YDA,0) 		--未到账资金_年日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_YDA,0) 			--股票质押负债_年日均（用于冲抵未到账资金，所以使用二级资产的责权比例处理）
	+COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_YDA,0) 				--融资融券总资产_年日均
	
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0) 	--约定购回质押市值_年日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_YDA,0) 			--限售股市值_年日均
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_YDA,0) 		--个股期权市值_年日均
	
	--扣减股票质押担保证券市值
	-COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_YDA,0) 	--股票质押担保证券市值_年日均
	as 总资产_年日均

	--20180423，修正二级市值中扣减的股票质押市值
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_FINAL,0) as 股票质押担保证券市值_期末_二级扣减
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_MDA,0)   as 股票质押担保证券市值_月日均_二级扣减
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_YDA,0)   as 股票质押担保证券市值_年日均_二级扣减
	
	--20180416：总资产中股票质押资产已扣减，股票质押责权负债先清0
	,0 as 股票质押负债_期末
	,0 as 股票质押负债_月日均
	,0 as 股票质押负债_年日均
	
	,0 as 股票质押担保证券市值_期末
	,0 as 股票质押担保证券市值_月日均
	,0 as 股票质押担保证券市值_年日均
 FROM #T_PUB_SER_RELA T2
 LEFT JOIN DM.T_AST_ODI_M_D t1 
 	ON t1.OCCUR_DT=t2.OCCUR_DT 
 			and t1.CUST_ID=t2.HS_CUST_ID
 left join DM.T_AST_CREDIT_M_D t3 
 		on t2.OCCUR_DT=t3.OCCUR_DT 
 			and t2.HS_CUST_ID=t3.CUST_ID
 left join #temp_t_gpzy t_gpzy 
 		on t2.OCCUR_DT=t_gpzy.OCCUR_DT 
 			and t2.HS_CUST_ID=t_gpzy.CUST_ID
 left join DM.T_AST_APPTBUYB_M_D t_ydgh 
 		on t2.OCCUR_DT=t_ydgh.OCCUR_DT 
 			and t2.HS_CUST_ID=t_ydgh.CUST_ID
 ;

END
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_STKPLG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户股票质押月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户股票质押月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

   --PART0 删除当月数据
    DELETE FROM DM.T_AST_EMPCUS_STKPLG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
   ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;

	 
	--每日员工信息表
	select a.dt AS OCCUR_DT,a.year,a.mth,pk_org as  WH_ORG_NO,afatwo_ygh AS AFA_SEC_EMPID,rylx,hrid,ygh,ygxm,ygzt,is_virtual,jgbh_hs,lzrq
	into #T_PTY_PERSON_M
	from  dm.T_PUB_DATE a
	left join dba.t_edw_person_d  b on b.rq=case when a.dt<=20171031 then a.nxt_trd_day else a.dt end  
	where a.dt=@V_BIN_DATE;	 
	
	
	 --生成每日客户汇总
  SELECT  
     OUC.CLIENT_ID 	AS CUST_ID  --客户编码
	,@V_BIN_YEAR           	AS YEAR      --年
	,@V_BIN_MTH           	AS MTH       --月
	,@V_BIN_DATE            AS OCCUR_DT  --业务日期
	,OUF.FUND_ACCOUNT  		AS MAIN_CPTL_ACCT     --主资金账号（普通账户）
	,DOH.PK_ORG 	 		AS WH_ORG_ID          --仓库机构编码 
	,CONVERT(VARCHAR,OUC.BRANCH_NO) AS HS_ORG_ID  --恒生机构编码
    ,OUF.OPEN_DATE 					AS TE_OACT_DT   --最早开户日期
	
	INTO #T_PUB_CUST
	
	FROM DBA.T_EDW_UF2_CLIENT  			OUC   --所有客户信息
    LEFT JOIN DBA.T_edw_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID AND OUF.LOAD_DT=OUC.LOAD_dT AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --普通账户主资金账号
	LEFT JOIN DBA.T_DIM_ORG_HIS  		DOH ON CONVERT(VARCHAR,OUC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=OUC.LOAD_dT AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL    --有重复值
	WHERE OUC.BRANCH_NO NOT IN (5,55,51,44,9999)--20180207 新增：排除"总部专用账户"
      AND OUC.LOAD_DT=@V_BIN_DATE;
		 
	

	INSERT INTO DM.T_AST_EMPCUS_STKPLG_M_D 
	(
	   YEAR                 		  --年
	  ,MTH                  		  --月
	  ,OCCUR_DT                       --业务日期
	  ,CUST_ID              		  --客户编码
	  ,AFA_SEC_EMPID        		  --AFA_二期员工号
	  ,CTR_NO               		  --合同编号
	  ,YEAR_MTH             		  --年月
	  ,YEAR_MTH_CUST_ID     		  --年月客户编码
	  ,YEAR_MTH_PSN_JNO     		  --年月员工号
	  ,WH_ORG_ID_CUST       		  --仓库机构编码_客户
	  ,WH_ORG_ID_EMP        		  --仓库机构编码_员工
	  ,GUAR_SECU_MVAL_FINAL 		  --担保证券市值_期末
	  ,STKPLG_FIN_BAL_FINAL 		  --股票质押融资余额_期末
	  ,SH_GUAR_SECU_MVAL_FINAL 	      --上海担保证券市值_期末
	  ,SZ_GUAR_SECU_MVAL_FINAL 	      --深圳担保证券市值_期末
	  ,SH_NOTS_GUAR_SECU_MVAL_FINAL   --上海限售股担保证券市值_期末
	  ,SZ_NOTS_GUAR_SECU_MVAL_FINAL   --深圳限售股担保证券市值_期末
	  ,PROP_FINAC_OUT_SIDE_BAL_FINAL  --自营融出方余额_期末
	  ,ASSM_FINAC_OUT_SIDE_BAL_FINAL  --资管融出方余额_期末
	  ,SM_LOAN_FINAC_OUT_BAL_FINAL    --小额贷融出余额_期末
	  ,GUAR_SECU_MVAL_MDA             --担保证券市值_月日均
	  ,STKPLG_FIN_BAL_MDA             --股票质押融资余额_月日均
	  ,SH_GUAR_SECU_MVAL_MDA          --上海担保证券市值_月日均
	  ,SZ_GUAR_SECU_MVAL_MDA          --深圳担保证券市值_月日均
	  ,SH_NOTS_GUAR_SECU_MVAL_MDA     --上海限售股担保证券市值_月日均
	  ,SZ_NOTS_GUAR_SECU_MVAL_MDA     --深圳限售股担保证券市值_月日均
	  ,PROP_FINAC_OUT_SIDE_BAL_MDA    --自营融出方余额_月日均
	  ,ASSM_FINAC_OUT_SIDE_BAL_MDA    --资管融出方余额_月日均
	  ,SM_LOAN_FINAC_OUT_BAL_MDA      --小额贷融出余额_月日均
	  ,GUAR_SECU_MVAL_YDA             --担保证券市值_年日均
	  ,STKPLG_FIN_BAL_YDA             --股票质押融资余额_年日均
	  ,SH_GUAR_SECU_MVAL_YDA          --上海担保证券市值_年日均
	  ,SZ_GUAR_SECU_MVAL_YDA          --深圳担保证券市值_年日均
	  ,SH_NOTS_GUAR_SECU_MVAL_YDA     --上海限售股担保证券市值_年日均
	  ,SZ_NOTS_GUAR_SECU_MVAL_YDA     --深圳限售股担保证券市值_年日均
	  ,PROP_FINAC_OUT_SIDE_BAL_YDA    --自营融出方余额_年日均
	  ,ASSM_FINAC_OUT_SIDE_BAL_YDA    --资管融出方余额_年日均
	  ,SM_LOAN_FINAC_OUT_BAL_YDA      --小额贷融出余额_年日均
	  ,LOAD_DT                        --清洗日期
	)
	select
	t1.YEAR as 年
	,t1.MTH as 月
	,T1.OCCUR_DT
	,t1.CUST_ID as 客户编码
	,t1.AFA_SEC_EMPID as AFA二期员工号
	,t1.CTR_NO as 合同编号
	,t1.YEAR||t1.MTH as 年月
	,t1.YEAR||t1.MTH||t1.CUST_ID as 年月客户编码
	,t_kh.WH_ORG_ID as 仓库机构编码_客户
	,t_yg.WH_ORG_NO as 仓库机构编码_员工
	,t1.YEAR||t1.MTH||t1.AFA_SEC_EMPID as 年月员工号
	,sum(COALESCE(t1.担保证券市值_期末,0)) as 担保证券市值_期末
	,sum(COALESCE(t1.股票质押融资余额_期末,0)) as 股票质押融资余额_期末
	,sum(COALESCE(t1.上海担保证券市值_期末,0)) as 上海担保证券市值_期末
	,sum(COALESCE(t1.深圳担保证券市值_期末,0)) as 深圳担保证券市值_期末
	,sum(COALESCE(t1.上海限售股担保证券市值_期末,0)) as 上海限售股担保证券市值_期末
	,sum(COALESCE(t1.深圳限售股担保证券市值_期末,0)) as 深圳限售股担保证券市值_期末
	,sum(COALESCE(t1.自营融出方余额_期末,0)) as 自营融出方余额_期末
	,sum(COALESCE(t1.资管融出方余额_期末,0)) as 资管融出方余额_期末
	,sum(COALESCE(t1.小额贷融出余额_期末,0)) as 小额贷融出余额_期末
	
	,sum(COALESCE(t1.担保证券市值_月日均,0)) as 担保证券市值_月日均
	,sum(COALESCE(t1.股票质押融资余额_月日均,0)) as 股票质押融资余额_月日均
	,sum(COALESCE(t1.上海担保证券市值_月日均,0)) as 上海担保证券市值_月日均
	,sum(COALESCE(t1.深圳担保证券市值_月日均,0)) as 深圳担保证券市值_月日均
	,sum(COALESCE(t1.上海限售股担保证券市值_月日均,0)) as 上海限售股担保证券市值_月日均
	,sum(COALESCE(t1.深圳限售股担保证券市值_月日均,0)) as 深圳限售股担保证券市值_月日均
	,sum(COALESCE(t1.自营融出方余额_月日均,0)) as 自营融出方余额_月日均
	,sum(COALESCE(t1.资管融出方余额_月日均,0)) as 资管融出方余额_月日均
	,sum(COALESCE(t1.小额贷融出余额_月日均,0)) as 小额贷融出余额_月日均
	
	,sum(COALESCE(t1.担保证券市值_年日均,0)) as 担保证券市值_年日均
	,sum(COALESCE(t1.股票质押融资余额_年日均,0)) as 股票质押融资余额_年日均
	,sum(COALESCE(t1.上海担保证券市值_年日均,0)) as 上海担保证券市值_年日均
	,sum(COALESCE(t1.深圳担保证券市值_年日均,0)) as 深圳担保证券市值_年日均
	,sum(COALESCE(t1.上海限售股担保证券市值_年日均,0)) as 上海限售股担保证券市值_年日均
	,sum(COALESCE(t1.深圳限售股担保证券市值_年日均,0)) as 深圳限售股担保证券市值_年日均
	,sum(COALESCE(t1.自营融出方余额_年日均,0)) as 自营融出方余额_年日均
	,sum(COALESCE(t1.资管融出方余额_年日均,0)) as 资管融出方余额_年日均
	,sum(COALESCE(t1.小额贷融出余额_年日均,0)) as 小额贷融出余额_年日均
	,@V_BIN_DATE                       --清洗日期
	from
	(
	select 
		t1.YEAR
		,t1.MTH	
        ,T1.OCCUR_DT		
		,t1.CUST_ID		
		,t1.CTR_NO
		,t2.AFA_SEC_EMPID		
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_FINAL,0) as 担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_FINAL,0) as 股票质押融资余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0) as 上海担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0) as 深圳担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0) as 上海限售股担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0) as 深圳限售股担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0) as 自营融出方余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0) as 资管融出方余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0) as 小额贷融出余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_MDA,0) as 担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_MDA,0) as 股票质押融资余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0) as 上海担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0) as 深圳担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0) as 上海限售股担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0) as 深圳限售股担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0) as 自营融出方余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0) as 资管融出方余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0) as 小额贷融出余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_YDA,0) as 担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_YDA,0) as 股票质押融资余额_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0) as 上海担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0) as 深圳担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0) as 上海限售股担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0) as 深圳限售股担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0) as 自营融出方余额_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0) as 资管融出方余额_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0) as 小额贷融出余额_年日均
	 from DM.T_AST_STKPLG_M_D t1
	 left join
		 (
			select 	a.nianyue 	as YEAR_MTH
					,b. occur_dt 
					,case when b.AFA_SEC_EMPID is null then a.afatwo_ygh else b.AFA_SEC_EMPID end as AFA_SEC_EMPID
					,cntr_id    AS  CTR_NO
					,a.jxbl     as RIGHT_RATI
			from dba.t_gzhs_zq             a
			left join #T_PTY_PERSON_M      b on a.hrid=b.hrid and b.year||b.mth=a.nianyue
			WHERE A.NIANYUE=(SELECT MAX(NIANYUE) FROM dba.t_gzhs_zq  WHERE NIANYUE <=@V_BIN_YEAR||@V_BIN_MTH)
		) t2 on t1.OCCUR_DT=T2.OCCUR_DT and t1.CTR_NO=t2.CTR_NO
	 WHERE t1.YEAR_MTH=SUBSTR(@V_BIN_DATE||'',1,6) and t2.CTR_NO is not null	 
	 
	 union all
	 select 
		t1.YEAR
		,t1.MTH		
		,T1.OCCUR_DT
		,t1.CUST_ID		
		,t1.CTR_NO
		,t2.AFA_SEC_EMPID		
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_FINAL,0) as 担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_FINAL,0) as 股票质押融资余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0) as 上海担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0) as 深圳担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0) as 上海限售股担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0) as 深圳限售股担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0) as 自营融出方余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0) as 资管融出方余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0) as 小额贷融出余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_MDA,0) as 担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_MDA,0) as 股票质押融资余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0) as 上海担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0) as 深圳担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0) as 上海限售股担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0) as 深圳限售股担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0) as 自营融出方余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0) as 资管融出方余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0) as 小额贷融出余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_YDA,0) as 担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_YDA,0) as 股票质押融资余额_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0) as 上海担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0) as 深圳担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0) as 上海限售股担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0) as 深圳限售股担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0) as 自营融出方余额_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0) as 资管融出方余额_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0) as 小额贷融出余额_年日均
	  from DM.T_AST_STKPLG_M_D                     t1
	  left join (select t1.nianyue AS YEAR_MTH, t1.cntr_id AS  CTR_NO
				   from dba.t_gzhs_zq              t1
				   WHERE NIANYUE=(SELECT MAX(NIANYUE) FROM dba.t_gzhs_zq  WHERE NIANYUE <=@V_BIN_YEAR||@V_BIN_MTH)
				  group by t1.nianyue, t1.cntr_id) t_htzq on t1.YEAR||T1.MTH = t_htzq.YEAR_MTH and t1.CTR_NO = t_htzq.CTR_NO
	  left join  #T_PUB_SER_RELA                   t2    on t1.YEAR = t2.YEAR             and t1.MTH = t2.MTH and t1.CUST_ID = t2.HS_CUST_ID
	 WHERE t1.OCCUR_DT=@V_BIN_DATE 
	   and t_htzq.CTR_NO is null
	   
	   )       t1
	   
	  left join #T_PTY_PERSON_M   t_yg on t1.OCCUR_DT=T_YG.OCCUR_DT  and t1.AFA_SEC_EMPID = t_yg.AFA_SEC_EMPID
	  left join #T_PUB_CUST       t_kh on t1.OCCUR_DT= t_kh.OCCUR_DT and t1.CUST_ID = t_kh.CUST_ID
	  WHERE AFA二期员工号 IS NOT NULL
group by
	t1.YEAR
	,t1.MTH
	,T1.OCCUR_DT
	,t1.CUST_ID	
	,t1.CTR_NO 
	,t1.YEAR||t1.MTH
	,t1.AFA_SEC_EMPID
	,t_kh.WH_ORG_ID
	,t_yg.WH_ORG_NO
;		
END
GO
CREATE PROCEDURE dm.P_AST_M_BRH(IN @V_DATE INT)
BEGIN

/******************************************************************
  程序功能: 营业部资产（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-09
  简介：营业部维度的客户资产表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
 	DECLARE @V_ACCU_MDAYS INT;		-- 月累计天数
 	DECLARE @V_ACCU_YDAYS INT;		-- 年累计天数
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_AST_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_YEAR									AS    YEAR   					--年
		,@V_MONTH 									AS    MTH 						--月
		,BRH_ID										AS    BRH_ID                	--营业部编码	
		,@V_DATE 									AS 	  OCCUR_DT 					--发生日期
		,SUM(TOT_AST)/@V_ACCU_MDAYS					AS    TOT_AST_MDA				--总资产_月日均			
		,SUM(SCDY_MVAL)/@V_ACCU_MDAYS				AS    SCDY_MVAL_MDA				--二级市值_月日均			
		,SUM(STKF_MVAL)/@V_ACCU_MDAYS				AS    STKF_MVAL_MDA				--股基市值_月日均			
		,SUM(A_SHR_MVAL)/@V_ACCU_MDAYS				AS    A_SHR_MVAL_MDA			--A股市值_月日均				
		,SUM(NOTS_MVAL)/@V_ACCU_MDAYS				AS    NOTS_MVAL_MDA				--限售股市值_月日均			
		,SUM(OFFUND_MVAL)/@V_ACCU_MDAYS				AS    OFFUND_MVAL_MDA			--场内基金市值_月日均				
		,SUM(OPFUND_MVAL)/@V_ACCU_MDAYS				AS    OPFUND_MVAL_MDA			--场外基金市值_月日均				
		,SUM(SB_MVAL)/@V_ACCU_MDAYS					AS    SB_MVAL_MDA				--三板市值_月日均			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_MDAYS			AS    IMGT_PD_MVAL_MDA			--资管产品市值_月日均				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_MDAYS			AS    BANK_CHRM_MVAL_MDA		--银行理财市值_月日均					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_MDAYS			AS    SECU_CHRM_MVAL_MDA		--证券理财市值_月日均					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_MDAYS			AS    PSTK_OPTN_MVAL_MDA		--个股期权市值_月日均					
		,SUM(B_SHR_MVAL)/@V_ACCU_MDAYS				AS    B_SHR_MVAL_MDA			--B股市值_月日均				
		,SUM(OUTMARK_MVAL)/@V_ACCU_MDAYS			AS    OUTMARK_MVAL_MDA			--体外市值_月日均				
		,SUM(CPTL_BAL)/@V_ACCU_MDAYS				AS    CPTL_BAL_MDA				--资金余额_月日均			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_MDAYS			AS    NO_ARVD_CPTL_MDA			--未到账资金_月日均				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_MDAYS			AS    PTE_FUND_MVAL_MDA			--私募基金市值_月日均				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_MDAYS			AS    CPTL_BAL_RMB_MDA			--资金余额人民币_月日均				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_MDAYS			AS    CPTL_BAL_HKD_MDA			--资金余额港币_月日均				
		,SUM(CPTL_BAL_USD)/@V_ACCU_MDAYS			AS    CPTL_BAL_USD_MDA			--资金余额美元_月日均				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_MDAYS		AS    FUND_SPACCT_MVAL_MDA		--基金专户市值_月日均					
		,SUM(HGT_MVAL)/@V_ACCU_MDAYS				AS    HGT_MVAL_MDA				--沪港通市值_月日均			
		,SUM(SGT_MVAL)/@V_ACCU_MDAYS				AS    SGT_MVAL_MDA				--深港通市值_月日均			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_MDAYS	AS    TOT_AST_CONTAIN_NOTS_MDA	--总资产_含限售股_月日均						
		,SUM(BOND_MVAL)/@V_ACCU_MDAYS				AS    BOND_MVAL_MDA				--债券市值_月日均			
		,SUM(REPO_MVAL)/@V_ACCU_MDAYS				AS    REPO_MVAL_MDA				--回购市值_月日均			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_MDAYS			AS    TREA_REPO_MVAL_MDA		--国债回购市值_月日均					
		,SUM(REPQ_MVAL)/@V_ACCU_MDAYS				AS    REPQ_MVAL_MDA				--报价回购市值_月日均			
		,SUM(PO_FUND_MVAL)/@V_ACCU_MDAYS			AS    PO_FUND_MVAL_MDA			--公募基金市值_月日均				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_MDAYS		AS    APPTBUYB_PLG_MVAL_MDA		--约定购回质押市值_月日均					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_MDAYS			AS    OTH_PROD_MVAL_MDA			--其他产品市值_月日均				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_MDAYS			AS    STKT_FUND_MVAL_MDA		--股票型基金市值_月日均					
		,SUM(OTH_AST_MVAL)/@V_ACCU_MDAYS			AS    OTH_AST_MVAL_MDA			--其他资产市值_月日均				
		,SUM(CREDIT_MARG)/@V_ACCU_MDAYS				AS    CREDIT_MARG_MDA			--融资融券保证金_月日均				
		,SUM(CREDIT_NET_AST)/@V_ACCU_MDAYS			AS    CREDIT_NET_AST_MDA		--融资融券净资产_月日均					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_MDAYS			AS    PROD_TOT_MVAL_MDA			--产品总市值_月日均				
		,SUM(JQL9_MVAL)/@V_ACCU_MDAYS				AS    JQL9_MVAL_MDA				--金麒麟9市值_月日均			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_MDAYS		AS    STKPLG_GUAR_SECMV_MDA		--股票质押担保证券市值_月日均					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_MDAYS			AS    STKPLG_FIN_BAL_MDA		--股票质押融资余额_月日均					
		,SUM(APPTBUYB_BAL)/@V_ACCU_MDAYS			AS    APPTBUYB_BAL_MDA			--约定购回余额_月日均				
		,SUM(CRED_MARG)/@V_ACCU_MDAYS				AS    CRED_MARG_MDA				--信用保证金_月日均			
		,SUM(INTR_LIAB)/@V_ACCU_MDAYS				AS    INTR_LIAB_MDA				--利息负债_月日均			
		,SUM(FEE_LIAB)/@V_ACCU_MDAYS				AS    FEE_LIAB_MDA				--费用负债_月日均			
		,SUM(OTHLIAB)/@V_ACCU_MDAYS					AS    OTHLIAB_MDA				--其他负债_月日均			
		,SUM(FIN_LIAB)/@V_ACCU_MDAYS				AS    FIN_LIAB_MDA				--融资负债_月日均			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_MDAYS			AS    CRDT_STK_LIAB_MDA			--融券负债_月日均				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_MDAYS			AS    CREDIT_TOT_AST_MDA		--融资融券总资产_月日均					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_MDAYS			AS    CREDIT_TOT_LIAB_MDA		--融资融券总负债_月日均					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_MDAYS		AS    APPTBUYB_GUAR_SECMV_MDA	--约定购回担保证券市值_月日均						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_MDAYS		AS    CREDIT_GUAR_SECMV_MDA		--融资融券担保证券市值_月日均					
	INTO #T_AST_M_BRH_MTH
	FROM DM.T_AST_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

		SELECT 
		 @V_YEAR									AS    YEAR   					--年
		,@V_MONTH 									AS    MTH 						--月
		,BRH_ID										AS    BRH_ID                	--营业部编码	
		,@V_DATE 									AS 	  OCCUR_DT 					--发生日期
		,SUM(TOT_AST)/@V_ACCU_YDAYS					AS    TOT_AST_YDA				--总资产_月日均			
		,SUM(SCDY_MVAL)/@V_ACCU_YDAYS				AS    SCDY_MVAL_YDA				--二级市值_月日均			
		,SUM(STKF_MVAL)/@V_ACCU_YDAYS				AS    STKF_MVAL_YDA				--股基市值_月日均			
		,SUM(A_SHR_MVAL)/@V_ACCU_YDAYS				AS    A_SHR_MVAL_YDA			--A股市值_月日均				
		,SUM(NOTS_MVAL)/@V_ACCU_YDAYS				AS    NOTS_MVAL_YDA				--限售股市值_月日均			
		,SUM(OFFUND_MVAL)/@V_ACCU_YDAYS				AS    OFFUND_MVAL_YDA			--场内基金市值_月日均				
		,SUM(OPFUND_MVAL)/@V_ACCU_YDAYS				AS    OPFUND_MVAL_YDA			--场外基金市值_月日均				
		,SUM(SB_MVAL)/@V_ACCU_YDAYS					AS    SB_MVAL_YDA				--三板市值_月日均			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_YDAYS			AS    IMGT_PD_MVAL_YDA			--资管产品市值_月日均				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_YDAYS			AS    BANK_CHRM_MVAL_YDA		--银行理财市值_月日均					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_YDAYS			AS    SECU_CHRM_MVAL_YDA		--证券理财市值_月日均					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_YDAYS			AS    PSTK_OPTN_MVAL_YDA		--个股期权市值_月日均					
		,SUM(B_SHR_MVAL)/@V_ACCU_YDAYS				AS    B_SHR_MVAL_YDA			--B股市值_月日均				
		,SUM(OUTMARK_MVAL)/@V_ACCU_YDAYS			AS    OUTMARK_MVAL_YDA			--体外市值_月日均				
		,SUM(CPTL_BAL)/@V_ACCU_YDAYS				AS    CPTL_BAL_YDA				--资金余额_月日均			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_YDAYS			AS    NO_ARVD_CPTL_YDA			--未到账资金_月日均				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_YDAYS			AS    PTE_FUND_MVAL_YDA			--私募基金市值_月日均				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_YDAYS			AS    CPTL_BAL_RMB_YDA			--资金余额人民币_月日均				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_YDAYS			AS    CPTL_BAL_HKD_YDA			--资金余额港币_月日均				
		,SUM(CPTL_BAL_USD)/@V_ACCU_YDAYS			AS    CPTL_BAL_USD_YDA			--资金余额美元_月日均				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_YDAYS		AS    FUND_SPACCT_MVAL_YDA		--基金专户市值_月日均					
		,SUM(HGT_MVAL)/@V_ACCU_YDAYS				AS    HGT_MVAL_YDA				--沪港通市值_月日均			
		,SUM(SGT_MVAL)/@V_ACCU_YDAYS				AS    SGT_MVAL_YDA				--深港通市值_月日均			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_YDAYS	AS    TOT_AST_CONTAIN_NOTS_YDA	--总资产_含限售股_月日均						
		,SUM(BOND_MVAL)/@V_ACCU_YDAYS				AS    BOND_MVAL_YDA				--债券市值_月日均			
		,SUM(REPO_MVAL)/@V_ACCU_YDAYS				AS    REPO_MVAL_YDA				--回购市值_月日均			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_YDAYS			AS    TREA_REPO_MVAL_YDA		--国债回购市值_月日均					
		,SUM(REPQ_MVAL)/@V_ACCU_YDAYS				AS    REPQ_MVAL_YDA				--报价回购市值_月日均			
		,SUM(PO_FUND_MVAL)/@V_ACCU_YDAYS			AS    PO_FUND_MVAL_YDA			--公募基金市值_月日均				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_YDAYS		AS    APPTBUYB_PLG_MVAL_YDA		--约定购回质押市值_月日均					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_YDAYS			AS    OTH_PROD_MVAL_YDA			--其他产品市值_月日均				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_YDAYS			AS    STKT_FUND_MVAL_YDA		--股票型基金市值_月日均					
		,SUM(OTH_AST_MVAL)/@V_ACCU_YDAYS			AS    OTH_AST_MVAL_YDA			--其他资产市值_月日均				
		,SUM(CREDIT_MARG)/@V_ACCU_YDAYS				AS    CREDIT_MARG_YDA			--融资融券保证金_月日均				
		,SUM(CREDIT_NET_AST)/@V_ACCU_YDAYS			AS    CREDIT_NET_AST_YDA		--融资融券净资产_月日均					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_YDAYS			AS    PROD_TOT_MVAL_YDA			--产品总市值_月日均				
		,SUM(JQL9_MVAL)/@V_ACCU_YDAYS				AS    JQL9_MVAL_YDA				--金麒麟9市值_月日均			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_YDAYS		AS    STKPLG_GUAR_SECMV_YDA		--股票质押担保证券市值_月日均					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_YDAYS			AS    STKPLG_FIN_BAL_YDA		--股票质押融资余额_月日均					
		,SUM(APPTBUYB_BAL)/@V_ACCU_YDAYS			AS    APPTBUYB_BAL_YDA			--约定购回余额_月日均				
		,SUM(CRED_MARG)/@V_ACCU_YDAYS				AS    CRED_MARG_YDA				--信用保证金_月日均			
		,SUM(INTR_LIAB)/@V_ACCU_YDAYS				AS    INTR_LIAB_YDA				--利息负债_月日均			
		,SUM(FEE_LIAB)/@V_ACCU_YDAYS				AS    FEE_LIAB_YDA				--费用负债_月日均			
		,SUM(OTHLIAB)/@V_ACCU_YDAYS					AS    OTHLIAB_YDA				--其他负债_月日均			
		,SUM(FIN_LIAB)/@V_ACCU_YDAYS				AS    FIN_LIAB_YDA				--融资负债_月日均			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_YDAYS			AS    CRDT_STK_LIAB_YDA			--融券负债_月日均				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_YDAYS			AS    CREDIT_TOT_AST_YDA		--融资融券总资产_月日均					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_YDAYS			AS    CREDIT_TOT_LIAB_YDA		--融资融券总负债_月日均					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_YDAYS		AS    APPTBUYB_GUAR_SECMV_YDA	--约定购回担保证券市值_月日均						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_YDAYS		AS    CREDIT_GUAR_SECMV_YDA		--融资融券担保证券市值_月日均					
	INTO #T_AST_M_BRH_YEAR
	FROM DM.T_AST_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--插入目标表
	INSERT INTO DM.T_AST_M_BRH(
		 YEAR        					--年
		,MTH         					--月
		,BRH_ID                			--营业部编码	
		,OCCUR_DT    					--发生日期
		,TOT_AST_MDA          			--总资产_月日均
		,TOT_AST_YDA          			--总资产_年日均
		,SCDY_MVAL_MDA        			--二级市值_月日均
		,SCDY_MVAL_YDA        			--二级市值_年日均
		,STKF_MVAL_MDA        			--股基市值_月日均
		,STKF_MVAL_YDA        			--股基市值_年日均
		,A_SHR_MVAL_MDA       			--A股市值_月日均
		,A_SHR_MVAL_YDA       			--A股市值_年日均
		,NOTS_MVAL_MDA        			--限售股市值_月日均
		,NOTS_MVAL_YDA        			--限售股市值_年日均
		,OFFUND_MVAL_MDA      			--场内基金市值_月日均
		,OFFUND_MVAL_YDA      			--场内基金市值_年日均
		,OPFUND_MVAL_MDA      			--场外基金市值_月日均
		,OPFUND_MVAL_YDA      			--场外基金市值_年日均
		,SB_MVAL_MDA          			--三板市值_月日均
		,SB_MVAL_YDA          			--三板市值_年日均
		,IMGT_PD_MVAL_MDA     			--资管产品市值_月日均
		,IMGT_PD_MVAL_YDA     			--资管产品市值_年日均
		,BANK_CHRM_MVAL_YDA   			--银行理财市值_年日均
		,BANK_CHRM_MVAL_MDA   			--银行理财市值_月日均
		,SECU_CHRM_MVAL_MDA   			--证券理财市值_月日均
		,SECU_CHRM_MVAL_YDA   			--证券理财市值_年日均
		,PSTK_OPTN_MVAL_MDA   			--个股期权市值_月日均
		,PSTK_OPTN_MVAL_YDA   			--个股期权市值_年日均
		,B_SHR_MVAL_MDA       			--B股市值_月日均
		,B_SHR_MVAL_YDA       			--B股市值_年日均
		,OUTMARK_MVAL_MDA     			--体外市值_月日均
		,OUTMARK_MVAL_YDA     			--体外市值_年日均
		,CPTL_BAL_MDA         			--资金余额_月日均
		,CPTL_BAL_YDA         			--资金余额_年日均
		,NO_ARVD_CPTL_MDA     			--未到账资金_月日均
		,NO_ARVD_CPTL_YDA     			--未到账资金_年日均
		,PTE_FUND_MVAL_MDA    			--私募基金市值_月日均
		,PTE_FUND_MVAL_YDA    			--私募基金市值_年日均
		,CPTL_BAL_RMB_MDA     			--资金余额人民币_月日均
		,CPTL_BAL_RMB_YDA     			--资金余额人民币_年日均
		,CPTL_BAL_HKD_MDA     			--资金余额港币_月日均
		,CPTL_BAL_HKD_YDA     			--资金余额港币_年日均
		,CPTL_BAL_USD_MDA     			--资金余额美元_月日均
		,CPTL_BAL_USD_YDA     			--资金余额美元_年日均
		,FUND_SPACCT_MVAL_MDA 			--基金专户市值_月日均
		,FUND_SPACCT_MVAL_YDA 			--基金专户市值_年日均
		,HGT_MVAL_MDA         			--沪港通市值_月日均
		,HGT_MVAL_YDA         			--沪港通市值_年日均
		,SGT_MVAL_MDA         			--深港通市值_月日均
		,SGT_MVAL_YDA         			--深港通市值_年日均
		,TOT_AST_CONTAIN_NOTS_MDA		--总资产_含限售股_月日均
		,TOT_AST_CONTAIN_NOTS_YDA		--总资产_含限售股_年日均
		,BOND_MVAL_MDA        			--债券市值_月日均
		,BOND_MVAL_YDA        			--债券市值_年日均
		,REPO_MVAL_MDA        			--回购市值_月日均
		,REPO_MVAL_YDA        			--回购市值_年日均
		,TREA_REPO_MVAL_MDA   			--国债回购市值_月日均
		,TREA_REPO_MVAL_YDA   			--国债回购市值_年日均
		,REPQ_MVAL_MDA        			--报价回购市值_月日均
		,REPQ_MVAL_YDA        			--报价回购市值_年日均
		,PO_FUND_MVAL_MDA     			--公募基金市值_月日均
		,PO_FUND_MVAL_YDA     			--公募基金市值_年日均
		,APPTBUYB_PLG_MVAL_MDA			--约定购回质押市值_月日均
		,APPTBUYB_PLG_MVAL_YDA			--约定购回质押市值_月日均
		,OTH_PROD_MVAL_MDA    			--其他产品市值_月日均
		,STKT_FUND_MVAL_MDA   			--股票型基金市值_月日均
		,OTH_AST_MVAL_MDA     			--其他资产市值_月日均
		,OTH_PROD_MVAL_YDA    			--其他产品市值_年日均
		,APPTBUYB_BAL_YDA     			--约定购回余额_月日均
		,CREDIT_MARG_MDA      			--融资融券保证金_月日均
		,CREDIT_MARG_YDA      			--融资融券保证金_年日均
		,CREDIT_NET_AST_MDA   			--融资融券净资产_月日均
		,CREDIT_NET_AST_YDA   			--融资融券净资产_年日均
		,PROD_TOT_MVAL_MDA    			--产品总市值_月日均
		,PROD_TOT_MVAL_YDA    			--产品总市值_年日均
		,JQL9_MVAL_MDA        			--金麒麟9市值_月日均
		,JQL9_MVAL_YDA        			--金麒麟9市值_年日均
		,STKPLG_GUAR_SECMV_MDA			--股票质押担保证券市值_月日均
		,STKPLG_GUAR_SECMV_YDA			--股票质押担保证券市值_年日均
		,STKPLG_FIN_BAL_MDA   			--股票质押融资余额_月日均
		,STKPLG_FIN_BAL_YDA   			--股票质押融资余额_年日均
		,APPTBUYB_BAL_MDA     			--约定购回余额_月日均
		,CRED_MARG_MDA        			--信用保证金_月日均
		,CRED_MARG_YDA        			--信用保证金_年日均
		,INTR_LIAB_MDA        			--利息负债_月日均
		,INTR_LIAB_YDA        			--利息负债_年日均
		,FEE_LIAB_MDA         			--费用负债_月日均
		,FEE_LIAB_YDA         			--费用负债_年日均
		,OTHLIAB_MDA          			--其他负债_月日均
		,OTHLIAB_YDA          			--其他负债_年日均
		,FIN_LIAB_MDA         			--融资负债_月日均
		,CRDT_STK_LIAB_YDA    			--融券负债_年日均
		,CRDT_STK_LIAB_MDA    			--融券负债_月日均
		,FIN_LIAB_YDA         			--融资负债_年日均
		,CREDIT_TOT_AST_MDA   			--融资融券总资产_月日均
		,CREDIT_TOT_AST_YDA   			--融资融券总资产_年日均
		,CREDIT_TOT_LIAB_MDA  			--融资融券总负债_月日均
		,CREDIT_TOT_LIAB_YDA  			--融资融券总负债_年日均
		,APPTBUYB_GUAR_SECMV_MDA		--约定购回担保证券市值_月日均
		,APPTBUYB_GUAR_SECMV_YDA		--约定购回担保证券市值_年日均
		,CREDIT_GUAR_SECMV_MDA			--融资融券担保证券市值_月日均
		,CREDIT_GUAR_SECMV_YDA			--融资融券担保证券市值_年日均		
	)		
	SELECT 
		 T1.YEAR						AS  YEAR					  --年
		,T1.MTH							AS  MTH						  --月
		,T1.BRH_ID                		AS  BRH_ID                	  --营业部编码		
		,T1.OCCUR_DT					AS  OCCUR_DT				  --发生日期
		,T1.TOT_AST_MDA	  	  			AS  TOT_AST_MDA               --总资产_月日均
		,T2.TOT_AST_YDA	  	  			AS  TOT_AST_YDA               --总资产_年日均
		,T1.SCDY_MVAL_MDA	  			AS  SCDY_MVAL_MDA             --二级市值_月日均
		,T2.SCDY_MVAL_YDA	  			AS  SCDY_MVAL_YDA             --二级市值_年日均
		,T1.STKF_MVAL_MDA	  			AS  STKF_MVAL_MDA             --股基市值_月日均
		,T2.STKF_MVAL_YDA	  			AS  STKF_MVAL_YDA             --股基市值_年日均
		,T1.A_SHR_MVAL_MDA	  			AS  A_SHR_MVAL_MDA            --A股市值_月日均
		,T2.A_SHR_MVAL_YDA	  			AS  A_SHR_MVAL_YDA            --A股市值_年日均
		,T1.NOTS_MVAL_MDA	  			AS  NOTS_MVAL_MDA             --限售股市值_月日均
		,T2.NOTS_MVAL_YDA	  			AS  NOTS_MVAL_YDA             --限售股市值_年日均
		,T1.OFFUND_MVAL_MDA	  			AS  OFFUND_MVAL_MDA           --场内基金市值_月日均
		,T2.OFFUND_MVAL_YDA	  			AS  OFFUND_MVAL_YDA           --场内基金市值_年日均
		,T1.OPFUND_MVAL_MDA	  			AS  OPFUND_MVAL_MDA           --场外基金市值_月日均
		,T2.OPFUND_MVAL_YDA	  			AS  OPFUND_MVAL_YDA           --场外基金市值_年日均
		,T1.SB_MVAL_MDA	  	  			AS  SB_MVAL_MDA               --三板市值_月日均
		,T2.SB_MVAL_YDA	  	  			AS  SB_MVAL_YDA               --三板市值_年日均
		,T1.IMGT_PD_MVAL_MDA	  		AS  IMGT_PD_MVAL_MDA          --资管产品市值_月日均
		,T2.IMGT_PD_MVAL_YDA	  		AS  IMGT_PD_MVAL_YDA          --资管产品市值_年日均
		,T2.BANK_CHRM_MVAL_YDA	  		AS  BANK_CHRM_MVAL_YDA        --银行理财市值_年日均
		,T1.BANK_CHRM_MVAL_MDA	  		AS  BANK_CHRM_MVAL_MDA        --银行理财市值_月日均
		,T1.SECU_CHRM_MVAL_MDA	  		AS  SECU_CHRM_MVAL_MDA        --证券理财市值_月日均
		,T2.SECU_CHRM_MVAL_YDA	  		AS  SECU_CHRM_MVAL_YDA        --证券理财市值_年日均
		,T1.PSTK_OPTN_MVAL_MDA	  		AS  PSTK_OPTN_MVAL_MDA        --个股期权市值_月日均
		,T2.PSTK_OPTN_MVAL_YDA	  		AS  PSTK_OPTN_MVAL_YDA        --个股期权市值_年日均
		,T1.B_SHR_MVAL_MDA	  			AS  B_SHR_MVAL_MDA            --B股市值_月日均
		,T2.B_SHR_MVAL_YDA	  			AS  B_SHR_MVAL_YDA            --B股市值_年日均
		,T1.OUTMARK_MVAL_MDA	  		AS  OUTMARK_MVAL_MDA          --体外市值_月日均
		,T2.OUTMARK_MVAL_YDA	  		AS  OUTMARK_MVAL_YDA          --体外市值_年日均
		,T1.CPTL_BAL_MDA	  			AS  CPTL_BAL_MDA              --资金余额_月日均
		,T2.CPTL_BAL_YDA	  			AS  CPTL_BAL_YDA              --资金余额_年日均
		,T1.NO_ARVD_CPTL_MDA	  		AS  NO_ARVD_CPTL_MDA          --未到账资金_月日均
		,T2.NO_ARVD_CPTL_YDA	  		AS  NO_ARVD_CPTL_YDA          --未到账资金_年日均
		,T1.PTE_FUND_MVAL_MDA	  		AS  PTE_FUND_MVAL_MDA         --私募基金市值_月日均
		,T2.PTE_FUND_MVAL_YDA	  		AS  PTE_FUND_MVAL_YDA         --私募基金市值_年日均
		,T1.CPTL_BAL_RMB_MDA	  		AS  CPTL_BAL_RMB_MDA          --资金余额人民币_月日均
		,T2.CPTL_BAL_RMB_YDA	  		AS  CPTL_BAL_RMB_YDA          --资金余额人民币_年日均
		,T1.CPTL_BAL_HKD_MDA	  		AS  CPTL_BAL_HKD_MDA          --资金余额港币_月日均
		,T2.CPTL_BAL_HKD_YDA	  		AS  CPTL_BAL_HKD_YDA          --资金余额港币_年日均
		,T1.CPTL_BAL_USD_MDA	  		AS  CPTL_BAL_USD_MDA          --资金余额美元_月日均
		,T2.CPTL_BAL_USD_YDA	  		AS  CPTL_BAL_USD_YDA          --资金余额美元_年日均
		,T1.FUND_SPACCT_MVAL_MDA	  	AS  FUND_SPACCT_MVAL_MDA      --基金专户市值_月日均
		,T2.FUND_SPACCT_MVAL_YDA	  	AS  FUND_SPACCT_MVAL_YDA      --基金专户市值_年日均
		,T1.HGT_MVAL_MDA	  			AS  HGT_MVAL_MDA              --沪港通市值_月日均
		,T2.HGT_MVAL_YDA	  			AS  HGT_MVAL_YDA              --沪港通市值_年日均
		,T1.SGT_MVAL_MDA	  			AS  SGT_MVAL_MDA              --深港通市值_月日均
		,T2.SGT_MVAL_YDA	  			AS  SGT_MVAL_YDA              --深港通市值_年日均
		,T1.TOT_AST_CONTAIN_NOTS_MDA	AS  TOT_AST_CONTAIN_NOTS_MDA  --总资产_含限售股_月日均
		,T2.TOT_AST_CONTAIN_NOTS_YDA	AS  TOT_AST_CONTAIN_NOTS_YDA  --总资产_含限售股_年日均
		,T1.BOND_MVAL_MDA	  			AS  BOND_MVAL_MDA             --债券市值_月日均
		,T2.BOND_MVAL_YDA	  			AS  BOND_MVAL_YDA             --债券市值_年日均
		,T1.REPO_MVAL_MDA	  			AS  REPO_MVAL_MDA             --回购市值_月日均
		,T2.REPO_MVAL_YDA	  			AS  REPO_MVAL_YDA             --回购市值_年日均
		,T1.TREA_REPO_MVAL_MDA	  		AS  TREA_REPO_MVAL_MDA        --国债回购市值_月日均
		,T2.TREA_REPO_MVAL_YDA	  		AS  TREA_REPO_MVAL_YDA        --国债回购市值_年日均
		,T1.REPQ_MVAL_MDA	  			AS  REPQ_MVAL_MDA             --报价回购市值_月日均
		,T2.REPQ_MVAL_YDA	  			AS  REPQ_MVAL_YDA             --报价回购市值_年日均
		,T1.PO_FUND_MVAL_MDA	  		AS  PO_FUND_MVAL_MDA          --公募基金市值_月日均
		,T2.PO_FUND_MVAL_YDA	  		AS  PO_FUND_MVAL_YDA          --公募基金市值_年日均
		,T1.APPTBUYB_PLG_MVAL_MDA	  	AS  APPTBUYB_PLG_MVAL_MDA     --约定购回质押市值_月日均
		,T2.APPTBUYB_PLG_MVAL_YDA	  	AS  APPTBUYB_PLG_MVAL_YDA     --约定购回质押市值_月日均
		,T1.OTH_PROD_MVAL_MDA	  		AS  OTH_PROD_MVAL_MDA         --其他产品市值_月日均
		,T1.STKT_FUND_MVAL_MDA	  		AS  STKT_FUND_MVAL_MDA        --股票型基金市值_月日均
		,T1.OTH_AST_MVAL_MDA	  		AS  OTH_AST_MVAL_MDA          --其他资产市值_月日均
		,T2.OTH_PROD_MVAL_YDA	  		AS  OTH_PROD_MVAL_YDA         --其他产品市值_年日均
		,T2.APPTBUYB_BAL_YDA	  		AS  APPTBUYB_BAL_YDA          --约定购回余额_月日均
		,T1.CREDIT_MARG_MDA	  			AS  CREDIT_MARG_MDA           --融资融券保证金_月日均
		,T2.CREDIT_MARG_YDA	  			AS  CREDIT_MARG_YDA           --融资融券保证金_年日均
		,T1.CREDIT_NET_AST_MDA	  		AS  CREDIT_NET_AST_MDA        --融资融券净资产_月日均
		,T2.CREDIT_NET_AST_YDA	  		AS  CREDIT_NET_AST_YDA        --融资融券净资产_年日均
		,T1.PROD_TOT_MVAL_MDA	  		AS  PROD_TOT_MVAL_MDA         --产品总市值_月日均
		,T2.PROD_TOT_MVAL_YDA	  		AS  PROD_TOT_MVAL_YDA         --产品总市值_年日均
		,T1.JQL9_MVAL_MDA	  			AS  JQL9_MVAL_MDA             --金麒麟9市值_月日均
		,T2.JQL9_MVAL_YDA	  			AS  JQL9_MVAL_YDA             --金麒麟9市值_年日均
		,T1.STKPLG_GUAR_SECMV_MDA	  	AS  STKPLG_GUAR_SECMV_MDA     --股票质押担保证券市值_月日均
		,T2.STKPLG_GUAR_SECMV_YDA	  	AS  STKPLG_GUAR_SECMV_YDA     --股票质押担保证券市值_年日均
		,T1.STKPLG_FIN_BAL_MDA	  		AS  STKPLG_FIN_BAL_MDA        --股票质押融资余额_月日均
		,T2.STKPLG_FIN_BAL_YDA	  		AS  STKPLG_FIN_BAL_YDA        --股票质押融资余额_年日均
		,T1.APPTBUYB_BAL_MDA	  		AS  APPTBUYB_BAL_MDA          --约定购回余额_月日均
		,T1.CRED_MARG_MDA	  			AS  CRED_MARG_MDA             --信用保证金_月日均
		,T2.CRED_MARG_YDA	  			AS  CRED_MARG_YDA             --信用保证金_年日均
		,T1.INTR_LIAB_MDA	  			AS  INTR_LIAB_MDA             --利息负债_月日均
		,T2.INTR_LIAB_YDA	  			AS  INTR_LIAB_YDA             --利息负债_年日均
		,T1.FEE_LIAB_MDA	  			AS  FEE_LIAB_MDA              --费用负债_月日均
		,T2.FEE_LIAB_YDA	  			AS  FEE_LIAB_YDA              --费用负债_年日均
		,T1.OTHLIAB_MDA	  				AS  OTHLIAB_MDA               --其他负债_月日均
		,T2.OTHLIAB_YDA	  				AS  OTHLIAB_YDA               --其他负债_年日均
		,T1.FIN_LIAB_MDA	  			AS  FIN_LIAB_MDA              --融资负债_月日均
		,T2.CRDT_STK_LIAB_YDA	  		AS  CRDT_STK_LIAB_YDA         --融券负债_年日均
		,T1.CRDT_STK_LIAB_MDA	  		AS  CRDT_STK_LIAB_MDA         --融券负债_月日均
		,T2.FIN_LIAB_YDA	  			AS  FIN_LIAB_YDA              --融资负债_年日均
		,T1.CREDIT_TOT_AST_MDA	  		AS  CREDIT_TOT_AST_MDA        --融资融券总资产_月日均
		,T2.CREDIT_TOT_AST_YDA	  		AS  CREDIT_TOT_AST_YDA        --融资融券总资产_年日均
		,T1.CREDIT_TOT_LIAB_MDA	  		AS  CREDIT_TOT_LIAB_MDA       --融资融券总负债_月日均
		,T2.CREDIT_TOT_LIAB_YDA	  		AS  CREDIT_TOT_LIAB_YDA       --融资融券总负债_年日均
		,T1.APPTBUYB_GUAR_SECMV_MDA	  	AS  APPTBUYB_GUAR_SECMV_MDA   --约定购回担保证券市值_月日均
		,T2.APPTBUYB_GUAR_SECMV_YDA	  	AS  APPTBUYB_GUAR_SECMV_YDA   --约定购回担保证券市值_年日均
		,T1.CREDIT_GUAR_SECMV_MDA	  	AS  CREDIT_GUAR_SECMV_MDA     --融资融券担保证券市值_月日均
		,T2.CREDIT_GUAR_SECMV_YDA	  	AS  CREDIT_GUAR_SECMV_YDA     --融资融券担保证券市值_年日均
	FROM #T_AST_M_BRH_MTH T1,#T_AST_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID 
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_AST_M_EMP(IN @V_DATE INT)
BEGIN

/******************************************************************
  程序功能: 员工资产（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-12
  简介：员工维度的客户资产表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
 	DECLARE @V_ACCU_MDAYS INT;		-- 月累计天数
 	DECLARE @V_ACCU_YDAYS INT;		-- 年累计天数
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_AST_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_YEAR									AS    YEAR   					--年
		,@V_MONTH 									AS    MTH 						--月
		,EMP_ID										AS    EMP_ID                	--员工编码	
		,@V_DATE 									AS 	  OCCUR_DT 					--发生日期
		,SUM(TOT_AST)/@V_ACCU_MDAYS					AS    TOT_AST_MDA				--总资产_月日均			
		,SUM(SCDY_MVAL)/@V_ACCU_MDAYS				AS    SCDY_MVAL_MDA				--二级市值_月日均			
		,SUM(STKF_MVAL)/@V_ACCU_MDAYS				AS    STKF_MVAL_MDA				--股基市值_月日均			
		,SUM(A_SHR_MVAL)/@V_ACCU_MDAYS				AS    A_SHR_MVAL_MDA			--A股市值_月日均				
		,SUM(NOTS_MVAL)/@V_ACCU_MDAYS				AS    NOTS_MVAL_MDA				--限售股市值_月日均			
		,SUM(OFFUND_MVAL)/@V_ACCU_MDAYS				AS    OFFUND_MVAL_MDA			--场内基金市值_月日均				
		,SUM(OPFUND_MVAL)/@V_ACCU_MDAYS				AS    OPFUND_MVAL_MDA			--场外基金市值_月日均				
		,SUM(SB_MVAL)/@V_ACCU_MDAYS					AS    SB_MVAL_MDA				--三板市值_月日均			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_MDAYS			AS    IMGT_PD_MVAL_MDA			--资管产品市值_月日均				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_MDAYS			AS    BANK_CHRM_MVAL_MDA		--银行理财市值_月日均					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_MDAYS			AS    SECU_CHRM_MVAL_MDA		--证券理财市值_月日均					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_MDAYS			AS    PSTK_OPTN_MVAL_MDA		--个股期权市值_月日均					
		,SUM(B_SHR_MVAL)/@V_ACCU_MDAYS				AS    B_SHR_MVAL_MDA			--B股市值_月日均				
		,SUM(OUTMARK_MVAL)/@V_ACCU_MDAYS			AS    OUTMARK_MVAL_MDA			--体外市值_月日均				
		,SUM(CPTL_BAL)/@V_ACCU_MDAYS				AS    CPTL_BAL_MDA				--资金余额_月日均			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_MDAYS			AS    NO_ARVD_CPTL_MDA			--未到账资金_月日均				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_MDAYS			AS    PTE_FUND_MVAL_MDA			--私募基金市值_月日均				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_MDAYS			AS    CPTL_BAL_RMB_MDA			--资金余额人民币_月日均				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_MDAYS			AS    CPTL_BAL_HKD_MDA			--资金余额港币_月日均				
		,SUM(CPTL_BAL_USD)/@V_ACCU_MDAYS			AS    CPTL_BAL_USD_MDA			--资金余额美元_月日均				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_MDAYS		AS    FUND_SPACCT_MVAL_MDA		--基金专户市值_月日均					
		,SUM(HGT_MVAL)/@V_ACCU_MDAYS				AS    HGT_MVAL_MDA				--沪港通市值_月日均			
		,SUM(SGT_MVAL)/@V_ACCU_MDAYS				AS    SGT_MVAL_MDA				--深港通市值_月日均			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_MDAYS	AS    TOT_AST_CONTAIN_NOTS_MDA	--总资产_含限售股_月日均						
		,SUM(BOND_MVAL)/@V_ACCU_MDAYS				AS    BOND_MVAL_MDA				--债券市值_月日均			
		,SUM(REPO_MVAL)/@V_ACCU_MDAYS				AS    REPO_MVAL_MDA				--回购市值_月日均			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_MDAYS			AS    TREA_REPO_MVAL_MDA		--国债回购市值_月日均					
		,SUM(REPQ_MVAL)/@V_ACCU_MDAYS				AS    REPQ_MVAL_MDA				--报价回购市值_月日均			
		,SUM(PO_FUND_MVAL)/@V_ACCU_MDAYS			AS    PO_FUND_MVAL_MDA			--公募基金市值_月日均				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_MDAYS		AS    APPTBUYB_PLG_MVAL_MDA		--约定购回质押市值_月日均					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_MDAYS			AS    OTH_PROD_MVAL_MDA			--其他产品市值_月日均				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_MDAYS			AS    STKT_FUND_MVAL_MDA		--股票型基金市值_月日均					
		,SUM(OTH_AST_MVAL)/@V_ACCU_MDAYS			AS    OTH_AST_MVAL_MDA			--其他资产市值_月日均				
		,SUM(CREDIT_MARG)/@V_ACCU_MDAYS				AS    CREDIT_MARG_MDA			--融资融券保证金_月日均				
		,SUM(CREDIT_NET_AST)/@V_ACCU_MDAYS			AS    CREDIT_NET_AST_MDA		--融资融券净资产_月日均					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_MDAYS			AS    PROD_TOT_MVAL_MDA			--产品总市值_月日均				
		,SUM(JQL9_MVAL)/@V_ACCU_MDAYS				AS    JQL9_MVAL_MDA				--金麒麟9市值_月日均			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_MDAYS		AS    STKPLG_GUAR_SECMV_MDA		--股票质押担保证券市值_月日均					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_MDAYS			AS    STKPLG_FIN_BAL_MDA		--股票质押融资余额_月日均					
		,SUM(APPTBUYB_BAL)/@V_ACCU_MDAYS			AS    APPTBUYB_BAL_MDA			--约定购回余额_月日均				
		,SUM(CRED_MARG)/@V_ACCU_MDAYS				AS    CRED_MARG_MDA				--信用保证金_月日均			
		,SUM(INTR_LIAB)/@V_ACCU_MDAYS				AS    INTR_LIAB_MDA				--利息负债_月日均			
		,SUM(FEE_LIAB)/@V_ACCU_MDAYS				AS    FEE_LIAB_MDA				--费用负债_月日均			
		,SUM(OTHLIAB)/@V_ACCU_MDAYS					AS    OTHLIAB_MDA				--其他负债_月日均			
		,SUM(FIN_LIAB)/@V_ACCU_MDAYS				AS    FIN_LIAB_MDA				--融资负债_月日均			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_MDAYS			AS    CRDT_STK_LIAB_MDA			--融券负债_月日均				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_MDAYS			AS    CREDIT_TOT_AST_MDA		--融资融券总资产_月日均					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_MDAYS			AS    CREDIT_TOT_LIAB_MDA		--融资融券总负债_月日均					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_MDAYS		AS    APPTBUYB_GUAR_SECMV_MDA	--约定购回担保证券市值_月日均						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_MDAYS		AS    CREDIT_GUAR_SECMV_MDA		--融资融券担保证券市值_月日均					
	INTO #T_AST_M_EMP_MTH
	FROM DM.T_AST_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

		SELECT 
		 @V_YEAR									AS    YEAR   					--年
		,@V_MONTH 									AS    MTH 						--月
		,EMP_ID										AS    EMP_ID                	--员工编码	
		,@V_DATE 									AS 	  OCCUR_DT 					--发生日期
		,SUM(TOT_AST)/@V_ACCU_YDAYS					AS    TOT_AST_YDA				--总资产_月日均			
		,SUM(SCDY_MVAL)/@V_ACCU_YDAYS				AS    SCDY_MVAL_YDA				--二级市值_月日均			
		,SUM(STKF_MVAL)/@V_ACCU_YDAYS				AS    STKF_MVAL_YDA				--股基市值_月日均			
		,SUM(A_SHR_MVAL)/@V_ACCU_YDAYS				AS    A_SHR_MVAL_YDA			--A股市值_月日均				
		,SUM(NOTS_MVAL)/@V_ACCU_YDAYS				AS    NOTS_MVAL_YDA				--限售股市值_月日均			
		,SUM(OFFUND_MVAL)/@V_ACCU_YDAYS				AS    OFFUND_MVAL_YDA			--场内基金市值_月日均				
		,SUM(OPFUND_MVAL)/@V_ACCU_YDAYS				AS    OPFUND_MVAL_YDA			--场外基金市值_月日均				
		,SUM(SB_MVAL)/@V_ACCU_YDAYS					AS    SB_MVAL_YDA				--三板市值_月日均			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_YDAYS			AS    IMGT_PD_MVAL_YDA			--资管产品市值_月日均				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_YDAYS			AS    BANK_CHRM_MVAL_YDA		--银行理财市值_月日均					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_YDAYS			AS    SECU_CHRM_MVAL_YDA		--证券理财市值_月日均					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_YDAYS			AS    PSTK_OPTN_MVAL_YDA		--个股期权市值_月日均					
		,SUM(B_SHR_MVAL)/@V_ACCU_YDAYS				AS    B_SHR_MVAL_YDA			--B股市值_月日均				
		,SUM(OUTMARK_MVAL)/@V_ACCU_YDAYS			AS    OUTMARK_MVAL_YDA			--体外市值_月日均				
		,SUM(CPTL_BAL)/@V_ACCU_YDAYS				AS    CPTL_BAL_YDA				--资金余额_月日均			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_YDAYS			AS    NO_ARVD_CPTL_YDA			--未到账资金_月日均				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_YDAYS			AS    PTE_FUND_MVAL_YDA			--私募基金市值_月日均				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_YDAYS			AS    CPTL_BAL_RMB_YDA			--资金余额人民币_月日均				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_YDAYS			AS    CPTL_BAL_HKD_YDA			--资金余额港币_月日均				
		,SUM(CPTL_BAL_USD)/@V_ACCU_YDAYS			AS    CPTL_BAL_USD_YDA			--资金余额美元_月日均				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_YDAYS		AS    FUND_SPACCT_MVAL_YDA		--基金专户市值_月日均					
		,SUM(HGT_MVAL)/@V_ACCU_YDAYS				AS    HGT_MVAL_YDA				--沪港通市值_月日均			
		,SUM(SGT_MVAL)/@V_ACCU_YDAYS				AS    SGT_MVAL_YDA				--深港通市值_月日均			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_YDAYS	AS    TOT_AST_CONTAIN_NOTS_YDA	--总资产_含限售股_月日均						
		,SUM(BOND_MVAL)/@V_ACCU_YDAYS				AS    BOND_MVAL_YDA				--债券市值_月日均			
		,SUM(REPO_MVAL)/@V_ACCU_YDAYS				AS    REPO_MVAL_YDA				--回购市值_月日均			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_YDAYS			AS    TREA_REPO_MVAL_YDA		--国债回购市值_月日均					
		,SUM(REPQ_MVAL)/@V_ACCU_YDAYS				AS    REPQ_MVAL_YDA				--报价回购市值_月日均			
		,SUM(PO_FUND_MVAL)/@V_ACCU_YDAYS			AS    PO_FUND_MVAL_YDA			--公募基金市值_月日均				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_YDAYS		AS    APPTBUYB_PLG_MVAL_YDA		--约定购回质押市值_月日均					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_YDAYS			AS    OTH_PROD_MVAL_YDA			--其他产品市值_月日均				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_YDAYS			AS    STKT_FUND_MVAL_YDA		--股票型基金市值_月日均					
		,SUM(OTH_AST_MVAL)/@V_ACCU_YDAYS			AS    OTH_AST_MVAL_YDA			--其他资产市值_月日均				
		,SUM(CREDIT_MARG)/@V_ACCU_YDAYS				AS    CREDIT_MARG_YDA			--融资融券保证金_月日均				
		,SUM(CREDIT_NET_AST)/@V_ACCU_YDAYS			AS    CREDIT_NET_AST_YDA		--融资融券净资产_月日均					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_YDAYS			AS    PROD_TOT_MVAL_YDA			--产品总市值_月日均				
		,SUM(JQL9_MVAL)/@V_ACCU_YDAYS				AS    JQL9_MVAL_YDA				--金麒麟9市值_月日均			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_YDAYS		AS    STKPLG_GUAR_SECMV_YDA		--股票质押担保证券市值_月日均					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_YDAYS			AS    STKPLG_FIN_BAL_YDA		--股票质押融资余额_月日均					
		,SUM(APPTBUYB_BAL)/@V_ACCU_YDAYS			AS    APPTBUYB_BAL_YDA			--约定购回余额_月日均				
		,SUM(CRED_MARG)/@V_ACCU_YDAYS				AS    CRED_MARG_YDA				--信用保证金_月日均			
		,SUM(INTR_LIAB)/@V_ACCU_YDAYS				AS    INTR_LIAB_YDA				--利息负债_月日均			
		,SUM(FEE_LIAB)/@V_ACCU_YDAYS				AS    FEE_LIAB_YDA				--费用负债_月日均			
		,SUM(OTHLIAB)/@V_ACCU_YDAYS					AS    OTHLIAB_YDA				--其他负债_月日均			
		,SUM(FIN_LIAB)/@V_ACCU_YDAYS				AS    FIN_LIAB_YDA				--融资负债_月日均			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_YDAYS			AS    CRDT_STK_LIAB_YDA			--融券负债_月日均				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_YDAYS			AS    CREDIT_TOT_AST_YDA		--融资融券总资产_月日均					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_YDAYS			AS    CREDIT_TOT_LIAB_YDA		--融资融券总负债_月日均					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_YDAYS		AS    APPTBUYB_GUAR_SECMV_YDA	--约定购回担保证券市值_月日均						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_YDAYS		AS    CREDIT_GUAR_SECMV_YDA		--融资融券担保证券市值_月日均					
	INTO #T_AST_M_EMP_YEAR
	FROM DM.T_AST_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	--插入目标表
	INSERT INTO DM.T_AST_M_EMP(
		 YEAR        					--年
		,MTH         					--月
		,EMP_ID      					--员工编号
		,OCCUR_DT    					--发生日期
		,TOT_AST_MDA          			--总资产_月日均
		,TOT_AST_YDA          			--总资产_年日均
		,SCDY_MVAL_MDA        			--二级市值_月日均
		,SCDY_MVAL_YDA        			--二级市值_年日均
		,STKF_MVAL_MDA        			--股基市值_月日均
		,STKF_MVAL_YDA        			--股基市值_年日均
		,A_SHR_MVAL_MDA       			--A股市值_月日均
		,A_SHR_MVAL_YDA       			--A股市值_年日均
		,NOTS_MVAL_MDA        			--限售股市值_月日均
		,NOTS_MVAL_YDA        			--限售股市值_年日均
		,OFFUND_MVAL_MDA      			--场内基金市值_月日均
		,OFFUND_MVAL_YDA      			--场内基金市值_年日均
		,OPFUND_MVAL_MDA      			--场外基金市值_月日均
		,OPFUND_MVAL_YDA      			--场外基金市值_年日均
		,SB_MVAL_MDA          			--三板市值_月日均
		,SB_MVAL_YDA          			--三板市值_年日均
		,IMGT_PD_MVAL_MDA     			--资管产品市值_月日均
		,IMGT_PD_MVAL_YDA     			--资管产品市值_年日均
		,BANK_CHRM_MVAL_YDA   			--银行理财市值_年日均
		,BANK_CHRM_MVAL_MDA   			--银行理财市值_月日均
		,SECU_CHRM_MVAL_MDA   			--证券理财市值_月日均
		,SECU_CHRM_MVAL_YDA   			--证券理财市值_年日均
		,PSTK_OPTN_MVAL_MDA   			--个股期权市值_月日均
		,PSTK_OPTN_MVAL_YDA   			--个股期权市值_年日均
		,B_SHR_MVAL_MDA       			--B股市值_月日均
		,B_SHR_MVAL_YDA       			--B股市值_年日均
		,OUTMARK_MVAL_MDA     			--体外市值_月日均
		,OUTMARK_MVAL_YDA     			--体外市值_年日均
		,CPTL_BAL_MDA         			--资金余额_月日均
		,CPTL_BAL_YDA         			--资金余额_年日均
		,NO_ARVD_CPTL_MDA     			--未到账资金_月日均
		,NO_ARVD_CPTL_YDA     			--未到账资金_年日均
		,PTE_FUND_MVAL_MDA    			--私募基金市值_月日均
		,PTE_FUND_MVAL_YDA    			--私募基金市值_年日均
		,CPTL_BAL_RMB_MDA     			--资金余额人民币_月日均
		,CPTL_BAL_RMB_YDA     			--资金余额人民币_年日均
		,CPTL_BAL_HKD_MDA     			--资金余额港币_月日均
		,CPTL_BAL_HKD_YDA     			--资金余额港币_年日均
		,CPTL_BAL_USD_MDA     			--资金余额美元_月日均
		,CPTL_BAL_USD_YDA     			--资金余额美元_年日均
		,FUND_SPACCT_MVAL_MDA 			--基金专户市值_月日均
		,FUND_SPACCT_MVAL_YDA 			--基金专户市值_年日均
		,HGT_MVAL_MDA         			--沪港通市值_月日均
		,HGT_MVAL_YDA         			--沪港通市值_年日均
		,SGT_MVAL_MDA         			--深港通市值_月日均
		,SGT_MVAL_YDA         			--深港通市值_年日均
		,TOT_AST_CONTAIN_NOTS_MDA		--总资产_含限售股_月日均
		,TOT_AST_CONTAIN_NOTS_YDA		--总资产_含限售股_年日均
		,BOND_MVAL_MDA        			--债券市值_月日均
		,BOND_MVAL_YDA        			--债券市值_年日均
		,REPO_MVAL_MDA        			--回购市值_月日均
		,REPO_MVAL_YDA        			--回购市值_年日均
		,TREA_REPO_MVAL_MDA   			--国债回购市值_月日均
		,TREA_REPO_MVAL_YDA   			--国债回购市值_年日均
		,REPQ_MVAL_MDA        			--报价回购市值_月日均
		,REPQ_MVAL_YDA        			--报价回购市值_年日均
		,PO_FUND_MVAL_MDA     			--公募基金市值_月日均
		,PO_FUND_MVAL_YDA     			--公募基金市值_年日均
		,APPTBUYB_PLG_MVAL_MDA			--约定购回质押市值_月日均
		,APPTBUYB_PLG_MVAL_YDA			--约定购回质押市值_月日均
		,OTH_PROD_MVAL_MDA    			--其他产品市值_月日均
		,STKT_FUND_MVAL_MDA   			--股票型基金市值_月日均
		,OTH_AST_MVAL_MDA     			--其他资产市值_月日均
		,OTH_PROD_MVAL_YDA    			--其他产品市值_年日均
		,APPTBUYB_BAL_YDA     			--约定购回余额_月日均
		,CREDIT_MARG_MDA      			--融资融券保证金_月日均
		,CREDIT_MARG_YDA      			--融资融券保证金_年日均
		,CREDIT_NET_AST_MDA   			--融资融券净资产_月日均
		,CREDIT_NET_AST_YDA   			--融资融券净资产_年日均
		,PROD_TOT_MVAL_MDA    			--产品总市值_月日均
		,PROD_TOT_MVAL_YDA    			--产品总市值_年日均
		,JQL9_MVAL_MDA        			--金麒麟9市值_月日均
		,JQL9_MVAL_YDA        			--金麒麟9市值_年日均
		,STKPLG_GUAR_SECMV_MDA			--股票质押担保证券市值_月日均
		,STKPLG_GUAR_SECMV_YDA			--股票质押担保证券市值_年日均
		,STKPLG_FIN_BAL_MDA   			--股票质押融资余额_月日均
		,STKPLG_FIN_BAL_YDA   			--股票质押融资余额_年日均
		,APPTBUYB_BAL_MDA     			--约定购回余额_月日均
		,CRED_MARG_MDA        			--信用保证金_月日均
		,CRED_MARG_YDA        			--信用保证金_年日均
		,INTR_LIAB_MDA        			--利息负债_月日均
		,INTR_LIAB_YDA        			--利息负债_年日均
		,FEE_LIAB_MDA         			--费用负债_月日均
		,FEE_LIAB_YDA         			--费用负债_年日均
		,OTHLIAB_MDA          			--其他负债_月日均
		,OTHLIAB_YDA          			--其他负债_年日均
		,FIN_LIAB_MDA         			--融资负债_月日均
		,CRDT_STK_LIAB_YDA    			--融券负债_年日均
		,CRDT_STK_LIAB_MDA    			--融券负债_月日均
		,FIN_LIAB_YDA         			--融资负债_年日均
		,CREDIT_TOT_AST_MDA   			--融资融券总资产_月日均
		,CREDIT_TOT_AST_YDA   			--融资融券总资产_年日均
		,CREDIT_TOT_LIAB_MDA  			--融资融券总负债_月日均
		,CREDIT_TOT_LIAB_YDA  			--融资融券总负债_年日均
		,APPTBUYB_GUAR_SECMV_MDA		--约定购回担保证券市值_月日均
		,APPTBUYB_GUAR_SECMV_YDA		--约定购回担保证券市值_年日均
		,CREDIT_GUAR_SECMV_MDA			--融资融券担保证券市值_月日均
		,CREDIT_GUAR_SECMV_YDA			--融资融券担保证券市值_年日均		
	)		
	SELECT 
		T1.YEAR							AS  YEAR					  --年
		,T1.MTH							AS  MTH						  --月
		,T1.EMP_ID						AS  EMP_ID					  --员工编号
		,T1.OCCUR_DT					AS  OCCUR_DT				  --发生日期
		,T1.TOT_AST_MDA	  	  			AS  TOT_AST_MDA               --总资产_月日均
		,T2.TOT_AST_YDA	  	  			AS  TOT_AST_YDA               --总资产_年日均
		,T1.SCDY_MVAL_MDA	  			AS  SCDY_MVAL_MDA             --二级市值_月日均
		,T2.SCDY_MVAL_YDA	  			AS  SCDY_MVAL_YDA             --二级市值_年日均
		,T1.STKF_MVAL_MDA	  			AS  STKF_MVAL_MDA             --股基市值_月日均
		,T2.STKF_MVAL_YDA	  			AS  STKF_MVAL_YDA             --股基市值_年日均
		,T1.A_SHR_MVAL_MDA	  			AS  A_SHR_MVAL_MDA            --A股市值_月日均
		,T2.A_SHR_MVAL_YDA	  			AS  A_SHR_MVAL_YDA            --A股市值_年日均
		,T1.NOTS_MVAL_MDA	  			AS  NOTS_MVAL_MDA             --限售股市值_月日均
		,T2.NOTS_MVAL_YDA	  			AS  NOTS_MVAL_YDA             --限售股市值_年日均
		,T1.OFFUND_MVAL_MDA	  			AS  OFFUND_MVAL_MDA           --场内基金市值_月日均
		,T2.OFFUND_MVAL_YDA	  			AS  OFFUND_MVAL_YDA           --场内基金市值_年日均
		,T1.OPFUND_MVAL_MDA	  			AS  OPFUND_MVAL_MDA           --场外基金市值_月日均
		,T2.OPFUND_MVAL_YDA	  			AS  OPFUND_MVAL_YDA           --场外基金市值_年日均
		,T1.SB_MVAL_MDA	  	  			AS  SB_MVAL_MDA               --三板市值_月日均
		,T2.SB_MVAL_YDA	  	  			AS  SB_MVAL_YDA               --三板市值_年日均
		,T1.IMGT_PD_MVAL_MDA	  		AS  IMGT_PD_MVAL_MDA          --资管产品市值_月日均
		,T2.IMGT_PD_MVAL_YDA	  		AS  IMGT_PD_MVAL_YDA          --资管产品市值_年日均
		,T2.BANK_CHRM_MVAL_YDA	  		AS  BANK_CHRM_MVAL_YDA        --银行理财市值_年日均
		,T1.BANK_CHRM_MVAL_MDA	  		AS  BANK_CHRM_MVAL_MDA        --银行理财市值_月日均
		,T1.SECU_CHRM_MVAL_MDA	  		AS  SECU_CHRM_MVAL_MDA        --证券理财市值_月日均
		,T2.SECU_CHRM_MVAL_YDA	  		AS  SECU_CHRM_MVAL_YDA        --证券理财市值_年日均
		,T1.PSTK_OPTN_MVAL_MDA	  		AS  PSTK_OPTN_MVAL_MDA        --个股期权市值_月日均
		,T2.PSTK_OPTN_MVAL_YDA	  		AS  PSTK_OPTN_MVAL_YDA        --个股期权市值_年日均
		,T1.B_SHR_MVAL_MDA	  			AS  B_SHR_MVAL_MDA            --B股市值_月日均
		,T2.B_SHR_MVAL_YDA	  			AS  B_SHR_MVAL_YDA            --B股市值_年日均
		,T1.OUTMARK_MVAL_MDA	  		AS  OUTMARK_MVAL_MDA          --体外市值_月日均
		,T2.OUTMARK_MVAL_YDA	  		AS  OUTMARK_MVAL_YDA          --体外市值_年日均
		,T1.CPTL_BAL_MDA	  			AS  CPTL_BAL_MDA              --资金余额_月日均
		,T2.CPTL_BAL_YDA	  			AS  CPTL_BAL_YDA              --资金余额_年日均
		,T1.NO_ARVD_CPTL_MDA	  		AS  NO_ARVD_CPTL_MDA          --未到账资金_月日均
		,T2.NO_ARVD_CPTL_YDA	  		AS  NO_ARVD_CPTL_YDA          --未到账资金_年日均
		,T1.PTE_FUND_MVAL_MDA	  		AS  PTE_FUND_MVAL_MDA         --私募基金市值_月日均
		,T2.PTE_FUND_MVAL_YDA	  		AS  PTE_FUND_MVAL_YDA         --私募基金市值_年日均
		,T1.CPTL_BAL_RMB_MDA	  		AS  CPTL_BAL_RMB_MDA          --资金余额人民币_月日均
		,T2.CPTL_BAL_RMB_YDA	  		AS  CPTL_BAL_RMB_YDA          --资金余额人民币_年日均
		,T1.CPTL_BAL_HKD_MDA	  		AS  CPTL_BAL_HKD_MDA          --资金余额港币_月日均
		,T2.CPTL_BAL_HKD_YDA	  		AS  CPTL_BAL_HKD_YDA          --资金余额港币_年日均
		,T1.CPTL_BAL_USD_MDA	  		AS  CPTL_BAL_USD_MDA          --资金余额美元_月日均
		,T2.CPTL_BAL_USD_YDA	  		AS  CPTL_BAL_USD_YDA          --资金余额美元_年日均
		,T1.FUND_SPACCT_MVAL_MDA	  	AS  FUND_SPACCT_MVAL_MDA      --基金专户市值_月日均
		,T2.FUND_SPACCT_MVAL_YDA	  	AS  FUND_SPACCT_MVAL_YDA      --基金专户市值_年日均
		,T1.HGT_MVAL_MDA	  			AS  HGT_MVAL_MDA              --沪港通市值_月日均
		,T2.HGT_MVAL_YDA	  			AS  HGT_MVAL_YDA              --沪港通市值_年日均
		,T1.SGT_MVAL_MDA	  			AS  SGT_MVAL_MDA              --深港通市值_月日均
		,T2.SGT_MVAL_YDA	  			AS  SGT_MVAL_YDA              --深港通市值_年日均
		,T1.TOT_AST_CONTAIN_NOTS_MDA	AS  TOT_AST_CONTAIN_NOTS_MDA  --总资产_含限售股_月日均
		,T2.TOT_AST_CONTAIN_NOTS_YDA	AS  TOT_AST_CONTAIN_NOTS_YDA  --总资产_含限售股_年日均
		,T1.BOND_MVAL_MDA	  			AS  BOND_MVAL_MDA             --债券市值_月日均
		,T2.BOND_MVAL_YDA	  			AS  BOND_MVAL_YDA             --债券市值_年日均
		,T1.REPO_MVAL_MDA	  			AS  REPO_MVAL_MDA             --回购市值_月日均
		,T2.REPO_MVAL_YDA	  			AS  REPO_MVAL_YDA             --回购市值_年日均
		,T1.TREA_REPO_MVAL_MDA	  		AS  TREA_REPO_MVAL_MDA        --国债回购市值_月日均
		,T2.TREA_REPO_MVAL_YDA	  		AS  TREA_REPO_MVAL_YDA        --国债回购市值_年日均
		,T1.REPQ_MVAL_MDA	  			AS  REPQ_MVAL_MDA             --报价回购市值_月日均
		,T2.REPQ_MVAL_YDA	  			AS  REPQ_MVAL_YDA             --报价回购市值_年日均
		,T1.PO_FUND_MVAL_MDA	  		AS  PO_FUND_MVAL_MDA          --公募基金市值_月日均
		,T2.PO_FUND_MVAL_YDA	  		AS  PO_FUND_MVAL_YDA          --公募基金市值_年日均
		,T1.APPTBUYB_PLG_MVAL_MDA	  	AS  APPTBUYB_PLG_MVAL_MDA     --约定购回质押市值_月日均
		,T2.APPTBUYB_PLG_MVAL_YDA	  	AS  APPTBUYB_PLG_MVAL_YDA     --约定购回质押市值_月日均
		,T1.OTH_PROD_MVAL_MDA	  		AS  OTH_PROD_MVAL_MDA         --其他产品市值_月日均
		,T1.STKT_FUND_MVAL_MDA	  		AS  STKT_FUND_MVAL_MDA        --股票型基金市值_月日均
		,T1.OTH_AST_MVAL_MDA	  		AS  OTH_AST_MVAL_MDA          --其他资产市值_月日均
		,T2.OTH_PROD_MVAL_YDA	  		AS  OTH_PROD_MVAL_YDA         --其他产品市值_年日均
		,T2.APPTBUYB_BAL_YDA	  		AS  APPTBUYB_BAL_YDA          --约定购回余额_月日均
		,T1.CREDIT_MARG_MDA	  			AS  CREDIT_MARG_MDA           --融资融券保证金_月日均
		,T2.CREDIT_MARG_YDA	  			AS  CREDIT_MARG_YDA           --融资融券保证金_年日均
		,T1.CREDIT_NET_AST_MDA	  		AS  CREDIT_NET_AST_MDA        --融资融券净资产_月日均
		,T2.CREDIT_NET_AST_YDA	  		AS  CREDIT_NET_AST_YDA        --融资融券净资产_年日均
		,T1.PROD_TOT_MVAL_MDA	  		AS  PROD_TOT_MVAL_MDA         --产品总市值_月日均
		,T2.PROD_TOT_MVAL_YDA	  		AS  PROD_TOT_MVAL_YDA         --产品总市值_年日均
		,T1.JQL9_MVAL_MDA	  			AS  JQL9_MVAL_MDA             --金麒麟9市值_月日均
		,T2.JQL9_MVAL_YDA	  			AS  JQL9_MVAL_YDA             --金麒麟9市值_年日均
		,T1.STKPLG_GUAR_SECMV_MDA	  	AS  STKPLG_GUAR_SECMV_MDA     --股票质押担保证券市值_月日均
		,T2.STKPLG_GUAR_SECMV_YDA	  	AS  STKPLG_GUAR_SECMV_YDA     --股票质押担保证券市值_年日均
		,T1.STKPLG_FIN_BAL_MDA	  		AS  STKPLG_FIN_BAL_MDA        --股票质押融资余额_月日均
		,T2.STKPLG_FIN_BAL_YDA	  		AS  STKPLG_FIN_BAL_YDA        --股票质押融资余额_年日均
		,T1.APPTBUYB_BAL_MDA	  		AS  APPTBUYB_BAL_MDA          --约定购回余额_月日均
		,T1.CRED_MARG_MDA	  			AS  CRED_MARG_MDA             --信用保证金_月日均
		,T2.CRED_MARG_YDA	  			AS  CRED_MARG_YDA             --信用保证金_年日均
		,T1.INTR_LIAB_MDA	  			AS  INTR_LIAB_MDA             --利息负债_月日均
		,T2.INTR_LIAB_YDA	  			AS  INTR_LIAB_YDA             --利息负债_年日均
		,T1.FEE_LIAB_MDA	  			AS  FEE_LIAB_MDA              --费用负债_月日均
		,T2.FEE_LIAB_YDA	  			AS  FEE_LIAB_YDA              --费用负债_年日均
		,T1.OTHLIAB_MDA	  				AS  OTHLIAB_MDA               --其他负债_月日均
		,T2.OTHLIAB_YDA	  				AS  OTHLIAB_YDA               --其他负债_年日均
		,T1.FIN_LIAB_MDA	  			AS  FIN_LIAB_MDA              --融资负债_月日均
		,T2.CRDT_STK_LIAB_YDA	  		AS  CRDT_STK_LIAB_YDA         --融券负债_年日均
		,T1.CRDT_STK_LIAB_MDA	  		AS  CRDT_STK_LIAB_MDA         --融券负债_月日均
		,T2.FIN_LIAB_YDA	  			AS  FIN_LIAB_YDA              --融资负债_年日均
		,T1.CREDIT_TOT_AST_MDA	  		AS  CREDIT_TOT_AST_MDA        --融资融券总资产_月日均
		,T2.CREDIT_TOT_AST_YDA	  		AS  CREDIT_TOT_AST_YDA        --融资融券总资产_年日均
		,T1.CREDIT_TOT_LIAB_MDA	  		AS  CREDIT_TOT_LIAB_MDA       --融资融券总负债_月日均
		,T2.CREDIT_TOT_LIAB_YDA	  		AS  CREDIT_TOT_LIAB_YDA       --融资融券总负债_年日均
		,T1.APPTBUYB_GUAR_SECMV_MDA	  	AS  APPTBUYB_GUAR_SECMV_MDA   --约定购回担保证券市值_月日均
		,T2.APPTBUYB_GUAR_SECMV_YDA	  	AS  APPTBUYB_GUAR_SECMV_YDA   --约定购回担保证券市值_年日均
		,T1.CREDIT_GUAR_SECMV_MDA	  	AS  CREDIT_GUAR_SECMV_MDA     --融资融券担保证券市值_月日均
		,T2.CREDIT_GUAR_SECMV_YDA	  	AS  CREDIT_GUAR_SECMV_YDA     --融资融券担保证券市值_年日均
	FROM #T_AST_M_EMP_MTH T1,#T_AST_M_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID 
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.p_ast_odi(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能: 客户普通资产表
  编写者: rengz
  创建日期: 2017-11-16
  简介：不包括信用及衍生品等的普通账户资产，日更新
       主要指标参考全景图日表日更新dba.tmp_ddw_khqjt_d_d进行处理
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             2017-12-06               rengz              修订私募基金，根据柜台产品表进行分类 dba.t_edw_uf2_prodcode where  prodcode_type='j'
             2017-12-20               rengz              增加公募基金市值
             2018-1-31                rengz              根据经纪业务总部要求，增加 股基市值、其他产品市值（未设置或设置类型为空）、其他资产、约定购回质押市值、期末资产等字段  
             2018-4-12                rengz              1、增加股票质押负债
                                                         2、未到账金额修正股票质押负债
                                                         3、其他资产调整为：TOT_AST_N_CONTAIN_NOTS（总资产_不含限售股）+股票质押负债
                                                         4、期末资产final_ast即为经纪业务总部要求的总资产=股基市值+资金余额+债券市值+回购市值+产品总市值+其他资产+未到账资金+股票质押负债+融资融券总资产+约定购回质押市值+限售股市值+个股期权市值
  *********************************************************************/
  
    --declare @v_bin_date         numeric(8); 
    declare @v_bin_mth          varchar(2);
    declare @v_bin_year         varchar(4);   
    declare @v_bin_20avg_start  numeric(8,0);---最近20个交易日开始日期
    declare @v_bin_20avg_end    numeric(8,0);---最近20个交易日结束日期

	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date;

    --生成衍生变量
    set @v_bin_mth  =substr(convert(varchar,@v_bin_date),5,2);
    set @v_bin_year =substr(convert(varchar,@v_bin_date),1,4);
    set @v_bin_20avg_start =(select b.rq
                             from    dba.t_ddw_d_rq      a
                             left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=21      --(T-21日)打新 t-2日前20天
                             where a.rq=@v_bin_date);
    set @v_bin_20avg_end =(select b.rq
                            from    dba.t_ddw_d_rq      a
                            left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=2       --(T-2日)打新t-2日
                            where a.rq=@v_bin_date);	
    commit;

   
    --删除计算期数据
    delete from dm.t_ast_odi where load_dt =@v_bin_date;
    commit;

    ---插入基础客户信息
    insert into dm.t_ast_odi(
                            OCCUR_DT,               --清洗日期 
                            CUST_ID,                --客户编码
                            main_cptl_acct,         --主资金账号
                            TOT_AST_N_CONTAIN_NOTS, --总资产_不含限售股
                            RCT_20D_DA_AST,	        --近20日日均资产
                            SCDY_MVAL,	            --二级市值
                            NO_ARVD_CPTL,	        --未到账资金
                            CPTL_BAL,	            --资金余额
                            CPTL_BAL_RMB,	        --资金余额人民币
                            CPTL_BAL_HKD,	        --资金余额港币
                            CPTL_BAL_USD,	        --资金余额美元 
                            HGT_MVAL,	            --沪港通市值
                            SGT_MVAL,	            --深港通市值
                            PSTK_OPTN_MVAL,	        --个股期权市值
                            IMGT_PD_MVAL,	        --资管产品市值
                            BANK_CHRM_MVAL,	        --银行理财市值
                            SECU_CHRM_MVAL,         --证券理财市值 
                            --FUND_SPACCT_MVAL,     --基金专户市值
                            STKT_FUND_MVAL,         --股票型基金市值
                            --STKPLG_LIAB,            --股票质押负债
                            LOAD_DT)
    select rq
       ,client_id
       ,fund_account
       ,zzc         --- 包括：资金余额、未到账资金、二级市值、开基市值、资管产品市值、融资融券净资产、约定购回净资产、 银行理财持有金额、证券理财产品额 
       ,zzc_20rj    --- 20日均总资产：工作日
       ,ejsz
       ,wdzzj
       ,zjye
       ,zjye_rmb
       ,zjye_gb
       ,zjye_my
       ,hgtsz_rmb   ---沪港通市值
       ,sgtsz_rmb   ---深港通市值
       ,qqsz        ---期权市值
       ,zgcpsz      ---资管产品市值
       ,yhlccyje    ---银行理财持有金额
       ,zqlccpe     ---证券理财产品额 
       --,jjzhsz    ---基金专户市值
       ,gjsz        ---股票型基金市值
       ,rq as load_dt
    from dba.t_ddw_client_index_high_priority
    where rq=@v_bin_date
     and jgbh_hs not in  ('5','55','51','44','9999');  ---modify by rengz 20180212 剔除总部客户
  commit;

------------------------
  -- 体外市值
------------------------

        select a.zjzh,
               case when a.yrdh_flag = '0' then 1
                    when a.yrdh_flag = '1' and a.tn_sz > 0 then a.bzjzh_tn_sz / a.tn_sz else 1 / b.cnt
               end                      as tn_sz_fencheng,
               tw_sz * tn_sz_fencheng   as tw_zc_20avg,----体外资产
               d.avg_zzc_20d            as tn_zc_20avg ----体内资产
          into #t_twzc
          from dba.t_index_assetinfo_v2 a
        -- 一人多户处理
          left join (select id_no, count(distinct zjzh) as cnt
                       from dba.t_index_assetinfo_v2
                      where init_date = @v_bin_date
                        and yrdh_flag = '1'
                      group by id_no) b --init_date         --update
            on a.id_no = b.id_no
        -- 体内20日均总资产计算 （总资产未修正）
          left join (select zjzh, sum(zzc) / 20         as avg_zzc_20d
                       from dba.tmp_ddw_khqjt_d_d
                      where rq >= @v_bin_20avg_start
                        and rq <= @v_bin_20avg_end
                      group by zjzh) d
            on a.zjzh = d.zjzh
         where a.init_date = @v_bin_date;
      
      commit;

    update dm.t_ast_odi 
       set OUTMARK_MVAL = coalesce(tw_zc_20avg, 0) 
    from dm.t_ast_odi  a 
    left join #t_twzc  b on a.main_cptl_acct = b.zjzh  
     where 
           a.occur_dt  = @v_bin_date;
    commit;

------------------------
  -- 股基市值 三板市值 A股期末市值 B股期末市值 私募基金市值
------------------------
  select 
       zjzh
       ,sum(case when zqfz1dm='11' and b.sclx in ('01','02') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agsz     ---A股期末市值
	   ,sum(case when zqfz1dm='12' and b.sclx in ('03','04') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bgsz     ---B股期末市值 
       ,sum(case when a.zqlx in ('10', 'A1', -- A股      包含 深港通、沪港通、三板
                                 '17', '18', -- B股
                                 '11',       -- 封闭式基金
                                 '1A',       -- ETF
                                 '74', '75', -- 权证
                                 '19'        -- LOF --含场内开基
                                ) then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                   as gjsz            ---股基市值

       ,sum(case when zqfz1dm='11'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agqmsz          ---A股期末市值_私财 包含 深港通、沪港通 
       ,sum(case when zqfz1dm in('20','22')then JRCCSZ*c.turn_rmb/turn_rate else 0  end )        as sbsz            ---三板市值
       ,sum(case when zqfz1dm='14'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as fbsjjqmsz       ---封闭式基金期末市值_私财  
       ,sum(case when zqfz1dm='18'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as etfqmsz         ---ETF期末市值_私财 
       ,sum(case when zqfz1dm='19'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as lofqmsz         ---LOF期末市值_私财 
       ,sum(case when zqfz1dm='25'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as cnkjqmsz        ---场内开基期末市值_私财 
       ,sum(case when zqfz1dm='30'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bzqqmsz         ---标准券期末市值_私财 
       ,sum(case when zqfz1dm='21'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as hgqmsz          ---回购期末市值_私财 
  into #t_sz
  from dba.T_DDW_F00_KHMRCPYKHZ_D                     a
  left join dba.T_DDW_D_ZQFZ                          b on a.zqlx=b.zqlx AND a.sclx=b.sclx
  left join  dba.T_EDW_T06_YEAR_EXCHANGE_RATE         c on a.tjrq between c.star_dt and c.end_dt 
                                                       and c.curr_type_cd = case
                                                                            when a.zqlx = '18' and a.sclx = '05' then  'USD'
                                                                            when a.zqlx = '17'                   then 'USD'
                                                                            when a.zqlx = '18'                   then  'HKD'
                                                                            else  'CNY'
                                                                            end
  left join dba.t_ddw_d_jj                            d on a.zqdm=d.jjdm and d.nian=@v_bin_year and d.yue=@v_bin_mth
  where a.load_dt= @v_bin_date
    and a.sclx in( '01','02','03','04','05','0G','0S')
  group by zjzh; 

  commit;


  update dm.t_ast_odi 
       set  
           STKF_MVAL     = coalesce(gjsz, 0), --股基市值 
           SB_MVAL       = coalesce(sbsz, 0), --三板市值 
           A_SHR_MVAL    = coalesce(agsz, 0), --A股市值
           B_SHR_MVAL    = coalesce(bgsz, 0)  --B股市值
    from dm.t_ast_odi a
    left join   #t_sz b on a.main_cptl_acct = b.zjzh
     where  a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- 公募基金、私募基金市值
------------------------
    select a.zjzh
          ,SUM(case when b.lx = '公募-货币型' then a.qmsz_cw_d else 0 end)                                                                          as hjsz         -- 货基市值
          ,SUM(case when b.lx in( '公募-股票型','未设置') or b.lx is null then a.qmsz_cw_d else 0 end)                                              as gjsz         -- 股基市值(包含未定义)
          ,SUM(case when b.lx = '公募-债券型' then a.qmsz_cw_d else 0 end)                                                                          as zjsz         -- 债基市值
          ,SUM(case when b.lx in ('基金专户-股票型','基金专户-债券型')  then a.qmsz_cw_d else 0 end)                                                as jjzhsz       -- 基金专户市值
          ,SUM(case when b.lx in( '公募-股票型','公募-债券型','公募-货币型','基金专户','未设置') or b.lx is null then a.qmsz_cw_d else 0 end)       as kjsz         -- 开基市值(不含资管产品市值)
          ,SUM(case when b.lx in( '集合理财-股票型','集合理财-债券型','集合理财-货币型') then a.qmsz_cw_d else 0 end)                               as zgcpsz       -- 资管产品市值
          ,SUM(case when b.lx in( '集合理财-债券型','集合理财-货币型') then a.qmsz_cw_d else 0 end)                                                 as gdsylzgcpsz  -- 固定收益类资管产品市值
          ,SUM(case when b.lx in( '公募-股票型','公募-债券型','公募-货币型') then a.qmsz_cw_d else 0 end)                                           as gmsz         -- 公募基金市值
          ,SUM(case when b.lx in( '私募-股票型','私募-债券型') then a.qmsz_cw_d else 0 end)                                                         as smsz         -- 私募基金市值 
          ,SUM(case when b.lx ='未设置' or b.lx is null  then a.qmsz_cw_d else 0 end)                                                               as qtcpsz       -- 其他产品市值 
          ,SUM(case when b.lx in( '公募-货币型') then a.qmsz_cn_d else 0 end)                                                                       as cnhbxjjsz    -- 场内货币型基金市值_期末   
          ,SUM(a.qmsz_cw_d)                                                                                                                         as cwjjsz       -- 场外基金总市值
    into #t_sz_jj   
    --select *
      from dba.t_ddw_xy_jjzb_d as a
      left outer join (select jjdm, jjlb as lx                           -----与客户全景图略有差异，全景图直接使用lx字段，基金实际包括了私募基金
                         from dba.t_ddw_d_jj
                        where nian || yue =
                              (select MAX(nian || yue)
                                 from dba.t_ddw_d_jj
                                where nian || yue <
                                      convert(varchar(6), FLOOR(@v_bin_date / 100)))) as b
        on a.jjdm = b.jjdm
     where a.rq = @v_bin_date
     group by a.zjzh;

  commit;

 
  update dm.t_ast_odi  
       set 
           PTE_FUND_MVAL = coalesce(smsz, 0),               --私募基金市值
           PO_FUND_MVAL  = coalesce(gmsz, 0),               --公募基金市值 
           FUND_SPACCT_MVAL = coalesce(jjzhsz, 0),          --基金专户市值
           OTH_PROD_MVAL    = coalesce(qtcpsz, 0),          --其他产品市值                                 
           PROD_TOT_MVAL    = coalesce(cwjjsz, 0) + BANK_CHRM_MVAL+	        --银行理财市值
                                                  SECU_CHRM_MVAL            --证券理财市值      
                                                            --产品总市值      
    from       dm.t_ast_odi a
    left join  #t_sz_jj     b on a.main_cptl_acct = b.zjzh
     where 
        a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- 限售股市值
------------------------
     select b.fund_acct as zjzh,
           SUM(a.sec_bal * COALESCE(c.trad_price, 0)) as xsgsz
      into #t_xsgsz
      from dba.t_edw_tr_sec_bal_xslt as a
      left outer join dba.t_edw_t01_stock_acct as b on a.inv_acc = b.stock_acct and a.mkt_code = b.market_type_cd and b.market_type_cd <> '05'
      left outer join dba.t_edw_t06_stock_maket_info as c on a.load_dt = c.trad_dt and a.mkt_code = c.market_type_cd and a.sec_code = c.stock_cd and c.stock_type_cd not in ('19', '12')
     where a.load_dt = @v_bin_date
     group by b.fund_acct;

    commit;   

    update dm.t_ast_odi  
       set NOTS_MVAL = coalesce(xsgsz, 0)                --限售股市值
    from dm.t_ast_odi  a
    left join #t_xsgsz b on convert(varchar,a.main_cptl_acct) = convert(varchar,b.zjzh)
     where  a.occur_dt = @v_bin_date;

    commit;
    ------------------------
    -- 总资产 含限售股
    ------------------------
    update dm.t_ast_odi a
       set TOT_AST_CONTAIN_NOTS = coalesce(TOT_AST_N_CONTAIN_NOTS, 0) +
                                  coalesce(NOTS_MVAL, 0) ---总资产_含限售股
     where a.occur_dt = @v_bin_date;
    commit;

    ------------------------
    -- 场内 场外基金市值
    ------------------------
    select zjzh
           ,sum(qmsz_cw_d) as cwsz ---场外基金市值
           ,sum(qmsz_cn_d) as cnsz ---场内基金市值
      into #t_jjsz
      from dba.t_ddw_xy_jjzb_d a
     where rq = @v_bin_date
    group by zjzh;

    update dm.t_ast_odi a
       set OFFUND_MVAL = coalesce(cnsz, 0), --场内基金市值
           OPFUND_MVAL = coalesce(cwsz, 0)  --场外基金市值
    from dm.t_ast_odi a
    left join #t_jjsz b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;
------------------------
  -- 低风险资产
------------------------
-- 低风险资产总计 = 货基市值 + 债基市值 + 资金余额 + 报价回购市值 + 债券逆回购市值 
--                    + 固定收益类资管产品市值 + 国债市值 + 企业债市值 + 可转债市值

    select a.fund_Account as zjzh,
           coalesce(a.hjsz, 0) + coalesce(a.zjsz, 0) + coalesce(a.zjye, 0) +
           coalesce(b.bjhgsz, 0) + coalesce(c.zqnhgsz, 0) +
           coalesce(a.gdsylzgcpsz, 0) + coalesce(d.gzsz, 0) +
           coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0)                       as dfxzczj,
           coalesce(d.gzsz, 0) + coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0) as zqsz,
           coalesce(b.bjhgsz,0)                                              as bjhgsz,
           coalesce(c.zqnhgsz,0)                                             as zqnhgsz
      into #t_dfxzc
      from dba.t_ddw_client_index_high_priority a
      left join (select zjzh, cyje_br as bjhgsz       -- 报价回购市值
                   from dba.t_ddw_bjhg_d
                  where rq = @v_bin_date) b
        on a.fund_Account = b.zjzh
      left join (select zjzh, SUM(jrccsz) as zqnhgsz -- 债券逆回购市值
                   from dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx = '27'
                    and zqdm not like '205%'         -- 剔除报价回购
                  group by zjzh) c
        on a.fund_Account = c.zjzh
      left join (select zjzh,
                        SUM(case when zqlx = '12' then jrccsz else 0 end) as gzsz,  -- 国债市值  
                        SUM(case when zqlx = '13' then jrccsz else 0 end) as qyzsz, -- 企业债市值
                        SUM(case when zqlx = '14' then jrccsz else 0 end) as kzzsz  -- 可转债市值
                   from  dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx in ('12', '13', '14')
                  group by zjzh) d
        on a.fund_Account = d.zjzh
     where a.rq = @v_bin_date;

    update dm.t_ast_odi 
       set LOW_RISK_TOT_AST= coalesce(dfxzczj, 0),                      ---  低风险资产
           OVERSEA_TOT_AST = 0,                                         ---  海外总资产
           FUTR_TOT_AST    = 0,                                         ---  期货总资产
           BOND_MVAL       =coalesce(b.zqsz,0),                         ---  债券市值
           REPO_MVAL       =coalesce(b.bjhgsz,0)+coalesce(b.zqnhgsz,0), ---  回购市值
           TREA_REPO_MVAL  =coalesce(b.zqnhgsz,0),                      ---  国债回购市值
           REPQ_MVAL       =coalesce(b.bjhgsz,0)                        ---  报价回购市值
    from dm.t_ast_odi   a  
    left join  #t_dfxzc b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
    ------------------------
    -- 经纪业务部需求：股票质押负债
    ------------------------

    update dm.t_ast_odi 
       set STKPLG_LIAB= coalesce(fz, 0)                       ---  股票质押负债 
    from dm.t_ast_odi            a  
    left join dba.t_ddw_gpzyhg_d b on a.main_cptl_acct = b.zjzh and b.rq=a.occur_dt
     where 
         a.occur_dt = @v_bin_date;

    commit;

 
    ------------------------
    -- 经纪业务部需求：增加约定购回质押资产市值
    ------------------------

    select a.client_id,
           sum(a.entrust_amount * b.trad_price )        as 质押资产_期末_原始 ----  约定购回质押市值
    into #t_arpsz
      from dba.t_edw_arpcontract               a
      left join dba.t_edw_t06_stock_maket_info b
        on a.stock_code = b.stock_cd and '0' || a.exchange_type = b.market_type_cd and a.load_dt = b.trad_dt and b.stock_type_cd in ('10', 'A1')
     where a.load_dt = @v_bin_date
       and a.contract_status in ('2', '3', '7') -- 2-已签约, 3-已进行初始交易, 7 -已购回
     group by a.client_id;
   
    commit;
 
    update dm.t_ast_odi 
       set APPTBUYB_PLG_MVAL = coalesce(质押资产_期末_原始, 0) --约定购回质押市值
    from dm.t_ast_odi a
    left join #t_arpsz b on a.cust_id = b.client_id
     where 
         a.occur_dt = @v_bin_date;

    commit;
    
    ------------------------
    -- 经纪业务部需求：增加其他资产市值
    ------------------------

  update dm.t_ast_odi 
       set   OTH_AST_MVAL =  
                        coalesce(b.zzc,0)                                --- 仓库全景图总资产
                        + coalesce(b.rzrqzfz,0)                          --- 融资融券总负债
                        + coalesce(b.ydghfz,0)                           --- 约定购回负债
                        - coalesce(STKF_MVAL,0)                          --- 股基市值
                        - coalesce(CPTL_BAL ,0)                          --- 保证金/资金余额
                        - coalesce(BOND_MVAL,0)                          --- 债券市值
                        - (coalesce(c.bzqqmsz,0)+ coalesce(c.hgqmsz,0))  --- 回购市值--私财 标准券市值
                        - coalesce(PROD_TOT_MVAL,0)                      --- 产品总市值
                        - coalesce(APPTBUYB_PLG_MVAL,0)                  --- 约定购回质押市值
                        - coalesce(b.rzrqzzc,0)                          --- 两融账户总资产
                        - coalesce(NO_ARVD_CPTL,0) 	                     --- 未到账资金
    from dm.t_ast_odi   a
    left join dba.t_ddw_client_index_high_priority b on a.main_cptl_acct = b.fund_account and b.rq=a.occur_dt
    left join #t_sz                                c on a.main_cptl_acct = c.zjzh
     where 
         a.occur_dt = @v_bin_date;
    commit;
 

 ------------------------
    -- 经纪业务部需求：期末资产，即为经纪业务总部要求的总资产=股基市值+资金余额+债券市值+回购市值+产品总市值+其他资产+未到账资金+股票质押负债+融资融券总资产+约定购回质押市值+限售股市值+个股期权市值。
 ------------------------

    update dm.t_ast_odi
       set FINAL_AST = coalesce(STKF_MVAL, 0)           --股基市值
                       + coalesce(CPTL_BAL, 0)          --资金余额
                       + coalesce(BOND_MVAL, 0)         --债券市值
                       + coalesce(REPO_MVAL, 0)         --回购市值
                       + coalesce(PROD_TOT_MVAL, 0)     --产品总市值
                       + coalesce(OTH_AST_MVAL, 0)      --其他资产 
                       + coalesce(NO_ARVD_CPTL, 0)      --未到账资金 
                       + coalesce(STKPLG_LIAB, 0)       --股票质押负债 
                       + coalesce(b.rzrqzzc, 0)         --融资融券总资产    
                       + coalesce(APPTBUYB_PLG_MVAL, 0) --约定购回质押市值
                       + coalesce(NOTS_MVAL, 0)         --限售股市值 
                       + coalesce(PSTK_OPTN_MVAL, 0)    --个股期权市值 
    from dm.t_ast_odi a 
    left join dba.t_ddw_client_index_high_priority b on a.main_cptl_acct = b.fund_account and a.occur_dt = b.rq
     where a.occur_dt = @v_bin_date;

    commit;


 ------------------------
    -- 经纪业务部需求：净资产=期末资产（总资产）-融资融券总负债-股票质押负债-约定购回负债。这里的两融总负债要算所有类型的融资融券负债
 ------------------------

  update dm.t_ast_odi
     set NET_AST = FINAL_AST                    --期末资产/经纪业务口径总资产
                   - (COALESCE(FIN_CLOSE_BALANCE, 0)       +COALESCE(SLO_CLOSE_BALANCE, 0)       + COALESCE(FARE_CLOSE_DEBIT, 0)         + COALESCE(OTHER_CLOSE_DEBIT, 0) +
                      COALESCE(FIN_CLOSE_INTEREST, 0)      +COALESCE(SLO_CLOSE_INTEREST, 0)      +COALESCE(FARE_CLOSE_INTEREST, 0)       +COALESCE(OTHER_CLOSE_INTEREST, 0) +
                      COALESCE(FIN_CLOSE_FINE_INTEREST, 0) +COALESCE(SLO_CLOSE_FINE_INTEREST, 0) +COALESCE(OTHER_CLOSE_FINE_INTEREST, 0) +COALESCE(REFCOST_CLOSE_FARE, 0)) --融资融券总负债:融资负债、融券负债、费用负债、其他负债、利息负债、罚息负债
                   - coalesce(STKPLG_LIAB, 0)  --股票质押负债  
                   - coalesce(b.ydghfz, 0)     --约定购回负债
  from dm.t_ast_odi a 
  left join dba.t_ddw_client_index_high_priority b on a.main_cptl_acct = b.fund_account and a.occur_dt = b.rq
  left join DBA.T_EDW_UF2_RZRQ_ASSETDEBIT        c on a.cust_id = c.client_id           and a.occur_dt = c.load_dt
   where a.occur_dt = @v_bin_date;
  
  commit;

  set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 
         
   end
GO
GRANT EXECUTE ON dm.p_ast_odi TO query_dev
GO
GRANT EXECUTE ON dm.p_ast_odi TO xydc
GO
CREATE PROCEDURE dm.P_AST_ODI_M_D(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建客户普通资产月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：客户普通资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  
             20180201                   dcy               新增总资产、股票型基金市值、产品总市值、其他产品市值、其他资产市值、约定购回质押市值六个基础表的衍生指标
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --自然日_月末
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --交易日_月初
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --交易日_月末
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --交易日_年初
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --自然天数_月
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --交易天数_月
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --自然天数_年
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --交易天数_年


    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT)	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 删除当月数据
  DELETE FROM DM.T_AST_ODI_M_D WHERE YEAR=@V_BIN_YEAR AND MTH= @V_BIN_MTH;

	insert into DM.T_AST_ODI_M_D
	(
	 CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,SCDY_MVAL_FINAL
	,STKF_MVAL_FINAL
	,A_SHR_MVAL_FINAL
	,NOTS_MVAL_FINAL
	,OFFUND_MVAL_FINAL
	,OPFUND_MVAL_FINAL
	,SB_MVAL_FINAL
	,IMGT_PD_MVAL_FINAL
	,BANK_CHRM_MVAL_FINAL
	,SECU_CHRM_MVAL_FINAL
	,PSTK_OPTN_MVAL_FINAL
	,B_SHR_MVAL_FINAL
	,OUTMARK_MVAL_FINAL
	,CPTL_BAL_FINAL
	,NO_ARVD_CPTL_FINAL
	,PO_FUND_MVAL_FINAL
	,PTE_FUND_MVAL_FINAL
	,OVERSEA_TOT_AST_FINAL
	,FUTR_TOT_AST_FINAL
	,CPTL_BAL_RMB_FINAL
	,CPTL_BAL_HKD_FINAL
	,CPTL_BAL_USD_FINAL
	,LOW_RISK_TOT_AST_FINAL
	,FUND_SPACCT_MVAL_FINAL
	,HGT_MVAL_FINAL
	,SGT_MVAL_FINAL
	,NET_AST_FINAL
	,TOT_AST_CONTAIN_NOTS_FINAL
	,TOT_AST_N_CONTAIN_NOTS_FINAL
	,BOND_MVAL_FINAL
	,REPO_MVAL_FINAL
	,TREA_REPO_MVAL_FINAL
	,REPQ_MVAL_FINAL
	,TOT_AST_FINAL
	,STKT_FUND_MVAL_FINAL
	,PROD_TOT_MVAL_FINAL
	,OTH_PROD_MVAL_FINAL
	,OTH_AST_MVAL_FINAL
	,APPTBUYB_PLG_MVAL_FINAL
	,SCDY_MVAL_MDA
	,STKF_MVAL_MDA
	,A_SHR_MVAL_MDA
	,NOTS_MVAL_MDA
	,OFFUND_MVAL_MDA
	,OPFUND_MVAL_MDA
	,SB_MVAL_MDA
	,IMGT_PD_MVAL_MDA
	,BANK_CHRM_MVAL_MDA
	,SECU_CHRM_MVAL_MDA
	,PSTK_OPTN_MVAL_MDA
	,B_SHR_MVAL_MDA
	,OUTMARK_MVAL_MDA
	,CPTL_BAL_MDA
	,NO_ARVD_CPTL_MDA
	,PO_FUND_MVAL_MDA
	,PTE_FUND_MVAL_MDA
	,OVERSEA_TOT_AST_MDA
	,FUTR_TOT_AST_MDA
	,CPTL_BAL_RMB_MDA
	,CPTL_BAL_HKD_MDA
	,CPTL_BAL_USD_MDA
	,LOW_RISK_TOT_AST_MDA
	,FUND_SPACCT_MVAL_MDA
	,HGT_MVAL_MDA
	,SGT_MVAL_MDA
	,NET_AST_MDA
	,TOT_AST_CONTAIN_NOTS_MDA
	,TOT_AST_N_CONTAIN_NOTS_MDA
	,BOND_MVAL_MDA
	,REPO_MVAL_MDA
	,TREA_REPO_MVAL_MDA
	,REPQ_MVAL_MDA
	,TOT_AST_MDA
	,STKT_FUND_MVAL_MDA
	,PROD_TOT_MVAL_MDA
	,OTH_PROD_MVAL_MDA
	,OTH_AST_MVAL_MDA
	,APPTBUYB_PLG_MVAL_MDA
	,SCDY_MVAL_YDA
	,STKF_MVAL_YDA
	,A_SHR_MVAL_YDA
	,NOTS_MVAL_YDA
	,OFFUND_MVAL_YDA
	,OPFUND_MVAL_YDA
	,SB_MVAL_YDA
	,IMGT_PD_MVAL_YDA
	,BANK_CHRM_MVAL_YDA
	,SECU_CHRM_MVAL_YDA
	,PSTK_OPTN_MVAL_YDA
	,B_SHR_MVAL_YDA
	,OUTMARK_MVAL_YDA
	,CPTL_BAL_YDA
	,NO_ARVD_CPTL_YDA
	,PO_FUND_MVAL_YDA
	,PTE_FUND_MVAL_YDA
	,OVERSEA_TOT_AST_YDA
	,FUTR_TOT_AST_YDA
	,CPTL_BAL_RMB_YDA
	,CPTL_BAL_HKD_YDA
	,CPTL_BAL_USD_YDA
	,LOW_RISK_TOT_AST_YDA
	,FUND_SPACCT_MVAL_YDA
	,HGT_MVAL_YDA
	,SGT_MVAL_YDA
	,NET_AST_YDA
	,TOT_AST_CONTAIN_NOTS_YDA
	,TOT_AST_N_CONTAIN_NOTS_YDA
	,BOND_MVAL_YDA
	,REPO_MVAL_YDA
	,TREA_REPO_MVAL_YDA
	,REPQ_MVAL_YDA
	,TOT_AST_YDA
	,STKT_FUND_MVAL_YDA
	,PROD_TOT_MVAL_YDA
	,OTH_PROD_MVAL_YDA
	,OTH_AST_MVAL_YDA
	,APPTBUYB_PLG_MVAL_YDA
	,LOAD_DT
	)
select
	t1.CUST_ID as 客户编码
	,@V_BIN_DATE AS OCCUR_DT
	,t_rq.年
	,t_rq.月	
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编号
	
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SCDY_MVAL,0) else 0 end) as 二级市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.STKF_MVAL,0) else 0 end) as 股基市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.A_SHR_MVAL,0) else 0 end) as A股市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.NOTS_MVAL,0) else 0 end) as 限售股市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OFFUND_MVAL,0) else 0 end) as 场内基金市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OPFUND_MVAL,0) else 0 end) as 场外基金市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SB_MVAL,0) else 0 end) as 三板市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.IMGT_PD_MVAL,0) else 0 end) as 资管产品市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.BANK_CHRM_MVAL,0) else 0 end) as 银行理财市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SECU_CHRM_MVAL,0) else 0 end) as 证券理财市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.PSTK_OPTN_MVAL,0) else 0 end) as 个股期权市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.B_SHR_MVAL,0) else 0 end) as B股市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OUTMARK_MVAL,0) else 0 end) as 体外市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CPTL_BAL,0) else 0 end) as 资金余额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.NO_ARVD_CPTL,0) else 0 end) as 未到账资金_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.PO_FUND_MVAL,0) else 0 end) as 公募基金市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.PTE_FUND_MVAL,0) else 0 end) as 私募基金市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OVERSEA_TOT_AST,0) else 0 end) as 海外总资产_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.FUTR_TOT_AST,0) else 0 end) as 期货总资产_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CPTL_BAL_RMB,0) else 0 end) as 资金余额人民币_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CPTL_BAL_HKD,0) else 0 end) as 资金余额港币_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CPTL_BAL_USD,0) else 0 end) as 资金余额美元_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.LOW_RISK_TOT_AST,0) else 0 end) as 低风险总资产_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.FUND_SPACCT_MVAL,0) else 0 end) as 基金专户市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.HGT_MVAL,0) else 0 end) as 沪港通市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SGT_MVAL,0) else 0 end) as 深港通市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.NET_AST,0) else 0 end) as 净资产_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.TOT_AST_CONTAIN_NOTS,0) else 0 end) as 总资产_含限售股_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.TOT_AST_N_CONTAIN_NOTS,0) else 0 end) as 总资产_不含限售股_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.BOND_MVAL,0) else 0 end) as 债券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.REPO_MVAL,0) else 0 end) as 回购市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.TREA_REPO_MVAL,0) else 0 end) as 国债回购市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.REPQ_MVAL,0) else 0 end) as 报价回购市值_期末

	--20180201新增
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.FINAL_AST,0) else 0 end) as 总资产_期末        
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.STKT_FUND_MVAL,0) else 0 end) as 股票型基金市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.PROD_TOT_MVAL,0) else 0 end) as 产品总市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTH_PROD_MVAL,0) else 0 end) as 其他产品市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTH_AST_MVAL,0) else 0 end) as 其他资产市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.APPTBUYB_PLG_MVAL,0) else 0 end) as 约定购回质押市值_期末
	
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SCDY_MVAL,0) else 0 end)/t_rq.自然天数_月 as 二级市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKF_MVAL,0) else 0 end)/t_rq.自然天数_月 as 股基市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.A_SHR_MVAL,0) else 0 end)/t_rq.自然天数_月 as A股市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.NOTS_MVAL,0) else 0 end)/t_rq.自然天数_月 as 限售股市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OFFUND_MVAL,0) else 0 end)/t_rq.自然天数_月 as 场内基金市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OPFUND_MVAL,0) else 0 end)/t_rq.自然天数_月 as 场外基金市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SB_MVAL,0) else 0 end)/t_rq.自然天数_月 as 三板市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.IMGT_PD_MVAL,0) else 0 end)/t_rq.自然天数_月 as 资管产品市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.BANK_CHRM_MVAL,0) else 0 end)/t_rq.自然天数_月 as 银行理财市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SECU_CHRM_MVAL,0) else 0 end)/t_rq.自然天数_月 as 证券理财市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PSTK_OPTN_MVAL,0) else 0 end)/t_rq.自然天数_月 as 个股期权市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.B_SHR_MVAL,0) else 0 end)/t_rq.自然天数_月 as B股市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OUTMARK_MVAL,0) else 0 end)/t_rq.自然天数_月 as 体外市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CPTL_BAL,0) else 0 end)/t_rq.自然天数_月 as 资金余额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.NO_ARVD_CPTL,0) else 0 end)/t_rq.自然天数_月 as 未到账资金_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PO_FUND_MVAL,0) else 0 end)/t_rq.自然天数_月 as 公募基金市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PTE_FUND_MVAL,0) else 0 end)/t_rq.自然天数_月 as 私募基金市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OVERSEA_TOT_AST,0) else 0 end)/t_rq.自然天数_月 as 海外总资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FUTR_TOT_AST,0) else 0 end)/t_rq.自然天数_月 as 期货总资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CPTL_BAL_RMB,0) else 0 end)/t_rq.自然天数_月 as 资金余额人民币_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CPTL_BAL_HKD,0) else 0 end)/t_rq.自然天数_月 as 资金余额港币_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CPTL_BAL_USD,0) else 0 end)/t_rq.自然天数_月 as 资金余额美元_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.LOW_RISK_TOT_AST,0) else 0 end)/t_rq.自然天数_月 as 低风险总资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FUND_SPACCT_MVAL,0) else 0 end)/t_rq.自然天数_月 as 基金专户市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.HGT_MVAL,0) else 0 end)/t_rq.自然天数_月 as 沪港通市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SGT_MVAL,0) else 0 end)/t_rq.自然天数_月 as 深港通市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.NET_AST,0) else 0 end)/t_rq.自然天数_月 as 净资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.TOT_AST_CONTAIN_NOTS,0) else 0 end)/t_rq.自然天数_月 as 总资产_含限售股_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.TOT_AST_N_CONTAIN_NOTS,0) else 0 end)/t_rq.自然天数_月 as 总资产_不含限售股_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.BOND_MVAL,0) else 0 end)/t_rq.自然天数_月 as 债券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.REPO_MVAL,0) else 0 end)/t_rq.自然天数_月 as 回购市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.TREA_REPO_MVAL,0) else 0 end)/t_rq.自然天数_月 as 国债回购市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.REPQ_MVAL,0) else 0 end)/t_rq.自然天数_月 as 报价回购市值_月日均
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FINAL_AST,0) else 0 end)/t_rq.自然天数_月 as 总资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKT_FUND_MVAL,0) else 0 end)/t_rq.自然天数_月 as 股票型基金市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PROD_TOT_MVAL,0) else 0 end)/t_rq.自然天数_月 as 产品总市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTH_PROD_MVAL,0) else 0 end)/t_rq.自然天数_月 as 其他产品市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTH_AST_MVAL,0) else 0 end)/t_rq.自然天数_月 as 其他资产市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_PLG_MVAL,0) else 0 end)/t_rq.自然天数_月 as 约定购回质押市值_月日均

	,sum(COALESCE(t1.SCDY_MVAL,0))/t_rq.自然天数_年 as 二级市值_年日均
	,sum(COALESCE(t1.STKF_MVAL,0))/t_rq.自然天数_年 as 股基市值_年日均
	,sum(COALESCE(t1.A_SHR_MVAL,0))/t_rq.自然天数_年 as A股市值_年日均
	,sum(COALESCE(t1.NOTS_MVAL,0))/t_rq.自然天数_年 as 限售股市值_年日均
	,sum(COALESCE(t1.OFFUND_MVAL,0))/t_rq.自然天数_年 as 场内基金市值_年日均
	,sum(COALESCE(t1.OPFUND_MVAL,0))/t_rq.自然天数_年 as 场外基金市值_年日均
	,sum(COALESCE(t1.SB_MVAL,0))/t_rq.自然天数_年 as 三板市值_年日均
	,sum(COALESCE(t1.IMGT_PD_MVAL,0))/t_rq.自然天数_年 as 资管产品市值_年日均
	,sum(COALESCE(t1.BANK_CHRM_MVAL,0))/t_rq.自然天数_年 as 银行理财市值_年日均
	,sum(COALESCE(t1.SECU_CHRM_MVAL,0))/t_rq.自然天数_年 as 证券理财市值_年日均
	,sum(COALESCE(t1.PSTK_OPTN_MVAL,0))/t_rq.自然天数_年 as 个股期权市值_年日均
	,sum(COALESCE(t1.B_SHR_MVAL,0))/t_rq.自然天数_年 as B股市值_年日均
	,sum(COALESCE(t1.OUTMARK_MVAL,0))/t_rq.自然天数_年 as 体外市值_年日均
	,sum(COALESCE(t1.CPTL_BAL,0))/t_rq.自然天数_年 as 资金余额_年日均
	,sum(COALESCE(t1.NO_ARVD_CPTL,0))/t_rq.自然天数_年 as 未到账资金_年日均
	,sum(COALESCE(t1.PO_FUND_MVAL,0))/t_rq.自然天数_年 as 公募基金市值_年日均
	,sum(COALESCE(t1.PTE_FUND_MVAL,0))/t_rq.自然天数_年 as 私募基金市值_年日均
	,sum(COALESCE(t1.OVERSEA_TOT_AST,0))/t_rq.自然天数_年 as 海外总资产_年日均
	,sum(COALESCE(t1.FUTR_TOT_AST,0))/t_rq.自然天数_年 as 期货总资产_年日均
	,sum(COALESCE(t1.CPTL_BAL_RMB,0))/t_rq.自然天数_年 as 资金余额人民币_年日均
	,sum(COALESCE(t1.CPTL_BAL_HKD,0))/t_rq.自然天数_年 as 资金余额港币_年日均
	,sum(COALESCE(t1.CPTL_BAL_USD,0))/t_rq.自然天数_年 as 资金余额美元_年日均
	,sum(COALESCE(t1.LOW_RISK_TOT_AST,0))/t_rq.自然天数_年 as 低风险总资产_年日均
	,sum(COALESCE(t1.FUND_SPACCT_MVAL,0))/t_rq.自然天数_年 as 基金专户市值_年日均
	,sum(COALESCE(t1.HGT_MVAL,0))/t_rq.自然天数_年 as 沪港通市值_年日均
	,sum(COALESCE(t1.SGT_MVAL,0))/t_rq.自然天数_年 as 深港通市值_年日均		
	,sum(COALESCE(t1.NET_AST,0))/t_rq.自然天数_年 as 净资产_年日均
	,sum(COALESCE(t1.TOT_AST_CONTAIN_NOTS,0))/t_rq.自然天数_年 as 总资产_含限售股_年日均
	,sum(COALESCE(t1.TOT_AST_N_CONTAIN_NOTS,0))/t_rq.自然天数_年 as 总资产_不含限售股_年日均		
	,sum(COALESCE(t1.BOND_MVAL,0))/t_rq.自然天数_年 as 债券市值_年日均
	,sum(COALESCE(t1.REPO_MVAL,0))/t_rq.自然天数_年 as 回购市值_年日均
	,sum(COALESCE(t1.TREA_REPO_MVAL,0))/t_rq.自然天数_年 as 国债回购市值_年日均
	,sum(COALESCE(t1.REPQ_MVAL,0))/t_rq.自然天数_年 as 报价回购市值_年日均
	
	,sum(COALESCE(t1.FINAL_AST,0))/t_rq.自然天数_年 as 总资产_年日均
	,sum(COALESCE(t1.STKT_FUND_MVAL,0))/t_rq.自然天数_年 as 股票型基金市值_年日均
	,sum(COALESCE(t1.PROD_TOT_MVAL,0))/t_rq.自然天数_年 as 产品总市值_年日均
	,sum(COALESCE(t1.OTH_PROD_MVAL,0))/t_rq.自然天数_年 as 其他产品市值_年日均
	,sum(COALESCE(t1.OTH_AST_MVAL,0))/t_rq.自然天数_年 as 其他资产市值_年日均
	,sum(COALESCE(t1.APPTBUYB_PLG_MVAL,0))/t_rq.自然天数_年 as 约定购回质押市值_年日均
	
    ,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as 年
		,@V_BIN_MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,@V_BIN_NATRE_DAY_MTHBEG    as 自然日_月初
		,@V_BIN_NATRE_DAY_MTHEND    as 自然日_月末
		,@V_BIN_TRD_DAY_MTHBEG      as 交易日_月初
		,@V_BIN_TRD_DAY_MTHEND      as 交易日_月末
		,@V_BIN_NATRE_DAY_YEARBGN   as 自然日_年初
		,@V_BIN_TRD_DAY_YEARBGN     as 交易日_年初
		,@V_BIN_NATRE_DAYS_MTH      as 自然天数_月
		,@V_BIN_TRD_DAYS_MTH        as 交易天数_月
		,@V_BIN_NATRE_DAYS_YEAR     as 自然天数_年
		,@V_BIN_TRD_DAYS_YEAR       as 交易天数_年
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
left join DM.T_AST_ODI t1 on t_rq.交易日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t1.CUST_ID

;

END
GO
CREATE PROCEDURE dm.p_ast_sec_acct_hld(IN @V_BIN_DATE VARCHAR(10),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能: 证券账户持有表
  编写者: rengz
  创建日期: 2017-11-22
  简介：客户持有的证券数据，日更新
        存储过程主要参考dba.t_edw_t05_sec_bal
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180315                 rengz              修正可用数量
  *********************************************************************/
  
    --declare @v_bin_date numeric(8); 
    
	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date;
	
	--生成衍生变量
    --set @v_b_date=(select min(rq) from dba.t_ddw_d_rq where nian=substring(@V_BIN_DATE,1,4) and yue=substring(@V_BIN_DATE,5,2) and sfjrbz='1' ); 
   
    --删除计算期数据
    delete from dm.t_ast_sec_acct_hld where load_dt =@v_bin_date;

    commit;


------------------------
  -- 日证券信息表
------------------------   
      select a.stock_cd
           ,a.stock_call
           ,trad_price
           ,b.exchange_type
           ,b.stock_type
           ,b.money_type
           ,b.remark
      into #t_stock_info
      from dba.t_edw_t06_stock_maket_info a
      left join dba.t_ods_uf2_sclxdz b
        on a.stock_type_cd = b.sec_type
       and b.mkt_type = a.market_type_cd
       and b.cur_type = a.curr_type_cd
     where load_dt = @v_bin_date;
    commit;
 
 ------------------------
  -- 生成成本等基本信息
------------------------   

    insert into dm.t_ast_sec_acct_hld
      (CUST_ID,
       CPTL_ACCT,
       SECU_CD,
       SECU_TYPE,
       MKT_TYPE,
       OCCUR_DT,
       HLD_VOL,
       CET_VOL,
       AVL_VOL,
       FRZ_VOL,
       BUYIN_COST,
       ROUG_VOL,
       --LS_HLD_VOL  限售持有数量
       CLQN_PRIC,
       MVAL,
       LOAD_DT,
       prod_type_perfm) 
          select 
            client_id
            ,fund_account
            ,stock_code
            ,a.stock_type
            ,a.exchange_type
            ,a.load_dt
            ,sum(current_amount)                                   --持有数量
            ,sum(correct_amount)                                   --修正数量
            ,sum(current_amount) as gain_bal                       --可用数量   20180315 修订 与持有数量冗余
            ,sum(frozen_amount)                                    --冻结数量
            ,sum(cost_price * current_amount)
            ,sum(uncome_buy_amount - uncome_sell_amount) as ztsl ---待交收
            ,max(b.trad_price)
            ,sum(b.trad_price * current_amount)
            ,a.load_dt as rq
            ,'1' as cplx                                         -----产品类型 绩效  待更新
       from dba.t_edw_uf2_stock a
       left join #t_stock_info b
         on a.stock_code = b.stock_cd
        and a.stock_type = b.stock_type
        and a.exchange_type = b.exchange_type
        and a.money_type = b.money_type
      where a.load_dt = @v_bin_date
      group by client_id,
               fund_account,
               stock_code,
               a.stock_type,
               a.exchange_type,
               a.load_dt;

   commit;

  ------------------------
  -- 限售持有数量
  ------------------------
      select distinct a.fund_account, stock_account, a.client_id
        into #t_fund
        from dba.t_edw_uf2_stockholder a
        left join dba.t_edw_uf2_fundaccount b on a.fund_account = b.fund_account and b.load_dt = @v_bin_date and b.fundacct_status = '0'
       where a.load_dt = @v_bin_date
         and a.exchange_type in ('1', '2')
         and a.asset_prop = '0';


      select b.fund_account, sec_code, sum(sec_bal) as cysl
        into #t_xscysl
        from dba.t_edw_tr_sec_bal_xslt a
        left join #t_fund b
          on a.inv_acc = b.stock_account
       where a.load_dt = @v_bin_date 
       group by b.fund_account, sec_code;

      update dm.t_ast_sec_acct_hld a
         set LS_HLD_VOL = coalesce(cysl, 0) 
      from #t_xscysl b
       where a.CPTL_ACCT = b.fund_account
         and a.OCCUR_DT = @v_bin_date
         and a.secu_cd = b.sec_code;

      commit;

  set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 

end
GO
GRANT EXECUTE ON dm.p_ast_sec_acct_hld TO query_dev
GO
GRANT EXECUTE ON dm.p_ast_sec_acct_hld TO xydc
GO
CREATE PROCEDURE dm.P_AST_STKPLG(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_资产：股票质押资产
      编写者：chenhu
      创建日期：2017-11-22
      修改日志：2017-12-26 新增合同编号
      简介：
        
    *********************************************************************/

    COMMIT;
    
    --删除当日数据
    DELETE FROM DM.T_AST_STKPLG WHERE OCCUR_DT = @V_IN_DATE;
    
    /*
    股票属性:stock_property:
    '05','首发前限售股'
    '00','无限售流通股'
    '01','首发后个人类限售股'
    '02','股权激励限售股'
    '03','首发后机构类限售股'
    '04','高管锁定股'
    '07','非流通股'
    融出方编号：DBA.T_ODS_UF2_SRPFUNDER.funder_no
    */
    INSERT INTO DM.T_AST_STKPLG
        (CUST_ID,OCCUR_DT,LOAD_DT,CTR_NO,GUAR_SECU_MVAL,STKPLG_FIN_BAL,SH_GUAR_SECU_MVAL,SZ_GUAR_SECU_MVAL,SH_NOTS_GUAR_SECU_MVAL,SZ_NOTS_GUAR_SECU_MVAL,PROP_FINAC_OUT_SIDE_BAL,ASSM_FINAC_OUT_SIDE_BAL,SM_LOAN_FINAC_OUT_BAL)
    SELECT GH.KHBH_HS   AS CUST_ID          --客户编号
        ,GH.RQ          AS OCCUR_DT         --业务日期  
        ,GH.RQ          AS LOAD_DT          --清洗日期  
        ,GH.HTBH        AS CTR_NO           --合同编号
        ,SUM(GH.DYZQSZ) AS GUAR_SECU_MVAL   --担保证券市值
        ,COALESCE(SUM(CASE WHEN GH.XYZT IN ('1','2') THEN GH.YJGHJE END),0) AS STKPLG_FIN_BAL    --融资余额                        ---20180418 仅包含协议状态为1 生效 2变更两类合同记录
        ,SUM(CASE WHEN GH.SCLX = '01' THEN GH.DYZQSZ ELSE 0 END)            AS SH_GUAR_SECU_MVAL --上海担保证券市值
        ,SUM(CASE WHEN GH.SCLX = '02' THEN GH.DYZQSZ ELSE 0 END)            AS SZ_GUAR_SECU_MVAL --深圳担保证券市值
        ,SUM(CASE WHEN GH.SCLX = '01' AND HS.STOCK_PROPERTY <> '00' THEN GH.DYZQSZ ELSE 0 END) AS SH_NOTS_GUAR_SECU_MVAL  --上海限售股担保证券市值
        ,SUM(CASE WHEN GH.SCLX = '02' AND HS.STOCK_PROPERTY <> '00' THEN GH.DYZQSZ ELSE 0 END) AS SZ_NOTS_GUAR_SECU_MVAL  --深圳限售股担保证券市值
        ,SUM(CASE WHEN GH.RCFBM = 1 THEN GH.YJGHJE ELSE 0 END)                                 AS PROP_FINAC_OUT_SIDE_BAL --自营融出方余额
        ,SUM(CASE WHEN GH.RCFBM NOT IN (1,23,50) THEN GH.YJGHJE ELSE 0 END)                    AS ASSM_FINAC_OUT_SIDE_BAL --资管融出方余额 
        ,SUM(CASE WHEN GH.RCFBM IN (23,50) THEN GH.YJGHJE ELSE 0 END)                          AS SM_LOAN_FINAC_OUT_BAL   --小额贷融出余额
    FROM DBA.T_DDW_GPZYHG_HT_D            GH
    LEFT JOIN 
             (SELECT A.LOAD_DT,A.CONTRACT_ID, A.STOCK_PROPERTY,A.FUND_ACCOUNT,A.CLIENT_ID,A.STOCK_ACCOUNT,A.STOCK_CODE,A.EXCHANGE_TYPE
              FROM DBA.GT_ODS_HS06_SRPCONTRACT A 
              WHERE  A.LOAD_DT= @V_IN_DATE 
              UNION 
              SELECT A.DATE_CLEAR,A.CONTRACT_ID, A.STOCK_PROPERTY,A.FUND_ACCOUNT,A.CLIENT_ID,A.STOCK_ACCOUNT,A.STOCK_CODE,A.EXCHANGE_TYPE
              FROM DBA.GT_ODS_HS06_HISSRPCONTRACT A 
              WHERE  A.DATE_CLEAR= @V_IN_DATE 
              )                           HS ON GH.RQ = HS.LOAD_DT AND GH.HTBH = HS.CONTRACT_ID                           --根据合同编号关联       20180418 增加当日已经了解合同信息    
    WHERE GH.RQ = @V_IN_DATE
    GROUP BY GH.KHBH_HS,GH.RQ,GH.HTBH;
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_STKPLG TO query_dev
GO
GRANT EXECUTE ON dm.P_AST_STKPLG TO xydc
GO
CREATE PROCEDURE dm.P_AST_STKPLG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建股票质押资产月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：股票质押资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --自然日_月末
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --交易日_月初
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --交易日_月末
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --交易日_年初
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --自然天数_月
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --交易天数_月
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --自然天数_年
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --交易天数_年


    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
 
--PART0 删除当月数据
  DELETE FROM DM.T_AST_STKPLG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	INSERT INTO DM.T_AST_STKPLG_M_D 
	(
	CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,CTR_NO
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,GUAR_SECU_MVAL_FINAL
	,STKPLG_FIN_BAL_FINAL
	,SH_GUAR_SECU_MVAL_FINAL
	,SZ_GUAR_SECU_MVAL_FINAL
	,SH_NOTS_GUAR_SECU_MVAL_FINAL
	,SZ_NOTS_GUAR_SECU_MVAL_FINAL
	,PROP_FINAC_OUT_SIDE_BAL_FINAL
	,ASSM_FINAC_OUT_SIDE_BAL_FINAL
	,SM_LOAN_FINAC_OUT_BAL_FINAL
	,GUAR_SECU_MVAL_MDA
	,STKPLG_FIN_BAL_MDA
	,SH_GUAR_SECU_MVAL_MDA
	,SZ_GUAR_SECU_MVAL_MDA
	,SH_NOTS_GUAR_SECU_MVAL_MDA
	,SZ_NOTS_GUAR_SECU_MVAL_MDA
	,PROP_FINAC_OUT_SIDE_BAL_MDA
	,ASSM_FINAC_OUT_SIDE_BAL_MDA
	,SM_LOAN_FINAC_OUT_BAL_MDA
	,GUAR_SECU_MVAL_YDA
	,STKPLG_FIN_BAL_YDA
	,SH_GUAR_SECU_MVAL_YDA
	,SZ_GUAR_SECU_MVAL_YDA
	,SH_NOTS_GUAR_SECU_MVAL_YDA
	,SZ_NOTS_GUAR_SECU_MVAL_YDA
	,PROP_FINAC_OUT_SIDE_BAL_YDA
	,ASSM_FINAC_OUT_SIDE_BAL_YDA
	,SM_LOAN_FINAC_OUT_BAL_YDA
	,LOAD_DT
	)
SELECT
	T1.CUST_ID AS 客户编码	
    ,@V_BIN_DATE AS OCCUR_DT
	,T_RQ.年
	,T_RQ.月
	,T1.CTR_NO AS 合同编号
	,T_RQ.自然天数_月
	,T_RQ.自然天数_年
	,T_RQ.自然日_月初
	,T_RQ.年||T_RQ.月 AS 年月
	,T_RQ.年||T_RQ.月||T1.CUST_ID AS 年月客户编码
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.GUAR_SECU_MVAL,0) ELSE 0 END) 			AS 担保证券市值_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.STKPLG_FIN_BAL,0) ELSE 0 END) 			AS 股票质押融资余额_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.SH_GUAR_SECU_MVAL,0) ELSE 0 END) 		AS 上海担保证券市值_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.SZ_GUAR_SECU_MVAL,0) ELSE 0 END) 		AS 深圳担保证券市值_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.SH_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END) 	AS 上海限售股担保证券市值_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.SZ_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END) 	AS 深圳限售股担保证券市值_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL,0) ELSE 0 END) 	AS 自营融出方余额_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL,0) ELSE 0 END) 	AS 资管融出方余额_期末
	,SUM(CASE WHEN T_RQ.日期=T_RQ.自然日_月末 THEN COALESCE(T1.SM_LOAN_FINAC_OUT_BAL,0) ELSE 0 END) 	AS 小额贷融出余额_期末

	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.自然天数_月 			AS 担保证券市值_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.STKPLG_FIN_BAL,0) ELSE 0 END)/T_RQ.自然天数_月 			AS 股票质押融资余额_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.SH_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.自然天数_月 		AS 上海担保证券市值_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.SZ_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.自然天数_月 		AS 深圳担保证券市值_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.SH_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.自然天数_月 	AS 上海限售股担保证券市值_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.SZ_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.自然天数_月 	AS 深圳限售股担保证券市值_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL,0) ELSE 0 END)/T_RQ.自然天数_月 AS 自营融出方余额_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL,0) ELSE 0 END)/T_RQ.自然天数_月 AS 资管融出方余额_月日均
	,SUM(CASE WHEN T_RQ.日期>=T_RQ.自然日_月初 THEN COALESCE(T1.SM_LOAN_FINAC_OUT_BAL,0) ELSE 0 END)/T_RQ.自然天数_月 	AS 小额贷融出余额_月日均

	,SUM(COALESCE(T1.GUAR_SECU_MVAL,0))/T_RQ.自然天数_年 			AS 担保证券市值_年日均
	,SUM(COALESCE(T1.STKPLG_FIN_BAL,0))/T_RQ.自然天数_年 			AS 股票质押融资余额_年日均
	,SUM(COALESCE(T1.SH_GUAR_SECU_MVAL,0))/T_RQ.自然天数_年 		AS 上海担保证券市值_年日均
	,SUM(COALESCE(T1.SZ_GUAR_SECU_MVAL,0))/T_RQ.自然天数_年 		AS 深圳担保证券市值_年日均
	,SUM(COALESCE(T1.SH_NOTS_GUAR_SECU_MVAL,0))/T_RQ.自然天数_年 	AS 上海限售股担保证券市值_年日均
	,SUM(COALESCE(T1.SZ_NOTS_GUAR_SECU_MVAL,0))/T_RQ.自然天数_年 	AS 深圳限售股担保证券市值_年日均
	,SUM(COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL,0))/T_RQ.自然天数_年 	AS 自营融出方余额_年日均
	,SUM(COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL,0))/T_RQ.自然天数_年 	AS 资管融出方余额_年日均
	,SUM(COALESCE(T1.SM_LOAN_FINAC_OUT_BAL,0))/T_RQ.自然天数_年 	AS 小额贷融出余额_年日均
	,@V_BIN_DATE

FROM
(
	select
		@V_BIN_YEAR as 年
		,@V_BIN_MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,@V_BIN_NATRE_DAY_MTHBEG    as 自然日_月初
		,@V_BIN_NATRE_DAY_MTHEND    as 自然日_月末
		,@V_BIN_TRD_DAY_MTHBEG      as 交易日_月初
		,@V_BIN_TRD_DAY_MTHEND      as 交易日_月末
		,@V_BIN_NATRE_DAY_YEARBGN   as 自然日_年初
		,@V_BIN_TRD_DAY_YEARBGN     as 交易日_年初
		,@V_BIN_NATRE_DAYS_MTH      as 自然天数_月
		,@V_BIN_TRD_DAYS_MTH        as 交易天数_月
		,@V_BIN_NATRE_DAYS_YEAR     as 自然天数_年
		,@V_BIN_TRD_DAYS_YEAR       as 交易天数_年
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) T_RQ
LEFT JOIN DM.T_AST_STKPLG T1 ON T_RQ.交易日期=T1.OCCUR_DT
GROUP BY
	T_RQ.年
	,T_RQ.月
	,T_RQ.自然天数_月
	,T_RQ.自然天数_年
	,T_RQ.自然日_月初
	,T1.CTR_NO
	,T1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.p_evt_cred_incm_d_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))


begin   
  /******************************************************************
  程序功能:  客户信用业务收入日表 
  编写者: rengz
  创建日期: 2018-4-20
  简介： 

  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明

  *********************************************************************/
 
    --declare @v_bin_date             numeric(8,0); 
    declare @v_bin_lastday          numeric(8,0);  

	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date ;
	
	--生成衍生变量

    set @v_bin_lastday             =(select lst_trd_day from dm.t_pub_date where dt=@v_bin_date);
 
    --删除计算期数据
    delete from dm.t_evt_cred_incm_d_d where occur_dt=@v_bin_date ;
    commit;
     
------------------------
  -- 生成每日客户清单：仅保留有两融业务的客户ID
------------------------  
  insert into dm.t_evt_cred_incm_d_d (CUST_ID, OCCUR_DT, MAIN_CPTL_ACCT)
  select distinct a.client_id,
                  a.load_dt,
                  b.fund_account 
    from (select distinct client_id, load_dt
            from DBA.T_EDW_RZRQ_CLIENT t
           where t.load_dt = @v_bin_date
             and t.client_status = '0'
             and convert(varchar, t.branch_no) not in ('5', '55', '51', '44', '9999')
             and t.client_id <> '448999999' ----剔除1户“专项头寸账户自动生成”。疑似公司自有账户，client_id下无普通账户，仅有多个信用账户且均为主资金户
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_gpzyhg_d t
           where t.rq = @v_bin_date ---股票质押
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999'
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_ydsgh_d t
           where t.rq = @v_bin_date ---约定式购回
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999') a
    left join dba.t_edw_uf2_fundaccount b
      on a.client_id = b.client_id
     and b.load_dt = @v_bin_date
     and b.fundacct_status = '0'
     and b.asset_prop = '0'
     and b.main_flag = '1';
   
   commit;
------------------------
  -- 生成佣金 净佣金
------------------------  
    select client_id
    ,sum(fare1)                                                                                         as yhs       --印花税 
    ,sum(fare2)                                                                                         as ghf       --过户费
    ,sum(fare3)                                                                                         as wtf       --委托费  
    ,sum(EXCHANGE_FARE0)                                                                                as jsf       --经手费   
    ,sum(EXCHANGE_FARE3)                                                                                as zgf       --证管费   
    ,sum(FAREX)                                                                                         as qtfy      --其他费用  
    ,sum(case when business_flag in ( 4001, 4002,                                        ---普通
                                      4211, 4212, 4213, 4214, 4215, 4216                 ---信用
                                    )  then (fare0)  else 0 end)                                        as yj      --佣金
    ,sum(case when business_flag in ( 4001, 4002,                                        ---普通
                                      4211, 4212, 4213, 4214, 4215, 4216               ---信用
                                   )  then 
            	                                                                                        coalesce(fare0,0)
									                                                                    + coalesce(fare3,0)
									                                                                    + coalesce(farex,0)
									                                                                    + coalesce(fare2,0)
									                                                                    - coalesce(exchange_fare0,0)
									                                                                    - coalesce(exchange_fare3,0)
									                                                                    - coalesce(exchange_fare4,0)
									                                                                    - coalesce(exchange_fare5,0)
									                                                                    - coalesce(exchange_fare6,0)
									                                                                    - coalesce(exchange_farex,0)
									                                                                    - coalesce(exchange_fare2,0)
              		                                                                         else 0 end)    as jyj      --净佣金
  
   ---普通交易
    ,sum(case when business_flag in ( 4001, 4002)  then (fare0)  else 0 end)                                as pt_yj  --普通交易佣金
    ,sum(case when business_flag in ( 4001, 4002)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                              as pt_jyj  --普通交易净佣金
    ,sum(case when business_flag in ( 4001, 4002)  then (fare2)  else 0 end)                               as pt_ghf   --普通交易过户费
   ---信用交易
    ,sum(case when  business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)      as xy_yj    --信用交易佣金
    ,sum(case when  business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                as xy_jyj   --信用交易净佣金
    ,sum(case when  business_flag in (4211, 4212, 4213, 4214, 4215, 4216)  then (fare2)  else 0 end)         as xy_ghf    --信用交易过户费
     
    into #t_yj   
    from DBA.T_EDW_RZRQ_HISDELIVER a
    where a.load_dt=  @v_bin_date
    group by client_id;
 
    commit;
   
    update dm.t_evt_cred_incm_d_d a
    set 
	    a.GROSS_CMS	        =coalesce(yj,0)           , -- 毛佣金
	    a.NET_CMS	        =coalesce(jyj,0)          , -- 净佣金
	    a.TRAN_FEE	        =coalesce(ghf,0)            , -- 过户费
	    a.STP_TAX	        =coalesce(yhs,0)            , -- 印花税
	    a.ORDR_FEE	        =coalesce(wtf,0)            , -- 委托费
	    a.HANDLE_FEE	    =coalesce(jsf,0)            , -- 经手费
	    a.SEC_RGLT_FEE	    =coalesce(zgf,0)            , -- 证管费
	    a.OTH_FEE		    =coalesce(qtfy,0)           , -- 其他费用
	    a.CREDIT_ODI_CMS	    =coalesce(pt_yj,0)    , -- 融资融券普通佣金
	    a.CREDIT_ODI_NET_CMS	=coalesce(pt_jyj,0)   , -- 融资融券普通净佣金
	    a.CREDIT_ODI_TRAN_FEE	=coalesce(pt_ghf,0)   , -- 融资融券普通过户费
	    a.CREDIT_CRED_CMS	    =coalesce(xy_yj,0)    , -- 融资融券信用佣金
	    a.CREDIT_CRED_NET_CMS	=coalesce(xy_jyj,0)   , -- 融资融券信用净佣金
	    a.CREDIT_CRED_TRAN_FEE	=coalesce(xy_ghf,0)     -- 融资融券信用过户费
    from dm.t_evt_cred_incm_d_d  a
    left join #t_yj              b on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
 commit;
  
 
 
------------------------
  -- 两融利息
------------------------  
    ---实收利息分解
   select client_id
         ,sum(case when business_flag in (2219, 2812, 2822, 2832, 2842)                                 then abs(occur_balance) else 0 end) as  lxzc_rz
 		 ,sum(case when business_flag in (2807, 2224)                                                   then abs(occur_balance) else 0 end) as  lxzc_rq
         ,sum(case when business_flag in ( 2814, 2816, 2824,2826, 2834, 2836, 2844, 2846,  2220, 2221)  then abs(occur_balance) else 0 end) as  lxzc_qt
   into #t_rzrq_ss
   -- select *,occur_balance
   from dba.t_EDW_RZRQ_HISFUNDJOUR   
   where  init_date  = @v_bin_date
   group by client_id;

   commit;

    update dm.t_evt_cred_incm_d_d 
    set 
     a.FIN_PAIDINT =coalesce(lxzc_rz,0)+coalesce(lxzc_qt,0)            ,--融资实收利息
     a.FIN_IE  =coalesce(lxzc_rz,0)                                    ,--月融资利息支出
     a.CRDT_STK_IE =coalesce(lxzc_rq,0)                                ,--月融券利息支出
     a.OTH_IE      =coalesce(lxzc_qt,0)                                 --月其他利息支出
    from dm.t_evt_cred_incm_d_d a 
    left join #t_rzrq_ss        b on a.cust_id=b.client_id
    where  a.occur_dt=@v_bin_date;

   commit;
 
   ---应收利息分解
    select a.client_id
           ,b.byddjgzr  as tianshu
           ,a.close_finance_interest  as close_finance_interest_today
           ,a.close_fare_interest     as close_fare_interest_today  
           ,a.close_other_interest    as close_other_interest_today  

           ,c.close_finance_interest  as close_finance_interest_lastday
           ,c.close_fare_interest     as close_fare_interest_lastday 
           ,c.close_other_interest    as close_other_interest_lastday 
           ,a.finance_close_balance + a.CLOSE_FARE_DEBIT + a.CLOSE_OTHER_DEBIT  as rzrqzjcb_xzq    --融资融券资金成本_计算基数
   into #t_rzrq_ys
   from DBA.T_EDW_RZRQ_hisASSETDEBIT      a
   left join dba.t_ddw_d_rq               b on a.init_date=b.rq
   left join DBA.T_EDW_RZRQ_hisASSETDEBIT c on a.client_id=c.client_id and c.init_date=@v_bin_lastday
   where a.init_date = @v_bin_date
     and a.branch_no not in(44,9999);


  commit;
   
 
    update dm.t_evt_cred_incm_d_d 
    set  
        
        a.DAY_FIN_RECE_INT =coalesce(close_finance_interest_today,0)-coalesce(close_finance_interest_lastday,0)                                  ,--日融资应收利息
        a.DAY_FEE_RECE_INT =coalesce(close_fare_interest_today,0)-coalesce(close_fare_interest_lastday,0)                                        ,--日费用应收利息
        a.DAY_OTH_RECE_INT =coalesce(close_other_interest_today,0)-coalesce(close_other_interest_lastday,0)                                       --日其他应收利息 
    from dm.t_evt_cred_incm_d_d a 
    left join #t_rzrq_ys        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;

   commit;
 
------------------------
  -- 股票质押佣金
------------------------  
   select khbh_hs,
          sum(yj  )       as yj_d,
          sum(jyj )       as jyj_d,
          sum(case when rq =@v_bin_date then  sslx end ) 
             - sum(case when rq =@v_bin_lastday then  sslx                            end )      as sslx_d,
          sum(case when rq =@v_bin_date then  yswslx+sslx end ) 
             - sum(case when rq =@v_bin_lastday then  yswslx+sslx                     end )      as yslx_d 
   into #t_gpzyyj
   from dba.t_ddw_gpzyhg_d a
   where rq between @v_bin_lastday and  @v_bin_date
   group by khbh_hs;

   
  update dm.t_evt_cred_incm_d_d a
    set 
        a.STKPLG_CMS	    =coalesce(yj_d,0)      ,    -- 股票质押佣金
	    a.STKPLG_NET_CMS	=coalesce(jyj_d,0)     ,    -- 股票质押净佣金
	    a.STKPLG_PAIDINT	=coalesce(sslx_d,0)    ,    -- 股票质押实收利息
	    a.STKPLG_RECE_INT	=coalesce(yslx_d,0)         -- 股票质押应收利息 
    from dm.t_evt_cred_incm_d_d a
    left join #t_gpzyyj         b on a.cust_id=b.khbh_hs
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- 约定购回佣金
------------------------  
    
     select a.khbh_hs as client_id, 
        SUM(a.yj)           as yj_d,    -- 约定购回佣金
        SUM(a.jyj)          as jyj_d ,  -- 约定购回净佣金
        sum(sslx)           as sslx_d,  -- 约定购回实收利息
        sum(yswslx+sslx)    as yslx_d 
      into #t_ydghyj
      from  dba.t_ddw_ydsgh_d   a 
      where rq = @v_bin_date
      group by a.khbh_hs ;
    

    update dm.t_evt_cred_incm_d_d 
    set 
        a.APPTBUYB_CMS	    =coalesce(yj_d,0)      ,    -- 约定购回佣金
	    a.APPTBUYB_NET_CMS	=coalesce(jyj_d,0)     ,    -- 约定购回净佣金 
	    a.APPTBUYB_PAIDINT	=coalesce(sslx_d,0)         -- 约定购回实收利息 
    from dm.t_evt_cred_incm_d_d a 
    left join #t_ydghyj         b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 
 
   set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 
 
end
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_d_d TO query_dev
GO
CREATE PROCEDURE dm.p_evt_cred_incm_m_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能:  客户信用业务收入月表（日更新）
  编写者: rengz
  创建日期: 2017-11-28
  简介：客户资金变动数据，日更新
        主要数据来自于：T_DDW_F00_KHMRZJZHHZ_D 日报 普通账户资金 及市值流入流出
                        tmp_ddw_khqjt_m_m     融资融券客户资金流入 流出

  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180124                 rengz              对融资利息进行分拆
             20180316                 rengz              1、修正委托费、经手费
                                                         2、客户群增加股票质押和约定购回目标客户
             20180330                 rengz              增加保证金利差收入及保证金利差收入修正
  *********************************************************************/
 
    -- declare @v_bin_date             numeric(8,0); 
    declare @v_bin_year             varchar(4); 
    declare @v_bin_mth              varchar(2); 
    declare @v_bin_qtr              varchar(2); --季度
    declare @v_bin_year_start_date  numeric(8); 
    declare @v_bin_mth_start_date   numeric(8); 
    declare @v_bin_lastmth_date     numeric(8); --上月同期
    declare @v_bin_lastmth_year     varchar(4); --上月同期对应年
    declare @v_bin_lastmth_mth      varchar(2); --上月同期对应月
    declare @v_bin_lastmth_start_date numeric(8); --上月开始日期
    declare @v_bin_lastmth_end_date numeric(8); --上月结束日期
    declare @v_date_num             numeric(8); --本月自然日的天数
    declare @v_bin_mth_end_date     numeric(8); --本月结束交易日
    declare @v_lcbl                 numeric(38,8); ---保证金利差比例
    declare @v_bin_qtr_m1_start_date  numeric(8); --本季度第1个月第一个交易日
    declare @v_bin_qtr_m1_end_date    numeric(8); --本季度第1个月最后一个交易日
    declare @v_bin_qtr_m2_start_date  numeric(8); --本季度第2个月第一个交易日
    declare @v_bin_qtr_m2_end_date    numeric(8); --本季度第2个月最后一个交易日
    declare @v_bin_qtr_m3_start_date  numeric(8); --本季度第3个月第一个交易日
    declare @v_bin_qtr_m3_end_date    numeric(8); --本季度第3个月最后一个交易日
    declare @v_bin_qtr_end_date     numeric(8); --本季度结束交易日 
    declare @v_date_qtr_m1_num        numeric(8); --本月自然日的天数
    declare @v_date_qtr_m2_num        numeric(8); --本月自然日的天数
    declare @v_date_qtr_m3_num        numeric(8); --本月自然日的天数
    
	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date ;
	
	--生成衍生变量
    set @v_bin_year=(select year from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_mth =(select mth  from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_qtr =(select qtr  from dm.t_pub_date where dt=@v_bin_date );
    set @v_bin_year_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and if_trd_day_flag=1 ); 
    set @v_bin_mth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_mth_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_qtr_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and qtr=@v_bin_qtr and if_trd_day_flag=1 ); 
    set @v_bin_lastmth_date=convert(numeric(8,0),(select dateadd(month,-1,@v_bin_date)));
    set @v_bin_lastmth_year=(select year from dm.t_pub_date where dt=@v_bin_lastmth_date ); 
    set @v_bin_lastmth_mth =(select mth  from dm.t_pub_date where dt=@v_bin_lastmth_date ); 
    set @v_bin_lastmth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_lastmth_year  and mth=@v_bin_lastmth_mth ); 
    set @v_bin_lastmth_end_date=(select max(dt) from dm.t_pub_date where year=@v_bin_lastmth_year  and mth=@v_bin_lastmth_mth ----and if_trd_day_flag=1  modify by rengz 根据王健全意见调整为自然日
	                                                                                                    ); 
    set @v_date_num          =case  when @v_bin_date=@v_bin_mth_end_date then (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth )
                                    else (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and dt<=@v_bin_date) end;             --当月最后一个交易日，按照自然日统计天数
    set @v_lcbl              =case when coalesce((select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth),0)=0 then 
                                        (select bjzlclv from dba.t_jxfc_market where nian||yue=substr(convert(varchar,dateadd(month,-1,convert(varchar,@v_bin_date)),112),1,6)  )
                              else (select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth) end ; 
    set @v_bin_qtr_m1_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1);
    set @v_bin_qtr_m1_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and mth=(select convert(varchar,min(mth)) from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_date_qtr_m1_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date );             --本季度第1个月自然日的天数
    set @v_date_qtr_m2_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date );             --本季度第2个月自然日的天数
    set @v_date_qtr_m3_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m3_start_date and @v_bin_qtr_m3_end_date );             --本季度第3个月自然日的天数  
 
    --删除计算期数据
    delete from dm.t_evt_cred_incm_m_d where year=@v_bin_year and mth=@v_bin_mth ;
    commit;
     

------------------------
  -- 生成每日客户清单：仅保留有两融业务的客户ID
------------------------  
  insert into dm.t_evt_cred_incm_m_d (CUST_ID, OCCUR_DT, MAIN_CPTL_ACCT, LOAD_DT, YEAR, MTH)
  select distinct a.client_id,
                  a.load_dt,
                  b.fund_account,
                  a.load_dt as rq,
                  @v_bin_year,
                  @v_bin_mth
    from (select distinct client_id, load_dt
            from DBA.T_EDW_RZRQ_CLIENT t
           where t.load_dt = @v_bin_date
             and t.client_status = '0'
             and convert(varchar, t.branch_no) not in ('5', '55', '51', '44', '9999')
             and t.client_id <> '448999999' ----剔除1户“专项头寸账户自动生成”。疑似公司自有账户，client_id下无普通账户，仅有多个信用账户且均为主资金户
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_gpzyhg_d t
           where t.rq = @v_bin_date ---股票质押
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999'
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_ydsgh_d t
           where t.rq = @v_bin_date ---约定式购回
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999') a
    left join dba.t_edw_uf2_fundaccount b
      on a.client_id = b.client_id
     and b.load_dt = @v_bin_date
     and b.fundacct_status = '0'
     and b.asset_prop = '0'
     and b.main_flag = '1';
   
   commit;
------------------------
  -- 生成佣金 净佣金
------------------------  
    select client_id
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare1 else 0 end )                                                                                         as yhs       --印花税 
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare2 else 0 end )                                                                                         as ghf       --过户费
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare3 else 0 end )                                                                                         as wtf       --委托费  
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then EXCHANGE_FARE0 else 0 end )                                                                                as jsf       --经手费   
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then EXCHANGE_FARE3 else 0 end )                                                                                as zgf       --证管费   
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then FAREX else 0 end )                                                                                         as qtfy      --其他费用  
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002,                                        ---普通
                                                                                                  4211, 4212, 4213, 4214, 4215, 4216                 ---信用
                                                                                                )  then (fare0)  else 0 end)                                                               as yj_m      --佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002,                                        ---普通
                                                                                                    4211, 4212, 4213, 4214, 4215, 4216               ---信用
                                                                                                )  then 
            	                                                                                        coalesce(fare0,0)
									                                                                    + coalesce(fare3,0)
									                                                                    + coalesce(farex,0)
									                                                                    + coalesce(fare2,0)
									                                                                    - coalesce(exchange_fare0,0)
									                                                                    - coalesce(exchange_fare3,0)
									                                                                    - coalesce(exchange_fare4,0)
									                                                                    - coalesce(exchange_fare5,0)
									                                                                    - coalesce(exchange_fare6,0)
									                                                                    - coalesce(exchange_farex,0)
									                                                                    - coalesce(exchange_fare2,0)
              		                                                                         else 0 end)                                                                                as jyj_m      --净佣金
  
   ---普通交易
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then (fare0)  else 0 end)                                                as pt_yj_m  --普通交易佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                           as pt_jyj_m  --普通交易净佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then (fare2)  else 0 end)                                                as pt_ghf_m   --普通交易过户费
   ---信用交易
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)                        as xy_yj_m    --信用交易佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                       as xy_jyj_m   --信用交易净佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in (4211, 4212, 4213, 4214, 4215, 4216)  then (fare2)  else 0 end)                     as xy_ghf_m    --信用交易过户费

    ,sum(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)                   as xy_yj_y    --年累计信用交易佣金
    ,sum(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                       as xy_jyj_y   --年累计信用交易净佣金      
    into #t_yj   
    from DBA.T_EDW_RZRQ_HISDELIVER a
    where a.load_dt between @v_bin_year_start_date and @v_bin_date
    group by client_id;
 
    commit;
   
    update dm.t_evt_cred_incm_m_d a
    set 
	    a.GROSS_CMS	        =coalesce(yj_m,0)           , -- 毛佣金
	    a.NET_CMS	        =coalesce(jyj_m,0)          , -- 净佣金
	    a.TRAN_FEE	        =coalesce(ghf,0)            , -- 过户费
	    a.STP_TAX	        =coalesce(yhs,0)            , -- 印花税
	    a.ORDR_FEE	        =coalesce(wtf,0)            , -- 委托费
	    a.HANDLE_FEE	    =coalesce(jsf,0)            , -- 经手费
	    a.SEC_RGLT_FEE	    =coalesce(zgf,0)            , -- 证管费
	    a.OTH_FEE		    =coalesce(qtfy,0)           , -- 其他费用
	    a.CREDIT_ODI_CMS	    =coalesce(pt_yj_m,0)    , -- 融资融券普通佣金
	    a.CREDIT_ODI_NET_CMS	=coalesce(pt_jyj_m,0)   , -- 融资融券普通净佣金
	    a.CREDIT_ODI_TRAN_FEE	=coalesce(pt_ghf_m,0)   , -- 融资融券普通过户费
	    a.CREDIT_CRED_CMS	    =coalesce(xy_yj_m,0)    , -- 融资融券信用佣金
	    a.CREDIT_CRED_NET_CMS	=coalesce(xy_jyj_m,0)   , -- 融资融券信用净佣金
	    a.CREDIT_CRED_TRAN_FEE	=coalesce(xy_ghf_m,0)   , -- 融资融券信用过户费
	    a.TY_CRED_CMS	    =coalesce(xy_yj_y,0)        , -- 今年信用佣金
	    a.TY_CRED_NET_CMS   =coalesce(xy_jyj_y,0)	      -- 今年信用净佣金 
    from dm.t_evt_cred_incm_m_d  a
    left join #t_yj              b on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
 commit;
  
 

------------------------
  -- 两融利息
------------------------  
    ---实收利息分解
   select client_id
         ,sum(case when business_flag in (2219, 2812, 2822, 2832, 2842)                                 then abs(occur_balance) else 0 end) as  lxzc_rz_m
 		 ,sum(case when business_flag in (2807, 2224)                                                   then abs(occur_balance) else 0 end) as  lxzc_rq_m
         ,sum(case when business_flag in ( 2814, 2816, 2824,2826, 2834, 2836, 2844, 2846,  2220, 2221)  then abs(occur_balance) else 0 end) as  lxzc_qt_m
   into #t_rzrq_ss
   -- select *,occur_balance
   from dba.t_EDW_RZRQ_HISFUNDJOUR   
   where  init_date  between @v_bin_mth_start_date and @v_bin_date
   group by client_id;

   commit;

    update dm.t_evt_cred_incm_m_d 
    set 
     a.fin_paidint =coalesce(lxzc_rz_m,0)+coalesce(lxzc_qt_m,0)          ,--融资实收利息
     a.MTH_FIN_IE  =coalesce(lxzc_rz_m,0)                                ,--月融资利息支出
     a.MTH_CRDT_STK_IE =coalesce(lxzc_rq_m,0)                            ,--月融券利息支出
     a.MTH_OTH_IE      =coalesce(lxzc_qt_m,0)                             --月其他利息支出
    from dm.t_evt_cred_incm_m_d a 
    left join #t_rzrq_ss        b on a.cust_id=b.client_id
    where  a.occur_dt=@v_bin_date;

   commit;
 
   ---应收利息分解
    select a.client_id
           ,b.byddjgzr  as tianshu
           ,a.close_finance_interest  as close_finance_interest_ym
           ,a.close_fare_interest     as close_fare_interest_ym  
           ,a.close_other_interest    as close_other_interest_ym  

           ,c.close_finance_interest  as close_finance_interest_sy
           ,c.close_fare_interest     as close_fare_interest_sy  
           ,c.close_other_interest    as close_other_interest_sy  
           ,a.finance_close_balance + a.CLOSE_FARE_DEBIT + a.CLOSE_OTHER_DEBIT  as rzrqzjcb_xzq    --融资融券资金成本_计算基数
   into #t_rzrq_ys
   from DBA.T_EDW_RZRQ_hisASSETDEBIT      a
   left join dba.t_ddw_d_rq               b on a.init_date=b.rq
   left join DBA.T_EDW_RZRQ_hisASSETDEBIT c on a.client_id=c.client_id and c.init_date=@v_bin_lastmth_end_date
   where a.init_date = @v_bin_date
     and a.branch_no not in(44,9999);


  commit;
   
 
    update dm.t_evt_cred_incm_m_d 
    set  
        a.FIN_RECE_INT =coalesce(close_finance_interest_ym,0)+coalesce(close_fare_interest_ym,0)+coalesce(close_other_interest_ym,0)          
                       -coalesce(close_finance_interest_sy,0)-coalesce(close_fare_interest_sy,0)-coalesce(close_other_interest_sy,0)     ,--融资应收利息
        a.MTH_FIN_RECE_INT =coalesce(close_finance_interest_ym,0)-coalesce(close_finance_interest_sy,0)                                  ,--月融资应收利息
        a.MTH_FEE_RECE_INT =coalesce(close_fare_interest_ym,0)-coalesce(close_fare_interest_sy,0)                                        ,--月费用应收利息
        a.MTH_OTH_RECE_INT =coalesce(close_other_interest_ym,0)-coalesce(close_other_interest_sy,0)                                      ,--月其他应收利息
        a.CREDIT_CPTL_COST =coalesce(rzrqzjcb_xzq,0)*(select rzrq_ll from dba.t_jxfc_rzrq_ll where nianyue=@v_bin_year||@v_bin_mth ) / 360                --融资融券资金成本
    from dm.t_evt_cred_incm_m_d a 
    left join #t_rzrq_ys        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;

   commit;
 
------------------------
  -- 股票质押佣金
------------------------  
   select khbh_hs,
          sum(case when rq between @v_bin_mth_start_date and @v_bin_date then  yj  end )       as yj_m,
          sum(case when rq between @v_bin_mth_start_date and @v_bin_date then  jyj end )       as jyj_m,
          sum(case when rq =@v_bin_date then  sslx end ) 
             - sum(case when rq =@v_bin_lastmth_end_date then  sslx                            end )      as sslx_m,
          sum(case when rq =@v_bin_date then  yswslx+sslx end ) 
             - sum(case when rq =@v_bin_lastmth_end_date then  yswslx+sslx                     end )      as yslx_m 
   into #t_gpzyyj
   from dba.t_ddw_gpzyhg_d a
   where rq between @v_bin_lastmth_start_date  and @v_bin_date
   group by khbh_hs;

   
  update dm.t_evt_cred_incm_m_d a
    set 
        a.STKPLG_CMS	    =coalesce(yj_m,0)      ,    -- 股票质押佣金
	    a.STKPLG_NET_CMS	=coalesce(jyj_m,0)     ,    -- 股票质押净佣金
	    a.STKPLG_PAIDINT	=coalesce(sslx_m,0)      ,  -- 股票质押实收利息
	    a.STKPLG_RECE_INT	=coalesce(yslx_m,0)         -- 股票质押应收利息 
    from dm.t_evt_cred_incm_m_d a
    left join #t_gpzyyj         b on a.cust_id=b.khbh_hs
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- 约定购回佣金
------------------------  
    
     select a.khbh_hs as client_id, 
        SUM(a.yj)           as yj_m,    -- 约定购回佣金
        SUM(a.jyj)          as jyj_m ,  -- 约定购回净佣金
        sum(sslx)           as sslx_m,  -- 约定购回实收利息
        sum(yswslx+sslx)    as yslx_m 
      into #t_ydghyj
      from  dba.t_ddw_ydsgh_d   a 
      where rq between @v_bin_mth_start_date and @v_bin_date
      group by a.khbh_hs ;
    

    update dm.t_evt_cred_incm_m_d 
    set 
        a.APPTBUYB_CMS	    =coalesce(yj_m,0)      ,    -- 约定购回佣金
	    a.APPTBUYB_NET_CMS	=coalesce(jyj_m,0)     ,    -- 约定购回净佣金 
	    a.APPTBUYB_PAIDINT	=coalesce(sslx_m,0)         -- 约定购回实收利息 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_ydghyj         b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- 融资融券_核算保证金利差收入_月累计
------------------------  

   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- 月累计核算利差保证金  "max(账户现金-max(（负债-客户提交担保资产×折算比例）,0),0) 担保资产含市值和现金，为自然日累计"
          ,coalesce(hsbzj,0)/@v_date_num                                               as rzrq_hsbzj_yrj       -- 融资融券_核算保证金_月日均
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- 融资融券_核算保证金利差收入_月累计
   into #t_bzjlcsr
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between  @v_bin_mth_start_date AND @v_bin_date
   group by client_id;

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- 融资融券保证金利差收入 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 


------------------------
  -- 修正本季度2两个月的融资融券_核算保证金利差收入_月累计
------------------------  

 
  if @v_bin_date= @v_bin_qtr_end_date
  then 
 
  ---本季度第1月
   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- 月累计核算利差保证金  "max(账户现金-max(（负债-客户提交担保资产×折算比例）,0),0) 担保资产含市值和现金，为自然日累计"
          ,coalesce(hsbzj,0)/@v_date_qtr_m1_num                                        as rzrq_hsbzj_yrj       -- 融资融券_核算保证金_月日均
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- 融资融券_核算保证金利差收入_月累计
   into #t_bzjlcsr_qrt_m1
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between  @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date
   group by client_id;

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM_CET	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- 融资融券保证金利差收入_修正 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr_qrt_m1 b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_qtr_m1_end_date;
  commit; 


  ---本季度第2月
   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- 月累计核算利差保证金  "max(账户现金-max(（负债-客户提交担保资产×折算比例）,0),0) 担保资产含市值和现金，为自然日累计"
          ,coalesce(hsbzj,0)/@v_date_qtr_m2_num                                        as rzrq_hsbzj_yrj       -- 融资融券_核算保证金_月日均
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- 融资融券_核算保证金利差收入_月累计
   into #t_bzjlcsr_qrt_m2
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date
   group by client_id;
  commit;
  

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM_CET	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- 融资融券保证金利差收入_修正 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr_qrt_m2 b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_qtr_m2_end_date;
  commit; 
 
  end if;
 

   set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 
 
end
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_m_d TO query_dev
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_m_d TO xydc
GO
CREATE PROCEDURE dm.P_EVT_CUS_ODI_TRD_M_D(IN @v_date int)
begin 
  
  /******************************************************************
  程序功能: 客户普通交易事实表（月存储日更新）
  编写者: 张琦
  创建日期: 2017-12-06
  简介：普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  
  declare @v_year varchar(4);		-- 年份
  declare @v_month varchar(2);	-- 月份
  declare @v_begin_trad_date int;	-- 本月开始交易日
  
	commit;
	
	set @v_year = substring(convert(varchar,@v_date),1,4);
	set @v_month = substring(convert(varchar,@v_date),5,2);
	set @v_begin_trad_date = (select min(RQ) from dba.t_ddw_d_rq where sfjrbz='1' and nian=@v_year and yue=@v_month);

  
	DELETE FROM DM.T_EVT_CUS_ODI_TRD_M_D WHERE "YEAR"=@v_year AND MTH=@v_month;

	INSERT INTO DM.T_EVT_CUS_ODI_TRD_M_D(
		CUST_ID
		,OCCUR_DT
		,"YEAR"
		,MTH
		,MAIN_CPTL_ACCT
		,LOAD_DT
	)
	SELECT a.client_id as CUST_ID
		,@v_date as OCCUR_DT
		,@v_year as "YEAR"
		,@v_month as MTH
		,b.MAIN_CPTL_ACCT
		,@v_date AS LOAD_DT
	FROM DBA.T_EDW_UF2_CLIENT a
	LEFT JOIN (
		SELECT CLIENT_ID, MAX(FUND_ACCOUNT) AS MAIN_CPTL_ACCT
		FROM DBA.T_EDW_UF2_FUNDACCOUNT
		WHERE LOAD_DT=@v_date
		AND MAIN_FLAG='1' AND ASSET_PROP='0'
		GROUP BY CLIENT_ID
	) b on a.CLIENT_ID=b.CLIENT_ID
	WHERE a.LOAD_DT=@v_date;

	-- 毛佣金 净佣金 二级交易量 股基交易量 正回购交易量 逆回购交易量 沪港通交易量 深港通交易量
	UPDATE DM.T_EVT_CUS_ODI_TRD_M_D
	SET GROSS_CMS = COALESCE(b.GROSS_CMS,0)
		,NET_CMS = coalesce(b.NET_CMS,0)
		,SCDY_TRD_QTY = coalesce(b.SCDY_TRD_QTY,0)
		,STKF_TRD_QTY = coalesce(b.STKF_TRD_QTY,0)
		,S_REPUR_TRD_QTY = coalesce(b.S_REPUR_TRD_QTY,0)
		,R_REPUR_TRD_QTY = coalesce(b.R_REPUR_TRD_QTY,0)
		,HGT_TRD_QTY = coalesce(b.HGT_TRD_QTY,0)
		,SGT_TRD_QTY = coalesce(b.SGT_TRD_QTY,0)
	FROM DM.T_EVT_CUS_ODI_TRD_M_D a
	LEFT JOIN (
		SELECT a.zjzh
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as GROSS_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb else 0 end) as NET_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.cjje*b.turn_rmb else 0 end) as SCDY_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102')  
				and (a.zqlx in ('10', 'A1','17', '18',@v_month,'1A','74','75')
					or (a.sclx in ('01','02') and a.zqlx='19'))
				then a.cjje*b.turn_rmb else 0 end
				) as STKF_TRD_QTY
			,sum(case when a.busi_type_cd='3701' then a.cjje*b.turn_rmb else 0 end) as S_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd='3703' then a.cjje*b.turn_rmb else 0 end) as R_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0G' then a.cjje*b.turn_rmb else 0 end) as HGT_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0S' then a.cjje*b.turn_rmb else 0 end) as SGT_TRD_QTY
		FROM dba.t_ddw_f00_khzqhz_d as a 
		left outer join dba.t_edw_t06_year_exchange_rate as b on a.load_dt between b.star_dt and b.end_dt 
			and b.curr_type_cd = 
			   case when a.zqlx = '18' and a.sclx = '05' then 'USD'
			   when a.zqlx = '17' then 'USD'
			   when a.zqlx = '18' then 'HKD' else 'CNY'
			   end
		where a.LOAD_DT between @v_begin_trad_date and @v_date
		group by a.zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	where a.YEAR=@v_year and a.MTH=@v_month;


	-- 大宗交易量
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set BGDL_QTY = coalesce(b.BGDL_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as BGDL_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between  @v_begin_trad_date and @v_date
		and busi_type_cd in ('3101', '3102') and note like '%大宗%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;


	-- 股票质押交易量
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set STKPLG_TRD_QTY = coalesce(b.STKPLG_TRD_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as STKPLG_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between @v_begin_trad_date and @v_date
		and note like '%股票质押%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- 约定购回交易量
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set APPTBUYB_TRD_QTY = coalesce(b.APPTBUYB_TRD_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as APPTBUYB_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between @v_begin_trad_date and @v_date
		and note like '%约定式购回%' and busi_type_cd='3101'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- 报价回购交易量
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set REPQ_TRD_QTY = coalesce(b.REPQ_TRD_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as REPQ_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between @v_begin_trad_date and @v_date
		and busi_type_cd in ('3703','3704') and "stock_cd" like '205%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- 个股期权交易量
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set PSTK_OPTN_TRD_QTY = coalesce(b.PSTK_OPTN_TRD_QTY,0)
	from  DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select client_id
			,sum(BUSINESS_BALANCE) as PSTK_OPTN_TRD_QTY
		from dba.T_EDW_UF2_HIS_OPTDELIVER
		where LOAD_DT between @v_begin_trad_date and @v_date
		group by client_id
	) b ON a.cust_id=b.client_id
	where a.YEAR=@v_year and a.MTH=@v_month;


	-- 二级交易次数 最近交易日期_本月  交易次数
	UPDATE DM.T_EVT_CUS_ODI_TRD_M_D
	SET SCDY_TRD_FREQ = coalesce(b.SCDY_TRD_FREQ,0)
		,RCT_TRD_DT_M = coalesce(b.RCT_TRD_DT_M,0)
		,TRD_FREQ = coalesce(b.TRD_FREQ,0)
	FROM DM.T_EVT_CUS_ODI_TRD_M_D a
	LEFT JOIN (
		SELECT fund_acct
			,sum(case when t.market_type_cd in ('01','02','03','04','05','0G','0S') then 1 else 0 end) as SCDY_TRD_FREQ
			,max(t.load_dt) as RCT_TRD_DT_M
			,count(1) as TRD_FREQ
		FROM DBA.T_EDW_T05_TRADE_JOUR t
		WHERE LOAD_DT BETWEEN @v_begin_trad_date AND @v_date
		and busi_type_cd in ( '3101','3102','3701','3703')
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT = b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- 最近交易日期_累计
	/*
	UPDATE DM.T_EVT_CUS_ODI_TRD_M_D
	set RCT_TRD_DT_GT = coalesce(b.RCT_TRD_DT_GT,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,max(load_dt) as RCT_TRD_DT_GT
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt<=@v_date
		group by fund_acct
	) b on 
	where a.YEAR=@v_year and a.MTH=@v_month;
	*/

	-- 股基交易量_本年 正回购交易量_本年 逆回购交易量_本年 沪港通交易量_本年 深港通交易量_本年 股票质押交易量_本年 约定购回交易量_本年
	-- 报价回购交易量_本年 大宗交易量_本年 个股期权交易量_本年 交易次数_本年 二级交易次数_本年
	update dm.T_EVT_CUS_ODI_TRD_M_D
	set STKF_TRD_QTY_TY = COALESCE(b.STKF_TRD_QTY_TY,0) -- 股基交易量_本年
		,S_REPUR_TRD_QTY_TY = coalesce(b.S_REPUR_TRD_QTY_TY,0)  -- 正回购交易量_本年
		,R_REPUR_TRD_QTY_TY = coalesce(b.R_REPUR_TRD_QTY_TY,0)  -- 逆回购交易量_本年
		,HGT_TRD_QTY_TY = coalesce(b.HGT_TRD_QTY_TY,0)  -- 沪港通交易量_本年
		,SGT_TRD_QTY_TY = coalesce(b.SGT_TRD_QTY_TY,0)  -- 深港通交易量_本年
		,STKPLG_TRD_QTY_TY = coalesce(b.STKPLG_TRD_QTY_TY,0)    -- 股票质押交易量_本年
		,APPTBUYB_TRD_QTY_TY = coalesce(b.APPTBUYB_TRD_QTY_TY,0)    -- 约定购回交易量_本年
		,REPQ_TRD_QTY_TY = coalesce(b.REPQ_TRD_QTY_TY,0)    -- 报价回购交易量_本年
		,BGDL_QTY_TY = coalesce(b.BGDL_QTY_TY,0)        -- 大宗交易量_本年
		,PSTK_OPTN_TRD_QTY_TY = coalesce(b.PSTK_OPTN_TRD_QTY_TY,0)  -- 个股期权交易量_本年
		,TRD_FREQ_TY = coalesce(b.TRD_FREQ_TY,0)    -- 交易次数_本年
		,SCDY_TRD_FREQ_TY =  coalesce(b.SCDY_TRD_FREQ_TY,0) -- 二级交易次数_本年
	from dm.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select CUST_ID
			,sum(STKF_TRD_QTY) as STKF_TRD_QTY_TY
			,sum(S_REPUR_TRD_QTY) as S_REPUR_TRD_QTY_TY
			,sum(R_REPUR_TRD_QTY) as R_REPUR_TRD_QTY_TY
			,sum(HGT_TRD_QTY) as HGT_TRD_QTY_TY
			,sum(SGT_TRD_QTY) as SGT_TRD_QTY_TY
			,sum(STKPLG_TRD_QTY) as STKPLG_TRD_QTY_TY
			,sum(APPTBUYB_TRD_QTY) as APPTBUYB_TRD_QTY_TY
			,sum(REPQ_TRD_QTY) as REPQ_TRD_QTY_TY
			,sum(BGDL_QTY) as BGDL_QTY_TY
			,sum(PSTK_OPTN_TRD_QTY) as PSTK_OPTN_TRD_QTY_TY
			,sum(TRD_FREQ) as TRD_FREQ_TY
			,sum(SCDY_TRD_FREQ) as SCDY_TRD_FREQ_TY
		from dm.T_EVT_CUS_ODI_TRD_M_D
		where YEAR=@v_year and MTH<=@v_month
		group by CUST_ID
	) b on a.CUST_ID=b.CUST_ID
	where a.YEAR=@v_year and a.MTH=@v_month;

    -- 二级交易量_本年（scdy_trd_qty_ty）
    update dm.T_EVT_CUS_ODI_TRD_M_D
    set scdy_trd_qty_ty = coalesce(b.scdy_trd_qty_ty,0)
    from dm.T_EVT_CUS_ODI_TRD_M_D a 
    left join (
        select a.zjzh,
            SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.cjje*b.turn_rmb else 0 end) as scdy_trd_qty_ty  -- 二级交易量_本年
        from dba.t_ddw_f00_khzqhz_d as a 
        left outer join dba.t_edw_t06_year_exchange_rate as b on a.load_dt between b.star_dt and b.end_dt and b.curr_type_cd = 
            case when a.zqlx = '18' and a.sclx = '05' then 'USD'
            when a.zqlx = '17' then 'USD'
            when a.zqlx = '18' then 'HKD' else 'CNY'
            end 
        where a.load_dt between convert(int,@v_year||'0101') and @v_date and
        a.sclx in( '01','02','03','04','05','0G','0S')  /*2014-11-28增加沪港通市场类型 2016-11-18增加深港通类型*/
        group by a.zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.YEAR=@v_year and a.MTH=@v_month;
    
    -- PB交易量
    update DM.T_EVT_CUS_ODI_TRD_M_D
    set PB_TRD_QTY = coalesce(b.jyl,0)
    from DM.T_EVT_CUS_ODI_TRD_M_D a 
    left join (
        select client_id, sum(business_balance) as jyl
        from dba.t_edw_uf2_his_deliver a
        where a.business_flag in (4001,4002,4103,4104)
        and fund_account in (
            select distinct fund_account from dba.t_edw_uf2_fundaccount 
            where client_group in (30,38) and substring(convert(varchar,load_dt),1,6)=@v_year||@v_month
        ) and substring(convert(varchar,load_dt),1,6)=@v_year||@v_month
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.year=@v_year and a.mth=@v_month;

  
   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_CUS_ODI_TRD_M_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_CUS_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  程序功能: 客户交易事实表_日表
  编写者: 张琦
  创建日期: 2017-12-06
  简介：普通交易的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

    commit;
    
    delete from dm.T_EVT_CUS_TRD_D_D where OCCUR_DT=@v_date;
    
    insert into dm.T_EVT_CUS_TRD_D_D(CUST_ID,OCCUR_DT,MAIN_CPTL_ACCT)
    SELECT a.CLIENT_ID as CUST_ID
        ,@v_date as OCCUR_DT
        ,b.MAIN_CPTL_ACCT as MAIN_CPTL_ACCT
    FROM DBA.T_EDW_UF2_CLIENT a
    LEFT JOIN (
        SELECT CLIENT_ID, MAX(FUND_ACCOUNT) AS MAIN_CPTL_ACCT
        FROM DBA.T_EDW_UF2_FUNDACCOUNT
        WHERE LOAD_DT=@v_date
        AND MAIN_FLAG='1' AND ASSET_PROP='0'
        GROUP BY CLIENT_ID
    ) b on a.CLIENT_ID=b.CLIENT_ID
    WHERE a.LOAD_DT=@v_date;
    
	-- 毛佣金 净佣金 二级交易量 股基交易量 正回购交易量 逆回购交易量 沪港通交易量 深港通交易量
	UPDATE DM.T_EVT_CUS_TRD_D_D
	SET GROSS_CMS = COALESCE(b.GROSS_CMS,0)
		,NET_CMS = coalesce(b.NET_CMS,0)
		,SCDY_TRD_QTY = coalesce(b.SCDY_TRD_QTY,0)
		,STKF_TRD_QTY = coalesce(b.STKF_TRD_QTY,0)
		,S_REPUR_TRD_QTY = coalesce(b.S_REPUR_TRD_QTY,0)
		,R_REPUR_TRD_QTY = coalesce(b.R_REPUR_TRD_QTY,0)
		,HGT_TRD_QTY = coalesce(b.HGT_TRD_QTY,0)
		,SGT_TRD_QTY = coalesce(b.SGT_TRD_QTY,0)
	FROM DM.T_EVT_CUS_TRD_D_D a
	LEFT JOIN (
		SELECT a.zjzh
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as GROSS_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb else 0 end) as NET_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.cjje*b.turn_rmb else 0 end) as SCDY_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102')  
				and (a.zqlx in ('10', 'A1','11','17', '18','1A','74','75')
					or (a.sclx in ('01','02') and a.zqlx='19'))
				then a.cjje*b.turn_rmb else 0 end
				) as STKF_TRD_QTY
			,sum(case when a.busi_type_cd='3701' then a.cjje*b.turn_rmb else 0 end) as S_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd='3703' then a.cjje*b.turn_rmb else 0 end) as R_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0G' then a.cjje*b.turn_rmb else 0 end) as HGT_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0S' then a.cjje*b.turn_rmb else 0 end) as SGT_TRD_QTY
		FROM dba.t_ddw_f00_khzqhz_d as a 
		left outer join dba.t_edw_t06_year_exchange_rate as b on a.load_dt between b.star_dt and b.end_dt 
			and b.curr_type_cd = 
			   case when a.zqlx = '18' and a.sclx = '05' then 'USD'
			   when a.zqlx = '17' then 'USD'
			   when a.zqlx = '18' then 'HKD' else 'CNY'
			   end
		where a.LOAD_DT = @v_date
		group by a.zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	where a.occur_dt=@v_date;
    
	-- 股票质押交易量
/*
	update DM.T_EVT_CUS_TRD_D_D
	set STKPLG_TRD_QTY = coalesce(b.STKPLG_TRD_QTY,0)
	from DM.T_EVT_CUS_TRD_D_D a
	left join (
		select fund_acct
			,sum(trad_amt) as STKPLG_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt = @v_date
		and note like '%股票质押%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.occur_dt=@v_date;
*/
    
	update DM.T_EVT_CUS_TRD_D_D
	set APPTBUYB_TRD_QTY = coalesce(b.APPTBUYB_TRD_QTY,0)
        ,apptbuyb_trd_amt = coalesce(b.apptbuyb_trd_amt,0)
	from DM.T_EVT_CUS_TRD_D_D a
	left join (
		select fund_acct
			,sum(trad_num) as APPTBUYB_TRD_QTY  -- 约定购回交易量
            ,sum(trad_amt) as apptbuyb_trd_amt  -- 约定购回交易金额
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt = @v_date
		and note like '%约定式购回%' and busi_type_cd='3101'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.occur_dt=@v_date;
    
    -- 约定购回还款金额,约定购回购回金额
    update DM.T_EVT_CUS_TRD_D_D
    set apptbuyb_rep_amt = coalesce(b.apptbuyb_rep_amt,0)
        ,apptbuyb_buyb_amt = coalesce(b.apptbuyb_rep_amt,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select zjzh
            ,sum(fz) as apptbuyb_rep_amt
        from dba.t_ddw_ydsgh_d
        where rq=@v_date
        group by zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.occur_dt=@v_date;

	-- 个股期权交易量
	update DM.T_EVT_CUS_TRD_D_D
	set PSTK_OPTN_TRD_QTY = coalesce(b.PSTK_OPTN_TRD_QTY,0)
	from  DM.T_EVT_CUS_TRD_D_D a
	left join (
		select client_id
			,sum(BUSINESS_BALANCE) as PSTK_OPTN_TRD_QTY
		from dba.T_EDW_UF2_HIS_OPTDELIVER
		where LOAD_DT = @v_date
		group by client_id
	) b ON a.cust_id=b.client_id
	where a.occur_dt=@v_date;



    UPDATE DM.T_EVT_CUS_TRD_D_D
    SET credit_cred_trd_qty = coalesce(b.credit_cred_trd_qty,0)
        ,credit_odi_trd_qty = coalesce(b.credit_odi_trd_qty,0)
        ,credit_trd_qty = coalesce(b.credit_trd_qty,0)
        ,CCB_CNT = coalesce(b.CCB_CNT,0)
        ,CCB_AMT = coalesce(b.CCB_AMT,0)
        ,FIN_SELL_CNT = coalesce(b.FIN_SELL_CNT,0)
        ,FIN_SELL_AMT = coalesce(b.FIN_SELL_AMT,0)
        ,CRDT_STK_BUYIN_CNT = coalesce(b.CRDT_STK_BUYIN_CNT,0)
        ,CRDT_STK_BUYIN_AMT = coalesce(b.CRDT_STK_BUYIN_AMT,0)
        ,CSS_CNT = coalesce(b.CSS_CNT,0)
        ,CSS_AMT = coalesce(b.CSS_AMT,0)
    FROM DM.T_EVT_CUS_TRD_D_D a
    left join (
        select CLIENT_ID
            ,SUM(case when business_flag in( 4211,4212,4213,4214,4215,4216) then business_balance else 0 end) as credit_cred_trd_qty    -- 信用账户信用交易量
            ,SUM(case when business_flag in( 4001,4002) then business_balance else 0 end) as credit_odi_trd_qty -- 信用账户普通交易量
            ,credit_cred_trd_qty + credit_odi_trd_qty as credit_trd_qty -- 融资融券交易量
            ,sum(case when business_flag=4211 then 1 else 0 end) as CCB_CNT  -- 融资买入笔数
            ,sum(case when business_flag=4211 then business_balance else 0 end) as CCB_AMT  -- 融资买入金额
            ,sum(case when business_flag=4212 then 1 else 0 end) as FIN_SELL_CNT  -- 融资卖出笔数
            ,sum(case when business_flag=4212 then business_balance else 0 end) as FIN_SELL_AMT  -- 融资卖出金额
            ,sum(case when business_flag=4213 then 1 else 0 end) as CRDT_STK_BUYIN_CNT  -- 融券买入笔数
            ,sum(case when business_flag=4213 then business_balance else 0 end) as CRDT_STK_BUYIN_AMT  -- 融券买入金额
            ,sum(case when business_flag=4214 then 1 else 0 end) as CSS_CNT  -- 融券卖出笔数
            ,sum(case when business_flag=4214 then business_balance else 0 end) as CSS_AMT  -- 融券卖出金额
    -- select *
        from dba.t_edw_rzrq_hisdeliver
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;
    
    
    
    
    update DM.T_EVT_CUS_TRD_D_D 
    set FIN_AMT = coalesce(b.FIN_AMT,0)
        ,CRDT_STK_AMT = coalesce(b.CRDT_STK_AMT,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select client_id
            ,sum(finance_close_balance) as FIN_AMT  -- 融资金额
            ,sum(shortsell_close_balance) as CRDT_STK_AMT  -- 融券金额
        -- select *
        from dba.t_edw_rzrq_hisassetdebit
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;
    
    
    
      select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE into
        #tmp_edw_t05_trade_jour from(
        select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE from
          dba.t_edw_t05_trade_jour where
          load_dt = @v_date and
          note like '股票质押初始交易,融入方资金划入%' union
        select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE from
          dba.t_edw_t05_trade_jour where
          load_dt = @v_date and
          note like '股票质押购回交易,融入方资金划出%' union
        select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE from
          dba.t_edw_t05_trade_jour where
          load_dt = @v_date and
          note like '股票质押补充质押%') as t;
    
    update DM.T_EVT_CUS_TRD_D_D
    set STKPLG_BUYB_CNT = coalesce(b.STKPLG_BUYB_CNT,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
    select fund_acct
        ,SUM(case when note like '%购回交易%' then 1 else 0 end) as STKPLG_BUYB_CNT -- 股票质押购回笔数
    from #tmp_edw_t05_trade_jour
    group by fund_acct
    ) b on a.main_cptl_acct=b.fund_acct
    where a.occur_dt=@v_date;
    
    update DM.T_EVT_CUS_TRD_D_D
    set STKPLG_TRD_QTY = coalesce(b.STKPLG_TRD_QTY,0)
        ,STKPLG_BUYB_AMT = coalesce(b.STKPLG_BUYB_AMT,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select khbh_hs
            ,sum(csjyje+ghjyje) as STKPLG_TRD_QTY   -- 股票质押交易量
            ,sum(ghjyje) as STKPLG_BUYB_AMT -- 股票质押购回金额
        -- select *
        from dba.t_ddw_gpzyhg_d 
        where rq=@v_date
        group by khbh_hs
    ) b on a.cust_id=b.khbh_hs
    where a.occur_dt=@v_date;
    
    update DM.T_EVT_CUS_TRD_D_D
    set OFFUND_TRD_QTY = coalesce(b.OFFUND_TRD_QTY,0)
        ,OPFUND_TRD_QTY = coalesce(b.OPFUND_TRD_QTY,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select zjzh
            ,sum(cnje_rgqr_d+cnje_sgqr_d+cnje_dsdetzqr_d+cnje_shqr_d+cnje_jymr_d+cnje_jymc_d) as OFFUND_TRD_QTY -- 场内基金交易量
            ,sum(cwje_rgqr_d+cwje_sgqr_d+cwje_dsdetzqr_d+cwje_zhrqr_d+cwje_zhcqr_d+cwje_shqr_d) as OPFUND_TRD_QTY   -- 场外基金交易量
        -- select *
        from dba.t_ddw_xy_jjzb_d
        where rq=@v_date
        group by zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.occur_dt=@v_date;
    
    
    update DM.T_EVT_CUS_TRD_D_D 
    set BANK_CHRM_TRD_QTY = coalesce(b.BANK_CHRM_TRD_QTY,0)
    from DM.T_EVT_CUS_TRD_D_D a 
    left join (
        select client_id
            ,sum(case when business_flag in (43130,43142) then abs(entrust_balance) else 0 end) as BANK_CHRM_TRD_QTY    -- 银行理财交易量
        -- select *
        from dba.T_EDW_UF2_HIS_BANKMDELIVER
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;
    
    
    update DM.T_EVT_CUS_TRD_D_D 
    set SECU_CHRM_TRD_QTY = coalesce(b.SECU_CHRM_TRD_QTY,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select client_id
            ,sum(business_balance) as SECU_CHRM_TRD_QTY -- 证券理财交易量
        -- select *
        from dba.GT_ODS_ZHXT_HIS_SECUMDELIVER
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;

    -- 融资归还金额（暂无口径，置0）
    update DM.T_EVT_CUS_TRD_D_D a
    set fin_rtn_amt = 0
    where a.occur_dt=@v_date;

commit;


end
GO
GRANT EXECUTE ON dm.P_EVT_CUS_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_CUS_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建客户交易事实月表
  编写者: DCY
  创建日期: 2018-02-28
  简介：客户交易事实月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --自然日_月末
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --交易日_月初
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --交易日_月末
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --交易日_年初
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --自然天数_月
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --交易天数_月
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --自然天数_年
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --交易天数_年


    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 删除当月数据
  DELETE FROM DM.T_EVT_CUS_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_EVT_CUS_TRD_M_D 
	(
	 CUST_ID   
    ,OCCUR_DT	 
	,YEAR                 
	,MTH                  
	,NATRE_DAYS_MTH       
	,NATRE_DAYS_YEAR      
	,YEAR_MTH             
	,YEAR_MTH_CUST_ID     
	,STKF_TRD_QTY_MDA 
	,SCDY_TRD_QTY_MDA     
	,CREDIT_ODI_TRD_QTY_MDA 
	,CREDIT_CRED_TRD_QTY_MDA 
	,STKF_TRD_QTY_MTD     
	,SCDY_TRD_QTY_MTD     
	,S_REPUR_TRD_QTY_MTD  
	,R_REPUR_TRD_QTY_MTD  
	,HGT_TRD_QTY_MTD      
	,SGT_TRD_QTY_MTD      
	,STKPLG_TRD_QTY_MTD   
	,APPTBUYB_TRD_QTY_MTD 
	,CREDIT_TRD_QTY_MTD   
	,OFFUND_TRD_QTY_MTD   
	,OPFUND_TRD_QTY_MTD   
	,BANK_CHRM_TRD_QTY_MTD 
	,SECU_CHRM_TRD_QTY_MTD 
	,CREDIT_ODI_TRD_QTY_MTD 
	,CREDIT_CRED_TRD_QTY_MTD 
	,FIN_AMT_MTD          
	,CRDT_STK_AMT_MTD     
	,STKPLG_BUYB_AMT_MTD  
	,PSTK_OPTN_TRD_QTY_MTD 
	,GROSS_CMS_MTD        
	,NET_CMS_MTD          
	,STKPLG_BUYB_CNT_MTD  
	,CCB_AMT_MTD          
	,CCB_CNT_MTD          
	,FIN_SELL_AMT_MTD     
	,FIN_SELL_CNT_MTD     
	,CRDT_STK_BUYIN_AMT_MTD 
	,CRDT_STK_BUYIN_CNT_MTD 
	,CSS_AMT_MTD          
	,CSS_CNT_MTD          
	,FIN_RTN_AMT_MTD      
	,APPTBUYB_REP_AMT_MTD 
	,APPTBUYB_BUYB_AMT_MTD 
	,APPTBUYB_TRD_AMT_MTD 
	,STKF_TRD_QTY_YDA     
	,SCDY_TRD_QTY_YDA     
	,CREDIT_ODI_TRD_QTY_YDA 
	,CREDIT_CRED_TRD_QTY_YDA 
	,STKF_TRD_QTY_YTD     
	,SCDY_TRD_QTY_YTD     
	,S_REPUR_TRD_QTY_YTD  
	,R_REPUR_TRD_QTY_YTD  
	,HGT_TRD_QTY_YTD      
	,SGT_TRD_QTY_YTD      
	,STKPLG_TRD_QTY_YTD   
	,APPTBUYB_TRD_QTY_YTD 
	,CREDIT_TRD_QTY_YTD   
	,OFFUND_TRD_QTY_YTD   
	,OPFUND_TRD_QTY_YTD   
	,BANK_CHRM_TRD_QTY_YTD 
	,SECU_CHRM_TRD_QTY_YTD 
	,CREDIT_ODI_TRD_QTY_YTD 
	,CREDIT_CRED_TRD_QTY_YTD 
	,FIN_AMT_YTD          
	,CRDT_STK_AMT_YTD     
	,STKPLG_BUYB_AMT_YTD  
	,PSTK_OPTN_TRD_QTY_YTD 
	,GROSS_CMS_YTD        
	,NET_CMS_YTD          
	,STKPLG_BUYB_CNT_YTD  
	,CCB_AMT_YTD          
	,CCB_CNT_YTD          
	,FIN_SELL_AMT_YTD     
	,FIN_SELL_CNT_YTD     
	,CRDT_STK_BUYIN_AMT_YTD 
	,CRDT_STK_BUYIN_CNT_YTD 
	,CSS_AMT_YTD          
	,CSS_CNT_YTD          
	,FIN_RTN_AMT_YTD      
	,APPTBUYB_REP_AMT_YTD 
	,APPTBUYB_BUYB_AMT_YTD 
	,APPTBUYB_TRD_AMT_YTD 
	,LOAD_DT        
	)
select
	t1.CUST_ID as 客户编码	
	,@V_BIN_DATE as occur_dt
	,t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKF_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 股基交易量_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SCDY_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 二级交易量_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_ODI_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 信用账户普通交易量_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_CRED_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 信用账户信用交易量_月日均
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKF_TRD_QTY,0) else 0 end) as 股基交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SCDY_TRD_QTY,0) else 0 end) as 二级交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.S_REPUR_TRD_QTY,0) else 0 end) as 正回购交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.R_REPUR_TRD_QTY,0) else 0 end) as 逆回购交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.HGT_TRD_QTY,0) else 0 end) as 沪港通交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SGT_TRD_QTY,0) else 0 end) as 深港通交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKPLG_TRD_QTY,0) else 0 end) as 股票质押交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_TRD_QTY,0) else 0 end) as 约定购回交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_TRD_QTY,0) else 0 end) as 融资融券交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OFFUND_TRD_QTY,0) else 0 end) as 场内基金交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OPFUND_TRD_QTY,0) else 0 end) as 场外基金交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.BANK_CHRM_TRD_QTY,0) else 0 end) as 银行理财交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SECU_CHRM_TRD_QTY,0) else 0 end) as 证券理财交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_ODI_TRD_QTY,0) else 0 end) as 信用账户普通交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_CRED_TRD_QTY,0) else 0 end) as 信用账户信用交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_AMT,0) else 0 end) as 融资金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_AMT,0) else 0 end) as 融券金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKPLG_BUYB_AMT,0) else 0 end) as 股票质押购回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PSTK_OPTN_TRD_QTY,0) else 0 end) as 个股期权交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.GROSS_CMS,0) else 0 end) as 毛佣金_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.NET_CMS,0) else 0 end) as 净佣金_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKPLG_BUYB_CNT,0) else 0 end) as 股票质押购回笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CCB_AMT,0) else 0 end) as 融资买入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CCB_CNT,0) else 0 end) as 融资买入笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_SELL_AMT,0) else 0 end) as 融资卖出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_SELL_CNT,0) else 0 end) as 融资卖出笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_BUYIN_AMT,0) else 0 end) as 融券买入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_BUYIN_CNT,0) else 0 end) as 融券买入笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CSS_AMT,0) else 0 end) as 融券卖出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CSS_CNT,0) else 0 end) as 融券卖出笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_RTN_AMT,0) else 0 end) as 融资归还金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_REP_AMT,0) else 0 end) as 约定购回还款金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_BUYB_AMT,0) else 0 end) as 约定购回购回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_TRD_AMT,0) else 0 end) as 约定购回交易金额_月累计

	,sum(COALESCE(t1.STKF_TRD_QTY,0))/t_rq.自然天数_年 as 股基交易量_年日均
	,sum(COALESCE(t1.SCDY_TRD_QTY,0))/t_rq.自然天数_年 as 二级交易量_年日均
	,sum(COALESCE(t1.CREDIT_ODI_TRD_QTY,0))/t_rq.自然天数_年 as 信用账户普通交易量_年日均
	,sum(COALESCE(t1.CREDIT_CRED_TRD_QTY,0))/t_rq.自然天数_年 as 信用账户信用交易量_年日均
	
	,sum(COALESCE(t1.STKF_TRD_QTY,0)) as 股基交易量_年累计
	,sum(COALESCE(t1.SCDY_TRD_QTY,0)) as 二级交易量_年累计
	,sum(COALESCE(t1.S_REPUR_TRD_QTY,0)) as 正回购交易量_年累计
	,sum(COALESCE(t1.R_REPUR_TRD_QTY,0)) as 逆回购交易量_年累计
	,sum(COALESCE(t1.HGT_TRD_QTY,0)) as 沪港通交易量_年累计
	,sum(COALESCE(t1.SGT_TRD_QTY,0)) as 深港通交易量_年累计
	,sum(COALESCE(t1.STKPLG_TRD_QTY,0)) as 股票质押交易量_年累计
	,sum(COALESCE(t1.APPTBUYB_TRD_QTY,0)) as 约定购回交易量_年累计
	,sum(COALESCE(t1.CREDIT_TRD_QTY,0)) as 融资融券交易量_年累计
	,sum(COALESCE(t1.OFFUND_TRD_QTY,0)) as 场内基金交易量_年累计
	,sum(COALESCE(t1.OPFUND_TRD_QTY,0)) as 场外基金交易量_年累计
	,sum(COALESCE(t1.BANK_CHRM_TRD_QTY,0)) as 银行理财交易量_年累计
	,sum(COALESCE(t1.SECU_CHRM_TRD_QTY,0)) as 证券理财交易量_年累计
	,sum(COALESCE(t1.CREDIT_ODI_TRD_QTY,0)) as 信用账户普通交易量_年累计
	,sum(COALESCE(t1.CREDIT_CRED_TRD_QTY,0)) as 信用账户信用交易量_年累计
	,sum(COALESCE(t1.FIN_AMT,0)) as 融资金额_年累计
	,sum(COALESCE(t1.CRDT_STK_AMT,0)) as 融券金额_年累计
	,sum(COALESCE(t1.STKPLG_BUYB_AMT,0)) as 股票质押购回金额_年累计
	,sum(COALESCE(t1.PSTK_OPTN_TRD_QTY,0)) as 个股期权交易量_年累计
	,sum(COALESCE(t1.GROSS_CMS,0)) as 毛佣金_年累计
	,sum(COALESCE(t1.NET_CMS,0)) as 净佣金_年累计
	,sum(COALESCE(t1.STKPLG_BUYB_CNT,0)) as 股票质押购回笔数_年累计
	,sum(COALESCE(t1.CCB_AMT,0)) as 融资买入金额_年累计
	,sum(COALESCE(t1.CCB_CNT,0)) as 融资买入笔数_年累计
	,sum(COALESCE(t1.FIN_SELL_AMT,0)) as 融资卖出金额_年累计
	,sum(COALESCE(t1.FIN_SELL_CNT,0)) as 融资卖出笔数_年累计
	,sum(COALESCE(t1.CRDT_STK_BUYIN_AMT,0)) as 融券买入金额_年累计
	,sum(COALESCE(t1.CRDT_STK_BUYIN_CNT,0)) as 融券买入笔数_年累计
	,sum(COALESCE(t1.CSS_AMT,0)) as 融券卖出金额_年累计
	,sum(COALESCE(t1.CSS_CNT,0)) as 融券卖出笔数_年累计
	,sum(COALESCE(t1.FIN_RTN_AMT,0)) as 融资归还金额_年累计
	,sum(COALESCE(t1.APPTBUYB_REP_AMT,0)) as 约定购回还款金额_年累计
	,sum(COALESCE(t1.APPTBUYB_BUYB_AMT,0)) as 约定购回购回金额_年累计
	,sum(COALESCE(t1.APPTBUYB_TRD_AMT,0)) as 约定购回交易金额_年累计
	,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as 年
		,@V_BIN_MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,@V_BIN_NATRE_DAY_MTHBEG    as 自然日_月初
		,@V_BIN_NATRE_DAY_MTHEND    as 自然日_月末
		,@V_BIN_TRD_DAY_MTHBEG      as 交易日_月初
		,@V_BIN_TRD_DAY_MTHEND      as 交易日_月末
		,@V_BIN_NATRE_DAY_YEARBGN   as 自然日_年初
		,@V_BIN_TRD_DAY_YEARBGN     as 交易日_年初
		,@V_BIN_NATRE_DAYS_MTH      as 自然天数_月
		,@V_BIN_TRD_DAYS_MTH        as 交易天数_月
		,@V_BIN_NATRE_DAYS_YEAR     as 自然天数_年
		,@V_BIN_TRD_DAYS_YEAR       as 交易天数_年
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
 	  and t1.IF_TRD_DAY_FLAG=1
) t_rq
left join DM.T_EVT_CUS_TRD_D_D t1 on t_rq.日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t1.CUST_ID
	,年月
	,年月客户编码
;

END
GO
CREATE PROCEDURE dm.P_EVT_CUST_OACT_FEE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 客户开户费表
  编写者: DCY 参考董依良提供的取数逻辑
  创建日期: 2018-01-17
  简介：
  *********************************************************************
  修订记录：   修订日期    修订人     修改内容简要说明
           
  *********************************************************************/
    DECLARE @NIAN VARCHAR(4);		--本月_年份
	DECLARE @YUE VARCHAR(2)	;		--本月_月份
	DECLARE @ZRR_NC INT;            --自然日_月初
	DECLARE @ZRR_YC INT;            --自然日_年初 
	DECLARE @TD_YM INT;				--月末
	DECLARE @NY INT;
	
	
	DECLARE @ZRR_YM INT;            --自然日_月末
	
    SET @V_OUT_FLAG = -1;  --初始清洗赋值-1

    SET @NIAN=SUBSTR(@V_BIN_DATE||'',1,4);
	SET @YUE=SUBSTR(@V_BIN_DATE||'',5,2);
   	SET @ZRR_NC=(SELECT MIN(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.日期>=CONVERT(INT,@NIAN||'0101'));
	SET @ZRR_YC=(SELECT MIN(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.日期>=CONVERT(INT,@NIAN||@YUE||'01'));
	SET @TD_YM=(SELECT MAX(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.是否工作日='1' AND T1.日期<=CONVERT(INT,@NIAN||@YUE||'31'));
    SET @NY=CONVERT(INT,@NIAN||@YUE);
	
	SET @ZRR_YM=(SELECT MAX(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.日期<=CONVERT(INT,@NIAN||@YUE||'31'));

	
	
  --PART0 删除要回洗的数据
    DELETE FROM DM.T_EVT_CUST_OACT_FEE WHERE OACT_YEAR_MTH=@NIAN||@YUE;
	
 
    --PART1 客户的开户费：日更新月存储,重新清洗则只清洗每月最后一个交易日数据
	INSERT INTO DM.T_EVT_CUST_OACT_FEE
	(
	 OACT_YEAR_MTH       --开户年月
	,CUST_ID             --客户编码
	,SECU_ACCT           --证券账号
	,MTH                 --月
	,YEAR                --年
	,HS_ORG_ID           --恒生机构编码
	,WH_ORG_ID           --仓库机构编码
	,BRH_NAME            --营业部名称
	,SEPT_CORP_NAME      --分公司名称
	,CPTL_ACCT           --资金账号
	,SECU_ACCT_OACT_DT   --证券账号开户日期
	,OACT_FEE_PAYOUT     --开户费支出
	,LOAD_DT             --清洗日期
	)
(	SELECT
			SUBSTRING(CONVERT(VARCHAR,T2.OPEN_DATE),0,6) AS OACT_YEAR_MTH
			,T2.CLIENT_ID AS CUST_ID
			,T1.ZQZH  AS SECU_ACCT--证券账户
			,SUBSTRING(OACT_YEAR_MTH,5,6) AS MTH
			,SUBSTRING(OACT_YEAR_MTH,0,4) AS YEAR
			,CONVERT(VARCHAR,T2.BRANCH_NO) AS HS_ORG_ID
			,YYB.JGBH AS WH_ORG_ID 
			,YYB.JGMC AS BRH_NAME
			,YYB.FGS  AS SEPT_CORP_NAME
			,T2.FUND_ACCOUNT AS CPTL_ACCT
			,CONVERT(VARCHAR,T2.OPEN_DATE)  AS SECU_ACCT_OACT_DT--证券账户开户日期
			,SUM(CONVERT(DOUBLE,T1.YWFY)*T3.TURN_RMB) AS OACT_FEE_PAYOUT --开户费支出
			,@V_BIN_DATE --增加清洗日期
			
		FROM DBA.T_EDW_CSS_KH_YWLS_CL T1
		LEFT JOIN
		(
			SELECT
				T1.BRANCH_NO
				,T1.FUND_ACCOUNT
				,T1.CLIENT_ID
				,T1.STOCK_ACCOUNT
				,MIN(T1.OPEN_DATE) AS OPEN_DATE	--不同市场开户日期不一致，取最小的
			FROM DBA.T_EDW_UF2_STOCKHOLDER T1
			WHERE T1.LOAD_DT=@V_BIN_DATE
			GROUP BY
				T1.BRANCH_NO
				,T1.FUND_ACCOUNT
				,T1.CLIENT_ID
				,T1.STOCK_ACCOUNT
		) T2 ON T1.ZQZH=T2.STOCK_ACCOUNT
		LEFT JOIN DBA.T_EDW_T06_YEAR_EXCHANGE_RATE T3 ON T3.STATIS_YEAR=CONVERT(INT,@NIAN) AND T1.BZ=T3.CURR_TYPE_CD
		LEFT JOIN QUERY_SKB.YUNYING_08 YYB ON CONVERT(INT,T2.BRANCH_NO)=CONVERT(INT,YYB.JGBH_HS)
		WHERE T2.OPEN_DATE>=@ZRR_YC AND T2.OPEN_DATE<=@ZRR_YM		--根据董20170122只需清洗当月开户的数据即可	
			AND T1.JGDM='0000'	--处理成功
			AND T2.CLIENT_ID IS NOT NULL
		GROUP BY
		SUBSTRING(CONVERT(VARCHAR,T2.OPEN_DATE),0,6) 
			,T2.CLIENT_ID 
			,T1.ZQZH  
			,SUBSTRING(OACT_YEAR_MTH,5,6) 
			,SUBSTRING(OACT_YEAR_MTH,0,4) 
			,CONVERT(VARCHAR,T2.BRANCH_NO) 
			,YYB.JGBH 
			,YYB.JGMC 
			,YYB.FGS  
			,T2.FUND_ACCOUNT
			,CONVERT(VARCHAR,T2.OPEN_DATE)
		
);
COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_CUST_OACT_FEE TO query_dev
GO
GRANT EXECUTE ON dm.P_EVT_CUST_OACT_FEE TO xydc
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_CRED_INCM_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户信用收入月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户信用收入月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
               20180415               dcy                    董将字段全重新修改
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);


--PART0 删除当月数据
  DELETE FROM DM.T_EVT_EMPCUS_CRED_INCM_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    
    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;


	 SELECT
 		T1.YEAR AS YEAR
 		,T1.MTH AS MTH 
		,T1.OCCUR_DT AS OCCUR_DT
 		,T1.CUST_ID  AS CUST_ID
 		,SUM(COALESCE(T2.GROSS_CMS,0)) AS GROSS_CMS
		,SUM(COALESCE(T2.NET_CMS,0)) AS NET_CMS
		,SUM(COALESCE(T2.TRAN_FEE,0)) AS TRAN_FEE
		,SUM(COALESCE(T2.STP_TAX,0)) AS STP_TAX
		,SUM(COALESCE(T2.ORDR_FEE,0)) AS ORDR_FEE
		,SUM(COALESCE(T2.HANDLE_FEE,0)) AS HANDLE_FEE
		,SUM(COALESCE(T2.SEC_RGLT_FEE,0)) AS SEC_RGLT_FEE
		,SUM(COALESCE(T2.OTH_FEE,0)) AS OTH_FEE
		,SUM(COALESCE(T2.CREDIT_ODI_CMS,0)) AS CREDIT_ODI_CMS
		,SUM(COALESCE(T2.CREDIT_ODI_NET_CMS,0)) AS CREDIT_ODI_NET_CMS
		,SUM(COALESCE(T2.CREDIT_ODI_TRAN_FEE,0)) AS CREDIT_ODI_TRAN_FEE
		,SUM(COALESCE(T2.CREDIT_CRED_CMS,0)) AS CREDIT_CRED_CMS
		,SUM(COALESCE(T2.CREDIT_CRED_NET_CMS,0)) AS CREDIT_CRED_NET_CMS
		,SUM(COALESCE(T2.CREDIT_CRED_TRAN_FEE,0)) AS CREDIT_CRED_TRAN_FEE
		,SUM(COALESCE(T2.STKPLG_CMS,0)) AS STKPLG_CMS
		,SUM(COALESCE(T2.STKPLG_NET_CMS,0)) AS STKPLG_NET_CMS
		,SUM(COALESCE(T2.STKPLG_PAIDINT,0)) AS STKPLG_PAIDINT
		,SUM(COALESCE(T2.STKPLG_RECE_INT,0)) AS STKPLG_RECE_INT
		,SUM(COALESCE(T2.APPTBUYB_CMS,0)) AS APPTBUYB_CMS
		,SUM(COALESCE(T2.APPTBUYB_NET_CMS,0)) AS APPTBUYB_NET_CMS
		,SUM(COALESCE(T2.APPTBUYB_PAIDINT,0)) AS APPTBUYB_PAIDINT
		,SUM(COALESCE(T2.FIN_RECE_INT,0)) AS FIN_RECE_INT
		,SUM(COALESCE(T2.FIN_PAIDINT,0)) AS FIN_PAIDINT
		,SUM(COALESCE(T2.MTH_FIN_IE,0)) AS MTH_FIN_IE
		,SUM(COALESCE(T2.MTH_CRDT_STK_IE,0)) AS MTH_CRDT_STK_IE
		,SUM(COALESCE(T2.MTH_OTH_IE,0)) AS MTH_OTH_IE
		,SUM(COALESCE(T2.MTH_FIN_RECE_INT,0)) AS MTH_FIN_RECE_INT
		,SUM(COALESCE(T2.MTH_FEE_RECE_INT,0)) AS MTH_FEE_RECE_INT
		,SUM(COALESCE(T2.MTH_OTH_RECE_INT,0)) AS MTH_OTH_RECE_INT
		,SUM(COALESCE(T2.CREDIT_CPTL_COST,0)) AS CREDIT_CPTL_COST
		
		,SUM(COALESCE(T2.CREDIT_MARG_SPR_INCM,0)) AS CREDIT_MARG_SPR_INCM	
	INTO #TEMP_SUM	
 	FROM DM.T_EVT_CRED_INCM_M_D T1
 	LEFT JOIN DM.T_EVT_CRED_INCM_M_D T2 ON T1.CUST_ID=T2.CUST_ID AND T1.YEAR=T2.YEAR AND T1.OCCUR_DT>=T2.OCCUR_DT
	WHERE T1.OCCUR_DT=@V_BIN_DATE 
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	   AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
 	GROUP BY
 		T1.YEAR
 		,T1.MTH
		,T1.OCCUR_DT
 		,T1.CUST_ID;
  
	INSERT INTO DM.T_EVT_EMPCUS_CRED_INCM_M_D 
	(
	 YEAR                      --年
    ,MTH                       --月
	,OCCUR_DT                  --业务日期
    ,CUST_ID                   --客户编码
    ,AFA_SEC_EMPID             --AFA_二期员工号
    ,YEAR_MTH                  --年月
    ,MAIN_CPTL_ACCT            --主资金账号
    ,YEAR_MTH_CUST_ID          --年月客户编码
    ,YEAR_MTH_PSN_JNO          --年月员工号
    ,WH_ORG_ID_CUST            --仓库机构编码_客户
    ,WH_ORG_ID_EMP             --仓库机构编码_员工
    ,GROSS_CMS_MTD             --毛佣金_月累计
    ,NET_CMS_MTD               --净佣金_月累计
    ,TRAN_FEE_MTD              --过户费_月累计
    ,STP_TAX_MTD               --印花税_月累计
    ,ORDR_FEE_MTD              --委托费_月累计
    ,HANDLE_FEE_MTD            --经手费_月累计
    ,SEC_RGLT_FEE_MTD          --证管费_月累计
    ,OTH_FEE_MTD               --其他费用_月累计
    ,CREDIT_ODI_CMS_MTD        --融资融券普通佣金_月累计
    ,CREDIT_ODI_NET_CMS_MTD    --融资融券普通净佣金_月累计
    ,CREDIT_ODI_TRAN_FEE_MTD   --融资融券普通过户费_月累计
    ,CREDIT_CRED_CMS_MTD       --融资融券信用佣金_月累计
    ,CREDIT_CRED_NET_CMS_MTD   --融资融券信用净佣金_月累计
    ,CREDIT_CRED_TRAN_FEE_MTD  --融资融券信用过户费_月累计
    ,STKPLG_CMS_MTD            --股票质押佣金_月累计
    ,STKPLG_NET_CMS_MTD        --股票质押净佣金_月累计
    ,STKPLG_PAIDINT_MTD        --股票质押实收利息_月累计
    ,STKPLG_RECE_INT_MTD       --股票质押应收利息_月累计
    ,APPTBUYB_CMS_MTD          --约定购回佣金_月累计
    ,APPTBUYB_NET_CMS_MTD      --约定购回净佣金_月累计
    ,APPTBUYB_PAIDINT_MTD      --约定购回实收利息_月累计
    ,FIN_PAIDINT_MTD           --融资实收利息_月累计
    ,FIN_IE_MTD                --融资利息支出_月累计
    ,CRDT_STK_IE_MTD           --融券利息支出_月累计
    ,OTH_IE_MTD                --其他利息支出_月累计
    ,FIN_RECE_INT_MTD          --融资应收利息_月累计
    ,FEE_RECE_INT_MTD          --费用应收利息_月累计
    ,OTH_RECE_INT_MTD          --其他应收利息_月累计
    ,CREDIT_CPTL_COST_MTD      --融资融券资金成本_月累计
    ,CREDIT_MARG_SPR_INCM_MTD  --融资融券保证金利差收入_月累计
    ,GROSS_CMS_YTD             --毛佣金_年累计
    ,NET_CMS_YTD               --净佣金_年累计
    ,TRAN_FEE_YTD              --过户费_年累计
    ,STP_TAX_YTD               --印花税_年累计
    ,ORDR_FEE_YTD              --委托费_年累计
    ,HANDLE_FEE_YTD            --经手费_年累计
    ,SEC_RGLT_FEE_YTD          --证管费_年累计
    ,OTH_FEE_YTD               --其他费用_年累计
    ,CREDIT_ODI_CMS_YTD        --融资融券普通佣金_年累计
    ,CREDIT_ODI_NET_CMS_YTD    --融资融券普通净佣金_年累计
    ,CREDIT_ODI_TRAN_FEE_YTD   --融资融券普通过户费_年累计
    ,CREDIT_CRED_CMS_YTD       --融资融券信用佣金_年累计
    ,CREDIT_CRED_NET_CMS_YTD   --融资融券信用净佣金_年累计
    ,CREDIT_CRED_TRAN_FEE_YTD  --融资融券信用过户费_年累计
    ,STKPLG_CMS_YTD            --股票质押佣金_年累计
    ,STKPLG_NET_CMS_YTD        --股票质押净佣金_年累计
    ,STKPLG_PAIDINT_YTD        --股票质押实收利息_年累计
    ,STKPLG_RECE_INT_YTD       --股票质押应收利息_年累计
    ,APPTBUYB_CMS_YTD          --约定购回佣金_年累计
    ,APPTBUYB_NET_CMS_YTD      --约定购回净佣金_年累计
    ,APPTBUYB_PAIDINT_YTD      --约定购回实收利息_年累计
    ,FIN_PAIDINT_YTD           --融资实收利息_年累计
    ,FIN_IE_YTD                --融资利息支出_年累计
    ,CRDT_STK_IE_YTD           --融券利息支出_年累计
    ,OTH_IE_YTD                --其他利息支出_年累计
    ,FIN_RECE_INT_YTD          --融资应收利息_年累计
    ,FEE_RECE_INT_YTD          --费用应收利息_年累计
    ,OTH_RECE_INT_YTD          --其他应收利息_年累计
    ,CREDIT_CPTL_COST_YTD      --融资融券资金成本_年累计
    ,CREDIT_MARG_SPR_INCM_YTD  --融资融券保证金利差收入_年累计
    ,LOAD_DT                   --清洗日期
)
SELECT 
	T2.YEAR AS 年
	,T2.MTH AS 月
	,T2.OCCUR_DT
	,T2.HS_CUST_ID AS 客户编码
	,T2.AFA_SEC_EMPID AS AFA_二期员工号	
	,T2.YEAR||T2.MTH AS 年月
	,T2.CPTL_ACCT AS 主资金账号
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID AS 年月客户编码
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS 年月员工号
	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工
	
	,COALESCE(T1.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 毛佣金_月累计
	,COALESCE(T1.NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 净佣金_月累计
	,COALESCE(T1.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 过户费_月累计
	,COALESCE(T1.STP_TAX,0)*COALESCE(T2.PERFM_RATI9,0) AS 印花税_月累计
	,COALESCE(T1.ORDR_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 委托费_月累计
	,COALESCE(T1.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 经手费_月累计
	,COALESCE(T1.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 证管费_月累计
	,COALESCE(T1.OTH_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 其他费用_月累计
	,COALESCE(T1.CREDIT_ODI_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券普通佣金_月累计
	,COALESCE(T1.CREDIT_ODI_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券普通净佣金_月累计
	,COALESCE(T1.CREDIT_ODI_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券普通过户费_月累计
	,COALESCE(T1.CREDIT_CRED_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券信用佣金_月累计
	,COALESCE(T1.CREDIT_CRED_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券信用净佣金_月累计
	,COALESCE(T1.CREDIT_CRED_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券信用过户费_月累计
	,COALESCE(T1.STKPLG_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押佣金_月累计
	,COALESCE(T1.STKPLG_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押净佣金_月累计
	,COALESCE(T1.STKPLG_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押实收利息_月累计
	,COALESCE(T1.STKPLG_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押应收利息_月累计
	,COALESCE(T1.APPTBUYB_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回佣金_月累计
	,COALESCE(T1.APPTBUYB_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回净佣金_月累计
	,COALESCE(T1.APPTBUYB_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回实收利息_月累计	
--	,COALESCE(T1.FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券应收利息合计_月累计
	,COALESCE(T1.FIN_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资实收利息_月累计
	,COALESCE(T1.MTH_FIN_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资利息支出_月累计
	,COALESCE(T1.MTH_CRDT_STK_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融券利息支出_月累计
	,COALESCE(T1.MTH_OTH_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS 其他利息支出_月累计
	,COALESCE(T1.MTH_FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资应收利息_月累计
	,COALESCE(T1.MTH_FEE_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 费用应收利息_月累计
	,COALESCE(T1.MTH_OTH_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 其他应收利息_月累计
	,COALESCE(T1.CREDIT_CPTL_COST,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券资金成本_月累计
	,COALESCE(T1.CREDIT_MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券保证金利差收入_月累计	

	,COALESCE(T_NIAN.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 毛佣金_年累计
	,COALESCE(T_NIAN.NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 净佣金_年累计
	,COALESCE(T_NIAN.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 过户费_年累计
	,COALESCE(T_NIAN.STP_TAX,0)*COALESCE(T2.PERFM_RATI9,0) AS 印花税_年累计
	,COALESCE(T_NIAN.ORDR_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 委托费_年累计
	,COALESCE(T_NIAN.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 经手费_年累计
	,COALESCE(T_NIAN.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 证管费_年累计
	,COALESCE(T_NIAN.OTH_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 其他费用_年累计
	,COALESCE(T_NIAN.CREDIT_ODI_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券普通佣金_年累计
	,COALESCE(T_NIAN.CREDIT_ODI_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券普通净佣金_年累计
	,COALESCE(T_NIAN.CREDIT_ODI_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券普通过户费_年累计
	,COALESCE(T_NIAN.CREDIT_CRED_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券信用佣金_年累计
	,COALESCE(T_NIAN.CREDIT_CRED_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券信用净佣金_年累计
	,COALESCE(T_NIAN.CREDIT_CRED_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券信用过户费_年累计
	,COALESCE(T_NIAN.STKPLG_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押佣金_年累计
	,COALESCE(T_NIAN.STKPLG_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押净佣金_年累计
	,COALESCE(T_NIAN.STKPLG_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押实收利息_年累计
	,COALESCE(T_NIAN.STKPLG_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 股票质押应收利息_年累计
	,COALESCE(T_NIAN.APPTBUYB_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回佣金_年累计
	,COALESCE(T_NIAN.APPTBUYB_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回净佣金_年累计
	,COALESCE(T_NIAN.APPTBUYB_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS 约定购回实收利息_年累计
--	,COALESCE(T_NIAN.FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券应收利息合计_年累计
	,COALESCE(T_NIAN.FIN_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资实收利息_年累计
	,COALESCE(T_NIAN.MTH_FIN_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资利息支出_年累计
	,COALESCE(T_NIAN.MTH_CRDT_STK_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS 融券利息支出_年累计
	,COALESCE(T_NIAN.MTH_OTH_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS 其他利息支出_年累计
	,COALESCE(T_NIAN.MTH_FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资应收利息_年累计
	,COALESCE(T_NIAN.MTH_FEE_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 费用应收利息_年累计
	,COALESCE(T_NIAN.MTH_OTH_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS 其他应收利息_年累计
	,COALESCE(T_NIAN.CREDIT_CPTL_COST,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券资金成本_年累计
	,COALESCE(T_NIAN.CREDIT_MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI9,0) AS 融资融券保证金利差收入_年累计
	,20171229
 FROM #T_PUB_SER_RELA T2 
LEFT JOIN DM.T_EVT_CRED_INCM_M_D T1 
	ON T1.YEAR=T2.YEAR 
		AND T1.OCCUR_DT=T2.OCCUR_DT 
		AND T1.CUST_ID=T2.HS_CUST_ID
LEFT JOIN #TEMP_SUM 	T_NIAN 
	ON T2.YEAR=T_NIAN.YEAR 
		AND T2.OCCUR_DT=T_NIAN.OCCUR_DT 
		AND T2.HS_CUST_ID=T_NIAN.CUST_ID 
WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	   AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
;
END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_CRED_INCM_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_NUM_M_D(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户数月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户数月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ; 
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT;  --自然日_月初
	DECLARE @V_BIN_NATRE_DAY_YEARBGN INT;  --自然日_年初
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
	
--PART0 删除当月数据
  DELETE FROM DM.T_EVT_EMPCUS_NUM_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

  --生成每日客户汇总
  SELECT  
     OUC.CLIENT_ID 	AS CUST_ID  --客户编码
	,@V_BIN_YEAR           	AS YEAR      --年
	,@V_BIN_MTH           	AS MTH       --月
	,@V_BIN_DATE            AS OCCUR_DT  --业务日期
	,OUF.FUND_ACCOUNT  		AS MAIN_CPTL_ACCT     --主资金账号（普通账户）
	,DOH.PK_ORG 	 		AS WH_ORG_ID          --仓库机构编码 
	,CONVERT(VARCHAR,OUC.BRANCH_NO) AS HS_ORG_ID  --恒生机构编码
    ,OUF.OPEN_DATE 					AS TE_OACT_DT   --最早开户日期
	
	INTO #T_PUB_CUST
	
	FROM DBA.T_EDW_UF2_CLIENT  			OUC   --所有客户信息
    LEFT JOIN DBA.T_edw_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID AND OUF.LOAD_DT=OUC.LOAD_dT AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --普通账户主资金账号
	LEFT JOIN DBA.T_DIM_ORG_HIS  		DOH ON CONVERT(VARCHAR,OUC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=OUC.LOAD_dT AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL    --有重复值
	WHERE OUC.BRANCH_NO NOT IN (5,55,51,44,9999)--20180207 新增：排除"总部专用账户"
      AND OUC.LOAD_DT=@V_BIN_DATE;

    -- 业务数据临时表
    SELECT 
		 T1.YEAR
		,T1.MTH
		,T1.YEAR||T1.MTH AS 年月
		,T1.OCCUR_DT
		,T1.YEAR||T1.MTH||T1.CUST_ID AS 年月客户编码
		,T1.CUST_ID AS 客户编码	
		,T1.WH_ORG_ID AS 仓库机构编码
		,CASE WHEN T1.TE_OACT_DT>@V_BIN_NATRE_DAY_MTHBEG  THEN 1 ELSE 0 END AS 是否月新增
		,CASE WHEN T1.TE_OACT_DT>@V_BIN_NATRE_DAY_YEARBGN THEN 1 ELSE 0 END AS 是否年新增
		INTO #TEMP_T1
	FROM #T_PUB_CUST T1
	WHERE T1.OCCUR_DT=@V_BIN_DATE
	       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH) --20180207 ZQ:有责权关系的客户必须要有资金账户
		   AND T1.HS_ORG_ID NOT IN ('5','55','51','44','9999'); --20180314 排除"总部专用账户"
		  
  
    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;
	 
  
  
	INSERT INTO DM.T_EVT_EMPCUS_NUM_M_D 
	(
	YEAR              --年
	,MTH              --月 
	,OCCUR_DT 			  --OCCUR_DT
	,CUST_ID          --客户编码 
	,AFA_SEC_EMPID    --AFA_二期员工号 
	,YEAR_MTH         --年月 
	,YEAR_MTH_CUST_ID --年月客户编码 
	,YEAR_MTH_PSN_JNO --年月员工编号 
	,WH_ORG_ID_CUST   --仓库机构编码_客户 
	,WH_ORG_ID_EMP    --仓库机构编码_员工 
	,IF_MTH_NA        --是否月新增 
	,IF_YEAR_NA       --是否年新增 
	,CUST_NUM         --客户数 
	,CUST_NUM_CRED    --客户数_信用
	,LOAD_DT          --清洗日期
	)
	SELECT
	T2.YEAR AS 年
	,T2.MTH AS 月
	,T2.OCCUR_DT
	,T2.HS_CUST_ID
	,T2.AFA_SEC_EMPID AS AFA_二期员工号
	,T2.YEAR||T2.MTH	
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS 年月员工编号
	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工	
	,T1.是否月新增
	,T1.是否年新增
	,T2.PERFM_RATI1 AS 客户数
	,T2.PERFM_RATI9 AS 客户数_信用
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2
LEFT JOIN #TEMP_T1 T1 
	ON T1.occur_dt=t2.occur_dt 
	  AND T1.客户编码=T2.HS_CUST_ID
WHERE T2.AFA_SEC_EMPID IS NOT NULL
;

END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_NUM_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_ODI_INCM_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户普通收入月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户普通收入月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
              20180415                  DCY                董重新更改字段
  
           
  *********************************************************************/

   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	
  --PART0 删除当月数据
  DELETE FROM DM.T_EVT_EMPCUS_ODI_INCM_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz)      as MEMO,
		   max(ygxm)    as EMP_NAME,
		   sum(jxbl1)   as PERFM_RATI1,
		   sum(jxbl2)   as PERFM_RATI2,
		   sum(jxbl3)   as PERFM_RATI3,
		   sum(jxbl4)   as PERFM_RATI4,
		   sum(jxbl5)   as PERFM_RATI5,
		   sum(jxbl6)   as PERFM_RATI6,
		   sum(jxbl7)   as PERFM_RATI7,
		   sum(jxbl8)   as PERFM_RATI8,
		   sum(jxbl9)   as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE;

	 --业务数据临时表
	 SELECT
 		T1.YEAR
 		,T1.MTH
		,T1.OCCUR_DT
 		,T1.CUST_ID
 		,SUM(COALESCE(T2.GROSS_CMS,0)) AS GROSS_CMS
		,SUM(COALESCE(T2.TRAN_FEE,0)) AS TRAN_FEE
		,SUM(COALESCE(T2.SCDY_TRAN_FEE,0)) AS SCDY_TRAN_FEE
		,SUM(COALESCE(T2.STP_TAX,0)) AS STP_TAX
		,SUM(COALESCE(T2.HANDLE_FEE,0)) AS HANDLE_FEE
		,SUM(COALESCE(T2.SEC_RGLT_FEE,0)) AS SEC_RGLT_FEE
		,SUM(COALESCE(T2.OTH_FEE,0)) AS OTH_FEE
		,SUM(COALESCE(T2.STKF_CMS,0)) AS STKF_CMS
		,SUM(COALESCE(T2.STKF_TRAN_FEE,0)) AS STKF_TRAN_FEE
		,SUM(COALESCE(T2.STKF_NET_CMS,0)) AS STKF_NET_CMS
		,SUM(COALESCE(T2.BOND_CMS,0)) AS BOND_CMS
		,SUM(COALESCE(T2.BOND_NET_CMS,0)) AS BOND_NET_CMS
		,SUM(COALESCE(T2.REPQ_CMS,0)) AS REPQ_CMS
		,SUM(COALESCE(T2.REPQ_NET_CMS,0)) AS REPQ_NET_CMS
		,SUM(COALESCE(T2.HGT_CMS,0)) AS HGT_CMS
		,SUM(COALESCE(T2.HGT_NET_CMS,0)) AS HGT_NET_CMS
		,SUM(COALESCE(T2.HGT_TRAN_FEE,0)) AS HGT_TRAN_FEE
		,SUM(COALESCE(T2.SGT_CMS,0)) AS SGT_CMS
		,SUM(COALESCE(T2.SGT_NET_CMS,0)) AS SGT_NET_CMS
		,SUM(COALESCE(T2.SGT_TRAN_FEE,0)) AS SGT_TRAN_FEE
		,SUM(COALESCE(T2.BGDL_CMS,0)) AS BGDL_CMS
		,SUM(COALESCE(T2.NET_CMS,0)) AS NET_CMS
		,SUM(COALESCE(T2.BGDL_NET_CMS,0)) AS BGDL_NET_CMS
		,SUM(COALESCE(T2.BGDL_TRAN_FEE,0)) AS BGDL_TRAN_FEE
		,SUM(COALESCE(T2.PSTK_OPTN_CMS,0)) AS PSTK_OPTN_CMS
		,SUM(COALESCE(T2.PSTK_OPTN_NET_CMS,0)) AS PSTK_OPTN_NET_CMS
		,SUM(COALESCE(T2.SCDY_CMS,0)) AS SCDY_CMS
		,SUM(COALESCE(T2.SCDY_NET_CMS,0)) AS SCDY_NET_CMS
		--20180411新增
		,SUM(COALESCE(T2.PB_TRD_CMS,0)) AS PB_TRD_CMS
		,SUM(COALESCE(T2.MARG_SPR_INCM,0)) AS MARG_SPR_INCM
        
	INTO #TEMP_T1
 	FROM DM.T_EVT_ODI_INCM_M_D T1
 	LEFT JOIN DM.T_EVT_ODI_INCM_M_D T2 ON T1.CUST_ID=T2.CUST_ID AND T1.YEAR=T2.YEAR AND T1.OCCUR_DT>=T2.OCCUR_DT
	WHERE T1.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	   AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
 	GROUP BY
 		T1.YEAR
 		,T1.MTH
		,T1.OCCUR_DT
 		,T1.CUST_ID;
	 
INSERT INTO DM.T_EVT_EMPCUS_ODI_INCM_M_D 
(
	 YEAR                   --年    
    ,MTH                    --月
	,OCCUR_DT
    ,CUST_ID                --客户编码
    ,AFA_SEC_EMPID          --AFA_二期员工号
    ,YEAR_MTH               --年月
    ,MAIN_CPTL_ACCT         --主资金账号
    ,YEAR_MTH_CUST_ID       --年月客户编码
    ,YEAR_MTH_PSN_JNO       --年月员工号
    ,WH_ORG_ID_CUST         --仓库机构编码_客户
    ,WH_ORG_ID_EMP          --仓库机构编码_员工
    ,GROSS_CMS_MTD          --毛佣金_月累计
    ,TRAN_FEE_MTD           --过户费_月累计
    ,SCDY_TRAN_FEE_MTD      --二级过户费_月累计
    ,STP_TAX_MTD            --印花税_月累计
    ,HANDLE_FEE_MTD         --经手费_月累计
    ,SEC_RGLT_FEE_MTD       --证管费_月累计
    ,OTH_FEE_MTD            --其他费用_月累计
    ,STKF_CMS_MTD           --股基佣金_月累计
    ,STKF_TRAN_FEE_MTD      --股基过户费_月累计
    ,STKF_NET_CMS_MTD       --股基净佣金_月累计
    ,BOND_CMS_MTD           --债券佣金_月累计
    ,BOND_NET_CMS_MTD       --债券净佣金_月累计
    ,REPQ_CMS_MTD           --报价回购佣金_月累计
    ,REPQ_NET_CMS_MTD       --报价回购净佣金_月累计
    ,HGT_CMS_MTD            --沪港通佣金_月累计
    ,HGT_NET_CMS_MTD        --沪港通净佣金_月累计
    ,HGT_TRAN_FEE_MTD       --沪港通过户费_月累计
    ,SGT_CMS_MTD            --深港通佣金_月累计
    ,SGT_NET_CMS_MTD        --深港通净佣金_月累计
    ,SGT_TRAN_FEE_MTD       --深港通过户费_月累计
    ,BGDL_CMS_MTD           --大宗交易佣金_月累计
    ,NET_CMS_MTD            --净佣金_月累计
    ,BGDL_NET_CMS_MTD       --大宗交易净佣金_月累计
    ,BGDL_TRAN_FEE_MTD      --大宗交易过户费_月累计
    ,PSTK_OPTN_CMS_MTD      --个股期权佣金_月累计
    ,PSTK_OPTN_NET_CMS_MTD  --个股期权净佣金_月累计
    ,SCDY_CMS_MTD           --二级佣金_月累计
    ,SCDY_NET_CMS_MTD       --二级净佣金_月累计
    ,PB_TRD_CMS_MTD         --PB交易佣金_月累计
    ,MARG_SPR_INCM_MTD      --保证金利差收入_月累计
    ,GROSS_CMS_YTD          --毛佣金_年累计
    ,TRAN_FEE_YTD           --过户费_年累计
    ,SCDY_TRAN_FEE_YTD      --二级过户费_年累计
    ,STP_TAX_YTD            --印花税_年累计
    ,HANDLE_FEE_YTD         --经手费_年累计
    ,SEC_RGLT_FEE_YTD       --证管费_年累计
    ,OTH_FEE_YTD            --其他费用_年累计
    ,STKF_CMS_YTD           --股基佣金_年累计
    ,STKF_TRAN_FEE_YTD      --股基过户费_年累计
    ,STKF_NET_CMS_YTD       --股基净佣金_年累计
    ,BOND_CMS_YTD           --债券佣金_年累计
    ,BOND_NET_CMS_YTD       --债券净佣金_年累计
    ,REPQ_CMS_YTD           --报价回购佣金_年累计
    ,REPQ_NET_CMS_YTD       --报价回购净佣金_年累计
    ,HGT_CMS_YTD            --沪港通佣金_年累计
    ,HGT_NET_CMS_YTD        --沪港通净佣金_年累计
    ,HGT_TRAN_FEE_YTD       --沪港通过户费_年累计
    ,SGT_CMS_YTD            --深港通佣金_年累计
    ,SGT_NET_CMS_YTD        --深港通净佣金_年累计
    ,SGT_TRAN_FEE_YTD       --深港通过户费_年累计
    ,BGDL_CMS_YTD           --大宗交易佣金_年累计
    ,NET_CMS_YTD            --净佣金_年累计
    ,BGDL_NET_CMS_YTD       --大宗交易净佣金_年累计
    ,BGDL_TRAN_FEE_YTD      --大宗交易过户费_年累计
    ,PSTK_OPTN_CMS_YTD      --个股期权佣金_年累计
    ,PSTK_OPTN_NET_CMS_YTD  --个股期权净佣金_年累计
    ,SCDY_CMS_YTD           --二级佣金_年累计
    ,SCDY_NET_CMS_YTD       --二级净佣金_年累计
    ,PB_TRD_CMS_YTD         --PB交易佣金_年累计
    ,MARG_SPR_INCM_YTD      --保证金利差收入_年累计
    ,LOAD_DT                --清洗日期
)

SELECT 
	T2.YEAR AS 年
	,T2.MTH AS 月
	,T2.OCCUR_DT
	,T2.HS_CUST_ID AS 客户编码
	,T2.AFA_SEC_EMPID AS AFA二期员工号
	,T2.YEAR||T1.MTH AS 年月
	,T2.CPTL_ACCT AS 主资金账号
	,T2.YEAR||T1.MTH||T2.HS_CUST_ID AS 年月客户编号
	,T2.YEAR||T1.MTH||T2.AFA_SEC_EMPID AS 年月员工号
	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工
	
	,COALESCE(T1.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 毛佣金_月累计
	,COALESCE(T1.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 过户费_月累计
	,COALESCE(T1.SCDY_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 二级过户费_月累计
	,COALESCE(T1.STP_TAX,0)*COALESCE(T2.PERFM_RATI2,0) AS 印花税_月累计
	,COALESCE(T1.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 经手费_月累计
	,COALESCE(T1.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 证管费_月累计
	,COALESCE(T1.OTH_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 其他费用_月累计
	,COALESCE(T1.STKF_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 股基佣金_月累计
	,COALESCE(T1.STKF_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 股基过户费_月累计
	,COALESCE(T1.STKF_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 股基净佣金_月累计
	,COALESCE(T1.BOND_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 债券佣金_月累计
	,COALESCE(T1.BOND_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 债券净佣金_月累计
	,COALESCE(T1.REPQ_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 报价回购佣金_月累计
	,COALESCE(T1.REPQ_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 报价回购净佣金_月累计
	,COALESCE(T1.HGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 沪港通佣金_月累计
	,COALESCE(T1.HGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 沪港通净佣金_月累计
	,COALESCE(T1.HGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 沪港通过户费_月累计
	,COALESCE(T1.SGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 深港通佣金_月累计
	,COALESCE(T1.SGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 深港通净佣金_月累计
	,COALESCE(T1.SGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 深港通过户费_月累计
	,COALESCE(T1.BGDL_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 大宗交易佣金_月累计
	,COALESCE(T1.NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 净佣金_月累计
	,COALESCE(T1.BGDL_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 大宗交易净佣金_月累计
	,COALESCE(T1.BGDL_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 大宗交易过户费_月累计
	,COALESCE(T1.PSTK_OPTN_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 个股期权佣金_月累计
	,COALESCE(T1.PSTK_OPTN_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 个股期权净佣金_月累计
	,COALESCE(T1.SCDY_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 二级佣金_月累计
	,COALESCE(T1.SCDY_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 二级净佣金_月累计
	
	,COALESCE(T1.PB_TRD_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS PB交易佣金_月累计
	,COALESCE(T1.MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI2,0) AS 保证金利差收入_月累计
	
	,COALESCE(T_NIAN.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 毛佣金_年累计
	,COALESCE(T_NIAN.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 过户费_年累计
	,COALESCE(T_NIAN.SCDY_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 二级过户费_年累计
	,COALESCE(T_NIAN.STP_TAX,0)*COALESCE(T2.PERFM_RATI2,0) AS 印花税_年累计
	,COALESCE(T_NIAN.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 经手费_年累计
	,COALESCE(T_NIAN.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 证管费_年累计
	,COALESCE(T_NIAN.OTH_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 其他费用_年累计
	,COALESCE(T_NIAN.STKF_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 股基佣金_年累计
	,COALESCE(T_NIAN.STKF_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 股基过户费_年累计
	,COALESCE(T_NIAN.STKF_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 股基净佣金_年累计
	,COALESCE(T_NIAN.BOND_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 债券佣金_年累计
	,COALESCE(T_NIAN.BOND_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 债券净佣金_年累计
	,COALESCE(T_NIAN.REPQ_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 报价回购佣金_年累计
	,COALESCE(T_NIAN.REPQ_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 报价回购净佣金_年累计
	,COALESCE(T_NIAN.HGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 沪港通佣金_年累计
	,COALESCE(T_NIAN.HGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 沪港通净佣金_年累计
	,COALESCE(T_NIAN.HGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 沪港通过户费_年累计
	,COALESCE(T_NIAN.SGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 深港通佣金_年累计
	,COALESCE(T_NIAN.SGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 深港通净佣金_年累计
	,COALESCE(T_NIAN.SGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 深港通过户费_年累计
	,COALESCE(T_NIAN.BGDL_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 大宗交易佣金_年累计
	,COALESCE(T_NIAN.NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 净佣金_年累计
	,COALESCE(T_NIAN.BGDL_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 大宗交易净佣金_年累计
	,COALESCE(T_NIAN.BGDL_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS 大宗交易过户费_年累计
	,COALESCE(T_NIAN.PSTK_OPTN_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 个股期权佣金_年累计
	,COALESCE(T_NIAN.PSTK_OPTN_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 个股期权净佣金_年累计
	,COALESCE(T_NIAN.SCDY_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 二级佣金_年累计
	,COALESCE(T_NIAN.SCDY_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS 二级净佣金_年累计

	,COALESCE(T_NIAN.PB_TRD_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS PB交易佣金_年累计
	,COALESCE(T_NIAN.MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI2,0) AS 保证金利差收入_年累计
	,@V_BIN_DATE
 FROM #T_PUB_SER_RELA T2
 LEFT JOIN #TEMP_T1 T_NIAN 
 	ON T2.OCCUR_DT=T_NIAN.OCCUR_DT 
 		AND T2.HS_CUST_ID=T_NIAN.CUST_ID
 LEFT JOIN DM.T_EVT_ODI_INCM_M_D T1
 	ON  T1.occur_dt=T2.occur_dt 
 		AND T1.CUST_ID=T2.HS_CUST_ID   
 WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	   AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
;

END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_ODI_INCM_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_ODI_TRD_M_D(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户普通交易月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户普通交易月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 删除当月数据
  DELETE FROM DM.T_EVT_EMPCUS_ODI_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;


	 
INSERT INTO DM.T_EVT_EMPCUS_ODI_TRD_M_D 
(
	 YEAR                --年  
	,MTH                 --月
	,OCCUR_DT            --业务日期
	,CUST_ID             --客户编码
	,AFA_SEC_EMPID       --AFA_二期员工号
	,YEAR_MTH            --年月
	,MAIN_CPTL_ACCT      --主资金账号
	,YEAR_MTH_CUST_ID    --年月客户编码
	,YEAR_MTH_PSN_JNO    --年月员工号
	,WH_ORG_ID_CUST      --仓库机构编码_客户
	,WH_ORG_ID_EMP       --仓库机构编码_员工
	,EQT_CLAS_KEPP_PERCN --权益类持仓占比
	,SCDY_TRD_FREQ       --二级交易次数
	,RCT_TRD_DT_GT       --最近交易日期_累计
	,SCDY_TRD_QTY        --二级交易量
	,SCDY_TRD_QTY_TY     --二级交易量_本年
	,TRD_FREQ_TY         --交易次数_本年
	,STKF_TRD_QTY        --股基交易量
	,STKF_TRD_QTY_TY     --股基交易量_本年
	,S_REPUR_TRD_QTY     --正回购交易量
	,R_REPUR_TRD_QTY     --逆回购交易量
	,S_REPUR_TRD_QTY_TY  --正回购交易量_本年
	,R_REPUR_TRD_QTY_TY  --逆回购交易量_本年
	,HGT_TRD_QTY         --沪港通交易量
	,SGT_TRD_QTY         --深港通交易量
	,SGT_TRD_QTY_TY      --深港通交易量_本年
	,HGT_TRD_QTY_TY      --沪港通交易量_本年
	,Y_RCT_STK_TRD_QTY   --近12月股票交易量
	,SCDY_TRD_FREQ_TY    --二级交易次数_本年
	,TRD_FREQ            --交易次数
	,APPTBUYB_TRD_QTY    --约定购回交易量
	,APPTBUYB_TRD_QTY_TY --约定购回交易量_本年
	,RCT_TRD_DT_M        --最近交易日期_本月
	,STKPLG_TRD_QTY      --股票质押交易量
	,STKPLG_TRD_QTY_TY   --股票质押交易量_本年
	,PSTK_OPTN_TRD_QTY   --个股期权交易量
	,PSTK_OPTN_TRD_QTY_TY--个股期权交易量_本年
	,GROSS_CMS           --毛佣金
	,NET_CMS             --净佣金
	,REPQ_TRD_QTY        --报价回购交易量
	,REPQ_TRD_QTY_TY     --报价回购交易量_本年
	,BGDL_QTY            --大宗交易量
	,BGDL_QTY_TY         --大宗交易量_本年
	,LOAD_DT             --清洗日期

)
SELECT 
	T1.YEAR AS 年
	,T1.MTH AS 月
	,T1.OCCUR_DT
	,T1.CUST_ID AS 客户编码
	,T2.AFA_SEC_EMPID AS AFA_二期员工号
	,T1.YEAR||T1.MTH AS 年月
	,T1.MAIN_CPTL_ACCT AS 主资金账号
	,T1.YEAR||T1.MTH||T1.CUST_ID AS 年月客户编号
	,T1.YEAR||T1.MTH||T2.AFA_SEC_EMPID AS 年月员工号
	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工
	
	,T1.EQT_CLAS_KEPP_PERCN*PERFM_RATI3 AS 权益类持仓占比
	,T1.SCDY_TRD_FREQ*PERFM_RATI3 AS 二级交易次数
	,T1.RCT_TRD_DT_GT*PERFM_RATI3 AS 最近交易日期_累计
	,T1.SCDY_TRD_QTY*PERFM_RATI3 AS 二级交易量
	,T1.SCDY_TRD_QTY_TY*PERFM_RATI3 AS 二级交易量_本年
	,T1.TRD_FREQ_TY*PERFM_RATI3 AS 交易次数_本年
	,T1.STKF_TRD_QTY*PERFM_RATI3 AS 股基交易量
	,T1.STKF_TRD_QTY_TY*PERFM_RATI3 AS 股基交易量_本年
	,T1.S_REPUR_TRD_QTY*PERFM_RATI3 AS 正回购交易量
	,T1.R_REPUR_TRD_QTY*PERFM_RATI3 AS 逆回购交易量
	,T1.S_REPUR_TRD_QTY_TY*PERFM_RATI3 AS 正回购交易量_本年
	,T1.R_REPUR_TRD_QTY_TY*PERFM_RATI3 AS 逆回购交易量_本年
	,T1.HGT_TRD_QTY*PERFM_RATI3 AS 沪港通交易量
	,T1.SGT_TRD_QTY*PERFM_RATI3 AS 深港通交易量
	,T1.SGT_TRD_QTY_TY*PERFM_RATI3 AS 深港通交易量_本年
	,T1.HGT_TRD_QTY_TY*PERFM_RATI3 AS 沪港通交易量_本年
	,T1.Y_RCT_STK_TRD_QTY*PERFM_RATI3 AS 近12月股票交易量
	,T1.SCDY_TRD_FREQ_TY*PERFM_RATI3 AS 二级交易次数_本年
	,T1.TRD_FREQ*PERFM_RATI3 AS 交易次数
	,T1.APPTBUYB_TRD_QTY*PERFM_RATI3 AS 约定购回交易量
	,T1.APPTBUYB_TRD_QTY_TY*PERFM_RATI3 AS 约定购回交易量_本年
	,T1.RCT_TRD_DT_M*PERFM_RATI3 AS 最近交易日期_本月
	,T1.STKPLG_TRD_QTY*PERFM_RATI3 AS 股票质押交易量
	,T1.STKPLG_TRD_QTY_TY*PERFM_RATI3 AS 股票质押交易量_本年
	,T1.PSTK_OPTN_TRD_QTY*PERFM_RATI3 AS 个股期权交易量
	,T1.PSTK_OPTN_TRD_QTY_TY*PERFM_RATI3 AS 个股期权交易量_本年
	,T1.GROSS_CMS*PERFM_RATI3 AS 毛佣金
	,T1.NET_CMS*PERFM_RATI3 AS 净佣金
	,T1.REPQ_TRD_QTY*PERFM_RATI3 AS 报价回购交易量
	,T1.REPQ_TRD_QTY_TY*PERFM_RATI3 AS 报价回购交易量_本年
	,T1.BGDL_QTY*PERFM_RATI3 AS 大宗交易量
	,T1.BGDL_QTY_TY*PERFM_RATI3 AS 大宗交易量_本年
	,@V_BIN_DATE
 FROM DM.T_EVT_CUS_ODI_TRD_M_D T1
 LEFT JOIN #T_PUB_SER_RELA T2 ON T1.occur_dt=t2.occur_dt AND T1.CUST_ID=T2.HS_CUST_ID 
 WHERE T1.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	    AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
;

END
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_PROD_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户产品交易月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户产品交易月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
              20180322                  dcy                新增续作四个变量
  *********************************************************************/

   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	
	--PART0 删除当月数据
	  DELETE FROM DM.T_EVT_EMPCUS_PROD_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

   ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;


	 
	INSERT INTO DM.T_EVT_EMPCUS_PROD_TRD_M_D 
	(
	 YEAR                      --年
	,MTH                       --月
	,OCCUR_DT                  --业务日期
	,CUST_ID                   --客户编码
	,PROD_CD                   --产品代码
	,PROD_TYPE                 --产品类型
	,AFA_SEC_EMPID             --AFA_二期员工号
	,YEAR_MTH                  --年月
	,YEAR_MTH_CUST_ID          --年月客户编码
	,YEAR_MTH_PSN_JNO          --年月员工号
	,YEAR_MTH_CUST_ID_PROD_CD  --年月客户编码产品代码
	,WH_ORG_ID_CUST            --仓库机构编码_客户
	,WH_ORG_ID_EMP             --仓库机构编码_员工
	,ITC_RETAIN_AMT_FINAL      --场内保有金额_期末
	,OTC_RETAIN_AMT_FINAL      --场外保有金额_期末
	,ITC_RETAIN_SHAR_FINAL     --场内保有份额_期末
	,OTC_RETAIN_SHAR_FINAL     --场外保有份额_期末
	,ITC_RETAIN_AMT_MDA        --场内保有金额_月日均
	,OTC_RETAIN_AMT_MDA        --场外保有金额_月日均
	,ITC_RETAIN_SHAR_MDA       --场内保有份额_月日均
	,OTC_RETAIN_SHAR_MDA       --场外保有份额_月日均
	,ITC_RETAIN_AMT_YDA        --场内保有金额_年日均
	,OTC_RETAIN_AMT_YDA        --场外保有金额_年日均
	,ITC_RETAIN_SHAR_YDA       --场内保有份额_年日均
	,OTC_RETAIN_SHAR_YDA       --场外保有份额_年日均
	,ITC_SUBS_AMT_MTD          --场内认购金额_月累计
	,ITC_PURS_AMT_MTD          --场内申购金额_月累计
	,ITC_BUYIN_AMT_MTD         --场内买入金额_月累计
	,ITC_REDP_AMT_MTD          --场内赎回金额_月累计
	,ITC_SELL_AMT_MTD          --场内卖出金额_月累计
	,OTC_SUBS_AMT_MTD          --场外认购金额_月累计
	,OTC_PURS_AMT_MTD          --场外申购金额_月累计
	,OTC_CASTSL_AMT_MTD        --场外定投金额_月累计
	,OTC_COVT_IN_AMT_MTD       --场外转换入金额_月累计
	,OTC_REDP_AMT_MTD          --场外赎回金额_月累计
	,OTC_COVT_OUT_AMT_MTD      --场外转换出金额_月累计
	,ITC_SUBS_SHAR_MTD         --场内认购份额_月累计
	,ITC_PURS_SHAR_MTD         --场内申购份额_月累计
	,ITC_BUYIN_SHAR_MTD        --场内买入份额_月累计
	,ITC_REDP_SHAR_MTD         --场内赎回份额_月累计
	,ITC_SELL_SHAR_MTD         --场内卖出份额_月累计
	,OTC_SUBS_SHAR_MTD         --场外认购份额_月累计
	,OTC_PURS_SHAR_MTD         --场外申购份额_月累计
	,OTC_CASTSL_SHAR_MTD       --场外定投份额_月累计
	,OTC_COVT_IN_SHAR_MTD      --场外转换入份额_月累计
	,OTC_REDP_SHAR_MTD         --场外赎回份额_月累计
	,OTC_COVT_OUT_SHAR_MTD     --场外转换出份额_月累计
	,ITC_SUBS_CHAG_MTD         --场内认购手续费_月累计
	,ITC_PURS_CHAG_MTD         --场内申购手续费_月累计
	,ITC_BUYIN_CHAG_MTD        --场内买入手续费_月累计
	,ITC_REDP_CHAG_MTD         --场内赎回手续费_月累计
	,ITC_SELL_CHAG_MTD         --场内卖出手续费_月累计
	,OTC_SUBS_CHAG_MTD         --场外认购手续费_月累计
	,OTC_PURS_CHAG_MTD         --场外申购手续费_月累计
	,OTC_CASTSL_CHAG_MTD       --场外定投手续费_月累计
	,OTC_COVT_IN_CHAG_MTD      --场外转换入手续费_月累计
	,OTC_REDP_CHAG_MTD         --场外赎回手续费_月累计
	,OTC_COVT_OUT_CHAG_MTD     --场外转换出手续费_月累计
	,ITC_SUBS_AMT_YTD          --场内认购金额_年累计
	,ITC_PURS_AMT_YTD          --场内申购金额_年累计
	,ITC_BUYIN_AMT_YTD         --场内买入金额_年累计
	,ITC_REDP_AMT_YTD          --场内赎回金额_年累计
	,ITC_SELL_AMT_YTD          --场内卖出金额_年累计
	,OTC_SUBS_AMT_YTD          --场外认购金额_年累计
	,OTC_PURS_AMT_YTD          --场外申购金额_年累计
	,OTC_CASTSL_AMT_YTD        --场外定投金额_年累计
	,OTC_COVT_IN_AMT_YTD       --场外转换入金额_年累计
	,OTC_REDP_AMT_YTD          --场外赎回金额_年累计
	,OTC_COVT_OUT_AMT_YTD      --场外转换出金额_年累计
	,ITC_SUBS_SHAR_YTD         --场内认购份额_年累计
	,ITC_PURS_SHAR_YTD         --场内申购份额_年累计
	,ITC_BUYIN_SHAR_YTD        --场内买入份额_年累计
	,ITC_REDP_SHAR_YTD         --场内赎回份额_年累计
	,ITC_SELL_SHAR_YTD         --场内卖出份额_年累计
	,OTC_SUBS_SHAR_YTD         --场外认购份额_年累计
	,OTC_PURS_SHAR_YTD         --场外申购份额_年累计
	,OTC_CASTSL_SHAR_YTD       --场外定投份额_年累计
	,OTC_COVT_IN_SHAR_YTD      --场外转换入份额_年累计
	,OTC_REDP_SHAR_YTD         --场外赎回份额_年累计
	,OTC_COVT_OUT_SHAR_YTD     --场外转换出份额_年累计
	,ITC_SUBS_CHAG_YTD         --场内认购手续费_年累计
	,ITC_PURS_CHAG_YTD         --场内申购手续费_年累计
	,ITC_BUYIN_CHAG_YTD        --场内买入手续费_年累计
	,ITC_REDP_CHAG_YTD         --场内赎回手续费_年累计
	,ITC_SELL_CHAG_YTD         --场内卖出手续费_年累计
	,OTC_SUBS_CHAG_YTD         --场外认购手续费_年累计
	,OTC_PURS_CHAG_YTD         --场外申购手续费_年累计
	,OTC_CASTSL_CHAG_YTD       --场外定投手续费_年累计
	,OTC_COVT_IN_CHAG_YTD      --场外转换入手续费_年累计
	,OTC_REDP_CHAG_YTD         --场外赎回手续费_年累计
	,OTC_COVT_OUT_CHAG_YTD     --场外转换出手续费_年累计
	,LOAD_DT                   --清洗日期
	,CONTD_SALE_SHAR_MTD       --续作销售份额_月累计
	,CONTD_SALE_AMT_MTD        --续作销售金额_月累计
	,CONTD_SALE_SHAR_YTD       --续作销售份额_年累计
	,CONTD_SALE_AMT_YTD        --续作销售金额_年累计

)
SELECT 
	 T2.YEAR AS 年
	,T2.MTH AS 月
	,T2.OCCUR_DT
	,T2.HS_CUST_ID AS 客户编码
	,T1.PROD_CD AS 产品代码
	,T1.PROD_TYPE AS 产品类型
	,T2.AFA_SEC_EMPID AS AFA二期员工号
	,T2.YEAR||T2.MTH AS 年月
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID AS 年月客户编码
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS 年月员工号
	,T2.YEAR||T2.MTH||T1.PROD_CD AS 年月客户编码产品代码
	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工	
	
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) END AS 场内保有金额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) END AS 场外保有金额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) END AS 场内保有份额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) END AS 场外保有份额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) END AS 场内保有金额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) END AS 场外保有金额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) END AS 场内保有份额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) END AS 场外保有份额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) END AS 场内保有金额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) END AS 场外保有金额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) END AS 场内保有份额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) END AS 场外保有份额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) END AS 场内认购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) END AS 场内申购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) END AS 场内买入金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) END AS 场内赎回金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) END AS 场内卖出金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) END AS 场外认购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) END AS 场外申购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) END AS 场外定投金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) END AS 场外转换入金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) END AS 场外赎回金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) END AS 场外转换出金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) END AS 场内认购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) END AS 场内申购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) END AS 场内买入份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) END AS 场内赎回份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) END AS 场内卖出份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) END AS 场外认购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) END AS 场外申购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) END AS 场外定投份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) END AS 场外转换入份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) END AS 场外赎回份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) END AS 场外转换出份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) END AS 场内认购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) END AS 场内申购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) END AS 场内买入手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) END AS 场内赎回手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) END AS 场内卖出手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) END AS 场外认购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) END AS 场外申购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) END AS 场外定投手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) END AS 场外转换入手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) END AS 场外赎回手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) END AS 场外转换出手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) END AS 场内认购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) END AS 场内申购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) END AS 场内买入金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) END AS 场内赎回金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) END AS 场内卖出金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) END AS 场外认购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) END AS 场外申购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) END AS 场外定投金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) END AS 场外转换入金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) END AS 场外赎回金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) END AS 场外转换出金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) END AS 场内认购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) END AS 场内申购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) END AS 场内买入份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) END AS 场内赎回份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) END AS 场内卖出份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) END AS 场外认购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) END AS 场外申购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) END AS 场外定投份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) END AS 场外转换入份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) END AS 场外赎回份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) END AS 场外转换出份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) END AS 场内认购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) END AS 场内申购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) END AS 场内买入手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) END AS 场内赎回手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) END AS 场内卖出手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) END AS 场外认购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) END AS 场外申购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) END AS 场外定投手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) END AS 场外转换入手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) END AS 场外赎回手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) END AS 场外转换出手续费_年累计
    ,@V_BIN_DATE
	
	--20180321 董新增加续作销售
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) END AS 续作销售份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) END AS 续作销售金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) END AS 续作销售份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) END AS 续作销售金额_年累计
FROM #T_PUB_SER_RELA T2
LEFT JOIN DM.T_EVT_PROD_TRD_M_D T1
	ON T1.occur_dt=t2.occur_dt 
		AND T1.CUST_ID=T2.HS_CUST_ID                                  
WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	   AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
		AND T1.PROD_CD IS NOT NULL
;

END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_PROD_TRD_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUST_OACT_FEE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 员工客户开户费表
  编写者: DCY 参考董依良提供的取数逻辑
  创建日期: 2018-01-17
  简介：
  *********************************************************************
  修订记录：   修订日期    修订人     修改内容简要说明
           
  *********************************************************************/
    DECLARE @NIAN VARCHAR(4);		--本月_年份
	DECLARE @YUE VARCHAR(2)	;		--本月_月份
	DECLARE @ZRR_NC INT;            --自然日_月初
	DECLARE @ZRR_YC INT;            --自然日_年初 
	DECLARE @TD_YM INT;				--月末
	DECLARE @NY INT;                --年月
	
	DECLARE @ZRR_YM INT;            --自然日_月末
	
	DECLARE @V_TAX NUMERIC(20,4);  --扣税参数
	
	
    SET @V_OUT_FLAG = -1;  --初始清洗赋值-1

    SET @NIAN=SUBSTR(@V_BIN_DATE||'',1,4);
	SET @YUE=SUBSTR(@V_BIN_DATE||'',5,2);
   	SET @ZRR_NC=(SELECT MIN(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.日期>=CONVERT(INT,@NIAN||'0101'));
	SET @ZRR_YC=(SELECT MIN(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.日期>=CONVERT(INT,@NIAN||@YUE||'01'));
	SET @TD_YM=(SELECT MAX(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.是否工作日='1' AND T1.日期<=CONVERT(INT,@NIAN||@YUE||'31'));
    SET @NY=CONVERT(INT,@NIAN||@YUE);
	
	SET @ZRR_YM=(SELECT MAX(T1.日期) FROM DBA.V_SKB_D_RQ T1 WHERE T1.日期<=CONVERT(INT,@NIAN||@YUE||'31'));
    
	SET @V_TAX=1.06; --根据需求来调整
	
/*
	
  --PART0 删除要回洗的数据
    DELETE FROM DM.T_EVT_EMPCUST_OACT_FEE WHERE OACT_YEAR_MTH=@NIAN||@YUE;
	
 
    --PART1 员工客户的开户费：一个月更新一个版本，重新清洗则只清洗每月最后一个交易日数据
	INSERT INTO DM.T_EVT_EMPCUST_OACT_FEE
	(
	 OACT_YEAR_MTH            --开户年月
	,CUST_ID                  --客户编码
	,AFA_SEC_EMPID            --AFA二期员工号
	,OPENACT_NUM              --开户数
	,OACT_FEE_PAYOUT          --开户费支出
	,OACT_FEE_PAYOUT_DR_TAX   --开户费支出_扣税
	,LOAD_DT                  --清洗日期
	)
(
	SELECT
		T1.KHNY AS OACT_YEAR_MTH	
		,T1.KHBH_HS AS CUST_ID
		,T_GX.AFATWO_YGH AS AFA_SEC_EMPID
		,SUM(T_GX.JXBL2) AS OPENACT_NUM
		,SUM(T1.YWFY*T_GX.JXBL2) AS OACT_FEE_PAYOUT             --开户费支出
		,SUM(T1.YWFY*T_GX.JXBL2)/@V_TAX AS OACT_FEE_PAYOUT_DR_TAX --开户费支出_扣税
		,@V_BIN_DATE  
	FROM
	(
		SELECT
			CONVERT(INT,T2.BRANCH_NO) AS JGBH_HS
			,YYB.JGBH
			,YYB.JGMC
			,YYB.FGS
			,T2.FUND_ACCOUNT AS ZJZH
			,T2.CLIENT_ID AS KHBH_HS
			,T0.ZQZH
			,T0.YWRQ
			,SUBSTRING(CONVERT(VARCHAR,T2.OPEN_DATE),0,6) AS KHNY
			,SUBSTRING(KHNY,0,4) AS NIAN
			,SUBSTRING(KHNY,5,6) AS YUE
			,CONVERT(DOUBLE,T0.YWFY)*T3.TURN_RMB AS YWFY
		FROM DBA.T_EDW_CSS_KH_YWLS_CL T0
		LEFT JOIN
		(
			SELECT
				T0.BRANCH_NO
				,T0.FUND_ACCOUNT
				,T0.CLIENT_ID
				,T0.STOCK_ACCOUNT
				,MIN(T0.OPEN_DATE) AS OPEN_DATE	--不同市场开户日期不一致，取最小的
			FROM DBA.T_EDW_UF2_STOCKHOLDER T0
			WHERE T0.LOAD_DT=@V_BIN_DATE
			GROUP BY
				T0.BRANCH_NO
				,T0.FUND_ACCOUNT
				,T0.CLIENT_ID
				,T0.STOCK_ACCOUNT
		) T2 ON T0.ZQZH=T2.STOCK_ACCOUNT
		LEFT JOIN DBA.T_EDW_T06_YEAR_EXCHANGE_RATE T3 ON T3.STATIS_YEAR=CONVERT(INT,@NIAN) AND T0.BZ=T3.CURR_TYPE_CD
		LEFT JOIN QUERY_SKB.YUNYING_08 YYB ON CONVERT(INT,T2.BRANCH_NO)=CONVERT(INT,YYB.JGBH_HS)
		WHERE T2.OPEN_DATE>=@ZRR_YC AND T2.OPEN_DATE<=@ZRR_YM			
			AND T0.JGDM='0000'	--处理成功
			AND T2.CLIENT_ID IS NOT NULL
	) T1	
	LEFT JOIN DBA.T_DDW_SERV_RELATION T_GX ON T_GX.NIAN=T1.NIAN AND T_GX.YUE=T1.YUE AND T1.KHBH_HS=T_GX.KHBH_HS
	LEFT JOIN QUERY_SKB.YUNYING_08 YYB_YG ON T_GX.JGBH_YG=YYB_YG.JGBH
	GROUP BY
		 T1.KHNY 	
		,T1.KHBH_HS
		,T_GX.AFATWO_YGH
);

COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0 

*/
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUST_OACT_FEE TO query_dev
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUST_OACT_FEE TO xydc
GO
CREATE PROCEDURE dm.P_EVT_INCM_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部收入表（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-11
  简介：营业部收入表（日表）
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_INCM_D_BRH WHERE OCCUR_DT = @V_DATE;

  	-- 员工-营业部关系
	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--员工编码
		,A.PK_ORG 		AS 		BRH_ID			--营业部编码
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  		AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	CREATE TABLE #TMP_T_EVT_INCM_D_BRH(
	    OCCUR_DT             	numeric(8,0) NOT NULL,
		BRH_ID               	varchar(30)  NOT NULL,
		EMP_ID		 			varchar(30)  NOT NULL,
		NET_CMS              	numeric(38,8) NULL,
		GROSS_CMS            	numeric(38,8) NULL,
		SCDY_CMS             	numeric(38,8) NULL,
		SCDY_NET_CMS         	numeric(38,8) NULL,
		SCDY_TRAN_FEE        	numeric(38,8) NULL,
		ODI_TRD_TRAN_FEE     	numeric(38,8) NULL,
		CRED_TRD_TRAN_FEE    	numeric(38,8) NULL,
		STKF_CMS             	numeric(38,8) NULL,
		STKF_TRAN_FEE        	numeric(38,8) NULL,
		STKF_NET_CMS         	numeric(38,8) NULL,
		BOND_CMS             	numeric(38,8) NULL,
		BOND_NET_CMS         	numeric(38,8) NULL,
		REPQ_CMS             	numeric(38,8) NULL,
		REPQ_NET_CMS         	numeric(38,8) NULL,
		HGT_CMS              	numeric(38,8) NULL,
		HGT_NET_CMS          	numeric(38,8) NULL,
		HGT_TRAN_FEE         	numeric(38,8) NULL,
		SGT_CMS              	numeric(38,8) NULL,
		SGT_NET_CMS          	numeric(38,8) NULL,
		SGT_TRAN_FEE         	numeric(38,8) NULL,
		BGDL_CMS             	numeric(38,8) NULL,
		BGDL_NET_CMS         	numeric(38,8) NULL,
		BGDL_TRAN_FEE        	numeric(38,8) NULL,
		PSTK_OPTN_CMS        	numeric(38,8) NULL,
		PSTK_OPTN_NET_CMS    	numeric(38,8) NULL,
		CREDIT_ODI_CMS       	numeric(38,8) NULL,
		CREDIT_ODI_NET_CMS   	numeric(38,8) NULL,
		CREDIT_ODI_TRAN_FEE  	numeric(38,8) NULL,
		CREDIT_CRED_CMS      	numeric(38,8) NULL,
		CREDIT_CRED_NET_CMS  	numeric(38,8) NULL,
		CREDIT_CRED_TRAN_FEE 	numeric(38,8) NULL,
		FIN_RECE_INT         	numeric(38,8) NULL,
		FIN_PAIDINT          	numeric(38,8) NULL,
		STKPLG_CMS           	numeric(38,8) NULL,
		STKPLG_NET_CMS       	numeric(38,8) NULL,
		STKPLG_PAIDINT       	numeric(38,8) NULL,
		STKPLG_RECE_INT      	numeric(38,8) NULL,
		APPTBUYB_CMS         	numeric(38,8) NULL,
		APPTBUYB_NET_CMS     	numeric(38,8) NULL,
		APPTBUYB_PAIDINT     	numeric(38,8) NULL,
		FIN_IE               	numeric(38,8) NULL,
		CRDT_STK_IE          	numeric(38,8) NULL,
		OTH_IE               	numeric(38,8) NULL,
		FEE_RECE_INT         	numeric(38,8) NULL,
		OTH_RECE_INT         	numeric(38,8) NULL,
		CREDIT_CPTL_COST     	numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_INCM_D_BRH(
		  OCCUR_DT             			--发生日期
		 ,BRH_ID               			--营业部编码
		 ,EMP_ID		 	   			--员工编码		
		 ,NET_CMS              			--净佣金
		 ,GROSS_CMS            			--毛佣金
		 ,SCDY_CMS             			--二级佣金
		 ,SCDY_NET_CMS         			--二级净佣金
		 ,SCDY_TRAN_FEE        			--二级过户费
		 ,ODI_TRD_TRAN_FEE     			--普通交易过户费
		 ,CRED_TRD_TRAN_FEE    			--信用交易过户费
		 ,STKF_CMS             			--股基佣金
		 ,STKF_TRAN_FEE        			--股基过户费
		 ,STKF_NET_CMS         			--股基净佣金
		 ,BOND_CMS             			--债券佣金
		 ,BOND_NET_CMS         			--债券净佣金
		 ,REPQ_CMS             			--报价回购佣金
		 ,REPQ_NET_CMS         			--报价回购净佣金
		 ,HGT_CMS              			--沪港通佣金
		 ,HGT_NET_CMS          			--沪港通净佣金
		 ,HGT_TRAN_FEE         			--沪港通过户费
		 ,SGT_CMS              			--深港通佣金
		 ,SGT_NET_CMS          			--深港通净佣金
		 ,SGT_TRAN_FEE         			--深港通过户费
		 ,BGDL_CMS             			--大宗交易佣金
		 ,BGDL_NET_CMS         			--大宗交易净佣金
		 ,BGDL_TRAN_FEE        			--大宗交易过户费
		 ,PSTK_OPTN_CMS        			--个股期权佣金
		 ,PSTK_OPTN_NET_CMS    			--个股期权净佣金
		 ,CREDIT_ODI_CMS       			--融资融券普通佣金
		 ,CREDIT_ODI_NET_CMS   			--融资融券普通净佣金
		 ,CREDIT_ODI_TRAN_FEE  			--融资融券普通过户费
		 ,CREDIT_CRED_CMS      			--融资融券信用佣金
		 ,CREDIT_CRED_NET_CMS  			--融资融券信用净佣金
		 ,CREDIT_CRED_TRAN_FEE 			--融资融券信用过户费
		 ,FIN_RECE_INT         			--融资应收利息
		 ,FIN_PAIDINT          			--融资实收利息
		 ,STKPLG_CMS           			--股票质押佣金
		 ,STKPLG_NET_CMS       			--股票质押净佣金
		 ,STKPLG_PAIDINT       			--股票质押实收利息
		 ,STKPLG_RECE_INT      			--股票质押应收利息
		 ,APPTBUYB_CMS         			--约定购回佣金
		 ,APPTBUYB_NET_CMS     			--约定购回净佣金
		 ,APPTBUYB_PAIDINT     			--约定购回实收利息
		 ,FIN_IE               			--融资利息支出
		 ,CRDT_STK_IE          			--融券利息支出
		 ,OTH_IE               			--其他利息支出
		 ,FEE_RECE_INT         			--费用应收利息
		 ,OTH_RECE_INT         			--其他应收利息
		 ,CREDIT_CPTL_COST     			--融资融券资金成本
	)
	SELECT 
		  T.OCCUR_DT            		AS      OCCUR_DT            		--发生日期
		 ,T1.BRH_ID              		AS      BRH_ID              		--营业部编码
		 ,T.EMP_ID		 	  			AS      EMP_ID		 	  			--员工编码		
		 ,T.NET_CMS             		AS      NET_CMS             		--净佣金
		 ,T.GROSS_CMS           		AS      GROSS_CMS           		--毛佣金
		 ,T.SCDY_CMS            		AS      SCDY_CMS            		--二级佣金
		 ,T.SCDY_NET_CMS        		AS      SCDY_NET_CMS        		--二级净佣金
		 ,T.SCDY_TRAN_FEE       		AS      SCDY_TRAN_FEE       		--二级过户费
		 ,T.ODI_TRD_TRAN_FEE    		AS      ODI_TRD_TRAN_FEE    		--普通交易过户费
		 ,T.CRED_TRD_TRAN_FEE   		AS      CRED_TRD_TRAN_FEE   		--信用交易过户费
		 ,T.STKF_CMS            		AS      STKF_CMS            		--股基佣金
		 ,T.STKF_TRAN_FEE       		AS      STKF_TRAN_FEE       		--股基过户费
		 ,T.STKF_NET_CMS        		AS      STKF_NET_CMS        		--股基净佣金
		 ,T.BOND_CMS            		AS      BOND_CMS            		--债券佣金
		 ,T.BOND_NET_CMS        		AS      BOND_NET_CMS        		--债券净佣金
		 ,T.REPQ_CMS            		AS      REPQ_CMS            		--报价回购佣金
		 ,T.REPQ_NET_CMS        		AS      REPQ_NET_CMS        		--报价回购净佣金
		 ,T.HGT_CMS             		AS      HGT_CMS             		--沪港通佣金
		 ,T.HGT_NET_CMS         		AS      HGT_NET_CMS         		--沪港通净佣金
		 ,T.HGT_TRAN_FEE        		AS      HGT_TRAN_FEE        		--沪港通过户费
		 ,T.SGT_CMS             		AS      SGT_CMS             		--深港通佣金
		 ,T.SGT_NET_CMS         		AS      SGT_NET_CMS         		--深港通净佣金
		 ,T.SGT_TRAN_FEE        		AS      SGT_TRAN_FEE        		--深港通过户费
		 ,T.BGDL_CMS            		AS      BGDL_CMS            		--大宗交易佣金
		 ,T.BGDL_NET_CMS        		AS      BGDL_NET_CMS        		--大宗交易净佣金
		 ,T.BGDL_TRAN_FEE       		AS      BGDL_TRAN_FEE       		--大宗交易过户费
		 ,T.PSTK_OPTN_CMS       		AS      PSTK_OPTN_CMS       		--个股期权佣金
		 ,T.PSTK_OPTN_NET_CMS   		AS      PSTK_OPTN_NET_CMS   		--个股期权净佣金
		 ,T.CREDIT_ODI_CMS      		AS      CREDIT_ODI_CMS      		--融资融券普通佣金
		 ,T.CREDIT_ODI_NET_CMS  		AS      CREDIT_ODI_NET_CMS  		--融资融券普通净佣金
		 ,T.CREDIT_ODI_TRAN_FEE 		AS      CREDIT_ODI_TRAN_FEE 		--融资融券普通过户费
		 ,T.CREDIT_CRED_CMS     		AS      CREDIT_CRED_CMS     		--融资融券信用佣金
		 ,T.CREDIT_CRED_NET_CMS 		AS      CREDIT_CRED_NET_CMS 		--融资融券信用净佣金
		 ,T.CREDIT_CRED_TRAN_FEE		AS      CREDIT_CRED_TRAN_FEE		--融资融券信用过户费
		 ,T.FIN_RECE_INT        		AS      FIN_RECE_INT        		--融资应收利息
		 ,T.FIN_PAIDINT         		AS      FIN_PAIDINT         		--融资实收利息
		 ,T.STKPLG_CMS          		AS      STKPLG_CMS          		--股票质押佣金
		 ,T.STKPLG_NET_CMS      		AS      STKPLG_NET_CMS      		--股票质押净佣金
		 ,T.STKPLG_PAIDINT      		AS      STKPLG_PAIDINT      		--股票质押实收利息
		 ,T.STKPLG_RECE_INT     		AS      STKPLG_RECE_INT     		--股票质押应收利息
		 ,T.APPTBUYB_CMS        		AS      APPTBUYB_CMS        		--约定购回佣金
		 ,T.APPTBUYB_NET_CMS    		AS      APPTBUYB_NET_CMS    		--约定购回净佣金
		 ,T.APPTBUYB_PAIDINT    		AS      APPTBUYB_PAIDINT    		--约定购回实收利息
		 ,T.FIN_IE              		AS      FIN_IE              		--融资利息支出
		 ,T.CRDT_STK_IE         		AS      CRDT_STK_IE         		--融券利息支出
		 ,T.OTH_IE              		AS      OTH_IE              		--其他利息支出
		 ,T.FEE_RECE_INT        		AS      FEE_RECE_INT        		--费用应收利息
		 ,T.OTH_RECE_INT        		AS      OTH_RECE_INT        		--其他应收利息
		 ,T.CREDIT_CPTL_COST    		AS      CREDIT_CPTL_COST    		--融资融券资金成本
	FROM DM.T_EVT_INCM_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	 AND  T1.BRH_ID IS NOT NULL;
	
	--将临时表的按营业部维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_INCM_D_BRH (
			 OCCUR_DT            	--发生日期
			,BRH_ID              	--营业部编码		
			,NET_CMS             	--净佣金	
			,GROSS_CMS           	--毛佣金	
			,SCDY_CMS            	--二级佣金	
			,SCDY_NET_CMS        	--二级净佣金	
			,SCDY_TRAN_FEE       	--二级过户费	
			,ODI_TRD_TRAN_FEE    	--普通交易过户费	
			,CRED_TRD_TRAN_FEE   	--信用交易过户费	
			,STKF_CMS            	--股基佣金	
			,STKF_TRAN_FEE       	--股基过户费	
			,STKF_NET_CMS        	--股基净佣金	
			,BOND_CMS            	--债券佣金	
			,BOND_NET_CMS        	--债券净佣金	
			,REPQ_CMS            	--报价回购佣金	
			,REPQ_NET_CMS        	--报价回购净佣金	
			,HGT_CMS             	--沪港通佣金	
			,HGT_NET_CMS         	--沪港通净佣金	
			,HGT_TRAN_FEE        	--沪港通过户费	
			,SGT_CMS             	--深港通佣金	
			,SGT_NET_CMS         	--深港通净佣金	
			,SGT_TRAN_FEE        	--深港通过户费	
			,BGDL_CMS            	--大宗交易佣金	
			,BGDL_NET_CMS        	--大宗交易净佣金	
			,BGDL_TRAN_FEE       	--大宗交易过户费	
			,PSTK_OPTN_CMS       	--个股期权佣金	
			,PSTK_OPTN_NET_CMS   	--个股期权净佣金	
			,CREDIT_ODI_CMS      	--融资融券普通佣金	
			,CREDIT_ODI_NET_CMS  	--融资融券普通净佣金	
			,CREDIT_ODI_TRAN_FEE 	--融资融券普通过户费	
			,CREDIT_CRED_CMS     	--融资融券信用佣金	
			,CREDIT_CRED_NET_CMS 	--融资融券信用净佣金	
			,CREDIT_CRED_TRAN_FEE	--融资融券信用过户费	
			,FIN_RECE_INT        	--融资应收利息	
			,FIN_PAIDINT         	--融资实收利息	
			,STKPLG_CMS          	--股票质押佣金	
			,STKPLG_NET_CMS      	--股票质押净佣金	
			,STKPLG_PAIDINT      	--股票质押实收利息	
			,STKPLG_RECE_INT     	--股票质押应收利息	
			,APPTBUYB_CMS        	--约定购回佣金	
			,APPTBUYB_NET_CMS    	--约定购回净佣金	
			,APPTBUYB_PAIDINT    	--约定购回实收利息	
			,FIN_IE              	--融资利息支出	
			,CRDT_STK_IE         	--融券利息支出	
			,OTH_IE              	--其他利息支出	
			,FEE_RECE_INT        	--费用应收利息	
			,OTH_RECE_INT        	--其他应收利息	
			,CREDIT_CPTL_COST      	--融资融券资金成本						
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              --发生日期		
			,BRH_ID									AS    BRH_ID                --营业部编码	
			,SUM(NET_CMS)							AS 	  NET_CMS             	--净佣金				
			,SUM(GROSS_CMS)							AS 	  GROSS_CMS           	--毛佣金		
			,SUM(SCDY_CMS)							AS 	  SCDY_CMS            	--二级佣金		
			,SUM(SCDY_NET_CMS)						AS 	  SCDY_NET_CMS        	--二级净佣金			
			,SUM(SCDY_TRAN_FEE)						AS 	  SCDY_TRAN_FEE       	--二级过户费			
			,SUM(ODI_TRD_TRAN_FEE)					AS 	  ODI_TRD_TRAN_FEE    	--普通交易过户费				
			,SUM(CRED_TRD_TRAN_FEE)					AS 	  CRED_TRD_TRAN_FEE   	--信用交易过户费				
			,SUM(STKF_CMS)							AS 	  STKF_CMS            	--股基佣金		
			,SUM(STKF_TRAN_FEE)						AS 	  STKF_TRAN_FEE       	--股基过户费			
			,SUM(STKF_NET_CMS)						AS 	  STKF_NET_CMS        	--股基净佣金			
			,SUM(BOND_CMS)							AS 	  BOND_CMS            	--债券佣金		
			,SUM(BOND_NET_CMS)						AS 	  BOND_NET_CMS        	--债券净佣金			
			,SUM(REPQ_CMS)							AS 	  REPQ_CMS            	--报价回购佣金		
			,SUM(REPQ_NET_CMS)						AS 	  REPQ_NET_CMS        	--报价回购净佣金			
			,SUM(HGT_CMS)							AS 	  HGT_CMS             	--沪港通佣金		
			,SUM(HGT_NET_CMS)						AS 	  HGT_NET_CMS         	--沪港通净佣金			
			,SUM(HGT_TRAN_FEE)						AS 	  HGT_TRAN_FEE        	--沪港通过户费			
			,SUM(SGT_CMS)							AS 	  SGT_CMS             	--深港通佣金		
			,SUM(SGT_NET_CMS)						AS 	  SGT_NET_CMS         	--深港通净佣金			
			,SUM(SGT_TRAN_FEE)						AS 	  SGT_TRAN_FEE        	--深港通过户费			
			,SUM(BGDL_CMS)							AS 	  BGDL_CMS            	--大宗交易佣金		
			,SUM(BGDL_NET_CMS)						AS 	  BGDL_NET_CMS        	--大宗交易净佣金			
			,SUM(BGDL_TRAN_FEE)						AS 	  BGDL_TRAN_FEE       	--大宗交易过户费			
			,SUM(PSTK_OPTN_CMS)						AS 	  PSTK_OPTN_CMS       	--个股期权佣金			
			,SUM(PSTK_OPTN_NET_CMS)					AS 	  PSTK_OPTN_NET_CMS   	--个股期权净佣金				
			,SUM(CREDIT_ODI_CMS)					AS 	  CREDIT_ODI_CMS      	--融资融券普通佣金				
			,SUM(CREDIT_ODI_NET_CMS)				AS 	  CREDIT_ODI_NET_CMS  	--融资融券普通净佣金					
			,SUM(CREDIT_ODI_TRAN_FEE)				AS 	  CREDIT_ODI_TRAN_FEE 	--融资融券普通过户费					
			,SUM(CREDIT_CRED_CMS)					AS 	  CREDIT_CRED_CMS     	--融资融券信用佣金				
			,SUM(CREDIT_CRED_NET_CMS)				AS 	  CREDIT_CRED_NET_CMS 	--融资融券信用净佣金					
			,SUM(CREDIT_CRED_TRAN_FEE)				AS 	  CREDIT_CRED_TRAN_FEE	--融资融券信用过户费					
			,SUM(FIN_RECE_INT)						AS 	  FIN_RECE_INT        	--融资应收利息			
			,SUM(FIN_PAIDINT)						AS 	  FIN_PAIDINT         	--融资实收利息			
			,SUM(STKPLG_CMS)						AS 	  STKPLG_CMS          	--股票质押佣金			
			,SUM(STKPLG_NET_CMS)					AS 	  STKPLG_NET_CMS      	--股票质押净佣金				
			,SUM(STKPLG_PAIDINT)					AS 	  STKPLG_PAIDINT      	--股票质押实收利息				
			,SUM(STKPLG_RECE_INT)					AS 	  STKPLG_RECE_INT     	--股票质押应收利息				
			,SUM(APPTBUYB_CMS)						AS 	  APPTBUYB_CMS        	--约定购回佣金			
			,SUM(APPTBUYB_NET_CMS)					AS 	  APPTBUYB_NET_CMS    	--约定购回净佣金				
			,SUM(APPTBUYB_PAIDINT)					AS 	  APPTBUYB_PAIDINT    	--约定购回实收利息				
			,SUM(FIN_IE)							AS 	  FIN_IE              	--融资利息支出		
			,SUM(CRDT_STK_IE)						AS 	  CRDT_STK_IE         	--融券利息支出			
			,SUM(OTH_IE)							AS 	  OTH_IE              	--其他利息支出		
			,SUM(FEE_RECE_INT)						AS 	  FEE_RECE_INT        	--费用应收利息			
			,SUM(OTH_RECE_INT)						AS 	  OTH_RECE_INT        	--其他应收利息			
			,SUM(CREDIT_CPTL_COST)					AS 	  CREDIT_CPTL_COST      --融资融券资金成本							
		FROM #TMP_T_EVT_INCM_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_INCM_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工收入事实表（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-11
  简介：员工收入统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_INCM_D_EMP WHERE OCCUR_DT = @V_DATE;

	-- 1.1 在T_EVT_TRD_D_EMP的基础上增加资金账号（客户号）字段来创建临时表（为了取责权分配后的金额然后再根据员工维度汇总分配后的金额）

	CREATE TABLE #TMP_T_EVT_INCM_D_EMP(
			OCCUR_DT             numeric(8,0) NOT NULL,		--发生日期
			EMP_ID               varchar(30) NOT NULL,		--员工编码
			MAIN_CPTL_ACCT		 varchar(30) NOT NULL,		--资金账号
			NET_CMS              numeric(38,8) NULL,		--净佣金
			GROSS_CMS            numeric(38,8) NULL,		--毛佣金
			SCDY_CMS             numeric(38,8) NULL,		--二级佣金
			SCDY_NET_CMS         numeric(38,8) NULL,		--二级净佣金
			SCDY_TRAN_FEE        numeric(38,8) NULL,		--二级过户费
			ODI_TRD_TRAN_FEE     numeric(38,8) NULL,		--普通交易过户费
			ODI_TRD_STP_TAX      numeric(38,8) NULL,		--普通交易印花税
			ODI_TRD_HANDLE_FEE   numeric(38,8) NULL,		--普通交易经手费
			ODI_TRD_SEC_RGLT_FEE numeric(38,8) NULL,		--普通交易证管费 
			ODI_TRD_ORDR_FEE     numeric(38,8) NULL,		--普通交易委托费
			ODI_TRD_OTH_FEE      numeric(38,8) NULL,		--普通交易其他费用
			CRED_TRD_TRAN_FEE    numeric(38,8) NULL,		--信用交易过户费
			CRED_TRD_STP_TAX     numeric(38,8) NULL,		--信用交易印花税
			CRED_TRD_HANDLE_FEE  numeric(38,8) NULL,		--信用交易经手费
			CRED_TRD_SEC_RGLT_FEE numeric(38,8) NULL,		--信用交易证管费
			CRED_TRD_ORDR_FEE    numeric(38,8) NULL,		--信用交易委托费
			CRED_TRD_OTH_FEE     numeric(38,8) NULL,		--信用交易其他费用
			STKF_CMS             numeric(38,8) NULL,		--股基佣金
			STKF_TRAN_FEE        numeric(38,8) NULL,		--股基过户费
			STKF_NET_CMS         numeric(38,8) NULL,		--股基净佣金
			BOND_CMS             numeric(38,8) NULL,		--债券佣金
			BOND_NET_CMS         numeric(38,8) NULL,		--债券净佣金
			REPQ_CMS             numeric(38,8) NULL,		--报价回购佣金
			REPQ_NET_CMS         numeric(38,8) NULL,		--报价回购净佣金
			HGT_CMS              numeric(38,8) NULL,		--沪港通佣金
			HGT_NET_CMS          numeric(38,8) NULL,		--沪港通净佣金
			HGT_TRAN_FEE         numeric(38,8) NULL,		--沪港通过户费
			SGT_CMS              numeric(38,8) NULL,		--深港通佣金
			SGT_NET_CMS          numeric(38,8) NULL,		--深港通净佣金
			SGT_TRAN_FEE         numeric(38,8) NULL,		--深港通过户费
			BGDL_CMS             numeric(38,8) NULL,		--大宗交易佣金
			BGDL_NET_CMS         numeric(38,8) NULL,		--大宗交易净佣金
			BGDL_TRAN_FEE        numeric(38,8) NULL,		--大宗交易过户费
			PSTK_OPTN_CMS        numeric(38,8) NULL,		--个股期权佣金
			PSTK_OPTN_NET_CMS    numeric(38,8) NULL,		--个股期权净佣金
			CREDIT_ODI_CMS       numeric(38,8) NULL,		--融资融券普通佣金
			CREDIT_ODI_NET_CMS   numeric(38,8) NULL,		--融资融券普通净佣金
			CREDIT_ODI_TRAN_FEE  numeric(38,8) NULL,		--融资融券普通过户费
			CREDIT_CRED_CMS      numeric(38,8) NULL,		--融资融券信用佣金
			CREDIT_CRED_NET_CMS  numeric(38,8) NULL,		--融资融券信用净佣金
			CREDIT_CRED_TRAN_FEE numeric(38,8) NULL,		--融资融券信用过户费
			FIN_RECE_INT         numeric(38,8) NULL,		--融资应收利息
			FIN_PAIDINT          numeric(38,8) NULL,		--融资实收利息
			STKPLG_CMS           numeric(38,8) NULL,		--股票质押佣金
			STKPLG_NET_CMS       numeric(38,8) NULL,		--股票质押净佣金
			STKPLG_PAIDINT       numeric(38,8) NULL,		--股票质押实收利息
			STKPLG_RECE_INT      numeric(38,8) NULL,		--股票质押应收利息
			APPTBUYB_CMS         numeric(38,8) NULL,		--约定购回佣金
			APPTBUYB_NET_CMS     numeric(38,8) NULL,		--约定购回净佣金
			APPTBUYB_PAIDINT     numeric(38,8) NULL,		--约定购回实收利息
			FIN_IE               numeric(38,8) NULL,		--融资利息支出
			CRDT_STK_IE          numeric(38,8) NULL,		--融券利息支出
			OTH_IE               numeric(38,8) NULL,		--其他利息支出
			FEE_RECE_INT         numeric(38,8) NULL,		--费用应收利息
			OTH_RECE_INT         numeric(38,8) NULL,		--其他应收利息
			CREDIT_CPTL_COST     numeric(38,8) NULL			--融资融券资金成本
	);

	INSERT INTO #TMP_T_EVT_INCM_D_EMP(
		 OCCUR_DT					
		,EMP_ID						
		,MAIN_CPTL_ACCT
	)			
	SELECT 
		 @V_DATE AS OCCUR_DT			--发生日期
		,A.AFATWO_YGH AS EMP_ID			--员工编码
		,A.ZJZH AS MAIN_CPTL_ACCT		--资金账号
	FROM DBA.T_DDW_SERV_RELATION_D A
	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  		   ,A.ZJZH;

	-- 基于责权分配表统计（员工-客户）绩效分配比例

  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH;

	--更新分配后的各项指标
	UPDATE #TMP_T_EVT_INCM_D_EMP
		SET 
			 NET_CMS              	=  	COALESCE(B1.NET_CMS,0)					* 	C.PERFM_RATIO_4		--净佣金				
			,GROSS_CMS            	=  	COALESCE(B1.GROSS_CMS,0)				* 	C.PERFM_RATIO_4		--毛佣金				
			,SCDY_CMS             	=  	COALESCE(B1.SCDY_CMS,0)					* 	C.PERFM_RATIO_4		--二级佣金				
			,SCDY_NET_CMS         	=  	COALESCE(B1.SCDY_NET_CMS,0)				* 	C.PERFM_RATIO_4		--二级净佣金				
			,SCDY_TRAN_FEE        	=  	COALESCE(B1.SCDY_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--二级过户费				
			,ODI_TRD_TRAN_FEE     	=  	COALESCE(B1.ODI_TRD_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--普通交易过户费				
			,ODI_TRD_STP_TAX      	=  	COALESCE(B1.ODI_TRD_STP_TAX,0)			* 	C.PERFM_RATIO_4		--普通交易印花税				
			,ODI_TRD_HANDLE_FEE   	=  	COALESCE(B1.ODI_TRD_HANDLE_FEE,0)		* 	C.PERFM_RATIO_4		--普通交易经手费					
			,ODI_TRD_SEC_RGLT_FEE 	=  	COALESCE(B1.ODI_TRD_SEC_RGLT_FEE,0)		* 	C.PERFM_RATIO_4		--普通交易证管费 					
			--,ODI_TRD_ORDR_FEE     	=  	COALESCE(B1.ODI_TRD_ORDR_FEE,0)			* 	C.PERFM_RATIO_4		--普通交易委托费				
			,ODI_TRD_OTH_FEE      	=  	COALESCE(B1.ODI_TRD_OTH_FEE,0)			* 	C.PERFM_RATIO_4		--普通交易其他费用					
			,CRED_TRD_TRAN_FEE    	=  	COALESCE(B2.CRED_TRD_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--信用交易过户费					
			,CRED_TRD_STP_TAX     	=  	COALESCE(B2.CRED_TRD_STP_TAX,0)			* 	C.PERFM_RATIO_4		--信用交易印花税				
			,CRED_TRD_HANDLE_FEE  	=  	COALESCE(B2.CRED_TRD_HANDLE_FEE,0)		* 	C.PERFM_RATIO_4		--信用交易经手费					
			,CRED_TRD_SEC_RGLT_FEE	=  	COALESCE(B2.CRED_TRD_SEC_RGLT_FEE,0)	* 	C.PERFM_RATIO_4		--信用交易证管费						
			,CRED_TRD_ORDR_FEE    	=  	COALESCE(B2.CRED_TRD_ORDR_FEE,0)		* 	C.PERFM_RATIO_4		--信用交易委托费					
			,CRED_TRD_OTH_FEE     	=  	COALESCE(B2.CRED_TRD_OTH_FEE,0)			* 	C.PERFM_RATIO_4		--信用交易其他费用					
			,STKF_CMS             	=  	COALESCE(B1.STKF_CMS,0)					* 	C.PERFM_RATIO_4		--股基佣金				
			,STKF_TRAN_FEE        	=  	COALESCE(B1.STKF_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--股基过户费				
			,STKF_NET_CMS         	=  	COALESCE(B1.STKF_NET_CMS,0)				* 	C.PERFM_RATIO_4		--股基净佣金				
			,BOND_CMS             	=  	COALESCE(B1.BOND_CMS,0)					* 	C.PERFM_RATIO_4		--债券佣金				
			,BOND_NET_CMS         	=  	COALESCE(B1.BOND_NET_CMS,0)				* 	C.PERFM_RATIO_4		--债券净佣金				
			,REPQ_CMS             	=  	COALESCE(B1.REPQ_CMS,0)					* 	C.PERFM_RATIO_4		--报价回购佣金				
			,REPQ_NET_CMS         	=  	COALESCE(B1.REPQ_NET_CMS,0)				* 	C.PERFM_RATIO_4		--报价回购净佣金				
			,HGT_CMS              	=  	COALESCE(B1.HGT_CMS,0)					* 	C.PERFM_RATIO_4		--沪港通佣金				
			,HGT_NET_CMS          	=  	COALESCE(B1.HGT_NET_CMS,0)				* 	C.PERFM_RATIO_4		--沪港通净佣金				
			,HGT_TRAN_FEE         	=  	COALESCE(B1.HGT_TRAN_FEE,0)				* 	C.PERFM_RATIO_4		--沪港通过户费				
			,SGT_CMS              	=  	COALESCE(B1.SGT_CMS,0)					* 	C.PERFM_RATIO_4		--深港通佣金				
			,SGT_NET_CMS          	=  	COALESCE(B1.SGT_NET_CMS,0)				* 	C.PERFM_RATIO_4		--深港通净佣金				
			,SGT_TRAN_FEE         	=  	COALESCE(B1.SGT_TRAN_FEE,0)				* 	C.PERFM_RATIO_4		--深港通过户费				
			,BGDL_CMS             	=  	COALESCE(B1.BGDL_CMS,0)					* 	C.PERFM_RATIO_4		--大宗交易佣金				
			,BGDL_NET_CMS         	=  	COALESCE(B1.BGDL_NET_CMS,0)				* 	C.PERFM_RATIO_4		--大宗交易净佣金				
			,BGDL_TRAN_FEE        	=  	COALESCE(B1.BGDL_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--大宗交易过户费				
			,PSTK_OPTN_CMS        	=  	COALESCE(B1.PSTK_OPTN_CMS,0)			* 	C.PERFM_RATIO_4		--个股期权佣金				
			,PSTK_OPTN_NET_CMS    	=  	COALESCE(B1.PSTK_OPTN_NET_CMS,0)		* 	C.PERFM_RATIO_4		--个股期权净佣金					
			,CREDIT_ODI_CMS       	=  	COALESCE(B2.CREDIT_ODI_CMS,0)			* 	C.PERFM_RATIO_4		--融资融券普通佣金				
			,CREDIT_ODI_NET_CMS   	=  	COALESCE(B2.CREDIT_ODI_NET_CMS,0)		* 	C.PERFM_RATIO_4		--融资融券普通净佣金						
			,CREDIT_ODI_TRAN_FEE  	=  	COALESCE(B2.CREDIT_ODI_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--融资融券普通过户费						
			,CREDIT_CRED_CMS      	=  	COALESCE(B2.CREDIT_CRED_CMS,0)			* 	C.PERFM_RATIO_4		--融资融券信用佣金					
			,CREDIT_CRED_NET_CMS  	=  	COALESCE(B2.CREDIT_CRED_NET_CMS,0)		* 	C.PERFM_RATIO_4		--融资融券信用净佣金						
			,CREDIT_CRED_TRAN_FEE 	=  	COALESCE(B2.CREDIT_CRED_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--融资融券信用过户费					
			,FIN_RECE_INT         	=  	COALESCE(B2.FIN_RECE_INT,0)				* 	C.PERFM_RATIO_4		--融资应收利息				
			,FIN_PAIDINT          	=  	COALESCE(B2.FIN_PAIDINT,0)				* 	C.PERFM_RATIO_4		--融资实收利息				
			,STKPLG_CMS           	=  	COALESCE(B2.STKPLG_CMS,0)				* 	C.PERFM_RATIO_4		--股票质押佣金				
			,STKPLG_NET_CMS       	=  	COALESCE(B2.STKPLG_NET_CMS,0)			* 	C.PERFM_RATIO_4		--股票质押净佣金				
			,STKPLG_PAIDINT       	=  	COALESCE(B2.STKPLG_PAIDINT,0)			* 	C.PERFM_RATIO_4		--股票质押实收利息				
			,STKPLG_RECE_INT      	=  	COALESCE(B2.STKPLG_RECE_INT,0)			* 	C.PERFM_RATIO_4		--股票质押应收利息					
			,APPTBUYB_CMS         	=  	COALESCE(B2.APPTBUYB_CMS,0)				* 	C.PERFM_RATIO_4		--约定购回佣金				
			,APPTBUYB_NET_CMS     	=  	COALESCE(B2.APPTBUYB_NET_CMS,0)			* 	C.PERFM_RATIO_4		--约定购回净佣金				
			,APPTBUYB_PAIDINT     	=  	COALESCE(B2.APPTBUYB_PAIDINT,0)			* 	C.PERFM_RATIO_4		--约定购回实收利息					
			,FIN_IE               	=  	COALESCE(B2.FIN_IE,0)					* 	C.PERFM_RATIO_4		--融资利息支出				
			,CRDT_STK_IE          	=  	COALESCE(B2.CRDT_STK_IE,0)				* 	C.PERFM_RATIO_4		--融券利息支出				
			,OTH_IE               	=  	COALESCE(B2.OTH_IE,0)					* 	C.PERFM_RATIO_4		--其他利息支出				
			,FEE_RECE_INT         	=  	COALESCE(B2.FEE_RECE_INT,0)				* 	C.PERFM_RATIO_4		--费用应收利息				
			,OTH_RECE_INT         	=  	COALESCE(B2.OTH_RECE_INT,0)				* 	C.PERFM_RATIO_4		--其他应收利息				
			,CREDIT_CPTL_COST     	=  	COALESCE(B2.CREDIT_CPTL_COST,0)			* 	C.PERFM_RATIO_4		--融资融券资金成本									
		FROM #TMP_T_EVT_INCM_D_EMP A
		--关联客户普通交易日表
		LEFT JOIN (
				SELECT
					 T.MAIN_CPTL_ACCT  			AS 		MAIN_CPTL_ACCT			--资金账号
					,T.NET_CMS					AS 		NET_CMS             	--净佣金	
					,T.GROSS_CMS				AS 		GROSS_CMS           	--毛佣金	
					,T.SCDY_CMS					AS 		SCDY_CMS            	--二级佣金	
					,T.SCDY_NET_CMS				AS 		SCDY_NET_CMS        	--二级净佣金		
					,T.SCDY_TRAN_FEE			AS 		SCDY_TRAN_FEE       	--二级过户费		
					,T.TRAN_FEE					AS 		ODI_TRD_TRAN_FEE    	--普通交易过户费	
					,T.STP_TAX					AS 		ODI_TRD_STP_TAX     	--普通交易印花税	
					,T.HANDLE_FEE				AS 		ODI_TRD_HANDLE_FEE  	--普通交易经手费		
					,T.SEC_RGLT_FEE				AS 		ODI_TRD_SEC_RGLT_FEE	--普通交易证管费 		
					--,T.ORDR_FEE					AS 		ODI_TRD_ORDR_FEE    	--普通交易委托费	
					,T.OTH_FEE					AS 		ODI_TRD_OTH_FEE     	--普通交易其他费用	
					,T.STKF_CMS					AS 		STKF_CMS         		--股基佣金
					,T.STKF_TRAN_FEE			AS 		STKF_TRAN_FEE    		--股基过户费	
					,T.STKF_NET_CMS				AS 		STKF_NET_CMS     		--股基净佣金	
					,T.BOND_CMS					AS 		BOND_CMS         		--债券佣金
					,T.BOND_NET_CMS				AS 		BOND_NET_CMS     		--债券净佣金	
					,T.REPQ_CMS					AS 		REPQ_CMS         		--报价回购佣金
					,T.REPQ_NET_CMS				AS 		REPQ_NET_CMS     		--报价回购净佣金	
					,T.HGT_CMS     				AS 		HGT_CMS          		--沪港通佣金	
					,T.HGT_NET_CMS 				AS 		HGT_NET_CMS      		--沪港通净佣金	
					,T.HGT_TRAN_FEE				AS 		HGT_TRAN_FEE     		--沪港通过户费	
					,T.SGT_CMS     				AS 		SGT_CMS          		--深港通佣金	
					,T.SGT_NET_CMS 				AS 		SGT_NET_CMS      		--深港通净佣金	
					,T.SGT_TRAN_FEE				AS 		SGT_TRAN_FEE     		--深港通过户费	
					,T.BGDL_CMS    				AS 		BGDL_CMS         		--大宗交易佣金	
					,T.BGDL_NET_CMS 			AS 		BGDL_NET_CMS     		--大宗交易净佣金	
					,T.BGDL_TRAN_FEE			AS 		BGDL_TRAN_FEE    		--大宗交易过户费	
					,T.PSTK_OPTN_CMS    		AS 		PSTK_OPTN_CMS    		--个股期权佣金		
					,T.PSTK_OPTN_NET_CMS		AS 		PSTK_OPTN_NET_CMS		--个股期权净佣金		
				FROM DM.T_EVT_ODI_INCM_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B1 ON A.MAIN_CPTL_ACCT=B1.MAIN_CPTL_ACCT
		LEFT JOIN (
				SELECT
					 T.MAIN_CPTL_ACCT 			AS 		MAIN_CPTL_ACCT			--资金账号			
					,T.TRAN_FEE    				AS     	CRED_TRD_TRAN_FEE    	--信用交易过户费					
					,T.STP_TAX     				AS     	CRED_TRD_STP_TAX     	--信用交易印花税					
					,T.HANDLE_FEE  				AS     	CRED_TRD_HANDLE_FEE  	--信用交易经手费					
					,T.SEC_RGLT_FEE				AS     	CRED_TRD_SEC_RGLT_FEE	--信用交易证管费					
					,T.ORDR_FEE    				AS     	CRED_TRD_ORDR_FEE    	--信用交易委托费					
					,T.OTH_FEE     				AS     	CRED_TRD_OTH_FEE     	--信用交易其他费用					
					,T.CREDIT_ODI_CMS    		AS     	CREDIT_ODI_CMS      	--融资融券普通佣金							
					,T.CREDIT_ODI_NET_CMS		AS     	CREDIT_ODI_NET_CMS  	--融资融券普通净佣金							
					,T.CREDIT_ODI_TRAN_FEE		AS     	CREDIT_ODI_TRAN_FEE 	--融资融券普通过户费							
					,T.CREDIT_CRED_CMS   		AS     	CREDIT_CRED_CMS     	--融资融券信用佣金							
					,T.CREDIT_CRED_NET_CMS		AS     	CREDIT_CRED_NET_CMS 	--融资融券信用净佣金							
					,T.CREDIT_CRED_TRAN_FEE		AS     	CREDIT_CRED_TRAN_FEE	--融资融券信用过户费							
					,T.FIN_RECE_INT				AS     	FIN_RECE_INT        	--融资应收利息					
					,T.FIN_PAIDINT 				AS     	FIN_PAIDINT         	--融资实收利息					
					,T.STKPLG_CMS     			AS     	STKPLG_CMS          	--股票质押佣金						
					,T.STKPLG_NET_CMS 			AS     	STKPLG_NET_CMS      	--股票质押净佣金						
					,T.STKPLG_PAIDINT 			AS     	STKPLG_PAIDINT      	--股票质押实收利息						
					,T.STKPLG_RECE_INT			AS     	STKPLG_RECE_INT     	--股票质押应收利息						
					,T.APPTBUYB_CMS    			AS     	APPTBUYB_CMS        	--约定购回佣金						
					,T.APPTBUYB_NET_CMS			AS     	APPTBUYB_NET_CMS    	--约定购回净佣金						
					,T.APPTBUYB_PAIDINT			AS     	APPTBUYB_PAIDINT    	--约定购回实收利息						
					,T.FIN_IE     				AS     	FIN_IE              	--融资利息支出					
					,T.CRDT_STK_IE				AS     	CRDT_STK_IE         	--融券利息支出					
					,T.OTH_IE     				AS     	OTH_IE              	--其他利息支出					
					,T.DAY_FIN_RECE_INT			AS     	FEE_RECE_INT        	--费用应收利息						
					,T.DAY_FEE_RECE_INT			AS     	OTH_RECE_INT        	--其他应收利息						
					,T.DAY_OTH_RECE_INT			AS     	CREDIT_CPTL_COST    	--融资融券资金成本							
				FROM DM.T_EVT_CRED_INCM_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B2 ON A.MAIN_CPTL_ACCT=B2.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--将临时表的按员工维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_INCM_D_EMP (
			 OCCUR_DT            	 	--发生日期
			,EMP_ID               		--员工编码
			,NET_CMS              		--净佣金
			,GROSS_CMS            		--毛佣金
			,SCDY_CMS             		--二级佣金
			,SCDY_NET_CMS         		--二级净佣金
			,SCDY_TRAN_FEE        		--二级过户费
			,ODI_TRD_TRAN_FEE     		--普通交易过户费
			,ODI_TRD_STP_TAX      		--普通交易印花税
			,ODI_TRD_HANDLE_FEE   		--普通交易经手费
			,ODI_TRD_SEC_RGLT_FEE 		--普通交易证管费 
			--,ODI_TRD_ORDR_FEE     		--普通交易委托费
			,ODI_TRD_OTH_FEE      		--普通交易其他费用
			,CRED_TRD_TRAN_FEE    		--信用交易过户费
			,CRED_TRD_STP_TAX     		--信用交易印花税
			,CRED_TRD_HANDLE_FEE  		--信用交易经手费
			,CRED_TRD_SEC_RGLT_FEE		--信用交易证管费
			,CRED_TRD_ORDR_FEE    		--信用交易委托费
			,CRED_TRD_OTH_FEE     		--信用交易其他费用
			,STKF_CMS             		--股基佣金
			,STKF_TRAN_FEE        		--股基过户费
			,STKF_NET_CMS         		--股基净佣金
			,BOND_CMS             		--债券佣金
			,BOND_NET_CMS         		--债券净佣金
			,REPQ_CMS             		--报价回购佣金
			,REPQ_NET_CMS         		--报价回购净佣金
			,HGT_CMS              		--沪港通佣金
			,HGT_NET_CMS          		--沪港通净佣金
			,HGT_TRAN_FEE         		--沪港通过户费
			,SGT_CMS              		--深港通佣金
			,SGT_NET_CMS          		--深港通净佣金
			,SGT_TRAN_FEE         		--深港通过户费
			,BGDL_CMS             		--大宗交易佣金
			,BGDL_NET_CMS         		--大宗交易净佣金
			,BGDL_TRAN_FEE        		--大宗交易过户费
			,PSTK_OPTN_CMS        		--个股期权佣金
			,PSTK_OPTN_NET_CMS    		--个股期权净佣金
			,CREDIT_ODI_CMS       		--融资融券普通佣金
			,CREDIT_ODI_NET_CMS   		--融资融券普通净佣金
			,CREDIT_ODI_TRAN_FEE  		--融资融券普通过户费
			,CREDIT_CRED_CMS      		--融资融券信用佣金
			,CREDIT_CRED_NET_CMS  		--融资融券信用净佣金
			,CREDIT_CRED_TRAN_FEE 		--融资融券信用过户费
			,FIN_RECE_INT         		--融资应收利息
			,FIN_PAIDINT          		--融资实收利息
			,STKPLG_CMS           		--股票质押佣金
			,STKPLG_NET_CMS       		--股票质押净佣金
			,STKPLG_PAIDINT       		--股票质押实收利息
			,STKPLG_RECE_INT      		--股票质押应收利息
			,APPTBUYB_CMS         		--约定购回佣金
			,APPTBUYB_NET_CMS     		--约定购回净佣金
			,APPTBUYB_PAIDINT     		--约定购回实收利息
			,FIN_IE               		--融资利息支出
			,CRDT_STK_IE          		--融券利息支出
			,OTH_IE               		--其他利息支出
			,FEE_RECE_INT         		--费用应收利息
			,OTH_RECE_INT         		--其他应收利息
			,CREDIT_CPTL_COST     		--融资融券资金成本
		)
		SELECT 
			 OCCUR_DT            			AS     OCCUR_DT            	 	--发生日期
			,EMP_ID               			AS     EMP_ID               	--员工编码
			,SUM(NET_CMS)              		AS     NET_CMS              	--净佣金
			,SUM(GROSS_CMS)            		AS     GROSS_CMS            	--毛佣金
			,SUM(SCDY_CMS)             		AS     SCDY_CMS             	--二级佣金
			,SUM(SCDY_NET_CMS)         		AS     SCDY_NET_CMS         	--二级净佣金
			,SUM(SCDY_TRAN_FEE)        		AS     SCDY_TRAN_FEE        	--二级过户费
			,SUM(ODI_TRD_TRAN_FEE)     		AS     ODI_TRD_TRAN_FEE     	--普通交易过户费
			,SUM(ODI_TRD_STP_TAX)      		AS     ODI_TRD_STP_TAX      	--普通交易印花税
			,SUM(ODI_TRD_HANDLE_FEE)   		AS     ODI_TRD_HANDLE_FEE   	--普通交易经手费
			,SUM(ODI_TRD_SEC_RGLT_FEE) 		AS     ODI_TRD_SEC_RGLT_FEE 	--普通交易证管费 
			--,SUM(ODI_TRD_ORDR_FEE)     		AS     ODI_TRD_ORDR_FEE     	--普通交易委托费
			,SUM(ODI_TRD_OTH_FEE)      		AS     ODI_TRD_OTH_FEE      	--普通交易其他费用
			,SUM(CRED_TRD_TRAN_FEE)    		AS     CRED_TRD_TRAN_FEE    	--信用交易过户费
			,SUM(CRED_TRD_STP_TAX)     		AS     CRED_TRD_STP_TAX     	--信用交易印花税
			,SUM(CRED_TRD_HANDLE_FEE)  		AS     CRED_TRD_HANDLE_FEE  	--信用交易经手费
			,SUM(CRED_TRD_SEC_RGLT_FEE)		AS     CRED_TRD_SEC_RGLT_FEE	--信用交易证管费
			,SUM(CRED_TRD_ORDR_FEE)    		AS     CRED_TRD_ORDR_FEE    	--信用交易委托费
			,SUM(CRED_TRD_OTH_FEE)     		AS     CRED_TRD_OTH_FEE     	--信用交易其他费用
			,SUM(STKF_CMS)             		AS     STKF_CMS             	--股基佣金
			,SUM(STKF_TRAN_FEE)        		AS     STKF_TRAN_FEE        	--股基过户费
			,SUM(STKF_NET_CMS)         		AS     STKF_NET_CMS         	--股基净佣金
			,SUM(BOND_CMS)             		AS     BOND_CMS             	--债券佣金
			,SUM(BOND_NET_CMS)         		AS     BOND_NET_CMS         	--债券净佣金
			,SUM(REPQ_CMS)             		AS     REPQ_CMS             	--报价回购佣金
			,SUM(REPQ_NET_CMS)         		AS     REPQ_NET_CMS         	--报价回购净佣金
			,SUM(HGT_CMS)              		AS     HGT_CMS              	--沪港通佣金
			,SUM(HGT_NET_CMS)          		AS     HGT_NET_CMS          	--沪港通净佣金
			,SUM(HGT_TRAN_FEE)         		AS     HGT_TRAN_FEE         	--沪港通过户费
			,SUM(SGT_CMS)              		AS     SGT_CMS              	--深港通佣金
			,SUM(SGT_NET_CMS)          		AS     SGT_NET_CMS          	--深港通净佣金
			,SUM(SGT_TRAN_FEE)         		AS     SGT_TRAN_FEE         	--深港通过户费
			,SUM(BGDL_CMS)             		AS     BGDL_CMS             	--大宗交易佣金
			,SUM(BGDL_NET_CMS)         		AS     BGDL_NET_CMS         	--大宗交易净佣金
			,SUM(BGDL_TRAN_FEE)        		AS     BGDL_TRAN_FEE        	--大宗交易过户费
			,SUM(PSTK_OPTN_CMS)        		AS     PSTK_OPTN_CMS        	--个股期权佣金
			,SUM(PSTK_OPTN_NET_CMS)    		AS     PSTK_OPTN_NET_CMS    	--个股期权净佣金
			,SUM(CREDIT_ODI_CMS)       		AS     CREDIT_ODI_CMS       	--融资融券普通佣金
			,SUM(CREDIT_ODI_NET_CMS)   		AS     CREDIT_ODI_NET_CMS   	--融资融券普通净佣金
			,SUM(CREDIT_ODI_TRAN_FEE)  		AS     CREDIT_ODI_TRAN_FEE  	--融资融券普通过户费
			,SUM(CREDIT_CRED_CMS)      		AS     CREDIT_CRED_CMS      	--融资融券信用佣金
			,SUM(CREDIT_CRED_NET_CMS)  		AS     CREDIT_CRED_NET_CMS  	--融资融券信用净佣金
			,SUM(CREDIT_CRED_TRAN_FEE) 		AS     CREDIT_CRED_TRAN_FEE 	--融资融券信用过户费
			,SUM(FIN_RECE_INT)         		AS     FIN_RECE_INT         	--融资应收利息
			,SUM(FIN_PAIDINT)          		AS     FIN_PAIDINT          	--融资实收利息
			,SUM(STKPLG_CMS)           		AS     STKPLG_CMS           	--股票质押佣金
			,SUM(STKPLG_NET_CMS)       		AS     STKPLG_NET_CMS       	--股票质押净佣金
			,SUM(STKPLG_PAIDINT)       		AS     STKPLG_PAIDINT       	--股票质押实收利息
			,SUM(STKPLG_RECE_INT)      		AS     STKPLG_RECE_INT      	--股票质押应收利息
			,SUM(APPTBUYB_CMS)         		AS     APPTBUYB_CMS         	--约定购回佣金
			,SUM(APPTBUYB_NET_CMS)     		AS     APPTBUYB_NET_CMS     	--约定购回净佣金
			,SUM(APPTBUYB_PAIDINT)     		AS     APPTBUYB_PAIDINT     	--约定购回实收利息
			,SUM(FIN_IE)               		AS     FIN_IE               	--融资利息支出
			,SUM(CRDT_STK_IE)          		AS     CRDT_STK_IE          	--融券利息支出
			,SUM(OTH_IE)               		AS     OTH_IE               	--其他利息支出
			,SUM(FEE_RECE_INT)         		AS     FEE_RECE_INT         	--费用应收利息
			,SUM(OTH_RECE_INT)         		AS     OTH_RECE_INT         	--其他应收利息
			,SUM(CREDIT_CPTL_COST)     		AS     CREDIT_CPTL_COST     	--融资融券资金成本		
		FROM #TMP_T_EVT_INCM_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_INCM_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部收入事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-11
  简介：营业部收入统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_INCM_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID              			AS    BRH_ID              	    --营业部编码
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(NET_CMS)					AS    NET_CMS_MTD          		--净佣金_月累计
		,SUM(GROSS_CMS)					AS    GROSS_CMS_MTD        		--毛佣金_月累计
		,SUM(SCDY_CMS)					AS    SCDY_CMS_MTD         		--二级佣金_月累计
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_MTD     		--二级净佣金_月累计
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_MTD    		--二级过户费_月累计
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_MTD 		--普通交易过户费_月累计
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_MTD		--信用交易过户费_月累计
		,SUM(STKF_CMS)					AS    STKF_CMS_MTD         		--股基佣金_月累计
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_MTD    		--股基过户费_月累计
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_MTD     		--股基净佣金_月累计
		,SUM(BOND_CMS)					AS    BOND_CMS_MTD         		--债券佣金_月累计
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_MTD     		--债券净佣金_月累计
		,SUM(REPQ_CMS)					AS    REPQ_CMS_MTD         		--报价回购佣金_月累计
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_MTD     		--报价回购净佣金_月累计
		,SUM(HGT_CMS)					AS    HGT_CMS_MTD          		--沪港通佣金_月累计
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_MTD      		--沪港通净佣金_月累计
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_MTD     		--沪港通过户费_月累计
		,SUM(SGT_CMS)					AS    SGT_CMS_MTD          		--深港通佣金_月累计
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_MTD      		--深港通净佣金_月累计
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_MTD     		--深港通过户费_月累计
		,SUM(BGDL_CMS)					AS    BGDL_CMS_MTD         		--大宗交易佣金_月累计
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_MTD     		--大宗交易净佣金_月累计
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_MTD    		--大宗交易过户费_月累计
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_MTD    		--个股期权佣金_月累计
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_MTD 	--个股期权净佣金_月累计
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_MTD   		--融资融券普通佣金_月累计
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_MTD 	--融资融券普通净佣金_月累计
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_MTD 	--融资融券普通过户费_月累计
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_MTD  		--融资融券信用佣金_月累计
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_MTD 	--融资融券信用净佣金_月累计
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_MTD 	--融资融券信用过户费_月累计
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_MTD     		--融资应收利息_月累计
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_MTD      		--融资实收利息_月累计
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_MTD       		--股票质押佣金_月累计
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_MTD   		--股票质押净佣金_月累计
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_MTD   		--股票质押实收利息_月累计
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_MTD  		--股票质押应收利息_月累计
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_MTD     		--约定购回佣金_月累计
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_MTD 		--约定购回净佣金_月累计
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_MTD 		--约定购回实收利息_月累计
		,SUM(FIN_IE)					AS    FIN_IE_MTD           		--融资利息支出_月累计
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_MTD      		--融券利息支出_月累计
		,SUM(OTH_IE)					AS    OTH_IE_MTD           		--其他利息支出_月累计
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_MTD     		--费用应收利息_月累计
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_MTD     		--其他应收利息_月累计
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_MTD 		--融资融券资金成本_月累计
	INTO #TMP_T_EVT_INCM_D_BRH_MTH
	FROM DM.T_EVT_INCM_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	-- 统计年指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID              			AS    BRH_ID              	    --营业部编码
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(NET_CMS)					AS    NET_CMS_YTD          		--净佣金_年累计
		,SUM(GROSS_CMS)					AS    GROSS_CMS_YTD        		--毛佣金_年累计
		,SUM(SCDY_CMS)					AS    SCDY_CMS_YTD         		--二级佣金_年累计
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_YTD     		--二级净佣金_年累计
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_YTD    		--二级过户费_年累计
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_YTD 		--普通交易过户费_年累计
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_YTD		--信用交易过户费_年累计
		,SUM(STKF_CMS)					AS    STKF_CMS_YTD         		--股基佣金_年累计
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_YTD    		--股基过户费_年累计
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_YTD     		--股基净佣金_年累计
		,SUM(BOND_CMS)					AS    BOND_CMS_YTD         		--债券佣金_年累计
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_YTD     		--债券净佣金_年累计
		,SUM(REPQ_CMS)					AS    REPQ_CMS_YTD         		--报价回购佣金_年累计
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_YTD     		--报价回购净佣金_年累计
		,SUM(HGT_CMS)					AS    HGT_CMS_YTD          		--沪港通佣金_年累计
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_YTD      		--沪港通净佣金_年累计
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_YTD     		--沪港通过户费_年累计
		,SUM(SGT_CMS)					AS    SGT_CMS_YTD          		--深港通佣金_年累计
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_YTD      		--深港通净佣金_年累计
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_YTD     		--深港通过户费_年累计
		,SUM(BGDL_CMS)					AS    BGDL_CMS_YTD         		--大宗交易佣金_年累计
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_YTD     		--大宗交易净佣金_年累计
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_YTD    		--大宗交易过户费_年累计
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_YTD    		--个股期权佣金_年累计
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_YTD 	--个股期权净佣金_年累计
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_YTD   		--融资融券普通佣金_年累计
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_YTD 	--融资融券普通净佣金_年累计
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_YTD 	--融资融券普通过户费_年累计
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_YTD  		--融资融券信用佣金_年累计
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_YTD 	--融资融券信用净佣金_年累计
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_YTD 	--融资融券信用过户费_年累计
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_YTD     		--融资应收利息_年累计
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_YTD      		--融资实收利息_年累计
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_YTD       		--股票质押佣金_年累计
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_YTD   		--股票质押净佣金_年累计
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_YTD   		--股票质押实收利息_年累计
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_YTD  		--股票质押应收利息_年累计
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_YTD     		--约定购回佣金_年累计
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_YTD 		--约定购回净佣金_年累计
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_YTD 		--约定购回实收利息_年累计
		,SUM(FIN_IE)					AS    FIN_IE_YTD           		--融资利息支出_年累计
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_YTD      		--融券利息支出_年累计
		,SUM(OTH_IE)					AS    OTH_IE_YTD           		--其他利息支出_年累计
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_YTD     		--费用应收利息_年累计
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_YTD     		--其他应收利息_年累计
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_YTD 		--融资融券资金成本_年累计
	INTO #TMP_T_EVT_INCM_D_BRH_YEAR
	FROM DM.T_EVT_INCM_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--插入目标表
	INSERT INTO DM.T_EVT_INCM_M_BRH(
		 YEAR                 		--年
		,MTH                  		--月
		,BRH_ID              		--营业部编码
		,OCCUR_DT             		--发生日期
		,NET_CMS_MTD          		--净佣金_月累计
		,GROSS_CMS_MTD        		--毛佣金_月累计
		,SCDY_CMS_MTD         		--二级佣金_月累计
		,SCDY_NET_CMS_MTD     		--二级净佣金_月累计
		,SCDY_TRAN_FEE_MTD    		--二级过户费_月累计
		,ODI_TRD_TRAN_FEE_MTD 		--普通交易过户费_月累计
		,CRED_TRD_TRAN_FEE_MTD		--信用交易过户费_月累计
		,STKF_CMS_MTD         		--股基佣金_月累计
		,STKF_TRAN_FEE_MTD    		--股基过户费_月累计
		,STKF_NET_CMS_MTD     		--股基净佣金_月累计
		,BOND_CMS_MTD         		--债券佣金_月累计
		,BOND_NET_CMS_MTD     		--债券净佣金_月累计
		,REPQ_CMS_MTD         		--报价回购佣金_月累计
		,REPQ_NET_CMS_MTD     		--报价回购净佣金_月累计
		,HGT_CMS_MTD          		--沪港通佣金_月累计
		,HGT_NET_CMS_MTD      		--沪港通净佣金_月累计
		,HGT_TRAN_FEE_MTD     		--沪港通过户费_月累计
		,SGT_CMS_MTD          		--深港通佣金_月累计
		,SGT_NET_CMS_MTD      		--深港通净佣金_月累计
		,SGT_TRAN_FEE_MTD     		--深港通过户费_月累计
		,BGDL_CMS_MTD         		--大宗交易佣金_月累计
		,BGDL_NET_CMS_MTD     		--大宗交易净佣金_月累计
		,BGDL_TRAN_FEE_MTD    		--大宗交易过户费_月累计
		,PSTK_OPTN_CMS_MTD    		--个股期权佣金_月累计
		,PSTK_OPTN_NET_CMS_MTD 		--个股期权净佣金_月累计
		,CREDIT_ODI_CMS_MTD   		--融资融券普通佣金_月累计
		,CREDIT_ODI_NET_CMS_MTD 	--融资融券普通净佣金_月累计
		,CREDIT_ODI_TRAN_FEE_MTD 	--融资融券普通过户费_月累计
		,CREDIT_CRED_CMS_MTD  		--融资融券信用佣金_月累计
		,CREDIT_CRED_NET_CMS_MTD 	--融资融券信用净佣金_月累计
		,CREDIT_CRED_TRAN_FEE_MTD 	--融资融券信用过户费_月累计
		,FIN_RECE_INT_MTD     		--融资应收利息_月累计
		,FIN_PAIDINT_MTD      		--融资实收利息_月累计
		,STKPLG_CMS_MTD       		--股票质押佣金_月累计
		,STKPLG_NET_CMS_MTD   		--股票质押净佣金_月累计
		,STKPLG_PAIDINT_MTD   		--股票质押实收利息_月累计
		,STKPLG_RECE_INT_MTD  		--股票质押应收利息_月累计
		,APPTBUYB_CMS_MTD     		--约定购回佣金_月累计
		,APPTBUYB_NET_CMS_MTD 		--约定购回净佣金_月累计
		,APPTBUYB_PAIDINT_MTD 		--约定购回实收利息_月累计
		,FIN_IE_MTD           		--融资利息支出_月累计
		,CRDT_STK_IE_MTD      		--融券利息支出_月累计
		,OTH_IE_MTD           		--其他利息支出_月累计
		,FEE_RECE_INT_MTD     		--费用应收利息_月累计
		,OTH_RECE_INT_MTD     		--其他应收利息_月累计
		,CREDIT_CPTL_COST_MTD 		--融资融券资金成本_月累计
		,NET_CMS_YTD          		--净佣金_年累计
		,GROSS_CMS_YTD        		--毛佣金_年累计
		,SCDY_CMS_YTD         		--二级佣金_年累计
		,SCDY_NET_CMS_YTD     		--二级净佣金_年累计
		,SCDY_TRAN_FEE_YTD    		--二级过户费_年累计
		,ODI_TRD_TRAN_FEE_YTD 		--普通交易过户费_年累计
		,CRED_TRD_TRAN_FEE_YTD		--信用交易过户费_年累计
		,STKF_CMS_YTD         		--股基佣金_年累计
		,STKF_TRAN_FEE_YTD    		--股基过户费_年累计
		,STKF_NET_CMS_YTD     		--股基净佣金_年累计
		,BOND_CMS_YTD         		--债券佣金_年累计
		,BOND_NET_CMS_YTD     		--债券净佣金_年累计
		,REPQ_CMS_YTD         		--报价回购佣金_年累计
		,REPQ_NET_CMS_YTD     		--报价回购净佣金_年累计
		,HGT_CMS_YTD   				--沪港通佣金_年累计
		,HGT_NET_CMS_YTD       		--沪港通净佣金_年累计
		,HGT_TRAN_FEE_YTD     		--沪港通过户费_年累计
		,SGT_CMS_YTD          		--深港通佣金_年累计
		,SGT_NET_CMS_YTD      		--深港通净佣金_年累计
		,SGT_TRAN_FEE_YTD     		--深港通过户费_年累计
		,BGDL_CMS_YTD         		--大宗交易佣金_年累计
		,BGDL_NET_CMS_YTD     		--大宗交易净佣金_年累计
		,BGDL_TRAN_FEE_YTD    		--大宗交易过户费_年累计
		,PSTK_OPTN_CMS_YTD    		--个股期权佣金_年累计
		,PSTK_OPTN_NET_CMS_YTD		--个股期权净佣金_年累计
		,CREDIT_ODI_CMS_YTD   		--融资融券普通佣金_年累计
		,CREDIT_ODI_NET_CMS_YTD 	--融资融券普通净佣金_年累计	
		,CREDIT_ODI_TRAN_FEE_YTD 	--融资融券普通过户费_年累计
		,CREDIT_CRED_CMS_YTD  		--融资融券信用佣金_年累计
		,CREDIT_CRED_NET_CMS_YTD 	--融资融券信用净佣金_年累计
		,CREDIT_CRED_TRAN_FEE_YTD 	--融资融券信用过户费_年累计
		,FIN_RECE_INT_YTD     		--融资应收利息_年累计
		,FIN_PAIDINT_YTD      		--融资实收利息_年累计
		,STKPLG_CMS_YTD       		--股票质押佣金_年累计
		,STKPLG_NET_CMS_YTD   		--股票质押净佣金_年累计
		,STKPLG_PAIDINT_YTD   		--股票质押实收利息_年累计
		,STKPLG_RECE_INT_YTD  		--股票质押应收利息_年累计
		,APPTBUYB_CMS_YTD     		--约定购回佣金_年累计
		,APPTBUYB_NET_CMS_YTD 		--约定购回净佣金_年累计
		,APPTBUYB_PAIDINT_YTD 		--约定购回实收利息_年累计
		,FIN_IE_YTD           		--融资利息支出_年累计
		,CRDT_STK_IE_YTD      		--融券利息支出_年累计
		,OTH_IE_YTD           		--其他利息支出_年累计
		,FEE_RECE_INT_YTD     		--费用应收利息_年累计
		,OTH_RECE_INT_YTD     		--其他应收利息_年累计
		,CREDIT_CPTL_COST_YTD 		--融资融券资金成本_年累计
	)		
	SELECT 
		 T1.YEAR                 				AS    YEAR                 			--年
		,T1.MTH                  				AS    MTH                  			--月
		,T1.BRH_ID              				AS    BRH_ID              	    	--营业部编码
		,T1.OCCUR_DT             				AS    OCCUR_DT             			--发生日期
		,T1.NET_CMS_MTD          				AS    NET_CMS_MTD          			--净佣金_月累计
		,T1.GROSS_CMS_MTD        				AS    GROSS_CMS_MTD        			--毛佣金_月累计
		,T1.SCDY_CMS_MTD         				AS    SCDY_CMS_MTD         			--二级佣金_月累计
		,T1.SCDY_NET_CMS_MTD     				AS    SCDY_NET_CMS_MTD     			--二级净佣金_月累计
		,T1.SCDY_TRAN_FEE_MTD    				AS    SCDY_TRAN_FEE_MTD    			--二级过户费_月累计
		,T1.ODI_TRD_TRAN_FEE_MTD 				AS    ODI_TRD_TRAN_FEE_MTD 			--普通交易过户费_月累计
		,T1.CRED_TRD_TRAN_FEE_MTD				AS    CRED_TRD_TRAN_FEE_MTD			--信用交易过户费_月累计
		,T1.STKF_CMS_MTD         				AS    STKF_CMS_MTD         			--股基佣金_月累计
		,T1.STKF_TRAN_FEE_MTD    				AS    STKF_TRAN_FEE_MTD    			--股基过户费_月累计
		,T1.STKF_NET_CMS_MTD     				AS    STKF_NET_CMS_MTD     			--股基净佣金_月累计
		,T1.BOND_CMS_MTD         				AS    BOND_CMS_MTD         			--债券佣金_月累计
		,T1.BOND_NET_CMS_MTD     				AS    BOND_NET_CMS_MTD     			--债券净佣金_月累计
		,T1.REPQ_CMS_MTD         				AS    REPQ_CMS_MTD         			--报价回购佣金_月累计
		,T1.REPQ_NET_CMS_MTD     				AS    REPQ_NET_CMS_MTD     			--报价回购净佣金_月累计
		,T1.HGT_CMS_MTD          				AS    HGT_CMS_MTD          			--沪港通佣金_月累计
		,T1.HGT_NET_CMS_MTD      				AS    HGT_NET_CMS_MTD      			--沪港通净佣金_月累计
		,T1.HGT_TRAN_FEE_MTD     				AS    HGT_TRAN_FEE_MTD     			--沪港通过户费_月累计
		,T1.SGT_CMS_MTD          				AS    SGT_CMS_MTD          			--深港通佣金_月累计
		,T1.SGT_NET_CMS_MTD      				AS    SGT_NET_CMS_MTD      			--深港通净佣金_月累计
		,T1.SGT_TRAN_FEE_MTD     				AS    SGT_TRAN_FEE_MTD     			--深港通过户费_月累计
		,T1.BGDL_CMS_MTD         				AS    BGDL_CMS_MTD         			--大宗交易佣金_月累计
		,T1.BGDL_NET_CMS_MTD     				AS    BGDL_NET_CMS_MTD     			--大宗交易净佣金_月累计
		,T1.BGDL_TRAN_FEE_MTD    				AS    BGDL_TRAN_FEE_MTD    			--大宗交易过户费_月累计
		,T1.PSTK_OPTN_CMS_MTD    				AS    PSTK_OPTN_CMS_MTD    			--个股期权佣金_月累计
		,T1.PSTK_OPTN_NET_CMS_MTD 				AS    PSTK_OPTN_NET_CMS_MTD 		--个股期权净佣金_月累计
		,T1.CREDIT_ODI_CMS_MTD   				AS    CREDIT_ODI_CMS_MTD   			--融资融券普通佣金_月累计
		,T1.CREDIT_ODI_NET_CMS_MTD 				AS    CREDIT_ODI_NET_CMS_MTD 		--融资融券普通净佣金_月累计
		,T1.CREDIT_ODI_TRAN_FEE_MTD 			AS    CREDIT_ODI_TRAN_FEE_MTD 		--融资融券普通过户费_月累计
		,T1.CREDIT_CRED_CMS_MTD  				AS    CREDIT_CRED_CMS_MTD  			--融资融券信用佣金_月累计
		,T1.CREDIT_CRED_NET_CMS_MTD 			AS    CREDIT_CRED_NET_CMS_MTD 		--融资融券信用净佣金_月累计
		,T1.CREDIT_CRED_TRAN_FEE_MTD 			AS    CREDIT_CRED_TRAN_FEE_MTD 		--融资融券信用过户费_月累计
		,T1.FIN_RECE_INT_MTD     				AS    FIN_RECE_INT_MTD     			--融资应收利息_月累计
		,T1.FIN_PAIDINT_MTD      				AS    FIN_PAIDINT_MTD      			--融资实收利息_月累计
		,T1.STKPLG_CMS_MTD       				AS    STKPLG_CMS_MTD       			--股票质押佣金_月累计
		,T1.STKPLG_NET_CMS_MTD   				AS    STKPLG_NET_CMS_MTD   			--股票质押净佣金_月累计
		,T1.STKPLG_PAIDINT_MTD   				AS    STKPLG_PAIDINT_MTD   			--股票质押实收利息_月累计
		,T1.STKPLG_RECE_INT_MTD  				AS    STKPLG_RECE_INT_MTD  			--股票质押应收利息_月累计
		,T1.APPTBUYB_CMS_MTD     				AS    APPTBUYB_CMS_MTD     			--约定购回佣金_月累计
		,T1.APPTBUYB_NET_CMS_MTD 				AS    APPTBUYB_NET_CMS_MTD 			--约定购回净佣金_月累计
		,T1.APPTBUYB_PAIDINT_MTD 				AS    APPTBUYB_PAIDINT_MTD 			--约定购回实收利息_月累计
		,T1.FIN_IE_MTD           				AS    FIN_IE_MTD           			--融资利息支出_月累计
		,T1.CRDT_STK_IE_MTD      				AS    CRDT_STK_IE_MTD      			--融券利息支出_月累计
		,T1.OTH_IE_MTD           				AS    OTH_IE_MTD           			--其他利息支出_月累计
		,T1.FEE_RECE_INT_MTD     				AS    FEE_RECE_INT_MTD     			--费用应收利息_月累计
		,T1.OTH_RECE_INT_MTD     				AS    OTH_RECE_INT_MTD     			--其他应收利息_月累计
		,T1.CREDIT_CPTL_COST_MTD 				AS    CREDIT_CPTL_COST_MTD 			--融资融券资金成本_月累计
		,T2.NET_CMS_YTD          				AS    NET_CMS_YTD          			--净佣金_年累计
		,T2.GROSS_CMS_YTD        				AS    GROSS_CMS_YTD        			--毛佣金_年累计
		,T2.SCDY_CMS_YTD         				AS    SCDY_CMS_YTD         			--二级佣金_年累计
		,T2.SCDY_NET_CMS_YTD     				AS    SCDY_NET_CMS_YTD     			--二级净佣金_年累计
		,T2.SCDY_TRAN_FEE_YTD    				AS    SCDY_TRAN_FEE_YTD    			--二级过户费_年累计
		,T2.ODI_TRD_TRAN_FEE_YTD 				AS    ODI_TRD_TRAN_FEE_YTD 			--普通交易过户费_年累计
		,T2.CRED_TRD_TRAN_FEE_YTD				AS    CRED_TRD_TRAN_FEE_YTD			--信用交易过户费_年累计
		,T2.STKF_CMS_YTD         				AS    STKF_CMS_YTD         			--股基佣金_年累计
		,T2.STKF_TRAN_FEE_YTD    				AS    STKF_TRAN_FEE_YTD    			--股基过户费_年累计
		,T2.STKF_NET_CMS_YTD     				AS    STKF_NET_CMS_YTD     			--股基净佣金_年累计
		,T2.BOND_CMS_YTD         				AS    BOND_CMS_YTD         			--债券佣金_年累计
		,T2.BOND_NET_CMS_YTD     				AS    BOND_NET_CMS_YTD     			--债券净佣金_年累计
		,T2.REPQ_CMS_YTD         				AS    REPQ_CMS_YTD         			--报价回购佣金_年累计
		,T2.REPQ_NET_CMS_YTD     				AS    REPQ_NET_CMS_YTD     			--报价回购净佣金_年累计
		,T2.HGT_CMS_YTD   						AS    HGT_CMS_YTD   				--沪港通佣金_年累计
		,T2.HGT_NET_CMS_YTD      				AS    HGT_NET_CMS_YTD       		--沪港通净佣金_年累计
		,T2.HGT_TRAN_FEE_YTD     				AS    HGT_TRAN_FEE_YTD     			--沪港通过户费_年累计
		,T2.SGT_CMS_YTD          				AS    SGT_CMS_YTD          			--深港通佣金_年累计
		,T2.SGT_NET_CMS_YTD      				AS    SGT_NET_CMS_YTD      			--深港通净佣金_年累计
		,T2.SGT_TRAN_FEE_YTD     				AS    SGT_TRAN_FEE_YTD     			--深港通过户费_年累计
		,T2.BGDL_CMS_YTD         				AS    BGDL_CMS_YTD         			--大宗交易佣金_年累计
		,T2.BGDL_NET_CMS_YTD     				AS    BGDL_NET_CMS_YTD     			--大宗交易净佣金_年累计
		,T2.BGDL_TRAN_FEE_YTD    				AS    BGDL_TRAN_FEE_YTD    			--大宗交易过户费_年累计
		,T2.PSTK_OPTN_CMS_YTD    				AS    PSTK_OPTN_CMS_YTD    			--个股期权佣金_年累计
		,T2.PSTK_OPTN_NET_CMS_YTD				AS    PSTK_OPTN_NET_CMS_YTD			--个股期权净佣金_年累计
		,T2.CREDIT_ODI_CMS_YTD   				AS    CREDIT_ODI_CMS_YTD   			--融资融券普通佣金_年累计
		,T2.CREDIT_ODI_NET_CMS_YTD 				AS    CREDIT_ODI_NET_CMS_YTD 		--融资融券普通净佣金_年累计	
		,T2.CREDIT_ODI_TRAN_FEE_YTD 			AS    CREDIT_ODI_TRAN_FEE_YTD 		--融资融券普通过户费_年累计
		,T2.CREDIT_CRED_CMS_YTD  				AS    CREDIT_CRED_CMS_YTD  			--融资融券信用佣金_年累计
		,T2.CREDIT_CRED_NET_CMS_YTD 			AS    CREDIT_CRED_NET_CMS_YTD 		--融资融券信用净佣金_年累计
		,T2.CREDIT_CRED_TRAN_FEE_YTD 			AS    CREDIT_CRED_TRAN_FEE_YTD 		--融资融券信用过户费_年累计
		,T2.FIN_RECE_INT_YTD     				AS    FIN_RECE_INT_YTD     			--融资应收利息_年累计
		,T2.FIN_PAIDINT_YTD      				AS    FIN_PAIDINT_YTD      			--融资实收利息_年累计
		,T2.STKPLG_CMS_YTD       				AS    STKPLG_CMS_YTD       			--股票质押佣金_年累计
		,T2.STKPLG_NET_CMS_YTD   				AS    STKPLG_NET_CMS_YTD   			--股票质押净佣金_年累计
		,T2.STKPLG_PAIDINT_YTD   				AS    STKPLG_PAIDINT_YTD   			--股票质押实收利息_年累计
		,T2.STKPLG_RECE_INT_YTD  				AS    STKPLG_RECE_INT_YTD  			--股票质押应收利息_年累计
		,T2.APPTBUYB_CMS_YTD     				AS    APPTBUYB_CMS_YTD     			--约定购回佣金_年累计
		,T2.APPTBUYB_NET_CMS_YTD 				AS    APPTBUYB_NET_CMS_YTD 			--约定购回净佣金_年累计
		,T2.APPTBUYB_PAIDINT_YTD 				AS    APPTBUYB_PAIDINT_YTD 			--约定购回实收利息_年累计
		,T2.FIN_IE_YTD           				AS    FIN_IE_YTD           			--融资利息支出_年累计
		,T2.CRDT_STK_IE_YTD      				AS    CRDT_STK_IE_YTD      			--融券利息支出_年累计
		,T2.OTH_IE_YTD           				AS    OTH_IE_YTD           			--其他利息支出_年累计
		,T2.FEE_RECE_INT_YTD     				AS    FEE_RECE_INT_YTD     			--费用应收利息_年累计
		,T2.OTH_RECE_INT_YTD     				AS    OTH_RECE_INT_YTD     			--其他应收利息_年累计
		,T2.CREDIT_CPTL_COST_YTD 				AS    CREDIT_CPTL_COST_YTD 			--融资融券资金成本_年累计	
	FROM #TMP_T_EVT_INCM_D_BRH_MTH T1,#TMP_T_EVT_INCM_D_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_INCM_M_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工收入事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-11
  简介：员工收入统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_INCM_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,EMP_ID							AS    EMP_ID                	--员工编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(NET_CMS)					AS    NET_CMS_MTD          		--净佣金_月累计
		,SUM(GROSS_CMS)					AS    GROSS_CMS_MTD        		--毛佣金_月累计
		,SUM(SCDY_CMS)					AS    SCDY_CMS_MTD         		--二级佣金_月累计
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_MTD     		--二级净佣金_月累计
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_MTD    		--二级过户费_月累计
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_MTD 		--普通交易过户费_月累计
		,SUM(ODI_TRD_STP_TAX)			AS    ODI_TRD_STP_TAX_MTD  		--普通交易印花税_月累计
		,SUM(ODI_TRD_HANDLE_FEE)		AS    ODI_TRD_HANDLE_FEE_MTD 	--普通交易经手费_月累计
		,SUM(ODI_TRD_SEC_RGLT_FEE)		AS    ODI_TRD_SEC_RGLT_FEE_MTD 	--普通交易证管费 _月累计
		,SUM(ODI_TRD_ORDR_FEE)			AS    ODI_TRD_ORDR_FEE_MTD 		--普通交易委托费_月累计
		,SUM(ODI_TRD_OTH_FEE)			AS    ODI_TRD_OTH_FEE_MTD  		--普通交易其他费用_月累计
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_MTD		--信用交易过户费_月累计
		,SUM(CRED_TRD_STP_TAX)			AS    CRED_TRD_STP_TAX_MTD 		--信用交易印花税_月累计
		,SUM(CRED_TRD_HANDLE_FEE)		AS    CRED_TRD_HANDLE_FEE_MTD 	--信用交易经手费_月累计
		,SUM(CRED_TRD_SEC_RGLT_FEE)		AS    CRED_TRD_SEC_RGLT_FEE_MTD --信用交易证管费_月累计
		,SUM(CRED_TRD_ORDR_FEE)			AS    CRED_TRD_ORDR_FEE_MTD 	--信用交易委托费_月累计
		,SUM(CRED_TRD_OTH_FEE)			AS    CRED_TRD_OTH_FEE_MTD 		--信用交易其他费用_月累计
		,SUM(STKF_CMS)					AS    STKF_CMS_MTD         		--股基佣金_月累计
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_MTD    		--股基过户费_月累计
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_MTD     		--股基净佣金_月累计
		,SUM(BOND_CMS)					AS    BOND_CMS_MTD         		--债券佣金_月累计
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_MTD     		--债券净佣金_月累计
		,SUM(REPQ_CMS)					AS    REPQ_CMS_MTD         		--报价回购佣金_月累计
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_MTD     		--报价回购净佣金_月累计
		,SUM(HGT_CMS)					AS    HGT_CMS_MTD          		--沪港通佣金_月累计
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_MTD      		--沪港通净佣金_月累计
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_MTD     		--沪港通过户费_月累计
		,SUM(SGT_CMS)					AS    SGT_CMS_MTD          		--深港通佣金_月累计
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_MTD      		--深港通净佣金_月累计
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_MTD     		--深港通过户费_月累计
		,SUM(BGDL_CMS)					AS    BGDL_CMS_MTD         		--大宗交易佣金_月累计
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_MTD     		--大宗交易净佣金_月累计
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_MTD    		--大宗交易过户费_月累计
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_MTD    		--个股期权佣金_月累计
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_MTD 	--个股期权净佣金_月累计
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_MTD   		--融资融券普通佣金_月累计
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_MTD 	--融资融券普通净佣金_月累计
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_MTD 	--融资融券普通过户费_月累计
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_MTD  		--融资融券信用佣金_月累计
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_MTD 	--融资融券信用净佣金_月累计
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_MTD 	--融资融券信用过户费_月累计
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_MTD     		--融资应收利息_月累计
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_MTD      		--融资实收利息_月累计
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_MTD       		--股票质押佣金_月累计
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_MTD   		--股票质押净佣金_月累计
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_MTD   		--股票质押实收利息_月累计
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_MTD  		--股票质押应收利息_月累计
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_MTD     		--约定购回佣金_月累计
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_MTD 		--约定购回净佣金_月累计
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_MTD 		--约定购回实收利息_月累计
		,SUM(FIN_IE)					AS    FIN_IE_MTD           		--融资利息支出_月累计
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_MTD      		--融券利息支出_月累计
		,SUM(OTH_IE)					AS    OTH_IE_MTD           		--其他利息支出_月累计
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_MTD     		--费用应收利息_月累计
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_MTD     		--其他应收利息_月累计
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_MTD 		--融资融券资金成本_月累计
	INTO #TMP_T_EVT_INCM_D_EMP_MTH
	FROM DM.T_EVT_INCM_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	-- 统计年指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,EMP_ID							AS    EMP_ID                	--员工编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(NET_CMS)					AS    NET_CMS_YTD          		--净佣金_年累计
		,SUM(GROSS_CMS)					AS    GROSS_CMS_YTD        		--毛佣金_年累计
		,SUM(SCDY_CMS)					AS    SCDY_CMS_YTD         		--二级佣金_年累计
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_YTD     		--二级净佣金_年累计
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_YTD    		--二级过户费_年累计
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_YTD 		--普通交易过户费_年累计
		,SUM(ODI_TRD_STP_TAX)			AS    ODI_TRD_STP_TAX_YTD  		--普通交易印花税_年累计
		,SUM(ODI_TRD_HANDLE_FEE)		AS    ODI_TRD_HANDLE_FEE_YTD 	--普通交易经手费_年累计
		,SUM(ODI_TRD_SEC_RGLT_FEE)		AS    ODI_TRD_SEC_RGLT_FEE_YTD 	--普通交易证管费 _年累计
		,SUM(ODI_TRD_ORDR_FEE)			AS    ODI_TRD_ORDR_FEE_YTD 		--普通交易委托费_年累计
		,SUM(ODI_TRD_OTH_FEE)			AS    ODI_TRD_OTH_FEE_YTD  		--普通交易其他费用_年累计
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_YTD		--信用交易过户费_年累计
		,SUM(CRED_TRD_STP_TAX)			AS    CRED_TRD_STP_TAX_YTD 		--信用交易印花税_年累计
		,SUM(CRED_TRD_HANDLE_FEE)		AS    CRED_TRD_HANDLE_FEE_YTD 	--信用交易经手费_年累计
		,SUM(CRED_TRD_SEC_RGLT_FEE)		AS    CRED_TRD_SEC_RGLT_FEE_YTD --信用交易证管费_年累计
		,SUM(CRED_TRD_ORDR_FEE)			AS    CRED_TRD_ORDR_FEE_YTD 	--信用交易委托费_年累计
		,SUM(CRED_TRD_OTH_FEE)			AS    CRED_TRD_OTH_FEE_YTD 		--信用交易其他费用_年累计
		,SUM(STKF_CMS)					AS    STKF_CMS_YTD         		--股基佣金_年累计
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_YTD    		--股基过户费_年累计
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_YTD     		--股基净佣金_年累计
		,SUM(BOND_CMS)					AS    BOND_CMS_YTD         		--债券佣金_年累计
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_YTD     		--债券净佣金_年累计
		,SUM(REPQ_CMS)					AS    REPQ_CMS_YTD         		--报价回购佣金_年累计
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_YTD     		--报价回购净佣金_年累计
		,SUM(HGT_CMS)					AS    HGT_CMS_YTD          		--沪港通佣金_年累计
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_YTD      		--沪港通净佣金_年累计
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_YTD     		--沪港通过户费_年累计
		,SUM(SGT_CMS)					AS    SGT_CMS_YTD          		--深港通佣金_年累计
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_YTD      		--深港通净佣金_年累计
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_YTD     		--深港通过户费_年累计
		,SUM(BGDL_CMS)					AS    BGDL_CMS_YTD         		--大宗交易佣金_年累计
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_YTD     		--大宗交易净佣金_年累计
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_YTD    		--大宗交易过户费_年累计
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_YTD    		--个股期权佣金_年累计
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_YTD 	--个股期权净佣金_年累计
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_YTD   		--融资融券普通佣金_年累计
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_YTD 	--融资融券普通净佣金_年累计
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_YTD 	--融资融券普通过户费_年累计
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_YTD  		--融资融券信用佣金_年累计
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_YTD 	--融资融券信用净佣金_年累计
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_YTD 	--融资融券信用过户费_年累计
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_YTD     		--融资应收利息_年累计
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_YTD      		--融资实收利息_年累计
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_YTD       		--股票质押佣金_年累计
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_YTD   		--股票质押净佣金_年累计
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_YTD   		--股票质押实收利息_年累计
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_YTD  		--股票质押应收利息_年累计
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_YTD     		--约定购回佣金_年累计
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_YTD 		--约定购回净佣金_年累计
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_YTD 		--约定购回实收利息_年累计
		,SUM(FIN_IE)					AS    FIN_IE_YTD           		--融资利息支出_年累计
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_YTD      		--融券利息支出_年累计
		,SUM(OTH_IE)					AS    OTH_IE_YTD           		--其他利息支出_年累计
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_YTD     		--费用应收利息_年累计
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_YTD     		--其他应收利息_年累计
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_YTD 		--融资融券资金成本_年累计
	INTO #TMP_T_EVT_INCM_D_EMP_YEAR
	FROM DM.T_EVT_INCM_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	--插入目标表
	INSERT INTO DM.T_EVT_INCM_M_EMP(
		 YEAR                 		--年
		,MTH                  		--月
		,EMP_ID               		--员工编码
		,OCCUR_DT             		--发生日期
		,NET_CMS_MTD          		--净佣金_月累计
		,GROSS_CMS_MTD        		--毛佣金_月累计
		,SCDY_CMS_MTD         		--二级佣金_月累计
		,SCDY_NET_CMS_MTD     		--二级净佣金_月累计
		,SCDY_TRAN_FEE_MTD    		--二级过户费_月累计
		,ODI_TRD_TRAN_FEE_MTD 		--普通交易过户费_月累计
		,ODI_TRD_STP_TAX_MTD  		--普通交易印花税_月累计
		,ODI_TRD_HANDLE_FEE_MTD 	--普通交易经手费_月累计
		,ODI_TRD_SEC_RGLT_FEE_MTD 	--普通交易证管费 _月累计
		,ODI_TRD_ORDR_FEE_MTD 		--普通交易委托费_月累计
		,ODI_TRD_OTH_FEE_MTD  		--普通交易其他费用_月累计
		,CRED_TRD_TRAN_FEE_MTD		--信用交易过户费_月累计
		,CRED_TRD_STP_TAX_MTD 		--信用交易印花税_月累计
		,CRED_TRD_HANDLE_FEE_MTD 	--信用交易经手费_月累计
		,CRED_TRD_SEC_RGLT_FEE_MTD 	--信用交易证管费_月累计
		,CRED_TRD_ORDR_FEE_MTD 		--信用交易委托费_月累计
		,CRED_TRD_OTH_FEE_MTD 		--信用交易其他费用_月累计
		,STKF_CMS_MTD         		--股基佣金_月累计
		,STKF_TRAN_FEE_MTD    		--股基过户费_月累计
		,STKF_NET_CMS_MTD     		--股基净佣金_月累计
		,BOND_CMS_MTD         		--债券佣金_月累计
		,BOND_NET_CMS_MTD     		--债券净佣金_月累计
		,REPQ_CMS_MTD         		--报价回购佣金_月累计
		,REPQ_NET_CMS_MTD     		--报价回购净佣金_月累计
		,HGT_CMS_MTD          		--沪港通佣金_月累计
		,HGT_NET_CMS_MTD      		--沪港通净佣金_月累计
		,HGT_TRAN_FEE_MTD     		--沪港通过户费_月累计
		,SGT_CMS_MTD          		--深港通佣金_月累计
		,SGT_NET_CMS_MTD      		--深港通净佣金_月累计
		,SGT_TRAN_FEE_MTD     		--深港通过户费_月累计
		,BGDL_CMS_MTD         		--大宗交易佣金_月累计
		,BGDL_NET_CMS_MTD     		--大宗交易净佣金_月累计
		,BGDL_TRAN_FEE_MTD    		--大宗交易过户费_月累计
		,PSTK_OPTN_CMS_MTD    		--个股期权佣金_月累计
		,PSTK_OPTN_NET_CMS_MTD 		--个股期权净佣金_月累计
		,CREDIT_ODI_CMS_MTD   		--融资融券普通佣金_月累计
		,CREDIT_ODI_NET_CMS_MTD 	--融资融券普通净佣金_月累计
		,CREDIT_ODI_TRAN_FEE_MTD 	--融资融券普通过户费_月累计
		,CREDIT_CRED_CMS_MTD  		--融资融券信用佣金_月累计
		,CREDIT_CRED_NET_CMS_MTD 	--融资融券信用净佣金_月累计
		,CREDIT_CRED_TRAN_FEE_MTD 	--融资融券信用过户费_月累计
		,FIN_RECE_INT_MTD     		--融资应收利息_月累计
		,FIN_PAIDINT_MTD      		--融资实收利息_月累计
		,STKPLG_CMS_MTD       		--股票质押佣金_月累计
		,STKPLG_NET_CMS_MTD   		--股票质押净佣金_月累计
		,STKPLG_PAIDINT_MTD   		--股票质押实收利息_月累计
		,STKPLG_RECE_INT_MTD  		--股票质押应收利息_月累计
		,APPTBUYB_CMS_MTD     		--约定购回佣金_月累计
		,APPTBUYB_NET_CMS_MTD 		--约定购回净佣金_月累计
		,APPTBUYB_PAIDINT_MTD 		--约定购回实收利息_月累计
		,FIN_IE_MTD           		--融资利息支出_月累计
		,CRDT_STK_IE_MTD      		--融券利息支出_月累计
		,OTH_IE_MTD           		--其他利息支出_月累计
		,FEE_RECE_INT_MTD     		--费用应收利息_月累计
		,OTH_RECE_INT_MTD     		--其他应收利息_月累计
		,CREDIT_CPTL_COST_MTD 		--融资融券资金成本_月累计
		,NET_CMS_YTD          		--净佣金_年累计
		,GROSS_CMS_YTD        		--毛佣金_年累计
		,SCDY_CMS_YTD         		--二级佣金_年累计
		,SCDY_NET_CMS_YTD     		--二级净佣金_年累计
		,SCDY_TRAN_FEE_YTD    		--二级过户费_年累计
		,ODI_TRD_TRAN_FEE_YTD 		--普通交易过户费_年累计
		,ODI_TRD_STP_TAX_YTD  		--普通交易印花税_年累计
		,ODI_TRD_HANDLE_FEE_YTD 	--普通交易经手费_年累计	
		,ODI_TRD_SEC_RGLT_FEE_YTD 	--普通交易证管费 _年累计
		,ODI_TRD_ORDR_FEE_YTD 		--普通交易委托费_年累计
		,ODI_TRD_OTH_FEE_YTD  		--普通交易其他费用_年累计
		,CRED_TRD_TRAN_FEE_YTD		--信用交易过户费_年累计
		,CRED_TRD_STP_TAX_YTD 		--信用交易印花税_年累计
		,CRED_TRD_HANDLE_FEE_YTD 	--信用交易经手费_年累计
		,CRED_TRD_SEC_RGLT_FEE_YTD 	--信用交易证管费_年累计
		,CRED_TRD_ORDR_FEE_YTD 		--信用交易委托费_年累计
		,CRED_TRD_OTH_FEE_YTD 		--信用交易其他费用_年累计
		,STKF_CMS_YTD         		--股基佣金_年累计
		,STKF_TRAN_FEE_YTD    		--股基过户费_年累计
		,STKF_NET_CMS_YTD     		--股基净佣金_年累计
		,BOND_CMS_YTD         		--债券佣金_年累计
		,BOND_NET_CMS_YTD     		--债券净佣金_年累计
		,REPQ_CMS_YTD         		--报价回购佣金_年累计
		,REPQ_NET_CMS_YTD     		--报价回购净佣金_年累计
		,HGT_CMS_YTD   				--沪港通佣金_年累计
		,HGT_NET_CMS_YTD       		--沪港通净佣金_年累计
		,HGT_TRAN_FEE_YTD     		--沪港通过户费_年累计
		,SGT_CMS_YTD          		--深港通佣金_年累计
		,SGT_NET_CMS_YTD      		--深港通净佣金_年累计
		,SGT_TRAN_FEE_YTD     		--深港通过户费_年累计
		,BGDL_CMS_YTD         		--大宗交易佣金_年累计
		,BGDL_NET_CMS_YTD     		--大宗交易净佣金_年累计
		,BGDL_TRAN_FEE_YTD    		--大宗交易过户费_年累计
		,PSTK_OPTN_CMS_YTD    		--个股期权佣金_年累计
		,PSTK_OPTN_NET_CMS_YTD		--个股期权净佣金_年累计
		,CREDIT_ODI_CMS_YTD   		--融资融券普通佣金_年累计
		,CREDIT_ODI_NET_CMS_YTD 	--融资融券普通净佣金_年累计	
		,CREDIT_ODI_TRAN_FEE_YTD 	--融资融券普通过户费_年累计
		,CREDIT_CRED_CMS_YTD  		--融资融券信用佣金_年累计
		,CREDIT_CRED_NET_CMS_YTD 	--融资融券信用净佣金_年累计
		,CREDIT_CRED_TRAN_FEE_YTD 	--融资融券信用过户费_年累计
		,FIN_RECE_INT_YTD     		--融资应收利息_年累计
		,FIN_PAIDINT_YTD      		--融资实收利息_年累计
		,STKPLG_CMS_YTD       		--股票质押佣金_年累计
		,STKPLG_NET_CMS_YTD   		--股票质押净佣金_年累计
		,STKPLG_PAIDINT_YTD   		--股票质押实收利息_年累计
		,STKPLG_RECE_INT_YTD  		--股票质押应收利息_年累计
		,APPTBUYB_CMS_YTD     		--约定购回佣金_年累计
		,APPTBUYB_NET_CMS_YTD 		--约定购回净佣金_年累计
		,APPTBUYB_PAIDINT_YTD 		--约定购回实收利息_年累计
		,FIN_IE_YTD           		--融资利息支出_年累计
		,CRDT_STK_IE_YTD      		--融券利息支出_年累计
		,OTH_IE_YTD           		--其他利息支出_年累计
		,FEE_RECE_INT_YTD     		--费用应收利息_年累计
		,OTH_RECE_INT_YTD     		--其他应收利息_年累计
		,CREDIT_CPTL_COST_YTD 		--融资融券资金成本_年累计
	)		
	SELECT 
		 T1.YEAR                 				AS    YEAR                 			--年
		,T1.MTH                  				AS    MTH                  			--月
		,T1.EMP_ID               				AS    EMP_ID               			--员工编码
		,T1.OCCUR_DT             				AS    OCCUR_DT             			--发生日期
		,T1.NET_CMS_MTD          				AS    NET_CMS_MTD          			--净佣金_月累计
		,T1.GROSS_CMS_MTD        				AS    GROSS_CMS_MTD        			--毛佣金_月累计
		,T1.SCDY_CMS_MTD         				AS    SCDY_CMS_MTD         			--二级佣金_月累计
		,T1.SCDY_NET_CMS_MTD     				AS    SCDY_NET_CMS_MTD     			--二级净佣金_月累计
		,T1.SCDY_TRAN_FEE_MTD    				AS    SCDY_TRAN_FEE_MTD    			--二级过户费_月累计
		,T1.ODI_TRD_TRAN_FEE_MTD 				AS    ODI_TRD_TRAN_FEE_MTD 			--普通交易过户费_月累计
		,T1.ODI_TRD_STP_TAX_MTD  				AS    ODI_TRD_STP_TAX_MTD  			--普通交易印花税_月累计
		,T1.ODI_TRD_HANDLE_FEE_MTD 				AS    ODI_TRD_HANDLE_FEE_MTD 		--普通交易经手费_月累计
		,T1.ODI_TRD_SEC_RGLT_FEE_MTD 			AS    ODI_TRD_SEC_RGLT_FEE_MTD 		--普通交易证管费 _月累计
		,T1.ODI_TRD_ORDR_FEE_MTD 				AS    ODI_TRD_ORDR_FEE_MTD 			--普通交易委托费_月累计
		,T1.ODI_TRD_OTH_FEE_MTD  				AS    ODI_TRD_OTH_FEE_MTD  			--普通交易其他费用_月累计
		,T1.CRED_TRD_TRAN_FEE_MTD				AS    CRED_TRD_TRAN_FEE_MTD			--信用交易过户费_月累计
		,T1.CRED_TRD_STP_TAX_MTD 				AS    CRED_TRD_STP_TAX_MTD 			--信用交易印花税_月累计
		,T1.CRED_TRD_HANDLE_FEE_MTD 			AS    CRED_TRD_HANDLE_FEE_MTD 		--信用交易经手费_月累计
		,T1.CRED_TRD_SEC_RGLT_FEE_MTD 			AS    CRED_TRD_SEC_RGLT_FEE_MTD 	--信用交易证管费_月累计
		,T1.CRED_TRD_ORDR_FEE_MTD 				AS    CRED_TRD_ORDR_FEE_MTD 		--信用交易委托费_月累计
		,T1.CRED_TRD_OTH_FEE_MTD 				AS    CRED_TRD_OTH_FEE_MTD 			--信用交易其他费用_月累计
		,T1.STKF_CMS_MTD         				AS    STKF_CMS_MTD         			--股基佣金_月累计
		,T1.STKF_TRAN_FEE_MTD    				AS    STKF_TRAN_FEE_MTD    			--股基过户费_月累计
		,T1.STKF_NET_CMS_MTD     				AS    STKF_NET_CMS_MTD     			--股基净佣金_月累计
		,T1.BOND_CMS_MTD         				AS    BOND_CMS_MTD         			--债券佣金_月累计
		,T1.BOND_NET_CMS_MTD     				AS    BOND_NET_CMS_MTD     			--债券净佣金_月累计
		,T1.REPQ_CMS_MTD         				AS    REPQ_CMS_MTD         			--报价回购佣金_月累计
		,T1.REPQ_NET_CMS_MTD     				AS    REPQ_NET_CMS_MTD     			--报价回购净佣金_月累计
		,T1.HGT_CMS_MTD          				AS    HGT_CMS_MTD          			--沪港通佣金_月累计
		,T1.HGT_NET_CMS_MTD      				AS    HGT_NET_CMS_MTD      			--沪港通净佣金_月累计
		,T1.HGT_TRAN_FEE_MTD     				AS    HGT_TRAN_FEE_MTD     			--沪港通过户费_月累计
		,T1.SGT_CMS_MTD          				AS    SGT_CMS_MTD          			--深港通佣金_月累计
		,T1.SGT_NET_CMS_MTD      				AS    SGT_NET_CMS_MTD      			--深港通净佣金_月累计
		,T1.SGT_TRAN_FEE_MTD     				AS    SGT_TRAN_FEE_MTD     			--深港通过户费_月累计
		,T1.BGDL_CMS_MTD         				AS    BGDL_CMS_MTD         			--大宗交易佣金_月累计
		,T1.BGDL_NET_CMS_MTD     				AS    BGDL_NET_CMS_MTD     			--大宗交易净佣金_月累计
		,T1.BGDL_TRAN_FEE_MTD    				AS    BGDL_TRAN_FEE_MTD    			--大宗交易过户费_月累计
		,T1.PSTK_OPTN_CMS_MTD    				AS    PSTK_OPTN_CMS_MTD    			--个股期权佣金_月累计
		,T1.PSTK_OPTN_NET_CMS_MTD 				AS    PSTK_OPTN_NET_CMS_MTD 		--个股期权净佣金_月累计
		,T1.CREDIT_ODI_CMS_MTD   				AS    CREDIT_ODI_CMS_MTD   			--融资融券普通佣金_月累计
		,T1.CREDIT_ODI_NET_CMS_MTD 				AS    CREDIT_ODI_NET_CMS_MTD 		--融资融券普通净佣金_月累计
		,T1.CREDIT_ODI_TRAN_FEE_MTD 			AS    CREDIT_ODI_TRAN_FEE_MTD 		--融资融券普通过户费_月累计
		,T1.CREDIT_CRED_CMS_MTD  				AS    CREDIT_CRED_CMS_MTD  			--融资融券信用佣金_月累计
		,T1.CREDIT_CRED_NET_CMS_MTD 			AS    CREDIT_CRED_NET_CMS_MTD 		--融资融券信用净佣金_月累计
		,T1.CREDIT_CRED_TRAN_FEE_MTD 			AS    CREDIT_CRED_TRAN_FEE_MTD 		--融资融券信用过户费_月累计
		,T1.FIN_RECE_INT_MTD     				AS    FIN_RECE_INT_MTD     			--融资应收利息_月累计
		,T1.FIN_PAIDINT_MTD      				AS    FIN_PAIDINT_MTD      			--融资实收利息_月累计
		,T1.STKPLG_CMS_MTD       				AS    STKPLG_CMS_MTD       			--股票质押佣金_月累计
		,T1.STKPLG_NET_CMS_MTD   				AS    STKPLG_NET_CMS_MTD   			--股票质押净佣金_月累计
		,T1.STKPLG_PAIDINT_MTD   				AS    STKPLG_PAIDINT_MTD   			--股票质押实收利息_月累计
		,T1.STKPLG_RECE_INT_MTD  				AS    STKPLG_RECE_INT_MTD  			--股票质押应收利息_月累计
		,T1.APPTBUYB_CMS_MTD     				AS    APPTBUYB_CMS_MTD     			--约定购回佣金_月累计
		,T1.APPTBUYB_NET_CMS_MTD 				AS    APPTBUYB_NET_CMS_MTD 			--约定购回净佣金_月累计
		,T1.APPTBUYB_PAIDINT_MTD 				AS    APPTBUYB_PAIDINT_MTD 			--约定购回实收利息_月累计
		,T1.FIN_IE_MTD           				AS    FIN_IE_MTD           			--融资利息支出_月累计
		,T1.CRDT_STK_IE_MTD      				AS    CRDT_STK_IE_MTD      			--融券利息支出_月累计
		,T1.OTH_IE_MTD           				AS    OTH_IE_MTD           			--其他利息支出_月累计
		,T1.FEE_RECE_INT_MTD     				AS    FEE_RECE_INT_MTD     			--费用应收利息_月累计
		,T1.OTH_RECE_INT_MTD     				AS    OTH_RECE_INT_MTD     			--其他应收利息_月累计
		,T1.CREDIT_CPTL_COST_MTD 				AS    CREDIT_CPTL_COST_MTD 			--融资融券资金成本_月累计
		,T2.NET_CMS_YTD          				AS    NET_CMS_YTD          			--净佣金_年累计
		,T2.GROSS_CMS_YTD        				AS    GROSS_CMS_YTD        			--毛佣金_年累计
		,T2.SCDY_CMS_YTD         				AS    SCDY_CMS_YTD         			--二级佣金_年累计
		,T2.SCDY_NET_CMS_YTD     				AS    SCDY_NET_CMS_YTD     			--二级净佣金_年累计
		,T2.SCDY_TRAN_FEE_YTD    				AS    SCDY_TRAN_FEE_YTD    			--二级过户费_年累计
		,T2.ODI_TRD_TRAN_FEE_YTD 				AS    ODI_TRD_TRAN_FEE_YTD 			--普通交易过户费_年累计
		,T2.ODI_TRD_STP_TAX_YTD  				AS    ODI_TRD_STP_TAX_YTD  			--普通交易印花税_年累计
		,T2.ODI_TRD_HANDLE_FEE_YTD 				AS    ODI_TRD_HANDLE_FEE_YTD 		--普通交易经手费_年累计	
		,T2.ODI_TRD_SEC_RGLT_FEE_YTD 			AS    ODI_TRD_SEC_RGLT_FEE_YTD 		--普通交易证管费 _年累计
		,T2.ODI_TRD_ORDR_FEE_YTD 				AS    ODI_TRD_ORDR_FEE_YTD 			--普通交易委托费_年累计
		,T2.ODI_TRD_OTH_FEE_YTD  				AS    ODI_TRD_OTH_FEE_YTD  			--普通交易其他费用_年累计
		,T2.CRED_TRD_TRAN_FEE_YTD				AS    CRED_TRD_TRAN_FEE_YTD			--信用交易过户费_年累计
		,T2.CRED_TRD_STP_TAX_YTD 				AS    CRED_TRD_STP_TAX_YTD 			--信用交易印花税_年累计
		,T2.CRED_TRD_HANDLE_FEE_YTD 			AS    CRED_TRD_HANDLE_FEE_YTD 		--信用交易经手费_年累计
		,T2.CRED_TRD_SEC_RGLT_FEE_YTD 			AS    CRED_TRD_SEC_RGLT_FEE_YTD 	--信用交易证管费_年累计
		,T2.CRED_TRD_ORDR_FEE_YTD 				AS    CRED_TRD_ORDR_FEE_YTD 		--信用交易委托费_年累计
		,T2.CRED_TRD_OTH_FEE_YTD 				AS    CRED_TRD_OTH_FEE_YTD 			--信用交易其他费用_年累计
		,T2.STKF_CMS_YTD         				AS    STKF_CMS_YTD         			--股基佣金_年累计
		,T2.STKF_TRAN_FEE_YTD    				AS    STKF_TRAN_FEE_YTD    			--股基过户费_年累计
		,T2.STKF_NET_CMS_YTD     				AS    STKF_NET_CMS_YTD     			--股基净佣金_年累计
		,T2.BOND_CMS_YTD         				AS    BOND_CMS_YTD         			--债券佣金_年累计
		,T2.BOND_NET_CMS_YTD     				AS    BOND_NET_CMS_YTD     			--债券净佣金_年累计
		,T2.REPQ_CMS_YTD         				AS    REPQ_CMS_YTD         			--报价回购佣金_年累计
		,T2.REPQ_NET_CMS_YTD     				AS    REPQ_NET_CMS_YTD     			--报价回购净佣金_年累计
		,T2.HGT_CMS_YTD   						AS    HGT_CMS_YTD   				--沪港通佣金_年累计
		,T2.HGT_NET_CMS_YTD      				AS    HGT_NET_CMS_YTD       		--沪港通净佣金_年累计
		,T2.HGT_TRAN_FEE_YTD     				AS    HGT_TRAN_FEE_YTD     			--沪港通过户费_年累计
		,T2.SGT_CMS_YTD          				AS    SGT_CMS_YTD          			--深港通佣金_年累计
		,T2.SGT_NET_CMS_YTD      				AS    SGT_NET_CMS_YTD      			--深港通净佣金_年累计
		,T2.SGT_TRAN_FEE_YTD     				AS    SGT_TRAN_FEE_YTD     			--深港通过户费_年累计
		,T2.BGDL_CMS_YTD         				AS    BGDL_CMS_YTD         			--大宗交易佣金_年累计
		,T2.BGDL_NET_CMS_YTD     				AS    BGDL_NET_CMS_YTD     			--大宗交易净佣金_年累计
		,T2.BGDL_TRAN_FEE_YTD    				AS    BGDL_TRAN_FEE_YTD    			--大宗交易过户费_年累计
		,T2.PSTK_OPTN_CMS_YTD    				AS    PSTK_OPTN_CMS_YTD    			--个股期权佣金_年累计
		,T2.PSTK_OPTN_NET_CMS_YTD				AS    PSTK_OPTN_NET_CMS_YTD			--个股期权净佣金_年累计
		,T2.CREDIT_ODI_CMS_YTD   				AS    CREDIT_ODI_CMS_YTD   			--融资融券普通佣金_年累计
		,T2.CREDIT_ODI_NET_CMS_YTD 				AS    CREDIT_ODI_NET_CMS_YTD 		--融资融券普通净佣金_年累计	
		,T2.CREDIT_ODI_TRAN_FEE_YTD 			AS    CREDIT_ODI_TRAN_FEE_YTD 		--融资融券普通过户费_年累计
		,T2.CREDIT_CRED_CMS_YTD  				AS    CREDIT_CRED_CMS_YTD  			--融资融券信用佣金_年累计
		,T2.CREDIT_CRED_NET_CMS_YTD 			AS    CREDIT_CRED_NET_CMS_YTD 		--融资融券信用净佣金_年累计
		,T2.CREDIT_CRED_TRAN_FEE_YTD 			AS    CREDIT_CRED_TRAN_FEE_YTD 		--融资融券信用过户费_年累计
		,T2.FIN_RECE_INT_YTD     				AS    FIN_RECE_INT_YTD     			--融资应收利息_年累计
		,T2.FIN_PAIDINT_YTD      				AS    FIN_PAIDINT_YTD      			--融资实收利息_年累计
		,T2.STKPLG_CMS_YTD       				AS    STKPLG_CMS_YTD       			--股票质押佣金_年累计
		,T2.STKPLG_NET_CMS_YTD   				AS    STKPLG_NET_CMS_YTD   			--股票质押净佣金_年累计
		,T2.STKPLG_PAIDINT_YTD   				AS    STKPLG_PAIDINT_YTD   			--股票质押实收利息_年累计
		,T2.STKPLG_RECE_INT_YTD  				AS    STKPLG_RECE_INT_YTD  			--股票质押应收利息_年累计
		,T2.APPTBUYB_CMS_YTD     				AS    APPTBUYB_CMS_YTD     			--约定购回佣金_年累计
		,T2.APPTBUYB_NET_CMS_YTD 				AS    APPTBUYB_NET_CMS_YTD 			--约定购回净佣金_年累计
		,T2.APPTBUYB_PAIDINT_YTD 				AS    APPTBUYB_PAIDINT_YTD 			--约定购回实收利息_年累计
		,T2.FIN_IE_YTD           				AS    FIN_IE_YTD           			--融资利息支出_年累计
		,T2.CRDT_STK_IE_YTD      				AS    CRDT_STK_IE_YTD      			--融券利息支出_年累计
		,T2.OTH_IE_YTD           				AS    OTH_IE_YTD           			--其他利息支出_年累计
		,T2.FEE_RECE_INT_YTD     				AS    FEE_RECE_INT_YTD     			--费用应收利息_年累计
		,T2.OTH_RECE_INT_YTD     				AS    OTH_RECE_INT_YTD     			--其他应收利息_年累计
		,T2.CREDIT_CPTL_COST_YTD 				AS    CREDIT_CPTL_COST_YTD 			--融资融券资金成本_年累计	
	FROM #TMP_T_EVT_INCM_D_EMP_MTH T1,#TMP_T_EVT_INCM_D_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_ITC_ORDR_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  程序功能: 场内交易事实表_日表
  编写者: 张琦
  创建日期: 2017-12-07
  简介：场内二级交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  
  commit;
  delete from DM.T_EVT_ITC_ORDR_TRD_D_D WHERE OCCUR_DT=@v_date;
  
  INSERT INTO DM.T_EVT_ITC_ORDR_TRD_D_D(
		CUST_ID
		,OCCUR_DT
		,BRH_ID
		,WH_ORDR_MODE_CD
		,ORDR_SITE
		,MKT_TYPE
		,SECU_TYPE
		,BUSE_DIR
		,ORDR_VOL
		,ORDR_AMT
		,ORDR_CNT
		,MTCH_VOL
		,MTCH_AMT
		,LOAD_DT
	)
	SELECT b.CLIENT_ID AS CUST_ID   -- 客户编码
		,@v_date AS OCCUR_DT         -- 业务日期
		,a.org_cd AS BRH_ID          -- 营业部编码
		,a.order_way_cd AS WH_ORDR_MODE_CD  -- 仓库委托方式代码
		,case when substring(a.order_station,1,2)='Y_' then '优理宝'
			when substring(a.order_station,1,2)='HS' then '同花顺手机'
			when substring(a.order_station,1,2)='T_' then '通达信'
			when substring(a.order_station,1,2)='H_' then '同花顺PC'
			when substring(a.order_station,1,2)='MP' then '恒生手机'
			when substring(a.order_station,1,2)='HW' then '同花顺WEB'
			when substring(a.order_station,1,2)='H5' then '微信H5'
			else '其他' end as ORDR_SITE  -- 委托站点
		,a.market_type_cd AS MKT_TYPE   -- 市场类型
		,case when coalesce(a.stock_type_cd,'')='' then '99' else a.stock_type_cd end AS SECU_TYPE   -- 证券类型
		,a.deal_type_cd AS BUSE_DIR      -- 买卖方向
		,sum(a.order_num) as ORDR_VOL   -- 委托数量
		,sum(a.order_num*a.order_price) as ORDR_AMT -- 委托金额
		,count(1) as ORDR_CNT       -- 委托笔数
		,sum(a.trad_num) as MTCH_VOL    -- 成交数量
		,sum(a.trad_amt) as MTCH_AMT    -- 成交金额
		,@v_date AS LOAD_DT        -- 清洗日期
	FROM DBA.T_EDW_T05_ORDER_JOUR a
	LEFT JOIN DBA.T_ODS_UF2_FUNDACCOUNT b on a.fund_acct=b.FUND_ACCOUNT
	WHERE a.LOAD_DT=@v_date
	group by b.CLIENT_ID, a.org_cd, a.order_way_cd, ORDR_SITE, a.market_type_cd
		,SECU_TYPE, a.deal_type_cd;
  
  
   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_ITC_ORDR_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_ITC_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  程序功能: 客户交易事实表_日表
  编写者: 张琦
  创建日期: 2017-12-08
  简介：记录客户场内交易汇总指标
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  
	commit;
	
	delete from dm.T_EVT_ITC_TRD_D_D where load_dt=@v_date;
	INSERT INTO DM.T_EVT_ITC_TRD_D_D(
		CUST_ID
		,BRH_NO
		,MKT_TYPE
		,SECU_TYPE_MCGY_ID
		,BUSE_DIR
		,SECU_TYPE_SUB_ID
		,OCCUR_DT
		,TRD_QTY
		,TRD_AMT
		,TRD_CNT
		,LOAD_DT
	)
	SELECT a.CLIENT_ID as CUST_ID
		,b.pk_org as BRH_NO
		,c.MKT_TYPE as MKT_TYPE
		,c.SEC_TYPE as SECU_TYPE_MCGY_ID
		,MAX(d.BUSINESS_NAME) as BUSE_DIR
		,a.STOCK_TYPE as SECU_TYPE_SUB_ID
		,@v_date  as OCCUR_DT
		,sum(abs(a.BUSINESS_AMOUNT)) as TRD_QTY
		,sum(abs(a.BUSINESS_BALANCE)) as TRD_AMT
		,count(1) as TRD_CNT
		,@v_date as LOAD_DT
	FROM DBA.T_EDW_UF2_HIS_DELIVER a
	LEFT JOIN DBA.T_DIM_ORG b ON convert(varchar,a.BRANCH_NO)=b.branch_no
	LEFT JOIN DBA.T_ODS_UF2_SCLXDZ c on a.EXCHANGE_TYPE=c.EXCHANGE_TYPE and a.STOCK_TYPE=c.STOCK_TYPE
	LEFT JOIN DBA.T_ODS_UF2_BUSINFLAG d ON a.BUSINESS_FLAG=d.BUSINESS_FLAG
	WHERE a.LOAD_DT=@v_date
	and a.BUSINESS_FLAG in (4001,4002,4103,4104)
	GROUP BY a.CLIENT_ID, b.pk_org, c.MKT_TYPE, c.SEC_TYPE, a.STOCK_TYPE, a.BUSINESS_FLAG;
  
   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_ITC_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.p_evt_odi_incm_d_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能: 客户普通业务收入日表
  编写者: rengz
  创建日期: 2018-4-20
  简介：客户普通业务收入，日更新

  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明

  *********************************************************************/
 
    --declare @v_bin_date     numeric(8);  
    
	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date;
	
  
	--生成衍生变量
    

    --删除计算期数据
    delete from dm.t_evt_odi_incm_d_d where occur_dt=@v_bin_date;
    commit;
      

------------------------
  -- 生成每日客户清单
------------------------  
    insert into dm.t_evt_odi_incm_d_d(CUST_ID,OCCUR_DT, MAIN_CPTL_ACCT,LOAD_DT)
    select distinct client_id, a.load_dt as occur_dt, fund_account,a.load_dt as rq
      from dba.t_edw_uf2_fundaccount a
     where load_dt = @v_bin_date
       and fundacct_status = '0'
       and main_flag='1'
       and asset_prop='0';
    commit;

------------------------
  -- 佣金及净佣金
------------------------  
    --drop table #t_yj;
    select a.zjzh,
          SUM(a.ssyj*b.turn_rmb   ) as yj_d,           -- 佣金                    
          SUM(a.jyj*b.turn_rmb    ) as jyj_d,          -- 净佣金
          SUM(case when  a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as ejyj_d,  -- 二级佣金                     
          SUM(case when  a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb  else 0 end) as ejjyj_d, -- 二级净佣金
          SUM(case when  a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1',  -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            ) or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then  a.ssyj*b.turn_rmb else 0 end) as gjyj_d, -- 股基佣金
          SUM(case when a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then   a.jyj*b.turn_rmb else 0 end) as gjjyj_d, -- 股基净佣金
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ssyj*b.turn_rmb else 0 end) as yj_hgt_d,                 --沪港通佣金 
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.jyj*b.turn_rmb  else 0 end) as jyj_hgt_d,                --沪港通净佣金 
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ssyj*b.turn_rmb else 0 end) as yj_sgt_d,                 --深港通佣金
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.jyj*b.turn_rmb  else 0 end) as jyj_sgt_d,                --深港通净佣金
          SUM(case when a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.ssyj*b.turn_rmb else 0 end) as yj_bjhg_d,         --报价回购佣金 
          SUM(case when a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.jyj*b.turn_rmb  else 0 end) as jyj_bjhg_d,        --报价回购净佣金 
          SUM(case when a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.ssyj*b.turn_rmb else 0 end) as yj_zq_d,  --债券佣金 ：参考全景图日表，包括国债（12） 企业债（13） 可转债 （14）
          SUM(case when a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.jyj*b.turn_rmb  else 0 end) as jyj_zq_d,  --债券净佣金 
 
   ----相关费用
          SUM(a.yhs*b.turn_rmb ) as yhs_d ,                                          -- 印花税
          SUM(a.ghf*b.turn_rmb ) as ghf_d ,                                          -- 过户费
          SUM(a.jsf*b.turn_rmb ) as jsf_d ,                                          -- 经手费
          SUM(a.zgf*b.turn_rmb ) as zgf_d ,                                          -- 证管费
          SUM(a.qtfy*b.turn_rmb ) as qtfy_d ,                                        -- 其他费用
          SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.ghf*b.turn_rmb else 0 end) as ejghf_d ,                                          -- 二级过户费
          SUM(case when a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then a.ghf*b.turn_rmb else 0 end) as gjghf_d ,                                           -- 股基过户费
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ghf*b.turn_rmb else 0 end) as hgtghf_d ,                                      -- 沪港通过户费
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ghf*b.turn_rmb else 0 end) as sgtghf_d                                        -- 深港通过户费
      into #t_yj
       from dba.t_ddw_f00_khzqhz_d as a
       left outer join dba.t_edw_t06_year_exchange_rate as b
         on a.load_dt between b.star_dt and b.end_dt
        and b.curr_type_cd = case  when a.zqlx = '18' and a.sclx = '05' then 'USD'
                                   when a.zqlx = '17' then  'USD'
                                   when a.zqlx = '18' then 'HKD'
                                        else  'CNY'
                             end
      where a.load_dt = @v_bin_date
        and a.sclx in ('01', '02', '03', '04', '05', '0G', '0S')  
      group by a.zjzh;

    commit;

     update dm.t_evt_odi_incm_d_d a
       set GROSS_CMS            = coalesce(yj_d, 0),       --毛佣金
           NET_CMS              = coalesce(jyj_d, 0),       --净佣金
           STKF_CMS             = coalesce(gjyj_d, 0),      --股基佣金
           STKF_NET_CMS         = coalesce(gjjyj_d, 0),     --股基净佣金
           BOND_CMS             = coalesce(yj_zq_d, 0),     --债券佣金
           BOND_NET_CMS         = coalesce(jyj_zq_d, 0),    --债券净佣金
           REPQ_CMS             = coalesce(yj_bjhg_d, 0),   --报价回购佣金
           REPQ_NET_CMS         = coalesce(jyj_bjhg_d, 0),  --报价回购净佣金
           HGT_CMS              = coalesce(yj_hgt_d, 0),    --沪港通佣金
           HGT_NET_CMS          = coalesce(jyj_hgt_d, 0),   --沪港通净佣金
           SGT_CMS              = coalesce(yj_sgt_d, 0),    --深港通佣金
           SGT_NET_CMS          = coalesce(jyj_sgt_d, 0),   --深港通净佣金
           SCDY_CMS             = coalesce(ejyj_d, 0),      --二级佣金
           SCDY_NET_CMS         = coalesce(ejjyj_d, 0),     --二级净佣金 

           STP_TAX              = coalesce(yhs_d, 0),       -- 印花税 
           HANDLE_FEE           = coalesce(jsf_d, 0),       -- 经手费 
           SEC_RGLT_FEE         = coalesce(zgf_d, 0),       --证管费 
           OTH_FEE              = coalesce(qtfy_d, 0),      --其他费用          
           TRAN_FEE             = coalesce(ghf_d, 0),       --过户费 
           SCDY_TRAN_FEE        = coalesce(ejghf_d, 0),     --二级过户费 
           STKF_TRAN_FEE        = coalesce(gjghf_d, 0),     --股基过户费 
           SGT_TRAN_FEE         = coalesce(sgtghf_d, 0),    --深港通过户费
           HGT_TRAN_FEE         = coalesce(hgtghf_d, 0)     --沪港通过户费
      from dm.t_evt_odi_incm_d_d a
      left join            #t_yj b on a.main_cptl_acct=b.zjzh
     where a.occur_dt=@v_bin_date ;
     commit;


  -- 期权佣金及净佣金 

    select client_id,
           sum(fare0   ) as yj_qq_d,
           sum(fare0 - exchange_fare0 - exchange_fare3   ) as jyj_qq_d
      into #t_yj_qq
     from dba.T_EDW_UF2_HIS_OPTDELIVER
     where load_dt = @v_bin_date
     group by client_id;

   update dm.t_evt_odi_incm_d_d  
   set PSTK_OPTN_CMS = coalesce(yj_qq_d, 0),        --个股期权佣金 
       PSTK_OPTN_NET_CMS = coalesce(jyj_qq_d, 0)    --个股期权净佣金 
   from dm.t_evt_odi_incm_d_d a
   left join        #t_yj_qq  b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
   commit;


  -- 大宗交易佣金及净佣金
    ---drop table #t_yj_dzjy;
    select a1.fund_acct as zjzh,
        SUM(CASE WHEN  ordeR_way_cd ='53'  THEN ROUND(a1.FACT_COMM * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                       AS yj_dzjy_d,
        SUM(CASE WHEN  ordeR_way_cd ='53'  THEN ROUND((a1.FACT_COMM - a1.stock_mana_fee) * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END) AS jyj_dzjy_d,
        SUM(CASE WHEN  ordeR_way_cd ='53'  THEN ROUND(a1.trans_fee* a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                        AS ghf_dzjy_d
    into #t_yj_dzjy
    FROM    dba.T_EDW_T05_TRADE_JOUR           a1
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE a2
    ON      a1.occur_dt BETWEEN a2.star_dt AND a2.end_dt
    AND     a2.curr_type_cd = CASE
                                   WHEN a1.stock_type_cd='18' AND a1.market_type_cd = '05' THEN 'USD'
                                   WHEN a1.stock_type_cd='17' THEN 'USD'
                                   WHEN a1.stock_type_cd='18' THEN 'HKD'
                                   ELSE 'CNY'
                              END
    WHERE  a1.busi_type_cd IN ('3101','3102','3701','3703') 
       and a1.load_dt=@v_bin_date
    group by zjzh;
  
   update dm.t_evt_odi_incm_d_d  
   set  BGDL_CMS = coalesce(yj_dzjy_d, 0),         --大宗交易佣金 
        BGDL_NET_CMS = coalesce(jyj_dzjy_d, 0),    --大宗交易净佣金 
        BGDL_TRAN_FEE = coalesce(ghf_dzjy_d, 0)    --大宗交易过户费 
   from dm.t_evt_odi_incm_d_d a
   left join      #t_yj_dzjy  b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_date ;
  commit;
 

------------------------
  -- PB交易佣金
------------------------  
  select client_id,
         sum(fare0)                                                as pbyj_d,        --PB佣金
         sum( coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)) as pbjyj_d,     --PB净佣金
         sum(fare2)                                               as pbghf_d      --PB过户费   
    into #t_pbyj
    from dba.t_edw_uf2_his_deliver a
   where a.business_flag in (4001, 4002, 4103, 4104)
     and fund_account in
         (select distinct fund_account
            from dba.t_edw_uf2_fundaccount
           where client_group in (30, 38)
             and load_dt = @v_bin_date)
     and load_dt =@v_bin_date
   group by client_id;


   update dm.t_evt_odi_incm_d_d  
   set  PB_TRD_CMS  = coalesce(pbyj_d, 0) ,          --PB交易佣金 
        PB_NET_CMS  = coalesce(pbjyj_d, 0) ,         --PB_净佣金
        PB_TRAN_FEE  = coalesce(pbghf_d, 0)          --PB_过户费
   from dm.t_evt_odi_incm_d_d a
   left join      #t_pbyj     b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
  commit; 

 
  set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 


end
GO
GRANT EXECUTE ON dm.p_evt_odi_incm_d_d TO query_dev
GO
CREATE PROCEDURE dm.p_evt_odi_incm_m_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能: 客户普通业务收入月表（日更新）
  编写者: rengz
  创建日期: 2017-11-28
  简介：客户普通业务收入，日更新
        主要数据来自于：T_DDW_F00_KHMRZJZHHZ_D 日报 普通账户资金 及市值流入流出
                        tmp_ddw_khqjt_m_m     融资融券客户资金流入 流出

  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180328                 rengz              增加“PB交易佣金、保证金利差收入、保证金利差_修正”
  *********************************************************************/
 
    -- declare @v_bin_date             numeric(8); 
    declare @v_bin_year             varchar(4); 
    declare @v_bin_mth              varchar(2); 
    declare @v_bin_qtr              varchar(2); --季度
    declare @v_bin_year_start_date  numeric(8); --本年第一个交易日
    declare @v_bin_mth_start_date   numeric(8); --本月第一个交易日
    declare @v_bin_mth_end_date     numeric(8); --本月结束交易日
    declare @v_bin_qtr_end_date     numeric(8); --本季度结束交易日
    declare @v_bin_qtr_m1_start_date  numeric(8); --本季度第1个月第一个交易日
    declare @v_bin_qtr_m1_end_date    numeric(8); --本季度第1个月最后一个交易日
    declare @v_bin_qtr_m2_start_date  numeric(8); --本季度第2个月第一个交易日
    declare @v_bin_qtr_m2_end_date    numeric(8); --本季度第2个月最后一个交易日
    declare @v_bin_qtr_m3_start_date  numeric(8); --本季度第3个月第一个交易日
    declare @v_bin_qtr_m3_end_date    numeric(8); --本季度第3个月最后一个交易日
    declare @v_date_num               numeric(8); --本月自然日的天数
    declare @v_date_qtr_m1_num        numeric(8); --本月自然日的天数
    declare @v_date_qtr_m2_num        numeric(8); --本月自然日的天数
    declare @v_date_qtr_m3_num        numeric(8); --本月自然日的天数
    declare @v_lcbl                   numeric(38,8); ---保证金利差比例
    
	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date;
	
  
	--生成衍生变量
    set @v_bin_year=(select year from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_mth =(select mth  from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_qtr =(select qtr  from dm.t_pub_date where dt=@v_bin_date );
    set @v_bin_year_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and if_trd_day_flag=1 ); 
    set @v_bin_mth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_mth_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_qtr_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and qtr=@v_bin_qtr and if_trd_day_flag=1 ); 
    set @v_bin_qtr_m1_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1);
    set @v_bin_qtr_m1_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and mth=(select convert(varchar,min(mth)) from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_date_num              =case  when @v_bin_date=@v_bin_mth_end_date then (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth )
                                        else (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and dt<=@v_bin_date) end;        --当月最后一个交易日，按照自然日统计天数
    set @v_date_qtr_m1_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date );             --本季度第1个月自然日的天数
    set @v_date_qtr_m2_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date );             --本季度第2个月自然日的天数
    set @v_date_qtr_m3_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m3_start_date and @v_bin_qtr_m3_end_date );             --本季度第3个月自然日的天数
    set @v_lcbl              =case when coalesce((select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth),0)=0 then 
                                        (select bjzlclv from dba.t_jxfc_market where nian||yue=substr(convert(varchar,dateadd(month,-1,convert(varchar,@v_bin_date)),112),1,6)  )
                              else (select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth) end ;

 

    --删除计算期数据
    delete from dm.t_evt_odi_incm_m_d where year =@v_bin_year and mth=@v_bin_mth;
    commit;
      

------------------------
  -- 生成每日客户清单
------------------------  
    insert into dm.t_evt_odi_incm_m_d(CUST_ID,OCCUR_DT,YEAR,MTH,MAIN_CPTL_ACCT,LOAD_DT)
    select distinct client_id, a.load_dt as occur_dt,@v_bin_year,@v_bin_mth, fund_account,a.load_dt as rq
      from dba.t_edw_uf2_fundaccount a
     where load_dt = @v_bin_date
       and fundacct_status = '0'
       and main_flag='1'
       and asset_prop='0';
    commit;

------------------------
  -- 佣金及净佣金
------------------------  
    --drop table #t_yj;
    select a.zjzh,
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then  a.ssyj*b.turn_rmb  end ) as yj_m,           -- 佣金_月累计                    
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then  a.jyj*b.turn_rmb   end ) as jyj_m,          -- 净佣金_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as ejyj_m,  -- 二级佣金_月累计                     
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb  else 0 end) as ejjyj_m, -- 二级净佣金_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1',  -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            ) or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then  a.ssyj*b.turn_rmb else 0 end) as gjyj_m, -- 股基佣金_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then   a.jyj*b.turn_rmb else 0 end) as gjjyj_m, -- 股基净佣金_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ssyj*b.turn_rmb else 0 end) as yj_hgt_m,                 --沪港通佣金_月累计 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.jyj*b.turn_rmb  else 0 end) as jyj_hgt_m,                --沪港通净佣金_月累计 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ssyj*b.turn_rmb else 0 end) as yj_sgt_m,                 --深港通佣金_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.jyj*b.turn_rmb  else 0 end) as jyj_sgt_m,                --深港通净佣金_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.ssyj*b.turn_rmb else 0 end) as yj_bjhg_m,         --报价回购佣金_月累计 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.jyj*b.turn_rmb  else 0 end) as jyj_bjhg_m,        --报价回购净佣金_月累计 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.ssyj*b.turn_rmb else 0 end) as yj_zq_m,  --债券佣金_月累计 ：参考全景图日表，包括国债（12） 企业债（13） 可转债 （14）
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.jyj*b.turn_rmb  else 0 end) as jyj_zq_m,  --债券净佣金_月累计 


          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date then  a.ssyj*b.turn_rmb  end ) as yj_y,           -- 佣金_年累计                    
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date then  a.jyj*b.turn_rmb   end ) as jyj_y,          -- 净佣金_年累计
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as ejyj_y,  -- 二级佣金_年累计                     
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb  else 0 end) as ejjyj_y, -- 二级净佣金_年累计
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1',  -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            ) or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then  a.ssyj*b.turn_rmb else 0 end) as gjyj_y, -- 股基佣金_年累计
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then   a.jyj*b.turn_rmb else 0 end) as gjjyj_y, -- 股基净佣金_年累计
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ssyj*b.turn_rmb else 0 end) as yj_hgt_y,                 --沪港通佣金_年累计 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.jyj*b.turn_rmb  else 0 end) as jyj_hgt_y,                --沪港通净佣金_年累计 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ssyj*b.turn_rmb else 0 end) as yj_sgt_y,                 --深港通佣金_年累计
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.jyj*b.turn_rmb  else 0 end) as jyj_sgt_y,                --深港通净佣金_年累计
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.ssyj*b.turn_rmb else 0 end) as yj_bjhg_y,         --报价回购佣金_年累计 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.jyj*b.turn_rmb  else 0 end) as jyj_bjhg_y,        --报价回购净佣金_年累计 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.ssyj*b.turn_rmb else 0 end) as yj_zq_y,  --债券佣金_年累计 ：参考全景图日表，包括国债（12） 企业债（13） 可转债 （14）
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.jyj*b.turn_rmb  else 0 end) as jyj_zq_y, --债券净佣金_年累计 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3703') then a.jyj*b.turn_rmb else 0 end) as nhgjyj_y ,                                          -- 逆回购净佣金_年累计

   ----相关费用
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.yhs*b.turn_rmb else 0 end) as yhs_m ,                                          -- 印花税_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.ghf*b.turn_rmb else 0 end) as ghf_m ,                                          -- 过户费_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.jsf*b.turn_rmb else 0 end) as jsf_m ,                                          -- 经手费_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.zgf*b.turn_rmb else 0 end) as zgf_m ,                                          -- 证管费_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.qtfy*b.turn_rmb else 0 end) as qtfy_m ,                                        -- 其他费用_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.ghf*b.turn_rmb else 0 end) as ejghf_m ,                                          -- 二级过户费_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A股
                                                            '17', '18', -- B股
                                                            '11',       -- 封闭式基金
                                                            '1A',       -- ETF
                                                            '74', '75' -- 权证
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then a.ghf*b.turn_rmb else 0 end) as gjghf_m ,                                           -- 股基过户费_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ghf*b.turn_rmb else 0 end) as hgtghf_m ,                                      -- 沪港通过户费_月累计
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ghf*b.turn_rmb else 0 end) as sgtghf_m                                        -- 深港通过户费_月累计
      into #t_yj
       from dba.t_ddw_f00_khzqhz_d as a
       left outer join dba.t_edw_t06_year_exchange_rate as b
         on a.load_dt between b.star_dt and b.end_dt
        and b.curr_type_cd = case  when a.zqlx = '18' and a.sclx = '05' then 'USD'
                                   when a.zqlx = '17' then  'USD'
                                   when a.zqlx = '18' then 'HKD'
                                        else  'CNY'
                             end
      where a.load_dt between @v_bin_year_start_date and @v_bin_date
        and a.sclx in ('01', '02', '03', '04', '05', '0G', '0S')  
      group by a.zjzh;

    commit;

     update dm.t_evt_odi_incm_m_d a
       set GROSS_CMS            = coalesce(yj_m, 0),       --毛佣金
           NET_CMS              = coalesce(jyj_m, 0),       --净佣金
           STKF_CMS             = coalesce(gjyj_m, 0),      --股基佣金
           STKF_NET_CMS         = coalesce(gjjyj_m, 0),     --股基净佣金
           BOND_CMS             = coalesce(yj_zq_m, 0),     --债券佣金
           BOND_NET_CMS         = coalesce(jyj_zq_m, 0),    --债券净佣金
           REPQ_CMS             = coalesce(yj_bjhg_m, 0),   --报价回购佣金
           REPQ_NET_CMS         = coalesce(jyj_bjhg_m, 0),  --报价回购净佣金
           HGT_CMS              = coalesce(yj_hgt_m, 0),    --沪港通佣金
           HGT_NET_CMS          = coalesce(jyj_hgt_m, 0),   --沪港通净佣金
           SGT_CMS              = coalesce(yj_sgt_m, 0),    --深港通佣金
           SGT_NET_CMS          = coalesce(jyj_sgt_m, 0),   --深港通净佣金
           SCDY_CMS             = coalesce(ejyj_m, 0),      --二级佣金
           SCDY_NET_CMS         = coalesce(ejjyj_m, 0),     --二级净佣金
           TY_SCDY_CMS          = coalesce(ejyj_y, 0),      --今年二级佣金
           TY_SCDY_NET_CMS      = coalesce(ejjyj_y, 0),     --今年二级净佣金
           TY_ODI_NET_CMS       = coalesce(jyj_y, 0),       --今年普通净佣金
           TY_STKF_CMS          = coalesce(gjyj_y, 0),      --今年股基佣金
           TY_STKF_NET_CMS      = coalesce(gjjyj_y, 0),     --今年股基净佣金
           TY_ODI_CMS           = coalesce(yj_y, 0),        --今年普通佣金
           TY_SGT_NET_CMS       = coalesce(jyj_sgt_y, 0),   --今年深港通净佣金
           TY_HGT_NET_CMS       = coalesce(jyj_hgt_y, 0),   --今年沪港通净佣金
           TY_R_REPUR_NET_CMS   = coalesce(nhgjyj_y, 0),    --今年逆回购净佣金

           STP_TAX              = coalesce(yhs_m, 0),       -- 印花税 
           HANDLE_FEE           = coalesce(jsf_m, 0),       -- 经手费 
           SEC_RGLT_FEE         = coalesce(zgf_m, 0),       --证管费 
           OTH_FEE              = coalesce(qtfy_m, 0),      --其他费用          
           TRAN_FEE             = coalesce(ghf_m, 0),       --过户费 
           SCDY_TRAN_FEE        = coalesce(ejghf_m, 0),     --二级过户费 
           STKF_TRAN_FEE        = coalesce(gjghf_m, 0),     --股基过户费 
           SGT_TRAN_FEE         = coalesce(sgtghf_m, 0),    --深港通过户费
           HGT_TRAN_FEE         = coalesce(hgtghf_m, 0)     --沪港通过户费
      from dm.t_evt_odi_incm_m_d a
      left join            #t_yj b on a.main_cptl_acct=b.zjzh
     where a.occur_dt=@v_bin_date ;
     commit;


  -- 期权佣金及净佣金 

    select client_id,
           sum(case when load_dt between @v_bin_mth_start_date and @v_bin_date then fare0 end ) as yj_qq_m,
           sum(case when load_dt between @v_bin_mth_start_date and @v_bin_date then fare0 - exchange_fare0 - exchange_fare3 end ) as jyj_qq_m,
           sum(case when load_dt between @v_bin_year_start_date and @v_bin_date then fare0 end ) as yj_qq_y,
           sum(case when load_dt between @v_bin_year_start_date and @v_bin_date then fare0 - exchange_fare0 - exchange_fare3 end ) as jyj_qq_y
      into #t_yj_qq
     from dba.T_EDW_UF2_HIS_OPTDELIVER
     where load_dt between @v_bin_year_start_date and @v_bin_date
     group by client_id;

   update dm.t_evt_odi_incm_m_d  
   set PSTK_OPTN_CMS = coalesce(yj_qq_m, 0),        --个股期权佣金_月累计
       PSTK_OPTN_NET_CMS = coalesce(jyj_qq_m, 0),   --个股期权净佣金_月累计
       TY_PSTK_OPTN_CMS = coalesce(yj_qq_y, 0)      --个股期权佣金_年累计
   from dm.t_evt_odi_incm_m_d a
   left join        #t_yj_qq  b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
   commit;


  -- 大宗交易佣金及净佣金
    ---drop table #t_yj_dzjy;
    select a1.fund_acct as zjzh,
        SUM(CASE WHEN load_dt between @v_bin_mth_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND(a1.FACT_COMM * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                       AS yj_dzjy_m,
        SUM(CASE WHEN load_dt between @v_bin_mth_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND((a1.FACT_COMM - a1.stock_mana_fee) * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END) AS jyj_dzjy_m,
        SUM(CASE WHEN load_dt between @v_bin_mth_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND(a1.trans_fee* a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                        AS ghf_dzjy_m,
        SUM(CASE WHEN load_dt between @v_bin_year_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND(a1.FACT_COMM * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                        AS yj_dzjy_y,
        SUM(CASE WHEN load_dt between @v_bin_year_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND((a1.FACT_COMM - a1.stock_mana_fee) * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)  AS jyj_dzjy_y
    into #t_yj_dzjy
    FROM    dba.T_EDW_T05_TRADE_JOUR           a1
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE a2
    ON      a1.occur_dt BETWEEN a2.star_dt AND a2.end_dt
    AND     a2.curr_type_cd = CASE
                                   WHEN a1.stock_type_cd='18' AND a1.market_type_cd = '05' THEN 'USD'
                                   WHEN a1.stock_type_cd='17' THEN 'USD'
                                   WHEN a1.stock_type_cd='18' THEN 'HKD'
                                   ELSE 'CNY'
                              END
    WHERE  a1.busi_type_cd IN ('3101','3102','3701','3703') 
       and a1.load_dt between @v_bin_year_start_date and @v_bin_date
    group by zjzh;
  
   update dm.t_evt_odi_incm_m_d  
   set  BGDL_CMS = coalesce(yj_dzjy_m, 0),         --大宗交易佣金_月累计
        BGDL_NET_CMS = coalesce(jyj_dzjy_m, 0),    --大宗交易净佣金_月累计
        BGDL_TRAN_FEE = coalesce(ghf_dzjy_m, 0)    --大宗交易过户费_月累计
   from dm.t_evt_odi_incm_m_d a
   left join      #t_yj_dzjy  b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_date ;
  commit;
 

------------------------
  -- PB交易佣金
------------------------  
  select client_id, sum(fare0) as pbyj_m
    into #t_pbyj
    from dba.t_edw_uf2_his_deliver a
   where a.business_flag in (4001, 4002, 4103, 4104)
     and fund_account in
         (select distinct fund_account
            from dba.t_edw_uf2_fundaccount
           where client_group in (30, 38)
             and load_dt between @v_bin_mth_start_date AND @v_bin_date)
     and load_dt between @v_bin_mth_start_date AND @v_bin_date
   group by client_id;


   update dm.t_evt_odi_incm_m_d  
   set  PB_TRD_CMS  = coalesce(pbyj_m, 0)         --PB交易佣金 
   from dm.t_evt_odi_incm_m_d a
   left join      #t_pbyj     b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
  commit; 

------------------------
  -- 保证金利差收入
------------------------  

--保证金
  select zjzh,
         sum(a.zjye * b.turn_rmb / turn_rate) as zjyeh,
         (zjyeh/@v_date_num)* @v_lcbl         as lcsr
  into #t_lcsr
  from dba.T_DDW_F00_KHMRZJZHHZ_D a
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE b ON a.tjrq BETWEEN b.star_dt AND b.end_dt AND b.curr_type_cd = a.bzlb   
    LEFT JOIN (select rq, nian, yue,
                      case when sfjrbz = '1' then rq else syggzr
                      end as jyr
              from dba.T_DDW_D_RQ
              where rq  between @v_bin_mth_start_date AND  @v_bin_date ) c  on c.jyr = a.tjrq
  where a.tjrq between @v_bin_mth_start_date AND  @v_bin_date
  group by zjzh;

 commit;

   update dm.t_evt_odi_incm_m_d  
   set  MARG_SPR_INCM = coalesce(lcsr, 0)         --保证金利差收入 
   from dm.t_evt_odi_incm_m_d a
   left join      #t_lcsr  b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_date ;
  commit; 


------------------------
  -- 修正本季度2两个月的保证金利差收入
------------------------  

 
  if @v_bin_date= @v_bin_qtr_end_date
  then 
 
  ---本季度第1月
   select zjzh,
         sum(a.zjye * b.turn_rmb / turn_rate) as zjyeh,
         (zjyeh/@v_date_qtr_m1_num)* @v_lcbl         as lcsr
  into #t_lcsr_qrt_1
  from dba.T_DDW_F00_KHMRZJZHHZ_D a
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE b ON a.tjrq BETWEEN b.star_dt AND b.end_dt AND b.curr_type_cd = a.bzlb   
    LEFT JOIN (select rq, nian, yue,
                      case when sfjrbz = '1' then rq else syggzr
                      end as jyr
              from dba.T_DDW_D_RQ
              where rq  between @v_bin_qtr_m1_start_date AND  @v_bin_qtr_m1_end_date ) c  on c.jyr = a.tjrq
  where a.tjrq between @v_bin_qtr_m1_start_date AND  @v_bin_qtr_m1_end_date
  group by zjzh ;

   update dm.t_evt_odi_incm_m_d  
   set  MARG_SPR_INCM_CET = coalesce(lcsr, 0)         --保证金利差收入 
   from dm.t_evt_odi_incm_m_d a
   left join  #t_lcsr_qrt_1   b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_qtr_m1_end_date ;
  commit; 


  ---本季度第2月
   select zjzh,
         sum(a.zjye * b.turn_rmb / turn_rate) as zjyeh,
         (zjyeh/@v_date_qtr_m2_num)* @v_lcbl         as lcsr
  into #t_lcsr_qrt_2
  from dba.T_DDW_F00_KHMRZJZHHZ_D a
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE b ON a.tjrq BETWEEN b.star_dt AND b.end_dt AND b.curr_type_cd = a.bzlb   
    LEFT JOIN (select rq, nian, yue,
                      case when sfjrbz = '1' then rq else syggzr
                      end as jyr
              from dba.T_DDW_D_RQ
              where rq  between @v_bin_qtr_m2_start_date AND  @v_bin_qtr_m2_end_date ) c  on c.jyr = a.tjrq
  where a.tjrq between @v_bin_qtr_m2_start_date AND  @v_bin_qtr_m2_end_date
  group by zjzh ;
  commit;
  

   update dm.t_evt_odi_incm_m_d  
   set  MARG_SPR_INCM_CET = coalesce(lcsr, 0)         --保证金利差收入 
   from dm.t_evt_odi_incm_m_d a
   left join  #t_lcsr_qrt_2   b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_qtr_m2_end_date ;
  commit; 
 
  end if;

 
   set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 


end
GO
GRANT EXECUTE ON dm.p_evt_odi_incm_m_d TO query_dev
GO
GRANT EXECUTE ON dm.p_evt_odi_incm_m_d TO xydc
GO
CREATE PROCEDURE dm.P_EVT_OUTMARK_PROD_EXT_M(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 体外市值扩展表月表
  编写者: DCY
  创建日期: 2018-01-15
  简介：
  *********************************************************************
  修订记录：   修订日期    修订人     修改内容简要说明
           
  *********************************************************************/
    DECLARE @nian VARCHAR(4);		--本月_年份
	DECLARE @yue VARCHAR(2)	;		--本月_月份
	DECLARE @zrr_nc int;            --自然日_月初
	DECLARE @zrr_yc int;            --自然日_年初 
	DECLARE @td_ym int;				--月末
	DECLARE @ny int;
	
    SET @V_OUT_FLAG = -1;  --初始清洗赋值-1

    SET @nian=SUBSTR(@V_BIN_DATE||'',1,4);
	SET @yue=SUBSTR(@V_BIN_DATE||'',5,2);
   	set @zrr_nc=(select min(t1.日期) from DBA.v_skb_d_rq t1 where t1.日期>=convert(int,@nian||'0101'));
	set @zrr_yc=(select min(t1.日期) from DBA.v_skb_d_rq t1 where t1.日期>=convert(int,@nian||@yue||'01'));
	set @td_ym=(select max(t1.日期) from DBA.v_skb_d_rq t1 where t1.是否工作日='1' and t1.日期<=convert(int,@nian||@yue||'31'));
    set @ny=convert(int,@nian||@yue);
	
	
	
  --PART0 删除要回洗的数据
    DELETE FROM DM.T_EVT_OUTMARK_PROD_EXT_M WHERE YEAR=@nian AND MTH=@yue;
	
 --PART1 员工号剔重_临时表	
   select
		t1.ygh --afa一期员工号
		,T1.afatwo_ygh --afa二期员工号，如果员工号不存在，则以客户所在营业部编号作为二期员工号，算营业部公共客户。

		INTO #temp_ygh_tc
	from
	(
		select
			t1.ygh
			,case when t2.ygs=1 then t1.afatwo_ygh
				when t2.ygs>1 and t3.afatwo_ygh is not null then t3.afatwo_ygh
				else t4.afatwo_ygh end as afatwo_ygh
		from
		(
			select
				t1.ygh
				,t1.afatwo_ygh
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
		) t1	
		left join
		(--同一经纪人编号对应二期员工号数
			select
				t1.ygh
				,count(t1.afatwo_ygh) as ygs
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
			group by
				t1.ygh
		) t2 on t1.ygh=t2.ygh	
		left join
		(--同一经纪人编号对应正常员工号
			select
				t1.ygh
				,max(t1.afatwo_ygh) as afatwo_ygh
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
				and t1.ygzt='正常人员'
			group by
				t1.ygh
		) t3 on t1.ygh=t3.ygh
		left join
		(--同一经纪人编号对应异常员工号
			select
				t1.ygh
				,max(t1.afatwo_ygh) as afatwo_ygh
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
				and t1.ygzt<>'正常人员'
			group by
				t1.ygh
		) t4 on t1.ygh=t4.ygh
		group by
			t1.ygh
			,afatwo_ygh
	) t1
	where t1.afatwo_ygh is not null
	;
	COMMIT;
 
  --PART2 体外客户对照_临时表:特殊账户
  select
		t1.uid		--唯一识别号规则：（私募）机构编号_客户姓名；定向使用资金帐号
		,t1.sfdx	--是否定向客户	
		,case when t2.zjzh is null then convert(int,t1.gmrq) else t2.khrq end as khrq  --开户日期
		,case when khrq>=@zrr_nc then 1 else 0 end as sfxz_y  --是否月新增
		,case when khrq>=@zrr_yc then 1 else 0 end as sfxz_m  --是否年新增
		,t1.gmrq    --首次购买日期
		,t2.khzt    --客户状态
		
		INTO #temp_twkhdz   --特殊账户
	from
	(
		select
			case when t1.cplx='定向' or t1.cplx='定向-固定收益' then t1.zjzh
				else t1.jgbh||trim(t1.khmc)
				end as uid			
			,case when t1.cplx='定向' or t1.cplx='定向-固定收益' then 1 else 0 end as sfdx
			,min(t1.nian||t1.yue||'01') as gmrq
		from dba.gt_ods_simu_trade_jour t1
		group by uid,sfdx
	) t1
	left join dba.t_ddw_yunying2012_kh t2 on t1.uid=t2.zjzh and t2.nian=@nian and t2.yue=@yue	
  ;
  COMMIT;
  
   --PART3 体外产品扩展客户明细_临时表
 select
		@nian as nian
		,@yue as yue		
		,t1.uid		
		,t4.khrq
		,t4.sfxz_y
		,t4.sfxz_m
		,case when t1.cplx='定向' then '定向-权益类' else trim(t1.cplx) end as cplx
		,t1.cpmc
		,case when t1.zjzh is null or trim(t1.zjzh)='' then '无资金帐号' else t1.zjzh end as zjzh
		,t1.jgbh
--		,t1.jgmc
		,t1.afatwo_ygh
		,t1.xsje_m
		,t1.shje_m
		,t1.xsje_y
		,t1.shje_y
		,case when t1.zjzh is null or trim(t1.zjzh)='' or coalesce(t2.cpqmfe,0)<>0 then t1.qmfe else 0 end as qmfe
		,t1.qmfe_ys as qmfe_ys
		,coalesce(t2.cpqmfe_ys,0) as cpqmfe_ys
		,coalesce(t2.cpqmfe,0) as cpqmfe
		,case when t1.cplx in ('权益类私募信托','定向-权益类') and coalesce(t2.cpqmfe,0)>0 then t1.qmfe/coalesce(t2.cpqmfe,0) else 0 end as bybl
		,case when t1.cplx in ('固定收益','PE产品','定向-固定收益') then t1.qmbyje_gd 
			when t1.cplx='权益类私募信托' and (trim(t1.zjzh)='' or t1.zjzh is null) then t1.qmfe*coalesce(t3.jz,1)
			when t1.cplx in ('权益类私募信托','定向-权益类') and (t1.zjzh is not null and trim(t1.zjzh)<>'') then coalesce(t2.qmzc,0)*bybl
			else t1.qmfe end as qmbyje
		,case when t1.cplx in ('固定收益','PE产品','定向-固定收益') then t1.qmbyje_gd 
			when t1.cplx='权益类私募信托' and (trim(t1.zjzh)='' or t1.zjzh is null) then t1.qmfe*coalesce(t3.jz,1)
			when t1.cplx in ('权益类私募信托','定向-权益类') and (t1.zjzh is not null and trim(t1.zjzh)<>'') then coalesce(t2.rjzc_m,0)*bybl
			else t1.qmfe end as byje_yrj
		,case when t1.cplx in ('固定收益','PE产品','定向-固定收益') then t1.qmbyje_gd 
			when t1.cplx='权益类私募信托' and (trim(t1.zjzh)='' or t1.zjzh is null) then t1.qmfe*coalesce(t3.jz,1)
			when t1.cplx in ('权益类私募信托','定向-权益类') and (t1.zjzh is not null and trim(t1.zjzh)<>'') then coalesce(t2.rjzc_y,0)*bybl
			else t1.qmfe end as byje_nrj
			
	into #temp_twcp_khmx
	from 
	(--员工体外产品汇总数
		select
			t1.uid
			,t1.cpmc
			,t1.cplx
			,t1.zjzh
			,t1.jgbh
			,t1.afatwo_ygh
			,sum(t1.xsje_m) as xsje_m
			,sum(t1.shje_m) as shje_m
			,sum(t1.xsje_y) as xsje_y
			,sum(t1.shje_y) as shje_y
			,sum(t1.qmfe_ys) as qmfe_ys
			,case when qmfe_ys<0 then 0 else qmfe_ys end as qmfe			
			,sum(t1.qmbyje_gd) as qmbyje_gd	
		from
		(
			select
				case when t1.cplx='定向' or t1.cplx='定向-固定收益' then t1.zjzh
					else t1.jgbh||trim(t1.khmc)
					end as uid		
				,t1.cpmc
				,case when t1.cplx='定向' then '定向-权益类' else trim(t1.cplx) end as cplx
				,t1.zjzh
				,case when t1.cplx = '定向' then t2.jgbh 
					else t1.jgbh end as jgbh
				,case when t1.cplx = '定向' then t2.jgbh 
					when t1.cplx<>'定向' and t_yg.afatwo_ygh is null then t1.jgbh else t_yg.afatwo_ygh end as afatwo_ygh
				,sum(case when t1.nian=@nian and t1.yue=@yue and t1.ywlx in ('认购','申购','追加') then t1.je else 0 end) as xsje_m 
				,sum(case when t1.nian=@nian and t1.yue=@yue and t1.ywlx in ('赎回','部分赎回','全部赎回') then t1.je else 0 end) as shje_m
				,sum(case when t1.nian=@nian and t1.yue<=@yue and t1.ywlx in ('认购','申购','追加') then t1.je else 0 end) as xsje_y
				,sum(case when t1.nian=@nian and t1.yue<=@yue and t1.ywlx in ('赎回','部分赎回','全部赎回') then t1.je else 0 end) as shje_y
				,sum(case when t1.cplx='权益类私募信托' and t1.ywlx in ('赎回','部分赎回','全部赎回') then -t1.fe
						when t1.cplx='权益类私募信托' and t1.ywlx in ('认购','申购','追加','保有') then t1.fe
						when t1.cplx='定向' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('赎回','部分赎回','全部赎回') then -t1.je		--定向产品仅查询有效期内
						when t1.cplx='定向' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('认购','申购','追加','保有') then t1.je		--定向产品仅查询有效期内		
						else 0 end) as qmfe_ys
	--			,case when qmfe_ys>0 then qmfe_ys else 0 end as qmfe --消除期末份额负数		
				,sum(case when t1.cplx in ('固定收益','PE产品','定向-固定收益') and t1.ywlx in ('认购','申购','追加') 
	--				and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_yc then t1.je else 0 end) as qmbyje_gd	--固定收益类保有金额按有效期内的销售计算		
					and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym then t1.je else 0 end) as qmbyje_gd	--固定收益类保有金额按有效期内的销售计算	
			from dba.gt_ods_simu_trade_jour t1			
			left join #temp_ygh_tc t_yg on t1.tgbh=t_yg.ygh
			left join 
			(
				SELECT
					zjzh,
					cplx,
					jgbh
				FROM dba.gt_ods_simu_trade_jour t0
				WHERE ny = (
					SELECT max(ny)
						FROM dba.gt_ods_simu_trade_jour
						WHERE zjzh = t0.zjzh AND cplx = t0.cplx)
					AND cplx = '定向'
					GROUP BY zjzh, cplx, jgbh
			) t2 on t1.zjzh = t2.zjzh and t1.cplx = t2.cplx
			where t1.ny<=@ny
			group by 
				uid
				,t1.cpmc
				,cplx
				,t1.zjzh
				,jgbh
				,afatwo_ygh
		) t1
		group by
			t1.uid
			,t1.cpmc
			,t1.cplx
			,t1.zjzh
			,t1.jgbh
			,t1.afatwo_ygh
	) t1
	left join
	(--产品整体情况（私募或定向）
		select
			t1.zjzh
			,t1.cpqmfe
			,t1.cpqmfe_ys
			,t2.qmzc
			,t2.rjzc_m
			,t2.rjzc_y
		from
		(
			select
				t1.zjzh
				,sum(case when t1.cplx='权益类私募信托' and t1.ywlx in ('赎回','部分赎回','全部赎回') then -fe
					  when t1.cplx='权益类私募信托' and t1.ywlx in ('认购','申购','追加','保有') then fe
					  when t1.cplx='定向' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('认购','申购','追加','保有') then je
					  when t1.cplx='定向' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('赎回','部分赎回','全部赎回') then -je				  
					  else 0 end) as cpqmfe_ys
				,case when cpqmfe_ys>1 then cpqmfe_ys else 0 end as cpqmfe	--产品期末份额小于1的按0算，避免保有比例异常
			from dba.gt_ods_simu_trade_jour t1
			where t1.ny<=@ny 
--				and t1.yxq_end>=@td_ym
				and	t1.cplx in ('权益类私募信托','定向')
				and t1.zjzh is not null
			group by t1.zjzh
		) t1
		left join
		(
			select
				t1.zjzh		
				,coalesce(t1.期末资产,0)+coalesce(t2.rzrq_qmzc,0) as qmzc
				,coalesce(t1.日均资产,0)+coalesce(t2.rzrq_rjzc_m,0) as rjzc_m
				,coalesce(t3.日均资产,0)+coalesce(t2.rzrq_rjzc_y,0) as rjzc_y
			from 
			(
				select
					t1.资金账户 as zjzh
					,t1.期末资产
					,t1.日均资产
				from DBA.客户综合分析_月 t1
				where t1.年份=@nian and t1.月份=@yue
			) t1
			left join
			(
				select
					t1.zjzh
					,t1.rzrq_qmzc
					,t1.rzrq_rjzc_m
					,t1.rzrq_rjzc_y
				from dba.T_DDW_XYZQ_F00_KHZHFX_2011 t1
				where t1.nian=@nian and t1.yue=@yue
			) t2 on t1.zjzh=t2.zjzh
			left join
			(
				select
					t1.资金账户 as zjzh
					,t1.日均资产
				from DBA.客户综合分析_年 t1
				where t1.年份=@nian and t1.月份=@yue
							and 账户状态 = '正常'
			) t3 on t1.zjzh=t3.zjzh
		) t2 on t1.zjzh=t2.zjzh
	) t2 on t1.zjzh=t2.zjzh
	left join
	(--产品净值
		select
			t1.zjzh
			,max(t1.jz) as jz
		from dba.gt_ods_simu_trade_jour t1
		where t1.nian=@nian and t1.yue=@yue
			and t1.cplx in ('权益类私募信托','定向')
			and t1.zjzh is not null
		group by t1.zjzh
	) t3 on t1.zjzh=t3.zjzh
	left join #temp_twkhdz t4 on t1.uid=t4.uid
 ;
 commit;
 
 
    --PART4 1100_体外产品扩展表更新_临时表
	insert into DM.T_EVT_OUTMARK_PROD_EXT_M
	(
	 YEAR             --年  
	,MTH              --月
	,CUST_ID          --客户编码
	,OACT_DT          --开户日期
	,IF_MTH_NA        --是否月新增  
	,IF_YEAR_NA       --是否年新增  
	,CPTL_ACCT        --资金账号  
	,AFA_SEC_EMPID    --AFA_二期员工号 
	,ORG_ID           --机构编码
	,PROD_NAME        --产品名称
	,PROD_CD          --产品代码  
	,PROD_TYPE        --产品类型  
	,SALE_MTD         --销售_月累计  
	,REDP_MTD         --赎回_月累计  
	,SALE_YTD         --销售_年累计  
	,REDP_YTD         --赎回_年累计  
	,RETAIN_FINAL     --保有_期末  
	,RETAIN_MDA       --保有_月日均  
	,RETAIN_YDA       --保有_年日均  
	,LOAD_DT          --清洗日期
	)
(
	select
		t1.nian	
		,t1.yue
		,t1.uid as khbh
		,t1.khrq
		,t1.sfxz_m
		,t1.sfxz_y
		,t1.zjzh
		,t1.afatwo_ygh
		,t1.jgbh
		,t1.cpmc
		,t1.cpmc as cpdm
		,t1.cplx
		,t1.xsje_m as xs_ylj
		,t1.shje_m as sh_ylj
		,t1.xsje_y as xs_nlj
		,t1.shje_y as sh_nlj
		,t1.qmbyje as by_qm
		,t1.byje_yrj as by_yrj
		,t1.byje_nrj as by_nrj		
		,@V_BIN_DATE  AS LOAD_DT  --清洗日期
	from #temp_twcp_khmx t1	
	where t1.cplx not in ('定向-权益类','定向-固定收益')
	union all
	select
		t1.nian	
		,t1.yue
		,t1.uid as khbh
		,t1.khrq
		,t1.sfxz_m
		,t1.sfxz_y
		,t1.zjzh
		,case when t_gx.afatwo_ygh is null then t1.jgbh else t_gx.afatwo_ygh end as afatwo_ygh
		,case when t_gx.jgbh_yg is null then t1.jgbh else t_gx.jgbh_yg end as jgbh
		,t1.cpmc
		,t1.cpmc as cpdm
		,t1.cplx
		,sum(t1.xsje_m*isnull(t_gx.jxbl6, 1)) as xs_ylj
		,sum(t1.shje_m*isnull(t_gx.jxbl6, 1)) as sh_ylj
		,sum(t1.xsje_y*isnull(t_gx.jxbl6, 1)) as xs_nlj
		,sum(t1.shje_y*isnull(t_gx.jxbl6, 1)) as sh_nlj
		,sum(t1.qmbyje*isnull(t_gx.jxbl6, 1)) as by_qm
		,sum(t1.byje_yrj*isnull(t_gx.jxbl6, 1)) as by_yrj
		,sum(t1.byje_nrj*isnull(t_gx.jxbl6, 1)) as by_nrj	
        ,@V_BIN_DATE  AS LOAD_DT  --清洗日期		
	from #temp_twcp_khmx t1	
	left join dba.t_ddw_serv_relation t_gx on t1.zjzh=t_gx.zjzh and t_gx.nian=@nian and t_gx.yue=@yue	
	where t1.cplx in ('定向-权益类','定向-固定收益')
	group by t1.nian	
		,t1.yue
		,t1.uid
		,t1.khrq
		,t1.sfxz_m
		,t1.sfxz_y
		,t1.zjzh
		,afatwo_ygh
		,jgbh
		,t1.cpmc
		,t1.cplx
);
commit;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_OUTMARK_PROD_EXT_M TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部产品交易事实表（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-09
  简介：营业部产品事实表（日表）
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_PROD_TRD_D_BRH WHERE OCCUR_DT = @V_DATE;

  	-- 员工-营业部关系
	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--员工编码
		,A.PK_ORG 		AS 		BRH_ID			--营业部编码
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  		AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	CREATE TABLE #TMP_T_EVT_PROD_TRD_D_BRH(
	    OCCUR_DT             	numeric(8,0) 		NOT NULL,
		BRH_ID               	varchar(30) 		NOT NULL,
		EMP_ID		 			varchar(30) 		NOT NULL,
		PROD_CD              	varchar(30) 		NOT NULL,
		PROD_TYPE            	varchar(30) 		NOT NULL,
		ITC_RETAIN_AMT       	numeric(38,8) 		NULL,
		OTC_RETAIN_AMT       	numeric(38,8) 		NULL,
		ITC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		OTC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		ITC_SUBS_AMT         	numeric(38,8) 		NULL,
		ITC_PURS_AMT         	numeric(38,8) 		NULL,
		ITC_BUYIN_AMT        	numeric(38,8) 		NULL,
		ITC_REDP_AMT         	numeric(38,8) 		NULL,
		ITC_SELL_AMT         	numeric(38,8) 		NULL,
		OTC_SUBS_AMT         	numeric(38,8) 		NULL,
		OTC_PURS_AMT         	numeric(38,8) 		NULL,
		OTC_CASTSL_AMT       	numeric(38,8) 		NULL,
		OTC_COVT_IN_AMT      	numeric(38,8) 		NULL,
		OTC_REDP_AMT         	numeric(38,8) 		NULL,
		OTC_COVT_OUT_AMT     	numeric(38,8) 		NULL,
		ITC_SUBS_SHAR        	numeric(38,8) 		NULL,
		ITC_PURS_SHAR        	numeric(38,8) 		NULL,
		ITC_BUYIN_SHAR       	numeric(38,8) 		NULL,
		ITC_REDP_SHAR        	numeric(38,8) 		NULL,
		ITC_SELL_SHAR        	numeric(38,8) 		NULL,
		OTC_SUBS_SHAR        	numeric(38,8) 		NULL,
		OTC_PURS_SHAR        	numeric(38,8) 		NULL,
		OTC_CASTSL_SHAR      	numeric(38,8) 		NULL,
		OTC_COVT_IN_SHAR     	numeric(38,8) 		NULL,
		OTC_REDP_SHAR        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_SHAR    	numeric(38,8) 		NULL,
		ITC_SUBS_CHAG        	numeric(38,8) 		NULL,
		ITC_PURS_CHAG        	numeric(38,8) 		NULL,
		ITC_BUYIN_CHAG       	numeric(38,8) 		NULL,
		ITC_REDP_CHAG        	numeric(38,8) 		NULL,
		ITC_SELL_CHAG        	numeric(38,8) 		NULL,
		OTC_SUBS_CHAG        	numeric(38,8) 		NULL,
		OTC_PURS_CHAG        	numeric(38,8) 		NULL,
		OTC_CASTSL_CHAG      	numeric(38,8) 		NULL,
		OTC_COVT_IN_CHAG     	numeric(38,8) 		NULL,
		OTC_REDP_CHAG        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_CHAG    	numeric(38,8) 		NULL,
		CONTD_SALE_SHAR      	numeric(38,8) 		NULL,
		CONTD_SALE_AMT       	numeric(38,8) 		NULL
	);

	INSERT INTO #TMP_T_EVT_PROD_TRD_D_BRH(
		  OCCUR_DT          		--发生日期
		 ,BRH_ID					--营业部编码
		 ,EMP_ID            		--员工编码			
		 ,PROD_CD           		--产品代码			
		 ,PROD_TYPE         		--产品类型			
		 ,ITC_RETAIN_AMT    		--场内保有金额			
		 ,OTC_RETAIN_AMT    		--场外保有金额			
		 ,ITC_RETAIN_SHAR   		--场内保有份额			
		 ,OTC_RETAIN_SHAR   		--场外保有份额			
		 ,ITC_SUBS_AMT      		--场内认购金额			
		 ,ITC_PURS_AMT      		--场内申购金额			
		 ,ITC_BUYIN_AMT     		--场内买入金额			
		 ,ITC_REDP_AMT      		--场内赎回金额			
		 ,ITC_SELL_AMT      		--场内卖出金额			
		 ,OTC_SUBS_AMT      		--场外认购金额			
		 ,OTC_PURS_AMT      		--场外申购金额			
		 ,OTC_CASTSL_AMT    		--场外定投金额			
		 ,OTC_COVT_IN_AMT   		--场外转换入金额			
		 ,OTC_REDP_AMT      		--场外赎回金额			
		 ,OTC_COVT_OUT_AMT  		--场外转换出金额			
		 ,ITC_SUBS_SHAR     		--场内认购份额			
		 ,ITC_PURS_SHAR     		--场内申购份额			
		 ,ITC_BUYIN_SHAR    		--场内买入份额			
		 ,ITC_REDP_SHAR     		--场内赎回份额			
		 ,ITC_SELL_SHAR     		--场内卖出份额			
		 ,OTC_SUBS_SHAR     		--场外认购份额			
		 ,OTC_PURS_SHAR     		--场外申购份额			
		 ,OTC_CASTSL_SHAR   		--场外定投份额			
		 ,OTC_COVT_IN_SHAR  		--场外转换入份额			
		 ,OTC_REDP_SHAR     		--场外赎回份额			
		 ,OTC_COVT_OUT_SHAR 		--场外转换出份额			
		 ,ITC_SUBS_CHAG     		--场内认购手续费			
		 ,ITC_PURS_CHAG     		--场内申购手续费			
		 ,ITC_BUYIN_CHAG    		--场内买入手续费			
		 ,ITC_REDP_CHAG     		--场内赎回手续费			
		 ,ITC_SELL_CHAG     		--场内卖出手续费			
		 ,OTC_SUBS_CHAG     		--场外认购手续费			
		 ,OTC_PURS_CHAG     		--场外申购手续费			
		 ,OTC_CASTSL_CHAG   		--场外定投手续费			
		 ,OTC_COVT_IN_CHAG  		--场外转换入手续费			
		 ,OTC_REDP_CHAG     		--场外赎回手续费			
		 ,OTC_COVT_OUT_CHAG 		--场外转换出手续费			
		 ,CONTD_SALE_SHAR   		--续作销售份额			
		 ,CONTD_SALE_AMT    		--续作销售金额			
	)
	SELECT 
		  T.OCCUR_DT						AS			OCCUR_DT          		--发生日期
		 ,T1.BRH_ID							AS 			BRH_ID					--营业部编码
		 ,T.EMP_ID	  						AS 			EMP_ID					--员工编码
		 ,T.PROD_CD 						AS  		PROD_CD 				--产品代码				
		 ,T.PROD_TYPE 						AS  		PROD_TYPE 				--产品类型
		 ,T.ITC_RETAIN_AMT    				AS 			ITC_RETAIN_AMT    		--场内保有金额		
		 ,T.OTC_RETAIN_AMT    				AS 			OTC_RETAIN_AMT    		--场外保有金额		
		 ,T.ITC_RETAIN_SHAR   				AS 			ITC_RETAIN_SHAR   		--场内保有份额		
		 ,T.OTC_RETAIN_SHAR   				AS 			OTC_RETAIN_SHAR   		--场外保有份额		
		 ,T.ITC_SUBS_AMT      				AS 			ITC_SUBS_AMT      		--场内认购金额		
		 ,T.ITC_PURS_AMT      				AS 			ITC_PURS_AMT      		--场内申购金额		
		 ,T.ITC_BUYIN_AMT     				AS 			ITC_BUYIN_AMT     		--场内买入金额		
		 ,T.ITC_REDP_AMT      				AS 			ITC_REDP_AMT      		--场内赎回金额		
		 ,T.ITC_SELL_AMT      				AS 			ITC_SELL_AMT      		--场内卖出金额		
		 ,T.OTC_SUBS_AMT      				AS 			OTC_SUBS_AMT      		--场外认购金额		
		 ,T.OTC_PURS_AMT      				AS 			OTC_PURS_AMT      		--场外申购金额		
		 ,T.OTC_CASTSL_AMT    				AS 			OTC_CASTSL_AMT    		--场外定投金额		
		 ,T.OTC_COVT_IN_AMT   				AS 			OTC_COVT_IN_AMT   		--场外转换入金额	
		 ,T.OTC_REDP_AMT      				AS 			OTC_REDP_AMT      		--场外赎回金额		
		 ,T.OTC_COVT_OUT_AMT  				AS 			OTC_COVT_OUT_AMT  		--场外转换出金额	
		 ,T.ITC_SUBS_SHAR     				AS 			ITC_SUBS_SHAR     		--场内认购份额		
		 ,T.ITC_PURS_SHAR     				AS 			ITC_PURS_SHAR     		--场内申购份额		
		 ,T.ITC_BUYIN_SHAR    				AS 			ITC_BUYIN_SHAR    		--场内买入份额		
		 ,T.ITC_REDP_SHAR     				AS 			ITC_REDP_SHAR     		--场内赎回份额		
		 ,T.ITC_SELL_SHAR     				AS 			ITC_SELL_SHAR     		--场内卖出份额		
		 ,T.OTC_SUBS_SHAR     				AS 			OTC_SUBS_SHAR     		--场外认购份额		
		 ,T.OTC_PURS_SHAR     				AS 			OTC_PURS_SHAR     		--场外申购份额		
		 ,T.OTC_CASTSL_SHAR   				AS 			OTC_CASTSL_SHAR   		--场外定投份额		
		 ,T.OTC_COVT_IN_SHAR  				AS 			OTC_COVT_IN_SHAR  		--场外转换入份额	
		 ,T.OTC_REDP_SHAR     				AS 			OTC_REDP_SHAR     		--场外赎回份额		
		 ,T.OTC_COVT_OUT_SHAR 				AS 			OTC_COVT_OUT_SHAR 		--场外转换出份额	
		 ,T.ITC_SUBS_CHAG     				AS 			ITC_SUBS_CHAG     		--场内认购手续费	
		 ,T.ITC_PURS_CHAG     				AS 			ITC_PURS_CHAG     		--场内申购手续费	
		 ,T.ITC_BUYIN_CHAG    				AS 			ITC_BUYIN_CHAG    		--场内买入手续费	
		 ,T.ITC_REDP_CHAG     				AS 			ITC_REDP_CHAG     		--场内赎回手续费	
		 ,T.ITC_SELL_CHAG     				AS 			ITC_SELL_CHAG     		--场内卖出手续费	
		 ,T.OTC_SUBS_CHAG     				AS 			OTC_SUBS_CHAG     		--场外认购手续费	
		 ,T.OTC_PURS_CHAG     				AS 			OTC_PURS_CHAG     		--场外申购手续费	
		 ,T.OTC_CASTSL_CHAG   				AS 			OTC_CASTSL_CHAG   		--场外定投手续费	
		 ,T.OTC_COVT_IN_CHAG  				AS 			OTC_COVT_IN_CHAG  		--场外转换入手续费	
		 ,T.OTC_REDP_CHAG     				AS 			OTC_REDP_CHAG     		--场外赎回手续费	
		 ,T.OTC_COVT_OUT_CHAG 				AS 			OTC_COVT_OUT_CHAG 		--场外转换出手续费	
		 ,T.CONTD_SALE_SHAR   				AS 			CONTD_SALE_SHAR   		--续作销售份额		
		 ,T.CONTD_SALE_AMT    				AS 			CONTD_SALE_AMT    		--续作销售金额		
	FROM DM.T_EVT_PROD_TRD_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	  AND T1.BRH_ID IS NOT NULL;
	
	--将临时表的按营业部维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_PROD_TRD_D_BRH (
			  OCCUR_DT          		--发生日期
		     ,BRH_ID            		--营业部编码
		     ,PROD_CD           		--产品代码			
		     ,PROD_TYPE         		--产品类型			
		     ,ITC_RETAIN_AMT    		--场内保有金额			
		     ,OTC_RETAIN_AMT    		--场外保有金额			
		     ,ITC_RETAIN_SHAR   		--场内保有份额			
		     ,OTC_RETAIN_SHAR   		--场外保有份额			
		     ,ITC_SUBS_AMT      		--场内认购金额			
		     ,ITC_PURS_AMT      		--场内申购金额			
		     ,ITC_BUYIN_AMT     		--场内买入金额			
		     ,ITC_REDP_AMT      		--场内赎回金额			
		     ,ITC_SELL_AMT      		--场内卖出金额			
		     ,OTC_SUBS_AMT      		--场外认购金额			
		     ,OTC_PURS_AMT      		--场外申购金额			
		     ,OTC_CASTSL_AMT    		--场外定投金额			
		     ,OTC_COVT_IN_AMT   		--场外转换入金额			
		     ,OTC_REDP_AMT      		--场外赎回金额			
		     ,OTC_COVT_OUT_AMT  		--场外转换出金额			
		     ,ITC_SUBS_SHAR     		--场内认购份额			
		     ,ITC_PURS_SHAR     		--场内申购份额			
		     ,ITC_BUYIN_SHAR    		--场内买入份额			
		     ,ITC_REDP_SHAR     		--场内赎回份额			
		     ,ITC_SELL_SHAR     		--场内卖出份额			
		     ,OTC_SUBS_SHAR     		--场外认购份额			
		     ,OTC_PURS_SHAR     		--场外申购份额			
		     ,OTC_CASTSL_SHAR   		--场外定投份额			
		     ,OTC_COVT_IN_SHAR  		--场外转换入份额			
		     ,OTC_REDP_SHAR     		--场外赎回份额			
		     ,OTC_COVT_OUT_SHAR 		--场外转换出份额			
		     ,ITC_SUBS_CHAG     		--场内认购手续费			
		     ,ITC_PURS_CHAG     		--场内申购手续费			
		     ,ITC_BUYIN_CHAG    		--场内买入手续费			
		     ,ITC_REDP_CHAG     		--场内赎回手续费			
		     ,ITC_SELL_CHAG     		--场内卖出手续费			
		     ,OTC_SUBS_CHAG     		--场外认购手续费			
		     ,OTC_PURS_CHAG     		--场外申购手续费			
		     ,OTC_CASTSL_CHAG   		--场外定投手续费			
		     ,OTC_COVT_IN_CHAG  		--场外转换入手续费			
		     ,OTC_REDP_CHAG     		--场外赎回手续费			
		     ,OTC_COVT_OUT_CHAG 		--场外转换出手续费			
		     ,CONTD_SALE_SHAR   		--续作销售份额			
		     ,CONTD_SALE_AMT    		--续作销售金额		
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              	--发生日期		
			,BRH_ID									AS    BRH_ID                	--营业部编码	
			,PROD_CD           		 				AS    PROD_CD					--产品代码			
		    ,PROD_TYPE         						AS    PROD_TYPE					--产品类型			
			,SUM(ITC_RETAIN_AMT)    				AS    ITC_RETAIN_AMT   			--场内保有金额		
			,SUM(OTC_RETAIN_AMT)    				AS    OTC_RETAIN_AMT   			--场外保有金额		
			,SUM(ITC_RETAIN_SHAR)   				AS    ITC_RETAIN_SHAR  			--场内保有份额		
			,SUM(OTC_RETAIN_SHAR)  					AS    OTC_RETAIN_SHAR  			--场外保有份额		
			,SUM(ITC_SUBS_AMT)      				AS    ITC_SUBS_AMT     			--场内认购金额		
			,SUM(ITC_PURS_AMT)      				AS    ITC_PURS_AMT     			--场内申购金额		
			,SUM(ITC_BUYIN_AMT)     				AS    ITC_BUYIN_AMT    			--场内买入金额		
			,SUM(ITC_REDP_AMT)      				AS    ITC_REDP_AMT     			--场内赎回金额		
			,SUM(ITC_SELL_AMT)      				AS    ITC_SELL_AMT     			--场内卖出金额		
			,SUM(OTC_SUBS_AMT)      				AS    OTC_SUBS_AMT     			--场外认购金额		
			,SUM(OTC_PURS_AMT)      				AS    OTC_PURS_AMT     			--场外申购金额		
			,SUM(OTC_CASTSL_AMT)    				AS    OTC_CASTSL_AMT   			--场外定投金额		
			,SUM(OTC_COVT_IN_AMT)   				AS    OTC_COVT_IN_AMT  			--场外转换入金额	
			,SUM(OTC_REDP_AMT)      				AS    OTC_REDP_AMT     			--场外赎回金额		
			,SUM(OTC_COVT_OUT_AMT)  				AS    OTC_COVT_OUT_AMT 			--场外转换出金额	
			,SUM(ITC_SUBS_SHAR)     				AS    ITC_SUBS_SHAR    			--场内认购份额		
			,SUM(ITC_PURS_SHAR)     				AS    ITC_PURS_SHAR    			--场内申购份额		
			,SUM(ITC_BUYIN_SHAR)    				AS    ITC_BUYIN_SHAR   			--场内买入份额		
			,SUM(ITC_REDP_SHAR)     				AS    ITC_REDP_SHAR    			--场内赎回份额		
			,SUM(ITC_SELL_SHAR)     				AS    ITC_SELL_SHAR    			--场内卖出份额		
			,SUM(OTC_SUBS_SHAR)     				AS    OTC_SUBS_SHAR    			--场外认购份额		
			,SUM(OTC_PURS_SHAR)    					AS    OTC_PURS_SHAR    			--场外申购份额		
			,SUM(OTC_CASTSL_SHAR)   				AS    OTC_CASTSL_SHAR  			--场外定投份额		
			,SUM(OTC_COVT_IN_SHAR)  				AS    OTC_COVT_IN_SHAR 			--场外转换入份额	
			,SUM(OTC_REDP_SHAR)     				AS    OTC_REDP_SHAR    			--场外赎回份额		
			,SUM(OTC_COVT_OUT_SHAR) 				AS    OTC_COVT_OUT_SHAR			--场外转换出份额	
			,SUM(ITC_SUBS_CHAG)    					AS    ITC_SUBS_CHAG    			--场内认购手续费	
			,SUM(ITC_PURS_CHAG)     				AS    ITC_PURS_CHAG    			--场内申购手续费	
			,SUM(ITC_BUYIN_CHAG)    				AS    ITC_BUYIN_CHAG   			--场内买入手续费	
			,SUM(ITC_REDP_CHAG)     				AS    ITC_REDP_CHAG    			--场内赎回手续费	
			,SUM(ITC_SELL_CHAG)     				AS    ITC_SELL_CHAG    			--场内卖出手续费	
			,SUM(OTC_SUBS_CHAG)     				AS    OTC_SUBS_CHAG    			--场外认购手续费	
			,SUM(OTC_PURS_CHAG)     				AS    OTC_PURS_CHAG    			--场外申购手续费	
			,SUM(OTC_CASTSL_CHAG)   				AS    OTC_CASTSL_CHAG  			--场外定投手续费	
			,SUM(OTC_COVT_IN_CHAG)  				AS    OTC_COVT_IN_CHAG 			--场外转换入手续费	
			,SUM(OTC_REDP_CHAG)     				AS    OTC_REDP_CHAG    			--场外赎回手续费	
			,SUM(OTC_COVT_OUT_CHAG) 				AS    OTC_COVT_OUT_CHAG			--场外转换出手续费	
			,SUM(CONTD_SALE_SHAR)   				AS    CONTD_SALE_SHAR  			--续作销售份额		
			,SUM(CONTD_SALE_AMT)    				AS    CONTD_SALE_AMT   			--续作销售金额		
		FROM #TMP_T_EVT_PROD_TRD_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID,T.PROD_CD,T.PROD_TYPE;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  程序功能: 产品交易事实表_日表
  编写者: 张琦
  创建日期: 2017-12-07
  简介：记录场外产品保有销售，包括开基、银行理财、证券理财
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
	commit;
  
    DELETE FROM DM.T_EVT_PROD_TRD_D_D WHERE OCCUR_DT = @v_date;
	-- 开基
	INSERT INTO DM.T_EVT_PROD_TRD_D_D(
	    CUST_ID      -- 客户编码
	    ,PROD_CD        -- 产品代码
	    ,PROD_TYPE      -- 产品类型
	    ,OCCUR_DT       -- 业务日期
	    ,MAIN_CPTL_ACCT -- 主资金账号
		,ITC_SUBS_AMT	-- 场内认购金额
		,ITC_PURS_AMT  -- 场内申购金额
		,ITC_REDP_AMT  -- 场内赎回金额
		,ITC_RETAIN_AMT  -- 场内保有金额
		,ITC_BUYIN_AMT -- 场内买入金额
		,ITC_SELL_AMT  -- 场内卖出金额
		,OTC_SUBS_AMT  -- 场外认购金额
		,OTC_PURS_AMT  -- 场外申购金额
		,OTC_REDP_AMT  -- 场外赎回金额
		,OTC_RETAIN_AMT  -- 场外保有金额
		,OTC_CASTSL_AMT    -- 场外定投金额
		,OTC_COVT_IN_AMT  -- 场外转换入金额
		,OTC_COVT_OUT_AMT -- 场外转换出金额
		,ITC_RETAIN_SHAR    -- 场内保有份额
		,OTC_RETAIN_SHAR    -- 场外保有份额
		
		
		,ITC_SUBS_CHAG   -- 场内认购手续费
		,ITC_PURS_CHAG    -- 场内申购手续费
		,ITC_BUYIN_CHAG   -- 场内买入手续费
		,ITC_REDP_CHAG    -- 场内赎回手续费
		,ITC_SELL_CHAG    -- 场内卖出手续费
		,OTC_SUBS_CHAG    -- 场外认购手续费
		,OTC_PURS_CHAG    -- 场外申购手续费
		,OTC_CASTSL_CHAG  -- 场外定投手续费
		,OTC_COVT_IN_CHAG    -- 场外转换入手续费
		,OTC_REDP_CHAG        -- 场外赎回手续费
		,OTC_COVT_OUT_CHAG   -- 场外转换出手续费
		,LOAD_DT
	)
	SELECT 
		b.client_id AS CUST_ID  -- 客户编码
		,a.jjdm AS PROD_CD        -- 产品代码
		,'场外基金' AS PROD_TYPE  -- 产品类型
		,@v_date AS OCCUR_DT   -- 业务日期
		,a.zjzh as MAIN_CPTL_ACCT   -- 主资金账号
		,a.cnje_rgqr_d AS ITC_SUBS_AMT  -- 场内认购金额
		,a.cnje_sgqr_d AS ITC_PURS_AMT  -- 场内申购金额
		,a.cnje_shqr_d as ITC_REDP_AMT  -- 场内赎回金额
		,a.qmsz_cn_d as ITC_RETAIN_AMT  -- 场内保有金额
		,a.cnje_jymr_d as ITC_BUYIN_AMT -- 场内买入金额
		,a.cnje_jymc_d as ITC_SELL_AMT  -- 场内卖出金额
		,a.cwje_rgqr_d as OTC_SUBS_AMT  -- 场外认购金额
		,a.cwje_sgqr_d as OTC_PURS_AMT  -- 场外申购金额
		,a.cwje_shqr_d as OTC_REDP_AMT  -- 场外赎回金额
		,a.qmsz_cw_d as OTC_RETAIN_AMT  -- 场外保有金额
		,a.cwje_dsdetzqr_d as OTC_CASTSL_AMT    -- 场外定投金额
		,a.cwje_zhrqr_d as OTC_COVT_IN_AMT  -- 场外转换入金额
		,a.cwje_zhcqr_d as OTC_COVT_OUT_AMT -- 场外转换出金额
		
		,a.qmfe_cn_d as ITC_RETAIN_SHAR   -- 场内保有份额
		,a.qmfe_cw_d as OTC_RETAIN_SHAR     -- 场外保有份额
		
		,a.cwsxf_zhcqr_d as ITC_SUBS_CHAG   -- 场内认购手续费
		,a.cnsxf_sgqr_d as ITC_PURS_CHAG    -- 场内申购手续费
		,a.cnsxf_jymr_d as ITC_BUYIN_CHAG   -- 场内买入手续费
		,a.cnsxf_shqr_d as ITC_REDP_CHAG    -- 场内赎回手续费
		,a.cnsxf_jymc_d as ITC_SELL_CHAG    -- 场内卖出手续费
		,a.cwsxf_rgqr_d as OTC_SUBS_CHAG    -- 场外认购手续费
		,a.cwsxf_sgqr_d as OTC_PURS_CHAG    -- 场外申购手续费
		,a.cwsxf_dsdetzqr_d as OTC_CASTSL_CHAG  -- 场外定投手续费
		,a.cwsxf_zhrqr_d as OTC_COVT_IN_CHAG    -- 场外转换入手续费
		,a.cwsxf_shqr_d as OTC_REDP_CHAG        -- 场外赎回手续费
		,a.cwsxf_zhcqr_d as OTC_COVT_OUT_CHAG   -- 场外转换出手续费
		,@v_date AS LOAD_DT
	FROM dba.t_ddw_xy_jjzb_d a
	LEFT JOIN DBA.T_ODS_UF2_FUNDACCOUNT b ON a.zjzh = b.fund_account and b.main_flag='1'
	WHERE a.rq=@v_date and b.client_id is not null;
    
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET ITC_SUBS_SHAR = coalesce(b.cnfe_rgqr_d,0)   -- 场内认购份额
        ,ITC_PURS_SHAR = coalesce(b.cnfe_sgqr_d,0)  -- 场内申购份额
        ,ITC_REDP_SHAR = coalesce(b.cnfe_shqr_d,0)  -- 场内赎回份额
        ,ITC_BUYIN_SHAR = coalesce(b.cnfe_jymr_d,0) -- 场内买入份额
        ,ITC_SELL_SHAR = coalesce(b.cnfe_jymc_d,0) -- 场内卖出份额
        ,OTC_SUBS_SHAR = coalesce(b.cwfe_rgqr_d,0) -- 场外认购份额
        ,OTC_PURS_SHAR = coalesce(b.cwfe_sgqr_d,0) -- 场外申购份额
        ,OTC_REDP_SHAR = coalesce(b.cwfe_shqr_d,0)  -- 场外赎回份额
        ,OTC_CASTSL_SHAR = coalesce(b.cwfe_dsdetzqr_d,0) -- 场外定投份额
        ,OTC_COVT_IN_SHAR = coalesce(b.cwfe_zhrqr_d,0)  -- 场外转换入份额
        ,OTC_COVT_OUT_SHAR = coalesce(b.cwfe_zhcqr_d,0) -- 场外转换出份额
        
        ,ITC_SUBS_CNT = coalesce(b.cnbs_rgqr_d,0)    -- 场内认购笔数
        ,ITC_PURS_CNT = coalesce(b.cnbs_sgqr_d,0)   -- 场内申购笔数
        ,ITC_BUYIN_CNT = coalesce(b.cnbs_jymr_d,0) -- 场内买入笔数
        ,ITC_REDP_CNT = coalesce(b.cnbs_shqr_d,0) -- 场内赎回笔数
        ,ITC_SELL_CNT = coalesce(b.cnbs_jymc_d,0)   -- 场内卖出笔数
        ,OTC_SUBS_CNT = coalesce(b.cwbs_rgqr_d,0)   -- 场外认购笔数
        ,OTC_PURS_CNT = coalesce(b.cwbs_sgqr_d,0)   -- 场外申购笔数
        ,OTC_CASTSL_CNT = coalesce(b.cwbs_dsdetzqr_d,0) -- 场外定投笔数
        ,OTC_COVT_IN_CNT = coalesce(b.cwbs_zhrqr_d,0)   -- 场外转换入笔数
        ,OTC_REDP_CNT = coalesce(b.cwbs_shqr_d,0)   -- 场外赎回笔数
        ,OTC_COVT_OUT_CNT = coalesce(b.cwbs_zhcqr_d,0) -- 场外转换出笔数
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        SELECT a.fund_acct AS zjzh,
              a.stock_cd AS jjdm,
              
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND (a.busi_cd IN ('3408', '9994') OR (a.busi_cd='5140' and note like '%开放基金认购结果返款%')) THEN 1 ELSE 0 END) AS cnbs_rgqr_d,      -- 场内认购笔数
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5122' THEN 1 ELSE 0 END) AS cnbs_sgqr_d,      -- 场内申购笔数
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5124' THEN 1 ELSE 0 end) AS cnbs_shqr_d,      -- 场内赎回笔数
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3101' THEN 1 ELSE 0 end) AS cnbs_jymr_d,      -- 场内买入笔数
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3102' THEN 1 ELSE 0 end) AS cnbs_jymc_d,      -- 场内卖出笔数
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5130' THEN 1 ELSE 0 END) AS cwbs_rgqr_d,            -- 场外认购笔数
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5122' THEN 1 ELSE 0 END) AS cwbs_sgqr_d,            -- 场外申购笔数
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5139' THEN 1 ELSE 0 END) AS cwbs_dsdetzqr_d,        -- 场外定投笔数
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5137' THEN 1 ELSE 0 END) AS cwbs_zhrqr_d,           -- 场外转换入笔数
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd IN ('5136', '5138') THEN 1 ELSE 0 END) AS cwbs_zhcqr_d,           -- 场外转换出笔数
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5124' THEN 1 ELSE 0 END) AS cwbs_shqr_d,             -- 场外赎回笔数
              
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND (a.busi_cd IN ('3408', '9994') OR (a.busi_cd='5140' and note like '%开放基金认购结果返款%')) THEN a.trad_num ELSE 0 END) AS cnfe_rgqr_d,      -- 场内认购份额
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5122' THEN a.trad_num ELSE 0 END) AS cnfe_sgqr_d,      -- 场内申购份额
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5124' THEN a.trad_num ELSE 0 end) AS cnfe_shqr_d,      -- 场内赎回份额
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3101' THEN a.trad_num ELSE 0 end) AS cnfe_jymr_d,      -- 场内买入份额
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3102' THEN a.trad_num ELSE 0 end) AS cnfe_jymc_d,      -- 场内卖出份额
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5130' THEN a.trad_num ELSE 0 END) AS cwfe_rgqr_d,            -- 场外认购份额
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5122' THEN a.trad_num ELSE 0 END) AS cwfe_sgqr_d,            -- 场外申购份额
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5139' THEN a.trad_num ELSE 0 END) AS cwfe_dsdetzqr_d,        -- 场外定投份额
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5137' THEN a.trad_num ELSE 0 END) AS cwfe_zhrqr_d,           -- 场外转换入份额
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd IN ('5136', '5138') THEN a.trad_num ELSE 0 END) AS cwfe_zhcqr_d,           -- 场外转换出份额
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5124' THEN a.trad_num ELSE 0 END) AS cwfe_shqr_d             -- 场外赎回份额
         FROM dba.t_edw_t05_trade_jour a
        WHERE a.load_dt = @v_date
          AND a.stock_type_cd IN ('19', '1A')
        GROUP BY a.fund_acct, a.stock_cd
    ) b ON a.MAIN_CPTL_ACCT=b.zjzh
    where a.OCCUR_DT=@v_date;
    
    -- TODO: 续做销售份额(CONTD_SALE_SHAR) 续做销售金额(CONTD_SALE_AMT)
    
    
    -- 银行理财产品，初始化
    INSERT INTO DM.T_EVT_PROD_TRD_D_D(
        CUST_ID      -- 客户编码
        ,PROD_CD        -- 产品代码
        ,PROD_TYPE      -- 产品类型
        ,OCCUR_DT       -- 业务日期
        ,MAIN_CPTL_ACCT -- 主资金账号
        
        ,ITC_SUBS_AMT
        ,ITC_PURS_AMT
        ,ITC_REDP_AMT
        ,ITC_RETAIN_AMT
        ,ITC_BUYIN_AMT
        ,ITC_SELL_AMT
        ,OTC_SUBS_AMT
        ,OTC_PURS_AMT
        ,OTC_REDP_AMT
        ,OTC_RETAIN_AMT
        ,OTC_CASTSL_AMT
        ,OTC_COVT_IN_AMT
        ,OTC_COVT_OUT_AMT
        ,ITC_SUBS_SHAR
        ,ITC_PURS_SHAR
        ,ITC_REDP_SHAR
        ,ITC_RETAIN_SHAR
        ,ITC_BUYIN_SHAR
        ,ITC_SELL_SHAR
        ,OTC_SUBS_SHAR
        ,OTC_PURS_SHAR
        ,OTC_REDP_SHAR
        ,OTC_RETAIN_SHAR
        ,OTC_CASTSL_SHAR
        ,OTC_COVT_IN_SHAR
        ,OTC_COVT_OUT_SHAR
        ,ITC_SUBS_CNT
        ,ITC_PURS_CNT
        ,ITC_BUYIN_CNT
        ,ITC_REDP_CNT
        ,ITC_SELL_CNT
        ,OTC_SUBS_CNT
        ,OTC_PURS_CNT
        ,OTC_CASTSL_CNT
        ,OTC_COVT_IN_CNT
        ,OTC_REDP_CNT
        ,OTC_COVT_OUT_CNT
        ,ITC_SUBS_CHAG
        ,ITC_PURS_CHAG
        ,ITC_BUYIN_CHAG
        ,ITC_REDP_CHAG
        ,ITC_SELL_CHAG
        ,OTC_SUBS_CHAG
        ,OTC_PURS_CHAG
        ,OTC_CASTSL_CHAG
        ,OTC_COVT_IN_CHAG
        ,OTC_REDP_CHAG
        ,OTC_COVT_OUT_CHAG
        ,CONTD_SALE_SHAR
        ,CONTD_SALE_AMT
        ,LOAD_DT
    )
    select
        a.CLIENT_ID as CUST_ID      -- 客户编码
        ,a.PROD_CODE as PROD_CD        -- 产品代码
        ,'银行理财' as PROD_TYPE      -- 产品类型
        ,@v_date as OCCUR_DT       -- 业务日期
        ,a.FUND_ACCOUNT AS MAIN_CPTL_ACCT -- 主资金账号
        
        ,0 as ITC_SUBS_AMT
        ,0 as ITC_PURS_AMT
        ,0 as ITC_REDP_AMT
        ,0 as ITC_RETAIN_AMT
        ,0 as ITC_BUYIN_AMT
        ,0 as ITC_SELL_AMT
        ,0 as OTC_SUBS_AMT
        ,0 as OTC_PURS_AMT
        ,0 as OTC_REDP_AMT
        ,0 as OTC_RETAIN_AMT
        ,0 as OTC_CASTSL_AMT
        ,0 as OTC_COVT_IN_AMT
        ,0 as OTC_COVT_OUT_AMT
        ,0 as ITC_SUBS_SHAR
        ,0 as ITC_PURS_SHAR
        ,0 as ITC_REDP_SHAR
        ,0 as ITC_RETAIN_SHAR
        ,0 as ITC_BUYIN_SHAR
        ,0 as ITC_SELL_SHAR
        ,0 as OTC_SUBS_SHAR
        ,0 as OTC_PURS_SHAR
        ,0 as OTC_REDP_SHAR
        ,0 as OTC_RETAIN_SHAR
        ,0 as OTC_CASTSL_SHAR
        ,0 as OTC_COVT_IN_SHAR
        ,0 as OTC_COVT_OUT_SHAR
        ,0 as ITC_SUBS_CNT
        ,0 as ITC_PURS_CNT
        ,0 as ITC_BUYIN_CNT
        ,0 as ITC_REDP_CNT
        ,0 as ITC_SELL_CNT
        ,0 as OTC_SUBS_CNT
        ,0 as OTC_PURS_CNT
        ,0 as OTC_CASTSL_CNT
        ,0 as OTC_COVT_IN_CNT
        ,0 as OTC_REDP_CNT
        ,0 as OTC_COVT_OUT_CNT
        ,0 as ITC_SUBS_CHAG
        ,0 as ITC_PURS_CHAG
        ,0 as ITC_BUYIN_CHAG
        ,0 as ITC_REDP_CHAG
        ,0 as ITC_SELL_CHAG
        ,0 as OTC_SUBS_CHAG
        ,0 as OTC_PURS_CHAG
        ,0 as OTC_CASTSL_CHAG
        ,0 as OTC_COVT_IN_CHAG
        ,0 as OTC_REDP_CHAG
        ,0 as OTC_COVT_OUT_CHAG
        ,0 as CONTD_SALE_SHAR
        ,0 as CONTD_SALE_AMT
        ,@v_date as LOAD_DT
    from (
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.T_EDW_UF2_HIS_BANKMDELIVER
        where LOAD_DT=@v_date
        union
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.GT_ODS_ZHXT_BANKMSHARE
        where load_dt=@v_date
    ) a;
    
    -- 更新银行理财交易数据
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_PURS_AMT = COALESCE(b.OTC_PURS_AMT,0)       -- 场外申购金额
        ,OTC_PURS_SHAR = coalesce(b.OTC_PURS_SHAR,0)    -- 场外申购份额
        ,OTC_PURS_CNT = coalesce(b.OTC_PURS_CNT,0)      -- 场外申购笔数
        ,OTC_REDP_AMT = coalesce(b.OTC_REDP_AMT,0)      -- 场外赎回金额
        ,OTC_REDP_SHAR = coalesce(b.OTC_REDP_SHAR,0)    -- 场外赎回份额
        ,OTC_REDP_CNT = coalesce(b.OTC_REDP_CNT,0)       -- 场外赎回笔数
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        SELECT CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,sum(case when business_flag=43130 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_PURS_AMT   -- 场外申购金额
            ,sum(case when business_flag=43130 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_PURS_SHAR  -- 场外申购份额
            ,count(case when business_flag=43130 then 1 else 0 end) as OTC_PURS_CNT   -- 场外申购笔数
            
            ,sum(case when business_flag=43142 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_REDP_AMT   -- 场外赎回金额
            ,sum(case when business_flag=43142 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_REDP_SHAR  -- 场外赎回份额
            ,count(case when business_flag=43142 then 1 else 0 end) as OTC_REDP_CNT   -- 场外赎回笔数
        FROM DBA.T_EDW_UF2_HIS_BANKMDELIVER a
        WHERE LOAD_DT=@v_date
        group by CLIENT_ID,PROD_CODE
    ) b on a.CUST_ID=b.CUST_ID and a.PROD_CD = b.PROD_CD
    WHERE a.OCCUR_DT=@v_date AND a.PROD_TYPE='银行理财';
    
    -- 更新银行理财保有
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_RETAIN_AMT = coalesce(b.OTC_RETAIN_AMT,0),   -- 场外保有金额
        OTC_RETAIN_SHAR = coalesce(b.OTC_RETAIN_SHAR,0) -- 场外保有份额
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        select CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_AMT -- 场外保有金额
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_SHAR    -- 场外保有份额
        from dba.GT_ODS_ZHXT_BANKMSHARE
        where LOAD_DT=@v_date
        GROUP BY CLIENT_ID, PROD_CODE
    ) b ON a.CUST_ID=b.CUST_ID and a.PROD_CD=b.PROD_CD
    where a.PROD_TYPE='银行理财' and OCCUR_DT=@v_date;

    -- 证券理财初始化
    INSERT INTO DM.T_EVT_PROD_TRD_D_D(
        CUST_ID      -- 客户编码
        ,PROD_CD        -- 产品代码
        ,PROD_TYPE      -- 产品类型
        ,OCCUR_DT       -- 业务日期
        ,MAIN_CPTL_ACCT -- 主资金账号
        
        ,ITC_SUBS_AMT
        ,ITC_PURS_AMT
        ,ITC_REDP_AMT
        ,ITC_RETAIN_AMT
        ,ITC_BUYIN_AMT
        ,ITC_SELL_AMT
        ,OTC_SUBS_AMT
        ,OTC_PURS_AMT
        ,OTC_REDP_AMT
        ,OTC_RETAIN_AMT
        ,OTC_CASTSL_AMT
        ,OTC_COVT_IN_AMT
        ,OTC_COVT_OUT_AMT
        ,ITC_SUBS_SHAR
        ,ITC_PURS_SHAR
        ,ITC_REDP_SHAR
        ,ITC_RETAIN_SHAR
        ,ITC_BUYIN_SHAR
        ,ITC_SELL_SHAR
        ,OTC_SUBS_SHAR
        ,OTC_PURS_SHAR
        ,OTC_REDP_SHAR
        ,OTC_RETAIN_SHAR
        ,OTC_CASTSL_SHAR
        ,OTC_COVT_IN_SHAR
        ,OTC_COVT_OUT_SHAR
        ,ITC_SUBS_CNT
        ,ITC_PURS_CNT
        ,ITC_BUYIN_CNT
        ,ITC_REDP_CNT
        ,ITC_SELL_CNT
        ,OTC_SUBS_CNT
        ,OTC_PURS_CNT
        ,OTC_CASTSL_CNT
        ,OTC_COVT_IN_CNT
        ,OTC_REDP_CNT
        ,OTC_COVT_OUT_CNT
        ,ITC_SUBS_CHAG
        ,ITC_PURS_CHAG
        ,ITC_BUYIN_CHAG
        ,ITC_REDP_CHAG
        ,ITC_SELL_CHAG
        ,OTC_SUBS_CHAG
        ,OTC_PURS_CHAG
        ,OTC_CASTSL_CHAG
        ,OTC_COVT_IN_CHAG
        ,OTC_REDP_CHAG
        ,OTC_COVT_OUT_CHAG
        ,CONTD_SALE_SHAR
        ,CONTD_SALE_AMT
        ,LOAD_DT
    )
    select
        a.CLIENT_ID as CUST_ID      -- 客户编码
        ,a.PROD_CODE as PROD_CD        -- 产品代码
        ,'证券理财' as PROD_TYPE      -- 产品类型
        ,@v_date as OCCUR_DT       -- 业务日期
        ,a.FUND_ACCOUNT AS MAIN_CPTL_ACCT -- 主资金账号
        
        ,0 as ITC_SUBS_AMT
        ,0 as ITC_PURS_AMT
        ,0 as ITC_REDP_AMT
        ,0 as ITC_RETAIN_AMT
        ,0 as ITC_BUYIN_AMT
        ,0 as ITC_SELL_AMT
        ,0 as OTC_SUBS_AMT
        ,0 as OTC_PURS_AMT
        ,0 as OTC_REDP_AMT
        ,0 as OTC_RETAIN_AMT
        ,0 as OTC_CASTSL_AMT
        ,0 as OTC_COVT_IN_AMT
        ,0 as OTC_COVT_OUT_AMT
        ,0 as ITC_SUBS_SHAR
        ,0 as ITC_PURS_SHAR
        ,0 as ITC_REDP_SHAR
        ,0 as ITC_RETAIN_SHAR
        ,0 as ITC_BUYIN_SHAR
        ,0 as ITC_SELL_SHAR
        ,0 as OTC_SUBS_SHAR
        ,0 as OTC_PURS_SHAR
        ,0 as OTC_REDP_SHAR
        ,0 as OTC_RETAIN_SHAR
        ,0 as OTC_CASTSL_SHAR
        ,0 as OTC_COVT_IN_SHAR
        ,0 as OTC_COVT_OUT_SHAR
        ,0 as ITC_SUBS_CNT
        ,0 as ITC_PURS_CNT
        ,0 as ITC_BUYIN_CNT
        ,0 as ITC_REDP_CNT
        ,0 as ITC_SELL_CNT
        ,0 as OTC_SUBS_CNT
        ,0 as OTC_PURS_CNT
        ,0 as OTC_CASTSL_CNT
        ,0 as OTC_COVT_IN_CNT
        ,0 as OTC_REDP_CNT
        ,0 as OTC_COVT_OUT_CNT
        ,0 as ITC_SUBS_CHAG
        ,0 as ITC_PURS_CHAG
        ,0 as ITC_BUYIN_CHAG
        ,0 as ITC_REDP_CHAG
        ,0 as ITC_SELL_CHAG
        ,0 as OTC_SUBS_CHAG
        ,0 as OTC_PURS_CHAG
        ,0 as OTC_CASTSL_CHAG
        ,0 as OTC_COVT_IN_CHAG
        ,0 as OTC_REDP_CHAG
        ,0 as OTC_COVT_OUT_CHAG
        ,0 as CONTD_SALE_SHAR
        ,0 as CONTD_SALE_AMT
        ,@v_date as LOAD_DT
    from (
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.GT_ODS_ZHXT_HIS_SECUMDELIVER
        where LOAD_DT=@v_date
        union
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.GT_ODS_ZHXT_SECUMSHARE
        where load_dt=@v_date
    ) a;

    -- 更新证券理财交易数据
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_PURS_AMT = COALESCE(b.OTC_PURS_AMT,0)       -- 场外申购金额
        ,OTC_PURS_SHAR = coalesce(b.OTC_PURS_SHAR,0)    -- 场外申购份额
        ,OTC_PURS_CNT = coalesce(b.OTC_PURS_CNT,0)      -- 场外申购笔数
        ,OTC_REDP_AMT = coalesce(b.OTC_REDP_AMT,0)      -- 场外赎回金额
        ,OTC_REDP_SHAR = coalesce(b.OTC_REDP_SHAR,0)    -- 场外赎回份额
        ,OTC_REDP_CNT = coalesce(b.OTC_REDP_CNT,0)       -- 场外赎回笔数
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        SELECT CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,sum(case when business_flag=44130 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_PURS_AMT   -- 场外申购金额
            ,sum(case when business_flag=44130 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_PURS_SHAR  -- 场外申购份额
            ,count(case when business_flag=44130 then 1 else 0 end) as OTC_PURS_CNT   -- 场外申购笔数
            
            ,sum(case when business_flag=44150 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_REDP_AMT   -- 场外赎回金额
            ,sum(case when business_flag=44150 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_REDP_SHAR  -- 场外赎回份额
            ,count(case when business_flag=44150 then 1 else 0 end) as OTC_REDP_CNT   -- 场外赎回笔数
        FROM DBA.GT_ODS_ZHXT_HIS_SECUMDELIVER a
        WHERE LOAD_DT=@v_date
        group by CLIENT_ID,PROD_CODE
    ) b on a.CUST_ID=b.CUST_ID and a.PROD_CD = b.PROD_CD
    WHERE a.OCCUR_DT=@v_date AND a.PROD_TYPE='证券理财';


    
    -- 更新证券理财保有
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_RETAIN_AMT = coalesce(b.OTC_RETAIN_AMT,0),   -- 场外保有金额
        OTC_RETAIN_SHAR = coalesce(b.OTC_RETAIN_SHAR,0) -- 场外保有份额
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        select CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_AMT -- 场外保有金额
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_SHAR    -- 场外保有份额
        from dba.GT_ODS_ZHXT_SECUMSHARE 
        where LOAD_DT=@v_date
        GROUP BY CLIENT_ID, PROD_CODE
    ) b ON a.CUST_ID=b.CUST_ID and a.PROD_CD=b.PROD_CD
    where a.PROD_TYPE='证券理财' and OCCUR_DT=@v_date;


    update dm.T_EVT_PROD_TRD_D_D
    set contd_sale_shar =  otc_retain_shar - otc_subs_shar   -- 续做销售份额(场外保有份额 - 场外认购份额)
        ,contd_sale_amt =  otc_retain_amt - otc_subs_amt     -- 续做销售金额(场外保有金额 - 场外认购金额)
    -- select *
    from dm.T_EVT_PROD_TRD_D_D a
    where a.occur_dt=@v_date
    and a.prod_cd in 
    (
        select distinct b.seccode
        from dba.T_EDW_PD_T_PROD_FINANCIAL_COLLECTION a
        left join dba.T_EDW_PD_V_PROD_DC_PRODUCT b on a.product_id=b.product_id and a.load_dt=b.load_dt
        where a.load_dt=@v_date and a.is_staging='1'
        and substr(a.establish_time,1,8)=convert(varchar,@v_date)
    );

   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工产品事实表（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-09
  简介：员工产品事实表（日表）
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_PROD_TRD_D_EMP WHERE OCCUR_DT = @V_DATE;

  	-- 基于责权分配表统计（员工-客户）绩效分配比例
  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH;


	CREATE TABLE #TMP_T_EVT_PROD_TRD_D_EMP(
	    OCCUR_DT             	numeric(8,0) 		NOT NULL,
		EMP_ID               	varchar(30) 		NOT NULL,
		MAIN_CPTL_ACCT		 	varchar(30) 		NOT NULL,
		PROD_CD              	varchar(30) 		NOT NULL,
		PROD_TYPE            	varchar(30) 		NOT NULL,
		ITC_RETAIN_AMT       	numeric(38,8) 		NULL,
		OTC_RETAIN_AMT       	numeric(38,8) 		NULL,
		ITC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		OTC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		ITC_SUBS_AMT         	numeric(38,8) 		NULL,
		ITC_PURS_AMT         	numeric(38,8) 		NULL,
		ITC_BUYIN_AMT        	numeric(38,8) 		NULL,
		ITC_REDP_AMT         	numeric(38,8) 		NULL,
		ITC_SELL_AMT         	numeric(38,8) 		NULL,
		OTC_SUBS_AMT         	numeric(38,8) 		NULL,
		OTC_PURS_AMT         	numeric(38,8) 		NULL,
		OTC_CASTSL_AMT       	numeric(38,8) 		NULL,
		OTC_COVT_IN_AMT      	numeric(38,8) 		NULL,
		OTC_REDP_AMT         	numeric(38,8) 		NULL,
		OTC_COVT_OUT_AMT     	numeric(38,8) 		NULL,
		ITC_SUBS_SHAR        	numeric(38,8) 		NULL,
		ITC_PURS_SHAR        	numeric(38,8) 		NULL,
		ITC_BUYIN_SHAR       	numeric(38,8) 		NULL,
		ITC_REDP_SHAR        	numeric(38,8) 		NULL,
		ITC_SELL_SHAR        	numeric(38,8) 		NULL,
		OTC_SUBS_SHAR        	numeric(38,8) 		NULL,
		OTC_PURS_SHAR        	numeric(38,8) 		NULL,
		OTC_CASTSL_SHAR      	numeric(38,8) 		NULL,
		OTC_COVT_IN_SHAR     	numeric(38,8) 		NULL,
		OTC_REDP_SHAR        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_SHAR    	numeric(38,8) 		NULL,
		ITC_SUBS_CHAG        	numeric(38,8) 		NULL,
		ITC_PURS_CHAG        	numeric(38,8) 		NULL,
		ITC_BUYIN_CHAG       	numeric(38,8) 		NULL,
		ITC_REDP_CHAG        	numeric(38,8) 		NULL,
		ITC_SELL_CHAG        	numeric(38,8) 		NULL,
		OTC_SUBS_CHAG        	numeric(38,8) 		NULL,
		OTC_PURS_CHAG        	numeric(38,8) 		NULL,
		OTC_CASTSL_CHAG      	numeric(38,8) 		NULL,
		OTC_COVT_IN_CHAG     	numeric(38,8) 		NULL,
		OTC_REDP_CHAG        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_CHAG    	numeric(38,8) 		NULL,
		CONTD_SALE_SHAR      	numeric(38,8) 		NULL,
		CONTD_SALE_AMT       	numeric(38,8) 		NULL
	);

	INSERT INTO #TMP_T_EVT_PROD_TRD_D_EMP(
		  OCCUR_DT          		--发生日期
		 ,EMP_ID            		--员工编码
		 ,MAIN_CPTL_ACCT			--资金账号			
		 ,PROD_CD           		--产品代码			
		 ,PROD_TYPE         		--产品类型			
		 ,ITC_RETAIN_AMT    		--场内保有金额			
		 ,OTC_RETAIN_AMT    		--场外保有金额			
		 ,ITC_RETAIN_SHAR   		--场内保有份额			
		 ,OTC_RETAIN_SHAR   		--场外保有份额			
		 ,ITC_SUBS_AMT      		--场内认购金额			
		 ,ITC_PURS_AMT      		--场内申购金额			
		 ,ITC_BUYIN_AMT     		--场内买入金额			
		 ,ITC_REDP_AMT      		--场内赎回金额			
		 ,ITC_SELL_AMT      		--场内卖出金额			
		 ,OTC_SUBS_AMT      		--场外认购金额			
		 ,OTC_PURS_AMT      		--场外申购金额			
		 ,OTC_CASTSL_AMT    		--场外定投金额			
		 ,OTC_COVT_IN_AMT   		--场外转换入金额			
		 ,OTC_REDP_AMT      		--场外赎回金额			
		 ,OTC_COVT_OUT_AMT  		--场外转换出金额			
		 ,ITC_SUBS_SHAR     		--场内认购份额			
		 ,ITC_PURS_SHAR     		--场内申购份额			
		 ,ITC_BUYIN_SHAR    		--场内买入份额			
		 ,ITC_REDP_SHAR     		--场内赎回份额			
		 ,ITC_SELL_SHAR     		--场内卖出份额			
		 ,OTC_SUBS_SHAR     		--场外认购份额			
		 ,OTC_PURS_SHAR     		--场外申购份额			
		 ,OTC_CASTSL_SHAR   		--场外定投份额			
		 ,OTC_COVT_IN_SHAR  		--场外转换入份额			
		 ,OTC_REDP_SHAR     		--场外赎回份额			
		 ,OTC_COVT_OUT_SHAR 		--场外转换出份额			
		 ,ITC_SUBS_CHAG     		--场内认购手续费			
		 ,ITC_PURS_CHAG     		--场内申购手续费			
		 ,ITC_BUYIN_CHAG    		--场内买入手续费			
		 ,ITC_REDP_CHAG     		--场内赎回手续费			
		 ,ITC_SELL_CHAG     		--场内卖出手续费			
		 ,OTC_SUBS_CHAG     		--场外认购手续费			
		 ,OTC_PURS_CHAG     		--场外申购手续费			
		 ,OTC_CASTSL_CHAG   		--场外定投手续费			
		 ,OTC_COVT_IN_CHAG  		--场外转换入手续费			
		 ,OTC_REDP_CHAG     		--场外赎回手续费			
		 ,OTC_COVT_OUT_CHAG 		--场外转换出手续费			
		 ,CONTD_SALE_SHAR   		--续作销售份额			
		 ,CONTD_SALE_AMT    		--续作销售金额			
	)
	SELECT 
		  T.OCCUR_DT						AS			OCCUR_DT          		--发生日期
		 ,T1.EMP_ID							AS 			EMP_ID					--员工编码
		 ,T.MAIN_CPTL_ACCT	  				AS 			MAIN_CPTL_ACCT			--资金账号
		 ,T.PROD_CD 						AS  		PROD_CD 				--产品代码				
		 ,T.PROD_TYPE 						AS  		PROD_TYPE 				--产品类型
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_RETAIN_AMT           --场内保有金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_RETAIN_AMT           --场外保有金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_RETAIN_SHAR          --场内保有份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_RETAIN_SHAR          --场外保有份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_SUBS_AMT             --场内认购金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_PURS_AMT             --场内申购金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_BUYIN_AMT            --场内买入金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_REDP_AMT             --场内赎回金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_SELL_AMT             --场内卖出金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_SUBS_AMT             --场外认购金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_PURS_AMT             --场外申购金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_CASTSL_AMT           --场外定投金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_COVT_IN_AMT          --场外转换入金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_REDP_AMT             --场外赎回金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_COVT_OUT_AMT         --场外转换出金额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_SUBS_SHAR            --场内认购份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_PURS_SHAR            --场内申购份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0)
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_BUYIN_SHAR           --场内买入份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_REDP_SHAR            --场内赎回份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_SELL_SHAR            --场内卖出份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_SUBS_SHAR            --场外认购份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_PURS_SHAR            --场外申购份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       AS   OTC_CASTSL_SHAR          --场外定投份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_COVT_IN_SHAR         --场外转换入份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_REDP_SHAR            --场外赎回份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_COVT_OUT_SHAR        --场外转换出份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   AS   ITC_SUBS_CHAG            --场内认购手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_PURS_CHAG            --场内申购手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_BUYIN_CHAG           --场内买入手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_REDP_CHAG            --场内赎回手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_SELL_CHAG            --场内卖出手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_SUBS_CHAG            --场外认购手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_PURS_CHAG            --场外申购手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_CASTSL_CHAG          --场外定投手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_COVT_IN_CHAG         --场外转换入手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_REDP_CHAG            --场外赎回手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_COVT_OUT_CHAG        --场外转换出手续费
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   CONTD_SALE_SHAR          --续作销售份额
		 ,CASE WHEN T.PROD_TYPE='私募基金' THEN COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='集合理财' THEN COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='基金专户' THEN COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   CONTD_SALE_AMT           --续作销售金额
	FROM DM.T_EVT_PROD_TRD_D_D T
	LEFT JOIN #TMP_PERF_DISTR T1
		ON T.MAIN_CPTL_ACCT = T1.MAIN_CPTL_ACCT
	WHERE T.OCCUR_DT = @V_DATE;
	
	--将临时表的按员工维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_PROD_TRD_D_EMP (
			  OCCUR_DT          		--发生日期
		     ,EMP_ID            		--员工编码
		     ,PROD_CD           		--产品代码			
		     ,PROD_TYPE         		--产品类型			
		     ,ITC_RETAIN_AMT    		--场内保有金额			
		     ,OTC_RETAIN_AMT    		--场外保有金额			
		     ,ITC_RETAIN_SHAR   		--场内保有份额			
		     ,OTC_RETAIN_SHAR   		--场外保有份额			
		     ,ITC_SUBS_AMT      		--场内认购金额			
		     ,ITC_PURS_AMT      		--场内申购金额			
		     ,ITC_BUYIN_AMT     		--场内买入金额			
		     ,ITC_REDP_AMT      		--场内赎回金额			
		     ,ITC_SELL_AMT      		--场内卖出金额			
		     ,OTC_SUBS_AMT      		--场外认购金额			
		     ,OTC_PURS_AMT      		--场外申购金额			
		     ,OTC_CASTSL_AMT    		--场外定投金额			
		     ,OTC_COVT_IN_AMT   		--场外转换入金额			
		     ,OTC_REDP_AMT      		--场外赎回金额			
		     ,OTC_COVT_OUT_AMT  		--场外转换出金额			
		     ,ITC_SUBS_SHAR     		--场内认购份额			
		     ,ITC_PURS_SHAR     		--场内申购份额			
		     ,ITC_BUYIN_SHAR    		--场内买入份额			
		     ,ITC_REDP_SHAR     		--场内赎回份额			
		     ,ITC_SELL_SHAR     		--场内卖出份额			
		     ,OTC_SUBS_SHAR     		--场外认购份额			
		     ,OTC_PURS_SHAR     		--场外申购份额			
		     ,OTC_CASTSL_SHAR   		--场外定投份额			
		     ,OTC_COVT_IN_SHAR  		--场外转换入份额			
		     ,OTC_REDP_SHAR     		--场外赎回份额			
		     ,OTC_COVT_OUT_SHAR 		--场外转换出份额			
		     ,ITC_SUBS_CHAG     		--场内认购手续费			
		     ,ITC_PURS_CHAG     		--场内申购手续费			
		     ,ITC_BUYIN_CHAG    		--场内买入手续费			
		     ,ITC_REDP_CHAG     		--场内赎回手续费			
		     ,ITC_SELL_CHAG     		--场内卖出手续费			
		     ,OTC_SUBS_CHAG     		--场外认购手续费			
		     ,OTC_PURS_CHAG     		--场外申购手续费			
		     ,OTC_CASTSL_CHAG   		--场外定投手续费			
		     ,OTC_COVT_IN_CHAG  		--场外转换入手续费			
		     ,OTC_REDP_CHAG     		--场外赎回手续费			
		     ,OTC_COVT_OUT_CHAG 		--场外转换出手续费			
		     ,CONTD_SALE_SHAR   		--续作销售份额			
		     ,CONTD_SALE_AMT    		--续作销售金额		
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              	--发生日期		
			,EMP_ID									AS    EMP_ID                	--员工编码	
			,PROD_CD           		 				AS    PROD_CD					--产品代码			
		    ,PROD_TYPE         						AS    PROD_TYPE					--产品类型			
			,SUM(ITC_RETAIN_AMT)    				AS    ITC_RETAIN_AMT   			--场内保有金额		
			,SUM(OTC_RETAIN_AMT)    				AS    OTC_RETAIN_AMT   			--场外保有金额		
			,SUM(ITC_RETAIN_SHAR)   				AS    ITC_RETAIN_SHAR  			--场内保有份额		
			,SUM(OTC_RETAIN_SHAR)  					AS    OTC_RETAIN_SHAR  			--场外保有份额		
			,SUM(ITC_SUBS_AMT)      				AS    ITC_SUBS_AMT     			--场内认购金额		
			,SUM(ITC_PURS_AMT)      				AS    ITC_PURS_AMT     			--场内申购金额		
			,SUM(ITC_BUYIN_AMT)     				AS    ITC_BUYIN_AMT    			--场内买入金额		
			,SUM(ITC_REDP_AMT)      				AS    ITC_REDP_AMT     			--场内赎回金额		
			,SUM(ITC_SELL_AMT)      				AS    ITC_SELL_AMT     			--场内卖出金额		
			,SUM(OTC_SUBS_AMT)      				AS    OTC_SUBS_AMT     			--场外认购金额		
			,SUM(OTC_PURS_AMT)      				AS    OTC_PURS_AMT     			--场外申购金额		
			,SUM(OTC_CASTSL_AMT)    				AS    OTC_CASTSL_AMT   			--场外定投金额		
			,SUM(OTC_COVT_IN_AMT)   				AS    OTC_COVT_IN_AMT  			--场外转换入金额	
			,SUM(OTC_REDP_AMT)      				AS    OTC_REDP_AMT     			--场外赎回金额		
			,SUM(OTC_COVT_OUT_AMT)  				AS    OTC_COVT_OUT_AMT 			--场外转换出金额	
			,SUM(ITC_SUBS_SHAR)     				AS    ITC_SUBS_SHAR    			--场内认购份额		
			,SUM(ITC_PURS_SHAR)     				AS    ITC_PURS_SHAR    			--场内申购份额		
			,SUM(ITC_BUYIN_SHAR)    				AS    ITC_BUYIN_SHAR   			--场内买入份额		
			,SUM(ITC_REDP_SHAR)     				AS    ITC_REDP_SHAR    			--场内赎回份额		
			,SUM(ITC_SELL_SHAR)     				AS    ITC_SELL_SHAR    			--场内卖出份额		
			,SUM(OTC_SUBS_SHAR)     				AS    OTC_SUBS_SHAR    			--场外认购份额		
			,SUM(OTC_PURS_SHAR)    					AS    OTC_PURS_SHAR    			--场外申购份额		
			,SUM(OTC_CASTSL_SHAR)   				AS    OTC_CASTSL_SHAR  			--场外定投份额		
			,SUM(OTC_COVT_IN_SHAR)  				AS    OTC_COVT_IN_SHAR 			--场外转换入份额	
			,SUM(OTC_REDP_SHAR)     				AS    OTC_REDP_SHAR    			--场外赎回份额		
			,SUM(OTC_COVT_OUT_SHAR) 				AS    OTC_COVT_OUT_SHAR			--场外转换出份额	
			,SUM(ITC_SUBS_CHAG)    					AS    ITC_SUBS_CHAG    			--场内认购手续费	
			,SUM(ITC_PURS_CHAG)     				AS    ITC_PURS_CHAG    			--场内申购手续费	
			,SUM(ITC_BUYIN_CHAG)    				AS    ITC_BUYIN_CHAG   			--场内买入手续费	
			,SUM(ITC_REDP_CHAG)     				AS    ITC_REDP_CHAG    			--场内赎回手续费	
			,SUM(ITC_SELL_CHAG)     				AS    ITC_SELL_CHAG    			--场内卖出手续费	
			,SUM(OTC_SUBS_CHAG)     				AS    OTC_SUBS_CHAG    			--场外认购手续费	
			,SUM(OTC_PURS_CHAG)     				AS    OTC_PURS_CHAG    			--场外申购手续费	
			,SUM(OTC_CASTSL_CHAG)   				AS    OTC_CASTSL_CHAG  			--场外定投手续费	
			,SUM(OTC_COVT_IN_CHAG)  				AS    OTC_COVT_IN_CHAG 			--场外转换入手续费	
			,SUM(OTC_REDP_CHAG)     				AS    OTC_REDP_CHAG    			--场外赎回手续费	
			,SUM(OTC_COVT_OUT_CHAG) 				AS    OTC_COVT_OUT_CHAG			--场外转换出手续费	
			,SUM(CONTD_SALE_SHAR)   				AS    CONTD_SALE_SHAR  			--续作销售份额		
			,SUM(CONTD_SALE_AMT)    				AS    CONTD_SALE_AMT   			--续作销售金额		
		FROM #TMP_T_EVT_PROD_TRD_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID,T.PROD_CD,T.PROD_TYPE;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部产品交易事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-04
  简介：产品交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
 	DECLARE @V_ACCU_MDAYS INT;		-- 月累计天数
 	DECLARE @V_ACCU_YDAYS INT;		-- 年累计天数
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_EVT_PROD_TRD_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_YEAR								AS    YEAR   					--年
		,@V_MONTH 								AS    MTH 						--月
		,BRH_ID									AS    BRH_ID                	--营业部编码	
		,PROD_CD								AS    PROD_CD					--产品代码 
		,PROD_TYPE 							    AS    PROD_TYPE 				--产品类别
		,@V_DATE 								AS    OCCUR_DT 		 			--发生日期
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_MDAYS 		AS	  ITC_RETAIN_AMT_MDA  		--场内保有金额_月日均
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_MDAYS  	AS 	  OTC_RETAIN_AMT_MDA  		--场外保有金额_月日均
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  ITC_RETAIN_SHAR_MDA 		--场内保有份额_月日均
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  OTC_RETAIN_SHAR_MDA 		--场外保有份额_月日均  
		,SUM(ITC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_M			--场外认购金额_本月
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_M			--场内申购金额_本月
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_M    		--场内买入金额_本月
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_M     		--场内赎回金额_本月
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_M     		--场内卖出金额_本月
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_M     		--场外申购金额_本月
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_M   		--场外定投金额_本月
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_M  		--场外转换入金额_本月
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_M     		--场外赎回金额_本月
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_M 		--场外转换出金额_本月
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_M    		--场内认购份额_本月
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_M    		--场内申购份额_本月
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_M   		--场内买入份额_本月
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_M    		--场内赎回份额_本月
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_M    		--场内卖出份额_本月
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_M    		--场外认购份额_本月
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_M    		--场外申购份额_本月
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_M 		--场外定投份额_本月
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_M 		--场外转换入份额_本月
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_M    		--场外赎回份额_本月
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_M		--场外转换出份额_本月
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_M    		--场内认购手续费_本月
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_M    		--场内申购手续费_本月
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_M   		--场内买入手续费_本月
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_M    		--场内赎回手续费_本月
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_M    		--场内卖出手续费_本月
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_M    		--场外认购手续费_本月
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_M    		--场外申购手续费_本月
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_M  		--场外定投手续费_本月
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_M 		--场外转换入手续费_本月
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_M    		--场外赎回手续费_本月
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_M		--场外转换出手续费_本月
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_M  		--续作销售份额_本月
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_M  		--续作销售金额_本月
	INTO #T_EVT_PROD_TRD_M_BRH_MTH
	FROM DM.T_EVT_PROD_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID,T.PROD_CD,T.PROD_TYPE;

	-- 统计年指标
	SELECT 
		 @V_YEAR								AS    YEAR   					--年
		,@V_MONTH 								AS    MTH 						--月
		,BRH_ID									AS    BRH_ID                	--营业部编码	
		,PROD_CD								AS    PROD_CD					--产品代码 
		,PROD_TYPE 							    AS    PROD_TYPE 				--产品类别
		,@V_DATE 								AS    OCCUR_DT 		 			--发生日期	
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_YDAYS 		AS	  ITC_RETAIN_AMT_YDA  		--场内保有金额_年日均
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_YDAYS  	AS 	  OTC_RETAIN_AMT_YDA  		--场外保有金额_年日均
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  ITC_RETAIN_SHAR_YDA 		--场内保有份额_年日均
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  OTC_RETAIN_SHAR_YDA 		--场外保有份额_年日均  
		,SUM(OTC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_TY			--场外认购金额_本年
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_TY			--场内申购金额_本年
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_TY    		--场内买入金额_本年
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_TY     		--场内赎回金额_本年
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_TY     		--场内卖出金额_本年
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_TY     		--场外申购金额_本年
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_TY   		--场外定投金额_本年
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_TY  		--场外转换入金额_本年
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_TY     		--场外赎回金额_本年
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_TY 		--场外转换出金额_本年
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_TY    		--场内认购份额_本年
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_TY    		--场内申购份额_本年
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_TY   		--场内买入份额_本年
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_TY    		--场内赎回份额_本年
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_TY    		--场内卖出份额_本年
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_TY    		--场外认购份额_本年
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_TY    		--场外申购份额_本年
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_TY		--场外定投份额_本年
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_TY 		--场外转换入份额_本年
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_TY    		--场外赎回份额_本年
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_TY		--场外转换出份额_本年
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_TY    		--场内认购手续费_本年
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_TY    		--场内申购手续费_本年
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_TY   		--场内买入手续费_本年
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_TY    		--场内赎回手续费_本年
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_TY    		--场内卖出手续费_本年
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_TY    		--场外认购手续费_本年
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_TY    		--场外申购手续费_本年
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_TY  		--场外定投手续费_本年
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_TY 		--场外转换入手续费_本年
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_TY    		--场外赎回手续费_本年
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_TY		--场外转换出手续费_本年
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_TY  		--续作销售份额_本年
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_TY  		--续作销售金额_本年
	INTO #T_EVT_PROD_TRD_M_BRH_YEAR
	FROM DM.T_EVT_PROD_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID,T.PROD_CD,T.PROD_TYPE;

	--插入目标表
	INSERT INTO DM.T_EVT_PROD_TRD_M_BRH(
		 YEAR                				--年
		,MTH                 				--月
		,BRH_ID              				--营业部编码
		,PROD_CD             				--产品代码
		,PROD_TYPE           				--产品类型
		,OCCUR_DT            				--发生日期
		,ITC_RETAIN_AMT_MDA  				--场内保有金额_月日均
		,OTC_RETAIN_AMT_MDA  				--场外保有金额_月日均
		,ITC_RETAIN_SHAR_MDA 				--场内保有份额_月日均
		,OTC_RETAIN_SHAR_MDA 				--场外保有份额_月日均  
		,ITC_RETAIN_AMT_YDA  				--场内保有金额_年日均
		,OTC_RETAIN_AMT_YDA  				--场外保有金额_年日均
		,ITC_RETAIN_SHAR_YDA 				--场内保有份额_年日均
		,OTC_RETAIN_SHAR_YDA 				--场外保有份额_年日均  
		,OTC_SUBS_AMT_M      				--场外认购金额_本月
		,ITC_PURS_AMT_M      				--场内申购金额_本月
		,ITC_BUYIN_AMT_M     				--场内买入金额_本月
		,ITC_REDP_AMT_M      				--场内赎回金额_本月
		,ITC_SELL_AMT_M      				--场内卖出金额_本月
		,OTC_PURS_AMT_M      				--场外申购金额_本月
		,OTC_CASTSL_AMT_M    				--场外定投金额_本月
		,OTC_COVT_IN_AMT_M   				--场外转换入金额_本月
		,OTC_REDP_AMT_M      				--场外赎回金额_本月
		,OTC_COVT_OUT_AMT_M  				--场外转换出金额_本月
		,ITC_SUBS_SHAR_M     				--场内认购份额_本月
		,ITC_PURS_SHAR_M     				--场内申购份额_本月
		,ITC_BUYIN_SHAR_M    				--场内买入份额_本月
		,ITC_REDP_SHAR_M     				--场内赎回份额_本月
		,ITC_SELL_SHAR_M     				--场内卖出份额_本月
		,OTC_SUBS_SHAR_M     				--场外认购份额_本月
		,OTC_PURS_SHAR_M     				--场外申购份额_本月
		,OTC_CASTSL_SHAR_M   				--场外定投份额_本月
		,OTC_COVT_IN_SHAR_M  				--场外转换入份额_本月
		,OTC_REDP_SHAR_M     				--场外赎回份额_本月
		,OTC_COVT_OUT_SHAR_M 				--场外转换出份额_本月
		,ITC_SUBS_CHAG_M     				--场内认购手续费_本月
		,ITC_PURS_CHAG_M     				--场内申购手续费_本月
		,ITC_BUYIN_CHAG_M    				--场内买入手续费_本月
		,ITC_REDP_CHAG_M     				--场内赎回手续费_本月
		,ITC_SELL_CHAG_M     				--场内卖出手续费_本月
		,OTC_SUBS_CHAG_M     				--场外认购手续费_本月
		,OTC_PURS_CHAG_M     				--场外申购手续费_本月
		,OTC_CASTSL_CHAG_M   				--场外定投手续费_本月
		,OTC_COVT_IN_CHAG_M  				--场外转换入手续费_本月
		,OTC_REDP_CHAG_M     				--场外赎回手续费_本月
		,OTC_COVT_OUT_CHAG_M 				--场外转换出手续费_本月
		,CONTD_SALE_SHAR_M   				--续作销售份额_本月
		,CONTD_SALE_AMT_M    				--续作销售金额_本月
		,OTC_SUBS_AMT_TY     				--场外认购金额_本年
		,ITC_PURS_AMT_TY     				--场内申购金额_本年
		,ITC_BUYIN_AMT_TY    				--场内买入金额_本年
		,ITC_REDP_AMT_TY     				--场内赎回金额_本年
		,ITC_SELL_AMT_TY     				--场内卖出金额_本年
		,OTC_PURS_AMT_TY     				--场外申购金额_本年
		,OTC_CASTSL_AMT_TY   				--场外定投金额_本年
		,OTC_COVT_IN_AMT_TY  				--场外转换入金额_本年
		,OTC_REDP_AMT_TY     				--场外赎回金额_本年
		,OTC_COVT_OUT_AMT_TY 				--场外转换出金额_本年
		,ITC_SUBS_SHAR_TY    				--场内认购份额_本年
		,ITC_PURS_SHAR_TY    				--场内申购份额_本年
		,ITC_BUYIN_SHAR_TY   				--场内买入份额_本年
		,ITC_REDP_SHAR_TY    				--场内赎回份额_本年
		,ITC_SELL_SHAR_TY    				--场内卖出份额_本年
		,OTC_SUBS_SHAR_TY    				--场外认购份额_本年
		,OTC_PURS_SHAR_TY    				--场外申购份额_本年
		,OTC_CASTSL_SHAR_TY  				--场外定投份额_本年
		,OTC_COVT_IN_SHAR_TY 				--场外转换入份额_本年
		,OTC_REDP_SHAR_TY    				--场外赎回份额_本年
		,OTC_COVT_OUT_SHAR_TY				--场外转换出份额_本年
		,ITC_SUBS_CHAG_TY    				--场内认购手续费_本年
		,ITC_PURS_CHAG_TY    				--场内申购手续费_本年
		,ITC_BUYIN_CHAG_TY   				--场内买入手续费_本年
		,ITC_REDP_CHAG_TY    				--场内赎回手续费_本年
		,ITC_SELL_CHAG_TY    				--场内卖出手续费_本年
		,OTC_SUBS_CHAG_TY    				--场外认购手续费_本年
		,OTC_PURS_CHAG_TY    				--场外申购手续费_本年
		,OTC_CASTSL_CHAG_TY  				--场外定投手续费_本年
		,OTC_COVT_IN_CHAG_TY 				--场外转换入手续费_本年
		,OTC_REDP_CHAG_TY    				--场外赎回手续费_本年
		,OTC_COVT_OUT_CHAG_TY				--场外转换出手续费_本年
		,CONTD_SALE_SHAR_TY  				--续作销售份额_本年
		,CONTD_SALE_AMT_TY   				--续作销售金额_本年
	)		
	SELECT 
		 T1.YEAR                        AS 		YEAR                	   --年
		,T1.MTH                         AS 		MTH                 	   --月
		,T1.BRH_ID                      AS 		BRH_ID              	   --营业部编码
		,T1.PROD_CD                     AS 		PROD_CD             	   --产品代码
		,T1.PROD_TYPE                   AS 		PROD_TYPE           	   --产品类型
		,T1.OCCUR_DT                    AS 		OCCUR_DT            	   --发生日期
		,T1.ITC_RETAIN_AMT_MDA          AS 		ITC_RETAIN_AMT_MDA  	   --场内保有金额_月日均
		,T1.OTC_RETAIN_AMT_MDA          AS 		OTC_RETAIN_AMT_MDA  	   --场外保有金额_月日均
		,T1.ITC_RETAIN_SHAR_MDA         AS 		ITC_RETAIN_SHAR_MDA 	   --场内保有份额_月日均
		,T1.OTC_RETAIN_SHAR_MDA         AS 		OTC_RETAIN_SHAR_MDA 	   --场外保有份额_月日均  
		,T2.ITC_RETAIN_AMT_YDA          AS 		ITC_RETAIN_AMT_YDA  	   --场内保有金额_年日均
		,T2.OTC_RETAIN_AMT_YDA          AS 		OTC_RETAIN_AMT_YDA  	   --场外保有金额_年日均
		,T2.ITC_RETAIN_SHAR_YDA         AS 		ITC_RETAIN_SHAR_YDA 	   --场内保有份额_年日均
		,T2.OTC_RETAIN_SHAR_YDA         AS 		OTC_RETAIN_SHAR_YDA 	   --场外保有份额_年日均  
		,T1.OTC_SUBS_AMT_M              AS 		OTC_SUBS_AMT_M      	   --场外认购金额_本月
		,T1.ITC_PURS_AMT_M              AS 		ITC_PURS_AMT_M      	   --场内申购金额_本月
		,T1.ITC_BUYIN_AMT_M             AS 		ITC_BUYIN_AMT_M     	   --场内买入金额_本月
		,T1.ITC_REDP_AMT_M              AS 		ITC_REDP_AMT_M      	   --场内赎回金额_本月
		,T1.ITC_SELL_AMT_M              AS 		ITC_SELL_AMT_M      	   --场内卖出金额_本月
		,T1.OTC_PURS_AMT_M              AS 		OTC_PURS_AMT_M      	   --场外申购金额_本月
		,T1.OTC_CASTSL_AMT_M            AS 		OTC_CASTSL_AMT_M    	   --场外定投金额_本月
		,T1.OTC_COVT_IN_AMT_M           AS 		OTC_COVT_IN_AMT_M   	   --场外转换入金额_本月
		,T1.OTC_REDP_AMT_M              AS 		OTC_REDP_AMT_M      	   --场外赎回金额_本月
		,T1.OTC_COVT_OUT_AMT_M          AS 		OTC_COVT_OUT_AMT_M  	   --场外转换出金额_本月
		,T1.ITC_SUBS_SHAR_M             AS 		ITC_SUBS_SHAR_M     	   --场内认购份额_本月
		,T1.ITC_PURS_SHAR_M             AS 		ITC_PURS_SHAR_M     	   --场内申购份额_本月
		,T1.ITC_BUYIN_SHAR_M            AS 		ITC_BUYIN_SHAR_M    	   --场内买入份额_本月
		,T1.ITC_REDP_SHAR_M             AS 		ITC_REDP_SHAR_M     	   --场内赎回份额_本月
		,T1.ITC_SELL_SHAR_M             AS 		ITC_SELL_SHAR_M     	   --场内卖出份额_本月
		,T1.OTC_SUBS_SHAR_M             AS 		OTC_SUBS_SHAR_M     	   --场外认购份额_本月
		,T1.OTC_PURS_SHAR_M             AS 		OTC_PURS_SHAR_M     	   --场外申购份额_本月
		,T1.OTC_CASTSL_SHAR_M           AS 		OTC_CASTSL_SHAR_M   	   --场外定投份额_本月
		,T1.OTC_COVT_IN_SHAR_M          AS 		OTC_COVT_IN_SHAR_M  	   --场外转换入份额_本月
		,T1.OTC_REDP_SHAR_M             AS 		OTC_REDP_SHAR_M     	   --场外赎回份额_本月
		,T1.OTC_COVT_OUT_SHAR_M         AS 		OTC_COVT_OUT_SHAR_M 	   --场外转换出份额_本月
		,T1.ITC_SUBS_CHAG_M             AS 		ITC_SUBS_CHAG_M     	   --场内认购手续费_本月
		,T1.ITC_PURS_CHAG_M             AS 		ITC_PURS_CHAG_M     	   --场内申购手续费_本月
		,T1.ITC_BUYIN_CHAG_M            AS 		ITC_BUYIN_CHAG_M    	   --场内买入手续费_本月
		,T1.ITC_REDP_CHAG_M             AS 		ITC_REDP_CHAG_M     	   --场内赎回手续费_本月
		,T1.ITC_SELL_CHAG_M             AS 		ITC_SELL_CHAG_M     	   --场内卖出手续费_本月
		,T1.OTC_SUBS_CHAG_M             AS 		OTC_SUBS_CHAG_M     	   --场外认购手续费_本月
		,T1.OTC_PURS_CHAG_M             AS 		OTC_PURS_CHAG_M     	   --场外申购手续费_本月
		,T1.OTC_CASTSL_CHAG_M           AS 		OTC_CASTSL_CHAG_M   	   --场外定投手续费_本月
		,T1.OTC_COVT_IN_CHAG_M          AS 		OTC_COVT_IN_CHAG_M  	   --场外转换入手续费_本月
		,T1.OTC_REDP_CHAG_M             AS 		OTC_REDP_CHAG_M     	   --场外赎回手续费_本月
		,T1.OTC_COVT_OUT_CHAG_M         AS 		OTC_COVT_OUT_CHAG_M 	   --场外转换出手续费_本月
		,T1.CONTD_SALE_SHAR_M           AS 		CONTD_SALE_SHAR_M   	   --续作销售份额_本月
		,T1.CONTD_SALE_AMT_M            AS 		CONTD_SALE_AMT_M    	   --续作销售金额_本月
		,T2.OTC_SUBS_AMT_TY             AS 		OTC_SUBS_AMT_TY     	   --场外认购金额_本年
		,T2.ITC_PURS_AMT_TY             AS 		ITC_PURS_AMT_TY     	   --场内申购金额_本年
		,T2.ITC_BUYIN_AMT_TY            AS 		ITC_BUYIN_AMT_TY    	   --场内买入金额_本年
		,T2.ITC_REDP_AMT_TY             AS 		ITC_REDP_AMT_TY     	   --场内赎回金额_本年
		,T2.ITC_SELL_AMT_TY             AS 		ITC_SELL_AMT_TY     	   --场内卖出金额_本年
		,T2.OTC_PURS_AMT_TY             AS 		OTC_PURS_AMT_TY     	   --场外申购金额_本年
		,T2.OTC_CASTSL_AMT_TY           AS 		OTC_CASTSL_AMT_TY   	   --场外定投金额_本年
		,T2.OTC_COVT_IN_AMT_TY          AS 		OTC_COVT_IN_AMT_TY  	   --场外转换入金额_本年
		,T2.OTC_REDP_AMT_TY             AS 		OTC_REDP_AMT_TY     	   --场外赎回金额_本年
		,T2.OTC_COVT_OUT_AMT_TY         AS 		OTC_COVT_OUT_AMT_TY 	   --场外转换出金额_本年
		,T2.ITC_SUBS_SHAR_TY            AS 		ITC_SUBS_SHAR_TY    	   --场内认购份额_本年
		,T2.ITC_PURS_SHAR_TY            AS 		ITC_PURS_SHAR_TY    	   --场内申购份额_本年
		,T2.ITC_BUYIN_SHAR_TY           AS 		ITC_BUYIN_SHAR_TY   	   --场内买入份额_本年
		,T2.ITC_REDP_SHAR_TY            AS 		ITC_REDP_SHAR_TY    	   --场内赎回份额_本年
		,T2.ITC_SELL_SHAR_TY            AS 		ITC_SELL_SHAR_TY    	   --场内卖出份额_本年
		,T2.OTC_SUBS_SHAR_TY            AS 		OTC_SUBS_SHAR_TY    	   --场外认购份额_本年
		,T2.OTC_PURS_SHAR_TY            AS 		OTC_PURS_SHAR_TY    	   --场外申购份额_本年
		,T2.OTC_CASTSL_SHAR_TY          AS 		OTC_CASTSL_SHAR_TY  	   --场外定投份额_本年
		,T2.OTC_COVT_IN_SHAR_TY         AS 		OTC_COVT_IN_SHAR_TY 	   --场外转换入份额_本年
		,T2.OTC_REDP_SHAR_TY            AS 		OTC_REDP_SHAR_TY    	   --场外赎回份额_本年
		,T2.OTC_COVT_OUT_SHAR_TY        AS 		OTC_COVT_OUT_SHAR_TY	   --场外转换出份额_本年
		,T2.ITC_SUBS_CHAG_TY            AS 		ITC_SUBS_CHAG_TY    	   --场内认购手续费_本年
		,T2.ITC_PURS_CHAG_TY            AS 		ITC_PURS_CHAG_TY    	   --场内申购手续费_本年
		,T2.ITC_BUYIN_CHAG_TY           AS 		ITC_BUYIN_CHAG_TY   	   --场内买入手续费_本年
		,T2.ITC_REDP_CHAG_TY            AS 		ITC_REDP_CHAG_TY    	   --场内赎回手续费_本年
		,T2.ITC_SELL_CHAG_TY            AS 		ITC_SELL_CHAG_TY    	   --场内卖出手续费_本年
		,T2.OTC_SUBS_CHAG_TY            AS 		OTC_SUBS_CHAG_TY    	   --场外认购手续费_本年
		,T2.OTC_PURS_CHAG_TY            AS 		OTC_PURS_CHAG_TY    	   --场外申购手续费_本年
		,T2.OTC_CASTSL_CHAG_TY          AS 		OTC_CASTSL_CHAG_TY  	   --场外定投手续费_本年
		,T2.OTC_COVT_IN_CHAG_TY         AS 		OTC_COVT_IN_CHAG_TY 	   --场外转换入手续费_本年
		,T2.OTC_REDP_CHAG_TY            AS 		OTC_REDP_CHAG_TY    	   --场外赎回手续费_本年
		,T2.OTC_COVT_OUT_CHAG_TY        AS 		OTC_COVT_OUT_CHAG_TY	   --场外转换出手续费_本年
		,T2.CONTD_SALE_SHAR_TY          AS 		CONTD_SALE_SHAR_TY  	   --续作销售份额_本年
		,T2.CONTD_SALE_AMT_TY           AS 		CONTD_SALE_AMT_TY   	   --续作销售金额_本年
	FROM #T_EVT_PROD_TRD_M_BRH_MTH T1,#T_EVT_PROD_TRD_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID 
		AND T1.PROD_CD = T2.PROD_CD
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建产品交易事实月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：产品交易事实月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
              20180321                 dcy                新增年月产品代码+4个续作变量
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --自然日_月末
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --交易日_月初
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --交易日_月末
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --交易日_年初
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --自然天数_月
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --交易天数_月
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --自然天数_年
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --交易天数_年


    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 删除当月数据
  DELETE FROM DM.T_EVT_PROD_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_EVT_PROD_TRD_M_D 
	(
	CUST_ID
	,PROD_CD
	,PROD_TYPE
	,YEAR
	,MTH
	,OCCUR_DT
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,YEAR_MTH_PROD_CD
	,YEAR_MTH_CUST_ID_PROD_CD
	,ITC_RETAIN_AMT_FINAL
	,OTC_RETAIN_AMT_FINAL
	,ITC_RETAIN_SHAR_FINAL
	,OTC_RETAIN_SHAR_FINAL
	,ITC_RETAIN_AMT_MDA
	,OTC_RETAIN_AMT_MDA
	,ITC_RETAIN_SHAR_MDA
	,OTC_RETAIN_SHAR_MDA
	,ITC_RETAIN_AMT_YDA
	,OTC_RETAIN_AMT_YDA
	,ITC_RETAIN_SHAR_YDA
	,OTC_RETAIN_SHAR_YDA
	,ITC_SUBS_AMT_MTD
	,ITC_PURS_AMT_MTD
	,ITC_BUYIN_AMT_MTD
	,ITC_REDP_AMT_MTD
	,ITC_SELL_AMT_MTD
	,OTC_SUBS_AMT_MTD
	,OTC_PURS_AMT_MTD
	,OTC_CASTSL_AMT_MTD
	,OTC_COVT_IN_AMT_MTD
	,OTC_REDP_AMT_MTD
	,OTC_COVT_OUT_AMT_MTD
	,ITC_SUBS_SHAR_MTD
	,ITC_PURS_SHAR_MTD
	,ITC_BUYIN_SHAR_MTD
	,ITC_REDP_SHAR_MTD
	,ITC_SELL_SHAR_MTD
	,OTC_SUBS_SHAR_MTD
	,OTC_PURS_SHAR_MTD
	,OTC_CASTSL_SHAR_MTD
	,OTC_COVT_IN_SHAR_MTD
	,OTC_REDP_SHAR_MTD
	,OTC_COVT_OUT_SHAR_MTD
	,ITC_SUBS_CHAG_MTD
	,ITC_PURS_CHAG_MTD
	,ITC_BUYIN_CHAG_MTD
	,ITC_REDP_CHAG_MTD
	,ITC_SELL_CHAG_MTD
	,OTC_SUBS_CHAG_MTD
	,OTC_PURS_CHAG_MTD
	,OTC_CASTSL_CHAG_MTD
	,OTC_COVT_IN_CHAG_MTD
	,OTC_REDP_CHAG_MTD
	,OTC_COVT_OUT_CHAG_MTD
	,ITC_SUBS_AMT_YTD
	,ITC_PURS_AMT_YTD
	,ITC_BUYIN_AMT_YTD
	,ITC_REDP_AMT_YTD
	,ITC_SELL_AMT_YTD
	,OTC_SUBS_AMT_YTD
	,OTC_PURS_AMT_YTD
	,OTC_CASTSL_AMT_YTD
	,OTC_COVT_IN_AMT_YTD
	,OTC_REDP_AMT_YTD
	,OTC_COVT_OUT_AMT_YTD
	,ITC_SUBS_SHAR_YTD
	,ITC_PURS_SHAR_YTD
	,ITC_BUYIN_SHAR_YTD
	,ITC_REDP_SHAR_YTD
	,ITC_SELL_SHAR_YTD
	,OTC_SUBS_SHAR_YTD
	,OTC_PURS_SHAR_YTD
	,OTC_CASTSL_SHAR_YTD
	,OTC_COVT_IN_SHAR_YTD
	,OTC_REDP_SHAR_YTD
	,OTC_COVT_OUT_SHAR_YTD
	,ITC_SUBS_CHAG_YTD
	,ITC_PURS_CHAG_YTD
	,ITC_BUYIN_CHAG_YTD
	,ITC_REDP_CHAG_YTD
	,ITC_SELL_CHAG_YTD
	,OTC_SUBS_CHAG_YTD
	,OTC_PURS_CHAG_YTD
	,OTC_CASTSL_CHAG_YTD
	,OTC_COVT_IN_CHAG_YTD
	,OTC_REDP_CHAG_YTD
	,OTC_COVT_OUT_CHAG_YTD
	,CONTD_SALE_SHAR_MTD
	,CONTD_SALE_AMT_MTD 
	,CONTD_SALE_SHAR_YTD
	,CONTD_SALE_AMT_YTD 
	,LOAD_DT
	)
	select
	t1.CUST_ID as 客户编码
	,t1.PROD_CD as 产品代码
	,t1.PROD_TYPE as 产品类型
	,t_rq.年
	,t_rq.月
	,@V_BIN_DATE AS OCCUR_DT
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码
	,t_rq.年||t_rq.月||t1.PROD_CD as 年月产品代码
	,t_rq.年||t_rq.月||t1.CUST_ID||t1.PROD_CD as 年月客户编码产品代码
	
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.ITC_RETAIN_AMT,0) else 0 end) as 场内保有金额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTC_RETAIN_AMT,0) else 0 end) as 场外保有金额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.ITC_RETAIN_SHAR,0) else 0 end) as 场内保有份额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTC_RETAIN_SHAR,0) else 0 end) as 场外保有份额_期末

	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.ITC_RETAIN_AMT,0) else 0 end)/t_rq.自然天数_月 as 场内保有金额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTC_RETAIN_AMT,0) else 0 end)/t_rq.自然天数_月 as 场外保有金额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.ITC_RETAIN_SHAR,0) else 0 end)/t_rq.自然天数_月 as 场内保有份额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTC_RETAIN_SHAR,0) else 0 end)/t_rq.自然天数_月 as 场外保有份额_月日均

	,sum(COALESCE(t1.ITC_RETAIN_AMT,0))/t_rq.自然天数_年 as 场内保有金额_年日均
	,sum(COALESCE(t1.OTC_RETAIN_AMT,0))/t_rq.自然天数_年 as 场外保有金额_年日均
	,sum(COALESCE(t1.ITC_RETAIN_SHAR,0))/t_rq.自然天数_年 as 场内保有份额_年日均
	,sum(COALESCE(t1.OTC_RETAIN_SHAR,0))/t_rq.自然天数_年 as 场外保有份额_年日均

	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_AMT,0) else 0 end) as 场内认购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_AMT,0) else 0 end) as 场内申购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_AMT,0) else 0 end) as 场内买入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_AMT,0) else 0 end) as 场内赎回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_AMT,0) else 0 end) as 场内卖出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_AMT,0) else 0 end) as 场外认购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_AMT,0) else 0 end) as 场外申购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_AMT,0) else 0 end) as 场外定投金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_AMT,0) else 0 end) as 场外转换入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_AMT,0) else 0 end) as 场外赎回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_AMT,0) else 0 end) as 场外转换出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_SHAR,0) else 0 end) as 场内认购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_SHAR,0) else 0 end) as 场内申购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_SHAR,0) else 0 end) as 场内买入份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_SHAR,0) else 0 end) as 场内赎回份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_SHAR,0) else 0 end) as 场内卖出份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_SHAR,0) else 0 end) as 场外认购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_SHAR,0) else 0 end) as 场外申购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_SHAR,0) else 0 end) as 场外定投份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_SHAR,0) else 0 end) as 场外转换入份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_SHAR,0) else 0 end) as 场外赎回份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_SHAR,0) else 0 end) as 场外转换出份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_CHAG,0) else 0 end) as 场内认购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_CHAG,0) else 0 end) as 场内申购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_CHAG,0) else 0 end) as 场内买入手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_CHAG,0) else 0 end) as 场内赎回手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_CHAG,0) else 0 end) as 场内卖出手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_CHAG,0) else 0 end) as 场外认购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_CHAG,0) else 0 end) as 场外申购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_CHAG,0) else 0 end) as 场外定投手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_CHAG,0) else 0 end) as 场外转换入手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_CHAG,0) else 0 end) as 场外赎回手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_CHAG,0) else 0 end) as 场外转换出手续费_月累计

	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_AMT,0) else 0 end) as 场内认购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_AMT,0) else 0 end) as 场内申购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_AMT,0) else 0 end) as 场内买入金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_AMT,0) else 0 end) as 场内赎回金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_AMT,0) else 0 end) as 场内卖出金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_AMT,0) else 0 end) as 场外认购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_AMT,0) else 0 end) as 场外申购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_AMT,0) else 0 end) as 场外定投金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_AMT,0) else 0 end) as 场外转换入金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_AMT,0) else 0 end) as 场外赎回金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_AMT,0) else 0 end) as 场外转换出金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_SHAR,0) else 0 end) as 场内认购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_SHAR,0) else 0 end) as 场内申购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_SHAR,0) else 0 end) as 场内买入份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_SHAR,0) else 0 end) as 场内赎回份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_SHAR,0) else 0 end) as 场内卖出份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_SHAR,0) else 0 end) as 场外认购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_SHAR,0) else 0 end) as 场外申购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_SHAR,0) else 0 end) as 场外定投份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_SHAR,0) else 0 end) as 场外转换入份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_SHAR,0) else 0 end) as 场外赎回份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_SHAR,0) else 0 end) as 场外转换出份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_CHAG,0) else 0 end) as 场内认购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_CHAG,0) else 0 end) as 场内申购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_CHAG,0) else 0 end) as 场内买入手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_CHAG,0) else 0 end) as 场内赎回手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_CHAG,0) else 0 end) as 场内卖出手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_CHAG,0) else 0 end) as 场外认购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_CHAG,0) else 0 end) as 场外申购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_CHAG,0) else 0 end) as 场外定投手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_CHAG,0) else 0 end) as 场外转换入手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_CHAG,0) else 0 end) as 场外赎回手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_CHAG,0) else 0 end) as 场外转换出手续费_年累计
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_SHAR,0) else 0 end) as 续作销售份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_AMT,0) else 0 end) as 续作销售金额_月累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_SHAR,0) else 0 end) as 续作销售份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_AMT,0) else 0 end) as 续作销售金额_年累计
	
	,@V_BIN_DATE
from
(
	select
		@V_BIN_YEAR as 年
		,@V_BIN_MTH as 月
		,t1.DT      as 日期
		,t1.TRD_DT  as 交易日期
		,t1.if_trd_day_flag         as 是否交易日
		,@V_BIN_NATRE_DAY_MTHBEG    as 自然日_月初
		,@V_BIN_NATRE_DAY_MTHEND    as 自然日_月末
		,@V_BIN_TRD_DAY_MTHBEG      as 交易日_月初
		,@V_BIN_TRD_DAY_MTHEND      as 交易日_月末
		,@V_BIN_NATRE_DAY_YEARBGN   as 自然日_年初
		,@V_BIN_TRD_DAY_YEARBGN     as 交易日_年初
		,@V_BIN_NATRE_DAYS_MTH      as 自然天数_月
		,@V_BIN_TRD_DAYS_MTH        as 交易天数_月
		,@V_BIN_NATRE_DAYS_YEAR     as 自然天数_年
		,@V_BIN_TRD_DAYS_YEAR       as 交易天数_年
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE 
) t_rq
--市值保有需填充节假日数据
left join DM.T_EVT_PROD_TRD_D_D t1 on t_rq.交易日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t1.CUST_ID
	,t1.PROD_CD
	,t1.PROD_TYPE
;

END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_M_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_M_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工产品交易事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-04
  简介：产品交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
 	DECLARE @V_ACCU_MDAYS INT;		-- 月累计天数
 	DECLARE @V_ACCU_YDAYS INT;		-- 年累计天数
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_EVT_PROD_TRD_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_YEAR								AS    YEAR   					--年
		,@V_MONTH 								AS    MTH 						--月
		,EMP_ID									AS    EMP_ID                	--员工编码	
		,PROD_CD								AS    PROD_CD					--产品代码 
		,PROD_TYPE 							    AS    PROD_TYPE 				--产品类别
		,@V_DATE 								AS    OCCUR_DT 		 			--发生日期
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_MDAYS 		AS	  ITC_RETAIN_AMT_MDA  		--场内保有金额_月日均
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_MDAYS  	AS 	  OTC_RETAIN_AMT_MDA  		--场外保有金额_月日均
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  ITC_RETAIN_SHAR_MDA 		--场内保有份额_月日均
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  OTC_RETAIN_SHAR_MDA 		--场外保有份额_月日均  
		,SUM(ITC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_M			--场外认购金额_本月
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_M			--场内申购金额_本月
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_M    		--场内买入金额_本月
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_M     		--场内赎回金额_本月
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_M     		--场内卖出金额_本月
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_M     		--场外申购金额_本月
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_M   		--场外定投金额_本月
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_M  		--场外转换入金额_本月
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_M     		--场外赎回金额_本月
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_M 		--场外转换出金额_本月
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_M    		--场内认购份额_本月
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_M    		--场内申购份额_本月
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_M   		--场内买入份额_本月
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_M    		--场内赎回份额_本月
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_M    		--场内卖出份额_本月
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_M    		--场外认购份额_本月
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_M    		--场外申购份额_本月
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_M 		--场外定投份额_本月
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_M 		--场外转换入份额_本月
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_M    		--场外赎回份额_本月
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_M		--场外转换出份额_本月
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_M    		--场内认购手续费_本月
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_M    		--场内申购手续费_本月
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_M   		--场内买入手续费_本月
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_M    		--场内赎回手续费_本月
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_M    		--场内卖出手续费_本月
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_M    		--场外认购手续费_本月
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_M    		--场外申购手续费_本月
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_M  		--场外定投手续费_本月
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_M 		--场外转换入手续费_本月
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_M    		--场外赎回手续费_本月
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_M		--场外转换出手续费_本月
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_M  		--续作销售份额_本月
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_M  		--续作销售金额_本月
	INTO #T_EVT_PROD_TRD_D_EMP_MTH
	FROM DM.T_EVT_PROD_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID,T.PROD_CD,T.PROD_TYPE;

	-- 统计年指标
	SELECT 
		 @V_YEAR								AS    YEAR   					--年
		,@V_MONTH 								AS    MTH 						--月
		,EMP_ID									AS    EMP_ID                	--员工编码
		,PROD_CD								AS    PROD_CD					--产品代码 
		,PROD_TYPE 							    AS    PROD_TYPE 				--产品类别
		,@V_DATE 								AS    OCCUR_DT 		 			--发生日期	
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_YDAYS 		AS	  ITC_RETAIN_AMT_YDA  		--场内保有金额_年日均
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_YDAYS  	AS 	  OTC_RETAIN_AMT_YDA  		--场外保有金额_年日均
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  ITC_RETAIN_SHAR_YDA 		--场内保有份额_年日均
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  OTC_RETAIN_SHAR_YDA 		--场外保有份额_年日均  
		,SUM(OTC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_TY			--场外认购金额_本年
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_TY			--场内申购金额_本年
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_TY    		--场内买入金额_本年
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_TY     		--场内赎回金额_本年
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_TY     		--场内卖出金额_本年
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_TY     		--场外申购金额_本年
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_TY   		--场外定投金额_本年
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_TY  		--场外转换入金额_本年
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_TY     		--场外赎回金额_本年
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_TY 		--场外转换出金额_本年
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_TY    		--场内认购份额_本年
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_TY    		--场内申购份额_本年
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_TY   		--场内买入份额_本年
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_TY    		--场内赎回份额_本年
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_TY    		--场内卖出份额_本年
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_TY    		--场外认购份额_本年
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_TY    		--场外申购份额_本年
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_TY		--场外定投份额_本年
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_TY 		--场外转换入份额_本年
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_TY    		--场外赎回份额_本年
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_TY		--场外转换出份额_本年
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_TY    		--场内认购手续费_本年
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_TY    		--场内申购手续费_本年
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_TY   		--场内买入手续费_本年
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_TY    		--场内赎回手续费_本年
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_TY    		--场内卖出手续费_本年
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_TY    		--场外认购手续费_本年
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_TY    		--场外申购手续费_本年
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_TY  		--场外定投手续费_本年
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_TY 		--场外转换入手续费_本年
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_TY    		--场外赎回手续费_本年
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_TY		--场外转换出手续费_本年
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_TY  		--续作销售份额_本年
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_TY  		--续作销售金额_本年
	INTO #T_EVT_PROD_TRD_D_EMP_YEAR
	FROM DM.T_EVT_PROD_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID,T.PROD_CD,T.PROD_TYPE;

	--插入目标表
	INSERT INTO DM.T_EVT_PROD_TRD_M_EMP(
		 YEAR                				--年
		,MTH                 				--月
		,EMP_ID              				--员工编码
		,PROD_CD             				--产品代码
		,PROD_TYPE           				--产品类型
		,OCCUR_DT            				--发生日期
		,ITC_RETAIN_AMT_MDA  				--场内保有金额_月日均
		,OTC_RETAIN_AMT_MDA  				--场外保有金额_月日均
		,ITC_RETAIN_SHAR_MDA 				--场内保有份额_月日均
		,OTC_RETAIN_SHAR_MDA 				--场外保有份额_月日均  
		,ITC_RETAIN_AMT_YDA  				--场内保有金额_年日均
		,OTC_RETAIN_AMT_YDA  				--场外保有金额_年日均
		,ITC_RETAIN_SHAR_YDA 				--场内保有份额_年日均
		,OTC_RETAIN_SHAR_YDA 				--场外保有份额_年日均  
		,OTC_SUBS_AMT_M      				--场外认购金额_本月
		,ITC_PURS_AMT_M      				--场内申购金额_本月
		,ITC_BUYIN_AMT_M     				--场内买入金额_本月
		,ITC_REDP_AMT_M      				--场内赎回金额_本月
		,ITC_SELL_AMT_M      				--场内卖出金额_本月
		,OTC_PURS_AMT_M      				--场外申购金额_本月
		,OTC_CASTSL_AMT_M    				--场外定投金额_本月
		,OTC_COVT_IN_AMT_M   				--场外转换入金额_本月
		,OTC_REDP_AMT_M      				--场外赎回金额_本月
		,OTC_COVT_OUT_AMT_M  				--场外转换出金额_本月
		,ITC_SUBS_SHAR_M     				--场内认购份额_本月
		,ITC_PURS_SHAR_M     				--场内申购份额_本月
		,ITC_BUYIN_SHAR_M    				--场内买入份额_本月
		,ITC_REDP_SHAR_M     				--场内赎回份额_本月
		,ITC_SELL_SHAR_M     				--场内卖出份额_本月
		,OTC_SUBS_SHAR_M     				--场外认购份额_本月
		,OTC_PURS_SHAR_M     				--场外申购份额_本月
		,OTC_CASTSL_SHAR_M   				--场外定投份额_本月
		,OTC_COVT_IN_SHAR_M  				--场外转换入份额_本月
		,OTC_REDP_SHAR_M     				--场外赎回份额_本月
		,OTC_COVT_OUT_SHAR_M 				--场外转换出份额_本月
		,ITC_SUBS_CHAG_M     				--场内认购手续费_本月
		,ITC_PURS_CHAG_M     				--场内申购手续费_本月
		,ITC_BUYIN_CHAG_M    				--场内买入手续费_本月
		,ITC_REDP_CHAG_M     				--场内赎回手续费_本月
		,ITC_SELL_CHAG_M     				--场内卖出手续费_本月
		,OTC_SUBS_CHAG_M     				--场外认购手续费_本月
		,OTC_PURS_CHAG_M     				--场外申购手续费_本月
		,OTC_CASTSL_CHAG_M   				--场外定投手续费_本月
		,OTC_COVT_IN_CHAG_M  				--场外转换入手续费_本月
		,OTC_REDP_CHAG_M     				--场外赎回手续费_本月
		,OTC_COVT_OUT_CHAG_M 				--场外转换出手续费_本月
		,CONTD_SALE_SHAR_M   				--续作销售份额_本月
		,CONTD_SALE_AMT_M    				--续作销售金额_本月
		,OTC_SUBS_AMT_TY     				--场外认购金额_本年
		,ITC_PURS_AMT_TY     				--场内申购金额_本年
		,ITC_BUYIN_AMT_TY    				--场内买入金额_本年
		,ITC_REDP_AMT_TY     				--场内赎回金额_本年
		,ITC_SELL_AMT_TY     				--场内卖出金额_本年
		,OTC_PURS_AMT_TY     				--场外申购金额_本年
		,OTC_CASTSL_AMT_TY   				--场外定投金额_本年
		,OTC_COVT_IN_AMT_TY  				--场外转换入金额_本年
		,OTC_REDP_AMT_TY     				--场外赎回金额_本年
		,OTC_COVT_OUT_AMT_TY 				--场外转换出金额_本年
		,ITC_SUBS_SHAR_TY    				--场内认购份额_本年
		,ITC_PURS_SHAR_TY    				--场内申购份额_本年
		,ITC_BUYIN_SHAR_TY   				--场内买入份额_本年
		,ITC_REDP_SHAR_TY    				--场内赎回份额_本年
		,ITC_SELL_SHAR_TY    				--场内卖出份额_本年
		,OTC_SUBS_SHAR_TY    				--场外认购份额_本年
		,OTC_PURS_SHAR_TY    				--场外申购份额_本年
		,OTC_CASTSL_SHAR_TY  				--场外定投份额_本年
		,OTC_COVT_IN_SHAR_TY 				--场外转换入份额_本年
		,OTC_REDP_SHAR_TY    				--场外赎回份额_本年
		,OTC_COVT_OUT_SHAR_TY				--场外转换出份额_本年
		,ITC_SUBS_CHAG_TY    				--场内认购手续费_本年
		,ITC_PURS_CHAG_TY    				--场内申购手续费_本年
		,ITC_BUYIN_CHAG_TY   				--场内买入手续费_本年
		,ITC_REDP_CHAG_TY    				--场内赎回手续费_本年
		,ITC_SELL_CHAG_TY    				--场内卖出手续费_本年
		,OTC_SUBS_CHAG_TY    				--场外认购手续费_本年
		,OTC_PURS_CHAG_TY    				--场外申购手续费_本年
		,OTC_CASTSL_CHAG_TY  				--场外定投手续费_本年
		,OTC_COVT_IN_CHAG_TY 				--场外转换入手续费_本年
		,OTC_REDP_CHAG_TY    				--场外赎回手续费_本年
		,OTC_COVT_OUT_CHAG_TY				--场外转换出手续费_本年
		,CONTD_SALE_SHAR_TY  				--续作销售份额_本年
		,CONTD_SALE_AMT_TY   				--续作销售金额_本年
	)		
	SELECT 
		 T1.YEAR                        AS 		YEAR                	   --年
		,T1.MTH                         AS 		MTH                 	   --月
		,T1.EMP_ID                      AS 		EMP_ID              	   --员工编码
		,T1.PROD_CD                     AS 		PROD_CD             	   --产品代码
		,T1.PROD_TYPE                   AS 		PROD_TYPE           	   --产品类型
		,T1.OCCUR_DT                    AS 		OCCUR_DT            	   --发生日期
		,T1.ITC_RETAIN_AMT_MDA          AS 		ITC_RETAIN_AMT_MDA  	   --场内保有金额_月日均
		,T1.OTC_RETAIN_AMT_MDA          AS 		OTC_RETAIN_AMT_MDA  	   --场外保有金额_月日均
		,T1.ITC_RETAIN_SHAR_MDA         AS 		ITC_RETAIN_SHAR_MDA 	   --场内保有份额_月日均
		,T1.OTC_RETAIN_SHAR_MDA         AS 		OTC_RETAIN_SHAR_MDA 	   --场外保有份额_月日均  
		,T2.ITC_RETAIN_AMT_YDA          AS 		ITC_RETAIN_AMT_YDA  	   --场内保有金额_年日均
		,T2.OTC_RETAIN_AMT_YDA          AS 		OTC_RETAIN_AMT_YDA  	   --场外保有金额_年日均
		,T2.ITC_RETAIN_SHAR_YDA         AS 		ITC_RETAIN_SHAR_YDA 	   --场内保有份额_年日均
		,T2.OTC_RETAIN_SHAR_YDA         AS 		OTC_RETAIN_SHAR_YDA 	   --场外保有份额_年日均  
		,T1.OTC_SUBS_AMT_M              AS 		OTC_SUBS_AMT_M      	   --场外认购金额_本月
		,T1.ITC_PURS_AMT_M              AS 		ITC_PURS_AMT_M      	   --场内申购金额_本月
		,T1.ITC_BUYIN_AMT_M             AS 		ITC_BUYIN_AMT_M     	   --场内买入金额_本月
		,T1.ITC_REDP_AMT_M              AS 		ITC_REDP_AMT_M      	   --场内赎回金额_本月
		,T1.ITC_SELL_AMT_M              AS 		ITC_SELL_AMT_M      	   --场内卖出金额_本月
		,T1.OTC_PURS_AMT_M              AS 		OTC_PURS_AMT_M      	   --场外申购金额_本月
		,T1.OTC_CASTSL_AMT_M            AS 		OTC_CASTSL_AMT_M    	   --场外定投金额_本月
		,T1.OTC_COVT_IN_AMT_M           AS 		OTC_COVT_IN_AMT_M   	   --场外转换入金额_本月
		,T1.OTC_REDP_AMT_M              AS 		OTC_REDP_AMT_M      	   --场外赎回金额_本月
		,T1.OTC_COVT_OUT_AMT_M          AS 		OTC_COVT_OUT_AMT_M  	   --场外转换出金额_本月
		,T1.ITC_SUBS_SHAR_M             AS 		ITC_SUBS_SHAR_M     	   --场内认购份额_本月
		,T1.ITC_PURS_SHAR_M             AS 		ITC_PURS_SHAR_M     	   --场内申购份额_本月
		,T1.ITC_BUYIN_SHAR_M            AS 		ITC_BUYIN_SHAR_M    	   --场内买入份额_本月
		,T1.ITC_REDP_SHAR_M             AS 		ITC_REDP_SHAR_M     	   --场内赎回份额_本月
		,T1.ITC_SELL_SHAR_M             AS 		ITC_SELL_SHAR_M     	   --场内卖出份额_本月
		,T1.OTC_SUBS_SHAR_M             AS 		OTC_SUBS_SHAR_M     	   --场外认购份额_本月
		,T1.OTC_PURS_SHAR_M             AS 		OTC_PURS_SHAR_M     	   --场外申购份额_本月
		,T1.OTC_CASTSL_SHAR_M           AS 		OTC_CASTSL_SHAR_M   	   --场外定投份额_本月
		,T1.OTC_COVT_IN_SHAR_M          AS 		OTC_COVT_IN_SHAR_M  	   --场外转换入份额_本月
		,T1.OTC_REDP_SHAR_M             AS 		OTC_REDP_SHAR_M     	   --场外赎回份额_本月
		,T1.OTC_COVT_OUT_SHAR_M         AS 		OTC_COVT_OUT_SHAR_M 	   --场外转换出份额_本月
		,T1.ITC_SUBS_CHAG_M             AS 		ITC_SUBS_CHAG_M     	   --场内认购手续费_本月
		,T1.ITC_PURS_CHAG_M             AS 		ITC_PURS_CHAG_M     	   --场内申购手续费_本月
		,T1.ITC_BUYIN_CHAG_M            AS 		ITC_BUYIN_CHAG_M    	   --场内买入手续费_本月
		,T1.ITC_REDP_CHAG_M             AS 		ITC_REDP_CHAG_M     	   --场内赎回手续费_本月
		,T1.ITC_SELL_CHAG_M             AS 		ITC_SELL_CHAG_M     	   --场内卖出手续费_本月
		,T1.OTC_SUBS_CHAG_M             AS 		OTC_SUBS_CHAG_M     	   --场外认购手续费_本月
		,T1.OTC_PURS_CHAG_M             AS 		OTC_PURS_CHAG_M     	   --场外申购手续费_本月
		,T1.OTC_CASTSL_CHAG_M           AS 		OTC_CASTSL_CHAG_M   	   --场外定投手续费_本月
		,T1.OTC_COVT_IN_CHAG_M          AS 		OTC_COVT_IN_CHAG_M  	   --场外转换入手续费_本月
		,T1.OTC_REDP_CHAG_M             AS 		OTC_REDP_CHAG_M     	   --场外赎回手续费_本月
		,T1.OTC_COVT_OUT_CHAG_M         AS 		OTC_COVT_OUT_CHAG_M 	   --场外转换出手续费_本月
		,T1.CONTD_SALE_SHAR_M           AS 		CONTD_SALE_SHAR_M   	   --续作销售份额_本月
		,T1.CONTD_SALE_AMT_M            AS 		CONTD_SALE_AMT_M    	   --续作销售金额_本月
		,T2.OTC_SUBS_AMT_TY             AS 		OTC_SUBS_AMT_TY     	   --场外认购金额_本年
		,T2.ITC_PURS_AMT_TY             AS 		ITC_PURS_AMT_TY     	   --场内申购金额_本年
		,T2.ITC_BUYIN_AMT_TY            AS 		ITC_BUYIN_AMT_TY    	   --场内买入金额_本年
		,T2.ITC_REDP_AMT_TY             AS 		ITC_REDP_AMT_TY     	   --场内赎回金额_本年
		,T2.ITC_SELL_AMT_TY             AS 		ITC_SELL_AMT_TY     	   --场内卖出金额_本年
		,T2.OTC_PURS_AMT_TY             AS 		OTC_PURS_AMT_TY     	   --场外申购金额_本年
		,T2.OTC_CASTSL_AMT_TY           AS 		OTC_CASTSL_AMT_TY   	   --场外定投金额_本年
		,T2.OTC_COVT_IN_AMT_TY          AS 		OTC_COVT_IN_AMT_TY  	   --场外转换入金额_本年
		,T2.OTC_REDP_AMT_TY             AS 		OTC_REDP_AMT_TY     	   --场外赎回金额_本年
		,T2.OTC_COVT_OUT_AMT_TY         AS 		OTC_COVT_OUT_AMT_TY 	   --场外转换出金额_本年
		,T2.ITC_SUBS_SHAR_TY            AS 		ITC_SUBS_SHAR_TY    	   --场内认购份额_本年
		,T2.ITC_PURS_SHAR_TY            AS 		ITC_PURS_SHAR_TY    	   --场内申购份额_本年
		,T2.ITC_BUYIN_SHAR_TY           AS 		ITC_BUYIN_SHAR_TY   	   --场内买入份额_本年
		,T2.ITC_REDP_SHAR_TY            AS 		ITC_REDP_SHAR_TY    	   --场内赎回份额_本年
		,T2.ITC_SELL_SHAR_TY            AS 		ITC_SELL_SHAR_TY    	   --场内卖出份额_本年
		,T2.OTC_SUBS_SHAR_TY            AS 		OTC_SUBS_SHAR_TY    	   --场外认购份额_本年
		,T2.OTC_PURS_SHAR_TY            AS 		OTC_PURS_SHAR_TY    	   --场外申购份额_本年
		,T2.OTC_CASTSL_SHAR_TY          AS 		OTC_CASTSL_SHAR_TY  	   --场外定投份额_本年
		,T2.OTC_COVT_IN_SHAR_TY         AS 		OTC_COVT_IN_SHAR_TY 	   --场外转换入份额_本年
		,T2.OTC_REDP_SHAR_TY            AS 		OTC_REDP_SHAR_TY    	   --场外赎回份额_本年
		,T2.OTC_COVT_OUT_SHAR_TY        AS 		OTC_COVT_OUT_SHAR_TY	   --场外转换出份额_本年
		,T2.ITC_SUBS_CHAG_TY            AS 		ITC_SUBS_CHAG_TY    	   --场内认购手续费_本年
		,T2.ITC_PURS_CHAG_TY            AS 		ITC_PURS_CHAG_TY    	   --场内申购手续费_本年
		,T2.ITC_BUYIN_CHAG_TY           AS 		ITC_BUYIN_CHAG_TY   	   --场内买入手续费_本年
		,T2.ITC_REDP_CHAG_TY            AS 		ITC_REDP_CHAG_TY    	   --场内赎回手续费_本年
		,T2.ITC_SELL_CHAG_TY            AS 		ITC_SELL_CHAG_TY    	   --场内卖出手续费_本年
		,T2.OTC_SUBS_CHAG_TY            AS 		OTC_SUBS_CHAG_TY    	   --场外认购手续费_本年
		,T2.OTC_PURS_CHAG_TY            AS 		OTC_PURS_CHAG_TY    	   --场外申购手续费_本年
		,T2.OTC_CASTSL_CHAG_TY          AS 		OTC_CASTSL_CHAG_TY  	   --场外定投手续费_本年
		,T2.OTC_COVT_IN_CHAG_TY         AS 		OTC_COVT_IN_CHAG_TY 	   --场外转换入手续费_本年
		,T2.OTC_REDP_CHAG_TY            AS 		OTC_REDP_CHAG_TY    	   --场外赎回手续费_本年
		,T2.OTC_COVT_OUT_CHAG_TY        AS 		OTC_COVT_OUT_CHAG_TY	   --场外转换出手续费_本年
		,T2.CONTD_SALE_SHAR_TY          AS 		CONTD_SALE_SHAR_TY  	   --续作销售份额_本年
		,T2.CONTD_SALE_AMT_TY           AS 		CONTD_SALE_AMT_TY   	   --续作销售金额_本年
	FROM #T_EVT_PROD_TRD_D_EMP_MTH T1,#T_EVT_PROD_TRD_D_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID 
		AND T1.PROD_CD = T2.PROD_CD
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部普通交易事实表（月存储日更新）
  编写者: 叶宏冰
  创建日期: 2018-03-28
  简介：营业部维度普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_TRD_D_BRH WHERE OCCUR_DT = @V_DATE;

	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--员工编码
		,A.PK_ORG 		AS 		BRH_ID			--营业部编码
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  	  	AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	-- 在T_EVT_TRD_D_BRH的基础上增加营业部字段来创建临时表

	CREATE TABLE #TMP_T_EVT_TRD_D_BRH(
	    OCCUR_DT             numeric(8,0) NOT NULL,
		EMP_ID               varchar(30) NOT NULL,
		BRH_ID		 		 varchar(30) NOT NULL,
		STKF_TRD_QTY         numeric(38,8) NULL,
		SCDY_TRD_QTY         numeric(38,8) NULL,
		S_REPUR_TRD_QTY      numeric(38,8) NULL,
		R_REPUR_TRD_QTY      numeric(38,8) NULL,
		HGT_TRD_QTY          numeric(38,8) NULL,
		SGT_TRD_QTY          numeric(38,8) NULL,
		STKPLG_TRD_QTY       numeric(38,8) NULL,
		APPTBUYB_TRD_QTY     numeric(38,8) NULL,
		OFFUND_TRD_QTY       numeric(38,8) NULL,
		OPFUND_TRD_QTY       numeric(38,8) NULL,
		BANK_CHRM_TRD_QTY    numeric(38,8) NULL,
		SECU_CHRM_TRD_QTY    numeric(38,8) NULL,
		PSTK_OPTN_TRD_QTY    numeric(38,8) NULL,
		CREDIT_ODI_TRD_QTY   numeric(38,8) NULL,
		CREDIT_CRED_TRD_QTY  numeric(38,8) NULL,
		COVR_BUYIN_AMT       numeric(38,8) NULL,
		COVR_SELL_AMT        numeric(38,8) NULL,
		CCB_AMT              numeric(38,8) NULL,
		FIN_SELL_AMT         numeric(38,8) NULL,
		CRDT_STK_BUYIN_AMT   numeric(38,8) NULL,
		CSS_AMT              numeric(38,8) NULL,
		FIN_RTN_AMT          numeric(38,8) NULL,
		STKPLG_INIT_TRD_AMT  numeric(38,8) NULL,
		STKPLG_BUYB_TRD_AMT  numeric(38,8) NULL,
		APPTBUYB_INIT_TRD_AMT numeric(38,8) NULL,
		APPTBUYB_BUYB_TRD_AMT numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_TRD_D_BRH(
		 OCCUR_DT             			--发生日期		
		,EMP_ID               			--员工编码	
		,BRH_ID		 		 			--营业部编码		
		,STKF_TRD_QTY         			--股基交易量	
		,SCDY_TRD_QTY         			--二级交易量
		,S_REPUR_TRD_QTY      			--正回购交易量	
		,R_REPUR_TRD_QTY      			--逆回购交易量		
		,HGT_TRD_QTY          			--沪港通交易量	
		,SGT_TRD_QTY          			--深港通交易量	
		,STKPLG_TRD_QTY       			--股票质押交易量		
		,APPTBUYB_TRD_QTY     			--约定购回交易量
		,OFFUND_TRD_QTY       			--场内基金交易量 
		,OPFUND_TRD_QTY       			--场外基金交易量 
		,BANK_CHRM_TRD_QTY    			--银行理财交易量 
		,SECU_CHRM_TRD_QTY    			--证券理财交易量 
		,PSTK_OPTN_TRD_QTY    			--个股期权交易量	
		,CREDIT_ODI_TRD_QTY   			--信用账户普通交易量 
		,CREDIT_CRED_TRD_QTY  			--信用账户信用交易量 
		,COVR_BUYIN_AMT       			--平仓买入金额 ？
		,COVR_SELL_AMT        			--平仓卖出金额 ？
		,CCB_AMT              			--融资买入金额 
		,FIN_SELL_AMT         			--融资卖出金额 
		,CRDT_STK_BUYIN_AMT   			--融券买入金额 
		,CSS_AMT              			--融券卖出金额 
		,FIN_RTN_AMT          			--融资归还金额
		,STKPLG_INIT_TRD_AMT  			--股票质押初始交易金额
		,STKPLG_BUYB_TRD_AMT  			--股票质押购回交易金额
		,APPTBUYB_INIT_TRD_AMT			--约定购回初始交易金额
		,APPTBUYB_BUYB_TRD_AMT			--约定购回购回交易金额
	)
	SELECT 
		 T.OCCUR_DT             		AS 		OCCUR_DT              		--发生日期		
		,T.EMP_ID               		AS 		EMP_ID                		--员工编码	
		,T1.BRH_ID		 				AS 		BRH_ID		 		   		--营业部编码		
		,T.STKF_TRD_QTY         		AS 		STKF_TRD_QTY          		--股基交易量	
		,T.SCDY_TRD_QTY         		AS 		SCDY_TRD_QTY          		--二级交易量
		,T.S_REPUR_TRD_QTY      		AS 		S_REPUR_TRD_QTY       		--正回购交易量	
		,T.R_REPUR_TRD_QTY      		AS 		R_REPUR_TRD_QTY       		--逆回购交易量		
		,T.HGT_TRD_QTY          		AS 		HGT_TRD_QTY           		--沪港通交易量	
		,T.SGT_TRD_QTY          		AS 		SGT_TRD_QTY           		--深港通交易量	
		,T.STKPLG_TRD_QTY       		AS 		STKPLG_TRD_QTY        		--股票质押交易量		
		,T.APPTBUYB_TRD_QTY     		AS 		APPTBUYB_TRD_QTY      		--约定购回交易量
		,T.OFFUND_TRD_QTY       		AS 		OFFUND_TRD_QTY        		--场内基金交易量 
		,T.OPFUND_TRD_QTY       		AS 		OPFUND_TRD_QTY        		--场外基金交易量 
		,T.BANK_CHRM_TRD_QTY    		AS 		BANK_CHRM_TRD_QTY     		--银行理财交易量 
		,T.SECU_CHRM_TRD_QTY    		AS 		SECU_CHRM_TRD_QTY     		--证券理财交易量 
		,T.PSTK_OPTN_TRD_QTY    		AS 		PSTK_OPTN_TRD_QTY     		--个股期权交易量	
		,T.CREDIT_ODI_TRD_QTY   		AS 		CREDIT_ODI_TRD_QTY    		--信用账户普通交易量 
		,T.CREDIT_CRED_TRD_QTY  		AS 		CREDIT_CRED_TRD_QTY   		--信用账户信用交易量 
		,T.COVR_BUYIN_AMT       		AS 		COVR_BUYIN_AMT        		--平仓买入金额 ？
		,T.COVR_SELL_AMT        		AS 		COVR_SELL_AMT         		--平仓卖出金额 ？
		,T.CCB_AMT              		AS 		CCB_AMT               		--融资买入金额 
		,T.FIN_SELL_AMT         		AS 		FIN_SELL_AMT          		--融资卖出金额 
		,T.CRDT_STK_BUYIN_AMT   		AS 		CRDT_STK_BUYIN_AMT    		--融券买入金额 
		,T.CSS_AMT              		AS 		CSS_AMT               		--融券卖出金额 
		,T.FIN_RTN_AMT          		AS 		FIN_RTN_AMT           		--融资归还金额
		,T.STKPLG_INIT_TRD_AMT  		AS 		STKPLG_INIT_TRD_AMT   		--股票质押初始交易金额
		,T.STKPLG_BUYB_TRD_AMT  		AS 		STKPLG_BUYB_TRD_AMT   		--股票质押购回交易金额
		,T.APPTBUYB_INIT_TRD_AMT		AS 		APPTBUYB_INIT_TRD_AMT 		--约定购回初始交易金额
		,T.APPTBUYB_BUYB_TRD_AMT		AS 		APPTBUYB_BUYB_TRD_AMT 		--约定购回购回交易金额
	FROM DM.T_EVT_TRD_D_EMP T 
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	 AND  T1.BRH_ID IS NOT NULL;


	--将临时表的按营业部维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_TRD_D_BRH (
			 OCCUR_DT             					--发生日期		
			,BRH_ID               					--营业部编码			
			,STKF_TRD_QTY         					--股基交易量	
			,SCDY_TRD_QTY         					--二级交易量
			,S_REPUR_TRD_QTY      					--正回购交易量	
			,R_REPUR_TRD_QTY      					--逆回购交易量		
			,HGT_TRD_QTY          					--沪港通交易量	
			,SGT_TRD_QTY          					--深港通交易量	
			,STKPLG_TRD_QTY       					--股票质押交易量		
			,APPTBUYB_TRD_QTY     					--约定购回交易量
			,OFFUND_TRD_QTY       					--场内基金交易量 
			,OPFUND_TRD_QTY       					--场外基金交易量 
			,BANK_CHRM_TRD_QTY    					--银行理财交易量 
			,SECU_CHRM_TRD_QTY    					--证券理财交易量 
			,PSTK_OPTN_TRD_QTY    					--个股期权交易量	
			,CREDIT_ODI_TRD_QTY   					--信用账户普通交易量 
			,CREDIT_CRED_TRD_QTY  					--信用账户信用交易量 
			,COVR_BUYIN_AMT       					--平仓买入金额 ？
			,COVR_SELL_AMT        					--平仓卖出金额 ？
			,CCB_AMT              					--融资买入金额 
			,FIN_SELL_AMT         					--融资卖出金额 
			,CRDT_STK_BUYIN_AMT   					--融券买入金额 
			,CSS_AMT              					--融券卖出金额 
			,FIN_RTN_AMT          					--融资归还金额
			,STKPLG_INIT_TRD_AMT  					--股票质押初始交易金额
			,STKPLG_BUYB_TRD_AMT  					--股票质押购回交易金额
			,APPTBUYB_INIT_TRD_AMT					--约定购回初始交易金额
			,APPTBUYB_BUYB_TRD_AMT					--约定购回购回交易金额
		)
		SELECT 
			 OCCUR_DT						AS    OCCUR_DT              	--发生日期		
			,BRH_ID							AS    BRH_ID                	--营业部编码			
			,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY          	--股基交易量	
			,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY          	--二级交易量
			,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY       	--正回购交易量	
			,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY       	--逆回购交易量		
			,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY           	--沪港通交易量	
			,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY           	--深港通交易量	
			,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY        	--股票质押交易量		
			,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY      	--约定购回交易量
			,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY        	--场内基金交易量 
			,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY        	--场外基金交易量 
			,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY     	--银行理财交易量 
			,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY     	--证券理财交易量 
			,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY     	--个股期权交易量	
			,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY    	--信用账户普通交易量 
			,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY   	--信用账户信用交易量 
			,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT        	--平仓买入金额 ？
			,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT         	--平仓卖出金额 ？
			,SUM(CCB_AMT)              		AS    CCB_AMT               	--融资买入金额 
			,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT          	--融资卖出金额 
			,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT    	--融券买入金额 
			,SUM(CSS_AMT)              		AS    CSS_AMT               	--融券卖出金额 
			,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT           	--融资归还金额
			,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT   	--股票质押初始交易金额
			,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT   	--股票质押购回交易金额
			,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT 	--约定购回初始交易金额
			,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT 	--约定购回购回交易金额
		FROM #TMP_T_EVT_TRD_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工普通交易事实表（月存储日更新）
  编写者: 叶宏冰
  创建日期: 2018-03-28
  简介：普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_TRD_D_EMP WHERE OCCUR_DT = @V_DATE;

	-- 1.1 在T_EVT_TRD_D_EMP的基础上增加资金账号字段来创建临时表（为了取责权分配后的金额然后再根据员工维度汇总分配后的金额）

	CREATE TABLE #TMP_T_EVT_TRD_D_EMP(
	    OCCUR_DT             numeric(8,0) NOT NULL,
		EMP_ID               varchar(30) NOT NULL,
		MAIN_CPTL_ACCT		 varchar(30) NOT NULL,
		STKF_TRD_QTY         numeric(38,8) NULL,
		SCDY_TRD_QTY         numeric(38,8) NULL,
		S_REPUR_TRD_QTY      numeric(38,8) NULL,
		R_REPUR_TRD_QTY      numeric(38,8) NULL,
		HGT_TRD_QTY          numeric(38,8) NULL,
		SGT_TRD_QTY          numeric(38,8) NULL,
		STKPLG_TRD_QTY       numeric(38,8) NULL,
		APPTBUYB_TRD_QTY     numeric(38,8) NULL,
		OFFUND_TRD_QTY       numeric(38,8) NULL,
		OPFUND_TRD_QTY       numeric(38,8) NULL,
		BANK_CHRM_TRD_QTY    numeric(38,8) NULL,
		SECU_CHRM_TRD_QTY    numeric(38,8) NULL,
		PSTK_OPTN_TRD_QTY    numeric(38,8) NULL,
		CREDIT_ODI_TRD_QTY   numeric(38,8) NULL,
		CREDIT_CRED_TRD_QTY  numeric(38,8) NULL,
		COVR_BUYIN_AMT       numeric(38,8) NULL,
		COVR_SELL_AMT        numeric(38,8) NULL,
		CCB_AMT              numeric(38,8) NULL,
		FIN_SELL_AMT         numeric(38,8) NULL,
		CRDT_STK_BUYIN_AMT   numeric(38,8) NULL,
		CSS_AMT              numeric(38,8) NULL,
		FIN_RTN_AMT          numeric(38,8) NULL,
		STKPLG_INIT_TRD_AMT  numeric(38,8) NULL,
		STKPLG_BUYB_TRD_AMT  numeric(38,8) NULL,
		APPTBUYB_INIT_TRD_AMT numeric(38,8) NULL,
		APPTBUYB_BUYB_TRD_AMT numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_TRD_D_EMP(
		 OCCUR_DT					
		,EMP_ID						
		,MAIN_CPTL_ACCT
	)			
	SELECT 
		 @V_DATE AS OCCUR_DT			--发生日期
		,A.AFATWO_YGH AS EMP_ID			--员工编码
		,A.ZJZH AS MAIN_CPTL_ACCT		--资金账号
	FROM DBA.T_DDW_SERV_RELATION_D A
	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  		   ,A.ZJZH;

	-- 基于责权分配表统计（员工-客户）绩效分配比例

  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH;

	--更新分配后的各项指标
	UPDATE #TMP_T_EVT_TRD_D_EMP
		SET 
			 STKF_TRD_QTY = COALESCE(B.STKF_TRD_QTY,0)					* C.PERFM_RATIO_3		--股基交易量		
			,SCDY_TRD_QTY = COALESCE(B.SCDY_TRD_QTY,0)					* C.PERFM_RATIO_3		--二级交易量				
			,S_REPUR_TRD_QTY = COALESCE(B.S_REPUR_TRD_QTY,0)			* C.PERFM_RATIO_3		--正回购交易量						
			,R_REPUR_TRD_QTY = COALESCE(B.R_REPUR_TRD_QTY,0)			* C.PERFM_RATIO_3		--逆回购交易量						
			,HGT_TRD_QTY = COALESCE(B.HGT_TRD_QTY,0)					* C.PERFM_RATIO_3		--沪港通交易量				
			,SGT_TRD_QTY = COALESCE(B.SGT_TRD_QTY,0)					* C.PERFM_RATIO_3		--深港通交易量				
			,STKPLG_TRD_QTY = COALESCE(B.STKPLG_TRD_QTY,0)				* C.PERFM_RATIO_3		--股票质押交易量				
			,APPTBUYB_TRD_QTY = COALESCE(B.APPTBUYB_TRD_QTY,0)			* C.PERFM_RATIO_3		--约定购回交易量								
			,OFFUND_TRD_QTY = COALESCE(B.OFFUND_TRD_QTY,0)				* C.PERFM_RATIO_3		--场内基金交易量							
			,OPFUND_TRD_QTY = COALESCE(B.OPFUND_TRD_QTY,0)				* C.PERFM_RATIO_3		--场外基金交易量							
			,BANK_CHRM_TRD_QTY = COALESCE(B.BANK_CHRM_TRD_QTY,0)		* C.PERFM_RATIO_3		--银行理财交易量									
			,SECU_CHRM_TRD_QTY = COALESCE(B.SECU_CHRM_TRD_QTY,0)		* C.PERFM_RATIO_3		--证券理财交易量									
			,PSTK_OPTN_TRD_QTY = COALESCE(B.PSTK_OPTN_TRD_QTY,0)		* C.PERFM_RATIO_3		--个股期权交易量									
			,CREDIT_ODI_TRD_QTY = COALESCE(B.CREDIT_ODI_TRD_QTY,0)		* C.PERFM_RATIO_3		--信用账户普通交易量									
			,CREDIT_CRED_TRD_QTY = COALESCE(B.CREDIT_CRED_TRD_QTY,0)	* C.PERFM_RATIO_3		--信用账户信用交易量										
			,CCB_AMT = COALESCE(B.CCB_AMT,0)							* C.PERFM_RATIO_3		--融资买入金额				
			,FIN_SELL_AMT = COALESCE(B.FIN_SELL_AMT,0)					* C.PERFM_RATIO_3		--融资卖出金额						
			,CRDT_STK_BUYIN_AMT = COALESCE(B.CRDT_STK_BUYIN_AMT,0)		* C.PERFM_RATIO_3		--融券买入金额									
			,CSS_AMT = COALESCE(B.CSS_AMT,0)							* C.PERFM_RATIO_3		--融券卖出金额				
			,FIN_RTN_AMT = COALESCE(B.FIN_RTN_AMT,0)					* C.PERFM_RATIO_3		--融资归还金额						
			,STKPLG_INIT_TRD_AMT = COALESCE(B.STKPLG_INIT_TRD_AMT,0)		* C.PERFM_RATIO_3	--股票质押初始交易金额 							
			,STKPLG_BUYB_TRD_AMT = COALESCE(B.STKPLG_BUYB_TRD_AMT,0)		* C.PERFM_RATIO_3	--股票质押购回交易金额 								
			,APPTBUYB_INIT_TRD_AMT = COALESCE(B.APPTBUYB_INIT_TRD_AMT,0)	* C.PERFM_RATIO_3	--约定购回初始交易金额 						
			,APPTBUYB_BUYB_TRD_AMT = COALESCE(B.APPTBUYB_BUYB_TRD_AMT,0)	* C.PERFM_RATIO_3	--约定购回购回交易金额 										
		FROM #TMP_T_EVT_TRD_D_EMP A
		LEFT JOIN (
				SELECT 
					T.MAIN_CPTL_ACCT	  			AS 		MAIN_CPTL_ACCT			--资金账号			
				   ,T.STKF_TRD_QTY  	  			AS 		STKF_TRD_QTY			--股基交易量	
				   ,T.SCDY_TRD_QTY  	  			AS 		SCDY_TRD_QTY			--二级交易量			
				   ,T.S_REPUR_TRD_QTY     			AS 		S_REPUR_TRD_QTY			--正回购交易量				
				   ,T.R_REPUR_TRD_QTY     			AS 		R_REPUR_TRD_QTY			--逆回购交易量				
				   ,T.HGT_TRD_QTY  		  			AS 		HGT_TRD_QTY 			--沪港通交易量				
				   ,T.SGT_TRD_QTY  		  			AS 		SGT_TRD_QTY				--深港通交易量				
				   ,T.STKPLG_TRD_QTY 	  			AS      STKPLG_TRD_QTY 			--股票质押交易量				
				   ,T.APPTBUYB_TRD_QTY    			AS      APPTBUYB_TRD_QTY		--约定购回交易量
				   ,T.OFFUND_TRD_QTY	  			AS 	    OFFUND_TRD_QTY			--场内基金交易量
				   ,T.OPFUND_TRD_QTY	  			AS		OPFUND_TRD_QTY			--场外基金交易量
				   ,T.BANK_CHRM_TRD_QTY   			AS		BANK_CHRM_TRD_QTY		--银行理财交易量
				   ,T.SECU_CHRM_TRD_QTY	  			AS 		SECU_CHRM_TRD_QTY		--证券理财交易量
				   ,T.PSTK_OPTN_TRD_QTY   			AS 		PSTK_OPTN_TRD_QTY		--个股期权交易量
				   ,T.CREDIT_ODI_TRD_QTY  			AS	    CREDIT_ODI_TRD_QTY		--信用账户普通交易量
				   ,T.CREDIT_CRED_TRD_QTY 			AS      CREDIT_CRED_TRD_QTY     --信用账户信用交易量
				   ,0								AS		COVR_BUYIN_AMT			--平仓买入金额
				   ,0								AS 		COVR_SELL_AMT			--平仓卖出金额
				   ,T.CCB_AMT			  			AS      CCB_AMT                 --融资买入金额
				   ,T.FIN_SELL_AMT        			AS  	FIN_SELL_AMT         	--融资卖出金额
				   ,T.CRDT_STK_BUYIN_AMT  			AS      CRDT_STK_BUYIN_AMT   	--融券买入金额
				   ,T.CSS_AMT			  			AS      CSS_AMT              	--融券卖出金额
				   ,T.FIN_RTN_AMT         			AS      FIN_RTN_AMT          	--融资归还金额
				   ,T.STKPLG_TRD_QTY      			AS		STKPLG_INIT_TRD_AMT  	--股票质押初始交易金额 
				   ,T.STKPLG_BUYB_AMT     			AS 		STKPLG_BUYB_TRD_AMT  	--股票质押购回交易金额 
				   ,T.APPTBUYB_TRD_QTY    			AS		APPTBUYB_INIT_TRD_AMT	--约定购回初始交易金额 
				   ,T.APPTBUYB_TRD_AMT	  			AS		APPTBUYB_BUYB_TRD_AMT	--约定购回购回交易金额 						
				FROM DM.T_EVT_CUS_TRD_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B ON A.MAIN_CPTL_ACCT=B.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--将临时表的按员工维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_TRD_D_EMP (
			 OCCUR_DT             					--发生日期		
			,EMP_ID               					--员工编码			
			,STKF_TRD_QTY         					--股基交易量	
			,SCDY_TRD_QTY         					--二级交易量
			,S_REPUR_TRD_QTY      					--正回购交易量	
			,R_REPUR_TRD_QTY      					--逆回购交易量		
			,HGT_TRD_QTY          					--沪港通交易量	
			,SGT_TRD_QTY          					--深港通交易量	
			,STKPLG_TRD_QTY       					--股票质押交易量		
			,APPTBUYB_TRD_QTY     					--约定购回交易量
			,OFFUND_TRD_QTY       					--场内基金交易量 
			,OPFUND_TRD_QTY       					--场外基金交易量 
			,BANK_CHRM_TRD_QTY    					--银行理财交易量 
			,SECU_CHRM_TRD_QTY    					--证券理财交易量 
			,PSTK_OPTN_TRD_QTY    					--个股期权交易量	
			,CREDIT_ODI_TRD_QTY   					--信用账户普通交易量 
			,CREDIT_CRED_TRD_QTY  					--信用账户信用交易量 
			,COVR_BUYIN_AMT       					--平仓买入金额 ？
			,COVR_SELL_AMT        					--平仓卖出金额 ？
			,CCB_AMT              					--融资买入金额 
			,FIN_SELL_AMT         					--融资卖出金额 
			,CRDT_STK_BUYIN_AMT   					--融券买入金额 
			,CSS_AMT              					--融券卖出金额 
			,FIN_RTN_AMT          					--融资归还金额
			,STKPLG_INIT_TRD_AMT  					--股票质押初始交易金额
			,STKPLG_BUYB_TRD_AMT  					--股票质押购回交易金额
			,APPTBUYB_INIT_TRD_AMT					--约定购回初始交易金额
			,APPTBUYB_BUYB_TRD_AMT					--约定购回购回交易金额
		)
		SELECT 
			 OCCUR_DT						AS    OCCUR_DT              	--发生日期		
			,EMP_ID							AS    EMP_ID                	--员工编码			
			,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY          	--股基交易量	
			,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY          	--二级交易量
			,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY       	--正回购交易量	
			,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY       	--逆回购交易量		
			,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY           	--沪港通交易量	
			,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY           	--深港通交易量	
			,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY        	--股票质押交易量		
			,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY      	--约定购回交易量
			,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY        	--场内基金交易量 
			,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY        	--场外基金交易量 
			,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY     	--银行理财交易量 
			,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY     	--证券理财交易量 
			,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY     	--个股期权交易量	
			,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY    	--信用账户普通交易量 
			,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY   	--信用账户信用交易量 
			,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT        	--平仓买入金额 ？
			,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT         	--平仓卖出金额 ？
			,SUM(CCB_AMT)              		AS    CCB_AMT               	--融资买入金额 
			,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT          	--融资卖出金额 
			,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT    	--融券买入金额 
			,SUM(CSS_AMT)              		AS    CSS_AMT               	--融券卖出金额 
			,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT           	--融资归还金额
			,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT   	--股票质押初始交易金额
			,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT   	--股票质押购回交易金额
			,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT 	--约定购回初始交易金额
			,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT 	--约定购回购回交易金额
		FROM #TMP_T_EVT_TRD_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部普通交易事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-10
  简介：营业部普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_TRD_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID							AS    BRH_ID                	--营业部编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_M          	--股基交易量_本月	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_M          	--二级交易量_本月
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_M       	--正回购交易量_本月	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_M       	--逆回购交易量_本月		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_M           	--沪港通交易量_本月	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_M           	--深港通交易量_本月	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_M        	--股票质押交易量_本月		
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_M      	--约定购回交易量_本月
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_M        	--场内基金交易量_本月 
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_M        	--场外基金交易量_本月 
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_M     	--银行理财交易量_本月 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_M     	--证券理财交易量_本月 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_M     	--个股期权交易量_本月	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_M    	--信用账户普通交易量_本月 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_M   	--信用账户信用交易量_本月 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_M        	--平仓买入金额_本月 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_M         	--平仓卖出金额_本月 
		,SUM(CCB_AMT)              		AS    CCB_AMT_M               	--融资买入金额_本月 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_M          	--融资卖出金额_本月 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_M    	--融券买入金额_本月 
		,SUM(CSS_AMT)              		AS    CSS_AMT_M               	--融券卖出金额_本月 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_M           	--融资归还金额_本月
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_M   	--股票质押初始交易金额_本月
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_M   	--股票质押购回交易金额_本月
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_M 	--约定购回初始交易金额_本月
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_M 	--约定购回购回交易金额_本月
	INTO #TMP_T_EVT_TRD_M_BRH_MTH
	FROM DM.T_EVT_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	-- 统计年指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID							AS    BRH_ID                	--营业部编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_TY         	--股基交易量_本年	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_TY          	--二级交易量_本年	
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_TY       	--正回购交易量_本年	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_TY       	--逆回购交易量_本年		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_TY           	--沪港通交易量_本年	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_TY           	--深港通交易量_本年	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_TY        	--股票质押交易量_本年	
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_TY      	--约定购回交易量_本年
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_TY        	--场内基金交易量_本年
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_TY        	--场外基金交易量_本年
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_TY     	--银行理财交易量_本年 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_TY     	--证券理财交易量_本年 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_TY     	--个股期权交易量_本年	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_TY    	--信用账户普通交易量_本年 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_TY   	--信用账户信用交易量_本年 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_TY        	--平仓买入金额_本年 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_TY         	--平仓卖出金额_本年 
		,SUM(CCB_AMT)              		AS    CCB_AMT_TY               	--融资买入金额_本年 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_TY          	--融资卖出金额_本年 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_TY    	--融券买入金额_本年 
		,SUM(CSS_AMT)              		AS    CSS_AMT_TY               	--融券卖出金额_本年 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_TY           	--融资归还金额_本年
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_TY   	--股票质押初始交易金额_本年
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_TY   	--股票质押购回交易金额_本年
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_TY 	--约定购回初始交易金额_本年
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_TY 	--约定购回购回交易金额_本年
	INTO #TMP_T_EVT_TRD_M_BRH_YEAR
	FROM DM.T_EVT_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--插入目标表
	INSERT INTO DM.T_EVT_TRD_M_BRH(
		 YEAR                 								--年
		,MTH                  								--月		
		,BRH_ID												--营业部编码	
		,OCCUR_DT											--发生日期		
		,STKF_TRD_QTY_M										--股基交易量_本月	
		,STKF_TRD_QTY_TY									--股基交易量_本年	
		,SCDY_TRD_QTY_M										--二级交易量_本月	
		,SCDY_TRD_QTY_TY									--二级交易量_本年	
		,S_REPUR_TRD_QTY_M									--正回购交易量_本月		
		,S_REPUR_TRD_QTY_TY									--正回购交易量_本年		
		,R_REPUR_TRD_QTY_M									--逆回购交易量_本月			
		,R_REPUR_TRD_QTY_TY									--逆回购交易量_本年			
		,HGT_TRD_QTY_M										--沪港通交易量_本月	
		,HGT_TRD_QTY_TY										--沪港通交易量_本年		
		,SGT_TRD_QTY_M										--深港通交易量_本月	
		,SGT_TRD_QTY_TY										--深港通交易量_本年	
		,STKPLG_TRD_QTY_M									--股票质押交易量_本月			
		,STKPLG_TRD_QTY_TY									--股票质押交易量_本年		
		,APPTBUYB_TRD_QTY_M									--约定购回交易量_本月	
		,APPTBUYB_TRD_QTY_TY								--约定购回交易量_本年	
		,OFFUND_TRD_QTY_M									--场内基金交易量_本月	
		,OFFUND_TRD_QTY_TY									--场内基金交易量_本年	
		,OPFUND_TRD_QTY_M									--场外基金交易量_本月	
		,OPFUND_TRD_QTY_TY									--场外基金交易量_本年	
		,BANK_CHRM_TRD_QTY_M								--银行理财交易量_本月 	
		,BANK_CHRM_TRD_QTY_TY								--银行理财交易量_本年 		
		,SECU_CHRM_TRD_QTY_M								--证券理财交易量_本月	
		,SECU_CHRM_TRD_QTY_TY								--证券理财交易量_本年		
		,PSTK_OPTN_TRD_QTY_M								--个股期权交易量_本月		
		,PSTK_OPTN_TRD_QTY_TY								--个股期权交易量_本年			
		,CREDIT_ODI_TRD_QTY_M								--信用账户普通交易量_本月 		
		,CREDIT_ODI_TRD_QTY_TY								--信用账户普通交易量_本年 		
		,CREDIT_CRED_TRD_QTY_M								--信用账户信用交易量_本月 		
		,CREDIT_CRED_TRD_QTY_TY								--信用账户信用交易量_本年 		
		,COVR_BUYIN_AMT_M									--平仓买入金额_本月 	
		,COVR_BUYIN_AMT_TY									--平仓买入金额_本年 	
		,COVR_SELL_AMT_M									--平仓卖出金额_本月 
		,COVR_SELL_AMT_TY									--平仓卖出金额_本年 	
		,CCB_AMT_M											--融资买入金额_本月 
		,CCB_AMT_TY											--融资买入金额_本年 
		,FIN_SELL_AMT_M										--融资卖出金额_本月 
		,FIN_SELL_AMT_TY									--融资卖出金额_本年 
		,CRDT_STK_BUYIN_AMT_M								--融券买入金额_本月 		
		,CRDT_STK_BUYIN_AMT_TY								--融券买入金额_本年 		
		,CSS_AMT_M											--融券卖出金额_本月 
		,CSS_AMT_TY											--融券卖出金额_本年 
		,FIN_RTN_AMT_M        								--融资归还金额_本月		
		,FIN_RTN_AMT_TY       								--融资归还金额_本年		
		,STKPLG_INIT_TRD_AMT_M 								--股票质押初始交易金额_本月		
		,STKPLG_INIT_TRD_AMT_TY 							--股票质押初始交易金额_本年		
		,STKPLG_REPO_TRD_AMT_M								--股票质押购回交易金额_本月		
		,STKPLG_REPO_TRD_AMT_TY								--股票质押购回交易金额_本年		
		,APPTBUYB_INIT_TRD_AMT_M 							--约定购回初始交易金额_本月			
		,APPTBUYB_INIT_TRD_AMT_TY							--约定购回初始交易金额_本年			
		,APPTBUYB_BUYB_TRD_AMT_M							--约定购回购回交易金额_本月			
		,APPTBUYB_BUYB_TRD_AMT_TY							--约定购回购回交易金额_本年	
	)		
	SELECT 
		 T1.YEAR  							AS			YEAR                 								--年
		,T1.MTH 						    AS			MTH                  								--月		
		,T1.BRH_ID							AS			BRH_ID												--营业部编码	
		,T1.OCCUR_DT 						AS			OCCUR_DT											--发生日期		
		,T1.STKF_TRD_QTY_M        	 		AS			STKF_TRD_QTY_M										--股基交易量_本月	
		,T2.STKF_TRD_QTY_TY         		AS			STKF_TRD_QTY_TY										--股基交易量_本年	
		,T1.SCDY_TRD_QTY_M          		AS			SCDY_TRD_QTY_M										--二级交易量_本月	
		,T2.SCDY_TRD_QTY_TY          		AS			SCDY_TRD_QTY_TY										--二级交易量_本年		
		,T1.S_REPUR_TRD_QTY_M       		AS			S_REPUR_TRD_QTY_M									--正回购交易量_本月		
		,T2.S_REPUR_TRD_QTY_TY       		AS			S_REPUR_TRD_QTY_TY									--正回购交易量_本年			
		,T1.R_REPUR_TRD_QTY_M       		AS			R_REPUR_TRD_QTY_M									--逆回购交易量_本月			
		,T2.R_REPUR_TRD_QTY_TY       		AS			R_REPUR_TRD_QTY_TY									--逆回购交易量_本年	
		,T1.HGT_TRD_QTY_M           		AS			HGT_TRD_QTY_M										--沪港通交易量_本月	
		,T2.HGT_TRD_QTY_TY           		AS			HGT_TRD_QTY_TY										--沪港通交易量_本年	
		,T1.SGT_TRD_QTY_M           		AS			SGT_TRD_QTY_M										--深港通交易量_本月	
		,T2.SGT_TRD_QTY_TY           		AS			SGT_TRD_QTY_TY										--深港通交易量_本年	
		,T1.STKPLG_TRD_QTY_M        		AS			STKPLG_TRD_QTY_M									--股票质押交易量_本月			
		,T2.STKPLG_TRD_QTY_TY        		AS			STKPLG_TRD_QTY_TY									--股票质押交易量_本年		
		,T1.APPTBUYB_TRD_QTY_M      		AS			APPTBUYB_TRD_QTY_M									--约定购回交易量_本月	
		,T2.APPTBUYB_TRD_QTY_TY      		AS			APPTBUYB_TRD_QTY_TY									--约定购回交易量_本年	
		,T1.OFFUND_TRD_QTY_M        		AS			OFFUND_TRD_QTY_M									--场内基金交易量_本月	
		,T2.OFFUND_TRD_QTY_TY        		AS			OFFUND_TRD_QTY_TY									--场内基金交易量_本年	
		,T1.OPFUND_TRD_QTY_M        		AS			OPFUND_TRD_QTY_M									--场外基金交易量_本月	
		,T2.OPFUND_TRD_QTY_TY        		AS			OPFUND_TRD_QTY_TY									--场外基金交易量_本年	
		,T1.BANK_CHRM_TRD_QTY_M     		AS			BANK_CHRM_TRD_QTY_M									--银行理财交易量_本月 	
		,T2.BANK_CHRM_TRD_QTY_TY     		AS			BANK_CHRM_TRD_QTY_TY								--银行理财交易量_本年 		
		,T1.SECU_CHRM_TRD_QTY_M     		AS			SECU_CHRM_TRD_QTY_M									--证券理财交易量_本月	
		,T2.SECU_CHRM_TRD_QTY_TY     		AS			SECU_CHRM_TRD_QTY_TY								--证券理财交易量_本年		
		,T1.PSTK_OPTN_TRD_QTY_M     		AS			PSTK_OPTN_TRD_QTY_M									--个股期权交易量_本月		
		,T2.PSTK_OPTN_TRD_QTY_TY     		AS			PSTK_OPTN_TRD_QTY_TY								--个股期权交易量_本年			
		,T1.CREDIT_ODI_TRD_QTY_M    		AS			CREDIT_ODI_TRD_QTY_M								--信用账户普通交易量_本月 		
		,T2.CREDIT_ODI_TRD_QTY_TY    		AS			CREDIT_ODI_TRD_QTY_TY								--信用账户普通交易量_本年 		
		,T1.CREDIT_CRED_TRD_QTY_M   		AS			CREDIT_CRED_TRD_QTY_M								--信用账户信用交易量_本月 		
		,T2.CREDIT_CRED_TRD_QTY_TY   		AS			CREDIT_CRED_TRD_QTY_TY								--信用账户信用交易量_本年 		
		,T1.COVR_BUYIN_AMT_M        		AS			COVR_BUYIN_AMT_M									--平仓买入金额_本月 	
		,T2.COVR_BUYIN_AMT_TY        		AS			COVR_BUYIN_AMT_TY									--平仓买入金额_本年 	
		,T1.COVR_SELL_AMT_M         		AS			COVR_SELL_AMT_M										--平仓卖出金额_本月 
		,T2.COVR_SELL_AMT_TY         		AS			COVR_SELL_AMT_TY									--平仓卖出金额_本年 	
		,T1.CCB_AMT_M               		AS			CCB_AMT_M											--融资买入金额_本月 
		,T2.CCB_AMT_TY               		AS			CCB_AMT_TY											--融资买入金额_本年 
		,T1.FIN_SELL_AMT_M          		AS			FIN_SELL_AMT_M										--融资卖出金额_本月 
		,T2.FIN_SELL_AMT_TY          		AS			FIN_SELL_AMT_TY										--融资卖出金额_本年 
		,T1.CRDT_STK_BUYIN_AMT_M    		AS			CRDT_STK_BUYIN_AMT_M								--融券买入金额_本月 		
		,T2.CRDT_STK_BUYIN_AMT_TY    		AS			CRDT_STK_BUYIN_AMT_TY								--融券买入金额_本年 		
		,T1.CSS_AMT_M               		AS			CSS_AMT_M											--融券卖出金额_本月 
		,T2.CSS_AMT_TY               		AS			CSS_AMT_TY											--融券卖出金额_本年 
		,T1.FIN_RTN_AMT_M           		AS			FIN_RTN_AMT_M        								--融资归还金额_本月		
		,T2.FIN_RTN_AMT_TY           		AS			FIN_RTN_AMT_TY       								--融资归还金额_本年		
		,T1.STKPLG_INIT_TRD_AMT_M   		AS			STKPLG_INIT_TRD_AMT_M 								--股票质押初始交易金额_本月		
		,T2.STKPLG_INIT_TRD_AMT_TY   		AS			STKPLG_INIT_TRD_AMT_TY 								--股票质押初始交易金额_本年		
		,T1.STKPLG_BUYB_TRD_AMT_M   		AS			STKPLG_REPO_TRD_AMT_M								--股票质押购回交易金额_本月		
		,T2.STKPLG_BUYB_TRD_AMT_TY   		AS			STKPLG_REPO_TRD_AMT_TY								--股票质押购回交易金额_本年		
		,T1.APPTBUYB_INIT_TRD_AMT_M 		AS			APPTBUYB_INIT_TRD_AMT_M 							--约定购回初始交易金额_本月			
		,T2.APPTBUYB_INIT_TRD_AMT_TY 		AS			APPTBUYB_INIT_TRD_AMT_TY							--约定购回初始交易金额_本年			
		,T1.APPTBUYB_BUYB_TRD_AMT_M 		AS			APPTBUYB_BUYB_TRD_AMT_M								--约定购回购回交易金额_本月			
		,T2.APPTBUYB_BUYB_TRD_AMT_TY 		AS			APPTBUYB_BUYB_TRD_AMT_TY							--约定购回购回交易金额_本年			
	FROM #TMP_T_EVT_TRD_M_BRH_MTH T1,#TMP_T_EVT_TRD_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_M_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工普通交易事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-04
  简介：普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_TRD_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,EMP_ID							AS    EMP_ID                	--员工编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_M          	--股基交易量_本月	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_M          	--二级交易量_本月
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_M       	--正回购交易量_本月	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_M       	--逆回购交易量_本月		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_M           	--沪港通交易量_本月	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_M           	--深港通交易量_本月	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_M        	--股票质押交易量_本月		
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_M      	--约定购回交易量_本月
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_M        	--场内基金交易量_本月 
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_M        	--场外基金交易量_本月 
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_M     	--银行理财交易量_本月 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_M     	--证券理财交易量_本月 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_M     	--个股期权交易量_本月	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_M    	--信用账户普通交易量_本月 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_M   	--信用账户信用交易量_本月 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_M        	--平仓买入金额_本月 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_M         	--平仓卖出金额_本月 
		,SUM(CCB_AMT)              		AS    CCB_AMT_M               	--融资买入金额_本月 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_M          	--融资卖出金额_本月 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_M    	--融券买入金额_本月 
		,SUM(CSS_AMT)              		AS    CSS_AMT_M               	--融券卖出金额_本月 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_M           	--融资归还金额_本月
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_M   	--股票质押初始交易金额_本月
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_M   	--股票质押购回交易金额_本月
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_M 	--约定购回初始交易金额_本月
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_M 	--约定购回购回交易金额_本月
	INTO #TMP_T_EVT_TRD_M_EMP_MTH
	FROM DM.T_EVT_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	-- 统计年指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,EMP_ID							AS    EMP_ID                	--员工编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_TY         	--股基交易量_本年	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_TY          	--二级交易量_本年	
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_TY       	--正回购交易量_本年	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_TY       	--逆回购交易量_本年		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_TY           	--沪港通交易量_本年	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_TY           	--深港通交易量_本年	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_TY        	--股票质押交易量_本年	
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_TY      	--约定购回交易量_本年
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_TY        	--场内基金交易量_本年
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_TY        	--场外基金交易量_本年
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_TY     	--银行理财交易量_本年 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_TY     	--证券理财交易量_本年 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_TY     	--个股期权交易量_本年	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_TY    	--信用账户普通交易量_本年 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_TY   	--信用账户信用交易量_本年 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_TY        	--平仓买入金额_本年 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_TY         	--平仓卖出金额_本年 
		,SUM(CCB_AMT)              		AS    CCB_AMT_TY               	--融资买入金额_本年 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_TY          	--融资卖出金额_本年 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_TY    	--融券买入金额_本年 
		,SUM(CSS_AMT)              		AS    CSS_AMT_TY               	--融券卖出金额_本年 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_TY           	--融资归还金额_本年
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_TY   	--股票质押初始交易金额_本年
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_TY   	--股票质押购回交易金额_本年
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_TY 	--约定购回初始交易金额_本年
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_TY 	--约定购回购回交易金额_本年
	INTO #TMP_T_EVT_TRD_M_EMP_YEAR
	FROM DM.T_EVT_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	--插入目标表
	INSERT INTO DM.T_EVT_TRD_M_EMP(
		 YEAR                 								--年
		,MTH                  								--月		
		,EMP_ID												--员工编码	
		,OCCUR_DT											--发生日期		
		,STKF_TRD_QTY_M										--股基交易量_本月	
		,STKF_TRD_QTY_TY									--股基交易量_本年	
		,SCDY_TRD_QTY_M										--二级交易量_本月	
		,SCDY_TRD_QTY_TY									--二级交易量_本年	
		,S_REPUR_TRD_QTY_M									--正回购交易量_本月		
		,S_REPUR_TRD_QTY_TY									--正回购交易量_本年		
		,R_REPUR_TRD_QTY_M									--逆回购交易量_本月			
		,R_REPUR_TRD_QTY_TY									--逆回购交易量_本年			
		,HGT_TRD_QTY_M										--沪港通交易量_本月	
		,HGT_TRD_QTY_TY										--沪港通交易量_本年		
		,SGT_TRD_QTY_M										--深港通交易量_本月	
		,SGT_TRD_QTY_TY										--深港通交易量_本年	
		,STKPLG_TRD_QTY_M									--股票质押交易量_本月			
		,STKPLG_TRD_QTY_TY									--股票质押交易量_本年		
		,APPTBUYB_TRD_QTY_M									--约定购回交易量_本月	
		,APPTBUYB_TRD_QTY_TY								--约定购回交易量_本年	
		,OFFUND_TRD_QTY_M									--场内基金交易量_本月	
		,OFFUND_TRD_QTY_TY									--场内基金交易量_本年	
		,OPFUND_TRD_QTY_M									--场外基金交易量_本月	
		,OPFUND_TRD_QTY_TY									--场外基金交易量_本年	
		,BANK_CHRM_TRD_QTY_M								--银行理财交易量_本月 	
		,BANK_CHRM_TRD_QTY_TY								--银行理财交易量_本年 		
		,SECU_CHRM_TRD_QTY_M								--证券理财交易量_本月	
		,SECU_CHRM_TRD_QTY_TY								--证券理财交易量_本年		
		,PSTK_OPTN_TRD_QTY_M								--个股期权交易量_本月		
		,PSTK_OPTN_TRD_QTY_TY								--个股期权交易量_本年			
		,CREDIT_ODI_TRD_QTY_M								--信用账户普通交易量_本月 		
		,CREDIT_ODI_TRD_QTY_TY								--信用账户普通交易量_本年 		
		,CREDIT_CRED_TRD_QTY_M								--信用账户信用交易量_本月 		
		,CREDIT_CRED_TRD_QTY_TY								--信用账户信用交易量_本年 		
		,COVR_BUYIN_AMT_M									--平仓买入金额_本月 	
		,COVR_BUYIN_AMT_TY									--平仓买入金额_本年 	
		,COVR_SELL_AMT_M									--平仓卖出金额_本月 
		,COVR_SELL_AMT_TY									--平仓卖出金额_本年 	
		,CCB_AMT_M											--融资买入金额_本月 
		,CCB_AMT_TY											--融资买入金额_本年 
		,FIN_SELL_AMT_M										--融资卖出金额_本月 
		,FIN_SELL_AMT_TY									--融资卖出金额_本年 
		,CRDT_STK_BUYIN_AMT_M								--融券买入金额_本月 		
		,CRDT_STK_BUYIN_AMT_TY								--融券买入金额_本年 		
		,CSS_AMT_M											--融券卖出金额_本月 
		,CSS_AMT_TY											--融券卖出金额_本年 
		,FIN_RTN_AMT_M        								--融资归还金额_本月		
		,FIN_RTN_AMT_TY       								--融资归还金额_本年		
		,STKPLG_INIT_TRD_AMT_M 								--股票质押初始交易金额_本月		
		,STKPLG_INIT_TRD_AMT_TY 							--股票质押初始交易金额_本年		
		,STKPLG_REPO_TRD_AMT_M								--股票质押购回交易金额_本月		
		,STKPLG_REPO_TRD_AMT_TY								--股票质押购回交易金额_本年		
		,APPTBUYB_INIT_TRD_AMT_M 							--约定购回初始交易金额_本月			
		,APPTBUYB_INIT_TRD_AMT_TY							--约定购回初始交易金额_本年			
		,APPTBUYB_BUYB_TRD_AMT_M							--约定购回购回交易金额_本月			
		,APPTBUYB_BUYB_TRD_AMT_TY							--约定购回购回交易金额_本年	
	)		
	SELECT 
		 T1.YEAR  							AS			YEAR                 								--年
		,T1.MTH 						    AS			MTH                  								--月		
		,T1.EMP_ID							AS			EMP_ID												--员工编码	
		,T1.OCCUR_DT 						AS			OCCUR_DT											--发生日期		
		,T1.STKF_TRD_QTY_M        	 		AS			STKF_TRD_QTY_M										--股基交易量_本月	
		,T2.STKF_TRD_QTY_TY         		AS			STKF_TRD_QTY_TY										--股基交易量_本年	
		,T1.SCDY_TRD_QTY_M          		AS			SCDY_TRD_QTY_M										--二级交易量_本月	
		,T2.SCDY_TRD_QTY_TY          		AS			SCDY_TRD_QTY_TY										--二级交易量_本年		
		,T1.S_REPUR_TRD_QTY_M       		AS			S_REPUR_TRD_QTY_M									--正回购交易量_本月		
		,T2.S_REPUR_TRD_QTY_TY       		AS			S_REPUR_TRD_QTY_TY									--正回购交易量_本年			
		,T1.R_REPUR_TRD_QTY_M       		AS			R_REPUR_TRD_QTY_M									--逆回购交易量_本月			
		,T2.R_REPUR_TRD_QTY_TY       		AS			R_REPUR_TRD_QTY_TY									--逆回购交易量_本年	
		,T1.HGT_TRD_QTY_M           		AS			HGT_TRD_QTY_M										--沪港通交易量_本月	
		,T2.HGT_TRD_QTY_TY           		AS			HGT_TRD_QTY_TY										--沪港通交易量_本年	
		,T1.SGT_TRD_QTY_M           		AS			SGT_TRD_QTY_M										--深港通交易量_本月	
		,T2.SGT_TRD_QTY_TY           		AS			SGT_TRD_QTY_TY										--深港通交易量_本年	
		,T1.STKPLG_TRD_QTY_M        		AS			STKPLG_TRD_QTY_M									--股票质押交易量_本月			
		,T2.STKPLG_TRD_QTY_TY        		AS			STKPLG_TRD_QTY_TY									--股票质押交易量_本年		
		,T1.APPTBUYB_TRD_QTY_M      		AS			APPTBUYB_TRD_QTY_M									--约定购回交易量_本月	
		,T2.APPTBUYB_TRD_QTY_TY      		AS			APPTBUYB_TRD_QTY_TY									--约定购回交易量_本年	
		,T1.OFFUND_TRD_QTY_M        		AS			OFFUND_TRD_QTY_M									--场内基金交易量_本月	
		,T2.OFFUND_TRD_QTY_TY        		AS			OFFUND_TRD_QTY_TY									--场内基金交易量_本年	
		,T1.OPFUND_TRD_QTY_M        		AS			OPFUND_TRD_QTY_M									--场外基金交易量_本月	
		,T2.OPFUND_TRD_QTY_TY        		AS			OPFUND_TRD_QTY_TY									--场外基金交易量_本年	
		,T1.BANK_CHRM_TRD_QTY_M     		AS			BANK_CHRM_TRD_QTY_M									--银行理财交易量_本月 	
		,T2.BANK_CHRM_TRD_QTY_TY     		AS			BANK_CHRM_TRD_QTY_TY								--银行理财交易量_本年 		
		,T1.SECU_CHRM_TRD_QTY_M     		AS			SECU_CHRM_TRD_QTY_M									--证券理财交易量_本月	
		,T2.SECU_CHRM_TRD_QTY_TY     		AS			SECU_CHRM_TRD_QTY_TY								--证券理财交易量_本年		
		,T1.PSTK_OPTN_TRD_QTY_M     		AS			PSTK_OPTN_TRD_QTY_M									--个股期权交易量_本月		
		,T2.PSTK_OPTN_TRD_QTY_TY     		AS			PSTK_OPTN_TRD_QTY_TY								--个股期权交易量_本年			
		,T1.CREDIT_ODI_TRD_QTY_M    		AS			CREDIT_ODI_TRD_QTY_M								--信用账户普通交易量_本月 		
		,T2.CREDIT_ODI_TRD_QTY_TY    		AS			CREDIT_ODI_TRD_QTY_TY								--信用账户普通交易量_本年 		
		,T1.CREDIT_CRED_TRD_QTY_M   		AS			CREDIT_CRED_TRD_QTY_M								--信用账户信用交易量_本月 		
		,T2.CREDIT_CRED_TRD_QTY_TY   		AS			CREDIT_CRED_TRD_QTY_TY								--信用账户信用交易量_本年 		
		,T1.COVR_BUYIN_AMT_M        		AS			COVR_BUYIN_AMT_M									--平仓买入金额_本月 	
		,T2.COVR_BUYIN_AMT_TY        		AS			COVR_BUYIN_AMT_TY									--平仓买入金额_本年 	
		,T1.COVR_SELL_AMT_M         		AS			COVR_SELL_AMT_M										--平仓卖出金额_本月 
		,T2.COVR_SELL_AMT_TY         		AS			COVR_SELL_AMT_TY									--平仓卖出金额_本年 	
		,T1.CCB_AMT_M               		AS			CCB_AMT_M											--融资买入金额_本月 
		,T2.CCB_AMT_TY               		AS			CCB_AMT_TY											--融资买入金额_本年 
		,T1.FIN_SELL_AMT_M          		AS			FIN_SELL_AMT_M										--融资卖出金额_本月 
		,T2.FIN_SELL_AMT_TY          		AS			FIN_SELL_AMT_TY										--融资卖出金额_本年 
		,T1.CRDT_STK_BUYIN_AMT_M    		AS			CRDT_STK_BUYIN_AMT_M								--融券买入金额_本月 		
		,T2.CRDT_STK_BUYIN_AMT_TY    		AS			CRDT_STK_BUYIN_AMT_TY								--融券买入金额_本年 		
		,T1.CSS_AMT_M               		AS			CSS_AMT_M											--融券卖出金额_本月 
		,T2.CSS_AMT_TY               		AS			CSS_AMT_TY											--融券卖出金额_本年 
		,T1.FIN_RTN_AMT_M           		AS			FIN_RTN_AMT_M        								--融资归还金额_本月		
		,T2.FIN_RTN_AMT_TY           		AS			FIN_RTN_AMT_TY       								--融资归还金额_本年		
		,T1.STKPLG_INIT_TRD_AMT_M   		AS			STKPLG_INIT_TRD_AMT_M 								--股票质押初始交易金额_本月		
		,T2.STKPLG_INIT_TRD_AMT_TY   		AS			STKPLG_INIT_TRD_AMT_TY 								--股票质押初始交易金额_本年		
		,T1.STKPLG_BUYB_TRD_AMT_M   		AS			STKPLG_REPO_TRD_AMT_M								--股票质押购回交易金额_本月		
		,T2.STKPLG_BUYB_TRD_AMT_TY   		AS			STKPLG_REPO_TRD_AMT_TY								--股票质押购回交易金额_本年		
		,T1.APPTBUYB_INIT_TRD_AMT_M 		AS			APPTBUYB_INIT_TRD_AMT_M 							--约定购回初始交易金额_本月			
		,T2.APPTBUYB_INIT_TRD_AMT_TY 		AS			APPTBUYB_INIT_TRD_AMT_TY							--约定购回初始交易金额_本年			
		,T1.APPTBUYB_BUYB_TRD_AMT_M 		AS			APPTBUYB_BUYB_TRD_AMT_M								--约定购回购回交易金额_本月			
		,T2.APPTBUYB_BUYB_TRD_AMT_TY 		AS			APPTBUYB_BUYB_TRD_AMT_TY							--约定购回购回交易金额_本年			
	FROM #TMP_T_EVT_TRD_M_EMP_MTH T1,#TMP_T_EVT_TRD_M_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.p_ip_client(@i_rq numeric(8))
/*客户信息表*/
begin
  -- 初始化
  delete from
    dm.t_ip_client;
  insert into dm.t_ip_client( client_id,client_name,client_gender,nationality,id_kind,id_no,risk_level,cancel_date,open_date,client_status,branch_no,corp_client_group,client_type) 
    select a.client_id, -- 客户编号    
      a.client_name, -- 客户姓名       
      d.dict_prompt, -- 性别        
      a.nationality, -- 国籍       
      e.dict_prompt, -- 证件类别       
      a.id_no, -- 证件号码,   
      c.dict_prompt, -- 客户风险等级       
      a.cancel_date, -- 销户日期       
      a.open_date, -- 开户日期       
      b.dict_prompt, -- 客户状态           
      convert(varchar,a.branch_no), -- 机构编号         
      f.dict_prompt, -- 客户分组   
      g.dict_prompt from -- 客户类型
      DBA.T_EDW_UF2_CLIENT as a left outer join
      (select subentry,
        dict_prompt from dba.T_ODS_UF2_SYSDICTIONARY where dict_entry = 1000) as b on b.subentry = a.client_status left outer join
      (select subentry,
        dict_prompt from dba.T_ODS_UF2_SYSDICTIONARY where dict_entry = 2505) as c on c.subentry = convert(varchar,a.CORP_RISK_LEVEL) left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as d on d.dict_entry = 1049 and a.client_gender = d.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as e on e.dict_entry = 1041 and a.id_kind = e.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as f on f.dict_entry = 1050 and convert(varchar,a.corp_client_group) = f.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as g on g.dict_entry = 1048 and a.organ_flag = g.subentry where
      a.load_dt = @i_rq;
  -- 主服务人
  update dm.t_ip_client as a set
    main_advisor_userid = b.user_id,
    main_advisor_username = b.user_name from
    dm.t_ip_client as a left outer join
    (select a.client_id,a.user_id,b.user_name from
      (select client_id,max(user_id) as user_id from
        dba.gt_ods_afa2_serafa_relation where
        load_dt = @i_rq and is_mainserv = '1'
        group by client_id) as a left outer join
      dba.gt_ods_afa2_xtgl_user as b on b.load_dt = @i_rq and a.user_id = b.user_id) as b on
    a.client_id = b.client_id;
  -------------------------    
  --两融资产账户
  ------------------------------------------
  update dm.t_ip_client as a set
    rzrq_asset_account = b.fund_account from
    dm.t_ip_client as a,(select fund_account,client_id,load_dt from dba.t_edw_uf2_fundaccount where load_dt = @i_rq and asset_prop = '7' and main_flag = '1') as b where
    a.client_id = b.client_id;
  -------------------------
  --主资产账户
  ------------------------------------------
  update dm.t_ip_client as a set
    main_asset_account = b.fund_account from
    dm.t_ip_client as a,(select fund_account,client_id,load_dt from dba.t_edw_uf2_fundaccount where load_dt = @i_rq and asset_prop = '0' and main_flag = '1') as b where
    a.client_id = b.client_id;
  -------------------------
  --网开渠道,网开经纪人
  ---------------------------------
  update dm.t_ip_client as a set
    net_chanel = b.broker_code,
    net_broker = b.referer_name from
    dm.t_ip_client as a,dba.T_EDW_WSKH_USER_PRESENCE as b where
    a.client_id = b.user_no and
    b.load_dt = @i_rq;
  commit work
end
GO
CREATE PROCEDURE dm.p_ip_clientinfo(@i_rq numeric(8))
on exception resume
/*个人客户信息表*/
begin
  commit work;
  -- 初始化
  delete from
    dm.t_ip_clientinfo;
  insert into dm.t_ip_clientinfo( client_id,age,birthday,home_tel,office_tel,mobile_tel,address,e_mail,degree,profession,branch_no) 
    select a.client_id, -- 客户编号,          
      null, --abs(datediff(yy,getdate(),convert(date,a.birthday))) ,-- 年龄,              
      a.birthday, -- 出生日期,          
      a.home_tel, -- 家庭电话,          
      a.office_tel, -- 单位电话,          
      a.mobile_tel, -- 手机号,            
      a.address, -- 家庭地址,           
      a.e_mail, -- 邮箱,              
      dic_degree.dict_prompt, --学历,              
      dic_prof.dict_prompt, --职业,                         
      a.branch_no from -- 营业部编号
      DBA.T_EDW_UF2_CLIENTINFO as A left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as dic_degree on dic_degree.dict_entry = 1046 and a.degree_code = dic_degree.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as dic_prof on dic_prof.dict_entry = 1047 and a.profession_code = dic_prof.subentry where
      a.LOAD_DT = @i_rq;
  --年龄
  select a.client_id,case when a.birthday >= '19000100' and a.birthday <= '20200100' then
      a.birthday
    when b.birthday >= 19000100 and b.birthday <= 20200100 then
      convert(varchar,b.birthday)
    end as birthday into #tmp_client from
    (select client_id,case when length(rtrim(id_no)) = 18 and substr(id_no,7,8) not like '%[^0-9]%' then
        substr(id_no,7,8)
      when length(rtrim(id_no)) = 15 and substr(id_no,7,6) not like '%[^0-9]%' then '19' || 
        substr(id_no,7,6)
      end as birthday from dba.T_EDW_UF2_CLIENT where
      load_dt = @i_rq) as a left outer join
    dba.T_EDW_UF2_CLIENTINFO as b on a.client_id = b.client_id and b.load_dt = @i_rq;
  update dm.t_ip_clientinfo as a set
    age = case when substr(b.birthday,5,4) <= substr(convert(varchar,getdate(*),112),5,4) then
      convert(integer,substr(convert(varchar,getdate(*),112),1,4))-convert(integer,substr(b.birthday,1,4))
    else convert(integer,substr(convert(varchar,getdate(*),112),1,4))-convert(integer,substr(b.birthday,1,4))-1
    end from
    dm.t_ip_clientinfo as a,#tmp_client as b where
    a.client_id = b.client_id;
  commit work
end
GO
CREATE PROCEDURE dm.p_ip_organinfo(@i_rq numeric(8))
on exception resume
/*机构客户信息表*/
begin
  -- 初始化
  delete from
    dm.t_ip_organinfo;
  insert into dm.t_ip_organinfo( client_id,branch_no,organ_name,instrepr_name,organ_code,sale_licence,company_kind,register_fund,register_money_type,contract_person,e_mail,nationality,address,business_range) 
    select a.client_id, --客户编号,
      a.branch_no, --营业部编号,
      null, --a.organ_name机构名称,
      a.instrepr_name, --法人代表,
      a.organ_code, --组织机构代码,
      business_licence, --a.sale_licence营业执照,
      a.company_kind, --企业性质,
      a.register_fund, --注册资本,
      a.register_money_type, --注册资本币种,
      a.relation_name, --a.contract_person联系人,
      a.e_mail, --电子邮件,
      null, --a.nationality国籍,
      a.address, --地址,
      industry_range from --a.business_range经营范围      
      DBA.T_EDW_UF2_ORGANINFO as A where
      load_dt = @i_rq;
  ------机构名称-------------    
  update dm.t_ip_organinfo as a set
    organ_name = b.client_name,
    nationality = b.nationality from
    dm.t_ip_organinfo as a,(select client_id,client_name,nationality from dba.T_EDW_UF2_CLIENT where load_dt = @i_rq) as b where
    a.client_id = b.client_id;
  commit work
end
GO
CREATE PROCEDURE dm.P_PUB_CUST(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)

BEGIN 
  
  /******************************************************************
  程序功能: 客户信息维表
  编写者: DCY
  创建日期: 2017-11-14
  简介：清洗客户包含个人客户和机构客户的各个常用的属性信息
  *********************************************************************
  修订记录：   修订日期    修订人     修改内容简要说明
               20180104     dcy      将DBA.T_ODS_UF2_FUNDACCOUNT替换为 DBA.T_EDW_UF2_FUNDACCOUNT，防止历史回洗数据
			   20180129     dcy      将年，月，客户编号三个字段合并年月客户编号，（董要求）
			   20180207     dcy      排除"总部专用账户"
			   20180320     dcy		 新增 IF_PROD_NEW_CUST IS '是否产品新客户'
			   20180403     dcy      对客户姓名，id ，手机号，邮箱等进行脱敏
  *********************************************************************/
  DECLARE @V_NIAN VARCHAR(4);
  DECLARE @V_YUE VARCHAR(2);
  DECLARE @V_QUNIAN VARCHAR(4); --去年年份
  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
	
 --PART0 删除要回洗的数据
  DELETE FROM DM.T_PUB_CUST WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
 --变量赋值    
  SET @V_NIAN=(SELECT NIAN FROM DBA.T_DDW_D_RQ WHERE RQ = @V_BIN_DATE);
  SET @V_YUE=(SELECT YUE FROM DBA.T_DDW_D_RQ WHERE RQ = @V_BIN_DATE);
  SET @V_QUNIAN=(SELECT MAX(NIAN) FROM DBA.T_DDW_D_RQ WHERE NIAN < @V_NIAN);

 --PART1 下面生成几个临时表  
	--1,计算有效户，生成临时表
  SELECT 
  ZJZH
  ,SUM(LJJYL_M) AS LJJYL
  ,MAX(ZZCH_YRJ) AS ZCFZ INTO #TEMP_VALID_CUST 
  FROM(
		SELECT NIAN,YUE,ZJZH,
		  GJJYL_M+XYJYL_M+PTJYL_M+QQJYL_M AS LJJYL_M --累计交易量
		  ,ZZC_YRJ+QQSZ_YRJ AS ZZCH_YRJ 
		  FROM DBA.TMP_DDW_KHQJT_M_D AS A 
		  WHERE NIAN || YUE >= @V_QUNIAN || @V_YUE AND NIAN || YUE < @V_NIAN || @V_YUE --一年期限
		UNION
		SELECT @V_NIAN AS NIAN
		,@V_YUE AS YUE
		,FUND_ACCOUNT AS ZJZH
		,GJJYL_M+XYJYL_M+PTJYL_M+QQJYL_M AS LJJYL_M
		,ZZC_YRJ+QQSZ_YRJ AS ZZCH_YRJ
		FROM DBA.T_DDW_CLIENT_INDEX_HIGH_PRIORITY
		WHERE RQ = @V_BIN_DATE
	   ) AS A
    GROUP BY A.ZJZH;
	COMMIT;
	
	--2,出生日期
   SELECT A.CLIENT_ID
    ,CASE WHEN A.BIRTHDAY>='19000100' AND A.BIRTHDAY<='20200100' THEN A.BIRTHDAY 
          WHEN B.BIRTHDAY>=19000100 AND B.BIRTHDAY<=20200100 THEN CONVERT(VARCHAR,B.BIRTHDAY)
		  END BIRTHDAY 
    INTO #TMP_AGE 
    FROM (SELECT CLIENT_ID, CASE WHEN LENGTH(RTRIM(ID_NO))=18  AND SUBSTR(ID_NO,7,8) NOT LIKE '%[^0-9]%' THEN SUBSTR(ID_NO,7,8) 
                              WHEN  LENGTH(RTRIM(ID_NO))=15 AND SUBSTR(ID_NO,7,6) NOT LIKE '%[^0-9]%' THEN '19'||SUBSTR(ID_NO,7,6) 
							  END BIRTHDAY 
		   FROM DBA.T_EDW_UF2_CLIENT 
		   WHERE LOAD_DT=@V_BIN_DATE) A
    LEFT JOIN DBA.T_EDW_UF2_CLIENTINFO B ON A.CLIENT_ID=B.CLIENT_ID  AND B.LOAD_DT=@V_BIN_DATE;
	COMMIT;
	
    --3,主服务人信息
	SELECT A.CLIENT_ID, A.USER_ID, B.USER_NAME      --下面用来得到主服务人
	INTO #OAS
    FROM(
		SELECT CLIENT_ID, MAX(USER_ID) AS USER_ID
		FROM DBA.GT_ODS_AFA2_SERAFA_RELATION
		WHERE LOAD_DT=@V_BIN_DATE AND IS_MAINSERV='1'
		GROUP BY CLIENT_ID
      	) A
    LEFT JOIN DBA.GT_ODS_AFA2_XTGL_USER B ON B.LOAD_DT=@V_BIN_DATE AND A.USER_ID=B.USER_ID;
	COMMIT;
	
    --4,网开渠道和网开渠道    有重复值
    SELECT MAX(B.ACTIVITY_NAME)ACTIVITY_NAME, MAX(A.ACTIVITY_ID)ACTIVITY_ID,A.FUND_ACCOUNT   --网开渠道和网开渠道    
	INTO #TCO
	FROM DBA.T_EDW_LC_T_CLIENT_OUTSYSCLIENT A
	LEFT JOIN DBA.T_EDW_CF_T_INFO_ACTIVITY  B ON A.ACTIVITY_ID=B.ACTIVITY_ID AND B.LOAD_DT = @V_BIN_DATE
	WHERE A.LOAD_DT=@V_BIN_DATE AND FUND_ACCOUNT !=''
	GROUP BY A.FUND_ACCOUNT;
	COMMIT;

	
 --PART2 将每日采集的数据放入临时表
 
	SELECT
	 OUC.CLIENT_ID AS CUST_ID  --客户编码
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --年
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --月
	,OUF.FUND_ACCOUNT  AS MAIN_CPTL_ACCT    --主资金账号（普通账户）
	,DOH.PK_ORG  AS WH_ORG_ID               --仓库机构编码 
	,CONVERT(VARCHAR,OUC.BRANCH_NO) AS HS_ORG_ID  --恒生机构编码
	,DOH.HR_NAME AS BRH_NAME        --营业部名称
	,DOH.FATHER_BRANCH_NAME_ROOT AS SEPT_CORP_NAME --分公司名称
	,OUC.CLIENT_NAME AS CUST_NAME    --客户名称 
	,OUC.ORGAN_FLAG  AS CUST_TYPE    --客户类型
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUC.ORGAN_FLAG) 
	  AND OUS.DICT_ENTRY=1048) AS CUST_TYPE_NAME   --客户类型名称
	,CONVERT(VARCHAR,OUF.CLIENT_GROUP) AS CUST_GROUP  --客户分组
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUF.CLIENT_GROUP) AND OUS.DICT_ENTRY=1051) AS CUST_GROUP_NAME   --客户分组名称  
	,CONVERT(VARCHAR,OUC.CORP_RISK_LEVEL) AS CUST_RISK_RAK         --客户风险等级 
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
      WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUC.CORP_RISK_LEVEL) AND OUS.DICT_ENTRY=2505) AS CUST_RISK_RAK_NAME   --客户风险等级名称  
	,OUC.CLIENT_STATUS AS CUST_STAT	--客户状态  
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.CLIENT_STATUS AND OUS.DICT_ENTRY=1000) AS CUST_STAT_NAME    --客户状态名称 
    ,OUC.CLIENT_GENDER AS GENDER --性别
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.CLIENT_GENDER AND OUS.DICT_ENTRY=1049) AS GENDER_NAME    --性别名称
    ,CASE WHEN SUBSTR(TA.BIRTHDAY,5,4)<=SUBSTR(CONVERT(VARCHAR,GETDATE(),112),5,4)
              THEN CONVERT(INT,SUBSTR(CONVERT(VARCHAR,GETDATE(),112),1,4))-CONVERT(INT,SUBSTR(TA.BIRTHDAY,1,4))
              ELSE CONVERT(INT,SUBSTR(CONVERT(VARCHAR,GETDATE(),112),1,4))-CONVERT(INT,SUBSTR(TA.BIRTHDAY,1,4))-1
                 END  AS AGE  --年龄
	,OUCI.DEGREE_CODE AS EDU --学历
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUCI.DEGREE_CODE AND OUS.DICT_ENTRY=1046) AS EDU_NAME    --学历名称
	,OUC.NATIONALITY  AS NATI --国籍 
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.NATIONALITY AND OUS.DICT_ENTRY=1040) AS NATI_NAME    --国籍名称
	,OUC.ID_KIND AS ID_TYPE   --证件类别
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.ID_KIND AND OUS.DICT_ENTRY=1041) AS ID_TYPE_NAME    --证件类别名称
	,OUC.ID_NO        --证件号码
	,OAS.USER_ID AS MAIN_SERV_PSN_ID     --主服务人编码
	,OAS.USER_NAME AS MAIN_SERV_PSN_NAME   --主服务人名称
	,CONVERT(VARCHAR,TCO.ACTIVITY_ID) AS NET_OPEN_CHN --网开渠道  
	,CASE WHEN TCO.FUND_ACCOUNT IS NOT NULL THEN 1 ELSE 0 END AS IF_NET_OPEN       --是否网开
	,TCO.ACTIVITY_NAME AS CHN_NAME --渠道名称
	,WUP.REFERER_NAME AS NET_OPEN_BROK--网开经纪人
	,OUCI.MOBILE_TEL AS MOB_NO --手机号
	,CASE WHEN TBR.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END AS IF_BROK_CUST      --是否经纪人客户
	,CASE WHEN TBR2.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END AS IF_BROK_QUAF_CUST --是否经纪人合格客户 
	,CASE WHEN OUF.CLIENT_GROUP IN (12,23,26,27,29,31,32,33,34,35,37,7,5) THEN 1 ELSE 0 END AS IF_PROD_CUST      --是否产品客户
	,CASE WHEN TVC.LJJYL >= 2000 OR TVC.ZCFZ >= 10000 THEN 1 ELSE 0 END AS IF_VLD     --是否有效
	,OUF.OPEN_DATE AS TE_OACT_DT   --最早开户日期
	,OUF.CANCEL_DATE AS CLOS_DT --销户日期
	,@V_BIN_DATE  AS LOAD_DT  --清洗日期
	,CASE WHEN TAS.ZJGMCPRQ< CONVERT(NUMERIC(10),CONVERT(VARCHAR,DATEADD(YEAR,-3,CONVERT(DATE,@V_BIN_DATE||'',112)),112)) THEN 1 ELSE 0 END AS IF_PROD_NEW_CUST --是否产品新客户:近36月没有购买产品
	INTO #TMP_CUST
	
	FROM DBA.T_EDW_UF2_CLIENT OUC   --所有客户信息
	--LEFT JOIN DBA.T_ODS_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID  AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --普通账户主资金账号
	LEFT JOIN DBA.T_edw_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID AND OUF.LOAD_DT=@V_BIN_DATE AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --普通账户主资金账号
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL    --有重复值
	LEFT JOIN DBA.T_edw_UF2_CLIENTINFO OUCI ON OUC.CLIENT_ID=OUCI.CLIENT_ID AND OUCI.LOAD_DT=@V_BIN_DATE   --获取个人客户信息
	LEFT JOIN #OAS OAS ON OUC.CLIENT_ID=OAS.CLIENT_ID
	LEFT JOIN #TCO TCO ON OUF.FUND_ACCOUNT=TCO.FUND_ACCOUNT
	LEFT JOIN DBA.T_EDW_WSKH_USER_PRESENCE WUP ON OUC.CLIENT_ID=WUP.USER_NO AND WUP.LOAD_DT=@V_BIN_DATE AND WUP.USER_NO !=''  --获取网开经纪人
	LEFT JOIN DBA.T_EDW_BRK_T_BROK_RELATION TBR ON OUC.CLIENT_ID=TBR.CLIENT_ID AND TBR.LOAD_DT = @V_BIN_DATE AND TBR.RELATION_STATUS ='1'  --是否经纪人客户
	LEFT JOIN DBA.T_EDW_BRK_T_BROK_RELATION TBR2 ON OUC.CLIENT_ID=TBR2.CLIENT_ID AND TBR2.LOAD_DT = @V_BIN_DATE AND TBR2.RELATION_STATUS ='1' AND TBR2.RELATION_TYPE='4'
	LEFT JOIN #TEMP_VALID_CUST TVC ON OUF.FUND_ACCOUNT=TVC.ZJZH  --是否有效户
	LEFT JOIN #TMP_AGE TA ON OUC.CLIENT_ID=TA.CLIENT_ID  --年龄
	LEFT JOIN DBA.T_AFA_SCWY TAS ON OUF.FUND_ACCOUNT=TAS.ZJZH AND TAS.RQ=@V_BIN_DATE  --是否产品新客户:近36月没有购买产品
    WHERE OUC.LOAD_DT=@V_BIN_DATE 
	;
	COMMIT;


	--PART2.2 将客户姓名中的/替换掉
	UPDATE #TMP_CUST
	SET 
	    --CUST_NAME=REPLACE(REPLACE(REPLACE(CUST_NAME,'/',''),'\',''),'|',''),     --客户名称 ,变灰色是由于\引起，不会影响SQL运行
	    --MOB_NO=REPLACE(REPLACE(REPLACE(MOB_NO,'/',''),'\',''),'|',''),     
	    --main_serv_psn_name=REPLACE(REPLACE(REPLACE(main_serv_psn_name,'/',''),'\',''),'|','')
		 CUST_NAME=SUBSTR(CUST_NAME,1,0)||'***'   --姓名脱敏
		,MOB_NO=SUBSTR(MOB_NO,1,3)||'********'   --手机号脱敏
		,MAIN_SERV_PSN_NAME=SUBSTR(MAIN_SERV_PSN_NAME,1,0)||'********'   --主服务人名称脱敏
		,ID_NO=SUBSTR(ID_NO,1,0)||'***********'   --证件号码脱敏
	;
	COMMIT;
	

	
	--3 最后将当天新增的客户插入进来
	INSERT INTO DM.T_PUB_CUST
	(
	 CUST_ID           --客户编码  
	,YEAR              --年
	,MTH               --月
	,MAIN_CPTL_ACCT    --主资金账号  
	,WH_ORG_ID         --仓库机构编码
	,HS_ORG_ID         --恒生机构编码
	,BRH_NAME          --营业部名称 
	,SEPT_CORP_NAME   --分公司名称  
	,CUST_NAME        --客户名称 
	,CUST_TYPE        --客户类型
	,CUST_TYPE_NAME   --客户类型名称
	,CUST_GROUP       --客户分组 
	,CUST_GROUP_NAME  --客户分组名称 
	,CUST_RISK_RAK     --客户风险等级 
	,CUST_RISK_RAK_NAME   --客户风险等级名称 
	,CUST_STAT         --客户状态 
	,CUST_STAT_NAME    --客户状态名称
	,GENDER            --性别 
	,GENDER_NAME       --性别名称
	,AGE               --年龄 
	,EDU               --学历 
	,EDU_NAME          --学历名称
	,NATI              --国籍 
	,NATI_NAME         --国籍名称
	,ID_TYPE           --证件类别 
	,ID_TYPE_NAME      --证件类别名称
	,ID_NO             --证件号码 
	,MAIN_SERV_PSN_ID  --主服务人编码 
	,MAIN_SERV_PSN_NAME  --主服务人名称 
	,NET_OPEN_CHN      --网开渠道 
	,IF_NET_OPEN       --是否网开 
	,CHN_NAME          --渠道名称 
	,NET_OPEN_BROK     --网开经纪人 
	,MOB_NO            --手机号 
	,IF_BROK_CUST      --是否经纪人客户 
	,IF_BROK_QUAF_CUST --是否经纪人合格客户 
	,IF_PROD_CUST      --是否产品客户 
	,IF_VLD            --是否有效 
	,TE_OACT_DT        --最早开户日期 
	,CLOS_DT           --销户日期 
	,LOAD_DT           --清洗日期 
	,YEAR_MTH_CUST_ID
	,IF_PROD_NEW_CUST
	)
	SELECT 
	 CUST_ID           --客户编码  
	,YEAR              --年
	,MTH               --月
	,MAIN_CPTL_ACCT    --主资金账号  
	,WH_ORG_ID         --仓库机构编码
	,HS_ORG_ID         --恒生机构编码
	,BRH_NAME          --营业部名称 
	,SEPT_CORP_NAME   --分公司名称  
	,CUST_NAME        --客户名称 
	,CUST_TYPE        --客户类型
	,CUST_TYPE_NAME   --客户类型名称
	,CUST_GROUP       --客户分组 
	,CUST_GROUP_NAME  --客户分组名称 
	,CUST_RISK_RAK     --客户风险等级 
	,CUST_RISK_RAK_NAME   --客户风险等级名称 
	,CUST_STAT         --客户状态 
	,CUST_STAT_NAME    --客户状态名称
	,GENDER            --性别 
	,GENDER_NAME       --性别名称
	,AGE               --年龄 
	,EDU               --学历 
	,EDU_NAME          --学历名称
	,NATI              --国籍 
	,NATI_NAME         --国籍名称
	,ID_TYPE           --证件类别 
	,ID_TYPE_NAME      --证件类别名称
	,ID_NO             --证件号码 
	,MAIN_SERV_PSN_ID  --主服务人编码 
	,MAIN_SERV_PSN_NAME  --主服务人名称 
	,NET_OPEN_CHN      --网开渠道 
	,IF_NET_OPEN       --是否网开 
	,CHN_NAME          --渠道名称 
	,NET_OPEN_BROK     --网开经纪人 
	,MOB_NO            --手机号 
	,IF_BROK_CUST      --是否经纪人客户 
	,IF_BROK_QUAF_CUST --是否经纪人合格客户 
	,IF_PROD_CUST      --是否产品客户 
	,IF_VLD            --是否有效 
	,TE_OACT_DT        --最早开户日期 
	,CLOS_DT           --销户日期 
	,LOAD_DT           --清洗日期 
	,year||mth||CUST_ID AS YEAR_MTH_CUST_ID  --20180129新增
	,IF_PROD_NEW_CUST  --是否产品新客户
	FROM #TMP_CUST  TC
	WHERE HS_ORG_ID NOT IN ('5','55','51','44','9999')--20180207 新增：排除"总部专用账户"
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_CUST TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_CUST TO xydc
GO
CREATE PROCEDURE dm.P_PUB_CUST_LIMIT_M_D(IN @v_date int)
begin 
  
  /******************************************************************
  程序功能: 客户权限表(月存储日更新)
  编写者: 张琦
  创建日期: 2017-12-06
  简介：按月记录客户权限
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  
  declare @v_year varchar(4);		-- 年份
  declare @v_month varchar(2);	-- 月份
  declare @v_begin_trad_date int;	-- 本月开始交易日
  declare @v_sy varchar(6);
  
	commit;
	
	set @v_year = substring(convert(varchar,@v_date),1,4);
	set @v_month = substring(convert(varchar,@v_date),5,2);
	set @v_begin_trad_date = (select min(RQ) from dba.t_ddw_d_rq where sfjrbz='1' and nian=@v_year and yue=@v_month);
    set @v_sy=(select max(nian||yue) from dba.t_ddw_d_rq where nian||yue<@v_year||@v_month);

	DELETE FROM DM.T_PUB_CUST_LIMIT_M_D WHERE "YEAR"=@v_year and MTH=@v_month;
	
	INSERT INTO DM.T_PUB_CUST_LIMIT_M_D(CUST_ID,"YEAR",MTH,OCCUR_DT,MAIN_CPTL_ACCT)
	SELECT a.client_id as CUST_ID
	    ,@v_year as "YEAR"
	    ,@v_month as MTH
	    ,@v_date as OCCUR_DT
	    ,b.MAIN_CPTL_ACCT
	FROM DBA.T_EDW_UF2_CLIENT a
	LEFT JOIN (
	    SELECT CLIENT_ID, MAX(FUND_ACCOUNT) AS MAIN_CPTL_ACCT
	    FROM DBA.T_EDW_UF2_FUNDACCOUNT
	    WHERE LOAD_DT=@v_date
	    AND MAIN_FLAG='1' AND ASSET_PROP='0'
	    GROUP BY CLIENT_ID
	) b on a.CLIENT_ID=b.CLIENT_ID
	WHERE a.LOAD_DT=@v_date;

	-- 证券账户数
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET SECU_ACCTS = COALESCE(b.SECU_ACCTS,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT CLIENT_ID, COUNT(DISTINCT STOCK_ACCOUNT) as SECU_ACCTS
	    FROM DBA.t_edw_uf2_stockholder
	    WHERE LOAD_DT=@v_date
	    GROUP BY CLIENT_ID
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 参与业务-本月
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_STK_BIS = CASE WHEN COALESCE(gpyw_cnt,0)>=1 THEN 1 ELSE 0 END     -- 是否参与股票业务
	    ,IF_BOND_BIS = CASE WHEN COALESCE(zqyw_cnt,0)>=1 THEN 1 ELSE 0 END    -- 是否参与债券业务
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT b.CLIENT_ID
	        ,SUM(CASE WHEN MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	            AND stock_type_cd IN ('10', 'A1', '17', '18')
	            THEN 1 ELSE 0 END) AS gpyw_cnt
	        ,SUM(CASE WHEN MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	           AND stock_type_cd IN ('12', '13', '14')
	           THEN 1 ELSE 0 END) AS zqyw_cnt
	    FROM dba.t_edw_t05_order_jour a
	    left join dba.T_ODS_UF2_FUNDACCOUNT b on a.fund_acct=b.FUND_ACCOUNT
	    WHERE load_dt between @v_begin_trad_date AND @v_date
	    GROUP BY b.CLIENT_ID
	) b on a.cust_id=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与股票业务_累计
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_STK_BIS_GT = CASE WHEN b.FUND_ACCT IS NOT NULL THEN 1 ELSE 0 END      -- 是否参与股票业务_累计
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT FUND_ACCT
	    FROM dba.t_edw_t05_order_jour a
	    WHERE load_dt <= @v_date
	    AND MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	    AND stock_type_cd IN ('10', 'A1', '17', '18')
	) b on a.MAIN_CPTL_ACCT=b.FUND_ACCT
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与债券业务_累计
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_BOND_BIS_GT = CASE WHEN b.FUND_ACCT IS NOT NULL THEN 1 ELSE 0 END      -- 是否参与股票业务_累计
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT FUND_ACCT
	    FROM dba.t_edw_t05_order_jour a
	    WHERE load_dt <= @v_date
	    AND MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	    AND stock_type_cd IN ('12', '13', '14')
	) b on a.MAIN_CPTL_ACCT=b.FUND_ACCT
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否融资融券客户
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_CREDIT_CUST = CASE WHEN b.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT CLIENT_ID
	    FROM DBA.T_EDW_RZRQ_FUNDACCOUNT
	    WHERE LOAD_DT=@v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- TODO:是否融资融券有效客户 IF_CREDIT_EFF_CUST
	-- TODO:是否新增融资融券有效户 IF_NA_CREDIT_EFF_ACT

	-- 融资融券授信额度
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET CREDIT_CRED_QUO = coalesce(b.xyzhsxed,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    select convert(varchar,client_id) as client_id,
	        case when total_max_quota > 0 then total_max_quota
	        else finance_max_quota+shortsell_max_quota
	        end as xyzhsxed 
	    from dba.t_edw_rzrq_contract 
	    where load_dt = @v_date and contract_status = '0'
	) b on a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 融资融券开通日期、融资融券销户日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET CREDIT_OPEN_DT = COALESCE(b.OPEN_DATE,0)
	    ,CREDIT_CLOS_DT = COALESCE(b.CANCEL_DATE,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN DBA.t_edw_rzrq_client b ON b.load_dt=@v_date AND a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- TODO:融资融券有效户日期 CREDIT_EFF_ACT_DT

	-- 是否参与融资融券信用业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_CREDIT_CRED_BIS = CASE WHEN b.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT CONVERT(VARCHAR, client_id) AS CLIENT_ID 
	     FROM dba.t_edw_rzrq_hisdeliver
	    WHERE business_flag in (4211, 4212, 4213, 4214, 4215, 4216)   -- 信用交易
	      AND load_dt BETWEEN @v_begin_trad_date AND @v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与融资融券信用业务_累计
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_CREDIT_CRED_BIS_GT = CASE WHEN b.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT CONVERT(VARCHAR, client_id) AS CLIENT_ID 
	     FROM dba.t_edw_rzrq_hisdeliver
	    WHERE business_flag in (4211, 4212, 4213, 4214, 4215, 4216)   -- 信用交易
	      AND load_dt <= @v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否约定购回客户（开通约定购回权限）、是否报价回购客户、是否股票质押客户、是否大宗交易客户
	-- 是否沪港通客户 是否深港通客户 是否创业板客户 是否三板客户
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_CUST = coalesce(b.right_ydsgh,0)
	    ,IF_REPQ_CUST = coalesce(b.right_bjhg,0) 
	    ,IF_STKPLG_CUST = coalesce(b.right_gpzyhg,0) 
	    ,IF_BGDL_CUST = coalesce(b.right_dzjy,0) 
	    ,IF_HGT_CUST = coalesce(b.right_hgt,0)
	    ,IF_SGT_CUST = coalesce(b.right_sgt,0) 
	    ,IF_GEM_CUST = coalesce(b.right_cyb,0) 
	    ,IF_SB_CUST = coalesce(b.right_sb,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
	    SELECT CLIENT_ID
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%l%' THEN 1 ELSE 0 END) AS right_ydsgh
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%k%' THEN 1 ELSE 0 END) AS right_bjhg
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%t%' THEN 1 ELSE 0 END) AS right_gpzyhg
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%#%' THEN 1 ELSE 0 END) AS right_dzjy
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%z%' THEN 1 ELSE 0 END) AS right_hgt
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%c%' THEN 1 ELSE 0 END) AS right_sgt
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%j%' THEN 1 ELSE 0 END) AS right_cyb
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%a%' THEN 1 ELSE 0 END) AS right_sb
	    FROM DBA.T_EDW_UF2_STOCKHOLDER 
	    WHERE load_dt=@v_date
	    GROUP BY CLIENT_ID
	) b on a.cust_id=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- 是否参与约定购回业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_BIS = case when b.khbh_hs is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT distinct khbh_hs
	    FROM DBA.t_ddw_ydsgh_d
	    WHERE csjyje + ghjyje > 0
	    and rq between @v_begin_trad_date and @v_date
	) b on a.CUST_ID=b.khbh_hs
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与约定购回业务_累计
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_BIS = case when b.khbh_hs is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT distinct khbh_hs
	    FROM DBA.t_ddw_ydsgh_d
	    WHERE csjyje + ghjyje > 0
	) b on a.CUST_ID=b.khbh_hs
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 约定购回授信额度 & 股票质押授信额度
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET APPTBUYB_CRED_QUO = COALESCE(b.xsed_ydsgh,0)
	    ,STKPLG_CRED_QUO = COALESCE(b.xsed_gpzy,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    select CLIENT_ID
	        ,SUM(CASE WHEN EN_CBPBUSI_TYPE='002' THEN ARP_CREDIT_QUOTA ELSE 0 END) AS xsed_ydsgh
	        ,SUM(CASE WHEN EN_CBPBUSI_TYPE='004' THEN ARP_CREDIT_QUOTA ELSE 0 END) AS xsed_gpzy
	    from dba.GT_ODS_HS06_ARPCRQUOTA
	    WHERE load_dt=@v_date
	    GROUP BY CLIENT_ID
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 约定购回开通日期 报价回购开通日期 股票质押开通日期 创业板开通日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET APPTBUYB_OPEN_DT = COALESCE(b.ktrq_ydsgh,0)
	    ,REPQ_OPEN_DT = COALESCE(b.ktrq_bjhg,0)
	    ,STKPLG_OPEN_DT = COALESCE(b.ktrq_gpzy,0)
	    ,GEM_OPEN_DT = coalesce(b.ktrq_cyb,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN(
	    SELECT CLIENT_ID
	        , MAX(CASE WHEN BUSINESS_FLAG=1444 THEN INIT_DATE ELSE 0 END) AS ktrq_ydsgh
	        , MAX(CASE WHEN BUSINESS_FLAG=1443 THEN INIT_DATE ELSE 0 END) AS ktrq_bjhg
	        , MAX(CASE WHEN BUSINESS_FLAG=1477 THEN INIT_DATE ELSE 0 END) AS ktrq_gpzy
	        , MAX(CASE WHEN BUSINESS_FLAG in (1424,1425) THEN INIT_DATE ELSE 0 END) AS ktrq_cyb
	    FROM (
	        SELECT CLIENT_ID, INIT_DATE, BUSINESS_FLAG
	        FROM DBA.GT_ODS_ZHXT_HIS_STOCKHOLDERJOUR
	        WHERE load_dt<=@v_date
	        UNION
	        SELECT CLIENT_ID, INIT_DATE, BUSINESS_FLAG
	        FROM DBA.T_EDW_UF2_HIS_OFSTOCKHOLDERJOUR
	        WHERE load_dt<=@v_date
	    ) t
	    GROUP BY t.client_id
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否存在约定购回签约（当前是否有签约）
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_SUBSCR = case when b.client_id is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT client_id
	    FROM dba.t_edw_arpcontract 
	    WHERE load_dt=@v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与报价回购业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_REPQ_BIS = case when b.zjzh is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT distinct zjzh
	    FROM dba.t_ddw_bjhg_d 
	    WHERE rq<=@v_date
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- 是否参与债券逆回购业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_BOND_R_REPUR_BIS = case when b.zjzh is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT fund_acct AS zjzh
	     FROM dba.t_edw_t05_trade_jour
	    WHERE load_dt BETWEEN @v_begin_trad_date AND @v_date
	      AND busi_cd = '3703'
	    GROUP BY zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与国债逆回购业务_累计
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_TREA_R_REPUR_BIS_GT = case when b.zjzh is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT fund_acct AS zjzh
	     FROM dba.t_edw_t05_trade_jour
	    WHERE load_dt<=@v_date
	      AND busi_cd = '3703'
	    GROUP BY zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- 股票质押首次交易日期 & 最近质押申请日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET STKPLG_FST_TRD_DT = COALESCE(b.gpzyscjysj,0)
	    ,RCT_PLG_APP_DT = COALESCE(b.zjzysqrq,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT zjzh
	        , MIN(qyrq) gpzyscjysj
	        , MAX(qyrq) zjzysqrq
	    FROM DBA.t_ddw_gpzyhg_ht_d
	    GROUP BY zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- TODO:大宗交易开通日期

	-- 是否参与沪港通业务 是否参与深港通业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_HGT_BIS = coalesce(b.cyyw_hgt,0)
		,IF_SGT_BIS = coalesce(b.cyyw_sgt,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT fund_acct as zjzh
	        ,max(case when market_type_cd='0G' then 1 else 0 end) as cyyw_hgt
	      	,max(case when market_type_cd='0S' then 1 else 0 end) as cyyw_sgt
	    FROM dba.T_EDW_T05_TRADE_JOUR 
	    WHERE load_dt between @v_begin_trad_date and @v_date
	    group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 沪港通开通日期 深港通开通日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET HGT_OPEN_DT =  COALESCE(b.ktsj_hgt,0)
		,SGT_OPEN_DT = COALESCE(b.ktsj_sgt,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT FUND_ACCOUNT
	        ,MAX(CASE WHEN EXCHANGE_TYPE='G' THEN open_date ELSE 0 END) as ktsj_hgt
	      	,MAX(CASE WHEN EXCHANGE_TYPE='S' THEN open_date ELSE 0 END) as ktsj_sgt
	    FROM DBA.T_EDW_UF2_CBSSTOCKHOLDER
	    WHERE LOAD_DT=@v_date
	    GROUP BY FUND_ACCOUNT
	) b ON a.MAIN_CPTL_ACCT=b.FUND_ACCOUNT
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否有沪A权限 是否有深A权限 上海证券账户开通日期 深圳证券账户开通日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_HA_RIGH =  COALESCE(b.qx_ha,0)
		,IF_SA_RIGH = COALESCE(b.qx_sa,0)
		,SH_SECU_ACC_OPEN_DT = COALESCE(b.ktrq_sh,0)
		,SZ_SECU_ACC_OPEN_DT = COALESCE(b.ktrq_sz,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT CLIENT_ID
	        ,MAX(CASE WHEN EXCHANGE_TYPE='1' then 1 else 0 end) as qx_ha
	      	,MAX(CASE WHEN EXCHANGE_TYPE='2' then 1 else 0 end) as qx_sa
	      	,MAX(CASE WHEN EXCHANGE_TYPE='1' THEN OPEN_DATE ELSE 0 END) AS ktrq_sh
	      	,MAX(CASE WHEN EXCHANGE_TYPE='2' THEN OPEN_DATE ELSE 0 END) AS ktrq_sz
	    FROM DBA.T_EDW_UF2_STOCKHOLDER
	    WHERE LOAD_DT=@v_date and HOLDER_STATUS='0'
	    GROUP BY CLIENT_ID
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;



	-- 是否基金账户客户
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_ACC_CUST = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_edw_OFSTOCKHOLDER
		where load_dt=@v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- TODO:是否持有基金定投

	-- 是否参与基金定投业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_CASTSL_BIS = case when b.zjzh is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select distinct fund_acct as zjzh
			from dba.T_EDW_T05_TRADE_JOUR
			where busi_cd='5139' 
			and load_dt between @v_begin_trad_date and @v_date
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与基金专户业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_SPACCT_BIS = coalesce(b.cyyw_jjzh_m,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select a.zjzh
				,MAX(CASE WHEN b.lx = '基金专户'    THEN 1 ELSE 0 END) AS cyyw_jjzh_m
			from dba.t_ddw_xy_jjzb_d a
			left join (
					SELECT jjdm,lx
					FROM dba.t_ddw_d_jj
					WHERE nian || yue = (SELECT MAX(nian || yue)
						FROM dba.t_ddw_d_jj
						WHERE nian || yue < CONVERT(VARCHAR(6), FLOOR(@v_date / 100)))
					) b ON a.jjdm = b.jjdm
			where rq between @v_begin_trad_date and @v_date
			group by a.zjzh
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- 是否参与基金专户业务_累计
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_SPACCT_BIS_GT = coalesce(b.cyyw_jjzh,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select a.zjzh
				,MAX(CASE WHEN b.lx = '基金专户'    THEN 1 ELSE 0 END) AS cyyw_jjzh
			from dba.t_ddw_xy_jjzb_d a
			left join (
					SELECT jjdm,lx
					FROM dba.t_ddw_d_jj
					WHERE nian || yue = (SELECT MAX(nian || yue)
						FROM dba.t_ddw_d_jj
						WHERE nian || yue < CONVERT(VARCHAR(6), FLOOR(@v_date / 100)))
					) b ON a.jjdm = b.jjdm
			where rq <= @v_date
			group by a.zjzh
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否个股期权客户
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_PSTK_OPTN_CUST = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_EDW_UF2_OPTFUNDACCOUNT
		where load_dt=@v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 个股期权开通日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET PSTK_OPTN_OPEN_DT = coalesce(b.open_date,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
		select client_id
			,open_date
		FROM dba.T_EDW_UF2_FUNDACCOUNT 
		WHERE LOAD_DT=@v_date 
		and ASSET_PROP='B' and FUNDACCT_STATUS='0'
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 个股期权首次交易日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set PSTK_OPTN_FST_TRD_DT = coalesce(b.qqscjyrq,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select client_id, min(load_dt) as qqscjyrq 
			from (
				select load_dt, client_id
				from dba.GT_ODS_HS08OPT_HIS_OPTDELIVER
				where load_dt<=@v_date
				union
				select load_dt, client_id
				from dba.T_EDW_UF2_HIS_OPTDELIVER
				where load_dt<=@v_date
			) t 
			group by client_id
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 首次交易日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set FST_TRD_DT = coalesce(b.scjyrq,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			SELECT fund_acct,min(load_dt) scjyrq
			FROM DBA.t_edw_t05_trade_jour
			WHERE busi_cd IN ('3101', '3102',   -- 交易买卖
												'3408', '9994',         -- 场内金额_认购确认_日
												'5122',                 -- 场内金额_申购确认_日
												'5139',                 -- 场内金额_定时定额投资确认_日
												'5124')                 -- 场内金额_赎回确认_日
			GROUP BY fund_acct
	) b on a.MAIN_CPTL_ACCT=b.fund_acct
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 上海首次交易日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set SH_FST_TRD_DT = coalesce(b.scjyrq_sh,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			SELECT fund_acct,min(load_dt) scjyrq_sh
			FROM DBA.t_edw_t05_trade_jour
			WHERE busi_cd IN ('3101', '3102',   -- 交易买卖
												'3408', '9994',         -- 场内金额_认购确认_日
												'5122',                 -- 场内金额_申购确认_日
												'5139',                 -- 场内金额_定时定额投资确认_日
												'5124')                 -- 场内金额_赎回确认_日
			and market_type_cd='01'
			GROUP BY fund_acct
	) b on a.MAIN_CPTL_ACCT=b.fund_acct
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 深圳首次交易日期
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set SZ_FST_TRD_DT = coalesce(b.scjyrq_sz,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			SELECT fund_acct,min(load_dt) scjyrq_sz
			FROM DBA.t_edw_t05_trade_jour
			WHERE busi_cd IN ('3101', '3102',   -- 交易买卖
												'3408', '9994',         -- 场内金额_认购确认_日
												'5122',                 -- 场内金额_申购确认_日
												'5139',                 -- 场内金额_定时定额投资确认_日
												'5124')                 -- 场内金额_赎回确认_日
			and market_type_cd='02'
			GROUP BY fund_acct
	) b on a.MAIN_CPTL_ACCT=b.fund_acct
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否开通证券理财
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set IF_SECU_CHRM = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_EDW_UF2_PRODSECUMHOLDER
		where load_dt=@v_date
		and PRODHOLDER_STATUS='0'
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- 是否购买证券理财产品
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_PURC_SECU_CHRM_PROD = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN(
		select distinct client_id
		from dba.GT_ODS_ZHXT_HIS_SECUMDELIVER
		where load_dt between @v_begin_trad_date and @v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否开通银行理财
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set IF_BANK_CHRM = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_EDW_UF2_PRODSECUMHOLDER
		where load_dt=@v_date
		and PRODHOLDER_STATUS='0'
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与银行理财业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_BANK_CHRM_BIS = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.GT_ODS_ZHXT_HIS_BANKMENTRUST
		where load_dt between @v_begin_trad_date and @v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否参与银行理财业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_BANK_CHRM_BIS = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.GT_ODS_ZHXT_HIS_BANKMENTRUST
		where load_dt <= @v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否持有B股
	update DM.T_PUB_CUST_LIMIT_M_D
	set IF_HLD_B_SHR = case when b.zjzh is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct zjzh
		from dba.T_DDW_F00_KHMRCPYKHZ_D
		where load_Dt=@v_date
		and zqlx in ('17','18')
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- 是否根网客户
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_ROOTNET_CUST = CASE WHEN t2.zjzh IS NOT NULL THEN 1 ELSE 0 END     -- 是否根网客户
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT CONVERT(VARCHAR, CONVERT(numeric(30,0), acctid)) AS zjzh
	               FROM dba.t_edw_tr_getf_tradinglog
	              GROUP BY zjzh
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;
	     
	-- 是否资管电子签名客户
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_ASSM_ELEC_SIGNAT_CUST = CASE WHEN t2.zjzh IS NOT NULL THEN 1 ELSE 0 END     -- 是否资管电子签名
	  FROM dba.DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT fund_acct AS zjzh
	               FROM dba.t_edw_t01_fund_acct 
	              WHERE client_rights LIKE '%e%'
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;

	-- 是否金盾客户
	  UPDATE DM.T_PUB_CUST_LIMIT_M_D
	     SET IF_JD_CUST = CASE WHEN t2.zjzh_x IS NOT NULL THEN 1 ELSE 0 END     -- 是否金盾客户
	    FROM DM.T_PUB_CUST_LIMIT_M_D t1
	    LEFT JOIN (SELECT DISTINCT b.zjzh_x
	                 FROM dba.gt_ods_jindunkh a
	                 LEFT JOIN dba.t_ddw_d_khdz b ON a.zjzh = b.zjzh
	                WHERE load_dt = @v_date
	              ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh_x
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;

	-- 是否多银行存管
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_MULIT_BANK_DEPO = CASE WHEN t2.zjzh_x IS NOT NULL THEN 1 ELSE 0 END     -- 是否多银行存管
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT zjzh_x
	               FROM dba.t_ddw_d_khdz
	              GROUP BY zjzh_x
	             HAVING COUNT(DISTINCT zjzh) >= 2 
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh_x
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;

	-- 是否大小非
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_NON_TRD = CASE WHEN t2.zjzh IS NOT NULL THEN 1 ELSE 0 END     -- 是否大小非
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT zjzh
	               FROM dba.t_edw_dxfkhmd
	              WHERE nian || yue = (SELECT MAX(nian || yue) 
	                                     FROM dba.t_edw_dxfkhmd)
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;
	   
	-- TODO:是否期货客户 IF_FUTR_CUST

	-- 是否参与打新股业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_STAGGING_BIS = CASE WHEN t2.zjzh IS NULL THEN 0 ELSE 1 END
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT a.fund_acct AS zjzh
	               FROM dba.t_edw_t05_trade_jour a
	              WHERE a.load_dt BETWEEN @v_begin_trad_date AND @v_date
	                AND a.busi_type_cd IN ('3406') 
	                AND a.stock_type_cd IN ('35', '32')
	                AND a.market_type_cd IN ('01', '02', '03', '04', '05', '0G','0S')	/*2014-11-28增加沪港通市场类型 2016-11-18增加深港通业务*/
	                AND a.trad_amt > 0
	              GROUP BY zjzh
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;


	-- 是否参与打新股业务
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_STAGGING_BIS_GT = CASE WHEN t2.zjzh IS NULL THEN 0 ELSE 1 END
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT a.fund_acct AS zjzh
	               FROM dba.t_edw_t05_trade_jour a
	              WHERE a.load_dt <= @v_date
	                AND a.busi_type_cd IN ('3406') 
	                AND a.stock_type_cd IN ('35', '32')
	                AND a.market_type_cd IN ('01', '02', '03', '04', '05', '0G','0S')	/*2014-11-28增加沪港通市场类型 2016-11-18增加深港通业务*/
	                AND a.trad_amt > 0
	              GROUP BY zjzh
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;
	   
	-- 是否特殊账号
	update DM.T_PUB_CUST_LIMIT_M_D
	set if_spca_acct = case when b.zjzh is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
	    select distinct column_a as zjzh 
	    from dba.gt_ods_bbdr_org 
	    where nian ||yue = @v_year||@v_month 
	    and report_cd = 'tszhmd-A1' and row_num >= 2
	) b on a.main_cptl_acct=b.zjzh
	where a.year||a.mth=@v_year||@v_month;
    	   
    -- 是否融资融券有效客户 IF_CREDIT_EFF_CUST
    update DM.T_PUB_CUST_LIMIT_M_D
    set IF_CREDIT_EFF_CUST = coalesce(b.sfrzrqyxh, 0 )
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join dba.tmp_ddw_khqjt_m_d b on a.year=b.nian and a.mth=b.yue and a.main_cptl_acct=b.zjzh
	where a.year||a.mth=@v_year||@v_month;

    -- 是否新增融资融券有效户 if_na_credit_eff_act
    -- 融资融券有效户日期 credit_eff_act_dt
    update DM.T_PUB_CUST_LIMIT_M_D
    set if_na_credit_eff_act = case when a.IF_CREDIT_EFF_CUST=1 and coalesce(b.IF_CREDIT_EFF_CUST,0)=0 then 1 else 0 end
        ,credit_eff_act_dt = case when a.IF_CREDIT_EFF_CUST=1 and coalesce(b.IF_CREDIT_EFF_CUST,0)=0 then convert(int,@v_year||@v_month) else 0 end
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (select main_cptl_acct,IF_CREDIT_EFF_CUST from DM.T_PUB_CUST_LIMIT_M_D where year||mth=@v_sy) b on a.main_cptl_acct=b.main_cptl_acct
    where a.year=@v_year and a.mth=@v_month;

    -- 是否参与约定购回业务_累计 if_apptbuyb_bis_gt
    update DM.T_PUB_CUST_LIMIT_M_D
    set if_apptbuyb_bis_gt = case when b.zjzh is not null then 1 else 0 end
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (select distinct zjzh from dba.t_ddw_ydsgh_D where fz>0) b on a.main_cptl_acct=b.zjzh
    where a.year=@v_year and a.mth=@v_month;
    
    -- 是否参与银行理财业务_累计 if_bank_chrm_bis_gt
    update DM.T_PUB_CUST_LIMIT_M_D
    set if_bank_chrm_bis_gt = case when b.fund_account is not null then 1 else 0 end
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (
        select distinct fund_account
        from dba.GT_ODS_ZHXT_HIS_BANKMSHAREJOUR
    ) b on a.main_cptl_acct=b.fund_account
    where a.year=@v_year and a.mth=@v_month;


    update DM.T_PUB_CUST_LIMIT_M_D
    set IF_PURC_OEF_GT = case when kj>0 then 1 else 0 end -- 是否购买开基_累计	
        ,IF_PURC_ASSM_GT = case when zg>0 then 1 else 0 end   -- 是否购买资管_累计	
        ,IF_PO_STKT_BIS_GT = case when gm_gpx>0 then 1 else 0 end  -- 是否参与公募股票型业务_累计	
        ,IF_PO_BONDT_BIS_GT = case when gm_zqx>0 then 1 else 0 end -- 是否参与公募债券型业务_累计	
        ,IF_PO_CURRT_BIS_GT = case when gm_hbx>0 then 1 else 0 end -- 是否参与公募货币型业务_累计	
        ,IF_ASSM_STKT_BIS_GT = case when zg_gpx>0 then 1 else 0 end    -- 是否参与资管股票型业务_累计	
        ,IF_ASSM_BONDT_BIS_GT = case when zg_zqx>0 then 1 else 0 end   -- 是否参与资管债券型业务_累计	
        ,IF_ASSM_CURRT_BIS_GT = case when zg_hbx>0 then 1 else 0 end   -- 是否参与资管货币型业务_累计
    
        ,IF_PO_STKT_BIS = case when b.gm_gpx_m>0 then 1 else 0 end -- 是否参与公募股票型业务	
        ,IF_PO_BONDT_BIS = case when b.gm_zqx_m>0 then 1 else 0 end    -- 是否参与公募债券型业务	
        ,IF_PO_CURRT_BIS = case when b.gm_hbx_m>0 then 1 else 0 end    -- 是否参与公募货币型业务	
        ,IF_ASSM_STKT_BIS = case when b.zg_gpx_m>0 then 1 else 0 end   -- 是否参与资管股票型业务	
        ,IF_ASSM_BONDT_BIS = case when b.zg_zqx_m>0 then 1 else 0 end  -- 是否参与资管债券型业务	
        ,IF_ASSM_CURRT_BIS = case when b.zg_hbx_m>0 then 1 else 0 end  -- 是否参与资管货币型业务	
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (
        select a.zjzh
            ,count(1) kj
            ,sum(case when b.lx like '%集合理财%' then 1 else 0 end) as zg
            ,sum(case when b.lx like '%公募-股票型%' then 1 else 0 end) as gm_gpx
            ,sum(case when b.lx like '%公募-债券型%' then 1 else 0 end) as gm_zqx
            ,sum(case when b.lx like '%公募-货币型%' then 1 else 0 end) as gm_hbx
            ,sum(case when b.lx like '%集合理财-股票型%' then 1 else 0 end) as zg_gpx
            ,sum(case when b.lx like '%集合理财-债券型%' then 1 else 0 end) as zg_zqx
            ,sum(case when b.lx like '%集合理财-货币型%' then 1 else 0 end) as zg_hbx
    
            ,sum(case when b.lx like '%公募-股票型%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as gm_gpx_m
            ,sum(case when b.lx like '%公募-债券型%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as gm_zqx_m
            ,sum(case when b.lx like '%公募-货币型%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as gm_hbx_m
            ,sum(case when b.lx like '%集合理财-股票型%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as zg_gpx_m
            ,sum(case when b.lx like '%集合理财-债券型%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as zg_zqx_m
            ,sum(case when b.lx like '%集合理财-货币型%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as zg_hbx_m
        from (
            select nian, yue, zjzh, jjdm from dba.t_ddw_xy_jjzb_m where nian||yue<@v_year||@v_month
            union
            select @v_year as nian, @v_month as yue, zjzh, jjdm from dba.t_ddw_xy_jjzb_d where substring(convert(varchar,rq),1,6)=@v_year||@v_month
        ) a
        left join dba.t_ddw_d_jj b on a.nian=b.nian and a.yue=b.yue and a.jjdm=b.jjdm
        where a.nian||a.yue <= @v_year||@v_month
        group by a.zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.year=@v_year and a.mth=@v_month;



    update dm.T_PUB_CUST_LIMIT_M_D
    set BGDL_OPEN_DT = coalesce(b.dzscjyrq,0)
    from dm.T_PUB_CUST_LIMIT_M_D a
    left join (
    select fund_acct, min(load_dt) as dzscjyrq
    from dba.T_EDW_T05_TRADE_JOUR
    where substring(convert(varchar,load_dt),1,6)<=@v_year||@v_month
    and busi_cd in ('3101','3102') and note like '%大宗%'
    group by fund_acct 
    ) b on a.main_cptl_acct=b.fund_acct
    where a.year=@v_year and a.mth=@v_month;
    
    update dm.T_PUB_CUST_LIMIT_M_D
    set SB_OPEN_DT = case when a.IF_SB_CUST=1 and coalesce(b.IF_SB_CUST,0)=0 then convert(int,@v_year||@v_month||'01')
                        when a.IF_SB_CUST=1 and coalesce(b.IF_SB_CUST,0)>0 then b.SB_OPEN_DT
                        else 0 end
    from dm.T_PUB_CUST_LIMIT_M_D a
    left join (
        select cust_id,IF_SB_CUST,SB_OPEN_DT
        from dm.T_PUB_CUST_LIMIT_M_D
        where year||mth=@v_sy
    ) b on a.cust_id=b.cust_id
    where a.year=@v_year and a.mth=@v_month;

   commit;
end
GO
GRANT EXECUTE ON dm.P_PUB_CUST_LIMIT_M_D TO xydc
GO
CREATE PROCEDURE dm.P_PUB_DATE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 日期信息维表
  编写者: DCY
  创建日期: 2017-11-16
  简介：日期维表，里面包含日期的各个维度，方便日期变量取数
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
   --PART0 删除要回洗的数据
  DELETE FROM DM.T_PUB_DATE;
  
  --插入数据
     INSERT INTO DM.T_PUB_DATE
	 (
	  DT                --日期
	 ,DT_DATE           --日期_DATE
	 ,YEAR              --年
	 ,QTR               --季
	 ,MTH               --月
	 ,IF_TRD_DAY_FLAG   --是否交易日标志
	 ,WEEK              --周
	 ,DAY               --日
	 ,WEEK_DAY          --星期几
	 ,LST_TRD_DAY       --上一个交易日
	 ,NXT_TRD_DAY       --下一个交易日
	 ,LST_NORM_DAY      --上一个自然日
	 ,NXT_NORM_DAY      --下一个自然日
	 ,TW_SNB_TRD_DAY    --本周第几个交易日
	 ,TW_SNB_NORM_DAY   --本周第几个自然日
	 ,TM_SNB_TRD_DAY    --本月第几个交易日
	 ,TM_SNB_NORM_DAY   --本月第几个自然日
	 ,TQ_SNB_TRD_DAY    --本季第几个交易日
	 ,TQ_SNB_NORM_DAY   --本季第几个自然日
	 ,TY_SNB_TRD_DAY    --本年第几个交易日
	 ,TY_SNB_NORM_DAY   --本年第几个自然日
	 ,GT_WORK_DAY       --累计工作日
	 ,TRD_DT            --交易日期
	 )
	 SELECT 
	  A1.DATE_ID
	 ,CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE) --日期型日期
	 ,CONVERT(CHAR(4),A1.YEAR_ID) --年 
	 ,CONVERT(CHAR(2),A1.QUARTER_ID) --季 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --月 
	 ,A1.TRADE_FLAG    --是否交易日标志                      
     ,CONVERT(CHAR,A1.WEEK_NO)   --周 
     ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) --几号
	 ,CASE WHEN A1.WEEKDAY_ID=1 THEN '星期一' 
           WHEN A1.WEEKDAY_ID=2 THEN '星期二'
           WHEN A1.WEEKDAY_ID=3 THEN '星期三'	
           WHEN A1.WEEKDAY_ID=4 THEN '星期四'
           WHEN A1.WEEKDAY_ID=5 THEN '星期五'
           WHEN A1.WEEKDAY_ID=6 THEN '星期六'
           WHEN A1.WEEKDAY_ID=7 THEN '星期日'
       END    --星期几	   
     ,MAX(A2.DATE_ID)    --上一个交易日 
	 ,MIN(A21.DATE_ID)    --下一个交易日
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)-1),112) AS NUMERIC(8,0))  --上一个自然日
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)+1),112) AS NUMERIC(8,0))  --下一个自然日
     ,A3.GZR    --本周第几个交易日
	 ,A1.WEEKDAY_ID    --本周第几个自然日
	 ,A4.GZR     --本月的第几工作日 
	 ,CAST(SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) AS NUMERIC(8,0))     --本月第几个自然日
	 ,A5.GZR --本季的第几工作日 
	 ,A51.GZR --本季第几个自然日 
	 ,A6.GZR --本年的第几工作日
	 ,A61.GZR --本年第几个自然日
	 ,A7.GZR  --累计工作日 
	 ,NULL             --交易日期 
	 
	  FROM DBA.T_ODS_D_DATE AS A1 
	  
	  --上一个交易日
	  LEFT OUTER JOIN DBA.T_ODS_D_DATE AS A2 ON A2.TRADE_FLAG = 1 AND A2.DATE_ID < A1.DATE_ID 
	                                           AND CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE)-CAST(CAST(A2.DATE_ID AS CHAR(8)) AS DATE) < 20
	  --下一个交易日									   
	  LEFT OUTER JOIN DBA.T_ODS_D_DATE AS A21 ON A21.TRADE_FLAG = 1 AND A21.DATE_ID > A1.DATE_ID 
	                                           AND CAST(CAST(A21.DATE_ID AS CHAR(8)) AS DATE)-CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE) < 20

	  --本周第几个交易日
	  LEFT OUTER JOIN
					  (SELECT B1.DATE_ID, SUM(B2.TRADE_FLAG)
					  FROM DBA.T_ODS_D_DATE AS B1
					  LEFT OUTER JOIN DBA.T_ODS_D_DATE AS B2
						ON B2.TRADE_FLAG = 1
					   AND B1.YEAR_ID = B2.YEAR_ID
					   AND B1.WEEK_NO = B2.WEEK_NO
					   AND B2.DATE_ID <= B1.DATE_ID
					 WHERE B1.TRADE_FLAG = 1
					 GROUP BY B1.DATE_ID) AS A3(DATE_ID, GZR) ON A1.DATE_ID = A3.DATE_ID
	--本月的第几交易日				 
	  LEFT OUTER JOIN
				  (SELECT C1.DATE_ID,
					SUM(C2.TRADE_FLAG) FROM
					DBA.T_ODS_D_DATE AS C1 LEFT OUTER JOIN
					DBA.T_ODS_D_DATE AS C2 ON
					C2.TRADE_FLAG = 1 AND
					C1.YEAR_ID = C2.YEAR_ID AND
					C1.MONTH_ID = C2.MONTH_ID AND
					C2.DATE_ID <= C1.DATE_ID WHERE
					C1.TRADE_FLAG = 1
					GROUP BY C1.DATE_ID) AS A4( DATE_ID,GZR) ON A1.DATE_ID = A4.DATE_ID 
	--本季第几个交易日
	  LEFT OUTER JOIN
				  (SELECT D1.DATE_ID,
					SUM(D2.TRADE_FLAG) FROM
					DBA.T_ODS_D_DATE AS D1 LEFT OUTER JOIN
					DBA.T_ODS_D_DATE AS D2 ON
					D2.TRADE_FLAG = 1 AND
					D1.YEAR_ID = D2.YEAR_ID AND
					D1.QUARTER_ID = D2.QUARTER_ID AND
					D2.DATE_ID <= D1.DATE_ID WHERE
					D1.TRADE_FLAG = 1
					GROUP BY D1.DATE_ID) AS A5( DATE_ID,
				  GZR) ON A1.DATE_ID = A5.DATE_ID 
	--本季第几个自然日
	  LEFT OUTER JOIN
				  (SELECT D1.DATE_ID,
					COUNT(1) FROM
					DBA.T_ODS_D_DATE AS D1 LEFT OUTER JOIN
					DBA.T_ODS_D_DATE AS D2 ON
					D1.YEAR_ID = D2.YEAR_ID AND
					D1.QUARTER_ID = D2.QUARTER_ID AND
					D2.DATE_ID <= D1.DATE_ID 
					GROUP BY D1.DATE_ID) AS A51( DATE_ID,
				  GZR) ON A1.DATE_ID = A51.DATE_ID 
	--本年第几个交易日			  
	 LEFT OUTER JOIN
			  (SELECT E1.DATE_ID,
				SUM(E2.TRADE_FLAG) FROM
				DBA.T_ODS_D_DATE AS E1 LEFT OUTER JOIN
				DBA.T_ODS_D_DATE AS E2 ON
				E2.TRADE_FLAG = 1 AND
				E1.YEAR_ID = E2.YEAR_ID AND
				E2.DATE_ID <= E1.DATE_ID WHERE
				E1.TRADE_FLAG = 1
				GROUP BY E1.DATE_ID) AS A6( DATE_ID,GZR) ON A1.DATE_ID = A6.DATE_ID
	--本年第几个自然日			  
	 LEFT OUTER JOIN
			  (SELECT E1.DATE_ID,
				COUNT(1) FROM
				DBA.T_ODS_D_DATE AS E1 LEFT OUTER JOIN
				DBA.T_ODS_D_DATE AS E2 ON
				E1.YEAR_ID = E2.YEAR_ID AND
				E2.DATE_ID <= E1.DATE_ID 
				GROUP BY E1.DATE_ID) AS A61( DATE_ID,GZR) ON A1.DATE_ID = A61.DATE_ID
	--累计工作日 
	LEFT OUTER JOIN
			  (SELECT F1.DATE_ID,
				SUM(F2.TRADE_FLAG) FROM
				DBA.T_ODS_D_DATE AS F1 LEFT OUTER JOIN
				DBA.T_ODS_D_DATE AS F2 ON
				F2.TRADE_FLAG = 1 AND
				F2.DATE_ID <= F1.DATE_ID WHERE
				F1.TRADE_FLAG = 1
				GROUP BY F1.DATE_ID) AS A7( DATE_ID,
			  GZR) ON A1.DATE_ID = A7.DATE_ID
      GROUP BY 
	  A1.DATE_ID
	 ,CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE) --日期型日期
	 ,CONVERT(CHAR(4),A1.YEAR_ID) --年 
	 ,CONVERT(CHAR(2),A1.QUARTER_ID) --季 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --月 
	 ,A1.TRADE_FLAG    --是否交易日标志                      
     ,CONVERT(CHAR,A1.WEEK_NO)   --周  ,
     ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) --几号
	 ,CASE WHEN A1.WEEKDAY_ID=1 THEN '星期一' 
           WHEN A1.WEEKDAY_ID=2 THEN '星期二'
           WHEN A1.WEEKDAY_ID=3 THEN '星期三'	
           WHEN A1.WEEKDAY_ID=4 THEN '星期四'
           WHEN A1.WEEKDAY_ID=5 THEN '星期五'
           WHEN A1.WEEKDAY_ID=6 THEN '星期六'
           WHEN A1.WEEKDAY_ID=7 THEN '星期日'
       END    --星期几
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)-1),112) AS NUMERIC(8,0))  --上一个自然日
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)+1),112) AS NUMERIC(8,0))  --下一个自然日
     ,A3.GZR    --本周第几个交易日
	 ,A1.WEEKDAY_ID    --本周第几个自然日
	 ,A4.GZR     --本月的第几工作日 
	 ,CAST(SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) AS NUMERIC(8,0))     --本月第几个自然日
	 ,A5.GZR --本季的第几工作日 
	 ,A51.GZR --本季第几个自然日 
	 ,A6.GZR --本年的第几工作日
	 ,A61.GZR --本年第几个自然日
	 ,A7.GZR  --累计工作日
	  ORDER BY 1 ASC;
    COMMIT;
	
	--下面用来更新交易日期字段：如果当前日期是交易日，则使用当前日期；如果当前日期非交易日，则使用上一交易日。
	UPDATE DM.T_PUB_DATE
	SET TRD_DT= (CASE WHEN IF_TRD_DAY_FLAG=1 THEN DT ELSE LST_TRD_DAY END)
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_DATE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_DATE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_DATE_M(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 日期维表月表
  编写者: DCY
  创建日期: 2017-12-19
  简介：日期维表月表，里面包含月度级别时间
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
   --PART0 删除要回洗的数据
  DELETE FROM DM.T_PUB_DATE_M;
  
  --先算年级别的数据
  SELECT
     CONVERT(CHAR(4),A1.YEAR_ID)                          AS YEAR                --年 
    ,MIN( A1.DATE_ID )                                    AS NATRE_DAY_YEARBGN   --自然日_年初
	,MIN(CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END) AS TRD_DAY_YEARBGN     --交易日_年初
	,COUNT(DISTINCT A1.DATE_ID )                          AS NATRE_DAYS_YEAR     --自然天数_年
	,COUNT(DISTINCT CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END) AS TRD_DAYS_YEAR  --交易天数_年
	
	INTO #YEAR_STAT
	
	FROM
	DBA.T_ODS_D_DATE AS A1 
	GROUP BY 
    CONVERT(CHAR(4),A1.YEAR_ID)
    ;
	
  --插入数据
     INSERT INTO DM.T_PUB_DATE_M
	 (
	  YEAR               --年
	 ,MTH                --月
	 ,NATRE_DAY_MTHBEG   --自然日_月初
	 ,NATRE_DAY_MTHEND   --自然日_月末
	 ,TRD_DAY_MTHBEG     --交易日_月初
	 ,TRD_DAY_MTHEND     --交易日_月末
	 ,NATRE_DAY_YEARBGN  --自然日_年初
	 ,TRD_DAY_YEARBGN    --交易日_年初
	 ,NATRE_DAYS_MTH     --自然天数_月
	 ,TRD_DAYS_MTH       --交易天数_月
	 ,NATRE_DAYS_YEAR    --自然天数_年
	 ,TRD_DAYS_YEAR      --交易天数_年
	 )
	 SELECT 
	  CONVERT(CHAR(4),A1.YEAR_ID) --年 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --月 
	 ,MIN(A1.DATE_ID)  --自然日_月初
	 ,MAX(A1.DATE_ID)  --自然日_月末
	 ,MIN(CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END)  --交易日_月初
	 ,MAX(CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END)  --交易日_月末
	 ,A2.NATRE_DAY_YEARBGN     --自然日_年初
	 ,A2.TRD_DAY_YEARBGN       --交易日_年初
	 ,COUNT(DISTINCT A1.DATE_ID )                                      --自然天数_月
	 ,COUNT(DISTINCT CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END)  --交易天数_月
     ,A2.NATRE_DAYS_YEAR     --自然天数_年
	 ,A2.TRD_DAYS_YEAR       --交易天数_年
	 
	  FROM DBA.T_ODS_D_DATE AS A1 
	  LEFT OUTER JOIN #YEAR_STAT A2 ON CONVERT(CHAR(4),A1.YEAR_ID)=A2.YEAR
	  GROUP BY 
	  CONVERT(CHAR(4),A1.YEAR_ID) --年 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --月
	 ,A2.NATRE_DAY_YEARBGN     --自然日_年初
	 ,A2.TRD_DAY_YEARBGN       --交易日_年初
     ,A2.NATRE_DAYS_YEAR     --自然天数_年
	 ,A2.TRD_DAYS_YEAR       --交易天数_年
	 ;
	 
    COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_DATE_M TO query_dev
GO
CREATE PROCEDURE dm.P_PUB_IDV_CUST(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 个人客户信息维表
  编写者: DCY
  创建日期: 2017-11-17
  简介：清洗个人客户各个常用的属性信息
  *********************************************************************
  修订记录：   修订日期    修订人     修改内容简要说明
  数据脱敏     20180403     dcy       姓名、手机号、身份证号、等进行脱敏 
  重复值修复  20180415     chenhu  增加一个hr_name非空的条件         
  *********************************************************************/
  
   SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
   	
  --PART0 删除要回洗的数据
    DELETE FROM DM.T_PUB_IDV_CUST WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
	
  --PART1 将每日采集的数据放入临时表
 
	SELECT
	 OUCI.CLIENT_ID        AS CUST_ID      --客户编码
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --年
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --月
	,DOH.PK_ORG            AS WH_ORG_ID    --仓库机构编码 
	,CONVERT(VARCHAR,OUCI.BRANCH_NO) AS HS_ORG_ID  --恒生机构编码
	,OUC.CLIENT_NAME       AS CUST_NAME    --客户名称
	,OUCI.BIRTHDAY         AS BIRT_DT      --出生日期
	,OUCI.HOME_TEL         AS HOME_TEL     --家庭电话
	,OUCI.OFFICE_TEL       AS UNIT_TEL     --单位电话
	,OUCI.MOBILE_TEL       AS MOB_NO       --手机号
	,OUCI.ID_ADDRESS       AS HOME_ADDR    --家庭地址
	,OUCI.E_MAIL           AS EML          --邮箱
	,OUCI.PROFESSION_CODE  AS OCCU         --职业
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUCI.PROFESSION_CODE) AND OUS.DICT_ENTRY=1047) AS OCCU_NAME   --职业名称
    ,OUCI.NATION_ID        AS NATN	       --民族
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUCI.NATION_ID) AND OUS.DICT_ENTRY=971) AS NATN_NAME   --民族名称
	,@V_BIN_DATE  AS LOAD_DT  --清洗日期
	
	INTO #TEMP_IDV_CUST
	
	FROM DBA.T_EDW_UF2_CLIENTINFO OUCI
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUCI.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL   --有重复值  UPDATE BY CHENHU 20180415
	LEFT JOIN DBA.T_EDW_UF2_CLIENT OUC ON OUC.CLIENT_ID=OUCI.CLIENT_ID and OUC.LOAD_DT=@V_BIN_DATE
	WHERE OUCI.LOAD_DT=@V_BIN_DATE
	;
	COMMIT;
	
	--PART1.2 将客户姓名中的/替换掉
	UPDATE #TEMP_IDV_CUST
	SET 
	    --CUST_NAME=REPLACE(REPLACE(REPLACE(CUST_NAME,'/',''),'\',''),'|',''),     --客户名称 
	    --MOB_NO=REPLACE(REPLACE(REPLACE(MOB_NO,'/',''),'\',''),'|',''),
        --home_tel=REPLACE(REPLACE(REPLACE(home_tel,'/',''),'\',''),'|',''),
        --unit_tel=REPLACE(REPLACE(REPLACE(unit_tel,'/',''),'\',''),'|',''),
        --home_addr='*********',--由于里面有换行符，导致采集数据到GP有误，直接脱敏，不用后面REPLACE(REPLACE(REPLACE(home_addr,'/',''),'\',''),'|','')
		--eml=REPLACE(REPLACE(REPLACE(eml,'/',''),'\',''),'|','')
		
		 CUST_NAME=SUBSTR(CUST_NAME,1,0)||'***'   --姓名脱敏
		,MOB_NO=SUBSTR(MOB_NO,1,3)||'********'   --手机号脱敏
		,HOME_TEL=SUBSTR(HOME_TEL,1,0)||'********'   --家庭电话脱敏
		,UNIT_TEL=SUBSTR(UNIT_TEL,1,0)||'********'   --单位电话脱敏
		,EML=SUBSTR(EML,1,0)||'********'   --邮箱脱敏
		,HOME_ADDR=SUBSTR(HOME_ADDR,1,0)||'********'   --家庭地址脱敏
	;
	COMMIT;	
	
	--4.3 最后将当天新增的客户插入进来
	INSERT INTO DM.T_PUB_IDV_CUST
	(
	 CUST_ID        --客户编码
	,YEAR              --年
	,MTH               --月
	,WH_ORG_ID      --仓库机构编码
	,HS_ORG_ID      --恒生机构编码
	,CUST_NAME      --客户名称
	,BIRT_DT        --出生日期
	,HOME_TEL       --家庭电话
	,UNIT_TEL       --单位电话
	,MOB_NO         --手机号
	,HOME_ADDR      --家庭地址
	,EML            --邮箱
	,OCCU           --职业
	,OCCU_NAME      --职业名称
	,NATN           --民族
	,NATN_NAME      --民族名称
	,LOAD_DT        --清洗日期
	)
	SELECT
	 CUST_ID        --客户编码
	,YEAR              --年
	,MTH               --月
	,WH_ORG_ID      --仓库机构编码
	,HS_ORG_ID      --恒生机构编码
	,CUST_NAME      --客户名称
	,BIRT_DT        --出生日期
	,HOME_TEL       --家庭电话
	,UNIT_TEL       --单位电话
	,MOB_NO         --手机号
	,HOME_ADDR      --家庭地址
	,EML            --邮箱
	,OCCU           --职业
	,OCCU_NAME      --职业名称
	,NATN           --民族
	,NATN_NAME      --民族名称
	,LOAD_DT        --清洗日期
	FROM #TEMP_IDV_CUST  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_IDV_CUST TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_IDV_CUST TO xydc
GO
CREATE PROCEDURE dm.P_PUB_MKT_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 市场类型维表
  编写者: DCY
  创建日期: 2017-11-24
  简介：市场类型维表清洗
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
  
   --PART0 删除要回洗的数据
  DELETE FROM DM.T_PUB_MKT_TYPE ;
  
   --开始插入数据
  INSERT INTO DM.T_PUB_MKT_TYPE
  (
    WH_MKT_TYPE_ID    --仓库市场类型编码
   ,HS_MKT_TYPE_ID    --恒生市场类型编码
   ,WH_MKT_TYPE_NAME  --仓库市场类型名称
   ,HS_MKT_TYPE_NAME  --恒生市场类型名称
   ,LOAD_DT           --清洗日期
   )
	  
  SELECT DISTINCT 
	 TOUS.MKT_TYPE AS  WH_MKT_TYPE_ID     --仓库市场类型编码
	,TOUS.EXCHANGE_TYPE AS HS_MKT_TYPE_ID --恒生市场类型编码
    ,TETPC.CODE_NAME AS WH_MKT_TYPE_NAME  --仓库市场类型名称
	,DIC.DICT_PROMPT AS  HS_MKT_TYPE_NAME --恒生市场类型名称
    ,@V_BIN_DATE    --清洗日期 
	
  FROM DBA.T_ODS_UF2_SCLXDZ TOUS
  LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY DIC ON TOUS.EXCHANGE_TYPE=DIC.SUBENTRY  AND   DIC.DICT_ENTRY=1301 -- EXCHANGE_TYPE恒生市场类型
  LEFT JOIN DBA.T_EDW_T06_PUBLIC_CODE TETPC ON  TOUS.MKT_TYPE=TETPC.CODE_CD  AND FIELD_ENG_NAME='market_type_cd' --仓库市场类型
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_MKT_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_MKT_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_ORDR_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 委托方式维表
  编写者: DCY
  创建日期: 2017-11-27
  简介：委托方式维表清洗
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
    
   --PART0 删除要回洗的数据
  DELETE FROM DM.T_PUB_ORDR_TYPE ;
  
   --开始插入数据
  INSERT INTO DM.T_PUB_ORDR_TYPE
  (
    WH_ORDR_MODE_CD    --仓库委托类型编码
   ,WH_ORDR_MODE_NAME  --仓库委托类型名称
   ,HS_ORDR_MODE_CD    --恒生委托类型编码
   ,HS_ORDR_MODE_NAME  --恒生委托类型名称
   ,LOAD_DT           --清洗日期
   )
	  
  SELECT DISTINCT 
	 OEW.CODE_VAL     AS  WH_ORDR_MODE_CD    --仓库委托类型编码
	,TETPC.CODE_NAME  AS  WH_ORDR_MODE_NAME  --仓库委托类型名称
	,OEW.SRC_CODE_VAL AS  HS_ORDR_MODE_CD    --恒生委托类型编码
	,DIC.DICT_PROMPT  AS  HS_ORDR_MODE_NAME  --恒生委托类型名称
    ,@V_BIN_DATE    --清洗日期 
	
  FROM DBA.T_ODS_DIC_SJCK_TMP_OP_ENTRUST_WAY OEW --委托方式恒生和仓库的映射表
  LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY DIC ON OEW.SRC_CODE_VAL=DIC.SUBENTRY  AND   DIC.DICT_ENTRY=1201 --恒生委托类型
  LEFT JOIN DBA.T_EDW_T06_PUBLIC_CODE TETPC ON OEW.CODE_VAL=TETPC.CODE_CD  AND FIELD_ENG_NAME='order_way_cd' --仓库委托类型
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_ORDR_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_ORDR_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_ORG(IN @v_date INT)
BEGIN
  /******************************************************************
  程序功能: 处理机构维表（t_pub_org）
  编写者: 张琦
  创建日期: 2017-11-15
  简介：更新机构维表t_pub_org，对新增、更新及删除分别进行处理
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           2017年11月15日                张琦                    创建
  *********************************************************************/
  -- 1、取最新的数据
  -- drop table #t_org;
  
  declare @v_nian varchar(4);
  declare @v_yue varchar(2);
  
  commit;
  
  set @v_nian = substring(convert(varchar,@v_date),1,4);
  set @v_yue = substring(convert(varchar,@v_date),5,2);
  
    SELECT
        a.PK_ORG AS WH_ORG_ID    -- 仓库机构编码
        ,a.branch_no AS HS_ORG_ID -- 恒生机构编码
        ,a.hr_pk AS HR_ORG_ID     -- HR机构编码
        ,b.DEP_CODE AS XY_ORG_ID    -- 新意机构编码
        ,a.hr_name AS HR_ORG_NAME    -- HR机构名称
        ,a.branch_name AS HS_ORG_NAME   -- 恒生机构名称
        ,a.open_date AS OPEN_DT     -- 开业日期
        ,a.org_category AS ORG_CLAS -- 机构分类
        ,a.branch_type AS ORG_TYPE  -- 机构类型
        ,org_sept.pk_org AS SEPT_CORP_ID    -- 分公司编码
        ,a.father_branch_name_direct AS SEPT_CORP_NAME  -- 分公司名称
        ,org_sept_top.pk_org as TOP_SEPT_CORP_ID    -- 顶级分公司编码
        ,a.father_branch_name_root as TOP_SEPT_CORP_NAME    -- 顶级分公司名称
        ,a.center_org_pk as CENT_BRH_ID  -- 中心营业部编码
        ,a.center_org_name as CENT_BRH_NAME -- 中心营业部名称
        ,a.region_category as REGI_CLAS     -- 地区分类
        ,a.province as PROV     -- 省
        ,a.city as CITY         -- 城市
        ,a.prefecture_city as L_CITY    -- 地级市
        ,case when a.is_core_org='Y' then 1 else 0 end as IF_KEY        -- 是否核心
        ,a.is_in_system as IF_SYS_INR   -- 是否系统内
        ,case when a.enabled='Y' then 1 else 0 end as IF_VLD            -- 是否有效
        ,coalesce(b.ORG_CODE,a.org_supervise_code) as SRVL_CD    -- 监管代码
        ,b.BRANCH_SHORTNAME as ORG_ABBR     -- 机构简称
        ,b.BRANCH_ADDRESS as DET_ADDR       -- 详细地址
        ,b.BRANCH_TYPE as SRVL_CLAS         -- 监管分类
        ,b.SUPERVISE_AREA as SRVL_AREA      -- 监管辖区
        ,b.ADMINISTRATIVE_AREA as BRH_TYPE_PERFM  -- 营业部类别私财
        ,a.father_branch_hrpk_root as PRI_SEPT_CORPHR_NO    -- 一级分公司HR编号
        ,a.secondary_branch_hrpk as SCDY_SEPT_CORPHR_NO     -- 二级分公司HR编号
        ,a.father_branch_hrpk_direct as DIRECTL_SEPT_CORPHR_NO  -- 直属分公司HR编号
    INTO #t_org
    -- select *
    FROM DBA.T_DIM_ORG a
    LEFT JOIN DBA.T_ODS_CF_V_BRANCH b ON a.branch_no=CONVERT(VARCHAR,b.BRANCH_NO)
    LEFT JOIN DBA.T_DIM_ORG org_sept on a.father_branch_hrpk_direct=org_sept.hr_pk
    LEFT JOIN DBA.T_DIM_ORG org_sept_top on a.father_branch_hrpk_root=org_sept_top.hr_pk;
    
    
    delete from dm.T_PUB_ORG where "year"=@v_nian and mth=@v_yue;
    
    insert into dm.T_PUB_ORG(
	    WH_ORG_ID
			,"YEAR"
			,MTH
			,HS_ORG_ID
			,HR_ORG_ID
			,XY_ORG_ID
			,HR_ORG_NAME
			,HS_ORG_NAME
			,OPEN_DT
			,ORG_CLAS
			,ORG_TYPE
			,SEPT_CORP_ID
			,SEPT_CORP_NAME
			,TOP_SEPT_CORP_ID
			,TOP_SEPT_CORP_NAME
			,CENT_BRH_ID
			,CENT_BRH_NAME
			,REGI_CLAS
			,PROV
			,CITY
			,L_CITY
			,IF_KEY
			,IF_SYS_INR
			,IF_VLD
			,SRVL_CD
			,ORG_ABBR
			,DET_ADDR
			,SRVL_CLAS
			,SRVL_AREA
			,BRH_TYPE_PERFM
			,SUPERV_BUREAU
			,LOAD_DT
            ,PRI_SEPT_CORPHR_NO
            ,SCDY_SEPT_CORPHR_NO
            ,DIRECTL_SEPT_CORPHR_NO
    )
    SELECT
    	WH_ORG_ID
			,@v_nian AS "YEAR"
			,@v_yue AS MTH
			,HS_ORG_ID
			,HR_ORG_ID
			,XY_ORG_ID
			,HR_ORG_NAME
			,HS_ORG_NAME
			,OPEN_DT
			,ORG_CLAS
			,ORG_TYPE
			,SEPT_CORP_ID
			,SEPT_CORP_NAME
			,TOP_SEPT_CORP_ID
			,TOP_SEPT_CORP_NAME
			,CENT_BRH_ID
			,CENT_BRH_NAME
			,REGI_CLAS
			,PROV
			,CITY
			,L_CITY
			,IF_KEY
			,IF_SYS_INR
			,IF_VLD
			,SRVL_CD
			,ORG_ABBR
			,DET_ADDR
			,SRVL_CLAS
			,SRVL_AREA
			,BRH_TYPE_PERFM
			,NULL AS SUPERV_BUREAU
			,@v_date AS LOAD_DT
            ,PRI_SEPT_CORPHR_NO
            ,SCDY_SEPT_CORPHR_NO
            ,DIRECTL_SEPT_CORPHR_NO
    FROM #t_org;


    update dm.t_pub_org
    set prov = b.prov
    from dm.t_pub_org a
    left join (
        select  *
        from dm.t_pub_org
        where year='2017' and mth='12'
    ) b on a.wh_org_id=b.wh_org_id
    where a.year||a.mth=@v_nian||@v_yue;    

    
    commit;

END
GO
GRANT EXECUTE ON dm.P_PUB_ORG TO xydc
GO
CREATE PROCEDURE dm.P_PUB_ORG_CUST(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 机构客户信息维表
  编写者: DCY
  创建日期: 2017-11-14
  简介：清洗机构客户的各个常用的属性信息
  *********************************************************************
  修订记录：   修订日期    修订人     修改内容简要说明 
   数据脱敏     20180403     dcy       姓名、手机号、身份证号、企业的税务号、国税号等进行脱敏         
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
  
    --PART0 删除要回洗的数据
    DELETE FROM DM.T_PUB_ORG_CUST WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
  --PART1 将每日采集的数据放入临时表
 
	SELECT
	 OUOI.CLIENT_ID                    AS CUST_ID       --客户编码
	,SUBSTR(@V_BIN_DATE||'',1,4)       AS YEAR          --年
	,SUBSTR(@V_BIN_DATE||'',5,2)       AS MTH           --月
	,DOH.PK_ORG                        AS WH_ORG_ID     --仓库机构编码 
	,CONVERT(VARCHAR,OUOI.BRANCH_NO)   AS HS_ORG_ID     --恒生机构编码
	,OUC.CLIENT_NAME                   AS CUST_NAME     --客户名称
	,OUOI.INSTREPR_NAME                AS LEGP_REP      --法人代表
	,OUOI.ORGAN_CODE                   AS ORG_ID        --组织机构编码
	,OUOI.BUSINESS_LICENCE             AS DOBIZ_LICENS  --营业执照
	,OUOI.COMPANY_KIND                 AS ET            --企业性质
	,OUOI.REGISTER_FUND                AS REG_CAPI      --注册资本
	,OUOI.REGISTER_MONEY_TYPE          AS REG_CAPI_CCY  --注册资本币种
	,OUOI.RELATION_NAME                AS CONP          --联系人
	,OUOI.MOBILE_TEL                   AS MOB_NO        --手机号
	,OUOI.E_MAIL                       AS EML           --电子邮件
	,OUOI.ADDRESS                      AS ADDR          --地址
	,OUOI.WORK_RANGE                   AS MANAGE_SCP    --经营范围
	,OUOI.INDUSTRY_TYPE                AS INDT_TYPE     --行业类别
	,OUOI.TAX_REGISTER                 AS STA_TAX_CERTNO --国税税务登记证号
	,OUOI.REGTAX_REGISTER              AS LOC_TAX_CERTNO --地税税务登记证号
	,''                                AS UNI_SOCI_CRED_NO   --统一社会信用编号
	,OUC.ID_BEGINDATE                  AS ID_VLD_SDT         --证件有效开始日期
	,OUC.ID_ENDDATE                    AS ID_VLD_EDT         --证件有效截止日期
	,@V_BIN_DATE                       AS LOAD_DT  --清洗日期
	
	INTO #TEMP_ORG_CUST
	
	FROM DBA.T_EDW_UF2_ORGANINFO OUOI
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUOI.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL     
	--LEFT JOIN DBA.T_ODS_UF2_CLIENT OUC ON OUC.CLIENT_ID=OUOI.CLIENT_ID
	LEFT JOIN DBA.T_EDW_UF2_CLIENT OUC ON OUC.CLIENT_ID=OUOI.CLIENT_ID and OUC.LOAD_DT=@V_BIN_DATE

	WHERE OUOI.LOAD_DT=@V_BIN_DATE
	;
	COMMIT;
	
	--PART1.2 将客户姓名中的/替换掉
	UPDATE #TEMP_ORG_CUST
	SET 
	    --CUST_NAME=REPLACE(REPLACE(REPLACE(CUST_NAME,'/',''),'\',''),'|',''),     --客户名称 
	    --MOB_NO=REPLACE(REPLACE(REPLACE(MOB_NO,'/',''),'\',''),'|',''),
        --conp=REPLACE(REPLACE(REPLACE(conp,'/',''),'\',''),'|',''),
        --addr=REPLACE(REPLACE(REPLACE(addr,'/',''),'\',''),'|',''),
        MANAGE_SCP=REPLACE(REPLACE(REPLACE(MANAGE_SCP,'/',''),'\',''),'|','')
		
		,CUST_NAME=SUBSTR(CUST_NAME,1,0)||'***'   --姓名脱敏
		,MOB_NO=SUBSTR(MOB_NO,1,3)||'********'   --手机号脱敏
		,CONP=SUBSTR(CONP,1,0)||'********'   --联系人脱敏
		,LEGP_REP=SUBSTR(LEGP_REP,1,0)||'********'   --法人代表脱敏
		,EML=SUBSTR(EML,1,0)||'********'   --邮箱脱敏
		,ADDR=SUBSTR(ADDR,1,0)||'********'   --地址脱敏
		,STA_TAX_CERTNO=SUBSTR(STA_TAX_CERTNO,1,0)||'********'   --国税税务登记证号脱敏
		,LOC_TAX_CERTNO=SUBSTR(LOC_TAX_CERTNO,1,0)||'********'   --地税税务登记证号脱敏
		,UNI_SOCI_CRED_NO=SUBSTR(UNI_SOCI_CRED_NO,1,0)||'********'   --统一社会信用编号脱敏
		
	;
	COMMIT;
	
	--3 最后将当天新增的客户插入进来
	INSERT INTO DM.T_PUB_ORG_CUST
	(
	 CUST_ID    	--客户编码
	,YEAR           --年
	,MTH            --月
	,WH_ORG_ID    	--仓库机构编码
	,HS_ORG_ID    	--恒生机构编码
	,CUST_NAME    	--客户名称
	,LEGP_REP       --法人代表
	,ORG_ID         --组织机构编码
	,DOBIZ_LICENS   --营业执照
	,ET             --企业性质
	,REG_CAPI       --注册资本
	,REG_CAPI_CCY   --注册资本币种
	,CONP           --联系人
	,MOB_NO         --手机号
	,EML            --电子邮件
	,ADDR           --地址
	,MANAGE_SCP     --经营范围
	,INDT_TYPE      --行业类别
	,STA_TAX_CERTNO    --国税税务登记证号
	,LOC_TAX_CERTNO    --地税税务登记证号
	,UNI_SOCI_CRED_NO  --统一社会信用编号
	,ID_VLD_SDT    --证件有效开始日期
	,ID_VLD_EDT    --证件有效截止日期
	,LOAD_DT      --清洗日期
	)
	SELECT
	 CUST_ID    	--客户编码
	,YEAR           --年
	,MTH            --月
	,WH_ORG_ID    	--仓库机构编码
	,HS_ORG_ID    	--恒生机构编码
	,CUST_NAME    	--客户名称
	,LEGP_REP       --法人代表
	,ORG_ID         --组织机构编码
	,DOBIZ_LICENS   --营业执照
	,ET             --企业性质
	,REG_CAPI       --注册资本
	,REG_CAPI_CCY   --注册资本币种
	,CONP           --联系人
	,MOB_NO         --手机号
	,EML            --电子邮件
	,ADDR           --地址
	,MANAGE_SCP     --经营范围
	,INDT_TYPE      --行业类别
	,STA_TAX_CERTNO    --国税税务登记证号
	,LOC_TAX_CERTNO    --地税税务登记证号
	,UNI_SOCI_CRED_NO  --统一社会信用编号
	,ID_VLD_SDT    --证件有效开始日期
	,ID_VLD_EDT    --证件有效截止日期
	,LOAD_DT      --清洗日期
	FROM #TEMP_ORG_CUST  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_ORG_CUST TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_ORG_CUST TO xydc
GO
CREATE PROCEDURE dm.P_PUB_RIGH_INFO(IN @V_BIN_DATE numeric(8))
 
  /******************************************************************
  程序功能: 敏捷BI人员及机构权限报表
  编写者: rengz
  创建日期: 2018-01-12
  简介：正常人员及机构，与其权限所辖的机构进行关联
        --机构权限信息维表
            总部角色：所有营业部权限
            一级分公司：一级分公司下挂所有二级分公司、营业部
            二级分公司：二级分公司下挂所有营业部
            营业部    ：本营业部数据
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明

  *********************************************************************/
 begin 

    --declare @v_bin_date numeric(8); 
     
    set @v_bin_date =@v_bin_date;

------------------------
 -- 人员权限信息维表
------------------------ 
      
    --删除计算期数据
    delete from DM.T_PUB_PRSN_RIGH_INFO where LOAD_DT<=@v_bin_date;
    commit;  

   insert into DM.T_PUB_PRSN_RIGH_INFO(
    LOAD_DT,
    HR_ID               ,
	AFA_ID              ,
	EMP_NAME           ,
	ORG_TYPE             ,
	XY_ORG_ID            ,
	WH_ORG_ID            ,
	HS_ORG_ID            ,
	HR_ORG_ID            ,
	DIRECTL_ORG_ID       ,
	SCDY_ORG_ID          ,
	PRI_ORG_ID           ,
	ORG_NAME             ,
	DIRECTL_ORG_NAME     ,
	SCDY_ORG_NAME        ,
	PRI_ORG_NAME    )   
select a.rq                        as 日期,
       a.hrid                      as 人力编号,
       a.afatwo_ygh                as AFA编号,
       a.ygxm                      as 员工姓名,
       b.branch_type               as 机构类型,
       c.dep_code                  as 新意机构编码,
       a.pk_org                    as 机构仓库编码,
       a.jgbh_hs                   as 机构恒生编码,
       b.hr_pk                     as 机构人力编号,
       b.father_branch_hrpk_direct as 机构直属编号,
       secondary_branch_hrpk       as 机构二级编号,
       father_branch_hrpk_root     as 机构一级编号,
       b.hr_name                   as 机构名称,
       father_branch_name_direct   as 机构直属名称,
       secondary_branch_name       as 机构二级名称,
       father_branch_name_root     as 机构一级名称   
 from dba.t_edw_person_d a
  left join dba.t_dim_org b on a.pk_org = b.pk_org
  left join DBA.T_ODS_CF_V_BRANCH c on convert(varchar,b.branch_no)=convert(varchar,c.branch_no)
 where a.rq = @v_bin_date
   and a.ygzt = '正常人员'
   and a.rylx='员工' 
    and is_virtual=0 
    and hrid is not null;

commit;

------------------------
 -- 机构权限信息维表
------------------------ 
 
    --删除计算期数据
    delete from DM.T_PUB_ORG_RIGH_INFO where LOAD_DT <=@v_bin_date;
    commit;  

--drop table #t_jg;
    select  distinct pk_org,a.branch_no,hr_name,b.dep_code as xy_pk_org,
        case when  a.branch_type ='总部'               then  '总部'
             when  hr_pk=father_branch_hrpk_root     then '一级分公司'
             when  secondary_branch_hrpk is not null then '二级分公司'
             when  hr_pk<>father_branch_hrpk_direct or a.branch_type ='营业部' then '营业部'
         end jglb  ,
        father_branch_hrpk_root,
        father_branch_name_root,
        father_branch_hrpk_direct,
        father_branch_name_direct,
        secondary_branch_hrpk,
        secondary_branch_name
into #t_jg
from dba.t_dim_org  a
left join DBA.T_ODS_CF_V_BRANCH b on convert(varchar,b.branch_no)=convert(varchar,a.branch_no)
order by jglb ;

commit;

delete from DM.T_PUB_ORG_RIGH_INFO where load_dt <=@v_bin_date;
insert into  DM.T_PUB_ORG_RIGH_INFO
(	ORG_TYPE             ,
	WH_ORG_ID            ,
	HS_ORG_ID            ,
	XY_ORG_ID            ,
	ORG_NAME             ,
	UDRBRL_WH_ORG_ID     ,
	UDRBRL_HS_ORG_ID     ,
	UDRBRL_XY_ORG_ID     ,
	UDRBRL_ORG_NAME      ,
	LOAD_DT              
)
select  jglb                 as ORG_TYPE ,--- 机构类别
       pk_org               as WH_ORG_ID ,--- 仓库机构编码
       branch_no            as HS_ORG_ID ,--- 恒生机构编码
       xy_pk_org            as XY_ORG_ID ,--- 新意机构编码
       hr_name              as ORG_NAME ,--- 机构名称
       case when permission_pk_org is null then ''  else permission_pk_org       end  as UDRBRL_WH_ORG_ID ,--- 下挂仓库机构编码
       case when permission_branch_no is null then ''  else permission_branch_no end  as UDRBRL_HS_ORG_ID ,--- 下挂恒生机构编码
       permission_xy_pk_org  as UDRBRL_XY_ORG_ID ,--- 下挂新意机构编码
       case when permission_hr_name is null then ''  else permission_hr_name     end as UDRBRL_ORG_NAME ,--- 下挂机构名称
       @v_bin_date           as LOAD_DT  --- 清洗日期
into #t_fgs
  from (select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join (select distinct pk_org, branch_no, hr_name,xy_pk_org, '总部' as fz
                      from #t_jg
                     where jglb <> '总部'
                       and jglb is not null) b
            on a.jglb = b.fz
         where a.jglb = '总部' ---总部权限单位
        union all
        select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join #t_jg b
            on a.hr_name = b.father_branch_name_root
         where a.jglb = '一级分公司' ---一级分公司
        union all
        select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join #t_jg b
            on a.hr_name = b.secondary_branch_name
         where a.jglb = '二级分公司' ---二级分公司
        union all
        select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join #t_jg b
            on a.pk_org = b.pk_org and a.hr_name=b.hr_name
         where a.jglb = '营业部' ---营业部
        ) s
 order by s.jglb,s.pk_org;



commit;


end
GO
GRANT EXECUTE ON dm.P_PUB_RIGH_INFO TO query_dev
GO
CREATE PROCEDURE dm.P_PUB_SECU_INDT_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 证券行业类型维表
  编写者: DCY
  创建日期: 2017-12-11
  简介：证券行业类型维表清洗
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
  
   --PART0 删除要回洗的数据
  DELETE FROM DM.T_PUB_SECU_INDT_TYPE ;
  
  
   --开始插入数据
  INSERT INTO DM.T_PUB_SECU_INDT_TYPE
  (
    SECU_CD               --证券代码
   ,SECU_NAME             --证券名称
   ,MKT_TYPE              --市场类型
   ,wind_PRI_INDT_CD      --wind一级行业代码
   ,wind_PRI_INDT_NAME    --wind一级行业名称
   ,wind_SCDY_INDT_CD     --wind二级行业代码
   ,wind_SCDY_INDT_NAME   --wind二级行业名称
   ,wind_THRDY_INDT_CD    --wind三级行业代码
   ,wind_THRDY_INDT_NAME  --wind三级行业名称
   ,CITIC_PRI_INDT_CD     --中信一级行业代码
   ,CITIC_PRI_INDT_NAME   --中信一级行业名称
   ,CITIC_SCDY_INDT_CD    --中信二级行业代码
   ,CITIC_SCDY_INDT_NAME  --中信二级行业名称
   ,CITIC_THRDY_INDT_CD   --中信三级行业代码
   ,CITIC_THRDY_INDT_NAME --中信三级行业名称
   ,LOAD_DT              --清洗日期   
   )
  
  SELECT 
   A1.SECU_CD               --证券代码
  ,A1.SECU_NAME             --证券名称
  ,A1.MKT_TYPE              --市场类型
  ,A1.wind_PRI_INDT_CD      --wind一级行业代码
  ,A1.wind_PRI_INDT_NAME    --wind一级行业名称
  ,A2.wind_SCDY_INDT_CD     --wind二级行业代码
  ,A2.wind_SCDY_INDT_NAME   --wind二级行业名称
  ,A3.wind_THRDY_INDT_CD    --wind三级行业代码
  ,A3.wind_THRDY_INDT_NAME  --wind三级行业名称
  ,B1.CITIC_PRI_INDT_CD     --中信一级行业代码
  ,B1.CITIC_PRI_INDT_NAME   --中信一级行业名称
  ,B2.CITIC_SCDY_INDT_CD    --中信二级行业代码
  ,B2.CITIC_SCDY_INDT_NAME  --中信二级行业名称
  ,B3.CITIC_THRDY_INDT_CD   --中信三级行业代码
  ,B3.CITIC_THRDY_INDT_NAME --中信三级行业名称
  ,@V_BIN_DATE    --清洗日期   
  FROM
  (
  --wind一级行业代码名称
	Select
	 F16_1090 as SECU_CD                            --证券代码
	 ,ob_object_name_1090  as SECU_NAME             --证券名称
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --市场类型
     ,code as wind_PRI_INDT_CD                          --wind一级行业代码
	 ,a.name as wind_PRI_INDT_NAME    --wind一级行业名称
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,4)=substr(a.code,1,4)
	Where a.code Like '62%'
		  And a.levelnum=2
		  And F6_1400=1
		  And F4_1090 In ('A','B')
   )A1
  JOIN
  (
  --wind二级行业代码名称
	Select
	 F16_1090 as SECU_CD                            --证券代码
	 ,ob_object_name_1090  as SECU_NAME             --证券名称
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --市场类型
     ,code as wind_SCDY_INDT_CD                          --wind二级行业代码
	 ,replace (a.name,'Ⅱ','') as wind_SCDY_INDT_NAME    --wind二级行业名称
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,6)=substr(a.code,1,6)
	Where a.code Like '62%'
		  And a.levelnum=3
		  And F6_1400=1
		  And F4_1090 In ('A','B')		  
	)A2 ON A1.SECU_CD=A2.SECU_CD
   JOIN	
   (   
  --wind三级行业代码名称
	Select
	 F16_1090 as SECU_CD                            --证券代码
	 ,ob_object_name_1090  as SECU_NAME             --证券名称
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --市场类型
     ,code as wind_THRDY_INDT_CD                          --wind三级行业代码
	 ,replace (a.name,'Ⅲ','') as wind_THRDY_INDT_NAME    --wind三级行业名称
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,8)=substr(a.code,1,8)
	Where a.code Like '62%'
		  And a.levelnum=4
		  And F6_1400=1
		  And F4_1090 In ('A','B')			  
	)A3	ON A1.SECU_CD=A3.SECU_CD  
   LEFT JOIN	
   (     
  --中信一级行业代码名称
	Select
	 F16_1090 as SECU_CD                            --证券代码
	 ,ob_object_name_1090  as SECU_NAME             --证券名称
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --市场类型
     ,code as CITIC_PRI_INDT_CD                          --中信一级行业代码
	 ,a.name as CITIC_PRI_INDT_NAME    --中信一级行业名称
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,4)=substr(a.code,1,4)
	Where a.code Like 'b1%'
		  And a.levelnum=2
		  And F6_1400=1
		  And F4_1090 In ('A','B')		  
	)B1	ON A1.SECU_CD=B1.SECU_CD  
   LEFT JOIN	
   (     
  --中信二级行业代码名称
	Select
	 F16_1090 as SECU_CD                            --证券代码
	 ,ob_object_name_1090  as SECU_NAME             --证券名称
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --市场类型
     ,code as CITIC_SCDY_INDT_CD                          --中信二级行业代码
	 ,replace (a.name,'Ⅱ','') as CITIC_SCDY_INDT_NAME    --中信二级行业名称
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,6)=substr(a.code,1,6)
	Where a.code Like 'b1%'
		  And a.levelnum=3
		  And F6_1400=1
		  And F4_1090 In ('A','B')			  
	)B2	ON A1.SECU_CD=B2.SECU_CD  
   LEFT JOIN		
   (     
  --中信三级行业代码名称
	Select
	 F16_1090 as SECU_CD                            --证券代码
	 ,ob_object_name_1090  as SECU_NAME             --证券名称
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --市场类型
     ,code as CITIC_THRDY_INDT_CD                          --中信三级行业代码
	 ,replace (a.name,'Ⅲ','') as CITIC_THRDY_INDT_NAME    --中信三级行业名称
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,8)=substr(a.code,1,8)
	Where a.code Like 'b1%'
		  And a.levelnum=4
		  And F6_1400=1
		  And F4_1090 In ('A','B')			  
	)B3	ON A1.SECU_CD=B3.SECU_CD
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_SECU_INDT_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_SECU_INDT_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_SECU_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  程序功能: 证券类型维表
  编写者: DCY
  创建日期: 2017-11-24
  简介：证券类型维表清洗
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --初始清洗赋值-1
      
   --PART0 删除要回洗的数据
  DELETE FROM DM.T_PUB_SECU_TYPE ;
  
   --开始插入数据
  INSERT INTO DM.T_PUB_SECU_TYPE
  (
    SECU_TYPE_MCGY_ID    --证券类型大类编码
   ,SECU_TYPE_SUB_ID     --证券类型子类编码
   ,SECU_TYPE_MCGY_NAME  --证券类型大类名称
   ,SECU_TYPE_SUB_NAME   --证券类型子类名称
   ,LOAD_DT              --清洗日期
   )
	  
  SELECT DISTINCT 
	 NULL AS SECU_TYPE_MCGY_ID    --证券类型大类编码(暂时设置为空，后续再修改)
	,TOUS.stock_type AS  SECU_TYPE_SUB_ID     --证券类型子类编码
	, NULL AS SECU_TYPE_MCGY_NAME  --证券类型大类名称
	,DIC.DICT_PROMPT AS  SECU_TYPE_SUB_NAME --证券类型子类名称
    ,@V_BIN_DATE    --清洗日期 
	
  FROM DBA.T_ODS_UF2_SCLXDZ TOUS
  LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY DIC ON TOUS.STOCK_TYPE=DIC.SUBENTRY  AND   DIC.DICT_ENTRY=1206 -- 子类直接采用1206的字典
	-- LEFT JOIN DBA.T_EDW_T06_PUBLIC_CODE TETPC ON  TOUS.MKT_TYPE=TETPC.CODE_CD  AND FIELD_ENG_NAME='market_type_cd' --仓库市场类型
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --结束,清洗成功输出0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_SECU_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_SECU_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_VAR_ASSM(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_品种：资管产品（集合理财）
      编写者：chenhu
      创建日期：2017-11-30
      简介：
           集合理财基本信息
    *********************************************************************/

    COMMIT;
    --删除当日数据
    DELETE FROM DM.T_VAR_ASSM WHERE OCCUR_DT = @V_IN_DATE;
    
    --插入当日数据
    INSERT INTO DM.T_VAR_ASSM
        (PROD_CD,PROD_NAME,OCCUR_DT,IMGT_PD_TYPE,PURS_UNIT,FUND_CLS_END_DT,FRNT_CHAG_TYPE,INSM_SCP,INSM_STRA,EXPE_PAYF_RATE,TRD_STAT,PROD_SCAL,PROD_SETP_SCAL,
         REDP_DAYS,OPEN_DT,INSM_MNGR_NAME,LOAD_DT)
    SELECT PDP.SECCODE AS PROD_CD                   --产品代码
         ,PDP.PRODUCT_NAME AS PROD_NAME            --产品名称
         ,PFC.LOAD_DT AS OCCUR_DT            --业务日期
         ,'1' AS IMGT_PD_TYPE                --资管产品类型 : 1 集合理财； 2 定向理财
         ,PFC.PURCHASE_UNIT AS PURS_UNIT       --申购单位
         ,PFC.CLOSE_DAY AS FUND_CLS_END_DT     --基金封闭结束日期
         ,PFC.CHARGE_TYPE AS FRNT_CHAG_TYPE     --前后收费类型
         ,PFC.INVESTMENT_SCOPE AS INSM_SCP          --投资范围
         ,CASE WHEN PFC.INVESTMENT_STRATEGY = '' THEN NULL ELSE PFC.INVESTMENT_STRATEGY END AS INSM_STRA       --投资策略
         ,PFC.INVESTMENT_EXPECTED AS EXPE_PAYF_RATE    --预期收益率
         ,CASE WHEN PFC.TRADING_STATUS = '' THEN NULL ELSE PFC.TRADING_STATUS END AS TRD_STAT            --交易状态
         ,PFC.FINALNET_ASSETS AS PROD_SCAL           --产品规模
         ,PFC.ESTABLISHMENT_SCALE AS PROD_SETP_SCAL      --产品成立规模
         ,CASE WHEN PFC.REDEEMABLETART_DATE = '' THEN NULL ELSE CONVERT(NUMERIC(10,0),PFC.REDEEMABLETART_DATE) END AS REDP_DAYS           --赎回天数
         ,PFC.OPEN_DATE AS OPEN_DT             --开放日期
         ,PFC.INVEST_MANAGER AS INSM_MNGR_NAME     --投资经理名称
         ,PFC.LOAD_DT           --清洗日期
    FROM DBA.T_EDW_PD_T_PROD_FINANCIAL_COLLECTION PFC
    LEFT JOIN DBA.T_EDW_PD_V_PROD_DC_PRODUCT PDP
    ON PFC.PRODUCT_ID = PDP.PRODUCT_ID
    AND PFC.LOAD_DT = PDP.LOAD_DT
    WHERE PFC.LOAD_DT = @V_IN_DATE
    AND PDP.SECCODE IS NOT NULL;          -- PRODUCT表为已入库的产品表，关联不到的说明未入库
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_ASSM TO xydc
GO
CREATE PROCEDURE dm.P_VAR_BKCM_PFVU(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_品种：银行理财_收益凭证
      编写者：chenhu
      创建日期：2017-11-23
      简介：
        银行理财和收益凭证产品信息
    *********************************************************************/

    COMMIT;
    
    --删除当日数据
    DELETE FROM DM.T_VAR_BKCM_PFVU WHERE OCCUR_DT = @V_IN_DATE;
    --插入当日数据
    INSERT INTO DM.T_VAR_BKCM_PFVU
        (PRODTA_NO,PROD_CD,OCCUR_DT,PROD_TYPE,PROD_NAME,PROD_ALIAS,PROD_CORP,PROD_MATY,RISK_RAK,INSM_TYPE,PAYF_TYPE,EXPE_RCKON_RETN,CCY_TYPE,COLL_STRT_DT,COLL_END_DT,
         SUBS_END_DT,PROD_SETP_DT,PROD_END_DT,RCDINFO_END_DT,PROD_BACK_N,ORDR_MODE,PROD_STAT,SUB_UNIT,IDV_FST_LOW_AMT,IDV_LOW_SUBS_AMT,IDV_LOW_PURS_AMT,LISTS_DAY_PURS_MAX_AMT,
         ORG_FST_LOW_AMT,ORG_LOW_SUBS_AMT,ORG_LOW_PURS_AMT,LOAD_DT)
    SELECT  PRODTA_NO	AS	PRODTA_NO  --产品TA编号
        ,PROD_CODE	AS	PROD_CD  --产品代码
        ,LOAD_DT	AS	OCCUR_DT  --业务日期
        ,PROD_TYPE	AS	PROD_TYPE  --产品类别
        ,PROD_NAME	AS	PROD_NAME  --产品名称
        ,PRODALIAS_NAME	AS	PROD_ALIAS  --产品别名
        ,PRODCOMPANY_NAME	AS	PROD_CORP  --产品公司
        ,PROD_TERM	AS	PROD_MATY  --产品期限
        ,PRODRISK_LEVEL	AS	RISK_RAK  --风险等级
        ,INVEST_TYPE	AS	INSM_TYPE  --投资类别
        ,INCOME_TYPE	AS	PAYF_TYPE  --收益类型
        ,PRODPRE_RATIO	AS	EXPE_RCKON_RETN  --预期年收益率
        ,MONEY_TYPE	AS	CCY_TYPE  --币种类别
        ,IPO_BEGIN_DATE	AS	COLL_STRT_DT  --募集开始日期
        ,IPO_END_DATE	AS	COLL_END_DT  --募集结束日期
        ,SUBCONF_ENDDATE	AS	SUBS_END_DT  --认购截止日期
        ,PROD_BEGIN_DATE	AS	PROD_SETP_DT  --产品成立日期
        ,PROD_END_DATE	AS	PROD_END_DT  --产品结束日期
        ,INTEREST_END_DATE	AS	RCDINFO_END_DT  --记息结束日期
        ,PROD_BACK_N	AS	PROD_BACK_N  --产品T+N天数
        ,EN_ENTRUST_WAY	AS	ORDR_MODE  --委托方式
        ,PROD_STATUS	AS	PROD_STAT  --产品状态
        ,SUB_UNIT	AS	SUB_UNIT  --认购/申购单位
        ,OPEN_SHARE	AS	IDV_FST_LOW_AMT  --个人首次最低金额
        ,MIN_SHARE	AS	IDV_LOW_SUBS_AMT  --个人最低认购金额
        ,MIN_SHARE2	AS	IDV_LOW_PURS_AMT  --个人最低申购金额
        ,MAX_PDSHARE	AS	LISTS_DAY_PURS_MAX_AMT  --单日申购最高金额
        ,MINSIZE	AS	ORG_FST_LOW_AMT  --机构首次最低金额
        ,ORG_LOWLIMIT_BALANCE	AS	ORG_LOW_SUBS_AMT  --机构最低认购金额
        ,ORG_LOWLIMIT_BALANCE2	AS	ORG_LOW_PURS_AMT  --机构最低申购金额
        ,LOAD_DT	AS	LOAD_DT  --清洗日期
    FROM DBA.T_EDW_UF2_PRODCODE
    WHERE LOAD_DT = @V_IN_DATE
    AND ( PRODTA_NO LIKE 'D%'         --银行理财
          OR PRODTA_NO LIKE 'C%');    --收益凭证
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_BKCM_PFVU TO xydc
GO
CREATE PROCEDURE dm.P_VAR_OPTN(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_品种：期权
      编写者：chenhu
      创建日期：2017-11-27
      简介：
             期权合约产品信息
    *********************************************************************/

    COMMIT;
    
    --删除当日数据
    DELETE FROM DM.T_VAR_OPTN WHERE OCCUR_DT = @V_IN_DATE;
    --插入当日数据
    INSERT INTO DM.T_VAR_OPTN
        (CONT_ID,DELIV_MODE_CD,OCCUR_DT,EXER_PRC,MKT_TYPE_CD,CONT_TYPE_CD,SUBJ_SECU_CD,CONT_UNIT,FST_TRD_DAY ,LAST_TRD_DAY,EXER_DAY,MATU_DAY,DELI_DAY,NO_COVR_CONT_NUM,
        PLMT_LMT_TYPE_CD,LPRIC_UNIT_UPLMT,LPRIC_UNIT_LWRB,MATU_DAY_FLAG,MPRIC_UNIT_UPLMT,MPRIC_UNIT_LWRB,OPEP_MARG_LOW_STD,TRD_CD,CONT_STAT_CD,MIN_QUOT_UNIT,OPTN_FEER,LOAD_DT)
    SELECT OPTION_CODE AS CONT_ID              --合约编码
        ,OPTION_MODE AS DELIV_MODE_CD           --交割方式代码：E 欧式 ，A 美式
        ,LOAD_DT AS OCCUR_DT                    --业务日期
        ,EXERCISE_PRICE AS EXER_PRC             --期权行权的价格
        ,EXCHANGE_TYPE AS MKT_TYPE_CD           --市场类型代码
        ,OPTION_TYPE AS CONT_TYPE_CD            --合约类型代码：C 认购, P 认沽
        ,STOCK_CODE AS SUBJ_SECU_CD             --标的证券代码
        ,AMOUNT_PER_HAND AS CONT_UNIT           --合约单位(合约乘数)
        ,BEGIN_DATE AS FST_TRD_DAY              --首个交易日
        ,END_DATE AS LAST_TRD_DAY               --最后交易日
        ,EXE_BEGIN_DATE AS EXER_DAY             --行权日
        ,EXE_END_DATE AS MATU_DAY               --到期日
        ,DELIVER_DATE AS DELI_DAY               --交割日
        ,UNDROP_AMOUNT AS NO_COVR_CONT_NUM      --未平仓合约数
        ,PRICE_LIMIT_KIND AS PLMT_LMT_TYPE_CD    --涨跌幅限制类型代码
        ,LIMIT_HIGH_AMOUNT AS LPRIC_UNIT_UPLMT   --限价单笔申报上限
        ,LIMIT_LOW_AMOUNT AS LPRIC_UNIT_LWRB     --限价单笔申报下限
        ,OPT_FINAL_STATUS AS MATU_DAY_FLAG       --到期日标志
        ,MKT_HIGH_AMOUNT AS MPRIC_UNIT_UPLMT     --市价单笔申报上限
        ,MKT_LOW_AMOUNT AS MPRIC_UNIT_LWRB       --市价单笔申报下限
        ,INITPER_BALANCE AS OPEP_MARG_LOW_STD    --开仓保证金最低标准
        ,OPTCONTRACT_ID AS TRD_CD                --交易代码
        ,OPTCODE_STATUS AS CONT_STAT_CD          --合约状态代码
        ,OPT_PRICE_STEP AS MIN_QUOT_UNIT         --最小报价单位
        ,NULL AS OPTN_FEER                      --期权费率
        ,LOAD_DT AS LOAD_DT                      --清洗日期  
    FROM DBA.T_EDW_UF2_OPTCODE
    WHERE LOAD_DT = @V_IN_DATE;
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_OPTN TO xydc
GO
CREATE PROCEDURE dm.P_VAR_PO_FUND(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_品种：公募基金
      编写者：chenhu
      创建日期：2017-11-29
      简介：
        公募基金基本信息
    *********************************************************************/

    COMMIT;
    --删除当日数据
    DELETE FROM DM.T_VAR_PO_FUND WHERE OCCUR_DT = @V_IN_DATE;
    
    --插入当日数据
    INSERT INTO DM.T_VAR_PO_FUND
        (PROD_CD,OCCUR_DT,CLS_PERI,ISS_QUO,REDP_ARVD_DAYS,IF_PAUSE_LARGE_AMT_PURS,PERF_CONT_BASI,INSM_SCP,INSM_STRA,INSM_MNGR,IF_IS_ETF,IF_IS_LOF,IF_ISQDII,
         CASTSL_PURS_LOW_AMT,IF_AGNS,SUBS_PERI,PROD_MNGR,FRNT_TERN_CHAG_TYPE,LOAD_DT) 
    SELECT PROD.SECCODE AS PROD_CD                       --产品代码
        ,PF.LOAD_DT AS OCCUR_DT                           --业务日期
        ,CASE WHEN PF.CLOSED_PERIOD = '' THEN NULL ELSE CONVERT(NUMERIC(10,0),PF.CLOSED_PERIOD) END AS CLS_PERI  --封闭期(月)
        ,NULL --PF.ISSUE_AMONUT 
         AS ISS_QUO                       --发行额度 （源头数据问题，后续更新）
        ,NULL --PF.REDEEMABLETART_DATE 
         AS REDP_ARVD_DAYS          --赎回到账天数 （源头数据问题，后续更新）
        ,CASE WHEN PF.SUSPENDED_LARGE_PURCHASE = '是' THEN 1 
               WHEN PF.SUSPENDED_LARGE_PURCHASE = '否' THEN 0
               ELSE NULL END AS IF_PAUSE_LARGE_AMT_PURS    --是否暂停大额申购
        ,PF.PERFORMANCE_BENCHMARK AS PERF_CONT_BASI                --业绩比较基准
        ,PF.INVESTMENT_SCOPE AS INSM_SCP                           --投资范围
        ,PF.INVESTMENT_STRATEGY AS INSM_STRA                       --投资策略
        ,PF.INVEST_MANAGER AS INSM_MNGR                   --投资经理
        ,CASE WHEN PF.IS_ETF = '' THEN NULL ELSE CONVERT(INT,PF.IS_ETF) END AS IF_IS_ETF                           --是否是ETF
        ,CASE WHEN PF.IS_LOF = '' THEN NULL ELSE CONVERT(INT,PF.IS_LOF) END AS IF_IS_LOF                           --是否是LOF
        ,CASE WHEN PF.IS_QDII = '' THEN NULL ELSE CONVERT(INT,PF.IS_QDII) END AS IF_ISQDII                           --是否是QDII
        ,PF.MIN_SCHEDULED_AMOUNT AS CASTSL_PURS_LOW_AMT    --定投申购最低金额
        ,NULL --PF.ISFOR_SALE 
         AS IF_AGNS                           --是否代销 （源头数据问题，后续更新）
        ,NULL --PF.OPENED_PERIOD 
         AS SUBS_PERI                        --认购期（源头数据问题，后续更新）
         ,NULL AS PROD_MNGR                        --产品经理 (后续更新）
        ,PF.CHARGE_TYPE AS FRNT_TERN_CHAG_TYPE              --前后端收费类型
        ,PF.LOAD_DT AS LOAD_DT                           --清洗日期
    FROM DBA.T_EDW_PD_T_PROD_PUBLICFUND PF
    LEFT JOIN DBA.T_EDW_PD_V_PROD_DC_PRODUCT PROD
    ON PF.PRODUCT_ID = PROD.PRODUCT_ID
    AND PF.LOAD_DT = PROD.LOAD_DT
    WHERE PF.LOAD_DT = @V_IN_DATE
    AND PROD.SECCODE IS NOT NULL
    AND PROD.SECCODE <> '';          -- PRODUCT表为已入库的产品表，关联不到的说明未入库
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_PO_FUND TO xydc
GO
CREATE PROCEDURE dm.P_VAR_PROD_OTC(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      功能说明：私财集市_品种：场外产品维表
      编写者：chenhu
      创建日期：2017-11-30
      简介：
           场外产品的基本信息
           
      -- 增加场内产品  update by chenhu  20180119
      -- 增加产内三种类型：  'A'  基金申赎， 'N'  ETF申赎， 'K'  基金认购，'M'  ETF认购； 场外两只代码：940002,940003    update by chenhu 20180207
    *********************************************************************/

    COMMIT;
    --删除当日数据
    DELETE FROM DM.T_VAR_PROD_OTC WHERE OCCUR_DT = @V_IN_DATE;
    
    --插入当日数据(场外）
    INSERT INTO DM.T_VAR_PROD_OTC
        (PROD_CD,OCCUR_DT,TA_NO,PROD_NAME,PROD_TYPE,PROD_INVER_TYPE,IF_KEY_PROD,RISK_RAK,CSTD_ORG,MNG_PSN_NAME,END_DT,PROD_STAT,PROD_PAYF_FETUR,
         SETP_DT,TRD_CCY,SAVC_PERI,CSTD_BANK,SUBS_STRT_TIME,SUBS_END_TIME,BEGN_PURC_AMT,LOAD_DT)
    SELECT PP.PROD_TRD_CD AS PROD_CD      --产品代码  
         ,PP.LOAD_DT AS OCCUR_DT      --业务日期
         ,PP.TA_NO AS TA_NO      --TA编号  
         ,PP.PROD_NAME AS PROD_NAME      --产品名称         
         ,PP.PROD_TYPE AS PROD_TYPE      --产品类型         
         ,PP.INVEST_TO_TYPE AS PROD_INVER_TYPE      --产品投向类型
         ,CASE WHEN EMPHASIS_FUND='' THEN NULL ELSE CONVERT(INT,PUB.EMPHASIS_FUND) END AS IF_KEY_PROD      --是否重点产品   
         ,PP.RISK_RAK AS RISK_RAK      --风险等级          
         ,PP.CSTD_PSN AS CSTD_ORG      --托管机构          
         ,PP.BASEGODLEN_MGR_PSN_NAME AS MNG_PSN_NAME      --管理人名称    
         ,CASE WHEN PP.TML_DT='' THEN NULL ELSE CONVERT(INT,SUBSTR(PP.TML_DT,1,4))*10000 + CONVERT(INT,SUBSTR(PP.TML_DT,6,2))*100 + CONVERT(INT,SUBSTR(PP.TML_DT,9,2)) END AS END_DT      --终止日期            
         ,PP.MULITGODLEN_BASEGODLEN_STAT AS PROD_STAT      --产品状态         
         ,PP.INCM_FETUR AS PROD_PAYF_FETUR      --产品收益特征
         ,CASE WHEN PP.SETUP_DT='' THEN NULL ELSE CONVERT(INT,SUBSTR(PP.SETUP_DT,1,4))*10000 + CONVERT(INT,SUBSTR(PP.SETUP_DT,6,2))*100 + CONVERT(INT,SUBSTR(PP.SETUP_DT,9,2)) END AS SETP_DT      --成立日期           
         ,UP.MONEY_TYPE AS TRD_CCY      --交易币种           
         ,PP.DURA_DT AS SAVC_PERI      --存续期           
         ,UP.TRUSTEE_BANK AS CSTD_BANK      --托管银行         
         ,PP.SCRP_STRT_DT AS SUBS_STRT_TIME      --认购开始时间
         ,PP.SCRP_END_DT AS SUBS_END_TIME      --认购结束时间 
         ,UP.MIN_SHARE2 AS BEGN_PURC_AMT      --起购金额     
         ,PP.LOAD_DT AS LOAD_DT      --清洗日期 
    FROM (     
			SELECT * FROM (
			SELECT A.*,ROW_NUMBER() OVER  (PARTITION BY PROD_TRD_CD ORDER BY VOU_INPT_TIME DESC) RN
			FROM DBA.T_EDW_PD_V_PROD_PRODUCTINFO A WHERE (A.REC_STATUS IN ('1','2') OR A.PROD_TRD_CD IN ('940002','940003') ) AND A.LOAD_DT  = @V_IN_DATE
			) B
			WHERE B.RN=1   
    ) PP
    LEFT JOIN DBA.T_EDW_UF2_PRODCODE UP
    ON PP.PROD_TRD_CD = UP.PROD_CODE
    AND PP.LOAD_DT = UP.LOAD_DT
    LEFT JOIN DBA.T_EDW_PD_T_PROD_PUBLICFUND PUB
    ON PP.PROD_NO = PUB.PRODUCT_ID
    AND PP.LOAD_DT = PUB.LOAD_DT
    WHERE PP.LOAD_DT = @V_IN_DATE
    AND  PP.PROD_TRD_CD IS NOT NULL
    AND  PP.PROD_TRD_CD <>''
    AND ( PP.REC_STATUS IN ('1','2') OR PP.PROD_TRD_CD IN ('940002','940003') );            --记录状态：'-1','删除','1','未入库','2','入库','0','草稿' ,   940002,940003 特殊处理

   --插入当日数据(场内）
    INSERT INTO DM.T_VAR_PROD_OTC
        (PROD_CD,OCCUR_DT,TA_NO,PROD_NAME,PROD_TYPE,PROD_INVER_TYPE,IF_KEY_PROD,RISK_RAK,CSTD_ORG,MNG_PSN_NAME,END_DT,PROD_STAT,PROD_PAYF_FETUR,
         SETP_DT,TRD_CCY,SAVC_PERI,CSTD_BANK,SUBS_STRT_TIME,SUBS_END_TIME,BEGN_PURC_AMT,LOAD_DT)
    SELECT A.STOCK_CODE AS PROD_CD
        ,A.LOAD_DT AS OCCUR_DT
        ,NULL AS TA_NO
        ,A.STOCK_NAME AS PROD_NAME
        ,CASE WHEN B.JJLB LIKE '%公募%' THEN '公募基金' 
              WHEN B.JJLB LIKE '%私募%' THEN '私募基金' 
              WHEN B.JJLB LIKE '%基金专户%' THEN '基金专户' 
              WHEN B.JJLB LIKE '%集合理财%' THEN '集合理财' 
               WHEN B.JJLB IS NULL THEN '未设置' 
              ELSE B.JJLB END  AS PROD_TYPE
        ,CASE WHEN B.JJLB LIKE '%货币%' THEN '货币' 
              WHEN B.JJLB LIKE '%股票%' THEN '权益' 
              WHEN B.JJLB LIKE '%债券%' THEN '债券' 
              WHEN B.JJLB IS NULL THEN '未设置' 
              ELSE B.JJLB END AS PROD_INVER_TYPE
        ,NULL AS IF_KEY_PROD
        ,CASE WHEN C.DICT_PROMPT LIKE '%R%' THEN SUBSTR(C.DICT_PROMPT,4) ELSE C.DICT_PROMPT END AS RISK_RAK
        ,NULL AS CSTD_ORG
        ,B.GSMC AS MNG_PSN_NAME
        ,A.DELIST_DATE AS END_DT
        ,NULL AS PROD_STAT
        ,CASE WHEN B.JJLB LIKE '%货币%' THEN '现金型' 
              WHEN B.JJLB LIKE '%股票%' THEN '浮动收益' 
              WHEN B.JJLB LIKE '%债券%' THEN '类固定收益' 
              ELSE NULL END AS PROD_PAYF_FETUR
        ,ISSUE_DATE AS SETP_DT
        ,A.MONEY_TYPE AS TRD_CCY
        ,NULL AS SAVC_PERI
        ,NULL AS CSTD_BANK
        ,NULL AS SUBS_STRT_TIME
        ,NULL AS SUBS_END_TIME
        ,A.LOW_BALANCE AS BEGN_PURC_AMT
        ,A.LOAD_DT AS LOAD_DT
    FROM DBA.T_EDW_UF2_STKCODE A
    LEFT JOIN DBA.T_DDW_D_JJ B
    ON B.NIAN=SUBSTR(CONVERT(VARCHAR,A.LOAD_DT),1,4) AND B.YUE=SUBSTR(CONVERT(VARCHAR,A.LOAD_DT),5,2)
    AND A.STOCK_CODE = B.JJDM
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY C ON C.DICT_ENTRY=2506
    AND CONVERT(VARCHAR,A.ELIG_RISK_LEVEL) = C.SUBENTRY
    WHERE A.STOCK_TYPE IN ('1','6','L','T','j','l','A','N','K','M') --/*基金，投资基金，LOF基金，ETF基金，货币ETF基金，国债ETF基金，基金申赎，ETF申赎，基金认购，ETF认购*/
    AND A.LOAD_DT=@V_IN_DATE 
    AND A.STOCK_CODE NOT IN (
    SELECT DISTINCT PROD_CD FROM DM.T_VAR_PROD_OTC WHERE OCCUR_DT=@V_IN_DATE 
    );
        
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_PROD_OTC TO xydc
GO
CREATE PROCEDURE dm.tmp_ast_odi(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能: 客户普通资产表
  编写者: rengz
  创建日期: 2017-11-16
  简介：不包括信用及衍生品等的普通账户资产，日更新
       主要指标参考全景图日表日更新dba.tmp_ddw_khqjt_d_d进行处理
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             2017-12-06               rengz              修订私募基金，根据柜台产品表进行分类 dba.t_edw_uf2_prodcode where  prodcode_type='j'
             2017-12-20               rengz              增加公募基金市值
             2018-1-31                rengz              根据经纪业务总部要求，增加 股基市值、其他产品市值（未设置或设置类型为空）、其他资产、约定购回质押市值、期末资产等字段 
             2018-2-23                rengz              对201601-201704高优先级表数据缺失部分，利用全景图日表进行补充 
             2018-4-12                rengz              1、增加股票质押负债
                                                         2、未到账金额修正股票质押负债
                                                         3、其他资产调整为：TOT_AST_N_CONTAIN_NOTS（总资产_不含限售股）+股票质押负债
                                                         4、期末资产final_ast即为经纪业务总部要求的总资产=股基市值+资金余额+债券市值+回购市值+产品总市值+其他资产+未到账资金+股票质押负债+融资融券总资产+约定购回质押市值+限售股市值+个股期权市值
  *********************************************************************/
   --declare @v_bin_date         numeric(8); 
    declare @v_bin_mth          varchar(2);
    declare @v_bin_year         varchar(4);   
    declare @v_bin_20avg_start  numeric(8,0);---最近20个交易日开始日期
    declare @v_bin_20avg_end    numeric(8,0);---最近20个交易日结束日期

	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date = @v_bin_date;

    --生成衍生变量
    set @v_bin_mth  =substr(convert(varchar,@v_bin_date),5,2);
    set @v_bin_year =substr(convert(varchar,@v_bin_date),1,4);
    set @v_bin_20avg_start =(select b.rq
                             from    dba.t_ddw_d_rq      a
                             left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=21      --(T-21日)打新 t-2日前20天
                             where a.rq=@v_bin_date);
    set @v_bin_20avg_end =(select b.rq
                            from    dba.t_ddw_d_rq      a
                            left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=2       --(T-2日)打新t-2日
                            where a.rq=@v_bin_date);	
    commit;

   
    --删除计算期数据
    delete from dm.t_ast_odi where load_dt =@v_bin_date;
    commit;

    ---插入基础客户信息
    insert into dm.t_ast_odi(
                            OCCUR_DT,               --清洗日期 
                            CUST_ID,                --客户编码
                            main_cptl_acct,         --主资金账号
                            TOT_AST_N_CONTAIN_NOTS, --总资产_不含限售股
                            RCT_20D_DA_AST,	        --近20日日均资产
                            SCDY_MVAL,	            --二级市值
                            NO_ARVD_CPTL,	        --未到账资金
                            CPTL_BAL,	            --资金余额
                            CPTL_BAL_RMB,	        --资金余额人民币
                            CPTL_BAL_HKD,	        --资金余额港币
                            CPTL_BAL_USD,	        --资金余额美元 
                            HGT_MVAL,	            --沪港通市值
                            SGT_MVAL,	            --深港通市值
                            PSTK_OPTN_MVAL,	        --个股期权市值
                            IMGT_PD_MVAL,	        --资管产品市值
                            BANK_CHRM_MVAL,	        --银行理财市值
                            SECU_CHRM_MVAL,         --证券理财市值 
                            --FUND_SPACCT_MVAL,     --基金专户市值
                            STKT_FUND_MVAL,         --股票型基金市值
                            --STKPLG_LIAB,            --股票质押负债
                            LOAD_DT)
    select rq
       ,khbh_hs as client_id
       ,zjzh fund_account
       ,zzc         --- 包括：资金余额、未到账资金、二级市值、开基市值、资管产品市值、融资融券净资产、约定购回净资产、 银行理财持有金额、证券理财产品额 
       ,zzc_20rj    --- 20日均总资产：工作日
       ,ejsz
       ,wdzzj
       ,zjye
       ,zjye_rmb
       ,zjye_gb
       ,zjye_my
       ,hgtsz_rmb   ---沪港通市值
       ,sgtsz_rmb   ---深港通市值
       ,qqsz        ---期权市值
       ,zgcpsz      ---资管产品市值
       ,yhlccyje    ---银行理财持有金额
       ,zqlccpe     ---证券理财产品额 
       --,jjzhsz    ---基金专户市值
       ,gjsz        ---股票型基金市值
       ,rq as load_dt
    from dba.tmp_ddw_khqjt_d_d
    where rq=@v_bin_date
     and jgbh_hs not in  ('5','55','51','44','9999');  ---modify by rengz 20180212 剔除总部客户
  commit;

------------------------
  -- 体外市值
------------------------

        select a.zjzh,
               case when a.yrdh_flag = '0' then 1
                    when a.yrdh_flag = '1' and a.tn_sz > 0 then a.bzjzh_tn_sz / a.tn_sz else 1 / b.cnt
               end                      as tn_sz_fencheng,
               tw_sz * tn_sz_fencheng   as tw_zc_20avg,----体外资产
               d.avg_zzc_20d            as tn_zc_20avg ----体内资产
          into #t_twzc
          from dba.t_index_assetinfo_v2 a
        -- 一人多户处理
          left join (select id_no, count(distinct zjzh) as cnt
                       from dba.t_index_assetinfo_v2
                      where init_date = @v_bin_date
                        and yrdh_flag = '1'
                      group by id_no) b --init_date         --update
            on a.id_no = b.id_no
        -- 体内20日均总资产计算 （总资产未修正）
          left join (select zjzh, sum(zzc) / 20         as avg_zzc_20d
                       from dba.tmp_ddw_khqjt_d_d
                      where rq >= @v_bin_20avg_start
                        and rq <= @v_bin_20avg_end
                      group by zjzh) d
            on a.zjzh = d.zjzh
         where a.init_date = @v_bin_date;
      
      commit;

    update dm.t_ast_odi 
       set OUTMARK_MVAL = coalesce(tw_zc_20avg, 0) 
    from dm.t_ast_odi  a 
    left join #t_twzc  b on a.main_cptl_acct = b.zjzh  
     where 
           a.occur_dt  = @v_bin_date;
    commit;

------------------------
  -- 股基市值 三板市值 A股期末市值 B股期末市值 私募基金市值
------------------------
  select 
       zjzh
       ,sum(case when zqfz1dm='11' and b.sclx in ('01','02') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agsz     ---A股期末市值
	   ,sum(case when zqfz1dm='12' and b.sclx in ('03','04') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bgsz     ---B股期末市值 
       ,sum(case when a.zqlx in ('10', 'A1', -- A股      包含 深港通、沪港通、三板
                                 '17', '18', -- B股
                                 '11',       -- 封闭式基金
                                 '1A',       -- ETF
                                 '74', '75', -- 权证
                                 '19'        -- LOF --含场内开基
                                ) then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                   as gjsz            ---股基市值

       ,sum(case when zqfz1dm='11'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agqmsz          ---A股期末市值_私财 包含 深港通、沪港通 
       ,sum(case when zqfz1dm in('20','22')then JRCCSZ*c.turn_rmb/turn_rate else 0  end )        as sbsz            ---三板市值
       ,sum(case when zqfz1dm='14'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as fbsjjqmsz       ---封闭式基金期末市值_私财  
       ,sum(case when zqfz1dm='18'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as etfqmsz         ---ETF期末市值_私财 
       ,sum(case when zqfz1dm='19'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as lofqmsz         ---LOF期末市值_私财 
       ,sum(case when zqfz1dm='25'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as cnkjqmsz        ---场内开基期末市值_私财 
       ,sum(case when zqfz1dm='30'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bzqqmsz         ---标准券期末市值_私财 
       ,sum(case when zqfz1dm='21'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as hgqmsz          ---回购期末市值_私财 
  into #t_sz
  from dba.T_DDW_F00_KHMRCPYKHZ_D                     a
  left join dba.T_DDW_D_ZQFZ                          b on a.zqlx=b.zqlx AND a.sclx=b.sclx
  left join  dba.T_EDW_T06_YEAR_EXCHANGE_RATE         c on a.tjrq between c.star_dt and c.end_dt 
                                                       and c.curr_type_cd = case
                                                                            when a.zqlx = '18' and a.sclx = '05' then  'USD'
                                                                            when a.zqlx = '17'                   then 'USD'
                                                                            when a.zqlx = '18'                   then  'HKD'
                                                                            else  'CNY'
                                                                            end
  left join dba.t_ddw_d_jj                            d on a.zqdm=d.jjdm and d.nian=@v_bin_year and d.yue=@v_bin_mth
  where a.load_dt= @v_bin_date
    and a.sclx in( '01','02','03','04','05','0G','0S')
  group by zjzh; 

  commit;


  update dm.t_ast_odi 
       set  
           STKF_MVAL     = coalesce(gjsz, 0), --股基市值 
           SB_MVAL       = coalesce(sbsz, 0), --三板市值 
           A_SHR_MVAL    = coalesce(agsz, 0), --A股市值
           B_SHR_MVAL    = coalesce(bgsz, 0)  --B股市值
    from dm.t_ast_odi a
    left join   #t_sz b on a.main_cptl_acct = b.zjzh
     where  a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- 公募基金、私募基金市值
------------------------
    select a.zjzh
          ,SUM(case when b.lx = '公募-货币型' then a.qmsz_cw_d else 0 end)                                                                          as hjsz         -- 货基市值
          ,SUM(case when b.lx in( '公募-股票型','未设置') or b.lx is null then a.qmsz_cw_d else 0 end)                                              as gjsz         -- 股基市值(包含未定义)
          ,SUM(case when b.lx = '公募-债券型' then a.qmsz_cw_d else 0 end)                                                                          as zjsz         -- 债基市值
          ,SUM(case when b.lx in ('基金专户-股票型','基金专户-债券型')  then a.qmsz_cw_d else 0 end)                                                as jjzhsz       -- 基金专户市值
          ,SUM(case when b.lx in( '公募-股票型','公募-债券型','公募-货币型','基金专户','未设置') or b.lx is null then a.qmsz_cw_d else 0 end)       as kjsz         -- 开基市值(不含资管产品市值)
          ,SUM(case when b.lx in( '集合理财-股票型','集合理财-债券型','集合理财-货币型') then a.qmsz_cw_d else 0 end)                               as zgcpsz       -- 资管产品市值
          ,SUM(case when b.lx in( '集合理财-债券型','集合理财-货币型') then a.qmsz_cw_d else 0 end)                                                 as gdsylzgcpsz  -- 固定收益类资管产品市值
          ,SUM(case when b.lx in( '公募-股票型','公募-债券型','公募-货币型') then a.qmsz_cw_d else 0 end)                                           as gmsz         -- 公募基金市值
          ,SUM(case when b.lx in( '私募-股票型','私募-债券型') then a.qmsz_cw_d else 0 end)                                                         as smsz         -- 私募基金市值 
          ,SUM(case when b.lx ='未设置' or b.lx is null  then a.qmsz_cw_d else 0 end)                                                               as qtcpsz       -- 其他产品市值 
          ,SUM(case when b.lx in( '公募-货币型') then a.qmsz_cn_d else 0 end)                                                                       as cnhbxjjsz    -- 场内货币型基金市值_期末   
          ,SUM(a.qmsz_cw_d)                                                                                                                         as cwjjsz       -- 场外基金总市值
    into #t_sz_jj   
    --select *
      from dba.t_ddw_xy_jjzb_d as a
      left outer join (select jjdm, jjlb as lx                           -----与客户全景图略有差异，全景图直接使用lx字段，基金实际包括了私募基金
                         from dba.t_ddw_d_jj
                        where nian || yue =
                              (select MAX(nian || yue)
                                 from dba.t_ddw_d_jj
                                where nian || yue <
                                      convert(varchar(6), FLOOR(@v_bin_date / 100)))) as b
        on a.jjdm = b.jjdm
     where a.rq = @v_bin_date
     group by a.zjzh;

  commit;

 
  update dm.t_ast_odi  
       set 
           PTE_FUND_MVAL = coalesce(smsz, 0),               --私募基金市值
           PO_FUND_MVAL  = coalesce(gmsz, 0),               --公募基金市值 
           FUND_SPACCT_MVAL = coalesce(jjzhsz, 0),          --基金专户市值
           OTH_PROD_MVAL    = coalesce(qtcpsz, 0),          --其他产品市值                                 
           PROD_TOT_MVAL    = coalesce(cwjjsz, 0) + BANK_CHRM_MVAL+	        --银行理财市值
                                                  SECU_CHRM_MVAL            --证券理财市值      
                                                            --产品总市值      
    from       dm.t_ast_odi a
    left join  #t_sz_jj     b on a.main_cptl_acct = b.zjzh
     where 
        a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- 限售股市值:根据张琦意见，限售股市值历史数据修正过，故依据全景图进行修正
------------------------
    commit;   

    update dm.t_ast_odi  
       set NOTS_MVAL = coalesce(xsgsz, 0)                --限售股市值
    from dm.t_ast_odi  a
    left join dba.tmp_ddw_khqjt_d_d  b on convert(varchar,a.main_cptl_acct) = convert(varchar,b.zjzh) and a.occur_dt=b.rq
     where  a.occur_dt = @v_bin_date;

    commit;
    ------------------------
    -- 总资产 含限售股
    ------------------------
    update dm.t_ast_odi a
       set TOT_AST_CONTAIN_NOTS = coalesce(TOT_AST_N_CONTAIN_NOTS, 0) +
                                  coalesce(NOTS_MVAL, 0) ---总资产_含限售股
     where a.occur_dt = @v_bin_date;
    commit;

    ------------------------
    -- 场内 场外基金市值
    ------------------------
    select zjzh
           ,sum(qmsz_cw_d) as cwsz ---场外基金市值
           ,sum(qmsz_cn_d) as cnsz ---场内基金市值
      into #t_jjsz
      from dba.t_ddw_xy_jjzb_d a
     where rq = @v_bin_date
    group by zjzh;

    update dm.t_ast_odi a
       set OFFUND_MVAL = coalesce(cnsz, 0), --场内基金市值
           OPFUND_MVAL = coalesce(cwsz, 0)  --场外基金市值
    from dm.t_ast_odi a
    left join #t_jjsz b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;
------------------------
  -- 低风险资产
------------------------
-- 低风险资产总计 = 货基市值 + 债基市值 + 资金余额 + 报价回购市值 + 债券逆回购市值 
--                    + 固定收益类资管产品市值 + 国债市值 + 企业债市值 + 可转债市值

    select a.zjzh,
           coalesce(a.hjsz, 0) + coalesce(a.zjsz, 0) + coalesce(a.zjye, 0) +
           coalesce(b.bjhgsz, 0) + coalesce(c.zqnhgsz, 0) +
           coalesce(a.gdsylzgcpsz, 0) + coalesce(d.gzsz, 0) +
           coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0)                       as dfxzczj,
           coalesce(d.gzsz, 0) + coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0) as zqsz,
           coalesce(b.bjhgsz,0)                                              as bjhgsz,
           coalesce(c.zqnhgsz,0)                                             as zqnhgsz
      into #t_dfxzc
      from dba.tmp_ddw_khqjt_d_d a
      left join (select zjzh, cyje_br as bjhgsz       -- 报价回购市值
                   from dba.t_ddw_bjhg_d
                  where rq = @v_bin_date) b
        on a.zjzh = b.zjzh
      left join (select zjzh, SUM(jrccsz) as zqnhgsz -- 债券逆回购市值
                   from dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx = '27'
                    and zqdm not like '205%'         -- 剔除报价回购
                  group by zjzh) c
        on a.zjzh = c.zjzh
      left join (select zjzh,
                        SUM(case when zqlx = '12' then jrccsz else 0 end) as gzsz,  -- 国债市值  
                        SUM(case when zqlx = '13' then jrccsz else 0 end) as qyzsz, -- 企业债市值
                        SUM(case when zqlx = '14' then jrccsz else 0 end) as kzzsz  -- 可转债市值
                   from  dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx in ('12', '13', '14')
                  group by zjzh) d
        on a.zjzh  = d.zjzh
     where a.rq = @v_bin_date;

  commit;

    update dm.t_ast_odi 
       set LOW_RISK_TOT_AST= coalesce(dfxzczj, 0),                      ---  低风险资产
           OVERSEA_TOT_AST = 0,                                         ---  海外总资产
           FUTR_TOT_AST    = 0,                                         ---  期货总资产
           BOND_MVAL       =coalesce(b.zqsz,0),                         ---  债券市值
           REPO_MVAL       =coalesce(b.bjhgsz,0)+coalesce(b.zqnhgsz,0), ---  回购市值
           TREA_REPO_MVAL  =coalesce(b.zqnhgsz,0),                      ---  国债回购市值
           REPQ_MVAL       =coalesce(b.bjhgsz,0)                        ---  报价回购市值
    from dm.t_ast_odi   a  
    left join  #t_dfxzc b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
    ------------------------
    -- 经纪业务部需求：股票质押负债
    ------------------------

    update dm.t_ast_odi 
       set STKPLG_LIAB= coalesce(fz, 0)                       ---  股票质押负债 
    from dm.t_ast_odi            a  
    left join dba.t_ddw_gpzyhg_d b on a.main_cptl_acct = b.zjzh and b.rq=a.occur_dt
     where 
         a.occur_dt = @v_bin_date;

    commit;

 
    ------------------------
    -- 经纪业务部需求：增加约定购回质押资产市值
    ------------------------

    select a.client_id,
           sum(a.entrust_amount * b.trad_price )        as 质押资产_期末_原始 ----  约定购回质押市值
    into #t_arpsz
      from dba.t_edw_arpcontract               a
      left join dba.t_edw_t06_stock_maket_info b
        on a.stock_code = b.stock_cd and '0' || a.exchange_type = b.market_type_cd and a.load_dt = b.trad_dt and b.stock_type_cd in ('10', 'A1')
     where a.load_dt = @v_bin_date
       and a.contract_status in ('2', '3', '7') -- 2-已签约, 3-已进行初始交易, 7 -已购回
     group by a.client_id;
   
    commit;
 
    update dm.t_ast_odi 
       set APPTBUYB_PLG_MVAL = coalesce(质押资产_期末_原始, 0) --约定购回质押市值
    from dm.t_ast_odi a
    left join #t_arpsz b on a.cust_id = b.client_id
     where 
         a.occur_dt = @v_bin_date;

    commit;
    
    ------------------------
    -- 经纪业务部需求：增加其他资产市值
    ------------------------

  update dm.t_ast_odi 
       set   OTH_AST_MVAL =  
                        coalesce(b.zzc,0)                                --- 仓库全景图总资产
                        + coalesce(b.rzrqzfz,0)                          --- 融资融券总负债
                        + coalesce(b.ydghfz,0)                           --- 约定购回负债
                        - coalesce(STKF_MVAL,0)                          --- 股基市值
                        - coalesce(CPTL_BAL ,0)                          --- 保证金/资金余额
                        - coalesce(BOND_MVAL,0)                          --- 债券市值
                        - (coalesce(c.bzqqmsz,0)+ coalesce(c.hgqmsz,0))  --- 回购市值--私财 标准券市值
                        - coalesce(PROD_TOT_MVAL,0)                      --- 产品总市值
                        - coalesce(APPTBUYB_PLG_MVAL,0)                  --- 约定购回质押市值
                        - coalesce(b.rzrqzzc,0)                          --- 两融账户总资产
                        - coalesce(NO_ARVD_CPTL,0) 	                     --- 未到账资金
    from dm.t_ast_odi   a
    left join dba.tmp_ddw_khqjt_d_d b on a.main_cptl_acct = b.zjzh and b.rq=a.occur_dt
    left join #t_sz                                c on a.main_cptl_acct = c.zjzh
     where 
         a.occur_dt = @v_bin_date;
    commit;
 

 ------------------------
    -- 经纪业务部需求：期末资产，即为经纪业务总部要求的总资产=股基市值+资金余额+债券市值+回购市值+产品总市值+其他资产+未到账资金+股票质押负债+融资融券总资产+约定购回质押市值+限售股市值+个股期权市值。
 ------------------------

    update dm.t_ast_odi
       set FINAL_AST = coalesce(STKF_MVAL, 0)           --股基市值
                       + coalesce(CPTL_BAL, 0)          --资金余额
                       + coalesce(BOND_MVAL, 0)         --债券市值
                       + coalesce(REPO_MVAL, 0)         --回购市值
                       + coalesce(PROD_TOT_MVAL, 0)     --产品总市值
                       + coalesce(OTH_AST_MVAL, 0)      --其他资产 
                       + coalesce(NO_ARVD_CPTL, 0)      --未到账资金 
                       + coalesce(STKPLG_LIAB, 0)       --股票质押负债 
                       + coalesce(b.rzrqzzc, 0)         --融资融券总资产    
                       + coalesce(APPTBUYB_PLG_MVAL, 0) --约定购回质押市值
                       + coalesce(NOTS_MVAL, 0)         --限售股市值 
                       + coalesce(PSTK_OPTN_MVAL, 0)    --个股期权市值 
    from dm.t_ast_odi a 
    left join dba.tmp_ddw_khqjt_d_d b on a.main_cptl_acct = b.zjzh and a.occur_dt = b.rq
     where a.occur_dt = @v_bin_date;

    commit;


 ------------------------
    -- 经纪业务部需求：净资产=期末资产（总资产）-融资融券总负债-股票质押负债-约定购回负债。这里的两融总负债要算所有类型的融资融券负债
 ------------------------

  update dm.t_ast_odi
     set NET_AST = FINAL_AST                    --期末资产/经纪业务口径总资产
                   - (COALESCE(FIN_CLOSE_BALANCE, 0)       +COALESCE(SLO_CLOSE_BALANCE, 0)       + COALESCE(FARE_CLOSE_DEBIT, 0)         + COALESCE(OTHER_CLOSE_DEBIT, 0) +
                      COALESCE(FIN_CLOSE_INTEREST, 0)      +COALESCE(SLO_CLOSE_INTEREST, 0)      +COALESCE(FARE_CLOSE_INTEREST, 0)       +COALESCE(OTHER_CLOSE_INTEREST, 0) +
                      COALESCE(FIN_CLOSE_FINE_INTEREST, 0) +COALESCE(SLO_CLOSE_FINE_INTEREST, 0) +COALESCE(OTHER_CLOSE_FINE_INTEREST, 0) +COALESCE(REFCOST_CLOSE_FARE, 0)) --融资融券总负债:融资负债、融券负债、费用负债、其他负债、利息负债、罚息负债
                   - coalesce(STKPLG_LIAB, 0)  --股票质押负债  
                   - coalesce(b.ydghfz, 0)     --约定购回负债
  from dm.t_ast_odi a 
  left join dba.tmp_ddw_khqjt_d_d                b on a.main_cptl_acct = b.zjzh         and a.occur_dt = b.rq
  left join DBA.T_EDW_UF2_RZRQ_ASSETDEBIT        c on a.cust_id = c.client_id           and a.occur_dt = c.load_dt
   where a.occur_dt = @v_bin_date;
  
  commit;


  set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 

  end
GO
GRANT EXECUTE ON dm.tmp_ast_odi TO query_dev
GO
