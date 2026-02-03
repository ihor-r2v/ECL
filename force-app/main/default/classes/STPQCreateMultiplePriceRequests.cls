public without sharing class STPQCreateMultiplePriceRequests {
    private static final String DELIMITER = ';';
    
    public class Request {
        @InvocableVariable(required=true)
        public Id seasonId;

        @InvocableVariable(required=true)
        public List<Id> accountIds;

        @InvocableVariable(required=true)
        public List<Id> productIds;

        @InvocableVariable(required=true)
        public String trailerTypesString;
    }

    @InvocableMethod(
        label='STPQ Create Multiple Price Requests' 
        description='Creates Price Requests for multiple accounts and products for a given season'
    )
    public static List<List<Price_Request__c>> createPriceRequests(List<Request> requestList) {
        List<List<Price_Request__c>> result = new List<List<Price_Request__c>>();
        
        if (requestList == null || requestList.isEmpty()) {
            result.add(new List<Price_Request__c>());
            return result;
        }

        Request req = requestList[0];
        
        if (req.accountIds == null || req.accountIds.isEmpty() || 
            req.productIds == null || req.productIds.isEmpty()) {
            result.add(new List<Price_Request__c>());
            return result;
        }

        try {
            String seasonName = [SELECT Name FROM Season__c WHERE Id = :req.seasonId].Name;

            List<Account> accounts = [
                SELECT Id, Name 
                FROM Account 
                WHERE Id IN :req.accountIds
            ];

            if (accounts.isEmpty()) {
                result.add(new List<Price_Request__c>());
                return result;
            }

            // Create Price Requests
            List<Price_Request__c> newPriceRequests = new List<Price_Request__c>();
            Date requestDate = Date.today();

            for (Account account : accounts) {
                newPriceRequests.add(new Price_Request__c(
                    Name = seasonName + ' - ' + account.Name,
                    Request_Date__c = requestDate,
                    Season__c = req.seasonId,
                    Account__c = account.Id,
                    Type__c = 'Spot',
                    Show_Additional_Information__c = true
                ));
            }

            insert newPriceRequests;

            // Update Portal URLs
            String portalURL = [SELECT Portal_URL__c FROM Portal_Settings__mdt WHERE DeveloperName = 'Portal_Access']?.Portal_URL__c;
            for (Price_Request__c priceRequest : newPriceRequests) {
                priceRequest.Portal_URL__c = portalURL + '/?id=' + priceRequest.Id;
            }
            update newPriceRequests;

            // Parse trailer types
            List<String> trailerTypesList = new List<String>();
            if (String.isNotBlank(req.trailerTypesString)) {
                trailerTypesList = req.trailerTypesString.split(DELIMITER);
            }

            // Calculate total number of Lane Prices needed
            Integer totalLanePrices = newPriceRequests.size() * req.productIds.size() * trailerTypesList.size();
            List<Lane_Price__c> lanePrices = new List<Lane_Price__c>();
            
            // Use single loop with calculated indices instead of triple nested loop
            for (Integer i = 0; i < totalLanePrices; i++) {
                Integer priceRequestIndex = Math.mod(i / (req.productIds.size() * trailerTypesList.size()), newPriceRequests.size());
                Integer productIndex = Math.mod(i / trailerTypesList.size(), req.productIds.size());
                Integer trailerIndex = Math.mod(i, trailerTypesList.size());
                
                lanePrices.add(new Lane_Price__c(
                    Lane__c = req.productIds[productIndex],
                    Price_Request__c = newPriceRequests[priceRequestIndex].Id,
                    Type_Of_Trailer__c = trailerTypesList[trailerIndex],
                    Mandatory__c = true
                ));
            }

            if (!lanePrices.isEmpty()) {
                insert lanePrices;
            }

            result.add(newPriceRequests);
            
        } catch (Exception e) {
            System.debug('Error in createPriceRequests: ' + e.getMessage());
            result.add(new List<Price_Request__c>());
        }

        return result;
    }
}