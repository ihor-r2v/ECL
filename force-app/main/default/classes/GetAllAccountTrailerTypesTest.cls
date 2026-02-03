@isTest
private class GetAllAccountTrailerTypesTest {
    
    @isTest
    static void testGetAccountTrailerTypes_ReturnsAllPicklistValues() {
        
        Test.startTest();
        List<GetAllAccountTrailerTypes.Output> results = GetAllAccountTrailerTypes.getAccountTrailerTypes();
        Test.stopTest();
        
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should return exactly one Output object');
        Assert.isNotNull(results[0], 'Output object should not be null');
        Assert.isNotNull(results[0].keyValuePairs, 'KeyValuePairs list should not be null');
        Assert.isFalse(results[0].keyValuePairs.isEmpty(), 'KeyValuePairs list should contain picklist values');
        
        Schema.DescribeFieldResult fieldDescribe = Account.Trailer_Types__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        
        Assert.areEqual(
            picklistValues.size(), 
            results[0].keyValuePairs.size(), 
            'Number of returned KeyValuePairs should match number of picklist values'
        );
        
        Map<String, String> resultMap = new Map<String, String>();
        for (KeyValuePair__mdt kvp : results[0].keyValuePairs) {
            resultMap.put(kvp.DeveloperName, kvp.MasterLabel);
        }
        
        for (Schema.PicklistEntry ple : picklistValues) {
            Assert.isTrue(
                resultMap.containsKey(ple.getValue()),
                'Result should contain picklist value: ' + ple.getValue()
            );
            Assert.areEqual(
                ple.getLabel(),
                resultMap.get(ple.getValue()),
                'MasterLabel should match picklist label for value: ' + ple.getValue()
            );
        }
        
        for (KeyValuePair__mdt kvp : results[0].keyValuePairs) {
            Assert.isNotNull(kvp.MasterLabel, 'MasterLabel should not be null');
            Assert.isNotNull(kvp.DeveloperName, 'DeveloperName should not be null');
            Assert.isFalse(String.isBlank(kvp.MasterLabel), 'MasterLabel should not be blank');
            Assert.isFalse(String.isBlank(kvp.DeveloperName), 'DeveloperName should not be blank');
        }
        
        Set<String> expectedTrailerTypes = new Set<String>{
            'Frigo - chilled',
            'Frigo - frozen',
            'Dual temp',
            'Box trailer'
        };
        
        Set<String> actualValues = resultMap.keySet();
        for (String expectedType : expectedTrailerTypes) {
            Assert.isTrue(
                actualValues.contains(expectedType),
                'Expected trailer type should be present: ' + expectedType
            );
        }
    }
}