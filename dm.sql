CREATE PROCEDURE dm.P_ACC_CPTL_ACC(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: �ʽ��˻���Ϣά��
  ��д��: DCY
  ��������: 2017-11-20
  ��飺��ϴ�ʽ��˻��������õ�������Ϣ��ÿ�ո��£�ÿ�´洢
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
  DECLARE @V_MAX_DATE INT;
  
    SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1

  --PART0 ɾ����������
  DELETE FROM DM.T_ACC_CPTL_ACC WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
   --������ֵ:�õ�˽���Լ�ά����QUERY_SKB.YUNYING_07�����������    
  SET @V_MAX_DATE=(SELECT MAX(LOAD_DT) FROM QUERY_SKB.YUNYING_07);
  
  --PART0 ������������Ӷ���ʷ���һ����ʱ��
  SELECT 
   FARE_KIND
  ,MIN(CASE WHEN EXCHANGE_TYPE='1' THEN BALANCE_RATIO  END) AS SH_BALANCE_RATIO --����Ӷ����
  ,MIN(CASE WHEN EXCHANGE_TYPE='2' THEN BALANCE_RATIO  END) AS SZ_BALANCE_RATIO --����Ӷ����
  ,MIN(BALANCE_RATIO) AS OI_BALANCE_RATIO --��ͨӶ����
    
  INTO #TEMP_BALANCE_RATIO
	-- SELECT *
  FROM DBA.T_ODS_UF2_BFARE2
    WHERE FARE_TYPE='0'
  GROUP BY FARE_KIND
  ;
  
  --PART1 ��ÿ�ղɼ������ݷ�����ʱ��
 
	SELECT
	 OUF.FUND_ACCOUNT      AS CPTL_ACCT    --�ʽ��˺�
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --��
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --��
	,OUF.CLIENT_ID         AS CUST_ID      --�ͻ�����
	,DOH.PK_ORG            AS WH_ORG_ID    --�ֿ�������� 
	,CONVERT(VARCHAR,OUF.BRANCH_NO) AS HS_ORG_ID  --������������
	,CASE WHEN OUF.MAIN_FLAG='1' THEN '����' ELSE '����' END AS MAINSUB_FLAG --������־
	,UF.BANK_NO            AS DEPO_BANK --�������
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=UF.BANK_NO AND OUS.DICT_ENTRY=1601) AS DEPO_BANK_NAME    --�����������
	,OUF.FUNDACCT_STATUS   AS CPTL_ACC_STAT --�ʽ��˻�״̬
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUF.FUNDACCT_STATUS AND OUS.DICT_ENTRY=1000) AS CPTL_ACC_STAT_NAME    --�ʽ��˻�״̬����
	,OUF.ASSET_PROP        AS CPTL_ACC_TYPE --�ʽ��˻�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUF.ASSET_PROP AND OUS.DICT_ENTRY=3002) AS CPTL_ACC_TYPE_NAME    --�ʽ��˻���������
	,CONVERT(VARCHAR,OUF.CLIENT_GROUP)  AS CPTL_ACC_GROUP --�ʽ��˻�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUF.CLIENT_GROUP) AND OUS.DICT_ENTRY=1051) AS CPTL_ACC_GROUP_NAME    --�ʽ��˻���������
	,CASE WHEN YY.ZJZH IS NULL THEN 0 ELSE YY.ZHLX END AS IF_SPCA_ACCT --�Ƿ������˺� ��0���������˻���1�����⡢2��˽ļ��3������
	,ISNULL(TBR.SH_BALANCE_RATIO ,0) AS ODI_CMS_RATE --��ͨӶ���ʣ��û�����ͨӶ������䣨������
	,ISNULL(TBR.SH_BALANCE_RATIO ,0) AS SH_ODI_CMS_RATE --������ͨӶ����
	,ISNULL(TBR.SZ_BALANCE_RATIO ,0) AS SZ_ODI_CMS_RATE --������ͨӶ����
	,ISNULL(TBR2.SH_BALANCE_RATIO,0) AS CREDIT_CMS_RATE --������ȯӶ���ʣ��û�������Ӷ������� 
	,ISNULL(TBR2.SH_BALANCE_RATIO,0) AS SH_CRED_CMS_RATE --��������Ӷ����
	,ISNULL(TBR2.SZ_BALANCE_RATIO,0) AS SZ_CRED_CMS_RATE --��������Ӷ����
	,ISNULL(TBR3.OI_BALANCE_RATIO,0) AS GGT_CMS_RATE     --�۹�ͨӶ����   
	,ISNULL(TBR4.OI_BALANCE_RATIO,0) AS OFFUND_CMS_RATE  --���ڻ���Ӷ���� 
	,ISNULL(TBR5.OI_BALANCE_RATIO,0) AS WRNT_CMS_RATE    --Ȩ֤Ӷ���� 
	,ISNULL(TBR6.OI_BALANCE_RATIO,0) AS BGDL_CMS_RATE    --���ڽ���Ӷ���� 
	,OUF.OPEN_DATE         AS OACT_DT   --��������
	,OUF.CANCEL_DATE       AS CANCEL_DT --ע������
	,@V_BIN_DATE           AS LOAD_DT   --��ϴ����
	
	INTO #TEMP_CPTL_ACC
	
	FROM DBA.T_EDW_UF2_FUNDACCOUNT OUF
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUF.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL AND DOH.HR_NAME IS NOT NULL
    LEFT JOIN (--����������
				SELECT DISTINCT FUND_ACCOUNT,BANK_NO FROM DBA.T_ODS_UF2_FUND
				WHERE MONEY_TYPE='0' --���������
				)UF ON OUF.FUND_ACCOUNT=UF.FUND_ACCOUNT
	LEFT JOIN QUERY_SKB.YUNYING_07 YY  ON YY.LOAD_DT=@V_MAX_DATE AND OUF.FUND_ACCOUNT=YY.ZJZH              --�Ƿ������˺�
	LEFT JOIN #TEMP_BALANCE_RATIO TBR  ON SUBSTR(OUF.FARE_KIND_STR,5,4)= CONVERT(VARCHAR,TBR.FARE_KIND)    --��ͨӶ����  
	LEFT JOIN #TEMP_BALANCE_RATIO TBR2 ON SUBSTR(OUF.FARE_KIND_STR,34,4)= CONVERT(VARCHAR,TBR2.FARE_KIND)  --����Ӷ����
    LEFT JOIN #TEMP_BALANCE_RATIO TBR3 ON SUBSTR(OUF.FARE_KIND_STR,62,4)= CONVERT(VARCHAR,TBR3.FARE_KIND) --�۹�ͨӶ����    
    LEFT JOIN #TEMP_BALANCE_RATIO TBR4 ON SUBSTR(OUF.FARE_KIND_STR,13,4)= CONVERT(VARCHAR,TBR4.FARE_KIND) --���ڻ���Ӷ����	
    LEFT JOIN #TEMP_BALANCE_RATIO TBR5 ON SUBSTR(OUF.FARE_KIND_STR,25,4)= CONVERT(VARCHAR,TBR5.FARE_KIND) --Ȩ֤Ӷ����	
    LEFT JOIN #TEMP_BALANCE_RATIO TBR6 ON SUBSTR(OUF.FARE_KIND_STR,29,4)= CONVERT(VARCHAR,TBR6.FARE_KIND) --���ڽ���Ӷ����
    WHERE OUF.LOAD_DT=@V_BIN_DATE	
	;
	COMMIT;
	
	
	
	--2 ��󽫵���ͻ��������,�ڶ���ͬ�µĻ���ɾ������һ�µ�û��ɾ����������
	INSERT INTO DM.T_ACC_CPTL_ACC
	(
	 CPTL_ACCT           --�ʽ��˺�
    ,YEAR                --��
    ,MTH                 --��
    ,CUST_ID             --�ͻ�����
    ,WH_ORG_ID           --�ֿ��������
    ,HS_ORG_ID           --������������
    ,MAINSUB_FLAG        --������־
    ,DEPO_BANK           --�������
    ,DEPO_BANK_NAME      --�����������
    ,CPTL_ACC_STAT       --�ʽ��˻�״̬
    ,CPTL_ACC_STAT_NAME  --�ʽ��˻�״̬����
    ,CPTL_ACC_TYPE       --�ʽ��˻�����
    ,CPTL_ACC_TYPE_NAME  --�ʽ��˻���������
    ,CPTL_ACC_GROUP      --�ʽ��˻�����
    ,CPTL_ACC_GROUP_NAME --�ʽ��˻���������
    ,IF_SPCA_ACCT        --�Ƿ������˺�
    ,ODI_CMS_RATE        --��ͨӶ����
    ,SH_ODI_CMS_RATE     --������ͨӶ����
    ,SZ_ODI_CMS_RATE     --������ͨӶ����
    ,CREDIT_CMS_RATE     --������ȯӶ����
    ,SH_CRED_CMS_RATE    --��������Ӷ����
    ,SZ_CRED_CMS_RATE    --��������Ӷ����
    ,GGT_CMS_RATE        --�۹�ͨӶ����
    ,OFFUND_CMS_RATE     --���ڻ���Ӷ����
    ,WRNT_CMS_RATE       --Ȩ֤Ӷ����
    ,BGDL_CMS_RATE       --���ڽ���Ӷ����
    ,OACT_DT             --��������
    ,CANCEL_DT           --ע������
    ,LOAD_DT             --��ϴ����
	)
	SELECT
	 DISTINCT CPTL_ACCT           --�ʽ��˺�
    ,YEAR                --��
    ,MTH                 --��
    ,CUST_ID             --�ͻ�����
    ,WH_ORG_ID           --�ֿ��������
    ,HS_ORG_ID           --������������
    ,MAINSUB_FLAG        --������־
    ,DEPO_BANK           --�������
    ,DEPO_BANK_NAME      --�����������
    ,CPTL_ACC_STAT       --�ʽ��˻�״̬
    ,CPTL_ACC_STAT_NAME  --�ʽ��˻�״̬����
    ,CPTL_ACC_TYPE       --�ʽ��˻�����
    ,CPTL_ACC_TYPE_NAME  --�ʽ��˻���������
    ,CPTL_ACC_GROUP      --�ʽ��˻�����
    ,CPTL_ACC_GROUP_NAME --�ʽ��˻���������
    ,IF_SPCA_ACCT        --�Ƿ������˺�
    ,ODI_CMS_RATE        --��ͨӶ����
    ,SH_ODI_CMS_RATE     --������ͨӶ����
    ,SZ_ODI_CMS_RATE     --������ͨӶ����
    ,CREDIT_CMS_RATE     --������ȯӶ����
    ,SH_CRED_CMS_RATE    --��������Ӷ����
    ,SZ_CRED_CMS_RATE    --��������Ӷ����
    ,GGT_CMS_RATE        --�۹�ͨӶ����
    ,OFFUND_CMS_RATE     --���ڻ���Ӷ����
    ,WRNT_CMS_RATE       --Ȩ֤Ӷ����
    ,BGDL_CMS_RATE       --���ڽ���Ӷ����
    ,OACT_DT             --��������
    ,CANCEL_DT           --ע������
    ,LOAD_DT             --��ϴ����
	FROM #TEMP_CPTL_ACC  TOC
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_ACC_CPTL_ACC TO query_dev
GO
GRANT EXECUTE ON dm.P_ACC_CPTL_ACC TO xydc
GO
CREATE PROCEDURE dm.P_ACC_ITC_SECU_ACC(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ����֤ȯ�˻���Ϣά��
  ��д��: DCY
  ��������: 2017-11-28
  ��飺��ϴ����֤ȯ�˻���Ϣά��ĸ������õ�������Ϣ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
  
    --PART0 ɾ����������
  DELETE FROM DM.T_ACC_ITC_SECU_ACC WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
  --PART1 ��ÿ�ղɼ������ݷ�����ʱ��
 
	SELECT
	 TEUS.STOCK_ACCOUNT                AS SECU_ACCT     --֤ȯ�˺�
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --��
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --��
	,TEUS.EXCHANGE_TYPE                AS MKT_TYPE      --�г�����
	,TEUS.OPEN_DATE                    AS OACT_DT       --��������
	,TEUS.CLIENT_ID                    AS CUST_ID       --�ͻ�����	
	,TEUS.FUND_ACCOUNT                 AS CPTL_ACCT     --�ʽ��˺�
	,DOH.PK_ORG                        AS WH_ORG_ID     --�ֿ�������� 
	,CONVERT(VARCHAR,TEUS.BRANCH_NO)   AS HS_ORG_ID     --������������
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUS.EXCHANGE_TYPE 
	  AND OUS.DICT_ENTRY=1301) AS MKT_TYPE_NAME         --�г��������� 
	,TEUS.HOLDER_KIND                  AS ITC_SECU_ACC_TYPE        --����֤ȯ�˻�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUS.HOLDER_KIND 
	  AND OUS.DICT_ENTRY=1208)         AS ITC_SECU_ACC_TYPE_NAME   --����֤ȯ�˻��������� 
	,TEUS.SEAT_NO                      AS SEAT_NO       --ϯλ���
	,TEUS.HOLDER_STATUS                AS ITC_SECU_ACC_STAT        --����֤ȯ�˻�״̬
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUS.HOLDER_STATUS 
	  AND OUS.DICT_ENTRY=1000)         AS ITC_SECU_ACC_STAT_NAME    --����֤ȯ�˻�״̬����
	,TEUS.ACODE_ACCOUNT                AS YMT_ACCT                  --һ��ͨ�˺�
	,@V_BIN_DATE                       AS LOAD_DT  --��ϴ����
	
	INTO #TMP_ITC_SECU_ACC
	
	FROM DBA.T_EDW_UF2_STOCKHOLDER TEUS
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,TEUS.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL AND DOH.HR_NAME IS NOT NULL
    WHERE TEUS.LOAD_DT=@V_BIN_DATE AND TEUS.BRANCH_NO !=44 --�ų��ܲ���ֻ�м���������Ȼ���ݻ��ظ�
	;
	COMMIT;
	
	--2 ��󽫵��������Ŀͻ��������
	INSERT INTO DM.T_ACC_ITC_SECU_ACC
	(
	 SECU_ACCT               --֤ȯ�˺�
    ,YEAR                    --��
    ,MTH                     --��
	,MKT_TYPE                --�г�����
	,OACT_DT                 --��������
	,CUST_ID                 --�ͻ�����
	,CPTL_ACCT               --�ʽ��˺�
	,WH_ORG_ID               --�ֿ��������
	,HS_ORG_ID               --������������
	,MKT_TYPE_NAME           --�г���������
	,ITC_SECU_ACC_TYPE       --����֤ȯ�˻�����
	,ITC_SECU_ACC_TYPE_NAME  --����֤ȯ�˻���������
	,SEAT_NO                 --ϯλ���
	,ITC_SECU_ACC_STAT       --����֤ȯ�˻�״̬
	,ITC_SECU_ACC_STAT_NAME  --����֤ȯ�˻�״̬����
	,YMT_ACCT                --һ��ͨ�˺�
	,LOAD_DT                 --��ϴ����
	)
	SELECT
	 SECU_ACCT               --֤ȯ�˺�
    ,YEAR                    --��
    ,MTH                     --��
	,MKT_TYPE                --�г�����
	,OACT_DT                 --��������
	,CUST_ID                 --�ͻ�����
	,CPTL_ACCT               --�ʽ��˺�
	,WH_ORG_ID               --�ֿ��������
	,HS_ORG_ID               --������������
	,MKT_TYPE_NAME           --�г���������
	,ITC_SECU_ACC_TYPE       --����֤ȯ�˻�����
	,ITC_SECU_ACC_TYPE_NAME  --����֤ȯ�˻���������
	,SEAT_NO                 --ϯλ���
	,ITC_SECU_ACC_STAT       --����֤ȯ�˻�״̬
	,ITC_SECU_ACC_STAT_NAME  --����֤ȯ�˻�״̬����
	,YMT_ACCT                --һ��ͨ�˺�
	,LOAD_DT                 --��ϴ����
	FROM #TMP_ITC_SECU_ACC  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_ACC_ITC_SECU_ACC TO query_dev
GO
GRANT EXECUTE ON dm.P_ACC_ITC_SECU_ACC TO xydc
GO
CREATE PROCEDURE dm.P_ACC_OTC_SECU_CHRM_ACC(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ����֤ȯ����˻���Ϣά��
  ��д��: DCY
  ��������: 2017-11-29
  ��飺��ϴ����֤ȯ����˻���Ϣά��ĸ������õ�������Ϣ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
              
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
  
  --PART0 ɾ����������
  DELETE FROM DM.T_ACC_OTC_SECU_CHRM_ACC WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
  --PART1 ��ÿ�ղɼ������ݷ�����ʱ��
 
	SELECT
	 TEUP.SECUM_ACCOUNT                 AS SECU_CHRM_ACCT     --֤ȯ����˺�
	,TEUP.PRODTA_NO                    AS PRODTA_ID     --��ƷTA����
	,TEUP.TRANS_ACCOUNT                AS TRD_ACCT      --�����˺�
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --��
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --��
	,TEUP.CLIENT_ID                    AS CUST_ID       --�ͻ�����	
	,TEUP.FUND_ACCOUNT                 AS CPTL_ACCT     --�ʽ��˺�
	,DOH.PK_ORG                        AS WH_ORG_ID     --�ֿ�������� 
	,CONVERT(VARCHAR,TEUP.BRANCH_NO)   AS HS_ORG_ID     --������������
	,TEUP.PRODHOLDER_KIND              AS OTC_CHRM_ACC_TYPE  --��������˻�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUP.PRODHOLDER_KIND 
	  AND OUS.DICT_ENTRY=41100)        AS OTC_CHRM_ACC_TYPE_NAME    --��������˻��������� 
	,TEUP.ID_KIND                      AS ID_TYPE       --֤�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUP.ID_KIND 
	  AND OUS.DICT_ENTRY=1041)         AS ID_TYPE_NAME  --֤��������� 
	,TEUP.ID_NO                        AS ID_NO         --֤�����	
	
	,TEUP.PRODHOLDER_STATUS            AS PROD_ACC_STAT --��Ʒ�˻�״̬
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TEUP.PRODHOLDER_STATUS 
	  AND OUS.DICT_ENTRY=41101)        AS PROD_ACC_STAT_NAME    --��Ʒ�˻�״̬����
	,TEUP.OPEN_DATE                    AS OACT_DT       --��������	
	,TEUP.DIVIDEND_WAY                 AS BONS_MODE     --�ֺ췽ʽ
	,TEUP.SEAT_NO                      AS SEAT_NO       --ϯλ���
	,TEUP.BANK_NO                      AS BANK_NO       --���б��
	,TEUP.PAY_KIND                     AS PAY_MODE      --֧����ʽ
	,TEUP.PAY_ACCOUNT                  AS PAY_ACCT      --֧���˺�
	,@V_BIN_DATE                       AS LOAD_DT  --��ϴ����
	
	INTO #TMP_OTC_SECU_ACC
	
	FROM DBA.T_EDW_UF2_PRODSECUMHOLDER   TEUP
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,TEUP.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL AND DOH.HR_NAME IS NOT NULL
    WHERE TEUP.LOAD_DT=@V_BIN_DATE 
	;
	COMMIT;
	
	--2 ��󽫵��������Ŀͻ��������
	INSERT INTO DM.T_ACC_OTC_SECU_CHRM_ACC
	(
	 SECU_CHRM_ACCT        --֤ȯ����˺�
	,PRODTA_ID             --��ƷTA����
	,TRD_ACCT              --�����˺�
	,YEAR                  --��
	,MTH                   --��
	,CUST_ID               --�ͻ�����
	,CPTL_ACCT             --�ʽ��˺�
	,WH_ORG_ID             --�ֿ��������
	,HS_ORG_ID             --������������
	,OTC_CHRM_ACC_TYPE     --��������˻�����
	,OTC_CHRM_ACC_TYPE_NAME --��������˻���������
	,ID_TYPE               --֤�����
	,ID_TYPE_NAME          --֤���������
	,ID_NO                 --֤�����
	,PROD_ACC_STAT         --��Ʒ�˻�״̬
	,PROD_ACC_STAT_NAME    --��Ʒ�˻�״̬����
	,OACT_DT               --��������
	,BONS_MODE             --�ֺ췽ʽ
	,SEAT_NO               --ϯλ���
	,BANK_NO               --���б��
	,PAY_MODE              --֧����ʽ
	,PAY_ACCT              --֧���˺�
	,LOAD_DT               --��ϴ����
	)
	SELECT
	 SECU_CHRM_ACCT        --֤ȯ����˺�
	,PRODTA_ID             --��ƷTA����
	,TRD_ACCT              --�����˺�
	,YEAR                  --��
	,MTH                   --��
	,CUST_ID               --�ͻ�����
	,CPTL_ACCT             --�ʽ��˺�
	,WH_ORG_ID             --�ֿ��������
	,HS_ORG_ID             --������������
	,OTC_CHRM_ACC_TYPE     --��������˻�����
	,OTC_CHRM_ACC_TYPE_NAME --��������˻���������
	,ID_TYPE               --֤�����
	,ID_TYPE_NAME          --֤���������
	,ID_NO                 --֤�����
	,PROD_ACC_STAT         --��Ʒ�˻�״̬
	,PROD_ACC_STAT_NAME    --��Ʒ�˻�״̬����
	,OACT_DT               --��������
	,BONS_MODE             --�ֺ췽ʽ
	,SEAT_NO               --ϯλ���
	,BANK_NO               --���б��
	,PAY_MODE              --֧����ʽ
	,PAY_ACCT              --֧���˺�
	,LOAD_DT               --��ϴ����
	FROM #TMP_OTC_SECU_ACC  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_ACC_OTC_SECU_CHRM_ACC TO query_dev
GO
GRANT EXECUTE ON dm.P_ACC_OTC_SECU_CHRM_ACC TO xydc
GO
CREATE PROCEDURE dm.P_AGT_APPTBUYB_AGMT(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: Լ�����غ�ͬ
  ��д��: DCY
  ��������: 2017-11-22
  ��飺��ϴԼ�����غ�ͬ��Ϣ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
  
  --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_AGT_APPTBUYB_AGMT WHERE OCCUR_DT=@V_BIN_DATE;
  
  INSERT INTO DM.T_AGT_APPTBUYB_AGMT
  (
    CTR_NO                 --��ͬ��
   ,OCCUR_DT               --ҵ������
   ,CUST_ID                --�ͻ�����
   ,CPTL_ACCT              --�ʽ��˺�
   ,WH_ORG_NO              --�ֿ�������
   ,HS_ORG_NO              --�����������
   ,SECU_CD                --֤ȯ����
   ,SECU_ACCT              --֤ȯ�˺�
   ,RELA_CTR_NO            --������ͬ��
   ,WRITT_CTR_NO           --�����ͬ���
   ,APPT_CTR_TYPE          --Լ����ͬ����
   ,TRD_TYPE               --�������
   ,MATU_RCKON_RETN        --������������
   ,ORDR_VOL               --ί������
   ,ORDR_AMT               --ί�н��
   ,BUYB_AMT               --���ؽ��
   ,TFR_IN_DT              --ת������
   ,ORDR_DT                --ί������
   ,ORDR_NO                --ί�б��
   ,ACTL_BUYB_AMT          --ʵ�ʹ��ؽ��
   ,ACTL_BUYB_DT           --ʵ�ʹ�������
   ,ACTL_BUYB_INTR         --ʵ�ʹ�������
   ,APPT_CTR_STAT          --Լ����ͬ״̬
   ,SUBSCR_DT              --ǩԼ����
   ,RSTK_VOL               --�������
   ,BONUS_AMT              --�������
   ,CLR_DT                 --��������
   ,MEMO                   --��ע
   ,LOAD_DT                --��ϴ����
  )
  SELECT
    TEA.CONTRACT_ID            --��ͬ��                
   ,@V_BIN_DATE                 --ҵ������           
   ,TEA.CLIENT_ID              --�ͻ�����              
   ,CONVERT(VARCHAR,TEA.FUND_ACCOUNT)           --�ʽ��˺�                 
   ,DOH.PK_ORG                  --�ֿ�������          
   ,CONVERT(VARCHAR,TEA.BRANCH_NO)              --�����������              
   ,TEA.STOCK_CODE             --֤ȯ����               
   ,TEA.STOCK_ACCOUNT          --֤ȯ�˺�                  
   ,TEA.JOIN_CONTRACT_ID       --������ͬ��                     
   ,TEA.PAPERCONT_ID           --�����ͬ���                 
   ,TEA.ARP_CONTRACT_TYPE      --Լ����ͬ����                                        
   ,TEA.EXCHANGE_TYPE          --�������                  
   ,TEA.EXPIRE_YEAR_RATE       --������������                     
   ,TEA.ENTRUST_AMOUNT         --ί������                   
   ,TEA.ENTRUST_BALANCE        --ί�н��                    
   ,TEA.BACK_BALANCE           --���ؽ��                 
   ,TEA.DATE_BACK              --ת������              
   ,TEA.ENTRUST_DATE           --ί������                 
   ,CONVERT(VARCHAR,TEA.ENTRUST_NO)             --ί�б��               
   ,TEA.REAL_BACK_BALANCE      --ʵ�ʹ��ؽ��                      
   ,TEA.REAL_DATE_BACK         --ʵ�ʹ�������                   
   ,TEA.REAL_YEAR_RATE         --ʵ�ʹ�������                   
   ,TEA.CONTRACT_STATUS    --Լ����ͬ״̬                        
   ,TEA.SIGN_DATE              --ǩԼ����                                
   ,TEA.BONUS_AMOUNT           --�������                 
   ,TEA.BONUS_BALANCE          --�������                                     
   ,TEA.DATE_CLEAR             --��������                              
   ,TEA.REMARK                 --��ע           
   ,CONVERT(NUMERIC(8,0),CONVERT(VARCHAR(8),GETDATE(),112))    --��ϴ����                        

  FROM DBA.T_EDW_ARPCONTRACT  TEA  --DBA.T_ODS_UF2_ARPCONTRACT TEA
  LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,TEA.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL 
  WHERE TEA.LOAD_DT=@V_BIN_DATE
  ;
   
   COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AGT_APPTBUYB_AGMT TO query_dev
GO
GRANT EXECUTE ON dm.P_AGT_APPTBUYB_AGMT TO xydc
GO
CREATE PROCEDURE dm.P_AGT_CREDIT_AGMT(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ������ȯ��Լ
  ��д��: DCY
  ��������: 2017-11-22
  ��飺��ϴ���ں�Լ��Ϣ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_AGT_CREDIT_AGMT WHERE OCCUR_DT=@V_BIN_DATE;
  
  INSERT INTO DM.T_AGT_CREDIT_AGMT
  (
    CONT_NO              --��Լ���
   ,OCCUR_DT             --ҵ������
   ,CUST_ID              --�ͻ�����
   ,CPTL_ACCT            --�ʽ��˺�
   ,WH_ORG_NO            --�ֿ�������
   ,HS_ORG_NO            --�����������
   ,SECU_CD              --֤ȯ����
   ,SECU_ACCT            --֤ȯ�˺�
   ,CTR_NO               --��ͬ��
   ,ORDR_MODE            --ί�з�ʽ
   ,TRD_TYPE             --�������
   ,SECU_TYPE            --֤ȯ���
   ,SECU_TYPE_NAME       --֤ȯ�������
   ,CCY_TYPE             --�������
   ,CONT_TYPE            --��Լ���
   ,CONT_TYPE_NAME       --��Լ������� 
   ,ORDR_PRC             --ί�м۸�
   ,ORDR_VOL             --ί������
   ,CCB_ORDR_ROUG_AMT    --��������ί����;���
   ,CSS_ORDR_ROUG_VOL    --��ȯ����ί����;����
   ,FIN_USED_AMT         --����ռ�ý��
   ,CRDT_STK_USED_VOL    --��ȯռ������
   ,MTCH_PRC             --�ɽ��۸�
   ,MTCH_VOL             --�ɽ�����
   ,MTCH_AMT             --�ɽ����
   ,MTCH_CHAG_AMT        --�ɽ������ѽ��
   ,STR_CONT_AMT         --�ڳ���Լ���
   ,STR_CONT_VOL         --�ڳ���Լ����
   ,STR_CONT_TRD_CHAG    --�ڳ���Լ����������
   ,DAY_REAL_CONT_AMT    --�ռ�ʵʱ��Լ���
   ,DAY_REAL_CONT_VOL    --�ռ�ʵʱ��Լ����
   ,DAY_REAL_CONT_CHAG   --�ռ�ʵʱ��Լ������
   ,DAY_REAL_INTR_AMT    --�ռ�ʵʱ��Ϣ���
   ,CONT_AMT             --��Լ���
   ,CONT_VOL             --��Լ����
   ,TRD_CHAG             --����������
   ,RTNED_INTR           --�ѻ���Ϣ
   ,RCDINFO_STRT_DT      --��Ϣ��ʼ����
   ,EXT_INTA_DAYS        --�ӳټ�Ϣ����
   ,YEAR_INTR            --������
   ,MARG_RATE            --��֤�����
   ,CONT_INTR_ARRG       --��Լ��Ϣ����
   ,CONT_INTR_AMT        --��Լ��Ϣ���
   ,PNL_INT_ARRG         --��Ϣ����
   ,PNL_INT_STRT_DT      --��Ϣ��ʼ����
   ,PNL_INT_INTR         --��Ϣ����
   ,INTR_DT              --��Ϣ����
   ,INTL_MODE            --��Ϣ�˽᷽ʽ
   ,RTN_END_DAY          --�黹��ֹ��
   ,DELY_RTN_DAY         --���ڹ黹��
   ,POSTN_NO             --ͷ����
   ,ORDR_NO              --ί�б��
   ,CONT_STAT            --��Լ״̬
   ,CONT_SRC             --��Լ��Դ
   ,CRT_DT               --��������
   ,RTN_DT               --�黹����
   ,CLR_DT               --��������
   ,MEMO                 --��ע
   ,LOAD_DT              --��ϴ����
   )
   SELECT 
    URC.COMPACT_ID                      AS  CONT_NO              --��Լ���
   ,@V_BIN_DATE                         AS  OCCUR_DT             --ҵ������
   ,URC.CLIENT_ID                       AS  CUST_ID              --�ͻ�����
   ,URC.FUND_ACCOUNT                    AS  CPTL_ACCT            --�ʽ��˺�
   ,DOH.PK_ORG                          AS  WH_ORG_NO            --�ֿ�������
   ,CONVERT(VARCHAR,URC.BRANCH_NO)      AS  HS_ORG_NO            --�����������
   ,URC.STOCK_CODE                      AS  SECU_CD              --֤ȯ����
   ,URC.STOCK_ACCOUNT                   AS  SECU_ACCT            --֤ȯ�˺�
   ,URC.CONTRACT_ID                     AS  CTR_NO               --��ͬ��
   ,URC.OP_ENTRUST_WAY                  AS  ORDR_MODE            --ί�з�ʽ
   ,URC.EXCHANGE_TYPE                   AS  TRD_TYPE             --�������
   ,URC.STOCK_TYPE                      AS  SECU_TYPE            --֤ȯ���
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=URC.STOCK_TYPE AND OUS.DICT_ENTRY=1206) AS SECU_TYPE_NAME   --֤ȯ�������  
   ,URC.MONEY_TYPE                      AS  CCY_TYPE             --�������
   ,URC.COMPACT_TYPE                    AS  CONT_TYPE            --��Լ���
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=URC.COMPACT_TYPE AND OUS.DICT_ENTRY=31000) AS CONT_TYPE_NAME   --��Լ�������  
   ,URC.ENTRUST_PRICE                   AS  ORDR_PRC             --ί�м۸�
   ,URC.ENTRUST_AMOUNT                  AS  ORDR_VOL             --ί������
   ,URC.REAL_OCCUPED_BALANCE            AS  CCB_ORDR_ROUG_AMT    --��������ί����;���
   ,URC.REAL_OCCUPED_AMOUNT             AS  CSS_ORDR_ROUG_VOL    --��ȯ����ί����;����
   ,URC.OCCUPED_BALANCE                 AS  FIN_USED_AMT         --����ռ�ý��
   ,URC.OCCUPED_AMOUNT                  AS  CRDT_STK_USED_VOL    --��ȯռ������
   ,URC.BUSINESS_PRICE                  AS  MTCH_PRC             --�ɽ��۸�
   ,URC.BUSINESS_AMOUNT                 AS  MTCH_VOL             --�ɽ�����
   ,URC.BUSINESS_BALANCE                AS  MTCH_AMT             --�ɽ����
   ,URC.BUSINESS_FARE                   AS  MTCH_CHAG_AMT        --�ɽ������ѽ��
   ,URC.BEGIN_COMPACT_BALANCE           AS  STR_CONT_AMT         --�ڳ���Լ���
   ,URC.BEGIN_COMPACT_AMOUNT            AS  STR_CONT_VOL         --�ڳ���Լ����
   ,URC.BEGIN_COMPACT_FARE              AS  STR_CONT_TRD_CHAG    --�ڳ���Լ����������
   ,URC.REAL_COMPACT_BALANCE            AS  DAY_REAL_CONT_AMT    --�ռ�ʵʱ��Լ���
   ,URC.REAL_COMPACT_AMOUNT             AS  DAY_REAL_CONT_VOL    --�ռ�ʵʱ��Լ����
   ,URC.REAL_COMPACT_FARE               AS  DAY_REAL_CONT_CHAG   --�ռ�ʵʱ��Լ������
   ,URC.REAL_COMPACT_INTEREST           AS  DAY_REAL_INTR_AMT    --�ռ�ʵʱ��Ϣ���
   ,URC.COMPACT_BALANCE                 AS  CONT_AMT             --��Լ���
   ,URC.COMPACT_AMOUNT                  AS  CONT_VOL             --��Լ����
   ,URC.COMPACT_FARE                    AS  TRD_CHAG             --����������
   ,URC.REPAID_INTEREST                 AS  RTNED_INTR           --�ѻ���Ϣ
   ,URC.INTEREST_BEGIN_DATE             AS  RCDINFO_STRT_DT      --��Ϣ��ʼ����
   ,URC.DEFERED_DAYS                    AS  EXT_INTA_DAYS        --�ӳټ�Ϣ����
   ,URC.YEAR_RATE                       AS  YEAR_INTR            --������
   ,URC.CRDT_RATIO                      AS  MARG_RATE            --��֤�����
   ,URC.COMPACT_INTEGRAL                AS  CONT_INTR_ARRG       --��Լ��Ϣ����
   ,URC.COMPACT_INTEREST                AS  CONT_INTR_AMT        --��Լ��Ϣ���
   ,URC.FINE_INTEGRAL                   AS  PNL_INT_ARRG         --��Ϣ����
   ,URC.FINE_BEGIN_DATE                 AS  PNL_INT_STRT_DT      --��Ϣ��ʼ����
   ,URC.FINE_RATE                       AS  PNL_INT_INTR         --��Ϣ����
   ,URC.INTEREST_DATE                   AS  INTR_DT              --��Ϣ����
   ,URC.CRDTINT_MODE                    AS  INTL_MODE            --��Ϣ�˽᷽ʽ
   ,URC.RET_END_DATE                    AS  RTN_END_DAY          --�黹��ֹ��
   ,URC.DELAY_RET_DATE                  AS  DELY_RTN_DAY         --���ڹ黹��
   ,CONVERT(VARCHAR,URC.CASHGROUP_NO)   AS  POSTN_NO             --ͷ����
   ,CONVERT(VARCHAR,URC.ENTRUST_NO)     AS  ORDR_NO              --ί�б��
   ,URC.COMPACT_STATUS                  AS  CONT_STAT            --��Լ״̬
   ,URC.COMPACT_SOURCE                  AS  CONT_SRC             --��Լ��Դ
   ,URC.CREATE_DATE                     AS  CRT_DT               --��������
   ,URC.REPAID_DATE                     AS  RTN_DT               --�黹����
   ,URC.DATE_CLEAR                      AS  CLR_DT               --��������
   ,URC.REMARK                          AS  MEMO                 --��ע
   ,CONVERT(NUMERIC(8,0),CONVERT(VARCHAR(8),GETDATE(),112)) AS LOAD_DT    --��ϴ����

   
   FROM DBA.T_EDW_UF2_RZRQ_COMPACT URC
   LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,URC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL 
   WHERE URC.LOAD_DT=@V_BIN_DATE
   ;
   
   COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AGT_CREDIT_AGMT TO query_dev
GO
GRANT EXECUTE ON dm.P_AGT_CREDIT_AGMT TO xydc
GO
CREATE PROCEDURE dm.P_AGT_STKPLG_AGMT(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ��Ʊ��Ѻ��ͬ
  ��д��: DCY
  ��������: 2017-11-22
  ��飺��ϴ��Ʊ��Ѻ��ͬ��Ϣ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
      --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_AGT_STKPLG_AGMT WHERE OCCUR_DT=@V_BIN_DATE;
  
  INSERT INTO DM.T_AGT_STKPLG_AGMT
  (
    CTR_NO                   --��ͬ��
   ,OCCUR_DT                 --ҵ������
   ,CUST_ID                  --�ͻ�����
   ,CPTL_ACCT                --�ʽ��˺�
   ,WH_ORG_NO                --�ֿ�������
   ,HS_ORG_NO                --�����������
   ,SECU_CD                  --֤ȯ����
   ,SECU_ACCT                --֤ȯ�˺�
   ,RELA_CTR_NO              --������ͬ��
   ,WRITT_CTR_NO             --�����ͬ���
   ,CTR_TYPE                 --��ͬ����
   ,CTR_TYPE_NAME            --��ͬ��������
   ,TRD_TYPE                 --�������
   ,SECU_TYPE                --֤ȯ���
   ,SECU_TYPE_NAME           --֤ȯ�������
   ,CCY_TYPE                 --�������
   ,ORDR_VOL                 --ί������
   ,MATU_RCKON_RETN          --������������
   ,ORDR_AMT                 --ί�н��
   ,BUYB_AMT                 --���ؽ��
   ,TFR_IN_DT                --ת������
   ,ACTL_BUYB_INTR           --ʵ�ʹ�������
   ,ACTL_BUYB_AMT            --ʵ�ʹ��ؽ��
   ,ACTL_BUYB_DT             --ʵ�ʹ�������
   ,CTR_STAT                 --��ͬ״̬
   ,CTR_STAT_NAME            --��ͬ״̬����
   ,CLR_DT                   --��������
   ,SUBSCR_DT                --ǩԼ����
   ,ORDR_DT                  --ί������
   --,ORDR_NO                  --ί�б��
   --,MTCH_NO                  --�ɽ����
   ,CPTL_USES                --�ʽ���;
   ,GUAR_CNVR_PRIC           --���������
   ,AGT_ORDR_FLAG            --����ί�б�־
   ,FINAC_OUT_SIDE_NO        --�ڳ������
   ,FINAC_OUT_SIDE_NAME        --�ڳ�������
   ,FINAC_OUT_SIDE_TYPE        --�ڳ�������
   ,FINAC_OUT_SIDE_TYPE_NAME   --�ڳ�����������
   ,INTR_MODE                --���ʷ�ʽ
   ,RSTK_VOL                 --�������
   ,BONUS_AMT                --�������
   ,BUYB_TYPE                --��������
   ,BUYB_TYPE_NAME           --������������
   ,PTTT_STAT                --Ԥ����״̬
   ,CUM_POR_UNPLG_VOL        --�ۼƲ��ֽ�Ѻ����
   ,CUM_POR_UNPLG_BONUS      --�ۼƲ��ֽ�Ѻ����
   ,SHAR_CHAR                --�ɷ�����
   ,LAB_DT                   --�������
   ,RTNED_AMT                --�ѻ����
   ,ALDY_INTR                --�ѽ���Ϣ
   ,OTC_REPY_UNCKOT_INTR     --���⳥��δ����Ϣ
   ,REP_CTR_SEQ              --�걨��ͬ���
   ,PLG_NO                   --��Ѻ���
   ,LAL_FLAG                 --�߹ܱ�־
   ,NOTS_TRANSF_PRC          --���۹�ת�ü۸�
   ,NOTS_ORIG_VAL            --���۹�ԭֵ
   ,GUAR_CNVR_RATE           --����������
   ,CONCERN_GUAR_PROT_RATE   --��ע��Լ���ϱ�
   ,WARN_GUAR_PROT_RATE      --������Լ���ϱ�
   ,DEAL_GUAR_PROT_RATE      --������Լ���ϱ�
   ,INTR_ARRG                --��Ϣ����
   --,ARRG_MDF_DT              --������������
   --,LST_INTL_DT              --�ϴν�Ϣ����
   --,BATCH_UNCKOT_INTR        --����δ����Ϣ
   --,STKPLG_PROD_TYPE         --��Ʊ��Ѻ��Ʒ����
   --,FIN_PURS_PRE_FRZ_INTR    --�����깺Ԥ����Ϣ
   --,FIN_PURS_PRE_FRZ_FEE     --�����깺Ԥ������
   --,APP_BUYB_DT              --���빺������
   --,APP_BUYB_AMT             --���빺�ؽ��
   ,MEMO                     --��ע
   ,LOAD_DT                  --��ϴ����
 )
 SELECT 
    GOHS.CONTRACT_ID             --��ͬ��                    
   ,@V_BIN_DATE                  --ҵ������                    
   ,GOHS.CLIENT_ID               --�ͻ�����                  
   ,CONVERT(VARCHAR,GOHS.FUND_ACCOUNT)            --�ʽ��˺�                     
   ,DOH.PK_ORG                   --�ֿ�������               
   ,CONVERT(VARCHAR,GOHS.BRANCH_NO)              --�����������                  
   ,GOHS.STOCK_CODE              --֤ȯ����                   
   ,GOHS.STOCK_ACCOUNT           --֤ȯ�˺�                      
   ,GOHS.JOIN_CONTRACT_ID        --������ͬ��                         
   ,GOHS.PAPERCONT_ID            --�����ͬ���                     
   ,GOHS.SRP_CONTRACT_TYPE       --��ͬ����  
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.SRP_CONTRACT_TYPE AND OUS.DICT_ENTRY=1278) AS CTR_TYPE_NAME   --��ͬ��������     
   ,GOHS.EXCHANGE_TYPE           --�������                      
   ,GOHS.STOCK_TYPE              --֤ȯ��� 
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.STOCK_TYPE AND OUS.DICT_ENTRY=1206) AS SECU_TYPE_NAME   --֤ȯ�������      
   ,GOHS.MONEY_TYPE              --�������                   
   ,GOHS.ENTRUST_AMOUNT          --ί������                       
   ,GOHS.EXPIRE_YEAR_RATE        --������������                         
   ,GOHS.ENTRUST_BALANCE         --ί�н��                        
   ,GOHS.BACK_BALANCE            --���ؽ��                     
   ,GOHS.DATE_BACK               --ת������                  
   ,GOHS.REAL_YEAR_RATE          --ʵ�ʹ�������                       
   ,GOHS.REAL_BACK_BALANCE       --ʵ�ʹ��ؽ��                          
   ,GOHS.REAL_DATE_BACK          --ʵ�ʹ�������                       
   ,GOHS.SRP_CONTRACT_STATUS     --��ͬ״̬  
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.SRP_CONTRACT_STATUS AND OUS.DICT_ENTRY=1288) AS CTR_STAT_NAME   --��ͬ״̬���� 
   ,GOHS.DATE_CLEAR              --��������                   
   ,GOHS.SIGN_DATE               --ǩԼ����                  
   ,GOHS.ENTRUST_DATE            --ί������                     
   --,GOHS.ENTRUST_NO              --ί�б��                   
   --,GOHS.CBP_BUSINESS_ID         --�ɽ����                        
   ,GOHS.FUND_USAGE              --�ʽ���;                   
   ,GOHS.ASSURE_PRICE            --���������                     
   ,GOHS.SRP_AGENT_FLAG          --����ί�б�־                       
   ,CONVERT(VARCHAR,GOHS.FUNDER_NO)               --�ڳ������  
   ,TOUS.FUNDER_NAME             --�ڳ�������
   ,TOUS.FUNDER_TYPE             --�ڳ�������
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=TOUS.FUNDER_TYPE AND OUS.DICT_ENTRY=1289) AS FINAC_OUT_SIDE_TYPE_NAME   --�ڳ����������� 
   ,GOHS.RATE_MODE               --���ʷ�ʽ                  
   ,GOHS.BONUS_AMOUNT            --�������                     
   ,GOHS.BONUS_BALANCE           --�������                      
   ,GOHS.BACK_TYPE               --��������                  
   ,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=GOHS.BACK_TYPE AND OUS.DICT_ENTRY=1284) AS BUYB_TYPE_NAME   --������������ 
   ,GOHS.PREV_STATUS             --Ԥ����״̬                    
   ,GOHS.SUM_BACK_AMOUNT         --�ۼƲ��ֽ�Ѻ����                        
   ,GOHS.SUM_BACK_BALANCE        --�ۼƲ��ֽ�Ѻ����                         
   ,GOHS.STOCK_PROPERTY          --�ɷ�����                       
   ,GOHS.LIFT_DATE               --�������                  
   ,GOHS.REPAID_BALANCE          --�ѻ����                       
   ,GOHS.SETTLE_INTEREST         --�ѽ���Ϣ                        
   ,GOHS.UNSETTLE_INTEREST       --���⳥��δ����Ϣ                          
   ,GOHS.REPORT_ID               --�걨��ͬ���                  
   ,GOHS.IMPAWN_ID               --��Ѻ���                  
   ,GOHS.EXECUTIVES_FLAG         --�߹ܱ�־                        
   ,GOHS.LIMIT_TRANSFER_PRICE    --���۹�ת�ü۸�                             
   ,GOHS.LIMIT_ORIG_VALUE        --���۹�ԭֵ                         
   ,GOHS.ASSURE_RATIO            --����������                     
   ,GOHS.MARGIN_FOCUS_RATIO      --��ע��Լ���ϱ�                           
   ,GOHS.MARGIN_ALERT_RATIO      --������Լ���ϱ�                           
   ,GOHS.MARGIN_TREAT_RATIO      --������Լ���ϱ�                           
   ,GOHS.INTEGRAL_BALANCE        --��Ϣ����                         
   --,GOHS.INTEGRAL_UPDATE         --������������                        
   --,GOHS.LAST_INTEREST_DATE      --�ϴν�Ϣ����                           
   --,GOHS.BATCH_UNSETTLE_INTEREST --����δ����Ϣ                                
   --,GOHS.SRP_KIND                --��Ʊ��Ѻ��Ʒ����                 
   --,GOHS.IPO_PRE_INTEREST        --�����깺Ԥ����Ϣ                         
   --,GOHS.IPO_PRE_FARE            --�����깺Ԥ������                     
   --,GOHS.ASK_DATE_BACK           --���빺������                      
   --,GOHS.ASK_BACK_BALANCE        --���빺�ؽ��                         
   ,GOHS.REMARK                  --��ע                             
   ,CONVERT(NUMERIC(8,0),CONVERT(VARCHAR(8),GETDATE(),112))      --��ϴ����                           

   FROM DBA.GT_ODS_HS06_SRPCONTRACT  GOHS  --DBA.T_ODS_UF2_SRPCONTRACT
   LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,GOHS.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL 
   LEFT JOIN DBA.T_ODS_UF2_SRPFUNDER TOUS ON GOHS.FUNDER_NO=TOUS.FUNDER_NO
   WHERE GOHS.LOAD_DT=@V_BIN_DATE
   ;
   
   COMMIT;
   
   UPDATE dm.T_AGT_STKPLG_AGMT
	SET cptl_uses=REPLACE(REPLACE(REPLACE(cptl_uses,'/',''),'\',''),'|',''),     --�ͻ����� ,���ɫ������\���𣬲���Ӱ��SQL����
	    memo=REPLACE(REPLACE(REPLACE(memo,'/',''),'\',''),'|','')
		;  
   COMMIT;
   
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AGT_STKPLG_AGMT TO query_dev
GO
GRANT EXECUTE ON dm.P_AGT_STKPLG_AGMT TO xydc
GO
CREATE PROCEDURE dm.P_AST_APPTBUYB(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_�ʲ���Լ�������ʲ�
      ��д�ߣ�chenhu
      �������ڣ�2017-11-23
      ��飺
        �ͻ�����Լ������ҵ���ʲ�
    *********************************************************************/

    COMMIT;
    
    --ɾ����������
    DELETE FROM DM.T_AST_APPTBUYB WHERE OCCUR_DT = @V_IN_DATE;
    
    --���뵱������
    INSERT INTO DM.T_AST_APPTBUYB
        (CUST_ID,OCCUR_DT,GUAR_SECU_MVAL,APPTBUYB_BAL,SH_GUAR_SECU_MVAL,SZ_GUAR_SECU_MVAL,SH_NOTS_GUAR_SECU_MVAL,SZ_NOTS_GUAR_SECU_MVAL,PROP_FINAC_OUT_SIDE_BAL,ASSM_FINAC_OUT_SIDE_BAL,SM_LOAN_FINAC_OUT_BAL,LOAD_DT)
    SELECT KHBH_HS AS CUST_ID  --�ͻ�����
        ,RQ AS OCCUR_DT         --ҵ������
        ,DYZQSZ AS GUAR_SECU_MVAL  --����֤ȯ��ֵ
        ,FZ AS APPTBUYB_BAL  -- Լ���������
        ,NULL AS SH_GUAR_SECU_MVAL  --�Ϻ�����֤ȯ��ֵ��Ĭ��Ϊnull����������
        ,NULL AS SZ_GUAR_SECU_MVAL  --���ڵ���֤ȯ��ֵ��Ĭ��Ϊnull����������
        /*���۹ɲ�����Լ�����ؽ���*/
        ,0 AS SH_NOTS_GUAR_SECU_MVAL  --�Ϻ����۹ɵ���֤ȯ��ֵ
        ,0 AS SZ_NOTS_GUAR_SECU_MVAL  --�������۹ɵ���֤ȯ��ֵ
        /*�ڳ���Ϊ֤ȯ��˾�����ʹܵ�*/
        ,FZ AS PROP_FINAC_OUT_SIDE_BAL  --��Ӫ�ڳ������
        ,0 AS ASSM_FINAC_OUT_SIDE_BAL  --�ʹ��ڳ������
        ,0 AS SM_LOAN_FINAC_OUT_BAL  --С����ڳ����
        ,RQ AS LOAD_DT  --��ϴ����
    FROM DBA.T_DDW_YDSGH_D
    WHERE RQ = @V_IN_DATE;
    
    --���µ���֤ȯ��ֵ
    UPDATE DM.T_AST_APPTBUYB
        SET SH_GUAR_SECU_MVAL = COALESCE(BB.SH_GUAR_SECU_MVAL,0)
            ,SZ_GUAR_SECU_MVAL = COALESCE(BB.SZ_GUAR_SECU_MVAL,0)
    FROM DM.T_AST_APPTBUYB AA
    LEFT JOIN (
        SELECT AP.LOAD_DT AS OCCUR_DT    --ҵ������
            ,AP.CLIENT_ID AS CUST_ID      --�ͻ����  
            ,SUM(CASE WHEN AP.EXCHANGE_TYPE = '1' THEN AP.ENTRUST_AMOUNT*HQ.LAST_PRICE ELSE 0 END) AS SH_GUAR_SECU_MVAL --�Ϻ�����֤ȯ��ֵ
            ,SUM(CASE WHEN AP.EXCHANGE_TYPE = '2' THEN AP.ENTRUST_AMOUNT*HQ.LAST_PRICE ELSE 0 END) AS SZ_GUAR_SECU_MVAL --���ڵ���֤ȯ��ֵ
        FROM DBA.T_EDW_ARPCONTRACT AP
        LEFT JOIN DBA.T_EDW_UF2_HIS_PRICE HQ
        ON AP.LOAD_DT = HQ.LOAD_DT
        AND AP.EXCHANGE_TYPE = HQ.EXCHANGE_TYPE
        AND AP.STOCK_CODE = HQ.STOCK_CODE
        GROUP BY AP.LOAD_DT,AP.CLIENT_ID
    ) BB
    ON AA.CUST_ID = BB.CUST_ID
    AND AA.OCCUR_DT = BB.OCCUR_DT
    WHERE AA.OCCUR_DT = @V_IN_DATE;
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_APPTBUYB TO xydc
GO
CREATE PROCEDURE dm.P_AST_APPTBUYB_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Լ�������ʲ��±�
  ��д��: DCY
  ��������: 2018-01-05
  ��飺Լ�������ʲ��±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --��Ȼ��_�³�
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --��Ȼ��_��ĩ
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --������_�³�
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --������_��ĩ
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --��Ȼ��_���
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --������_���
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --��������_��
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --��������_��


    ----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
 

--PART0 ɾ����������
  DELETE FROM DM.T_AST_APPTBUYB_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    INSERT INTO DM.T_AST_APPTBUYB_M_D 
    (
	 CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,GUAR_SECU_MVAL_FINAL
	,APPTBUYB_BAL_FINAL
	,SH_GUAR_SECU_MVAL_FINAL
	,SZ_GUAR_SECU_MVAL_FINAL
	,SH_NOTS_GUAR_SECU_MVAL_FINAL
	,SZ_NOTS_GUAR_SECU_MVAL_FINAL
	,PROP_FINAC_OUT_SIDE_BAL_FINAL
	,ASSM_FINAC_OUT_SIDE_BAL_FINAL
	,SM_LOAN_FINAC_OUT_BAL_FINAL
	,GUAR_SECU_MVAL_MDA
	,APPTBUYB_BAL_MDA
	,SH_GUAR_SECU_MVAL_MDA
	,SZ_GUAR_SECU_MVAL_MDA
	,SH_NOTS_GUAR_SECU_MVAL_MDA
	,SZ_NOTS_GUAR_SECU_MVAL_MDA
	,PROP_FINAC_OUT_SIDE_BAL_MDA
	,ASSM_FINAC_OUT_SIDE_BAL_MDA
	,SM_LOAN_FINAC_OUT_BAL_MDA
	,GUAR_SECU_MVAL_YDA
	,APPTBUYB_BAL_YDA
	,SH_GUAR_SECU_MVAL_YDA
	,SZ_GUAR_SECU_MVAL_YDA
	,SH_NOTS_GUAR_SECU_MVAL_YDA
	,SZ_NOTS_GUAR_SECU_MVAL_YDA
	,PROP_FINAC_OUT_SIDE_BAL_YDA
	,ASSM_FINAC_OUT_SIDE_BAL_YDA
	,SM_LOAN_FINAC_OUT_BAL_YDA
	,LOAD_DT
	)
select
	t1.CUST_ID   as �ͻ�����
    ,@V_BIN_DATE AS OCCUR_DT
	,t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ��_�³�
	,t_rq.��||t_rq.�� as ����
	,t_rq.��||t_rq.��||t1.CUST_ID as ���¿ͻ�����		
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end) 			as ����֤ȯ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.APPTBUYB_BAL,0) else 0 end)		 		as Լ���������_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SH_GUAR_SECU_MVAL,0) else 0 end) 		as �Ϻ�����֤ȯ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SZ_GUAR_SECU_MVAL,0) else 0 end) 		as ���ڵ���֤ȯ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0) else 0 end) 	as �Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0) else 0 end) 	as �������۹ɵ���֤ȯ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0) else 0 end) 	as ��Ӫ�ڳ������_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0) else 0 end) 	as �ʹ��ڳ������_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0) else 0 end) 	as С����ڳ����_��ĩ

	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� 			as ����֤ȯ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.APPTBUYB_BAL,0) else 0 end)/t_rq.��Ȼ����_�� 			as Լ���������_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SH_GUAR_SECU_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� 		as �Ϻ�����֤ȯ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SZ_GUAR_SECU_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� 		as ���ڵ���֤ȯ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� 	as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� 	as �������۹ɵ���֤ȯ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0) else 0 end)/t_rq.��Ȼ����_�� as ��Ӫ�ڳ������_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0) else 0 end)/t_rq.��Ȼ����_�� as �ʹ��ڳ������_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0) else 0 end)/t_rq.��Ȼ����_�� 	as С����ڳ����_���վ�

	,sum(COALESCE(t1.GUAR_SECU_MVAL,0))/t_rq.��Ȼ����_�� 			as ����֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.APPTBUYB_BAL,0))/t_rq.��Ȼ����_�� 				as Լ���������_���վ�
	,sum(COALESCE(t1.SH_GUAR_SECU_MVAL,0))/t_rq.��Ȼ����_�� 		as �Ϻ�����֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.SZ_GUAR_SECU_MVAL,0))/t_rq.��Ȼ����_�� 		as ���ڵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL,0))/t_rq.��Ȼ����_�� 	as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL,0))/t_rq.��Ȼ����_�� 	as �������۹ɵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL,0))/t_rq.��Ȼ����_�� 	as ��Ӫ�ڳ������_���վ�
	,sum(COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL,0))/t_rq.��Ȼ����_�� 	as �ʹ��ڳ������_���վ�
	,sum(COALESCE(t1.SM_LOAN_FINAC_OUT_BAL,0))/t_rq.��Ȼ����_�� 	as С����ڳ����_���վ�
	,@V_BIN_DATE
from
(
	select
		@V_BIN_YEAR as ��
		,@V_BIN_MTH as ��
		,t1.DT as ����
		,t1.TRD_DT as ��������
		,@V_BIN_NATRE_DAY_MTHBEG    as ��Ȼ��_�³�
		,@V_BIN_NATRE_DAY_MTHEND    as ��Ȼ��_��ĩ
		,@V_BIN_TRD_DAY_MTHBEG      as ������_�³�
		,@V_BIN_TRD_DAY_MTHEND      as ������_��ĩ
		,@V_BIN_NATRE_DAY_YEARBGN   as ��Ȼ��_���
		,@V_BIN_TRD_DAY_YEARBGN     as ������_���
		,@V_BIN_NATRE_DAYS_MTH      as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_MTH        as ��������_��
		,@V_BIN_NATRE_DAYS_YEAR     as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_YEAR       as ��������_��
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
left join DM.T_AST_APPTBUYB t1 on t_rq.��������=t1.OCCUR_DT
group by
	t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ��_�³�
	,t1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.p_ast_cptl_chg(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  ������: �ʲ��䶯��
  ��д��: rengz
  ��������: 2017-11-21
  ��飺�ͻ��ʽ�䶯���ݣ��ո���
        ��Ҫ���������ڣ�T_DDW_F00_KHMRZJZHHZ_D �ձ� ��ͨ�˻��ʽ� ����ֵ��������
                        tmp_ddw_khqjt_m_m     ������ȯ�ͻ��ʽ����� ����

  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
             20180315                 rengz              �޶���ֵ��������
  *********************************************************************/
 
    --declare @v_bin_date numeric(8); 
    
    set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date =@v_bin_date;
	
    --������������
    --set @v_b_date=(select min(rq) from dba.t_ddw_d_rq where nian=substring(@V_BIN_DATE,1,4) and yue=substring(@V_BIN_DATE,5,2) and sfjrbz='1' ); 
   
    --ɾ������������
    delete from dm.t_ast_cptl_chg where load_dt =@v_bin_date;
    commit;
     
------------------------
  -- ����ÿ�տͻ��嵥
------------------------  
    select distinct fund_account, client_id, asset_prop, main_flag
      into #t_client
      from dba.t_edw_uf2_fundaccount
     where load_dt = @v_bin_date
       and fundacct_status = '0';
    commit;
     
    insert into dm.t_ast_cptl_chg(OCCUR_DT,CUST_ID, MAIN_CPTL_ACCT,CRED_CPTL_ACCT,LOAD_DT)
    select @v_bin_date as occur_dt,a.client_id,b.fund_account as zjzh_pt,c.fund_account as zjzh_xy,@v_bin_date as load_dt
    from (select distinct client_id from #t_client where  main_flag = '1')     a
    left join (select distinct client_id,fund_account from #t_client where asset_prop='0' and main_flag = '1') b on a.client_id=b.client_id
    left join (select distinct client_id,fund_account from #t_client where asset_prop='7' and main_flag = '1') c on a.client_id=c.client_id
    where a.client_id not in ('448999999'); ----�޳�1����ר��ͷ���˻��Զ����ɡ������ƹ�˾�����˻���client_id������ͨ�˻�������23�������˻��Ҿ�Ϊ���ʽ�

   commit;

------------------------
  -- ��ͨ�ʽ��˺��ʽ����� �ʽ�����
------------------------
 
  select c.client_id as cust_id,
         sum(a.zjlr * b.turn_rmb / b.turn_rate) as ptzjlr,
         sum(a.zjlc * b.turn_rmb / b.turn_rate) as ptzjlc,
         ptzjlr - ptzjlc as ptzjjlr
    into #t_pt_zjld
    from dba.t_ddw_f00_khzjhz_d a
    left join dba.T_EDW_T06_YEAR_EXCHANGE_RATE b
      on a.tjrq between b.star_dt and b.end_dt
     and a.bzlb = b.curr_type_cd
    left join (select distinct client_id, fund_account
                 from #t_client
                where asset_prop = '0') c
      on a.zjzh = c.fund_account
   where a.load_dt = @v_bin_date
   group by cust_id;

  commit;

 
   update dm.t_ast_cptl_chg  
   set ODI_CPTL_INFLOW         =coalesce(b.ptzjlr,0) ,----��ͨ�ʽ�����
       ODI_CPTL_OUTFLOW        =coalesce(b.ptzjlc,0), ----��ͨ�ʽ�����
       ODI_ACC_CPTL_NET_INFLOW =coalesce(b.ptzjjlr,0) ----��ͨ�ʽ�����
   from  dm.t_ast_cptl_chg a
   left join    #t_pt_zjld b on a.cust_id       =b.cust_id
   where a.OCCUR_DT      =@v_bin_date ;
   commit;
 

------------------------
  -- ��ͨ�ʽ��˺���ֵ���� ��ֵ����
------------------------
  select c.client_id as cust_id,
       --ÿ����ֵ���� = ת�й�ת����ֵ��ָ��ת����ֵ + ��������ҵ��(3410---�¹����е���)
       SUM((COALESCE(a.ztgzrsz, 0) + COALESCE(a.zdzrsz, 0)) +
           (COALESCE(case when a.busi_type_cd = '3410' and a.zqlx in ('10', '18') and a.sclx = '05' then a.qsje else 0 end, 0)) * b.turn_rmb / b.turn_rate) as mrszlr,
       --ÿ����ֵ���� = ת�й�ת����ֵ��ָ��ת����ֵ
       SUM((COALESCE(a.ztgzcsz, 0) + COALESCE(a.zdzcsz, 0)) * b.turn_rmb / b.turn_rate) as mrszlc
  into #t_pt_szld
  from dba.T_DDW_F00_KHZQHZ_D a
  left join dba.T_EDW_T06_YEAR_EXCHANGE_RATE b on a.tjrq between b.star_dt and b.end_dt and a.bzlb = b.curr_type_cd
    left join (select distinct client_id, fund_account
                 from #t_client
                where asset_prop = '0') c
      on a.zjzh = c.fund_account
  where a.load_dt = @v_bin_date 
 group by cust_id;


   update dm.t_ast_cptl_chg 
   set ODI_MVAL_INFLOW  =coalesce(b.mrszlr,0) ,----��ͨ��ֵ����
       ODI_MVAL_OUTFLOW =coalesce(b.mrszlc,0)  ----��ͨ��ֵ����            ---20180315 �޶�����
   from  dm.t_ast_cptl_chg a
   left join    #t_pt_szld b on a.cust_id       =b.cust_id
   where a.OCCUR_DT      =@v_bin_date ;
   commit;


 
------------------------
  -- �����˺��ʽ����� �ʽ�����
------------------------
     select client_id as cust_id,
            SUM(case when business_flag = 2041 then ABS(occur_balance) else 0 end) as zjlr_rzrq_d, -- �����ʽ�ת��_������ȯϵͳ
            SUM(case when business_flag = 2042 then ABS(occur_balance) else 0 end) as zjlc_rzrq_d, -- �����ʽ�ת��_������ȯϵͳ
            zjlr_rzrq_d - zjlc_rzrq_d as zjjlr_rzrq_d  -- �����ʽ�����_������ȯϵͳ
     into #t_rzrq_zjld
       from dba.t_edw_rzrq_hisfundjour as a
      where a.load_dt=@v_bin_date
        and a.business_flag in (2041, 2042)
      group by cust_id;
 
 commit;


   update dm.t_ast_cptl_chg  
   set CREDIT_CPTL_INFLOW     =coalesce(b.zjlr_rzrq_d,0) ,----�����ʽ�����
       CREDIT_CPTL_OUTFLOW    =coalesce(b.zjlc_rzrq_d,0) ,----�����ʽ�����
       CREDIT_CPTL_NET_INFLOW =coalesce(b.zjjlr_rzrq_d,0) ----�����ʽ����� 
   from  dm.t_ast_cptl_chg a
   left join  #t_rzrq_zjld b on a.CUST_ID =b.cust_id
   where a.OCCUR_DT=@v_bin_date ;

commit;

  set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 

end
GO
GRANT EXECUTE ON dm.p_ast_cptl_chg TO query_dev
GO
GRANT EXECUTE ON dm.p_ast_cptl_chg TO xydc
GO
CREATE PROCEDURE dm.P_AST_CPTL_CHG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д����ʲ��䶯�±�
  ��д��: DCY
  ��������: 2018-01-05
  ��飺�ʲ��䶯�±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --��Ȼ��_�³�
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --��Ȼ��_��ĩ
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --������_�³�
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --������_��ĩ
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --��Ȼ��_���
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --������_���
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --��������_��
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --��������_��


    ----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
 
--PART0 ɾ����������
  DELETE FROM DM.T_AST_CPTL_CHG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_AST_CPTL_CHG_M_D 
	(
	CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,ODI_CPTL_INFLOW_MTD
	,ODI_CPTL_OUTFLOW_MTD
	,ODI_MVAL_INFLOW_MTD
	,ODI_MVAL_OUTFLOW_MTD
	,CREDIT_CPTL_INFLOW_MTD
	,CREDIT_CPTL_OUTFLOW_MTD
	,ODI_ACC_CPTL_NET_INFLOW_MTD
	,CREDIT_CPTL_NET_INFLOW_MTD
	,ODI_CPTL_INFLOW_YTD
	,ODI_CPTL_OUTFLOW_YTD
	,ODI_MVAL_INFLOW_YTD
	,ODI_MVAL_OUTFLOW_YTD
	,CREDIT_CPTL_INFLOW_YTD
	,CREDIT_CPTL_OUTFLOW_YTD
	,ODI_ACC_CPTL_NET_INFLOW_YTD
	,CREDIT_CPTL_NET_INFLOW_YTD
	,LOAD_DT
	)
select		
	t1.CUST_ID as �ͻ�����
    ,@V_BIN_DATE AS OCCUR_DT	
	,t_rq.��
	,t_rq.��		
	,t_rq.��||t_rq.�� as ����
	,t_rq.��||t_rq.��||t1.CUST_ID as ���¿ͻ�����
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.ODI_CPTL_INFLOW else 0 end) 			as ��ͨ�ʽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.ODI_CPTL_OUTFLOW else 0 end) 		as ��ͨ�ʽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.ODI_MVAL_INFLOW else 0 end) 			as ��ͨ��ֵ����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.ODI_MVAL_OUTFLOW else 0 end) 		as ��ͨ��ֵ����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.CREDIT_CPTL_INFLOW else 0 end) 		as �����ʽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.CREDIT_CPTL_OUTFLOW else 0 end) 		as �����ʽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.ODI_ACC_CPTL_NET_INFLOW else 0 end) 	as ��ͨ�˻��ʽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then t1.CREDIT_CPTL_NET_INFLOW else 0 end) 	as �����ʽ�����_���ۼ�

	,sum(t1.ODI_CPTL_INFLOW) 			as ��ͨ�ʽ�����_���ۼ�
	,sum(t1.ODI_CPTL_OUTFLOW) 			as ��ͨ�ʽ�����_���ۼ�
	,sum(t1.ODI_MVAL_INFLOW) 			as ��ͨ��ֵ����_���ۼ�
	,sum(t1.ODI_MVAL_OUTFLOW) 			as ��ͨ��ֵ����_���ۼ�
	,sum(t1.CREDIT_CPTL_INFLOW) 		as �����ʽ�����_���ۼ�
	,sum(t1.CREDIT_CPTL_OUTFLOW) 		as �����ʽ�����_���ۼ�
	,sum(t1.ODI_ACC_CPTL_NET_INFLOW)	as ��ͨ�˻��ʽ�����_���ۼ�
	,sum(t1.CREDIT_CPTL_NET_INFLOW) 	as �����ʽ�����_���ۼ�
	,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as ��
		,@V_BIN_MTH as ��
		,t1.DT as ����
		,t1.TRD_DT as ��������
		,@V_BIN_NATRE_DAY_MTHBEG    as ��Ȼ��_�³�
		,@V_BIN_NATRE_DAY_MTHEND    as ��Ȼ��_��ĩ
		,@V_BIN_TRD_DAY_MTHBEG      as ������_�³�
		,@V_BIN_TRD_DAY_MTHEND      as ������_��ĩ
		,@V_BIN_NATRE_DAY_YEARBGN   as ��Ȼ��_���
		,@V_BIN_TRD_DAY_YEARBGN     as ������_���
		,@V_BIN_NATRE_DAYS_MTH      as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_MTH        as ��������_��
		,@V_BIN_NATRE_DAYS_YEAR     as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_YEAR       as ��������_��
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
--�ʲ��䶯�����
left join DM.T_AST_CPTL_CHG t1 on t_rq.��������=t1.OCCUR_DT	
group by
	t_rq.��
	,t_rq.��		
	,t1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.P_AST_CREDIT(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_�ʲ���������ȯ�ʲ���ծ
      ��д�ߣ�chenhu
      �������ڣ�2017-11-22
      ��飺
        ���ڿͻ����ݵ��ʲ��븺ծ
    *********************************************************************
   �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
              20180412                 rengz              ����A����ֵ
   *********************************************************************/

    --ɾ����������
    DELETE FROM DM.T_AST_CREDIT WHERE OCCUR_DT = @V_IN_DATE;
    
    INSERT INTO DM.T_AST_CREDIT
        (CUST_ID,OCCUR_DT,TOT_AST,TOT_LIAB,NET_AST,CRED_MARG,GUAR_SECU_MVAL,FIN_LIAB,CRDT_STK_LIAB,INTR_LIAB,FEE_LIAB,OTH_LIAB,LOAD_DT)
    SELECT CLIENT_ID    AS CUST_ID          --�ͻ����
        ,INIT_DATE      AS OCCUR_DT         --ҵ������
        ,ASSURE_CLOSE_BALANCE   AS TOT_AST  --���ʲ�
        ,COALESCE(FIN_CLOSE_BALANCE, 0) + COALESCE(SLO_CLOSE_BALANCE, 0) + COALESCE(FARE_CLOSE_DEBIT, 0) + COALESCE(OTHER_CLOSE_DEBIT, 0) + 
         COALESCE(FIN_CLOSE_INTEREST, 0) + COALESCE(SLO_CLOSE_INTEREST, 0) + COALESCE(FARE_CLOSE_INTEREST, 0) + COALESCE(OTHER_CLOSE_INTEREST, 0) +
         COALESCE(FIN_CLOSE_FINE_INTEREST, 0) + COALESCE(SLO_CLOSE_FINE_INTEREST, 0) + COALESCE(OTHER_CLOSE_FINE_INTEREST, 0) + COALESCE(REFCOST_CLOSE_FARE, 0) AS TOT_LIAB     --�ܸ�ծ
        ,TOT_AST - TOT_LIAB     AS NET_AST          --���ʲ�
        ,CURRENT_BALANCE        AS CRED_MARG        --���ñ�֤��
        ,MARKET_CLOSE_VALUE     AS GUAR_SECU_MVAL   --����֤ȯ��ֵ
        ,FIN_CLOSE_BALANCE      AS FIN_LIAB         --���ʸ�ծ
        ,SLO_CLOSE_BALANCE      AS CRDT_STK_LIAB    --��ȯ��ծ
        ,COALESCE(FIN_CLOSE_INTEREST, 0) + COALESCE(SLO_CLOSE_INTEREST, 0) + COALESCE(FARE_CLOSE_INTEREST, 0) + COALESCE(OTHER_CLOSE_INTEREST, 0)               AS INTR_LIAB    --��Ϣ��ծ
        ,FARE_CLOSE_DEBIT       AS FEE_LIAB         --���ø�ծ
        ,OTHER_CLOSE_DEBIT      AS OTH_LIAB         --������ծ
        ,INIT_DATE              AS LOAD_DT          --��ϴ����
    FROM DBA.T_EDW_UF2_RZRQ_ASSETDEBIT
    WHERE INIT_DATE = @V_IN_DATE;    
    
    COMMIT;

    --�����˻�A����ֵ
     select client_id,sum(a.current_amount*b.trad_price) as A_SHR_MVAL 
     into #t_xysz
      from   dba.t_edw_rzrq_stock  a
     left join dba.t_edw_t06_stock_maket_info  b on a.load_dt=b.load_dt and a.STOCK_CODE=b.stock_cd  and b.stock_type_cd in ('10','A1')
     where a.load_dt=@V_IN_DATE
     group by a.client_id;

    update DM.T_AST_CREDIT 
    set  A_SHR_MVAL=coalesce(b.A_SHR_MVAL,0)
    from DM.T_AST_CREDIT a 
    left join #t_xysz    b on a.cust_id=b.client_id
    where a.OCCUR_DT=@V_IN_DATE;
    
    commit;

END
GO
GRANT EXECUTE ON dm.P_AST_CREDIT TO xydc
GO
CREATE PROCEDURE dm.P_AST_CREDIT_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���������ȯ�ʲ��±�
  ��д��: DCY
  ��������: 2018-01-05
  ��飺������ȯ�ʲ��±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --��Ȼ��_�³�
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --��Ȼ��_��ĩ
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --������_�³�
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --������_��ĩ
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --��Ȼ��_���
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --������_���
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --��������_��
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --��������_��


    ----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 ɾ����������
  DELETE FROM DM.T_AST_CREDIT_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_AST_CREDIT_M_D 
	(
	CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,TOT_LIAB_FINAL
	,NET_AST_FINAL
	,CRED_MARG_FINAL
	,GUAR_SECU_MVAL_FINAL
	,FIN_LIAB_FINAL
	,CRDT_STK_LIAB_FINAL
	,INTR_LIAB_FINAL
	,FEE_LIAB_FINAL
	,OTH_LIAB_FINAL
	,TOT_AST_FINAL
	,A_SHR_MVAL_FINAL
	,TOT_LIAB_MDA
	,NET_AST_MDA
	,CRED_MARG_MDA
	,GUAR_SECU_MVAL_MDA
	,FIN_LIAB_MDA
	,CRDT_STK_LIAB_MDA
	,INTR_LIAB_MDA
	,FEE_LIAB_MDA
	,OTH_LIAB_MDA
	,TOT_AST_MDA
	,A_SHR_MVAL_MDA
	,TOT_LIAB_YDA
	,NET_AST_YDA
	,CRED_MARG_YDA
	,GUAR_SECU_MVAL_YDA
	,FIN_LIAB_YDA
	,CRDT_STK_LIAB_YDA
	,INTR_LIAB_YDA
	,FEE_LIAB_YDA
	,OTH_LIAB_YDA
	,TOT_AST_YDA
	,A_SHR_MVAL_YDA
	,LOAD_DT
	)
select
    t1.CUST_ID as �ͻ�����	
	,@V_BIN_DATE AS OCCUR_DT
	,t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ��_�³�
	,t_rq.��||t_rq.�� as ����
	,t_rq.��||t_rq.��||t1.CUST_ID as ���¿ͻ����
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.TOT_LIAB,0) else 0 end) 		as �ܸ�ծ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.NET_AST,0) else 0 end) 		as ���ʲ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.CRED_MARG,0) else 0 end) 	as ���ñ�֤��_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end) as ����֤ȯ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.FIN_LIAB,0) else 0 end) 		as ���ʸ�ծ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.CRDT_STK_LIAB,0) else 0 end) as ��ȯ��ծ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.INTR_LIAB,0) else 0 end) 	as ��Ϣ��ծ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.FEE_LIAB,0) else 0 end) 		as ���ø�ծ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OTH_LIAB,0) else 0 end) 		as ������ծ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.TOT_AST,0) else 0 end) 		as ���ʲ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.A_SHR_MVAL,0) else 0 end) 

	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.TOT_LIAB,0) else 0 end)/t_rq.��Ȼ����_�� 		as �ܸ�ծ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.NET_AST,0) else 0 end)/t_rq.��Ȼ����_�� 		as ���ʲ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CRED_MARG,0) else 0 end)/t_rq.��Ȼ����_�� 		as ���ñ�֤��_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.GUAR_SECU_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� 	as ����֤ȯ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FIN_LIAB,0) else 0 end)/t_rq.��Ȼ����_�� 		as ���ʸ�ծ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CRDT_STK_LIAB,0) else 0 end)/t_rq.��Ȼ����_�� 	as ��ȯ��ծ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.INTR_LIAB,0) else 0 end)/t_rq.��Ȼ����_�� 		as ��Ϣ��ծ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FEE_LIAB,0) else 0 end)/t_rq.��Ȼ����_��		as ���ø�ծ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OTH_LIAB,0) else 0 end)/t_rq.��Ȼ����_�� 		as ������ծ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.TOT_AST,0) else 0 end)/t_rq.��Ȼ����_�� 		as ���ʲ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.A_SHR_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� 

	,sum(COALESCE(t1.TOT_LIAB,0))/t_rq.��Ȼ����_�� 			as �ܸ�ծ_���վ�
	,sum(COALESCE(t1.NET_AST,0))/t_rq.��Ȼ����_�� 			as ���ʲ�_���վ�
	,sum(COALESCE(t1.CRED_MARG,0))/t_rq.��Ȼ����_�� 		as ���ñ�֤��_���վ�
	,sum(COALESCE(t1.GUAR_SECU_MVAL,0))/t_rq.��Ȼ����_�� 	as ����֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.FIN_LIAB,0))/t_rq.��Ȼ����_�� 			as ���ʸ�ծ_���վ�
	,sum(COALESCE(t1.CRDT_STK_LIAB,0))/t_rq.��Ȼ����_�� 	as ��ȯ��ծ_���վ�
	,sum(COALESCE(t1.INTR_LIAB,0))/t_rq.��Ȼ����_�� as ��Ϣ��ծ_���վ�
	,sum(COALESCE(t1.FEE_LIAB,0))/t_rq.��Ȼ����_�� 	as ���ø�ծ_���վ�
	,sum(COALESCE(t1.OTH_LIAB,0))/t_rq.��Ȼ����_�� 	as ������ծ_���վ�
	,sum(COALESCE(t1.TOT_AST,0))/t_rq.��Ȼ����_�� 	as ���ʲ�_���վ�
	,sum(COALESCE(t1.A_SHR_MVAL,0))/t_rq.��Ȼ����_��
    ,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as ��
		,@V_BIN_MTH as ��
		,t1.DT as ����
		,t1.TRD_DT as ��������
		,@V_BIN_NATRE_DAY_MTHBEG    as ��Ȼ��_�³�
		,@V_BIN_NATRE_DAY_MTHEND    as ��Ȼ��_��ĩ
		,@V_BIN_TRD_DAY_MTHBEG      as ������_�³�
		,@V_BIN_TRD_DAY_MTHEND      as ������_��ĩ
		,@V_BIN_NATRE_DAY_YEARBGN   as ��Ȼ��_���
		,@V_BIN_TRD_DAY_YEARBGN     as ������_���
		,@V_BIN_NATRE_DAYS_MTH      as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_MTH        as ��������_��
		,@V_BIN_NATRE_DAYS_YEAR     as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_YEAR       as ��������_��
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
left join DM.T_AST_CREDIT t1 on t_rq.��������=t1.OCCUR_DT
group by
	t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ��_�³�
	,t1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.P_AST_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ӫҵ���ʲ����ձ�
  ��д��: Ҷ���
  ��������: 2018-04-10
  ��飺Ӫҵ��ά�ȵĿͻ��ʲ���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	DELETE FROM DM.T_AST_D_BRH WHERE OCCUR_DT = @V_DATE;

	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--Ա������
		,A.PK_ORG 		AS 		BRH_ID			--Ӫҵ������
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  	  	AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	CREATE TABLE #TMP_T_AST_D_BRH(
	    OCCUR_DT             numeric(8,0) 	NOT NULL,
		EMP_ID               varchar(30) 	NOT NULL,
		BRH_ID		  		 varchar(30) 	NOT NULL,
		TOT_AST              numeric(38,8) NULL,
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
		TOT_AST_CONTAIN_NOTS numeric(38,8) NULL,
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
		CREDIT_TOT_AST       numeric(38,8) NULL,
		CREDIT_TOT_LIAB      numeric(38,8) NULL,
		APPTBUYB_GUAR_SECMV  numeric(38,8) NULL,
		CREDIT_GUAR_SECMV    numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_AST_D_BRH(
		 OCCUR_DT            		--��������	
		,EMP_ID              		--Ա�����
		,BRH_ID		  		 		--Ӫҵ�����	
		,TOT_AST             		--���ʲ�	
		,SCDY_MVAL           		--������ֵ	
		,STKF_MVAL           		--�ɻ���ֵ	
		,A_SHR_MVAL          		--A����ֵ	
		,NOTS_MVAL           		--���۹���ֵ	
		,OFFUND_MVAL         		--���ڻ�����ֵ	
		,OPFUND_MVAL         		--���������ֵ	
		,SB_MVAL             		--������ֵ	
		,IMGT_PD_MVAL        		--�ʹܲ�Ʒ��ֵ	
		,BANK_CHRM_MVAL      		--���������ֵ	
		,SECU_CHRM_MVAL      		--֤ȯ�����ֵ	
		,PSTK_OPTN_MVAL      		--������Ȩ��ֵ	
		,B_SHR_MVAL          		--B����ֵ	
		,OUTMARK_MVAL        		--������ֵ	
		,CPTL_BAL            		--�ʽ����	
		,NO_ARVD_CPTL        		--δ�����ʽ�	
		,PTE_FUND_MVAL       		--˽ļ������ֵ	
		,CPTL_BAL_RMB        		--�ʽ���������	
		,CPTL_BAL_HKD        		--�ʽ����۱�	
		,CPTL_BAL_USD        		--�ʽ������Ԫ	
		,FUND_SPACCT_MVAL    		--����ר��	
		,HGT_MVAL            		--����ͨ��ֵ	
		,SGT_MVAL            		--���ͨ��ֵ	
		,TOT_AST_CONTAIN_NOTS		--���ʲ�_�����۹�	
		,BOND_MVAL           		--ծȯ��ֵ	
		,REPO_MVAL           		--�ع���ֵ	
		,TREA_REPO_MVAL      		--��ծ�ع���ֵ	
		,REPQ_MVAL           		--���ۻع���ֵ	
		,PO_FUND_MVAL        		--��ļ������ֵ	
		,APPTBUYB_PLG_MVAL   		--Լ��������Ѻ��ֵ	
		,OTH_PROD_MVAL       		--������Ʒ��ֵ	
		,STKT_FUND_MVAL      		--��Ʊ�ͻ�����ֵ	
		,OTH_AST_MVAL        		--�����ʲ���ֵ	
		,CREDIT_MARG         		--������ȯ��֤��	
		,CREDIT_NET_AST      		--������ȯ���ʲ�	
		,PROD_TOT_MVAL       		--��Ʒ����ֵ	
		,JQL9_MVAL           		--������9��ֵ	
		,STKPLG_GUAR_SECMV   		--��Ʊ��Ѻ����֤ȯ��ֵ
		,STKPLG_FIN_BAL      		--��Ʊ��Ѻ�������	
		,APPTBUYB_BAL        		--Լ���������	
		,CRED_MARG           		--���ñ�֤��	
		,INTR_LIAB           		--��Ϣ��ծ	
		,FEE_LIAB            		--���ø�ծ	
		,OTHLIAB             		--������ծ	
		,FIN_LIAB            		--���ʸ�ծ	
		,CRDT_STK_LIAB       		--��ȯ��ծ	
		,CREDIT_TOT_AST      		--������ȯ���ʲ�	
		,CREDIT_TOT_LIAB     		--������ȯ�ܸ�ծ	
		,APPTBUYB_GUAR_SECMV 		--Լ�����ص���֤ȯ��ֵ
		,CREDIT_GUAR_SECMV   		--������ȯ����֤ȯ��ֵ
	)
	SELECT 
		 T.OCCUR_DT            			AS  	OCCUR_DT            		--��������	
		,T.EMP_ID              			AS  	EMP_ID              		--Ա�����
		,T1.BRH_ID		  		 		AS  	BRH_ID		  		 		--Ӫҵ�����	
		,T.TOT_AST             			AS  	TOT_AST             		--���ʲ�	
		,T.SCDY_MVAL           			AS  	SCDY_MVAL           		--������ֵ	
		,T.STKF_MVAL           			AS  	STKF_MVAL           		--�ɻ���ֵ	
		,T.A_SHR_MVAL          			AS  	A_SHR_MVAL          		--A����ֵ	
		,T.NOTS_MVAL           			AS  	NOTS_MVAL           		--���۹���ֵ	
		,T.OFFUND_MVAL         			AS  	OFFUND_MVAL         		--���ڻ�����ֵ	
		,T.OPFUND_MVAL         			AS  	OPFUND_MVAL         		--���������ֵ	
		,T.SB_MVAL             			AS  	SB_MVAL             		--������ֵ	
		,T.IMGT_PD_MVAL        			AS  	IMGT_PD_MVAL        		--�ʹܲ�Ʒ��ֵ	
		,T.BANK_CHRM_MVAL      			AS  	BANK_CHRM_MVAL      		--���������ֵ	
		,T.SECU_CHRM_MVAL      			AS  	SECU_CHRM_MVAL      		--֤ȯ�����ֵ	
		,T.PSTK_OPTN_MVAL      			AS  	PSTK_OPTN_MVAL      		--������Ȩ��ֵ	
		,T.B_SHR_MVAL          			AS  	B_SHR_MVAL          		--B����ֵ	
		,T.OUTMARK_MVAL        			AS  	OUTMARK_MVAL        		--������ֵ	
		,T.CPTL_BAL            			AS  	CPTL_BAL            		--�ʽ����	
		,T.NO_ARVD_CPTL        			AS  	NO_ARVD_CPTL        		--δ�����ʽ�	
		,T.PTE_FUND_MVAL       			AS  	PTE_FUND_MVAL       		--˽ļ������ֵ	
		,T.CPTL_BAL_RMB        			AS  	CPTL_BAL_RMB        		--�ʽ���������	
		,T.CPTL_BAL_HKD        			AS  	CPTL_BAL_HKD        		--�ʽ����۱�	
		,T.CPTL_BAL_USD        			AS  	CPTL_BAL_USD        		--�ʽ������Ԫ	
		,T.FUND_SPACCT_MVAL    			AS  	FUND_SPACCT_MVAL    		--����ר��	
		,T.HGT_MVAL            			AS  	HGT_MVAL            		--����ͨ��ֵ	
		,T.SGT_MVAL            			AS  	SGT_MVAL            		--���ͨ��ֵ	
		,T.TOT_AST_CONTAIN_NOTS			AS  	TOT_AST_CONTAIN_NOTS		--���ʲ�_�����۹�	
		,T.BOND_MVAL           			AS  	BOND_MVAL           		--ծȯ��ֵ	
		,T.REPO_MVAL           			AS  	REPO_MVAL           		--�ع���ֵ	
		,T.TREA_REPO_MVAL      			AS  	TREA_REPO_MVAL      		--��ծ�ع���ֵ	
		,T.REPQ_MVAL           			AS  	REPQ_MVAL           		--���ۻع���ֵ	
		,T.PO_FUND_MVAL        			AS  	PO_FUND_MVAL        		--��ļ������ֵ	
		,T.APPTBUYB_PLG_MVAL   			AS  	APPTBUYB_PLG_MVAL   		--Լ��������Ѻ��ֵ	
		,T.OTH_PROD_MVAL       			AS  	OTH_PROD_MVAL       		--������Ʒ��ֵ	
		,T.STKT_FUND_MVAL      			AS  	STKT_FUND_MVAL      		--��Ʊ�ͻ�����ֵ	
		,T.OTH_AST_MVAL        			AS  	OTH_AST_MVAL        		--�����ʲ���ֵ	
		,T.CREDIT_MARG         			AS  	CREDIT_MARG         		--������ȯ��֤��	
		,T.CREDIT_NET_AST      			AS  	CREDIT_NET_AST      		--������ȯ���ʲ�	
		,T.PROD_TOT_MVAL       			AS  	PROD_TOT_MVAL       		--��Ʒ����ֵ	
		,T.JQL9_MVAL           			AS  	JQL9_MVAL           		--������9��ֵ	
		,T.STKPLG_GUAR_SECMV   			AS  	STKPLG_GUAR_SECMV   		--��Ʊ��Ѻ����֤ȯ��
		,T.STKPLG_FIN_BAL      			AS  	STKPLG_FIN_BAL      		--��Ʊ��Ѻ�������	
		,T.APPTBUYB_BAL        			AS  	APPTBUYB_BAL        		--Լ���������	
		,T.CRED_MARG           			AS  	CRED_MARG           		--���ñ�֤��	
		,T.INTR_LIAB           			AS  	INTR_LIAB           		--��Ϣ��ծ	
		,T.FEE_LIAB            			AS  	FEE_LIAB            		--���ø�ծ	
		,T.OTHLIAB             			AS  	OTHLIAB             		--������ծ	
		,T.FIN_LIAB            			AS  	FIN_LIAB            		--���ʸ�ծ	
		,T.CRDT_STK_LIAB       			AS  	CRDT_STK_LIAB       		--��ȯ��ծ	
		,T.CREDIT_TOT_AST      			AS  	CREDIT_TOT_AST      		--������ȯ���ʲ�	
		,T.CREDIT_TOT_LIAB     			AS  	CREDIT_TOT_LIAB     		--������ȯ�ܸ�ծ	
		,T.APPTBUYB_GUAR_SECMV 			AS  	APPTBUYB_GUAR_SECMV 		--Լ�����ص���֤ȯ��
		,T.CREDIT_GUAR_SECMV   			AS  	CREDIT_GUAR_SECMV   		--������ȯ����֤ȯ��
	FROM DM.T_AST_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	  AND T1.BRH_ID IS NOT NULL;
	
	--����ʱ��İ�Ӫҵ��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	INSERT INTO DM.T_AST_D_BRH (
			 OCCUR_DT            		--��������	
			,BRH_ID              		--Ӫҵ�����	
			,TOT_AST             		--���ʲ�	
			,SCDY_MVAL           		--������ֵ	
			,STKF_MVAL           		--�ɻ���ֵ	
			,A_SHR_MVAL          		--A����ֵ	
			,NOTS_MVAL           		--���۹���ֵ	
			,OFFUND_MVAL         		--���ڻ�����ֵ	
			,OPFUND_MVAL         		--���������ֵ	
			,SB_MVAL             		--������ֵ	
			,IMGT_PD_MVAL        		--�ʹܲ�Ʒ��ֵ	
			,BANK_CHRM_MVAL      		--���������ֵ	
			,SECU_CHRM_MVAL      		--֤ȯ�����ֵ	
			,PSTK_OPTN_MVAL      		--������Ȩ��ֵ	
			,B_SHR_MVAL          		--B����ֵ	
			,OUTMARK_MVAL        		--������ֵ	
			,CPTL_BAL            		--�ʽ����	
			,NO_ARVD_CPTL        		--δ�����ʽ�	
			,PTE_FUND_MVAL       		--˽ļ������ֵ	
			,CPTL_BAL_RMB        		--�ʽ���������	
			,CPTL_BAL_HKD        		--�ʽ����۱�	
			,CPTL_BAL_USD        		--�ʽ������Ԫ	
			,FUND_SPACCT_MVAL    		--����ר��	
			,HGT_MVAL            		--����ͨ��ֵ	
			,SGT_MVAL            		--���ͨ��ֵ	
			,TOT_AST_CONTAIN_NOTS		--���ʲ�_�����۹�	
			,BOND_MVAL           		--ծȯ��ֵ	
			,REPO_MVAL           		--�ع���ֵ	
			,TREA_REPO_MVAL      		--��ծ�ع���ֵ	
			,REPQ_MVAL           		--���ۻع���ֵ	
			,PO_FUND_MVAL        		--��ļ������ֵ	
			,APPTBUYB_PLG_MVAL   		--Լ��������Ѻ��ֵ	
			,OTH_PROD_MVAL       		--������Ʒ��ֵ	
			,STKT_FUND_MVAL      		--��Ʊ�ͻ�����ֵ	
			,OTH_AST_MVAL        		--�����ʲ���ֵ	
			,CREDIT_MARG         		--������ȯ��֤��	
			,CREDIT_NET_AST      		--������ȯ���ʲ�	
			,PROD_TOT_MVAL       		--��Ʒ����ֵ	
			,JQL9_MVAL           		--������9��ֵ	
			,STKPLG_GUAR_SECMV   		--��Ʊ��Ѻ����֤ȯ��ֵ	
			,STKPLG_FIN_BAL      		--��Ʊ��Ѻ�������	
			,APPTBUYB_BAL        		--Լ���������	
			,CRED_MARG           		--���ñ�֤��	
			,INTR_LIAB           		--��Ϣ��ծ	
			,FEE_LIAB            		--���ø�ծ	
			,OTHLIAB             		--������ծ	
			,FIN_LIAB            		--���ʸ�ծ	
			,CRDT_STK_LIAB       		--��ȯ��ծ	
			,CREDIT_TOT_AST      		--������ȯ���ʲ�	
			,CREDIT_TOT_LIAB     		--������ȯ�ܸ�ծ	
			,APPTBUYB_GUAR_SECMV 		--Լ�����ص���֤ȯ��ֵ	
			,CREDIT_GUAR_SECMV   		--������ȯ����֤ȯ��ֵ
		)
		SELECT 
			 OCCUR_DT 						AS      OCCUR_DT                 --��������	 
			,BRH_ID		  		 			AS  	BRH_ID		  		 	 --Ӫҵ�����	
			,SUM(TOT_AST)             		AS      TOT_AST                  --���ʲ�	 	
			,SUM(SCDY_MVAL)           		AS      SCDY_MVAL                --������ֵ	 	
			,SUM(STKF_MVAL)          		AS      STKF_MVAL                --�ɻ���ֵ	 	
			,SUM(A_SHR_MVAL)          		AS      A_SHR_MVAL               --A����ֵ	 	
			,SUM(NOTS_MVAL)           		AS      NOTS_MVAL                --���۹���ֵ	 	
			,SUM(OFFUND_MVAL)         		AS      OFFUND_MVAL              --���ڻ�����ֵ	 	
			,SUM(OPFUND_MVAL)         		AS      OPFUND_MVAL              --���������ֵ	 	
			,SUM(SB_MVAL)             		AS      SB_MVAL                  --������ֵ	 	
			,SUM(IMGT_PD_MVAL)        		AS      IMGT_PD_MVAL             --�ʹܲ�Ʒ��ֵ	 	
			,SUM(BANK_CHRM_MVAL)      		AS      BANK_CHRM_MVAL           --���������ֵ	 	
			,SUM(SECU_CHRM_MVAL)      		AS      SECU_CHRM_MVAL           --֤ȯ�����ֵ	 	
			,SUM(PSTK_OPTN_MVAL)      		AS      PSTK_OPTN_MVAL           --������Ȩ��ֵ	 	
			,SUM(B_SHR_MVAL)          		AS      B_SHR_MVAL               --B����ֵ	 	
			,SUM(OUTMARK_MVAL)        		AS      OUTMARK_MVAL             --������ֵ	 	
			,SUM(CPTL_BAL)            		AS      CPTL_BAL                 --�ʽ����	 	
			,SUM(NO_ARVD_CPTL)        		AS      NO_ARVD_CPTL             --δ�����ʽ�	 	
			,SUM(PTE_FUND_MVAL)       		AS      PTE_FUND_MVAL            --˽ļ������ֵ	 	
			,SUM(CPTL_BAL_RMB)        		AS      CPTL_BAL_RMB             --�ʽ���������	 	
			,SUM(CPTL_BAL_HKD)        		AS      CPTL_BAL_HKD             --�ʽ����۱�	 	
			,SUM(CPTL_BAL_USD)        		AS      CPTL_BAL_USD             --�ʽ������Ԫ	 	
			,SUM(FUND_SPACCT_MVAL)    		AS      FUND_SPACCT_MVAL         --����ר��	 	
			,SUM(HGT_MVAL)            		AS      HGT_MVAL                 --����ͨ��ֵ	 	
			,SUM(SGT_MVAL)            		AS      SGT_MVAL                 --���ͨ��ֵ	 	
			,SUM(TOT_AST_CONTAIN_NOTS)		AS      TOT_AST_CONTAIN_NOTS     --���ʲ�_�����۹�	 	
			,SUM(BOND_MVAL)           		AS      BOND_MVAL                --ծȯ��ֵ	 	
			,SUM(REPO_MVAL)           		AS      REPO_MVAL                --�ع���ֵ	 	
			,SUM(TREA_REPO_MVAL)      		AS      TREA_REPO_MVAL           --��ծ�ع���ֵ	 	
			,SUM(REPQ_MVAL)           		AS      REPQ_MVAL                --���ۻع���ֵ	 	
			,SUM(PO_FUND_MVAL)        		AS      PO_FUND_MVAL             --��ļ������ֵ	 	
			,SUM(APPTBUYB_PLG_MVAL)   		AS      APPTBUYB_PLG_MVAL        --Լ��������Ѻ��ֵ	 	
			,SUM(OTH_PROD_MVAL)       		AS      OTH_PROD_MVAL            --������Ʒ��ֵ	 	
			,SUM(STKT_FUND_MVAL)      		AS      STKT_FUND_MVAL           --��Ʊ�ͻ�����ֵ	 	
			,SUM(OTH_AST_MVAL)        		AS      OTH_AST_MVAL             --�����ʲ���ֵ	 	
			,SUM(CREDIT_MARG)         		AS      CREDIT_MARG              --������ȯ��֤��	 	
			,SUM(CREDIT_NET_AST)      		AS      CREDIT_NET_AST           --������ȯ���ʲ�	 	
			,SUM(PROD_TOT_MVAL)       		AS      PROD_TOT_MVAL            --��Ʒ����ֵ	 	
			,SUM(JQL9_MVAL)           		AS      JQL9_MVAL                --������9��ֵ	 	
			,SUM(STKPLG_GUAR_SECMV)   		AS      STKPLG_GUAR_SECMV        --��Ʊ��Ѻ����֤ȯ��ֵ 	
			,SUM(STKPLG_FIN_BAL)      		AS      STKPLG_FIN_BAL           --��Ʊ��Ѻ�������	 	
			,SUM(APPTBUYB_BAL)        		AS      APPTBUYB_BAL             --Լ���������	 	
			,SUM(CRED_MARG)           		AS      CRED_MARG                --���ñ�֤��	 	
			,SUM(INTR_LIAB)           		AS      INTR_LIAB                --��Ϣ��ծ	 	
			,SUM(FEE_LIAB)            		AS      FEE_LIAB                 --���ø�ծ	 	
			,SUM(OTHLIAB)             		AS      OTHLIAB                  --������ծ	 	
			,SUM(FIN_LIAB)            		AS      FIN_LIAB                 --���ʸ�ծ	 	
			,SUM(CRDT_STK_LIAB)       		AS      CRDT_STK_LIAB            --��ȯ��ծ	 	
			,SUM(CREDIT_TOT_AST)      		AS      CREDIT_TOT_AST           --������ȯ���ʲ�	 	
			,SUM(CREDIT_TOT_LIAB)     		AS      CREDIT_TOT_LIAB          --������ȯ�ܸ�ծ	 	
			,SUM(APPTBUYB_GUAR_SECMV) 		AS      APPTBUYB_GUAR_SECMV      --Լ�����ص���֤ȯ��ֵ 	
			,SUM(CREDIT_GUAR_SECMV)   		AS      CREDIT_GUAR_SECMV        --������ȯ����֤ȯ��ֵ 	
		FROM #TMP_T_AST_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_AST_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ա���ʲ����ձ�
  ��д��: Ҷ���
  ��������: 2018-04-09
  ��飺Ա��ά�ȵĿͻ��ʲ���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	CREATE TABLE #TMP_T_AST_D_EMP(
	    OCCUR_DT             numeric(8,0)  NOT NULL,
		EMP_ID               varchar(30)   NOT NULL,
		MAIN_CPTL_ACCT		 varchar(30)   NOT NULL,
		CUST_ID				 varchar(30)   NOT NULL,
		TOT_AST              numeric(38,8) NULL,
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

	INSERT INTO #TMP_T_AST_D_EMP(
		 OCCUR_DT					
		,EMP_ID						
		,MAIN_CPTL_ACCT
		,CUST_ID
	)			
	SELECT 
		 @V_DATE AS OCCUR_DT			--��������
		,A.AFATWO_YGH AS EMP_ID			--Ա������
		,A.ZJZH AS MAIN_CPTL_ACCT		--�ʽ��˺�
		,A.KHBH_HS AS CUST_ID 			--�ͻ����
	FROM DBA.T_DDW_SERV_RELATION_D A
	WHERE A.RQ=@V_DATE
		AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  		   ,A.ZJZH
  		   ,A.KHBH_HS;


	-- ������Ȩ�����ͳ�ƣ�Ա��-�ͻ�����Ч�������

  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,A.KHBH_HS AS CUST_ID 		
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
  		AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH
  	          ,A.KHBH_HS;





	--���·����ĸ���ָ��
	UPDATE #TMP_T_AST_D_EMP
		SET 
				 TOT_AST             	= 	COALESCE(B1.TOT_AST             ,0)		*    C.PERFM_RATIO_1		--���ʲ�
				,SCDY_MVAL           	= 	COALESCE(B1.SCDY_MVAL           ,0)		*    C.PERFM_RATIO_1		--������ֵ
				,STKF_MVAL           	= 	COALESCE(B1.STKF_MVAL           ,0)		*    C.PERFM_RATIO_1		--�ɻ���ֵ
				,A_SHR_MVAL          	= 	COALESCE(B1.A_SHR_MVAL          ,0)		*    C.PERFM_RATIO_1		--A����ֵ
				,NOTS_MVAL           	= 	COALESCE(B1.NOTS_MVAL           ,0)		*    C.PERFM_RATIO_1		--���۹���ֵ
				,OFFUND_MVAL         	= 	COALESCE(B1.OFFUND_MVAL         ,0)		*    C.PERFM_RATIO_1		--���ڻ�����ֵ
				,OPFUND_MVAL         	= 	COALESCE(B1.OPFUND_MVAL         ,0)		*    C.PERFM_RATIO_1		--���������ֵ
				,SB_MVAL             	= 	COALESCE(B1.SB_MVAL             ,0)		*    C.PERFM_RATIO_1		--������ֵ
				,IMGT_PD_MVAL        	= 	COALESCE(B1.IMGT_PD_MVAL        ,0)		*    C.PERFM_RATIO_6		--�ʹܲ�Ʒ��ֵ
				,BANK_CHRM_MVAL      	= 	COALESCE(B1.BANK_CHRM_MVAL      ,0)		*    C.PERFM_RATIO_1		--���������ֵ
				,SECU_CHRM_MVAL      	= 	COALESCE(B1.SECU_CHRM_MVAL      ,0)		*    C.PERFM_RATIO_1		--֤ȯ�����ֵ
				,PSTK_OPTN_MVAL      	= 	COALESCE(B1.PSTK_OPTN_MVAL      ,0)		*    C.PERFM_RATIO_1		--������Ȩ��ֵ
				,B_SHR_MVAL          	= 	COALESCE(B1.B_SHR_MVAL          ,0)		*    C.PERFM_RATIO_1		--B����ֵ
				,OUTMARK_MVAL        	= 	COALESCE(B1.OUTMARK_MVAL        ,0)		*    C.PERFM_RATIO_1		--������ֵ
				,CPTL_BAL            	= 	COALESCE(B1.CPTL_BAL            ,0)		*    C.PERFM_RATIO_1		--�ʽ����
				,NO_ARVD_CPTL        	= 	COALESCE(B1.NO_ARVD_CPTL        ,0)		*    C.PERFM_RATIO_1		--δ�����ʽ�
				,PTE_FUND_MVAL       	= 	COALESCE(B1.PTE_FUND_MVAL       ,0)		*    C.PERFM_RATIO_7		--˽ļ������ֵ
				,CPTL_BAL_RMB        	= 	COALESCE(B1.CPTL_BAL_RMB        ,0)		*    C.PERFM_RATIO_1		--�ʽ���������
				,CPTL_BAL_HKD        	= 	COALESCE(B1.CPTL_BAL_HKD        ,0)		*    C.PERFM_RATIO_1		--�ʽ����۱�
				,CPTL_BAL_USD        	= 	COALESCE(B1.CPTL_BAL_USD        ,0)		*    C.PERFM_RATIO_1		--�ʽ������Ԫ
				,FUND_SPACCT_MVAL    	= 	COALESCE(B1.FUND_SPACCT_MVAL    ,0)		*    C.PERFM_RATIO_1		--����ר��
				,HGT_MVAL            	= 	COALESCE(B1.HGT_MVAL            ,0)		*    C.PERFM_RATIO_1		--����ͨ��ֵ
				,SGT_MVAL            	= 	COALESCE(B1.SGT_MVAL            ,0)		*    C.PERFM_RATIO_1		--���ͨ��ֵ
				,TOT_AST_CONTAIN_NOTS	= 	COALESCE(B1.TOT_AST_CONTAIN_NOTS,0)		*    C.PERFM_RATIO_1		--���ʲ�_�����۹�
				,BOND_MVAL           	= 	COALESCE(B1.BOND_MVAL           ,0)		*    C.PERFM_RATIO_1		--ծȯ��ֵ
				,REPO_MVAL           	= 	COALESCE(B1.REPO_MVAL           ,0)		*    C.PERFM_RATIO_1		--�ع���ֵ
				,TREA_REPO_MVAL      	= 	COALESCE(B1.TREA_REPO_MVAL      ,0)		*    C.PERFM_RATIO_1		--��ծ�ع���ֵ
				,REPQ_MVAL           	= 	COALESCE(B1.REPQ_MVAL           ,0)		*    C.PERFM_RATIO_1		--���ۻع���ֵ
				,PO_FUND_MVAL        	= 	COALESCE(B1.PO_FUND_MVAL        ,0)		*    C.PERFM_RATIO_1		--��ļ������ֵ
				,APPTBUYB_PLG_MVAL   	= 	COALESCE(B1.APPTBUYB_PLG_MVAL   ,0)		*    C.PERFM_RATIO_1		--Լ��������Ѻ��ֵ
				,OTH_PROD_MVAL       	= 	COALESCE(B1.OTH_PROD_MVAL       ,0)		*    C.PERFM_RATIO_1		--������Ʒ��ֵ
				,STKT_FUND_MVAL      	= 	COALESCE(B1.STKT_FUND_MVAL      ,0)		*    C.PERFM_RATIO_1		--��Ʊ�ͻ�����ֵ
				,OTH_AST_MVAL        	= 	COALESCE(B1.OTH_AST_MVAL        ,0)		*    C.PERFM_RATIO_1		--�����ʲ���ֵ
				,CREDIT_MARG         	= 	COALESCE(B2.CREDIT_MARG         ,0)		*    C.PERFM_RATIO_9		--������ȯ��֤��
				,CREDIT_NET_AST      	= 	COALESCE(B2.CREDIT_NET_AST      ,0)		*    C.PERFM_RATIO_9		--������ȯ���ʲ�
				,PROD_TOT_MVAL       	= 	COALESCE(B1.PROD_TOT_MVAL       ,0)		*    C.PERFM_RATIO_1		--��Ʒ����ֵ
				,JQL9_MVAL           	= 	COALESCE(B5.JQL9_MVAL           ,0)		*    C.PERFM_RATIO_1		--������9��ֵ
				,STKPLG_GUAR_SECMV   	= 	COALESCE(B3.STKPLG_GUAR_SECMV   ,0)		*    C.PERFM_RATIO_1		--��Ʊ��Ѻ����֤ȯ��ֵ
				,STKPLG_FIN_BAL      	= 	COALESCE(B3.STKPLG_FIN_BAL      ,0)		*    C.PERFM_RATIO_1		--��Ʊ��Ѻ�������	
				,APPTBUYB_BAL        	= 	COALESCE(B4.APPTBUYB_BAL        ,0)		*    C.PERFM_RATIO_1		--Լ���������
				,CRED_MARG           	= 	COALESCE(B2.CRED_MARG           ,0)		*    C.PERFM_RATIO_9		--���ñ�֤��	
				,INTR_LIAB           	= 	COALESCE(B2.INTR_LIAB           ,0)		*    C.PERFM_RATIO_9		--��Ϣ��ծ	
				,FEE_LIAB            	= 	COALESCE(B2.FEE_LIAB            ,0)		*    C.PERFM_RATIO_9		--���ø�ծ	
				,OTHLIAB             	= 	COALESCE(B2.OTHLIAB             ,0)		*    C.PERFM_RATIO_9		--������ծ	
				,FIN_LIAB            	= 	COALESCE(B2.FIN_LIAB            ,0)		*    C.PERFM_RATIO_9		--���ʸ�ծ	
				,CRDT_STK_LIAB       	= 	COALESCE(B2.CRDT_STK_LIAB       ,0)		*    C.PERFM_RATIO_9		--��ȯ��ծ	
				,CREDIT_TOT_AST      	= 	COALESCE(B2.CREDIT_TOT_AST      ,0)		*    C.PERFM_RATIO_9		--������ȯ���ʲ�
				,CREDIT_TOT_LIAB     	= 	COALESCE(B2.CREDIT_TOT_LIAB     ,0)		*    C.PERFM_RATIO_9		--������ȯ�ܸ�ծ
				,APPTBUYB_GUAR_SECMV 	= 	COALESCE(B4.APPTBUYB_GUAR_SECMV ,0)		*    C.PERFM_RATIO_4		--Լ�����ص���֤ȯ��ֵ
				,CREDIT_GUAR_SECMV   	= 	COALESCE(B2.CREDIT_GUAR_SECMV   ,0)		*    C.PERFM_RATIO_9		--������ȯ����֤ȯ��ֵ
		FROM #TMP_T_AST_D_EMP A
		--��ͨ�ʲ�
		LEFT JOIN (
				SELECT 
					T.MAIN_CPTL_ACCT	  			AS 		MAIN_CPTL_ACCT			--�ʽ��˺�			
					,T.TOT_AST_N_CONTAIN_NOTS		AS      TOT_AST              	--���ʲ�
					,T.SCDY_MVAL					AS      SCDY_MVAL            	--������ֵ
					,T.STKF_MVAL 					AS      STKF_MVAL            	--�ɻ���ֵ
					,T.A_SHR_MVAL					AS      A_SHR_MVAL           	--A����ֵ
					,T.NOTS_MVAL					AS      NOTS_MVAL            	--���۹���ֵ
					,T.OFFUND_MVAL					AS      OFFUND_MVAL          	--���ڻ�����ֵ
					,T.OPFUND_MVAL					AS      OPFUND_MVAL          	--���������ֵ
					,T.SB_MVAL						AS      SB_MVAL              	--������ֵ
					,T.IMGT_PD_MVAL					AS      IMGT_PD_MVAL         	--�ʹܲ�Ʒ��ֵ
					,T.BANK_CHRM_MVAL				AS      BANK_CHRM_MVAL       	--���������ֵ
					,T.SECU_CHRM_MVAL				AS      SECU_CHRM_MVAL       	--֤ȯ�����ֵ
					,T.PSTK_OPTN_MVAL				AS      PSTK_OPTN_MVAL       	--������Ȩ��ֵ
					,T.B_SHR_MVAL					AS      B_SHR_MVAL           	--B����ֵ
					,T.OUTMARK_MVAL					AS      OUTMARK_MVAL         	--������ֵ
					,T.CPTL_BAL 					AS      CPTL_BAL             	--�ʽ����
					,T.NO_ARVD_CPTL					AS      NO_ARVD_CPTL         	--δ�����ʽ�
					,T.PTE_FUND_MVAL				AS      PTE_FUND_MVAL        	--˽ļ������ֵ
					,T.CPTL_BAL_RMB					AS      CPTL_BAL_RMB         	--�ʽ���������
					,T.CPTL_BAL_HKD					AS      CPTL_BAL_HKD         	--�ʽ����۱�
					,T.CPTL_BAL_USD					AS      CPTL_BAL_USD         	--�ʽ������Ԫ
					,T.FUND_SPACCT_MVAL				AS      FUND_SPACCT_MVAL     	--����ר��
					,T.HGT_MVAL						AS      HGT_MVAL             	--����ͨ��ֵ
					,T.SGT_MVAL						AS      SGT_MVAL             	--���ͨ��ֵ
					,T.TOT_AST_CONTAIN_NOTS 		AS      TOT_AST_CONTAIN_NOTS 	--���ʲ�_�����۹�
					,T.BOND_MVAL					AS      BOND_MVAL            	--ծȯ��ֵ
					,T.REPO_MVAL 					AS      REPO_MVAL            	--�ع���ֵ
					,T.TREA_REPO_MVAL				AS      TREA_REPO_MVAL       	--��ծ�ع���ֵ
					,T.REPQ_MVAL					AS      REPQ_MVAL            	--���ۻع���ֵ
					,T.PO_FUND_MVAL					AS      PO_FUND_MVAL         	--��ļ������ֵ
					,T.APPTBUYB_PLG_MVAL			AS      APPTBUYB_PLG_MVAL    	--Լ��������Ѻ��ֵ
					,T.OTH_PROD_MVAL				AS      OTH_PROD_MVAL        	--������Ʒ��ֵ
					,T.STKT_FUND_MVAL				AS      STKT_FUND_MVAL       	--��Ʊ�ͻ�����ֵ
					,T.OTH_AST_MVAL					AS      OTH_AST_MVAL         	--�����ʲ���ֵ
					,T.PROD_TOT_MVAL				AS      PROD_TOT_MVAL        	--��Ʒ����ֵ
					--,0								AS      JQL9_MVAL            	--������9��ֵ
				FROM DM.T_AST_ODI T
				WHERE T.OCCUR_DT = @V_DATE
			) B1 ON A.MAIN_CPTL_ACCT=B1.MAIN_CPTL_ACCT
		--������ȯ�ʲ�
		LEFT JOIN (
				SELECT 
					 T.CUST_ID	  					AS 		CUST_ID					--�ͻ����			
					,T.CRED_MARG					AS      CREDIT_MARG          	--������ȯ��֤��
					,T.NET_AST						AS      CREDIT_NET_AST       	--������ȯ���ʲ�
					,T.CRED_MARG					AS      CRED_MARG            	--���ñ�֤��	
					,T.INTR_LIAB					AS      INTR_LIAB            	--��Ϣ��ծ	
					,T.FEE_LIAB						AS      FEE_LIAB             	--���ø�ծ
					,T.OTH_LIAB						AS      OTHLIAB              	--������ծ
					,T.FIN_LIAB						AS      FIN_LIAB             	--���ʸ�ծ	
					,T.CRDT_STK_LIAB				AS      CRDT_STK_LIAB        	--��ȯ��ծ	
					,T.TOT_AST						AS      CREDIT_TOT_AST       	--������ȯ���ʲ�
					,T.TOT_LIAB						AS      CREDIT_TOT_LIAB      	--������ȯ�ܸ�ծ
					,T.GUAR_SECU_MVAL				AS      CREDIT_GUAR_SECMV    	--������ȯ����֤ȯ��ֵ
				FROM DM.T_AST_CREDIT T
				WHERE T.OCCUR_DT = @V_DATE
			) B2 ON A.CUST_ID=B2.CUST_ID
		--��Ʊ��Ѻ�ʲ�(��Ʊ��Ѻ�ʲ��Ŀͻ���ſ��ܶ�Ӧ�����ͬ��ţ���˻��ڿͻ�ά�Ȼ������к�ͬ��ָ����)
		LEFT JOIN (
				SELECT 
					 T.CUST_ID	  					AS 		CUST_ID					--�ͻ����			
					,SUM(T.GUAR_SECU_MVAL)			AS      STKPLG_GUAR_SECMV    	--��Ʊ��Ѻ����֤ȯ��ֵ
					,SUM(T.STKPLG_FIN_BAL)			AS      STKPLG_FIN_BAL       	--��Ʊ��Ѻ�������	
				FROM DM.T_AST_STKPLG T
				WHERE T.OCCUR_DT = @V_DATE
				GROUP BY T.CUST_ID
			) B3 ON A.CUST_ID=B3.CUST_ID
		--Լ�������ʲ�
		LEFT JOIN (
				SELECT 
					 T.CUST_ID	  					AS 		CUST_ID					--�ͻ����			
					,T.APPTBUYB_BAL					AS      APPTBUYB_BAL         	--Լ���������
					,T.GUAR_SECU_MVAL				AS      APPTBUYB_GUAR_SECMV  	--Լ�����ص���֤ȯ��ֵ
				FROM DM.T_AST_APPTBUYB T
				WHERE T.OCCUR_DT = @V_DATE
			) B4 ON A.CUST_ID=B4.CUST_ID
		--������9��ֵ
		LEFT JOIN (
				SELECT 
					 T.MAIN_CPTL_ACCT	  			AS 		MAIN_CPTL_ACCT		    --�ʽ��˺�		 
					,SUM(T.OTC_RETAIN_AMT)	        AS      JQL9_MVAL            	--��������ֵ
				FROM DM.T_EVT_PROD_TRD_D_D T
				WHERE T.OCCUR_DT = @V_DATE
                GROUP BY T.MAIN_CPTL_ACCT
			) B5 ON B5.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.CUST_ID = A.CUST_ID
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--����ʱ��İ�Ա��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	DELETE FROM DM.T_AST_D_EMP WHERE OCCUR_DT = @V_DATE;
	INSERT INTO DM.T_AST_D_EMP (
			 OCCUR_DT            		--��������	
			,EMP_ID              		--Ա�����	
			,TOT_AST             		--���ʲ�	
			,SCDY_MVAL           		--������ֵ	
			,STKF_MVAL           		--�ɻ���ֵ	
			,A_SHR_MVAL          		--A����ֵ	
			,NOTS_MVAL           		--���۹���ֵ	
			,OFFUND_MVAL         		--���ڻ�����ֵ	
			,OPFUND_MVAL         		--���������ֵ	
			,SB_MVAL             		--������ֵ	
			,IMGT_PD_MVAL        		--�ʹܲ�Ʒ��ֵ	
			,BANK_CHRM_MVAL      		--���������ֵ	
			,SECU_CHRM_MVAL      		--֤ȯ�����ֵ	
			,PSTK_OPTN_MVAL      		--������Ȩ��ֵ	
			,B_SHR_MVAL          		--B����ֵ	
			,OUTMARK_MVAL        		--������ֵ	
			,CPTL_BAL            		--�ʽ����	
			,NO_ARVD_CPTL        		--δ�����ʽ�	
			,PTE_FUND_MVAL       		--˽ļ������ֵ	
			,CPTL_BAL_RMB        		--�ʽ���������	
			,CPTL_BAL_HKD        		--�ʽ����۱�	
			,CPTL_BAL_USD        		--�ʽ������Ԫ	
			,FUND_SPACCT_MVAL    		--����ר��	
			,HGT_MVAL            		--����ͨ��ֵ	
			,SGT_MVAL            		--���ͨ��ֵ	
			,TOT_AST_CONTAIN_NOTS		--���ʲ�_�����۹�	
			,BOND_MVAL           		--ծȯ��ֵ	
			,REPO_MVAL           		--�ع���ֵ	
			,TREA_REPO_MVAL      		--��ծ�ع���ֵ	
			,REPQ_MVAL           		--���ۻع���ֵ	
			,PO_FUND_MVAL        		--��ļ������ֵ	
			,APPTBUYB_PLG_MVAL   		--Լ��������Ѻ��ֵ	
			,OTH_PROD_MVAL       		--������Ʒ��ֵ	
			,STKT_FUND_MVAL      		--��Ʊ�ͻ�����ֵ	
			,OTH_AST_MVAL        		--�����ʲ���ֵ	
			,CREDIT_MARG         		--������ȯ��֤��	
			,CREDIT_NET_AST      		--������ȯ���ʲ�	
			,PROD_TOT_MVAL       		--��Ʒ����ֵ	
			,JQL9_MVAL           		--������9��ֵ	
			,STKPLG_GUAR_SECMV   		--��Ʊ��Ѻ����֤ȯ��ֵ	
			,STKPLG_FIN_BAL      		--��Ʊ��Ѻ�������	
			,APPTBUYB_BAL        		--Լ���������	
			,CRED_MARG           		--���ñ�֤��	
			,INTR_LIAB           		--��Ϣ��ծ	
			,FEE_LIAB            		--���ø�ծ	
			,OTHLIAB             		--������ծ	
			,FIN_LIAB            		--���ʸ�ծ	
			,CRDT_STK_LIAB       		--��ȯ��ծ	
			,CREDIT_TOT_AST      		--������ȯ���ʲ�	
			,CREDIT_TOT_LIAB     		--������ȯ�ܸ�ծ	
			,APPTBUYB_GUAR_SECMV 		--Լ�����ص���֤ȯ��ֵ	
			,CREDIT_GUAR_SECMV   		--������ȯ����֤ȯ��ֵ
		)
		SELECT 
			 OCCUR_DT 						AS      OCCUR_DT                 --��������	 
			,EMP_ID   						AS      EMP_ID                   --Ա�����	 
			,SUM(TOT_AST)             		AS      TOT_AST                  --���ʲ�	 	
			,SUM(SCDY_MVAL)           		AS      SCDY_MVAL                --������ֵ	 	
			,SUM(STKF_MVAL)          		AS      STKF_MVAL                --�ɻ���ֵ	 	
			,SUM(A_SHR_MVAL)          		AS      A_SHR_MVAL               --A����ֵ	 	
			,SUM(NOTS_MVAL)           		AS      NOTS_MVAL                --���۹���ֵ	 	
			,SUM(OFFUND_MVAL)         		AS      OFFUND_MVAL              --���ڻ�����ֵ	 	
			,SUM(OPFUND_MVAL)         		AS      OPFUND_MVAL              --���������ֵ	 	
			,SUM(SB_MVAL)             		AS      SB_MVAL                  --������ֵ	 	
			,SUM(IMGT_PD_MVAL)        		AS      IMGT_PD_MVAL             --�ʹܲ�Ʒ��ֵ	 	
			,SUM(BANK_CHRM_MVAL)      		AS      BANK_CHRM_MVAL           --���������ֵ	 	
			,SUM(SECU_CHRM_MVAL)      		AS      SECU_CHRM_MVAL           --֤ȯ�����ֵ	 	
			,SUM(PSTK_OPTN_MVAL)      		AS      PSTK_OPTN_MVAL           --������Ȩ��ֵ	 	
			,SUM(B_SHR_MVAL)          		AS      B_SHR_MVAL               --B����ֵ	 	
			,SUM(OUTMARK_MVAL)        		AS      OUTMARK_MVAL             --������ֵ	 	
			,SUM(CPTL_BAL)            		AS      CPTL_BAL                 --�ʽ����	 	
			,SUM(NO_ARVD_CPTL)        		AS      NO_ARVD_CPTL             --δ�����ʽ�	 	
			,SUM(PTE_FUND_MVAL)       		AS      PTE_FUND_MVAL            --˽ļ������ֵ	 	
			,SUM(CPTL_BAL_RMB)        		AS      CPTL_BAL_RMB             --�ʽ���������	 	
			,SUM(CPTL_BAL_HKD)        		AS      CPTL_BAL_HKD             --�ʽ����۱�	 	
			,SUM(CPTL_BAL_USD)        		AS      CPTL_BAL_USD             --�ʽ������Ԫ	 	
			,SUM(FUND_SPACCT_MVAL)    		AS      FUND_SPACCT_MVAL         --����ר��	 	
			,SUM(HGT_MVAL)            		AS      HGT_MVAL                 --����ͨ��ֵ	 	
			,SUM(SGT_MVAL)            		AS      SGT_MVAL                 --���ͨ��ֵ	 	
			,SUM(TOT_AST_CONTAIN_NOTS)		AS      TOT_AST_CONTAIN_NOTS     --���ʲ�_�����۹�	 	
			,SUM(BOND_MVAL)           		AS      BOND_MVAL                --ծȯ��ֵ	 	
			,SUM(REPO_MVAL)           		AS      REPO_MVAL                --�ع���ֵ	 	
			,SUM(TREA_REPO_MVAL)      		AS      TREA_REPO_MVAL           --��ծ�ع���ֵ	 	
			,SUM(REPQ_MVAL)           		AS      REPQ_MVAL                --���ۻع���ֵ	 	
			,SUM(PO_FUND_MVAL)        		AS      PO_FUND_MVAL             --��ļ������ֵ	 	
			,SUM(APPTBUYB_PLG_MVAL)   		AS      APPTBUYB_PLG_MVAL        --Լ��������Ѻ��ֵ	 	
			,SUM(OTH_PROD_MVAL)       		AS      OTH_PROD_MVAL            --������Ʒ��ֵ	 	
			,SUM(STKT_FUND_MVAL)      		AS      STKT_FUND_MVAL           --��Ʊ�ͻ�����ֵ	 	
			,SUM(OTH_AST_MVAL)        		AS      OTH_AST_MVAL             --�����ʲ���ֵ	 	
			,SUM(CREDIT_MARG)         		AS      CREDIT_MARG              --������ȯ��֤��	 	
			,SUM(CREDIT_NET_AST)      		AS      CREDIT_NET_AST           --������ȯ���ʲ�	 	
			,SUM(PROD_TOT_MVAL)       		AS      PROD_TOT_MVAL            --��Ʒ����ֵ	 	
			,SUM(JQL9_MVAL)           		AS      JQL9_MVAL                --������9��ֵ	 	
			,SUM(STKPLG_GUAR_SECMV)   		AS      STKPLG_GUAR_SECMV        --��Ʊ��Ѻ����֤ȯ��ֵ 	
			,SUM(STKPLG_FIN_BAL)      		AS      STKPLG_FIN_BAL           --��Ʊ��Ѻ�������	 	
			,SUM(APPTBUYB_BAL)        		AS      APPTBUYB_BAL             --Լ���������	 	
			,SUM(CRED_MARG)           		AS      CRED_MARG                --���ñ�֤��	 	
			,SUM(INTR_LIAB)           		AS      INTR_LIAB                --��Ϣ��ծ	 	
			,SUM(FEE_LIAB)            		AS      FEE_LIAB                 --���ø�ծ	 	
			,SUM(OTHLIAB)             		AS      OTHLIAB                  --������ծ	 	
			,SUM(FIN_LIAB)            		AS      FIN_LIAB                 --���ʸ�ծ	 	
			,SUM(CRDT_STK_LIAB)       		AS      CRDT_STK_LIAB            --��ȯ��ծ	 	
			,SUM(CREDIT_TOT_AST)      		AS      CREDIT_TOT_AST           --������ȯ���ʲ�	 	
			,SUM(CREDIT_TOT_LIAB)     		AS      CREDIT_TOT_LIAB          --������ȯ�ܸ�ծ	 	
			,SUM(APPTBUYB_GUAR_SECMV) 		AS      APPTBUYB_GUAR_SECMV      --Լ�����ص���֤ȯ��ֵ 	
			,SUM(CREDIT_GUAR_SECMV)   		AS      CREDIT_GUAR_SECMV        --������ȯ����֤ȯ��ֵ 	
		FROM #TMP_T_AST_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_APPTBUYB_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ�Լ�������±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ�Լ�������±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
  
      --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4);    
    DECLARE @V_BIN_MTH  VARCHAR(2);   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

  --PART0 ɾ����������
    DELETE FROM DM.T_AST_EMPCUS_APPTBUYB_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

  
    ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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

	 --ҵ��������ʱ��
	 SELECT 
	 T1.YEAR AS ��
	,T1.MTH AS ��
	,T1.OCCUR_DT
	,T1.NATRE_DAYS_MTH AS ��Ȼ����_��
	,T1.NATRE_DAYS_YEAR AS ��Ȼ����_��
	,T1.NATRE_DAY_MTHBEG AS ��Ȼ��_�³�
	,T1.CUST_ID AS �ͻ�����
	,T1.YEAR_MTH AS ����
	,T1.YEAR_MTH_CUST_ID AS ���¿ͻ�����
	,T1.GUAR_SECU_MVAL_FINAL AS ����֤ȯ��ֵ_��ĩ
	,T1.APPTBUYB_BAL_FINAL AS Լ���������_��ĩ
	,T1.SH_GUAR_SECU_MVAL_FINAL AS �Ϻ�����֤ȯ��ֵ_��ĩ
	,T1.SZ_GUAR_SECU_MVAL_FINAL AS ���ڵ���֤ȯ��ֵ_��ĩ
	,T1.SH_NOTS_GUAR_SECU_MVAL_FINAL AS �Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
	,T1.SZ_NOTS_GUAR_SECU_MVAL_FINAL AS �������۹ɵ���֤ȯ��ֵ_��ĩ
	,T1.PROP_FINAC_OUT_SIDE_BAL_FINAL AS ��Ӫ�ڳ������_��ĩ
	,T1.ASSM_FINAC_OUT_SIDE_BAL_FINAL AS �ʹ��ڳ������_��ĩ
	,T1.SM_LOAN_FINAC_OUT_BAL_FINAL AS С����ڳ����_��ĩ
	,T1.GUAR_SECU_MVAL_MDA AS ����֤ȯ��ֵ_���վ�
	,T1.APPTBUYB_BAL_MDA AS Լ���������_���վ�
	,T1.SH_GUAR_SECU_MVAL_MDA AS �Ϻ�����֤ȯ��ֵ_���վ�
	,T1.SZ_GUAR_SECU_MVAL_MDA AS ���ڵ���֤ȯ��ֵ_���վ�
	,T1.SH_NOTS_GUAR_SECU_MVAL_MDA AS �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,T1.SZ_NOTS_GUAR_SECU_MVAL_MDA AS �������۹ɵ���֤ȯ��ֵ_���վ�
	,T1.PROP_FINAC_OUT_SIDE_BAL_MDA AS ��Ӫ�ڳ������_���վ�
	,T1.ASSM_FINAC_OUT_SIDE_BAL_MDA AS �ʹ��ڳ������_���վ�
	,T1.SM_LOAN_FINAC_OUT_BAL_MDA AS С����ڳ����_���վ�
	,T1.GUAR_SECU_MVAL_YDA AS ����֤ȯ��ֵ_���վ�
	,T1.APPTBUYB_BAL_YDA AS Լ���������_���վ�
	,T1.SH_GUAR_SECU_MVAL_YDA AS �Ϻ�����֤ȯ��ֵ_���վ�
	,T1.SZ_GUAR_SECU_MVAL_YDA AS ���ڵ���֤ȯ��ֵ_���վ�
	,T1.SH_NOTS_GUAR_SECU_MVAL_YDA AS �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,T1.SZ_NOTS_GUAR_SECU_MVAL_YDA AS �������۹ɵ���֤ȯ��ֵ_���վ�
	,T1.PROP_FINAC_OUT_SIDE_BAL_YDA AS ��Ӫ�ڳ������_���վ�
	,T1.ASSM_FINAC_OUT_SIDE_BAL_YDA AS �ʹ��ڳ������_���վ�
	,T1.SM_LOAN_FINAC_OUT_BAL_YDA AS С����ڳ����_���վ�
 	INTO #TEMP_T1
 	FROM DM.T_AST_APPTBUYB_M_D T1
 	WHERE T1.OCCUR_DT=@V_BIN_DATE 
 	      AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
		   AND T1.CUST_ID NOT IN ('448999999',
					'440000001',
					'999900000001',
					'440000011',
					'440000015');--20180314 �ų�"�ܲ�ר���˻�"

	INSERT INTO DM.T_AST_EMPCUS_APPTBUYB_M_D 
	(
		 YEAR                           --��
		,MTH                            --��
		,OCCUR_DT                       --ҵ������
		,CUST_ID                        --�ͻ�����
		,AFA_SEC_EMPID                  --AFA_����Ա����
		,YEAR_MTH                       --����
		,YEAR_MTH_CUST_ID               --���¿ͻ�����
		,YEAR_MTH_PSN_JNO               --����Ա����
		,WH_ORG_ID_CUST                 --�ֿ��������_�ͻ�
		,WH_ORG_ID_EMP                  --�ֿ��������_Ա��
		,PERFM_RATI9_CREDIT             --��Ч����9_������ȯ
		,GUAR_SECU_MVAL_FINAL           --����֤ȯ��ֵ_��ĩ
		,APPTBUYB_BAL_FINAL             --Լ���������_��ĩ
		,SH_GUAR_SECU_MVAL_FINAL        --�Ϻ�����֤ȯ��ֵ_��ĩ
		,SZ_GUAR_SECU_MVAL_FINAL        --���ڵ���֤ȯ��ֵ_��ĩ
		,SH_NOTS_GUAR_SECU_MVAL_FINAL   --�Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
		,SZ_NOTS_GUAR_SECU_MVAL_FINAL   --�������۹ɵ���֤ȯ��ֵ_��ĩ
		,PROP_FINAC_OUT_SIDE_BAL_FINAL  --��Ӫ�ڳ������_��ĩ
		,ASSM_FINAC_OUT_SIDE_BAL_FINAL  --�ʹ��ڳ������_��ĩ
		,SM_LOAN_FINAC_OUT_BAL_FINAL    --С����ڳ����_��ĩ
		,GUAR_SECU_MVAL_MDA             --����֤ȯ��ֵ_���վ�
		,APPTBUYB_BAL_MDA               --Լ���������_���վ�
		,SH_GUAR_SECU_MVAL_MDA          --�Ϻ�����֤ȯ��ֵ_���վ�
		,SZ_GUAR_SECU_MVAL_MDA          --���ڵ���֤ȯ��ֵ_���վ�
		,SH_NOTS_GUAR_SECU_MVAL_MDA     --�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
		,SZ_NOTS_GUAR_SECU_MVAL_MDA     --�������۹ɵ���֤ȯ��ֵ_���վ�
		,PROP_FINAC_OUT_SIDE_BAL_MDA    --��Ӫ�ڳ������_���վ�
		,ASSM_FINAC_OUT_SIDE_BAL_MDA    --�ʹ��ڳ������_���վ�
		,SM_LOAN_FINAC_OUT_BAL_MDA      --С����ڳ����_���վ�
		,GUAR_SECU_MVAL_YDA             --����֤ȯ��ֵ_���վ�
		,APPTBUYB_BAL_YDA               --Լ���������_���վ�
		,SH_GUAR_SECU_MVAL_YDA          --�Ϻ�����֤ȯ��ֵ_���վ�
		,SZ_GUAR_SECU_MVAL_YDA          --���ڵ���֤ȯ��ֵ_���վ�
		,SH_NOTS_GUAR_SECU_MVAL_YDA     --�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
		,SZ_NOTS_GUAR_SECU_MVAL_YDA     --�������۹ɵ���֤ȯ��ֵ_���վ�
		,PROP_FINAC_OUT_SIDE_BAL_YDA    --��Ӫ�ڳ������_���վ�
		,ASSM_FINAC_OUT_SIDE_BAL_YDA    --�ʹ��ڳ������_���վ�
		,SM_LOAN_FINAC_OUT_BAL_YDA      --С����ڳ����_���վ�
		,LOAD_DT                        --��ϴ����
	)
SELECT
	 T2.YEAR
	,T2.MTH
	,@V_BIN_DATE 		AS OCCUR_DT
	,T2.HS_CUST_ID
	,T2.AFA_SEC_EMPID 	AS AFA_����Ա����	
	,T2.YEAR||T2.MTH 	AS ����
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID 	AS ���¿ͻ�����
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID  AS ����Ա����

	,T2.WH_ORG_ID_CUST AS �ֿ��������_�ͻ�
	,T2.WH_ORG_ID_EMP AS �ֿ��������_Ա��
	,T2.PERFM_RATI9 AS ��Ч����9_������ȯ
	
	,COALESCE(T1.����֤ȯ��ֵ_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS ����֤ȯ��ֵ_��ĩ
	,COALESCE(T1.Լ���������_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ���������_��ĩ
	,COALESCE(T1.�Ϻ�����֤ȯ��ֵ_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS �Ϻ�����֤ȯ��ֵ_��ĩ
	,COALESCE(T1.���ڵ���֤ȯ��ֵ_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS ���ڵ���֤ȯ��ֵ_��ĩ
	,COALESCE(T1.�Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS �Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
	,COALESCE(T1.�������۹ɵ���֤ȯ��ֵ_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS �������۹ɵ���֤ȯ��ֵ_��ĩ
	,COALESCE(T1.��Ӫ�ڳ������_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ӫ�ڳ������_��ĩ
	,COALESCE(T1.�ʹ��ڳ������_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS �ʹ��ڳ������_��ĩ
	,COALESCE(T1.С����ڳ����_��ĩ,0)*COALESCE(T2.PERFM_RATI9,0) AS С����ڳ����_��ĩ	
	
	,COALESCE(T1.����֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS ����֤ȯ��ֵ_���վ�
	,COALESCE(T1.Լ���������_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ���������_���վ�
	,COALESCE(T1.�Ϻ�����֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �Ϻ�����֤ȯ��ֵ_���վ�
	,COALESCE(T1.���ڵ���֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS ���ڵ���֤ȯ��ֵ_���վ�
	,COALESCE(T1.�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,COALESCE(T1.�������۹ɵ���֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �������۹ɵ���֤ȯ��ֵ_���վ�
	,COALESCE(T1.��Ӫ�ڳ������_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ӫ�ڳ������_���վ�
	,COALESCE(T1.�ʹ��ڳ������_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �ʹ��ڳ������_���վ�
	,COALESCE(T1.С����ڳ����_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS С����ڳ����_���վ�
	
	,COALESCE(T1.����֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS ����֤ȯ��ֵ_���վ�
	,COALESCE(T1.Լ���������_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ���������_���վ�
	,COALESCE(T1.�Ϻ�����֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �Ϻ�����֤ȯ��ֵ_���վ�
	,COALESCE(T1.���ڵ���֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS ���ڵ���֤ȯ��ֵ_���վ�
	,COALESCE(T1.�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,COALESCE(T1.�������۹ɵ���֤ȯ��ֵ_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �������۹ɵ���֤ȯ��ֵ_���վ�
	,COALESCE(T1.��Ӫ�ڳ������_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ӫ�ڳ������_���վ�
	,COALESCE(T1.�ʹ��ڳ������_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS �ʹ��ڳ������_���վ�
	,COALESCE(T1.С����ڳ����_���վ�,0)*COALESCE(T2.PERFM_RATI9,0) AS С����ڳ����_���վ�
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2 
LEFT JOIN #TEMP_T1 T1 
	ON T1.OCCUR_DT = T2.OCCUR_DT 
	AND T1.�ͻ����� = T2.HS_CUST_ID
;

END
GO
GRANT EXECUTE ON dm.P_AST_EMPCUS_APPTBUYB_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_CPTL_CHG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ��ʲ��䶯�±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ��ʲ��䶯�±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

   --PART0 ɾ����������
    DELETE FROM DM.T_AST_EMPCUS_CPTL_CHG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
   ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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


	 --ҵ��������ʱ��
	SELECT 
		T1.YEAR AS ��
		,T1.MTH AS ��
		,T1.OCCUR_DT 
		,T1.CUST_ID AS �ͻ�����
		,T1.YEAR_MTH AS ����
		,T1.YEAR_MTH_CUST_ID AS ���¿ͻ�����
		,T1.ODI_CPTL_INFLOW_MTD AS ��ͨ�ʽ�����_���ۼ�
		,T1.ODI_CPTL_OUTFLOW_MTD AS ��ͨ�ʽ�����_���ۼ�
		,T1.ODI_MVAL_INFLOW_MTD AS ��ͨ��ֵ����_���ۼ�
		,T1.ODI_MVAL_OUTFLOW_MTD AS ��ͨ��ֵ����_���ۼ�
		,T1.CREDIT_CPTL_INFLOW_MTD AS �����ʽ�����_���ۼ�
		,T1.CREDIT_CPTL_OUTFLOW_MTD AS �����ʽ�����_���ۼ�
		,T1.ODI_ACC_CPTL_NET_INFLOW_MTD AS ��ͨ�˻��ʽ�����_���ۼ�
		,T1.CREDIT_CPTL_NET_INFLOW_MTD AS �����ʽ�����_���ۼ�
		,T1.ODI_CPTL_INFLOW_YTD AS ��ͨ�ʽ�����_���ۼ�
		,T1.ODI_CPTL_OUTFLOW_YTD AS ��ͨ�ʽ�����_���ۼ�
		,T1.ODI_MVAL_INFLOW_YTD AS ��ͨ��ֵ����_���ۼ�
		,T1.ODI_MVAL_OUTFLOW_YTD AS ��ͨ��ֵ����_���ۼ�
		,T1.CREDIT_CPTL_INFLOW_YTD AS �����ʽ�����_���ۼ�
		,T1.CREDIT_CPTL_OUTFLOW_YTD AS �����ʽ�����_���ۼ�
		,T1.ODI_ACC_CPTL_NET_INFLOW_YTD AS ��ͨ�˻��ʽ�����_���ۼ�
		,T1.CREDIT_CPTL_NET_INFLOW_YTD AS �����ʽ�����_���ۼ�
		,T1.LOAD_DT AS ��ϴ���ڡ�
	INTO #TEMP_T1
	FROM DM.T_AST_CPTL_CHG_M_D T1
	WHERE T1.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
	   AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015');--20180314 �ų�"�ܲ�ר���˻�"


	INSERT INTO DM.T_AST_EMPCUS_CPTL_CHG_M_D 
	(
	 YEAR                        --��
	,MTH                         --��
	,OCCUR_DT                    --ҵ������
	,CUST_ID                     --�ͻ�����
	,AFA_SEC_EMPID               --AFA_����Ա����
	,YEAR_MTH                    --����
	,YEAR_MTH_CUST_ID            --���¿ͻ�����
	,YEAR_MTH_PSN_JNO            --����Ա����
	,WH_ORG_ID_CUST              --�ֿ��������_�ͻ�
	,WH_ORG_ID_EMP               --�ֿ��������_Ա��
	,PERFM_RATI1_SCDY_AST        --��Ч����1_�����ʲ�
	,PERFM_RATI9_CREDIT          --��Ч����9_������ȯ
	,ODI_CPTL_INFLOW_MTD         --��ͨ�ʽ�����_���ۼ�
	,ODI_CPTL_OUTFLOW_MTD        --��ͨ�ʽ�����_���ۼ�
	,ODI_MVAL_INFLOW_MTD         --��ͨ��ֵ����_���ۼ�
	,ODI_MVAL_OUTFLOW_MTD        --��ͨ��ֵ����_���ۼ�
	,CREDIT_CPTL_INFLOW_MTD      --�����ʽ�����_���ۼ�
	,CREDIT_CPTL_OUTFLOW_MTD     --�����ʽ�����_���ۼ�
	,ODI_ACC_CPTL_NET_INFLOW_MTD --��ͨ�˻��ʽ�����_���ۼ�
	,CREDIT_CPTL_NET_INFLOW_MTD  --�����ʽ�����_���ۼ�
	,ODI_CPTL_INFLOW_YTD         --��ͨ�ʽ�����_���ۼ�
	,ODI_CPTL_OUTFLOW_YTD        --��ͨ�ʽ�����_���ۼ�
	,ODI_MVAL_INFLOW_YTD         --��ͨ��ֵ����_���ۼ�
	,ODI_MVAL_OUTFLOW_YTD        --��ͨ��ֵ����_���ۼ�
	,CREDIT_CPTL_INFLOW_YTD      --�����ʽ�����_���ۼ�
	,CREDIT_CPTL_OUTFLOW_YTD     --�����ʽ�����_���ۼ�
	,ODI_ACC_CPTL_NET_INFLOW_YTD --��ͨ�˻��ʽ�����_���ۼ�
	,CREDIT_CPTL_NET_INFLOW_YTD  --�����ʽ�����_���ۼ�
	,LOAD_DT                     --��ϴ����

)
SELECT
	T2.YEAR
	,T2.MTH
	,T2.OCCUR_DT
	,T2.HS_CUST_ID
	,T2.AFA_SEC_EMPID AS AFA_����Ա����
	,T2.YEAR||T2.MTH
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID AS ���¿ͻ����
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS ����Ա����
	,T2.WH_ORG_ID_CUST AS �ֿ��������_�ͻ�
	,T2.WH_ORG_ID_EMP AS �ֿ��������_Ա��
	,T2.PERFM_RATI1 AS ��Ч����1_�����ʲ�
	,T2.PERFM_RATI9 AS ��Ч����9_������ȯ
	
	,COALESCE(T1.��ͨ�ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ�ʽ�����_���ۼ�
	,COALESCE(T1.��ͨ�ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ�ʽ�����_���ۼ�
	,COALESCE(T1.��ͨ��ֵ����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ��ֵ����_���ۼ�
	,COALESCE(T1.��ͨ��ֵ����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ��ֵ����_���ۼ�
	,COALESCE(T1.�����ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI9,0) AS �����ʽ�����_���ۼ�
	,COALESCE(T1.�����ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI9,0) AS �����ʽ�����_���ۼ�
	,COALESCE(T1.��ͨ�˻��ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ�˻��ʽ�����_���ۼ�
	,COALESCE(T1.�����ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI9,0) AS �����ʽ�����_���ۼ�
	
	,COALESCE(T1.��ͨ�ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ�ʽ�����_���ۼ�
	,COALESCE(T1.��ͨ�ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ�ʽ�����_���ۼ�
	,COALESCE(T1.��ͨ��ֵ����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ��ֵ����_���ۼ�
	,COALESCE(T1.��ͨ��ֵ����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ��ֵ����_���ۼ�
	,COALESCE(T1.�����ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI9,0) AS �����ʽ�����_���ۼ�
	,COALESCE(T1.�����ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI9,0) AS �����ʽ�����_���ۼ�
	,COALESCE(T1.��ͨ�˻��ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI1,0) AS ��ͨ�˻��ʽ�����_���ۼ�
	,COALESCE(T1.�����ʽ�����_���ۼ�,0) * COALESCE(T2.PERFM_RATI9,0) AS �����ʽ�����_���ۼ�
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2 
LEFT JOIN #TEMP_T1 T1 
	ON T1.OCCUR_DT = T2.OCCUR_DT 
		AND T1.�ͻ����� = T2.HS_CUST_ID
;

END
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_CREDIT_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ�������ȯ�±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ�������ȯ�±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

   --PART0 ɾ����������
  DELETE FROM DM.T_AST_EMPCUS_CREDIT_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
   ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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

	 --ҵ��������ʱ��
	select 
	t1.YEAR as ��
	,t1.MTH as ��
	,T1.OCCUR_DT
	,t1.NATRE_DAYS_MTH as ��Ȼ����_��
	,t1.NATRE_DAYS_YEAR as ��Ȼ����_��
	,t1.NATRE_DAY_MTHBEG as ��Ȼ��_�³�
	,t1.CUST_ID as �ͻ�����
	,t1.YEAR_MTH as ����
	,t1.YEAR_MTH_CUST_ID as ���¿ͻ�����
	,t1.TOT_LIAB_FINAL as �ܸ�ծ_��ĩ
	,t1.NET_AST_FINAL as ���ʲ�_��ĩ
	,t1.CRED_MARG_FINAL as ���ñ�֤��_��ĩ
	,t1.GUAR_SECU_MVAL_FINAL as ����֤ȯ��ֵ_��ĩ
	,t1.FIN_LIAB_FINAL as ���ʸ�ծ_��ĩ
	,t1.CRDT_STK_LIAB_FINAL as ��ȯ��ծ_��ĩ
	,t1.INTR_LIAB_FINAL as ��Ϣ��ծ_��ĩ
	,t1.FEE_LIAB_FINAL as ���ø�ծ_��ĩ
	,t1.OTH_LIAB_FINAL as ������ծ_��ĩ
	,t1.TOT_AST_FINAL as ���ʲ�_��ĩ
	,t1.TOT_LIAB_MDA as �ܸ�ծ_���վ�
	,t1.NET_AST_MDA as ���ʲ�_���վ�
	,t1.CRED_MARG_MDA as ���ñ�֤��_���վ�
	,t1.GUAR_SECU_MVAL_MDA as ����֤ȯ��ֵ_���վ�
	,t1.FIN_LIAB_MDA as ���ʸ�ծ_���վ�
	,t1.CRDT_STK_LIAB_MDA as ��ȯ��ծ_���վ�
	,t1.INTR_LIAB_MDA as ��Ϣ��ծ_���վ�
	,t1.FEE_LIAB_MDA as ���ø�ծ_���վ�
	,t1.OTH_LIAB_MDA as ������ծ_���վ�
	,t1.TOT_AST_MDA as ���ʲ�_���վ�
	,t1.TOT_LIAB_YDA as �ܸ�ծ_���վ�
	,t1.NET_AST_YDA as ���ʲ�_���վ�
	,t1.CRED_MARG_YDA as ���ñ�֤��_���վ�
	,t1.GUAR_SECU_MVAL_YDA as ����֤ȯ��ֵ_���վ�
	,t1.FIN_LIAB_YDA as ���ʸ�ծ_���վ�
	,t1.CRDT_STK_LIAB_YDA as ��ȯ��ծ_���վ�
	,t1.INTR_LIAB_YDA as ��Ϣ��ծ_���վ�
	,t1.FEE_LIAB_YDA as ���ø�ծ_���վ�
	,t1.OTH_LIAB_YDA as ������ծ_���վ�
	,t1.TOT_AST_YDA as ���ʲ�_���վ�
	,t1.LOAD_DT as ��ϴ����
	INTO #TEMP_T1
	 from DM.T_AST_CREDIT_M_D t1
	 WHERE T1.OCCUR_DT=@V_BIN_DATE
	 AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015');--20180314 �ų�"�ܲ�ר���˻�"

	INSERT INTO DM.T_AST_EMPCUS_CREDIT_M_D 
	(
	   YEAR                  --��
	  ,MTH                   --��
	  ,OCCUR_DT              --ҵ������
	  ,CUST_ID               --�ͻ�����
	  ,AFA_SEC_EMPID         --AFA_����Ա����
	  ,YEAR_MTH              --����
	  ,YEAR_MTH_CUST_ID      --���¿ͻ����
	  ,YEAR_MTH_PSN_JNO      --����Ա�����
	  ,WH_ORG_ID_CUST        --�ֿ��������_�ͻ�
	  ,WH_ORG_ID_EMP         --�ֿ��������_Ա��
	  ,PERFM_RATI9_CREDIT    --��Ч����9_������ȯ
	  ,TOT_LIAB_FINAL        --�ܸ�ծ_��ĩ
	  ,NET_AST_FINAL         --���ʲ�_��ĩ
	  ,CRED_MARG_FINAL       --���ñ�֤��_��ĩ
	  ,GUAR_SECU_MVAL_FINAL  --����֤ȯ��ֵ_���վ�
	  ,FIN_LIAB_FINAL        --���ʸ�ծ_��ĩ
	  ,CRDT_STK_LIAB_FINAL   --��ȯ��ծ_��ĩ
	  ,INTR_LIAB_FINAL       --��Ϣ��ծ_��ĩ
	  ,FEE_LIAB_FINAL        --���ø�ծ_��ĩ
	  ,OTH_LIAB_FINAL        --������ծ_��ĩ
	  ,TOT_AST_FINAL         --���ʲ�_��ĩ
	  ,TOT_LIAB_MDA          --�ܸ�ծ_���վ�
	  ,NET_AST_MDA           --���ʲ�_���վ�
	  ,CRED_MARG_MDA         --���ñ�֤��_���վ�
	  ,GUAR_SECU_MVAL_MDA    --����֤ȯ��ֵ_���վ�
	  ,FIN_LIAB_MDA          --���ʸ�ծ_���վ�
	  ,CRDT_STK_LIAB_MDA     --��ȯ��ծ_���վ�
	  ,INTR_LIAB_MDA         --��Ϣ��ծ_���վ�
	  ,FEE_LIAB_MDA          --���ø�ծ_���վ�
	  ,OTH_LIAB_MDA          --������ծ_���վ�
	  ,TOT_AST_MDA           --���ʲ�_���վ�
	  ,TOT_LIAB_YDA          --�ܸ�ծ_���վ�
	  ,NET_AST_YDA           --���ʲ�_���վ�
	  ,CRED_MARG_YDA         --���ñ�֤��_���վ�
	  ,GUAR_SECU_MVAL_YDA    --����֤ȯ��ֵ_���վ�
	  ,FIN_LIAB_YDA          --���ʸ�ծ_���վ�
	  ,CRDT_STK_LIAB_YDA     --��ȯ��ծ_���վ�
	  ,INTR_LIAB_YDA         --��Ϣ��ծ_���վ�
	  ,FEE_LIAB_YDA          --���ø�ծ_���վ�
	  ,OTH_LIAB_YDA          --������ծ_���վ�
	  ,TOT_AST_YDA           --���ʲ�_���վ�
	  ,LOAD_DT               --��ϴ����
	)
	select
	 t2.YEAR
	,t2.MTH
	,T2.OCCUR_DT
	,t2.HS_CUST_ID
	,t2.AFA_SEC_EMPID as AFA_����Ա����
	,t2.YEAR||t2.MTH as ����
	,t2.YEAR||t2.MTH||t2.HS_CUST_ID as ���¿ͻ����
	,t2.YEAR||t2.MTH||t2.AFA_SEC_EMPID as ����Ա�����
	,t2.WH_ORG_ID_CUST as �ֿ��������_�ͻ�
	,t2.WH_ORG_ID_EMP as �ֿ��������_Ա��
	,t2.PERFM_RATI9 as ��Ч����9_������ȯ
	
	,COALESCE(t1.�ܸ�ծ_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as �ܸ�ծ_��ĩ
	,COALESCE(t1.���ʲ�_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʲ�_��ĩ
	,COALESCE(t1.���ñ�֤��_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ���ñ�֤��_��ĩ
	,COALESCE(t1.����֤ȯ��ֵ_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ����֤ȯ��ֵ_��ĩ
	,COALESCE(t1.���ʸ�ծ_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʸ�ծ_��ĩ
	,COALESCE(t1.��ȯ��ծ_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ��ȯ��ծ_��ĩ
	,COALESCE(t1.��Ϣ��ծ_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ��Ϣ��ծ_��ĩ
	,COALESCE(t1.���ø�ծ_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ���ø�ծ_��ĩ
	,COALESCE(t1.������ծ_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ������ծ_��ĩ
	,COALESCE(t1.���ʲ�_��ĩ,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʲ�_��ĩ

	,COALESCE(t1.�ܸ�ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as �ܸ�ծ_���վ�
	,COALESCE(t1.���ʲ�_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʲ�_���վ�
	,COALESCE(t1.���ñ�֤��_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ñ�֤��_���վ�
	,COALESCE(t1.����֤ȯ��ֵ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ����֤ȯ��ֵ_���վ�
	,COALESCE(t1.���ʸ�ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʸ�ծ_���վ�
	,COALESCE(t1.��ȯ��ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ��ȯ��ծ_���վ�
	,COALESCE(t1.��Ϣ��ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ��Ϣ��ծ_���վ�
	,COALESCE(t1.���ø�ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ø�ծ_���վ�
	,COALESCE(t1.������ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ������ծ_���վ�
	,COALESCE(t1.���ʲ�_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʲ�_���վ�

	,COALESCE(t1.�ܸ�ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as �ܸ�ծ_���վ�
	,COALESCE(t1.���ʲ�_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʲ�_���վ�
	,COALESCE(t1.���ñ�֤��_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ñ�֤��_���վ�
	,COALESCE(t1.����֤ȯ��ֵ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ����֤ȯ��ֵ_���վ�
	,COALESCE(t1.���ʸ�ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʸ�ծ_���վ�
	,COALESCE(t1.��ȯ��ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ��ȯ��ծ_���վ�
	,COALESCE(t1.��Ϣ��ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ��Ϣ��ծ_���վ�
	,COALESCE(t1.���ø�ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ø�ծ_���վ�
	,COALESCE(t1.������ծ_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ������ծ_���վ�
	,COALESCE(t1.���ʲ�_���վ�,0)*COALESCE(t2.PERFM_RATI9,0) as ���ʲ�_���վ�
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2
LEFT JOIN #TEMP_T1 T1
		ON T1.occur_dt=t2.occur_dt 
		 AND T1.�ͻ�����=T2.HS_CUST_ID 
;

END
GO
GRANT EXECUTE ON dm.P_AST_EMPCUS_CREDIT_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_ODI_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ���ͨ�ʲ��±�
  ��д��: DCY
  ��������: 2018-03-01
  ��飺Ա���ͻ���ͨ�ʲ��±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 ɾ����������
  DELETE FROM DM.T_AST_EMPCUS_ODI_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
  
    ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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

	 --ҵ��������ʱ��
	 select
				t1.YEAR
				,t1.MTH
				,T1.OCCUR_DT
				,t1.CUST_ID
				--��Ʊ��Ѻ����֤ȯ��ֵ
				,sum(t1.GUAR_SECU_MVAL_FINAL) as GUAR_SECU_MVAL_FINAL
				,sum(t1.GUAR_SECU_MVAL_MDA)   as GUAR_SECU_MVAL_MDA
				,sum(t1.GUAR_SECU_MVAL_YDA)   as GUAR_SECU_MVAL_YDA
	 into #temp_t_gpzy
	 from DM.T_AST_STKPLG_M_D t1
	 group by 
	 	t1.YEAR
	 	,t1.MTH
	 	,T1.OCCUR_DT
	 	,t1.CUST_ID;


	INSERT INTO DM.T_AST_EMPCUS_ODI_M_D 
	(
		year                                   ,
		mth                                    ,
		OCCUR_DT                               ,
		cust_id                                ,
		year_mth                               ,
		year_mth_cust_id                       ,
		AFA_SEC_EMPID                          ,
		wh_org_id_emp                          ,
		year_mth_psn_jno                       ,
		scdy_mval_final                        ,
		stkf_mval_final                        ,
		a_shr_mval_final                       ,
		nots_mval_final                        ,
		offund_mval_final                      ,
		opfund_mval_final                      ,
		sb_mval_final                          ,
		imgt_pd_mval_final                     ,
		bank_chrm_mval_final                   ,
		secu_chrm_mval_final                   ,
		pstk_optn_mval_final                   ,
		b_shr_mval_final                       ,
		outmark_mval_final                     ,
		cptl_bal_final                         ,
		no_arvd_cptl_final                     ,
		pte_fund_mval_final                    ,
		oversea_tot_ast_final                  ,
		futr_tot_ast_final                     ,
		cptl_bal_rmb_final                     ,
		cptl_bal_hkd_final                     ,
		cptl_bal_usd_final                     ,
		low_risk_tot_ast_final                 ,
		fund_spacct_mval_final                 ,
		hgt_mval_final                         ,
		sgt_mval_final                         ,
		net_ast_final                          ,
		tot_ast_contain_nots_final             ,
		tot_ast_n_contain_nots_final           ,
		bond_mval_final                        ,
		repo_mval_final                        ,
		trea_repo_mval_final                   ,
		repq_mval_final                        ,
		scdy_mval_mda                          ,
		stkf_mval_mda                          ,
		a_shr_mval_mda                         ,
		nots_mval_mda                          ,
		offund_mval_mda                        ,
		opfund_mval_mda                        ,
		sb_mval_mda                            ,
		imgt_pd_mval_mda                       ,
		bank_chrm_mval_mda                     ,
		secu_chrm_mval_mda                     ,
		pstk_optn_mval_mda                     ,
		b_shr_mval_mda                         ,
		outmark_mval_mda                       ,
		cptl_bal_mda                           ,
		no_arvd_cptl_mda                       ,
		pte_fund_mval_mda                      ,
		oversea_tot_ast_mda                    ,
		futr_tot_ast_mda                       ,
		cptl_bal_rmb_mda                       ,
		cptl_bal_hkd_mda                       ,
		cptl_bal_usd_mda                       ,
		low_risk_tot_ast_mda                   ,
		fund_spacct_mval_mda                   ,
		hgt_mval_mda                           ,
		sgt_mval_mda                           ,
		net_ast_mda                            ,
		tot_ast_contain_nots_mda               ,
		tot_ast_n_contain_nots_mda             ,
		bond_mval_mda                          ,
		repo_mval_mda                          ,
		trea_repo_mval_mda                     ,
		repq_mval_mda                          ,
		scdy_mval_yda                          ,
		stkf_mval_yda                          ,
		a_shr_mval_yda                         ,
		nots_mval_yda                          ,
		offund_mval_yda                        ,
		opfund_mval_yda                        ,
		sb_mval_yda                            ,
		imgt_pd_mval_yda                       ,
		bank_chrm_mval_yda                     ,
		secu_chrm_mval_yda                     ,
		pstk_optn_mval_yda                     ,
		b_shr_mval_yda                         ,
		outmark_mval_yda                       ,
		cptl_bal_yda                           ,
		no_arvd_cptl_yda                       ,
		pte_fund_mval_yda                      ,
		oversea_tot_ast_yda                    ,
		futr_tot_ast_yda                       ,
		cptl_bal_rmb_yda                       ,
		cptl_bal_hkd_yda                       ,
		cptl_bal_usd_yda                       ,
		low_risk_tot_ast_yda                   ,
		fund_spacct_mval_yda                   ,
		hgt_mval_yda                           ,
		sgt_mval_yda                           ,
		net_ast_yda                            ,
		tot_ast_contain_nots_yda               ,
		tot_ast_n_contain_nots_yda             ,
		bond_mval_yda                          ,
		repo_mval_yda                          ,
		trea_repo_mval_yda                     ,
		repq_mval_yda                          ,
		po_fund_mval_final                     ,
		po_fund_mval_mda                       ,
		po_fund_mval_yda                       ,
		stkt_fund_mval_final                   ,
		oth_prod_mval_final                    ,
		oth_ast_mval_final                     ,
		apptbuyb_plg_mval_final                ,
		stkt_fund_mval_mda                     ,
		oth_prod_mval_mda                      ,
		oth_ast_mval_mda                       ,
		apptbuyb_plg_mval_mda                  ,
		stkt_fund_mval_yda                     ,
		oth_prod_mval_yda                      ,
		oth_ast_mval_yda                       ,
		apptbuyb_plg_mval_yda                  ,
		credit_net_ast_final                   ,
		credit_marg_final                      ,
		credit_bal_final                       ,
		credit_net_ast_mda                     ,
		credit_marg_mda                        ,
		credit_bal_mda                         ,
		credit_net_ast_yda                     ,
		credit_marg_yda                        ,
		credit_bal_yda                         ,
		credit_tot_liab_final                  ,
		credit_tot_liab_mda                    ,
		credit_tot_liab_yda                    ,
		credit_tot_ast_final                   ,
		credit_tot_ast_mda                     ,
		credit_tot_ast_yda                     ,
		apptbuyb_bal_final                     ,
		apptbuyb_bal_mda                       ,
		apptbuyb_bal_yda                       ,
		prod_tot_mval_final                    ,
		prod_tot_mval_mda                      ,
		prod_tot_mval_yda                      ,
		tot_ast_final                          ,
		tot_ast_mda                            ,
		tot_ast_yda                            ,
		stkplg_guar_secu_mval_final_scdy_deduct,
		stkplg_guar_secu_mval_mda_scdy_deduct  ,
		stkplg_guar_secu_mval_yda_scdy_deduct  ,
		stkplg_liab_final                      ,
		stkplg_liab_mda                        ,
		stkplg_liab_yda                        ,
		stkplg_guar_secu_mval_final            ,
		stkplg_guar_secu_mval_mda              ,
		stkplg_guar_secu_mval_yda
	)
	select 
	 t2.YEAR 			as ��
	,t2.MTH 			as ��
	,T2.OCCUR_DT
	,t2.HS_CUST_ID 		as �ͻ�����
	,t2.YEAR||t2.MTH 	as ����
	,t2.YEAR||t2.MTH||t2.HS_CUST_ID as ���¿ͻ�����

	,t2.AFA_SEC_EMPID as AFA����Ա����
	,t2.WH_ORG_ID_EMP as �ֿ��������_Ա��
	,t2.YEAR||t2.MTH||t2.AFA_SEC_EMPID as ����Ա����

	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_FINAL,0) as ������ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_FINAL,0) as �ɻ���ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_FINAL,0) as A����ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_FINAL,0) as ���۹���ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_FINAL,0) as ���ڻ�����ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_FINAL,0) as ���������ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_FINAL,0) as ������ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0) as �ʹܲ�Ʒ��ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0) as ���������ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0) as ֤ȯ�����ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0) as ������Ȩ��ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_FINAL,0) as B����ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_FINAL,0) as ������ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_FINAL,0) as �ʽ����_��ĩ
	--����δ����
	,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_FINAL,0)+COALESCE(t1.STKPLG_LIAB_FINAL,0)) as δ�����ʽ�_��ĩ
	,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0) as ˽ļ������ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_FINAL,0) as �������ʲ�_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_FINAL,0) as �ڻ����ʲ�_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_FINAL,0) as �ʽ���������_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_FINAL,0) as �ʽ����۱�_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_FINAL,0) as �ʽ������Ԫ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_FINAL,0) as �ͷ������ʲ�_��ĩ
	,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0) as ����ר����ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_FINAL,0) as ����ͨ��ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_FINAL,0) as ���ͨ��ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_FINAL,0) as ���ʲ�_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_FINAL,0) as ���ʲ�_�����۹�_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_FINAL,0) as ���ʲ�_�������۹�_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_FINAL,0) as ծȯ��ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_FINAL,0) as �ع���ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_FINAL,0) as ��ծ�ع���ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_FINAL,0) as ���ۻع���ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_MDA,0) as ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_MDA,0) as �ɻ���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_MDA,0) as A����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_MDA,0) as ���۹���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_MDA,0) as ���ڻ�����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_MDA,0) as ���������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_MDA,0) as ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0) as �ʹܲ�Ʒ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0) as ���������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0) as ֤ȯ�����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_MDA,0) as ������Ȩ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_MDA,0) as B����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_MDA,0) as ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_MDA,0) as �ʽ����_���վ�
	--����δ�����ʽ�
	,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_MDA,0)+COALESCE(t1.STKPLG_LIAB_MDA,0)) as δ�����ʽ�_���վ�
	,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0) as ˽ļ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_MDA,0) as �������ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_MDA,0) as �ڻ����ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_MDA,0) as �ʽ���������_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_MDA,0) as �ʽ����۱�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_MDA,0) as �ʽ������Ԫ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_MDA,0) as �ͷ������ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0) as ����ר����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_MDA,0) as ����ͨ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_MDA,0) as ���ͨ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_MDA,0) as ���ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_MDA,0) as ���ʲ�_�����۹�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_MDA,0) as ���ʲ�_�������۹�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_MDA,0) as ծȯ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_MDA,0) as �ع���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_MDA,0) as ��ծ�ع���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_MDA,0) as ���ۻع���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_YDA,0) as ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_YDA,0) as �ɻ���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_YDA,0) as A����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_YDA,0) as ���۹���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_YDA,0) as ���ڻ�����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_YDA,0) as ���������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_YDA,0) as ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0) as �ʹܲ�Ʒ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0) as ���������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0) as ֤ȯ�����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_YDA,0) as ������Ȩ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_YDA,0) as B����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_YDA,0) as ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_YDA,0) as �ʽ����_���վ�
	--����δ�����ʽ�
	,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_YDA,0)+COALESCE(t1.STKPLG_LIAB_YDA,0))  as δ�����ʽ�_���վ�
	,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0) as ˽ļ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_YDA,0) as �������ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_YDA,0) as �ڻ����ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_YDA,0) as �ʽ���������_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_YDA,0) as �ʽ����۱�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_YDA,0) as �ʽ������Ԫ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_YDA,0) as �ͷ������ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0) as ����ר����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_YDA,0) as ����ͨ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_YDA,0) as ���ͨ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_YDA,0) as ���ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_YDA,0) as ���ʲ�_�����۹�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_YDA,0) as ���ʲ�_�������۹�_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_YDA,0) as ծȯ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_YDA,0) as �ع���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_YDA,0) as ��ծ�ع���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_YDA,0) as ���ۻع���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0) as ��ļ������ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0) as ��ļ������ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0) as ��ļ������ֵ_���վ�

	--�������
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_FINAL,0) as ��Ʊ�ͻ�����ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0) as ������Ʒ��ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_FINAL,0) as �����ʲ���ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0) as Լ��������Ѻ��ֵ_��ĩ
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_MDA,0) as ��Ʊ�ͻ�����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0) as ������Ʒ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_MDA,0) as �����ʲ���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0) as Լ��������Ѻ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_YDA,0) as ��Ʊ�ͻ�����ֵ_���վ�
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0) as ������Ʒ��ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_YDA,0) as �����ʲ���ֵ_���վ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0) as Լ��������Ѻ��ֵ_���վ�

	--����������ȯ����
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_FINAL,0) as ������ȯ���ʲ�_��ĩ
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_FINAL,0) as ������ȯ��֤��_��ĩ
	,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_FINAL,0)+COALESCE(t3.CRDT_STK_LIAB_FINAL,0)) as ������ȯ���_��ĩ
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_MDA,0) as ������ȯ���ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_MDA,0) as ������ȯ��֤��_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_MDA,0)+COALESCE(t3.CRDT_STK_LIAB_MDA,0)) as ������ȯ���_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_YDA,0) as ������ȯ���ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_YDA,0) as ������ȯ��֤��_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_YDA,0)+COALESCE(t3.CRDT_STK_LIAB_YDA,0)) as ������ȯ���_���վ�

	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_FINAL,0) as ������ȯ�ܸ�ծ_��ĩ
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_MDA,0) as ������ȯ�ܸ�ծ_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_YDA,0) as ������ȯ�ܸ�ծ_���վ�

	--20180412������������ȯ���ʲ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_FINAL,0) as ������ȯ���ʲ�_��ĩ
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_MDA,0) as ������ȯ���ʲ�_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_YDA,0) as ������ȯ���ʲ�_���վ�
	--20180416������Լ�����������ڼ��㾻�ʲ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_FINAL,0) as Լ���������_��ĩ
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_MDA,0) as Լ���������_���վ�
	,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_YDA,0) as Լ���������_���վ�


	--��Ʒ����ֵ����ļ������ֵ+����ר����ֵ+�ʹܲ�Ʒ��ֵ+˽ļ������ֵ+���������ֵ+֤ȯ�����ֵ+������Ʒ��ֵ
	,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0) 			--��ļ������ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0) 	--����ר����ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0) 		--�ʹܲ�Ʒ��ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0) 		--˽ļ������ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0) 	--���������ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0) 	--֤ȯ�����ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0)		--������Ʒ��ֵ_��ĩ
	as ��Ʒ����ֵ_��ĩ
,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0) 			--��ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0) 	--����ר����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0) 		--�ʹܲ�Ʒ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0) 		--˽ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0) 		--���������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0) 		--֤ȯ�����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0)		--������Ʒ��ֵ_���վ�
	as ��Ʒ����ֵ_���վ�
,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0) 			--��ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0) 	--����ר����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0) 		--�ʹܲ�Ʒ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0) 		--˽ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0) 		--���������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0) 		--֤ȯ�����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0)		--������Ʒ��ֵ_���վ�
	as ��Ʒ����ֵ_���վ�	
	
--���ʲ����ɻ���ֵ+�ʽ����+ծȯ��ֵ+�ع���ֵ+��Ʒ����ֵ+�����ʲ�+δ�����ʽ�+��Ʊ��Ѻ��ծ+������ȯ���ʲ�+Լ��������Ѻ��ֵ+���۹���ֵ
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_FINAL,0) 				--�ɻ���ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_FINAL,0) 			--�ʽ����_��ĩ
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_FINAL,0) 			--ծȯ��ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_FINAL,0) 			--�ع���ֵ_��ĩ
	
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0) 		--��ļ������ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0) 	--����ר����ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0) 		--�ʹܲ�Ʒ��ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0) 		--˽ļ������ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0) 	--���������ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0) 	--֤ȯ�����ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0)		--������Ʒ��ֵ_��ĩ
	
	--20180412����
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_FINAL,0) 		--�����ʲ���ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_FINAL,0) 		--δ�����ʽ�_��ĩ
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_FINAL,0) 		--��Ʊ��Ѻ��ծ_��ĩ�����ڳ��δ�����ʽ�����ʹ�ö����ʲ�����Ȩ��������
	+COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_FINAL,0) 			--������ȯ���ʲ�_��ĩ
	
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0) 	--Լ��������Ѻ��ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_FINAL,0) 			--���۹���ֵ_��ĩ
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0) 	--������Ȩ��ֵ_��ĩ
	
	--�ۼ���Ʊ��Ѻ����֤ȯ��ֵ
	-COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_FINAL,0) --��Ʊ��Ѻ����֤ȯ��ֵ_��ĩ
	as ���ʲ�_��ĩ
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_MDA,0) 				--�ɻ���ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_MDA,0) 			--�ʽ����_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_MDA,0) 			--ծȯ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_MDA,0) 			--�ع���ֵ_���վ�
	
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0) 		--��ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0) 	--����ר����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0) 		--�ʹܲ�Ʒ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0) 		--˽ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0) 		--���������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0) 		--֤ȯ�����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0)		--������Ʒ��ֵ_���վ�
	
	--20180412����
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_MDA,0) 		--�����ʲ���ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_MDA,0) 		--δ�����ʽ�_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_MDA,0) 			--��Ʊ��Ѻ��ծ_���վ������ڳ��δ�����ʽ�����ʹ�ö����ʲ�����Ȩ��������
	+COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_MDA,0) 				--������ȯ���ʲ�_���վ�
	
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0) 	--Լ��������Ѻ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_MDA,0) 			--���۹���ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_MDA,0) 		--������Ȩ��ֵ_���վ�
	
	--�ۼ���Ʊ��Ѻ����֤ȯ��ֵ
	-COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_MDA,0) 	--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
	as ���ʲ�_���վ�
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_YDA,0) 				--�ɻ���ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_YDA,0) 			--�ʽ����_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_YDA,0) 			--ծȯ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_YDA,0) 			--�ع���ֵ_���վ�
	
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0) 		--��ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0) 	--����ר����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0) 		--�ʹܲ�Ʒ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0) 		--˽ļ������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0) 		--���������ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0) 		--֤ȯ�����ֵ_���վ�
	+COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0)		--������Ʒ��ֵ_���վ�
	
	--20180412����
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_YDA,0) 		--�����ʲ���ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_YDA,0) 		--δ�����ʽ�_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_YDA,0) 			--��Ʊ��Ѻ��ծ_���վ������ڳ��δ�����ʽ�����ʹ�ö����ʲ�����Ȩ��������
	+COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_YDA,0) 				--������ȯ���ʲ�_���վ�
	
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0) 	--Լ��������Ѻ��ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_YDA,0) 			--���۹���ֵ_���վ�
	+COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_YDA,0) 		--������Ȩ��ֵ_���վ�
	
	--�ۼ���Ʊ��Ѻ����֤ȯ��ֵ
	-COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_YDA,0) 	--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
	as ���ʲ�_���վ�

	--20180423������������ֵ�пۼ��Ĺ�Ʊ��Ѻ��ֵ
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_FINAL,0) as ��Ʊ��Ѻ����֤ȯ��ֵ_��ĩ_�����ۼ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_MDA,0)   as ��Ʊ��Ѻ����֤ȯ��ֵ_���վ�_�����ۼ�
	,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_YDA,0)   as ��Ʊ��Ѻ����֤ȯ��ֵ_���վ�_�����ۼ�
	
	--20180416�����ʲ��й�Ʊ��Ѻ�ʲ��ѿۼ�����Ʊ��Ѻ��Ȩ��ծ����0
	,0 as ��Ʊ��Ѻ��ծ_��ĩ
	,0 as ��Ʊ��Ѻ��ծ_���վ�
	,0 as ��Ʊ��Ѻ��ծ_���վ�
	
	,0 as ��Ʊ��Ѻ����֤ȯ��ֵ_��ĩ
	,0 as ��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
	,0 as ��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
 FROM #T_PUB_SER_RELA T2
 LEFT JOIN DM.T_AST_ODI_M_D t1 
 	ON t1.OCCUR_DT=t2.OCCUR_DT 
 			and t1.CUST_ID=t2.HS_CUST_ID
 left join DM.T_AST_CREDIT_M_D t3 
 		on t2.OCCUR_DT=t3.OCCUR_DT 
 			and t2.HS_CUST_ID=t3.CUST_ID
 left join #temp_t_gpzy t_gpzy 
 		on t2.OCCUR_DT=t_gpzy.OCCUR_DT 
 			and t2.HS_CUST_ID=t_gpzy.CUST_ID
 left join DM.T_AST_APPTBUYB_M_D t_ydgh 
 		on t2.OCCUR_DT=t_ydgh.OCCUR_DT 
 			and t2.HS_CUST_ID=t_ydgh.CUST_ID
 ;

END
GO
CREATE PROCEDURE dm.P_AST_EMPCUS_STKPLG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ���Ʊ��Ѻ�±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ���Ʊ��Ѻ�±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

   --PART0 ɾ����������
    DELETE FROM DM.T_AST_EMPCUS_STKPLG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
   ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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

	 
	--ÿ��Ա����Ϣ��
	select a.dt AS OCCUR_DT,a.year,a.mth,pk_org as  WH_ORG_NO,afatwo_ygh AS AFA_SEC_EMPID,rylx,hrid,ygh,ygxm,ygzt,is_virtual,jgbh_hs,lzrq
	into #T_PTY_PERSON_M
	from  dm.T_PUB_DATE a
	left join dba.t_edw_person_d  b on b.rq=case when a.dt<=20171031 then a.nxt_trd_day else a.dt end  
	where a.dt=@V_BIN_DATE;	 
	
	
	 --����ÿ�տͻ�����
  SELECT  
     OUC.CLIENT_ID 	AS CUST_ID  --�ͻ�����
	,@V_BIN_YEAR           	AS YEAR      --��
	,@V_BIN_MTH           	AS MTH       --��
	,@V_BIN_DATE            AS OCCUR_DT  --ҵ������
	,OUF.FUND_ACCOUNT  		AS MAIN_CPTL_ACCT     --���ʽ��˺ţ���ͨ�˻���
	,DOH.PK_ORG 	 		AS WH_ORG_ID          --�ֿ�������� 
	,CONVERT(VARCHAR,OUC.BRANCH_NO) AS HS_ORG_ID  --������������
    ,OUF.OPEN_DATE 					AS TE_OACT_DT   --���翪������
	
	INTO #T_PUB_CUST
	
	FROM DBA.T_EDW_UF2_CLIENT  			OUC   --���пͻ���Ϣ
    LEFT JOIN DBA.T_edw_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID AND OUF.LOAD_DT=OUC.LOAD_dT AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --��ͨ�˻����ʽ��˺�
	LEFT JOIN DBA.T_DIM_ORG_HIS  		DOH ON CONVERT(VARCHAR,OUC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=OUC.LOAD_dT AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL    --���ظ�ֵ
	WHERE OUC.BRANCH_NO NOT IN (5,55,51,44,9999)--20180207 �������ų�"�ܲ�ר���˻�"
      AND OUC.LOAD_DT=@V_BIN_DATE;
		 
	

	INSERT INTO DM.T_AST_EMPCUS_STKPLG_M_D 
	(
	   YEAR                 		  --��
	  ,MTH                  		  --��
	  ,OCCUR_DT                       --ҵ������
	  ,CUST_ID              		  --�ͻ�����
	  ,AFA_SEC_EMPID        		  --AFA_����Ա����
	  ,CTR_NO               		  --��ͬ���
	  ,YEAR_MTH             		  --����
	  ,YEAR_MTH_CUST_ID     		  --���¿ͻ�����
	  ,YEAR_MTH_PSN_JNO     		  --����Ա����
	  ,WH_ORG_ID_CUST       		  --�ֿ��������_�ͻ�
	  ,WH_ORG_ID_EMP        		  --�ֿ��������_Ա��
	  ,GUAR_SECU_MVAL_FINAL 		  --����֤ȯ��ֵ_��ĩ
	  ,STKPLG_FIN_BAL_FINAL 		  --��Ʊ��Ѻ�������_��ĩ
	  ,SH_GUAR_SECU_MVAL_FINAL 	      --�Ϻ�����֤ȯ��ֵ_��ĩ
	  ,SZ_GUAR_SECU_MVAL_FINAL 	      --���ڵ���֤ȯ��ֵ_��ĩ
	  ,SH_NOTS_GUAR_SECU_MVAL_FINAL   --�Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
	  ,SZ_NOTS_GUAR_SECU_MVAL_FINAL   --�������۹ɵ���֤ȯ��ֵ_��ĩ
	  ,PROP_FINAC_OUT_SIDE_BAL_FINAL  --��Ӫ�ڳ������_��ĩ
	  ,ASSM_FINAC_OUT_SIDE_BAL_FINAL  --�ʹ��ڳ������_��ĩ
	  ,SM_LOAN_FINAC_OUT_BAL_FINAL    --С����ڳ����_��ĩ
	  ,GUAR_SECU_MVAL_MDA             --����֤ȯ��ֵ_���վ�
	  ,STKPLG_FIN_BAL_MDA             --��Ʊ��Ѻ�������_���վ�
	  ,SH_GUAR_SECU_MVAL_MDA          --�Ϻ�����֤ȯ��ֵ_���վ�
	  ,SZ_GUAR_SECU_MVAL_MDA          --���ڵ���֤ȯ��ֵ_���վ�
	  ,SH_NOTS_GUAR_SECU_MVAL_MDA     --�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	  ,SZ_NOTS_GUAR_SECU_MVAL_MDA     --�������۹ɵ���֤ȯ��ֵ_���վ�
	  ,PROP_FINAC_OUT_SIDE_BAL_MDA    --��Ӫ�ڳ������_���վ�
	  ,ASSM_FINAC_OUT_SIDE_BAL_MDA    --�ʹ��ڳ������_���վ�
	  ,SM_LOAN_FINAC_OUT_BAL_MDA      --С����ڳ����_���վ�
	  ,GUAR_SECU_MVAL_YDA             --����֤ȯ��ֵ_���վ�
	  ,STKPLG_FIN_BAL_YDA             --��Ʊ��Ѻ�������_���վ�
	  ,SH_GUAR_SECU_MVAL_YDA          --�Ϻ�����֤ȯ��ֵ_���վ�
	  ,SZ_GUAR_SECU_MVAL_YDA          --���ڵ���֤ȯ��ֵ_���վ�
	  ,SH_NOTS_GUAR_SECU_MVAL_YDA     --�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	  ,SZ_NOTS_GUAR_SECU_MVAL_YDA     --�������۹ɵ���֤ȯ��ֵ_���վ�
	  ,PROP_FINAC_OUT_SIDE_BAL_YDA    --��Ӫ�ڳ������_���վ�
	  ,ASSM_FINAC_OUT_SIDE_BAL_YDA    --�ʹ��ڳ������_���վ�
	  ,SM_LOAN_FINAC_OUT_BAL_YDA      --С����ڳ����_���վ�
	  ,LOAD_DT                        --��ϴ����
	)
	select
	t1.YEAR as ��
	,t1.MTH as ��
	,T1.OCCUR_DT
	,t1.CUST_ID as �ͻ�����
	,t1.AFA_SEC_EMPID as AFA����Ա����
	,t1.CTR_NO as ��ͬ���
	,t1.YEAR||t1.MTH as ����
	,t1.YEAR||t1.MTH||t1.CUST_ID as ���¿ͻ�����
	,t_kh.WH_ORG_ID as �ֿ��������_�ͻ�
	,t_yg.WH_ORG_NO as �ֿ��������_Ա��
	,t1.YEAR||t1.MTH||t1.AFA_SEC_EMPID as ����Ա����
	,sum(COALESCE(t1.����֤ȯ��ֵ_��ĩ,0)) as ����֤ȯ��ֵ_��ĩ
	,sum(COALESCE(t1.��Ʊ��Ѻ�������_��ĩ,0)) as ��Ʊ��Ѻ�������_��ĩ
	,sum(COALESCE(t1.�Ϻ�����֤ȯ��ֵ_��ĩ,0)) as �Ϻ�����֤ȯ��ֵ_��ĩ
	,sum(COALESCE(t1.���ڵ���֤ȯ��ֵ_��ĩ,0)) as ���ڵ���֤ȯ��ֵ_��ĩ
	,sum(COALESCE(t1.�Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ,0)) as �Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
	,sum(COALESCE(t1.�������۹ɵ���֤ȯ��ֵ_��ĩ,0)) as �������۹ɵ���֤ȯ��ֵ_��ĩ
	,sum(COALESCE(t1.��Ӫ�ڳ������_��ĩ,0)) as ��Ӫ�ڳ������_��ĩ
	,sum(COALESCE(t1.�ʹ��ڳ������_��ĩ,0)) as �ʹ��ڳ������_��ĩ
	,sum(COALESCE(t1.С����ڳ����_��ĩ,0)) as С����ڳ����_��ĩ
	
	,sum(COALESCE(t1.����֤ȯ��ֵ_���վ�,0)) as ����֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.��Ʊ��Ѻ�������_���վ�,0)) as ��Ʊ��Ѻ�������_���վ�
	,sum(COALESCE(t1.�Ϻ�����֤ȯ��ֵ_���վ�,0)) as �Ϻ�����֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.���ڵ���֤ȯ��ֵ_���վ�,0)) as ���ڵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�,0)) as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.�������۹ɵ���֤ȯ��ֵ_���վ�,0)) as �������۹ɵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.��Ӫ�ڳ������_���վ�,0)) as ��Ӫ�ڳ������_���վ�
	,sum(COALESCE(t1.�ʹ��ڳ������_���վ�,0)) as �ʹ��ڳ������_���վ�
	,sum(COALESCE(t1.С����ڳ����_���վ�,0)) as С����ڳ����_���վ�
	
	,sum(COALESCE(t1.����֤ȯ��ֵ_���վ�,0)) as ����֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.��Ʊ��Ѻ�������_���վ�,0)) as ��Ʊ��Ѻ�������_���վ�
	,sum(COALESCE(t1.�Ϻ�����֤ȯ��ֵ_���վ�,0)) as �Ϻ�����֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.���ڵ���֤ȯ��ֵ_���վ�,0)) as ���ڵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.�Ϻ����۹ɵ���֤ȯ��ֵ_���վ�,0)) as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.�������۹ɵ���֤ȯ��ֵ_���վ�,0)) as �������۹ɵ���֤ȯ��ֵ_���վ�
	,sum(COALESCE(t1.��Ӫ�ڳ������_���վ�,0)) as ��Ӫ�ڳ������_���վ�
	,sum(COALESCE(t1.�ʹ��ڳ������_���վ�,0)) as �ʹ��ڳ������_���վ�
	,sum(COALESCE(t1.С����ڳ����_���վ�,0)) as С����ڳ����_���վ�
	,@V_BIN_DATE                       --��ϴ����
	from
	(
	select 
		t1.YEAR
		,t1.MTH	
        ,T1.OCCUR_DT		
		,t1.CUST_ID		
		,t1.CTR_NO
		,t2.AFA_SEC_EMPID		
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_FINAL,0) as ����֤ȯ��ֵ_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_FINAL,0) as ��Ʊ��Ѻ�������_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0) as �Ϻ�����֤ȯ��ֵ_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0) as ���ڵ���֤ȯ��ֵ_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0) as �Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0) as �������۹ɵ���֤ȯ��ֵ_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0) as ��Ӫ�ڳ������_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0) as �ʹ��ڳ������_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0) as С����ڳ����_��ĩ
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_MDA,0) as ����֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_MDA,0) as ��Ʊ��Ѻ�������_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0) as �Ϻ�����֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0) as ���ڵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0) as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0) as �������۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0) as ��Ӫ�ڳ������_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0) as �ʹ��ڳ������_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0) as С����ڳ����_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.GUAR_SECU_MVAL_YDA,0) as ����֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.STKPLG_FIN_BAL_YDA,0) as ��Ʊ��Ѻ�������_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0) as �Ϻ�����֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0) as ���ڵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0) as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0) as �������۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0) as ��Ӫ�ڳ������_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0) as �ʹ��ڳ������_���վ�
		,COALESCE(t2.RIGHT_RATI,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0) as С����ڳ����_���վ�
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
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_FINAL,0) as ����֤ȯ��ֵ_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_FINAL,0) as ��Ʊ��Ѻ�������_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_FINAL,0) as �Ϻ�����֤ȯ��ֵ_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_FINAL,0) as ���ڵ���֤ȯ��ֵ_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_FINAL,0) as �Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_FINAL,0) as �������۹ɵ���֤ȯ��ֵ_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_FINAL,0) as ��Ӫ�ڳ������_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_FINAL,0) as �ʹ��ڳ������_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_FINAL,0) as С����ڳ����_��ĩ
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_MDA,0) as ����֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_MDA,0) as ��Ʊ��Ѻ�������_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_MDA,0) as �Ϻ�����֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_MDA,0) as ���ڵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_MDA,0) as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_MDA,0) as �������۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_MDA,0) as ��Ӫ�ڳ������_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_MDA,0) as �ʹ��ڳ������_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_MDA,0) as С����ڳ����_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.GUAR_SECU_MVAL_YDA,0) as ����֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.STKPLG_FIN_BAL_YDA,0) as ��Ʊ��Ѻ�������_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_GUAR_SECU_MVAL_YDA,0) as �Ϻ�����֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_GUAR_SECU_MVAL_YDA,0) as ���ڵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SH_NOTS_GUAR_SECU_MVAL_YDA,0) as �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SZ_NOTS_GUAR_SECU_MVAL_YDA,0) as �������۹ɵ���֤ȯ��ֵ_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.PROP_FINAC_OUT_SIDE_BAL_YDA,0) as ��Ӫ�ڳ������_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.ASSM_FINAC_OUT_SIDE_BAL_YDA,0) as �ʹ��ڳ������_���վ�
		,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t1.SM_LOAN_FINAC_OUT_BAL_YDA,0) as С����ڳ����_���վ�
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
	  WHERE AFA����Ա���� IS NOT NULL
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
GO
CREATE PROCEDURE dm.P_AST_M_BRH(IN @V_DATE INT)
BEGIN

/******************************************************************
  ������: Ӫҵ���ʲ����±�
  ��д��: Ҷ���
  ��������: 2018-04-09
  ��飺Ӫҵ��ά�ȵĿͻ��ʲ���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
 	DECLARE @V_ACCU_MDAYS INT;		-- ���ۼ�����
 	DECLARE @V_ACCU_YDAYS INT;		-- ���ۼ�����
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_AST_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_YEAR									AS    YEAR   					--��
		,@V_MONTH 									AS    MTH 						--��
		,BRH_ID										AS    BRH_ID                	--Ӫҵ������	
		,@V_DATE 									AS 	  OCCUR_DT 					--��������
		,SUM(TOT_AST)/@V_ACCU_MDAYS					AS    TOT_AST_MDA				--���ʲ�_���վ�			
		,SUM(SCDY_MVAL)/@V_ACCU_MDAYS				AS    SCDY_MVAL_MDA				--������ֵ_���վ�			
		,SUM(STKF_MVAL)/@V_ACCU_MDAYS				AS    STKF_MVAL_MDA				--�ɻ���ֵ_���վ�			
		,SUM(A_SHR_MVAL)/@V_ACCU_MDAYS				AS    A_SHR_MVAL_MDA			--A����ֵ_���վ�				
		,SUM(NOTS_MVAL)/@V_ACCU_MDAYS				AS    NOTS_MVAL_MDA				--���۹���ֵ_���վ�			
		,SUM(OFFUND_MVAL)/@V_ACCU_MDAYS				AS    OFFUND_MVAL_MDA			--���ڻ�����ֵ_���վ�				
		,SUM(OPFUND_MVAL)/@V_ACCU_MDAYS				AS    OPFUND_MVAL_MDA			--���������ֵ_���վ�				
		,SUM(SB_MVAL)/@V_ACCU_MDAYS					AS    SB_MVAL_MDA				--������ֵ_���վ�			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_MDAYS			AS    IMGT_PD_MVAL_MDA			--�ʹܲ�Ʒ��ֵ_���վ�				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_MDAYS			AS    BANK_CHRM_MVAL_MDA		--���������ֵ_���վ�					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_MDAYS			AS    SECU_CHRM_MVAL_MDA		--֤ȯ�����ֵ_���վ�					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_MDAYS			AS    PSTK_OPTN_MVAL_MDA		--������Ȩ��ֵ_���վ�					
		,SUM(B_SHR_MVAL)/@V_ACCU_MDAYS				AS    B_SHR_MVAL_MDA			--B����ֵ_���վ�				
		,SUM(OUTMARK_MVAL)/@V_ACCU_MDAYS			AS    OUTMARK_MVAL_MDA			--������ֵ_���վ�				
		,SUM(CPTL_BAL)/@V_ACCU_MDAYS				AS    CPTL_BAL_MDA				--�ʽ����_���վ�			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_MDAYS			AS    NO_ARVD_CPTL_MDA			--δ�����ʽ�_���վ�				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_MDAYS			AS    PTE_FUND_MVAL_MDA			--˽ļ������ֵ_���վ�				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_MDAYS			AS    CPTL_BAL_RMB_MDA			--�ʽ���������_���վ�				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_MDAYS			AS    CPTL_BAL_HKD_MDA			--�ʽ����۱�_���վ�				
		,SUM(CPTL_BAL_USD)/@V_ACCU_MDAYS			AS    CPTL_BAL_USD_MDA			--�ʽ������Ԫ_���վ�				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_MDAYS		AS    FUND_SPACCT_MVAL_MDA		--����ר����ֵ_���վ�					
		,SUM(HGT_MVAL)/@V_ACCU_MDAYS				AS    HGT_MVAL_MDA				--����ͨ��ֵ_���վ�			
		,SUM(SGT_MVAL)/@V_ACCU_MDAYS				AS    SGT_MVAL_MDA				--���ͨ��ֵ_���վ�			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_MDAYS	AS    TOT_AST_CONTAIN_NOTS_MDA	--���ʲ�_�����۹�_���վ�						
		,SUM(BOND_MVAL)/@V_ACCU_MDAYS				AS    BOND_MVAL_MDA				--ծȯ��ֵ_���վ�			
		,SUM(REPO_MVAL)/@V_ACCU_MDAYS				AS    REPO_MVAL_MDA				--�ع���ֵ_���վ�			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_MDAYS			AS    TREA_REPO_MVAL_MDA		--��ծ�ع���ֵ_���վ�					
		,SUM(REPQ_MVAL)/@V_ACCU_MDAYS				AS    REPQ_MVAL_MDA				--���ۻع���ֵ_���վ�			
		,SUM(PO_FUND_MVAL)/@V_ACCU_MDAYS			AS    PO_FUND_MVAL_MDA			--��ļ������ֵ_���վ�				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_MDAYS		AS    APPTBUYB_PLG_MVAL_MDA		--Լ��������Ѻ��ֵ_���վ�					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_MDAYS			AS    OTH_PROD_MVAL_MDA			--������Ʒ��ֵ_���վ�				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_MDAYS			AS    STKT_FUND_MVAL_MDA		--��Ʊ�ͻ�����ֵ_���վ�					
		,SUM(OTH_AST_MVAL)/@V_ACCU_MDAYS			AS    OTH_AST_MVAL_MDA			--�����ʲ���ֵ_���վ�				
		,SUM(CREDIT_MARG)/@V_ACCU_MDAYS				AS    CREDIT_MARG_MDA			--������ȯ��֤��_���վ�				
		,SUM(CREDIT_NET_AST)/@V_ACCU_MDAYS			AS    CREDIT_NET_AST_MDA		--������ȯ���ʲ�_���վ�					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_MDAYS			AS    PROD_TOT_MVAL_MDA			--��Ʒ����ֵ_���վ�				
		,SUM(JQL9_MVAL)/@V_ACCU_MDAYS				AS    JQL9_MVAL_MDA				--������9��ֵ_���վ�			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_MDAYS		AS    STKPLG_GUAR_SECMV_MDA		--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_MDAYS			AS    STKPLG_FIN_BAL_MDA		--��Ʊ��Ѻ�������_���վ�					
		,SUM(APPTBUYB_BAL)/@V_ACCU_MDAYS			AS    APPTBUYB_BAL_MDA			--Լ���������_���վ�				
		,SUM(CRED_MARG)/@V_ACCU_MDAYS				AS    CRED_MARG_MDA				--���ñ�֤��_���վ�			
		,SUM(INTR_LIAB)/@V_ACCU_MDAYS				AS    INTR_LIAB_MDA				--��Ϣ��ծ_���վ�			
		,SUM(FEE_LIAB)/@V_ACCU_MDAYS				AS    FEE_LIAB_MDA				--���ø�ծ_���վ�			
		,SUM(OTHLIAB)/@V_ACCU_MDAYS					AS    OTHLIAB_MDA				--������ծ_���վ�			
		,SUM(FIN_LIAB)/@V_ACCU_MDAYS				AS    FIN_LIAB_MDA				--���ʸ�ծ_���վ�			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_MDAYS			AS    CRDT_STK_LIAB_MDA			--��ȯ��ծ_���վ�				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_MDAYS			AS    CREDIT_TOT_AST_MDA		--������ȯ���ʲ�_���վ�					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_MDAYS			AS    CREDIT_TOT_LIAB_MDA		--������ȯ�ܸ�ծ_���վ�					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_MDAYS		AS    APPTBUYB_GUAR_SECMV_MDA	--Լ�����ص���֤ȯ��ֵ_���վ�						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_MDAYS		AS    CREDIT_GUAR_SECMV_MDA		--������ȯ����֤ȯ��ֵ_���վ�					
	INTO #T_AST_M_BRH_MTH
	FROM DM.T_AST_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

		SELECT 
		 @V_YEAR									AS    YEAR   					--��
		,@V_MONTH 									AS    MTH 						--��
		,BRH_ID										AS    BRH_ID                	--Ӫҵ������	
		,@V_DATE 									AS 	  OCCUR_DT 					--��������
		,SUM(TOT_AST)/@V_ACCU_YDAYS					AS    TOT_AST_YDA				--���ʲ�_���վ�			
		,SUM(SCDY_MVAL)/@V_ACCU_YDAYS				AS    SCDY_MVAL_YDA				--������ֵ_���վ�			
		,SUM(STKF_MVAL)/@V_ACCU_YDAYS				AS    STKF_MVAL_YDA				--�ɻ���ֵ_���վ�			
		,SUM(A_SHR_MVAL)/@V_ACCU_YDAYS				AS    A_SHR_MVAL_YDA			--A����ֵ_���վ�				
		,SUM(NOTS_MVAL)/@V_ACCU_YDAYS				AS    NOTS_MVAL_YDA				--���۹���ֵ_���վ�			
		,SUM(OFFUND_MVAL)/@V_ACCU_YDAYS				AS    OFFUND_MVAL_YDA			--���ڻ�����ֵ_���վ�				
		,SUM(OPFUND_MVAL)/@V_ACCU_YDAYS				AS    OPFUND_MVAL_YDA			--���������ֵ_���վ�				
		,SUM(SB_MVAL)/@V_ACCU_YDAYS					AS    SB_MVAL_YDA				--������ֵ_���վ�			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_YDAYS			AS    IMGT_PD_MVAL_YDA			--�ʹܲ�Ʒ��ֵ_���վ�				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_YDAYS			AS    BANK_CHRM_MVAL_YDA		--���������ֵ_���վ�					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_YDAYS			AS    SECU_CHRM_MVAL_YDA		--֤ȯ�����ֵ_���վ�					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_YDAYS			AS    PSTK_OPTN_MVAL_YDA		--������Ȩ��ֵ_���վ�					
		,SUM(B_SHR_MVAL)/@V_ACCU_YDAYS				AS    B_SHR_MVAL_YDA			--B����ֵ_���վ�				
		,SUM(OUTMARK_MVAL)/@V_ACCU_YDAYS			AS    OUTMARK_MVAL_YDA			--������ֵ_���վ�				
		,SUM(CPTL_BAL)/@V_ACCU_YDAYS				AS    CPTL_BAL_YDA				--�ʽ����_���վ�			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_YDAYS			AS    NO_ARVD_CPTL_YDA			--δ�����ʽ�_���վ�				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_YDAYS			AS    PTE_FUND_MVAL_YDA			--˽ļ������ֵ_���վ�				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_YDAYS			AS    CPTL_BAL_RMB_YDA			--�ʽ���������_���վ�				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_YDAYS			AS    CPTL_BAL_HKD_YDA			--�ʽ����۱�_���վ�				
		,SUM(CPTL_BAL_USD)/@V_ACCU_YDAYS			AS    CPTL_BAL_USD_YDA			--�ʽ������Ԫ_���վ�				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_YDAYS		AS    FUND_SPACCT_MVAL_YDA		--����ר����ֵ_���վ�					
		,SUM(HGT_MVAL)/@V_ACCU_YDAYS				AS    HGT_MVAL_YDA				--����ͨ��ֵ_���վ�			
		,SUM(SGT_MVAL)/@V_ACCU_YDAYS				AS    SGT_MVAL_YDA				--���ͨ��ֵ_���վ�			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_YDAYS	AS    TOT_AST_CONTAIN_NOTS_YDA	--���ʲ�_�����۹�_���վ�						
		,SUM(BOND_MVAL)/@V_ACCU_YDAYS				AS    BOND_MVAL_YDA				--ծȯ��ֵ_���վ�			
		,SUM(REPO_MVAL)/@V_ACCU_YDAYS				AS    REPO_MVAL_YDA				--�ع���ֵ_���վ�			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_YDAYS			AS    TREA_REPO_MVAL_YDA		--��ծ�ع���ֵ_���վ�					
		,SUM(REPQ_MVAL)/@V_ACCU_YDAYS				AS    REPQ_MVAL_YDA				--���ۻع���ֵ_���վ�			
		,SUM(PO_FUND_MVAL)/@V_ACCU_YDAYS			AS    PO_FUND_MVAL_YDA			--��ļ������ֵ_���վ�				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_YDAYS		AS    APPTBUYB_PLG_MVAL_YDA		--Լ��������Ѻ��ֵ_���վ�					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_YDAYS			AS    OTH_PROD_MVAL_YDA			--������Ʒ��ֵ_���վ�				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_YDAYS			AS    STKT_FUND_MVAL_YDA		--��Ʊ�ͻ�����ֵ_���վ�					
		,SUM(OTH_AST_MVAL)/@V_ACCU_YDAYS			AS    OTH_AST_MVAL_YDA			--�����ʲ���ֵ_���վ�				
		,SUM(CREDIT_MARG)/@V_ACCU_YDAYS				AS    CREDIT_MARG_YDA			--������ȯ��֤��_���վ�				
		,SUM(CREDIT_NET_AST)/@V_ACCU_YDAYS			AS    CREDIT_NET_AST_YDA		--������ȯ���ʲ�_���վ�					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_YDAYS			AS    PROD_TOT_MVAL_YDA			--��Ʒ����ֵ_���վ�				
		,SUM(JQL9_MVAL)/@V_ACCU_YDAYS				AS    JQL9_MVAL_YDA				--������9��ֵ_���վ�			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_YDAYS		AS    STKPLG_GUAR_SECMV_YDA		--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_YDAYS			AS    STKPLG_FIN_BAL_YDA		--��Ʊ��Ѻ�������_���վ�					
		,SUM(APPTBUYB_BAL)/@V_ACCU_YDAYS			AS    APPTBUYB_BAL_YDA			--Լ���������_���վ�				
		,SUM(CRED_MARG)/@V_ACCU_YDAYS				AS    CRED_MARG_YDA				--���ñ�֤��_���վ�			
		,SUM(INTR_LIAB)/@V_ACCU_YDAYS				AS    INTR_LIAB_YDA				--��Ϣ��ծ_���վ�			
		,SUM(FEE_LIAB)/@V_ACCU_YDAYS				AS    FEE_LIAB_YDA				--���ø�ծ_���վ�			
		,SUM(OTHLIAB)/@V_ACCU_YDAYS					AS    OTHLIAB_YDA				--������ծ_���վ�			
		,SUM(FIN_LIAB)/@V_ACCU_YDAYS				AS    FIN_LIAB_YDA				--���ʸ�ծ_���վ�			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_YDAYS			AS    CRDT_STK_LIAB_YDA			--��ȯ��ծ_���վ�				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_YDAYS			AS    CREDIT_TOT_AST_YDA		--������ȯ���ʲ�_���վ�					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_YDAYS			AS    CREDIT_TOT_LIAB_YDA		--������ȯ�ܸ�ծ_���վ�					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_YDAYS		AS    APPTBUYB_GUAR_SECMV_YDA	--Լ�����ص���֤ȯ��ֵ_���վ�						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_YDAYS		AS    CREDIT_GUAR_SECMV_YDA		--������ȯ����֤ȯ��ֵ_���վ�					
	INTO #T_AST_M_BRH_YEAR
	FROM DM.T_AST_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--����Ŀ���
	INSERT INTO DM.T_AST_M_BRH(
		 YEAR        					--��
		,MTH         					--��
		,BRH_ID                			--Ӫҵ������	
		,OCCUR_DT    					--��������
		,TOT_AST_MDA          			--���ʲ�_���վ�
		,TOT_AST_YDA          			--���ʲ�_���վ�
		,SCDY_MVAL_MDA        			--������ֵ_���վ�
		,SCDY_MVAL_YDA        			--������ֵ_���վ�
		,STKF_MVAL_MDA        			--�ɻ���ֵ_���վ�
		,STKF_MVAL_YDA        			--�ɻ���ֵ_���վ�
		,A_SHR_MVAL_MDA       			--A����ֵ_���վ�
		,A_SHR_MVAL_YDA       			--A����ֵ_���վ�
		,NOTS_MVAL_MDA        			--���۹���ֵ_���վ�
		,NOTS_MVAL_YDA        			--���۹���ֵ_���վ�
		,OFFUND_MVAL_MDA      			--���ڻ�����ֵ_���վ�
		,OFFUND_MVAL_YDA      			--���ڻ�����ֵ_���վ�
		,OPFUND_MVAL_MDA      			--���������ֵ_���վ�
		,OPFUND_MVAL_YDA      			--���������ֵ_���վ�
		,SB_MVAL_MDA          			--������ֵ_���վ�
		,SB_MVAL_YDA          			--������ֵ_���վ�
		,IMGT_PD_MVAL_MDA     			--�ʹܲ�Ʒ��ֵ_���վ�
		,IMGT_PD_MVAL_YDA     			--�ʹܲ�Ʒ��ֵ_���վ�
		,BANK_CHRM_MVAL_YDA   			--���������ֵ_���վ�
		,BANK_CHRM_MVAL_MDA   			--���������ֵ_���վ�
		,SECU_CHRM_MVAL_MDA   			--֤ȯ�����ֵ_���վ�
		,SECU_CHRM_MVAL_YDA   			--֤ȯ�����ֵ_���վ�
		,PSTK_OPTN_MVAL_MDA   			--������Ȩ��ֵ_���վ�
		,PSTK_OPTN_MVAL_YDA   			--������Ȩ��ֵ_���վ�
		,B_SHR_MVAL_MDA       			--B����ֵ_���վ�
		,B_SHR_MVAL_YDA       			--B����ֵ_���վ�
		,OUTMARK_MVAL_MDA     			--������ֵ_���վ�
		,OUTMARK_MVAL_YDA     			--������ֵ_���վ�
		,CPTL_BAL_MDA         			--�ʽ����_���վ�
		,CPTL_BAL_YDA         			--�ʽ����_���վ�
		,NO_ARVD_CPTL_MDA     			--δ�����ʽ�_���վ�
		,NO_ARVD_CPTL_YDA     			--δ�����ʽ�_���վ�
		,PTE_FUND_MVAL_MDA    			--˽ļ������ֵ_���վ�
		,PTE_FUND_MVAL_YDA    			--˽ļ������ֵ_���վ�
		,CPTL_BAL_RMB_MDA     			--�ʽ���������_���վ�
		,CPTL_BAL_RMB_YDA     			--�ʽ���������_���վ�
		,CPTL_BAL_HKD_MDA     			--�ʽ����۱�_���վ�
		,CPTL_BAL_HKD_YDA     			--�ʽ����۱�_���վ�
		,CPTL_BAL_USD_MDA     			--�ʽ������Ԫ_���վ�
		,CPTL_BAL_USD_YDA     			--�ʽ������Ԫ_���վ�
		,FUND_SPACCT_MVAL_MDA 			--����ר����ֵ_���վ�
		,FUND_SPACCT_MVAL_YDA 			--����ר����ֵ_���վ�
		,HGT_MVAL_MDA         			--����ͨ��ֵ_���վ�
		,HGT_MVAL_YDA         			--����ͨ��ֵ_���վ�
		,SGT_MVAL_MDA         			--���ͨ��ֵ_���վ�
		,SGT_MVAL_YDA         			--���ͨ��ֵ_���վ�
		,TOT_AST_CONTAIN_NOTS_MDA		--���ʲ�_�����۹�_���վ�
		,TOT_AST_CONTAIN_NOTS_YDA		--���ʲ�_�����۹�_���վ�
		,BOND_MVAL_MDA        			--ծȯ��ֵ_���վ�
		,BOND_MVAL_YDA        			--ծȯ��ֵ_���վ�
		,REPO_MVAL_MDA        			--�ع���ֵ_���վ�
		,REPO_MVAL_YDA        			--�ع���ֵ_���վ�
		,TREA_REPO_MVAL_MDA   			--��ծ�ع���ֵ_���վ�
		,TREA_REPO_MVAL_YDA   			--��ծ�ع���ֵ_���վ�
		,REPQ_MVAL_MDA        			--���ۻع���ֵ_���վ�
		,REPQ_MVAL_YDA        			--���ۻع���ֵ_���վ�
		,PO_FUND_MVAL_MDA     			--��ļ������ֵ_���վ�
		,PO_FUND_MVAL_YDA     			--��ļ������ֵ_���վ�
		,APPTBUYB_PLG_MVAL_MDA			--Լ��������Ѻ��ֵ_���վ�
		,APPTBUYB_PLG_MVAL_YDA			--Լ��������Ѻ��ֵ_���վ�
		,OTH_PROD_MVAL_MDA    			--������Ʒ��ֵ_���վ�
		,STKT_FUND_MVAL_MDA   			--��Ʊ�ͻ�����ֵ_���վ�
		,OTH_AST_MVAL_MDA     			--�����ʲ���ֵ_���վ�
		,OTH_PROD_MVAL_YDA    			--������Ʒ��ֵ_���վ�
		,APPTBUYB_BAL_YDA     			--Լ���������_���վ�
		,CREDIT_MARG_MDA      			--������ȯ��֤��_���վ�
		,CREDIT_MARG_YDA      			--������ȯ��֤��_���վ�
		,CREDIT_NET_AST_MDA   			--������ȯ���ʲ�_���վ�
		,CREDIT_NET_AST_YDA   			--������ȯ���ʲ�_���վ�
		,PROD_TOT_MVAL_MDA    			--��Ʒ����ֵ_���վ�
		,PROD_TOT_MVAL_YDA    			--��Ʒ����ֵ_���վ�
		,JQL9_MVAL_MDA        			--������9��ֵ_���վ�
		,JQL9_MVAL_YDA        			--������9��ֵ_���վ�
		,STKPLG_GUAR_SECMV_MDA			--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,STKPLG_GUAR_SECMV_YDA			--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,STKPLG_FIN_BAL_MDA   			--��Ʊ��Ѻ�������_���վ�
		,STKPLG_FIN_BAL_YDA   			--��Ʊ��Ѻ�������_���վ�
		,APPTBUYB_BAL_MDA     			--Լ���������_���վ�
		,CRED_MARG_MDA        			--���ñ�֤��_���վ�
		,CRED_MARG_YDA        			--���ñ�֤��_���վ�
		,INTR_LIAB_MDA        			--��Ϣ��ծ_���վ�
		,INTR_LIAB_YDA        			--��Ϣ��ծ_���վ�
		,FEE_LIAB_MDA         			--���ø�ծ_���վ�
		,FEE_LIAB_YDA         			--���ø�ծ_���վ�
		,OTHLIAB_MDA          			--������ծ_���վ�
		,OTHLIAB_YDA          			--������ծ_���վ�
		,FIN_LIAB_MDA         			--���ʸ�ծ_���վ�
		,CRDT_STK_LIAB_YDA    			--��ȯ��ծ_���վ�
		,CRDT_STK_LIAB_MDA    			--��ȯ��ծ_���վ�
		,FIN_LIAB_YDA         			--���ʸ�ծ_���վ�
		,CREDIT_TOT_AST_MDA   			--������ȯ���ʲ�_���վ�
		,CREDIT_TOT_AST_YDA   			--������ȯ���ʲ�_���վ�
		,CREDIT_TOT_LIAB_MDA  			--������ȯ�ܸ�ծ_���վ�
		,CREDIT_TOT_LIAB_YDA  			--������ȯ�ܸ�ծ_���վ�
		,APPTBUYB_GUAR_SECMV_MDA		--Լ�����ص���֤ȯ��ֵ_���վ�
		,APPTBUYB_GUAR_SECMV_YDA		--Լ�����ص���֤ȯ��ֵ_���վ�
		,CREDIT_GUAR_SECMV_MDA			--������ȯ����֤ȯ��ֵ_���վ�
		,CREDIT_GUAR_SECMV_YDA			--������ȯ����֤ȯ��ֵ_���վ�		
	)		
	SELECT 
		 T1.YEAR						AS  YEAR					  --��
		,T1.MTH							AS  MTH						  --��
		,T1.BRH_ID                		AS  BRH_ID                	  --Ӫҵ������		
		,T1.OCCUR_DT					AS  OCCUR_DT				  --��������
		,T1.TOT_AST_MDA	  	  			AS  TOT_AST_MDA               --���ʲ�_���վ�
		,T2.TOT_AST_YDA	  	  			AS  TOT_AST_YDA               --���ʲ�_���վ�
		,T1.SCDY_MVAL_MDA	  			AS  SCDY_MVAL_MDA             --������ֵ_���վ�
		,T2.SCDY_MVAL_YDA	  			AS  SCDY_MVAL_YDA             --������ֵ_���վ�
		,T1.STKF_MVAL_MDA	  			AS  STKF_MVAL_MDA             --�ɻ���ֵ_���վ�
		,T2.STKF_MVAL_YDA	  			AS  STKF_MVAL_YDA             --�ɻ���ֵ_���վ�
		,T1.A_SHR_MVAL_MDA	  			AS  A_SHR_MVAL_MDA            --A����ֵ_���վ�
		,T2.A_SHR_MVAL_YDA	  			AS  A_SHR_MVAL_YDA            --A����ֵ_���վ�
		,T1.NOTS_MVAL_MDA	  			AS  NOTS_MVAL_MDA             --���۹���ֵ_���վ�
		,T2.NOTS_MVAL_YDA	  			AS  NOTS_MVAL_YDA             --���۹���ֵ_���վ�
		,T1.OFFUND_MVAL_MDA	  			AS  OFFUND_MVAL_MDA           --���ڻ�����ֵ_���վ�
		,T2.OFFUND_MVAL_YDA	  			AS  OFFUND_MVAL_YDA           --���ڻ�����ֵ_���վ�
		,T1.OPFUND_MVAL_MDA	  			AS  OPFUND_MVAL_MDA           --���������ֵ_���վ�
		,T2.OPFUND_MVAL_YDA	  			AS  OPFUND_MVAL_YDA           --���������ֵ_���վ�
		,T1.SB_MVAL_MDA	  	  			AS  SB_MVAL_MDA               --������ֵ_���վ�
		,T2.SB_MVAL_YDA	  	  			AS  SB_MVAL_YDA               --������ֵ_���վ�
		,T1.IMGT_PD_MVAL_MDA	  		AS  IMGT_PD_MVAL_MDA          --�ʹܲ�Ʒ��ֵ_���վ�
		,T2.IMGT_PD_MVAL_YDA	  		AS  IMGT_PD_MVAL_YDA          --�ʹܲ�Ʒ��ֵ_���վ�
		,T2.BANK_CHRM_MVAL_YDA	  		AS  BANK_CHRM_MVAL_YDA        --���������ֵ_���վ�
		,T1.BANK_CHRM_MVAL_MDA	  		AS  BANK_CHRM_MVAL_MDA        --���������ֵ_���վ�
		,T1.SECU_CHRM_MVAL_MDA	  		AS  SECU_CHRM_MVAL_MDA        --֤ȯ�����ֵ_���վ�
		,T2.SECU_CHRM_MVAL_YDA	  		AS  SECU_CHRM_MVAL_YDA        --֤ȯ�����ֵ_���վ�
		,T1.PSTK_OPTN_MVAL_MDA	  		AS  PSTK_OPTN_MVAL_MDA        --������Ȩ��ֵ_���վ�
		,T2.PSTK_OPTN_MVAL_YDA	  		AS  PSTK_OPTN_MVAL_YDA        --������Ȩ��ֵ_���վ�
		,T1.B_SHR_MVAL_MDA	  			AS  B_SHR_MVAL_MDA            --B����ֵ_���վ�
		,T2.B_SHR_MVAL_YDA	  			AS  B_SHR_MVAL_YDA            --B����ֵ_���վ�
		,T1.OUTMARK_MVAL_MDA	  		AS  OUTMARK_MVAL_MDA          --������ֵ_���վ�
		,T2.OUTMARK_MVAL_YDA	  		AS  OUTMARK_MVAL_YDA          --������ֵ_���վ�
		,T1.CPTL_BAL_MDA	  			AS  CPTL_BAL_MDA              --�ʽ����_���վ�
		,T2.CPTL_BAL_YDA	  			AS  CPTL_BAL_YDA              --�ʽ����_���վ�
		,T1.NO_ARVD_CPTL_MDA	  		AS  NO_ARVD_CPTL_MDA          --δ�����ʽ�_���վ�
		,T2.NO_ARVD_CPTL_YDA	  		AS  NO_ARVD_CPTL_YDA          --δ�����ʽ�_���վ�
		,T1.PTE_FUND_MVAL_MDA	  		AS  PTE_FUND_MVAL_MDA         --˽ļ������ֵ_���վ�
		,T2.PTE_FUND_MVAL_YDA	  		AS  PTE_FUND_MVAL_YDA         --˽ļ������ֵ_���վ�
		,T1.CPTL_BAL_RMB_MDA	  		AS  CPTL_BAL_RMB_MDA          --�ʽ���������_���վ�
		,T2.CPTL_BAL_RMB_YDA	  		AS  CPTL_BAL_RMB_YDA          --�ʽ���������_���վ�
		,T1.CPTL_BAL_HKD_MDA	  		AS  CPTL_BAL_HKD_MDA          --�ʽ����۱�_���վ�
		,T2.CPTL_BAL_HKD_YDA	  		AS  CPTL_BAL_HKD_YDA          --�ʽ����۱�_���վ�
		,T1.CPTL_BAL_USD_MDA	  		AS  CPTL_BAL_USD_MDA          --�ʽ������Ԫ_���վ�
		,T2.CPTL_BAL_USD_YDA	  		AS  CPTL_BAL_USD_YDA          --�ʽ������Ԫ_���վ�
		,T1.FUND_SPACCT_MVAL_MDA	  	AS  FUND_SPACCT_MVAL_MDA      --����ר����ֵ_���վ�
		,T2.FUND_SPACCT_MVAL_YDA	  	AS  FUND_SPACCT_MVAL_YDA      --����ר����ֵ_���վ�
		,T1.HGT_MVAL_MDA	  			AS  HGT_MVAL_MDA              --����ͨ��ֵ_���վ�
		,T2.HGT_MVAL_YDA	  			AS  HGT_MVAL_YDA              --����ͨ��ֵ_���վ�
		,T1.SGT_MVAL_MDA	  			AS  SGT_MVAL_MDA              --���ͨ��ֵ_���վ�
		,T2.SGT_MVAL_YDA	  			AS  SGT_MVAL_YDA              --���ͨ��ֵ_���վ�
		,T1.TOT_AST_CONTAIN_NOTS_MDA	AS  TOT_AST_CONTAIN_NOTS_MDA  --���ʲ�_�����۹�_���վ�
		,T2.TOT_AST_CONTAIN_NOTS_YDA	AS  TOT_AST_CONTAIN_NOTS_YDA  --���ʲ�_�����۹�_���վ�
		,T1.BOND_MVAL_MDA	  			AS  BOND_MVAL_MDA             --ծȯ��ֵ_���վ�
		,T2.BOND_MVAL_YDA	  			AS  BOND_MVAL_YDA             --ծȯ��ֵ_���վ�
		,T1.REPO_MVAL_MDA	  			AS  REPO_MVAL_MDA             --�ع���ֵ_���վ�
		,T2.REPO_MVAL_YDA	  			AS  REPO_MVAL_YDA             --�ع���ֵ_���վ�
		,T1.TREA_REPO_MVAL_MDA	  		AS  TREA_REPO_MVAL_MDA        --��ծ�ع���ֵ_���վ�
		,T2.TREA_REPO_MVAL_YDA	  		AS  TREA_REPO_MVAL_YDA        --��ծ�ع���ֵ_���վ�
		,T1.REPQ_MVAL_MDA	  			AS  REPQ_MVAL_MDA             --���ۻع���ֵ_���վ�
		,T2.REPQ_MVAL_YDA	  			AS  REPQ_MVAL_YDA             --���ۻع���ֵ_���վ�
		,T1.PO_FUND_MVAL_MDA	  		AS  PO_FUND_MVAL_MDA          --��ļ������ֵ_���վ�
		,T2.PO_FUND_MVAL_YDA	  		AS  PO_FUND_MVAL_YDA          --��ļ������ֵ_���վ�
		,T1.APPTBUYB_PLG_MVAL_MDA	  	AS  APPTBUYB_PLG_MVAL_MDA     --Լ��������Ѻ��ֵ_���վ�
		,T2.APPTBUYB_PLG_MVAL_YDA	  	AS  APPTBUYB_PLG_MVAL_YDA     --Լ��������Ѻ��ֵ_���վ�
		,T1.OTH_PROD_MVAL_MDA	  		AS  OTH_PROD_MVAL_MDA         --������Ʒ��ֵ_���վ�
		,T1.STKT_FUND_MVAL_MDA	  		AS  STKT_FUND_MVAL_MDA        --��Ʊ�ͻ�����ֵ_���վ�
		,T1.OTH_AST_MVAL_MDA	  		AS  OTH_AST_MVAL_MDA          --�����ʲ���ֵ_���վ�
		,T2.OTH_PROD_MVAL_YDA	  		AS  OTH_PROD_MVAL_YDA         --������Ʒ��ֵ_���վ�
		,T2.APPTBUYB_BAL_YDA	  		AS  APPTBUYB_BAL_YDA          --Լ���������_���վ�
		,T1.CREDIT_MARG_MDA	  			AS  CREDIT_MARG_MDA           --������ȯ��֤��_���վ�
		,T2.CREDIT_MARG_YDA	  			AS  CREDIT_MARG_YDA           --������ȯ��֤��_���վ�
		,T1.CREDIT_NET_AST_MDA	  		AS  CREDIT_NET_AST_MDA        --������ȯ���ʲ�_���վ�
		,T2.CREDIT_NET_AST_YDA	  		AS  CREDIT_NET_AST_YDA        --������ȯ���ʲ�_���վ�
		,T1.PROD_TOT_MVAL_MDA	  		AS  PROD_TOT_MVAL_MDA         --��Ʒ����ֵ_���վ�
		,T2.PROD_TOT_MVAL_YDA	  		AS  PROD_TOT_MVAL_YDA         --��Ʒ����ֵ_���վ�
		,T1.JQL9_MVAL_MDA	  			AS  JQL9_MVAL_MDA             --������9��ֵ_���վ�
		,T2.JQL9_MVAL_YDA	  			AS  JQL9_MVAL_YDA             --������9��ֵ_���վ�
		,T1.STKPLG_GUAR_SECMV_MDA	  	AS  STKPLG_GUAR_SECMV_MDA     --��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,T2.STKPLG_GUAR_SECMV_YDA	  	AS  STKPLG_GUAR_SECMV_YDA     --��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,T1.STKPLG_FIN_BAL_MDA	  		AS  STKPLG_FIN_BAL_MDA        --��Ʊ��Ѻ�������_���վ�
		,T2.STKPLG_FIN_BAL_YDA	  		AS  STKPLG_FIN_BAL_YDA        --��Ʊ��Ѻ�������_���վ�
		,T1.APPTBUYB_BAL_MDA	  		AS  APPTBUYB_BAL_MDA          --Լ���������_���վ�
		,T1.CRED_MARG_MDA	  			AS  CRED_MARG_MDA             --���ñ�֤��_���վ�
		,T2.CRED_MARG_YDA	  			AS  CRED_MARG_YDA             --���ñ�֤��_���վ�
		,T1.INTR_LIAB_MDA	  			AS  INTR_LIAB_MDA             --��Ϣ��ծ_���վ�
		,T2.INTR_LIAB_YDA	  			AS  INTR_LIAB_YDA             --��Ϣ��ծ_���վ�
		,T1.FEE_LIAB_MDA	  			AS  FEE_LIAB_MDA              --���ø�ծ_���վ�
		,T2.FEE_LIAB_YDA	  			AS  FEE_LIAB_YDA              --���ø�ծ_���վ�
		,T1.OTHLIAB_MDA	  				AS  OTHLIAB_MDA               --������ծ_���վ�
		,T2.OTHLIAB_YDA	  				AS  OTHLIAB_YDA               --������ծ_���վ�
		,T1.FIN_LIAB_MDA	  			AS  FIN_LIAB_MDA              --���ʸ�ծ_���վ�
		,T2.CRDT_STK_LIAB_YDA	  		AS  CRDT_STK_LIAB_YDA         --��ȯ��ծ_���վ�
		,T1.CRDT_STK_LIAB_MDA	  		AS  CRDT_STK_LIAB_MDA         --��ȯ��ծ_���վ�
		,T2.FIN_LIAB_YDA	  			AS  FIN_LIAB_YDA              --���ʸ�ծ_���վ�
		,T1.CREDIT_TOT_AST_MDA	  		AS  CREDIT_TOT_AST_MDA        --������ȯ���ʲ�_���վ�
		,T2.CREDIT_TOT_AST_YDA	  		AS  CREDIT_TOT_AST_YDA        --������ȯ���ʲ�_���վ�
		,T1.CREDIT_TOT_LIAB_MDA	  		AS  CREDIT_TOT_LIAB_MDA       --������ȯ�ܸ�ծ_���վ�
		,T2.CREDIT_TOT_LIAB_YDA	  		AS  CREDIT_TOT_LIAB_YDA       --������ȯ�ܸ�ծ_���վ�
		,T1.APPTBUYB_GUAR_SECMV_MDA	  	AS  APPTBUYB_GUAR_SECMV_MDA   --Լ�����ص���֤ȯ��ֵ_���վ�
		,T2.APPTBUYB_GUAR_SECMV_YDA	  	AS  APPTBUYB_GUAR_SECMV_YDA   --Լ�����ص���֤ȯ��ֵ_���վ�
		,T1.CREDIT_GUAR_SECMV_MDA	  	AS  CREDIT_GUAR_SECMV_MDA     --������ȯ����֤ȯ��ֵ_���վ�
		,T2.CREDIT_GUAR_SECMV_YDA	  	AS  CREDIT_GUAR_SECMV_YDA     --������ȯ����֤ȯ��ֵ_���վ�
	FROM #T_AST_M_BRH_MTH T1,#T_AST_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID 
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_AST_M_EMP(IN @V_DATE INT)
BEGIN

/******************************************************************
  ������: Ա���ʲ����±�
  ��д��: Ҷ���
  ��������: 2018-04-12
  ��飺Ա��ά�ȵĿͻ��ʲ���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
 	DECLARE @V_ACCU_MDAYS INT;		-- ���ۼ�����
 	DECLARE @V_ACCU_YDAYS INT;		-- ���ۼ�����
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_AST_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_YEAR									AS    YEAR   					--��
		,@V_MONTH 									AS    MTH 						--��
		,EMP_ID										AS    EMP_ID                	--Ա������	
		,@V_DATE 									AS 	  OCCUR_DT 					--��������
		,SUM(TOT_AST)/@V_ACCU_MDAYS					AS    TOT_AST_MDA				--���ʲ�_���վ�			
		,SUM(SCDY_MVAL)/@V_ACCU_MDAYS				AS    SCDY_MVAL_MDA				--������ֵ_���վ�			
		,SUM(STKF_MVAL)/@V_ACCU_MDAYS				AS    STKF_MVAL_MDA				--�ɻ���ֵ_���վ�			
		,SUM(A_SHR_MVAL)/@V_ACCU_MDAYS				AS    A_SHR_MVAL_MDA			--A����ֵ_���վ�				
		,SUM(NOTS_MVAL)/@V_ACCU_MDAYS				AS    NOTS_MVAL_MDA				--���۹���ֵ_���վ�			
		,SUM(OFFUND_MVAL)/@V_ACCU_MDAYS				AS    OFFUND_MVAL_MDA			--���ڻ�����ֵ_���վ�				
		,SUM(OPFUND_MVAL)/@V_ACCU_MDAYS				AS    OPFUND_MVAL_MDA			--���������ֵ_���վ�				
		,SUM(SB_MVAL)/@V_ACCU_MDAYS					AS    SB_MVAL_MDA				--������ֵ_���վ�			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_MDAYS			AS    IMGT_PD_MVAL_MDA			--�ʹܲ�Ʒ��ֵ_���վ�				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_MDAYS			AS    BANK_CHRM_MVAL_MDA		--���������ֵ_���վ�					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_MDAYS			AS    SECU_CHRM_MVAL_MDA		--֤ȯ�����ֵ_���վ�					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_MDAYS			AS    PSTK_OPTN_MVAL_MDA		--������Ȩ��ֵ_���վ�					
		,SUM(B_SHR_MVAL)/@V_ACCU_MDAYS				AS    B_SHR_MVAL_MDA			--B����ֵ_���վ�				
		,SUM(OUTMARK_MVAL)/@V_ACCU_MDAYS			AS    OUTMARK_MVAL_MDA			--������ֵ_���վ�				
		,SUM(CPTL_BAL)/@V_ACCU_MDAYS				AS    CPTL_BAL_MDA				--�ʽ����_���վ�			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_MDAYS			AS    NO_ARVD_CPTL_MDA			--δ�����ʽ�_���վ�				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_MDAYS			AS    PTE_FUND_MVAL_MDA			--˽ļ������ֵ_���վ�				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_MDAYS			AS    CPTL_BAL_RMB_MDA			--�ʽ���������_���վ�				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_MDAYS			AS    CPTL_BAL_HKD_MDA			--�ʽ����۱�_���վ�				
		,SUM(CPTL_BAL_USD)/@V_ACCU_MDAYS			AS    CPTL_BAL_USD_MDA			--�ʽ������Ԫ_���վ�				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_MDAYS		AS    FUND_SPACCT_MVAL_MDA		--����ר����ֵ_���վ�					
		,SUM(HGT_MVAL)/@V_ACCU_MDAYS				AS    HGT_MVAL_MDA				--����ͨ��ֵ_���վ�			
		,SUM(SGT_MVAL)/@V_ACCU_MDAYS				AS    SGT_MVAL_MDA				--���ͨ��ֵ_���վ�			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_MDAYS	AS    TOT_AST_CONTAIN_NOTS_MDA	--���ʲ�_�����۹�_���վ�						
		,SUM(BOND_MVAL)/@V_ACCU_MDAYS				AS    BOND_MVAL_MDA				--ծȯ��ֵ_���վ�			
		,SUM(REPO_MVAL)/@V_ACCU_MDAYS				AS    REPO_MVAL_MDA				--�ع���ֵ_���վ�			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_MDAYS			AS    TREA_REPO_MVAL_MDA		--��ծ�ع���ֵ_���վ�					
		,SUM(REPQ_MVAL)/@V_ACCU_MDAYS				AS    REPQ_MVAL_MDA				--���ۻع���ֵ_���վ�			
		,SUM(PO_FUND_MVAL)/@V_ACCU_MDAYS			AS    PO_FUND_MVAL_MDA			--��ļ������ֵ_���վ�				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_MDAYS		AS    APPTBUYB_PLG_MVAL_MDA		--Լ��������Ѻ��ֵ_���վ�					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_MDAYS			AS    OTH_PROD_MVAL_MDA			--������Ʒ��ֵ_���վ�				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_MDAYS			AS    STKT_FUND_MVAL_MDA		--��Ʊ�ͻ�����ֵ_���վ�					
		,SUM(OTH_AST_MVAL)/@V_ACCU_MDAYS			AS    OTH_AST_MVAL_MDA			--�����ʲ���ֵ_���վ�				
		,SUM(CREDIT_MARG)/@V_ACCU_MDAYS				AS    CREDIT_MARG_MDA			--������ȯ��֤��_���վ�				
		,SUM(CREDIT_NET_AST)/@V_ACCU_MDAYS			AS    CREDIT_NET_AST_MDA		--������ȯ���ʲ�_���վ�					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_MDAYS			AS    PROD_TOT_MVAL_MDA			--��Ʒ����ֵ_���վ�				
		,SUM(JQL9_MVAL)/@V_ACCU_MDAYS				AS    JQL9_MVAL_MDA				--������9��ֵ_���վ�			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_MDAYS		AS    STKPLG_GUAR_SECMV_MDA		--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_MDAYS			AS    STKPLG_FIN_BAL_MDA		--��Ʊ��Ѻ�������_���վ�					
		,SUM(APPTBUYB_BAL)/@V_ACCU_MDAYS			AS    APPTBUYB_BAL_MDA			--Լ���������_���վ�				
		,SUM(CRED_MARG)/@V_ACCU_MDAYS				AS    CRED_MARG_MDA				--���ñ�֤��_���վ�			
		,SUM(INTR_LIAB)/@V_ACCU_MDAYS				AS    INTR_LIAB_MDA				--��Ϣ��ծ_���վ�			
		,SUM(FEE_LIAB)/@V_ACCU_MDAYS				AS    FEE_LIAB_MDA				--���ø�ծ_���վ�			
		,SUM(OTHLIAB)/@V_ACCU_MDAYS					AS    OTHLIAB_MDA				--������ծ_���վ�			
		,SUM(FIN_LIAB)/@V_ACCU_MDAYS				AS    FIN_LIAB_MDA				--���ʸ�ծ_���վ�			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_MDAYS			AS    CRDT_STK_LIAB_MDA			--��ȯ��ծ_���վ�				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_MDAYS			AS    CREDIT_TOT_AST_MDA		--������ȯ���ʲ�_���վ�					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_MDAYS			AS    CREDIT_TOT_LIAB_MDA		--������ȯ�ܸ�ծ_���վ�					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_MDAYS		AS    APPTBUYB_GUAR_SECMV_MDA	--Լ�����ص���֤ȯ��ֵ_���վ�						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_MDAYS		AS    CREDIT_GUAR_SECMV_MDA		--������ȯ����֤ȯ��ֵ_���վ�					
	INTO #T_AST_M_EMP_MTH
	FROM DM.T_AST_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

		SELECT 
		 @V_YEAR									AS    YEAR   					--��
		,@V_MONTH 									AS    MTH 						--��
		,EMP_ID										AS    EMP_ID                	--Ա������	
		,@V_DATE 									AS 	  OCCUR_DT 					--��������
		,SUM(TOT_AST)/@V_ACCU_YDAYS					AS    TOT_AST_YDA				--���ʲ�_���վ�			
		,SUM(SCDY_MVAL)/@V_ACCU_YDAYS				AS    SCDY_MVAL_YDA				--������ֵ_���վ�			
		,SUM(STKF_MVAL)/@V_ACCU_YDAYS				AS    STKF_MVAL_YDA				--�ɻ���ֵ_���վ�			
		,SUM(A_SHR_MVAL)/@V_ACCU_YDAYS				AS    A_SHR_MVAL_YDA			--A����ֵ_���վ�				
		,SUM(NOTS_MVAL)/@V_ACCU_YDAYS				AS    NOTS_MVAL_YDA				--���۹���ֵ_���վ�			
		,SUM(OFFUND_MVAL)/@V_ACCU_YDAYS				AS    OFFUND_MVAL_YDA			--���ڻ�����ֵ_���վ�				
		,SUM(OPFUND_MVAL)/@V_ACCU_YDAYS				AS    OPFUND_MVAL_YDA			--���������ֵ_���վ�				
		,SUM(SB_MVAL)/@V_ACCU_YDAYS					AS    SB_MVAL_YDA				--������ֵ_���վ�			
		,SUM(IMGT_PD_MVAL)/@V_ACCU_YDAYS			AS    IMGT_PD_MVAL_YDA			--�ʹܲ�Ʒ��ֵ_���վ�				
		,SUM(BANK_CHRM_MVAL)/@V_ACCU_YDAYS			AS    BANK_CHRM_MVAL_YDA		--���������ֵ_���վ�					
		,SUM(SECU_CHRM_MVAL)/@V_ACCU_YDAYS			AS    SECU_CHRM_MVAL_YDA		--֤ȯ�����ֵ_���վ�					
		,SUM(PSTK_OPTN_MVAL)/@V_ACCU_YDAYS			AS    PSTK_OPTN_MVAL_YDA		--������Ȩ��ֵ_���վ�					
		,SUM(B_SHR_MVAL)/@V_ACCU_YDAYS				AS    B_SHR_MVAL_YDA			--B����ֵ_���վ�				
		,SUM(OUTMARK_MVAL)/@V_ACCU_YDAYS			AS    OUTMARK_MVAL_YDA			--������ֵ_���վ�				
		,SUM(CPTL_BAL)/@V_ACCU_YDAYS				AS    CPTL_BAL_YDA				--�ʽ����_���վ�			
		,SUM(NO_ARVD_CPTL)/@V_ACCU_YDAYS			AS    NO_ARVD_CPTL_YDA			--δ�����ʽ�_���վ�				
		,SUM(PTE_FUND_MVAL)/@V_ACCU_YDAYS			AS    PTE_FUND_MVAL_YDA			--˽ļ������ֵ_���վ�				
		,SUM(CPTL_BAL_RMB)/@V_ACCU_YDAYS			AS    CPTL_BAL_RMB_YDA			--�ʽ���������_���վ�				
		,SUM(CPTL_BAL_HKD)/@V_ACCU_YDAYS			AS    CPTL_BAL_HKD_YDA			--�ʽ����۱�_���վ�				
		,SUM(CPTL_BAL_USD)/@V_ACCU_YDAYS			AS    CPTL_BAL_USD_YDA			--�ʽ������Ԫ_���վ�				
		,SUM(FUND_SPACCT_MVAL)/@V_ACCU_YDAYS		AS    FUND_SPACCT_MVAL_YDA		--����ר����ֵ_���վ�					
		,SUM(HGT_MVAL)/@V_ACCU_YDAYS				AS    HGT_MVAL_YDA				--����ͨ��ֵ_���վ�			
		,SUM(SGT_MVAL)/@V_ACCU_YDAYS				AS    SGT_MVAL_YDA				--���ͨ��ֵ_���վ�			
		,SUM(TOT_AST_CONTAIN_NOTS)/@V_ACCU_YDAYS	AS    TOT_AST_CONTAIN_NOTS_YDA	--���ʲ�_�����۹�_���վ�						
		,SUM(BOND_MVAL)/@V_ACCU_YDAYS				AS    BOND_MVAL_YDA				--ծȯ��ֵ_���վ�			
		,SUM(REPO_MVAL)/@V_ACCU_YDAYS				AS    REPO_MVAL_YDA				--�ع���ֵ_���վ�			
		,SUM(TREA_REPO_MVAL)/@V_ACCU_YDAYS			AS    TREA_REPO_MVAL_YDA		--��ծ�ع���ֵ_���վ�					
		,SUM(REPQ_MVAL)/@V_ACCU_YDAYS				AS    REPQ_MVAL_YDA				--���ۻع���ֵ_���վ�			
		,SUM(PO_FUND_MVAL)/@V_ACCU_YDAYS			AS    PO_FUND_MVAL_YDA			--��ļ������ֵ_���վ�				
		,SUM(APPTBUYB_PLG_MVAL)/@V_ACCU_YDAYS		AS    APPTBUYB_PLG_MVAL_YDA		--Լ��������Ѻ��ֵ_���վ�					
		,SUM(OTH_PROD_MVAL)/@V_ACCU_YDAYS			AS    OTH_PROD_MVAL_YDA			--������Ʒ��ֵ_���վ�				
		,SUM(STKT_FUND_MVAL)/@V_ACCU_YDAYS			AS    STKT_FUND_MVAL_YDA		--��Ʊ�ͻ�����ֵ_���վ�					
		,SUM(OTH_AST_MVAL)/@V_ACCU_YDAYS			AS    OTH_AST_MVAL_YDA			--�����ʲ���ֵ_���վ�				
		,SUM(CREDIT_MARG)/@V_ACCU_YDAYS				AS    CREDIT_MARG_YDA			--������ȯ��֤��_���վ�				
		,SUM(CREDIT_NET_AST)/@V_ACCU_YDAYS			AS    CREDIT_NET_AST_YDA		--������ȯ���ʲ�_���վ�					
		,SUM(PROD_TOT_MVAL)/@V_ACCU_YDAYS			AS    PROD_TOT_MVAL_YDA			--��Ʒ����ֵ_���վ�				
		,SUM(JQL9_MVAL)/@V_ACCU_YDAYS				AS    JQL9_MVAL_YDA				--������9��ֵ_���վ�			
		,SUM(STKPLG_GUAR_SECMV)/@V_ACCU_YDAYS		AS    STKPLG_GUAR_SECMV_YDA		--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�					
		,SUM(STKPLG_FIN_BAL)/@V_ACCU_YDAYS			AS    STKPLG_FIN_BAL_YDA		--��Ʊ��Ѻ�������_���վ�					
		,SUM(APPTBUYB_BAL)/@V_ACCU_YDAYS			AS    APPTBUYB_BAL_YDA			--Լ���������_���վ�				
		,SUM(CRED_MARG)/@V_ACCU_YDAYS				AS    CRED_MARG_YDA				--���ñ�֤��_���վ�			
		,SUM(INTR_LIAB)/@V_ACCU_YDAYS				AS    INTR_LIAB_YDA				--��Ϣ��ծ_���վ�			
		,SUM(FEE_LIAB)/@V_ACCU_YDAYS				AS    FEE_LIAB_YDA				--���ø�ծ_���վ�			
		,SUM(OTHLIAB)/@V_ACCU_YDAYS					AS    OTHLIAB_YDA				--������ծ_���վ�			
		,SUM(FIN_LIAB)/@V_ACCU_YDAYS				AS    FIN_LIAB_YDA				--���ʸ�ծ_���վ�			
		,SUM(CRDT_STK_LIAB)/@V_ACCU_YDAYS			AS    CRDT_STK_LIAB_YDA			--��ȯ��ծ_���վ�				
		,SUM(CREDIT_TOT_AST)/@V_ACCU_YDAYS			AS    CREDIT_TOT_AST_YDA		--������ȯ���ʲ�_���վ�					
		,SUM(CREDIT_TOT_LIAB)/@V_ACCU_YDAYS			AS    CREDIT_TOT_LIAB_YDA		--������ȯ�ܸ�ծ_���վ�					
		,SUM(APPTBUYB_GUAR_SECMV)/@V_ACCU_YDAYS		AS    APPTBUYB_GUAR_SECMV_YDA	--Լ�����ص���֤ȯ��ֵ_���վ�						
		,SUM(CREDIT_GUAR_SECMV)/@V_ACCU_YDAYS		AS    CREDIT_GUAR_SECMV_YDA		--������ȯ����֤ȯ��ֵ_���վ�					
	INTO #T_AST_M_EMP_YEAR
	FROM DM.T_AST_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	--����Ŀ���
	INSERT INTO DM.T_AST_M_EMP(
		 YEAR        					--��
		,MTH         					--��
		,EMP_ID      					--Ա�����
		,OCCUR_DT    					--��������
		,TOT_AST_MDA          			--���ʲ�_���վ�
		,TOT_AST_YDA          			--���ʲ�_���վ�
		,SCDY_MVAL_MDA        			--������ֵ_���վ�
		,SCDY_MVAL_YDA        			--������ֵ_���վ�
		,STKF_MVAL_MDA        			--�ɻ���ֵ_���վ�
		,STKF_MVAL_YDA        			--�ɻ���ֵ_���վ�
		,A_SHR_MVAL_MDA       			--A����ֵ_���վ�
		,A_SHR_MVAL_YDA       			--A����ֵ_���վ�
		,NOTS_MVAL_MDA        			--���۹���ֵ_���վ�
		,NOTS_MVAL_YDA        			--���۹���ֵ_���վ�
		,OFFUND_MVAL_MDA      			--���ڻ�����ֵ_���վ�
		,OFFUND_MVAL_YDA      			--���ڻ�����ֵ_���վ�
		,OPFUND_MVAL_MDA      			--���������ֵ_���վ�
		,OPFUND_MVAL_YDA      			--���������ֵ_���վ�
		,SB_MVAL_MDA          			--������ֵ_���վ�
		,SB_MVAL_YDA          			--������ֵ_���վ�
		,IMGT_PD_MVAL_MDA     			--�ʹܲ�Ʒ��ֵ_���վ�
		,IMGT_PD_MVAL_YDA     			--�ʹܲ�Ʒ��ֵ_���վ�
		,BANK_CHRM_MVAL_YDA   			--���������ֵ_���վ�
		,BANK_CHRM_MVAL_MDA   			--���������ֵ_���վ�
		,SECU_CHRM_MVAL_MDA   			--֤ȯ�����ֵ_���վ�
		,SECU_CHRM_MVAL_YDA   			--֤ȯ�����ֵ_���վ�
		,PSTK_OPTN_MVAL_MDA   			--������Ȩ��ֵ_���վ�
		,PSTK_OPTN_MVAL_YDA   			--������Ȩ��ֵ_���վ�
		,B_SHR_MVAL_MDA       			--B����ֵ_���վ�
		,B_SHR_MVAL_YDA       			--B����ֵ_���վ�
		,OUTMARK_MVAL_MDA     			--������ֵ_���վ�
		,OUTMARK_MVAL_YDA     			--������ֵ_���վ�
		,CPTL_BAL_MDA         			--�ʽ����_���վ�
		,CPTL_BAL_YDA         			--�ʽ����_���վ�
		,NO_ARVD_CPTL_MDA     			--δ�����ʽ�_���վ�
		,NO_ARVD_CPTL_YDA     			--δ�����ʽ�_���վ�
		,PTE_FUND_MVAL_MDA    			--˽ļ������ֵ_���վ�
		,PTE_FUND_MVAL_YDA    			--˽ļ������ֵ_���վ�
		,CPTL_BAL_RMB_MDA     			--�ʽ���������_���վ�
		,CPTL_BAL_RMB_YDA     			--�ʽ���������_���վ�
		,CPTL_BAL_HKD_MDA     			--�ʽ����۱�_���վ�
		,CPTL_BAL_HKD_YDA     			--�ʽ����۱�_���վ�
		,CPTL_BAL_USD_MDA     			--�ʽ������Ԫ_���վ�
		,CPTL_BAL_USD_YDA     			--�ʽ������Ԫ_���վ�
		,FUND_SPACCT_MVAL_MDA 			--����ר����ֵ_���վ�
		,FUND_SPACCT_MVAL_YDA 			--����ר����ֵ_���վ�
		,HGT_MVAL_MDA         			--����ͨ��ֵ_���վ�
		,HGT_MVAL_YDA         			--����ͨ��ֵ_���վ�
		,SGT_MVAL_MDA         			--���ͨ��ֵ_���վ�
		,SGT_MVAL_YDA         			--���ͨ��ֵ_���վ�
		,TOT_AST_CONTAIN_NOTS_MDA		--���ʲ�_�����۹�_���վ�
		,TOT_AST_CONTAIN_NOTS_YDA		--���ʲ�_�����۹�_���վ�
		,BOND_MVAL_MDA        			--ծȯ��ֵ_���վ�
		,BOND_MVAL_YDA        			--ծȯ��ֵ_���վ�
		,REPO_MVAL_MDA        			--�ع���ֵ_���վ�
		,REPO_MVAL_YDA        			--�ع���ֵ_���վ�
		,TREA_REPO_MVAL_MDA   			--��ծ�ع���ֵ_���վ�
		,TREA_REPO_MVAL_YDA   			--��ծ�ع���ֵ_���վ�
		,REPQ_MVAL_MDA        			--���ۻع���ֵ_���վ�
		,REPQ_MVAL_YDA        			--���ۻع���ֵ_���վ�
		,PO_FUND_MVAL_MDA     			--��ļ������ֵ_���վ�
		,PO_FUND_MVAL_YDA     			--��ļ������ֵ_���վ�
		,APPTBUYB_PLG_MVAL_MDA			--Լ��������Ѻ��ֵ_���վ�
		,APPTBUYB_PLG_MVAL_YDA			--Լ��������Ѻ��ֵ_���վ�
		,OTH_PROD_MVAL_MDA    			--������Ʒ��ֵ_���վ�
		,STKT_FUND_MVAL_MDA   			--��Ʊ�ͻ�����ֵ_���վ�
		,OTH_AST_MVAL_MDA     			--�����ʲ���ֵ_���վ�
		,OTH_PROD_MVAL_YDA    			--������Ʒ��ֵ_���վ�
		,APPTBUYB_BAL_YDA     			--Լ���������_���վ�
		,CREDIT_MARG_MDA      			--������ȯ��֤��_���վ�
		,CREDIT_MARG_YDA      			--������ȯ��֤��_���վ�
		,CREDIT_NET_AST_MDA   			--������ȯ���ʲ�_���վ�
		,CREDIT_NET_AST_YDA   			--������ȯ���ʲ�_���վ�
		,PROD_TOT_MVAL_MDA    			--��Ʒ����ֵ_���վ�
		,PROD_TOT_MVAL_YDA    			--��Ʒ����ֵ_���վ�
		,JQL9_MVAL_MDA        			--������9��ֵ_���վ�
		,JQL9_MVAL_YDA        			--������9��ֵ_���վ�
		,STKPLG_GUAR_SECMV_MDA			--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,STKPLG_GUAR_SECMV_YDA			--��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,STKPLG_FIN_BAL_MDA   			--��Ʊ��Ѻ�������_���վ�
		,STKPLG_FIN_BAL_YDA   			--��Ʊ��Ѻ�������_���վ�
		,APPTBUYB_BAL_MDA     			--Լ���������_���վ�
		,CRED_MARG_MDA        			--���ñ�֤��_���վ�
		,CRED_MARG_YDA        			--���ñ�֤��_���վ�
		,INTR_LIAB_MDA        			--��Ϣ��ծ_���վ�
		,INTR_LIAB_YDA        			--��Ϣ��ծ_���վ�
		,FEE_LIAB_MDA         			--���ø�ծ_���վ�
		,FEE_LIAB_YDA         			--���ø�ծ_���վ�
		,OTHLIAB_MDA          			--������ծ_���վ�
		,OTHLIAB_YDA          			--������ծ_���վ�
		,FIN_LIAB_MDA         			--���ʸ�ծ_���վ�
		,CRDT_STK_LIAB_YDA    			--��ȯ��ծ_���վ�
		,CRDT_STK_LIAB_MDA    			--��ȯ��ծ_���վ�
		,FIN_LIAB_YDA         			--���ʸ�ծ_���վ�
		,CREDIT_TOT_AST_MDA   			--������ȯ���ʲ�_���վ�
		,CREDIT_TOT_AST_YDA   			--������ȯ���ʲ�_���վ�
		,CREDIT_TOT_LIAB_MDA  			--������ȯ�ܸ�ծ_���վ�
		,CREDIT_TOT_LIAB_YDA  			--������ȯ�ܸ�ծ_���վ�
		,APPTBUYB_GUAR_SECMV_MDA		--Լ�����ص���֤ȯ��ֵ_���վ�
		,APPTBUYB_GUAR_SECMV_YDA		--Լ�����ص���֤ȯ��ֵ_���վ�
		,CREDIT_GUAR_SECMV_MDA			--������ȯ����֤ȯ��ֵ_���վ�
		,CREDIT_GUAR_SECMV_YDA			--������ȯ����֤ȯ��ֵ_���վ�		
	)		
	SELECT 
		T1.YEAR							AS  YEAR					  --��
		,T1.MTH							AS  MTH						  --��
		,T1.EMP_ID						AS  EMP_ID					  --Ա�����
		,T1.OCCUR_DT					AS  OCCUR_DT				  --��������
		,T1.TOT_AST_MDA	  	  			AS  TOT_AST_MDA               --���ʲ�_���վ�
		,T2.TOT_AST_YDA	  	  			AS  TOT_AST_YDA               --���ʲ�_���վ�
		,T1.SCDY_MVAL_MDA	  			AS  SCDY_MVAL_MDA             --������ֵ_���վ�
		,T2.SCDY_MVAL_YDA	  			AS  SCDY_MVAL_YDA             --������ֵ_���վ�
		,T1.STKF_MVAL_MDA	  			AS  STKF_MVAL_MDA             --�ɻ���ֵ_���վ�
		,T2.STKF_MVAL_YDA	  			AS  STKF_MVAL_YDA             --�ɻ���ֵ_���վ�
		,T1.A_SHR_MVAL_MDA	  			AS  A_SHR_MVAL_MDA            --A����ֵ_���վ�
		,T2.A_SHR_MVAL_YDA	  			AS  A_SHR_MVAL_YDA            --A����ֵ_���վ�
		,T1.NOTS_MVAL_MDA	  			AS  NOTS_MVAL_MDA             --���۹���ֵ_���վ�
		,T2.NOTS_MVAL_YDA	  			AS  NOTS_MVAL_YDA             --���۹���ֵ_���վ�
		,T1.OFFUND_MVAL_MDA	  			AS  OFFUND_MVAL_MDA           --���ڻ�����ֵ_���վ�
		,T2.OFFUND_MVAL_YDA	  			AS  OFFUND_MVAL_YDA           --���ڻ�����ֵ_���վ�
		,T1.OPFUND_MVAL_MDA	  			AS  OPFUND_MVAL_MDA           --���������ֵ_���վ�
		,T2.OPFUND_MVAL_YDA	  			AS  OPFUND_MVAL_YDA           --���������ֵ_���վ�
		,T1.SB_MVAL_MDA	  	  			AS  SB_MVAL_MDA               --������ֵ_���վ�
		,T2.SB_MVAL_YDA	  	  			AS  SB_MVAL_YDA               --������ֵ_���վ�
		,T1.IMGT_PD_MVAL_MDA	  		AS  IMGT_PD_MVAL_MDA          --�ʹܲ�Ʒ��ֵ_���վ�
		,T2.IMGT_PD_MVAL_YDA	  		AS  IMGT_PD_MVAL_YDA          --�ʹܲ�Ʒ��ֵ_���վ�
		,T2.BANK_CHRM_MVAL_YDA	  		AS  BANK_CHRM_MVAL_YDA        --���������ֵ_���վ�
		,T1.BANK_CHRM_MVAL_MDA	  		AS  BANK_CHRM_MVAL_MDA        --���������ֵ_���վ�
		,T1.SECU_CHRM_MVAL_MDA	  		AS  SECU_CHRM_MVAL_MDA        --֤ȯ�����ֵ_���վ�
		,T2.SECU_CHRM_MVAL_YDA	  		AS  SECU_CHRM_MVAL_YDA        --֤ȯ�����ֵ_���վ�
		,T1.PSTK_OPTN_MVAL_MDA	  		AS  PSTK_OPTN_MVAL_MDA        --������Ȩ��ֵ_���վ�
		,T2.PSTK_OPTN_MVAL_YDA	  		AS  PSTK_OPTN_MVAL_YDA        --������Ȩ��ֵ_���վ�
		,T1.B_SHR_MVAL_MDA	  			AS  B_SHR_MVAL_MDA            --B����ֵ_���վ�
		,T2.B_SHR_MVAL_YDA	  			AS  B_SHR_MVAL_YDA            --B����ֵ_���վ�
		,T1.OUTMARK_MVAL_MDA	  		AS  OUTMARK_MVAL_MDA          --������ֵ_���վ�
		,T2.OUTMARK_MVAL_YDA	  		AS  OUTMARK_MVAL_YDA          --������ֵ_���վ�
		,T1.CPTL_BAL_MDA	  			AS  CPTL_BAL_MDA              --�ʽ����_���վ�
		,T2.CPTL_BAL_YDA	  			AS  CPTL_BAL_YDA              --�ʽ����_���վ�
		,T1.NO_ARVD_CPTL_MDA	  		AS  NO_ARVD_CPTL_MDA          --δ�����ʽ�_���վ�
		,T2.NO_ARVD_CPTL_YDA	  		AS  NO_ARVD_CPTL_YDA          --δ�����ʽ�_���վ�
		,T1.PTE_FUND_MVAL_MDA	  		AS  PTE_FUND_MVAL_MDA         --˽ļ������ֵ_���վ�
		,T2.PTE_FUND_MVAL_YDA	  		AS  PTE_FUND_MVAL_YDA         --˽ļ������ֵ_���վ�
		,T1.CPTL_BAL_RMB_MDA	  		AS  CPTL_BAL_RMB_MDA          --�ʽ���������_���վ�
		,T2.CPTL_BAL_RMB_YDA	  		AS  CPTL_BAL_RMB_YDA          --�ʽ���������_���վ�
		,T1.CPTL_BAL_HKD_MDA	  		AS  CPTL_BAL_HKD_MDA          --�ʽ����۱�_���վ�
		,T2.CPTL_BAL_HKD_YDA	  		AS  CPTL_BAL_HKD_YDA          --�ʽ����۱�_���վ�
		,T1.CPTL_BAL_USD_MDA	  		AS  CPTL_BAL_USD_MDA          --�ʽ������Ԫ_���վ�
		,T2.CPTL_BAL_USD_YDA	  		AS  CPTL_BAL_USD_YDA          --�ʽ������Ԫ_���վ�
		,T1.FUND_SPACCT_MVAL_MDA	  	AS  FUND_SPACCT_MVAL_MDA      --����ר����ֵ_���վ�
		,T2.FUND_SPACCT_MVAL_YDA	  	AS  FUND_SPACCT_MVAL_YDA      --����ר����ֵ_���վ�
		,T1.HGT_MVAL_MDA	  			AS  HGT_MVAL_MDA              --����ͨ��ֵ_���վ�
		,T2.HGT_MVAL_YDA	  			AS  HGT_MVAL_YDA              --����ͨ��ֵ_���վ�
		,T1.SGT_MVAL_MDA	  			AS  SGT_MVAL_MDA              --���ͨ��ֵ_���վ�
		,T2.SGT_MVAL_YDA	  			AS  SGT_MVAL_YDA              --���ͨ��ֵ_���վ�
		,T1.TOT_AST_CONTAIN_NOTS_MDA	AS  TOT_AST_CONTAIN_NOTS_MDA  --���ʲ�_�����۹�_���վ�
		,T2.TOT_AST_CONTAIN_NOTS_YDA	AS  TOT_AST_CONTAIN_NOTS_YDA  --���ʲ�_�����۹�_���վ�
		,T1.BOND_MVAL_MDA	  			AS  BOND_MVAL_MDA             --ծȯ��ֵ_���վ�
		,T2.BOND_MVAL_YDA	  			AS  BOND_MVAL_YDA             --ծȯ��ֵ_���վ�
		,T1.REPO_MVAL_MDA	  			AS  REPO_MVAL_MDA             --�ع���ֵ_���վ�
		,T2.REPO_MVAL_YDA	  			AS  REPO_MVAL_YDA             --�ع���ֵ_���վ�
		,T1.TREA_REPO_MVAL_MDA	  		AS  TREA_REPO_MVAL_MDA        --��ծ�ع���ֵ_���վ�
		,T2.TREA_REPO_MVAL_YDA	  		AS  TREA_REPO_MVAL_YDA        --��ծ�ع���ֵ_���վ�
		,T1.REPQ_MVAL_MDA	  			AS  REPQ_MVAL_MDA             --���ۻع���ֵ_���վ�
		,T2.REPQ_MVAL_YDA	  			AS  REPQ_MVAL_YDA             --���ۻع���ֵ_���վ�
		,T1.PO_FUND_MVAL_MDA	  		AS  PO_FUND_MVAL_MDA          --��ļ������ֵ_���վ�
		,T2.PO_FUND_MVAL_YDA	  		AS  PO_FUND_MVAL_YDA          --��ļ������ֵ_���վ�
		,T1.APPTBUYB_PLG_MVAL_MDA	  	AS  APPTBUYB_PLG_MVAL_MDA     --Լ��������Ѻ��ֵ_���վ�
		,T2.APPTBUYB_PLG_MVAL_YDA	  	AS  APPTBUYB_PLG_MVAL_YDA     --Լ��������Ѻ��ֵ_���վ�
		,T1.OTH_PROD_MVAL_MDA	  		AS  OTH_PROD_MVAL_MDA         --������Ʒ��ֵ_���վ�
		,T1.STKT_FUND_MVAL_MDA	  		AS  STKT_FUND_MVAL_MDA        --��Ʊ�ͻ�����ֵ_���վ�
		,T1.OTH_AST_MVAL_MDA	  		AS  OTH_AST_MVAL_MDA          --�����ʲ���ֵ_���վ�
		,T2.OTH_PROD_MVAL_YDA	  		AS  OTH_PROD_MVAL_YDA         --������Ʒ��ֵ_���վ�
		,T2.APPTBUYB_BAL_YDA	  		AS  APPTBUYB_BAL_YDA          --Լ���������_���վ�
		,T1.CREDIT_MARG_MDA	  			AS  CREDIT_MARG_MDA           --������ȯ��֤��_���վ�
		,T2.CREDIT_MARG_YDA	  			AS  CREDIT_MARG_YDA           --������ȯ��֤��_���վ�
		,T1.CREDIT_NET_AST_MDA	  		AS  CREDIT_NET_AST_MDA        --������ȯ���ʲ�_���վ�
		,T2.CREDIT_NET_AST_YDA	  		AS  CREDIT_NET_AST_YDA        --������ȯ���ʲ�_���վ�
		,T1.PROD_TOT_MVAL_MDA	  		AS  PROD_TOT_MVAL_MDA         --��Ʒ����ֵ_���վ�
		,T2.PROD_TOT_MVAL_YDA	  		AS  PROD_TOT_MVAL_YDA         --��Ʒ����ֵ_���վ�
		,T1.JQL9_MVAL_MDA	  			AS  JQL9_MVAL_MDA             --������9��ֵ_���վ�
		,T2.JQL9_MVAL_YDA	  			AS  JQL9_MVAL_YDA             --������9��ֵ_���վ�
		,T1.STKPLG_GUAR_SECMV_MDA	  	AS  STKPLG_GUAR_SECMV_MDA     --��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,T2.STKPLG_GUAR_SECMV_YDA	  	AS  STKPLG_GUAR_SECMV_YDA     --��Ʊ��Ѻ����֤ȯ��ֵ_���վ�
		,T1.STKPLG_FIN_BAL_MDA	  		AS  STKPLG_FIN_BAL_MDA        --��Ʊ��Ѻ�������_���վ�
		,T2.STKPLG_FIN_BAL_YDA	  		AS  STKPLG_FIN_BAL_YDA        --��Ʊ��Ѻ�������_���վ�
		,T1.APPTBUYB_BAL_MDA	  		AS  APPTBUYB_BAL_MDA          --Լ���������_���վ�
		,T1.CRED_MARG_MDA	  			AS  CRED_MARG_MDA             --���ñ�֤��_���վ�
		,T2.CRED_MARG_YDA	  			AS  CRED_MARG_YDA             --���ñ�֤��_���վ�
		,T1.INTR_LIAB_MDA	  			AS  INTR_LIAB_MDA             --��Ϣ��ծ_���վ�
		,T2.INTR_LIAB_YDA	  			AS  INTR_LIAB_YDA             --��Ϣ��ծ_���վ�
		,T1.FEE_LIAB_MDA	  			AS  FEE_LIAB_MDA              --���ø�ծ_���վ�
		,T2.FEE_LIAB_YDA	  			AS  FEE_LIAB_YDA              --���ø�ծ_���վ�
		,T1.OTHLIAB_MDA	  				AS  OTHLIAB_MDA               --������ծ_���վ�
		,T2.OTHLIAB_YDA	  				AS  OTHLIAB_YDA               --������ծ_���վ�
		,T1.FIN_LIAB_MDA	  			AS  FIN_LIAB_MDA              --���ʸ�ծ_���վ�
		,T2.CRDT_STK_LIAB_YDA	  		AS  CRDT_STK_LIAB_YDA         --��ȯ��ծ_���վ�
		,T1.CRDT_STK_LIAB_MDA	  		AS  CRDT_STK_LIAB_MDA         --��ȯ��ծ_���վ�
		,T2.FIN_LIAB_YDA	  			AS  FIN_LIAB_YDA              --���ʸ�ծ_���վ�
		,T1.CREDIT_TOT_AST_MDA	  		AS  CREDIT_TOT_AST_MDA        --������ȯ���ʲ�_���վ�
		,T2.CREDIT_TOT_AST_YDA	  		AS  CREDIT_TOT_AST_YDA        --������ȯ���ʲ�_���վ�
		,T1.CREDIT_TOT_LIAB_MDA	  		AS  CREDIT_TOT_LIAB_MDA       --������ȯ�ܸ�ծ_���վ�
		,T2.CREDIT_TOT_LIAB_YDA	  		AS  CREDIT_TOT_LIAB_YDA       --������ȯ�ܸ�ծ_���վ�
		,T1.APPTBUYB_GUAR_SECMV_MDA	  	AS  APPTBUYB_GUAR_SECMV_MDA   --Լ�����ص���֤ȯ��ֵ_���վ�
		,T2.APPTBUYB_GUAR_SECMV_YDA	  	AS  APPTBUYB_GUAR_SECMV_YDA   --Լ�����ص���֤ȯ��ֵ_���վ�
		,T1.CREDIT_GUAR_SECMV_MDA	  	AS  CREDIT_GUAR_SECMV_MDA     --������ȯ����֤ȯ��ֵ_���վ�
		,T2.CREDIT_GUAR_SECMV_YDA	  	AS  CREDIT_GUAR_SECMV_YDA     --������ȯ����֤ȯ��ֵ_���վ�
	FROM #T_AST_M_EMP_MTH T1,#T_AST_M_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID 
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.p_ast_odi(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  ������: �ͻ���ͨ�ʲ���
  ��д��: rengz
  ��������: 2017-11-16
  ��飺���������ü�����Ʒ�ȵ���ͨ�˻��ʲ����ո���
       ��Ҫָ��ο�ȫ��ͼ�ձ��ո���dba.tmp_ddw_khqjt_d_d���д���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
             2017-12-06               rengz              �޶�˽ļ���𣬸��ݹ�̨��Ʒ����з��� dba.t_edw_uf2_prodcode where  prodcode_type='j'
             2017-12-20               rengz              ���ӹ�ļ������ֵ
             2018-1-31                rengz              ���ݾ���ҵ���ܲ�Ҫ������ �ɻ���ֵ��������Ʒ��ֵ��δ���û���������Ϊ�գ��������ʲ���Լ��������Ѻ��ֵ����ĩ�ʲ����ֶ�  
             2018-4-12                rengz              1�����ӹ�Ʊ��Ѻ��ծ
                                                         2��δ���˽��������Ʊ��Ѻ��ծ
                                                         3�������ʲ�����Ϊ��TOT_AST_N_CONTAIN_NOTS�����ʲ�_�������۹ɣ�+��Ʊ��Ѻ��ծ
                                                         4����ĩ�ʲ�final_ast��Ϊ����ҵ���ܲ�Ҫ������ʲ�=�ɻ���ֵ+�ʽ����+ծȯ��ֵ+�ع���ֵ+��Ʒ����ֵ+�����ʲ�+δ�����ʽ�+��Ʊ��Ѻ��ծ+������ȯ���ʲ�+Լ��������Ѻ��ֵ+���۹���ֵ+������Ȩ��ֵ
  *********************************************************************/
  
    --declare @v_bin_date         numeric(8); 
    declare @v_bin_mth          varchar(2);
    declare @v_bin_year         varchar(4);   
    declare @v_bin_20avg_start  numeric(8,0);---���20�������տ�ʼ����
    declare @v_bin_20avg_end    numeric(8,0);---���20�������ս�������

	set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date =@v_bin_date;

    --������������
    set @v_bin_mth  =substr(convert(varchar,@v_bin_date),5,2);
    set @v_bin_year =substr(convert(varchar,@v_bin_date),1,4);
    set @v_bin_20avg_start =(select b.rq
                             from    dba.t_ddw_d_rq      a
                             left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=21      --(T-21��)���� t-2��ǰ20��
                             where a.rq=@v_bin_date);
    set @v_bin_20avg_end =(select b.rq
                            from    dba.t_ddw_d_rq      a
                            left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=2       --(T-2��)����t-2��
                            where a.rq=@v_bin_date);	
    commit;

   
    --ɾ������������
    delete from dm.t_ast_odi where load_dt =@v_bin_date;
    commit;

    ---��������ͻ���Ϣ
    insert into dm.t_ast_odi(
                            OCCUR_DT,               --��ϴ���� 
                            CUST_ID,                --�ͻ�����
                            main_cptl_acct,         --���ʽ��˺�
                            TOT_AST_N_CONTAIN_NOTS, --���ʲ�_�������۹�
                            RCT_20D_DA_AST,	        --��20���վ��ʲ�
                            SCDY_MVAL,	            --������ֵ
                            NO_ARVD_CPTL,	        --δ�����ʽ�
                            CPTL_BAL,	            --�ʽ����
                            CPTL_BAL_RMB,	        --�ʽ���������
                            CPTL_BAL_HKD,	        --�ʽ����۱�
                            CPTL_BAL_USD,	        --�ʽ������Ԫ 
                            HGT_MVAL,	            --����ͨ��ֵ
                            SGT_MVAL,	            --���ͨ��ֵ
                            PSTK_OPTN_MVAL,	        --������Ȩ��ֵ
                            IMGT_PD_MVAL,	        --�ʹܲ�Ʒ��ֵ
                            BANK_CHRM_MVAL,	        --���������ֵ
                            SECU_CHRM_MVAL,         --֤ȯ�����ֵ 
                            --FUND_SPACCT_MVAL,     --����ר����ֵ
                            STKT_FUND_MVAL,         --��Ʊ�ͻ�����ֵ
                            --STKPLG_LIAB,            --��Ʊ��Ѻ��ծ
                            LOAD_DT)
    select rq
       ,client_id
       ,fund_account
       ,zzc         --- �������ʽ���δ�����ʽ𡢶�����ֵ��������ֵ���ʹܲ�Ʒ��ֵ��������ȯ���ʲ���Լ�����ؾ��ʲ��� ������Ƴ��н�֤ȯ��Ʋ�Ʒ�� 
       ,zzc_20rj    --- 20�վ����ʲ���������
       ,ejsz
       ,wdzzj
       ,zjye
       ,zjye_rmb
       ,zjye_gb
       ,zjye_my
       ,hgtsz_rmb   ---����ͨ��ֵ
       ,sgtsz_rmb   ---���ͨ��ֵ
       ,qqsz        ---��Ȩ��ֵ
       ,zgcpsz      ---�ʹܲ�Ʒ��ֵ
       ,yhlccyje    ---������Ƴ��н��
       ,zqlccpe     ---֤ȯ��Ʋ�Ʒ�� 
       --,jjzhsz    ---����ר����ֵ
       ,gjsz        ---��Ʊ�ͻ�����ֵ
       ,rq as load_dt
    from dba.t_ddw_client_index_high_priority
    where rq=@v_bin_date
     and jgbh_hs not in  ('5','55','51','44','9999');  ---modify by rengz 20180212 �޳��ܲ��ͻ�
  commit;

------------------------
  -- ������ֵ
------------------------

        select a.zjzh,
               case when a.yrdh_flag = '0' then 1
                    when a.yrdh_flag = '1' and a.tn_sz > 0 then a.bzjzh_tn_sz / a.tn_sz else 1 / b.cnt
               end                      as tn_sz_fencheng,
               tw_sz * tn_sz_fencheng   as tw_zc_20avg,----�����ʲ�
               d.avg_zzc_20d            as tn_zc_20avg ----�����ʲ�
          into #t_twzc
          from dba.t_index_assetinfo_v2 a
        -- һ�˶໧����
          left join (select id_no, count(distinct zjzh) as cnt
                       from dba.t_index_assetinfo_v2
                      where init_date = @v_bin_date
                        and yrdh_flag = '1'
                      group by id_no) b --init_date         --update
            on a.id_no = b.id_no
        -- ����20�վ����ʲ����� �����ʲ�δ������
          left join (select zjzh, sum(zzc) / 20         as avg_zzc_20d
                       from dba.tmp_ddw_khqjt_d_d
                      where rq >= @v_bin_20avg_start
                        and rq <= @v_bin_20avg_end
                      group by zjzh) d
            on a.zjzh = d.zjzh
         where a.init_date = @v_bin_date;
      
      commit;

    update dm.t_ast_odi 
       set OUTMARK_MVAL = coalesce(tw_zc_20avg, 0) 
    from dm.t_ast_odi  a 
    left join #t_twzc  b on a.main_cptl_acct = b.zjzh  
     where 
           a.occur_dt  = @v_bin_date;
    commit;

------------------------
  -- �ɻ���ֵ ������ֵ A����ĩ��ֵ B����ĩ��ֵ ˽ļ������ֵ
------------------------
  select 
       zjzh
       ,sum(case when zqfz1dm='11' and b.sclx in ('01','02') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agsz     ---A����ĩ��ֵ
	   ,sum(case when zqfz1dm='12' and b.sclx in ('03','04') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bgsz     ---B����ĩ��ֵ 
       ,sum(case when a.zqlx in ('10', 'A1', -- A��      ���� ���ͨ������ͨ������
                                 '17', '18', -- B��
                                 '11',       -- ���ʽ����
                                 '1A',       -- ETF
                                 '74', '75', -- Ȩ֤
                                 '19'        -- LOF --�����ڿ���
                                ) then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                   as gjsz            ---�ɻ���ֵ

       ,sum(case when zqfz1dm='11'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agqmsz          ---A����ĩ��ֵ_˽�� ���� ���ͨ������ͨ 
       ,sum(case when zqfz1dm in('20','22')then JRCCSZ*c.turn_rmb/turn_rate else 0  end )        as sbsz            ---������ֵ
       ,sum(case when zqfz1dm='14'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as fbsjjqmsz       ---���ʽ������ĩ��ֵ_˽��  
       ,sum(case when zqfz1dm='18'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as etfqmsz         ---ETF��ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='19'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as lofqmsz         ---LOF��ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='25'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as cnkjqmsz        ---���ڿ�����ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='30'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bzqqmsz         ---��׼ȯ��ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='21'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as hgqmsz          ---�ع���ĩ��ֵ_˽�� 
  into #t_sz
  from dba.T_DDW_F00_KHMRCPYKHZ_D                     a
  left join dba.T_DDW_D_ZQFZ                          b on a.zqlx=b.zqlx AND a.sclx=b.sclx
  left join  dba.T_EDW_T06_YEAR_EXCHANGE_RATE         c on a.tjrq between c.star_dt and c.end_dt 
                                                       and c.curr_type_cd = case
                                                                            when a.zqlx = '18' and a.sclx = '05' then  'USD'
                                                                            when a.zqlx = '17'                   then 'USD'
                                                                            when a.zqlx = '18'                   then  'HKD'
                                                                            else  'CNY'
                                                                            end
  left join dba.t_ddw_d_jj                            d on a.zqdm=d.jjdm and d.nian=@v_bin_year and d.yue=@v_bin_mth
  where a.load_dt= @v_bin_date
    and a.sclx in( '01','02','03','04','05','0G','0S')
  group by zjzh; 

  commit;


  update dm.t_ast_odi 
       set  
           STKF_MVAL     = coalesce(gjsz, 0), --�ɻ���ֵ 
           SB_MVAL       = coalesce(sbsz, 0), --������ֵ 
           A_SHR_MVAL    = coalesce(agsz, 0), --A����ֵ
           B_SHR_MVAL    = coalesce(bgsz, 0)  --B����ֵ
    from dm.t_ast_odi a
    left join   #t_sz b on a.main_cptl_acct = b.zjzh
     where  a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- ��ļ����˽ļ������ֵ
------------------------
    select a.zjzh
          ,SUM(case when b.lx = '��ļ-������' then a.qmsz_cw_d else 0 end)                                                                          as hjsz         -- ������ֵ
          ,SUM(case when b.lx in( '��ļ-��Ʊ��','δ����') or b.lx is null then a.qmsz_cw_d else 0 end)                                              as gjsz         -- �ɻ���ֵ(����δ����)
          ,SUM(case when b.lx = '��ļ-ծȯ��' then a.qmsz_cw_d else 0 end)                                                                          as zjsz         -- ծ����ֵ
          ,SUM(case when b.lx in ('����ר��-��Ʊ��','����ר��-ծȯ��')  then a.qmsz_cw_d else 0 end)                                                as jjzhsz       -- ����ר����ֵ
          ,SUM(case when b.lx in( '��ļ-��Ʊ��','��ļ-ծȯ��','��ļ-������','����ר��','δ����') or b.lx is null then a.qmsz_cw_d else 0 end)       as kjsz         -- ������ֵ(�����ʹܲ�Ʒ��ֵ)
          ,SUM(case when b.lx in( '�������-��Ʊ��','�������-ծȯ��','�������-������') then a.qmsz_cw_d else 0 end)                               as zgcpsz       -- �ʹܲ�Ʒ��ֵ
          ,SUM(case when b.lx in( '�������-ծȯ��','�������-������') then a.qmsz_cw_d else 0 end)                                                 as gdsylzgcpsz  -- �̶��������ʹܲ�Ʒ��ֵ
          ,SUM(case when b.lx in( '��ļ-��Ʊ��','��ļ-ծȯ��','��ļ-������') then a.qmsz_cw_d else 0 end)                                           as gmsz         -- ��ļ������ֵ
          ,SUM(case when b.lx in( '˽ļ-��Ʊ��','˽ļ-ծȯ��') then a.qmsz_cw_d else 0 end)                                                         as smsz         -- ˽ļ������ֵ 
          ,SUM(case when b.lx ='δ����' or b.lx is null  then a.qmsz_cw_d else 0 end)                                                               as qtcpsz       -- ������Ʒ��ֵ 
          ,SUM(case when b.lx in( '��ļ-������') then a.qmsz_cn_d else 0 end)                                                                       as cnhbxjjsz    -- ���ڻ����ͻ�����ֵ_��ĩ   
          ,SUM(a.qmsz_cw_d)                                                                                                                         as cwjjsz       -- �����������ֵ
    into #t_sz_jj   
    --select *
      from dba.t_ddw_xy_jjzb_d as a
      left outer join (select jjdm, jjlb as lx                           -----��ͻ�ȫ��ͼ���в��죬ȫ��ͼֱ��ʹ��lx�ֶΣ�����ʵ�ʰ�����˽ļ����
                         from dba.t_ddw_d_jj
                        where nian || yue =
                              (select MAX(nian || yue)
                                 from dba.t_ddw_d_jj
                                where nian || yue <
                                      convert(varchar(6), FLOOR(@v_bin_date / 100)))) as b
        on a.jjdm = b.jjdm
     where a.rq = @v_bin_date
     group by a.zjzh;

  commit;

 
  update dm.t_ast_odi  
       set 
           PTE_FUND_MVAL = coalesce(smsz, 0),               --˽ļ������ֵ
           PO_FUND_MVAL  = coalesce(gmsz, 0),               --��ļ������ֵ 
           FUND_SPACCT_MVAL = coalesce(jjzhsz, 0),          --����ר����ֵ
           OTH_PROD_MVAL    = coalesce(qtcpsz, 0),          --������Ʒ��ֵ                                 
           PROD_TOT_MVAL    = coalesce(cwjjsz, 0) + BANK_CHRM_MVAL+	        --���������ֵ
                                                  SECU_CHRM_MVAL            --֤ȯ�����ֵ      
                                                            --��Ʒ����ֵ      
    from       dm.t_ast_odi a
    left join  #t_sz_jj     b on a.main_cptl_acct = b.zjzh
     where 
        a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- ���۹���ֵ
------------------------
     select b.fund_acct as zjzh,
           SUM(a.sec_bal * COALESCE(c.trad_price, 0)) as xsgsz
      into #t_xsgsz
      from dba.t_edw_tr_sec_bal_xslt as a
      left outer join dba.t_edw_t01_stock_acct as b on a.inv_acc = b.stock_acct and a.mkt_code = b.market_type_cd and b.market_type_cd <> '05'
      left outer join dba.t_edw_t06_stock_maket_info as c on a.load_dt = c.trad_dt and a.mkt_code = c.market_type_cd and a.sec_code = c.stock_cd and c.stock_type_cd not in ('19', '12')
     where a.load_dt = @v_bin_date
     group by b.fund_acct;

    commit;   

    update dm.t_ast_odi  
       set NOTS_MVAL = coalesce(xsgsz, 0)                --���۹���ֵ
    from dm.t_ast_odi  a
    left join #t_xsgsz b on convert(varchar,a.main_cptl_acct) = convert(varchar,b.zjzh)
     where  a.occur_dt = @v_bin_date;

    commit;
    ------------------------
    -- ���ʲ� �����۹�
    ------------------------
    update dm.t_ast_odi a
       set TOT_AST_CONTAIN_NOTS = coalesce(TOT_AST_N_CONTAIN_NOTS, 0) +
                                  coalesce(NOTS_MVAL, 0) ---���ʲ�_�����۹�
     where a.occur_dt = @v_bin_date;
    commit;

    ------------------------
    -- ���� ���������ֵ
    ------------------------
    select zjzh
           ,sum(qmsz_cw_d) as cwsz ---���������ֵ
           ,sum(qmsz_cn_d) as cnsz ---���ڻ�����ֵ
      into #t_jjsz
      from dba.t_ddw_xy_jjzb_d a
     where rq = @v_bin_date
    group by zjzh;

    update dm.t_ast_odi a
       set OFFUND_MVAL = coalesce(cnsz, 0), --���ڻ�����ֵ
           OPFUND_MVAL = coalesce(cwsz, 0)  --���������ֵ
    from dm.t_ast_odi a
    left join #t_jjsz b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;
------------------------
  -- �ͷ����ʲ�
------------------------
-- �ͷ����ʲ��ܼ� = ������ֵ + ծ����ֵ + �ʽ���� + ���ۻع���ֵ + ծȯ��ع���ֵ 
--                    + �̶��������ʹܲ�Ʒ��ֵ + ��ծ��ֵ + ��ҵծ��ֵ + ��תծ��ֵ

    select a.fund_Account as zjzh,
           coalesce(a.hjsz, 0) + coalesce(a.zjsz, 0) + coalesce(a.zjye, 0) +
           coalesce(b.bjhgsz, 0) + coalesce(c.zqnhgsz, 0) +
           coalesce(a.gdsylzgcpsz, 0) + coalesce(d.gzsz, 0) +
           coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0)                       as dfxzczj,
           coalesce(d.gzsz, 0) + coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0) as zqsz,
           coalesce(b.bjhgsz,0)                                              as bjhgsz,
           coalesce(c.zqnhgsz,0)                                             as zqnhgsz
      into #t_dfxzc
      from dba.t_ddw_client_index_high_priority a
      left join (select zjzh, cyje_br as bjhgsz       -- ���ۻع���ֵ
                   from dba.t_ddw_bjhg_d
                  where rq = @v_bin_date) b
        on a.fund_Account = b.zjzh
      left join (select zjzh, SUM(jrccsz) as zqnhgsz -- ծȯ��ع���ֵ
                   from dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx = '27'
                    and zqdm not like '205%'         -- �޳����ۻع�
                  group by zjzh) c
        on a.fund_Account = c.zjzh
      left join (select zjzh,
                        SUM(case when zqlx = '12' then jrccsz else 0 end) as gzsz,  -- ��ծ��ֵ  
                        SUM(case when zqlx = '13' then jrccsz else 0 end) as qyzsz, -- ��ҵծ��ֵ
                        SUM(case when zqlx = '14' then jrccsz else 0 end) as kzzsz  -- ��תծ��ֵ
                   from  dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx in ('12', '13', '14')
                  group by zjzh) d
        on a.fund_Account = d.zjzh
     where a.rq = @v_bin_date;

    update dm.t_ast_odi 
       set LOW_RISK_TOT_AST= coalesce(dfxzczj, 0),                      ---  �ͷ����ʲ�
           OVERSEA_TOT_AST = 0,                                         ---  �������ʲ�
           FUTR_TOT_AST    = 0,                                         ---  �ڻ����ʲ�
           BOND_MVAL       =coalesce(b.zqsz,0),                         ---  ծȯ��ֵ
           REPO_MVAL       =coalesce(b.bjhgsz,0)+coalesce(b.zqnhgsz,0), ---  �ع���ֵ
           TREA_REPO_MVAL  =coalesce(b.zqnhgsz,0),                      ---  ��ծ�ع���ֵ
           REPQ_MVAL       =coalesce(b.bjhgsz,0)                        ---  ���ۻع���ֵ
    from dm.t_ast_odi   a  
    left join  #t_dfxzc b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
    ------------------------
    -- ����ҵ�����󣺹�Ʊ��Ѻ��ծ
    ------------------------

    update dm.t_ast_odi 
       set STKPLG_LIAB= coalesce(fz, 0)                       ---  ��Ʊ��Ѻ��ծ 
    from dm.t_ast_odi            a  
    left join dba.t_ddw_gpzyhg_d b on a.main_cptl_acct = b.zjzh and b.rq=a.occur_dt
     where 
         a.occur_dt = @v_bin_date;

    commit;

 
    ------------------------
    -- ����ҵ����������Լ��������Ѻ�ʲ���ֵ
    ------------------------

    select a.client_id,
           sum(a.entrust_amount * b.trad_price )        as ��Ѻ�ʲ�_��ĩ_ԭʼ ----  Լ��������Ѻ��ֵ
    into #t_arpsz
      from dba.t_edw_arpcontract               a
      left join dba.t_edw_t06_stock_maket_info b
        on a.stock_code = b.stock_cd and '0' || a.exchange_type = b.market_type_cd and a.load_dt = b.trad_dt and b.stock_type_cd in ('10', 'A1')
     where a.load_dt = @v_bin_date
       and a.contract_status in ('2', '3', '7') -- 2-��ǩԼ, 3-�ѽ��г�ʼ����, 7 -�ѹ���
     group by a.client_id;
   
    commit;
 
    update dm.t_ast_odi 
       set APPTBUYB_PLG_MVAL = coalesce(��Ѻ�ʲ�_��ĩ_ԭʼ, 0) --Լ��������Ѻ��ֵ
    from dm.t_ast_odi a
    left join #t_arpsz b on a.cust_id = b.client_id
     where 
         a.occur_dt = @v_bin_date;

    commit;
    
    ------------------------
    -- ����ҵ���������������ʲ���ֵ
    ------------------------

  update dm.t_ast_odi 
       set   OTH_AST_MVAL =  
                        coalesce(b.zzc,0)                                --- �ֿ�ȫ��ͼ���ʲ�
                        + coalesce(b.rzrqzfz,0)                          --- ������ȯ�ܸ�ծ
                        + coalesce(b.ydghfz,0)                           --- Լ�����ظ�ծ
                        - coalesce(STKF_MVAL,0)                          --- �ɻ���ֵ
                        - coalesce(CPTL_BAL ,0)                          --- ��֤��/�ʽ����
                        - coalesce(BOND_MVAL,0)                          --- ծȯ��ֵ
                        - (coalesce(c.bzqqmsz,0)+ coalesce(c.hgqmsz,0))  --- �ع���ֵ--˽�� ��׼ȯ��ֵ
                        - coalesce(PROD_TOT_MVAL,0)                      --- ��Ʒ����ֵ
                        - coalesce(APPTBUYB_PLG_MVAL,0)                  --- Լ��������Ѻ��ֵ
                        - coalesce(b.rzrqzzc,0)                          --- �����˻����ʲ�
                        - coalesce(NO_ARVD_CPTL,0) 	                     --- δ�����ʽ�
    from dm.t_ast_odi   a
    left join dba.t_ddw_client_index_high_priority b on a.main_cptl_acct = b.fund_account and b.rq=a.occur_dt
    left join #t_sz                                c on a.main_cptl_acct = c.zjzh
     where 
         a.occur_dt = @v_bin_date;
    commit;
 

 ------------------------
    -- ����ҵ��������ĩ�ʲ�����Ϊ����ҵ���ܲ�Ҫ������ʲ�=�ɻ���ֵ+�ʽ����+ծȯ��ֵ+�ع���ֵ+��Ʒ����ֵ+�����ʲ�+δ�����ʽ�+��Ʊ��Ѻ��ծ+������ȯ���ʲ�+Լ��������Ѻ��ֵ+���۹���ֵ+������Ȩ��ֵ��
 ------------------------

    update dm.t_ast_odi
       set FINAL_AST = coalesce(STKF_MVAL, 0)           --�ɻ���ֵ
                       + coalesce(CPTL_BAL, 0)          --�ʽ����
                       + coalesce(BOND_MVAL, 0)         --ծȯ��ֵ
                       + coalesce(REPO_MVAL, 0)         --�ع���ֵ
                       + coalesce(PROD_TOT_MVAL, 0)     --��Ʒ����ֵ
                       + coalesce(OTH_AST_MVAL, 0)      --�����ʲ� 
                       + coalesce(NO_ARVD_CPTL, 0)      --δ�����ʽ� 
                       + coalesce(STKPLG_LIAB, 0)       --��Ʊ��Ѻ��ծ 
                       + coalesce(b.rzrqzzc, 0)         --������ȯ���ʲ�    
                       + coalesce(APPTBUYB_PLG_MVAL, 0) --Լ��������Ѻ��ֵ
                       + coalesce(NOTS_MVAL, 0)         --���۹���ֵ 
                       + coalesce(PSTK_OPTN_MVAL, 0)    --������Ȩ��ֵ 
    from dm.t_ast_odi a 
    left join dba.t_ddw_client_index_high_priority b on a.main_cptl_acct = b.fund_account and a.occur_dt = b.rq
     where a.occur_dt = @v_bin_date;

    commit;


 ------------------------
    -- ����ҵ�����󣺾��ʲ�=��ĩ�ʲ������ʲ���-������ȯ�ܸ�ծ-��Ʊ��Ѻ��ծ-Լ�����ظ�ծ������������ܸ�ծҪ���������͵�������ȯ��ծ
 ------------------------

  update dm.t_ast_odi
     set NET_AST = FINAL_AST                    --��ĩ�ʲ�/����ҵ��ھ����ʲ�
                   - (COALESCE(FIN_CLOSE_BALANCE, 0)       +COALESCE(SLO_CLOSE_BALANCE, 0)       + COALESCE(FARE_CLOSE_DEBIT, 0)         + COALESCE(OTHER_CLOSE_DEBIT, 0) +
                      COALESCE(FIN_CLOSE_INTEREST, 0)      +COALESCE(SLO_CLOSE_INTEREST, 0)      +COALESCE(FARE_CLOSE_INTEREST, 0)       +COALESCE(OTHER_CLOSE_INTEREST, 0) +
                      COALESCE(FIN_CLOSE_FINE_INTEREST, 0) +COALESCE(SLO_CLOSE_FINE_INTEREST, 0) +COALESCE(OTHER_CLOSE_FINE_INTEREST, 0) +COALESCE(REFCOST_CLOSE_FARE, 0)) --������ȯ�ܸ�ծ:���ʸ�ծ����ȯ��ծ�����ø�ծ��������ծ����Ϣ��ծ����Ϣ��ծ
                   - coalesce(STKPLG_LIAB, 0)  --��Ʊ��Ѻ��ծ  
                   - coalesce(b.ydghfz, 0)     --Լ�����ظ�ծ
  from dm.t_ast_odi a 
  left join dba.t_ddw_client_index_high_priority b on a.main_cptl_acct = b.fund_account and a.occur_dt = b.rq
  left join DBA.T_EDW_UF2_RZRQ_ASSETDEBIT        c on a.cust_id = c.client_id           and a.occur_dt = c.load_dt
   where a.occur_dt = @v_bin_date;
  
  commit;

  set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 
         
   end
GO
GRANT EXECUTE ON dm.p_ast_odi TO query_dev
GO
GRANT EXECUTE ON dm.p_ast_odi TO xydc
GO
CREATE PROCEDURE dm.P_AST_ODI_M_D(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  ������: ��GP�д����ͻ���ͨ�ʲ��±�
  ��д��: DCY
  ��������: 2018-01-05
  ��飺�ͻ���ͨ�ʲ��±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  
             20180201                   dcy               �������ʲ�����Ʊ�ͻ�����ֵ����Ʒ����ֵ��������Ʒ��ֵ�������ʲ���ֵ��Լ��������Ѻ��ֵ���������������ָ��
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --��Ȼ��_�³�
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --��Ȼ��_��ĩ
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --������_�³�
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --������_��ĩ
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --��Ȼ��_���
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --������_���
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --��������_��
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --��������_��


    ----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT)	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 ɾ����������
  DELETE FROM DM.T_AST_ODI_M_D WHERE YEAR=@V_BIN_YEAR AND MTH= @V_BIN_MTH;

	insert into DM.T_AST_ODI_M_D
	(
	 CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,SCDY_MVAL_FINAL
	,STKF_MVAL_FINAL
	,A_SHR_MVAL_FINAL
	,NOTS_MVAL_FINAL
	,OFFUND_MVAL_FINAL
	,OPFUND_MVAL_FINAL
	,SB_MVAL_FINAL
	,IMGT_PD_MVAL_FINAL
	,BANK_CHRM_MVAL_FINAL
	,SECU_CHRM_MVAL_FINAL
	,PSTK_OPTN_MVAL_FINAL
	,B_SHR_MVAL_FINAL
	,OUTMARK_MVAL_FINAL
	,CPTL_BAL_FINAL
	,NO_ARVD_CPTL_FINAL
	,PO_FUND_MVAL_FINAL
	,PTE_FUND_MVAL_FINAL
	,OVERSEA_TOT_AST_FINAL
	,FUTR_TOT_AST_FINAL
	,CPTL_BAL_RMB_FINAL
	,CPTL_BAL_HKD_FINAL
	,CPTL_BAL_USD_FINAL
	,LOW_RISK_TOT_AST_FINAL
	,FUND_SPACCT_MVAL_FINAL
	,HGT_MVAL_FINAL
	,SGT_MVAL_FINAL
	,NET_AST_FINAL
	,TOT_AST_CONTAIN_NOTS_FINAL
	,TOT_AST_N_CONTAIN_NOTS_FINAL
	,BOND_MVAL_FINAL
	,REPO_MVAL_FINAL
	,TREA_REPO_MVAL_FINAL
	,REPQ_MVAL_FINAL
	,TOT_AST_FINAL
	,STKT_FUND_MVAL_FINAL
	,PROD_TOT_MVAL_FINAL
	,OTH_PROD_MVAL_FINAL
	,OTH_AST_MVAL_FINAL
	,APPTBUYB_PLG_MVAL_FINAL
	,SCDY_MVAL_MDA
	,STKF_MVAL_MDA
	,A_SHR_MVAL_MDA
	,NOTS_MVAL_MDA
	,OFFUND_MVAL_MDA
	,OPFUND_MVAL_MDA
	,SB_MVAL_MDA
	,IMGT_PD_MVAL_MDA
	,BANK_CHRM_MVAL_MDA
	,SECU_CHRM_MVAL_MDA
	,PSTK_OPTN_MVAL_MDA
	,B_SHR_MVAL_MDA
	,OUTMARK_MVAL_MDA
	,CPTL_BAL_MDA
	,NO_ARVD_CPTL_MDA
	,PO_FUND_MVAL_MDA
	,PTE_FUND_MVAL_MDA
	,OVERSEA_TOT_AST_MDA
	,FUTR_TOT_AST_MDA
	,CPTL_BAL_RMB_MDA
	,CPTL_BAL_HKD_MDA
	,CPTL_BAL_USD_MDA
	,LOW_RISK_TOT_AST_MDA
	,FUND_SPACCT_MVAL_MDA
	,HGT_MVAL_MDA
	,SGT_MVAL_MDA
	,NET_AST_MDA
	,TOT_AST_CONTAIN_NOTS_MDA
	,TOT_AST_N_CONTAIN_NOTS_MDA
	,BOND_MVAL_MDA
	,REPO_MVAL_MDA
	,TREA_REPO_MVAL_MDA
	,REPQ_MVAL_MDA
	,TOT_AST_MDA
	,STKT_FUND_MVAL_MDA
	,PROD_TOT_MVAL_MDA
	,OTH_PROD_MVAL_MDA
	,OTH_AST_MVAL_MDA
	,APPTBUYB_PLG_MVAL_MDA
	,SCDY_MVAL_YDA
	,STKF_MVAL_YDA
	,A_SHR_MVAL_YDA
	,NOTS_MVAL_YDA
	,OFFUND_MVAL_YDA
	,OPFUND_MVAL_YDA
	,SB_MVAL_YDA
	,IMGT_PD_MVAL_YDA
	,BANK_CHRM_MVAL_YDA
	,SECU_CHRM_MVAL_YDA
	,PSTK_OPTN_MVAL_YDA
	,B_SHR_MVAL_YDA
	,OUTMARK_MVAL_YDA
	,CPTL_BAL_YDA
	,NO_ARVD_CPTL_YDA
	,PO_FUND_MVAL_YDA
	,PTE_FUND_MVAL_YDA
	,OVERSEA_TOT_AST_YDA
	,FUTR_TOT_AST_YDA
	,CPTL_BAL_RMB_YDA
	,CPTL_BAL_HKD_YDA
	,CPTL_BAL_USD_YDA
	,LOW_RISK_TOT_AST_YDA
	,FUND_SPACCT_MVAL_YDA
	,HGT_MVAL_YDA
	,SGT_MVAL_YDA
	,NET_AST_YDA
	,TOT_AST_CONTAIN_NOTS_YDA
	,TOT_AST_N_CONTAIN_NOTS_YDA
	,BOND_MVAL_YDA
	,REPO_MVAL_YDA
	,TREA_REPO_MVAL_YDA
	,REPQ_MVAL_YDA
	,TOT_AST_YDA
	,STKT_FUND_MVAL_YDA
	,PROD_TOT_MVAL_YDA
	,OTH_PROD_MVAL_YDA
	,OTH_AST_MVAL_YDA
	,APPTBUYB_PLG_MVAL_YDA
	,LOAD_DT
	)
select
	t1.CUST_ID as �ͻ�����
	,@V_BIN_DATE AS OCCUR_DT
	,t_rq.��
	,t_rq.��	
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ��_�³�
	,t_rq.��||t_rq.�� as ����
	,t_rq.��||t_rq.��||t1.CUST_ID as ���¿ͻ����
	
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SCDY_MVAL,0) else 0 end) as ������ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.STKF_MVAL,0) else 0 end) as �ɻ���ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.A_SHR_MVAL,0) else 0 end) as A����ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.NOTS_MVAL,0) else 0 end) as ���۹���ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OFFUND_MVAL,0) else 0 end) as ���ڻ�����ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OPFUND_MVAL,0) else 0 end) as ���������ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SB_MVAL,0) else 0 end) as ������ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.IMGT_PD_MVAL,0) else 0 end) as �ʹܲ�Ʒ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.BANK_CHRM_MVAL,0) else 0 end) as ���������ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SECU_CHRM_MVAL,0) else 0 end) as ֤ȯ�����ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.PSTK_OPTN_MVAL,0) else 0 end) as ������Ȩ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.B_SHR_MVAL,0) else 0 end) as B����ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OUTMARK_MVAL,0) else 0 end) as ������ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.CPTL_BAL,0) else 0 end) as �ʽ����_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.NO_ARVD_CPTL,0) else 0 end) as δ�����ʽ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.PO_FUND_MVAL,0) else 0 end) as ��ļ������ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.PTE_FUND_MVAL,0) else 0 end) as ˽ļ������ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OVERSEA_TOT_AST,0) else 0 end) as �������ʲ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.FUTR_TOT_AST,0) else 0 end) as �ڻ����ʲ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.CPTL_BAL_RMB,0) else 0 end) as �ʽ���������_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.CPTL_BAL_HKD,0) else 0 end) as �ʽ����۱�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.CPTL_BAL_USD,0) else 0 end) as �ʽ������Ԫ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.LOW_RISK_TOT_AST,0) else 0 end) as �ͷ������ʲ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.FUND_SPACCT_MVAL,0) else 0 end) as ����ר����ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.HGT_MVAL,0) else 0 end) as ����ͨ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.SGT_MVAL,0) else 0 end) as ���ͨ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.NET_AST,0) else 0 end) as ���ʲ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.TOT_AST_CONTAIN_NOTS,0) else 0 end) as ���ʲ�_�����۹�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.TOT_AST_N_CONTAIN_NOTS,0) else 0 end) as ���ʲ�_�������۹�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.BOND_MVAL,0) else 0 end) as ծȯ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.REPO_MVAL,0) else 0 end) as �ع���ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.TREA_REPO_MVAL,0) else 0 end) as ��ծ�ع���ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.REPQ_MVAL,0) else 0 end) as ���ۻع���ֵ_��ĩ

	--20180201����
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.FINAL_AST,0) else 0 end) as ���ʲ�_��ĩ        
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.STKT_FUND_MVAL,0) else 0 end) as ��Ʊ�ͻ�����ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.PROD_TOT_MVAL,0) else 0 end) as ��Ʒ����ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OTH_PROD_MVAL,0) else 0 end) as ������Ʒ��ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OTH_AST_MVAL,0) else 0 end) as �����ʲ���ֵ_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.APPTBUYB_PLG_MVAL,0) else 0 end) as Լ��������Ѻ��ֵ_��ĩ
	
	
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SCDY_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ������ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.STKF_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as �ɻ���ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.A_SHR_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as A����ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.NOTS_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ���۹���ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OFFUND_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ���ڻ�����ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OPFUND_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ���������ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SB_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ������ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.IMGT_PD_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as �ʹܲ�Ʒ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.BANK_CHRM_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ���������ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SECU_CHRM_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ֤ȯ�����ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.PSTK_OPTN_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ������Ȩ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.B_SHR_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as B����ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OUTMARK_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ������ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CPTL_BAL,0) else 0 end)/t_rq.��Ȼ����_�� as �ʽ����_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.NO_ARVD_CPTL,0) else 0 end)/t_rq.��Ȼ����_�� as δ�����ʽ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.PO_FUND_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ��ļ������ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.PTE_FUND_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ˽ļ������ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OVERSEA_TOT_AST,0) else 0 end)/t_rq.��Ȼ����_�� as �������ʲ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FUTR_TOT_AST,0) else 0 end)/t_rq.��Ȼ����_�� as �ڻ����ʲ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CPTL_BAL_RMB,0) else 0 end)/t_rq.��Ȼ����_�� as �ʽ���������_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CPTL_BAL_HKD,0) else 0 end)/t_rq.��Ȼ����_�� as �ʽ����۱�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CPTL_BAL_USD,0) else 0 end)/t_rq.��Ȼ����_�� as �ʽ������Ԫ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.LOW_RISK_TOT_AST,0) else 0 end)/t_rq.��Ȼ����_�� as �ͷ������ʲ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FUND_SPACCT_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ����ר����ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.HGT_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ����ͨ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SGT_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ���ͨ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.NET_AST,0) else 0 end)/t_rq.��Ȼ����_�� as ���ʲ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.TOT_AST_CONTAIN_NOTS,0) else 0 end)/t_rq.��Ȼ����_�� as ���ʲ�_�����۹�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.TOT_AST_N_CONTAIN_NOTS,0) else 0 end)/t_rq.��Ȼ����_�� as ���ʲ�_�������۹�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.BOND_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ծȯ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.REPO_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as �ع���ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.TREA_REPO_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ��ծ�ع���ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.REPQ_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ���ۻع���ֵ_���վ�
	
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FINAL_AST,0) else 0 end)/t_rq.��Ȼ����_�� as ���ʲ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.STKT_FUND_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ��Ʊ�ͻ�����ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.PROD_TOT_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ��Ʒ����ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OTH_PROD_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as ������Ʒ��ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OTH_AST_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as �����ʲ���ֵ_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.APPTBUYB_PLG_MVAL,0) else 0 end)/t_rq.��Ȼ����_�� as Լ��������Ѻ��ֵ_���վ�

	,sum(COALESCE(t1.SCDY_MVAL,0))/t_rq.��Ȼ����_�� as ������ֵ_���վ�
	,sum(COALESCE(t1.STKF_MVAL,0))/t_rq.��Ȼ����_�� as �ɻ���ֵ_���վ�
	,sum(COALESCE(t1.A_SHR_MVAL,0))/t_rq.��Ȼ����_�� as A����ֵ_���վ�
	,sum(COALESCE(t1.NOTS_MVAL,0))/t_rq.��Ȼ����_�� as ���۹���ֵ_���վ�
	,sum(COALESCE(t1.OFFUND_MVAL,0))/t_rq.��Ȼ����_�� as ���ڻ�����ֵ_���վ�
	,sum(COALESCE(t1.OPFUND_MVAL,0))/t_rq.��Ȼ����_�� as ���������ֵ_���վ�
	,sum(COALESCE(t1.SB_MVAL,0))/t_rq.��Ȼ����_�� as ������ֵ_���վ�
	,sum(COALESCE(t1.IMGT_PD_MVAL,0))/t_rq.��Ȼ����_�� as �ʹܲ�Ʒ��ֵ_���վ�
	,sum(COALESCE(t1.BANK_CHRM_MVAL,0))/t_rq.��Ȼ����_�� as ���������ֵ_���վ�
	,sum(COALESCE(t1.SECU_CHRM_MVAL,0))/t_rq.��Ȼ����_�� as ֤ȯ�����ֵ_���վ�
	,sum(COALESCE(t1.PSTK_OPTN_MVAL,0))/t_rq.��Ȼ����_�� as ������Ȩ��ֵ_���վ�
	,sum(COALESCE(t1.B_SHR_MVAL,0))/t_rq.��Ȼ����_�� as B����ֵ_���վ�
	,sum(COALESCE(t1.OUTMARK_MVAL,0))/t_rq.��Ȼ����_�� as ������ֵ_���վ�
	,sum(COALESCE(t1.CPTL_BAL,0))/t_rq.��Ȼ����_�� as �ʽ����_���վ�
	,sum(COALESCE(t1.NO_ARVD_CPTL,0))/t_rq.��Ȼ����_�� as δ�����ʽ�_���վ�
	,sum(COALESCE(t1.PO_FUND_MVAL,0))/t_rq.��Ȼ����_�� as ��ļ������ֵ_���վ�
	,sum(COALESCE(t1.PTE_FUND_MVAL,0))/t_rq.��Ȼ����_�� as ˽ļ������ֵ_���վ�
	,sum(COALESCE(t1.OVERSEA_TOT_AST,0))/t_rq.��Ȼ����_�� as �������ʲ�_���վ�
	,sum(COALESCE(t1.FUTR_TOT_AST,0))/t_rq.��Ȼ����_�� as �ڻ����ʲ�_���վ�
	,sum(COALESCE(t1.CPTL_BAL_RMB,0))/t_rq.��Ȼ����_�� as �ʽ���������_���վ�
	,sum(COALESCE(t1.CPTL_BAL_HKD,0))/t_rq.��Ȼ����_�� as �ʽ����۱�_���վ�
	,sum(COALESCE(t1.CPTL_BAL_USD,0))/t_rq.��Ȼ����_�� as �ʽ������Ԫ_���վ�
	,sum(COALESCE(t1.LOW_RISK_TOT_AST,0))/t_rq.��Ȼ����_�� as �ͷ������ʲ�_���վ�
	,sum(COALESCE(t1.FUND_SPACCT_MVAL,0))/t_rq.��Ȼ����_�� as ����ר����ֵ_���վ�
	,sum(COALESCE(t1.HGT_MVAL,0))/t_rq.��Ȼ����_�� as ����ͨ��ֵ_���վ�
	,sum(COALESCE(t1.SGT_MVAL,0))/t_rq.��Ȼ����_�� as ���ͨ��ֵ_���վ�		
	,sum(COALESCE(t1.NET_AST,0))/t_rq.��Ȼ����_�� as ���ʲ�_���վ�
	,sum(COALESCE(t1.TOT_AST_CONTAIN_NOTS,0))/t_rq.��Ȼ����_�� as ���ʲ�_�����۹�_���վ�
	,sum(COALESCE(t1.TOT_AST_N_CONTAIN_NOTS,0))/t_rq.��Ȼ����_�� as ���ʲ�_�������۹�_���վ�		
	,sum(COALESCE(t1.BOND_MVAL,0))/t_rq.��Ȼ����_�� as ծȯ��ֵ_���վ�
	,sum(COALESCE(t1.REPO_MVAL,0))/t_rq.��Ȼ����_�� as �ع���ֵ_���վ�
	,sum(COALESCE(t1.TREA_REPO_MVAL,0))/t_rq.��Ȼ����_�� as ��ծ�ع���ֵ_���վ�
	,sum(COALESCE(t1.REPQ_MVAL,0))/t_rq.��Ȼ����_�� as ���ۻع���ֵ_���վ�
	
	,sum(COALESCE(t1.FINAL_AST,0))/t_rq.��Ȼ����_�� as ���ʲ�_���վ�
	,sum(COALESCE(t1.STKT_FUND_MVAL,0))/t_rq.��Ȼ����_�� as ��Ʊ�ͻ�����ֵ_���վ�
	,sum(COALESCE(t1.PROD_TOT_MVAL,0))/t_rq.��Ȼ����_�� as ��Ʒ����ֵ_���վ�
	,sum(COALESCE(t1.OTH_PROD_MVAL,0))/t_rq.��Ȼ����_�� as ������Ʒ��ֵ_���վ�
	,sum(COALESCE(t1.OTH_AST_MVAL,0))/t_rq.��Ȼ����_�� as �����ʲ���ֵ_���վ�
	,sum(COALESCE(t1.APPTBUYB_PLG_MVAL,0))/t_rq.��Ȼ����_�� as Լ��������Ѻ��ֵ_���վ�
	
    ,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as ��
		,@V_BIN_MTH as ��
		,t1.DT as ����
		,t1.TRD_DT as ��������
		,@V_BIN_NATRE_DAY_MTHBEG    as ��Ȼ��_�³�
		,@V_BIN_NATRE_DAY_MTHEND    as ��Ȼ��_��ĩ
		,@V_BIN_TRD_DAY_MTHBEG      as ������_�³�
		,@V_BIN_TRD_DAY_MTHEND      as ������_��ĩ
		,@V_BIN_NATRE_DAY_YEARBGN   as ��Ȼ��_���
		,@V_BIN_TRD_DAY_YEARBGN     as ������_���
		,@V_BIN_NATRE_DAYS_MTH      as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_MTH        as ��������_��
		,@V_BIN_NATRE_DAYS_YEAR     as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_YEAR       as ��������_��
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) t_rq
left join DM.T_AST_ODI t1 on t_rq.��������=t1.OCCUR_DT
group by
	t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ��_�³�
	,t1.CUST_ID

;

END
GO
CREATE PROCEDURE dm.p_ast_sec_acct_hld(IN @V_BIN_DATE VARCHAR(10),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  ������: ֤ȯ�˻����б�
  ��д��: rengz
  ��������: 2017-11-22
  ��飺�ͻ����е�֤ȯ���ݣ��ո���
        �洢������Ҫ�ο�dba.t_edw_t05_sec_bal
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
             20180315                 rengz              ������������
  *********************************************************************/
  
    --declare @v_bin_date numeric(8); 
    
	set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date =@v_bin_date;
	
	--������������
    --set @v_b_date=(select min(rq) from dba.t_ddw_d_rq where nian=substring(@V_BIN_DATE,1,4) and yue=substring(@V_BIN_DATE,5,2) and sfjrbz='1' ); 
   
    --ɾ������������
    delete from dm.t_ast_sec_acct_hld where load_dt =@v_bin_date;

    commit;


------------------------
  -- ��֤ȯ��Ϣ��
------------------------   
      select a.stock_cd
           ,a.stock_call
           ,trad_price
           ,b.exchange_type
           ,b.stock_type
           ,b.money_type
           ,b.remark
      into #t_stock_info
      from dba.t_edw_t06_stock_maket_info a
      left join dba.t_ods_uf2_sclxdz b
        on a.stock_type_cd = b.sec_type
       and b.mkt_type = a.market_type_cd
       and b.cur_type = a.curr_type_cd
     where load_dt = @v_bin_date;
    commit;
 
 ------------------------
  -- ���ɳɱ��Ȼ�����Ϣ
------------------------   

    insert into dm.t_ast_sec_acct_hld
      (CUST_ID,
       CPTL_ACCT,
       SECU_CD,
       SECU_TYPE,
       MKT_TYPE,
       OCCUR_DT,
       HLD_VOL,
       CET_VOL,
       AVL_VOL,
       FRZ_VOL,
       BUYIN_COST,
       ROUG_VOL,
       --LS_HLD_VOL  ���۳�������
       CLQN_PRIC,
       MVAL,
       LOAD_DT,
       prod_type_perfm) 
          select 
            client_id
            ,fund_account
            ,stock_code
            ,a.stock_type
            ,a.exchange_type
            ,a.load_dt
            ,sum(current_amount)                                   --��������
            ,sum(correct_amount)                                   --��������
            ,sum(current_amount) as gain_bal                       --��������   20180315 �޶� �������������
            ,sum(frozen_amount)                                    --��������
            ,sum(cost_price * current_amount)
            ,sum(uncome_buy_amount - uncome_sell_amount) as ztsl ---������
            ,max(b.trad_price)
            ,sum(b.trad_price * current_amount)
            ,a.load_dt as rq
            ,'1' as cplx                                         -----��Ʒ���� ��Ч  ������
       from dba.t_edw_uf2_stock a
       left join #t_stock_info b
         on a.stock_code = b.stock_cd
        and a.stock_type = b.stock_type
        and a.exchange_type = b.exchange_type
        and a.money_type = b.money_type
      where a.load_dt = @v_bin_date
      group by client_id,
               fund_account,
               stock_code,
               a.stock_type,
               a.exchange_type,
               a.load_dt;

   commit;

  ------------------------
  -- ���۳�������
  ------------------------
      select distinct a.fund_account, stock_account, a.client_id
        into #t_fund
        from dba.t_edw_uf2_stockholder a
        left join dba.t_edw_uf2_fundaccount b on a.fund_account = b.fund_account and b.load_dt = @v_bin_date and b.fundacct_status = '0'
       where a.load_dt = @v_bin_date
         and a.exchange_type in ('1', '2')
         and a.asset_prop = '0';


      select b.fund_account, sec_code, sum(sec_bal) as cysl
        into #t_xscysl
        from dba.t_edw_tr_sec_bal_xslt a
        left join #t_fund b
          on a.inv_acc = b.stock_account
       where a.load_dt = @v_bin_date 
       group by b.fund_account, sec_code;

      update dm.t_ast_sec_acct_hld a
         set LS_HLD_VOL = coalesce(cysl, 0) 
      from #t_xscysl b
       where a.CPTL_ACCT = b.fund_account
         and a.OCCUR_DT = @v_bin_date
         and a.secu_cd = b.sec_code;

      commit;

  set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 

end
GO
GRANT EXECUTE ON dm.p_ast_sec_acct_hld TO query_dev
GO
GRANT EXECUTE ON dm.p_ast_sec_acct_hld TO xydc
GO
CREATE PROCEDURE dm.P_AST_STKPLG(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_�ʲ�����Ʊ��Ѻ�ʲ�
      ��д�ߣ�chenhu
      �������ڣ�2017-11-22
      �޸���־��2017-12-26 ������ͬ���
      ��飺
        
    *********************************************************************/

    COMMIT;
    
    --ɾ����������
    DELETE FROM DM.T_AST_STKPLG WHERE OCCUR_DT = @V_IN_DATE;
    
    /*
    ��Ʊ����:stock_property:
    '05','�׷�ǰ���۹�'
    '00','��������ͨ��'
    '01','�׷�����������۹�'
    '02','��Ȩ�������۹�'
    '03','�׷�����������۹�'
    '04','�߹�������'
    '07','����ͨ��'
    �ڳ�����ţ�DBA.T_ODS_UF2_SRPFUNDER.funder_no
    */
    INSERT INTO DM.T_AST_STKPLG
        (CUST_ID,OCCUR_DT,LOAD_DT,CTR_NO,GUAR_SECU_MVAL,STKPLG_FIN_BAL,SH_GUAR_SECU_MVAL,SZ_GUAR_SECU_MVAL,SH_NOTS_GUAR_SECU_MVAL,SZ_NOTS_GUAR_SECU_MVAL,PROP_FINAC_OUT_SIDE_BAL,ASSM_FINAC_OUT_SIDE_BAL,SM_LOAN_FINAC_OUT_BAL)
    SELECT GH.KHBH_HS   AS CUST_ID          --�ͻ����
        ,GH.RQ          AS OCCUR_DT         --ҵ������  
        ,GH.RQ          AS LOAD_DT          --��ϴ����  
        ,GH.HTBH        AS CTR_NO           --��ͬ���
        ,SUM(GH.DYZQSZ) AS GUAR_SECU_MVAL   --����֤ȯ��ֵ
        ,COALESCE(SUM(CASE WHEN GH.XYZT IN ('1','2') THEN GH.YJGHJE END),0) AS STKPLG_FIN_BAL    --�������                        ---20180418 ������Э��״̬Ϊ1 ��Ч 2��������ͬ��¼
        ,SUM(CASE WHEN GH.SCLX = '01' THEN GH.DYZQSZ ELSE 0 END)            AS SH_GUAR_SECU_MVAL --�Ϻ�����֤ȯ��ֵ
        ,SUM(CASE WHEN GH.SCLX = '02' THEN GH.DYZQSZ ELSE 0 END)            AS SZ_GUAR_SECU_MVAL --���ڵ���֤ȯ��ֵ
        ,SUM(CASE WHEN GH.SCLX = '01' AND HS.STOCK_PROPERTY <> '00' THEN GH.DYZQSZ ELSE 0 END) AS SH_NOTS_GUAR_SECU_MVAL  --�Ϻ����۹ɵ���֤ȯ��ֵ
        ,SUM(CASE WHEN GH.SCLX = '02' AND HS.STOCK_PROPERTY <> '00' THEN GH.DYZQSZ ELSE 0 END) AS SZ_NOTS_GUAR_SECU_MVAL  --�������۹ɵ���֤ȯ��ֵ
        ,SUM(CASE WHEN GH.RCFBM = 1 THEN GH.YJGHJE ELSE 0 END)                                 AS PROP_FINAC_OUT_SIDE_BAL --��Ӫ�ڳ������
        ,SUM(CASE WHEN GH.RCFBM NOT IN (1,23,50) THEN GH.YJGHJE ELSE 0 END)                    AS ASSM_FINAC_OUT_SIDE_BAL --�ʹ��ڳ������ 
        ,SUM(CASE WHEN GH.RCFBM IN (23,50) THEN GH.YJGHJE ELSE 0 END)                          AS SM_LOAN_FINAC_OUT_BAL   --С����ڳ����
    FROM DBA.T_DDW_GPZYHG_HT_D            GH
    LEFT JOIN 
             (SELECT A.LOAD_DT,A.CONTRACT_ID, A.STOCK_PROPERTY,A.FUND_ACCOUNT,A.CLIENT_ID,A.STOCK_ACCOUNT,A.STOCK_CODE,A.EXCHANGE_TYPE
              FROM DBA.GT_ODS_HS06_SRPCONTRACT A 
              WHERE  A.LOAD_DT= @V_IN_DATE 
              UNION 
              SELECT A.DATE_CLEAR,A.CONTRACT_ID, A.STOCK_PROPERTY,A.FUND_ACCOUNT,A.CLIENT_ID,A.STOCK_ACCOUNT,A.STOCK_CODE,A.EXCHANGE_TYPE
              FROM DBA.GT_ODS_HS06_HISSRPCONTRACT A 
              WHERE  A.DATE_CLEAR= @V_IN_DATE 
              )                           HS ON GH.RQ = HS.LOAD_DT AND GH.HTBH = HS.CONTRACT_ID                           --���ݺ�ͬ��Ź���       20180418 ���ӵ����Ѿ��˽��ͬ��Ϣ    
    WHERE GH.RQ = @V_IN_DATE
    GROUP BY GH.KHBH_HS,GH.RQ,GH.HTBH;
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_AST_STKPLG TO query_dev
GO
GRANT EXECUTE ON dm.P_AST_STKPLG TO xydc
GO
CREATE PROCEDURE dm.P_AST_STKPLG_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д�����Ʊ��Ѻ�ʲ��±�
  ��д��: DCY
  ��������: 2018-01-05
  ��飺��Ʊ��Ѻ�ʲ��±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --��Ȼ��_�³�
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --��Ȼ��_��ĩ
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --������_�³�
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --������_��ĩ
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --��Ȼ��_���
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --������_���
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --��������_��
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --��������_��


    ----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
 
--PART0 ɾ����������
  DELETE FROM DM.T_AST_STKPLG_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	INSERT INTO DM.T_AST_STKPLG_M_D 
	(
	CUST_ID
	,OCCUR_DT
	,YEAR
	,MTH
	,CTR_NO
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,NATRE_DAY_MTHBEG
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,GUAR_SECU_MVAL_FINAL
	,STKPLG_FIN_BAL_FINAL
	,SH_GUAR_SECU_MVAL_FINAL
	,SZ_GUAR_SECU_MVAL_FINAL
	,SH_NOTS_GUAR_SECU_MVAL_FINAL
	,SZ_NOTS_GUAR_SECU_MVAL_FINAL
	,PROP_FINAC_OUT_SIDE_BAL_FINAL
	,ASSM_FINAC_OUT_SIDE_BAL_FINAL
	,SM_LOAN_FINAC_OUT_BAL_FINAL
	,GUAR_SECU_MVAL_MDA
	,STKPLG_FIN_BAL_MDA
	,SH_GUAR_SECU_MVAL_MDA
	,SZ_GUAR_SECU_MVAL_MDA
	,SH_NOTS_GUAR_SECU_MVAL_MDA
	,SZ_NOTS_GUAR_SECU_MVAL_MDA
	,PROP_FINAC_OUT_SIDE_BAL_MDA
	,ASSM_FINAC_OUT_SIDE_BAL_MDA
	,SM_LOAN_FINAC_OUT_BAL_MDA
	,GUAR_SECU_MVAL_YDA
	,STKPLG_FIN_BAL_YDA
	,SH_GUAR_SECU_MVAL_YDA
	,SZ_GUAR_SECU_MVAL_YDA
	,SH_NOTS_GUAR_SECU_MVAL_YDA
	,SZ_NOTS_GUAR_SECU_MVAL_YDA
	,PROP_FINAC_OUT_SIDE_BAL_YDA
	,ASSM_FINAC_OUT_SIDE_BAL_YDA
	,SM_LOAN_FINAC_OUT_BAL_YDA
	,LOAD_DT
	)
SELECT
	T1.CUST_ID AS �ͻ�����	
    ,@V_BIN_DATE AS OCCUR_DT
	,T_RQ.��
	,T_RQ.��
	,T1.CTR_NO AS ��ͬ���
	,T_RQ.��Ȼ����_��
	,T_RQ.��Ȼ����_��
	,T_RQ.��Ȼ��_�³�
	,T_RQ.��||T_RQ.�� AS ����
	,T_RQ.��||T_RQ.��||T1.CUST_ID AS ���¿ͻ�����
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.GUAR_SECU_MVAL,0) ELSE 0 END) 			AS ����֤ȯ��ֵ_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.STKPLG_FIN_BAL,0) ELSE 0 END) 			AS ��Ʊ��Ѻ�������_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.SH_GUAR_SECU_MVAL,0) ELSE 0 END) 		AS �Ϻ�����֤ȯ��ֵ_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.SZ_GUAR_SECU_MVAL,0) ELSE 0 END) 		AS ���ڵ���֤ȯ��ֵ_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.SH_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END) 	AS �Ϻ����۹ɵ���֤ȯ��ֵ_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.SZ_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END) 	AS �������۹ɵ���֤ȯ��ֵ_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL,0) ELSE 0 END) 	AS ��Ӫ�ڳ������_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL,0) ELSE 0 END) 	AS �ʹ��ڳ������_��ĩ
	,SUM(CASE WHEN T_RQ.����=T_RQ.��Ȼ��_��ĩ THEN COALESCE(T1.SM_LOAN_FINAC_OUT_BAL,0) ELSE 0 END) 	AS С����ڳ����_��ĩ

	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� 			AS ����֤ȯ��ֵ_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.STKPLG_FIN_BAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� 			AS ��Ʊ��Ѻ�������_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.SH_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� 		AS �Ϻ�����֤ȯ��ֵ_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.SZ_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� 		AS ���ڵ���֤ȯ��ֵ_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.SH_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� 	AS �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.SZ_NOTS_GUAR_SECU_MVAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� 	AS �������۹ɵ���֤ȯ��ֵ_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� AS ��Ӫ�ڳ������_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� AS �ʹ��ڳ������_���վ�
	,SUM(CASE WHEN T_RQ.����>=T_RQ.��Ȼ��_�³� THEN COALESCE(T1.SM_LOAN_FINAC_OUT_BAL,0) ELSE 0 END)/T_RQ.��Ȼ����_�� 	AS С����ڳ����_���վ�

	,SUM(COALESCE(T1.GUAR_SECU_MVAL,0))/T_RQ.��Ȼ����_�� 			AS ����֤ȯ��ֵ_���վ�
	,SUM(COALESCE(T1.STKPLG_FIN_BAL,0))/T_RQ.��Ȼ����_�� 			AS ��Ʊ��Ѻ�������_���վ�
	,SUM(COALESCE(T1.SH_GUAR_SECU_MVAL,0))/T_RQ.��Ȼ����_�� 		AS �Ϻ�����֤ȯ��ֵ_���վ�
	,SUM(COALESCE(T1.SZ_GUAR_SECU_MVAL,0))/T_RQ.��Ȼ����_�� 		AS ���ڵ���֤ȯ��ֵ_���վ�
	,SUM(COALESCE(T1.SH_NOTS_GUAR_SECU_MVAL,0))/T_RQ.��Ȼ����_�� 	AS �Ϻ����۹ɵ���֤ȯ��ֵ_���վ�
	,SUM(COALESCE(T1.SZ_NOTS_GUAR_SECU_MVAL,0))/T_RQ.��Ȼ����_�� 	AS �������۹ɵ���֤ȯ��ֵ_���վ�
	,SUM(COALESCE(T1.PROP_FINAC_OUT_SIDE_BAL,0))/T_RQ.��Ȼ����_�� 	AS ��Ӫ�ڳ������_���վ�
	,SUM(COALESCE(T1.ASSM_FINAC_OUT_SIDE_BAL,0))/T_RQ.��Ȼ����_�� 	AS �ʹ��ڳ������_���վ�
	,SUM(COALESCE(T1.SM_LOAN_FINAC_OUT_BAL,0))/T_RQ.��Ȼ����_�� 	AS С����ڳ����_���վ�
	,@V_BIN_DATE

FROM
(
	select
		@V_BIN_YEAR as ��
		,@V_BIN_MTH as ��
		,t1.DT as ����
		,t1.TRD_DT as ��������
		,@V_BIN_NATRE_DAY_MTHBEG    as ��Ȼ��_�³�
		,@V_BIN_NATRE_DAY_MTHEND    as ��Ȼ��_��ĩ
		,@V_BIN_TRD_DAY_MTHBEG      as ������_�³�
		,@V_BIN_TRD_DAY_MTHEND      as ������_��ĩ
		,@V_BIN_NATRE_DAY_YEARBGN   as ��Ȼ��_���
		,@V_BIN_TRD_DAY_YEARBGN     as ������_���
		,@V_BIN_NATRE_DAYS_MTH      as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_MTH        as ��������_��
		,@V_BIN_NATRE_DAYS_YEAR     as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_YEAR       as ��������_��
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
) T_RQ
LEFT JOIN DM.T_AST_STKPLG T1 ON T_RQ.��������=T1.OCCUR_DT
GROUP BY
	T_RQ.��
	,T_RQ.��
	,T_RQ.��Ȼ����_��
	,T_RQ.��Ȼ����_��
	,T_RQ.��Ȼ��_�³�
	,T1.CTR_NO
	,T1.CUST_ID
;

END
GO
CREATE PROCEDURE dm.p_evt_cred_incm_d_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))


begin   
  /******************************************************************
  ������:  �ͻ�����ҵ�������ձ� 
  ��д��: rengz
  ��������: 2018-4-20
  ��飺 

  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��

  *********************************************************************/
 
    --declare @v_bin_date             numeric(8,0); 
    declare @v_bin_lastday          numeric(8,0);  

	set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date =@v_bin_date ;
	
	--������������

    set @v_bin_lastday             =(select lst_trd_day from dm.t_pub_date where dt=@v_bin_date);
 
    --ɾ������������
    delete from dm.t_evt_cred_incm_d_d where occur_dt=@v_bin_date ;
    commit;
     
------------------------
  -- ����ÿ�տͻ��嵥��������������ҵ��Ŀͻ�ID
------------------------  
  insert into dm.t_evt_cred_incm_d_d (CUST_ID, OCCUR_DT, MAIN_CPTL_ACCT)
  select distinct a.client_id,
                  a.load_dt,
                  b.fund_account 
    from (select distinct client_id, load_dt
            from DBA.T_EDW_RZRQ_CLIENT t
           where t.load_dt = @v_bin_date
             and t.client_status = '0'
             and convert(varchar, t.branch_no) not in ('5', '55', '51', '44', '9999')
             and t.client_id <> '448999999' ----�޳�1����ר��ͷ���˻��Զ����ɡ������ƹ�˾�����˻���client_id������ͨ�˻������ж�������˻��Ҿ�Ϊ���ʽ�
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_gpzyhg_d t
           where t.rq = @v_bin_date ---��Ʊ��Ѻ
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999'
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_ydsgh_d t
           where t.rq = @v_bin_date ---Լ��ʽ����
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999') a
    left join dba.t_edw_uf2_fundaccount b
      on a.client_id = b.client_id
     and b.load_dt = @v_bin_date
     and b.fundacct_status = '0'
     and b.asset_prop = '0'
     and b.main_flag = '1';
   
   commit;
------------------------
  -- ����Ӷ�� ��Ӷ��
------------------------  
    select client_id
    ,sum(fare1)                                                                                         as yhs       --ӡ��˰ 
    ,sum(fare2)                                                                                         as ghf       --������
    ,sum(fare3)                                                                                         as wtf       --ί�з�  
    ,sum(EXCHANGE_FARE0)                                                                                as jsf       --���ַ�   
    ,sum(EXCHANGE_FARE3)                                                                                as zgf       --֤�ܷ�   
    ,sum(FAREX)                                                                                         as qtfy      --��������  
    ,sum(case when business_flag in ( 4001, 4002,                                        ---��ͨ
                                      4211, 4212, 4213, 4214, 4215, 4216                 ---����
                                    )  then (fare0)  else 0 end)                                        as yj      --Ӷ��
    ,sum(case when business_flag in ( 4001, 4002,                                        ---��ͨ
                                      4211, 4212, 4213, 4214, 4215, 4216               ---����
                                   )  then 
            	                                                                                        coalesce(fare0,0)
									                                                                    + coalesce(fare3,0)
									                                                                    + coalesce(farex,0)
									                                                                    + coalesce(fare2,0)
									                                                                    - coalesce(exchange_fare0,0)
									                                                                    - coalesce(exchange_fare3,0)
									                                                                    - coalesce(exchange_fare4,0)
									                                                                    - coalesce(exchange_fare5,0)
									                                                                    - coalesce(exchange_fare6,0)
									                                                                    - coalesce(exchange_farex,0)
									                                                                    - coalesce(exchange_fare2,0)
              		                                                                         else 0 end)    as jyj      --��Ӷ��
  
   ---��ͨ����
    ,sum(case when business_flag in ( 4001, 4002)  then (fare0)  else 0 end)                                as pt_yj  --��ͨ����Ӷ��
    ,sum(case when business_flag in ( 4001, 4002)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                              as pt_jyj  --��ͨ���׾�Ӷ��
    ,sum(case when business_flag in ( 4001, 4002)  then (fare2)  else 0 end)                               as pt_ghf   --��ͨ���׹�����
   ---���ý���
    ,sum(case when  business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)      as xy_yj    --���ý���Ӷ��
    ,sum(case when  business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                as xy_jyj   --���ý��׾�Ӷ��
    ,sum(case when  business_flag in (4211, 4212, 4213, 4214, 4215, 4216)  then (fare2)  else 0 end)         as xy_ghf    --���ý��׹�����
     
    into #t_yj   
    from DBA.T_EDW_RZRQ_HISDELIVER a
    where a.load_dt=  @v_bin_date
    group by client_id;
 
    commit;
   
    update dm.t_evt_cred_incm_d_d a
    set 
	    a.GROSS_CMS	        =coalesce(yj,0)           , -- ëӶ��
	    a.NET_CMS	        =coalesce(jyj,0)          , -- ��Ӷ��
	    a.TRAN_FEE	        =coalesce(ghf,0)            , -- ������
	    a.STP_TAX	        =coalesce(yhs,0)            , -- ӡ��˰
	    a.ORDR_FEE	        =coalesce(wtf,0)            , -- ί�з�
	    a.HANDLE_FEE	    =coalesce(jsf,0)            , -- ���ַ�
	    a.SEC_RGLT_FEE	    =coalesce(zgf,0)            , -- ֤�ܷ�
	    a.OTH_FEE		    =coalesce(qtfy,0)           , -- ��������
	    a.CREDIT_ODI_CMS	    =coalesce(pt_yj,0)    , -- ������ȯ��ͨӶ��
	    a.CREDIT_ODI_NET_CMS	=coalesce(pt_jyj,0)   , -- ������ȯ��ͨ��Ӷ��
	    a.CREDIT_ODI_TRAN_FEE	=coalesce(pt_ghf,0)   , -- ������ȯ��ͨ������
	    a.CREDIT_CRED_CMS	    =coalesce(xy_yj,0)    , -- ������ȯ����Ӷ��
	    a.CREDIT_CRED_NET_CMS	=coalesce(xy_jyj,0)   , -- ������ȯ���þ�Ӷ��
	    a.CREDIT_CRED_TRAN_FEE	=coalesce(xy_ghf,0)     -- ������ȯ���ù�����
    from dm.t_evt_cred_incm_d_d  a
    left join #t_yj              b on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
 commit;
  
 
 
------------------------
  -- ������Ϣ
------------------------  
    ---ʵ����Ϣ�ֽ�
   select client_id
         ,sum(case when business_flag in (2219, 2812, 2822, 2832, 2842)                                 then abs(occur_balance) else 0 end) as  lxzc_rz
 		 ,sum(case when business_flag in (2807, 2224)                                                   then abs(occur_balance) else 0 end) as  lxzc_rq
         ,sum(case when business_flag in ( 2814, 2816, 2824,2826, 2834, 2836, 2844, 2846,  2220, 2221)  then abs(occur_balance) else 0 end) as  lxzc_qt
   into #t_rzrq_ss
   -- select *,occur_balance
   from dba.t_EDW_RZRQ_HISFUNDJOUR   
   where  init_date  = @v_bin_date
   group by client_id;

   commit;

    update dm.t_evt_cred_incm_d_d 
    set 
     a.FIN_PAIDINT =coalesce(lxzc_rz,0)+coalesce(lxzc_qt,0)            ,--����ʵ����Ϣ
     a.FIN_IE  =coalesce(lxzc_rz,0)                                    ,--��������Ϣ֧��
     a.CRDT_STK_IE =coalesce(lxzc_rq,0)                                ,--����ȯ��Ϣ֧��
     a.OTH_IE      =coalesce(lxzc_qt,0)                                 --��������Ϣ֧��
    from dm.t_evt_cred_incm_d_d a 
    left join #t_rzrq_ss        b on a.cust_id=b.client_id
    where  a.occur_dt=@v_bin_date;

   commit;
 
   ---Ӧ����Ϣ�ֽ�
    select a.client_id
           ,b.byddjgzr  as tianshu
           ,a.close_finance_interest  as close_finance_interest_today
           ,a.close_fare_interest     as close_fare_interest_today  
           ,a.close_other_interest    as close_other_interest_today  

           ,c.close_finance_interest  as close_finance_interest_lastday
           ,c.close_fare_interest     as close_fare_interest_lastday 
           ,c.close_other_interest    as close_other_interest_lastday 
           ,a.finance_close_balance + a.CLOSE_FARE_DEBIT + a.CLOSE_OTHER_DEBIT  as rzrqzjcb_xzq    --������ȯ�ʽ�ɱ�_�������
   into #t_rzrq_ys
   from DBA.T_EDW_RZRQ_hisASSETDEBIT      a
   left join dba.t_ddw_d_rq               b on a.init_date=b.rq
   left join DBA.T_EDW_RZRQ_hisASSETDEBIT c on a.client_id=c.client_id and c.init_date=@v_bin_lastday
   where a.init_date = @v_bin_date
     and a.branch_no not in(44,9999);


  commit;
   
 
    update dm.t_evt_cred_incm_d_d 
    set  
        
        a.DAY_FIN_RECE_INT =coalesce(close_finance_interest_today,0)-coalesce(close_finance_interest_lastday,0)                                  ,--������Ӧ����Ϣ
        a.DAY_FEE_RECE_INT =coalesce(close_fare_interest_today,0)-coalesce(close_fare_interest_lastday,0)                                        ,--�շ���Ӧ����Ϣ
        a.DAY_OTH_RECE_INT =coalesce(close_other_interest_today,0)-coalesce(close_other_interest_lastday,0)                                       --������Ӧ����Ϣ 
    from dm.t_evt_cred_incm_d_d a 
    left join #t_rzrq_ys        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;

   commit;
 
------------------------
  -- ��Ʊ��ѺӶ��
------------------------  
   select khbh_hs,
          sum(yj  )       as yj_d,
          sum(jyj )       as jyj_d,
          sum(case when rq =@v_bin_date then  sslx end ) 
             - sum(case when rq =@v_bin_lastday then  sslx                            end )      as sslx_d,
          sum(case when rq =@v_bin_date then  yswslx+sslx end ) 
             - sum(case when rq =@v_bin_lastday then  yswslx+sslx                     end )      as yslx_d 
   into #t_gpzyyj
   from dba.t_ddw_gpzyhg_d a
   where rq between @v_bin_lastday and  @v_bin_date
   group by khbh_hs;

   
  update dm.t_evt_cred_incm_d_d a
    set 
        a.STKPLG_CMS	    =coalesce(yj_d,0)      ,    -- ��Ʊ��ѺӶ��
	    a.STKPLG_NET_CMS	=coalesce(jyj_d,0)     ,    -- ��Ʊ��Ѻ��Ӷ��
	    a.STKPLG_PAIDINT	=coalesce(sslx_d,0)    ,    -- ��Ʊ��Ѻʵ����Ϣ
	    a.STKPLG_RECE_INT	=coalesce(yslx_d,0)         -- ��Ʊ��ѺӦ����Ϣ 
    from dm.t_evt_cred_incm_d_d a
    left join #t_gpzyyj         b on a.cust_id=b.khbh_hs
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- Լ������Ӷ��
------------------------  
    
     select a.khbh_hs as client_id, 
        SUM(a.yj)           as yj_d,    -- Լ������Ӷ��
        SUM(a.jyj)          as jyj_d ,  -- Լ�����ؾ�Ӷ��
        sum(sslx)           as sslx_d,  -- Լ������ʵ����Ϣ
        sum(yswslx+sslx)    as yslx_d 
      into #t_ydghyj
      from  dba.t_ddw_ydsgh_d   a 
      where rq = @v_bin_date
      group by a.khbh_hs ;
    

    update dm.t_evt_cred_incm_d_d 
    set 
        a.APPTBUYB_CMS	    =coalesce(yj_d,0)      ,    -- Լ������Ӷ��
	    a.APPTBUYB_NET_CMS	=coalesce(jyj_d,0)     ,    -- Լ�����ؾ�Ӷ�� 
	    a.APPTBUYB_PAIDINT	=coalesce(sslx_d,0)         -- Լ������ʵ����Ϣ 
    from dm.t_evt_cred_incm_d_d a 
    left join #t_ydghyj         b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 
 
   set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 
 
end
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_d_d TO query_dev
GO
CREATE PROCEDURE dm.p_evt_cred_incm_m_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  ������:  �ͻ�����ҵ�������±��ո��£�
  ��д��: rengz
  ��������: 2017-11-28
  ��飺�ͻ��ʽ�䶯���ݣ��ո���
        ��Ҫ���������ڣ�T_DDW_F00_KHMRZJZHHZ_D �ձ� ��ͨ�˻��ʽ� ����ֵ��������
                        tmp_ddw_khqjt_m_m     ������ȯ�ͻ��ʽ����� ����

  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
             20180124                 rengz              ��������Ϣ���зֲ�
             20180316                 rengz              1������ί�зѡ����ַ�
                                                         2���ͻ�Ⱥ���ӹ�Ʊ��Ѻ��Լ������Ŀ��ͻ�
             20180330                 rengz              ���ӱ�֤���������뼰��֤��������������
  *********************************************************************/
 
    -- declare @v_bin_date             numeric(8,0); 
    declare @v_bin_year             varchar(4); 
    declare @v_bin_mth              varchar(2); 
    declare @v_bin_qtr              varchar(2); --����
    declare @v_bin_year_start_date  numeric(8); 
    declare @v_bin_mth_start_date   numeric(8); 
    declare @v_bin_lastmth_date     numeric(8); --����ͬ��
    declare @v_bin_lastmth_year     varchar(4); --����ͬ�ڶ�Ӧ��
    declare @v_bin_lastmth_mth      varchar(2); --����ͬ�ڶ�Ӧ��
    declare @v_bin_lastmth_start_date numeric(8); --���¿�ʼ����
    declare @v_bin_lastmth_end_date numeric(8); --���½�������
    declare @v_date_num             numeric(8); --������Ȼ�յ�����
    declare @v_bin_mth_end_date     numeric(8); --���½���������
    declare @v_lcbl                 numeric(38,8); ---��֤���������
    declare @v_bin_qtr_m1_start_date  numeric(8); --�����ȵ�1���µ�һ��������
    declare @v_bin_qtr_m1_end_date    numeric(8); --�����ȵ�1�������һ��������
    declare @v_bin_qtr_m2_start_date  numeric(8); --�����ȵ�2���µ�һ��������
    declare @v_bin_qtr_m2_end_date    numeric(8); --�����ȵ�2�������һ��������
    declare @v_bin_qtr_m3_start_date  numeric(8); --�����ȵ�3���µ�һ��������
    declare @v_bin_qtr_m3_end_date    numeric(8); --�����ȵ�3�������һ��������
    declare @v_bin_qtr_end_date     numeric(8); --�����Ƚ��������� 
    declare @v_date_qtr_m1_num        numeric(8); --������Ȼ�յ�����
    declare @v_date_qtr_m2_num        numeric(8); --������Ȼ�յ�����
    declare @v_date_qtr_m3_num        numeric(8); --������Ȼ�յ�����
    
	set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date =@v_bin_date ;
	
	--������������
    set @v_bin_year=(select year from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_mth =(select mth  from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_qtr =(select qtr  from dm.t_pub_date where dt=@v_bin_date );
    set @v_bin_year_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and if_trd_day_flag=1 ); 
    set @v_bin_mth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_mth_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_qtr_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and qtr=@v_bin_qtr and if_trd_day_flag=1 ); 
    set @v_bin_lastmth_date=convert(numeric(8,0),(select dateadd(month,-1,@v_bin_date)));
    set @v_bin_lastmth_year=(select year from dm.t_pub_date where dt=@v_bin_lastmth_date ); 
    set @v_bin_lastmth_mth =(select mth  from dm.t_pub_date where dt=@v_bin_lastmth_date ); 
    set @v_bin_lastmth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_lastmth_year  and mth=@v_bin_lastmth_mth ); 
    set @v_bin_lastmth_end_date=(select max(dt) from dm.t_pub_date where year=@v_bin_lastmth_year  and mth=@v_bin_lastmth_mth ----and if_trd_day_flag=1  modify by rengz ��������ȫ�������Ϊ��Ȼ��
	                                                                                                    ); 
    set @v_date_num          =case  when @v_bin_date=@v_bin_mth_end_date then (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth )
                                    else (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and dt<=@v_bin_date) end;             --�������һ�������գ�������Ȼ��ͳ������
    set @v_lcbl              =case when coalesce((select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth),0)=0 then 
                                        (select bjzlclv from dba.t_jxfc_market where nian||yue=substr(convert(varchar,dateadd(month,-1,convert(varchar,@v_bin_date)),112),1,6)  )
                              else (select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth) end ; 
    set @v_bin_qtr_m1_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1);
    set @v_bin_qtr_m1_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and mth=(select convert(varchar,min(mth)) from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_date_qtr_m1_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date );             --�����ȵ�1������Ȼ�յ�����
    set @v_date_qtr_m2_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date );             --�����ȵ�2������Ȼ�յ�����
    set @v_date_qtr_m3_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m3_start_date and @v_bin_qtr_m3_end_date );             --�����ȵ�3������Ȼ�յ�����  
 
    --ɾ������������
    delete from dm.t_evt_cred_incm_m_d where year=@v_bin_year and mth=@v_bin_mth ;
    commit;
     

------------------------
  -- ����ÿ�տͻ��嵥��������������ҵ��Ŀͻ�ID
------------------------  
  insert into dm.t_evt_cred_incm_m_d (CUST_ID, OCCUR_DT, MAIN_CPTL_ACCT, LOAD_DT, YEAR, MTH)
  select distinct a.client_id,
                  a.load_dt,
                  b.fund_account,
                  a.load_dt as rq,
                  @v_bin_year,
                  @v_bin_mth
    from (select distinct client_id, load_dt
            from DBA.T_EDW_RZRQ_CLIENT t
           where t.load_dt = @v_bin_date
             and t.client_status = '0'
             and convert(varchar, t.branch_no) not in ('5', '55', '51', '44', '9999')
             and t.client_id <> '448999999' ----�޳�1����ר��ͷ���˻��Զ����ɡ������ƹ�˾�����˻���client_id������ͨ�˻������ж�������˻��Ҿ�Ϊ���ʽ�
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_gpzyhg_d t
           where t.rq = @v_bin_date ---��Ʊ��Ѻ
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999'
          union
          select distinct khbh_hs, rq
            from dba.t_ddw_ydsgh_d t
           where t.rq = @v_bin_date ---Լ��ʽ����
             and convert(varchar, t.jgbh_hs) not in ('5', '55', '51', '44', '9999')
             and t.khbh_hs <> '448999999') a
    left join dba.t_edw_uf2_fundaccount b
      on a.client_id = b.client_id
     and b.load_dt = @v_bin_date
     and b.fundacct_status = '0'
     and b.asset_prop = '0'
     and b.main_flag = '1';
   
   commit;
------------------------
  -- ����Ӷ�� ��Ӷ��
------------------------  
    select client_id
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare1 else 0 end )                                                                                         as yhs       --ӡ��˰ 
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare2 else 0 end )                                                                                         as ghf       --������
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then fare3 else 0 end )                                                                                         as wtf       --ί�з�  
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then EXCHANGE_FARE0 else 0 end )                                                                                as jsf       --���ַ�   
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then EXCHANGE_FARE3 else 0 end )                                                                                as zgf       --֤�ܷ�   
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then FAREX else 0 end )                                                                                         as qtfy      --��������  
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002,                                        ---��ͨ
                                                                                                  4211, 4212, 4213, 4214, 4215, 4216                 ---����
                                                                                                )  then (fare0)  else 0 end)                                                               as yj_m      --Ӷ��
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002,                                        ---��ͨ
                                                                                                    4211, 4212, 4213, 4214, 4215, 4216               ---����
                                                                                                )  then 
            	                                                                                        coalesce(fare0,0)
									                                                                    + coalesce(fare3,0)
									                                                                    + coalesce(farex,0)
									                                                                    + coalesce(fare2,0)
									                                                                    - coalesce(exchange_fare0,0)
									                                                                    - coalesce(exchange_fare3,0)
									                                                                    - coalesce(exchange_fare4,0)
									                                                                    - coalesce(exchange_fare5,0)
									                                                                    - coalesce(exchange_fare6,0)
									                                                                    - coalesce(exchange_farex,0)
									                                                                    - coalesce(exchange_fare2,0)
              		                                                                         else 0 end)                                                                                as jyj_m      --��Ӷ��
  
   ---��ͨ����
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then (fare0)  else 0 end)                                                as pt_yj_m  --��ͨ����Ӷ��
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                           as pt_jyj_m  --��ͨ���׾�Ӷ��
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4001, 4002)  then (fare2)  else 0 end)                                                as pt_ghf_m   --��ͨ���׹�����
   ---���ý���
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)                        as xy_yj_m    --���ý���Ӷ��
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                       as xy_jyj_m   --���ý��׾�Ӷ��
    ,sum(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and business_flag in (4211, 4212, 4213, 4214, 4215, 4216)  then (fare2)  else 0 end)                     as xy_ghf_m    --���ý��׹�����

    ,sum(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then (fare0)  else 0 end)                   as xy_yj_y    --���ۼ����ý���Ӷ��
    ,sum(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and business_flag in ( 4211, 4212, 4213, 4214, 4215, 4216)  then 
                    coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)  else 0 end)                                                                                                       as xy_jyj_y   --���ۼ����ý��׾�Ӷ��      
    into #t_yj   
    from DBA.T_EDW_RZRQ_HISDELIVER a
    where a.load_dt between @v_bin_year_start_date and @v_bin_date
    group by client_id;
 
    commit;
   
    update dm.t_evt_cred_incm_m_d a
    set 
	    a.GROSS_CMS	        =coalesce(yj_m,0)           , -- ëӶ��
	    a.NET_CMS	        =coalesce(jyj_m,0)          , -- ��Ӷ��
	    a.TRAN_FEE	        =coalesce(ghf,0)            , -- ������
	    a.STP_TAX	        =coalesce(yhs,0)            , -- ӡ��˰
	    a.ORDR_FEE	        =coalesce(wtf,0)            , -- ί�з�
	    a.HANDLE_FEE	    =coalesce(jsf,0)            , -- ���ַ�
	    a.SEC_RGLT_FEE	    =coalesce(zgf,0)            , -- ֤�ܷ�
	    a.OTH_FEE		    =coalesce(qtfy,0)           , -- ��������
	    a.CREDIT_ODI_CMS	    =coalesce(pt_yj_m,0)    , -- ������ȯ��ͨӶ��
	    a.CREDIT_ODI_NET_CMS	=coalesce(pt_jyj_m,0)   , -- ������ȯ��ͨ��Ӷ��
	    a.CREDIT_ODI_TRAN_FEE	=coalesce(pt_ghf_m,0)   , -- ������ȯ��ͨ������
	    a.CREDIT_CRED_CMS	    =coalesce(xy_yj_m,0)    , -- ������ȯ����Ӷ��
	    a.CREDIT_CRED_NET_CMS	=coalesce(xy_jyj_m,0)   , -- ������ȯ���þ�Ӷ��
	    a.CREDIT_CRED_TRAN_FEE	=coalesce(xy_ghf_m,0)   , -- ������ȯ���ù�����
	    a.TY_CRED_CMS	    =coalesce(xy_yj_y,0)        , -- ��������Ӷ��
	    a.TY_CRED_NET_CMS   =coalesce(xy_jyj_y,0)	      -- �������þ�Ӷ�� 
    from dm.t_evt_cred_incm_m_d  a
    left join #t_yj              b on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
 commit;
  
 

------------------------
  -- ������Ϣ
------------------------  
    ---ʵ����Ϣ�ֽ�
   select client_id
         ,sum(case when business_flag in (2219, 2812, 2822, 2832, 2842)                                 then abs(occur_balance) else 0 end) as  lxzc_rz_m
 		 ,sum(case when business_flag in (2807, 2224)                                                   then abs(occur_balance) else 0 end) as  lxzc_rq_m
         ,sum(case when business_flag in ( 2814, 2816, 2824,2826, 2834, 2836, 2844, 2846,  2220, 2221)  then abs(occur_balance) else 0 end) as  lxzc_qt_m
   into #t_rzrq_ss
   -- select *,occur_balance
   from dba.t_EDW_RZRQ_HISFUNDJOUR   
   where  init_date  between @v_bin_mth_start_date and @v_bin_date
   group by client_id;

   commit;

    update dm.t_evt_cred_incm_m_d 
    set 
     a.fin_paidint =coalesce(lxzc_rz_m,0)+coalesce(lxzc_qt_m,0)          ,--����ʵ����Ϣ
     a.MTH_FIN_IE  =coalesce(lxzc_rz_m,0)                                ,--��������Ϣ֧��
     a.MTH_CRDT_STK_IE =coalesce(lxzc_rq_m,0)                            ,--����ȯ��Ϣ֧��
     a.MTH_OTH_IE      =coalesce(lxzc_qt_m,0)                             --��������Ϣ֧��
    from dm.t_evt_cred_incm_m_d a 
    left join #t_rzrq_ss        b on a.cust_id=b.client_id
    where  a.occur_dt=@v_bin_date;

   commit;
 
   ---Ӧ����Ϣ�ֽ�
    select a.client_id
           ,b.byddjgzr  as tianshu
           ,a.close_finance_interest  as close_finance_interest_ym
           ,a.close_fare_interest     as close_fare_interest_ym  
           ,a.close_other_interest    as close_other_interest_ym  

           ,c.close_finance_interest  as close_finance_interest_sy
           ,c.close_fare_interest     as close_fare_interest_sy  
           ,c.close_other_interest    as close_other_interest_sy  
           ,a.finance_close_balance + a.CLOSE_FARE_DEBIT + a.CLOSE_OTHER_DEBIT  as rzrqzjcb_xzq    --������ȯ�ʽ�ɱ�_�������
   into #t_rzrq_ys
   from DBA.T_EDW_RZRQ_hisASSETDEBIT      a
   left join dba.t_ddw_d_rq               b on a.init_date=b.rq
   left join DBA.T_EDW_RZRQ_hisASSETDEBIT c on a.client_id=c.client_id and c.init_date=@v_bin_lastmth_end_date
   where a.init_date = @v_bin_date
     and a.branch_no not in(44,9999);


  commit;
   
 
    update dm.t_evt_cred_incm_m_d 
    set  
        a.FIN_RECE_INT =coalesce(close_finance_interest_ym,0)+coalesce(close_fare_interest_ym,0)+coalesce(close_other_interest_ym,0)          
                       -coalesce(close_finance_interest_sy,0)-coalesce(close_fare_interest_sy,0)-coalesce(close_other_interest_sy,0)     ,--����Ӧ����Ϣ
        a.MTH_FIN_RECE_INT =coalesce(close_finance_interest_ym,0)-coalesce(close_finance_interest_sy,0)                                  ,--������Ӧ����Ϣ
        a.MTH_FEE_RECE_INT =coalesce(close_fare_interest_ym,0)-coalesce(close_fare_interest_sy,0)                                        ,--�·���Ӧ����Ϣ
        a.MTH_OTH_RECE_INT =coalesce(close_other_interest_ym,0)-coalesce(close_other_interest_sy,0)                                      ,--������Ӧ����Ϣ
        a.CREDIT_CPTL_COST =coalesce(rzrqzjcb_xzq,0)*(select rzrq_ll from dba.t_jxfc_rzrq_ll where nianyue=@v_bin_year||@v_bin_mth ) / 360                --������ȯ�ʽ�ɱ�
    from dm.t_evt_cred_incm_m_d a 
    left join #t_rzrq_ys        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;

   commit;
 
------------------------
  -- ��Ʊ��ѺӶ��
------------------------  
   select khbh_hs,
          sum(case when rq between @v_bin_mth_start_date and @v_bin_date then  yj  end )       as yj_m,
          sum(case when rq between @v_bin_mth_start_date and @v_bin_date then  jyj end )       as jyj_m,
          sum(case when rq =@v_bin_date then  sslx end ) 
             - sum(case when rq =@v_bin_lastmth_end_date then  sslx                            end )      as sslx_m,
          sum(case when rq =@v_bin_date then  yswslx+sslx end ) 
             - sum(case when rq =@v_bin_lastmth_end_date then  yswslx+sslx                     end )      as yslx_m 
   into #t_gpzyyj
   from dba.t_ddw_gpzyhg_d a
   where rq between @v_bin_lastmth_start_date  and @v_bin_date
   group by khbh_hs;

   
  update dm.t_evt_cred_incm_m_d a
    set 
        a.STKPLG_CMS	    =coalesce(yj_m,0)      ,    -- ��Ʊ��ѺӶ��
	    a.STKPLG_NET_CMS	=coalesce(jyj_m,0)     ,    -- ��Ʊ��Ѻ��Ӷ��
	    a.STKPLG_PAIDINT	=coalesce(sslx_m,0)      ,  -- ��Ʊ��Ѻʵ����Ϣ
	    a.STKPLG_RECE_INT	=coalesce(yslx_m,0)         -- ��Ʊ��ѺӦ����Ϣ 
    from dm.t_evt_cred_incm_m_d a
    left join #t_gpzyyj         b on a.cust_id=b.khbh_hs
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- Լ������Ӷ��
------------------------  
    
     select a.khbh_hs as client_id, 
        SUM(a.yj)           as yj_m,    -- Լ������Ӷ��
        SUM(a.jyj)          as jyj_m ,  -- Լ�����ؾ�Ӷ��
        sum(sslx)           as sslx_m,  -- Լ������ʵ����Ϣ
        sum(yswslx+sslx)    as yslx_m 
      into #t_ydghyj
      from  dba.t_ddw_ydsgh_d   a 
      where rq between @v_bin_mth_start_date and @v_bin_date
      group by a.khbh_hs ;
    

    update dm.t_evt_cred_incm_m_d 
    set 
        a.APPTBUYB_CMS	    =coalesce(yj_m,0)      ,    -- Լ������Ӷ��
	    a.APPTBUYB_NET_CMS	=coalesce(jyj_m,0)     ,    -- Լ�����ؾ�Ӷ�� 
	    a.APPTBUYB_PAIDINT	=coalesce(sslx_m,0)         -- Լ������ʵ����Ϣ 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_ydghyj         b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 

------------------------
  -- ������ȯ_���㱣֤����������_���ۼ�
------------------------  

   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- ���ۼƺ������֤��  "max(�˻��ֽ�-max(����ծ-�ͻ��ύ�����ʲ������������,0),0) �����ʲ�����ֵ���ֽ�Ϊ��Ȼ���ۼ�"
          ,coalesce(hsbzj,0)/@v_date_num                                               as rzrq_hsbzj_yrj       -- ������ȯ_���㱣֤��_���վ�
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- ������ȯ_���㱣֤����������_���ۼ�
   into #t_bzjlcsr
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between  @v_bin_mth_start_date AND @v_bin_date
   group by client_id;

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- ������ȯ��֤���������� 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr        b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_date;
    commit; 


------------------------
  -- ����������2�����µ�������ȯ_���㱣֤����������_���ۼ�
------------------------  

 
  if @v_bin_date= @v_bin_qtr_end_date
  then 
 
  ---�����ȵ�1��
   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- ���ۼƺ������֤��  "max(�˻��ֽ�-max(����ծ-�ͻ��ύ�����ʲ������������,0),0) �����ʲ�����ֵ���ֽ�Ϊ��Ȼ���ۼ�"
          ,coalesce(hsbzj,0)/@v_date_qtr_m1_num                                        as rzrq_hsbzj_yrj       -- ������ȯ_���㱣֤��_���վ�
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- ������ȯ_���㱣֤����������_���ۼ�
   into #t_bzjlcsr_qrt_m1
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between  @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date
   group by client_id;

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM_CET	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- ������ȯ��֤����������_���� 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr_qrt_m1 b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_qtr_m1_end_date;
  commit; 


  ---�����ȵ�2��
   select  client_id
          ,max(finance_close_balance+shortsell_close_balance+close_fare_debit+close_other_debit) as fuzai
          ,max(close_market_value_assure+current_balance) as dbsz
          ,case when fuzai-dbsz<0 then 0 else fuzai-dbsz end as wh
          ,case when max(current_balance)-wh<0 then 0 else max(current_balance)-wh end as hsbzj                -- ���ۼƺ������֤��  "max(�˻��ֽ�-max(����ծ-�ͻ��ύ�����ʲ������������,0),0) �����ʲ�����ֵ���ֽ�Ϊ��Ȼ���ۼ�"
          ,coalesce(hsbzj,0)/@v_date_qtr_m2_num                                        as rzrq_hsbzj_yrj       -- ������ȯ_���㱣֤��_���վ�
          ,rzrq_hsbzj_yrj * @v_lcbl      AS rzrq_hsbzjlcsr_m                                                   -- ������ȯ_���㱣֤����������_���ۼ�
   into #t_bzjlcsr_qrt_m2
-- select *
   from dba.T_EDW_RZRQ_HISASSETDEBIT
   where init_date between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date
   group by client_id;
  commit;
  

    update dm.t_evt_cred_incm_m_d 
    set  a.CREDIT_MARG_SPR_INCM_CET	    =coalesce(rzrq_hsbzjlcsr_m,0)           -- ������ȯ��֤����������_���� 
    from dm.t_evt_cred_incm_m_d a 
    left join #t_bzjlcsr_qrt_m2 b  on a.cust_id=b.client_id
    where a.occur_dt=@v_bin_qtr_m2_end_date;
  commit; 
 
  end if;
 

   set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 
 
end
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_m_d TO query_dev
GO
GRANT EXECUTE ON dm.p_evt_cred_incm_m_d TO xydc
GO
CREATE PROCEDURE dm.P_EVT_CUS_ODI_TRD_M_D(IN @v_date int)
begin 
  
  /******************************************************************
  ������: �ͻ���ͨ������ʵ���´洢�ո��£�
  ��д��: ����
  ��������: 2017-12-06
  ��飺��ͨ�������ף��������ڣ��Ľ���ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  
  declare @v_year varchar(4);		-- ���
  declare @v_month varchar(2);	-- �·�
  declare @v_begin_trad_date int;	-- ���¿�ʼ������
  
	commit;
	
	set @v_year = substring(convert(varchar,@v_date),1,4);
	set @v_month = substring(convert(varchar,@v_date),5,2);
	set @v_begin_trad_date = (select min(RQ) from dba.t_ddw_d_rq where sfjrbz='1' and nian=@v_year and yue=@v_month);

  
	DELETE FROM DM.T_EVT_CUS_ODI_TRD_M_D WHERE "YEAR"=@v_year AND MTH=@v_month;

	INSERT INTO DM.T_EVT_CUS_ODI_TRD_M_D(
		CUST_ID
		,OCCUR_DT
		,"YEAR"
		,MTH
		,MAIN_CPTL_ACCT
		,LOAD_DT
	)
	SELECT a.client_id as CUST_ID
		,@v_date as OCCUR_DT
		,@v_year as "YEAR"
		,@v_month as MTH
		,b.MAIN_CPTL_ACCT
		,@v_date AS LOAD_DT
	FROM DBA.T_EDW_UF2_CLIENT a
	LEFT JOIN (
		SELECT CLIENT_ID, MAX(FUND_ACCOUNT) AS MAIN_CPTL_ACCT
		FROM DBA.T_EDW_UF2_FUNDACCOUNT
		WHERE LOAD_DT=@v_date
		AND MAIN_FLAG='1' AND ASSET_PROP='0'
		GROUP BY CLIENT_ID
	) b on a.CLIENT_ID=b.CLIENT_ID
	WHERE a.LOAD_DT=@v_date;

	-- ëӶ�� ��Ӷ�� ���������� �ɻ������� ���ع������� ��ع������� ����ͨ������ ���ͨ������
	UPDATE DM.T_EVT_CUS_ODI_TRD_M_D
	SET GROSS_CMS = COALESCE(b.GROSS_CMS,0)
		,NET_CMS = coalesce(b.NET_CMS,0)
		,SCDY_TRD_QTY = coalesce(b.SCDY_TRD_QTY,0)
		,STKF_TRD_QTY = coalesce(b.STKF_TRD_QTY,0)
		,S_REPUR_TRD_QTY = coalesce(b.S_REPUR_TRD_QTY,0)
		,R_REPUR_TRD_QTY = coalesce(b.R_REPUR_TRD_QTY,0)
		,HGT_TRD_QTY = coalesce(b.HGT_TRD_QTY,0)
		,SGT_TRD_QTY = coalesce(b.SGT_TRD_QTY,0)
	FROM DM.T_EVT_CUS_ODI_TRD_M_D a
	LEFT JOIN (
		SELECT a.zjzh
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as GROSS_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb else 0 end) as NET_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.cjje*b.turn_rmb else 0 end) as SCDY_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102')  
				and (a.zqlx in ('10', 'A1','17', '18',@v_month,'1A','74','75')
					or (a.sclx in ('01','02') and a.zqlx='19'))
				then a.cjje*b.turn_rmb else 0 end
				) as STKF_TRD_QTY
			,sum(case when a.busi_type_cd='3701' then a.cjje*b.turn_rmb else 0 end) as S_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd='3703' then a.cjje*b.turn_rmb else 0 end) as R_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0G' then a.cjje*b.turn_rmb else 0 end) as HGT_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0S' then a.cjje*b.turn_rmb else 0 end) as SGT_TRD_QTY
		FROM dba.t_ddw_f00_khzqhz_d as a 
		left outer join dba.t_edw_t06_year_exchange_rate as b on a.load_dt between b.star_dt and b.end_dt 
			and b.curr_type_cd = 
			   case when a.zqlx = '18' and a.sclx = '05' then 'USD'
			   when a.zqlx = '17' then 'USD'
			   when a.zqlx = '18' then 'HKD' else 'CNY'
			   end
		where a.LOAD_DT between @v_begin_trad_date and @v_date
		group by a.zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	where a.YEAR=@v_year and a.MTH=@v_month;


	-- ���ڽ�����
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set BGDL_QTY = coalesce(b.BGDL_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as BGDL_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between  @v_begin_trad_date and @v_date
		and busi_type_cd in ('3101', '3102') and note like '%����%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;


	-- ��Ʊ��Ѻ������
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set STKPLG_TRD_QTY = coalesce(b.STKPLG_TRD_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as STKPLG_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between @v_begin_trad_date and @v_date
		and note like '%��Ʊ��Ѻ%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- Լ�����ؽ�����
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set APPTBUYB_TRD_QTY = coalesce(b.APPTBUYB_TRD_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as APPTBUYB_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between @v_begin_trad_date and @v_date
		and note like '%Լ��ʽ����%' and busi_type_cd='3101'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- ���ۻع�������
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set REPQ_TRD_QTY = coalesce(b.REPQ_TRD_QTY,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,sum(trad_amt) as REPQ_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt between @v_begin_trad_date and @v_date
		and busi_type_cd in ('3703','3704') and "stock_cd" like '205%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- ������Ȩ������
	update DM.T_EVT_CUS_ODI_TRD_M_D
	set PSTK_OPTN_TRD_QTY = coalesce(b.PSTK_OPTN_TRD_QTY,0)
	from  DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select client_id
			,sum(BUSINESS_BALANCE) as PSTK_OPTN_TRD_QTY
		from dba.T_EDW_UF2_HIS_OPTDELIVER
		where LOAD_DT between @v_begin_trad_date and @v_date
		group by client_id
	) b ON a.cust_id=b.client_id
	where a.YEAR=@v_year and a.MTH=@v_month;


	-- �������״��� �����������_����  ���״���
	UPDATE DM.T_EVT_CUS_ODI_TRD_M_D
	SET SCDY_TRD_FREQ = coalesce(b.SCDY_TRD_FREQ,0)
		,RCT_TRD_DT_M = coalesce(b.RCT_TRD_DT_M,0)
		,TRD_FREQ = coalesce(b.TRD_FREQ,0)
	FROM DM.T_EVT_CUS_ODI_TRD_M_D a
	LEFT JOIN (
		SELECT fund_acct
			,sum(case when t.market_type_cd in ('01','02','03','04','05','0G','0S') then 1 else 0 end) as SCDY_TRD_FREQ
			,max(t.load_dt) as RCT_TRD_DT_M
			,count(1) as TRD_FREQ
		FROM DBA.T_EDW_T05_TRADE_JOUR t
		WHERE LOAD_DT BETWEEN @v_begin_trad_date AND @v_date
		and busi_type_cd in ( '3101','3102','3701','3703')
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT = b.fund_acct
	where a.YEAR=@v_year and a.MTH=@v_month;

	-- �����������_�ۼ�
	/*
	UPDATE DM.T_EVT_CUS_ODI_TRD_M_D
	set RCT_TRD_DT_GT = coalesce(b.RCT_TRD_DT_GT,0)
	from DM.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select fund_acct
			,max(load_dt) as RCT_TRD_DT_GT
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt<=@v_date
		group by fund_acct
	) b on 
	where a.YEAR=@v_year and a.MTH=@v_month;
	*/

	-- �ɻ�������_���� ���ع�������_���� ��ع�������_���� ����ͨ������_���� ���ͨ������_���� ��Ʊ��Ѻ������_���� Լ�����ؽ�����_����
	-- ���ۻع�������_���� ���ڽ�����_���� ������Ȩ������_���� ���״���_���� �������״���_����
	update dm.T_EVT_CUS_ODI_TRD_M_D
	set STKF_TRD_QTY_TY = COALESCE(b.STKF_TRD_QTY_TY,0) -- �ɻ�������_����
		,S_REPUR_TRD_QTY_TY = coalesce(b.S_REPUR_TRD_QTY_TY,0)  -- ���ع�������_����
		,R_REPUR_TRD_QTY_TY = coalesce(b.R_REPUR_TRD_QTY_TY,0)  -- ��ع�������_����
		,HGT_TRD_QTY_TY = coalesce(b.HGT_TRD_QTY_TY,0)  -- ����ͨ������_����
		,SGT_TRD_QTY_TY = coalesce(b.SGT_TRD_QTY_TY,0)  -- ���ͨ������_����
		,STKPLG_TRD_QTY_TY = coalesce(b.STKPLG_TRD_QTY_TY,0)    -- ��Ʊ��Ѻ������_����
		,APPTBUYB_TRD_QTY_TY = coalesce(b.APPTBUYB_TRD_QTY_TY,0)    -- Լ�����ؽ�����_����
		,REPQ_TRD_QTY_TY = coalesce(b.REPQ_TRD_QTY_TY,0)    -- ���ۻع�������_����
		,BGDL_QTY_TY = coalesce(b.BGDL_QTY_TY,0)        -- ���ڽ�����_����
		,PSTK_OPTN_TRD_QTY_TY = coalesce(b.PSTK_OPTN_TRD_QTY_TY,0)  -- ������Ȩ������_����
		,TRD_FREQ_TY = coalesce(b.TRD_FREQ_TY,0)    -- ���״���_����
		,SCDY_TRD_FREQ_TY =  coalesce(b.SCDY_TRD_FREQ_TY,0) -- �������״���_����
	from dm.T_EVT_CUS_ODI_TRD_M_D a
	left join (
		select CUST_ID
			,sum(STKF_TRD_QTY) as STKF_TRD_QTY_TY
			,sum(S_REPUR_TRD_QTY) as S_REPUR_TRD_QTY_TY
			,sum(R_REPUR_TRD_QTY) as R_REPUR_TRD_QTY_TY
			,sum(HGT_TRD_QTY) as HGT_TRD_QTY_TY
			,sum(SGT_TRD_QTY) as SGT_TRD_QTY_TY
			,sum(STKPLG_TRD_QTY) as STKPLG_TRD_QTY_TY
			,sum(APPTBUYB_TRD_QTY) as APPTBUYB_TRD_QTY_TY
			,sum(REPQ_TRD_QTY) as REPQ_TRD_QTY_TY
			,sum(BGDL_QTY) as BGDL_QTY_TY
			,sum(PSTK_OPTN_TRD_QTY) as PSTK_OPTN_TRD_QTY_TY
			,sum(TRD_FREQ) as TRD_FREQ_TY
			,sum(SCDY_TRD_FREQ) as SCDY_TRD_FREQ_TY
		from dm.T_EVT_CUS_ODI_TRD_M_D
		where YEAR=@v_year and MTH<=@v_month
		group by CUST_ID
	) b on a.CUST_ID=b.CUST_ID
	where a.YEAR=@v_year and a.MTH=@v_month;

    -- ����������_���꣨scdy_trd_qty_ty��
    update dm.T_EVT_CUS_ODI_TRD_M_D
    set scdy_trd_qty_ty = coalesce(b.scdy_trd_qty_ty,0)
    from dm.T_EVT_CUS_ODI_TRD_M_D a 
    left join (
        select a.zjzh,
            SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.cjje*b.turn_rmb else 0 end) as scdy_trd_qty_ty  -- ����������_����
        from dba.t_ddw_f00_khzqhz_d as a 
        left outer join dba.t_edw_t06_year_exchange_rate as b on a.load_dt between b.star_dt and b.end_dt and b.curr_type_cd = 
            case when a.zqlx = '18' and a.sclx = '05' then 'USD'
            when a.zqlx = '17' then 'USD'
            when a.zqlx = '18' then 'HKD' else 'CNY'
            end 
        where a.load_dt between convert(int,@v_year||'0101') and @v_date and
        a.sclx in( '01','02','03','04','05','0G','0S')  /*2014-11-28���ӻ���ͨ�г����� 2016-11-18�������ͨ����*/
        group by a.zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.YEAR=@v_year and a.MTH=@v_month;
    
    -- PB������
    update DM.T_EVT_CUS_ODI_TRD_M_D
    set PB_TRD_QTY = coalesce(b.jyl,0)
    from DM.T_EVT_CUS_ODI_TRD_M_D a 
    left join (
        select client_id, sum(business_balance) as jyl
        from dba.t_edw_uf2_his_deliver a
        where a.business_flag in (4001,4002,4103,4104)
        and fund_account in (
            select distinct fund_account from dba.t_edw_uf2_fundaccount 
            where client_group in (30,38) and substring(convert(varchar,load_dt),1,6)=@v_year||@v_month
        ) and substring(convert(varchar,load_dt),1,6)=@v_year||@v_month
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.year=@v_year and a.mth=@v_month;

  
   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_CUS_ODI_TRD_M_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_CUS_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  ������: �ͻ�������ʵ��_�ձ�
  ��д��: ����
  ��������: 2017-12-06
  ��飺��ͨ���׵Ľ���ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

    commit;
    
    delete from dm.T_EVT_CUS_TRD_D_D where OCCUR_DT=@v_date;
    
    insert into dm.T_EVT_CUS_TRD_D_D(CUST_ID,OCCUR_DT,MAIN_CPTL_ACCT)
    SELECT a.CLIENT_ID as CUST_ID
        ,@v_date as OCCUR_DT
        ,b.MAIN_CPTL_ACCT as MAIN_CPTL_ACCT
    FROM DBA.T_EDW_UF2_CLIENT a
    LEFT JOIN (
        SELECT CLIENT_ID, MAX(FUND_ACCOUNT) AS MAIN_CPTL_ACCT
        FROM DBA.T_EDW_UF2_FUNDACCOUNT
        WHERE LOAD_DT=@v_date
        AND MAIN_FLAG='1' AND ASSET_PROP='0'
        GROUP BY CLIENT_ID
    ) b on a.CLIENT_ID=b.CLIENT_ID
    WHERE a.LOAD_DT=@v_date;
    
	-- ëӶ�� ��Ӷ�� ���������� �ɻ������� ���ع������� ��ع������� ����ͨ������ ���ͨ������
	UPDATE DM.T_EVT_CUS_TRD_D_D
	SET GROSS_CMS = COALESCE(b.GROSS_CMS,0)
		,NET_CMS = coalesce(b.NET_CMS,0)
		,SCDY_TRD_QTY = coalesce(b.SCDY_TRD_QTY,0)
		,STKF_TRD_QTY = coalesce(b.STKF_TRD_QTY,0)
		,S_REPUR_TRD_QTY = coalesce(b.S_REPUR_TRD_QTY,0)
		,R_REPUR_TRD_QTY = coalesce(b.R_REPUR_TRD_QTY,0)
		,HGT_TRD_QTY = coalesce(b.HGT_TRD_QTY,0)
		,SGT_TRD_QTY = coalesce(b.SGT_TRD_QTY,0)
	FROM DM.T_EVT_CUS_TRD_D_D a
	LEFT JOIN (
		SELECT a.zjzh
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as GROSS_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb else 0 end) as NET_CMS
			,SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.cjje*b.turn_rmb else 0 end) as SCDY_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102')  
				and (a.zqlx in ('10', 'A1','11','17', '18','1A','74','75')
					or (a.sclx in ('01','02') and a.zqlx='19'))
				then a.cjje*b.turn_rmb else 0 end
				) as STKF_TRD_QTY
			,sum(case when a.busi_type_cd='3701' then a.cjje*b.turn_rmb else 0 end) as S_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd='3703' then a.cjje*b.turn_rmb else 0 end) as R_REPUR_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0G' then a.cjje*b.turn_rmb else 0 end) as HGT_TRD_QTY
			,sum(case when a.busi_type_cd in ('3101', '3102') and a.sclx='0S' then a.cjje*b.turn_rmb else 0 end) as SGT_TRD_QTY
		FROM dba.t_ddw_f00_khzqhz_d as a 
		left outer join dba.t_edw_t06_year_exchange_rate as b on a.load_dt between b.star_dt and b.end_dt 
			and b.curr_type_cd = 
			   case when a.zqlx = '18' and a.sclx = '05' then 'USD'
			   when a.zqlx = '17' then 'USD'
			   when a.zqlx = '18' then 'HKD' else 'CNY'
			   end
		where a.LOAD_DT = @v_date
		group by a.zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	where a.occur_dt=@v_date;
    
	-- ��Ʊ��Ѻ������
/*
	update DM.T_EVT_CUS_TRD_D_D
	set STKPLG_TRD_QTY = coalesce(b.STKPLG_TRD_QTY,0)
	from DM.T_EVT_CUS_TRD_D_D a
	left join (
		select fund_acct
			,sum(trad_amt) as STKPLG_TRD_QTY
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt = @v_date
		and note like '%��Ʊ��Ѻ%'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.occur_dt=@v_date;
*/
    
	update DM.T_EVT_CUS_TRD_D_D
	set APPTBUYB_TRD_QTY = coalesce(b.APPTBUYB_TRD_QTY,0)
        ,apptbuyb_trd_amt = coalesce(b.apptbuyb_trd_amt,0)
	from DM.T_EVT_CUS_TRD_D_D a
	left join (
		select fund_acct
			,sum(trad_num) as APPTBUYB_TRD_QTY  -- Լ�����ؽ�����
            ,sum(trad_amt) as apptbuyb_trd_amt  -- Լ�����ؽ��׽��
		from dba.T_EDW_T05_TRADE_JOUR
		where load_dt = @v_date
		and note like '%Լ��ʽ����%' and busi_type_cd='3101'
		group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.fund_acct
	where a.occur_dt=@v_date;
    
    -- Լ�����ػ�����,Լ�����ع��ؽ��
    update DM.T_EVT_CUS_TRD_D_D
    set apptbuyb_rep_amt = coalesce(b.apptbuyb_rep_amt,0)
        ,apptbuyb_buyb_amt = coalesce(b.apptbuyb_rep_amt,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select zjzh
            ,sum(fz) as apptbuyb_rep_amt
        from dba.t_ddw_ydsgh_d
        where rq=@v_date
        group by zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.occur_dt=@v_date;

	-- ������Ȩ������
	update DM.T_EVT_CUS_TRD_D_D
	set PSTK_OPTN_TRD_QTY = coalesce(b.PSTK_OPTN_TRD_QTY,0)
	from  DM.T_EVT_CUS_TRD_D_D a
	left join (
		select client_id
			,sum(BUSINESS_BALANCE) as PSTK_OPTN_TRD_QTY
		from dba.T_EDW_UF2_HIS_OPTDELIVER
		where LOAD_DT = @v_date
		group by client_id
	) b ON a.cust_id=b.client_id
	where a.occur_dt=@v_date;



    UPDATE DM.T_EVT_CUS_TRD_D_D
    SET credit_cred_trd_qty = coalesce(b.credit_cred_trd_qty,0)
        ,credit_odi_trd_qty = coalesce(b.credit_odi_trd_qty,0)
        ,credit_trd_qty = coalesce(b.credit_trd_qty,0)
        ,CCB_CNT = coalesce(b.CCB_CNT,0)
        ,CCB_AMT = coalesce(b.CCB_AMT,0)
        ,FIN_SELL_CNT = coalesce(b.FIN_SELL_CNT,0)
        ,FIN_SELL_AMT = coalesce(b.FIN_SELL_AMT,0)
        ,CRDT_STK_BUYIN_CNT = coalesce(b.CRDT_STK_BUYIN_CNT,0)
        ,CRDT_STK_BUYIN_AMT = coalesce(b.CRDT_STK_BUYIN_AMT,0)
        ,CSS_CNT = coalesce(b.CSS_CNT,0)
        ,CSS_AMT = coalesce(b.CSS_AMT,0)
    FROM DM.T_EVT_CUS_TRD_D_D a
    left join (
        select CLIENT_ID
            ,SUM(case when business_flag in( 4211,4212,4213,4214,4215,4216) then business_balance else 0 end) as credit_cred_trd_qty    -- �����˻����ý�����
            ,SUM(case when business_flag in( 4001,4002) then business_balance else 0 end) as credit_odi_trd_qty -- �����˻���ͨ������
            ,credit_cred_trd_qty + credit_odi_trd_qty as credit_trd_qty -- ������ȯ������
            ,sum(case when business_flag=4211 then 1 else 0 end) as CCB_CNT  -- �����������
            ,sum(case when business_flag=4211 then business_balance else 0 end) as CCB_AMT  -- ����������
            ,sum(case when business_flag=4212 then 1 else 0 end) as FIN_SELL_CNT  -- ������������
            ,sum(case when business_flag=4212 then business_balance else 0 end) as FIN_SELL_AMT  -- �����������
            ,sum(case when business_flag=4213 then 1 else 0 end) as CRDT_STK_BUYIN_CNT  -- ��ȯ�������
            ,sum(case when business_flag=4213 then business_balance else 0 end) as CRDT_STK_BUYIN_AMT  -- ��ȯ������
            ,sum(case when business_flag=4214 then 1 else 0 end) as CSS_CNT  -- ��ȯ��������
            ,sum(case when business_flag=4214 then business_balance else 0 end) as CSS_AMT  -- ��ȯ�������
    -- select *
        from dba.t_edw_rzrq_hisdeliver
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;
    
    
    
    
    update DM.T_EVT_CUS_TRD_D_D 
    set FIN_AMT = coalesce(b.FIN_AMT,0)
        ,CRDT_STK_AMT = coalesce(b.CRDT_STK_AMT,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select client_id
            ,sum(finance_close_balance) as FIN_AMT  -- ���ʽ��
            ,sum(shortsell_close_balance) as CRDT_STK_AMT  -- ��ȯ���
        -- select *
        from dba.t_edw_rzrq_hisassetdebit
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;
    
    
    
      select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE into
        #tmp_edw_t05_trade_jour from(
        select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE from
          dba.t_edw_t05_trade_jour where
          load_dt = @v_date and
          note like '��Ʊ��Ѻ��ʼ����,���뷽�ʽ���%' union
        select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE from
          dba.t_edw_t05_trade_jour where
          load_dt = @v_date and
          note like '��Ʊ��Ѻ���ؽ���,���뷽�ʽ𻮳�%' union
        select
     trad_jour_seq_no,load_dt,seq_no,occur_dt,occur_time,oper_org_cd,org_cd,fund_acct,brok_acct,curr_type_cd,stock_acct,busi_cd,order_way_cd,order_seq_no,seat_cd,market_type_cd,trad_num,trad_price,trad_amt,bargain_amt,curr_fund_bal,curr_stock_bal,stad_comm,fact_comm,third_back_comm,stamp_tax,trans_fee,handle_fee,stock_mana_fee,other_fee,operator_cd,station_cd,note,nati_debt_int,stock_cd,stock_type_cd,offer_acct,bank_cd,front_fee,clear_fee,depo_type_cd,depo_bank,busi_type_cd,fund_acct_z,PRIMARY_EXCHANGE_FEE,PRIMARY_FEE,PRIMARY_OTHER_FEE,PRIMARY_RISK_FEE,PRIMARY_TRANS_FEE from
          dba.t_edw_t05_trade_jour where
          load_dt = @v_date and
          note like '��Ʊ��Ѻ������Ѻ%') as t;
    
    update DM.T_EVT_CUS_TRD_D_D
    set STKPLG_BUYB_CNT = coalesce(b.STKPLG_BUYB_CNT,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
    select fund_acct
        ,SUM(case when note like '%���ؽ���%' then 1 else 0 end) as STKPLG_BUYB_CNT -- ��Ʊ��Ѻ���ر���
    from #tmp_edw_t05_trade_jour
    group by fund_acct
    ) b on a.main_cptl_acct=b.fund_acct
    where a.occur_dt=@v_date;
    
    update DM.T_EVT_CUS_TRD_D_D
    set STKPLG_TRD_QTY = coalesce(b.STKPLG_TRD_QTY,0)
        ,STKPLG_BUYB_AMT = coalesce(b.STKPLG_BUYB_AMT,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select khbh_hs
            ,sum(csjyje+ghjyje) as STKPLG_TRD_QTY   -- ��Ʊ��Ѻ������
            ,sum(ghjyje) as STKPLG_BUYB_AMT -- ��Ʊ��Ѻ���ؽ��
        -- select *
        from dba.t_ddw_gpzyhg_d 
        where rq=@v_date
        group by khbh_hs
    ) b on a.cust_id=b.khbh_hs
    where a.occur_dt=@v_date;
    
    update DM.T_EVT_CUS_TRD_D_D
    set OFFUND_TRD_QTY = coalesce(b.OFFUND_TRD_QTY,0)
        ,OPFUND_TRD_QTY = coalesce(b.OPFUND_TRD_QTY,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select zjzh
            ,sum(cnje_rgqr_d+cnje_sgqr_d+cnje_dsdetzqr_d+cnje_shqr_d+cnje_jymr_d+cnje_jymc_d) as OFFUND_TRD_QTY -- ���ڻ�������
            ,sum(cwje_rgqr_d+cwje_sgqr_d+cwje_dsdetzqr_d+cwje_zhrqr_d+cwje_zhcqr_d+cwje_shqr_d) as OPFUND_TRD_QTY   -- �����������
        -- select *
        from dba.t_ddw_xy_jjzb_d
        where rq=@v_date
        group by zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.occur_dt=@v_date;
    
    
    update DM.T_EVT_CUS_TRD_D_D 
    set BANK_CHRM_TRD_QTY = coalesce(b.BANK_CHRM_TRD_QTY,0)
    from DM.T_EVT_CUS_TRD_D_D a 
    left join (
        select client_id
            ,sum(case when business_flag in (43130,43142) then abs(entrust_balance) else 0 end) as BANK_CHRM_TRD_QTY    -- ������ƽ�����
        -- select *
        from dba.T_EDW_UF2_HIS_BANKMDELIVER
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;
    
    
    update DM.T_EVT_CUS_TRD_D_D 
    set SECU_CHRM_TRD_QTY = coalesce(b.SECU_CHRM_TRD_QTY,0)
    from DM.T_EVT_CUS_TRD_D_D a
    left join (
        select client_id
            ,sum(business_balance) as SECU_CHRM_TRD_QTY -- ֤ȯ��ƽ�����
        -- select *
        from dba.GT_ODS_ZHXT_HIS_SECUMDELIVER
        where init_date=@v_date
        group by client_id
    ) b on a.cust_id=b.client_id
    where a.occur_dt=@v_date;

    -- ���ʹ黹�����޿ھ�����0��
    update DM.T_EVT_CUS_TRD_D_D a
    set fin_rtn_amt = 0
    where a.occur_dt=@v_date;

commit;


end
GO
GRANT EXECUTE ON dm.P_EVT_CUS_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_CUS_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д����ͻ�������ʵ�±�
  ��д��: DCY
  ��������: 2018-02-28
  ��飺�ͻ�������ʵ�±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --��Ȼ��_�³�
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --��Ȼ��_��ĩ
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --������_�³�
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --������_��ĩ
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --��Ȼ��_���
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --������_���
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --��������_��
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --��������_��


    ----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 ɾ����������
  DELETE FROM DM.T_EVT_CUS_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_EVT_CUS_TRD_M_D 
	(
	 CUST_ID   
    ,OCCUR_DT	 
	,YEAR                 
	,MTH                  
	,NATRE_DAYS_MTH       
	,NATRE_DAYS_YEAR      
	,YEAR_MTH             
	,YEAR_MTH_CUST_ID     
	,STKF_TRD_QTY_MDA 
	,SCDY_TRD_QTY_MDA     
	,CREDIT_ODI_TRD_QTY_MDA 
	,CREDIT_CRED_TRD_QTY_MDA 
	,STKF_TRD_QTY_MTD     
	,SCDY_TRD_QTY_MTD     
	,S_REPUR_TRD_QTY_MTD  
	,R_REPUR_TRD_QTY_MTD  
	,HGT_TRD_QTY_MTD      
	,SGT_TRD_QTY_MTD      
	,STKPLG_TRD_QTY_MTD   
	,APPTBUYB_TRD_QTY_MTD 
	,CREDIT_TRD_QTY_MTD   
	,OFFUND_TRD_QTY_MTD   
	,OPFUND_TRD_QTY_MTD   
	,BANK_CHRM_TRD_QTY_MTD 
	,SECU_CHRM_TRD_QTY_MTD 
	,CREDIT_ODI_TRD_QTY_MTD 
	,CREDIT_CRED_TRD_QTY_MTD 
	,FIN_AMT_MTD          
	,CRDT_STK_AMT_MTD     
	,STKPLG_BUYB_AMT_MTD  
	,PSTK_OPTN_TRD_QTY_MTD 
	,GROSS_CMS_MTD        
	,NET_CMS_MTD          
	,STKPLG_BUYB_CNT_MTD  
	,CCB_AMT_MTD          
	,CCB_CNT_MTD          
	,FIN_SELL_AMT_MTD     
	,FIN_SELL_CNT_MTD     
	,CRDT_STK_BUYIN_AMT_MTD 
	,CRDT_STK_BUYIN_CNT_MTD 
	,CSS_AMT_MTD          
	,CSS_CNT_MTD          
	,FIN_RTN_AMT_MTD      
	,APPTBUYB_REP_AMT_MTD 
	,APPTBUYB_BUYB_AMT_MTD 
	,APPTBUYB_TRD_AMT_MTD 
	,STKF_TRD_QTY_YDA     
	,SCDY_TRD_QTY_YDA     
	,CREDIT_ODI_TRD_QTY_YDA 
	,CREDIT_CRED_TRD_QTY_YDA 
	,STKF_TRD_QTY_YTD     
	,SCDY_TRD_QTY_YTD     
	,S_REPUR_TRD_QTY_YTD  
	,R_REPUR_TRD_QTY_YTD  
	,HGT_TRD_QTY_YTD      
	,SGT_TRD_QTY_YTD      
	,STKPLG_TRD_QTY_YTD   
	,APPTBUYB_TRD_QTY_YTD 
	,CREDIT_TRD_QTY_YTD   
	,OFFUND_TRD_QTY_YTD   
	,OPFUND_TRD_QTY_YTD   
	,BANK_CHRM_TRD_QTY_YTD 
	,SECU_CHRM_TRD_QTY_YTD 
	,CREDIT_ODI_TRD_QTY_YTD 
	,CREDIT_CRED_TRD_QTY_YTD 
	,FIN_AMT_YTD          
	,CRDT_STK_AMT_YTD     
	,STKPLG_BUYB_AMT_YTD  
	,PSTK_OPTN_TRD_QTY_YTD 
	,GROSS_CMS_YTD        
	,NET_CMS_YTD          
	,STKPLG_BUYB_CNT_YTD  
	,CCB_AMT_YTD          
	,CCB_CNT_YTD          
	,FIN_SELL_AMT_YTD     
	,FIN_SELL_CNT_YTD     
	,CRDT_STK_BUYIN_AMT_YTD 
	,CRDT_STK_BUYIN_CNT_YTD 
	,CSS_AMT_YTD          
	,CSS_CNT_YTD          
	,FIN_RTN_AMT_YTD      
	,APPTBUYB_REP_AMT_YTD 
	,APPTBUYB_BUYB_AMT_YTD 
	,APPTBUYB_TRD_AMT_YTD 
	,LOAD_DT        
	)
select
	t1.CUST_ID as �ͻ�����	
	,@V_BIN_DATE as occur_dt
	,t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��		
	,t_rq.��||t_rq.�� as ����
	,t_rq.��||t_rq.��||t1.CUST_ID as ���¿ͻ�����
	
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.STKF_TRD_QTY,0) else 0 end)/t_rq.��Ȼ����_�� as �ɻ�������_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SCDY_TRD_QTY,0) else 0 end)/t_rq.��Ȼ����_�� as ����������_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CREDIT_ODI_TRD_QTY,0) else 0 end)/t_rq.��Ȼ����_�� as �����˻���ͨ������_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CREDIT_CRED_TRD_QTY,0) else 0 end)/t_rq.��Ȼ����_�� as �����˻����ý�����_���վ�
	
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.STKF_TRD_QTY,0) else 0 end) as �ɻ�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SCDY_TRD_QTY,0) else 0 end) as ����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.S_REPUR_TRD_QTY,0) else 0 end) as ���ع�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.R_REPUR_TRD_QTY,0) else 0 end) as ��ع�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.HGT_TRD_QTY,0) else 0 end) as ����ͨ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SGT_TRD_QTY,0) else 0 end) as ���ͨ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.STKPLG_TRD_QTY,0) else 0 end) as ��Ʊ��Ѻ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.APPTBUYB_TRD_QTY,0) else 0 end) as Լ�����ؽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CREDIT_TRD_QTY,0) else 0 end) as ������ȯ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OFFUND_TRD_QTY,0) else 0 end) as ���ڻ�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OPFUND_TRD_QTY,0) else 0 end) as �����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.BANK_CHRM_TRD_QTY,0) else 0 end) as ������ƽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.SECU_CHRM_TRD_QTY,0) else 0 end) as ֤ȯ��ƽ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CREDIT_ODI_TRD_QTY,0) else 0 end) as �����˻���ͨ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CREDIT_CRED_TRD_QTY,0) else 0 end) as �����˻����ý�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FIN_AMT,0) else 0 end) as ���ʽ��_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CRDT_STK_AMT,0) else 0 end) as ��ȯ���_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.STKPLG_BUYB_AMT,0) else 0 end) as ��Ʊ��Ѻ���ؽ��_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.PSTK_OPTN_TRD_QTY,0) else 0 end) as ������Ȩ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.GROSS_CMS,0) else 0 end) as ëӶ��_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.NET_CMS,0) else 0 end) as ��Ӷ��_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.STKPLG_BUYB_CNT,0) else 0 end) as ��Ʊ��Ѻ���ر���_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CCB_AMT,0) else 0 end) as ����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CCB_CNT,0) else 0 end) as �����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FIN_SELL_AMT,0) else 0 end) as �����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FIN_SELL_CNT,0) else 0 end) as ������������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CRDT_STK_BUYIN_AMT,0) else 0 end) as ��ȯ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CRDT_STK_BUYIN_CNT,0) else 0 end) as ��ȯ�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CSS_AMT,0) else 0 end) as ��ȯ�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.CSS_CNT,0) else 0 end) as ��ȯ��������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.FIN_RTN_AMT,0) else 0 end) as ���ʹ黹���_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.APPTBUYB_REP_AMT,0) else 0 end) as Լ�����ػ�����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.APPTBUYB_BUYB_AMT,0) else 0 end) as Լ�����ع��ؽ��_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.APPTBUYB_TRD_AMT,0) else 0 end) as Լ�����ؽ��׽��_���ۼ�

	,sum(COALESCE(t1.STKF_TRD_QTY,0))/t_rq.��Ȼ����_�� as �ɻ�������_���վ�
	,sum(COALESCE(t1.SCDY_TRD_QTY,0))/t_rq.��Ȼ����_�� as ����������_���վ�
	,sum(COALESCE(t1.CREDIT_ODI_TRD_QTY,0))/t_rq.��Ȼ����_�� as �����˻���ͨ������_���վ�
	,sum(COALESCE(t1.CREDIT_CRED_TRD_QTY,0))/t_rq.��Ȼ����_�� as �����˻����ý�����_���վ�
	
	,sum(COALESCE(t1.STKF_TRD_QTY,0)) as �ɻ�������_���ۼ�
	,sum(COALESCE(t1.SCDY_TRD_QTY,0)) as ����������_���ۼ�
	,sum(COALESCE(t1.S_REPUR_TRD_QTY,0)) as ���ع�������_���ۼ�
	,sum(COALESCE(t1.R_REPUR_TRD_QTY,0)) as ��ع�������_���ۼ�
	,sum(COALESCE(t1.HGT_TRD_QTY,0)) as ����ͨ������_���ۼ�
	,sum(COALESCE(t1.SGT_TRD_QTY,0)) as ���ͨ������_���ۼ�
	,sum(COALESCE(t1.STKPLG_TRD_QTY,0)) as ��Ʊ��Ѻ������_���ۼ�
	,sum(COALESCE(t1.APPTBUYB_TRD_QTY,0)) as Լ�����ؽ�����_���ۼ�
	,sum(COALESCE(t1.CREDIT_TRD_QTY,0)) as ������ȯ������_���ۼ�
	,sum(COALESCE(t1.OFFUND_TRD_QTY,0)) as ���ڻ�������_���ۼ�
	,sum(COALESCE(t1.OPFUND_TRD_QTY,0)) as �����������_���ۼ�
	,sum(COALESCE(t1.BANK_CHRM_TRD_QTY,0)) as ������ƽ�����_���ۼ�
	,sum(COALESCE(t1.SECU_CHRM_TRD_QTY,0)) as ֤ȯ��ƽ�����_���ۼ�
	,sum(COALESCE(t1.CREDIT_ODI_TRD_QTY,0)) as �����˻���ͨ������_���ۼ�
	,sum(COALESCE(t1.CREDIT_CRED_TRD_QTY,0)) as �����˻����ý�����_���ۼ�
	,sum(COALESCE(t1.FIN_AMT,0)) as ���ʽ��_���ۼ�
	,sum(COALESCE(t1.CRDT_STK_AMT,0)) as ��ȯ���_���ۼ�
	,sum(COALESCE(t1.STKPLG_BUYB_AMT,0)) as ��Ʊ��Ѻ���ؽ��_���ۼ�
	,sum(COALESCE(t1.PSTK_OPTN_TRD_QTY,0)) as ������Ȩ������_���ۼ�
	,sum(COALESCE(t1.GROSS_CMS,0)) as ëӶ��_���ۼ�
	,sum(COALESCE(t1.NET_CMS,0)) as ��Ӷ��_���ۼ�
	,sum(COALESCE(t1.STKPLG_BUYB_CNT,0)) as ��Ʊ��Ѻ���ر���_���ۼ�
	,sum(COALESCE(t1.CCB_AMT,0)) as ����������_���ۼ�
	,sum(COALESCE(t1.CCB_CNT,0)) as �����������_���ۼ�
	,sum(COALESCE(t1.FIN_SELL_AMT,0)) as �����������_���ۼ�
	,sum(COALESCE(t1.FIN_SELL_CNT,0)) as ������������_���ۼ�
	,sum(COALESCE(t1.CRDT_STK_BUYIN_AMT,0)) as ��ȯ������_���ۼ�
	,sum(COALESCE(t1.CRDT_STK_BUYIN_CNT,0)) as ��ȯ�������_���ۼ�
	,sum(COALESCE(t1.CSS_AMT,0)) as ��ȯ�������_���ۼ�
	,sum(COALESCE(t1.CSS_CNT,0)) as ��ȯ��������_���ۼ�
	,sum(COALESCE(t1.FIN_RTN_AMT,0)) as ���ʹ黹���_���ۼ�
	,sum(COALESCE(t1.APPTBUYB_REP_AMT,0)) as Լ�����ػ�����_���ۼ�
	,sum(COALESCE(t1.APPTBUYB_BUYB_AMT,0)) as Լ�����ع��ؽ��_���ۼ�
	,sum(COALESCE(t1.APPTBUYB_TRD_AMT,0)) as Լ�����ؽ��׽��_���ۼ�
	,@V_BIN_DATE

from
(
	select
		@V_BIN_YEAR as ��
		,@V_BIN_MTH as ��
		,t1.DT as ����
		,t1.TRD_DT as ��������
		,@V_BIN_NATRE_DAY_MTHBEG    as ��Ȼ��_�³�
		,@V_BIN_NATRE_DAY_MTHEND    as ��Ȼ��_��ĩ
		,@V_BIN_TRD_DAY_MTHBEG      as ������_�³�
		,@V_BIN_TRD_DAY_MTHEND      as ������_��ĩ
		,@V_BIN_NATRE_DAY_YEARBGN   as ��Ȼ��_���
		,@V_BIN_TRD_DAY_YEARBGN     as ������_���
		,@V_BIN_NATRE_DAYS_MTH      as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_MTH        as ��������_��
		,@V_BIN_NATRE_DAYS_YEAR     as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_YEAR       as ��������_��
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE
 	  and t1.IF_TRD_DAY_FLAG=1
) t_rq
left join DM.T_EVT_CUS_TRD_D_D t1 on t_rq.����=t1.OCCUR_DT
group by
	t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��		
	,t1.CUST_ID
	,����
	,���¿ͻ�����
;

END
GO
CREATE PROCEDURE dm.P_EVT_CUST_OACT_FEE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: �ͻ������ѱ�
  ��д��: DCY �ο��������ṩ��ȡ���߼�
  ��������: 2018-01-17
  ��飺
  *********************************************************************
  �޶���¼��   �޶�����    �޶���     �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    DECLARE @NIAN VARCHAR(4);		--����_���
	DECLARE @YUE VARCHAR(2)	;		--����_�·�
	DECLARE @ZRR_NC INT;            --��Ȼ��_�³�
	DECLARE @ZRR_YC INT;            --��Ȼ��_��� 
	DECLARE @TD_YM INT;				--��ĩ
	DECLARE @NY INT;
	
	
	DECLARE @ZRR_YM INT;            --��Ȼ��_��ĩ
	
    SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1

    SET @NIAN=SUBSTR(@V_BIN_DATE||'',1,4);
	SET @YUE=SUBSTR(@V_BIN_DATE||'',5,2);
   	SET @ZRR_NC=(SELECT MIN(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.����>=CONVERT(INT,@NIAN||'0101'));
	SET @ZRR_YC=(SELECT MIN(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.����>=CONVERT(INT,@NIAN||@YUE||'01'));
	SET @TD_YM=(SELECT MAX(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.�Ƿ�����='1' AND T1.����<=CONVERT(INT,@NIAN||@YUE||'31'));
    SET @NY=CONVERT(INT,@NIAN||@YUE);
	
	SET @ZRR_YM=(SELECT MAX(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.����<=CONVERT(INT,@NIAN||@YUE||'31'));

	
	
  --PART0 ɾ��Ҫ��ϴ������
    DELETE FROM DM.T_EVT_CUST_OACT_FEE WHERE OACT_YEAR_MTH=@NIAN||@YUE;
	
 
    --PART1 �ͻ��Ŀ����ѣ��ո����´洢,������ϴ��ֻ��ϴÿ�����һ������������
	INSERT INTO DM.T_EVT_CUST_OACT_FEE
	(
	 OACT_YEAR_MTH       --��������
	,CUST_ID             --�ͻ�����
	,SECU_ACCT           --֤ȯ�˺�
	,MTH                 --��
	,YEAR                --��
	,HS_ORG_ID           --������������
	,WH_ORG_ID           --�ֿ��������
	,BRH_NAME            --Ӫҵ������
	,SEPT_CORP_NAME      --�ֹ�˾����
	,CPTL_ACCT           --�ʽ��˺�
	,SECU_ACCT_OACT_DT   --֤ȯ�˺ſ�������
	,OACT_FEE_PAYOUT     --������֧��
	,LOAD_DT             --��ϴ����
	)
(	SELECT
			SUBSTRING(CONVERT(VARCHAR,T2.OPEN_DATE),0,6) AS OACT_YEAR_MTH
			,T2.CLIENT_ID AS CUST_ID
			,T1.ZQZH  AS SECU_ACCT--֤ȯ�˻�
			,SUBSTRING(OACT_YEAR_MTH,5,6) AS MTH
			,SUBSTRING(OACT_YEAR_MTH,0,4) AS YEAR
			,CONVERT(VARCHAR,T2.BRANCH_NO) AS HS_ORG_ID
			,YYB.JGBH AS WH_ORG_ID 
			,YYB.JGMC AS BRH_NAME
			,YYB.FGS  AS SEPT_CORP_NAME
			,T2.FUND_ACCOUNT AS CPTL_ACCT
			,CONVERT(VARCHAR,T2.OPEN_DATE)  AS SECU_ACCT_OACT_DT--֤ȯ�˻���������
			,SUM(CONVERT(DOUBLE,T1.YWFY)*T3.TURN_RMB) AS OACT_FEE_PAYOUT --������֧��
			,@V_BIN_DATE --������ϴ����
			
		FROM DBA.T_EDW_CSS_KH_YWLS_CL T1
		LEFT JOIN
		(
			SELECT
				T1.BRANCH_NO
				,T1.FUND_ACCOUNT
				,T1.CLIENT_ID
				,T1.STOCK_ACCOUNT
				,MIN(T1.OPEN_DATE) AS OPEN_DATE	--��ͬ�г��������ڲ�һ�£�ȡ��С��
			FROM DBA.T_EDW_UF2_STOCKHOLDER T1
			WHERE T1.LOAD_DT=@V_BIN_DATE
			GROUP BY
				T1.BRANCH_NO
				,T1.FUND_ACCOUNT
				,T1.CLIENT_ID
				,T1.STOCK_ACCOUNT
		) T2 ON T1.ZQZH=T2.STOCK_ACCOUNT
		LEFT JOIN DBA.T_EDW_T06_YEAR_EXCHANGE_RATE T3 ON T3.STATIS_YEAR=CONVERT(INT,@NIAN) AND T1.BZ=T3.CURR_TYPE_CD
		LEFT JOIN QUERY_SKB.YUNYING_08 YYB ON CONVERT(INT,T2.BRANCH_NO)=CONVERT(INT,YYB.JGBH_HS)
		WHERE T2.OPEN_DATE>=@ZRR_YC AND T2.OPEN_DATE<=@ZRR_YM		--���ݶ�20170122ֻ����ϴ���¿��������ݼ���	
			AND T1.JGDM='0000'	--����ɹ�
			AND T2.CLIENT_ID IS NOT NULL
		GROUP BY
		SUBSTRING(CONVERT(VARCHAR,T2.OPEN_DATE),0,6) 
			,T2.CLIENT_ID 
			,T1.ZQZH  
			,SUBSTRING(OACT_YEAR_MTH,5,6) 
			,SUBSTRING(OACT_YEAR_MTH,0,4) 
			,CONVERT(VARCHAR,T2.BRANCH_NO) 
			,YYB.JGBH 
			,YYB.JGMC 
			,YYB.FGS  
			,T2.FUND_ACCOUNT
			,CONVERT(VARCHAR,T2.OPEN_DATE)
		
);
COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_CUST_OACT_FEE TO query_dev
GO
GRANT EXECUTE ON dm.P_EVT_CUST_OACT_FEE TO xydc
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_CRED_INCM_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ����������±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ����������±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
               20180415               dcy                    �����ֶ�ȫ�����޸�
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);


--PART0 ɾ����������
  DELETE FROM DM.T_EVT_EMPCUS_CRED_INCM_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    
    ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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


	 SELECT
 		T1.YEAR AS YEAR
 		,T1.MTH AS MTH 
		,T1.OCCUR_DT AS OCCUR_DT
 		,T1.CUST_ID  AS CUST_ID
 		,SUM(COALESCE(T2.GROSS_CMS,0)) AS GROSS_CMS
		,SUM(COALESCE(T2.NET_CMS,0)) AS NET_CMS
		,SUM(COALESCE(T2.TRAN_FEE,0)) AS TRAN_FEE
		,SUM(COALESCE(T2.STP_TAX,0)) AS STP_TAX
		,SUM(COALESCE(T2.ORDR_FEE,0)) AS ORDR_FEE
		,SUM(COALESCE(T2.HANDLE_FEE,0)) AS HANDLE_FEE
		,SUM(COALESCE(T2.SEC_RGLT_FEE,0)) AS SEC_RGLT_FEE
		,SUM(COALESCE(T2.OTH_FEE,0)) AS OTH_FEE
		,SUM(COALESCE(T2.CREDIT_ODI_CMS,0)) AS CREDIT_ODI_CMS
		,SUM(COALESCE(T2.CREDIT_ODI_NET_CMS,0)) AS CREDIT_ODI_NET_CMS
		,SUM(COALESCE(T2.CREDIT_ODI_TRAN_FEE,0)) AS CREDIT_ODI_TRAN_FEE
		,SUM(COALESCE(T2.CREDIT_CRED_CMS,0)) AS CREDIT_CRED_CMS
		,SUM(COALESCE(T2.CREDIT_CRED_NET_CMS,0)) AS CREDIT_CRED_NET_CMS
		,SUM(COALESCE(T2.CREDIT_CRED_TRAN_FEE,0)) AS CREDIT_CRED_TRAN_FEE
		,SUM(COALESCE(T2.STKPLG_CMS,0)) AS STKPLG_CMS
		,SUM(COALESCE(T2.STKPLG_NET_CMS,0)) AS STKPLG_NET_CMS
		,SUM(COALESCE(T2.STKPLG_PAIDINT,0)) AS STKPLG_PAIDINT
		,SUM(COALESCE(T2.STKPLG_RECE_INT,0)) AS STKPLG_RECE_INT
		,SUM(COALESCE(T2.APPTBUYB_CMS,0)) AS APPTBUYB_CMS
		,SUM(COALESCE(T2.APPTBUYB_NET_CMS,0)) AS APPTBUYB_NET_CMS
		,SUM(COALESCE(T2.APPTBUYB_PAIDINT,0)) AS APPTBUYB_PAIDINT
		,SUM(COALESCE(T2.FIN_RECE_INT,0)) AS FIN_RECE_INT
		,SUM(COALESCE(T2.FIN_PAIDINT,0)) AS FIN_PAIDINT
		,SUM(COALESCE(T2.MTH_FIN_IE,0)) AS MTH_FIN_IE
		,SUM(COALESCE(T2.MTH_CRDT_STK_IE,0)) AS MTH_CRDT_STK_IE
		,SUM(COALESCE(T2.MTH_OTH_IE,0)) AS MTH_OTH_IE
		,SUM(COALESCE(T2.MTH_FIN_RECE_INT,0)) AS MTH_FIN_RECE_INT
		,SUM(COALESCE(T2.MTH_FEE_RECE_INT,0)) AS MTH_FEE_RECE_INT
		,SUM(COALESCE(T2.MTH_OTH_RECE_INT,0)) AS MTH_OTH_RECE_INT
		,SUM(COALESCE(T2.CREDIT_CPTL_COST,0)) AS CREDIT_CPTL_COST
		
		,SUM(COALESCE(T2.CREDIT_MARG_SPR_INCM,0)) AS CREDIT_MARG_SPR_INCM	
	INTO #TEMP_SUM	
 	FROM DM.T_EVT_CRED_INCM_M_D T1
 	LEFT JOIN DM.T_EVT_CRED_INCM_M_D T2 ON T1.CUST_ID=T2.CUST_ID AND T1.YEAR=T2.YEAR AND T1.OCCUR_DT>=T2.OCCUR_DT
	WHERE T1.OCCUR_DT=@V_BIN_DATE 
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
	   AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 �ų�"�ܲ�ר���˻�"
 	GROUP BY
 		T1.YEAR
 		,T1.MTH
		,T1.OCCUR_DT
 		,T1.CUST_ID;
  
	INSERT INTO DM.T_EVT_EMPCUS_CRED_INCM_M_D 
	(
	 YEAR                      --��
    ,MTH                       --��
	,OCCUR_DT                  --ҵ������
    ,CUST_ID                   --�ͻ�����
    ,AFA_SEC_EMPID             --AFA_����Ա����
    ,YEAR_MTH                  --����
    ,MAIN_CPTL_ACCT            --���ʽ��˺�
    ,YEAR_MTH_CUST_ID          --���¿ͻ�����
    ,YEAR_MTH_PSN_JNO          --����Ա����
    ,WH_ORG_ID_CUST            --�ֿ��������_�ͻ�
    ,WH_ORG_ID_EMP             --�ֿ��������_Ա��
    ,GROSS_CMS_MTD             --ëӶ��_���ۼ�
    ,NET_CMS_MTD               --��Ӷ��_���ۼ�
    ,TRAN_FEE_MTD              --������_���ۼ�
    ,STP_TAX_MTD               --ӡ��˰_���ۼ�
    ,ORDR_FEE_MTD              --ί�з�_���ۼ�
    ,HANDLE_FEE_MTD            --���ַ�_���ۼ�
    ,SEC_RGLT_FEE_MTD          --֤�ܷ�_���ۼ�
    ,OTH_FEE_MTD               --��������_���ۼ�
    ,CREDIT_ODI_CMS_MTD        --������ȯ��ͨӶ��_���ۼ�
    ,CREDIT_ODI_NET_CMS_MTD    --������ȯ��ͨ��Ӷ��_���ۼ�
    ,CREDIT_ODI_TRAN_FEE_MTD   --������ȯ��ͨ������_���ۼ�
    ,CREDIT_CRED_CMS_MTD       --������ȯ����Ӷ��_���ۼ�
    ,CREDIT_CRED_NET_CMS_MTD   --������ȯ���þ�Ӷ��_���ۼ�
    ,CREDIT_CRED_TRAN_FEE_MTD  --������ȯ���ù�����_���ۼ�
    ,STKPLG_CMS_MTD            --��Ʊ��ѺӶ��_���ۼ�
    ,STKPLG_NET_CMS_MTD        --��Ʊ��Ѻ��Ӷ��_���ۼ�
    ,STKPLG_PAIDINT_MTD        --��Ʊ��Ѻʵ����Ϣ_���ۼ�
    ,STKPLG_RECE_INT_MTD       --��Ʊ��ѺӦ����Ϣ_���ۼ�
    ,APPTBUYB_CMS_MTD          --Լ������Ӷ��_���ۼ�
    ,APPTBUYB_NET_CMS_MTD      --Լ�����ؾ�Ӷ��_���ۼ�
    ,APPTBUYB_PAIDINT_MTD      --Լ������ʵ����Ϣ_���ۼ�
    ,FIN_PAIDINT_MTD           --����ʵ����Ϣ_���ۼ�
    ,FIN_IE_MTD                --������Ϣ֧��_���ۼ�
    ,CRDT_STK_IE_MTD           --��ȯ��Ϣ֧��_���ۼ�
    ,OTH_IE_MTD                --������Ϣ֧��_���ۼ�
    ,FIN_RECE_INT_MTD          --����Ӧ����Ϣ_���ۼ�
    ,FEE_RECE_INT_MTD          --����Ӧ����Ϣ_���ۼ�
    ,OTH_RECE_INT_MTD          --����Ӧ����Ϣ_���ۼ�
    ,CREDIT_CPTL_COST_MTD      --������ȯ�ʽ�ɱ�_���ۼ�
    ,CREDIT_MARG_SPR_INCM_MTD  --������ȯ��֤����������_���ۼ�
    ,GROSS_CMS_YTD             --ëӶ��_���ۼ�
    ,NET_CMS_YTD               --��Ӷ��_���ۼ�
    ,TRAN_FEE_YTD              --������_���ۼ�
    ,STP_TAX_YTD               --ӡ��˰_���ۼ�
    ,ORDR_FEE_YTD              --ί�з�_���ۼ�
    ,HANDLE_FEE_YTD            --���ַ�_���ۼ�
    ,SEC_RGLT_FEE_YTD          --֤�ܷ�_���ۼ�
    ,OTH_FEE_YTD               --��������_���ۼ�
    ,CREDIT_ODI_CMS_YTD        --������ȯ��ͨӶ��_���ۼ�
    ,CREDIT_ODI_NET_CMS_YTD    --������ȯ��ͨ��Ӷ��_���ۼ�
    ,CREDIT_ODI_TRAN_FEE_YTD   --������ȯ��ͨ������_���ۼ�
    ,CREDIT_CRED_CMS_YTD       --������ȯ����Ӷ��_���ۼ�
    ,CREDIT_CRED_NET_CMS_YTD   --������ȯ���þ�Ӷ��_���ۼ�
    ,CREDIT_CRED_TRAN_FEE_YTD  --������ȯ���ù�����_���ۼ�
    ,STKPLG_CMS_YTD            --��Ʊ��ѺӶ��_���ۼ�
    ,STKPLG_NET_CMS_YTD        --��Ʊ��Ѻ��Ӷ��_���ۼ�
    ,STKPLG_PAIDINT_YTD        --��Ʊ��Ѻʵ����Ϣ_���ۼ�
    ,STKPLG_RECE_INT_YTD       --��Ʊ��ѺӦ����Ϣ_���ۼ�
    ,APPTBUYB_CMS_YTD          --Լ������Ӷ��_���ۼ�
    ,APPTBUYB_NET_CMS_YTD      --Լ�����ؾ�Ӷ��_���ۼ�
    ,APPTBUYB_PAIDINT_YTD      --Լ������ʵ����Ϣ_���ۼ�
    ,FIN_PAIDINT_YTD           --����ʵ����Ϣ_���ۼ�
    ,FIN_IE_YTD                --������Ϣ֧��_���ۼ�
    ,CRDT_STK_IE_YTD           --��ȯ��Ϣ֧��_���ۼ�
    ,OTH_IE_YTD                --������Ϣ֧��_���ۼ�
    ,FIN_RECE_INT_YTD          --����Ӧ����Ϣ_���ۼ�
    ,FEE_RECE_INT_YTD          --����Ӧ����Ϣ_���ۼ�
    ,OTH_RECE_INT_YTD          --����Ӧ����Ϣ_���ۼ�
    ,CREDIT_CPTL_COST_YTD      --������ȯ�ʽ�ɱ�_���ۼ�
    ,CREDIT_MARG_SPR_INCM_YTD  --������ȯ��֤����������_���ۼ�
    ,LOAD_DT                   --��ϴ����
)
SELECT 
	T2.YEAR AS ��
	,T2.MTH AS ��
	,T2.OCCUR_DT
	,T2.HS_CUST_ID AS �ͻ�����
	,T2.AFA_SEC_EMPID AS AFA_����Ա����	
	,T2.YEAR||T2.MTH AS ����
	,T2.CPTL_ACCT AS ���ʽ��˺�
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID AS ���¿ͻ�����
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS ����Ա����
	,T2.WH_ORG_ID_CUST AS �ֿ��������_�ͻ�
	,T2.WH_ORG_ID_EMP AS �ֿ��������_Ա��
	
	,COALESCE(T1.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ëӶ��_���ۼ�
	,COALESCE(T1.NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ӷ��_���ۼ�
	,COALESCE(T1.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������_���ۼ�
	,COALESCE(T1.STP_TAX,0)*COALESCE(T2.PERFM_RATI9,0) AS ӡ��˰_���ۼ�
	,COALESCE(T1.ORDR_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ί�з�_���ۼ�
	,COALESCE(T1.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ���ַ�_���ۼ�
	,COALESCE(T1.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ֤�ܷ�_���ۼ�
	,COALESCE(T1.OTH_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ��������_���ۼ�
	,COALESCE(T1.CREDIT_ODI_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��ͨӶ��_���ۼ�
	,COALESCE(T1.CREDIT_ODI_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��ͨ��Ӷ��_���ۼ�
	,COALESCE(T1.CREDIT_ODI_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��ͨ������_���ۼ�
	,COALESCE(T1.CREDIT_CRED_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ����Ӷ��_���ۼ�
	,COALESCE(T1.CREDIT_CRED_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ���þ�Ӷ��_���ۼ�
	,COALESCE(T1.CREDIT_CRED_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ���ù�����_���ۼ�
	,COALESCE(T1.STKPLG_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��ѺӶ��_���ۼ�
	,COALESCE(T1.STKPLG_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��Ѻ��Ӷ��_���ۼ�
	,COALESCE(T1.STKPLG_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��Ѻʵ����Ϣ_���ۼ�
	,COALESCE(T1.STKPLG_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��ѺӦ����Ϣ_���ۼ�
	,COALESCE(T1.APPTBUYB_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ������Ӷ��_���ۼ�
	,COALESCE(T1.APPTBUYB_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ�����ؾ�Ӷ��_���ۼ�
	,COALESCE(T1.APPTBUYB_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ������ʵ����Ϣ_���ۼ�	
--	,COALESCE(T1.FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯӦ����Ϣ�ϼ�_���ۼ�
	,COALESCE(T1.FIN_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����ʵ����Ϣ_���ۼ�
	,COALESCE(T1.MTH_FIN_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������Ϣ֧��_���ۼ�
	,COALESCE(T1.MTH_CRDT_STK_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS ��ȯ��Ϣ֧��_���ۼ�
	,COALESCE(T1.MTH_OTH_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������Ϣ֧��_���ۼ�
	,COALESCE(T1.MTH_FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����Ӧ����Ϣ_���ۼ�
	,COALESCE(T1.MTH_FEE_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����Ӧ����Ϣ_���ۼ�
	,COALESCE(T1.MTH_OTH_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����Ӧ����Ϣ_���ۼ�
	,COALESCE(T1.CREDIT_CPTL_COST,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ�ʽ�ɱ�_���ۼ�
	,COALESCE(T1.CREDIT_MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��֤����������_���ۼ�	

	,COALESCE(T_NIAN.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ëӶ��_���ۼ�
	,COALESCE(T_NIAN.NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������_���ۼ�
	,COALESCE(T_NIAN.STP_TAX,0)*COALESCE(T2.PERFM_RATI9,0) AS ӡ��˰_���ۼ�
	,COALESCE(T_NIAN.ORDR_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ί�з�_���ۼ�
	,COALESCE(T_NIAN.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ���ַ�_���ۼ�
	,COALESCE(T_NIAN.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ֤�ܷ�_���ۼ�
	,COALESCE(T_NIAN.OTH_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ��������_���ۼ�
	,COALESCE(T_NIAN.CREDIT_ODI_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��ͨӶ��_���ۼ�
	,COALESCE(T_NIAN.CREDIT_ODI_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��ͨ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.CREDIT_ODI_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��ͨ������_���ۼ�
	,COALESCE(T_NIAN.CREDIT_CRED_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ����Ӷ��_���ۼ�
	,COALESCE(T_NIAN.CREDIT_CRED_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ���þ�Ӷ��_���ۼ�
	,COALESCE(T_NIAN.CREDIT_CRED_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ���ù�����_���ۼ�
	,COALESCE(T_NIAN.STKPLG_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��ѺӶ��_���ۼ�
	,COALESCE(T_NIAN.STKPLG_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��Ѻ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.STKPLG_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��Ѻʵ����Ϣ_���ۼ�
	,COALESCE(T_NIAN.STKPLG_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ��Ʊ��ѺӦ����Ϣ_���ۼ�
	,COALESCE(T_NIAN.APPTBUYB_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ������Ӷ��_���ۼ�
	,COALESCE(T_NIAN.APPTBUYB_NET_CMS,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ�����ؾ�Ӷ��_���ۼ�
	,COALESCE(T_NIAN.APPTBUYB_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS Լ������ʵ����Ϣ_���ۼ�
--	,COALESCE(T_NIAN.FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯӦ����Ϣ�ϼ�_���ۼ�
	,COALESCE(T_NIAN.FIN_PAIDINT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����ʵ����Ϣ_���ۼ�
	,COALESCE(T_NIAN.MTH_FIN_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������Ϣ֧��_���ۼ�
	,COALESCE(T_NIAN.MTH_CRDT_STK_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS ��ȯ��Ϣ֧��_���ۼ�
	,COALESCE(T_NIAN.MTH_OTH_IE,0)*COALESCE(T2.PERFM_RATI9,0) AS ������Ϣ֧��_���ۼ�
	,COALESCE(T_NIAN.MTH_FIN_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����Ӧ����Ϣ_���ۼ�
	,COALESCE(T_NIAN.MTH_FEE_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����Ӧ����Ϣ_���ۼ�
	,COALESCE(T_NIAN.MTH_OTH_RECE_INT,0)*COALESCE(T2.PERFM_RATI9,0) AS ����Ӧ����Ϣ_���ۼ�
	,COALESCE(T_NIAN.CREDIT_CPTL_COST,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ�ʽ�ɱ�_���ۼ�
	,COALESCE(T_NIAN.CREDIT_MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI9,0) AS ������ȯ��֤����������_���ۼ�
	,20171229
 FROM #T_PUB_SER_RELA T2 
LEFT JOIN DM.T_EVT_CRED_INCM_M_D T1 
	ON T1.YEAR=T2.YEAR 
		AND T1.OCCUR_DT=T2.OCCUR_DT 
		AND T1.CUST_ID=T2.HS_CUST_ID
LEFT JOIN #TEMP_SUM 	T_NIAN 
	ON T2.YEAR=T_NIAN.YEAR 
		AND T2.OCCUR_DT=T_NIAN.OCCUR_DT 
		AND T2.HS_CUST_ID=T_NIAN.CUST_ID 
WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
	   AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 �ų�"�ܲ�ר���˻�"
;
END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_CRED_INCM_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_NUM_M_D(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ����±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ����±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ; 
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT;  --��Ȼ��_�³�
	DECLARE @V_BIN_NATRE_DAY_YEARBGN INT;  --��Ȼ��_���
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
	
--PART0 ɾ����������
  DELETE FROM DM.T_EVT_EMPCUS_NUM_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

  --����ÿ�տͻ�����
  SELECT  
     OUC.CLIENT_ID 	AS CUST_ID  --�ͻ�����
	,@V_BIN_YEAR           	AS YEAR      --��
	,@V_BIN_MTH           	AS MTH       --��
	,@V_BIN_DATE            AS OCCUR_DT  --ҵ������
	,OUF.FUND_ACCOUNT  		AS MAIN_CPTL_ACCT     --���ʽ��˺ţ���ͨ�˻���
	,DOH.PK_ORG 	 		AS WH_ORG_ID          --�ֿ�������� 
	,CONVERT(VARCHAR,OUC.BRANCH_NO) AS HS_ORG_ID  --������������
    ,OUF.OPEN_DATE 					AS TE_OACT_DT   --���翪������
	
	INTO #T_PUB_CUST
	
	FROM DBA.T_EDW_UF2_CLIENT  			OUC   --���пͻ���Ϣ
    LEFT JOIN DBA.T_edw_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID AND OUF.LOAD_DT=OUC.LOAD_dT AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --��ͨ�˻����ʽ��˺�
	LEFT JOIN DBA.T_DIM_ORG_HIS  		DOH ON CONVERT(VARCHAR,OUC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=OUC.LOAD_dT AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL    --���ظ�ֵ
	WHERE OUC.BRANCH_NO NOT IN (5,55,51,44,9999)--20180207 �������ų�"�ܲ�ר���˻�"
      AND OUC.LOAD_DT=@V_BIN_DATE;

    -- ҵ��������ʱ��
    SELECT 
		 T1.YEAR
		,T1.MTH
		,T1.YEAR||T1.MTH AS ����
		,T1.OCCUR_DT
		,T1.YEAR||T1.MTH||T1.CUST_ID AS ���¿ͻ�����
		,T1.CUST_ID AS �ͻ�����	
		,T1.WH_ORG_ID AS �ֿ��������
		,CASE WHEN T1.TE_OACT_DT>@V_BIN_NATRE_DAY_MTHBEG  THEN 1 ELSE 0 END AS �Ƿ�������
		,CASE WHEN T1.TE_OACT_DT>@V_BIN_NATRE_DAY_YEARBGN THEN 1 ELSE 0 END AS �Ƿ�������
		INTO #TEMP_T1
	FROM #T_PUB_CUST T1
	WHERE T1.OCCUR_DT=@V_BIN_DATE
	       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH) --20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
		   AND T1.HS_ORG_ID NOT IN ('5','55','51','44','9999'); --20180314 �ų�"�ܲ�ר���˻�"
		  
  
    ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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
	 
  
  
	INSERT INTO DM.T_EVT_EMPCUS_NUM_M_D 
	(
	YEAR              --��
	,MTH              --�� 
	,OCCUR_DT 			  --OCCUR_DT
	,CUST_ID          --�ͻ����� 
	,AFA_SEC_EMPID    --AFA_����Ա���� 
	,YEAR_MTH         --���� 
	,YEAR_MTH_CUST_ID --���¿ͻ����� 
	,YEAR_MTH_PSN_JNO --����Ա����� 
	,WH_ORG_ID_CUST   --�ֿ��������_�ͻ� 
	,WH_ORG_ID_EMP    --�ֿ��������_Ա�� 
	,IF_MTH_NA        --�Ƿ������� 
	,IF_YEAR_NA       --�Ƿ������� 
	,CUST_NUM         --�ͻ��� 
	,CUST_NUM_CRED    --�ͻ���_����
	,LOAD_DT          --��ϴ����
	)
	SELECT
	T2.YEAR AS ��
	,T2.MTH AS ��
	,T2.OCCUR_DT
	,T2.HS_CUST_ID
	,T2.AFA_SEC_EMPID AS AFA_����Ա����
	,T2.YEAR||T2.MTH	
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS ����Ա�����
	,T2.WH_ORG_ID_CUST AS �ֿ��������_�ͻ�
	,T2.WH_ORG_ID_EMP AS �ֿ��������_Ա��	
	,T1.�Ƿ�������
	,T1.�Ƿ�������
	,T2.PERFM_RATI1 AS �ͻ���
	,T2.PERFM_RATI9 AS �ͻ���_����
	,@V_BIN_DATE
FROM #T_PUB_SER_RELA T2
LEFT JOIN #TEMP_T1 T1 
	ON T1.occur_dt=t2.occur_dt 
	  AND T1.�ͻ�����=T2.HS_CUST_ID
WHERE T2.AFA_SEC_EMPID IS NOT NULL
;

END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_NUM_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_ODI_INCM_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ���ͨ�����±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ���ͨ�����±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
              20180415                  DCY                �����¸����ֶ�
  
           
  *********************************************************************/

   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	
  --PART0 ɾ����������
  DELETE FROM DM.T_EVT_EMPCUS_ODI_INCM_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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
		   max(bz)      as MEMO,
		   max(ygxm)    as EMP_NAME,
		   sum(jxbl1)   as PERFM_RATI1,
		   sum(jxbl2)   as PERFM_RATI2,
		   sum(jxbl3)   as PERFM_RATI3,
		   sum(jxbl4)   as PERFM_RATI4,
		   sum(jxbl5)   as PERFM_RATI5,
		   sum(jxbl6)   as PERFM_RATI6,
		   sum(jxbl7)   as PERFM_RATI7,
		   sum(jxbl8)   as PERFM_RATI8,
		   sum(jxbl9)   as PERFM_RATI9,
		   sum(jxbl10) as PERFM_RATI10,
		   sum(jxbl11) as PERFM_RATI11,
		   sum(jxbl12) as PERFM_RATI12 
     INTO #T_PUB_SER_RELA
	  from (select *
			  from dba.t_ddw_serv_relation_d
			 where jxbl1 + jxbl2 + jxbl3 + jxbl4 + jxbl5 + jxbl6 + jxbl7 + jxbl8 +
				   jxbl9 + jxbl10 + jxbl11 + jxbl12 > 0
		       AND RQ=@V_BIN_DATE) a
	 group by YEAR, MTH,OCCUR_DT, HS_ORG_ID, HS_CUST_ID,CPTL_ACCT,FST_EMPID_BROK_ID,AFA_SEC_EMPID,WH_ORG_ID_CUST,WH_ORG_ID_EMP,PRSN_TYPE;

	 --ҵ��������ʱ��
	 SELECT
 		T1.YEAR
 		,T1.MTH
		,T1.OCCUR_DT
 		,T1.CUST_ID
 		,SUM(COALESCE(T2.GROSS_CMS,0)) AS GROSS_CMS
		,SUM(COALESCE(T2.TRAN_FEE,0)) AS TRAN_FEE
		,SUM(COALESCE(T2.SCDY_TRAN_FEE,0)) AS SCDY_TRAN_FEE
		,SUM(COALESCE(T2.STP_TAX,0)) AS STP_TAX
		,SUM(COALESCE(T2.HANDLE_FEE,0)) AS HANDLE_FEE
		,SUM(COALESCE(T2.SEC_RGLT_FEE,0)) AS SEC_RGLT_FEE
		,SUM(COALESCE(T2.OTH_FEE,0)) AS OTH_FEE
		,SUM(COALESCE(T2.STKF_CMS,0)) AS STKF_CMS
		,SUM(COALESCE(T2.STKF_TRAN_FEE,0)) AS STKF_TRAN_FEE
		,SUM(COALESCE(T2.STKF_NET_CMS,0)) AS STKF_NET_CMS
		,SUM(COALESCE(T2.BOND_CMS,0)) AS BOND_CMS
		,SUM(COALESCE(T2.BOND_NET_CMS,0)) AS BOND_NET_CMS
		,SUM(COALESCE(T2.REPQ_CMS,0)) AS REPQ_CMS
		,SUM(COALESCE(T2.REPQ_NET_CMS,0)) AS REPQ_NET_CMS
		,SUM(COALESCE(T2.HGT_CMS,0)) AS HGT_CMS
		,SUM(COALESCE(T2.HGT_NET_CMS,0)) AS HGT_NET_CMS
		,SUM(COALESCE(T2.HGT_TRAN_FEE,0)) AS HGT_TRAN_FEE
		,SUM(COALESCE(T2.SGT_CMS,0)) AS SGT_CMS
		,SUM(COALESCE(T2.SGT_NET_CMS,0)) AS SGT_NET_CMS
		,SUM(COALESCE(T2.SGT_TRAN_FEE,0)) AS SGT_TRAN_FEE
		,SUM(COALESCE(T2.BGDL_CMS,0)) AS BGDL_CMS
		,SUM(COALESCE(T2.NET_CMS,0)) AS NET_CMS
		,SUM(COALESCE(T2.BGDL_NET_CMS,0)) AS BGDL_NET_CMS
		,SUM(COALESCE(T2.BGDL_TRAN_FEE,0)) AS BGDL_TRAN_FEE
		,SUM(COALESCE(T2.PSTK_OPTN_CMS,0)) AS PSTK_OPTN_CMS
		,SUM(COALESCE(T2.PSTK_OPTN_NET_CMS,0)) AS PSTK_OPTN_NET_CMS
		,SUM(COALESCE(T2.SCDY_CMS,0)) AS SCDY_CMS
		,SUM(COALESCE(T2.SCDY_NET_CMS,0)) AS SCDY_NET_CMS
		--20180411����
		,SUM(COALESCE(T2.PB_TRD_CMS,0)) AS PB_TRD_CMS
		,SUM(COALESCE(T2.MARG_SPR_INCM,0)) AS MARG_SPR_INCM
        
	INTO #TEMP_T1
 	FROM DM.T_EVT_ODI_INCM_M_D T1
 	LEFT JOIN DM.T_EVT_ODI_INCM_M_D T2 ON T1.CUST_ID=T2.CUST_ID AND T1.YEAR=T2.YEAR AND T1.OCCUR_DT>=T2.OCCUR_DT
	WHERE T1.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
	   AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 �ų�"�ܲ�ר���˻�"
 	GROUP BY
 		T1.YEAR
 		,T1.MTH
		,T1.OCCUR_DT
 		,T1.CUST_ID;
	 
INSERT INTO DM.T_EVT_EMPCUS_ODI_INCM_M_D 
(
	 YEAR                   --��    
    ,MTH                    --��
	,OCCUR_DT
    ,CUST_ID                --�ͻ�����
    ,AFA_SEC_EMPID          --AFA_����Ա����
    ,YEAR_MTH               --����
    ,MAIN_CPTL_ACCT         --���ʽ��˺�
    ,YEAR_MTH_CUST_ID       --���¿ͻ�����
    ,YEAR_MTH_PSN_JNO       --����Ա����
    ,WH_ORG_ID_CUST         --�ֿ��������_�ͻ�
    ,WH_ORG_ID_EMP          --�ֿ��������_Ա��
    ,GROSS_CMS_MTD          --ëӶ��_���ۼ�
    ,TRAN_FEE_MTD           --������_���ۼ�
    ,SCDY_TRAN_FEE_MTD      --����������_���ۼ�
    ,STP_TAX_MTD            --ӡ��˰_���ۼ�
    ,HANDLE_FEE_MTD         --���ַ�_���ۼ�
    ,SEC_RGLT_FEE_MTD       --֤�ܷ�_���ۼ�
    ,OTH_FEE_MTD            --��������_���ۼ�
    ,STKF_CMS_MTD           --�ɻ�Ӷ��_���ۼ�
    ,STKF_TRAN_FEE_MTD      --�ɻ�������_���ۼ�
    ,STKF_NET_CMS_MTD       --�ɻ���Ӷ��_���ۼ�
    ,BOND_CMS_MTD           --ծȯӶ��_���ۼ�
    ,BOND_NET_CMS_MTD       --ծȯ��Ӷ��_���ۼ�
    ,REPQ_CMS_MTD           --���ۻع�Ӷ��_���ۼ�
    ,REPQ_NET_CMS_MTD       --���ۻع���Ӷ��_���ۼ�
    ,HGT_CMS_MTD            --����ͨӶ��_���ۼ�
    ,HGT_NET_CMS_MTD        --����ͨ��Ӷ��_���ۼ�
    ,HGT_TRAN_FEE_MTD       --����ͨ������_���ۼ�
    ,SGT_CMS_MTD            --���ͨӶ��_���ۼ�
    ,SGT_NET_CMS_MTD        --���ͨ��Ӷ��_���ۼ�
    ,SGT_TRAN_FEE_MTD       --���ͨ������_���ۼ�
    ,BGDL_CMS_MTD           --���ڽ���Ӷ��_���ۼ�
    ,NET_CMS_MTD            --��Ӷ��_���ۼ�
    ,BGDL_NET_CMS_MTD       --���ڽ��׾�Ӷ��_���ۼ�
    ,BGDL_TRAN_FEE_MTD      --���ڽ��׹�����_���ۼ�
    ,PSTK_OPTN_CMS_MTD      --������ȨӶ��_���ۼ�
    ,PSTK_OPTN_NET_CMS_MTD  --������Ȩ��Ӷ��_���ۼ�
    ,SCDY_CMS_MTD           --����Ӷ��_���ۼ�
    ,SCDY_NET_CMS_MTD       --������Ӷ��_���ۼ�
    ,PB_TRD_CMS_MTD         --PB����Ӷ��_���ۼ�
    ,MARG_SPR_INCM_MTD      --��֤����������_���ۼ�
    ,GROSS_CMS_YTD          --ëӶ��_���ۼ�
    ,TRAN_FEE_YTD           --������_���ۼ�
    ,SCDY_TRAN_FEE_YTD      --����������_���ۼ�
    ,STP_TAX_YTD            --ӡ��˰_���ۼ�
    ,HANDLE_FEE_YTD         --���ַ�_���ۼ�
    ,SEC_RGLT_FEE_YTD       --֤�ܷ�_���ۼ�
    ,OTH_FEE_YTD            --��������_���ۼ�
    ,STKF_CMS_YTD           --�ɻ�Ӷ��_���ۼ�
    ,STKF_TRAN_FEE_YTD      --�ɻ�������_���ۼ�
    ,STKF_NET_CMS_YTD       --�ɻ���Ӷ��_���ۼ�
    ,BOND_CMS_YTD           --ծȯӶ��_���ۼ�
    ,BOND_NET_CMS_YTD       --ծȯ��Ӷ��_���ۼ�
    ,REPQ_CMS_YTD           --���ۻع�Ӷ��_���ۼ�
    ,REPQ_NET_CMS_YTD       --���ۻع���Ӷ��_���ۼ�
    ,HGT_CMS_YTD            --����ͨӶ��_���ۼ�
    ,HGT_NET_CMS_YTD        --����ͨ��Ӷ��_���ۼ�
    ,HGT_TRAN_FEE_YTD       --����ͨ������_���ۼ�
    ,SGT_CMS_YTD            --���ͨӶ��_���ۼ�
    ,SGT_NET_CMS_YTD        --���ͨ��Ӷ��_���ۼ�
    ,SGT_TRAN_FEE_YTD       --���ͨ������_���ۼ�
    ,BGDL_CMS_YTD           --���ڽ���Ӷ��_���ۼ�
    ,NET_CMS_YTD            --��Ӷ��_���ۼ�
    ,BGDL_NET_CMS_YTD       --���ڽ��׾�Ӷ��_���ۼ�
    ,BGDL_TRAN_FEE_YTD      --���ڽ��׹�����_���ۼ�
    ,PSTK_OPTN_CMS_YTD      --������ȨӶ��_���ۼ�
    ,PSTK_OPTN_NET_CMS_YTD  --������Ȩ��Ӷ��_���ۼ�
    ,SCDY_CMS_YTD           --����Ӷ��_���ۼ�
    ,SCDY_NET_CMS_YTD       --������Ӷ��_���ۼ�
    ,PB_TRD_CMS_YTD         --PB����Ӷ��_���ۼ�
    ,MARG_SPR_INCM_YTD      --��֤����������_���ۼ�
    ,LOAD_DT                --��ϴ����
)

SELECT 
	T2.YEAR AS ��
	,T2.MTH AS ��
	,T2.OCCUR_DT
	,T2.HS_CUST_ID AS �ͻ�����
	,T2.AFA_SEC_EMPID AS AFA����Ա����
	,T2.YEAR||T1.MTH AS ����
	,T2.CPTL_ACCT AS ���ʽ��˺�
	,T2.YEAR||T1.MTH||T2.HS_CUST_ID AS ���¿ͻ����
	,T2.YEAR||T1.MTH||T2.AFA_SEC_EMPID AS ����Ա����
	,T2.WH_ORG_ID_CUST AS �ֿ��������_�ͻ�
	,T2.WH_ORG_ID_EMP AS �ֿ��������_Ա��
	
	,COALESCE(T1.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ëӶ��_���ۼ�
	,COALESCE(T1.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ������_���ۼ�
	,COALESCE(T1.SCDY_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ����������_���ۼ�
	,COALESCE(T1.STP_TAX,0)*COALESCE(T2.PERFM_RATI2,0) AS ӡ��˰_���ۼ�
	,COALESCE(T1.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ַ�_���ۼ�
	,COALESCE(T1.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ֤�ܷ�_���ۼ�
	,COALESCE(T1.OTH_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ��������_���ۼ�
	,COALESCE(T1.STKF_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS �ɻ�Ӷ��_���ۼ�
	,COALESCE(T1.STKF_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS �ɻ�������_���ۼ�
	,COALESCE(T1.STKF_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS �ɻ���Ӷ��_���ۼ�
	,COALESCE(T1.BOND_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ծȯӶ��_���ۼ�
	,COALESCE(T1.BOND_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ծȯ��Ӷ��_���ۼ�
	,COALESCE(T1.REPQ_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ۻع�Ӷ��_���ۼ�
	,COALESCE(T1.REPQ_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ۻع���Ӷ��_���ۼ�
	,COALESCE(T1.HGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ����ͨӶ��_���ۼ�
	,COALESCE(T1.HGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ����ͨ��Ӷ��_���ۼ�
	,COALESCE(T1.HGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ����ͨ������_���ۼ�
	,COALESCE(T1.SGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ͨӶ��_���ۼ�
	,COALESCE(T1.SGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ͨ��Ӷ��_���ۼ�
	,COALESCE(T1.SGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ͨ������_���ۼ�
	,COALESCE(T1.BGDL_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ڽ���Ӷ��_���ۼ�
	,COALESCE(T1.NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ��Ӷ��_���ۼ�
	,COALESCE(T1.BGDL_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ڽ��׾�Ӷ��_���ۼ�
	,COALESCE(T1.BGDL_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ڽ��׹�����_���ۼ�
	,COALESCE(T1.PSTK_OPTN_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ������ȨӶ��_���ۼ�
	,COALESCE(T1.PSTK_OPTN_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ������Ȩ��Ӷ��_���ۼ�
	,COALESCE(T1.SCDY_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ����Ӷ��_���ۼ�
	,COALESCE(T1.SCDY_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ������Ӷ��_���ۼ�
	
	,COALESCE(T1.PB_TRD_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS PB����Ӷ��_���ۼ�
	,COALESCE(T1.MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI2,0) AS ��֤����������_���ۼ�
	
	,COALESCE(T_NIAN.GROSS_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ëӶ��_���ۼ�
	,COALESCE(T_NIAN.TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ������_���ۼ�
	,COALESCE(T_NIAN.SCDY_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ����������_���ۼ�
	,COALESCE(T_NIAN.STP_TAX,0)*COALESCE(T2.PERFM_RATI2,0) AS ӡ��˰_���ۼ�
	,COALESCE(T_NIAN.HANDLE_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ַ�_���ۼ�
	,COALESCE(T_NIAN.SEC_RGLT_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ֤�ܷ�_���ۼ�
	,COALESCE(T_NIAN.OTH_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ��������_���ۼ�
	,COALESCE(T_NIAN.STKF_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS �ɻ�Ӷ��_���ۼ�
	,COALESCE(T_NIAN.STKF_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS �ɻ�������_���ۼ�
	,COALESCE(T_NIAN.STKF_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS �ɻ���Ӷ��_���ۼ�
	,COALESCE(T_NIAN.BOND_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ծȯӶ��_���ۼ�
	,COALESCE(T_NIAN.BOND_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ծȯ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.REPQ_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ۻع�Ӷ��_���ۼ�
	,COALESCE(T_NIAN.REPQ_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ۻع���Ӷ��_���ۼ�
	,COALESCE(T_NIAN.HGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ����ͨӶ��_���ۼ�
	,COALESCE(T_NIAN.HGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ����ͨ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.HGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ����ͨ������_���ۼ�
	,COALESCE(T_NIAN.SGT_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ͨӶ��_���ۼ�
	,COALESCE(T_NIAN.SGT_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ͨ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.SGT_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ͨ������_���ۼ�
	,COALESCE(T_NIAN.BGDL_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ڽ���Ӷ��_���ۼ�
	,COALESCE(T_NIAN.NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.BGDL_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ڽ��׾�Ӷ��_���ۼ�
	,COALESCE(T_NIAN.BGDL_TRAN_FEE,0)*COALESCE(T2.PERFM_RATI2,0) AS ���ڽ��׹�����_���ۼ�
	,COALESCE(T_NIAN.PSTK_OPTN_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ������ȨӶ��_���ۼ�
	,COALESCE(T_NIAN.PSTK_OPTN_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ������Ȩ��Ӷ��_���ۼ�
	,COALESCE(T_NIAN.SCDY_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ����Ӷ��_���ۼ�
	,COALESCE(T_NIAN.SCDY_NET_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS ������Ӷ��_���ۼ�

	,COALESCE(T_NIAN.PB_TRD_CMS,0)*COALESCE(T2.PERFM_RATI2,0) AS PB����Ӷ��_���ۼ�
	,COALESCE(T_NIAN.MARG_SPR_INCM,0)*COALESCE(T2.PERFM_RATI2,0) AS ��֤����������_���ۼ�
	,@V_BIN_DATE
 FROM #T_PUB_SER_RELA T2
 LEFT JOIN #TEMP_T1 T_NIAN 
 	ON T2.OCCUR_DT=T_NIAN.OCCUR_DT 
 		AND T2.HS_CUST_ID=T_NIAN.CUST_ID
 LEFT JOIN DM.T_EVT_ODI_INCM_M_D T1
 	ON  T1.occur_dt=T2.occur_dt 
 		AND T1.CUST_ID=T2.HS_CUST_ID   
 WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
	   AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 �ų�"�ܲ�ר���˻�"
;

END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_ODI_INCM_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_ODI_TRD_M_D(IN @V_BIN_DATE INT)


BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ���ͨ�����±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ���ͨ�����±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 ɾ����������
  DELETE FROM DM.T_EVT_EMPCUS_ODI_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

    ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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


	 
INSERT INTO DM.T_EVT_EMPCUS_ODI_TRD_M_D 
(
	 YEAR                --��  
	,MTH                 --��
	,OCCUR_DT            --ҵ������
	,CUST_ID             --�ͻ�����
	,AFA_SEC_EMPID       --AFA_����Ա����
	,YEAR_MTH            --����
	,MAIN_CPTL_ACCT      --���ʽ��˺�
	,YEAR_MTH_CUST_ID    --���¿ͻ�����
	,YEAR_MTH_PSN_JNO    --����Ա����
	,WH_ORG_ID_CUST      --�ֿ��������_�ͻ�
	,WH_ORG_ID_EMP       --�ֿ��������_Ա��
	,EQT_CLAS_KEPP_PERCN --Ȩ����ֲ�ռ��
	,SCDY_TRD_FREQ       --�������״���
	,RCT_TRD_DT_GT       --�����������_�ۼ�
	,SCDY_TRD_QTY        --����������
	,SCDY_TRD_QTY_TY     --����������_����
	,TRD_FREQ_TY         --���״���_����
	,STKF_TRD_QTY        --�ɻ�������
	,STKF_TRD_QTY_TY     --�ɻ�������_����
	,S_REPUR_TRD_QTY     --���ع�������
	,R_REPUR_TRD_QTY     --��ع�������
	,S_REPUR_TRD_QTY_TY  --���ع�������_����
	,R_REPUR_TRD_QTY_TY  --��ع�������_����
	,HGT_TRD_QTY         --����ͨ������
	,SGT_TRD_QTY         --���ͨ������
	,SGT_TRD_QTY_TY      --���ͨ������_����
	,HGT_TRD_QTY_TY      --����ͨ������_����
	,Y_RCT_STK_TRD_QTY   --��12�¹�Ʊ������
	,SCDY_TRD_FREQ_TY    --�������״���_����
	,TRD_FREQ            --���״���
	,APPTBUYB_TRD_QTY    --Լ�����ؽ�����
	,APPTBUYB_TRD_QTY_TY --Լ�����ؽ�����_����
	,RCT_TRD_DT_M        --�����������_����
	,STKPLG_TRD_QTY      --��Ʊ��Ѻ������
	,STKPLG_TRD_QTY_TY   --��Ʊ��Ѻ������_����
	,PSTK_OPTN_TRD_QTY   --������Ȩ������
	,PSTK_OPTN_TRD_QTY_TY--������Ȩ������_����
	,GROSS_CMS           --ëӶ��
	,NET_CMS             --��Ӷ��
	,REPQ_TRD_QTY        --���ۻع�������
	,REPQ_TRD_QTY_TY     --���ۻع�������_����
	,BGDL_QTY            --���ڽ�����
	,BGDL_QTY_TY         --���ڽ�����_����
	,LOAD_DT             --��ϴ����

)
SELECT 
	T1.YEAR AS ��
	,T1.MTH AS ��
	,T1.OCCUR_DT
	,T1.CUST_ID AS �ͻ�����
	,T2.AFA_SEC_EMPID AS AFA_����Ա����
	,T1.YEAR||T1.MTH AS ����
	,T1.MAIN_CPTL_ACCT AS ���ʽ��˺�
	,T1.YEAR||T1.MTH||T1.CUST_ID AS ���¿ͻ����
	,T1.YEAR||T1.MTH||T2.AFA_SEC_EMPID AS ����Ա����
	,T2.WH_ORG_ID_CUST AS �ֿ��������_�ͻ�
	,T2.WH_ORG_ID_EMP AS �ֿ��������_Ա��
	
	,T1.EQT_CLAS_KEPP_PERCN*PERFM_RATI3 AS Ȩ����ֲ�ռ��
	,T1.SCDY_TRD_FREQ*PERFM_RATI3 AS �������״���
	,T1.RCT_TRD_DT_GT*PERFM_RATI3 AS �����������_�ۼ�
	,T1.SCDY_TRD_QTY*PERFM_RATI3 AS ����������
	,T1.SCDY_TRD_QTY_TY*PERFM_RATI3 AS ����������_����
	,T1.TRD_FREQ_TY*PERFM_RATI3 AS ���״���_����
	,T1.STKF_TRD_QTY*PERFM_RATI3 AS �ɻ�������
	,T1.STKF_TRD_QTY_TY*PERFM_RATI3 AS �ɻ�������_����
	,T1.S_REPUR_TRD_QTY*PERFM_RATI3 AS ���ع�������
	,T1.R_REPUR_TRD_QTY*PERFM_RATI3 AS ��ع�������
	,T1.S_REPUR_TRD_QTY_TY*PERFM_RATI3 AS ���ع�������_����
	,T1.R_REPUR_TRD_QTY_TY*PERFM_RATI3 AS ��ع�������_����
	,T1.HGT_TRD_QTY*PERFM_RATI3 AS ����ͨ������
	,T1.SGT_TRD_QTY*PERFM_RATI3 AS ���ͨ������
	,T1.SGT_TRD_QTY_TY*PERFM_RATI3 AS ���ͨ������_����
	,T1.HGT_TRD_QTY_TY*PERFM_RATI3 AS ����ͨ������_����
	,T1.Y_RCT_STK_TRD_QTY*PERFM_RATI3 AS ��12�¹�Ʊ������
	,T1.SCDY_TRD_FREQ_TY*PERFM_RATI3 AS �������״���_����
	,T1.TRD_FREQ*PERFM_RATI3 AS ���״���
	,T1.APPTBUYB_TRD_QTY*PERFM_RATI3 AS Լ�����ؽ�����
	,T1.APPTBUYB_TRD_QTY_TY*PERFM_RATI3 AS Լ�����ؽ�����_����
	,T1.RCT_TRD_DT_M*PERFM_RATI3 AS �����������_����
	,T1.STKPLG_TRD_QTY*PERFM_RATI3 AS ��Ʊ��Ѻ������
	,T1.STKPLG_TRD_QTY_TY*PERFM_RATI3 AS ��Ʊ��Ѻ������_����
	,T1.PSTK_OPTN_TRD_QTY*PERFM_RATI3 AS ������Ȩ������
	,T1.PSTK_OPTN_TRD_QTY_TY*PERFM_RATI3 AS ������Ȩ������_����
	,T1.GROSS_CMS*PERFM_RATI3 AS ëӶ��
	,T1.NET_CMS*PERFM_RATI3 AS ��Ӷ��
	,T1.REPQ_TRD_QTY*PERFM_RATI3 AS ���ۻع�������
	,T1.REPQ_TRD_QTY_TY*PERFM_RATI3 AS ���ۻع�������_����
	,T1.BGDL_QTY*PERFM_RATI3 AS ���ڽ�����
	,T1.BGDL_QTY_TY*PERFM_RATI3 AS ���ڽ�����_����
	,@V_BIN_DATE
 FROM DM.T_EVT_CUS_ODI_TRD_M_D T1
 LEFT JOIN #T_PUB_SER_RELA T2 ON T1.occur_dt=t2.occur_dt AND T1.CUST_ID=T2.HS_CUST_ID 
 WHERE T1.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T1.CUST_ID AND YEAR=T1.YEAR AND MTH=T1.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
	    AND T1.CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 �ų�"�ܲ�ר���˻�"
;

END
GO
CREATE PROCEDURE dm.P_EVT_EMPCUS_PROD_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д���Ա���ͻ���Ʒ�����±�
  ��д��: DCY
  ��������: 2018-02-05
  ��飺Ա���ͻ���Ʒ�����±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
              20180322                  dcy                ���������ĸ�����
  *********************************************************************/

   --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
	
	----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
	
	--PART0 ɾ����������
	  DELETE FROM DM.T_EVT_EMPCUS_PROD_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

   ---��������Ȩ���ܱ�---�޳����ֿͻ��ٷ�����Ȩ2����¼���
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


	 
	INSERT INTO DM.T_EVT_EMPCUS_PROD_TRD_M_D 
	(
	 YEAR                      --��
	,MTH                       --��
	,OCCUR_DT                  --ҵ������
	,CUST_ID                   --�ͻ�����
	,PROD_CD                   --��Ʒ����
	,PROD_TYPE                 --��Ʒ����
	,AFA_SEC_EMPID             --AFA_����Ա����
	,YEAR_MTH                  --����
	,YEAR_MTH_CUST_ID          --���¿ͻ�����
	,YEAR_MTH_PSN_JNO          --����Ա����
	,YEAR_MTH_CUST_ID_PROD_CD  --���¿ͻ������Ʒ����
	,WH_ORG_ID_CUST            --�ֿ��������_�ͻ�
	,WH_ORG_ID_EMP             --�ֿ��������_Ա��
	,ITC_RETAIN_AMT_FINAL      --���ڱ��н��_��ĩ
	,OTC_RETAIN_AMT_FINAL      --���Ᵽ�н��_��ĩ
	,ITC_RETAIN_SHAR_FINAL     --���ڱ��зݶ�_��ĩ
	,OTC_RETAIN_SHAR_FINAL     --���Ᵽ�зݶ�_��ĩ
	,ITC_RETAIN_AMT_MDA        --���ڱ��н��_���վ�
	,OTC_RETAIN_AMT_MDA        --���Ᵽ�н��_���վ�
	,ITC_RETAIN_SHAR_MDA       --���ڱ��зݶ�_���վ�
	,OTC_RETAIN_SHAR_MDA       --���Ᵽ�зݶ�_���վ�
	,ITC_RETAIN_AMT_YDA        --���ڱ��н��_���վ�
	,OTC_RETAIN_AMT_YDA        --���Ᵽ�н��_���վ�
	,ITC_RETAIN_SHAR_YDA       --���ڱ��зݶ�_���վ�
	,OTC_RETAIN_SHAR_YDA       --���Ᵽ�зݶ�_���վ�
	,ITC_SUBS_AMT_MTD          --�����Ϲ����_���ۼ�
	,ITC_PURS_AMT_MTD          --�����깺���_���ۼ�
	,ITC_BUYIN_AMT_MTD         --����������_���ۼ�
	,ITC_REDP_AMT_MTD          --������ؽ��_���ۼ�
	,ITC_SELL_AMT_MTD          --�����������_���ۼ�
	,OTC_SUBS_AMT_MTD          --�����Ϲ����_���ۼ�
	,OTC_PURS_AMT_MTD          --�����깺���_���ۼ�
	,OTC_CASTSL_AMT_MTD        --���ⶨͶ���_���ۼ�
	,OTC_COVT_IN_AMT_MTD       --����ת������_���ۼ�
	,OTC_REDP_AMT_MTD          --������ؽ��_���ۼ�
	,OTC_COVT_OUT_AMT_MTD      --����ת�������_���ۼ�
	,ITC_SUBS_SHAR_MTD         --�����Ϲ��ݶ�_���ۼ�
	,ITC_PURS_SHAR_MTD         --�����깺�ݶ�_���ۼ�
	,ITC_BUYIN_SHAR_MTD        --��������ݶ�_���ۼ�
	,ITC_REDP_SHAR_MTD         --������طݶ�_���ۼ�
	,ITC_SELL_SHAR_MTD         --���������ݶ�_���ۼ�
	,OTC_SUBS_SHAR_MTD         --�����Ϲ��ݶ�_���ۼ�
	,OTC_PURS_SHAR_MTD         --�����깺�ݶ�_���ۼ�
	,OTC_CASTSL_SHAR_MTD       --���ⶨͶ�ݶ�_���ۼ�
	,OTC_COVT_IN_SHAR_MTD      --����ת����ݶ�_���ۼ�
	,OTC_REDP_SHAR_MTD         --������طݶ�_���ۼ�
	,OTC_COVT_OUT_SHAR_MTD     --����ת�����ݶ�_���ۼ�
	,ITC_SUBS_CHAG_MTD         --�����Ϲ�������_���ۼ�
	,ITC_PURS_CHAG_MTD         --�����깺������_���ۼ�
	,ITC_BUYIN_CHAG_MTD        --��������������_���ۼ�
	,ITC_REDP_CHAG_MTD         --�������������_���ۼ�
	,ITC_SELL_CHAG_MTD         --��������������_���ۼ�
	,OTC_SUBS_CHAG_MTD         --�����Ϲ�������_���ۼ�
	,OTC_PURS_CHAG_MTD         --�����깺������_���ۼ�
	,OTC_CASTSL_CHAG_MTD       --���ⶨͶ������_���ۼ�
	,OTC_COVT_IN_CHAG_MTD      --����ת����������_���ۼ�
	,OTC_REDP_CHAG_MTD         --�������������_���ۼ�
	,OTC_COVT_OUT_CHAG_MTD     --����ת����������_���ۼ�
	,ITC_SUBS_AMT_YTD          --�����Ϲ����_���ۼ�
	,ITC_PURS_AMT_YTD          --�����깺���_���ۼ�
	,ITC_BUYIN_AMT_YTD         --����������_���ۼ�
	,ITC_REDP_AMT_YTD          --������ؽ��_���ۼ�
	,ITC_SELL_AMT_YTD          --�����������_���ۼ�
	,OTC_SUBS_AMT_YTD          --�����Ϲ����_���ۼ�
	,OTC_PURS_AMT_YTD          --�����깺���_���ۼ�
	,OTC_CASTSL_AMT_YTD        --���ⶨͶ���_���ۼ�
	,OTC_COVT_IN_AMT_YTD       --����ת������_���ۼ�
	,OTC_REDP_AMT_YTD          --������ؽ��_���ۼ�
	,OTC_COVT_OUT_AMT_YTD      --����ת�������_���ۼ�
	,ITC_SUBS_SHAR_YTD         --�����Ϲ��ݶ�_���ۼ�
	,ITC_PURS_SHAR_YTD         --�����깺�ݶ�_���ۼ�
	,ITC_BUYIN_SHAR_YTD        --��������ݶ�_���ۼ�
	,ITC_REDP_SHAR_YTD         --������طݶ�_���ۼ�
	,ITC_SELL_SHAR_YTD         --���������ݶ�_���ۼ�
	,OTC_SUBS_SHAR_YTD         --�����Ϲ��ݶ�_���ۼ�
	,OTC_PURS_SHAR_YTD         --�����깺�ݶ�_���ۼ�
	,OTC_CASTSL_SHAR_YTD       --���ⶨͶ�ݶ�_���ۼ�
	,OTC_COVT_IN_SHAR_YTD      --����ת����ݶ�_���ۼ�
	,OTC_REDP_SHAR_YTD         --������طݶ�_���ۼ�
	,OTC_COVT_OUT_SHAR_YTD     --����ת�����ݶ�_���ۼ�
	,ITC_SUBS_CHAG_YTD         --�����Ϲ�������_���ۼ�
	,ITC_PURS_CHAG_YTD         --�����깺������_���ۼ�
	,ITC_BUYIN_CHAG_YTD        --��������������_���ۼ�
	,ITC_REDP_CHAG_YTD         --�������������_���ۼ�
	,ITC_SELL_CHAG_YTD         --��������������_���ۼ�
	,OTC_SUBS_CHAG_YTD         --�����Ϲ�������_���ۼ�
	,OTC_PURS_CHAG_YTD         --�����깺������_���ۼ�
	,OTC_CASTSL_CHAG_YTD       --���ⶨͶ������_���ۼ�
	,OTC_COVT_IN_CHAG_YTD      --����ת����������_���ۼ�
	,OTC_REDP_CHAG_YTD         --�������������_���ۼ�
	,OTC_COVT_OUT_CHAG_YTD     --����ת����������_���ۼ�
	,LOAD_DT                   --��ϴ����
	,CONTD_SALE_SHAR_MTD       --�������۷ݶ�_���ۼ�
	,CONTD_SALE_AMT_MTD        --�������۽��_���ۼ�
	,CONTD_SALE_SHAR_YTD       --�������۷ݶ�_���ۼ�
	,CONTD_SALE_AMT_YTD        --�������۽��_���ۼ�

)
SELECT 
	 T2.YEAR AS ��
	,T2.MTH AS ��
	,T2.OCCUR_DT
	,T2.HS_CUST_ID AS �ͻ�����
	,T1.PROD_CD AS ��Ʒ����
	,T1.PROD_TYPE AS ��Ʒ����
	,T2.AFA_SEC_EMPID AS AFA����Ա����
	,T2.YEAR||T2.MTH AS ����
	,T2.YEAR||T2.MTH||T2.HS_CUST_ID AS ���¿ͻ�����
	,T2.YEAR||T2.MTH||T2.AFA_SEC_EMPID AS ����Ա����
	,T2.YEAR||T2.MTH||T1.PROD_CD AS ���¿ͻ������Ʒ����
	,T2.WH_ORG_ID_CUST AS �ֿ��������_�ͻ�
	,T2.WH_ORG_ID_EMP AS �ֿ��������_Ա��	
	
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_FINAL,0) END AS ���ڱ��н��_��ĩ
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_FINAL,0) END AS ���Ᵽ�н��_��ĩ
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_FINAL,0) END AS ���ڱ��зݶ�_��ĩ
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_FINAL,0) END AS ���Ᵽ�зݶ�_��ĩ
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_MDA,0) END AS ���ڱ��н��_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_MDA,0) END AS ���Ᵽ�н��_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_MDA,0) END AS ���ڱ��зݶ�_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_MDA,0) END AS ���Ᵽ�зݶ�_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_AMT_YDA,0) END AS ���ڱ��н��_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_AMT_YDA,0) END AS ���Ᵽ�н��_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_RETAIN_SHAR_YDA,0) END AS ���ڱ��зݶ�_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_RETAIN_SHAR_YDA,0) END AS ���Ᵽ�зݶ�_���վ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_AMT_MTD,0) END AS �����Ϲ����_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_AMT_MTD,0) END AS �����깺���_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_AMT_MTD,0) END AS ����������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_AMT_MTD,0) END AS ������ؽ��_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_AMT_MTD,0) END AS �����������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_AMT_MTD,0) END AS �����Ϲ����_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_AMT_MTD,0) END AS �����깺���_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_AMT_MTD,0) END AS ���ⶨͶ���_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_AMT_MTD,0) END AS ����ת������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_AMT_MTD,0) END AS ������ؽ��_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_AMT_MTD,0) END AS ����ת�������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_SHAR_MTD,0) END AS �����Ϲ��ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_SHAR_MTD,0) END AS �����깺�ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_SHAR_MTD,0) END AS ��������ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_SHAR_MTD,0) END AS ������طݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_SHAR_MTD,0) END AS ���������ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_SHAR_MTD,0) END AS �����Ϲ��ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_SHAR_MTD,0) END AS �����깺�ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_SHAR_MTD,0) END AS ���ⶨͶ�ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_SHAR_MTD,0) END AS ����ת����ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_SHAR_MTD,0) END AS ������طݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_MTD,0) END AS ����ת�����ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_CHAG_MTD,0) END AS �����Ϲ�������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_CHAG_MTD,0) END AS �����깺������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_CHAG_MTD,0) END AS ��������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_CHAG_MTD,0) END AS �������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_CHAG_MTD,0) END AS ��������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_CHAG_MTD,0) END AS �����Ϲ�������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_CHAG_MTD,0) END AS �����깺������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_CHAG_MTD,0) END AS ���ⶨͶ������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_CHAG_MTD,0) END AS ����ת����������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_CHAG_MTD,0) END AS �������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_MTD,0) END AS ����ת����������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_AMT_YTD,0) END AS �����Ϲ����_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_AMT_YTD,0) END AS �����깺���_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_AMT_YTD,0) END AS ����������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_AMT_YTD,0) END AS ������ؽ��_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_AMT_YTD,0) END AS �����������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_AMT_YTD,0) END AS �����Ϲ����_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_AMT_YTD,0) END AS �����깺���_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_AMT_YTD,0) END AS ���ⶨͶ���_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_AMT_YTD,0) END AS ����ת������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_AMT_YTD,0) END AS ������ؽ��_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_AMT_YTD,0) END AS ����ת�������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_SHAR_YTD,0) END AS �����Ϲ��ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_SHAR_YTD,0) END AS �����깺�ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_SHAR_YTD,0) END AS ��������ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_SHAR_YTD,0) END AS ������طݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_SHAR_YTD,0) END AS ���������ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_SHAR_YTD,0) END AS �����Ϲ��ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_SHAR_YTD,0) END AS �����깺�ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_SHAR_YTD,0) END AS ���ⶨͶ�ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_SHAR_YTD,0) END AS ����ת����ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_SHAR_YTD,0) END AS ������طݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_SHAR_YTD,0) END AS ����ת�����ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SUBS_CHAG_YTD,0) END AS �����Ϲ�������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_PURS_CHAG_YTD,0) END AS �����깺������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_BUYIN_CHAG_YTD,0) END AS ��������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_REDP_CHAG_YTD,0) END AS �������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.ITC_SELL_CHAG_YTD,0) END AS ��������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_SUBS_CHAG_YTD,0) END AS �����Ϲ�������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_PURS_CHAG_YTD,0) END AS �����깺������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_CASTSL_CHAG_YTD,0) END AS ���ⶨͶ������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_IN_CHAG_YTD,0) END AS ����ת����������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_REDP_CHAG_YTD,0) END AS �������������_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.OTC_COVT_OUT_CHAG_YTD,0) END AS ����ת����������_���ۼ�
    ,@V_BIN_DATE
	
	--20180321 ����������������
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_SHAR_MTD,0) END AS �������۷ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_AMT_MTD,0) END AS �������۽��_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_SHAR_YTD,0) END AS �������۷ݶ�_���ۼ�
	,CASE WHEN T1.PROD_TYPE='˽ļ����' THEN COALESCE(T2.PERFM_RATI7,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) WHEN T1.PROD_TYPE='�������' THEN COALESCE(T2.PERFM_RATI6,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) WHEN T1.PROD_TYPE='����ר��' THEN COALESCE(T2.PERFM_RATI5,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) ELSE COALESCE(T2.PERFM_RATI4,0)*COALESCE(T1.CONTD_SALE_AMT_YTD,0) END AS �������۽��_���ۼ�
FROM #T_PUB_SER_RELA T2
LEFT JOIN DM.T_EVT_PROD_TRD_M_D T1
	ON T1.occur_dt=t2.occur_dt 
		AND T1.CUST_ID=T2.HS_CUST_ID                                  
WHERE T2.OCCUR_DT=@V_BIN_DATE
       AND EXISTS(SELECT 1 FROM DM.T_ACC_CPTL_ACC WHERE CUST_ID=T2.HS_CUST_ID AND YEAR=T2.YEAR AND MTH=T2.MTH)--20180207 ZQ:����Ȩ��ϵ�Ŀͻ�����Ҫ���ʽ��˻�
	   AND T2.HS_CUST_ID NOT IN ('448999999',
				'440000001',
				'999900000001',
				'440000011',
				'440000015')--20180314 �ų�"�ܲ�ר���˻�"
		AND T1.PROD_CD IS NOT NULL
;

END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUS_PROD_TRD_M_D TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_EMPCUST_OACT_FEE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: Ա���ͻ������ѱ�
  ��д��: DCY �ο��������ṩ��ȡ���߼�
  ��������: 2018-01-17
  ��飺
  *********************************************************************
  �޶���¼��   �޶�����    �޶���     �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    DECLARE @NIAN VARCHAR(4);		--����_���
	DECLARE @YUE VARCHAR(2)	;		--����_�·�
	DECLARE @ZRR_NC INT;            --��Ȼ��_�³�
	DECLARE @ZRR_YC INT;            --��Ȼ��_��� 
	DECLARE @TD_YM INT;				--��ĩ
	DECLARE @NY INT;                --����
	
	DECLARE @ZRR_YM INT;            --��Ȼ��_��ĩ
	
	DECLARE @V_TAX NUMERIC(20,4);  --��˰����
	
	
    SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1

    SET @NIAN=SUBSTR(@V_BIN_DATE||'',1,4);
	SET @YUE=SUBSTR(@V_BIN_DATE||'',5,2);
   	SET @ZRR_NC=(SELECT MIN(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.����>=CONVERT(INT,@NIAN||'0101'));
	SET @ZRR_YC=(SELECT MIN(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.����>=CONVERT(INT,@NIAN||@YUE||'01'));
	SET @TD_YM=(SELECT MAX(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.�Ƿ�����='1' AND T1.����<=CONVERT(INT,@NIAN||@YUE||'31'));
    SET @NY=CONVERT(INT,@NIAN||@YUE);
	
	SET @ZRR_YM=(SELECT MAX(T1.����) FROM DBA.V_SKB_D_RQ T1 WHERE T1.����<=CONVERT(INT,@NIAN||@YUE||'31'));
    
	SET @V_TAX=1.06; --��������������
	
/*
	
  --PART0 ɾ��Ҫ��ϴ������
    DELETE FROM DM.T_EVT_EMPCUST_OACT_FEE WHERE OACT_YEAR_MTH=@NIAN||@YUE;
	
 
    --PART1 Ա���ͻ��Ŀ����ѣ�һ���¸���һ���汾��������ϴ��ֻ��ϴÿ�����һ������������
	INSERT INTO DM.T_EVT_EMPCUST_OACT_FEE
	(
	 OACT_YEAR_MTH            --��������
	,CUST_ID                  --�ͻ�����
	,AFA_SEC_EMPID            --AFA����Ա����
	,OPENACT_NUM              --������
	,OACT_FEE_PAYOUT          --������֧��
	,OACT_FEE_PAYOUT_DR_TAX   --������֧��_��˰
	,LOAD_DT                  --��ϴ����
	)
(
	SELECT
		T1.KHNY AS OACT_YEAR_MTH	
		,T1.KHBH_HS AS CUST_ID
		,T_GX.AFATWO_YGH AS AFA_SEC_EMPID
		,SUM(T_GX.JXBL2) AS OPENACT_NUM
		,SUM(T1.YWFY*T_GX.JXBL2) AS OACT_FEE_PAYOUT             --������֧��
		,SUM(T1.YWFY*T_GX.JXBL2)/@V_TAX AS OACT_FEE_PAYOUT_DR_TAX --������֧��_��˰
		,@V_BIN_DATE  
	FROM
	(
		SELECT
			CONVERT(INT,T2.BRANCH_NO) AS JGBH_HS
			,YYB.JGBH
			,YYB.JGMC
			,YYB.FGS
			,T2.FUND_ACCOUNT AS ZJZH
			,T2.CLIENT_ID AS KHBH_HS
			,T0.ZQZH
			,T0.YWRQ
			,SUBSTRING(CONVERT(VARCHAR,T2.OPEN_DATE),0,6) AS KHNY
			,SUBSTRING(KHNY,0,4) AS NIAN
			,SUBSTRING(KHNY,5,6) AS YUE
			,CONVERT(DOUBLE,T0.YWFY)*T3.TURN_RMB AS YWFY
		FROM DBA.T_EDW_CSS_KH_YWLS_CL T0
		LEFT JOIN
		(
			SELECT
				T0.BRANCH_NO
				,T0.FUND_ACCOUNT
				,T0.CLIENT_ID
				,T0.STOCK_ACCOUNT
				,MIN(T0.OPEN_DATE) AS OPEN_DATE	--��ͬ�г��������ڲ�һ�£�ȡ��С��
			FROM DBA.T_EDW_UF2_STOCKHOLDER T0
			WHERE T0.LOAD_DT=@V_BIN_DATE
			GROUP BY
				T0.BRANCH_NO
				,T0.FUND_ACCOUNT
				,T0.CLIENT_ID
				,T0.STOCK_ACCOUNT
		) T2 ON T0.ZQZH=T2.STOCK_ACCOUNT
		LEFT JOIN DBA.T_EDW_T06_YEAR_EXCHANGE_RATE T3 ON T3.STATIS_YEAR=CONVERT(INT,@NIAN) AND T0.BZ=T3.CURR_TYPE_CD
		LEFT JOIN QUERY_SKB.YUNYING_08 YYB ON CONVERT(INT,T2.BRANCH_NO)=CONVERT(INT,YYB.JGBH_HS)
		WHERE T2.OPEN_DATE>=@ZRR_YC AND T2.OPEN_DATE<=@ZRR_YM			
			AND T0.JGDM='0000'	--����ɹ�
			AND T2.CLIENT_ID IS NOT NULL
	) T1	
	LEFT JOIN DBA.T_DDW_SERV_RELATION T_GX ON T_GX.NIAN=T1.NIAN AND T_GX.YUE=T1.YUE AND T1.KHBH_HS=T_GX.KHBH_HS
	LEFT JOIN QUERY_SKB.YUNYING_08 YYB_YG ON T_GX.JGBH_YG=YYB_YG.JGBH
	GROUP BY
		 T1.KHNY 	
		,T1.KHBH_HS
		,T_GX.AFATWO_YGH
);

COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 

*/
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUST_OACT_FEE TO query_dev
GO
GRANT EXECUTE ON dm.P_EVT_EMPCUST_OACT_FEE TO xydc
GO
CREATE PROCEDURE dm.P_EVT_INCM_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ӫҵ��������ձ�
  ��д��: Ҷ���
  ��������: 2018-04-11
  ��飺Ӫҵ��������ձ�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	DELETE FROM DM.T_EVT_INCM_D_BRH WHERE OCCUR_DT = @V_DATE;

  	-- Ա��-Ӫҵ����ϵ
	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--Ա������
		,A.PK_ORG 		AS 		BRH_ID			--Ӫҵ������
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  		AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	CREATE TABLE #TMP_T_EVT_INCM_D_BRH(
	    OCCUR_DT             	numeric(8,0) NOT NULL,
		BRH_ID               	varchar(30)  NOT NULL,
		EMP_ID		 			varchar(30)  NOT NULL,
		NET_CMS              	numeric(38,8) NULL,
		GROSS_CMS            	numeric(38,8) NULL,
		SCDY_CMS             	numeric(38,8) NULL,
		SCDY_NET_CMS         	numeric(38,8) NULL,
		SCDY_TRAN_FEE        	numeric(38,8) NULL,
		ODI_TRD_TRAN_FEE     	numeric(38,8) NULL,
		CRED_TRD_TRAN_FEE    	numeric(38,8) NULL,
		STKF_CMS             	numeric(38,8) NULL,
		STKF_TRAN_FEE        	numeric(38,8) NULL,
		STKF_NET_CMS         	numeric(38,8) NULL,
		BOND_CMS             	numeric(38,8) NULL,
		BOND_NET_CMS         	numeric(38,8) NULL,
		REPQ_CMS             	numeric(38,8) NULL,
		REPQ_NET_CMS         	numeric(38,8) NULL,
		HGT_CMS              	numeric(38,8) NULL,
		HGT_NET_CMS          	numeric(38,8) NULL,
		HGT_TRAN_FEE         	numeric(38,8) NULL,
		SGT_CMS              	numeric(38,8) NULL,
		SGT_NET_CMS          	numeric(38,8) NULL,
		SGT_TRAN_FEE         	numeric(38,8) NULL,
		BGDL_CMS             	numeric(38,8) NULL,
		BGDL_NET_CMS         	numeric(38,8) NULL,
		BGDL_TRAN_FEE        	numeric(38,8) NULL,
		PSTK_OPTN_CMS        	numeric(38,8) NULL,
		PSTK_OPTN_NET_CMS    	numeric(38,8) NULL,
		CREDIT_ODI_CMS       	numeric(38,8) NULL,
		CREDIT_ODI_NET_CMS   	numeric(38,8) NULL,
		CREDIT_ODI_TRAN_FEE  	numeric(38,8) NULL,
		CREDIT_CRED_CMS      	numeric(38,8) NULL,
		CREDIT_CRED_NET_CMS  	numeric(38,8) NULL,
		CREDIT_CRED_TRAN_FEE 	numeric(38,8) NULL,
		FIN_RECE_INT         	numeric(38,8) NULL,
		FIN_PAIDINT          	numeric(38,8) NULL,
		STKPLG_CMS           	numeric(38,8) NULL,
		STKPLG_NET_CMS       	numeric(38,8) NULL,
		STKPLG_PAIDINT       	numeric(38,8) NULL,
		STKPLG_RECE_INT      	numeric(38,8) NULL,
		APPTBUYB_CMS         	numeric(38,8) NULL,
		APPTBUYB_NET_CMS     	numeric(38,8) NULL,
		APPTBUYB_PAIDINT     	numeric(38,8) NULL,
		FIN_IE               	numeric(38,8) NULL,
		CRDT_STK_IE          	numeric(38,8) NULL,
		OTH_IE               	numeric(38,8) NULL,
		FEE_RECE_INT         	numeric(38,8) NULL,
		OTH_RECE_INT         	numeric(38,8) NULL,
		CREDIT_CPTL_COST     	numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_INCM_D_BRH(
		  OCCUR_DT             			--��������
		 ,BRH_ID               			--Ӫҵ������
		 ,EMP_ID		 	   			--Ա������		
		 ,NET_CMS              			--��Ӷ��
		 ,GROSS_CMS            			--ëӶ��
		 ,SCDY_CMS             			--����Ӷ��
		 ,SCDY_NET_CMS         			--������Ӷ��
		 ,SCDY_TRAN_FEE        			--����������
		 ,ODI_TRD_TRAN_FEE     			--��ͨ���׹�����
		 ,CRED_TRD_TRAN_FEE    			--���ý��׹�����
		 ,STKF_CMS             			--�ɻ�Ӷ��
		 ,STKF_TRAN_FEE        			--�ɻ�������
		 ,STKF_NET_CMS         			--�ɻ���Ӷ��
		 ,BOND_CMS             			--ծȯӶ��
		 ,BOND_NET_CMS         			--ծȯ��Ӷ��
		 ,REPQ_CMS             			--���ۻع�Ӷ��
		 ,REPQ_NET_CMS         			--���ۻع���Ӷ��
		 ,HGT_CMS              			--����ͨӶ��
		 ,HGT_NET_CMS          			--����ͨ��Ӷ��
		 ,HGT_TRAN_FEE         			--����ͨ������
		 ,SGT_CMS              			--���ͨӶ��
		 ,SGT_NET_CMS          			--���ͨ��Ӷ��
		 ,SGT_TRAN_FEE         			--���ͨ������
		 ,BGDL_CMS             			--���ڽ���Ӷ��
		 ,BGDL_NET_CMS         			--���ڽ��׾�Ӷ��
		 ,BGDL_TRAN_FEE        			--���ڽ��׹�����
		 ,PSTK_OPTN_CMS        			--������ȨӶ��
		 ,PSTK_OPTN_NET_CMS    			--������Ȩ��Ӷ��
		 ,CREDIT_ODI_CMS       			--������ȯ��ͨӶ��
		 ,CREDIT_ODI_NET_CMS   			--������ȯ��ͨ��Ӷ��
		 ,CREDIT_ODI_TRAN_FEE  			--������ȯ��ͨ������
		 ,CREDIT_CRED_CMS      			--������ȯ����Ӷ��
		 ,CREDIT_CRED_NET_CMS  			--������ȯ���þ�Ӷ��
		 ,CREDIT_CRED_TRAN_FEE 			--������ȯ���ù�����
		 ,FIN_RECE_INT         			--����Ӧ����Ϣ
		 ,FIN_PAIDINT          			--����ʵ����Ϣ
		 ,STKPLG_CMS           			--��Ʊ��ѺӶ��
		 ,STKPLG_NET_CMS       			--��Ʊ��Ѻ��Ӷ��
		 ,STKPLG_PAIDINT       			--��Ʊ��Ѻʵ����Ϣ
		 ,STKPLG_RECE_INT      			--��Ʊ��ѺӦ����Ϣ
		 ,APPTBUYB_CMS         			--Լ������Ӷ��
		 ,APPTBUYB_NET_CMS     			--Լ�����ؾ�Ӷ��
		 ,APPTBUYB_PAIDINT     			--Լ������ʵ����Ϣ
		 ,FIN_IE               			--������Ϣ֧��
		 ,CRDT_STK_IE          			--��ȯ��Ϣ֧��
		 ,OTH_IE               			--������Ϣ֧��
		 ,FEE_RECE_INT         			--����Ӧ����Ϣ
		 ,OTH_RECE_INT         			--����Ӧ����Ϣ
		 ,CREDIT_CPTL_COST     			--������ȯ�ʽ�ɱ�
	)
	SELECT 
		  T.OCCUR_DT            		AS      OCCUR_DT            		--��������
		 ,T1.BRH_ID              		AS      BRH_ID              		--Ӫҵ������
		 ,T.EMP_ID		 	  			AS      EMP_ID		 	  			--Ա������		
		 ,T.NET_CMS             		AS      NET_CMS             		--��Ӷ��
		 ,T.GROSS_CMS           		AS      GROSS_CMS           		--ëӶ��
		 ,T.SCDY_CMS            		AS      SCDY_CMS            		--����Ӷ��
		 ,T.SCDY_NET_CMS        		AS      SCDY_NET_CMS        		--������Ӷ��
		 ,T.SCDY_TRAN_FEE       		AS      SCDY_TRAN_FEE       		--����������
		 ,T.ODI_TRD_TRAN_FEE    		AS      ODI_TRD_TRAN_FEE    		--��ͨ���׹�����
		 ,T.CRED_TRD_TRAN_FEE   		AS      CRED_TRD_TRAN_FEE   		--���ý��׹�����
		 ,T.STKF_CMS            		AS      STKF_CMS            		--�ɻ�Ӷ��
		 ,T.STKF_TRAN_FEE       		AS      STKF_TRAN_FEE       		--�ɻ�������
		 ,T.STKF_NET_CMS        		AS      STKF_NET_CMS        		--�ɻ���Ӷ��
		 ,T.BOND_CMS            		AS      BOND_CMS            		--ծȯӶ��
		 ,T.BOND_NET_CMS        		AS      BOND_NET_CMS        		--ծȯ��Ӷ��
		 ,T.REPQ_CMS            		AS      REPQ_CMS            		--���ۻع�Ӷ��
		 ,T.REPQ_NET_CMS        		AS      REPQ_NET_CMS        		--���ۻع���Ӷ��
		 ,T.HGT_CMS             		AS      HGT_CMS             		--����ͨӶ��
		 ,T.HGT_NET_CMS         		AS      HGT_NET_CMS         		--����ͨ��Ӷ��
		 ,T.HGT_TRAN_FEE        		AS      HGT_TRAN_FEE        		--����ͨ������
		 ,T.SGT_CMS             		AS      SGT_CMS             		--���ͨӶ��
		 ,T.SGT_NET_CMS         		AS      SGT_NET_CMS         		--���ͨ��Ӷ��
		 ,T.SGT_TRAN_FEE        		AS      SGT_TRAN_FEE        		--���ͨ������
		 ,T.BGDL_CMS            		AS      BGDL_CMS            		--���ڽ���Ӷ��
		 ,T.BGDL_NET_CMS        		AS      BGDL_NET_CMS        		--���ڽ��׾�Ӷ��
		 ,T.BGDL_TRAN_FEE       		AS      BGDL_TRAN_FEE       		--���ڽ��׹�����
		 ,T.PSTK_OPTN_CMS       		AS      PSTK_OPTN_CMS       		--������ȨӶ��
		 ,T.PSTK_OPTN_NET_CMS   		AS      PSTK_OPTN_NET_CMS   		--������Ȩ��Ӷ��
		 ,T.CREDIT_ODI_CMS      		AS      CREDIT_ODI_CMS      		--������ȯ��ͨӶ��
		 ,T.CREDIT_ODI_NET_CMS  		AS      CREDIT_ODI_NET_CMS  		--������ȯ��ͨ��Ӷ��
		 ,T.CREDIT_ODI_TRAN_FEE 		AS      CREDIT_ODI_TRAN_FEE 		--������ȯ��ͨ������
		 ,T.CREDIT_CRED_CMS     		AS      CREDIT_CRED_CMS     		--������ȯ����Ӷ��
		 ,T.CREDIT_CRED_NET_CMS 		AS      CREDIT_CRED_NET_CMS 		--������ȯ���þ�Ӷ��
		 ,T.CREDIT_CRED_TRAN_FEE		AS      CREDIT_CRED_TRAN_FEE		--������ȯ���ù�����
		 ,T.FIN_RECE_INT        		AS      FIN_RECE_INT        		--����Ӧ����Ϣ
		 ,T.FIN_PAIDINT         		AS      FIN_PAIDINT         		--����ʵ����Ϣ
		 ,T.STKPLG_CMS          		AS      STKPLG_CMS          		--��Ʊ��ѺӶ��
		 ,T.STKPLG_NET_CMS      		AS      STKPLG_NET_CMS      		--��Ʊ��Ѻ��Ӷ��
		 ,T.STKPLG_PAIDINT      		AS      STKPLG_PAIDINT      		--��Ʊ��Ѻʵ����Ϣ
		 ,T.STKPLG_RECE_INT     		AS      STKPLG_RECE_INT     		--��Ʊ��ѺӦ����Ϣ
		 ,T.APPTBUYB_CMS        		AS      APPTBUYB_CMS        		--Լ������Ӷ��
		 ,T.APPTBUYB_NET_CMS    		AS      APPTBUYB_NET_CMS    		--Լ�����ؾ�Ӷ��
		 ,T.APPTBUYB_PAIDINT    		AS      APPTBUYB_PAIDINT    		--Լ������ʵ����Ϣ
		 ,T.FIN_IE              		AS      FIN_IE              		--������Ϣ֧��
		 ,T.CRDT_STK_IE         		AS      CRDT_STK_IE         		--��ȯ��Ϣ֧��
		 ,T.OTH_IE              		AS      OTH_IE              		--������Ϣ֧��
		 ,T.FEE_RECE_INT        		AS      FEE_RECE_INT        		--����Ӧ����Ϣ
		 ,T.OTH_RECE_INT        		AS      OTH_RECE_INT        		--����Ӧ����Ϣ
		 ,T.CREDIT_CPTL_COST    		AS      CREDIT_CPTL_COST    		--������ȯ�ʽ�ɱ�
	FROM DM.T_EVT_INCM_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	 AND  T1.BRH_ID IS NOT NULL;
	
	--����ʱ��İ�Ӫҵ��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	INSERT INTO DM.T_EVT_INCM_D_BRH (
			 OCCUR_DT            	--��������
			,BRH_ID              	--Ӫҵ������		
			,NET_CMS             	--��Ӷ��	
			,GROSS_CMS           	--ëӶ��	
			,SCDY_CMS            	--����Ӷ��	
			,SCDY_NET_CMS        	--������Ӷ��	
			,SCDY_TRAN_FEE       	--����������	
			,ODI_TRD_TRAN_FEE    	--��ͨ���׹�����	
			,CRED_TRD_TRAN_FEE   	--���ý��׹�����	
			,STKF_CMS            	--�ɻ�Ӷ��	
			,STKF_TRAN_FEE       	--�ɻ�������	
			,STKF_NET_CMS        	--�ɻ���Ӷ��	
			,BOND_CMS            	--ծȯӶ��	
			,BOND_NET_CMS        	--ծȯ��Ӷ��	
			,REPQ_CMS            	--���ۻع�Ӷ��	
			,REPQ_NET_CMS        	--���ۻع���Ӷ��	
			,HGT_CMS             	--����ͨӶ��	
			,HGT_NET_CMS         	--����ͨ��Ӷ��	
			,HGT_TRAN_FEE        	--����ͨ������	
			,SGT_CMS             	--���ͨӶ��	
			,SGT_NET_CMS         	--���ͨ��Ӷ��	
			,SGT_TRAN_FEE        	--���ͨ������	
			,BGDL_CMS            	--���ڽ���Ӷ��	
			,BGDL_NET_CMS        	--���ڽ��׾�Ӷ��	
			,BGDL_TRAN_FEE       	--���ڽ��׹�����	
			,PSTK_OPTN_CMS       	--������ȨӶ��	
			,PSTK_OPTN_NET_CMS   	--������Ȩ��Ӷ��	
			,CREDIT_ODI_CMS      	--������ȯ��ͨӶ��	
			,CREDIT_ODI_NET_CMS  	--������ȯ��ͨ��Ӷ��	
			,CREDIT_ODI_TRAN_FEE 	--������ȯ��ͨ������	
			,CREDIT_CRED_CMS     	--������ȯ����Ӷ��	
			,CREDIT_CRED_NET_CMS 	--������ȯ���þ�Ӷ��	
			,CREDIT_CRED_TRAN_FEE	--������ȯ���ù�����	
			,FIN_RECE_INT        	--����Ӧ����Ϣ	
			,FIN_PAIDINT         	--����ʵ����Ϣ	
			,STKPLG_CMS          	--��Ʊ��ѺӶ��	
			,STKPLG_NET_CMS      	--��Ʊ��Ѻ��Ӷ��	
			,STKPLG_PAIDINT      	--��Ʊ��Ѻʵ����Ϣ	
			,STKPLG_RECE_INT     	--��Ʊ��ѺӦ����Ϣ	
			,APPTBUYB_CMS        	--Լ������Ӷ��	
			,APPTBUYB_NET_CMS    	--Լ�����ؾ�Ӷ��	
			,APPTBUYB_PAIDINT    	--Լ������ʵ����Ϣ	
			,FIN_IE              	--������Ϣ֧��	
			,CRDT_STK_IE         	--��ȯ��Ϣ֧��	
			,OTH_IE              	--������Ϣ֧��	
			,FEE_RECE_INT        	--����Ӧ����Ϣ	
			,OTH_RECE_INT        	--����Ӧ����Ϣ	
			,CREDIT_CPTL_COST      	--������ȯ�ʽ�ɱ�						
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              --��������		
			,BRH_ID									AS    BRH_ID                --Ӫҵ������	
			,SUM(NET_CMS)							AS 	  NET_CMS             	--��Ӷ��				
			,SUM(GROSS_CMS)							AS 	  GROSS_CMS           	--ëӶ��		
			,SUM(SCDY_CMS)							AS 	  SCDY_CMS            	--����Ӷ��		
			,SUM(SCDY_NET_CMS)						AS 	  SCDY_NET_CMS        	--������Ӷ��			
			,SUM(SCDY_TRAN_FEE)						AS 	  SCDY_TRAN_FEE       	--����������			
			,SUM(ODI_TRD_TRAN_FEE)					AS 	  ODI_TRD_TRAN_FEE    	--��ͨ���׹�����				
			,SUM(CRED_TRD_TRAN_FEE)					AS 	  CRED_TRD_TRAN_FEE   	--���ý��׹�����				
			,SUM(STKF_CMS)							AS 	  STKF_CMS            	--�ɻ�Ӷ��		
			,SUM(STKF_TRAN_FEE)						AS 	  STKF_TRAN_FEE       	--�ɻ�������			
			,SUM(STKF_NET_CMS)						AS 	  STKF_NET_CMS        	--�ɻ���Ӷ��			
			,SUM(BOND_CMS)							AS 	  BOND_CMS            	--ծȯӶ��		
			,SUM(BOND_NET_CMS)						AS 	  BOND_NET_CMS        	--ծȯ��Ӷ��			
			,SUM(REPQ_CMS)							AS 	  REPQ_CMS            	--���ۻع�Ӷ��		
			,SUM(REPQ_NET_CMS)						AS 	  REPQ_NET_CMS        	--���ۻع���Ӷ��			
			,SUM(HGT_CMS)							AS 	  HGT_CMS             	--����ͨӶ��		
			,SUM(HGT_NET_CMS)						AS 	  HGT_NET_CMS         	--����ͨ��Ӷ��			
			,SUM(HGT_TRAN_FEE)						AS 	  HGT_TRAN_FEE        	--����ͨ������			
			,SUM(SGT_CMS)							AS 	  SGT_CMS             	--���ͨӶ��		
			,SUM(SGT_NET_CMS)						AS 	  SGT_NET_CMS         	--���ͨ��Ӷ��			
			,SUM(SGT_TRAN_FEE)						AS 	  SGT_TRAN_FEE        	--���ͨ������			
			,SUM(BGDL_CMS)							AS 	  BGDL_CMS            	--���ڽ���Ӷ��		
			,SUM(BGDL_NET_CMS)						AS 	  BGDL_NET_CMS        	--���ڽ��׾�Ӷ��			
			,SUM(BGDL_TRAN_FEE)						AS 	  BGDL_TRAN_FEE       	--���ڽ��׹�����			
			,SUM(PSTK_OPTN_CMS)						AS 	  PSTK_OPTN_CMS       	--������ȨӶ��			
			,SUM(PSTK_OPTN_NET_CMS)					AS 	  PSTK_OPTN_NET_CMS   	--������Ȩ��Ӷ��				
			,SUM(CREDIT_ODI_CMS)					AS 	  CREDIT_ODI_CMS      	--������ȯ��ͨӶ��				
			,SUM(CREDIT_ODI_NET_CMS)				AS 	  CREDIT_ODI_NET_CMS  	--������ȯ��ͨ��Ӷ��					
			,SUM(CREDIT_ODI_TRAN_FEE)				AS 	  CREDIT_ODI_TRAN_FEE 	--������ȯ��ͨ������					
			,SUM(CREDIT_CRED_CMS)					AS 	  CREDIT_CRED_CMS     	--������ȯ����Ӷ��				
			,SUM(CREDIT_CRED_NET_CMS)				AS 	  CREDIT_CRED_NET_CMS 	--������ȯ���þ�Ӷ��					
			,SUM(CREDIT_CRED_TRAN_FEE)				AS 	  CREDIT_CRED_TRAN_FEE	--������ȯ���ù�����					
			,SUM(FIN_RECE_INT)						AS 	  FIN_RECE_INT        	--����Ӧ����Ϣ			
			,SUM(FIN_PAIDINT)						AS 	  FIN_PAIDINT         	--����ʵ����Ϣ			
			,SUM(STKPLG_CMS)						AS 	  STKPLG_CMS          	--��Ʊ��ѺӶ��			
			,SUM(STKPLG_NET_CMS)					AS 	  STKPLG_NET_CMS      	--��Ʊ��Ѻ��Ӷ��				
			,SUM(STKPLG_PAIDINT)					AS 	  STKPLG_PAIDINT      	--��Ʊ��Ѻʵ����Ϣ				
			,SUM(STKPLG_RECE_INT)					AS 	  STKPLG_RECE_INT     	--��Ʊ��ѺӦ����Ϣ				
			,SUM(APPTBUYB_CMS)						AS 	  APPTBUYB_CMS        	--Լ������Ӷ��			
			,SUM(APPTBUYB_NET_CMS)					AS 	  APPTBUYB_NET_CMS    	--Լ�����ؾ�Ӷ��				
			,SUM(APPTBUYB_PAIDINT)					AS 	  APPTBUYB_PAIDINT    	--Լ������ʵ����Ϣ				
			,SUM(FIN_IE)							AS 	  FIN_IE              	--������Ϣ֧��		
			,SUM(CRDT_STK_IE)						AS 	  CRDT_STK_IE         	--��ȯ��Ϣ֧��			
			,SUM(OTH_IE)							AS 	  OTH_IE              	--������Ϣ֧��		
			,SUM(FEE_RECE_INT)						AS 	  FEE_RECE_INT        	--����Ӧ����Ϣ			
			,SUM(OTH_RECE_INT)						AS 	  OTH_RECE_INT        	--����Ӧ����Ϣ			
			,SUM(CREDIT_CPTL_COST)					AS 	  CREDIT_CPTL_COST      --������ȯ�ʽ�ɱ�							
		FROM #TMP_T_EVT_INCM_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_INCM_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ա��������ʵ���ձ�
  ��д��: Ҷ���
  ��������: 2018-04-11
  ��飺Ա������ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	DELETE FROM DM.T_EVT_INCM_D_EMP WHERE OCCUR_DT = @V_DATE;

	-- 1.1 ��T_EVT_TRD_D_EMP�Ļ����������ʽ��˺ţ��ͻ��ţ��ֶ���������ʱ��Ϊ��ȡ��Ȩ�����Ľ��Ȼ���ٸ���Ա��ά�Ȼ��ܷ����Ľ�

	CREATE TABLE #TMP_T_EVT_INCM_D_EMP(
			OCCUR_DT             numeric(8,0) NOT NULL,		--��������
			EMP_ID               varchar(30) NOT NULL,		--Ա������
			MAIN_CPTL_ACCT		 varchar(30) NOT NULL,		--�ʽ��˺�
			NET_CMS              numeric(38,8) NULL,		--��Ӷ��
			GROSS_CMS            numeric(38,8) NULL,		--ëӶ��
			SCDY_CMS             numeric(38,8) NULL,		--����Ӷ��
			SCDY_NET_CMS         numeric(38,8) NULL,		--������Ӷ��
			SCDY_TRAN_FEE        numeric(38,8) NULL,		--����������
			ODI_TRD_TRAN_FEE     numeric(38,8) NULL,		--��ͨ���׹�����
			ODI_TRD_STP_TAX      numeric(38,8) NULL,		--��ͨ����ӡ��˰
			ODI_TRD_HANDLE_FEE   numeric(38,8) NULL,		--��ͨ���׾��ַ�
			ODI_TRD_SEC_RGLT_FEE numeric(38,8) NULL,		--��ͨ����֤�ܷ� 
			ODI_TRD_ORDR_FEE     numeric(38,8) NULL,		--��ͨ����ί�з�
			ODI_TRD_OTH_FEE      numeric(38,8) NULL,		--��ͨ������������
			CRED_TRD_TRAN_FEE    numeric(38,8) NULL,		--���ý��׹�����
			CRED_TRD_STP_TAX     numeric(38,8) NULL,		--���ý���ӡ��˰
			CRED_TRD_HANDLE_FEE  numeric(38,8) NULL,		--���ý��׾��ַ�
			CRED_TRD_SEC_RGLT_FEE numeric(38,8) NULL,		--���ý���֤�ܷ�
			CRED_TRD_ORDR_FEE    numeric(38,8) NULL,		--���ý���ί�з�
			CRED_TRD_OTH_FEE     numeric(38,8) NULL,		--���ý�����������
			STKF_CMS             numeric(38,8) NULL,		--�ɻ�Ӷ��
			STKF_TRAN_FEE        numeric(38,8) NULL,		--�ɻ�������
			STKF_NET_CMS         numeric(38,8) NULL,		--�ɻ���Ӷ��
			BOND_CMS             numeric(38,8) NULL,		--ծȯӶ��
			BOND_NET_CMS         numeric(38,8) NULL,		--ծȯ��Ӷ��
			REPQ_CMS             numeric(38,8) NULL,		--���ۻع�Ӷ��
			REPQ_NET_CMS         numeric(38,8) NULL,		--���ۻع���Ӷ��
			HGT_CMS              numeric(38,8) NULL,		--����ͨӶ��
			HGT_NET_CMS          numeric(38,8) NULL,		--����ͨ��Ӷ��
			HGT_TRAN_FEE         numeric(38,8) NULL,		--����ͨ������
			SGT_CMS              numeric(38,8) NULL,		--���ͨӶ��
			SGT_NET_CMS          numeric(38,8) NULL,		--���ͨ��Ӷ��
			SGT_TRAN_FEE         numeric(38,8) NULL,		--���ͨ������
			BGDL_CMS             numeric(38,8) NULL,		--���ڽ���Ӷ��
			BGDL_NET_CMS         numeric(38,8) NULL,		--���ڽ��׾�Ӷ��
			BGDL_TRAN_FEE        numeric(38,8) NULL,		--���ڽ��׹�����
			PSTK_OPTN_CMS        numeric(38,8) NULL,		--������ȨӶ��
			PSTK_OPTN_NET_CMS    numeric(38,8) NULL,		--������Ȩ��Ӷ��
			CREDIT_ODI_CMS       numeric(38,8) NULL,		--������ȯ��ͨӶ��
			CREDIT_ODI_NET_CMS   numeric(38,8) NULL,		--������ȯ��ͨ��Ӷ��
			CREDIT_ODI_TRAN_FEE  numeric(38,8) NULL,		--������ȯ��ͨ������
			CREDIT_CRED_CMS      numeric(38,8) NULL,		--������ȯ����Ӷ��
			CREDIT_CRED_NET_CMS  numeric(38,8) NULL,		--������ȯ���þ�Ӷ��
			CREDIT_CRED_TRAN_FEE numeric(38,8) NULL,		--������ȯ���ù�����
			FIN_RECE_INT         numeric(38,8) NULL,		--����Ӧ����Ϣ
			FIN_PAIDINT          numeric(38,8) NULL,		--����ʵ����Ϣ
			STKPLG_CMS           numeric(38,8) NULL,		--��Ʊ��ѺӶ��
			STKPLG_NET_CMS       numeric(38,8) NULL,		--��Ʊ��Ѻ��Ӷ��
			STKPLG_PAIDINT       numeric(38,8) NULL,		--��Ʊ��Ѻʵ����Ϣ
			STKPLG_RECE_INT      numeric(38,8) NULL,		--��Ʊ��ѺӦ����Ϣ
			APPTBUYB_CMS         numeric(38,8) NULL,		--Լ������Ӷ��
			APPTBUYB_NET_CMS     numeric(38,8) NULL,		--Լ�����ؾ�Ӷ��
			APPTBUYB_PAIDINT     numeric(38,8) NULL,		--Լ������ʵ����Ϣ
			FIN_IE               numeric(38,8) NULL,		--������Ϣ֧��
			CRDT_STK_IE          numeric(38,8) NULL,		--��ȯ��Ϣ֧��
			OTH_IE               numeric(38,8) NULL,		--������Ϣ֧��
			FEE_RECE_INT         numeric(38,8) NULL,		--����Ӧ����Ϣ
			OTH_RECE_INT         numeric(38,8) NULL,		--����Ӧ����Ϣ
			CREDIT_CPTL_COST     numeric(38,8) NULL			--������ȯ�ʽ�ɱ�
	);

	INSERT INTO #TMP_T_EVT_INCM_D_EMP(
		 OCCUR_DT					
		,EMP_ID						
		,MAIN_CPTL_ACCT
	)			
	SELECT 
		 @V_DATE AS OCCUR_DT			--��������
		,A.AFATWO_YGH AS EMP_ID			--Ա������
		,A.ZJZH AS MAIN_CPTL_ACCT		--�ʽ��˺�
	FROM DBA.T_DDW_SERV_RELATION_D A
	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  		   ,A.ZJZH;

	-- ������Ȩ�����ͳ�ƣ�Ա��-�ͻ�����Ч�������

  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH;

	--���·����ĸ���ָ��
	UPDATE #TMP_T_EVT_INCM_D_EMP
		SET 
			 NET_CMS              	=  	COALESCE(B1.NET_CMS,0)					* 	C.PERFM_RATIO_4		--��Ӷ��				
			,GROSS_CMS            	=  	COALESCE(B1.GROSS_CMS,0)				* 	C.PERFM_RATIO_4		--ëӶ��				
			,SCDY_CMS             	=  	COALESCE(B1.SCDY_CMS,0)					* 	C.PERFM_RATIO_4		--����Ӷ��				
			,SCDY_NET_CMS         	=  	COALESCE(B1.SCDY_NET_CMS,0)				* 	C.PERFM_RATIO_4		--������Ӷ��				
			,SCDY_TRAN_FEE        	=  	COALESCE(B1.SCDY_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--����������				
			,ODI_TRD_TRAN_FEE     	=  	COALESCE(B1.ODI_TRD_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--��ͨ���׹�����				
			,ODI_TRD_STP_TAX      	=  	COALESCE(B1.ODI_TRD_STP_TAX,0)			* 	C.PERFM_RATIO_4		--��ͨ����ӡ��˰				
			,ODI_TRD_HANDLE_FEE   	=  	COALESCE(B1.ODI_TRD_HANDLE_FEE,0)		* 	C.PERFM_RATIO_4		--��ͨ���׾��ַ�					
			,ODI_TRD_SEC_RGLT_FEE 	=  	COALESCE(B1.ODI_TRD_SEC_RGLT_FEE,0)		* 	C.PERFM_RATIO_4		--��ͨ����֤�ܷ� 					
			--,ODI_TRD_ORDR_FEE     	=  	COALESCE(B1.ODI_TRD_ORDR_FEE,0)			* 	C.PERFM_RATIO_4		--��ͨ����ί�з�				
			,ODI_TRD_OTH_FEE      	=  	COALESCE(B1.ODI_TRD_OTH_FEE,0)			* 	C.PERFM_RATIO_4		--��ͨ������������					
			,CRED_TRD_TRAN_FEE    	=  	COALESCE(B2.CRED_TRD_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--���ý��׹�����					
			,CRED_TRD_STP_TAX     	=  	COALESCE(B2.CRED_TRD_STP_TAX,0)			* 	C.PERFM_RATIO_4		--���ý���ӡ��˰				
			,CRED_TRD_HANDLE_FEE  	=  	COALESCE(B2.CRED_TRD_HANDLE_FEE,0)		* 	C.PERFM_RATIO_4		--���ý��׾��ַ�					
			,CRED_TRD_SEC_RGLT_FEE	=  	COALESCE(B2.CRED_TRD_SEC_RGLT_FEE,0)	* 	C.PERFM_RATIO_4		--���ý���֤�ܷ�						
			,CRED_TRD_ORDR_FEE    	=  	COALESCE(B2.CRED_TRD_ORDR_FEE,0)		* 	C.PERFM_RATIO_4		--���ý���ί�з�					
			,CRED_TRD_OTH_FEE     	=  	COALESCE(B2.CRED_TRD_OTH_FEE,0)			* 	C.PERFM_RATIO_4		--���ý�����������					
			,STKF_CMS             	=  	COALESCE(B1.STKF_CMS,0)					* 	C.PERFM_RATIO_4		--�ɻ�Ӷ��				
			,STKF_TRAN_FEE        	=  	COALESCE(B1.STKF_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--�ɻ�������				
			,STKF_NET_CMS         	=  	COALESCE(B1.STKF_NET_CMS,0)				* 	C.PERFM_RATIO_4		--�ɻ���Ӷ��				
			,BOND_CMS             	=  	COALESCE(B1.BOND_CMS,0)					* 	C.PERFM_RATIO_4		--ծȯӶ��				
			,BOND_NET_CMS         	=  	COALESCE(B1.BOND_NET_CMS,0)				* 	C.PERFM_RATIO_4		--ծȯ��Ӷ��				
			,REPQ_CMS             	=  	COALESCE(B1.REPQ_CMS,0)					* 	C.PERFM_RATIO_4		--���ۻع�Ӷ��				
			,REPQ_NET_CMS         	=  	COALESCE(B1.REPQ_NET_CMS,0)				* 	C.PERFM_RATIO_4		--���ۻع���Ӷ��				
			,HGT_CMS              	=  	COALESCE(B1.HGT_CMS,0)					* 	C.PERFM_RATIO_4		--����ͨӶ��				
			,HGT_NET_CMS          	=  	COALESCE(B1.HGT_NET_CMS,0)				* 	C.PERFM_RATIO_4		--����ͨ��Ӷ��				
			,HGT_TRAN_FEE         	=  	COALESCE(B1.HGT_TRAN_FEE,0)				* 	C.PERFM_RATIO_4		--����ͨ������				
			,SGT_CMS              	=  	COALESCE(B1.SGT_CMS,0)					* 	C.PERFM_RATIO_4		--���ͨӶ��				
			,SGT_NET_CMS          	=  	COALESCE(B1.SGT_NET_CMS,0)				* 	C.PERFM_RATIO_4		--���ͨ��Ӷ��				
			,SGT_TRAN_FEE         	=  	COALESCE(B1.SGT_TRAN_FEE,0)				* 	C.PERFM_RATIO_4		--���ͨ������				
			,BGDL_CMS             	=  	COALESCE(B1.BGDL_CMS,0)					* 	C.PERFM_RATIO_4		--���ڽ���Ӷ��				
			,BGDL_NET_CMS         	=  	COALESCE(B1.BGDL_NET_CMS,0)				* 	C.PERFM_RATIO_4		--���ڽ��׾�Ӷ��				
			,BGDL_TRAN_FEE        	=  	COALESCE(B1.BGDL_TRAN_FEE,0)			* 	C.PERFM_RATIO_4		--���ڽ��׹�����				
			,PSTK_OPTN_CMS        	=  	COALESCE(B1.PSTK_OPTN_CMS,0)			* 	C.PERFM_RATIO_4		--������ȨӶ��				
			,PSTK_OPTN_NET_CMS    	=  	COALESCE(B1.PSTK_OPTN_NET_CMS,0)		* 	C.PERFM_RATIO_4		--������Ȩ��Ӷ��					
			,CREDIT_ODI_CMS       	=  	COALESCE(B2.CREDIT_ODI_CMS,0)			* 	C.PERFM_RATIO_4		--������ȯ��ͨӶ��				
			,CREDIT_ODI_NET_CMS   	=  	COALESCE(B2.CREDIT_ODI_NET_CMS,0)		* 	C.PERFM_RATIO_4		--������ȯ��ͨ��Ӷ��						
			,CREDIT_ODI_TRAN_FEE  	=  	COALESCE(B2.CREDIT_ODI_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--������ȯ��ͨ������						
			,CREDIT_CRED_CMS      	=  	COALESCE(B2.CREDIT_CRED_CMS,0)			* 	C.PERFM_RATIO_4		--������ȯ����Ӷ��					
			,CREDIT_CRED_NET_CMS  	=  	COALESCE(B2.CREDIT_CRED_NET_CMS,0)		* 	C.PERFM_RATIO_4		--������ȯ���þ�Ӷ��						
			,CREDIT_CRED_TRAN_FEE 	=  	COALESCE(B2.CREDIT_CRED_TRAN_FEE,0)		* 	C.PERFM_RATIO_4		--������ȯ���ù�����					
			,FIN_RECE_INT         	=  	COALESCE(B2.FIN_RECE_INT,0)				* 	C.PERFM_RATIO_4		--����Ӧ����Ϣ				
			,FIN_PAIDINT          	=  	COALESCE(B2.FIN_PAIDINT,0)				* 	C.PERFM_RATIO_4		--����ʵ����Ϣ				
			,STKPLG_CMS           	=  	COALESCE(B2.STKPLG_CMS,0)				* 	C.PERFM_RATIO_4		--��Ʊ��ѺӶ��				
			,STKPLG_NET_CMS       	=  	COALESCE(B2.STKPLG_NET_CMS,0)			* 	C.PERFM_RATIO_4		--��Ʊ��Ѻ��Ӷ��				
			,STKPLG_PAIDINT       	=  	COALESCE(B2.STKPLG_PAIDINT,0)			* 	C.PERFM_RATIO_4		--��Ʊ��Ѻʵ����Ϣ				
			,STKPLG_RECE_INT      	=  	COALESCE(B2.STKPLG_RECE_INT,0)			* 	C.PERFM_RATIO_4		--��Ʊ��ѺӦ����Ϣ					
			,APPTBUYB_CMS         	=  	COALESCE(B2.APPTBUYB_CMS,0)				* 	C.PERFM_RATIO_4		--Լ������Ӷ��				
			,APPTBUYB_NET_CMS     	=  	COALESCE(B2.APPTBUYB_NET_CMS,0)			* 	C.PERFM_RATIO_4		--Լ�����ؾ�Ӷ��				
			,APPTBUYB_PAIDINT     	=  	COALESCE(B2.APPTBUYB_PAIDINT,0)			* 	C.PERFM_RATIO_4		--Լ������ʵ����Ϣ					
			,FIN_IE               	=  	COALESCE(B2.FIN_IE,0)					* 	C.PERFM_RATIO_4		--������Ϣ֧��				
			,CRDT_STK_IE          	=  	COALESCE(B2.CRDT_STK_IE,0)				* 	C.PERFM_RATIO_4		--��ȯ��Ϣ֧��				
			,OTH_IE               	=  	COALESCE(B2.OTH_IE,0)					* 	C.PERFM_RATIO_4		--������Ϣ֧��				
			,FEE_RECE_INT         	=  	COALESCE(B2.FEE_RECE_INT,0)				* 	C.PERFM_RATIO_4		--����Ӧ����Ϣ				
			,OTH_RECE_INT         	=  	COALESCE(B2.OTH_RECE_INT,0)				* 	C.PERFM_RATIO_4		--����Ӧ����Ϣ				
			,CREDIT_CPTL_COST     	=  	COALESCE(B2.CREDIT_CPTL_COST,0)			* 	C.PERFM_RATIO_4		--������ȯ�ʽ�ɱ�									
		FROM #TMP_T_EVT_INCM_D_EMP A
		--�����ͻ���ͨ�����ձ�
		LEFT JOIN (
				SELECT
					 T.MAIN_CPTL_ACCT  			AS 		MAIN_CPTL_ACCT			--�ʽ��˺�
					,T.NET_CMS					AS 		NET_CMS             	--��Ӷ��	
					,T.GROSS_CMS				AS 		GROSS_CMS           	--ëӶ��	
					,T.SCDY_CMS					AS 		SCDY_CMS            	--����Ӷ��	
					,T.SCDY_NET_CMS				AS 		SCDY_NET_CMS        	--������Ӷ��		
					,T.SCDY_TRAN_FEE			AS 		SCDY_TRAN_FEE       	--����������		
					,T.TRAN_FEE					AS 		ODI_TRD_TRAN_FEE    	--��ͨ���׹�����	
					,T.STP_TAX					AS 		ODI_TRD_STP_TAX     	--��ͨ����ӡ��˰	
					,T.HANDLE_FEE				AS 		ODI_TRD_HANDLE_FEE  	--��ͨ���׾��ַ�		
					,T.SEC_RGLT_FEE				AS 		ODI_TRD_SEC_RGLT_FEE	--��ͨ����֤�ܷ� 		
					--,T.ORDR_FEE					AS 		ODI_TRD_ORDR_FEE    	--��ͨ����ί�з�	
					,T.OTH_FEE					AS 		ODI_TRD_OTH_FEE     	--��ͨ������������	
					,T.STKF_CMS					AS 		STKF_CMS         		--�ɻ�Ӷ��
					,T.STKF_TRAN_FEE			AS 		STKF_TRAN_FEE    		--�ɻ�������	
					,T.STKF_NET_CMS				AS 		STKF_NET_CMS     		--�ɻ���Ӷ��	
					,T.BOND_CMS					AS 		BOND_CMS         		--ծȯӶ��
					,T.BOND_NET_CMS				AS 		BOND_NET_CMS     		--ծȯ��Ӷ��	
					,T.REPQ_CMS					AS 		REPQ_CMS         		--���ۻع�Ӷ��
					,T.REPQ_NET_CMS				AS 		REPQ_NET_CMS     		--���ۻع���Ӷ��	
					,T.HGT_CMS     				AS 		HGT_CMS          		--����ͨӶ��	
					,T.HGT_NET_CMS 				AS 		HGT_NET_CMS      		--����ͨ��Ӷ��	
					,T.HGT_TRAN_FEE				AS 		HGT_TRAN_FEE     		--����ͨ������	
					,T.SGT_CMS     				AS 		SGT_CMS          		--���ͨӶ��	
					,T.SGT_NET_CMS 				AS 		SGT_NET_CMS      		--���ͨ��Ӷ��	
					,T.SGT_TRAN_FEE				AS 		SGT_TRAN_FEE     		--���ͨ������	
					,T.BGDL_CMS    				AS 		BGDL_CMS         		--���ڽ���Ӷ��	
					,T.BGDL_NET_CMS 			AS 		BGDL_NET_CMS     		--���ڽ��׾�Ӷ��	
					,T.BGDL_TRAN_FEE			AS 		BGDL_TRAN_FEE    		--���ڽ��׹�����	
					,T.PSTK_OPTN_CMS    		AS 		PSTK_OPTN_CMS    		--������ȨӶ��		
					,T.PSTK_OPTN_NET_CMS		AS 		PSTK_OPTN_NET_CMS		--������Ȩ��Ӷ��		
				FROM DM.T_EVT_ODI_INCM_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B1 ON A.MAIN_CPTL_ACCT=B1.MAIN_CPTL_ACCT
		LEFT JOIN (
				SELECT
					 T.MAIN_CPTL_ACCT 			AS 		MAIN_CPTL_ACCT			--�ʽ��˺�			
					,T.TRAN_FEE    				AS     	CRED_TRD_TRAN_FEE    	--���ý��׹�����					
					,T.STP_TAX     				AS     	CRED_TRD_STP_TAX     	--���ý���ӡ��˰					
					,T.HANDLE_FEE  				AS     	CRED_TRD_HANDLE_FEE  	--���ý��׾��ַ�					
					,T.SEC_RGLT_FEE				AS     	CRED_TRD_SEC_RGLT_FEE	--���ý���֤�ܷ�					
					,T.ORDR_FEE    				AS     	CRED_TRD_ORDR_FEE    	--���ý���ί�з�					
					,T.OTH_FEE     				AS     	CRED_TRD_OTH_FEE     	--���ý�����������					
					,T.CREDIT_ODI_CMS    		AS     	CREDIT_ODI_CMS      	--������ȯ��ͨӶ��							
					,T.CREDIT_ODI_NET_CMS		AS     	CREDIT_ODI_NET_CMS  	--������ȯ��ͨ��Ӷ��							
					,T.CREDIT_ODI_TRAN_FEE		AS     	CREDIT_ODI_TRAN_FEE 	--������ȯ��ͨ������							
					,T.CREDIT_CRED_CMS   		AS     	CREDIT_CRED_CMS     	--������ȯ����Ӷ��							
					,T.CREDIT_CRED_NET_CMS		AS     	CREDIT_CRED_NET_CMS 	--������ȯ���þ�Ӷ��							
					,T.CREDIT_CRED_TRAN_FEE		AS     	CREDIT_CRED_TRAN_FEE	--������ȯ���ù�����							
					,T.FIN_RECE_INT				AS     	FIN_RECE_INT        	--����Ӧ����Ϣ					
					,T.FIN_PAIDINT 				AS     	FIN_PAIDINT         	--����ʵ����Ϣ					
					,T.STKPLG_CMS     			AS     	STKPLG_CMS          	--��Ʊ��ѺӶ��						
					,T.STKPLG_NET_CMS 			AS     	STKPLG_NET_CMS      	--��Ʊ��Ѻ��Ӷ��						
					,T.STKPLG_PAIDINT 			AS     	STKPLG_PAIDINT      	--��Ʊ��Ѻʵ����Ϣ						
					,T.STKPLG_RECE_INT			AS     	STKPLG_RECE_INT     	--��Ʊ��ѺӦ����Ϣ						
					,T.APPTBUYB_CMS    			AS     	APPTBUYB_CMS        	--Լ������Ӷ��						
					,T.APPTBUYB_NET_CMS			AS     	APPTBUYB_NET_CMS    	--Լ�����ؾ�Ӷ��						
					,T.APPTBUYB_PAIDINT			AS     	APPTBUYB_PAIDINT    	--Լ������ʵ����Ϣ						
					,T.FIN_IE     				AS     	FIN_IE              	--������Ϣ֧��					
					,T.CRDT_STK_IE				AS     	CRDT_STK_IE         	--��ȯ��Ϣ֧��					
					,T.OTH_IE     				AS     	OTH_IE              	--������Ϣ֧��					
					,T.DAY_FIN_RECE_INT			AS     	FEE_RECE_INT        	--����Ӧ����Ϣ						
					,T.DAY_FEE_RECE_INT			AS     	OTH_RECE_INT        	--����Ӧ����Ϣ						
					,T.DAY_OTH_RECE_INT			AS     	CREDIT_CPTL_COST    	--������ȯ�ʽ�ɱ�							
				FROM DM.T_EVT_CRED_INCM_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B2 ON A.MAIN_CPTL_ACCT=B2.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--����ʱ��İ�Ա��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	INSERT INTO DM.T_EVT_INCM_D_EMP (
			 OCCUR_DT            	 	--��������
			,EMP_ID               		--Ա������
			,NET_CMS              		--��Ӷ��
			,GROSS_CMS            		--ëӶ��
			,SCDY_CMS             		--����Ӷ��
			,SCDY_NET_CMS         		--������Ӷ��
			,SCDY_TRAN_FEE        		--����������
			,ODI_TRD_TRAN_FEE     		--��ͨ���׹�����
			,ODI_TRD_STP_TAX      		--��ͨ����ӡ��˰
			,ODI_TRD_HANDLE_FEE   		--��ͨ���׾��ַ�
			,ODI_TRD_SEC_RGLT_FEE 		--��ͨ����֤�ܷ� 
			--,ODI_TRD_ORDR_FEE     		--��ͨ����ί�з�
			,ODI_TRD_OTH_FEE      		--��ͨ������������
			,CRED_TRD_TRAN_FEE    		--���ý��׹�����
			,CRED_TRD_STP_TAX     		--���ý���ӡ��˰
			,CRED_TRD_HANDLE_FEE  		--���ý��׾��ַ�
			,CRED_TRD_SEC_RGLT_FEE		--���ý���֤�ܷ�
			,CRED_TRD_ORDR_FEE    		--���ý���ί�з�
			,CRED_TRD_OTH_FEE     		--���ý�����������
			,STKF_CMS             		--�ɻ�Ӷ��
			,STKF_TRAN_FEE        		--�ɻ�������
			,STKF_NET_CMS         		--�ɻ���Ӷ��
			,BOND_CMS             		--ծȯӶ��
			,BOND_NET_CMS         		--ծȯ��Ӷ��
			,REPQ_CMS             		--���ۻع�Ӷ��
			,REPQ_NET_CMS         		--���ۻع���Ӷ��
			,HGT_CMS              		--����ͨӶ��
			,HGT_NET_CMS          		--����ͨ��Ӷ��
			,HGT_TRAN_FEE         		--����ͨ������
			,SGT_CMS              		--���ͨӶ��
			,SGT_NET_CMS          		--���ͨ��Ӷ��
			,SGT_TRAN_FEE         		--���ͨ������
			,BGDL_CMS             		--���ڽ���Ӷ��
			,BGDL_NET_CMS         		--���ڽ��׾�Ӷ��
			,BGDL_TRAN_FEE        		--���ڽ��׹�����
			,PSTK_OPTN_CMS        		--������ȨӶ��
			,PSTK_OPTN_NET_CMS    		--������Ȩ��Ӷ��
			,CREDIT_ODI_CMS       		--������ȯ��ͨӶ��
			,CREDIT_ODI_NET_CMS   		--������ȯ��ͨ��Ӷ��
			,CREDIT_ODI_TRAN_FEE  		--������ȯ��ͨ������
			,CREDIT_CRED_CMS      		--������ȯ����Ӷ��
			,CREDIT_CRED_NET_CMS  		--������ȯ���þ�Ӷ��
			,CREDIT_CRED_TRAN_FEE 		--������ȯ���ù�����
			,FIN_RECE_INT         		--����Ӧ����Ϣ
			,FIN_PAIDINT          		--����ʵ����Ϣ
			,STKPLG_CMS           		--��Ʊ��ѺӶ��
			,STKPLG_NET_CMS       		--��Ʊ��Ѻ��Ӷ��
			,STKPLG_PAIDINT       		--��Ʊ��Ѻʵ����Ϣ
			,STKPLG_RECE_INT      		--��Ʊ��ѺӦ����Ϣ
			,APPTBUYB_CMS         		--Լ������Ӷ��
			,APPTBUYB_NET_CMS     		--Լ�����ؾ�Ӷ��
			,APPTBUYB_PAIDINT     		--Լ������ʵ����Ϣ
			,FIN_IE               		--������Ϣ֧��
			,CRDT_STK_IE          		--��ȯ��Ϣ֧��
			,OTH_IE               		--������Ϣ֧��
			,FEE_RECE_INT         		--����Ӧ����Ϣ
			,OTH_RECE_INT         		--����Ӧ����Ϣ
			,CREDIT_CPTL_COST     		--������ȯ�ʽ�ɱ�
		)
		SELECT 
			 OCCUR_DT            			AS     OCCUR_DT            	 	--��������
			,EMP_ID               			AS     EMP_ID               	--Ա������
			,SUM(NET_CMS)              		AS     NET_CMS              	--��Ӷ��
			,SUM(GROSS_CMS)            		AS     GROSS_CMS            	--ëӶ��
			,SUM(SCDY_CMS)             		AS     SCDY_CMS             	--����Ӷ��
			,SUM(SCDY_NET_CMS)         		AS     SCDY_NET_CMS         	--������Ӷ��
			,SUM(SCDY_TRAN_FEE)        		AS     SCDY_TRAN_FEE        	--����������
			,SUM(ODI_TRD_TRAN_FEE)     		AS     ODI_TRD_TRAN_FEE     	--��ͨ���׹�����
			,SUM(ODI_TRD_STP_TAX)      		AS     ODI_TRD_STP_TAX      	--��ͨ����ӡ��˰
			,SUM(ODI_TRD_HANDLE_FEE)   		AS     ODI_TRD_HANDLE_FEE   	--��ͨ���׾��ַ�
			,SUM(ODI_TRD_SEC_RGLT_FEE) 		AS     ODI_TRD_SEC_RGLT_FEE 	--��ͨ����֤�ܷ� 
			--,SUM(ODI_TRD_ORDR_FEE)     		AS     ODI_TRD_ORDR_FEE     	--��ͨ����ί�з�
			,SUM(ODI_TRD_OTH_FEE)      		AS     ODI_TRD_OTH_FEE      	--��ͨ������������
			,SUM(CRED_TRD_TRAN_FEE)    		AS     CRED_TRD_TRAN_FEE    	--���ý��׹�����
			,SUM(CRED_TRD_STP_TAX)     		AS     CRED_TRD_STP_TAX     	--���ý���ӡ��˰
			,SUM(CRED_TRD_HANDLE_FEE)  		AS     CRED_TRD_HANDLE_FEE  	--���ý��׾��ַ�
			,SUM(CRED_TRD_SEC_RGLT_FEE)		AS     CRED_TRD_SEC_RGLT_FEE	--���ý���֤�ܷ�
			,SUM(CRED_TRD_ORDR_FEE)    		AS     CRED_TRD_ORDR_FEE    	--���ý���ί�з�
			,SUM(CRED_TRD_OTH_FEE)     		AS     CRED_TRD_OTH_FEE     	--���ý�����������
			,SUM(STKF_CMS)             		AS     STKF_CMS             	--�ɻ�Ӷ��
			,SUM(STKF_TRAN_FEE)        		AS     STKF_TRAN_FEE        	--�ɻ�������
			,SUM(STKF_NET_CMS)         		AS     STKF_NET_CMS         	--�ɻ���Ӷ��
			,SUM(BOND_CMS)             		AS     BOND_CMS             	--ծȯӶ��
			,SUM(BOND_NET_CMS)         		AS     BOND_NET_CMS         	--ծȯ��Ӷ��
			,SUM(REPQ_CMS)             		AS     REPQ_CMS             	--���ۻع�Ӷ��
			,SUM(REPQ_NET_CMS)         		AS     REPQ_NET_CMS         	--���ۻع���Ӷ��
			,SUM(HGT_CMS)              		AS     HGT_CMS              	--����ͨӶ��
			,SUM(HGT_NET_CMS)          		AS     HGT_NET_CMS          	--����ͨ��Ӷ��
			,SUM(HGT_TRAN_FEE)         		AS     HGT_TRAN_FEE         	--����ͨ������
			,SUM(SGT_CMS)              		AS     SGT_CMS              	--���ͨӶ��
			,SUM(SGT_NET_CMS)          		AS     SGT_NET_CMS          	--���ͨ��Ӷ��
			,SUM(SGT_TRAN_FEE)         		AS     SGT_TRAN_FEE         	--���ͨ������
			,SUM(BGDL_CMS)             		AS     BGDL_CMS             	--���ڽ���Ӷ��
			,SUM(BGDL_NET_CMS)         		AS     BGDL_NET_CMS         	--���ڽ��׾�Ӷ��
			,SUM(BGDL_TRAN_FEE)        		AS     BGDL_TRAN_FEE        	--���ڽ��׹�����
			,SUM(PSTK_OPTN_CMS)        		AS     PSTK_OPTN_CMS        	--������ȨӶ��
			,SUM(PSTK_OPTN_NET_CMS)    		AS     PSTK_OPTN_NET_CMS    	--������Ȩ��Ӷ��
			,SUM(CREDIT_ODI_CMS)       		AS     CREDIT_ODI_CMS       	--������ȯ��ͨӶ��
			,SUM(CREDIT_ODI_NET_CMS)   		AS     CREDIT_ODI_NET_CMS   	--������ȯ��ͨ��Ӷ��
			,SUM(CREDIT_ODI_TRAN_FEE)  		AS     CREDIT_ODI_TRAN_FEE  	--������ȯ��ͨ������
			,SUM(CREDIT_CRED_CMS)      		AS     CREDIT_CRED_CMS      	--������ȯ����Ӷ��
			,SUM(CREDIT_CRED_NET_CMS)  		AS     CREDIT_CRED_NET_CMS  	--������ȯ���þ�Ӷ��
			,SUM(CREDIT_CRED_TRAN_FEE) 		AS     CREDIT_CRED_TRAN_FEE 	--������ȯ���ù�����
			,SUM(FIN_RECE_INT)         		AS     FIN_RECE_INT         	--����Ӧ����Ϣ
			,SUM(FIN_PAIDINT)          		AS     FIN_PAIDINT          	--����ʵ����Ϣ
			,SUM(STKPLG_CMS)           		AS     STKPLG_CMS           	--��Ʊ��ѺӶ��
			,SUM(STKPLG_NET_CMS)       		AS     STKPLG_NET_CMS       	--��Ʊ��Ѻ��Ӷ��
			,SUM(STKPLG_PAIDINT)       		AS     STKPLG_PAIDINT       	--��Ʊ��Ѻʵ����Ϣ
			,SUM(STKPLG_RECE_INT)      		AS     STKPLG_RECE_INT      	--��Ʊ��ѺӦ����Ϣ
			,SUM(APPTBUYB_CMS)         		AS     APPTBUYB_CMS         	--Լ������Ӷ��
			,SUM(APPTBUYB_NET_CMS)     		AS     APPTBUYB_NET_CMS     	--Լ�����ؾ�Ӷ��
			,SUM(APPTBUYB_PAIDINT)     		AS     APPTBUYB_PAIDINT     	--Լ������ʵ����Ϣ
			,SUM(FIN_IE)               		AS     FIN_IE               	--������Ϣ֧��
			,SUM(CRDT_STK_IE)          		AS     CRDT_STK_IE          	--��ȯ��Ϣ֧��
			,SUM(OTH_IE)               		AS     OTH_IE               	--������Ϣ֧��
			,SUM(FEE_RECE_INT)         		AS     FEE_RECE_INT         	--����Ӧ����Ϣ
			,SUM(OTH_RECE_INT)         		AS     OTH_RECE_INT         	--����Ӧ����Ϣ
			,SUM(CREDIT_CPTL_COST)     		AS     CREDIT_CPTL_COST     	--������ȯ�ʽ�ɱ�		
		FROM #TMP_T_EVT_INCM_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_INCM_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ӫҵ��������ʵ���±�
  ��д��: Ҷ���
  ��������: 2018-04-11
  ��飺Ӫҵ������ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_INCM_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,BRH_ID              			AS    BRH_ID              	    --Ӫҵ������
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(NET_CMS)					AS    NET_CMS_MTD          		--��Ӷ��_���ۼ�
		,SUM(GROSS_CMS)					AS    GROSS_CMS_MTD        		--ëӶ��_���ۼ�
		,SUM(SCDY_CMS)					AS    SCDY_CMS_MTD         		--����Ӷ��_���ۼ�
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_MTD     		--������Ӷ��_���ۼ�
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_MTD    		--����������_���ۼ�
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_MTD 		--��ͨ���׹�����_���ۼ�
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_MTD		--���ý��׹�����_���ۼ�
		,SUM(STKF_CMS)					AS    STKF_CMS_MTD         		--�ɻ�Ӷ��_���ۼ�
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_MTD    		--�ɻ�������_���ۼ�
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_MTD     		--�ɻ���Ӷ��_���ۼ�
		,SUM(BOND_CMS)					AS    BOND_CMS_MTD         		--ծȯӶ��_���ۼ�
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_MTD     		--ծȯ��Ӷ��_���ۼ�
		,SUM(REPQ_CMS)					AS    REPQ_CMS_MTD         		--���ۻع�Ӷ��_���ۼ�
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_MTD     		--���ۻع���Ӷ��_���ۼ�
		,SUM(HGT_CMS)					AS    HGT_CMS_MTD          		--����ͨӶ��_���ۼ�
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_MTD      		--����ͨ��Ӷ��_���ۼ�
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_MTD     		--����ͨ������_���ۼ�
		,SUM(SGT_CMS)					AS    SGT_CMS_MTD          		--���ͨӶ��_���ۼ�
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_MTD      		--���ͨ��Ӷ��_���ۼ�
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_MTD     		--���ͨ������_���ۼ�
		,SUM(BGDL_CMS)					AS    BGDL_CMS_MTD         		--���ڽ���Ӷ��_���ۼ�
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_MTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_MTD    		--���ڽ��׹�����_���ۼ�
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_MTD    		--������ȨӶ��_���ۼ�
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_MTD 	--������Ȩ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_MTD   		--������ȯ��ͨӶ��_���ۼ�
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_MTD 	--������ȯ��ͨ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_MTD 	--������ȯ��ͨ������_���ۼ�
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_MTD  		--������ȯ����Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_MTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_MTD 	--������ȯ���ù�����_���ۼ�
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_MTD      		--����ʵ����Ϣ_���ۼ�
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_MTD       		--��Ʊ��ѺӶ��_���ۼ�
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_MTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_MTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_MTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_MTD     		--Լ������Ӷ��_���ۼ�
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_MTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_MTD 		--Լ������ʵ����Ϣ_���ۼ�
		,SUM(FIN_IE)					AS    FIN_IE_MTD           		--������Ϣ֧��_���ۼ�
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_MTD      		--��ȯ��Ϣ֧��_���ۼ�
		,SUM(OTH_IE)					AS    OTH_IE_MTD           		--������Ϣ֧��_���ۼ�
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_MTD 		--������ȯ�ʽ�ɱ�_���ۼ�
	INTO #TMP_T_EVT_INCM_D_BRH_MTH
	FROM DM.T_EVT_INCM_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,BRH_ID              			AS    BRH_ID              	    --Ӫҵ������
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(NET_CMS)					AS    NET_CMS_YTD          		--��Ӷ��_���ۼ�
		,SUM(GROSS_CMS)					AS    GROSS_CMS_YTD        		--ëӶ��_���ۼ�
		,SUM(SCDY_CMS)					AS    SCDY_CMS_YTD         		--����Ӷ��_���ۼ�
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_YTD     		--������Ӷ��_���ۼ�
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_YTD    		--����������_���ۼ�
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_YTD 		--��ͨ���׹�����_���ۼ�
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_YTD		--���ý��׹�����_���ۼ�
		,SUM(STKF_CMS)					AS    STKF_CMS_YTD         		--�ɻ�Ӷ��_���ۼ�
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_YTD    		--�ɻ�������_���ۼ�
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_YTD     		--�ɻ���Ӷ��_���ۼ�
		,SUM(BOND_CMS)					AS    BOND_CMS_YTD         		--ծȯӶ��_���ۼ�
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_YTD     		--ծȯ��Ӷ��_���ۼ�
		,SUM(REPQ_CMS)					AS    REPQ_CMS_YTD         		--���ۻع�Ӷ��_���ۼ�
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_YTD     		--���ۻع���Ӷ��_���ۼ�
		,SUM(HGT_CMS)					AS    HGT_CMS_YTD          		--����ͨӶ��_���ۼ�
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_YTD      		--����ͨ��Ӷ��_���ۼ�
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_YTD     		--����ͨ������_���ۼ�
		,SUM(SGT_CMS)					AS    SGT_CMS_YTD          		--���ͨӶ��_���ۼ�
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_YTD      		--���ͨ��Ӷ��_���ۼ�
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_YTD     		--���ͨ������_���ۼ�
		,SUM(BGDL_CMS)					AS    BGDL_CMS_YTD         		--���ڽ���Ӷ��_���ۼ�
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_YTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_YTD    		--���ڽ��׹�����_���ۼ�
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_YTD    		--������ȨӶ��_���ۼ�
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_YTD 	--������Ȩ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_YTD   		--������ȯ��ͨӶ��_���ۼ�
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_YTD 	--������ȯ��ͨ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_YTD 	--������ȯ��ͨ������_���ۼ�
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_YTD  		--������ȯ����Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_YTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_YTD 	--������ȯ���ù�����_���ۼ�
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_YTD      		--����ʵ����Ϣ_���ۼ�
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_YTD       		--��Ʊ��ѺӶ��_���ۼ�
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_YTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_YTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_YTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_YTD     		--Լ������Ӷ��_���ۼ�
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_YTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_YTD 		--Լ������ʵ����Ϣ_���ۼ�
		,SUM(FIN_IE)					AS    FIN_IE_YTD           		--������Ϣ֧��_���ۼ�
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_YTD      		--��ȯ��Ϣ֧��_���ۼ�
		,SUM(OTH_IE)					AS    OTH_IE_YTD           		--������Ϣ֧��_���ۼ�
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_YTD 		--������ȯ�ʽ�ɱ�_���ۼ�
	INTO #TMP_T_EVT_INCM_D_BRH_YEAR
	FROM DM.T_EVT_INCM_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--����Ŀ���
	INSERT INTO DM.T_EVT_INCM_M_BRH(
		 YEAR                 		--��
		,MTH                  		--��
		,BRH_ID              		--Ӫҵ������
		,OCCUR_DT             		--��������
		,NET_CMS_MTD          		--��Ӷ��_���ۼ�
		,GROSS_CMS_MTD        		--ëӶ��_���ۼ�
		,SCDY_CMS_MTD         		--����Ӷ��_���ۼ�
		,SCDY_NET_CMS_MTD     		--������Ӷ��_���ۼ�
		,SCDY_TRAN_FEE_MTD    		--����������_���ۼ�
		,ODI_TRD_TRAN_FEE_MTD 		--��ͨ���׹�����_���ۼ�
		,CRED_TRD_TRAN_FEE_MTD		--���ý��׹�����_���ۼ�
		,STKF_CMS_MTD         		--�ɻ�Ӷ��_���ۼ�
		,STKF_TRAN_FEE_MTD    		--�ɻ�������_���ۼ�
		,STKF_NET_CMS_MTD     		--�ɻ���Ӷ��_���ۼ�
		,BOND_CMS_MTD         		--ծȯӶ��_���ۼ�
		,BOND_NET_CMS_MTD     		--ծȯ��Ӷ��_���ۼ�
		,REPQ_CMS_MTD         		--���ۻع�Ӷ��_���ۼ�
		,REPQ_NET_CMS_MTD     		--���ۻع���Ӷ��_���ۼ�
		,HGT_CMS_MTD          		--����ͨӶ��_���ۼ�
		,HGT_NET_CMS_MTD      		--����ͨ��Ӷ��_���ۼ�
		,HGT_TRAN_FEE_MTD     		--����ͨ������_���ۼ�
		,SGT_CMS_MTD          		--���ͨӶ��_���ۼ�
		,SGT_NET_CMS_MTD      		--���ͨ��Ӷ��_���ۼ�
		,SGT_TRAN_FEE_MTD     		--���ͨ������_���ۼ�
		,BGDL_CMS_MTD         		--���ڽ���Ӷ��_���ۼ�
		,BGDL_NET_CMS_MTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,BGDL_TRAN_FEE_MTD    		--���ڽ��׹�����_���ۼ�
		,PSTK_OPTN_CMS_MTD    		--������ȨӶ��_���ۼ�
		,PSTK_OPTN_NET_CMS_MTD 		--������Ȩ��Ӷ��_���ۼ�
		,CREDIT_ODI_CMS_MTD   		--������ȯ��ͨӶ��_���ۼ�
		,CREDIT_ODI_NET_CMS_MTD 	--������ȯ��ͨ��Ӷ��_���ۼ�
		,CREDIT_ODI_TRAN_FEE_MTD 	--������ȯ��ͨ������_���ۼ�
		,CREDIT_CRED_CMS_MTD  		--������ȯ����Ӷ��_���ۼ�
		,CREDIT_CRED_NET_CMS_MTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,CREDIT_CRED_TRAN_FEE_MTD 	--������ȯ���ù�����_���ۼ�
		,FIN_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,FIN_PAIDINT_MTD      		--����ʵ����Ϣ_���ۼ�
		,STKPLG_CMS_MTD       		--��Ʊ��ѺӶ��_���ۼ�
		,STKPLG_NET_CMS_MTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,STKPLG_PAIDINT_MTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,STKPLG_RECE_INT_MTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,APPTBUYB_CMS_MTD     		--Լ������Ӷ��_���ۼ�
		,APPTBUYB_NET_CMS_MTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,APPTBUYB_PAIDINT_MTD 		--Լ������ʵ����Ϣ_���ۼ�
		,FIN_IE_MTD           		--������Ϣ֧��_���ۼ�
		,CRDT_STK_IE_MTD      		--��ȯ��Ϣ֧��_���ۼ�
		,OTH_IE_MTD           		--������Ϣ֧��_���ۼ�
		,FEE_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,OTH_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,CREDIT_CPTL_COST_MTD 		--������ȯ�ʽ�ɱ�_���ۼ�
		,NET_CMS_YTD          		--��Ӷ��_���ۼ�
		,GROSS_CMS_YTD        		--ëӶ��_���ۼ�
		,SCDY_CMS_YTD         		--����Ӷ��_���ۼ�
		,SCDY_NET_CMS_YTD     		--������Ӷ��_���ۼ�
		,SCDY_TRAN_FEE_YTD    		--����������_���ۼ�
		,ODI_TRD_TRAN_FEE_YTD 		--��ͨ���׹�����_���ۼ�
		,CRED_TRD_TRAN_FEE_YTD		--���ý��׹�����_���ۼ�
		,STKF_CMS_YTD         		--�ɻ�Ӷ��_���ۼ�
		,STKF_TRAN_FEE_YTD    		--�ɻ�������_���ۼ�
		,STKF_NET_CMS_YTD     		--�ɻ���Ӷ��_���ۼ�
		,BOND_CMS_YTD         		--ծȯӶ��_���ۼ�
		,BOND_NET_CMS_YTD     		--ծȯ��Ӷ��_���ۼ�
		,REPQ_CMS_YTD         		--���ۻع�Ӷ��_���ۼ�
		,REPQ_NET_CMS_YTD     		--���ۻع���Ӷ��_���ۼ�
		,HGT_CMS_YTD   				--����ͨӶ��_���ۼ�
		,HGT_NET_CMS_YTD       		--����ͨ��Ӷ��_���ۼ�
		,HGT_TRAN_FEE_YTD     		--����ͨ������_���ۼ�
		,SGT_CMS_YTD          		--���ͨӶ��_���ۼ�
		,SGT_NET_CMS_YTD      		--���ͨ��Ӷ��_���ۼ�
		,SGT_TRAN_FEE_YTD     		--���ͨ������_���ۼ�
		,BGDL_CMS_YTD         		--���ڽ���Ӷ��_���ۼ�
		,BGDL_NET_CMS_YTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,BGDL_TRAN_FEE_YTD    		--���ڽ��׹�����_���ۼ�
		,PSTK_OPTN_CMS_YTD    		--������ȨӶ��_���ۼ�
		,PSTK_OPTN_NET_CMS_YTD		--������Ȩ��Ӷ��_���ۼ�
		,CREDIT_ODI_CMS_YTD   		--������ȯ��ͨӶ��_���ۼ�
		,CREDIT_ODI_NET_CMS_YTD 	--������ȯ��ͨ��Ӷ��_���ۼ�	
		,CREDIT_ODI_TRAN_FEE_YTD 	--������ȯ��ͨ������_���ۼ�
		,CREDIT_CRED_CMS_YTD  		--������ȯ����Ӷ��_���ۼ�
		,CREDIT_CRED_NET_CMS_YTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,CREDIT_CRED_TRAN_FEE_YTD 	--������ȯ���ù�����_���ۼ�
		,FIN_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,FIN_PAIDINT_YTD      		--����ʵ����Ϣ_���ۼ�
		,STKPLG_CMS_YTD       		--��Ʊ��ѺӶ��_���ۼ�
		,STKPLG_NET_CMS_YTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,STKPLG_PAIDINT_YTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,STKPLG_RECE_INT_YTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,APPTBUYB_CMS_YTD     		--Լ������Ӷ��_���ۼ�
		,APPTBUYB_NET_CMS_YTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,APPTBUYB_PAIDINT_YTD 		--Լ������ʵ����Ϣ_���ۼ�
		,FIN_IE_YTD           		--������Ϣ֧��_���ۼ�
		,CRDT_STK_IE_YTD      		--��ȯ��Ϣ֧��_���ۼ�
		,OTH_IE_YTD           		--������Ϣ֧��_���ۼ�
		,FEE_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,OTH_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,CREDIT_CPTL_COST_YTD 		--������ȯ�ʽ�ɱ�_���ۼ�
	)		
	SELECT 
		 T1.YEAR                 				AS    YEAR                 			--��
		,T1.MTH                  				AS    MTH                  			--��
		,T1.BRH_ID              				AS    BRH_ID              	    	--Ӫҵ������
		,T1.OCCUR_DT             				AS    OCCUR_DT             			--��������
		,T1.NET_CMS_MTD          				AS    NET_CMS_MTD          			--��Ӷ��_���ۼ�
		,T1.GROSS_CMS_MTD        				AS    GROSS_CMS_MTD        			--ëӶ��_���ۼ�
		,T1.SCDY_CMS_MTD         				AS    SCDY_CMS_MTD         			--����Ӷ��_���ۼ�
		,T1.SCDY_NET_CMS_MTD     				AS    SCDY_NET_CMS_MTD     			--������Ӷ��_���ۼ�
		,T1.SCDY_TRAN_FEE_MTD    				AS    SCDY_TRAN_FEE_MTD    			--����������_���ۼ�
		,T1.ODI_TRD_TRAN_FEE_MTD 				AS    ODI_TRD_TRAN_FEE_MTD 			--��ͨ���׹�����_���ۼ�
		,T1.CRED_TRD_TRAN_FEE_MTD				AS    CRED_TRD_TRAN_FEE_MTD			--���ý��׹�����_���ۼ�
		,T1.STKF_CMS_MTD         				AS    STKF_CMS_MTD         			--�ɻ�Ӷ��_���ۼ�
		,T1.STKF_TRAN_FEE_MTD    				AS    STKF_TRAN_FEE_MTD    			--�ɻ�������_���ۼ�
		,T1.STKF_NET_CMS_MTD     				AS    STKF_NET_CMS_MTD     			--�ɻ���Ӷ��_���ۼ�
		,T1.BOND_CMS_MTD         				AS    BOND_CMS_MTD         			--ծȯӶ��_���ۼ�
		,T1.BOND_NET_CMS_MTD     				AS    BOND_NET_CMS_MTD     			--ծȯ��Ӷ��_���ۼ�
		,T1.REPQ_CMS_MTD         				AS    REPQ_CMS_MTD         			--���ۻع�Ӷ��_���ۼ�
		,T1.REPQ_NET_CMS_MTD     				AS    REPQ_NET_CMS_MTD     			--���ۻع���Ӷ��_���ۼ�
		,T1.HGT_CMS_MTD          				AS    HGT_CMS_MTD          			--����ͨӶ��_���ۼ�
		,T1.HGT_NET_CMS_MTD      				AS    HGT_NET_CMS_MTD      			--����ͨ��Ӷ��_���ۼ�
		,T1.HGT_TRAN_FEE_MTD     				AS    HGT_TRAN_FEE_MTD     			--����ͨ������_���ۼ�
		,T1.SGT_CMS_MTD          				AS    SGT_CMS_MTD          			--���ͨӶ��_���ۼ�
		,T1.SGT_NET_CMS_MTD      				AS    SGT_NET_CMS_MTD      			--���ͨ��Ӷ��_���ۼ�
		,T1.SGT_TRAN_FEE_MTD     				AS    SGT_TRAN_FEE_MTD     			--���ͨ������_���ۼ�
		,T1.BGDL_CMS_MTD         				AS    BGDL_CMS_MTD         			--���ڽ���Ӷ��_���ۼ�
		,T1.BGDL_NET_CMS_MTD     				AS    BGDL_NET_CMS_MTD     			--���ڽ��׾�Ӷ��_���ۼ�
		,T1.BGDL_TRAN_FEE_MTD    				AS    BGDL_TRAN_FEE_MTD    			--���ڽ��׹�����_���ۼ�
		,T1.PSTK_OPTN_CMS_MTD    				AS    PSTK_OPTN_CMS_MTD    			--������ȨӶ��_���ۼ�
		,T1.PSTK_OPTN_NET_CMS_MTD 				AS    PSTK_OPTN_NET_CMS_MTD 		--������Ȩ��Ӷ��_���ۼ�
		,T1.CREDIT_ODI_CMS_MTD   				AS    CREDIT_ODI_CMS_MTD   			--������ȯ��ͨӶ��_���ۼ�
		,T1.CREDIT_ODI_NET_CMS_MTD 				AS    CREDIT_ODI_NET_CMS_MTD 		--������ȯ��ͨ��Ӷ��_���ۼ�
		,T1.CREDIT_ODI_TRAN_FEE_MTD 			AS    CREDIT_ODI_TRAN_FEE_MTD 		--������ȯ��ͨ������_���ۼ�
		,T1.CREDIT_CRED_CMS_MTD  				AS    CREDIT_CRED_CMS_MTD  			--������ȯ����Ӷ��_���ۼ�
		,T1.CREDIT_CRED_NET_CMS_MTD 			AS    CREDIT_CRED_NET_CMS_MTD 		--������ȯ���þ�Ӷ��_���ۼ�
		,T1.CREDIT_CRED_TRAN_FEE_MTD 			AS    CREDIT_CRED_TRAN_FEE_MTD 		--������ȯ���ù�����_���ۼ�
		,T1.FIN_RECE_INT_MTD     				AS    FIN_RECE_INT_MTD     			--����Ӧ����Ϣ_���ۼ�
		,T1.FIN_PAIDINT_MTD      				AS    FIN_PAIDINT_MTD      			--����ʵ����Ϣ_���ۼ�
		,T1.STKPLG_CMS_MTD       				AS    STKPLG_CMS_MTD       			--��Ʊ��ѺӶ��_���ۼ�
		,T1.STKPLG_NET_CMS_MTD   				AS    STKPLG_NET_CMS_MTD   			--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,T1.STKPLG_PAIDINT_MTD   				AS    STKPLG_PAIDINT_MTD   			--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,T1.STKPLG_RECE_INT_MTD  				AS    STKPLG_RECE_INT_MTD  			--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,T1.APPTBUYB_CMS_MTD     				AS    APPTBUYB_CMS_MTD     			--Լ������Ӷ��_���ۼ�
		,T1.APPTBUYB_NET_CMS_MTD 				AS    APPTBUYB_NET_CMS_MTD 			--Լ�����ؾ�Ӷ��_���ۼ�
		,T1.APPTBUYB_PAIDINT_MTD 				AS    APPTBUYB_PAIDINT_MTD 			--Լ������ʵ����Ϣ_���ۼ�
		,T1.FIN_IE_MTD           				AS    FIN_IE_MTD           			--������Ϣ֧��_���ۼ�
		,T1.CRDT_STK_IE_MTD      				AS    CRDT_STK_IE_MTD      			--��ȯ��Ϣ֧��_���ۼ�
		,T1.OTH_IE_MTD           				AS    OTH_IE_MTD           			--������Ϣ֧��_���ۼ�
		,T1.FEE_RECE_INT_MTD     				AS    FEE_RECE_INT_MTD     			--����Ӧ����Ϣ_���ۼ�
		,T1.OTH_RECE_INT_MTD     				AS    OTH_RECE_INT_MTD     			--����Ӧ����Ϣ_���ۼ�
		,T1.CREDIT_CPTL_COST_MTD 				AS    CREDIT_CPTL_COST_MTD 			--������ȯ�ʽ�ɱ�_���ۼ�
		,T2.NET_CMS_YTD          				AS    NET_CMS_YTD          			--��Ӷ��_���ۼ�
		,T2.GROSS_CMS_YTD        				AS    GROSS_CMS_YTD        			--ëӶ��_���ۼ�
		,T2.SCDY_CMS_YTD         				AS    SCDY_CMS_YTD         			--����Ӷ��_���ۼ�
		,T2.SCDY_NET_CMS_YTD     				AS    SCDY_NET_CMS_YTD     			--������Ӷ��_���ۼ�
		,T2.SCDY_TRAN_FEE_YTD    				AS    SCDY_TRAN_FEE_YTD    			--����������_���ۼ�
		,T2.ODI_TRD_TRAN_FEE_YTD 				AS    ODI_TRD_TRAN_FEE_YTD 			--��ͨ���׹�����_���ۼ�
		,T2.CRED_TRD_TRAN_FEE_YTD				AS    CRED_TRD_TRAN_FEE_YTD			--���ý��׹�����_���ۼ�
		,T2.STKF_CMS_YTD         				AS    STKF_CMS_YTD         			--�ɻ�Ӷ��_���ۼ�
		,T2.STKF_TRAN_FEE_YTD    				AS    STKF_TRAN_FEE_YTD    			--�ɻ�������_���ۼ�
		,T2.STKF_NET_CMS_YTD     				AS    STKF_NET_CMS_YTD     			--�ɻ���Ӷ��_���ۼ�
		,T2.BOND_CMS_YTD         				AS    BOND_CMS_YTD         			--ծȯӶ��_���ۼ�
		,T2.BOND_NET_CMS_YTD     				AS    BOND_NET_CMS_YTD     			--ծȯ��Ӷ��_���ۼ�
		,T2.REPQ_CMS_YTD         				AS    REPQ_CMS_YTD         			--���ۻع�Ӷ��_���ۼ�
		,T2.REPQ_NET_CMS_YTD     				AS    REPQ_NET_CMS_YTD     			--���ۻع���Ӷ��_���ۼ�
		,T2.HGT_CMS_YTD   						AS    HGT_CMS_YTD   				--����ͨӶ��_���ۼ�
		,T2.HGT_NET_CMS_YTD      				AS    HGT_NET_CMS_YTD       		--����ͨ��Ӷ��_���ۼ�
		,T2.HGT_TRAN_FEE_YTD     				AS    HGT_TRAN_FEE_YTD     			--����ͨ������_���ۼ�
		,T2.SGT_CMS_YTD          				AS    SGT_CMS_YTD          			--���ͨӶ��_���ۼ�
		,T2.SGT_NET_CMS_YTD      				AS    SGT_NET_CMS_YTD      			--���ͨ��Ӷ��_���ۼ�
		,T2.SGT_TRAN_FEE_YTD     				AS    SGT_TRAN_FEE_YTD     			--���ͨ������_���ۼ�
		,T2.BGDL_CMS_YTD         				AS    BGDL_CMS_YTD         			--���ڽ���Ӷ��_���ۼ�
		,T2.BGDL_NET_CMS_YTD     				AS    BGDL_NET_CMS_YTD     			--���ڽ��׾�Ӷ��_���ۼ�
		,T2.BGDL_TRAN_FEE_YTD    				AS    BGDL_TRAN_FEE_YTD    			--���ڽ��׹�����_���ۼ�
		,T2.PSTK_OPTN_CMS_YTD    				AS    PSTK_OPTN_CMS_YTD    			--������ȨӶ��_���ۼ�
		,T2.PSTK_OPTN_NET_CMS_YTD				AS    PSTK_OPTN_NET_CMS_YTD			--������Ȩ��Ӷ��_���ۼ�
		,T2.CREDIT_ODI_CMS_YTD   				AS    CREDIT_ODI_CMS_YTD   			--������ȯ��ͨӶ��_���ۼ�
		,T2.CREDIT_ODI_NET_CMS_YTD 				AS    CREDIT_ODI_NET_CMS_YTD 		--������ȯ��ͨ��Ӷ��_���ۼ�	
		,T2.CREDIT_ODI_TRAN_FEE_YTD 			AS    CREDIT_ODI_TRAN_FEE_YTD 		--������ȯ��ͨ������_���ۼ�
		,T2.CREDIT_CRED_CMS_YTD  				AS    CREDIT_CRED_CMS_YTD  			--������ȯ����Ӷ��_���ۼ�
		,T2.CREDIT_CRED_NET_CMS_YTD 			AS    CREDIT_CRED_NET_CMS_YTD 		--������ȯ���þ�Ӷ��_���ۼ�
		,T2.CREDIT_CRED_TRAN_FEE_YTD 			AS    CREDIT_CRED_TRAN_FEE_YTD 		--������ȯ���ù�����_���ۼ�
		,T2.FIN_RECE_INT_YTD     				AS    FIN_RECE_INT_YTD     			--����Ӧ����Ϣ_���ۼ�
		,T2.FIN_PAIDINT_YTD      				AS    FIN_PAIDINT_YTD      			--����ʵ����Ϣ_���ۼ�
		,T2.STKPLG_CMS_YTD       				AS    STKPLG_CMS_YTD       			--��Ʊ��ѺӶ��_���ۼ�
		,T2.STKPLG_NET_CMS_YTD   				AS    STKPLG_NET_CMS_YTD   			--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,T2.STKPLG_PAIDINT_YTD   				AS    STKPLG_PAIDINT_YTD   			--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,T2.STKPLG_RECE_INT_YTD  				AS    STKPLG_RECE_INT_YTD  			--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,T2.APPTBUYB_CMS_YTD     				AS    APPTBUYB_CMS_YTD     			--Լ������Ӷ��_���ۼ�
		,T2.APPTBUYB_NET_CMS_YTD 				AS    APPTBUYB_NET_CMS_YTD 			--Լ�����ؾ�Ӷ��_���ۼ�
		,T2.APPTBUYB_PAIDINT_YTD 				AS    APPTBUYB_PAIDINT_YTD 			--Լ������ʵ����Ϣ_���ۼ�
		,T2.FIN_IE_YTD           				AS    FIN_IE_YTD           			--������Ϣ֧��_���ۼ�
		,T2.CRDT_STK_IE_YTD      				AS    CRDT_STK_IE_YTD      			--��ȯ��Ϣ֧��_���ۼ�
		,T2.OTH_IE_YTD           				AS    OTH_IE_YTD           			--������Ϣ֧��_���ۼ�
		,T2.FEE_RECE_INT_YTD     				AS    FEE_RECE_INT_YTD     			--����Ӧ����Ϣ_���ۼ�
		,T2.OTH_RECE_INT_YTD     				AS    OTH_RECE_INT_YTD     			--����Ӧ����Ϣ_���ۼ�
		,T2.CREDIT_CPTL_COST_YTD 				AS    CREDIT_CPTL_COST_YTD 			--������ȯ�ʽ�ɱ�_���ۼ�	
	FROM #TMP_T_EVT_INCM_D_BRH_MTH T1,#TMP_T_EVT_INCM_D_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_INCM_M_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ա��������ʵ���±�
  ��д��: Ҷ���
  ��������: 2018-04-11
  ��飺Ա������ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_INCM_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,EMP_ID							AS    EMP_ID                	--Ա������	
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(NET_CMS)					AS    NET_CMS_MTD          		--��Ӷ��_���ۼ�
		,SUM(GROSS_CMS)					AS    GROSS_CMS_MTD        		--ëӶ��_���ۼ�
		,SUM(SCDY_CMS)					AS    SCDY_CMS_MTD         		--����Ӷ��_���ۼ�
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_MTD     		--������Ӷ��_���ۼ�
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_MTD    		--����������_���ۼ�
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_MTD 		--��ͨ���׹�����_���ۼ�
		,SUM(ODI_TRD_STP_TAX)			AS    ODI_TRD_STP_TAX_MTD  		--��ͨ����ӡ��˰_���ۼ�
		,SUM(ODI_TRD_HANDLE_FEE)		AS    ODI_TRD_HANDLE_FEE_MTD 	--��ͨ���׾��ַ�_���ۼ�
		,SUM(ODI_TRD_SEC_RGLT_FEE)		AS    ODI_TRD_SEC_RGLT_FEE_MTD 	--��ͨ����֤�ܷ� _���ۼ�
		,SUM(ODI_TRD_ORDR_FEE)			AS    ODI_TRD_ORDR_FEE_MTD 		--��ͨ����ί�з�_���ۼ�
		,SUM(ODI_TRD_OTH_FEE)			AS    ODI_TRD_OTH_FEE_MTD  		--��ͨ������������_���ۼ�
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_MTD		--���ý��׹�����_���ۼ�
		,SUM(CRED_TRD_STP_TAX)			AS    CRED_TRD_STP_TAX_MTD 		--���ý���ӡ��˰_���ۼ�
		,SUM(CRED_TRD_HANDLE_FEE)		AS    CRED_TRD_HANDLE_FEE_MTD 	--���ý��׾��ַ�_���ۼ�
		,SUM(CRED_TRD_SEC_RGLT_FEE)		AS    CRED_TRD_SEC_RGLT_FEE_MTD --���ý���֤�ܷ�_���ۼ�
		,SUM(CRED_TRD_ORDR_FEE)			AS    CRED_TRD_ORDR_FEE_MTD 	--���ý���ί�з�_���ۼ�
		,SUM(CRED_TRD_OTH_FEE)			AS    CRED_TRD_OTH_FEE_MTD 		--���ý�����������_���ۼ�
		,SUM(STKF_CMS)					AS    STKF_CMS_MTD         		--�ɻ�Ӷ��_���ۼ�
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_MTD    		--�ɻ�������_���ۼ�
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_MTD     		--�ɻ���Ӷ��_���ۼ�
		,SUM(BOND_CMS)					AS    BOND_CMS_MTD         		--ծȯӶ��_���ۼ�
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_MTD     		--ծȯ��Ӷ��_���ۼ�
		,SUM(REPQ_CMS)					AS    REPQ_CMS_MTD         		--���ۻع�Ӷ��_���ۼ�
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_MTD     		--���ۻع���Ӷ��_���ۼ�
		,SUM(HGT_CMS)					AS    HGT_CMS_MTD          		--����ͨӶ��_���ۼ�
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_MTD      		--����ͨ��Ӷ��_���ۼ�
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_MTD     		--����ͨ������_���ۼ�
		,SUM(SGT_CMS)					AS    SGT_CMS_MTD          		--���ͨӶ��_���ۼ�
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_MTD      		--���ͨ��Ӷ��_���ۼ�
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_MTD     		--���ͨ������_���ۼ�
		,SUM(BGDL_CMS)					AS    BGDL_CMS_MTD         		--���ڽ���Ӷ��_���ۼ�
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_MTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_MTD    		--���ڽ��׹�����_���ۼ�
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_MTD    		--������ȨӶ��_���ۼ�
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_MTD 	--������Ȩ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_MTD   		--������ȯ��ͨӶ��_���ۼ�
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_MTD 	--������ȯ��ͨ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_MTD 	--������ȯ��ͨ������_���ۼ�
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_MTD  		--������ȯ����Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_MTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_MTD 	--������ȯ���ù�����_���ۼ�
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_MTD      		--����ʵ����Ϣ_���ۼ�
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_MTD       		--��Ʊ��ѺӶ��_���ۼ�
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_MTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_MTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_MTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_MTD     		--Լ������Ӷ��_���ۼ�
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_MTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_MTD 		--Լ������ʵ����Ϣ_���ۼ�
		,SUM(FIN_IE)					AS    FIN_IE_MTD           		--������Ϣ֧��_���ۼ�
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_MTD      		--��ȯ��Ϣ֧��_���ۼ�
		,SUM(OTH_IE)					AS    OTH_IE_MTD           		--������Ϣ֧��_���ۼ�
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_MTD 		--������ȯ�ʽ�ɱ�_���ۼ�
	INTO #TMP_T_EVT_INCM_D_EMP_MTH
	FROM DM.T_EVT_INCM_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,EMP_ID							AS    EMP_ID                	--Ա������	
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(NET_CMS)					AS    NET_CMS_YTD          		--��Ӷ��_���ۼ�
		,SUM(GROSS_CMS)					AS    GROSS_CMS_YTD        		--ëӶ��_���ۼ�
		,SUM(SCDY_CMS)					AS    SCDY_CMS_YTD         		--����Ӷ��_���ۼ�
		,SUM(SCDY_NET_CMS)				AS    SCDY_NET_CMS_YTD     		--������Ӷ��_���ۼ�
		,SUM(SCDY_TRAN_FEE)				AS    SCDY_TRAN_FEE_YTD    		--����������_���ۼ�
		,SUM(ODI_TRD_TRAN_FEE)			AS    ODI_TRD_TRAN_FEE_YTD 		--��ͨ���׹�����_���ۼ�
		,SUM(ODI_TRD_STP_TAX)			AS    ODI_TRD_STP_TAX_YTD  		--��ͨ����ӡ��˰_���ۼ�
		,SUM(ODI_TRD_HANDLE_FEE)		AS    ODI_TRD_HANDLE_FEE_YTD 	--��ͨ���׾��ַ�_���ۼ�
		,SUM(ODI_TRD_SEC_RGLT_FEE)		AS    ODI_TRD_SEC_RGLT_FEE_YTD 	--��ͨ����֤�ܷ� _���ۼ�
		,SUM(ODI_TRD_ORDR_FEE)			AS    ODI_TRD_ORDR_FEE_YTD 		--��ͨ����ί�з�_���ۼ�
		,SUM(ODI_TRD_OTH_FEE)			AS    ODI_TRD_OTH_FEE_YTD  		--��ͨ������������_���ۼ�
		,SUM(CRED_TRD_TRAN_FEE)			AS    CRED_TRD_TRAN_FEE_YTD		--���ý��׹�����_���ۼ�
		,SUM(CRED_TRD_STP_TAX)			AS    CRED_TRD_STP_TAX_YTD 		--���ý���ӡ��˰_���ۼ�
		,SUM(CRED_TRD_HANDLE_FEE)		AS    CRED_TRD_HANDLE_FEE_YTD 	--���ý��׾��ַ�_���ۼ�
		,SUM(CRED_TRD_SEC_RGLT_FEE)		AS    CRED_TRD_SEC_RGLT_FEE_YTD --���ý���֤�ܷ�_���ۼ�
		,SUM(CRED_TRD_ORDR_FEE)			AS    CRED_TRD_ORDR_FEE_YTD 	--���ý���ί�з�_���ۼ�
		,SUM(CRED_TRD_OTH_FEE)			AS    CRED_TRD_OTH_FEE_YTD 		--���ý�����������_���ۼ�
		,SUM(STKF_CMS)					AS    STKF_CMS_YTD         		--�ɻ�Ӷ��_���ۼ�
		,SUM(STKF_TRAN_FEE)				AS    STKF_TRAN_FEE_YTD    		--�ɻ�������_���ۼ�
		,SUM(STKF_NET_CMS)				AS    STKF_NET_CMS_YTD     		--�ɻ���Ӷ��_���ۼ�
		,SUM(BOND_CMS)					AS    BOND_CMS_YTD         		--ծȯӶ��_���ۼ�
		,SUM(BOND_NET_CMS)				AS    BOND_NET_CMS_YTD     		--ծȯ��Ӷ��_���ۼ�
		,SUM(REPQ_CMS)					AS    REPQ_CMS_YTD         		--���ۻع�Ӷ��_���ۼ�
		,SUM(REPQ_NET_CMS)				AS    REPQ_NET_CMS_YTD     		--���ۻع���Ӷ��_���ۼ�
		,SUM(HGT_CMS)					AS    HGT_CMS_YTD          		--����ͨӶ��_���ۼ�
		,SUM(HGT_NET_CMS)				AS    HGT_NET_CMS_YTD      		--����ͨ��Ӷ��_���ۼ�
		,SUM(HGT_TRAN_FEE)				AS    HGT_TRAN_FEE_YTD     		--����ͨ������_���ۼ�
		,SUM(SGT_CMS)					AS    SGT_CMS_YTD          		--���ͨӶ��_���ۼ�
		,SUM(SGT_NET_CMS)				AS    SGT_NET_CMS_YTD      		--���ͨ��Ӷ��_���ۼ�
		,SUM(SGT_TRAN_FEE)				AS    SGT_TRAN_FEE_YTD     		--���ͨ������_���ۼ�
		,SUM(BGDL_CMS)					AS    BGDL_CMS_YTD         		--���ڽ���Ӷ��_���ۼ�
		,SUM(BGDL_NET_CMS)				AS    BGDL_NET_CMS_YTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,SUM(BGDL_TRAN_FEE)				AS    BGDL_TRAN_FEE_YTD    		--���ڽ��׹�����_���ۼ�
		,SUM(PSTK_OPTN_CMS)				AS    PSTK_OPTN_CMS_YTD    		--������ȨӶ��_���ۼ�
		,SUM(PSTK_OPTN_NET_CMS)			AS    PSTK_OPTN_NET_CMS_YTD 	--������Ȩ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_CMS)			AS    CREDIT_ODI_CMS_YTD   		--������ȯ��ͨӶ��_���ۼ�
		,SUM(CREDIT_ODI_NET_CMS)		AS    CREDIT_ODI_NET_CMS_YTD 	--������ȯ��ͨ��Ӷ��_���ۼ�
		,SUM(CREDIT_ODI_TRAN_FEE)		AS    CREDIT_ODI_TRAN_FEE_YTD 	--������ȯ��ͨ������_���ۼ�
		,SUM(CREDIT_CRED_CMS)			AS    CREDIT_CRED_CMS_YTD  		--������ȯ����Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_NET_CMS)		AS    CREDIT_CRED_NET_CMS_YTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,SUM(CREDIT_CRED_TRAN_FEE)		AS    CREDIT_CRED_TRAN_FEE_YTD 	--������ȯ���ù�����_���ۼ�
		,SUM(FIN_RECE_INT)				AS    FIN_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(FIN_PAIDINT)				AS    FIN_PAIDINT_YTD      		--����ʵ����Ϣ_���ۼ�
		,SUM(STKPLG_CMS)				AS    STKPLG_CMS_YTD       		--��Ʊ��ѺӶ��_���ۼ�
		,SUM(STKPLG_NET_CMS)			AS    STKPLG_NET_CMS_YTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,SUM(STKPLG_PAIDINT)			AS    STKPLG_PAIDINT_YTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,SUM(STKPLG_RECE_INT)			AS    STKPLG_RECE_INT_YTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,SUM(APPTBUYB_CMS)				AS    APPTBUYB_CMS_YTD     		--Լ������Ӷ��_���ۼ�
		,SUM(APPTBUYB_NET_CMS)			AS    APPTBUYB_NET_CMS_YTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,SUM(APPTBUYB_PAIDINT)			AS    APPTBUYB_PAIDINT_YTD 		--Լ������ʵ����Ϣ_���ۼ�
		,SUM(FIN_IE)					AS    FIN_IE_YTD           		--������Ϣ֧��_���ۼ�
		,SUM(CRDT_STK_IE)				AS    CRDT_STK_IE_YTD      		--��ȯ��Ϣ֧��_���ۼ�
		,SUM(OTH_IE)					AS    OTH_IE_YTD           		--������Ϣ֧��_���ۼ�
		,SUM(FEE_RECE_INT)				AS    FEE_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(OTH_RECE_INT)				AS    OTH_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,SUM(CREDIT_CPTL_COST)			AS    CREDIT_CPTL_COST_YTD 		--������ȯ�ʽ�ɱ�_���ۼ�
	INTO #TMP_T_EVT_INCM_D_EMP_YEAR
	FROM DM.T_EVT_INCM_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	--����Ŀ���
	INSERT INTO DM.T_EVT_INCM_M_EMP(
		 YEAR                 		--��
		,MTH                  		--��
		,EMP_ID               		--Ա������
		,OCCUR_DT             		--��������
		,NET_CMS_MTD          		--��Ӷ��_���ۼ�
		,GROSS_CMS_MTD        		--ëӶ��_���ۼ�
		,SCDY_CMS_MTD         		--����Ӷ��_���ۼ�
		,SCDY_NET_CMS_MTD     		--������Ӷ��_���ۼ�
		,SCDY_TRAN_FEE_MTD    		--����������_���ۼ�
		,ODI_TRD_TRAN_FEE_MTD 		--��ͨ���׹�����_���ۼ�
		,ODI_TRD_STP_TAX_MTD  		--��ͨ����ӡ��˰_���ۼ�
		,ODI_TRD_HANDLE_FEE_MTD 	--��ͨ���׾��ַ�_���ۼ�
		,ODI_TRD_SEC_RGLT_FEE_MTD 	--��ͨ����֤�ܷ� _���ۼ�
		,ODI_TRD_ORDR_FEE_MTD 		--��ͨ����ί�з�_���ۼ�
		,ODI_TRD_OTH_FEE_MTD  		--��ͨ������������_���ۼ�
		,CRED_TRD_TRAN_FEE_MTD		--���ý��׹�����_���ۼ�
		,CRED_TRD_STP_TAX_MTD 		--���ý���ӡ��˰_���ۼ�
		,CRED_TRD_HANDLE_FEE_MTD 	--���ý��׾��ַ�_���ۼ�
		,CRED_TRD_SEC_RGLT_FEE_MTD 	--���ý���֤�ܷ�_���ۼ�
		,CRED_TRD_ORDR_FEE_MTD 		--���ý���ί�з�_���ۼ�
		,CRED_TRD_OTH_FEE_MTD 		--���ý�����������_���ۼ�
		,STKF_CMS_MTD         		--�ɻ�Ӷ��_���ۼ�
		,STKF_TRAN_FEE_MTD    		--�ɻ�������_���ۼ�
		,STKF_NET_CMS_MTD     		--�ɻ���Ӷ��_���ۼ�
		,BOND_CMS_MTD         		--ծȯӶ��_���ۼ�
		,BOND_NET_CMS_MTD     		--ծȯ��Ӷ��_���ۼ�
		,REPQ_CMS_MTD         		--���ۻع�Ӷ��_���ۼ�
		,REPQ_NET_CMS_MTD     		--���ۻع���Ӷ��_���ۼ�
		,HGT_CMS_MTD          		--����ͨӶ��_���ۼ�
		,HGT_NET_CMS_MTD      		--����ͨ��Ӷ��_���ۼ�
		,HGT_TRAN_FEE_MTD     		--����ͨ������_���ۼ�
		,SGT_CMS_MTD          		--���ͨӶ��_���ۼ�
		,SGT_NET_CMS_MTD      		--���ͨ��Ӷ��_���ۼ�
		,SGT_TRAN_FEE_MTD     		--���ͨ������_���ۼ�
		,BGDL_CMS_MTD         		--���ڽ���Ӷ��_���ۼ�
		,BGDL_NET_CMS_MTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,BGDL_TRAN_FEE_MTD    		--���ڽ��׹�����_���ۼ�
		,PSTK_OPTN_CMS_MTD    		--������ȨӶ��_���ۼ�
		,PSTK_OPTN_NET_CMS_MTD 		--������Ȩ��Ӷ��_���ۼ�
		,CREDIT_ODI_CMS_MTD   		--������ȯ��ͨӶ��_���ۼ�
		,CREDIT_ODI_NET_CMS_MTD 	--������ȯ��ͨ��Ӷ��_���ۼ�
		,CREDIT_ODI_TRAN_FEE_MTD 	--������ȯ��ͨ������_���ۼ�
		,CREDIT_CRED_CMS_MTD  		--������ȯ����Ӷ��_���ۼ�
		,CREDIT_CRED_NET_CMS_MTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,CREDIT_CRED_TRAN_FEE_MTD 	--������ȯ���ù�����_���ۼ�
		,FIN_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,FIN_PAIDINT_MTD      		--����ʵ����Ϣ_���ۼ�
		,STKPLG_CMS_MTD       		--��Ʊ��ѺӶ��_���ۼ�
		,STKPLG_NET_CMS_MTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,STKPLG_PAIDINT_MTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,STKPLG_RECE_INT_MTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,APPTBUYB_CMS_MTD     		--Լ������Ӷ��_���ۼ�
		,APPTBUYB_NET_CMS_MTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,APPTBUYB_PAIDINT_MTD 		--Լ������ʵ����Ϣ_���ۼ�
		,FIN_IE_MTD           		--������Ϣ֧��_���ۼ�
		,CRDT_STK_IE_MTD      		--��ȯ��Ϣ֧��_���ۼ�
		,OTH_IE_MTD           		--������Ϣ֧��_���ۼ�
		,FEE_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,OTH_RECE_INT_MTD     		--����Ӧ����Ϣ_���ۼ�
		,CREDIT_CPTL_COST_MTD 		--������ȯ�ʽ�ɱ�_���ۼ�
		,NET_CMS_YTD          		--��Ӷ��_���ۼ�
		,GROSS_CMS_YTD        		--ëӶ��_���ۼ�
		,SCDY_CMS_YTD         		--����Ӷ��_���ۼ�
		,SCDY_NET_CMS_YTD     		--������Ӷ��_���ۼ�
		,SCDY_TRAN_FEE_YTD    		--����������_���ۼ�
		,ODI_TRD_TRAN_FEE_YTD 		--��ͨ���׹�����_���ۼ�
		,ODI_TRD_STP_TAX_YTD  		--��ͨ����ӡ��˰_���ۼ�
		,ODI_TRD_HANDLE_FEE_YTD 	--��ͨ���׾��ַ�_���ۼ�	
		,ODI_TRD_SEC_RGLT_FEE_YTD 	--��ͨ����֤�ܷ� _���ۼ�
		,ODI_TRD_ORDR_FEE_YTD 		--��ͨ����ί�з�_���ۼ�
		,ODI_TRD_OTH_FEE_YTD  		--��ͨ������������_���ۼ�
		,CRED_TRD_TRAN_FEE_YTD		--���ý��׹�����_���ۼ�
		,CRED_TRD_STP_TAX_YTD 		--���ý���ӡ��˰_���ۼ�
		,CRED_TRD_HANDLE_FEE_YTD 	--���ý��׾��ַ�_���ۼ�
		,CRED_TRD_SEC_RGLT_FEE_YTD 	--���ý���֤�ܷ�_���ۼ�
		,CRED_TRD_ORDR_FEE_YTD 		--���ý���ί�з�_���ۼ�
		,CRED_TRD_OTH_FEE_YTD 		--���ý�����������_���ۼ�
		,STKF_CMS_YTD         		--�ɻ�Ӷ��_���ۼ�
		,STKF_TRAN_FEE_YTD    		--�ɻ�������_���ۼ�
		,STKF_NET_CMS_YTD     		--�ɻ���Ӷ��_���ۼ�
		,BOND_CMS_YTD         		--ծȯӶ��_���ۼ�
		,BOND_NET_CMS_YTD     		--ծȯ��Ӷ��_���ۼ�
		,REPQ_CMS_YTD         		--���ۻع�Ӷ��_���ۼ�
		,REPQ_NET_CMS_YTD     		--���ۻع���Ӷ��_���ۼ�
		,HGT_CMS_YTD   				--����ͨӶ��_���ۼ�
		,HGT_NET_CMS_YTD       		--����ͨ��Ӷ��_���ۼ�
		,HGT_TRAN_FEE_YTD     		--����ͨ������_���ۼ�
		,SGT_CMS_YTD          		--���ͨӶ��_���ۼ�
		,SGT_NET_CMS_YTD      		--���ͨ��Ӷ��_���ۼ�
		,SGT_TRAN_FEE_YTD     		--���ͨ������_���ۼ�
		,BGDL_CMS_YTD         		--���ڽ���Ӷ��_���ۼ�
		,BGDL_NET_CMS_YTD     		--���ڽ��׾�Ӷ��_���ۼ�
		,BGDL_TRAN_FEE_YTD    		--���ڽ��׹�����_���ۼ�
		,PSTK_OPTN_CMS_YTD    		--������ȨӶ��_���ۼ�
		,PSTK_OPTN_NET_CMS_YTD		--������Ȩ��Ӷ��_���ۼ�
		,CREDIT_ODI_CMS_YTD   		--������ȯ��ͨӶ��_���ۼ�
		,CREDIT_ODI_NET_CMS_YTD 	--������ȯ��ͨ��Ӷ��_���ۼ�	
		,CREDIT_ODI_TRAN_FEE_YTD 	--������ȯ��ͨ������_���ۼ�
		,CREDIT_CRED_CMS_YTD  		--������ȯ����Ӷ��_���ۼ�
		,CREDIT_CRED_NET_CMS_YTD 	--������ȯ���þ�Ӷ��_���ۼ�
		,CREDIT_CRED_TRAN_FEE_YTD 	--������ȯ���ù�����_���ۼ�
		,FIN_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,FIN_PAIDINT_YTD      		--����ʵ����Ϣ_���ۼ�
		,STKPLG_CMS_YTD       		--��Ʊ��ѺӶ��_���ۼ�
		,STKPLG_NET_CMS_YTD   		--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,STKPLG_PAIDINT_YTD   		--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,STKPLG_RECE_INT_YTD  		--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,APPTBUYB_CMS_YTD     		--Լ������Ӷ��_���ۼ�
		,APPTBUYB_NET_CMS_YTD 		--Լ�����ؾ�Ӷ��_���ۼ�
		,APPTBUYB_PAIDINT_YTD 		--Լ������ʵ����Ϣ_���ۼ�
		,FIN_IE_YTD           		--������Ϣ֧��_���ۼ�
		,CRDT_STK_IE_YTD      		--��ȯ��Ϣ֧��_���ۼ�
		,OTH_IE_YTD           		--������Ϣ֧��_���ۼ�
		,FEE_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,OTH_RECE_INT_YTD     		--����Ӧ����Ϣ_���ۼ�
		,CREDIT_CPTL_COST_YTD 		--������ȯ�ʽ�ɱ�_���ۼ�
	)		
	SELECT 
		 T1.YEAR                 				AS    YEAR                 			--��
		,T1.MTH                  				AS    MTH                  			--��
		,T1.EMP_ID               				AS    EMP_ID               			--Ա������
		,T1.OCCUR_DT             				AS    OCCUR_DT             			--��������
		,T1.NET_CMS_MTD          				AS    NET_CMS_MTD          			--��Ӷ��_���ۼ�
		,T1.GROSS_CMS_MTD        				AS    GROSS_CMS_MTD        			--ëӶ��_���ۼ�
		,T1.SCDY_CMS_MTD         				AS    SCDY_CMS_MTD         			--����Ӷ��_���ۼ�
		,T1.SCDY_NET_CMS_MTD     				AS    SCDY_NET_CMS_MTD     			--������Ӷ��_���ۼ�
		,T1.SCDY_TRAN_FEE_MTD    				AS    SCDY_TRAN_FEE_MTD    			--����������_���ۼ�
		,T1.ODI_TRD_TRAN_FEE_MTD 				AS    ODI_TRD_TRAN_FEE_MTD 			--��ͨ���׹�����_���ۼ�
		,T1.ODI_TRD_STP_TAX_MTD  				AS    ODI_TRD_STP_TAX_MTD  			--��ͨ����ӡ��˰_���ۼ�
		,T1.ODI_TRD_HANDLE_FEE_MTD 				AS    ODI_TRD_HANDLE_FEE_MTD 		--��ͨ���׾��ַ�_���ۼ�
		,T1.ODI_TRD_SEC_RGLT_FEE_MTD 			AS    ODI_TRD_SEC_RGLT_FEE_MTD 		--��ͨ����֤�ܷ� _���ۼ�
		,T1.ODI_TRD_ORDR_FEE_MTD 				AS    ODI_TRD_ORDR_FEE_MTD 			--��ͨ����ί�з�_���ۼ�
		,T1.ODI_TRD_OTH_FEE_MTD  				AS    ODI_TRD_OTH_FEE_MTD  			--��ͨ������������_���ۼ�
		,T1.CRED_TRD_TRAN_FEE_MTD				AS    CRED_TRD_TRAN_FEE_MTD			--���ý��׹�����_���ۼ�
		,T1.CRED_TRD_STP_TAX_MTD 				AS    CRED_TRD_STP_TAX_MTD 			--���ý���ӡ��˰_���ۼ�
		,T1.CRED_TRD_HANDLE_FEE_MTD 			AS    CRED_TRD_HANDLE_FEE_MTD 		--���ý��׾��ַ�_���ۼ�
		,T1.CRED_TRD_SEC_RGLT_FEE_MTD 			AS    CRED_TRD_SEC_RGLT_FEE_MTD 	--���ý���֤�ܷ�_���ۼ�
		,T1.CRED_TRD_ORDR_FEE_MTD 				AS    CRED_TRD_ORDR_FEE_MTD 		--���ý���ί�з�_���ۼ�
		,T1.CRED_TRD_OTH_FEE_MTD 				AS    CRED_TRD_OTH_FEE_MTD 			--���ý�����������_���ۼ�
		,T1.STKF_CMS_MTD         				AS    STKF_CMS_MTD         			--�ɻ�Ӷ��_���ۼ�
		,T1.STKF_TRAN_FEE_MTD    				AS    STKF_TRAN_FEE_MTD    			--�ɻ�������_���ۼ�
		,T1.STKF_NET_CMS_MTD     				AS    STKF_NET_CMS_MTD     			--�ɻ���Ӷ��_���ۼ�
		,T1.BOND_CMS_MTD         				AS    BOND_CMS_MTD         			--ծȯӶ��_���ۼ�
		,T1.BOND_NET_CMS_MTD     				AS    BOND_NET_CMS_MTD     			--ծȯ��Ӷ��_���ۼ�
		,T1.REPQ_CMS_MTD         				AS    REPQ_CMS_MTD         			--���ۻع�Ӷ��_���ۼ�
		,T1.REPQ_NET_CMS_MTD     				AS    REPQ_NET_CMS_MTD     			--���ۻع���Ӷ��_���ۼ�
		,T1.HGT_CMS_MTD          				AS    HGT_CMS_MTD          			--����ͨӶ��_���ۼ�
		,T1.HGT_NET_CMS_MTD      				AS    HGT_NET_CMS_MTD      			--����ͨ��Ӷ��_���ۼ�
		,T1.HGT_TRAN_FEE_MTD     				AS    HGT_TRAN_FEE_MTD     			--����ͨ������_���ۼ�
		,T1.SGT_CMS_MTD          				AS    SGT_CMS_MTD          			--���ͨӶ��_���ۼ�
		,T1.SGT_NET_CMS_MTD      				AS    SGT_NET_CMS_MTD      			--���ͨ��Ӷ��_���ۼ�
		,T1.SGT_TRAN_FEE_MTD     				AS    SGT_TRAN_FEE_MTD     			--���ͨ������_���ۼ�
		,T1.BGDL_CMS_MTD         				AS    BGDL_CMS_MTD         			--���ڽ���Ӷ��_���ۼ�
		,T1.BGDL_NET_CMS_MTD     				AS    BGDL_NET_CMS_MTD     			--���ڽ��׾�Ӷ��_���ۼ�
		,T1.BGDL_TRAN_FEE_MTD    				AS    BGDL_TRAN_FEE_MTD    			--���ڽ��׹�����_���ۼ�
		,T1.PSTK_OPTN_CMS_MTD    				AS    PSTK_OPTN_CMS_MTD    			--������ȨӶ��_���ۼ�
		,T1.PSTK_OPTN_NET_CMS_MTD 				AS    PSTK_OPTN_NET_CMS_MTD 		--������Ȩ��Ӷ��_���ۼ�
		,T1.CREDIT_ODI_CMS_MTD   				AS    CREDIT_ODI_CMS_MTD   			--������ȯ��ͨӶ��_���ۼ�
		,T1.CREDIT_ODI_NET_CMS_MTD 				AS    CREDIT_ODI_NET_CMS_MTD 		--������ȯ��ͨ��Ӷ��_���ۼ�
		,T1.CREDIT_ODI_TRAN_FEE_MTD 			AS    CREDIT_ODI_TRAN_FEE_MTD 		--������ȯ��ͨ������_���ۼ�
		,T1.CREDIT_CRED_CMS_MTD  				AS    CREDIT_CRED_CMS_MTD  			--������ȯ����Ӷ��_���ۼ�
		,T1.CREDIT_CRED_NET_CMS_MTD 			AS    CREDIT_CRED_NET_CMS_MTD 		--������ȯ���þ�Ӷ��_���ۼ�
		,T1.CREDIT_CRED_TRAN_FEE_MTD 			AS    CREDIT_CRED_TRAN_FEE_MTD 		--������ȯ���ù�����_���ۼ�
		,T1.FIN_RECE_INT_MTD     				AS    FIN_RECE_INT_MTD     			--����Ӧ����Ϣ_���ۼ�
		,T1.FIN_PAIDINT_MTD      				AS    FIN_PAIDINT_MTD      			--����ʵ����Ϣ_���ۼ�
		,T1.STKPLG_CMS_MTD       				AS    STKPLG_CMS_MTD       			--��Ʊ��ѺӶ��_���ۼ�
		,T1.STKPLG_NET_CMS_MTD   				AS    STKPLG_NET_CMS_MTD   			--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,T1.STKPLG_PAIDINT_MTD   				AS    STKPLG_PAIDINT_MTD   			--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,T1.STKPLG_RECE_INT_MTD  				AS    STKPLG_RECE_INT_MTD  			--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,T1.APPTBUYB_CMS_MTD     				AS    APPTBUYB_CMS_MTD     			--Լ������Ӷ��_���ۼ�
		,T1.APPTBUYB_NET_CMS_MTD 				AS    APPTBUYB_NET_CMS_MTD 			--Լ�����ؾ�Ӷ��_���ۼ�
		,T1.APPTBUYB_PAIDINT_MTD 				AS    APPTBUYB_PAIDINT_MTD 			--Լ������ʵ����Ϣ_���ۼ�
		,T1.FIN_IE_MTD           				AS    FIN_IE_MTD           			--������Ϣ֧��_���ۼ�
		,T1.CRDT_STK_IE_MTD      				AS    CRDT_STK_IE_MTD      			--��ȯ��Ϣ֧��_���ۼ�
		,T1.OTH_IE_MTD           				AS    OTH_IE_MTD           			--������Ϣ֧��_���ۼ�
		,T1.FEE_RECE_INT_MTD     				AS    FEE_RECE_INT_MTD     			--����Ӧ����Ϣ_���ۼ�
		,T1.OTH_RECE_INT_MTD     				AS    OTH_RECE_INT_MTD     			--����Ӧ����Ϣ_���ۼ�
		,T1.CREDIT_CPTL_COST_MTD 				AS    CREDIT_CPTL_COST_MTD 			--������ȯ�ʽ�ɱ�_���ۼ�
		,T2.NET_CMS_YTD          				AS    NET_CMS_YTD          			--��Ӷ��_���ۼ�
		,T2.GROSS_CMS_YTD        				AS    GROSS_CMS_YTD        			--ëӶ��_���ۼ�
		,T2.SCDY_CMS_YTD         				AS    SCDY_CMS_YTD         			--����Ӷ��_���ۼ�
		,T2.SCDY_NET_CMS_YTD     				AS    SCDY_NET_CMS_YTD     			--������Ӷ��_���ۼ�
		,T2.SCDY_TRAN_FEE_YTD    				AS    SCDY_TRAN_FEE_YTD    			--����������_���ۼ�
		,T2.ODI_TRD_TRAN_FEE_YTD 				AS    ODI_TRD_TRAN_FEE_YTD 			--��ͨ���׹�����_���ۼ�
		,T2.ODI_TRD_STP_TAX_YTD  				AS    ODI_TRD_STP_TAX_YTD  			--��ͨ����ӡ��˰_���ۼ�
		,T2.ODI_TRD_HANDLE_FEE_YTD 				AS    ODI_TRD_HANDLE_FEE_YTD 		--��ͨ���׾��ַ�_���ۼ�	
		,T2.ODI_TRD_SEC_RGLT_FEE_YTD 			AS    ODI_TRD_SEC_RGLT_FEE_YTD 		--��ͨ����֤�ܷ� _���ۼ�
		,T2.ODI_TRD_ORDR_FEE_YTD 				AS    ODI_TRD_ORDR_FEE_YTD 			--��ͨ����ί�з�_���ۼ�
		,T2.ODI_TRD_OTH_FEE_YTD  				AS    ODI_TRD_OTH_FEE_YTD  			--��ͨ������������_���ۼ�
		,T2.CRED_TRD_TRAN_FEE_YTD				AS    CRED_TRD_TRAN_FEE_YTD			--���ý��׹�����_���ۼ�
		,T2.CRED_TRD_STP_TAX_YTD 				AS    CRED_TRD_STP_TAX_YTD 			--���ý���ӡ��˰_���ۼ�
		,T2.CRED_TRD_HANDLE_FEE_YTD 			AS    CRED_TRD_HANDLE_FEE_YTD 		--���ý��׾��ַ�_���ۼ�
		,T2.CRED_TRD_SEC_RGLT_FEE_YTD 			AS    CRED_TRD_SEC_RGLT_FEE_YTD 	--���ý���֤�ܷ�_���ۼ�
		,T2.CRED_TRD_ORDR_FEE_YTD 				AS    CRED_TRD_ORDR_FEE_YTD 		--���ý���ί�з�_���ۼ�
		,T2.CRED_TRD_OTH_FEE_YTD 				AS    CRED_TRD_OTH_FEE_YTD 			--���ý�����������_���ۼ�
		,T2.STKF_CMS_YTD         				AS    STKF_CMS_YTD         			--�ɻ�Ӷ��_���ۼ�
		,T2.STKF_TRAN_FEE_YTD    				AS    STKF_TRAN_FEE_YTD    			--�ɻ�������_���ۼ�
		,T2.STKF_NET_CMS_YTD     				AS    STKF_NET_CMS_YTD     			--�ɻ���Ӷ��_���ۼ�
		,T2.BOND_CMS_YTD         				AS    BOND_CMS_YTD         			--ծȯӶ��_���ۼ�
		,T2.BOND_NET_CMS_YTD     				AS    BOND_NET_CMS_YTD     			--ծȯ��Ӷ��_���ۼ�
		,T2.REPQ_CMS_YTD         				AS    REPQ_CMS_YTD         			--���ۻع�Ӷ��_���ۼ�
		,T2.REPQ_NET_CMS_YTD     				AS    REPQ_NET_CMS_YTD     			--���ۻع���Ӷ��_���ۼ�
		,T2.HGT_CMS_YTD   						AS    HGT_CMS_YTD   				--����ͨӶ��_���ۼ�
		,T2.HGT_NET_CMS_YTD      				AS    HGT_NET_CMS_YTD       		--����ͨ��Ӷ��_���ۼ�
		,T2.HGT_TRAN_FEE_YTD     				AS    HGT_TRAN_FEE_YTD     			--����ͨ������_���ۼ�
		,T2.SGT_CMS_YTD          				AS    SGT_CMS_YTD          			--���ͨӶ��_���ۼ�
		,T2.SGT_NET_CMS_YTD      				AS    SGT_NET_CMS_YTD      			--���ͨ��Ӷ��_���ۼ�
		,T2.SGT_TRAN_FEE_YTD     				AS    SGT_TRAN_FEE_YTD     			--���ͨ������_���ۼ�
		,T2.BGDL_CMS_YTD         				AS    BGDL_CMS_YTD         			--���ڽ���Ӷ��_���ۼ�
		,T2.BGDL_NET_CMS_YTD     				AS    BGDL_NET_CMS_YTD     			--���ڽ��׾�Ӷ��_���ۼ�
		,T2.BGDL_TRAN_FEE_YTD    				AS    BGDL_TRAN_FEE_YTD    			--���ڽ��׹�����_���ۼ�
		,T2.PSTK_OPTN_CMS_YTD    				AS    PSTK_OPTN_CMS_YTD    			--������ȨӶ��_���ۼ�
		,T2.PSTK_OPTN_NET_CMS_YTD				AS    PSTK_OPTN_NET_CMS_YTD			--������Ȩ��Ӷ��_���ۼ�
		,T2.CREDIT_ODI_CMS_YTD   				AS    CREDIT_ODI_CMS_YTD   			--������ȯ��ͨӶ��_���ۼ�
		,T2.CREDIT_ODI_NET_CMS_YTD 				AS    CREDIT_ODI_NET_CMS_YTD 		--������ȯ��ͨ��Ӷ��_���ۼ�	
		,T2.CREDIT_ODI_TRAN_FEE_YTD 			AS    CREDIT_ODI_TRAN_FEE_YTD 		--������ȯ��ͨ������_���ۼ�
		,T2.CREDIT_CRED_CMS_YTD  				AS    CREDIT_CRED_CMS_YTD  			--������ȯ����Ӷ��_���ۼ�
		,T2.CREDIT_CRED_NET_CMS_YTD 			AS    CREDIT_CRED_NET_CMS_YTD 		--������ȯ���þ�Ӷ��_���ۼ�
		,T2.CREDIT_CRED_TRAN_FEE_YTD 			AS    CREDIT_CRED_TRAN_FEE_YTD 		--������ȯ���ù�����_���ۼ�
		,T2.FIN_RECE_INT_YTD     				AS    FIN_RECE_INT_YTD     			--����Ӧ����Ϣ_���ۼ�
		,T2.FIN_PAIDINT_YTD      				AS    FIN_PAIDINT_YTD      			--����ʵ����Ϣ_���ۼ�
		,T2.STKPLG_CMS_YTD       				AS    STKPLG_CMS_YTD       			--��Ʊ��ѺӶ��_���ۼ�
		,T2.STKPLG_NET_CMS_YTD   				AS    STKPLG_NET_CMS_YTD   			--��Ʊ��Ѻ��Ӷ��_���ۼ�
		,T2.STKPLG_PAIDINT_YTD   				AS    STKPLG_PAIDINT_YTD   			--��Ʊ��Ѻʵ����Ϣ_���ۼ�
		,T2.STKPLG_RECE_INT_YTD  				AS    STKPLG_RECE_INT_YTD  			--��Ʊ��ѺӦ����Ϣ_���ۼ�
		,T2.APPTBUYB_CMS_YTD     				AS    APPTBUYB_CMS_YTD     			--Լ������Ӷ��_���ۼ�
		,T2.APPTBUYB_NET_CMS_YTD 				AS    APPTBUYB_NET_CMS_YTD 			--Լ�����ؾ�Ӷ��_���ۼ�
		,T2.APPTBUYB_PAIDINT_YTD 				AS    APPTBUYB_PAIDINT_YTD 			--Լ������ʵ����Ϣ_���ۼ�
		,T2.FIN_IE_YTD           				AS    FIN_IE_YTD           			--������Ϣ֧��_���ۼ�
		,T2.CRDT_STK_IE_YTD      				AS    CRDT_STK_IE_YTD      			--��ȯ��Ϣ֧��_���ۼ�
		,T2.OTH_IE_YTD           				AS    OTH_IE_YTD           			--������Ϣ֧��_���ۼ�
		,T2.FEE_RECE_INT_YTD     				AS    FEE_RECE_INT_YTD     			--����Ӧ����Ϣ_���ۼ�
		,T2.OTH_RECE_INT_YTD     				AS    OTH_RECE_INT_YTD     			--����Ӧ����Ϣ_���ۼ�
		,T2.CREDIT_CPTL_COST_YTD 				AS    CREDIT_CPTL_COST_YTD 			--������ȯ�ʽ�ɱ�_���ۼ�	
	FROM #TMP_T_EVT_INCM_D_EMP_MTH T1,#TMP_T_EVT_INCM_D_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_INCM_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_ITC_ORDR_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  ������: ���ڽ�����ʵ��_�ձ�
  ��д��: ����
  ��������: 2017-12-07
  ��飺���ڶ�������ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  
  commit;
  delete from DM.T_EVT_ITC_ORDR_TRD_D_D WHERE OCCUR_DT=@v_date;
  
  INSERT INTO DM.T_EVT_ITC_ORDR_TRD_D_D(
		CUST_ID
		,OCCUR_DT
		,BRH_ID
		,WH_ORDR_MODE_CD
		,ORDR_SITE
		,MKT_TYPE
		,SECU_TYPE
		,BUSE_DIR
		,ORDR_VOL
		,ORDR_AMT
		,ORDR_CNT
		,MTCH_VOL
		,MTCH_AMT
		,LOAD_DT
	)
	SELECT b.CLIENT_ID AS CUST_ID   -- �ͻ�����
		,@v_date AS OCCUR_DT         -- ҵ������
		,a.org_cd AS BRH_ID          -- Ӫҵ������
		,a.order_way_cd AS WH_ORDR_MODE_CD  -- �ֿ�ί�з�ʽ����
		,case when substring(a.order_station,1,2)='Y_' then '����'
			when substring(a.order_station,1,2)='HS' then 'ͬ��˳�ֻ�'
			when substring(a.order_station,1,2)='T_' then 'ͨ����'
			when substring(a.order_station,1,2)='H_' then 'ͬ��˳PC'
			when substring(a.order_station,1,2)='MP' then '�����ֻ�'
			when substring(a.order_station,1,2)='HW' then 'ͬ��˳WEB'
			when substring(a.order_station,1,2)='H5' then '΢��H5'
			else '����' end as ORDR_SITE  -- ί��վ��
		,a.market_type_cd AS MKT_TYPE   -- �г�����
		,case when coalesce(a.stock_type_cd,'')='' then '99' else a.stock_type_cd end AS SECU_TYPE   -- ֤ȯ����
		,a.deal_type_cd AS BUSE_DIR      -- ��������
		,sum(a.order_num) as ORDR_VOL   -- ί������
		,sum(a.order_num*a.order_price) as ORDR_AMT -- ί�н��
		,count(1) as ORDR_CNT       -- ί�б���
		,sum(a.trad_num) as MTCH_VOL    -- �ɽ�����
		,sum(a.trad_amt) as MTCH_AMT    -- �ɽ����
		,@v_date AS LOAD_DT        -- ��ϴ����
	FROM DBA.T_EDW_T05_ORDER_JOUR a
	LEFT JOIN DBA.T_ODS_UF2_FUNDACCOUNT b on a.fund_acct=b.FUND_ACCOUNT
	WHERE a.LOAD_DT=@v_date
	group by b.CLIENT_ID, a.org_cd, a.order_way_cd, ORDR_SITE, a.market_type_cd
		,SECU_TYPE, a.deal_type_cd;
  
  
   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_ITC_ORDR_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_ITC_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  ������: �ͻ�������ʵ��_�ձ�
  ��д��: ����
  ��������: 2017-12-08
  ��飺��¼�ͻ����ڽ��׻���ָ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  
	commit;
	
	delete from dm.T_EVT_ITC_TRD_D_D where load_dt=@v_date;
	INSERT INTO DM.T_EVT_ITC_TRD_D_D(
		CUST_ID
		,BRH_NO
		,MKT_TYPE
		,SECU_TYPE_MCGY_ID
		,BUSE_DIR
		,SECU_TYPE_SUB_ID
		,OCCUR_DT
		,TRD_QTY
		,TRD_AMT
		,TRD_CNT
		,LOAD_DT
	)
	SELECT a.CLIENT_ID as CUST_ID
		,b.pk_org as BRH_NO
		,c.MKT_TYPE as MKT_TYPE
		,c.SEC_TYPE as SECU_TYPE_MCGY_ID
		,MAX(d.BUSINESS_NAME) as BUSE_DIR
		,a.STOCK_TYPE as SECU_TYPE_SUB_ID
		,@v_date  as OCCUR_DT
		,sum(abs(a.BUSINESS_AMOUNT)) as TRD_QTY
		,sum(abs(a.BUSINESS_BALANCE)) as TRD_AMT
		,count(1) as TRD_CNT
		,@v_date as LOAD_DT
	FROM DBA.T_EDW_UF2_HIS_DELIVER a
	LEFT JOIN DBA.T_DIM_ORG b ON convert(varchar,a.BRANCH_NO)=b.branch_no
	LEFT JOIN DBA.T_ODS_UF2_SCLXDZ c on a.EXCHANGE_TYPE=c.EXCHANGE_TYPE and a.STOCK_TYPE=c.STOCK_TYPE
	LEFT JOIN DBA.T_ODS_UF2_BUSINFLAG d ON a.BUSINESS_FLAG=d.BUSINESS_FLAG
	WHERE a.LOAD_DT=@v_date
	and a.BUSINESS_FLAG in (4001,4002,4103,4104)
	GROUP BY a.CLIENT_ID, b.pk_org, c.MKT_TYPE, c.SEC_TYPE, a.STOCK_TYPE, a.BUSINESS_FLAG;
  
   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_ITC_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.p_evt_odi_incm_d_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  ������: �ͻ���ͨҵ�������ձ�
  ��д��: rengz
  ��������: 2018-4-20
  ��飺�ͻ���ͨҵ�����룬�ո���

  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��

  *********************************************************************/
 
    --declare @v_bin_date     numeric(8);  
    
	set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date =@v_bin_date;
	
  
	--������������
    

    --ɾ������������
    delete from dm.t_evt_odi_incm_d_d where occur_dt=@v_bin_date;
    commit;
      

------------------------
  -- ����ÿ�տͻ��嵥
------------------------  
    insert into dm.t_evt_odi_incm_d_d(CUST_ID,OCCUR_DT, MAIN_CPTL_ACCT,LOAD_DT)
    select distinct client_id, a.load_dt as occur_dt, fund_account,a.load_dt as rq
      from dba.t_edw_uf2_fundaccount a
     where load_dt = @v_bin_date
       and fundacct_status = '0'
       and main_flag='1'
       and asset_prop='0';
    commit;

------------------------
  -- Ӷ�𼰾�Ӷ��
------------------------  
    --drop table #t_yj;
    select a.zjzh,
          SUM(a.ssyj*b.turn_rmb   ) as yj_d,           -- Ӷ��                    
          SUM(a.jyj*b.turn_rmb    ) as jyj_d,          -- ��Ӷ��
          SUM(case when  a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as ejyj_d,  -- ����Ӷ��                     
          SUM(case when  a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb  else 0 end) as ejjyj_d, -- ������Ӷ��
          SUM(case when  a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1',  -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            ) or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then  a.ssyj*b.turn_rmb else 0 end) as gjyj_d, -- �ɻ�Ӷ��
          SUM(case when a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then   a.jyj*b.turn_rmb else 0 end) as gjjyj_d, -- �ɻ���Ӷ��
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ssyj*b.turn_rmb else 0 end) as yj_hgt_d,                 --����ͨӶ�� 
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.jyj*b.turn_rmb  else 0 end) as jyj_hgt_d,                --����ͨ��Ӷ�� 
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ssyj*b.turn_rmb else 0 end) as yj_sgt_d,                 --���ͨӶ��
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.jyj*b.turn_rmb  else 0 end) as jyj_sgt_d,                --���ͨ��Ӷ��
          SUM(case when a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.ssyj*b.turn_rmb else 0 end) as yj_bjhg_d,         --���ۻع�Ӷ�� 
          SUM(case when a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.jyj*b.turn_rmb  else 0 end) as jyj_bjhg_d,        --���ۻع���Ӷ�� 
          SUM(case when a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.ssyj*b.turn_rmb else 0 end) as yj_zq_d,  --ծȯӶ�� ���ο�ȫ��ͼ�ձ�������ծ��12�� ��ҵծ��13�� ��תծ ��14��
          SUM(case when a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.jyj*b.turn_rmb  else 0 end) as jyj_zq_d,  --ծȯ��Ӷ�� 
 
   ----��ط���
          SUM(a.yhs*b.turn_rmb ) as yhs_d ,                                          -- ӡ��˰
          SUM(a.ghf*b.turn_rmb ) as ghf_d ,                                          -- ������
          SUM(a.jsf*b.turn_rmb ) as jsf_d ,                                          -- ���ַ�
          SUM(a.zgf*b.turn_rmb ) as zgf_d ,                                          -- ֤�ܷ�
          SUM(a.qtfy*b.turn_rmb ) as qtfy_d ,                                        -- ��������
          SUM(case when a.busi_type_cd in( '3101','3102','3701','3703') then a.ghf*b.turn_rmb else 0 end) as ejghf_d ,                                          -- ����������
          SUM(case when a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then a.ghf*b.turn_rmb else 0 end) as gjghf_d ,                                           -- �ɻ�������
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ghf*b.turn_rmb else 0 end) as hgtghf_d ,                                      -- ����ͨ������
          SUM(case when a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ghf*b.turn_rmb else 0 end) as sgtghf_d                                        -- ���ͨ������
      into #t_yj
       from dba.t_ddw_f00_khzqhz_d as a
       left outer join dba.t_edw_t06_year_exchange_rate as b
         on a.load_dt between b.star_dt and b.end_dt
        and b.curr_type_cd = case  when a.zqlx = '18' and a.sclx = '05' then 'USD'
                                   when a.zqlx = '17' then  'USD'
                                   when a.zqlx = '18' then 'HKD'
                                        else  'CNY'
                             end
      where a.load_dt = @v_bin_date
        and a.sclx in ('01', '02', '03', '04', '05', '0G', '0S')  
      group by a.zjzh;

    commit;

     update dm.t_evt_odi_incm_d_d a
       set GROSS_CMS            = coalesce(yj_d, 0),       --ëӶ��
           NET_CMS              = coalesce(jyj_d, 0),       --��Ӷ��
           STKF_CMS             = coalesce(gjyj_d, 0),      --�ɻ�Ӷ��
           STKF_NET_CMS         = coalesce(gjjyj_d, 0),     --�ɻ���Ӷ��
           BOND_CMS             = coalesce(yj_zq_d, 0),     --ծȯӶ��
           BOND_NET_CMS         = coalesce(jyj_zq_d, 0),    --ծȯ��Ӷ��
           REPQ_CMS             = coalesce(yj_bjhg_d, 0),   --���ۻع�Ӷ��
           REPQ_NET_CMS         = coalesce(jyj_bjhg_d, 0),  --���ۻع���Ӷ��
           HGT_CMS              = coalesce(yj_hgt_d, 0),    --����ͨӶ��
           HGT_NET_CMS          = coalesce(jyj_hgt_d, 0),   --����ͨ��Ӷ��
           SGT_CMS              = coalesce(yj_sgt_d, 0),    --���ͨӶ��
           SGT_NET_CMS          = coalesce(jyj_sgt_d, 0),   --���ͨ��Ӷ��
           SCDY_CMS             = coalesce(ejyj_d, 0),      --����Ӷ��
           SCDY_NET_CMS         = coalesce(ejjyj_d, 0),     --������Ӷ�� 

           STP_TAX              = coalesce(yhs_d, 0),       -- ӡ��˰ 
           HANDLE_FEE           = coalesce(jsf_d, 0),       -- ���ַ� 
           SEC_RGLT_FEE         = coalesce(zgf_d, 0),       --֤�ܷ� 
           OTH_FEE              = coalesce(qtfy_d, 0),      --��������          
           TRAN_FEE             = coalesce(ghf_d, 0),       --������ 
           SCDY_TRAN_FEE        = coalesce(ejghf_d, 0),     --���������� 
           STKF_TRAN_FEE        = coalesce(gjghf_d, 0),     --�ɻ������� 
           SGT_TRAN_FEE         = coalesce(sgtghf_d, 0),    --���ͨ������
           HGT_TRAN_FEE         = coalesce(hgtghf_d, 0)     --����ͨ������
      from dm.t_evt_odi_incm_d_d a
      left join            #t_yj b on a.main_cptl_acct=b.zjzh
     where a.occur_dt=@v_bin_date ;
     commit;


  -- ��ȨӶ�𼰾�Ӷ�� 

    select client_id,
           sum(fare0   ) as yj_qq_d,
           sum(fare0 - exchange_fare0 - exchange_fare3   ) as jyj_qq_d
      into #t_yj_qq
     from dba.T_EDW_UF2_HIS_OPTDELIVER
     where load_dt = @v_bin_date
     group by client_id;

   update dm.t_evt_odi_incm_d_d  
   set PSTK_OPTN_CMS = coalesce(yj_qq_d, 0),        --������ȨӶ�� 
       PSTK_OPTN_NET_CMS = coalesce(jyj_qq_d, 0)    --������Ȩ��Ӷ�� 
   from dm.t_evt_odi_incm_d_d a
   left join        #t_yj_qq  b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
   commit;


  -- ���ڽ���Ӷ�𼰾�Ӷ��
    ---drop table #t_yj_dzjy;
    select a1.fund_acct as zjzh,
        SUM(CASE WHEN  ordeR_way_cd ='53'  THEN ROUND(a1.FACT_COMM * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                       AS yj_dzjy_d,
        SUM(CASE WHEN  ordeR_way_cd ='53'  THEN ROUND((a1.FACT_COMM - a1.stock_mana_fee) * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END) AS jyj_dzjy_d,
        SUM(CASE WHEN  ordeR_way_cd ='53'  THEN ROUND(a1.trans_fee* a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                        AS ghf_dzjy_d
    into #t_yj_dzjy
    FROM    dba.T_EDW_T05_TRADE_JOUR           a1
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE a2
    ON      a1.occur_dt BETWEEN a2.star_dt AND a2.end_dt
    AND     a2.curr_type_cd = CASE
                                   WHEN a1.stock_type_cd='18' AND a1.market_type_cd = '05' THEN 'USD'
                                   WHEN a1.stock_type_cd='17' THEN 'USD'
                                   WHEN a1.stock_type_cd='18' THEN 'HKD'
                                   ELSE 'CNY'
                              END
    WHERE  a1.busi_type_cd IN ('3101','3102','3701','3703') 
       and a1.load_dt=@v_bin_date
    group by zjzh;
  
   update dm.t_evt_odi_incm_d_d  
   set  BGDL_CMS = coalesce(yj_dzjy_d, 0),         --���ڽ���Ӷ�� 
        BGDL_NET_CMS = coalesce(jyj_dzjy_d, 0),    --���ڽ��׾�Ӷ�� 
        BGDL_TRAN_FEE = coalesce(ghf_dzjy_d, 0)    --���ڽ��׹����� 
   from dm.t_evt_odi_incm_d_d a
   left join      #t_yj_dzjy  b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_date ;
  commit;
 

------------------------
  -- PB����Ӷ��
------------------------  
  select client_id,
         sum(fare0)                                                as pbyj_d,        --PBӶ��
         sum( coalesce(fare0,0)
									+ coalesce(fare3,0)
									+ coalesce(farex,0)
									+ coalesce(fare2,0)
									- coalesce(exchange_fare0,0)
									- coalesce(exchange_fare3,0)
									- coalesce(exchange_fare4,0)
									- coalesce(exchange_fare5,0)
									- coalesce(exchange_fare6,0)
									- coalesce(exchange_farex,0)
									- coalesce(exchange_fare2,0)) as pbjyj_d,     --PB��Ӷ��
         sum(fare2)                                               as pbghf_d      --PB������   
    into #t_pbyj
    from dba.t_edw_uf2_his_deliver a
   where a.business_flag in (4001, 4002, 4103, 4104)
     and fund_account in
         (select distinct fund_account
            from dba.t_edw_uf2_fundaccount
           where client_group in (30, 38)
             and load_dt = @v_bin_date)
     and load_dt =@v_bin_date
   group by client_id;


   update dm.t_evt_odi_incm_d_d  
   set  PB_TRD_CMS  = coalesce(pbyj_d, 0) ,          --PB����Ӷ�� 
        PB_NET_CMS  = coalesce(pbjyj_d, 0) ,         --PB_��Ӷ��
        PB_TRAN_FEE  = coalesce(pbghf_d, 0)          --PB_������
   from dm.t_evt_odi_incm_d_d a
   left join      #t_pbyj     b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
  commit; 

 
  set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 


end
GO
GRANT EXECUTE ON dm.p_evt_odi_incm_d_d TO query_dev
GO
CREATE PROCEDURE dm.p_evt_odi_incm_m_d(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  ������: �ͻ���ͨҵ�������±��ո��£�
  ��д��: rengz
  ��������: 2017-11-28
  ��飺�ͻ���ͨҵ�����룬�ո���
        ��Ҫ���������ڣ�T_DDW_F00_KHMRZJZHHZ_D �ձ� ��ͨ�˻��ʽ� ����ֵ��������
                        tmp_ddw_khqjt_m_m     ������ȯ�ͻ��ʽ����� ����

  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
             20180328                 rengz              ���ӡ�PB����Ӷ�𡢱�֤���������롢��֤������_������
  *********************************************************************/
 
    -- declare @v_bin_date             numeric(8); 
    declare @v_bin_year             varchar(4); 
    declare @v_bin_mth              varchar(2); 
    declare @v_bin_qtr              varchar(2); --����
    declare @v_bin_year_start_date  numeric(8); --�����һ��������
    declare @v_bin_mth_start_date   numeric(8); --���µ�һ��������
    declare @v_bin_mth_end_date     numeric(8); --���½���������
    declare @v_bin_qtr_end_date     numeric(8); --�����Ƚ���������
    declare @v_bin_qtr_m1_start_date  numeric(8); --�����ȵ�1���µ�һ��������
    declare @v_bin_qtr_m1_end_date    numeric(8); --�����ȵ�1�������һ��������
    declare @v_bin_qtr_m2_start_date  numeric(8); --�����ȵ�2���µ�һ��������
    declare @v_bin_qtr_m2_end_date    numeric(8); --�����ȵ�2�������һ��������
    declare @v_bin_qtr_m3_start_date  numeric(8); --�����ȵ�3���µ�һ��������
    declare @v_bin_qtr_m3_end_date    numeric(8); --�����ȵ�3�������һ��������
    declare @v_date_num               numeric(8); --������Ȼ�յ�����
    declare @v_date_qtr_m1_num        numeric(8); --������Ȼ�յ�����
    declare @v_date_qtr_m2_num        numeric(8); --������Ȼ�յ�����
    declare @v_date_qtr_m3_num        numeric(8); --������Ȼ�յ�����
    declare @v_lcbl                   numeric(38,8); ---��֤���������
    
	set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date =@v_bin_date;
	
  
	--������������
    set @v_bin_year=(select year from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_mth =(select mth  from dm.t_pub_date where dt=@v_bin_date ); 
    set @v_bin_qtr =(select qtr  from dm.t_pub_date where dt=@v_bin_date );
    set @v_bin_year_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and if_trd_day_flag=1 ); 
    set @v_bin_mth_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_mth_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and if_trd_day_flag=1 ); 
    set @v_bin_qtr_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year  and qtr=@v_bin_qtr and if_trd_day_flag=1 ); 
    set @v_bin_qtr_m1_start_date=(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1);
    set @v_bin_qtr_m1_end_date  =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and mth=(select convert(varchar,min(mth)) from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m2_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+1 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_start_date  =(select min(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_bin_qtr_m3_end_date   =(select max(dt) from dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr and if_trd_day_flag=1
                                  and convert(numeric(2),mth)=(select min(convert(numeric(2),mth))+2 from  dm.t_pub_date where year=@v_bin_year and qtr=@v_bin_qtr)) ;
    set @v_date_num              =case  when @v_bin_date=@v_bin_mth_end_date then (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth )
                                        else (select count(dt) from dm.t_pub_date where year=@v_bin_year  and mth=@v_bin_mth and dt<=@v_bin_date) end;        --�������һ�������գ�������Ȼ��ͳ������
    set @v_date_qtr_m1_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m1_start_date and @v_bin_qtr_m1_end_date );             --�����ȵ�1������Ȼ�յ�����
    set @v_date_qtr_m2_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m2_start_date and @v_bin_qtr_m2_end_date );             --�����ȵ�2������Ȼ�յ�����
    set @v_date_qtr_m3_num          =(select count(dt) from dm.t_pub_date where dt between @v_bin_qtr_m3_start_date and @v_bin_qtr_m3_end_date );             --�����ȵ�3������Ȼ�յ�����
    set @v_lcbl              =case when coalesce((select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth),0)=0 then 
                                        (select bjzlclv from dba.t_jxfc_market where nian||yue=substr(convert(varchar,dateadd(month,-1,convert(varchar,@v_bin_date)),112),1,6)  )
                              else (select bjzlclv from dba.t_jxfc_market where nian=@v_bin_year and yue=@v_bin_mth) end ;

 

    --ɾ������������
    delete from dm.t_evt_odi_incm_m_d where year =@v_bin_year and mth=@v_bin_mth;
    commit;
      

------------------------
  -- ����ÿ�տͻ��嵥
------------------------  
    insert into dm.t_evt_odi_incm_m_d(CUST_ID,OCCUR_DT,YEAR,MTH,MAIN_CPTL_ACCT,LOAD_DT)
    select distinct client_id, a.load_dt as occur_dt,@v_bin_year,@v_bin_mth, fund_account,a.load_dt as rq
      from dba.t_edw_uf2_fundaccount a
     where load_dt = @v_bin_date
       and fundacct_status = '0'
       and main_flag='1'
       and asset_prop='0';
    commit;

------------------------
  -- Ӷ�𼰾�Ӷ��
------------------------  
    --drop table #t_yj;
    select a.zjzh,
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then  a.ssyj*b.turn_rmb  end ) as yj_m,           -- Ӷ��_���ۼ�                    
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then  a.jyj*b.turn_rmb   end ) as jyj_m,          -- ��Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as ejyj_m,  -- ����Ӷ��_���ۼ�                     
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb  else 0 end) as ejjyj_m, -- ������Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1',  -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            ) or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then  a.ssyj*b.turn_rmb else 0 end) as gjyj_m, -- �ɻ�Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then   a.jyj*b.turn_rmb else 0 end) as gjjyj_m, -- �ɻ���Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ssyj*b.turn_rmb else 0 end) as yj_hgt_m,                 --����ͨӶ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.jyj*b.turn_rmb  else 0 end) as jyj_hgt_m,                --����ͨ��Ӷ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ssyj*b.turn_rmb else 0 end) as yj_sgt_m,                 --���ͨӶ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.jyj*b.turn_rmb  else 0 end) as jyj_sgt_m,                --���ͨ��Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.ssyj*b.turn_rmb else 0 end) as yj_bjhg_m,         --���ۻع�Ӷ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.jyj*b.turn_rmb  else 0 end) as jyj_bjhg_m,        --���ۻع���Ӷ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.ssyj*b.turn_rmb else 0 end) as yj_zq_m,  --ծȯӶ��_���ۼ� ���ο�ȫ��ͼ�ձ�������ծ��12�� ��ҵծ��13�� ��תծ ��14��
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.jyj*b.turn_rmb  else 0 end) as jyj_zq_m,  --ծȯ��Ӷ��_���ۼ� 


          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date then  a.ssyj*b.turn_rmb  end ) as yj_y,           -- Ӷ��_���ۼ�                    
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date then  a.jyj*b.turn_rmb   end ) as jyj_y,          -- ��Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.ssyj*b.turn_rmb else 0 end) as ejyj_y,  -- ����Ӷ��_���ۼ�                     
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.jyj*b.turn_rmb  else 0 end) as ejjyj_y, -- ������Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1',  -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            ) or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then  a.ssyj*b.turn_rmb else 0 end) as gjyj_y, -- �ɻ�Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then   a.jyj*b.turn_rmb else 0 end) as gjjyj_y, -- �ɻ���Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ssyj*b.turn_rmb else 0 end) as yj_hgt_y,                 --����ͨӶ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.jyj*b.turn_rmb  else 0 end) as jyj_hgt_y,                --����ͨ��Ӷ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ssyj*b.turn_rmb else 0 end) as yj_sgt_y,                 --���ͨӶ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.jyj*b.turn_rmb  else 0 end) as jyj_sgt_y,                --���ͨ��Ӷ��_���ۼ�
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.ssyj*b.turn_rmb else 0 end) as yj_bjhg_y,         --���ۻع�Ӷ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3703', '3704')  and a.zqdm like '205%' then a.jyj*b.turn_rmb  else 0 end) as jyj_bjhg_y,        --���ۻع���Ӷ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.ssyj*b.turn_rmb else 0 end) as yj_zq_y,  --ծȯӶ��_���ۼ� ���ο�ȫ��ͼ�ձ�������ծ��12�� ��ҵծ��13�� ��תծ ��14��
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd IN ('3101','3102')   and a.zqlx in( '12','13','14')  then a.jyj*b.turn_rmb  else 0 end) as jyj_zq_y, --ծȯ��Ӷ��_���ۼ� 
          SUM(case when a.load_dt between @v_bin_year_start_date and @v_bin_date and a.busi_type_cd in( '3703') then a.jyj*b.turn_rmb else 0 end) as nhgjyj_y ,                                          -- ��ع���Ӷ��_���ۼ�

   ----��ط���
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.yhs*b.turn_rmb else 0 end) as yhs_m ,                                          -- ӡ��˰_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.ghf*b.turn_rmb else 0 end) as ghf_m ,                                          -- ������_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.jsf*b.turn_rmb else 0 end) as jsf_m ,                                          -- ���ַ�_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.zgf*b.turn_rmb else 0 end) as zgf_m ,                                          -- ֤�ܷ�_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date then a.qtfy*b.turn_rmb else 0 end) as qtfy_m ,                                        -- ��������_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102','3701','3703') then a.ghf*b.turn_rmb else 0 end) as ejghf_m ,                                          -- ����������_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and
                                            (a.zqlx in    ('10', 'A1', -- A��
                                                            '17', '18', -- B��
                                                            '11',       -- ���ʽ����
                                                            '1A',       -- ETF
                                                            '74', '75' -- Ȩ֤
                                                            )  or  
                                                            (a.sclx = '02' and a.zqlx = '19') -- LOF
                                                            ) then a.ghf*b.turn_rmb else 0 end) as gjghf_m ,                                           -- �ɻ�������_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0G' then a.ghf*b.turn_rmb else 0 end) as hgtghf_m ,                                      -- ����ͨ������_���ۼ�
          SUM(case when a.load_dt between @v_bin_mth_start_date and @v_bin_date and a.busi_type_cd in( '3101','3102') and a.sclx = '0S' then a.ghf*b.turn_rmb else 0 end) as sgtghf_m                                        -- ���ͨ������_���ۼ�
      into #t_yj
       from dba.t_ddw_f00_khzqhz_d as a
       left outer join dba.t_edw_t06_year_exchange_rate as b
         on a.load_dt between b.star_dt and b.end_dt
        and b.curr_type_cd = case  when a.zqlx = '18' and a.sclx = '05' then 'USD'
                                   when a.zqlx = '17' then  'USD'
                                   when a.zqlx = '18' then 'HKD'
                                        else  'CNY'
                             end
      where a.load_dt between @v_bin_year_start_date and @v_bin_date
        and a.sclx in ('01', '02', '03', '04', '05', '0G', '0S')  
      group by a.zjzh;

    commit;

     update dm.t_evt_odi_incm_m_d a
       set GROSS_CMS            = coalesce(yj_m, 0),       --ëӶ��
           NET_CMS              = coalesce(jyj_m, 0),       --��Ӷ��
           STKF_CMS             = coalesce(gjyj_m, 0),      --�ɻ�Ӷ��
           STKF_NET_CMS         = coalesce(gjjyj_m, 0),     --�ɻ���Ӷ��
           BOND_CMS             = coalesce(yj_zq_m, 0),     --ծȯӶ��
           BOND_NET_CMS         = coalesce(jyj_zq_m, 0),    --ծȯ��Ӷ��
           REPQ_CMS             = coalesce(yj_bjhg_m, 0),   --���ۻع�Ӷ��
           REPQ_NET_CMS         = coalesce(jyj_bjhg_m, 0),  --���ۻع���Ӷ��
           HGT_CMS              = coalesce(yj_hgt_m, 0),    --����ͨӶ��
           HGT_NET_CMS          = coalesce(jyj_hgt_m, 0),   --����ͨ��Ӷ��
           SGT_CMS              = coalesce(yj_sgt_m, 0),    --���ͨӶ��
           SGT_NET_CMS          = coalesce(jyj_sgt_m, 0),   --���ͨ��Ӷ��
           SCDY_CMS             = coalesce(ejyj_m, 0),      --����Ӷ��
           SCDY_NET_CMS         = coalesce(ejjyj_m, 0),     --������Ӷ��
           TY_SCDY_CMS          = coalesce(ejyj_y, 0),      --�������Ӷ��
           TY_SCDY_NET_CMS      = coalesce(ejjyj_y, 0),     --���������Ӷ��
           TY_ODI_NET_CMS       = coalesce(jyj_y, 0),       --������ͨ��Ӷ��
           TY_STKF_CMS          = coalesce(gjyj_y, 0),      --����ɻ�Ӷ��
           TY_STKF_NET_CMS      = coalesce(gjjyj_y, 0),     --����ɻ���Ӷ��
           TY_ODI_CMS           = coalesce(yj_y, 0),        --������ͨӶ��
           TY_SGT_NET_CMS       = coalesce(jyj_sgt_y, 0),   --�������ͨ��Ӷ��
           TY_HGT_NET_CMS       = coalesce(jyj_hgt_y, 0),   --���껦��ͨ��Ӷ��
           TY_R_REPUR_NET_CMS   = coalesce(nhgjyj_y, 0),    --������ع���Ӷ��

           STP_TAX              = coalesce(yhs_m, 0),       -- ӡ��˰ 
           HANDLE_FEE           = coalesce(jsf_m, 0),       -- ���ַ� 
           SEC_RGLT_FEE         = coalesce(zgf_m, 0),       --֤�ܷ� 
           OTH_FEE              = coalesce(qtfy_m, 0),      --��������          
           TRAN_FEE             = coalesce(ghf_m, 0),       --������ 
           SCDY_TRAN_FEE        = coalesce(ejghf_m, 0),     --���������� 
           STKF_TRAN_FEE        = coalesce(gjghf_m, 0),     --�ɻ������� 
           SGT_TRAN_FEE         = coalesce(sgtghf_m, 0),    --���ͨ������
           HGT_TRAN_FEE         = coalesce(hgtghf_m, 0)     --����ͨ������
      from dm.t_evt_odi_incm_m_d a
      left join            #t_yj b on a.main_cptl_acct=b.zjzh
     where a.occur_dt=@v_bin_date ;
     commit;


  -- ��ȨӶ�𼰾�Ӷ�� 

    select client_id,
           sum(case when load_dt between @v_bin_mth_start_date and @v_bin_date then fare0 end ) as yj_qq_m,
           sum(case when load_dt between @v_bin_mth_start_date and @v_bin_date then fare0 - exchange_fare0 - exchange_fare3 end ) as jyj_qq_m,
           sum(case when load_dt between @v_bin_year_start_date and @v_bin_date then fare0 end ) as yj_qq_y,
           sum(case when load_dt between @v_bin_year_start_date and @v_bin_date then fare0 - exchange_fare0 - exchange_fare3 end ) as jyj_qq_y
      into #t_yj_qq
     from dba.T_EDW_UF2_HIS_OPTDELIVER
     where load_dt between @v_bin_year_start_date and @v_bin_date
     group by client_id;

   update dm.t_evt_odi_incm_m_d  
   set PSTK_OPTN_CMS = coalesce(yj_qq_m, 0),        --������ȨӶ��_���ۼ�
       PSTK_OPTN_NET_CMS = coalesce(jyj_qq_m, 0),   --������Ȩ��Ӷ��_���ۼ�
       TY_PSTK_OPTN_CMS = coalesce(yj_qq_y, 0)      --������ȨӶ��_���ۼ�
   from dm.t_evt_odi_incm_m_d a
   left join        #t_yj_qq  b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
   commit;


  -- ���ڽ���Ӷ�𼰾�Ӷ��
    ---drop table #t_yj_dzjy;
    select a1.fund_acct as zjzh,
        SUM(CASE WHEN load_dt between @v_bin_mth_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND(a1.FACT_COMM * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                       AS yj_dzjy_m,
        SUM(CASE WHEN load_dt between @v_bin_mth_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND((a1.FACT_COMM - a1.stock_mana_fee) * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END) AS jyj_dzjy_m,
        SUM(CASE WHEN load_dt between @v_bin_mth_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND(a1.trans_fee* a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                        AS ghf_dzjy_m,
        SUM(CASE WHEN load_dt between @v_bin_year_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND(a1.FACT_COMM * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)                        AS yj_dzjy_y,
        SUM(CASE WHEN load_dt between @v_bin_year_start_date and @v_bin_date  and ordeR_way_cd ='53'  THEN ROUND((a1.FACT_COMM - a1.stock_mana_fee) * a2.turn_rmb / a2.turn_rate,2) ELSE 0 END)  AS jyj_dzjy_y
    into #t_yj_dzjy
    FROM    dba.T_EDW_T05_TRADE_JOUR           a1
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE a2
    ON      a1.occur_dt BETWEEN a2.star_dt AND a2.end_dt
    AND     a2.curr_type_cd = CASE
                                   WHEN a1.stock_type_cd='18' AND a1.market_type_cd = '05' THEN 'USD'
                                   WHEN a1.stock_type_cd='17' THEN 'USD'
                                   WHEN a1.stock_type_cd='18' THEN 'HKD'
                                   ELSE 'CNY'
                              END
    WHERE  a1.busi_type_cd IN ('3101','3102','3701','3703') 
       and a1.load_dt between @v_bin_year_start_date and @v_bin_date
    group by zjzh;
  
   update dm.t_evt_odi_incm_m_d  
   set  BGDL_CMS = coalesce(yj_dzjy_m, 0),         --���ڽ���Ӷ��_���ۼ�
        BGDL_NET_CMS = coalesce(jyj_dzjy_m, 0),    --���ڽ��׾�Ӷ��_���ۼ�
        BGDL_TRAN_FEE = coalesce(ghf_dzjy_m, 0)    --���ڽ��׹�����_���ۼ�
   from dm.t_evt_odi_incm_m_d a
   left join      #t_yj_dzjy  b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_date ;
  commit;
 

------------------------
  -- PB����Ӷ��
------------------------  
  select client_id, sum(fare0) as pbyj_m
    into #t_pbyj
    from dba.t_edw_uf2_his_deliver a
   where a.business_flag in (4001, 4002, 4103, 4104)
     and fund_account in
         (select distinct fund_account
            from dba.t_edw_uf2_fundaccount
           where client_group in (30, 38)
             and load_dt between @v_bin_mth_start_date AND @v_bin_date)
     and load_dt between @v_bin_mth_start_date AND @v_bin_date
   group by client_id;


   update dm.t_evt_odi_incm_m_d  
   set  PB_TRD_CMS  = coalesce(pbyj_m, 0)         --PB����Ӷ�� 
   from dm.t_evt_odi_incm_m_d a
   left join      #t_pbyj     b on a.cust_id=b.client_id
   where a.occur_dt=@v_bin_date ;
  commit; 

------------------------
  -- ��֤����������
------------------------  

--��֤��
  select zjzh,
         sum(a.zjye * b.turn_rmb / turn_rate) as zjyeh,
         (zjyeh/@v_date_num)* @v_lcbl         as lcsr
  into #t_lcsr
  from dba.T_DDW_F00_KHMRZJZHHZ_D a
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE b ON a.tjrq BETWEEN b.star_dt AND b.end_dt AND b.curr_type_cd = a.bzlb   
    LEFT JOIN (select rq, nian, yue,
                      case when sfjrbz = '1' then rq else syggzr
                      end as jyr
              from dba.T_DDW_D_RQ
              where rq  between @v_bin_mth_start_date AND  @v_bin_date ) c  on c.jyr = a.tjrq
  where a.tjrq between @v_bin_mth_start_date AND  @v_bin_date
  group by zjzh;

 commit;

   update dm.t_evt_odi_incm_m_d  
   set  MARG_SPR_INCM = coalesce(lcsr, 0)         --��֤���������� 
   from dm.t_evt_odi_incm_m_d a
   left join      #t_lcsr  b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_date ;
  commit; 


------------------------
  -- ����������2�����µı�֤����������
------------------------  

 
  if @v_bin_date= @v_bin_qtr_end_date
  then 
 
  ---�����ȵ�1��
   select zjzh,
         sum(a.zjye * b.turn_rmb / turn_rate) as zjyeh,
         (zjyeh/@v_date_qtr_m1_num)* @v_lcbl         as lcsr
  into #t_lcsr_qrt_1
  from dba.T_DDW_F00_KHMRZJZHHZ_D a
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE b ON a.tjrq BETWEEN b.star_dt AND b.end_dt AND b.curr_type_cd = a.bzlb   
    LEFT JOIN (select rq, nian, yue,
                      case when sfjrbz = '1' then rq else syggzr
                      end as jyr
              from dba.T_DDW_D_RQ
              where rq  between @v_bin_qtr_m1_start_date AND  @v_bin_qtr_m1_end_date ) c  on c.jyr = a.tjrq
  where a.tjrq between @v_bin_qtr_m1_start_date AND  @v_bin_qtr_m1_end_date
  group by zjzh ;

   update dm.t_evt_odi_incm_m_d  
   set  MARG_SPR_INCM_CET = coalesce(lcsr, 0)         --��֤���������� 
   from dm.t_evt_odi_incm_m_d a
   left join  #t_lcsr_qrt_1   b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_qtr_m1_end_date ;
  commit; 


  ---�����ȵ�2��
   select zjzh,
         sum(a.zjye * b.turn_rmb / turn_rate) as zjyeh,
         (zjyeh/@v_date_qtr_m2_num)* @v_lcbl         as lcsr
  into #t_lcsr_qrt_2
  from dba.T_DDW_F00_KHMRZJZHHZ_D a
    LEFT JOIN dba.T_EDW_T06_YEAR_EXCHANGE_RATE b ON a.tjrq BETWEEN b.star_dt AND b.end_dt AND b.curr_type_cd = a.bzlb   
    LEFT JOIN (select rq, nian, yue,
                      case when sfjrbz = '1' then rq else syggzr
                      end as jyr
              from dba.T_DDW_D_RQ
              where rq  between @v_bin_qtr_m2_start_date AND  @v_bin_qtr_m2_end_date ) c  on c.jyr = a.tjrq
  where a.tjrq between @v_bin_qtr_m2_start_date AND  @v_bin_qtr_m2_end_date
  group by zjzh ;
  commit;
  

   update dm.t_evt_odi_incm_m_d  
   set  MARG_SPR_INCM_CET = coalesce(lcsr, 0)         --��֤���������� 
   from dm.t_evt_odi_incm_m_d a
   left join  #t_lcsr_qrt_2   b on a.main_cptl_acct=b.zjzh
   where a.occur_dt=@v_bin_qtr_m2_end_date ;
  commit; 
 
  end if;

 
   set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 


end
GO
GRANT EXECUTE ON dm.p_evt_odi_incm_m_d TO query_dev
GO
GRANT EXECUTE ON dm.p_evt_odi_incm_m_d TO xydc
GO
CREATE PROCEDURE dm.P_EVT_OUTMARK_PROD_EXT_M(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ������ֵ��չ���±�
  ��д��: DCY
  ��������: 2018-01-15
  ��飺
  *********************************************************************
  �޶���¼��   �޶�����    �޶���     �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
    DECLARE @nian VARCHAR(4);		--����_���
	DECLARE @yue VARCHAR(2)	;		--����_�·�
	DECLARE @zrr_nc int;            --��Ȼ��_�³�
	DECLARE @zrr_yc int;            --��Ȼ��_��� 
	DECLARE @td_ym int;				--��ĩ
	DECLARE @ny int;
	
    SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1

    SET @nian=SUBSTR(@V_BIN_DATE||'',1,4);
	SET @yue=SUBSTR(@V_BIN_DATE||'',5,2);
   	set @zrr_nc=(select min(t1.����) from DBA.v_skb_d_rq t1 where t1.����>=convert(int,@nian||'0101'));
	set @zrr_yc=(select min(t1.����) from DBA.v_skb_d_rq t1 where t1.����>=convert(int,@nian||@yue||'01'));
	set @td_ym=(select max(t1.����) from DBA.v_skb_d_rq t1 where t1.�Ƿ�����='1' and t1.����<=convert(int,@nian||@yue||'31'));
    set @ny=convert(int,@nian||@yue);
	
	
	
  --PART0 ɾ��Ҫ��ϴ������
    DELETE FROM DM.T_EVT_OUTMARK_PROD_EXT_M WHERE YEAR=@nian AND MTH=@yue;
	
 --PART1 Ա��������_��ʱ��	
   select
		t1.ygh --afaһ��Ա����
		,T1.afatwo_ygh --afa����Ա���ţ����Ա���Ų����ڣ����Կͻ�����Ӫҵ�������Ϊ����Ա���ţ���Ӫҵ�������ͻ���

		INTO #temp_ygh_tc
	from
	(
		select
			t1.ygh
			,case when t2.ygs=1 then t1.afatwo_ygh
				when t2.ygs>1 and t3.afatwo_ygh is not null then t3.afatwo_ygh
				else t4.afatwo_ygh end as afatwo_ygh
		from
		(
			select
				t1.ygh
				,t1.afatwo_ygh
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
		) t1	
		left join
		(--ͬһ�����˱�Ŷ�Ӧ����Ա������
			select
				t1.ygh
				,count(t1.afatwo_ygh) as ygs
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
			group by
				t1.ygh
		) t2 on t1.ygh=t2.ygh	
		left join
		(--ͬһ�����˱�Ŷ�Ӧ����Ա����
			select
				t1.ygh
				,max(t1.afatwo_ygh) as afatwo_ygh
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
				and t1.ygzt='������Ա'
			group by
				t1.ygh
		) t3 on t1.ygh=t3.ygh
		left join
		(--ͬһ�����˱�Ŷ�Ӧ�쳣Ա����
			select
				t1.ygh
				,max(t1.afatwo_ygh) as afatwo_ygh
			from dba.v_edw_person_m t1
			where t1.nian=@nian and t1.yue=@yue --and t1.jxlx=@jxlx
				and t1.ygzt<>'������Ա'
			group by
				t1.ygh
		) t4 on t1.ygh=t4.ygh
		group by
			t1.ygh
			,afatwo_ygh
	) t1
	where t1.afatwo_ygh is not null
	;
	COMMIT;
 
  --PART2 ����ͻ�����_��ʱ��:�����˻�
  select
		t1.uid		--Ψһʶ��Ź��򣺣�˽ļ���������_�ͻ�����������ʹ���ʽ��ʺ�
		,t1.sfdx	--�Ƿ���ͻ�	
		,case when t2.zjzh is null then convert(int,t1.gmrq) else t2.khrq end as khrq  --��������
		,case when khrq>=@zrr_nc then 1 else 0 end as sfxz_y  --�Ƿ�������
		,case when khrq>=@zrr_yc then 1 else 0 end as sfxz_m  --�Ƿ�������
		,t1.gmrq    --�״ι�������
		,t2.khzt    --�ͻ�״̬
		
		INTO #temp_twkhdz   --�����˻�
	from
	(
		select
			case when t1.cplx='����' or t1.cplx='����-�̶�����' then t1.zjzh
				else t1.jgbh||trim(t1.khmc)
				end as uid			
			,case when t1.cplx='����' or t1.cplx='����-�̶�����' then 1 else 0 end as sfdx
			,min(t1.nian||t1.yue||'01') as gmrq
		from dba.gt_ods_simu_trade_jour t1
		group by uid,sfdx
	) t1
	left join dba.t_ddw_yunying2012_kh t2 on t1.uid=t2.zjzh and t2.nian=@nian and t2.yue=@yue	
  ;
  COMMIT;
  
   --PART3 �����Ʒ��չ�ͻ���ϸ_��ʱ��
 select
		@nian as nian
		,@yue as yue		
		,t1.uid		
		,t4.khrq
		,t4.sfxz_y
		,t4.sfxz_m
		,case when t1.cplx='����' then '����-Ȩ����' else trim(t1.cplx) end as cplx
		,t1.cpmc
		,case when t1.zjzh is null or trim(t1.zjzh)='' then '���ʽ��ʺ�' else t1.zjzh end as zjzh
		,t1.jgbh
--		,t1.jgmc
		,t1.afatwo_ygh
		,t1.xsje_m
		,t1.shje_m
		,t1.xsje_y
		,t1.shje_y
		,case when t1.zjzh is null or trim(t1.zjzh)='' or coalesce(t2.cpqmfe,0)<>0 then t1.qmfe else 0 end as qmfe
		,t1.qmfe_ys as qmfe_ys
		,coalesce(t2.cpqmfe_ys,0) as cpqmfe_ys
		,coalesce(t2.cpqmfe,0) as cpqmfe
		,case when t1.cplx in ('Ȩ����˽ļ����','����-Ȩ����') and coalesce(t2.cpqmfe,0)>0 then t1.qmfe/coalesce(t2.cpqmfe,0) else 0 end as bybl
		,case when t1.cplx in ('�̶�����','PE��Ʒ','����-�̶�����') then t1.qmbyje_gd 
			when t1.cplx='Ȩ����˽ļ����' and (trim(t1.zjzh)='' or t1.zjzh is null) then t1.qmfe*coalesce(t3.jz,1)
			when t1.cplx in ('Ȩ����˽ļ����','����-Ȩ����') and (t1.zjzh is not null and trim(t1.zjzh)<>'') then coalesce(t2.qmzc,0)*bybl
			else t1.qmfe end as qmbyje
		,case when t1.cplx in ('�̶�����','PE��Ʒ','����-�̶�����') then t1.qmbyje_gd 
			when t1.cplx='Ȩ����˽ļ����' and (trim(t1.zjzh)='' or t1.zjzh is null) then t1.qmfe*coalesce(t3.jz,1)
			when t1.cplx in ('Ȩ����˽ļ����','����-Ȩ����') and (t1.zjzh is not null and trim(t1.zjzh)<>'') then coalesce(t2.rjzc_m,0)*bybl
			else t1.qmfe end as byje_yrj
		,case when t1.cplx in ('�̶�����','PE��Ʒ','����-�̶�����') then t1.qmbyje_gd 
			when t1.cplx='Ȩ����˽ļ����' and (trim(t1.zjzh)='' or t1.zjzh is null) then t1.qmfe*coalesce(t3.jz,1)
			when t1.cplx in ('Ȩ����˽ļ����','����-Ȩ����') and (t1.zjzh is not null and trim(t1.zjzh)<>'') then coalesce(t2.rjzc_y,0)*bybl
			else t1.qmfe end as byje_nrj
			
	into #temp_twcp_khmx
	from 
	(--Ա�������Ʒ������
		select
			t1.uid
			,t1.cpmc
			,t1.cplx
			,t1.zjzh
			,t1.jgbh
			,t1.afatwo_ygh
			,sum(t1.xsje_m) as xsje_m
			,sum(t1.shje_m) as shje_m
			,sum(t1.xsje_y) as xsje_y
			,sum(t1.shje_y) as shje_y
			,sum(t1.qmfe_ys) as qmfe_ys
			,case when qmfe_ys<0 then 0 else qmfe_ys end as qmfe			
			,sum(t1.qmbyje_gd) as qmbyje_gd	
		from
		(
			select
				case when t1.cplx='����' or t1.cplx='����-�̶�����' then t1.zjzh
					else t1.jgbh||trim(t1.khmc)
					end as uid		
				,t1.cpmc
				,case when t1.cplx='����' then '����-Ȩ����' else trim(t1.cplx) end as cplx
				,t1.zjzh
				,case when t1.cplx = '����' then t2.jgbh 
					else t1.jgbh end as jgbh
				,case when t1.cplx = '����' then t2.jgbh 
					when t1.cplx<>'����' and t_yg.afatwo_ygh is null then t1.jgbh else t_yg.afatwo_ygh end as afatwo_ygh
				,sum(case when t1.nian=@nian and t1.yue=@yue and t1.ywlx in ('�Ϲ�','�깺','׷��') then t1.je else 0 end) as xsje_m 
				,sum(case when t1.nian=@nian and t1.yue=@yue and t1.ywlx in ('���','�������','ȫ�����') then t1.je else 0 end) as shje_m
				,sum(case when t1.nian=@nian and t1.yue<=@yue and t1.ywlx in ('�Ϲ�','�깺','׷��') then t1.je else 0 end) as xsje_y
				,sum(case when t1.nian=@nian and t1.yue<=@yue and t1.ywlx in ('���','�������','ȫ�����') then t1.je else 0 end) as shje_y
				,sum(case when t1.cplx='Ȩ����˽ļ����' and t1.ywlx in ('���','�������','ȫ�����') then -t1.fe
						when t1.cplx='Ȩ����˽ļ����' and t1.ywlx in ('�Ϲ�','�깺','׷��','����') then t1.fe
						when t1.cplx='����' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('���','�������','ȫ�����') then -t1.je		--�����Ʒ����ѯ��Ч����
						when t1.cplx='����' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('�Ϲ�','�깺','׷��','����') then t1.je		--�����Ʒ����ѯ��Ч����		
						else 0 end) as qmfe_ys
	--			,case when qmfe_ys>0 then qmfe_ys else 0 end as qmfe --������ĩ�ݶ��		
				,sum(case when t1.cplx in ('�̶�����','PE��Ʒ','����-�̶�����') and t1.ywlx in ('�Ϲ�','�깺','׷��') 
	--				and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_yc then t1.je else 0 end) as qmbyje_gd	--�̶������ౣ�н���Ч���ڵ����ۼ���		
					and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym then t1.je else 0 end) as qmbyje_gd	--�̶������ౣ�н���Ч���ڵ����ۼ���	
			from dba.gt_ods_simu_trade_jour t1			
			left join #temp_ygh_tc t_yg on t1.tgbh=t_yg.ygh
			left join 
			(
				SELECT
					zjzh,
					cplx,
					jgbh
				FROM dba.gt_ods_simu_trade_jour t0
				WHERE ny = (
					SELECT max(ny)
						FROM dba.gt_ods_simu_trade_jour
						WHERE zjzh = t0.zjzh AND cplx = t0.cplx)
					AND cplx = '����'
					GROUP BY zjzh, cplx, jgbh
			) t2 on t1.zjzh = t2.zjzh and t1.cplx = t2.cplx
			where t1.ny<=@ny
			group by 
				uid
				,t1.cpmc
				,cplx
				,t1.zjzh
				,jgbh
				,afatwo_ygh
		) t1
		group by
			t1.uid
			,t1.cpmc
			,t1.cplx
			,t1.zjzh
			,t1.jgbh
			,t1.afatwo_ygh
	) t1
	left join
	(--��Ʒ���������˽ļ����
		select
			t1.zjzh
			,t1.cpqmfe
			,t1.cpqmfe_ys
			,t2.qmzc
			,t2.rjzc_m
			,t2.rjzc_y
		from
		(
			select
				t1.zjzh
				,sum(case when t1.cplx='Ȩ����˽ļ����' and t1.ywlx in ('���','�������','ȫ�����') then -fe
					  when t1.cplx='Ȩ����˽ļ����' and t1.ywlx in ('�Ϲ�','�깺','׷��','����') then fe
					  when t1.cplx='����' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('�Ϲ�','�깺','׷��','����') then je
					  when t1.cplx='����' and t1.yxq_start<=@td_ym and t1.yxq_end>=@td_ym and t1.ywlx in ('���','�������','ȫ�����') then -je				  
					  else 0 end) as cpqmfe_ys
				,case when cpqmfe_ys>1 then cpqmfe_ys else 0 end as cpqmfe	--��Ʒ��ĩ�ݶ�С��1�İ�0�㣬���Ᵽ�б����쳣
			from dba.gt_ods_simu_trade_jour t1
			where t1.ny<=@ny 
--				and t1.yxq_end>=@td_ym
				and	t1.cplx in ('Ȩ����˽ļ����','����')
				and t1.zjzh is not null
			group by t1.zjzh
		) t1
		left join
		(
			select
				t1.zjzh		
				,coalesce(t1.��ĩ�ʲ�,0)+coalesce(t2.rzrq_qmzc,0) as qmzc
				,coalesce(t1.�վ��ʲ�,0)+coalesce(t2.rzrq_rjzc_m,0) as rjzc_m
				,coalesce(t3.�վ��ʲ�,0)+coalesce(t2.rzrq_rjzc_y,0) as rjzc_y
			from 
			(
				select
					t1.�ʽ��˻� as zjzh
					,t1.��ĩ�ʲ�
					,t1.�վ��ʲ�
				from DBA.�ͻ��ۺϷ���_�� t1
				where t1.���=@nian and t1.�·�=@yue
			) t1
			left join
			(
				select
					t1.zjzh
					,t1.rzrq_qmzc
					,t1.rzrq_rjzc_m
					,t1.rzrq_rjzc_y
				from dba.T_DDW_XYZQ_F00_KHZHFX_2011 t1
				where t1.nian=@nian and t1.yue=@yue
			) t2 on t1.zjzh=t2.zjzh
			left join
			(
				select
					t1.�ʽ��˻� as zjzh
					,t1.�վ��ʲ�
				from DBA.�ͻ��ۺϷ���_�� t1
				where t1.���=@nian and t1.�·�=@yue
							and �˻�״̬ = '����'
			) t3 on t1.zjzh=t3.zjzh
		) t2 on t1.zjzh=t2.zjzh
	) t2 on t1.zjzh=t2.zjzh
	left join
	(--��Ʒ��ֵ
		select
			t1.zjzh
			,max(t1.jz) as jz
		from dba.gt_ods_simu_trade_jour t1
		where t1.nian=@nian and t1.yue=@yue
			and t1.cplx in ('Ȩ����˽ļ����','����')
			and t1.zjzh is not null
		group by t1.zjzh
	) t3 on t1.zjzh=t3.zjzh
	left join #temp_twkhdz t4 on t1.uid=t4.uid
 ;
 commit;
 
 
    --PART4 1100_�����Ʒ��չ�����_��ʱ��
	insert into DM.T_EVT_OUTMARK_PROD_EXT_M
	(
	 YEAR             --��  
	,MTH              --��
	,CUST_ID          --�ͻ�����
	,OACT_DT          --��������
	,IF_MTH_NA        --�Ƿ�������  
	,IF_YEAR_NA       --�Ƿ�������  
	,CPTL_ACCT        --�ʽ��˺�  
	,AFA_SEC_EMPID    --AFA_����Ա���� 
	,ORG_ID           --��������
	,PROD_NAME        --��Ʒ����
	,PROD_CD          --��Ʒ����  
	,PROD_TYPE        --��Ʒ����  
	,SALE_MTD         --����_���ۼ�  
	,REDP_MTD         --���_���ۼ�  
	,SALE_YTD         --����_���ۼ�  
	,REDP_YTD         --���_���ۼ�  
	,RETAIN_FINAL     --����_��ĩ  
	,RETAIN_MDA       --����_���վ�  
	,RETAIN_YDA       --����_���վ�  
	,LOAD_DT          --��ϴ����
	)
(
	select
		t1.nian	
		,t1.yue
		,t1.uid as khbh
		,t1.khrq
		,t1.sfxz_m
		,t1.sfxz_y
		,t1.zjzh
		,t1.afatwo_ygh
		,t1.jgbh
		,t1.cpmc
		,t1.cpmc as cpdm
		,t1.cplx
		,t1.xsje_m as xs_ylj
		,t1.shje_m as sh_ylj
		,t1.xsje_y as xs_nlj
		,t1.shje_y as sh_nlj
		,t1.qmbyje as by_qm
		,t1.byje_yrj as by_yrj
		,t1.byje_nrj as by_nrj		
		,@V_BIN_DATE  AS LOAD_DT  --��ϴ����
	from #temp_twcp_khmx t1	
	where t1.cplx not in ('����-Ȩ����','����-�̶�����')
	union all
	select
		t1.nian	
		,t1.yue
		,t1.uid as khbh
		,t1.khrq
		,t1.sfxz_m
		,t1.sfxz_y
		,t1.zjzh
		,case when t_gx.afatwo_ygh is null then t1.jgbh else t_gx.afatwo_ygh end as afatwo_ygh
		,case when t_gx.jgbh_yg is null then t1.jgbh else t_gx.jgbh_yg end as jgbh
		,t1.cpmc
		,t1.cpmc as cpdm
		,t1.cplx
		,sum(t1.xsje_m*isnull(t_gx.jxbl6, 1)) as xs_ylj
		,sum(t1.shje_m*isnull(t_gx.jxbl6, 1)) as sh_ylj
		,sum(t1.xsje_y*isnull(t_gx.jxbl6, 1)) as xs_nlj
		,sum(t1.shje_y*isnull(t_gx.jxbl6, 1)) as sh_nlj
		,sum(t1.qmbyje*isnull(t_gx.jxbl6, 1)) as by_qm
		,sum(t1.byje_yrj*isnull(t_gx.jxbl6, 1)) as by_yrj
		,sum(t1.byje_nrj*isnull(t_gx.jxbl6, 1)) as by_nrj	
        ,@V_BIN_DATE  AS LOAD_DT  --��ϴ����		
	from #temp_twcp_khmx t1	
	left join dba.t_ddw_serv_relation t_gx on t1.zjzh=t_gx.zjzh and t_gx.nian=@nian and t_gx.yue=@yue	
	where t1.cplx in ('����-Ȩ����','����-�̶�����')
	group by t1.nian	
		,t1.yue
		,t1.uid
		,t1.khrq
		,t1.sfxz_m
		,t1.sfxz_y
		,t1.zjzh
		,afatwo_ygh
		,jgbh
		,t1.cpmc
		,t1.cplx
);
commit;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_OUTMARK_PROD_EXT_M TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ӫҵ����Ʒ������ʵ���ձ�
  ��д��: Ҷ���
  ��������: 2018-04-09
  ��飺Ӫҵ����Ʒ��ʵ���ձ�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	DELETE FROM DM.T_EVT_PROD_TRD_D_BRH WHERE OCCUR_DT = @V_DATE;

  	-- Ա��-Ӫҵ����ϵ
	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--Ա������
		,A.PK_ORG 		AS 		BRH_ID			--Ӫҵ������
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  		AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	CREATE TABLE #TMP_T_EVT_PROD_TRD_D_BRH(
	    OCCUR_DT             	numeric(8,0) 		NOT NULL,
		BRH_ID               	varchar(30) 		NOT NULL,
		EMP_ID		 			varchar(30) 		NOT NULL,
		PROD_CD              	varchar(30) 		NOT NULL,
		PROD_TYPE            	varchar(30) 		NOT NULL,
		ITC_RETAIN_AMT       	numeric(38,8) 		NULL,
		OTC_RETAIN_AMT       	numeric(38,8) 		NULL,
		ITC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		OTC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		ITC_SUBS_AMT         	numeric(38,8) 		NULL,
		ITC_PURS_AMT         	numeric(38,8) 		NULL,
		ITC_BUYIN_AMT        	numeric(38,8) 		NULL,
		ITC_REDP_AMT         	numeric(38,8) 		NULL,
		ITC_SELL_AMT         	numeric(38,8) 		NULL,
		OTC_SUBS_AMT         	numeric(38,8) 		NULL,
		OTC_PURS_AMT         	numeric(38,8) 		NULL,
		OTC_CASTSL_AMT       	numeric(38,8) 		NULL,
		OTC_COVT_IN_AMT      	numeric(38,8) 		NULL,
		OTC_REDP_AMT         	numeric(38,8) 		NULL,
		OTC_COVT_OUT_AMT     	numeric(38,8) 		NULL,
		ITC_SUBS_SHAR        	numeric(38,8) 		NULL,
		ITC_PURS_SHAR        	numeric(38,8) 		NULL,
		ITC_BUYIN_SHAR       	numeric(38,8) 		NULL,
		ITC_REDP_SHAR        	numeric(38,8) 		NULL,
		ITC_SELL_SHAR        	numeric(38,8) 		NULL,
		OTC_SUBS_SHAR        	numeric(38,8) 		NULL,
		OTC_PURS_SHAR        	numeric(38,8) 		NULL,
		OTC_CASTSL_SHAR      	numeric(38,8) 		NULL,
		OTC_COVT_IN_SHAR     	numeric(38,8) 		NULL,
		OTC_REDP_SHAR        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_SHAR    	numeric(38,8) 		NULL,
		ITC_SUBS_CHAG        	numeric(38,8) 		NULL,
		ITC_PURS_CHAG        	numeric(38,8) 		NULL,
		ITC_BUYIN_CHAG       	numeric(38,8) 		NULL,
		ITC_REDP_CHAG        	numeric(38,8) 		NULL,
		ITC_SELL_CHAG        	numeric(38,8) 		NULL,
		OTC_SUBS_CHAG        	numeric(38,8) 		NULL,
		OTC_PURS_CHAG        	numeric(38,8) 		NULL,
		OTC_CASTSL_CHAG      	numeric(38,8) 		NULL,
		OTC_COVT_IN_CHAG     	numeric(38,8) 		NULL,
		OTC_REDP_CHAG        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_CHAG    	numeric(38,8) 		NULL,
		CONTD_SALE_SHAR      	numeric(38,8) 		NULL,
		CONTD_SALE_AMT       	numeric(38,8) 		NULL
	);

	INSERT INTO #TMP_T_EVT_PROD_TRD_D_BRH(
		  OCCUR_DT          		--��������
		 ,BRH_ID					--Ӫҵ������
		 ,EMP_ID            		--Ա������			
		 ,PROD_CD           		--��Ʒ����			
		 ,PROD_TYPE         		--��Ʒ����			
		 ,ITC_RETAIN_AMT    		--���ڱ��н��			
		 ,OTC_RETAIN_AMT    		--���Ᵽ�н��			
		 ,ITC_RETAIN_SHAR   		--���ڱ��зݶ�			
		 ,OTC_RETAIN_SHAR   		--���Ᵽ�зݶ�			
		 ,ITC_SUBS_AMT      		--�����Ϲ����			
		 ,ITC_PURS_AMT      		--�����깺���			
		 ,ITC_BUYIN_AMT     		--����������			
		 ,ITC_REDP_AMT      		--������ؽ��			
		 ,ITC_SELL_AMT      		--�����������			
		 ,OTC_SUBS_AMT      		--�����Ϲ����			
		 ,OTC_PURS_AMT      		--�����깺���			
		 ,OTC_CASTSL_AMT    		--���ⶨͶ���			
		 ,OTC_COVT_IN_AMT   		--����ת������			
		 ,OTC_REDP_AMT      		--������ؽ��			
		 ,OTC_COVT_OUT_AMT  		--����ת�������			
		 ,ITC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		 ,ITC_PURS_SHAR     		--�����깺�ݶ�			
		 ,ITC_BUYIN_SHAR    		--��������ݶ�			
		 ,ITC_REDP_SHAR     		--������طݶ�			
		 ,ITC_SELL_SHAR     		--���������ݶ�			
		 ,OTC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		 ,OTC_PURS_SHAR     		--�����깺�ݶ�			
		 ,OTC_CASTSL_SHAR   		--���ⶨͶ�ݶ�			
		 ,OTC_COVT_IN_SHAR  		--����ת����ݶ�			
		 ,OTC_REDP_SHAR     		--������طݶ�			
		 ,OTC_COVT_OUT_SHAR 		--����ת�����ݶ�			
		 ,ITC_SUBS_CHAG     		--�����Ϲ�������			
		 ,ITC_PURS_CHAG     		--�����깺������			
		 ,ITC_BUYIN_CHAG    		--��������������			
		 ,ITC_REDP_CHAG     		--�������������			
		 ,ITC_SELL_CHAG     		--��������������			
		 ,OTC_SUBS_CHAG     		--�����Ϲ�������			
		 ,OTC_PURS_CHAG     		--�����깺������			
		 ,OTC_CASTSL_CHAG   		--���ⶨͶ������			
		 ,OTC_COVT_IN_CHAG  		--����ת����������			
		 ,OTC_REDP_CHAG     		--�������������			
		 ,OTC_COVT_OUT_CHAG 		--����ת����������			
		 ,CONTD_SALE_SHAR   		--�������۷ݶ�			
		 ,CONTD_SALE_AMT    		--�������۽��			
	)
	SELECT 
		  T.OCCUR_DT						AS			OCCUR_DT          		--��������
		 ,T1.BRH_ID							AS 			BRH_ID					--Ӫҵ������
		 ,T.EMP_ID	  						AS 			EMP_ID					--Ա������
		 ,T.PROD_CD 						AS  		PROD_CD 				--��Ʒ����				
		 ,T.PROD_TYPE 						AS  		PROD_TYPE 				--��Ʒ����
		 ,T.ITC_RETAIN_AMT    				AS 			ITC_RETAIN_AMT    		--���ڱ��н��		
		 ,T.OTC_RETAIN_AMT    				AS 			OTC_RETAIN_AMT    		--���Ᵽ�н��		
		 ,T.ITC_RETAIN_SHAR   				AS 			ITC_RETAIN_SHAR   		--���ڱ��зݶ�		
		 ,T.OTC_RETAIN_SHAR   				AS 			OTC_RETAIN_SHAR   		--���Ᵽ�зݶ�		
		 ,T.ITC_SUBS_AMT      				AS 			ITC_SUBS_AMT      		--�����Ϲ����		
		 ,T.ITC_PURS_AMT      				AS 			ITC_PURS_AMT      		--�����깺���		
		 ,T.ITC_BUYIN_AMT     				AS 			ITC_BUYIN_AMT     		--����������		
		 ,T.ITC_REDP_AMT      				AS 			ITC_REDP_AMT      		--������ؽ��		
		 ,T.ITC_SELL_AMT      				AS 			ITC_SELL_AMT      		--�����������		
		 ,T.OTC_SUBS_AMT      				AS 			OTC_SUBS_AMT      		--�����Ϲ����		
		 ,T.OTC_PURS_AMT      				AS 			OTC_PURS_AMT      		--�����깺���		
		 ,T.OTC_CASTSL_AMT    				AS 			OTC_CASTSL_AMT    		--���ⶨͶ���		
		 ,T.OTC_COVT_IN_AMT   				AS 			OTC_COVT_IN_AMT   		--����ת������	
		 ,T.OTC_REDP_AMT      				AS 			OTC_REDP_AMT      		--������ؽ��		
		 ,T.OTC_COVT_OUT_AMT  				AS 			OTC_COVT_OUT_AMT  		--����ת�������	
		 ,T.ITC_SUBS_SHAR     				AS 			ITC_SUBS_SHAR     		--�����Ϲ��ݶ�		
		 ,T.ITC_PURS_SHAR     				AS 			ITC_PURS_SHAR     		--�����깺�ݶ�		
		 ,T.ITC_BUYIN_SHAR    				AS 			ITC_BUYIN_SHAR    		--��������ݶ�		
		 ,T.ITC_REDP_SHAR     				AS 			ITC_REDP_SHAR     		--������طݶ�		
		 ,T.ITC_SELL_SHAR     				AS 			ITC_SELL_SHAR     		--���������ݶ�		
		 ,T.OTC_SUBS_SHAR     				AS 			OTC_SUBS_SHAR     		--�����Ϲ��ݶ�		
		 ,T.OTC_PURS_SHAR     				AS 			OTC_PURS_SHAR     		--�����깺�ݶ�		
		 ,T.OTC_CASTSL_SHAR   				AS 			OTC_CASTSL_SHAR   		--���ⶨͶ�ݶ�		
		 ,T.OTC_COVT_IN_SHAR  				AS 			OTC_COVT_IN_SHAR  		--����ת����ݶ�	
		 ,T.OTC_REDP_SHAR     				AS 			OTC_REDP_SHAR     		--������طݶ�		
		 ,T.OTC_COVT_OUT_SHAR 				AS 			OTC_COVT_OUT_SHAR 		--����ת�����ݶ�	
		 ,T.ITC_SUBS_CHAG     				AS 			ITC_SUBS_CHAG     		--�����Ϲ�������	
		 ,T.ITC_PURS_CHAG     				AS 			ITC_PURS_CHAG     		--�����깺������	
		 ,T.ITC_BUYIN_CHAG    				AS 			ITC_BUYIN_CHAG    		--��������������	
		 ,T.ITC_REDP_CHAG     				AS 			ITC_REDP_CHAG     		--�������������	
		 ,T.ITC_SELL_CHAG     				AS 			ITC_SELL_CHAG     		--��������������	
		 ,T.OTC_SUBS_CHAG     				AS 			OTC_SUBS_CHAG     		--�����Ϲ�������	
		 ,T.OTC_PURS_CHAG     				AS 			OTC_PURS_CHAG     		--�����깺������	
		 ,T.OTC_CASTSL_CHAG   				AS 			OTC_CASTSL_CHAG   		--���ⶨͶ������	
		 ,T.OTC_COVT_IN_CHAG  				AS 			OTC_COVT_IN_CHAG  		--����ת����������	
		 ,T.OTC_REDP_CHAG     				AS 			OTC_REDP_CHAG     		--�������������	
		 ,T.OTC_COVT_OUT_CHAG 				AS 			OTC_COVT_OUT_CHAG 		--����ת����������	
		 ,T.CONTD_SALE_SHAR   				AS 			CONTD_SALE_SHAR   		--�������۷ݶ�		
		 ,T.CONTD_SALE_AMT    				AS 			CONTD_SALE_AMT    		--�������۽��		
	FROM DM.T_EVT_PROD_TRD_D_EMP T
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	  AND T1.BRH_ID IS NOT NULL;
	
	--����ʱ��İ�Ӫҵ��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	INSERT INTO DM.T_EVT_PROD_TRD_D_BRH (
			  OCCUR_DT          		--��������
		     ,BRH_ID            		--Ӫҵ������
		     ,PROD_CD           		--��Ʒ����			
		     ,PROD_TYPE         		--��Ʒ����			
		     ,ITC_RETAIN_AMT    		--���ڱ��н��			
		     ,OTC_RETAIN_AMT    		--���Ᵽ�н��			
		     ,ITC_RETAIN_SHAR   		--���ڱ��зݶ�			
		     ,OTC_RETAIN_SHAR   		--���Ᵽ�зݶ�			
		     ,ITC_SUBS_AMT      		--�����Ϲ����			
		     ,ITC_PURS_AMT      		--�����깺���			
		     ,ITC_BUYIN_AMT     		--����������			
		     ,ITC_REDP_AMT      		--������ؽ��			
		     ,ITC_SELL_AMT      		--�����������			
		     ,OTC_SUBS_AMT      		--�����Ϲ����			
		     ,OTC_PURS_AMT      		--�����깺���			
		     ,OTC_CASTSL_AMT    		--���ⶨͶ���			
		     ,OTC_COVT_IN_AMT   		--����ת������			
		     ,OTC_REDP_AMT      		--������ؽ��			
		     ,OTC_COVT_OUT_AMT  		--����ת�������			
		     ,ITC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		     ,ITC_PURS_SHAR     		--�����깺�ݶ�			
		     ,ITC_BUYIN_SHAR    		--��������ݶ�			
		     ,ITC_REDP_SHAR     		--������طݶ�			
		     ,ITC_SELL_SHAR     		--���������ݶ�			
		     ,OTC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		     ,OTC_PURS_SHAR     		--�����깺�ݶ�			
		     ,OTC_CASTSL_SHAR   		--���ⶨͶ�ݶ�			
		     ,OTC_COVT_IN_SHAR  		--����ת����ݶ�			
		     ,OTC_REDP_SHAR     		--������طݶ�			
		     ,OTC_COVT_OUT_SHAR 		--����ת�����ݶ�			
		     ,ITC_SUBS_CHAG     		--�����Ϲ�������			
		     ,ITC_PURS_CHAG     		--�����깺������			
		     ,ITC_BUYIN_CHAG    		--��������������			
		     ,ITC_REDP_CHAG     		--�������������			
		     ,ITC_SELL_CHAG     		--��������������			
		     ,OTC_SUBS_CHAG     		--�����Ϲ�������			
		     ,OTC_PURS_CHAG     		--�����깺������			
		     ,OTC_CASTSL_CHAG   		--���ⶨͶ������			
		     ,OTC_COVT_IN_CHAG  		--����ת����������			
		     ,OTC_REDP_CHAG     		--�������������			
		     ,OTC_COVT_OUT_CHAG 		--����ת����������			
		     ,CONTD_SALE_SHAR   		--�������۷ݶ�			
		     ,CONTD_SALE_AMT    		--�������۽��		
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              	--��������		
			,BRH_ID									AS    BRH_ID                	--Ӫҵ������	
			,PROD_CD           		 				AS    PROD_CD					--��Ʒ����			
		    ,PROD_TYPE         						AS    PROD_TYPE					--��Ʒ����			
			,SUM(ITC_RETAIN_AMT)    				AS    ITC_RETAIN_AMT   			--���ڱ��н��		
			,SUM(OTC_RETAIN_AMT)    				AS    OTC_RETAIN_AMT   			--���Ᵽ�н��		
			,SUM(ITC_RETAIN_SHAR)   				AS    ITC_RETAIN_SHAR  			--���ڱ��зݶ�		
			,SUM(OTC_RETAIN_SHAR)  					AS    OTC_RETAIN_SHAR  			--���Ᵽ�зݶ�		
			,SUM(ITC_SUBS_AMT)      				AS    ITC_SUBS_AMT     			--�����Ϲ����		
			,SUM(ITC_PURS_AMT)      				AS    ITC_PURS_AMT     			--�����깺���		
			,SUM(ITC_BUYIN_AMT)     				AS    ITC_BUYIN_AMT    			--����������		
			,SUM(ITC_REDP_AMT)      				AS    ITC_REDP_AMT     			--������ؽ��		
			,SUM(ITC_SELL_AMT)      				AS    ITC_SELL_AMT     			--�����������		
			,SUM(OTC_SUBS_AMT)      				AS    OTC_SUBS_AMT     			--�����Ϲ����		
			,SUM(OTC_PURS_AMT)      				AS    OTC_PURS_AMT     			--�����깺���		
			,SUM(OTC_CASTSL_AMT)    				AS    OTC_CASTSL_AMT   			--���ⶨͶ���		
			,SUM(OTC_COVT_IN_AMT)   				AS    OTC_COVT_IN_AMT  			--����ת������	
			,SUM(OTC_REDP_AMT)      				AS    OTC_REDP_AMT     			--������ؽ��		
			,SUM(OTC_COVT_OUT_AMT)  				AS    OTC_COVT_OUT_AMT 			--����ת�������	
			,SUM(ITC_SUBS_SHAR)     				AS    ITC_SUBS_SHAR    			--�����Ϲ��ݶ�		
			,SUM(ITC_PURS_SHAR)     				AS    ITC_PURS_SHAR    			--�����깺�ݶ�		
			,SUM(ITC_BUYIN_SHAR)    				AS    ITC_BUYIN_SHAR   			--��������ݶ�		
			,SUM(ITC_REDP_SHAR)     				AS    ITC_REDP_SHAR    			--������طݶ�		
			,SUM(ITC_SELL_SHAR)     				AS    ITC_SELL_SHAR    			--���������ݶ�		
			,SUM(OTC_SUBS_SHAR)     				AS    OTC_SUBS_SHAR    			--�����Ϲ��ݶ�		
			,SUM(OTC_PURS_SHAR)    					AS    OTC_PURS_SHAR    			--�����깺�ݶ�		
			,SUM(OTC_CASTSL_SHAR)   				AS    OTC_CASTSL_SHAR  			--���ⶨͶ�ݶ�		
			,SUM(OTC_COVT_IN_SHAR)  				AS    OTC_COVT_IN_SHAR 			--����ת����ݶ�	
			,SUM(OTC_REDP_SHAR)     				AS    OTC_REDP_SHAR    			--������طݶ�		
			,SUM(OTC_COVT_OUT_SHAR) 				AS    OTC_COVT_OUT_SHAR			--����ת�����ݶ�	
			,SUM(ITC_SUBS_CHAG)    					AS    ITC_SUBS_CHAG    			--�����Ϲ�������	
			,SUM(ITC_PURS_CHAG)     				AS    ITC_PURS_CHAG    			--�����깺������	
			,SUM(ITC_BUYIN_CHAG)    				AS    ITC_BUYIN_CHAG   			--��������������	
			,SUM(ITC_REDP_CHAG)     				AS    ITC_REDP_CHAG    			--�������������	
			,SUM(ITC_SELL_CHAG)     				AS    ITC_SELL_CHAG    			--��������������	
			,SUM(OTC_SUBS_CHAG)     				AS    OTC_SUBS_CHAG    			--�����Ϲ�������	
			,SUM(OTC_PURS_CHAG)     				AS    OTC_PURS_CHAG    			--�����깺������	
			,SUM(OTC_CASTSL_CHAG)   				AS    OTC_CASTSL_CHAG  			--���ⶨͶ������	
			,SUM(OTC_COVT_IN_CHAG)  				AS    OTC_COVT_IN_CHAG 			--����ת����������	
			,SUM(OTC_REDP_CHAG)     				AS    OTC_REDP_CHAG    			--�������������	
			,SUM(OTC_COVT_OUT_CHAG) 				AS    OTC_COVT_OUT_CHAG			--����ת����������	
			,SUM(CONTD_SALE_SHAR)   				AS    CONTD_SALE_SHAR  			--�������۷ݶ�		
			,SUM(CONTD_SALE_AMT)    				AS    CONTD_SALE_AMT   			--�������۽��		
		FROM #TMP_T_EVT_PROD_TRD_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID,T.PROD_CD,T.PROD_TYPE;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_D_D(IN @v_date int)
begin 
  
  /******************************************************************
  ������: ��Ʒ������ʵ��_�ձ�
  ��д��: ����
  ��������: 2017-12-07
  ��飺��¼�����Ʒ�������ۣ�����������������ơ�֤ȯ���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
	commit;
  
    DELETE FROM DM.T_EVT_PROD_TRD_D_D WHERE OCCUR_DT = @v_date;
	-- ����
	INSERT INTO DM.T_EVT_PROD_TRD_D_D(
	    CUST_ID      -- �ͻ�����
	    ,PROD_CD        -- ��Ʒ����
	    ,PROD_TYPE      -- ��Ʒ����
	    ,OCCUR_DT       -- ҵ������
	    ,MAIN_CPTL_ACCT -- ���ʽ��˺�
		,ITC_SUBS_AMT	-- �����Ϲ����
		,ITC_PURS_AMT  -- �����깺���
		,ITC_REDP_AMT  -- ������ؽ��
		,ITC_RETAIN_AMT  -- ���ڱ��н��
		,ITC_BUYIN_AMT -- ����������
		,ITC_SELL_AMT  -- �����������
		,OTC_SUBS_AMT  -- �����Ϲ����
		,OTC_PURS_AMT  -- �����깺���
		,OTC_REDP_AMT  -- ������ؽ��
		,OTC_RETAIN_AMT  -- ���Ᵽ�н��
		,OTC_CASTSL_AMT    -- ���ⶨͶ���
		,OTC_COVT_IN_AMT  -- ����ת������
		,OTC_COVT_OUT_AMT -- ����ת�������
		,ITC_RETAIN_SHAR    -- ���ڱ��зݶ�
		,OTC_RETAIN_SHAR    -- ���Ᵽ�зݶ�
		
		
		,ITC_SUBS_CHAG   -- �����Ϲ�������
		,ITC_PURS_CHAG    -- �����깺������
		,ITC_BUYIN_CHAG   -- ��������������
		,ITC_REDP_CHAG    -- �������������
		,ITC_SELL_CHAG    -- ��������������
		,OTC_SUBS_CHAG    -- �����Ϲ�������
		,OTC_PURS_CHAG    -- �����깺������
		,OTC_CASTSL_CHAG  -- ���ⶨͶ������
		,OTC_COVT_IN_CHAG    -- ����ת����������
		,OTC_REDP_CHAG        -- �������������
		,OTC_COVT_OUT_CHAG   -- ����ת����������
		,LOAD_DT
	)
	SELECT 
		b.client_id AS CUST_ID  -- �ͻ�����
		,a.jjdm AS PROD_CD        -- ��Ʒ����
		,'�������' AS PROD_TYPE  -- ��Ʒ����
		,@v_date AS OCCUR_DT   -- ҵ������
		,a.zjzh as MAIN_CPTL_ACCT   -- ���ʽ��˺�
		,a.cnje_rgqr_d AS ITC_SUBS_AMT  -- �����Ϲ����
		,a.cnje_sgqr_d AS ITC_PURS_AMT  -- �����깺���
		,a.cnje_shqr_d as ITC_REDP_AMT  -- ������ؽ��
		,a.qmsz_cn_d as ITC_RETAIN_AMT  -- ���ڱ��н��
		,a.cnje_jymr_d as ITC_BUYIN_AMT -- ����������
		,a.cnje_jymc_d as ITC_SELL_AMT  -- �����������
		,a.cwje_rgqr_d as OTC_SUBS_AMT  -- �����Ϲ����
		,a.cwje_sgqr_d as OTC_PURS_AMT  -- �����깺���
		,a.cwje_shqr_d as OTC_REDP_AMT  -- ������ؽ��
		,a.qmsz_cw_d as OTC_RETAIN_AMT  -- ���Ᵽ�н��
		,a.cwje_dsdetzqr_d as OTC_CASTSL_AMT    -- ���ⶨͶ���
		,a.cwje_zhrqr_d as OTC_COVT_IN_AMT  -- ����ת������
		,a.cwje_zhcqr_d as OTC_COVT_OUT_AMT -- ����ת�������
		
		,a.qmfe_cn_d as ITC_RETAIN_SHAR   -- ���ڱ��зݶ�
		,a.qmfe_cw_d as OTC_RETAIN_SHAR     -- ���Ᵽ�зݶ�
		
		,a.cwsxf_zhcqr_d as ITC_SUBS_CHAG   -- �����Ϲ�������
		,a.cnsxf_sgqr_d as ITC_PURS_CHAG    -- �����깺������
		,a.cnsxf_jymr_d as ITC_BUYIN_CHAG   -- ��������������
		,a.cnsxf_shqr_d as ITC_REDP_CHAG    -- �������������
		,a.cnsxf_jymc_d as ITC_SELL_CHAG    -- ��������������
		,a.cwsxf_rgqr_d as OTC_SUBS_CHAG    -- �����Ϲ�������
		,a.cwsxf_sgqr_d as OTC_PURS_CHAG    -- �����깺������
		,a.cwsxf_dsdetzqr_d as OTC_CASTSL_CHAG  -- ���ⶨͶ������
		,a.cwsxf_zhrqr_d as OTC_COVT_IN_CHAG    -- ����ת����������
		,a.cwsxf_shqr_d as OTC_REDP_CHAG        -- �������������
		,a.cwsxf_zhcqr_d as OTC_COVT_OUT_CHAG   -- ����ת����������
		,@v_date AS LOAD_DT
	FROM dba.t_ddw_xy_jjzb_d a
	LEFT JOIN DBA.T_ODS_UF2_FUNDACCOUNT b ON a.zjzh = b.fund_account and b.main_flag='1'
	WHERE a.rq=@v_date and b.client_id is not null;
    
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET ITC_SUBS_SHAR = coalesce(b.cnfe_rgqr_d,0)   -- �����Ϲ��ݶ�
        ,ITC_PURS_SHAR = coalesce(b.cnfe_sgqr_d,0)  -- �����깺�ݶ�
        ,ITC_REDP_SHAR = coalesce(b.cnfe_shqr_d,0)  -- ������طݶ�
        ,ITC_BUYIN_SHAR = coalesce(b.cnfe_jymr_d,0) -- ��������ݶ�
        ,ITC_SELL_SHAR = coalesce(b.cnfe_jymc_d,0) -- ���������ݶ�
        ,OTC_SUBS_SHAR = coalesce(b.cwfe_rgqr_d,0) -- �����Ϲ��ݶ�
        ,OTC_PURS_SHAR = coalesce(b.cwfe_sgqr_d,0) -- �����깺�ݶ�
        ,OTC_REDP_SHAR = coalesce(b.cwfe_shqr_d,0)  -- ������طݶ�
        ,OTC_CASTSL_SHAR = coalesce(b.cwfe_dsdetzqr_d,0) -- ���ⶨͶ�ݶ�
        ,OTC_COVT_IN_SHAR = coalesce(b.cwfe_zhrqr_d,0)  -- ����ת����ݶ�
        ,OTC_COVT_OUT_SHAR = coalesce(b.cwfe_zhcqr_d,0) -- ����ת�����ݶ�
        
        ,ITC_SUBS_CNT = coalesce(b.cnbs_rgqr_d,0)    -- �����Ϲ�����
        ,ITC_PURS_CNT = coalesce(b.cnbs_sgqr_d,0)   -- �����깺����
        ,ITC_BUYIN_CNT = coalesce(b.cnbs_jymr_d,0) -- �����������
        ,ITC_REDP_CNT = coalesce(b.cnbs_shqr_d,0) -- ������ر���
        ,ITC_SELL_CNT = coalesce(b.cnbs_jymc_d,0)   -- ������������
        ,OTC_SUBS_CNT = coalesce(b.cwbs_rgqr_d,0)   -- �����Ϲ�����
        ,OTC_PURS_CNT = coalesce(b.cwbs_sgqr_d,0)   -- �����깺����
        ,OTC_CASTSL_CNT = coalesce(b.cwbs_dsdetzqr_d,0) -- ���ⶨͶ����
        ,OTC_COVT_IN_CNT = coalesce(b.cwbs_zhrqr_d,0)   -- ����ת�������
        ,OTC_REDP_CNT = coalesce(b.cwbs_shqr_d,0)   -- ������ر���
        ,OTC_COVT_OUT_CNT = coalesce(b.cwbs_zhcqr_d,0) -- ����ת��������
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        SELECT a.fund_acct AS zjzh,
              a.stock_cd AS jjdm,
              
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND (a.busi_cd IN ('3408', '9994') OR (a.busi_cd='5140' and note like '%���Ż����Ϲ��������%')) THEN 1 ELSE 0 END) AS cnbs_rgqr_d,      -- �����Ϲ�����
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5122' THEN 1 ELSE 0 END) AS cnbs_sgqr_d,      -- �����깺����
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5124' THEN 1 ELSE 0 end) AS cnbs_shqr_d,      -- ������ر���
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3101' THEN 1 ELSE 0 end) AS cnbs_jymr_d,      -- �����������
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3102' THEN 1 ELSE 0 end) AS cnbs_jymc_d,      -- ������������
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5130' THEN 1 ELSE 0 END) AS cwbs_rgqr_d,            -- �����Ϲ�����
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5122' THEN 1 ELSE 0 END) AS cwbs_sgqr_d,            -- �����깺����
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5139' THEN 1 ELSE 0 END) AS cwbs_dsdetzqr_d,        -- ���ⶨͶ����
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5137' THEN 1 ELSE 0 END) AS cwbs_zhrqr_d,           -- ����ת�������
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd IN ('5136', '5138') THEN 1 ELSE 0 END) AS cwbs_zhcqr_d,           -- ����ת��������
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5124' THEN 1 ELSE 0 END) AS cwbs_shqr_d,             -- ������ر���
              
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND (a.busi_cd IN ('3408', '9994') OR (a.busi_cd='5140' and note like '%���Ż����Ϲ��������%')) THEN a.trad_num ELSE 0 END) AS cnfe_rgqr_d,      -- �����Ϲ��ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5122' THEN a.trad_num ELSE 0 END) AS cnfe_sgqr_d,      -- �����깺�ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '5124' THEN a.trad_num ELSE 0 end) AS cnfe_shqr_d,      -- ������طݶ�
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3101' THEN a.trad_num ELSE 0 end) AS cnfe_jymr_d,      -- ��������ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('01', '02') AND a.busi_cd = '3102' THEN a.trad_num ELSE 0 end) AS cnfe_jymc_d,      -- ���������ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5130' THEN a.trad_num ELSE 0 END) AS cwfe_rgqr_d,            -- �����Ϲ��ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5122' THEN a.trad_num ELSE 0 END) AS cwfe_sgqr_d,            -- �����깺�ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5139' THEN a.trad_num ELSE 0 END) AS cwfe_dsdetzqr_d,        -- ���ⶨͶ�ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5137' THEN a.trad_num ELSE 0 END) AS cwfe_zhrqr_d,           -- ����ת����ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd IN ('5136', '5138') THEN a.trad_num ELSE 0 END) AS cwfe_zhcqr_d,           -- ����ת�����ݶ�
              SUM(CASE WHEN a.market_type_cd IN ('07') AND a.busi_cd = '5124' THEN a.trad_num ELSE 0 END) AS cwfe_shqr_d             -- ������طݶ�
         FROM dba.t_edw_t05_trade_jour a
        WHERE a.load_dt = @v_date
          AND a.stock_type_cd IN ('19', '1A')
        GROUP BY a.fund_acct, a.stock_cd
    ) b ON a.MAIN_CPTL_ACCT=b.zjzh
    where a.OCCUR_DT=@v_date;
    
    -- TODO: �������۷ݶ�(CONTD_SALE_SHAR) �������۽��(CONTD_SALE_AMT)
    
    
    -- ������Ʋ�Ʒ����ʼ��
    INSERT INTO DM.T_EVT_PROD_TRD_D_D(
        CUST_ID      -- �ͻ�����
        ,PROD_CD        -- ��Ʒ����
        ,PROD_TYPE      -- ��Ʒ����
        ,OCCUR_DT       -- ҵ������
        ,MAIN_CPTL_ACCT -- ���ʽ��˺�
        
        ,ITC_SUBS_AMT
        ,ITC_PURS_AMT
        ,ITC_REDP_AMT
        ,ITC_RETAIN_AMT
        ,ITC_BUYIN_AMT
        ,ITC_SELL_AMT
        ,OTC_SUBS_AMT
        ,OTC_PURS_AMT
        ,OTC_REDP_AMT
        ,OTC_RETAIN_AMT
        ,OTC_CASTSL_AMT
        ,OTC_COVT_IN_AMT
        ,OTC_COVT_OUT_AMT
        ,ITC_SUBS_SHAR
        ,ITC_PURS_SHAR
        ,ITC_REDP_SHAR
        ,ITC_RETAIN_SHAR
        ,ITC_BUYIN_SHAR
        ,ITC_SELL_SHAR
        ,OTC_SUBS_SHAR
        ,OTC_PURS_SHAR
        ,OTC_REDP_SHAR
        ,OTC_RETAIN_SHAR
        ,OTC_CASTSL_SHAR
        ,OTC_COVT_IN_SHAR
        ,OTC_COVT_OUT_SHAR
        ,ITC_SUBS_CNT
        ,ITC_PURS_CNT
        ,ITC_BUYIN_CNT
        ,ITC_REDP_CNT
        ,ITC_SELL_CNT
        ,OTC_SUBS_CNT
        ,OTC_PURS_CNT
        ,OTC_CASTSL_CNT
        ,OTC_COVT_IN_CNT
        ,OTC_REDP_CNT
        ,OTC_COVT_OUT_CNT
        ,ITC_SUBS_CHAG
        ,ITC_PURS_CHAG
        ,ITC_BUYIN_CHAG
        ,ITC_REDP_CHAG
        ,ITC_SELL_CHAG
        ,OTC_SUBS_CHAG
        ,OTC_PURS_CHAG
        ,OTC_CASTSL_CHAG
        ,OTC_COVT_IN_CHAG
        ,OTC_REDP_CHAG
        ,OTC_COVT_OUT_CHAG
        ,CONTD_SALE_SHAR
        ,CONTD_SALE_AMT
        ,LOAD_DT
    )
    select
        a.CLIENT_ID as CUST_ID      -- �ͻ�����
        ,a.PROD_CODE as PROD_CD        -- ��Ʒ����
        ,'�������' as PROD_TYPE      -- ��Ʒ����
        ,@v_date as OCCUR_DT       -- ҵ������
        ,a.FUND_ACCOUNT AS MAIN_CPTL_ACCT -- ���ʽ��˺�
        
        ,0 as ITC_SUBS_AMT
        ,0 as ITC_PURS_AMT
        ,0 as ITC_REDP_AMT
        ,0 as ITC_RETAIN_AMT
        ,0 as ITC_BUYIN_AMT
        ,0 as ITC_SELL_AMT
        ,0 as OTC_SUBS_AMT
        ,0 as OTC_PURS_AMT
        ,0 as OTC_REDP_AMT
        ,0 as OTC_RETAIN_AMT
        ,0 as OTC_CASTSL_AMT
        ,0 as OTC_COVT_IN_AMT
        ,0 as OTC_COVT_OUT_AMT
        ,0 as ITC_SUBS_SHAR
        ,0 as ITC_PURS_SHAR
        ,0 as ITC_REDP_SHAR
        ,0 as ITC_RETAIN_SHAR
        ,0 as ITC_BUYIN_SHAR
        ,0 as ITC_SELL_SHAR
        ,0 as OTC_SUBS_SHAR
        ,0 as OTC_PURS_SHAR
        ,0 as OTC_REDP_SHAR
        ,0 as OTC_RETAIN_SHAR
        ,0 as OTC_CASTSL_SHAR
        ,0 as OTC_COVT_IN_SHAR
        ,0 as OTC_COVT_OUT_SHAR
        ,0 as ITC_SUBS_CNT
        ,0 as ITC_PURS_CNT
        ,0 as ITC_BUYIN_CNT
        ,0 as ITC_REDP_CNT
        ,0 as ITC_SELL_CNT
        ,0 as OTC_SUBS_CNT
        ,0 as OTC_PURS_CNT
        ,0 as OTC_CASTSL_CNT
        ,0 as OTC_COVT_IN_CNT
        ,0 as OTC_REDP_CNT
        ,0 as OTC_COVT_OUT_CNT
        ,0 as ITC_SUBS_CHAG
        ,0 as ITC_PURS_CHAG
        ,0 as ITC_BUYIN_CHAG
        ,0 as ITC_REDP_CHAG
        ,0 as ITC_SELL_CHAG
        ,0 as OTC_SUBS_CHAG
        ,0 as OTC_PURS_CHAG
        ,0 as OTC_CASTSL_CHAG
        ,0 as OTC_COVT_IN_CHAG
        ,0 as OTC_REDP_CHAG
        ,0 as OTC_COVT_OUT_CHAG
        ,0 as CONTD_SALE_SHAR
        ,0 as CONTD_SALE_AMT
        ,@v_date as LOAD_DT
    from (
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.T_EDW_UF2_HIS_BANKMDELIVER
        where LOAD_DT=@v_date
        union
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.GT_ODS_ZHXT_BANKMSHARE
        where load_dt=@v_date
    ) a;
    
    -- ����������ƽ�������
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_PURS_AMT = COALESCE(b.OTC_PURS_AMT,0)       -- �����깺���
        ,OTC_PURS_SHAR = coalesce(b.OTC_PURS_SHAR,0)    -- �����깺�ݶ�
        ,OTC_PURS_CNT = coalesce(b.OTC_PURS_CNT,0)      -- �����깺����
        ,OTC_REDP_AMT = coalesce(b.OTC_REDP_AMT,0)      -- ������ؽ��
        ,OTC_REDP_SHAR = coalesce(b.OTC_REDP_SHAR,0)    -- ������طݶ�
        ,OTC_REDP_CNT = coalesce(b.OTC_REDP_CNT,0)       -- ������ر���
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        SELECT CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,sum(case when business_flag=43130 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_PURS_AMT   -- �����깺���
            ,sum(case when business_flag=43130 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_PURS_SHAR  -- �����깺�ݶ�
            ,count(case when business_flag=43130 then 1 else 0 end) as OTC_PURS_CNT   -- �����깺����
            
            ,sum(case when business_flag=43142 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_REDP_AMT   -- ������ؽ��
            ,sum(case when business_flag=43142 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_REDP_SHAR  -- ������طݶ�
            ,count(case when business_flag=43142 then 1 else 0 end) as OTC_REDP_CNT   -- ������ر���
        FROM DBA.T_EDW_UF2_HIS_BANKMDELIVER a
        WHERE LOAD_DT=@v_date
        group by CLIENT_ID,PROD_CODE
    ) b on a.CUST_ID=b.CUST_ID and a.PROD_CD = b.PROD_CD
    WHERE a.OCCUR_DT=@v_date AND a.PROD_TYPE='�������';
    
    -- ����������Ʊ���
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_RETAIN_AMT = coalesce(b.OTC_RETAIN_AMT,0),   -- ���Ᵽ�н��
        OTC_RETAIN_SHAR = coalesce(b.OTC_RETAIN_SHAR,0) -- ���Ᵽ�зݶ�
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        select CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_AMT -- ���Ᵽ�н��
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_SHAR    -- ���Ᵽ�зݶ�
        from dba.GT_ODS_ZHXT_BANKMSHARE
        where LOAD_DT=@v_date
        GROUP BY CLIENT_ID, PROD_CODE
    ) b ON a.CUST_ID=b.CUST_ID and a.PROD_CD=b.PROD_CD
    where a.PROD_TYPE='�������' and OCCUR_DT=@v_date;

    -- ֤ȯ��Ƴ�ʼ��
    INSERT INTO DM.T_EVT_PROD_TRD_D_D(
        CUST_ID      -- �ͻ�����
        ,PROD_CD        -- ��Ʒ����
        ,PROD_TYPE      -- ��Ʒ����
        ,OCCUR_DT       -- ҵ������
        ,MAIN_CPTL_ACCT -- ���ʽ��˺�
        
        ,ITC_SUBS_AMT
        ,ITC_PURS_AMT
        ,ITC_REDP_AMT
        ,ITC_RETAIN_AMT
        ,ITC_BUYIN_AMT
        ,ITC_SELL_AMT
        ,OTC_SUBS_AMT
        ,OTC_PURS_AMT
        ,OTC_REDP_AMT
        ,OTC_RETAIN_AMT
        ,OTC_CASTSL_AMT
        ,OTC_COVT_IN_AMT
        ,OTC_COVT_OUT_AMT
        ,ITC_SUBS_SHAR
        ,ITC_PURS_SHAR
        ,ITC_REDP_SHAR
        ,ITC_RETAIN_SHAR
        ,ITC_BUYIN_SHAR
        ,ITC_SELL_SHAR
        ,OTC_SUBS_SHAR
        ,OTC_PURS_SHAR
        ,OTC_REDP_SHAR
        ,OTC_RETAIN_SHAR
        ,OTC_CASTSL_SHAR
        ,OTC_COVT_IN_SHAR
        ,OTC_COVT_OUT_SHAR
        ,ITC_SUBS_CNT
        ,ITC_PURS_CNT
        ,ITC_BUYIN_CNT
        ,ITC_REDP_CNT
        ,ITC_SELL_CNT
        ,OTC_SUBS_CNT
        ,OTC_PURS_CNT
        ,OTC_CASTSL_CNT
        ,OTC_COVT_IN_CNT
        ,OTC_REDP_CNT
        ,OTC_COVT_OUT_CNT
        ,ITC_SUBS_CHAG
        ,ITC_PURS_CHAG
        ,ITC_BUYIN_CHAG
        ,ITC_REDP_CHAG
        ,ITC_SELL_CHAG
        ,OTC_SUBS_CHAG
        ,OTC_PURS_CHAG
        ,OTC_CASTSL_CHAG
        ,OTC_COVT_IN_CHAG
        ,OTC_REDP_CHAG
        ,OTC_COVT_OUT_CHAG
        ,CONTD_SALE_SHAR
        ,CONTD_SALE_AMT
        ,LOAD_DT
    )
    select
        a.CLIENT_ID as CUST_ID      -- �ͻ�����
        ,a.PROD_CODE as PROD_CD        -- ��Ʒ����
        ,'֤ȯ���' as PROD_TYPE      -- ��Ʒ����
        ,@v_date as OCCUR_DT       -- ҵ������
        ,a.FUND_ACCOUNT AS MAIN_CPTL_ACCT -- ���ʽ��˺�
        
        ,0 as ITC_SUBS_AMT
        ,0 as ITC_PURS_AMT
        ,0 as ITC_REDP_AMT
        ,0 as ITC_RETAIN_AMT
        ,0 as ITC_BUYIN_AMT
        ,0 as ITC_SELL_AMT
        ,0 as OTC_SUBS_AMT
        ,0 as OTC_PURS_AMT
        ,0 as OTC_REDP_AMT
        ,0 as OTC_RETAIN_AMT
        ,0 as OTC_CASTSL_AMT
        ,0 as OTC_COVT_IN_AMT
        ,0 as OTC_COVT_OUT_AMT
        ,0 as ITC_SUBS_SHAR
        ,0 as ITC_PURS_SHAR
        ,0 as ITC_REDP_SHAR
        ,0 as ITC_RETAIN_SHAR
        ,0 as ITC_BUYIN_SHAR
        ,0 as ITC_SELL_SHAR
        ,0 as OTC_SUBS_SHAR
        ,0 as OTC_PURS_SHAR
        ,0 as OTC_REDP_SHAR
        ,0 as OTC_RETAIN_SHAR
        ,0 as OTC_CASTSL_SHAR
        ,0 as OTC_COVT_IN_SHAR
        ,0 as OTC_COVT_OUT_SHAR
        ,0 as ITC_SUBS_CNT
        ,0 as ITC_PURS_CNT
        ,0 as ITC_BUYIN_CNT
        ,0 as ITC_REDP_CNT
        ,0 as ITC_SELL_CNT
        ,0 as OTC_SUBS_CNT
        ,0 as OTC_PURS_CNT
        ,0 as OTC_CASTSL_CNT
        ,0 as OTC_COVT_IN_CNT
        ,0 as OTC_REDP_CNT
        ,0 as OTC_COVT_OUT_CNT
        ,0 as ITC_SUBS_CHAG
        ,0 as ITC_PURS_CHAG
        ,0 as ITC_BUYIN_CHAG
        ,0 as ITC_REDP_CHAG
        ,0 as ITC_SELL_CHAG
        ,0 as OTC_SUBS_CHAG
        ,0 as OTC_PURS_CHAG
        ,0 as OTC_CASTSL_CHAG
        ,0 as OTC_COVT_IN_CHAG
        ,0 as OTC_REDP_CHAG
        ,0 as OTC_COVT_OUT_CHAG
        ,0 as CONTD_SALE_SHAR
        ,0 as CONTD_SALE_AMT
        ,@v_date as LOAD_DT
    from (
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.GT_ODS_ZHXT_HIS_SECUMDELIVER
        where LOAD_DT=@v_date
        union
        select distinct CLIENT_ID, FUND_ACCOUNT, PROD_CODE
        from dba.GT_ODS_ZHXT_SECUMSHARE
        where load_dt=@v_date
    ) a;

    -- ����֤ȯ��ƽ�������
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_PURS_AMT = COALESCE(b.OTC_PURS_AMT,0)       -- �����깺���
        ,OTC_PURS_SHAR = coalesce(b.OTC_PURS_SHAR,0)    -- �����깺�ݶ�
        ,OTC_PURS_CNT = coalesce(b.OTC_PURS_CNT,0)      -- �����깺����
        ,OTC_REDP_AMT = coalesce(b.OTC_REDP_AMT,0)      -- ������ؽ��
        ,OTC_REDP_SHAR = coalesce(b.OTC_REDP_SHAR,0)    -- ������طݶ�
        ,OTC_REDP_CNT = coalesce(b.OTC_REDP_CNT,0)       -- ������ر���
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        SELECT CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,sum(case when business_flag=44130 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_PURS_AMT   -- �����깺���
            ,sum(case when business_flag=44130 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_PURS_SHAR  -- �����깺�ݶ�
            ,count(case when business_flag=44130 then 1 else 0 end) as OTC_PURS_CNT   -- �����깺����
            
            ,sum(case when business_flag=44150 then abs(a.ENTRUST_BALANCE) else 0 end) as OTC_REDP_AMT   -- ������ؽ��
            ,sum(case when business_flag=44150 then abs(a.ENTRUST_AMOUNT) else 0 end) as OTC_REDP_SHAR  -- ������طݶ�
            ,count(case when business_flag=44150 then 1 else 0 end) as OTC_REDP_CNT   -- ������ر���
        FROM DBA.GT_ODS_ZHXT_HIS_SECUMDELIVER a
        WHERE LOAD_DT=@v_date
        group by CLIENT_ID,PROD_CODE
    ) b on a.CUST_ID=b.CUST_ID and a.PROD_CD = b.PROD_CD
    WHERE a.OCCUR_DT=@v_date AND a.PROD_TYPE='֤ȯ���';


    
    -- ����֤ȯ��Ʊ���
    UPDATE DM.T_EVT_PROD_TRD_D_D
    SET OTC_RETAIN_AMT = coalesce(b.OTC_RETAIN_AMT,0),   -- ���Ᵽ�н��
        OTC_RETAIN_SHAR = coalesce(b.OTC_RETAIN_SHAR,0) -- ���Ᵽ�зݶ�
    FROM DM.T_EVT_PROD_TRD_D_D a
    LEFT JOIN (
        select CLIENT_ID as CUST_ID
            ,PROD_CODE as PROD_CD
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_AMT -- ���Ᵽ�н��
            ,SUM(CURRENT_AMOUNT) AS OTC_RETAIN_SHAR    -- ���Ᵽ�зݶ�
        from dba.GT_ODS_ZHXT_SECUMSHARE 
        where LOAD_DT=@v_date
        GROUP BY CLIENT_ID, PROD_CODE
    ) b ON a.CUST_ID=b.CUST_ID and a.PROD_CD=b.PROD_CD
    where a.PROD_TYPE='֤ȯ���' and OCCUR_DT=@v_date;


    update dm.T_EVT_PROD_TRD_D_D
    set contd_sale_shar =  otc_retain_shar - otc_subs_shar   -- �������۷ݶ�(���Ᵽ�зݶ� - �����Ϲ��ݶ�)
        ,contd_sale_amt =  otc_retain_amt - otc_subs_amt     -- �������۽��(���Ᵽ�н�� - �����Ϲ����)
    -- select *
    from dm.T_EVT_PROD_TRD_D_D a
    where a.occur_dt=@v_date
    and a.prod_cd in 
    (
        select distinct b.seccode
        from dba.T_EDW_PD_T_PROD_FINANCIAL_COLLECTION a
        left join dba.T_EDW_PD_V_PROD_DC_PRODUCT b on a.product_id=b.product_id and a.load_dt=b.load_dt
        where a.load_dt=@v_date and a.is_staging='1'
        and substr(a.establish_time,1,8)=convert(varchar,@v_date)
    );

   commit;
end
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_D_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ա����Ʒ��ʵ���ձ�
  ��д��: Ҷ���
  ��������: 2018-04-09
  ��飺Ա����Ʒ��ʵ���ձ�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	DELETE FROM DM.T_EVT_PROD_TRD_D_EMP WHERE OCCUR_DT = @V_DATE;

  	-- ������Ȩ�����ͳ�ƣ�Ա��-�ͻ�����Ч�������
  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH;


	CREATE TABLE #TMP_T_EVT_PROD_TRD_D_EMP(
	    OCCUR_DT             	numeric(8,0) 		NOT NULL,
		EMP_ID               	varchar(30) 		NOT NULL,
		MAIN_CPTL_ACCT		 	varchar(30) 		NOT NULL,
		PROD_CD              	varchar(30) 		NOT NULL,
		PROD_TYPE            	varchar(30) 		NOT NULL,
		ITC_RETAIN_AMT       	numeric(38,8) 		NULL,
		OTC_RETAIN_AMT       	numeric(38,8) 		NULL,
		ITC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		OTC_RETAIN_SHAR      	numeric(38,8) 		NULL,
		ITC_SUBS_AMT         	numeric(38,8) 		NULL,
		ITC_PURS_AMT         	numeric(38,8) 		NULL,
		ITC_BUYIN_AMT        	numeric(38,8) 		NULL,
		ITC_REDP_AMT         	numeric(38,8) 		NULL,
		ITC_SELL_AMT         	numeric(38,8) 		NULL,
		OTC_SUBS_AMT         	numeric(38,8) 		NULL,
		OTC_PURS_AMT         	numeric(38,8) 		NULL,
		OTC_CASTSL_AMT       	numeric(38,8) 		NULL,
		OTC_COVT_IN_AMT      	numeric(38,8) 		NULL,
		OTC_REDP_AMT         	numeric(38,8) 		NULL,
		OTC_COVT_OUT_AMT     	numeric(38,8) 		NULL,
		ITC_SUBS_SHAR        	numeric(38,8) 		NULL,
		ITC_PURS_SHAR        	numeric(38,8) 		NULL,
		ITC_BUYIN_SHAR       	numeric(38,8) 		NULL,
		ITC_REDP_SHAR        	numeric(38,8) 		NULL,
		ITC_SELL_SHAR        	numeric(38,8) 		NULL,
		OTC_SUBS_SHAR        	numeric(38,8) 		NULL,
		OTC_PURS_SHAR        	numeric(38,8) 		NULL,
		OTC_CASTSL_SHAR      	numeric(38,8) 		NULL,
		OTC_COVT_IN_SHAR     	numeric(38,8) 		NULL,
		OTC_REDP_SHAR        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_SHAR    	numeric(38,8) 		NULL,
		ITC_SUBS_CHAG        	numeric(38,8) 		NULL,
		ITC_PURS_CHAG        	numeric(38,8) 		NULL,
		ITC_BUYIN_CHAG       	numeric(38,8) 		NULL,
		ITC_REDP_CHAG        	numeric(38,8) 		NULL,
		ITC_SELL_CHAG        	numeric(38,8) 		NULL,
		OTC_SUBS_CHAG        	numeric(38,8) 		NULL,
		OTC_PURS_CHAG        	numeric(38,8) 		NULL,
		OTC_CASTSL_CHAG      	numeric(38,8) 		NULL,
		OTC_COVT_IN_CHAG     	numeric(38,8) 		NULL,
		OTC_REDP_CHAG        	numeric(38,8) 		NULL,
		OTC_COVT_OUT_CHAG    	numeric(38,8) 		NULL,
		CONTD_SALE_SHAR      	numeric(38,8) 		NULL,
		CONTD_SALE_AMT       	numeric(38,8) 		NULL
	);

	INSERT INTO #TMP_T_EVT_PROD_TRD_D_EMP(
		  OCCUR_DT          		--��������
		 ,EMP_ID            		--Ա������
		 ,MAIN_CPTL_ACCT			--�ʽ��˺�			
		 ,PROD_CD           		--��Ʒ����			
		 ,PROD_TYPE         		--��Ʒ����			
		 ,ITC_RETAIN_AMT    		--���ڱ��н��			
		 ,OTC_RETAIN_AMT    		--���Ᵽ�н��			
		 ,ITC_RETAIN_SHAR   		--���ڱ��зݶ�			
		 ,OTC_RETAIN_SHAR   		--���Ᵽ�зݶ�			
		 ,ITC_SUBS_AMT      		--�����Ϲ����			
		 ,ITC_PURS_AMT      		--�����깺���			
		 ,ITC_BUYIN_AMT     		--����������			
		 ,ITC_REDP_AMT      		--������ؽ��			
		 ,ITC_SELL_AMT      		--�����������			
		 ,OTC_SUBS_AMT      		--�����Ϲ����			
		 ,OTC_PURS_AMT      		--�����깺���			
		 ,OTC_CASTSL_AMT    		--���ⶨͶ���			
		 ,OTC_COVT_IN_AMT   		--����ת������			
		 ,OTC_REDP_AMT      		--������ؽ��			
		 ,OTC_COVT_OUT_AMT  		--����ת�������			
		 ,ITC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		 ,ITC_PURS_SHAR     		--�����깺�ݶ�			
		 ,ITC_BUYIN_SHAR    		--��������ݶ�			
		 ,ITC_REDP_SHAR     		--������طݶ�			
		 ,ITC_SELL_SHAR     		--���������ݶ�			
		 ,OTC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		 ,OTC_PURS_SHAR     		--�����깺�ݶ�			
		 ,OTC_CASTSL_SHAR   		--���ⶨͶ�ݶ�			
		 ,OTC_COVT_IN_SHAR  		--����ת����ݶ�			
		 ,OTC_REDP_SHAR     		--������طݶ�			
		 ,OTC_COVT_OUT_SHAR 		--����ת�����ݶ�			
		 ,ITC_SUBS_CHAG     		--�����Ϲ�������			
		 ,ITC_PURS_CHAG     		--�����깺������			
		 ,ITC_BUYIN_CHAG    		--��������������			
		 ,ITC_REDP_CHAG     		--�������������			
		 ,ITC_SELL_CHAG     		--��������������			
		 ,OTC_SUBS_CHAG     		--�����Ϲ�������			
		 ,OTC_PURS_CHAG     		--�����깺������			
		 ,OTC_CASTSL_CHAG   		--���ⶨͶ������			
		 ,OTC_COVT_IN_CHAG  		--����ת����������			
		 ,OTC_REDP_CHAG     		--�������������			
		 ,OTC_COVT_OUT_CHAG 		--����ת����������			
		 ,CONTD_SALE_SHAR   		--�������۷ݶ�			
		 ,CONTD_SALE_AMT    		--�������۽��			
	)
	SELECT 
		  T.OCCUR_DT						AS			OCCUR_DT          		--��������
		 ,T1.EMP_ID							AS 			EMP_ID					--Ա������
		 ,T.MAIN_CPTL_ACCT	  				AS 			MAIN_CPTL_ACCT			--�ʽ��˺�
		 ,T.PROD_CD 						AS  		PROD_CD 				--��Ʒ����				
		 ,T.PROD_TYPE 						AS  		PROD_TYPE 				--��Ʒ����
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_RETAIN_AMT           --���ڱ��н��
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_RETAIN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_RETAIN_AMT           --���Ᵽ�н��
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_RETAIN_SHAR          --���ڱ��зݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_RETAIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_RETAIN_SHAR          --���Ᵽ�зݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_SUBS_AMT             --�����Ϲ����
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_PURS_AMT             --�����깺���
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_BUYIN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_BUYIN_AMT            --����������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_REDP_AMT             --������ؽ��
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SELL_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_SELL_AMT             --�����������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_SUBS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_SUBS_AMT             --�����Ϲ����
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_PURS_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_PURS_AMT             --�����깺���
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_CASTSL_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_CASTSL_AMT           --���ⶨͶ���
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_COVT_IN_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_COVT_IN_AMT          --����ת������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_REDP_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_REDP_AMT             --������ؽ��
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_COVT_OUT_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_COVT_OUT_AMT         --����ת�������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_SUBS_SHAR            --�����Ϲ��ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_PURS_SHAR            --�����깺�ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0)
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_BUYIN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_BUYIN_SHAR           --��������ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_REDP_SHAR            --������طݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.ITC_SELL_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   ITC_SELL_SHAR            --���������ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_SUBS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_SUBS_SHAR            --�����Ϲ��ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_PURS_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_PURS_SHAR            --�����깺�ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_CASTSL_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       AS   OTC_CASTSL_SHAR          --���ⶨͶ�ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_COVT_IN_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_COVT_IN_SHAR         --����ת����ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		       WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		       WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		       ELSE COALESCE(T.OTC_REDP_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		       								AS   OTC_REDP_SHAR            --������طݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_COVT_OUT_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_COVT_OUT_SHAR        --����ת�����ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   AS   ITC_SUBS_CHAG            --�����Ϲ�������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_PURS_CHAG            --�����깺������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_BUYIN_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_BUYIN_CHAG           --��������������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_REDP_CHAG            --�������������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.ITC_SELL_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   ITC_SELL_CHAG            --��������������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_SUBS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_SUBS_CHAG            --�����Ϲ�������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_PURS_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_PURS_CHAG            --�����깺������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_CASTSL_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_CASTSL_CHAG          --���ⶨͶ������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_COVT_IN_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_COVT_IN_CHAG         --����ת����������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_REDP_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_REDP_CHAG            --�������������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.OTC_COVT_OUT_CHAG,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   OTC_COVT_OUT_CHAG        --����ת����������
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.CONTD_SALE_SHAR,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   CONTD_SALE_SHAR          --�������۷ݶ�
		 ,CASE WHEN T.PROD_TYPE='˽ļ����' THEN COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_7,0) 
		 	   WHEN T.PROD_TYPE='�������' THEN COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_6,0) 
		 	   WHEN T.PROD_TYPE='����ר��' THEN COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_5,0) 
		 	   ELSE COALESCE(T.CONTD_SALE_AMT,0)*COALESCE(T1.PERFM_RATIO_4,0) END   
		 	   								AS   CONTD_SALE_AMT           --�������۽��
	FROM DM.T_EVT_PROD_TRD_D_D T
	LEFT JOIN #TMP_PERF_DISTR T1
		ON T.MAIN_CPTL_ACCT = T1.MAIN_CPTL_ACCT
	WHERE T.OCCUR_DT = @V_DATE;
	
	--����ʱ��İ�Ա��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	INSERT INTO DM.T_EVT_PROD_TRD_D_EMP (
			  OCCUR_DT          		--��������
		     ,EMP_ID            		--Ա������
		     ,PROD_CD           		--��Ʒ����			
		     ,PROD_TYPE         		--��Ʒ����			
		     ,ITC_RETAIN_AMT    		--���ڱ��н��			
		     ,OTC_RETAIN_AMT    		--���Ᵽ�н��			
		     ,ITC_RETAIN_SHAR   		--���ڱ��зݶ�			
		     ,OTC_RETAIN_SHAR   		--���Ᵽ�зݶ�			
		     ,ITC_SUBS_AMT      		--�����Ϲ����			
		     ,ITC_PURS_AMT      		--�����깺���			
		     ,ITC_BUYIN_AMT     		--����������			
		     ,ITC_REDP_AMT      		--������ؽ��			
		     ,ITC_SELL_AMT      		--�����������			
		     ,OTC_SUBS_AMT      		--�����Ϲ����			
		     ,OTC_PURS_AMT      		--�����깺���			
		     ,OTC_CASTSL_AMT    		--���ⶨͶ���			
		     ,OTC_COVT_IN_AMT   		--����ת������			
		     ,OTC_REDP_AMT      		--������ؽ��			
		     ,OTC_COVT_OUT_AMT  		--����ת�������			
		     ,ITC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		     ,ITC_PURS_SHAR     		--�����깺�ݶ�			
		     ,ITC_BUYIN_SHAR    		--��������ݶ�			
		     ,ITC_REDP_SHAR     		--������طݶ�			
		     ,ITC_SELL_SHAR     		--���������ݶ�			
		     ,OTC_SUBS_SHAR     		--�����Ϲ��ݶ�			
		     ,OTC_PURS_SHAR     		--�����깺�ݶ�			
		     ,OTC_CASTSL_SHAR   		--���ⶨͶ�ݶ�			
		     ,OTC_COVT_IN_SHAR  		--����ת����ݶ�			
		     ,OTC_REDP_SHAR     		--������طݶ�			
		     ,OTC_COVT_OUT_SHAR 		--����ת�����ݶ�			
		     ,ITC_SUBS_CHAG     		--�����Ϲ�������			
		     ,ITC_PURS_CHAG     		--�����깺������			
		     ,ITC_BUYIN_CHAG    		--��������������			
		     ,ITC_REDP_CHAG     		--�������������			
		     ,ITC_SELL_CHAG     		--��������������			
		     ,OTC_SUBS_CHAG     		--�����Ϲ�������			
		     ,OTC_PURS_CHAG     		--�����깺������			
		     ,OTC_CASTSL_CHAG   		--���ⶨͶ������			
		     ,OTC_COVT_IN_CHAG  		--����ת����������			
		     ,OTC_REDP_CHAG     		--�������������			
		     ,OTC_COVT_OUT_CHAG 		--����ת����������			
		     ,CONTD_SALE_SHAR   		--�������۷ݶ�			
		     ,CONTD_SALE_AMT    		--�������۽��		
		)
		SELECT 
			 OCCUR_DT								AS    OCCUR_DT              	--��������		
			,EMP_ID									AS    EMP_ID                	--Ա������	
			,PROD_CD           		 				AS    PROD_CD					--��Ʒ����			
		    ,PROD_TYPE         						AS    PROD_TYPE					--��Ʒ����			
			,SUM(ITC_RETAIN_AMT)    				AS    ITC_RETAIN_AMT   			--���ڱ��н��		
			,SUM(OTC_RETAIN_AMT)    				AS    OTC_RETAIN_AMT   			--���Ᵽ�н��		
			,SUM(ITC_RETAIN_SHAR)   				AS    ITC_RETAIN_SHAR  			--���ڱ��зݶ�		
			,SUM(OTC_RETAIN_SHAR)  					AS    OTC_RETAIN_SHAR  			--���Ᵽ�зݶ�		
			,SUM(ITC_SUBS_AMT)      				AS    ITC_SUBS_AMT     			--�����Ϲ����		
			,SUM(ITC_PURS_AMT)      				AS    ITC_PURS_AMT     			--�����깺���		
			,SUM(ITC_BUYIN_AMT)     				AS    ITC_BUYIN_AMT    			--����������		
			,SUM(ITC_REDP_AMT)      				AS    ITC_REDP_AMT     			--������ؽ��		
			,SUM(ITC_SELL_AMT)      				AS    ITC_SELL_AMT     			--�����������		
			,SUM(OTC_SUBS_AMT)      				AS    OTC_SUBS_AMT     			--�����Ϲ����		
			,SUM(OTC_PURS_AMT)      				AS    OTC_PURS_AMT     			--�����깺���		
			,SUM(OTC_CASTSL_AMT)    				AS    OTC_CASTSL_AMT   			--���ⶨͶ���		
			,SUM(OTC_COVT_IN_AMT)   				AS    OTC_COVT_IN_AMT  			--����ת������	
			,SUM(OTC_REDP_AMT)      				AS    OTC_REDP_AMT     			--������ؽ��		
			,SUM(OTC_COVT_OUT_AMT)  				AS    OTC_COVT_OUT_AMT 			--����ת�������	
			,SUM(ITC_SUBS_SHAR)     				AS    ITC_SUBS_SHAR    			--�����Ϲ��ݶ�		
			,SUM(ITC_PURS_SHAR)     				AS    ITC_PURS_SHAR    			--�����깺�ݶ�		
			,SUM(ITC_BUYIN_SHAR)    				AS    ITC_BUYIN_SHAR   			--��������ݶ�		
			,SUM(ITC_REDP_SHAR)     				AS    ITC_REDP_SHAR    			--������طݶ�		
			,SUM(ITC_SELL_SHAR)     				AS    ITC_SELL_SHAR    			--���������ݶ�		
			,SUM(OTC_SUBS_SHAR)     				AS    OTC_SUBS_SHAR    			--�����Ϲ��ݶ�		
			,SUM(OTC_PURS_SHAR)    					AS    OTC_PURS_SHAR    			--�����깺�ݶ�		
			,SUM(OTC_CASTSL_SHAR)   				AS    OTC_CASTSL_SHAR  			--���ⶨͶ�ݶ�		
			,SUM(OTC_COVT_IN_SHAR)  				AS    OTC_COVT_IN_SHAR 			--����ת����ݶ�	
			,SUM(OTC_REDP_SHAR)     				AS    OTC_REDP_SHAR    			--������طݶ�		
			,SUM(OTC_COVT_OUT_SHAR) 				AS    OTC_COVT_OUT_SHAR			--����ת�����ݶ�	
			,SUM(ITC_SUBS_CHAG)    					AS    ITC_SUBS_CHAG    			--�����Ϲ�������	
			,SUM(ITC_PURS_CHAG)     				AS    ITC_PURS_CHAG    			--�����깺������	
			,SUM(ITC_BUYIN_CHAG)    				AS    ITC_BUYIN_CHAG   			--��������������	
			,SUM(ITC_REDP_CHAG)     				AS    ITC_REDP_CHAG    			--�������������	
			,SUM(ITC_SELL_CHAG)     				AS    ITC_SELL_CHAG    			--��������������	
			,SUM(OTC_SUBS_CHAG)     				AS    OTC_SUBS_CHAG    			--�����Ϲ�������	
			,SUM(OTC_PURS_CHAG)     				AS    OTC_PURS_CHAG    			--�����깺������	
			,SUM(OTC_CASTSL_CHAG)   				AS    OTC_CASTSL_CHAG  			--���ⶨͶ������	
			,SUM(OTC_COVT_IN_CHAG)  				AS    OTC_COVT_IN_CHAG 			--����ת����������	
			,SUM(OTC_REDP_CHAG)     				AS    OTC_REDP_CHAG    			--�������������	
			,SUM(OTC_COVT_OUT_CHAG) 				AS    OTC_COVT_OUT_CHAG			--����ת����������	
			,SUM(CONTD_SALE_SHAR)   				AS    CONTD_SALE_SHAR  			--�������۷ݶ�		
			,SUM(CONTD_SALE_AMT)    				AS    CONTD_SALE_AMT   			--�������۽��		
		FROM #TMP_T_EVT_PROD_TRD_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID,T.PROD_CD,T.PROD_TYPE;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ӫҵ����Ʒ������ʵ���±�
  ��д��: Ҷ���
  ��������: 2018-04-04
  ��飺��Ʒ����ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
 	DECLARE @V_ACCU_MDAYS INT;		-- ���ۼ�����
 	DECLARE @V_ACCU_YDAYS INT;		-- ���ۼ�����
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_EVT_PROD_TRD_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_YEAR								AS    YEAR   					--��
		,@V_MONTH 								AS    MTH 						--��
		,BRH_ID									AS    BRH_ID                	--Ӫҵ������	
		,PROD_CD								AS    PROD_CD					--��Ʒ���� 
		,PROD_TYPE 							    AS    PROD_TYPE 				--��Ʒ���
		,@V_DATE 								AS    OCCUR_DT 		 			--��������
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_MDAYS 		AS	  ITC_RETAIN_AMT_MDA  		--���ڱ��н��_���վ�
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_MDAYS  	AS 	  OTC_RETAIN_AMT_MDA  		--���Ᵽ�н��_���վ�
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  ITC_RETAIN_SHAR_MDA 		--���ڱ��зݶ�_���վ�
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  OTC_RETAIN_SHAR_MDA 		--���Ᵽ�зݶ�_���վ�  
		,SUM(ITC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_M			--�����Ϲ����_����
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_M			--�����깺���_����
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_M    		--����������_����
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_M     		--������ؽ��_����
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_M     		--�����������_����
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_M     		--�����깺���_����
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_M   		--���ⶨͶ���_����
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_M  		--����ת������_����
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_M     		--������ؽ��_����
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_M 		--����ת�������_����
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_M    		--�����Ϲ��ݶ�_����
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_M    		--�����깺�ݶ�_����
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_M   		--��������ݶ�_����
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_M    		--������طݶ�_����
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_M    		--���������ݶ�_����
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_M    		--�����Ϲ��ݶ�_����
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_M    		--�����깺�ݶ�_����
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_M 		--���ⶨͶ�ݶ�_����
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_M 		--����ת����ݶ�_����
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_M    		--������طݶ�_����
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_M		--����ת�����ݶ�_����
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_M    		--�����Ϲ�������_����
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_M    		--�����깺������_����
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_M   		--��������������_����
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_M    		--�������������_����
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_M    		--��������������_����
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_M    		--�����Ϲ�������_����
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_M    		--�����깺������_����
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_M  		--���ⶨͶ������_����
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_M 		--����ת����������_����
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_M    		--�������������_����
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_M		--����ת����������_����
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_M  		--�������۷ݶ�_����
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_M  		--�������۽��_����
	INTO #T_EVT_PROD_TRD_M_BRH_MTH
	FROM DM.T_EVT_PROD_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID,T.PROD_CD,T.PROD_TYPE;

	-- ͳ����ָ��
	SELECT 
		 @V_YEAR								AS    YEAR   					--��
		,@V_MONTH 								AS    MTH 						--��
		,BRH_ID									AS    BRH_ID                	--Ӫҵ������	
		,PROD_CD								AS    PROD_CD					--��Ʒ���� 
		,PROD_TYPE 							    AS    PROD_TYPE 				--��Ʒ���
		,@V_DATE 								AS    OCCUR_DT 		 			--��������	
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_YDAYS 		AS	  ITC_RETAIN_AMT_YDA  		--���ڱ��н��_���վ�
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_YDAYS  	AS 	  OTC_RETAIN_AMT_YDA  		--���Ᵽ�н��_���վ�
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  ITC_RETAIN_SHAR_YDA 		--���ڱ��зݶ�_���վ�
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  OTC_RETAIN_SHAR_YDA 		--���Ᵽ�зݶ�_���վ�  
		,SUM(OTC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_TY			--�����Ϲ����_����
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_TY			--�����깺���_����
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_TY    		--����������_����
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_TY     		--������ؽ��_����
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_TY     		--�����������_����
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_TY     		--�����깺���_����
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_TY   		--���ⶨͶ���_����
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_TY  		--����ת������_����
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_TY     		--������ؽ��_����
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_TY 		--����ת�������_����
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_TY    		--�����Ϲ��ݶ�_����
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_TY    		--�����깺�ݶ�_����
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_TY   		--��������ݶ�_����
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_TY    		--������طݶ�_����
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_TY    		--���������ݶ�_����
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_TY    		--�����Ϲ��ݶ�_����
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_TY    		--�����깺�ݶ�_����
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_TY		--���ⶨͶ�ݶ�_����
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_TY 		--����ת����ݶ�_����
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_TY    		--������طݶ�_����
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_TY		--����ת�����ݶ�_����
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_TY    		--�����Ϲ�������_����
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_TY    		--�����깺������_����
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_TY   		--��������������_����
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_TY    		--�������������_����
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_TY    		--��������������_����
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_TY    		--�����Ϲ�������_����
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_TY    		--�����깺������_����
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_TY  		--���ⶨͶ������_����
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_TY 		--����ת����������_����
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_TY    		--�������������_����
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_TY		--����ת����������_����
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_TY  		--�������۷ݶ�_����
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_TY  		--�������۽��_����
	INTO #T_EVT_PROD_TRD_M_BRH_YEAR
	FROM DM.T_EVT_PROD_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID,T.PROD_CD,T.PROD_TYPE;

	--����Ŀ���
	INSERT INTO DM.T_EVT_PROD_TRD_M_BRH(
		 YEAR                				--��
		,MTH                 				--��
		,BRH_ID              				--Ӫҵ������
		,PROD_CD             				--��Ʒ����
		,PROD_TYPE           				--��Ʒ����
		,OCCUR_DT            				--��������
		,ITC_RETAIN_AMT_MDA  				--���ڱ��н��_���վ�
		,OTC_RETAIN_AMT_MDA  				--���Ᵽ�н��_���վ�
		,ITC_RETAIN_SHAR_MDA 				--���ڱ��зݶ�_���վ�
		,OTC_RETAIN_SHAR_MDA 				--���Ᵽ�зݶ�_���վ�  
		,ITC_RETAIN_AMT_YDA  				--���ڱ��н��_���վ�
		,OTC_RETAIN_AMT_YDA  				--���Ᵽ�н��_���վ�
		,ITC_RETAIN_SHAR_YDA 				--���ڱ��зݶ�_���վ�
		,OTC_RETAIN_SHAR_YDA 				--���Ᵽ�зݶ�_���վ�  
		,OTC_SUBS_AMT_M      				--�����Ϲ����_����
		,ITC_PURS_AMT_M      				--�����깺���_����
		,ITC_BUYIN_AMT_M     				--����������_����
		,ITC_REDP_AMT_M      				--������ؽ��_����
		,ITC_SELL_AMT_M      				--�����������_����
		,OTC_PURS_AMT_M      				--�����깺���_����
		,OTC_CASTSL_AMT_M    				--���ⶨͶ���_����
		,OTC_COVT_IN_AMT_M   				--����ת������_����
		,OTC_REDP_AMT_M      				--������ؽ��_����
		,OTC_COVT_OUT_AMT_M  				--����ת�������_����
		,ITC_SUBS_SHAR_M     				--�����Ϲ��ݶ�_����
		,ITC_PURS_SHAR_M     				--�����깺�ݶ�_����
		,ITC_BUYIN_SHAR_M    				--��������ݶ�_����
		,ITC_REDP_SHAR_M     				--������طݶ�_����
		,ITC_SELL_SHAR_M     				--���������ݶ�_����
		,OTC_SUBS_SHAR_M     				--�����Ϲ��ݶ�_����
		,OTC_PURS_SHAR_M     				--�����깺�ݶ�_����
		,OTC_CASTSL_SHAR_M   				--���ⶨͶ�ݶ�_����
		,OTC_COVT_IN_SHAR_M  				--����ת����ݶ�_����
		,OTC_REDP_SHAR_M     				--������طݶ�_����
		,OTC_COVT_OUT_SHAR_M 				--����ת�����ݶ�_����
		,ITC_SUBS_CHAG_M     				--�����Ϲ�������_����
		,ITC_PURS_CHAG_M     				--�����깺������_����
		,ITC_BUYIN_CHAG_M    				--��������������_����
		,ITC_REDP_CHAG_M     				--�������������_����
		,ITC_SELL_CHAG_M     				--��������������_����
		,OTC_SUBS_CHAG_M     				--�����Ϲ�������_����
		,OTC_PURS_CHAG_M     				--�����깺������_����
		,OTC_CASTSL_CHAG_M   				--���ⶨͶ������_����
		,OTC_COVT_IN_CHAG_M  				--����ת����������_����
		,OTC_REDP_CHAG_M     				--�������������_����
		,OTC_COVT_OUT_CHAG_M 				--����ת����������_����
		,CONTD_SALE_SHAR_M   				--�������۷ݶ�_����
		,CONTD_SALE_AMT_M    				--�������۽��_����
		,OTC_SUBS_AMT_TY     				--�����Ϲ����_����
		,ITC_PURS_AMT_TY     				--�����깺���_����
		,ITC_BUYIN_AMT_TY    				--����������_����
		,ITC_REDP_AMT_TY     				--������ؽ��_����
		,ITC_SELL_AMT_TY     				--�����������_����
		,OTC_PURS_AMT_TY     				--�����깺���_����
		,OTC_CASTSL_AMT_TY   				--���ⶨͶ���_����
		,OTC_COVT_IN_AMT_TY  				--����ת������_����
		,OTC_REDP_AMT_TY     				--������ؽ��_����
		,OTC_COVT_OUT_AMT_TY 				--����ת�������_����
		,ITC_SUBS_SHAR_TY    				--�����Ϲ��ݶ�_����
		,ITC_PURS_SHAR_TY    				--�����깺�ݶ�_����
		,ITC_BUYIN_SHAR_TY   				--��������ݶ�_����
		,ITC_REDP_SHAR_TY    				--������طݶ�_����
		,ITC_SELL_SHAR_TY    				--���������ݶ�_����
		,OTC_SUBS_SHAR_TY    				--�����Ϲ��ݶ�_����
		,OTC_PURS_SHAR_TY    				--�����깺�ݶ�_����
		,OTC_CASTSL_SHAR_TY  				--���ⶨͶ�ݶ�_����
		,OTC_COVT_IN_SHAR_TY 				--����ת����ݶ�_����
		,OTC_REDP_SHAR_TY    				--������طݶ�_����
		,OTC_COVT_OUT_SHAR_TY				--����ת�����ݶ�_����
		,ITC_SUBS_CHAG_TY    				--�����Ϲ�������_����
		,ITC_PURS_CHAG_TY    				--�����깺������_����
		,ITC_BUYIN_CHAG_TY   				--��������������_����
		,ITC_REDP_CHAG_TY    				--�������������_����
		,ITC_SELL_CHAG_TY    				--��������������_����
		,OTC_SUBS_CHAG_TY    				--�����Ϲ�������_����
		,OTC_PURS_CHAG_TY    				--�����깺������_����
		,OTC_CASTSL_CHAG_TY  				--���ⶨͶ������_����
		,OTC_COVT_IN_CHAG_TY 				--����ת����������_����
		,OTC_REDP_CHAG_TY    				--�������������_����
		,OTC_COVT_OUT_CHAG_TY				--����ת����������_����
		,CONTD_SALE_SHAR_TY  				--�������۷ݶ�_����
		,CONTD_SALE_AMT_TY   				--�������۽��_����
	)		
	SELECT 
		 T1.YEAR                        AS 		YEAR                	   --��
		,T1.MTH                         AS 		MTH                 	   --��
		,T1.BRH_ID                      AS 		BRH_ID              	   --Ӫҵ������
		,T1.PROD_CD                     AS 		PROD_CD             	   --��Ʒ����
		,T1.PROD_TYPE                   AS 		PROD_TYPE           	   --��Ʒ����
		,T1.OCCUR_DT                    AS 		OCCUR_DT            	   --��������
		,T1.ITC_RETAIN_AMT_MDA          AS 		ITC_RETAIN_AMT_MDA  	   --���ڱ��н��_���վ�
		,T1.OTC_RETAIN_AMT_MDA          AS 		OTC_RETAIN_AMT_MDA  	   --���Ᵽ�н��_���վ�
		,T1.ITC_RETAIN_SHAR_MDA         AS 		ITC_RETAIN_SHAR_MDA 	   --���ڱ��зݶ�_���վ�
		,T1.OTC_RETAIN_SHAR_MDA         AS 		OTC_RETAIN_SHAR_MDA 	   --���Ᵽ�зݶ�_���վ�  
		,T2.ITC_RETAIN_AMT_YDA          AS 		ITC_RETAIN_AMT_YDA  	   --���ڱ��н��_���վ�
		,T2.OTC_RETAIN_AMT_YDA          AS 		OTC_RETAIN_AMT_YDA  	   --���Ᵽ�н��_���վ�
		,T2.ITC_RETAIN_SHAR_YDA         AS 		ITC_RETAIN_SHAR_YDA 	   --���ڱ��зݶ�_���վ�
		,T2.OTC_RETAIN_SHAR_YDA         AS 		OTC_RETAIN_SHAR_YDA 	   --���Ᵽ�зݶ�_���վ�  
		,T1.OTC_SUBS_AMT_M              AS 		OTC_SUBS_AMT_M      	   --�����Ϲ����_����
		,T1.ITC_PURS_AMT_M              AS 		ITC_PURS_AMT_M      	   --�����깺���_����
		,T1.ITC_BUYIN_AMT_M             AS 		ITC_BUYIN_AMT_M     	   --����������_����
		,T1.ITC_REDP_AMT_M              AS 		ITC_REDP_AMT_M      	   --������ؽ��_����
		,T1.ITC_SELL_AMT_M              AS 		ITC_SELL_AMT_M      	   --�����������_����
		,T1.OTC_PURS_AMT_M              AS 		OTC_PURS_AMT_M      	   --�����깺���_����
		,T1.OTC_CASTSL_AMT_M            AS 		OTC_CASTSL_AMT_M    	   --���ⶨͶ���_����
		,T1.OTC_COVT_IN_AMT_M           AS 		OTC_COVT_IN_AMT_M   	   --����ת������_����
		,T1.OTC_REDP_AMT_M              AS 		OTC_REDP_AMT_M      	   --������ؽ��_����
		,T1.OTC_COVT_OUT_AMT_M          AS 		OTC_COVT_OUT_AMT_M  	   --����ת�������_����
		,T1.ITC_SUBS_SHAR_M             AS 		ITC_SUBS_SHAR_M     	   --�����Ϲ��ݶ�_����
		,T1.ITC_PURS_SHAR_M             AS 		ITC_PURS_SHAR_M     	   --�����깺�ݶ�_����
		,T1.ITC_BUYIN_SHAR_M            AS 		ITC_BUYIN_SHAR_M    	   --��������ݶ�_����
		,T1.ITC_REDP_SHAR_M             AS 		ITC_REDP_SHAR_M     	   --������طݶ�_����
		,T1.ITC_SELL_SHAR_M             AS 		ITC_SELL_SHAR_M     	   --���������ݶ�_����
		,T1.OTC_SUBS_SHAR_M             AS 		OTC_SUBS_SHAR_M     	   --�����Ϲ��ݶ�_����
		,T1.OTC_PURS_SHAR_M             AS 		OTC_PURS_SHAR_M     	   --�����깺�ݶ�_����
		,T1.OTC_CASTSL_SHAR_M           AS 		OTC_CASTSL_SHAR_M   	   --���ⶨͶ�ݶ�_����
		,T1.OTC_COVT_IN_SHAR_M          AS 		OTC_COVT_IN_SHAR_M  	   --����ת����ݶ�_����
		,T1.OTC_REDP_SHAR_M             AS 		OTC_REDP_SHAR_M     	   --������طݶ�_����
		,T1.OTC_COVT_OUT_SHAR_M         AS 		OTC_COVT_OUT_SHAR_M 	   --����ת�����ݶ�_����
		,T1.ITC_SUBS_CHAG_M             AS 		ITC_SUBS_CHAG_M     	   --�����Ϲ�������_����
		,T1.ITC_PURS_CHAG_M             AS 		ITC_PURS_CHAG_M     	   --�����깺������_����
		,T1.ITC_BUYIN_CHAG_M            AS 		ITC_BUYIN_CHAG_M    	   --��������������_����
		,T1.ITC_REDP_CHAG_M             AS 		ITC_REDP_CHAG_M     	   --�������������_����
		,T1.ITC_SELL_CHAG_M             AS 		ITC_SELL_CHAG_M     	   --��������������_����
		,T1.OTC_SUBS_CHAG_M             AS 		OTC_SUBS_CHAG_M     	   --�����Ϲ�������_����
		,T1.OTC_PURS_CHAG_M             AS 		OTC_PURS_CHAG_M     	   --�����깺������_����
		,T1.OTC_CASTSL_CHAG_M           AS 		OTC_CASTSL_CHAG_M   	   --���ⶨͶ������_����
		,T1.OTC_COVT_IN_CHAG_M          AS 		OTC_COVT_IN_CHAG_M  	   --����ת����������_����
		,T1.OTC_REDP_CHAG_M             AS 		OTC_REDP_CHAG_M     	   --�������������_����
		,T1.OTC_COVT_OUT_CHAG_M         AS 		OTC_COVT_OUT_CHAG_M 	   --����ת����������_����
		,T1.CONTD_SALE_SHAR_M           AS 		CONTD_SALE_SHAR_M   	   --�������۷ݶ�_����
		,T1.CONTD_SALE_AMT_M            AS 		CONTD_SALE_AMT_M    	   --�������۽��_����
		,T2.OTC_SUBS_AMT_TY             AS 		OTC_SUBS_AMT_TY     	   --�����Ϲ����_����
		,T2.ITC_PURS_AMT_TY             AS 		ITC_PURS_AMT_TY     	   --�����깺���_����
		,T2.ITC_BUYIN_AMT_TY            AS 		ITC_BUYIN_AMT_TY    	   --����������_����
		,T2.ITC_REDP_AMT_TY             AS 		ITC_REDP_AMT_TY     	   --������ؽ��_����
		,T2.ITC_SELL_AMT_TY             AS 		ITC_SELL_AMT_TY     	   --�����������_����
		,T2.OTC_PURS_AMT_TY             AS 		OTC_PURS_AMT_TY     	   --�����깺���_����
		,T2.OTC_CASTSL_AMT_TY           AS 		OTC_CASTSL_AMT_TY   	   --���ⶨͶ���_����
		,T2.OTC_COVT_IN_AMT_TY          AS 		OTC_COVT_IN_AMT_TY  	   --����ת������_����
		,T2.OTC_REDP_AMT_TY             AS 		OTC_REDP_AMT_TY     	   --������ؽ��_����
		,T2.OTC_COVT_OUT_AMT_TY         AS 		OTC_COVT_OUT_AMT_TY 	   --����ת�������_����
		,T2.ITC_SUBS_SHAR_TY            AS 		ITC_SUBS_SHAR_TY    	   --�����Ϲ��ݶ�_����
		,T2.ITC_PURS_SHAR_TY            AS 		ITC_PURS_SHAR_TY    	   --�����깺�ݶ�_����
		,T2.ITC_BUYIN_SHAR_TY           AS 		ITC_BUYIN_SHAR_TY   	   --��������ݶ�_����
		,T2.ITC_REDP_SHAR_TY            AS 		ITC_REDP_SHAR_TY    	   --������طݶ�_����
		,T2.ITC_SELL_SHAR_TY            AS 		ITC_SELL_SHAR_TY    	   --���������ݶ�_����
		,T2.OTC_SUBS_SHAR_TY            AS 		OTC_SUBS_SHAR_TY    	   --�����Ϲ��ݶ�_����
		,T2.OTC_PURS_SHAR_TY            AS 		OTC_PURS_SHAR_TY    	   --�����깺�ݶ�_����
		,T2.OTC_CASTSL_SHAR_TY          AS 		OTC_CASTSL_SHAR_TY  	   --���ⶨͶ�ݶ�_����
		,T2.OTC_COVT_IN_SHAR_TY         AS 		OTC_COVT_IN_SHAR_TY 	   --����ת����ݶ�_����
		,T2.OTC_REDP_SHAR_TY            AS 		OTC_REDP_SHAR_TY    	   --������طݶ�_����
		,T2.OTC_COVT_OUT_SHAR_TY        AS 		OTC_COVT_OUT_SHAR_TY	   --����ת�����ݶ�_����
		,T2.ITC_SUBS_CHAG_TY            AS 		ITC_SUBS_CHAG_TY    	   --�����Ϲ�������_����
		,T2.ITC_PURS_CHAG_TY            AS 		ITC_PURS_CHAG_TY    	   --�����깺������_����
		,T2.ITC_BUYIN_CHAG_TY           AS 		ITC_BUYIN_CHAG_TY   	   --��������������_����
		,T2.ITC_REDP_CHAG_TY            AS 		ITC_REDP_CHAG_TY    	   --�������������_����
		,T2.ITC_SELL_CHAG_TY            AS 		ITC_SELL_CHAG_TY    	   --��������������_����
		,T2.OTC_SUBS_CHAG_TY            AS 		OTC_SUBS_CHAG_TY    	   --�����Ϲ�������_����
		,T2.OTC_PURS_CHAG_TY            AS 		OTC_PURS_CHAG_TY    	   --�����깺������_����
		,T2.OTC_CASTSL_CHAG_TY          AS 		OTC_CASTSL_CHAG_TY  	   --���ⶨͶ������_����
		,T2.OTC_COVT_IN_CHAG_TY         AS 		OTC_COVT_IN_CHAG_TY 	   --����ת����������_����
		,T2.OTC_REDP_CHAG_TY            AS 		OTC_REDP_CHAG_TY    	   --�������������_����
		,T2.OTC_COVT_OUT_CHAG_TY        AS 		OTC_COVT_OUT_CHAG_TY	   --����ת����������_����
		,T2.CONTD_SALE_SHAR_TY          AS 		CONTD_SALE_SHAR_TY  	   --�������۷ݶ�_����
		,T2.CONTD_SALE_AMT_TY           AS 		CONTD_SALE_AMT_TY   	   --�������۽��_����
	FROM #T_EVT_PROD_TRD_M_BRH_MTH T1,#T_EVT_PROD_TRD_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID 
		AND T1.PROD_CD = T2.PROD_CD
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  ������: ��GP�д�����Ʒ������ʵ�±�
  ��д��: DCY
  ��������: 2018-01-05
  ��飺��Ʒ������ʵ�±�
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
              20180321                 dcy                �������²�Ʒ����+4����������
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;    
    DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --��Ȼ��_�³�
    DECLARE @V_BIN_NATRE_DAY_MTHEND  INT ;    --��Ȼ��_��ĩ
    DECLARE @V_BIN_TRD_DAY_MTHBEG    INT ;    --������_�³�
    DECLARE @V_BIN_TRD_DAY_MTHEND    INT ;    --������_��ĩ
    DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --��Ȼ��_���
    DECLARE @V_BIN_TRD_DAY_YEARBGN   INT ;    --������_���
    DECLARE @V_BIN_NATRE_DAYS_MTH    INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_MTH      INT ;    --��������_��
    DECLARE @V_BIN_NATRE_DAYS_YEAR   INT ;    --��Ȼ����_��
    DECLARE @V_BIN_TRD_DAYS_YEAR     INT ;    --��������_��


    ----��������
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
    SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_NATRE_DAY_MTHEND  =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH);
    SET @V_BIN_TRD_DAY_MTHBEG    =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_TRD_DAY_MTHEND    =(SELECT MAX(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR  );
    SET @V_BIN_TRD_DAY_YEARBGN   =(SELECT MIN(DT) 	FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_MTH    =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE );
    SET @V_BIN_TRD_DAYS_MTH      =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH AND DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
    SET @V_BIN_NATRE_DAYS_YEAR   =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE);
    SET @V_BIN_TRD_DAYS_YEAR     =(SELECT COUNT(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_BIN_YEAR AND  DT<=@V_BIN_DATE AND IF_TRD_DAY_FLAG=1);
	
--PART0 ɾ����������
  DELETE FROM DM.T_EVT_PROD_TRD_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;

	insert into DM.T_EVT_PROD_TRD_M_D 
	(
	CUST_ID
	,PROD_CD
	,PROD_TYPE
	,YEAR
	,MTH
	,OCCUR_DT
	,NATRE_DAYS_MTH
	,NATRE_DAYS_YEAR
	,YEAR_MTH
	,YEAR_MTH_CUST_ID
	,YEAR_MTH_PROD_CD
	,YEAR_MTH_CUST_ID_PROD_CD
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
	t1.CUST_ID as �ͻ�����
	,t1.PROD_CD as ��Ʒ����
	,t1.PROD_TYPE as ��Ʒ����
	,t_rq.��
	,t_rq.��
	,@V_BIN_DATE AS OCCUR_DT
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��		
	,t_rq.��||t_rq.�� as ����
	,t_rq.��||t_rq.��||t1.CUST_ID as ���¿ͻ�����
	,t_rq.��||t_rq.��||t1.PROD_CD as ���²�Ʒ����
	,t_rq.��||t_rq.��||t1.CUST_ID||t1.PROD_CD as ���¿ͻ������Ʒ����
	
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.ITC_RETAIN_AMT,0) else 0 end) as ���ڱ��н��_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OTC_RETAIN_AMT,0) else 0 end) as ���Ᵽ�н��_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.ITC_RETAIN_SHAR,0) else 0 end) as ���ڱ��зݶ�_��ĩ
	,sum(case when t_rq.����=t_rq.��Ȼ��_��ĩ then COALESCE(t1.OTC_RETAIN_SHAR,0) else 0 end) as ���Ᵽ�зݶ�_��ĩ

	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.ITC_RETAIN_AMT,0) else 0 end)/t_rq.��Ȼ����_�� as ���ڱ��н��_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OTC_RETAIN_AMT,0) else 0 end)/t_rq.��Ȼ����_�� as ���Ᵽ�н��_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.ITC_RETAIN_SHAR,0) else 0 end)/t_rq.��Ȼ����_�� as ���ڱ��зݶ�_���վ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� then COALESCE(t1.OTC_RETAIN_SHAR,0) else 0 end)/t_rq.��Ȼ����_�� as ���Ᵽ�зݶ�_���վ�

	,sum(COALESCE(t1.ITC_RETAIN_AMT,0))/t_rq.��Ȼ����_�� as ���ڱ��н��_���վ�
	,sum(COALESCE(t1.OTC_RETAIN_AMT,0))/t_rq.��Ȼ����_�� as ���Ᵽ�н��_���վ�
	,sum(COALESCE(t1.ITC_RETAIN_SHAR,0))/t_rq.��Ȼ����_�� as ���ڱ��зݶ�_���վ�
	,sum(COALESCE(t1.OTC_RETAIN_SHAR,0))/t_rq.��Ȼ����_�� as ���Ᵽ�зݶ�_���վ�

	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SUBS_AMT,0) else 0 end) as �����Ϲ����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_PURS_AMT,0) else 0 end) as �����깺���_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_BUYIN_AMT,0) else 0 end) as ����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_REDP_AMT,0) else 0 end) as ������ؽ��_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SELL_AMT,0) else 0 end) as �����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_SUBS_AMT,0) else 0 end) as �����Ϲ����_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_PURS_AMT,0) else 0 end) as �����깺���_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_CASTSL_AMT,0) else 0 end) as ���ⶨͶ���_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_IN_AMT,0) else 0 end) as ����ת������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_REDP_AMT,0) else 0 end) as ������ؽ��_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_OUT_AMT,0) else 0 end) as ����ת�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SUBS_SHAR,0) else 0 end) as �����Ϲ��ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_PURS_SHAR,0) else 0 end) as �����깺�ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_BUYIN_SHAR,0) else 0 end) as ��������ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_REDP_SHAR,0) else 0 end) as ������طݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SELL_SHAR,0) else 0 end) as ���������ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_SUBS_SHAR,0) else 0 end) as �����Ϲ��ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_PURS_SHAR,0) else 0 end) as �����깺�ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_CASTSL_SHAR,0) else 0 end) as ���ⶨͶ�ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_IN_SHAR,0) else 0 end) as ����ת����ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_REDP_SHAR,0) else 0 end) as ������طݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_OUT_SHAR,0) else 0 end) as ����ת�����ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SUBS_CHAG,0) else 0 end) as �����Ϲ�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_PURS_CHAG,0) else 0 end) as �����깺������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_BUYIN_CHAG,0) else 0 end) as ��������������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_REDP_CHAG,0) else 0 end) as �������������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SELL_CHAG,0) else 0 end) as ��������������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_SUBS_CHAG,0) else 0 end) as �����Ϲ�������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_PURS_CHAG,0) else 0 end) as �����깺������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_CASTSL_CHAG,0) else 0 end) as ���ⶨͶ������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_IN_CHAG,0) else 0 end) as ����ת����������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_REDP_CHAG,0) else 0 end) as �������������_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_OUT_CHAG,0) else 0 end) as ����ת����������_���ۼ�

	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SUBS_AMT,0) else 0 end) as �����Ϲ����_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_PURS_AMT,0) else 0 end) as �����깺���_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_BUYIN_AMT,0) else 0 end) as ����������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_REDP_AMT,0) else 0 end) as ������ؽ��_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SELL_AMT,0) else 0 end) as �����������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_SUBS_AMT,0) else 0 end) as �����Ϲ����_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_PURS_AMT,0) else 0 end) as �����깺���_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_CASTSL_AMT,0) else 0 end) as ���ⶨͶ���_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_IN_AMT,0) else 0 end) as ����ת������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_REDP_AMT,0) else 0 end) as ������ؽ��_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_OUT_AMT,0) else 0 end) as ����ת�������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SUBS_SHAR,0) else 0 end) as �����Ϲ��ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_PURS_SHAR,0) else 0 end) as �����깺�ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_BUYIN_SHAR,0) else 0 end) as ��������ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_REDP_SHAR,0) else 0 end) as ������طݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SELL_SHAR,0) else 0 end) as ���������ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_SUBS_SHAR,0) else 0 end) as �����Ϲ��ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_PURS_SHAR,0) else 0 end) as �����깺�ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_CASTSL_SHAR,0) else 0 end) as ���ⶨͶ�ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_IN_SHAR,0) else 0 end) as ����ת����ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_REDP_SHAR,0) else 0 end) as ������طݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_OUT_SHAR,0) else 0 end) as ����ת�����ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SUBS_CHAG,0) else 0 end) as �����Ϲ�������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_PURS_CHAG,0) else 0 end) as �����깺������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_BUYIN_CHAG,0) else 0 end) as ��������������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_REDP_CHAG,0) else 0 end) as �������������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.ITC_SELL_CHAG,0) else 0 end) as ��������������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_SUBS_CHAG,0) else 0 end) as �����Ϲ�������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_PURS_CHAG,0) else 0 end) as �����깺������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_CASTSL_CHAG,0) else 0 end) as ���ⶨͶ������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_IN_CHAG,0) else 0 end) as ����ת����������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_REDP_CHAG,0) else 0 end) as �������������_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.OTC_COVT_OUT_CHAG,0) else 0 end) as ����ת����������_���ۼ�
	
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.CONTD_SALE_SHAR,0) else 0 end) as �������۷ݶ�_���ۼ�
	,sum(case when t_rq.����>=t_rq.��Ȼ��_�³� and t_rq.�Ƿ�����=1 then COALESCE(t1.CONTD_SALE_AMT,0) else 0 end) as �������۽��_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.CONTD_SALE_SHAR,0) else 0 end) as �������۷ݶ�_���ۼ�
	,sum(case when t_rq.�Ƿ�����=1 then COALESCE(t1.CONTD_SALE_AMT,0) else 0 end) as �������۽��_���ۼ�
	
	,@V_BIN_DATE
from
(
	select
		@V_BIN_YEAR as ��
		,@V_BIN_MTH as ��
		,t1.DT      as ����
		,t1.TRD_DT  as ��������
		,t1.if_trd_day_flag         as �Ƿ�����
		,@V_BIN_NATRE_DAY_MTHBEG    as ��Ȼ��_�³�
		,@V_BIN_NATRE_DAY_MTHEND    as ��Ȼ��_��ĩ
		,@V_BIN_TRD_DAY_MTHBEG      as ������_�³�
		,@V_BIN_TRD_DAY_MTHEND      as ������_��ĩ
		,@V_BIN_NATRE_DAY_YEARBGN   as ��Ȼ��_���
		,@V_BIN_TRD_DAY_YEARBGN     as ������_���
		,@V_BIN_NATRE_DAYS_MTH      as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_MTH        as ��������_��
		,@V_BIN_NATRE_DAYS_YEAR     as ��Ȼ����_��
		,@V_BIN_TRD_DAYS_YEAR       as ��������_��
	from DM.T_PUB_DATE t1 
	where t1.YEAR=@V_BIN_YEAR
	  AND T1.DT<=@V_BIN_DATE 
) t_rq
--��ֵ���������ڼ�������
left join DM.T_EVT_PROD_TRD_D_D t1 on t_rq.��������=t1.OCCUR_DT
group by
	t_rq.��
	,t_rq.��
	,t_rq.��Ȼ����_��
	,t_rq.��Ȼ����_��		
	,t1.CUST_ID
	,t1.PROD_CD
	,t1.PROD_TYPE
;

END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_M_D TO xydc
GO
CREATE PROCEDURE dm.P_EVT_PROD_TRD_M_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ա����Ʒ������ʵ���±�
  ��д��: Ҷ���
  ��������: 2018-04-04
  ��飺��Ʒ����ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
 	DECLARE @V_ACCU_MDAYS INT;		-- ���ۼ�����
 	DECLARE @V_ACCU_YDAYS INT;		-- ���ۼ�����
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 
    SET @V_ACCU_MDAYS=(SELECT TM_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);
    SET @V_ACCU_YDAYS=(SELECT TY_SNB_NORM_DAY FROM DM.T_PUB_DATE WHERE DT=@V_DATE);

	DELETE FROM DM.T_EVT_PROD_TRD_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_YEAR								AS    YEAR   					--��
		,@V_MONTH 								AS    MTH 						--��
		,EMP_ID									AS    EMP_ID                	--Ա������	
		,PROD_CD								AS    PROD_CD					--��Ʒ���� 
		,PROD_TYPE 							    AS    PROD_TYPE 				--��Ʒ���
		,@V_DATE 								AS    OCCUR_DT 		 			--��������
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_MDAYS 		AS	  ITC_RETAIN_AMT_MDA  		--���ڱ��н��_���վ�
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_MDAYS  	AS 	  OTC_RETAIN_AMT_MDA  		--���Ᵽ�н��_���վ�
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  ITC_RETAIN_SHAR_MDA 		--���ڱ��зݶ�_���վ�
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_MDAYS 	AS 	  OTC_RETAIN_SHAR_MDA 		--���Ᵽ�зݶ�_���վ�  
		,SUM(ITC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_M			--�����Ϲ����_����
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_M			--�����깺���_����
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_M    		--����������_����
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_M     		--������ؽ��_����
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_M     		--�����������_����
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_M     		--�����깺���_����
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_M   		--���ⶨͶ���_����
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_M  		--����ת������_����
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_M     		--������ؽ��_����
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_M 		--����ת�������_����
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_M    		--�����Ϲ��ݶ�_����
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_M    		--�����깺�ݶ�_����
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_M   		--��������ݶ�_����
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_M    		--������طݶ�_����
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_M    		--���������ݶ�_����
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_M    		--�����Ϲ��ݶ�_����
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_M    		--�����깺�ݶ�_����
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_M 		--���ⶨͶ�ݶ�_����
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_M 		--����ת����ݶ�_����
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_M    		--������طݶ�_����
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_M		--����ת�����ݶ�_����
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_M    		--�����Ϲ�������_����
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_M    		--�����깺������_����
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_M   		--��������������_����
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_M    		--�������������_����
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_M    		--��������������_����
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_M    		--�����Ϲ�������_����
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_M    		--�����깺������_����
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_M  		--���ⶨͶ������_����
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_M 		--����ת����������_����
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_M    		--�������������_����
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_M		--����ת����������_����
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_M  		--�������۷ݶ�_����
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_M  		--�������۽��_����
	INTO #T_EVT_PROD_TRD_D_EMP_MTH
	FROM DM.T_EVT_PROD_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID,T.PROD_CD,T.PROD_TYPE;

	-- ͳ����ָ��
	SELECT 
		 @V_YEAR								AS    YEAR   					--��
		,@V_MONTH 								AS    MTH 						--��
		,EMP_ID									AS    EMP_ID                	--Ա������
		,PROD_CD								AS    PROD_CD					--��Ʒ���� 
		,PROD_TYPE 							    AS    PROD_TYPE 				--��Ʒ���
		,@V_DATE 								AS    OCCUR_DT 		 			--��������	
		,SUM(ITC_RETAIN_AMT)/@V_ACCU_YDAYS 		AS	  ITC_RETAIN_AMT_YDA  		--���ڱ��н��_���վ�
		,SUM(OTC_RETAIN_AMT)/@V_ACCU_YDAYS  	AS 	  OTC_RETAIN_AMT_YDA  		--���Ᵽ�н��_���վ�
		,SUM(ITC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  ITC_RETAIN_SHAR_YDA 		--���ڱ��зݶ�_���վ�
		,SUM(OTC_RETAIN_SHAR)/@V_ACCU_YDAYS 	AS 	  OTC_RETAIN_SHAR_YDA 		--���Ᵽ�зݶ�_���վ�  
		,SUM(OTC_SUBS_AMT)      				AS	  OTC_SUBS_AMT_TY			--�����Ϲ����_����
		,SUM(ITC_PURS_AMT)      				AS	  ITC_PURS_AMT_TY			--�����깺���_����
		,SUM(ITC_BUYIN_AMT)     				AS	  ITC_BUYIN_AMT_TY    		--����������_����
		,SUM(ITC_REDP_AMT)      				AS	  ITC_REDP_AMT_TY     		--������ؽ��_����
		,SUM(ITC_SELL_AMT)      				AS	  ITC_SELL_AMT_TY     		--�����������_����
		,SUM(OTC_PURS_AMT)      				AS	  OTC_PURS_AMT_TY     		--�����깺���_����
		,SUM(OTC_CASTSL_AMT)    				AS	  OTC_CASTSL_AMT_TY   		--���ⶨͶ���_����
		,SUM(OTC_COVT_IN_AMT)   				AS	  OTC_COVT_IN_AMT_TY  		--����ת������_����
		,SUM(OTC_REDP_AMT)      				AS	  OTC_REDP_AMT_TY     		--������ؽ��_����
		,SUM(OTC_COVT_OUT_AMT)  				AS	  OTC_COVT_OUT_AMT_TY 		--����ת�������_����
		,SUM(ITC_SUBS_SHAR)     				AS	  ITC_SUBS_SHAR_TY    		--�����Ϲ��ݶ�_����
		,SUM(ITC_PURS_SHAR)     				AS	  ITC_PURS_SHAR_TY    		--�����깺�ݶ�_����
		,SUM(ITC_BUYIN_SHAR)    				AS	  ITC_BUYIN_SHAR_TY   		--��������ݶ�_����
		,SUM(ITC_REDP_SHAR)     				AS	  ITC_REDP_SHAR_TY    		--������طݶ�_����
		,SUM(ITC_SELL_SHAR)     				AS	  ITC_SELL_SHAR_TY    		--���������ݶ�_����
		,SUM(OTC_SUBS_SHAR)     				AS	  OTC_SUBS_SHAR_TY    		--�����Ϲ��ݶ�_����
		,SUM(OTC_PURS_SHAR)     				AS	  OTC_PURS_SHAR_TY    		--�����깺�ݶ�_����
		,SUM(OTC_CASTSL_SHAR)   				AS	  OTC_CASTSL_SHAR_TY		--���ⶨͶ�ݶ�_����
		,SUM(OTC_COVT_IN_SHAR)  				AS	  OTC_COVT_IN_SHAR_TY 		--����ת����ݶ�_����
		,SUM(OTC_REDP_SHAR)     				AS	  OTC_REDP_SHAR_TY    		--������طݶ�_����
		,SUM(OTC_COVT_OUT_SHAR) 				AS	  OTC_COVT_OUT_SHAR_TY		--����ת�����ݶ�_����
		,SUM(ITC_SUBS_CHAG)     				AS	  ITC_SUBS_CHAG_TY    		--�����Ϲ�������_����
		,SUM(ITC_PURS_CHAG)     				AS	  ITC_PURS_CHAG_TY    		--�����깺������_����
		,SUM(ITC_BUYIN_CHAG)    				AS	  ITC_BUYIN_CHAG_TY   		--��������������_����
		,SUM(ITC_REDP_CHAG)     				AS	  ITC_REDP_CHAG_TY    		--�������������_����
		,SUM(ITC_SELL_CHAG)     				AS	  ITC_SELL_CHAG_TY    		--��������������_����
		,SUM(OTC_SUBS_CHAG)     				AS	  OTC_SUBS_CHAG_TY    		--�����Ϲ�������_����
		,SUM(OTC_PURS_CHAG)     				AS	  OTC_PURS_CHAG_TY    		--�����깺������_����
		,SUM(OTC_CASTSL_CHAG)   				AS	  OTC_CASTSL_CHAG_TY  		--���ⶨͶ������_����
		,SUM(OTC_COVT_IN_CHAG)  				AS	  OTC_COVT_IN_CHAG_TY 		--����ת����������_����
		,SUM(OTC_REDP_CHAG)    					AS	  OTC_REDP_CHAG_TY    		--�������������_����
		,SUM(OTC_COVT_OUT_CHAG) 				AS	  OTC_COVT_OUT_CHAG_TY		--����ת����������_����
		,SUM(CONTD_SALE_SHAR)   				AS	  CONTD_SALE_SHAR_TY  		--�������۷ݶ�_����
		,SUM(CONTD_SALE_AMT)    				AS	  CONTD_SALE_AMT_TY  		--�������۽��_����
	INTO #T_EVT_PROD_TRD_D_EMP_YEAR
	FROM DM.T_EVT_PROD_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID,T.PROD_CD,T.PROD_TYPE;

	--����Ŀ���
	INSERT INTO DM.T_EVT_PROD_TRD_M_EMP(
		 YEAR                				--��
		,MTH                 				--��
		,EMP_ID              				--Ա������
		,PROD_CD             				--��Ʒ����
		,PROD_TYPE           				--��Ʒ����
		,OCCUR_DT            				--��������
		,ITC_RETAIN_AMT_MDA  				--���ڱ��н��_���վ�
		,OTC_RETAIN_AMT_MDA  				--���Ᵽ�н��_���վ�
		,ITC_RETAIN_SHAR_MDA 				--���ڱ��зݶ�_���վ�
		,OTC_RETAIN_SHAR_MDA 				--���Ᵽ�зݶ�_���վ�  
		,ITC_RETAIN_AMT_YDA  				--���ڱ��н��_���վ�
		,OTC_RETAIN_AMT_YDA  				--���Ᵽ�н��_���վ�
		,ITC_RETAIN_SHAR_YDA 				--���ڱ��зݶ�_���վ�
		,OTC_RETAIN_SHAR_YDA 				--���Ᵽ�зݶ�_���վ�  
		,OTC_SUBS_AMT_M      				--�����Ϲ����_����
		,ITC_PURS_AMT_M      				--�����깺���_����
		,ITC_BUYIN_AMT_M     				--����������_����
		,ITC_REDP_AMT_M      				--������ؽ��_����
		,ITC_SELL_AMT_M      				--�����������_����
		,OTC_PURS_AMT_M      				--�����깺���_����
		,OTC_CASTSL_AMT_M    				--���ⶨͶ���_����
		,OTC_COVT_IN_AMT_M   				--����ת������_����
		,OTC_REDP_AMT_M      				--������ؽ��_����
		,OTC_COVT_OUT_AMT_M  				--����ת�������_����
		,ITC_SUBS_SHAR_M     				--�����Ϲ��ݶ�_����
		,ITC_PURS_SHAR_M     				--�����깺�ݶ�_����
		,ITC_BUYIN_SHAR_M    				--��������ݶ�_����
		,ITC_REDP_SHAR_M     				--������طݶ�_����
		,ITC_SELL_SHAR_M     				--���������ݶ�_����
		,OTC_SUBS_SHAR_M     				--�����Ϲ��ݶ�_����
		,OTC_PURS_SHAR_M     				--�����깺�ݶ�_����
		,OTC_CASTSL_SHAR_M   				--���ⶨͶ�ݶ�_����
		,OTC_COVT_IN_SHAR_M  				--����ת����ݶ�_����
		,OTC_REDP_SHAR_M     				--������طݶ�_����
		,OTC_COVT_OUT_SHAR_M 				--����ת�����ݶ�_����
		,ITC_SUBS_CHAG_M     				--�����Ϲ�������_����
		,ITC_PURS_CHAG_M     				--�����깺������_����
		,ITC_BUYIN_CHAG_M    				--��������������_����
		,ITC_REDP_CHAG_M     				--�������������_����
		,ITC_SELL_CHAG_M     				--��������������_����
		,OTC_SUBS_CHAG_M     				--�����Ϲ�������_����
		,OTC_PURS_CHAG_M     				--�����깺������_����
		,OTC_CASTSL_CHAG_M   				--���ⶨͶ������_����
		,OTC_COVT_IN_CHAG_M  				--����ת����������_����
		,OTC_REDP_CHAG_M     				--�������������_����
		,OTC_COVT_OUT_CHAG_M 				--����ת����������_����
		,CONTD_SALE_SHAR_M   				--�������۷ݶ�_����
		,CONTD_SALE_AMT_M    				--�������۽��_����
		,OTC_SUBS_AMT_TY     				--�����Ϲ����_����
		,ITC_PURS_AMT_TY     				--�����깺���_����
		,ITC_BUYIN_AMT_TY    				--����������_����
		,ITC_REDP_AMT_TY     				--������ؽ��_����
		,ITC_SELL_AMT_TY     				--�����������_����
		,OTC_PURS_AMT_TY     				--�����깺���_����
		,OTC_CASTSL_AMT_TY   				--���ⶨͶ���_����
		,OTC_COVT_IN_AMT_TY  				--����ת������_����
		,OTC_REDP_AMT_TY     				--������ؽ��_����
		,OTC_COVT_OUT_AMT_TY 				--����ת�������_����
		,ITC_SUBS_SHAR_TY    				--�����Ϲ��ݶ�_����
		,ITC_PURS_SHAR_TY    				--�����깺�ݶ�_����
		,ITC_BUYIN_SHAR_TY   				--��������ݶ�_����
		,ITC_REDP_SHAR_TY    				--������طݶ�_����
		,ITC_SELL_SHAR_TY    				--���������ݶ�_����
		,OTC_SUBS_SHAR_TY    				--�����Ϲ��ݶ�_����
		,OTC_PURS_SHAR_TY    				--�����깺�ݶ�_����
		,OTC_CASTSL_SHAR_TY  				--���ⶨͶ�ݶ�_����
		,OTC_COVT_IN_SHAR_TY 				--����ת����ݶ�_����
		,OTC_REDP_SHAR_TY    				--������طݶ�_����
		,OTC_COVT_OUT_SHAR_TY				--����ת�����ݶ�_����
		,ITC_SUBS_CHAG_TY    				--�����Ϲ�������_����
		,ITC_PURS_CHAG_TY    				--�����깺������_����
		,ITC_BUYIN_CHAG_TY   				--��������������_����
		,ITC_REDP_CHAG_TY    				--�������������_����
		,ITC_SELL_CHAG_TY    				--��������������_����
		,OTC_SUBS_CHAG_TY    				--�����Ϲ�������_����
		,OTC_PURS_CHAG_TY    				--�����깺������_����
		,OTC_CASTSL_CHAG_TY  				--���ⶨͶ������_����
		,OTC_COVT_IN_CHAG_TY 				--����ת����������_����
		,OTC_REDP_CHAG_TY    				--�������������_����
		,OTC_COVT_OUT_CHAG_TY				--����ת����������_����
		,CONTD_SALE_SHAR_TY  				--�������۷ݶ�_����
		,CONTD_SALE_AMT_TY   				--�������۽��_����
	)		
	SELECT 
		 T1.YEAR                        AS 		YEAR                	   --��
		,T1.MTH                         AS 		MTH                 	   --��
		,T1.EMP_ID                      AS 		EMP_ID              	   --Ա������
		,T1.PROD_CD                     AS 		PROD_CD             	   --��Ʒ����
		,T1.PROD_TYPE                   AS 		PROD_TYPE           	   --��Ʒ����
		,T1.OCCUR_DT                    AS 		OCCUR_DT            	   --��������
		,T1.ITC_RETAIN_AMT_MDA          AS 		ITC_RETAIN_AMT_MDA  	   --���ڱ��н��_���վ�
		,T1.OTC_RETAIN_AMT_MDA          AS 		OTC_RETAIN_AMT_MDA  	   --���Ᵽ�н��_���վ�
		,T1.ITC_RETAIN_SHAR_MDA         AS 		ITC_RETAIN_SHAR_MDA 	   --���ڱ��зݶ�_���վ�
		,T1.OTC_RETAIN_SHAR_MDA         AS 		OTC_RETAIN_SHAR_MDA 	   --���Ᵽ�зݶ�_���վ�  
		,T2.ITC_RETAIN_AMT_YDA          AS 		ITC_RETAIN_AMT_YDA  	   --���ڱ��н��_���վ�
		,T2.OTC_RETAIN_AMT_YDA          AS 		OTC_RETAIN_AMT_YDA  	   --���Ᵽ�н��_���վ�
		,T2.ITC_RETAIN_SHAR_YDA         AS 		ITC_RETAIN_SHAR_YDA 	   --���ڱ��зݶ�_���վ�
		,T2.OTC_RETAIN_SHAR_YDA         AS 		OTC_RETAIN_SHAR_YDA 	   --���Ᵽ�зݶ�_���վ�  
		,T1.OTC_SUBS_AMT_M              AS 		OTC_SUBS_AMT_M      	   --�����Ϲ����_����
		,T1.ITC_PURS_AMT_M              AS 		ITC_PURS_AMT_M      	   --�����깺���_����
		,T1.ITC_BUYIN_AMT_M             AS 		ITC_BUYIN_AMT_M     	   --����������_����
		,T1.ITC_REDP_AMT_M              AS 		ITC_REDP_AMT_M      	   --������ؽ��_����
		,T1.ITC_SELL_AMT_M              AS 		ITC_SELL_AMT_M      	   --�����������_����
		,T1.OTC_PURS_AMT_M              AS 		OTC_PURS_AMT_M      	   --�����깺���_����
		,T1.OTC_CASTSL_AMT_M            AS 		OTC_CASTSL_AMT_M    	   --���ⶨͶ���_����
		,T1.OTC_COVT_IN_AMT_M           AS 		OTC_COVT_IN_AMT_M   	   --����ת������_����
		,T1.OTC_REDP_AMT_M              AS 		OTC_REDP_AMT_M      	   --������ؽ��_����
		,T1.OTC_COVT_OUT_AMT_M          AS 		OTC_COVT_OUT_AMT_M  	   --����ת�������_����
		,T1.ITC_SUBS_SHAR_M             AS 		ITC_SUBS_SHAR_M     	   --�����Ϲ��ݶ�_����
		,T1.ITC_PURS_SHAR_M             AS 		ITC_PURS_SHAR_M     	   --�����깺�ݶ�_����
		,T1.ITC_BUYIN_SHAR_M            AS 		ITC_BUYIN_SHAR_M    	   --��������ݶ�_����
		,T1.ITC_REDP_SHAR_M             AS 		ITC_REDP_SHAR_M     	   --������طݶ�_����
		,T1.ITC_SELL_SHAR_M             AS 		ITC_SELL_SHAR_M     	   --���������ݶ�_����
		,T1.OTC_SUBS_SHAR_M             AS 		OTC_SUBS_SHAR_M     	   --�����Ϲ��ݶ�_����
		,T1.OTC_PURS_SHAR_M             AS 		OTC_PURS_SHAR_M     	   --�����깺�ݶ�_����
		,T1.OTC_CASTSL_SHAR_M           AS 		OTC_CASTSL_SHAR_M   	   --���ⶨͶ�ݶ�_����
		,T1.OTC_COVT_IN_SHAR_M          AS 		OTC_COVT_IN_SHAR_M  	   --����ת����ݶ�_����
		,T1.OTC_REDP_SHAR_M             AS 		OTC_REDP_SHAR_M     	   --������طݶ�_����
		,T1.OTC_COVT_OUT_SHAR_M         AS 		OTC_COVT_OUT_SHAR_M 	   --����ת�����ݶ�_����
		,T1.ITC_SUBS_CHAG_M             AS 		ITC_SUBS_CHAG_M     	   --�����Ϲ�������_����
		,T1.ITC_PURS_CHAG_M             AS 		ITC_PURS_CHAG_M     	   --�����깺������_����
		,T1.ITC_BUYIN_CHAG_M            AS 		ITC_BUYIN_CHAG_M    	   --��������������_����
		,T1.ITC_REDP_CHAG_M             AS 		ITC_REDP_CHAG_M     	   --�������������_����
		,T1.ITC_SELL_CHAG_M             AS 		ITC_SELL_CHAG_M     	   --��������������_����
		,T1.OTC_SUBS_CHAG_M             AS 		OTC_SUBS_CHAG_M     	   --�����Ϲ�������_����
		,T1.OTC_PURS_CHAG_M             AS 		OTC_PURS_CHAG_M     	   --�����깺������_����
		,T1.OTC_CASTSL_CHAG_M           AS 		OTC_CASTSL_CHAG_M   	   --���ⶨͶ������_����
		,T1.OTC_COVT_IN_CHAG_M          AS 		OTC_COVT_IN_CHAG_M  	   --����ת����������_����
		,T1.OTC_REDP_CHAG_M             AS 		OTC_REDP_CHAG_M     	   --�������������_����
		,T1.OTC_COVT_OUT_CHAG_M         AS 		OTC_COVT_OUT_CHAG_M 	   --����ת����������_����
		,T1.CONTD_SALE_SHAR_M           AS 		CONTD_SALE_SHAR_M   	   --�������۷ݶ�_����
		,T1.CONTD_SALE_AMT_M            AS 		CONTD_SALE_AMT_M    	   --�������۽��_����
		,T2.OTC_SUBS_AMT_TY             AS 		OTC_SUBS_AMT_TY     	   --�����Ϲ����_����
		,T2.ITC_PURS_AMT_TY             AS 		ITC_PURS_AMT_TY     	   --�����깺���_����
		,T2.ITC_BUYIN_AMT_TY            AS 		ITC_BUYIN_AMT_TY    	   --����������_����
		,T2.ITC_REDP_AMT_TY             AS 		ITC_REDP_AMT_TY     	   --������ؽ��_����
		,T2.ITC_SELL_AMT_TY             AS 		ITC_SELL_AMT_TY     	   --�����������_����
		,T2.OTC_PURS_AMT_TY             AS 		OTC_PURS_AMT_TY     	   --�����깺���_����
		,T2.OTC_CASTSL_AMT_TY           AS 		OTC_CASTSL_AMT_TY   	   --���ⶨͶ���_����
		,T2.OTC_COVT_IN_AMT_TY          AS 		OTC_COVT_IN_AMT_TY  	   --����ת������_����
		,T2.OTC_REDP_AMT_TY             AS 		OTC_REDP_AMT_TY     	   --������ؽ��_����
		,T2.OTC_COVT_OUT_AMT_TY         AS 		OTC_COVT_OUT_AMT_TY 	   --����ת�������_����
		,T2.ITC_SUBS_SHAR_TY            AS 		ITC_SUBS_SHAR_TY    	   --�����Ϲ��ݶ�_����
		,T2.ITC_PURS_SHAR_TY            AS 		ITC_PURS_SHAR_TY    	   --�����깺�ݶ�_����
		,T2.ITC_BUYIN_SHAR_TY           AS 		ITC_BUYIN_SHAR_TY   	   --��������ݶ�_����
		,T2.ITC_REDP_SHAR_TY            AS 		ITC_REDP_SHAR_TY    	   --������طݶ�_����
		,T2.ITC_SELL_SHAR_TY            AS 		ITC_SELL_SHAR_TY    	   --���������ݶ�_����
		,T2.OTC_SUBS_SHAR_TY            AS 		OTC_SUBS_SHAR_TY    	   --�����Ϲ��ݶ�_����
		,T2.OTC_PURS_SHAR_TY            AS 		OTC_PURS_SHAR_TY    	   --�����깺�ݶ�_����
		,T2.OTC_CASTSL_SHAR_TY          AS 		OTC_CASTSL_SHAR_TY  	   --���ⶨͶ�ݶ�_����
		,T2.OTC_COVT_IN_SHAR_TY         AS 		OTC_COVT_IN_SHAR_TY 	   --����ת����ݶ�_����
		,T2.OTC_REDP_SHAR_TY            AS 		OTC_REDP_SHAR_TY    	   --������طݶ�_����
		,T2.OTC_COVT_OUT_SHAR_TY        AS 		OTC_COVT_OUT_SHAR_TY	   --����ת�����ݶ�_����
		,T2.ITC_SUBS_CHAG_TY            AS 		ITC_SUBS_CHAG_TY    	   --�����Ϲ�������_����
		,T2.ITC_PURS_CHAG_TY            AS 		ITC_PURS_CHAG_TY    	   --�����깺������_����
		,T2.ITC_BUYIN_CHAG_TY           AS 		ITC_BUYIN_CHAG_TY   	   --��������������_����
		,T2.ITC_REDP_CHAG_TY            AS 		ITC_REDP_CHAG_TY    	   --�������������_����
		,T2.ITC_SELL_CHAG_TY            AS 		ITC_SELL_CHAG_TY    	   --��������������_����
		,T2.OTC_SUBS_CHAG_TY            AS 		OTC_SUBS_CHAG_TY    	   --�����Ϲ�������_����
		,T2.OTC_PURS_CHAG_TY            AS 		OTC_PURS_CHAG_TY    	   --�����깺������_����
		,T2.OTC_CASTSL_CHAG_TY          AS 		OTC_CASTSL_CHAG_TY  	   --���ⶨͶ������_����
		,T2.OTC_COVT_IN_CHAG_TY         AS 		OTC_COVT_IN_CHAG_TY 	   --����ת����������_����
		,T2.OTC_REDP_CHAG_TY            AS 		OTC_REDP_CHAG_TY    	   --�������������_����
		,T2.OTC_COVT_OUT_CHAG_TY        AS 		OTC_COVT_OUT_CHAG_TY	   --����ת����������_����
		,T2.CONTD_SALE_SHAR_TY          AS 		CONTD_SALE_SHAR_TY  	   --�������۷ݶ�_����
		,T2.CONTD_SALE_AMT_TY           AS 		CONTD_SALE_AMT_TY   	   --�������۽��_����
	FROM #T_EVT_PROD_TRD_D_EMP_MTH T1,#T_EVT_PROD_TRD_D_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID 
		AND T1.PROD_CD = T2.PROD_CD
		AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_PROD_TRD_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_D_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ӫҵ����ͨ������ʵ���´洢�ո��£�
  ��д��: Ҷ���
  ��������: 2018-03-28
  ��飺Ӫҵ��ά����ͨ�������ף��������ڣ��Ľ���ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	DELETE FROM DM.T_EVT_TRD_D_BRH WHERE OCCUR_DT = @V_DATE;

	SELECT
    	 A.AFATWO_YGH 	AS 		EMP_ID			--Ա������
		,A.PK_ORG 		AS 		BRH_ID			--Ӫҵ������
  	INTO #TMP_ORG_EMP_RELA
  	FROM DBA.T_EDW_PERSON_D A
  	WHERE A.RQ=@V_DATE
  	  	AND A.PK_ORG IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	        ,A.PK_ORG;

	-- ��T_EVT_TRD_D_BRH�Ļ���������Ӫҵ���ֶ���������ʱ��

	CREATE TABLE #TMP_T_EVT_TRD_D_BRH(
	    OCCUR_DT             numeric(8,0) NOT NULL,
		EMP_ID               varchar(30) NOT NULL,
		BRH_ID		 		 varchar(30) NOT NULL,
		STKF_TRD_QTY         numeric(38,8) NULL,
		SCDY_TRD_QTY         numeric(38,8) NULL,
		S_REPUR_TRD_QTY      numeric(38,8) NULL,
		R_REPUR_TRD_QTY      numeric(38,8) NULL,
		HGT_TRD_QTY          numeric(38,8) NULL,
		SGT_TRD_QTY          numeric(38,8) NULL,
		STKPLG_TRD_QTY       numeric(38,8) NULL,
		APPTBUYB_TRD_QTY     numeric(38,8) NULL,
		OFFUND_TRD_QTY       numeric(38,8) NULL,
		OPFUND_TRD_QTY       numeric(38,8) NULL,
		BANK_CHRM_TRD_QTY    numeric(38,8) NULL,
		SECU_CHRM_TRD_QTY    numeric(38,8) NULL,
		PSTK_OPTN_TRD_QTY    numeric(38,8) NULL,
		CREDIT_ODI_TRD_QTY   numeric(38,8) NULL,
		CREDIT_CRED_TRD_QTY  numeric(38,8) NULL,
		COVR_BUYIN_AMT       numeric(38,8) NULL,
		COVR_SELL_AMT        numeric(38,8) NULL,
		CCB_AMT              numeric(38,8) NULL,
		FIN_SELL_AMT         numeric(38,8) NULL,
		CRDT_STK_BUYIN_AMT   numeric(38,8) NULL,
		CSS_AMT              numeric(38,8) NULL,
		FIN_RTN_AMT          numeric(38,8) NULL,
		STKPLG_INIT_TRD_AMT  numeric(38,8) NULL,
		STKPLG_BUYB_TRD_AMT  numeric(38,8) NULL,
		APPTBUYB_INIT_TRD_AMT numeric(38,8) NULL,
		APPTBUYB_BUYB_TRD_AMT numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_TRD_D_BRH(
		 OCCUR_DT             			--��������		
		,EMP_ID               			--Ա������	
		,BRH_ID		 		 			--Ӫҵ������		
		,STKF_TRD_QTY         			--�ɻ�������	
		,SCDY_TRD_QTY         			--����������
		,S_REPUR_TRD_QTY      			--���ع�������	
		,R_REPUR_TRD_QTY      			--��ع�������		
		,HGT_TRD_QTY          			--����ͨ������	
		,SGT_TRD_QTY          			--���ͨ������	
		,STKPLG_TRD_QTY       			--��Ʊ��Ѻ������		
		,APPTBUYB_TRD_QTY     			--Լ�����ؽ�����
		,OFFUND_TRD_QTY       			--���ڻ������� 
		,OPFUND_TRD_QTY       			--����������� 
		,BANK_CHRM_TRD_QTY    			--������ƽ����� 
		,SECU_CHRM_TRD_QTY    			--֤ȯ��ƽ����� 
		,PSTK_OPTN_TRD_QTY    			--������Ȩ������	
		,CREDIT_ODI_TRD_QTY   			--�����˻���ͨ������ 
		,CREDIT_CRED_TRD_QTY  			--�����˻����ý����� 
		,COVR_BUYIN_AMT       			--ƽ�������� ��
		,COVR_SELL_AMT        			--ƽ��������� ��
		,CCB_AMT              			--���������� 
		,FIN_SELL_AMT         			--����������� 
		,CRDT_STK_BUYIN_AMT   			--��ȯ������ 
		,CSS_AMT              			--��ȯ������� 
		,FIN_RTN_AMT          			--���ʹ黹���
		,STKPLG_INIT_TRD_AMT  			--��Ʊ��Ѻ��ʼ���׽��
		,STKPLG_BUYB_TRD_AMT  			--��Ʊ��Ѻ���ؽ��׽��
		,APPTBUYB_INIT_TRD_AMT			--Լ�����س�ʼ���׽��
		,APPTBUYB_BUYB_TRD_AMT			--Լ�����ع��ؽ��׽��
	)
	SELECT 
		 T.OCCUR_DT             		AS 		OCCUR_DT              		--��������		
		,T.EMP_ID               		AS 		EMP_ID                		--Ա������	
		,T1.BRH_ID		 				AS 		BRH_ID		 		   		--Ӫҵ������		
		,T.STKF_TRD_QTY         		AS 		STKF_TRD_QTY          		--�ɻ�������	
		,T.SCDY_TRD_QTY         		AS 		SCDY_TRD_QTY          		--����������
		,T.S_REPUR_TRD_QTY      		AS 		S_REPUR_TRD_QTY       		--���ع�������	
		,T.R_REPUR_TRD_QTY      		AS 		R_REPUR_TRD_QTY       		--��ع�������		
		,T.HGT_TRD_QTY          		AS 		HGT_TRD_QTY           		--����ͨ������	
		,T.SGT_TRD_QTY          		AS 		SGT_TRD_QTY           		--���ͨ������	
		,T.STKPLG_TRD_QTY       		AS 		STKPLG_TRD_QTY        		--��Ʊ��Ѻ������		
		,T.APPTBUYB_TRD_QTY     		AS 		APPTBUYB_TRD_QTY      		--Լ�����ؽ�����
		,T.OFFUND_TRD_QTY       		AS 		OFFUND_TRD_QTY        		--���ڻ������� 
		,T.OPFUND_TRD_QTY       		AS 		OPFUND_TRD_QTY        		--����������� 
		,T.BANK_CHRM_TRD_QTY    		AS 		BANK_CHRM_TRD_QTY     		--������ƽ����� 
		,T.SECU_CHRM_TRD_QTY    		AS 		SECU_CHRM_TRD_QTY     		--֤ȯ��ƽ����� 
		,T.PSTK_OPTN_TRD_QTY    		AS 		PSTK_OPTN_TRD_QTY     		--������Ȩ������	
		,T.CREDIT_ODI_TRD_QTY   		AS 		CREDIT_ODI_TRD_QTY    		--�����˻���ͨ������ 
		,T.CREDIT_CRED_TRD_QTY  		AS 		CREDIT_CRED_TRD_QTY   		--�����˻����ý����� 
		,T.COVR_BUYIN_AMT       		AS 		COVR_BUYIN_AMT        		--ƽ�������� ��
		,T.COVR_SELL_AMT        		AS 		COVR_SELL_AMT         		--ƽ��������� ��
		,T.CCB_AMT              		AS 		CCB_AMT               		--���������� 
		,T.FIN_SELL_AMT         		AS 		FIN_SELL_AMT          		--����������� 
		,T.CRDT_STK_BUYIN_AMT   		AS 		CRDT_STK_BUYIN_AMT    		--��ȯ������ 
		,T.CSS_AMT              		AS 		CSS_AMT               		--��ȯ������� 
		,T.FIN_RTN_AMT          		AS 		FIN_RTN_AMT           		--���ʹ黹���
		,T.STKPLG_INIT_TRD_AMT  		AS 		STKPLG_INIT_TRD_AMT   		--��Ʊ��Ѻ��ʼ���׽��
		,T.STKPLG_BUYB_TRD_AMT  		AS 		STKPLG_BUYB_TRD_AMT   		--��Ʊ��Ѻ���ؽ��׽��
		,T.APPTBUYB_INIT_TRD_AMT		AS 		APPTBUYB_INIT_TRD_AMT 		--Լ�����س�ʼ���׽��
		,T.APPTBUYB_BUYB_TRD_AMT		AS 		APPTBUYB_BUYB_TRD_AMT 		--Լ�����ع��ؽ��׽��
	FROM DM.T_EVT_TRD_D_EMP T 
	LEFT JOIN #TMP_ORG_EMP_RELA T1
		ON T.EMP_ID = T1.EMP_ID
	WHERE T.OCCUR_DT = @V_DATE
	 AND  T1.BRH_ID IS NOT NULL;


	--����ʱ��İ�Ӫҵ��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	INSERT INTO DM.T_EVT_TRD_D_BRH (
			 OCCUR_DT             					--��������		
			,BRH_ID               					--Ӫҵ������			
			,STKF_TRD_QTY         					--�ɻ�������	
			,SCDY_TRD_QTY         					--����������
			,S_REPUR_TRD_QTY      					--���ع�������	
			,R_REPUR_TRD_QTY      					--��ع�������		
			,HGT_TRD_QTY          					--����ͨ������	
			,SGT_TRD_QTY          					--���ͨ������	
			,STKPLG_TRD_QTY       					--��Ʊ��Ѻ������		
			,APPTBUYB_TRD_QTY     					--Լ�����ؽ�����
			,OFFUND_TRD_QTY       					--���ڻ������� 
			,OPFUND_TRD_QTY       					--����������� 
			,BANK_CHRM_TRD_QTY    					--������ƽ����� 
			,SECU_CHRM_TRD_QTY    					--֤ȯ��ƽ����� 
			,PSTK_OPTN_TRD_QTY    					--������Ȩ������	
			,CREDIT_ODI_TRD_QTY   					--�����˻���ͨ������ 
			,CREDIT_CRED_TRD_QTY  					--�����˻����ý����� 
			,COVR_BUYIN_AMT       					--ƽ�������� ��
			,COVR_SELL_AMT        					--ƽ��������� ��
			,CCB_AMT              					--���������� 
			,FIN_SELL_AMT         					--����������� 
			,CRDT_STK_BUYIN_AMT   					--��ȯ������ 
			,CSS_AMT              					--��ȯ������� 
			,FIN_RTN_AMT          					--���ʹ黹���
			,STKPLG_INIT_TRD_AMT  					--��Ʊ��Ѻ��ʼ���׽��
			,STKPLG_BUYB_TRD_AMT  					--��Ʊ��Ѻ���ؽ��׽��
			,APPTBUYB_INIT_TRD_AMT					--Լ�����س�ʼ���׽��
			,APPTBUYB_BUYB_TRD_AMT					--Լ�����ع��ؽ��׽��
		)
		SELECT 
			 OCCUR_DT						AS    OCCUR_DT              	--��������		
			,BRH_ID							AS    BRH_ID                	--Ӫҵ������			
			,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY          	--�ɻ�������	
			,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY          	--����������
			,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY       	--���ع�������	
			,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY       	--��ع�������		
			,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY           	--����ͨ������	
			,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY           	--���ͨ������	
			,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY        	--��Ʊ��Ѻ������		
			,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY      	--Լ�����ؽ�����
			,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY        	--���ڻ������� 
			,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY        	--����������� 
			,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY     	--������ƽ����� 
			,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY     	--֤ȯ��ƽ����� 
			,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY     	--������Ȩ������	
			,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY    	--�����˻���ͨ������ 
			,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY   	--�����˻����ý����� 
			,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT        	--ƽ�������� ��
			,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT         	--ƽ��������� ��
			,SUM(CCB_AMT)              		AS    CCB_AMT               	--���������� 
			,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT          	--����������� 
			,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT    	--��ȯ������ 
			,SUM(CSS_AMT)              		AS    CSS_AMT               	--��ȯ������� 
			,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT           	--���ʹ黹���
			,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT   	--��Ʊ��Ѻ��ʼ���׽��
			,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT   	--��Ʊ��Ѻ���ؽ��׽��
			,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT 	--Լ�����س�ʼ���׽��
			,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT 	--Լ�����ع��ؽ��׽��
		FROM #TMP_T_EVT_TRD_D_BRH T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.BRH_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_D_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_D_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ա����ͨ������ʵ���´洢�ո��£�
  ��д��: Ҷ���
  ��������: 2018-03-28
  ��飺��ͨ�������ף��������ڣ��Ľ���ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/

	DELETE FROM DM.T_EVT_TRD_D_EMP WHERE OCCUR_DT = @V_DATE;

	-- 1.1 ��T_EVT_TRD_D_EMP�Ļ����������ʽ��˺��ֶ���������ʱ��Ϊ��ȡ��Ȩ�����Ľ��Ȼ���ٸ���Ա��ά�Ȼ��ܷ����Ľ�

	CREATE TABLE #TMP_T_EVT_TRD_D_EMP(
	    OCCUR_DT             numeric(8,0) NOT NULL,
		EMP_ID               varchar(30) NOT NULL,
		MAIN_CPTL_ACCT		 varchar(30) NOT NULL,
		STKF_TRD_QTY         numeric(38,8) NULL,
		SCDY_TRD_QTY         numeric(38,8) NULL,
		S_REPUR_TRD_QTY      numeric(38,8) NULL,
		R_REPUR_TRD_QTY      numeric(38,8) NULL,
		HGT_TRD_QTY          numeric(38,8) NULL,
		SGT_TRD_QTY          numeric(38,8) NULL,
		STKPLG_TRD_QTY       numeric(38,8) NULL,
		APPTBUYB_TRD_QTY     numeric(38,8) NULL,
		OFFUND_TRD_QTY       numeric(38,8) NULL,
		OPFUND_TRD_QTY       numeric(38,8) NULL,
		BANK_CHRM_TRD_QTY    numeric(38,8) NULL,
		SECU_CHRM_TRD_QTY    numeric(38,8) NULL,
		PSTK_OPTN_TRD_QTY    numeric(38,8) NULL,
		CREDIT_ODI_TRD_QTY   numeric(38,8) NULL,
		CREDIT_CRED_TRD_QTY  numeric(38,8) NULL,
		COVR_BUYIN_AMT       numeric(38,8) NULL,
		COVR_SELL_AMT        numeric(38,8) NULL,
		CCB_AMT              numeric(38,8) NULL,
		FIN_SELL_AMT         numeric(38,8) NULL,
		CRDT_STK_BUYIN_AMT   numeric(38,8) NULL,
		CSS_AMT              numeric(38,8) NULL,
		FIN_RTN_AMT          numeric(38,8) NULL,
		STKPLG_INIT_TRD_AMT  numeric(38,8) NULL,
		STKPLG_BUYB_TRD_AMT  numeric(38,8) NULL,
		APPTBUYB_INIT_TRD_AMT numeric(38,8) NULL,
		APPTBUYB_BUYB_TRD_AMT numeric(38,8) NULL
	);

	INSERT INTO #TMP_T_EVT_TRD_D_EMP(
		 OCCUR_DT					
		,EMP_ID						
		,MAIN_CPTL_ACCT
	)			
	SELECT 
		 @V_DATE AS OCCUR_DT			--��������
		,A.AFATWO_YGH AS EMP_ID			--Ա������
		,A.ZJZH AS MAIN_CPTL_ACCT		--�ʽ��˺�
	FROM DBA.T_DDW_SERV_RELATION_D A
	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  		   ,A.ZJZH;

	-- ������Ȩ�����ͳ�ƣ�Ա��-�ͻ�����Ч�������

  	SELECT
    	 A.AFATWO_YGH AS EMP_ID
    	,A.ZJZH AS MAIN_CPTL_ACCT
    	,SUM(A.JXBL1) AS PERFM_RATIO_1
    	,SUM(A.JXBL2) AS PERFM_RATIO_2
    	,SUM(A.JXBL3) AS PERFM_RATIO_3
    	,SUM(A.JXBL4) AS PERFM_RATIO_4
    	,SUM(A.JXBL5) AS PERFM_RATIO_5
    	,SUM(A.JXBL6) AS PERFM_RATIO_6
    	,SUM(A.JXBL7) AS PERFM_RATIO_7
    	,SUM(A.JXBL8) AS PERFM_RATIO_8
    	,SUM(A.JXBL9) AS PERFM_RATIO_9
    	,SUM(A.JXBL10) AS PERFM_RATIO_10
    	,SUM(A.JXBL11) AS PERFM_RATIO_11
    	,SUM(A.JXBL12) AS PERFM_RATIO_12
  	INTO #TMP_PERF_DISTR
  	FROM  DBA.T_DDW_SERV_RELATION_D A
  	WHERE A.RQ=@V_DATE
			AND A.ZJZH IS NOT NULL
  	GROUP BY A.AFATWO_YGH
  	          ,A.ZJZH;

	--���·����ĸ���ָ��
	UPDATE #TMP_T_EVT_TRD_D_EMP
		SET 
			 STKF_TRD_QTY = COALESCE(B.STKF_TRD_QTY,0)					* C.PERFM_RATIO_3		--�ɻ�������		
			,SCDY_TRD_QTY = COALESCE(B.SCDY_TRD_QTY,0)					* C.PERFM_RATIO_3		--����������				
			,S_REPUR_TRD_QTY = COALESCE(B.S_REPUR_TRD_QTY,0)			* C.PERFM_RATIO_3		--���ع�������						
			,R_REPUR_TRD_QTY = COALESCE(B.R_REPUR_TRD_QTY,0)			* C.PERFM_RATIO_3		--��ع�������						
			,HGT_TRD_QTY = COALESCE(B.HGT_TRD_QTY,0)					* C.PERFM_RATIO_3		--����ͨ������				
			,SGT_TRD_QTY = COALESCE(B.SGT_TRD_QTY,0)					* C.PERFM_RATIO_3		--���ͨ������				
			,STKPLG_TRD_QTY = COALESCE(B.STKPLG_TRD_QTY,0)				* C.PERFM_RATIO_3		--��Ʊ��Ѻ������				
			,APPTBUYB_TRD_QTY = COALESCE(B.APPTBUYB_TRD_QTY,0)			* C.PERFM_RATIO_3		--Լ�����ؽ�����								
			,OFFUND_TRD_QTY = COALESCE(B.OFFUND_TRD_QTY,0)				* C.PERFM_RATIO_3		--���ڻ�������							
			,OPFUND_TRD_QTY = COALESCE(B.OPFUND_TRD_QTY,0)				* C.PERFM_RATIO_3		--�����������							
			,BANK_CHRM_TRD_QTY = COALESCE(B.BANK_CHRM_TRD_QTY,0)		* C.PERFM_RATIO_3		--������ƽ�����									
			,SECU_CHRM_TRD_QTY = COALESCE(B.SECU_CHRM_TRD_QTY,0)		* C.PERFM_RATIO_3		--֤ȯ��ƽ�����									
			,PSTK_OPTN_TRD_QTY = COALESCE(B.PSTK_OPTN_TRD_QTY,0)		* C.PERFM_RATIO_3		--������Ȩ������									
			,CREDIT_ODI_TRD_QTY = COALESCE(B.CREDIT_ODI_TRD_QTY,0)		* C.PERFM_RATIO_3		--�����˻���ͨ������									
			,CREDIT_CRED_TRD_QTY = COALESCE(B.CREDIT_CRED_TRD_QTY,0)	* C.PERFM_RATIO_3		--�����˻����ý�����										
			,CCB_AMT = COALESCE(B.CCB_AMT,0)							* C.PERFM_RATIO_3		--����������				
			,FIN_SELL_AMT = COALESCE(B.FIN_SELL_AMT,0)					* C.PERFM_RATIO_3		--�����������						
			,CRDT_STK_BUYIN_AMT = COALESCE(B.CRDT_STK_BUYIN_AMT,0)		* C.PERFM_RATIO_3		--��ȯ������									
			,CSS_AMT = COALESCE(B.CSS_AMT,0)							* C.PERFM_RATIO_3		--��ȯ�������				
			,FIN_RTN_AMT = COALESCE(B.FIN_RTN_AMT,0)					* C.PERFM_RATIO_3		--���ʹ黹���						
			,STKPLG_INIT_TRD_AMT = COALESCE(B.STKPLG_INIT_TRD_AMT,0)		* C.PERFM_RATIO_3	--��Ʊ��Ѻ��ʼ���׽�� 							
			,STKPLG_BUYB_TRD_AMT = COALESCE(B.STKPLG_BUYB_TRD_AMT,0)		* C.PERFM_RATIO_3	--��Ʊ��Ѻ���ؽ��׽�� 								
			,APPTBUYB_INIT_TRD_AMT = COALESCE(B.APPTBUYB_INIT_TRD_AMT,0)	* C.PERFM_RATIO_3	--Լ�����س�ʼ���׽�� 						
			,APPTBUYB_BUYB_TRD_AMT = COALESCE(B.APPTBUYB_BUYB_TRD_AMT,0)	* C.PERFM_RATIO_3	--Լ�����ع��ؽ��׽�� 										
		FROM #TMP_T_EVT_TRD_D_EMP A
		LEFT JOIN (
				SELECT 
					T.MAIN_CPTL_ACCT	  			AS 		MAIN_CPTL_ACCT			--�ʽ��˺�			
				   ,T.STKF_TRD_QTY  	  			AS 		STKF_TRD_QTY			--�ɻ�������	
				   ,T.SCDY_TRD_QTY  	  			AS 		SCDY_TRD_QTY			--����������			
				   ,T.S_REPUR_TRD_QTY     			AS 		S_REPUR_TRD_QTY			--���ع�������				
				   ,T.R_REPUR_TRD_QTY     			AS 		R_REPUR_TRD_QTY			--��ع�������				
				   ,T.HGT_TRD_QTY  		  			AS 		HGT_TRD_QTY 			--����ͨ������				
				   ,T.SGT_TRD_QTY  		  			AS 		SGT_TRD_QTY				--���ͨ������				
				   ,T.STKPLG_TRD_QTY 	  			AS      STKPLG_TRD_QTY 			--��Ʊ��Ѻ������				
				   ,T.APPTBUYB_TRD_QTY    			AS      APPTBUYB_TRD_QTY		--Լ�����ؽ�����
				   ,T.OFFUND_TRD_QTY	  			AS 	    OFFUND_TRD_QTY			--���ڻ�������
				   ,T.OPFUND_TRD_QTY	  			AS		OPFUND_TRD_QTY			--�����������
				   ,T.BANK_CHRM_TRD_QTY   			AS		BANK_CHRM_TRD_QTY		--������ƽ�����
				   ,T.SECU_CHRM_TRD_QTY	  			AS 		SECU_CHRM_TRD_QTY		--֤ȯ��ƽ�����
				   ,T.PSTK_OPTN_TRD_QTY   			AS 		PSTK_OPTN_TRD_QTY		--������Ȩ������
				   ,T.CREDIT_ODI_TRD_QTY  			AS	    CREDIT_ODI_TRD_QTY		--�����˻���ͨ������
				   ,T.CREDIT_CRED_TRD_QTY 			AS      CREDIT_CRED_TRD_QTY     --�����˻����ý�����
				   ,0								AS		COVR_BUYIN_AMT			--ƽ��������
				   ,0								AS 		COVR_SELL_AMT			--ƽ���������
				   ,T.CCB_AMT			  			AS      CCB_AMT                 --����������
				   ,T.FIN_SELL_AMT        			AS  	FIN_SELL_AMT         	--�����������
				   ,T.CRDT_STK_BUYIN_AMT  			AS      CRDT_STK_BUYIN_AMT   	--��ȯ������
				   ,T.CSS_AMT			  			AS      CSS_AMT              	--��ȯ�������
				   ,T.FIN_RTN_AMT         			AS      FIN_RTN_AMT          	--���ʹ黹���
				   ,T.STKPLG_TRD_QTY      			AS		STKPLG_INIT_TRD_AMT  	--��Ʊ��Ѻ��ʼ���׽�� 
				   ,T.STKPLG_BUYB_AMT     			AS 		STKPLG_BUYB_TRD_AMT  	--��Ʊ��Ѻ���ؽ��׽�� 
				   ,T.APPTBUYB_TRD_QTY    			AS		APPTBUYB_INIT_TRD_AMT	--Լ�����س�ʼ���׽�� 
				   ,T.APPTBUYB_TRD_AMT	  			AS		APPTBUYB_BUYB_TRD_AMT	--Լ�����ع��ؽ��׽�� 						
				FROM DM.T_EVT_CUS_TRD_D_D T
				WHERE T.OCCUR_DT = @V_DATE
			) B ON A.MAIN_CPTL_ACCT=B.MAIN_CPTL_ACCT
	  	LEFT JOIN #TMP_PERF_DISTR C
	        ON C.MAIN_CPTL_ACCT = A.MAIN_CPTL_ACCT
	          AND C.EMP_ID = A.EMP_ID
		WHERE A.OCCUR_DT = @V_DATE;
	
	--����ʱ��İ�Ա��ά�Ȼ��ܸ���ָ������뵽Ŀ���
	INSERT INTO DM.T_EVT_TRD_D_EMP (
			 OCCUR_DT             					--��������		
			,EMP_ID               					--Ա������			
			,STKF_TRD_QTY         					--�ɻ�������	
			,SCDY_TRD_QTY         					--����������
			,S_REPUR_TRD_QTY      					--���ع�������	
			,R_REPUR_TRD_QTY      					--��ع�������		
			,HGT_TRD_QTY          					--����ͨ������	
			,SGT_TRD_QTY          					--���ͨ������	
			,STKPLG_TRD_QTY       					--��Ʊ��Ѻ������		
			,APPTBUYB_TRD_QTY     					--Լ�����ؽ�����
			,OFFUND_TRD_QTY       					--���ڻ������� 
			,OPFUND_TRD_QTY       					--����������� 
			,BANK_CHRM_TRD_QTY    					--������ƽ����� 
			,SECU_CHRM_TRD_QTY    					--֤ȯ��ƽ����� 
			,PSTK_OPTN_TRD_QTY    					--������Ȩ������	
			,CREDIT_ODI_TRD_QTY   					--�����˻���ͨ������ 
			,CREDIT_CRED_TRD_QTY  					--�����˻����ý����� 
			,COVR_BUYIN_AMT       					--ƽ�������� ��
			,COVR_SELL_AMT        					--ƽ��������� ��
			,CCB_AMT              					--���������� 
			,FIN_SELL_AMT         					--����������� 
			,CRDT_STK_BUYIN_AMT   					--��ȯ������ 
			,CSS_AMT              					--��ȯ������� 
			,FIN_RTN_AMT          					--���ʹ黹���
			,STKPLG_INIT_TRD_AMT  					--��Ʊ��Ѻ��ʼ���׽��
			,STKPLG_BUYB_TRD_AMT  					--��Ʊ��Ѻ���ؽ��׽��
			,APPTBUYB_INIT_TRD_AMT					--Լ�����س�ʼ���׽��
			,APPTBUYB_BUYB_TRD_AMT					--Լ�����ع��ؽ��׽��
		)
		SELECT 
			 OCCUR_DT						AS    OCCUR_DT              	--��������		
			,EMP_ID							AS    EMP_ID                	--Ա������			
			,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY          	--�ɻ�������	
			,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY          	--����������
			,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY       	--���ع�������	
			,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY       	--��ع�������		
			,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY           	--����ͨ������	
			,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY           	--���ͨ������	
			,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY        	--��Ʊ��Ѻ������		
			,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY      	--Լ�����ؽ�����
			,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY        	--���ڻ������� 
			,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY        	--����������� 
			,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY     	--������ƽ����� 
			,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY     	--֤ȯ��ƽ����� 
			,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY     	--������Ȩ������	
			,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY    	--�����˻���ͨ������ 
			,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY   	--�����˻����ý����� 
			,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT        	--ƽ�������� ��
			,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT         	--ƽ��������� ��
			,SUM(CCB_AMT)              		AS    CCB_AMT               	--���������� 
			,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT          	--����������� 
			,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT    	--��ȯ������ 
			,SUM(CSS_AMT)              		AS    CSS_AMT               	--��ȯ������� 
			,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT           	--���ʹ黹���
			,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT   	--��Ʊ��Ѻ��ʼ���׽��
			,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT   	--��Ʊ��Ѻ���ؽ��׽��
			,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT 	--Լ�����س�ʼ���׽��
			,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT 	--Լ�����ع��ؽ��׽��
		FROM #TMP_T_EVT_TRD_D_EMP T 
		WHERE T.OCCUR_DT = @V_DATE
	    GROUP BY T.OCCUR_DT,T.EMP_ID;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_D_EMP TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_M_BRH(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ӫҵ����ͨ������ʵ���±�
  ��д��: Ҷ���
  ��������: 2018-04-10
  ��飺Ӫҵ����ͨ�������ף��������ڣ��Ľ���ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_TRD_M_BRH WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,BRH_ID							AS    BRH_ID                	--Ӫҵ������	
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_M          	--�ɻ�������_����	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_M          	--����������_����
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_M       	--���ع�������_����	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_M       	--��ع�������_����		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_M           	--����ͨ������_����	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_M           	--���ͨ������_����	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_M        	--��Ʊ��Ѻ������_����		
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_M      	--Լ�����ؽ�����_����
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_M        	--���ڻ�������_���� 
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_M        	--�����������_���� 
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_M     	--������ƽ�����_���� 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_M     	--֤ȯ��ƽ�����_���� 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_M     	--������Ȩ������_����	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_M    	--�����˻���ͨ������_���� 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_M   	--�����˻����ý�����_���� 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_M        	--ƽ��������_���� 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_M         	--ƽ���������_���� 
		,SUM(CCB_AMT)              		AS    CCB_AMT_M               	--����������_���� 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_M          	--�����������_���� 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_M    	--��ȯ������_���� 
		,SUM(CSS_AMT)              		AS    CSS_AMT_M               	--��ȯ�������_���� 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_M           	--���ʹ黹���_����
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_M   	--��Ʊ��Ѻ��ʼ���׽��_����
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_M   	--��Ʊ��Ѻ���ؽ��׽��_����
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_M 	--Լ�����س�ʼ���׽��_����
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_M 	--Լ�����ع��ؽ��׽��_����
	INTO #TMP_T_EVT_TRD_M_BRH_MTH
	FROM DM.T_EVT_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,BRH_ID							AS    BRH_ID                	--Ӫҵ������	
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_TY         	--�ɻ�������_����	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_TY          	--����������_����	
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_TY       	--���ع�������_����	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_TY       	--��ع�������_����		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_TY           	--����ͨ������_����	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_TY           	--���ͨ������_����	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_TY        	--��Ʊ��Ѻ������_����	
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_TY      	--Լ�����ؽ�����_����
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_TY        	--���ڻ�������_����
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_TY        	--�����������_����
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_TY     	--������ƽ�����_���� 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_TY     	--֤ȯ��ƽ�����_���� 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_TY     	--������Ȩ������_����	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_TY    	--�����˻���ͨ������_���� 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_TY   	--�����˻����ý�����_���� 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_TY        	--ƽ��������_���� 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_TY         	--ƽ���������_���� 
		,SUM(CCB_AMT)              		AS    CCB_AMT_TY               	--����������_���� 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_TY          	--�����������_���� 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_TY    	--��ȯ������_���� 
		,SUM(CSS_AMT)              		AS    CSS_AMT_TY               	--��ȯ�������_���� 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_TY           	--���ʹ黹���_����
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_TY   	--��Ʊ��Ѻ��ʼ���׽��_����
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_TY   	--��Ʊ��Ѻ���ؽ��׽��_����
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_TY 	--Լ�����س�ʼ���׽��_����
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_TY 	--Լ�����ع��ؽ��׽��_����
	INTO #TMP_T_EVT_TRD_M_BRH_YEAR
	FROM DM.T_EVT_TRD_D_BRH T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.BRH_ID;

	--����Ŀ���
	INSERT INTO DM.T_EVT_TRD_M_BRH(
		 YEAR                 								--��
		,MTH                  								--��		
		,BRH_ID												--Ӫҵ������	
		,OCCUR_DT											--��������		
		,STKF_TRD_QTY_M										--�ɻ�������_����	
		,STKF_TRD_QTY_TY									--�ɻ�������_����	
		,SCDY_TRD_QTY_M										--����������_����	
		,SCDY_TRD_QTY_TY									--����������_����	
		,S_REPUR_TRD_QTY_M									--���ع�������_����		
		,S_REPUR_TRD_QTY_TY									--���ع�������_����		
		,R_REPUR_TRD_QTY_M									--��ع�������_����			
		,R_REPUR_TRD_QTY_TY									--��ع�������_����			
		,HGT_TRD_QTY_M										--����ͨ������_����	
		,HGT_TRD_QTY_TY										--����ͨ������_����		
		,SGT_TRD_QTY_M										--���ͨ������_����	
		,SGT_TRD_QTY_TY										--���ͨ������_����	
		,STKPLG_TRD_QTY_M									--��Ʊ��Ѻ������_����			
		,STKPLG_TRD_QTY_TY									--��Ʊ��Ѻ������_����		
		,APPTBUYB_TRD_QTY_M									--Լ�����ؽ�����_����	
		,APPTBUYB_TRD_QTY_TY								--Լ�����ؽ�����_����	
		,OFFUND_TRD_QTY_M									--���ڻ�������_����	
		,OFFUND_TRD_QTY_TY									--���ڻ�������_����	
		,OPFUND_TRD_QTY_M									--�����������_����	
		,OPFUND_TRD_QTY_TY									--�����������_����	
		,BANK_CHRM_TRD_QTY_M								--������ƽ�����_���� 	
		,BANK_CHRM_TRD_QTY_TY								--������ƽ�����_���� 		
		,SECU_CHRM_TRD_QTY_M								--֤ȯ��ƽ�����_����	
		,SECU_CHRM_TRD_QTY_TY								--֤ȯ��ƽ�����_����		
		,PSTK_OPTN_TRD_QTY_M								--������Ȩ������_����		
		,PSTK_OPTN_TRD_QTY_TY								--������Ȩ������_����			
		,CREDIT_ODI_TRD_QTY_M								--�����˻���ͨ������_���� 		
		,CREDIT_ODI_TRD_QTY_TY								--�����˻���ͨ������_���� 		
		,CREDIT_CRED_TRD_QTY_M								--�����˻����ý�����_���� 		
		,CREDIT_CRED_TRD_QTY_TY								--�����˻����ý�����_���� 		
		,COVR_BUYIN_AMT_M									--ƽ��������_���� 	
		,COVR_BUYIN_AMT_TY									--ƽ��������_���� 	
		,COVR_SELL_AMT_M									--ƽ���������_���� 
		,COVR_SELL_AMT_TY									--ƽ���������_���� 	
		,CCB_AMT_M											--����������_���� 
		,CCB_AMT_TY											--����������_���� 
		,FIN_SELL_AMT_M										--�����������_���� 
		,FIN_SELL_AMT_TY									--�����������_���� 
		,CRDT_STK_BUYIN_AMT_M								--��ȯ������_���� 		
		,CRDT_STK_BUYIN_AMT_TY								--��ȯ������_���� 		
		,CSS_AMT_M											--��ȯ�������_���� 
		,CSS_AMT_TY											--��ȯ�������_���� 
		,FIN_RTN_AMT_M        								--���ʹ黹���_����		
		,FIN_RTN_AMT_TY       								--���ʹ黹���_����		
		,STKPLG_INIT_TRD_AMT_M 								--��Ʊ��Ѻ��ʼ���׽��_����		
		,STKPLG_INIT_TRD_AMT_TY 							--��Ʊ��Ѻ��ʼ���׽��_����		
		,STKPLG_REPO_TRD_AMT_M								--��Ʊ��Ѻ���ؽ��׽��_����		
		,STKPLG_REPO_TRD_AMT_TY								--��Ʊ��Ѻ���ؽ��׽��_����		
		,APPTBUYB_INIT_TRD_AMT_M 							--Լ�����س�ʼ���׽��_����			
		,APPTBUYB_INIT_TRD_AMT_TY							--Լ�����س�ʼ���׽��_����			
		,APPTBUYB_BUYB_TRD_AMT_M							--Լ�����ع��ؽ��׽��_����			
		,APPTBUYB_BUYB_TRD_AMT_TY							--Լ�����ع��ؽ��׽��_����	
	)		
	SELECT 
		 T1.YEAR  							AS			YEAR                 								--��
		,T1.MTH 						    AS			MTH                  								--��		
		,T1.BRH_ID							AS			BRH_ID												--Ӫҵ������	
		,T1.OCCUR_DT 						AS			OCCUR_DT											--��������		
		,T1.STKF_TRD_QTY_M        	 		AS			STKF_TRD_QTY_M										--�ɻ�������_����	
		,T2.STKF_TRD_QTY_TY         		AS			STKF_TRD_QTY_TY										--�ɻ�������_����	
		,T1.SCDY_TRD_QTY_M          		AS			SCDY_TRD_QTY_M										--����������_����	
		,T2.SCDY_TRD_QTY_TY          		AS			SCDY_TRD_QTY_TY										--����������_����		
		,T1.S_REPUR_TRD_QTY_M       		AS			S_REPUR_TRD_QTY_M									--���ع�������_����		
		,T2.S_REPUR_TRD_QTY_TY       		AS			S_REPUR_TRD_QTY_TY									--���ع�������_����			
		,T1.R_REPUR_TRD_QTY_M       		AS			R_REPUR_TRD_QTY_M									--��ع�������_����			
		,T2.R_REPUR_TRD_QTY_TY       		AS			R_REPUR_TRD_QTY_TY									--��ع�������_����	
		,T1.HGT_TRD_QTY_M           		AS			HGT_TRD_QTY_M										--����ͨ������_����	
		,T2.HGT_TRD_QTY_TY           		AS			HGT_TRD_QTY_TY										--����ͨ������_����	
		,T1.SGT_TRD_QTY_M           		AS			SGT_TRD_QTY_M										--���ͨ������_����	
		,T2.SGT_TRD_QTY_TY           		AS			SGT_TRD_QTY_TY										--���ͨ������_����	
		,T1.STKPLG_TRD_QTY_M        		AS			STKPLG_TRD_QTY_M									--��Ʊ��Ѻ������_����			
		,T2.STKPLG_TRD_QTY_TY        		AS			STKPLG_TRD_QTY_TY									--��Ʊ��Ѻ������_����		
		,T1.APPTBUYB_TRD_QTY_M      		AS			APPTBUYB_TRD_QTY_M									--Լ�����ؽ�����_����	
		,T2.APPTBUYB_TRD_QTY_TY      		AS			APPTBUYB_TRD_QTY_TY									--Լ�����ؽ�����_����	
		,T1.OFFUND_TRD_QTY_M        		AS			OFFUND_TRD_QTY_M									--���ڻ�������_����	
		,T2.OFFUND_TRD_QTY_TY        		AS			OFFUND_TRD_QTY_TY									--���ڻ�������_����	
		,T1.OPFUND_TRD_QTY_M        		AS			OPFUND_TRD_QTY_M									--�����������_����	
		,T2.OPFUND_TRD_QTY_TY        		AS			OPFUND_TRD_QTY_TY									--�����������_����	
		,T1.BANK_CHRM_TRD_QTY_M     		AS			BANK_CHRM_TRD_QTY_M									--������ƽ�����_���� 	
		,T2.BANK_CHRM_TRD_QTY_TY     		AS			BANK_CHRM_TRD_QTY_TY								--������ƽ�����_���� 		
		,T1.SECU_CHRM_TRD_QTY_M     		AS			SECU_CHRM_TRD_QTY_M									--֤ȯ��ƽ�����_����	
		,T2.SECU_CHRM_TRD_QTY_TY     		AS			SECU_CHRM_TRD_QTY_TY								--֤ȯ��ƽ�����_����		
		,T1.PSTK_OPTN_TRD_QTY_M     		AS			PSTK_OPTN_TRD_QTY_M									--������Ȩ������_����		
		,T2.PSTK_OPTN_TRD_QTY_TY     		AS			PSTK_OPTN_TRD_QTY_TY								--������Ȩ������_����			
		,T1.CREDIT_ODI_TRD_QTY_M    		AS			CREDIT_ODI_TRD_QTY_M								--�����˻���ͨ������_���� 		
		,T2.CREDIT_ODI_TRD_QTY_TY    		AS			CREDIT_ODI_TRD_QTY_TY								--�����˻���ͨ������_���� 		
		,T1.CREDIT_CRED_TRD_QTY_M   		AS			CREDIT_CRED_TRD_QTY_M								--�����˻����ý�����_���� 		
		,T2.CREDIT_CRED_TRD_QTY_TY   		AS			CREDIT_CRED_TRD_QTY_TY								--�����˻����ý�����_���� 		
		,T1.COVR_BUYIN_AMT_M        		AS			COVR_BUYIN_AMT_M									--ƽ��������_���� 	
		,T2.COVR_BUYIN_AMT_TY        		AS			COVR_BUYIN_AMT_TY									--ƽ��������_���� 	
		,T1.COVR_SELL_AMT_M         		AS			COVR_SELL_AMT_M										--ƽ���������_���� 
		,T2.COVR_SELL_AMT_TY         		AS			COVR_SELL_AMT_TY									--ƽ���������_���� 	
		,T1.CCB_AMT_M               		AS			CCB_AMT_M											--����������_���� 
		,T2.CCB_AMT_TY               		AS			CCB_AMT_TY											--����������_���� 
		,T1.FIN_SELL_AMT_M          		AS			FIN_SELL_AMT_M										--�����������_���� 
		,T2.FIN_SELL_AMT_TY          		AS			FIN_SELL_AMT_TY										--�����������_���� 
		,T1.CRDT_STK_BUYIN_AMT_M    		AS			CRDT_STK_BUYIN_AMT_M								--��ȯ������_���� 		
		,T2.CRDT_STK_BUYIN_AMT_TY    		AS			CRDT_STK_BUYIN_AMT_TY								--��ȯ������_���� 		
		,T1.CSS_AMT_M               		AS			CSS_AMT_M											--��ȯ�������_���� 
		,T2.CSS_AMT_TY               		AS			CSS_AMT_TY											--��ȯ�������_���� 
		,T1.FIN_RTN_AMT_M           		AS			FIN_RTN_AMT_M        								--���ʹ黹���_����		
		,T2.FIN_RTN_AMT_TY           		AS			FIN_RTN_AMT_TY       								--���ʹ黹���_����		
		,T1.STKPLG_INIT_TRD_AMT_M   		AS			STKPLG_INIT_TRD_AMT_M 								--��Ʊ��Ѻ��ʼ���׽��_����		
		,T2.STKPLG_INIT_TRD_AMT_TY   		AS			STKPLG_INIT_TRD_AMT_TY 								--��Ʊ��Ѻ��ʼ���׽��_����		
		,T1.STKPLG_BUYB_TRD_AMT_M   		AS			STKPLG_REPO_TRD_AMT_M								--��Ʊ��Ѻ���ؽ��׽��_����		
		,T2.STKPLG_BUYB_TRD_AMT_TY   		AS			STKPLG_REPO_TRD_AMT_TY								--��Ʊ��Ѻ���ؽ��׽��_����		
		,T1.APPTBUYB_INIT_TRD_AMT_M 		AS			APPTBUYB_INIT_TRD_AMT_M 							--Լ�����س�ʼ���׽��_����			
		,T2.APPTBUYB_INIT_TRD_AMT_TY 		AS			APPTBUYB_INIT_TRD_AMT_TY							--Լ�����س�ʼ���׽��_����			
		,T1.APPTBUYB_BUYB_TRD_AMT_M 		AS			APPTBUYB_BUYB_TRD_AMT_M								--Լ�����ع��ؽ��׽��_����			
		,T2.APPTBUYB_BUYB_TRD_AMT_TY 		AS			APPTBUYB_BUYB_TRD_AMT_TY							--Լ�����ع��ؽ��׽��_����			
	FROM #TMP_T_EVT_TRD_M_BRH_MTH T1,#TMP_T_EVT_TRD_M_BRH_YEAR T2
	WHERE T1.BRH_ID = T2.BRH_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_M_BRH TO query_dev
GO
CREATE PROCEDURE dm.P_EVT_TRD_M_EMP(IN @V_DATE INT)
BEGIN

  /******************************************************************
  ������: Ա����ͨ������ʵ���±�
  ��д��: Ҷ���
  ��������: 2018-04-04
  ��飺��ͨ�������ף��������ڣ��Ľ���ͳ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  	DECLARE @V_YEAR VARCHAR(4);		-- ���
  	DECLARE @V_MONTH VARCHAR(2);	-- �·�
 	DECLARE @V_BEGIN_TRAD_DATE INT;	-- ���¿�ʼ������
 	DECLARE @V_YEAR_START_DATE INT; -- ���꿪ʼ������
  
	COMMIT;
	
	SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_DATE),1,4);
	SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_DATE),5,2);
	SET @V_BEGIN_TRAD_DATE = (SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ='1' AND NIAN=@V_YEAR AND YUE=@V_MONTH);
    SET @V_YEAR_START_DATE=(SELECT MIN(DT) FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND IF_TRD_DAY_FLAG=1 ); 

	DELETE FROM DM.T_EVT_TRD_M_EMP WHERE YEAR=@V_YEAR AND MTH=@V_MONTH;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,EMP_ID							AS    EMP_ID                	--Ա������	
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_M          	--�ɻ�������_����	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_M          	--����������_����
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_M       	--���ع�������_����	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_M       	--��ع�������_����		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_M           	--����ͨ������_����	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_M           	--���ͨ������_����	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_M        	--��Ʊ��Ѻ������_����		
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_M      	--Լ�����ؽ�����_����
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_M        	--���ڻ�������_���� 
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_M        	--�����������_���� 
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_M     	--������ƽ�����_���� 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_M     	--֤ȯ��ƽ�����_���� 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_M     	--������Ȩ������_����	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_M    	--�����˻���ͨ������_���� 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_M   	--�����˻����ý�����_���� 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_M        	--ƽ��������_���� 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_M         	--ƽ���������_���� 
		,SUM(CCB_AMT)              		AS    CCB_AMT_M               	--����������_���� 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_M          	--�����������_���� 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_M    	--��ȯ������_���� 
		,SUM(CSS_AMT)              		AS    CSS_AMT_M               	--��ȯ�������_���� 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_M           	--���ʹ黹���_����
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_M   	--��Ʊ��Ѻ��ʼ���׽��_����
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_M   	--��Ʊ��Ѻ���ؽ��׽��_����
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_M 	--Լ�����س�ʼ���׽��_����
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_M 	--Լ�����ع��ؽ��׽��_����
	INTO #TMP_T_EVT_TRD_M_EMP_MTH
	FROM DM.T_EVT_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_BEGIN_TRAD_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	-- ͳ����ָ��
	SELECT 
		 @V_DATE						AS    OCCUR_DT              	--��������		
		,EMP_ID							AS    EMP_ID                	--Ա������	
		,@V_YEAR						AS    YEAR   					--��
		,@V_MONTH 						AS    MTH 						--��
		,SUM(STKF_TRD_QTY)         		AS    STKF_TRD_QTY_TY         	--�ɻ�������_����	
		,SUM(SCDY_TRD_QTY)         		AS    SCDY_TRD_QTY_TY          	--����������_����	
		,SUM(S_REPUR_TRD_QTY)     		AS    S_REPUR_TRD_QTY_TY       	--���ع�������_����	
		,SUM(R_REPUR_TRD_QTY)      		AS    R_REPUR_TRD_QTY_TY       	--��ع�������_����		
		,SUM(HGT_TRD_QTY)          		AS    HGT_TRD_QTY_TY           	--����ͨ������_����	
		,SUM(SGT_TRD_QTY)          		AS    SGT_TRD_QTY_TY           	--���ͨ������_����	
		,SUM(STKPLG_TRD_QTY)       		AS    STKPLG_TRD_QTY_TY        	--��Ʊ��Ѻ������_����	
		,SUM(APPTBUYB_TRD_QTY)     		AS    APPTBUYB_TRD_QTY_TY      	--Լ�����ؽ�����_����
		,SUM(OFFUND_TRD_QTY)       		AS    OFFUND_TRD_QTY_TY        	--���ڻ�������_����
		,SUM(OPFUND_TRD_QTY)       		AS    OPFUND_TRD_QTY_TY        	--�����������_����
		,SUM(BANK_CHRM_TRD_QTY)    		AS    BANK_CHRM_TRD_QTY_TY     	--������ƽ�����_���� 
		,SUM(SECU_CHRM_TRD_QTY)    		AS    SECU_CHRM_TRD_QTY_TY     	--֤ȯ��ƽ�����_���� 
		,SUM(PSTK_OPTN_TRD_QTY)    		AS    PSTK_OPTN_TRD_QTY_TY     	--������Ȩ������_����	
		,SUM(CREDIT_ODI_TRD_QTY)   		AS    CREDIT_ODI_TRD_QTY_TY    	--�����˻���ͨ������_���� 
		,SUM(CREDIT_CRED_TRD_QTY)  		AS    CREDIT_CRED_TRD_QTY_TY   	--�����˻����ý�����_���� 
		,SUM(COVR_BUYIN_AMT)       		AS    COVR_BUYIN_AMT_TY        	--ƽ��������_���� 
		,SUM(COVR_SELL_AMT)        		AS    COVR_SELL_AMT_TY         	--ƽ���������_���� 
		,SUM(CCB_AMT)              		AS    CCB_AMT_TY               	--����������_���� 
		,SUM(FIN_SELL_AMT)         		AS    FIN_SELL_AMT_TY          	--�����������_���� 
		,SUM(CRDT_STK_BUYIN_AMT)   		AS    CRDT_STK_BUYIN_AMT_TY    	--��ȯ������_���� 
		,SUM(CSS_AMT)              		AS    CSS_AMT_TY               	--��ȯ�������_���� 
		,SUM(FIN_RTN_AMT)          		AS    FIN_RTN_AMT_TY           	--���ʹ黹���_����
		,SUM(STKPLG_INIT_TRD_AMT)  		AS    STKPLG_INIT_TRD_AMT_TY   	--��Ʊ��Ѻ��ʼ���׽��_����
		,SUM(STKPLG_BUYB_TRD_AMT)  		AS    STKPLG_BUYB_TRD_AMT_TY   	--��Ʊ��Ѻ���ؽ��׽��_����
		,SUM(APPTBUYB_INIT_TRD_AMT)		AS    APPTBUYB_INIT_TRD_AMT_TY 	--Լ�����س�ʼ���׽��_����
		,SUM(APPTBUYB_BUYB_TRD_AMT)		AS    APPTBUYB_BUYB_TRD_AMT_TY 	--Լ�����ع��ؽ��׽��_����
	INTO #TMP_T_EVT_TRD_M_EMP_YEAR
	FROM DM.T_EVT_TRD_D_EMP T 
	WHERE T.OCCUR_DT BETWEEN @V_YEAR_START_DATE AND @V_DATE
	   GROUP BY T.EMP_ID;

	--����Ŀ���
	INSERT INTO DM.T_EVT_TRD_M_EMP(
		 YEAR                 								--��
		,MTH                  								--��		
		,EMP_ID												--Ա������	
		,OCCUR_DT											--��������		
		,STKF_TRD_QTY_M										--�ɻ�������_����	
		,STKF_TRD_QTY_TY									--�ɻ�������_����	
		,SCDY_TRD_QTY_M										--����������_����	
		,SCDY_TRD_QTY_TY									--����������_����	
		,S_REPUR_TRD_QTY_M									--���ع�������_����		
		,S_REPUR_TRD_QTY_TY									--���ع�������_����		
		,R_REPUR_TRD_QTY_M									--��ع�������_����			
		,R_REPUR_TRD_QTY_TY									--��ع�������_����			
		,HGT_TRD_QTY_M										--����ͨ������_����	
		,HGT_TRD_QTY_TY										--����ͨ������_����		
		,SGT_TRD_QTY_M										--���ͨ������_����	
		,SGT_TRD_QTY_TY										--���ͨ������_����	
		,STKPLG_TRD_QTY_M									--��Ʊ��Ѻ������_����			
		,STKPLG_TRD_QTY_TY									--��Ʊ��Ѻ������_����		
		,APPTBUYB_TRD_QTY_M									--Լ�����ؽ�����_����	
		,APPTBUYB_TRD_QTY_TY								--Լ�����ؽ�����_����	
		,OFFUND_TRD_QTY_M									--���ڻ�������_����	
		,OFFUND_TRD_QTY_TY									--���ڻ�������_����	
		,OPFUND_TRD_QTY_M									--�����������_����	
		,OPFUND_TRD_QTY_TY									--�����������_����	
		,BANK_CHRM_TRD_QTY_M								--������ƽ�����_���� 	
		,BANK_CHRM_TRD_QTY_TY								--������ƽ�����_���� 		
		,SECU_CHRM_TRD_QTY_M								--֤ȯ��ƽ�����_����	
		,SECU_CHRM_TRD_QTY_TY								--֤ȯ��ƽ�����_����		
		,PSTK_OPTN_TRD_QTY_M								--������Ȩ������_����		
		,PSTK_OPTN_TRD_QTY_TY								--������Ȩ������_����			
		,CREDIT_ODI_TRD_QTY_M								--�����˻���ͨ������_���� 		
		,CREDIT_ODI_TRD_QTY_TY								--�����˻���ͨ������_���� 		
		,CREDIT_CRED_TRD_QTY_M								--�����˻����ý�����_���� 		
		,CREDIT_CRED_TRD_QTY_TY								--�����˻����ý�����_���� 		
		,COVR_BUYIN_AMT_M									--ƽ��������_���� 	
		,COVR_BUYIN_AMT_TY									--ƽ��������_���� 	
		,COVR_SELL_AMT_M									--ƽ���������_���� 
		,COVR_SELL_AMT_TY									--ƽ���������_���� 	
		,CCB_AMT_M											--����������_���� 
		,CCB_AMT_TY											--����������_���� 
		,FIN_SELL_AMT_M										--�����������_���� 
		,FIN_SELL_AMT_TY									--�����������_���� 
		,CRDT_STK_BUYIN_AMT_M								--��ȯ������_���� 		
		,CRDT_STK_BUYIN_AMT_TY								--��ȯ������_���� 		
		,CSS_AMT_M											--��ȯ�������_���� 
		,CSS_AMT_TY											--��ȯ�������_���� 
		,FIN_RTN_AMT_M        								--���ʹ黹���_����		
		,FIN_RTN_AMT_TY       								--���ʹ黹���_����		
		,STKPLG_INIT_TRD_AMT_M 								--��Ʊ��Ѻ��ʼ���׽��_����		
		,STKPLG_INIT_TRD_AMT_TY 							--��Ʊ��Ѻ��ʼ���׽��_����		
		,STKPLG_REPO_TRD_AMT_M								--��Ʊ��Ѻ���ؽ��׽��_����		
		,STKPLG_REPO_TRD_AMT_TY								--��Ʊ��Ѻ���ؽ��׽��_����		
		,APPTBUYB_INIT_TRD_AMT_M 							--Լ�����س�ʼ���׽��_����			
		,APPTBUYB_INIT_TRD_AMT_TY							--Լ�����س�ʼ���׽��_����			
		,APPTBUYB_BUYB_TRD_AMT_M							--Լ�����ع��ؽ��׽��_����			
		,APPTBUYB_BUYB_TRD_AMT_TY							--Լ�����ع��ؽ��׽��_����	
	)		
	SELECT 
		 T1.YEAR  							AS			YEAR                 								--��
		,T1.MTH 						    AS			MTH                  								--��		
		,T1.EMP_ID							AS			EMP_ID												--Ա������	
		,T1.OCCUR_DT 						AS			OCCUR_DT											--��������		
		,T1.STKF_TRD_QTY_M        	 		AS			STKF_TRD_QTY_M										--�ɻ�������_����	
		,T2.STKF_TRD_QTY_TY         		AS			STKF_TRD_QTY_TY										--�ɻ�������_����	
		,T1.SCDY_TRD_QTY_M          		AS			SCDY_TRD_QTY_M										--����������_����	
		,T2.SCDY_TRD_QTY_TY          		AS			SCDY_TRD_QTY_TY										--����������_����		
		,T1.S_REPUR_TRD_QTY_M       		AS			S_REPUR_TRD_QTY_M									--���ع�������_����		
		,T2.S_REPUR_TRD_QTY_TY       		AS			S_REPUR_TRD_QTY_TY									--���ع�������_����			
		,T1.R_REPUR_TRD_QTY_M       		AS			R_REPUR_TRD_QTY_M									--��ع�������_����			
		,T2.R_REPUR_TRD_QTY_TY       		AS			R_REPUR_TRD_QTY_TY									--��ع�������_����	
		,T1.HGT_TRD_QTY_M           		AS			HGT_TRD_QTY_M										--����ͨ������_����	
		,T2.HGT_TRD_QTY_TY           		AS			HGT_TRD_QTY_TY										--����ͨ������_����	
		,T1.SGT_TRD_QTY_M           		AS			SGT_TRD_QTY_M										--���ͨ������_����	
		,T2.SGT_TRD_QTY_TY           		AS			SGT_TRD_QTY_TY										--���ͨ������_����	
		,T1.STKPLG_TRD_QTY_M        		AS			STKPLG_TRD_QTY_M									--��Ʊ��Ѻ������_����			
		,T2.STKPLG_TRD_QTY_TY        		AS			STKPLG_TRD_QTY_TY									--��Ʊ��Ѻ������_����		
		,T1.APPTBUYB_TRD_QTY_M      		AS			APPTBUYB_TRD_QTY_M									--Լ�����ؽ�����_����	
		,T2.APPTBUYB_TRD_QTY_TY      		AS			APPTBUYB_TRD_QTY_TY									--Լ�����ؽ�����_����	
		,T1.OFFUND_TRD_QTY_M        		AS			OFFUND_TRD_QTY_M									--���ڻ�������_����	
		,T2.OFFUND_TRD_QTY_TY        		AS			OFFUND_TRD_QTY_TY									--���ڻ�������_����	
		,T1.OPFUND_TRD_QTY_M        		AS			OPFUND_TRD_QTY_M									--�����������_����	
		,T2.OPFUND_TRD_QTY_TY        		AS			OPFUND_TRD_QTY_TY									--�����������_����	
		,T1.BANK_CHRM_TRD_QTY_M     		AS			BANK_CHRM_TRD_QTY_M									--������ƽ�����_���� 	
		,T2.BANK_CHRM_TRD_QTY_TY     		AS			BANK_CHRM_TRD_QTY_TY								--������ƽ�����_���� 		
		,T1.SECU_CHRM_TRD_QTY_M     		AS			SECU_CHRM_TRD_QTY_M									--֤ȯ��ƽ�����_����	
		,T2.SECU_CHRM_TRD_QTY_TY     		AS			SECU_CHRM_TRD_QTY_TY								--֤ȯ��ƽ�����_����		
		,T1.PSTK_OPTN_TRD_QTY_M     		AS			PSTK_OPTN_TRD_QTY_M									--������Ȩ������_����		
		,T2.PSTK_OPTN_TRD_QTY_TY     		AS			PSTK_OPTN_TRD_QTY_TY								--������Ȩ������_����			
		,T1.CREDIT_ODI_TRD_QTY_M    		AS			CREDIT_ODI_TRD_QTY_M								--�����˻���ͨ������_���� 		
		,T2.CREDIT_ODI_TRD_QTY_TY    		AS			CREDIT_ODI_TRD_QTY_TY								--�����˻���ͨ������_���� 		
		,T1.CREDIT_CRED_TRD_QTY_M   		AS			CREDIT_CRED_TRD_QTY_M								--�����˻����ý�����_���� 		
		,T2.CREDIT_CRED_TRD_QTY_TY   		AS			CREDIT_CRED_TRD_QTY_TY								--�����˻����ý�����_���� 		
		,T1.COVR_BUYIN_AMT_M        		AS			COVR_BUYIN_AMT_M									--ƽ��������_���� 	
		,T2.COVR_BUYIN_AMT_TY        		AS			COVR_BUYIN_AMT_TY									--ƽ��������_���� 	
		,T1.COVR_SELL_AMT_M         		AS			COVR_SELL_AMT_M										--ƽ���������_���� 
		,T2.COVR_SELL_AMT_TY         		AS			COVR_SELL_AMT_TY									--ƽ���������_���� 	
		,T1.CCB_AMT_M               		AS			CCB_AMT_M											--����������_���� 
		,T2.CCB_AMT_TY               		AS			CCB_AMT_TY											--����������_���� 
		,T1.FIN_SELL_AMT_M          		AS			FIN_SELL_AMT_M										--�����������_���� 
		,T2.FIN_SELL_AMT_TY          		AS			FIN_SELL_AMT_TY										--�����������_���� 
		,T1.CRDT_STK_BUYIN_AMT_M    		AS			CRDT_STK_BUYIN_AMT_M								--��ȯ������_���� 		
		,T2.CRDT_STK_BUYIN_AMT_TY    		AS			CRDT_STK_BUYIN_AMT_TY								--��ȯ������_���� 		
		,T1.CSS_AMT_M               		AS			CSS_AMT_M											--��ȯ�������_���� 
		,T2.CSS_AMT_TY               		AS			CSS_AMT_TY											--��ȯ�������_���� 
		,T1.FIN_RTN_AMT_M           		AS			FIN_RTN_AMT_M        								--���ʹ黹���_����		
		,T2.FIN_RTN_AMT_TY           		AS			FIN_RTN_AMT_TY       								--���ʹ黹���_����		
		,T1.STKPLG_INIT_TRD_AMT_M   		AS			STKPLG_INIT_TRD_AMT_M 								--��Ʊ��Ѻ��ʼ���׽��_����		
		,T2.STKPLG_INIT_TRD_AMT_TY   		AS			STKPLG_INIT_TRD_AMT_TY 								--��Ʊ��Ѻ��ʼ���׽��_����		
		,T1.STKPLG_BUYB_TRD_AMT_M   		AS			STKPLG_REPO_TRD_AMT_M								--��Ʊ��Ѻ���ؽ��׽��_����		
		,T2.STKPLG_BUYB_TRD_AMT_TY   		AS			STKPLG_REPO_TRD_AMT_TY								--��Ʊ��Ѻ���ؽ��׽��_����		
		,T1.APPTBUYB_INIT_TRD_AMT_M 		AS			APPTBUYB_INIT_TRD_AMT_M 							--Լ�����س�ʼ���׽��_����			
		,T2.APPTBUYB_INIT_TRD_AMT_TY 		AS			APPTBUYB_INIT_TRD_AMT_TY							--Լ�����س�ʼ���׽��_����			
		,T1.APPTBUYB_BUYB_TRD_AMT_M 		AS			APPTBUYB_BUYB_TRD_AMT_M								--Լ�����ع��ؽ��׽��_����			
		,T2.APPTBUYB_BUYB_TRD_AMT_TY 		AS			APPTBUYB_BUYB_TRD_AMT_TY							--Լ�����ع��ؽ��׽��_����			
	FROM #TMP_T_EVT_TRD_M_EMP_MTH T1,#TMP_T_EVT_TRD_M_EMP_YEAR T2
	WHERE T1.EMP_ID = T2.EMP_ID AND T1.OCCUR_DT = T2.OCCUR_DT;
	COMMIT;
END
GO
GRANT EXECUTE ON dm.P_EVT_TRD_M_EMP TO query_dev
GO
CREATE PROCEDURE dm.p_ip_client(@i_rq numeric(8))
/*�ͻ���Ϣ��*/
begin
  -- ��ʼ��
  delete from
    dm.t_ip_client;
  insert into dm.t_ip_client( client_id,client_name,client_gender,nationality,id_kind,id_no,risk_level,cancel_date,open_date,client_status,branch_no,corp_client_group,client_type) 
    select a.client_id, -- �ͻ����    
      a.client_name, -- �ͻ�����       
      d.dict_prompt, -- �Ա�        
      a.nationality, -- ����       
      e.dict_prompt, -- ֤�����       
      a.id_no, -- ֤������,   
      c.dict_prompt, -- �ͻ����յȼ�       
      a.cancel_date, -- ��������       
      a.open_date, -- ��������       
      b.dict_prompt, -- �ͻ�״̬           
      convert(varchar,a.branch_no), -- �������         
      f.dict_prompt, -- �ͻ�����   
      g.dict_prompt from -- �ͻ�����
      DBA.T_EDW_UF2_CLIENT as a left outer join
      (select subentry,
        dict_prompt from dba.T_ODS_UF2_SYSDICTIONARY where dict_entry = 1000) as b on b.subentry = a.client_status left outer join
      (select subentry,
        dict_prompt from dba.T_ODS_UF2_SYSDICTIONARY where dict_entry = 2505) as c on c.subentry = convert(varchar,a.CORP_RISK_LEVEL) left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as d on d.dict_entry = 1049 and a.client_gender = d.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as e on e.dict_entry = 1041 and a.id_kind = e.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as f on f.dict_entry = 1050 and convert(varchar,a.corp_client_group) = f.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as g on g.dict_entry = 1048 and a.organ_flag = g.subentry where
      a.load_dt = @i_rq;
  -- ��������
  update dm.t_ip_client as a set
    main_advisor_userid = b.user_id,
    main_advisor_username = b.user_name from
    dm.t_ip_client as a left outer join
    (select a.client_id,a.user_id,b.user_name from
      (select client_id,max(user_id) as user_id from
        dba.gt_ods_afa2_serafa_relation where
        load_dt = @i_rq and is_mainserv = '1'
        group by client_id) as a left outer join
      dba.gt_ods_afa2_xtgl_user as b on b.load_dt = @i_rq and a.user_id = b.user_id) as b on
    a.client_id = b.client_id;
  -------------------------    
  --�����ʲ��˻�
  ------------------------------------------
  update dm.t_ip_client as a set
    rzrq_asset_account = b.fund_account from
    dm.t_ip_client as a,(select fund_account,client_id,load_dt from dba.t_edw_uf2_fundaccount where load_dt = @i_rq and asset_prop = '7' and main_flag = '1') as b where
    a.client_id = b.client_id;
  -------------------------
  --���ʲ��˻�
  ------------------------------------------
  update dm.t_ip_client as a set
    main_asset_account = b.fund_account from
    dm.t_ip_client as a,(select fund_account,client_id,load_dt from dba.t_edw_uf2_fundaccount where load_dt = @i_rq and asset_prop = '0' and main_flag = '1') as b where
    a.client_id = b.client_id;
  -------------------------
  --��������,����������
  ---------------------------------
  update dm.t_ip_client as a set
    net_chanel = b.broker_code,
    net_broker = b.referer_name from
    dm.t_ip_client as a,dba.T_EDW_WSKH_USER_PRESENCE as b where
    a.client_id = b.user_no and
    b.load_dt = @i_rq;
  commit work
end
GO
CREATE PROCEDURE dm.p_ip_clientinfo(@i_rq numeric(8))
on exception resume
/*���˿ͻ���Ϣ��*/
begin
  commit work;
  -- ��ʼ��
  delete from
    dm.t_ip_clientinfo;
  insert into dm.t_ip_clientinfo( client_id,age,birthday,home_tel,office_tel,mobile_tel,address,e_mail,degree,profession,branch_no) 
    select a.client_id, -- �ͻ����,          
      null, --abs(datediff(yy,getdate(),convert(date,a.birthday))) ,-- ����,              
      a.birthday, -- ��������,          
      a.home_tel, -- ��ͥ�绰,          
      a.office_tel, -- ��λ�绰,          
      a.mobile_tel, -- �ֻ���,            
      a.address, -- ��ͥ��ַ,           
      a.e_mail, -- ����,              
      dic_degree.dict_prompt, --ѧ��,              
      dic_prof.dict_prompt, --ְҵ,                         
      a.branch_no from -- Ӫҵ�����
      DBA.T_EDW_UF2_CLIENTINFO as A left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as dic_degree on dic_degree.dict_entry = 1046 and a.degree_code = dic_degree.subentry left outer join
      dba.T_ODS_UF2_SYSDICTIONARY as dic_prof on dic_prof.dict_entry = 1047 and a.profession_code = dic_prof.subentry where
      a.LOAD_DT = @i_rq;
  --����
  select a.client_id,case when a.birthday >= '19000100' and a.birthday <= '20200100' then
      a.birthday
    when b.birthday >= 19000100 and b.birthday <= 20200100 then
      convert(varchar,b.birthday)
    end as birthday into #tmp_client from
    (select client_id,case when length(rtrim(id_no)) = 18 and substr(id_no,7,8) not like '%[^0-9]%' then
        substr(id_no,7,8)
      when length(rtrim(id_no)) = 15 and substr(id_no,7,6) not like '%[^0-9]%' then '19' || 
        substr(id_no,7,6)
      end as birthday from dba.T_EDW_UF2_CLIENT where
      load_dt = @i_rq) as a left outer join
    dba.T_EDW_UF2_CLIENTINFO as b on a.client_id = b.client_id and b.load_dt = @i_rq;
  update dm.t_ip_clientinfo as a set
    age = case when substr(b.birthday,5,4) <= substr(convert(varchar,getdate(*),112),5,4) then
      convert(integer,substr(convert(varchar,getdate(*),112),1,4))-convert(integer,substr(b.birthday,1,4))
    else convert(integer,substr(convert(varchar,getdate(*),112),1,4))-convert(integer,substr(b.birthday,1,4))-1
    end from
    dm.t_ip_clientinfo as a,#tmp_client as b where
    a.client_id = b.client_id;
  commit work
end
GO
CREATE PROCEDURE dm.p_ip_organinfo(@i_rq numeric(8))
on exception resume
/*�����ͻ���Ϣ��*/
begin
  -- ��ʼ��
  delete from
    dm.t_ip_organinfo;
  insert into dm.t_ip_organinfo( client_id,branch_no,organ_name,instrepr_name,organ_code,sale_licence,company_kind,register_fund,register_money_type,contract_person,e_mail,nationality,address,business_range) 
    select a.client_id, --�ͻ����,
      a.branch_no, --Ӫҵ�����,
      null, --a.organ_name��������,
      a.instrepr_name, --���˴���,
      a.organ_code, --��֯��������,
      business_licence, --a.sale_licenceӪҵִ��,
      a.company_kind, --��ҵ����,
      a.register_fund, --ע���ʱ�,
      a.register_money_type, --ע���ʱ�����,
      a.relation_name, --a.contract_person��ϵ��,
      a.e_mail, --�����ʼ�,
      null, --a.nationality����,
      a.address, --��ַ,
      industry_range from --a.business_range��Ӫ��Χ      
      DBA.T_EDW_UF2_ORGANINFO as A where
      load_dt = @i_rq;
  ------��������-------------    
  update dm.t_ip_organinfo as a set
    organ_name = b.client_name,
    nationality = b.nationality from
    dm.t_ip_organinfo as a,(select client_id,client_name,nationality from dba.T_EDW_UF2_CLIENT where load_dt = @i_rq) as b where
    a.client_id = b.client_id;
  commit work
end
GO
CREATE PROCEDURE dm.P_PUB_CUST(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)

BEGIN 
  
  /******************************************************************
  ������: �ͻ���Ϣά��
  ��д��: DCY
  ��������: 2017-11-14
  ��飺��ϴ�ͻ��������˿ͻ��ͻ����ͻ��ĸ������õ�������Ϣ
  *********************************************************************
  �޶���¼��   �޶�����    �޶���     �޸����ݼ�Ҫ˵��
               20180104     dcy      ��DBA.T_ODS_UF2_FUNDACCOUNT�滻Ϊ DBA.T_EDW_UF2_FUNDACCOUNT����ֹ��ʷ��ϴ����
			   20180129     dcy      ���꣬�£��ͻ���������ֶκϲ����¿ͻ���ţ�����Ҫ��
			   20180207     dcy      �ų�"�ܲ�ר���˻�"
			   20180320     dcy		 ���� IF_PROD_NEW_CUST IS '�Ƿ��Ʒ�¿ͻ�'
			   20180403     dcy      �Կͻ�������id ���ֻ��ţ�����Ƚ�������
  *********************************************************************/
  DECLARE @V_NIAN VARCHAR(4);
  DECLARE @V_YUE VARCHAR(2);
  DECLARE @V_QUNIAN VARCHAR(4); --ȥ�����
  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
	
 --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_PUB_CUST WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
 --������ֵ    
  SET @V_NIAN=(SELECT NIAN FROM DBA.T_DDW_D_RQ WHERE RQ = @V_BIN_DATE);
  SET @V_YUE=(SELECT YUE FROM DBA.T_DDW_D_RQ WHERE RQ = @V_BIN_DATE);
  SET @V_QUNIAN=(SELECT MAX(NIAN) FROM DBA.T_DDW_D_RQ WHERE NIAN < @V_NIAN);

 --PART1 �������ɼ�����ʱ��  
	--1,������Ч����������ʱ��
  SELECT 
  ZJZH
  ,SUM(LJJYL_M) AS LJJYL
  ,MAX(ZZCH_YRJ) AS ZCFZ INTO #TEMP_VALID_CUST 
  FROM(
		SELECT NIAN,YUE,ZJZH,
		  GJJYL_M+XYJYL_M+PTJYL_M+QQJYL_M AS LJJYL_M --�ۼƽ�����
		  ,ZZC_YRJ+QQSZ_YRJ AS ZZCH_YRJ 
		  FROM DBA.TMP_DDW_KHQJT_M_D AS A 
		  WHERE NIAN || YUE >= @V_QUNIAN || @V_YUE AND NIAN || YUE < @V_NIAN || @V_YUE --һ������
		UNION
		SELECT @V_NIAN AS NIAN
		,@V_YUE AS YUE
		,FUND_ACCOUNT AS ZJZH
		,GJJYL_M+XYJYL_M+PTJYL_M+QQJYL_M AS LJJYL_M
		,ZZC_YRJ+QQSZ_YRJ AS ZZCH_YRJ
		FROM DBA.T_DDW_CLIENT_INDEX_HIGH_PRIORITY
		WHERE RQ = @V_BIN_DATE
	   ) AS A
    GROUP BY A.ZJZH;
	COMMIT;
	
	--2,��������
   SELECT A.CLIENT_ID
    ,CASE WHEN A.BIRTHDAY>='19000100' AND A.BIRTHDAY<='20200100' THEN A.BIRTHDAY 
          WHEN B.BIRTHDAY>=19000100 AND B.BIRTHDAY<=20200100 THEN CONVERT(VARCHAR,B.BIRTHDAY)
		  END BIRTHDAY 
    INTO #TMP_AGE 
    FROM (SELECT CLIENT_ID, CASE WHEN LENGTH(RTRIM(ID_NO))=18  AND SUBSTR(ID_NO,7,8) NOT LIKE '%[^0-9]%' THEN SUBSTR(ID_NO,7,8) 
                              WHEN  LENGTH(RTRIM(ID_NO))=15 AND SUBSTR(ID_NO,7,6) NOT LIKE '%[^0-9]%' THEN '19'||SUBSTR(ID_NO,7,6) 
							  END BIRTHDAY 
		   FROM DBA.T_EDW_UF2_CLIENT 
		   WHERE LOAD_DT=@V_BIN_DATE) A
    LEFT JOIN DBA.T_EDW_UF2_CLIENTINFO B ON A.CLIENT_ID=B.CLIENT_ID  AND B.LOAD_DT=@V_BIN_DATE;
	COMMIT;
	
    --3,����������Ϣ
	SELECT A.CLIENT_ID, A.USER_ID, B.USER_NAME      --���������õ���������
	INTO #OAS
    FROM(
		SELECT CLIENT_ID, MAX(USER_ID) AS USER_ID
		FROM DBA.GT_ODS_AFA2_SERAFA_RELATION
		WHERE LOAD_DT=@V_BIN_DATE AND IS_MAINSERV='1'
		GROUP BY CLIENT_ID
      	) A
    LEFT JOIN DBA.GT_ODS_AFA2_XTGL_USER B ON B.LOAD_DT=@V_BIN_DATE AND A.USER_ID=B.USER_ID;
	COMMIT;
	
    --4,������������������    ���ظ�ֵ
    SELECT MAX(B.ACTIVITY_NAME)ACTIVITY_NAME, MAX(A.ACTIVITY_ID)ACTIVITY_ID,A.FUND_ACCOUNT   --������������������    
	INTO #TCO
	FROM DBA.T_EDW_LC_T_CLIENT_OUTSYSCLIENT A
	LEFT JOIN DBA.T_EDW_CF_T_INFO_ACTIVITY  B ON A.ACTIVITY_ID=B.ACTIVITY_ID AND B.LOAD_DT = @V_BIN_DATE
	WHERE A.LOAD_DT=@V_BIN_DATE AND FUND_ACCOUNT !=''
	GROUP BY A.FUND_ACCOUNT;
	COMMIT;

	
 --PART2 ��ÿ�ղɼ������ݷ�����ʱ��
 
	SELECT
	 OUC.CLIENT_ID AS CUST_ID  --�ͻ�����
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --��
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --��
	,OUF.FUND_ACCOUNT  AS MAIN_CPTL_ACCT    --���ʽ��˺ţ���ͨ�˻���
	,DOH.PK_ORG  AS WH_ORG_ID               --�ֿ�������� 
	,CONVERT(VARCHAR,OUC.BRANCH_NO) AS HS_ORG_ID  --������������
	,DOH.HR_NAME AS BRH_NAME        --Ӫҵ������
	,DOH.FATHER_BRANCH_NAME_ROOT AS SEPT_CORP_NAME --�ֹ�˾����
	,OUC.CLIENT_NAME AS CUST_NAME    --�ͻ����� 
	,OUC.ORGAN_FLAG  AS CUST_TYPE    --�ͻ�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUC.ORGAN_FLAG) 
	  AND OUS.DICT_ENTRY=1048) AS CUST_TYPE_NAME   --�ͻ���������
	,CONVERT(VARCHAR,OUF.CLIENT_GROUP) AS CUST_GROUP  --�ͻ�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUF.CLIENT_GROUP) AND OUS.DICT_ENTRY=1051) AS CUST_GROUP_NAME   --�ͻ���������  
	,CONVERT(VARCHAR,OUC.CORP_RISK_LEVEL) AS CUST_RISK_RAK         --�ͻ����յȼ� 
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
      WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUC.CORP_RISK_LEVEL) AND OUS.DICT_ENTRY=2505) AS CUST_RISK_RAK_NAME   --�ͻ����յȼ�����  
	,OUC.CLIENT_STATUS AS CUST_STAT	--�ͻ�״̬  
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.CLIENT_STATUS AND OUS.DICT_ENTRY=1000) AS CUST_STAT_NAME    --�ͻ�״̬���� 
    ,OUC.CLIENT_GENDER AS GENDER --�Ա�
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.CLIENT_GENDER AND OUS.DICT_ENTRY=1049) AS GENDER_NAME    --�Ա�����
    ,CASE WHEN SUBSTR(TA.BIRTHDAY,5,4)<=SUBSTR(CONVERT(VARCHAR,GETDATE(),112),5,4)
              THEN CONVERT(INT,SUBSTR(CONVERT(VARCHAR,GETDATE(),112),1,4))-CONVERT(INT,SUBSTR(TA.BIRTHDAY,1,4))
              ELSE CONVERT(INT,SUBSTR(CONVERT(VARCHAR,GETDATE(),112),1,4))-CONVERT(INT,SUBSTR(TA.BIRTHDAY,1,4))-1
                 END  AS AGE  --����
	,OUCI.DEGREE_CODE AS EDU --ѧ��
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUCI.DEGREE_CODE AND OUS.DICT_ENTRY=1046) AS EDU_NAME    --ѧ������
	,OUC.NATIONALITY  AS NATI --���� 
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.NATIONALITY AND OUS.DICT_ENTRY=1040) AS NATI_NAME    --��������
	,OUC.ID_KIND AS ID_TYPE   --֤�����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=OUC.ID_KIND AND OUS.DICT_ENTRY=1041) AS ID_TYPE_NAME    --֤���������
	,OUC.ID_NO        --֤������
	,OAS.USER_ID AS MAIN_SERV_PSN_ID     --�������˱���
	,OAS.USER_NAME AS MAIN_SERV_PSN_NAME   --������������
	,CONVERT(VARCHAR,TCO.ACTIVITY_ID) AS NET_OPEN_CHN --��������  
	,CASE WHEN TCO.FUND_ACCOUNT IS NOT NULL THEN 1 ELSE 0 END AS IF_NET_OPEN       --�Ƿ�����
	,TCO.ACTIVITY_NAME AS CHN_NAME --��������
	,WUP.REFERER_NAME AS NET_OPEN_BROK--����������
	,OUCI.MOBILE_TEL AS MOB_NO --�ֻ���
	,CASE WHEN TBR.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END AS IF_BROK_CUST      --�Ƿ񾭼��˿ͻ�
	,CASE WHEN TBR2.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END AS IF_BROK_QUAF_CUST --�Ƿ񾭼��˺ϸ�ͻ� 
	,CASE WHEN OUF.CLIENT_GROUP IN (12,23,26,27,29,31,32,33,34,35,37,7,5) THEN 1 ELSE 0 END AS IF_PROD_CUST      --�Ƿ��Ʒ�ͻ�
	,CASE WHEN TVC.LJJYL >= 2000 OR TVC.ZCFZ >= 10000 THEN 1 ELSE 0 END AS IF_VLD     --�Ƿ���Ч
	,OUF.OPEN_DATE AS TE_OACT_DT   --���翪������
	,OUF.CANCEL_DATE AS CLOS_DT --��������
	,@V_BIN_DATE  AS LOAD_DT  --��ϴ����
	,CASE WHEN TAS.ZJGMCPRQ< CONVERT(NUMERIC(10),CONVERT(VARCHAR,DATEADD(YEAR,-3,CONVERT(DATE,@V_BIN_DATE||'',112)),112)) THEN 1 ELSE 0 END AS IF_PROD_NEW_CUST --�Ƿ��Ʒ�¿ͻ�:��36��û�й����Ʒ
	INTO #TMP_CUST
	
	FROM DBA.T_EDW_UF2_CLIENT OUC   --���пͻ���Ϣ
	--LEFT JOIN DBA.T_ODS_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID  AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --��ͨ�˻����ʽ��˺�
	LEFT JOIN DBA.T_edw_UF2_FUNDACCOUNT OUF ON OUC.CLIENT_ID=OUF.CLIENT_ID AND OUF.LOAD_DT=@V_BIN_DATE AND OUF.ASSET_PROP='0' AND OUF.MAIN_FLAG='1'  --��ͨ�˻����ʽ��˺�
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUC.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL    --���ظ�ֵ
	LEFT JOIN DBA.T_edw_UF2_CLIENTINFO OUCI ON OUC.CLIENT_ID=OUCI.CLIENT_ID AND OUCI.LOAD_DT=@V_BIN_DATE   --��ȡ���˿ͻ���Ϣ
	LEFT JOIN #OAS OAS ON OUC.CLIENT_ID=OAS.CLIENT_ID
	LEFT JOIN #TCO TCO ON OUF.FUND_ACCOUNT=TCO.FUND_ACCOUNT
	LEFT JOIN DBA.T_EDW_WSKH_USER_PRESENCE WUP ON OUC.CLIENT_ID=WUP.USER_NO AND WUP.LOAD_DT=@V_BIN_DATE AND WUP.USER_NO !=''  --��ȡ����������
	LEFT JOIN DBA.T_EDW_BRK_T_BROK_RELATION TBR ON OUC.CLIENT_ID=TBR.CLIENT_ID AND TBR.LOAD_DT = @V_BIN_DATE AND TBR.RELATION_STATUS ='1'  --�Ƿ񾭼��˿ͻ�
	LEFT JOIN DBA.T_EDW_BRK_T_BROK_RELATION TBR2 ON OUC.CLIENT_ID=TBR2.CLIENT_ID AND TBR2.LOAD_DT = @V_BIN_DATE AND TBR2.RELATION_STATUS ='1' AND TBR2.RELATION_TYPE='4'
	LEFT JOIN #TEMP_VALID_CUST TVC ON OUF.FUND_ACCOUNT=TVC.ZJZH  --�Ƿ���Ч��
	LEFT JOIN #TMP_AGE TA ON OUC.CLIENT_ID=TA.CLIENT_ID  --����
	LEFT JOIN DBA.T_AFA_SCWY TAS ON OUF.FUND_ACCOUNT=TAS.ZJZH AND TAS.RQ=@V_BIN_DATE  --�Ƿ��Ʒ�¿ͻ�:��36��û�й����Ʒ
    WHERE OUC.LOAD_DT=@V_BIN_DATE 
	;
	COMMIT;


	--PART2.2 ���ͻ������е�/�滻��
	UPDATE #TMP_CUST
	SET 
	    --CUST_NAME=REPLACE(REPLACE(REPLACE(CUST_NAME,'/',''),'\',''),'|',''),     --�ͻ����� ,���ɫ������\���𣬲���Ӱ��SQL����
	    --MOB_NO=REPLACE(REPLACE(REPLACE(MOB_NO,'/',''),'\',''),'|',''),     
	    --main_serv_psn_name=REPLACE(REPLACE(REPLACE(main_serv_psn_name,'/',''),'\',''),'|','')
		 CUST_NAME=SUBSTR(CUST_NAME,1,0)||'***'   --��������
		,MOB_NO=SUBSTR(MOB_NO,1,3)||'********'   --�ֻ�������
		,MAIN_SERV_PSN_NAME=SUBSTR(MAIN_SERV_PSN_NAME,1,0)||'********'   --����������������
		,ID_NO=SUBSTR(ID_NO,1,0)||'***********'   --֤����������
	;
	COMMIT;
	

	
	--3 ��󽫵��������Ŀͻ��������
	INSERT INTO DM.T_PUB_CUST
	(
	 CUST_ID           --�ͻ�����  
	,YEAR              --��
	,MTH               --��
	,MAIN_CPTL_ACCT    --���ʽ��˺�  
	,WH_ORG_ID         --�ֿ��������
	,HS_ORG_ID         --������������
	,BRH_NAME          --Ӫҵ������ 
	,SEPT_CORP_NAME   --�ֹ�˾����  
	,CUST_NAME        --�ͻ����� 
	,CUST_TYPE        --�ͻ�����
	,CUST_TYPE_NAME   --�ͻ���������
	,CUST_GROUP       --�ͻ����� 
	,CUST_GROUP_NAME  --�ͻ��������� 
	,CUST_RISK_RAK     --�ͻ����յȼ� 
	,CUST_RISK_RAK_NAME   --�ͻ����յȼ����� 
	,CUST_STAT         --�ͻ�״̬ 
	,CUST_STAT_NAME    --�ͻ�״̬����
	,GENDER            --�Ա� 
	,GENDER_NAME       --�Ա�����
	,AGE               --���� 
	,EDU               --ѧ�� 
	,EDU_NAME          --ѧ������
	,NATI              --���� 
	,NATI_NAME         --��������
	,ID_TYPE           --֤����� 
	,ID_TYPE_NAME      --֤���������
	,ID_NO             --֤������ 
	,MAIN_SERV_PSN_ID  --�������˱��� 
	,MAIN_SERV_PSN_NAME  --������������ 
	,NET_OPEN_CHN      --�������� 
	,IF_NET_OPEN       --�Ƿ����� 
	,CHN_NAME          --�������� 
	,NET_OPEN_BROK     --���������� 
	,MOB_NO            --�ֻ��� 
	,IF_BROK_CUST      --�Ƿ񾭼��˿ͻ� 
	,IF_BROK_QUAF_CUST --�Ƿ񾭼��˺ϸ�ͻ� 
	,IF_PROD_CUST      --�Ƿ��Ʒ�ͻ� 
	,IF_VLD            --�Ƿ���Ч 
	,TE_OACT_DT        --���翪������ 
	,CLOS_DT           --�������� 
	,LOAD_DT           --��ϴ���� 
	,YEAR_MTH_CUST_ID
	,IF_PROD_NEW_CUST
	)
	SELECT 
	 CUST_ID           --�ͻ�����  
	,YEAR              --��
	,MTH               --��
	,MAIN_CPTL_ACCT    --���ʽ��˺�  
	,WH_ORG_ID         --�ֿ��������
	,HS_ORG_ID         --������������
	,BRH_NAME          --Ӫҵ������ 
	,SEPT_CORP_NAME   --�ֹ�˾����  
	,CUST_NAME        --�ͻ����� 
	,CUST_TYPE        --�ͻ�����
	,CUST_TYPE_NAME   --�ͻ���������
	,CUST_GROUP       --�ͻ����� 
	,CUST_GROUP_NAME  --�ͻ��������� 
	,CUST_RISK_RAK     --�ͻ����յȼ� 
	,CUST_RISK_RAK_NAME   --�ͻ����յȼ����� 
	,CUST_STAT         --�ͻ�״̬ 
	,CUST_STAT_NAME    --�ͻ�״̬����
	,GENDER            --�Ա� 
	,GENDER_NAME       --�Ա�����
	,AGE               --���� 
	,EDU               --ѧ�� 
	,EDU_NAME          --ѧ������
	,NATI              --���� 
	,NATI_NAME         --��������
	,ID_TYPE           --֤����� 
	,ID_TYPE_NAME      --֤���������
	,ID_NO             --֤������ 
	,MAIN_SERV_PSN_ID  --�������˱��� 
	,MAIN_SERV_PSN_NAME  --������������ 
	,NET_OPEN_CHN      --�������� 
	,IF_NET_OPEN       --�Ƿ����� 
	,CHN_NAME          --�������� 
	,NET_OPEN_BROK     --���������� 
	,MOB_NO            --�ֻ��� 
	,IF_BROK_CUST      --�Ƿ񾭼��˿ͻ� 
	,IF_BROK_QUAF_CUST --�Ƿ񾭼��˺ϸ�ͻ� 
	,IF_PROD_CUST      --�Ƿ��Ʒ�ͻ� 
	,IF_VLD            --�Ƿ���Ч 
	,TE_OACT_DT        --���翪������ 
	,CLOS_DT           --�������� 
	,LOAD_DT           --��ϴ���� 
	,year||mth||CUST_ID AS YEAR_MTH_CUST_ID  --20180129����
	,IF_PROD_NEW_CUST  --�Ƿ��Ʒ�¿ͻ�
	FROM #TMP_CUST  TC
	WHERE HS_ORG_ID NOT IN ('5','55','51','44','9999')--20180207 �������ų�"�ܲ�ר���˻�"
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_CUST TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_CUST TO xydc
GO
CREATE PROCEDURE dm.P_PUB_CUST_LIMIT_M_D(IN @v_date int)
begin 
  
  /******************************************************************
  ������: �ͻ�Ȩ�ޱ�(�´洢�ո���)
  ��д��: ����
  ��������: 2017-12-06
  ��飺���¼�¼�ͻ�Ȩ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
  *********************************************************************/
  
  declare @v_year varchar(4);		-- ���
  declare @v_month varchar(2);	-- �·�
  declare @v_begin_trad_date int;	-- ���¿�ʼ������
  declare @v_sy varchar(6);
  
	commit;
	
	set @v_year = substring(convert(varchar,@v_date),1,4);
	set @v_month = substring(convert(varchar,@v_date),5,2);
	set @v_begin_trad_date = (select min(RQ) from dba.t_ddw_d_rq where sfjrbz='1' and nian=@v_year and yue=@v_month);
    set @v_sy=(select max(nian||yue) from dba.t_ddw_d_rq where nian||yue<@v_year||@v_month);

	DELETE FROM DM.T_PUB_CUST_LIMIT_M_D WHERE "YEAR"=@v_year and MTH=@v_month;
	
	INSERT INTO DM.T_PUB_CUST_LIMIT_M_D(CUST_ID,"YEAR",MTH,OCCUR_DT,MAIN_CPTL_ACCT)
	SELECT a.client_id as CUST_ID
	    ,@v_year as "YEAR"
	    ,@v_month as MTH
	    ,@v_date as OCCUR_DT
	    ,b.MAIN_CPTL_ACCT
	FROM DBA.T_EDW_UF2_CLIENT a
	LEFT JOIN (
	    SELECT CLIENT_ID, MAX(FUND_ACCOUNT) AS MAIN_CPTL_ACCT
	    FROM DBA.T_EDW_UF2_FUNDACCOUNT
	    WHERE LOAD_DT=@v_date
	    AND MAIN_FLAG='1' AND ASSET_PROP='0'
	    GROUP BY CLIENT_ID
	) b on a.CLIENT_ID=b.CLIENT_ID
	WHERE a.LOAD_DT=@v_date;

	-- ֤ȯ�˻���
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET SECU_ACCTS = COALESCE(b.SECU_ACCTS,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT CLIENT_ID, COUNT(DISTINCT STOCK_ACCOUNT) as SECU_ACCTS
	    FROM DBA.t_edw_uf2_stockholder
	    WHERE LOAD_DT=@v_date
	    GROUP BY CLIENT_ID
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- ����ҵ��-����
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_STK_BIS = CASE WHEN COALESCE(gpyw_cnt,0)>=1 THEN 1 ELSE 0 END     -- �Ƿ�����Ʊҵ��
	    ,IF_BOND_BIS = CASE WHEN COALESCE(zqyw_cnt,0)>=1 THEN 1 ELSE 0 END    -- �Ƿ����ծȯҵ��
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT b.CLIENT_ID
	        ,SUM(CASE WHEN MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	            AND stock_type_cd IN ('10', 'A1', '17', '18')
	            THEN 1 ELSE 0 END) AS gpyw_cnt
	        ,SUM(CASE WHEN MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	           AND stock_type_cd IN ('12', '13', '14')
	           THEN 1 ELSE 0 END) AS zqyw_cnt
	    FROM dba.t_edw_t05_order_jour a
	    left join dba.T_ODS_UF2_FUNDACCOUNT b on a.fund_acct=b.FUND_ACCOUNT
	    WHERE load_dt between @v_begin_trad_date AND @v_date
	    GROUP BY b.CLIENT_ID
	) b on a.cust_id=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�����Ʊҵ��_�ۼ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_STK_BIS_GT = CASE WHEN b.FUND_ACCT IS NOT NULL THEN 1 ELSE 0 END      -- �Ƿ�����Ʊҵ��_�ۼ�
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT FUND_ACCT
	    FROM dba.t_edw_t05_order_jour a
	    WHERE load_dt <= @v_date
	    AND MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	    AND stock_type_cd IN ('10', 'A1', '17', '18')
	) b on a.MAIN_CPTL_ACCT=b.FUND_ACCT
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ����ծȯҵ��_�ۼ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_BOND_BIS_GT = CASE WHEN b.FUND_ACCT IS NOT NULL THEN 1 ELSE 0 END      -- �Ƿ�����Ʊҵ��_�ۼ�
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT FUND_ACCT
	    FROM dba.t_edw_t05_order_jour a
	    WHERE load_dt <= @v_date
	    AND MARKET_TYPE_CD IN ('01', '02', '03', '04', '05', '0G', '0S') 
	    AND stock_type_cd IN ('12', '13', '14')
	) b on a.MAIN_CPTL_ACCT=b.FUND_ACCT
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�������ȯ�ͻ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_CREDIT_CUST = CASE WHEN b.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT CLIENT_ID
	    FROM DBA.T_EDW_RZRQ_FUNDACCOUNT
	    WHERE LOAD_DT=@v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- TODO:�Ƿ�������ȯ��Ч�ͻ� IF_CREDIT_EFF_CUST
	-- TODO:�Ƿ�����������ȯ��Ч�� IF_NA_CREDIT_EFF_ACT

	-- ������ȯ���Ŷ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET CREDIT_CRED_QUO = coalesce(b.xyzhsxed,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    select convert(varchar,client_id) as client_id,
	        case when total_max_quota > 0 then total_max_quota
	        else finance_max_quota+shortsell_max_quota
	        end as xyzhsxed 
	    from dba.t_edw_rzrq_contract 
	    where load_dt = @v_date and contract_status = '0'
	) b on a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- ������ȯ��ͨ���ڡ�������ȯ��������
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET CREDIT_OPEN_DT = COALESCE(b.OPEN_DATE,0)
	    ,CREDIT_CLOS_DT = COALESCE(b.CANCEL_DATE,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN DBA.t_edw_rzrq_client b ON b.load_dt=@v_date AND a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- TODO:������ȯ��Ч������ CREDIT_EFF_ACT_DT

	-- �Ƿ����������ȯ����ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_CREDIT_CRED_BIS = CASE WHEN b.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT CONVERT(VARCHAR, client_id) AS CLIENT_ID 
	     FROM dba.t_edw_rzrq_hisdeliver
	    WHERE business_flag in (4211, 4212, 4213, 4214, 4215, 4216)   -- ���ý���
	      AND load_dt BETWEEN @v_begin_trad_date AND @v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ����������ȯ����ҵ��_�ۼ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_CREDIT_CRED_BIS_GT = CASE WHEN b.CLIENT_ID IS NOT NULL THEN 1 ELSE 0 END
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT DISTINCT CONVERT(VARCHAR, client_id) AS CLIENT_ID 
	     FROM dba.t_edw_rzrq_hisdeliver
	    WHERE business_flag in (4211, 4212, 4213, 4214, 4215, 4216)   -- ���ý���
	      AND load_dt <= @v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�Լ�����ؿͻ�����ͨԼ������Ȩ�ޣ����Ƿ񱨼ۻع��ͻ����Ƿ��Ʊ��Ѻ�ͻ����Ƿ���ڽ��׿ͻ�
	-- �Ƿ񻦸�ͨ�ͻ� �Ƿ����ͨ�ͻ� �Ƿ�ҵ��ͻ� �Ƿ�����ͻ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_CUST = coalesce(b.right_ydsgh,0)
	    ,IF_REPQ_CUST = coalesce(b.right_bjhg,0) 
	    ,IF_STKPLG_CUST = coalesce(b.right_gpzyhg,0) 
	    ,IF_BGDL_CUST = coalesce(b.right_dzjy,0) 
	    ,IF_HGT_CUST = coalesce(b.right_hgt,0)
	    ,IF_SGT_CUST = coalesce(b.right_sgt,0) 
	    ,IF_GEM_CUST = coalesce(b.right_cyb,0) 
	    ,IF_SB_CUST = coalesce(b.right_sb,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
	    SELECT CLIENT_ID
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%l%' THEN 1 ELSE 0 END) AS right_ydsgh
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%k%' THEN 1 ELSE 0 END) AS right_bjhg
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%t%' THEN 1 ELSE 0 END) AS right_gpzyhg
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%#%' THEN 1 ELSE 0 END) AS right_dzjy
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%z%' THEN 1 ELSE 0 END) AS right_hgt
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%c%' THEN 1 ELSE 0 END) AS right_sgt
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%j%' THEN 1 ELSE 0 END) AS right_cyb
	        ,MAX(CASE WHEN HOLDER_RIGHTS like '%a%' THEN 1 ELSE 0 END) AS right_sb
	    FROM DBA.T_EDW_UF2_STOCKHOLDER 
	    WHERE load_dt=@v_date
	    GROUP BY CLIENT_ID
	) b on a.cust_id=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- �Ƿ����Լ������ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_BIS = case when b.khbh_hs is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT distinct khbh_hs
	    FROM DBA.t_ddw_ydsgh_d
	    WHERE csjyje + ghjyje > 0
	    and rq between @v_begin_trad_date and @v_date
	) b on a.CUST_ID=b.khbh_hs
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ����Լ������ҵ��_�ۼ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_BIS = case when b.khbh_hs is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT distinct khbh_hs
	    FROM DBA.t_ddw_ydsgh_d
	    WHERE csjyje + ghjyje > 0
	) b on a.CUST_ID=b.khbh_hs
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- Լ���������Ŷ�� & ��Ʊ��Ѻ���Ŷ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET APPTBUYB_CRED_QUO = COALESCE(b.xsed_ydsgh,0)
	    ,STKPLG_CRED_QUO = COALESCE(b.xsed_gpzy,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    select CLIENT_ID
	        ,SUM(CASE WHEN EN_CBPBUSI_TYPE='002' THEN ARP_CREDIT_QUOTA ELSE 0 END) AS xsed_ydsgh
	        ,SUM(CASE WHEN EN_CBPBUSI_TYPE='004' THEN ARP_CREDIT_QUOTA ELSE 0 END) AS xsed_gpzy
	    from dba.GT_ODS_HS06_ARPCRQUOTA
	    WHERE load_dt=@v_date
	    GROUP BY CLIENT_ID
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- Լ�����ؿ�ͨ���� ���ۻع���ͨ���� ��Ʊ��Ѻ��ͨ���� ��ҵ�忪ͨ����
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET APPTBUYB_OPEN_DT = COALESCE(b.ktrq_ydsgh,0)
	    ,REPQ_OPEN_DT = COALESCE(b.ktrq_bjhg,0)
	    ,STKPLG_OPEN_DT = COALESCE(b.ktrq_gpzy,0)
	    ,GEM_OPEN_DT = coalesce(b.ktrq_cyb,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN(
	    SELECT CLIENT_ID
	        , MAX(CASE WHEN BUSINESS_FLAG=1444 THEN INIT_DATE ELSE 0 END) AS ktrq_ydsgh
	        , MAX(CASE WHEN BUSINESS_FLAG=1443 THEN INIT_DATE ELSE 0 END) AS ktrq_bjhg
	        , MAX(CASE WHEN BUSINESS_FLAG=1477 THEN INIT_DATE ELSE 0 END) AS ktrq_gpzy
	        , MAX(CASE WHEN BUSINESS_FLAG in (1424,1425) THEN INIT_DATE ELSE 0 END) AS ktrq_cyb
	    FROM (
	        SELECT CLIENT_ID, INIT_DATE, BUSINESS_FLAG
	        FROM DBA.GT_ODS_ZHXT_HIS_STOCKHOLDERJOUR
	        WHERE load_dt<=@v_date
	        UNION
	        SELECT CLIENT_ID, INIT_DATE, BUSINESS_FLAG
	        FROM DBA.T_EDW_UF2_HIS_OFSTOCKHOLDERJOUR
	        WHERE load_dt<=@v_date
	    ) t
	    GROUP BY t.client_id
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ����Լ������ǩԼ����ǰ�Ƿ���ǩԼ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_APPTBUYB_SUBSCR = case when b.client_id is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT client_id
	    FROM dba.t_edw_arpcontract 
	    WHERE load_dt=@v_date
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ���뱨�ۻع�ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_REPQ_BIS = case when b.zjzh is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT distinct zjzh
	    FROM dba.t_ddw_bjhg_d 
	    WHERE rq<=@v_date
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- �Ƿ����ծȯ��ع�ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_BOND_R_REPUR_BIS = case when b.zjzh is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT fund_acct AS zjzh
	     FROM dba.t_edw_t05_trade_jour
	    WHERE load_dt BETWEEN @v_begin_trad_date AND @v_date
	      AND busi_cd = '3703'
	    GROUP BY zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�����ծ��ع�ҵ��_�ۼ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_TREA_R_REPUR_BIS_GT = case when b.zjzh is not null then 1 else 0 end
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT fund_acct AS zjzh
	     FROM dba.t_edw_t05_trade_jour
	    WHERE load_dt<=@v_date
	      AND busi_cd = '3703'
	    GROUP BY zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- ��Ʊ��Ѻ�״ν������� & �����Ѻ��������
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET STKPLG_FST_TRD_DT = COALESCE(b.gpzyscjysj,0)
	    ,RCT_PLG_APP_DT = COALESCE(b.zjzysqrq,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT zjzh
	        , MIN(qyrq) gpzyscjysj
	        , MAX(qyrq) zjzysqrq
	    FROM DBA.t_ddw_gpzyhg_ht_d
	    GROUP BY zjzh
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- TODO:���ڽ��׿�ͨ����

	-- �Ƿ���뻦��ͨҵ�� �Ƿ�������ͨҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_HGT_BIS = coalesce(b.cyyw_hgt,0)
		,IF_SGT_BIS = coalesce(b.cyyw_sgt,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT fund_acct as zjzh
	        ,max(case when market_type_cd='0G' then 1 else 0 end) as cyyw_hgt
	      	,max(case when market_type_cd='0S' then 1 else 0 end) as cyyw_sgt
	    FROM dba.T_EDW_T05_TRADE_JOUR 
	    WHERE load_dt between @v_begin_trad_date and @v_date
	    group by fund_acct
	) b ON a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- ����ͨ��ͨ���� ���ͨ��ͨ����
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET HGT_OPEN_DT =  COALESCE(b.ktsj_hgt,0)
		,SGT_OPEN_DT = COALESCE(b.ktsj_sgt,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT FUND_ACCOUNT
	        ,MAX(CASE WHEN EXCHANGE_TYPE='G' THEN open_date ELSE 0 END) as ktsj_hgt
	      	,MAX(CASE WHEN EXCHANGE_TYPE='S' THEN open_date ELSE 0 END) as ktsj_sgt
	    FROM DBA.T_EDW_UF2_CBSSTOCKHOLDER
	    WHERE LOAD_DT=@v_date
	    GROUP BY FUND_ACCOUNT
	) b ON a.MAIN_CPTL_ACCT=b.FUND_ACCOUNT
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ��л�AȨ�� �Ƿ�����AȨ�� �Ϻ�֤ȯ�˻���ͨ���� ����֤ȯ�˻���ͨ����
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET IF_HA_RIGH =  COALESCE(b.qx_ha,0)
		,IF_SA_RIGH = COALESCE(b.qx_sa,0)
		,SH_SECU_ACC_OPEN_DT = COALESCE(b.ktrq_sh,0)
		,SZ_SECU_ACC_OPEN_DT = COALESCE(b.ktrq_sz,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
	    SELECT CLIENT_ID
	        ,MAX(CASE WHEN EXCHANGE_TYPE='1' then 1 else 0 end) as qx_ha
	      	,MAX(CASE WHEN EXCHANGE_TYPE='2' then 1 else 0 end) as qx_sa
	      	,MAX(CASE WHEN EXCHANGE_TYPE='1' THEN OPEN_DATE ELSE 0 END) AS ktrq_sh
	      	,MAX(CASE WHEN EXCHANGE_TYPE='2' THEN OPEN_DATE ELSE 0 END) AS ktrq_sz
	    FROM DBA.T_EDW_UF2_STOCKHOLDER
	    WHERE LOAD_DT=@v_date and HOLDER_STATUS='0'
	    GROUP BY CLIENT_ID
	) b ON a.CUST_ID=b.CLIENT_ID
	WHERE a."year"=@v_year AND a.mth=@v_month;



	-- �Ƿ�����˻��ͻ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_ACC_CUST = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_edw_OFSTOCKHOLDER
		where load_dt=@v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- TODO:�Ƿ���л���Ͷ

	-- �Ƿ�������Ͷҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_CASTSL_BIS = case when b.zjzh is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select distinct fund_acct as zjzh
			from dba.T_EDW_T05_TRADE_JOUR
			where busi_cd='5139' 
			and load_dt between @v_begin_trad_date and @v_date
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�������ר��ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_SPACCT_BIS = coalesce(b.cyyw_jjzh_m,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select a.zjzh
				,MAX(CASE WHEN b.lx = '����ר��'    THEN 1 ELSE 0 END) AS cyyw_jjzh_m
			from dba.t_ddw_xy_jjzb_d a
			left join (
					SELECT jjdm,lx
					FROM dba.t_ddw_d_jj
					WHERE nian || yue = (SELECT MAX(nian || yue)
						FROM dba.t_ddw_d_jj
						WHERE nian || yue < CONVERT(VARCHAR(6), FLOOR(@v_date / 100)))
					) b ON a.jjdm = b.jjdm
			where rq between @v_begin_trad_date and @v_date
			group by a.zjzh
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- �Ƿ�������ר��ҵ��_�ۼ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_FUND_SPACCT_BIS_GT = coalesce(b.cyyw_jjzh,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select a.zjzh
				,MAX(CASE WHEN b.lx = '����ר��'    THEN 1 ELSE 0 END) AS cyyw_jjzh
			from dba.t_ddw_xy_jjzb_d a
			left join (
					SELECT jjdm,lx
					FROM dba.t_ddw_d_jj
					WHERE nian || yue = (SELECT MAX(nian || yue)
						FROM dba.t_ddw_d_jj
						WHERE nian || yue < CONVERT(VARCHAR(6), FLOOR(@v_date / 100)))
					) b ON a.jjdm = b.jjdm
			where rq <= @v_date
			group by a.zjzh
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ������Ȩ�ͻ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_PSTK_OPTN_CUST = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_EDW_UF2_OPTFUNDACCOUNT
		where load_dt=@v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- ������Ȩ��ͨ����
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	SET PSTK_OPTN_OPEN_DT = coalesce(b.open_date,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN (
		select client_id
			,open_date
		FROM dba.T_EDW_UF2_FUNDACCOUNT 
		WHERE LOAD_DT=@v_date 
		and ASSET_PROP='B' and FUNDACCT_STATUS='0'
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- ������Ȩ�״ν�������
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set PSTK_OPTN_FST_TRD_DT = coalesce(b.qqscjyrq,0)
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			select client_id, min(load_dt) as qqscjyrq 
			from (
				select load_dt, client_id
				from dba.GT_ODS_HS08OPT_HIS_OPTDELIVER
				where load_dt<=@v_date
				union
				select load_dt, client_id
				from dba.T_EDW_UF2_HIS_OPTDELIVER
				where load_dt<=@v_date
			) t 
			group by client_id
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �״ν�������
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set FST_TRD_DT = coalesce(b.scjyrq,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			SELECT fund_acct,min(load_dt) scjyrq
			FROM DBA.t_edw_t05_trade_jour
			WHERE busi_cd IN ('3101', '3102',   -- ��������
												'3408', '9994',         -- ���ڽ��_�Ϲ�ȷ��_��
												'5122',                 -- ���ڽ��_�깺ȷ��_��
												'5139',                 -- ���ڽ��_��ʱ����Ͷ��ȷ��_��
												'5124')                 -- ���ڽ��_���ȷ��_��
			GROUP BY fund_acct
	) b on a.MAIN_CPTL_ACCT=b.fund_acct
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ϻ��״ν�������
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set SH_FST_TRD_DT = coalesce(b.scjyrq_sh,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			SELECT fund_acct,min(load_dt) scjyrq_sh
			FROM DBA.t_edw_t05_trade_jour
			WHERE busi_cd IN ('3101', '3102',   -- ��������
												'3408', '9994',         -- ���ڽ��_�Ϲ�ȷ��_��
												'5122',                 -- ���ڽ��_�깺ȷ��_��
												'5139',                 -- ���ڽ��_��ʱ����Ͷ��ȷ��_��
												'5124')                 -- ���ڽ��_���ȷ��_��
			and market_type_cd='01'
			GROUP BY fund_acct
	) b on a.MAIN_CPTL_ACCT=b.fund_acct
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �����״ν�������
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set SZ_FST_TRD_DT = coalesce(b.scjyrq_sz,0)
	FROM DM.T_PUB_CUST_LIMIT_M_D a
	left join (
			SELECT fund_acct,min(load_dt) scjyrq_sz
			FROM DBA.t_edw_t05_trade_jour
			WHERE busi_cd IN ('3101', '3102',   -- ��������
												'3408', '9994',         -- ���ڽ��_�Ϲ�ȷ��_��
												'5122',                 -- ���ڽ��_�깺ȷ��_��
												'5139',                 -- ���ڽ��_��ʱ����Ͷ��ȷ��_��
												'5124')                 -- ���ڽ��_���ȷ��_��
			and market_type_cd='02'
			GROUP BY fund_acct
	) b on a.MAIN_CPTL_ACCT=b.fund_acct
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�֤ͨȯ���
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set IF_SECU_CHRM = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_EDW_UF2_PRODSECUMHOLDER
		where load_dt=@v_date
		and PRODHOLDER_STATUS='0'
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;


	-- �Ƿ���֤ȯ��Ʋ�Ʒ
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_PURC_SECU_CHRM_PROD = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	LEFT JOIN(
		select distinct client_id
		from dba.GT_ODS_ZHXT_HIS_SECUMDELIVER
		where load_dt between @v_begin_trad_date and @v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�ͨ�������
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	set IF_BANK_CHRM = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.T_EDW_UF2_PRODSECUMHOLDER
		where load_dt=@v_date
		and PRODHOLDER_STATUS='0'
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�����������ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_BANK_CHRM_BIS = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.GT_ODS_ZHXT_HIS_BANKMENTRUST
		where load_dt between @v_begin_trad_date and @v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�����������ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
		set IF_BANK_CHRM_BIS = case when b.client_id is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct client_id
		from dba.GT_ODS_ZHXT_HIS_BANKMENTRUST
		where load_dt <= @v_date
	) b on a.CUST_ID=b.client_id
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ����B��
	update DM.T_PUB_CUST_LIMIT_M_D
	set IF_HLD_B_SHR = case when b.zjzh is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
		select distinct zjzh
		from dba.T_DDW_F00_KHMRCPYKHZ_D
		where load_Dt=@v_date
		and zqlx in ('17','18')
	) b on a.MAIN_CPTL_ACCT=b.zjzh
	WHERE a."year"=@v_year AND a.mth=@v_month;

	-- �Ƿ�����ͻ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_ROOTNET_CUST = CASE WHEN t2.zjzh IS NOT NULL THEN 1 ELSE 0 END     -- �Ƿ�����ͻ�
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT CONVERT(VARCHAR, CONVERT(numeric(30,0), acctid)) AS zjzh
	               FROM dba.t_edw_tr_getf_tradinglog
	              GROUP BY zjzh
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;
	     
	-- �Ƿ��ʹܵ���ǩ���ͻ�
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_ASSM_ELEC_SIGNAT_CUST = CASE WHEN t2.zjzh IS NOT NULL THEN 1 ELSE 0 END     -- �Ƿ��ʹܵ���ǩ��
	  FROM dba.DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT fund_acct AS zjzh
	               FROM dba.t_edw_t01_fund_acct 
	              WHERE client_rights LIKE '%e%'
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;

	-- �Ƿ��ܿͻ�
	  UPDATE DM.T_PUB_CUST_LIMIT_M_D
	     SET IF_JD_CUST = CASE WHEN t2.zjzh_x IS NOT NULL THEN 1 ELSE 0 END     -- �Ƿ��ܿͻ�
	    FROM DM.T_PUB_CUST_LIMIT_M_D t1
	    LEFT JOIN (SELECT DISTINCT b.zjzh_x
	                 FROM dba.gt_ods_jindunkh a
	                 LEFT JOIN dba.t_ddw_d_khdz b ON a.zjzh = b.zjzh
	                WHERE load_dt = @v_date
	              ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh_x
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;

	-- �Ƿ�����д��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_MULIT_BANK_DEPO = CASE WHEN t2.zjzh_x IS NOT NULL THEN 1 ELSE 0 END     -- �Ƿ�����д��
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT zjzh_x
	               FROM dba.t_ddw_d_khdz
	              GROUP BY zjzh_x
	             HAVING COUNT(DISTINCT zjzh) >= 2 
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh_x
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;

	-- �Ƿ��С��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_NON_TRD = CASE WHEN t2.zjzh IS NOT NULL THEN 1 ELSE 0 END     -- �Ƿ��С��
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT zjzh
	               FROM dba.t_edw_dxfkhmd
	              WHERE nian || yue = (SELECT MAX(nian || yue) 
	                                     FROM dba.t_edw_dxfkhmd)
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;
	   
	-- TODO:�Ƿ��ڻ��ͻ� IF_FUTR_CUST

	-- �Ƿ������¹�ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_STAGGING_BIS = CASE WHEN t2.zjzh IS NULL THEN 0 ELSE 1 END
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT a.fund_acct AS zjzh
	               FROM dba.t_edw_t05_trade_jour a
	              WHERE a.load_dt BETWEEN @v_begin_trad_date AND @v_date
	                AND a.busi_type_cd IN ('3406') 
	                AND a.stock_type_cd IN ('35', '32')
	                AND a.market_type_cd IN ('01', '02', '03', '04', '05', '0G','0S')	/*2014-11-28���ӻ���ͨ�г����� 2016-11-18�������ͨҵ��*/
	                AND a.trad_amt > 0
	              GROUP BY zjzh
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;


	-- �Ƿ������¹�ҵ��
	UPDATE DM.T_PUB_CUST_LIMIT_M_D
	   SET IF_STAGGING_BIS_GT = CASE WHEN t2.zjzh IS NULL THEN 0 ELSE 1 END
	  FROM DM.T_PUB_CUST_LIMIT_M_D t1
	  LEFT JOIN (SELECT a.fund_acct AS zjzh
	               FROM dba.t_edw_t05_trade_jour a
	              WHERE a.load_dt <= @v_date
	                AND a.busi_type_cd IN ('3406') 
	                AND a.stock_type_cd IN ('35', '32')
	                AND a.market_type_cd IN ('01', '02', '03', '04', '05', '0G','0S')	/*2014-11-28���ӻ���ͨ�г����� 2016-11-18�������ͨҵ��*/
	                AND a.trad_amt > 0
	              GROUP BY zjzh
	            ) t2 ON t1.MAIN_CPTL_ACCT = t2.zjzh
	 WHERE t1."year" = @v_year
	   AND t1.mth = @v_month;
	   
	-- �Ƿ������˺�
	update DM.T_PUB_CUST_LIMIT_M_D
	set if_spca_acct = case when b.zjzh is not null then 1 else 0 end
	from DM.T_PUB_CUST_LIMIT_M_D a
	left join (
	    select distinct column_a as zjzh 
	    from dba.gt_ods_bbdr_org 
	    where nian ||yue = @v_year||@v_month 
	    and report_cd = 'tszhmd-A1' and row_num >= 2
	) b on a.main_cptl_acct=b.zjzh
	where a.year||a.mth=@v_year||@v_month;
    	   
    -- �Ƿ�������ȯ��Ч�ͻ� IF_CREDIT_EFF_CUST
    update DM.T_PUB_CUST_LIMIT_M_D
    set IF_CREDIT_EFF_CUST = coalesce(b.sfrzrqyxh, 0 )
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join dba.tmp_ddw_khqjt_m_d b on a.year=b.nian and a.mth=b.yue and a.main_cptl_acct=b.zjzh
	where a.year||a.mth=@v_year||@v_month;

    -- �Ƿ�����������ȯ��Ч�� if_na_credit_eff_act
    -- ������ȯ��Ч������ credit_eff_act_dt
    update DM.T_PUB_CUST_LIMIT_M_D
    set if_na_credit_eff_act = case when a.IF_CREDIT_EFF_CUST=1 and coalesce(b.IF_CREDIT_EFF_CUST,0)=0 then 1 else 0 end
        ,credit_eff_act_dt = case when a.IF_CREDIT_EFF_CUST=1 and coalesce(b.IF_CREDIT_EFF_CUST,0)=0 then convert(int,@v_year||@v_month) else 0 end
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (select main_cptl_acct,IF_CREDIT_EFF_CUST from DM.T_PUB_CUST_LIMIT_M_D where year||mth=@v_sy) b on a.main_cptl_acct=b.main_cptl_acct
    where a.year=@v_year and a.mth=@v_month;

    -- �Ƿ����Լ������ҵ��_�ۼ� if_apptbuyb_bis_gt
    update DM.T_PUB_CUST_LIMIT_M_D
    set if_apptbuyb_bis_gt = case when b.zjzh is not null then 1 else 0 end
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (select distinct zjzh from dba.t_ddw_ydsgh_D where fz>0) b on a.main_cptl_acct=b.zjzh
    where a.year=@v_year and a.mth=@v_month;
    
    -- �Ƿ�����������ҵ��_�ۼ� if_bank_chrm_bis_gt
    update DM.T_PUB_CUST_LIMIT_M_D
    set if_bank_chrm_bis_gt = case when b.fund_account is not null then 1 else 0 end
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (
        select distinct fund_account
        from dba.GT_ODS_ZHXT_HIS_BANKMSHAREJOUR
    ) b on a.main_cptl_acct=b.fund_account
    where a.year=@v_year and a.mth=@v_month;


    update DM.T_PUB_CUST_LIMIT_M_D
    set IF_PURC_OEF_GT = case when kj>0 then 1 else 0 end -- �Ƿ��򿪻�_�ۼ�	
        ,IF_PURC_ASSM_GT = case when zg>0 then 1 else 0 end   -- �Ƿ����ʹ�_�ۼ�	
        ,IF_PO_STKT_BIS_GT = case when gm_gpx>0 then 1 else 0 end  -- �Ƿ���빫ļ��Ʊ��ҵ��_�ۼ�	
        ,IF_PO_BONDT_BIS_GT = case when gm_zqx>0 then 1 else 0 end -- �Ƿ���빫ļծȯ��ҵ��_�ۼ�	
        ,IF_PO_CURRT_BIS_GT = case when gm_hbx>0 then 1 else 0 end -- �Ƿ���빫ļ������ҵ��_�ۼ�	
        ,IF_ASSM_STKT_BIS_GT = case when zg_gpx>0 then 1 else 0 end    -- �Ƿ�����ʹܹ�Ʊ��ҵ��_�ۼ�	
        ,IF_ASSM_BONDT_BIS_GT = case when zg_zqx>0 then 1 else 0 end   -- �Ƿ�����ʹ�ծȯ��ҵ��_�ۼ�	
        ,IF_ASSM_CURRT_BIS_GT = case when zg_hbx>0 then 1 else 0 end   -- �Ƿ�����ʹܻ�����ҵ��_�ۼ�
    
        ,IF_PO_STKT_BIS = case when b.gm_gpx_m>0 then 1 else 0 end -- �Ƿ���빫ļ��Ʊ��ҵ��	
        ,IF_PO_BONDT_BIS = case when b.gm_zqx_m>0 then 1 else 0 end    -- �Ƿ���빫ļծȯ��ҵ��	
        ,IF_PO_CURRT_BIS = case when b.gm_hbx_m>0 then 1 else 0 end    -- �Ƿ���빫ļ������ҵ��	
        ,IF_ASSM_STKT_BIS = case when b.zg_gpx_m>0 then 1 else 0 end   -- �Ƿ�����ʹܹ�Ʊ��ҵ��	
        ,IF_ASSM_BONDT_BIS = case when b.zg_zqx_m>0 then 1 else 0 end  -- �Ƿ�����ʹ�ծȯ��ҵ��	
        ,IF_ASSM_CURRT_BIS = case when b.zg_hbx_m>0 then 1 else 0 end  -- �Ƿ�����ʹܻ�����ҵ��	
    from DM.T_PUB_CUST_LIMIT_M_D a
    left join (
        select a.zjzh
            ,count(1) kj
            ,sum(case when b.lx like '%�������%' then 1 else 0 end) as zg
            ,sum(case when b.lx like '%��ļ-��Ʊ��%' then 1 else 0 end) as gm_gpx
            ,sum(case when b.lx like '%��ļ-ծȯ��%' then 1 else 0 end) as gm_zqx
            ,sum(case when b.lx like '%��ļ-������%' then 1 else 0 end) as gm_hbx
            ,sum(case when b.lx like '%�������-��Ʊ��%' then 1 else 0 end) as zg_gpx
            ,sum(case when b.lx like '%�������-ծȯ��%' then 1 else 0 end) as zg_zqx
            ,sum(case when b.lx like '%�������-������%' then 1 else 0 end) as zg_hbx
    
            ,sum(case when b.lx like '%��ļ-��Ʊ��%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as gm_gpx_m
            ,sum(case when b.lx like '%��ļ-ծȯ��%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as gm_zqx_m
            ,sum(case when b.lx like '%��ļ-������%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as gm_hbx_m
            ,sum(case when b.lx like '%�������-��Ʊ��%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as zg_gpx_m
            ,sum(case when b.lx like '%�������-ծȯ��%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as zg_zqx_m
            ,sum(case when b.lx like '%�������-������%' and a.nian||a.yue=@v_year||@v_month then 1 else 0 end) as zg_hbx_m
        from (
            select nian, yue, zjzh, jjdm from dba.t_ddw_xy_jjzb_m where nian||yue<@v_year||@v_month
            union
            select @v_year as nian, @v_month as yue, zjzh, jjdm from dba.t_ddw_xy_jjzb_d where substring(convert(varchar,rq),1,6)=@v_year||@v_month
        ) a
        left join dba.t_ddw_d_jj b on a.nian=b.nian and a.yue=b.yue and a.jjdm=b.jjdm
        where a.nian||a.yue <= @v_year||@v_month
        group by a.zjzh
    ) b on a.main_cptl_acct=b.zjzh
    where a.year=@v_year and a.mth=@v_month;



    update dm.T_PUB_CUST_LIMIT_M_D
    set BGDL_OPEN_DT = coalesce(b.dzscjyrq,0)
    from dm.T_PUB_CUST_LIMIT_M_D a
    left join (
    select fund_acct, min(load_dt) as dzscjyrq
    from dba.T_EDW_T05_TRADE_JOUR
    where substring(convert(varchar,load_dt),1,6)<=@v_year||@v_month
    and busi_cd in ('3101','3102') and note like '%����%'
    group by fund_acct 
    ) b on a.main_cptl_acct=b.fund_acct
    where a.year=@v_year and a.mth=@v_month;
    
    update dm.T_PUB_CUST_LIMIT_M_D
    set SB_OPEN_DT = case when a.IF_SB_CUST=1 and coalesce(b.IF_SB_CUST,0)=0 then convert(int,@v_year||@v_month||'01')
                        when a.IF_SB_CUST=1 and coalesce(b.IF_SB_CUST,0)>0 then b.SB_OPEN_DT
                        else 0 end
    from dm.T_PUB_CUST_LIMIT_M_D a
    left join (
        select cust_id,IF_SB_CUST,SB_OPEN_DT
        from dm.T_PUB_CUST_LIMIT_M_D
        where year||mth=@v_sy
    ) b on a.cust_id=b.cust_id
    where a.year=@v_year and a.mth=@v_month;

   commit;
end
GO
GRANT EXECUTE ON dm.P_PUB_CUST_LIMIT_M_D TO xydc
GO
CREATE PROCEDURE dm.P_PUB_DATE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ������Ϣά��
  ��д��: DCY
  ��������: 2017-11-16
  ��飺����ά������������ڵĸ���ά�ȣ��������ڱ���ȡ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
   --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_PUB_DATE;
  
  --��������
     INSERT INTO DM.T_PUB_DATE
	 (
	  DT                --����
	 ,DT_DATE           --����_DATE
	 ,YEAR              --��
	 ,QTR               --��
	 ,MTH               --��
	 ,IF_TRD_DAY_FLAG   --�Ƿ����ձ�־
	 ,WEEK              --��
	 ,DAY               --��
	 ,WEEK_DAY          --���ڼ�
	 ,LST_TRD_DAY       --��һ��������
	 ,NXT_TRD_DAY       --��һ��������
	 ,LST_NORM_DAY      --��һ����Ȼ��
	 ,NXT_NORM_DAY      --��һ����Ȼ��
	 ,TW_SNB_TRD_DAY    --���ܵڼ���������
	 ,TW_SNB_NORM_DAY   --���ܵڼ�����Ȼ��
	 ,TM_SNB_TRD_DAY    --���µڼ���������
	 ,TM_SNB_NORM_DAY   --���µڼ�����Ȼ��
	 ,TQ_SNB_TRD_DAY    --�����ڼ���������
	 ,TQ_SNB_NORM_DAY   --�����ڼ�����Ȼ��
	 ,TY_SNB_TRD_DAY    --����ڼ���������
	 ,TY_SNB_NORM_DAY   --����ڼ�����Ȼ��
	 ,GT_WORK_DAY       --�ۼƹ�����
	 ,TRD_DT            --��������
	 )
	 SELECT 
	  A1.DATE_ID
	 ,CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE) --����������
	 ,CONVERT(CHAR(4),A1.YEAR_ID) --�� 
	 ,CONVERT(CHAR(2),A1.QUARTER_ID) --�� 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --�� 
	 ,A1.TRADE_FLAG    --�Ƿ����ձ�־                      
     ,CONVERT(CHAR,A1.WEEK_NO)   --�� 
     ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) --����
	 ,CASE WHEN A1.WEEKDAY_ID=1 THEN '����һ' 
           WHEN A1.WEEKDAY_ID=2 THEN '���ڶ�'
           WHEN A1.WEEKDAY_ID=3 THEN '������'	
           WHEN A1.WEEKDAY_ID=4 THEN '������'
           WHEN A1.WEEKDAY_ID=5 THEN '������'
           WHEN A1.WEEKDAY_ID=6 THEN '������'
           WHEN A1.WEEKDAY_ID=7 THEN '������'
       END    --���ڼ�	   
     ,MAX(A2.DATE_ID)    --��һ�������� 
	 ,MIN(A21.DATE_ID)    --��һ��������
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)-1),112) AS NUMERIC(8,0))  --��һ����Ȼ��
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)+1),112) AS NUMERIC(8,0))  --��һ����Ȼ��
     ,A3.GZR    --���ܵڼ���������
	 ,A1.WEEKDAY_ID    --���ܵڼ�����Ȼ��
	 ,A4.GZR     --���µĵڼ������� 
	 ,CAST(SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) AS NUMERIC(8,0))     --���µڼ�����Ȼ��
	 ,A5.GZR --�����ĵڼ������� 
	 ,A51.GZR --�����ڼ�����Ȼ�� 
	 ,A6.GZR --����ĵڼ�������
	 ,A61.GZR --����ڼ�����Ȼ��
	 ,A7.GZR  --�ۼƹ����� 
	 ,NULL             --�������� 
	 
	  FROM DBA.T_ODS_D_DATE AS A1 
	  
	  --��һ��������
	  LEFT OUTER JOIN DBA.T_ODS_D_DATE AS A2 ON A2.TRADE_FLAG = 1 AND A2.DATE_ID < A1.DATE_ID 
	                                           AND CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE)-CAST(CAST(A2.DATE_ID AS CHAR(8)) AS DATE) < 20
	  --��һ��������									   
	  LEFT OUTER JOIN DBA.T_ODS_D_DATE AS A21 ON A21.TRADE_FLAG = 1 AND A21.DATE_ID > A1.DATE_ID 
	                                           AND CAST(CAST(A21.DATE_ID AS CHAR(8)) AS DATE)-CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE) < 20

	  --���ܵڼ���������
	  LEFT OUTER JOIN
					  (SELECT B1.DATE_ID, SUM(B2.TRADE_FLAG)
					  FROM DBA.T_ODS_D_DATE AS B1
					  LEFT OUTER JOIN DBA.T_ODS_D_DATE AS B2
						ON B2.TRADE_FLAG = 1
					   AND B1.YEAR_ID = B2.YEAR_ID
					   AND B1.WEEK_NO = B2.WEEK_NO
					   AND B2.DATE_ID <= B1.DATE_ID
					 WHERE B1.TRADE_FLAG = 1
					 GROUP BY B1.DATE_ID) AS A3(DATE_ID, GZR) ON A1.DATE_ID = A3.DATE_ID
	--���µĵڼ�������				 
	  LEFT OUTER JOIN
				  (SELECT C1.DATE_ID,
					SUM(C2.TRADE_FLAG) FROM
					DBA.T_ODS_D_DATE AS C1 LEFT OUTER JOIN
					DBA.T_ODS_D_DATE AS C2 ON
					C2.TRADE_FLAG = 1 AND
					C1.YEAR_ID = C2.YEAR_ID AND
					C1.MONTH_ID = C2.MONTH_ID AND
					C2.DATE_ID <= C1.DATE_ID WHERE
					C1.TRADE_FLAG = 1
					GROUP BY C1.DATE_ID) AS A4( DATE_ID,GZR) ON A1.DATE_ID = A4.DATE_ID 
	--�����ڼ���������
	  LEFT OUTER JOIN
				  (SELECT D1.DATE_ID,
					SUM(D2.TRADE_FLAG) FROM
					DBA.T_ODS_D_DATE AS D1 LEFT OUTER JOIN
					DBA.T_ODS_D_DATE AS D2 ON
					D2.TRADE_FLAG = 1 AND
					D1.YEAR_ID = D2.YEAR_ID AND
					D1.QUARTER_ID = D2.QUARTER_ID AND
					D2.DATE_ID <= D1.DATE_ID WHERE
					D1.TRADE_FLAG = 1
					GROUP BY D1.DATE_ID) AS A5( DATE_ID,
				  GZR) ON A1.DATE_ID = A5.DATE_ID 
	--�����ڼ�����Ȼ��
	  LEFT OUTER JOIN
				  (SELECT D1.DATE_ID,
					COUNT(1) FROM
					DBA.T_ODS_D_DATE AS D1 LEFT OUTER JOIN
					DBA.T_ODS_D_DATE AS D2 ON
					D1.YEAR_ID = D2.YEAR_ID AND
					D1.QUARTER_ID = D2.QUARTER_ID AND
					D2.DATE_ID <= D1.DATE_ID 
					GROUP BY D1.DATE_ID) AS A51( DATE_ID,
				  GZR) ON A1.DATE_ID = A51.DATE_ID 
	--����ڼ���������			  
	 LEFT OUTER JOIN
			  (SELECT E1.DATE_ID,
				SUM(E2.TRADE_FLAG) FROM
				DBA.T_ODS_D_DATE AS E1 LEFT OUTER JOIN
				DBA.T_ODS_D_DATE AS E2 ON
				E2.TRADE_FLAG = 1 AND
				E1.YEAR_ID = E2.YEAR_ID AND
				E2.DATE_ID <= E1.DATE_ID WHERE
				E1.TRADE_FLAG = 1
				GROUP BY E1.DATE_ID) AS A6( DATE_ID,GZR) ON A1.DATE_ID = A6.DATE_ID
	--����ڼ�����Ȼ��			  
	 LEFT OUTER JOIN
			  (SELECT E1.DATE_ID,
				COUNT(1) FROM
				DBA.T_ODS_D_DATE AS E1 LEFT OUTER JOIN
				DBA.T_ODS_D_DATE AS E2 ON
				E1.YEAR_ID = E2.YEAR_ID AND
				E2.DATE_ID <= E1.DATE_ID 
				GROUP BY E1.DATE_ID) AS A61( DATE_ID,GZR) ON A1.DATE_ID = A61.DATE_ID
	--�ۼƹ����� 
	LEFT OUTER JOIN
			  (SELECT F1.DATE_ID,
				SUM(F2.TRADE_FLAG) FROM
				DBA.T_ODS_D_DATE AS F1 LEFT OUTER JOIN
				DBA.T_ODS_D_DATE AS F2 ON
				F2.TRADE_FLAG = 1 AND
				F2.DATE_ID <= F1.DATE_ID WHERE
				F1.TRADE_FLAG = 1
				GROUP BY F1.DATE_ID) AS A7( DATE_ID,
			  GZR) ON A1.DATE_ID = A7.DATE_ID
      GROUP BY 
	  A1.DATE_ID
	 ,CAST(CAST(A1.DATE_ID AS CHAR(8)) AS DATE) --����������
	 ,CONVERT(CHAR(4),A1.YEAR_ID) --�� 
	 ,CONVERT(CHAR(2),A1.QUARTER_ID) --�� 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --�� 
	 ,A1.TRADE_FLAG    --�Ƿ����ձ�־                      
     ,CONVERT(CHAR,A1.WEEK_NO)   --��  ,
     ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) --����
	 ,CASE WHEN A1.WEEKDAY_ID=1 THEN '����һ' 
           WHEN A1.WEEKDAY_ID=2 THEN '���ڶ�'
           WHEN A1.WEEKDAY_ID=3 THEN '������'	
           WHEN A1.WEEKDAY_ID=4 THEN '������'
           WHEN A1.WEEKDAY_ID=5 THEN '������'
           WHEN A1.WEEKDAY_ID=6 THEN '������'
           WHEN A1.WEEKDAY_ID=7 THEN '������'
       END    --���ڼ�
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)-1),112) AS NUMERIC(8,0))  --��һ����Ȼ��
	 ,CAST(CONVERT(VARCHAR(8),(CAST(A1.DATE_NAME AS DATE)+1),112) AS NUMERIC(8,0))  --��һ����Ȼ��
     ,A3.GZR    --���ܵڼ���������
	 ,A1.WEEKDAY_ID    --���ܵڼ�����Ȼ��
	 ,A4.GZR     --���µĵڼ������� 
	 ,CAST(SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),7,2) AS NUMERIC(8,0))     --���µڼ�����Ȼ��
	 ,A5.GZR --�����ĵڼ������� 
	 ,A51.GZR --�����ڼ�����Ȼ�� 
	 ,A6.GZR --����ĵڼ�������
	 ,A61.GZR --����ڼ�����Ȼ��
	 ,A7.GZR  --�ۼƹ�����
	  ORDER BY 1 ASC;
    COMMIT;
	
	--�����������½��������ֶΣ������ǰ�����ǽ����գ���ʹ�õ�ǰ���ڣ������ǰ���ڷǽ����գ���ʹ����һ�����ա�
	UPDATE DM.T_PUB_DATE
	SET TRD_DT= (CASE WHEN IF_TRD_DAY_FLAG=1 THEN DT ELSE LST_TRD_DAY END)
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_DATE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_DATE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_DATE_M(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ����ά���±�
  ��д��: DCY
  ��������: 2017-12-19
  ��飺����ά���±���������¶ȼ���ʱ��
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
   --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_PUB_DATE_M;
  
  --�����꼶�������
  SELECT
     CONVERT(CHAR(4),A1.YEAR_ID)                          AS YEAR                --�� 
    ,MIN( A1.DATE_ID )                                    AS NATRE_DAY_YEARBGN   --��Ȼ��_���
	,MIN(CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END) AS TRD_DAY_YEARBGN     --������_���
	,COUNT(DISTINCT A1.DATE_ID )                          AS NATRE_DAYS_YEAR     --��Ȼ����_��
	,COUNT(DISTINCT CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END) AS TRD_DAYS_YEAR  --��������_��
	
	INTO #YEAR_STAT
	
	FROM
	DBA.T_ODS_D_DATE AS A1 
	GROUP BY 
    CONVERT(CHAR(4),A1.YEAR_ID)
    ;
	
  --��������
     INSERT INTO DM.T_PUB_DATE_M
	 (
	  YEAR               --��
	 ,MTH                --��
	 ,NATRE_DAY_MTHBEG   --��Ȼ��_�³�
	 ,NATRE_DAY_MTHEND   --��Ȼ��_��ĩ
	 ,TRD_DAY_MTHBEG     --������_�³�
	 ,TRD_DAY_MTHEND     --������_��ĩ
	 ,NATRE_DAY_YEARBGN  --��Ȼ��_���
	 ,TRD_DAY_YEARBGN    --������_���
	 ,NATRE_DAYS_MTH     --��Ȼ����_��
	 ,TRD_DAYS_MTH       --��������_��
	 ,NATRE_DAYS_YEAR    --��Ȼ����_��
	 ,TRD_DAYS_YEAR      --��������_��
	 )
	 SELECT 
	  CONVERT(CHAR(4),A1.YEAR_ID) --�� 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --�� 
	 ,MIN(A1.DATE_ID)  --��Ȼ��_�³�
	 ,MAX(A1.DATE_ID)  --��Ȼ��_��ĩ
	 ,MIN(CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END)  --������_�³�
	 ,MAX(CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END)  --������_��ĩ
	 ,A2.NATRE_DAY_YEARBGN     --��Ȼ��_���
	 ,A2.TRD_DAY_YEARBGN       --������_���
	 ,COUNT(DISTINCT A1.DATE_ID )                                      --��Ȼ����_��
	 ,COUNT(DISTINCT CASE WHEN A1.TRADE_FLAG = 1 THEN A1.DATE_ID END)  --��������_��
     ,A2.NATRE_DAYS_YEAR     --��Ȼ����_��
	 ,A2.TRD_DAYS_YEAR       --��������_��
	 
	  FROM DBA.T_ODS_D_DATE AS A1 
	  LEFT OUTER JOIN #YEAR_STAT A2 ON CONVERT(CHAR(4),A1.YEAR_ID)=A2.YEAR
	  GROUP BY 
	  CONVERT(CHAR(4),A1.YEAR_ID) --�� 
	 ,SUBSTR(CAST(A1.DATE_ID AS CHAR(8)),5,2) --��
	 ,A2.NATRE_DAY_YEARBGN     --��Ȼ��_���
	 ,A2.TRD_DAY_YEARBGN       --������_���
     ,A2.NATRE_DAYS_YEAR     --��Ȼ����_��
	 ,A2.TRD_DAYS_YEAR       --��������_��
	 ;
	 
    COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_DATE_M TO query_dev
GO
CREATE PROCEDURE dm.P_PUB_IDV_CUST(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ���˿ͻ���Ϣά��
  ��д��: DCY
  ��������: 2017-11-17
  ��飺��ϴ���˿ͻ��������õ�������Ϣ
  *********************************************************************
  �޶���¼��   �޶�����    �޶���     �޸����ݼ�Ҫ˵��
  ��������     20180403     dcy       �������ֻ��š����֤�š��Ƚ������� 
  �ظ�ֵ�޸�  20180415     chenhu  ����һ��hr_name�ǿյ�����         
  *********************************************************************/
  
   SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
   	
  --PART0 ɾ��Ҫ��ϴ������
    DELETE FROM DM.T_PUB_IDV_CUST WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
	
  --PART1 ��ÿ�ղɼ������ݷ�����ʱ��
 
	SELECT
	 OUCI.CLIENT_ID        AS CUST_ID      --�ͻ�����
	,SUBSTR(@V_BIN_DATE||'',1,4)           AS YEAR      --��
	,SUBSTR(@V_BIN_DATE||'',5,2)           AS MTH       --��
	,DOH.PK_ORG            AS WH_ORG_ID    --�ֿ�������� 
	,CONVERT(VARCHAR,OUCI.BRANCH_NO) AS HS_ORG_ID  --������������
	,OUC.CLIENT_NAME       AS CUST_NAME    --�ͻ�����
	,OUCI.BIRTHDAY         AS BIRT_DT      --��������
	,OUCI.HOME_TEL         AS HOME_TEL     --��ͥ�绰
	,OUCI.OFFICE_TEL       AS UNIT_TEL     --��λ�绰
	,OUCI.MOBILE_TEL       AS MOB_NO       --�ֻ���
	,OUCI.ID_ADDRESS       AS HOME_ADDR    --��ͥ��ַ
	,OUCI.E_MAIL           AS EML          --����
	,OUCI.PROFESSION_CODE  AS OCCU         --ְҵ
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUCI.PROFESSION_CODE) AND OUS.DICT_ENTRY=1047) AS OCCU_NAME   --ְҵ����
    ,OUCI.NATION_ID        AS NATN	       --����
	,(SELECT DICT_PROMPT FROM DBA.T_ODS_UF2_SYSDICTIONARY OUS 
	  WHERE OUS.SUBENTRY=CONVERT(VARCHAR,OUCI.NATION_ID) AND OUS.DICT_ENTRY=971) AS NATN_NAME   --��������
	,@V_BIN_DATE  AS LOAD_DT  --��ϴ����
	
	INTO #TEMP_IDV_CUST
	
	FROM DBA.T_EDW_UF2_CLIENTINFO OUCI
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUCI.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL  AND DOH.HR_NAME IS NOT NULL   --���ظ�ֵ  UPDATE BY CHENHU 20180415
	LEFT JOIN DBA.T_EDW_UF2_CLIENT OUC ON OUC.CLIENT_ID=OUCI.CLIENT_ID and OUC.LOAD_DT=@V_BIN_DATE
	WHERE OUCI.LOAD_DT=@V_BIN_DATE
	;
	COMMIT;
	
	--PART1.2 ���ͻ������е�/�滻��
	UPDATE #TEMP_IDV_CUST
	SET 
	    --CUST_NAME=REPLACE(REPLACE(REPLACE(CUST_NAME,'/',''),'\',''),'|',''),     --�ͻ����� 
	    --MOB_NO=REPLACE(REPLACE(REPLACE(MOB_NO,'/',''),'\',''),'|',''),
        --home_tel=REPLACE(REPLACE(REPLACE(home_tel,'/',''),'\',''),'|',''),
        --unit_tel=REPLACE(REPLACE(REPLACE(unit_tel,'/',''),'\',''),'|',''),
        --home_addr='*********',--���������л��з������²ɼ����ݵ�GP����ֱ�����������ú���REPLACE(REPLACE(REPLACE(home_addr,'/',''),'\',''),'|','')
		--eml=REPLACE(REPLACE(REPLACE(eml,'/',''),'\',''),'|','')
		
		 CUST_NAME=SUBSTR(CUST_NAME,1,0)||'***'   --��������
		,MOB_NO=SUBSTR(MOB_NO,1,3)||'********'   --�ֻ�������
		,HOME_TEL=SUBSTR(HOME_TEL,1,0)||'********'   --��ͥ�绰����
		,UNIT_TEL=SUBSTR(UNIT_TEL,1,0)||'********'   --��λ�绰����
		,EML=SUBSTR(EML,1,0)||'********'   --��������
		,HOME_ADDR=SUBSTR(HOME_ADDR,1,0)||'********'   --��ͥ��ַ����
	;
	COMMIT;	
	
	--4.3 ��󽫵��������Ŀͻ��������
	INSERT INTO DM.T_PUB_IDV_CUST
	(
	 CUST_ID        --�ͻ�����
	,YEAR              --��
	,MTH               --��
	,WH_ORG_ID      --�ֿ��������
	,HS_ORG_ID      --������������
	,CUST_NAME      --�ͻ�����
	,BIRT_DT        --��������
	,HOME_TEL       --��ͥ�绰
	,UNIT_TEL       --��λ�绰
	,MOB_NO         --�ֻ���
	,HOME_ADDR      --��ͥ��ַ
	,EML            --����
	,OCCU           --ְҵ
	,OCCU_NAME      --ְҵ����
	,NATN           --����
	,NATN_NAME      --��������
	,LOAD_DT        --��ϴ����
	)
	SELECT
	 CUST_ID        --�ͻ�����
	,YEAR              --��
	,MTH               --��
	,WH_ORG_ID      --�ֿ��������
	,HS_ORG_ID      --������������
	,CUST_NAME      --�ͻ�����
	,BIRT_DT        --��������
	,HOME_TEL       --��ͥ�绰
	,UNIT_TEL       --��λ�绰
	,MOB_NO         --�ֻ���
	,HOME_ADDR      --��ͥ��ַ
	,EML            --����
	,OCCU           --ְҵ
	,OCCU_NAME      --ְҵ����
	,NATN           --����
	,NATN_NAME      --��������
	,LOAD_DT        --��ϴ����
	FROM #TEMP_IDV_CUST  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_IDV_CUST TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_IDV_CUST TO xydc
GO
CREATE PROCEDURE dm.P_PUB_MKT_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: �г�����ά��
  ��д��: DCY
  ��������: 2017-11-24
  ��飺�г�����ά����ϴ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
  
   --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_PUB_MKT_TYPE ;
  
   --��ʼ��������
  INSERT INTO DM.T_PUB_MKT_TYPE
  (
    WH_MKT_TYPE_ID    --�ֿ��г����ͱ���
   ,HS_MKT_TYPE_ID    --�����г����ͱ���
   ,WH_MKT_TYPE_NAME  --�ֿ��г���������
   ,HS_MKT_TYPE_NAME  --�����г���������
   ,LOAD_DT           --��ϴ����
   )
	  
  SELECT DISTINCT 
	 TOUS.MKT_TYPE AS  WH_MKT_TYPE_ID     --�ֿ��г����ͱ���
	,TOUS.EXCHANGE_TYPE AS HS_MKT_TYPE_ID --�����г����ͱ���
    ,TETPC.CODE_NAME AS WH_MKT_TYPE_NAME  --�ֿ��г���������
	,DIC.DICT_PROMPT AS  HS_MKT_TYPE_NAME --�����г���������
    ,@V_BIN_DATE    --��ϴ���� 
	
  FROM DBA.T_ODS_UF2_SCLXDZ TOUS
  LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY DIC ON TOUS.EXCHANGE_TYPE=DIC.SUBENTRY  AND   DIC.DICT_ENTRY=1301 -- EXCHANGE_TYPE�����г�����
  LEFT JOIN DBA.T_EDW_T06_PUBLIC_CODE TETPC ON  TOUS.MKT_TYPE=TETPC.CODE_CD  AND FIELD_ENG_NAME='market_type_cd' --�ֿ��г�����
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_MKT_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_MKT_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_ORDR_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ί�з�ʽά��
  ��д��: DCY
  ��������: 2017-11-27
  ��飺ί�з�ʽά����ϴ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    
   --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_PUB_ORDR_TYPE ;
  
   --��ʼ��������
  INSERT INTO DM.T_PUB_ORDR_TYPE
  (
    WH_ORDR_MODE_CD    --�ֿ�ί�����ͱ���
   ,WH_ORDR_MODE_NAME  --�ֿ�ί����������
   ,HS_ORDR_MODE_CD    --����ί�����ͱ���
   ,HS_ORDR_MODE_NAME  --����ί����������
   ,LOAD_DT           --��ϴ����
   )
	  
  SELECT DISTINCT 
	 OEW.CODE_VAL     AS  WH_ORDR_MODE_CD    --�ֿ�ί�����ͱ���
	,TETPC.CODE_NAME  AS  WH_ORDR_MODE_NAME  --�ֿ�ί����������
	,OEW.SRC_CODE_VAL AS  HS_ORDR_MODE_CD    --����ί�����ͱ���
	,DIC.DICT_PROMPT  AS  HS_ORDR_MODE_NAME  --����ί����������
    ,@V_BIN_DATE    --��ϴ���� 
	
  FROM DBA.T_ODS_DIC_SJCK_TMP_OP_ENTRUST_WAY OEW --ί�з�ʽ�����Ͳֿ��ӳ���
  LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY DIC ON OEW.SRC_CODE_VAL=DIC.SUBENTRY  AND   DIC.DICT_ENTRY=1201 --����ί������
  LEFT JOIN DBA.T_EDW_T06_PUBLIC_CODE TETPC ON OEW.CODE_VAL=TETPC.CODE_CD  AND FIELD_ENG_NAME='order_way_cd' --�ֿ�ί������
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_ORDR_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_ORDR_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_ORG(IN @v_date INT)
BEGIN
  /******************************************************************
  ������: �������ά��t_pub_org��
  ��д��: ����
  ��������: 2017-11-15
  ��飺���»���ά��t_pub_org�������������¼�ɾ���ֱ���д���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           2017��11��15��                ����                    ����
  *********************************************************************/
  -- 1��ȡ���µ�����
  -- drop table #t_org;
  
  declare @v_nian varchar(4);
  declare @v_yue varchar(2);
  
  commit;
  
  set @v_nian = substring(convert(varchar,@v_date),1,4);
  set @v_yue = substring(convert(varchar,@v_date),5,2);
  
    SELECT
        a.PK_ORG AS WH_ORG_ID    -- �ֿ��������
        ,a.branch_no AS HS_ORG_ID -- ������������
        ,a.hr_pk AS HR_ORG_ID     -- HR��������
        ,b.DEP_CODE AS XY_ORG_ID    -- �����������
        ,a.hr_name AS HR_ORG_NAME    -- HR��������
        ,a.branch_name AS HS_ORG_NAME   -- ������������
        ,a.open_date AS OPEN_DT     -- ��ҵ����
        ,a.org_category AS ORG_CLAS -- ��������
        ,a.branch_type AS ORG_TYPE  -- ��������
        ,org_sept.pk_org AS SEPT_CORP_ID    -- �ֹ�˾����
        ,a.father_branch_name_direct AS SEPT_CORP_NAME  -- �ֹ�˾����
        ,org_sept_top.pk_org as TOP_SEPT_CORP_ID    -- �����ֹ�˾����
        ,a.father_branch_name_root as TOP_SEPT_CORP_NAME    -- �����ֹ�˾����
        ,a.center_org_pk as CENT_BRH_ID  -- ����Ӫҵ������
        ,a.center_org_name as CENT_BRH_NAME -- ����Ӫҵ������
        ,a.region_category as REGI_CLAS     -- ��������
        ,a.province as PROV     -- ʡ
        ,a.city as CITY         -- ����
        ,a.prefecture_city as L_CITY    -- �ؼ���
        ,case when a.is_core_org='Y' then 1 else 0 end as IF_KEY        -- �Ƿ����
        ,a.is_in_system as IF_SYS_INR   -- �Ƿ�ϵͳ��
        ,case when a.enabled='Y' then 1 else 0 end as IF_VLD            -- �Ƿ���Ч
        ,coalesce(b.ORG_CODE,a.org_supervise_code) as SRVL_CD    -- ��ܴ���
        ,b.BRANCH_SHORTNAME as ORG_ABBR     -- �������
        ,b.BRANCH_ADDRESS as DET_ADDR       -- ��ϸ��ַ
        ,b.BRANCH_TYPE as SRVL_CLAS         -- ��ܷ���
        ,b.SUPERVISE_AREA as SRVL_AREA      -- ���Ͻ��
        ,b.ADMINISTRATIVE_AREA as BRH_TYPE_PERFM  -- Ӫҵ�����˽��
        ,a.father_branch_hrpk_root as PRI_SEPT_CORPHR_NO    -- һ���ֹ�˾HR���
        ,a.secondary_branch_hrpk as SCDY_SEPT_CORPHR_NO     -- �����ֹ�˾HR���
        ,a.father_branch_hrpk_direct as DIRECTL_SEPT_CORPHR_NO  -- ֱ���ֹ�˾HR���
    INTO #t_org
    -- select *
    FROM DBA.T_DIM_ORG a
    LEFT JOIN DBA.T_ODS_CF_V_BRANCH b ON a.branch_no=CONVERT(VARCHAR,b.BRANCH_NO)
    LEFT JOIN DBA.T_DIM_ORG org_sept on a.father_branch_hrpk_direct=org_sept.hr_pk
    LEFT JOIN DBA.T_DIM_ORG org_sept_top on a.father_branch_hrpk_root=org_sept_top.hr_pk;
    
    
    delete from dm.T_PUB_ORG where "year"=@v_nian and mth=@v_yue;
    
    insert into dm.T_PUB_ORG(
	    WH_ORG_ID
			,"YEAR"
			,MTH
			,HS_ORG_ID
			,HR_ORG_ID
			,XY_ORG_ID
			,HR_ORG_NAME
			,HS_ORG_NAME
			,OPEN_DT
			,ORG_CLAS
			,ORG_TYPE
			,SEPT_CORP_ID
			,SEPT_CORP_NAME
			,TOP_SEPT_CORP_ID
			,TOP_SEPT_CORP_NAME
			,CENT_BRH_ID
			,CENT_BRH_NAME
			,REGI_CLAS
			,PROV
			,CITY
			,L_CITY
			,IF_KEY
			,IF_SYS_INR
			,IF_VLD
			,SRVL_CD
			,ORG_ABBR
			,DET_ADDR
			,SRVL_CLAS
			,SRVL_AREA
			,BRH_TYPE_PERFM
			,SUPERV_BUREAU
			,LOAD_DT
            ,PRI_SEPT_CORPHR_NO
            ,SCDY_SEPT_CORPHR_NO
            ,DIRECTL_SEPT_CORPHR_NO
    )
    SELECT
    	WH_ORG_ID
			,@v_nian AS "YEAR"
			,@v_yue AS MTH
			,HS_ORG_ID
			,HR_ORG_ID
			,XY_ORG_ID
			,HR_ORG_NAME
			,HS_ORG_NAME
			,OPEN_DT
			,ORG_CLAS
			,ORG_TYPE
			,SEPT_CORP_ID
			,SEPT_CORP_NAME
			,TOP_SEPT_CORP_ID
			,TOP_SEPT_CORP_NAME
			,CENT_BRH_ID
			,CENT_BRH_NAME
			,REGI_CLAS
			,PROV
			,CITY
			,L_CITY
			,IF_KEY
			,IF_SYS_INR
			,IF_VLD
			,SRVL_CD
			,ORG_ABBR
			,DET_ADDR
			,SRVL_CLAS
			,SRVL_AREA
			,BRH_TYPE_PERFM
			,NULL AS SUPERV_BUREAU
			,@v_date AS LOAD_DT
            ,PRI_SEPT_CORPHR_NO
            ,SCDY_SEPT_CORPHR_NO
            ,DIRECTL_SEPT_CORPHR_NO
    FROM #t_org;


    update dm.t_pub_org
    set prov = b.prov
    from dm.t_pub_org a
    left join (
        select  *
        from dm.t_pub_org
        where year='2017' and mth='12'
    ) b on a.wh_org_id=b.wh_org_id
    where a.year||a.mth=@v_nian||@v_yue;    

    
    commit;

END
GO
GRANT EXECUTE ON dm.P_PUB_ORG TO xydc
GO
CREATE PROCEDURE dm.P_PUB_ORG_CUST(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: �����ͻ���Ϣά��
  ��д��: DCY
  ��������: 2017-11-14
  ��飺��ϴ�����ͻ��ĸ������õ�������Ϣ
  *********************************************************************
  �޶���¼��   �޶�����    �޶���     �޸����ݼ�Ҫ˵�� 
   ��������     20180403     dcy       �������ֻ��š����֤�š���ҵ��˰��š���˰�ŵȽ�������         
  *********************************************************************/
  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
  
    --PART0 ɾ��Ҫ��ϴ������
    DELETE FROM DM.T_PUB_ORG_CUST WHERE YEAR=SUBSTR(@V_BIN_DATE||'',1,4) AND MTH=SUBSTR(@V_BIN_DATE||'',5,2);
  
  --PART1 ��ÿ�ղɼ������ݷ�����ʱ��
 
	SELECT
	 OUOI.CLIENT_ID                    AS CUST_ID       --�ͻ�����
	,SUBSTR(@V_BIN_DATE||'',1,4)       AS YEAR          --��
	,SUBSTR(@V_BIN_DATE||'',5,2)       AS MTH           --��
	,DOH.PK_ORG                        AS WH_ORG_ID     --�ֿ�������� 
	,CONVERT(VARCHAR,OUOI.BRANCH_NO)   AS HS_ORG_ID     --������������
	,OUC.CLIENT_NAME                   AS CUST_NAME     --�ͻ�����
	,OUOI.INSTREPR_NAME                AS LEGP_REP      --���˴���
	,OUOI.ORGAN_CODE                   AS ORG_ID        --��֯��������
	,OUOI.BUSINESS_LICENCE             AS DOBIZ_LICENS  --Ӫҵִ��
	,OUOI.COMPANY_KIND                 AS ET            --��ҵ����
	,OUOI.REGISTER_FUND                AS REG_CAPI      --ע���ʱ�
	,OUOI.REGISTER_MONEY_TYPE          AS REG_CAPI_CCY  --ע���ʱ�����
	,OUOI.RELATION_NAME                AS CONP          --��ϵ��
	,OUOI.MOBILE_TEL                   AS MOB_NO        --�ֻ���
	,OUOI.E_MAIL                       AS EML           --�����ʼ�
	,OUOI.ADDRESS                      AS ADDR          --��ַ
	,OUOI.WORK_RANGE                   AS MANAGE_SCP    --��Ӫ��Χ
	,OUOI.INDUSTRY_TYPE                AS INDT_TYPE     --��ҵ���
	,OUOI.TAX_REGISTER                 AS STA_TAX_CERTNO --��˰˰��Ǽ�֤��
	,OUOI.REGTAX_REGISTER              AS LOC_TAX_CERTNO --��˰˰��Ǽ�֤��
	,''                                AS UNI_SOCI_CRED_NO   --ͳһ������ñ��
	,OUC.ID_BEGINDATE                  AS ID_VLD_SDT         --֤����Ч��ʼ����
	,OUC.ID_ENDDATE                    AS ID_VLD_EDT         --֤����Ч��ֹ����
	,@V_BIN_DATE                       AS LOAD_DT  --��ϴ����
	
	INTO #TEMP_ORG_CUST
	
	FROM DBA.T_EDW_UF2_ORGANINFO OUOI
	LEFT JOIN DBA.T_DIM_ORG_HIS  DOH ON CONVERT(VARCHAR,OUOI.BRANCH_NO)=DOH.BRANCH_NO AND DOH.RQ=@V_BIN_DATE AND DOH.BRANCH_NO IS NOT NULL     
	--LEFT JOIN DBA.T_ODS_UF2_CLIENT OUC ON OUC.CLIENT_ID=OUOI.CLIENT_ID
	LEFT JOIN DBA.T_EDW_UF2_CLIENT OUC ON OUC.CLIENT_ID=OUOI.CLIENT_ID and OUC.LOAD_DT=@V_BIN_DATE

	WHERE OUOI.LOAD_DT=@V_BIN_DATE
	;
	COMMIT;
	
	--PART1.2 ���ͻ������е�/�滻��
	UPDATE #TEMP_ORG_CUST
	SET 
	    --CUST_NAME=REPLACE(REPLACE(REPLACE(CUST_NAME,'/',''),'\',''),'|',''),     --�ͻ����� 
	    --MOB_NO=REPLACE(REPLACE(REPLACE(MOB_NO,'/',''),'\',''),'|',''),
        --conp=REPLACE(REPLACE(REPLACE(conp,'/',''),'\',''),'|',''),
        --addr=REPLACE(REPLACE(REPLACE(addr,'/',''),'\',''),'|',''),
        MANAGE_SCP=REPLACE(REPLACE(REPLACE(MANAGE_SCP,'/',''),'\',''),'|','')
		
		,CUST_NAME=SUBSTR(CUST_NAME,1,0)||'***'   --��������
		,MOB_NO=SUBSTR(MOB_NO,1,3)||'********'   --�ֻ�������
		,CONP=SUBSTR(CONP,1,0)||'********'   --��ϵ������
		,LEGP_REP=SUBSTR(LEGP_REP,1,0)||'********'   --���˴�������
		,EML=SUBSTR(EML,1,0)||'********'   --��������
		,ADDR=SUBSTR(ADDR,1,0)||'********'   --��ַ����
		,STA_TAX_CERTNO=SUBSTR(STA_TAX_CERTNO,1,0)||'********'   --��˰˰��Ǽ�֤������
		,LOC_TAX_CERTNO=SUBSTR(LOC_TAX_CERTNO,1,0)||'********'   --��˰˰��Ǽ�֤������
		,UNI_SOCI_CRED_NO=SUBSTR(UNI_SOCI_CRED_NO,1,0)||'********'   --ͳһ������ñ������
		
	;
	COMMIT;
	
	--3 ��󽫵��������Ŀͻ��������
	INSERT INTO DM.T_PUB_ORG_CUST
	(
	 CUST_ID    	--�ͻ�����
	,YEAR           --��
	,MTH            --��
	,WH_ORG_ID    	--�ֿ��������
	,HS_ORG_ID    	--������������
	,CUST_NAME    	--�ͻ�����
	,LEGP_REP       --���˴���
	,ORG_ID         --��֯��������
	,DOBIZ_LICENS   --Ӫҵִ��
	,ET             --��ҵ����
	,REG_CAPI       --ע���ʱ�
	,REG_CAPI_CCY   --ע���ʱ�����
	,CONP           --��ϵ��
	,MOB_NO         --�ֻ���
	,EML            --�����ʼ�
	,ADDR           --��ַ
	,MANAGE_SCP     --��Ӫ��Χ
	,INDT_TYPE      --��ҵ���
	,STA_TAX_CERTNO    --��˰˰��Ǽ�֤��
	,LOC_TAX_CERTNO    --��˰˰��Ǽ�֤��
	,UNI_SOCI_CRED_NO  --ͳһ������ñ��
	,ID_VLD_SDT    --֤����Ч��ʼ����
	,ID_VLD_EDT    --֤����Ч��ֹ����
	,LOAD_DT      --��ϴ����
	)
	SELECT
	 CUST_ID    	--�ͻ�����
	,YEAR           --��
	,MTH            --��
	,WH_ORG_ID    	--�ֿ��������
	,HS_ORG_ID    	--������������
	,CUST_NAME    	--�ͻ�����
	,LEGP_REP       --���˴���
	,ORG_ID         --��֯��������
	,DOBIZ_LICENS   --Ӫҵִ��
	,ET             --��ҵ����
	,REG_CAPI       --ע���ʱ�
	,REG_CAPI_CCY   --ע���ʱ�����
	,CONP           --��ϵ��
	,MOB_NO         --�ֻ���
	,EML            --�����ʼ�
	,ADDR           --��ַ
	,MANAGE_SCP     --��Ӫ��Χ
	,INDT_TYPE      --��ҵ���
	,STA_TAX_CERTNO    --��˰˰��Ǽ�֤��
	,LOC_TAX_CERTNO    --��˰˰��Ǽ�֤��
	,UNI_SOCI_CRED_NO  --ͳһ������ñ��
	,ID_VLD_SDT    --֤����Ч��ʼ����
	,ID_VLD_EDT    --֤����Ч��ֹ����
	,LOAD_DT      --��ϴ����
	FROM #TEMP_ORG_CUST  
	;
	COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_ORG_CUST TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_ORG_CUST TO xydc
GO
CREATE PROCEDURE dm.P_PUB_RIGH_INFO(IN @V_BIN_DATE numeric(8))
 
  /******************************************************************
  ������: ����BI��Ա������Ȩ�ޱ���
  ��д��: rengz
  ��������: 2018-01-12
  ��飺������Ա������������Ȩ����Ͻ�Ļ������й���
        --����Ȩ����Ϣά��
            �ܲ���ɫ������Ӫҵ��Ȩ��
            һ���ֹ�˾��һ���ֹ�˾�¹����ж����ֹ�˾��Ӫҵ��
            �����ֹ�˾�������ֹ�˾�¹�����Ӫҵ��
            Ӫҵ��    ����Ӫҵ������
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��

  *********************************************************************/
 begin 

    --declare @v_bin_date numeric(8); 
     
    set @v_bin_date =@v_bin_date;

------------------------
 -- ��ԱȨ����Ϣά��
------------------------ 
      
    --ɾ������������
    delete from DM.T_PUB_PRSN_RIGH_INFO where LOAD_DT<=@v_bin_date;
    commit;  

   insert into DM.T_PUB_PRSN_RIGH_INFO(
    LOAD_DT,
    HR_ID               ,
	AFA_ID              ,
	EMP_NAME           ,
	ORG_TYPE             ,
	XY_ORG_ID            ,
	WH_ORG_ID            ,
	HS_ORG_ID            ,
	HR_ORG_ID            ,
	DIRECTL_ORG_ID       ,
	SCDY_ORG_ID          ,
	PRI_ORG_ID           ,
	ORG_NAME             ,
	DIRECTL_ORG_NAME     ,
	SCDY_ORG_NAME        ,
	PRI_ORG_NAME    )   
select a.rq                        as ����,
       a.hrid                      as �������,
       a.afatwo_ygh                as AFA���,
       a.ygxm                      as Ա������,
       b.branch_type               as ��������,
       c.dep_code                  as �����������,
       a.pk_org                    as �����ֿ����,
       a.jgbh_hs                   as ������������,
       b.hr_pk                     as �����������,
       b.father_branch_hrpk_direct as ����ֱ�����,
       secondary_branch_hrpk       as �����������,
       father_branch_hrpk_root     as ����һ�����,
       b.hr_name                   as ��������,
       father_branch_name_direct   as ����ֱ������,
       secondary_branch_name       as ������������,
       father_branch_name_root     as ����һ������   
 from dba.t_edw_person_d a
  left join dba.t_dim_org b on a.pk_org = b.pk_org
  left join DBA.T_ODS_CF_V_BRANCH c on convert(varchar,b.branch_no)=convert(varchar,c.branch_no)
 where a.rq = @v_bin_date
   and a.ygzt = '������Ա'
   and a.rylx='Ա��' 
    and is_virtual=0 
    and hrid is not null;

commit;

------------------------
 -- ����Ȩ����Ϣά��
------------------------ 
 
    --ɾ������������
    delete from DM.T_PUB_ORG_RIGH_INFO where LOAD_DT <=@v_bin_date;
    commit;  

--drop table #t_jg;
    select  distinct pk_org,a.branch_no,hr_name,b.dep_code as xy_pk_org,
        case when  a.branch_type ='�ܲ�'               then  '�ܲ�'
             when  hr_pk=father_branch_hrpk_root     then 'һ���ֹ�˾'
             when  secondary_branch_hrpk is not null then '�����ֹ�˾'
             when  hr_pk<>father_branch_hrpk_direct or a.branch_type ='Ӫҵ��' then 'Ӫҵ��'
         end jglb  ,
        father_branch_hrpk_root,
        father_branch_name_root,
        father_branch_hrpk_direct,
        father_branch_name_direct,
        secondary_branch_hrpk,
        secondary_branch_name
into #t_jg
from dba.t_dim_org  a
left join DBA.T_ODS_CF_V_BRANCH b on convert(varchar,b.branch_no)=convert(varchar,a.branch_no)
order by jglb ;

commit;

delete from DM.T_PUB_ORG_RIGH_INFO where load_dt <=@v_bin_date;
insert into  DM.T_PUB_ORG_RIGH_INFO
(	ORG_TYPE             ,
	WH_ORG_ID            ,
	HS_ORG_ID            ,
	XY_ORG_ID            ,
	ORG_NAME             ,
	UDRBRL_WH_ORG_ID     ,
	UDRBRL_HS_ORG_ID     ,
	UDRBRL_XY_ORG_ID     ,
	UDRBRL_ORG_NAME      ,
	LOAD_DT              
)
select  jglb                 as ORG_TYPE ,--- �������
       pk_org               as WH_ORG_ID ,--- �ֿ��������
       branch_no            as HS_ORG_ID ,--- ������������
       xy_pk_org            as XY_ORG_ID ,--- �����������
       hr_name              as ORG_NAME ,--- ��������
       case when permission_pk_org is null then ''  else permission_pk_org       end  as UDRBRL_WH_ORG_ID ,--- �¹Ҳֿ��������
       case when permission_branch_no is null then ''  else permission_branch_no end  as UDRBRL_HS_ORG_ID ,--- �¹Һ�����������
       permission_xy_pk_org  as UDRBRL_XY_ORG_ID ,--- �¹������������
       case when permission_hr_name is null then ''  else permission_hr_name     end as UDRBRL_ORG_NAME ,--- �¹һ�������
       @v_bin_date           as LOAD_DT  --- ��ϴ����
into #t_fgs
  from (select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join (select distinct pk_org, branch_no, hr_name,xy_pk_org, '�ܲ�' as fz
                      from #t_jg
                     where jglb <> '�ܲ�'
                       and jglb is not null) b
            on a.jglb = b.fz
         where a.jglb = '�ܲ�' ---�ܲ�Ȩ�޵�λ
        union all
        select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join #t_jg b
            on a.hr_name = b.father_branch_name_root
         where a.jglb = 'һ���ֹ�˾' ---һ���ֹ�˾
        union all
        select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join #t_jg b
            on a.hr_name = b.secondary_branch_name
         where a.jglb = '�����ֹ�˾' ---�����ֹ�˾
        union all
        select distinct a.jglb,
                        a.pk_org,
                        a.branch_no,
                        a.hr_name,a.xy_pk_org,
                        b.pk_org    as permission_pk_org,
                        b.branch_no as permission_branch_no,
                        b.hr_name   as permission_hr_name,b.xy_pk_org as permission_xy_pk_org
          from #t_jg a
          left join #t_jg b
            on a.pk_org = b.pk_org and a.hr_name=b.hr_name
         where a.jglb = 'Ӫҵ��' ---Ӫҵ��
        ) s
 order by s.jglb,s.pk_org;



commit;


end
GO
GRANT EXECUTE ON dm.P_PUB_RIGH_INFO TO query_dev
GO
CREATE PROCEDURE dm.P_PUB_SECU_INDT_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ֤ȯ��ҵ����ά��
  ��д��: DCY
  ��������: 2017-12-11
  ��飺֤ȯ��ҵ����ά����ϴ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
  
   --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_PUB_SECU_INDT_TYPE ;
  
  
   --��ʼ��������
  INSERT INTO DM.T_PUB_SECU_INDT_TYPE
  (
    SECU_CD               --֤ȯ����
   ,SECU_NAME             --֤ȯ����
   ,MKT_TYPE              --�г�����
   ,wind_PRI_INDT_CD      --windһ����ҵ����
   ,wind_PRI_INDT_NAME    --windһ����ҵ����
   ,wind_SCDY_INDT_CD     --wind������ҵ����
   ,wind_SCDY_INDT_NAME   --wind������ҵ����
   ,wind_THRDY_INDT_CD    --wind������ҵ����
   ,wind_THRDY_INDT_NAME  --wind������ҵ����
   ,CITIC_PRI_INDT_CD     --����һ����ҵ����
   ,CITIC_PRI_INDT_NAME   --����һ����ҵ����
   ,CITIC_SCDY_INDT_CD    --���Ŷ�����ҵ����
   ,CITIC_SCDY_INDT_NAME  --���Ŷ�����ҵ����
   ,CITIC_THRDY_INDT_CD   --����������ҵ����
   ,CITIC_THRDY_INDT_NAME --����������ҵ����
   ,LOAD_DT              --��ϴ����   
   )
  
  SELECT 
   A1.SECU_CD               --֤ȯ����
  ,A1.SECU_NAME             --֤ȯ����
  ,A1.MKT_TYPE              --�г�����
  ,A1.wind_PRI_INDT_CD      --windһ����ҵ����
  ,A1.wind_PRI_INDT_NAME    --windһ����ҵ����
  ,A2.wind_SCDY_INDT_CD     --wind������ҵ����
  ,A2.wind_SCDY_INDT_NAME   --wind������ҵ����
  ,A3.wind_THRDY_INDT_CD    --wind������ҵ����
  ,A3.wind_THRDY_INDT_NAME  --wind������ҵ����
  ,B1.CITIC_PRI_INDT_CD     --����һ����ҵ����
  ,B1.CITIC_PRI_INDT_NAME   --����һ����ҵ����
  ,B2.CITIC_SCDY_INDT_CD    --���Ŷ�����ҵ����
  ,B2.CITIC_SCDY_INDT_NAME  --���Ŷ�����ҵ����
  ,B3.CITIC_THRDY_INDT_CD   --����������ҵ����
  ,B3.CITIC_THRDY_INDT_NAME --����������ҵ����
  ,@V_BIN_DATE    --��ϴ����   
  FROM
  (
  --windһ����ҵ��������
	Select
	 F16_1090 as SECU_CD                            --֤ȯ����
	 ,ob_object_name_1090  as SECU_NAME             --֤ȯ����
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --�г�����
     ,code as wind_PRI_INDT_CD                          --windһ����ҵ����
	 ,a.name as wind_PRI_INDT_NAME    --windһ����ҵ����
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,4)=substr(a.code,1,4)
	Where a.code Like '62%'
		  And a.levelnum=2
		  And F6_1400=1
		  And F4_1090 In ('A','B')
   )A1
  JOIN
  (
  --wind������ҵ��������
	Select
	 F16_1090 as SECU_CD                            --֤ȯ����
	 ,ob_object_name_1090  as SECU_NAME             --֤ȯ����
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --�г�����
     ,code as wind_SCDY_INDT_CD                          --wind������ҵ����
	 ,replace (a.name,'��','') as wind_SCDY_INDT_NAME    --wind������ҵ����
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,6)=substr(a.code,1,6)
	Where a.code Like '62%'
		  And a.levelnum=3
		  And F6_1400=1
		  And F4_1090 In ('A','B')		  
	)A2 ON A1.SECU_CD=A2.SECU_CD
   JOIN	
   (   
  --wind������ҵ��������
	Select
	 F16_1090 as SECU_CD                            --֤ȯ����
	 ,ob_object_name_1090  as SECU_NAME             --֤ȯ����
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --�г�����
     ,code as wind_THRDY_INDT_CD                          --wind������ҵ����
	 ,replace (a.name,'��','') as wind_THRDY_INDT_NAME    --wind������ҵ����
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,8)=substr(a.code,1,8)
	Where a.code Like '62%'
		  And a.levelnum=4
		  And F6_1400=1
		  And F4_1090 In ('A','B')			  
	)A3	ON A1.SECU_CD=A3.SECU_CD  
   LEFT JOIN	
   (     
  --����һ����ҵ��������
	Select
	 F16_1090 as SECU_CD                            --֤ȯ����
	 ,ob_object_name_1090  as SECU_NAME             --֤ȯ����
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --�г�����
     ,code as CITIC_PRI_INDT_CD                          --����һ����ҵ����
	 ,a.name as CITIC_PRI_INDT_NAME    --����һ����ҵ����
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,4)=substr(a.code,1,4)
	Where a.code Like 'b1%'
		  And a.levelnum=2
		  And F6_1400=1
		  And F4_1090 In ('A','B')		  
	)B1	ON A1.SECU_CD=B1.SECU_CD  
   LEFT JOIN	
   (     
  --���Ŷ�����ҵ��������
	Select
	 F16_1090 as SECU_CD                            --֤ȯ����
	 ,ob_object_name_1090  as SECU_NAME             --֤ȯ����
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --�г�����
     ,code as CITIC_SCDY_INDT_CD                          --���Ŷ�����ҵ����
	 ,replace (a.name,'��','') as CITIC_SCDY_INDT_NAME    --���Ŷ�����ҵ����
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,6)=substr(a.code,1,6)
	Where a.code Like 'b1%'
		  And a.levelnum=3
		  And F6_1400=1
		  And F4_1090 In ('A','B')			  
	)B2	ON A1.SECU_CD=B2.SECU_CD  
   LEFT JOIN		
   (     
  --����������ҵ��������
	Select
	 F16_1090 as SECU_CD                            --֤ȯ����
	 ,ob_object_name_1090  as SECU_NAME             --֤ȯ����
	 ,case when f27_1090 ='SSE' then '1' WHEN f27_1090 ='SZSE' THEN '2' ELSE '9999' END AS MKT_TYPE              --�г�����
     ,code as CITIC_THRDY_INDT_CD                          --����������ҵ����
	 ,replace (a.name,'��','') as CITIC_THRDY_INDT_NAME    --����������ҵ����
	From dba.T_EDW_JRZX_TB_OBJECT_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1400 On F1_1400 = OB_REVISIONS_1090
		 Inner Join dba.T_ODS_JRZX_TB_OBJECT_1022 a On substr(f3_1400,1,8)=substr(a.code,1,8)
	Where a.code Like 'b1%'
		  And a.levelnum=4
		  And F6_1400=1
		  And F4_1090 In ('A','B')			  
	)B3	ON A1.SECU_CD=B3.SECU_CD
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_SECU_INDT_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_SECU_INDT_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_PUB_SECU_TYPE(IN @V_BIN_DATE INT,OUT @V_OUT_FLAG  INT)
BEGIN 
  
  /******************************************************************
  ������: ֤ȯ����ά��
  ��д��: DCY
  ��������: 2017-11-24
  ��飺֤ȯ����ά����ϴ
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
           
  *********************************************************************/

  
  SET @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
      
   --PART0 ɾ��Ҫ��ϴ������
  DELETE FROM DM.T_PUB_SECU_TYPE ;
  
   --��ʼ��������
  INSERT INTO DM.T_PUB_SECU_TYPE
  (
    SECU_TYPE_MCGY_ID    --֤ȯ���ʹ������
   ,SECU_TYPE_SUB_ID     --֤ȯ�����������
   ,SECU_TYPE_MCGY_NAME  --֤ȯ���ʹ�������
   ,SECU_TYPE_SUB_NAME   --֤ȯ������������
   ,LOAD_DT              --��ϴ����
   )
	  
  SELECT DISTINCT 
	 NULL AS SECU_TYPE_MCGY_ID    --֤ȯ���ʹ������(��ʱ����Ϊ�գ��������޸�)
	,TOUS.stock_type AS  SECU_TYPE_SUB_ID     --֤ȯ�����������
	, NULL AS SECU_TYPE_MCGY_NAME  --֤ȯ���ʹ�������
	,DIC.DICT_PROMPT AS  SECU_TYPE_SUB_NAME --֤ȯ������������
    ,@V_BIN_DATE    --��ϴ���� 
	
  FROM DBA.T_ODS_UF2_SCLXDZ TOUS
  LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY DIC ON TOUS.STOCK_TYPE=DIC.SUBENTRY  AND   DIC.DICT_ENTRY=1206 -- ����ֱ�Ӳ���1206���ֵ�
	-- LEFT JOIN DBA.T_EDW_T06_PUBLIC_CODE TETPC ON  TOUS.MKT_TYPE=TETPC.CODE_CD  AND FIELD_ENG_NAME='market_type_cd' --�ֿ��г�����
  ;
  COMMIT;
	
  SET @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0    
   COMMIT;
END
GO
GRANT EXECUTE ON dm.P_PUB_SECU_TYPE TO query_dev
GO
GRANT EXECUTE ON dm.P_PUB_SECU_TYPE TO xydc
GO
CREATE PROCEDURE dm.P_VAR_ASSM(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_Ʒ�֣��ʹܲ�Ʒ��������ƣ�
      ��д�ߣ�chenhu
      �������ڣ�2017-11-30
      ��飺
           ������ƻ�����Ϣ
    *********************************************************************/

    COMMIT;
    --ɾ����������
    DELETE FROM DM.T_VAR_ASSM WHERE OCCUR_DT = @V_IN_DATE;
    
    --���뵱������
    INSERT INTO DM.T_VAR_ASSM
        (PROD_CD,PROD_NAME,OCCUR_DT,IMGT_PD_TYPE,PURS_UNIT,FUND_CLS_END_DT,FRNT_CHAG_TYPE,INSM_SCP,INSM_STRA,EXPE_PAYF_RATE,TRD_STAT,PROD_SCAL,PROD_SETP_SCAL,
         REDP_DAYS,OPEN_DT,INSM_MNGR_NAME,LOAD_DT)
    SELECT PDP.SECCODE AS PROD_CD                   --��Ʒ����
         ,PDP.PRODUCT_NAME AS PROD_NAME            --��Ʒ����
         ,PFC.LOAD_DT AS OCCUR_DT            --ҵ������
         ,'1' AS IMGT_PD_TYPE                --�ʹܲ�Ʒ���� : 1 ������ƣ� 2 �������
         ,PFC.PURCHASE_UNIT AS PURS_UNIT       --�깺��λ
         ,PFC.CLOSE_DAY AS FUND_CLS_END_DT     --�����ս�������
         ,PFC.CHARGE_TYPE AS FRNT_CHAG_TYPE     --ǰ���շ�����
         ,PFC.INVESTMENT_SCOPE AS INSM_SCP          --Ͷ�ʷ�Χ
         ,CASE WHEN PFC.INVESTMENT_STRATEGY = '' THEN NULL ELSE PFC.INVESTMENT_STRATEGY END AS INSM_STRA       --Ͷ�ʲ���
         ,PFC.INVESTMENT_EXPECTED AS EXPE_PAYF_RATE    --Ԥ��������
         ,CASE WHEN PFC.TRADING_STATUS = '' THEN NULL ELSE PFC.TRADING_STATUS END AS TRD_STAT            --����״̬
         ,PFC.FINALNET_ASSETS AS PROD_SCAL           --��Ʒ��ģ
         ,PFC.ESTABLISHMENT_SCALE AS PROD_SETP_SCAL      --��Ʒ������ģ
         ,CASE WHEN PFC.REDEEMABLETART_DATE = '' THEN NULL ELSE CONVERT(NUMERIC(10,0),PFC.REDEEMABLETART_DATE) END AS REDP_DAYS           --�������
         ,PFC.OPEN_DATE AS OPEN_DT             --��������
         ,PFC.INVEST_MANAGER AS INSM_MNGR_NAME     --Ͷ�ʾ�������
         ,PFC.LOAD_DT           --��ϴ����
    FROM DBA.T_EDW_PD_T_PROD_FINANCIAL_COLLECTION PFC
    LEFT JOIN DBA.T_EDW_PD_V_PROD_DC_PRODUCT PDP
    ON PFC.PRODUCT_ID = PDP.PRODUCT_ID
    AND PFC.LOAD_DT = PDP.LOAD_DT
    WHERE PFC.LOAD_DT = @V_IN_DATE
    AND PDP.SECCODE IS NOT NULL;          -- PRODUCT��Ϊ�����Ĳ�Ʒ������������˵��δ���
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_ASSM TO xydc
GO
CREATE PROCEDURE dm.P_VAR_BKCM_PFVU(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_Ʒ�֣��������_����ƾ֤
      ��д�ߣ�chenhu
      �������ڣ�2017-11-23
      ��飺
        ������ƺ�����ƾ֤��Ʒ��Ϣ
    *********************************************************************/

    COMMIT;
    
    --ɾ����������
    DELETE FROM DM.T_VAR_BKCM_PFVU WHERE OCCUR_DT = @V_IN_DATE;
    --���뵱������
    INSERT INTO DM.T_VAR_BKCM_PFVU
        (PRODTA_NO,PROD_CD,OCCUR_DT,PROD_TYPE,PROD_NAME,PROD_ALIAS,PROD_CORP,PROD_MATY,RISK_RAK,INSM_TYPE,PAYF_TYPE,EXPE_RCKON_RETN,CCY_TYPE,COLL_STRT_DT,COLL_END_DT,
         SUBS_END_DT,PROD_SETP_DT,PROD_END_DT,RCDINFO_END_DT,PROD_BACK_N,ORDR_MODE,PROD_STAT,SUB_UNIT,IDV_FST_LOW_AMT,IDV_LOW_SUBS_AMT,IDV_LOW_PURS_AMT,LISTS_DAY_PURS_MAX_AMT,
         ORG_FST_LOW_AMT,ORG_LOW_SUBS_AMT,ORG_LOW_PURS_AMT,LOAD_DT)
    SELECT  PRODTA_NO	AS	PRODTA_NO  --��ƷTA���
        ,PROD_CODE	AS	PROD_CD  --��Ʒ����
        ,LOAD_DT	AS	OCCUR_DT  --ҵ������
        ,PROD_TYPE	AS	PROD_TYPE  --��Ʒ���
        ,PROD_NAME	AS	PROD_NAME  --��Ʒ����
        ,PRODALIAS_NAME	AS	PROD_ALIAS  --��Ʒ����
        ,PRODCOMPANY_NAME	AS	PROD_CORP  --��Ʒ��˾
        ,PROD_TERM	AS	PROD_MATY  --��Ʒ����
        ,PRODRISK_LEVEL	AS	RISK_RAK  --���յȼ�
        ,INVEST_TYPE	AS	INSM_TYPE  --Ͷ�����
        ,INCOME_TYPE	AS	PAYF_TYPE  --��������
        ,PRODPRE_RATIO	AS	EXPE_RCKON_RETN  --Ԥ����������
        ,MONEY_TYPE	AS	CCY_TYPE  --�������
        ,IPO_BEGIN_DATE	AS	COLL_STRT_DT  --ļ����ʼ����
        ,IPO_END_DATE	AS	COLL_END_DT  --ļ����������
        ,SUBCONF_ENDDATE	AS	SUBS_END_DT  --�Ϲ���ֹ����
        ,PROD_BEGIN_DATE	AS	PROD_SETP_DT  --��Ʒ��������
        ,PROD_END_DATE	AS	PROD_END_DT  --��Ʒ��������
        ,INTEREST_END_DATE	AS	RCDINFO_END_DT  --��Ϣ��������
        ,PROD_BACK_N	AS	PROD_BACK_N  --��ƷT+N����
        ,EN_ENTRUST_WAY	AS	ORDR_MODE  --ί�з�ʽ
        ,PROD_STATUS	AS	PROD_STAT  --��Ʒ״̬
        ,SUB_UNIT	AS	SUB_UNIT  --�Ϲ�/�깺��λ
        ,OPEN_SHARE	AS	IDV_FST_LOW_AMT  --�����״���ͽ��
        ,MIN_SHARE	AS	IDV_LOW_SUBS_AMT  --��������Ϲ����
        ,MIN_SHARE2	AS	IDV_LOW_PURS_AMT  --��������깺���
        ,MAX_PDSHARE	AS	LISTS_DAY_PURS_MAX_AMT  --�����깺��߽��
        ,MINSIZE	AS	ORG_FST_LOW_AMT  --�����״���ͽ��
        ,ORG_LOWLIMIT_BALANCE	AS	ORG_LOW_SUBS_AMT  --��������Ϲ����
        ,ORG_LOWLIMIT_BALANCE2	AS	ORG_LOW_PURS_AMT  --��������깺���
        ,LOAD_DT	AS	LOAD_DT  --��ϴ����
    FROM DBA.T_EDW_UF2_PRODCODE
    WHERE LOAD_DT = @V_IN_DATE
    AND ( PRODTA_NO LIKE 'D%'         --�������
          OR PRODTA_NO LIKE 'C%');    --����ƾ֤
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_BKCM_PFVU TO xydc
GO
CREATE PROCEDURE dm.P_VAR_OPTN(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_Ʒ�֣���Ȩ
      ��д�ߣ�chenhu
      �������ڣ�2017-11-27
      ��飺
             ��Ȩ��Լ��Ʒ��Ϣ
    *********************************************************************/

    COMMIT;
    
    --ɾ����������
    DELETE FROM DM.T_VAR_OPTN WHERE OCCUR_DT = @V_IN_DATE;
    --���뵱������
    INSERT INTO DM.T_VAR_OPTN
        (CONT_ID,DELIV_MODE_CD,OCCUR_DT,EXER_PRC,MKT_TYPE_CD,CONT_TYPE_CD,SUBJ_SECU_CD,CONT_UNIT,FST_TRD_DAY ,LAST_TRD_DAY,EXER_DAY,MATU_DAY,DELI_DAY,NO_COVR_CONT_NUM,
        PLMT_LMT_TYPE_CD,LPRIC_UNIT_UPLMT,LPRIC_UNIT_LWRB,MATU_DAY_FLAG,MPRIC_UNIT_UPLMT,MPRIC_UNIT_LWRB,OPEP_MARG_LOW_STD,TRD_CD,CONT_STAT_CD,MIN_QUOT_UNIT,OPTN_FEER,LOAD_DT)
    SELECT OPTION_CODE AS CONT_ID              --��Լ����
        ,OPTION_MODE AS DELIV_MODE_CD           --���ʽ���룺E ŷʽ ��A ��ʽ
        ,LOAD_DT AS OCCUR_DT                    --ҵ������
        ,EXERCISE_PRICE AS EXER_PRC             --��Ȩ��Ȩ�ļ۸�
        ,EXCHANGE_TYPE AS MKT_TYPE_CD           --�г����ʹ���
        ,OPTION_TYPE AS CONT_TYPE_CD            --��Լ���ʹ��룺C �Ϲ�, P �Ϲ�
        ,STOCK_CODE AS SUBJ_SECU_CD             --���֤ȯ����
        ,AMOUNT_PER_HAND AS CONT_UNIT           --��Լ��λ(��Լ����)
        ,BEGIN_DATE AS FST_TRD_DAY              --�׸�������
        ,END_DATE AS LAST_TRD_DAY               --�������
        ,EXE_BEGIN_DATE AS EXER_DAY             --��Ȩ��
        ,EXE_END_DATE AS MATU_DAY               --������
        ,DELIVER_DATE AS DELI_DAY               --������
        ,UNDROP_AMOUNT AS NO_COVR_CONT_NUM      --δƽ�ֺ�Լ��
        ,PRICE_LIMIT_KIND AS PLMT_LMT_TYPE_CD    --�ǵ����������ʹ���
        ,LIMIT_HIGH_AMOUNT AS LPRIC_UNIT_UPLMT   --�޼۵����걨����
        ,LIMIT_LOW_AMOUNT AS LPRIC_UNIT_LWRB     --�޼۵����걨����
        ,OPT_FINAL_STATUS AS MATU_DAY_FLAG       --�����ձ�־
        ,MKT_HIGH_AMOUNT AS MPRIC_UNIT_UPLMT     --�м۵����걨����
        ,MKT_LOW_AMOUNT AS MPRIC_UNIT_LWRB       --�м۵����걨����
        ,INITPER_BALANCE AS OPEP_MARG_LOW_STD    --���ֱ�֤����ͱ�׼
        ,OPTCONTRACT_ID AS TRD_CD                --���״���
        ,OPTCODE_STATUS AS CONT_STAT_CD          --��Լ״̬����
        ,OPT_PRICE_STEP AS MIN_QUOT_UNIT         --��С���۵�λ
        ,NULL AS OPTN_FEER                      --��Ȩ����
        ,LOAD_DT AS LOAD_DT                      --��ϴ����  
    FROM DBA.T_EDW_UF2_OPTCODE
    WHERE LOAD_DT = @V_IN_DATE;
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_OPTN TO xydc
GO
CREATE PROCEDURE dm.P_VAR_PO_FUND(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_Ʒ�֣���ļ����
      ��д�ߣ�chenhu
      �������ڣ�2017-11-29
      ��飺
        ��ļ���������Ϣ
    *********************************************************************/

    COMMIT;
    --ɾ����������
    DELETE FROM DM.T_VAR_PO_FUND WHERE OCCUR_DT = @V_IN_DATE;
    
    --���뵱������
    INSERT INTO DM.T_VAR_PO_FUND
        (PROD_CD,OCCUR_DT,CLS_PERI,ISS_QUO,REDP_ARVD_DAYS,IF_PAUSE_LARGE_AMT_PURS,PERF_CONT_BASI,INSM_SCP,INSM_STRA,INSM_MNGR,IF_IS_ETF,IF_IS_LOF,IF_ISQDII,
         CASTSL_PURS_LOW_AMT,IF_AGNS,SUBS_PERI,PROD_MNGR,FRNT_TERN_CHAG_TYPE,LOAD_DT) 
    SELECT PROD.SECCODE AS PROD_CD                       --��Ʒ����
        ,PF.LOAD_DT AS OCCUR_DT                           --ҵ������
        ,CASE WHEN PF.CLOSED_PERIOD = '' THEN NULL ELSE CONVERT(NUMERIC(10,0),PF.CLOSED_PERIOD) END AS CLS_PERI  --�����(��)
        ,NULL --PF.ISSUE_AMONUT 
         AS ISS_QUO                       --���ж�� ��Դͷ�������⣬�������£�
        ,NULL --PF.REDEEMABLETART_DATE 
         AS REDP_ARVD_DAYS          --��ص������� ��Դͷ�������⣬�������£�
        ,CASE WHEN PF.SUSPENDED_LARGE_PURCHASE = '��' THEN 1 
               WHEN PF.SUSPENDED_LARGE_PURCHASE = '��' THEN 0
               ELSE NULL END AS IF_PAUSE_LARGE_AMT_PURS    --�Ƿ���ͣ����깺
        ,PF.PERFORMANCE_BENCHMARK AS PERF_CONT_BASI                --ҵ���Ƚϻ�׼
        ,PF.INVESTMENT_SCOPE AS INSM_SCP                           --Ͷ�ʷ�Χ
        ,PF.INVESTMENT_STRATEGY AS INSM_STRA                       --Ͷ�ʲ���
        ,PF.INVEST_MANAGER AS INSM_MNGR                   --Ͷ�ʾ���
        ,CASE WHEN PF.IS_ETF = '' THEN NULL ELSE CONVERT(INT,PF.IS_ETF) END AS IF_IS_ETF                           --�Ƿ���ETF
        ,CASE WHEN PF.IS_LOF = '' THEN NULL ELSE CONVERT(INT,PF.IS_LOF) END AS IF_IS_LOF                           --�Ƿ���LOF
        ,CASE WHEN PF.IS_QDII = '' THEN NULL ELSE CONVERT(INT,PF.IS_QDII) END AS IF_ISQDII                           --�Ƿ���QDII
        ,PF.MIN_SCHEDULED_AMOUNT AS CASTSL_PURS_LOW_AMT    --��Ͷ�깺��ͽ��
        ,NULL --PF.ISFOR_SALE 
         AS IF_AGNS                           --�Ƿ���� ��Դͷ�������⣬�������£�
        ,NULL --PF.OPENED_PERIOD 
         AS SUBS_PERI                        --�Ϲ��ڣ�Դͷ�������⣬�������£�
         ,NULL AS PROD_MNGR                        --��Ʒ���� (�������£�
        ,PF.CHARGE_TYPE AS FRNT_TERN_CHAG_TYPE              --ǰ����շ�����
        ,PF.LOAD_DT AS LOAD_DT                           --��ϴ����
    FROM DBA.T_EDW_PD_T_PROD_PUBLICFUND PF
    LEFT JOIN DBA.T_EDW_PD_V_PROD_DC_PRODUCT PROD
    ON PF.PRODUCT_ID = PROD.PRODUCT_ID
    AND PF.LOAD_DT = PROD.LOAD_DT
    WHERE PF.LOAD_DT = @V_IN_DATE
    AND PROD.SECCODE IS NOT NULL
    AND PROD.SECCODE <> '';          -- PRODUCT��Ϊ�����Ĳ�Ʒ������������˵��δ���
    
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_PO_FUND TO xydc
GO
CREATE PROCEDURE dm.P_VAR_PROD_OTC(IN @V_IN_DATE NUMERIC(10,0))
BEGIN
    /******************************************************************
      ����˵����˽�Ƽ���_Ʒ�֣������Ʒά��
      ��д�ߣ�chenhu
      �������ڣ�2017-11-30
      ��飺
           �����Ʒ�Ļ�����Ϣ
           
      -- ���ӳ��ڲ�Ʒ  update by chenhu  20180119
      -- ���Ӳ����������ͣ�  'A'  �������꣬ 'N'  ETF���꣬ 'K'  �����Ϲ���'M'  ETF�Ϲ��� ������ֻ���룺940002,940003    update by chenhu 20180207
    *********************************************************************/

    COMMIT;
    --ɾ����������
    DELETE FROM DM.T_VAR_PROD_OTC WHERE OCCUR_DT = @V_IN_DATE;
    
    --���뵱������(���⣩
    INSERT INTO DM.T_VAR_PROD_OTC
        (PROD_CD,OCCUR_DT,TA_NO,PROD_NAME,PROD_TYPE,PROD_INVER_TYPE,IF_KEY_PROD,RISK_RAK,CSTD_ORG,MNG_PSN_NAME,END_DT,PROD_STAT,PROD_PAYF_FETUR,
         SETP_DT,TRD_CCY,SAVC_PERI,CSTD_BANK,SUBS_STRT_TIME,SUBS_END_TIME,BEGN_PURC_AMT,LOAD_DT)
    SELECT PP.PROD_TRD_CD AS PROD_CD      --��Ʒ����  
         ,PP.LOAD_DT AS OCCUR_DT      --ҵ������
         ,PP.TA_NO AS TA_NO      --TA���  
         ,PP.PROD_NAME AS PROD_NAME      --��Ʒ����         
         ,PP.PROD_TYPE AS PROD_TYPE      --��Ʒ����         
         ,PP.INVEST_TO_TYPE AS PROD_INVER_TYPE      --��ƷͶ������
         ,CASE WHEN EMPHASIS_FUND='' THEN NULL ELSE CONVERT(INT,PUB.EMPHASIS_FUND) END AS IF_KEY_PROD      --�Ƿ��ص��Ʒ   
         ,PP.RISK_RAK AS RISK_RAK      --���յȼ�          
         ,PP.CSTD_PSN AS CSTD_ORG      --�йܻ���          
         ,PP.BASEGODLEN_MGR_PSN_NAME AS MNG_PSN_NAME      --����������    
         ,CASE WHEN PP.TML_DT='' THEN NULL ELSE CONVERT(INT,SUBSTR(PP.TML_DT,1,4))*10000 + CONVERT(INT,SUBSTR(PP.TML_DT,6,2))*100 + CONVERT(INT,SUBSTR(PP.TML_DT,9,2)) END AS END_DT      --��ֹ����            
         ,PP.MULITGODLEN_BASEGODLEN_STAT AS PROD_STAT      --��Ʒ״̬         
         ,PP.INCM_FETUR AS PROD_PAYF_FETUR      --��Ʒ��������
         ,CASE WHEN PP.SETUP_DT='' THEN NULL ELSE CONVERT(INT,SUBSTR(PP.SETUP_DT,1,4))*10000 + CONVERT(INT,SUBSTR(PP.SETUP_DT,6,2))*100 + CONVERT(INT,SUBSTR(PP.SETUP_DT,9,2)) END AS SETP_DT      --��������           
         ,UP.MONEY_TYPE AS TRD_CCY      --���ױ���           
         ,PP.DURA_DT AS SAVC_PERI      --������           
         ,UP.TRUSTEE_BANK AS CSTD_BANK      --�й�����         
         ,PP.SCRP_STRT_DT AS SUBS_STRT_TIME      --�Ϲ���ʼʱ��
         ,PP.SCRP_END_DT AS SUBS_END_TIME      --�Ϲ�����ʱ�� 
         ,UP.MIN_SHARE2 AS BEGN_PURC_AMT      --�𹺽��     
         ,PP.LOAD_DT AS LOAD_DT      --��ϴ���� 
    FROM (     
			SELECT * FROM (
			SELECT A.*,ROW_NUMBER() OVER  (PARTITION BY PROD_TRD_CD ORDER BY VOU_INPT_TIME DESC) RN
			FROM DBA.T_EDW_PD_V_PROD_PRODUCTINFO A WHERE (A.REC_STATUS IN ('1','2') OR A.PROD_TRD_CD IN ('940002','940003') ) AND A.LOAD_DT  = @V_IN_DATE
			) B
			WHERE B.RN=1   
    ) PP
    LEFT JOIN DBA.T_EDW_UF2_PRODCODE UP
    ON PP.PROD_TRD_CD = UP.PROD_CODE
    AND PP.LOAD_DT = UP.LOAD_DT
    LEFT JOIN DBA.T_EDW_PD_T_PROD_PUBLICFUND PUB
    ON PP.PROD_NO = PUB.PRODUCT_ID
    AND PP.LOAD_DT = PUB.LOAD_DT
    WHERE PP.LOAD_DT = @V_IN_DATE
    AND  PP.PROD_TRD_CD IS NOT NULL
    AND  PP.PROD_TRD_CD <>''
    AND ( PP.REC_STATUS IN ('1','2') OR PP.PROD_TRD_CD IN ('940002','940003') );            --��¼״̬��'-1','ɾ��','1','δ���','2','���','0','�ݸ�' ,   940002,940003 ���⴦��

   --���뵱������(���ڣ�
    INSERT INTO DM.T_VAR_PROD_OTC
        (PROD_CD,OCCUR_DT,TA_NO,PROD_NAME,PROD_TYPE,PROD_INVER_TYPE,IF_KEY_PROD,RISK_RAK,CSTD_ORG,MNG_PSN_NAME,END_DT,PROD_STAT,PROD_PAYF_FETUR,
         SETP_DT,TRD_CCY,SAVC_PERI,CSTD_BANK,SUBS_STRT_TIME,SUBS_END_TIME,BEGN_PURC_AMT,LOAD_DT)
    SELECT A.STOCK_CODE AS PROD_CD
        ,A.LOAD_DT AS OCCUR_DT
        ,NULL AS TA_NO
        ,A.STOCK_NAME AS PROD_NAME
        ,CASE WHEN B.JJLB LIKE '%��ļ%' THEN '��ļ����' 
              WHEN B.JJLB LIKE '%˽ļ%' THEN '˽ļ����' 
              WHEN B.JJLB LIKE '%����ר��%' THEN '����ר��' 
              WHEN B.JJLB LIKE '%�������%' THEN '�������' 
               WHEN B.JJLB IS NULL THEN 'δ����' 
              ELSE B.JJLB END  AS PROD_TYPE
        ,CASE WHEN B.JJLB LIKE '%����%' THEN '����' 
              WHEN B.JJLB LIKE '%��Ʊ%' THEN 'Ȩ��' 
              WHEN B.JJLB LIKE '%ծȯ%' THEN 'ծȯ' 
              WHEN B.JJLB IS NULL THEN 'δ����' 
              ELSE B.JJLB END AS PROD_INVER_TYPE
        ,NULL AS IF_KEY_PROD
        ,CASE WHEN C.DICT_PROMPT LIKE '%R%' THEN SUBSTR(C.DICT_PROMPT,4) ELSE C.DICT_PROMPT END AS RISK_RAK
        ,NULL AS CSTD_ORG
        ,B.GSMC AS MNG_PSN_NAME
        ,A.DELIST_DATE AS END_DT
        ,NULL AS PROD_STAT
        ,CASE WHEN B.JJLB LIKE '%����%' THEN '�ֽ���' 
              WHEN B.JJLB LIKE '%��Ʊ%' THEN '��������' 
              WHEN B.JJLB LIKE '%ծȯ%' THEN '��̶�����' 
              ELSE NULL END AS PROD_PAYF_FETUR
        ,ISSUE_DATE AS SETP_DT
        ,A.MONEY_TYPE AS TRD_CCY
        ,NULL AS SAVC_PERI
        ,NULL AS CSTD_BANK
        ,NULL AS SUBS_STRT_TIME
        ,NULL AS SUBS_END_TIME
        ,A.LOW_BALANCE AS BEGN_PURC_AMT
        ,A.LOAD_DT AS LOAD_DT
    FROM DBA.T_EDW_UF2_STKCODE A
    LEFT JOIN DBA.T_DDW_D_JJ B
    ON B.NIAN=SUBSTR(CONVERT(VARCHAR,A.LOAD_DT),1,4) AND B.YUE=SUBSTR(CONVERT(VARCHAR,A.LOAD_DT),5,2)
    AND A.STOCK_CODE = B.JJDM
    LEFT JOIN DBA.T_ODS_UF2_SYSDICTIONARY C ON C.DICT_ENTRY=2506
    AND CONVERT(VARCHAR,A.ELIG_RISK_LEVEL) = C.SUBENTRY
    WHERE A.STOCK_TYPE IN ('1','6','L','T','j','l','A','N','K','M') --/*����Ͷ�ʻ���LOF����ETF���𣬻���ETF���𣬹�ծETF���𣬻������꣬ETF���꣬�����Ϲ���ETF�Ϲ�*/
    AND A.LOAD_DT=@V_IN_DATE 
    AND A.STOCK_CODE NOT IN (
    SELECT DISTINCT PROD_CD FROM DM.T_VAR_PROD_OTC WHERE OCCUR_DT=@V_IN_DATE 
    );
        
    COMMIT;
END
GO
GRANT EXECUTE ON dm.P_VAR_PROD_OTC TO xydc
GO
CREATE PROCEDURE dm.tmp_ast_odi(IN @V_BIN_DATE numeric(8,0),OUT @V_OUT_FLAG  NUMERIC(1))

begin   
  /******************************************************************
  ������: �ͻ���ͨ�ʲ���
  ��д��: rengz
  ��������: 2017-11-16
  ��飺���������ü�����Ʒ�ȵ���ͨ�˻��ʲ����ո���
       ��Ҫָ��ο�ȫ��ͼ�ձ��ո���dba.tmp_ddw_khqjt_d_d���д���
  *********************************************************************
  �޶���¼�� �޶�����       �汾��    �޶���             �޸����ݼ�Ҫ˵��
             2017-12-06               rengz              �޶�˽ļ���𣬸��ݹ�̨��Ʒ����з��� dba.t_edw_uf2_prodcode where  prodcode_type='j'
             2017-12-20               rengz              ���ӹ�ļ������ֵ
             2018-1-31                rengz              ���ݾ���ҵ���ܲ�Ҫ������ �ɻ���ֵ��������Ʒ��ֵ��δ���û���������Ϊ�գ��������ʲ���Լ��������Ѻ��ֵ����ĩ�ʲ����ֶ� 
             2018-2-23                rengz              ��201601-201704�����ȼ�������ȱʧ���֣�����ȫ��ͼ�ձ���в��� 
             2018-4-12                rengz              1�����ӹ�Ʊ��Ѻ��ծ
                                                         2��δ���˽��������Ʊ��Ѻ��ծ
                                                         3�������ʲ�����Ϊ��TOT_AST_N_CONTAIN_NOTS�����ʲ�_�������۹ɣ�+��Ʊ��Ѻ��ծ
                                                         4����ĩ�ʲ�final_ast��Ϊ����ҵ���ܲ�Ҫ������ʲ�=�ɻ���ֵ+�ʽ����+ծȯ��ֵ+�ع���ֵ+��Ʒ����ֵ+�����ʲ�+δ�����ʽ�+��Ʊ��Ѻ��ծ+������ȯ���ʲ�+Լ��������Ѻ��ֵ+���۹���ֵ+������Ȩ��ֵ
  *********************************************************************/
   --declare @v_bin_date         numeric(8); 
    declare @v_bin_mth          varchar(2);
    declare @v_bin_year         varchar(4);   
    declare @v_bin_20avg_start  numeric(8,0);---���20�������տ�ʼ����
    declare @v_bin_20avg_end    numeric(8,0);---���20�������ս�������

	set @V_OUT_FLAG = -1;  --��ʼ��ϴ��ֵ-1
    set @v_bin_date = @v_bin_date;

    --������������
    set @v_bin_mth  =substr(convert(varchar,@v_bin_date),5,2);
    set @v_bin_year =substr(convert(varchar,@v_bin_date),1,4);
    set @v_bin_20avg_start =(select b.rq
                             from    dba.t_ddw_d_rq      a
                             left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=21      --(T-21��)���� t-2��ǰ20��
                             where a.rq=@v_bin_date);
    set @v_bin_20avg_end =(select b.rq
                            from    dba.t_ddw_d_rq      a
                            left join dba.t_ddw_d_rq    b  on a.sfjrbz='1' and b.sfjrbz='1' and a.ljgzr-b.ljgzr+1=2       --(T-2��)����t-2��
                            where a.rq=@v_bin_date);	
    commit;

   
    --ɾ������������
    delete from dm.t_ast_odi where load_dt =@v_bin_date;
    commit;

    ---��������ͻ���Ϣ
    insert into dm.t_ast_odi(
                            OCCUR_DT,               --��ϴ���� 
                            CUST_ID,                --�ͻ�����
                            main_cptl_acct,         --���ʽ��˺�
                            TOT_AST_N_CONTAIN_NOTS, --���ʲ�_�������۹�
                            RCT_20D_DA_AST,	        --��20���վ��ʲ�
                            SCDY_MVAL,	            --������ֵ
                            NO_ARVD_CPTL,	        --δ�����ʽ�
                            CPTL_BAL,	            --�ʽ����
                            CPTL_BAL_RMB,	        --�ʽ���������
                            CPTL_BAL_HKD,	        --�ʽ����۱�
                            CPTL_BAL_USD,	        --�ʽ������Ԫ 
                            HGT_MVAL,	            --����ͨ��ֵ
                            SGT_MVAL,	            --���ͨ��ֵ
                            PSTK_OPTN_MVAL,	        --������Ȩ��ֵ
                            IMGT_PD_MVAL,	        --�ʹܲ�Ʒ��ֵ
                            BANK_CHRM_MVAL,	        --���������ֵ
                            SECU_CHRM_MVAL,         --֤ȯ�����ֵ 
                            --FUND_SPACCT_MVAL,     --����ר����ֵ
                            STKT_FUND_MVAL,         --��Ʊ�ͻ�����ֵ
                            --STKPLG_LIAB,            --��Ʊ��Ѻ��ծ
                            LOAD_DT)
    select rq
       ,khbh_hs as client_id
       ,zjzh fund_account
       ,zzc         --- �������ʽ���δ�����ʽ𡢶�����ֵ��������ֵ���ʹܲ�Ʒ��ֵ��������ȯ���ʲ���Լ�����ؾ��ʲ��� ������Ƴ��н�֤ȯ��Ʋ�Ʒ�� 
       ,zzc_20rj    --- 20�վ����ʲ���������
       ,ejsz
       ,wdzzj
       ,zjye
       ,zjye_rmb
       ,zjye_gb
       ,zjye_my
       ,hgtsz_rmb   ---����ͨ��ֵ
       ,sgtsz_rmb   ---���ͨ��ֵ
       ,qqsz        ---��Ȩ��ֵ
       ,zgcpsz      ---�ʹܲ�Ʒ��ֵ
       ,yhlccyje    ---������Ƴ��н��
       ,zqlccpe     ---֤ȯ��Ʋ�Ʒ�� 
       --,jjzhsz    ---����ר����ֵ
       ,gjsz        ---��Ʊ�ͻ�����ֵ
       ,rq as load_dt
    from dba.tmp_ddw_khqjt_d_d
    where rq=@v_bin_date
     and jgbh_hs not in  ('5','55','51','44','9999');  ---modify by rengz 20180212 �޳��ܲ��ͻ�
  commit;

------------------------
  -- ������ֵ
------------------------

        select a.zjzh,
               case when a.yrdh_flag = '0' then 1
                    when a.yrdh_flag = '1' and a.tn_sz > 0 then a.bzjzh_tn_sz / a.tn_sz else 1 / b.cnt
               end                      as tn_sz_fencheng,
               tw_sz * tn_sz_fencheng   as tw_zc_20avg,----�����ʲ�
               d.avg_zzc_20d            as tn_zc_20avg ----�����ʲ�
          into #t_twzc
          from dba.t_index_assetinfo_v2 a
        -- һ�˶໧����
          left join (select id_no, count(distinct zjzh) as cnt
                       from dba.t_index_assetinfo_v2
                      where init_date = @v_bin_date
                        and yrdh_flag = '1'
                      group by id_no) b --init_date         --update
            on a.id_no = b.id_no
        -- ����20�վ����ʲ����� �����ʲ�δ������
          left join (select zjzh, sum(zzc) / 20         as avg_zzc_20d
                       from dba.tmp_ddw_khqjt_d_d
                      where rq >= @v_bin_20avg_start
                        and rq <= @v_bin_20avg_end
                      group by zjzh) d
            on a.zjzh = d.zjzh
         where a.init_date = @v_bin_date;
      
      commit;

    update dm.t_ast_odi 
       set OUTMARK_MVAL = coalesce(tw_zc_20avg, 0) 
    from dm.t_ast_odi  a 
    left join #t_twzc  b on a.main_cptl_acct = b.zjzh  
     where 
           a.occur_dt  = @v_bin_date;
    commit;

------------------------
  -- �ɻ���ֵ ������ֵ A����ĩ��ֵ B����ĩ��ֵ ˽ļ������ֵ
------------------------
  select 
       zjzh
       ,sum(case when zqfz1dm='11' and b.sclx in ('01','02') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agsz     ---A����ĩ��ֵ
	   ,sum(case when zqfz1dm='12' and b.sclx in ('03','04') then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bgsz     ---B����ĩ��ֵ 
       ,sum(case when a.zqlx in ('10', 'A1', -- A��      ���� ���ͨ������ͨ������
                                 '17', '18', -- B��
                                 '11',       -- ���ʽ����
                                 '1A',       -- ETF
                                 '74', '75', -- Ȩ֤
                                 '19'        -- LOF --�����ڿ���
                                ) then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                   as gjsz            ---�ɻ���ֵ

       ,sum(case when zqfz1dm='11'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as agqmsz          ---A����ĩ��ֵ_˽�� ���� ���ͨ������ͨ 
       ,sum(case when zqfz1dm in('20','22')then JRCCSZ*c.turn_rmb/turn_rate else 0  end )        as sbsz            ---������ֵ
       ,sum(case when zqfz1dm='14'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as fbsjjqmsz       ---���ʽ������ĩ��ֵ_˽��  
       ,sum(case when zqfz1dm='18'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as etfqmsz         ---ETF��ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='19'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as lofqmsz         ---LOF��ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='25'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as cnkjqmsz        ---���ڿ�����ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='30'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as bzqqmsz         ---��׼ȯ��ĩ��ֵ_˽�� 
       ,sum(case when zqfz1dm='21'  then JRCCSZ*c.turn_rmb/turn_rate else 0 end)                 as hgqmsz          ---�ع���ĩ��ֵ_˽�� 
  into #t_sz
  from dba.T_DDW_F00_KHMRCPYKHZ_D                     a
  left join dba.T_DDW_D_ZQFZ                          b on a.zqlx=b.zqlx AND a.sclx=b.sclx
  left join  dba.T_EDW_T06_YEAR_EXCHANGE_RATE         c on a.tjrq between c.star_dt and c.end_dt 
                                                       and c.curr_type_cd = case
                                                                            when a.zqlx = '18' and a.sclx = '05' then  'USD'
                                                                            when a.zqlx = '17'                   then 'USD'
                                                                            when a.zqlx = '18'                   then  'HKD'
                                                                            else  'CNY'
                                                                            end
  left join dba.t_ddw_d_jj                            d on a.zqdm=d.jjdm and d.nian=@v_bin_year and d.yue=@v_bin_mth
  where a.load_dt= @v_bin_date
    and a.sclx in( '01','02','03','04','05','0G','0S')
  group by zjzh; 

  commit;


  update dm.t_ast_odi 
       set  
           STKF_MVAL     = coalesce(gjsz, 0), --�ɻ���ֵ 
           SB_MVAL       = coalesce(sbsz, 0), --������ֵ 
           A_SHR_MVAL    = coalesce(agsz, 0), --A����ֵ
           B_SHR_MVAL    = coalesce(bgsz, 0)  --B����ֵ
    from dm.t_ast_odi a
    left join   #t_sz b on a.main_cptl_acct = b.zjzh
     where  a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- ��ļ����˽ļ������ֵ
------------------------
    select a.zjzh
          ,SUM(case when b.lx = '��ļ-������' then a.qmsz_cw_d else 0 end)                                                                          as hjsz         -- ������ֵ
          ,SUM(case when b.lx in( '��ļ-��Ʊ��','δ����') or b.lx is null then a.qmsz_cw_d else 0 end)                                              as gjsz         -- �ɻ���ֵ(����δ����)
          ,SUM(case when b.lx = '��ļ-ծȯ��' then a.qmsz_cw_d else 0 end)                                                                          as zjsz         -- ծ����ֵ
          ,SUM(case when b.lx in ('����ר��-��Ʊ��','����ר��-ծȯ��')  then a.qmsz_cw_d else 0 end)                                                as jjzhsz       -- ����ר����ֵ
          ,SUM(case when b.lx in( '��ļ-��Ʊ��','��ļ-ծȯ��','��ļ-������','����ר��','δ����') or b.lx is null then a.qmsz_cw_d else 0 end)       as kjsz         -- ������ֵ(�����ʹܲ�Ʒ��ֵ)
          ,SUM(case when b.lx in( '�������-��Ʊ��','�������-ծȯ��','�������-������') then a.qmsz_cw_d else 0 end)                               as zgcpsz       -- �ʹܲ�Ʒ��ֵ
          ,SUM(case when b.lx in( '�������-ծȯ��','�������-������') then a.qmsz_cw_d else 0 end)                                                 as gdsylzgcpsz  -- �̶��������ʹܲ�Ʒ��ֵ
          ,SUM(case when b.lx in( '��ļ-��Ʊ��','��ļ-ծȯ��','��ļ-������') then a.qmsz_cw_d else 0 end)                                           as gmsz         -- ��ļ������ֵ
          ,SUM(case when b.lx in( '˽ļ-��Ʊ��','˽ļ-ծȯ��') then a.qmsz_cw_d else 0 end)                                                         as smsz         -- ˽ļ������ֵ 
          ,SUM(case when b.lx ='δ����' or b.lx is null  then a.qmsz_cw_d else 0 end)                                                               as qtcpsz       -- ������Ʒ��ֵ 
          ,SUM(case when b.lx in( '��ļ-������') then a.qmsz_cn_d else 0 end)                                                                       as cnhbxjjsz    -- ���ڻ����ͻ�����ֵ_��ĩ   
          ,SUM(a.qmsz_cw_d)                                                                                                                         as cwjjsz       -- �����������ֵ
    into #t_sz_jj   
    --select *
      from dba.t_ddw_xy_jjzb_d as a
      left outer join (select jjdm, jjlb as lx                           -----��ͻ�ȫ��ͼ���в��죬ȫ��ͼֱ��ʹ��lx�ֶΣ�����ʵ�ʰ�����˽ļ����
                         from dba.t_ddw_d_jj
                        where nian || yue =
                              (select MAX(nian || yue)
                                 from dba.t_ddw_d_jj
                                where nian || yue <
                                      convert(varchar(6), FLOOR(@v_bin_date / 100)))) as b
        on a.jjdm = b.jjdm
     where a.rq = @v_bin_date
     group by a.zjzh;

  commit;

 
  update dm.t_ast_odi  
       set 
           PTE_FUND_MVAL = coalesce(smsz, 0),               --˽ļ������ֵ
           PO_FUND_MVAL  = coalesce(gmsz, 0),               --��ļ������ֵ 
           FUND_SPACCT_MVAL = coalesce(jjzhsz, 0),          --����ר����ֵ
           OTH_PROD_MVAL    = coalesce(qtcpsz, 0),          --������Ʒ��ֵ                                 
           PROD_TOT_MVAL    = coalesce(cwjjsz, 0) + BANK_CHRM_MVAL+	        --���������ֵ
                                                  SECU_CHRM_MVAL            --֤ȯ�����ֵ      
                                                            --��Ʒ����ֵ      
    from       dm.t_ast_odi a
    left join  #t_sz_jj     b on a.main_cptl_acct = b.zjzh
     where 
        a.occur_dt = @v_bin_date;

    commit;

------------------------
  -- ���۹���ֵ:����������������۹���ֵ��ʷ������������������ȫ��ͼ��������
------------------------
    commit;   

    update dm.t_ast_odi  
       set NOTS_MVAL = coalesce(xsgsz, 0)                --���۹���ֵ
    from dm.t_ast_odi  a
    left join dba.tmp_ddw_khqjt_d_d  b on convert(varchar,a.main_cptl_acct) = convert(varchar,b.zjzh) and a.occur_dt=b.rq
     where  a.occur_dt = @v_bin_date;

    commit;
    ------------------------
    -- ���ʲ� �����۹�
    ------------------------
    update dm.t_ast_odi a
       set TOT_AST_CONTAIN_NOTS = coalesce(TOT_AST_N_CONTAIN_NOTS, 0) +
                                  coalesce(NOTS_MVAL, 0) ---���ʲ�_�����۹�
     where a.occur_dt = @v_bin_date;
    commit;

    ------------------------
    -- ���� ���������ֵ
    ------------------------
    select zjzh
           ,sum(qmsz_cw_d) as cwsz ---���������ֵ
           ,sum(qmsz_cn_d) as cnsz ---���ڻ�����ֵ
      into #t_jjsz
      from dba.t_ddw_xy_jjzb_d a
     where rq = @v_bin_date
    group by zjzh;

    update dm.t_ast_odi a
       set OFFUND_MVAL = coalesce(cnsz, 0), --���ڻ�����ֵ
           OPFUND_MVAL = coalesce(cwsz, 0)  --���������ֵ
    from dm.t_ast_odi a
    left join #t_jjsz b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;
------------------------
  -- �ͷ����ʲ�
------------------------
-- �ͷ����ʲ��ܼ� = ������ֵ + ծ����ֵ + �ʽ���� + ���ۻع���ֵ + ծȯ��ع���ֵ 
--                    + �̶��������ʹܲ�Ʒ��ֵ + ��ծ��ֵ + ��ҵծ��ֵ + ��תծ��ֵ

    select a.zjzh,
           coalesce(a.hjsz, 0) + coalesce(a.zjsz, 0) + coalesce(a.zjye, 0) +
           coalesce(b.bjhgsz, 0) + coalesce(c.zqnhgsz, 0) +
           coalesce(a.gdsylzgcpsz, 0) + coalesce(d.gzsz, 0) +
           coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0)                       as dfxzczj,
           coalesce(d.gzsz, 0) + coalesce(d.qyzsz, 0) + coalesce(d.kzzsz, 0) as zqsz,
           coalesce(b.bjhgsz,0)                                              as bjhgsz,
           coalesce(c.zqnhgsz,0)                                             as zqnhgsz
      into #t_dfxzc
      from dba.tmp_ddw_khqjt_d_d a
      left join (select zjzh, cyje_br as bjhgsz       -- ���ۻع���ֵ
                   from dba.t_ddw_bjhg_d
                  where rq = @v_bin_date) b
        on a.zjzh = b.zjzh
      left join (select zjzh, SUM(jrccsz) as zqnhgsz -- ծȯ��ع���ֵ
                   from dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx = '27'
                    and zqdm not like '205%'         -- �޳����ۻع�
                  group by zjzh) c
        on a.zjzh = c.zjzh
      left join (select zjzh,
                        SUM(case when zqlx = '12' then jrccsz else 0 end) as gzsz,  -- ��ծ��ֵ  
                        SUM(case when zqlx = '13' then jrccsz else 0 end) as qyzsz, -- ��ҵծ��ֵ
                        SUM(case when zqlx = '14' then jrccsz else 0 end) as kzzsz  -- ��תծ��ֵ
                   from  dba.t_ddw_f00_khmrcpykhz_d
                  where load_dt = @v_bin_date
                    and zqlx in ('12', '13', '14')
                  group by zjzh) d
        on a.zjzh  = d.zjzh
     where a.rq = @v_bin_date;

  commit;

    update dm.t_ast_odi 
       set LOW_RISK_TOT_AST= coalesce(dfxzczj, 0),                      ---  �ͷ����ʲ�
           OVERSEA_TOT_AST = 0,                                         ---  �������ʲ�
           FUTR_TOT_AST    = 0,                                         ---  �ڻ����ʲ�
           BOND_MVAL       =coalesce(b.zqsz,0),                         ---  ծȯ��ֵ
           REPO_MVAL       =coalesce(b.bjhgsz,0)+coalesce(b.zqnhgsz,0), ---  �ع���ֵ
           TREA_REPO_MVAL  =coalesce(b.zqnhgsz,0),                      ---  ��ծ�ع���ֵ
           REPQ_MVAL       =coalesce(b.bjhgsz,0)                        ---  ���ۻع���ֵ
    from dm.t_ast_odi   a  
    left join  #t_dfxzc b on a.main_cptl_acct = b.zjzh
     where 
         a.occur_dt = @v_bin_date;

    commit;

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
    ------------------------
    -- ����ҵ�����󣺹�Ʊ��Ѻ��ծ
    ------------------------

    update dm.t_ast_odi 
       set STKPLG_LIAB= coalesce(fz, 0)                       ---  ��Ʊ��Ѻ��ծ 
    from dm.t_ast_odi            a  
    left join dba.t_ddw_gpzyhg_d b on a.main_cptl_acct = b.zjzh and b.rq=a.occur_dt
     where 
         a.occur_dt = @v_bin_date;

    commit;

 
    ------------------------
    -- ����ҵ����������Լ��������Ѻ�ʲ���ֵ
    ------------------------

    select a.client_id,
           sum(a.entrust_amount * b.trad_price )        as ��Ѻ�ʲ�_��ĩ_ԭʼ ----  Լ��������Ѻ��ֵ
    into #t_arpsz
      from dba.t_edw_arpcontract               a
      left join dba.t_edw_t06_stock_maket_info b
        on a.stock_code = b.stock_cd and '0' || a.exchange_type = b.market_type_cd and a.load_dt = b.trad_dt and b.stock_type_cd in ('10', 'A1')
     where a.load_dt = @v_bin_date
       and a.contract_status in ('2', '3', '7') -- 2-��ǩԼ, 3-�ѽ��г�ʼ����, 7 -�ѹ���
     group by a.client_id;
   
    commit;
 
    update dm.t_ast_odi 
       set APPTBUYB_PLG_MVAL = coalesce(��Ѻ�ʲ�_��ĩ_ԭʼ, 0) --Լ��������Ѻ��ֵ
    from dm.t_ast_odi a
    left join #t_arpsz b on a.cust_id = b.client_id
     where 
         a.occur_dt = @v_bin_date;

    commit;
    
    ------------------------
    -- ����ҵ���������������ʲ���ֵ
    ------------------------

  update dm.t_ast_odi 
       set   OTH_AST_MVAL =  
                        coalesce(b.zzc,0)                                --- �ֿ�ȫ��ͼ���ʲ�
                        + coalesce(b.rzrqzfz,0)                          --- ������ȯ�ܸ�ծ
                        + coalesce(b.ydghfz,0)                           --- Լ�����ظ�ծ
                        - coalesce(STKF_MVAL,0)                          --- �ɻ���ֵ
                        - coalesce(CPTL_BAL ,0)                          --- ��֤��/�ʽ����
                        - coalesce(BOND_MVAL,0)                          --- ծȯ��ֵ
                        - (coalesce(c.bzqqmsz,0)+ coalesce(c.hgqmsz,0))  --- �ع���ֵ--˽�� ��׼ȯ��ֵ
                        - coalesce(PROD_TOT_MVAL,0)                      --- ��Ʒ����ֵ
                        - coalesce(APPTBUYB_PLG_MVAL,0)                  --- Լ��������Ѻ��ֵ
                        - coalesce(b.rzrqzzc,0)                          --- �����˻����ʲ�
                        - coalesce(NO_ARVD_CPTL,0) 	                     --- δ�����ʽ�
    from dm.t_ast_odi   a
    left join dba.tmp_ddw_khqjt_d_d b on a.main_cptl_acct = b.zjzh and b.rq=a.occur_dt
    left join #t_sz                                c on a.main_cptl_acct = c.zjzh
     where 
         a.occur_dt = @v_bin_date;
    commit;
 

 ------------------------
    -- ����ҵ��������ĩ�ʲ�����Ϊ����ҵ���ܲ�Ҫ������ʲ�=�ɻ���ֵ+�ʽ����+ծȯ��ֵ+�ع���ֵ+��Ʒ����ֵ+�����ʲ�+δ�����ʽ�+��Ʊ��Ѻ��ծ+������ȯ���ʲ�+Լ��������Ѻ��ֵ+���۹���ֵ+������Ȩ��ֵ��
 ------------------------

    update dm.t_ast_odi
       set FINAL_AST = coalesce(STKF_MVAL, 0)           --�ɻ���ֵ
                       + coalesce(CPTL_BAL, 0)          --�ʽ����
                       + coalesce(BOND_MVAL, 0)         --ծȯ��ֵ
                       + coalesce(REPO_MVAL, 0)         --�ع���ֵ
                       + coalesce(PROD_TOT_MVAL, 0)     --��Ʒ����ֵ
                       + coalesce(OTH_AST_MVAL, 0)      --�����ʲ� 
                       + coalesce(NO_ARVD_CPTL, 0)      --δ�����ʽ� 
                       + coalesce(STKPLG_LIAB, 0)       --��Ʊ��Ѻ��ծ 
                       + coalesce(b.rzrqzzc, 0)         --������ȯ���ʲ�    
                       + coalesce(APPTBUYB_PLG_MVAL, 0) --Լ��������Ѻ��ֵ
                       + coalesce(NOTS_MVAL, 0)         --���۹���ֵ 
                       + coalesce(PSTK_OPTN_MVAL, 0)    --������Ȩ��ֵ 
    from dm.t_ast_odi a 
    left join dba.tmp_ddw_khqjt_d_d b on a.main_cptl_acct = b.zjzh and a.occur_dt = b.rq
     where a.occur_dt = @v_bin_date;

    commit;


 ------------------------
    -- ����ҵ�����󣺾��ʲ�=��ĩ�ʲ������ʲ���-������ȯ�ܸ�ծ-��Ʊ��Ѻ��ծ-Լ�����ظ�ծ������������ܸ�ծҪ���������͵�������ȯ��ծ
 ------------------------

  update dm.t_ast_odi
     set NET_AST = FINAL_AST                    --��ĩ�ʲ�/����ҵ��ھ����ʲ�
                   - (COALESCE(FIN_CLOSE_BALANCE, 0)       +COALESCE(SLO_CLOSE_BALANCE, 0)       + COALESCE(FARE_CLOSE_DEBIT, 0)         + COALESCE(OTHER_CLOSE_DEBIT, 0) +
                      COALESCE(FIN_CLOSE_INTEREST, 0)      +COALESCE(SLO_CLOSE_INTEREST, 0)      +COALESCE(FARE_CLOSE_INTEREST, 0)       +COALESCE(OTHER_CLOSE_INTEREST, 0) +
                      COALESCE(FIN_CLOSE_FINE_INTEREST, 0) +COALESCE(SLO_CLOSE_FINE_INTEREST, 0) +COALESCE(OTHER_CLOSE_FINE_INTEREST, 0) +COALESCE(REFCOST_CLOSE_FARE, 0)) --������ȯ�ܸ�ծ:���ʸ�ծ����ȯ��ծ�����ø�ծ��������ծ����Ϣ��ծ����Ϣ��ծ
                   - coalesce(STKPLG_LIAB, 0)  --��Ʊ��Ѻ��ծ  
                   - coalesce(b.ydghfz, 0)     --Լ�����ظ�ծ
  from dm.t_ast_odi a 
  left join dba.tmp_ddw_khqjt_d_d                b on a.main_cptl_acct = b.zjzh         and a.occur_dt = b.rq
  left join DBA.T_EDW_UF2_RZRQ_ASSETDEBIT        c on a.cust_id = c.client_id           and a.occur_dt = c.load_dt
   where a.occur_dt = @v_bin_date;
  
  commit;


  set @V_OUT_FLAG = 0;  --����,��ϴ�ɹ����0 

  end
GO
GRANT EXECUTE ON dm.tmp_ast_odi TO query_dev
GO
