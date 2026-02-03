@isTest
private class GetAccountDeliveryCountriesTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Transport Company',
            BillingCountryCode = 'NL',
            Destination_Country_Codes__c = 'NL;GB;DE;FR;BE'
        );
        insert testAccount;
    }
        
    @isTest
    static void testGetAccountDeliveryCountries_MultipleCountries() {
        Account testAccount = new Account(
            Name = 'Multi Destination Company',
            BillingCountryCode = 'NL',
            Destination_Country_Codes__c = 'NL;DE;BE;FR;GB;IT;ES'
        );
        insert testAccount;
        
        GetAccountDeliveryCountries.Input input = new GetAccountDeliveryCountries.Input();
        input.accountId = testAccount.Id;
        List<GetAccountDeliveryCountries.Input> inputs = new List<GetAccountDeliveryCountries.Input>{input};
        
        Test.startTest();
        List<GetAccountDeliveryCountries.Output> outputs = GetAccountDeliveryCountries.getAccountDeliveryCountries(inputs);
        Test.stopTest();
        
        Assert.isNotNull(outputs, 'Output should not be null');
        Assert.isTrue(outputs[0].keyValuePairs.size() > 0, 'Should return multiple countries');
    }
}