CREATE OR REPLACE PROCEDURE dm.P_AST_EMPCUS_STKPLG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户股票质押月表
  编写者: DCY
  创建日期: 2018-02-05
  简介：员工客户股票质押月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

   --PART0 删除当月数据
    DELETE FROM DM.T_AST_EMPCUS_STKPLG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
   ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
	select @V_BIN_YEAR 	as year,
		   @V_BIN_MTH  	as mth,
		   RQ   		AS OCCUR_DT,
		   jgbh_hs 		as HS_ORG_ID,
		   khbh_hs 		as HS_CUST_ID,
		   zjzh    		AS CPTL_ACCT,
		   ygh     		AS FST_EMPID_BROK_ID,
		   afatwo_ygh 	as AFA_SEC_EMPID,
		   jgbh_kh 		as WH_ORG_ID_CUST,
		   jgbh_yg      as WH_ORG_ID_EMP,
		   rylx         AS PRSN_TYPE,
		   max(bz) as MEMO,
		   max(ygxm) as EMP_NAME,
		   sum(jxbl1) as PERFM_RATI1,
		   sum(jxbl2) as PERFM_RATI2,
		   sum(jxbl3) as PERFM_RATI3,
		   sum(jxbl4) as PERFM_RATI4,
		   sum(jxbl5) as PERFM_RATI5,
		   sum(jxbl6) as PERFM_RATI6,
		   sum(jxbl7) as PERFM_RATI7,
		   sum(jxbl8) as PERFM_RATI8,
		   sum(jxbl9) as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE ;

	 
	--每日员工信息表
	select a.dt AS OCCUR_DT,a.year,a.mth,pk_org as  WH_ORG_NO,afatwo_ygh AS AFA_SEC_EMPID,rylx,hrid,ygh,ygxm,ygzt,is_virtual,jgbh_hs,lzrq
	into #T_PTY_PERSON_M
	from  dm.T_PUB_DATE a
	left join dba.t_edw_person_d  b on b.rq=case when a.dt<=20171031 then a.nxt_trd_day else a.dt end  
	where a.dt=@V_BIN_DATE;	 
	
	
	 --生成每日客户汇总
  SELECT  
     OUC.CLIENT_ID 	AS CUST_ID  --客户编码
	,@V_BIN_YEAR           	AS YEAR      --年
	,@V_BIN_MTH           	AS MTH       --月
	,@V_BIN_DATE            AS OCCUR_DT  --业务日期
	,OUF.FUND_ACCOUNT  		AS MAIN_CPTL_ACCT     --主资金账号（普通账户）
	,DOH.PK_ORG 	 		AS WH_ORG_ID          --仓库机构编码 
	,CONVERT(VARCHAR,OUC.BRANCH_NO) AS HS_ORG_ID  --恒生机构编码
    ,OUF.OPEN_DATE 					AS TE_OACT_DT   --最早开户日期
	
	INTO #T_PUB_CUST
	
	FROM DBA.T_EDW_UF2_CLIENT  			OUC   --所有客户信息
    LEFT JOIN DBA.T_edw_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID AND OUF.LOAD_DT=OUC.LOAD_dT AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --普通账户主资金账号
	LEFT JOIN DBA.T_DIM_ORG_HIS  		DOH ON CONVERT(VARCHAR,OUC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=OUC.LOAD_dT AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL    --有重复值
	WHERE OUC.BRANCH_NO NOT IN (5,55,51,44,9999)--20180207 新增：排除"总部专用账户"
      AND OUC.LOAD_DT=@V_BIN_DATE;
		 
	

	INSERT INTO DM.T_AST_EMPCUS_STKPLG_M_D 
	(
	   YEAR                 		  --年
	  ,MTH                  		  --月
	  ,OCCUR_DT                       --业务日期
	  ,CUST_ID              		  --客户编码
	  ,AFA_SEC_EMPID        		  --AFA_二期员工号
	  ,CTR_NO               		  --合同编号
	  ,YEAR_MTH             		  --年月
	  ,YEAR_MTH_CUST_ID     		  --年月客户编码
	  ,YEAR_MTH_PSN_JNO     		  --年月员工号
	  ,WH_ORG_ID_CUST       		  --仓库机构编码_客户
	  ,WH_ORG_ID_EMP        		  --仓库机构编码_员工
	  ,GUAR_SECU_MVAL_FINAL 		  --担保证券市值_期末
	  ,STKPLG_FIN_BAL_FINAL 		  --股票质押融资余额_期末
	  ,SH_GUAR_SECU_MVAL_FINAL 	      --上海担保证券市值_期末
	  ,SZ_GUAR_SECU_MVAL_FINAL 	      --深圳担保证券市值_期末
	  ,SH_NOTS_GUAR_SECU_MVAL_FINAL   --上海限售股担保证券市值_期末
	  ,SZ_NOTS_GUAR_SECU_MVAL_FINAL   --深圳限售股担保证券市值_期末
	  ,PROP_FINAC_OUT_SIDE_BAL_FINAL  --自营融出方余额_期末
	  ,ASSM_FINAC_OUT_SIDE_BAL_FINAL  --资管融出方余额_期末
	  ,SM_LOAN_FINAC_OUT_BAL_FINAL    --小额贷融出余额_期末
	  ,GUAR_SECU_MVAL_MDA             --担保证券市值_月日均
	  ,STKPLG_FIN_BAL_MDA             --股票质押融资余额_月日均
	  ,SH_GUAR_SECU_MVAL_MDA          --上海担保证券市值_月日均
	  ,SZ_GUAR_SECU_MVAL_MDA          --深圳担保证券市值_月日均
	  ,SH_NOTS_GUAR_SECU_MVAL_MDA     --上海限售股担保证券市值_月日均
	  ,SZ_NOTS_GUAR_SECU_MVAL_MDA     --深圳限售股担保证券市值_月日均
	  ,PROP_FINAC_OUT_SIDE_BAL_MDA    --自营融出方余额_月日均
	  ,ASSM_FINAC_OUT_SIDE_BAL_MDA    --资管融出方余额_月日均
	  ,SM_LOAN_FINAC_OUT_BAL_MDA      --小额贷融出余额_月日均
	  ,GUAR_SECU_MVAL_YDA             --担保证券市值_年日均
	  ,STKPLG_FIN_BAL_YDA             --股票质押融资余额_年日均
	  ,SH_GUAR_SECU_MVAL_YDA          --上海担保证券市值_年日均
	  ,SZ_GUAR_SECU_MVAL_YDA          --深圳担保证券市值_年日均
	  ,SH_NOTS_GUAR_SECU_MVAL_YDA     --上海限售股担保证券市值_年日均
	  ,SZ_NOTS_GUAR_SECU_MVAL_YDA     --深圳限售股担保证券市值_年日均
	  ,PROP_FINAC_OUT_SIDE_BAL_YDA    --自营融出方余额_年日均
	  ,ASSM_FINAC_OUT_SIDE_BAL_YDA    --资管融出方余额_年日均
	  ,SM_LOAN_FINAC_OUT_BAL_YDA      --小额贷融出余额_年日均
	  ,LOAD_DT                        --清洗日期
	)
	select
	t1.YEAR as 年
	,t1.MTH as 月
	,T1.OCCUR_DT
	,t1.CUST_ID as 客户编码
	,t1.AFA_SEC_EMPID as AFA二期员工号
	,t1.CTR_NO as 合同编号
	,t1.YEAR||t1.MTH as 年月
	,t1.YEAR||t1.MTH||t1.CUST_ID as 年月客户编码
	,t_kh.WH_ORG_ID as 仓库机构编码_客户
	,t_yg.WH_ORG_NO as 仓库机构编码_员工
	,t1.YEAR||t1.MTH||t1.AFA_SEC_EMPID as 年月员工号
	,sum(COALESCE(t1.担保证券市值_期末,0)) as 担保证券市值_期末
	,sum(COALESCE(t1.股票质押融资余额_期末,0)) as 股票质押融资余额_期末
	,sum(COALESCE(t1.上海担保证券市值_期末,0)) as 上海担保证券市值_期末
	,sum(COALESCE(t1.深圳担保证券市值_期末,0)) as 深圳担保证券市值_期末
	,sum(COALESCE(t1.上海限售股担保证券市值_期末,0)) as 上海限售股担保证券市值_期末
	,sum(COALESCE(t1.深圳限售股担保证券市值_期末,0)) as 深圳限售股担保证券市值_期末
	,sum(COALESCE(t1.自营融出方余额_期末,0)) as 自营融出方余额_期末
	,sum(COALESCE(t1.资管融出方余额_期末,0)) as 资管融出方余额_期末
	,sum(COALESCE(t1.小额贷融出余额_期末,0)) as 小额贷融出余额_期末
	
	,sum(COALESCE(t1.担保证券市值_月日均,0)) as 担保证券市值_月日均
	,sum(COALESCE(t1.股票质押融资余额_月日均,0)) as 股票质押融资余额_月日均
	,sum(COALESCE(t1.上海担保证券市值_月日均,0)) as 上海担保证券市值_月日均
	,sum(COALESCE(t1.深圳担保证券市值_月日均,0)) as 深圳担保证券市值_月日均
	,sum(COALESCE(t1.上海限售股担保证券市值_月日均,0)) as 上海限售股担保证券市值_月日均
	,sum(COALESCE(t1.深圳限售股担保证券市值_月日均,0)) as 深圳限售股担保证券市值_月日均
	,sum(COALESCE(t1.自营融出方余额_月日均,0)) as 自营融出方余额_月日均
	,sum(COALESCE(t1.资管融出方余额_月日均,0)) as 资管融出方余额_月日均
	,sum(COALESCE(t1.小额贷融出余额_月日均,0)) as 小额贷融出余额_月日均
	
	,sum(COALESCE(t1.担保证券市值_年日均,0)) as 担保证券市值_年日均
	,sum(COALESCE(t1.股票质押融资余额_年日均,0)) as 股票质押融资余额_年日均
	,sum(COALESCE(t1.上海担保证券市值_年日均,0)) as 上海担保证券市值_年日均
	,sum(COALESCE(t1.深圳担保证券市值_年日均,0)) as 深圳担保证券市值_年日均
	,sum(COALESCE(t1.上海限售股担保证券市值_年日均,0)) as 上海限售股担保证券市值_年日均
	,sum(COALESCE(t1.深圳限售股担保证券市值_年日均,0)) as 深圳限售股担保证券市值_年日均
	,sum(COALESCE(t1.自营融出方余额_年日均,0)) as 自营融出方余额_年日均
	,sum(COALESCE(t1.资管融出方余额_年日均,0)) as 资管融出方余额_年日均
	,sum(COALESCE(t1.小额贷融出余额_年日均,0)) as 小额贷融出余额_年日均
	,@V_BIN_DATE                       --清洗日期
	from
	(
	select 
		t1.YEAR
		,t1.MTH	
        ,T1.OCCUR_DT		
		,t1.CUST_ID		
		,t1.CTR_NO
		,t2.AFA_SEC_EMPID		
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_FINAL,0) as 担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_FINAL,0) as 股票质押融资余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0) as 上海担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0) as 深圳担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0) as 上海限售股担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0) as 深圳限售股担保证券市值_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0) as 自营融出方余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0) as 资管融出方余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0) as 小额贷融出余额_期末
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_MDA,0) as 担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_MDA,0) as 股票质押融资余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0) as 上海担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0) as 深圳担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0) as 上海限售股担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0) as 深圳限售股担保证券市值_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0) as 自营融出方余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0) as 资管融出方余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0) as 小额贷融出余额_月日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_YDA,0) as 担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_YDA,0) as 股票质押融资余额_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0) as 上海担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0) as 深圳担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0) as 上海限售股担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0) as 深圳限售股担保证券市值_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0) as 自营融出方余额_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0) as 资管融出方余额_年日均
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0) as 小额贷融出余额_年日均
	 from DM.T_AST_STKPLG_M_D t1
	 left join
		 (
			select 	a.nianyue 	as YEAR_MTH
					,b. occur_dt 
					,case when b.AFA_SEC_EMPID is null then a.afatwo_ygh else b.AFA_SEC_EMPID end as AFA_SEC_EMPID
					,cntr_id    AS  CTR_NO
					,a.jxbl     as RIGHT_RATI
			from dba.t_gzhs_zq             a
			left join #T_PTY_PERSON_M      b on a.hrid=b.hrid and b.year||b.mth=a.nianyue
			WHERE A.NIANYUE=(SELECT MAX(NIANYUE) FROM dba.t_gzhs_zq  WHERE NIANYUE <=@V_BIN_YEAR||@V_BIN_MTH)
		) t2 on t1.OCCUR_DT=T2.OCCUR_DT and t1.CTR_NO=t2.CTR_NO
	 WHERE t1.YEAR_MTH=SUBSTR(@V_BIN_DATE||'',1,6) and t2.CTR_NO is not null	 
	 
	 union all
	 select 
		t1.YEAR
		,t1.MTH		
		,T1.OCCUR_DT
		,t1.CUST_ID		
		,t1.CTR_NO
		,t2.AFA_SEC_EMPID		
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_FINAL,0) as 担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_FINAL,0) as 股票质押融资余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0) as 上海担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0) as 深圳担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0) as 上海限售股担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0) as 深圳限售股担保证券市值_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0) as 自营融出方余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0) as 资管融出方余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0) as 小额贷融出余额_期末
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_MDA,0) as 担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_MDA,0) as 股票质押融资余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0) as 上海担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0) as 深圳担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0) as 上海限售股担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0) as 深圳限售股担保证券市值_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0) as 自营融出方余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0) as 资管融出方余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0) as 小额贷融出余额_月日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_YDA,0) as 担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_YDA,0) as 股票质押融资余额_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0) as 上海担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0) as 深圳担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0) as 上海限售股担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0) as 深圳限售股担保证券市值_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0) as 自营融出方余额_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0) as 资管融出方余额_年日均
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0) as 小额贷融出余额_年日均
	  from DM.T_AST_STKPLG_M_D                     t1
	  left join (select t1.nianyue AS YEAR_MTH, t1.cntr_id AS  CTR_NO
				   from dba.t_gzhs_zq              t1
				   WHERE NIANYUE=(SELECT MAX(NIANYUE) FROM dba.t_gzhs_zq  WHERE NIANYUE <=@V_BIN_YEAR||@V_BIN_MTH)
				  group by t1.nianyue, t1.cntr_id) t_htzq on t1.YEAR||T1.MTH = t_htzq.YEAR_MTH and t1.CTR_NO = t_htzq.CTR_NO
	  left join  #T_PUB_SER_RELA                   t2    on t1.YEAR = t2.YEAR             and t1.MTH = t2.MTH and t1.CUST_ID = t2.HS_CUST_ID
	 WHERE t1.OCCUR_DT=@V_BIN_DATE 
	   and t_htzq.CTR_NO is null
	   
	   )       t1
	   
	  left join #T_PTY_PERSON_M   t_yg on t1.OCCUR_DT=T_YG.OCCUR_DT  and t1.AFA_SEC_EMPID = t_yg.AFA_SEC_EMPID
	  left join #T_PUB_CUST       t_kh on t1.OCCUR_DT= t_kh.OCCUR_DT and t1.CUST_ID = t_kh.CUST_ID
	  WHERE AFA二期员工号 IS NOT NULL
group by
	t1.YEAR
	,t1.MTH
	,T1.OCCUR_DT
	,t1.CUST_ID	
	,t1.CTR_NO 
	,t1.YEAR||t1.MTH
	,t1.AFA_SEC_EMPID
	,t_kh.WH_ORG_ID
	,t_yg.WH_ORG_NO
;		
END