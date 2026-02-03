@isTest
private class STPQGetAccountsByDeliveryCodesActionTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts with various combinations of delivery codes and trailer types
        List<Account> testAccounts = new List<Account>();
        
        // Account with multiple European country codes and trailer types
        testAccounts.add(new Account(
            Name = 'Test Account 1',
            Type = 'Customer',
            Destination_Country_Codes__c = 'DE;FR;NL',
            Trailer_Types__c = 'Frigo - chilled;Frigo - frozen'
        ));
        
        // Account with single country code and trailer type
        testAccounts.add(new Account(
            Name = 'Test Account 2',
            Type = 'Prospect',
            Destination_Country_Codes__c = 'PL',
            Trailer_Types__c = 'Box trailer'
        ));
        
        // Account with different combinations
        testAccounts.add(new Account(
            Name = 'Test Account 3',
            Type = 'Customer',
            Destination_Country_Codes__c = 'IT;ES;PT',
            Trailer_Types__c = 'Frigo - chilled;Dual temp;Box trailer'
        ));
        
        // Account with multiple Western European countries
        testAccounts.add(new Account(
            Name = 'Test Account 4',
            Type = 'Customer',
            Destination_Country_Codes__c = 'BE;LU;NL;DE',
            Trailer_Types__c = 'Dual temp;Frigo - frozen'
        ));
        
        // Account with Central/Eastern European countries
        testAccounts.add(new Account(
            Name = 'Test Account 5',
            Type = 'Prospect',
            Destination_Country_Codes__c = 'CZ;SK;HU;AT',
            Trailer_Types__c = 'Frigo - chilled;Box trailer'
        ));
        
        // Account with Nordic countries
        testAccounts.add(new Account(
            Name = 'Test Account 6',
            Type = 'Customer',
            Destination_Country_Codes__c = 'SE;NO;DK;FI',
            Trailer_Types__c = 'Frigo - frozen;Dual temp'
        ));
        
        // Account with only country codes, no trailer types
        testAccounts.add(new Account(
            Name = 'Test Account 7',
            Type = 'Customer',
            Destination_Country_Codes__c = 'GB;IE',
            Trailer_Types__c = null
        ));
        
        // Account without matching criteria
        testAccounts.add(new Account(
            Name = 'Test Account 8',
            Type = 'Prospect',
            Destination_Country_Codes__c = 'RO;BG',
            Trailer_Types__c = 'Frigo - chilled'
        ));
        
        insert testAccounts;
    }
    
    @isTest
    static void testGetAccounts_WithValidCountryCodesAndTrailerTypes() {
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'DE', 'FR'};
        req.trailerTypesString = 'Frigo - chilled;Frigo - frozen';
        
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one list of accounts');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        // Verify the account has all required fields
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Destination_Country_Codes__c.contains('DE') && 
                acc.Destination_Country_Codes__c.contains('FR'),
                'Account should contain both DE and FR country codes'
            );
            Assert.isTrue(
                acc.Trailer_Types__c.contains('Frigo - chilled') && 
                acc.Trailer_Types__c.contains('Frigo - frozen'),
                'Account should contain both Frigo - chilled and Frigo - frozen trailer types'
            );
        }
    }
    
    @isTest
    static void testGetAccounts_WithSingleCountryCodeAndBoxTrailer() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'PL'};
        req.trailerTypesString = 'Box trailer';
              
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Destination_Country_Codes__c.contains('PL'),
                'Account should contain PL country code'
            );
            Assert.isTrue(
                acc.Trailer_Types__c.contains('Box trailer'),
                'Account should contain Box trailer type'
            );
        }
    }
    
    @isTest
    static void testGetAccounts_WithDualTempTrailer() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'IT', 'ES'};
        req.trailerTypesString = 'Dual temp;Frigo - chilled';
        
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
              
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Destination_Country_Codes__c.contains('IT') &&
                acc.Destination_Country_Codes__c.contains('ES'),
                'Account should contain IT and ES country codes'
            );
            Assert.isTrue(
                acc.Trailer_Types__c.contains('Dual temp') &&
                acc.Trailer_Types__c.contains('Frigo - chilled'),
                'Account should contain Dual temp and Frigo - chilled trailer types'
            );
        }
    }
    
    @isTest
    static void testGetAccounts_WithCountryCodesOnly() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'BE', 'NL'};
        req.trailerTypesString = '';
               
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
               
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Destination_Country_Codes__c.contains('BE') &&
                acc.Destination_Country_Codes__c.contains('NL'),
                'Account should contain BE and NL country codes'
            );
        }
    }
    
    @isTest
    static void testGetAccounts_WithNullRequest() {
        
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(null);
        Test.stopTest();
             
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isTrue(results[0].isEmpty(), 'Should return empty list for null request');
    }
    
    @isTest
    static void testGetAccounts_WithEmptyRequestList() {
        
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>()
        );
        Test.stopTest();
               
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isTrue(results[0].isEmpty(), 'Should return empty list for empty request');
    }
    
    @isTest
    static void testGetAccounts_WithNullCountryCodes() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = null;
        req.trailerTypesString = 'Frigo - frozen';
              
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
        
        
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isTrue(results[0].isEmpty(), 'Should return empty list for null country codes');
    }
    
    @isTest
    static void testGetAccounts_WithEmptyCountryCodes() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>();
        req.trailerTypesString = 'Box trailer';
              
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
              
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isTrue(results[0].isEmpty(), 'Should return empty list for empty country codes');
    }
    
    @isTest
    static void testGetAccounts_NoMatchingAccounts() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'ZZ', 'YY'}; // Non-existent codes
        req.trailerTypesString = 'NonExistentTrailerType';
              
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
              
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isTrue(results[0].isEmpty(), 'Should return empty list when no matches found');
    }
    
    @isTest
    static void testGetAccounts_MultipleCountryCodesAndTrailerTypes() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'SE', 'NO', 'DK'};
        req.trailerTypesString = 'Frigo - frozen;Dual temp';
            
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
              
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Destination_Country_Codes__c.contains('SE') &&
                acc.Destination_Country_Codes__c.contains('NO') &&
                acc.Destination_Country_Codes__c.contains('DK'),
                'Account should contain all Nordic country codes'
            );
            Assert.isTrue(
                acc.Trailer_Types__c.contains('Frigo - frozen') &&
                acc.Trailer_Types__c.contains('Dual temp'),
                'Account should contain both Frigo - frozen and Dual temp trailer types'
            );
        }
    }
    
    @isTest
    static void testGetAccounts_AllTrailerTypes() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'IT'};
        req.trailerTypesString = 'Frigo - chilled;Dual temp;Box trailer';
             
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
              
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Trailer_Types__c.contains('Frigo - chilled') &&
                acc.Trailer_Types__c.contains('Dual temp') &&
                acc.Trailer_Types__c.contains('Box trailer'),
                'Account should contain all three trailer types'
            );
        }
    }
    
    @isTest
    static void testGetAccounts_CentralEuropeanCountries() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'CZ', 'SK', 'HU'};
        req.trailerTypesString = 'Frigo - chilled';
              
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
              
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Destination_Country_Codes__c.contains('CZ') &&
                acc.Destination_Country_Codes__c.contains('SK') &&
                acc.Destination_Country_Codes__c.contains('HU'),
                'Account should contain CZ, SK, and HU country codes'
            );
            Assert.isTrue(
                acc.Trailer_Types__c.contains('Frigo - chilled'),
                'Account should contain Frigo - chilled trailer type'
            );
        }
    }
    
    @isTest
    static void testGetAccounts_ResultsOrderedByName() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'DE'};
        req.trailerTypesString = '';
              
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
              
        if (results[0].size() > 1) {
            for (Integer i = 0; i < results[0].size() - 1; i++) {
                Assert.isTrue(
                    results[0][i].Name <= results[0][i + 1].Name,
                    'Results should be ordered by Name ascending'
                );
            }
        }
    }
    
    @isTest
    static void testGetAccounts_VerifyReturnedFields() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'DE'};
        req.trailerTypesString = 'Frigo - chilled';
            
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
               
        if (!results[0].isEmpty()) {
            Account acc = results[0][0];
            Assert.isNotNull(acc.Id, 'Account Id should be returned');
            Assert.isNotNull(acc.Name, 'Account Name should be returned');
            Assert.isNotNull(acc.Type, 'Account Type should be returned');
            Assert.isNotNull(acc.Destination_Country_Codes__c, 'Destination_Country_Codes__c should be returned');
        }
    }
    
    @isTest
    static void testGetAccounts_BeneluxCountries() {
        
        STPQGetAccountsByDeliveryCodesAction.Request req = new STPQGetAccountsByDeliveryCodesAction.Request();
        req.deliveryCountryCodes = new List<String>{'BE', 'NL', 'LU'};
        req.trailerTypesString = 'Dual temp';
        
        Test.startTest();
        List<List<Account>> results = STPQGetAccountsByDeliveryCodesAction.getAccounts(
            new List<STPQGetAccountsByDeliveryCodesAction.Request>{req}
        );
        Test.stopTest();
          
        Assert.areEqual(1, results.size(), 'Should return one list');
        Assert.isFalse(results[0].isEmpty(), 'Should find matching accounts');
        
        for (Account acc : results[0]) {
            Assert.isTrue(
                acc.Destination_Country_Codes__c.contains('BE') &&
                acc.Destination_Country_Codes__c.contains('NL') &&
                acc.Destination_Country_Codes__c.contains('LU'),
                'Account should contain Benelux country codes'
            );
            Assert.isTrue(
                acc.Trailer_Types__c.contains('Dual temp'),
                'Account should contain Dual temp trailer type'
            );
        }
    }
}