public with sharing class AccountAccessCodeAction {

    private static final String CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    private static final Integer CODE_LENGTH = 9;

    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    @InvocableMethod(label='Generate Account Access Code')
    public static void generatePortalAccessCode(List<Request> requestList) {
        Request req = requestList[0];
        update new Account(Id = req.accountId, Access_code__c = generateCode());
    }

    private static String generateCode() {
        String code = '';

        for (Integer i = 0; i < CODE_LENGTH; i++) {
            Integer rand = Math.abs(Crypto.getRandomInteger());
            Integer index = Math.mod(rand, CHARS.length());
            code += CHARS.substring(index, index + 1);
        }

        return code;
    }
}