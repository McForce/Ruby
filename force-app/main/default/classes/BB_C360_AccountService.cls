public with sharing class BB_C360_AccountService {

    public static Account getAccount(Id accountId) {
        return [
            SELECT
                Name,
                Industry,
                FICA_CIF_Flag__c,
                FinServ_Length_Of_Relationship__c,
                VAPM__c,
                AnnualRevenue,
                LLC_BI_Total_Direct_Exposure__c,
                Cost_to_Serve__c,
                CIF_Number__c
            FROM Account
            WHERE Id = :accountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }
}
