@IsTest
public class AddContactRolesHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Test Accounts
        List<Account> accList = new List<Account>{
            new Account(Name = 'Account A'),
                new Account(Name = 'Account B')
                };
                    insert accList;
        
        // Create Contacts under each Account
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Naveen', LastName = 'Sharma', AccountId = accList[0].Id),
                new Contact(FirstName = 'naveen2', LastName = 'Sharma', AccountId = accList[0].Id),
                new Contact(FirstName = 'Naveen', LastName = 'Kumar', AccountId = accList[1].Id)
                };
                    insert contacts;
    }
    
    @IsTest
    static void testAfterInsertClosedWon() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Opp Closed Won',
            StageName = 'Closed Won',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        
        Test.startTest();
        insert opp;
        Test.stopTest();
        
        List<OpportunityContactRole> ocrList = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.debug(ocrList);
        System.assertEquals(2, ocrList.size(), 'Should create 2 OCRs');
    }
    
    @IsTest
    static void testStageChangeToClosedWon() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Opp Stage Change',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        opp.StageName = 'Closed Won';
        
        Test.startTest();
        update opp;
        Test.stopTest();
        
        List<OpportunityContactRole> ocrList = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.assertEquals(2, ocrList.size(), 'Should create 2 OCRs');
    }
    
    @IsTest
    static void testAccountChangeOnClosedWon() {
        Account accA = [SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1];
        Account accB = [SELECT Id FROM Account WHERE Name = 'Account B' LIMIT 1];
        
        // Create Opp under Account A (2 contacts)
        Opportunity opp = new Opportunity(
            Name = 'Opp Account Change',
            StageName = 'Closed Won',
            CloseDate = System.today(),
            AccountId = accA.Id
        );
        insert opp;
        
        // OCR count for Account A (2 contacts)
        List<OpportunityContactRole> ocrListInitial = [SELECT Id, ContactId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.assertEquals(2, ocrListInitial.size());
        
        // Change AccountId to Account B (1 contact)
        opp.AccountId = accB.Id;
        
        Test.startTest();
        update opp;
        Test.stopTest();
        
        // After update, OCRs for Account A should be deleted, and 1 new created for Account B
        List<OpportunityContactRole> ocrList = [SELECT Id, ContactId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, ocrList.size(), 'Should have 1 OCR for account B');
    }
    
    @IsTest
    static void testStageReversedFromClosedWon() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1];
        
        Opportunity opp = new Opportunity(
            Name = 'Opp Stage Reversed',
            StageName = 'Closed Won',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        // OCR count for Account A (2 contacts)
        List<OpportunityContactRole> ocrListInitial = [SELECT Id, ContactId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.assertEquals(2, ocrListInitial.size());
        
        //update stage
        opp.StageName = 'Prospecting';
        
        Test.startTest();
        update opp;
        Test.stopTest();
        
        List<OpportunityContactRole> ocrList = [SELECT Id, ContactId FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.assertEquals(0, ocrList.size(),'Ocr should be deleted');
    }
    
    @IsTest
    static void testBulkScenario() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1];
        
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            oppList.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                StageName = 'Closed Won',
                CloseDate = System.today(),
                AccountId = acc.Id
            ));
        }
        
        Test.startTest();
        insert oppList;
        Test.stopTest();
        
        List<OpportunityContactRole> ocrList = [SELECT Id, ContactId FROM OpportunityContactRole];
        System.assertEquals(10,ocrList.size(),'Should create 2 ocr per Opp, total 10');
    }
}