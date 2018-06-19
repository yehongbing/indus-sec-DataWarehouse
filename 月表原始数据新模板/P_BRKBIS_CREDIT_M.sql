create PROCEDURE dm.P_BRKBIS_CREDIT_M(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 经纪业务融资融券月报
  编写者: YHB
  创建日期: 2018-05-25
  经纪业务融资融券月报
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180525                  yhb                新建存储过程     
  *********************************************************************/
  --declare @V_BIN_DATE int;
  DECLARE @V_YEAR VARCHAR(4);		-- 年份
  DECLARE @V_MONTH VARCHAR(2);	-- 月份
  --set @V_BIN_DATE=20180427;
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

  --PART0 删除当月数据
  DELETE FROM DM.T_BRKBIS_CREDIT_M WHERE YEAR_MTH=@V_YEAR||@V_MONTH;

  INSERT INTO DM.T_BRKBIS_CREDIT_M
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
    ,IF_CREDIT_YEAR_NA            --是否融资融券年新增
    ,IF_CREDIT_MTH_NA             --是否融资融券月新增
    ,CUST_NUM                     --客户数
    ,CREDIT_EFF_HOUS              --融资融券有效户数
    ,CREDIT_CRED_QUO              --融资融券授信额度
    ,CREDIT_TOTAST_FINAL          --融资融券总资产_期末
    ,CREDIT_NET_AST_FINAL         --融资融券净资产_期末
    ,CREDIT_TOT_LIAB_FINAL        --融资融券总负债_期末
    ,CREDIT_BAL_FINAL             --融资融券余额_期末
    ,CRED_MARG_FINAL              --信用保证金_期末
    ,CREDIT_TOTAST_MDA            --融资融券总资产_月日均
    ,CREDIT_NET_AST_MDA           --融资融券净资产_月日均
    ,CREDIT_TOT_LIAB_MDA          --融资融券总负债_月日均
    ,CREDIT_BAL_MDA               --融资融券余额_月日均
    ,CRED_MARG_MDA                --信用保证金_月日均
    ,CREDIT_TOTAST_YDA            --融资融券总资产_年日均
    ,CREDIT_NET_AST_YDA           --融资融券净资产_年日均
    ,CREDIT_TOT_LIAB_YDA          --融资融券总负债_年日均
    ,CREDIT_BAL_YDA               --融资融券余额_年日均
    ,CRED_MARG_YDA                --信用保证金_年日均
    ,CCB_MTD                      --融资买入_月累计
    ,CSS_MTD                      --融券卖出_月累计
    ,FIN_SELL_MTD                 --融资卖出_月累计
    ,CRDT_STK_BUYIN_MTD           --融券买入_月累计
    ,CCB_YTD                      --融资买入_年累计
    ,CSS_YTD                      --融券卖出_年累计
    ,FIN_SELL_YTD                 --融资卖出_年累计
    ,CRDT_STK_BUYIN_YTD           --融券买入_年累计
    ,CREDIT_TRD_QTY_ODI_MTD       --融资融券交易量_普通_月累计
    ,CREDIT_TRD_QTY_CRED_MTD      --融资融券交易量_信用_月累计
    ,CREDIT_TRD_QTY_ODI_YTD       --融资融券交易量_普通_年累计
    ,CREDIT_TRD_QTY_CRED_YTD      --融资融券交易量_信用_年累计
    ,CREDIT_NET_CMS_ODI_MTD       --融资融券净佣金_普通_月累计
    ,CREDIT_NET_CMS_CRED_MTD      --融资融券净佣金_信用_月累计
    ,CREDIT_NET_CMS_ODI_YTD       --融资融券净佣金_普通_年累计
    ,CREDIT_NET_CMS_CRED_YTD      --融资融券净佣金_信用_年累计
    ,CREDIT_RECE_INT_MTD          --融资融券应收利息_月累计
    ,CREDIT_PAIDINT_MTD           --融资融券实收利息_月累计
    ,CREDIT_CPTL_COST_MTD         --融资融券资金成本_月累计
    ,CREDIT_MARG_SPR_INCM_MTD     --融资融券保证金利差收入_月累计
    ,CREDIT_RECE_INT_YTD          --融资融券应收利息_年累计
    ,CREDIT_PAIDINT_YTD           --融资融券实收利息_年累计
    ,CREDIT_CPTL_COST_YTD         --融资融券资金成本_年累计
    ,CREDIT_MARG_SPR_INCM_YTD     --融资融券保证金利差收入_年累计
  )
  SELECT 
    T1.YEAR||T1.MTH
    , CASE WHEN t_jg.WH_ORG_ID IS NULL THEN t1.WH_ORG_ID_EMP ELSE t_jg.WH_ORG_ID END   as 机构编号	
    , CASE WHEN t_jg.WH_ORG_ID IS NULL THEN '总部'           ELSE T_jg.HR_ORG_NAME END as 营业部
    , CASE 
           WHEN t_jg.WH_ORG_ID IS NULL THEN  '总部' 
           WHEN t_jg.TOP_SEPT_CORP_NAME  IS NULL  OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')   THEN  T_JG.HR_ORG_NAME   ELSE t_jg.TOP_SEPT_CORP_NAME END as 分公司
     , CASE WHEN t_jg.WH_ORG_ID IS NULL OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')  THEN '总部' 
          ELSE T_JG.ORG_TYPE END   as 分公司类型
    ,T_KHSX.是否年新增 
    ,T_KHSX.是否月新增
    ,CASE WHEN T_KHSX.客户类型 IS NULL THEN '其他' ELSE T_KHSX.客户类型 END
    ,T_KHSX.是否特殊账户
    ,T_KHSX.资产段
    ,T_KHSX.是否融资融券年新增  
    ,T_KHSX.是否融资融券月新增
    ,SUM(CASE WHEN T_KHSX.客户状态='正常' THEN T2.JXBL1 ELSE 0 END)
    ,SUM(CASE WHEN T_KHSX.客户状态='正常' AND T_KHSX.是否融资融券客户=1 AND T_KHSX.是否融资融券有效客户=1 THEN T2.JXBL9 ELSE 0 END)
    ,SUM(COALESCE(T_KHSX.融资融券授信额度,0)*T2.JXBL1)         AS     CREDIT_CRED_QUO              --融资融券授信额度        
    ,SUM(COALESCE(T1.TOT_AST_FINAL,0))                AS     CREDIT_TOTAST_FINAL          --总资产_期末
    ,SUM(COALESCE(T1.NET_AST_FINAL,0))                AS     CREDIT_NET_AST_FINAL         --净资产_期末
    ,SUM(COALESCE(T1.TOT_LIAB_FINAL,0))               AS     CREDIT_TOT_LIAB_FINAL        --总负债_期末
    ,SUM(COALESCE(T3.CREDIT_BAL_FINAL,0))             AS     CREDIT_BAL_FINAL             --融资融券余额_期末
    ,SUM(COALESCE(T1.CRED_MARG_FINAL,0))              AS     CRED_MARG_FINAL              --信用保证金_期末
    ,SUM(COALESCE(T1.TOT_AST_MDA,0))                  AS     CREDIT_TOTAST_MDA            --总资产_月日均
    ,SUM(COALESCE(T1.NET_AST_MDA,0))                  AS     CREDIT_NET_AST_MDA           --净资产_月日均
    ,SUM(COALESCE(T1.TOT_LIAB_MDA,0))                 AS     CREDIT_TOT_LIAB_MDA          --总负债_月日均
    ,SUM(COALESCE(T3.CREDIT_BAL_MDA,0))               AS     CREDIT_BAL_MDA               --融资融券余额_月日均
    ,SUM(COALESCE(T1.CRED_MARG_MDA,0))                AS     CRED_MARG_MDA                --信用保证金_月日均    
    ,SUM(COALESCE(T1.TOT_AST_YDA,0))                  AS     CREDIT_TOTAST_YDA            --总资产_年日均
    ,SUM(COALESCE(T1.NET_AST_YDA,0))                  AS     CREDIT_NET_AST_YDA           --净资产_年日均
    ,SUM(COALESCE(T1.TOT_LIAB_YDA,0))                 AS     CREDIT_TOT_LIAB_YDA          --总负债_年日均
    ,SUM(COALESCE(T3.CREDIT_BAL_YDA,0))               AS     CREDIT_BAL_YDA               --融资融券余额_年日均
    ,SUM(COALESCE(T1.CRED_MARG_YDA,0))                AS     CRED_MARG_YDA                --信用保证金_年日均
    ,SUM(COALESCE(T4.CCB_AMT_MTD,0))                  AS     CCB_MTD                      --融资买入金额_月累计
    ,SUM(COALESCE(T4.CSS_AMT_MTD,0))                  AS     CSS_MTD                      --融券卖出金额_月累计
    ,SUM(COALESCE(T4.FIN_SELL_AMT_MTD,0))             AS     FIN_SELL_MTD                 --融资卖出金额_月累计
    ,SUM(COALESCE(T4.CRDT_STK_BUYIN_AMT_MTD,0))       AS     CRDT_STK_BUYIN_MTD           --融券买入金额_月累计
    ,SUM(COALESCE(T4.CCB_AMT_YTD,0))                  AS     CCB_YTD                      --融资买入金额_年累计
    ,SUM(COALESCE(T4.CSS_AMT_YTD,0))                  AS     CSS_YTD                      --融券卖出金额_年累计
    ,SUM(COALESCE(T4.FIN_SELL_AMT_YTD,0))             AS     FIN_SELL_YTD                 --融资卖出金额_年累计
    ,SUM(COALESCE(T4.CRDT_STK_BUYIN_AMT_YTD,0))       AS     CRDT_STK_BUYIN_YTD           --融券买入金额_年累计
    ,SUM(COALESCE(T4.CREDIT_TRD_QTY_MTD,0))           AS     CREDIT_TRD_QTY_ODI_MTD       --融资融券交易量_普通_月累计
    ,SUM(COALESCE(T4.CREDIT_TRD_QTY_MTD,0))           AS     CREDIT_TRD_QTY_CRED_MTD      --融资融券交易量_信用_月累计
    ,SUM(COALESCE(T4.CREDIT_TRD_QTY_YTD,0))           AS     CREDIT_TRD_QTY_ODI_YTD       --融资融券交易量_普通_年累计
    ,SUM(COALESCE(T4.CREDIT_TRD_QTY_YTD,0))           AS     CREDIT_TRD_QTY_CRED_YTD      --融资融券交易量_信用_年累计
    ,SUM(COALESCE(T5.CREDIT_ODI_NET_CMS_MTD,0))       AS     CREDIT_NET_CMS_ODI_MTD       --融资融券净佣金_普通_月累计
    ,SUM(COALESCE(T5.CREDIT_CRED_NET_CMS_MTD,0))      AS     CREDIT_NET_CMS_CRED_MTD      --融资融券净佣金_信用_月累计
    ,SUM(COALESCE(T5.CREDIT_ODI_NET_CMS_YTD,0))       AS     CREDIT_NET_CMS_ODI_YTD       --融资融券净佣金_普通_年累计
    ,SUM(COALESCE(T5.CREDIT_CRED_NET_CMS_YTD,0))      AS     CREDIT_NET_CMS_CRED_YTD      --融资融券净佣金_信用_年累计
    ,SUM(COALESCE(T5.FIN_RECE_INT_MTD,0))             AS     CREDIT_RECE_INT_MTD          --融资融券应收利息_月累计
    ,SUM(COALESCE(T5.FIN_PAIDINT_MTD,0))              AS     CREDIT_PAIDINT_MTD           --融资融券实收利息_月累计
    ,SUM(COALESCE(T5.CREDIT_CPTL_COST_MTD,0))         AS     CREDIT_CPTL_COST_MTD         --融资融券资金成本_月累计
    ,SUM(COALESCE(T5.CREDIT_MARG_SPR_INCM_MTD,0))     AS     CREDIT_MARG_SPR_INCM_MTD     --融资融券保证金利差收入_月累计
    ,SUM(COALESCE(T5.FIN_RECE_INT_YTD,0))             AS     CREDIT_RECE_INT_YTD          --融资融券应收利息_年累计
    ,SUM(COALESCE(T5.FIN_PAIDINT_YTD,0))              AS     CREDIT_PAIDINT_YTD           --融资融券实收利息_年累计
    ,SUM(COALESCE(T5.CREDIT_CPTL_COST_YTD,0))         AS     CREDIT_CPTL_COST_YTD         --融资融券资金成本_年累计       
    ,SUM(COALESCE(T5.CREDIT_MARG_SPR_INCM_YTD,0))     AS     CREDIT_MARG_SPR_INCM_YTD     --融资融券保证金利差收入_年累计

  FROM DM.T_AST_EMPCUS_CREDIT_M_D T1
  LEFT JOIN DBA.T_DDW_SERV_RELATION T2
        ON T1.YEAR=T2.NIAN 
          AND T1.MTH=T2.YUE 
          AND T2.KHBH_HS=T1.CUST_ID 
          AND T1.AFA_SEC_EMPID=T2.AFATWO_YGH
  LEFT JOIN DM.T_AST_EMPCUS_ODI_M_D T3
        ON T1.YEAR=T3.YEAR 
          AND T1.MTH=T3.MTH 
          AND T1.CUST_ID=T3.CUST_ID 
          AND T1.AFA_SEC_EMPID=T3.AFA_SEC_EMPID         
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
      ,COALESCE(T3.IF_CREDIT_CUST,0) AS 是否融资融券客户
      ,COALESCE(T3.IF_CREDIT_EFF_CUST,0) AS 是否融资融券有效客户    
      ,CASE WHEN T3.IF_CREDIT_CUST=1 AND T3.CREDIT_OPEN_DT>=T2.NATRE_DAY_MTHBEG THEN 1 ELSE 0 END AS 是否融资融券月新增
      ,CASE WHEN T3.IF_CREDIT_CUST=1 AND T3.CREDIT_OPEN_DT>=T2.NATRE_DAY_YEARBGN THEN 1 ELSE 0 END AS 是否融资融券年新增   
      ,CASE WHEN T3.IF_CREDIT_CUST=1 AND T3.CREDIT_EFF_ACT_DT>=T2.NATRE_DAY_MTHBEG THEN 1 ELSE 0 END AS 是否融资融券月新增有效户
      ,CASE WHEN T3.IF_CREDIT_CUST=1 AND T3.CREDIT_EFF_ACT_DT>=T2.NATRE_DAY_YEARBGN THEN 1 ELSE 0 END AS 是否融资融券年新增有效户
      ,T3.CREDIT_CRED_QUO AS 融资融券授信额度
      ,T3.APPTBUYB_CRED_QUO AS 约定购回授信额度   
      ,T3.STKPLG_CRED_QUO AS 股票质押授信额度
      ,CASE 
          WHEN COALESCE(T5.TOT_AST_MDA,0)<100                                     THEN '00-100以下'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 100      AND COALESCE(T5.TOT_AST_MDA,0)<1000     THEN '01-100_1000'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 1000     AND COALESCE(T5.TOT_AST_MDA,0)<2000     THEN '02-1000_2000'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 2000     AND COALESCE(T5.TOT_AST_MDA,0)<5000     THEN '03-2000_5000'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 5000     AND COALESCE(T5.TOT_AST_MDA,0)<10000    THEN '04-5000_1W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 10000    AND COALESCE(T5.TOT_AST_MDA,0)<50000    THEN '05-1W_5W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 50000    AND COALESCE(T5.TOT_AST_MDA,0)<100000   THEN '06-5W_10W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 100000   AND COALESCE(T5.TOT_AST_MDA,0)<200000   THEN '1-10W_20W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 200000   AND COALESCE(T5.TOT_AST_MDA,0)<500000   THEN '2-20W_50W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 500000   AND COALESCE(T5.TOT_AST_MDA,0)<1000000  THEN '3-50W_100W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 1000000  AND COALESCE(T5.TOT_AST_MDA,0)<2000000  THEN '4-100W_200W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 2000000  AND COALESCE(T5.TOT_AST_MDA,0)<3000000  THEN '5-200W_300W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 3000000  AND COALESCE(T5.TOT_AST_MDA,0)<5000000  THEN '6-300W_500W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 5000000  AND COALESCE(T5.TOT_AST_MDA,0)<10000000 THEN '7-500W_1000W'
          WHEN COALESCE(T5.TOT_AST_MDA,0) >= 10000000 AND COALESCE(T5.TOT_AST_MDA,0)<30000000 THEN '8-1000W_3000W'
        WHEN COALESCE(T5.TOT_AST_MDA,0) >= 30000000                             THEN '9-大于3000W'
           END AS 资产段   
      FROM DM.T_PUB_CUST T1   
      LEFT JOIN DM.T_PUB_DATE_M         T2 ON T1.YEAR=T2.YEAR AND T1.MTH=T2.MTH
      LEFT JOIN DM.T_PUB_CUST_LIMIT_M_D T3 ON T1.YEAR=T3.YEAR AND T1.MTH=T3.MTH AND T1.CUST_ID=T3.CUST_ID
      LEFT JOIN DM.T_ACC_CPTL_ACC       T4 ON T1.YEAR=T4.YEAR AND T1.MTH=T4.MTH AND T1.MAIN_CPTL_ACCT=T4.CPTL_ACCT
      LEFT JOIN DM.T_AST_ODI_M_D        T5 ON T1.YEAR=T5.YEAR AND T1.MTH=T5.MTH AND T1.CUST_ID=T5.CUST_ID
        WHERE T1.YEAR = @V_YEAR 
          AND T1.MTH =  @V_MONTH
           --AND 资产段 IS NOT NULL
  ) T_KHSX ON T1.YEAR=T_KHSX.YEAR AND T1.MTH=T_KHSX.MTH AND T1.CUST_ID=T_KHSX.CUST_ID
   LEFT JOIN DM.T_EVT_EMPCUS_ODI_TRD_M_D T4
        ON T1.YEAR = T4.YEAR
          AND T1.MTH = T4.MTH
          AND T1.AFA_SEC_EMPID = T4.AFA_SEC_EMPID
          AND T1.CUST_ID = T4.CUST_ID
   LEFT JOIN DM.T_EVT_EMPCUS_CRED_INCM_M_D T5
        ON T1.YEAR = T5.YEAR 
          AND T1.MTH = T5.MTH
          AND T1.AFA_SEC_EMPID = T5.AFA_SEC_EMPID
          AND T1.CUST_ID = T5.CUST_ID      
  WHERE T1.YEAR = @V_YEAR 
    AND T1.MTH =  @V_MONTH
    --AND T_KHSX.是否年新增  IS NOT NULL
  GROUP BY 
     T1.YEAR||T1.MTH
	,机构编号	
	,营业部
	,分公司
    ,分公司类型
    ,T_KHSX.是否年新增 
    ,T_KHSX.是否月新增
    ,T_KHSX.客户类型
    ,T_KHSX.是否特殊账户
    ,T_KHSX.资产段
    ,T_KHSX.是否融资融券年新增
    ,T_KHSX.是否融资融券月新增;

END