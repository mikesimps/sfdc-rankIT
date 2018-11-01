public class RankITUtil {

    public static void sendFailureEmail(String subject, String emailBody) {
        
        List<String> toAddresses = new List<String>(); 
        for(ApexEmailNotification aen: [Select Id, User.Email, Email FROM ApexEmailNotification]) {
            if(aen.User.Email == null) {
                toAddresses.add(aen.Email);
            } else {
                toAddresses.add(aen.User.Email);
            }
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSenderDisplayName('Salesforce - RankIt');
        mail.setSubject(subject);
        mail.setToAddresses(toAddresses);
        mail.setPlainTextBody(emailBody);

        if (toAddresses.size() > 0) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }

    public static List<RankIt_Settings__mdt> getSettings(String objectName) {
        
        String settingsSoql = 'SELECT Id, Object__c, DeveloperName, Order__c, Source_Field__c,'
                        + 'Target_Field__c, Filter__c, Record_Limit__c '
                    + 'FROM RankIt_Settings__mdt '
                    + 'WHERE Object__c = \'' + objectName + '\'';

        if(!Test.isRunningTest()) {
            settingsSoql += ' AND ActiveInd__c = true';
        } else {
            settingsSoql += ' AND Include_In_Tests__c = true';
        }

        return database.query(settingsSoql + ' LIMIT 1');
    }
}
