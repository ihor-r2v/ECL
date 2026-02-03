public with sharing class TPQAddLanesToPriceRequestAction {
    private static final String DEFAULT_CURRENCY = 'EUR';
    private static final String DELIMITER = ';';

    public class Input {
        @InvocableVariable(required=true)
        public Id priceRequestId;
       
        @InvocableVariable(required=true)
        public List<String> filteredLaneIds;

        @InvocableVariable
        public List<String> mandatoryLaneIds;

        @InvocableVariable(required=true)
        public String trailerTypesString;
    }

    @InvocableMethod(label='TPQ Add Lanes To Price Request' description='TPQ Add Lanes To Price Request')
    public static void addLanesToPriceRequest(List<Input> inputs)
    {    
        if (inputs == null || inputs.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'No input data provided to run TPQ Add Lanes To Price Request');
            return;
        }
        
        try
        {
            Input req = inputs[0];
            List<Lane_Price__c> lanePricesToInsert = new List<Lane_Price__c>();
            List<String> filteredLaneIds = req.filteredLaneIds;
            List<String> mandatoryLaneIds = req.mandatoryLaneIds == null ? new List<String>() : req.mandatoryLaneIds;
            List<String> trailerTypesList = req.trailerTypesString.split(DELIMITER);

            if (trailerTypesList.isEmpty()) {
                // Create lane prices without trailer types
                for (String productId : filteredLaneIds) {
                    lanePricesToInsert.add(
                        new Lane_Price__c(
                            Lane__c = productId,
                            Price_Request__c = req.priceRequestId,
                            Mandatory__c = mandatoryLaneIds.contains(productId) ? true : false,
                            CurrencyIsoCode = DEFAULT_CURRENCY
                        )
                    );           
                }
            } else {            
                for (String trailerType : trailerTypesList) {
                    for (String productId : filteredLaneIds) {
                        lanePricesToInsert.add(
                            new Lane_Price__c(
                                Lane__c = productId,
                                Price_Request__c = req.priceRequestId,
                                Type_Of_Trailer__c = trailerType,
                                Mandatory__c = mandatoryLaneIds.contains(productId) ? true : false,
                                CurrencyIsoCode = DEFAULT_CURRENCY
                            )
                        );
                    }
                }
            }

            if (!lanePricesToInsert.isEmpty()) insert lanePricesToInsert;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in TPQ Add Lanes To Price Request: ' + e.getMessage());
            throw e;
        }

        return;
    }
}