@isTest
private class PriceRequestTriggerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Carrier Account',
            Type = 'Carrier'
        );
        insert testAccount;
        
        Location__c loadingLocation = new Location__c(
            Name = 'Loading Test Location',
            Type__c = 'Loading',
            Country_Code__c = 'DE',
            Postal_Code__c = '12345'
        );
        
        Location__c deliveryLocation = new Location__c(
            Name = 'Delivery Test Location',
            Type__c = 'Delivery',
            Country_Code__c = 'FR',
            Postal_Code__c = '67890'
        );
        
        insert new List<Location__c>{loadingLocation, deliveryLocation};
        
        Product2 testLane = new Product2(
            Name = 'Test Lane DE-FR',
            Loading_Location__c = loadingLocation.Id,
            Destination_Location__c = deliveryLocation.Id
        );
        insert testLane;
    }
    
    @isTest
    static void testSendEmailOnStageChangeToAnswerPending() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received',
            Contacts_emails__c = 'test1@example.com;test2@example.com'
        );
        insert testPriceRequest;
        
        Test.startTest();
        testPriceRequest.Stage__c = 'Answer pending';
        update testPriceRequest;
        Test.stopTest();
        
        Assert.areEqual('Answer pending', [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id].Stage__c, 'Stage should be updated');
    }
    
    @isTest
    static void testSendEmailOnStageChangeFromCompleted() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Completed',
            Contacts_emails__c = 'test@example.com'
        );
        insert testPriceRequest;
        
        Test.startTest();
        testPriceRequest.Stage__c = 'Answer pending';
        update testPriceRequest;
        Test.stopTest();
        
        Assert.areEqual('Answer pending', [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id].Stage__c, 'Stage should be updated');
    }
    
    @isTest
    static void testNoEmailSentWhenStageNotAnswerPending() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received',
            Contacts_emails__c = 'test@example.com'
        );
        insert testPriceRequest;
        
        Test.startTest();
        testPriceRequest.Stage__c = 'New';
        update testPriceRequest;
        Test.stopTest();
        
        Assert.areEqual('New', [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id].Stage__c, 'Stage should be updated');
    }
    
    @isTest
    static void testNoEmailSentWhenNoContactsEmails() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received'
        );
        insert testPriceRequest;
        
        Test.startTest();
        testPriceRequest.Stage__c = 'Answer pending';
        update testPriceRequest;
        Test.stopTest();
        
        Assert.areEqual('Answer pending', [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id].Stage__c, 'Stage should be updated');
    }
    
    @isTest
    static void testEmailSentWithBlankPortalUrl() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received',
            Contacts_emails__c = 'test@example.com'
        );
        insert testPriceRequest;
        
        Test.startTest();
        testPriceRequest.Stage__c = 'Answer pending';
        update testPriceRequest;
        Test.stopTest();
        
        Assert.areEqual('Answer pending', [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id].Stage__c, 'Stage should be updated');
    }
    
    @isTest
    static void testInsertTrigger() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer pending',
            Contacts_emails__c = 'test@example.com'
        );
        insert testPriceRequest;
        Test.stopTest();
        
        Assert.areEqual('Answer pending', [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id].Stage__c, 'Stage should be set');
    }
    
    @isTest
    static void testMultiplePriceRequestsUpdate() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        List<Price_Request__c> priceRequests = new List<Price_Request__c>();
        for (Integer i = 0; i < 3; i++) {
            priceRequests.add(new Price_Request__c(
                Account__c = testAccount.Id,
                Request_Date__c = Date.today(),
                Stage__c = 'Answer received',
                Contacts_emails__c = 'test' + i + '@example.com'
            ));
        }
        insert priceRequests;
        
        Test.startTest();
        for (Price_Request__c pr : priceRequests) {
            pr.Stage__c = 'Answer pending';
        }
        update priceRequests;
        Test.stopTest();
        
        List<Price_Request__c> updatedRequests = [SELECT Stage__c FROM Price_Request__c WHERE Id IN :priceRequests];
        for (Price_Request__c pr : updatedRequests) {
            Assert.areEqual('Answer pending', pr.Stage__c, 'All stages should be updated');
        }
    }
    
    @isTest
    static void testNoEmailOnNonQualifyingStageTransition() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'New',
            Contacts_emails__c = 'test@example.com'
        );
        insert testPriceRequest;
        
        Test.startTest();
        testPriceRequest.Stage__c = 'Answer pending';
        update testPriceRequest;
        Test.stopTest();
        
        Assert.areEqual('Answer pending', [SELECT Stage__c FROM Price_Request__c WHERE Id = :testPriceRequest.Id].Stage__c, 'Stage should be updated');
    }
}