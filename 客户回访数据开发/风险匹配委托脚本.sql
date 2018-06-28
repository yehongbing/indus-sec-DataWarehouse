CREATE OR REPLACE PROCEDURE DM.SECUM_MIDMTH_SUPLMT(IN @V_BIN_DATE INT)

BEGIN
  /******************************************************************
  程序功能: 开基，证券理财及银行理财月中补
  编写者: YHB
  创建日期: 2018-05-21
  简介： 
  *********************************************************************/

  DECLARE @V_YEAR VARCHAR(4);   -- 当前年
  DECLARE @YEAR VARCHAR(4);     --若月份为01则年份续作处理
  DECLARE @MONTH VARCHAR(4);    --同上
  DECLARE @V_MONTH VARCHAR(2);  --当前月
  DECLARE @V_LST_NATRE_DAY_MTHBEG  INT ;    --自然月_上月初
  DECLARE @V_LST_NATRE_DAY_MTHEND  INT ;    --自然月_上月末
  DECLARE @V_NATRE_DAY_MTHBEG  INT ;    --自然月_本月初


  SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
  SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
  SET @YEAR = (SELECT CASE WHEN  @V_MONTH = '01'  THEN  CONVERT(VARCHAR,CONVERT(INTEGER,@V_YEAR) - 1) ELSE @V_YEAR END);
  SET @MONTH = (SELECT CASE WHEN  @V_MONTH = '01'  THEN '12' 
                            WHEN  CONVERT(INTEGER,@V_MONTH) >= 11 THEN CONVERT(VARCHAR,CONVERT(INTEGER,@V_MONTH)-1)
                            ELSE '0'||CONVERT(VARCHAR,CONVERT(INTEGER,@V_MONTH)-1) END);
  SET @V_LST_NATRE_DAY_MTHBEG = (SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@YEAR AND MTH = @MONTH);
  SET @V_LST_NATRE_DAY_MTHEND = (SELECT MAX(DT) FROM DM.T_PUB_DATE WHERE YEAR=@YEAR AND MTH = @MONTH);
  SET @V_NATRE_DAY_MTHBEG = (SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND MTH = @V_MONTH);

    ------------------------------------
    ----- 开基和证券理财 ----------------
    ------------------------------------
    SELECT @YEAR                                                 AS NIAN,       
           @MONTH                                                AS YUE,        
           A.CURR_DATE                                            AS WTRQ,       
           H.HR_NAME                                              AS YYBMC,      
           A.FUND_ACCOUNT                                         AS ZJZH,       
           A.CLIENT_ID                                            AS KHBH,       
           ACC_NAME                                               AS KHXM,       
           CASE WHEN B.SEX_CODE = '1' THEN '男'
                WHEN B.SEX_CODE = '2' THEN '女'
                ELSE ''
           END                                                    AS XB,         
           B.OPEN_DATE                                            AS KHRQ,       
           CASE WHEN A.BUSINESS_FLAG = 44020 THEN '认购'
                WHEN A.BUSINESS_FLAG = 44022 THEN '申购'
           END                                                    AS YWLX,       
           A.ENTRUST_BALANCE                                      AS WTJE,       
           A.PROD_CODE                                            AS JJDM,       
           A.PROD_NAME                                            AS JJMC,       
           CASE WHEN A.PROD_TA_NO='CZZ' THEN '证券理财'
                ELSE I.JJLB  END                                  AS CPLX,       
           E.DICT_PROMPT                                          AS CPFXDJ,     
           C.DICT_PROMPT                                          AS KHFXDJ,     
           COALESCE(F.ZQLCCPE,0)                                  AS YMCCSZ,     
           G.GMJE                                                 AS BYGMJE,     
           CASE WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='1' THEN '1'
                WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='0' AND A.ENTRUST_BALANCE <  1000000  THEN '7'
                WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='0' AND A.ENTRUST_BALANCE >= 1000000  THEN '8' 
           END                                                    AS LX,
           CONVERT(VARCHAR,A.BRANCH_NO)                           AS JGBH
    INTO #T_ADD_SECUM_TEMP
    FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST A
    LEFT JOIN DBA.T_ODS_TR_FUND_ACC_INFO   B ON CONVERT(VARCHAR, A.FUND_ACCOUNT) = B.FUND_ACC
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  C ON C.DICT_ENTRY = 2505 AND C.SUBENTRY = CONVERT(VARCHAR, A.CORP_RISK_LEVEL)
    LEFT JOIN  DBA.T_EDW_UF2_PRODCODE   D ON A.CURR_DATE=D.LOAD_DT AND A.PROD_CODE=D.PROD_CODE
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  E ON E.DICT_ENTRY = 2505 AND E.SUBENTRY = CONVERT(VARCHAR, D.PRODRISK_LEVEL)
    LEFT JOIN (SELECT FUND_ACCOUNT, PROD_CODE, SUM(CURRENT_AMOUNT) AS ZQLCCPE
               FROM DBA.GT_ODS_ZHXT_SECUMSHARE
               WHERE LOAD_DT = @V_LST_NATRE_DAY_MTHBEG
               GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
    LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(BUSINESS_BALANCE) AS GMJE
               FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST T1
               WHERE CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
                 AND SUBSTR(T1.ELIG_CHECK_STR,5,1)='0'       
                 AND DEAL_FLAG<>'4'                     
                 AND BUSINESS_FLAG IN (44022,44020)     
               GROUP BY FUND_ACCOUNT,PROD_CODE )  G  ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
     LEFT  JOIN DBA.T_DIM_ORG                 AS  H  ON A.BRANCH_NO = H.BRANCH_NO
     LEFT  JOIN DBA.T_DDW_D_JJ                    I  ON I.NIAN=@V_YEAR AND I.YUE=@V_MONTH AND A.PROD_CODE=I.JJDM
    WHERE A.CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND AND A.DATE_CLEAR >= @V_NATRE_DAY_MTHBEG
    AND A.ENTRUST_STATUS='8'                           
    AND A.DEAL_FLAG <> '4'                             
    AND A.BUSINESS_FLAG IN (44022, 44020)              
    ;
   

    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH 
    INTO #T_ADD_SECUM 
    FROM #T_ADD_SECUM_TEMP
    WHERE ZJZH||'-'||JJDM||'-'||WTRQ NOT IN(
    SELECT ZJZH||'-'||JJDM||'-'||WTRQ FROM DBA.T_YYBHF_FXPP_M 
    WHERE NIAN||YUE=@YEAR||@MONTH);



    INSERT INTO DBA.T_YYBHF_FXPP_M(NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH)
    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH
    FROM #T_ADD_SECUM;

    COMMIT;

    ------------------------------------
    ----- 在途部分 ----------------------
    ------------------------------------

    -- UNFINISHED ENTRUST LISTS OF PRODUCT(BANK PRODUCT EXCLUDED)
    SELECT @YEAR                                                    AS NIAN,                     
           @MONTH                                                   AS YUE,                                          
           A.CURR_DATE                                                AS WTRQ,                        
           H.HR_NAME                                                  AS YYBMC,                                       
           A.FUND_ACCOUNT                                             AS ZJZH,                    
           A.CLIENT_ID                                                AS KHBH,                               
           ACC_NAME                                                   AS KHXM,                                                       
           CASE WHEN B.SEX_CODE = '1' THEN '男'
                WHEN B.SEX_CODE = '2' THEN '女'
                ELSE ''
           END                                                        AS XB,                                   
           B.OPEN_DATE                                                AS KHRQ,       
           CASE WHEN A.BUSINESS_FLAG = 44020 THEN '认购'
                WHEN A.BUSINESS_FLAG = 44022 THEN '申购'
           END                                                        AS YWLX,       
           A.ENTRUST_BALANCE                                          AS WTJE,       
           A.PROD_CODE                                                AS JJDM,       
           A.PROD_NAME                                                AS JJMC,       
           I.JJLB                                                     AS CPLX,       
           E.DICT_PROMPT                                              AS CPFXDJ,     
           C.DICT_PROMPT                                              AS KHFXDJ,     
           COALESCE(F.ZQLCCPE,0)                                      AS YMCCSZ,     
           G.GMJE                                                     AS BYGMJE,     
           CASE WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='1' THEN '1'
                WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='0' AND A.ENTRUST_BALANCE <  1000000  THEN '7'
                WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='0' AND A.ENTRUST_BALANCE >= 1000000  THEN '8' 
           END                                                         AS LX,
           CONVERT(VARCHAR,A.BRANCH_NO)                                AS JGBH
      INTO #T_ADD_SECUM_UNFINISH_TEMP
      FROM DBA.T_ODS_HS08_REAL_SECUMENTRUST A
      LEFT JOIN DBA.T_ODS_TR_FUND_ACC_INFO   B ON CONVERT(VARCHAR, A.FUND_ACCOUNT) = B.FUND_ACC
      LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  C ON C.DICT_ENTRY = 2505 AND C.SUBENTRY = CONVERT(VARCHAR, A.CORP_RISK_LEVEL)
      LEFT JOIN DBA.T_EDW_UF2_PRODCODE  D ON A.CURR_DATE=D.LOAD_DT AND A.PROD_CODE=D.PROD_CODE
      LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  E ON E.DICT_ENTRY = 2505 AND E.SUBENTRY = CONVERT(VARCHAR, D.PRODRISK_LEVEL)
      LEFT JOIN (SELECT FUND_ACCOUNT, PROD_CODE, SUM(CURRENT_AMOUNT) AS ZQLCCPE
                 FROM DBA.GT_ODS_ZHXT_SECUMSHARE
                 WHERE LOAD_DT = @V_LST_NATRE_DAY_MTHBEG
                 GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
      LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(BUSINESS_BALANCE) AS GMJE
                 FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST T1
                 WHERE CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
                   AND SUBSTR(T1.ELIG_CHECK_STR,5,1)='0'    
                   AND DEAL_FLAG<>'4'                       
                   AND BUSINESS_FLAG IN (44022,44020)       
                 GROUP BY FUND_ACCOUNT,PROD_CODE )  G  ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
       LEFT  JOIN DBA.T_DIM_ORG                 AS  H  ON CONVERT(VARCHAR,A.BRANCH_NO) = H.BRANCH_NO
       LEFT  JOIN DBA.T_DDW_D_JJ                    I  ON I.NIAN=@V_YEAR AND I.YUE=@V_MONTH AND A.PROD_CODE=I.JJDM
      WHERE A.CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
       AND A.ENTRUST_STATUS='8'                            
       AND A.DEAL_FLAG <> '4'                              
       AND A.BUSINESS_FLAG IN (44022, 44020)               
    ;

    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH 
    INTO #T_ADD_SECUM_UNFINISH 
    FROM #T_ADD_SECUM_UNFINISH_TEMP
    WHERE ZJZH||'-'||JJDM||'-'||WTRQ NOT IN(
    SELECT ZJZH||'-'||JJDM||'-'||WTRQ FROM DBA.T_YYBHF_FXPP_M 
    WHERE NIAN||YUE=@YEAR||@MONTH);

    INSERT INTO DBA.T_YYBHF_FXPP_M(NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH)
    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH
    FROM #T_ADD_SECUM_UNFINISH;

    COMMIT;

    ------------------------------------
    ----- 银行理财 ----------------------
    ------------------------------------
    SELECT 
           @YEAR                                                    AS NIAN,                         
           @MONTH                                                   AS YUE,                                              
           A.CURR_DATE                                                AS WTRQ,                            
           H.HR_NAME                                                  AS YYBMC,                                           
           A.FUND_ACCOUNT                                             AS ZJZH,                        
           A.CLIENT_ID                                                AS KHBH,                                   
           ACC_NAME                                                   AS KHXM,                                                           
           CASE WHEN B.SEX_CODE = '1' THEN '男'
                WHEN B.SEX_CODE = '2' THEN '女'
                ELSE ''
           END                                                        AS XB,                                       
           B.OPEN_DATE                                                AS KHRQ,       
           CASE WHEN A.BUSINESS_FLAG = 43130 THEN '认购'
           END                                                        AS YWLX,       
           ABS(A.ENTRUST_BALANCE)                                     AS WTJE,       
           A.PROD_CODE                                                AS JJDM,       
           A.PROD_NAME                                                AS JJMC,       
           '银行理财'                                                  AS CPLX,       
           E.DICT_PROMPT                                              AS CPFXDJ,     
           C.DICT_PROMPT                                              AS KHFXDJ,     
           COALESCE(F.YHLCCYJE,0)                                      AS YMCCSZ,     
           G.GMJE                                                     AS BYGMJE,     
           CASE WHEN A.ENTRUST_BALANCE <  1000000  THEN '7'
                WHEN A.ENTRUST_BALANCE >= 1000000  THEN '8' 
           END                                                         AS LX,
           CONVERT(VARCHAR,A.BRANCH_NO)                                AS JGBH
      INTO #T_ADD_BANKPROD
      FROM DBA.T_EDW_UF2_HIS_BANKMDELIVER    A
      LEFT JOIN DBA.T_ODS_TR_FUND_ACC_INFO   B ON CONVERT(VARCHAR, A.FUND_ACCOUNT) = B.FUND_ACC
      LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  C ON C.DICT_ENTRY = 2505 AND C.SUBENTRY = CONVERT(VARCHAR, A.CORP_RISK_LEVEL)
      LEFT JOIN (SELECT DISTINCT PROD_CODE,PRODRISK_LEVEL FROM DBA.T_EDW_UF2_PRODCODE  WHERE LOAD_DT BETWEEN  @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND ) D ON A.PROD_CODE=D.PROD_CODE
      LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  E ON E.DICT_ENTRY = 2505 AND E.SUBENTRY = CONVERT(VARCHAR, D.PRODRISK_LEVEL)
      LEFT JOIN (SELECT ZJZH AS FUND_ACCOUNT, CPDM AS PROD_CODE, SUM(DQCYJE) AS YHLCCYJE 
                 FROM DBA.T_DDW_YHLC_D
                 WHERE RQ = @V_LST_NATRE_DAY_MTHEND
                 GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
      LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(ENTRUST_BALANCE) AS GMJE
                FROM DBA.T_EDW_UF2_HIS_BANKMDELIVER T1
                WHERE T1.CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
                  AND T1.BUSINESS_FLAG = 43130           
                GROUP BY FUND_ACCOUNT,PROD_CODE )    G   ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
     LEFT  JOIN DBA.T_DIM_ORG                 AS     H  ON CONVERT(VARCHAR, A.BRANCH_NO) = H.BRANCH_NO
      WHERE A.CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
        AND A.BUSINESS_FLAG = 43130                    
    ;


    INSERT INTO DBA.T_YYBHF_FXPP_M(NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH)
    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH
    FROM #T_ADD_BANKPROD;

    COMMIT;

    -------------------------------------------
    ----- 积极型客户处理 -----------------------
    -------------------------------------------

    SELECT @YEAR                                            AS NIAN,     
       @MONTH                                               AS YUE,      
       A.CURR_DATE                                            AS WTRQ,     
       H.HR_NAME                                              AS YYBMC,    
       A.FUND_ACCOUNT                                         AS ZJZH,     
       A.CLIENT_ID                                            AS KHBH,     
       ACC_NAME                                               AS KHXM,     
       CASE WHEN B.SEX_CODE = '1' THEN '男'
            WHEN B.SEX_CODE = '2' THEN '女'
            ELSE ''
       END                                                    AS XB,       
       B.OPEN_DATE                                            AS KHRQ,     
       CASE WHEN A.BUSINESS_FLAG = 44020 THEN '认购'
            WHEN A.BUSINESS_FLAG = 44022 THEN '申购'
       END                                                    AS YWLX,     
       A.ENTRUST_BALANCE                                      AS WTJE,     
       A.PROD_CODE                                            AS JJDM,     
       A.PROD_NAME                                            AS JJMC,     
       CASE WHEN A.PROD_TA_NO='CZZ' THEN '证券理财'
            WHEN J.TYPE_ID = '59' THEN I.JJLB||'(小集合)'
            WHEN J.TYPE_ID = '58' THEN I.JJLB||'(大集合)'
            ELSE I.JJLB  END                                  AS CPLX,     
       E.DICT_PROMPT                                          AS CPFXDJ,   
       C.DICT_PROMPT                                          AS KHFXDJ,   
       COALESCE(F.ZQLCCPE,0)                                  AS YMCCSZ,   
       G.GMJE                                                 AS BYGMJE,   
       CASE WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='1' THEN '1'
            WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='0' AND A.ENTRUST_BALANCE <  1000000  THEN '7'
            WHEN SUBSTR(A.ELIG_CHECK_STR,5,1)='0' AND A.ENTRUST_BALANCE >= 1000000  THEN '8' 
       END                                                    AS LX,
       CONVERT(VARCHAR,A.BRANCH_NO)                           AS JGBH
    INTO #T_ADD_POS_SECUM_TEMP
    FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST A
    LEFT JOIN DBA.T_ODS_TR_FUND_ACC_INFO   B ON CONVERT(VARCHAR, A.FUND_ACCOUNT) = B.FUND_ACC
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  C ON C.DICT_ENTRY = 2505 AND C.SUBENTRY = CONVERT(VARCHAR, A.CORP_RISK_LEVEL)
    LEFT JOIN  DBA.T_EDW_UF2_PRODCODE      D ON A.CURR_DATE=D.LOAD_DT AND A.PROD_CODE=D.PROD_CODE
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  E ON E.DICT_ENTRY = 2505 AND E.SUBENTRY = CONVERT(VARCHAR, D.PRODRISK_LEVEL)
    LEFT JOIN (SELECT FUND_ACCOUNT, PROD_CODE, SUM(CURRENT_AMOUNT) AS ZQLCCPE
               FROM DBA.GT_ODS_ZHXT_SECUMSHARE
               WHERE LOAD_DT = @V_BIN_DATE
               GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
    LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(BUSINESS_BALANCE) AS GMJE
               FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST T1
               WHERE CURR_DATE BETWEEN @V_NATRE_DAY_MTHBEG AND @V_BIN_DATE
                 AND SUBSTR(T1.ELIG_CHECK_STR,5,1)='0'    
                 AND DEAL_FLAG<>'4'                       
                 AND BUSINESS_FLAG IN (44022,44020)       
               GROUP BY FUND_ACCOUNT,PROD_CODE )  G  ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
     LEFT JOIN DBA.T_DIM_ORG                 AS  H  ON A.BRANCH_NO = H.BRANCH_NO
     LEFT JOIN DBA.T_DDW_D_JJ                    I  ON I.NIAN=@V_YEAR AND I.YUE=@V_MONTH AND A.PROD_CODE=I.JJDM
     LEFT JOIN DBA.T_EDW_XZZG_T_WEIXIN_PRODUCT AS J ON A.PROD_CODE = J.P_CODE AND A.CURR_DATE = J.LOAD_DT
    WHERE A.CURR_DATE BETWEEN @V_NATRE_DAY_MTHBEG AND @V_BIN_DATE 
    AND A.ENTRUST_STATUS='8'                           
    AND A.DEAL_FLAG <> '4'                             
    AND A.BUSINESS_FLAG IN (44022, 44020)              
    AND D.PRODRISK_LEVEL = 5                           
    ;

    INSERT INTO DBA.T_YYBHF_FXPP_M(NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH)
    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH
    FROM #T_ADD_POS_SECUM_TEMP;

    COMMIT;
END