@isTest
private class TPQNewPriceRequestActionTest {
    
    // Constants for test data
    private static final String CARRIER_ACCOUNT_1 = 'Test Carrier Account 1';
    private static final String CARRIER_ACCOUNT_2 = 'Test Carrier Account 2';
    private static final String CARRIER_ACCOUNT_NO_TRAILERS = 'Test Carrier Account No Trailers';
    private static final String TRAILER_TYPES_DUAL_FRIGO = 'Dual temp;Frigo - chilled';
    private static final String TRAILER_TYPES_DUAL = 'Dual temp';
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>{
            createAccount(CARRIER_ACCOUNT_1, TRAILER_TYPES_DUAL_FRIGO),
            createAccount(CARRIER_ACCOUNT_2, TRAILER_TYPES_DUAL),
            createAccount(CARRIER_ACCOUNT_NO_TRAILERS, null)
        };
        insert testAccounts;

        // Create season
        Season__c currentSeason = new Season__c(
            Type__c = 'Tender',
            Status__c = 'Active',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(180)
        );
        insert currentSeason;
        
        // Create test locations
        List<Location__c> testLocations = new List<Location__c>{
            createLocation('Loading Test Location DE', 'Loading', 'DE', '12345'),
            createLocation('Loading Test Location FR', 'Loading', 'FR', '67890'),
            createLocation('Delivery Test Location IT', 'Delivery', 'IT', '54321'),
            createLocation('Delivery Test Location ES', 'Delivery', 'ES', '98765'),
            createLocation('Delivery Test Location NL', 'Delivery', 'NL', '11111')
        };
        insert testLocations;
        
        // Create test products
        List<Product2> testProducts = new List<Product2>{
            createProduct('Test Lane DE-IT', testLocations[0].Id, testLocations[2].Id),
            createProduct('Test Lane DE-ES', testLocations[0].Id, testLocations[3].Id),
            createProduct('Test Lane FR-IT', testLocations[1].Id, testLocations[2].Id),
            createProduct('Test Lane FR-NL', testLocations[1].Id, testLocations[4].Id)
        };
        insert testProducts;
    }
    
    // Helper methods for test data creation
    private static Account createAccount(String name, String trailerTypes) {
        return new Account(
            Name = name,
            Type = 'Haulier',
            Trailer_Types__c = trailerTypes
        );
    }
    
    private static Location__c createLocation(String name, String type, String countryCode, String postalCode) {
        return new Location__c(
            Name = name,
            Type__c = type,
            Country_Code__c = countryCode,
            Postal_Code__c = postalCode
        );
    }
    
    private static Product2 createProduct(String name, Id loadingLocationId, Id deliveryLocationId) {
        return new Product2(
            Name = name,
            Loading_Location__c = loadingLocationId,
            Destination_Location__c = deliveryLocationId
        );
    }
    
    // Helper method to get test account
    private static Account getTestAccount(String accountName) {
        return [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1];
    }
    
    // Helper method to get test products
    private static List<Product2> getTestProducts(String namePattern, String orderBy) {
        String query = 'SELECT Id FROM Product2 WHERE Name LIKE :namePattern';
        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;
        }
        return Database.query(query);
    }
    
    // Helper method to get season
    private static Season__c getCurrentSeason() {
        return [SELECT Id, Type__c FROM Season__c LIMIT 1];
    }
    
    // Helper method to create request
    private static TPQNewPriceRequestAction.Request createRequest(
        Id accountId,
        List<String> loadingCountryCodes,
        List<String> deliveryCountryCodes,
        List<Id> mandatoryProductIds,
        String trailerTypesString,
        Id seasonId
    ) {
        TPQNewPriceRequestAction.Request request = new TPQNewPriceRequestAction.Request();
        request.accountId = accountId;
        request.loadingCountryCodes = loadingCountryCodes;
        request.deliveryCountryCodes = deliveryCountryCodes;
        request.mandatoryProductIds = mandatoryProductIds;
        request.trailerTypesString = trailerTypesString;
        request.seasonId = seasonId;
        return request;
    }
    
    // Helper method to execute request
    private static List<TPQNewPriceRequestAction.Response> executeRequest(TPQNewPriceRequestAction.Request request) {
        Test.startTest();
        List<TPQNewPriceRequestAction.Response> results = 
            TPQNewPriceRequestAction.createPriceRequest(new List<TPQNewPriceRequestAction.Request>{request});
        Test.stopTest();
        return results;
    }
    
    // Helper method to validate basic response
    private static void validateBasicResponse(List<TPQNewPriceRequestAction.Response> results) {
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isNotNull(results[0].priceRequestId, 'Price request ID should not be null');
    }
    
    // Helper method to validate price request record
    private static void validatePriceRequest(Id priceRequestId, Id accountId) {
        Price_Request__c createdPriceRequest = [
            SELECT Id, Account__c, Request_Date__c, CurrencyIsoCode
            FROM Price_Request__c 
            WHERE Id = :priceRequestId
        ];
        Assert.areEqual(accountId, createdPriceRequest.Account__c, 'Account should match');
        Assert.areEqual(Date.today(), createdPriceRequest.Request_Date__c, 'Request date should be today');
        Assert.areEqual('EUR', createdPriceRequest.CurrencyIsoCode, 'Currency should be EUR');
    }
    
    // Helper method to get lane prices
    private static List<Lane_Price__c> getLanePrices(Id priceRequestId) {
        return [
            SELECT Id, Price_Request__c, Lane__c, Type_Of_Trailer__c, Mandatory__c, CurrencyIsoCode
            FROM Lane_Price__c 
            WHERE Price_Request__c = :priceRequestId
        ];
    }
    
    // Helper method to validate lane price basics
    private static void validateLanePriceBasics(Lane_Price__c lp, Id priceRequestId) {
        Assert.areEqual(priceRequestId, lp.Price_Request__c, 'Lane price should be linked to price request');
        Assert.areEqual('EUR', lp.CurrencyIsoCode, 'Currency should be EUR');
    }
    
    // Helper method to count mandatory vs optional
    private static Map<String, Integer> countMandatoryOptional(List<Lane_Price__c> lanePrices) {
        Integer mandatoryCount = 0;
        Integer optionalCount = 0;
        for (Lane_Price__c lp : lanePrices) {
            if (lp.Mandatory__c) {
                mandatoryCount++;
            } else {
                optionalCount++;
            }
        }
        return new Map<String, Integer>{
            'mandatory' => mandatoryCount,
            'optional' => optionalCount
        };
    }
    
    @isTest
    static void testCreatePriceRequestWithSingleCountryCodes() {
        Account testAccount = getTestAccount(CARRIER_ACCOUNT_1);
        List<Product2> allProducts = getTestProducts('Test Lane%', null);
        Season__c currentSeason = getCurrentSeason();
        
        TPQNewPriceRequestAction.Request request = createRequest(
            testAccount.Id,
            new List<String>{'DE'},
            new List<String>{'IT'},
            new List<Id>{allProducts[0].Id},
            TRAILER_TYPES_DUAL_FRIGO,
            currentSeason.Id
        );
        
        List<TPQNewPriceRequestAction.Response> results = executeRequest(request);
        
        validateBasicResponse(results);
        validatePriceRequest(results[0].priceRequestId, testAccount.Id);
        
        List<Lane_Price__c> createdLanePrices = getLanePrices(results[0].priceRequestId);
        Assert.areEqual(2, createdLanePrices.size(), 'Should create 2 lane prices for 2 trailer types');
    }
    
    @isTest
    static void testCreatePriceRequestWithMultipleCountryCodes() {
        Account testAccount = getTestAccount(CARRIER_ACCOUNT_1);
        List<Product2> allProducts = getTestProducts('Test Lane%', 'Name');
        Season__c currentSeason = getCurrentSeason();
        
        TPQNewPriceRequestAction.Request request = createRequest(
            testAccount.Id,
            new List<String>{'DE;FR'},
            new List<String>{'IT;ES'},
            new List<Id>{allProducts[0].Id, allProducts[1].Id},
            TRAILER_TYPES_DUAL_FRIGO,
            currentSeason.Id
        );
        
        List<TPQNewPriceRequestAction.Response> results = executeRequest(request);
        
        validateBasicResponse(results);
        
        List<Lane_Price__c> createdLanePrices = getLanePrices(results[0].priceRequestId);
        Assert.areEqual(6, createdLanePrices.size(), 'Should create 6 lane prices for 3 products and 2 trailer types');
        
        Map<String, Integer> counts = countMandatoryOptional(createdLanePrices);
        Assert.areEqual(4, counts.get('mandatory'), 'Should have 4 mandatory lane prices (2 products * 2 trailer types)');
        Assert.areEqual(2, counts.get('optional'), 'Should have 2 optional lane prices (1 product * 2 trailer types)');
    }
    
    @isTest
    static void testCreatePriceRequestWithNoTrailerTypes() {
        Account testAccount = getTestAccount(CARRIER_ACCOUNT_NO_TRAILERS);
        List<Product2> allProducts = getTestProducts('Test Lane%', null);
        Season__c currentSeason = getCurrentSeason();
        
        TPQNewPriceRequestAction.Request request = createRequest(
            testAccount.Id,
            new List<String>{'DE'},
            new List<String>{'IT'},
            new List<Id>{allProducts[0].Id},
            TRAILER_TYPES_DUAL_FRIGO,
            currentSeason.Id
        );
        
        List<TPQNewPriceRequestAction.Response> results = executeRequest(request);
        
        validateBasicResponse(results);
        
        List<Lane_Price__c> createdLanePrices = getLanePrices(results[0].priceRequestId);
        Assert.areEqual(1, createdLanePrices.size(), 'Should create 1 lane price without trailer types');
        Assert.isNull(createdLanePrices[0].Type_Of_Trailer__c, 'Trailer type should be null');
    }
    
    @isTest
    static void testCreatePriceRequestWithWhitespaceInCountryCodes() {
        Account testAccount = getTestAccount(CARRIER_ACCOUNT_1);
        List<Product2> allProducts = getTestProducts('Test Lane%', null);
        Season__c currentSeason = getCurrentSeason();
        
        TPQNewPriceRequestAction.Request request = createRequest(
            testAccount.Id,
            new List<String>{' DE ; FR '},
            new List<String>{' IT '},
            new List<Id>(),
            TRAILER_TYPES_DUAL_FRIGO,
            currentSeason.Id
        );
        
        List<TPQNewPriceRequestAction.Response> results = executeRequest(request);
        
        validateBasicResponse(results);
        
        List<Lane_Price__c> createdLanePrices = getLanePrices(results[0].priceRequestId);
        Assert.areEqual(4, createdLanePrices.size(), 'Should create 4 lane prices (2 products * 2 trailer types)');
    }
    
    @isTest
    static void testCreatePriceRequestWithEmptyCountryCodes() {
        Account testAccount = getTestAccount(CARRIER_ACCOUNT_1);
        List<Product2> allProducts = getTestProducts('Test Lane%', null);
        Season__c currentSeason = getCurrentSeason();
        
        TPQNewPriceRequestAction.Request request = createRequest(
            testAccount.Id,
            new List<String>(),
            new List<String>(),
            new List<Id>{allProducts[0].Id},
            TRAILER_TYPES_DUAL_FRIGO,
            currentSeason.Id
        );
        
        List<TPQNewPriceRequestAction.Response> results = executeRequest(request);
        
        validateBasicResponse(results);
        
        List<Lane_Price__c> createdLanePrices = getLanePrices(results[0].priceRequestId);
        Assert.areEqual(8, createdLanePrices.size(), 'Should create 8 lane prices (4 products * 2 trailer types)');
    }
    
    @isTest
    static void testCreatePriceRequestWithNullRequestList() {
        Test.startTest();
        List<TPQNewPriceRequestAction.Response> results = TPQNewPriceRequestAction.createPriceRequest(null);
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty list when request list is null');
    }
    
    @isTest
    static void testCreatePriceRequestWithEmptyRequestList() {
        Test.startTest();
        List<TPQNewPriceRequestAction.Response> results = 
            TPQNewPriceRequestAction.createPriceRequest(new List<TPQNewPriceRequestAction.Request>());
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty list when request list is empty');
    }
    
    @isTest
    static void testParseCountryCodesMethod() {
        Test.startTest();
        
        // Test with semicolon-separated values
        List<String> result1 = TPQNewPriceRequestAction.parseCountryCodes(new List<String>{'DE;FR;IT'});
        Assert.areEqual(3, result1.size(), 'Should parse semicolon-separated values');
        Assert.areEqual('DE', result1[0], 'First code should be DE');
        Assert.areEqual('FR', result1[1], 'Second code should be FR');
        Assert.areEqual('IT', result1[2], 'Third code should be IT');
        
        // Test with whitespace
        List<String> result2 = TPQNewPriceRequestAction.parseCountryCodes(new List<String>{' DE ; FR ; IT '});
        Assert.areEqual(3, result2.size(), 'Should handle whitespace correctly');
        Assert.areEqual('DE', result2[0], 'Should trim whitespace');
        
        // Test with empty strings
        List<String> result3 = TPQNewPriceRequestAction.parseCountryCodes(new List<String>{';;'});
        Assert.areEqual(0, result3.size(), 'Should ignore empty strings');
        
        // Test with null
        List<String> result4 = TPQNewPriceRequestAction.parseCountryCodes(null);
        Assert.areEqual(0, result4.size(), 'Should handle null input');
        
        Test.stopTest();
    }
    
    @isTest
    static void testQueryMatchingProductsMethod() {
        Test.startTest();
        
        List<Product2> result1 = TPQNewPriceRequestAction.queryMatchingProducts(
            new List<String>{'DE'}, 
            new List<String>{'IT'}
        );
        Assert.areEqual(1, result1.size(), 'Should find one matching product');
        Assert.areEqual('Test Lane DE-IT', result1[0].Name, 'Should find correct product');
        
        List<Product2> result2 = TPQNewPriceRequestAction.queryMatchingProducts(
            new List<String>{'DE', 'FR'}, 
            new List<String>{'IT'}
        );
        Assert.areEqual(2, result2.size(), 'Should find two matching products');
        
        List<Product2> result3 = TPQNewPriceRequestAction.queryMatchingProducts(
            new List<String>(), 
            new List<String>()
        );
        Assert.areEqual(4, result3.size(), 'Should find all products when no filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCreatePriceRequestRecordMethod() {
        Account testAccount = getTestAccount(CARRIER_ACCOUNT_1);
        Season__c currentSeason = getCurrentSeason();
        
        Test.startTest();
        Price_Request__c priceRequest = TPQNewPriceRequestAction.createPriceRequestRecord(
            testAccount.Id, 
            currentSeason.Id
        );
        Test.stopTest();
        
        Assert.isNotNull(priceRequest.Id, 'Price request should be inserted');
        Assert.areEqual(testAccount.Id, priceRequest.Account__c, 'Account should match');
        Assert.areEqual(Date.today(), priceRequest.Request_Date__c, 'Date should be today');
        Assert.areEqual('EUR', priceRequest.CurrencyIsoCode, 'Currency should be EUR');
    }
    
    @isTest
    static void testCreateLanePriceRecordMethod() {
        Account testAccount = getTestAccount(CARRIER_ACCOUNT_1);
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Lane DE-IT' LIMIT 1];
        Season__c currentSeason = getCurrentSeason();
        Price_Request__c priceRequest = TPQNewPriceRequestAction.createPriceRequestRecord(
            testAccount.Id, 
            currentSeason.Id
        );
        
        Test.startTest();
        Lane_Price__c lanePrice = TPQNewPriceRequestAction.createLanePriceRecord(
            priceRequest.Id, 
            testProduct.Id, 
            'Dual temp', 
            true
        );
        Test.stopTest();
        
        Assert.areEqual(priceRequest.Id, lanePrice.Price_Request__c, 'Price request should match');
        Assert.areEqual(testProduct.Id, lanePrice.Lane__c, 'Product should match');
        Assert.areEqual('Dual temp', lanePrice.Type_Of_Trailer__c, 'Trailer type should match');
        Assert.areEqual('EUR', lanePrice.CurrencyIsoCode, 'Currency should be EUR');
    }
}