public without sharing class GitHubBackportConflictJob implements Queueable, Database.AllowsCallouts {

    private Map < String, Object > payload;
    private String action;

    public GitHubBackportConflictJob(Map < String, Object > payload, String action) {
        this.payload = payload;
        this.action = action;
    }

    public void execute(QueueableContext qc) {
        try {
            System.debug('CJ action=' + action);
			System.debug('CJ payload keys=' + (payload == null ? null : payload.keySet()));
            
            if (payload == null || action != 'closed') return;

            Map < String, Object > pr = (Map < String, Object > ) payload.get('pull_request');
            Map < String, Object > repo = (Map < String, Object > ) payload.get('repository');
            System.debug('CJ pr exists=' + (pr != null));
			System.debug('CJ repo exists=' + (repo != null));
            if (pr == null || repo == null) return;

            Boolean merged = (Boolean) pr.get('merged');
            System.debug('CJ merged=' + merged);
            if (merged != true) return;

            String repoFullName = (String) repo.get('full_name');
            Integer pr1Number = (Integer) pr.get('number');

            Map < String, Object > head = (Map < String, Object > ) pr.get('head');
            Map < String, Object > base = (Map < String, Object > ) pr.get('base');

            String sourceBranch = head == null ? null : (String) head.get('ref');
            String rawSourceHeadSha = head == null ? null : (String) head.get('sha');
            String sourceBaseBranch = base == null ? null : (String) base.get('ref');
            
            System.debug('CJ repoFullName=' + repoFullName);
            System.debug('CJ pr1Number=' + pr1Number);
            System.debug('CJ sourceBranch=' + sourceBranch);
            System.debug('CJ rawSourceHeadSha=' + rawSourceHeadSha);
            System.debug('CJ sourceBaseBranch=' + sourceBaseBranch);	

            if (String.isBlank(repoFullName) || pr1Number == null || String.isBlank(rawSourceHeadSha) || String.isBlank(sourceBaseBranch)) {
                System.debug('ConflictJob: missing required payload fields.');
                return;
            }

            String targetBranch = ReleasePairService.getPairedBranch(sourceBaseBranch);
            System.debug('CJ targetBranch=' + targetBranch);
            if (String.isBlank(targetBranch)) {
                System.debug('ConflictJob: no paired branch configured for ' + sourceBaseBranch);
                return;
            }

            List < String > repoParts = repoFullName.split('/');
            System.debug('CJ repoParts=' + repoParts);
            if (repoParts.size() < 2) return;

            String owner = repoParts[0];
            String repoName = repoParts[1];

            // IMPORTANT: ignore merge commit like "Merge branch 'preprod1' into XYZ"
            String sourceHeadSha = sanitizeHeadShaForConflictBackport(
                owner,
                repoName,
                rawSourceHeadSha,
                sourceBaseBranch,
                sourceBranch
            );
			System.debug('CJ sanitizedSourceHeadSha=' + sourceHeadSha);
            System.debug('ConflictJob: rawSourceHeadSha=' + rawSourceHeadSha + ' sanitizedSourceHeadSha=' + sourceHeadSha);

            String backportBranch = 'conflict/pr-' + pr1Number + '-to-' + targetBranch.replace('/', '-');

            GitHubConflictGitService.createOrResetBranchFromSha(
                owner,
                repoName,
                backportBranch,
                sourceHeadSha
            );

            GitHubConflictGitService.PullRequestResult pr2 =
                GitHubConflictGitService.createOrFindPullRequest(
                    owner,
                    repoName,
                    '[Auto][ConflictUI] Backport PR #' + pr1Number + ' to ' + targetBranch,
                    backportBranch,
                    targetBranch,
                    buildPrBody(pr1Number, sourceBranch, sourceBaseBranch, targetBranch, sourceHeadSha)
                );

            if (pr2 == null || pr2.num == null) {
                System.debug('ConflictJob: unable to create/find PR2.');
                return;
            }

            // Clean old pending rows for same PR2
            // Detect conflicts first
            GitHubConflictDetectionService.DetectionResult detection =
                GitHubConflictDetectionService.detect(
                    owner,
                    repoName,
                    pr1Number,
                    sourceHeadSha,
                    backportBranch,
                    targetBranch
                );
            
            System.debug('ConflictJob: pr1Files=' + detection.pr1Files);
            System.debug('ConflictJob: featureConflictFiles=' + detection.featureConflictFiles);
            System.debug('ConflictJob: r2OnlyFiles=' + detection.r2OnlyFiles);
            
            // Always post resolver link BEFORE any DML
            String resolverLink = Label.GitHub_Conflict_Site_Base_Url + '?pr2=' + pr2.num;
            String comment =
                '⚠ Backport story-file conflicts detected.\n\n' +
                'Only story-owned conflicting files are shown in Salesforce.\n\n' +
                'Resolve here:\n' + resolverLink + '\n\n' +
                'PR1: #' + pr1Number + '\n' +
                'PR2: #' + pr2.num + '\n' +
                'Branch: ' + backportBranch + '\n' +
                'Detected story conflict count: ' + detection.featureConflictFiles.size();
            
            GitHubConflictGitService.commentOnPullRequest(
                owner,
                repoName,
                pr2.num,
                comment
            );
            
            // NOW do DML after callout
            
            // Clean old pending rows for same PR2
            List < GitHub_Backport_Conflict__c > oldRows = [
                SELECT Id
                FROM GitHub_Backport_Conflict__c
                WHERE Target_PR_Number__c =: pr2.num
                AND Status__c = 'Pending'
            ];
            if (!oldRows.isEmpty()) {
                delete oldRows;
            }
            
            if (detection == null || detection.featureConflictFiles.isEmpty()) {
                return;
            }
            
            List < GitHub_Backport_Conflict__c > inserts = new List < GitHub_Backport_Conflict__c > ();
            
            for (String filePath: detection.featureConflictFiles) {
                GitHub_Backport_Conflict__c row = new GitHub_Backport_Conflict__c();
                row.Source_PR_Number__c = pr1Number;
                row.Target_PR_Number__c = pr2.num;
                row.Repo_Full_Name__c = repoFullName;
                row.Source_Branch__c = sourceBranch;
                row.Target_Branch__c = targetBranch;
                row.Backport_Branch__c = backportBranch;
                row.File_Path__c = filePath;
                row.Status__c = 'Pending';
                inserts.add(row);
            }
            
            if (!inserts.isEmpty()) {
                insert inserts;
            }

        } catch (Exception e) {
            System.debug('GitHubBackportConflictJob error: ' + e.getMessage() + ' line=' + e.getLineNumber());
        }
    }

    private static String buildPrBody(
        Integer pr1Number,
        String sourceBranch,
        String sourceBaseBranch,
        String targetBranch,
        String sourceHeadSha
    ) {
        return 'Auto-created Copado-style backport PR.\n\n' +
        'Mode: Feature-head based backport (merge commit ignored)\n' +
        'Source PR: #' + pr1Number + '\n' +
            'Source Branch: ' + sourceBranch + '\n' +
            'Source Base: ' + sourceBaseBranch + '\n' +
            'Target Base: ' + targetBranch + '\n' +
            'Feature Head SHA: ' + sourceHeadSha + '\n';
    }

    // Ignore merge commit like: Merge branch 'preprod1' into CCSTMA-8455
    private static String sanitizeHeadShaForConflictBackport(
        String owner,
        String repo,
        String headSha,
        String baseRef,
        String headRef
    ) {
        if (String.isBlank(headSha) || String.isBlank(baseRef)) return headSha;

        HttpResponse resp = GitHubApi.get('/repos/' + owner + '/' + repo + '/commits/' + headSha);
        if (resp.getStatusCode() < 200 || resp.getStatusCode() >= 300) {
            System.debug('sanitizeHeadSha: unable to read commit: ' + resp.getBody());
            return headSha;
        }

        Map < String, Object > out = (Map < String, Object > ) JSON.deserializeUntyped(resp.getBody());
        Map < String, Object > commitObj = (Map < String, Object > ) out.get('commit');
        String msg = commitObj == null ? null : (String) commitObj.get('message');

        List < Object > parents = (List < Object > ) out.get('parents');
        if (parents == null || parents.size() < 2) return headSha;

        String prefix = 'Merge branch \'' + baseRef + '\' into ';
        if (String.isBlank(msg) || !msg.startsWith(prefix)) return headSha;

        Map < String, Object > p0 = (Map < String, Object > ) parents[0];
        String parent0Sha = p0 == null ? null : (String) p0.get('sha');

        if (String.isBlank(parent0Sha)) return headSha;

        return parent0Sha;
    }
}