@isTest
private class TPQGetLanesToAddInPriceRequestTest {

    @TestSetup
    static void setupTestData() {

        Account testAccount = new Account(
            Name = 'Test Carrier Account',
            Type = 'Carrier',
            Trailer_Types__c = 'Dual temp;Frigo - chilled',
            Destination_Country_Codes__c = 'NL;DE;FR',
            Access_code__c = 'NMMNBB6778'
        );
        insert testAccount;
        
        List<Location__c> locations = new List<Location__c>{
            new Location__c(
                Name = 'NL Loading Location',
                Type__c = 'Loading',
                Country_Code__c = 'NL',
                Postal_Code__c = '1234AB'
            ),
            new Location__c(
                Name = 'DE Loading Location',
                Type__c = 'Loading',
                Country_Code__c = 'DE',
                Postal_Code__c = '12345'
            ),
            new Location__c(
                Name = 'FR Delivery Location',
                Type__c = 'Delivery',
                Country_Code__c = 'FR',
                Postal_Code__c = '75001'
            ),
            new Location__c(
                Name = 'DE Delivery Location',
                Type__c = 'Delivery',
                Country_Code__c = 'DE',
                Postal_Code__c = '54321'
            ),
            new Location__c(
                Name = 'NL Delivery Location',
                Type__c = 'Delivery',
                Country_Code__c = 'NL',
                Postal_Code__c = '5678CD'
            ),
            new Location__c(
                Name = 'BE Delivery Location',
                Type__c = 'Delivery',
                Country_Code__c = 'BE',
                Postal_Code__c = '1000'
            )
        };
        insert locations;
        
        List<Product2> lanes = new List<Product2>{
            new Product2(
                Name = 'NL-FR Lane',
                Loading_Location__c = locations[0].Id,
                Destination_Location__c = locations[2].Id,
                IsActive = true
            ),
            new Product2(
                Name = 'NL-DE Lane',
                Loading_Location__c = locations[0].Id,
                Destination_Location__c = locations[3].Id,
                IsActive = true
            ),
            new Product2(
                Name = 'DE-FR Lane',
                Loading_Location__c = locations[1].Id,
                Destination_Location__c = locations[2].Id,
                IsActive = true
            ),
            new Product2(
                Name = 'DE-NL Lane',
                Loading_Location__c = locations[1].Id,
                Destination_Location__c = locations[4].Id,
                IsActive = true
            ),
            new Product2(
                Name = 'NL-BE Lane',
                Loading_Location__c = locations[0].Id,
                Destination_Location__c = locations[5].Id,
                IsActive = true
            )
        };
        insert lanes;
        
        Price_Request__c priceRequest = new Price_Request__c(
            Name = 'Test Price Request',
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received'
        );
        insert priceRequest;
        
        // Create existing lane price (NL-FR Lane already exists in price request)
        Lane_Price__c existingLanePrice = new Lane_Price__c(
            Price_Request__c = priceRequest.Id,
            Lane__c = lanes[0].Id,
            Type_Of_Trailer__c = 'Dual temp',
            Freight_Price__c = 1000,
            Mandatory__c = true,
            CurrencyIsoCode = 'EUR'
        );
        insert existingLanePrice;
    }
    
    @isTest
    static void testGetMatchingLanesSuccessfully() {
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        TPQGetLanesToAddInPriceRequest.Input input = new TPQGetLanesToAddInPriceRequest.Input();
        input.priceRequestId = priceRequest.Id;
        input.loadingCountryCodes = new List<String>{ 'NL;DE' };
        input.deliveryCountryCodes = new List<String>{ 'FR;DE' };
        
        Test.startTest();
        List<TPQGetLanesToAddInPriceRequest.Response> response = TPQGetLanesToAddInPriceRequest.addLanesToPriceRequest(
            new List<TPQGetLanesToAddInPriceRequest.Input>{ input }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.isNotNull(response[0].matchingLanes, 'Matching lanes should not be null');
        Assert.areEqual(2, response[0].matchingLanes.size(), 'Should return 2 matching lanes');
        
        Set<String> laneNames = new Set<String>();
        for (Product2 lane : response[0].matchingLanes) {
            laneNames.add(lane.Name);
        }

        Assert.isTrue(laneNames.contains('NL-DE Lane'), 'Should include NL-DE Lane');
        Assert.isTrue(laneNames.contains('DE-FR Lane'), 'Should include DE-FR Lane');
        Assert.isFalse(laneNames.contains('DE-NL Lane'), 'Should exclude DE-NL Lane (NL not in delivery codes)');
        Assert.isFalse(laneNames.contains('NL-FR Lane'), 'Should exclude existing NL-FR Lane');
        Assert.isFalse(laneNames.contains('NL-BE Lane'), 'Should exclude NL-BE Lane (BE not in delivery codes)');
    }
    
    @isTest
    static void testGetLanesWithSingleCountryCodes() {
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        TPQGetLanesToAddInPriceRequest.Input input = new TPQGetLanesToAddInPriceRequest.Input();
        input.priceRequestId = priceRequest.Id;
        input.loadingCountryCodes = new List<String>{ 'NL' };
        input.deliveryCountryCodes = new List<String>{ 'DE' };
        
        Test.startTest();
        List<TPQGetLanesToAddInPriceRequest.Response> response = TPQGetLanesToAddInPriceRequest.addLanesToPriceRequest(
            new List<TPQGetLanesToAddInPriceRequest.Input>{ input }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.areEqual(1, response[0].matchingLanes.size(), 'Should return 1 matching lane');
        Assert.areEqual('NL-DE Lane', response[0].matchingLanes[0].Name, 'Should return NL-DE Lane');
    }
    
    @isTest
    static void testGetLanesWithNoMatchingCountryCodes() {
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        TPQGetLanesToAddInPriceRequest.Input input = new TPQGetLanesToAddInPriceRequest.Input();
        input.priceRequestId = priceRequest.Id;
        input.loadingCountryCodes = new List<String>{ 'ES' };
        input.deliveryCountryCodes = new List<String>{ 'IT' };
        
        Test.startTest();
        List<TPQGetLanesToAddInPriceRequest.Response> response = TPQGetLanesToAddInPriceRequest.addLanesToPriceRequest(
            new List<TPQGetLanesToAddInPriceRequest.Input>{ input }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.areEqual(0, response[0].matchingLanes.size(), 'Should return 0 matching lanes');
    }
    
    @isTest
    static void testGetLanesWithInvalidInput() {
        Test.startTest();
        
        // Test null input list
        List<TPQGetLanesToAddInPriceRequest.Response> nullResponse = TPQGetLanesToAddInPriceRequest.addLanesToPriceRequest(null);
        Assert.areEqual(0, nullResponse.size(), 'Should handle null input');
        
        // Test empty input list
        List<TPQGetLanesToAddInPriceRequest.Response> emptyResponse = TPQGetLanesToAddInPriceRequest.addLanesToPriceRequest(
            new List<TPQGetLanesToAddInPriceRequest.Input>()
        );
        Assert.areEqual(0, emptyResponse.size(), 'Should handle empty input list');
        
        Test.stopTest();
    }
    
    @isTest
    static void testParseCountryCodesWithVariousFormats() {
        Test.startTest();
        
        // Test with semicolon-separated values
        List<String> result1 = TPQGetLanesToAddInPriceRequest.parseCountryCodes(new List<String>{ 'NL;DE;FR' });
        Assert.areEqual(3, result1.size(), 'Should parse 3 country codes');
        Assert.isTrue(result1.contains('NL'), 'Should contain NL');
        Assert.isTrue(result1.contains('DE'), 'Should contain DE');
        Assert.isTrue(result1.contains('FR'), 'Should contain FR');
        
        // Test with multiple list items
        List<String> result2 = TPQGetLanesToAddInPriceRequest.parseCountryCodes(new List<String>{ 'NL;DE', 'FR;BE' });
        Assert.areEqual(4, result2.size(), 'Should parse 4 country codes');
        
        // Test with spaces
        List<String> result3 = TPQGetLanesToAddInPriceRequest.parseCountryCodes(new List<String>{ ' NL ; DE ' });
        Assert.areEqual(2, result3.size(), 'Should parse 2 country codes and trim spaces');
        
        // Test with empty strings
        List<String> result4 = TPQGetLanesToAddInPriceRequest.parseCountryCodes(new List<String>{ '', 'NL', '' });
        Assert.areEqual(1, result4.size(), 'Should skip empty strings');
        Assert.areEqual('NL', result4[0], 'Should only return NL');
        
        // Test with null
        List<String> result5 = TPQGetLanesToAddInPriceRequest.parseCountryCodes(null);
        Assert.areEqual(0, result5.size(), 'Should handle null input');
        
        // Test with blank values
        List<String> result6 = TPQGetLanesToAddInPriceRequest.parseCountryCodes(new List<String>{ ';;NL;;' });
        Assert.areEqual(1, result6.size(), 'Should skip blank values');
        Assert.areEqual('NL', result6[0], 'Should only return NL');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetLanesExcludesExistingLanes() {
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        Product2 existingLane = [SELECT Id FROM Product2 WHERE Name = 'NL-FR Lane' LIMIT 1];
        
        TPQGetLanesToAddInPriceRequest.Input input = new TPQGetLanesToAddInPriceRequest.Input();
        input.priceRequestId = priceRequest.Id;
        input.loadingCountryCodes = new List<String>{ 'NL' };
        input.deliveryCountryCodes = new List<String>{ 'FR;DE' };
        
        Test.startTest();
        List<TPQGetLanesToAddInPriceRequest.Response> response = TPQGetLanesToAddInPriceRequest.addLanesToPriceRequest(
            new List<TPQGetLanesToAddInPriceRequest.Input>{ input }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        
        Set<Id> returnedLaneIds = new Set<Id>();
        for (Product2 lane : response[0].matchingLanes) {
            returnedLaneIds.add(lane.Id);
        }
        
        Assert.isFalse(returnedLaneIds.contains(existingLane.Id), 'Should exclude existing lane (NL-FR)');
        Assert.areEqual(1, response[0].matchingLanes.size(), 'Should only return NL-DE Lane');
    }
}