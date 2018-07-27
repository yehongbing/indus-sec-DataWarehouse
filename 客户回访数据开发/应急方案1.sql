   -- 替换一下变量
   -- @i_nian     年
   -- @i_yue      月
   -- @v_kszzr_m  月初
   -- @v_jszzr_m  月末


  insert into dba.t_yybhf_fxpp_m(nian,yue,wtrq,yybmc,zjzh,khbh,khxm,xb,khrq,ywlx,wtje,jjdm,jjmc,cplx,cpfxdj,khfxdj,ymccsz,bygmje,lx,JGBH)
    select @i_nian,                 -- 年      
           @i_yue,                  -- 月
           a.curr_date,               -- 委托日期
    
           h.hr_name,               --营业部
           a.fund_account,          -- 资金账号
           a.client_id,             -- 客户编号
           acc_name,                -- 客户姓名
           case when b.sex_code = '1' then '男'
                when b.sex_code = '2' then '女'
                else ''
           end              as sex, --性别
           b.open_date,             -- 开户日期
           case when a.business_flag = 44020 then '认购'
                when a.business_flag = 44022 then '申购'
                when a.business_flag = 44039 then '定投'
           end              as ywlb, -- 业务类型
           a.entrust_balance,        -- 委托金额
           a.prod_code,              -- 代码
           a.prod_name,              -- 证券理财名称
           case when a.prod_ta_no='CZZ' then '证券理财'
                else i.jjlb  end         as cplx, -- 产品类型
           e.dict_prompt    as cpfxdj,-- 产品风险等级
           c.dict_prompt    as khfxdj,-- 客户风险等级
           coalesce(f.zqlccpe,0)        as ymccsz,-- 月末持仓市场
           g.gmje           as gmje  ,-- 本月购买金额
           case when substr(a.elig_check_str,5,1)='1' then '1'
                when substr(a.elig_check_str,5,1)='0' and a.entrust_balance <  1000000  then '7'
                when substr(a.elig_check_str,5,1)='0' and a.entrust_balance >= 1000000  then '8' 
           end as fenlei,
           convert(varchar,a.branch_no)
-- select *
      from dba.T_EDW_UF2_HIS_SECUMENTRUST a
      left join dba.t_ods_tr_fund_acc_info   b on convert(varchar, a.fund_account) = b.fund_acc
      left join dba.T_ODS_UF2_SYSDICTIONARY  c on c.dict_entry = 2505 and c.subentry = convert(varchar, a.corp_risk_level)
      left join (select distinct prod_code,prodrisk_level from dba.T_EDW_UF2_PRODCODE  where load_dt between  @v_kszzr_m and @v_jszzr_m ) d on a.prod_code=d.prod_code
      left join dba.T_ODS_UF2_SYSDICTIONARY  e on e.dict_entry = 41003 and e.subentry = convert(varchar, d.prodrisk_level)
      left join (select FUND_ACCOUNT, prod_code, SUM(CURRENT_AMOUNT) as zqlccpe
                 from DBA.GT_ODS_ZHXT_SECUMSHARE
                 where load_dt = @v_jszzr_m
                 group by FUND_ACCOUNT, prod_code)   f   on a.FUND_ACCOUNT=f.fund_account and a.prod_code=f.prod_code
      left join (select fund_account,prod_code,sum(business_balance) as gmje
                 from dba.T_EDW_UF2_HIS_SECUMENTRUST 
                 where curr_date between @v_kszzr_m and @v_jszzr_m
                   and DEAL_FLAG<>'4'                       -- 排除撤单
                   and BUSINESS_FLAG in (44022,44020,44039)       -- 申购、认购
                 group by fund_account,prod_code )  g  on a.fund_account=g.fund_account and a.prod_code=g.prod_code
       left  join dba.t_dim_org                 as  h  on convert(numeric(10,0), a.branch_no) = convert(numeric(10,0),h.branch_no)
       left  join dba.t_ddw_d_jj                    i  on i.nian=@i_nian and i.yue=@i_yue and a.prod_code=i.jjdm
      where a.curr_date between @v_kszzr_m and @v_jszzr_m
       and  substr(elig_check_str,5,1)='0'                  -- 20180314 调整判定条件 风险等级匹配
       and a.entrust_status='8'                             -- 委托成功
       and a.DEAL_FLAG <> '4'                               -- 排除撤单
       and a.BUSINESS_FLAG in (44022,44020,44039)                -- 申购、认购
    ;
    
    ------------------------------------
    -----  银行理财
    ------------------------------------
    insert into dba.t_yybhf_fxpp_m(nian,yue,wtrq,yybmc,zjzh,khbh,khxm,xb,khrq,ywlx,wtje,jjdm,jjmc,cplx,cpfxdj,khfxdj,ymccsz,bygmje,lx,JGBH)
    select @i_nian,                 -- 年      
           @i_yue,                  -- 月
           a.curr_date,               -- 委托日期
    
           h.hr_name,               --营业部
           a.fund_account,          -- 资金账号
           a.client_id,             -- 客户编号
           acc_name,                -- 客户姓名
           case when b.sex_code = '1' then '男'
                when b.sex_code = '2' then '女'
                else ''
           end              as sex, --性别
           b.open_date,             -- 开户日期
           case when a.business_flag = 43130 then '认购'
           end              as ywlb, -- 业务类型
           abs(a.entrust_balance),   -- 委托金额
           a.prod_code,              -- 代码
           a.prod_name,              -- 银行理财名称
           '银行理财'       as cplx, -- 产品类型
           e.dict_prompt    as cpfxdj,-- 产品风险等级
           c.dict_prompt    as khfxdj,-- 客户风险等级
           coalesce(f.yhlccyje,0)        as ymccsz,-- 月末持仓市场
           g.gmje           as gmje  ,-- 本月购买金额
           case when a.entrust_balance <  1000000  then '7'
                when a.entrust_balance >= 1000000  then '8' 
           end as fenlei,
           convert(varchar,a.branch_no)
    --select*
      from dba.t_edw_uf2_his_bankmdeliver    a
      left join dba.t_ods_tr_fund_acc_info   b on convert(varchar, a.fund_account) = b.fund_acc
      left join dba.T_ODS_UF2_SYSDICTIONARY  c on c.dict_entry = 2505 and c.subentry = convert(varchar, a.corp_risk_level)
      left join (select distinct prod_code,prodrisk_level from dba.T_EDW_UF2_PRODCODE  where load_dt between  @v_kszzr_m and @v_jszzr_m ) d on a.prod_code=d.prod_code
      left join dba.T_ODS_UF2_SYSDICTIONARY  e on e.dict_entry = 41003 and e.subentry = convert(varchar, d.prodrisk_level)
      left join (select zjzh as FUND_ACCOUNT, cpdm as prod_code, SUM(dqcyje) as yhlccyje 
                 from dba.t_ddw_yhlc_d
                 where rq = @v_jszzr_m
                 group by FUND_ACCOUNT, prod_code)   f   on a.FUND_ACCOUNT=f.fund_account and a.prod_code=f.prod_code
      left join (select fund_account,prod_code,sum(entrust_balance) as gmje
                from dba.t_edw_uf2_his_bankmdeliver a
                where a.curr_date between @v_kszzr_m and @v_jszzr_m
                  and a.business_flag = 43130           ---银行理财认购成立
                group by fund_account,prod_code )    g   on a.fund_account=g.fund_account and a.prod_code=g.prod_code
     left  join DBA.t_dim_org                 as     h  on convert(numeric(10,0), a.branch_no) = convert(numeric(10,0),h.branch_no)
      where a.curr_date between @v_kszzr_m and @v_jszzr_m
        and a.business_flag = 43130                     ---银行理财认购成立
    ;
    commit;

    -- 积极型客户的月初数据处理
    insert into dba.t_yybhf_fxpp_m(nian,yue,wtrq,yybmc,zjzh,khbh,khxm,xb,khrq,ywlx,wtje,jjdm,jjmc,cplx,cpfxdj,khfxdj,ymccsz,bygmje,lx,JGBH)
    SELECT @i_nian                                            AS NIAN,     
       @i_yue                                               AS YUE,      
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
               WHERE LOAD_DT = @v_jszzr_m
               GROUP BY FUND_ACCOUNT, PROD_CODE)   F   ON A.FUND_ACCOUNT=F.FUND_ACCOUNT AND A.PROD_CODE=F.PROD_CODE
    LEFT JOIN (SELECT FUND_ACCOUNT,PROD_CODE,SUM(BUSINESS_BALANCE) AS GMJE
               FROM DBA.T_EDW_UF2_HIS_SECUMENTRUST T1
               WHERE CURR_DATE BETWEEN @v_kszzr_m AND @v_jszzr_m
                 AND DEAL_FLAG<>'4'                       
                 AND BUSINESS_FLAG IN (44022,44020,44039)       
               GROUP BY FUND_ACCOUNT,PROD_CODE )  G  ON A.FUND_ACCOUNT=G.FUND_ACCOUNT AND A.PROD_CODE=G.PROD_CODE
     LEFT JOIN DBA.T_DIM_ORG                 AS  H  ON CONVERT(NUMERIC(10,0), A.BRANCH_NO) = CONVERT(NUMERIC(10,0),H.BRANCH_NO)
     LEFT JOIN DBA.T_DDW_D_JJ                    I  ON I.NIAN=@i_nian AND I.YUE=@i_yue  AND A.PROD_CODE=I.JJDM
     LEFT JOIN DBA.T_EDW_XZZG_T_WEIXIN_PRODUCT AS J ON A.PROD_CODE = J.P_CODE AND A.CURR_DATE = J.LOAD_DT
    WHERE A.CURR_DATE BETWEEN @v_kszzr_m AND @v_jszzr_m
    AND A.ENTRUST_STATUS='8'                           
    AND A.DEAL_FLAG <> '4'                             
    AND A.BUSINESS_FLAG IN (44022, 44020,44039)              
    AND D.PRODRISK_LEVEL = 5                           
    ;