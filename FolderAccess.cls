/*
** This class is written to get a list of report / dashboard folders with sharing access detail
** Author:            Dilip Rathore
** Date (Created):    9/14        
*/

public with sharing class FolderAccess {
    public list<folder> reportDashboardFolders{get; set;}
    public string URL; //= system.URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v45.0/folders';
    public string SESSION_ID  = UserInfo.getSessionId();
    public String LATESTAPIVERSION;
    public string METHOD = 'GET'; 
    public FolderAccess(){
        decimal APIVersion = [SELECT ApiVersion FROM ApexClass order by ApiVersion desc limit 1].ApiVersion;
        LATESTAPIVERSION = String.valueOf(APIVersion);
        URL = system.URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v'+LATESTAPIVERSION+'/folders';
        reportDashboardFolders = getFolderList();
        for(folder obj: reportDashboardFolders){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'OAuth ' + SESSION_ID);
            req.setEndpoint(URL+'/'+obj.Id+'/shares');
            req.setMethod(METHOD);
            HttpResponse res = h.send(req);
            if (res.getStatusCode() == 200){
                obj.shares = (shares)JSON.deserialize(res.getBody(),shares.class);
            }
        }
    }
    public pageReference exportToExcel(){
        pageReference pageToPrint  = Page.FolderAccessPage2;
        pageToPrint.setRedirect(false);
        return pageToPrint;          
    }

    // Method to fetch Folder and folder sharing detail for report and dashboard folders
    public list<folder> getFolderList(){  
        Http h = new Http();
        HttpRequest req = new HttpRequest();    
        req.setHeader('Authorization', 'OAuth ' + SESSION_ID);
        req.setEndpoint(URL);
        req.setMethod(METHOD);
        HttpResponse res = h.send(req);
        List<folder> fldrList = new List<folder>();
        if (res.getStatusCode() == 200){
           // String s = res.getBody();
            FolderResponse deserializeResults = (FolderResponse)JSON.deserialize(res.getBody(),FolderResponse.class);
            for(folder fldr:deserializeResults.folders){
                if(fldr.type == 'Report' || fldr.type == 'Dashboard'){
                    fldrList.add(fldr);
                }
            }
        }
        if(fldrList.isEmpty()){
            return null;
        } else{
            return fldrList;
        }
    }  

    // Wrapper class for folder list

    public with sharing class FolderResponse {
        public List<folder> folders;
        public Integer Count;
        public FolderResponse () {
        }
    }
    public class folder{
        public String Id{get; set;}
        public String label{get; set;}
        public String name{get; set;}
        public String namespace{get; set;}
        public String type{get; set;}
        public String url{get; set;}
        public shares shares{get; set;}
        public folder(String Id,String label,String name,String type){ 
            this.Id = Id;
            this.label= label;
            this.name= name;
            this.type= type;
        }
    }

    // Wrapper class for folder sharing
    public class shares{
        public list<share> shares{get; set;}
    }
    public class share{
        public String accessType{get; set;}
        public String imageColor{get; set;}
        public String imageUrl{get; set;}
        public String shareId{get; set;}
        public String shareType{get; set;}
        public String sharedWithId{get; set;}
        public String sharedWithLabel{get; set;}  
        public String url{get; set;}  
        public share(){
        }
    }
}