public with sharing class BB_C360_DataCloudService {

    public class Metrics {
        // Leads Universe __dlm
        public Decimal clientTurnover;        // Turnover_CY__c
        public Decimal cashFlowMovement;      // OVERDRAFT_MTD_AVE_VALUE__c
        public Decimal totalRevenue;          // NIR__c
        public Decimal lendingGrowth;         // Asset__c
        public String  vapm;                  // VAPM_YTD_CY__c

        // Profitability csv __dlm
        public Decimal profitBeforeTax;       // PBT__c
        public Decimal profitAfterTax;        // PAT__c
        public Decimal clientProfitability;   // PARCC__c
        public Decimal costToServe;           // COST__c
        public Decimal averageAdvances;       // AVERAGE_ADVANCES__c
        public Decimal averageDeposits;       // AVERAGE_DEPOSITS__c

        // NBP csv __dlm
        public String  marginTrend;           // VAPM_TREND__c
    }

    public static Metrics getMetrics(String customerKey) {
        Metrics result = new Metrics();
        if (String.isBlank(customerKey)) return result;

        loadLeadsUniverse(result, customerKey);
        loadProfitability(result, customerKey);
        loadNbp(result, customerKey);

        return result;
    }

    // ── Per-DMO loaders ────────────────────────────────────────────────────

    private static void loadLeadsUniverse(Metrics result, String customerKey) {
        String sql =
            'SELECT Turnover_CY__c, OVERDRAFT_MTD_AVE_VALUE__c, NIR__c, Asset__c, VAPM_YTD_CY__c '
          + 'FROM Leads_Universe__dlm '
          + 'WHERE CustomerKey__c = \'' + String.escapeSingleQuotes(customerKey) + '\' '
          + 'LIMIT 1';

        List<Object> row = firstRow(sql);
        if (row == null) return;

        result.clientTurnover   = toDecimal(row[0]);
        result.cashFlowMovement = toDecimal(row[1]);
        result.totalRevenue     = toDecimal(row[2]);
        result.lendingGrowth    = toDecimal(row[3]);
        result.vapm             = toStringValue(row[4]);
    }

    private static void loadProfitability(Metrics result, String customerKey) {
        String sql =
            'SELECT PBT__c, PAT__c, PARCC__c, COST__c, AVERAGE_ADVANCES__c, AVERAGE_DEPOSITS__c '
          + 'FROM Profitabilitycsv__dlm '
          + 'WHERE CUSTOMERKEY__c = \'' + String.escapeSingleQuotes(customerKey) + '\' '
          + 'LIMIT 1';

        List<Object> row = firstRow(sql);
        if (row == null) return;

        result.profitBeforeTax     = toDecimal(row[0]);
        result.profitAfterTax      = toDecimal(row[1]);
        result.clientProfitability = toDecimal(row[2]);
        result.costToServe         = toDecimal(row[3]);
        result.averageAdvances     = toDecimal(row[4]);
        result.averageDeposits     = toDecimal(row[5]);
    }

    private static void loadNbp(Metrics result, String customerKey) {
        String sql =
            'SELECT VAPM_TREND__c '
          + 'FROM NBPcsv__dlm '
          + 'WHERE CUSTOMERKEY__c = \'' + String.escapeSingleQuotes(customerKey) + '\' '
          + 'LIMIT 1';

        List<Object> row = firstRow(sql);
        if (row == null) return;

        result.marginTrend = toStringValue(row[0]);
    }

    // ── Shared CdpQuery utility ────────────────────────────────────────────

    private static List<Object> firstRow(String sql) {
        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql = sql;

        ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(input);
        if (output == null || output.data == null || output.data.isEmpty()) return null;

        List<Object> row = output.data[0].rowData;
        return (row == null || row.isEmpty()) ? null : row;
    }

    // Handles native numerics from Profitability DMO and stringified currency
    // values from Leads Universe DMO (e.g. "1,234,567", "R 1,234,567", blank).
    private static Decimal toDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof Decimal) return (Decimal) value;
        if (value instanceof Integer) return Decimal.valueOf((Integer) value);
        if (value instanceof Long)    return Decimal.valueOf((Long) value);
        if (value instanceof Double)  return Decimal.valueOf((Double) value);

        String s = String.valueOf(value).trim();
        if (String.isBlank(s)) return null;
        // Strip leading "R " currency prefix
        s = s.replaceAll('(?i)^R\\s*', '');
        // Strip ALL whitespace (regular space, tab, non-breaking space) and commas
        // — Leads Universe uses spaces as thousand separators (e.g. "86 596 370")
        s = s.replaceAll('[\\s\\u00A0,]', '');
        if (String.isBlank(s)) return null;
        try {
            return Decimal.valueOf(s);
        } catch (Exception e) {
            return null;
        }
    }

    private static String toStringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}
