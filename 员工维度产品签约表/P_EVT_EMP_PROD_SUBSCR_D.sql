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
	
	----衍生变量
  SET @V_BIN_DATE=@V_BIN_DATE;
  SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
  SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

  --PART0 删除当日数据
  DELETE FROM DM.T_EVT_EMP_PROD_SUBSCR_D WHERE OCCUR_DT = @V_BIN_DATE;
  DELETE FROM DM.T_EVT_CUST_PROD_SUBSCR_D WHERE OCCUR_DT = @V_BIN_DATE;

  --插入客户产品签约信息
  INSERT INTO DM.T_EVT_CUST_PROD_SUBSCR_D(
     OCCUR_DT     --业务日期
    ,CUST_NO      --客户编号
    ,PROD_CD      --资金账号
    ,CPTL_ACCT    --产品代码
    ,SUBSCR_DT    --签约日期
  )
  SELECT @V_BIN_DATE        AS OCCUR_DT  --业务日期
         ,A.CLIENT_ID       AS CUST_NO   --客户编号
         ,A.FUND_ACCOUNT    AS PROD_CD   --资金账号
         ,A.PROD_CODE       AS CPTL_ACCT --产品代码
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

  --插入员工产品签约日表
  INSERT INTO DM.T_EVT_EMP_PROD_SUBSCR_D(
       OCCUR_DT                     --业务日期
      ,WH_ORG_ID_EMP                --仓库机构编码_员工
      ,EMP_ID                       --员工编码
      ,PROD_CD                      --产品代码
      ,RETAIN_AMT_FINAL             --保有金额_期末
      ,RETAIN_EFF_HOUS_FINAL        --保有有效户数_期末
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
       T1.OCCUR_DT                                              AS    OCCUR_DT                     --业务日期
      ,T1.WH_ORG_ID_EMP                                         AS    WH_ORG_ID_EMP                --仓库机构编码_员工
      ,T1.AFA_SEC_EMPID                                         AS    EMP_ID                       --员工编码
      ,T1.PROD_CD                                               AS    PROD_CD                      --产品代码
      ,SUM(T1.ITC_RETAIN_AMT_FINAL + T1.OTC_RETAIN_AMT_FINAL)   AS    RETAIN_AMT_FINAL             --保有金额_期末
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.是否有效 = 1 
                THEN 1 
            ELSE 0 
          END)                                                  AS   RETAIN_EFF_HOUS_FINAL        --保有有效户数_期末
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T2.SUBSCR_DT = @V_BIN_DATE 
                THEN 1 
           ELSE 0 
          END)                                                  AS   NA_SUBSCR_CUST_NUM_D         --新增签约客户数_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T2.SUBSCR_DT = @V_BIN_DATE 
                  AND T_KHSX.是否有效 = 1 
                THEN 1 
            ELSE 0 
          END)                                                  AS   NA_EFF_CUST_NUM_D            --新增有效客户数_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T2.SUBSCR_DT = @V_BIN_DATE 
                THEN (T1.ITC_RETAIN_AMT_FINAL + T1.OTC_RETAIN_AMT_FINAL) 
            ELSE 0 
          END)                                                  AS   NA_CUST_RETAIN_AMT_D         --新增客户保有金额_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.开户日期 = @V_BIN_DATE 
                  AND T2.SUBSCR_DT = @V_BIN_DATE 
                THEN 1 
            ELSE 0 
          END)                                                  AS   OACOPN_CUST_NUM_D            --开户就开通客户数_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND T_KHSX.开户日期 = @V_BIN_DATE 
                  AND T2.SUBSCR_DT = @V_BIN_DATE 
                THEN (T1.ITC_RETAIN_AMT_FINAL + T1.OTC_RETAIN_AMT_FINAL) 
            ELSE 0 
          END)                                                  AS   OACOPN_CUST_RETAIN_AMT_D     --开户就开通客户保有金额_本日
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),5,2)=@V_BIN_MTH
                THEN 1 
               ELSE 0 
          END)                                                  AS   NA_SUBSCR_CUST_NUM_M         --新增签约客户数_本月
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),5,2)=@V_BIN_MTH
                  AND T_KHSX.是否有效 = 1 
                THEN 1 
            ELSE 0 
          END)                                                  AS    NA_EFF_CUST_NUM_M            --新增有效客户数_本月
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),5,2)=@V_BIN_MTH
                THEN (T1.ITC_RETAIN_AMT_FINAL + T1.OTC_RETAIN_AMT_FINAL) 
            ELSE 0 
          END)                                                  AS    NA_CUST_RETAIN_AMT_M         --新增客户保有金额_本月
      ,SUM(T1.ITC_RETAIN_AMT_MDA + T1.OTC_RETAIN_AMT_MDA)       AS    RETAIN_AMT_MDA               --保有金额_月日均
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),5,2)=@V_BIN_MTH
                  AND T_KHSX.开户日期 = T2.SUBSCR_DT
                THEN 1 
            ELSE 0 
          END)                                                  AS    OACOPN_CUST_NUM_M            --开户就开通客户数_本月
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),5,2)=@V_BIN_MTH
                  AND T_KHSX.开户日期 = T2.SUBSCR_DT 
                THEN (T1.ITC_RETAIN_AMT_FINAL + T1.OTC_RETAIN_AMT_FINAL) 
            ELSE 0 
          END)                                                  AS    OACOPN_CUST_RETAIN_AMT_M     --开户就开通客户保有金额_本月
      ,SUM(T1.ITC_RETAIN_AMT_YDA + T1.OTC_RETAIN_AMT_YDA)       AS    RETAIN_AMT_YDA               --保有金额_年日均
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                THEN 1 
           ELSE 0 
          END)                                                  AS   NA_SUBSCR_CUST_NUM_TY         --新增签约客户数_本年
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                  AND T_KHSX.是否有效 = 1 
                THEN 1 
            ELSE 0 
          END)                                                  AS   NA_EFF_CUST_NUM_TY            --新增有效客户数_本年
      ,SUM(CASE WHEN T_KHSX.客户状态='正常' 
                  AND SUBSTR(CONVERT(VARCHAR,T2.SUBSCR_DT),1,4)=@V_BIN_YEAR
                THEN (T1.ITC_RETAIN_AMT_FINAL + T1.OTC_RETAIN_AMT_FINAL) 
            ELSE 0 
          END)                                                  AS   NA_CUST_RETAIN_AMT_TY         --新增客户保有金额_本年
  FROM DM.T_EVT_EMPCUS_PROD_TRD_M_D T1
  LEFT JOIN 
  (
      SELECT 
       T1.YEAR
      ,T1.MTH 
      ,T1.CUST_ID
      ,T1.CUST_STAT_NAME AS 客户状态
      ,COALESCE(T1.IF_VLD,0) AS 是否有效
      ,T1.TE_OACT_DT 开户日期        
      FROM DM.T_PUB_CUST T1   
      WHERE T1.YEAR=@V_BIN_YEAR 
           AND T1.MTH=@V_BIN_MTH
  ) T_KHSX ON T1.YEAR=T_KHSX.YEAR AND T1.MTH=T_KHSX.MTH AND T1.CUST_ID=T_KHSX.CUST_ID
  LEFT JOIN DM.T_EVT_CUST_PROD_SUBSCR_D T2
        ON T1.OCCUR_DT = T2.OCCUR_DT
          AND T1.CUST_ID = T2.CUST_NO
          AND T1.PROD_CD = T2.PROD_CD
  WHERE T1.OCCUR_DT = @V_BIN_DATE
  GROUP BY 
       T1.OCCUR_DT
      ,T1.WH_ORG_ID_EMP
      ,T1.AFA_SEC_EMPID
      ,T1.PROD_CD;
COMMIT;
END

