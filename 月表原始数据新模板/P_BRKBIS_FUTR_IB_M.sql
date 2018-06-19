CREATE OR REPLACE PROCEDURE dm.P_BRKBIS_FUTR_IB_M(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 经纪业务期货IB月报
  编写者: YHB
  创建日期: 2018-06-01
  经纪业务期货IB月报
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
             20180601                  yhb                新建存储过程     
  *********************************************************************/

  DECLARE @V_YEAR VARCHAR(4);   -- 年份
  DECLARE @V_MONTH VARCHAR(2);  -- 月份
  DECLARE @V_BIN_NATRE_DAY_MTHBEG  INT ;    --自然日_月初
  DECLARE @V_BIN_NATRE_DAY_YEARBGN INT ;    --自然日_年初


  SET @V_YEAR = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
  SET @V_MONTH = SUBSTRING(CONVERT(VARCHAR,@V_BIN_DATE),5,2);
  SET @V_BIN_NATRE_DAY_MTHBEG  =(SELECT MIN(DT)  FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR AND MTH=@V_MONTH);
  SET @V_BIN_NATRE_DAY_YEARBGN =(SELECT MIN(DT)  FROM DM.T_PUB_DATE WHERE YEAR=@V_YEAR);

  --PART0 删除当月数据
  DELETE FROM DM.T_BRKBIS_FUTR_IB_M WHERE YEAR_MTH=@V_YEAR||@V_MONTH;

  INSERT INTO DM.T_BRKBIS_FUTR_IB_M
  (
       YEAR_MTH           --年月
      ,ORG_NO             --机构编号
      ,BRH                --营业部
      ,SEPT_CORP          --分公司
      ,SEPT_CORP_TYPE     --分公司类型
      ,IF_YEAR_NA         --是否年新增
      ,IF_MTH_NA          --是否月新增
      ,CUST_NUM           --客户数
      ,IB_AST_FINAL       --IB资产_期末
      ,IB_AST_MDA         --IB资产_月日均
      ,NET_RETAN_CHAG_MTD --净留存手续费_月累计
  )
  SELECT 
       T1.NIAN||T1.YUE      AS      YEAR_MTH           --年月
      ,T1.JGBH              as      机构编号 
      , CASE WHEN t_jg.WH_ORG_ID IS NULL THEN '总部'           ELSE T_jg.HR_ORG_NAME END as 营业部
      , CASE 
           WHEN t_jg.WH_ORG_ID IS NULL THEN  '总部' 
           WHEN t_jg.TOP_SEPT_CORP_NAME  IS NULL  OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')   THEN  T_JG.HR_ORG_NAME   ELSE t_jg.TOP_SEPT_CORP_NAME END as 分公司
       , CASE WHEN t_jg.WH_ORG_ID IS NULL OR  T_JG.WH_ORG_ID IN ('XYJYZB1400',--证券投资部
                                                              'XYXZBM0251',--网络发展部
                                                              '#010000005',--兴业金麒麟 
                                                              '##JGXSSYB',--机构与销售交易事业总部
                                                              'XYRZRQ4400',--融资融券部
                                                              'XYXZBM0034',--总部
                                                              '#999999999')  THEN '总部' 
          ELSE T_JG.ORG_TYPE END   as 分公司类型
      ,CASE WHEN T1.KHRQ >= @V_BIN_NATRE_DAY_YEARBGN 
              THEN 1
            ELSE 0  END                                         AS    IF_YEAR_NA         --是否年新增   
      ,CASE WHEN T1.KHRQ >= @V_BIN_NATRE_DAY_MTHBEG 
              THEN 1
            ELSE 0  END                                         AS    IF_MTH_NA          --是否月新增 
      ,COUNT(T1.KHH)                                            AS    CUST_NUM           --客户数
      ,SUM(COALESCE(T1.QMQY,0))                                 AS    IB_AST_FINAL       --IB资产_期末                     
      ,SUM(COALESCE(T1.RJQY,0))                                 AS    IB_AST_MDA         --IB资产_月日均                     
      ,SUM(COALESCE(T1.JLCSXF,0))                               AS    NET_RETAN_CHAG_MTD --净留存手续费_月累计                       
  FROM DBA.T_DDW_IBYWMX T1
  LEFT JOIN DM.T_PUB_ORG T_JG         --机构表
        ON T1.NIAN=T_JG.YEAR AND T1.YUE=T_JG.MTH 
          AND T1.JGBH=T_JG.WH_ORG_ID
  WHERE T1.NIAN = @V_YEAR AND T1.YUE = @V_MONTH
  GROUP BY 
     YEAR_MTH
    ,机构编号 
    ,营业部
    ,分公司
    ,分公司类型                                  
    ,IF_YEAR_NA 
    ,IF_MTH_NA
  ;
  COMMIT;
END