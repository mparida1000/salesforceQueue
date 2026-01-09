public without sharing class JenkinsTrigger {
    @future(callout=true)
    public static void triggerJenkinsJob(String cityName, String id) {
        Map<String, String> authDetails = fetchJenkinsCrumbAndSession();
        // Encode city name for URL (e.g., replace spaces with %20)
        String encodedCity = EncodingUtil.urlEncode(cityName, 'UTF-8');

        // Jenkins job URL with the CITY parameter
        String jenkinsUrl = 'callout:Jenkins_Auth/job/Weather%20Pipeline/buildWithParameters?CITY_NAME=' + encodedCity+'&promotionTestId='+id;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(jenkinsUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader(authDetails.get('crumbField'), authDetails.get('crumbToken'));  // Include Crumb Token
    	req.setHeader('Cookie', authDetails.get('sessionCookie'));  // Include JSESSIONID Cookie

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('print response:::'+res);

        if (res.getStatusCode() == 201) {
            System.debug('🎉 Jenkins job triggered successfully for city: ' + cityName);
        } else {
            System.debug('Failed to trigger Jenkins for ' + cityName + ': ' + res.getBody());
        }
    }
    
    
    
    // Step 2: Fetch Weather Data from Jenkins
    @InvocableMethod(label='Call Jenkins')
    public static void fetchJenkinsWeatherData(List<String> idList) {
        String id = idList.get(0);
        String jenkinsArtifactUrl = 'callout:Jenkins_Auth/job/Weather%20Pipeline/lastSuccessfulBuild/artifact/weather_data.csv';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(jenkinsArtifactUrl);
        req.setMethod('GET');
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('✅ Fetched Weather Data: ' + res.getBody());
            storeWeatherInSalesforce(id,res.getBody());
        } else {
            System.debug('❌ Failed to fetch weather data: ' + res.getBody());
            //return null;
        }
    }

    // Step 3: Store Weather Data in Salesforce
    public static String storeWeatherInSalesforce(Id id, String csvData) {
        // Parse CSV data
        List<String> rows = csvData.split('\n');
        if (rows.size() < 2) {
            return 'No data found in CSV';
        }

        // Extract weather values (City, Temperature, Pressure, Humidity, Wind Speed)
        List<String> values = rows[1].split(',');

        Weather__c weatherRecord = new Weather__c();
        weatherRecord.Id = id;
        weatherRecord.Temperature__c = Decimal.valueOf(values[1]);
        weatherRecord.Pressure__c = Decimal.valueOf(values[2]);
        weatherRecord.Humidity__c = Decimal.valueOf(values[3]);
        weatherRecord.Wind_Speed__c  = Decimal.valueOf(values[4]);

        update weatherRecord;
        return '✅ Weather Data Stored Successfully!';
    }
    
    
    public static Map<String, String> fetchJenkinsCrumbAndSession() {
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setMethod('GET');
    request.setEndpoint('callout:Jenkins_Auth/crumbIssuer/api/json');  // Using Named Credential
    //request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('your-jenkins-username:your-api-token')));

    HttpResponse response = http.send(request);
    if (response.getStatusCode() == 200) {
        Map<String, Object> crumbResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String crumbToken = (String) crumbResponse.get('crumb');
        String crumbField = (String) crumbResponse.get('crumbRequestField');

        // Extract JSESSIONID from response headers
        String sessionCookie;
        for (String header : response.getHeaderKeys()) {
            if (header.toLowerCase().contains('set-cookie')) {
                String cookieValue = response.getHeader(header);
                if (cookieValue.startsWith('JSESSIONID')) {
                    sessionCookie = cookieValue.split(';')[0];  // Extract "JSESSIONID=xxxx"
                }
            }
        }

        return new Map<String, String>{ 'crumbToken' => crumbToken, 'crumbField' => crumbField, 'sessionCookie' => sessionCookie };
    } else {
        throw new CalloutException('Failed to get Jenkins Crumb Token: ' + response.getStatusCode());
    }
}

}