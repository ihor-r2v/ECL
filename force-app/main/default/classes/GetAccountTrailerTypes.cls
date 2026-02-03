public without sharing class GetAccountTrailerTypes
{
    public class Input {
        @InvocableVariable(required=true)
        public String accountId;
    }

    public class Output {
        @InvocableVariable
        public List<KeyValuePair__mdt> keyValuePairs;
    }

    @InvocableMethod(label='Get Account Trailer Types' description='Get Account Trailer Types')
    public static List<Output> getAccountTrailerTypes(List<Input> inputs)
    {
        List<Output> result = new List<Output>();
        result.add(new Output());
        result[0].keyValuePairs = new List<KeyValuePair__mdt>();

        Account acc = [SELECT Id, Name, Trailer_Types__c FROM Account WHERE Id = :inputs[0].accountId];

        Schema.DescribeFieldResult f = Account.Trailer_Types__c.getDescribe();
        for (Schema.PicklistEntry ple : f.getPicklistValues())
        {
            if (acc.Trailer_Types__c.contains(ple.getValue())) {
                result[0].keyValuePairs.add(new KeyValuePair__mdt(MasterLabel = ple.getLabel(), DeveloperName = ple.getValue()));
            }
        }
        return result;
    }
}