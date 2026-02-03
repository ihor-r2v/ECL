trigger PriceRequestTrigger on Price_Request__c (before insert,before update,before delete,after insert,after update,after delete,after undelete) {
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        PriceRequestTriggerHandler.sendEmailToContact((Map<Id, Price_Request__c>) Trigger.newMap, (Map<Id, Price_Request__c>) Trigger.oldMap);
    }

}