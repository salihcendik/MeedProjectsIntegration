#MEED Projects Integration

MEEDProjectsIntegrationBatch meed = new MEEDProjectsIntegrationBatch();
meed.fromDate = '08-12-2023';
meed.toDate = '08-12-2023';
Database.executeBatch(meed, 1);
