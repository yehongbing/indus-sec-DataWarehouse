CREATE PROCEDURE DM.P_EVT_INCM_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 员工收入事实表（日表）
  编写者: 叶宏冰
  创建日期: 2018-04-11
  简介：员工收入统计
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
  *********************************************************************/

	DELETE FROM DM.T_EVT_INCM_D_EMP WHERE OCCUR_DT = @V_DATE;

	-- 1.1 在T_EVT_TRD_D_EMP的基础上增加资金账号（客户号）字段来创建临时表（为了取责权分配后的金额然后再根据员工维度汇总分配后的金额）

	CREATE TABLE #TMP_T_EVT_INCM_D_EMP(
			OCCUR_DT             numeric(8,0) NOT NULL,		--发生日期
			EMP_ID               varchar(30) NOT NULL,		--员工编码
			MAIN_CPTL_ACCT		 varchar(30) NOT NULL,		--资金账号
			NET_CMS              numeric(38,8) NULL,		--净佣金
			GROSS_CMS            numeric(38,8) NULL,		--毛佣金
			SCDY_CMS             numeric(38,8) NULL,		--二级佣金
			SCDY_NET_CMS         numeric(38,8) NULL,		--二级净佣金
			SCDY_TRAN_FEE        numeric(38,8) NULL,		--二级过户费
			ODI_TRD_TRAN_FEE     numeric(38,8) NULL,		--普通交易过户费
			ODI_TRD_STP_TAX      numeric(38,8) NULL,		--普通交易印花税
			ODI_TRD_HANDLE_FEE   numeric(38,8) NULL,		--普通交易经手费
			ODI_TRD_SEC_RGLT_FEE numeric(38,8) NULL,		--普通交易证管费 
			ODI_TRD_ORDR_FEE     numeric(38,8) NULL,		--普通交易委托费
			ODI_TRD_OTH_FEE      numeric(38,8) NULL,		--普通交易其他费用
			CRED_TRD_TRAN_FEE    numeric(38,8) NULL,		--信用交易过户费
			CRED_TRD_STP_TAX     numeric(38,8) NULL,		--信用交易印花税
			CRED_TRD_HANDLE_FEE  numeric(38,8) NULL,		--信用交易经手费
			CRED_TRD_SEC_RGLT_FEE numeric(38,8) NULL,		--信用交易证管费
			CRED_TRD_ORDR_FEE    numeric(38,8) NULL,		--信用交易委托费
			CRED_TRD_OTH_FEE     numeric(38,8) NULL,		--信用交易其他费用
			STKF_CMS             numeric(38,8) NULL,		--股基佣金
			STKF_TRAN_FEE        numeric(38,8) NULL,		--股基过户费
			STKF_NET_CMS         numeric(38,8) NULL,		--股基净佣金
			BOND_CMS             numeric(38,8) NULL,		--债券佣金
			BOND_NET_CMS         numeric(38,8) NULL,		--债券净佣金
			REPQ_CMS             numeric(38,8) NULL,		--报价回购佣金
			REPQ_NET_CMS         numeric(38,8) NULL,		--报价回购净佣金
			HGT_CMS              numeric(38,8) NULL,		--沪港通佣金
			HGT_NET_CMS          numeric(38,8) NULL,		--沪港通净佣金
			HGT_TRAN_FEE         numeric(38,8) NULL,		--沪港通过户费
			SGT_CMS              numeric(38,8) NULL,		--深港通佣金
			SGT_NET_CMS          numeric(38,8) NULL,		--深港通净佣金
			SGT_TRAN_FEE         numeric(38,8) NULL,		--深港通过户费
			BGDL_CMS             numeric(38,8) NULL,		--大宗交易佣金
			BGDL_NET_CMS         numeric(38,8) NULL,		--大宗交易净佣金
			BGDL_TRAN_FEE        numeric(38,8) NULL,		--大宗交易过户费
			PSTK_OPTN_CMS        numeric(38,8) NULL,		--个股期权佣金
			PSTK_OPTN_NET_CMS    numeric(38,8) NULL,		--个股期权净佣金
			CREDIT_ODI_CMS       numeric(38,8) NULL,		--融资融券普通佣金
			CREDIT_ODI_NET_CMS   numeric(38,8) NULL,		--融资融券普通净佣金
			CREDIT_ODI_TRAN_FEE  numeric(38,8) NULL,		--融资融券普通过户费
			CREDIT_CRED_CMS      numeric(38,8) NULL,		--融资融券信用佣金
			CREDIT_CRED_NET_CMS  numeric(38,8) NULL,		--融资融券信用净佣金
			CREDIT_CRED_TRAN_FEE numeric(38,8) NULL,		--融资融券信用过户费
			FIN_RECE_INT         numeric(38,8) NULL,		--融资应收利息
			FIN_PAIDINT          numeric(38,8) NULL,		--融资实收利息
			STKPLG_CMS           numeric(38,8) NULL,		--股票质押佣金
			STKPLG_NET_CMS       numeric(38,8) NULL,		--股票质押净佣金
			STKPLG_PAIDINT       numeric(38,8) NULL,		--股票质押实收利息
			STKPLG_RECE_INT      numeric(38,8) NULL,		--股票质押应收利息
			APPTBUYB_CMS         numeric(38,8) NULL,		--约定购回佣金
			APPTBUYB_NET_CMS     numeric(38,8) NULL,		--约定购回净佣金
			APPTBUYB_PAIDINT     numeric(38,8) NULL,		--约定购回实收利息
			FIN_IE               numeric(38,8) NULL,		--融资利息支出
			CRDT_STK_IE          numeric(38,8) NULL,		--融券利息支出
			OTH_IE               numeric(38,8) NULL,		--其他利息支出
			FEE_RECE_INT         numeric(38,8) NULL,		--费用应收利息
			OTH_RECE_INT         numeric(38,8) NULL,		--其他应收利息
			CREDIT_CPTL_COST     numeric(38,8) NULL			--融资融券资金成本
	);

	INSERT INTO #TMP_T_EVT_INCM_D_EMP(
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
	UPDATE #TMP_T_EVT_INCM_D_EMP
		SET 
			 NET_CMS              	=  	COALESCE(B1.NET_CMS,0)					* 	C.PERFM_RATIO_4		--净佣金				
			,GROSS_CMS            	=  	COALESCE(B1.GROSS_CMS,0)				* 	C.PERFM_RATIO_4		--毛佣金				
			,SCDY_CMS             	=  	COALESCE(B1.SCDY_CMS,0)					* 	C.PERFM_RATIO_4		--二级佣金				
			,SCDY_NET_CMS         	=  	COALESCE(B1.SCDY_NET_CMS,0)				* 	C.PERFM_RATIO_4		--二级净佣金				
			,SCDY_TRAN_FEE        	=  	COALESCE(B1.SCDY_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--二级过户费				
			,ODI_TRD_TRAN_FEE     	=  	COALESCE(B1.ODI_TRD_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--普通交易过户费				
			,ODI_TRD_STP_TAX      	=  	COALESCE(B1.ODI_TRD_STP_TAX,0)			* 	C.PERFM_RATIO_4		--普通交易印花税				
			,ODI_TRD_HANDLE_FEE   	=  	COALESCE(B1.ODI_TRD_HANDLE_FEE,0)		* 	C.PERFM_RATIO_4		--普通交易经手费					
			,ODI_TRD_SEC_RGLT_FEE 	=  	COALESCE(B1.ODI_TRD_SEC_RGLT_FEE,0)		* 	C.PERFM_RATIO_4		--普通交易证管费 					
			,ODI_TRD_ORDR_FEE     	=  	COALESCE(B1.ODI_TRD_ORDR_FEE,0)			* 	C.PERFM_RATIO_4		--普通交易委托费				
			,ODI_TRD_OTH_FEE      	=  	COALESCE(B1.ODI_TRD_OTH_FEE,0)			* 	C.PERFM_RATIO_4		--普通交易其他费用					
			,CRED_TRD_TRAN_FEE    	=  	COALESCE(B2.CRED_TRD_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--信用交易过户费					
			,CRED_TRD_STP_TAX     	=  	COALESCE(B2.CRED_TRD_STP_TAX,0)			* 	C.PERFM_RATIO_4		--信用交易印花税				
			,CRED_TRD_HANDLE_FEE  	=  	COALESCE(B2.CRED_TRD_HANDLE_FEE,0)		* 	C.PERFM_RATIO_4		--信用交易经手费					
			,CRED_TRD_SEC_RGLT_FEE	=  	COALESCE(B2.CRED_TRD_SEC_RGLT_FEE,0)	* 	C.PERFM_RATIO_4		--信用交易证管费						
			,CRED_TRD_ORDR_FEE    	=  	COALESCE(B2.CRED_TRD_ORDR_FEE,0)		* 	C.PERFM_RATIO_4		--信用交易委托费					
			,CRED_TRD_OTH_FEE     	=  	COALESCE(B2.CRED_TRD_OTH_FEE,0)			* 	C.PERFM_RATIO_4		--信用交易其他费用					
			,STKF_CMS             	=  	COALESCE(B1.STKF_CMS,0)					* 	C.PERFM_RATIO_4		--股基佣金				
			,STKF_TRAN_FEE        	=  	COALESCE(B1.STKF_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--股基过户费				
			,STKF_NET_CMS         	=  	COALESCE(B1.STKF_NET_CMS,0)				* 	C.PERFM_RATIO_4		--股基净佣金				
			,BOND_CMS             	=  	COALESCE(B1.BOND_CMS,0)					* 	C.PERFM_RATIO_4		--债券佣金				
			,BOND_NET_CMS         	=  	COALESCE(B1.BOND_NET_CMS,0)				* 	C.PERFM_RATIO_4		--债券净佣金				
			,REPQ_CMS             	=  	COALESCE(B1.REPQ_CMS,0)					* 	C.PERFM_RATIO_4		--报价回购佣金				
			,REPQ_NET_CMS         	=  	COALESCE(B1.REPQ_NET_CMS,0)				* 	C.PERFM_RATIO_4		--报价回购净佣金				
			,HGT_CMS              	=  	COALESCE(B1.HGT_CMS,0)					* 	C.PERFM_RATIO_4		--沪港通佣金				
			,HGT_NET_CMS          	=  	COALESCE(B1.HGT_NET_CMS,0)				* 	C.PERFM_RATIO_4		--沪港通净佣金				
			,HGT_TRAN_FEE         	=  	COALESCE(B1.HGT_TRAN_FEE,0)				* 	C.PERFM_RATIO_4		--沪港通过户费				
			,SGT_CMS              	=  	COALESCE(B1.SGT_CMS,0)					* 	C.PERFM_RATIO_4		--深港通佣金				
			,SGT_NET_CMS          	=  	COALESCE(B1.SGT_NET_CMS,0)				* 	C.PERFM_RATIO_4		--深港通净佣金				
			,SGT_TRAN_FEE         	=  	COALESCE(B1.SGT_TRAN_FEE,0)				* 	C.PERFM_RATIO_4		--深港通过户费				
			,BGDL_CMS             	=  	COALESCE(B1.BGDL_CMS,0)					* 	C.PERFM_RATIO_4		--大宗交易佣金				
			,BGDL_NET_CMS         	=  	COALESCE(B1.BGDL_NET_CMS,0)				* 	C.PERFM_RATIO_4		--大宗交易净佣金				
			,BGDL_TRAN_FEE        	=  	COALESCE(B1.BGDL_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--大宗交易过户费				
			,PSTK_OPTN_CMS        	=  	COALESCE(B1.PSTK_OPTN_CMS,0)			* 	C.PERFM_RATIO_4		--个股期权佣金				
			,PSTK_OPTN_NET_CMS    	=  	COALESCE(B1.PSTK_OPTN_NET_CMS,0)		* 	C.PERFM_RATIO_4		--个股期权净佣金					
			,CREDIT_ODI_CMS       	=  	COALESCE(B2.CREDIT_ODI_CMS,0)			* 	C.PERFM_RATIO_4		--融资融券普通佣金				
			,CREDIT_ODI_NET_CMS   	=  	COALESCE(B2.CREDIT_ODI_NET_CMS,0)		* 	C.PERFM_RATIO_4		--融资融券普通净佣金						
			,CREDIT_ODI_TRAN_FEE  	=  	COALESCE(B2.CREDIT_ODI_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--融资融券普通过户费						
			,CREDIT_CRED_CMS      	=  	COALESCE(B2.CREDIT_CRED_CMS,0)			* 	C.PERFM_RATIO_4		--融资融券信用佣金					
			,CREDIT_CRED_NET_CMS  	=  	COALESCE(B2.CREDIT_CRED_NET_CMS,0)		* 	C.PERFM_RATIO_4		--融资融券信用净佣金						
			,CREDIT_CRED_TRAN_FEE 	=  	COALESCE(B2.CREDIT_CRED_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--融资融券信用过户费					
			,FIN_RECE_INT         	=  	COALESCE(B2.FIN_RECE_INT,0)				* 	C.PERFM_RATIO_4		--融资应收利息				
			,FIN_PAIDINT          	=  	COALESCE(B2.FIN_PAIDINT,0)				* 	C.PERFM_RATIO_4		--融资实收利息				
			,STKPLG_CMS           	=  	COALESCE(B2.STKPLG_CMS,0)				* 	C.PERFM_RATIO_4		--股票质押佣金				
			,STKPLG_NET_CMS       	=  	COALESCE(B2.STKPLG_NET_CMS,0)			* 	C.PERFM_RATIO_4		--股票质押净佣金				
			,STKPLG_PAIDINT       	=  	COALESCE(B2.STKPLG_PAIDINT,0)			* 	C.PERFM_RATIO_4		--股票质押实收利息				
			,STKPLG_RECE_INT      	=  	COALESCE(B2.STKPLG_RECE_INT,0)			* 	C.PERFM_RATIO_4		--股票质押应收利息					
			,APPTBUYB_CMS         	=  	COALESCE(B2.APPTBUYB_CMS,0)				* 	C.PERFM_RATIO_4		--约定购回佣金				
			,APPTBUYB_NET_CMS     	=  	COALESCE(B2.APPTBUYB_NET_CMS,0)			* 	C.PERFM_RATIO_4		--约定购回净佣金				
			,APPTBUYB_PAIDINT     	=  	COALESCE(B2.APPTBUYB_PAIDINT,0)			* 	C.PERFM_RATIO_4		--约定购回实收利息					
			,FIN_IE               	=  	COALESCE(B2.FIN_IE,0)					* 	C.PERFM_RATIO_4		--融资利息支出				
			,CRDT_STK_IE          	=  	COALESCE(B2.CRDT_STK_IE,0)				* 	C.PERFM_RATIO_4		--融券利息支出				
			,OTH_IE               	=  	COALESCE(B2.OTH_IE,0)					* 	C.PERFM_RATIO_4		--其他利息支出				
			,FEE_RECE_INT         	=  	COALESCE(B2.FEE_RECE_INT,0)				* 	C.PERFM_RATIO_4		--费用应收利息				
			,OTH_RECE_INT         	=  	COALESCE(B2.OTH_RECE_INT,0)				* 	C.PERFM_RATIO_4		--其他应收利息				
			,CREDIT_CPTL_COST     	=  	COALESCE(B2.CREDIT_CPTL_COST,0)			* 	C.PERFM_RATIO_4		--融资融券资金成本									
		FROM #TMP_T_EVT_INCM_D_EMP A
		--关联客户普通交易日表
		LEFT JOIN (
				SELECT
					 T.MAIN_CPTL_ACCT  			AS 		MAIN_CPTL_ACCT			--资金账号
					,T.NET_CMS					AS 		NET_CMS             	--净佣金	
					,T.GROSS_CMS				AS 		GROSS_CMS           	--毛佣金	
					,T.SCDY_CMS					AS 		SCDY_CMS            	--二级佣金	
					,T.SCDY_NET_CMS				AS 		SCDY_NET_CMS        	--二级净佣金		
					,T.SCDY_TRAN_FEE			AS 		SCDY_TRAN_FEE       	--二级过户费		
					,T.TRAN_FEE					AS 		ODI_TRD_TRAN_FEE    	--普通交易过户费	
					,T.STP_TAX					AS 		ODI_TRD_STP_TAX     	--普通交易印花税	
					,T.HANDLE_FEE				AS 		ODI_TRD_HANDLE_FEE  	--普通交易经手费		
					,T.SEC_RGLT_FEE				AS 		ODI_TRD_SEC_RGLT_FEE	--普通交易证管费 		
					,T.ORDR_FEE					AS 		ODI_TRD_ORDR_FEE    	--普通交易委托费	
					,T.OTH_FEE					AS 		ODI_TRD_OTH_FEE     	--普通交易其他费用	
					,T.STKF_CMS					AS 		STKF_CMS         		--股基佣金
					,T.STKF_TRAN_FEE			AS 		STKF_TRAN_FEE    		--股基过户费	
					,T.STKF_NET_CMS				AS 		STKF_NET_CMS     		--股基净佣金	
					,T.BOND_CMS					AS 		BOND_CMS         		--债券佣金
					,T.BOND_NET_CMS				AS 		BOND_NET_CMS     		--债券净佣金	
					,T.REPQ_CMS					AS 		REPQ_CMS         		--报价回购佣金
					,T.REPQ_NET_CMS				AS 		REPQ_NET_CMS     		--报价回购净佣金	
					,T.HGT_CMS     				AS 		HGT_CMS          		--沪港通佣金	
					,T.HGT_NET_CMS 				AS 		HGT_NET_CMS      		--沪港通净佣金	
					,T.HGT_TRAN_FEE				AS 		HGT_TRAN_FEE     		--沪港通过户费	
					,T.SGT_CMS     				AS 		SGT_CMS          		--深港通佣金	
					,T.SGT_NET_CMS 				AS 		SGT_NET_CMS      		--深港通净佣金	
					,T.SGT_TRAN_FEE				AS 		SGT_TRAN_FEE     		--深港通过户费	
					,T.BGDL_CMS    				AS 		BGDL_CMS         		--大宗交易佣金	
					,T.BGDL_NET_CMS 			AS 		BGDL_NET_CMS     		--大宗交易净佣金	
					,T.BGDL_TRAN_FEE			AS 		BGDL_TRAN_FEE    		--大宗交易过户费	
					,T.PSTK_OPTN_CMS    		AS 		PSTK_OPTN_CMS    		--个股期权佣金		
					,T.PSTK_OPTN_NET_CMS		AS 		PSTK_OPTN_NET_CMS		--个股期权净佣金		
				FROM DM.T_EVT_ODI_INCM_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B1 ON A.MAIN_CPTL_ACCT=B.MAIN_CPTL_ACCT
		LEFT JOIN (
				SELECT
					 T.MAIN_CPTL_ACCT 			AS 		MAIN_CPTL_ACCT			--资金账号			
					,T.TRAN_FEE    				AS     	CRED_TRD_TRAN_FEE    	--信用交易过户费					
					,T.STP_TAX     				AS     	CRED_TRD_STP_TAX     	--信用交易印花税					
					,T.HANDLE_FEE  				AS     	CRED_TRD_HANDLE_FEE  	--信用交易经手费					
					,T.SEC_RGLT_FEE				AS     	CRED_TRD_SEC_RGLT_FEE	--信用交易证管费					
					,T.ORDR_FEE    				AS     	CRED_TRD_ORDR_FEE    	--信用交易委托费					
					,T.OTH_FEE     				AS     	CRED_TRD_OTH_FEE     	--信用交易其他费用					
					,T.CREDIT_ODI_CMS    		AS     	CREDIT_ODI_CMS      	--融资融券普通佣金							
					,T.CREDIT_ODI_NET_CMS		AS     	CREDIT_ODI_NET_CMS  	--融资融券普通净佣金							
					,T.CREDIT_ODI_TRAN_FE		AS     	CREDIT_ODI_TRAN_FEE 	--融资融券普通过户费							
					,T.CREDIT_CRED_CMS   		AS     	CREDIT_CRED_CMS     	--融资融券信用佣金							
					,T.CREDIT_CRED_NET_CM		AS     	CREDIT_CRED_NET_CMS 	--融资融券信用净佣金							
					,T.CREDIT_CRED_TRAN_F		AS     	CREDIT_CRED_TRAN_FEE	--融资融券信用过户费							
					,T.FIN_RECE_INT				AS     	FIN_RECE_INT        	--融资应收利息					
					,T.FIN_PAIDINT 				AS     	FIN_PAIDINT         	--融资实收利息					
					,T.STKPLG_CMS     			AS     	STKPLG_CMS          	--股票质押佣金						
					,T.STKPLG_NET_CMS 			AS     	STKPLG_NET_CMS      	--股票质押净佣金						
					,T.STKPLG_PAIDINT 			AS     	STKPLG_PAIDINT      	--股票质押实收利息						
					,T.STKPLG_RECE_INT			AS     	STKPLG_RECE_INT     	--股票质押应收利息						
					,T.APPTBUYB_CMS    			AS     	APPTBUYB_CMS        	--约定购回佣金						
					,T.APPTBUYB_NET_CMS			AS     	APPTBUYB_NET_CMS    	--约定购回净佣金						
					,T.APPTBUYB_PAIDINT			AS     	APPTBUYB_PAIDINT    	--约定购回实收利息						
					,T.FIN_IE     				AS     	FIN_IE              	--融资利息支出					
					,T.CRDT_STK_IE				AS     	CRDT_STK_IE         	--融券利息支出					
					,T.OTH_IE     				AS     	OTH_IE              	--其他利息支出					
					,T.DAY_FIN_RECE_INT			AS     	FEE_RECE_INT        	--费用应收利息						
					,T.DAY_FEE_RECE_INT			AS     	OTH_RECE_INT        	--其他应收利息						
					,T.DAY_OTH_RECE_INT			AS     	CREDIT_CPTL_COST    	--融资融券资金成本							
				FROM DM.T_EVT_CRED_INCM_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B2 ON A.MAIN_CPTL_ACCT=B.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--将临时表的按员工维度汇总各项指标金额并插入到目标表
	INSERT INTO DM.T_EVT_INCM_D_EMP (
			 OCCUR_DT            	 	--发生日期
			,EMP_ID               		--员工编码
			,NET_CMS              		--净佣金
			,GROSS_CMS            		--毛佣金
			,SCDY_CMS             		--二级佣金
			,SCDY_NET_CMS         		--二级净佣金
			,SCDY_TRAN_FEE        		--二级过户费
			,ODI_TRD_TRAN_FEE     		--普通交易过户费
			,ODI_TRD_STP_TAX      		--普通交易印花税
			,ODI_TRD_HANDLE_FEE   		--普通交易经手费
			,ODI_TRD_SEC_RGLT_FEE 		--普通交易证管费 
			,ODI_TRD_ORDR_FEE     		--普通交易委托费
			,ODI_TRD_OTH_FEE      		--普通交易其他费用
			,CRED_TRD_TRAN_FEE    		--信用交易过户费
			,CRED_TRD_STP_TAX     		--信用交易印花税
			,CRED_TRD_HANDLE_FEE  		--信用交易经手费
			,CRED_TRD_SEC_RGLT_FEE		--信用交易证管费
			,CRED_TRD_ORDR_FEE    		--信用交易委托费
			,CRED_TRD_OTH_FEE     		--信用交易其他费用
			,STKF_CMS             		--股基佣金
			,STKF_TRAN_FEE        		--股基过户费
			,STKF_NET_CMS         		--股基净佣金
			,BOND_CMS             		--债券佣金
			,BOND_NET_CMS         		--债券净佣金
			,REPQ_CMS             		--报价回购佣金
			,REPQ_NET_CMS         		--报价回购净佣金
			,HGT_CMS              		--沪港通佣金
			,HGT_NET_CMS          		--沪港通净佣金
			,HGT_TRAN_FEE         		--沪港通过户费
			,SGT_CMS              		--深港通佣金
			,SGT_NET_CMS          		--深港通净佣金
			,SGT_TRAN_FEE         		--深港通过户费
			,BGDL_CMS             		--大宗交易佣金
			,BGDL_NET_CMS         		--大宗交易净佣金
			,BGDL_TRAN_FEE        		--大宗交易过户费
			,PSTK_OPTN_CMS        		--个股期权佣金
			,PSTK_OPTN_NET_CMS    		--个股期权净佣金
			,CREDIT_ODI_CMS       		--融资融券普通佣金
			,CREDIT_ODI_NET_CMS   		--融资融券普通净佣金
			,CREDIT_ODI_TRAN_FEE  		--融资融券普通过户费
			,CREDIT_CRED_CMS      		--融资融券信用佣金
			,CREDIT_CRED_NET_CMS  		--融资融券信用净佣金
			,CREDIT_CRED_TRAN_FEE 		--融资融券信用过户费
			,FIN_RECE_INT         		--融资应收利息
			,FIN_PAIDINT          		--融资实收利息
			,STKPLG_CMS           		--股票质押佣金
			,STKPLG_NET_CMS       		--股票质押净佣金
			,STKPLG_PAIDINT       		--股票质押实收利息
			,STKPLG_RECE_INT      		--股票质押应收利息
			,APPTBUYB_CMS         		--约定购回佣金
			,APPTBUYB_NET_CMS     		--约定购回净佣金
			,APPTBUYB_PAIDINT     		--约定购回实收利息
			,FIN_IE               		--融资利息支出
			,CRDT_STK_IE          		--融券利息支出
			,OTH_IE               		--其他利息支出
			,FEE_RECE_INT         		--费用应收利息
			,OTH_RECE_INT         		--其他应收利息
			,CREDIT_CPTL_COST     		--融资融券资金成本
		)
		SELECT 
			 OCCUR_DT            			AS     OCCUR_DT            	 	--发生日期
			,EMP_ID               			AS     EMP_ID               	--员工编码
			,SUM(NET_CMS)              		AS     NET_CMS              	--净佣金
			,SUM(GROSS_CMS)            		AS     GROSS_CMS            	--毛佣金
			,SUM(SCDY_CMS)             		AS     SCDY_CMS             	--二级佣金
			,SUM(SCDY_NET_CMS)         		AS     SCDY_NET_CMS         	--二级净佣金
			,SUM(SCDY_TRAN_FEE)        		AS     SCDY_TRAN_FEE        	--二级过户费
			,SUM(ODI_TRD_TRAN_FEE)     		AS     ODI_TRD_TRAN_FEE     	--普通交易过户费
			,SUM(ODI_TRD_STP_TAX)      		AS     ODI_TRD_STP_TAX      	--普通交易印花税
			,SUM(ODI_TRD_HANDLE_FEE)   		AS     ODI_TRD_HANDLE_FEE   	--普通交易经手费
			,SUM(ODI_TRD_SEC_RGLT_FEE) 		AS     ODI_TRD_SEC_RGLT_FEE 	--普通交易证管费 
			,SUM(ODI_TRD_ORDR_FEE)     		AS     ODI_TRD_ORDR_FEE     	--普通交易委托费
			,SUM(ODI_TRD_OTH_FEE)      		AS     ODI_TRD_OTH_FEE      	--普通交易其他费用
			,SUM(CRED_TRD_TRAN_FEE)    		AS     CRED_TRD_TRAN_FEE    	--信用交易过户费
			,SUM(CRED_TRD_STP_TAX)     		AS     CRED_TRD_STP_TAX     	--信用交易印花税
			,SUM(CRED_TRD_HANDLE_FEE)  		AS     CRED_TRD_HANDLE_FEE  	--信用交易经手费
			,SUM(CRED_TRD_SEC_RGLT_FEE)		AS     CRED_TRD_SEC_RGLT_FEE	--信用交易证管费
			,SUM(CRED_TRD_ORDR_FEE)    		AS     CRED_TRD_ORDR_FEE    	--信用交易委托费
			,SUM(CRED_TRD_OTH_FEE)     		AS     CRED_TRD_OTH_FEE     	--信用交易其他费用
			,SUM(STKF_CMS)             		AS     STKF_CMS             	--股基佣金
			,SUM(STKF_TRAN_FEE)        		AS     STKF_TRAN_FEE        	--股基过户费
			,SUM(STKF_NET_CMS)         		AS     STKF_NET_CMS         	--股基净佣金
			,SUM(BOND_CMS)             		AS     BOND_CMS             	--债券佣金
			,SUM(BOND_NET_CMS)         		AS     BOND_NET_CMS         	--债券净佣金
			,SUM(REPQ_CMS)             		AS     REPQ_CMS             	--报价回购佣金
			,SUM(REPQ_NET_CMS)         		AS     REPQ_NET_CMS         	--报价回购净佣金
			,SUM(HGT_CMS)              		AS     HGT_CMS              	--沪港通佣金
			,SUM(HGT_NET_CMS)          		AS     HGT_NET_CMS          	--沪港通净佣金
			,SUM(HGT_TRAN_FEE)         		AS     HGT_TRAN_FEE         	--沪港通过户费
			,SUM(SGT_CMS)              		AS     SGT_CMS              	--深港通佣金
			,SUM(SGT_NET_CMS)          		AS     SGT_NET_CMS          	--深港通净佣金
			,SUM(SGT_TRAN_FEE)         		AS     SGT_TRAN_FEE         	--深港通过户费
			,SUM(BGDL_CMS)             		AS     BGDL_CMS             	--大宗交易佣金
			,SUM(BGDL_NET_CMS)         		AS     BGDL_NET_CMS         	--大宗交易净佣金
			,SUM(BGDL_TRAN_FEE)        		AS     BGDL_TRAN_FEE        	--大宗交易过户费
			,SUM(PSTK_OPTN_CMS)        		AS     PSTK_OPTN_CMS        	--个股期权佣金
			,SUM(PSTK_OPTN_NET_CMS)    		AS     PSTK_OPTN_NET_CMS    	--个股期权净佣金
			,SUM(CREDIT_ODI_CMS)       		AS     CREDIT_ODI_CMS       	--融资融券普通佣金
			,SUM(CREDIT_ODI_NET_CMS)   		AS     CREDIT_ODI_NET_CMS   	--融资融券普通净佣金
			,SUM(CREDIT_ODI_TRAN_FEE)  		AS     CREDIT_ODI_TRAN_FEE  	--融资融券普通过户费
			,SUM(CREDIT_CRED_CMS)      		AS     CREDIT_CRED_CMS      	--融资融券信用佣金
			,SUM(CREDIT_CRED_NET_CMS)  		AS     CREDIT_CRED_NET_CMS  	--融资融券信用净佣金
			,SUM(CREDIT_CRED_TRAN_FEE) 		AS     CREDIT_CRED_TRAN_FEE 	--融资融券信用过户费
			,SUM(FIN_RECE_INT)         		AS     FIN_RECE_INT         	--融资应收利息
			,SUM(FIN_PAIDINT)          		AS     FIN_PAIDINT          	--融资实收利息
			,SUM(STKPLG_CMS)           		AS     STKPLG_CMS           	--股票质押佣金
			,SUM(STKPLG_NET_CMS)       		AS     STKPLG_NET_CMS       	--股票质押净佣金
			,SUM(STKPLG_PAIDINT)       		AS     STKPLG_PAIDINT       	--股票质押实收利息
			,SUM(STKPLG_RECE_INT)      		AS     STKPLG_RECE_INT      	--股票质押应收利息
			,SUM(APPTBUYB_CMS)         		AS     APPTBUYB_CMS         	--约定购回佣金
			,SUM(APPTBUYB_NET_CMS)     		AS     APPTBUYB_NET_CMS     	--约定购回净佣金
			,SUM(APPTBUYB_PAIDINT)     		AS     APPTBUYB_PAIDINT     	--约定购回实收利息
			,SUM(FIN_IE)               		AS     FIN_IE               	--融资利息支出
			,SUM(CRDT_STK_IE)          		AS     CRDT_STK_IE          	--融券利息支出
			,SUM(OTH_IE)               		AS     OTH_IE               	--其他利息支出
			,SUM(FEE_RECE_INT)         		AS     FEE_RECE_INT         	--费用应收利息
			,SUM(OTH_RECE_INT)         		AS     OTH_RECE_INT         	--其他应收利息
			,SUM(CREDIT_CPTL_COST)     		AS     CREDIT_CPTL_COST     	--融资融券资金成本		
		FROM #TMP_T_EVT_INCM_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
