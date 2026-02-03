public without sharing class TPQCheckAccountTrailerTypes {
    private static final String DELIMITER = ';';

    public class Request {
        @InvocableVariable(required=true)
        public String accountTrailerTypesString;

        @InvocableVariable(required=true)
        public String selectedTrailerTypesString;
    }

    public class Response {
        @InvocableVariable
        public Boolean valid;
    }

    @InvocableMethod(label='TPQ Check Account Trailer Types' description='Check if user selected valid trailer types')
    public static List<Response> checkTrailerTypes(List<Request> requestList) {
        List<Response> results = new List<Response>();
        
        if (requestList == null || requestList.isEmpty()) {
            Response res = new Response();
            res.valid = false;
            results.add(res);
            return results;
        }

        Request req = requestList[0];
        Boolean valid = false;
        
        if (String.isNotBlank(req.accountTrailerTypesString) && String.isNotBlank(req.selectedTrailerTypesString)) {
            Set<String> accountTrailerTypes = normalizeTrailerTypes(req.accountTrailerTypesString.split(DELIMITER));
            Set<String> selectedTrailerTypes = normalizeTrailerTypes(req.selectedTrailerTypesString.split(DELIMITER));
            
            // Check if at least one selected type exists in account types
            for (String selectedType : selectedTrailerTypes) {
                if (accountTrailerTypes.contains(selectedType)) {
                    valid = true;
                    break;
                }
            }
        }

        Response res = new Response();
        res.valid = valid;
        results.add(res);

        return results;
    }

    private static Set<String> normalizeTrailerTypes(List<String> trailerTypes) {
        Set<String> normalized = new Set<String>();
        for (String trailerType : trailerTypes) {
            if (String.isNotBlank(trailerType)) {
                normalized.add(trailerType.trim().toLowerCase());
            }
        }
        return normalized;
    }
}