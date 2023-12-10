# MEED Projects Integration

* Get Full Data: <br/>
Database.executeBatch(new MEEDProjectsIntegrationBatch(), 1);
* Get Filtered Data:<br/> 
MEEDProjectsIntegrationBatch meed = new MEEDProjectsIntegrationBatch();<br/>
meed.fromDate = '08-12-2023';<br/>
meed.toDate = '08-12-2023';<br/>
Database.executeBatch(meed, 1);
