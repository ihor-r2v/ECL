@isTest
private class LaneSelectorControllerTest {
    @TestSetup
    static void setupTestData() {
        
        Account testAccount = new Account(
            Name = 'Test Carrier Account',
            Type = 'Carrier',
            Destination_Country_Codes__c = 'FR;DE;NL',
            Fuel_surcharge_percentage__c = 5.0,
            Diesel_mark_up_Price__c = 10.0,
            ETS__c = 15.0,
            Plug_in__c = 20.0,
            Harbour_Dues__c = 25.0,
            Overnight_charges_Price__c = 45.0,
            Waiting_Hour__c = 30.0,
            Seasonal_Surcharge__c = 40.0,
            Weekend_Charges__c = 35.0,
            Dangerous_Goods_Price__c = 50.0,
            Pallet_Exchange_Price__c = 55.0,
            Tail_Lift_Price__c = 60.0,
            Pallet_Jack_Price__c = 65.0,
            Price_Ferry__c = 70.0,
            Price_2nd_Driver__c = 75.0,
            Price_Per_Stop__c = 80.0
        );
        
        Account testAccount2 = new Account(
            Name = 'Test Carrier Account 2',
            Type = 'Carrier',
            Destination_Country_Codes__c = 'FR;ES;IT',
            Fuel_surcharge_percentage__c = 6.0,
            Price_Per_Stop__c = 85.0
        );
        
        insert new List<Account>{testAccount, testAccount2};
        
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
            Destination_Location__c = deliveryLocation.Id
        );
        insert testLane;

        // Create Tender Season
        Season__c testSeason = new Season__c(
            Name = 'Test Season',
            Type__c = 'Tender',
            Status__c = 'Active',
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(30)
        );
        
        // Create Spot Season
        Season__c spotSeason = new Season__c(
            Name = 'Spot Season 2025',
            Type__c = 'Spot',
            Status__c = 'Active',
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(30)
        );
        
        insert new List<Season__c>{testSeason, spotSeason};
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received',
            Season__c = testSeason.Id,
            Type__c = 'Tender'
        );
        
        Price_Request__c spotPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received',
            Season__c = spotSeason.Id,
            Type__c = 'Spot'
        );
        
        insert new List<Price_Request__c>{testPriceRequest, spotPriceRequest};
        
        Lane_Price__c testLanePrice = new Lane_Price__c(
            Price_Request__c = testPriceRequest.Id,
            Lane__c = testLane.Id,
            Freight_Price__c = 1000,
            Type_Of_Trailer__c = 'Frigo - chilled',
            Additional_Stops__c = 100,
            Price_2nd_Driver__c = 200,
            Price_Ferry__c = 300,
            PreferredCarrier__c = false
        );
        
        Lane_Price__c spotLanePrice = new Lane_Price__c(
            Price_Request__c = spotPriceRequest.Id,
            Lane__c = testLane.Id,
            Freight_Price__c = 1200,
            Type_Of_Trailer__c = 'Frigo - chilled',
            PreferredCarrier__c = true
        );
        
        insert new List<Lane_Price__c>{testLanePrice, spotLanePrice};

        Carrier_Score__c testCarrierScore = new Carrier_Score__c(
            Carrier__c = testAccount.Id,
            Reliability_Score__c = 95.5,
            Availability_Score_Percentage__c = 88.0,
            Price_Level_Percentage__c = 75.0
        );
        insert testCarrierScore;
        
        // Create opportunity and line item for delete tests
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testLane.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert oli;
    }

    @isTest
    static void testGetLocationsAndSeasons() {
        Test.startTest();
        List<Location__c> locations = LaneSelectorController.getLocations();
        List<Season__c> seasons = LaneSelectorController.getSeasons();
        List<Season__c> spotSeasons = LaneSelectorController.getSpotSeasons();
        List<Season__c> tenderSeasons = LaneSelectorController.getTenderSeasons();
        Test.stopTest();
        
        Assert.areEqual(2, locations.size(), 'Should return 2 locations');
        Assert.areEqual(2, seasons.size(), 'Should return 2 active seasons');
        Assert.areEqual(1, spotSeasons.size(), 'Should return 1 spot season');
        Assert.areEqual(1, tenderSeasons.size(), 'Should return 1 tender season');
        Assert.areEqual('Active', seasons[0].Status__c, 'Season should be active');
    }

    @isTest
    static void testGetMatchingAccountsAndTrailerTypes() {
        Location__c loadingLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Loading' LIMIT 1];
        Location__c deliveryLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Delivery' LIMIT 1];
        
        Test.startTest();
        List<Account> accounts = LaneSelectorController.getMatchingAccounts(loadingLocation.Id, deliveryLocation.Id);
        List<String> trailerTypes = LaneSelectorController.getTrailerTypePicklistValues();
        Test.stopTest();
        
        Assert.areEqual(2, accounts.size(), 'Should return 2 accounts');
        Assert.isTrue(trailerTypes.size() > 0, 'Should return trailer types');
    }

    @isTest
    static void testGetMatchingLanes() {
        Location__c loadingLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Loading' LIMIT 1];
        Location__c deliveryLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Delivery' LIMIT 1];
        Season__c testSeason = [SELECT Id FROM Season__c WHERE Type__c = 'Tender' LIMIT 1];
        
        Test.startTest();
        List<LaneSelectorController.LaneResult> results = LaneSelectorController.getMatchingLanes(
            loadingLocation.Id, 
            deliveryLocation.Id, 
            testSeason.Id,
            'Frigo - chilled'
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return 1 lane result');
        LaneSelectorController.LaneResult result = results[0];
        Assert.isNotNull(result.accountId, 'Account ID should not be null');
        Assert.areEqual('Test Lane DE-FR', result.laneName, 'Lane name should match');
        Assert.areEqual(1, result.trailerTypes.size(), 'Should have 1 trailer type');
        Assert.areEqual(1, result.accountScores.size(), 'Should have 1 account score');
        Assert.areEqual(96, result.accountScores[0].reliabilityScore, 'Reliability score should match');
        Assert.isFalse(result.preferredCarrier, 'Should not be preferred carrier initially');
    }

    @isTest
    static void testCreateAndUpdatePreferredSupplier() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Carrier Account' LIMIT 1];
        Lane_Price__c testLanePrice = [SELECT Id FROM Lane_Price__c WHERE Freight_Price__c = 1000 LIMIT 1];
        Location__c loadingLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Loading' LIMIT 1];
        Location__c deliveryLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Delivery' LIMIT 1];
        Season__c testSeason = [SELECT Id FROM Season__c WHERE Type__c = 'Tender' LIMIT 1];
        
        Test.startTest();
        // Create first preferred supplier
        LaneSelectorController.createPreferredSupplier(
            testAccount.Id,
            testLanePrice.Id,
            loadingLocation.Id,
            deliveryLocation.Id,
            'Frigo - chilled',
            1345.5,
            testSeason.Id,
            '{}'
        );
        
        // Create second preferred supplier (should replace first)
        LaneSelectorController.createPreferredSupplier(
            testAccount.Id,
            testLanePrice.Id,
            loadingLocation.Id,
            deliveryLocation.Id,
            'Frigo - chilled',
            1500.0,
            testSeason.Id,
            '{}'
        );
        Test.stopTest();
        
        List<Preferred_Supplier__c> preferredSuppliers = [
            SELECT Id, Total_Freight_Price__c
            FROM Preferred_Supplier__c
            WHERE Account__c = :testAccount.Id
        ];
        
        List<Lane_Price__c> lanePrices = [
            SELECT Id, PreferredCarrier__c
            FROM Lane_Price__c
            WHERE Id = :testLanePrice.Id
        ];
        
        Assert.areEqual(1, preferredSuppliers.size(), 'Should have only 1 preferred supplier');
        Assert.areEqual(1500.0, preferredSuppliers[0].Total_Freight_Price__c, 'Should have updated price');
        Assert.isTrue(lanePrices[0].PreferredCarrier__c, 'Lane price should be marked as preferred');
    }

    @isTest
    static void testCreatePriceRequests() {
        delete [SELECT Id FROM Price_Request__c];
        Account testAccount1 = [SELECT Id, Name FROM Account WHERE Name = 'Test Carrier Account' LIMIT 1];
        Account testAccount2 = [SELECT Id, Name FROM Account WHERE Name = 'Test Carrier Account 2' LIMIT 1];
        Location__c loadingLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Loading' LIMIT 1];
        Location__c deliveryLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Delivery' LIMIT 1];
        Season__c spotSeason = [SELECT Id, Name FROM Season__c WHERE Type__c = 'Spot' LIMIT 1];
        
        List<String> accountIds = new List<String>{testAccount1.Id, testAccount2.Id};
        
        Test.startTest();
        LaneSelectorController.createPriceRequests(
            accountIds,
            spotSeason.Id,
            'Frigo - chilled',
            loadingLocation.Id,
            deliveryLocation.Id
        );
        Test.stopTest();
        
        // Verify Price Requests created
        List<Price_Request__c> createdPriceRequests = [
            SELECT Id, Name, Account__c, Season__c, Type__c, Request_Date__c, Show_Additional_Information__c
            FROM Price_Request__c
            WHERE Account__c IN :accountIds
                AND Season__c = :spotSeason.Id
                AND Type__c = 'Spot'
        ];
        
        Assert.areEqual(2, createdPriceRequests.size(), 'Should create 2 price requests');
        Assert.areEqual(Date.today(), createdPriceRequests[0].Request_Date__c, 'Request date should be today');
        Assert.isTrue(createdPriceRequests[0].Show_Additional_Information__c, 'Should show additional information');
        
        // Verify Lane Prices created
        List<Lane_Price__c> createdLanePrices = [
            SELECT Id, Price_Request__c, Type_Of_Trailer__c, Mandatory__c
            FROM Lane_Price__c
            WHERE Price_Request__c IN :createdPriceRequests
        ];
        
        Assert.areEqual(2, createdLanePrices.size(), 'Should create 2 lane prices');
        Assert.areEqual('Frigo - chilled', createdLanePrices[0].Type_Of_Trailer__c, 'Trailer type should match');
        Assert.isTrue(createdLanePrices[0].Mandatory__c, 'Lane price should be mandatory');
    }

    @isTest
    static void testGetCarriersForSpotPrice() {
        Location__c loadingLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Loading' LIMIT 1];
        Location__c deliveryLocation = [SELECT Id, Country_Code__c FROM Location__c WHERE Type__c = 'Delivery' LIMIT 1];
        Season__c spotSeason = [SELECT Id FROM Season__c WHERE Type__c = 'Spot' LIMIT 1];
        
        Test.startTest();
        LaneSelectorController.SpotPriceResult result = LaneSelectorController.getCarriersForSpotPrice(
            deliveryLocation.Country_Code__c,
            spotSeason.Id,
            'Frigo - chilled',
            loadingLocation.Id,
            deliveryLocation.Id
        );
        Test.stopTest();
        
        // Verify available prices
        Assert.isNotNull(result.availablePrices, 'Available prices should not be null');
        Assert.areEqual(1, result.availablePrices.size(), 'Should return 1 available price');
        
        LaneSelectorController.LaneResult laneResult = result.availablePrices[0];
        Assert.isNotNull(laneResult.accountId, 'Account ID should not be null');
        Assert.areEqual('Test Lane DE-FR', laneResult.laneName, 'Lane name should match');
        Assert.areEqual(1200, laneResult.lanePrice, 'Lane price should be 1200');
        Assert.isTrue(laneResult.preferredCarrier, 'Should be preferred carrier');
        Assert.isNotNull(laneResult.fuelSurchargePercentage, 'Fuel surcharge should not be null');
        Assert.isNotNull(laneResult.pricePerStop, 'Price per stop should not be null');
        
        // Verify potential carriers (carriers without lane prices)
        Assert.isNotNull(result.potentialCarriers, 'Potential carriers should not be null');
        Assert.areEqual(1, result.potentialCarriers.size(), 'Should return 1 potential carrier');
        
        LaneSelectorController.CarrierResult carrierResult = result.potentialCarriers[0];
        Assert.areEqual('Test Carrier Account 2', carrierResult.accountName, 'Carrier name should match');
        Assert.areEqual('Carrier', carrierResult.type, 'Type should be Carrier');
        Assert.isTrue(carrierResult.destinationCountries.contains('FR'), 'Should support FR destination');
    }

    @isTest
    static void testGetCarriersForSpotPriceNoLane() {
        Location__c loadingLocation = new Location__c(
            Name = 'New Loading Location',
            Type__c = 'Loading',
            Country_Code__c = 'ES',
            Postal_Code__c = '28001'
        );
        
        Location__c deliveryLocation = new Location__c(
            Name = 'New Delivery Location',
            Type__c = 'Delivery',
            Country_Code__c = 'IT',
            Postal_Code__c = '00100'
        );
        
        insert new List<Location__c>{loadingLocation, deliveryLocation};
        
        Season__c spotSeason = [SELECT Id FROM Season__c WHERE Type__c = 'Spot' LIMIT 1];
        
        Test.startTest();
        LaneSelectorController.SpotPriceResult result = LaneSelectorController.getCarriersForSpotPrice(
            deliveryLocation.Country_Code__c,
            spotSeason.Id,
            'Frigo - chilled',
            loadingLocation.Id,
            deliveryLocation.Id
        );
        Test.stopTest();
        
        Assert.areEqual(0, result.availablePrices.size(), 'Should return 0 available prices');
        Assert.areEqual(0, result.potentialCarriers.size(), 'Should return 0 potential carriers');
    }

    @isTest
    static void testDeleteLocations() {
        Location__c loadingLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Loading' LIMIT 1];
        Location__c deliveryLocation = [SELECT Id FROM Location__c WHERE Type__c = 'Delivery' LIMIT 1];
        
        // Create additional location without products
        Location__c newLocation = new Location__c(
            Name = 'New Location',
            Type__c = 'Loading',
            Country_Code__c = 'GB',
            Postal_Code__c = '11111'
        );
        insert newLocation;
        
        Test.startTest();
        // Delete loading location with products and opportunity line items
        LaneSelectorController.deleteLocation(loadingLocation.Id, 'Loading');
        // Delete delivery location
        LaneSelectorController.deleteLocation(deliveryLocation.Id, 'Delivery');
        // Delete location without products
        LaneSelectorController.deleteLocation(newLocation.Id, 'Loading');
        Test.stopTest();
        
        List<Location__c> remainingLocations = [SELECT Id FROM Location__c];
        List<Product2> remainingProducts = [SELECT Id FROM Product2];
        List<OpportunityLineItem> remainingOLIs = [SELECT Id FROM OpportunityLineItem];
        
        Assert.areEqual(0, remainingLocations.size(), 'All locations should be deleted');
        Assert.areEqual(0, remainingProducts.size(), 'All products should be deleted');
        Assert.areEqual(0, remainingOLIs.size(), 'All opportunity line items should be deleted');
    }

    @isTest
    static void testGetDeliveryLocations() {
        Test.startTest();
        List<Location__c> deliveryResults = LaneSelectorController.getDeliveryLocations('Delivery', 'Delivery Test');
        List<Location__c> loadingResults = LaneSelectorController.getDeliveryLocations('Loading', 'Loading');
        List<Location__c> noResults = LaneSelectorController.getDeliveryLocations('Loading', 'NonExistent');
        Test.stopTest();
        
        Assert.areEqual(1, deliveryResults.size(), 'Should return 1 delivery location');
        Assert.areEqual(1, loadingResults.size(), 'Should return 1 loading location');
        Assert.areEqual(0, noResults.size(), 'Should return 0 for non-existent');
    }

    @isTest
    static void testExceptionHandling() {
        Test.startTest();
        try {
            LaneSelectorController.deleteLocation(null, 'Loading');
            Assert.fail('Should throw exception for null location');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Error message should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testWrapperClasses() {
        // Test LaneResult
        LaneSelectorController.LaneResult result = new LaneSelectorController.LaneResult();
        result.accountId = 'testId';
        result.laneName = 'Test Lane';
        result.preferredCarrier = true;
        
        // Test TrailerType
        LaneSelectorController.TrailerType trailer = new LaneSelectorController.TrailerType();
        trailer.laneId = 'laneId';
        trailer.type = 'Frigo - chilled';
        trailer.price = 1000.0;
        
        // Test AccountScore
        LaneSelectorController.AccountScore score = new LaneSelectorController.AccountScore();
        score.reliabilityScore = 95.0;
        score.priceScore = 75.0;
        score.availabilityScore = 88.0;
        
        // Test SpotPriceResult
        LaneSelectorController.SpotPriceResult spotResult = new LaneSelectorController.SpotPriceResult();
        spotResult.potentialCarriers = new List<LaneSelectorController.CarrierResult>();
        spotResult.availablePrices = new List<LaneSelectorController.LaneResult>();
        
        // Test CarrierResult
        LaneSelectorController.CarrierResult carrier = new LaneSelectorController.CarrierResult();
        carrier.accountId = 'carrierId';
        carrier.accountName = 'Test Carrier';
        carrier.type = 'Carrier';
        carrier.destinationCountries = 'FR;DE';
        
        Assert.areEqual('testId', result.accountId, 'Account ID should match');
        Assert.isTrue(result.preferredCarrier, 'Should be preferred carrier');
        Assert.areEqual('Frigo - chilled', trailer.type, 'Trailer type should match');
        Assert.areEqual(95.0, score.reliabilityScore, 'Score should match');
        Assert.isNotNull(spotResult.potentialCarriers, 'Potential carriers should not be null');
        Assert.areEqual('Test Carrier', carrier.accountName, 'Carrier name should match');
    }
}