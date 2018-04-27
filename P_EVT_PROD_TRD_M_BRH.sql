CREATE PROCEDURE DM.P_EVT_PROD_TRD_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部产品交易事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-04
  简介：产品交易统计
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

	DELETE FROM DM.T_EVT_PROD_TRD_M_BRH WHERE YEAR = @V_YEAR AND MTH = @V_MONTH;

	-- 统计月指标
	SELECT 
		 @V_YEAR								AS    YEAR   					--年
		,@V_MONTH 								AS    MTH 						--月
		,BRH_ID									AS    BRH_ID                	--营业部编码	
		,PROD_CD								AS    PROD_CD					--产品代码 
		,PROD_TYPE 							    AS    PROD_TYPE 				--产品类别
		,@V_DATE 								AS    OCCUR_DT 		 			--发生日期
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_MDAYS 		AS	  ITC_RETAIN_AMT_MDA  		--场内保有金额_月日均
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_MDAYS  	AS 	  OTC_RETAIN_AMT_MDA  		--场外保有金额_月日均
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  ITC_RETAIN_SHAR_MDA 		--场内保有份额_月日均
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  OTC_RETAIN_SHAR_MDA 		--场外保有份额_月日均  
		,SUM(ITC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_M			--场外认购金额_本月
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_M			--场内申购金额_本月
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_M    		--场内买入金额_本月
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_M     		--场内赎回金额_本月
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_M     		--场内卖出金额_本月
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_M     		--场外申购金额_本月
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_M   		--场外定投金额_本月
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_M  		--场外转换入金额_本月
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_M     		--场外赎回金额_本月
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_M 		--场外转换出金额_本月
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_M    		--场内认购份额_本月
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_M    		--场内申购份额_本月
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_M   		--场内买入份额_本月
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_M    		--场内赎回份额_本月
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_M    		--场内卖出份额_本月
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_M    		--场外认购份额_本月
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_M    		--场外申购份额_本月
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_M 		--场外定投份额_本月
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_M 		--场外转换入份额_本月
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_M    		--场外赎回份额_本月
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_M		--场外转换出份额_本月
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_M    		--场内认购手续费_本月
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_M    		--场内申购手续费_本月
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_M   		--场内买入手续费_本月
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_M    		--场内赎回手续费_本月
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_M    		--场内卖出手续费_本月
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_M    		--场外认购手续费_本月
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_M    		--场外申购手续费_本月
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_M  		--场外定投手续费_本月
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_M 		--场外转换入手续费_本月
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_M    		--场外赎回手续费_本月
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_M		--场外转换出手续费_本月
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_M  		--续作销售份额_本月
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_M  		--续作销售金额_本月
	INTO #T_EVT_PROD_TRD_M_BRH_MTH
	FROM DM.T_EVT_PROD_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID,T.PROD_CD,T.PROD_TYPE;

	-- 统计年指标
	SELECT 
		 @V_YEAR								AS    YEAR   					--年
		,@V_MONTH 								AS    MTH 						--月
		,BRH_ID									AS    BRH_ID                	--营业部编码	
		,PROD_CD								AS    PROD_CD					--产品代码 
		,PROD_TYPE 							    AS    PROD_TYPE 				--产品类别
		,@V_DATE 								AS    OCCUR_DT 		 			--发生日期	
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_YDAYS 		AS	  ITC_RETAIN_AMT_YDA  		--场内保有金额_年日均
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_YDAYS  	AS 	  OTC_RETAIN_AMT_YDA  		--场外保有金额_年日均
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  ITC_RETAIN_SHAR_YDA 		--场内保有份额_年日均
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  OTC_RETAIN_SHAR_YDA 		--场外保有份额_年日均  
		,SUM(OTC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_TY			--场外认购金额_本年
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_TY			--场内申购金额_本年
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_TY    		--场内买入金额_本年
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_TY     		--场内赎回金额_本年
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_TY     		--场内卖出金额_本年
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_TY     		--场外申购金额_本年
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_TY   		--场外定投金额_本年
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_TY  		--场外转换入金额_本年
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_TY     		--场外赎回金额_本年
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_TY 		--场外转换出金额_本年
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_TY    		--场内认购份额_本年
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_TY    		--场内申购份额_本年
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_TY   		--场内买入份额_本年
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_TY    		--场内赎回份额_本年
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_TY    		--场内卖出份额_本年
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_TY    		--场外认购份额_本年
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_TY    		--场外申购份额_本年
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_TY		--场外定投份额_本年
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_TY 		--场外转换入份额_本年
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_TY    		--场外赎回份额_本年
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_TY		--场外转换出份额_本年
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_TY    		--场内认购手续费_本年
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_TY    		--场内申购手续费_本年
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_TY   		--场内买入手续费_本年
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_TY    		--场内赎回手续费_本年
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_TY    		--场内卖出手续费_本年
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_TY    		--场外认购手续费_本年
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_TY    		--场外申购手续费_本年
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_TY  		--场外定投手续费_本年
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_TY 		--场外转换入手续费_本年
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_TY    		--场外赎回手续费_本年
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_TY		--场外转换出手续费_本年
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_TY  		--续作销售份额_本年
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_TY  		--续作销售金额_本年
	INTO #T_EVT_PROD_TRD_M_BRH_YEAR
	FROM DM.T_EVT_PROD_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID,T.PROD_CD,T.PROD_TYPE;

	--插入目标表
	INSERT INTO DM.T_EVT_PROD_TRD_M_BRH(
		 YEAR                				--年
		,MTH                 				--月
		,BRH_ID              				--营业部编码
		,PROD_CD             				--产品代码
		,PROD_TYPE           				--产品类型
		,OCCUR_DT            				--发生日期
		,ITC_RETAIN_AMT_MDA  				--场内保有金额_月日均
		,OTC_RETAIN_AMT_MDA  				--场外保有金额_月日均
		,ITC_RETAIN_SHAR_MDA 				--场内保有份额_月日均
		,OTC_RETAIN_SHAR_MDA 				--场外保有份额_月日均  
		,ITC_RETAIN_AMT_YDA  				--场内保有金额_年日均
		,OTC_RETAIN_AMT_YDA  				--场外保有金额_年日均
		,ITC_RETAIN_SHAR_YDA 				--场内保有份额_年日均
		,OTC_RETAIN_SHAR_YDA 				--场外保有份额_年日均  
		,OTC_SUBS_AMT_M      				--场外认购金额_本月
		,ITC_PURS_AMT_M      				--场内申购金额_本月
		,ITC_BUYIN_AMT_M     				--场内买入金额_本月
		,ITC_REDP_AMT_M      				--场内赎回金额_本月
		,ITC_SELL_AMT_M      				--场内卖出金额_本月
		,OTC_PURS_AMT_M      				--场外申购金额_本月
		,OTC_CASTSL_AMT_M    				--场外定投金额_本月
		,OTC_COVT_IN_AMT_M   				--场外转换入金额_本月
		,OTC_REDP_AMT_M      				--场外赎回金额_本月
		,OTC_COVT_OUT_AMT_M  				--场外转换出金额_本月
		,ITC_SUBS_SHAR_M     				--场内认购份额_本月
		,ITC_PURS_SHAR_M     				--场内申购份额_本月
		,ITC_BUYIN_SHAR_M    				--场内买入份额_本月
		,ITC_REDP_SHAR_M     				--场内赎回份额_本月
		,ITC_SELL_SHAR_M     				--场内卖出份额_本月
		,OTC_SUBS_SHAR_M     				--场外认购份额_本月
		,OTC_PURS_SHAR_M     				--场外申购份额_本月
		,OTC_CASTSL_SHAR_M   				--场外定投份额_本月
		,OTC_COVT_IN_SHAR_M  				--场外转换入份额_本月
		,OTC_REDP_SHAR_M     				--场外赎回份额_本月
		,OTC_COVT_OUT_SHAR_M 				--场外转换出份额_本月
		,ITC_SUBS_CHAG_M     				--场内认购手续费_本月
		,ITC_PURS_CHAG_M     				--场内申购手续费_本月
		,ITC_BUYIN_CHAG_M    				--场内买入手续费_本月
		,ITC_REDP_CHAG_M     				--场内赎回手续费_本月
		,ITC_SELL_CHAG_M     				--场内卖出手续费_本月
		,OTC_SUBS_CHAG_M     				--场外认购手续费_本月
		,OTC_PURS_CHAG_M     				--场外申购手续费_本月
		,OTC_CASTSL_CHAG_M   				--场外定投手续费_本月
		,OTC_COVT_IN_CHAG_M  				--场外转换入手续费_本月
		,OTC_REDP_CHAG_M     				--场外赎回手续费_本月
		,OTC_COVT_OUT_CHAG_M 				--场外转换出手续费_本月
		,CONTD_SALE_SHAR_M   				--续作销售份额_本月
		,CONTD_SALE_AMT_M    				--续作销售金额_本月
		,OTC_SUBS_AMT_TY     				--场外认购金额_本年
		,ITC_PURS_AMT_TY     				--场内申购金额_本年
		,ITC_BUYIN_AMT_TY    				--场内买入金额_本年
		,ITC_REDP_AMT_TY     				--场内赎回金额_本年
		,ITC_SELL_AMT_TY     				--场内卖出金额_本年
		,OTC_PURS_AMT_TY     				--场外申购金额_本年
		,OTC_CASTSL_AMT_TY   				--场外定投金额_本年
		,OTC_COVT_IN_AMT_TY  				--场外转换入金额_本年
		,OTC_REDP_AMT_TY     				--场外赎回金额_本年
		,OTC_COVT_OUT_AMT_TY 				--场外转换出金额_本年
		,ITC_SUBS_SHAR_TY    				--场内认购份额_本年
		,ITC_PURS_SHAR_TY    				--场内申购份额_本年
		,ITC_BUYIN_SHAR_TY   				--场内买入份额_本年
		,ITC_REDP_SHAR_TY    				--场内赎回份额_本年
		,ITC_SELL_SHAR_TY    				--场内卖出份额_本年
		,OTC_SUBS_SHAR_TY    				--场外认购份额_本年
		,OTC_PURS_SHAR_TY    				--场外申购份额_本年
		,OTC_CASTSL_SHAR_TY  				--场外定投份额_本年
		,OTC_COVT_IN_SHAR_TY 				--场外转换入份额_本年
		,OTC_REDP_SHAR_TY    				--场外赎回份额_本年
		,OTC_COVT_OUT_SHAR_TY				--场外转换出份额_本年
		,ITC_SUBS_CHAG_TY    				--场内认购手续费_本年
		,ITC_PURS_CHAG_TY    				--场内申购手续费_本年
		,ITC_BUYIN_CHAG_TY   				--场内买入手续费_本年
		,ITC_REDP_CHAG_TY    				--场内赎回手续费_本年
		,ITC_SELL_CHAG_TY    				--场内卖出手续费_本年
		,OTC_SUBS_CHAG_TY    				--场外认购手续费_本年
		,OTC_PURS_CHAG_TY    				--场外申购手续费_本年
		,OTC_CASTSL_CHAG_TY  				--场外定投手续费_本年
		,OTC_COVT_IN_CHAG_TY 				--场外转换入手续费_本年
		,OTC_REDP_CHAG_TY    				--场外赎回手续费_本年
		,OTC_COVT_OUT_CHAG_TY				--场外转换出手续费_本年
		,CONTD_SALE_SHAR_TY  				--续作销售份额_本年
		,CONTD_SALE_AMT_TY   				--续作销售金额_本年
	)		
	SELECT 
		 T1.YEAR                        AS 		YEAR                	   --年
		,T1.MTH                         AS 		MTH                 	   --月
		,T1.BRH_ID                      AS 		BRH_ID              	   --营业部编码
		,T1.PROD_CD                     AS 		PROD_CD             	   --产品代码
		,T1.PROD_TYPE                   AS 		PROD_TYPE           	   --产品类型
		,T1.OCCUR_DT                    AS 		OCCUR_DT            	   --发生日期
		,T1.ITC_RETAIN_AMT_MDA          AS 		ITC_RETAIN_AMT_MDA  	   --场内保有金额_月日均
		,T1.OTC_RETAIN_AMT_MDA          AS 		OTC_RETAIN_AMT_MDA  	   --场外保有金额_月日均
		,T1.ITC_RETAIN_SHAR_MDA         AS 		ITC_RETAIN_SHAR_MDA 	   --场内保有份额_月日均
		,T1.OTC_RETAIN_SHAR_MDA         AS 		OTC_RETAIN_SHAR_MDA 	   --场外保有份额_月日均  
		,T2.ITC_RETAIN_AMT_YDA          AS 		ITC_RETAIN_AMT_YDA  	   --场内保有金额_年日均
		,T2.OTC_RETAIN_AMT_YDA          AS 		OTC_RETAIN_AMT_YDA  	   --场外保有金额_年日均
		,T2.ITC_RETAIN_SHAR_YDA         AS 		ITC_RETAIN_SHAR_YDA 	   --场内保有份额_年日均
		,T2.OTC_RETAIN_SHAR_YDA         AS 		OTC_RETAIN_SHAR_YDA 	   --场外保有份额_年日均  
		,T1.OTC_SUBS_AMT_M              AS 		OTC_SUBS_AMT_M      	   --场外认购金额_本月
		,T1.ITC_PURS_AMT_M              AS 		ITC_PURS_AMT_M      	   --场内申购金额_本月
		,T1.ITC_BUYIN_AMT_M             AS 		ITC_BUYIN_AMT_M     	   --场内买入金额_本月
		,T1.ITC_REDP_AMT_M              AS 		ITC_REDP_AMT_M      	   --场内赎回金额_本月
		,T1.ITC_SELL_AMT_M              AS 		ITC_SELL_AMT_M      	   --场内卖出金额_本月
		,T1.OTC_PURS_AMT_M              AS 		OTC_PURS_AMT_M      	   --场外申购金额_本月
		,T1.OTC_CASTSL_AMT_M            AS 		OTC_CASTSL_AMT_M    	   --场外定投金额_本月
		,T1.OTC_COVT_IN_AMT_M           AS 		OTC_COVT_IN_AMT_M   	   --场外转换入金额_本月
		,T1.OTC_REDP_AMT_M              AS 		OTC_REDP_AMT_M      	   --场外赎回金额_本月
		,T1.OTC_COVT_OUT_AMT_M          AS 		OTC_COVT_OUT_AMT_M  	   --场外转换出金额_本月
		,T1.ITC_SUBS_SHAR_M             AS 		ITC_SUBS_SHAR_M     	   --场内认购份额_本月
		,T1.ITC_PURS_SHAR_M             AS 		ITC_PURS_SHAR_M     	   --场内申购份额_本月
		,T1.ITC_BUYIN_SHAR_M            AS 		ITC_BUYIN_SHAR_M    	   --场内买入份额_本月
		,T1.ITC_REDP_SHAR_M             AS 		ITC_REDP_SHAR_M     	   --场内赎回份额_本月
		,T1.ITC_SELL_SHAR_M             AS 		ITC_SELL_SHAR_M     	   --场内卖出份额_本月
		,T1.OTC_SUBS_SHAR_M             AS 		OTC_SUBS_SHAR_M     	   --场外认购份额_本月
		,T1.OTC_PURS_SHAR_M             AS 		OTC_PURS_SHAR_M     	   --场外申购份额_本月
		,T1.OTC_CASTSL_SHAR_M           AS 		OTC_CASTSL_SHAR_M   	   --场外定投份额_本月
		,T1.OTC_COVT_IN_SHAR_M          AS 		OTC_COVT_IN_SHAR_M  	   --场外转换入份额_本月
		,T1.OTC_REDP_SHAR_M             AS 		OTC_REDP_SHAR_M     	   --场外赎回份额_本月
		,T1.OTC_COVT_OUT_SHAR_M         AS 		OTC_COVT_OUT_SHAR_M 	   --场外转换出份额_本月
		,T1.ITC_SUBS_CHAG_M             AS 		ITC_SUBS_CHAG_M     	   --场内认购手续费_本月
		,T1.ITC_PURS_CHAG_M             AS 		ITC_PURS_CHAG_M     	   --场内申购手续费_本月
		,T1.ITC_BUYIN_CHAG_M            AS 		ITC_BUYIN_CHAG_M    	   --场内买入手续费_本月
		,T1.ITC_REDP_CHAG_M             AS 		ITC_REDP_CHAG_M     	   --场内赎回手续费_本月
		,T1.ITC_SELL_CHAG_M             AS 		ITC_SELL_CHAG_M     	   --场内卖出手续费_本月
		,T1.OTC_SUBS_CHAG_M             AS 		OTC_SUBS_CHAG_M     	   --场外认购手续费_本月
		,T1.OTC_PURS_CHAG_M             AS 		OTC_PURS_CHAG_M     	   --场外申购手续费_本月
		,T1.OTC_CASTSL_CHAG_M           AS 		OTC_CASTSL_CHAG_M   	   --场外定投手续费_本月
		,T1.OTC_COVT_IN_CHAG_M          AS 		OTC_COVT_IN_CHAG_M  	   --场外转换入手续费_本月
		,T1.OTC_REDP_CHAG_M             AS 		OTC_REDP_CHAG_M     	   --场外赎回手续费_本月
		,T1.OTC_COVT_OUT_CHAG_M         AS 		OTC_COVT_OUT_CHAG_M 	   --场外转换出手续费_本月
		,T1.CONTD_SALE_SHAR_M           AS 		CONTD_SALE_SHAR_M   	   --续作销售份额_本月
		,T1.CONTD_SALE_AMT_M            AS 		CONTD_SALE_AMT_M    	   --续作销售金额_本月
		,T2.OTC_SUBS_AMT_TY             AS 		OTC_SUBS_AMT_TY     	   --场外认购金额_本年
		,T2.ITC_PURS_AMT_TY             AS 		ITC_PURS_AMT_TY     	   --场内申购金额_本年
		,T2.ITC_BUYIN_AMT_TY            AS 		ITC_BUYIN_AMT_TY    	   --场内买入金额_本年
		,T2.ITC_REDP_AMT_TY             AS 		ITC_REDP_AMT_TY     	   --场内赎回金额_本年
		,T2.ITC_SELL_AMT_TY             AS 		ITC_SELL_AMT_TY     	   --场内卖出金额_本年
		,T2.OTC_PURS_AMT_TY             AS 		OTC_PURS_AMT_TY     	   --场外申购金额_本年
		,T2.OTC_CASTSL_AMT_TY           AS 		OTC_CASTSL_AMT_TY   	   --场外定投金额_本年
		,T2.OTC_COVT_IN_AMT_TY          AS 		OTC_COVT_IN_AMT_TY  	   --场外转换入金额_本年
		,T2.OTC_REDP_AMT_TY             AS 		OTC_REDP_AMT_TY     	   --场外赎回金额_本年
		,T2.OTC_COVT_OUT_AMT_TY         AS 		OTC_COVT_OUT_AMT_TY 	   --场外转换出金额_本年
		,T2.ITC_SUBS_SHAR_TY            AS 		ITC_SUBS_SHAR_TY    	   --场内认购份额_本年
		,T2.ITC_PURS_SHAR_TY            AS 		ITC_PURS_SHAR_TY    	   --场内申购份额_本年
		,T2.ITC_BUYIN_SHAR_TY           AS 		ITC_BUYIN_SHAR_TY   	   --场内买入份额_本年
		,T2.ITC_REDP_SHAR_TY            AS 		ITC_REDP_SHAR_TY    	   --场内赎回份额_本年
		,T2.ITC_SELL_SHAR_TY            AS 		ITC_SELL_SHAR_TY    	   --场内卖出份额_本年
		,T2.OTC_SUBS_SHAR_TY            AS 		OTC_SUBS_SHAR_TY    	   --场外认购份额_本年
		,T2.OTC_PURS_SHAR_TY            AS 		OTC_PURS_SHAR_TY    	   --场外申购份额_本年
		,T2.OTC_CASTSL_SHAR_TY          AS 		OTC_CASTSL_SHAR_TY  	   --场外定投份额_本年
		,T2.OTC_COVT_IN_SHAR_TY         AS 		OTC_COVT_IN_SHAR_TY 	   --场外转换入份额_本年
		,T2.OTC_REDP_SHAR_TY            AS 		OTC_REDP_SHAR_TY    	   --场外赎回份额_本年
		,T2.OTC_COVT_OUT_SHAR_TY        AS 		OTC_COVT_OUT_SHAR_TY	   --场外转换出份额_本年
		,T2.ITC_SUBS_CHAG_TY            AS 		ITC_SUBS_CHAG_TY    	   --场内认购手续费_本年
		,T2.ITC_PURS_CHAG_TY            AS 		ITC_PURS_CHAG_TY    	   --场内申购手续费_本年
		,T2.ITC_BUYIN_CHAG_TY           AS 		ITC_BUYIN_CHAG_TY   	   --场内买入手续费_本年
		,T2.ITC_REDP_CHAG_TY            AS 		ITC_REDP_CHAG_TY    	   --场内赎回手续费_本年
		,T2.ITC_SELL_CHAG_TY            AS 		ITC_SELL_CHAG_TY    	   --场内卖出手续费_本年
		,T2.OTC_SUBS_CHAG_TY            AS 		OTC_SUBS_CHAG_TY    	   --场外认购手续费_本年
		,T2.OTC_PURS_CHAG_TY            AS 		OTC_PURS_CHAG_TY    	   --场外申购手续费_本年
		,T2.OTC_CASTSL_CHAG_TY          AS 		OTC_CASTSL_CHAG_TY  	   --场外定投手续费_本年
		,T2.OTC_COVT_IN_CHAG_TY         AS 		OTC_COVT_IN_CHAG_TY 	   --场外转换入手续费_本年
		,T2.OTC_REDP_CHAG_TY            AS 		OTC_REDP_CHAG_TY    	   --场外赎回手续费_本年
		,T2.OTC_COVT_OUT_CHAG_TY        AS 		OTC_COVT_OUT_CHAG_TY	   --场外转换出手续费_本年
		,T2.CONTD_SALE_SHAR_TY          AS 		CONTD_SALE_SHAR_TY  	   --续作销售份额_本年
		,T2.CONTD_SALE_AMT_TY           AS 		CONTD_SALE_AMT_TY   	   --续作销售金额_本年
	FROM #T_EVT_PROD_TRD_M_BRH_MTH T1,#T_EVT_PROD_TRD_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID 
		AND T1.PROD_CD = T2.PROD_CD
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
