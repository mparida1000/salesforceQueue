/**
 * Created by manojparida on 23/04/25.
 */
@RestResource(urlMapping='/jenkins/tests/webook')
global without sharing class JenkinsWebhookHandler {

    @HttpPost
    global static void receiveJenkinsJobStatus() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            String requestBody = req.requestBody.toString();
            System.debug('Request >>'+requestBody);
            Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            String promotionTestId = (String) jsonBody.get('promotionTestId');
            System.debug('promotionTestId::'+promotionTestId);
            saveJsonAsAttachment(promotionTestId, requestBody);
            res.responseBody = Blob.valueOf('Jenkins Test results stored successfully');
            res.statusCode = 200;
        }catch (Exception e) {
            System.debug('Error processing Webhook: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
    
    public static void saveJsonAsAttachment(String parentId, String jsonBody) {
        if (String.isBlank(parentId) || String.isBlank(jsonBody)) {
            System.debug('Missing parentId or jsonBody. Skipping attachment.');
            return;
        }

        try {
            Attachment attachment = new Attachment();
            attachment.ParentId = parentId;
            attachment.Name = 'WebhookPayload_' + parentId + '.json';
            attachment.ContentType = 'application/json';
            attachment.Body = Blob.valueOf(jsonBody);
            insert attachment;

            System.debug('Attachment successfully inserted for: ' + parentId);
        } catch (Exception e) {
            System.debug('Error inserting attachment: ' + e.getMessage());
        }
    }
}