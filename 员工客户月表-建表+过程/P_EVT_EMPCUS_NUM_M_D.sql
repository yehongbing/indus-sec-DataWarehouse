CREATE OR REPLACE PROCEDURE dm.P_EVT_EMPCUS_NUM_M_D(IN @V_BIN_DATE INT)


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