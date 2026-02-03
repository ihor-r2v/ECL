({
	close : function(component, event, helper)
    {
        component.set("v.isModalOpen", false);
        let scope = component.get('v.scope');
        let masterRecordId = component.get('v.masterRecordId');
        if (masterRecordId != null && masterRecordId !== '')
        {
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
                "recordId": masterRecordId,
                "isredirect": "true"
            });
            urlEvent.fire();
        }
        else
        {      
            var homeEvent = $A.get("e.force:navigateToObjectHome");
            homeEvent.setParams({"scope": scope});
            homeEvent.fire(); 
        }
	}
})