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
        if (lower.endsWith('.md')) return 'markdown';
        if (lower.endsWith('.yml') || lower.endsWith('.yaml')) return 'yaml';

        return 'plaintext';
    }

    public static String safeString(String s) {
        return s == null ? '' : s;
    }

    public static Boolean same(String a, String b) {
        return String.valueOf(a) == String.valueOf(b);
    }
}