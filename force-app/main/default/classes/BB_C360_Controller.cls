public with sharing class BB_C360_Controller {

    @AuraEnabled(cacheable=true)
    public static BB_C360_Helper.AccountResult getAccountData(Id accountId) {
        return BB_C360_Helper.fetchAccountData(accountId);
    }

    // Separate output class for @InvocableMethod — @InvocableVariable and @AuraEnabled
    // cannot share the same inner class, so the agent uses this dedicated wrapper.
    public class AgentOutput {
        @InvocableVariable(label='Account Name'
            description='The customer\'s legal company name.')
        public String accountName;

        @InvocableVariable(label='Industry'
            description='The industry sector the customer operates in.')
        public String industry;

        @InvocableVariable(label='FICA CIF Flag'
            description='Boolean. True means the customer is FICA compliant.')
        public Boolean ficaCifFlag;

        @InvocableVariable(label='Length of Relationship (Years)'
            description='Number of years the customer has been with the bank.')
        public Decimal lengthOfRelationship;

        @InvocableVariable(label='Total Exposure'
            description='Total direct credit exposure to the customer in ZAR.')
        public Decimal totalExposure;

        @InvocableVariable(label='Client Turnover'
            description='Annual client turnover in ZAR, sourced from Data Cloud Leads Universe (Turnover_CY).')
        public Decimal clientTurnover;

        @InvocableVariable(label='Cash Flow Movement'
            description='Overdraft month-to-date average in ZAR, sourced from Data Cloud Leads Universe (OVERDRAFT_MTD_AVE_VALUE). Use for cash flow movement questions.')
        public Decimal cashFlowMovement;

        @InvocableVariable(label='Total Revenue'
            description='Net interest revenue in ZAR, sourced from Data Cloud Leads Universe (NIR). Use for revenue, turnover, top line, or income questions.')
        public Decimal totalRevenue;

        @InvocableVariable(label='Lending Growth'
            description='Asset value in ZAR (proxy for lending growth), sourced from Data Cloud Leads Universe (Asset).')
        public Decimal lendingGrowth;

        @InvocableVariable(label='VAPM'
            description='Value Added Per Month year-to-date, sourced from Data Cloud Leads Universe (VAPM_YTD_CY).')
        public String vapm;

        @InvocableVariable(label='Profit Before Tax'
            description='Profit Before Tax (PBT) in ZAR, sourced from Data Cloud Profitability.')
        public Decimal profitBeforeTax;

        @InvocableVariable(label='Profit After Tax'
            description='Profit After Tax (PAT) in ZAR, sourced from Data Cloud Profitability.')
        public Decimal profitAfterTax;

        @InvocableVariable(label='Client Profitability'
            description='Profit After Risk-adjusted Capital Charge (PARCC) in ZAR, sourced from Data Cloud Profitability. Use for client profitability questions.')
        public Decimal clientProfitability;

        @InvocableVariable(label='Cost to Serve'
            description='Annual cost to serve in ZAR, sourced from Data Cloud Profitability (COST).')
        public Decimal costToServe;

        @InvocableVariable(label='Average Advances'
            description='Average advances balance in ZAR, sourced from Data Cloud Profitability.')
        public Decimal averageAdvances;

        @InvocableVariable(label='Average Deposits'
            description='Average deposits balance in ZAR, sourced from Data Cloud Profitability.')
        public Decimal averageDeposits;

        @InvocableVariable(label='Margin Trend'
            description='VAPM trend direction, sourced from Data Cloud NBP (VAPM_TREND).')
        public String marginTrend;
    }

    @InvocableMethod(
        label='Get Customer 360 Account Data'
        description='Returns the full Customer 360 profile (Account fields + Data Cloud: Leads Universe, Profitability, NBP). When the user asks for a single metric, return only that metric — do not list all fields.'
        category='Account'
    )
    public static List<AgentOutput> getAccountDataForAgent(List<Id> accountIds) {
        List<AgentOutput> results = new List<AgentOutput>();
        for (Id accountId : accountIds) {
            BB_C360_Helper.AccountResult src = BB_C360_Helper.fetchAccountData(accountId);
            AgentOutput out          = new AgentOutput();
            out.accountName          = src.accountName;
            out.industry             = src.industry;
            out.ficaCifFlag          = src.ficaCifFlag;
            out.lengthOfRelationship = src.lengthOfRelationship;
            out.totalExposure        = src.totalExposure;
            out.clientTurnover       = src.clientTurnover;
            out.cashFlowMovement     = src.cashFlowMovement;
            out.totalRevenue         = src.totalRevenue;
            out.lendingGrowth        = src.lendingGrowth;
            out.vapm                 = src.vapm;
            out.profitBeforeTax      = src.profitBeforeTax;
            out.profitAfterTax       = src.profitAfterTax;
            out.clientProfitability  = src.clientProfitability;
            out.costToServe          = src.costToServe;
            out.averageAdvances      = src.averageAdvances;
            out.averageDeposits      = src.averageDeposits;
            out.marginTrend          = src.marginTrend;
            results.add(out);
        }
        return results;
    }
}
