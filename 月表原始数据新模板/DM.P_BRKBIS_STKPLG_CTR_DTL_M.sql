CREATE OR REPLACE PROCEDURE dm.P_BRKBIS_STKPLG_CTR_DTL_M(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 经纪业务股票质押合同明细月报
  编写者: YHB
  创建日期: 2018-05-25
  经纪业务股票质押合同明细月报
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180525                  yhb                新建存储过程     
  *********************************************************************/

  DECLARE @V_YEAR VARCHAR(4);		-- 年份
  DECLARE @V_MONTH VARCHAR(2);	-- 月份
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

  --PART0 删除当月数据
  DELETE FROM DM.T_BRKBIS_STKPLG_CTR_DTL_M WHERE YEAR_MTH=@V_YEAR||@V_MONTH;

  INSERT INTO DM.T_BRKBIS_STKPLG_CTR_DTL_M
  (
       YEAR_MTH                   --年月
      ,ORG_NO                     --机构编号
      ,BRH                        --营业部
      ,SEPT_CORP                  --分公司
      ,SEPT_CORP_TYPE             --分公司类型
      ,IF_YEAR_NA                 --是否年新增
      ,IF_MTH_NA                  --是否月新增
      ,ACC_CHAR                   --账户性质
      ,IF_SPCA_ACC                --是否特殊账户
      ,AST_SGMTS                  --资产段
      ,IF_STKPLG_CUST_YEAR_NA     --是否股票质押客户_年新增
      ,IF_STKPLG_CUST_MTH_NA      --是否股票质押客户_月新增
      ,CTR_NO                     --合同编号
      ,ORDR_DT                    --委托日期
      ,ACTL_BUYB_DT               --实际购回日期
      ,SECU_CD                    --证券代码
      ,IF_LS                      --是否限售
      ,STKPLG_TOTAST_FINAL        --股票质押总资产_期末
      ,STKPLG_NET_AST_FINAL       --股票质押净资产_期末
      ,STKPLG_BAL_FINAL           --股票质押余额_期末
      ,STKPLG_TOTAST_MDA          --股票质押总资产_月日均
      ,STKPLG_NET_AST_MDA         --股票质押净资产_月日均
      ,STKPLG_BAL_MDA             --股票质押余额_月日均
      ,STKPLG_TOTAST_YDA          --股票质押总资产_年日均
      ,STKPLG_NET_AST_YDA         --股票质押净资产_年日均
      ,STKPLG_BAL_YDA             --股票质押余额_年日均
      ,FINOS_NO                   --融出方编号
      ,FINOS_NAME                 --融出方名称
      ,FINOS_TYPE                 --融出方类型
  )
  SELECT 
       T1.YEAR||T1.MTH                                      AS        YEAR_MTH                   --年月          
      , CASE WHEN t_jg.WH_ORG_ID IS NULL THEN t1.WH_ORG_ID_EMP ELSE t_jg.WH_ORG_ID END   as ORG_NO                     --机构编号
      , CASE WHEN t_jg.WH_ORG_ID IS NULL THEN '总部'           ELSE T_jg.HR_ORG_NAME END as BRH                        --营业部
      , CASE 
           WHEN t_jg.WH_ORG_ID IS NULL THEN  '总部' 
           WHEN t_jg.TOP_SEPT_CORP_NAME  IS NULL  OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')   THEN  T_JG.HR_ORG_NAME   
           ELSE t_jg.TOP_SEPT_CORP_NAME END                      as SEPT_CORP                  --分公司
       , CASE WHEN t_jg.WH_ORG_ID IS NULL OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')  THEN '总部' 
          ELSE T_JG.ORG_TYPE END                                 as        SEPT_CORP_TYPE             --分公司类型
      ,T_KHSX.是否年新增                                         AS        IF_YEAR_NA                 --是否年新增             
      ,T_KHSX.是否月新增                                         AS        IF_MTH_NA                  --是否月新增           
      ,T_KHSX.客户类型                                           AS        ACC_CHAR                   --账户性质          
      ,T_KHSX.是否特殊账户                                       AS        IF_SPCA_ACC                --是否特殊账户              
      ,T_KHSX.资产段                                             AS        AST_SGMTS                  --资产段       
      ,T_KHSX.是否股票质押客户_月新增                            AS        IF_STKPLG_CUST_YEAR_NA     --是否股票质押客户_年新增                         
      ,T_KHSX.是否股票质押客户_年新增                            AS        IF_STKPLG_CUST_MTH_NA      --是否股票质押客户_月新增                         
      ,T1.CTR_NO                                                 AS        CTR_NO                     --合同编号    
      ,CONVERT(VARCHAR,T_STKPLG_AGMT.ORDR_DT)                    AS        ORDR_DT                    --委托日期                
      ,CONVERT(VARCHAR,T_STKPLG_AGMT.ACTL_BUYB_DT)               AS        ACTL_BUYB_DT               --实际购回日期                    
      ,T_STKPLG_AGMT.SECU_CD                                     AS        SECU_CD                    --证券代码                
      ,1                                                         AS        IF_LS                      --是否限售       
      ,SUM(T1.GUAR_SECU_MVAL_FINAL)                              AS        STKPLG_TOTAST_FINAL        --股票质押总资产_期末                  
      ,SUM(T1.GUAR_SECU_MVAL_FINAL - T1.STKPLG_FIN_BAL_FINAL)    AS        STKPLG_NET_AST_FINAL       --股票质押净资产_期末                                            
      ,SUM(T1.STKPLG_FIN_BAL_FINAL)                              AS        STKPLG_BAL_FINAL           --股票质押余额_期末                  
      ,SUM(T1.GUAR_SECU_MVAL_MDA)                                AS        STKPLG_TOTAST_MDA          --股票质押总资产_月日均                
      ,SUM(T1.GUAR_SECU_MVAL_MDA - T1.STKPLG_FIN_BAL_MDA)        AS        STKPLG_NET_AST_MDA         --股票质押净资产_月日均                                        
      ,SUM(T1.STKPLG_FIN_BAL_MDA)                                AS        STKPLG_BAL_MDA             --股票质押余额_月日均                
      ,SUM(T1.GUAR_SECU_MVAL_YDA)                                AS        STKPLG_TOTAST_YDA          --股票质押总资产_年日均                
      ,SUM(T1.GUAR_SECU_MVAL_YDA - T1.STKPLG_FIN_BAL_YDA)        AS        STKPLG_NET_AST_YDA         --股票质押净资产_年日均                                        
      ,SUM(T1.STKPLG_FIN_BAL_YDA)                                AS        STKPLG_BAL_YDA             --股票质押余额_年日均                
      ,T_STKPLG_AGMT.FINAC_OUT_SIDE_NO                           AS        FINOS_NO                   --融出方编号                          
      ,T_STKPLG_AGMT.FINAC_OUT_SIDE_NAME                         AS        FINOS_NAME                 --融出方名称                            
      ,T_STKPLG_AGMT.FINAC_OUT_SIDE_TYPE                         AS        FINOS_TYPE                 --融出方类型                            
  FROM DM.T_AST_EMPCUS_STKPLG_M_D T1
  LEFT JOIN DM.T_PUB_ORG T_JG         --机构表
        ON T1.YEAR=T_JG.YEAR AND T1.MTH=T_JG.MTH 
          AND T1.WH_ORG_ID_EMP=T_JG.WH_ORG_ID
  LEFT JOIN DM.T_AGT_STKPLG_AGMT T_STKPLG_AGMT
        ON T_STKPLG_AGMT.OCCUR_DT = T1.OCCUR_DT
          AND T_STKPLG_AGMT.CTR_NO = T1.CTR_NO
          AND T_STKPLG_AGMT.CUST_ID = T1.CUST_ID
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
      ,CASE WHEN T3.IF_STKPLG_CUST=1 AND T3.STKPLG_OPEN_DT>=T2.NATRE_DAY_MTHBEG THEN 1 ELSE 0 END AS 是否股票质押客户_月新增
      ,CASE WHEN T3.IF_STKPLG_CUST=1 AND T3.STKPLG_OPEN_DT>=T2.NATRE_DAY_YEARBGN THEN 1 ELSE 0 END AS 是否股票质押客户_年新增   
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
      LEFT JOIN DM.T_PUB_DATE_M T2 ON T1.YEAR=T2.YEAR AND T1.MTH=T2.MTH
      LEFT JOIN DM.T_PUB_CUST_LIMIT_M_D T3 ON T1.YEAR=T3.YEAR AND T1.MTH=T3.MTH AND T1.CUST_ID=T3.CUST_ID
      LEFT JOIN DM.T_ACC_CPTL_ACC T4 ON T1.YEAR=T4.YEAR AND T1.MTH=T4.MTH AND T1.MAIN_CPTL_ACCT=T4.CPTL_ACCT
      LEFT JOIN DM.T_AST_ODI_M_D T5 ON T1.YEAR=T5.YEAR AND T1.MTH=T5.MTH AND T1.CUST_ID=T5.CUST_ID
        WHERE T1.YEAR=@V_YEAR 
           AND T1.MTH=@V_MONTH
          -- AND 资产段 IS NOT NULL
  ) T_KHSX ON T1.YEAR=T_KHSX.YEAR AND T1.MTH=T_KHSX.MTH AND T1.CUST_ID=T_KHSX.CUST_ID
  WHERE T1.YEAR = @V_YEAR AND T1.MTH = @V_MONTH
  GROUP BY 
   YEAR_MTH              
   ,ORG_NO                
   ,BRH                   
   ,SEPT_CORP             
   ,SEPT_CORP_TYPE        
   ,IF_YEAR_NA            
   ,IF_MTH_NA             
   ,ACC_CHAR              
   ,IF_SPCA_ACC           
   ,AST_SGMTS             
   ,IF_STKPLG_CUST_YEAR_NA
   ,IF_STKPLG_CUST_MTH_NA 
   ,CTR_NO                
   ,ORDR_DT               
   ,ACTL_BUYB_DT          
   ,SECU_CD               
   ,IF_LS
   ,FINOS_NO  
   ,FINOS_NAME
   ,FINOS_TYPE;
END