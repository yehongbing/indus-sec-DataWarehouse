CREATE OR REPLACE PROCEDURE dm.P_EVT_EMPCUS_CRED_INCM_M_D(IN @V_BIN_DATE INT)

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