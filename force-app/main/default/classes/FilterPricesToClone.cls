public with sharing class FilterPricesToClone {
    public class Request {
        @InvocableVariable(required=true)
        public Id targetAccountId;

        @InvocableVariable(required=true)
        public Id originalAccountId;

        @InvocableVariable(required=true)
        public Id originalPriceRequestId;
    }

    public class Response {
        @InvocableVariable
        public Integer originalPricesCount;

        @InvocableVariable
        public Integer targetPricesCount;

        @InvocableVariable
        public String originalDestinationCodes;

        @InvocableVariable
        public String originalTrailerTypes;

        @InvocableVariable
        public List<Id> lanePriceIdsForCloning;

    }

    @InvocableMethod(
        label='Filter Prices To Clone Action' 
        description='Filters out irrelevant lane prices based on account settings'
    )
    public static List<Response> filterPrices(List<Request> requestList) {
        List<Response> results = new List<Response>();

        if (requestList == null || requestList.isEmpty()) { return results; }

        Request req = requestList[0];
        Response res = new Response(); 

        List<Lane_Price__c> originalLanePrices = getLanePrices(req.originalPriceRequestId);
        if (originalLanePrices.isEmpty()) { return results; }

        res.originalPricesCount = originalLanePrices.size();
        res.originalTrailerTypes = String.join(getOriginalTrailerTypes(originalLanePrices), ';');
        res.originalDestinationCodes = String.join(getOriginalDestinationCodes(originalLanePrices), ';');

        Account targetAccount = getAccount(req.targetAccountId);
        Account originalAccount = getAccount(req.originalAccountId);
        List<String> targetDestinationCountries = parseMultiSelectPicklist(targetAccount.Destination_Country_Codes__c);
        List<String> targetTrailerTypes = parseMultiSelectPicklist(targetAccount.Trailer_Types__c);

        if (targetDestinationCountries.isEmpty() || targetTrailerTypes.isEmpty()) {return results;}

        List<Id> lanePriceIdsForCloning = getLanePriceIdsForCloning(originalLanePrices, targetDestinationCountries, targetTrailerTypes);

        res.targetPricesCount = lanePriceIdsForCloning.size();
        res.lanePriceIdsForCloning = lanePriceIdsForCloning;
        results.add(res);
        
        return results;
    }

    private static List<Lane_Price__c> getLanePrices(Id priceRequestId) {
        return [
            SELECT 
                Id, 
                Lane__c,
                CurrencyIsoCode,
                Mandatory__c,
                Type_Of_Trailer__c, 
                Lane__r.Destination_Location__r.Country_Code__c 
            FROM Lane_Price__c 
            WHERE Price_Request__c = :priceRequestId
        ];
    }

    private static Set<String> getOriginalTrailerTypes(List<Lane_Price__c> originalLanePrices) {
        Set<String> result = new Set<String>();
        for (Lane_Price__c lanePrice : originalLanePrices) {
            result.add(lanePrice.Type_Of_Trailer__c);
        }
        return result;
    }

    private static Set<String> getOriginalDestinationCodes(List<Lane_Price__c> originalLanePrices) {
        Set<String> result = new Set<String>();
        for (Lane_Price__c lanePrice : originalLanePrices) {
            result.add(lanePrice.Lane__r?.Destination_Location__r?.Country_Code__c);
        }
        return result;
    }

    private static Account getAccount(Id accountId) {
        return [
            SELECT 
                Id, 
                Name, 
                Trailer_Types__c,
                Destination_Country_Codes__c 
            FROM Account 
            WHERE Id = :accountId
        ];
    }

    private static List<String> parseMultiSelectPicklist(String picklistValue) {
        return String.isBlank(picklistValue) 
            ? new List<String>() 
            : picklistValue.split(';');
    }

    private static List<Id> getLanePriceIdsForCloning(
        List<Lane_Price__c> originalLanePrices,
        List<String> targetDestinationCountries,
        List<String> targetTrailerTypes
    ) {
        List<Id> result = new List<Id>();

        for (Lane_Price__c lanePrice : originalLanePrices) {
            if (
                targetDestinationCountries.contains(lanePrice.Lane__r?.Destination_Location__r?.Country_Code__c) &&
                targetTrailerTypes.contains(lanePrice.Type_Of_Trailer__c)
            ) {
                result.add(lanePrice.Id);
            }
        }

        return result;
    }
}