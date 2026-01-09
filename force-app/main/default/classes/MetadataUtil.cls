public class MetadataUtil {
// Create and configure the Metadata API service
    public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        
        // Construct the base URL using System.Url.getOrgDomainUrl()
        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        service.endpoint_x = baseUrl + '/services/Soap/m/60.0'; // Replace "60.0" with the desired Metadata API version
        
        // Set the Session Header with the current session ID
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }
}