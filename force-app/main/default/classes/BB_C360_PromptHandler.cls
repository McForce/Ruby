public with sharing class BB_C360_PromptHandler {

    public class Input {
        @InvocableVariable(
            required=true
            label='Account ID'
            description='The Account record Id for the customer the banker is asking about. Usually the current record on the page.')
        public Id accountId;

        @InvocableVariable(
            required=true
            label='User Question'
            description='The banker\'s original question, verbatim. For example: "What is the total revenue?", "Is this customer FICA compliant?", "What is the client profitability?"')
        public String userQuestion;
    }

    public class Output {
        @InvocableVariable(label='Answer')
        public String answer;
    }

    @InvocableMethod(
        label='Answer Customer 360 Question'
        description='Loads the Customer 360 profile (Salesforce + Data Cloud) for the account and uses the BB_C360_Insight prompt template to return a single conversational sentence answering the banker\'s question. Always returns a clean string — never a raw data payload.'
        category='Account'
    )
    public static List<Output> answer(List<Input> inputs) {
        List<Output> results = new List<Output>();
        for (Input req : inputs) {
            BB_C360_Helper.AccountResult data = BB_C360_Helper.fetchAccountData(req.accountId);
            String profile = formatProfile(data);

            ConnectApi.EinsteinPromptTemplateGenerationsInput genInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            genInput.inputParams = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue question = new ConnectApi.WrappedValue();
            question.value = req.userQuestion;
            genInput.inputParams.put('Input:userQuestion', question);

            ConnectApi.WrappedValue customer = new ConnectApi.WrappedValue();
            customer.value = profile;
            genInput.inputParams.put('Input:customerProfile', customer);

            genInput.isPreview = false;
            genInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            genInput.additionalConfig.applicationName = 'PromptBuilderPreview';

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'BB_C360_Insight',
                    genInput
                );

            Output out = new Output();
            out.answer = (response != null
                          && response.generations != null
                          && !response.generations.isEmpty())
                ? response.generations[0].text
                : 'I was not able to retrieve that information.';
            results.add(out);
        }
        return results;
    }

    private static String formatProfile(BB_C360_Helper.AccountResult d) {
        List<String> lines = new List<String>{
            'Account Name: '              + valueOf(d.accountName),
            'Industry: '                  + valueOf(d.industry),
            'FICA Compliant: '            + booleanLabel(d.ficaCifFlag),
            'Length of Relationship: '    + valueOf(d.lengthOfRelationship) + ' years',
            'Total Exposure (ZAR): '      + valueOf(d.totalExposure),
            'Client Turnover (ZAR): '     + valueOf(d.clientTurnover),
            'Cash Flow Movement (ZAR): '  + valueOf(d.cashFlowMovement),
            'Total Revenue (ZAR): '       + valueOf(d.totalRevenue),
            'Lending Growth (ZAR): '      + valueOf(d.lendingGrowth),
            'VAPM: '                      + valueOf(d.vapm),
            'Profit Before Tax (ZAR): '   + valueOf(d.profitBeforeTax),
            'Profit After Tax (ZAR): '    + valueOf(d.profitAfterTax),
            'Client Profitability (ZAR): '+ valueOf(d.clientProfitability),
            'Cost to Serve (ZAR): '       + valueOf(d.costToServe),
            'Average Advances (ZAR): '    + valueOf(d.averageAdvances),
            'Average Deposits (ZAR): '    + valueOf(d.averageDeposits),
            'Margin Trend: '              + valueOf(d.marginTrend)
        };
        return String.join(lines, '\n');
    }

    private static String valueOf(Object v) {
        return v == null ? 'unknown' : String.valueOf(v);
    }

    private static String booleanLabel(Boolean b) {
        if (b == null) return 'unknown';
        return b ? 'Yes' : 'No';
    }
}
