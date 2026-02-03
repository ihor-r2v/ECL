public without sharing class GetAccountDeliveryCountries
{
    public class Input {
        @InvocableVariable(required=true)
        public String accountId;
    }

    public class Output {
        @InvocableVariable
        public List<KeyValuePair__mdt> keyValuePairs;
    }

    @InvocableMethod(label='Get Account Delivery Countries' description='Get Account Delivery Countries')
    public static List<Output> getAccountDeliveryCountries(List<Input> inputs)
    {
        List<Output> result = new List<Output>();
        result.add(new Output());
        result[0].keyValuePairs = new List<KeyValuePair__mdt>();

        Account acc = [SELECT Id, Name, Destination_Country_Codes__c FROM Account WHERE Id = :inputs[0].accountId];

        Schema.DescribeFieldResult f = Account.BillingCountryCode.getDescribe();
        for (Schema.PicklistEntry ple : f.getPicklistValues())
        {
            if (acc.Destination_Country_Codes__c.contains(ple.getValue())) {
                result[0].keyValuePairs.add(new KeyValuePair__mdt(MasterLabel = ple.getLabel(), DeveloperName = ple.getValue()));
            }
        }
        return result;
    }
}