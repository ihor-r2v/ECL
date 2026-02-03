public with sharing class ClonePriceRequestAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id originalPriceRequestId;

        @InvocableVariable(required=true)
        public Id targetAccountId;

        @InvocableVariable(required=true)
        public List<Id> matchingLanePrices;
    }

    public class Response {
        @InvocableVariable
        public Id clonedPriceRequestId;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(label='Clone Price Request Action' description='Clone price request with matching lane prices')
    public static List<Response> createPriceRequest(List<Request> requestList) {
        List<Response> results = new List<Response>();

        if (requestList == null || requestList.isEmpty()) { return results; }

        Request req = requestList[0];
        Response res = new Response();

        try {
            Account targetAccount = getAccount(req.targetAccountId);
            Price_Request__c originalPriceRequest = getPriceRequest(req.originalPriceRequestId);
            Price_Request__c clonedPriceRequest = clonePriceRequest(originalPriceRequest, targetAccount);
            insert clonedPriceRequest;

            res.clonedPriceRequestId = clonedPriceRequest.Id;

            List<Lane_Price__c> lanePrices = getLanePrices(req.matchingLanePrices);

            List<Lane_Price__c> lanePricesToClone = prepareClonedLanePrices(lanePrices, clonedPriceRequest.Id);

            insert lanePricesToClone;

            results.add(res);
        } catch (Exception e) {
            res.errorMessage = e.getMessage();
            results.add(res);
        }
        
        return results;
    }

    private static Account getAccount(Id accountId) {
        return [
            SELECT 
                Id, 
                Name, 
                Destination_Country_Codes__c, 
                Trailer_Types__c 
            FROM Account 
            WHERE Id = :accountId
        ];
    }

    private static Price_Request__c clonePriceRequest(Price_Request__c originalPriceRequest, Account targetAccount) {
        Price_Request__c cloned = originalPriceRequest.clone(false, true, false, false);
        cloned.Name = originalPriceRequest.Season__r?.Name + ' - ' + targetAccount.Name;
        cloned.Account__c = targetAccount.Id;
        cloned.Stage__c = 'Answer pending';
        cloned.Request_Date__c = Date.today();
        return cloned;
    }

    private static List<Lane_Price__c> prepareClonedLanePrices(
        List<Lane_Price__c> lanePrices,
        Id clonedPriceRequestId
    ) {
        List<Lane_Price__c> clonedList = new List<Lane_Price__c>();

        for (Lane_Price__c lanePrice : lanePrices) {
            Lane_Price__c clonedLanePrice = lanePrice.clone(false, true, false, false);
            clonedLanePrice.Price_Request__c = clonedPriceRequestId;
            clonedLanePrice.Freight_Price__c = null;
            clonedList.add(clonedLanePrice);
        }

        return clonedList;
    }

    private static Price_Request__c getPriceRequest(Id priceRequestId) {
        return [
            SELECT 
                Id,
                Request_Date__c,
                CurrencyIsoCode,
                Type__c,
                Account__c,
                ADR__c,
                Season__c,
                Season__r.Name,
                Show_Additional_Information__c,
                Seasonal_surcharge__c,
                Overnight_charges__c,
                Pallet_exchange__c,
                Diesel_mark_up__c,
                Tail_lift__c,
                Additional_stops__c,
                Dangerous_Goods__c,
                ETS__c,
                Show_Additional_Lane_Price_Information__c,
                Plug_in__c,
                Harbour_dues__c,
                Pallet_jack__c,
                Waiting_hours__c,
                Weekend_charges__c,
                Two_drivers__c,
                Direct_Ferry__c,
                Fuel_surcharge_percentage__c 
            FROM Price_Request__c 
            WHERE Id = :priceRequestId 
        ];
    }

    private static List<Lane_Price__c> getLanePrices(List<Id> matchingLanePrices) {
        return [
            SELECT 
                Id, 
                Lane__c,
                CurrencyIsoCode,
                Mandatory__c,
                Price_Request__c,
                Type_Of_Trailer__c, 
                Freight_Price__c
            FROM Lane_Price__c 
            WHERE Id IN :matchingLanePrices
        ];
    }
}