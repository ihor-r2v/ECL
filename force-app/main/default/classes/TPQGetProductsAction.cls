public without sharing class TPQGetProductsAction {
    private static final String DELIMITER = ';';
    
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;

        @InvocableVariable(required=true)
        public List<String> loadingCountryCodes;

        @InvocableVariable(required=true)
        public List<String> deliveryCountryCodes;
    }

    @InvocableMethod(label='TPQ Get Products' description='Returns Products records by request')
    public static List<List<Product2>> getProducts(List<Request> requestList) {
        List<List<Product2>> groupedResults = new List<List<Product2>>();
        
        if (requestList == null || requestList.isEmpty()) {
            groupedResults.add(new List<Product2>());
            return groupedResults;
        }

        Request req = requestList[0];

        // Get Account destination country codes
        Account acc = [SELECT Destination_Country_Codes__c FROM Account WHERE Id = :req.accountId LIMIT 1];
        List<String> accountDestinations = parsePicklistField(acc.Destination_Country_Codes__c);

        // If account has no destinations, return empty list
        if (accountDestinations.isEmpty()) {
            groupedResults.add(new List<Product2>());
            return groupedResults;
        }

        List<String> loadingCountryCodes = new List<String>();
        for (String str : req.loadingCountryCodes) {
            for (String code : str.split(DELIMITER)) {
                if (!String.isBlank(code)) loadingCountryCodes.add(code.trim());
            }
        }

        List<String> deliveryCountryCodes = new List<String>();
        for (String str : req.deliveryCountryCodes) {
            for (String code : str.split(DELIMITER)) {
                if (!String.isBlank(code)) deliveryCountryCodes.add(code.trim());
            }
        }

        String baseQuery = 
            'SELECT Id, Name, Loading_Location__r.Country_Code__c, Destination_Location__r.Country_Code__c ' +
            'FROM Product2';

        List<String> filters = new List<String>();
        
        if (!loadingCountryCodes.isEmpty()) {
            filters.add('Loading_Location__r.Country_Code__c IN :loadingCountryCodes');
        }
        
        if (!deliveryCountryCodes.isEmpty()) {
            filters.add('Destination_Location__r.Country_Code__c IN :deliveryCountryCodes');
        }

        // Add account destinations filter - REQUIRED
        filters.add('Destination_Location__r.Country_Code__c IN :accountDestinations');

        if (!filters.isEmpty()) {
            baseQuery += ' WHERE ' + String.join(filters, ' AND ');
        }

        List<Product2> matchingProducts = Database.query(baseQuery);

        groupedResults.add(matchingProducts);
        return groupedResults;
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
}