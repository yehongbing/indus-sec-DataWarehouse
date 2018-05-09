CREATE OR REPLACE PROCEDURE DM.P_EVT_CUS_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建客户交易事实月表
  编写者: DCY
  创建日期: 2018-02-28
  简介：客户交易事实月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

  DECLARE @V_ACCU_MDAYS INT;		-- 月累计天数
  DECLARE @V_ACCU_YDAYS INT;		-- 年累计天数
  DECLARE @V_BEGIN_TRAD_DATE INT;	-- 本月开始交易日
  DECLARE @V_YEAR_START_DATE INT; -- 本年开始交易日
  SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4) AND YUE=SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2));
  SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4)  AND IF_TRD_DAY_FLAG=1 ); 
  SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_BIN_DATE);
  SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_BIN_DATE);
--PART0 删除当月数据
  DELETE FROM DM.T_EVT_CUS_TRD_M_D WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);

insert into DM.T_EVT_CUS_TRD_M_D 
(
	 CUST_ID            
	,YEAR                 
	,MTH                  
	,NATRE_DAYS_MTH       
	,NATRE_DAYS_YEAR      
	,YEAR_MTH             
	,YEAR_MTH_CUST_ID     
	,STKF_TRD_QTY_MDA 
	,SCDY_TRD_QTY_MDA     
	,CREDIT_ODI_TRD_QTY_MDA 
	,CREDIT_CRED_TRD_QTY_MDA 
	,STKF_TRD_QTY_MTD     
	,SCDY_TRD_QTY_MTD     
	,S_REPUR_TRD_QTY_MTD  
	,R_REPUR_TRD_QTY_MTD  
	,HGT_TRD_QTY_MTD      
	,SGT_TRD_QTY_MTD      
	,STKPLG_TRD_QTY_MTD   
	,APPTBUYB_TRD_QTY_MTD 
	,CREDIT_TRD_QTY_MTD   
	,OFFUND_TRD_QTY_MTD   
	,OPFUND_TRD_QTY_MTD   
	,BANK_CHRM_TRD_QTY_MTD 
	,SECU_CHRM_TRD_QTY_MTD 
	,CREDIT_ODI_TRD_QTY_MTD 
	,CREDIT_CRED_TRD_QTY_MTD 
	,FIN_AMT_MTD          
	,CRDT_STK_AMT_MTD     
	,STKPLG_BUYB_AMT_MTD  
	,PSTK_OPTN_TRD_QTY_MTD 
	,GROSS_CMS_MTD        
	,NET_CMS_MTD          
	,STKPLG_BUYB_CNT_MTD  
	,CCB_AMT_MTD          
	,CCB_CNT_MTD          
	,FIN_SELL_AMT_MTD     
	,FIN_SELL_CNT_MTD     
	,CRDT_STK_BUYIN_AMT_MTD 
	,CRDT_STK_BUYIN_CNT_MTD 
	,CSS_AMT_MTD          
	,CSS_CNT_MTD          
	,FIN_RTN_AMT_MTD      
	,APPTBUYB_REP_AMT_MTD 
	,APPTBUYB_BUYB_AMT_MTD 
	,APPTBUYB_TRD_AMT_MTD 
	,STKF_TRD_QTY_YDA     
	,SCDY_TRD_QTY_YDA     
	,CREDIT_ODI_TRD_QTY_YDA 
	,CREDIT_CRED_TRD_QTY_YDA 
	,STKF_TRD_QTY_YTD     
	,SCDY_TRD_QTY_YTD     
	,S_REPUR_TRD_QTY_YTD  
	,R_REPUR_TRD_QTY_YTD  
	,HGT_TRD_QTY_YTD      
	,SGT_TRD_QTY_YTD      
	,STKPLG_TRD_QTY_YTD   
	,APPTBUYB_TRD_QTY_YTD 
	,CREDIT_TRD_QTY_YTD   
	,OFFUND_TRD_QTY_YTD   
	,OPFUND_TRD_QTY_YTD   
	,BANK_CHRM_TRD_QTY_YTD 
	,SECU_CHRM_TRD_QTY_YTD 
	,CREDIT_ODI_TRD_QTY_YTD 
	,CREDIT_CRED_TRD_QTY_YTD 
	,FIN_AMT_YTD          
	,CRDT_STK_AMT_YTD     
	,STKPLG_BUYB_AMT_YTD  
	,PSTK_OPTN_TRD_QTY_YTD 
	,GROSS_CMS_YTD        
	,NET_CMS_YTD          
	,STKPLG_BUYB_CNT_YTD  
	,CCB_AMT_YTD          
	,CCB_CNT_YTD          
	,FIN_SELL_AMT_YTD     
	,FIN_SELL_CNT_YTD     
	,CRDT_STK_BUYIN_AMT_YTD 
	,CRDT_STK_BUYIN_CNT_YTD 
	,CSS_AMT_YTD          
	,CSS_CNT_YTD          
	,FIN_RTN_AMT_YTD      
	,APPTBUYB_REP_AMT_YTD 
	,APPTBUYB_BUYB_AMT_YTD 
	,APPTBUYB_TRD_AMT_YTD 
	,LOAD_DT	        
)
select
	t1.CUST_ID as 客户编码	
	,t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKF_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 股基交易量_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SCDY_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 二级交易量_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_ODI_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 信用账户普通交易量_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_CRED_TRD_QTY,0) else 0 end)/t_rq.自然天数_月 as 信用账户信用交易量_月日均
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKF_TRD_QTY,0) else 0 end) as 股基交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SCDY_TRD_QTY,0) else 0 end) as 二级交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.S_REPUR_TRD_QTY,0) else 0 end) as 正回购交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.R_REPUR_TRD_QTY,0) else 0 end) as 逆回购交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.HGT_TRD_QTY,0) else 0 end) as 沪港通交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SGT_TRD_QTY,0) else 0 end) as 深港通交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKPLG_TRD_QTY,0) else 0 end) as 股票质押交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_TRD_QTY,0) else 0 end) as 约定购回交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_TRD_QTY,0) else 0 end) as 融资融券交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OFFUND_TRD_QTY,0) else 0 end) as 场内基金交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OPFUND_TRD_QTY,0) else 0 end) as 场外基金交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.BANK_CHRM_TRD_QTY,0) else 0 end) as 银行理财交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SECU_CHRM_TRD_QTY,0) else 0 end) as 证券理财交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_ODI_TRD_QTY,0) else 0 end) as 信用账户普通交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CREDIT_CRED_TRD_QTY,0) else 0 end) as 信用账户信用交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_AMT,0) else 0 end) as 融资金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_AMT,0) else 0 end) as 融券金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKPLG_BUYB_AMT,0) else 0 end) as 股票质押购回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PSTK_OPTN_TRD_QTY,0) else 0 end) as 个股期权交易量_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.GROSS_CMS,0) else 0 end) as 毛佣金_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.NET_CMS,0) else 0 end) as 净佣金_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.STKPLG_BUYB_CNT,0) else 0 end) as 股票质押购回笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CCB_AMT,0) else 0 end) as 融资买入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CCB_CNT,0) else 0 end) as 融资买入笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_SELL_AMT,0) else 0 end) as 融资卖出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_SELL_CNT,0) else 0 end) as 融资卖出笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_BUYIN_AMT,0) else 0 end) as 融券买入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_BUYIN_CNT,0) else 0 end) as 融券买入笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CSS_AMT,0) else 0 end) as 融券卖出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CSS_CNT,0) else 0 end) as 融券卖出笔数_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_RTN_AMT,0) else 0 end) as 融资归还金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_REP_AMT,0) else 0 end) as 约定购回还款金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_BUYB_AMT,0) else 0 end) as 约定购回购回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_TRD_AMT,0) else 0 end) as 约定购回交易金额_月累计

	,sum(COALESCE(t1.STKF_TRD_QTY,0))/t_rq.自然天数_年 as 股基交易量_年日均
	,sum(COALESCE(t1.SCDY_TRD_QTY,0))/t_rq.自然天数_年 as 二级交易量_年日均
	,sum(COALESCE(t1.CREDIT_ODI_TRD_QTY,0))/t_rq.自然天数_年 as 信用账户普通交易量_年日均
	,sum(COALESCE(t1.CREDIT_CRED_TRD_QTY,0))/t_rq.自然天数_年 as 信用账户信用交易量_年日均
	
	,sum(COALESCE(t1.STKF_TRD_QTY,0)) as 股基交易量_年累计
	,sum(COALESCE(t1.SCDY_TRD_QTY,0)) as 二级交易量_年累计
	,sum(COALESCE(t1.S_REPUR_TRD_QTY,0)) as 正回购交易量_年累计
	,sum(COALESCE(t1.R_REPUR_TRD_QTY,0)) as 逆回购交易量_年累计
	,sum(COALESCE(t1.HGT_TRD_QTY,0)) as 沪港通交易量_年累计
	,sum(COALESCE(t1.SGT_TRD_QTY,0)) as 深港通交易量_年累计
	,sum(COALESCE(t1.STKPLG_TRD_QTY,0)) as 股票质押交易量_年累计
	,sum(COALESCE(t1.APPTBUYB_TRD_QTY,0)) as 约定购回交易量_年累计
	,sum(COALESCE(t1.CREDIT_TRD_QTY,0)) as 融资融券交易量_年累计
	,sum(COALESCE(t1.OFFUND_TRD_QTY,0)) as 场内基金交易量_年累计
	,sum(COALESCE(t1.OPFUND_TRD_QTY,0)) as 场外基金交易量_年累计
	,sum(COALESCE(t1.BANK_CHRM_TRD_QTY,0)) as 银行理财交易量_年累计
	,sum(COALESCE(t1.SECU_CHRM_TRD_QTY,0)) as 证券理财交易量_年累计
	,sum(COALESCE(t1.CREDIT_ODI_TRD_QTY,0)) as 信用账户普通交易量_年累计
	,sum(COALESCE(t1.CREDIT_CRED_TRD_QTY,0)) as 信用账户信用交易量_年累计
	,sum(COALESCE(t1.FIN_AMT,0)) as 融资金额_年累计
	,sum(COALESCE(t1.CRDT_STK_AMT,0)) as 融券金额_年累计
	,sum(COALESCE(t1.STKPLG_BUYB_AMT,0)) as 股票质押购回金额_年累计
	,sum(COALESCE(t1.PSTK_OPTN_TRD_QTY,0)) as 个股期权交易量_年累计
	,sum(COALESCE(t1.GROSS_CMS,0)) as 毛佣金_年累计
	,sum(COALESCE(t1.NET_CMS,0)) as 净佣金_年累计
	,sum(COALESCE(t1.STKPLG_BUYB_CNT,0)) as 股票质押购回笔数_年累计
	,sum(COALESCE(t1.CCB_AMT,0)) as 融资买入金额_年累计
	,sum(COALESCE(t1.CCB_CNT,0)) as 融资买入笔数_年累计
	,sum(COALESCE(t1.FIN_SELL_AMT,0)) as 融资卖出金额_年累计
	,sum(COALESCE(t1.FIN_SELL_CNT,0)) as 融资卖出笔数_年累计
	,sum(COALESCE(t1.CRDT_STK_BUYIN_AMT,0)) as 融券买入金额_年累计
	,sum(COALESCE(t1.CRDT_STK_BUYIN_CNT,0)) as 融券买入笔数_年累计
	,sum(COALESCE(t1.CSS_AMT,0)) as 融券卖出金额_年累计
	,sum(COALESCE(t1.CSS_CNT,0)) as 融券卖出笔数_年累计
	,sum(COALESCE(t1.FIN_RTN_AMT,0)) as 融资归还金额_年累计
	,sum(COALESCE(t1.APPTBUYB_REP_AMT,0)) as 约定购回还款金额_年累计
	,sum(COALESCE(t1.APPTBUYB_BUYB_AMT,0)) as 约定购回购回金额_年累计
	,sum(COALESCE(t1.APPTBUYB_TRD_AMT,0)) as 约定购回交易金额_年累计
	,@V_BIN_DATE
 
from			  
(
	select
		t1.YEAR as 年
		,t2.MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,t2.NATRE_DAY_MTHBEG as 自然日_月初
		,t2.NATRE_DAY_MTHEND as 自然日_月末
		,t2.TRD_DAY_MTHBEG as 交易日_月初
		,t2.TRD_DAY_MTHEND as 交易日_月末
		,t2.NATRE_DAY_YEARBGN as 自然日_年初
		,t2.TRD_DAY_YEARBGN as 交易日_年初
		,t2.NATRE_DAYS_MTH as 自然天数_月
		,t2.TRD_DAYS_MTH as 交易天数_月
		,t2.NATRE_DAYS_YEAR as 自然天数_年
		,t2.TRD_DAYS_YEAR as 交易天数_年
	from DM.T_PUB_DATE t1
	left join DM.T_PUB_DATE_M t2 on t1.YEAR=t2.YEAR and t1.MTH<=t2.MTH	
	where t1.YEAR=substr(@V_BIN_DATE||'',1,4) and t2.MTH=substr(@V_BIN_DATE||'',5,2) and t1.IF_TRD_DAY_FLAG=1
) t_rq
left join DM.T_EVT_CUS_TRD_D_D t1 on t_rq.日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t1.CUST_ID
	,年月
	,年月客户编码
;

-- 补充字段客户交易月表字段

UPDATE DM.T_EVT_CUS_TRD_M_D 
	SET 
		EQT_CLAS_KEPP_PERCN  		= 	T2.EQT_CLAS_KEPP_PERCN 							--权益类持仓占比		
	   ,SCDY_TRD_FREQ_MTD    		= 	T2.SCDY_TRD_FREQ								--二级交易次数_月累计		
	   ,SCDY_TRD_FREQ_YTD    		= 	T2.SCDY_TRD_FREQ_TY								--二级交易次数_年累计		
	   ,RCT_TRD_DT_GT        		= 	T2.RCT_TRD_DT_GT								--最近交易日期_累计		
	   ,RCT_TRD_DT_M         		= 	T2.RCT_TRD_DT_M									--最近交易日期_本月		
	   ,Y_RCT_STK_TRD_QTY    		= 	T2.Y_RCT_STK_TRD_QTY							--近12月股票交易量		
	   ,TRD_FREQ_MTD         		= 	T2.TRD_FREQ										--交易次数_月累计		
	   ,TRD_FREQ_YTD         		= 	T2.TRD_FREQ_TY									--交易次数_年累计		
	   ,REPQ_TRD_QTY_MTD     		= 	T2.REPQ_TRD_QTY									--报价回购交易量_月累计		
	   ,REPQ_TRD_QTY_YTD     		= 	T2.REPQ_TRD_QTY_TY								--报价回购交易量_年累计		
	   ,BGDL_QTY_MTD         		= 	T2.BGDL_QTY										--大宗交易量_月累计		
	   ,BGDL_QTY_YTD         		= 	T2.BGDL_QTY_TY									--大宗交易量_年累计		
	   ,PB_TRD_QTY_MTD       		= 	T2.PB_TRD_QTY									--PB交易量_月累计			
	   ,MAIN_CPTL_ACCT       		= 	T2.MAIN_CPTL_ACCT								--主资金账号			
	   ,S_REPUR_TRD_QTY_MDA  		= 	T2.S_REPUR_TRD_QTY/@V_ACCU_MDAYS				--正回购交易量_月日均		
	   ,R_REPUR_TRD_QTY_MDA  		= 	T2.S_REPUR_TRD_QTY_TY/@V_ACCU_MDAYS				--逆回购交易量_月日均		
	   ,S_REPUR_TRD_QTY_YDA  		= 	T2.S_REPUR_TRD_QTY/@V_ACCU_YDAYS				--正回购交易量_年日均		
	   ,R_REPUR_TRD_QTY_YDA  		= 	T2.S_REPUR_TRD_QTY/@V_ACCU_YDAYS				--逆回购交易量_年日均  
	 FROM DM.T_EVT_CUS_TRD_M_D T1
	 LEFT JOIN DM.T_EVT_CUS_ODI_TRD_M_D T2
	 	ON T1.YEAR = T2.YEAR 
	 		AND T1.MTH = T2.MTH
	 		AND T1.CUST_ID = T2.CUST_ID;

-- 补充场内委托事实表字段
SELECT 
     A.OCCUR_DT
    ,A.CUST_ID
    ,SUM(CASE WHEN A.SECU_TYPE IN ('10','18','24') THEN A.MTCH_VOL ELSE 0 END ) AS SB_TRD_QTY_MTD
    ,SUM(CASE WHEN A.SECU_TYPE IN ('12','13','14') THEN A.MTCH_VOL ELSE 0 END ) AS BOND_TRD_QTY_MTD
    --SUM(CASE WHEN SECU_TYPE = '19' THEN MTCH_VOL END ) AS 场内开基交易量
INTO #TEMP_A
FROM DM.T_EVT_ITC_ORDR_TRD_D_D A
WHERE A.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_BIN_DATE
 	AND A.MKT_TYPE IN  ( '01','02','03','04','05','0G','0S')
GROUP BY A.OCCUR_DT,A.CUST_ID;

SELECT 
     A.OCCUR_DT
    ,A.CUST_ID
    ,SUM(CASE WHEN A.SECU_TYPE IN ('10','18','24') THEN A.MTCH_VOL ELSE 0 END ) AS SB_TRD_QTY_YTD
    ,SUM(CASE WHEN A.SECU_TYPE IN ('12','13','14') THEN A.MTCH_VOL ELSE 0 END ) AS BOND_TRD_QTY_YTD
    --SUM(CASE WHEN SECU_TYPE = '19' THEN MTCH_VOL END ) AS 场内开基交易量
INTO #TEMP_B
FROM DM.T_EVT_ITC_ORDR_TRD_D_D A
WHERE A.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_BIN_DATE
 	AND A.MKT_TYPE IN  ( '01','02','03','04','05','0G','0S')
GROUP BY A.OCCUR_DT,A.CUST_ID;

UPDATE DM.T_EVT_CUS_TRD_M_D 
	SET 
	   SB_TRD_QTY_MTD       		= 		T2.SB_TRD_QTY_MTD				--三板交易量_月累计		
	  ,SB_TRD_QTY_YTD       		= 		T3.SB_TRD_QTY_YTD				--三板交易量_年累计		
	  ,BOND_TRD_QTY_MTD     		= 		T2.BOND_TRD_QTY_MTD				--债券交易量_月累计		
	  ,BOND_TRD_QTY_YTD     		= 		T3.BOND_TRD_QTY_YTD				--债券交易量_年累计		
	  ,ITC_CRRC_FUND_TRD_QTY_MTD	= 		0								--场内货币基金交易量_月累计		
	  ,ITC_CRRC_FUND_TRD_QTY_YTD	= 		0								--场内货币基金交易量_年累计		
	  ,S_REPUR_NET_CMS_MTD  		= 		0								--正回购净佣金_月累计		
	  ,S_REPUR_NET_CMS_YTD  		= 		0								--正回购净佣金_年累计		
	  ,R_REPUR_NET_CMS_MTD  		= 		0								--逆回购净佣金_月累计		
	  ,R_REPUR_NET_CMS_YTD  		= 		0								--逆回购净佣金_年累计		
	  ,ITC_CRRC_FUND_NET_CMS_MTD	= 		0								--场内货币基金净佣金_月累计		
	  ,ITC_CRRC_FUND_NET_CMS_YTD	= 		0								--场内货币基金净佣金_年累计		
	 FROM DM.T_EVT_CUS_TRD_M_D T1
	 LEFT JOIN #TEMP_A T2
	 	ON T1.OCCUR_DT = T2.OCCUR_DT
	 		AND T1.CUST_ID = T2.CUST_ID
	 LEFT JOIN #TEMP_B T3
	 	ON T1.OCCUR_DT = T2.OCCUR_DT
	 		AND T1.CUST_ID = T2.CUST_ID;

END
