create procedure dba.p_yybhf_fxpp_m_new(@i_nian varchar(4), @i_yue varchar(2))
begin

  /******************************************************************
  程序功能: 营业部回访客户、产品风险匹配情况
  编写者: 张琦
  创建日期: 2014-10-10
  简介：

  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180314                 rengz              修改风险等级判断条件，由“a.PROD_RISK_FLAG = '0' -- 合规”调整至，依据“elig_check_str”第5位判断。代表风险等级  数值0代表匹配，1代表不匹配 
                                                         secumentrust 表中 elig_check_str 字段，8位字符串含义（1-是否需要重新评价；2-产品期限；3-产品类别；4-资产要求；5-风险等级；6-属于高龄客户；7-亏损率；8-收益类型）
                                                                      取值：0-匹配，1-不匹配，2-无需匹配
  *********************************************************************/



    
    declare @v_kszzr_m int;
    declare @v_jszzr_m int;
    
    commit;
    
    set @v_kszzr_m = (select min(rq) from dba.t_ddw_d_rq where nian||yue=@i_nian||@i_yue);
    set @v_jszzr_m = (select max(rq) from dba.t_ddw_d_rq where nian||yue=@i_nian||@i_yue);

    delete from dba.t_yybhf_fxpp_m where nian||yue=@i_nian||@i_yue;
    commit;
    ------------------------------------
    -----  开基及证券理财
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
           case when a.business_flag = 44020 then '认购'
                when a.business_flag = 44022 then '申购'
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
           case when a.entrust_balance <  1000000  then '4'
                when a.entrust_balance >= 1000000  then '5' 
           end as fenlei,
           convert(varchar,a.branch_no)
-- select *
      from dba.T_EDW_UF2_HIS_SECUMENTRUST a
      left join dba.t_ods_tr_fund_acc_info   b on convert(varchar, a.fund_account) = b.fund_acc
      left join dba.T_ODS_UF2_SYSDICTIONARY  c on c.dict_entry = 2505 and c.subentry = convert(varchar, a.corp_risk_level)
      left join (select distinct prod_code,prodrisk_level from dba.T_EDW_UF2_PRODCODE  where load_dt between  @v_kszzr_m and @v_jszzr_m ) d on a.prod_code=d.prod_code
      left join dba.T_ODS_UF2_SYSDICTIONARY  e on e.dict_entry = 2505 and e.subentry = convert(varchar, d.prodrisk_level)
      left join (select FUND_ACCOUNT, prod_code, SUM(CURRENT_AMOUNT) as zqlccpe
                 from DBA.GT_ODS_ZHXT_SECUMSHARE
                 where load_dt = @v_jszzr_m
                 group by FUND_ACCOUNT, prod_code)   f   on a.FUND_ACCOUNT=f.fund_account and a.prod_code=f.prod_code
      left join (select fund_account,prod_code,sum(business_balance) as gmje
                 from dba.T_EDW_UF2_HIS_SECUMENTRUST 
                 where curr_date between @v_kszzr_m and @v_jszzr_m
                   and substr(elig_check_str,5,1)='0'        -- 20180314 调整判定条件 风险等级匹配
                   and DEAL_FLAG<>'4'                       -- 排除撤单
                   and BUSINESS_FLAG in (44022,44020)       -- 申购、认购
                 group by fund_account,prod_code )  g  on a.fund_account=g.fund_account and a.prod_code=g.prod_code
       left  join dba.t_dim_org                 as  h  on convert(numeric(10,0), a.branch_no) = convert(numeric(10,0),h.branch_no)
       left  join dba.t_ddw_d_jj                    i  on i.nian=@i_nian and i.yue=@i_yue and a.prod_code=i.jjdm
      where a.curr_date between @v_kszzr_m and @v_jszzr_m
       and  substr(elig_check_str,5,1)='0'                  -- 20180314 调整判定条件 风险等级匹配
       and a.entrust_status='8'	                            -- 委托成功
       and a.DEAL_FLAG <> '4'                               -- 排除撤单
       and a.BUSINESS_FLAG in (44022, 44020)                -- 申购、认购
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
           case when a.entrust_balance <  1000000  then '4'
                when a.entrust_balance >= 1000000  then '5' 
           end as fenlei,
           convert(varchar,a.branch_no)
    --select*
      from dba.t_edw_uf2_his_bankmdeliver    a
      left join dba.t_ods_tr_fund_acc_info   b on convert(varchar, a.fund_account) = b.fund_acc
      left join dba.T_ODS_UF2_SYSDICTIONARY  c on c.dict_entry = 2505 and c.subentry = convert(varchar, a.corp_risk_level)
      left join (select distinct prod_code,prodrisk_level from dba.T_EDW_UF2_PRODCODE  where load_dt between  @v_kszzr_m and @v_jszzr_m ) d on a.prod_code=d.prod_code
      left join dba.T_ODS_UF2_SYSDICTIONARY  e on e.dict_entry = 2505 and e.subentry = convert(varchar, d.prodrisk_level)
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

end