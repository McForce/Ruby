public with sharing class BB_C360_DataCloudService {

    public class ProfitabilityResult {
        public Decimal clientProfitability;
        public Decimal profitAfterTax;
        public Decimal profitBeforeTax;
    }

    public static ProfitabilityResult getProfitability(String cifNumber) {
        ProfitabilityResult result = new ProfitabilityResult();
        if (String.isBlank(cifNumber)) return result;

        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql =
            'SELECT Client_Profitability__c, Profit_After_Tax__c, Profit_Before_Tax__c '
          + 'FROM C360_Profitability_TestData_v2csv__dlm '
          + 'WHERE CIF_Number__c = \'' + String.escapeSingleQuotes(cifNumber) + '\' '
          + 'LIMIT 1';

        ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(input);
        if (output == null || output.data == null || output.data.isEmpty()) return result;

        List<Object> row = output.data[0].rowData;
        if (row == null || row.isEmpty()) return result;

        result.clientProfitability = toDecimal(row[0]);
        result.profitAfterTax      = toDecimal(row[1]);
        result.profitBeforeTax     = toDecimal(row[2]);
        return result;
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof Decimal) return (Decimal) value;
        if (value instanceof Integer) return Decimal.valueOf((Integer) value);
        if (value instanceof Long)    return Decimal.valueOf((Long) value);
        if (value instanceof Double)  return Decimal.valueOf((Double) value);
        return Decimal.valueOf(String.valueOf(value));
    }
}
