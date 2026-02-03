@isTest
private class ProductLineControllerTest {
    
    private static Season__c testSeason;
    
    @TestSetup
    static void setupTestData() {
        testSeason = new Season__c(
            Name = 'Test Season',
            Status__c = 'Active',
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(30)
        );
        insert testSeason;
        
        List<Account> carriers = createCarrierAccounts();
        insert carriers;
        
        List<Location__c> locations = createLocations();
        insert locations;
        
        List<Product2> products = createProducts(locations);
        insert products;
        
        List<Price_Request__c> priceRequests = createPriceRequests(carriers, testSeason.Id);
        insert priceRequests;
        
        List<Lane_Price__c> lanePrices = createLanePrices(priceRequests, products);
        insert lanePrices;
        
        List<Carrier_Score__c> carrierScores = createCarrierScores(carriers);
        insert carrierScores;
    }
    
    private static List<Account> createCarrierAccounts() {
        return new List<Account>{
            new Account(
                Name = 'Test Carrier Account 1',
                Type = 'Haulier',
                Dangerous_Goods__c = true,
                Pallet_Exchange__c = true,
                Tail_Lift__c = true,
                Pallet_Jack__c = false,
                Trailer_Types__c = 'Dual temp;Frigo - chilled'
            ),
            new Account(
                Name = 'Test Carrier Account 2',
                Type = 'Haulier',
                Dangerous_Goods__c = false,
                Pallet_Exchange__c = true,
                Tail_Lift__c = false,
                Pallet_Jack__c = true,
                Trailer_Types__c = 'Dual temp'
            ),
            new Account(
                Name = 'Test Carrier Account 3',
                Type = 'Haulier',
                Dangerous_Goods__c = true,
                Pallet_Exchange__c = false,
                Tail_Lift__c = true,
                Pallet_Jack__c = true,
                Trailer_Types__c = 'Frigo - chilled'
            )
        };
    }
    
    private static List<Location__c> createLocations() {
        return new List<Location__c>{
            new Location__c(Name = 'Loading Test Location DE', Type__c = 'Loading', Country_Code__c = 'DE', Postal_Code__c = '12345'),
            new Location__c(Name = 'Loading Test Location FR', Type__c = 'Loading', Country_Code__c = 'FR', Postal_Code__c = '67890'),
            new Location__c(Name = 'Delivery Test Location IT', Type__c = 'Delivery', Country_Code__c = 'IT', Postal_Code__c = '54321'),
            new Location__c(Name = 'Delivery Test Location ES', Type__c = 'Delivery', Country_Code__c = 'ES', Postal_Code__c = '98765')
        };
    }
    
    private static List<Product2> createProducts(List<Location__c> locations) {
        return new List<Product2>{
            new Product2(Name = 'Test Lane DE-IT', Loading_Location__c = locations[0].Id, Destination_Location__c = locations[2].Id, IsActive = true),
            new Product2(Name = 'Test Lane DE-ES', Loading_Location__c = locations[0].Id, Destination_Location__c = locations[3].Id, IsActive = true),
            new Product2(Name = 'Test Lane FR-IT', Loading_Location__c = locations[1].Id, Destination_Location__c = locations[2].Id, IsActive = true),
            new Product2(Name = 'Inactive Lane DE-IT', Loading_Location__c = locations[0].Id, Destination_Location__c = locations[2].Id, IsActive = false)
        };
    }
    
    private static List<Price_Request__c> createPriceRequests(List<Account> carriers, Id seasonId) {
        List<Price_Request__c> priceRequests = new List<Price_Request__c>();
        for (Account carrier : carriers) {
            priceRequests.add(new Price_Request__c(
                Account__c = carrier.Id,
                Request_Date__c = Date.today(),
                Stage__c = 'Answer received',
                Season__c = seasonId
            ));
        }
        return priceRequests;
    }
    
    private static List<Lane_Price__c> createLanePrices(List<Price_Request__c> priceRequests, List<Product2> products) {
        return new List<Lane_Price__c>{
            new Lane_Price__c(Price_Request__c = priceRequests[0].Id, Lane__c = products[0].Id, Freight_Price__c = 1000, Type_Of_Trailer__c = 'Dual temp'),
            new Lane_Price__c(Price_Request__c = priceRequests[0].Id, Lane__c = products[0].Id, Freight_Price__c = 1100, Type_Of_Trailer__c = 'Frigo - chilled'),
            new Lane_Price__c(Price_Request__c = priceRequests[1].Id, Lane__c = products[0].Id, Freight_Price__c = 1050, Type_Of_Trailer__c = 'Dual temp'),
            new Lane_Price__c(Price_Request__c = priceRequests[2].Id, Lane__c = products[1].Id, Freight_Price__c = 1200, Type_Of_Trailer__c = 'Frigo - chilled'),
            new Lane_Price__c(Price_Request__c = priceRequests[0].Id, Lane__c = products[2].Id, Freight_Price__c = 1300, Type_Of_Trailer__c = 'Dual temp'),
            new Lane_Price__c(Price_Request__c = priceRequests[1].Id, Lane__c = products[1].Id, Freight_Price__c = null, Type_Of_Trailer__c = 'Dual temp'),
            new Lane_Price__c(Price_Request__c = priceRequests[0].Id, Lane__c = products[3].Id, Freight_Price__c = 900, Type_Of_Trailer__c = 'Dual temp')
        };
    }
    
    private static List<Carrier_Score__c> createCarrierScores(List<Account> carriers) {
        return new List<Carrier_Score__c>{
            new Carrier_Score__c(Carrier__c = carriers[0].Id, Reliability_Score__c = 95.5, Availability_Score_Percentage__c = 88.0, Price_Level_Percentage__c = 75.0),
            new Carrier_Score__c(Carrier__c = carriers[0].Id, Reliability_Score__c = 92.0, Availability_Score_Percentage__c = 90.0, Price_Level_Percentage__c = 80.0),
            new Carrier_Score__c(Carrier__c = carriers[1].Id, Reliability_Score__c = 87.5, Availability_Score_Percentage__c = 85.0, Price_Level_Percentage__c = 70.0),
            new Carrier_Score__c(Carrier__c = carriers[2].Id, Reliability_Score__c = 90.0, Availability_Score_Percentage__c = 92.0, Price_Level_Percentage__c = 85.0)
        };
    }
    
    private static Id getSeasonId() {
        return [SELECT Id FROM Season__c WHERE Name = 'Test Season' LIMIT 1].Id;
    }
    
    private static Location__c getLocation(String countryCode, String locationType) {
        return [SELECT Id FROM Location__c WHERE Country_Code__c = :countryCode AND Type__c = :locationType LIMIT 1];
    }
    
    private static List<ProductLineController.LineInfoAndCarrierScore> callGetLinesByLocations(
        String loadingLocationId, String destinationLocationId, String trailerType
    ) {
        return ProductLineController.getLinesByLocations(
            loadingLocationId, 
            destinationLocationId, 
            Date.today(),
            trailerType,
            getSeasonId()
        );
    }
    
    @isTest
    static void testGetLinesByLocationsSuccessWithFrigoTrailer() {
        Location__c loadingLocation = getLocation('DE', 'Loading');
        Location__c deliveryLocation = getLocation('IT', 'Delivery');
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results = callGetLinesByLocations(
            loadingLocation.Id, deliveryLocation.Id, 'Dual temp'
        );
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return 2 Dual temp lane prices');
        
        ProductLineController.LineInfoAndCarrierScore result1 = results[0];
        Assert.isNotNull(result1.Id, 'Lane price ID should not be null');
        Assert.isNotNull(result1.productId, 'Product ID should not be null');
        Assert.areEqual('Test Lane DE-IT', result1.productName, 'Product name should match');
        Assert.areEqual('Dual temp', result1.trailerType, 'Trailer type should match');
        
        ProductLineController.LineInfoAndCarrierScore carrier1Result = null;
        for (ProductLineController.LineInfoAndCarrierScore result : results) {
            if (result.carrier == 'Test Carrier Account 1') {
                carrier1Result = result;
                break;
            }
        }
        
        Assert.isNotNull(carrier1Result, 'Should find result for carrier 1');
        Assert.areEqual(1000, carrier1Result.unitPrice, 'Unit price should match');
        Assert.areEqual('Test Carrier Account 1', carrier1Result.carrier, 'Carrier name should match');
        Assert.isTrue(carrier1Result.dangerousGoods, 'Should support dangerous goods');
        Assert.isTrue(carrier1Result.palletExchange, 'Should support pallet exchange');
        Assert.isTrue(carrier1Result.tailLift, 'Should support tail lift');
        Assert.isFalse(carrier1Result.palletJack, 'Should not support pallet jack');
        Assert.areEqual(2, carrier1Result.carrierScores.size(), 'Should have 2 carrier scores');
        Assert.areEqual(95.5, carrier1Result.carrierScores[0].reliabilityScore, 'Reliability score should match');
        Assert.areEqual(88.0, carrier1Result.carrierScores[0].availabilityScore, 'Availability score should match');
        Assert.areEqual(75.0, carrier1Result.carrierScores[0].priceLevel, 'Price level should match');
    }
    
    @isTest
    static void testGetLinesByLocationsSuccessWithCooledTrailer() {
        Location__c loadingLocation = getLocation('DE', 'Loading');
        Location__c deliveryLocation = getLocation('IT', 'Delivery');
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results = callGetLinesByLocations(
            loadingLocation.Id, deliveryLocation.Id, 'Frigo - chilled'
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return 1 Frigo - chilled lane price');
        Assert.areEqual('Frigo - chilled', results[0].trailerType, 'Trailer type should be Frigo - chilled');
        Assert.areEqual(1100, results[0].unitPrice, 'Unit price should match');
        Assert.areEqual('Test Carrier Account 1', results[0].carrier, 'Carrier name should match');
    }
    
    @isTest
    static void testGetLinesByLocationsWithBlankParameters() {
        Id seasonId = getSeasonId();
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results1 = ProductLineController.getLinesByLocations(
            null, 'someId', Date.today(), 'Dual temp', seasonId
        );
        List<ProductLineController.LineInfoAndCarrierScore> results2 = ProductLineController.getLinesByLocations(
            'someId', '', Date.today(), 'Dual temp', seasonId
        );
        List<ProductLineController.LineInfoAndCarrierScore> results3 = ProductLineController.getLinesByLocations(
            '', null, Date.today(), 'Dual temp', seasonId
        );
        Test.stopTest();
        
        Assert.areEqual(0, results1.size(), 'Should return empty list when loading location is null');
        Assert.areEqual(0, results2.size(), 'Should return empty list when destination location is blank');
        Assert.areEqual(0, results3.size(), 'Should return empty list when both parameters are blank');
    }
    
    @isTest
    static void testGetLinesByLocationsNoMatchingLanes() {
        Location__c loadingLocation = getLocation('FR', 'Loading');
        Location__c deliveryLocation = getLocation('ES', 'Delivery');
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results = callGetLinesByLocations(
            loadingLocation.Id, deliveryLocation.Id, 'Dual temp'
        );
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty list when no matching lane prices exist');
    }
    
    @isTest
    static void testGetLinesByLocationsWithNonMatchingTrailerType() {
        Location__c loadingLocation = getLocation('DE', 'Loading');
        Location__c deliveryLocation = getLocation('IT', 'Delivery');
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results = callGetLinesByLocations(
            loadingLocation.Id, deliveryLocation.Id, 'Standard'
        );
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty list when no matching trailer type exists');
    }
    
    @isTest
    static void testGetLinesByLocationsWithCarrierWithoutScores() {
        Account carrierWithoutScores = new Account(
            Name = 'Carrier Without Scores',
            Type = 'Carrier',
            Dangerous_Goods__c = false,
            Pallet_Exchange__c = false,
            Tail_Lift__c = false,
            Pallet_Jack__c = false
        );
        insert carrierWithoutScores;
        
        Id seasonId = getSeasonId();
        Price_Request__c priceRequest = new Price_Request__c(
            Account__c = carrierWithoutScores.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received',
            Season__c = seasonId
        );
        insert priceRequest;
        
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Lane DE-IT' LIMIT 1];
        Lane_Price__c lanePrice = new Lane_Price__c(
            Price_Request__c = priceRequest.Id,
            Lane__c = testProduct.Id,
            Freight_Price__c = 1500,
            Type_Of_Trailer__c = 'Dual temp'
        );
        insert lanePrice;
        
        Location__c loadingLocation = getLocation('DE', 'Loading');
        Location__c deliveryLocation = getLocation('IT', 'Delivery');
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results = callGetLinesByLocations(
            loadingLocation.Id, deliveryLocation.Id, 'Dual temp'
        );
        Test.stopTest();
        
        ProductLineController.LineInfoAndCarrierScore resultWithoutScores = null;
        for (ProductLineController.LineInfoAndCarrierScore result : results) {
            if (result.carrier == 'Carrier Without Scores') {
                resultWithoutScores = result;
                break;
            }
        }
        
        Assert.isNotNull(resultWithoutScores, 'Should find result for carrier without scores');
        Assert.areEqual(0, resultWithoutScores.carrierScores.size(), 'Should have empty carrier scores list');
        Assert.areEqual(1500, resultWithoutScores.unitPrice, 'Unit price should match');
        Assert.isFalse(resultWithoutScores.dangerousGoods, 'Should not support dangerous goods');
    }
    
    @isTest
    static void testGetLinesByLocationsExcludesNullFreightPrices() {
        Location__c loadingLocation = getLocation('DE', 'Loading');
        Location__c deliveryLocation = getLocation('ES', 'Delivery');
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results = callGetLinesByLocations(
            loadingLocation.Id, deliveryLocation.Id, 'Frigo - chilled'
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should exclude lane prices with null freight price');
        Assert.areEqual(1200, results[0].unitPrice, 'Should return the lane price with valid freight price');
    }
    
    @isTest
    static void testGetLinesByLocationsExcludesInactiveProducts() {
        Location__c loadingLocation = getLocation('DE', 'Loading');
        Location__c deliveryLocation = getLocation('IT', 'Delivery');
        
        Test.startTest();
        List<ProductLineController.LineInfoAndCarrierScore> results = callGetLinesByLocations(
            loadingLocation.Id, deliveryLocation.Id, 'Dual temp'
        );
        Test.stopTest();
        
        for (ProductLineController.LineInfoAndCarrierScore result : results) {
            Assert.areNotEqual('Inactive Lane DE-IT', result.productName, 'Should not include inactive products');
        }
    }
    
    @isTest
    static void testCarrierScoreClass() {
        ProductLineController.CarrierScore cs = new ProductLineController.CarrierScore();
        cs.reliabilityScore = 95.5;
        cs.availabilityScore = 88.0;
        cs.priceLevel = 75.0;
        
        Assert.areEqual(95.5, cs.reliabilityScore, 'Reliability score should match');
        Assert.areEqual(88.0, cs.availabilityScore, 'Availability score should match');
        Assert.areEqual(75.0, cs.priceLevel, 'Price level should match');
    }
    
    @isTest
    static void testLineInfoAndCarrierScoreClass() {
        ProductLineController.LineInfoAndCarrierScore lineInfo = new ProductLineController.LineInfoAndCarrierScore();
        lineInfo.Id = 'testId';
        lineInfo.productId = 'testProductId';
        lineInfo.productName = 'Test Product';
        lineInfo.carrier = 'Test Carrier';
        lineInfo.trailerType = 'Dual temp';
        lineInfo.unitPrice = 1000;
        lineInfo.dieselMarkup = 10.5;
        lineInfo.transitTime = 2;
        lineInfo.dangerousGoods = true;
        lineInfo.palletExchange = false;
        lineInfo.tailLift = true;
        lineInfo.palletJack = false;
        lineInfo.carrierScores = new List<ProductLineController.CarrierScore>();
        
        Assert.areEqual('testId', lineInfo.Id, 'ID should match');
        Assert.areEqual('testProductId', lineInfo.productId, 'Product ID should match');
        Assert.areEqual('Test Product', lineInfo.productName, 'Product name should match');
        Assert.areEqual('Test Carrier', lineInfo.carrier, 'Carrier should match');
        Assert.areEqual('Dual temp', lineInfo.trailerType, 'Trailer type should match');
        Assert.areEqual(1000, lineInfo.unitPrice, 'Unit price should match');
        Assert.areEqual(10.5, lineInfo.dieselMarkup, 'Diesel markup should match');
        Assert.areEqual(2, lineInfo.transitTime, 'Transit time should match');
        Assert.isTrue(lineInfo.dangerousGoods, 'Dangerous goods should be true');
        Assert.isFalse(lineInfo.palletExchange, 'Pallet exchange should be false');
        Assert.isTrue(lineInfo.tailLift, 'Tail lift should be true');
        Assert.isFalse(lineInfo.palletJack, 'Pallet jack should be false');
        Assert.isNotNull(lineInfo.carrierScores, 'Carrier scores should not be null');
    }
}