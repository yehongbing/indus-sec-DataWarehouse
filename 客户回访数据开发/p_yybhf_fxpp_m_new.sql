create procedure dba.p_yybhf_fxpp_m_new(@i_nian varchar(4), @i_yue varchar(2))
begin

  /******************************************************************
  ������: Ӫҵ���طÿͻ�����Ʒ����ƥ�����
  ��д��: ����
  ��������: 2014-10-10
  ��飺

  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
             20180314                 rengz              �޸ķ��յȼ��ж��������ɡ�a.PROD_RISK_FLAG = '0' -- �Ϲ桱�����������ݡ�elig_check_str����5λ�жϡ�������յȼ�  ��ֵ0����ƥ�䣬1����ƥ�� 
                                                         secumentrust ���� elig_check_str �ֶΣ�8λ�ַ������壨1-�Ƿ���Ҫ�������ۣ�2-��Ʒ���ޣ�3-��Ʒ���4-�ʲ�Ҫ��5-���յȼ���6-���ڸ���ͻ���7-�����ʣ�8-�������ͣ�
                                                                      ȡֵ��0-ƥ�䣬1-��ƥ�䣬2-����ƥ��
  *********************************************************************/



    
    declare @v_kszzr_m int;
    declare @v_jszzr_m int;
    
    commit;
    
    set @v_kszzr_m = (select min(rq) from dba.t_ddw_d_rq where nian||yue=@i_nian||@i_yue);
    set @v_jszzr_m = (select max(rq) from dba.t_ddw_d_rq where nian||yue=@i_nian||@i_yue);

    delete from dba.t_yybhf_fxpp_m where nian||yue=@i_nian||@i_yue;
    commit;
    ------------------------------------
    -----  ������֤ȯ���
    ------------------------------------
    insert into dba.t_yybhf_fxpp_m(nian,yue,wtrq,yybmc,zjzh,khbh,khxm,xb,khrq,ywlx,wtje,jjdm,jjmc,cplx,cpfxdj,khfxdj,ymccsz,bygmje,lx,JGBH)
    select @i_nian,                 -- ��      
           @i_yue,                  -- ��
           a.curr_date,               -- ί������
    
           h.hr_name,               --Ӫҵ��
           a.fund_account,          -- �ʽ��˺�
           a.client_id,             -- �ͻ����
           acc_name,                -- �ͻ�����
           case when b.sex_code = '1' then '��'
                when b.sex_code = '2' then 'Ů'
                else ''
           end              as sex, --�Ա�
           b.open_date,             -- ��������
           case when a.business_flag = 44020 then '�Ϲ�'
                when a.business_flag = 44022 then '�깺'
           end              as ywlb, -- ҵ������
           a.entrust_balance,        -- ί�н��
           a.prod_code,              -- ����
           a.prod_name,              -- ֤ȯ�������
           case when a.prod_ta_no='CZZ' then '֤ȯ���'
                else i.jjlb  end         as cplx, -- ��Ʒ����
           e.dict_prompt    as cpfxdj,-- ��Ʒ���յȼ�
           c.dict_prompt    as khfxdj,-- �ͻ����յȼ�
           coalesce(f.zqlccpe,0)        as ymccsz,-- ��ĩ�ֲ��г�
           g.gmje           as gmje  ,-- ���¹�����
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
                   and substr(elig_check_str,5,1)='0'        -- 20180314 �����ж����� ���յȼ�ƥ��
                   and DEAL_FLAG<>'4'                       -- �ų�����
                   and BUSINESS_FLAG in (44022,44020)       -- �깺���Ϲ�
                 group by fund_account,prod_code )  g  on a.fund_account=g.fund_account and a.prod_code=g.prod_code
       left  join dba.t_dim_org                 as  h  on convert(numeric(10,0), a.branch_no) = convert(numeric(10,0),h.branch_no)
       left  join dba.t_ddw_d_jj                    i  on i.nian=@i_nian and i.yue=@i_yue and a.prod_code=i.jjdm
      where a.curr_date between @v_kszzr_m and @v_jszzr_m
       and  substr(elig_check_str,5,1)='0'                  -- 20180314 �����ж����� ���յȼ�ƥ��
       and a.entrust_status='8'	                            -- ί�гɹ�
       and a.DEAL_FLAG <> '4'                               -- �ų�����
       and a.BUSINESS_FLAG in (44022, 44020)                -- �깺���Ϲ�
    ;
    
    ------------------------------------
    -----  �������
    ------------------------------------
    insert into dba.t_yybhf_fxpp_m(nian,yue,wtrq,yybmc,zjzh,khbh,khxm,xb,khrq,ywlx,wtje,jjdm,jjmc,cplx,cpfxdj,khfxdj,ymccsz,bygmje,lx,JGBH)
    select @i_nian,                 -- ��      
           @i_yue,                  -- ��
           a.curr_date,               -- ί������
    
           h.hr_name,               --Ӫҵ��
           a.fund_account,          -- �ʽ��˺�
           a.client_id,             -- �ͻ����
           acc_name,                -- �ͻ�����
           case when b.sex_code = '1' then '��'
                when b.sex_code = '2' then 'Ů'
                else ''
           end              as sex, --�Ա�
           b.open_date,             -- ��������
           case when a.business_flag = 43130 then '�Ϲ�'
           end              as ywlb, -- ҵ������
           abs(a.entrust_balance),   -- ί�н��
           a.prod_code,              -- ����
           a.prod_name,              -- �����������
           '�������'       as cplx, -- ��Ʒ����
           e.dict_prompt    as cpfxdj,-- ��Ʒ���յȼ�
           c.dict_prompt    as khfxdj,-- �ͻ����յȼ�
           coalesce(f.yhlccyje,0)        as ymccsz,-- ��ĩ�ֲ��г�
           g.gmje           as gmje  ,-- ���¹�����
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
                  and a.business_flag = 43130           ---��������Ϲ�����
                group by fund_account,prod_code )    g   on a.fund_account=g.fund_account and a.prod_code=g.prod_code
     left  join DBA.t_dim_org                 as     h  on convert(numeric(10,0), a.branch_no) = convert(numeric(10,0),h.branch_no)
      where a.curr_date between @v_kszzr_m and @v_jszzr_m
        and a.business_flag = 43130                     ---��������Ϲ�����
    ;
    commit;

end