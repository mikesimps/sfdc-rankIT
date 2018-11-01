public class BatchUpdateRank implements Database.Batchable<sObject>, Database.Stateful {

    String query;
    Integer rank = 1;
    Integer successCount = 0;
    Integer errorCount = 0;
    String targetField;
    String emailBody;

    public BatchUpdateRank(String objectName) {

        List<RankIt_Settings__mdt> settings =  RankITUtil.getSettings(objectName);
        
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

        if (this.errorCount > 0) {
            RankITUtil.sendFailureEmail('Failures in RankIT UpdateRank Job: ' + this.errorCount, this.emailBody);
        }
    }
}