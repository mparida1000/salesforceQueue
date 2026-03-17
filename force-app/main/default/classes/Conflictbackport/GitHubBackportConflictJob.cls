public without sharing class GitHubBackportConflictJob implements Queueable, Database.AllowsCallouts {

    private Map<String, Object> payload;
    private String action;

    public GitHubBackportConflictJob(Map<String, Object> payload, String action) {
        this.payload = payload;
        this.action = action;
    }

    public void execute(QueueableContext qc) {
        try {
            if (payload == null || action != 'closed') return;

            Map<String, Object> pr = (Map<String, Object>) payload.get('pull_request');
            Map<String, Object> repo = (Map<String, Object>) payload.get('repository');
            if (pr == null || repo == null) return;

            Boolean merged = (Boolean) pr.get('merged');
            if (merged != true) return;

            String repoFullName = (String) repo.get('full_name');
            Integer pr1Number = (Integer) pr.get('number');

            Map<String, Object> head = (Map<String, Object>) pr.get('head');
            Map<String, Object> base = (Map<String, Object>) pr.get('base');

            String sourceBranch = head == null ? null : (String) head.get('ref');
            String rawSourceHeadSha = head == null ? null : (String) head.get('sha');
            String sourceBaseBranch = base == null ? null : (String) base.get('ref');

            if (String.isBlank(repoFullName) || pr1Number == null || String.isBlank(rawSourceHeadSha) || String.isBlank(sourceBaseBranch)) {
                System.debug('GBCJ: missing required payload fields');
                return;
            }

            String targetBranch = ReleasePairService.getPairedBranch(sourceBaseBranch);
            if (String.isBlank(targetBranch)) {
                System.debug('GBCJ: no paired branch configured for ' + sourceBaseBranch);
                return;
            }

            List<String> repoParts = repoFullName.split('/');
            if (repoParts.size() < 2) return;

            String owner = repoParts[0];
            String repoName = repoParts[1];

            String sourceHeadSha = sanitizeHeadShaForSession(
                    owner,
                    repoName,
                    rawSourceHeadSha,
                    sourceBaseBranch
            );

            GitHubConflictDetectionService.DetectionResult detection =
                    GitHubConflictDetectionService.detectForSession(
                            owner,
                            repoName,
                            pr1Number,
                            sourceHeadSha,
                            targetBranch
                    );

            // DML starts only after all callouts are done
            GitHub_Backport_Session__c sessionRow = new GitHub_Backport_Session__c();
            sessionRow.Source_PR_Number__c = pr1Number;
            sessionRow.Repo_Full_Name__c = repoFullName;
            sessionRow.Source_Branch__c = sourceBranch;
            sessionRow.Source_Sha__c = sourceHeadSha;
            sessionRow.Source_Base_Branch__c = sourceBaseBranch;
            sessionRow.Target_Branch__c = targetBranch;
            sessionRow.Merge_Base_Sha__c = detection.mergeBaseSha;
            sessionRow.Safe_File_Count__c = detection.safeCount;
            sessionRow.Conflict_File_Count__c = detection.conflictCount;
            sessionRow.Resolved_File_Count__c = 0;
            sessionRow.Status__c = detection.conflictCount > 0 ? 'In Progress' : 'Ready To Build';
            insert sessionRow;

            List<GitHub_Backport_Conflict__c> childRows = new List<GitHub_Backport_Conflict__c>();

            for (GitHubConflictDetectionService.FileAnalysis fa : detection.files) {
                GitHub_Backport_Conflict__c row = new GitHub_Backport_Conflict__c();
                row.Backport_Session__c = sessionRow.Id;
                row.Source_PR_Number__c = pr1Number;
                row.Repo_Full_Name__c = repoFullName;
                row.Source_Branch__c = sourceBranch;
                row.Target_Branch__c = targetBranch;
                row.File_Path__c = fa.filePath;
                row.Previous_File_Path__c = fa.previousFilePath;
                row.Change_Type__c = fa.changeType;
                row.Base_Content__c = fa.baseContent;
                row.Source_Content__c = fa.sourceContent;
                row.Target_Content__c = fa.targetContent;
                row.Is_Safe_File__c = fa.isSafe;
                row.Sequence__c = fa.sequence;
                row.Status__c = fa.isConflict ? 'Pending' : 'Skipped';
                childRows.add(row);
            }

            if (!childRows.isEmpty()) {
                insert childRows;
            }

            System.enqueueJob(new GitHubConflictCommentJob(
                    owner,
                    repoName,
                    pr1Number,
                    sessionRow.Id,
                    detection.safeCount,
                    detection.conflictCount
            ));

        } catch (Exception e) {
            System.debug('GitHubBackportConflictJob error: ' + e.getMessage() + ' line=' + e.getLineNumber());
        }
    }

    private static String sanitizeHeadShaForSession(
            String owner,
            String repo,
            String headSha,
            String baseRef
    ) {
        if (String.isBlank(headSha) || String.isBlank(baseRef)) return headSha;

        HttpResponse resp = GitHubApi.get('/repos/' + owner + '/' + repo + '/commits/' + headSha);
        if (resp.getStatusCode() < 200 || resp.getStatusCode() >= 300) {
            return headSha;
        }

        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
        Map<String, Object> commitObj = (Map<String, Object>) out.get('commit');
        String msg = commitObj == null ? null : (String) commitObj.get('message');

        List<Object> parents = (List<Object>) out.get('parents');
        if (parents == null || parents.size() < 2) return headSha;

        String prefix = 'Merge branch \'' + baseRef + '\' into ';
        if (String.isBlank(msg) || !msg.startsWith(prefix)) return headSha;

        Map<String, Object> p0 = (Map<String, Object>) parents[0];
        String parent0Sha = p0 == null ? null : (String) p0.get('sha');

        return String.isBlank(parent0Sha) ? headSha : parent0Sha;
    }
}