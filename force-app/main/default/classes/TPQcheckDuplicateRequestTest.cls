@isTest
private class TPQcheckDuplicateRequestTest {
    
    private static final String ACCOUNT_NAME = 'Test Carrier Account';
    private static final String ACCOUNT_TYPE_HAULIER = 'Haulier';
    private static final String TRAILER_TYPE_DUAL_TEMP = 'Dual temp';
    private static final String TRAILER_TYPE_FRIGO = 'Frigo - chilled';
    private static final String TRAILER_TYPES_DUAL_FRIGO = TRAILER_TYPE_DUAL_TEMP + ';' + TRAILER_TYPE_FRIGO;
    private static final String CURRENCY_EUR = 'EUR';
    private static final String SEASON_TYPE_TENDER = 'Tender';
    private static final String SEASON_STATUS_ACTIVE = 'Active';
    private static final String LOCATION_TYPE_LOADING = 'Loading';
    private static final String LOCATION_TYPE_DELIVERY = 'Delivery';
    private static final String COUNTRY_CODE_DE = 'DE';
    private static final String COUNTRY_CODE_IT = 'IT';
    private static final String POSTAL_CODE_DE = '12345';
    private static final String POSTAL_CODE_IT = '54321';
    private static final String LOCATION_NAME_LOADING_DE = 'Loading Location DE';
    private static final String LOCATION_NAME_DELIVERY_IT = 'Delivery Location IT';
    private static final String PRODUCT_NAME_LANE_1 = 'Test Lane 1';
    private static final String PRODUCT_NAME_LANE_2 = 'Test Lane 2';
    private static final String PRODUCT_NAME_LANE_3 = 'Test Lane 3';
    private static final Decimal FREIGHT_PRICE = 100.00;
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = createAccount(ACCOUNT_NAME, TRAILER_TYPES_DUAL_FRIGO);
        insert testAccount;

        Season__c currentSeason = createSeason(SEASON_TYPE_TENDER, SEASON_STATUS_ACTIVE);
        insert currentSeason;
        
        List<Location__c> testLocations = new List<Location__c>{
            createLocation(LOCATION_NAME_LOADING_DE, LOCATION_TYPE_LOADING, COUNTRY_CODE_DE, POSTAL_CODE_DE),
            createLocation(LOCATION_NAME_DELIVERY_IT, LOCATION_TYPE_DELIVERY, COUNTRY_CODE_IT, POSTAL_CODE_IT)
        };
        insert testLocations;
        
        List<Product2> testProducts = new List<Product2>{
            createProduct(PRODUCT_NAME_LANE_1, testLocations[0].Id, testLocations[1].Id),
            createProduct(PRODUCT_NAME_LANE_2, testLocations[0].Id, testLocations[1].Id),
            createProduct(PRODUCT_NAME_LANE_3, testLocations[0].Id, testLocations[1].Id)
        };
        insert testProducts;
    }
        
    private static Account createAccount(String name, String trailerTypes) {
        return new Account(
            Name = name,
            Type = ACCOUNT_TYPE_HAULIER,
            Trailer_Types__c = trailerTypes
        );
    }
    
    private static Season__c createSeason(String type, String status) {
        return new Season__c(
            Type__c = type,
            Status__c = status,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(180)
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
    
    private static Price_Request__c createPriceRequest(Id accountId, Id seasonId) {
        return new Price_Request__c(
            Account__c = accountId,
            Season__c = seasonId,
            Request_Date__c = Date.today(),
            CurrencyIsoCode = CURRENCY_EUR
        );
    }
    
    private static Lane_Price__c createLanePrice(Id priceRequestId, Id productId, String trailerType, Boolean mandatory, Decimal freightPrice) {
        return new Lane_Price__c(
            Price_Request__c = priceRequestId,
            Lane__c = productId,
            Type_Of_Trailer__c = trailerType,
            Mandatory__c = mandatory,
            Freight_Price__c = freightPrice,
            CurrencyIsoCode = CURRENCY_EUR
        );
    }
        
    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = :ACCOUNT_NAME LIMIT 1];
    }
    
    private static Season__c getCurrentSeason() {
        return [SELECT Id FROM Season__c LIMIT 1];
    }
    
    private static List<Product2> getTestProducts() {
        return [SELECT Id, Name FROM Product2 ORDER BY Name];
    }
    
    private static Product2 getProductByName(String productName) {
        return [SELECT Id FROM Product2 WHERE Name = :productName LIMIT 1];
    }
        
    private static TPQcheckDuplicateRequest.Request createRequest(
        Id accountId,
        List<Id> mandatoryProductIds,
        String trailerTypesString,
        Id seasonId
    ) {
        TPQcheckDuplicateRequest.Request request = new TPQcheckDuplicateRequest.Request();
        request.accountId = accountId;
        request.mandatoryProductIds = mandatoryProductIds;
        request.trailerTypesString = trailerTypesString;
        request.seasonId = seasonId;
        return request;
    }
    
    private static List<TPQcheckDuplicateRequest.Response> executeRequest(TPQcheckDuplicateRequest.Request request) {
        Test.startTest();
        List<TPQcheckDuplicateRequest.Response> results = 
            TPQcheckDuplicateRequest.checkDuplicateRequest(new List<TPQcheckDuplicateRequest.Request>{request});
        Test.stopTest();
        return results;
    }
        
    private static void setupExistingPriceRequestWithLanePrices(
        Id accountId,
        Id seasonId,
        List<Id> productIds,
        String trailerType,
        Boolean withPrices
    ) {
        Price_Request__c priceRequest = createPriceRequest(accountId, seasonId);
        insert priceRequest;
        
        List<Lane_Price__c> lanePrices = new List<Lane_Price__c>();
        for (Id productId : productIds) {
            Decimal price = withPrices ? FREIGHT_PRICE : null;
            lanePrices.add(createLanePrice(priceRequest.Id, productId, trailerType, true, price));
        }
        insert lanePrices;
    }
        
    @isTest
    static void testUniqueRequest_NoExistingLanePrices() {
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            currentSeason.Id
        );
        
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].uniqueRequest, 'Request should be unique when no existing lane prices');
    }
    
    @isTest
    static void testDuplicateRequest_AllMandatoryLanesHavePrices() {      
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            true
        );
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            currentSeason.Id
        );
        
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isFalse(results[0].uniqueRequest, 'Request should not be unique when all mandatory lanes have prices');
    }
    
    @isTest
    static void testUniqueRequest_PartialLanePrices() {      
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> requestProductIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        List<Id> existingProductIds = new List<Id>{testProducts[0].Id}; // Only one has price
        
        // Setup existing price request with only one mandatory lane priced
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            existingProductIds,
            TRAILER_TYPE_DUAL_TEMP,
            true
        );
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            requestProductIds,
            TRAILER_TYPE_DUAL_TEMP,
            currentSeason.Id
        );
               
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
               
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].uniqueRequest, 'Request should be unique when only partial lanes have prices');
    }
    
    @isTest
    static void testUniqueRequest_ExistingLanesWithoutPrices() {       
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            false
        );
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            currentSeason.Id
        );
               
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
            
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].uniqueRequest, 'Request should be unique when existing lanes have no prices');
    }
    
    @isTest
    static void testUniqueRequest_DifferentTrailerType() {       
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            true
        );
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            productIds,
            TRAILER_TYPE_FRIGO,
            currentSeason.Id
        );
        
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].uniqueRequest, 'Request should be unique when trailer type is different');
    }
    
    @isTest
    static void testUniqueRequest_DifferentAccount() {       
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        Account anotherAccount = createAccount('Another Carrier Account', TRAILER_TYPES_DUAL_FRIGO);
        insert anotherAccount;
        
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            true
        );
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            anotherAccount.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            currentSeason.Id
        );
              
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
             
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].uniqueRequest, 'Request should be unique when account is different');
    }
    
    @isTest
    static void testUniqueRequest_DifferentSeason() {      
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        Season__c anotherSeason = createSeason(SEASON_TYPE_TENDER, SEASON_STATUS_ACTIVE);
        insert anotherSeason;
        
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            true
        );
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            anotherSeason.Id
        );
        
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].uniqueRequest, 'Request should be unique when season is different');
    }
    
    @isTest
    static void testUniqueRequest_MultipleTrailerTypes() {      
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            productIds,
            TRAILER_TYPE_DUAL_TEMP,
            true
        );
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            productIds,
            TRAILER_TYPES_DUAL_FRIGO,
            currentSeason.Id
        );
        
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isFalse(results[0].uniqueRequest, 'Request should not be unique when one trailer type already has all prices');
    }
    
    @isTest
    static void testUniqueRequest_EmptyTrailerTypeString() {
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        List<Id> productIds = new List<Id>{testProducts[0].Id, testProducts[1].Id};
        
        TPQcheckDuplicateRequest.Request request = createRequest(
            testAccount.Id,
            productIds,
            '',
            currentSeason.Id
        );
        
        List<TPQcheckDuplicateRequest.Response> results = executeRequest(request);
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].uniqueRequest, 'Request should be unique when trailer type string is empty');
    }
    
    @isTest
    static void testMultipleRequests() {
        Account testAccount = getTestAccount();
        Season__c currentSeason = getCurrentSeason();
        List<Product2> testProducts = getTestProducts();
        
        List<Id> productIds1 = new List<Id>{testProducts[0].Id};
        List<Id> productIds2 = new List<Id>{testProducts[1].Id};
        
        setupExistingPriceRequestWithLanePrices(
            testAccount.Id,
            currentSeason.Id,
            productIds1,
            TRAILER_TYPE_DUAL_TEMP,
            true
        );
        
        List<TPQcheckDuplicateRequest.Request> requests = new List<TPQcheckDuplicateRequest.Request>{
            createRequest(testAccount.Id, productIds1, TRAILER_TYPE_DUAL_TEMP, currentSeason.Id),
            createRequest(testAccount.Id, productIds2, TRAILER_TYPE_DUAL_TEMP, currentSeason.Id)
        };
        
        Test.startTest();
        List<TPQcheckDuplicateRequest.Response> results = 
            TPQcheckDuplicateRequest.checkDuplicateRequest(requests);
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return two responses');
        Assert.isFalse(results[0].uniqueRequest, 'First request should not be unique (duplicate)');
        Assert.isTrue(results[1].uniqueRequest, 'Second request should be unique');
    }
    
    @isTest
    static void testEmptyRequestList() {
        Test.startTest();
        List<TPQcheckDuplicateRequest.Response> results = 
            TPQcheckDuplicateRequest.checkDuplicateRequest(new List<TPQcheckDuplicateRequest.Request>());
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty list when request list is empty');
    }
}