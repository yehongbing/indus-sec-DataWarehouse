CREATE OR REPLACE PROCEDURE dm.P_EVT_EMP_PROD_SUBSCR_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 员工产品签约日表
  编写者: YHB
  创建日期: 2018-06-08
  简介：员工产品签约日表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
  --DECLARE @V_BIN_DATE INT ;
  DECLARE @V_BIN_YEAR VARCHAR(4);    
  DECLARE @V_BIN_MTH  VARCHAR(2);   
  DECLARE @V_NATRE_DAY_MTHBEG INT;
  DECLARE @V_NATRE_DAY_YEARBEG INT;
	
	----衍生变量
  SET @V_BIN_DATE=@V_BIN_DATE;
  SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
  SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
  SET @V_NATRE_DAY_MTHBEG = (SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH = @V_BIN_MTH);
  SET @V_NATRE_DAY_YEARBEG = (SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR);


  --PART0 删除当日数据
  DELETE FROM DM.T_EVT_EMP_PROD_SUBSCR_D WHERE OCCUR_DT = @V_BIN_DATE;
  DELETE FROM DM.T_EVT_CUST_PROD_SUBSCR_D WHERE OCCUR_DT = @V_BIN_DATE;

  -- 对于每个资金账号，取其金9最早购买日期
  SELECT ZJZH,MIN(RQ) AS INI_PURC_DT
  INTO #TEMP_INI_PURC_ZJZH
  FROM DBA.T_DDW_XY_JJZB_D
  WHERE CWJE_SGQR_D > 0 AND JJDM = 'AB0009'
  GROUP BY ZJZH;

  -- 计算期末保有客户数
  SELECT RQ,ZJZH,JJDM,COUNT(ZJZH) AS CUST_CNT
  INTO #TEMP_RETAIN_CUST_NUM_FINAL
  FROM DBA.T_DDW_XY_JJZB_D
  WHERE JJDM = 'AB0009' 
    AND RQ = @V_BIN_DATE
  GROUP BY RQ,ZJZH,JJDM;

  --开户日期7日后
  SELECT T1.RQ 
        ,T1.LJGZR
  FROM DBA.T_DDW_D_RQ T1
  WHERE 

  --客户信息临时表
  SELECT 
       T1.YEAR
      ,T1.MTH 
      ,T1.CUST_ID
      ,T1.MAIN_CPTL_ACCT
      ,T1.CUST_STAT_NAME AS 客户状态
      ,COALESCE(T1.IF_VLD,0) AS 是否有效
      ,T1.TE_OACT_DT AS 开户日期
      ,T4.LJGZR + 7   AS 七个工作日后的累计工作日
      ,COALESCE(T2.INI_PURC_DT,29991231) AS 金九最早购买日期 --若空值则赋一个脏数值
      ,COALESCE(T3.CUST_CNT,0) AS 金九保有客户数
  INTO #TEMP_CUST_INFO      
  FROM DM.T_PUB_CUST T1
  LEFT JOIN #TEMP_INI_PURC_ZJZH T2 
        ON T1.MAIN_CPTL_ACCT = T2.ZJZH   
  LEFT JOIN #TEMP_RETAIN_CUST_NUM_FINAL T3
        ON T1.MAIN_CPTL_ACCT = T3.ZJZH
  LEFT JOIN DBA.T_DDW_D_RQ T4
        ON T1.TE_OACT_DT = T4.RQ
  WHERE T1.YEAR=@V_BIN_YEAR 
    AND T1.MTH=@V_BIN_MTH;

  ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
  SELECT @V_BIN_YEAR  AS YEAR,
       @V_BIN_MTH   AS MTH,
       RQ           AS OCCUR_DT,
       JGBH_HS      AS HS_ORG_ID,
       KHBH_HS      AS HS_CUST_ID,
       ZJZH         AS CPTL_ACCT,
       YGH          AS FST_EMPID_BROK_ID,
       AFATWO_YGH   AS AFA_SEC_EMPID,
       JGBH_KH      AS WH_ORG_ID_CUST,
       JGBH_YG      AS WH_ORG_ID_EMP,
       RYLX         AS PRSN_TYPE,
       MAX(BZ)      AS MEMO,
       MAX(YGXM)    AS EMP_NAME,
       SUM(JXBL1)   AS PERFM_RATI1,
       SUM(JXBL2)   AS PERFM_RATI2,
       SUM(JXBL3)   AS PERFM_RATI3,
       SUM(JXBL4)   AS PERFM_RATI4,
       SUM(JXBL5)   AS PERFM_RATI5,
       SUM(JXBL6)   AS PERFM_RATI6,
       SUM(JXBL7)   AS PERFM_RATI7,
       SUM(JXBL8)   AS PERFM_RATI8,
       SUM(JXBL9)   AS PERFM_RATI9,
       SUM(JXBL10) AS PERFM_RATI10,
       SUM(JXBL11) AS PERFM_RATI11,
       SUM(JXBL12) AS PERFM_RATI12 
     INTO #T_PUB_SER_RELA
    FROM (SELECT *
        FROM DBA.T_DDW_SERV_RELATION_D
       WHERE JXBL1 + JXBL2 + JXBL3 + JXBL4 + JXBL5 + JXBL6 + JXBL7 + JXBL8 +
           JXBL9 + JXBL10 + JXBL11 + JXBL12 > 0
           AND RQ=@V_BIN_DATE) A
   GROUP BY YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;


  --插入客户产品签约信息
  INSERT INTO DM.T_EVT_CUST_PROD_SUBSCR_D(
     OCCUR_DT     --业务日期
    ,CUST_NO      --客户编号
    ,PROD_CD      --产品代码
    ,CPTL_ACCT    --资金账号
    ,SUBSCR_DT    --签约日期
  )
  SELECT @V_BIN_DATE        AS OCCUR_DT  --业务日期
         ,A.CLIENT_ID       AS CUST_NO   --客户编号
         ,A.PROD_CODE       AS PROD_CD   --产品代码
         ,A.FUND_ACCOUNT    AS CPTL_ACCT --资金账号
         ,A.QYRQ            AS SUBSCR_DT --签约日期
  FROM 
  (
    SELECT PROD_CODE, CLIENT_ID, FUND_ACCOUNT, MIN(INIT_DATE) AS QYRQ
    FROM DBA.T_EDW_UF2_HIS_PRODCASHACCTJOUR
    WHERE BUSINESS_FLAG = 44062 AND INIT_DATE <= @V_BIN_DATE
    GROUP BY PROD_CODE, CLIENT_ID, FUND_ACCOUNT
  ) A
  LEFT JOIN DBA.T_EDW_UF2_PRODCASHACCT B 
        ON B.LOAD_DT = @V_BIN_DATE 
          AND A.PROD_CODE = B.PROD_CODE 
          AND A.CLIENT_ID = B.CLIENT_ID
  WHERE B.CLIENT_ID IS NOT NULL;
  COMMIT;

  --客户数类型的指标临时表
  SELECT 
       T2.OCCUR_DT                                                                        AS    OCCUR_DT                     --业务日期
      ,T3.WH_ORG_ID_EMP                                                                   AS    WH_ORG_ID_EMP                --仓库机构编码_员工
      ,T3.AFA_SEC_EMPID                                                                   AS    EMP_ID                       --员工编码
      ,T2.PROD_CD                                                                         AS    PROD_CD                      --产品代码
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.是否有效 = 1 
                THEN T3.PERFM_RATI6  
            ELSE 0 
          END)                                                                            AS   RETAIN_EFF_HOUS_FINAL        --保有有效户数_期末
      ,SUM(T_KHSX.金九保有客户数 * T3.PERFM_RATI6)                                         AS   RETAIN_CUST_NUM_FINAL        --保有客户数_期末
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T2.SUBSCR_DT = @V_BIN_DATE 
                THEN T3.PERFM_RATI6 
           ELSE 0 
          END)                                                                            AS   NA_SUBSCR_CUST_NUM_D         --新增签约客户数_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.金九最早购买日期 = @V_BIN_DATE 
                THEN T3.PERFM_RATI6 
            ELSE 0 
          END)                                                                            AS   NA_EFF_CUST_NUM_D            --新增有效客户数_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.开户日期 = @V_BIN_DATE 
                  AND T2.SUBSCR_DT = @V_BIN_DATE 
                THEN T3.PERFM_RATI6 
            ELSE 0 
          END)                                                                            AS   OACOPN_CUST_NUM_D            --开户就开通客户数_本日

      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),5,2)=@V_BIN_MTH
                THEN T3.PERFM_RATI6 
               ELSE 0 
          END)                                                                            AS   NA_SUBSCR_CUST_NUM_M         --新增签约客户数_本月
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.金九最早购买日期 BETWEEN @V_NATRE_DAY_MTHBEG AND @V_BIN_DATE
                THEN T3.PERFM_RATI6 
            ELSE 0 
          END)                                                                            AS    NA_EFF_CUST_NUM_M            --新增有效客户数_本月
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),5,2)=@V_BIN_MTH
                  AND T2.SUBSCR_DT BETWEEN T_KHSX.开户日期 AND T4.RQ
                THEN T3.PERFM_RATI6 
            ELSE 0 
          END)                                                                            AS    OACOPN_CUST_NUM_M            --开户就开通客户数_本月
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                THEN T3.PERFM_RATI6 
           ELSE 0 
          END)                                                                            AS   NA_SUBSCR_CUST_NUM_TY         --新增签约客户数_本年
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.金九最早购买日期 BETWEEN @V_NATRE_DAY_YEARBEG AND @V_BIN_DATE
                THEN T3.PERFM_RATI6 
            ELSE 0 
          END)                                                                            AS   NA_EFF_CUST_NUM_TY            --新增有效客户数_本年
  INTO #TEMP_CUST_CNT
  FROM DM.T_EVT_CUST_PROD_SUBSCR_D T2
  LEFT JOIN #TEMP_CUST_INFO T_KHSX 
        ON SUBSTR(CONVERT(VARCHAR,T2.OCCUR_DT),1,4) = T_KHSX.YEAR 
          AND SUBSTR(CONVERT(VARCHAR,T2.OCCUR_DT),5,2) = T_KHSX.MTH 
          AND T2.CUST_NO = T_KHSX.CUST_ID
  LEFT JOIN #T_PUB_SER_RELA T3
        ON T3.OCCUR_DT = T2.OCCUR_DT
          AND T3.HS_CUST_ID = T2.CUST_NO
  LEFT JOIN DBA.T_DDW_D_RQ T4
        ON T_KHSX.七个工作日后的累计工作日 = T4.LJGZR
  WHERE T2.OCCUR_DT = @V_BIN_DATE    
    AND T3.WH_ORG_ID_EMP IS NOT NULL
    AND T3.AFA_SEC_EMPID IS NOT NULL
  GROUP BY 
       T2.OCCUR_DT     
      ,T3.WH_ORG_ID_EMP
      ,T3.AFA_SEC_EMPID
      ,T2.PROD_CD;

  --金额类型指标临时表
  SELECT 
       T1.OCCUR_DT                                                                        AS    OCCUR_DT                     --业务日期
      ,T2.WH_ORG_ID_EMP                                                                   AS    WH_ORG_ID_EMP                --仓库机构编码_员工
      ,T2.AFA_SEC_EMPID                                                                   AS    EMP_ID                       --员工编码
      ,T1.PROD_CD                                                                         AS    PROD_CD                      --产品代码
      ,SUM(COALESCE(T2.ITC_RETAIN_AMT_FINAL,0) + COALESCE(T2.OTC_RETAIN_AMT_FINAL,0))     AS    RETAIN_AMT_FINAL             --保有金额_期末
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T1.SUBSCR_DT = @V_BIN_DATE 
                THEN (COALESCE(T2.ITC_RETAIN_AMT_FINAL,0) + COALESCE(T2.OTC_RETAIN_AMT_FINAL,0)) 
            ELSE 0 
          END)                                                                            AS   NA_CUST_RETAIN_AMT_D         --新增客户保有金额_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.开户日期 = @V_BIN_DATE 
                  AND T1.SUBSCR_DT = @V_BIN_DATE 
                THEN (COALESCE(T2.ITC_RETAIN_AMT_FINAL,0) + COALESCE(T2.OTC_RETAIN_AMT_FINAL,0)) 
            ELSE 0 
          END)                                                                            AS   OACOPN_CUST_RETAIN_AMT_D     --开户就开通客户保有金额_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T1.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T1.SUBSCR_DT),5,2)=@V_BIN_MTH
                THEN (COALESCE(T2.ITC_RETAIN_AMT_FINAL,0) + COALESCE(T2.OTC_RETAIN_AMT_FINAL,0)) 
            ELSE 0 
          END)                                                                            AS    NA_CUST_RETAIN_AMT_M         --新增客户保有金额_本月
      ,SUM(T2.ITC_RETAIN_AMT_MDA + T2.OTC_RETAIN_AMT_MDA)                                 AS    RETAIN_AMT_MDA               --保有金额_月日均
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T1.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T1.SUBSCR_DT),5,2)=@V_BIN_MTH
                  AND T1.SUBSCR_DT BETWEEN T_KHSX.开户日期 AND T4.RQ
                THEN (COALESCE(T2.ITC_RETAIN_AMT_FINAL,0) + COALESCE(T2.OTC_RETAIN_AMT_FINAL,0)) 
            ELSE 0 
          END)                                                                            AS    OACOPN_CUST_RETAIN_AMT_M     --开户就开通客户保有金额_本月
      ,SUM(T2.ITC_RETAIN_AMT_YDA + T2.OTC_RETAIN_AMT_YDA)                                 AS    RETAIN_AMT_YDA               --保有金额_年日均
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T1.SUBSCR_DT),1,4)=@V_BIN_YEAR
                THEN (COALESCE(T2.ITC_RETAIN_AMT_FINAL,0) + COALESCE(T2.OTC_RETAIN_AMT_FINAL,0)) 
            ELSE 0 
          END)                                                                            AS   NA_CUST_RETAIN_AMT_TY         --新增客户保有金额_本年
  INTO #TEMP_CUST_AMT
  FROM DM.T_EVT_CUST_PROD_SUBSCR_D T1
  LEFT JOIN DM.T_EVT_EMPCUS_PROD_TRD_M_D T2
        ON T1.OCCUR_DT = T2.OCCUR_DT
          AND T1.CUST_NO = T2.CUST_ID
          AND T1.PROD_CD = T2.PROD_CD
  LEFT JOIN #TEMP_CUST_INFO T_KHSX 
        ON SUBSTR(CONVERT(VARCHAR,T2.OCCUR_DT),1,4) = T_KHSX.YEAR 
          AND SUBSTR(CONVERT(VARCHAR,T2.OCCUR_DT),5,2) = T_KHSX.MTH 
          AND T1.CUST_NO = T_KHSX.CUST_ID  
  LEFT JOIN DBA.T_DDW_D_RQ T4
        ON T_KHSX.七个工作日后的累计工作日 = T4.LJGZR
  WHERE T1.OCCUR_DT = @V_BIN_DATE   
  GROUP BY 
       T1.OCCUR_DT     
      ,T2.WH_ORG_ID_EMP
      ,T2.AFA_SEC_EMPID
      ,T1.PROD_CD;      



  --插入员工产品签约日表
  INSERT INTO DM.T_EVT_EMP_PROD_SUBSCR_D(
       OCCUR_DT                     --业务日期
      ,WH_ORG_ID_EMP                --仓库机构编码_员工
      ,EMP_ID                       --员工编码
      ,PROD_CD                      --产品代码
      ,RETAIN_AMT_FINAL             --保有金额_期末
      ,RETAIN_EFF_HOUS_FINAL        --保有有效户数_期末
      ,RETAIN_CUST_NUM_FINAL		    --保有客户数_期末
      ,NA_SUBSCR_CUST_NUM_D         --新增签约客户数_本日
      ,NA_EFF_CUST_NUM_D            --新增有效客户数_本日
      ,NA_CUST_RETAIN_AMT_D         --新增客户保有金额_本日
      ,OACOPN_CUST_NUM_D            --开户就开通客户数_本日
      ,OACOPN_CUST_RETAIN_AMT_D     --开户就开通客户保有金额_本日
      ,NA_SUBSCR_CUST_NUM_M         --新增签约客户数_本月
      ,NA_EFF_CUST_NUM_M            --新增有效客户数_本月
      ,NA_CUST_RETAIN_AMT_M         --新增客户保有金额_本月
      ,RETAIN_AMT_MDA               --保有金额_月日均
      ,OACOPN_CUST_NUM_M            --开户就开通客户数_本月
      ,OACOPN_CUST_RETAIN_AMT_M     --开户就开通客户保有金额_本月
      ,RETAIN_AMT_YDA               --保有金额_年日均
      ,NA_SUBSCR_CUST_NUM_TY        --新增签约客户数_本年
      ,NA_EFF_CUST_NUM_TY           --新增有效客户数_本年
      ,NA_CUST_RETAIN_AMT_TY        --新增客户保有金额_本年
  )
  SELECT 
       T1.OCCUR_DT                        AS    OCCUR_DT                     --业务日期
      ,T1.WH_ORG_ID_EMP                   AS    WH_ORG_ID_EMP                --仓库机构编码_员工
      ,T1.EMP_ID                          AS    EMP_ID                       --员工编码
      ,T1.PROD_CD                         AS    PROD_CD                      --产品代码
      ,T2.RETAIN_AMT_FINAL                AS    RETAIN_AMT_FINAL             --保有金额_期末
      ,T1.RETAIN_EFF_HOUS_FINAL           AS    RETAIN_EFF_HOUS_FINAL        --保有有效户数_期末
      ,T1.RETAIN_CUST_NUM_FINAL 		      AS    RETAIN_CUST_NUM_FINAL        --保有客户数_期末
      ,T1.NA_SUBSCR_CUST_NUM_D            AS    NA_SUBSCR_CUST_NUM_D         --新增签约客户数_本日
      ,T1.NA_EFF_CUST_NUM_D               AS    NA_EFF_CUST_NUM_D            --新增有效客户数_本日
      ,T2.NA_CUST_RETAIN_AMT_D            AS    NA_CUST_RETAIN_AMT_D         --新增客户保有金额_本日
      ,T1.OACOPN_CUST_NUM_D               AS    OACOPN_CUST_NUM_D            --开户就开通客户数_本日
      ,T2.OACOPN_CUST_RETAIN_AMT_D        AS    OACOPN_CUST_RETAIN_AMT_D     --开户就开通客户保有金额_本日
      ,T1.NA_SUBSCR_CUST_NUM_M            AS    NA_SUBSCR_CUST_NUM_M         --新增签约客户数_本月
      ,T1.NA_EFF_CUST_NUM_M               AS    NA_EFF_CUST_NUM_M            --新增有效客户数_本月
      ,T2.NA_CUST_RETAIN_AMT_M            AS    NA_CUST_RETAIN_AMT_M         --新增客户保有金额_本月
      ,T2.RETAIN_AMT_MDA                  AS    RETAIN_AMT_MDA               --保有金额_月日均
      ,T1.OACOPN_CUST_NUM_M               AS    OACOPN_CUST_NUM_M            --开户就开通客户数_本月
      ,T2.OACOPN_CUST_RETAIN_AMT_M        AS    OACOPN_CUST_RETAIN_AMT_M     --开户就开通客户保有金额_本月
      ,T2.RETAIN_AMT_YDA                  AS    RETAIN_AMT_YDA               --保有金额_年日均
      ,T1.NA_SUBSCR_CUST_NUM_TY           AS    NA_SUBSCR_CUST_NUM_TY        --新增签约客户数_本年
      ,T1.NA_EFF_CUST_NUM_TY              AS    NA_EFF_CUST_NUM_TY           --新增有效客户数_本年
      ,T2.NA_CUST_RETAIN_AMT_TY           AS    NA_CUST_RETAIN_AMT_TY        --新增客户保有金额_本年
  FROM #TEMP_CUST_CNT T1
  LEFT JOIN #TEMP_CUST_AMT T2 
        ON T1.OCCUR_DT = T2.OCCUR_DT
          AND T1.WH_ORG_ID_EMP = T2.WH_ORG_ID_EMP
          AND T1.EMP_ID = T2.EMP_ID
          AND T1.PROD_CD = T2.PROD_CD;
COMMIT;


  --插入DBA.T_DDW_XY_JJZB_D表中相比DM.T_EVT_CUST_PROD_SUBSCR_D多余的资金账号的数据
  SELECT 
     T1.RQ             AS OCCUR_DT     --业务日期
    ,T2.CUST_ID        AS CUST_NO      --客户编号      
    ,T1.JJDM           AS PROD_CD      --产品代码  
    ,T1.ZJZH           AS CPTL_ACCT    --资金账号  
    ,T1.CUST_CNT       AS CUST_CNT    --保有客户数  
  INTO #TEMP_CUST_CNT_EXT     
  FROM #TEMP_RETAIN_CUST_NUM_FINAL T1 
  LEFT JOIN DM.T_PUB_CUST T2
        ON T2.MAIN_CPTL_ACCT = T1.ZJZH
          AND SUBSTR(CONVERT(VARCHAR,T1.RQ),1,4) = T2.YEAR 
          AND SUBSTR(CONVERT(VARCHAR,T1.RQ),5,2) = T2.MTH 
  LEFT JOIN #TEMP_INI_PURC_ZJZH T3
        ON T1.ZJZH = T3.ZJZH
  WHERE T2.CUST_ID NOT IN (SELECT DISTINCT CUST_NO FROM DM.T_EVT_CUST_PROD_SUBSCR_D WHERE OCCUR_DT = @V_BIN_DATE);

  --准备临时表插入目标表
  SELECT 
       T2.OCCUR_DT                                                                        AS    OCCUR_DT                     --业务日期
      ,T3.WH_ORG_ID_EMP                                                                   AS    WH_ORG_ID_EMP                --仓库机构编码_员工
      ,T3.AFA_SEC_EMPID                                                                   AS    EMP_ID                       --员工编码
      ,T2.PROD_CD                                                                         AS    PROD_CD                      --产品代码
      ,SUM(T2.CUST_CNT * T3.PERFM_RATI6)                                                  AS    RETAIN_CUST_NUM_FINAL        --保有客户数_期末
  INTO #TEMP_EXT_CUST_CNT
  FROM #TEMP_CUST_CNT_EXT T2
  LEFT JOIN #TEMP_CUST_INFO T_KHSX 
        ON SUBSTR(CONVERT(VARCHAR,T2.OCCUR_DT),1,4) = T_KHSX.YEAR 
          AND SUBSTR(CONVERT(VARCHAR,T2.OCCUR_DT),5,2) = T_KHSX.MTH 
          AND T2.CUST_NO = T_KHSX.CUST_ID
  LEFT JOIN #T_PUB_SER_RELA T3
        ON T3.OCCUR_DT = T2.OCCUR_DT
          AND T3.HS_CUST_ID = T2.CUST_NO
  WHERE T2.OCCUR_DT = @V_BIN_DATE    
    AND T3.WH_ORG_ID_EMP IS NOT NULL
    AND T3.AFA_SEC_EMPID IS NOT NULL
  GROUP BY 
       T2.OCCUR_DT     
      ,T3.WH_ORG_ID_EMP
      ,T3.AFA_SEC_EMPID
      ,T2.PROD_CD;

  --对于主键已经存在在目标表中的，用UPDATE把客户数合计起来
  UPDATE DM.T_EVT_EMP_PROD_SUBSCR_D T1 
  SET T1.RETAIN_CUST_NUM_FINAL = T1.RETAIN_CUST_NUM_FINAL + B.RETAIN_CUST_NUM_FINAL 
  FROM DM.T_EVT_EMP_PROD_SUBSCR_D T1,#TEMP_EXT_CUST_CNT B  
  WHERE T1.OCCUR_DT = B.OCCUR_DT
          AND T1.WH_ORG_ID_EMP = B.WH_ORG_ID_EMP
          AND T1.EMP_ID = B.EMP_ID
          AND T1.PROD_CD = B.PROD_CD;

  --插入员工产品签约日表
  INSERT INTO DM.T_EVT_EMP_PROD_SUBSCR_D(
       OCCUR_DT                     --业务日期
      ,WH_ORG_ID_EMP                --仓库机构编码_员工
      ,EMP_ID                       --员工编码
      ,PROD_CD                      --产品代码
      ,RETAIN_CUST_NUM_FINAL        --保有客户数_期末
  )
  SELECT 
      OCCUR_DT             
     ,WH_ORG_ID_EMP        
     ,EMP_ID               
     ,PROD_CD              
     ,RETAIN_CUST_NUM_FINAL
  FROM #TEMP_EXT_CUST_CNT T1 
  WHERE NOT EXISTS
  (SELECT 1 FROM DM.T_EVT_EMP_PROD_SUBSCR_D T2 
      WHERE T1.OCCUR_DT = T2.OCCUR_DT
         AND T1.WH_ORG_ID_EMP = T2.WH_ORG_ID_EMP 
         AND T1.EMP_ID = T2.EMP_ID 
         AND T1.PROD_CD = T2.PROD_CD)
;


COMMIT;

END

