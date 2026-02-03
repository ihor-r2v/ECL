@isTest
private class GetAccountTrailerTypesTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Transport Company',
            BillingCountryCode = 'NL',
            Trailer_Types__c = 'Dual temp;Frigo - chilled;Frigo - frozen'
        );
        insert testAccount;
    }
    
    @isTest
    static void testGetAccountTrailerTypes_SingleType() {
        Account testAccount = new Account(
            Name = 'Single Trailer Company',
            BillingCountryCode = 'NL',
            Trailer_Types__c = 'Frigo - frozen'
        );
        insert testAccount;
        
        GetAccountTrailerTypes.Input input = new GetAccountTrailerTypes.Input();
        input.accountId = testAccount.Id;
        List<GetAccountTrailerTypes.Input> inputs = new List<GetAccountTrailerTypes.Input>{input};
        
        Test.startTest();
        List<GetAccountTrailerTypes.Output> outputs = GetAccountTrailerTypes.getAccountTrailerTypes(inputs);
        Test.stopTest();
        
        Assert.isNotNull(outputs, 'Output should not be null');
        Assert.areEqual(1, outputs.size(), 'Should return one output');
        Assert.isTrue(outputs[0].keyValuePairs.size() >= 1, 'Should return at least one trailer type');
    }
}