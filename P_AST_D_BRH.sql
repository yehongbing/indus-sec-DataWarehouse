CREATE PROCEDURE DM.P_AST_D_BRH(IN @V_DATE INT)
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
	WHERE T.OCCUR_DT = @V_DATE;
	
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
