CREATE PROCEDURE DM.P_EVT_INCM_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部收入表（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-11
  简介：营业部收入表（日表）
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_INCM_D_BRH WHERE OCCUR_DT = @V_DATE;

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

	CREATE TABLE #TMP_T_EVT_INCM_D_BRH(
	    OCCUR_DT             	numeric(8,0) NOT NULL,
		BRH_ID               	varchar(30)  NOT NULL,
		EMP_ID		 			varchar(30)  NOT NULL,
		NET_CMS              	numeric(38,8) NULL,
		GROSS_CMS            	numeric(38,8) NULL,
		SCDY_CMS             	numeric(38,8) NULL,
		SCDY_NET_CMS         	numeric(38,8) NULL,
		SCDY_TRAN_FEE        	numeric(38,8) NULL,
		ODI_TRD_TRAN_FEE     	numeric(38,8) NULL,
		CRED_TRD_TRAN_FEE    	numeric(38,8) NULL,
		STKF_CMS             	numeric(38,8) NULL,
		STKF_TRAN_FEE        	numeric(38,8) NULL,
		STKF_NET_CMS         	numeric(38,8) NULL,
		BOND_CMS             	numeric(38,8) NULL,
		BOND_NET_CMS         	numeric(38,8) NULL,
		REPQ_CMS             	numeric(38,8) NULL,
		REPQ_NET_CMS         	numeric(38,8) NULL,
		HGT_CMS              	numeric(38,8) NULL,
		HGT_NET_CMS          	numeric(38,8) NULL,
		HGT_TRAN_FEE         	numeric(38,8) NULL,
		SGT_CMS              	numeric(38,8) NULL,
		SGT_NET_CMS          	numeric(38,8) NULL,
		SGT_TRAN_FEE         	numeric(38,8) NULL,
		BGDL_CMS             	numeric(38,8) NULL,
		BGDL_NET_CMS         	numeric(38,8) NULL,
		BGDL_TRAN_FEE        	numeric(38,8) NULL,
		PSTK_OPTN_CMS        	numeric(38,8) NULL,
		PSTK_OPTN_NET_CMS    	numeric(38,8) NULL,
		CREDIT_ODI_CMS       	numeric(38,8) NULL,
		CREDIT_ODI_NET_CMS   	numeric(38,8) NULL,
		CREDIT_ODI_TRAN_FEE  	numeric(38,8) NULL,
		CREDIT_CRED_CMS      	numeric(38,8) NULL,
		CREDIT_CRED_NET_CMS  	numeric(38,8) NULL,
		CREDIT_CRED_TRAN_FEE 	numeric(38,8) NULL,
		FIN_RECE_INT         	numeric(38,8) NULL,
		FIN_PAIDINT          	numeric(38,8) NULL,
		STKPLG_CMS           	numeric(38,8) NULL,
		STKPLG_NET_CMS       	numeric(38,8) NULL,
		STKPLG_PAIDINT       	numeric(38,8) NULL,
		STKPLG_RECE_INT      	numeric(38,8) NULL,
		APPTBUYB_CMS         	numeric(38,8) NULL,
		APPTBUYB_NET_CMS     	numeric(38,8) NULL,
		APPTBUYB_PAIDINT     	numeric(38,8) NULL,
		FIN_IE               	numeric(38,8) NULL,
		CRDT_STK_IE          	numeric(38,8) NULL,
		OTH_IE               	numeric(38,8) NULL,
		FEE_RECE_INT         	numeric(38,8) NULL,
		OTH_RECE_INT         	numeric(38,8) NULL,
		CREDIT_CPTL_COST     	numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_INCM_D_BRH(
		  OCCUR_DT             			--发生日期
		 ,BRH_ID               			--营业部编码
		 ,EMP_ID		 	   			--员工编码		
		 ,NET_CMS              			--净佣金
		 ,GROSS_CMS            			--毛佣金
		 ,SCDY_CMS             			--二级佣金
		 ,SCDY_NET_CMS         			--二级净佣金
		 ,SCDY_TRAN_FEE        			--二级过户费
		 ,ODI_TRD_TRAN_FEE     			--普通交易过户费
		 ,CRED_TRD_TRAN_FEE    			--信用交易过户费
		 ,STKF_CMS             			--股基佣金
		 ,STKF_TRAN_FEE        			--股基过户费
		 ,STKF_NET_CMS         			--股基净佣金
		 ,BOND_CMS             			--债券佣金
		 ,BOND_NET_CMS         			--债券净佣金
		 ,REPQ_CMS             			--报价回购佣金
		 ,REPQ_NET_CMS         			--报价回购净佣金
		 ,HGT_CMS              			--沪港通佣金
		 ,HGT_NET_CMS          			--沪港通净佣金
		 ,HGT_TRAN_FEE         			--沪港通过户费
		 ,SGT_CMS              			--深港通佣金
		 ,SGT_NET_CMS          			--深港通净佣金
		 ,SGT_TRAN_FEE         			--深港通过户费
		 ,BGDL_CMS             			--大宗交易佣金
		 ,BGDL_NET_CMS         			--大宗交易净佣金
		 ,BGDL_TRAN_FEE        			--大宗交易过户费
		 ,PSTK_OPTN_CMS        			--个股期权佣金
		 ,PSTK_OPTN_NET_CMS    			--个股期权净佣金
		 ,CREDIT_ODI_CMS       			--融资融券普通佣金
		 ,CREDIT_ODI_NET_CMS   			--融资融券普通净佣金
		 ,CREDIT_ODI_TRAN_FEE  			--融资融券普通过户费
		 ,CREDIT_CRED_CMS      			--融资融券信用佣金
		 ,CREDIT_CRED_NET_CMS  			--融资融券信用净佣金
		 ,CREDIT_CRED_TRAN_FEE 			--融资融券信用过户费
		 ,FIN_RECE_INT         			--融资应收利息
		 ,FIN_PAIDINT          			--融资实收利息
		 ,STKPLG_CMS           			--股票质押佣金
		 ,STKPLG_NET_CMS       			--股票质押净佣金
		 ,STKPLG_PAIDINT       			--股票质押实收利息
		 ,STKPLG_RECE_INT      			--股票质押应收利息
		 ,APPTBUYB_CMS         			--约定购回佣金
		 ,APPTBUYB_NET_CMS     			--约定购回净佣金
		 ,APPTBUYB_PAIDINT     			--约定购回实收利息
		 ,FIN_IE               			--融资利息支出
		 ,CRDT_STK_IE          			--融券利息支出
		 ,OTH_IE               			--其他利息支出
		 ,FEE_RECE_INT         			--费用应收利息
		 ,OTH_RECE_INT         			--其他应收利息
		 ,CREDIT_CPTL_COST     			--融资融券资金成本
	)
	SELECT 
		  T.OCCUR_DT            		AS      OCCUR_DT            		--发生日期
		 ,T1.BRH_ID              		AS      BRH_ID              		--营业部编码
		 ,T.EMP_ID		 	  			AS      EMP_ID		 	  			--员工编码		
		 ,T.NET_CMS             		AS      NET_CMS             		--净佣金
		 ,T.GROSS_CMS           		AS      GROSS_CMS           		--毛佣金
		 ,T.SCDY_CMS            		AS      SCDY_CMS            		--二级佣金
		 ,T.SCDY_NET_CMS        		AS      SCDY_NET_CMS        		--二级净佣金
		 ,T.SCDY_TRAN_FEE       		AS      SCDY_TRAN_FEE       		--二级过户费
		 ,T.ODI_TRD_TRAN_FEE    		AS      ODI_TRD_TRAN_FEE    		--普通交易过户费
		 ,T.CRED_TRD_TRAN_FEE   		AS      CRED_TRD_TRAN_FEE   		--信用交易过户费
		 ,T.STKF_CMS            		AS      STKF_CMS            		--股基佣金
		 ,T.STKF_TRAN_FEE       		AS      STKF_TRAN_FEE       		--股基过户费
		 ,T.STKF_NET_CMS        		AS      STKF_NET_CMS        		--股基净佣金
		 ,T.BOND_CMS            		AS      BOND_CMS            		--债券佣金
		 ,T.BOND_NET_CMS        		AS      BOND_NET_CMS        		--债券净佣金
		 ,T.REPQ_CMS            		AS      REPQ_CMS            		--报价回购佣金
		 ,T.REPQ_NET_CMS        		AS      REPQ_NET_CMS        		--报价回购净佣金
		 ,T.HGT_CMS             		AS      HGT_CMS             		--沪港通佣金
		 ,T.HGT_NET_CMS         		AS      HGT_NET_CMS         		--沪港通净佣金
		 ,T.HGT_TRAN_FEE        		AS      HGT_TRAN_FEE        		--沪港通过户费
		 ,T.SGT_CMS             		AS      SGT_CMS             		--深港通佣金
		 ,T.SGT_NET_CMS         		AS      SGT_NET_CMS         		--深港通净佣金
		 ,T.SGT_TRAN_FEE        		AS      SGT_TRAN_FEE        		--深港通过户费
		 ,T.BGDL_CMS            		AS      BGDL_CMS            		--大宗交易佣金
		 ,T.BGDL_NET_CMS        		AS      BGDL_NET_CMS        		--大宗交易净佣金
		 ,T.BGDL_TRAN_FEE       		AS      BGDL_TRAN_FEE       		--大宗交易过户费
		 ,T.PSTK_OPTN_CMS       		AS      PSTK_OPTN_CMS       		--个股期权佣金
		 ,T.PSTK_OPTN_NET_CMS   		AS      PSTK_OPTN_NET_CMS   		--个股期权净佣金
		 ,T.CREDIT_ODI_CMS      		AS      CREDIT_ODI_CMS      		--融资融券普通佣金
		 ,T.CREDIT_ODI_NET_CMS  		AS      CREDIT_ODI_NET_CMS  		--融资融券普通净佣金
		 ,T.CREDIT_ODI_TRAN_FEE 		AS      CREDIT_ODI_TRAN_FEE 		--融资融券普通过户费
		 ,T.CREDIT_CRED_CMS     		AS      CREDIT_CRED_CMS     		--融资融券信用佣金
		 ,T.CREDIT_CRED_NET_CMS 		AS      CREDIT_CRED_NET_CMS 		--融资融券信用净佣金
		 ,T.CREDIT_CRED_TRAN_FEE		AS      CREDIT_CRED_TRAN_FEE		--融资融券信用过户费
		 ,T.FIN_RECE_INT        		AS      FIN_RECE_INT        		--融资应收利息
		 ,T.FIN_PAIDINT         		AS      FIN_PAIDINT         		--融资实收利息
		 ,T.STKPLG_CMS          		AS      STKPLG_CMS          		--股票质押佣金
		 ,T.STKPLG_NET_CMS      		AS      STKPLG_NET_CMS      		--股票质押净佣金
		 ,T.STKPLG_PAIDINT      		AS      STKPLG_PAIDINT      		--股票质押实收利息
		 ,T.STKPLG_RECE_INT     		AS      STKPLG_RECE_INT     		--股票质押应收利息
		 ,T.APPTBUYB_CMS        		AS      APPTBUYB_CMS        		--约定购回佣金
		 ,T.APPTBUYB_NET_CMS    		AS      APPTBUYB_NET_CMS    		--约定购回净佣金
		 ,T.APPTBUYB_PAIDINT    		AS      APPTBUYB_PAIDINT    		--约定购回实收利息
		 ,T.FIN_IE              		AS      FIN_IE              		--融资利息支出
		 ,T.CRDT_STK_IE         		AS      CRDT_STK_IE         		--融券利息支出
		 ,T.OTH_IE              		AS      OTH_IE              		--其他利息支出
		 ,T.FEE_RECE_INT        		AS      FEE_RECE_INT        		--费用应收利息
		 ,T.OTH_RECE_INT        		AS      OTH_RECE_INT        		--其他应收利息
		 ,T.CREDIT_CPTL_COST    		AS      CREDIT_CPTL_COST    		--融资融券资金成本
	FROM DM.T_EVT_INCM_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE;
	
	--将临时表的按营业部维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_INCM_D_BRH (
			 OCCUR_DT            	--发生日期
			,BRH_ID              	--营业部编码		
			,NET_CMS             	--净佣金	
			,GROSS_CMS           	--毛佣金	
			,SCDY_CMS            	--二级佣金	
			,SCDY_NET_CMS        	--二级净佣金	
			,SCDY_TRAN_FEE       	--二级过户费	
			,ODI_TRD_TRAN_FEE    	--普通交易过户费	
			,CRED_TRD_TRAN_FEE   	--信用交易过户费	
			,STKF_CMS            	--股基佣金	
			,STKF_TRAN_FEE       	--股基过户费	
			,STKF_NET_CMS        	--股基净佣金	
			,BOND_CMS            	--债券佣金	
			,BOND_NET_CMS        	--债券净佣金	
			,REPQ_CMS            	--报价回购佣金	
			,REPQ_NET_CMS        	--报价回购净佣金	
			,HGT_CMS             	--沪港通佣金	
			,HGT_NET_CMS         	--沪港通净佣金	
			,HGT_TRAN_FEE        	--沪港通过户费	
			,SGT_CMS             	--深港通佣金	
			,SGT_NET_CMS         	--深港通净佣金	
			,SGT_TRAN_FEE        	--深港通过户费	
			,BGDL_CMS            	--大宗交易佣金	
			,BGDL_NET_CMS        	--大宗交易净佣金	
			,BGDL_TRAN_FEE       	--大宗交易过户费	
			,PSTK_OPTN_CMS       	--个股期权佣金	
			,PSTK_OPTN_NET_CMS   	--个股期权净佣金	
			,CREDIT_ODI_CMS      	--融资融券普通佣金	
			,CREDIT_ODI_NET_CMS  	--融资融券普通净佣金	
			,CREDIT_ODI_TRAN_FEE 	--融资融券普通过户费	
			,CREDIT_CRED_CMS     	--融资融券信用佣金	
			,CREDIT_CRED_NET_CMS 	--融资融券信用净佣金	
			,CREDIT_CRED_TRAN_FEE	--融资融券信用过户费	
			,FIN_RECE_INT        	--融资应收利息	
			,FIN_PAIDINT         	--融资实收利息	
			,STKPLG_CMS          	--股票质押佣金	
			,STKPLG_NET_CMS      	--股票质押净佣金	
			,STKPLG_PAIDINT      	--股票质押实收利息	
			,STKPLG_RECE_INT     	--股票质押应收利息	
			,APPTBUYB_CMS        	--约定购回佣金	
			,APPTBUYB_NET_CMS    	--约定购回净佣金	
			,APPTBUYB_PAIDINT    	--约定购回实收利息	
			,FIN_IE              	--融资利息支出	
			,CRDT_STK_IE         	--融券利息支出	
			,OTH_IE              	--其他利息支出	
			,FEE_RECE_INT        	--费用应收利息	
			,OTH_RECE_INT        	--其他应收利息	
			,CREDIT_CPTL_COST      	--融资融券资金成本						
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              --发生日期		
			,BRH_ID									AS    BRH_ID                --营业部编码	
			,SUM(NET_CMS)							AS 	  NET_CMS             	--净佣金				
			,SUM(GROSS_CMS)							AS 	  GROSS_CMS           	--毛佣金		
			,SUM(SCDY_CMS)							AS 	  SCDY_CMS            	--二级佣金		
			,SUM(SCDY_NET_CMS)						AS 	  SCDY_NET_CMS        	--二级净佣金			
			,SUM(SCDY_TRAN_FEE)						AS 	  SCDY_TRAN_FEE       	--二级过户费			
			,SUM(ODI_TRD_TRAN_FEE)					AS 	  ODI_TRD_TRAN_FEE    	--普通交易过户费				
			,SUM(CRED_TRD_TRAN_FEE)					AS 	  CRED_TRD_TRAN_FEE   	--信用交易过户费				
			,SUM(STKF_CMS)							AS 	  STKF_CMS            	--股基佣金		
			,SUM(STKF_TRAN_FEE)						AS 	  STKF_TRAN_FEE       	--股基过户费			
			,SUM(STKF_NET_CMS)						AS 	  STKF_NET_CMS        	--股基净佣金			
			,SUM(BOND_CMS)							AS 	  BOND_CMS            	--债券佣金		
			,SUM(BOND_NET_CMS)						AS 	  BOND_NET_CMS        	--债券净佣金			
			,SUM(REPQ_CMS)							AS 	  REPQ_CMS            	--报价回购佣金		
			,SUM(REPQ_NET_CMS)						AS 	  REPQ_NET_CMS        	--报价回购净佣金			
			,SUM(HGT_CMS)							AS 	  HGT_CMS             	--沪港通佣金		
			,SUM(HGT_NET_CMS)						AS 	  HGT_NET_CMS         	--沪港通净佣金			
			,SUM(HGT_TRAN_FEE)						AS 	  HGT_TRAN_FEE        	--沪港通过户费			
			,SUM(SGT_CMS)							AS 	  SGT_CMS             	--深港通佣金		
			,SUM(SGT_NET_CMS)						AS 	  SGT_NET_CMS         	--深港通净佣金			
			,SUM(SGT_TRAN_FEE)						AS 	  SGT_TRAN_FEE        	--深港通过户费			
			,SUM(BGDL_CMS)							AS 	  BGDL_CMS            	--大宗交易佣金		
			,SUM(BGDL_NET_CMS)						AS 	  BGDL_NET_CMS        	--大宗交易净佣金			
			,SUM(BGDL_TRAN_FEE)						AS 	  BGDL_TRAN_FEE       	--大宗交易过户费			
			,SUM(PSTK_OPTN_CMS)						AS 	  PSTK_OPTN_CMS       	--个股期权佣金			
			,SUM(PSTK_OPTN_NET_CMS)					AS 	  PSTK_OPTN_NET_CMS   	--个股期权净佣金				
			,SUM(CREDIT_ODI_CMS)					AS 	  CREDIT_ODI_CMS      	--融资融券普通佣金				
			,SUM(CREDIT_ODI_NET_CMS)				AS 	  CREDIT_ODI_NET_CMS  	--融资融券普通净佣金					
			,SUM(CREDIT_ODI_TRAN_FEE)				AS 	  CREDIT_ODI_TRAN_FEE 	--融资融券普通过户费					
			,SUM(CREDIT_CRED_CMS)					AS 	  CREDIT_CRED_CMS     	--融资融券信用佣金				
			,SUM(CREDIT_CRED_NET_CMS)				AS 	  CREDIT_CRED_NET_CMS 	--融资融券信用净佣金					
			,SUM(CREDIT_CRED_TRAN_FEE)				AS 	  CREDIT_CRED_TRAN_FEE	--融资融券信用过户费					
			,SUM(FIN_RECE_INT)						AS 	  FIN_RECE_INT        	--融资应收利息			
			,SUM(FIN_PAIDINT)						AS 	  FIN_PAIDINT         	--融资实收利息			
			,SUM(STKPLG_CMS)						AS 	  STKPLG_CMS          	--股票质押佣金			
			,SUM(STKPLG_NET_CMS)					AS 	  STKPLG_NET_CMS      	--股票质押净佣金				
			,SUM(STKPLG_PAIDINT)					AS 	  STKPLG_PAIDINT      	--股票质押实收利息				
			,SUM(STKPLG_RECE_INT)					AS 	  STKPLG_RECE_INT     	--股票质押应收利息				
			,SUM(APPTBUYB_CMS)						AS 	  APPTBUYB_CMS        	--约定购回佣金			
			,SUM(APPTBUYB_NET_CMS)					AS 	  APPTBUYB_NET_CMS    	--约定购回净佣金				
			,SUM(APPTBUYB_PAIDINT)					AS 	  APPTBUYB_PAIDINT    	--约定购回实收利息				
			,SUM(FIN_IE)							AS 	  FIN_IE              	--融资利息支出		
			,SUM(CRDT_STK_IE)						AS 	  CRDT_STK_IE         	--融券利息支出			
			,SUM(OTH_IE)							AS 	  OTH_IE              	--其他利息支出		
			,SUM(FEE_RECE_INT)						AS 	  FEE_RECE_INT        	--费用应收利息			
			,SUM(OTH_RECE_INT)						AS 	  OTH_RECE_INT        	--其他应收利息			
			,SUM(CREDIT_CPTL_COST)					AS 	  CREDIT_CPTL_COST      --融资融券资金成本							
		FROM #TMP_T_EVT_INCM_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
