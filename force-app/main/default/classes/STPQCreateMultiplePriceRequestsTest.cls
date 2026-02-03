@isTest
private class STPQCreateMultiplePriceRequestsTest {
    
    @TestSetup
    static void setupTestData() {

        Season__c testSeason = new Season__c(
            Name = 'Spring Season',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(3)
        );
        insert testSeason;
        
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Transport GmbH',
            Type = 'Customer',
            Destination_Country_Codes__c = 'DE;FR;NL',
            Trailer_Types__c = 'Frigo - chilled;Frigo - frozen'
        ));
        testAccounts.add(new Account(
            Name = 'Logistics East',
            Type = 'Customer',
            Destination_Country_Codes__c = 'PL;CZ;SK',
            Trailer_Types__c = 'Box trailer;Dual temp'
        ));
        testAccounts.add(new Account(
            Name = 'Nordic Express',
            Type = 'Prospect',
            Destination_Country_Codes__c = 'SE;NO;DK',
            Trailer_Types__c = 'Frigo - frozen;Dual temp'
        ));
        insert testAccounts;
        
        List<Product2> testProducts = new List<Product2>();
        testProducts.add(new Product2(
            Name = 'Lane DE-PL',
            ProductCode = 'DE-PL-001',
            IsActive = true
        ));
        testProducts.add(new Product2(
            Name = 'Lane FR-IT',
            ProductCode = 'FR-IT-002',
            IsActive = true
        ));
        insert testProducts;
    }
    
    @isTest
    static void testCreatePriceRequests_SuccessfulCreation() {
        Season__c season = [SELECT Id, Name FROM Season__c LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account];
        List<Product2> products = [SELECT Id FROM Product2];
        
        STPQCreateMultiplePriceRequests.Request req = new STPQCreateMultiplePriceRequests.Request();
        req.seasonId = season.Id;
        req.accountIds = new List<Id>{accounts[0].Id, accounts[1].Id};
        req.productIds = new List<Id>{products[0].Id, products[1].Id};
        req.trailerTypesString = 'Frigo - chilled;Frigo - frozen;Dual temp';
        
        Test.startTest();
        List<List<Price_Request__c>> results = STPQCreateMultiplePriceRequests.createPriceRequests(
            new List<STPQCreateMultiplePriceRequests.Request>{req}
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one list of Price Requests');
        Assert.isFalse(results[0].isEmpty(), 'Should create Price Requests');
        Assert.areEqual(2, results[0].size(), 'Should create 2 Price Requests (one per account)');
        
        // Verify Price Request fields
        for (Price_Request__c pr : results[0]) {
            Assert.isNotNull(pr.Id, 'Price Request should have an Id');
            Assert.isTrue(pr.Name.contains(season.Name), 'Price Request name should contain season name');
            Assert.areEqual(Date.today(), pr.Request_Date__c, 'Request date should be today');
            Assert.areEqual(season.Id, pr.Season__c, 'Season should match');
            Assert.areEqual('Spot', pr.Type__c, 'Type should be Spot');
            Assert.areEqual(true, pr.Show_Additional_Information__c, 'Show_Additional_Information__c should be true');
            Assert.isNotNull(pr.Portal_URL__c, 'Portal URL should be populated');
            Assert.isTrue(pr.Portal_URL__c.contains(pr.Id), 'Portal URL should contain Price Request Id');
        }
        
        // Verify Lane Prices were created
        List<Lane_Price__c> lanePrices = [
            SELECT Id, Lane__c, Price_Request__c, Type_Of_Trailer__c, Mandatory__c 
            FROM Lane_Price__c
        ];
        
        Integer expectedLanePrices = 2 * 2 * 3;
        Assert.areEqual(expectedLanePrices, lanePrices.size(), 'Should create 12 Lane Prices');
        
        // Verify all Lane Prices are mandatory
        for (Lane_Price__c lp : lanePrices) {
            Assert.areEqual(true, lp.Mandatory__c, 'All Lane Prices should be mandatory');
            Assert.isTrue(
                lp.Type_Of_Trailer__c == 'Frigo - chilled' || 
                lp.Type_Of_Trailer__c == 'Frigo - frozen' || 
                lp.Type_Of_Trailer__c == 'Dual temp',
                'Trailer type should be one of the specified types'
            );
        }
        
        // Verify each Price Request has the correct number of Lane Prices
        Map<Id, Integer> priceRequestLaneCounts = new Map<Id, Integer>();
        for (Lane_Price__c lp : lanePrices) {
            if (!priceRequestLaneCounts.containsKey(lp.Price_Request__c)) {
                priceRequestLaneCounts.put(lp.Price_Request__c, 0);
            }
            priceRequestLaneCounts.put(lp.Price_Request__c, priceRequestLaneCounts.get(lp.Price_Request__c) + 1);
        }
        
        for (Integer count : priceRequestLaneCounts.values()) {
            Assert.areEqual(6, count, 'Each Price Request should have 6 Lane Prices (2 products * 3 trailer types)');
        }
    }
    
    @isTest
    static void testCreatePriceRequests_WithNullAndEmptyInputs() {
        // Test 1: Null request list
        Test.startTest();
        List<List<Price_Request__c>> nullResults = STPQCreateMultiplePriceRequests.createPriceRequests(null);
        Test.stopTest();
        
        Assert.areEqual(1, nullResults.size(), 'Should return one list for null request');
        Assert.isTrue(nullResults[0].isEmpty(), 'Should return empty list for null request');
        
        // Test 2: Empty request list
        List<List<Price_Request__c>> emptyResults = STPQCreateMultiplePriceRequests.createPriceRequests(
            new List<STPQCreateMultiplePriceRequests.Request>()
        );
        
        Assert.areEqual(1, emptyResults.size(), 'Should return one list for empty request');
        Assert.isTrue(emptyResults[0].isEmpty(), 'Should return empty list for empty request');
        
        // Test 3: Null account IDs
        Season__c season = [SELECT Id FROM Season__c LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        
        STPQCreateMultiplePriceRequests.Request req1 = new STPQCreateMultiplePriceRequests.Request();
        req1.seasonId = season.Id;
        req1.accountIds = null;
        req1.productIds = new List<Id>{products[0].Id};
        req1.trailerTypesString = 'Box trailer';
        
        List<List<Price_Request__c>> nullAccountResults = STPQCreateMultiplePriceRequests.createPriceRequests(
            new List<STPQCreateMultiplePriceRequests.Request>{req1}
        );
        
        Assert.areEqual(1, nullAccountResults.size(), 'Should return one list for null account IDs');
        Assert.isTrue(nullAccountResults[0].isEmpty(), 'Should return empty list for null account IDs');
        
        // Test 4: Empty account IDs
        STPQCreateMultiplePriceRequests.Request req2 = new STPQCreateMultiplePriceRequests.Request();
        req2.seasonId = season.Id;
        req2.accountIds = new List<Id>();
        req2.productIds = new List<Id>{products[0].Id};
        req2.trailerTypesString = 'Frigo - chilled';
        
        List<List<Price_Request__c>> emptyAccountResults = STPQCreateMultiplePriceRequests.createPriceRequests(
            new List<STPQCreateMultiplePriceRequests.Request>{req2}
        );
        
        Assert.areEqual(1, emptyAccountResults.size(), 'Should return one list for empty account IDs');
        Assert.isTrue(emptyAccountResults[0].isEmpty(), 'Should return empty list for empty account IDs');
        
        // Test 5: Null product IDs
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        
        STPQCreateMultiplePriceRequests.Request req3 = new STPQCreateMultiplePriceRequests.Request();
        req3.seasonId = season.Id;
        req3.accountIds = new List<Id>{accounts[0].Id};
        req3.productIds = null;
        req3.trailerTypesString = 'Dual temp';
        
        List<List<Price_Request__c>> nullProductResults = STPQCreateMultiplePriceRequests.createPriceRequests(
            new List<STPQCreateMultiplePriceRequests.Request>{req3}
        );
        
        Assert.areEqual(1, nullProductResults.size(), 'Should return one list for null product IDs');
        Assert.isTrue(nullProductResults[0].isEmpty(), 'Should return empty list for null product IDs');
        
        // Verify no records were created in any of the tests
        List<Price_Request__c> allPriceRequests = [SELECT Id FROM Price_Request__c];
        Assert.isTrue(allPriceRequests.isEmpty(), 'No Price Requests should be created for invalid inputs');
        
        List<Lane_Price__c> allLanePrices = [SELECT Id FROM Lane_Price__c];
        Assert.isTrue(allLanePrices.isEmpty(), 'No Lane Prices should be created for invalid inputs');
    }
    
    @isTest
    static void testCreatePriceRequests_MultipleAccountsAndTrailerTypes() {
       
        Season__c season = [SELECT Id, Name FROM Season__c LIMIT 1];
        List<Account> accounts = [SELECT Id, Name FROM Account ORDER BY Name];
        List<Product2> products = [SELECT Id FROM Product2];
        
        STPQCreateMultiplePriceRequests.Request req = new STPQCreateMultiplePriceRequests.Request();
        req.seasonId = season.Id;
        req.accountIds = new List<Id>{accounts[0].Id, accounts[1].Id, accounts[2].Id};
        req.productIds = new List<Id>{products[0].Id};
        req.trailerTypesString = 'Frigo - chilled;Frigo - frozen;Dual temp;Box trailer';
        
        Test.startTest();
        List<List<Price_Request__c>> results = STPQCreateMultiplePriceRequests.createPriceRequests(
            new List<STPQCreateMultiplePriceRequests.Request>{req}
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.areEqual(3, results[0].size(), 'Should create 3 Price Requests (one per account)');
        
        // Verify Price Request naming convention
        Map<Id, String> accountNamesMap = new Map<Id, String>();
        for (Account acc : accounts) {
            accountNamesMap.put(acc.Id, acc.Name);
        }
        
        for (Price_Request__c pr : results[0]) {
            String expectedNamePattern = season.Name + ' - ';
            Assert.isTrue(pr.Name.startsWith(expectedNamePattern), 'Price Request name should start with season name');
            Assert.isTrue(
                accountNamesMap.containsKey(pr.Account__c),
                'Price Request should be linked to one of the input accounts'
            );
        }
        
        // Verify Lane Prices distribution
        List<Lane_Price__c> lanePrices = [
            SELECT Id, Lane__c, Price_Request__c, Type_Of_Trailer__c 
            FROM Lane_Price__c
            ORDER BY Price_Request__c, Type_Of_Trailer__c
        ];
        
        Integer expectedTotal = 3 * 1 * 4;
        Assert.areEqual(expectedTotal, lanePrices.size(), 'Should create 12 Lane Prices total');
        
        // Group Lane Prices by trailer type
        Map<String, Integer> trailerTypeCount = new Map<String, Integer>{
            'Frigo - chilled' => 0,
            'Frigo - frozen' => 0,
            'Dual temp' => 0,
            'Box trailer' => 0
        };
        
        for (Lane_Price__c lp : lanePrices) {
            if (trailerTypeCount.containsKey(lp.Type_Of_Trailer__c)) {
                trailerTypeCount.put(lp.Type_Of_Trailer__c, trailerTypeCount.get(lp.Type_Of_Trailer__c) + 1);
            }
        }
        
        // Each trailer type should appear exactly 3 times (once per account)
        for (String trailerType : trailerTypeCount.keySet()) {
            Assert.areEqual(
                3, 
                trailerTypeCount.get(trailerType), 
                'Each trailer type should appear exactly 3 times (once per Price Request)'
            );
        }
        
        // Verify all Lane Prices reference the same product
        Set<Id> uniqueProducts = new Set<Id>();
        for (Lane_Price__c lp : lanePrices) {
            uniqueProducts.add(lp.Lane__c);
        }
        
        Assert.areEqual(1, uniqueProducts.size(), 'All Lane Prices should reference the same product');
        Assert.areEqual(products[0].Id, new List<Id>(uniqueProducts)[0], 'Lane Prices should reference the specified product');
    }
}