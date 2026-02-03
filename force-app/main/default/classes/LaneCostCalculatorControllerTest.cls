@isTest
private class LaneCostCalculatorControllerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Carrier Account',
            Type = 'Carrier',
            ETS__c = 15.0,
            Plug_in__c = 20.0,
            Tail_Lift__c = true,
            Pallet_Jack__c = true,
            Harbour_Dues__c = 25.0,
            Waiting_Hour__c = 30.0,
            Pallet_Exchange__c = true,
            Dangerous_Goods__c = true,
            Weekend_Charges__c = 35.0,
            Seasonal_Surcharge__c = 40.0,
            Diesel_mark_up_Price__c = 10.0,
            Overnight_charges_Price__c = 45.0,
            Dangerous_Goods_Price__c = 50.0,
            Pallet_Exchange_Price__c = 55.0,
            Tail_Lift_Price__c = 60.0,
            Pallet_Jack_Price__c = 65.0,
            Price_Ferry__c = 300,
            Price_2nd_Driver__c = 200,
            Price_Per_Stop__c = 100
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
            Destination_Location__c = deliveryLocation.Id,
            IsActive = true
        );
        insert testLane;

        Price_Request__c testPriceRequest = new Price_Request__c(
            Account__c = testAccount.Id,
            Request_Date__c = Date.today(),
            Stage__c = 'Answer received'
        );
        insert testPriceRequest;

        Lane_Price__c testLanePrice = new Lane_Price__c(
            Price_Request__c = testPriceRequest.Id,
            Lane__c = testLane.Id,
            Mandatory__c = true,
            Two_Drivers__c = true,
            Direct_Ferry__c = true,
            Freight_Price__c = 1000,
            Type_Of_Trailer__c = 'Frigo - chilled',
            Additional_Stops__c = 100
        );
        insert testLanePrice;
    }

    @isTest
    static void testGetLanePriceAndAccountSuccess() {
        Lane_Price__c testLanePrice = [SELECT Id FROM Lane_Price__c LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        LaneCostCalculatorController.LanePriceAccountWrapper result = LaneCostCalculatorController.getLanePriceAndAccount(testLanePrice.Id, testAccount.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.lanePrice, 'Lane price should not be null');
        Assert.isNotNull(result.account, 'Account should not be null');

        Assert.areEqual(testLanePrice.Id, result.lanePrice.Id, 'Lane price ID should match');
        Assert.isTrue(result.lanePrice.Mandatory__c, 'Lane should be mandatory');
        Assert.areEqual(1000, result.lanePrice.Freight_Price__c, 'Freight price should match');
        Assert.areEqual('Frigo - chilled', result.lanePrice.Type_Of_Trailer__c, 'Trailer type should match');

        Assert.areEqual(testAccount.Id, result.account.Id, 'Account ID should match');
        Assert.areEqual('Test Carrier Account', result.account.Name, 'Account name should match');
        Assert.areEqual('Carrier', result.account.Type, 'Account type should match');
        Assert.areEqual(15.0, result.account.ETS__c, 'ETS should match');
        Assert.areEqual(20.0, result.account.Plug_in__c, 'Plug in should match');
        Assert.isTrue(result.account.Tail_Lift__c, 'Tail lift should be true');
        Assert.isTrue(result.account.Pallet_Jack__c, 'Pallet jack should be true');
        Assert.areEqual(25.0, result.account.Harbour_Dues__c, 'Harbour dues should match');
        Assert.areEqual(30.0, result.account.Waiting_Hour__c, 'Waiting hour should match');
        Assert.isTrue(result.account.Pallet_Exchange__c, 'Pallet exchange should be true');
        Assert.isTrue(result.account.Dangerous_Goods__c, 'Dangerous goods should be true');
        Assert.areEqual(35.0, result.account.Weekend_Charges__c, 'Weekend charges should match');
        Assert.areEqual(40.0, result.account.Seasonal_Surcharge__c, 'Seasonal surcharge should match');
        Assert.areEqual(10.0, result.account.Diesel_mark_up_Price__c, 'Diesel markup price should match');
        Assert.areEqual(45.0, result.account.Overnight_charges_Price__c, 'Overnight charges price should match');
        Assert.areEqual(50.0, result.account.Dangerous_Goods_Price__c, 'Dangerous goods price should match');
        Assert.areEqual(55.0, result.account.Pallet_Exchange_Price__c, 'Pallet exchange price should match');
        Assert.areEqual(60.0, result.account.Tail_Lift_Price__c, 'Tail lift price should match');
        Assert.areEqual(65.0, result.account.Pallet_Jack_Price__c, 'Pallet jack price should match');
    }

    @isTest
    static void testLanePriceAccountWrapperConstructor() {
        Lane_Price__c testLanePrice = [SELECT Id, Lane_Name__c, Mandatory__c FROM Lane_Price__c LIMIT 1];
        Account testAccount = [SELECT Id, Name, Type FROM Account LIMIT 1];

        Test.startTest();
        LaneCostCalculatorController.LanePriceAccountWrapper wrapper = new LaneCostCalculatorController.LanePriceAccountWrapper(testLanePrice, testAccount);
        Test.stopTest();

        Assert.isNotNull(wrapper, 'Wrapper should not be null');
        Assert.areEqual(testLanePrice.Id, wrapper.lanePrice.Id, 'Lane price should match');
        Assert.areEqual(testAccount.Id, wrapper.account.Id, 'Account should match');
    }
}