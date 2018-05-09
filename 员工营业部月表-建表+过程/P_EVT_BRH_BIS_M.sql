CREATE OR REPLACE PROCEDURE DM.P_EVT_BRH_BIS_M(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 创建员营业部业务数据月表:带权责
  编写者: YHB
  创建日期: 2018-03-26
  简介：员工客户数月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180329                  dcy                新增资产段      
             20180409                  dcy                新增普通交易28个字段			 
  *********************************************************************/

  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 删除当月数据
  DELETE FROM DM.T_EVT_BRH_BIS_M WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

insert into DM.T_EVT_BRH_BIS_M
	(
		 YEAR
		,MTH
		,YEAR_MTH
		,ORG_NO
		,CUST_STAT
		,IF_SPCA_ACC
		,IF_PROD_NEW_CUST
		,IF_MTH_NA
		,IF_YEAR_NA
		,IF_CREDIT_CUST
		,IF_CREDIT_MTH_NA
		,IF_CREDIT_YEAR_NA
		,IF_CREDIT_EFF_CUST
		,IF_CREDIT_MTH_NA_EFF_ACT
		,IF_CREDIT_YEAR_NA_EFF_ACT
		,AST_SGMTS
		,CUST_TYPE
		,CUST_NUM
		,EFF_CUST_NUM
		,CREDIT_CUST_NUM
		,CREDIT_EFF_CUST_NUM
		,ODIAST_SCDY_MVAL_FINAL
		,ODIAST_STKF_MVAL_FINAL
		,ODIAST_A_SHR_MVAL_FINAL
		,ODIAST_NOTS_MVAL_FINAL
		,ODIAST_OFFUND_MVAL_FINAL
		,ODIAST_OPFUND_MVAL_FINAL
		,ODIAST_SB_MVAL_FINAL
		,ODIAST_IMGT_PD_MVAL_FINAL
		,ODIAST_BANK_CHRM_MVAL_FINAL
		,ODIAST_SECU_CHRM_MVAL_FINAL
		,ODIAST_PSTK_OPTN_MVAL_FINAL
		,ODIAST_B_SHR_MVAL_FINAL
		,ODIAST_OUTMARK_MVAL_FINAL
		,ODIAST_CPTL_BAL_FINAL
		,ODIAST_NO_ARVD_CPTL_FINAL
		,ODIAST_PTE_FUND_MVAL_FINAL
		,ODIAST_OVERSEA_TOTAST_FINAL
		,ODIAST_FUTR_TOTAST_FINAL
		,ODIAST_CPTL_BAL_RMB_FINAL
		,ODIAST_CPTL_BAL_HKD_FINAL
		,ODIAST_CPTL_BAL_USD_FINAL
		,ODIAST_LOW_RISK_TOTAST_FINAL
		,ODIAST_FUND_SPACCT_MVAL_FINAL
		,ODIAST_HGT_MVAL_FINAL
		,ODIAST_SGT_MVAL_FINAL
		,ODIAST_NET_AST_FINAL
		,ODIAST_TOTAST_CONTAIN_NOTS_FINAL
		,ODIAST_TOTAST_N_CONTAIN_NOTS_FINAL
		,ODIAST_BOND_MVAL_FINAL
		,ODIAST_REPO_MVAL_FINAL
		,ODIAST_TREA_REPO_MVAL_FINAL
		,ODIAST_REPQ_MVAL_FINAL
		,ODIAST_SCDY_MVAL_MDA
		,ODIAST_STKF_MVAL_MDA
		,ODIAST_A_SHR_MVAL_MDA
		,ODIAST_NOTS_MVAL_MDA
		,ODIAST_OFFUND_MVAL_MDA
		,ODIAST_OPFUND_MVAL_MDA
		,ODIAST_SB_MVAL_MDA
		,ODIAST_IMGT_PD_MVAL_MDA
		,ODIAST_BANK_CHRM_MVAL_MDA
		,ODIAST_SECU_CHRM_MVAL_MDA
		,ODIAST_PSTK_OPTN_MVAL_MDA
		,ODIAST_B_SHR_MVAL_MDA
		,ODIAST_OUTMARK_MVAL_MDA
		,ODIAST_CPTL_BAL_MDA
		,ODIAST_NO_ARVD_CPTL_MDA
		,ODIAST_PTE_FUND_MVAL_MDA
		,ODIAST_OVERSEA_TOTAST_MDA
		,ODIAST_FUTR_TOTAST_MDA
		,ODIAST_CPTL_BAL_RMB_MDA
		,ODIAST_CPTL_BAL_HKD_MDA
		,ODIAST_CPTL_BAL_USD_MDA
		,ODIAST_LOW_RISK_TOTAST_MDA
		,ODIAST_FUND_SPACCT_MVAL_MDA
		,ODIAST_HGT_MVAL_MDA
		,ODIAST_SGT_MVAL_MDA
		,ODIAST_NET_AST_MDA
		,ODIAST_TOTAST_CONTAIN_NOTS_MDA
		,ODIAST_TOTAST_N_CONTAIN_NOTS_MDA
		,ODIAST_BOND_MVAL_MDA
		,ODIAST_REPO_MVAL_MDA
		,ODIAST_TREA_REPO_MVAL_MDA
		,ODIAST_REPQ_MVAL_MDA
		,ODIAST_SCDY_MVAL_YDA
		,ODIAST_STKF_MVAL_YDA
		,ODIAST_A_SHR_MVAL_YDA
		,ODIAST_NOTS_MVAL_YDA
		,ODIAST_OFFUND_MVAL_YDA
		,ODIAST_OPFUND_MVAL_YDA
		,ODIAST_SB_MVAL_YDA
		,ODIAST_IMGT_PD_MVAL_YDA
		,ODIAST_BANK_CHRM_MVAL_YDA
		,ODIAST_SECU_CHRM_MVAL_YDA
		,ODIAST_PSTK_OPTN_MVAL_YDA
		,ODIAST_B_SHR_MVAL_YDA
		,ODIAST_OUTMARK_MVAL_YDA
		,ODIAST_CPTL_BAL_YDA
		,ODIAST_NO_ARVD_CPTL_YDA
		,ODIAST_PTE_FUND_MVAL_YDA
		,ODIAST_OVERSEA_TOTAST_YDA
		,ODIAST_FUTR_TOTAST_YDA
		,ODIAST_CPTL_BAL_RMB_YDA
		,ODIAST_CPTL_BAL_HKD_YDA
		,ODIAST_CPTL_BAL_USD_YDA
		,ODIAST_LOW_RISK_TOTAST_YDA
		,ODIAST_FUND_SPACCT_MVAL_YDA
		,ODIAST_HGT_MVAL_YDA
		,ODIAST_SGT_MVAL_YDA
		,ODIAST_NET_AST_YDA
		,ODIAST_TOTAST_CONTAIN_NOTS_YDA
		,ODIAST_TOTAST_N_CONTAIN_NOTS_YDA
		,ODIAST_BOND_MVAL_YDA
		,ODIAST_REPO_MVAL_YDA
		,ODIAST_TREA_REPO_MVAL_YDA
		,ODIAST_REPQ_MVAL_YDA
		,ODIAST_PO_FUND_MVAL_FINAL
		,ODIAST_PO_FUND_MVAL_MDA
		,ODIAST_PO_FUND_MVAL_YDA
		,ODIAST_STKT_FUND_MVAL_FINAL
		,ODIAST_OTH_PROD_MVAL_FINAL
		,ODIAST_OTH_AST_MVAL_FINAL
		,ODIAST_APPTBUYB_PLG_MVAL_FINAL
		,ODIAST_STKT_FUND_MVAL_MDA
		,ODIAST_OTH_PROD_MVAL_MDA
		,ODIAST_OTH_AST_MVAL_MDA
		,ODIAST_APPTBUYB_PLG_MVAL_MDA
		,ODIAST_STKT_FUND_MVAL_YDA
		,ODIAST_OTH_PROD_MVAL_YDA
		,ODIAST_OTH_AST_MVAL_YDA
		,ODIAST_APPTBUYB_PLG_MVAL_YDA
		,ODIAST_CREDIT_NET_AST_FINAL
		,ODIAST_CREDIT_MARG_FINAL
		,ODIAST_CREDIT_BAL_FINAL
		,ODIAST_CREDIT_NET_AST_MDA
		,ODIAST_CREDIT_MARG_MDA
		,ODIAST_CREDIT_BAL_MDA
		,ODIAST_CREDIT_NET_AST_YDA
		,ODIAST_CREDIT_MARG_YDA
		,ODIAST_CREDIT_BAL_YDA
		,ODIAST_PROD_TOT_MVAL_FINAL
		,ODIAST_PROD_TOT_MVAL_MDA
		,ODIAST_PROD_TOT_MVAL_YDA
		,ODIAST_TOTAST_FINAL
		,ODIAST_TOTAST_MDA
		,ODIAST_TOTAST_YDA
		,ODIAST_STKPLG_GUAR_SECMV_FINAL_SCDY_DEDUCT
		,ODIAST_STKPLG_GUAR_SECMV_MDA_SCDY_DEDUCT
		,ODIAST_STKPLG_GUAR_SECMV_YDA_SCDY_DEDUCT
		,ODIAST_STKPLG_LIAB_FINAL
		,ODIAST_STKPLG_LIAB_MDA
		,ODIAST_STKPLG_LIAB_YDA
		,ODIAST_CREDIT_TOT_LIAB_FINAL
		,ODIAST_CREDIT_TOT_LIAB_MDA
		,ODIAST_CREDIT_TOT_LIAB_YDA
		,ODIAST_APPTBUYB_BAL_FINAL
		,ODIAST_APPTBUYB_BAL_MDA
		,ODIAST_APPTBUYB_BAL_YDA
		,ODIAST_CREDIT_TOTAST_FINAL
		,ODIAST_CREDIT_TOTAST_MDA
		,ODIAST_CREDIT_TOTAST_YDA
		,ODIAST_STKPLG_GUAR_SECMV_FINAL
		,ODIAST_STKPLG_GUAR_SECMV_MDA
		,ODIAST_STKPLG_GUAR_SECMV_YDA
		,CREDIT_TOT_LIAB_FINAL
		,CREDIT_NET_AST_FINAL
		,CREDIT_CRED_MARG_FINAL
		,CREDIT_GUAR_SECMV_FINAL
		,CREDIT_FIN_LIAB_FINAL
		,CREDIT_CRDT_STK_LIAB_FINAL
		,CREDIT_INTR_LIAB_FINAL
		,CREDIT_FEE_LIAB_FINAL
		,CREDIT_OTHLIAB_FINAL
		,CREDIT_TOTAST_FINAL
		,CREDIT_A_SHR_MVAL_FINAL
		,CREDIT_TOT_LIAB_MDA
		,CREDIT_NET_AST_MDA
		,CREDIT_CRED_MARG_MDA
		,CREDIT_GUAR_SECMV_MDA
		,CREDIT_FIN_LIAB_MDA
		,CREDIT_CRDT_STK_LIAB_MDA
		,CREDIT_INTR_LIAB_MDA
		,CREDIT_FEE_LIAB_MDA
		,CREDIT_OTHLIAB_MDA
		,CREDIT_TOTAST_MDA
		,CREDIT_A_SHR_MVAL_MDA
		,CREDIT_TOT_LIAB_YDA
		,CREDIT_NET_AST_YDA
		,CREDIT_CRED_MARG_YDA
		,CREDIT_GUAR_SECMV_YDA
		,CREDIT_FIN_LIAB_YDA
		,CREDIT_CRDT_STK_LIAB_YDA
		,CREDIT_INTR_LIAB_YDA
		,CREDIT_FEE_LIAB_YDA
		,CREDIT_OTHLIAB_YDA
		,CREDIT_TOTAST_YDA
		,CREDIT_A_SHR_MVAL_YDA
		,ASTCHG_ODI_CPTL_INFLOW_MTD
		,ASTCHG_ODI_CPTL_OUTFLOW_MTD
		,ASTCHG_ODI_MVAL_INFLOW_MTD
		,ASTCHG_ODI_MVAL_OUTFLOW_MTD
		,ASTCHG_CREDIT_CPTL_INFLOW_MTD
		,ASTCHG_CREDIT_CPTL_OUTFLOW_MTD
		,ASTCHG_ODI_ACC_CPTL_NET_INFLOW_MTD
		,ASTCHG_CREDIT_CPTL_NET_INFLOW_MTD
		,ASTCHG_ODI_CPTL_INFLOW_YTD
		,ASTCHG_ODI_CPTL_OUTFLOW_YTD
		,ASTCHG_ODI_MVAL_INFLOW_YTD
		,ASTCHG_ODI_MVAL_OUTFLOW_YTD
		,ASTCHG_CREDIT_CPTL_INFLOW_YTD
		,ASTCHG_CREDIT_CPTL_OUTFLOW_YTD
		,ASTCHG_ODI_ACC_CPTL_NET_INFLOW_YTD
		,ASTCHG_CREDIT_CPTL_NET_INFLOW_YTD
		,ODI_INCM_PB_TRD_CMS_MTD
		,ODI_INCM_MARG_SPR_INCM_MTD
		,ODI_INCM_PB_TRD_CMS_YTD
		,ODI_INCM_MARG_SPR_INCM_YTD
		,ODI_INCM_GROSS_CMS_MTD
		,ODI_INCM_TRAN_FEE_MTD
		,ODI_INCM_SCDY_TRAN_FEE_MTD
		,ODI_INCM_STP_TAX_MTD
		,ODI_INCM_HANDLE_FEE_MTD
		,ODI_INCM_SEC_RGLT_FEE_MTD
		,ODI_INCM_OTH_FEE_MTD
		,ODI_INCM_STKF_CMS_MTD
		,ODI_INCM_STKF_TRAN_FEE_MTD
		,ODI_INCM_STKF_NET_CMS_MTD
		,ODI_INCM_BOND_CMS_MTD
		,ODI_INCM_BOND_NET_CMS_MTD
		,ODI_INCM_REPQ_CMS_MTD
		,ODI_INCM_REPQ_NET_CMS_MTD
		,ODI_INCM_HGT_CMS_MTD
		,ODI_INCM_HGT_NET_CMS_MTD
		,ODI_INCM_HGT_TRAN_FEE_MTD
		,ODI_INCM_SGT_CMS_MTD
		,ODI_INCM_SGT_NET_CMS_MTD
		,ODI_INCM_SGT_TRAN_FEE_MTD
		,ODI_INCM_BGDL_CMS_MTD
		,ODI_INCM_NET_CMS_MTD
		,ODI_INCM_BGDL_NET_CMS_MTD
		,ODI_INCM_BGDL_TRAN_FEE_MTD
		,ODI_INCM_PSTK_OPTN_CMS_MTD
		,ODI_INCM_PSTK_OPTN_NET_CMS_MTD
		,ODI_INCM_SCDY_CMS_MTD
		,ODI_INCM_SCDY_NET_CMS_MTD
		,ODI_INCM_GROSS_CMS_YTD
		,ODI_INCM_TRAN_FEE_YTD
		,ODI_INCM_SCDY_TRAN_FEE_YTD
		,ODI_INCM_STP_TAX_YTD
		,ODI_INCM_HANDLE_FEE_YTD
		,ODI_INCM_SEC_RGLT_FEE_YTD
		,ODI_INCM_OTH_FEE_YTD
		,ODI_INCM_STKF_CMS_YTD
		,ODI_INCM_STKF_TRAN_FEE_YTD
		,ODI_INCM_STKF_NET_CMS_YTD
		,ODI_INCM_BOND_CMS_YTD
		,ODI_INCM_BOND_NET_CMS_YTD
		,ODI_INCM_REPQ_CMS_YTD
		,ODI_INCM_REPQ_NET_CMS_YTD
		,ODI_INCM_HGT_CMS_YTD
		,ODI_INCM_HGT_NET_CMS_YTD
		,ODI_INCM_HGT_TRAN_FEE_YTD
		,ODI_INCM_SGT_CMS_YTD
		,ODI_INCM_SGT_NET_CMS_YTD
		,ODI_INCM_SGT_TRAN_FEE_YTD
		,ODI_INCM_BGDL_CMS_YTD
		,ODI_INCM_NET_CMS_YTD
		,ODI_INCM_BGDL_NET_CMS_YTD
		,ODI_INCM_BGDL_TRAN_FEE_YTD
		,ODI_INCM_PSTK_OPTN_CMS_YTD
		,ODI_INCM_PSTK_OPTN_NET_CMS_YTD
		,ODI_INCM_SCDY_CMS_YTD
		,ODI_INCM_SCDY_NET_CMS_YTD
		,CRED_INCM_CREDIT_MARG_SPR_INCM_YTD
		,CRED_INCM_CREDIT_MARG_SPR_INCM_MTD
		,CRED_INCM_GROSS_CMS_MTD
		,CRED_INCM_NET_CMS_MTD
		,CRED_INCM_TRAN_FEE_MTD
		,CRED_INCM_STP_TAX_MTD
		,CRED_INCM_ORDR_FEE_MTD
		,CRED_INCM_HANDLE_FEE_MTD
		,CRED_INCM_SEC_RGLT_FEE_MTD
		,CRED_INCM_OTH_FEE_MTD
		,CRED_INCM_CREDIT_ODI_CMS_MTD
		,CRED_INCM_CREDIT_ODI_NET_CMS_MTD
		,CRED_INCM_CREDIT_ODI_TRAN_FEE_MTD
		,CRED_INCM_CREDIT_CRED_CMS_MTD
		,CRED_INCM_CREDIT_CRED_NET_CMS_MTD
		,CRED_INCM_CREDIT_CRED_TRAN_FEE_MTD
		,CRED_INCM_STKPLG_CMS_MTD
		,CRED_INCM_STKPLG_NET_CMS_MTD
		,CRED_INCM_STKPLG_PAIDINT_MTD
		,CRED_INCM_STKPLG_RECE_INT_MTD
		,CRED_INCM_APPTBUYB_CMS_MTD
		,CRED_INCM_APPTBUYB_NET_CMS_MTD
		,CRED_INCM_APPTBUYB_PAIDINT_MTD
		,CRED_INCM_FIN_PAIDINT_MTD
		,CRED_INCM_FIN_IE_MTD
		,CRED_INCM_CRDT_STK_IE_MTD
		,CRED_INCM_OTH_IE_MTD
		,CRED_INCM_FIN_RECE_INT_MTD
		,CRED_INCM_FEE_RECE_INT_MTD
		,CRED_INCM_OTH_RECE_INT_MTD
		,CRED_INCM_CREDIT_CPTL_COST_MTD
		,CRED_INCM_GROSS_CMS_YTD
		,CRED_INCM_NET_CMS_YTD
		,CRED_INCM_TRAN_FEE_YTD
		,CRED_INCM_STP_TAX_YTD
		,CRED_INCM_ORDR_FEE_YTD
		,CRED_INCM_HANDLE_FEE_YTD
		,CRED_INCM_SEC_RGLT_FEE_YTD
		,CRED_INCM_OTH_FEE_YTD
		,CRED_INCM_CREDIT_ODI_CMS_YTD
		,CRED_INCM_CREDIT_ODI_NET_CMS_YTD
		,CRED_INCM_CREDIT_ODI_TRAN_FEE_YTD
		,CRED_INCM_CREDIT_CRED_CMS_YTD
		,CRED_INCM_CREDIT_CRED_NET_CMS_YTD
		,CRED_INCM_CREDIT_CRED_TRAN_FEE_YTD
		,CRED_INCM_STKPLG_CMS_YTD
		,CRED_INCM_STKPLG_NET_CMS_YTD
		,CRED_INCM_STKPLG_PAIDINT_YTD
		,CRED_INCM_STKPLG_RECE_INT_YTD
		,CRED_INCM_APPTBUYB_CMS_YTD
		,CRED_INCM_APPTBUYB_NET_CMS_YTD
		,CRED_INCM_APPTBUYB_PAIDINT_YTD
		,CRED_INCM_FIN_PAIDINT_YTD
		,CRED_INCM_FIN_IE_YTD
		,CRED_INCM_CRDT_STK_IE_YTD
		,CRED_INCM_OTH_IE_YTD
		,CRED_INCM_FIN_RECE_INT_YTD
		,CRED_INCM_FEE_RECE_INT_YTD
		,CRED_INCM_OTH_RECE_INT_YTD
		,CRED_INCM_CREDIT_CPTL_COST_YTD
		,APPTBUYB_GUAR_SECMV_FINAL
		,APPTBUYB_APPTBUYB_BAL_FINAL
		,APPTBUYB_SH_GUAR_SECMV_FINAL
		,APPTBUYB_SZ_GUAR_SECMV_FINAL
		,APPTBUYB_SH_NOTS_GUAR_SECMV_FINAL
		,APPTBUYB_SZ_NOTS_GUAR_SECMV_FINAL
		,APPTBUYB_PROP_FINOS_BAL_FINAL
		,APPTBUYB_ASSM_FINOS_BAL_FINAL
		,APPTBUYB_SM_LOAN_FINO_BAL_FINAL
		,APPTBUYB_GUAR_SECMV_MDA
		,APPTBUYB_APPTBUYB_BAL_MDA
		,APPTBUYB_SH_GUAR_SECMV_MDA
		,APPTBUYB_SZ_GUAR_SECMV_MDA
		,APPTBUYB_SH_NOTS_GUAR_SECMV_MDA
		,APPTBUYB_SZ_NOTS_GUAR_SECMV_MDA
		,APPTBUYB_PROP_FINOS_BAL_MDA
		,APPTBUYB_ASSM_FINOS_BAL_MDA
		,APPTBUYB_SM_LOAN_FINO_BAL_MDA
		,APPTBUYB_GUAR_SECMV_YDA
		,APPTBUYB_APPTBUYB_BAL_YDA
		,APPTBUYB_SH_GUAR_SECMV_YDA
		,APPTBUYB_SZ_GUAR_SECMV_YDA
		,APPTBUYB_SH_NOTS_GUAR_SECMV_YDA
		,APPTBUYB_SZ_NOTS_GUAR_SECMV_YDA
		,APPTBUYB_PROP_FINOS_BAL_YDA
		,APPTBUYB_ASSM_FINOS_BAL_YDA
		,APPTBUYB_SM_LOAN_FINO_BAL_YDA
		,STKPLG_GUAR_SECMV_FINAL
		,STKPLG_STKPLG_FIN_BAL_FINAL
		,STKPLG_SH_GUAR_SECMV_FINAL
		,STKPLG_SZ_GUAR_SECMV_FINAL
		,STKPLG_SH_NOTS_GUAR_SECMV_FINAL
		,STKPLG_SZ_NOTS_GUAR_SECMV_FINAL
		,STKPLG_PROP_FINOS_BAL_FINAL
		,STKPLG_ASSM_FINOS_BAL_FINAL
		,STKPLG_SM_LOAN_FINO_BAL_FINAL
		,STKPLG_GUAR_SECMV_MDA
		,STKPLG_STKPLG_FIN_BAL_MDA
		,STKPLG_SH_GUAR_SECMV_MDA
		,STKPLG_SZ_GUAR_SECMV_MDA
		,STKPLG_SH_NOTS_GUAR_SECMV_MDA
		,STKPLG_SZ_NOTS_GUAR_SECMV_MDA
		,STKPLG_PROP_FINOS_BAL_MDA
		,STKPLG_ASSM_FINOS_BAL_MDA
		,STKPLG_SM_LOAN_FINO_BAL_MDA
		,STKPLG_GUAR_SECMV_YDA
		,STKPLG_STKPLG_FIN_BAL_YDA
		,STKPLG_SH_GUAR_SECMV_YDA
		,STKPLG_SZ_GUAR_SECMV_YDA
		,STKPLG_SH_NOTS_GUAR_SECMV_YDA
		,STKPLG_SZ_NOTS_GUAR_SECMV_YDA
		,STKPLG_PROP_FINOS_BAL_YDA
		,STKPLG_ASSM_FINOS_BAL_YDA
		,STKPLG_SM_LOAN_FINO_BAL_YDA
		,ODI_TRD_SCDY_TRD_FREQ_MTD
		,ODI_TRD_SCDY_TRD_QTY_MTD
		,ODI_TRD_SCDY_TRD_QTY_YTD
		,ODI_TRD_TRD_FREQ_YTD
		,ODI_TRD_STKF_TRD_QTY_MTD
		,ODI_TRD_STKF_TRD_QTY_YTD
		,ODI_TRD_S_REPUR_TRD_QTY_MTD
		,ODI_TRD_R_REPUR_TRD_QTY_MTD
		,ODI_TRD_S_REPUR_TRD_QTY_YTD
		,ODI_TRD_R_REPUR_TRD_QTY_YTD
		,ODI_TRD_HGT_TRD_QTY_MTD
		,ODI_TRD_SGT_TRD_QTY_MTD
		,ODI_TRD_SGT_TRD_QTY_YTD
		,ODI_TRD_HGT_TRD_QTY_YTD
		,ODI_TRD_Y_RCT_STK_TRD_QTY
		,ODI_TRD_SCDY_TRD_FREQ_YTD
		,ODI_TRD_TRD_FREQ_MTD
		,ODI_TRD_APPTBUYB_TRD_QTY_MTD
		,ODI_TRD_APPTBUYB_TRD_QTY_YTD
		,ODI_TRD_RCT_TRD_DT_M
		,ODI_TRD_STKPLG_TRD_QTY_MTD
		,ODI_TRD_STKPLG_TRD_QTY_YTD
		,ODI_TRD_PSTK_OPTN_TRD_QTY_MTD
		,ODI_TRD_PSTK_OPTN_TRD_QTY_YTD
		,ODI_TRD_REPQ_TRD_QTY_MTD
		,ODI_TRD_REPQ_TRD_QTY_YTD
		,ODI_TRD_BGDL_QTY_MTD
		,ODI_TRD_BGDL_QTY_YTD
		,CREDIT_CRED_QUO
		,APPTBUYB_CRED_QUO
		,STKPLG_CRED_QUO
		,LOAD_DT
		,ODI_TRD_SB_TRD_QTY_MTD
		,ODI_TRD_SB_TRD_QTY_YTD
		,ODI_TRD_BOND_TRD_QTY_MTD
		,ODI_TRD_BOND_TRD_QTY_YTD
		,ODI_TRD_ITC_CRRC_FUND_TRD_QTY_MTD
		,ODI_TRD_ITC_CRRC_FUND_TRD_QTY_YTD
		,ODI_TRD_S_REPUR_NET_CMS_MTD
		,ODI_TRD_S_REPUR_NET_CMS_YTD
		,ODI_TRD_R_REPUR_NET_CMS_MTD
		,ODI_TRD_R_REPUR_NET_CMS_YTD
		,ODI_TRD_ITC_CRRC_FUND_NET_CMS_MTD
		,ODI_TRD_ITC_CRRC_FUND_NET_CMS_YTD
	)

select
	 t1.YEAR as 年
	,t1.MTH as 月
	,t1.YEAR||t1.MTH as 年月
	,t_jg.WH_ORG_ID as 机构编号	
	
	--维度信息
	,t_khsx.客户状态
	,t_khsx.是否特殊账户
	,t_khsx.是否产品新客户
	,t_khsx.是否月新增
	,t_khsx.是否年新增	
	,t_khsx.是否融资融券客户
	,t_khsx.是否融资融券月新增
	,t_khsx.是否融资融券年新增
	,t_khsx.是否融资融券有效客户
	,t_khsx.是否融资融券月新增有效户
	,t_khsx.是否融资融券年新增有效户
	,t_khsx.资产段
	,t_khsx.客户类型	
	
	,sum(case when t_khsx.客户状态='0' then t2.PERFM_RATI1 else 0 end) as 客户数
	,sum(case when t_khsx.客户状态='0' and t_khsx.是否有效=1 then t2.PERFM_RATI1 else 0 end) as 有效客户数
	,sum(case when t_khsx.客户状态='0' and t_khsx.是否融资融券客户=1 then t2.PERFM_RATI9 else 0 end) as 融资融券_客户数
	,sum(case when t_khsx.客户状态='0' and t_khsx.是否融资融券客户=1 and t_khsx.是否融资融券有效客户=1 then t2.PERFM_RATI9 else 0 end) as 融资融券_有效客户数
	
	--普通资产
	,sum(COALESCE(t1.SCDY_MVAL_FINAL,0)) as 普通资产_二级市值_期末
	,sum(COALESCE(t1.STKF_MVAL_FINAL,0)) as 普通资产_股基市值_期末
	,sum(COALESCE(t1.A_SHR_MVAL_FINAL,0)) as 普通资产_A股市值_期末
	,sum(COALESCE(t1.NOTS_MVAL_FINAL,0)) as 普通资产_限售股市值_期末
	,sum(COALESCE(t1.OFFUND_MVAL_FINAL,0)) as 普通资产_场内基金市值_期末
	,sum(COALESCE(t1.OPFUND_MVAL_FINAL,0)) as 普通资产_场外基金市值_期末
	,sum(COALESCE(t1.SB_MVAL_FINAL,0)) as 普通资产_三板市值_期末
	,sum(COALESCE(t1.IMGT_PD_MVAL_FINAL,0)) as 普通资产_资管产品市值_期末
	,sum(COALESCE(t1.BANK_CHRM_MVAL_FINAL,0)) as 普通资产_银行理财市值_期末
	,sum(COALESCE(t1.SECU_CHRM_MVAL_FINAL,0)) as 普通资产_证券理财市值_期末
	,sum(COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0)) as 普通资产_个股期权市值_期末
	,sum(COALESCE(t1.B_SHR_MVAL_FINAL,0)) as 普通资产_B股市值_期末
	,sum(COALESCE(t1.OUTMARK_MVAL_FINAL,0)) as 普通资产_体外市值_期末
	,sum(COALESCE(t1.CPTL_BAL_FINAL,0)) as 普通资产_资金余额_期末
	,sum(COALESCE(t1.NO_ARVD_CPTL_FINAL,0)) as 普通资产_未到账资金_期末
	,sum(COALESCE(t1.PTE_FUND_MVAL_FINAL,0)) as 普通资产_私募基金市值_期末
	,sum(COALESCE(t1.OVERSEA_TOT_AST_FINAL,0)) as 普通资产_海外总资产_期末
	,sum(COALESCE(t1.FUTR_TOT_AST_FINAL,0)) as 普通资产_期货总资产_期末
	,sum(COALESCE(t1.CPTL_BAL_RMB_FINAL,0)) as 普通资产_资金余额人民币_期末
	,sum(COALESCE(t1.CPTL_BAL_HKD_FINAL,0)) as 普通资产_资金余额港币_期末
	,sum(COALESCE(t1.CPTL_BAL_USD_FINAL,0)) as 普通资产_资金余额美元_期末
	,sum(COALESCE(t1.LOW_RISK_TOT_AST_FINAL,0)) as 普通资产_低风险总资产_期末
	,sum(COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0)) as 普通资产_基金专户市值_期末
	,sum(COALESCE(t1.HGT_MVAL_FINAL,0)) as 普通资产_沪港通市值_期末
	,sum(COALESCE(t1.SGT_MVAL_FINAL,0)) as 普通资产_深港通市值_期末
	,sum(COALESCE(t1.NET_AST_FINAL,0)) as 普通资产_净资产_期末
	,sum(COALESCE(t1.TOT_AST_CONTAIN_NOTS_FINAL,0)) as 普通资产_总资产_含限售股_期末
	,sum(COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_FINAL,0)) as 普通资产_总资产_不含限售股_期末
	,sum(COALESCE(t1.BOND_MVAL_FINAL,0)) as 普通资产_债券市值_期末
	,sum(COALESCE(t1.REPO_MVAL_FINAL,0)) as 普通资产_回购市值_期末
	,sum(COALESCE(t1.TREA_REPO_MVAL_FINAL,0)) as 普通资产_国债回购市值_期末
	,sum(COALESCE(t1.REPQ_MVAL_FINAL,0)) as 普通资产_报价回购市值_期末
	,sum(COALESCE(t1.SCDY_MVAL_MDA,0)) as 普通资产_二级市值_月日均
	,sum(COALESCE(t1.STKF_MVAL_MDA,0)) as 普通资产_股基市值_月日均
	,sum(COALESCE(t1.A_SHR_MVAL_MDA,0)) as 普通资产_A股市值_月日均
	,sum(COALESCE(t1.NOTS_MVAL_MDA,0)) as 普通资产_限售股市值_月日均
	,sum(COALESCE(t1.OFFUND_MVAL_MDA,0)) as 普通资产_场内基金市值_月日均
	,sum(COALESCE(t1.OPFUND_MVAL_MDA,0)) as 普通资产_场外基金市值_月日均
	,sum(COALESCE(t1.SB_MVAL_MDA,0)) as 普通资产_三板市值_月日均
	,sum(COALESCE(t1.IMGT_PD_MVAL_MDA,0)) as 普通资产_资管产品市值_月日均
	,sum(COALESCE(t1.BANK_CHRM_MVAL_MDA,0)) as 普通资产_银行理财市值_月日均
	,sum(COALESCE(t1.SECU_CHRM_MVAL_MDA,0)) as 普通资产_证券理财市值_月日均
	,sum(COALESCE(t1.PSTK_OPTN_MVAL_MDA,0)) as 普通资产_个股期权市值_月日均
	,sum(COALESCE(t1.B_SHR_MVAL_MDA,0)) as 普通资产_B股市值_月日均
	,sum(COALESCE(t1.OUTMARK_MVAL_MDA,0)) as 普通资产_体外市值_月日均
	,sum(COALESCE(t1.CPTL_BAL_MDA,0)) as 普通资产_资金余额_月日均
	,sum(COALESCE(t1.NO_ARVD_CPTL_MDA,0)) as 普通资产_未到账资金_月日均
	,sum(COALESCE(t1.PTE_FUND_MVAL_MDA,0)) as 普通资产_私募基金市值_月日均
	,sum(COALESCE(t1.OVERSEA_TOT_AST_MDA,0)) as 普通资产_海外总资产_月日均
	,sum(COALESCE(t1.FUTR_TOT_AST_MDA,0)) as 普通资产_期货总资产_月日均
	,sum(COALESCE(t1.CPTL_BAL_RMB_MDA,0)) as 普通资产_资金余额人民币_月日均
	,sum(COALESCE(t1.CPTL_BAL_HKD_MDA,0)) as 普通资产_资金余额港币_月日均
	,sum(COALESCE(t1.CPTL_BAL_USD_MDA,0)) as 普通资产_资金余额美元_月日均
	,sum(COALESCE(t1.LOW_RISK_TOT_AST_MDA,0)) as 普通资产_低风险总资产_月日均
	,sum(COALESCE(t1.FUND_SPACCT_MVAL_MDA,0)) as 普通资产_基金专户市值_月日均
	,sum(COALESCE(t1.HGT_MVAL_MDA,0)) as 普通资产_沪港通市值_月日均
	,sum(COALESCE(t1.SGT_MVAL_MDA,0)) as 普通资产_深港通市值_月日均
	,sum(COALESCE(t1.NET_AST_MDA,0)) as 普通资产_净资产_月日均
	,sum(COALESCE(t1.TOT_AST_CONTAIN_NOTS_MDA,0)) as 普通资产_总资产_含限售股_月日均
	,sum(COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_MDA,0)) as 普通资产_总资产_不含限售股_月日均
	,sum(COALESCE(t1.BOND_MVAL_MDA,0)) as 普通资产_债券市值_月日均
	,sum(COALESCE(t1.REPO_MVAL_MDA,0)) as 普通资产_回购市值_月日均
	,sum(COALESCE(t1.TREA_REPO_MVAL_MDA,0)) as 普通资产_国债回购市值_月日均
	,sum(COALESCE(t1.REPQ_MVAL_MDA,0)) as 普通资产_报价回购市值_月日均
	,sum(COALESCE(t1.SCDY_MVAL_YDA,0)) as 普通资产_二级市值_年日均
	,sum(COALESCE(t1.STKF_MVAL_YDA,0)) as 普通资产_股基市值_年日均
	,sum(COALESCE(t1.A_SHR_MVAL_YDA,0)) as 普通资产_A股市值_年日均
	,sum(COALESCE(t1.NOTS_MVAL_YDA,0)) as 普通资产_限售股市值_年日均
	,sum(COALESCE(t1.OFFUND_MVAL_YDA,0)) as 普通资产_场内基金市值_年日均
	,sum(COALESCE(t1.OPFUND_MVAL_YDA,0)) as 普通资产_场外基金市值_年日均
	,sum(COALESCE(t1.SB_MVAL_YDA,0)) as 普通资产_三板市值_年日均
	,sum(COALESCE(t1.IMGT_PD_MVAL_YDA,0)) as 普通资产_资管产品市值_年日均
	,sum(COALESCE(t1.BANK_CHRM_MVAL_YDA,0)) as 普通资产_银行理财市值_年日均
	,sum(COALESCE(t1.SECU_CHRM_MVAL_YDA,0)) as 普通资产_证券理财市值_年日均
	,sum(COALESCE(t1.PSTK_OPTN_MVAL_YDA,0)) as 普通资产_个股期权市值_年日均
	,sum(COALESCE(t1.B_SHR_MVAL_YDA,0)) as 普通资产_B股市值_年日均
	,sum(COALESCE(t1.OUTMARK_MVAL_YDA,0)) as 普通资产_体外市值_年日均
	,sum(COALESCE(t1.CPTL_BAL_YDA,0)) as 普通资产_资金余额_年日均
	,sum(COALESCE(t1.NO_ARVD_CPTL_YDA,0)) as 普通资产_未到账资金_年日均
	,sum(COALESCE(t1.PTE_FUND_MVAL_YDA,0)) as 普通资产_私募基金市值_年日均
	,sum(COALESCE(t1.OVERSEA_TOT_AST_YDA,0)) as 普通资产_海外总资产_年日均
	,sum(COALESCE(t1.FUTR_TOT_AST_YDA,0)) as 普通资产_期货总资产_年日均
	,sum(COALESCE(t1.CPTL_BAL_RMB_YDA,0)) as 普通资产_资金余额人民币_年日均
	,sum(COALESCE(t1.CPTL_BAL_HKD_YDA,0)) as 普通资产_资金余额港币_年日均
	,sum(COALESCE(t1.CPTL_BAL_USD_YDA,0)) as 普通资产_资金余额美元_年日均
	,sum(COALESCE(t1.LOW_RISK_TOT_AST_YDA,0)) as 普通资产_低风险总资产_年日均
	,sum(COALESCE(t1.FUND_SPACCT_MVAL_YDA,0)) as 普通资产_基金专户市值_年日均
	,sum(COALESCE(t1.HGT_MVAL_YDA,0)) as 普通资产_沪港通市值_年日均
	,sum(COALESCE(t1.SGT_MVAL_YDA,0)) as 普通资产_深港通市值_年日均
	,sum(COALESCE(t1.NET_AST_YDA,0)) as 普通资产_净资产_年日均
	,sum(COALESCE(t1.TOT_AST_CONTAIN_NOTS_YDA,0)) as 普通资产_总资产_含限售股_年日均
	,sum(COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_YDA,0)) as 普通资产_总资产_不含限售股_年日均
	,sum(COALESCE(t1.BOND_MVAL_YDA,0)) as 普通资产_债券市值_年日均
	,sum(COALESCE(t1.REPO_MVAL_YDA,0)) as 普通资产_回购市值_年日均
	,sum(COALESCE(t1.TREA_REPO_MVAL_YDA,0)) as 普通资产_国债回购市值_年日均
	,sum(COALESCE(t1.REPQ_MVAL_YDA,0)) as 普通资产_报价回购市值_年日均
	,sum(COALESCE(t1.PO_FUND_MVAL_FINAL,0)) as 普通资产_公募基金市值_期末
	,sum(COALESCE(t1.PO_FUND_MVAL_MDA,0)) as 普通资产_公募基金市值_月日均
	,sum(COALESCE(t1.PO_FUND_MVAL_YDA,0)) as 普通资产_公募基金市值_年日均
	,sum(COALESCE(t1.STKT_FUND_MVAL_FINAL,0)) as 普通资产_股票型基金市值_期末
	,sum(COALESCE(t1.OTH_PROD_MVAL_FINAL,0)) as 普通资产_其他产品市值_期末
	,sum(COALESCE(t1.OTH_AST_MVAL_FINAL,0)) as 普通资产_其他资产市值_期末
	,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0)) as 普通资产_约定购回质押市值_期末
	,sum(COALESCE(t1.STKT_FUND_MVAL_MDA,0)) as 普通资产_股票型基金市值_月日均
	,sum(COALESCE(t1.OTH_PROD_MVAL_MDA,0)) as 普通资产_其他产品市值_月日均
	,sum(COALESCE(t1.OTH_AST_MVAL_MDA,0)) as 普通资产_其他资产市值_月日均
	,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0)) as 普通资产_约定购回质押市值_月日均
	,sum(COALESCE(t1.STKT_FUND_MVAL_YDA,0)) as 普通资产_股票型基金市值_年日均
	,sum(COALESCE(t1.OTH_PROD_MVAL_YDA,0)) as 普通资产_其他产品市值_年日均
	,sum(COALESCE(t1.OTH_AST_MVAL_YDA,0)) as 普通资产_其他资产市值_年日均
	,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0)) as 普通资产_约定购回质押市值_年日均
	,sum(COALESCE(t1.CREDIT_NET_AST_FINAL,0)) as 普通资产_融资融券净资产_期末
	,sum(COALESCE(t1.CREDIT_MARG_FINAL,0)) as 普通资产_融资融券保证金_期末
	,sum(COALESCE(t1.CREDIT_BAL_FINAL,0)) as 普通资产_融资融券余额_期末
	,sum(COALESCE(t1.CREDIT_NET_AST_MDA,0)) as 普通资产_融资融券净资产_月日均
	,sum(COALESCE(t1.CREDIT_MARG_MDA,0)) as 普通资产_融资融券保证金_月日均
	,sum(COALESCE(t1.CREDIT_BAL_MDA,0)) as 普通资产_融资融券余额_月日均
	,sum(COALESCE(t1.CREDIT_NET_AST_YDA,0)) as 普通资产_融资融券净资产_年日均
	,sum(COALESCE(t1.CREDIT_MARG_YDA,0)) as 普通资产_融资融券保证金_年日均
	,sum(COALESCE(t1.CREDIT_BAL_YDA,0)) as 普通资产_融资融券余额_年日均
	,sum(COALESCE(t1.PROD_TOT_MVAL_FINAL,0)) as 普通资产_产品总市值_期末
	,sum(COALESCE(t1.PROD_TOT_MVAL_MDA,0)) as 普通资产_产品总市值_月日均
	,sum(COALESCE(t1.PROD_TOT_MVAL_YDA,0)) as 普通资产_产品总市值_年日均
	,sum(COALESCE(t1.TOT_AST_FINAL,0)) as 普通资产_总资产_期末
	,sum(COALESCE(t1.TOT_AST_MDA,0)) as 普通资产_总资产_月日均
	,sum(COALESCE(t1.TOT_AST_YDA,0)) as 普通资产_总资产_年日均
	
	,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_FINAL_SCDY_DEDUCT,0)) as 普通资产_股票质押担保证券市值_期末_二级扣减
	,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_MDA_SCDY_DEDUCT,0)) as 普通资产_股票质押担保证券市值_月日均_二级扣减
	,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_YDA_SCDY_DEDUCT,0)) as 普通资产_股票质押担保证券市值_年日均_二级扣减
	,sum(COALESCE(t1.STKPLG_LIAB_FINAL,0)) as 普通资产_股票质押负债_期末
	,sum(COALESCE(t1.STKPLG_LIAB_MDA,0)) as 普通资产_股票质押负债_月日均
	,sum(COALESCE(t1.STKPLG_LIAB_YDA,0)) as 普通资产_股票质押负债_年日均
	,sum(COALESCE(t1.CREDIT_TOT_LIAB_FINAL,0)) as 普通资产_融资融券总负债_期末
	,sum(COALESCE(t1.CREDIT_TOT_LIAB_MDA,0)) as 普通资产_融资融券总负债_月日均
	,sum(COALESCE(t1.CREDIT_TOT_LIAB_YDA,0)) as 普通资产_融资融券总负债_年日均
	,sum(COALESCE(t1.APPTBUYB_BAL_FINAL,0)) as 普通资产_约定购回余额_期末
	,sum(COALESCE(t1.APPTBUYB_BAL_MDA,0)) as 普通资产_约定购回余额_月日均
	,sum(COALESCE(t1.APPTBUYB_BAL_YDA,0)) as 普通资产_约定购回余额_年日均
	,sum(COALESCE(t1.CREDIT_TOT_AST_FINAL,0)) as 普通资产_融资融券总资产_期末
	,sum(COALESCE(t1.CREDIT_TOT_AST_MDA,0)) as 普通资产_融资融券总资产_月日均
	,sum(COALESCE(t1.CREDIT_TOT_AST_YDA,0)) as 普通资产_融资融券总资产_年日均
	,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_FINAL,0)) as 普通资产_股票质押担保证券市值_期末
	,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_MDA,0)) as 普通资产_股票质押担保证券市值_月日均
	,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_YDA,0)) as 普通资产_股票质押担保证券市值_年日均
	
	--融资融券
	,sum(COALESCE(t_rzrq.TOT_LIAB_FINAL,0)) as 融资融券_总负债_期末
	,sum(COALESCE(t_rzrq.NET_AST_FINAL,0)) as 融资融券_净资产_期末
	,sum(COALESCE(t_rzrq.CRED_MARG_FINAL,0)) as 融资融券_信用保证金_期末
	,sum(COALESCE(t_rzrq.GUAR_SECU_MVAL_FINAL,0)) as 融资融券_担保证券市值_期末
	,sum(COALESCE(t_rzrq.FIN_LIAB_FINAL,0)) as 融资融券_融资负债_期末
	,sum(COALESCE(t_rzrq.CRDT_STK_LIAB_FINAL,0)) as 融资融券_融券负债_期末
	,sum(COALESCE(t_rzrq.INTR_LIAB_FINAL,0)) as 融资融券_利息负债_期末
	,sum(COALESCE(t_rzrq.FEE_LIAB_FINAL,0)) as 融资融券_费用负债_期末
	,sum(COALESCE(t_rzrq.OTH_LIAB_FINAL,0)) as 融资融券_其他负债_期末
	,sum(COALESCE(t_rzrq.TOT_AST_FINAL,0)) as 融资融券_总资产_期末
	,sum(COALESCE(t_rzrq.A_SHR_MVAL_FINAL,0)) as 融资融券_A股市值_期末
	
	,sum(COALESCE(t_rzrq.TOT_LIAB_MDA,0)) as 融资融券_总负债_月日均
	,sum(COALESCE(t_rzrq.NET_AST_MDA,0)) as 融资融券_净资产_月日均
	,sum(COALESCE(t_rzrq.CRED_MARG_MDA,0)) as 融资融券_信用保证金_月日均
	,sum(COALESCE(t_rzrq.GUAR_SECU_MVAL_MDA,0)) as 融资融券_担保证券市值_月日均
	,sum(COALESCE(t_rzrq.FIN_LIAB_MDA,0)) as 融资融券_融资负债_月日均
	,sum(COALESCE(t_rzrq.CRDT_STK_LIAB_MDA,0)) as 融资融券_融券负债_月日均
	,sum(COALESCE(t_rzrq.INTR_LIAB_MDA,0)) as 融资融券_利息负债_月日均
	,sum(COALESCE(t_rzrq.FEE_LIAB_MDA,0)) as 融资融券_费用负债_月日均
	,sum(COALESCE(t_rzrq.OTH_LIAB_MDA,0)) as 融资融券_其他负债_月日均
	,sum(COALESCE(t_rzrq.TOT_AST_MDA,0)) as 融资融券_总资产_月日均
	,sum(COALESCE(t_rzrq.A_SHR_MVAL_MDA,0)) as 融资融券_A股市值_月日均
	
	,sum(COALESCE(t_rzrq.TOT_LIAB_YDA,0)) as 融资融券_总负债_年日均
	,sum(COALESCE(t_rzrq.NET_AST_YDA,0)) as 融资融券_净资产_年日均
	,sum(COALESCE(t_rzrq.CRED_MARG_YDA,0)) as 融资融券_信用保证金_年日均
	,sum(COALESCE(t_rzrq.GUAR_SECU_MVAL_YDA,0)) as 融资融券_担保证券市值_年日均
	,sum(COALESCE(t_rzrq.FIN_LIAB_YDA,0)) as 融资融券_融资负债_年日均
	,sum(COALESCE(t_rzrq.CRDT_STK_LIAB_YDA,0)) as 融资融券_融券负债_年日均
	,sum(COALESCE(t_rzrq.INTR_LIAB_YDA,0)) as 融资融券_利息负债_年日均
	,sum(COALESCE(t_rzrq.FEE_LIAB_YDA,0)) as 融资融券_费用负债_年日均
	,sum(COALESCE(t_rzrq.OTH_LIAB_YDA,0)) as 融资融券_其他负债_年日均
	,sum(COALESCE(t_rzrq.TOT_AST_YDA,0)) as 融资融券_总资产_年日均
	,sum(COALESCE(t_rzrq.A_SHR_MVAL_YDA,0)) as 融资融券_A股市值_年日均
	
	--资产变动
	,sum(COALESCE(t_zcbd.ODI_CPTL_INFLOW_MTD,0)) as 资产变动_普通资金流入_月累计
	,sum(COALESCE(t_zcbd.ODI_CPTL_OUTFLOW_MTD,0)) as 资产变动_普通资金流出_月累计
	,sum(COALESCE(t_zcbd.ODI_MVAL_INFLOW_MTD,0)) as 资产变动_普通市值流入_月累计
	,sum(COALESCE(t_zcbd.ODI_MVAL_OUTFLOW_MTD,0)) as 资产变动_普通市值流出_月累计
	,sum(COALESCE(t_zcbd.CREDIT_CPTL_INFLOW_MTD,0)) as 资产变动_两融资金流入_月累计
	,sum(COALESCE(t_zcbd.CREDIT_CPTL_OUTFLOW_MTD,0)) as 资产变动_两融资金流出_月累计
	,sum(COALESCE(t_zcbd.ODI_ACC_CPTL_NET_INFLOW_MTD,0)) as 资产变动_普通账户资金净流入_月累计
	,sum(COALESCE(t_zcbd.CREDIT_CPTL_NET_INFLOW_MTD,0)) as 资产变动_两融资金净流入_月累计
	,sum(COALESCE(t_zcbd.ODI_CPTL_INFLOW_YTD,0)) as 资产变动_普通资金流入_年累计
	,sum(COALESCE(t_zcbd.ODI_CPTL_OUTFLOW_YTD,0)) as 资产变动_普通资金流出_年累计
	,sum(COALESCE(t_zcbd.ODI_MVAL_INFLOW_YTD,0)) as 资产变动_普通市值流入_年累计
	,sum(COALESCE(t_zcbd.ODI_MVAL_OUTFLOW_YTD,0)) as 资产变动_普通市值流出_年累计
	,sum(COALESCE(t_zcbd.CREDIT_CPTL_INFLOW_YTD,0)) as 资产变动_两融资金流入_年累计
	,sum(COALESCE(t_zcbd.CREDIT_CPTL_OUTFLOW_YTD,0)) as 资产变动_两融资金流出_年累计
	,sum(COALESCE(t_zcbd.ODI_ACC_CPTL_NET_INFLOW_YTD,0)) as 资产变动_普通账户资金净流入_年累计
	,sum(COALESCE(t_zcbd.CREDIT_CPTL_NET_INFLOW_YTD,0)) as 资产变动_两融资金净流入_年累计
	
	--普通收入更新日期20180411
	,sum(COALESCE(t_ptsr.PB_TRD_CMS_MTD,0)) as 普通收入_PB交易佣金_月累计
	,sum(COALESCE(t_ptsr.MARG_SPR_INCM_MTD,0)) as 普通收入_保证金利差收入_月累计
	,sum(COALESCE(t_ptsr.PB_TRD_CMS_YTD,0)) as 普通收入_PB交易佣金_年累计
	,sum(COALESCE(t_ptsr.MARG_SPR_INCM_YTD,0)) as 普通收入_保证金利差收入_年累计
	,sum(COALESCE(t_ptsr.GROSS_CMS_MTD,0)) as 普通收入_毛佣金_月累计
	,sum(COALESCE(t_ptsr.TRAN_FEE_MTD,0)) as 普通收入_过户费_月累计
	,sum(COALESCE(t_ptsr.SCDY_TRAN_FEE_MTD,0)) as 普通收入_二级过户费_月累计
	,sum(COALESCE(t_ptsr.STP_TAX_MTD,0)) as 普通收入_印花税_月累计
	,sum(COALESCE(t_ptsr.HANDLE_FEE_MTD,0)) as 普通收入_经手费_月累计
	,sum(COALESCE(t_ptsr.SEC_RGLT_FEE_MTD,0)) as 普通收入_证管费_月累计
	,sum(COALESCE(t_ptsr.OTH_FEE_MTD,0)) as 普通收入_其他费用_月累计
	,sum(COALESCE(t_ptsr.STKF_CMS_MTD,0)) as 普通收入_股基佣金_月累计
	,sum(COALESCE(t_ptsr.STKF_TRAN_FEE_MTD,0)) as 普通收入_股基过户费_月累计
	,sum(COALESCE(t_ptsr.STKF_NET_CMS_MTD,0)) as 普通收入_股基净佣金_月累计
	,sum(COALESCE(t_ptsr.BOND_CMS_MTD,0)) as 普通收入_债券佣金_月累计
	,sum(COALESCE(t_ptsr.BOND_NET_CMS_MTD,0)) as 普通收入_债券净佣金_月累计
	,sum(COALESCE(t_ptsr.REPQ_CMS_MTD,0)) as 普通收入_报价回购佣金_月累计
	,sum(COALESCE(t_ptsr.REPQ_NET_CMS_MTD,0)) as 普通收入_报价回购净佣金_月累计
	,sum(COALESCE(t_ptsr.HGT_CMS_MTD,0)) as 普通收入_沪港通佣金_月累计
	,sum(COALESCE(t_ptsr.HGT_NET_CMS_MTD,0)) as 普通收入_沪港通净佣金_月累计
	,sum(COALESCE(t_ptsr.HGT_TRAN_FEE_MTD,0)) as 普通收入_沪港通过户费_月累计
	,sum(COALESCE(t_ptsr.SGT_CMS_MTD,0)) as 普通收入_深港通佣金_月累计
	,sum(COALESCE(t_ptsr.SGT_NET_CMS_MTD,0)) as 普通收入_深港通净佣金_月累计
	,sum(COALESCE(t_ptsr.SGT_TRAN_FEE_MTD,0)) as 普通收入_深港通过户费_月累计
	,sum(COALESCE(t_ptsr.BGDL_CMS_MTD,0)) as 普通收入_大宗交易佣金_月累计
	,sum(COALESCE(t_ptsr.NET_CMS_MTD,0)) as 普通收入_净佣金_月累计
	,sum(COALESCE(t_ptsr.BGDL_NET_CMS_MTD,0)) as 普通收入_大宗交易净佣金_月累计
	,sum(COALESCE(t_ptsr.BGDL_TRAN_FEE_MTD,0)) as 普通收入_大宗交易过户费_月累计
	,sum(COALESCE(t_ptsr.PSTK_OPTN_CMS_MTD,0)) as 普通收入_个股期权佣金_月累计
	,sum(COALESCE(t_ptsr.PSTK_OPTN_NET_CMS_MTD,0)) as 普通收入_个股期权净佣金_月累计
	,sum(COALESCE(t_ptsr.SCDY_CMS_MTD,0)) as 普通收入_二级佣金_月累计
	,sum(COALESCE(t_ptsr.SCDY_NET_CMS_MTD,0)) as 普通收入_二级净佣金_月累计
	,sum(COALESCE(t_ptsr.GROSS_CMS_YTD,0)) as 普通收入_毛佣金_年累计
	,sum(COALESCE(t_ptsr.TRAN_FEE_YTD,0)) as 普通收入_过户费_年累计
	,sum(COALESCE(t_ptsr.SCDY_TRAN_FEE_YTD,0)) as 普通收入_二级过户费_年累计
	,sum(COALESCE(t_ptsr.STP_TAX_YTD,0)) as 普通收入_印花税_年累计
	,sum(COALESCE(t_ptsr.HANDLE_FEE_YTD,0)) as 普通收入_经手费_年累计
	,sum(COALESCE(t_ptsr.SEC_RGLT_FEE_YTD,0)) as 普通收入_证管费_年累计
	,sum(COALESCE(t_ptsr.OTH_FEE_YTD,0)) as 普通收入_其他费用_年累计
	,sum(COALESCE(t_ptsr.STKF_CMS_YTD,0)) as 普通收入_股基佣金_年累计
	,sum(COALESCE(t_ptsr.STKF_TRAN_FEE_YTD,0)) as 普通收入_股基过户费_年累计
	,sum(COALESCE(t_ptsr.STKF_NET_CMS_YTD,0)) as 普通收入_股基净佣金_年累计
	,sum(COALESCE(t_ptsr.BOND_CMS_YTD,0)) as 普通收入_债券佣金_年累计
	,sum(COALESCE(t_ptsr.BOND_NET_CMS_YTD,0)) as 普通收入_债券净佣金_年累计
	,sum(COALESCE(t_ptsr.REPQ_CMS_YTD,0)) as 普通收入_报价回购佣金_年累计
	,sum(COALESCE(t_ptsr.REPQ_NET_CMS_YTD,0)) as 普通收入_报价回购净佣金_年累计
	,sum(COALESCE(t_ptsr.HGT_CMS_YTD,0)) as 普通收入_沪港通佣金_年累计
	,sum(COALESCE(t_ptsr.HGT_NET_CMS_YTD,0)) as 普通收入_沪港通净佣金_年累计
	,sum(COALESCE(t_ptsr.HGT_TRAN_FEE_YTD,0)) as 普通收入_沪港通过户费_年累计
	,sum(COALESCE(t_ptsr.SGT_CMS_YTD,0)) as 普通收入_深港通佣金_年累计
	,sum(COALESCE(t_ptsr.SGT_NET_CMS_YTD,0)) as 普通收入_深港通净佣金_年累计
	,sum(COALESCE(t_ptsr.SGT_TRAN_FEE_YTD,0)) as 普通收入_深港通过户费_年累计
	,sum(COALESCE(t_ptsr.BGDL_CMS_YTD,0)) as 普通收入_大宗交易佣金_年累计
	,sum(COALESCE(t_ptsr.NET_CMS_YTD,0)) as 普通收入_净佣金_年累计
	,sum(COALESCE(t_ptsr.BGDL_NET_CMS_YTD,0)) as 普通收入_大宗交易净佣金_年累计
	,sum(COALESCE(t_ptsr.BGDL_TRAN_FEE_YTD,0)) as 普通收入_大宗交易过户费_年累计
	,sum(COALESCE(t_ptsr.PSTK_OPTN_CMS_YTD,0)) as 普通收入_个股期权佣金_年累计
	,sum(COALESCE(t_ptsr.PSTK_OPTN_NET_CMS_YTD,0)) as 普通收入_个股期权净佣金_年累计
	,sum(COALESCE(t_ptsr.SCDY_CMS_YTD,0)) as 普通收入_二级佣金_年累计
	,sum(COALESCE(t_ptsr.SCDY_NET_CMS_YTD,0)) as 普通收入_二级净佣金_年累计
	
	--信用收入
	,sum(COALESCE(t_xysr.CREDIT_MARG_SPR_INCM_YTD,0)) as 信用收入_融资融券保证金利差收入_年累计
	,sum(COALESCE(t_xysr.CREDIT_MARG_SPR_INCM_MTD,0)) as 信用收入_融资融券保证金利差收入_月累计
	,sum(COALESCE(t_xysr.GROSS_CMS_MTD,0)) as 信用收入_毛佣金_月累计
	,sum(COALESCE(t_xysr.NET_CMS_MTD,0)) as 信用收入_净佣金_月累计
	,sum(COALESCE(t_xysr.TRAN_FEE_MTD,0)) as 信用收入_过户费_月累计
	,sum(COALESCE(t_xysr.STP_TAX_MTD,0)) as 信用收入_印花税_月累计
	,sum(COALESCE(t_xysr.ORDR_FEE_MTD,0)) as 信用收入_委托费_月累计
	,sum(COALESCE(t_xysr.HANDLE_FEE_MTD,0)) as 信用收入_经手费_月累计
	,sum(COALESCE(t_xysr.SEC_RGLT_FEE_MTD,0)) as 信用收入_证管费_月累计
	,sum(COALESCE(t_xysr.OTH_FEE_MTD,0)) as 信用收入_其他费用_月累计
	,sum(COALESCE(t_xysr.CREDIT_ODI_CMS_MTD,0)) as 信用收入_融资融券普通佣金_月累计
	,sum(COALESCE(t_xysr.CREDIT_ODI_NET_CMS_MTD,0)) as 信用收入_融资融券普通净佣金_月累计
	,sum(COALESCE(t_xysr.CREDIT_ODI_TRAN_FEE_MTD,0)) as 信用收入_融资融券普通过户费_月累计
	,sum(COALESCE(t_xysr.CREDIT_CRED_CMS_MTD,0)) as 信用收入_融资融券信用佣金_月累计
	,sum(COALESCE(t_xysr.CREDIT_CRED_NET_CMS_MTD,0)) as 信用收入_融资融券信用净佣金_月累计
	,sum(COALESCE(t_xysr.CREDIT_CRED_TRAN_FEE_MTD,0)) as 信用收入_融资融券信用过户费_月累计
	,sum(COALESCE(t_xysr.STKPLG_CMS_MTD,0)) as 信用收入_股票质押佣金_月累计
	,sum(COALESCE(t_xysr.STKPLG_NET_CMS_MTD,0)) as 信用收入_股票质押净佣金_月累计
	,sum(COALESCE(t_xysr.STKPLG_PAIDINT_MTD,0)) as 信用收入_股票质押实收利息_月累计
	,sum(COALESCE(t_xysr.STKPLG_RECE_INT_MTD,0)) as 信用收入_股票质押应收利息_月累计
	,sum(COALESCE(t_xysr.APPTBUYB_CMS_MTD,0)) as 信用收入_约定购回佣金_月累计
	,sum(COALESCE(t_xysr.APPTBUYB_NET_CMS_MTD,0)) as 信用收入_约定购回净佣金_月累计
	,sum(COALESCE(t_xysr.APPTBUYB_PAIDINT_MTD,0)) as 信用收入_约定购回实收利息_月累计
	,sum(COALESCE(t_xysr.FIN_PAIDINT_MTD,0)) as 信用收入_融资实收利息_月累计
	,sum(COALESCE(t_xysr.FIN_IE_MTD,0)) as 信用收入_融资利息支出_月累计
	,sum(COALESCE(t_xysr.CRDT_STK_IE_MTD,0)) as 信用收入_融券利息支出_月累计
	,sum(COALESCE(t_xysr.OTH_IE_MTD,0)) as 信用收入_其他利息支出_月累计
	,sum(COALESCE(t_xysr.FIN_RECE_INT_MTD,0)) as 信用收入_融资应收利息_月累计
	,sum(COALESCE(t_xysr.FEE_RECE_INT_MTD,0)) as 信用收入_费用应收利息_月累计
	,sum(COALESCE(t_xysr.OTH_RECE_INT_MTD,0)) as 信用收入_其他应收利息_月累计
	,sum(COALESCE(t_xysr.CREDIT_CPTL_COST_MTD,0)) as 信用收入_融资融券资金成本_月累计
	,sum(COALESCE(t_xysr.GROSS_CMS_YTD,0)) as 信用收入_毛佣金_年累计
	,sum(COALESCE(t_xysr.NET_CMS_YTD,0)) as 信用收入_净佣金_年累计
	,sum(COALESCE(t_xysr.TRAN_FEE_YTD,0)) as 信用收入_过户费_年累计
	,sum(COALESCE(t_xysr.STP_TAX_YTD,0)) as 信用收入_印花税_年累计
	,sum(COALESCE(t_xysr.ORDR_FEE_YTD,0)) as 信用收入_委托费_年累计
	,sum(COALESCE(t_xysr.HANDLE_FEE_YTD,0)) as 信用收入_经手费_年累计
	,sum(COALESCE(t_xysr.SEC_RGLT_FEE_YTD,0)) as 信用收入_证管费_年累计
	,sum(COALESCE(t_xysr.OTH_FEE_YTD,0)) as 信用收入_其他费用_年累计
	,sum(COALESCE(t_xysr.CREDIT_ODI_CMS_YTD,0)) as 信用收入_融资融券普通佣金_年累计
	,sum(COALESCE(t_xysr.CREDIT_ODI_NET_CMS_YTD,0)) as 信用收入_融资融券普通净佣金_年累计
	,sum(COALESCE(t_xysr.CREDIT_ODI_TRAN_FEE_YTD,0)) as 信用收入_融资融券普通过户费_年累计
	,sum(COALESCE(t_xysr.CREDIT_CRED_CMS_YTD,0)) as 信用收入_融资融券信用佣金_年累计
	,sum(COALESCE(t_xysr.CREDIT_CRED_NET_CMS_YTD,0)) as 信用收入_融资融券信用净佣金_年累计
	,sum(COALESCE(t_xysr.CREDIT_CRED_TRAN_FEE_YTD,0)) as 信用收入_融资融券信用过户费_年累计
	,sum(COALESCE(t_xysr.STKPLG_CMS_YTD,0)) as 信用收入_股票质押佣金_年累计
	,sum(COALESCE(t_xysr.STKPLG_NET_CMS_YTD,0)) as 信用收入_股票质押净佣金_年累计
	,sum(COALESCE(t_xysr.STKPLG_PAIDINT_YTD,0)) as 信用收入_股票质押实收利息_年累计
	,sum(COALESCE(t_xysr.STKPLG_RECE_INT_YTD,0)) as 信用收入_股票质押应收利息_年累计
	,sum(COALESCE(t_xysr.APPTBUYB_CMS_YTD,0)) as 信用收入_约定购回佣金_年累计
	,sum(COALESCE(t_xysr.APPTBUYB_NET_CMS_YTD,0)) as 信用收入_约定购回净佣金_年累计
	,sum(COALESCE(t_xysr.APPTBUYB_PAIDINT_YTD,0)) as 信用收入_约定购回实收利息_年累计
	,sum(COALESCE(t_xysr.FIN_PAIDINT_YTD,0)) as 信用收入_融资实收利息_年累计
	,sum(COALESCE(t_xysr.FIN_IE_YTD,0)) as 信用收入_融资利息支出_年累计
	,sum(COALESCE(t_xysr.CRDT_STK_IE_YTD,0)) as 信用收入_融券利息支出_年累计
	,sum(COALESCE(t_xysr.OTH_IE_YTD,0)) as 信用收入_其他利息支出_年累计
	,sum(COALESCE(t_xysr.FIN_RECE_INT_YTD,0)) as 信用收入_融资应收利息_年累计
	,sum(COALESCE(t_xysr.FEE_RECE_INT_YTD,0)) as 信用收入_费用应收利息_年累计
	,sum(COALESCE(t_xysr.OTH_RECE_INT_YTD,0)) as 信用收入_其他应收利息_年累计
	,sum(COALESCE(t_xysr.CREDIT_CPTL_COST_YTD,0)) as 信用收入_融资融券资金成本_年累计	
	
	--约定购回
	,sum(COALESCE(t_ydgh.GUAR_SECU_MVAL_FINAL,0)) as 约定购回_担保证券市值_期末
	,sum(COALESCE(t_ydgh.APPTBUYB_BAL_FINAL,0)) as 约定购回_约定购回余额_期末
	,sum(COALESCE(t_ydgh.SH_GUAR_SECU_MVAL_FINAL,0)) as 约定购回_上海担保证券市值_期末
	,sum(COALESCE(t_ydgh.SZ_GUAR_SECU_MVAL_FINAL,0)) as 约定购回_深圳担保证券市值_期末
	,sum(COALESCE(t_ydgh.SH_NOTS_GUAR_SECU_MVAL_FINAL,0)) as 约定购回_上海限售股担保证券市值_期末
	,sum(COALESCE(t_ydgh.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0)) as 约定购回_深圳限售股担保证券市值_期末
	,sum(COALESCE(t_ydgh.PROP_FINAC_OUT_SIDE_BAL_FINAL,0)) as 约定购回_自营融出方余额_期末
	,sum(COALESCE(t_ydgh.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0)) as 约定购回_资管融出方余额_期末
	,sum(COALESCE(t_ydgh.SM_LOAN_FINAC_OUT_BAL_FINAL,0)) as 约定购回_小额贷融出余额_期末
	,sum(COALESCE(t_ydgh.GUAR_SECU_MVAL_MDA,0)) as 约定购回_担保证券市值_月日均
	,sum(COALESCE(t_ydgh.APPTBUYB_BAL_MDA,0)) as 约定购回_约定购回余额_月日均
	,sum(COALESCE(t_ydgh.SH_GUAR_SECU_MVAL_MDA,0)) as 约定购回_上海担保证券市值_月日均
	,sum(COALESCE(t_ydgh.SZ_GUAR_SECU_MVAL_MDA,0)) as 约定购回_深圳担保证券市值_月日均
	,sum(COALESCE(t_ydgh.SH_NOTS_GUAR_SECU_MVAL_MDA,0)) as 约定购回_上海限售股担保证券市值_月日均
	,sum(COALESCE(t_ydgh.SZ_NOTS_GUAR_SECU_MVAL_MDA,0)) as 约定购回_深圳限售股担保证券市值_月日均
	,sum(COALESCE(t_ydgh.PROP_FINAC_OUT_SIDE_BAL_MDA,0)) as 约定购回_自营融出方余额_月日均
	,sum(COALESCE(t_ydgh.ASSM_FINAC_OUT_SIDE_BAL_MDA,0)) as 约定购回_资管融出方余额_月日均
	,sum(COALESCE(t_ydgh.SM_LOAN_FINAC_OUT_BAL_MDA,0)) as 约定购回_小额贷融出余额_月日均
	,sum(COALESCE(t_ydgh.GUAR_SECU_MVAL_YDA,0)) as 约定购回_担保证券市值_年日均
	,sum(COALESCE(t_ydgh.APPTBUYB_BAL_YDA,0)) as 约定购回_约定购回余额_年日均
	,sum(COALESCE(t_ydgh.SH_GUAR_SECU_MVAL_YDA,0)) as 约定购回_上海担保证券市值_年日均
	,sum(COALESCE(t_ydgh.SZ_GUAR_SECU_MVAL_YDA,0)) as 约定购回_深圳担保证券市值_年日均
	,sum(COALESCE(t_ydgh.SH_NOTS_GUAR_SECU_MVAL_YDA,0)) as 约定购回_上海限售股担保证券市值_年日均
	,sum(COALESCE(t_ydgh.SZ_NOTS_GUAR_SECU_MVAL_YDA,0)) as 约定购回_深圳限售股担保证券市值_年日均
	,sum(COALESCE(t_ydgh.PROP_FINAC_OUT_SIDE_BAL_YDA,0)) as 约定购回_自营融出方余额_年日均
	,sum(COALESCE(t_ydgh.ASSM_FINAC_OUT_SIDE_BAL_YDA,0)) as 约定购回_资管融出方余额_年日均
	,sum(COALESCE(t_ydgh.SM_LOAN_FINAC_OUT_BAL_YDA,0)) as 约定购回_小额贷融出余额_年日均
	
	--股票质押
	,sum(COALESCE(t_gpzy.GUAR_SECU_MVAL_FINAL,0)) as 股票质押_担保证券市值_期末
	,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_FINAL,0)) as 股票质押_股票质押融资余额_期末
	,sum(COALESCE(t_gpzy.SH_GUAR_SECU_MVAL_FINAL,0)) as 股票质押_上海担保证券市值_期末
	,sum(COALESCE(t_gpzy.SZ_GUAR_SECU_MVAL_FINAL,0)) as 股票质押_深圳担保证券市值_期末
	,sum(COALESCE(t_gpzy.SH_NOTS_GUAR_SECU_MVAL_FINAL,0)) as 股票质押_上海限售股担保证券市值_期末
	,sum(COALESCE(t_gpzy.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0)) as 股票质押_深圳限售股担保证券市值_期末
	,sum(COALESCE(t_gpzy.PROP_FINAC_OUT_SIDE_BAL_FINAL,0)) as 股票质押_自营融出方余额_期末
	,sum(COALESCE(t_gpzy.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0)) as 股票质押_资管融出方余额_期末
	,sum(COALESCE(t_gpzy.SM_LOAN_FINAC_OUT_BAL_FINAL,0)) as 股票质押_小额贷融出余额_期末
	,sum(COALESCE(t_gpzy.GUAR_SECU_MVAL_MDA,0)) as 股票质押_担保证券市值_月日均
	,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_MDA,0)) as 股票质押_股票质押融资余额_月日均
	,sum(COALESCE(t_gpzy.SH_GUAR_SECU_MVAL_MDA,0)) as 股票质押_上海担保证券市值_月日均
	,sum(COALESCE(t_gpzy.SZ_GUAR_SECU_MVAL_MDA,0)) as 股票质押_深圳担保证券市值_月日均
	,sum(COALESCE(t_gpzy.SH_NOTS_GUAR_SECU_MVAL_MDA,0)) as 股票质押_上海限售股担保证券市值_月日均
	,sum(COALESCE(t_gpzy.SZ_NOTS_GUAR_SECU_MVAL_MDA,0)) as 股票质押_深圳限售股担保证券市值_月日均
	,sum(COALESCE(t_gpzy.PROP_FINAC_OUT_SIDE_BAL_MDA,0)) as 股票质押_自营融出方余额_月日均
	,sum(COALESCE(t_gpzy.ASSM_FINAC_OUT_SIDE_BAL_MDA,0)) as 股票质押_资管融出方余额_月日均
	,sum(COALESCE(t_gpzy.SM_LOAN_FINAC_OUT_BAL_MDA,0)) as 股票质押_小额贷融出余额_月日均
	,sum(COALESCE(t_gpzy.GUAR_SECU_MVAL_YDA,0)) as 股票质押_担保证券市值_年日均
	,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_YDA,0)) as 股票质押_股票质押融资余额_年日均
	,sum(COALESCE(t_gpzy.SH_GUAR_SECU_MVAL_YDA,0)) as 股票质押_上海担保证券市值_年日均
	,sum(COALESCE(t_gpzy.SZ_GUAR_SECU_MVAL_YDA,0)) as 股票质押_深圳担保证券市值_年日均
	,sum(COALESCE(t_gpzy.SH_NOTS_GUAR_SECU_MVAL_YDA,0)) as 股票质押_上海限售股担保证券市值_年日均
	,sum(COALESCE(t_gpzy.SZ_NOTS_GUAR_SECU_MVAL_YDA,0)) as 股票质押_深圳限售股担保证券市值_年日均
	,sum(COALESCE(t_gpzy.PROP_FINAC_OUT_SIDE_BAL_YDA,0)) as 股票质押_自营融出方余额_年日均
	,sum(COALESCE(t_gpzy.ASSM_FINAC_OUT_SIDE_BAL_YDA,0)) as 股票质押_资管融出方余额_年日均
	,sum(COALESCE(t_gpzy.SM_LOAN_FINAC_OUT_BAL_YDA,0)) as 股票质押_小额贷融出余额_年日均
	
	--普通交易
	,sum(COALESCE(t_ptjy.SCDY_TRD_FREQ_MTD,0)) as 普通交易_二级交易次数
	,sum(COALESCE(t_ptjy.SCDY_TRD_QTY_MTD,0)) as 普通交易_二级交易量
	,sum(COALESCE(t_ptjy.SCDY_TRD_QTY_YTD,0)) as 普通交易_二级交易量_本年
	,sum(COALESCE(t_ptjy.TRD_FREQ_MTD,0)) as 普通交易_交易次数_本年
	,sum(COALESCE(t_ptjy.STKF_TRD_QTY_MTD,0)) as 普通交易_股基交易量
	,sum(COALESCE(t_ptjy.STKF_TRD_QTY_YTD,0)) as 普通交易_股基交易量_本年
	,sum(COALESCE(t_ptjy.S_REPUR_TRD_QTY_MTD,0)) as 普通交易_正回购交易量
	,sum(COALESCE(t_ptjy.R_REPUR_TRD_QTY_MTD,0)) as 普通交易_逆回购交易量
	,sum(COALESCE(t_ptjy.S_REPUR_TRD_QTY_YTD,0)) as 普通交易_正回购交易量_本年
	,sum(COALESCE(t_ptjy.R_REPUR_TRD_QTY_YTD,0)) as 普通交易_逆回购交易量_本年
	,sum(COALESCE(t_ptjy.HGT_TRD_QTY_MTD,0)) as 普通交易_沪港通交易量
	,sum(COALESCE(t_ptjy.SGT_TRD_QTY_MTD,0)) as 普通交易_深港通交易量
	,sum(COALESCE(t_ptjy.SGT_TRD_QTY_YTD,0)) as 普通交易_深港通交易量_本年
	,sum(COALESCE(t_ptjy.HGT_TRD_QTY_YTD,0)) as 普通交易_沪港通交易量_本年
	,sum(COALESCE(t_ptjy.Y_RCT_STK_TRD_QTY,0)) as 普通交易_近12月股票交易量
	,sum(COALESCE(t_ptjy.SCDY_TRD_FREQ_YTD,0)) as 普通交易_二级交易次数_本年
	,sum(COALESCE(t_ptjy.TRD_FREQ_MTD,0)) as 普通交易_交易次数
	,sum(COALESCE(t_ptjy.APPTBUYB_TRD_QTY_MTD,0)) as 普通交易_约定购回交易量
	,sum(COALESCE(t_ptjy.APPTBUYB_TRD_QTY_YTD,0)) as 普通交易_约定购回交易量_本年
	,sum(COALESCE(t_ptjy.RCT_TRD_DT_M,0)) as 普通交易_最近交易日期_本月
	,sum(COALESCE(t_ptjy.STKPLG_TRD_QTY_MTD,0)) as 普通交易_股票质押交易量
	,sum(COALESCE(t_ptjy.STKPLG_TRD_QTY_YTD,0)) as 普通交易_股票质押交易量_本年
	,sum(COALESCE(t_ptjy.PSTK_OPTN_TRD_QTY_MTD,0)) as 普通交易_个股期权交易量
	,sum(COALESCE(t_ptjy.PSTK_OPTN_TRD_QTY_YTD,0)) as 普通交易_个股期权交易量_本年
	,sum(COALESCE(t_ptjy.REPQ_TRD_QTY_MTD,0)) as 普通交易_报价回购交易量
	,sum(COALESCE(t_ptjy.REPQ_TRD_QTY_YTD,0)) as 普通交易_报价回购交易量_本年
	,sum(COALESCE(t_ptjy.BGDL_QTY_MTD,0)) as 普通交易_大宗交易量
	,sum(COALESCE(t_ptjy.BGDL_QTY_YTD,0)) as 普通交易_大宗交易量_本年
	
	,sum(COALESCE(t_khsx.融资融券授信额度,0)*t2.PERFM_RATI9) as 融资融券授信额度
	,sum(COALESCE(t_khsx.约定购回授信额度,0)*t2.PERFM_RATI9) as 约定购回授信额度
	,sum(COALESCE(t_khsx.股票质押授信额度,0)*t2.PERFM_RATI9) as 股票质押授信额度
	,@V_BIN_DATE	

	,sum(COALESCE(t_ptjy.SB_TRD_QTY_MTD,0))        			as 三板交易量_本月
	,sum(COALESCE(t_ptjy.SB_TRD_QTY_YTD,0))        			as 三板交易量_本年
	,sum(COALESCE(t_ptjy.BOND_TRD_QTY_MTD,0))      			as 债券交易量_本月
	,sum(COALESCE(t_ptjy.BOND_TRD_QTY_YTD,0))      			as 债券交易量_本年
	,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_TRD_QTY_MTD,0)) 		as 场内货币基金交易量_本月
	,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_TRD_QTY_YTD,0)) 		as 场内货币基金交易量_本年
	,sum(COALESCE(t_ptjy.S_REPUR_NET_CMS_MTD,0))   			as 正回购净佣金_本月
	,sum(COALESCE(t_ptjy.S_REPUR_NET_CMS_YTD,0))   			as 正回购净佣金_本年
	,sum(COALESCE(t_ptjy.R_REPUR_NET_CMS_MTD,0))   			as 逆回购净佣金_本月
	,sum(COALESCE(t_ptjy.R_REPUR_NET_CMS_YTD,0))   			as 逆回购净佣金_本年
	,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_NET_CMS_MTD,0)) 		as 场内货币基金净佣金_本月
	,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_NET_CMS_YTD,0)) 		as 场内货币基金净佣金_本年
from DM.T_AST_EMPCUS_ODI_M_D t1					--员工客户普通资产
left join DM.T_PUB_ORG t_jg					--机构表
	on t1.YEAR=t_jg.YEAR and t1.MTH=t_jg.MTH and t1.WH_ORG_ID_EMP=t_jg.WH_ORG_ID
--20180427修改增加责权表
left join DM.T_PUB_SER_RELA t2
	on t1.year=t2.year 
		and t1.mth=t2.mth 
		and t2.hs_cust_id=t1.cust_id 
		and t2.afa_sec_empid=t2.afa_sec_empid
left join 
(											--客户属性和维度处理
	select 
		t1.YEAR
		,t1.MTH	
		,t1.CUST_ID
		,t1.CUST_STAT_NAME as 客户状态
		,case when t1.TE_OACT_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as 是否月新增
		,case when t1.TE_OACT_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as 是否年新增
		,t1.IF_VLD as 是否有效
		,t4.IF_SPCA_ACCT as 是否特殊账户
		,t1.IF_PROD_NEW_CUST as 是否产品新客户
		,t1.CUST_TYPE_NAME as 客户类型
		
		,t3.IF_CREDIT_CUST as 是否融资融券客户
		,t3.IF_CREDIT_EFF_CUST as 是否融资融券有效客户		
		,case when t3.IF_CREDIT_CUST=1 and t3.CREDIT_OPEN_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as 是否融资融券月新增
		,case when t3.IF_CREDIT_CUST=1 and t3.CREDIT_OPEN_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as 是否融资融券年新增		
		,case when t3.IF_CREDIT_CUST=1 and t3.CREDIT_EFF_ACT_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as 是否融资融券月新增有效户
		,case when t3.IF_CREDIT_CUST=1 and t3.CREDIT_EFF_ACT_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as 是否融资融券年新增有效户
		
		,t3.CREDIT_CRED_QUO as 融资融券授信额度
		,t3.APPTBUYB_CRED_QUO as 约定购回授信额度		
		,t3.STKPLG_CRED_QUO as 股票质押授信额度
		
		,case when t5.TOT_AST_MDA<100000 then '0-小于10w'
			when t5.TOT_AST_MDA >= 100000 and t5.TOT_AST_MDA<200000 then '1-10w_20w'
			when t5.TOT_AST_MDA >= 200000 and t5.TOT_AST_MDA<500000 then '2-20w_50w'
			when t5.TOT_AST_MDA >= 500000 and t5.TOT_AST_MDA<1000000 then '3-50w_100w'
			when t5.TOT_AST_MDA >= 1000000 and t5.TOT_AST_MDA<2000000 then '4-100w_200w'
			when t5.TOT_AST_MDA >= 2000000 and t5.TOT_AST_MDA<3000000 then '5-200w_300w'
			when t5.TOT_AST_MDA >= 3000000 and t5.TOT_AST_MDA<5000000 then '6-300w_500w'
			when t5.TOT_AST_MDA >= 5000000 and t5.TOT_AST_MDA<10000000 then '7-500w_1000w'
			when t5.TOT_AST_MDA >= 10000000 and t5.TOT_AST_MDA<30000000 then '8-1000w_3000w'
			when t5.TOT_AST_MDA >= 30000000 then '9-大于3000w'
			else '0-小于10w' end as 资产段		
	 from DM.T_PUB_CUST t1	 
	 left join DM.T_PUB_DATE_M t2 on t1.YEAR=t2.YEAR and t1.MTH=t2.MTH
	 left join DM.T_PUB_CUST_LIMIT_M_D t3 on t1.YEAR=t3.YEAR and t1.MTH=t3.MTH and t1.CUST_ID=t3.CUST_ID
	 left join DM.T_ACC_CPTL_ACC t4 on t1.YEAR=t4.YEAR and t1.MTH=t4.MTH and t1.MAIN_CPTL_ACCT=t4.CPTL_ACCT
	 left join DM.T_AST_ODI_M_D t5 on t1.YEAR=t5.YEAR and t1.MTH=t5.MTH and t1.CUST_ID=t5.CUST_ID
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
group by
	t1.YEAR
	,t1.MTH
	,t_jg.WH_ORG_ID	
	
	--维度信息
	,t_khsx.客户状态
	,t_khsx.是否特殊账户
	,t_khsx.是否产品新客户
	,t_khsx.是否月新增
	,t_khsx.是否年新增	
	,t_khsx.是否融资融券客户
	,t_khsx.是否融资融券月新增
	,t_khsx.是否融资融券年新增
	,t_khsx.是否融资融券有效客户
	,t_khsx.是否融资融券月新增有效户
	,t_khsx.是否融资融券年新增有效户
	,t_khsx.资产段
	,t_khsx.客户类型;


END
