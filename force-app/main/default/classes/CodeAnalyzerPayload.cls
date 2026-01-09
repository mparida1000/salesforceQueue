/**
 * Created by mp1863 on 06/05/25.
 */
public class CodeAnalyzerPayload {
    public String userSty;
    public String commitSha;
    public List<Violation> commitViolations;
    public List<Violation> lineLevelViolations;

    public class Violation {
        public String rule;
        public String engine;
        public Integer severity;
        public List<String> tags;
        public Integer primaryLocationIndex;
        public List<Location> locations;
        public String message;
        public List<String> resources;
    }

    public class Location {
        public String file;
        public Integer startLine;
        public Integer startColumn;
        public Integer endLine;
        public Integer endColumn;
    }
}