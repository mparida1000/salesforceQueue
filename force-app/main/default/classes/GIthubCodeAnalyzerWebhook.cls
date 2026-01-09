/**
 * Created by mp1863 on 06/05/25.
 */
@RestResource(urlMapping='/github/codeAnalyzer')
global without sharing class GIthubCodeAnalyzerWebhook {
    @HttpPost
    global static void handleViolationPayload() {
        try {
            String jsonPayload = RestContext.request.requestBody.toString();
            System.debug('Received JSON payload: ' + jsonPayload);

            //CodeAnalyzerPayload payload = (CodeAnalyzerPayload) JSON.deserialize(jsonPayload, CodeAnalyzerPayload.class);

            //System.debug('USer Story: ' + payload.userSty);
            //System.debug('Commit SHA: ' + payload.commitSha);
            //System.debug('Commit Violations count: ' + (payload.commitViolations != null ? payload.commitViolations.size() : 0));
            //System.debug('Line Level Violations count: ' + (payload.lineLevelViolations != null ? payload.lineLevelViolations.size() : 0));

            //CodeViolationService.processPayload(payload);

            RestContext.response.responseBody = Blob.valueOf('{"status":"success"}');
            RestContext.response.statusCode = 200;
        } catch(Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            RestContext.response.responseBody = Blob.valueOf('{"error":"' + e.getMessage() + '"}');
            RestContext.response.statusCode = 500;
        }
    }
}