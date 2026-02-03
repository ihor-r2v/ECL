public without sharing class LaneSelectorController {
    
    @AuraEnabled(cacheable=true)
    public static List<Location__c> getLocations() {
        try {
            return [
                SELECT Id, Name, Type__c, Country_Code__c, Postal_Code__c 
                FROM Location__c 
                ORDER BY Name ASC 
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving locations: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Account> getMatchingAccounts(String loadingLocationId, String deliveryLocationId) {
        try {            
            return [SELECT Id, Name, Type FROM Account];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving matching accounts: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Season__c> getSeasons() {
        try {            
            return [
                SELECT Id, Name, Status__c 
                FROM Season__c 
                WHERE Status__c = 'Active' 
                    AND Start_Date__c <= :Date.today() 
                    AND End_Date__c >= :Date.today()
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving seasons: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Season__c> getSpotSeasons() {
        try {            
            return [
                SELECT Id, Name, Status__c 
                FROM Season__c 
                WHERE Type__c = 'Spot'
                    AND Status__c = 'Active' 
                    AND Start_Date__c <= :Date.today() 
                    AND End_Date__c >= :Date.today()
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving seasons: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Season__c> getTenderSeasons() {
        try {            
            return [
                SELECT Id, Name, Status__c 
                FROM Season__c 
                WHERE Type__c = 'Tender'
                    AND Status__c = 'Active' 
                    AND Start_Date__c <= :Date.today() 
                    AND End_Date__c >= :Date.today()
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving seasons: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Location__c> getDeliveryLocations(String type, String searchKey) {
        String likeKey = '%' + searchKey + '%';
        return [
            SELECT Id, Name 
            FROM Location__c
            WHERE Type__c = :type
            AND Name LIKE :likeKey
            ORDER BY Name
            LIMIT 1000
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getTrailerTypePicklistValues(){
        List<String> picklistValues = new List<String>();

        for(Schema.PicklistEntry plE : Account.Trailer_Types__c.getDescribe().getPicklistValues()){
            picklistValues.add(plE.getValue());
        }

        return picklistValues;
    }

    @AuraEnabled
    public static void deleteLocation(Id locationId, String type) {
        if (locationId == null) {
            throw new AuraHandledException('No Location selected.');
        }

        try {
            List<Product2> productsToDelete = new List<Product2>();
            if (type == 'Loading') {
                productsToDelete = [SELECT Id FROM Product2 WHERE Loading_Location__c = :locationId];
            } else if (type == 'Delivery') {
                productsToDelete = [SELECT Id FROM Product2 WHERE Destination_Location__c = :locationId];
            }

            deleteOpportunityProducts(productsToDelete);
            deleteProducts(productsToDelete);
            deleteLocationRecord(locationId);

        } catch(Exception e) {
            throw new AuraHandledException('Error deleting Location: ' + e.getMessage());
        }
    }

    private static void deleteOpportunityProducts(List<Product2> productsToDelete) {
        if (productsToDelete.isEmpty()) return;

        try {
            List<OpportunityLineItem> oppLineItems = [
                SELECT Id FROM OpportunityLineItem WHERE Product2Id IN :productsToDelete
            ];
            if (!oppLineItems.isEmpty()) {
                delete oppLineItems;
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting Opportunity Products: ' + e.getMessage());
        }
    }

    private static void deleteProducts(List<Product2> productsToDelete) {
        if (productsToDelete.isEmpty()) return;
        try {
            delete productsToDelete;
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting Products: ' + e.getMessage());
        }
    }

    private static void deleteLocationRecord(Id locationId) {
        try {
            delete [SELECT Id FROM Location__c WHERE Id = :locationId];
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting Location record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void createPreferredSupplier(
        String accountId, 
        String lanePriceId, 
        String loadingLocationId, 
        String deliveryLocationId, 
        String trailerType,
        Decimal totalPrice,
        String seasonId,
        String psConfigs
    ) {
        try {  
            Product2 product = [
                SELECT Id, Name
                FROM Product2 
                WHERE Loading_Location__c = :loadingLocationId 
                    AND Destination_Location__c = :deliveryLocationId 
                LIMIT 1
            ];

            List<Preferred_Supplier__c> recordsToDelete = new List<Preferred_Supplier__c>();
            List<Lane_Price__c> recordsToUpdate = new List<Lane_Price__c>();
            
            // Query old preferred supplier records to delete
            recordsToDelete = [
                SELECT Id 
                FROM Preferred_Supplier__c 
                WHERE Lane__c = :product.Id
                    AND Trailer_Type__c = :trailerType
                    AND Season__c = :seasonId
            ];

            // Query lane prices to update
            List<Lane_Price__c> lanePrices = [
                SELECT Id, PreferredCarrier__c 
                FROM Lane_Price__c 
                WHERE Lane__c = :product.Id 
                    AND Type_Of_Trailer__c = :trailerType 
                    AND Price_Request__r.Season__c = :seasonId
            ];
            
            // Prepare lane prices for update
            for (Lane_Price__c lp : lanePrices) {
                lp.PreferredCarrier__c = (lp.Id == lanePriceId);
                recordsToUpdate.add(lp);
            }

            // Create new preferred supplier
            Preferred_Supplier__c ps = new Preferred_Supplier__c(
                Name = product.Name,
                Account__c = accountId,
                Lane_Price__c = lanePriceId,
                Lane__c = product.Id,
                Trailer_Type__c = trailerType,
                Total_Freight_Price__c = totalPrice,
                Season__c = seasonId
            );

            // Perform DML operations in order
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
            
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
            
            insert ps;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Preferred Supplier: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<LaneResult> getMatchingLanes(String loadingLocationId, String deliveryLocationId, String seasonId, String trailerTypeName) {
        try { 
            LaneResult result = new LaneResult();
            Id productId = [SELECT Id FROM Product2 WHERE Loading_Location__c = :loadingLocationId AND Destination_Location__c = :deliveryLocationId LIMIT 1].Id;
            
            List<Lane_Price__c> allPrices = [
                SELECT Id,
                    Freight_Price__c,
                    Type_Of_Trailer__c,
                    PreferredCarrier__c,
                    Supplier_Name__c, 
                    Loading_Postal_Code__c,
                    Delivery_Postal_Code__c,
                    Lane__r.Name,
                    Lane__r.Loading_Location__r.Country_Code__c,
                    Lane__r.Destination_Location__r.Country_Code__c,
                    Price_Request__c, 
                    Price_Request__r.Account__c, 
                    Price_Request__r.Account__r.Name,
                    Price_Request__r.Account__r.Fuel_surcharge_percentage__c,
                    Price_Request__r.Account__r.ETS__c,
                    Price_Request__r.Account__r.Plug_in__c,
                    Price_Request__r.Account__r.Harbour_Dues__c,
                    Price_Request__r.Account__r.Overnight_charges_Price__c,
                    Price_Request__r.Account__r.Waiting_Hour__c,
                    Price_Request__r.Account__r.Seasonal_Surcharge__c,
                    Price_Request__r.Account__r.Weekend_Charges__c,
                    Price_Request__r.Account__r.Dangerous_Goods_Price__c,
                    Price_Request__r.Account__r.Pallet_Exchange_Price__c,
                    Price_Request__r.Account__r.Pallet_Jack_Price__c,
                    Price_Request__r.Account__r.Tail_Lift_Price__c,
                    Price_Request__r.Account__r.Price_Ferry__c,
                    Price_Request__r.Account__r.Price_2nd_Driver__c,
                    Price_Request__r.Account__r.Price_Per_Stop__c,
                    Price_Request__r.Season__r.Name
                FROM Lane_Price__c 
                WHERE Lane__c = :productId 
                    AND Price_Request__r.Season__c = :seasonId
                    AND Type_Of_Trailer__c = :trailerTypeName
                ORDER BY Freight_Price__c ASC 
                NULLS LAST
            ];
            
            // Separate prices into three categories
            List<Lane_Price__c> positivePrices = new List<Lane_Price__c>();
            List<Lane_Price__c> zeroPrices = new List<Lane_Price__c>();
            List<Lane_Price__c> nullPrices = new List<Lane_Price__c>();
            
            for (Lane_Price__c lp : allPrices) {
                if (lp.Freight_Price__c == null) {
                    nullPrices.add(lp);
                } else if (lp.Freight_Price__c == 0) {
                    zeroPrices.add(lp);
                } else {
                    positivePrices.add(lp);
                }
            }
            
            // Combine in desired order: positive prices, then zeros, then nulls
            List<Lane_Price__c> prices = new List<Lane_Price__c>();
            prices.addAll(positivePrices);
            prices.addAll(zeroPrices);
            prices.addAll(nullPrices);
            
            Map<Id, LaneResult> resultsByAccount = new Map<Id, LaneResult>();

            for (Lane_Price__c lp : prices) {
                Id accId = lp.Price_Request__r?.Account__c;
                if (accId == null) continue;

                if (!resultsByAccount.containsKey(accId)) {
                    LaneResult res = new LaneResult();
                    res.accountId = accId;
                    res.priceRequestId = lp.Price_Request__c;
                    res.preferredCarrier = lp.PreferredCarrier__c;
                    res.laneName = lp.Lane__r?.Name;
                    res.lanePrice = lp.Freight_Price__c;
                    res.loadingPC = lp.Loading_Postal_Code__c;
                    res.deliveryPC = lp.Delivery_Postal_Code__c;
                    res.accountName = lp.Price_Request__r?.Account__r?.Name;
                    res.fuelSurchargePercentage = lp.Price_Request__r?.Account__r?.Fuel_surcharge_percentage__c;
                    res.ets = lp.Price_Request__r?.Account__r?.ETS__c;
                    res.plugIn = lp.Price_Request__r?.Account__r?.Plug_in__c;
                    res.harbourDues = lp.Price_Request__r?.Account__r?.Harbour_Dues__c;
                    res.overnightPrice = lp.Price_Request__r?.Account__r?.Overnight_charges_Price__c;
                    res.waitingHour = lp.Price_Request__r?.Account__r?.Waiting_Hour__c;
                    res.seasonalSurcharge = lp.Price_Request__r?.Account__r?.Seasonal_Surcharge__c;
                    res.weekendCharges = lp.Price_Request__r?.Account__r?.Weekend_Charges__c;
                    res.dangerousGoods = lp.Price_Request__r?.Account__r?.Dangerous_Goods_Price__c;
                    res.palletExchange = lp.Price_Request__r?.Account__r?.Pallet_Exchange_Price__c;
                    res.palletJack = lp.Price_Request__r?.Account__r?.Pallet_Jack_Price__c;
                    res.tailLift = lp.Price_Request__r?.Account__r?.Tail_Lift_Price__c;
                    res.priceFerry = lp.Price_Request__r?.Account__r?.Price_Ferry__c;
                    res.price2ndDriver = lp.Price_Request__r?.Account__r?.Price_2nd_Driver__c;
                    res.pricePerStop = lp.Price_Request__r?.Account__r?.Price_Per_Stop__c;
                    res.seasonName = lp.Price_Request__r?.Season__r?.Name;
                    res.trailerTypes = new List<TrailerType>();
                    
                    resultsByAccount.put(accId, res);
                }

                LaneResult existing = resultsByAccount.get(accId);

                TrailerType trailerType = new TrailerType();
                trailerType.laneId = lp.Id;
                String type = lp.Type_Of_Trailer__c == null ? 'Not Specified' : lp.Type_Of_Trailer__c;
                trailerType.type = type;
                trailerType.price = lp.Freight_Price__c;
                existing.trailerTypes.add(trailerType);
            }

            if (!resultsByAccount.isEmpty()) {
                Set<Id> accountIds = resultsByAccount.keySet();

                List<AggregateResult> agg = [
                    SELECT Carrier__c carrierId,
                        AVG(Reliability_Score__c) avgReliability,
                        AVG(Price_Level_Percentage__c) avgPrice,
                        AVG(Availability_Score_Percentage__c) avgAvailability
                    FROM Carrier_Score__c
                    WHERE Carrier__c IN :accountIds
                    GROUP BY Carrier__c
                ];

                Map<Id, AccountScore> scoresByAccount = new Map<Id, AccountScore>();
                for (AggregateResult ar : agg) {
                    Id acctId = (Id) ar.get('carrierId');
                    Decimal avgRel = (Decimal) ar.get('avgReliability');
                    Decimal avgP = (Decimal) ar.get('avgPrice');
                    Decimal avgA = (Decimal) ar.get('avgAvailability');

                    AccountScore sc = new AccountScore();
                    sc.reliabilityScore = (avgRel == null) ? 0 : avgRel.setScale(0);
                    sc.priceScore = (avgP == null) ? 0 : avgP.setScale(0);
                    sc.availabilityScore = (avgA == null) ? 0 : avgA.setScale(0);

                    scoresByAccount.put(acctId, sc);
                }

                for (Id accId : resultsByAccount.keySet()) {
                    LaneResult lr = resultsByAccount.get(accId);
                    lr.accountScores = new List<AccountScore>();

                    AccountScore sc = scoresByAccount.get(accId);
                    if (sc == null) {
                        sc = new AccountScore();
                        sc.reliabilityScore = 0;
                        sc.priceScore = 0;
                        sc.availabilityScore = 0;
                    }
                    lr.accountScores.add(sc);
                }
            }

            return resultsByAccount.values();

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving matching lane prices: ' + e.getMessage());
        }
    }

        @AuraEnabled
    public static void createPriceRequests(
        List<String> accountIds,
        String seasonId,
        String trailerType,
        String loadingLocationId,
        String deliveryLocationId
    ) {
        try {
            Product2 product = [
                SELECT Id, Name
                FROM Product2 
                WHERE Loading_Location__c = :loadingLocationId 
                    AND Destination_Location__c = :deliveryLocationId 
                LIMIT 1
            ];

            String seasonName = [SELECT Name FROM Season__c WHERE Id = :seasonId].Name;
            List<Account> accounts = [SELECT Name FROM Account WHERE Id IN :accountIds];
            
            List<Price_Request__c> priceRequests = new List<Price_Request__c>();
            List<Lane_Price__c> lanePrices = new List<Lane_Price__c>();
            
            for (Account account : accounts) {
                Price_Request__c pr = new Price_Request__c(
                    Name = seasonName + ' - ' + account.Name,
                    Account__c = account.Id,
                    Season__c = seasonId,
                    Type__c = 'Spot',
                    Request_Date__c = Date.today(),
                    Show_Additional_Information__c = true
                );
                priceRequests.add(pr);
            }
            
            insert priceRequests;

            String portalURL = [SELECT Portal_URL__c FROM Portal_Settings__mdt WHERE DeveloperName = 'Portal_Access']?.Portal_URL__c;
            for (Price_Request__c pr : priceRequests) {
                pr.Portal_URL__c = portalURL + '/?id=' + pr.Id;
            }
            update priceRequests;
            
            for (Price_Request__c pr : priceRequests) {
                Lane_Price__c lp = new Lane_Price__c(
                    Price_Request__c = pr.Id,
                    Lane__c = product.Id,
                    Type_Of_Trailer__c = trailerType,
                    Mandatory__c = true
                );
                lanePrices.add(lp);
            }
            
            insert lanePrices;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating price requests: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static SpotPriceResult getCarriersForSpotPrice(
        String deliveryCountryCode, 
        String seasonId,
        String trailerType,
        String loadingLocationId,
        String deliveryLocationId
    ) {
        try {
            SpotPriceResult result = new SpotPriceResult();
            
            List<Product2> products = [
                SELECT Id, Name
                FROM Product2 
                WHERE Loading_Location__c = :loadingLocationId 
                    AND Destination_Location__c = :deliveryLocationId 
                LIMIT 1
            ];
            
            if (products.isEmpty()) {
                result.potentialCarriers = new List<CarrierResult>();
                result.availablePrices = new List<LaneResult>();
                return result;
            }
            
            Id productId = products[0].Id;
            
            // Get Lane Prices with freight prices populated - INCLUDING ALL PRICE VARIABLES
            List<Lane_Price__c> lanePricesWithPrices = [
                SELECT Id,
                    Freight_Price__c,
                    Type_Of_Trailer__c,
                    PreferredCarrier__c,
                    Loading_Postal_Code__c,
                    Delivery_Postal_Code__c,
                    Lane__r.Name,
                    Price_Request__c,
                    Price_Request__r.Account__c,
                    Price_Request__r.Account__r.Name,
                    Price_Request__r.Account__r.Type,
                    Price_Request__r.Account__r.Fuel_surcharge_percentage__c,
                    Price_Request__r.Account__r.ETS__c,
                    Price_Request__r.Account__r.Plug_in__c,
                    Price_Request__r.Account__r.Harbour_Dues__c,
                    Price_Request__r.Account__r.Overnight_charges_Price__c,
                    Price_Request__r.Account__r.Waiting_Hour__c,
                    Price_Request__r.Account__r.Seasonal_Surcharge__c,
                    Price_Request__r.Account__r.Weekend_Charges__c,
                    Price_Request__r.Account__r.Dangerous_Goods_Price__c,
                    Price_Request__r.Account__r.Pallet_Exchange_Price__c,
                    Price_Request__r.Account__r.Pallet_Jack_Price__c,
                    Price_Request__r.Account__r.Tail_Lift_Price__c,
                    Price_Request__r.Account__r.Price_Ferry__c,
                    Price_Request__r.Account__r.Price_2nd_Driver__c,
                    Price_Request__r.Account__r.Price_Per_Stop__c,
                    Price_Request__r.Season__r.Name
                FROM Lane_Price__c 
                WHERE Lane__c = :productId 
                    AND Price_Request__r.Season__c = :seasonId
                    AND Type_Of_Trailer__c = :trailerType
                    AND Freight_Price__c != null
                ORDER BY Freight_Price__c ASC
            ];
            
            // Get accounts that have lane prices (with or without freight prices)
            Set<Id> accountsWithLanePrices = new Set<Id>();
            for (Lane_Price__c lp : [
                SELECT Price_Request__r.Account__c
                FROM Lane_Price__c 
                WHERE Lane__c = :productId 
                    AND Price_Request__r.Season__c = :seasonId
                    AND Type_Of_Trailer__c = :trailerType
            ]) {
                if (lp.Price_Request__r?.Account__c != null) {
                    accountsWithLanePrices.add(lp.Price_Request__r.Account__c);
                }
            }
            
            // Map available prices (accounts with populated freight prices)
            Map<Id, LaneResult> resultsByAccount = new Map<Id, LaneResult>();
            for (Lane_Price__c lp : lanePricesWithPrices) {
                Id accId = lp.Price_Request__r?.Account__c;
                if (accId == null) continue;

                if (!resultsByAccount.containsKey(accId)) {
                    LaneResult res = new LaneResult();
                    res.accountId = accId;
                    res.priceRequestId = lp.Price_Request__c;
                    res.preferredCarrier = lp.PreferredCarrier__c;
                    res.laneName = lp.Lane__r?.Name;
                    res.lanePrice = lp.Freight_Price__c;
                    res.loadingPC = lp.Loading_Postal_Code__c;
                    res.deliveryPC = lp.Delivery_Postal_Code__c;
                    res.accountName = lp.Price_Request__r?.Account__r?.Name;
                    
                    // ALL PRICE VARIABLES
                    res.fuelSurchargePercentage = lp.Price_Request__r?.Account__r?.Fuel_surcharge_percentage__c;
                    res.ets = lp.Price_Request__r?.Account__r?.ETS__c;
                    res.plugIn = lp.Price_Request__r?.Account__r?.Plug_in__c;
                    res.harbourDues = lp.Price_Request__r?.Account__r?.Harbour_Dues__c;
                    res.overnightPrice = lp.Price_Request__r?.Account__r?.Overnight_charges_Price__c;
                    res.waitingHour = lp.Price_Request__r?.Account__r?.Waiting_Hour__c;
                    res.seasonalSurcharge = lp.Price_Request__r?.Account__r?.Seasonal_Surcharge__c;
                    res.weekendCharges = lp.Price_Request__r?.Account__r?.Weekend_Charges__c;
                    res.dangerousGoods = lp.Price_Request__r?.Account__r?.Dangerous_Goods_Price__c;
                    res.palletExchange = lp.Price_Request__r?.Account__r?.Pallet_Exchange_Price__c;
                    res.palletJack = lp.Price_Request__r?.Account__r?.Pallet_Jack_Price__c;
                    res.tailLift = lp.Price_Request__r?.Account__r?.Tail_Lift_Price__c;
                    res.priceFerry = lp.Price_Request__r?.Account__r?.Price_Ferry__c;
                    res.price2ndDriver = lp.Price_Request__r?.Account__r?.Price_2nd_Driver__c;
                    res.pricePerStop = lp.Price_Request__r?.Account__r?.Price_Per_Stop__c;
                    
                    res.seasonName = lp.Price_Request__r?.Season__r?.Name;
                    res.trailerTypes = new List<TrailerType>();
                    
                    TrailerType tt = new TrailerType();
                    tt.laneId = lp.Id;
                    tt.type = trailerType;
                    tt.price = lp.Freight_Price__c;
                    res.trailerTypes.add(tt);
                    
                    resultsByAccount.put(accId, res);
                }
            }

            // Get Account Scores for available prices
            if (!resultsByAccount.isEmpty()) {
                Set<Id> accountIds = resultsByAccount.keySet();

                List<AggregateResult> agg = [
                    SELECT Carrier__c carrierId,
                        AVG(Reliability_Score__c) avgReliability,
                        AVG(Price_Level_Percentage__c) avgPrice,
                        AVG(Availability_Score_Percentage__c) avgAvailability
                    FROM Carrier_Score__c
                    WHERE Carrier__c IN :accountIds
                    GROUP BY Carrier__c
                ];

                Map<Id, AccountScore> scoresByAccount = new Map<Id, AccountScore>();
                for (AggregateResult ar : agg) {
                    Id acctId = (Id) ar.get('carrierId');
                    Decimal avgRel = (Decimal) ar.get('avgReliability');
                    Decimal avgP = (Decimal) ar.get('avgPrice');
                    Decimal avgA = (Decimal) ar.get('avgAvailability');

                    AccountScore sc = new AccountScore();
                    sc.reliabilityScore = (avgRel == null) ? 0 : avgRel.setScale(0);
                    sc.priceScore = (avgP == null) ? 0 : avgP.setScale(0);
                    sc.availabilityScore = (avgA == null) ? 0 : avgA.setScale(0);

                    scoresByAccount.put(acctId, sc);
                }

                for (Id accId : resultsByAccount.keySet()) {
                    LaneResult lr = resultsByAccount.get(accId);
                    lr.accountScores = new List<AccountScore>();

                    AccountScore sc = scoresByAccount.get(accId);
                    if (sc == null) {
                        sc = new AccountScore();
                        sc.reliabilityScore = 0;
                        sc.priceScore = 0;
                        sc.availabilityScore = 0;
                    }
                    lr.accountScores.add(sc);
                }
            }
            
            // Get potential carriers (support destination but no lane price record)
            List<Account> carriers = [
                SELECT Id, Name, Destination_Country_Codes__c, Type
                FROM Account
                WHERE Destination_Country_Codes__c INCLUDES (:deliveryCountryCode)
                    AND Id NOT IN :accountsWithLanePrices
                ORDER BY Name
            ];
            
            List<CarrierResult> potentialCarriers = new List<CarrierResult>();
            for (Account acc : carriers) {
                CarrierResult cr = new CarrierResult();
                cr.accountId = acc.Id;
                cr.accountName = acc.Name;
                cr.type = acc.Type;
                cr.destinationCountries = acc.Destination_Country_Codes__c;
                potentialCarriers.add(cr);
            }
            
            result.potentialCarriers = potentialCarriers;
            result.availablePrices = resultsByAccount.values();
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving carriers: ' + e.getMessage());
        }
    }

    public class SpotPriceResult {
        @AuraEnabled public List<CarrierResult> potentialCarriers { get; set; }
        @AuraEnabled public List<LaneResult> availablePrices { get; set; }
    }

    public class CarrierResult {
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String destinationCountries { get; set; }
        @AuraEnabled public String type { get; set; }
    }

    public class LaneResult {
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String priceRequestId { get; set; }
        @AuraEnabled public String laneName { get; set; }
        @AuraEnabled public Decimal lanePrice { get; set; }
        @AuraEnabled public String loadingPC { get; set; }
        @AuraEnabled public String deliveryPC { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Boolean preferredCarrier { get; set; }
        @AuraEnabled public Decimal fuelSurchargePercentage { get; set; }
        @AuraEnabled public Decimal ets { get; set; }
        @AuraEnabled public Decimal plugIn { get; set; }
        @AuraEnabled public Decimal harbourDues { get; set; }
        @AuraEnabled public Decimal overnightPrice { get; set; }
        @AuraEnabled public Decimal waitingHour { get; set; }
        @AuraEnabled public Decimal seasonalSurcharge { get; set; }
        @AuraEnabled public Decimal weekendCharges { get; set; }
        @AuraEnabled public Decimal dangerousGoods { get; set; }
        @AuraEnabled public Decimal palletExchange { get; set; }
        @AuraEnabled public Decimal palletJack { get; set; }
        @AuraEnabled public Decimal tailLift { get; set; }
        @AuraEnabled public Decimal priceFerry { get; set; }
        @AuraEnabled public Decimal price2ndDriver { get; set; }
        @AuraEnabled public Decimal pricePerStop { get; set; }
        @AuraEnabled public String seasonName { get; set; }
        @AuraEnabled public List<TrailerType> trailerTypes { get; set; }
        @AuraEnabled public List<AccountScore> accountScores { get; set; }
    }
    public class TrailerType {
        @AuraEnabled public String laneId { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Decimal price { get; set; }
    }
    public class AccountScore {
        @AuraEnabled public Decimal reliabilityScore { get; set; }
        @AuraEnabled public Decimal priceScore       { get; set; }
        @AuraEnabled public Decimal availabilityScore{ get; set; }
    }
}