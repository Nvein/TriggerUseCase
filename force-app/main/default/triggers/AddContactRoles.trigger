trigger AddContactRoles on Opportunity (after insert, after update, after delete, after undelete) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AddContactRolesHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            AddContactRolesHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
    
}