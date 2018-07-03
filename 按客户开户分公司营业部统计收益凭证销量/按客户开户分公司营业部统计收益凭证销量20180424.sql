CREATE OR REPLACE PROCEDURE dm.P_EVT_EMP_PROD_SUBSCR_D(IN @V_BIN_DATE INT)

BEGIN 
/********************************************************************
������: ����ƾ֤���۽��ͻ�ͳ��
��д��: WJQ
��������: 2018424
��飺 ÿ��ͳ�Ƶ��¼�����������ĩ��������ƾ֤���۽����¹���ͻ��������¹������
       �����ͻ��������ڷֹ�˾��Ӫҵ������
����������ꡢ��
*********************************************************************
�޶���¼���޶�����,�޶���,�޸����ݼ�Ҫ˵��

*********************************************************************/  

/*
--ǰ����������ֶ������£�
CREATE TABLE #T_REPORT_CPXS_SYPZ_FGS_M 
(
 NIAN VARCHAR(4),         --��
 YUE VARCHAR(2),          --��
 FZJD VARCHAR(30),        --�ֹ�˾��չ�׶�
 FGS VARCHAR(50),         --�ֹ�˾
 YYB VARCHAR(60),         --Ӫҵ��
 XSJE_M NUMERIC(38,8),    --��������ƾ֤���۽��
 XSKHS_M INTEGER,         --��������ƾ֤���ۿͻ���
 XSBS_M INTEGER,          --��������ƾ֤���۱���
 XSJE_Y NUMERIC(38,8),    --��������ƾ֤���۽��
);
*/

DECLARE @NIAN VARCHAR(4);
DECLARE @YUE VARCHAR(2);
DECLARE @I_JYR_MTH_END INTEGER;       --�������һ��������
DECLARE @I_ZRR_MTH_START INTEGER;     --���µ�һ����Ȼ��
DECLARE @I_ZRR_MTH_END INTEGER;       --�������һ����Ȼ��
DECLARE @I_ZRR_YEAR_START INTEGER;    --�����һ����Ȼ��

SET @NIAN=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);;
SET @YUE =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);;
SET @I_JYR_MTH_END    =(SELECT MAX(RQ) FROM DBA.T_DDW_D_RQ WHERE SFJRBZ = '1' AND NIAN=@NIAN AND YUE =@YUE);
SET @I_ZRR_MTH_START  =(SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE NIAN=@NIAN AND YUE =@YUE);
SET @I_ZRR_MTH_END    =(SELECT MAX(RQ) FROM DBA.T_DDW_D_RQ WHERE NIAN=@NIAN AND YUE =@YUE);
SET @I_ZRR_YEAR_START =(SELECT MIN(RQ) FROM DBA.T_DDW_D_RQ WHERE NIAN=@NIAN);
  

INSERT INTO DM.T_REPORT_CPXS_SYPZ_FGS_M 
SELECT @NIAN  AS NIAN,        --��
       @YUE   AS YUE,          --��
       CASE WHEN D.TOP_SEPT_CORP_NAME IN ('���ݷֹ�˾','���ŷֹ�˾','Ȫ�ݷֹ�˾','��ƽ�ֹ�˾','���ҷֹ�˾','���ݷֹ�˾','�����ֹ�˾') THEN '������'
            WHEN D.TOP_SEPT_CORP_NAME IN ('�����ֹ�˾','�Ϻ��ֹ�˾','�㶫�ֹ�˾','���ڷֹ�˾','���շֹ�˾','�㽭�ֹ�˾','ɽ���ֹ�˾','�����ֹ�˾',
                           '���շֹ�˾','�Ĵ��ֹ�˾','�����ֹ�˾','���Ϸֹ�˾','����ֹ�˾','�������ֹ�˾','���ɹŷֹ�˾'
                           ) THEN '�ɳ���'
            WHEN D.TOP_SEPT_CORP_NAME IN ('�����ֹ�˾','����ֹ�˾','�½��ֹ�˾','�ӱ��ֹ�˾','���·ֹ�˾','���Ϸֹ�˾','���ݷֹ�˾','���ֹ�˾',
                           '�����ֹ�˾','�����ֹ�˾','ɽ���ֹ�˾','���Ϸֹ�˾'
              ) THEN '������'
        ELSE NULL
       END AS FZJD,                           --�ֹ�˾��չ�׶�
       D.TOP_SEPT_CORP_NAME AS FGS,           --�ֹ�˾
       D.HR_ORG_NAME AS YYB,                  --Ӫҵ��
       SUM(CASE WHEN A.OCCUR_DT>=@I_ZRR_MTH_START  
                  THEN COALESCE(A.ITC_SUBS_AMT,0)+COALESCE(A.OTC_SUBS_AMT,0)+COALESCE(A.OTC_PURS_AMT,0)+COALESCE(A.OTC_CASTSL_AMT,0)+COALESCE(A.OTC_COVT_IN_AMT,0)+COALESCE(A.CONTD_SALE_AMT,0)
            ELSE 0
          END)      AS XSJE_M,                   --��������ƾ֤���۽��
       COUNT(DISTINCT CASE WHEN A.OCCUR_DT>=@I_ZRR_MTH_START THEN A.CUST_ID ELSE NULL END) AS XSKHS_M,           --��������ƾ֤���ۿͻ���
       COUNT(DISTINCT CASE WHEN A.OCCUR_DT>=@I_ZRR_MTH_START THEN A.CUST_ID||A.PROD_CD ELSE NULL END) AS XSBS,   --��������ƾ֤���۱���
     SUM(COALESCE(A.ITC_SUBS_AMT,0)+COALESCE(A.OTC_SUBS_AMT,0)+COALESCE(A.OTC_PURS_AMT,0)+COALESCE(A.OTC_CASTSL_AMT,0)+COALESCE(A.OTC_COVT_IN_AMT,0)+COALESCE(A.CONTD_SALE_AMT,0)) AS XSJE_Y   --��������ƾ֤���۽��
 FROM DM.T_EVT_PROD_TRD_D_D A
 LEFT JOIN DM.T_VAR_PROD_OTC B ON A.PROD_CD = B.PROD_CD AND B.OCCUR_DT = @I_JYR_MTH_END 
 LEFT JOIN DM.T_PUB_CUST C ON A.CUST_ID = C.CUST_ID AND C.YEAR=@NIAN AND C.MTH = @YUE
 LEFT JOIN DM.T_PUB_ORG D ON C.WH_ORG_ID = D.WH_ORG_ID AND D.YEAR=@NIAN AND D.MTH=@YUE
 WHERE A.OCCUR_DT>=@I_ZRR_YEAR_START AND A.OCCUR_DT<=@I_ZRR_MTH_END
      AND COALESCE(A.ITC_SUBS_AMT,0)+COALESCE(A.OTC_SUBS_AMT,0)+COALESCE(A.OTC_PURS_AMT,0)+COALESCE(A.OTC_CASTSL_AMT,0)+COALESCE(A.OTC_COVT_IN_AMT,0)+COALESCE(A.CONTD_SALE_AMT,0)>0
      AND B.PROD_TYPE ='����ƾ֤' 
 GROUP BY FZJD,FGS,YYB;

END;

