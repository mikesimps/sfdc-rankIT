public class BatchUpdateRank implements Database.Batchable<sObject>, Database.Stateful {

    String query;
    Integer rank = 1;
    Integer successCount = 0;
    Integer errorCount = 0;
    String targetField;
    String emailBody;

    public BatchUpdateRank(String objectName) {

        RankIt_Settings__mdt[] settings = [SELECT Id, Object__c, DeveloperName, Order__c, Source_Field__c, 
                                                Target_Field__c, Filter__c, Record_Limit__c
                                            FROM RankIt_Settings__mdt
                                            WHERE Object__c = :objectName AND ActiveInd__c = true LIMIT 1];
        
        if(settings != null) {
            RankIt_Settings__mdt setting = settings[0];
            this.query = 'SELECT Id, ' + setting.Source_Field__c + ', ' + setting.Target_Field__c + ' FROM ' + objectName;

            if (setting.Filter__c != null) {
                this.query += ' WHERE ' + setting.Filter__c;
            }
                        
            this.query += ' ORDER BY ' + setting.Source_Field__c + ' ' + setting.Order__c + ' LIMIT ' + setting.Record_Limit__c.intValue();
            this.targetField = setting.Target_Field__c;
        } else {
            this.query = 'SELECT ID FROM Account WHERE Id = 1'; //will never be true and will just skip all processing if there are no active ranks
        }
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {

        for (sObject r : scope) {
            r.put(this.targetField, this.rank);
            this.rank++;
        }

        List<Database.SaveResult> SaveResultList = Database.update(scope, false);
        for(Integer i = 0; i < SaveResultList.size(); i++) {
            Database.SaveResult sr = SaveResultList[i];
            if(sr.IsSuccess()) {
                this.successCount++;
            } else {
                this.errorCount++;
                for(Database.Error e: sr.getErrors()) {
                    this.emailBody += scope[i] + ': ' + e.getStatusCode() + ' - ' + e.getMessage() + ' - ' + e.getFields() + '\n';
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {

        List<String> toAddresses = new List<String>(); 
        for(ApexEmailNotification aen: [Select Id, User.Email, Email FROM ApexEmailNotification]) {
            if(aen.User.Email == null) {
                toAddresses.add(aen.Email);
            } else {
                toAddresses.add(aen.User.Email);
            }
        }

        if (this.errorCount > 0 && toAddresses.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSenderDisplayName('Salesforce - RankIt');
            mail.setSubject('Failures in RankIt UpdateRank Job: ' + this.errorCount);
            mail.setToAddresses(toAddresses);
            mail.setPlainTextBody(this.emailBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }
}