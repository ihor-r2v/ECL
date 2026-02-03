@IsTest
private class AccountAccessCodeActionTest {
    
    @IsTest
    static void testGeneratePortalAccessCode_OnAccountCreation() {

        Account newAccount = new Account(
            Name = 'Test Account for Flow'
        );
        
        Test.startTest();
        insert newAccount;
        
        AccountAccessCodeAction.Request request = new AccountAccessCodeAction.Request();
        request.accountId = newAccount.Id;
        List<AccountAccessCodeAction.Request> requestList = new List<AccountAccessCodeAction.Request>{request};
        
        AccountAccessCodeAction.generatePortalAccessCode(requestList);
        Test.stopTest();
        
        Account updatedAccount = [SELECT Id, Access_code__c FROM Account WHERE Id = :newAccount.Id];
        Assert.isNotNull(updatedAccount.Access_code__c, 'Access code should be generated after account creation');
        Assert.areEqual(9, updatedAccount.Access_code__c.length(), 'Access code should be 9 characters long');
        assertValidAccessCode(updatedAccount.Access_code__c);
    }
    
    @IsTest
    static void testGeneratePortalAccessCode_MultipleAccountsCreated() {

        List<Account> accountsToInsert = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2'),
            new Account(Name = 'Test Account 3')
        };
        
        Test.startTest();
        insert accountsToInsert;
        
        for (Account acc : accountsToInsert) {
            AccountAccessCodeAction.Request request = new AccountAccessCodeAction.Request();
            request.accountId = acc.Id;
            AccountAccessCodeAction.generatePortalAccessCode(new List<AccountAccessCodeAction.Request>{request});
        }
        Test.stopTest();
        
        List<Account> updatedAccounts = [SELECT Id, Name, Access_code__c FROM Account WHERE Id IN :accountsToInsert ORDER BY Name];
        Assert.areEqual(3, updatedAccounts.size(), 'Should have 3 accounts');
        
        Set<String> generatedCodes = new Set<String>();
        for (Account acc : updatedAccounts) {
            Assert.isNotNull(acc.Access_code__c, 'Access code should be generated for account: ' + acc.Name);
            Assert.areEqual(9, acc.Access_code__c.length(), 'Access code should be 9 characters for: ' + acc.Name);
            assertValidAccessCode(acc.Access_code__c);
            generatedCodes.add(acc.Access_code__c);
        }
        
        Assert.areEqual(3, generatedCodes.size(), 'Generated codes should be unique');
    }
    
    private static void assertValidAccessCode(String code) {
        Assert.areEqual(9, code.length(), 'Code must be 9 characters');
        
        String validChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        for (Integer i = 0; i < code.length(); i++) {
            String character = code.substring(i, i + 1);
            Assert.isTrue(validChars.contains(character), 
                'Code should only contain valid characters (A-Z, 0-9). Found: ' + character);
        }
    }
}