CREATE PROCEDURE DM.P_AST_M_EMP(IN @V_DATE INT)
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

	DELETE FROM DM.T_AST_M_EMP WHERE YEAR = @V_YEAR AND MTH = @V_MONTH;

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
