public without sharing class GitHubConflictGitService {

    public class PullRequestResult {
        public Integer num;
        public String url;
    }

    public class FileContentResult {
        public String text;
        public String sha;
        public Boolean exists;
    }

    public static void createOrResetBranchFromSha(
            String owner,
            String repo,
            String branchName,
            String sha
    ) {
        Map<String, Object> body = new Map<String, Object>{
                'ref' => 'refs/heads/' + branchName,
                'sha' => sha
        };

        HttpResponse res = GitHubApi.post(
                '/repos/' + owner + '/' + repo + '/git/refs',
                JSON.serialize(body)
        );

        if (res.getStatusCode() == 201) return;

        if (res.getStatusCode() == 422) {
            Map<String, Object> patchBody = new Map<String, Object>{
                    'sha' => sha,
                    'force' => true
            };

            HttpResponse patchRes = GitHubApi.patch(
                    '/repos/' + owner + '/' + repo + '/git/refs/heads/' + branchName,
                    JSON.serialize(patchBody)
            );

            if (patchRes.getStatusCode() == 200) return;

            throw new CalloutException('Branch reset failed: ' + patchRes.getBody());
        }

        throw new CalloutException('Branch creation failed: ' + res.getBody());
    }

    public static String getBranchHeadSha(
            String owner,
            String repo,
            String branchName
    ) {
        HttpResponse res = GitHubApi.get(
                '/repos/' + owner + '/' + repo + '/git/ref/heads/' + branchName
        );

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('Branch head fetch failed: ' + res.getBody());
        }

        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> obj = (Map<String, Object>) out.get('object');

        return obj == null ? null : (String) obj.get('sha');
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

        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> mergeBase = (Map<String, Object>) out.get('merge_base_commit');

        return mergeBase == null ? null : (String) mergeBase.get('sha');
    }

    public static List<Map<String, Object>> getPullRequestFiles(
            String owner,
            String repo,
            Integer prNumber
    ) {
        HttpResponse res = GitHubApi.get(
                '/repos/' + owner + '/' + repo + '/pulls/' + prNumber + '/files'
        );

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('PR files fetch failed: ' + res.getBody());
        }

        List<Map<String, Object>> results = new List<Map<String, Object>>();
        List<Object> rawRows = (List<Object>) JSON.deserializeUntyped(res.getBody());

        for (Object rowObj : rawRows) {
            results.add((Map<String, Object>) rowObj);
        }

        return results;
    }

    public static FileContentResult getFileContent(
            String owner,
            String repo,
            String path,
            String ref
    ) {
        FileContentResult r = new FileContentResult();
        r.exists = false;
        r.text = null;
        r.sha = null;

        HttpResponse res = GitHubApi.get(
                '/repos/' + owner + '/' + repo +
                        '/contents/' + EncodingUtil.urlEncode(path, 'UTF-8') +
                        '?ref=' + ref
        );

        if (res.getStatusCode() == 404) {
            return r;
        }

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('File fetch failed for ' + path + ': ' + res.getBody());
        }

        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String content = (String) out.get('content');

        r.exists = true;
        r.sha = (String) out.get('sha');

        if (content != null) {
            Blob decoded = EncodingUtil.base64Decode(content.replace('\n', ''));
            r.text = decoded.toString();
        } else {
            r.text = '';
        }

        return r;
    }

    public static void putResolvedFile(
            String owner,
            String repo,
            String branch,
            String path,
            String content,
            String message
    ) {
        Blob b = Blob.valueOf(content == null ? '' : content);

        HttpResponse getRes = GitHubApi.get(
                '/repos/' + owner + '/' + repo +
                        '/contents/' + EncodingUtil.urlEncode(path, 'UTF-8') +
                        '?ref=' + branch
        );

        String existingSha = null;

        if (getRes.getStatusCode() == 200) {
            Map<String, Object> existing =
                    (Map<String, Object>) JSON.deserializeUntyped(getRes.getBody());
            existingSha = (String) existing.get('sha');
        } else if (getRes.getStatusCode() != 404) {
            throw new CalloutException('Unable to read existing file before commit: ' + getRes.getBody());
        }

        Map<String, Object> body = new Map<String, Object>{
                'message' => message,
                'content' => EncodingUtil.base64Encode(b),
                'branch' => branch
        };

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

    public static void deleteFileFromBranch(
            String owner,
            String repo,
            String branch,
            String path,
            String message
    ) {
        FileContentResult current = getFileContent(owner, repo, path, branch);
        if (!current.exists || String.isBlank(current.sha)) return;

        Map<String, Object> body = new Map<String, Object>{
                'message' => message,
                'sha' => current.sha,
                'branch' => branch
        };

        HttpResponse res = GitHubApi.deleteReq(
                '/repos/' + owner + '/' + repo +
                        '/contents/' + EncodingUtil.urlEncode(path, 'UTF-8'),
                JSON.serialize(body)
        );

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('Delete failed: ' + res.getBody());
        }
    }

    public static PullRequestResult createFinalPullRequest(
            String owner,
            String repo,
            String title,
            String head,
            String base,
            String body
    ) {
        Map<String, Object> reqBody = new Map<String, Object>{
                'title' => title,
                'head' => head,
                'base' => base,
                'body' => body
        };

        HttpResponse res = GitHubApi.post(
                '/repos/' + owner + '/' + repo + '/pulls',
                JSON.serialize(reqBody)
        );

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('Final PR creation failed: ' + res.getBody());
        }

        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        PullRequestResult r = new PullRequestResult();
        r.num = (Integer) out.get('number');
        r.url = (String) out.get('html_url');

        return r;
    }

    public static void mergePullRequest(
            String owner,
            String repo,
            Integer prNumber
    ) {
        Map<String, Object> body = new Map<String, Object>{
                'merge_method' => 'merge'
        };

        HttpResponse res = GitHubApi.put(
                '/repos/' + owner + '/' + repo + '/pulls/' + prNumber + '/merge',
                JSON.serialize(body)
        );

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('Merge PR failed: ' + res.getBody());
        }
    }

    public static void commentOnPullRequest(
            String owner,
            String repo,
            Integer prNumber,
            String message
    ) {
        Map<String, Object> body = new Map<String, Object>{
                'body' => message
        };

        HttpResponse res = GitHubApi.post(
                '/repos/' + owner + '/' + repo +
                        '/issues/' + prNumber + '/comments',
                JSON.serialize(body)
        );

        if (res.getStatusCode() >= 300) {
            throw new CalloutException('PR comment failed: ' + res.getBody());
        }
    }
}