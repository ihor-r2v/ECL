public without sharing class NLAddNewLaneAction {
    public class Request {
        @InvocableVariable(required=true)
        public String locationName;

        @InvocableVariable(required=true)
        public String locationType;

        @InvocableVariable(required=true)
        public String locationISOCode;

        @InvocableVariable(required=true)
        public String locationPostalCode;
    }

    public class Response {
        @InvocableVariable
        public Id locationId;
    }

    public class TPQException extends Exception {}

    @InvocableMethod(label='NL New Location Action' description='Creates new Location and the corresponding Laness')
    public static List<Response> createPriceRequest(List<Request> requestList) {
        List<Response> results = new List<Response>();
        
        if (requestList == null || requestList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'No request data provided to NL New Location Action');
            return results;
        }
        
        try {  
            
            Request req = requestList[0];

            Location__c location = new Location__c(
                Name = req.locationName,
                Type__c = req.locationType,
                Country_Code__c = req.locationISOCode,
                Postal_Code__c = req.locationPostalCode
            );
            insert location;

            createLanes(location, req.locationType);

            Response res = new Response();
            res.locationId = location.Id;
            results.add(res);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in NL New Location Action insert Location: ' + e.getMessage());
            throw e;
        }

        return results;
    }

    private static void createLanes(Location__c location, String locationType) {
        try {
            List<Product2> newLanes = new List<Product2>();
            if (locationType == 'Loading') {
                List<Location__c> deliveryLocations = [SELECT Id, Name, Type__c FROM Location__c WHERE Type__c = 'Delivery'];
                for (Location__c loc : deliveryLocations) {
                    newLanes.add(
                        new Product2(
                            Name = location.Name + ' - ' + loc.Name,
                            ProductCode = location.Name.toUpperCase() + '_' + loc.Name.toUpperCase(),
                            Loading_Location__c = location.Id,
                            Destination_Location__c = loc.Id,
                            IsActive = true
                        )
                    );
                }
            } else {
                List<Location__c> loadingLocations = [SELECT Id, Name, Type__c FROM Location__c WHERE Type__c = 'Loading'];
                for (Location__c loc : loadingLocations) {
                    newLanes.add(
                        new Product2(
                            Name = loc.Name + ' - ' + location.Name,
                            ProductCode = loc.Name.toUpperCase() + '_' + location.Name.toUpperCase(),
                            Loading_Location__c = loc.Id,
                            Destination_Location__c = location.Id,
                            IsActive = true
                        )
                    );
                }
            }

            if (!newLanes.isEmpty()) {
                insert newLanes;
                addToStandardPriceBook(newLanes);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in NL New Location Action create products: ' + e.getMessage());
            throw e;
        }
    }

    public static void addToStandardPriceBook(List<Product2> newLanes) {
        try {
            Id standardPriceBookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            List<PricebookEntry> newPBEs = new List<PricebookEntry>();
            for (Product2 newLane : newLanes) {
                newPBEs.add(
                    new PricebookEntry(
                        Pricebook2Id = standardPriceBookId,
                        Product2Id = newLane.Id,
                        UnitPrice = 0,
                        IsActive = true
                    )
                );
            }
            insert newPBEs;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in NL New Location Action add poducts to standard pricebook: ' + e.getMessage());
            throw e;
        }
    }
}