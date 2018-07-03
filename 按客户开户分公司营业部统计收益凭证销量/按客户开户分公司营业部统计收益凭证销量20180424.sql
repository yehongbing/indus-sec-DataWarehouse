CREATE OR REPLACE PROCEDURE dm.P_EVT_EMP_PROD_SUBSCR_D(IN @V_BIN_DATE INT)

BEGIN 
/********************************************************************
程序功能: 收益凭证销售金额、客户统计
编写者: WJQ
创建日期: 2018424
简介： 每月统计当月及截至到当月末本年收益凭证销售金额，当月购买客户数，当月购买笔数
       并按客户开户所在分公司、营业部汇总
输入参数：年、月
*********************************************************************
修订记录：修订日期,修订人,修改内容简要说明

*********************************************************************/  

/*
--前端输出报表字段名如下：
CREATE TABLE #T_REPORT_CPXS_SYPZ_FGS_M 
(
 NIAN VARCHAR(4),         --年
 YUE VARCHAR(2),          --月
 FZJD VARCHAR(30),        --分公司发展阶段
 FGS VARCHAR(50),         --分公司
 YYB VARCHAR(60),         --营业部
 XSJE_M NUMERIC(38,8),    --本月收益凭证销售金额
 XSKHS_M INTEGER,         --本月收益凭证销售客户数
 XSBS_M INTEGER,          --本月收益凭证销售笔数
 XSJE_Y NUMERIC(38,8),    --本年收益凭证销售金额
);
*/

DECLARE @NIAN VARCHAR(4);
DECLARE @YUE VARCHAR(2);
DECLARE @I_JYR_MTH_END INTEGER;       --本月最后一个交易日
DECLARE @I_ZRR_MTH_START INTEGER;     --本月第一个自然日
DECLARE @I_ZRR_MTH_END INTEGER;       --本月最后一个自然日
DECLARE @I_ZRR_YEAR_START INTEGER;    --本年第一个自然日

SET @NIAN=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);;
SET @YUE =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);;
SET @I_JYR_MTH_END    =(SELECT MAX(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ = '1' AND NIAN=@NIAN AND YUE =@YUE);
SET @I_ZRR_MTH_START  =(SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE NIAN=@NIAN AND YUE =@YUE);
SET @I_ZRR_MTH_END    =(SELECT MAX(RQ) FROM DBA.T_DDW_D_RQ WHERE NIAN=@NIAN AND YUE =@YUE);
SET @I_ZRR_YEAR_START =(SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE NIAN=@NIAN);
  

INSERT INTO DM.T_REPORT_CPXS_SYPZ_FGS_M 
SELECT @NIAN  AS NIAN,        --年
       @YUE   AS YUE,          --月
       CASE WHEN D.TOP_SEPT_CORP_NAME IN ('福州分公司','厦门分公司','泉州分公司','南平分公司','龙岩分公司','漳州分公司','三明分公司') THEN '成熟期'
            WHEN D.TOP_SEPT_CORP_NAME IN ('北京分公司','上海分公司','广东分公司','深圳分公司','江苏分公司','浙江分公司','山东分公司','陕西分公司',
                           '安徽分公司','四川分公司','湖北分公司','湖南分公司','莆田分公司','黑龙江分公司','内蒙古分公司'
                           ) THEN '成长期'
            WHEN D.TOP_SEPT_CORP_NAME IN ('江西分公司','重庆分公司','新疆分公司','河北分公司','宁德分公司','云南分公司','贵州分公司','天津分公司',
                           '广西分公司','辽宁分公司','山西分公司','河南分公司'
              ) THEN '培育期'
        ELSE NULL
       END AS FZJD,                           --分公司发展阶段
       D.TOP_SEPT_CORP_NAME AS FGS,           --分公司
       D.HR_ORG_NAME AS YYB,                  --营业部
       SUM(CASE WHEN A.OCCUR_DT>=@I_ZRR_MTH_START  
                  THEN COALESCE(A.ITC_SUBS_AMT,0)+COALESCE(A.OTC_SUBS_AMT,0)+COALESCE(A.OTC_PURS_AMT,0)+COALESCE(A.OTC_CASTSL_AMT,0)+COALESCE(A.OTC_COVT_IN_AMT,0)+COALESCE(A.CONTD_SALE_AMT,0)
            ELSE 0
          END)      AS XSJE_M,                   --本月收益凭证销售金额
       COUNT(DISTINCT CASE WHEN A.OCCUR_DT>=@I_ZRR_MTH_START THEN A.CUST_ID ELSE NULL END) AS XSKHS_M,           --本月收益凭证销售客户数
       COUNT(DISTINCT CASE WHEN A.OCCUR_DT>=@I_ZRR_MTH_START THEN A.CUST_ID||A.PROD_CD ELSE NULL END) AS XSBS,   --本月收益凭证销售笔数
     SUM(COALESCE(A.ITC_SUBS_AMT,0)+COALESCE(A.OTC_SUBS_AMT,0)+COALESCE(A.OTC_PURS_AMT,0)+COALESCE(A.OTC_CASTSL_AMT,0)+COALESCE(A.OTC_COVT_IN_AMT,0)+COALESCE(A.CONTD_SALE_AMT,0)) AS XSJE_Y   --本年收益凭证销售金额
 FROM DM.T_EVT_PROD_TRD_D_D A
 LEFT JOIN DM.T_VAR_PROD_OTC B ON A.PROD_CD = B.PROD_CD AND B.OCCUR_DT = @I_JYR_MTH_END 
 LEFT JOIN DM.T_PUB_CUST C ON A.CUST_ID = C.CUST_ID AND C.YEAR=@NIAN AND C.MTH = @YUE
 LEFT JOIN DM.T_PUB_ORG D ON C.WH_ORG_ID = D.WH_ORG_ID AND D.YEAR=@NIAN AND D.MTH=@YUE
 WHERE A.OCCUR_DT>=@I_ZRR_YEAR_START AND A.OCCUR_DT<=@I_ZRR_MTH_END
      AND COALESCE(A.ITC_SUBS_AMT,0)+COALESCE(A.OTC_SUBS_AMT,0)+COALESCE(A.OTC_PURS_AMT,0)+COALESCE(A.OTC_CASTSL_AMT,0)+COALESCE(A.OTC_COVT_IN_AMT,0)+COALESCE(A.CONTD_SALE_AMT,0)>0
      AND B.PROD_TYPE ='收益凭证' 
 GROUP BY FZJD,FGS,YYB;

END;

