@RestResource(urlMapping = '/github/branch-guard/*')
global with sharing class GitHubBranchGuard {

    @HttpPost
    global static void validatePR() {
        try {
            RestRequest req = RestContext.request;
            Map < String, Object > payload = (Map < String, Object > ) JSON.deserializeUntyped(req.requestBody.toString());
            Map < String, Object > pr = (Map < String, Object > ) payload.get('pull_request');

            if (pr == null) return;

            String targetBranch = (String)((Map < String, Object > ) pr.get('base')).get('ref');
            String featureBranch = (String)((Map < String, Object > ) pr.get('head')).get('ref');
            Integer prNumber = (Integer) pr.get('number');
            String repo = (String)((Map < String, Object > ) payload.get('repository')).get('full_name');

            // Extreme Strict Check
            Boolean isValid = verifyStrictParentage(repo, targetBranch, featureBranch);

            System.debug('Check Result - Target: ' + targetBranch + ' | Feature: ' + featureBranch + ' | Valid: ' + isValid);

            if (!isValid) {
                closeAndComment(repo, prNumber, targetBranch);
            }
        } catch (Exception e) {
            System.debug('Error in Webhook: ' + e.getMessage());
        }
    }

    private static Boolean verifyStrictParentage(String repo, String target, String feature) {
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://api.github.com/repos/' + repo + '/compare/' + target + '...' + feature);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + Label.YOUR_GITHUB_TOKEN);
    req.setHeader('Accept', 'application/vnd.github+json');
    req.setHeader('User-Agent', 'Salesforce-PR-Guard');

    HttpResponse res = h.send(req);

    if (res.getStatusCode() == 200) {
        Map < String, Object > result = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());

        // 1. Get the current "Tip" of the target branch (base_commit)
        Map < String, Object > baseCommit = (Map < String, Object > ) result.get('base_commit');
        String targetTipSha = (String) baseCommit.get('sha');

        // 2. Get the "Common Ancestor" (merge_base_commit)
        Map < String, Object > mergeBase = (Map < String, Object > ) result.get('merge_base_commit');
        String commonAncestorSha = (String) mergeBase.get('sha');

        // 3. Get commit counts
        Integer aheadBy = (Integer) result.get('ahead_by');
        Integer behindBy = (Integer) result.get('behind_by');

        System.debug('Target Tip: ' + targetTipSha);
        System.debug('Common Ancestor: ' + commonAncestorSha);

        // EXTREME RULE:
        // The point where the feature branch started MUST be the current tip of the target branch.
        // AND it must not be behind the target branch at all.
        Boolean isDirectlyCut = (targetTipSha == commonAncestorSha);
        Boolean isUpToDate = (behindBy == 0);

        return isDirectlyCut && isUpToDate;
    }
    return true;
}

    @future(callout = true)
    private static void closeAndComment(String repo, Integer prNum, String target) {
        String prUrl = 'https://api.github.com/repos/' + repo + '/pulls/' + prNum;
        String commentUrl = 'https://api.github.com/repos/' + repo + '/issues/' + prNum + '/comments';
        String token = Label.YOUR_GITHUB_TOKEN;

        // 1. Close PR
        sendAction(prUrl, 'PATCH', '{"state":"closed"}', token);

        // 2. Add Comment
        String msg = '{"body": "🛑 **STRICT POLICY VIOLATION** 🛑\\n\\nThis PR was closed because the source branch was not cut directly from the tip of `' + target + '`.\\n\\n**Requirement:** You must cut your feature branch from the specific Release branch you intend to merge into."}';
        sendAction(commentUrl, 'POST', msg, token);
    }

    private static void sendAction(String url, String method, String body, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Accept', 'application/vnd.github+json');
        req.setHeader('User-Agent', 'Salesforce-PR-Guard');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);

        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug('Action Result [' + method + ']: ' + res.getStatusCode());
    }
}
