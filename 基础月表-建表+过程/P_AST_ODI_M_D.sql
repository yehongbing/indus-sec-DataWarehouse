CREATE OR REPLACE PROCEDURE DM.P_AST_ODI_M_D(IN @V_BIN_DATE INT)


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

--PART0 删除当月数据
  DELETE FROM DM.T_AST_ODI_M_D WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);

insert into DM.T_AST_ODI_M_D
(
 CUST_ID
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
		t1.YEAR as 年
		,t2.MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,t2.NATRE_DAY_MTHBEG as 自然日_月初
		,t2.NATRE_DAY_MTHEND as 自然日_月末
		,t2.TRD_DAY_MTHBEG as 交易日_月初
		,t2.TRD_DAY_MTHEND as 交易日_月末
		,t2.NATRE_DAY_YEARBGN as 自然日_年初
		,t2.TRD_DAY_YEARBGN as 交易日_年初
		,t2.NATRE_DAYS_MTH as 自然天数_月
		,t2.TRD_DAYS_MTH as 交易天数_月
		,t2.NATRE_DAYS_YEAR as 自然天数_年
		,t2.TRD_DAYS_YEAR as 交易天数_年
	from DM.T_PUB_DATE t1
    join DM.T_PUB_DATE_M t2 on t1.YEAR=t2.YEAR and t1.MTH<=t2.MTH	
	where t1.YEAR=substr(@V_BIN_DATE||'',1,4) and t2.MTH=substr(@V_BIN_DATE||'',5,2)
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
