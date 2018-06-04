CREATE PROCEDURE dm.p_evt_cred_incm_m_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  程序功能:  客户信用业务收入月表（日更新）
  编写者: rengz
  创建日期: 2017-11-28
  简介：客户资金变动数据，日更新
        主要数据来自于：T_DDW_F00_KHMRZJZHHZ_D 日报 普通账户资金 及市值流入流出
                        tmp_ddw_khqjt_m_m     融资融券客户资金流入 流出

  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180124                 rengz              对融资利息进行分拆
             20180316                 rengz              1、修正委托费、经手费
                                                         2、客户群增加股票质押和约定购回目标客户
             20180330                 rengz              增加保证金利差收入及保证金利差收入修正
  *********************************************************************/
 
    -- declare @v_bin_date             numeric(8,0); 
    declare @v_bin_year             varchar(4); 
    declare @v_bin_mth              varchar(2); 
    declare @v_bin_qtr              varchar(2); --季度
    declare @v_bin_year_start_date  numeric(8); 
    declare @v_bin_mth_start_date   numeric(8); 
    declare @v_bin_lastmth_date     numeric(8); --上月同期
    declare @v_bin_lastmth_year     varchar(4); --上月同期对应年
    declare @v_bin_lastmth_mth      varchar(2); --上月同期对应月
    declare @v_bin_lastmth_start_date numeric(8); --上月开始日期
    declare @v_bin_lastmth_end_date numeric(8); --上月结束日期
    declare @v_date_num             numeric(8); --本月自然日的天数
    declare @v_bin_mth_end_date     numeric(8); --本月结束交易日
    declare @v_lcbl                 numeric(38,8); ---保证金利差比例
    declare @v_bin_qtr_m1_start_date  numeric(8); --本季度第1个月第一个交易日
    declare @v_bin_qtr_m1_end_date    numeric(8); --本季度第1个月最后一个交易日
    declare @v_bin_qtr_m2_start_date  numeric(8); --本季度第2个月第一个交易日
    declare @v_bin_qtr_m2_end_date    numeric(8); --本季度第2个月最后一个交易日
    declare @v_bin_qtr_m3_start_date  numeric(8); --本季度第3个月第一个交易日
    declare @v_bin_qtr_m3_end_date    numeric(8); --本季度第3个月最后一个交易日
    declare @v_bin_qtr_end_date     numeric(8); --本季度结束交易日 
    declare @v_date_qtr_m1_num        numeric(8); --本月自然日的天数
    declare @v_date_qtr_m2_num        numeric(8); --本月自然日的天数
    declare @v_date_qtr_m3_num        numeric(8); --本月自然日的天数
    
	set @V_OUT_FLAG = -1;  --初始清洗赋值-1
    set @v_bin_date =@v_bin_date ;
	
	--生成衍生变量
    set @v_bin_year=(select year from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_mth =(select mth  from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_qtr =(select qtr  from dm.t_pub_date where dt=@v_bin_date );
    set @v_bin_year_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and if_trd_day_flag=1 ); 
    set @v_bin_mth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_mth_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_qtr_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and qtr=@v_bin_qtr and if_trd_day_flag=1 ); 
    set @v_bin_lastmth_date=convert(numeric(8,0),(select dateadd(month,-1,@v_bin_date)));
    set @v_bin_lastmth_year=(select year from dm.t_pub_date where dt=@v_bin_lastmth_date ); 
    set @v_bin_lastmth_mth =(select mth  from dm.t_pub_date where dt=@v_bin_lastmth_date ); 
    set @v_bin_lastmth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_lastmth_year  and mth=@v_bin_lastmth_mth ); 
    set @v_bin_lastmth_end_date=(select max(dt) from dm.t_pub_date where year=@v_bin_lastmth_year  and mth=@v_bin_lastmth_mth ----and if_trd_day_flag=1  modify by rengz 根据王健全意见调整为自然日
	                                                                                                    ); 
    set @v_date_num          =case  when @v_bin_date=@v_bin_mth_end_date then (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth )
                                    else (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and dt<=@v_bin_date) end;             --当月最后一个交易日，按照自然日统计天数
    set @v_lcbl              =case when coalesce((select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth),0)=0 then 
                                        (select bjzlclv from dba.t_jxfc_market where nian||yue=substr(convert(varchar,dateadd(month,-1,convert(varchar,@v_bin_date)),112),1,6)  )
                              else (select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth) end ; 
    set @v_bin_qtr_m1_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1);
    set @v_bin_qtr_m1_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and mth=(select convert(varchar,min(mth)) from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_date_qtr_m1_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date );             --本季度第1个月自然日的天数
    set @v_date_qtr_m2_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date );             --本季度第2个月自然日的天数
    set @v_date_qtr_m3_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m3_start_date and @v_bin_qtr_m3_end_date );             --本季度第3个月自然日的天数  
 
    --删除计算期数据
    delete from dm.t_evt_cred_incm_m_d where year=@v_bin_year and mth=@v_bin_mth ;
    commit;
     

------------------------
  -- 生成每日客户清单：仅保留有两融业务的客户ID
------------------------  
  insert into dm.t_evt_cred_incm_m_d (CUST_ID, OCCUR_DT, MAIN_CPTL_ACCT, LOAD_DT, YEAR, MTH)
  select distinct a.client_id,
                  a.load_dt,
                  b.fund_account,
                  a.load_dt as rq,
                  @v_bin_year,
                  @v_bin_mth
    from (select distinct client_id, load_dt
            from DBA.T_EDW_RZRQ_CLIENT t
           where t.load_dt = @v_bin_date
             -- and t.client_status = '0'		-- 20180525 算年累计不需排除 
             -- and convert(varchar, t.branch_no) not in ('5', '55', '51', '44', '9999')   --20180525 客户层不限制
             and t.client_id <> '448999999' ----剔除1户“专项头寸账户自动生成”。疑似公司自有账户，client_id下无普通账户，仅有多个信用账户且均为主资金户
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_gpzyhg_d t
           where t.rq between @v_bin_mth_start_date and  @v_bin_date ---股票质押 
             -- and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')  --20180525 客户层不限制
             and t.khbh_hs <> '448999999'
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_ydsgh_d t
           where t.rq between @v_bin_mth_start_date and  @v_bin_date ---约定式购回
             -- and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')  --20180525 客户层不限制
             and t.khbh_hs <> '448999999') a
    left join dba.t_edw_uf2_fundaccount b
      on a.client_id = b.client_id
     and b.load_dt = @v_bin_date
     -- and b.fundacct_status = '0'	-- 20180525 算年累计不需排除
     and b.asset_prop = '0'
     and b.main_flag = '1';
   
   commit;
------------------------
  -- 生成佣金 净佣金
------------------------  
    select client_id
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare1 else 0 end )                                                                                         as yhs       --印花税 
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare2 else 0 end )                                                                                         as ghf       --过户费
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare3 else 0 end )                                                                                         as wtf       --委托费  
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then EXCHANGE_FARE0 else 0 end )                                                                                as jsf       --经手费   
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then EXCHANGE_FARE3 else 0 end )                                                                                as zgf       --证管费   
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then FAREX else 0 end )                                                                                         as qtfy      --其他费用  
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002,                                        ---普通
                                                                                                  4211, 4212, 4213, 4214, 4215, 4216                 ---信用
                                                                                                )  then (fare0)  else 0 end)                                                               as yj_m      --佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002,                                        ---普通
                                                                                                    4211, 4212, 4213, 4214, 4215, 4216               ---信用
                                                                                                )  then 
            	                                                                                        coalesce(fare0,0)
									                                                                    + coalesce(fare3,0)
									                                                                    + coalesce(farex,0)
									                                                                    + coalesce(fare2,0)
									                                                                    - coalesce(exchange_fare0,0)
									                                                                    - coalesce(exchange_fare3,0)
									                                                                    - coalesce(exchange_fare4,0)
									                                                                    - coalesce(exchange_fare5,0)
									                                                                    - coalesce(exchange_fare6,0)
									                                                                    - coalesce(exchange_farex,0)
									                                                                    - coalesce(exchange_fare2,0)
              		                                                                         else 0 end)                                                                                as jyj_m      --净佣金
  
   ---普通交易
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then (fare0)  else 0 end)                                                as pt_yj_m  --普通交易佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                           as pt_jyj_m  --普通交易净佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then (fare2)  else 0 end)                                                as pt_ghf_m   --普通交易过户费
   ---信用交易
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)                        as xy_yj_m    --信用交易佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                       as xy_jyj_m   --信用交易净佣金
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in (4211, 4212, 4213, 4214, 4215, 4216)  then (fare2)  else 0 end)                     as xy_ghf_m    --信用交易过户费

    ,sum(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)                   as xy_yj_y    --年累计信用交易佣金
    ,sum(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                       as xy_jyj_y   --年累计信用交易净佣金      
    into #t_yj   
    from DBA.T_EDW_RZRQ_HISDELIVER a
    where a.load_dt between @v_bin_year_start_date and @v_bin_date
    group by client_id;
 
    commit;
   
    update dm.t_evt_cred_incm_m_d a
    set 
	    a.GROSS_CMS	        =coalesce(yj_m,0)           , -- 毛佣金
	    a.NET_CMS	        =coalesce(jyj_m,0)          , -- 净佣金
	    a.TRAN_FEE	        =coalesce(ghf,0)            , -- 过户费
	    a.STP_TAX	        =coalesce(yhs,0)            , -- 印花税
	    a.ORDR_FEE	        =coalesce(wtf,0)            , -- 委托费
	    a.HANDLE_FEE	    =coalesce(jsf,0)            , -- 经手费
	    a.SEC_RGLT_FEE	    =coalesce(zgf,0)            , -- 证管费
	    a.OTH_FEE		    =coalesce(qtfy,0)           , -- 其他费用
	    a.CREDIT_ODI_CMS	    =coalesce(pt_yj_m,0)    , -- 融资融券普通佣金
	    a.CREDIT_ODI_NET_CMS	=coalesce(pt_jyj_m,0)   , -- 融资融券普通净佣金
	    a.CREDIT_ODI_TRAN_FEE	=coalesce(pt_ghf_m,0)   , -- 融资融券普通过户费
	    a.CREDIT_CRED_CMS	    =coalesce(xy_yj_m,0)    , -- 融资融券信用佣金
	    a.CREDIT_CRED_NET_CMS	=coalesce(xy_jyj_m,0)   , -- 融资融券信用净佣金
	    a.CREDIT_CRED_TRAN_FEE	=coalesce(xy_ghf_m,0)   , -- 融资融券信用过户费
	    a.TY_CRED_CMS	    =coalesce(xy_yj_y,0)        , -- 今年信用佣金
	    a.TY_CRED_NET_CMS   =coalesce(xy_jyj_y,0)	      -- 今年信用净佣金 
    from dm.t_evt_cred_incm_m_d  a
    left join #t_yj              b on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
 commit;
  
 

------------------------
  -- 两融利息
------------------------  
    ---实收利息分解
   select client_id
         ,sum(case when business_flag in (2219, 2812, 2822, 2832, 2842)                                 then abs(occur_balance) else 0 end) as  lxzc_rz_m
 		 ,sum(case when business_flag in (2807, 2224)                                                   then abs(occur_balance) else 0 end) as  lxzc_rq_m
         ,sum(case when business_flag in ( 2814, 2816, 2824,2826, 2834, 2836, 2844, 2846,  2220, 2221)  then abs(occur_balance) else 0 end) as  lxzc_qt_m
   into #t_rzrq_ss
   -- select *,occur_balance
   from dba.t_EDW_RZRQ_HISFUNDJOUR   
   where  init_date  between @v_bin_mth_start_date and @v_bin_date
   group by client_id;

   commit;

    update dm.t_evt_cred_incm_m_d 
    set 
     a.fin_paidint =coalesce(lxzc_rz_m,0)+coalesce(lxzc_qt_m,0)          ,--融资实收利息
     a.MTH_FIN_IE  =coalesce(lxzc_rz_m,0)                                ,--月融资利息支出
     a.MTH_CRDT_STK_IE =coalesce(lxzc_rq_m,0)                            ,--月融券利息支出
     a.MTH_OTH_IE      =coalesce(lxzc_qt_m,0)                             --月其他利息支出
    from dm.t_evt_cred_incm_m_d a 
    left join #t_rzrq_ss        b on a.cust_id=b.client_id
    where  a.occur_dt=@v_bin_date;

   commit;
 
   ---应收利息分解
    select a.client_id
           ,b.byddjgzr  as tianshu
           ,a.close_finance_interest  as close_finance_interest_ym
           ,a.close_fare_interest     as close_fare_interest_ym  
           ,a.close_other_interest    as close_other_interest_ym  

           ,c.close_finance_interest  as close_finance_interest_sy
           ,c.close_fare_interest     as close_fare_interest_sy  
           ,c.close_other_interest    as close_other_interest_sy  
           ,a.finance_close_balance + a.CLOSE_FARE_DEBIT + a.CLOSE_OTHER_DEBIT  as rzrqzjcb_xzq    --融资融券资金成本_计算基数
   into #t_rzrq_ys
   from DBA.T_EDW_RZRQ_hisASSETDEBIT      a
   left join dba.t_ddw_d_rq               b on a.init_date=b.rq
   left join DBA.T_EDW_RZRQ_hisASSETDEBIT c on a.client_id=c.client_id and c.init_date=@v_bin_lastmth_end_date
   where a.init_date = @v_bin_date
     and a.branch_no not in(44,9999);


  commit;
   
 
    update dm.t_evt_cred_incm_m_d 
    set  
        a.FIN_RECE_INT =coalesce(close_finance_interest_ym,0)+coalesce(close_fare_interest_ym,0)+coalesce(close_other_interest_ym,0)          
                       -coalesce(close_finance_interest_sy,0)-coalesce(close_fare_interest_sy,0)-coalesce(close_other_interest_sy,0)     ,--融资应收利息
        a.MTH_FIN_RECE_INT =coalesce(close_finance_interest_ym,0)-coalesce(close_finance_interest_sy,0)                                  ,--月融资应收利息
        a.MTH_FEE_RECE_INT =coalesce(close_fare_interest_ym,0)-coalesce(close_fare_interest_sy,0)                                        ,--月费用应收利息
        a.MTH_OTH_RECE_INT =coalesce(close_other_interest_ym,0)-coalesce(close_other_interest_sy,0)                                      ,--月其他应收利息
        a.CREDIT_CPTL_COST =coalesce(rzrqzjcb_xzq,0)*(select rzrq_ll from dba.t_jxfc_rzrq_ll where nianyue=@v_bin_year||@v_bin_mth ) / 360                --融资融券资金成本
    from dm.t_evt_cred_incm_m_d a 
    left join #t_rzrq_ys        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;

   commit;
 
------------------------
  -- 股票质押佣金
------------------------  
   select khbh_hs,
          sum(case when rq between @v_bin_mth_start_date and @v_bin_date then  yj  end )       as yj_m,
          sum(case when rq between @v_bin_mth_start_date and @v_bin_date then  jyj end )       as jyj_m,
          sum(case when rq =@v_bin_date then  sslx end ) 
             - sum(case when rq =@v_bin_lastmth_end_date then  sslx                            end )      as sslx_m,
          sum(case when rq =@v_bin_date then  yswslx+sslx end ) 
             - sum(case when rq =@v_bin_lastmth_end_date then  yswslx+sslx                     end )      as yslx_m 
   into #t_gpzyyj
   from dba.t_ddw_gpzyhg_d a
   where rq between @v_bin_lastmth_start_date  and @v_bin_date
   group by khbh_hs;

   
  update dm.t_evt_cred_incm_m_d a
    set 
        a.STKPLG_CMS	    =coalesce(yj_m,0)      ,    -- 股票质押佣金
	    a.STKPLG_NET_CMS	=coalesce(jyj_m,0)     ,    -- 股票质押净佣金
	    a.STKPLG_PAIDINT	=coalesce(sslx_m,0)      ,  -- 股票质押实收利息
	    a.STKPLG_RECE_INT	=coalesce(yslx_m,0)         -- 股票质押应收利息 
    from dm.t_evt_cred_incm_m_d a
    left join #t_gpzyyj         b on a.cust_id=b.khbh_hs
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- 约定购回佣金
------------------------  
    
     select a.khbh_hs as client_id, 
        SUM(a.yj)           as yj_m,    -- 约定购回佣金
        SUM(a.jyj)          as jyj_m ,  -- 约定购回净佣金
        sum(sslx)           as sslx_m,  -- 约定购回实收利息
        sum(yswslx+sslx)    as yslx_m 
      into #t_ydghyj
      from  dba.t_ddw_ydsgh_d   a 
      where rq between @v_bin_mth_start_date and @v_bin_date
      group by a.khbh_hs ;
    

    update dm.t_evt_cred_incm_m_d 
    set 
        a.APPTBUYB_CMS	    =coalesce(yj_m,0)      ,    -- 约定购回佣金
	    a.APPTBUYB_NET_CMS	=coalesce(jyj_m,0)     ,    -- 约定购回净佣金 
	    a.APPTBUYB_PAIDINT	=coalesce(sslx_m,0)         -- 约定购回实收利息 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_ydghyj         b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- 融资融券_核算保证金利差收入_月累计
------------------------  

   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- 月累计核算利差保证金  "max(账户现金-max(（负债-客户提交担保资产×折算比例）,0),0) 担保资产含市值和现金，为自然日累计"
          ,coalesce(hsbzj,0)/@v_date_num                                               as rzrq_hsbzj_yrj       -- 融资融券_核算保证金_月日均
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- 融资融券_核算保证金利差收入_月累计
   into #t_bzjlcsr
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between  @v_bin_mth_start_date AND @v_bin_date
   group by client_id;

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- 融资融券保证金利差收入 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 

	-- pb过户费
	update dm.T_EVT_CRED_INCM_M_D
	set pb_tran_fee = coalesce(b.PB_TRAN_FEE_M,0)
	from dm.T_EVT_CRED_INCM_M_D a
	left join (
		select cust_id, sum(PB_TRAN_FEE) as PB_TRAN_FEE_M
		from dm.T_EVT_ODI_INCM_D_D
		where occur_dt between @v_bin_mth_start_date AND @v_bin_date
		group by cust_id
	) b on a.cust_id=b.cust_id
	where a.occur_dt=@v_bin_date;


------------------------
  -- 修正本季度2两个月的融资融券_核算保证金利差收入_月累计
------------------------  

 
  if @v_bin_date= @v_bin_qtr_end_date
  then 
 
  ---本季度第1月
   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- 月累计核算利差保证金  "max(账户现金-max(（负债-客户提交担保资产×折算比例）,0),0) 担保资产含市值和现金，为自然日累计"
          ,coalesce(hsbzj,0)/@v_date_qtr_m1_num                                        as rzrq_hsbzj_yrj       -- 融资融券_核算保证金_月日均
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- 融资融券_核算保证金利差收入_月累计
   into #t_bzjlcsr_qrt_m1
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between  @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date
   group by client_id;

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM_CET	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- 融资融券保证金利差收入_修正 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr_qrt_m1 b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_qtr_m1_end_date;
  commit; 


  ---本季度第2月
   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- 月累计核算利差保证金  "max(账户现金-max(（负债-客户提交担保资产×折算比例）,0),0) 担保资产含市值和现金，为自然日累计"
          ,coalesce(hsbzj,0)/@v_date_qtr_m2_num                                        as rzrq_hsbzj_yrj       -- 融资融券_核算保证金_月日均
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- 融资融券_核算保证金利差收入_月累计
   into #t_bzjlcsr_qrt_m2
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date
   group by client_id;
  commit;
  

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM_CET	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- 融资融券保证金利差收入_修正 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr_qrt_m2 b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_qtr_m2_end_date;
  commit; 
 
  end if;
 

   set @V_OUT_FLAG = 0;  --结束,清洗成功输出0 
 
end
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_m_d TO query_dev
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_m_d TO xydc
GO