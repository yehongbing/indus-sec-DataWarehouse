CREATE OR REPLACE PROCEDURE DM.P_EVT_PROD_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建产品交易事实月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：产品交易事实月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
              20180321                 dcy                新增年月产品代码+4个续作变量
  *********************************************************************/

--PART0 删除当月数据
  DELETE FROM DM.T_EVT_PROD_TRD_M_D WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);

insert into DM.T_EVT_PROD_TRD_M_D 
(
CUST_ID
,OCCUR_DT
,PROD_CD
,PROD_TYPE
,YEAR
,MTH
,NATRE_DAYS_MTH
,NATRE_DAYS_YEAR
,YEAR_MTH
,YEAR_MTH_CUST_ID
,YEAR_MTH_PROD_CD
,YEAR_MTH_CUST_ID_PROD_CD
,ITC_RETAIN_AMT_FINAL
,OTC_RETAIN_AMT_FINAL
,ITC_RETAIN_SHAR_FINAL
,OTC_RETAIN_SHAR_FINAL
,ITC_RETAIN_AMT_MDA
,OTC_RETAIN_AMT_MDA
,ITC_RETAIN_SHAR_MDA
,OTC_RETAIN_SHAR_MDA
,ITC_RETAIN_AMT_YDA
,OTC_RETAIN_AMT_YDA
,ITC_RETAIN_SHAR_YDA
,OTC_RETAIN_SHAR_YDA
,ITC_SUBS_AMT_MTD
,ITC_PURS_AMT_MTD
,ITC_BUYIN_AMT_MTD
,ITC_REDP_AMT_MTD
,ITC_SELL_AMT_MTD
,OTC_SUBS_AMT_MTD
,OTC_PURS_AMT_MTD
,OTC_CASTSL_AMT_MTD
,OTC_COVT_IN_AMT_MTD
,OTC_REDP_AMT_MTD
,OTC_COVT_OUT_AMT_MTD
,ITC_SUBS_SHAR_MTD
,ITC_PURS_SHAR_MTD
,ITC_BUYIN_SHAR_MTD
,ITC_REDP_SHAR_MTD
,ITC_SELL_SHAR_MTD
,OTC_SUBS_SHAR_MTD
,OTC_PURS_SHAR_MTD
,OTC_CASTSL_SHAR_MTD
,OTC_COVT_IN_SHAR_MTD
,OTC_REDP_SHAR_MTD
,OTC_COVT_OUT_SHAR_MTD
,ITC_SUBS_CHAG_MTD
,ITC_PURS_CHAG_MTD
,ITC_BUYIN_CHAG_MTD
,ITC_REDP_CHAG_MTD
,ITC_SELL_CHAG_MTD
,OTC_SUBS_CHAG_MTD
,OTC_PURS_CHAG_MTD
,OTC_CASTSL_CHAG_MTD
,OTC_COVT_IN_CHAG_MTD
,OTC_REDP_CHAG_MTD
,OTC_COVT_OUT_CHAG_MTD
,ITC_SUBS_AMT_YTD
,ITC_PURS_AMT_YTD
,ITC_BUYIN_AMT_YTD
,ITC_REDP_AMT_YTD
,ITC_SELL_AMT_YTD
,OTC_SUBS_AMT_YTD
,OTC_PURS_AMT_YTD
,OTC_CASTSL_AMT_YTD
,OTC_COVT_IN_AMT_YTD
,OTC_REDP_AMT_YTD
,OTC_COVT_OUT_AMT_YTD
,ITC_SUBS_SHAR_YTD
,ITC_PURS_SHAR_YTD
,ITC_BUYIN_SHAR_YTD
,ITC_REDP_SHAR_YTD
,ITC_SELL_SHAR_YTD
,OTC_SUBS_SHAR_YTD
,OTC_PURS_SHAR_YTD
,OTC_CASTSL_SHAR_YTD
,OTC_COVT_IN_SHAR_YTD
,OTC_REDP_SHAR_YTD
,OTC_COVT_OUT_SHAR_YTD
,ITC_SUBS_CHAG_YTD
,ITC_PURS_CHAG_YTD
,ITC_BUYIN_CHAG_YTD
,ITC_REDP_CHAG_YTD
,ITC_SELL_CHAG_YTD
,OTC_SUBS_CHAG_YTD
,OTC_PURS_CHAG_YTD
,OTC_CASTSL_CHAG_YTD
,OTC_COVT_IN_CHAG_YTD
,OTC_REDP_CHAG_YTD
,OTC_COVT_OUT_CHAG_YTD
,CONTD_SALE_SHAR_MTD
,CONTD_SALE_AMT_MTD 
,CONTD_SALE_SHAR_YTD
,CONTD_SALE_AMT_YTD 
,LOAD_DT
)
select
	t1.CUST_ID as 客户编码
	,@V_BIN_DATE as OCCUR_DT
	,t1.PROD_CD as 产品代码
	,t1.PROD_TYPE as 产品类型
	,t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码
	,t_rq.年||t_rq.月||t1.PROD_CD as 年月产品代码
	,t_rq.年||t_rq.月||t1.CUST_ID||t1.PROD_CD as 年月客户编码产品代码
	
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.ITC_RETAIN_AMT,0) else 0 end) as 场内保有金额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTC_RETAIN_AMT,0) else 0 end) as 场外保有金额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.ITC_RETAIN_SHAR,0) else 0 end) as 场内保有份额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTC_RETAIN_SHAR,0) else 0 end) as 场外保有份额_期末

	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.ITC_RETAIN_AMT,0) else 0 end)/t_rq.自然天数_月 as 场内保有金额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTC_RETAIN_AMT,0) else 0 end)/t_rq.自然天数_月 as 场外保有金额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.ITC_RETAIN_SHAR,0) else 0 end)/t_rq.自然天数_月 as 场内保有份额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTC_RETAIN_SHAR,0) else 0 end)/t_rq.自然天数_月 as 场外保有份额_月日均

	,sum(COALESCE(t1.ITC_RETAIN_AMT,0))/t_rq.自然天数_年 as 场内保有金额_年日均
	,sum(COALESCE(t1.OTC_RETAIN_AMT,0))/t_rq.自然天数_年 as 场外保有金额_年日均
	,sum(COALESCE(t1.ITC_RETAIN_SHAR,0))/t_rq.自然天数_年 as 场内保有份额_年日均
	,sum(COALESCE(t1.OTC_RETAIN_SHAR,0))/t_rq.自然天数_年 as 场外保有份额_年日均

	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_AMT,0) else 0 end) as 场内认购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_AMT,0) else 0 end) as 场内申购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_AMT,0) else 0 end) as 场内买入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_AMT,0) else 0 end) as 场内赎回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_AMT,0) else 0 end) as 场内卖出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_AMT,0) else 0 end) as 场外认购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_AMT,0) else 0 end) as 场外申购金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_AMT,0) else 0 end) as 场外定投金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_AMT,0) else 0 end) as 场外转换入金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_AMT,0) else 0 end) as 场外赎回金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_AMT,0) else 0 end) as 场外转换出金额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_SHAR,0) else 0 end) as 场内认购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_SHAR,0) else 0 end) as 场内申购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_SHAR,0) else 0 end) as 场内买入份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_SHAR,0) else 0 end) as 场内赎回份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_SHAR,0) else 0 end) as 场内卖出份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_SHAR,0) else 0 end) as 场外认购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_SHAR,0) else 0 end) as 场外申购份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_SHAR,0) else 0 end) as 场外定投份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_SHAR,0) else 0 end) as 场外转换入份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_SHAR,0) else 0 end) as 场外赎回份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_SHAR,0) else 0 end) as 场外转换出份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_CHAG,0) else 0 end) as 场内认购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_CHAG,0) else 0 end) as 场内申购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_CHAG,0) else 0 end) as 场内买入手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_CHAG,0) else 0 end) as 场内赎回手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_CHAG,0) else 0 end) as 场内卖出手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_CHAG,0) else 0 end) as 场外认购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_CHAG,0) else 0 end) as 场外申购手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_CHAG,0) else 0 end) as 场外定投手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_CHAG,0) else 0 end) as 场外转换入手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_CHAG,0) else 0 end) as 场外赎回手续费_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_CHAG,0) else 0 end) as 场外转换出手续费_月累计

	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_AMT,0) else 0 end) as 场内认购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_AMT,0) else 0 end) as 场内申购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_AMT,0) else 0 end) as 场内买入金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_AMT,0) else 0 end) as 场内赎回金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_AMT,0) else 0 end) as 场内卖出金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_AMT,0) else 0 end) as 场外认购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_AMT,0) else 0 end) as 场外申购金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_AMT,0) else 0 end) as 场外定投金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_AMT,0) else 0 end) as 场外转换入金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_AMT,0) else 0 end) as 场外赎回金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_AMT,0) else 0 end) as 场外转换出金额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_SHAR,0) else 0 end) as 场内认购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_SHAR,0) else 0 end) as 场内申购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_SHAR,0) else 0 end) as 场内买入份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_SHAR,0) else 0 end) as 场内赎回份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_SHAR,0) else 0 end) as 场内卖出份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_SHAR,0) else 0 end) as 场外认购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_SHAR,0) else 0 end) as 场外申购份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_SHAR,0) else 0 end) as 场外定投份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_SHAR,0) else 0 end) as 场外转换入份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_SHAR,0) else 0 end) as 场外赎回份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_SHAR,0) else 0 end) as 场外转换出份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SUBS_CHAG,0) else 0 end) as 场内认购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_PURS_CHAG,0) else 0 end) as 场内申购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_BUYIN_CHAG,0) else 0 end) as 场内买入手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_REDP_CHAG,0) else 0 end) as 场内赎回手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.ITC_SELL_CHAG,0) else 0 end) as 场内卖出手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_SUBS_CHAG,0) else 0 end) as 场外认购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_PURS_CHAG,0) else 0 end) as 场外申购手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_CASTSL_CHAG,0) else 0 end) as 场外定投手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_IN_CHAG,0) else 0 end) as 场外转换入手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_REDP_CHAG,0) else 0 end) as 场外赎回手续费_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.OTC_COVT_OUT_CHAG,0) else 0 end) as 场外转换出手续费_年累计
	
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_SHAR,0) else 0 end) as 续作销售份额_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 and t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_AMT,0) else 0 end) as 续作销售金额_月累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_SHAR,0) else 0 end) as 续作销售份额_年累计
	,sum(case when t_rq.是否交易日=1 then COALESCE(t1.CONTD_SALE_AMT,0) else 0 end) as 续作销售金额_年累计
	
	,@V_BIN_DATE
from
(
	select
		t1.YEAR as 年
		,t2.MTH as 月
		,t1.DT as 日期
		,t1.TRD_DT as 交易日期
		,t1.if_trd_day_flag as 是否交易日
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
	where t1.YEAR=substr(@V_BIN_DATE||'',1,4) and t2.MTH=substr(@V_BIN_DATE||'',5,2)
) t_rq
--市值保有需填充节假日数据
left join DM.T_EVT_PROD_TRD_D_D t1 on t_rq.交易日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年		
	,t1.CUST_ID
	,t1.PROD_CD
	,t1.PROD_TYPE
;

END
