public with sharing class PriceRequestTriggerHandler {
    
    public static void sendEmailToContact(Map<Id, Price_Request__c> newMap, Map<Id, Price_Request__c> oldMap){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        Id orgWideEmailId = getOrgWideEmailAddressId();

        for(Price_Request__c pr : newMap.values()){
            if(oldMap != null && oldMap.containsKey(pr.Id) && (oldMap.get(pr.Id).Stage__c == 'Answer received' || oldMap.get(pr.Id).Stage__c == 'Completed')
             && pr.Stage__c == 'Answer pending' && pr.Contacts_emails__c != null){
                
                List<String> listEmailToSend = pr.Contacts_emails__c.split(';');

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(listEmailToSend);
                mail.setSubject('Your request for a price update has been approved');

                if(orgWideEmailId != null) {mail.setOrgWideEmailAddressId(orgWideEmailId);}

                String portalUrl = pr.Portal_URL__c != null ? pr.Portal_URL__c.trim() : '';
                String body = 
                    'Dear Sir/Madam,\n\n' +
                    'We hope this message finds you well.\n\n' +
                    'Your request has been approved. You can now make changes to your submitted freight prices in the portal at your convenience.\n\n' +
                    'Portal access link:\n' +
                    (portalUrl != '' ? portalUrl + '\n\n' : '\n') +
                    'If you have any questions or experience any issues accessing the portal, please don’t hesitate to contact us.\n\n' +
                    'Thank you for your prompt attention to this update.\n\n' +
                    'Best regards,\n\n' +
                    'The ECL Team';

                mail.setPlainTextBody(body);
                mails.add(mail);
            }
        }
        if(!mails.isEmpty()) {
            try {
                Messaging.sendEmail(mails);
            } catch (Exception e) {
                System.debug('Error sending PriceRequest emails: ' + e);
            }
        }
    }

    private static Id getOrgWideEmailAddressId() {
        try {            
            OrgWideEmailAddress[] oweaFallback = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                LIMIT 1
            ];
            
            return !oweaFallback.isEmpty() ? oweaFallback[0].Id : null;
            
        } catch (Exception e) {
            System.debug('Error retrieving Organization-Wide Email Address: ' + e);
            return null;
        }
    }

}