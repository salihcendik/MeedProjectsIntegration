public virtual class MEEDProjectsIntegrationBase {
    public final String REC_TYPE_ID = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('LeadProject').getRecordTypeId();
    public final String BASE_URL = MEED_API_Settings__c.getOrgDefaults().Endpoint__c;

    public void upsertProjects(List<MEEDProjectsResponseParser.Projects> meedProjects){
        List<Project__c> projectsToUpsert = new List<Project__c>();

        for (MEEDProjectsResponseParser.Projects project : meedProjects) {
            Project__c newProject = new Project__c();
            newProject.recordTypeId = REC_TYPE_ID;
            newProject.Project_Source__c = 'Meed';
            newProject.Project_Status__c = 'Lead';
            newProject.SalesOrg__c = '2102';
            newProject.Company__c = '2100';
            processProjectInformation(newProject, project.ProjectInformation);
            processMEEDLocations(newProject, project.MEEDLocations);
            processMEEDContacts(newProject, project.MEEDContacts);
            processMEEDContractors(newProject, project.MEEDContractors);
            projectsToUpsert.add(newProject);
        }

        Schema.SObjectField projectId = Project__c.yr_ProjeId__c; 
        Database.UpsertResult[] results = database.upsert(projectsToUpsert, projectId, false);
        generateErrorLogs(projectsToUpsert, results);
    }

    public void processProjectInformation(Project__c newProject, List<MEEDProjectsResponseParser.ProjectInformation> informations){
        if (newProject == null || informations.isEmpty()){
            return;
        }
        MEEDProjectsResponseParser.ProjectInformation info = informations[0];
        newProject.yr_ProjeId__c = String.valueof(info.ProjectId);
        newProject.Name = (info.MEEDTitle).left(80);
        newProject.Meed_Parent_Project__c = info.ParentProject;
        newProject.yr_ProjeSehir__c = info.MEEDCityTown;
        newProject.yr_ProjeUlke__c = info.MEEDCountry;
        newProject.Meed_Industry__c = info.Industry;
        newProject.yr_ProjeBedeli__c = String.valueof(info.ProjectValue);
        newProject.Meed_Region__c = info.MEEDCountryRegion;
        newProject.Meed_Contract_Type__c = info.MEEDContractType;
        newProject.Project_Stage__c = info.MEEDStage;
        newProject.Meed_Profile_Type__c = info.ProfileType;
        newProject.Meed_Location_Type__c = info.MEEDLocationType;
        newProject.yr_ProjectCategory__c = info.MEEDSector;
        newProject.Meed_Scope__c = String.join(info.ProjectScope, '\n');
        newProject.isBrownfield__c = info.isBrownfield;
        newProject.Meed_Net_Value__c = info.NetValue;
        newProject.MEED_Contract_Value__c = info.MEEDContractValue;
        newProject.yr_kayittarih__c = info.MEEDCompletionDate;
        newProject.Progress__c = info.Progress;
        newProject.Cash_Spend__c = info.CashSpent;
        newProject.Image_Download_Link__c = info.ImageDownload;
        newProject.Project_URL__c = info.URL;

        /* Process Date Fields*/
        Date awardedDate = Date.valueof(info.MEEDAwardedDate);
        Date completionDate = checkIfEndlessDate(info.MEEDCompletionDate);
        newProject.StartDate__c = awardedDate;
        newProject.yr_BaslangicYilCeyrek__c = String.valueOf(awardedDate?.year()) + String.valueOf(getQuarterOfYear(awardedDate)); 
        newProject.EndDate__c = completionDate;
        newProject.yr_BitisYilCeyrek__c = String.valueOf(completionDate?.year()) + String.valueOf(getQuarterOfYear(completionDate)); 
    }

    public Integer getQuarterOfYear(Date inputDate){
        if (inputDate == null){
            return null;
        }
        return (inputDate.month() - 1) / 3 + 1; 
    }

    public Date checkIfEndlessDate(String dateStr){
        return Date.valueof(dateStr?.substringBefore('-') == '0001' ? dateStr.replace('0001', '4000') : dateStr);
    }

    public void processMEEDLocations(Project__c newProject, List<MEEDProjectsResponseParser.MEEDLocations> locations){
        if (newProject == null || locations.isEmpty()){
            return;
        }
        newProject.Project_Location__latitude__s = locations[0].MEEDLatitude;
        newProject.Project_Location__longitude__s = locations[0].MEEDLongitude;
    }

    public void processMEEDContacts(Project__c newProject, List<MEEDProjectsResponseParser.MEEDContacts> meedContacts){
        if (newProject == null || meedContacts.isEmpty()){
            return;
        }
        String allContacts = '';
        for (MEEDProjectsResponseParser.MEEDContacts contact: meedContacts){
            if (contact.Title == 'Procurement Manager'){
                newProject.yr_ProjeYetkili__c = contact.Name;
                newProject.yr_YetkiliGorev__c = contact.Title;
                newProject.yr_YetkiliMail__c = contact.Email;
                newProject.yr_YetkiliTelefon__c = contact.Phone;
            }else{
                String contactInfo = contact.Name + '-' + contact.Title + '-' + contact.Email + '-' + contact.Phone; 
                allContacts += contactInfo + '▪\n';
            }
        }
        newProject.All_Contacts__c = allContacts;
    }

    public void processMEEDContractors(Project__c newProject, List<MEEDProjectsResponseParser.MEEDContractors> meedContractors){
        if (newProject == null || meedContractors.isEmpty()){
            return;
        }
        String allAccounts = '';
        for (MEEDProjectsResponseParser.MEEDContractors contract: meedContractors){
            if (contract.ContactType == 'Main Contractor'){
                newProject.yr_MuteahhitAdi__c = contract.CompanyName;
                newProject.yr_muteahhitAdres__c = contract.CompanyLocation;
                newProject.yr_muteahhitType__c = contract.CompanyType;
                newProject.Contractor_Meed_Id__c = String.valueof(contract.CompanyId);
                newProject.Contractor_Website__c = contract.Website;
            }else{
                String contractInfo = contract.CompanyName + '-' + contract.CompanyType + '-' + contract.CompanyLocation + '-' + contract.Website;        
                allAccounts += contractInfo + '▪\n';
            }
        }
        newProject.All_Accounts__c = allAccounts;
    }

    public HttpResponse sendRequest(MeedRequest reqParam){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String baseURL = this.BASE_URL + '/api/Content/GetProjectsDetails';
        String queryParams = 'TokenID=' + reqParam.tokenId +
                            '&DisplayName=vitra' +
                            '&ProfileType=All' +
                            '&ProjectOwnerType=All' +
                            '&PageNumber=' + reqParam.pageNumber;

        if (String.isNotBlank(reqParam.pageSize)){
            queryParams += '&PageSize=' + reqParam.pageSize;
        }
        if (String.isNotBlank(reqParam.fromDate) && String.isNotBlank(reqParam.toDate)){
            queryParams += '&FromDate=' + reqParam.fromDate + '&ToDate=' + reqParam.toDate;
        }
        String requestUrl = baseURL + '?' + queryParams;
        req.setEndpoint(requestUrl); 
        req.setMethod('GET');  
        return http.send(req);
    }

    public String generateNewTokenId(String oldTokenId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String baseURL = this.BASE_URL + '/api/Token/TokenGeneration';
        String queryParams = 'OldTokenId=' + oldTokenId;
        String requestUrl = baseUrl + '?' + queryParams;
        req.setEndpoint(requestUrl); 
        req.setMethod('GET'); 
        HttpResponse response = http.send(req);
        if (response.getStatusCode() != 200 || response.getBody().contains('Incorrect')){
            throw new CalloutException(response.getBody());
        }
        List<MeedTokenResponseParser> result = (List<MeedTokenResponseParser>) JSON.deserialize(response.getBody(), List<MeedTokenResponseParser>.class);
        updateMeedSettings(result[0]);
        return result[0].Tokenid;
    }

    public void updateMeedSettings(MeedTokenResponseParser tokenInfo){
        MEED_API_Settings__c meedSetting = MEED_API_Settings__c.getOrgDefaults();
        meedSetting.put('Tokenid__c',tokenInfo.Tokenid);
        meedSetting.put('Issued_Date__c',tokenInfo.IssuedDate);
        meedSetting.put('Expiry_Date__c',tokenInfo.ExpiryDate);
        update meedSetting;
    }

    public void generateErrorLogs(List<Project__c> projectsToUpsert, List<Database.UpsertResult> results){
        List<String> errors = new List<String>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results.get(i).isSuccess()) {
                errors.add('Record which got error : ' + projectsToUpsert.get(i));
                for(Database.Error err : results.get(i).getErrors()) {
                errors.add(err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields());
                }
                errors.add('-------------------------------');
            }
        }
        if(!errors.isEmpty()) {
            System.debug('Error count : ' + errors.size() / 3);
            System.debug(String.join(errors, '\n'));
            Logger.error('Error count : ' + errors.size() / 3);
            Logger.error(String.join(errors, '\n'));
        }
    }

    public class MeedRequest{
        public String tokenId;
        public String fromDate;  //dd-mm-yyyy
        public String toDate;  //dd-mm-yyyy
        public String pageNumber; //Default 1
        public String pageSize; //Default 100, Max. 100

        public MeedRequest(String tokenId, String fromDate, String toDate, String pageNumber, String pageSize){
            this.tokenId = tokenId;
            this.fromDate = fromDate;
            this.toDate = toDate;
            this.pageNumber = pageNumber;
            this.pageSize = pageSize;
        }
    }

    public class MeedTokenResponseParser {
        public String Tokenid;
        public String IssuedDate;
        public String ExpiryDate;
    }
}