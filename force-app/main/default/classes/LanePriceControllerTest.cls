@isTest
private class LanePriceControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Carrier Account',
            Type = 'Carrier'
        );
        insert testAccount;
        
        Location__c loadingLocation = new Location__c(
            Name = 'Loading Test Location',
            Type__c = 'Loading',
            Country_Code__c = 'DE',
            Postal_Code__c = '12345'
        );
        
        Location__c deliveryLocation = new Location__c(
            Name = 'Delivery Test Location',
            Type__c = 'Delivery',
            Country_Code__c = 'FR',
            Postal_Code__c = '67890'
        );
        
        insert new List<Location__c>{loadingLocation, deliveryLocation};
        
        Product2 testLane = new Product2(
            Name = 'Test Lane DE-FR',
            Loading_Location__c = loadingLocation.Id,
            Destination_Location__c = deliveryLocation.Id,
            IsActive = true
        );
        insert testLane;
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received'
        );
        insert testPriceRequest;
        
        List<Lane_Price__c> testLanePrices = new List<Lane_Price__c>();
        
        Lane_Price__c lanePrice1 = new Lane_Price__c(
            Price_Request__c = testPriceRequest.Id,
            Lane__c = testLane.Id,
            Freight_Price__c = 1000,
            Type_Of_Trailer__c = 'Frigo - chilled'
        );
        testLanePrices.add(lanePrice1);
        
        Lane_Price__c lanePrice2 = new Lane_Price__c(
            Price_Request__c = testPriceRequest.Id,
            Lane__c = testLane.Id,
            Freight_Price__c = 1200,
            Type_Of_Trailer__c = 'Dual temp'
        );
        testLanePrices.add(lanePrice2);
        
        insert testLanePrices;
    }
    
    @isTest
    static void testGetLanePricesByAccountIdSuccess() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<LanePriceController.LaneWrapper> results = LanePriceController.getLanePricesByAccountId(testAccount.Id);
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return 2 lane prices');
        
        LanePriceController.LaneWrapper result1 = results[0];
        Assert.isNotNull(result1.lanePriceId, 'Lane price ID should not be null');
        Assert.isNotNull(result1.priceRequestName, 'Price request name should not be null');
        Assert.areEqual('Test Lane DE-FR', result1.laneName, 'Lane name should match');
        Assert.isNotNull(result1.freightPrice, 'Freight price should not be null');
        Assert.isNotNull(result1.typeOfTrailer, 'Type of trailer should not be null');
        Assert.isNotNull(result1.requestDate, 'Request date should not be null');
        Assert.isNotNull(result1.priceRequestId, 'Price request ID should not be null');
    }
    
    @isTest
    static void testGetLanePricesByAccountIdNoResults() {
        Account newAccount = new Account(
            Name = 'New Test Account',
            Type = 'Carrier'
        );
        insert newAccount;
        
        Test.startTest();
        List<LanePriceController.LaneWrapper> results = LanePriceController.getLanePricesByAccountId(newAccount.Id);
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return no lane prices for account with no price requests');
    }
    
    @isTest
    static void testGetLanePricesByAccountIdWithNullFreightPrice() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Price_Request__c testPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        Product2 testLane = [SELECT Id FROM Product2 LIMIT 1];
        
        Lane_Price__c nullPriceLane = new Lane_Price__c(
            Price_Request__c = testPriceRequest.Id,
            Lane__c = testLane.Id,
            Freight_Price__c = null,
            Type_Of_Trailer__c = 'Frigo - chilled'
        );
        insert nullPriceLane;
        
        Test.startTest();
        List<LanePriceController.LaneWrapper> results = LanePriceController.getLanePricesByAccountId(testAccount.Id);
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should only return lane prices with non-null freight prices');
        for (LanePriceController.LaneWrapper wrapper : results) {
            Assert.isNotNull(wrapper.freightPrice, 'All returned lane prices should have freight price');
        }
    }
    
    @isTest
    static void testLaneWrapperProperties() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<LanePriceController.LaneWrapper> results = LanePriceController.getLanePricesByAccountId(testAccount.Id);
        Test.stopTest();
        
        Assert.isTrue(results.size() > 0, 'Should have at least one result');
        
        LanePriceController.LaneWrapper wrapper = results[0];
        Assert.isNotNull(wrapper.lanePriceId, 'Lane price ID should not be null');
        Assert.isNotNull(wrapper.priceRequestName, 'Price request name should not be null');
        Assert.isNotNull(wrapper.laneName, 'Lane name should not be null');
        Assert.isNotNull(wrapper.freightPrice, 'Freight price should not be null');
        Assert.isNotNull(wrapper.typeOfTrailer, 'Type of trailer should not be null');
        Assert.isNotNull(wrapper.requestDate, 'Request date should not be null');
        Assert.isNotNull(wrapper.priceRequestId, 'Price request ID should not be null');
    }
}