
CREATE PROCEDURE DBA.P_EDW_T03_ORGANIZATION(in LOAD_DT varchar(10),out RUNSTATUS integer,inout MSG varchar(4000))
on exception resume
begin
  --定义存储过程信息
  declare @PROC_NAME varchar(50);
  declare @TARGET_SCHEMA varchar(10);
  declare @TARGET_TABLE varchar(20);
  declare @ERR_SQL varchar(200);
  declare @TX_DATE numeric(8);
  --定义错误代码，错误状态
  declare @ERR_MSG varchar(100);
  declare not_found exception for sqlstate value '02000';
  declare @temp_sql varchar(2000);
  declare @T_NAME varchar(20);
  declare @I integer;
  set @PROC_NAME='P_EDW_T03_ORGANIZATION';
  set @TARGET_SCHEMA='DBA';
  set @TARGET_TABLE='T_EDW_T03_ORGANIZATION';
  set @ERR_MSG='';
  set @TX_DATE=LOAD_DT;
  --删除目标表中的数据
  set @ERR_SQL='DELETE FROM T_EDW_T03_ORGANIZATION';
  delete from T_EDW_T03_ORGANIZATION;
  --获取今日数据
  set @ERR_SQL='INSERT INTO T_EDW_T03_ORGANIZATION';
  insert into T_EDW_T03_ORGANIZATION( org_cd,
    org_name,
    org_full_name,
    org_type_cd,
    org_prop_cd,
    up_org_cd,
    org_leve_cd,
    open_dt,
    end_dt,
    org_id,
    org_status_cd,
    org_addr,
    tel,
    cont_name,
    post_zip,
    email) 
    select COALESCE(a.DEP_CODE,''),
      COALESCE(a.DEP_NAME,''),
      COALESCE(a.DEP_FULL_NAME,''),
      /*
      ,CASE 
      WHEN DEP_CODE IN ('#000000001','#999999999') THEN '0'
      WHEN DEP_FULL_NAME LIKE '%营业部%' THEN '1'
      WHEN DEP_CODE LIKE 'XYXZBM%' and dep_code <> 'XYXZBM0034' then '1'
      WHEN DEP_FULL_NAME LIKE '%服务部%' THEN '2'
      ELSE ''
      END
      */
      case when a.dep_code = 'XYXZBM0186' then '1'
      when b.branch_type in( '分公司','营业部') then '1'
      when b.branch_type = '总部' then '0' else ''
      end,COALESCE(a.DEP_PROP,''),
      COALESCE(a.PARENT_DEP,''),
      COALESCE(a.DEP_LEVEL,''),
      0,
      0,
      COALESCE(convert(char(10),a.DEP_CODE_ID),''),'0',
      COALESCE(a.ADDR,''),
      COALESCE(a.TEL,''),
      COALESCE(a.LINKMAN,''),
      COALESCE(a.POST,''),
      COALESCE(a.EMAIL,'') from
      T_ODS_D_DEP_INFO as a left outer join
      dba.t_dim_org as b on a.dep_code = b.pk_org;
  update t_edw_etl_status set flag = '0',update_time = current timestamp where proc_name = @PROC_NAME;
  commit work;
  return
exception
  when others then --自定义异常处理
    set @ERR_MSG='系统错误：SQLCODE=' || sqlcode || ',SQLSTATE=' || sqlstate || '';
    begin
      rollback work;
      insert into T_EDW_ERROR_MESSAGES( ERR_DATE,PROC_NAME,TARGET_SCHEMA,TARGET_TABLE,ERR_MSG,ERR_SQL) values( current timestamp,@PROC_NAME,@TARGET_SCHEMA,@TARGET_TABLE,@ERR_MSG,@ERR_SQL) ;
      update t_edw_etl_status set flag = '1',update_time = current timestamp where proc_name = @PROC_NAME;
      set RUNSTATUS=1;
      set MSG='PROGRAMMING ERROR HAPPENED';
      commit work;
      return
    end
end
GO
