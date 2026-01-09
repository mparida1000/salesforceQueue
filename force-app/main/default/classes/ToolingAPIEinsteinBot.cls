public with sharing class ToolingAPIEinsteinBot {
    public static void enableEinsteinBot() {
        // Use System.Url.getOrgDomainUrl() to construct the base URL
        String orgBaseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        String toolingEndpoint = orgBaseUrl + '/services/data/v60.0/tooling/sobjects/EinsteinBotSettings';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(toolingEndpoint);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{ "enableEinsteinBots": true }');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 204) {
            System.debug('Einstein Bots enabled successfully!');
        } else {
            System.debug('Error enabling Einstein Bots: ' + res.getBody());
        }
    }//ToolingAPIEinsteinBot.enableEinsteinBot();
}