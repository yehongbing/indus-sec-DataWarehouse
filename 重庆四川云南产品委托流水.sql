										
-- 重庆、四川与云南
select 分公司
      ,分支机构
      ,客户编号
      ,客户总资产
      ,交易日期
      ,当前时间
      ,申报日期
      ,资产账户
      ,证券理财账号
      ,交易账号
      ,产品TA编号
      ,产品代码
      ,产品类型
      ,产品名称
      ,产品风险等级
      ,客户风险等级
      ,委托方式
      --,委托状态
      ,委托数量
      --,委托价格
      ,委托金额
      ,成交数量
      ,成交金额
      ,min(b.init_date) as 最近风险评测时间
from
(
select b.father_branch_name_root 分公司
    ,b.hr_name 分支机构
    ,a.client_id 客户编号
    ,c.zzc 客户总资产
    ,a.init_date 交易日期
    ,a.curr_time 当前时间
    ,a.curr_date 申报日期
    ,a.fund_account 资产账户
    ,a.secum_account 证券理财账号
    ,trans_account 交易账号
    ,a.prodta_no 产品TA编号
    ,a.prod_code 产品代码
    ,case when a.prodta_no='CZZ' then '证券理财' else d.jjlb end 产品类型	
    ,a.prod_name 产品名称	
    ,e_dic.dict_prompt 产品风险等级	
    ,f.dict_prompt 客户风险等级	
   -- ,最近风险评测时间	
   ,g.dict_prompt 委托方式	
    --,h.dict_prompt 委托状态	
    ,a.entrust_amount 委托数量	
    --,a.entrust_price 委托价格	
    ,a.entrust_balance 委托金额	
    ,a.business_amount 成交数量	
    ,a.business_balance 成交金额
-- select  *
from dba.T_EDW_UF2_HIS_SECUMDEALINFO a
left join dba.t_dim_org b on convert(varchar,a.branch_no)=b.branch_no and b.branch_no is not null
left join dba.tmp_ddw_khqjt_d_d c on c.rq=a.curr_date and a.client_id=c.khbh_hs
left join dba.t_ddw_d_jj d on a.prod_code=d.jjdm and substring(convert(varchar,a.curr_date),1,6)=d.nian||d.yue
left join dba.T_EDW_UF2_PRODCODE e on e.load_dt=a.curr_date and e.prod_code=a.prod_code
left join dba.T_ODS_UF2_SYSDICTIONARY  e_dic on e_dic.dict_entry = 2505 and e_dic.subentry = convert(varchar, e.prodrisk_level)
left join dba.T_ODS_UF2_SYSDICTIONARY f on f.dict_entry=2505 and convert(varchar, a.corp_risk_level)=f.subentry
left join dba.T_ODS_UF2_SYSDICTIONARY g on g.dict_entry=1201 and a.op_entrust_way=g.subentry
--left join dba.T_ODS_UF2_SYSDICTIONARY h on h.dict_entry=1203 and a.op_entrust_way=h.subentry
where a.curr_date between 20180101 and 20180629
and b.father_branch_name_root in ('重庆分公司','四川分公司','云南分公司')
) a
left join dba.T_EDW_UF2_HIS_CLIENTJOUR b on b.business_flag=1827 and a.申报日期>=b.init_date and a.客户编号=b.client_id
group by 分公司
        ,分支机构
        ,客户编号
        ,客户总资产
        ,交易日期
        ,当前时间
        ,申报日期
        ,资产账户
        ,证券理财账号
        ,交易账号
        ,产品TA编号
        ,产品代码
        ,产品类型
        ,产品名称
        ,产品风险等级
        ,客户风险等级
        ,委托方式
        --,委托状态
        ,委托数量
        --,委托价格
        ,委托金额
        ,成交数量
        ,成交金额

-- select client_id, max(init_date) 最近风测日期  from dba.T_EDW_UF2_HIS_CLIENTJOUR where business_flag=1827 group by client_id


