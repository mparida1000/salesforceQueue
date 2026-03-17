public without sharing class GitHubConflictDetectionService {

    public class DetectionResult {
        public Set < String > pr1Files = new Set < String > ();
        public Set < String > featureConflictFiles = new Set < String > ();
        public Set < String > r2OnlyFiles = new Set < String > ();
    }

    public static DetectionResult detect(
        String owner,
        String repo,
        Integer pr1Number,
        String sourceHeadSha,
        String backportBranch,
        String targetBranch
    ) {
        DetectionResult result = new DetectionResult();

        // PR1 changed files
        List < Map < String, Object >> pr1Rows =
            GitHubConflictGitService.getPullRequestFiles(owner, repo, pr1Number);

        for (Map < String, Object > row: pr1Rows) {
            String filename = (String) row.get('filename');
            if (!String.isBlank(filename)) {
                result.pr1Files.add(filename);
            }
        }

        // Compute merge base between PR2 source branch and target branch
        String mergeBaseSha = GitHubConflictGitService.getMergeBaseSha(
            owner,
            repo,
            targetBranch,
            backportBranch
        );

        if (String.isBlank(mergeBaseSha)) {
            System.debug('DetectionService: merge base not found.');
            return result;
        }

        for (String filePath: result.pr1Files) {

            GitHubConflictGitService.FileContentResult baseFile =
                GitHubConflictGitService.getFileContent(owner, repo, filePath, mergeBaseSha);

            GitHubConflictGitService.FileContentResult sourceFile =
                GitHubConflictGitService.getFileContent(owner, repo, filePath, sourceHeadSha);

            GitHubConflictGitService.FileContentResult targetFile =
                GitHubConflictGitService.getFileContent(owner, repo, filePath, targetBranch);

            String baseText = (baseFile != null && baseFile.exists) ? baseFile.text : null;
            String sourceText = (sourceFile != null && sourceFile.exists) ? sourceFile.text : null;
            String targetText = (targetFile != null && targetFile.exists) ? targetFile.text : null;

            Boolean sourceChanged = !same(baseText, sourceText);
            Boolean targetChanged = !same(baseText, targetText);
            Boolean sourceVsTargetDifferent = !same(sourceText, targetText);

            // Actual same-file conflict candidate
            if (sourceChanged && targetChanged && sourceVsTargetDifferent) {
                result.featureConflictFiles.add(filePath);
            }
        }

        return result;
    }

    private static Boolean same(String a, String b) {
        return String.valueOf(a) == String.valueOf(b);
    }
}