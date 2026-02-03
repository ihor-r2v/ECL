public without sharing class GetAllAccountTrailerTypes {

    public class Output {
        @InvocableVariable
        public List<KeyValuePair__mdt> keyValuePairs;
    }

    @InvocableMethod(label='Get All Account Trailer Types' description='Get All Account Trailer Types')
    public static List<Output> getAccountTrailerTypes()
    {
        List<Output> result = new List<Output>();
        result.add(new Output());
        result[0].keyValuePairs = new List<KeyValuePair__mdt>();


        Schema.DescribeFieldResult f = Account.Trailer_Types__c.getDescribe();
        for (Schema.PicklistEntry ple : f.getPicklistValues())
        {
            result[0].keyValuePairs.add(new KeyValuePair__mdt(MasterLabel = ple.getLabel(), DeveloperName = ple.getValue()));
        }
        return result;
    }
}