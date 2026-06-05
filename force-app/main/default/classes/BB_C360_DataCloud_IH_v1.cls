public with sharing class BB_C360_DataCloud_IH_v1 {

    private static final String GRAPH_NAME       = 'Customer_360';
    private static final String CONFIG_NAME       = 'Default';

    private static final String CDP_GRANT_TYPE    = 'urn:salesforce:grant-type:external:cdp';
    private static final String ACCESS_TOKEN_TYPE = 'urn:ietf:params:oauth:token-type:access_token';

    // Cached per transaction
    private static String dataCloudToken;
    private static String dataCloudInstanceUrl;

    public static BB_C360_DataCloud_Resp_IB_v1 getDataGraph(String customerKey) {
        if (String.isBlank(customerKey)) {
            return new BB_C360_DataCloud_Resp_IB_v1();
        }
        return queryDataGraph(customerKey);
    }

    private static BB_C360_DataCloud_Resp_IB_v1 queryDataGraph(String customerKey) {
        ensureDataCloudAuth();

        String lookupKeys = 'CustomerKey__c%3D' + EncodingUtil.urlEncode(customerKey, 'UTF-8');
        String endpoint   = dataCloudInstanceUrl + '/api/v1/dataGraph/' + GRAPH_NAME
            + '?lookupKeys=' + lookupKeys;

        System.debug(LoggingLevel.DEBUG, 'BB_C360_DataCloud_IH_v1 → endpoint: ' + endpoint);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + dataCloudToken);
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

    // ── Auth: Client Credentials Flow → CDP Token Exchange ───────────────────

    @TestVisible
    private static void ensureDataCloudAuth() {
        if (String.isNotBlank(dataCloudToken) && String.isNotBlank(dataCloudInstanceUrl)) {
            return;
        }
        String coreToken = requestCoreToken();
        exchangeForDataCloudToken(coreToken);
    }

    private static String requestCoreToken() {
        BB_C360_Config__mdt cfg = BB_C360_Config__mdt.getInstance(CONFIG_NAME);
        if (cfg == null || String.isBlank(cfg.ConsumerKey__c)) {
            throw new DataCloudException(
                'Missing BB_C360_Config__mdt.' + CONFIG_NAME + ' ConsumerKey__c');
        }

        Map<String,String> form = new Map<String,String>{
            'grant_type' => 'client_credentials',
            'client_id'  => cfg.ConsumerKey__c
        };
        if (String.isNotBlank(cfg.ConsumerSecret__c)) {
            form.put('client_secret', cfg.ConsumerSecret__c);
        }

        Map<String,Object> resp = postForm(orgDomain() + '/services/oauth2/token', form, 'Client Credentials');
        String token = (String) resp.get('access_token');
        if (String.isBlank(token)) {
            throw new DataCloudException('Client Credentials Flow returned no access_token');
        }
        return token;
    }

    // Populates both dataCloudToken and dataCloudInstanceUrl from the exchange response.
    private static void exchangeForDataCloudToken(String coreToken) {
        Map<String,String> form = new Map<String,String>{
            'grant_type'         => CDP_GRANT_TYPE,
            'subject_token_type' => ACCESS_TOKEN_TYPE,
            'subject_token'      => coreToken
        };

        Map<String,Object> resp = postForm(orgDomain() + '/services/a360/token', form, 'Token Exchange');

        String token       = (String) resp.get('access_token');
        String instanceUrl = (String) resp.get('instance_url');

        if (String.isBlank(token)) {
            throw new DataCloudException('Token Exchange Flow returned no access_token');
        }
        if (String.isBlank(instanceUrl)) {
            throw new DataCloudException('Token Exchange Flow returned no instance_url');
        }

        dataCloudToken       = token;
        dataCloudInstanceUrl = instanceUrl.startsWith('http') ? instanceUrl : 'https://' + instanceUrl;
    }

    // ── HTTP helpers ──────────────────────────────────────────────────────────

    private static Map<String,Object> postForm(String endpoint, Map<String,String> form, String label) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        req.setBody(encodeForm(form));
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);
        String rawBody = res.getBody();

        if (res.getStatusCode() != 200) {
            System.debug(LoggingLevel.ERROR,
                'BB_C360_DataCloud_IH_v1 ' + label + ' error [' + res.getStatusCode() + ']: ' + rawBody);
            throw new DataCloudException(
                label + ' [' + res.getStatusCode() + ']: ' + extractMessage(rawBody));
        }
        return (Map<String,Object>) JSON.deserializeUntyped(rawBody);
    }

    private static String encodeForm(Map<String,String> form) {
        List<String> parts = new List<String>();
        for (String key : form.keySet()) {
            parts.add(EncodingUtil.urlEncode(key, 'UTF-8')
                + '=' + EncodingUtil.urlEncode(form.get(key), 'UTF-8'));
        }
        return String.join(parts, '&');
    }

    private static String orgDomain() {
        return URL.getOrgDomainUrl().toExternalForm();
    }

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