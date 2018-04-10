
CREATE TABLE dm.T_EVT_INCM_D_EMP
(	OCCUR_DT             numeric(8,0) NOT NULL,
	EMP_ID               varchar(30) NOT NULL,
	NET_CMS              numeric(38,8) NULL,
	GROSS_CMS            numeric(38,8) NULL,
	SCDY_CMS             numeric(38,8) NULL,
	SCDY_NET_CMS         numeric(38,8) NULL,
	SCDY_TRAN_FEE        numeric(38,8) NULL,
	ODI_TRD_TRAN_FEE     numeric(38,8) NULL,
	ODI_TRD_STP_TAX      numeric(38,8) NULL,
	ODI_TRD_HANDLE_FEE   numeric(38,8) NULL,
	ODI_TRD_SEC_RGLT_FEE numeric(38,8) NULL,
	ODI_TRD_ORDR_FEE     numeric(38,8) NULL,
	ODI_TRD_OTH_FEE      numeric(38,8) NULL,
	CRED_TRD_TRAN_FEE    numeric(38,8) NULL,
	CRED_TRD_STP_TAX     numeric(38,8) NULL,
	CRED_TRD_HANDLE_FEE  numeric(38,8) NULL,
	CRED_TRD_SEC_RGLT_FEE numeric(38,8) NULL,
	CRED_TRD_ORDR_FEE    numeric(38,8) NULL,
	CRED_TRD_OTH_FEE     numeric(38,8) NULL,
	STKF_CMS             numeric(38,8) NULL,
	STKF_TRAN_FEE        numeric(38,8) NULL,
	STKF_NET_CMS         numeric(38,8) NULL,
	BOND_CMS             numeric(38,8) NULL,
	BOND_NET_CMS         numeric(38,8) NULL,
	REPQ_CMS             numeric(38,8) NULL,
	REPQ_NET_CMS         numeric(38,8) NULL,
	HGT_CMS              numeric(38,8) NULL,
	HGT_NET_CMS          numeric(38,8) NULL,
	HGT_TRAN_FEE         numeric(38,8) NULL,
	SGT_CMS              numeric(38,8) NULL,
	SGT_NET_CMS          numeric(38,8) NULL,
	SGT_TRAN_FEE         numeric(38,8) NULL,
	BGDL_CMS             numeric(38,8) NULL,
	BGDL_NET_CMS         numeric(38,8) NULL,
	BGDL_TRAN_FEE        numeric(38,8) NULL,
	PSTK_OPTN_CMS        numeric(38,8) NULL,
	PSTK_OPTN_NET_CMS    numeric(38,8) NULL,
	CREDIT_ODI_CMS       numeric(38,8) NULL,
	CREDIT_ODI_NET_CMS   numeric(38,8) NULL,
	CREDIT_ODI_TRAN_FEE  numeric(38,8) NULL,
	CREDIT_CRED_CMS      numeric(38,8) NULL,
	CREDIT_CRED_NET_CMS  numeric(38,8) NULL,
	CREDIT_CRED_TRAN_FEE numeric(38,8) NULL,
	FIN_RECE_INT         numeric(38,8) NULL,
	FIN_PAIDINT          numeric(38,8) NULL,
	STKPLG_CMS           numeric(38,8) NULL,
	STKPLG_NET_CMS       numeric(38,8) NULL,
	STKPLG_PAIDINT       numeric(38,8) NULL,
	STKPLG_RECE_INT      numeric(38,8) NULL,
	APPTBUYB_CMS         numeric(38,8) NULL,
	APPTBUYB_NET_CMS     numeric(38,8) NULL,
	APPTBUYB_PAIDINT     numeric(38,8) NULL,
	FIN_IE               numeric(38,8) NULL,
	CRDT_STK_IE          numeric(38,8) NULL,
	OTH_IE               numeric(38,8) NULL,
	FEE_RECE_INT         numeric(38,8) NULL,
	OTH_RECE_INT         numeric(38,8) NULL,
	CREDIT_CPTL_COST     numeric(38,8) NULL
);



COMMENT ON TABLE dm.T_EVT_INCM_D_EMP IS '员工收入表_日表';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.EMP_ID IS '员工编码';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.OCCUR_DT IS '业务日期';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.SCDY_CMS IS '二级佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.SCDY_NET_CMS IS '二级净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.SCDY_TRAN_FEE IS '二级过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.ODI_TRD_TRAN_FEE IS '普通交易过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.ODI_TRD_STP_TAX IS '普通交易印花税';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.ODI_TRD_HANDLE_FEE IS '普通交易经手费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.ODI_TRD_SEC_RGLT_FEE IS '普通交易证管费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.ODI_TRD_OTH_FEE IS '普通交易其他费用';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.STKF_CMS IS '股基佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.STKF_TRAN_FEE IS '股基过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.STKF_NET_CMS IS '股基净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.BOND_CMS IS '债券佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.BOND_NET_CMS IS '债券净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.REPQ_CMS IS '报价回购佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.REPQ_NET_CMS IS '报价回购净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.HGT_CMS IS '沪港通佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.HGT_NET_CMS IS '沪港通净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.HGT_TRAN_FEE IS '沪港通过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.SGT_CMS IS '深港通佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.SGT_NET_CMS IS '深港通净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.SGT_TRAN_FEE IS '深港通过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.BGDL_CMS IS '大宗交易佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.BGDL_NET_CMS IS '大宗交易净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.BGDL_TRAN_FEE IS '大宗交易过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.PSTK_OPTN_CMS IS '个股期权佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.PSTK_OPTN_NET_CMS IS '个股期权净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.ODI_TRD_ORDR_FEE IS '普通交易委托费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CREDIT_ODI_CMS IS '融资融券普通佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CREDIT_ODI_NET_CMS IS '融资融券普通净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CREDIT_ODI_TRAN_FEE IS '融资融券普通过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CREDIT_CRED_CMS IS '融资融券信用佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CREDIT_CRED_NET_CMS IS '融资融券信用净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CREDIT_CRED_TRAN_FEE IS '融资融券信用过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.FIN_RECE_INT IS '融资应收利息';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.FIN_PAIDINT IS '融资实收利息';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.STKPLG_CMS IS '股票质押佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.STKPLG_NET_CMS IS '股票质押净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.STKPLG_PAIDINT IS '股票质押实收利息';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.STKPLG_RECE_INT IS '股票质押应收利息';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.APPTBUYB_CMS IS '约定购回佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.APPTBUYB_NET_CMS IS '约定购回净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.APPTBUYB_PAIDINT IS '约定购回实收利息';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.FIN_IE IS '融资利息支出';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CRDT_STK_IE IS '融券利息支出';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.OTH_IE IS '其他利息支出';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.FEE_RECE_INT IS '费用应收利息';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.OTH_RECE_INT IS '其他应收利息';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CREDIT_CPTL_COST IS '融资融券资金成本';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.NET_CMS IS '净佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.GROSS_CMS IS '毛佣金';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CRED_TRD_TRAN_FEE IS '信用交易过户费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CRED_TRD_STP_TAX IS '信用交易印花税';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CRED_TRD_HANDLE_FEE IS '信用交易经手费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CRED_TRD_SEC_RGLT_FEE IS '信用交易证管费';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CRED_TRD_OTH_FEE IS '信用交易其他费用';




COMMENT ON COLUMN dm.T_EVT_INCM_D_EMP.CRED_TRD_ORDR_FEE IS '信用交易委托费';



ALTER TABLE dm.T_EVT_INCM_D_EMP
	ADD PRIMARY KEY (OCCUR_DT,EMP_ID);



CREATE TABLE dm.T_EVT_INCM_M_EMP
(	YEAR                 varchar(4) NOT NULL,
	MTH                  varchar(2) NOT NULL,
	EMP_ID               varchar(30) NOT NULL,
	OCCUR_DT             numeric(8,0) NULL,
	NET_CMS_MTD          numeric(38,8) NULL,
	GROSS_CMS_MTD        numeric(38,8) NULL,
	SCDY_CMS_MTD         numeric(38,8) NULL,
	SCDY_NET_CMS_MTD     numeric(38,8) NULL,
	SCDY_TRAN_FEE_MTD    numeric(38,8) NULL,
	ODI_TRD_TRAN_FEE_MTD numeric(38,8) NULL,
	ODI_TRD_STP_TAX_MTD  numeric(38,8) NULL,
	ODI_TRD_HANDLE_FEE_MTD numeric(38,8) NULL,
	ODI_TRD_SEC_RGLT_FEE_MTD numeric(38,8) NULL,
	ODI_TRD_ORDR_FEE_MTD numeric(38,8) NULL,
	ODI_TRD_OTH_FEE_MTD  numeric(38,8) NULL,
	CRED_TRD_TRAN_FEE_MTD numeric(38,8) NULL,
	CRED_TRD_STP_TAX_MTD numeric(38,8) NULL,
	CRED_TRD_HANDLE_FEE_MTD numeric(38,8) NULL,
	CRED_TRD_SEC_RGLT_FEE_MTD numeric(38,8) NULL,
	CRED_TRD_ORDR_FEE_MTD numeric(38,8) NULL,
	CRED_TRD_OTH_FEE_MTD numeric(38,8) NULL,
	STKF_CMS_MTD         numeric(38,8) NULL,
	STKF_TRAN_FEE_MTD    numeric(38,8) NULL,
	STKF_NET_CMS_MTD     numeric(38,8) NULL,
	BOND_CMS_MTD         numeric(38,8) NULL,
	BOND_NET_CMS_MTD     numeric(38,8) NULL,
	REPQ_CMS_MTD         numeric(38,8) NULL,
	REPQ_NET_CMS_MTD     numeric(38,8) NULL,
	HGT_CMS_MTD          numeric(38,8) NULL,
	HGT_NET_CMS_MTD      numeric(38,8) NULL,
	HGT_TRAN_FEE_MTD     numeric(38,8) NULL,
	SGT_CMS_MTD          numeric(38,8) NULL,
	SGT_NET_CMS_MTD      numeric(38,8) NULL,
	SGT_TRAN_FEE_MTD     numeric(38,8) NULL,
	BGDL_CMS_MTD         numeric(38,8) NULL,
	BGDL_NET_CMS_MTD     numeric(38,8) NULL,
	BGDL_TRAN_FEE_MTD    numeric(38,8) NULL,
	PSTK_OPTN_CMS_MTD    numeric(38,8) NULL,
	PSTK_OPTN_NET_CMS_MTD numeric(38,8) NULL,
	CREDIT_ODI_CMS_MTD   numeric(38,8) NULL,
	CREDIT_ODI_NET_CMS_MTD numeric(38,8) NULL,
	CREDIT_ODI_TRAN_FEE_MTD numeric(38,8) NULL,
	CREDIT_CRED_CMS_MTD  numeric(38,8) NULL,
	CREDIT_CRED_NET_CMS_MTD numeric(38,8) NULL,
	CREDIT_CRED_TRAN_FEE_MTD numeric(38,8) NULL,
	FIN_RECE_INT_MTD     numeric(38,8) NULL,
	FIN_PAIDINT_MTD      numeric(38,8) NULL,
	STKPLG_CMS_MTD       numeric(38,8) NULL,
	STKPLG_NET_CMS_MTD   numeric(38,8) NULL,
	STKPLG_PAIDINT_MTD   numeric(38,8) NULL,
	STKPLG_RECE_INT_MTD  numeric(38,8) NULL,
	APPTBUYB_CMS_MTD     numeric(38,8) NULL,
	APPTBUYB_NET_CMS_MTD numeric(38,8) NULL,
	APPTBUYB_PAIDINT_MTD numeric(38,8) NULL,
	FIN_IE_MTD           numeric(38,8) NULL,
	CRDT_STK_IE_MTD      numeric(38,8) NULL,
	OTH_IE_MTD           numeric(38,8) NULL,
	FEE_RECE_INT_MTD     numeric(38,8) NULL,
	OTH_RECE_INT_MTD     numeric(38,8) NULL,
	CREDIT_CPTL_COST_MTD numeric(38,8) NULL,
	NET_CMS_YTD          numeric(38,8) NULL,
	GROSS_CMS_YTD        numeric(38,8) NULL,
	SCDY_CMS_YTD         numeric(38,8) NULL,
	SCDY_NET_CMS_YTD     numeric(38,8) NULL,
	SCDY_TRAN_FEE_YTD    numeric(38,8) NULL,
	ODI_TRD_TRAN_FEE_YTD numeric(38,8) NULL,
	ODI_TRD_STP_TAX_YTD  numeric(38,8) NULL,
	ODI_TRD_HANDLE_FEE_YTD numeric(38,8) NULL,
	ODI_TRD_SEC_RGLT_FEE_YTD numeric(38,8) NULL,
	ODI_TRD_ORDR_FEE_YTD numeric(38,8) NULL,
	ODI_TRD_OTH_FEE_YTD  numeric(38,8) NULL,
	CRED_TRD_TRAN_FEE_YTD numeric(38,8) NULL,
	CRED_TRD_STP_TAX_YTD numeric(38,8) NULL,
	CRED_TRD_HANDLE_FEE_YTD numeric(38,8) NULL,
	CRED_TRD_SEC_RGLT_FEE_YTD numeric(38,8) NULL,
	CRED_TRD_ORDR_FEE_YTD numeric(38,8) NULL,
	CRED_TRD_OTH_FEE_YTD numeric(38,8) NULL,
	STKF_CMS_YTD         numeric(38,8) NULL,
	STKF_TRAN_FEE_YTD    numeric(38,8) NULL,
	STKF_NET_CMS_YTD     numeric(38,8) NULL,
	BOND_CMS_YTD         numeric(38,8) NULL,
	BOND_NET_CMS_YTD     numeric(38,8) NULL,
	REPQ_CMS_YTD         numeric(38,8) NULL,
	REPQ_NET_CMS_YTD     numeric(38,8) NULL,
	HGT_CMS_YTD          numeric(38,8) NULL,
	HGT_TRAN_FEE_YTD     numeric(38,8) NULL,
	SGT_CMS_YTD          numeric(38,8) NULL,
	SGT_NET_CMS_YTD      numeric(38,8) NULL,
	SGT_TRAN_FEE_YTD     numeric(38,8) NULL,
	BGDL_CMS_YTD         numeric(38,8) NULL,
	BGDL_NET_CMS_YTD     numeric(38,8) NULL,
	BGDL_TRAN_FEE_YTD    numeric(38,8) NULL,
	PSTK_OPTN_CMS_YTD    numeric(38,8) NULL,
	PSTK_OPTN_NET_CMS_YTD numeric(38,8) NULL,
	CREDIT_ODI_CMS_YTD   numeric(38,8) NULL,
	CREDIT_ODI_NET_CMS_YTD numeric(38,8) NULL,
	CREDIT_ODI_TRAN_FEE_YTD numeric(38,8) NULL,
	CREDIT_CRED_CMS_YTD  numeric(38,8) NULL,
	CREDIT_CRED_NET_CMS_YTD numeric(38,8) NULL,
	CREDIT_CRED_TRAN_FEE_YTD numeric(38,8) NULL,
	FIN_RECE_INT_YTD     numeric(38,8) NULL,
	FIN_PAIDINT_YTD      numeric(38,8) NULL,
	STKPLG_CMS_YTD       numeric(38,8) NULL,
	STKPLG_NET_CMS_YTD   numeric(38,8) NULL,
	STKPLG_PAIDINT_YTD   numeric(38,8) NULL,
	STKPLG_RECE_INT_YTD  numeric(38,8) NULL,
	APPTBUYB_CMS_YTD     numeric(38,8) NULL,
	APPTBUYB_NET_CMS_YTD numeric(38,8) NULL,
	APPTBUYB_PAIDINT_YTD numeric(38,8) NULL,
	FIN_IE_YTD           numeric(38,8) NULL,
	CRDT_STK_IE_YTD      numeric(38,8) NULL,
	OTH_IE_YTD           numeric(38,8) NULL,
	FEE_RECE_INT_YTD     numeric(38,8) NULL,
	OTH_RECE_INT_YTD     numeric(38,8) NULL,
	CREDIT_CPTL计_COST_YTD numeric(38,8) NULL
);



COMMENT ON TABLE dm.T_EVT_INCM_M_EMP IS '员工收入表_月表';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.EMP_ID IS '员工编码';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.OCCUR_DT IS '业务日期';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SCDY_CMS_MTD IS '二级佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SCDY_NET_CMS_MTD IS '二级净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SCDY_TRAN_FEE_MTD IS '二级过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_TRAN_FEE_MTD IS '普通交易过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_STP_TAX_MTD IS '普通交易印花税_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_HANDLE_FEE_MTD IS '普通交易经手费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_SEC_RGLT_FEE_MTD IS '普通交易证管费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_OTH_FEE_MTD IS '普通交易其他费用_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKF_CMS_MTD IS '股基佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKF_TRAN_FEE_MTD IS '股基过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKF_NET_CMS_MTD IS '股基净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BOND_CMS_MTD IS '债券佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BOND_NET_CMS_MTD IS '债券净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.REPQ_CMS_MTD IS '报价回购佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.REPQ_NET_CMS_MTD IS '报价回购净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.HGT_CMS_MTD IS '沪港通佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.HGT_NET_CMS_MTD IS '沪港通净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.HGT_TRAN_FEE_MTD IS '沪港通过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SGT_CMS_MTD IS '深港通佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SGT_NET_CMS_MTD IS '深港通净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SGT_TRAN_FEE_MTD IS '深港通过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BGDL_CMS_MTD IS '大宗交易佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BGDL_NET_CMS_MTD IS '大宗交易净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BGDL_TRAN_FEE_MTD IS '大宗交易过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.PSTK_OPTN_CMS_MTD IS '个股期权佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.PSTK_OPTN_NET_CMS_MTD IS '个股期权净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_ODI_CMS_MTD IS '融资融券普通佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_ODI_NET_CMS_MTD IS '融资融券普通净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_ODI_TRAN_FEE_MTD IS '融资融券普通过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CRED_CMS_MTD IS '融资融券信用佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CRED_NET_CMS_MTD IS '融资融券信用净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CRED_TRAN_FEE_MTD IS '融资融券信用过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FIN_RECE_INT_MTD IS '融资应收利息_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FIN_PAIDINT_MTD IS '融资实收利息_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_CMS_MTD IS '股票质押佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_NET_CMS_MTD IS '股票质押净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_PAIDINT_MTD IS '股票质押实收利息_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_RECE_INT_MTD IS '股票质押应收利息_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.APPTBUYB_CMS_MTD IS '约定购回佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.APPTBUYB_NET_CMS_MTD IS '约定购回净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.APPTBUYB_PAIDINT_MTD IS '约定购回实收利息_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FIN_IE_MTD IS '融资利息支出_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRDT_STK_IE_MTD IS '融券利息支出_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.OTH_IE_MTD IS '其他利息支出_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FEE_RECE_INT_MTD IS '费用应收利息_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.OTH_RECE_INT_MTD IS '其他应收利息_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CPTL_COST_MTD IS '融资融券资金成本_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.NET_CMS_MTD IS '净佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.GROSS_CMS_MTD IS '毛佣金_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_TRAN_FEE_MTD IS '信用交易过户费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_STP_TAX_MTD IS '信用交易印花税_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_HANDLE_FEE_MTD IS '信用交易经手费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_SEC_RGLT_FEE_MTD IS '信用交易证管费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_OTH_FEE_MTD IS '信用交易其他费用_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.NET_CMS_YTD IS '净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.GROSS_CMS_YTD IS '毛佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SCDY_CMS_YTD IS '二级佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SCDY_NET_CMS_YTD IS '二级净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SCDY_TRAN_FEE_YTD IS '二级过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_TRAN_FEE_YTD IS '普通交易过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_STP_TAX_YTD IS '普通交易印花税_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_HANDLE_FEE_YTD IS '普通交易经手费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_SEC_RGLT_FEE_YTD IS '普通交易证管费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_OTH_FEE_YTD IS '普通交易其他费用_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_TRAN_FEE_YTD IS '信用交易过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_STP_TAX_YTD IS '信用交易印花税_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_HANDLE_FEE_YTD IS '信用交易经手费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_SEC_RGLT_FEE_YTD IS '信用交易证管费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_OTH_FEE_YTD IS '信用交易其他费用_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKF_CMS_YTD IS '股基佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKF_TRAN_FEE_YTD IS '股基过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKF_NET_CMS_YTD IS '股基净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BOND_CMS_YTD IS '债券佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BOND_NET_CMS_YTD IS '债券净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.REPQ_CMS_YTD IS '报价回购佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.REPQ_NET_CMS_YTD IS '报价回购净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.HGT_CMS_YTD IS '沪港通佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.HGT_TRAN_FEE_YTD IS '沪港通过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SGT_CMS_YTD IS '深港通佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SGT_NET_CMS_YTD IS '深港通净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.SGT_TRAN_FEE_YTD IS '深港通过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BGDL_CMS_YTD IS '大宗交易佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BGDL_NET_CMS_YTD IS '大宗交易净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.BGDL_TRAN_FEE_YTD IS '大宗交易过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.PSTK_OPTN_CMS_YTD IS '个股期权佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.PSTK_OPTN_NET_CMS_YTD IS '个股期权净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_ODI_CMS_YTD IS '融资融券普通佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_ODI_NET_CMS_YTD IS '融资融券普通净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_ODI_TRAN_FEE_YTD IS '融资融券普通过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CRED_CMS_YTD IS '融资融券信用佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CRED_NET_CMS_YTD IS '融资融券信用净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CRED_TRAN_FEE_YTD IS '融资融券信用过户费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FIN_RECE_INT_YTD IS '融资应收利息_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FIN_PAIDINT_YTD IS '融资实收利息_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_CMS_YTD IS '股票质押佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_NET_CMS_YTD IS '股票质押净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_PAIDINT_YTD IS '股票质押实收利息_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.STKPLG_RECE_INT_YTD IS '股票质押应收利息_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.APPTBUYB_CMS_YTD IS '约定购回佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.APPTBUYB_NET_CMS_YTD IS '约定购回净佣金_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.APPTBUYB_PAIDINT_YTD IS '约定购回实收利息_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FIN_IE_YTD IS '融资利息支出_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRDT_STK_IE_YTD IS '融券利息支出_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.OTH_IE_YTD IS '其他利息支出_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.FEE_RECE_INT_YTD IS '费用应收利息_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.OTH_RECE_INT_YTD IS '其他应收利息_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CREDIT_CPTL计_COST_YTD IS '融资融券资金计成本_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.YEAR IS '年';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.MTH IS '月';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_ORDR_FEE_MTD IS '普通交易委托费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.ODI_TRD_ORDR_FEE_YTD IS '普通交易委托费_年累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_ORDR_FEE_MTD IS '信用交易委托费_月累计';




COMMENT ON COLUMN dm.T_EVT_INCM_M_EMP.CRED_TRD_ORDR_FEE_YTD IS '信用交易委托费_年累计';



ALTER TABLE dm.T_EVT_INCM_M_EMP
	ADD PRIMARY KEY (YEAR,MTH,EMP_ID);







