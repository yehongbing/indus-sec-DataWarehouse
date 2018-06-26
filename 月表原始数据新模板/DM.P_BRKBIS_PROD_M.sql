create PROCEDURE DM.P_BRKBIS_PROD_M(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  ������: ����ҵ���Ʒ�±�
  ��д��: LIZM
  ��������: 2018-05-25
  ��飺����ҵ���Ʒ�±���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

    DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
    DECLARE @V_YEAR_MONTH VARCHAR(6);	-- ���·�
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_YEAR_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4) + SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

    --PART0 ɾ����������
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
        t1.YEAR_MTH as ����
        ,t_jg.WH_ORG_ID as �������
        ,t_jg.HR_ORG_NAME as Ӫҵ��
        ,t_jg.HR_ORG_NAME as �ֹ�˾
        ,t_jg.ORG_TYPE as �ֹ�˾���� 
        ,t_khsx.�Ƿ�������
        ,t_khsx.�Ƿ�������
        ,t_khsx.�˻�����
        ,t_khsx.�Ƿ������˻�
        ,t_khsx.�ʲ���
        ,t_khsx.�Ƿ��Ʒ�¿ͻ�
        ,case when t_cp.PROD_TYPE  is null then '' else t_cp.PROD_TYPE end  as ��Ʒ����
        ,case when t_cp.PROD_PAYF_FETUR  is null then '' else t_cp.PROD_PAYF_FETUR end  as ������������
        ,convert(varchar(20),COALESCE(t_cp.IF_KEY_PROD,0)) as �Ƿ��ص��Ʒ
        ,sum(COALESCE(t1.ITC_RETAIN_AMT_FINAL,0)) as ���ڱ��н��_��ĩ
        ,sum(COALESCE(t1.ITC_RETAIN_AMT_MDA,0)) as ���ڱ��н��_���վ�
        ,sum(COALESCE(t1.ITC_RETAIN_AMT_YDA,0)) as ���ڱ��н��_���վ�
        ,sum(COALESCE(t1.OTC_RETAIN_AMT_FINAL,0)) as ���Ᵽ�н��_��ĩ
        ,sum(COALESCE(t1.OTC_RETAIN_AMT_MDA,0)) as ���Ᵽ�н��_���վ�
        ,sum(COALESCE(t1.OTC_RETAIN_AMT_YDA,0)) as ���Ᵽ�н��_���վ�
        --���۽������Ϲ��������Ϲ������ѡ������Ϲ��������깺�����ⶨͶ������ת������������۽�ת�й�����
        ,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)	--�����Ϲ����_���ۼ�
            +COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--�����Ϲ�������_���ۼ�
            +COALESCE(t1.OTC_SUBS_AMT_MTD,0)	--�����Ϲ����_���ۼ�
            +COALESCE(t1.OTC_PURS_AMT_MTD,0)	--�����깺���_���ۼ�
            +COALESCE(t1.OTC_CASTSL_AMT_MTD,0)	--���ⶨͶ���_���ۼ�		
            +COALESCE(t1.OTC_COVT_IN_AMT_MTD,0)	--����ת������_���ۼ�
            +COALESCE(t1.CONTD_SALE_AMT_MTD,0)	--�������۽��_���ۼ�				
            ) as ��Ʒ���۽��_���ۼ�
        --�׷����۽������Ϲ��������Ϲ������ѡ������Ϲ����
        ,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)	--�����Ϲ����_���ۼ�		
            +COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--�����Ϲ�������_���ۼ�
            +COALESCE(t1.OTC_SUBS_AMT_MTD,0)	--�����Ϲ����_���ۼ�		
            ) as �׷���Ʒ���۽��_���ۼ�
        ,sum(COALESCE(t1.ITC_SUBS_AMT_MTD,0)) as �����Ϲ����_���ۼ�
        ,sum(COALESCE(t1.OTC_SUBS_AMT_MTD,0)) as �����Ϲ����_���ۼ�
        ,sum(COALESCE(t1.OTC_PURS_AMT_MTD,0)) as �����깺���_���ۼ�
        ,sum(COALESCE(t1.OTC_CASTSL_AMT_MTD,0)) as ���ⶨͶ���_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_IN_AMT_MTD,0)) as ����ת������_���ۼ�
        ,sum(COALESCE(t_jjzb.ZTGRQRJE_M,0)) as ת�й�����_���ۼ�
        ,sum(COALESCE(t1.CONTD_SALE_AMT_MTD,0)) as �������۽��_���ۼ�
        --��ؽ�������ؽ�����ת������ת�йܳ����
        ,sum(COALESCE(t1.OTC_REDP_AMT_MTD,0)		--������ؽ��_���ۼ�		
            +COALESCE(t1.OTC_COVT_OUT_AMT_MTD,0)--����ת�������_���ۼ�	
            ) as ��Ʒ��ؽ��_���ۼ�
        ,sum(COALESCE(t1.OTC_REDP_AMT_MTD,0)) as ������ؽ��_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_OUT_AMT_MTD,0)) as ����ת�������_���ۼ�
        ,sum(COALESCE(t_jjzb.ZTGCQRJE_M,0)) as ת�йܳ����_���ۼ�
        --���۽������Ϲ��������Ϲ������ѡ������Ϲ��������깺�����ⶨͶ������ת������������۽�ת�й�����
        ,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)	--�����Ϲ����_���ۼ�		
            +COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--�����Ϲ�������_���ۼ�
            +COALESCE(t1.OTC_SUBS_AMT_YTD,0)	--�����Ϲ����_���ۼ�
            +COALESCE(t1.OTC_PURS_AMT_YTD,0)	--�����깺���_���ۼ�
            +COALESCE(t1.OTC_CASTSL_AMT_YTD,0)	--���ⶨͶ���_���ۼ�		
            +COALESCE(t1.OTC_COVT_IN_AMT_YTD,0)	--����ת������_���ۼ�
            +COALESCE(t1.CONTD_SALE_AMT_YTD,0)	--�������۽��_���ۼ�	
            ) as ��Ʒ���۽��_���ۼ�
        --�׷����۽������Ϲ��������Ϲ������ѡ������Ϲ����
        ,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)	--�����Ϲ����_���ۼ�	
            +COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--�����Ϲ�������_���ۼ�	
            +COALESCE(t1.OTC_SUBS_AMT_YTD,0)	--�����Ϲ����_���ۼ�		
            ) as �׷���Ʒ���۽��_���ۼ�
        ,sum(COALESCE(t1.ITC_SUBS_AMT_YTD,0)) as �����Ϲ����_���ۼ�
        ,sum(COALESCE(t1.OTC_SUBS_AMT_YTD,0)) as �����Ϲ����_���ۼ�
        ,sum(COALESCE(t1.OTC_PURS_AMT_YTD,0)) as �����깺���_���ۼ�
        ,sum(COALESCE(t1.OTC_CASTSL_AMT_YTD,0)) as ���ⶨͶ���_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_IN_AMT_YTD,0)) as ����ת������_���ۼ�
        ,sum(COALESCE(t_jjzb.ZTGRQRJE_Y,0)) as ת�й�����_���ۼ�
        ,sum(COALESCE(t1.CONTD_SALE_AMT_YTD,0)) as �������۽��_���ۼ�
        --��ؽ�������ؽ�����ת������ת�йܳ����
        ,sum(COALESCE(t1.OTC_REDP_AMT_YTD,0)	--������ؽ��_���ۼ�		
            +COALESCE(t1.OTC_COVT_OUT_AMT_YTD,0)--����ת�������_���ۼ�	
            ) as ��Ʒ��ؽ��_���ۼ�
        ,sum(COALESCE(t1.OTC_REDP_AMT_YTD,0)) as ������ؽ��_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_OUT_AMT_YTD,0)) as ����ת�������_���ۼ�
        ,sum(COALESCE(t_jjzb.ZTGCQRJE_Y,0)) as ת�йܳ����_���ۼ�
        --�����Ϲ��������Ϲ��������깺�����ⶨͶ������ת���롢�������ۡ�ת�й���
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_MTD,0)	--�����Ϲ�������_���ۼ�		
            +COALESCE(t1.OTC_SUBS_CHAG_MTD,0)	--�����Ϲ�������_���ۼ�
            +COALESCE(t1.OTC_PURS_CHAG_MTD,0)	--�����깺������_���ۼ�
            +COALESCE(t1.OTC_CASTSL_CHAG_MTD,0)	--���ⶨͶ������_���ۼ�
            +COALESCE(t1.OTC_COVT_IN_CHAG_MTD,0) --����ת����������_���ۼ�
            ) as ��Ʒ����������_���ۼ� 
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_MTD,0)) as �����Ϲ�������_���ۼ�
        ,sum(COALESCE(t1.OTC_SUBS_CHAG_MTD,0)) as �����Ϲ�������_���ۼ�
        ,sum(COALESCE(t1.OTC_PURS_CHAG_MTD,0)) as �����깺������_���ۼ�
        ,sum(COALESCE(t1.OTC_CASTSL_CHAG_MTD,0)) as ���ⶨͶ������_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_IN_CHAG_MTD,0)) as ����ת����������_���ۼ�
        ,0 as ת�й���������_���ۼ�
        --������ء�����ת������ת�йܳ�
        ,sum(COALESCE(t1.OTC_REDP_CHAG_MTD,0)	--�������������_���ۼ�	
			+COALESCE(t1.OTC_COVT_OUT_CHAG_MTD,0) --����ת����������_���ۼ�
            --ת�йܳ�������_���ۼƣ�δ��ȡ��
			) as ��Ʒ���������_���ۼ�
        ,sum(COALESCE(t1.OTC_REDP_CHAG_MTD,0)) as �������������_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_OUT_CHAG_MTD,0)) as ����ת����������_���ۼ�
        ,0 as ת�йܳ�������_���ۼ�
        --�����Ϲ��������Ϲ��������깺�����ⶨͶ������ת���롢�������ۡ�ת�й���
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_YTD,0)	--�����Ϲ�������_���ۼ�		
			+COALESCE(t1.OTC_SUBS_CHAG_YTD,0)	--�����Ϲ�������_���ۼ�
			+COALESCE(t1.OTC_PURS_CHAG_YTD,0)	--�����깺������_���ۼ�
			+COALESCE(t1.OTC_CASTSL_CHAG_YTD,0)	--���ⶨͶ������_���ۼ�
			+COALESCE(t1.OTC_COVT_IN_CHAG_YTD,0) --����ת����������_���ۼ�
			) as ��Ʒ����������_���ۼ� 
        ,sum(COALESCE(t1.ITC_SUBS_CHAG_YTD,0)) as �����Ϲ�������_���ۼ�
        ,sum(COALESCE(t1.OTC_SUBS_CHAG_YTD,0)) as �����Ϲ�������_���ۼ�
        ,sum(COALESCE(t1.OTC_PURS_CHAG_YTD,0)) as �����깺������_���ۼ� 
        ,sum(COALESCE(t1.OTC_CASTSL_CHAG_YTD,0)) as ���ⶨͶ������_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_IN_CHAG_YTD,0)) as ����ת����������_���ۼ�
        ,0 as ת�й���������_���ۼ�
        --������ء�����ת������ת�йܳ�
        ,sum(COALESCE(t1.OTC_REDP_CHAG_YTD,0)	--�������������_���ۼ�
            +COALESCE(t1.OTC_COVT_OUT_CHAG_YTD,0) --����ת����������_���ۼ�
            --ת�йܳ�������_���ۼƣ�δ��ȡ��
            ) as ��Ʒ���������_���ۼ�
        ,sum(COALESCE(t1.OTC_REDP_CHAG_YTD,0)) as �������������_���ۼ�
        ,sum(COALESCE(t1.OTC_COVT_OUT_CHAG_YTD,0)) as ����ת����������_���ۼ�
        --������ء�����ת������ת�йܳ�
        ,0 as ת�йܳ�������_���ۼ�
	from DM.T_EVT_EMPCUS_PROD_TRD_M_D t1
    left join DM.T_PUB_ORG t_jg					--������
	    on t1.YEAR=t_jg.YEAR and t1.MTH=t_jg.MTH and t1.WH_ORG_ID_EMP=t_jg.WH_ORG_ID
    left join DM.T_VAR_PROD_OTC t_cp
        on t_cp.OCCUR_DT = @V_BIN_DATE and t_cp.PROD_CD = t1.PROD_CD
    left join DBA.T_DDW_XY_JJZB_M t_jjzb
        on t_jjzb.NIAN = t1.YEAR and t_jjzb.YUE = t1.MTH and t_jjzb.JJDM = t1.PROD_CD
    left join 
    (											--�ͻ����Ժ�ά�ȴ���
		select 
			t1.YEAR
			,t1.MTH	
			,t1.CUST_ID
			,t1.CUST_STAT as �ͻ�״̬
			,case when t1.TE_OACT_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as �Ƿ�������
			,case when t1.TE_OACT_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as �Ƿ�������
			,coalesce(t1.IF_VLD,0) as �Ƿ���Ч
			,coalesce(CONVERT(VARCHAR,t4.IF_SPCA_ACCT),'0') as �Ƿ������˻�
			,coalesce(convert(varchar,t1.IF_PROD_NEW_CUST),'0') as �Ƿ��Ʒ�¿ͻ�
			,t1.CUST_TYPE as �ͻ�����
			,t1.CUST_TYPE_NAME as �˻�����
	     	,case 
            when t5.TOT_AST_MDA<100                                     then '00-100����'
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
			when t5.TOT_AST_MDA >= 30000000                             then '9-����3000w'
         end as �ʲ���			
		 from DM.T_PUB_CUST t1	 
		 left join DM.T_PUB_DATE_M t2 on t1.YEAR=t2.YEAR and t1.MTH=t2.MTH
		 left join DM.T_PUB_CUST_LIMIT_M_D t3 on t1.YEAR=t3.YEAR and t1.MTH=t3.MTH and t1.CUST_ID=t3.CUST_ID
		 left join DM.T_ACC_CPTL_ACC t4 on t1.YEAR=t4.YEAR and t1.MTH=t4.MTH and t1.MAIN_CPTL_ACCT=t4.CPTL_ACCT
		 left join DM.T_AST_ODI_M_D t5 on t1.YEAR=t5.YEAR and t1.MTH=t5.MTH and t1.CUST_ID=t5.CUST_ID
     WHERE t1.YEAR= @V_YEAR 
        and t1.MTH= @V_MONTH 
        AND �ʲ��� IS NOT NULL
	) t_khsx on t1.YEAR=t_khsx.YEAR and t1.MTH=t_khsx.MTH and t1.CUST_ID=t_khsx.CUST_ID
 WHERE  t1.YEAR=@V_YEAR and t1.MTH=@V_MONTH
    and t_khsx.�Ƿ������˻� IS NOT NULL 
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
        ,t_khsx.�Ƿ�������
        ,t_khsx.�Ƿ�������
        ,t_khsx.�˻�����
        ,t_khsx.�Ƿ������˻�
        ,t_khsx.�ʲ���
        ,t_khsx.�Ƿ��Ʒ�¿ͻ�
        ,t_cp.PROD_TYPE
        ,t_cp.PROD_PAYF_FETUR
        ,t_cp.IF_KEY_PROD
	;

END