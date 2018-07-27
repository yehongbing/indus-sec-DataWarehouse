
-- 应急方案使用说明： 将下列变量按实际值进行全部替换，
-- 例如当前跑批日期是20180715，那么需要替换的变量为：
    -- @V_YEAR（当前年）可替换成'2018'
    -- @YEAR（当前年，若当前跑批日期为1月，那么该变量则为上年）可替换成'2018'
    -- @MONTH（上月）可替换成'06'
    -- @V_MONTH（本月）可调换成'07'
    -- @V_LST_NATRE_DAY_MTHBEG（上月月初）可替换成20180601，注意没有单引号，因为数据类型为INT
    -- @V_LST_NATRE_DAY_MTHEND（上月月末）可替换成20180630，注意没有单引号，因为数据类型为INT
    -- @V_NATRE_DAY_MTHBEG（本月月初）可替换成20180701，注意没有单引号，因为数据类型为INT


-- 以下为需要替换日期变量的脚本，替换完并执行
    ------------------------------------
    ----- 开基和证券理财 ----------------
    ------------------------------------
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
                WHEN A.BUSINESS_FLAG = 44039 THEN '定投'
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
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  E ON E.DICT_ENTRY = 41003 AND E.SUBENTRY = CONVERT(VARCHAR, D.PRODRISK_LEVEL)
    LEFT JOIN (SELECT FUND_ACCOUNT, PROD_CODE, SUM(CURRENT_AMOUNT) AS ZQLCCPE
               FROM DBA.GT_ODS_ZHXT_SECUMSHARE
               WHERE LOAD_DT = @V_LST_NATRE_DAY_MTHEND
               GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
    LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(BUSINESS_BALANCE) AS GMJE
               FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST T1
               WHERE CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
                 AND DEAL_FLAG<>'4'                     
                 AND BUSINESS_FLAG IN (44022,44020,44039)     
               GROUP BY FUND_ACCOUNT,PROD_CODE )  G  ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
     LEFT  JOIN DBA.T_DIM_ORG                 AS  H  ON CONVERT(NUMERIC(10,0), A.BRANCH_NO) = CONVERT(NUMERIC(10,0),H.BRANCH_NO)
     LEFT  JOIN DBA.T_DDW_D_JJ                    I  ON I.NIAN=@YEAR AND I.YUE=@MONTH AND A.PROD_CODE=I.JJDM
    WHERE A.CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND AND A.DATE_CLEAR >= @V_NATRE_DAY_MTHBEG
    AND A.ENTRUST_STATUS='8'                           
    AND A.DEAL_FLAG <> '4'                             
    AND A.BUSINESS_FLAG IN (44022,44020,44039)              
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
                WHEN A.BUSINESS_FLAG = 44039 THEN '定投'
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
      LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  E ON E.DICT_ENTRY = 41003 AND E.SUBENTRY = CONVERT(VARCHAR, D.PRODRISK_LEVEL)
      LEFT JOIN (SELECT FUND_ACCOUNT, PROD_CODE, SUM(CURRENT_AMOUNT) AS ZQLCCPE
                 FROM DBA.GT_ODS_ZHXT_SECUMSHARE
                 WHERE LOAD_DT = @V_LST_NATRE_DAY_MTHEND
                 GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
      LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(BUSINESS_BALANCE) AS GMJE
                 FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST T1
                 WHERE CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
                   AND DEAL_FLAG<>'4'                       
                   AND BUSINESS_FLAG IN (44022,44020,44039)       
                 GROUP BY FUND_ACCOUNT,PROD_CODE )  G  ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
       LEFT  JOIN DBA.T_DIM_ORG                 AS  H  ON CONVERT(VARCHAR,A.BRANCH_NO) = H.BRANCH_NO
       LEFT  JOIN DBA.T_DDW_D_JJ                    I  ON I.NIAN=@YEAR AND I.YUE=@MONTH AND A.PROD_CODE=I.JJDM
      WHERE A.CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
       AND A.ENTRUST_STATUS='8'                            
       AND A.DEAL_FLAG <> '4'                              
       AND A.BUSINESS_FLAG IN (44022,44020,44039)               
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
            WHEN A.BUSINESS_FLAG = 44039 THEN '定投'
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
       '5'                                                    AS LX,
       CONVERT(VARCHAR,A.BRANCH_NO)                           AS JGBH
    INTO #T_ADD_POS_SECUM_TEMP
    FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST A
    LEFT JOIN DBA.T_ODS_TR_FUND_ACC_INFO   B ON CONVERT(VARCHAR, A.FUND_ACCOUNT) = B.FUND_ACC
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  C ON C.DICT_ENTRY = 2505 AND C.SUBENTRY = CONVERT(VARCHAR, A.CORP_RISK_LEVEL)
    LEFT JOIN  DBA.T_EDW_UF2_PRODCODE      D ON A.CURR_DATE=D.LOAD_DT AND A.PROD_CODE=D.PROD_CODE
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY  E ON E.DICT_ENTRY = 41003 AND E.SUBENTRY = CONVERT(VARCHAR, D.PRODRISK_LEVEL)
    LEFT JOIN (SELECT FUND_ACCOUNT, PROD_CODE, SUM(CURRENT_AMOUNT) AS ZQLCCPE
               FROM DBA.GT_ODS_ZHXT_SECUMSHARE
               WHERE LOAD_DT = @V_LST_NATRE_DAY_MTHEND
               GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
    LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(BUSINESS_BALANCE) AS GMJE
               FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST T1
               WHERE CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND
                 AND DEAL_FLAG<>'4'                       
                 AND BUSINESS_FLAG IN (44022, 44020,44039)       
               GROUP BY FUND_ACCOUNT,PROD_CODE )  G  ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
     LEFT JOIN DBA.T_DIM_ORG                 AS  H  ON CONVERT(NUMERIC(10,0), A.BRANCH_NO) = CONVERT(NUMERIC(10,0),H.BRANCH_NO)
     LEFT JOIN DBA.T_DDW_D_JJ                    I  ON I.NIAN=@YEAR AND I.YUE=@MONTH AND A.PROD_CODE=I.JJDM
     LEFT JOIN DBA.T_EDW_XZZG_T_WEIXIN_PRODUCT AS J ON A.PROD_CODE = J.P_CODE AND A.CURR_DATE = J.LOAD_DT
    WHERE A.CURR_DATE BETWEEN @V_LST_NATRE_DAY_MTHBEG AND @V_LST_NATRE_DAY_MTHEND AND A.DATE_CLEAR >= @V_NATRE_DAY_MTHBEG
    AND A.ENTRUST_STATUS='8'                           
    AND A.DEAL_FLAG <> '4'                             
    AND A.BUSINESS_FLAG IN (44022, 44020,44039)              
    AND D.PRODRISK_LEVEL = 5                           
    ;


    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH 
    INTO #T_ADD_POS_SECUM
    FROM #T_ADD_POS_SECUM_TEMP
    WHERE ZJZH||'-'||JJDM||'-'||WTRQ NOT IN(
    SELECT ZJZH||'-'||JJDM||'-'||WTRQ FROM DBA.T_YYBHF_FXPP_M 
    WHERE NIAN||YUE=@YEAR||@MONTH);


    INSERT INTO DBA.T_YYBHF_FXPP_M(NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH)
    SELECT NIAN,YUE,WTRQ,YYBMC,ZJZH,KHBH,KHXM,XB,KHRQ,YWLX,WTJE,JJDM,JJMC,CPLX,CPFXDJ,KHFXDJ,YMCCSZ,BYGMJE,LX,JGBH
    FROM #T_ADD_POS_SECUM;

    COMMIT;