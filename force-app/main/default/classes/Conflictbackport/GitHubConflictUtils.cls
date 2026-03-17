public without sharing class GitHubConflictUtils {

    public static String detectMonacoLanguage(String filePath) {
        if (String.isBlank(filePath)) return 'plaintext';

        String lower = filePath.toLowerCase();

        if (lower.endsWith('.cls') || lower.endsWith('.trigger')) return 'java';
        if (lower.endsWith('.js')) return 'javascript';
        if (lower.endsWith('.html')) return 'html';
        if (lower.endsWith('.xml')) return 'xml';
        if (lower.endsWith('.css')) return 'css';
        if (lower.endsWith('.json')) return 'json';
        if (lower.endsWith('.yml') || lower.endsWith('.yaml')) return 'yaml';
        if (lower.endsWith('.md')) return 'markdown';

        return 'plaintext';
    }
}