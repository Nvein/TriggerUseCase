public class AddContactRolesHandler {
    
    // New Opp with Closed Won Insertion
    public static void handleAfterInsert(List<Opportunity> oppList) {
        List<Opportunity> newClosedWonOpps = new List<Opportunity>();
        for (Opportunity opp : oppList) {
            if (opp.StageName == 'Closed Won' && opp.AccountId != null) {
                newClosedWonOpps.add(opp);
            }
        }
        System.debug('newClosedWonOpps should be 1 size: '+ newClosedWonOpps.size());
        createContactRoles(newClosedWonOpps);
    }
    
    // Stage Updated to Closed Won
    // AccountId Changed for a closed Won Opportunity
    // Stage Reversed from Closed Won
    public static void handleAfterUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        List<Opportunity> newClosedWonOpps = new List<Opportunity>();
        List<Opportunity> accountChangedOpps = new List<Opportunity>();
        List<Opportunity> stageReversedOpps = new List<Opportunity>();
        
        for (Opportunity opp : newMap.values()) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            
            Boolean nowClosedWon = (opp.StageName == 'Closed Won');
            Boolean wasClosedWon = (oldOpp.StageName == 'Closed Won');
            Boolean accountChanged = (opp.AccountId != oldOpp.AccountId);
            
            // If Stage changed to Closed Won → add OCRs
            if (nowClosedWon && !wasClosedWon && opp.AccountId != null) {
                newClosedWonOpps.add(opp);
            }
            
            // If Account changed while Closed Won : delete old ocr + add new OCRs
            if (nowClosedWon && accountChanged) {
                accountChangedOpps.add(opp);
            }
            
            // If Stage changed from Closed Won : delete OCRs
            if (!nowClosedWon && wasClosedWon) {
                stageReversedOpps.add(opp);
            }
        }
        
        // Delete old OCRs - Deletion Comes first
        deleteContactRoles(accountChangedOpps, oldMap);
        deleteContactRoles(stageReversedOpps, oldMap);
        
        // Add new OCRs for Closed Won or changed Account
        createContactRoles(newClosedWonOpps);
        createContactRoles(accountChangedOpps);
    }
    
    // Create OCRs for all Contacts under Account
    private static void createContactRoles(List<Opportunity> oppList) {
        if (oppList.isEmpty()) return;
        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppList) {
            if (opp.AccountId != null)
                accountIds.add(opp.AccountId);
        }
        
        Map<Id, Set<Id>> accountIdWithContactIds = new Map<Id, Set<Id>>();
        List<Contact> contactList = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds];
        System.debug('Associate contact with acc: '+ contactList.size());
        for (Contact con : contactList ){
            if (!accountIdWithContactIds.containsKey(con.AccountId)) {
                accountIdWithContactIds.put(con.AccountId, new Set<Id>());
            }
            accountIdWithContactIds.get(con.AccountId).add(con.Id);
        }
        
        List<OpportunityContactRole> ocrInsertList = new List<OpportunityContactRole>();
        for (Opportunity opp : oppList) {
            List<OpportunityContactRole> ocrListInitial = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
            System.debug('Size of ocrList initial: '+ ocrListInitial.size());
            Set<Id> contactIds = accountIdWithContactIds.get(opp.AccountId);
            if (contactIds != null) {
                for (Id contactId : contactIds) {
                    ocrInsertList.add(new OpportunityContactRole(
                        OpportunityId = opp.Id,
                        ContactId = contactId,
                        Role = 'Family Member',
                        IsPrimary = false
                    ));
                }
            }
        }
        System.debug('ocrInsertList size: '+ocrInsertList.size());
        
        if (!ocrInsertList.isEmpty()) {
            insert ocrInsertList;
        }
    }
    
    // Delete OCRs for given Opportunities
    private static void deleteContactRoles(List<Opportunity> oppList, Map<Id, Opportunity> oldMap) {
        if (oppList.isEmpty()) return;
        
        Set<Id> oppIdsToDelete = new Set<Id>();
        for (Opportunity opp : oppList) {
            oppIdsToDelete.add(opp.Id);
        }
        
        List<OpportunityContactRole> ocrToDelete = [
            SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :oppIdsToDelete
        ];
        
        if (!ocrToDelete.isEmpty()) {
            delete ocrToDelete;
        }
    }
}