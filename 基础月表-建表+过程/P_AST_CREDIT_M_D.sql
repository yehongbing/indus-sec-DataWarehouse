CREATE OR REPLACE PROCEDURE DM.P_AST_CREDIT_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建融资融券资产月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：融资融券资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

--PART0 删除当月数据
  DELETE FROM DM.T_AST_CREDIT_M_D WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);

insert into DM.T_AST_CREDIT_M_D 
(
CUST_ID
,OCCUR_DT
,YEAR
,MTH
,NATRE_DAYS_MTH
,NATRE_DAYS_YEAR
,NATRE_DAY_MTHBEG
,YEAR_MTH
,YEAR_MTH_CUST_ID
,TOT_LIAB_FINAL
,NET_AST_FINAL
,CRED_MARG_FINAL
,GUAR_SECU_MVAL_FINAL
,FIN_LIAB_FINAL
,CRDT_STK_LIAB_FINAL
,INTR_LIAB_FINAL
,FEE_LIAB_FINAL
,OTH_LIAB_FINAL
,TOT_AST_FINAL
,TOT_LIAB_MDA
,NET_AST_MDA
,CRED_MARG_MDA
,GUAR_SECU_MVAL_MDA
,FIN_LIAB_MDA
,CRDT_STK_LIAB_MDA
,INTR_LIAB_MDA
,FEE_LIAB_MDA
,OTH_LIAB_MDA
,TOT_AST_MDA
,TOT_LIAB_YDA
,NET_AST_YDA
,CRED_MARG_YDA
,GUAR_SECU_MVAL_YDA
,FIN_LIAB_YDA
,CRDT_STK_LIAB_YDA
,INTR_LIAB_YDA
,FEE_LIAB_YDA
,OTH_LIAB_YDA
,TOT_AST_YDA
,LOAD_DT
)
select
    t1.CUST_ID as 客户编码	
    ,@V_BIN_DATE as OCCUR_DT
	,t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编号
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.TOT_LIAB,0) else 0 end) as 总负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.NET_AST,0) else 0 end) as 净资产_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CRED_MARG,0) else 0 end) as 信用保证金_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end) as 担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.FIN_LIAB,0) else 0 end) as 融资负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.CRDT_STK_LIAB,0) else 0 end) as 融券负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.INTR_LIAB,0) else 0 end) as 利息负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.FEE_LIAB,0) else 0 end) as 费用负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.OTH_LIAB,0) else 0 end) as 其他负债_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.TOT_AST,0) else 0 end) as 总资产_期末

	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.TOT_LIAB,0) else 0 end)/t_rq.自然天数_月 as 总负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.NET_AST,0) else 0 end)/t_rq.自然天数_月 as 净资产_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRED_MARG,0) else 0 end)/t_rq.自然天数_月 as 信用保证金_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 as 担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FIN_LIAB,0) else 0 end)/t_rq.自然天数_月 as 融资负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.CRDT_STK_LIAB,0) else 0 end)/t_rq.自然天数_月 as 融券负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.INTR_LIAB,0) else 0 end)/t_rq.自然天数_月 as 利息负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.FEE_LIAB,0) else 0 end)/t_rq.自然天数_月 as 费用负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.OTH_LIAB,0) else 0 end)/t_rq.自然天数_月 as 其他负债_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.TOT_AST,0) else 0 end)/t_rq.自然天数_月 as 总资产_月日均

	,sum(COALESCE(t1.TOT_LIAB,0))/t_rq.自然天数_年 as 总负债_年日均
	,sum(COALESCE(t1.NET_AST,0))/t_rq.自然天数_年 as 净资产_年日均
	,sum(COALESCE(t1.CRED_MARG,0))/t_rq.自然天数_年 as 信用保证金_年日均
	,sum(COALESCE(t1.GUAR_SECU_MVAL,0))/t_rq.自然天数_年 as 担保证券市值_年日均
	,sum(COALESCE(t1.FIN_LIAB,0))/t_rq.自然天数_年 as 融资负债_年日均
	,sum(COALESCE(t1.CRDT_STK_LIAB,0))/t_rq.自然天数_年 as 融券负债_年日均
	,sum(COALESCE(t1.INTR_LIAB,0))/t_rq.自然天数_年 as 利息负债_年日均
	,sum(COALESCE(t1.FEE_LIAB,0))/t_rq.自然天数_年 as 费用负债_年日均
	,sum(COALESCE(t1.OTH_LIAB,0))/t_rq.自然天数_年 as 其他负债_年日均
	,sum(COALESCE(t1.TOT_AST,0))/t_rq.自然天数_年 as 总资产_年日均
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
left join DM.T_AST_CREDIT t1 on t_rq.交易日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t1.CUST_ID
;

END
