public without sharing class TPQcheckDuplicateRequest {
    private static final String DELIMITER = ';';

    public class Request {
        @InvocableVariable(required = true)
        public Id accountId;

        @InvocableVariable(required = true)
        public List<Id> mandatoryProductIds;

        @InvocableVariable(required = true)
        public String trailerTypesString;

        @InvocableVariable(required = true)
        public Id seasonId;
    }

    public class Response {
        @InvocableVariable
        public Boolean uniqueRequest;
    }

    @InvocableMethod(
        label='TPQ Check Duplicate Price Request'
        description='Checks if there is a duplicate Price Request based on mandatory Lane Prices and trailer types.'
    )
    public static List<Response> checkDuplicateRequest(List<Request> requestList) {
        List<Response> results = new List<Response>();

        for (Request req : requestList) {
            Boolean uniqueRequest = true;

            List<String> trailerTypesList = new List<String>();
            if (String.isNotBlank(req.trailerTypesString)) {
                trailerTypesList = req.trailerTypesString.split(DELIMITER);
            }

            // Query existing Lane Prices
            List<Lane_Price__c> lanePrices = [
                SELECT Id
                FROM Lane_Price__c
                WHERE Freight_Price__c != null
                    AND Mandatory__c = true
                    AND Lane__c IN :req.mandatoryProductIds
                    AND Type_Of_Trailer__c IN :trailerTypesList
                    AND Price_Request__r.Account__c = :req.accountId
                    AND Price_Request__r.Season__c = :req.seasonId
            ];

            // If all mandatory lanes already have prices, request is not unique
            if (lanePrices.size() == req.mandatoryProductIds.size() && !lanePrices.isEmpty()) {
                uniqueRequest = false;
            }

            Response res = new Response();
            res.uniqueRequest = uniqueRequest;
            results.add(res);
        }

        return results;
    }
}