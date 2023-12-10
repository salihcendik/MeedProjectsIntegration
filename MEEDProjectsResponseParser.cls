/**
 * @author            : salihcendik
 * @last modified on  : 05-11-2023
 * @last modified by  : salih.cendik
**/
public with sharing class MEEDProjectsResponseParser {
	
	public List<Projects> Projects;
	public List<TotalRecordsDetails> TotalRecordsDetails;
	
	public class TotalRecordsDetails {
		public Integer TotalRecords;
		public Integer NoOfPages;
	}
	
	public class Projects {
		public List<ProjectInformation> ProjectInformation;
		public List<MEEDContacts> MEEDContacts;
		public List<MEEDContractors> MEEDContractors;
		public List<MEEDLocations> MEEDLocations;
		public List<RelatedProjects> RelatedProjects;
		public List<MeedStageHistory> MeedStageHistory;
		public List<Companies> Companies;
	}
	
	public class ProjectInformation {
		public Integer ProjectId;
		public Integer OldProjectId;
		public String MEEDTitle;
		public Boolean isParentProject;
		public String ParentProject;
		public String MEEDCityTown;
		public String MEEDCountry;
		public String Industry;
		public Double ProjectValue;
		public String MEEDCountryRegion;
		public String MEEDContractType;
		public String MEEDStage;
		public String ProfileType;
		public String MEEDLocationType;
		public String LocationData;
		public String MEEDSector;
		public List<String> ProjectScope;
		public Boolean isBrownfield;
		public String LastUpdatedOn;
		public Double NetValue;
		public Double MEEDContractValue;
		public Boolean hasChild;
		public String MEEDCompletionDate;
		public Double Progress;
		public String MEEDAwardedDate;
		public Double CashSpent;
		public String ImageDownload;
		public String Url;
	}
	
	public class MEEDContacts {
		public String FirstName;
		public String LastName;
		public String Name;
		public String Title;
		public String Phone;
		public String Email;
	}
	
	public class MEEDContractors {
		public Integer CompanyId;
		public String CompanyName;
		public String CompanyType;
		public String CompanyLocation;
		public String ContactType;
		public String Phone;
		public String Website;
		public String UrlNode;
	}
	
	public class MEEDLocations {
		public Double MEEDLatitude;
		public Double MEEDLongitude;
		public Double MEEDCountryLatitude;
		public Double MEEDCountryLongitude;
		public Double MEEDRegionLatitude;
		public Double MEEDRegionLongitude;
		public Double MEEDCityLatitude;
		public Double MEEDCityLongitude;
	}
	
	public class RelatedProjects {
		public Integer ProjectId;
		public String ProjectName;
		public String Status;
		public String Industry;
		public String Sector;
		public Double NetValue;
	}
	
	public class Companies {
		public Integer CompanyId;
		public String CompanyName;
	}

	public class MeedStageHistory {
	}

	public static MEEDProjectsResponseParser parse(String json) {
		return (MEEDProjectsResponseParser) System.JSON.deserialize(json, MEEDProjectsResponseParser.class);
	}
}