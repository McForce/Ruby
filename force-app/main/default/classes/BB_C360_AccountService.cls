public with sharing class BB_C360_AccountService {

    public static Account getAccount(Id accountId) {
        return [
            SELECT
                Name,
                Industry,
                FICA_CIF_Flag__c,
                FinServ_Length_Of_Relationship__c,
                LLC_BI_Total_Direct_Exposure__c,
                Customer_Key__c
            FROM Account
            WHERE Id = :accountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }
}
