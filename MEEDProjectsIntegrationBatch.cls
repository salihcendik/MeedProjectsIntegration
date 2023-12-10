public with sharing class MEEDProjectsIntegrationBatch extends MEEDProjectsIntegrationBase implements Database.Batchable<Integer>, Database.AllowsCallouts, Schedulable {
    public String originalTransactionId;
    public String tokenId; 
    public String fromDate;  //dd-mm-yyyy
    public String toDate;  //dd-mm-yyyy
    public String pageNumber; //Default 1
    public String pageSize; //Default 100, Max. 100
    public Boolean isJob = false;

    public MEEDProjectsIntegrationBatch(){
        this.tokenId = MEED_API_Settings__c.getOrgDefaults().Tokenid__c;
        this.pageNumber = '1';
    }

    public Iterable<Integer> start(Database.BatchableContext bc) {
        this.originalTransactionId = Logger.getTransactionId();
        Logger.info('MEEDProjectsIntegrationBatch is starting...');
        MeedRequest meedParam = new MeedRequest(this.tokenId, this.fromDate, this.toDate, this.pageNumber, this.pageSize);
        HttpResponse response = sendRequest(meedParam);
        if (response.getStatusCode() == 401){
            String newTokenId = generateNewTokenId(this.tokenId);
            meedParam.tokenId = newTokenId;
            response = sendRequest(meedParam);
        }
        if(response.getStatusCode() != 200) {
            throw new CalloutException(response.getBody());
        }

        MEEDProjectsResponseParser result = MEEDProjectsResponseParser.parse(response.getBody());
        if (result == null || result?.TotalRecordsDetails?.isEmpty()){
            throw new CalloutException('There is no meed projects');
        }

        Integer numberOfPage = result.TotalRecordsDetails[0].NoOfPages;
        Logger.info('Count of requests: ' +  numberOfPage); 

        List<Integer> pageNumbers = new List<Integer>();
        for (Integer i = 1; i <= numberOfPage; i++) {
            pageNumbers.add(i);
        }
        Logger.saveLog();
        return pageNumbers;
    }

    public void execute(Database.BatchableContext bc, List<Integer> pageNumbers){
        Logger.setParentLogTransactionId(this.originalTransactionId);
        if(pageNumbers.size() != 1 ) {
            throw new CalloutException('Batch size must be 1');
        }
        this.pageNumber = String.valueof(pageNumbers[0]);
        Logger.info('Request #' + this.pageNumber);
        MeedRequest meedParam = new MeedRequest(this.tokenId, this.fromDate, this.toDate, this.pageNumber, this.pageSize);
        HttpResponse response = sendRequest(meedParam);
        MEEDProjectsResponseParser parsedResponse = MEEDProjectsResponseParser.parse(response.getBody());
        system.debug(parsedResponse);
        upsertProjects(parsedResponse.Projects);
        Logger.saveLog();
    }  

    public void finish(Database.BatchableContext bc){
        if (this.isJob){
            return;
        }
        Set<String> recipientsIds = new Set<String>{Userinfo.getUserId()};
        Messaging.CustomNotification notification = new Messaging.CustomNotification(); 
        notification.setTitle('Meed Projects Batch Completed'); 
        notification.setBody('Batch Job Id: '+ bc.getJobId()); 
        String pgRef = '{ type: "standard__objectPage", attributes:{objectApiName: "Project__c", actionName: "list"}}';
        notification.setTargetPageRef(pgRef);   
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Batch_Completed_Notification'];  
        notification.setNotificationTypeId(notificationType.id); 
        notification.send(recipientsIds);
    }

    public void execute(SchedulableContext schedulableContext) {
        MEEDProjectsIntegrationBatch meedBatch = new MEEDProjectsIntegrationBatch();
        meedBatch.isJob = true; 
        meedBatch.fromDate = DateTime.now().format('dd-MM-yyyy');
        meedBatch.toDate = DateTime.now().format('dd-MM-yyyy');
        Database.executeBatch(meedBatch, 1);
    }
}


