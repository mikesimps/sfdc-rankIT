public class BatchClearRank implements Database.Batchable<sObject>, Database.Stateful {

    String query;
    String obj;
    Integer successCount = 0;
    Integer errorCount = 0;
    String targetField;
    String emailBody;

    public BatchClearRank(String objectName) {
        this.obj = objectName;

        List<RankIt_Settings__mdt> settings =  RankITUtil.getSettings(objectName);
        
        if(settings != null) {
            RankIt_Settings__mdt setting = settings[0];
            this.query = 'SELECT Id, ' + setting.Source_Field__c + ', ' + setting.Target_Field__c 
                        + ' FROM ' + objectName
                        + ' WHERE ' + setting.Target_Field__c + ' <> null';
            this.targetField = setting.Target_Field__c;

        } else {
            this.query = 'SELECT ID FROM Account WHERE Id = 1'; //will never be true and will just skip all processing if there are no active ranks
        }
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        system.debug(this.targetField);
        for (sObject r : scope) {
            r.put(this.targetField, null);
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
            RankITUtil.sendFailureEmail('Failures in RankIT ClearRank Job: ' + this.errorCount, this.emailBody);
        } else {
            BatchUpdateRank b = new BatchUpdateRank(this.obj);
            database.executebatch(b,200);
        }
    }
}