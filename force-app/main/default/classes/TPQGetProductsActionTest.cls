@isTest
private class TPQGetProductsActionTest {
    @TestSetup
    static void setupTestData() {
        insert new Account(
            Name = 'Test Carrier Account',
            Type = 'Haulier',
            Trailer_Types__c = 'Dual temp;Frigo - chilled',
            Destination_Country_Codes__c = 'IT;ES;NL'
        );

        List<Location__c> testLocations = new List<Location__c>{
            new Location__c(Name = 'Loading Test Location DE', Type__c = 'Loading', Country_Code__c = 'DE', Postal_Code__c = '12345'),
            new Location__c(Name = 'Loading Test Location FR', Type__c = 'Loading', Country_Code__c = 'FR', Postal_Code__c = '67890'),
            new Location__c(Name = 'Delivery Test Location IT', Type__c = 'Delivery', Country_Code__c = 'IT', Postal_Code__c = '54321'),
            new Location__c(Name = 'Delivery Test Location ES', Type__c = 'Delivery', Country_Code__c = 'ES', Postal_Code__c = '98765'),
            new Location__c(Name = 'Delivery Test Location NL', Type__c = 'Delivery', Country_Code__c = 'NL', Postal_Code__c = '11111')
        };
        insert testLocations;

        Map<String, Id> locationMap = new Map<String, Id>();
        for (Location__c loc : testLocations) {
            locationMap.put(loc.Country_Code__c + '_' + loc.Type__c, loc.Id);
        }

        insert new List<Product2>{
            new Product2(Name = 'Test Lane DE-IT', Loading_Location__c = locationMap.get('DE_Loading'), Destination_Location__c = locationMap.get('IT_Delivery')),
            new Product2(Name = 'Test Lane DE-ES', Loading_Location__c = locationMap.get('DE_Loading'), Destination_Location__c = locationMap.get('ES_Delivery')),
            new Product2(Name = 'Test Lane FR-IT', Loading_Location__c = locationMap.get('FR_Loading'), Destination_Location__c = locationMap.get('IT_Delivery')),
            new Product2(Name = 'Test Lane FR-NL', Loading_Location__c = locationMap.get('FR_Loading'), Destination_Location__c = locationMap.get('NL_Delivery'))
        };
    }

    private static Account getTestAccount() {
        return [SELECT Id, Trailer_Types__c FROM Account LIMIT 1];
    }

    private static List<TPQGetProductsAction.Request> createRequestList(
        List<String> loadingCodes,
        List<String> deliveryCodes
    ) {
        Account acc = getTestAccount();
        TPQGetProductsAction.Request req = new TPQGetProductsAction.Request();
        req.loadingCountryCodes = loadingCodes;
        req.deliveryCountryCodes = deliveryCodes;
        req.accountId = acc.Id;
        return new List<TPQGetProductsAction.Request>{ req };
    }

    private static List<Product2> runGetProducts(List<String> loadingCodes, List<String> deliveryCodes) {
        List<List<Product2>> resultWrapper = TPQGetProductsAction.getProducts(createRequestList(loadingCodes, deliveryCodes));
        Assert.areEqual(1, resultWrapper.size(), 'Should always return one list of products');
        return resultWrapper[0];
    }

    @isTest
    static void testGetProductsWithSingleCountryCodes() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>{'DE'}, new List<String>{'IT'});
        Test.stopTest();

        Assert.areEqual(1, products.size(), 'Should return one matching product');
        Assert.areEqual('Test Lane DE-IT', products[0].Name, 'Should return correct lane');
        Assert.areEqual('DE', products[0].Loading_Location__r.Country_Code__c);
        Assert.areEqual('IT', products[0].Destination_Location__r.Country_Code__c);
    }

    @isTest
    static void testGetProductsWithMultipleCountryCodes() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>{'DE;FR'}, new List<String>{'IT;ES'});
        Test.stopTest();

        Assert.areEqual(3, products.size(), 'Should return three matching products');
        Set<String> expected = new Set<String>{'Test Lane DE-IT', 'Test Lane DE-ES', 'Test Lane FR-IT'};
        Set<String> actual = new Set<String>();
        for (Product2 p : products) actual.add(p.Name);
        Assert.areEqual(expected, actual, 'Should return correct products');
    }

    @isTest
    static void testGetProductsWithLoadingCountryOnly() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>{'DE'}, new List<String>());
        Test.stopTest();

        Assert.areEqual(2, products.size(), 'Should return two products from DE');
        for (Product2 p : products)
            Assert.areEqual('DE', p.Loading_Location__r.Country_Code__c);
    }

    @isTest
    static void testGetProductsWithDeliveryCountryOnly() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>(), new List<String>{'IT'});
        Test.stopTest();

        Assert.areEqual(2, products.size(), 'Should return two products to IT');
        for (Product2 p : products)
            Assert.areEqual('IT', p.Destination_Location__r.Country_Code__c);
    }

    @isTest
    static void testGetProductsWithNoFilters() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>(), new List<String>());
        Test.stopTest();

        Assert.areEqual(4, products.size(), 'Should return all products when no filters applied');
    }

    @isTest
    static void testGetProductsWithEmptyStrings() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>{''}, new List<String>{''});
        Test.stopTest();

        Assert.areEqual(4, products.size(), 'Should return all products when empty strings provided');
    }

    @isTest
    static void testGetProductsWithWhitespace() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>{' DE ; FR '}, new List<String>{' IT '});
        Test.stopTest();

        Assert.areEqual(2, products.size(), 'Should handle whitespace correctly');
        Set<String> expected = new Set<String>{'Test Lane DE-IT', 'Test Lane FR-IT'};
        Set<String> actual = new Set<String>();
        for (Product2 p : products) actual.add(p.Name);
        Assert.areEqual(expected, actual, 'Should return correct products after trimming');
    }

    @isTest
    static void testGetProductsWithNoMatchingCountries() {
        Test.startTest();
        List<Product2> products = runGetProducts(new List<String>{'US'}, new List<String>{'CA'});
        Test.stopTest();

        Assert.areEqual(0, products.size(), 'Should return no products for non-matching countries');
    }
}