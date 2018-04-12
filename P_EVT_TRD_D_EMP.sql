CREATE PROCEDURE DM.P_EVT_TRD_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工普通交易事实表（月存储日更新）
  编写者: 叶宏冰
  创建日期: 2018-03-28
  简介：普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_TRD_D_EMP WHERE OCCUR_DT = @V_DATE;

	-- 1.1 在T_EVT_TRD_D_EMP的基础上增加资金账号字段来创建临时表（为了取责权分配后的金额然后再根据员工维度汇总分配后的金额）

	CREATE TABLE #TMP_T_EVT_TRD_D_EMP(
	    OCCUR_DT             numeric(8,0) NOT NULL,
		EMP_ID               varchar(30) NOT NULL,
		MAIN_CPTL_ACCT		 varchar(30) NOT NULL,
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

	INSERT INTO #TMP_T_EVT_TRD_D_EMP(
		 OCCUR_DT					
		,EMP_ID						
		,MAIN_CPTL_ACCT
	)			
	SELECT 
		 @V_DATE AS OCCUR_DT			--发生日期
		,A.AFATWO_YGH AS EMP_ID			--员工编码
		,A.ZJZH AS MAIN_CPTL_ACCT		--资金账号
	FROM DBA.T_DDW_SERV_RELATION_D A
	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  		   ,A.ZJZH;

	-- 基于责权分配表统计（员工-客户）绩效分配比例

  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH;

	--更新分配后的各项指标
	UPDATE #TMP_T_EVT_TRD_D_EMP
		SET 
			 STKF_TRD_QTY = COALESCE(B.STKF_TRD_QTY,0)					* C.PERFM_RATIO_3		--股基交易量		
			,SCDY_TRD_QTY = COALESCE(B.SCDY_TRD_QTY,0)					* C.PERFM_RATIO_3		--二级交易量				
			,S_REPUR_TRD_QTY = COALESCE(B.S_REPUR_TRD_QTY,0)			* C.PERFM_RATIO_3		--正回购交易量						
			,R_REPUR_TRD_QTY = COALESCE(B.R_REPUR_TRD_QTY,0)			* C.PERFM_RATIO_3		--逆回购交易量						
			,HGT_TRD_QTY = COALESCE(B.HGT_TRD_QTY,0)					* C.PERFM_RATIO_3		--沪港通交易量				
			,SGT_TRD_QTY = COALESCE(B.SGT_TRD_QTY,0)					* C.PERFM_RATIO_3		--深港通交易量				
			,STKPLG_TRD_QTY = COALESCE(B.STKPLG_TRD_QTY,0)				* C.PERFM_RATIO_3		--股票质押交易量				
			,APPTBUYB_TRD_QTY = COALESCE(B.APPTBUYB_TRD_QTY,0)			* C.PERFM_RATIO_3		--约定购回交易量								
			,OFFUND_TRD_QTY = COALESCE(B.OFFUND_TRD_QTY,0)				* C.PERFM_RATIO_3		--场内基金交易量							
			,OPFUND_TRD_QTY = COALESCE(B.OPFUND_TRD_QTY,0)				* C.PERFM_RATIO_3		--场外基金交易量							
			,BANK_CHRM_TRD_QTY = COALESCE(B.BANK_CHRM_TRD_QTY,0)		* C.PERFM_RATIO_3		--银行理财交易量									
			,SECU_CHRM_TRD_QTY = COALESCE(B.SECU_CHRM_TRD_QTY,0)		* C.PERFM_RATIO_3		--证券理财交易量									
			,PSTK_OPTN_TRD_QTY = COALESCE(B.PSTK_OPTN_TRD_QTY,0)		* C.PERFM_RATIO_3		--个股期权交易量									
			,CREDIT_ODI_TRD_QTY = COALESCE(B.CREDIT_ODI_TRD_QTY,0)		* C.PERFM_RATIO_3		--信用账户普通交易量									
			,CREDIT_CRED_TRD_QTY = COALESCE(B.CREDIT_CRED_TRD_QTY,0)	* C.PERFM_RATIO_3		--信用账户信用交易量										
			,CCB_AMT = COALESCE(B.CCB_AMT,0)							* C.PERFM_RATIO_3		--融资买入金额				
			,FIN_SELL_AMT = COALESCE(B.FIN_SELL_AMT,0)					* C.PERFM_RATIO_3		--融资卖出金额						
			,CRDT_STK_BUYIN_AMT = COALESCE(B.CRDT_STK_BUYIN_AMT,0)		* C.PERFM_RATIO_3		--融券买入金额									
			,CSS_AMT = COALESCE(B.CSS_AMT,0)							* C.PERFM_RATIO_3		--融券卖出金额				
			,FIN_RTN_AMT = COALESCE(B.FIN_RTN_AMT,0)					* C.PERFM_RATIO_3		--融资归还金额						
			,STKPLG_INIT_TRD_AMT = COALESCE(B.STKPLG_INIT_TRD_AMT,0)		* C.PERFM_RATIO_3	--股票质押初始交易金额 							
			,STKPLG_BUYB_TRD_AMT = COALESCE(B.STKPLG_BUYB_TRD_AMT,0)		* C.PERFM_RATIO_3	--股票质押购回交易金额 								
			,APPTBUYB_INIT_TRD_AMT = COALESCE(B.APPTBUYB_INIT_TRD_AMT,0)	* C.PERFM_RATIO_3	--约定购回初始交易金额 						
			,APPTBUYB_BUYB_TRD_AMT = COALESCE(B.APPTBUYB_BUYB_TRD_AMT,0)	* C.PERFM_RATIO_3	--约定购回购回交易金额 										
		FROM #TMP_T_EVT_TRD_D_EMP A
		LEFT JOIN (
				SELECT 
					T.MAIN_CPTL_ACCT	  			AS 		MAIN_CPTL_ACCT			--资金账号			
				   ,T.STKF_TRD_QTY  	  			AS 		STKF_TRD_QTY			--股基交易量	
				   ,T.SCDY_TRD_QTY  	  			AS 		SCDY_TRD_QTY			--二级交易量			
				   ,T.S_REPUR_TRD_QTY     			AS 		S_REPUR_TRD_QTY			--正回购交易量				
				   ,T.R_REPUR_TRD_QTY     			AS 		R_REPUR_TRD_QTY			--逆回购交易量				
				   ,T.HGT_TRD_QTY  		  			AS 		HGT_TRD_QTY 			--沪港通交易量				
				   ,T.SGT_TRD_QTY  		  			AS 		SGT_TRD_QTY				--深港通交易量				
				   ,T.STKPLG_TRD_QTY 	  			AS      STKPLG_TRD_QTY 			--股票质押交易量				
				   ,T.APPTBUYB_TRD_QTY    			AS      APPTBUYB_TRD_QTY		--约定购回交易量
				   ,T.OFFUND_TRD_QTY	  			AS 	    OFFUND_TRD_QTY			--场内基金交易量
				   ,T.OPFUND_TRD_QTY	  			AS		OPFUND_TRD_QTY			--场外基金交易量
				   ,T.BANK_CHRM_TRD_QTY   			AS		BANK_CHRM_TRD_QTY		--银行理财交易量
				   ,T.SECU_CHRM_TRD_QTY	  			AS 		SECU_CHRM_TRD_QTY		--证券理财交易量
				   ,T.PSTK_OPTN_TRD_QTY   			AS 		PSTK_OPTN_TRD_QTY		--个股期权交易量
				   ,T.CREDIT_ODI_TRD_QTY  			AS	    CREDIT_ODI_TRD_QTY		--信用账户普通交易量
				   ,T.CREDIT_CRED_TRD_QTY 			AS      CREDIT_CRED_TRD_QTY     --信用账户信用交易量
				   ,0								AS		COVR_BUYIN_AMT			--平仓买入金额
				   ,0								AS 		COVR_SELL_AMT			--平仓卖出金额
				   ,T.CCB_AMT			  			AS      CCB_AMT                 --融资买入金额
				   ,T.FIN_SELL_AMT        			AS  	FIN_SELL_AMT         	--融资卖出金额
				   ,T.CRDT_STK_BUYIN_AMT  			AS      CRDT_STK_BUYIN_AMT   	--融券买入金额
				   ,T.CSS_AMT			  			AS      CSS_AMT              	--融券卖出金额
				   ,T.FIN_RTN_AMT         			AS      FIN_RTN_AMT          	--融资归还金额
				   ,T.STKPLG_TRD_QTY      			AS		STKPLG_INIT_TRD_AMT  	--股票质押初始交易金额 
				   ,T.STKPLG_BUYB_AMT     			AS 		STKPLG_BUYB_TRD_AMT  	--股票质押购回交易金额 
				   ,T.APPTBUYB_TRD_QTY    			AS		APPTBUYB_INIT_TRD_AMT	--约定购回初始交易金额 
				   ,T.APPTBUYB_TRD_AMT	  			AS		APPTBUYB_BUYB_TRD_AMT	--约定购回购回交易金额 						
				FROM DM.T_EVT_CUS_TRD_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B ON A.MAIN_CPTL_ACCT=B.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--将临时表的按员工维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_TRD_D_EMP (
			 OCCUR_DT             					--发生日期		
			,EMP_ID               					--员工编码			
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
			,EMP_ID							AS    EMP_ID                	--员工编码			
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
		FROM #TMP_T_EVT_TRD_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
