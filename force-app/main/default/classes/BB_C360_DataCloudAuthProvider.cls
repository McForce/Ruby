global class BB_C360_DataCloudAuthProvider implements Auth.AuthProviderPlugin {

    private static final String CDP_GRANT     = 'urn:salesforce:grant-type:external:cdp';
    private static final String TOKEN_TYPE    = 'urn:ietf:params:oauth:token-type:access_token';

    // Tells Salesforce which Custom Metadata Type holds this provider's config.
    // Fields on BB_C360_Config__mdt are passed into every method via authProviderConfiguration.
    global String getCustomMetadataType() {
        return 'BB_C360_Config__mdt';
    }

    // Called to start the auth flow. For client credentials there is no browser
    // redirect — we bounce straight to the callback URL so handleCallback fires.
    global PageReference initiate(Map<String,String> config, String stateToPropagate) {
        String callbackUrl = config.get('callbackUrl');
        return new PageReference(callbackUrl + '?state=' + stateToPropagate + '&code=cc_flow');
    }

    // Called after initiate. Performs both token steps and returns the DC token.
    global Auth.AuthProviderTokenResponse handleCallback(
            Map<String,String> config, Auth.AuthProviderCallbackState callbackState) {

        String dcToken = fetchDataCloudToken(config);
        return new Auth.AuthProviderTokenResponse(
            'BB_C360_DataCloudAuthProvider',
            dcToken,
            'no_refresh',
            callbackState.queryParameters.get('state')
        );
    }

    // Called automatically by the framework when the token expires.
    global Auth.OAuthRefreshResult refresh(Map<String,String> config, String refreshToken) {
        String dcToken = fetchDataCloudToken(config);
        return new Auth.OAuthRefreshResult(dcToken, 'no_refresh');
    }

    // Required by the interface. Not meaningful for server-to-server callouts.
    global Auth.UserData getUserInfo(
            Map<String,String> config, Auth.AuthProviderTokenResponse response) {

        return new Auth.UserData(
            'BB_C360_DataCloud', null, null, null, null,
            null, null, null, 'BB_C360_DataCloudAuthProvider',
            null, new Map<String,String>()
        );
    }

    // ── Two-step token fetch ──────────────────────────────────────────────────

    private String fetchDataCloudToken(Map<String,String> config) {
        String coreToken = getCoreToken(config);
        return getDataCloudToken(coreToken);
    }

    // Step 1 — Client Credentials Flow
    private String getCoreToken(Map<String,String> config) {
        String consumerKey    = config.get('ConsumerKey__c');
        String consumerSecret = config.get('ConsumerSecret__c');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/oauth2/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(30000);
        req.setBody(
            'grant_type=client_credentials'
            + '&client_id='     + EncodingUtil.urlEncode(consumerKey,    'UTF-8')
            + '&client_secret=' + EncodingUtil.urlEncode(consumerSecret, 'UTF-8')
        );

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new Auth.AuthProviderPluginException(
                'Client Credentials failed [' + res.getStatusCode() + ']: ' + res.getBody());
        }
        return (String)((Map<String,Object>) JSON.deserializeUntyped(res.getBody())).get('access_token');
    }

    // Step 2 — CDP Token Exchange
    private String getDataCloudToken(String coreToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/a360/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(30000);
        req.setBody(
            'grant_type='            + EncodingUtil.urlEncode(CDP_GRANT,  'UTF-8')
            + '&subject_token='      + EncodingUtil.urlEncode(coreToken,  'UTF-8')
            + '&subject_token_type=' + EncodingUtil.urlEncode(TOKEN_TYPE, 'UTF-8')
        );

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new Auth.AuthProviderPluginException(
                'CDP Token Exchange failed [' + res.getStatusCode() + ']: ' + res.getBody());
        }
        return (String)((Map<String,Object>) JSON.deserializeUntyped(res.getBody())).get('access_token');
    }
}
