CREATE OR REPLACE PROCEDURE DM.P_EVT_EMP_PROD_M(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工产品级别月表:带权责
  编写者: DCY
  创建日期: 2018-03-26
  简介：员工产品级别月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/

    DECLARE @V_YEAR VARCHAR(4);		-- 年份
  	DECLARE @V_MONTH VARCHAR(2);	-- 月份
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 删除当月数据
  DELETE FROM DM.T_EVT_EMP_PROD_M WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

  	insert into DM.T_EVT_EMP_PROD_M
  		(
  			 YEAR                 
			,MTH                  
			,YEAR_MTH             
			,PROD_CD              
			,PROD_TYPE            
			,WH_ORG_ID_EMP 
			,AFA_SEC_EMPID
			,IF_SPCA_ACC        
			,ITC_RETAIN_AMT_FINAL 
			,OTC_RETAIN_AMT_FINAL 
			,ITC_RETAIN_SHAR_FINAL
			,OTC_RETAIN_SHAR_FINAL
			,ITC_RETAIN_AMT_MDA   
			,OTC_RETAIN_AMT_MDA   
			,ITC_RETAIN_SHAR_MDA  
			,OTC_RETAIN_SHAR_MDA  
			,ITC_RETAIN_AMT_YDA   
			,OTC_RETAIN_AMT_YDA   
			,ITC_RETAIN_SHAR_YDA  
			,OTC_RETAIN_SHAR_YDA  
			,ITC_SUBS_AMT_MTD     
			,ITC_PURS_AMT_MTD     
			,ITC_BUYIN_AMT_MTD    
			,ITC_REDP_AMT_MTD     
			,ITC_SELL_AMT_MTD     
			,OTC_SUBS_AMT_MTD     
			,OTC_PURS_AMT_MTD     
			,OTC_CASTSL_AMT_MTD   
			,OTC_COVT_IN_AMT_MTD  
			,OTC_REDP_AMT_MTD     
			,OTC_COVT_OUT_AMT_MTD 
			,SALE_AMT_MTD         
			,TF_SALE_AMT_MTD      
			,REDP_AMT_MTD         
			,ITC_SUBS_SHAR_MTD    
			,ITC_PURS_SHAR_MTD    
			,ITC_BUYIN_SHAR_MTD   
			,ITC_REDP_SHAR_MTD    
			,ITC_SELL_SHAR_MTD    
			,OTC_SUBS_SHAR_MTD    
			,OTC_PURS_SHAR_MTD    
			,OTC_CASTSL_SHAR_MTD  
			,OTC_COVT_IN_SHAR_MTD 
			,OTC_REDP_SHAR_MTD    
			,OTC_COVT_OUT_SHAR_MTD
			,ITC_SUBS_CHAG_MTD    
			,ITC_PURS_CHAG_MTD    
			,ITC_BUYIN_CHAG_MTD   
			,ITC_REDP_CHAG_MTD    
			,ITC_SELL_CHAG_MTD    
			,OTC_SUBS_CHAG_MTD    
			,OTC_PURS_CHAG_MTD    
			,OTC_CASTSL_CHAG_MTD  
			,OTC_COVT_IN_CHAG_MTD 
			,OTC_REDP_CHAG_MTD    
			,OTC_COVT_OUT_CHAG_MTD
			,ITC_SUBS_AMT_YTD     
			,ITC_PURS_AMT_YTD     
			,ITC_BUYIN_AMT_YTD    
			,ITC_REDP_AMT_YTD     
			,ITC_SELL_AMT_YTD     
			,OTC_SUBS_AMT_YTD     
			,OTC_PURS_AMT_YTD     
			,OTC_CASTSL_AMT_YTD   
			,OTC_COVT_IN_AMT_YTD  
			,OTC_REDP_AMT_YTD     
			,OTC_COVT_OUT_AMT_YTD 
			,SALE_AMT_YTD         
			,TF_SALE_AMT_YTD      
			,REDP_AMT_YTD         
			,ITC_SUBS_SHAR_YTD    
			,ITC_PURS_SHAR_YTD    
			,ITC_BUYIN_SHAR_YTD   
			,ITC_REDP_SHAR_YTD    
			,ITC_SELL_SHAR_YTD    
			,OTC_SUBS_SHAR_YTD    
			,OTC_PURS_SHAR_YTD    
			,OTC_CASTSL_SHAR_YTD  
			,OTC_COVT_IN_SHAR_YTD 
			,OTC_REDP_SHAR_YTD    
			,OTC_COVT_OUT_SHAR_YTD
			,ITC_SUBS_CHAG_YTD    
			,ITC_PURS_CHAG_YTD    
			,ITC_BUYIN_CHAG_YTD   
			,ITC_REDP_CHAG_YTD    
			,ITC_SELL_CHAG_YTD    
			,OTC_SUBS_CHAG_YTD    
			,OTC_PURS_CHAG_YTD    
			,OTC_CASTSL_CHAG_YTD  
			,OTC_COVT_IN_CHAG_YTD 
			,OTC_REDP_CHAG_YTD    
			,OTC_COVT_OUT_CHAG_YTD
			,CONTD_SALE_SHAR_MTD  
			,CONTD_SALE_AMT_MTD   
			,CONTD_SALE_SHAR_YTD  
			,CONTD_SALE_AMT_YTD   
			,LOAD_DT              
  		)
	select 
		t1.YEAR as 年
		,t1.MTH as 月
		,t1.YEAR_MTH as 年月
		,t1.PROD_CD as 产品代码
		,t1.PROD_TYPE as 产品类型
		,t1.WH_ORG_ID_EMP as 仓库机构编码_员工
		,t1.AFA_SEC_EMPID as AFA二期员工号
		
		--维度信息
		--	,t_khsx.客户状态
		,t_khsx.是否特殊账户
	--	,t_khsx.是否产品新客户
	--	,t_khsx.是否月新增
	--	,t_khsx.是否年新增	
	--	,t_khsx.资产段
	--	,t_khsx.客户类型
		
		,sum(COALESCE(t1.ITC_RETAIN_AMT_FINAL,0)) as 场内保有金额_期末
		,sum(COALESCE(t1.OTC_RETAIN_AMT_FINAL,0)) as 场外保有金额_期末
		,sum(COALESCE(t1.ITC_RETAIN_SHAR_FINAL,0)) as 场内保有份额_期末
		,sum(COALESCE(t1.OTC_RETAIN_SHAR_FINAL,0)) as 场外保有份额_期末
		,sum(COALESCE(t1.ITC_RETAIN_AMT_MDA,0)) as 场内保有金额_月日均
		,sum(COALESCE(t1.OTC_RETAIN_AMT_MDA,0)) as 场外保有金额_月日均
		,sum(COALESCE(t1.ITC_RETAIN_SHAR_MDA,0)) as 场内保有份额_月日均
		,sum(COALESCE(t1.OTC_RETAIN_SHAR_MDA,0)) as 场外保有份额_月日均
		,sum(COALESCE(t1.ITC_RETAIN_AMT_YDA,0)) as 场内保有金额_年日均
		,sum(COALESCE(t1.OTC_RETAIN_AMT_YDA,0)) as 场外保有金额_年日均
		,sum(COALESCE(t1.ITC_RETAIN_SHAR_YDA,0)) as 场内保有份额_年日均
		,sum(COALESCE(t1.OTC_RETAIN_SHAR_YDA,0)) as 场外保有份额_年日均
		
		,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)) as 场内认购金额_月累计
		,sum(COALESCE(t1.ITC_PURS_AMT_MTD,0)) as 场内申购金额_月累计
		,sum(COALESCE(t1.ITC_BUYIN_AMT_MTD,0)) as 场内买入金额_月累计
		,sum(COALESCE(t1.ITC_REDP_AMT_MTD,0)) as 场内赎回金额_月累计
		,sum(COALESCE(t1.ITC_SELL_AMT_MTD,0)) as 场内卖出金额_月累计
		,sum(COALESCE(t1.OTC_SUBS_AMT_MTD,0)) as 场外认购金额_月累计
		,sum(COALESCE(t1.OTC_PURS_AMT_MTD,0)) as 场外申购金额_月累计
		,sum(COALESCE(t1.OTC_CASTSL_AMT_MTD,0)) as 场外定投金额_月累计
		,sum(COALESCE(t1.OTC_COVT_IN_AMT_MTD,0)) as 场外转换入金额_月累计
		,sum(COALESCE(t1.OTC_REDP_AMT_MTD,0)) as 场外赎回金额_月累计
		,sum(COALESCE(t1.OTC_COVT_OUT_AMT_MTD,0)) as 场外转换出金额_月累计
		
		--销售金额：场内认购金额、场内认购手续费、场外认购金额、场外申购金额、场外定投金额、场外转换入金额、续作销售金额、转托管入金额
		,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)	--场内认购金额_月累计
			+COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--场内认购手续费_月累计
			+COALESCE(t1.OTC_SUBS_AMT_MTD,0)	--场外认购金额_月累计
			+COALESCE(t1.OTC_PURS_AMT_MTD,0)	--场外申购金额_月累计
			+COALESCE(t1.OTC_CASTSL_AMT_MTD,0)	--场外定投金额_月累计		
			+COALESCE(t1.OTC_COVT_IN_AMT_MTD,0)	--场外转换入金额_月累计
			+COALESCE(t1.CONTD_SALE_AMT_MTD,0)	--续作销售金额_月累计				
			) as 销售金额_月累计
			
		--首发销售金额：场内认购金额、场内认购手续费、场外认购金额
		,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)	--场内认购金额_月累计		
			+COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--场内认购手续费_月累计
			+COALESCE(t1.OTC_SUBS_AMT_MTD,0)	--场外认购金额_月累计		
			) as 首发销售金额_月累计		
			
		--赎回金额：场外赎回金额、场外转换出金额、转托管出金额
		,sum(		
			COALESCE(t1.OTC_REDP_AMT_MTD,0)		--场外赎回金额_月累计		
			+COALESCE(t1.OTC_COVT_OUT_AMT_MTD,0)--场外转换出金额_月累计	
			) as 赎回金额_月累计
				
		,sum(COALESCE(t1.ITC_SUBS_SHAR_MTD,0)) as 场内认购份额_月累计
		,sum(COALESCE(t1.ITC_PURS_SHAR_MTD,0)) as 场内申购份额_月累计
		,sum(COALESCE(t1.ITC_BUYIN_SHAR_MTD,0)) as 场内买入份额_月累计
		,sum(COALESCE(t1.ITC_REDP_SHAR_MTD,0)) as 场内赎回份额_月累计
		,sum(COALESCE(t1.ITC_SELL_SHAR_MTD,0)) as 场内卖出份额_月累计
		,sum(COALESCE(t1.OTC_SUBS_SHAR_MTD,0)) as 场外认购份额_月累计
		,sum(COALESCE(t1.OTC_PURS_SHAR_MTD,0)) as 场外申购份额_月累计
		,sum(COALESCE(t1.OTC_CASTSL_SHAR_MTD,0)) as 场外定投份额_月累计
		,sum(COALESCE(t1.OTC_COVT_IN_SHAR_MTD,0)) as 场外转换入份额_月累计
		,sum(COALESCE(t1.OTC_REDP_SHAR_MTD,0)) as 场外赎回份额_月累计
		,sum(COALESCE(t1.OTC_COVT_OUT_SHAR_MTD,0)) as 场外转换出份额_月累计
		,sum(COALESCE(t1.ITC_SUBS_CHAG_MTD,0)) as 场内认购手续费_月累计
		,sum(COALESCE(t1.ITC_PURS_CHAG_MTD,0)) as 场内申购手续费_月累计
		,sum(COALESCE(t1.ITC_BUYIN_CHAG_MTD,0)) as 场内买入手续费_月累计
		,sum(COALESCE(t1.ITC_REDP_CHAG_MTD,0)) as 场内赎回手续费_月累计
		,sum(COALESCE(t1.ITC_SELL_CHAG_MTD,0)) as 场内卖出手续费_月累计
		,sum(COALESCE(t1.OTC_SUBS_CHAG_MTD,0)) as 场外认购手续费_月累计
		,sum(COALESCE(t1.OTC_PURS_CHAG_MTD,0)) as 场外申购手续费_月累计
		,sum(COALESCE(t1.OTC_CASTSL_CHAG_MTD,0)) as 场外定投手续费_月累计
		,sum(COALESCE(t1.OTC_COVT_IN_CHAG_MTD,0)) as 场外转换入手续费_月累计
		,sum(COALESCE(t1.OTC_REDP_CHAG_MTD,0)) as 场外赎回手续费_月累计
		,sum(COALESCE(t1.OTC_COVT_OUT_CHAG_MTD,0)) as 场外转换出手续费_月累计
		,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)) as 场内认购金额_年累计
		,sum(COALESCE(t1.ITC_PURS_AMT_YTD,0)) as 场内申购金额_年累计
		,sum(COALESCE(t1.ITC_BUYIN_AMT_YTD,0)) as 场内买入金额_年累计
		,sum(COALESCE(t1.ITC_REDP_AMT_YTD,0)) as 场内赎回金额_年累计
		,sum(COALESCE(t1.ITC_SELL_AMT_YTD,0)) as 场内卖出金额_年累计
		,sum(COALESCE(t1.OTC_SUBS_AMT_YTD,0)) as 场外认购金额_年累计
		,sum(COALESCE(t1.OTC_PURS_AMT_YTD,0)) as 场外申购金额_年累计
		,sum(COALESCE(t1.OTC_CASTSL_AMT_YTD,0)) as 场外定投金额_年累计
		,sum(COALESCE(t1.OTC_COVT_IN_AMT_YTD,0)) as 场外转换入金额_年累计
		,sum(COALESCE(t1.OTC_REDP_AMT_YTD,0)) as 场外赎回金额_年累计
		,sum(COALESCE(t1.OTC_COVT_OUT_AMT_YTD,0)) as 场外转换出金额_年累计
		
		--销售金额：场内认购金额、场内认购手续费、场外认购金额、场外申购金额、场外定投金额、场外转换入金额、续作销售金额、转托管入金额
		,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)	--场内认购金额_年累计		
			+COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--场内认购手续费_年累计
			+COALESCE(t1.OTC_SUBS_AMT_YTD,0)	--场外认购金额_年累计
			+COALESCE(t1.OTC_PURS_AMT_YTD,0)	--场外申购金额_年累计
			+COALESCE(t1.OTC_CASTSL_AMT_YTD,0)	--场外定投金额_年累计		
			+COALESCE(t1.OTC_COVT_IN_AMT_YTD,0)	--场外转换入金额_年累计
			+COALESCE(t1.CONTD_SALE_AMT_YTD,0)	--续作销售金额_年累计	
			) as 销售金额_年累计
			
		--首发销售金额：场内认购金额、场内认购手续费、场外认购金额
		,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)	--场内认购金额_年累计	
			+COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--场内认购手续费_年累计	
			+COALESCE(t1.OTC_SUBS_AMT_YTD,0)	--场外认购金额_年累计		
			) as 首发销售金额_年累计				
		
		--赎回金额：场外赎回金额、场外转换出金额、转托管出金额
		,sum(COALESCE(t1.OTC_REDP_AMT_YTD,0)	--场外赎回金额_年累计		
			+COALESCE(t1.OTC_COVT_OUT_AMT_YTD,0)--场外转换出金额_年累计	
			) as 赎回金额_年累计	
			
		,sum(COALESCE(t1.ITC_SUBS_SHAR_YTD,0)) as 场内认购份额_年累计
		,sum(COALESCE(t1.ITC_PURS_SHAR_YTD,0)) as 场内申购份额_年累计
		,sum(COALESCE(t1.ITC_BUYIN_SHAR_YTD,0)) as 场内买入份额_年累计
		,sum(COALESCE(t1.ITC_REDP_SHAR_YTD,0)) as 场内赎回份额_年累计
		,sum(COALESCE(t1.ITC_SELL_SHAR_YTD,0)) as 场内卖出份额_年累计
		,sum(COALESCE(t1.OTC_SUBS_SHAR_YTD,0)) as 场外认购份额_年累计
		,sum(COALESCE(t1.OTC_PURS_SHAR_YTD,0)) as 场外申购份额_年累计
		,sum(COALESCE(t1.OTC_CASTSL_SHAR_YTD,0)) as 场外定投份额_年累计
		,sum(COALESCE(t1.OTC_COVT_IN_SHAR_YTD,0)) as 场外转换入份额_年累计
		,sum(COALESCE(t1.OTC_REDP_SHAR_YTD,0)) as 场外赎回份额_年累计
		,sum(COALESCE(t1.OTC_COVT_OUT_SHAR_YTD,0)) as 场外转换出份额_年累计
		,sum(COALESCE(t1.ITC_SUBS_CHAG_YTD,0)) as 场内认购手续费_年累计
		,sum(COALESCE(t1.ITC_PURS_CHAG_YTD,0)) as 场内申购手续费_年累计
		,sum(COALESCE(t1.ITC_BUYIN_CHAG_YTD,0)) as 场内买入手续费_年累计
		,sum(COALESCE(t1.ITC_REDP_CHAG_YTD,0)) as 场内赎回手续费_年累计
		,sum(COALESCE(t1.ITC_SELL_CHAG_YTD,0)) as 场内卖出手续费_年累计
		,sum(COALESCE(t1.OTC_SUBS_CHAG_YTD,0)) as 场外认购手续费_年累计
		,sum(COALESCE(t1.OTC_PURS_CHAG_YTD,0)) as 场外申购手续费_年累计
		,sum(COALESCE(t1.OTC_CASTSL_CHAG_YTD,0)) as 场外定投手续费_年累计
		,sum(COALESCE(t1.OTC_COVT_IN_CHAG_YTD,0)) as 场外转换入手续费_年累计
		,sum(COALESCE(t1.OTC_REDP_CHAG_YTD,0)) as 场外赎回手续费_年累计
		,sum(COALESCE(t1.OTC_COVT_OUT_CHAG_YTD,0)) as 场外转换出手续费_年累计
		--续作销售
		,sum(COALESCE(t1.CONTD_SALE_SHAR_MTD,0)) as 续作销售份额_月累计
		,sum(COALESCE(t1.CONTD_SALE_AMT_MTD,0)) as 续作销售金额_月累计
		,sum(COALESCE(t1.CONTD_SALE_SHAR_YTD,0)) as 续作销售份额_年累计
		,sum(COALESCE(t1.CONTD_SALE_AMT_YTD,0)) as 续作销售金额_年累计
		,@V_BIN_DATE
	from DM.T_EVT_EMPCUS_PROD_TRD_M_D t1
	left join 
	(											--客户属性和维度处理
		select 
			t1.YEAR
			,t1.MTH	
			,t1.CUST_ID
			,t1.CUST_STAT as 客户状态
			,case when t1.TE_OACT_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as 是否月新增
			,case when t1.TE_OACT_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as 是否年新增
			,t1.IF_VLD as 是否有效
			,t4.IF_SPCA_ACCT as 是否特殊账户
			,t1.IF_PROD_NEW_CUST as 是否产品新客户
			,t1.CUST_TYPE as 客户类型
			
			,case when t5.TOT_AST_MDA<100000 then '0-小于10w'
				when t5.TOT_AST_MDA >= 100000 and t5.TOT_AST_MDA<200000 then '1-10w_20w'
				when t5.TOT_AST_MDA >= 200000 and t5.TOT_AST_MDA<500000 then '2-20w_50w'
				when t5.TOT_AST_MDA >= 500000 and t5.TOT_AST_MDA<1000000 then '3-50w_100w'
				when t5.TOT_AST_MDA >= 1000000 and t5.TOT_AST_MDA<2000000 then '4-100w_200w'
				when t5.TOT_AST_MDA >= 2000000 and t5.TOT_AST_MDA<3000000 then '5-200w_300w'
				when t5.TOT_AST_MDA >= 3000000 and t5.TOT_AST_MDA<5000000 then '6-300w_500w'
				when t5.TOT_AST_MDA >= 5000000 and t5.TOT_AST_MDA<10000000 then '7-500w_1000w'
				when t5.TOT_AST_MDA >= 10000000 and t5.TOT_AST_MDA<30000000 then '8-1000w_3000w'
				when t5.TOT_AST_MDA >= 30000000 then '9-大于3000w'
				else '0-小于10w' end as 资产段		
		 from DM.T_PUB_CUST t1	 
		 left join DM.T_PUB_DATE_M t2 on t1.YEAR=t2.YEAR and t1.MTH=t2.MTH
		 left join DM.T_PUB_CUST_LIMIT_M_D t3 on t1.YEAR=t3.YEAR and t1.MTH=t3.MTH and t1.CUST_ID=t3.CUST_ID
		 left join DM.T_ACC_CPTL_ACC t4 on t1.YEAR=t4.YEAR and t1.MTH=t4.MTH and t1.MAIN_CPTL_ACCT=t4.CPTL_ACCT
		 left join DM.T_AST_ODI_M_D t5 on t1.YEAR=t5.YEAR and t1.MTH=t5.MTH and t1.CUST_ID=t5.CUST_ID
	) t_khsx on t1.YEAR=t_khsx.YEAR and t1.MTH=t_khsx.MTH and t1.CUST_ID=t_khsx.CUST_ID
	group by
		t1.YEAR
		,t1.MTH 
		,t1.YEAR_MTH
		,t1.PROD_CD
		,t1.PROD_TYPE
		,t1.WH_ORG_ID_EMP
		,t1.AFA_SEC_EMPID
		,t_khsx.是否特殊账户
	;

END
