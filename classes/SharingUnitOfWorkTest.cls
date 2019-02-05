/* 
 * SharingUnitOfWorkTest
 * 
 * Test class for SharingUnitOfWork
 * 
 */
@isTest
private class SharingUnitOfWorkTest {
    @testSetup static void setup() {
        List<User> testUsers = new List<User>();
        for (Integer i=0; i<10; i++) {
            User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'SUOW Test ' + i,
                Email = 'testuser' + i + '@testuser.com',
                Username = 'testuser' + i + '@testuser.com' + System.currentTimeMillis(),
                CompanyName = 'Test',
                Title = 'Title',
                Alias = 'test' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
            );
            testUsers.add(u);
        }
        insert testUsers;
        
        System.runAs(testUsers[0]) {
            List<Account> testAccounts = new List<Account>();
            for (Integer i=0; i<10; i++) {
                Account a = new Account(Name='Test Account ' + i);
                testAccounts.add(a);
            }
            insert testAccounts;
            
            List<Opportunity> testOpportunities = new List<Opportunity>();
            for (Integer i=0; i<10; i++) {
                Opportunity o = new Opportunity(
                    Name='Test Opportunity ' + i,
                    StageName='Prospecting',
                    CloseDate=System.today().addDays(1),
                    AccountId=testAccounts[i].Id
                );
                testOpportunities.add(o);
            }
            insert testOpportunities;
        }
    }
    
    @isTest static void testAddAndRemoveAccountTeamMember() {
        List<User> testUsers = [SELECT Id FROM User WHERE LastName LIKE 'SUOW Test%'];
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 2];
        System.runAs(testUsers[0]) {
            SharingUnitOfWork uow = new SharingUnitOfWork();
            uow.addAccountTeamMember(testUsers[0].Id, testAccounts[0].Id, 'TEST EDIT ONLY');
            uow.addAccountTeamMember(testUsers[1].Id, testAccounts[0].Id, 'TEST READ ONLY');
            uow.addAccountTeamMember(testUsers[2].Id, testAccounts[1].Id, 'TEST READ ONLY');
            uow.commitChanges();
            
            System.assertEquals(1, [SELECT Id FROM AccountTeamMember WHERE AccountId=:testAccounts[0].Id AND TeamMemberRole='TEST EDIT ONLY'].size());
        	System.assertEquals(2, [SELECT Id FROM AccountTeamMember WHERE AccountId IN (:testAccounts[0].Id, :testAccounts[1].Id) AND TeamMemberRole='TEST READ ONLY'].size());
            
            uow = new SharingUnitOfWork();
            uow.removeAccountTeamMember(testUsers[0].Id, testAccounts[0].Id);
            uow.removeAccountTeamMember(testUsers[2].Id, testAccounts[1].Id);
            uow.commitChanges();
            
            System.assertEquals(0, [SELECT Id FROM AccountTeamMember WHERE AccountId=:testAccounts[0].Id AND TeamMemberRole='TEST EDIT ONLY'].size());
        	System.assertEquals(1, [SELECT Id FROM AccountTeamMember WHERE AccountId IN (:testAccounts[0].Id, :testAccounts[1].Id) AND TeamMemberRole='TEST READ ONLY'].size());
        }
    }
    
    @isTest static void testAddAndRemoveOpportunityTeamMember() {
        List<User> testUsers = [SELECT Id FROM User WHERE LastName LIKE 'SUOW Test%'];
        List<Opportunity> testOpportunities = [SELECT Id FROM Opportunity LIMIT 2];
        System.runAs(testUsers[0]) {
            SharingUnitOfWork uow = new SharingUnitOfWork();
            uow.addOpportunityTeamMember(testUsers[0].Id, testOpportunities[0].Id, 'TEST EDIT ONLY OPP');
            uow.addOpportunityTeamMember(testUsers[1].Id, testOpportunities[0].Id, 'TEST READ ONLY OPP');
            uow.addOpportunityTeamMember(testUsers[2].Id, testOpportunities[1].Id, 'TEST READ ONLY OPP');
            uow.commitChanges();
            
            System.assertEquals(1, [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId=:testOpportunities[0].Id AND TeamMemberRole='TEST EDIT ONLY OPP'].size());
        	System.assertEquals(2, [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId IN (:testOpportunities[0].Id, :testOpportunities[1].Id) AND TeamMemberRole='TEST READ ONLY OPP'].size());
            
            uow = new SharingUnitOfWork();
            uow.removeOpportunityTeamMember(testUsers[0].Id, testOpportunities[0].Id);
            uow.removeOpportunityTeamMember(testUsers[2].Id, testOpportunities[1].Id);
            uow.commitChanges();
            
            System.assertEquals(0, [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId=:testOpportunities[0].Id AND TeamMemberRole='TEST EDIT ONLY OPP'].size());
        	System.assertEquals(1, [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId IN (:testOpportunities[0].Id, :testOpportunities[1].Id) AND TeamMemberRole='TEST READ ONLY OPP'].size());
        }
    }
    
    @isTest static void testAddAndRemoveCombined() {
        List<User> testUsers = [SELECT Id FROM User WHERE LastName LIKE 'SUOW Test%'];
        List<Opportunity> testOpportunities = [SELECT Id FROM Opportunity LIMIT 2];
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 2];
        System.runAs(testUsers[0]) {
            SharingUnitOfWork uow = new SharingUnitOfWork();
            uow.addAccountTeamMember(testUsers[0].Id, testAccounts[0].Id, 'TEST EDIT ONLY');
            uow.addAccountTeamMember(testUsers[1].Id, testAccounts[0].Id, 'TEST READ ONLY');
            uow.addAccountTeamMember(testUsers[2].Id, testAccounts[1].Id, 'TEST READ ONLY');
            uow.addOpportunityTeamMember(testUsers[0].Id, testOpportunities[0].Id, 'TEST EDIT ONLY OPP');
            uow.addOpportunityTeamMember(testUsers[1].Id, testOpportunities[0].Id, 'TEST READ ONLY OPP');
            uow.addOpportunityTeamMember(testUsers[2].Id, testOpportunities[1].Id, 'TEST READ ONLY OPP');
            uow.commitChanges();
            
            System.assertEquals(1, [SELECT Id FROM AccountTeamMember WHERE AccountId=:testAccounts[0].Id AND TeamMemberRole='TEST EDIT ONLY'].size());
        	System.assertEquals(2, [SELECT Id FROM AccountTeamMember WHERE AccountId IN (:testAccounts[0].Id, :testAccounts[1].Id) AND TeamMemberRole='TEST READ ONLY'].size());
            System.assertEquals(1, [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId=:testOpportunities[0].Id AND TeamMemberRole='TEST EDIT ONLY OPP'].size());
        	System.assertEquals(2, [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId IN (:testOpportunities[0].Id, :testOpportunities[1].Id) AND TeamMemberRole='TEST READ ONLY OPP'].size());
            
            uow = new SharingUnitOfWork();
            uow.removeAccountTeamMember(testUsers[0].Id, testAccounts[0].Id);
            uow.removeAccountTeamMember(testUsers[2].Id, testAccounts[1].Id);
            uow.removeOpportunityTeamMember(testUsers[0].Id, testOpportunities[0].Id);
            uow.removeOpportunityTeamMember(testUsers[2].Id, testOpportunities[1].Id);
            uow.addAccountTeamMember(testUsers[0].Id, testAccounts[1].Id, 'TEST EDIT ONLY');
            uow.addOpportunityTeamMember(testUsers[1].Id, testOpportunities[1].Id, 'TEST EDIT ONLY OPP');
            uow.commitChanges();
            
        	System.assertEquals(2, [SELECT Id FROM AccountTeamMember WHERE AccountId IN (:testAccounts[0].Id, :testAccounts[1].Id)].size());
        	System.assertEquals(2, [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId IN (:testOpportunities[0].Id, :testOpportunities[1].Id)].size());
        }
    }
    
    @isTest static void testAddAndRemoveBulk() {
        List<User> testUsers = [SELECT Id FROM User WHERE LastName LIKE 'SUOW Test%'];
        List<Opportunity> testOpportunities = [SELECT Id FROM Opportunity];
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.runAs(testUsers[0]) {
            SharingUnitOfWork uow = new SharingUnitOfWork();
            for (Integer i=0; i<10; i++) {
                uow.addAccountTeamMember(testUsers[i].Id, testAccounts[i].Id, 'TEST EDIT ONLY');
                uow.addOpportunityTeamMember(testUsers[i].Id, testOpportunities[i].Id, 'TEST EDIT ONLY OPP');
            }
            uow.commitChanges();
            
            System.assertEquals(10, [SELECT Id FROM AccountTeamMember WHERE TeamMemberRole='TEST EDIT ONLY'].size());
            System.assertEquals(10, [SELECT Id FROM OpportunityTeamMember WHERE TeamMemberRole='TEST EDIT ONLY OPP'].size());
            
            uow = new SharingUnitOfWork();
            for (Integer i=0; i<10; i++) {
                uow.removeAccountTeamMember(testUsers[i].Id, testAccounts[i].Id);
                uow.removeOpportunityTeamMember(testUsers[i].Id, testOpportunities[i].Id);
            }
            uow.commitChanges();
            
        	System.assertEquals(0, [SELECT Id FROM AccountTeamMember WHERE TeamMemberRole='TEST EDIT ONLY'].size());
        	System.assertEquals(0, [SELECT Id FROM OpportunityTeamMember WHERE TeamMemberRole='TEST EDIT ONLY OPP'].size());
        }
    }
}