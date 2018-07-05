
CREATE TABLE DM.T_REPORT_PAYF_VOU_SALE_STATS_M
(	YEAR                 varchar(4) NULL,
	MTH                  varchar(2) NULL,
	SEPT_CORP_DEVLOP_SEG varchar(30) NULL,
	SEPT_CORP            varchar(50) NULL,
	BRH                  varchar(60) NULL,
	PAYF_VOU_SALE_AMT_M  numeric(38,8) NULL,
	PAYF_VOU_SALE_CUST_NUM_M numeric(38,8) NULL,
	PAYF_VOU_SALE_CNT_M  numeric(38,8) NULL,
	PAYF_VOU_SALE_AMT_TY numeric(38,8) NULL
);



COMMENT ON TABLE DM.T_REPORT_PAYF_VOU_SALE_STATS_M IS '收益凭证销售统计月报';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.YEAR IS '年';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.MTH IS '月';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.SEPT_CORP_DEVLOP_SEG IS '分公司发展阶段';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.SEPT_CORP IS '分公司';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.BRH IS '营业部';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.PAYF_VOU_SALE_AMT_M IS '收益凭证销售金额_本月';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.PAYF_VOU_SALE_CUST_NUM_M IS '收益凭证销售客户数_本月';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.PAYF_VOU_SALE_CNT_M IS '收益凭证销售笔数_本月';




COMMENT ON COLUMN DM.T_REPORT_PAYF_VOU_SALE_STATS_M.PAYF_VOU_SALE_AMT_TY IS '收益凭证销售金额_本年';

