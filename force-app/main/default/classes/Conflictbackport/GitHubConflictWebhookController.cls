@RestResource(urlMapping = '/github/webhook/conflict')
global with sharing class GitHubConflictWebhookController {

    @HttpPost
    global static void onPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        if (!GitHubWebhookSecurity.verifySignature(req)) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('invalid signature');
            return;
        }

        String eventType = req.headers.get('X-GitHub-Event');
        if (eventType != 'pull_request') {
            res.statusCode = 202;
            res.responseBody = Blob.valueOf('ignored');
            return;
        }

        String body = req.requestBody == null ? null : req.requestBody.toString();
        if (String.isBlank(body)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('empty body');
            return;
        }

        Map < String, Object > payload = (Map < String, Object > ) JSON.deserializeUntyped(body);
        String action = (String) payload.get('action');

        System.enqueueJob(new GitHubBackportConflictJob(payload, action));

        res.statusCode = 200;
        res.responseBody = Blob.valueOf('ok');
    }
}