trigger WeatherTrigger on Weather__c (after insert, after update) {
    if(trigger.isInsert && trigger.isAfter){
        for (Weather__c weather : Trigger.new) {
            if (weather.City__c != null) {
                System.debug('Triggering Jenkins Job for City: ' + weather.City__c);
                JenkinsTrigger.triggerJenkinsJob(weather.City__c, weather.Id); 
            }
        }
    }
    
    /*if(trigger.isUpdate && trigger.isAfter){
        for (Weather__c weather : Trigger.new) {
            if (Trigger.oldMap.get(weather.Id).PostSuccess__c == false && weather.PostSuccess__c == true) {
                System.debug('Jenkins Job triggered successfully for City: ' + weather.City__c);
                JenkinsTrigger.fetchJenkinsWeatherData(weather.Id); 
            }
        }
    }*/
}