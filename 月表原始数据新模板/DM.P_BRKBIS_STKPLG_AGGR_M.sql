CREATE OR REPLACE PROCEDURE dm.P_BRKBIS_STKPLG_AGGR_M(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 经纪业务股票质押月报
  编写者: YHB
  创建日期: 2018-05-25
  经纪业务股票质押月报
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180525                  yhb                新建存储过程     
  *********************************************************************/

  DECLARE @V_YEAR VARCHAR(4);		-- 年份
  DECLARE @V_MONTH VARCHAR(2);	-- 月份
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

  --PART0 删除当月数据
  DELETE FROM DM.T_BRKBIS_STKPLG_AGGR_M WHERE YEAR_MTH=@V_YEAR||@V_MONTH;

  -- 客户表临时表
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
          WHEN COALESCE(T5.TOT_AST_MDA,0) <  100                                              THEN '00-100以下'
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
  INTO #TEMP_CUST_INFO
  FROM DM.T_PUB_CUST T1   
      LEFT JOIN DM.T_PUB_DATE_M T2 ON T1.YEAR=T2.YEAR AND T1.MTH=T2.MTH
      LEFT JOIN DM.T_PUB_CUST_LIMIT_M_D T3 ON T1.YEAR=T3.YEAR AND T1.MTH=T3.MTH AND T1.CUST_ID=T3.CUST_ID
      LEFT JOIN DM.T_ACC_CPTL_ACC T4 ON T1.YEAR=T4.YEAR AND T1.MTH=T4.MTH AND T1.MAIN_CPTL_ACCT=T4.CPTL_ACCT
      LEFT JOIN DM.T_AST_ODI_M_D T5 ON T1.YEAR=T5.YEAR AND T1.MTH=T5.MTH AND T1.CUST_ID=T5.CUST_ID
        WHERE T1.YEAR=@V_YEAR 
           AND T1.MTH=@V_MONTH;
  
  -- 客户数临时表
 SELECT 
       T1.YEAR||T1.MTH            AS    YEAR_MTH
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN t1.WH_ORG_ID_EMP ELSE t_jg.WH_ORG_ID END   as ORG_NO 
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN '总部'           ELSE T_jg.HR_ORG_NAME END as BRH
      ,CASE 
           WHEN t_jg.WH_ORG_ID IS NULL THEN  '总部' 
           WHEN t_jg.TOP_SEPT_CORP_NAME  IS NULL  OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB', --机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')   THEN  T_JG.HR_ORG_NAME   ELSE t_jg.TOP_SEPT_CORP_NAME END as SEPT_CORP
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB', --机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')  THEN '总部' 
          ELSE T_JG.ORG_TYPE END       AS SEPT_CORP_TYPE
      ,T_KHSX.是否年新增               AS IF_YEAR_NA
      ,T_KHSX.是否月新增               AS IF_MTH_NA
      ,T_KHSX.客户类型                 AS ACC_CHAR
      ,T_KHSX.是否特殊账户             AS IF_SPCA_ACC
      ,T_KHSX.资产段                   AS AST_SGMTS
      ,T_KHSX.是否股票质押客户_月新增  AS IF_STKPLG_CUST_YEAR_NA
      ,T_KHSX.是否股票质押客户_年新增  AS IF_STKPLG_CUST_MTH_NA
      ,MAX(CASE WHEN T_KHSX.客户状态='正常' THEN T2.JXBL1 ELSE 0 END) AS CUST_NUM
  INTO #TEMP_CUST_NUM
  FROM DM.T_AST_EMPCUS_STKPLG_M_D T1 
  LEFT JOIN DBA.T_DDW_SERV_RELATION T2
        ON T1.YEAR=T2.NIAN 
          AND T1.MTH=T2.YUE 
          AND T2.KHBH_HS=T1.CUST_ID 
          AND T1.AFA_SEC_EMPID=T2.AFATWO_YGH        
  LEFT JOIN DM.T_PUB_ORG T_JG         --机构表
        ON T1.YEAR=T_JG.YEAR AND T1.MTH=T_JG.MTH 
          AND T1.WH_ORG_ID_EMP=T_JG.WH_ORG_ID
  LEFT JOIN #TEMP_CUST_INFO T_KHSX 
        ON T1.YEAR=T_KHSX.YEAR 
          AND T1.MTH=T_KHSX.MTH 
          AND T1.CUST_ID=T_KHSX.CUST_ID
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
      ,IF_STKPLG_CUST_MTH_NA ;


  INSERT INTO DM.T_BRKBIS_STKPLG_AGGR_M
  (
       YEAR_MTH                       --年月
      ,ORG_NO                         --机构编号
      ,BRH                            --营业部
      ,SEPT_CORP                      --分公司
      ,SEPT_CORP_TYPE                 --分公司类型
      ,IF_YEAR_NA                     --是否年新增
      ,IF_MTH_NA                      --是否月新增
      ,ACC_CHAR                       --账户性质
      ,IF_SPCA_ACC                    --是否特殊账户
      ,AST_SGMTS                      --资产段
      ,IF_STKPLG_CUST_YEAR_NA         --是否股票质押客户_年新增
      ,IF_STKPLG_CUST_MTH_NA          --是否股票质押客户_月新增
      --,CUST_NUM                       --客户数
      ,STKPLG_TOTAST_FINAL            --股票质押总资产_期末
      ,STKPLG_NET_AST_FINAL           --股票质押净资产_期末
      ,STKPLG_BAL_FINAL               --股票质押余额_期末
      ,PROP_FINOS_BAL_FINAL           --自营融出方余额_期末
      ,ASSM_FINOS_BAL_FINAL           --资管融出方余额_期末
      ,MINO_AMT_FINOS_BAL_FINAL       --小额融出方余额_期末
      ,STKPLG_TOTAST_MDA              --股票质押总资产_月日均
      ,STKPLG_NET_AST_MDA             --股票质押净资产_月日均
      ,STKPLG_BAL_MDA                 --股票质押余额_月日均
      ,PROP_FINOS_BAL_MDA             --自营融出方余额_月日均
      ,ASSM_FINOS_BAL_MDA             --资管融出方余额_月日均
      ,MINO_AMT_FINOS_BAL_MDA         --小额融出方余额_月日均
      ,STKPLG_TOTAST_YDA              --股票质押总资产_年日均
      ,STKPLG_NET_AST_YDA             --股票质押净资产_年日均
      ,STKPLG_BAL_YDA                 --股票质押余额_年日均
      ,PROP_FINOS_BAL_YDA             --自营融出方余额_年日均
      ,ASSM_FINOS_BAL_YDA             --资管融出方余额_年日均
      ,MINO_AMT_FINOS_BAL_YDA         --小额融出方余额_年日均
      ,STKPLG_NET_CMS_MTD             --股票质押净佣金_月累计
      ,STKPLG_RECE_INT_MTD            --股票质押应收利息_月累计
      ,STKPLG_PAIDINT_MTD             --股票质押实收利息_月累计
      ,STKPLG_CPTL_COST_MTD           --股票质押资金成本_月累计
      ,STKPLG_NET_CMS_YTD             --股票质押净佣金_年累计
      ,STKPLG_RECE_INT_YTD            --股票质押应收利息_年累计
      ,STKPLG_PAIDINT_YTD             --股票质押实收利息_年累计
      ,STKPLG_CPTL_COST_YTD           --股票质押资金成本_年累计
  )
  SELECT 
       T1.YEAR||T1.MTH
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN t1.WH_ORG_ID_EMP ELSE t_jg.WH_ORG_ID END   as 机构编号	
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL THEN '总部'           ELSE T_jg.HR_ORG_NAME END as 营业部
      ,CASE 
           WHEN t_jg.WH_ORG_ID IS NULL THEN  '总部' 
           WHEN t_jg.TOP_SEPT_CORP_NAME  IS NULL  OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB', --机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')   THEN  T_JG.HR_ORG_NAME   ELSE t_jg.TOP_SEPT_CORP_NAME END as 分公司
      ,CASE WHEN t_jg.WH_ORG_ID IS NULL OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB', --机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')  THEN '总部' 
          ELSE T_JG.ORG_TYPE END   as 分公司类型
      ,T_KHSX.是否年新增 
      ,T_KHSX.是否月新增
      ,T_KHSX.客户类型
      ,T_KHSX.是否特殊账户
      ,T_KHSX.资产段
      ,T_KHSX.是否股票质押客户_月新增
      ,T_KHSX.是否股票质押客户_年新增
      --,SUM(CASE WHEN T_KHSX.客户状态='正常' THEN T2.JXBL1 ELSE 0 END)
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_FINAL,0))                              AS   STKPLG_TOTAST_FINAL            --股票质押总资产_期末      
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_FINAL - T1.STKPLG_FIN_BAL_FINAL,0))    AS   STKPLG_NET_AST_FINAL           --股票质押净资产_期末                                
      ,SUM(COALESCE(T1.STKPLG_FIN_BAL_FINAL,0))                              AS   STKPLG_BAL_FINAL               --股票质押余额_期末      
      ,SUM(COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0))                     AS   PROP_FINOS_BAL_FINAL           --自营融出方余额_期末              
      ,SUM(COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0))                     AS   ASSM_FINOS_BAL_FINAL           --资管融出方余额_期末              
      ,SUM(COALESCE(T1.SM_LOAN_FINAC_OUT_BAL_FINAL,0))                       AS   MINO_AMT_FINOS_BAL_FINAL       --小额融出方余额_期末            
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_MDA,0))                                AS   STKPLG_TOTAST_MDA              --股票质押总资产_月日均    
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_MDA - T1.STKPLG_FIN_BAL_MDA,0))        AS   STKPLG_NET_AST_MDA             --股票质押净资产_月日均                            
      ,SUM(COALESCE(T1.STKPLG_FIN_BAL_MDA,0))                                AS   STKPLG_BAL_MDA                 --股票质押余额_月日均    
      ,SUM(COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL_MDA,0))                       AS   PROP_FINOS_BAL_MDA             --自营融出方余额_月日均            
      ,SUM(COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0))                       AS   ASSM_FINOS_BAL_MDA             --资管融出方余额_月日均            
      ,SUM(COALESCE(T1.SM_LOAN_FINAC_OUT_BAL_MDA,0))                         AS   MINO_AMT_FINOS_BAL_MDA         --小额融出方余额_月日均          
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_YDA,0))                                AS   STKPLG_TOTAST_YDA              --股票质押总资产_年日均    
      ,SUM(COALESCE(T1.GUAR_SECU_MVAL_YDA - T1.STKPLG_FIN_BAL_YDA,0))        AS   STKPLG_NET_AST_YDA             --股票质押净资产_年日均                            
      ,SUM(COALESCE(T1.STKPLG_FIN_BAL_YDA,0))                                AS   STKPLG_BAL_YDA                 --股票质押余额_年日均    
      ,SUM(COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL_YDA,0))                       AS   PROP_FINOS_BAL_YDA             --自营融出方余额_年日均            
      ,SUM(COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0))                       AS   ASSM_FINOS_BAL_YDA             --资管融出方余额_年日均            
      ,SUM(COALESCE(T1.SM_LOAN_FINAC_OUT_BAL_YDA,0))                         AS   MINO_AMT_FINOS_BAL_YDA         --小额融出方余额_年日均                                                          
      ,SUM(COALESCE(T_XYSR.STKPLG_NET_CMS_MTD,0))                            AS   STKPLG_NET_CMS_MTD             --股票质押净佣金_月累计                                            
      ,SUM(COALESCE(T_XYSR.STKPLG_RECE_INT_MTD,0))                           AS   STKPLG_RECE_INT_MTD            --股票质押应收利息_月累计                                              
      ,SUM(COALESCE(T_XYSR.STKPLG_PAIDINT_MTD,0))                            AS   STKPLG_PAIDINT_MTD             --股票质押实收利息_月累计                                              
      ,0                                                                     AS   STKPLG_CPTL_COST_MTD           --股票质押资金成本_月累计                                                                     
      ,SUM(COALESCE(T_XYSR.STKPLG_NET_CMS_YTD,0))                            AS   STKPLG_NET_CMS_YTD             --股票质押净佣金_年累计                                            
      ,SUM(COALESCE(T_XYSR.STKPLG_RECE_INT_YTD,0))                           AS   STKPLG_RECE_INT_YTD            --股票质押应收利息_年累计                                              
      ,SUM(COALESCE(T_XYSR.STKPLG_PAIDINT_YTD,0))                            AS   STKPLG_PAIDINT_YTD             --股票质押实收利息_年累计                                              
      ,0                                                                     AS   STKPLG_CPTL_COST_YTD           --股票质押资金成本_年累计    
  FROM DM.T_AST_EMPCUS_STKPLG_M_D T1 
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
  LEFT JOIN #TEMP_CUST_INFO T_KHSX 
        ON T1.YEAR=T_KHSX.YEAR 
          AND T1.MTH=T_KHSX.MTH 
          AND T1.CUST_ID=T_KHSX.CUST_ID
  WHERE T1.YEAR = @V_YEAR AND T1.MTH = @V_MONTH
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
      ,T_KHSX.是否股票质押客户_月新增
      ,T_KHSX.是否股票质押客户_年新增;

--更新客户数
UPDATE DM.T_BRKBIS_STKPLG_AGGR_M
SET T1.CUST_NUM = T2.CUST_NUM
FROM DM.T_BRKBIS_STKPLG_AGGR_M T1
LEFT JOIN #TEMP_CUST_NUM T2
      ON T1.YEAR_MTH                  = T2.YEAR_MTH              
        AND T1.ORG_NO                 = T2.ORG_NO                
        AND T1.BRH                    = T2.BRH                   
        AND T1.SEPT_CORP              = T2.SEPT_CORP             
        AND T1.SEPT_CORP_TYPE         = T2.SEPT_CORP_TYPE        
        AND T1.IF_YEAR_NA             = T2.IF_YEAR_NA            
        AND T1.IF_MTH_NA              = T2.IF_MTH_NA             
        AND T1.ACC_CHAR               = T2.ACC_CHAR              
        AND T1.IF_SPCA_ACC            = T2.IF_SPCA_ACC           
        AND T1.AST_SGMTS              = T2.AST_SGMTS             
        AND T1.IF_STKPLG_CUST_YEAR_NA = T2.IF_STKPLG_CUST_YEAR_NA
        AND T1.IF_STKPLG_CUST_MTH_NA  = T2.IF_STKPLG_CUST_MTH_NA;
COMMIT;

END
