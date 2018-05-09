CREATE OR REPLACE PROCEDURE DM.P_AST_CPTL_CHG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建资产变动月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：资产变动月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

--PART0 删除当月数据
  DELETE FROM DM.T_AST_CPTL_CHG_M_D WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);

insert into DM.T_AST_CPTL_CHG_M_D 
(
CUST_ID
,YEAR
,MTH
,YEAR_MTH
,YEAR_MTH_CUST_ID
,ODI_CPTL_INFLOW_MTD
,ODI_CPTL_OUTFLOW_MTD
,ODI_MVAL_INFLOW_MTD
,ODI_MVAL_OUTFLOW_MTD
,CREDIT_CPTL_INFLOW_MTD
,CREDIT_CPTL_OUTFLOW_MTD
,ODI_ACC_CPTL_NET_INFLOW_MTD
,CREDIT_CPTL_NET_INFLOW_MTD
,ODI_CPTL_INFLOW_YTD
,ODI_CPTL_OUTFLOW_YTD
,ODI_MVAL_INFLOW_YTD
,ODI_MVAL_OUTFLOW_YTD
,CREDIT_CPTL_INFLOW_YTD
,CREDIT_CPTL_OUTFLOW_YTD
,ODI_ACC_CPTL_NET_INFLOW_YTD
,CREDIT_CPTL_NET_INFLOW_YTD
,LOAD_DT
)
select		
	t1.CUST_ID as 客户编码			
	,t_rq.年
	,t_rq.月		
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_CPTL_INFLOW else 0 end) as 普通资金流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_CPTL_OUTFLOW else 0 end) as 普通资金流出_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_MVAL_INFLOW else 0 end) as 普通市值流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_MVAL_OUTFLOW else 0 end) as 普通市值流出_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.CREDIT_CPTL_INFLOW else 0 end) as 两融资金流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.CREDIT_CPTL_OUTFLOW else 0 end) as 两融资金流出_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.ODI_ACC_CPTL_NET_INFLOW else 0 end) as 普通账户资金净流入_月累计
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then t1.CREDIT_CPTL_NET_INFLOW else 0 end) as 两融资金净流入_月累计

	,sum(t1.ODI_CPTL_INFLOW) as 普通资金流入_年累计
	,sum(t1.ODI_CPTL_OUTFLOW) as 普通资金流出_年累计
	,sum(t1.ODI_MVAL_INFLOW) as 普通市值流入_年累计
	,sum(t1.ODI_MVAL_OUTFLOW) as 普通市值流出_年累计
	,sum(t1.CREDIT_CPTL_INFLOW) as 两融资金流入_年累计
	,sum(t1.CREDIT_CPTL_OUTFLOW) as 两融资金流出_年累计
	,sum(t1.ODI_ACC_CPTL_NET_INFLOW) as 普通账户资金净流入_年累计
	,sum(t1.CREDIT_CPTL_NET_INFLOW) as 两融资金净流入_年累计
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
	where t1.YEAR=substr(@V_BIN_DATE||'',1,4) and t2.MTH=substr(@V_BIN_DATE||'',5,2)
) t_rq
--资产变动不填充
left join DM.T_AST_CPTL_CHG t1 on t_rq.交易日期=t1.OCCUR_DT	
group by
	t_rq.年
	,t_rq.月		
	,t1.CUST_ID
;

END
