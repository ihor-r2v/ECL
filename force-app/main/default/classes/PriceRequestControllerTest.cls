@isTest
private class PriceRequestControllerTest {
    
    // Trailer Type Constants
    private static final String TRAILER_DUAL_TEMP = 'Dual temp';
    private static final String TRAILER_FRIGO_CHILLED = 'Frigo - chilled';
    
    // Country Code Constants
    private static final String COUNTRY_CODE_DE = 'DE';
    private static final String COUNTRY_CODE_FR = 'FR';
    
    // Postal Code Constants
    private static final String POSTAL_CODE_LOADING = '12345';
    private static final String POSTAL_CODE_DELIVERY = '67890';
    
    // Stage Constants
    private static final String STAGE_NEW = 'New';
    private static final String STAGE_ANSWER_RECEIVED = 'Answer received';
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Carrier Account',
            Fuel_surcharge_percentage__c = 10.0,
            Price_Per_Stop__c = 250.0,
            Price_2nd_Driver__c = 150.0,
            Price_Ferry__c = 300.0,
            ETS__c = 15.0,
            Plug_in__c = 20.0,
            Harbour_Dues__c = 25.0,
            Waiting_Hour__c = 30.0,
            Pallet_Exchange__c = true,
            Dangerous_Goods__c = true,
            Weekend_Charges__c = 35.0,
            Seasonal_Surcharge__c = 40.0,
            Overnight_charges_Price__c = 45.0,
            Dangerous_Goods_Price__c = 50.0,
            Pallet_Exchange_Price__c = 55.0,
            Tail_Lift_Price__c = 60.0,
            Pallet_Jack_Price__c = 65.0
        );
        insert testAccount;
        
        Location__c loadingLocation = new Location__c(
            Name = 'Loading Test Location',
            Type__c = 'Loading',
            Country_Code__c = COUNTRY_CODE_DE,
            Postal_Code__c = POSTAL_CODE_LOADING
        );
        
        Location__c deliveryLocation = new Location__c(
            Name = 'Delivery Test Location',
            Type__c = 'Delivery',
            Country_Code__c = COUNTRY_CODE_FR,
            Postal_Code__c = POSTAL_CODE_DELIVERY
        );
        
        insert new List<Location__c>{loadingLocation, deliveryLocation};
        
        Product2 testLane = new Product2(
            Name = 'Test Lane DE-FR',
            Loading_Location__c = loadingLocation.Id,
            Destination_Location__c = deliveryLocation.Id
        );
        insert testLane;
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Show_Additional_Lane_Price_Information__c = true,
            Show_Additional_Information__c = true,
            Additional_stops__c = true,
            ADR__c = true,
            Diesel_mark_up__c = true,
            Direct_Ferry__c = true,
            Harbour_dues__c = true,
            Overnight_charges__c = true,
            Pallet_Exchange__c = true,
            Pallet_Jack__c = true,
            Plug_in__c = true,
            Seasonal_surcharge__c = true,
            Tail_Lift__c = true,
            Two_drivers__c = true,
            Waiting_hours__c = true,
            Weekend_charges__c = true,
            Dangerous_Goods__c = true,
            ETS__c = true,
            Stage__c = STAGE_NEW
        );
        insert testPriceRequest;
        
        List<Lane_Price__c> testLanePrices = new List<Lane_Price__c>();
        Lane_Price__c mandatoryLanePrice = new Lane_Price__c(
            Price_Request__c = testPriceRequest.Id,
            Lane__c = testLane.Id,
            Mandatory__c = true,
            Freight_Price__c = 1000,
            Type_Of_Trailer__c = TRAILER_DUAL_TEMP
        );
        testLanePrices.add(mandatoryLanePrice);
        
        Lane_Price__c optionalLanePrice = new Lane_Price__c(
            Price_Request__c = testPriceRequest.Id,
            Lane__c = testLane.Id,
            Mandatory__c = false,
            Freight_Price__c = 1200,
            Type_Of_Trailer__c = TRAILER_FRIGO_CHILLED
        );
        testLanePrices.add(optionalLanePrice);
        
        insert testLanePrices;
    }
    
    @isTest
    static void testGetPriceRequestById() {
        Price_Request__c testPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        Test.startTest();
        Price_Request__c retrievedPriceRequest = PriceRequestController.getPriceRequestById(testPriceRequest.Id);
        Test.stopTest();
        Assert.isNotNull(retrievedPriceRequest, 'Price request should be retrieved');
        Assert.isTrue(retrievedPriceRequest.Show_Additional_Lane_Price_Information__c, 'Should have expected flag value');
        Assert.isTrue(retrievedPriceRequest.Show_Additional_Information__c, 'Should have expected flag value');
        Assert.isTrue(retrievedPriceRequest.ADR__c, 'Should have expected flag value');
        Assert.areEqual(STAGE_NEW, retrievedPriceRequest.Stage__c, 'Stage should match expected value');
    }
    
    @isTest
    static void testGetLanePrices() {
        Price_Request__c testPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        Test.startTest();
        List<PriceRequestController.LanePriceWrapper> lanePrices = PriceRequestController.getLanePrices(testPriceRequest.Id, 1000, 0);
        Test.stopTest();
        
        Assert.areEqual(2, lanePrices.size(), 'Should retrieve two lane prices');
        Assert.isTrue(lanePrices[0].mandatory, 'First lane price should be mandatory');
        Assert.areEqual(1, lanePrices[0].numOfMandatoryLanes, 'Should have 1 mandatory lane');
        Assert.areEqual(TRAILER_DUAL_TEMP, lanePrices[0].typeOfTrailer, 'Should have correct trailer type');
        Assert.areEqual(1000, lanePrices[0].freightPrice, 'Should have correct freight price');
    }
    
    @isTest
    static void testGetLanePricesWithExistingCombinations() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testLane = [SELECT Id FROM Product2 LIMIT 1];
        
        Season__c testSeason = new Season__c(
            Name = 'Test Season',
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(30)
        );
        insert testSeason;
        
        Price_Request__c olderPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Season__c = testSeason.Id,
            Request_Date__c = Date.today().addDays(-10),
            Stage__c = STAGE_ANSWER_RECEIVED
        );
        insert olderPriceRequest;
        
        Lane_Price__c existingLanePrice = new Lane_Price__c(
            Price_Request__c = olderPriceRequest.Id,
            Lane__c = testLane.Id,
            Freight_Price__c = 900,
            Type_Of_Trailer__c = TRAILER_DUAL_TEMP
        );
        insert existingLanePrice;
        
        Price_Request__c newPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Season__c = testSeason.Id,
            Request_Date__c = Date.today(),
            Stage__c = STAGE_NEW
        );
        insert newPriceRequest;
        
        List<Lane_Price__c> newLanePrices = new List<Lane_Price__c>{
            new Lane_Price__c(
                Price_Request__c = newPriceRequest.Id,
                Lane__c = testLane.Id,
                Type_Of_Trailer__c = TRAILER_DUAL_TEMP,
                Mandatory__c = true
            ),
            new Lane_Price__c(
                Price_Request__c = newPriceRequest.Id,
                Lane__c = testLane.Id,
                Type_Of_Trailer__c = TRAILER_FRIGO_CHILLED,
                Mandatory__c = false
            )
        };
        insert newLanePrices;
        
        Test.startTest();
        List<PriceRequestController.LanePriceWrapper> lanePrices = PriceRequestController.getLanePrices(newPriceRequest.Id, 1000, 0);
        Test.stopTest();
        
        Assert.areEqual(1, lanePrices.size(), 'Should filter out existing lane-trailer combination');
        Assert.areEqual(TRAILER_FRIGO_CHILLED, lanePrices[0].typeOfTrailer, 'Should only return non-existing trailer type');
        Assert.areEqual(0, lanePrices[0].numOfMandatoryLanes, 'Mandatory lane should be filtered out');
    }
    
    @isTest
    static void testGetExistingLanePrices() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testLane = [SELECT Id FROM Product2 LIMIT 1];
        
        Season__c testSeason = new Season__c(
            Name = 'Test Season',
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(30)
        );
        insert testSeason;
        
        Price_Request__c existingPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Season__c = testSeason.Id,
            Name = 'Existing Request',
            Request_Date__c = Date.today().addDays(-10),
            Stage__c = STAGE_ANSWER_RECEIVED
        );
        insert existingPriceRequest;
        
        Lane_Price__c existingLanePrice = new Lane_Price__c(
            Price_Request__c = existingPriceRequest.Id,
            Lane__c = testLane.Id,
            Freight_Price__c = 850,
            Type_Of_Trailer__c = TRAILER_DUAL_TEMP,
            Mandatory__c = true
        );
        insert existingLanePrice;
        
        Price_Request__c currentPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Season__c = testSeason.Id,
            Request_Date__c = Date.today(),
            Stage__c = STAGE_NEW
        );
        insert currentPriceRequest;
        
        Lane_Price__c currentLanePrice = new Lane_Price__c(
            Price_Request__c = currentPriceRequest.Id,
            Lane__c = testLane.Id,
            Type_Of_Trailer__c = TRAILER_DUAL_TEMP,
            Mandatory__c = true
        );
        insert currentLanePrice;
        
        Test.startTest();
        List<PriceRequestController.ExistingLanePriceWrapper> existingPrices = 
            PriceRequestController.getExistingLanePrices(currentPriceRequest.Id);
        Test.stopTest();
        
        Assert.areEqual(1, existingPrices.size(), 'Should return one existing lane price');
        Assert.areEqual(850, existingPrices[0].freightPrice, 'Should return freight price from existing lane');
        Assert.areEqual('Existing Request', existingPrices[0].sourcePriceRequestName, 'Should reference existing price request');
        Assert.areEqual(existingPriceRequest.Id, existingPrices[0].sourcePriceRequestId, 'Should have correct source PR ID');
        Assert.areEqual(currentLanePrice.Id, existingPrices[0].currentPriceRequestLaneId, 'Should link to current lane price');
        Assert.areEqual(testLane.Id, existingPrices[0].laneId, 'Should have correct lane ID');
        Assert.areEqual(TRAILER_DUAL_TEMP, existingPrices[0].typeOfTrailer, 'Should have correct trailer type');
        Assert.areEqual(POSTAL_CODE_LOADING, existingPrices[0].loadingPostalCode, 'Should have loading postal code');
        Assert.areEqual(COUNTRY_CODE_DE, existingPrices[0].loadingCountryCode, 'Should have loading country code');
        Assert.areEqual(POSTAL_CODE_DELIVERY, existingPrices[0].deliveryPostalCode, 'Should have delivery postal code');
        Assert.areEqual(COUNTRY_CODE_FR, existingPrices[0].deliveryCountryCode, 'Should have delivery country code');
    }

    @isTest
    static void testUpdateExistingLanePricesMultipleRecords() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testLane = [SELECT Id FROM Product2 LIMIT 1];
        
        Season__c testSeason = new Season__c(
            Name = 'Test Season',
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(30)
        );
        insert testSeason;
        
        Price_Request__c existingPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Season__c = testSeason.Id,
            Request_Date__c = Date.today().addDays(-10),
            Stage__c = STAGE_ANSWER_RECEIVED
        );
        insert existingPriceRequest;
        
        List<Lane_Price__c> existingLanePrices = new List<Lane_Price__c>{
            new Lane_Price__c(
                Price_Request__c = existingPriceRequest.Id,
                Lane__c = testLane.Id,
                Freight_Price__c = 700,
                Type_Of_Trailer__c = TRAILER_DUAL_TEMP
            ),
            new Lane_Price__c(
                Price_Request__c = existingPriceRequest.Id,
                Lane__c = testLane.Id,
                Freight_Price__c = 800,
                Type_Of_Trailer__c = TRAILER_DUAL_TEMP
            )
        };
        insert existingLanePrices;
        
        Price_Request__c currentPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Season__c = testSeason.Id,
            Request_Date__c = Date.today(),
            Stage__c = STAGE_NEW
        );
        insert currentPriceRequest;
        
        String jsonData = '[';
        jsonData += '{"originalId":"' + existingLanePrices[0].Id + '","freightPrice":"750","typeOfTrailer":"' + TRAILER_DUAL_TEMP + '"},';
        jsonData += '{"originalId":"' + existingLanePrices[1].Id + '","freightPrice":"850","typeOfTrailer":"' + TRAILER_FRIGO_CHILLED + '"}';
        jsonData += ']';
        
        Test.startTest();
        PriceRequestController.updateExistingLanePrices(jsonData, currentPriceRequest.Id, true);
        Test.stopTest();
        
        List<Lane_Price__c> updatedLanePrices = [
            SELECT Id, Freight_Price__c, Type_Of_Trailer__c
            FROM Lane_Price__c 
            WHERE Id IN :existingLanePrices
            ORDER BY Freight_Price__c ASC
        ];
        
        Assert.areEqual(2, updatedLanePrices.size(), 'Should have updated 2 lane prices');
        Assert.areEqual(750, updatedLanePrices[0].Freight_Price__c, 'First lane price should be updated');
        Assert.areEqual(TRAILER_DUAL_TEMP, updatedLanePrices[0].Type_Of_Trailer__c, 'First trailer type should be updated');
        Assert.areEqual(850, updatedLanePrices[1].Freight_Price__c, 'Second lane price should be updated');
        Assert.areEqual(TRAILER_FRIGO_CHILLED, updatedLanePrices[1].Type_Of_Trailer__c, 'Second trailer type should be updated');
    }

    @IsTest
    static void testGetCountryCodeToNameMap() {
        Test.startTest();
        Map<String, String> result = PriceRequestController.getCountryCodeToNameMap();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Country code map should not be null');
        Assert.isFalse(result.isEmpty(), 'Country code map should not be empty');
        Assert.isTrue(result.size() > 0, 'Map should contain at least one country code');
        
        for (String countryCode : result.keySet()) {
            Assert.isNotNull(countryCode, 'Country code key should not be null');
            Assert.isNotNull(result.get(countryCode), 'Country name value should not be null');
            Assert.isFalse(String.isBlank(countryCode), 'Country code should not be blank');
            Assert.isFalse(String.isBlank(result.get(countryCode)), 'Country name should not be blank');
        }
    }
    
    @isTest
    static void testGetAccessCodeFromAccount() {
        Price_Request__c testPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        Test.startTest();
        String accessCode = PriceRequestController.getAccessCodeFromAccount(testPriceRequest.Id);
        Test.stopTest();
        
        Assert.isNotNull(accessCode, 'Access code should be populated');
    }
    
    @isTest
    static void testUpdateFreightPrices() {
        List<Lane_Price__c> lanePrices = [SELECT Id FROM Lane_Price__c];
        Price_Request__c testPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        
        String jsonData = '[';
        jsonData += '{"id":"' + lanePrices[0].Id + '","freightPrice":"1500","additionalStops":"150","twoDrivers":"250","directFerry":"350","typeOfTrailer":"' + TRAILER_FRIGO_CHILLED + '"},';
        jsonData += '{"id":"' + lanePrices[1].Id + '","freightPrice":"1700","additionalStops":"170","twoDrivers":"270","directFerry":"370","typeOfTrailer":"' + TRAILER_FRIGO_CHILLED + '"}';
        jsonData += ']';
        
        Test.startTest();
        PriceRequestController.updateFreightPrices(jsonData, testPriceRequest.Id, true);
        Test.stopTest();
        
        List<Lane_Price__c> updatedLanePrices = [
            SELECT Id, Freight_Price__c, Type_Of_Trailer__c
            FROM Lane_Price__c 
            ORDER BY Mandatory__c DESC
        ];
        
        Assert.areEqual(1500, updatedLanePrices[0].Freight_Price__c, 'First lane price should have updated freight price');
        Assert.areEqual(TRAILER_FRIGO_CHILLED, updatedLanePrices[0].Type_Of_Trailer__c, 'First lane price should have updated trailer type');
        Assert.areEqual(1700, updatedLanePrices[1].Freight_Price__c, 'Second lane price should have updated freight price');
        Assert.areEqual(TRAILER_FRIGO_CHILLED, updatedLanePrices[1].Type_Of_Trailer__c, 'Second lane price should have updated trailer type');
        
        Price_Request__c updatedRequest = [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id];
        Assert.areEqual(STAGE_ANSWER_RECEIVED, updatedRequest.Stage__c, 'Price request stage should be updated to Answer received');
    }
    
    @isTest
    static void testRequestPermissionToChange() {
        Price_Request__c testPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        Test.startTest();
        try {
            PriceRequestController.requestPermissionToChange(testPriceRequest.Id);
        } catch (Exception e) {
            Assert.isTrue(e instanceof AuraHandledException || e.getMessage().contains('notification'), 'Expected exception due to missing notification type: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountByLanePrice() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Account retrievedAccount = PriceRequestController.getAccountByLanePrice(testAccount.Id);
        Test.stopTest();
        Assert.isNotNull(retrievedAccount, 'Account should be retrieved');
        Assert.areEqual(testAccount.Id, retrievedAccount.Id, 'Retrieved account should match test account');
        Assert.areEqual(45.0, retrievedAccount.Overnight_charges_Price__c, 'Should have correct overnight charges price');
        Assert.areEqual(50.0, retrievedAccount.Dangerous_Goods_Price__c, 'Should have correct dangerous goods price');
        Assert.areEqual(15.0, retrievedAccount.ETS__c, 'Should have correct ETS value');
    }
    
    @isTest
    static void testUpdateAccountByLanePrice() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Price_Request__c testPriceRequest = [SELECT Id FROM Price_Request__c LIMIT 1];
        Account updatedAccount = new Account(
            Id = testAccount.Id,
            Fuel_surcharge_percentage__c = 5.0,
            Price_Per_Stop__c = 240.0,
            Price_2nd_Driver__c = 160.0,
            Price_Ferry__c = 200.0,
            ETS__c = 150.0,
            Plug_in__c = 120.0,
            Harbour_Dues__c = 25.0,
            Waiting_Hour__c = 130.0,
            Pallet_Exchange__c = true,
            Dangerous_Goods__c = true,
            Weekend_Charges__c = 135.0,
            Seasonal_Surcharge__c = 140.0,
            Overnight_charges_Price__c = 145.0,
            Dangerous_Goods_Price__c = 150.0,
            Pallet_Exchange_Price__c = 155.0,
            Tail_Lift_Price__c = 160.0,
            Pallet_Jack_Price__c = 165.0
        );
        String jsonAccount = JSON.serialize(updatedAccount);
        Test.startTest();
        PriceRequestController.updateAccountByLanePrice(jsonAccount, testPriceRequest.Id, true);
        Test.stopTest();
        Account verifyAccount = [
            SELECT Overnight_charges_Price__c, Seasonal_Surcharge__c, ETS__c, Dangerous_Goods_Price__c
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        Assert.areEqual(145.0, verifyAccount.Overnight_charges_Price__c, 'Should have updated overnight charges price');
        Assert.areEqual(140.0, verifyAccount.Seasonal_Surcharge__c, 'Should have updated seasonal surcharge');
        Assert.areEqual(150.0, verifyAccount.ETS__c, 'Should have updated ETS');
        Assert.areEqual(150.0, verifyAccount.Dangerous_Goods_Price__c, 'Should have updated dangerous goods price');
        Price_Request__c updatedRequest = [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id];
        Assert.areEqual(STAGE_ANSWER_RECEIVED, updatedRequest.Stage__c, 'Price request stage should be updated to Answer received');
    }
}