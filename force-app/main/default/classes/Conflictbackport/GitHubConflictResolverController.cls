public without sharing class GitHubConflictResolverController {

    public Id sessionId { get; set; }
    public Id conflictId { get; set; }

    public GitHub_Backport_Session__c sessionRow { get; set; }
    public List<GitHub_Backport_Conflict__c> pendingConflicts { get; set; }
    public List<GitHub_Backport_Conflict__c> resolvedConflicts { get; set; }
    public List<GitHub_Backport_Conflict__c> safeFiles { get; set; }

    public GitHub_Backport_Conflict__c currentConflict { get; set; }

    public String baseContent { get; set; }
    public String sourceContent { get; set; }
    public String targetContent { get; set; }
    public String resolvedContent { get; set; }

    public String pageMessage { get; set; }
    public String languageName { get; set; }

    public GitHubConflictResolverController() {
        String sessionParam = ApexPages.currentPage().getParameters().get('sessionId');
        String idParam = ApexPages.currentPage().getParameters().get('id');

        if (!String.isBlank(sessionParam)) {
            sessionId = (Id) sessionParam;
            loadHome();
        }

        if (!String.isBlank(idParam)) {
            conflictId = (Id) idParam;
            loadEditor();
        }
    }

    public void loadHome() {
        sessionRow = [
                SELECT Id, Source_PR_Number__c, Repo_Full_Name__c, Source_Branch__c, Source_Sha__c,
                        Source_Base_Branch__c, Target_Branch__c, Merge_Base_Sha__c, Resolved_Branch__c,
                        Final_PR_Number__c, Safe_File_Count__c, Conflict_File_Count__c,
                        Resolved_File_Count__c, Status__c
                FROM GitHub_Backport_Session__c
                WHERE Id = :sessionId
                LIMIT 1
        ];

        pendingConflicts = [
                SELECT Id, File_Path__c, Status__c, Sequence__c, Is_Safe_File__c
                FROM GitHub_Backport_Conflict__c
                WHERE Backport_Session__c = :sessionId
                AND Is_Safe_File__c = false
                AND Status__c = 'Pending'
                ORDER BY Sequence__c
        ];

        resolvedConflicts = [
                SELECT Id, File_Path__c, Status__c, Sequence__c, Is_Safe_File__c
                FROM GitHub_Backport_Conflict__c
                WHERE Backport_Session__c = :sessionId
                AND Is_Safe_File__c = false
                AND Status__c = 'Resolved'
                ORDER BY Sequence__c
        ];

        safeFiles = [
                SELECT Id, File_Path__c, Status__c, Sequence__c, Is_Safe_File__c
                FROM GitHub_Backport_Conflict__c
                WHERE Backport_Session__c = :sessionId
                AND Is_Safe_File__c = true
                ORDER BY Sequence__c
        ];
    }

    public void loadEditor() {
        currentConflict = [
                SELECT Id, Backport_Session__c, File_Path__c, Base_Content__c, Source_Content__c,
                        Target_Content__c, Resolved_Content__c, Status__c
                FROM GitHub_Backport_Conflict__c
                WHERE Id = :conflictId
                LIMIT 1
        ];

        sessionId = currentConflict.Backport_Session__c;

        baseContent = GitHubConflictUtils.safeString(currentConflict.Base_Content__c);
        sourceContent = GitHubConflictUtils.safeString(currentConflict.Source_Content__c);
        targetContent = GitHubConflictUtils.safeString(currentConflict.Target_Content__c);

        if (!String.isBlank(currentConflict.Resolved_Content__c)) {
            resolvedContent = currentConflict.Resolved_Content__c;
        } else {
            resolvedContent = String.isBlank(sourceContent) ? targetContent : sourceContent;
        }

        languageName = GitHubConflictUtils.detectMonacoLanguage(currentConflict.File_Path__c);
    }

    public PageReference saveResolution() {
        try {
            currentConflict.Resolved_Content__c = resolvedContent;
            currentConflict.Status__c = 'Resolved';
            currentConflict.Resolved_By__c = UserInfo.getUserName();
            currentConflict.Resolved_On__c = System.now();
            currentConflict.Resolution_Note__c = 'Resolved via Salesforce Monaco editor';
            update currentConflict;

            refreshSessionResolvedCount();

            pageMessage = 'Resolution saved successfully.';
            loadEditor();
        } catch (Exception e) {
            pageMessage = 'Save failed: ' + e.getMessage();
        }
        return null;
    }

    public PageReference saveAndNext() {
        saveResolution();

        List<GitHub_Backport_Conflict__c> nextRows = [
                SELECT Id
                FROM GitHub_Backport_Conflict__c
                WHERE Backport_Session__c = :sessionId
                AND Is_Safe_File__c = false
                AND Status__c = 'Pending'
                ORDER BY Sequence__c
                LIMIT 1
        ];

        if (!nextRows.isEmpty()) {
            PageReference nextPage = Page.GitHubConflictEditor;
            nextPage.getParameters().put('id', String.valueOf(nextRows[0].Id));
            nextPage.setRedirect(true);
            return nextPage;
        }

        PageReference home = Page.GitHubConflictHome;
        home.getParameters().put('sessionId', String.valueOf(sessionId));
        home.setRedirect(true);
        return home;
    }

    public PageReference buildFinalBranchAction() {
        try {
            GitHubConflictBuildService.buildFinalBranch(sessionId);
            pageMessage = 'Final branch built successfully.';
            loadHome();
        } catch (Exception e) {
            pageMessage = 'Build failed: ' + e.getMessage();
        }
        return null;
    }

    public PageReference createFinalPrAction() {
        try {
            Integer prNum = GitHubConflictBuildService.createFinalPr(sessionId);
            pageMessage = 'Final PR created successfully. PR #' + prNum;
            loadHome();
        } catch (Exception e) {
            pageMessage = 'Create PR failed: ' + e.getMessage();
        }
        return null;
    }

    public PageReference mergeFinalPrAction() {
        try {
            GitHubConflictBuildService.mergeFinalPr(sessionId);
            pageMessage = 'Final PR merged successfully.';
            loadHome();
        } catch (Exception e) {
            pageMessage = 'Merge failed: ' + e.getMessage();
        }
        return null;
    }

    public Boolean getCanBuildFinalBranch() {
        return sessionRow != null &&
                pendingConflicts != null &&
                pendingConflicts.isEmpty() &&
                (sessionRow.Status__c == 'In Progress' || sessionRow.Status__c == 'Ready To Build');
    }

    public Boolean getCanCreateFinalPr() {
        return sessionRow != null &&
                sessionRow.Status__c == 'Built' &&
                sessionRow.Final_PR_Number__c == null;
    }

    public Boolean getCanMergeFinalPr() {
        return sessionRow != null &&
                sessionRow.Status__c == 'Final PR Created' &&
                sessionRow.Final_PR_Number__c != null;
    }

    public String getFinalPrUrl() {
        if (sessionRow == null || sessionRow.Final_PR_Number__c == null || String.isBlank(sessionRow.Repo_Full_Name__c)) return null;
        return 'https://github.com/' + sessionRow.Repo_Full_Name__c + '/pull/' +
                Integer.valueOf(String.valueOf(sessionRow.Final_PR_Number__c));
    }

    private void refreshSessionResolvedCount() {
        Integer resolvedCount = [
                SELECT COUNT()
                FROM GitHub_Backport_Conflict__c
                WHERE Backport_Session__c = :sessionId
                AND Is_Safe_File__c = false
                AND Status__c = 'Resolved'
        ];

        if (sessionRow == null) {
            sessionRow = [
                    SELECT Id, Conflict_File_Count__c
                    FROM GitHub_Backport_Session__c
                    WHERE Id = :sessionId
                    LIMIT 1
            ];
        }

        GitHub_Backport_Session__c s = new GitHub_Backport_Session__c(
                Id = sessionId,
                Resolved_File_Count__c = resolvedCount,
                Status__c = resolvedCount >= sessionRow.Conflict_File_Count__c ? 'Ready To Build' : 'In Progress'
        );
        update s;
    }

    public String getBaseJson() {
        return JSON.serialize(baseContent == null ? '' : baseContent);
    }

    public String getSourceJson() {
        return JSON.serialize(sourceContent == null ? '' : sourceContent);
    }

    public String getTargetJson() {
        return JSON.serialize(targetContent == null ? '' : targetContent);
    }

    public String getResolvedJson() {
        return JSON.serialize(resolvedContent == null ? '' : resolvedContent);
    }

    public String getLanguageJson() {
        return JSON.serialize(languageName == null ? 'plaintext' : languageName);
    }
}