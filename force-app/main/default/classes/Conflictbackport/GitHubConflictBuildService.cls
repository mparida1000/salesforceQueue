/**
 * Created by manojparida on 17/03/26.
 */

public without sharing class GitHubConflictBuildService {

    public static void buildFinalBranch(Id sessionId) {
        GitHub_Backport_Session__c sessionRow = [
                SELECT Id, Source_PR_Number__c, Repo_Full_Name__c, Source_Branch__c, Source_Sha__c,
                        Source_Base_Branch__c, Target_Branch__c, Merge_Base_Sha__c, Status__c
                FROM GitHub_Backport_Session__c
                WHERE Id = :sessionId
                LIMIT 1
        ];

        List<GitHub_Backport_Conflict__c> rows = [
                SELECT Id, Backport_Session__c, Repo_Full_Name__c, File_Path__c, Previous_File_Path__c,
                        Change_Type__c, Source_Content__c, Resolved_Content__c, Is_Safe_File__c, Status__c, Sequence__c
                FROM GitHub_Backport_Conflict__c
                WHERE Backport_Session__c = :sessionId
                ORDER BY Sequence__c
        ];

        for (GitHub_Backport_Conflict__c r : rows) {
            if (!r.Is_Safe_File__c && r.Status__c != 'Resolved') {
                throw new AuraHandledException('All conflict files must be resolved before building the final branch.');
            }
        }

        List<String> parts = sessionRow.Repo_Full_Name__c.split('/');
        String owner = parts[0];
        String repo = parts[1];

        String resolvedBranch =
                'resolved/pr-' + String.valueOf((Integer)sessionRow.Source_PR_Number__c) +
                        '-to-' + sessionRow.Target_Branch__c.replace('/', '-');

        String targetHeadSha =
                GitHubConflictGitService.getBranchHeadSha(owner, repo, sessionRow.Target_Branch__c);

        // callouts first
        GitHubConflictGitService.createOrResetBranchFromSha(
                owner,
                repo,
                resolvedBranch,
                targetHeadSha
        );

        for (GitHub_Backport_Conflict__c r : rows) {
            String contentToApply = r.Is_Safe_File__c ? r.Source_Content__c : r.Resolved_Content__c;

            if (r.Change_Type__c == 'removed') {
                GitHubConflictGitService.deleteFileFromBranch(
                        owner,
                        repo,
                        resolvedBranch,
                        r.File_Path__c,
                        'Apply removal for ' + r.File_Path__c
                );
            } else {
                if (r.Change_Type__c == 'renamed' && !String.isBlank(r.Previous_File_Path__c)) {
                    GitHubConflictGitService.deleteFileFromBranch(
                            owner,
                            repo,
                            resolvedBranch,
                            r.Previous_File_Path__c,
                            'Remove old renamed path ' + r.Previous_File_Path__c
                    );
                }

                GitHubConflictGitService.putResolvedFile(
                        owner,
                        repo,
                        resolvedBranch,
                        r.File_Path__c,
                        contentToApply,
                        'Apply backport content for ' + r.File_Path__c
                );
            }
        }

        // DML after callouts
        for (GitHub_Backport_Conflict__c r : rows) {
            r.Backport_Branch__c = resolvedBranch;
            r.Status__c = 'Built';
        }
        update rows;

        sessionRow.Resolved_Branch__c = resolvedBranch;
        sessionRow.Status__c = 'Built';
        update sessionRow;
    }

    public static Integer createFinalPr(Id sessionId) {
        GitHub_Backport_Session__c sessionRow = [
                SELECT Id, Source_PR_Number__c, Repo_Full_Name__c, Target_Branch__c, Resolved_Branch__c, Status__c
                FROM GitHub_Backport_Session__c
                WHERE Id = :sessionId
                LIMIT 1
        ];

        if (String.isBlank(sessionRow.Resolved_Branch__c)) {
            throw new AuraHandledException('Build the final branch before creating the PR.');
        }

        List<String> parts = sessionRow.Repo_Full_Name__c.split('/');
        String owner = parts[0];
        String repo = parts[1];

        GitHubConflictGitService.PullRequestResult pr =
                GitHubConflictGitService.createFinalPullRequest(
                        owner,
                        repo,
                        '[Auto][Resolved] Backport PR #' + String.valueOf((Integer)sessionRow.Source_PR_Number__c) +
                                ' to ' + sessionRow.Target_Branch__c,
                        sessionRow.Resolved_Branch__c,
                        sessionRow.Target_Branch__c,
                        'Final resolved PR built from Salesforce conflict session.'
                );

        sessionRow.Final_PR_Number__c = pr.num;
        sessionRow.Status__c = 'Final PR Created';
        update sessionRow;

        return pr.num;
    }

    public static void mergeFinalPr(Id sessionId) {
        GitHub_Backport_Session__c sessionRow = [
                SELECT Id, Repo_Full_Name__c, Final_PR_Number__c, Status__c
                FROM GitHub_Backport_Session__c
                WHERE Id = :sessionId
                LIMIT 1
        ];

        if (sessionRow.Final_PR_Number__c == null) {
            throw new AuraHandledException('Create the final PR before merge.');
        }

        List<String> parts = sessionRow.Repo_Full_Name__c.split('/');
        String owner = parts[0];
        String repo = parts[1];

        GitHubConflictGitService.mergePullRequest(
                owner,
                repo,
                Integer.valueOf(String.valueOf(sessionRow.Final_PR_Number__c))
        );

        sessionRow.Status__c = 'Merged';
        update sessionRow;
    }
}