public without sharing class GitHubConflictDetectionService {

    public class FileAnalysis {
        public Integer sequence;
        public String filePath;
        public String previousFilePath;
        public String changeType;
        public String baseContent;
        public String sourceContent;
        public String targetContent;
        public Boolean isConflict;
        public Boolean isSafe;
    }

    public class DetectionResult {
        public String mergeBaseSha;
        public List<FileAnalysis> files = new List<FileAnalysis>();
        public Integer safeCount = 0;
        public Integer conflictCount = 0;
    }

    public static DetectionResult detectForSession(
            String owner,
            String repo,
            Integer pr1Number,
            String sourceHeadSha,
            String targetBranch
    ) {
        DetectionResult result = new DetectionResult();

        result.mergeBaseSha = GitHubConflictGitService.getMergeBaseSha(
                owner,
                repo,
                targetBranch,
                sourceHeadSha
        );

        List<Map<String, Object>> pr1Rows =
                GitHubConflictGitService.getPullRequestFiles(owner, repo, pr1Number);

        Integer seq = 1;

        for (Map<String, Object> row : pr1Rows) {
            String filePath = (String) row.get('filename');
            String previousPath = (String) row.get('previous_filename');
            String status = (String) row.get('status');

            if (String.isBlank(filePath)) continue;

            String baseLookupPath = !String.isBlank(previousPath) ? previousPath : filePath;

            GitHubConflictGitService.FileContentResult baseFile =
                    GitHubConflictGitService.getFileContent(
                            owner,
                            repo,
                            baseLookupPath,
                            result.mergeBaseSha
                    );

            GitHubConflictGitService.FileContentResult sourceFile;
            if (status == 'removed') {
                sourceFile = new GitHubConflictGitService.FileContentResult();
                sourceFile.exists = false;
                sourceFile.text = '';
            } else {
                sourceFile = GitHubConflictGitService.getFileContent(
                        owner,
                        repo,
                        filePath,
                        sourceHeadSha
                );
            }

            GitHubConflictGitService.FileContentResult targetFile =
                    GitHubConflictGitService.getFileContent(
                            owner,
                            repo,
                            filePath,
                            targetBranch
                    );

            String baseText = (baseFile != null && baseFile.exists) ? baseFile.text : null;
            String sourceText = (sourceFile != null && sourceFile.exists) ? sourceFile.text : null;
            String targetText = (targetFile != null && targetFile.exists) ? targetFile.text : null;

            Boolean sourceChanged = !GitHubConflictUtils.same(baseText, sourceText);
            Boolean targetChanged = !GitHubConflictUtils.same(baseText, targetText);
            Boolean sourceTargetDiffer = !GitHubConflictUtils.same(sourceText, targetText);

            FileAnalysis fa = new FileAnalysis();
            fa.sequence = seq++;
            fa.filePath = filePath;
            fa.previousFilePath = previousPath;
            fa.changeType = status;
            fa.baseContent = baseText == null ? '' : baseText;
            fa.sourceContent = sourceText == null ? '' : sourceText;
            fa.targetContent = targetText == null ? '' : targetText;

            if (sourceChanged && !targetChanged) {
                fa.isSafe = true;
                fa.isConflict = false;
                result.safeCount++;
            } else if (sourceChanged && targetChanged && sourceTargetDiffer) {
                fa.isSafe = false;
                fa.isConflict = true;
                result.conflictCount++;
            } else {
                // no-op / still safe for our current use case
                fa.isSafe = true;
                fa.isConflict = false;
                result.safeCount++;
            }

            result.files.add(fa);
        }

        return result;
    }
}