CREATE PROCEDURE DM.P_EVT_TRD_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部普通交易事实表（月存储日更新）
  编写者: 叶宏冰
  创建日期: 2018-03-28
  简介：营业部维度普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_TRD_D_BRH WHERE OCCUR_DT = @V_DATE;

	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--员工编码
		,A.PK_ORG 		AS 		BRH_ID			--营业部编码
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	-- 在T_EVT_TRD_D_BRH的基础上增加营业部字段来创建临时表

	CREATE TABLE #TMP_T_EVT_TRD_D_BRH(
	    OCCUR_DT             numeric(8,0) NOT NULL,
		EMP_ID               varchar(30) NOT NULL,
		BRH_ID		 		 varchar(30) NOT NULL,
		STKF_TRD_QTY         numeric(38,8) NULL,
		SCDY_TRD_QTY         numeric(38,8) NULL,
		S_REPUR_TRD_QTY      numeric(38,8) NULL,
		R_REPUR_TRD_QTY      numeric(38,8) NULL,
		HGT_TRD_QTY          numeric(38,8) NULL,
		SGT_TRD_QTY          numeric(38,8) NULL,
		STKPLG_TRD_QTY       numeric(38,8) NULL,
		APPTBUYB_TRD_QTY     numeric(38,8) NULL,
		OFFUND_TRD_QTY       numeric(38,8) NULL,
		OPFUND_TRD_QTY       numeric(38,8) NULL,
		BANK_CHRM_TRD_QTY    numeric(38,8) NULL,
		SECU_CHRM_TRD_QTY    numeric(38,8) NULL,
		PSTK_OPTN_TRD_QTY    numeric(38,8) NULL,
		CREDIT_ODI_TRD_QTY   numeric(38,8) NULL,
		CREDIT_CRED_TRD_QTY  numeric(38,8) NULL,
		COVR_BUYIN_AMT       numeric(38,8) NULL,
		COVR_SELL_AMT        numeric(38,8) NULL,
		CCB_AMT              numeric(38,8) NULL,
		FIN_SELL_AMT         numeric(38,8) NULL,
		CRDT_STK_BUYIN_AMT   numeric(38,8) NULL,
		CSS_AMT              numeric(38,8) NULL,
		FIN_RTN_AMT          numeric(38,8) NULL,
		STKPLG_INIT_TRD_AMT  numeric(38,8) NULL,
		STKPLG_BUYB_TRD_AMT  numeric(38,8) NULL,
		APPTBUYB_INIT_TRD_AMT numeric(38,8) NULL,
		APPTBUYB_BUYB_TRD_AMT numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_TRD_D_BRH(
		 OCCUR_DT             			--发生日期		
		,EMP_ID               			--员工编码	
		,BRH_ID		 		 			--营业部编码		
		,STKF_TRD_QTY         			--股基交易量	
		,SCDY_TRD_QTY         			--二级交易量
		,S_REPUR_TRD_QTY      			--正回购交易量	
		,R_REPUR_TRD_QTY      			--逆回购交易量		
		,HGT_TRD_QTY          			--沪港通交易量	
		,SGT_TRD_QTY          			--深港通交易量	
		,STKPLG_TRD_QTY       			--股票质押交易量		
		,APPTBUYB_TRD_QTY     			--约定购回交易量
		,OFFUND_TRD_QTY       			--场内基金交易量 
		,OPFUND_TRD_QTY       			--场外基金交易量 
		,BANK_CHRM_TRD_QTY    			--银行理财交易量 
		,SECU_CHRM_TRD_QTY    			--证券理财交易量 
		,PSTK_OPTN_TRD_QTY    			--个股期权交易量	
		,CREDIT_ODI_TRD_QTY   			--信用账户普通交易量 
		,CREDIT_CRED_TRD_QTY  			--信用账户信用交易量 
		,COVR_BUYIN_AMT       			--平仓买入金额 ？
		,COVR_SELL_AMT        			--平仓卖出金额 ？
		,CCB_AMT              			--融资买入金额 
		,FIN_SELL_AMT         			--融资卖出金额 
		,CRDT_STK_BUYIN_AMT   			--融券买入金额 
		,CSS_AMT              			--融券卖出金额 
		,FIN_RTN_AMT          			--融资归还金额
		,STKPLG_INIT_TRD_AMT  			--股票质押初始交易金额
		,STKPLG_BUYB_TRD_AMT  			--股票质押购回交易金额
		,APPTBUYB_INIT_TRD_AMT			--约定购回初始交易金额
		,APPTBUYB_BUYB_TRD_AMT			--约定购回购回交易金额
	)
	SELECT 
		 T.OCCUR_DT             		AS 		OCCUR_DT              		--发生日期		
		,T.EMP_ID               		AS 		EMP_ID                		--员工编码	
		,T1.BRH_ID		 				AS 		BRH_ID		 		   		--营业部编码		
		,T.STKF_TRD_QTY         		AS 		STKF_TRD_QTY          		--股基交易量	
		,T.SCDY_TRD_QTY         		AS 		SCDY_TRD_QTY          		--二级交易量
		,T.S_REPUR_TRD_QTY      		AS 		S_REPUR_TRD_QTY       		--正回购交易量	
		,T.R_REPUR_TRD_QTY      		AS 		R_REPUR_TRD_QTY       		--逆回购交易量		
		,T.HGT_TRD_QTY          		AS 		HGT_TRD_QTY           		--沪港通交易量	
		,T.SGT_TRD_QTY          		AS 		SGT_TRD_QTY           		--深港通交易量	
		,T.STKPLG_TRD_QTY       		AS 		STKPLG_TRD_QTY        		--股票质押交易量		
		,T.APPTBUYB_TRD_QTY     		AS 		APPTBUYB_TRD_QTY      		--约定购回交易量
		,T.OFFUND_TRD_QTY       		AS 		OFFUND_TRD_QTY        		--场内基金交易量 
		,T.OPFUND_TRD_QTY       		AS 		OPFUND_TRD_QTY        		--场外基金交易量 
		,T.BANK_CHRM_TRD_QTY    		AS 		BANK_CHRM_TRD_QTY     		--银行理财交易量 
		,T.SECU_CHRM_TRD_QTY    		AS 		SECU_CHRM_TRD_QTY     		--证券理财交易量 
		,T.PSTK_OPTN_TRD_QTY    		AS 		PSTK_OPTN_TRD_QTY     		--个股期权交易量	
		,T.CREDIT_ODI_TRD_QTY   		AS 		CREDIT_ODI_TRD_QTY    		--信用账户普通交易量 
		,T.CREDIT_CRED_TRD_QTY  		AS 		CREDIT_CRED_TRD_QTY   		--信用账户信用交易量 
		,T.COVR_BUYIN_AMT       		AS 		COVR_BUYIN_AMT        		--平仓买入金额 ？
		,T.COVR_SELL_AMT        		AS 		COVR_SELL_AMT         		--平仓卖出金额 ？
		,T.CCB_AMT              		AS 		CCB_AMT               		--融资买入金额 
		,T.FIN_SELL_AMT         		AS 		FIN_SELL_AMT          		--融资卖出金额 
		,T.CRDT_STK_BUYIN_AMT   		AS 		CRDT_STK_BUYIN_AMT    		--融券买入金额 
		,T.CSS_AMT              		AS 		CSS_AMT               		--融券卖出金额 
		,T.FIN_RTN_AMT          		AS 		FIN_RTN_AMT           		--融资归还金额
		,T.STKPLG_INIT_TRD_AMT  		AS 		STKPLG_INIT_TRD_AMT   		--股票质押初始交易金额
		,T.STKPLG_BUYB_TRD_AMT  		AS 		STKPLG_BUYB_TRD_AMT   		--股票质押购回交易金额
		,T.APPTBUYB_INIT_TRD_AMT		AS 		APPTBUYB_INIT_TRD_AMT 		--约定购回初始交易金额
		,T.APPTBUYB_BUYB_TRD_AMT		AS 		APPTBUYB_BUYB_TRD_AMT 		--约定购回购回交易金额
	FROM DM.T_EVT_TRD_D_EMP T 
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE;


	--将临时表的按营业部维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_TRD_D_BRH (
			 OCCUR_DT             					--发生日期		
			,BRH_ID               					--营业部编码			
			,STKF_TRD_QTY         					--股基交易量	
			,SCDY_TRD_QTY         					--二级交易量
			,S_REPUR_TRD_QTY      					--正回购交易量	
			,R_REPUR_TRD_QTY      					--逆回购交易量		
			,HGT_TRD_QTY          					--沪港通交易量	
			,SGT_TRD_QTY          					--深港通交易量	
			,STKPLG_TRD_QTY       					--股票质押交易量		
			,APPTBUYB_TRD_QTY     					--约定购回交易量
			,OFFUND_TRD_QTY       					--场内基金交易量 
			,OPFUND_TRD_QTY       					--场外基金交易量 
			,BANK_CHRM_TRD_QTY    					--银行理财交易量 
			,SECU_CHRM_TRD_QTY    					--证券理财交易量 
			,PSTK_OPTN_TRD_QTY    					--个股期权交易量	
			,CREDIT_ODI_TRD_QTY   					--信用账户普通交易量 
			,CREDIT_CRED_TRD_QTY  					--信用账户信用交易量 
			,COVR_BUYIN_AMT       					--平仓买入金额 ？
			,COVR_SELL_AMT        					--平仓卖出金额 ？
			,CCB_AMT              					--融资买入金额 
			,FIN_SELL_AMT         					--融资卖出金额 
			,CRDT_STK_BUYIN_AMT   					--融券买入金额 
			,CSS_AMT              					--融券卖出金额 
			,FIN_RTN_AMT          					--融资归还金额
			,STKPLG_INIT_TRD_AMT  					--股票质押初始交易金额
			,STKPLG_BUYB_TRD_AMT  					--股票质押购回交易金额
			,APPTBUYB_INIT_TRD_AMT					--约定购回初始交易金额
			,APPTBUYB_BUYB_TRD_AMT					--约定购回购回交易金额
		)
		SELECT 
			 OCCUR_DT						AS    OCCUR_DT              	--发生日期		
			,BRH_ID							AS    BRH_ID                	--营业部编码			
			,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY          	--股基交易量	
			,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY          	--二级交易量
			,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY       	--正回购交易量	
			,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY       	--逆回购交易量		
			,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY           	--沪港通交易量	
			,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY           	--深港通交易量	
			,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY        	--股票质押交易量		
			,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY      	--约定购回交易量
			,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY        	--场内基金交易量 
			,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY        	--场外基金交易量 
			,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY     	--银行理财交易量 
			,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY     	--证券理财交易量 
			,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY     	--个股期权交易量	
			,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY    	--信用账户普通交易量 
			,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY   	--信用账户信用交易量 
			,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT        	--平仓买入金额 ？
			,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT         	--平仓卖出金额 ？
			,SUM(CCB_AMT)              		AS    CCB_AMT               	--融资买入金额 
			,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT          	--融资卖出金额 
			,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT    	--融券买入金额 
			,SUM(CSS_AMT)              		AS    CSS_AMT               	--融券卖出金额 
			,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT           	--融资归还金额
			,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT   	--股票质押初始交易金额
			,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT   	--股票质押购回交易金额
			,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT 	--约定购回初始交易金额
			,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT 	--约定购回购回交易金额
		FROM #TMP_T_EVT_TRD_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
