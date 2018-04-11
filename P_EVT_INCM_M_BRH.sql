CREATE PROCEDURE DM.P_EVT_INCM_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  程序功能: 营业部收入事实表（月表）
  编写者: 叶宏冰
  创建日期: 2018-04-11
  简介：营业部收入统计
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

	DELETE FROM DM.T_EVT_INCM_M_BRH WHERE OCCUR_DT = @V_DATE;

	-- 统计月指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID              			AS    BRH_ID              	    --营业部编码
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(NET_CMS)					AS    NET_CMS_MTD          		--净佣金_月累计
		,SUM(GROSS_CMS)					AS    GROSS_CMS_MTD        		--毛佣金_月累计
		,SUM(SCDY_CMS)					AS    SCDY_CMS_MTD         		--二级佣金_月累计
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_MTD     		--二级净佣金_月累计
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_MTD    		--二级过户费_月累计
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_MTD 		--普通交易过户费_月累计
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_MTD		--信用交易过户费_月累计
		,SUM(STKF_CMS)					AS    STKF_CMS_MTD         		--股基佣金_月累计
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_MTD    		--股基过户费_月累计
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_MTD     		--股基净佣金_月累计
		,SUM(BOND_CMS)					AS    BOND_CMS_MTD         		--债券佣金_月累计
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_MTD     		--债券净佣金_月累计
		,SUM(REPQ_CMS)					AS    REPQ_CMS_MTD         		--报价回购佣金_月累计
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_MTD     		--报价回购净佣金_月累计
		,SUM(HGT_CMS)					AS    HGT_CMS_MTD          		--沪港通佣金_月累计
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_MTD      		--沪港通净佣金_月累计
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_MTD     		--沪港通过户费_月累计
		,SUM(SGT_CMS)					AS    SGT_CMS_MTD          		--深港通佣金_月累计
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_MTD      		--深港通净佣金_月累计
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_MTD     		--深港通过户费_月累计
		,SUM(BGDL_CMS)					AS    BGDL_CMS_MTD         		--大宗交易佣金_月累计
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_MTD     		--大宗交易净佣金_月累计
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_MTD    		--大宗交易过户费_月累计
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_MTD    		--个股期权佣金_月累计
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_MTD 	--个股期权净佣金_月累计
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_MTD   		--融资融券普通佣金_月累计
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_MTD 	--融资融券普通净佣金_月累计
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_MTD 	--融资融券普通过户费_月累计
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_MTD  		--融资融券信用佣金_月累计
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_MTD 	--融资融券信用净佣金_月累计
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_MTD 	--融资融券信用过户费_月累计
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_MTD     		--融资应收利息_月累计
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_MTD      		--融资实收利息_月累计
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_MTD       		--股票质押佣金_月累计
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_MTD   		--股票质押净佣金_月累计
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_MTD   		--股票质押实收利息_月累计
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_MTD  		--股票质押应收利息_月累计
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_MTD     		--约定购回佣金_月累计
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_MTD 		--约定购回净佣金_月累计
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_MTD 		--约定购回实收利息_月累计
		,SUM(FIN_IE)					AS    FIN_IE_MTD           		--融资利息支出_月累计
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_MTD      		--融券利息支出_月累计
		,SUM(OTH_IE)					AS    OTH_IE_MTD           		--其他利息支出_月累计
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_MTD     		--费用应收利息_月累计
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_MTD     		--其他应收利息_月累计
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_MTD 		--融资融券资金成本_月累计
	INTO #TMP_T_EVT_INCM_D_BRH_MTH
	FROM DM.T_EVT_INCM_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	-- 统计年指标
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--发生日期		
		,BRH_ID              			AS    BRH_ID              	    --营业部编码
		,@V_YEAR						AS    YEAR   					--年
		,@V_MONTH 						AS    MTH 						--月
		,SUM(NET_CMS)					AS    NET_CMS_YTD          		--净佣金_年累计
		,SUM(GROSS_CMS)					AS    GROSS_CMS_YTD        		--毛佣金_年累计
		,SUM(SCDY_CMS)					AS    SCDY_CMS_YTD         		--二级佣金_年累计
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_YTD     		--二级净佣金_年累计
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_YTD    		--二级过户费_年累计
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_YTD 		--普通交易过户费_年累计
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_YTD		--信用交易过户费_年累计
		,SUM(STKF_CMS)					AS    STKF_CMS_YTD         		--股基佣金_年累计
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_YTD    		--股基过户费_年累计
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_YTD     		--股基净佣金_年累计
		,SUM(BOND_CMS)					AS    BOND_CMS_YTD         		--债券佣金_年累计
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_YTD     		--债券净佣金_年累计
		,SUM(REPQ_CMS)					AS    REPQ_CMS_YTD         		--报价回购佣金_年累计
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_YTD     		--报价回购净佣金_年累计
		,SUM(HGT_CMS)					AS    HGT_CMS_YTD          		--沪港通佣金_年累计
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_YTD      		--沪港通净佣金_年累计
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_YTD     		--沪港通过户费_年累计
		,SUM(SGT_CMS)					AS    SGT_CMS_YTD          		--深港通佣金_年累计
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_YTD      		--深港通净佣金_年累计
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_YTD     		--深港通过户费_年累计
		,SUM(BGDL_CMS)					AS    BGDL_CMS_YTD         		--大宗交易佣金_年累计
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_YTD     		--大宗交易净佣金_年累计
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_YTD    		--大宗交易过户费_年累计
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_YTD    		--个股期权佣金_年累计
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_YTD 	--个股期权净佣金_年累计
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_YTD   		--融资融券普通佣金_年累计
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_YTD 	--融资融券普通净佣金_年累计
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_YTD 	--融资融券普通过户费_年累计
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_YTD  		--融资融券信用佣金_年累计
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_YTD 	--融资融券信用净佣金_年累计
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_YTD 	--融资融券信用过户费_年累计
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_YTD     		--融资应收利息_年累计
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_YTD      		--融资实收利息_年累计
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_YTD       		--股票质押佣金_年累计
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_YTD   		--股票质押净佣金_年累计
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_YTD   		--股票质押实收利息_年累计
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_YTD  		--股票质押应收利息_年累计
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_YTD     		--约定购回佣金_年累计
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_YTD 		--约定购回净佣金_年累计
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_YTD 		--约定购回实收利息_年累计
		,SUM(FIN_IE)					AS    FIN_IE_YTD           		--融资利息支出_年累计
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_YTD      		--融券利息支出_年累计
		,SUM(OTH_IE)					AS    OTH_IE_YTD           		--其他利息支出_年累计
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_YTD     		--费用应收利息_年累计
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_YTD     		--其他应收利息_年累计
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_YTD 		--融资融券资金成本_年累计
	INTO #TMP_T_EVT_INCM_D_BRH_YEAR
	FROM DM.T_EVT_INCM_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--插入目标表
	INSERT INTO DM.T_EVT_INCM_M_BRH(
		 YEAR                 		--年
		,MTH                  		--月
		,BRH_ID              		--营业部编码
		,OCCUR_DT             		--发生日期
		,NET_CMS_MTD          		--净佣金_月累计
		,GROSS_CMS_MTD        		--毛佣金_月累计
		,SCDY_CMS_MTD         		--二级佣金_月累计
		,SCDY_NET_CMS_MTD     		--二级净佣金_月累计
		,SCDY_TRAN_FEE_MTD    		--二级过户费_月累计
		,ODI_TRD_TRAN_FEE_MTD 		--普通交易过户费_月累计
		,CRED_TRD_TRAN_FEE_MTD		--信用交易过户费_月累计
		,STKF_CMS_MTD         		--股基佣金_月累计
		,STKF_TRAN_FEE_MTD    		--股基过户费_月累计
		,STKF_NET_CMS_MTD     		--股基净佣金_月累计
		,BOND_CMS_MTD         		--债券佣金_月累计
		,BOND_NET_CMS_MTD     		--债券净佣金_月累计
		,REPQ_CMS_MTD         		--报价回购佣金_月累计
		,REPQ_NET_CMS_MTD     		--报价回购净佣金_月累计
		,HGT_CMS_MTD          		--沪港通佣金_月累计
		,HGT_NET_CMS_MTD      		--沪港通净佣金_月累计
		,HGT_TRAN_FEE_MTD     		--沪港通过户费_月累计
		,SGT_CMS_MTD          		--深港通佣金_月累计
		,SGT_NET_CMS_MTD      		--深港通净佣金_月累计
		,SGT_TRAN_FEE_MTD     		--深港通过户费_月累计
		,BGDL_CMS_MTD         		--大宗交易佣金_月累计
		,BGDL_NET_CMS_MTD     		--大宗交易净佣金_月累计
		,BGDL_TRAN_FEE_MTD    		--大宗交易过户费_月累计
		,PSTK_OPTN_CMS_MTD    		--个股期权佣金_月累计
		,PSTK_OPTN_NET_CMS_MTD 		--个股期权净佣金_月累计
		,CREDIT_ODI_CMS_MTD   		--融资融券普通佣金_月累计
		,CREDIT_ODI_NET_CMS_MTD 	--融资融券普通净佣金_月累计
		,CREDIT_ODI_TRAN_FEE_MTD 	--融资融券普通过户费_月累计
		,CREDIT_CRED_CMS_MTD  		--融资融券信用佣金_月累计
		,CREDIT_CRED_NET_CMS_MTD 	--融资融券信用净佣金_月累计
		,CREDIT_CRED_TRAN_FEE_MTD 	--融资融券信用过户费_月累计
		,FIN_RECE_INT_MTD     		--融资应收利息_月累计
		,FIN_PAIDINT_MTD      		--融资实收利息_月累计
		,STKPLG_CMS_MTD       		--股票质押佣金_月累计
		,STKPLG_NET_CMS_MTD   		--股票质押净佣金_月累计
		,STKPLG_PAIDINT_MTD   		--股票质押实收利息_月累计
		,STKPLG_RECE_INT_MTD  		--股票质押应收利息_月累计
		,APPTBUYB_CMS_MTD     		--约定购回佣金_月累计
		,APPTBUYB_NET_CMS_MTD 		--约定购回净佣金_月累计
		,APPTBUYB_PAIDINT_MTD 		--约定购回实收利息_月累计
		,FIN_IE_MTD           		--融资利息支出_月累计
		,CRDT_STK_IE_MTD      		--融券利息支出_月累计
		,OTH_IE_MTD           		--其他利息支出_月累计
		,FEE_RECE_INT_MTD     		--费用应收利息_月累计
		,OTH_RECE_INT_MTD     		--其他应收利息_月累计
		,CREDIT_CPTL_COST_MTD 		--融资融券资金成本_月累计
		,NET_CMS_YTD          		--净佣金_年累计
		,GROSS_CMS_YTD        		--毛佣金_年累计
		,SCDY_CMS_YTD         		--二级佣金_年累计
		,SCDY_NET_CMS_YTD     		--二级净佣金_年累计
		,SCDY_TRAN_FEE_YTD    		--二级过户费_年累计
		,ODI_TRD_TRAN_FEE_YTD 		--普通交易过户费_年累计
		,CRED_TRD_TRAN_FEE_YTD		--信用交易过户费_年累计
		,STKF_CMS_YTD         		--股基佣金_年累计
		,STKF_TRAN_FEE_YTD    		--股基过户费_年累计
		,STKF_NET_CMS_YTD     		--股基净佣金_年累计
		,BOND_CMS_YTD         		--债券佣金_年累计
		,BOND_NET_CMS_YTD     		--债券净佣金_年累计
		,REPQ_CMS_YTD         		--报价回购佣金_年累计
		,REPQ_NET_CMS_YTD     		--报价回购净佣金_年累计
		,HGT_CMS_YTD   				--沪港通佣金_年累计
		,HGT_NET_CMS_YTD       		--沪港通净佣金_年累计
		,HGT_TRAN_FEE_YTD     		--沪港通过户费_年累计
		,SGT_CMS_YTD          		--深港通佣金_年累计
		,SGT_NET_CMS_YTD      		--深港通净佣金_年累计
		,SGT_TRAN_FEE_YTD     		--深港通过户费_年累计
		,BGDL_CMS_YTD         		--大宗交易佣金_年累计
		,BGDL_NET_CMS_YTD     		--大宗交易净佣金_年累计
		,BGDL_TRAN_FEE_YTD    		--大宗交易过户费_年累计
		,PSTK_OPTN_CMS_YTD    		--个股期权佣金_年累计
		,PSTK_OPTN_NET_CMS_YTD		--个股期权净佣金_年累计
		,CREDIT_ODI_CMS_YTD   		--融资融券普通佣金_年累计
		,CREDIT_ODI_NET_CMS_YTD 	--融资融券普通净佣金_年累计	
		,CREDIT_ODI_TRAN_FEE_YTD 	--融资融券普通过户费_年累计
		,CREDIT_CRED_CMS_YTD  		--融资融券信用佣金_年累计
		,CREDIT_CRED_NET_CMS_YTD 	--融资融券信用净佣金_年累计
		,CREDIT_CRED_TRAN_FEE_YTD 	--融资融券信用过户费_年累计
		,FIN_RECE_INT_YTD     		--融资应收利息_年累计
		,FIN_PAIDINT_YTD      		--融资实收利息_年累计
		,STKPLG_CMS_YTD       		--股票质押佣金_年累计
		,STKPLG_NET_CMS_YTD   		--股票质押净佣金_年累计
		,STKPLG_PAIDINT_YTD   		--股票质押实收利息_年累计
		,STKPLG_RECE_INT_YTD  		--股票质押应收利息_年累计
		,APPTBUYB_CMS_YTD     		--约定购回佣金_年累计
		,APPTBUYB_NET_CMS_YTD 		--约定购回净佣金_年累计
		,APPTBUYB_PAIDINT_YTD 		--约定购回实收利息_年累计
		,FIN_IE_YTD           		--融资利息支出_年累计
		,CRDT_STK_IE_YTD      		--融券利息支出_年累计
		,OTH_IE_YTD           		--其他利息支出_年累计
		,FEE_RECE_INT_YTD     		--费用应收利息_年累计
		,OTH_RECE_INT_YTD     		--其他应收利息_年累计
		,CREDIT_CPTL_COST_YTD 		--融资融券资金成本_年累计
	)		
	SELECT 
		 T1.YEAR                 				AS    YEAR                 			--年
		,T1.MTH                  				AS    MTH                  			--月
		,T1.BRH_ID              				AS    BRH_ID              	    	--营业部编码
		,T1.OCCUR_DT             				AS    OCCUR_DT             			--发生日期
		,T1.NET_CMS_MTD          				AS    NET_CMS_MTD          			--净佣金_月累计
		,T1.GROSS_CMS_MTD        				AS    GROSS_CMS_MTD        			--毛佣金_月累计
		,T1.SCDY_CMS_MTD         				AS    SCDY_CMS_MTD         			--二级佣金_月累计
		,T1.SCDY_NET_CMS_MTD     				AS    SCDY_NET_CMS_MTD     			--二级净佣金_月累计
		,T1.SCDY_TRAN_FEE_MTD    				AS    SCDY_TRAN_FEE_MTD    			--二级过户费_月累计
		,T1.ODI_TRD_TRAN_FEE_MTD 				AS    ODI_TRD_TRAN_FEE_MTD 			--普通交易过户费_月累计
		,T1.CRED_TRD_TRAN_FEE_MTD				AS    CRED_TRD_TRAN_FEE_MTD			--信用交易过户费_月累计
		,T1.STKF_CMS_MTD         				AS    STKF_CMS_MTD         			--股基佣金_月累计
		,T1.STKF_TRAN_FEE_MTD    				AS    STKF_TRAN_FEE_MTD    			--股基过户费_月累计
		,T1.STKF_NET_CMS_MTD     				AS    STKF_NET_CMS_MTD     			--股基净佣金_月累计
		,T1.BOND_CMS_MTD         				AS    BOND_CMS_MTD         			--债券佣金_月累计
		,T1.BOND_NET_CMS_MTD     				AS    BOND_NET_CMS_MTD     			--债券净佣金_月累计
		,T1.REPQ_CMS_MTD         				AS    REPQ_CMS_MTD         			--报价回购佣金_月累计
		,T1.REPQ_NET_CMS_MTD     				AS    REPQ_NET_CMS_MTD     			--报价回购净佣金_月累计
		,T1.HGT_CMS_MTD          				AS    HGT_CMS_MTD          			--沪港通佣金_月累计
		,T1.HGT_NET_CMS_MTD      				AS    HGT_NET_CMS_MTD      			--沪港通净佣金_月累计
		,T1.HGT_TRAN_FEE_MTD     				AS    HGT_TRAN_FEE_MTD     			--沪港通过户费_月累计
		,T1.SGT_CMS_MTD          				AS    SGT_CMS_MTD          			--深港通佣金_月累计
		,T1.SGT_NET_CMS_MTD      				AS    SGT_NET_CMS_MTD      			--深港通净佣金_月累计
		,T1.SGT_TRAN_FEE_MTD     				AS    SGT_TRAN_FEE_MTD     			--深港通过户费_月累计
		,T1.BGDL_CMS_MTD         				AS    BGDL_CMS_MTD         			--大宗交易佣金_月累计
		,T1.BGDL_NET_CMS_MTD     				AS    BGDL_NET_CMS_MTD     			--大宗交易净佣金_月累计
		,T1.BGDL_TRAN_FEE_MTD    				AS    BGDL_TRAN_FEE_MTD    			--大宗交易过户费_月累计
		,T1.PSTK_OPTN_CMS_MTD    				AS    PSTK_OPTN_CMS_MTD    			--个股期权佣金_月累计
		,T1.PSTK_OPTN_NET_CMS_MTD 				AS    PSTK_OPTN_NET_CMS_MTD 		--个股期权净佣金_月累计
		,T1.CREDIT_ODI_CMS_MTD   				AS    CREDIT_ODI_CMS_MTD   			--融资融券普通佣金_月累计
		,T1.CREDIT_ODI_NET_CMS_MTD 				AS    CREDIT_ODI_NET_CMS_MTD 		--融资融券普通净佣金_月累计
		,T1.CREDIT_ODI_TRAN_FEE_MTD 			AS    CREDIT_ODI_TRAN_FEE_MTD 		--融资融券普通过户费_月累计
		,T1.CREDIT_CRED_CMS_MTD  				AS    CREDIT_CRED_CMS_MTD  			--融资融券信用佣金_月累计
		,T1.CREDIT_CRED_NET_CMS_MTD 			AS    CREDIT_CRED_NET_CMS_MTD 		--融资融券信用净佣金_月累计
		,T1.CREDIT_CRED_TRAN_FEE_MTD 			AS    CREDIT_CRED_TRAN_FEE_MTD 		--融资融券信用过户费_月累计
		,T1.FIN_RECE_INT_MTD     				AS    FIN_RECE_INT_MTD     			--融资应收利息_月累计
		,T1.FIN_PAIDINT_MTD      				AS    FIN_PAIDINT_MTD      			--融资实收利息_月累计
		,T1.STKPLG_CMS_MTD       				AS    STKPLG_CMS_MTD       			--股票质押佣金_月累计
		,T1.STKPLG_NET_CMS_MTD   				AS    STKPLG_NET_CMS_MTD   			--股票质押净佣金_月累计
		,T1.STKPLG_PAIDINT_MTD   				AS    STKPLG_PAIDINT_MTD   			--股票质押实收利息_月累计
		,T1.STKPLG_RECE_INT_MTD  				AS    STKPLG_RECE_INT_MTD  			--股票质押应收利息_月累计
		,T1.APPTBUYB_CMS_MTD     				AS    APPTBUYB_CMS_MTD     			--约定购回佣金_月累计
		,T1.APPTBUYB_NET_CMS_MTD 				AS    APPTBUYB_NET_CMS_MTD 			--约定购回净佣金_月累计
		,T1.APPTBUYB_PAIDINT_MTD 				AS    APPTBUYB_PAIDINT_MTD 			--约定购回实收利息_月累计
		,T1.FIN_IE_MTD           				AS    FIN_IE_MTD           			--融资利息支出_月累计
		,T1.CRDT_STK_IE_MTD      				AS    CRDT_STK_IE_MTD      			--融券利息支出_月累计
		,T1.OTH_IE_MTD           				AS    OTH_IE_MTD           			--其他利息支出_月累计
		,T1.FEE_RECE_INT_MTD     				AS    FEE_RECE_INT_MTD     			--费用应收利息_月累计
		,T1.OTH_RECE_INT_MTD     				AS    OTH_RECE_INT_MTD     			--其他应收利息_月累计
		,T1.CREDIT_CPTL_COST_MTD 				AS    CREDIT_CPTL_COST_MTD 			--融资融券资金成本_月累计
		,T2.NET_CMS_YTD          				AS    NET_CMS_YTD          			--净佣金_年累计
		,T2.GROSS_CMS_YTD        				AS    GROSS_CMS_YTD        			--毛佣金_年累计
		,T2.SCDY_CMS_YTD         				AS    SCDY_CMS_YTD         			--二级佣金_年累计
		,T2.SCDY_NET_CMS_YTD     				AS    SCDY_NET_CMS_YTD     			--二级净佣金_年累计
		,T2.SCDY_TRAN_FEE_YTD    				AS    SCDY_TRAN_FEE_YTD    			--二级过户费_年累计
		,T2.ODI_TRD_TRAN_FEE_YTD 				AS    ODI_TRD_TRAN_FEE_YTD 			--普通交易过户费_年累计
		,T2.CRED_TRD_TRAN_FEE_YTD				AS    CRED_TRD_TRAN_FEE_YTD			--信用交易过户费_年累计
		,T2.STKF_CMS_YTD         				AS    STKF_CMS_YTD         			--股基佣金_年累计
		,T2.STKF_TRAN_FEE_YTD    				AS    STKF_TRAN_FEE_YTD    			--股基过户费_年累计
		,T2.STKF_NET_CMS_YTD     				AS    STKF_NET_CMS_YTD     			--股基净佣金_年累计
		,T2.BOND_CMS_YTD         				AS    BOND_CMS_YTD         			--债券佣金_年累计
		,T2.BOND_NET_CMS_YTD     				AS    BOND_NET_CMS_YTD     			--债券净佣金_年累计
		,T2.REPQ_CMS_YTD         				AS    REPQ_CMS_YTD         			--报价回购佣金_年累计
		,T2.REPQ_NET_CMS_YTD     				AS    REPQ_NET_CMS_YTD     			--报价回购净佣金_年累计
		,T2.HGT_CMS_YTD   						AS    HGT_CMS_YTD   				--沪港通佣金_年累计
		,T2.HGT_NET_CMS_YTD      				AS    HGT_NET_CMS_YTD       		--沪港通净佣金_年累计
		,T2.HGT_TRAN_FEE_YTD     				AS    HGT_TRAN_FEE_YTD     			--沪港通过户费_年累计
		,T2.SGT_CMS_YTD          				AS    SGT_CMS_YTD          			--深港通佣金_年累计
		,T2.SGT_NET_CMS_YTD      				AS    SGT_NET_CMS_YTD      			--深港通净佣金_年累计
		,T2.SGT_TRAN_FEE_YTD     				AS    SGT_TRAN_FEE_YTD     			--深港通过户费_年累计
		,T2.BGDL_CMS_YTD         				AS    BGDL_CMS_YTD         			--大宗交易佣金_年累计
		,T2.BGDL_NET_CMS_YTD     				AS    BGDL_NET_CMS_YTD     			--大宗交易净佣金_年累计
		,T2.BGDL_TRAN_FEE_YTD    				AS    BGDL_TRAN_FEE_YTD    			--大宗交易过户费_年累计
		,T2.PSTK_OPTN_CMS_YTD    				AS    PSTK_OPTN_CMS_YTD    			--个股期权佣金_年累计
		,T2.PSTK_OPTN_NET_CMS_YTD				AS    PSTK_OPTN_NET_CMS_YTD			--个股期权净佣金_年累计
		,T2.CREDIT_ODI_CMS_YTD   				AS    CREDIT_ODI_CMS_YTD   			--融资融券普通佣金_年累计
		,T2.CREDIT_ODI_NET_CMS_YTD 				AS    CREDIT_ODI_NET_CMS_YTD 		--融资融券普通净佣金_年累计	
		,T2.CREDIT_ODI_TRAN_FEE_YTD 			AS    CREDIT_ODI_TRAN_FEE_YTD 		--融资融券普通过户费_年累计
		,T2.CREDIT_CRED_CMS_YTD  				AS    CREDIT_CRED_CMS_YTD  			--融资融券信用佣金_年累计
		,T2.CREDIT_CRED_NET_CMS_YTD 			AS    CREDIT_CRED_NET_CMS_YTD 		--融资融券信用净佣金_年累计
		,T2.CREDIT_CRED_TRAN_FEE_YTD 			AS    CREDIT_CRED_TRAN_FEE_YTD 		--融资融券信用过户费_年累计
		,T2.FIN_RECE_INT_YTD     				AS    FIN_RECE_INT_YTD     			--融资应收利息_年累计
		,T2.FIN_PAIDINT_YTD      				AS    FIN_PAIDINT_YTD      			--融资实收利息_年累计
		,T2.STKPLG_CMS_YTD       				AS    STKPLG_CMS_YTD       			--股票质押佣金_年累计
		,T2.STKPLG_NET_CMS_YTD   				AS    STKPLG_NET_CMS_YTD   			--股票质押净佣金_年累计
		,T2.STKPLG_PAIDINT_YTD   				AS    STKPLG_PAIDINT_YTD   			--股票质押实收利息_年累计
		,T2.STKPLG_RECE_INT_YTD  				AS    STKPLG_RECE_INT_YTD  			--股票质押应收利息_年累计
		,T2.APPTBUYB_CMS_YTD     				AS    APPTBUYB_CMS_YTD     			--约定购回佣金_年累计
		,T2.APPTBUYB_NET_CMS_YTD 				AS    APPTBUYB_NET_CMS_YTD 			--约定购回净佣金_年累计
		,T2.APPTBUYB_PAIDINT_YTD 				AS    APPTBUYB_PAIDINT_YTD 			--约定购回实收利息_年累计
		,T2.FIN_IE_YTD           				AS    FIN_IE_YTD           			--融资利息支出_年累计
		,T2.CRDT_STK_IE_YTD      				AS    CRDT_STK_IE_YTD      			--融券利息支出_年累计
		,T2.OTH_IE_YTD           				AS    OTH_IE_YTD           			--其他利息支出_年累计
		,T2.FEE_RECE_INT_YTD     				AS    FEE_RECE_INT_YTD     			--费用应收利息_年累计
		,T2.OTH_RECE_INT_YTD     				AS    OTH_RECE_INT_YTD     			--其他应收利息_年累计
		,T2.CREDIT_CPTL_COST_YTD 				AS    CREDIT_CPTL_COST_YTD 			--融资融券资金成本_年累计	
	FROM #TMP_T_EVT_INCM_D_BRH_MTH T1,#TMP_T_EVT_INCM_D_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
