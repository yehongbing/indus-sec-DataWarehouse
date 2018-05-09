CREATE OR REPLACE PROCEDURE dm.P_AST_EMPCUS_APPTBUYB_M_D(IN @V_BIN_DATE INT)

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