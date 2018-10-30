global class BatchScheduleUpdateRank implements Schedulable {

    String obj;

    global BatchScheduleUpdateRank(String obj) {
        this.obj = obj;
    }

    global void execute(SchedulableContext sc) {
        BatchUpdateRank b = new BatchUpdateRank(this.obj);
        database.executebatch(b,200);
    } 
} 
