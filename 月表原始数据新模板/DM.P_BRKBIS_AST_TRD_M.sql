create PROCEDURE DM.P_BRKBIS_AST_TRD_M(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  程序功能: 经纪业务资产交易月报
  编写者: LIZM
  创建日期: 2018-05-21
  简介： 经纪业务资产交易月报表
  *********************************************************************/
    DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
  	DECLARE @V_YEAR_MTH VARCHAR(6);		-- 年月
    SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	SET @V_YEAR_MTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4)+ SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);


	--PART0 删除当月数据
  DELETE FROM DM.T_BRKBIS_AST_TRD_M WHERE YEAR_MTH=@V_YEAR_MTH;

  INSERT INTO DM.T_BRKBIS_AST_TRD_M
	(
	 YEAR_MTH
     ,ORG_NO  
     ,BRH     
     ,SEPT_CORP
     ,SEPT_CORP_TYPE
     ,IF_YEAR_NA    
     ,IF_MTH_NA
     ,ACC_CHAR
     ,IF_SPCA_ACC   
     ,AST_SGMTS
     ,CUST_NUM
     ,EFF_HOUS
     ,TOTAST_FINAL  
     ,NET_AST_FINAL 
     ,STKF_MVAL_FINAL
     ,NOTS_MVAL_FINAL
     ,SPGSMV_FINAL_SCDY_DEDUCT
     ,MARG_FINAL    
     ,BOND_MVAL_FINAL
     ,REPO_MVAL_FINAL
     ,PSTK_OPTN_FINAL
     ,PROD_MVAL_FINAL
     ,CREDIT_TOTAST_FINAL 
     ,CREDIT_TOT_LIAB_FINAL
     ,CREDIT_BAL_FINAL    
     ,APPTBUYB_TOTAST_FINAL
     ,APPTBUYB_BAL_FINAL  
     ,STKPLG_TOTAST_FINAL 
     ,STKPLG_BAL_FINAL    
     ,OTH_AST_FINAL 
     ,REAL_NO_ARVD_CPTL_FINAL
     ,ODI_A_SHR_MVAL_FINAL
     ,CRED_A_SHR_MVAL_FINAL
     ,TOTAST_MDA    
     ,NET_AST_MDA   
     ,STKF_MVAL_MDA 
     ,NOTS_MVAL_MDA 
     ,SPGSMV_MDA_SCDY_DEDUCT
     ,MARG_MDA
     ,BOND_MVAL_MDA 
     ,REPO_MVAL_MDA 
     ,PSTK_OPTN_MDA 
     ,PROD_MVAL_MDA 
     ,CREDIT_TOTAST_MDA   
     ,CREDIT_TOT_LIAB_MDA 
     ,CREDIT_BAL_MDA
     ,APPTBUYB_TOTAST_MDA 
     ,APPTBUYB_BAL_MDA    
     ,STKPLG_TOTAST_MDA   
     ,STKPLG_BAL_MDA
     ,OTH_AST_MDA   
     ,REAL_NO_ARVD_CPTL_MDA
     ,ODI_A_SHR_MVAL_MDA  
     ,CRED_A_SHR_MVAL_MDA 
     ,TOTAST_YDA    
     ,NET_AST_YDA   
     ,STKF_MVAL_YDA 
     ,NOTS_MVAL_YDA 
     ,SPGSMV_YDA_SCDY_DEDUCT
     ,MARG_YDA
     ,BOND_MVAL_YDA 
     ,REPO_MVAL_YDA 
     ,PSTK_OPTN_YDA 
     ,PROD_MVAL_YDA 
     ,CREDIT_TOTAST_YDA   
     ,CREDIT_TOT_LIAB_YDA 
     ,CREDIT_BAL_YDA
     ,APPTBUYB_TOTAST_YDA 
     ,APPTBUYB_BAL_YDA    
     ,STKPLG_TOTAST_YDA   
     ,STKPLG_BAL_YDA
     ,OTH_AST_YDA   
     ,REAL_NO_ARVD_CPTL_YDA
     ,ODI_A_SHR_MVAL_YDA  
     ,CRED_A_SHR_MVAL_YDA 
     ,STKF_TRD_QTY_MTD    
     ,HGT_TRD_QTY_MTD
     ,SGT_TRD_QTY_MTD
     ,SB_TRD_QTY_MTD
     ,PSTK_OPTN_TRD_QTY_MTD
     ,BOND_TRD_QTY_MTD    
     ,S_REPUR_TRD_QTY_MTD 
     ,R_REPUR_TRD_QTY_MTD 
     ,CREDIT_ODI_TRD_QTY_MTD
     ,CREDIT_CRED_TRD_QTY_MTD
     ,ITC_CRRC_FUND_TRD_QTY_MTD
     ,BGDL_QTY_MTD  
     ,REPQ_TRD_QTY_MTD    
     ,STKF_TRD_QTY_YTD    
     ,HGT_TRD_QTY_YTD
     ,SGT_TRD_QTY_YTD
     ,SB_TRD_QTY_YTD
     ,PSTK_OPTN_TRD_QTY_YTD
     ,BOND_TRD_QTY_YTD    
     ,S_REPUR_TRD_QTY_YTD 
     ,R_REPUR_TRD_QTY_YTD 
     ,CREDIT_ODI_TRD_QTY_YTD
     ,CREDIT_CRED_TRD_QTY_YTD
     ,ITC_CRRC_FUND_TRD_QTY_YTD
     ,BGDL_QTY_YTD  
     ,REPQ_TRD_QTY_YTD    
     ,STKF_NET_CMS_MTD    
     ,HGT_NET_CMS_MTD
     ,SGT_NET_CMS_MTD
     ,PSTK_OPTN_NET_CMS_MTD
     ,S_REPUR_NET_CMS_MTD 
     ,R_REPUR_NET_CMS_MTD 
     ,CREDIT_ODI_NET_CMS_MTD
     ,CREDIT_CRED_NET_CMS_MTD
     ,ITC_CRRC_FUND_NET_CMS_MTD
     ,BGDL_NET_CMS_MTD    
     ,REPQ_NET_CMS_MTD    
     ,ODI_SPR_INCM_MTD    
     ,CRED_SPR_INCM_MTD   
     ,STKF_NET_CMS_YTD    
     ,HGT_NET_CMS_YTD
     ,SGT_NET_CMS_YTD
     ,PSTK_OPTN_NET_CMS_YTD
     ,S_REPUR_NET_CMS_YTD 
     ,R_REPUR_NET_CMS_YTD 
     ,CREDIT_ODI_NET_CMS_YTD
     ,CREDIT_CRED_NET_CMS_YTD
     ,ITC_CRRC_FUND_NET_CMS_YTD
     ,BGDL_NET_CMS_YTD    
     ,REPQ_NET_CMS_YTD    
     ,ODI_SPR_INCM_YTD    
     ,CRED_SPR_INCM_YTD     
	)
	select
	t1.YEAR||t1.MTH as 年月
	,t_jg.WH_ORG_ID as 机构编号	
    ,t_jg.HR_ORG_NAME as 营业部
    ,t_jg.SEPT_CORP_NAME as 分公司
    ,t_jg.ORG_TYPE as 分公司类型 
    ,t_khsx.是否年新增
    ,t_khsx.是否月新增
    ,t_khsx.账户性质
    ,t_khsx.是否特殊账户
    ,t_khsx.资产段
    ,sum(case when t_khsx.客户状态='0' then t2.JXBL1 else 0 end) as 客户数
    ,sum(case when t_khsx.客户状态='0' and t_khsx.是否有效=1 then t2.JXBL1 else 0 end) as 有效客户数
    ,sum(COALESCE(t1.TOT_AST_FINAL,0)) as 普通资产_总资产_期末
    ,sum(COALESCE(t1.NET_AST_FINAL,0)) as 普通资产_净资产_期末
    ,sum(COALESCE(t1.STKF_MVAL_FINAL,0)) as 普通资产_股基市值_期末
    ,sum(COALESCE(t1.NOTS_MVAL_FINAL,0)) as 普通资产_限售股市值_期末
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_FINAL_SCDY_DEDUCT,0)) as 普通资产_股票质押担保证券市值_期末_二级扣减
    ,sum(COALESCE(t1.CPTL_BAL_FINAL,0)) as 保证金_期末
    ,sum(COALESCE(t1.BOND_MVAL_FINAL,0)) as 普通资产_债券市值_期末
    ,sum(COALESCE(t1.REPO_MVAL_FINAL,0)) as 普通资产_回购市值_期末
    ,sum(COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0)) as 普通资产_个股期权_期末 
    ,sum(COALESCE(t1.PROD_TOT_MVAL_FINAL,0)) as 普通资产_产品市值_期末
    ,sum(COALESCE(t1.CREDIT_TOT_AST_FINAL,0)) as 普通资产_融资融券总资产_期末
    ,sum(COALESCE(t1.CREDIT_TOT_LIAB_FINAL,0)) as 普通资产_融资融券总负债_期末
    ,sum(COALESCE(t1.CREDIT_BAL_FINAL,0)) as 普通资产_融资融券余额_期末
    ,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0)) as 约定购回总资产_期末
    ,sum(COALESCE(t1.APPTBUYB_BAL_FINAL,0)) as 普通资产_约定购回余额_期末
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_FINAL,0)) as 股票质押总资产_期末
    ,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_FINAL,0)) as 股票质押余额_期末
    ,sum(COALESCE(t1.OTH_AST_MVAL_FINAL,0)) as 普通资产_其他资产_期末
    ,sum(COALESCE(t1.NO_ARVD_CPTL_FINAL,0)) as 普通资产_真实未到账资金_期末
    ,sum(COALESCE(t1.A_SHR_MVAL_FINAL,0)) as 普通资产_普通A股市值_期末
    ,sum(COALESCE(t_rzrq.A_SHR_MVAL_FINAL,0)) as 信用A股市值_期末
    ,sum(COALESCE(t1.TOT_AST_MDA,0)) as 普通资产_总资产_月日均
    ,sum(COALESCE(t1.NET_AST_MDA,0)) as 普通资产_净资产_月日均
    ,sum(COALESCE(t1.STKF_MVAL_MDA,0)) as 普通资产_股基市值_月日均
    ,sum(COALESCE(t1.NOTS_MVAL_MDA,0)) as 普通资产_限售股市值_月日均
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_MDA_SCDY_DEDUCT,0)) as 普通资产_股票质押担保证券市值_月日均_二级扣减
    ,sum(COALESCE(t1.CPTL_BAL_MDA,0)) as 保证金_月日均
    ,sum(COALESCE(t1.BOND_MVAL_MDA,0)) as 普通资产_债券市值_月日均
    ,sum(COALESCE(t1.REPO_MVAL_MDA,0)) as 普通资产_回购市值_月日均
    ,sum(COALESCE(t1.PSTK_OPTN_MVAL_MDA,0)) as 普通资产_个股期权_月日均
    ,sum(COALESCE(t1.PROD_TOT_MVAL_MDA,0)) as 普通资产_产品市值_月日均
    ,sum(COALESCE(t1.CREDIT_TOT_AST_MDA,0)) as 普通资产_融资融券总资产_月日均
    ,sum(COALESCE(t1.CREDIT_TOT_LIAB_MDA,0)) as 普通资产_融资融券总负债_月日均
    ,sum(COALESCE(t1.CREDIT_BAL_MDA,0)) as 普通资产_融资融券余额_月日均
    ,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0)) AS  约定购回总资产_月日均
    ,sum(COALESCE(t1.APPTBUYB_BAL_MDA,0)) as 普通资产_约定购回余额_月日均
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_MDA,0)) as 股票质押总资产_月日均
    ,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_MDA,0)) as 股票质押余额_月日均
    ,sum(COALESCE(t1.OTH_AST_MVAL_MDA,0)) as 普通资产_其他资产_月日均
    ,sum(COALESCE(t1.NO_ARVD_CPTL_MDA,0)) as 普通资产_真实未到账资金_月日均
    ,sum(COALESCE(t1.A_SHR_MVAL_MDA,0)) as 普通资产_普通A股市值_月日均
    ,sum(COALESCE(t_rzrq.A_SHR_MVAL_MDA,0)) as 信用A股市值_月日均
    ,sum(COALESCE(t1.TOT_AST_YDA,0)) as 普通资产_总资产_年日均
    ,sum(COALESCE(t1.NET_AST_YDA,0)) as 普通资产_净资产_年日均
    ,sum(COALESCE(t1.STKF_MVAL_YDA,0)) as 普通资产_股基市值_年日均
    ,sum(COALESCE(t1.NOTS_MVAL_YDA,0)) as 普通资产_限售股市值_年日均
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_YDA_SCDY_DEDUCT,0)) as 普通资产_股票质押担保证券市值_年日均_二级扣减
    ,sum(COALESCE(t1.CPTL_BAL_YDA,0)) as 保证金_年日均
    ,sum(COALESCE(t1.BOND_MVAL_YDA,0)) as 普通资产_债券市值_年日均
    ,sum(COALESCE(t1.REPO_MVAL_YDA,0)) as 普通资产_回购市值_年日均
    ,sum(COALESCE(t1.PSTK_OPTN_MVAL_YDA,0)) as 普通资产_个股期权_年日均
    ,sum(COALESCE(t1.PROD_TOT_MVAL_YDA,0)) as 普通资产_产品市值_年日均
    ,sum(COALESCE(t1.CREDIT_TOT_AST_YDA,0)) as 普通资产_融资融券总资产_年日均
    ,sum(COALESCE(t1.CREDIT_TOT_LIAB_YDA,0)) as 普通资产_融资融券总负债_年日均
    ,sum(COALESCE(t1.CREDIT_BAL_YDA,0)) as 普通资产_融资融券余额_年日均
    ,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0)) as 约定购回总资产_年日均
    ,sum(COALESCE(t1.APPTBUYB_BAL_YDA,0)) as 普通资产_约定购回余额_年日均
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_YDA,0)) as 股票质押总资产_年日均
    ,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_YDA,0)) as 股票质押余额_年日均
    ,sum(COALESCE(t1.OTH_AST_MVAL_YDA,0)) as 普通资产_其他资产_年日均
    ,sum(COALESCE(t1.NO_ARVD_CPTL_YDA,0)) as 普通资产_真实未到账资金_年日均
    ,sum(COALESCE(t1.A_SHR_MVAL_YDA,0)) as 普通资产_普通A股市值_年日均
    ,sum(COALESCE(t_rzrq.A_SHR_MVAL_YDA,0)) as 信用A股市值_年日均
    ,sum(COALESCE(t_ptjy.STKF_TRD_QTY_MTD,0)) as 普通交易_股基交易量_月累计
    ,sum(COALESCE(t_ptjy.HGT_TRD_QTY_MTD,0)) as 普通交易_沪港通交易量_月累计
    ,sum(COALESCE(t_ptjy.SGT_TRD_QTY_MTD,0)) as 普通交易_深港通交易量_月累计
    ,sum(COALESCE(t_ptjy.SB_TRD_QTY_MTD,0)) as 三板交易量_月累计
    ,sum(COALESCE(t_ptjy.PSTK_OPTN_TRD_QTY_MTD,0)) as 普通交易_个股期权交易量_月累计
    ,sum(COALESCE(t_ptjy.BOND_TRD_QTY_MTD,0)) as 债券交易量_月累计
    ,sum(COALESCE(t_ptjy.S_REPUR_TRD_QTY_MTD,0)) as 普通交易_正回购交易量_月累计
    ,sum(COALESCE(t_ptjy.R_REPUR_TRD_QTY_MTD,0)) as 普通交易_逆回购交易量_月累计
    ,sum(COALESCE(t_ptjy.CREDIT_ODI_TRD_QTY_MTD,0)) as 信用账户普通交易量_月累计
    ,sum(COALESCE(t_ptjy.CREDIT_CRED_TRD_QTY_MTD,0)) as 信用账户信用交易量_月累计
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_TRD_QTY_MTD,0)) as 场内货币基金交易量_月累计
    ,sum(COALESCE(t_ptjy.BGDL_QTY_MTD,0)) as 普通交易_大宗交易量_月累计
    ,sum(COALESCE(t_ptjy.REPQ_TRD_QTY_MTD,0)) as 普通交易_报价回购交易量_月累计
    ,sum(COALESCE(t_ptjy.STKF_TRD_QTY_YTD,0)) as 普通交易_股基交易量_年累计
    ,sum(COALESCE(t_ptjy.HGT_TRD_QTY_YTD,0)) as 普通交易_沪港通交易量_年累计
    ,sum(COALESCE(t_ptjy.SGT_TRD_QTY_YTD,0)) as 普通交易_深港通交易量_年累计
    ,sum(COALESCE(t_ptjy.SB_TRD_QTY_YTD,0)) as 三板交易量_年累计
    ,sum(COALESCE(t_ptjy.PSTK_OPTN_TRD_QTY_YTD,0)) as 普通交易_个股期权交易量_年累计
    ,sum(COALESCE(t_ptjy.BOND_TRD_QTY_YTD,0)) as 债券交易量_年累计
    ,sum(COALESCE(t_ptjy.S_REPUR_TRD_QTY_YTD,0)) as 普通交易_正回购交易量_年累计
    ,sum(COALESCE(t_ptjy.R_REPUR_TRD_QTY_YTD,0)) as 普通交易_逆回购交易量_年累计
    ,sum(COALESCE(t_ptjy.CREDIT_ODI_TRD_QTY_YTD,0)) as 信用账户普通交易量_年累计
    ,sum(COALESCE(t_ptjy.CREDIT_CRED_TRD_QTY_YTD,0)) as 信用账户信用交易量_年累计
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_TRD_QTY_YTD,0)) as 场内货币基金交易量_年累计
    ,sum(COALESCE(t_ptjy.BGDL_QTY_YTD,0)) as 普通交易_大宗交易量_年累计
    ,sum(COALESCE(t_ptjy.REPQ_TRD_QTY_YTD,0)) as 普通交易_报价回购交易量_年累计
    ,sum(COALESCE(t_ptsr.STKF_NET_CMS_MTD,0)) as 普通收入_股基净佣金_月累计
    ,sum(COALESCE(t_ptsr.HGT_NET_CMS_MTD,0)) as 普通收入_沪港通净佣金_月累计
    ,sum(COALESCE(t_ptsr.SGT_NET_CMS_MTD,0)) as 普通收入_深港通净佣金_月累计
    ,sum(COALESCE(t_ptsr.PSTK_OPTN_NET_CMS_MTD,0)) as 普通收入_个股期权净佣金_月累计
    ,sum(COALESCE(t_ptjy.S_REPUR_NET_CMS_MTD,0)) as 正回购净佣金_月累计
    ,sum(COALESCE(t_ptjy.R_REPUR_NET_CMS_MTD,0)) as 逆回购净佣金_月累计
    ,sum(COALESCE(t_xysr.CREDIT_ODI_NET_CMS_MTD,0)) as 信用账户普通净佣金_月累计
    ,sum(COALESCE(t_xysr.CREDIT_CRED_NET_CMS_MTD,0)) as 信用账户信用净佣金_月累计
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_NET_CMS_MTD,0)) as 场内货币基金净佣金_月累计
    ,sum(COALESCE(t_ptsr.BGDL_NET_CMS_MTD,0)) as 普通收入_大宗交易净佣金_月累计
    ,sum(COALESCE(t_ptsr.REPQ_NET_CMS_MTD,0)) as 普通收入_报价回购净佣金_月累计
    ,sum(COALESCE(t_ptsr.MARG_SPR_INCM_MTD,0)) as 普通利差收入_月累计
    ,sum(COALESCE(t_xysr.CREDIT_MARG_SPR_INCM_MTD,0)) AS  信用利差收入_月累计
    ,sum(COALESCE(t_ptsr.STKF_NET_CMS_YTD,0)) as 普通收入_股基净佣金_年累计
    ,sum(COALESCE(t_ptsr.HGT_NET_CMS_YTD,0)) as 普通收入_沪港通净佣金_年累计
    ,sum(COALESCE(t_ptsr.SGT_NET_CMS_YTD,0)) as 普通收入_深港通净佣金_年累计
    ,sum(COALESCE(t_ptsr.PSTK_OPTN_NET_CMS_YTD,0)) as 普通收入_个股期权净佣金_年累计
    ,sum(COALESCE(t_ptjy.S_REPUR_NET_CMS_YTD,0)) as 正回购净佣金_年累计
    ,sum(COALESCE(t_ptjy.R_REPUR_NET_CMS_YTD,0)) as 逆回购净佣金_年累计
    ,sum(COALESCE(t_xysr.CREDIT_ODI_NET_CMS_YTD,0)) as 信用账户普通净佣金_年累计
    ,sum(COALESCE(t_xysr.CREDIT_CRED_NET_CMS_YTD,0)) as 信用账户信用净佣金_年累计
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_NET_CMS_YTD,0)) as 场内货币基金净佣金_年累计
    ,sum(COALESCE(t_ptsr.BGDL_NET_CMS_YTD,0)) as 普通收入_大宗交易净佣金_年累计
    ,sum(COALESCE(t_ptsr.REPQ_NET_CMS_YTD,0)) as 普通收入_报价回购净佣金_年累计
    ,sum(COALESCE(t_ptsr.MARG_SPR_INCM_YTD,0)) as 普通利差收入_年累计
    ,sum(COALESCE(t_xysr.CREDIT_MARG_SPR_INCM_YTD,0)) as 信用利差收入_年累计
from DM.T_AST_EMPCUS_ODI_M_D t1					--员工客户普通资产
left join DM.T_PUB_ORG t_jg					--机构表
	on t1.YEAR=t_jg.YEAR and t1.MTH=t_jg.MTH and t1.WH_ORG_ID_EMP=t_jg.WH_ORG_ID
--20180427修改增加责权表
left join DBA.t_ddw_serv_relation t2
	on t1.year=t2.NIAN 
		and t1.mth=t2.YUE 
		and t2.KHBH_HS=t1.cust_id 
		and t1.afa_sec_empid=t2.AFATWO_YGH
left join 
(											--客户属性和维度处理
	select 
		t1.YEAR
		,t1.MTH	
		,t1.CUST_ID
		,t1.CUST_STAT_NAME as 客户状态
		,case when t1.TE_OACT_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as 是否月新增
		,case when t1.TE_OACT_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as 是否年新增
		,coalesce(t1.IF_VLD,0) as 是否有效
		,coalesce(t4.IF_SPCA_ACCT,0) as 是否特殊账户
		,coalesce(t1.IF_PROD_NEW_CUST,0)   as 是否产品新客户
		,t1.CUST_TYPE_NAME as 账户性质
		,case 
            when t5.TOT_AST_MDA<100                                     then '00-100以下'
			when t5.TOT_AST_MDA >= 100      and t5.TOT_AST_MDA<1000     then '01-100_1000'
			when t5.TOT_AST_MDA >= 1000     and t5.TOT_AST_MDA<2000     then '02-1000_2000'
			when t5.TOT_AST_MDA >= 2000     and t5.TOT_AST_MDA<5000     then '03-2000_5000'
			when t5.TOT_AST_MDA >= 5000     and t5.TOT_AST_MDA<10000    then '04-5000_1w'
			when t5.TOT_AST_MDA >= 10000    and t5.TOT_AST_MDA<50000    then '05-1w_5w'
			when t5.TOT_AST_MDA >= 50000    and t5.TOT_AST_MDA<100000   then '06-5w_10w'
            when t5.TOT_AST_MDA >= 100000   and t5.TOT_AST_MDA<200000   then '1-10w_20w'
    		when t5.TOT_AST_MDA >= 200000   and t5.TOT_AST_MDA<500000   then '2-20w_50w'
    		when t5.TOT_AST_MDA >= 500000   and t5.TOT_AST_MDA<1000000  then '3-50w_100w'
    		when t5.TOT_AST_MDA >= 1000000  and t5.TOT_AST_MDA<2000000  then '4-100w_200w'
    		when t5.TOT_AST_MDA >= 2000000  and t5.TOT_AST_MDA<3000000  then '5-200w_300w'
    		when t5.TOT_AST_MDA >= 3000000  and t5.TOT_AST_MDA<5000000  then '6-300w_500w'
    		when t5.TOT_AST_MDA >= 5000000  and t5.TOT_AST_MDA<10000000 then '7-500w_1000w'
    		when t5.TOT_AST_MDA >= 10000000 and t5.TOT_AST_MDA<30000000 then '8-1000w_3000w'
			when t5.TOT_AST_MDA >= 30000000                             then '9-大于3000w'
         end as 资产段
        
	 from DM.T_PUB_CUST t1	 
	 left join DM.T_PUB_DATE_M t2 on t1.YEAR=t2.YEAR and t1.MTH=t2.MTH
	 left join DM.T_PUB_CUST_LIMIT_M_D t3 on t1.YEAR=t3.YEAR and t1.MTH=t3.MTH and t1.CUST_ID=t3.CUST_ID
	 left join DM.T_ACC_CPTL_ACC t4 on t1.YEAR=t4.YEAR and t1.MTH=t4.MTH and t1.MAIN_CPTL_ACCT=t4.CPTL_ACCT
	 left join DM.T_AST_ODI_M_D t5 on t1.YEAR=t5.YEAR and t1.MTH=t5.MTH and t1.CUST_ID=t5.CUST_ID
    where  t1.YEAR=@V_YEAR and t1.MTH=@V_MONTH  and 资产段 is not null
) t_khsx on t1.YEAR=t_khsx.YEAR and t1.MTH=t_khsx.MTH and t1.CUST_ID=t_khsx.CUST_ID
left join DM.T_AST_EMPCUS_ODI_M_D t_ptzc			--员工客户普通资产
	on t1.YEAR=t_ptzc.YEAR and t1.MTH=t_ptzc.MTH and t1.CUST_ID=t_ptzc.CUST_ID and t1.AFA_SEC_EMPID=t_ptzc.AFA_SEC_EMPID
left join DM.T_AST_EMPCUS_CREDIT_M_D t_rzrq		--员工客户融资融券
	on t1.YEAR=t_rzrq.YEAR and t1.MTH=t_rzrq.MTH and t1.CUST_ID=t_rzrq.CUST_ID and t1.AFA_SEC_EMPID=t_rzrq.AFA_SEC_EMPID
left join DM.T_AST_EMPCUS_CPTL_CHG_M_D t_zcbd	--员工客户资产变动
	on t1.YEAR=t_zcbd.YEAR and t1.MTH=t_zcbd.MTH and t1.CUST_ID=t_zcbd.CUST_ID and t1.AFA_SEC_EMPID=t_zcbd.AFA_SEC_EMPID
left join DM.T_EVT_EMPCUS_ODI_TRD_M_D t_ptjy		--员工客户普通交易
	on t1.YEAR=t_ptjy.YEAR and t1.MTH=t_ptjy.MTH and t1.CUST_ID=t_ptjy.CUST_ID and t1.AFA_SEC_EMPID=t_ptjy.AFA_SEC_EMPID
left join DM.T_EVT_EMPCUS_ODI_INCM_M_D t_ptsr	--员工客户普通收入
	on t1.YEAR=t_ptsr.YEAR and t1.MTH=t_ptsr.MTH and t1.CUST_ID=t_ptsr.CUST_ID and t1.AFA_SEC_EMPID=t_ptsr.AFA_SEC_EMPID
left join DM.T_EVT_EMPCUS_CRED_INCM_M_D t_xysr	--员工客户信用收入
	on t1.YEAR=t_xysr.YEAR and t1.MTH=t_xysr.MTH and t1.CUST_ID=t_xysr.CUST_ID and t1.AFA_SEC_EMPID=t_xysr.AFA_SEC_EMPID
left join DM.T_AST_EMPCUS_APPTBUYB_M_D t_ydgh	--约定购回表
	on t1.YEAR=t_ydgh.YEAR and t1.MTH=t_ydgh.MTH and t1.CUST_ID=t_ydgh.CUST_ID and t1.AFA_SEC_EMPID=t_ydgh.AFA_SEC_EMPID
left join
(
	select
		t1.YEAR
		,t1.MTH
		,t1.CUST_ID
		,t1.AFA_SEC_EMPID
		,sum(COALESCE(t1.GUAR_SECU_MVAL_FINAL,0)) as GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.STKPLG_FIN_BAL_FINAL,0)) as STKPLG_FIN_BAL_FINAL
		,sum(COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0)) as SH_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0)) as SZ_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0)) as SH_NOTS_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0)) as SZ_NOTS_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0)) as PROP_FINAC_OUT_SIDE_BAL_FINAL
		,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0)) as ASSM_FINAC_OUT_SIDE_BAL_FINAL
		,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0)) as SM_LOAN_FINAC_OUT_BAL_FINAL
		,sum(COALESCE(t1.GUAR_SECU_MVAL_MDA,0)) as GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.STKPLG_FIN_BAL_MDA,0)) as STKPLG_FIN_BAL_MDA
		,sum(COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0)) as SH_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0)) as SZ_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0)) as SH_NOTS_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0)) as SZ_NOTS_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0)) as PROP_FINAC_OUT_SIDE_BAL_MDA
		,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0)) as ASSM_FINAC_OUT_SIDE_BAL_MDA
		,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0)) as SM_LOAN_FINAC_OUT_BAL_MDA
		,sum(COALESCE(t1.GUAR_SECU_MVAL_YDA,0)) as GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.STKPLG_FIN_BAL_YDA,0)) as STKPLG_FIN_BAL_YDA
		,sum(COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0)) as SH_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0)) as SZ_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0)) as SH_NOTS_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0)) as SZ_NOTS_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0)) as PROP_FINAC_OUT_SIDE_BAL_YDA
		,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0)) as ASSM_FINAC_OUT_SIDE_BAL_YDA
		,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0)) as SM_LOAN_FINAC_OUT_BAL_YDA
	from DM.T_AST_EMPCUS_STKPLG_M_D t1
	group by
		t1.YEAR
		,t1.MTH
		,t1.CUST_ID
		,t1.AFA_SEC_EMPID
) t_gpzy 									--股票质押表
	on t1.YEAR=t_gpzy.YEAR and t1.MTH=t_gpzy.MTH and t1.CUST_ID=t_gpzy.CUST_ID and t1.AFA_SEC_EMPID=t_gpzy.AFA_SEC_EMPID
where t1.YEAR=@V_YEAR and t1.MTH=@V_MONTH
 AND t_khsx.是否特殊账户 IS NOT NULL
 AND t_khsx.是否产品新客户 IS NOT NULL
 AND t_khsx.CUST_ID IS NOT NULL
 AND t_jg.WH_ORG_ID IS NOT NULL
group by
	t1.YEAR
	,t1.MTH
	,t_jg.WH_ORG_ID	
	,t_jg.HR_ORG_NAME
	,t_jg.SEPT_CORP_NAME
    ,t_jg.ORG_TYPE
	--维度信息
    ,t_khsx.账户性质
	,t_khsx.是否特殊账户
	,t_khsx.是否月新增
	,t_khsx.是否年新增	
	,t_khsx.资产段
	;
END