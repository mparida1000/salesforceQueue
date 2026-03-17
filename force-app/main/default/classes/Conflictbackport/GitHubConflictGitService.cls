public without sharing class GitHubConflictGitService {

    public class PullRequestResult {
        public Integer num;
    }

    public class FileContentResult {
        public String text;
        public Boolean exists;
    }

    /*
     * Create branch from SHA (or reset if already exists)
     */
    public static void createOrResetBranchFromSha(
        String owner,
        String repo,
        String branchName,
        String sha
    ) {

        Map < String, Object > body = new Map < String, Object > {
            'ref' => 'refs/heads/' + branchName,
            'sha' => sha
        };

        HttpResponse res = GitHubApi.post(
            '/repos/' + owner + '/' + repo + '/git/refs',
            JSON.serialize(body)
        );

        if (res.getStatusCode() == 201) {
            return;
        }

        if (res.getStatusCode() == 422) {
            Map < String, Object > patchBody = new Map < String, Object > {
                'sha' => sha,
                'force' => true
            };

            HttpResponse patchRes = GitHubApi.patch(
                '/repos/' + owner + '/' + repo + '/git/refs/heads/' + branchName,
                JSON.serialize(patchBody)
            );

            if (patchRes.getStatusCode() == 200) {
                return;
            }

            throw new CalloutException('Branch reset failed: ' + patchRes.getBody());
        }

        throw new CalloutException('Branch creation failed: ' + res.getBody());
    }

    /*
     * Create PR (or return existing)
     */
    public static PullRequestResult createOrFindPullRequest(
        String owner,
        String repo,
        String title,
        String head,
        String base,
        String body
    ) {

        Map < String, Object > reqBody = new Map < String, Object > {
            'title' => title,
            'head' => head,
            'base' => base,
            'body' => body
        };

        HttpResponse res = GitHubApi.post(
            '/repos/' + owner + '/' + repo + '/pulls',
            JSON.serialize(reqBody)
        );

        if (res.getStatusCode() == 201) {

            Map < String, Object > out =
                (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());

            PullRequestResult r = new PullRequestResult();
            r.num = (Integer) out.get('number');

            return r;
        }

        if (res.getStatusCode() == 422) { 

            String q =
                'repo:' + owner + '/' + repo +
                ' is:pr is:open head:' + owner + ':' + head +
                ' base:' + base;

            HttpResponse search =
                GitHubApi.get('/search/issues?q=' +
                    EncodingUtil.urlEncode(q, 'UTF-8'));

            Map < String, Object > s =
                (Map < String, Object > ) JSON.deserializeUntyped(search.getBody());

            List < Object > items = (List < Object > ) s.get('items');

            if (!items.isEmpty()) {

                Map < String, Object > first =
                    (Map < String, Object > ) items[0];

                PullRequestResult r = new PullRequestResult();
                r.num = (Integer) first.get('number');

                return r;
            }
        }

        throw new CalloutException('PR creation failed: ' + res.getBody());
    }

    /*
     * Comment on PR
     */
    public static void commentOnPullRequest(
        String owner,
        String repo,
        Integer prNumber,
        String message
    ) {

        Map < String, Object > body = new Map < String, Object > {
            'body' => message
        };

        HttpResponse res = GitHubApi.post(
            '/repos/' + owner + '/' + repo +
            '/issues/' + prNumber + '/comments',
            JSON.serialize(body)
        );

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('Comment failed: ' + res.getBody());
        }
    }

    /*
     * Get PR files
     */
    public static List < Map < String, Object >> getPullRequestFiles(
        String owner,
        String repo,
        Integer prNumber
    ) {
        HttpResponse res = GitHubApi.get(
            '/repos/' + owner + '/' + repo +
            '/pulls/' + prNumber + '/files'
        );
    
        if (res.getStatusCode() >= 300) {
            throw new CalloutException('PR files fetch failed: ' + res.getBody());
        }
    
        List < Map < String, Object >> results = new List < Map < String, Object >> ();
        List < Object > rawRows = (List < Object > ) JSON.deserializeUntyped(res.getBody());
    
        for (Object rowObj: rawRows) {
            results.add((Map < String, Object > ) rowObj);
        }
    
        return results;
    }

    /*
     * Get file content
     */
    public static FileContentResult getFileContent(
        String owner,
        String repo,
        String path,
        String ref
    ) {

        HttpResponse res = GitHubApi.get(
            '/repos/' + owner + '/' + repo +
            '/contents/' + EncodingUtil.urlEncode(path, 'UTF-8') +
            '?ref=' + ref
        );

        FileContentResult r = new FileContentResult();

        if (res.getStatusCode() >= 300) {
            r.exists = false;
            return r;
        }

        Map < String, Object > out =
            (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());

        String content = (String) out.get('content');

        if (content == null) {
            r.exists = false;
            return r;
        }

        r.exists = true;

        Blob decoded =
            EncodingUtil.base64Decode(content.replace('\n', ''));

        r.text = decoded.toString();

        return r;
    }

    /*
     * Commit resolved file
     */
    public static void putResolvedFile(
        String owner,
        String repo,
        String branch,
        String path,
        String content,
        String message
    ) {
        Blob b = Blob.valueOf(content == null ? '' : content);
    
        // First read current file so we can supply SHA if file already exists
        HttpResponse getRes = GitHubApi.get(
            '/repos/' + owner + '/' + repo +
            '/contents/' + EncodingUtil.urlEncode(path, 'UTF-8') +
            '?ref=' + branch
        );
    
        String existingSha = null;
    
        if (getRes.getStatusCode() == 200) {
            Map < String, Object > existing =
                (Map < String, Object > ) JSON.deserializeUntyped(getRes.getBody());
            existingSha = (String) existing.get('sha');
        } else if (getRes.getStatusCode() != 404) {
            throw new CalloutException('Unable to read existing file before commit: ' + getRes.getBody());
        }
    
        Map < String, Object > body = new Map < String, Object > {
            'message' => message,
            'content' => EncodingUtil.base64Encode(b),
            'branch' => branch
        };
    
        // Required when updating an existing file
        if (!String.isBlank(existingSha)) {
            body.put('sha', existingSha);
        }
    
        HttpResponse res = GitHubApi.put(
            '/repos/' + owner + '/' + repo +
            '/contents/' + EncodingUtil.urlEncode(path, 'UTF-8'),
            JSON.serialize(body)
        );
    
        if (res.getStatusCode() >= 300) {
            throw new CalloutException('Commit failed: ' + res.getBody());
        }
    }
    
    public static String getMergeBaseSha(
        String owner,
        String repo,
        String baseRef,
        String headRef
        ) {
            HttpResponse res = GitHubApi.get(
            '/repos/' + owner + '/' + repo + '/compare/' + baseRef + '...' + headRef
            );
            
            if (res.getStatusCode() >= 300) {
            throw new CalloutException('Merge base compare failed: ' + res.getBody());
            }
            
            Map<String, Object> out =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            Map<String, Object> mergeBase =
            (Map<String, Object>) out.get('merge_base_commit');
            
            return mergeBase == null ? null : (String) mergeBase.get('sha');
        }
}