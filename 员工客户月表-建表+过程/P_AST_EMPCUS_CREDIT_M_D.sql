CREATE OR REPLACE PROCEDURE dm.P_AST_EMPCUS_CREDIT_M_D(IN @V_BIN_DATE INT)

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