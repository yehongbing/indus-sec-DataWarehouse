CREATE PROCEDURE DM.P_EVT_PROD_TRD_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部产品交易事实表（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-09
  简介：营业部产品事实表（日表）
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_PROD_TRD_D_BRH WHERE OCCUR_DT = @V_DATE;

  	-- 员工-营业部关系
	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--员工编码
		,A.PK_ORG 		AS 		BRH_ID			--营业部编码
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  		AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	CREATE TABLE #TMP_T_EVT_PROD_TRD_D_BRH(
	    OCCUR_DT             	numeric(8,0) 		NOT NULL,
		BRH_ID               	varchar(30) 		NOT NULL,
		EMP_ID		 			varchar(30) 		NOT NULL,
		PROD_CD              	varchar(30) 		NOT NULL,
		PROD_TYPE            	varchar(30) 		NOT NULL,
		ITC_RETAIN_AMT       	numeric(38,8) 		NULL,
		OTC_RETAIN_AMT       	numeric(38,8) 		NULL,
		ITC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		OTC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		ITC_SUBS_AMT         	numeric(38,8) 		NULL,
		ITC_PURS_AMT         	numeric(38,8) 		NULL,
		ITC_BUYIN_AMT        	numeric(38,8) 		NULL,
		ITC_REDP_AMT         	numeric(38,8) 		NULL,
		ITC_SELL_AMT         	numeric(38,8) 		NULL,
		OTC_SUBS_AMT         	numeric(38,8) 		NULL,
		OTC_PURS_AMT         	numeric(38,8) 		NULL,
		OTC_CASTSL_AMT       	numeric(38,8) 		NULL,
		OTC_COVT_IN_AMT      	numeric(38,8) 		NULL,
		OTC_REDP_AMT         	numeric(38,8) 		NULL,
		OTC_COVT_OUT_AMT     	numeric(38,8) 		NULL,
		ITC_SUBS_SHAR        	numeric(38,8) 		NULL,
		ITC_PURS_SHAR        	numeric(38,8) 		NULL,
		ITC_BUYIN_SHAR       	numeric(38,8) 		NULL,
		ITC_REDP_SHAR        	numeric(38,8) 		NULL,
		ITC_SELL_SHAR        	numeric(38,8) 		NULL,
		OTC_SUBS_SHAR        	numeric(38,8) 		NULL,
		OTC_PURS_SHAR        	numeric(38,8) 		NULL,
		OTC_CASTSL_SHAR      	numeric(38,8) 		NULL,
		OTC_COVT_IN_SHAR     	numeric(38,8) 		NULL,
		OTC_REDP_SHAR        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_SHAR    	numeric(38,8) 		NULL,
		ITC_SUBS_CHAG        	numeric(38,8) 		NULL,
		ITC_PURS_CHAG        	numeric(38,8) 		NULL,
		ITC_BUYIN_CHAG       	numeric(38,8) 		NULL,
		ITC_REDP_CHAG        	numeric(38,8) 		NULL,
		ITC_SELL_CHAG        	numeric(38,8) 		NULL,
		OTC_SUBS_CHAG        	numeric(38,8) 		NULL,
		OTC_PURS_CHAG        	numeric(38,8) 		NULL,
		OTC_CASTSL_CHAG      	numeric(38,8) 		NULL,
		OTC_COVT_IN_CHAG     	numeric(38,8) 		NULL,
		OTC_REDP_CHAG        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_CHAG    	numeric(38,8) 		NULL,
		CONTD_SALE_SHAR      	numeric(38,8) 		NULL,
		CONTD_SALE_AMT       	numeric(38,8) 		NULL
	);

	INSERT INTO #TMP_T_EVT_PROD_TRD_D_BRH(
		  OCCUR_DT          		--发生日期
		 ,BRH_ID					--营业部编码
		 ,EMP_ID            		--员工编码			
		 ,PROD_CD           		--产品代码			
		 ,PROD_TYPE         		--产品类型			
		 ,ITC_RETAIN_AMT    		--场内保有金额			
		 ,OTC_RETAIN_AMT    		--场外保有金额			
		 ,ITC_RETAIN_SHAR   		--场内保有份额			
		 ,OTC_RETAIN_SHAR   		--场外保有份额			
		 ,ITC_SUBS_AMT      		--场内认购金额			
		 ,ITC_PURS_AMT      		--场内申购金额			
		 ,ITC_BUYIN_AMT     		--场内买入金额			
		 ,ITC_REDP_AMT      		--场内赎回金额			
		 ,ITC_SELL_AMT      		--场内卖出金额			
		 ,OTC_SUBS_AMT      		--场外认购金额			
		 ,OTC_PURS_AMT      		--场外申购金额			
		 ,OTC_CASTSL_AMT    		--场外定投金额			
		 ,OTC_COVT_IN_AMT   		--场外转换入金额			
		 ,OTC_REDP_AMT      		--场外赎回金额			
		 ,OTC_COVT_OUT_AMT  		--场外转换出金额			
		 ,ITC_SUBS_SHAR     		--场内认购份额			
		 ,ITC_PURS_SHAR     		--场内申购份额			
		 ,ITC_BUYIN_SHAR    		--场内买入份额			
		 ,ITC_REDP_SHAR     		--场内赎回份额			
		 ,ITC_SELL_SHAR     		--场内卖出份额			
		 ,OTC_SUBS_SHAR     		--场外认购份额			
		 ,OTC_PURS_SHAR     		--场外申购份额			
		 ,OTC_CASTSL_SHAR   		--场外定投份额			
		 ,OTC_COVT_IN_SHAR  		--场外转换入份额			
		 ,OTC_REDP_SHAR     		--场外赎回份额			
		 ,OTC_COVT_OUT_SHAR 		--场外转换出份额			
		 ,ITC_SUBS_CHAG     		--场内认购手续费			
		 ,ITC_PURS_CHAG     		--场内申购手续费			
		 ,ITC_BUYIN_CHAG    		--场内买入手续费			
		 ,ITC_REDP_CHAG     		--场内赎回手续费			
		 ,ITC_SELL_CHAG     		--场内卖出手续费			
		 ,OTC_SUBS_CHAG     		--场外认购手续费			
		 ,OTC_PURS_CHAG     		--场外申购手续费			
		 ,OTC_CASTSL_CHAG   		--场外定投手续费			
		 ,OTC_COVT_IN_CHAG  		--场外转换入手续费			
		 ,OTC_REDP_CHAG     		--场外赎回手续费			
		 ,OTC_COVT_OUT_CHAG 		--场外转换出手续费			
		 ,CONTD_SALE_SHAR   		--续作销售份额			
		 ,CONTD_SALE_AMT    		--续作销售金额			
	)
	SELECT 
		  T.OCCUR_DT						AS			OCCUR_DT          		--发生日期
		 ,T1.BRH_ID							AS 			BRH_ID					--营业部编码
		 ,T.EMP_ID	  						AS 			EMP_ID					--员工编码
		 ,T.PROD_CD 						AS  		PROD_CD 				--产品代码				
		 ,T.PROD_TYPE 						AS  		PROD_TYPE 				--产品类型
		 ,T.ITC_RETAIN_AMT    				AS 			ITC_RETAIN_AMT    		--场内保有金额		
		 ,T.OTC_RETAIN_AMT    				AS 			OTC_RETAIN_AMT    		--场外保有金额		
		 ,T.ITC_RETAIN_SHAR   				AS 			ITC_RETAIN_SHAR   		--场内保有份额		
		 ,T.OTC_RETAIN_SHAR   				AS 			OTC_RETAIN_SHAR   		--场外保有份额		
		 ,T.ITC_SUBS_AMT      				AS 			ITC_SUBS_AMT      		--场内认购金额		
		 ,T.ITC_PURS_AMT      				AS 			ITC_PURS_AMT      		--场内申购金额		
		 ,T.ITC_BUYIN_AMT     				AS 			ITC_BUYIN_AMT     		--场内买入金额		
		 ,T.ITC_REDP_AMT      				AS 			ITC_REDP_AMT      		--场内赎回金额		
		 ,T.ITC_SELL_AMT      				AS 			ITC_SELL_AMT      		--场内卖出金额		
		 ,T.OTC_SUBS_AMT      				AS 			OTC_SUBS_AMT      		--场外认购金额		
		 ,T.OTC_PURS_AMT      				AS 			OTC_PURS_AMT      		--场外申购金额		
		 ,T.OTC_CASTSL_AMT    				AS 			OTC_CASTSL_AMT    		--场外定投金额		
		 ,T.OTC_COVT_IN_AMT   				AS 			OTC_COVT_IN_AMT   		--场外转换入金额	
		 ,T.OTC_REDP_AMT      				AS 			OTC_REDP_AMT      		--场外赎回金额		
		 ,T.OTC_COVT_OUT_AMT  				AS 			OTC_COVT_OUT_AMT  		--场外转换出金额	
		 ,T.ITC_SUBS_SHAR     				AS 			ITC_SUBS_SHAR     		--场内认购份额		
		 ,T.ITC_PURS_SHAR     				AS 			ITC_PURS_SHAR     		--场内申购份额		
		 ,T.ITC_BUYIN_SHAR    				AS 			ITC_BUYIN_SHAR    		--场内买入份额		
		 ,T.ITC_REDP_SHAR     				AS 			ITC_REDP_SHAR     		--场内赎回份额		
		 ,T.ITC_SELL_SHAR     				AS 			ITC_SELL_SHAR     		--场内卖出份额		
		 ,T.OTC_SUBS_SHAR     				AS 			OTC_SUBS_SHAR     		--场外认购份额		
		 ,T.OTC_PURS_SHAR     				AS 			OTC_PURS_SHAR     		--场外申购份额		
		 ,T.OTC_CASTSL_SHAR   				AS 			OTC_CASTSL_SHAR   		--场外定投份额		
		 ,T.OTC_COVT_IN_SHAR  				AS 			OTC_COVT_IN_SHAR  		--场外转换入份额	
		 ,T.OTC_REDP_SHAR     				AS 			OTC_REDP_SHAR     		--场外赎回份额		
		 ,T.OTC_COVT_OUT_SHAR 				AS 			OTC_COVT_OUT_SHAR 		--场外转换出份额	
		 ,T.ITC_SUBS_CHAG     				AS 			ITC_SUBS_CHAG     		--场内认购手续费	
		 ,T.ITC_PURS_CHAG     				AS 			ITC_PURS_CHAG     		--场内申购手续费	
		 ,T.ITC_BUYIN_CHAG    				AS 			ITC_BUYIN_CHAG    		--场内买入手续费	
		 ,T.ITC_REDP_CHAG     				AS 			ITC_REDP_CHAG     		--场内赎回手续费	
		 ,T.ITC_SELL_CHAG     				AS 			ITC_SELL_CHAG     		--场内卖出手续费	
		 ,T.OTC_SUBS_CHAG     				AS 			OTC_SUBS_CHAG     		--场外认购手续费	
		 ,T.OTC_PURS_CHAG     				AS 			OTC_PURS_CHAG     		--场外申购手续费	
		 ,T.OTC_CASTSL_CHAG   				AS 			OTC_CASTSL_CHAG   		--场外定投手续费	
		 ,T.OTC_COVT_IN_CHAG  				AS 			OTC_COVT_IN_CHAG  		--场外转换入手续费	
		 ,T.OTC_REDP_CHAG     				AS 			OTC_REDP_CHAG     		--场外赎回手续费	
		 ,T.OTC_COVT_OUT_CHAG 				AS 			OTC_COVT_OUT_CHAG 		--场外转换出手续费	
		 ,T.CONTD_SALE_SHAR   				AS 			CONTD_SALE_SHAR   		--续作销售份额		
		 ,T.CONTD_SALE_AMT    				AS 			CONTD_SALE_AMT    		--续作销售金额		
	FROM DM.T_EVT_PROD_TRD_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE;
	
	--将临时表的按营业部维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_PROD_TRD_D_BRH (
			  OCCUR_DT          		--发生日期
		     ,BRH_ID            		--营业部编码
		     ,PROD_CD           		--产品代码			
		     ,PROD_TYPE         		--产品类型			
		     ,ITC_RETAIN_AMT    		--场内保有金额			
		     ,OTC_RETAIN_AMT    		--场外保有金额			
		     ,ITC_RETAIN_SHAR   		--场内保有份额			
		     ,OTC_RETAIN_SHAR   		--场外保有份额			
		     ,ITC_SUBS_AMT      		--场内认购金额			
		     ,ITC_PURS_AMT      		--场内申购金额			
		     ,ITC_BUYIN_AMT     		--场内买入金额			
		     ,ITC_REDP_AMT      		--场内赎回金额			
		     ,ITC_SELL_AMT      		--场内卖出金额			
		     ,OTC_SUBS_AMT      		--场外认购金额			
		     ,OTC_PURS_AMT      		--场外申购金额			
		     ,OTC_CASTSL_AMT    		--场外定投金额			
		     ,OTC_COVT_IN_AMT   		--场外转换入金额			
		     ,OTC_REDP_AMT      		--场外赎回金额			
		     ,OTC_COVT_OUT_AMT  		--场外转换出金额			
		     ,ITC_SUBS_SHAR     		--场内认购份额			
		     ,ITC_PURS_SHAR     		--场内申购份额			
		     ,ITC_BUYIN_SHAR    		--场内买入份额			
		     ,ITC_REDP_SHAR     		--场内赎回份额			
		     ,ITC_SELL_SHAR     		--场内卖出份额			
		     ,OTC_SUBS_SHAR     		--场外认购份额			
		     ,OTC_PURS_SHAR     		--场外申购份额			
		     ,OTC_CASTSL_SHAR   		--场外定投份额			
		     ,OTC_COVT_IN_SHAR  		--场外转换入份额			
		     ,OTC_REDP_SHAR     		--场外赎回份额			
		     ,OTC_COVT_OUT_SHAR 		--场外转换出份额			
		     ,ITC_SUBS_CHAG     		--场内认购手续费			
		     ,ITC_PURS_CHAG     		--场内申购手续费			
		     ,ITC_BUYIN_CHAG    		--场内买入手续费			
		     ,ITC_REDP_CHAG     		--场内赎回手续费			
		     ,ITC_SELL_CHAG     		--场内卖出手续费			
		     ,OTC_SUBS_CHAG     		--场外认购手续费			
		     ,OTC_PURS_CHAG     		--场外申购手续费			
		     ,OTC_CASTSL_CHAG   		--场外定投手续费			
		     ,OTC_COVT_IN_CHAG  		--场外转换入手续费			
		     ,OTC_REDP_CHAG     		--场外赎回手续费			
		     ,OTC_COVT_OUT_CHAG 		--场外转换出手续费			
		     ,CONTD_SALE_SHAR   		--续作销售份额			
		     ,CONTD_SALE_AMT    		--续作销售金额		
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              	--发生日期		
			,BRH_ID									AS    BRH_ID                	--营业部编码	
			,PROD_CD           		 				AS    PROD_CD					--产品代码			
		    ,PROD_TYPE         						AS    PROD_TYPE					--产品类型			
			,SUM(ITC_RETAIN_AMT)    				AS    ITC_RETAIN_AMT   			--场内保有金额		
			,SUM(OTC_RETAIN_AMT)    				AS    OTC_RETAIN_AMT   			--场外保有金额		
			,SUM(ITC_RETAIN_SHAR)   				AS    ITC_RETAIN_SHAR  			--场内保有份额		
			,SUM(OTC_RETAIN_SHAR)  					AS    OTC_RETAIN_SHAR  			--场外保有份额		
			,SUM(ITC_SUBS_AMT)      				AS    ITC_SUBS_AMT     			--场内认购金额		
			,SUM(ITC_PURS_AMT)      				AS    ITC_PURS_AMT     			--场内申购金额		
			,SUM(ITC_BUYIN_AMT)     				AS    ITC_BUYIN_AMT    			--场内买入金额		
			,SUM(ITC_REDP_AMT)      				AS    ITC_REDP_AMT     			--场内赎回金额		
			,SUM(ITC_SELL_AMT)      				AS    ITC_SELL_AMT     			--场内卖出金额		
			,SUM(OTC_SUBS_AMT)      				AS    OTC_SUBS_AMT     			--场外认购金额		
			,SUM(OTC_PURS_AMT)      				AS    OTC_PURS_AMT     			--场外申购金额		
			,SUM(OTC_CASTSL_AMT)    				AS    OTC_CASTSL_AMT   			--场外定投金额		
			,SUM(OTC_COVT_IN_AMT)   				AS    OTC_COVT_IN_AMT  			--场外转换入金额	
			,SUM(OTC_REDP_AMT)      				AS    OTC_REDP_AMT     			--场外赎回金额		
			,SUM(OTC_COVT_OUT_AMT)  				AS    OTC_COVT_OUT_AMT 			--场外转换出金额	
			,SUM(ITC_SUBS_SHAR)     				AS    ITC_SUBS_SHAR    			--场内认购份额		
			,SUM(ITC_PURS_SHAR)     				AS    ITC_PURS_SHAR    			--场内申购份额		
			,SUM(ITC_BUYIN_SHAR)    				AS    ITC_BUYIN_SHAR   			--场内买入份额		
			,SUM(ITC_REDP_SHAR)     				AS    ITC_REDP_SHAR    			--场内赎回份额		
			,SUM(ITC_SELL_SHAR)     				AS    ITC_SELL_SHAR    			--场内卖出份额		
			,SUM(OTC_SUBS_SHAR)     				AS    OTC_SUBS_SHAR    			--场外认购份额		
			,SUM(OTC_PURS_SHAR)    					AS    OTC_PURS_SHAR    			--场外申购份额		
			,SUM(OTC_CASTSL_SHAR)   				AS    OTC_CASTSL_SHAR  			--场外定投份额		
			,SUM(OTC_COVT_IN_SHAR)  				AS    OTC_COVT_IN_SHAR 			--场外转换入份额	
			,SUM(OTC_REDP_SHAR)     				AS    OTC_REDP_SHAR    			--场外赎回份额		
			,SUM(OTC_COVT_OUT_SHAR) 				AS    OTC_COVT_OUT_SHAR			--场外转换出份额	
			,SUM(ITC_SUBS_CHAG)    					AS    ITC_SUBS_CHAG    			--场内认购手续费	
			,SUM(ITC_PURS_CHAG)     				AS    ITC_PURS_CHAG    			--场内申购手续费	
			,SUM(ITC_BUYIN_CHAG)    				AS    ITC_BUYIN_CHAG   			--场内买入手续费	
			,SUM(ITC_REDP_CHAG)     				AS    ITC_REDP_CHAG    			--场内赎回手续费	
			,SUM(ITC_SELL_CHAG)     				AS    ITC_SELL_CHAG    			--场内卖出手续费	
			,SUM(OTC_SUBS_CHAG)     				AS    OTC_SUBS_CHAG    			--场外认购手续费	
			,SUM(OTC_PURS_CHAG)     				AS    OTC_PURS_CHAG    			--场外申购手续费	
			,SUM(OTC_CASTSL_CHAG)   				AS    OTC_CASTSL_CHAG  			--场外定投手续费	
			,SUM(OTC_COVT_IN_CHAG)  				AS    OTC_COVT_IN_CHAG 			--场外转换入手续费	
			,SUM(OTC_REDP_CHAG)     				AS    OTC_REDP_CHAG    			--场外赎回手续费	
			,SUM(OTC_COVT_OUT_CHAG) 				AS    OTC_COVT_OUT_CHAG			--场外转换出手续费	
			,SUM(CONTD_SALE_SHAR)   				AS    CONTD_SALE_SHAR  			--续作销售份额		
			,SUM(CONTD_SALE_AMT)    				AS    CONTD_SALE_AMT   			--续作销售金额		
		FROM #TMP_T_EVT_PROD_TRD_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID,T.PROD_CD,T.PROD_TYPE;
	COMMIT;
END
