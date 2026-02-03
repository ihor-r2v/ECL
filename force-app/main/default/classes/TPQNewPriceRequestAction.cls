public without sharing class TPQNewPriceRequestAction {
    private static final String DEFAULT_CURRENCY = 'EUR';
    private static final String DELIMITER = ';';
    
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;

        @InvocableVariable(required=true)
        public List<String> loadingCountryCodes;

        @InvocableVariable(required=true)
        public List<String> deliveryCountryCodes;

        @InvocableVariable(required=true)
        public List<Id> mandatoryProductIds;

        @InvocableVariable(required=true)
        public String trailerTypesString;
        
        @InvocableVariable(required=true)
        public Id seasonId;
    }

    public class Response {
        @InvocableVariable
        public Id priceRequestId;
    }

    public class TPQException extends Exception {}

    @InvocableMethod(label='TPQ New Price Request Action' description='TPQ Creates a Price_Request__c record with Lane_Price__c')
    public static List<Response> createPriceRequest(List<Request> requestList) {
        List<Response> results = new List<Response>();
        
        if (requestList == null || requestList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'No request data provided to TPQ Price Request action');
            return results;
        }

        Request req = requestList[0];
        
        try {        
            Id priceRequestId = processRequest(req);
            
            Response res = new Response();
            res.priceRequestId = priceRequestId;
            results.add(res);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in TPQ Price Request creation: ' + e.getMessage());
            throw e;
        }

        return results;
    }

    private static Id processRequest(Request req) {

        List<String> loadingCountryCodes = parseCountryCodes(req.loadingCountryCodes);
        List<String> deliveryCountryCodes = parseCountryCodes(req.deliveryCountryCodes);
        List<String> trailerTypesList = req.trailerTypesString.split(DELIMITER);
        
        Account acc = [
            SELECT Destination_Country_Codes__c, Trailer_Types__c
            FROM Account 
            WHERE Id = :req.accountId
            LIMIT 1
        ];
        List<String> accountDestinations = parsePicklistField(acc.Destination_Country_Codes__c);
        List<String> accountTrailerTypes = parsePicklistField(acc.Trailer_Types__c);

        // Filter trailer types to only keep types that exist in accountTrailerTypes
        List<String> filteredTrailerTypes = new List<String>();
        if (!accountTrailerTypes.isEmpty() && !trailerTypesList.isEmpty()) {
            Set<String> accountTrailerSet = new Set<String>(accountTrailerTypes);
            for (String type : trailerTypesList) {
                if (accountTrailerSet.contains(type)) {
                    filteredTrailerTypes.add(type);
                }
            }
        }
       
        // Filter deliveryCountryCodes to only keep codes that exist in accountDestinations
        if (!accountDestinations.isEmpty() && !deliveryCountryCodes.isEmpty()) {
            Set<String> accountDestSet = new Set<String>(accountDestinations);
            List<String> filteredDeliveryCodes = new List<String>();

            for (String code : deliveryCountryCodes) {
                if (accountDestSet.contains(code)) {
                    filteredDeliveryCodes.add(code);
                }
            }
            deliveryCountryCodes = filteredDeliveryCodes;
        }

        List<Product2> matchingProducts = queryMatchingProducts(loadingCountryCodes, deliveryCountryCodes);
        Price_Request__c priceRequest = createPriceRequestRecord(req.accountId, req.seasonId);  
        
        createLanePricesForProducts(
            priceRequest.Id, 
            matchingProducts, 
            req.mandatoryProductIds, 
            filteredTrailerTypes,
            req.accountId,
            req.seasonId
        );
        
        return priceRequest.Id;
    }

    @TestVisible
    private static List<String> parseCountryCodes(List<String> countryCodes) {
        List<String> parsedCodes = new List<String>();
        
        if (countryCodes == null) {
            return parsedCodes;
        }
        
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

    @TestVisible
    private static List<String> parsePicklistField(String picklistValue) {
        List<String> values = new List<String>();
        if (String.isBlank(picklistValue)) return values;
        for (String val : picklistValue.split(DELIMITER)) {
            String clean = val.trim();
            if (String.isNotBlank(clean)) values.add(clean);
        }
        return values;
    }

    @TestVisible
    private static List<Product2> queryMatchingProducts(
        List<String> loadingCountryCodes, 
        List<String> deliveryCountryCodes
    ) {
        String baseQuery = 'SELECT Id, Name FROM Product2';
        List<String> filters = new List<String>();
        
        if (!loadingCountryCodes.isEmpty()) {
            filters.add('Loading_Location__r.Country_Code__c IN :loadingCountryCodes');
        }
        
        if (!deliveryCountryCodes.isEmpty()) {
            filters.add('Destination_Location__r.Country_Code__c IN :deliveryCountryCodes');
        }

        if (!filters.isEmpty()) {
            baseQuery += ' WHERE ' + String.join(filters, ' AND ');
        }

        return Database.query(baseQuery);
    }


    @TestVisible
    private static Price_Request__c createPriceRequestRecord(Id accountId, Id seasonId) {
        String type = [SELECT Type__c FROM Season__c WHERE Id = :seasonId].Type__c;
        Price_Request__c priceRequest = new Price_Request__c(
            Account__c = accountId,
            Request_Date__c = Date.today(),
            Season__c = seasonId,
            Type__c = type,
            CurrencyIsoCode = DEFAULT_CURRENCY
        );
        
        try {
            insert priceRequest;
            return priceRequest;
        } catch (DmlException e) {
            throw new TPQException('Failed to create price request: ' + e.getMessage());
        }
    }

    @TestVisible
    private static void createLanePricesForProducts(
        Id priceRequestId, 
        List<Product2> matchingProducts, 
        List<Id> mandatoryProductIds, 
        List<String> trailerTypes,
        Id accountId,
        Id seasonId
    ) {
        List<Lane_Price__c> lanePrices = new List<Lane_Price__c>();
        Set<Id> mandatoryProductSet = new Set<Id>(mandatoryProductIds);

        Map<Id, List<String>> productIdToTrailerTypeMap = getAvailablePricesForAccount(accountId, seasonId);
        
        if (trailerTypes.isEmpty()) {
            // Create lane prices without trailer types
            for (Product2 prod : matchingProducts) {
                Lane_Price__c lanePrice = createLanePriceRecord(
                    priceRequestId, 
                    prod.Id, 
                    null, 
                    mandatoryProductSet.contains(prod.Id)
                );
                lanePrices.add(lanePrice);            
            }
        } else {            
            for (String trailerType : trailerTypes) {
                for (Product2 prod : matchingProducts) {
                    List<String> existingTrailerTypes = productIdToTrailerTypeMap.get(prod.Id);
                    // Create a Lane Price only if there is no existing Lane Price for the product and trailer type with a price already set
                    if (existingTrailerTypes == null || !existingTrailerTypes.contains(trailerType)) {
                        Lane_Price__c lanePrice = createLanePriceRecord(
                            priceRequestId, 
                            prod.Id, 
                            trailerType, 
                            mandatoryProductSet.contains(prod.Id)
                        );
                        lanePrices.add(lanePrice);
                    }
                }
            }
        }

        if (!lanePrices.isEmpty()) {
            try {
                insert lanePrices;
            } catch (DmlException e) {
                throw new TPQException('Failed to create lane prices: ' + e.getMessage());
            }
        }
    }

    @TestVisible
    private static Map<Id, List<String>> getAvailablePricesForAccount(Id accountId, Id seasonId) {
        List<Lane_Price__c> availablePrices = [
            SELECT Id, 
                Lane__c,
                Type_Of_Trailer__c 
            FROM Lane_Price__c 
            WHERE Price_Request__r.Account__c = :accountId 
                AND Price_Request__r.Season__c = :seasonId
                AND Freight_Price__c != NULL
        ];
       
        Map<Id, List<String>> productIdToTrailerTypeMap = new Map<Id, List<String>>();
        for (Lane_Price__c price : availablePrices) {
            if (productIdToTrailerTypeMap.containsKey(price.Lane__c)) {
                productIdToTrailerTypeMap.get(price.Lane__c).add(price.Type_Of_Trailer__c);
            } else {
                productIdToTrailerTypeMap.put(price.Lane__c, new List<String>{price.Type_Of_Trailer__c});
            }
        }
        
        return productIdToTrailerTypeMap;
    }

    @TestVisible
    private static Lane_Price__c createLanePriceRecord(
        Id priceRequestId, 
        Id productId, 
        String trailerType, 
        Boolean isMandatory
    ) {
        Lane_Price__c lanePrice = new Lane_Price__c(
            Price_Request__c = priceRequestId,
            Lane__c = productId,
            CurrencyIsoCode = DEFAULT_CURRENCY,
            Mandatory__c = isMandatory
        );
        
        if (String.isNotBlank(trailerType)) {
            lanePrice.Type_Of_Trailer__c = trailerType;
        }
        
        return lanePrice;
    }
}