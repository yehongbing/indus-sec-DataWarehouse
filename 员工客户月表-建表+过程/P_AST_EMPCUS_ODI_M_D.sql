CREATE OR REPLACE PROCEDURE dm.P_AST_EMPCUS_ODI_M_D(IN @V_BIN_DATE INT)

BEGIN 
  
  /******************************************************************
  程序功能: 在GP中创建员工客户普通资产月表
  编写者: DCY
  创建日期: 2018-03-01
  简介：员工客户普通资产月表
  *********************************************************************
  修订记录： 修订日期       版本号    修订人             修改内容简要说明
           
  *********************************************************************/
    --DECLARE @V_BIN_DATE INT ;
    DECLARE @V_BIN_YEAR VARCHAR(4) ;    
    DECLARE @V_BIN_MTH  VARCHAR(2) ;   
    
    ----衍生变量
    SET @V_BIN_DATE=@V_BIN_DATE;
    SET @V_BIN_YEAR=SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),1,4);
    SET @V_BIN_MTH =SUBSTR(CONVERT(VARCHAR,@V_BIN_DATE),5,2);

--PART0 删除当月数据
  DELETE FROM DM.T_AST_EMPCUS_ODI_M_D WHERE YEAR=@V_BIN_YEAR AND MTH=@V_BIN_MTH;
  
  
    ---汇总日责权汇总表---剔除部分客户再分配责权2条记录情况
    select @V_BIN_YEAR  as year,
           @V_BIN_MTH   as mth,
           RQ           AS OCCUR_DT,
           jgbh_hs      as HS_ORG_ID,
           khbh_hs      as HS_CUST_ID,
           zjzh         AS CPTL_ACCT,
           ygh          AS FST_EMPID_BROK_ID,
           afatwo_ygh   as AFA_SEC_EMPID,
           jgbh_kh      as WH_ORG_ID_CUST,
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

     --业务数据临时表
     select
                t1.YEAR
                ,t1.MTH
                ,T1.OCCUR_DT
                ,t1.CUST_ID
                --股票质押担保证券市值
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
     t2.YEAR            as 年
    ,t2.MTH             as 月
    ,T2.OCCUR_DT
    ,t2.HS_CUST_ID      as 客户编码
    ,t2.YEAR||t2.MTH    as 年月
    ,t2.YEAR||t2.MTH||t2.HS_CUST_ID as 年月客户编码

    ,t2.AFA_SEC_EMPID as AFA二期员工号
    ,t2.WH_ORG_ID_EMP as 仓库机构编码_员工
    ,t2.YEAR||t2.MTH||t2.AFA_SEC_EMPID as 年月员工号

    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_FINAL,0) as 二级市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_FINAL,0) as 股基市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_FINAL,0) as A股市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_FINAL,0) as 限售股市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_FINAL,0) as 场内基金市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_FINAL,0) as 场外基金市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_FINAL,0) as 三板市值_期末
    ,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0) as 资管产品市值_期末
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0) as 银行理财市值_期末
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0) as 证券理财市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0) as 个股期权市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_FINAL,0) as B股市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_FINAL,0) as 体外市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_FINAL,0) as 资金余额_期末
    --修正未到账
    ,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_FINAL,0)+COALESCE(t1.STKPLG_LIAB_FINAL,0)) as 未到账资金_期末
    ,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0) as 私募基金市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_FINAL,0) as 海外总资产_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_FINAL,0) as 期货总资产_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_FINAL,0) as 资金余额人民币_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_FINAL,0) as 资金余额港币_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_FINAL,0) as 资金余额美元_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_FINAL,0) as 低风险总资产_期末
    ,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0) as 基金专户市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_FINAL,0) as 沪港通市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_FINAL,0) as 深港通市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_FINAL,0) as 净资产_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_FINAL,0) as 总资产_含限售股_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_FINAL,0) as 总资产_不含限售股_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_FINAL,0) as 债券市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_FINAL,0) as 回购市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_FINAL,0) as 国债回购市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_FINAL,0) as 报价回购市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_MDA,0) as 二级市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_MDA,0) as 股基市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_MDA,0) as A股市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_MDA,0) as 限售股市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_MDA,0) as 场内基金市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_MDA,0) as 场外基金市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_MDA,0) as 三板市值_月日均
    ,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0) as 资管产品市值_月日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0) as 银行理财市值_月日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0) as 证券理财市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_MDA,0) as 个股期权市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_MDA,0) as B股市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_MDA,0) as 体外市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_MDA,0) as 资金余额_月日均
    --修正未到账资金
    ,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_MDA,0)+COALESCE(t1.STKPLG_LIAB_MDA,0)) as 未到账资金_月日均
    ,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0) as 私募基金市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_MDA,0) as 海外总资产_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_MDA,0) as 期货总资产_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_MDA,0) as 资金余额人民币_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_MDA,0) as 资金余额港币_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_MDA,0) as 资金余额美元_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_MDA,0) as 低风险总资产_月日均
    ,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0) as 基金专户市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_MDA,0) as 沪港通市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_MDA,0) as 深港通市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_MDA,0) as 净资产_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_MDA,0) as 总资产_含限售股_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_MDA,0) as 总资产_不含限售股_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_MDA,0) as 债券市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_MDA,0) as 回购市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_MDA,0) as 国债回购市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_MDA,0) as 报价回购市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SCDY_MVAL_YDA,0) as 二级市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_YDA,0) as 股基市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.A_SHR_MVAL_YDA,0) as A股市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_YDA,0) as 限售股市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OFFUND_MVAL_YDA,0) as 场内基金市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OPFUND_MVAL_YDA,0) as 场外基金市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SB_MVAL_YDA,0) as 三板市值_年日均
    ,COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0) as 资管产品市值_年日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0) as 银行理财市值_年日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0) as 证券理财市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_YDA,0) as 个股期权市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.B_SHR_MVAL_YDA,0) as B股市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OUTMARK_MVAL_YDA,0) as 体外市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_YDA,0) as 资金余额_年日均
    --修正未到账资金
    ,COALESCE(t2.PERFM_RATI1,0)*(COALESCE(t1.NO_ARVD_CPTL_YDA,0)+COALESCE(t1.STKPLG_LIAB_YDA,0))  as 未到账资金_年日均
    ,COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0) as 私募基金市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OVERSEA_TOT_AST_YDA,0) as 海外总资产_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.FUTR_TOT_AST_YDA,0) as 期货总资产_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_RMB_YDA,0) as 资金余额人民币_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_HKD_YDA,0) as 资金余额港币_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_USD_YDA,0) as 资金余额美元_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.LOW_RISK_TOT_AST_YDA,0) as 低风险总资产_年日均
    ,COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0) as 基金专户市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.HGT_MVAL_YDA,0) as 沪港通市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.SGT_MVAL_YDA,0) as 深港通市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NET_AST_YDA,0) as 净资产_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_CONTAIN_NOTS_YDA,0) as 总资产_含限售股_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TOT_AST_N_CONTAIN_NOTS_YDA,0) as 总资产_不含限售股_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_YDA,0) as 债券市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_YDA,0) as 回购市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.TREA_REPO_MVAL_YDA,0) as 国债回购市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPQ_MVAL_YDA,0) as 报价回购市值_年日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0) as 公募基金市值_期末
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0) as 公募基金市值_月日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0) as 公募基金市值_年日均

    --补充更新
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_FINAL,0) as 股票型基金市值_期末
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0) as 其他产品市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_FINAL,0) as 其他资产市值_期末
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0) as 约定购回质押市值_期末
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_MDA,0) as 股票型基金市值_月日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0) as 其他产品市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_MDA,0) as 其他资产市值_月日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0) as 约定购回质押市值_月日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.STKT_FUND_MVAL_YDA,0) as 股票型基金市值_年日均
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0) as 其他产品市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_YDA,0) as 其他资产市值_年日均
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0) as 约定购回质押市值_年日均

    --补充融资融券数据
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_FINAL,0) as 融资融券净资产_期末
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_FINAL,0) as 融资融券保证金_期末
    ,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_FINAL,0)+COALESCE(t3.CRDT_STK_LIAB_FINAL,0)) as 融资融券余额_期末
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_MDA,0) as 融资融券净资产_月日均
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_MDA,0) as 融资融券保证金_月日均
    ,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_MDA,0)+COALESCE(t3.CRDT_STK_LIAB_MDA,0)) as 融资融券余额_月日均
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.NET_AST_YDA,0) as 融资融券净资产_年日均
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.CRED_MARG_YDA,0) as 融资融券保证金_年日均
    ,COALESCE(t2.PERFM_RATI9,0)*(COALESCE(t3.FIN_LIAB_YDA,0)+COALESCE(t3.CRDT_STK_LIAB_YDA,0)) as 融资融券余额_年日均

    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_FINAL,0) as 融资融券总负债_期末
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_MDA,0) as 融资融券总负债_月日均
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_LIAB_YDA,0) as 融资融券总负债_年日均

    --20180412：增加融资融券总资产
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_FINAL,0) as 融资融券总资产_期末
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_MDA,0) as 融资融券总资产_月日均
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_YDA,0) as 融资融券总资产_年日均
    --20180416：增加约定购回余额，用于计算净资产
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_FINAL,0) as 约定购回余额_期末
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_MDA,0) as 约定购回余额_月日均
    ,COALESCE(t2.PERFM_RATI9,0)*COALESCE(t_ydgh.APPTBUYB_BAL_YDA,0) as 约定购回余额_年日均


    --产品总市值：公募基金市值+基金专户市值+资管产品市值+私募基金市值+银行理财市值+证券理财市值+其他产品市值
    ,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0)           --公募基金市值_期末
    +COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0)   --基金专户市值_期末
    +COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0)       --资管产品市值_期末
    +COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0)      --私募基金市值_期末
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0)     --银行理财市值_期末
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0)     --证券理财市值_期末
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0)      --其他产品市值_期末
    as 产品总市值_期末
,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0)             --公募基金市值_月日均
    +COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0)     --基金专户市值_月日均
    +COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0)         --资管产品市值_月日均
    +COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0)        --私募基金市值_月日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0)       --银行理财市值_月日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0)       --证券理财市值_月日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0)        --其他产品市值_月日均
    as 产品总市值_月日均
,COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0)             --公募基金市值_年日均
    +COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0)     --基金专户市值_年日均
    +COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0)         --资管产品市值_年日均
    +COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0)        --私募基金市值_年日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0)       --银行理财市值_年日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0)       --证券理财市值_年日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0)        --其他产品市值_年日均
    as 产品总市值_年日均    
    
--总资产：股基市值+资金余额+债券市值+回购市值+产品总市值+其他资产+未到账资金+股票质押负债+融资融券总资产+约定购回质押市值+限售股市值
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_FINAL,0)              --股基市值_期末
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_FINAL,0)           --资金余额_期末
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_FINAL,0)          --债券市值_期末
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_FINAL,0)          --回购市值_期末
    
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_FINAL,0)       --公募基金市值_期末
    +COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_FINAL,0)   --基金专户市值_期末
    +COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_FINAL,0)       --资管产品市值_期末
    +COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_FINAL,0)      --私募基金市值_期末
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_FINAL,0)     --银行理财市值_期末
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_FINAL,0)     --证券理财市值_期末
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_FINAL,0)      --其他产品市值_期末
    
    --20180412修正
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_FINAL,0)       --其他资产市值_期末
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_FINAL,0)       --未到账资金_期末
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_FINAL,0)        --股票质押负债_期末（用于冲抵未到账资金，所以使用二级资产的责权比例处理）
    +COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_FINAL,0)            --融资融券总资产_期末
    
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_FINAL,0)  --约定购回质押市值_期末
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_FINAL,0)          --限售股市值_期末
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_FINAL,0)     --个股期权市值_期末
    
    --扣减股票质押担保证券市值
    -COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_FINAL,0) --股票质押担保证券市值_期末
    as 总资产_期末
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_MDA,0)                --股基市值_月日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_MDA,0)             --资金余额_月日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_MDA,0)            --债券市值_月日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_MDA,0)            --回购市值_月日均
    
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_MDA,0)         --公募基金市值_月日均
    +COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_MDA,0)     --基金专户市值_月日均
    +COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_MDA,0)         --资管产品市值_月日均
    +COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_MDA,0)        --私募基金市值_月日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_MDA,0)       --银行理财市值_月日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_MDA,0)       --证券理财市值_月日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_MDA,0)        --其他产品市值_月日均
    
    --20180412修正
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_MDA,0)         --其他资产市值_月日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_MDA,0)         --未到账资金_月日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_MDA,0)          --股票质押负债_月日均（用于冲抵未到账资金，所以使用二级资产的责权比例处理）
    +COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_MDA,0)              --融资融券总资产_月日均
    
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_MDA,0)    --约定购回质押市值_月日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_MDA,0)            --限售股市值_月日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_MDA,0)       --个股期权市值_月日均
    
    --扣减股票质押担保证券市值
    -COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_MDA,0)   --股票质押担保证券市值_月日均
    as 总资产_月日均
,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKF_MVAL_YDA,0)                --股基市值_年日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.CPTL_BAL_YDA,0)             --资金余额_年日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.BOND_MVAL_YDA,0)            --债券市值_年日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.REPO_MVAL_YDA,0)            --回购市值_年日均
    
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.PO_FUND_MVAL_YDA,0)         --公募基金市值_年日均
    +COALESCE(t2.PERFM_RATI5,0)*COALESCE(t1.FUND_SPACCT_MVAL_YDA,0)     --基金专户市值_年日均
    +COALESCE(t2.PERFM_RATI6,0)*COALESCE(t1.IMGT_PD_MVAL_YDA,0)         --资管产品市值_年日均
    +COALESCE(t2.PERFM_RATI7,0)*COALESCE(t1.PTE_FUND_MVAL_YDA,0)        --私募基金市值_年日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.BANK_CHRM_MVAL_YDA,0)       --银行理财市值_年日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.SECU_CHRM_MVAL_YDA,0)       --证券理财市值_年日均
    +COALESCE(t2.PERFM_RATI4,0)*COALESCE(t1.OTH_PROD_MVAL_YDA,0)        --其他产品市值_年日均
    
    --20180412修正
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.OTH_AST_MVAL_YDA,0)         --其他资产市值_年日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NO_ARVD_CPTL_YDA,0)         --未到账资金_年日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.STKPLG_LIAB_YDA,0)          --股票质押负债_年日均（用于冲抵未到账资金，所以使用二级资产的责权比例处理）
    +COALESCE(t2.PERFM_RATI9,0)*COALESCE(t3.TOT_AST_YDA,0)              --融资融券总资产_年日均
    
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.APPTBUYB_PLG_MVAL_YDA,0)    --约定购回质押市值_年日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.NOTS_MVAL_YDA,0)            --限售股市值_年日均
    +COALESCE(t2.PERFM_RATI1,0)*COALESCE(t1.PSTK_OPTN_MVAL_YDA,0)       --个股期权市值_年日均
    
    --扣减股票质押担保证券市值
    -COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_YDA,0)   --股票质押担保证券市值_年日均
    as 总资产_年日均

    --20180423，修正二级市值中扣减的股票质押市值
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_FINAL,0) as 股票质押担保证券市值_期末_二级扣减
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_MDA,0)   as 股票质押担保证券市值_月日均_二级扣减
    ,COALESCE(t2.PERFM_RATI1,0)*COALESCE(t_gpzy.GUAR_SECU_MVAL_YDA,0)   as 股票质押担保证券市值_年日均_二级扣减
    
    --20180416：总资产中股票质押资产已扣减，股票质押责权负债先清0
    ,0 as 股票质押负债_期末
    ,0 as 股票质押负债_月日均
    ,0 as 股票质押负债_年日均
    
    ,0 as 股票质押担保证券市值_期末
    ,0 as 股票质押担保证券市值_月日均
    ,0 as 股票质押担保证券市值_年日均
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