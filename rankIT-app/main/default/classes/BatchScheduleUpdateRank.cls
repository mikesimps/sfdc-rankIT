global class BatchScheduleUpdateRank implements Schedulable {

    String obj;

    global BatchScheduleUpdateRank(String obj) {
        this.obj = obj;
    }

    global void execute(SchedulableContext sc) {
        BatchClearRank b = new BatchClearRank(this.obj);
        database.executebatch(b,200);
    } 
} 
