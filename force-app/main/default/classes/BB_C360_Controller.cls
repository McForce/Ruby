public with sharing class BB_C360_Controller {

    @AuraEnabled(cacheable=true)
    public static BB_C360_Helper.AccountResult getAccountData(Id accountId) {
        return BB_C360_Helper.fetchAccountData(accountId);
    }

    // Separate output class for @InvocableMethod — @InvocableVariable and @AuraEnabled
    // cannot share the same inner class, so the agent uses this dedicated wrapper.
    public class AgentOutput {
        @InvocableVariable(
            label='Account Name'
            description='The customer\'s legal company name. Use when the user asks who the customer is or for the account name.')
        public String accountName;

        @InvocableVariable(
            label='Industry'
            description='The industry sector the customer operates in (e.g. Apparel, Retail, Manufacturing). Use for questions about sector, industry, or business type.')
        public String industry;

        @InvocableVariable(
            label='FICA CIF Flag'
            description='Boolean. True means the customer is FICA (Financial Intelligence Centre Act) compliant. Use for questions about FICA, compliance, KYC, or regulatory status.')
        public Boolean ficaCifFlag;

        @InvocableVariable(
            label='Length of Relationship (Years)'
            description='Number of years the customer has been with the bank. Use for questions about tenure, relationship length, or how long the customer has been with us.')
        public Decimal lengthOfRelationship;

        @InvocableVariable(
            label='VAPM'
            description='Value Added Per Month — a relationship value indicator. Use for questions about VAPM, value contribution, or relationship strength.')
        public String vapm;

        @InvocableVariable(
            label='Total Revenue'
            description='The customer\'s annual revenue / turnover in ZAR. Use for questions about revenue, turnover, top line, sales, or income.')
        public Decimal totalRevenue;

        @InvocableVariable(
            label='Total Exposure'
            description='Total direct credit exposure to the customer in ZAR. Use for questions about exposure, lending balance, credit risk, or amounts owed.')
        public Decimal totalExposure;

        @InvocableVariable(
            label='Cost to Serve'
            description='Annual cost to serve this customer in ZAR. Use for questions about cost to serve, servicing cost, or operating cost.')
        public Decimal costToServe;

        @InvocableVariable(
            label='Profit Before Tax'
            description='Profit Before Tax (PBT) from this customer in ZAR, sourced from Data Cloud. Use for questions about PBT or pre-tax profit.')
        public Decimal profitBeforeTax;

        @InvocableVariable(
            label='Profit After Tax'
            description='Profit After Tax (PAT) from this customer in ZAR, sourced from Data Cloud. Use for questions about PAT, net profit, or post-tax profit.')
        public Decimal profitAfterTax;

        @InvocableVariable(
            label='Client Profitability'
            description='Overall client profitability value in ZAR, sourced from Data Cloud. Use for questions about how profitable the client is or for client profitability.')
        public Decimal clientProfitability;
    }

    @InvocableMethod(
        label='Get Customer 360 Account Data'
        description='Returns the Customer 360 profile for an Account: name, industry, FICA status, relationship length, VAPM, revenue, exposure, cost to serve, PBT, PAT, and client profitability. When the user asks for a single metric, return only that metric — do not list all fields.'
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
            out.vapm                 = src.vapm;
            out.totalRevenue         = src.totalRevenue;
            out.totalExposure        = src.totalExposure;
            out.costToServe          = src.costToServe;
            out.profitBeforeTax      = src.profitBeforeTax;
            out.profitAfterTax       = src.profitAfterTax;
            out.clientProfitability  = src.clientProfitability;
            results.add(out);
        }
        return results;
    }
}
