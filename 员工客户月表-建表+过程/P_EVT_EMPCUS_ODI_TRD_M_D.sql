CREATE OR REPLACE PROCEDURE dm.P_EVT_EMPCUS_ODI_TRD_M_D(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户普通交易月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户普通交易月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 删除当月数据
  DELETE FROM DM.T_EVT_EMPCUS_ODI_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;


	 
INSERT INTO DM.T_EVT_EMPCUS_ODI_TRD_M_D 
(
	 YEAR                 				--年
	,MTH                  				--月
	,YEAR_MTH             				--年月
	,CUST_ID              				--客户编号
	,MAIN_CPTL_ACCT       				--主资金账号
	,YEAR_MTH_CUST_ID     				--年月客户编号
	,AFA_SEC_EMPID        				--AFA员工编号
	,YEAR_MTH_PSN_JNO     				--年月员工编号
	,WH_ORG_ID_CUST       				--仓库机构编码_客户
	,WH_ORG_ID_EMP        				--仓库机构编码_员工
	,EQT_CLAS_KEPP_PERCN  				--权益类持仓占比
	,SCDY_TRD_FREQ_MTD    				--二级交易次数_月累计
	,RCT_TRD_DT_GT        				--最近交易日期_累计
	,SCDY_TRD_QTY_YTD     				--二级交易量_年累计
	,TRD_FREQ_YTD         				--交易次数_年累计
	,STKF_TRD_QTY_MDA     				--股基交易量_月日均
	,STKF_TRD_QTY_YDA     				--股基交易量_年日均
	,S_REPUR_TRD_QTY_MDA  				--正回购交易量_月日均
	,R_REPUR_TRD_QTY_MDA  				--逆回购交易量_月日均
	,S_REPUR_TRD_QTY_YDA  				--正回购交易量_年日均
	,R_REPUR_TRD_QTY_YDA  				--逆回购交易量_年日均
	,HGT_TRD_QTY_MTD      				--沪港通交易量_月累计
	,SGT_TRD_QTY_MTD      				--深港通交易量_月累计
	,SGT_TRD_QTY_YTD      				--深港通交易量_年累计
	,HGT_TRD_QTY_YTD      				--沪港通交易量_年累计
	,Y_RCT_STK_TRD_QTY    				--近12月股票交易量
	,SCDY_TRD_FREQ_YTD    				--二级交易次数_年累计
	,TRD_FREQ_MTD         				--交易次数_月累计
	,APPTBUYB_TRD_QTY_MTD 				--约定购回交易量_月累计
	,APPTBUYB_TRD_QTY_YTD 				--约定购回交易量_年累计
	,RCT_TRD_DT_M         				--最近交易日期_本月
	,STKPLG_TRD_QTY_MTD   				--股票质押交易量_月累计
	,STKPLG_TRD_QTY_YTD   				--股票质押交易量_年累计
	,PSTK_OPTN_TRD_QTY_MTD				--个股期权交易量_月累计
	,PSTK_OPTN_TRD_QTY_YTD				--个股期权交易量_年累计
	,REPQ_TRD_QTY_MTD     				--报价回购交易量_月累计
	,REPQ_TRD_QTY_YTD     				--报价回购交易量_年累计
	,BGDL_QTY_MTD         				--大宗交易量_月累计
	,BGDL_QTY_YTD         				--大宗交易量_年累计
	,LOAD_DT              				--清洗日期
	,NATRE_DAYS_MTH       				--自然天数_月
	,NATRE_DAYS_YEAR      				--自然天数_年
	,CREDIT_ODI_TRD_QTY_MDA 			--信用账户普通交易量_月日均
	,CREDIT_CRED_TRD_QTY_MDA			--信用账户信用交易量_月日均
	,STKF_TRD_QTY_MTD     				--股基交易量_月累计
	,SCDY_TRD_QTY_MTD     				--二级交易量_月累计
	,SCDY_TRD_QTY_MDA     				--二级交易量_月日均
	,S_REPUR_TRD_QTY_MTD  				--正回购交易量_月累计
	,R_REPUR_TRD_QTY_MTD  				--逆回购交易量_月累计
	,CREDIT_TRD_QTY_MTD   				--融资融券交易量_月累计
	,OFFUND_TRD_QTY_MTD   				--场内基金交易量_月累计
	,OPFUND_TRD_QTY_MTD   				--场外基金交易量_月累计
	,BANK_CHRM_TRD_QTY_MTD 				--银行理财交易量_月累计
	,SECU_CHRM_TRD_QTY_MTD 				--证券理财交易量_月累计
	,CREDIT_ODI_TRD_QTY_MTD 			--信用账户普通交易量_月累计
	,CREDIT_CRED_TRD_QTY_MTD 			--信用账户信用交易量_月累计
	,FIN_AMT_MTD          				--融资金额_月累计
	,CRDT_STK_AMT_MTD     				--融券金额_月累计
	,STKPLG_BUYB_AMT_MTD  				--股票质押购回金额_月累计
	,GROSS_CMS_MTD        				--毛佣金_月累计
	,NET_CMS_MTD          				--净佣金_月累计
	,STKPLG_BUYB_CNT_MTD  				--股票质押购回笔数_月累计
	,CCB_AMT_MTD          				--融资买入金额_月累计
	,CCB_CNT_MTD          				--融资买入笔数_月累计
	,FIN_SELL_AMT_MTD     				--融资卖出金额_月累计
	,FIN_SELL_CNT_MTD     				--融资卖出笔数_月累计
	,CRDT_STK_BUYIN_AMT_MTD 			--融券买入金额_月累计
	,CRDT_STK_BUYIN_CNT_MTD 			--融券买入笔数_月累计
	,CSS_AMT_MTD          				--融券卖出金额_月累计
	,CSS_CNT_MTD          				--融券卖出笔数_月累计
	,FIN_RTN_AMT_MTD      				--融资归还金额_月累计
	,APPTBUYB_REP_AMT_MTD 				--约定购回还款金额_月累计
	,APPTBUYB_BUYB_AMT_MTD				--约定购回购回金额_月累计
	,APPTBUYB_TRD_AMT_MTD 				--约定购回交易金额_月累计
	,SCDY_TRD_QTY_YDA     				--二级交易量_年日均
	,CREDIT_ODI_TRD_QTY_YDA 			--信用账户普通交易量_年日均
	,CREDIT_CRED_TRD_QTY_YDA 			--信用账户信用交易量_年日均
	,STKF_TRD_QTY_YTD     				--股基交易量_年累计
	,S_REPUR_TRD_QTY_YTD  				--正回购交易量_年累计
	,R_REPUR_TRD_QTY_YTD  				--逆回购交易量_年累计
	,CREDIT_TRD_QTY_YTD   				--融资融券交易量_年累计
	,OFFUND_TRD_QTY_YTD   				--场内基金交易量_年累计
	,OPFUND_TRD_QTY_YTD   				--场外基金交易量_年累计
	,BANK_CHRM_TRD_QTY_YTD 				--银行理财交易量_年累计
	,SECU_CHRM_TRD_QTY_YTD 				--证券理财交易量_年累计
	,CREDIT_ODI_TRD_QTY_YTD 			--信用账户普通交易量_年累计
	,CREDIT_CRED_TRD_QTY_YTD 			--信用账户信用交易量_年累计
	,FIN_AMT_YTD          				--融资金额_年累计
	,CRDT_STK_AMT_YTD     				--融券金额_年累计
	,STKPLG_BUYB_AMT_YTD  				--股票质押购回金额_年累计
	,GROSS_CMS_YTD        				--毛佣金_年累计
	,NET_CMS_YTD          				--净佣金_年累计
	,STKPLG_BUYB_CNT_YTD  				--股票质押购回笔数_年累计
	,CCB_AMT_YTD          				--融资买入金额_年累计
	,CCB_CNT_YTD          				--融资买入笔数_年累计
	,FIN_SELL_AMT_YTD     				--融资卖出金额_年累计
	,FIN_SELL_CNT_YTD     				--融资卖出笔数_年累计
	,CRDT_STK_BUYIN_AMT_YTD 			--融券买入金额_年累计
	,CRDT_STK_BUYIN_CNT_YTD 			--融券买入笔数_年累计
	,CSS_AMT_YTD          				--融券卖出金额_年累计
	,CSS_CNT_YTD          				--融券卖出笔数_年累计
	,FIN_RTN_AMT_YTD      				--融资归还金额_年累计
	,APPTBUYB_REP_AMT_YTD 				--约定购回还款金额_年累计
	,APPTBUYB_BUYB_AMT_YTD				--约定购回购回金额_年累计
	,APPTBUYB_TRD_AMT_YTD 				--约定购回交易金额_年累计
	,SB_TRD_QTY_MTD       				--三板交易量_月累计
	,SB_TRD_QTY_YTD       				--三板交易量_年累计
	,BOND_TRD_QTY_MTD     				--债券交易量_月累计
	,BOND_TRD_QTY_YTD     				--债券交易量_年累计
	,ITC_CRRC_FUND_TRD_QTY_MTD 			--场内货币基金交易量_月累计
	,ITC_CRRC_FUND_TRD_QTY_YTD 			--场内货币基金交易量_年累计
	,S_REPUR_NET_CMS_MTD  				--正回购净佣金_月累计
	,S_REPUR_NET_CMS_YTD  				--正回购净佣金_年累计
	,R_REPUR_NET_CMS_MTD  				--逆回购净佣金_月累计
	,R_REPUR_NET_CMS_YTD  				--逆回购净佣金_年累计
	,ITC_CRRC_FUND_NET_CMS_MTD 			--场内货币基金净佣金_月累计
	,ITC_CRRC_FUND_NET_CMS_YTD 			--场内货币基金净佣金_年累计
	,PB_TRD_QTY_MTD       				--PB交易量_月累计
)
SELECT 
	 T2.YEAR														AS 年
	,T2.MTH 														AS 月
	,T2.YEAR||T2.MTH 												AS 年月
	,T2.HS_CUST_ID													AS 客户编码
	,T2.CPTL_ACCT 													AS 主资金账号
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID 								AS 年月客户编号
	,T2.AFA_SEC_EMPID 												AS AFA_二期员工号
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID 							    AS 年月员工号
	,T2.WH_ORG_ID_CUST											    AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP 											    AS 仓库机构编码_员工
	,COALESCE(T1.EQT_CLAS_KEPP_PERCN,0)			* COALESCE(T2.PERFM_RATI3,0)	AS EQT_CLAS_KEPP_PERCN  			--权益类持仓占比		
	,COALESCE(T1.SCDY_TRD_FREQ_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS SCDY_TRD_FREQ_MTD    			--二级交易次数_月累计		
	,COALESCE(T1.RCT_TRD_DT_GT,0)				* COALESCE(T2.PERFM_RATI3,0)	AS RCT_TRD_DT_GT        			--最近交易日期_累计	
	,COALESCE(T1.SCDY_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS SCDY_TRD_QTY_YTD     			--二级交易量_年累计	
	,COALESCE(T1.TRD_FREQ_YTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS TRD_FREQ_YTD         			--交易次数_年累计
	,COALESCE(T1.STKF_TRD_QTY_MDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKF_TRD_QTY_MDA     			--股基交易量_月日均	
	,COALESCE(T1.STKF_TRD_QTY_YDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKF_TRD_QTY_YDA     			--股基交易量_年日均	
	,COALESCE(T1.S_REPUR_TRD_QTY_MDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS S_REPUR_TRD_QTY_MDA  			--正回购交易量_月日均		
	,COALESCE(T1.R_REPUR_TRD_QTY_MDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS R_REPUR_TRD_QTY_MDA  			--逆回购交易量_月日均		
	,COALESCE(T1.S_REPUR_TRD_QTY_YDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS S_REPUR_TRD_QTY_YDA  			--正回购交易量_年日均		
	,COALESCE(T1.R_REPUR_TRD_QTY_YDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS R_REPUR_TRD_QTY_YDA  			--逆回购交易量_年日均		
	,COALESCE(T1.HGT_TRD_QTY_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS HGT_TRD_QTY_MTD      			--沪港通交易量_月累计	
	,COALESCE(T1.SGT_TRD_QTY_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS SGT_TRD_QTY_MTD      			--深港通交易量_月累计	
	,COALESCE(T1.SGT_TRD_QTY_YTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS SGT_TRD_QTY_YTD      			--深港通交易量_年累计	
	,COALESCE(T1.HGT_TRD_QTY_YTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS HGT_TRD_QTY_YTD      			--沪港通交易量_年累计	
	,COALESCE(T1.Y_RCT_STK_TRD_QTY,0)			* COALESCE(T2.PERFM_RATI3,0)	AS Y_RCT_STK_TRD_QTY    			--近12月股票交易量		
	,COALESCE(T1.SCDY_TRD_FREQ_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS SCDY_TRD_FREQ_YTD    			--二级交易次数_年累计		
	,COALESCE(T1.TRD_FREQ_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS TRD_FREQ_MTD         			--交易次数_月累计
	,COALESCE(T1.APPTBUYB_TRD_QTY_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_TRD_QTY_MTD 			--约定购回交易量_月累计		
	,COALESCE(T1.APPTBUYB_TRD_QTY_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_TRD_QTY_YTD 			--约定购回交易量_年累计		
	,COALESCE(T1.RCT_TRD_DT_M,0)				* COALESCE(T2.PERFM_RATI3,0)	AS RCT_TRD_DT_M         			--最近交易日期_本月
	,COALESCE(T1.STKPLG_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKPLG_TRD_QTY_MTD   			--股票质押交易量_月累计		
	,COALESCE(T1.STKPLG_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKPLG_TRD_QTY_YTD   			--股票质押交易量_年累计		
	,COALESCE(T1.PSTK_OPTN_TRD_QTY_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS PSTK_OPTN_TRD_QTY_MTD			--个股期权交易量_月累计			
	,COALESCE(T1.PSTK_OPTN_TRD_QTY_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS PSTK_OPTN_TRD_QTY_YTD			--个股期权交易量_年累计			
	,COALESCE(T1.REPQ_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS REPQ_TRD_QTY_MTD     			--报价回购交易量_月累计	
	,COALESCE(T1.REPQ_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS REPQ_TRD_QTY_YTD     			--报价回购交易量_年累计	
	,COALESCE(T1.BGDL_QTY_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS BGDL_QTY_MTD         			--大宗交易量_月累计
	,COALESCE(T1.BGDL_QTY_YTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS BGDL_QTY_YTD         			--大宗交易量_年累计
	,@V_BIN_DATE																AS LOAD_DT              			--清洗日期
	,COALESCE(T1.NATRE_DAYS_MTH,0)				* COALESCE(T2.PERFM_RATI3,0)	AS NATRE_DAYS_MTH       			--自然天数_月	
	,COALESCE(T1.NATRE_DAYS_YEAR,0)				* COALESCE(T2.PERFM_RATI3,0)	AS NATRE_DAYS_YEAR      			--自然天数_年	
	,COALESCE(T1.CREDIT_ODI_TRD_QTY_MDA,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_ODI_TRD_QTY_MDA 		    --信用账户普通交易量_月日均			
	,COALESCE(T1.CREDIT_CRED_TRD_QTY_MDA,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_CRED_TRD_QTY_MDA		    --信用账户信用交易量_月日均			
	,COALESCE(T1.STKF_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKF_TRD_QTY_MTD     			--股基交易量_月累计	
	,COALESCE(T1.SCDY_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS SCDY_TRD_QTY_MTD     			--二级交易量_月累计	
	,COALESCE(T1.SCDY_TRD_QTY_MDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS SCDY_TRD_QTY_MDA     			--二级交易量_月日均	
	,COALESCE(T1.S_REPUR_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS S_REPUR_TRD_QTY_MTD  			--正回购交易量_月累计		
	,COALESCE(T1.R_REPUR_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS R_REPUR_TRD_QTY_MTD  			--逆回购交易量_月累计		
	,COALESCE(T1.CREDIT_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_TRD_QTY_MTD   			--融资融券交易量_月累计		
	,COALESCE(T1.OFFUND_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS OFFUND_TRD_QTY_MTD   			--场内基金交易量_月累计		
	,COALESCE(T1.OPFUND_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS OPFUND_TRD_QTY_MTD   			--场外基金交易量_月累计		
	,COALESCE(T1.BANK_CHRM_TRD_QTY_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS BANK_CHRM_TRD_QTY_MTD 			--银行理财交易量_月累计			
	,COALESCE(T1.SECU_CHRM_TRD_QTY_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS SECU_CHRM_TRD_QTY_MTD 			--证券理财交易量_月累计			
	,COALESCE(T1.CREDIT_ODI_TRD_QTY_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_ODI_TRD_QTY_MTD 		    --信用账户普通交易量_月累计			
	,COALESCE(T1.CREDIT_CRED_TRD_QTY_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_CRED_TRD_QTY_MTD 		    --信用账户信用交易量_月累计			
	,COALESCE(T1.FIN_AMT_MTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS FIN_AMT_MTD          			--融资金额_月累计
	,COALESCE(T1.CRDT_STK_AMT_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS CRDT_STK_AMT_MTD     			--融券金额_月累计	
	,COALESCE(T1.STKPLG_BUYB_AMT_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKPLG_BUYB_AMT_MTD  			--股票质押购回金额_月累计		
	,COALESCE(T1.GROSS_CMS_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS GROSS_CMS_MTD        			--毛佣金_月累计	
	,COALESCE(T1.NET_CMS_MTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS NET_CMS_MTD          			--净佣金_月累计
	,COALESCE(T1.STKPLG_BUYB_CNT_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKPLG_BUYB_CNT_MTD  			--股票质押购回笔数_月累计		
	,COALESCE(T1.CCB_AMT_MTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CCB_AMT_MTD          			--融资买入金额_月累计
	,COALESCE(T1.CCB_CNT_MTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CCB_CNT_MTD          			--融资买入笔数_月累计
	,COALESCE(T1.FIN_SELL_AMT_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS FIN_SELL_AMT_MTD     			--融资卖出金额_月累计	
	,COALESCE(T1.FIN_SELL_CNT_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS FIN_SELL_CNT_MTD     			--融资卖出笔数_月累计	
	,COALESCE(T1.CRDT_STK_BUYIN_AMT_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CRDT_STK_BUYIN_AMT_MTD 		    --融券买入金额_月累计			
	,COALESCE(T1.CRDT_STK_BUYIN_CNT_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CRDT_STK_BUYIN_CNT_MTD 		    --融券买入笔数_月累计			
	,COALESCE(T1.CSS_AMT_MTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CSS_AMT_MTD          			--融券卖出金额_月累计
	,COALESCE(T1.CSS_CNT_MTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CSS_CNT_MTD          			--融券卖出笔数_月累计
	,COALESCE(T1.FIN_RTN_AMT_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS FIN_RTN_AMT_MTD      			--融资归还金额_月累计	
	,COALESCE(T1.APPTBUYB_REP_AMT_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_REP_AMT_MTD 			--约定购回还款金额_月累计		
	,COALESCE(T1.APPTBUYB_BUYB_AMT_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_BUYB_AMT_MTD			--约定购回购回金额_月累计			
	,COALESCE(T1.APPTBUYB_TRD_AMT_MTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_TRD_AMT_MTD 			--约定购回交易金额_月累计		
	,COALESCE(T1.SCDY_TRD_QTY_YDA,0)			* COALESCE(T2.PERFM_RATI3,0)	AS SCDY_TRD_QTY_YDA     			--二级交易量_年日均	
	,COALESCE(T1.CREDIT_ODI_TRD_QTY_YDA,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_ODI_TRD_QTY_YDA 		    --信用账户普通交易量_年日均			
	,COALESCE(T1.CREDIT_CRED_TRD_QTY_YDA,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_CRED_TRD_QTY_YDA 		    --信用账户信用交易量_年日均			
	,COALESCE(T1.STKF_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKF_TRD_QTY_YTD     			--股基交易量_年累计	
	,COALESCE(T1.S_REPUR_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS S_REPUR_TRD_QTY_YTD  			--正回购交易量_年累计		
	,COALESCE(T1.R_REPUR_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS R_REPUR_TRD_QTY_YTD  			--逆回购交易量_年累计		
	,COALESCE(T1.CREDIT_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_TRD_QTY_YTD   			--融资融券交易量_年累计		
	,COALESCE(T1.OFFUND_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS OFFUND_TRD_QTY_YTD   			--场内基金交易量_年累计		
	,COALESCE(T1.OPFUND_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS OPFUND_TRD_QTY_YTD   			--场外基金交易量_年累计		
	,COALESCE(T1.BANK_CHRM_TRD_QTY_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS BANK_CHRM_TRD_QTY_YTD 			--银行理财交易量_年累计			
	,COALESCE(T1.SECU_CHRM_TRD_QTY_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS SECU_CHRM_TRD_QTY_YTD 			--证券理财交易量_年累计			
	,COALESCE(T1.CREDIT_ODI_TRD_QTY_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_ODI_TRD_QTY_YTD 		    --信用账户普通交易量_年累计			
	,COALESCE(T1.CREDIT_CRED_TRD_QTY_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CREDIT_CRED_TRD_QTY_YTD 		    --信用账户信用交易量_年累计			
	,COALESCE(T1.FIN_AMT_YTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS FIN_AMT_YTD          			--融资金额_年累计
	,COALESCE(T1.CRDT_STK_AMT_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS CRDT_STK_AMT_YTD     			--融券金额_年累计	
	,COALESCE(T1.STKPLG_BUYB_AMT_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKPLG_BUYB_AMT_YTD  			--股票质押购回金额_年累计		
	,COALESCE(T1.GROSS_CMS_YTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS GROSS_CMS_YTD        			--毛佣金_年累计	
	,COALESCE(T1.NET_CMS_YTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS NET_CMS_YTD          			--净佣金_年累计
	,COALESCE(T1.STKPLG_BUYB_CNT_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS STKPLG_BUYB_CNT_YTD  			--股票质押购回笔数_年累计		
	,COALESCE(T1.CCB_AMT_YTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CCB_AMT_YTD          			--融资买入金额_年累计
	,COALESCE(T1.CCB_CNT_YTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CCB_CNT_YTD          			--融资买入笔数_年累计
	,COALESCE(T1.FIN_SELL_AMT_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS FIN_SELL_AMT_YTD     			--融资卖出金额_年累计	
	,COALESCE(T1.FIN_SELL_CNT_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS FIN_SELL_CNT_YTD     			--融资卖出笔数_年累计	
	,COALESCE(T1.CRDT_STK_BUYIN_AMT_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CRDT_STK_BUYIN_AMT_YTD 		    --融券买入金额_年累计			
	,COALESCE(T1.CRDT_STK_BUYIN_CNT_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS CRDT_STK_BUYIN_CNT_YTD 		    --融券买入笔数_年累计			
	,COALESCE(T1.CSS_AMT_YTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CSS_AMT_YTD          			--融券卖出金额_年累计
	,COALESCE(T1.CSS_CNT_YTD,0)					* COALESCE(T2.PERFM_RATI3,0)	AS CSS_CNT_YTD          			--融券卖出笔数_年累计
	,COALESCE(T1.FIN_RTN_AMT_YTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS FIN_RTN_AMT_YTD      			--融资归还金额_年累计	
	,COALESCE(T1.APPTBUYB_REP_AMT_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_REP_AMT_YTD 			--约定购回还款金额_年累计		
	,COALESCE(T1.APPTBUYB_BUYB_AMT_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_BUYB_AMT_YTD			--约定购回购回金额_年累计			
	,COALESCE(T1.APPTBUYB_TRD_AMT_YTD,0)		* COALESCE(T2.PERFM_RATI3,0)	AS APPTBUYB_TRD_AMT_YTD 			--约定购回交易金额_年累计		
	,COALESCE(T1.SB_TRD_QTY_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS SB_TRD_QTY_MTD       			--三板交易量_月累计	
	,COALESCE(T1.SB_TRD_QTY_YTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS SB_TRD_QTY_YTD       			--三板交易量_年累计	
	,COALESCE(T1.BOND_TRD_QTY_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS BOND_TRD_QTY_MTD     			--债券交易量_月累计	
	,COALESCE(T1.BOND_TRD_QTY_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS BOND_TRD_QTY_YTD     			--债券交易量_年累计	
	,COALESCE(T1.ITC_CRRC_FUND_TRD_QTY_MTD,0)	* COALESCE(T2.PERFM_RATI3,0)	AS ITC_CRRC_FUND_TRD_QTY_MTD 		--场内货币基金交易量_月累计				
	,COALESCE(T1.ITC_CRRC_FUND_TRD_QTY_YTD,0)	* COALESCE(T2.PERFM_RATI3,0)	AS ITC_CRRC_FUND_TRD_QTY_YTD 		--场内货币基金交易量_年累计				
	,COALESCE(T1.S_REPUR_NET_CMS_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS S_REPUR_NET_CMS_MTD  			--正回购净佣金_月累计		
	,COALESCE(T1.S_REPUR_NET_CMS_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS S_REPUR_NET_CMS_YTD  			--正回购净佣金_年累计		
	,COALESCE(T1.R_REPUR_NET_CMS_MTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS R_REPUR_NET_CMS_MTD  			--逆回购净佣金_月累计		
	,COALESCE(T1.R_REPUR_NET_CMS_YTD,0)			* COALESCE(T2.PERFM_RATI3,0)	AS R_REPUR_NET_CMS_YTD  			--逆回购净佣金_年累计		
	,COALESCE(T1.ITC_CRRC_FUND_NET_CMS_MTD,0)	* COALESCE(T2.PERFM_RATI3,0)	AS ITC_CRRC_FUND_NET_CMS_MTD 		--场内货币基金净佣金_月累计				
	,COALESCE(T1.ITC_CRRC_FUND_NET_CMS_YTD,0)	* COALESCE(T2.PERFM_RATI3,0)	AS ITC_CRRC_FUND_NET_CMS_YTD 		--场内货币基金净佣金_年累计				
	,COALESCE(T1.PB_TRD_QTY_MTD,0)				* COALESCE(T2.PERFM_RATI3,0)	AS PB_TRD_QTY_MTD       			--PB交易量_月累计	   		
 FROM #T_PUB_SER_RELA T2
 LEFT JOIN DM.T_EVT_CUS_TRD_M_D T1 
 	ON T1.load_dt=t2.occur_dt 
 		AND T1.CUST_ID=T2.HS_CUST_ID 
 WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	    AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
;

END