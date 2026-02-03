public with sharing class TPQGetLanesToAddInPriceRequest {
    private static final String DELIMITER = ';';
    public class Input {
        @InvocableVariable(required=true)
        public Id priceRequestId;

        @InvocableVariable(required=true)
        public List<String> loadingCountryCodes;

        @InvocableVariable(required=true)
        public List<String> deliveryCountryCodes;
    }

    public class Response {
        @InvocableVariable
        public List<Product2> matchingLanes;
    }

    @InvocableMethod(label='TPQ Get Lanes To Add In Price Request' description='TPQ Get Lanes To Add In Price Request')
    public static List<Response> addLanesToPriceRequest(List<Input> inputs) {
        List<Response> results = new List<Response>();

        if (inputs == null || inputs.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'No input data provided to run TPQ Get Lanes To Add In Price Request');
            return results;
        }

        try {
            Id priceRequestId = inputs[0].priceRequestId;

            List<String> loadingCountryCodes = parseCountryCodes(inputs[0].loadingCountryCodes);
            List<String> deliveryCountryCodes = parseCountryCodes(inputs[0].deliveryCountryCodes);

            Price_Request__c priceRequest = [SELECT Id, Account__r.Trailer_Types__c, Account__r.Destination_Country_Codes__c FROM Price_Request__c WHERE Id = :priceRequestId];
            List<Lane_Price__c> existingLanePrices = [SELECT Id, Lane__c, Type_Of_Trailer__c FROM Lane_Price__c WHERE Price_Request__c = :priceRequestId];

            List<String> accountDestinationCodes = priceRequest.Account__r.Destination_Country_Codes__c.split(';');
            List<Id> existingLaneIds = new List<Id>();
            for (Lane_Price__c lp : existingLanePrices) {
                existingLaneIds.add(lp.Lane__c);
            }

            List<Product2> lanes = [
                SELECT Id, Name, Loading_Country_Code__c, Destination_Country_Code__c
                FROM Product2 
                WHERE Id NOT IN :existingLaneIds 
                    AND Destination_Location__r.Country_Code__c IN :deliveryCountryCodes
                    AND Loading_Location__r.Country_Code__c IN :loadingCountryCodes
            ];

            Response res = new Response();
            res.matchingLanes = lanes;
            results.add(res);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in TPQ Get Lanes To Add In Price Request: ' + e.getMessage());
            throw e;
        }
        return results;
    }

    @TestVisible
    private static List<String> parseCountryCodes(List<String> countryCodes) {
        List<String> parsedCodes = new List<String>();
        
        if (countryCodes == null) { return parsedCodes; }
        
        for (String str : countryCodes) {
            if (String.isNotBlank(str)) {
                for (String code : str.split(DELIMITER)) {
                    String cleanCode = code.trim();
                    if (String.isNotBlank(cleanCode)) {
                        parsedCodes.add(cleanCode);
                    }
                }
            }
        }
    
        return parsedCodes;
    }
}