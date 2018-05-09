CREATE OR REPLACE PROCEDURE dm.P_AST_EMPCUS_CPTL_CHG_M_D(IN @V_BIN_DATE INT)

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