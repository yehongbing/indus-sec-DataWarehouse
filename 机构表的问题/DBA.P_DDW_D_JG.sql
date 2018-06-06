
CREATE PROCEDURE DBA.P_DDW_D_JG(in LOAD_DT varchar(10),out RUNSTATUS integer,inout MSG varchar(4000))
begin
  --定义存储过程信息
  declare @PROC_NAME varchar(80);
  declare @TARGET_SCHEMA varchar(10);
  declare @TARGET_TABLE varchar(20);
  declare @ERR_SQL varchar(200);
  declare @TX_DATE numeric(8);
  declare i_nian varchar(4);
  declare i_yue varchar(2);
  --定义错误代码，错误状态
  declare @ERR_MSG varchar(100);
  declare not_found exception for sqlstate value '02000';
  declare @temp_sql varchar(2000);
  declare @T_NAME varchar(20);
  declare @I integer;
  set @PROC_NAME='P_DDW_D_JG';
  set @TARGET_SCHEMA='DBA';
  set @TARGET_TABLE='T_DDW_D_JG';
  set @ERR_MSG='';
  set @TX_DATE=LOAD_DT;
  --删除表数据
  set @ERR_SQL='DELETE FROM T_DDW_D_JG';
  delete from T_DDW_D_JG;
  --获取今日数据
  set @ERR_SQL='INSERT INTO T_DDW_D_JG';
  insert into T_DDW_D_JG( jgbh,
    jgmc,
    jglx,
    sjjgbh,
    hsjgbh) 
    select org_cd,
      org_name,
      org_type_cd,
      up_org_cd,
      hens_org_cd from
      T_EDW_T03_ORGANIZATION;
  select max(nian) into i_nian from DBA.T_DDW_A_XXB_M;
  select max(yue) into i_yue from DBA.T_DDW_A_XXB_M where nian = i_nian;
  update DBA.T_DDW_A_XXB_M set yybjc = '要安排开通' where
    yybjc is null and nian = i_nian and yue = i_yue;
  update dba.T_DDW_D_JG as a set yybjc = b.yybjc from
    dba.T_DDW_D_JG as a,DBA.T_DDW_A_XXB_M as b where
    a.jgbh = b.jgbh and b.yybjc is not null and
    b.nian = i_nian and b.yue = i_yue;
    
    /*
  -- 更新名称
  update dba.t_ddw_d_jg as t1 set
    jgmc = COALESCE(t2.branch_name,t1.jgmc) from
    dba.t_ddw_d_jg as t1 left outer join
    dba.t_dim_org as t2 on t1.jgbh = t2.pk_org;
    */
    
    -- 更新名称
    update dba.t_ddw_d_jg
       set jgmc = COALESCE(t2.jgmc, t1.jgmc)
      from dba.t_ddw_d_jg t1
      left join dba.yybdz t2 on t1.jgbh = t2.jgbh;
    
  insert into dba.t_ddw_d_jg( jgbh,jgmc,jglx,sjjgbh,hsjgbh,yybjc) 
    /*
    select '#990299999','泉州分公司本部','1','#000000001','',''
    -- union all 
    -- select '#990399999','北京分公司本部','1','#000000001','',''
    union all 
    select '#9904','华中分公司本部','1','#000000001','',''
    */
    select pk_org,hr_name,'1','#000000001','','' from dba.t_dim_org where branch_type = '分公司' and branch_no is null 
    union all
    select '#999999995','总部','0','#000000001','','' 
    union all
    select '#CFZX','财富中心','0','#000000001','','';

  --更新T_DDW_A_XXB_M_model 表，若此表中的机构编号在旧数据中不存在，那插入当前日期的数据
  insert into DBA.T_DDW_A_XXB_M_model( load_dt,nian,ji,yue,jgbh,g6,UPID,yybjc,username) 
    select 20130807,'2013','03','07',jgbh,'2013-08-07','00001030',jgmc,jgmc from dba.T_DDW_D_JG where
      not jgbh = any(select jgbh from DBA.T_DDW_A_XXB_M_model) and jglx = '1';

  --更新T_DDW_A_XXB_M_model
  insert into DBA.T_DDW_A_XXB_M_model( load_dt,
    nian,ji,yue,jgbh,b3,c3,e3,b4,c4,e4,b5,c5,e5,b6,c6,e6,b7,c7,e7,b8,c8,e8,b9,c9,e9,b10,c10,e10,b11,c11,e11,b12,c12,e12,b13,c13,e13,b14,c14,e14,b16,e16,b17,e17,b18,e18,b19,e19,b20,e20,b21,e21,b22,e22,b23,e23,b24,c24,e24,b25,c25,e25,b26,c26,e26,b28,c28,e28,b29,c29,e29,b30,c30,e30,b31,c31,e31,b32,c32,e32,b33,c33,e33,b34,c34,e34,b35,c35,e35,b36,c36,e36,b37,c37,e37,b38,c38,e38,b40,c40,e40,b41,c41,e41,b42,c42,e42,b43,
    e43) 
    select load_dt,nian,ji,yue,a.jgbh,b3,c3,e3,b4,c4,e4,b5,c5,e5,b6,c6,e6,b7,c7,e7,b8,c8,e8,b9,c9,e9,b10,c10,e10,b11,c11,e11,b12,c12,e12,b13,c13,e13,b14,c14,e14,b16,e16,b17,e17,b18,e18,b19,e19,b20,e20,b21,e21,b22,e22,b23,e23,b24,c24,e24,b25,c25,e25,b26,c26,e26,b28,c28,e28,b29,c29,e29,b30,c30,e30,b31,c31,e31,b32,c32,e32,b33,c33,e33,b34,c34,e34,b35,c35,e35,b36,c36,e36,b37,c37,e37,b38,c38,e38,b40,c40,e40,b41,c41,e41,b42,c42,e42,b43,e43 from
      dba.T_DDW_D_JG as a left outer join
      (select load_dt,nian,ji,yue,jgbh,b3,c3,e3,b4,c4,e4,b5,c5,e5,b6,c6,e6,b7,c7,e7,b8,c8,e8,b9,c9,e9,b10,c10,e10,b11,c11,e11,b12,c12,e12,b13,c13,e13,b14,c14,e14,b16,e16,b17,e17,b18,e18,b19,e19,b20,e20,b21,e21,b22,e22,b23,e23,b24,c24,e24,b25,c25,e25,b26,c26,e26,b28,c28,e28,b29,c29,e29,b30,c30,e30,b31,c31,e31,b32,c32,e32,b33,c33,e33,b34,c34,e34,b35,c35,e35,b36,c36,e36,b37,c37,e37,b38,c38,e38,b40,c40,e40,b41,c41,e41,b42,c42,e42,b43,e43 from
        DBA.T_DDW_A0_M_MODEL where jgbh = 'XYZZWP0930') as b on
      1 = 1 where
      not a.jgbh = any(select jgbh from DBA.T_DDW_A0_M_MODEL) and jglx = '1';

  --更新YYBDZ update yybdz.jgqc , zhangqit, 20170105
  update dba.yybdz as a set
    jgqc = b.branch_name from
    dba.yybdz as a left outer join
    dba.T_ODS_HS08_ALLBRANCH as b on a.jgbh_hs = convert(varchar,b.branch_no) where
    b.branch_name is not null;

    insert into dba.t_ddw_d_jg(jgbh,jgmc,jglx,sjjgbh,yybjc)
    select pk_org as jgbh,
        hr_name as jgmc,
        '1' as jglx,
        '#XYSYYB002' as sjjgbh,
        branch_name as yybjc
    from dba.t_dim_org where branch_type in ('分公司','营业部') and is_zssyb='N'
    and pk_org not in (select jgbh from dba.t_ddw_d_jg);

    update dba.t_ddw_d_jg set jgmc = b.hr_name
    from dba.t_ddw_d_jg a
    left join dba.t_dim_org b on a.jgbh=b.pk_org
    where trim(coalesce(a.jgmc,''))='' and b.hr_name is not null;

    commit;

end
GO
