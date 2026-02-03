@isTest
private class TPQAddLanesToPriceRequestActionTest {
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
            )
        };
        insert locations;
        
        List<Product2> lanes = new List<Product2>{
            new Product2(
                Name = 'NL-FR Lane',
                Loading_Location__c = locations[0].Id,
                Destination_Location__c = locations[1].Id,
                IsActive = true
            ),
            new Product2(
                Name = 'NL-DE Lane',
                Loading_Location__c = locations[0].Id,
                Destination_Location__c = locations[2].Id,
                IsActive = true
            )
        };
        insert lanes;
        
        Price_Request__c priceRequest = new Price_Request__c(
            Name = 'Test Price Request',
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received',
            CurrencyIsoCode = 'EUR'
        );
        insert priceRequest;
    }
    
    @isTest
    static void testAddLanesWithMultipleTrailerTypes() {
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        List<Product2> lanes = [SELECT Id FROM Product2];
        
        List<String> laneIds = new List<String>();
        for (Product2 lane : lanes) {
            laneIds.add(lane.Id);
        }
        
        TPQAddLanesToPriceRequestAction.Input input = new TPQAddLanesToPriceRequestAction.Input();
        input.priceRequestId = priceRequest.Id;
        input.filteredLaneIds = laneIds;
        input.mandatoryLaneIds = new List<String>{ lanes[0].Id };
        input.trailerTypesString = 'Dual temp;Frigo - chilled';
        
        Test.startTest();
        TPQAddLanesToPriceRequestAction.addLanesToPriceRequest(
            new List<TPQAddLanesToPriceRequestAction.Input>{ input }
        );
        Test.stopTest();
        
        List<Lane_Price__c> lanePrices = [
            SELECT Id, Lane__c, Type_Of_Trailer__c, Mandatory__c, CurrencyIsoCode, Price_Request__c
            FROM Lane_Price__c
            WHERE Price_Request__c = :priceRequest.Id
        ];
        
        Assert.areEqual(4, lanePrices.size(), 'Should create 4 lane prices (2 lanes x 2 trailer types)');
        
        Integer mandatoryCount = 0;
        Integer nonMandatoryCount = 0;
        Set<String> trailerTypes = new Set<String>();
        
        for (Lane_Price__c lp : lanePrices) {
            Assert.areEqual(priceRequest.Id, lp.Price_Request__c, 'Should be linked to price request');
            Assert.areEqual('EUR', lp.CurrencyIsoCode, 'Should have EUR currency');
            Assert.isNotNull(lp.Type_Of_Trailer__c, 'Should have trailer type');
            trailerTypes.add(lp.Type_Of_Trailer__c);
            
            if (lp.Lane__c == lanes[0].Id) {
                Assert.isTrue(lp.Mandatory__c, 'First lane should be mandatory');
                mandatoryCount++;
            } else {
                Assert.isFalse(lp.Mandatory__c, 'Second lane should not be mandatory');
                nonMandatoryCount++;
            }
        }
        
        Assert.areEqual(2, mandatoryCount, 'Should have 2 mandatory lane prices');
        Assert.areEqual(2, nonMandatoryCount, 'Should have 2 non-mandatory lane prices');
        Assert.isTrue(trailerTypes.contains('Dual temp'), 'Should contain Dual temp');
        Assert.isTrue(trailerTypes.contains('Frigo - chilled'), 'Should contain Frigo - chilled');
    }
    
    @isTest
    static void testAddLanesWithoutTrailerTypes() {
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        List<Product2> lanes = [SELECT Id FROM Product2 ORDER BY Name LIMIT 1];
        
        TPQAddLanesToPriceRequestAction.Input input = new TPQAddLanesToPriceRequestAction.Input();
        input.priceRequestId = priceRequest.Id;
        input.filteredLaneIds = new List<String>{ lanes[0].Id };
        input.mandatoryLaneIds = new List<String>{ lanes[0].Id };
        input.trailerTypesString = '';
        
        Test.startTest();
        TPQAddLanesToPriceRequestAction.addLanesToPriceRequest(
            new List<TPQAddLanesToPriceRequestAction.Input>{ input }
        );
        Test.stopTest();
        
        List<Lane_Price__c> lanePrices = [
            SELECT Id, Type_Of_Trailer__c, Mandatory__c, CurrencyIsoCode
            FROM Lane_Price__c
            WHERE Price_Request__c = :priceRequest.Id
        ];
        
        Assert.areEqual(1, lanePrices.size(), 'Should create 1 lane price');
        Assert.isNull(lanePrices[0].Type_Of_Trailer__c, 'Should not have trailer type');
        Assert.isTrue(lanePrices[0].Mandatory__c, 'Should be mandatory');
        Assert.areEqual('EUR', lanePrices[0].CurrencyIsoCode, 'Should have EUR currency');
    }
    
    @isTest
    static void testAddLanesWithAllMandatory() {
        Price_Request__c priceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        List<Product2> lanes = [SELECT Id FROM Product2];
        
        List<String> laneIds = new List<String>();
        for (Product2 lane : lanes) {
            laneIds.add(lane.Id);
        }
        
        TPQAddLanesToPriceRequestAction.Input input = new TPQAddLanesToPriceRequestAction.Input();
        input.priceRequestId = priceRequest.Id;
        input.filteredLaneIds = laneIds;
        input.mandatoryLaneIds = laneIds;
        input.trailerTypesString = 'Dual temp';
        
        Test.startTest();
        TPQAddLanesToPriceRequestAction.addLanesToPriceRequest(
            new List<TPQAddLanesToPriceRequestAction.Input>{ input }
        );
        Test.stopTest();
        
        List<Lane_Price__c> lanePrices = [
            SELECT Id, Mandatory__c
            FROM Lane_Price__c
            WHERE Price_Request__c = :priceRequest.Id
        ];
        
        Assert.areEqual(2, lanePrices.size(), 'Should create 2 lane prices');
        
        for (Lane_Price__c lp : lanePrices) {
            Assert.isTrue(lp.Mandatory__c, 'All lanes should be mandatory');
        }
    }
    
    @isTest
    static void testAddLanesWithInvalidInput() {
        Test.startTest();
        
        // Test null input list
        TPQAddLanesToPriceRequestAction.addLanesToPriceRequest(null);
        
        // Test empty input list
        TPQAddLanesToPriceRequestAction.addLanesToPriceRequest(
            new List<TPQAddLanesToPriceRequestAction.Input>()
        );
        
        Test.stopTest();
        
        // Verify no lane prices were created
        List<Lane_Price__c> lanePrices = [SELECT Id FROM Lane_Price__c];
        Assert.areEqual(0, lanePrices.size(), 'Should not create any lane prices with invalid input');
    }
    
    @isTest
    static void testAddLanesWithExceptionHandling() {
        TPQAddLanesToPriceRequestAction.Input input = new TPQAddLanesToPriceRequestAction.Input();
        input.priceRequestId = null;
        input.filteredLaneIds = new List<String>{ 'invalidId' };
        input.mandatoryLaneIds = new List<String>();
        input.trailerTypesString = 'Dual temp';
        
        Test.startTest();
        try {
            TPQAddLanesToPriceRequestAction.addLanesToPriceRequest(
                new List<TPQAddLanesToPriceRequestAction.Input>{ input }
            );
            Assert.fail('Should have thrown an exception');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }
}