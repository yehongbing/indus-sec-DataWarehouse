CREATE OR REPLACE PROCEDURE dm.P_BRKBIS_APPTBUYB_M(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 经纪业务约定购回月报
  编写者: YHB
  创建日期: 2018-05-27
  经纪业务约定购回月报
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180525                  yhb                新建存储过程     
  *********************************************************************/

  DECLARE @V_YEAR VARCHAR(4);		-- 年份
  DECLARE @V_MONTH VARCHAR(2);	-- 月份
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

  --PART0 删除当月数据
  DELETE FROM DM.T_BRKBIS_APPTBUYB_M WHERE YEAR_MTH=@V_YEAR||@V_MONTH;

  INSERT INTO DM.T_BRKBIS_APPTBUYB_M
  (
       YEAR_MTH                     --年月
      ,ORG_NO                       --机构编号
      ,BRH                          --营业部
      ,SEPT_CORP                    --分公司
      ,SEPT_CORP_TYPE               --分公司类型
      ,IF_YEAR_NA                   --是否年新增
      ,IF_MTH_NA                    --是否月新增
      ,ACC_CHAR                     --账户性质
      ,IF_SPCA_ACC                  --是否特殊账户 
      ,AST_SGMTS                    --资产段 
      ,IF_APPTBUYB_CUST_YEAR_NA     --是否约定购回客户_年新增
      ,IF_APPTBUYB_CUST_MTH_NA      --是否约定购回客户_月新增
      ,CUST_NUM                     --客户数
      ,APPTBUYB_TOTAST_FINAL        --约定购回总资产_期末
      ,APPTBUYB_NET_AST_FINAL       --约定购回净资产_期末
      ,APPTBUYB_BAL_FINAL           --约定购回余额_期末
      ,APPTBUYB_TOTAST_MDA          --约定购回总资产_月日均
      ,APPTBUYB_NET_AST_MDA         --约定购回净资产_月日均
      ,APPTBUYB_BAL_MDA             --约定购回余额_月日均
      ,APPTBUYB_TOTAST_YDA          --约定购回总资产_年日均
      ,APPTBUYB_NET_AST_YDA         --约定购回净资产_年日均
      ,APPTBUYB_BAL_YDA             --约定购回余额_年日均
      ,APPTBUYB_NET_CMS_MTD         --约定购回净佣金_月累计
      ,APPTBUYB_RECE_INT_MTD        --约定购回应收利息_月累计
      ,APPTBUYB_PAIDINT_MTD         --约定购回实收利息_月累计
      ,APPTBUYB_CPTL_COST_MTD       --约定购回资金成本_月累计
      ,APPTBUYB_NET_CMS_YTD         --约定购回净佣金_年累计
      ,APPTBUYB_RECE_INT_YTD        --约定购回应收利息_年累计
      ,APPTBUYB_PAIDINT_YTD         --约定购回实收利息_年累计
      ,APPTBUYB_CPTL_COST_YTD       --约定购回资金成本_年累计
  )
  SELECT 
       T1.YEAR||T1.MTH
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN t1.WH_ORG_ID_EMP ELSE t_jg.WH_ORG_ID   END as 机构编号 
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN '总部'           ELSE T_jg.HR_ORG_NAME END as 营业部
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN  '总部' 
          WHEN t_jg.TOP_SEPT_CORP_NAME IS NULL OR T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034'--总部
                                                              )   THEN  T_JG.HR_ORG_NAME   
       ELSE t_jg.TOP_SEPT_CORP_NAME END as 分公司
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL OR T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034'--总部
                                                              )  THEN '总部' 
       ELSE T_JG.ORG_TYPE END   as 分公司类型
      ,T_KHSX.是否年新增 
      ,T_KHSX.是否月新增
      ,T_KHSX.客户类型
      ,T_KHSX.是否特殊账户
      ,T_KHSX.资产段
      ,T_KHSX.是否约定购回客户_月新增
      ,T_KHSX.是否约定购回客户_年新增
      ,SUM(CASE WHEN T_KHSX.客户状态='0' THEN T2.JXBL1 ELSE 0 END)
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_FINAL,0))                         AS     APPTBUYB_TOTAST_FINAL        --约定购回总资产_期末                     
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_FINAL - T1.APPTBUYB_BAL_FINAL,0)) AS     APPTBUYB_NET_AST_FINAL       --约定购回净资产_期末                                         
      ,SUM(COALESCE(T1.APPTBUYB_BAL_FINAL,0))                           AS     APPTBUYB_BAL_FINAL           --约定购回余额_期末                   
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_MDA,0))                           AS     APPTBUYB_TOTAST_MDA          --约定购回总资产_月日均                   
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_MDA - T1.APPTBUYB_BAL_MDA,0))     AS     APPTBUYB_NET_AST_MDA         --约定购回净资产_月日均                                     
      ,SUM(COALESCE(T1.APPTBUYB_BAL_MDA,0))                             AS     APPTBUYB_BAL_MDA             --约定购回余额_月日均                 
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_YDA,0))                           AS     APPTBUYB_TOTAST_YDA          --约定购回总资产_年日均                   
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_YDA - T1.APPTBUYB_BAL_YDA,0))     AS     APPTBUYB_NET_AST_YDA         --约定购回净资产_年日均                                     
      ,SUM(COALESCE(T1.APPTBUYB_BAL_YDA,0))                             AS     APPTBUYB_BAL_YDA             --约定购回余额_年日均                 
      ,SUM(COALESCE(T_XYSR.APPTBUYB_NET_CMS_MTD,0))                     AS     APPTBUYB_NET_CMS_MTD         --约定购回净佣金_月累计                     
      ,0                                                                AS     APPTBUYB_RECE_INT_MTD        --约定购回应收利息_月累计 
      ,SUM(COALESCE(T_XYSR.APPTBUYB_PAIDINT_MTD,0))                     AS     APPTBUYB_PAIDINT_MTD         --约定购回实收利息_月累计                     
      ,0                                                                AS     APPTBUYB_CPTL_COST_MTD       --约定购回资金成本_月累计 
      ,SUM(COALESCE(T_XYSR.APPTBUYB_NET_CMS_YTD,0))                     AS     APPTBUYB_NET_CMS_YTD         --约定购回净佣金_年累计                     
      ,0                                                                AS     APPTBUYB_RECE_INT_YTD        --约定购回应收利息_年累计 
      ,SUM(COALESCE(T_XYSR.APPTBUYB_PAIDINT_YTD,0))                     AS     APPTBUYB_PAIDINT_YTD         --约定购回实收利息_年累计                     
      ,0                                                                AS     APPTBUYB_CPTL_COST_YTD       --约定购回资金成本_年累计 
   FROM DM.T_AST_EMPCUS_APPTBUYB_M_D T1 
  LEFT JOIN DBA.T_DDW_SERV_RELATION T2
        ON T1.YEAR=T2.NIAN 
          AND T1.MTH=T2.YUE 
          AND T2.KHBH_HS=T1.CUST_ID 
          AND T1.AFA_SEC_EMPID=T2.AFATWO_YGH                                                                     
  LEFT JOIN DM.T_EVT_EMPCUS_CRED_INCM_M_D T_XYSR  --员工客户信用收入
        ON T1.YEAR=T_XYSR.YEAR AND T1.MTH=T_XYSR.MTH 
          AND T1.CUST_ID=T_XYSR.CUST_ID 
          AND T1.AFA_SEC_EMPID=T_XYSR.AFA_SEC_EMPID
  LEFT JOIN DM.T_PUB_ORG T_JG         --机构表
        ON T1.YEAR=T_JG.YEAR AND T1.MTH=T_JG.MTH 
          AND T1.WH_ORG_ID_EMP=T_JG.WH_ORG_ID
  LEFT JOIN 
  (                     --客户属性和维度处理
    SELECT 
       T1.YEAR
      ,T1.MTH 
      ,T1.CUST_ID
      ,T1.CUST_STAT_NAME AS 客户状态
      ,CASE WHEN T1.TE_OACT_DT>=T2.NATRE_DAY_MTHBEG THEN 1 ELSE 0 END AS 是否月新增
      ,CASE WHEN T1.TE_OACT_DT>=T2.NATRE_DAY_YEARBGN THEN 1 ELSE 0 END AS 是否年新增
      ,COALESCE(T1.IF_VLD,0) AS 是否有效
      ,COALESCE(T4.IF_SPCA_ACCT,0) AS 是否特殊账户
      ,COALESCE(T1.IF_PROD_NEW_CUST,0)   AS 是否产品新客户
      ,T1.CUST_TYPE_NAME AS 客户类型  
      ,CASE WHEN T3.IF_APPTBUYB_CUST=1 AND T3.APPTBUYB_OPEN_DT>=T2.NATRE_DAY_MTHBEG THEN 1 ELSE 0 END AS 是否约定购回客户_月新增
      ,CASE WHEN T3.IF_APPTBUYB_CUST=1 AND T3.APPTBUYB_OPEN_DT>=T2.NATRE_DAY_YEARBGN THEN 1 ELSE 0 END AS 是否约定购回客户_年新增   
      ,CASE 
          WHEN T5.TOT_AST_MDA<100                                     THEN '00-100以下'
          WHEN T5.TOT_AST_MDA >= 100      AND T5.TOT_AST_MDA<1000     THEN '01-100_1000'
          WHEN T5.TOT_AST_MDA >= 1000     AND T5.TOT_AST_MDA<2000     THEN '02-1000_2000'
          WHEN T5.TOT_AST_MDA >= 2000     AND T5.TOT_AST_MDA<5000     THEN '03-2000_5000'
          WHEN T5.TOT_AST_MDA >= 5000     AND T5.TOT_AST_MDA<10000    THEN '04-5000_1W'
          WHEN T5.TOT_AST_MDA >= 10000    AND T5.TOT_AST_MDA<50000    THEN '05-1W_5W'
          WHEN T5.TOT_AST_MDA >= 50000    AND T5.TOT_AST_MDA<100000   THEN '06-5W_10W'
          WHEN T5.TOT_AST_MDA >= 100000   AND T5.TOT_AST_MDA<200000   THEN '1-10W_20W'
          WHEN T5.TOT_AST_MDA >= 200000   AND T5.TOT_AST_MDA<500000   THEN '2-20W_50W'
          WHEN T5.TOT_AST_MDA >= 500000   AND T5.TOT_AST_MDA<1000000  THEN '3-50W_100W'
          WHEN T5.TOT_AST_MDA >= 1000000  AND T5.TOT_AST_MDA<2000000  THEN '4-100W_200W'
          WHEN T5.TOT_AST_MDA >= 2000000  AND T5.TOT_AST_MDA<3000000  THEN '5-200W_300W'
          WHEN T5.TOT_AST_MDA >= 3000000  AND T5.TOT_AST_MDA<5000000  THEN '6-300W_500W'
          WHEN T5.TOT_AST_MDA >= 5000000  AND T5.TOT_AST_MDA<10000000 THEN '7-500W_1000W'
          WHEN T5.TOT_AST_MDA >= 10000000 AND T5.TOT_AST_MDA<30000000 THEN '8-1000W_3000W'
        WHEN T5.TOT_AST_MDA >= 30000000                             THEN '9-大于3000W'
           END AS 资产段   
      FROM DM.T_PUB_CUST T1   
      LEFT JOIN DM.T_PUB_DATE_M T2 ON T1.YEAR=T2.YEAR AND T1.MTH=T2.MTH
      LEFT JOIN DM.T_PUB_CUST_LIMIT_M_D T3 ON T1.YEAR=T3.YEAR AND T1.MTH=T3.MTH AND T1.CUST_ID=T3.CUST_ID
      LEFT JOIN DM.T_ACC_CPTL_ACC T4 ON T1.YEAR=T4.YEAR AND T1.MTH=T4.MTH AND T1.MAIN_CPTL_ACCT=T4.CPTL_ACCT
      LEFT JOIN DM.T_AST_ODI_M_D T5 ON T1.YEAR=T5.YEAR AND T1.MTH=T5.MTH AND T1.CUST_ID=T5.CUST_ID
        WHERE T1.YEAR=@V_YEAR 
           AND T1.MTH=@V_MONTH
           AND 资产段 IS NOT NULL
  ) T_KHSX ON T1.YEAR=T_KHSX.YEAR AND T1.MTH=T_KHSX.MTH AND T1.CUST_ID=T_KHSX.CUST_ID
  WHERE T1.YEAR = @V_YEAR AND T1.MTH = @V_MONTH
  GROUP BY 
       T1.YEAR||T1.MTH
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN t1.WH_ORG_ID_EMP ELSE t_jg.WH_ORG_ID   END
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN '总部'           ELSE T_jg.HR_ORG_NAME END
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN  '总部' 
          WHEN t_jg.TOP_SEPT_CORP_NAME IS NULL OR T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034'--总部
                                                              )   THEN  T_JG.HR_ORG_NAME   
       ELSE t_jg.TOP_SEPT_CORP_NAME END
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL OR T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034'--总部
                                                              )  THEN '总部' 
       ELSE T_JG.ORG_TYPE END 
      ,T_KHSX.是否年新增 
      ,T_KHSX.是否月新增
      ,T_KHSX.客户类型
      ,T_KHSX.是否特殊账户
      ,T_KHSX.资产段
      ,T_KHSX.是否约定购回客户_月新增
      ,T_KHSX.是否约定购回客户_年新增;
END
