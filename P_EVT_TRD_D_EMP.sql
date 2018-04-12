CREATE PROCEDURE DM.P_EVT_TRD_D_EMP(IN @V_DATE INT)
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
