@isTest
private class TPQCheckAccountTrailerTypesTest {
    
    @isTest
    static void testAllSelectedTrailerTypesValid() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp;Frigo - chilled;Standard';
        req.selectedTrailerTypesString = 'Dual temp;Frigo - chilled';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isTrue(results[0].valid, 'Should be valid when at least one selected type matches');
    }
    
    @isTest
    static void testSingleMatchingTrailerType() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp;Frigo - chilled';
        req.selectedTrailerTypesString = 'Dual temp';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should be valid for single matching trailer type');
    }
    
    @isTest
    static void testPartialMatch() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp;Frigo - chilled';
        req.selectedTrailerTypesString = 'Dual temp;Standard;Box truck';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should be valid when at least one type matches (Dual temp)');
    }
    
    @isTest
    static void testNoMatchingTrailerTypes() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp;Frigo - chilled';
        req.selectedTrailerTypesString = 'Standard;Box truck';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isFalse(results[0].valid, 'Should be invalid when no selected types match account types');
    }
    
    @isTest
    static void testCaseInsensitiveMatching() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual Temp;FRIGO - CHILLED';
        req.selectedTrailerTypesString = 'dual temp;frigo - chilled';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should match trailer types case-insensitively');
    }
    
    @isTest
    static void testWhitespaceHandling() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = '  Dual temp  ;  Frigo - chilled  ';
        req.selectedTrailerTypesString = 'Dual temp;Frigo - chilled';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should handle whitespace correctly and find match');
    }
    
    @isTest
    static void testEmptySelectedTrailerTypes() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp;Frigo - chilled';
        req.selectedTrailerTypesString = '';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isFalse(results[0].valid, 'Should be invalid when selected types are empty');
    }
    
    @isTest
    static void testEmptyAccountTrailerTypes() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = '';
        req.selectedTrailerTypesString = 'Dual temp';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isFalse(results[0].valid, 'Should be invalid when account types are empty');
    }
    
    @isTest
    static void testNullAccountTrailerTypes() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = null;
        req.selectedTrailerTypesString = 'Dual temp';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isFalse(results[0].valid, 'Should be invalid when account types are null');
    }
    
    @isTest
    static void testNullSelectedTrailerTypes() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp';
        req.selectedTrailerTypesString = null;
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isFalse(results[0].valid, 'Should be invalid when selected types are null');
    }
    
    @isTest
    static void testEmptyRequestList() {
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>()
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isFalse(results[0].valid, 'Should be invalid when request list is empty');
    }
    
    @isTest
    static void testNullRequestList() {
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(null);
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one response');
        Assert.isFalse(results[0].valid, 'Should be invalid when request list is null');
    }
    
    @isTest
    static void testMultipleRequests() {
        TPQCheckAccountTrailerTypes.Request req1 = new TPQCheckAccountTrailerTypes.Request();
        req1.accountTrailerTypesString = 'Dual temp;Frigo - chilled';
        req1.selectedTrailerTypesString = 'Dual temp';
        
        TPQCheckAccountTrailerTypes.Request req2 = new TPQCheckAccountTrailerTypes.Request();
        req2.accountTrailerTypesString = 'Standard';
        req2.selectedTrailerTypesString = 'Box truck';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req1, req2 }
        );
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should process only first request');
        Assert.isTrue(results[0].valid, 'Should validate first request correctly');
    }
    
    @isTest
    static void testSingleTrailerTypeExactMatch() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp';
        req.selectedTrailerTypesString = 'Dual temp';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should be valid for exact single match');
    }
    
    @isTest
    static void testTrailingDelimiters() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp;Frigo - chilled;';
        req.selectedTrailerTypesString = 'Dual temp;';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should handle trailing delimiters and find match');
    }
    
    @isTest
    static void testMultipleDelimiters() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Dual temp;;Frigo - chilled';
        req.selectedTrailerTypesString = 'Frigo - chilled';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should handle multiple delimiters and find match');
    }
    
    @isTest
    static void testRequestAndResponseClasses() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Test';
        req.selectedTrailerTypesString = 'Test';
        
        TPQCheckAccountTrailerTypes.Response res = new TPQCheckAccountTrailerTypes.Response();
        res.valid = true;
        
        Assert.areEqual('Test', req.accountTrailerTypesString, 'Request account types should be set');
        Assert.areEqual('Test', req.selectedTrailerTypesString, 'Request selected types should be set');
        Assert.isTrue(res.valid, 'Response valid should be set');
    }
    
    @isTest
    static void testFirstMatchWins() {
        TPQCheckAccountTrailerTypes.Request req = new TPQCheckAccountTrailerTypes.Request();
        req.accountTrailerTypesString = 'Standard;Dual temp;Frigo - chilled';
        req.selectedTrailerTypesString = 'Standard;Invalid1;Invalid2';
        
        Test.startTest();
        List<TPQCheckAccountTrailerTypes.Response> results = TPQCheckAccountTrailerTypes.checkTrailerTypes(
            new List<TPQCheckAccountTrailerTypes.Request>{ req }
        );
        Test.stopTest();
        
        Assert.isTrue(results[0].valid, 'Should be valid when first selected type matches');
    }
}