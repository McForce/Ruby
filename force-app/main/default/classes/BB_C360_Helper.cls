public with sharing class BB_C360_Helper {

    public class AccountResult {
        @AuraEnabled public String  accountName;
        @AuraEnabled public String  industry;
        @AuraEnabled public Boolean ficaCifFlag;
        @AuraEnabled public Decimal lengthOfRelationship;
        @AuraEnabled public String  vapm;
        @AuraEnabled public Decimal totalRevenue;
        @AuraEnabled public Decimal totalExposure;
        @AuraEnabled public Decimal costToServe;
        @AuraEnabled public Decimal profitBeforeTax;
        @AuraEnabled public Decimal profitAfterTax;
        @AuraEnabled public Decimal clientProfitability;
    }

    public static AccountResult fetchAccountData(Id accountId) {
        Account acc = BB_C360_AccountService.getAccount(accountId);
        BB_C360_DataCloudService.ProfitabilityResult profitability =
            BB_C360_DataCloudService.getProfitability(acc.CIF_Number__c);

        AccountResult result = new AccountResult();
        result.accountName          = acc.Name;
        result.industry             = acc.Industry;
        result.ficaCifFlag          = acc.FICA_CIF_Flag__c;
        result.lengthOfRelationship = acc.FinServ_Length_Of_Relationship__c;
        result.vapm                 = acc.VAPM__c;
        result.totalRevenue         = acc.AnnualRevenue;
        result.totalExposure        = acc.LLC_BI_Total_Direct_Exposure__c;
        result.costToServe          = acc.Cost_to_Serve__c;
        result.clientProfitability  = profitability.clientProfitability;
        result.profitAfterTax       = profitability.profitAfterTax;
        result.profitBeforeTax      = profitability.profitBeforeTax;
        return result;
    }
}
