create or replace PROCEDURE DBA.P_REPORT_PTEPD_TRDASSN(IN @v_year varchar(4), @v_mth varchar(2))
BEGIN 
	DECLARE @V_LAST_TR_DATE INT; 
	DECLARE @V_YEARMONTH VARCHAR(6); 
	SELECT MAX(RQ) INTO @V_LAST_TR_DATE FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1'  AND NIAN||YUE=@V_YEARMONTH;
	SET @V_YEARMONTH=@v_year||@v_mth;
	  commit;
	select zjzh,
       jjdm,
       sum(ljsz_cw_y + ljsz_cn_y) /
       (select count(1)
          from dba.t_ddw_d_rq
         where nian||yue between @v_year||'01' and
               @V_YEARMONTH) as rjsz
  into #t
  from dba.t_ddw_xy_jjzb_m
 where nian || yue = @V_YEARMONTH
   and jjdm in (select distinct column_a
                  from dba.gt_ods_bbdr_org a
                 where nian || yue = @V_YEARMONTH
                   and report_cd = 'smcpkh'
                   and row_num > 1)
 group by jjdm, zjzh;
  commit;
	-- 一产品户多产品清单
	select column_c as prod_account,
	       column_a as prod_code
  into #t_multi_prod
  from dba.gt_ods_bbdr_org a
 where nian || yue = @V_YEARMONTH
   and report_cd = 'smcpkh'
   and row_num > 1
   and column_c in (select column_c
                      from dba.gt_ods_bbdr_org a
                     where nian || yue = @V_YEARMONTH
                       and report_cd = 'smcpkh'
                       and row_num > 1
                     group by column_c
                    having count(column_a) > 1);

   --调整前后产品代码映射关系
   select prod_code,prod_code_adjust
   into #temp_prod_mapping
   from #t_multi_prod a
   left join (select prod_account,
                    min(prod_code) as prod_code_adjust
               from #t_multi_prod
              group by prod_account) b
     on a.prod_account = b.prod_account
   where prod_code <> prod_code_adjust;

	
	select a.zjzh 资金账号,
       a.jjdm 基金代码,
       a.rjsz 月日均市值,
       case
         when b.rjsz = 0 then
          0
         else
          a.rjsz / b.rjsz
       end as 保有比例,
       c.prod_code,
       c.prod_account
  into #t_kh_fp
  from #t a
  left join (select jjdm, sum(rjsz) as rjsz from #t group by jjdm) b
    on a.jjdm = b.jjdm
  left join #t_multi_prod c
    on a.jjdm = c.prod_code
 order by a.jjdm;
	
  commit;
-- 更新多产品保有比例
	update #t_kh_fp
   set 保有比例 = coalesce(b.保有比例_adjust, 0) from #t_kh_fp a 
    left join (select 资金账号,
                       基金代码,
                       月日均市值 /
                       月日均市值_total as 保有比例_adjust
                  from #t_kh_fp a
                  left join (select prod_account,
                                   sum(月日均市值) as 月日均市值_total
                              from #t_kh_fp
                             where prod_account is not null
                             group by prod_account) b on a.prod_account = b.prod_account
                 where a.prod_account is not null) b on a.资金账号 = b.资金账号 and a.基金代码 = b.基金代码
 where b.资金账号 is not null;
	
  commit;

  --各个产品下的股基交易量指标，待修正调整前后的指标
  select a.column_a as 产品代码,
                         sum(b.gjjyl_m + coalesce(b.ptjyl_m, 0) +
                             coalesce(b.xyjyl_m, 0)) as 股基交易量_产品户_月,
                         sum(b.gjjyl_y + coalesce(b.ptjyl_y, 0) +
                             coalesce(b.xyjyl_y, 0)) as 股基交易量_产品户_年
  into #temp_prod_amt
  from dba.gt_ods_bbdr_org a
  left join dba.tmp_ddw_khqjt_m_d b on a.column_c = b.zjzh and b.nian || b.yue = @V_YEARMONTH
  where a.nian || a.yue = @V_YEARMONTH
     and report_cd = 'smcpkh'
     and row_num > 1
  group by a.column_a;

  --修正调整后产品代码的股基交易量
  update #temp_prod_amt a 
  set 
  a.股基交易量_产品户_月 = c.股基交易量_产品户_月
  ,a.股基交易量_产品户_年 = c.股基交易量_产品户_年
  from #temp_prod_amt a
  left join  #temp_prod_mapping b on a.产品代码 = b.prod_code
  left join #temp_prod_amt c on c.产品代码 = b.prod_code_adjust
  where c.股基交易量_产品户_月  is not null 
  and c.股基交易量_产品户_年 is not null;


--私募产品交易分配_客户指标_产品户

	delete from DBA.T_REPORT_PTEPD_TRDASSN_CUS_PDACC where YEAR_MTH=convert(int,@V_YEARMONTH);
	insert into DBA.T_REPORT_PTEPD_TRDASSN_CUS_PDACC
  (YEAR_MTH,
   PROD_CD,
   PROD_ACT_CPTL_ACCT,
   PROD_ACT_ORG_NO,
   PROD_ACT_ORG_NAME,
   PDACSFTQ_MTH,
   PDACSFTQ_YEAR,
   AJST_BEFO_PROD_CD)
  select CONVERT(INT, @V_YEARMONTH), --   AS 年月,
         coalesce(d.prod_code_adjust, a.column_a), -- as 产品代码,
         a.column_c, -- as 产品户资金账号,
         c.wh_org_id, -- as 产品户机构编号,
         c.brh_name, -- 产品户机构名称,
         b.gjjyl_m + coalesce(b.ptjyl_m, 0) + coalesce(b.xyjyl_m, 0), -- as 股基交易量_产品户_月,
         b.gjjyl_y + coalesce(b.ptjyl_y, 0) + coalesce(b.xyjyl_y, 0), -- as 股基交易量_产品户_年,
         d.prod_code -- as 调整前产品代码
    from dba.gt_ods_bbdr_org a
    left join dba.tmp_ddw_khqjt_m_d b
      on a.column_c = b.zjzh
     and b.nian || b.yue = @V_YEARMONTH
    left join dm.T_PUB_CUST c
      on c.year || c.mth = @V_YEARMONTH
     and a.column_c = c.main_cptl_acct
    left join (select *
                 from #t_multi_prod a
                 left join (select prod_account,
                                  min(prod_code) as prod_code_adjust
                             from #t_multi_prod
                            group by prod_account) b
                   on a.prod_account = b.prod_account) d
      on a.column_a = d.prod_code
   where a.nian || a.yue = @V_YEARMONTH
     and report_cd = 'smcpkh'
     and row_num > 1
     and a.column_a not in (select DISTINCT prod_code from #temp_prod_mapping);
   
   --私募产品交易分配_客户指标_客户分配
	delete from DBA.T_REPORT_PTEPD_TRDASSN_CUS_CUSASSN WHERE YEAR_MTH=CONVERT(INT,@V_YEARMONTH);
	INSERT INTO DBA.T_REPORT_PTEPD_TRDASSN_CUS_CUSASSN
  (YEAR_MTH,
   CUST_CPTL_ACCT,
   CUST_ORG_NO,
   CUST_ORG_NAME,
   PROD_CD,
   PDACSFTQ_MTH,
   PDACSFTQ_YEAR,
   RETAIN_RATI,
   SFTQAV_PROD_ACT_MTH,
   SFTQAV_PROD_ACT_YEAR,
   AJST_BEFO_PROD_CD)
  select CONVERT(INT, @V_YEARMONTH),
         b.资金账号 as 客户资金账号,
         c.wh_org_id as 客户机构编号,
         c.brh_name 客户机构名称,
         coalesce(d.prod_code_adjust, a.产品代码) as 产品代码,
         a.股基交易量_产品户_月,
         a.股基交易量_产品户_年,
         b.保有比例,
         a.股基交易量_产品户_月 * b.保有比例 as 调整值_股基交易量_产品户_月,
         a.股基交易量_产品户_年 * b.保有比例 as 调整值_股基交易量_产品户_年,
         d.prod_code as 调整前产品代码
    from #temp_prod_amt a
    left join #t_kh_fp b
      on a.产品代码 = b.基金代码
    left join dm.T_PUB_CUST c
      on c.year || c.mth = @V_YEARMONTH
     and b.资金账号 = c.main_cptl_acct
    left join (select *
                 from #t_multi_prod a
                 left join (select prod_account,
                                  min(prod_code) as prod_code_adjust
                             from #t_multi_prod
                            group by prod_account) b
                   on a.prod_account = b.prod_account) d
      on a.产品代码 = d.prod_code;
  commit;
  --修正有产品代码调整的部分的指标
 update dba.t_report_ptepd_trdassn_cus_cusassn 
   set sftqav_prod_act_mth = pdacsftq_mth * retain_rati
       ,sftqav_prod_act_year = pdacsftq_year * retain_rati
 from dba.t_report_ptepd_trdassn_cus_cusassn 
 where year_mth = @v_yearmonth 
  and prod_cd in (select distinct prod_code_adjust from #temp_prod_mapping);
 commit;

  --私募产品交易分配_员工客户指标_产品户

	DELETE FROM DBA.T_REPORT_PTEPD_TRDASSN_EMPCUS_PDACC WHERE YEAR_MTH=CONVERT(INT,@V_YEARMONTH);
	INSERT INTO DBA.T_REPORT_PTEPD_TRDASSN_EMPCUS_PDACC
  (YEAR_MTH,
   PROD_CD,
   PROD_ACT_CPTL_ACCT,
   PROD_ACT_ORG_NO,
   PROD_ACT_ORG_NAME,
   PDACSFTQ_MTH,
   PDACSFTQ_YEAR,
   PSN_JNO,
   EMP_ORG_NO,
   EMP_ORG_NAME,
   RIGHT_RATI,
   RASFTQ_PROD_ACT_MTH,
   RASFTQ_PROD_ACT_YEAR,
   AJST_BEFO_PROD_CD)
  select CONVERT(INT, @V_YEARMONTH),
         coalesce(d.prod_code_adjust, a.产品代码) as 产品代码,
         a.产品户资金账号,
         a.产品户机构编号,
         a.产品户机构名称,
         a.股基交易量_产品户_月,
         a.股基交易量_产品户_年,
         b.afatwo_ygh 员工号,
         c.pk_org as 员工机构编号,
         c.hr_name as 员工机构名称,
         b.jxbl2 责权比例,
         a.股基交易量_产品户_月 * jxbl2 as 责权分配后股基交易量_产品户_月,
         a.股基交易量_产品户_年 * jxbl2 as 责权分配后股基交易量_产品户_年,
         d.prod_code as 调整前产品代码
    from (select a.column_a as 产品代码,
                 a.column_c as 产品户资金账号,
                 c.wh_org_id as 产品户机构编号,
                 c.brh_name 产品户机构名称,
                 b.gjjyl_m + coalesce(b.ptjyl_m, 0) + coalesce(b.xyjyl_m, 0) as 股基交易量_产品户_月,
                 b.gjjyl_y + coalesce(b.ptjyl_y, 0) + coalesce(b.xyjyl_y, 0) as 股基交易量_产品户_年
            from dba.gt_ods_bbdr_org a
            left join dba.tmp_ddw_khqjt_m_d b
              on a.column_c = b.zjzh
             and b.nian || b.yue = @V_YEARMONTH
            left join dm.T_PUB_CUST c
              on c.year || c.mth = @V_YEARMONTH
             and a.column_c = c.main_cptl_acct
           where a.nian || a.yue = @V_YEARMONTH
             and report_cd = 'smcpkh'
             and row_num > 1
             --修正产品代码调整部分需要剔除的记录
             and a.column_a not in (select DISTINCT prod_code from #temp_prod_mapping)) a
    left join dba.t_ddw_serv_relation b
      on b.nian || b.yue = @V_YEARMONTH
     and a.产品户资金账号 = b.zjzh
    LEFT JOIN dba.t_dim_org c
      on b.jgbh_yg = c.pk_org
    left join (select *
                 from #t_multi_prod a
                 left join (select prod_account,
                                  min(prod_code) as prod_code_adjust
                             from #t_multi_prod
                            group by prod_account) b
                   on a.prod_account = b.prod_account) d
      on a.产品代码 = d.prod_code;
     commit;

  --私募产品交易分配_员工客户指标_客户分配

	delete from DBA.T_REPORT_PTEPD_TRDASSN_EMPCUS_CUSASSN WHERE YEAR_MTH=CONVERT(INT,@V_YEARMONTH);
	INSERT INTO DBA.T_REPORT_PTEPD_TRDASSN_EMPCUS_CUSASSN
  (YEAR_MTH,
   CUST_CPTL_ACCT,
   CUST_ORG_NO,
   CUST_ORG_NAME,
   PROD_CD,
   PDACSFTQ_MTH,
   PDACSFTQ_YEAR,
   RETAIN_RATI,
   SFTQAV_PROD_ACT_MTH,
   SFTQAV_PROD_ACT_YEAR,
   PSN_JNO,
   EMP_ORG_NO,
   EMP_ORG_NAME,
   RIGHT_RATI,
   RASFTQAV_PROD_ACT_MTH,
   RASFTQAV_PROD_ACT_YEAR,
   AJST_BEFO_PROD_CD)
  select CONVERT(INT, @V_YEARMONTH),
         a.客户资金账号,
         a.客户机构编号,
         a.客户机构名称,
         coalesce(d.prod_code_adjust, a.产品代码) as 产品代码,
         a.股基交易量_产品户_月,
         a.股基交易量_产品户_年,
         a.保有比例,
         a.调整值_股基交易量_产品户_月,
         a.调整值_股基交易量_产品户_年,
         b.afatwo_ygh 员工号,
         c.pk_org as 员工机构编号,
         c.hr_name as 员工机构名称,
         b.jxbl2 责权比例,
         a.调整值_股基交易量_产品户_月 * b.jxbl2 as 责权分配后调整值_股基交易量_产品户_月,
         a.调整值_股基交易量_产品户_年 * b.jxbl2 as 责权分配后调整值_股基交易量_产品户_年,
         d.prod_code as 调整前产品代码
    from (select b.资金账号 as 客户资金账号,
                 c.wh_org_id as 客户机构编号,
                 c.brh_name 客户机构名称,
                 a.*,
                 b.保有比例,
                 a.股基交易量_产品户_月 * b.保有比例 as 调整值_股基交易量_产品户_月,
                 a.股基交易量_产品户_年 * b.保有比例 as 调整值_股基交易量_产品户_年
          -- into #t_kh
            from #temp_prod_amt a
            left join #t_kh_fp b
              on a.产品代码 = b.基金代码
            left join dm.T_PUB_CUST c on c.year || c.mth = @V_YEARMONTH and b.资金账号 = c.main_cptl_acct) a
    left join dba.t_ddw_serv_relation b on b.nian || b.yue = @V_YEARMONTH and a.客户资金账号 = b.zjzh
    LEFT JOIN dba.t_dim_org c on b.jgbh_yg = c.pk_org
    left join (select *
                 from #t_multi_prod a
                 left join (select prod_account,
                                  min(prod_code) as prod_code_adjust
                             from #t_multi_prod
                            group by prod_account) b
                   on a.prod_account = b.prod_account) d on a.产品代码 = d.prod_code;
  commit;
 
 --修正有产品代码调整的部分的指标
 update dba.t_report_ptepd_trdassn_empcus_cusassn 
   set sftqav_prod_act_mth = pdacsftq_mth * retain_rati * right_rati
       ,sftqav_prod_act_year = pdacsftq_year * retain_rati * right_rati
       ,rasftqav_prod_act_mth = pdacsftq_mth * retain_rati * right_rati
       ,rasftqav_prod_act_year = pdacsftq_year * retain_rati * right_rati
 from dba.t_report_ptepd_trdassn_empcus_cusassn 
 where year_mth = @v_yearmonth 
  and prod_cd in (select distinct prod_code_adjust from #temp_prod_mapping);
 commit;
	END

 
-- select * from DBA.T_REPORT_PTEPD_TRDASSN_EMPCUS_CUSASSN where  year_mth=201712
-- select * from DBA.T_REPORT_PTEPD_TRDASSN_EMPCUS_PDACC where year_mth=201712
