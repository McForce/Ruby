public with sharing class BB_C360_DataCloud_IH_v1 {

    private static final String GRAPH_NAME       = 'Customer_360';

    // Named Credential wired to External Credential BB_C360_DataCloud_JWT, whose
    // Auth Provider (lwt__DataCloudAuthProvider) performs the JWT bearer + CDP
    // token exchange. The framework injects the Authorization header on callout,
    // so no token handling is needed here.
    private static final String NAMED_CREDENTIAL = 'BB_C360_DataCloud_JWT';

    public static BB_C360_DataCloud_Resp_IB_v1 getDataGraph(String customerKey) {
        if (String.isBlank(customerKey)) {
            return new BB_C360_DataCloud_Resp_IB_v1();
        }
        return queryDataGraph(customerKey);
    }

    private static BB_C360_DataCloud_Resp_IB_v1 queryDataGraph(String customerKey) {
        String lookupKeys = 'CustomerKey__c%3D' + EncodingUtil.urlEncode(customerKey, 'UTF-8');
        String endpoint   = 'callout:' + NAMED_CREDENTIAL + '/api/v1/dataGraph/' + GRAPH_NAME
            + '?lookupKeys=' + lookupKeys;

        System.debug(LoggingLevel.DEBUG, 'BB_C360_DataCloud_IH_v1 → endpoint: ' + endpoint);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            String rawBody = res.getBody();
            System.debug(LoggingLevel.ERROR,
                'BB_C360_DataCloud_IH_v1 error [' + res.getStatusCode() + ']: ' + rawBody);
            throw new DataCloudException(
                'Data Graph [' + res.getStatusCode() + ']: ' + extractMessage(rawBody)
            );
        }

        Map<String,Object> body = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> data = (List<Object>) body.get('data');
        if (data == null || data.isEmpty()) {
            return new BB_C360_DataCloud_Resp_IB_v1();
        }

        return BB_C360_DataCloud_IU_v1.mapDataGraphResponse(body);
    }

    // ── HTTP helpers ──────────────────────────────────────────────────────────

    private static String extractMessage(String responseBody) {
        if (String.isBlank(responseBody)) return '(empty response)';
        try {
            Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(responseBody);
            for (String key : new List<String>{ 'message', 'error_description', 'error' }) {
                Object val = parsed.get(key);
                if (val != null) return String.valueOf(val);
            }
        } catch (Exception ignore) {}
        return responseBody;
    }

    public class DataCloudException extends Exception {}
}