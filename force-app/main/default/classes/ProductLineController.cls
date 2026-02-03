public class ProductLineController {
    
    public class LineInfoAndCarrierScore {
        @AuraEnabled public String Id;
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String carrier;
        @AuraEnabled public String trailerType;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal dieselMarkup;
        @AuraEnabled public Decimal transitTime;
        @AuraEnabled public Boolean dangerousGoods;
        @AuraEnabled public Boolean palletExchange;
        @AuraEnabled public Boolean tailLift;
        @AuraEnabled public Boolean palletJack;
        @AuraEnabled public List<CarrierScore> carrierScores;
    }

    public class CarrierScore {
        @AuraEnabled public Decimal reliabilityScore;
        @AuraEnabled public Decimal availabilityScore;
        @AuraEnabled public Decimal priceLevel;
    }

    @AuraEnabled(cacheable=true)
    public static List<LineInfoAndCarrierScore> getLinesByLocations(
        String loadingLocationId, 
        String destinationLocationId, 
        Date deliveryDate, 
        String trailerType,
        String seasonId
    ) {
        
        if (String.isBlank(loadingLocationId) || String.isBlank(destinationLocationId)) {
            return new List<LineInfoAndCarrierScore>();
        }

        List<Lane_Price__c> lanePrices = queryLanes(loadingLocationId, destinationLocationId, trailerType, seasonId);
        Map<Id, List<Carrier_Score__c>> carrierToScoreMap = getCarrierScoreMap(lanePrices);
        
        return buildLineInfoList(lanePrices, carrierToScoreMap);
    }

    private static List<Lane_Price__c> queryLanes(String loadingLocationId, String destinationLocationId, String trailerType, String seasonId) {
        List<String> filters = new List<String>();
        filters.add('Freight_Price__c != null');
        filters.add('Type_Of_Trailer__c = :trailerType');
        filters.add('Lane__r.IsActive = true');
        filters.add('Lane__r.Loading_Location__c = :loadingLocationId');
        filters.add('Lane__r.Destination_Location__c = :destinationLocationId');
        filters.add('Price_Request__r.Season__c = :seasonId');

        String query = 'SELECT Id, Freight_Price__c, Lane__c, Type_Of_Trailer__c, Price_Request__c,' +
            ' Lane__r.Name, Lane__r.Loading_Location__c, Lane__r.Destination_Location__c,' +
            ' Price_Request__r.Account__c, Price_Request__r.Account__r.Name, Price_Request__r.Account__r.Dangerous_Goods__c,' +
            ' Price_Request__r.Account__r.Pallet_Exchange__c, Price_Request__r.Account__r.Tail_Lift__c, Price_Request__r.Account__r.Pallet_Jack__c' +
            ' FROM Lane_Price__c WHERE ' + String.join(filters, ' AND ');

        return Database.query(query);
    }

    private static Map<Id, List<Carrier_Score__c>> getCarrierScoreMap(List<Lane_Price__c> lanePrices) {
        Set<Id> carrierIds = extractCarrierIds(lanePrices);

        Map<Id, List<Carrier_Score__c>> carrierToScoreMap = new Map<Id, List<Carrier_Score__c>>();
        for (Carrier_Score__c score : [
            SELECT Id, Carrier__c, Reliability_Score__c, Availability_Score_Percentage__c, Price_Level_Percentage__c
            FROM Carrier_Score__c
            WHERE Carrier__c IN :carrierIds
        ]) {
            if (!carrierToScoreMap.containsKey(score.Carrier__c)) {
                carrierToScoreMap.put(score.Carrier__c, new List<Carrier_Score__c>());
            }
            carrierToScoreMap.get(score.Carrier__c).add(score);
        }

        return carrierToScoreMap;
    }

    private static Set<Id> extractCarrierIds(List<Lane_Price__c> lanePrices) {
        Set<Id> carrierIds = new Set<Id>();
        for (Lane_Price__c lp : lanePrices) {
            if (lp.Price_Request__r.Account__c != null) {
                carrierIds.add(lp.Price_Request__r.Account__c);
            }
        }
        return carrierIds;
    }

    private static List<LineInfoAndCarrierScore> buildLineInfoList(List<Lane_Price__c> lanePrices, Map<Id, List<Carrier_Score__c>> carrierToScoreMap) {
        List<LineInfoAndCarrierScore> result = new List<LineInfoAndCarrierScore>();

        for (Lane_Price__c lp : lanePrices) {
            LineInfoAndCarrierScore lineInfo = createLineInfo(lp, carrierToScoreMap);
            result.add(lineInfo);
        }
        
        return result;
    }

    private static LineInfoAndCarrierScore createLineInfo(Lane_Price__c lp, Map<Id, List<Carrier_Score__c>> carrierToScoreMap) {
        LineInfoAndCarrierScore lineInfo = new LineInfoAndCarrierScore();
        lineInfo.Id = lp.Id;
        lineInfo.productId = lp.Lane__c;
        lineInfo.productName = lp.Lane__r.Name;
        lineInfo.unitPrice = lp.Freight_Price__c;
        lineInfo.trailerType = lp.Type_Of_Trailer__c;
        lineInfo.carrier = lp.Price_Request__r.Account__c != null ? lp.Price_Request__r.Account__r.Name : '';

        lineInfo.dangerousGoods = lp.Price_Request__r.Account__c != null ? lp.Price_Request__r.Account__r.Dangerous_Goods__c : false;
        lineInfo.palletExchange = lp.Price_Request__r.Account__c != null ? lp.Price_Request__r.Account__r.Pallet_Exchange__c : false;
        lineInfo.tailLift = lp.Price_Request__r.Account__c != null ? lp.Price_Request__r.Account__r.Tail_Lift__c : false;
        lineInfo.palletJack = lp.Price_Request__r.Account__c != null ? lp.Price_Request__r.Account__r.Pallet_Jack__c : false;

        lineInfo.carrierScores = buildCarrierScores(lp, carrierToScoreMap);
        
        return lineInfo;
    }

    private static List<CarrierScore> buildCarrierScores(Lane_Price__c lp, Map<Id, List<Carrier_Score__c>> carrierToScoreMap) {
        List<CarrierScore> carrierScores = new List<CarrierScore>();
        List<Carrier_Score__c> scores = carrierToScoreMap.get(lp.Price_Request__r.Account__c);
        
        if (scores != null) {
            for (Carrier_Score__c score : scores) {
                CarrierScore cs = new CarrierScore();
                cs.reliabilityScore = score.Reliability_Score__c;
                cs.availabilityScore = score.Availability_Score_Percentage__c;
                cs.priceLevel = score.Price_Level_Percentage__c;
                carrierScores.add(cs);
            }
        }
        
        return carrierScores;
    }
}