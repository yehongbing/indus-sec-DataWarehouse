CREATE OR REPLACE PROCEDURE DM.P_AST_APPTBUYB_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建约定购回资产月表
  编写者: DCY
  创建日期: 2018-01-05
  简介：约定购回资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

--PART0 删除当月数据
  DELETE FROM DM.T_AST_APPTBUYB_M_D WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);

INSERT INTO DM.T_AST_APPTBUYB_M_D 
(
 CUST_ID
,YEAR
,MTH
,NATRE_DAYS_MTH
,NATRE_DAYS_YEAR
,NATRE_DAY_MTHBEG
,YEAR_MTH
,YEAR_MTH_CUST_ID
,GUAR_SECU_MVAL_FINAL
,APPTBUYB_BAL_FINAL
,SH_GUAR_SECU_MVAL_FINAL
,SZ_GUAR_SECU_MVAL_FINAL
,SH_NOTS_GUAR_SECU_MVAL_FINAL
,SZ_NOTS_GUAR_SECU_MVAL_FINAL
,PROP_FINAC_OUT_SIDE_BAL_FINAL
,ASSM_FINAC_OUT_SIDE_BAL_FINAL
,SM_LOAN_FINAC_OUT_BAL_FINAL
,GUAR_SECU_MVAL_MDA
,APPTBUYB_BAL_MDA
,SH_GUAR_SECU_MVAL_MDA
,SZ_GUAR_SECU_MVAL_MDA
,SH_NOTS_GUAR_SECU_MVAL_MDA
,SZ_NOTS_GUAR_SECU_MVAL_MDA
,PROP_FINAC_OUT_SIDE_BAL_MDA
,ASSM_FINAC_OUT_SIDE_BAL_MDA
,SM_LOAN_FINAC_OUT_BAL_MDA
,GUAR_SECU_MVAL_YDA
,APPTBUYB_BAL_YDA
,SH_GUAR_SECU_MVAL_YDA
,SZ_GUAR_SECU_MVAL_YDA
,SH_NOTS_GUAR_SECU_MVAL_YDA
,SZ_NOTS_GUAR_SECU_MVAL_YDA
,PROP_FINAC_OUT_SIDE_BAL_YDA
,ASSM_FINAC_OUT_SIDE_BAL_YDA
,SM_LOAN_FINAC_OUT_BAL_YDA
,LOAD_DT
)
select
	t1.CUST_ID as 客户编码
	,t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t_rq.年||t_rq.月 as 年月
	,t_rq.年||t_rq.月||t1.CUST_ID as 年月客户编码		
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end) as 担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.APPTBUYB_BAL,0) else 0 end) as 约定购回余额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SH_GUAR_SECU_MVAL,0) else 0 end) as 上海担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SZ_GUAR_SECU_MVAL,0) else 0 end) as 深圳担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0) else 0 end) as 上海限售股担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0) else 0 end) as 深圳限售股担保证券市值_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0) else 0 end) as 自营融出方余额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0) else 0 end) as 资管融出方余额_期末
	,sum(case when t_rq.日期=t_rq.自然日_月末 then COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0) else 0 end) as 小额贷融出余额_期末

	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 as 担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.APPTBUYB_BAL,0) else 0 end)/t_rq.自然天数_月 as 约定购回余额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SH_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 as 上海担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SZ_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 as 深圳担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 as 上海限售股担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0) else 0 end)/t_rq.自然天数_月 as 深圳限售股担保证券市值_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0) else 0 end)/t_rq.自然天数_月 as 自营融出方余额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0) else 0 end)/t_rq.自然天数_月 as 资管融出方余额_月日均
	,sum(case when t_rq.日期>=t_rq.自然日_月初 then COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0) else 0 end)/t_rq.自然天数_月 as 小额贷融出余额_月日均

	,sum(COALESCE(t1.GUAR_SECU_MVAL,0))/t_rq.自然天数_年 as 担保证券市值_年日均
	,sum(COALESCE(t1.APPTBUYB_BAL,0))/t_rq.自然天数_年 as 约定购回余额_年日均
	,sum(COALESCE(t1.SH_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 as 上海担保证券市值_年日均
	,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 as 深圳担保证券市值_年日均
	,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 as 上海限售股担保证券市值_年日均
	,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0))/t_rq.自然天数_年 as 深圳限售股担保证券市值_年日均
	,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0))/t_rq.自然天数_年 as 自营融出方余额_年日均
	,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0))/t_rq.自然天数_年 as 资管融出方余额_年日均
	,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0))/t_rq.自然天数_年 as 小额贷融出余额_年日均
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
left join DM.T_AST_APPTBUYB t1 on t_rq.交易日期=t1.OCCUR_DT
group by
	t_rq.年
	,t_rq.月
	,t_rq.自然天数_月
	,t_rq.自然天数_年
	,t_rq.自然日_月初
	,t1.CUST_ID
;

END
