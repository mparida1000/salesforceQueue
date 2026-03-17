public without sharing class GitHubConflictResolverController {

    public Integer pr2Number {
        get;
        set;
    }
    public List < GitHub_Backport_Conflict__c > pendingConflicts {
        get;
        set;
    }

    public Id conflictId {
        get;
        set;
    }
    public GitHub_Backport_Conflict__c currentConflict {
        get;
        set;
    }

    public String sourceContent {
        get;
        set;
    }
    public String targetContent {
        get;
        set;
    }
    public String resolvedContent {
        get;
        set;
    }

    public String pageMessage {
        get;
        set;
    }
    public String languageName {
        get;
        set;
    }

    public GitHubConflictResolverController() {
        String pr2Param = ApexPages.currentPage().getParameters().get('pr2');
        String idParam = ApexPages.currentPage().getParameters().get('id');

        if (!String.isBlank(pr2Param)) {
            pr2Number = Integer.valueOf(pr2Param);
            loadHome();
        }

        if (!String.isBlank(idParam)) {
            conflictId = (Id) idParam;
            loadEditor();
        }
    }

    public void loadHome() {
        pendingConflicts = [
            SELECT Id, Name, Source_PR_Number__c, Target_PR_Number__c,
            Repo_Full_Name__c, Source_Branch__c, Target_Branch__c,
            Backport_Branch__c, File_Path__c, Status__c
            FROM GitHub_Backport_Conflict__c
            WHERE Target_PR_Number__c =: pr2Number
            AND Status__c = 'Pending'
            ORDER BY File_Path__c
        ];
    }

    public void loadEditor() {
        currentConflict = [
            SELECT Id, Name, Source_PR_Number__c, Target_PR_Number__c,
            Repo_Full_Name__c, Source_Branch__c, Target_Branch__c,
            Backport_Branch__c, File_Path__c, Status__c
            FROM GitHub_Backport_Conflict__c
            WHERE Id =: conflictId
            LIMIT 1
        ];

        List < String > parts = currentConflict.Repo_Full_Name__c.split('/');
        String owner = parts[0];
        String repo = parts[1];

        GitHubConflictGitService.FileContentResult src =
            GitHubConflictGitService.getFileContent(
                owner,
                repo,
                currentConflict.File_Path__c,
                currentConflict.Source_Branch__c
            );
        
        GitHubConflictGitService.FileContentResult tgt =
            GitHubConflictGitService.getFileContent(
                owner,
                repo,
                currentConflict.File_Path__c,
                currentConflict.Target_Branch__c
            );
        
        sourceContent = (src != null && src.exists) ? src.text : '';
        targetContent = (tgt != null && tgt.exists) ? tgt.text : '';

        resolvedContent = String.isBlank(sourceContent) ? targetContent : sourceContent;
        languageName = GitHubConflictUtils.detectMonacoLanguage(currentConflict.File_Path__c);
    }

    public PageReference saveResolution() {
        System.debug('GCRC saveResolution called');
        System.debug('GCRC resolvedContent length=' + (resolvedContent == null ? null : resolvedContent.length()));
        try {
            commitCurrentResolution();
            pageMessage = 'Resolution saved successfully.';
            loadEditor();
        } catch (Exception e) {
            pageMessage = 'Save failed: ' + e.getMessage();
            System.debug('GCRC saveResolution error=' + e.getMessage());
        }
        return null;
    }

    public PageReference saveAndNext() {
        System.debug('GCRC saveAndNext called');
		System.debug('GCRC resolvedContent length=' + (resolvedContent == null ? null : resolvedContent.length()));
        try {
            commitCurrentResolution();

            List < GitHub_Backport_Conflict__c > nextRows = [
                SELECT Id
                FROM GitHub_Backport_Conflict__c
                WHERE Target_PR_Number__c =: currentConflict.Target_PR_Number__c
                AND Status__c = 'Pending'
                ORDER BY File_Path__c
                LIMIT 1
            ];

            if (!nextRows.isEmpty()) {
                PageReference nextPage = Page.GitHubConflictEditor;
                nextPage.getParameters().put('id', String.valueOf(nextRows[0].Id));
                nextPage.setRedirect(true);
                return nextPage;
            }

            PageReference home = Page.GitHubConflictHome;
            home.getParameters().put('pr2', String.valueOf(currentConflict.Target_PR_Number__c));
            home.setRedirect(true);
            return home;

        } catch (Exception e) {
            pageMessage = 'Save failed: ' + e.getMessage();
            return null;
        }
    }

    private void commitCurrentResolution() {
        System.debug('GCRC commitCurrentResolution called');
		System.debug('GCRC conflictId=' + currentConflict.Id);
		System.debug('GCRC file=' + currentConflict.File_Path__c);	
        List < String > parts = currentConflict.Repo_Full_Name__c.split('/');
        String owner = parts[0];
        String repo = parts[1];

        String commitMessage = 'Resolve conflict for ' + currentConflict.File_Path__c;

        GitHubConflictGitService.putResolvedFile(
            owner,
            repo,
            currentConflict.Backport_Branch__c,
            currentConflict.File_Path__c,
            resolvedContent,
            commitMessage
        );

        currentConflict.Status__c = 'Committed';
        currentConflict.Resolution_Note__c = 'Resolved via VF Monaco editor';
        currentConflict.Resolved_By__c = UserInfo.getUserName();
        currentConflict.Resolved_On__c = System.now();
        update currentConflict;
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