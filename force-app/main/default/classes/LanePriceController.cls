public with sharing class LanePriceController {
    
    @AuraEnabled(cacheable=true)
    public static List<LaneWrapper> getLanePricesByAccountId(Id accountId) {
        List<LaneWrapper> laneWrappers = new List<LaneWrapper>();
        
        try {
            List<Lane_Price__c> lanePrices = [
                SELECT 
                    Id,
                    Name,
                    CreatedDate, 
                    Lane_Name__c,
                    Freight_Price__c,
                    Type_Of_Trailer__c,
                    Price_Request__c,
                    Price_Request__r.Name,
                    Price_Request__r.Season__c
                FROM Lane_Price__c 
                WHERE Price_Request__r.Account__c = :accountId
                AND Freight_Price__c != null
            ];

            for(Lane_Price__c lp : lanePrices){
                LaneWrapper wrapper = new LaneWrapper();
                wrapper.lanePriceId = lp.Id;
                wrapper.priceRequestName = lp.Price_Request__r.Name;
                wrapper.laneName = lp.Lane_Name__c;
                wrapper.freightPrice = lp.Freight_Price__c;
                wrapper.typeOfTrailer = lp.Type_Of_Trailer__c;
                wrapper.requestDate = lp.CreatedDate.date();
                wrapper.priceRequestId = lp.Price_Request__c;
                wrapper.seasonId = lp.Price_Request__r.Season__c;
                laneWrappers.add(wrapper);
            }
            return laneWrappers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class LaneWrapper {
        @AuraEnabled public Id lanePriceId { get; set; }
        @AuraEnabled public String priceRequestName { get; set; }
        @AuraEnabled public String laneName { get; set; }
        @AuraEnabled public Decimal freightPrice { get; set; }
        @AuraEnabled public String typeOfTrailer { get; set; }
        @AuraEnabled public Date requestDate { get; set; }
        @AuraEnabled public Id priceRequestId { get; set; }
        @AuraEnabled public Id seasonId { get; set; }
    }
}