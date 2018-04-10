
CREATE TABLE dm.T_AST_D_BRH
(	OCCUR_DT             numeric(8,0) NOT NULL,
	BRH_ID               varchar(30) NOT NULL,
	TOT_AST               numeric(38,8) NULL,
	SCDY_MVAL            numeric(38,8) NULL,
	STKF_MVAL            numeric(38,8) NULL,
	A_SHR_MVAL           numeric(38,8) NULL,
	NOTS_MVAL            numeric(38,8) NULL,
	OFFUND_MVAL          numeric(38,8) NULL,
	OPFUND_MVAL          numeric(38,8) NULL,
	SB_MVAL              numeric(38,8) NULL,
	IMGT_PD_MVAL         numeric(38,8) NULL,
	BANK_CHRM_MVAL       numeric(38,8) NULL,
	SECU_CHRM_MVAL       numeric(38,8) NULL,
	PSTK_OPTN_MVAL       numeric(38,8) NULL,
	B_SHR_MVAL           numeric(38,8) NULL,
	OUTMARK_MVAL         numeric(38,8) NULL,
	CPTL_BAL             numeric(38,8) NULL,
	NO_ARVD_CPTL         numeric(38,8) NULL,
	PTE_FUND_MVAL        numeric(38,8) NULL,
	CPTL_BAL_RMB         numeric(38,8) NULL,
	CPTL_BAL_HKD         numeric(38,8) NULL,
	CPTL_BAL_USD         numeric(38,8) NULL,
	FUND_SPACCT_MVAL     numeric(38,8) NULL,
	HGT_MVAL             numeric(38,8) NULL,
	SGT_MVAL             numeric(38,8) NULL,
	TOT_AST_CONTAIN_NOTS  numeric(38,8) NULL,
	BOND_MVAL            numeric(38,8) NULL,
	REPO_MVAL            numeric(38,8) NULL,
	TREA_REPO_MVAL       numeric(38,8) NULL,
	REPQ_MVAL            numeric(38,8) NULL,
	PO_FUND_MVAL         numeric(38,8) NULL,
	APPTBUYB_PLG_MVAL    numeric(38,8) NULL,
	OTH_PROD_MVAL        numeric(38,8) NULL,
	STKT_FUND_MVAL       numeric(38,8) NULL,
	OTH_AST_MVAL         numeric(38,8) NULL,
	CREDIT_MARG          numeric(38,8) NULL,
	CREDIT_NET_AST       numeric(38,8) NULL,
	PROD_TOT_MVAL        numeric(38,8) NULL,
	JQL9_MVAL            numeric(38,8) NULL,
	STKPLG_GUAR_SECMV    numeric(38,8) NULL,
	STKPLG_FIN_BAL       numeric(38,8) NULL,
	APPTBUYB_BAL         numeric(38,8) NULL,
	CRED_MARG            numeric(38,8) NULL,
	INTR_LIAB            numeric(38,8) NULL,
	FEE_LIAB             numeric(38,8) NULL,
	OTHLIAB              numeric(38,8) NULL,
	FIN_LIAB             numeric(38,8) NULL,
	CRDT_STK_LIAB        numeric(38,8) NULL,
	CREDIT_TOT_AST        numeric(38,8) NULL,
	CREDIT_TOT_LIAB      numeric(38,8) NULL,
	APPTBUYB_GUAR_SECMV  numeric(38,8) NULL,
	CREDIT_GUAR_SECMV    numeric(38,8) NULL
);



COMMENT ON TABLE dm.T_AST_D_BRH IS 'Ӫҵ���ʲ�_�ձ�';




COMMENT ON COLUMN dm.T_AST_D_BRH.OCCUR_DT IS 'ҵ������';




COMMENT ON COLUMN dm.T_AST_D_BRH.JQL9_MVAL IS '������9��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.SCDY_MVAL IS '������ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.STKF_MVAL IS '�ɻ���ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.A_SHR_MVAL IS 'A����ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.NOTS_MVAL IS '���۹���ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.OFFUND_MVAL IS '���ڻ�����ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.OPFUND_MVAL IS '���������ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.SB_MVAL IS '������ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.IMGT_PD_MVAL IS '�ʹܲ�Ʒ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.BANK_CHRM_MVAL IS '���������ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.SECU_CHRM_MVAL IS '֤ȯ�����ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.PSTK_OPTN_MVAL IS '������Ȩ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.B_SHR_MVAL IS 'B����ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.OUTMARK_MVAL IS '������ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.CPTL_BAL IS '�ʽ����';




COMMENT ON COLUMN dm.T_AST_D_BRH.NO_ARVD_CPTL IS 'δ�����ʽ�';




COMMENT ON COLUMN dm.T_AST_D_BRH.PTE_FUND_MVAL IS '˽ļ������ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.CPTL_BAL_RMB IS '�ʽ���������';




COMMENT ON COLUMN dm.T_AST_D_BRH.CPTL_BAL_HKD IS '�ʽ����۱�';




COMMENT ON COLUMN dm.T_AST_D_BRH.CPTL_BAL_USD IS '�ʽ������Ԫ';




COMMENT ON COLUMN dm.T_AST_D_BRH.FUND_SPACCT_MVAL IS '����ר����ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.HGT_MVAL IS '����ͨ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.SGT_MVAL IS '���ͨ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.TOT_AST_CONTAIN_NOTS IS '���ʲ�_�����۹�';




COMMENT ON COLUMN dm.T_AST_D_BRH.BOND_MVAL IS 'ծȯ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.REPO_MVAL IS '�ع���ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.TREA_REPO_MVAL IS '��ծ�ع���ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.REPQ_MVAL IS '���ۻع���ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.PO_FUND_MVAL IS '��ļ������ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.APPTBUYB_PLG_MVAL IS 'Լ��������Ѻ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.OTH_PROD_MVAL IS '������Ʒ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.STKT_FUND_MVAL IS '��Ʊ�ͻ�����ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.OTH_AST_MVAL IS '�����ʲ���ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.CREDIT_MARG IS '������ȯ��֤��';




COMMENT ON COLUMN dm.T_AST_D_BRH.CREDIT_NET_AST IS '������ȯ���ʲ�';




COMMENT ON COLUMN dm.T_AST_D_BRH.PROD_TOT_MVAL IS '��Ʒ����ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.TOT_AST IS '���ʲ�';




COMMENT ON COLUMN dm.T_AST_D_BRH.STKPLG_GUAR_SECMV IS '��Ʊ��Ѻ����֤ȯ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.STKPLG_FIN_BAL IS '��Ʊ��Ѻ�������';




COMMENT ON COLUMN dm.T_AST_D_BRH.APPTBUYB_BAL IS 'Լ���������';




COMMENT ON COLUMN dm.T_AST_D_BRH.INTR_LIAB IS '��Ϣ��ծ';




COMMENT ON COLUMN dm.T_AST_D_BRH.FEE_LIAB IS '���ø�ծ';




COMMENT ON COLUMN dm.T_AST_D_BRH.OTHLIAB IS '������ծ';




COMMENT ON COLUMN dm.T_AST_D_BRH.CRED_MARG IS '���ñ�֤��';




COMMENT ON COLUMN dm.T_AST_D_BRH.FIN_LIAB IS '���ʸ�ծ';




COMMENT ON COLUMN dm.T_AST_D_BRH.CRDT_STK_LIAB IS '��ȯ��ծ';




COMMENT ON COLUMN dm.T_AST_D_BRH.BRH_ID IS 'Ӫҵ������';




COMMENT ON COLUMN dm.T_AST_D_BRH.CREDIT_TOT_AST IS '������ȯ���ʲ�';




COMMENT ON COLUMN dm.T_AST_D_BRH.CREDIT_TOT_LIAB IS '������ȯ�ܸ�ծ';




COMMENT ON COLUMN dm.T_AST_D_BRH.APPTBUYB_GUAR_SECMV IS 'Լ�����ص���֤ȯ��ֵ';




COMMENT ON COLUMN dm.T_AST_D_BRH.CREDIT_GUAR_SECMV IS '������ȯ����֤ȯ��ֵ';



ALTER TABLE dm.T_AST_D_BRH
	ADD PRIMARY KEY (OCCUR_DT,BRH_ID);



CREATE TABLE dm.T_AST_M_BRH
(	YEAR                 varchar(4) NOT NULL,
	MTH                  varchar(2) NOT NULL,
	BRH_ID               varchar(30) NOT NULL,
	OCCUR_DT             numeric(8,0) NULL,
	TOT_AST_MDA           numeric(38,8) NULL,
	TOT_AST_YDA           numeric(38,8) NULL,
	SCDY_MVAL_MDA        numeric(38,8) NULL,
	SCDY_MVAL_YDA        numeric(38,8) NULL,
	STKF_MVAL_MDA        numeric(38,8) NULL,
	STKF_MVAL_YDA        numeric(38,8) NULL,
	A_SHR_MVAL_MDA       numeric(38,8) NULL,
	A_SHR_MVAL_YDA       numeric(38,8) NULL,
	NOTS_MVAL_MDA        numeric(38,8) NULL,
	NOTS_MVAL_YDA        numeric(38,8) NULL,
	OFFUND_MVAL_MDA      numeric(38,8) NULL,
	OFFUND_MVAL_YDA      numeric(38,8) NULL,
	OPFUND_MVAL_MDA      numeric(38,8) NULL,
	OPFUND_MVAL_YDA      numeric(38,8) NULL,
	SB_MVAL_MDA          numeric(38,8) NULL,
	SB_MVAL_YDA          numeric(38,8) NULL,
	IMGT_PD_MVAL_MDA     numeric(38,8) NULL,
	IMGT_PD_MVAL_YDA     numeric(38,8) NULL,
	BANK_CHRM_MVAL_YDA   numeric(38,8) NULL,
	BANK_CHRM_MVAL_MDA   numeric(38,8) NULL,
	SECU_CHRM_MVAL_MDA   numeric(38,8) NULL,
	SECU_CHRM_MVAL_YDA   numeric(38,8) NULL,
	PSTK_OPTN_MVAL_MDA   numeric(38,8) NULL,
	PSTK_OPTN_MVAL_YDA   numeric(38,8) NULL,
	B_SHR_MVAL_MDA       numeric(38,8) NULL,
	B_SHR_MVAL_YDA       numeric(38,8) NULL,
	OUTMARK_MVAL_MDA     numeric(38,8) NULL,
	OUTMARK_MVAL_YDA     numeric(38,8) NULL,
	CPTL_BAL_MDA         numeric(38,8) NULL,
	CPTL_BAL_YDA         numeric(38,8) NULL,
	NO_ARVD_CPTL_MDA     numeric(38,8) NULL,
	NO_ARVD_CPTL_YDA     numeric(38,8) NULL,
	PTE_FUND_MVAL_MDA    numeric(38,8) NULL,
	PTE_FUND_MVAL_YDA    numeric(38,8) NULL,
	CPTL_BAL_RMB_MDA     numeric(38,8) NULL,
	CPTL_BAL_RMB_YDA     numeric(38,8) NULL,
	CPTL_BAL_HKD_MDA     numeric(38,8) NULL,
	CPTL_BAL_HKD_YDA     numeric(38,8) NULL,
	CPTL_BAL_USD_MDA     numeric(38,8) NULL,
	CPTL_BAL_USD_YDA     numeric(38,8) NULL,
	FUND_SPACCT_MVAL_MDA numeric(38,8) NULL,
	FUND_SPACCT_MVAL_YDA numeric(38,8) NULL,
	HGT_MVAL_MDA         numeric(38,8) NULL,
	HGT_MVAL_YDA         numeric(38,8) NULL,
	SGT_MVAL_MDA         numeric(38,8) NULL,
	SGT_MVAL_YDA         numeric(38,8) NULL,
	TOT_AST_CONTAIN_NOTS_MDA numeric(38,8) NULL,
	TOT_AST_CONTAIN_NOTS_YDA numeric(38,8) NULL,
	BOND_MVAL_MDA        numeric(38,8) NULL,
	BOND_MVAL_YDA        numeric(38,8) NULL,
	REPO_MVAL_MDA        numeric(38,8) NULL,
	REPO_MVAL_YDA        numeric(38,8) NULL,
	TREA_REPO_MVAL_MDA   numeric(38,8) NULL,
	TREA_REPO_MVAL_YDA   numeric(38,8) NULL,
	REPQ_MVAL_MDA        numeric(38,8) NULL,
	REPQ_MVAL_YDA        numeric(38,8) NULL,
	PO_FUND_MVAL_MDA     numeric(38,8) NULL,
	PO_FUND_MVAL_YDA     numeric(38,8) NULL,
	APPTBUYB_PLG_MVAL_MDA numeric(38,8) NULL,
	APPTBUYB_PLG_MVAL_YDA numeric(38,8) NULL,
	OTH_PROD_MVAL_MDA    numeric(38,8) NULL,
	STKT_FUND_MVAL_MDA   numeric(38,8) NULL,
	OTH_AST_MVAL_MDA     numeric(38,8) NULL,
	OTH_PROD_MVAL_YDA    numeric(38,8) NULL,
	APPTBUYB_BAL_YDA     numeric(38,8) NULL,
	CREDIT_MARG_MDA      numeric(38,8) NULL,
	CREDIT_MARG_YDA      numeric(38,8) NULL,
	CREDIT_NET_AST_MDA   numeric(38,8) NULL,
	CREDIT_NET_AST_YDA   numeric(38,8) NULL,
	PROD_TOT_MVAL_MDA    numeric(38,8) NULL,
	PROD_TOT_MVAL_YDA    numeric(38,8) NULL,
	JQL9_MVAL_MDA        numeric(38,8) NULL,
	JQL9_MVAL_YDA        numeric(38,8) NULL,
	STKPLG_GUAR_SECMV_MDA numeric(38,8) NULL,
	STKPLG_GUAR_SECMV_YDA numeric(38,8) NULL,
	STKPLG_FIN_BAL_MDA   numeric(38,8) NULL,
	STKPLG_FIN_BAL_YDA   numeric(38,8) NULL,
	APPTBUYB_BAL_MDA     numeric(38,8) NULL,
	CRED_MARG_MDA        numeric(38,8) NULL,
	CRED_MARG_YDA        numeric(38,8) NULL,
	INTR_LIAB_MDA        numeric(38,8) NULL,
	INTR_LIAB_YDA        numeric(38,8) NULL,
	FEE_LIAB_MDA         numeric(38,8) NULL,
	FEE_LIAB_YDA         numeric(38,8) NULL,
	OTHLIAB_MDA          numeric(38,8) NULL,
	OTHLIAB_YDA          numeric(38,8) NULL,
	FIN_LIAB_MDA         numeric(38,8) NULL,
	CRDT_STK_LIAB_YDA    numeric(38,8) NULL,
	CRDT_STK_LIAB_MDA    numeric(38,8) NULL,
	FIN_LIAB_YDA         numeric(38,8) NULL,
	CREDIT_TOT_AST_MDA    numeric(38,8) NULL,
	CREDIT_TOT_AST_YDA    numeric(38,8) NULL,
	CREDIT_TOT_LIAB_MDA  numeric(38,8) NULL,
	CREDIT_TOT_LIAB_YDA  numeric(38,8) NULL,
	APPTBUYB_GUAR_SECMV_MDA numeric(38,8) NULL,
	APPTBUYB_GUAR_SECMV_YDA numeric(38,8) NULL,
	CREDIT_GUAR_SECMV_MDA numeric(38,8) NULL,
	CREDIT_GUAR_SECMV_YDA numeric(38,8) NULL
);



COMMENT ON TABLE dm.T_AST_M_BRH IS 'Ӫҵ���ʲ�_�±�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OCCUR_DT IS 'ҵ������';




COMMENT ON COLUMN dm.T_AST_M_BRH.JQL9_MVAL_MDA IS '������9��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SCDY_MVAL_MDA IS '������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.STKF_MVAL_MDA IS '�ɻ���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.A_SHR_MVAL_MDA IS 'A����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.NOTS_MVAL_MDA IS '���۹���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OFFUND_MVAL_MDA IS '���ڻ�����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OPFUND_MVAL_MDA IS '���������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SB_MVAL_MDA IS '������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.IMGT_PD_MVAL_MDA IS '�ʹܲ�Ʒ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.BANK_CHRM_MVAL_MDA IS '���������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SECU_CHRM_MVAL_MDA IS '֤ȯ�����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PSTK_OPTN_MVAL_MDA IS '������Ȩ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.B_SHR_MVAL_MDA IS 'B����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OUTMARK_MVAL_MDA IS '������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_MDA IS '�ʽ����_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.NO_ARVD_CPTL_MDA IS 'δ�����ʽ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PTE_FUND_MVAL_MDA IS '˽ļ������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_RMB_MDA IS '�ʽ���������_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_HKD_MDA IS '�ʽ����۱�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_USD_MDA IS '�ʽ������Ԫ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.FUND_SPACCT_MVAL_MDA IS '����ר����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.HGT_MVAL_MDA IS '����ͨ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SGT_MVAL_MDA IS '���ͨ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.TOT_AST_CONTAIN_NOTS_MDA IS '���ʲ�_�����۹�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.BOND_MVAL_MDA IS 'ծȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.REPO_MVAL_MDA IS '�ع���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.TREA_REPO_MVAL_MDA IS '��ծ�ع���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.REPQ_MVAL_MDA IS '���ۻع���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PO_FUND_MVAL_MDA IS '��ļ������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.APPTBUYB_PLG_MVAL_MDA IS 'Լ��������Ѻ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OTH_PROD_MVAL_MDA IS '������Ʒ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.STKT_FUND_MVAL_MDA IS '��Ʊ�ͻ�����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OTH_AST_MVAL_MDA IS '�����ʲ���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_MARG_MDA IS '������ȯ��֤��_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_NET_AST_MDA IS '������ȯ���ʲ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PROD_TOT_MVAL_MDA IS '��Ʒ����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.TOT_AST_MDA IS '���ʲ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.STKPLG_GUAR_SECMV_MDA IS '��Ʊ��Ѻ����֤ȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.STKPLG_FIN_BAL_MDA IS '��Ʊ��Ѻ�������_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.APPTBUYB_BAL_MDA IS 'Լ���������_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.INTR_LIAB_MDA IS '��Ϣ��ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.FEE_LIAB_MDA IS '���ø�ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OTHLIAB_MDA IS '������ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CRED_MARG_MDA IS '���ñ�֤��_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.FIN_LIAB_MDA IS '���ʸ�ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CRDT_STK_LIAB_MDA IS '��ȯ��ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.BRH_ID IS 'Ӫҵ������';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_TOT_AST_MDA IS '������ȯ���ʲ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_TOT_LIAB_MDA IS '������ȯ�ܸ�ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.APPTBUYB_GUAR_SECMV_MDA IS 'Լ�����ص���֤ȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_GUAR_SECMV_MDA IS '������ȯ����֤ȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.TOT_AST_YDA IS '���ʲ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SCDY_MVAL_YDA IS '������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.STKF_MVAL_YDA IS '�ɻ���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.A_SHR_MVAL_YDA IS 'A����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.NOTS_MVAL_YDA IS '���۹���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OFFUND_MVAL_YDA IS '���ڻ�����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OPFUND_MVAL_YDA IS '���������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SB_MVAL_YDA IS '������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.IMGT_PD_MVAL_YDA IS '�ʹܲ�Ʒ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.BANK_CHRM_MVAL_YDA IS '���������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SECU_CHRM_MVAL_YDA IS '֤ȯ�����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PSTK_OPTN_MVAL_YDA IS '������Ȩ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.B_SHR_MVAL_YDA IS 'B����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OUTMARK_MVAL_YDA IS '������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_YDA IS '�ʽ����_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.NO_ARVD_CPTL_YDA IS 'δ�����ʽ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PTE_FUND_MVAL_YDA IS '˽ļ������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_RMB_YDA IS '�ʽ���������_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_HKD_YDA IS '�ʽ����۱�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CPTL_BAL_USD_YDA IS '�ʽ������Ԫ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.FUND_SPACCT_MVAL_YDA IS '����ר����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.HGT_MVAL_YDA IS '����ͨ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.SGT_MVAL_YDA IS '���ͨ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.TOT_AST_CONTAIN_NOTS_YDA IS '���ʲ�_�����۹�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.BOND_MVAL_YDA IS 'ծȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.REPO_MVAL_YDA IS '�ع���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.TREA_REPO_MVAL_YDA IS '��ծ�ع���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.REPQ_MVAL_YDA IS '���ۻع���ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PO_FUND_MVAL_YDA IS '��ļ������ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.APPTBUYB_PLG_MVAL_YDA IS 'Լ��������Ѻ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OTH_PROD_MVAL_YDA IS '������Ʒ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_MARG_YDA IS '������ȯ��֤��_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_NET_AST_YDA IS '������ȯ���ʲ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.PROD_TOT_MVAL_YDA IS '��Ʒ����ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.JQL9_MVAL_YDA IS '������9��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.STKPLG_GUAR_SECMV_YDA IS '��Ʊ��Ѻ����֤ȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.STKPLG_FIN_BAL_YDA IS '��Ʊ��Ѻ�������_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.APPTBUYB_BAL_YDA IS 'Լ���������_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CRED_MARG_YDA IS '���ñ�֤��_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.INTR_LIAB_YDA IS '��Ϣ��ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.FEE_LIAB_YDA IS '���ø�ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.OTHLIAB_YDA IS '������ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CRDT_STK_LIAB_YDA IS '��ȯ��ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.FIN_LIAB_YDA IS '���ʸ�ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_TOT_LIAB_YDA IS '������ȯ�ܸ�ծ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_TOT_AST_YDA IS '������ȯ���ʲ�_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.APPTBUYB_GUAR_SECMV_YDA IS 'Լ�����ص���֤ȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.CREDIT_GUAR_SECMV_YDA IS '������ȯ����֤ȯ��ֵ_���վ�';




COMMENT ON COLUMN dm.T_AST_M_BRH.YEAR IS '��';




COMMENT ON COLUMN dm.T_AST_M_BRH.MTH IS '��';



ALTER TABLE dm.T_AST_M_BRH
	ADD PRIMARY KEY (YEAR,MTH,BRH_ID);


