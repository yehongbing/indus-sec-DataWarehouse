create PROCEDURE DM.P_BRKBIS_AST_TRD_M(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  ������: ����ҵ���ʲ������±�
  ��д��: LIZM
  ��������: 2018-05-21
  ��飺 ����ҵ���ʲ������±���
  *********************************************************************/
    DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
  	DECLARE @V_YEAR_MTH VARCHAR(6);		-- ����
    SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	SET @V_YEAR_MTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4)+ SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);


	--PART0 ɾ����������
  DELETE FROM DM.T_BRKBIS_AST_TRD_M WHERE YEAR_MTH=@V_YEAR_MTH;

  INSERT INTO DM.T_BRKBIS_AST_TRD_M
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
     ,CUST_NUM
     ,EFF_HOUS
     ,TOTAST_FINAL  
     ,NET_AST_FINAL 
     ,STKF_MVAL_FINAL
     ,NOTS_MVAL_FINAL
     ,SPGSMV_FINAL_SCDY_DEDUCT
     ,MARG_FINAL    
     ,BOND_MVAL_FINAL
     ,REPO_MVAL_FINAL
     ,PSTK_OPTN_FINAL
     ,PROD_MVAL_FINAL
     ,CREDIT_TOTAST_FINAL 
     ,CREDIT_TOT_LIAB_FINAL
     ,CREDIT_BAL_FINAL    
     ,APPTBUYB_TOTAST_FINAL
     ,APPTBUYB_BAL_FINAL  
     ,STKPLG_TOTAST_FINAL 
     ,STKPLG_BAL_FINAL    
     ,OTH_AST_FINAL 
     ,REAL_NO_ARVD_CPTL_FINAL
     ,ODI_A_SHR_MVAL_FINAL
     ,CRED_A_SHR_MVAL_FINAL
     ,TOTAST_MDA    
     ,NET_AST_MDA   
     ,STKF_MVAL_MDA 
     ,NOTS_MVAL_MDA 
     ,SPGSMV_MDA_SCDY_DEDUCT
     ,MARG_MDA
     ,BOND_MVAL_MDA 
     ,REPO_MVAL_MDA 
     ,PSTK_OPTN_MDA 
     ,PROD_MVAL_MDA 
     ,CREDIT_TOTAST_MDA   
     ,CREDIT_TOT_LIAB_MDA 
     ,CREDIT_BAL_MDA
     ,APPTBUYB_TOTAST_MDA 
     ,APPTBUYB_BAL_MDA    
     ,STKPLG_TOTAST_MDA   
     ,STKPLG_BAL_MDA
     ,OTH_AST_MDA   
     ,REAL_NO_ARVD_CPTL_MDA
     ,ODI_A_SHR_MVAL_MDA  
     ,CRED_A_SHR_MVAL_MDA 
     ,TOTAST_YDA    
     ,NET_AST_YDA   
     ,STKF_MVAL_YDA 
     ,NOTS_MVAL_YDA 
     ,SPGSMV_YDA_SCDY_DEDUCT
     ,MARG_YDA
     ,BOND_MVAL_YDA 
     ,REPO_MVAL_YDA 
     ,PSTK_OPTN_YDA 
     ,PROD_MVAL_YDA 
     ,CREDIT_TOTAST_YDA   
     ,CREDIT_TOT_LIAB_YDA 
     ,CREDIT_BAL_YDA
     ,APPTBUYB_TOTAST_YDA 
     ,APPTBUYB_BAL_YDA    
     ,STKPLG_TOTAST_YDA   
     ,STKPLG_BAL_YDA
     ,OTH_AST_YDA   
     ,REAL_NO_ARVD_CPTL_YDA
     ,ODI_A_SHR_MVAL_YDA  
     ,CRED_A_SHR_MVAL_YDA 
     ,STKF_TRD_QTY_MTD    
     ,HGT_TRD_QTY_MTD
     ,SGT_TRD_QTY_MTD
     ,SB_TRD_QTY_MTD
     ,PSTK_OPTN_TRD_QTY_MTD
     ,BOND_TRD_QTY_MTD    
     ,S_REPUR_TRD_QTY_MTD 
     ,R_REPUR_TRD_QTY_MTD 
     ,CREDIT_ODI_TRD_QTY_MTD
     ,CREDIT_CRED_TRD_QTY_MTD
     ,ITC_CRRC_FUND_TRD_QTY_MTD
     ,BGDL_QTY_MTD  
     ,REPQ_TRD_QTY_MTD    
     ,STKF_TRD_QTY_YTD    
     ,HGT_TRD_QTY_YTD
     ,SGT_TRD_QTY_YTD
     ,SB_TRD_QTY_YTD
     ,PSTK_OPTN_TRD_QTY_YTD
     ,BOND_TRD_QTY_YTD    
     ,S_REPUR_TRD_QTY_YTD 
     ,R_REPUR_TRD_QTY_YTD 
     ,CREDIT_ODI_TRD_QTY_YTD
     ,CREDIT_CRED_TRD_QTY_YTD
     ,ITC_CRRC_FUND_TRD_QTY_YTD
     ,BGDL_QTY_YTD  
     ,REPQ_TRD_QTY_YTD    
     ,STKF_NET_CMS_MTD    
     ,HGT_NET_CMS_MTD
     ,SGT_NET_CMS_MTD
     ,PSTK_OPTN_NET_CMS_MTD
     ,S_REPUR_NET_CMS_MTD 
     ,R_REPUR_NET_CMS_MTD 
     ,CREDIT_ODI_NET_CMS_MTD
     ,CREDIT_CRED_NET_CMS_MTD
     ,ITC_CRRC_FUND_NET_CMS_MTD
     ,BGDL_NET_CMS_MTD    
     ,REPQ_NET_CMS_MTD    
     ,ODI_SPR_INCM_MTD    
     ,CRED_SPR_INCM_MTD   
     ,STKF_NET_CMS_YTD    
     ,HGT_NET_CMS_YTD
     ,SGT_NET_CMS_YTD
     ,PSTK_OPTN_NET_CMS_YTD
     ,S_REPUR_NET_CMS_YTD 
     ,R_REPUR_NET_CMS_YTD 
     ,CREDIT_ODI_NET_CMS_YTD
     ,CREDIT_CRED_NET_CMS_YTD
     ,ITC_CRRC_FUND_NET_CMS_YTD
     ,BGDL_NET_CMS_YTD    
     ,REPQ_NET_CMS_YTD    
     ,ODI_SPR_INCM_YTD    
     ,CRED_SPR_INCM_YTD     
	)
	select
	t1.YEAR||t1.MTH as ����
	,t_jg.WH_ORG_ID as �������	
    ,t_jg.HR_ORG_NAME as Ӫҵ��
    ,t_jg.SEPT_CORP_NAME as �ֹ�˾
    ,t_jg.ORG_TYPE as �ֹ�˾���� 
    ,t_khsx.�Ƿ�������
    ,t_khsx.�Ƿ�������
    ,t_khsx.�˻�����
    ,t_khsx.�Ƿ������˻�
    ,t_khsx.�ʲ���
    ,sum(case when t_khsx.�ͻ�״̬='0' then t2.JXBL1 else 0 end) as �ͻ���
    ,sum(case when t_khsx.�ͻ�״̬='0' and t_khsx.�Ƿ���Ч=1 then t2.JXBL1 else 0 end) as ��Ч�ͻ���
    ,sum(COALESCE(t1.TOT_AST_FINAL,0)) as ��ͨ�ʲ�_���ʲ�_��ĩ
    ,sum(COALESCE(t1.NET_AST_FINAL,0)) as ��ͨ�ʲ�_���ʲ�_��ĩ
    ,sum(COALESCE(t1.STKF_MVAL_FINAL,0)) as ��ͨ�ʲ�_�ɻ���ֵ_��ĩ
    ,sum(COALESCE(t1.NOTS_MVAL_FINAL,0)) as ��ͨ�ʲ�_���۹���ֵ_��ĩ
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_FINAL_SCDY_DEDUCT,0)) as ��ͨ�ʲ�_��Ʊ��Ѻ����֤ȯ��ֵ_��ĩ_�����ۼ�
    ,sum(COALESCE(t1.CPTL_BAL_FINAL,0)) as ��֤��_��ĩ
    ,sum(COALESCE(t1.BOND_MVAL_FINAL,0)) as ��ͨ�ʲ�_ծȯ��ֵ_��ĩ
    ,sum(COALESCE(t1.REPO_MVAL_FINAL,0)) as ��ͨ�ʲ�_�ع���ֵ_��ĩ
    ,sum(COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0)) as ��ͨ�ʲ�_������Ȩ_��ĩ 
    ,sum(COALESCE(t1.PROD_TOT_MVAL_FINAL,0)) as ��ͨ�ʲ�_��Ʒ��ֵ_��ĩ
    ,sum(COALESCE(t1.CREDIT_TOT_AST_FINAL,0)) as ��ͨ�ʲ�_������ȯ���ʲ�_��ĩ
    ,sum(COALESCE(t1.CREDIT_TOT_LIAB_FINAL,0)) as ��ͨ�ʲ�_������ȯ�ܸ�ծ_��ĩ
    ,sum(COALESCE(t1.CREDIT_BAL_FINAL,0)) as ��ͨ�ʲ�_������ȯ���_��ĩ
    ,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0)) as Լ���������ʲ�_��ĩ
    ,sum(COALESCE(t1.APPTBUYB_BAL_FINAL,0)) as ��ͨ�ʲ�_Լ���������_��ĩ
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_FINAL,0)) as ��Ʊ��Ѻ���ʲ�_��ĩ
    ,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_FINAL,0)) as ��Ʊ��Ѻ���_��ĩ
    ,sum(COALESCE(t1.OTH_AST_MVAL_FINAL,0)) as ��ͨ�ʲ�_�����ʲ�_��ĩ
    ,sum(COALESCE(t1.NO_ARVD_CPTL_FINAL,0)) as ��ͨ�ʲ�_��ʵδ�����ʽ�_��ĩ
    ,sum(COALESCE(t1.A_SHR_MVAL_FINAL,0)) as ��ͨ�ʲ�_��ͨA����ֵ_��ĩ
    ,sum(COALESCE(t_rzrq.A_SHR_MVAL_FINAL,0)) as ����A����ֵ_��ĩ
    ,sum(COALESCE(t1.TOT_AST_MDA,0)) as ��ͨ�ʲ�_���ʲ�_���վ�
    ,sum(COALESCE(t1.NET_AST_MDA,0)) as ��ͨ�ʲ�_���ʲ�_���վ�
    ,sum(COALESCE(t1.STKF_MVAL_MDA,0)) as ��ͨ�ʲ�_�ɻ���ֵ_���վ�
    ,sum(COALESCE(t1.NOTS_MVAL_MDA,0)) as ��ͨ�ʲ�_���۹���ֵ_���վ�
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_MDA_SCDY_DEDUCT,0)) as ��ͨ�ʲ�_��Ʊ��Ѻ����֤ȯ��ֵ_���վ�_�����ۼ�
    ,sum(COALESCE(t1.CPTL_BAL_MDA,0)) as ��֤��_���վ�
    ,sum(COALESCE(t1.BOND_MVAL_MDA,0)) as ��ͨ�ʲ�_ծȯ��ֵ_���վ�
    ,sum(COALESCE(t1.REPO_MVAL_MDA,0)) as ��ͨ�ʲ�_�ع���ֵ_���վ�
    ,sum(COALESCE(t1.PSTK_OPTN_MVAL_MDA,0)) as ��ͨ�ʲ�_������Ȩ_���վ�
    ,sum(COALESCE(t1.PROD_TOT_MVAL_MDA,0)) as ��ͨ�ʲ�_��Ʒ��ֵ_���վ�
    ,sum(COALESCE(t1.CREDIT_TOT_AST_MDA,0)) as ��ͨ�ʲ�_������ȯ���ʲ�_���վ�
    ,sum(COALESCE(t1.CREDIT_TOT_LIAB_MDA,0)) as ��ͨ�ʲ�_������ȯ�ܸ�ծ_���վ�
    ,sum(COALESCE(t1.CREDIT_BAL_MDA,0)) as ��ͨ�ʲ�_������ȯ���_���վ�
    ,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0)) AS  Լ���������ʲ�_���վ�
    ,sum(COALESCE(t1.APPTBUYB_BAL_MDA,0)) as ��ͨ�ʲ�_Լ���������_���վ�
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_MDA,0)) as ��Ʊ��Ѻ���ʲ�_���վ�
    ,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_MDA,0)) as ��Ʊ��Ѻ���_���վ�
    ,sum(COALESCE(t1.OTH_AST_MVAL_MDA,0)) as ��ͨ�ʲ�_�����ʲ�_���վ�
    ,sum(COALESCE(t1.NO_ARVD_CPTL_MDA,0)) as ��ͨ�ʲ�_��ʵδ�����ʽ�_���վ�
    ,sum(COALESCE(t1.A_SHR_MVAL_MDA,0)) as ��ͨ�ʲ�_��ͨA����ֵ_���վ�
    ,sum(COALESCE(t_rzrq.A_SHR_MVAL_MDA,0)) as ����A����ֵ_���վ�
    ,sum(COALESCE(t1.TOT_AST_YDA,0)) as ��ͨ�ʲ�_���ʲ�_���վ�
    ,sum(COALESCE(t1.NET_AST_YDA,0)) as ��ͨ�ʲ�_���ʲ�_���վ�
    ,sum(COALESCE(t1.STKF_MVAL_YDA,0)) as ��ͨ�ʲ�_�ɻ���ֵ_���վ�
    ,sum(COALESCE(t1.NOTS_MVAL_YDA,0)) as ��ͨ�ʲ�_���۹���ֵ_���վ�
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_YDA_SCDY_DEDUCT,0)) as ��ͨ�ʲ�_��Ʊ��Ѻ����֤ȯ��ֵ_���վ�_�����ۼ�
    ,sum(COALESCE(t1.CPTL_BAL_YDA,0)) as ��֤��_���վ�
    ,sum(COALESCE(t1.BOND_MVAL_YDA,0)) as ��ͨ�ʲ�_ծȯ��ֵ_���վ�
    ,sum(COALESCE(t1.REPO_MVAL_YDA,0)) as ��ͨ�ʲ�_�ع���ֵ_���վ�
    ,sum(COALESCE(t1.PSTK_OPTN_MVAL_YDA,0)) as ��ͨ�ʲ�_������Ȩ_���վ�
    ,sum(COALESCE(t1.PROD_TOT_MVAL_YDA,0)) as ��ͨ�ʲ�_��Ʒ��ֵ_���վ�
    ,sum(COALESCE(t1.CREDIT_TOT_AST_YDA,0)) as ��ͨ�ʲ�_������ȯ���ʲ�_���վ�
    ,sum(COALESCE(t1.CREDIT_TOT_LIAB_YDA,0)) as ��ͨ�ʲ�_������ȯ�ܸ�ծ_���վ�
    ,sum(COALESCE(t1.CREDIT_BAL_YDA,0)) as ��ͨ�ʲ�_������ȯ���_���վ�
    ,sum(COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0)) as Լ���������ʲ�_���վ�
    ,sum(COALESCE(t1.APPTBUYB_BAL_YDA,0)) as ��ͨ�ʲ�_Լ���������_���վ�
    ,sum(COALESCE(t1.STKPLG_GUAR_SECU_MVAL_YDA,0)) as ��Ʊ��Ѻ���ʲ�_���վ�
    ,sum(COALESCE(t_gpzy.STKPLG_FIN_BAL_YDA,0)) as ��Ʊ��Ѻ���_���վ�
    ,sum(COALESCE(t1.OTH_AST_MVAL_YDA,0)) as ��ͨ�ʲ�_�����ʲ�_���վ�
    ,sum(COALESCE(t1.NO_ARVD_CPTL_YDA,0)) as ��ͨ�ʲ�_��ʵδ�����ʽ�_���վ�
    ,sum(COALESCE(t1.A_SHR_MVAL_YDA,0)) as ��ͨ�ʲ�_��ͨA����ֵ_���վ�
    ,sum(COALESCE(t_rzrq.A_SHR_MVAL_YDA,0)) as ����A����ֵ_���վ�
    ,sum(COALESCE(t_ptjy.STKF_TRD_QTY_MTD,0)) as ��ͨ����_�ɻ�������_���ۼ�
    ,sum(COALESCE(t_ptjy.HGT_TRD_QTY_MTD,0)) as ��ͨ����_����ͨ������_���ۼ�
    ,sum(COALESCE(t_ptjy.SGT_TRD_QTY_MTD,0)) as ��ͨ����_���ͨ������_���ۼ�
    ,sum(COALESCE(t_ptjy.SB_TRD_QTY_MTD,0)) as ���彻����_���ۼ�
    ,sum(COALESCE(t_ptjy.PSTK_OPTN_TRD_QTY_MTD,0)) as ��ͨ����_������Ȩ������_���ۼ�
    ,sum(COALESCE(t_ptjy.BOND_TRD_QTY_MTD,0)) as ծȯ������_���ۼ�
    ,sum(COALESCE(t_ptjy.S_REPUR_TRD_QTY_MTD,0)) as ��ͨ����_���ع�������_���ۼ�
    ,sum(COALESCE(t_ptjy.R_REPUR_TRD_QTY_MTD,0)) as ��ͨ����_��ع�������_���ۼ�
    ,sum(COALESCE(t_ptjy.CREDIT_ODI_TRD_QTY_MTD,0)) as �����˻���ͨ������_���ۼ�
    ,sum(COALESCE(t_ptjy.CREDIT_CRED_TRD_QTY_MTD,0)) as �����˻����ý�����_���ۼ�
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_TRD_QTY_MTD,0)) as ���ڻ��һ�������_���ۼ�
    ,sum(COALESCE(t_ptjy.BGDL_QTY_MTD,0)) as ��ͨ����_���ڽ�����_���ۼ�
    ,sum(COALESCE(t_ptjy.REPQ_TRD_QTY_MTD,0)) as ��ͨ����_���ۻع�������_���ۼ�
    ,sum(COALESCE(t_ptjy.STKF_TRD_QTY_YTD,0)) as ��ͨ����_�ɻ�������_���ۼ�
    ,sum(COALESCE(t_ptjy.HGT_TRD_QTY_YTD,0)) as ��ͨ����_����ͨ������_���ۼ�
    ,sum(COALESCE(t_ptjy.SGT_TRD_QTY_YTD,0)) as ��ͨ����_���ͨ������_���ۼ�
    ,sum(COALESCE(t_ptjy.SB_TRD_QTY_YTD,0)) as ���彻����_���ۼ�
    ,sum(COALESCE(t_ptjy.PSTK_OPTN_TRD_QTY_YTD,0)) as ��ͨ����_������Ȩ������_���ۼ�
    ,sum(COALESCE(t_ptjy.BOND_TRD_QTY_YTD,0)) as ծȯ������_���ۼ�
    ,sum(COALESCE(t_ptjy.S_REPUR_TRD_QTY_YTD,0)) as ��ͨ����_���ع�������_���ۼ�
    ,sum(COALESCE(t_ptjy.R_REPUR_TRD_QTY_YTD,0)) as ��ͨ����_��ع�������_���ۼ�
    ,sum(COALESCE(t_ptjy.CREDIT_ODI_TRD_QTY_YTD,0)) as �����˻���ͨ������_���ۼ�
    ,sum(COALESCE(t_ptjy.CREDIT_CRED_TRD_QTY_YTD,0)) as �����˻����ý�����_���ۼ�
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_TRD_QTY_YTD,0)) as ���ڻ��һ�������_���ۼ�
    ,sum(COALESCE(t_ptjy.BGDL_QTY_YTD,0)) as ��ͨ����_���ڽ�����_���ۼ�
    ,sum(COALESCE(t_ptjy.REPQ_TRD_QTY_YTD,0)) as ��ͨ����_���ۻع�������_���ۼ�
    ,sum(COALESCE(t_ptsr.STKF_NET_CMS_MTD,0)) as ��ͨ����_�ɻ���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.HGT_NET_CMS_MTD,0)) as ��ͨ����_����ͨ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.SGT_NET_CMS_MTD,0)) as ��ͨ����_���ͨ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.PSTK_OPTN_NET_CMS_MTD,0)) as ��ͨ����_������Ȩ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptjy.S_REPUR_NET_CMS_MTD,0)) as ���ع���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptjy.R_REPUR_NET_CMS_MTD,0)) as ��ع���Ӷ��_���ۼ�
    ,sum(COALESCE(t_xysr.CREDIT_ODI_NET_CMS_MTD,0)) as �����˻���ͨ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_xysr.CREDIT_CRED_NET_CMS_MTD,0)) as �����˻����þ�Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_NET_CMS_MTD,0)) as ���ڻ��һ���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.BGDL_NET_CMS_MTD,0)) as ��ͨ����_���ڽ��׾�Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.REPQ_NET_CMS_MTD,0)) as ��ͨ����_���ۻع���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.MARG_SPR_INCM_MTD,0)) as ��ͨ��������_���ۼ�
    ,sum(COALESCE(t_xysr.CREDIT_MARG_SPR_INCM_MTD,0)) AS  ������������_���ۼ�
    ,sum(COALESCE(t_ptsr.STKF_NET_CMS_YTD,0)) as ��ͨ����_�ɻ���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.HGT_NET_CMS_YTD,0)) as ��ͨ����_����ͨ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.SGT_NET_CMS_YTD,0)) as ��ͨ����_���ͨ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.PSTK_OPTN_NET_CMS_YTD,0)) as ��ͨ����_������Ȩ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptjy.S_REPUR_NET_CMS_YTD,0)) as ���ع���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptjy.R_REPUR_NET_CMS_YTD,0)) as ��ع���Ӷ��_���ۼ�
    ,sum(COALESCE(t_xysr.CREDIT_ODI_NET_CMS_YTD,0)) as �����˻���ͨ��Ӷ��_���ۼ�
    ,sum(COALESCE(t_xysr.CREDIT_CRED_NET_CMS_YTD,0)) as �����˻����þ�Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptjy.ITC_CRRC_FUND_NET_CMS_YTD,0)) as ���ڻ��һ���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.BGDL_NET_CMS_YTD,0)) as ��ͨ����_���ڽ��׾�Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.REPQ_NET_CMS_YTD,0)) as ��ͨ����_���ۻع���Ӷ��_���ۼ�
    ,sum(COALESCE(t_ptsr.MARG_SPR_INCM_YTD,0)) as ��ͨ��������_���ۼ�
    ,sum(COALESCE(t_xysr.CREDIT_MARG_SPR_INCM_YTD,0)) as ������������_���ۼ�
from DM.T_AST_EMPCUS_ODI_M_D t1					--Ա���ͻ���ͨ�ʲ�
left join DM.T_PUB_ORG t_jg					--������
	on t1.YEAR=t_jg.YEAR and t1.MTH=t_jg.MTH and t1.WH_ORG_ID_EMP=t_jg.WH_ORG_ID
--20180427�޸�������Ȩ��
left join DBA.t_ddw_serv_relation t2
	on t1.year=t2.NIAN 
		and t1.mth=t2.YUE 
		and t2.KHBH_HS=t1.cust_id 
		and t1.afa_sec_empid=t2.AFATWO_YGH
left join 
(											--�ͻ����Ժ�ά�ȴ���
	select 
		t1.YEAR
		,t1.MTH	
		,t1.CUST_ID
		,t1.CUST_STAT_NAME as �ͻ�״̬
		,case when t1.TE_OACT_DT>=t2.NATRE_DAY_MTHBEG then 1 else 0 end as �Ƿ�������
		,case when t1.TE_OACT_DT>=t2.NATRE_DAY_YEARBGN then 1 else 0 end as �Ƿ�������
		,coalesce(t1.IF_VLD,0) as �Ƿ���Ч
		,coalesce(t4.IF_SPCA_ACCT,0) as �Ƿ������˻�
		,coalesce(t1.IF_PROD_NEW_CUST,0)   as �Ƿ��Ʒ�¿ͻ�
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
    where  t1.YEAR=@V_YEAR and t1.MTH=@V_MONTH  and �ʲ��� is not null
) t_khsx on t1.YEAR=t_khsx.YEAR and t1.MTH=t_khsx.MTH and t1.CUST_ID=t_khsx.CUST_ID
left join DM.T_AST_EMPCUS_ODI_M_D t_ptzc			--Ա���ͻ���ͨ�ʲ�
	on t1.YEAR=t_ptzc.YEAR and t1.MTH=t_ptzc.MTH and t1.CUST_ID=t_ptzc.CUST_ID and t1.AFA_SEC_EMPID=t_ptzc.AFA_SEC_EMPID
left join DM.T_AST_EMPCUS_CREDIT_M_D t_rzrq		--Ա���ͻ�������ȯ
	on t1.YEAR=t_rzrq.YEAR and t1.MTH=t_rzrq.MTH and t1.CUST_ID=t_rzrq.CUST_ID and t1.AFA_SEC_EMPID=t_rzrq.AFA_SEC_EMPID
left join DM.T_AST_EMPCUS_CPTL_CHG_M_D t_zcbd	--Ա���ͻ��ʲ��䶯
	on t1.YEAR=t_zcbd.YEAR and t1.MTH=t_zcbd.MTH and t1.CUST_ID=t_zcbd.CUST_ID and t1.AFA_SEC_EMPID=t_zcbd.AFA_SEC_EMPID
left join DM.T_EVT_EMPCUS_ODI_TRD_M_D t_ptjy		--Ա���ͻ���ͨ����
	on t1.YEAR=t_ptjy.YEAR and t1.MTH=t_ptjy.MTH and t1.CUST_ID=t_ptjy.CUST_ID and t1.AFA_SEC_EMPID=t_ptjy.AFA_SEC_EMPID
left join DM.T_EVT_EMPCUS_ODI_INCM_M_D t_ptsr	--Ա���ͻ���ͨ����
	on t1.YEAR=t_ptsr.YEAR and t1.MTH=t_ptsr.MTH and t1.CUST_ID=t_ptsr.CUST_ID and t1.AFA_SEC_EMPID=t_ptsr.AFA_SEC_EMPID
left join DM.T_EVT_EMPCUS_CRED_INCM_M_D t_xysr	--Ա���ͻ���������
	on t1.YEAR=t_xysr.YEAR and t1.MTH=t_xysr.MTH and t1.CUST_ID=t_xysr.CUST_ID and t1.AFA_SEC_EMPID=t_xysr.AFA_SEC_EMPID
left join DM.T_AST_EMPCUS_APPTBUYB_M_D t_ydgh	--Լ�����ر�
	on t1.YEAR=t_ydgh.YEAR and t1.MTH=t_ydgh.MTH and t1.CUST_ID=t_ydgh.CUST_ID and t1.AFA_SEC_EMPID=t_ydgh.AFA_SEC_EMPID
left join
(
	select
		t1.YEAR
		,t1.MTH
		,t1.CUST_ID
		,t1.AFA_SEC_EMPID
		,sum(COALESCE(t1.GUAR_SECU_MVAL_FINAL,0)) as GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.STKPLG_FIN_BAL_FINAL,0)) as STKPLG_FIN_BAL_FINAL
		,sum(COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0)) as SH_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0)) as SZ_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0)) as SH_NOTS_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0)) as SZ_NOTS_GUAR_SECU_MVAL_FINAL
		,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0)) as PROP_FINAC_OUT_SIDE_BAL_FINAL
		,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0)) as ASSM_FINAC_OUT_SIDE_BAL_FINAL
		,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0)) as SM_LOAN_FINAC_OUT_BAL_FINAL
		,sum(COALESCE(t1.GUAR_SECU_MVAL_MDA,0)) as GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.STKPLG_FIN_BAL_MDA,0)) as STKPLG_FIN_BAL_MDA
		,sum(COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0)) as SH_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0)) as SZ_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0)) as SH_NOTS_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0)) as SZ_NOTS_GUAR_SECU_MVAL_MDA
		,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0)) as PROP_FINAC_OUT_SIDE_BAL_MDA
		,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0)) as ASSM_FINAC_OUT_SIDE_BAL_MDA
		,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0)) as SM_LOAN_FINAC_OUT_BAL_MDA
		,sum(COALESCE(t1.GUAR_SECU_MVAL_YDA,0)) as GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.STKPLG_FIN_BAL_YDA,0)) as STKPLG_FIN_BAL_YDA
		,sum(COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0)) as SH_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0)) as SZ_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0)) as SH_NOTS_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0)) as SZ_NOTS_GUAR_SECU_MVAL_YDA
		,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0)) as PROP_FINAC_OUT_SIDE_BAL_YDA
		,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0)) as ASSM_FINAC_OUT_SIDE_BAL_YDA
		,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0)) as SM_LOAN_FINAC_OUT_BAL_YDA
	from DM.T_AST_EMPCUS_STKPLG_M_D t1
	group by
		t1.YEAR
		,t1.MTH
		,t1.CUST_ID
		,t1.AFA_SEC_EMPID
) t_gpzy 									--��Ʊ��Ѻ��
	on t1.YEAR=t_gpzy.YEAR and t1.MTH=t_gpzy.MTH and t1.CUST_ID=t_gpzy.CUST_ID and t1.AFA_SEC_EMPID=t_gpzy.AFA_SEC_EMPID
where t1.YEAR=@V_YEAR and t1.MTH=@V_MONTH
 AND t_khsx.�Ƿ������˻� IS NOT NULL
 AND t_khsx.�Ƿ��Ʒ�¿ͻ� IS NOT NULL
 AND t_khsx.CUST_ID IS NOT NULL
 AND t_jg.WH_ORG_ID IS NOT NULL
group by
	t1.YEAR
	,t1.MTH
	,t_jg.WH_ORG_ID	
	,t_jg.HR_ORG_NAME
	,t_jg.SEPT_CORP_NAME
    ,t_jg.ORG_TYPE
	--ά����Ϣ
    ,t_khsx.�˻�����
	,t_khsx.�Ƿ������˻�
	,t_khsx.�Ƿ�������
	,t_khsx.�Ƿ�������	
	,t_khsx.�ʲ���
	;
END