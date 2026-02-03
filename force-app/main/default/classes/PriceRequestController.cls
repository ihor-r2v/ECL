public without sharing class PriceRequestController {
    
    @AuraEnabled(cacheable=true)
    public static Price_Request__c getPriceRequestById(Id priceRequestId) {
        return [
            SELECT 
                Show_Additional_Lane_Price_Information__c, 
                Show_Additional_Information__c,
                Additional_stops__c,
                ADR__c, 
                Fuel_surcharge_percentage__c, 
                Direct_Ferry__c, 
                Harbour_dues__c, 
                Overnight_charges__c, 
                Pallet_Exchange__c, 
                Pallet_Jack__c, 
                Plug_in__c,
                Seasonal_surcharge__c, 
                Tail_Lift__c, 
                Two_drivers__c, 
                Type_of_trailer__c, 
                Waiting_hours__c, 
                Weekend_charges__c, 
                Dangerous_Goods__c, 
                Account__c,
                ETS__c, 
                Stage__c,
                Season__r.Name
            FROM Price_Request__c 
            WHERE Id = :priceRequestId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<LanePriceWrapper> getLanePrices(Id priceRequestId, Integer howMany, Integer offset) {
        Integer numOfMandatoryLanes = 0;

        if(howMany == null) howMany = 1000000000;
        if(offset == null) offset = 0;

        // Get current price request details
        Price_Request__c currentPR = [
            SELECT Account__c, Season__c 
            FROM Price_Request__c 
            WHERE Id = :priceRequestId 
            LIMIT 1
        ];
        
        // Get lane IDs + trailer types that already have prices in OTHER price requests with same account/season/trailer
        Set<String> existingLaneTrailerCombos = new Set<String>();
        for (Lane_Price__c existingLP : [
            SELECT Lane__c, Type_Of_Trailer__c
            FROM Lane_Price__c 
            WHERE Price_Request__r.Account__c = :currentPR.Account__c
            AND Price_Request__r.Season__c = :currentPR.Season__c
            AND Price_Request__c != :priceRequestId
            AND Freight_Price__c != null
        ]) {
            // Create a unique key combining Lane ID and Trailer Type
            String comboKey = existingLP.Lane__c + '_' + (existingLP.Type_Of_Trailer__c != null ? existingLP.Type_Of_Trailer__c : '');
            existingLaneTrailerCombos.add(comboKey);
        }

        List<Lane_Price__c> allLanePrices = [
            SELECT Id,
                Transit__c, 
                Mandatory__c,
                Freight_Price__c,
                Type_Of_Trailer__c,
                Loading_Postal_Code__c,
                Loading_Country_Code__c,
                Delivery_Postal_Code__c, 
                Delivery_Country_Code__c, 
                Lane__r.Name,  
                Lane__r.Loading_Location__r.Country_Code__c, 
                Lane__r.Destination_Location__r.Country_Code__c,
                Price_Request__r.Account__c,
                Lane__c
            FROM Lane_Price__c 
            WHERE Price_Request__c = :priceRequestId
            ORDER BY Mandatory__c DESC
            LIMIT :howMany
            OFFSET :offset
        ];
        
        // Filter out lanes that match existing lane+trailer combinations
        List<Lane_Price__c> lanePrices = new List<Lane_Price__c>();
        for (Lane_Price__c lp : allLanePrices) {
            String comboKey = lp.Lane__c + '_' + (lp.Type_Of_Trailer__c != null ? lp.Type_Of_Trailer__c : '');
            if (!existingLaneTrailerCombos.contains(comboKey)) {
                lanePrices.add(lp);
                if(lp.Mandatory__c == true) {
                    numOfMandatoryLanes++;
                }
            }
        }

        List<LanePriceWrapper> result = new List<LanePriceWrapper>();
        for (Lane_Price__c lp : lanePrices) {
            result.add(new LanePriceWrapper(
                lp.Id,
                lp.Lane__r.Name,
                lp.Freight_Price__c,
                lp.Transit__c,
                lp.Mandatory__c,
                lp.Loading_Postal_Code__c,
                lp.Loading_Country_Code__c,
                lp.Delivery_Postal_Code__c,
                lp.Delivery_Country_Code__c,
                lp.Type_Of_Trailer__c,
                lp.Lane__r?.Loading_Location__r?.Country_Code__c,
                lp.Lane__r?.Destination_Location__r?.Country_Code__c,
                lp.Price_Request__r.Account__c,
                numOfMandatoryLanes
                )
            );
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<ExistingLanePriceWrapper> getExistingLanePrices(Id priceRequestId) {
        // Get current price request details
        Price_Request__c currentPR = [
            SELECT Account__c, Season__c 
            FROM Price_Request__c 
            WHERE Id = :priceRequestId 
            LIMIT 1
        ];
        
        // Get lanes from current price request with their trailer types
        Map<String, Lane_Price__c> currentPriceRequestLanes = new Map<String, Lane_Price__c>();
        Set<Id> currentLaneIds = new Set<Id>();
        
        for (Lane_Price__c lp : [
            SELECT Lane__c, Type_Of_Trailer__c, Id
            FROM Lane_Price__c 
            WHERE Price_Request__c = :priceRequestId
        ]) {
            String comboKey = lp.Lane__c + '_' + (lp.Type_Of_Trailer__c != null ? lp.Type_Of_Trailer__c : '');
            currentPriceRequestLanes.put(comboKey, lp);
            currentLaneIds.add(lp.Lane__c);
        }
        
        // Get all lane prices from OTHER price requests with same account and season
        List<Lane_Price__c> existingLanePrices = [
            SELECT Id,
                Transit__c, 
                Mandatory__c,
                Freight_Price__c,
                Type_Of_Trailer__c,
                Loading_Postal_Code__c,
                Loading_Country_Code__c,
                Delivery_Postal_Code__c, 
                Delivery_Country_Code__c, 
                Lane__r.Name,  
                Lane__r.Loading_Location__r.Country_Code__c, 
                Lane__r.Destination_Location__r.Country_Code__c,
                Price_Request__r.Account__c,
                Price_Request__r.Name,
                Price_Request__c,
                Lane__c,
                CreatedDate
            FROM Lane_Price__c 
            WHERE Price_Request__r.Account__c = :currentPR.Account__c
            AND Price_Request__r.Season__c = :currentPR.Season__c
            AND Price_Request__c != :priceRequestId
            AND Freight_Price__c != null
            AND Lane__c IN :currentLaneIds
            ORDER BY CreatedDate DESC
        ];
        
        // Group by Lane+Trailer combination to get only the most recent price for each combination
        Map<String, Lane_Price__c> mostRecentByLaneTrailer = new Map<String, Lane_Price__c>();
        for (Lane_Price__c lp : existingLanePrices) {
            String comboKey = lp.Lane__c + '_' + (lp.Type_Of_Trailer__c != null ? lp.Type_Of_Trailer__c : '');
            
            // Only include if this combination exists in current price request
            if (currentPriceRequestLanes.containsKey(comboKey) && !mostRecentByLaneTrailer.containsKey(comboKey)) {
                mostRecentByLaneTrailer.put(comboKey, lp);
            }
        }
        
        List<ExistingLanePriceWrapper> result = new List<ExistingLanePriceWrapper>();
        for (String comboKey : mostRecentByLaneTrailer.keySet()) {
            Lane_Price__c lp = mostRecentByLaneTrailer.get(comboKey);
            Lane_Price__c currentLP = currentPriceRequestLanes.get(comboKey);
            
            if (currentLP != null) {
                ExistingLanePriceWrapper wrapper = new ExistingLanePriceWrapper();
                wrapper.id = lp.Id;
                wrapper.laneName = lp.Lane__r.Name;
                wrapper.freightPrice = lp.Freight_Price__c;
                wrapper.transit = lp.Transit__c;
                wrapper.mandatory = lp.Mandatory__c;
                wrapper.loadingPostalCode = lp.Loading_Postal_Code__c;
                wrapper.loadingCountryCode = lp.Loading_Country_Code__c;
                wrapper.deliveryPostalCode = lp.Delivery_Postal_Code__c;
                wrapper.deliveryCountryCode = lp.Delivery_Country_Code__c;
                wrapper.typeOfTrailer = lp.Type_Of_Trailer__c;
                wrapper.loadingLocationCode = lp.Lane__r?.Loading_Location__r?.Country_Code__c;
                wrapper.destinationLocationCode = lp.Lane__r?.Destination_Location__r?.Country_Code__c;
                wrapper.accountID = lp.Price_Request__r.Account__c;
                wrapper.numOfMandatoryLanes = 0;
                wrapper.sourcePriceRequestName = lp.Price_Request__r.Name;
                wrapper.sourcePriceRequestId = lp.Price_Request__c;
                wrapper.currentPriceRequestLaneId = currentLP.Id;
                wrapper.laneId = lp.Lane__c;
                
                result.add(wrapper);
            }
        }
        
        return result;
    }

    @AuraEnabled
    public static void updateExistingLanePrices(String jsonData, String priceRequestId, Boolean isFinalSubmit) {
        List<Object> rawData = (List<Object>) JSON.deserializeUntyped(jsonData);
        
        List<Lane_Price__c> updates = new List<Lane_Price__c>();
        
        for (Object rawItem : rawData) {
            Map<String, Object> item = (Map<String, Object>) rawItem;
            
            // Use originalId for existing lane prices (from previous price request)
            String originalId = (String) item.get('originalId');
            if (String.isNotBlank(originalId)) {
                Lane_Price__c lanePrice = new Lane_Price__c(Id = originalId);
                
                if (item.containsKey('freightPrice') && item.get('freightPrice') != null) {
                    Object fpValue = item.get('freightPrice');
                    if (fpValue instanceof String && String.isNotBlank((String) fpValue)) {
                        lanePrice.Freight_Price__c = Decimal.valueOf((String) fpValue);
                    } else if (fpValue instanceof Decimal) {
                        lanePrice.Freight_Price__c = (Decimal) fpValue;
                    }
                }
                
                if (item.containsKey('typeOfTrailer') && item.get('typeOfTrailer') != null) {
                    lanePrice.Type_Of_Trailer__c = (String) item.get('typeOfTrailer');
                }
                
                updates.add(lanePrice);
            }
        }
        
        if (!updates.isEmpty()) {
            update updates;
        }

        if (String.isNotBlank(priceRequestId) && isFinalSubmit) {
            Price_Request__c relatedPriceRequest = new Price_Request__c(
                Id = priceRequestId, 
                Stage__c = 'Answer received'
            );
            update relatedPriceRequest;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCountryCodeToNameMap() {
        Map<String, String> countryCodeToNameMap = new Map<String, String>();
        
        Schema.DescribeFieldResult f = Account.BillingCountryCode.getDescribe();
        for (Schema.PicklistEntry ple : f.getPicklistValues())
        {
            countryCodeToNameMap.put(ple.getValue(), ple.getLabel());
        }
        return countryCodeToNameMap;
    }

    @AuraEnabled(cacheable=true)
    public static String getAccessCodeFromAccount(String priceRequestId){
        try {
            if (String.isBlank(priceRequestId)) {
                return null;
            }
            
            List<Price_Request__c> priceRequests = [
                SELECT Account__c 
                FROM Price_Request__c 
                WHERE Id = :priceRequestId 
                LIMIT 1
            ];
            
            if (priceRequests.isEmpty() || priceRequests[0].Account__c == null) {
                return null;
            }
            
            String accountId = priceRequests[0].Account__c;
            
            List<Account> accounts = [
                SELECT Access_code__c 
                FROM Account 
                WHERE Id = :accountId 
                LIMIT 1
            ];
            
            return accounts.isEmpty() ? null : accounts[0].Access_code__c;
        } catch (Exception e) {
            System.debug('Error in getAccessCodeFromAccount: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static void updateFreightPrices(String jsonData, String priceRequestId,Boolean isFinalSubmit) {
        List<Object> rawData = (List<Object>) JSON.deserializeUntyped(jsonData);
        
        List<Lane_Price__c> updates = new List<Lane_Price__c>();
        
        for (Object rawItem : rawData) {
            Map<String, Object> item = (Map<String, Object>) rawItem;
            Lane_Price__c lanePrice = new Lane_Price__c(Id = (String) item.get('id'));
            
            if (item.containsKey('freightPrice') && item.get('freightPrice') != null) {
                Object fpValue = item.get('freightPrice');
                if (fpValue instanceof String && String.isNotBlank((String) fpValue)) {
                    lanePrice.Freight_Price__c = Decimal.valueOf((String) fpValue);
                } else if (fpValue instanceof Decimal) {
                    lanePrice.Freight_Price__c = (Decimal) fpValue;
                }
            }
            
            if (item.containsKey('typeOfTrailer') && item.get('typeOfTrailer') != null) {
                lanePrice.Type_Of_Trailer__c = (String) item.get('typeOfTrailer');
            }
            
            updates.add(lanePrice);
        }
        
        if (!updates.isEmpty()) {
            update updates;
        }

        if (String.isNotBlank(priceRequestId) && isFinalSubmit) {
            Price_Request__c relatedPriceRequest = new Price_Request__c(
                Id = priceRequestId, 
                Stage__c = 'Answer received'
            );
            update relatedPriceRequest;
        }
    }

    @AuraEnabled
    public static void requestPermissionToChange(String priceRequestId){
        Set<String> userIds = new Set<String>();
        try {
            if (String.isBlank(priceRequestId)) {
                throw new AuraHandledException('Price Request ID is required.');
            }
            
            CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Price_Request_Notification' LIMIT 1];
            Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'Price_Quote_Manager'];
            List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :publicGroup.Id AND UserOrGroupId IN (SELECT Id FROM User WHERE IsActive = true)];
            String accountName = [SELECT Account__r.Name FROM Price_Request__c WHERE Id = :priceRequestId]?.Account__r.Name;
            
            for (GroupMember gm : groupMembers) {
                if(gm.UserOrGroupId != null) {
                    userIds.add(gm.UserOrGroupId);
                }
            }

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Permission to change prices for ' + accountName);
            notification.setBody(accountName + ' is requesting permission to change the price request. Please review and approve.');
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(priceRequestId);

            try {
                notification.send(userIds);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error sending notification: ' + e.getMessage());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error requesting permission: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Account getAccountByLanePrice(String accountId){
        try {
            return [
                SELECT Id,
                    Overnight_charges_Price__c,
                    Fuel_surcharge_percentage__c,
                    Seasonal_Surcharge__c,
                    Name,
                    Plug_in__c,
                    Waiting_Hour__c,
                    Harbour_Dues__c,
                    Price_2nd_Driver__c,
                    Price_Per_Stop__c,
                    Price_Ferry__c,
                    ETS__c,
                    Weekend_Charges__c,
                    Dangerous_Goods_Price__c,
                    Pallet_Exchange_Price__c,
                    Tail_Lift_Price__c,
                    Pallet_Jack_Price__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateAccountByLanePrice(String jsonAccount, String priceRequestId, Boolean isFinalSubmit){
        try {
            Account accToUpdate = (Account) JSON.deserialize(jsonAccount, Account.class);
            Account finalUpdate = new Account(Id = accToUpdate.Id);
            Price_Request__c relatedPriceRequest = new Price_Request__c(
                Id = priceRequestId, 
                Stage__c = 'Answer received'
            );
            if(accToUpdate.Fuel_surcharge_percentage__c != null) {
                finalUpdate.Fuel_surcharge_percentage__c = accToUpdate.Fuel_surcharge_percentage__c;
            }
            if(accToUpdate.Price_Ferry__c != null) {
                finalUpdate.Price_Ferry__c = accToUpdate.Price_Ferry__c;
            }
            if(accToUpdate.Price_2nd_Driver__c != null) {
                finalUpdate.Price_2nd_Driver__c = accToUpdate.Price_2nd_Driver__c;
            }
            if(accToUpdate.Price_Per_Stop__c != null) {
                finalUpdate.Price_Per_Stop__c = accToUpdate.Price_Per_Stop__c;
            }
            if(accToUpdate.Overnight_charges_Price__c != null) {
                finalUpdate.Overnight_charges_Price__c = accToUpdate.Overnight_charges_Price__c;
            }
            if(accToUpdate.Seasonal_Surcharge__c != null) {
                finalUpdate.Seasonal_Surcharge__c = accToUpdate.Seasonal_Surcharge__c;
            }
            if(accToUpdate.Plug_in__c != null) {
                finalUpdate.Plug_in__c = accToUpdate.Plug_in__c;
            }
            if(accToUpdate.Waiting_Hour__c != null) {
                finalUpdate.Waiting_Hour__c = accToUpdate.Waiting_Hour__c;
            }
            if(accToUpdate.Harbour_Dues__c != null) {
                finalUpdate.Harbour_Dues__c = accToUpdate.Harbour_Dues__c;
            }
            if(accToUpdate.ETS__c != null) {
                finalUpdate.ETS__c = accToUpdate.ETS__c;
            }
            if(accToUpdate.Weekend_Charges__c != null) {
                finalUpdate.Weekend_Charges__c = accToUpdate.Weekend_Charges__c;
            }
            if(accToUpdate.Dangerous_Goods_Price__c != null) {
                finalUpdate.Dangerous_Goods_Price__c = accToUpdate.Dangerous_Goods_Price__c;
            }
            if(accToUpdate.Pallet_Exchange_Price__c != null) {
                finalUpdate.Pallet_Exchange_Price__c = accToUpdate.Pallet_Exchange_Price__c;
            }
            if(accToUpdate.Tail_Lift_Price__c != null) {
                finalUpdate.Tail_Lift_Price__c = accToUpdate.Tail_Lift_Price__c;
            }
            if(accToUpdate.Pallet_Jack_Price__c != null) {
                finalUpdate.Pallet_Jack_Price__c = accToUpdate.Pallet_Jack_Price__c;
            }
            update finalUpdate;
            
            if(isFinalSubmit){
                update relatedPriceRequest;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Account: ' + e.getMessage());
        }
    }

    public class LanePriceWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String laneName;
        @AuraEnabled public Decimal freightPrice;
        @AuraEnabled public String transit;
        @AuraEnabled public Boolean mandatory;
        @AuraEnabled public String loadingPostalCode;
        @AuraEnabled public String loadingCountryCode;
        @AuraEnabled public String deliveryPostalCode;
        @AuraEnabled public String deliveryCountryCode;
        @AuraEnabled public String typeOfTrailer;
        @AuraEnabled public String loadingLocationCode;
        @AuraEnabled public String destinationLocationCode;
        @AuraEnabled public String accountID;
        @AuraEnabled public Integer numOfMandatoryLanes;

        public LanePriceWrapper() {}

        public LanePriceWrapper(
            String id,
            String laneName,
            Decimal freightPrice,
            String transit,
            Boolean mandatory,
            String loadingPostalCode,
            String loadingCountryCode,
            String deliveryPostalCode,
            String deliveryCountryCode,
            String typeOfTrailer,
            String loadingLocationCode,
            String destinationLocationCode,
            String accountID,
            Integer numOfMandatoryLanes
        ) {
            this.id = id;
            this.laneName = laneName;
            this.freightPrice = freightPrice;
            this.transit = transit;
            this.mandatory = mandatory;
            this.loadingPostalCode = loadingPostalCode;
            this.loadingCountryCode = loadingCountryCode;
            this.deliveryPostalCode = deliveryPostalCode;
            this.deliveryCountryCode = deliveryCountryCode;
            this.typeOfTrailer = typeOfTrailer;
            this.loadingLocationCode = loadingLocationCode;
            this.destinationLocationCode = destinationLocationCode;
            this.accountID = accountID;
            this.numOfMandatoryLanes = numOfMandatoryLanes;
        }
    }

    public class ExistingLanePriceWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String laneName;
        @AuraEnabled public Decimal freightPrice;
        @AuraEnabled public String transit;
        @AuraEnabled public Boolean mandatory;
        @AuraEnabled public String loadingPostalCode;
        @AuraEnabled public String loadingCountryCode;
        @AuraEnabled public String deliveryPostalCode;
        @AuraEnabled public String deliveryCountryCode;
        @AuraEnabled public String typeOfTrailer;
        @AuraEnabled public String loadingLocationCode;
        @AuraEnabled public String destinationLocationCode;
        @AuraEnabled public String accountID;
        @AuraEnabled public Integer numOfMandatoryLanes;
        @AuraEnabled public String sourcePriceRequestName;
        @AuraEnabled public String sourcePriceRequestId;
        @AuraEnabled public String currentPriceRequestLaneId;
        @AuraEnabled public String laneId;
    }
}