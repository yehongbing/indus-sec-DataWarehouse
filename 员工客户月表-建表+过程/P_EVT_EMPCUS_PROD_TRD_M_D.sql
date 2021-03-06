CREATE OR REPLACE PROCEDURE dm.P_EVT_EMPCUS_PROD_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户产品交易月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户产品交易月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
              20180322                  dcy                新增续作四个变量
  *********************************************************************/

   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	
	--PART0 删除当月数据
	  DELETE FROM DM.T_EVT_EMPCUS_PROD_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

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


	 
	INSERT INTO DM.T_EVT_EMPCUS_PROD_TRD_M_D 
	(
	 YEAR                      --年
	,MTH                       --月
	,OCCUR_DT                  --业务日期
	,CUST_ID                   --客户编码
	,PROD_CD                   --产品代码
	,PROD_TYPE                 --产品类型
	,AFA_SEC_EMPID             --AFA_二期员工号
	,YEAR_MTH                  --年月
	,YEAR_MTH_CUST_ID          --年月客户编码
	,YEAR_MTH_PSN_JNO          --年月员工号
	,YEAR_MTH_CUST_ID_PROD_CD  --年月客户编码产品代码
	,WH_ORG_ID_CUST            --仓库机构编码_客户
	,WH_ORG_ID_EMP             --仓库机构编码_员工
	,ITC_RETAIN_AMT_FINAL      --场内保有金额_期末
	,OTC_RETAIN_AMT_FINAL      --场外保有金额_期末
	,ITC_RETAIN_SHAR_FINAL     --场内保有份额_期末
	,OTC_RETAIN_SHAR_FINAL     --场外保有份额_期末
	,ITC_RETAIN_AMT_MDA        --场内保有金额_月日均
	,OTC_RETAIN_AMT_MDA        --场外保有金额_月日均
	,ITC_RETAIN_SHAR_MDA       --场内保有份额_月日均
	,OTC_RETAIN_SHAR_MDA       --场外保有份额_月日均
	,ITC_RETAIN_AMT_YDA        --场内保有金额_年日均
	,OTC_RETAIN_AMT_YDA        --场外保有金额_年日均
	,ITC_RETAIN_SHAR_YDA       --场内保有份额_年日均
	,OTC_RETAIN_SHAR_YDA       --场外保有份额_年日均
	,ITC_SUBS_AMT_MTD          --场内认购金额_月累计
	,ITC_PURS_AMT_MTD          --场内申购金额_月累计
	,ITC_BUYIN_AMT_MTD         --场内买入金额_月累计
	,ITC_REDP_AMT_MTD          --场内赎回金额_月累计
	,ITC_SELL_AMT_MTD          --场内卖出金额_月累计
	,OTC_SUBS_AMT_MTD          --场外认购金额_月累计
	,OTC_PURS_AMT_MTD          --场外申购金额_月累计
	,OTC_CASTSL_AMT_MTD        --场外定投金额_月累计
	,OTC_COVT_IN_AMT_MTD       --场外转换入金额_月累计
	,OTC_REDP_AMT_MTD          --场外赎回金额_月累计
	,OTC_COVT_OUT_AMT_MTD      --场外转换出金额_月累计
	,ITC_SUBS_SHAR_MTD         --场内认购份额_月累计
	,ITC_PURS_SHAR_MTD         --场内申购份额_月累计
	,ITC_BUYIN_SHAR_MTD        --场内买入份额_月累计
	,ITC_REDP_SHAR_MTD         --场内赎回份额_月累计
	,ITC_SELL_SHAR_MTD         --场内卖出份额_月累计
	,OTC_SUBS_SHAR_MTD         --场外认购份额_月累计
	,OTC_PURS_SHAR_MTD         --场外申购份额_月累计
	,OTC_CASTSL_SHAR_MTD       --场外定投份额_月累计
	,OTC_COVT_IN_SHAR_MTD      --场外转换入份额_月累计
	,OTC_REDP_SHAR_MTD         --场外赎回份额_月累计
	,OTC_COVT_OUT_SHAR_MTD     --场外转换出份额_月累计
	,ITC_SUBS_CHAG_MTD         --场内认购手续费_月累计
	,ITC_PURS_CHAG_MTD         --场内申购手续费_月累计
	,ITC_BUYIN_CHAG_MTD        --场内买入手续费_月累计
	,ITC_REDP_CHAG_MTD         --场内赎回手续费_月累计
	,ITC_SELL_CHAG_MTD         --场内卖出手续费_月累计
	,OTC_SUBS_CHAG_MTD         --场外认购手续费_月累计
	,OTC_PURS_CHAG_MTD         --场外申购手续费_月累计
	,OTC_CASTSL_CHAG_MTD       --场外定投手续费_月累计
	,OTC_COVT_IN_CHAG_MTD      --场外转换入手续费_月累计
	,OTC_REDP_CHAG_MTD         --场外赎回手续费_月累计
	,OTC_COVT_OUT_CHAG_MTD     --场外转换出手续费_月累计
	,ITC_SUBS_AMT_YTD          --场内认购金额_年累计
	,ITC_PURS_AMT_YTD          --场内申购金额_年累计
	,ITC_BUYIN_AMT_YTD         --场内买入金额_年累计
	,ITC_REDP_AMT_YTD          --场内赎回金额_年累计
	,ITC_SELL_AMT_YTD          --场内卖出金额_年累计
	,OTC_SUBS_AMT_YTD          --场外认购金额_年累计
	,OTC_PURS_AMT_YTD          --场外申购金额_年累计
	,OTC_CASTSL_AMT_YTD        --场外定投金额_年累计
	,OTC_COVT_IN_AMT_YTD       --场外转换入金额_年累计
	,OTC_REDP_AMT_YTD          --场外赎回金额_年累计
	,OTC_COVT_OUT_AMT_YTD      --场外转换出金额_年累计
	,ITC_SUBS_SHAR_YTD         --场内认购份额_年累计
	,ITC_PURS_SHAR_YTD         --场内申购份额_年累计
	,ITC_BUYIN_SHAR_YTD        --场内买入份额_年累计
	,ITC_REDP_SHAR_YTD         --场内赎回份额_年累计
	,ITC_SELL_SHAR_YTD         --场内卖出份额_年累计
	,OTC_SUBS_SHAR_YTD         --场外认购份额_年累计
	,OTC_PURS_SHAR_YTD         --场外申购份额_年累计
	,OTC_CASTSL_SHAR_YTD       --场外定投份额_年累计
	,OTC_COVT_IN_SHAR_YTD      --场外转换入份额_年累计
	,OTC_REDP_SHAR_YTD         --场外赎回份额_年累计
	,OTC_COVT_OUT_SHAR_YTD     --场外转换出份额_年累计
	,ITC_SUBS_CHAG_YTD         --场内认购手续费_年累计
	,ITC_PURS_CHAG_YTD         --场内申购手续费_年累计
	,ITC_BUYIN_CHAG_YTD        --场内买入手续费_年累计
	,ITC_REDP_CHAG_YTD         --场内赎回手续费_年累计
	,ITC_SELL_CHAG_YTD         --场内卖出手续费_年累计
	,OTC_SUBS_CHAG_YTD         --场外认购手续费_年累计
	,OTC_PURS_CHAG_YTD         --场外申购手续费_年累计
	,OTC_CASTSL_CHAG_YTD       --场外定投手续费_年累计
	,OTC_COVT_IN_CHAG_YTD      --场外转换入手续费_年累计
	,OTC_REDP_CHAG_YTD         --场外赎回手续费_年累计
	,OTC_COVT_OUT_CHAG_YTD     --场外转换出手续费_年累计
	,LOAD_DT                   --清洗日期
	,CONTD_SALE_SHAR_MTD       --续作销售份额_月累计
	,CONTD_SALE_AMT_MTD        --续作销售金额_月累计
	,CONTD_SALE_SHAR_YTD       --续作销售份额_年累计
	,CONTD_SALE_AMT_YTD        --续作销售金额_年累计

)
SELECT 
	 T2.YEAR AS 年
	,T2.MTH AS 月
	,T2.OCCUR_DT
	,T2.HS_CUST_ID AS 客户编码
	,T1.PROD_CD AS 产品代码
	,T1.PROD_TYPE AS 产品类型
	,T2.AFA_SEC_EMPID AS AFA二期员工号
	,T2.YEAR||T2.MTH AS 年月
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID AS 年月客户编码
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS 年月员工号
	,T2.YEAR||T2.MTH||T1.PROD_CD AS 年月客户编码产品代码
	,T2.WH_ORG_ID_CUST AS 仓库机构编码_客户
	,T2.WH_ORG_ID_EMP AS 仓库机构编码_员工	
	
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) END AS 场内保有金额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) END AS 场外保有金额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) END AS 场内保有份额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) END AS 场外保有份额_期末
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) END AS 场内保有金额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) END AS 场外保有金额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) END AS 场内保有份额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) END AS 场外保有份额_月日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) END AS 场内保有金额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) END AS 场外保有金额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) END AS 场内保有份额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) END AS 场外保有份额_年日均
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) END AS 场内认购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) END AS 场内申购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) END AS 场内买入金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) END AS 场内赎回金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) END AS 场内卖出金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) END AS 场外认购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) END AS 场外申购金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) END AS 场外定投金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) END AS 场外转换入金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) END AS 场外赎回金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) END AS 场外转换出金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) END AS 场内认购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) END AS 场内申购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) END AS 场内买入份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) END AS 场内赎回份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) END AS 场内卖出份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) END AS 场外认购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) END AS 场外申购份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) END AS 场外定投份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) END AS 场外转换入份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) END AS 场外赎回份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) END AS 场外转换出份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) END AS 场内认购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) END AS 场内申购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) END AS 场内买入手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) END AS 场内赎回手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) END AS 场内卖出手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) END AS 场外认购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) END AS 场外申购手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) END AS 场外定投手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) END AS 场外转换入手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) END AS 场外赎回手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) END AS 场外转换出手续费_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) END AS 场内认购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) END AS 场内申购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) END AS 场内买入金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) END AS 场内赎回金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) END AS 场内卖出金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) END AS 场外认购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) END AS 场外申购金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) END AS 场外定投金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) END AS 场外转换入金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) END AS 场外赎回金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) END AS 场外转换出金额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) END AS 场内认购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) END AS 场内申购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) END AS 场内买入份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) END AS 场内赎回份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) END AS 场内卖出份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) END AS 场外认购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) END AS 场外申购份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) END AS 场外定投份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) END AS 场外转换入份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) END AS 场外赎回份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) END AS 场外转换出份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) END AS 场内认购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) END AS 场内申购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) END AS 场内买入手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) END AS 场内赎回手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) END AS 场内卖出手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) END AS 场外认购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) END AS 场外申购手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) END AS 场外定投手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) END AS 场外转换入手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) END AS 场外赎回手续费_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) END AS 场外转换出手续费_年累计
    ,@V_BIN_DATE
	
	--20180321 董新增加续作销售
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) END AS 续作销售份额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) END AS 续作销售金额_月累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) END AS 续作销售份额_年累计
	,CASE WHEN T1.PROD_TYPE='私募基金' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) WHEN T1.PROD_TYPE='集合理财' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) WHEN T1.PROD_TYPE='基金专户' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) END AS 续作销售金额_年累计
FROM #T_PUB_SER_RELA T2
LEFT JOIN DM.T_EVT_PROD_TRD_M_D T1
	ON T1.occur_dt=t2.occur_dt 
		AND T1.CUST_ID=T2.HS_CUST_ID                                  
WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:有责权关系的客户必须要有资金账户
	   AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 排除"总部专用账户"
		AND T1.PROD_CD IS NOT NULL
;

END