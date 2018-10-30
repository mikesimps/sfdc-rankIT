@IsTest public class BatchUpdateRankTEST {
    static void generateData() {
        List<Account> accts = new List<Account>();

        for(Integer i = 1; i<=100; i++) {
            Account a = new Account(Name = 'Test Account ' + i, AnnualRevenue = i * Math.mod(i,4));
            accts.add(a);
        }

        insert accts;
    }

    static testMethod void testUpdateRank() {
        generateData();

        Test.startTest();
            BatchUpdateRank bur = new BatchUpdateRank('Account');
            Database.executeBatch(bur, 100);
        Test.stopTest();

        List<Account> accts = [SELECT Id, Name, AnnualRevenue, Rank__c FROM Account WHERE Rank__c <> null ORDER BY Rank__c ASC];
        System.assertEquals(75, accts.size());
        System.assertEquals('Test Account 99', accts[0].name);
        System.assertEquals('Test Account 90', accts[12].name);
    }

    static testmethod void testScheduler() {
       
        Test.startTest();
            BatchScheduleUpdateRank baur = new BatchScheduleUpdateRank('Account');      
            String sch = '0 0 0 * * ?';
            system.schedule('UpdateRankTest', sch, baur);
        Test.stopTest();

        List<CronTrigger> ct = [SELECT Id, CronJobDetail.Name, CronJobDetail.Id, State
                                FROM CronTrigger 
                                WHERE CronJobDetail.Name = 'UpdateRankTest' AND State !='COMPLETE'];
        
        System.assertEquals(1, ct.size());
    }
}
