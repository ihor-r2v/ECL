@isTest
private class ClonePriceRequestActionTest {

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
            )
        };
        insert accounts;
        
        Season__c season = new Season__c(
            Name = 'Transportation Summer'
        );
        insert season;
        
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
            )
        };
        insert lanes;
        
        Price_Request__c priceRequest = new Price_Request__c(
            Name = 'Test Price Request',
            Account__c = accounts[0].Id,
            Season__c = season.Id,
            Request_Date__c = Date.today().addDays(-10),
            Stage__c = 'Answer received',
            CurrencyIsoCode = 'EUR',
            Fuel_surcharge_percentage__c = true,
            Additional_stops__c = true
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
                Lane__c = lanes[0].Id,
                Type_Of_Trailer__c = 'Frigo - chilled',
                Freight_Price__c = 1100,
                Mandatory__c = true,
                CurrencyIsoCode = 'EUR'
            )
        };
        insert lanePrices;
    }
    
    @isTest
    static void testSuccessfulCloneWithMatchingLanePrices() {
        Account targetAccount = [SELECT Id FROM Account WHERE Name = 'Target Carrier Account' LIMIT 1];
        Price_Request__c originalPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        List<Lane_Price__c> lanePrices = [SELECT Id FROM Lane_Price__c WHERE Type_Of_Trailer__c = 'Dual temp'];
        
        List<Id> lanePriceIds = new List<Id>();
        for (Lane_Price__c lp : lanePrices) {
            lanePriceIds.add(lp.Id);
        }
        
        ClonePriceRequestAction.Request request = new ClonePriceRequestAction.Request();
        request.originalPriceRequestId = originalPriceRequest.Id;
        request.targetAccountId = targetAccount.Id;
        request.matchingLanePrices = lanePriceIds;
        
        Test.startTest();
        List<ClonePriceRequestAction.Response> response = ClonePriceRequestAction.createPriceRequest(
            new List<ClonePriceRequestAction.Request>{ request }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.isNotNull(response[0].clonedPriceRequestId, 'Cloned price request ID should not be null');
        Assert.isNull(response[0].errorMessage, 'Error message should be null');
        
        Price_Request__c clonedPriceRequest = [
            SELECT Id, Name, Account__c, Stage__c, Request_Date__c, Season__c, Type__c, Fuel_surcharge_percentage__c, Additional_stops__c
            FROM Price_Request__c 
            WHERE Id = :response[0].clonedPriceRequestId
        ];
        
        Assert.areEqual(targetAccount.Id, clonedPriceRequest.Account__c, 'Should be linked to target account');
        Assert.areEqual('Answer pending', clonedPriceRequest.Stage__c, 'Stage should be Answer pending');
        Assert.areEqual(Date.today(), clonedPriceRequest.Request_Date__c, 'Request date should be today');
        Assert.isTrue(clonedPriceRequest.Name.contains('Transportation Summer'), 'Name should contain season name');
        Assert.isTrue(clonedPriceRequest.Name.contains('Target Carrier Account'), 'Name should contain account name');
        Assert.isNotNull(clonedPriceRequest.Season__c, 'Season should be copied');
        Assert.areEqual(true, clonedPriceRequest.Fuel_surcharge_percentage__c, 'Fuel_surcharge_percentage__c should be copied');
        Assert.areEqual(true, clonedPriceRequest.Additional_stops__c, 'Additional_stops__c should be copied');
        
        List<Lane_Price__c> clonedLanePrices = [
            SELECT Id, Price_Request__c, Lane__c, Type_Of_Trailer__c, Freight_Price__c, Mandatory__c
            FROM Lane_Price__c 
            WHERE Price_Request__c = :response[0].clonedPriceRequestId
        ];
        
        Assert.areEqual(2, clonedLanePrices.size(), 'Should have 2 cloned lane prices');
        for (Lane_Price__c clonedLp : clonedLanePrices) {
            Assert.areEqual(response[0].clonedPriceRequestId, clonedLp.Price_Request__c, 'Should be linked to cloned price request');
            Assert.isNull(clonedLp.Freight_Price__c, 'Freight price should be null');
            Assert.isNotNull(clonedLp.Lane__c, 'Lane should be copied');
            Assert.isNotNull(clonedLp.Type_Of_Trailer__c, 'Type of trailer should be copied');
        }
    }
    
    @isTest
    static void testCloneWithEmptyLanePricesList() {
        Account targetAccount = [SELECT Id FROM Account WHERE Name = 'Target Carrier Account' LIMIT 1];
        Price_Request__c originalPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        ClonePriceRequestAction.Request request = new ClonePriceRequestAction.Request();
        request.originalPriceRequestId = originalPriceRequest.Id;
        request.targetAccountId = targetAccount.Id;
        request.matchingLanePrices = new List<Id>();
        
        Test.startTest();
        List<ClonePriceRequestAction.Response> response = ClonePriceRequestAction.createPriceRequest(
            new List<ClonePriceRequestAction.Request>{ request }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.isNotNull(response[0].clonedPriceRequestId, 'Cloned price request ID should not be null');
        Assert.isNull(response[0].errorMessage, 'Error message should be null');
        
        List<Lane_Price__c> clonedLanePrices = [
            SELECT Id 
            FROM Lane_Price__c 
            WHERE Price_Request__c = :response[0].clonedPriceRequestId
        ];
        
        Assert.areEqual(0, clonedLanePrices.size(), 'Should have 0 cloned lane prices');
    }
    
    @isTest
    static void testCloneWithInvalidInput() {
        Test.startTest();
        
        // Test null request list
        List<ClonePriceRequestAction.Response> nullResponse = ClonePriceRequestAction.createPriceRequest(null);
        Assert.areEqual(0, nullResponse.size(), 'Should handle null request');
        
        // Test empty request list
        List<ClonePriceRequestAction.Response> emptyResponse = ClonePriceRequestAction.createPriceRequest(
            new List<ClonePriceRequestAction.Request>()
        );
        Assert.areEqual(0, emptyResponse.size(), 'Should handle empty request list');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCloneWithInvalidAccountId() {
        Price_Request__c originalPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        List<Lane_Price__c> lanePrices = [SELECT Id FROM Lane_Price__c LIMIT 1];
        
        ClonePriceRequestAction.Request request = new ClonePriceRequestAction.Request();
        request.originalPriceRequestId = originalPriceRequest.Id;
        request.targetAccountId = null;
        request.matchingLanePrices = new List<Id>{ lanePrices[0].Id };
        
        Test.startTest();
        List<ClonePriceRequestAction.Response> response = ClonePriceRequestAction.createPriceRequest(
            new List<ClonePriceRequestAction.Request>{ request }
        );
        Test.stopTest();
        
        Assert.areEqual(1, response.size(), 'Should return one response');
        Assert.isNull(response[0].clonedPriceRequestId, 'Cloned price request ID should be null');
        Assert.isNotNull(response[0].errorMessage, 'Error message should not be null');
    }
}