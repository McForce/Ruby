public with sharing class BB_C360_DataCloud_IU_v1 {

    public static BB_C360_DataCloud_Req_IB_v1 mapRequestFields(String customerKey) {
        BB_C360_DataCloud_Req_IB_v1 req = new BB_C360_DataCloud_Req_IB_v1();
        req.customerKey = customerKey;
        return req;
    }

    // Data Graph response mapper — paired with BB_C360_DataCloud_IH_v1.queryDataGraph.
    // Shape from GET /api/v1/dataGraph/Customer_360?lookupKeys=[...]:
    // {
    //   "data": [{ "json_blob__c": "{...stringified JSON...}" }]
    // }
    // Inside the parsed payload:
    //   - Primary DMO (Profitabilitycsv) fields are at TOP LEVEL (PBT__c, PAT__c, etc.)
    //   - Child DMOs are NESTED ARRAYS: "Leads_Universe__dlm":[{...}], "NBPcsv__dlm":[{...}]
    //   - Numeric values may arrive as STRINGS with spaces ("1 234 567") or "-" for null
    public static BB_C360_DataCloud_Resp_IB_v1 mapDataGraphResponse(Map<String,Object> body) {
        BB_C360_DataCloud_Resp_IB_v1 res = new BB_C360_DataCloud_Resp_IB_v1();
        if (body == null) return res;

        List<Object> dataList = (List<Object>) body.get('data');
        if (dataList == null || dataList.isEmpty()) return res;

        Map<String,Object> firstRow = (Map<String,Object>) dataList[0];
        String payloadStr = (String) firstRow.get('json_blob__c');
        if (String.isBlank(payloadStr)) return res;

        Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(payloadStr);

        // Primary DMO (Profitabilitycsv) fields at top level
        res.profitBeforeTax     = toDecimal(payload.get('PBT__c'));
        res.profitAfterTax      = toDecimal(payload.get('PAT__c'));
        res.clientProfitability = toDecimal(payload.get('PARCC__c'));
        res.costToServe         = toDecimal(payload.get('COST__c'));
        res.averageAdvances     = toDecimal(payload.get('AVERAGE_ADVANCES__c'));
        res.averageDeposits     = toDecimal(payload.get('AVERAGE_DEPOSITS__c'));

        // Leads_Universe__dlm child (array)
        Map<String,Object> leads = firstChild(payload, 'Leads_Universe__dlm');
        if (leads != null) {
            res.clientTurnover   = toDecimal(leads.get('Turnover_CY__c'));
            res.cashFlowMovement = toDecimal(leads.get('OVERDRAFT_MTD_AVE_VALUE__c'));
            res.totalRevenue     = toDecimal(leads.get('NIR__c'));
            res.lendingGrowth    = toDecimal(leads.get('Asset__c'));
            res.vapm             = toStringValue(leads.get('VAPM_YTD_CY__c'));
        }

        // NBPcsv__dlm child (array)
        Map<String,Object> nbp = firstChild(payload, 'NBPcsv__dlm');
        if (nbp != null) {
            res.marginTrend = toStringValue(nbp.get('VAPM_TREND__c'));
        }

        return res;
    }

    private static Map<String,Object> firstChild(Map<String,Object> payload, String key) {
        Object raw = payload.get(key);
        if (raw == null) return null;
        if (raw instanceof List<Object>) {
            List<Object> arr = (List<Object>) raw;
            return arr.isEmpty() ? null : (Map<String,Object>) arr[0];
        }
        if (raw instanceof Map<String,Object>) {
            return (Map<String,Object>) raw;
        }
        return null;
    }

    private static Decimal toDecimal(Object v) {
        if (v == null)            return null;
        if (v instanceof Decimal) return (Decimal)  v;
        if (v instanceof Integer) return Decimal.valueOf((Integer) v);
        if (v instanceof Long)    return Decimal.valueOf((Long)    v);
        if (v instanceof Double)  return Decimal.valueOf((Double)  v);
        String s = String.valueOf(v).trim();
        if (String.isBlank(s) || s == '-') return null;
        // Strip leading "R " currency prefix and thousand separators (spaces, commas, NBSP)
        s = s.replaceAll('(?i)^R\\s*', '');
        s = s.replaceAll('[\\s\\u00A0,]', '');
        if (String.isBlank(s)) return null;
        try {
            return Decimal.valueOf(s);
        } catch (Exception e) {
            return null;
        }
    }

    private static String toStringValue(Object v) {
        return v == null ? null : String.valueOf(v);
    }
}
