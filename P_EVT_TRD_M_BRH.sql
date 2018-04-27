CREATE PROCEDURE DM.P_EVT_TRD_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部普通交易事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-10
  简介：营业部普通二级交易（不含两融）的交易统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
 	DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_TRD_M_BRH WHERE YEAR = @V_YEAR AND MTH = @V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID							AS    BRH_ID                	--营业部编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_M          	--股基交易量_本月	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_M          	--二级交易量_本月
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_M       	--正回购交易量_本月	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_M       	--逆回购交易量_本月		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_M           	--沪港通交易量_本月	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_M           	--深港通交易量_本月	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_M        	--股票质押交易量_本月		
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_M      	--约定购回交易量_本月
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_M        	--场内基金交易量_本月 
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_M        	--场外基金交易量_本月 
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_M     	--银行理财交易量_本月 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_M     	--证券理财交易量_本月 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_M     	--个股期权交易量_本月	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_M    	--信用账户普通交易量_本月 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_M   	--信用账户信用交易量_本月 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_M        	--平仓买入金额_本月 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_M         	--平仓卖出金额_本月 
		,SUM(CCB_AMT)              		AS    CCB_AMT_M               	--融资买入金额_本月 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_M          	--融资卖出金额_本月 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_M    	--融券买入金额_本月 
		,SUM(CSS_AMT)              		AS    CSS_AMT_M               	--融券卖出金额_本月 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_M           	--融资归还金额_本月
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_M   	--股票质押初始交易金额_本月
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_M   	--股票质押购回交易金额_本月
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_M 	--约定购回初始交易金额_本月
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_M 	--约定购回购回交易金额_本月
	INTO #TMP_T_EVT_TRD_M_BRH_MTH
	FROM DM.T_EVT_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	-- 统计年指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID							AS    BRH_ID                	--营业部编码	
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_TY         	--股基交易量_本年	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_TY          	--二级交易量_本年	
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_TY       	--正回购交易量_本年	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_TY       	--逆回购交易量_本年		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_TY           	--沪港通交易量_本年	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_TY           	--深港通交易量_本年	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_TY        	--股票质押交易量_本年	
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_TY      	--约定购回交易量_本年
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_TY        	--场内基金交易量_本年
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_TY        	--场外基金交易量_本年
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_TY     	--银行理财交易量_本年 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_TY     	--证券理财交易量_本年 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_TY     	--个股期权交易量_本年	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_TY    	--信用账户普通交易量_本年 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_TY   	--信用账户信用交易量_本年 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_TY        	--平仓买入金额_本年 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_TY         	--平仓卖出金额_本年 
		,SUM(CCB_AMT)              		AS    CCB_AMT_TY               	--融资买入金额_本年 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_TY          	--融资卖出金额_本年 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_TY    	--融券买入金额_本年 
		,SUM(CSS_AMT)              		AS    CSS_AMT_TY               	--融券卖出金额_本年 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_TY           	--融资归还金额_本年
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_TY   	--股票质押初始交易金额_本年
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_TY   	--股票质押购回交易金额_本年
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_TY 	--约定购回初始交易金额_本年
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_TY 	--约定购回购回交易金额_本年
	INTO #TMP_T_EVT_TRD_M_BRH_YEAR
	FROM DM.T_EVT_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--插入目标表
	INSERT INTO DM.T_EVT_TRD_M_BRH(
		 YEAR                 								--年
		,MTH                  								--月		
		,BRH_ID												--营业部编码	
		,OCCUR_DT											--发生日期		
		,STKF_TRD_QTY_M										--股基交易量_本月	
		,STKF_TRD_QTY_TY									--股基交易量_本年	
		,SCDY_TRD_QTY_M										--二级交易量_本月	
		,SCDY_TRD_QTY_TY									--二级交易量_本年	
		,S_REPUR_TRD_QTY_M									--正回购交易量_本月		
		,S_REPUR_TRD_QTY_TY									--正回购交易量_本年		
		,R_REPUR_TRD_QTY_M									--逆回购交易量_本月			
		,R_REPUR_TRD_QTY_TY									--逆回购交易量_本年			
		,HGT_TRD_QTY_M										--沪港通交易量_本月	
		,HGT_TRD_QTY_TY										--沪港通交易量_本年		
		,SGT_TRD_QTY_M										--深港通交易量_本月	
		,SGT_TRD_QTY_TY										--深港通交易量_本年	
		,STKPLG_TRD_QTY_M									--股票质押交易量_本月			
		,STKPLG_TRD_QTY_TY									--股票质押交易量_本年		
		,APPTBUYB_TRD_QTY_M									--约定购回交易量_本月	
		,APPTBUYB_TRD_QTY_TY								--约定购回交易量_本年	
		,OFFUND_TRD_QTY_M									--场内基金交易量_本月	
		,OFFUND_TRD_QTY_TY									--场内基金交易量_本年	
		,OPFUND_TRD_QTY_M									--场外基金交易量_本月	
		,OPFUND_TRD_QTY_TY									--场外基金交易量_本年	
		,BANK_CHRM_TRD_QTY_M								--银行理财交易量_本月 	
		,BANK_CHRM_TRD_QTY_TY								--银行理财交易量_本年 		
		,SECU_CHRM_TRD_QTY_M								--证券理财交易量_本月	
		,SECU_CHRM_TRD_QTY_TY								--证券理财交易量_本年		
		,PSTK_OPTN_TRD_QTY_M								--个股期权交易量_本月		
		,PSTK_OPTN_TRD_QTY_TY								--个股期权交易量_本年			
		,CREDIT_ODI_TRD_QTY_M								--信用账户普通交易量_本月 		
		,CREDIT_ODI_TRD_QTY_TY								--信用账户普通交易量_本年 		
		,CREDIT_CRED_TRD_QTY_M								--信用账户信用交易量_本月 		
		,CREDIT_CRED_TRD_QTY_TY								--信用账户信用交易量_本年 		
		,COVR_BUYIN_AMT_M									--平仓买入金额_本月 	
		,COVR_BUYIN_AMT_TY									--平仓买入金额_本年 	
		,COVR_SELL_AMT_M									--平仓卖出金额_本月 
		,COVR_SELL_AMT_TY									--平仓卖出金额_本年 	
		,CCB_AMT_M											--融资买入金额_本月 
		,CCB_AMT_TY											--融资买入金额_本年 
		,FIN_SELL_AMT_M										--融资卖出金额_本月 
		,FIN_SELL_AMT_TY									--融资卖出金额_本年 
		,CRDT_STK_BUYIN_AMT_M								--融券买入金额_本月 		
		,CRDT_STK_BUYIN_AMT_TY								--融券买入金额_本年 		
		,CSS_AMT_M											--融券卖出金额_本月 
		,CSS_AMT_TY											--融券卖出金额_本年 
		,FIN_RTN_AMT_M        								--融资归还金额_本月		
		,FIN_RTN_AMT_TY       								--融资归还金额_本年		
		,STKPLG_INIT_TRD_AMT_M 								--股票质押初始交易金额_本月		
		,STKPLG_INIT_TRD_AMT_TY 							--股票质押初始交易金额_本年		
		,STKPLG_REPO_TRD_AMT_M								--股票质押购回交易金额_本月		
		,STKPLG_REPO_TRD_AMT_TY								--股票质押购回交易金额_本年		
		,APPTBUYB_INIT_TRD_AMT_M 							--约定购回初始交易金额_本月			
		,APPTBUYB_INIT_TRD_AMT_TY							--约定购回初始交易金额_本年			
		,APPTBUYB_BUYB_TRD_AMT_M							--约定购回购回交易金额_本月			
		,APPTBUYB_BUYB_TRD_AMT_TY							--约定购回购回交易金额_本年	
	)		
	SELECT 
		 T1.YEAR  							AS			YEAR                 								--年
		,T1.MTH 						    AS			MTH                  								--月		
		,T1.BRH_ID							AS			BRH_ID												--营业部编码	
		,T1.OCCUR_DT 						AS			OCCUR_DT											--发生日期		
		,T1.STKF_TRD_QTY_M        	 		AS			STKF_TRD_QTY_M										--股基交易量_本月	
		,T2.STKF_TRD_QTY_TY         		AS			STKF_TRD_QTY_TY										--股基交易量_本年	
		,T1.SCDY_TRD_QTY_M          		AS			SCDY_TRD_QTY_M										--二级交易量_本月	
		,T2.SCDY_TRD_QTY_TY          		AS			SCDY_TRD_QTY_TY										--二级交易量_本年		
		,T1.S_REPUR_TRD_QTY_M       		AS			S_REPUR_TRD_QTY_M									--正回购交易量_本月		
		,T2.S_REPUR_TRD_QTY_TY       		AS			S_REPUR_TRD_QTY_TY									--正回购交易量_本年			
		,T1.R_REPUR_TRD_QTY_M       		AS			R_REPUR_TRD_QTY_M									--逆回购交易量_本月			
		,T2.R_REPUR_TRD_QTY_TY       		AS			R_REPUR_TRD_QTY_TY									--逆回购交易量_本年	
		,T1.HGT_TRD_QTY_M           		AS			HGT_TRD_QTY_M										--沪港通交易量_本月	
		,T2.HGT_TRD_QTY_TY           		AS			HGT_TRD_QTY_TY										--沪港通交易量_本年	
		,T1.SGT_TRD_QTY_M           		AS			SGT_TRD_QTY_M										--深港通交易量_本月	
		,T2.SGT_TRD_QTY_TY           		AS			SGT_TRD_QTY_TY										--深港通交易量_本年	
		,T1.STKPLG_TRD_QTY_M        		AS			STKPLG_TRD_QTY_M									--股票质押交易量_本月			
		,T2.STKPLG_TRD_QTY_TY        		AS			STKPLG_TRD_QTY_TY									--股票质押交易量_本年		
		,T1.APPTBUYB_TRD_QTY_M      		AS			APPTBUYB_TRD_QTY_M									--约定购回交易量_本月	
		,T2.APPTBUYB_TRD_QTY_TY      		AS			APPTBUYB_TRD_QTY_TY									--约定购回交易量_本年	
		,T1.OFFUND_TRD_QTY_M        		AS			OFFUND_TRD_QTY_M									--场内基金交易量_本月	
		,T2.OFFUND_TRD_QTY_TY        		AS			OFFUND_TRD_QTY_TY									--场内基金交易量_本年	
		,T1.OPFUND_TRD_QTY_M        		AS			OPFUND_TRD_QTY_M									--场外基金交易量_本月	
		,T2.OPFUND_TRD_QTY_TY        		AS			OPFUND_TRD_QTY_TY									--场外基金交易量_本年	
		,T1.BANK_CHRM_TRD_QTY_M     		AS			BANK_CHRM_TRD_QTY_M									--银行理财交易量_本月 	
		,T2.BANK_CHRM_TRD_QTY_TY     		AS			BANK_CHRM_TRD_QTY_TY								--银行理财交易量_本年 		
		,T1.SECU_CHRM_TRD_QTY_M     		AS			SECU_CHRM_TRD_QTY_M									--证券理财交易量_本月	
		,T2.SECU_CHRM_TRD_QTY_TY     		AS			SECU_CHRM_TRD_QTY_TY								--证券理财交易量_本年		
		,T1.PSTK_OPTN_TRD_QTY_M     		AS			PSTK_OPTN_TRD_QTY_M									--个股期权交易量_本月		
		,T2.PSTK_OPTN_TRD_QTY_TY     		AS			PSTK_OPTN_TRD_QTY_TY								--个股期权交易量_本年			
		,T1.CREDIT_ODI_TRD_QTY_M    		AS			CREDIT_ODI_TRD_QTY_M								--信用账户普通交易量_本月 		
		,T2.CREDIT_ODI_TRD_QTY_TY    		AS			CREDIT_ODI_TRD_QTY_TY								--信用账户普通交易量_本年 		
		,T1.CREDIT_CRED_TRD_QTY_M   		AS			CREDIT_CRED_TRD_QTY_M								--信用账户信用交易量_本月 		
		,T2.CREDIT_CRED_TRD_QTY_TY   		AS			CREDIT_CRED_TRD_QTY_TY								--信用账户信用交易量_本年 		
		,T1.COVR_BUYIN_AMT_M        		AS			COVR_BUYIN_AMT_M									--平仓买入金额_本月 	
		,T2.COVR_BUYIN_AMT_TY        		AS			COVR_BUYIN_AMT_TY									--平仓买入金额_本年 	
		,T1.COVR_SELL_AMT_M         		AS			COVR_SELL_AMT_M										--平仓卖出金额_本月 
		,T2.COVR_SELL_AMT_TY         		AS			COVR_SELL_AMT_TY									--平仓卖出金额_本年 	
		,T1.CCB_AMT_M               		AS			CCB_AMT_M											--融资买入金额_本月 
		,T2.CCB_AMT_TY               		AS			CCB_AMT_TY											--融资买入金额_本年 
		,T1.FIN_SELL_AMT_M          		AS			FIN_SELL_AMT_M										--融资卖出金额_本月 
		,T2.FIN_SELL_AMT_TY          		AS			FIN_SELL_AMT_TY										--融资卖出金额_本年 
		,T1.CRDT_STK_BUYIN_AMT_M    		AS			CRDT_STK_BUYIN_AMT_M								--融券买入金额_本月 		
		,T2.CRDT_STK_BUYIN_AMT_TY    		AS			CRDT_STK_BUYIN_AMT_TY								--融券买入金额_本年 		
		,T1.CSS_AMT_M               		AS			CSS_AMT_M											--融券卖出金额_本月 
		,T2.CSS_AMT_TY               		AS			CSS_AMT_TY											--融券卖出金额_本年 
		,T1.FIN_RTN_AMT_M           		AS			FIN_RTN_AMT_M        								--融资归还金额_本月		
		,T2.FIN_RTN_AMT_TY           		AS			FIN_RTN_AMT_TY       								--融资归还金额_本年		
		,T1.STKPLG_INIT_TRD_AMT_M   		AS			STKPLG_INIT_TRD_AMT_M 								--股票质押初始交易金额_本月		
		,T2.STKPLG_INIT_TRD_AMT_TY   		AS			STKPLG_INIT_TRD_AMT_TY 								--股票质押初始交易金额_本年		
		,T1.STKPLG_BUYB_TRD_AMT_M   		AS			STKPLG_REPO_TRD_AMT_M								--股票质押购回交易金额_本月		
		,T2.STKPLG_BUYB_TRD_AMT_TY   		AS			STKPLG_REPO_TRD_AMT_TY								--股票质押购回交易金额_本年		
		,T1.APPTBUYB_INIT_TRD_AMT_M 		AS			APPTBUYB_INIT_TRD_AMT_M 							--约定购回初始交易金额_本月			
		,T2.APPTBUYB_INIT_TRD_AMT_TY 		AS			APPTBUYB_INIT_TRD_AMT_TY							--约定购回初始交易金额_本年			
		,T1.APPTBUYB_BUYB_TRD_AMT_M 		AS			APPTBUYB_BUYB_TRD_AMT_M								--约定购回购回交易金额_本月			
		,T2.APPTBUYB_BUYB_TRD_AMT_TY 		AS			APPTBUYB_BUYB_TRD_AMT_TY							--约定购回购回交易金额_本年			
	FROM #TMP_T_EVT_TRD_M_BRH_MTH T1,#TMP_T_EVT_TRD_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
