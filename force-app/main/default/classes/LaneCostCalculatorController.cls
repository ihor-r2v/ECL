public without sharing class LaneCostCalculatorController {
    @AuraEnabled(cacheable=true)
    public static LanePriceAccountWrapper getLanePriceAndAccount(Id lanePriceId, Id accountId) {
        Lane_Price__c lanePrice = [
            SELECT Id,
                Lane_Name__c,
                Mandatory__c,
                Two_Drivers__c,
                Direct_Ferry__c,
                Freight_Price__c,
                Type_Of_Trailer__c,
                Loading_Postal_Code__c,
                Delivery_Postal_Code__c
            FROM Lane_Price__c
            WHERE Id = :lanePriceId
            LIMIT 1
        ];

        Account acc = [
            SELECT Id,
                Name,
                Type,
                Fuel_surcharge_percentage__c,
                ETS__c,
                Plug_in__c,
                Tail_Lift__c,
                Pallet_Jack__c,
                Harbour_Dues__c,
                Waiting_Hour__c,
                Pallet_Exchange__c,
                Dangerous_Goods__c,
                Weekend_Charges__c,
                Seasonal_Surcharge__c,
                Diesel_mark_up_Price__c,
                Overnight_charges_Price__c,
                Dangerous_Goods_Price__c, 
                Pallet_Exchange_Price__c,
                Tail_Lift_Price__c,
                Pallet_Jack_Price__c,
                Price_Ferry__c,
                Price_2nd_Driver__c,
                Price_Per_Stop__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        return new LanePriceAccountWrapper(lanePrice, acc);
    }

    public class LanePriceAccountWrapper {
        @AuraEnabled public Lane_Price__c lanePrice { get; set; }
        @AuraEnabled public Account account { get; set; }

        public LanePriceAccountWrapper(Lane_Price__c lp, Account acc) {
            this.lanePrice = lp;
            this.account = acc;
        }
    } 
}