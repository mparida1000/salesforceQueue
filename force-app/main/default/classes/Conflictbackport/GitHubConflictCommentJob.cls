/**
 * Created by manojparida on 17/03/26.
 */

public without sharing class GitHubConflictCommentJob implements Queueable, Database.AllowsCallouts {

    private String owner;
    private String repo;
    private Integer pr1Number;
    private Id sessionId;
    private Integer safeCount;
    private Integer conflictCount;

    public GitHubConflictCommentJob(
            String owner,
            String repo,
            Integer pr1Number,
            Id sessionId,
            Integer safeCount,
            Integer conflictCount
    ) {
        this.owner = owner;
        this.repo = repo;
        this.pr1Number = pr1Number;
        this.sessionId = sessionId;
        this.safeCount = safeCount;
        this.conflictCount = conflictCount;
    }

    public void execute(QueueableContext qc) {
        String resolverLink = Label.GitHub_Conflict_Site_Base_Url + '?sessionId=' + sessionId;

        String comment =
                '📌 Backport review session created.\n\n' +
                        'Open here:\n' + resolverLink + '\n\n' +
                        'Safe files: ' + safeCount + '\n' +
                        'Conflict files: ' + conflictCount + '\n\n' +
                        'Resolve conflicts in Salesforce. Final PR will be created from the site UI.';

        GitHubConflictGitService.commentOnPullRequest(
                owner,
                repo,
                pr1Number,
                comment
        );
    }
}