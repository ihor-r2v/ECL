public without sharing class STPQGetAccountsByDeliveryCodesAction {
    private static final String DELIMITER = ';';

    public class Request {
        @InvocableVariable(required=true label='Delivery Country Codes')
        public List<String> deliveryCountryCodes;

        @InvocableVariable(required=true label='Trailer Types')
        public String trailerTypesString;
    }

    @InvocableMethod(
        label='STPQ Get Accounts By Delivery Country Codes and Trailer Types' 
        description='Retrieves Accounts that have ALL the specified delivery country codes and Trailer Types'
    )
    public static List<List<Account>> getAccounts(List<Request> requestList) {
        List<List<Account>> result = new List<List<Account>>();
        
        if (requestList == null || requestList.isEmpty()) {
            result.add(new List<Account>());
            return result;
        }

        Request req = requestList[0];
        
        if (req.deliveryCountryCodes == null || req.deliveryCountryCodes.isEmpty()) {
            result.add(new List<Account>());
            return result;
        }

        try {
            // Parse trailer types
            List<String> trailerTypesList = new List<String>();
            if (String.isNotBlank(req.trailerTypesString)) {
                trailerTypesList = req.trailerTypesString.split(DELIMITER);
            }
            
            // Build WHERE clause for both fields
            String whereClause = buildWhereClause(req.deliveryCountryCodes, trailerTypesList);
            
            String query = 'SELECT Id, Name, Type, Today__c, Destination_Country_Codes__c, Trailer_Types__c ' +
                          'FROM Account ' +
                          'WHERE ' + whereClause +
                          ' ORDER BY Name';
            
            List<Account> matchingAccounts = Database.query(query);
            
            result.add(matchingAccounts);
            
        } catch (Exception e) {
            System.debug('Error in getAccounts: ' + e.getMessage());
            result.add(new List<Account>());
        }

        return result;
    }

    private static String buildWhereClause(List<String> countryCodes, List<String> trailerTypes) {
        List<String> conditions = new List<String>();
        
        // Add conditions for country codes
        for (String code : countryCodes) {
            String sanitizedCode = String.escapeSingleQuotes(code.trim());
            conditions.add('Destination_Country_Codes__c INCLUDES (\'' + sanitizedCode + '\')');
        }
        
        // Add conditions for trailer types
        if (trailerTypes != null && !trailerTypes.isEmpty()) {
            for (String trailerType : trailerTypes) {
                String sanitizedType = String.escapeSingleQuotes(trailerType.trim());
                conditions.add('Trailer_Types__c INCLUDES (\'' + sanitizedType + '\')');
            }
        }
        
        return String.join(conditions, ' AND ');
    }
}