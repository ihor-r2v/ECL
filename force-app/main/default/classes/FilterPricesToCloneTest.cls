@isTest
private class FilterPricesToCloneTest {

    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Original Carrier Account',
                Type = 'Carrier',
                Trailer_Types__c = 'Dual temp;Frigo - chilled',
                Destination_Country_Codes__c = 'NL;DE;ES',
                Access_code__c = 'NMMNBB6778'
            ),
            new Account(
                Name = 'Target Carrier Account',
                Type = 'Carrier',
                Trailer_Types__c = 'Dual temp;Frigo - frozen',
                Destination_Country_Codes__c = 'NL;DE',
                Access_code__c = 'NMMNBB6323'
            ),
            new Account(
                Name = 'Empty Account',
                Type = 'Carrier',
                Trailer_Types__c = null,
                Destination_Country_Codes__c = null,
                Access_code__c = 'NMMNBB6234'
            )
        };
        insert accounts;
        
        List<Location__c> locations = new List<Location__c>{
            new Location__c(
                Name = 'NL Location',
                Type__c = 'Delivery',
                Country_Code__c = 'NL',
                Postal_Code__c = '1234AB'
            ),
            new Location__c(
                Name = 'DE Location',
                Type__c = 'Delivery',
                Country_Code__c = 'DE',
                Postal_Code__c = '12345'
            ),
            new Location__c(
                Name = 'ES Location',
                Type__c = 'Delivery',
                Country_Code__c = 'ES',
                Postal_Code__c = '28001'
            )
        };
        insert locations;
        
        List<Product2> lanes = new List<Product2>{
            new Product2(
                Name = 'NL Lane',
                Destination_Location__c = locations[0].Id,
                IsActive = true
            ),
            new Product2(
                Name = 'DE Lane',
                Destination_Location__c = locations[1].Id,
                IsActive = true
            ),
            new Product2(
                Name = 'ES Lane',
                Destination_Location__c = locations[2].Id,
                IsActive = true
            )
        };
        insert lanes;
        
        Price_Request__c priceRequest = new Price_Request__c(
            Name = 'Test Price Request',
            Account__c = accounts[0].Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received'
        );
        insert priceRequest;
        
        List<Lane_Price__c> lanePrices = new List<Lane_Price__c>{
            new Lane_Price__c(
                Price_Request__c = priceRequest.Id,
                Lane__c = lanes[0].Id,
                Type_Of_Trailer__c = 'Dual temp',
                Freight_Price__c = 1000,
                Mandatory__c = true,
                CurrencyIsoCode = 'EUR'
            ),
            new Lane_Price__c(
                Price_Request__c = priceRequest.Id,
                Lane__c = lanes[1].Id,
                Type_Of_Trailer__c = 'Dual temp',
                Freight_Price__c = 1200,
                Mandatory__c = false,
                CurrencyIsoCode = 'EUR'
            ),
            new Lane_Price__c(
                Price_Request__c = priceRequest.Id,
                Lane__c = lanes[2].Id,
                Type_Of_Trailer__c = 'Dual temp',
                Freight_Price__c = 950,
                Mandatory__c = false,
                CurrencyIsoCode = 'EUR'
            ),
            new Lane_Price__c(
                Price_Request__c = priceRequest.Id,
                Lane__c = lanes[0].Id,
                Type_Of_Trailer__c = 'Frigo - chilled',
                Freight_Price__c = 1100,
                Mandatory__c = true,
                CurrencyIsoCode = 'EUR'
            ),
            new Lane_Price__c(
                Price_Request__c = priceRequest.Id,
                Lane__c = lanes[0].Id,
                Type_Of_Trailer__c = 'Frigo - frozen',
                Freight_Price__c = 1300,
                Mandatory__c = false,
                CurrencyIsoCode = 'EUR'
            )
        };
        insert lanePrices;
    }
    
    @isTest
    static void testFilterPricesWithMatchingCriteria() {
        Account originalAccount = [SELECT Id FROM Account WHERE Name = 'Original Carrier Account' LIMIT 1];
        Account targetAccount = [SELECT Id FROM Account WHERE Name = 'Target Carrier Account' LIMIT 1];
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        FilterPricesToClone.Request request = new FilterPricesToClone.Request();
        request.targetAccountId = targetAccount.Id;
        request.originalAccountId = originalAccount.Id;
        request.originalPriceRequestId = priceRequest.Id;
        
        Test.startTest();
        List<FilterPricesToClone.Response> response = FilterPricesToClone.filterPrices(
            new List<FilterPricesToClone.Request>{ request }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.areEqual(5, response[0].originalPricesCount, 'Should have 5 original prices');
        Assert.areEqual(3, response[0].targetPricesCount, 'Should have 3 matching prices');
        Assert.areEqual(3, response[0].lanePriceIdsForCloning.size(), 'Should return 3 IDs for cloning');
        Assert.isTrue(response[0].originalDestinationCodes.contains('NL'), 'Should contain NL');
        Assert.isTrue(response[0].originalDestinationCodes.contains('DE'), 'Should contain DE');
        Assert.isTrue(response[0].originalTrailerTypes.contains('Dual temp'), 'Should contain Dual temp');
        Assert.isTrue(response[0].originalTrailerTypes.contains('Frigo - chilled'), 'Should contain Frigo - chilled');
    }
    
    @isTest
    static void testFilterPricesWithNoMatchingCriteria() {
        Account originalAccount = [SELECT Id FROM Account WHERE Name = 'Original Carrier Account' LIMIT 1];
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        Account noMatchAccount = new Account(
            Name = 'No Match Account',
            Type = 'Carrier',
            Trailer_Types__c = 'Box trailer',
            Destination_Country_Codes__c = 'GB;FR',
            Access_code__c = 'NMMNBB9999'
        );
        insert noMatchAccount;
        
        FilterPricesToClone.Request request = new FilterPricesToClone.Request();
        request.targetAccountId = noMatchAccount.Id;
        request.originalAccountId = originalAccount.Id;
        request.originalPriceRequestId = priceRequest.Id;
        
        Test.startTest();
        List<FilterPricesToClone.Response> response = FilterPricesToClone.filterPrices(
            new List<FilterPricesToClone.Request>{ request }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.areEqual(5, response[0].originalPricesCount, 'Should have 5 original prices');
        Assert.areEqual(0, response[0].targetPricesCount, 'Should have 0 matching prices');
        Assert.areEqual(0, response[0].lanePriceIdsForCloning.size(), 'Should return empty IDs list');
    }
    
    @isTest
    static void testFilterPricesWithEmptyAccountPicklists() {
        Account originalAccount = [SELECT Id FROM Account WHERE Name = 'Original Carrier Account' LIMIT 1];
        Account emptyAccount = [SELECT Id FROM Account WHERE Name = 'Empty Account' LIMIT 1];
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        FilterPricesToClone.Request request = new FilterPricesToClone.Request();
        request.targetAccountId = emptyAccount.Id;
        request.originalAccountId = originalAccount.Id;
        request.originalPriceRequestId = priceRequest.Id;
        
        Test.startTest();
        List<FilterPricesToClone.Response> response = FilterPricesToClone.filterPrices(
            new List<FilterPricesToClone.Request>{ request }
        );
        Test.stopTest();
        
        Assert.areEqual(0, response.size(), 'Should return empty when target account has empty picklists');
    }
    
    @isTest
    static void testFilterPricesWithInvalidInput() {
        Account originalAccount = [SELECT Id FROM Account WHERE Name = 'Original Carrier Account' LIMIT 1];
        Account targetAccount = [SELECT Id FROM Account WHERE Name = 'Target Carrier Account' LIMIT 1];
        
        Test.startTest();
        
        // Test null request list
        List<FilterPricesToClone.Response> nullResponse = FilterPricesToClone.filterPrices(null);
        Assert.areEqual(0, nullResponse.size(), 'Should handle null request');
        
        // Test empty request list
        List<FilterPricesToClone.Response> emptyResponse = FilterPricesToClone.filterPrices(
            new List<FilterPricesToClone.Request>()
        );
        Assert.areEqual(0, emptyResponse.size(), 'Should handle empty request list');
        
        // Test price request with no lane prices
        Price_Request__c emptyPriceRequest = new Price_Request__c(
            Name = 'Empty Price Request',
            Account__c = originalAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'New'
        );
        insert emptyPriceRequest;
        
        FilterPricesToClone.Request noLanesRequest = new FilterPricesToClone.Request();
        noLanesRequest.targetAccountId = targetAccount.Id;
        noLanesRequest.originalAccountId = originalAccount.Id;
        noLanesRequest.originalPriceRequestId = emptyPriceRequest.Id;
        
        List<FilterPricesToClone.Response> noLanesResponse = FilterPricesToClone.filterPrices(
            new List<FilterPricesToClone.Request>{ noLanesRequest }
        );
        Assert.areEqual(0, noLanesResponse.size(), 'Should return empty when no lane prices exist');
        
        Test.stopTest();
    }
}