@isTest
public class NLAddNewLaneActionTest {
    
    @TestSetup
    static void setupTestData() {

        Id standardPricebookId = Test.getStandardPricebookId();
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = standardPricebookId,
            IsActive = true
        );
        update standardPricebook;

        List<Location__c> loadingLocations = new List<Location__c>{
            new Location__c(
                Name = 'Loading Location 1',
                Type__c = 'Loading',
                Country_Code__c = 'NL',
                Postal_Code__c = '1012AB'
            ),
            new Location__c(
                Name = 'Loading Location 2',
                Type__c = 'Loading',
                Country_Code__c = 'DE',
                Postal_Code__c = '10115'
            )
        };
        insert loadingLocations;
        
        List<Location__c> deliveryLocations = new List<Location__c>{
            new Location__c(
                Name = 'Delivery Location 1',
                Type__c = 'Delivery',
                Country_Code__c = 'GB',
                Postal_Code__c = 'SW1A 1AA'
            ),
            new Location__c(
                Name = 'Delivery Location 2',
                Type__c = 'Delivery',
                Country_Code__c = 'NL',
                Postal_Code__c = '2514AB'
            )
        };
        insert deliveryLocations;
    }
    
    @isTest
    static void testCreateLoadingLocation() {

        NLAddNewLaneAction.Request req = new NLAddNewLaneAction.Request();
        req.locationName = 'New Loading Location';
        req.locationType = 'Loading';
        req.locationISOCode = 'GB';
        req.locationPostalCode = 'W1A 1AA';
        
        List<NLAddNewLaneAction.Request> requests = new List<NLAddNewLaneAction.Request>{req};
        
        Test.startTest();
        List<NLAddNewLaneAction.Response> responses = NLAddNewLaneAction.createPriceRequest(requests);
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isNotNull(responses[0].locationId, 'Location Id should not be null');
        
        Location__c createdLocation = [SELECT Id, Name, Type__c, Country_Code__c, Postal_Code__c 
                                       FROM Location__c 
                                       WHERE Id = :responses[0].locationId];
        Assert.areEqual('New Loading Location', createdLocation.Name);
        Assert.areEqual('Loading', createdLocation.Type__c);
        Assert.areEqual('GB', createdLocation.Country_Code__c);
        Assert.areEqual('W1A 1AA', createdLocation.Postal_Code__c);
        
        List<Product2> lanes = [SELECT Id, Name, ProductCode, Loading_Location__c, Destination_Location__c 
                                FROM Product2 
                                WHERE Loading_Location__c = :responses[0].locationId];
        Assert.areEqual(2, lanes.size(), 'Should create 2 lanes for 2 existing Delivery locations');
        
        List<PricebookEntry> pbes = [SELECT Id, Product2Id, UnitPrice 
                                      FROM PricebookEntry 
                                      WHERE Product2Id IN :lanes 
                                      AND Pricebook2.IsStandard = true];
        Assert.areEqual(2, pbes.size(), 'Should create 2 pricebook entries');
        Assert.areEqual(0, pbes[0].UnitPrice, 'Unit price should be 0');
    }
    
    @isTest
    static void testCreateDeliveryLocation() {

        NLAddNewLaneAction.Request req = new NLAddNewLaneAction.Request();
        req.locationName = 'New Delivery Location';
        req.locationType = 'Delivery';
        req.locationISOCode = 'DE';
        req.locationPostalCode = '10115';
        
        List<NLAddNewLaneAction.Request> requests = new List<NLAddNewLaneAction.Request>{req};
        
        Test.startTest();
        List<NLAddNewLaneAction.Response> responses = NLAddNewLaneAction.createPriceRequest(requests);
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isNotNull(responses[0].locationId, 'Location Id should not be null');
        
        Location__c createdLocation = [SELECT Id, Name, Type__c, Country_Code__c, Postal_Code__c 
                                       FROM Location__c 
                                       WHERE Id = :responses[0].locationId];
        Assert.areEqual('New Delivery Location', createdLocation.Name);
        Assert.areEqual('Delivery', createdLocation.Type__c);
        
        List<Product2> lanes = [SELECT Id, Name, ProductCode, Loading_Location__c, Destination_Location__c 
                                FROM Product2 
                                WHERE Destination_Location__c = :responses[0].locationId];
        Assert.areEqual(2, lanes.size(), 'Should create 2 lanes from 2 existing Loading locations');
        
        for (Product2 lane : lanes) {
            Assert.isTrue(lane.Name.endsWith(' - New Delivery Location'), 'Lane name should end with new location name');
            Assert.isTrue(lane.ProductCode.endsWith('_NEW DELIVERY LOCATION'), 'ProductCode should follow naming convention');
        }
    }
    
    @isTest
    static void testCreateLocationWithNoExistingLocations() {

        delete [SELECT Id FROM Location__c];
        
        NLAddNewLaneAction.Request req = new NLAddNewLaneAction.Request();
        req.locationName = 'First Location';
        req.locationType = 'Loading';
        req.locationISOCode = 'FR';
        req.locationPostalCode = '75001';
        
        List<NLAddNewLaneAction.Request> requests = new List<NLAddNewLaneAction.Request>{req};
        
        Test.startTest();
        List<NLAddNewLaneAction.Response> responses = NLAddNewLaneAction.createPriceRequest(requests);
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isNotNull(responses[0].locationId, 'Location Id should not be null');
        
        List<Product2> lanes = [SELECT Id FROM Product2];
        Assert.areEqual(0, lanes.size(), 'Should not create any lanes when no matching locations exist');
    }
    
    @isTest
    static void testEmptyRequestList() {
        List<NLAddNewLaneAction.Request> emptyRequests = new List<NLAddNewLaneAction.Request>();
        
        Test.startTest();
        List<NLAddNewLaneAction.Response> responses = NLAddNewLaneAction.createPriceRequest(emptyRequests);
        Test.stopTest();
        
        Assert.areEqual(0, responses.size(), 'Should return empty response list for empty request');
    }
    
    @isTest
    static void testNullRequestList() {
        Test.startTest();
        List<NLAddNewLaneAction.Response> responses = NLAddNewLaneAction.createPriceRequest(null);
        Test.stopTest();
        
        Assert.areEqual(0, responses.size(), 'Should return empty response list for null request');
    }
    
    @isTest
    static void testProductCodeGeneration() {

        NLAddNewLaneAction.Request req = new NLAddNewLaneAction.Request();
        req.locationName = 'Test Location';
        req.locationType = 'Loading';
        req.locationISOCode = 'ES';
        req.locationPostalCode = '28001';
        
        List<NLAddNewLaneAction.Request> requests = new List<NLAddNewLaneAction.Request>{req};
        
        Test.startTest();
        List<NLAddNewLaneAction.Response> responses = NLAddNewLaneAction.createPriceRequest(requests);
        Test.stopTest();
        
        List<Product2> lanes = [SELECT Id, Name, ProductCode 
                                FROM Product2 
                                WHERE Loading_Location__c = :responses[0].locationId];
        
        for (Product2 lane : lanes) {
            Assert.isTrue(lane.ProductCode.startsWith('TEST LOCATION_'), 'ProductCode should start with uppercase location name');
            Assert.isTrue(lane.ProductCode.contains('_'), 'ProductCode should contain underscore separator');
        }
    }
    
    @isTest
    static void testBulkLocationCreation() {

        List<NLAddNewLaneAction.Request> requests = new List<NLAddNewLaneAction.Request>();
        
        for (Integer i = 1; i <= 3; i++) {
            NLAddNewLaneAction.Request req = new NLAddNewLaneAction.Request();
            req.locationName = 'Bulk Location ' + i;
            req.locationType = 'Delivery';
            req.locationISOCode = 'IT';
            req.locationPostalCode = '0012' + i;
            requests.add(req);
        }
        
        Test.startTest();
        List<NLAddNewLaneAction.Response> responses = NLAddNewLaneAction.createPriceRequest(requests);
        Test.stopTest();
        
        Assert.areEqual(1, responses.size(), 'Should process first request');
    }
}