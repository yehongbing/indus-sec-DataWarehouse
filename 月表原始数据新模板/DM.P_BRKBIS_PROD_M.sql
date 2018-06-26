create PROCEDURE DM.P_BRKBIS_PROD_M(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  程序功能: 经纪业务产品月报
  编写者: LIZM
  创建日期: 2018-05-25
  简介：经纪业务产品月报表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

    DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
    DECLARE @V_YEAR_MONTH VARCHAR(6);	-- 年月份
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_YEAR_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4) + SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

    --PART0 删除当月数据
    DELETE FROM DM.T_BRKBIS_PROD_M WHERE YEAR_MTH=@V_YEAR_MONTH;

    insert into DM.T_BRKBIS_PROD_M
    (
    YEAR_MTH             
    ,ORG_NO               
    ,BRH                  
    ,SEPT_CORP            
    ,SEPT_CORP_TYPE       
    ,IF_YEAR_NA           
    ,IF_MTH_NA            
    ,ACC_CHAR             
    ,IF_SPCA_ACC          
    ,AST_SGMTS            
  	,IF_PROD_NEW_CUST     
    ,PROD_TYPE            
    ,PAYF_FETUR_TYPE      
    ,IF_KEY_PROD  
    ,ITC_RETAIN_AMT_FINAL 
    ,ITC_RETAIN_AMT_MDA   
    ,ITC_RETAIN_AMT_YDA           
    ,OTC_RETAIN_AMT_FINAL 
    ,OTC_RETAIN_AMT_MDA   
    ,OTC_RETAIN_AMT_YDA   
    ,PROD_SALE_AMT_MTD    
    ,TF_PROD_SALE_AMT_MTD 
    ,ITC_SUBS_AMT_MTD     
    ,OTC_SUBS_AMT_MTD     
    ,OTC_PURS_AMT_MTD     
    ,OTC_CASTSL_AMT_MTD   
    ,OTC_COVT_IN_AMT_MTD  
    ,SFT_CSTD_IN_AMT_MTD  
    ,CONTD_SALE_AMT_MTD   
    ,PROD_REDP_AMT_MTD    
    ,OTC_REDP_AMT_MTD     
    ,OTC_COVT_OUT_AMT_MTD 
    ,SFT_CSTD_OUT_AMT_MTD 
    ,PROD_SALE_AMT_YTD    
    ,TF_PROD_SALE_AMT_YTD 
    ,ITC_SUBS_AMT_YTD     
    ,OTC_SUBS_AMT_YTD     
    ,OTC_PURS_AMT_YTD     
    ,OTC_CASTSL_AMT_YTD   
    ,OTC_COVT_IN_AMT_YTD  
    ,SFT_CSTD_IN_AMT_YTD  
    ,CONTD_SALE_AMT_YTD   
    ,PROD_REDP_AMT_YTD    
    ,OTC_REDP_AMT_YTD     
    ,OTC_COVT_OUT_AMT_YTD 
    ,SFT_CSTD_OUT_AMT_YTD 
    ,PROD_SALE_CHAG_MTD   
    ,ITC_SUBS_CHAG_MTD    
    ,OTC_SUBS_CHAG_MTD    
    ,OTC_PURS_CHAG_MTD    
    ,OTC_CASTSL_CHAG_MTD  
    ,OTC_COVT_IN_CHAG_MTD 
    ,SFT_CSTD_IN_CHAG_MTD 
    ,PROD_REDP_CHAG_MTD   
    ,OTC_REDP_CHAG_MTD    
    ,OTC_COVT_OUT_CHAG_MTD 
    ,SFT_CSTD_OUT_CHAG_MTD 
    ,PROD_SALE_CHAG_YTD   
    ,ITC_SUBS_CHAG_YTD    
    ,OTC_SUBS_CHAG_YTD    
    ,OTC_PURS_CHAG_YTD    
    ,OTC_CASTSL_CHAG_YTD  
    ,OTC_COVT_IN_CHAG_YTD 
    ,SFT_CSTD_IN_CHAG_YTD 
    ,PROD_REDP_CHAG_YTD   
    ,OTC_REDP_CHAG_YTD    
    ,OTC_COVT_OUT_CHAG_YTD 
    ,SFT_CSTD_OUT_CHAG_YTD
     
    )
	select 
        t1.YEAR_MTH as 年月
        ,t_jg.WH_ORG_ID as 机构编号
        ,t_jg.HR_ORG_NAME as 营业部
        ,t_jg.HR_ORG_NAME as 分公司
        ,t_jg.ORG_TYPE as 分公司类型 
        ,t_khsx.是否月新增
        ,t_khsx.是否月新增
        ,t_khsx.账户性质
        ,t_khsx.是否特殊账户
        ,t_khsx.资产段
        ,t_khsx.是否产品新客户
        ,case when t_cp.PROD_TYPE  is null then '' else t_cp.PROD_TYPE end  as 产品类型
        ,case when t_cp.PROD_PAYF_FETUR  is null then '' else t_cp.PROD_PAYF_FETUR end  as 收益特征类型
        ,convert(varchar(20),COALESCE(t_cp.IF_KEY_PROD,0)) as 是否重点产品
        ,sum(COALESCE(t1.ITC_RETAIN_AMT_FINAL,0)) as 场内保有金额_期末
        ,sum(COALESCE(t1.ITC_RETAIN_AMT_MDA,0)) as 场内保有金额_月日均
        ,sum(COALESCE(t1.ITC_RETAIN_AMT_YDA,0)) as 场内保有金额_年日均
        ,sum(COALESCE(t1.OTC_RETAIN_AMT_FINAL,0)) as 场外保有金额_期末
        ,sum(COALESCE(t1.OTC_RETAIN_AMT_MDA,0)) as 场外保有金额_月日均
        ,sum(COALESCE(t1.OTC_RETAIN_AMT_YDA,0)) as 场外保有金额_年日均
        --销售金额：场内认购金额、场内认购手续费、场外认购金额、场外申购金额、场外定投金额、场外转换入金额、续作销售金额、转托管入金额
        ,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)	--场内认购金额_月累计
            +COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--场内认购手续费_月累计
            +COALESCE(t1.OTC_SUBS_AMT_MTD,0)	--场外认购金额_月累计
            +COALESCE(t1.OTC_PURS_AMT_MTD,0)	--场外申购金额_月累计
            +COALESCE(t1.OTC_CASTSL_AMT_MTD,0)	--场外定投金额_月累计		
            +COALESCE(t1.OTC_COVT_IN_AMT_MTD,0)	--场外转换入金额_月累计
            +COALESCE(t1.CONTD_SALE_AMT_MTD,0)	--续作销售金额_月累计				
            ) as 产品销售金额_月累计
        --首发销售金额：场内认购金额、场内认购手续费、场外认购金额
        ,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)	--场内认购金额_月累计		
            +COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--场内认购手续费_月累计
            +COALESCE(t1.OTC_SUBS_AMT_MTD,0)	--场外认购金额_月累计		
            ) as 首发产品销售金额_月累计
        ,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)) as 场内认购金额_月累计
        ,sum(COALESCE(t1.OTC_SUBS_AMT_MTD,0)) as 场外认购金额_月累计
        ,sum(COALESCE(t1.OTC_PURS_AMT_MTD,0)) as 场外申购金额_月累计
        ,sum(COALESCE(t1.OTC_CASTSL_AMT_MTD,0)) as 场外定投金额_月累计
        ,sum(COALESCE(t1.OTC_COVT_IN_AMT_MTD,0)) as 场外转换入金额_月累计
        ,sum(COALESCE(t_jjzb.ZTGRQRJE_M,0)) as 转托管入金额_月累计
        ,sum(COALESCE(t1.CONTD_SALE_AMT_MTD,0)) as 续作销售金额_月累计
        --赎回金额：场外赎回金额、场外转换出金额、转托管出金额
        ,sum(COALESCE(t1.OTC_REDP_AMT_MTD,0)		--场外赎回金额_月累计		
            +COALESCE(t1.OTC_COVT_OUT_AMT_MTD,0)--场外转换出金额_月累计	
            ) as 产品赎回金额_月累计
        ,sum(COALESCE(t1.OTC_REDP_AMT_MTD,0)) as 场外赎回金额_月累计
        ,sum(COALESCE(t1.OTC_COVT_OUT_AMT_MTD,0)) as 场外转换出金额_月累计
        ,sum(COALESCE(t_jjzb.ZTGCQRJE_M,0)) as 转托管出金额_月累计
        --销售金额：场内认购金额、场内认购手续费、场外认购金额、场外申购金额、场外定投金额、场外转换入金额、续作销售金额、转托管入金额
        ,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)	--场内认购金额_年累计		
            +COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--场内认购手续费_年累计
            +COALESCE(t1.OTC_SUBS_AMT_YTD,0)	--场外认购金额_年累计
            +COALESCE(t1.OTC_PURS_AMT_YTD,0)	--场外申购金额_年累计
            +COALESCE(t1.OTC_CASTSL_AMT_YTD,0)	--场外定投金额_年累计		
            +COALESCE(t1.OTC_COVT_IN_AMT_YTD,0)	--场外转换入金额_年累计
            +COALESCE(t1.CONTD_SALE_AMT_YTD,0)	--续作销售金额_年累计	
            ) as 产品销售金额_年累计
        --首发销售金额：场内认购金额、场内认购手续费、场外认购金额
        ,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)	--场内认购金额_年累计	
            +COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--场内认购手续费_年累计	
            +COALESCE(t1.OTC_SUBS_AMT_YTD,0)	--场外认购金额_年累计		
            ) as 首发产品销售金额_年累计
        ,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)) as 场内认购金额_年累计
        ,sum(COALESCE(t1.OTC_SUBS_AMT_YTD,0)) as 场外认购金额_年累计
        ,sum(COALESCE(t1.OTC_PURS_AMT_YTD,0)) as 场外申购金额_年累计
        ,sum(COALESCE(t1.OTC_CASTSL_AMT_YTD,0)) as 场外定投金额_年累计
        ,sum(COALESCE(t1.OTC_COVT_IN_AMT_YTD,0)) as 场外转换入金额_年累计
        ,sum(COALESCE(t_jjzb.ZTGRQRJE_Y,0)) as 转托管入金额_年累计
        ,sum(COALESCE(t1.CONTD_SALE_AMT_YTD,0)) as 续作销售金额_年累计
        --赎回金额：场外赎回金额、场外转换出金额、转托管出金额
        ,sum(COALESCE(t1.OTC_REDP_AMT_YTD,0)	--场外赎回金额_年累计		
            +COALESCE(t1.OTC_COVT_OUT_AMT_YTD,0)--场外转换出金额_年累计	
            ) as 产品赎回金额_年累计
        ,sum(COALESCE(t1.OTC_REDP_AMT_YTD,0)) as 场外赎回金额_年累计
        ,sum(COALESCE(t1.OTC_COVT_OUT_AMT_YTD,0)) as 场外转换出金额_年累计
        ,sum(COALESCE(t_jjzb.ZTGCQRJE_Y,0)) as 转托管出金额_年累计
        --场内认购、场外认购、场外申购、场外定投、场外转换入、续作销售、转托管入
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--场内认购手续费_月累计		
            +COALESCE(t1.OTC_SUBS_CHAG_MTD,0)	--场外认购手续费_月累计
            +COALESCE(t1.OTC_PURS_CHAG_MTD,0)	--场外申购手续费_月累计
            +COALESCE(t1.OTC_CASTSL_CHAG_MTD,0)	--场外定投手续费_月累计
            +COALESCE(t1.OTC_COVT_IN_CHAG_MTD,0) --场外转换入手续费_月累计
            ) as 产品销售手续费_月累计 
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_MTD,0)) as 场内认购手续费_月累计
        ,sum(COALESCE(t1.OTC_SUBS_CHAG_MTD,0)) as 场外认购手续费_月累计
        ,sum(COALESCE(t1.OTC_PURS_CHAG_MTD,0)) as 场外申购手续费_月累计
        ,sum(COALESCE(t1.OTC_CASTSL_CHAG_MTD,0)) as 场外定投手续费_月累计
        ,sum(COALESCE(t1.OTC_COVT_IN_CHAG_MTD,0)) as 场外转换入手续费_月累计
        ,0 as 转托管入手续费_月累计
        --场外赎回、场外转换出、转托管出
        ,sum(COALESCE(t1.OTC_REDP_CHAG_MTD,0)	--场外赎回手续费_月累计	
			+COALESCE(t1.OTC_COVT_OUT_CHAG_MTD,0) --场外转换出手续费_月累计
            --转托管出手续费_月累计（未获取）
			) as 产品赎回手续费_月累计
        ,sum(COALESCE(t1.OTC_REDP_CHAG_MTD,0)) as 场外赎回手续费_月累计
        ,sum(COALESCE(t1.OTC_COVT_OUT_CHAG_MTD,0)) as 场外转换出手续费_月累计
        ,0 as 转托管出手续费_月累计
        --场内认购、场外认购、场外申购、场外定投、场外转换入、续作销售、转托管入
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--场内认购手续费_年累计		
			+COALESCE(t1.OTC_SUBS_CHAG_YTD,0)	--场外认购手续费_年累计
			+COALESCE(t1.OTC_PURS_CHAG_YTD,0)	--场外申购手续费_年累计
			+COALESCE(t1.OTC_CASTSL_CHAG_YTD,0)	--场外定投手续费_年累计
			+COALESCE(t1.OTC_COVT_IN_CHAG_YTD,0) --场外转换入手续费_年累计
			) as 产品销售手续费_年累计 
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_YTD,0)) as 场内认购手续费_年累计
        ,sum(COALESCE(t1.OTC_SUBS_CHAG_YTD,0)) as 场外认购手续费_年累计
        ,sum(COALESCE(t1.OTC_PURS_CHAG_YTD,0)) as 场外申购手续费_年累计 
        ,sum(COALESCE(t1.OTC_CASTSL_CHAG_YTD,0)) as 场外定投手续费_年累计
        ,sum(COALESCE(t1.OTC_COVT_IN_CHAG_YTD,0)) as 场外转换入手续费_年累计
        ,0 as 转托管入手续费_年累计
        --场外赎回、场外转换出、转托管出
        ,sum(COALESCE(t1.OTC_REDP_CHAG_YTD,0)	--场外赎回手续费_年累计
            +COALESCE(t1.OTC_COVT_OUT_CHAG_YTD,0) --场外转换出手续费_年累计
            --转托管出手续费_年累计（未获取）
            ) as 产品赎回手续费_年累计
        ,sum(COALESCE(t1.OTC_REDP_CHAG_YTD,0)) as 场外赎回手续费_年累计
        ,sum(COALESCE(t1.OTC_COVT_OUT_CHAG_YTD,0)) as 场外转换出手续费_年累计
        --场外赎回、场外转换出、转托管出
        ,0 as 转托管出手续费_年累计
	from DM.T_EVT_EMPCUS_PROD_TRD_M_D t1
    left join DM.T_PUB_ORG t_jg					--机构表
	    on t1.YEAR=t_jg.YEAR and t1.MTH=t_jg.MTH and t1.WH_ORG_ID_EMP=t_jg.WH_ORG_ID
    left join DM.T_VAR_PROD_OTC t_cp
        on t_cp.OCCUR_DT = @V_BIN_DATE and t_cp.PROD_CD = t1.PROD_CD
    left join DBA.T_DDW_XY_JJZB_M t_jjzb
        on t_jjzb.NIAN = t1.YEAR and t_jjzb.YUE = t1.MTH and t_jjzb.JJDM = t1.PROD_CD
    left join 
    (											--客户属性和维度处理
		select 
			t1.YEAR
			,t1.MTH	
			,t1.CUST_ID
			,t1.CUST_STAT as 客户状态
			,case when t1.TE_OACT_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as 是否月新增
			,case when t1.TE_OACT_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as 是否年新增
			,coalesce(t1.IF_VLD,0) as 是否有效
			,coalesce(CONVERT(VARCHAR,t4.IF_SPCA_ACCT),'0') as 是否特殊账户
			,coalesce(convert(varchar,t1.IF_PROD_NEW_CUST),'0') as 是否产品新客户
			,t1.CUST_TYPE as 客户类型
			,t1.CUST_TYPE_NAME as 账户性质
	     	,case 
            when t5.TOT_AST_MDA<100                                     then '00-100以下'
			when t5.TOT_AST_MDA >= 100      and t5.TOT_AST_MDA<1000     then '01-100_1000'
			when t5.TOT_AST_MDA >= 1000     and t5.TOT_AST_MDA<2000     then '02-1000_2000'
			when t5.TOT_AST_MDA >= 2000     and t5.TOT_AST_MDA<5000     then '03-2000_5000'
			when t5.TOT_AST_MDA >= 5000     and t5.TOT_AST_MDA<10000    then '04-5000_1w'
			when t5.TOT_AST_MDA >= 10000    and t5.TOT_AST_MDA<50000    then '05-1w_5w'
			when t5.TOT_AST_MDA >= 50000    and t5.TOT_AST_MDA<100000   then '06-5w_10w'
            when t5.TOT_AST_MDA >= 100000   and t5.TOT_AST_MDA<200000   then '1-10w_20w'
    		when t5.TOT_AST_MDA >= 200000   and t5.TOT_AST_MDA<500000   then '2-20w_50w'
    		when t5.TOT_AST_MDA >= 500000   and t5.TOT_AST_MDA<1000000  then '3-50w_100w'
    		when t5.TOT_AST_MDA >= 1000000  and t5.TOT_AST_MDA<2000000  then '4-100w_200w'
    		when t5.TOT_AST_MDA >= 2000000  and t5.TOT_AST_MDA<3000000  then '5-200w_300w'
    		when t5.TOT_AST_MDA >= 3000000  and t5.TOT_AST_MDA<5000000  then '6-300w_500w'
    		when t5.TOT_AST_MDA >= 5000000  and t5.TOT_AST_MDA<10000000 then '7-500w_1000w'
    		when t5.TOT_AST_MDA >= 10000000 and t5.TOT_AST_MDA<30000000 then '8-1000w_3000w'
			when t5.TOT_AST_MDA >= 30000000                             then '9-大于3000w'
         end as 资产段			
		 from DM.T_PUB_CUST t1	 
		 left join DM.T_PUB_DATE_M t2 on t1.YEAR=t2.YEAR and t1.MTH=t2.MTH
		 left join DM.T_PUB_CUST_LIMIT_M_D t3 on t1.YEAR=t3.YEAR and t1.MTH=t3.MTH and t1.CUST_ID=t3.CUST_ID
		 left join DM.T_ACC_CPTL_ACC t4 on t1.YEAR=t4.YEAR and t1.MTH=t4.MTH and t1.MAIN_CPTL_ACCT=t4.CPTL_ACCT
		 left join DM.T_AST_ODI_M_D t5 on t1.YEAR=t5.YEAR and t1.MTH=t5.MTH and t1.CUST_ID=t5.CUST_ID
     WHERE t1.YEAR= @V_YEAR 
        and t1.MTH= @V_MONTH 
        AND 资产段 IS NOT NULL
	) t_khsx on t1.YEAR=t_khsx.YEAR and t1.MTH=t_khsx.MTH and t1.CUST_ID=t_khsx.CUST_ID
 WHERE  t1.YEAR=@V_YEAR and t1.MTH=@V_MONTH
    and t_khsx.是否特殊账户 IS NOT NULL 
    AND t_khsx.CUST_ID IS NOT NULL
    and t1.AFA_SEC_EMPID IS NOT NULL
    AND t1.WH_ORG_ID_EMP IS NOT NULL
    AND t1.AFA_SEC_EMPID IS NOT NULL
	group by
        t1.YEAR
        ,t1.MTH 
        ,t1.YEAR_MTH
        ,t_jg.WH_ORG_ID
        ,t_jg.HR_ORG_NAME
        ,t_jg.SEPT_CORP_NAME
        ,t_jg.ORG_TYPE
        ,t_khsx.是否月新增
        ,t_khsx.是否月新增
        ,t_khsx.账户性质
        ,t_khsx.是否特殊账户
        ,t_khsx.资产段
        ,t_khsx.是否产品新客户
        ,t_cp.PROD_TYPE
        ,t_cp.PROD_PAYF_FETUR
        ,t_cp.IF_KEY_PROD
	;

END