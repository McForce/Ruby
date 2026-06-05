public with sharing class BB_C360_Helper {

    public class AccountResult {
        // From Account
        @AuraEnabled public String  accountName;
        @AuraEnabled public String  industry;
        @AuraEnabled public Boolean ficaCifFlag;
        @AuraEnabled public Decimal lengthOfRelationship;
        @AuraEnabled public Decimal totalExposure;

        // From Data Cloud — Leads Universe
        @AuraEnabled public Decimal clientTurnover;
        @AuraEnabled public Decimal cashFlowMovement;
        @AuraEnabled public Decimal totalRevenue;
        @AuraEnabled public Decimal lendingGrowth;
        @AuraEnabled public String  vapm;

        // From Data Cloud — Profitability
        @AuraEnabled public Decimal profitBeforeTax;
        @AuraEnabled public Decimal profitAfterTax;
        @AuraEnabled public Decimal clientProfitability;
        @AuraEnabled public Decimal costToServe;
        @AuraEnabled public Decimal averageAdvances;
        @AuraEnabled public Decimal averageDeposits;

        // From Data Cloud — NBP
        @AuraEnabled public String  marginTrend;
    }

    public static AccountResult fetchAccountData(Id accountId) {
        Account acc = BB_C360_AccountService.getAccount(accountId);
        BB_C360_DataCloud_Resp_IB_v1 dg =
            BB_C360_DataCloud_IH_v1.getDataGraph(acc.Customer_Key__c);

        AccountResult result = new AccountResult();

        // Account-sourced
        result.accountName          = acc.Name;
        result.industry             = acc.Industry;
        result.ficaCifFlag          = acc.FICA_CIF_Flag__c;
        result.lengthOfRelationship = acc.FinServ_Length_Of_Relationship__c;
        result.totalExposure        = acc.LLC_BI_Total_Direct_Exposure__c;

        // Data Cloud — Leads Universe
        result.clientTurnover   = dg.clientTurnover;
        result.cashFlowMovement = dg.cashFlowMovement;
        result.totalRevenue     = dg.totalRevenue;
        result.lendingGrowth    = dg.lendingGrowth;
        result.vapm             = dg.vapm;

        // Data Cloud — Profitability
        result.profitBeforeTax     = dg.profitBeforeTax;
        result.profitAfterTax      = dg.profitAfterTax;
        result.clientProfitability = dg.clientProfitability;
        result.costToServe         = dg.costToServe;
        result.averageAdvances     = dg.averageAdvances;
        result.averageDeposits     = dg.averageDeposits;

        // Data Cloud — NBP
        result.marginTrend = dg.marginTrend;

        return result;
    }
}
