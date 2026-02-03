({
    init : function (component) {
        component.set('v.isModalOpen', true);
        let flowElement = component.find("flowElement");
		let flowName = component.get('v.flowName');
        let sendRecordTypeId = component.get('v.sendRecordTypeIdToFlow');
        let recordTypeId = new URLSearchParams(window.location.search).get('recordTypeId');
        var inputVariables = component.get('v.inputVariables');
        if (inputVariables == null) {
			inputVariables = [];
        }
        
        if (sendRecordTypeId) {
           	inputVariables.push({
                name: 'varRecordTypeId',
                type: 'String',
                value: recordTypeId == null ? '' : recordTypeId
            });
        }
        
		if (inputVariables.length > 0) {
        	flowElement.startFlow(flowName, inputVariables);
        }                                              
        else {
        	flowElement.startFlow(flowName);
        }
    },
    
    closeFlowModal : function(component, event, helper) {
		helper.close(component, event, helper);
    },
    
	closeModalOnFinish : function(component, event, helper)
    {
    	if(event.getParam("status") === "FINISHED")
        {
        	let openNewRecord = component.get('v.tryToOpenNewRecord');
            if (openNewRecord)
            {
                var outputVariables = event.getParam("outputVariables");
                var outputVar;
                for(var i = 0; i < outputVariables.length; i++)
                {
                    outputVar = outputVariables[i];
                    if(outputVar.name === "outputVarRecordId")
                    {
                        if (outputVar.value != null && outputVar.value !== '')
                        {
                            var urlEvent = $A.get("e.force:navigateToSObject");
                            urlEvent.setParams({
                                "recordId": outputVar.value,
                                "isredirect": "true"
                                });
                            urlEvent.fire();
                        }
                        else
                        {
                            helper.close(component, event, helper);
                        }
                    } 
                }
            }
            else
            {
                helper.close(component, event, helper);
            }
		}
    },
})