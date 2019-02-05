/* 
 * SharingUnitOfWork
 * 
 * UnitOfWork pattern class used for adding and removing 
 * AccountTeamMember and OpportunityTeamMember records dynamically
 * 
 * USAGE:
 * 
 * Use the Team Member Sharing custom metadata type to list any roles
 * and the roles' access levels for related objects. This will ensure
 * all Accout Team Members added have the correct access levels. 
 * 
 * Navigate to Setup --> Develop --> Custom Metadata Types --> Team Member Sharing.
 * Click Manage Records to add or edit any Team Member Sharing records. 
 * 
 * Create an new SharingUnitOfWork instance:
 * 
 * 		SharingUnitOfWork uow = new SharingUnitOfWork();
 * 
 * Use the add and remove methods to store the AccountTeamMembers and
 * OpportunityTeamMembers to be inserted or removed:
 * 
 * 		uow.addAccountTeamMember(userId, accountId, role);
 * 		uow.removeAccountTeamMember(userId, accountId);
 * 		uow.addOpportunityTeamMember(userId, opportunityId, role);
 * 		uow.removeOpportunityTeamMember(userId, opportunityId);
 * 
 * Once all potential team member transactions have been stored,
 * use the commitChanges method to insert/remove team members
 * 
 * 		uow.commitChanges();
 * 
 */
public without sharing class SharingUnitOfWork {
    /**
     * Private Instance Variables
     */ 
    private Map<String, List<AccountTeamMember>> accountTeamMemberInsertMap = new Map<String, List<AccountTeamMember>>();
    private Set<Id> accountIdsForDeletes = new Set<Id>();
    private Map<String, String> accountTeamMemberDeleteMap = new Map<String, String>();
    private Map<String, List<OpportunityTeamMember>> oppTeamMemberInsertMap = new Map<String, List<OpportunityTeamMember>>();
    private Set<Id> oppIdsForDeletes = new Set<Id>();
    private Map<String, String> oppTeamMemberDeleteMap = new Map<String, String>();
    
    
    /**
     * Helper Methods
     */ 
    
    /**
     * Used by the commitChanges method to create the list of Team Member records to be inserted.
     * @param teamType  String indicating the type of team. Options: 'Account' or 'Opportunity'.
     * @param tmInsertMap  Account-to-Team Member insert map. Should be one of the Private Instance Variable insert maps.
     * @return tmInsertList  List of compiled TeamMember records to be inserted by commitChanges.
     */
    private List<sObject> buildTeamMemberInsertList(String teamType, Map<String, List<sObject>> tmInsertMap) {
        List<sObject> tmInsertList = new List<sObject>();
        if (!tmInsertMap.isEmpty()) {
            Map<String,Team_Member_Sharing__mdt> roleAccessMap = new Map<String,Team_Member_Sharing__mdt>();
            for (Team_Member_Sharing__mdt tms : [SELECT Role__c, AccountAccessLevel__c, CaseAccessLevel__c, ContactAccessLevel__c, OpportunityAccessLevel__c FROM Team_Member_Sharing__mdt WHERE Team_Type__c = :teamType AND Role__c IN :tmInsertMap.keySet()]) {
                roleAccessMap.put(tms.Role__c, tms);
            }
            for (String role : tmInsertMap.keySet()) {
                if (roleAccessMap.containsKey(role)) {
                	Team_Member_Sharing__mdt roleAccess = roleAccessMap.get(role);
                    for (sObject tm : tmInsertMap.get(role)) {
                        if (teamType == 'Account') {
                            AccountTeamMember atm = (AccountTeamMember) tm;
                            atm.AccountAccessLevel = roleAccess.AccountAccessLevel__c;
                        	atm.CaseAccessLevel = roleAccess.CaseAccessLevel__c;
                        	atm.ContactAccessLevel = roleAccess.ContactAccessLevel__c;
                        	atm.OpportunityAccessLevel = roleAccess.OpportunityAccessLevel__c;
                            tmInsertList.add(atm);
                        } else if (teamType == 'Opportunity') {
                            OpportunityTeamMember otm = (OpportunityTeamMember) tm;
                            otm.OpportunityAccessLevel = roleAccess.OpportunityAccessLevel__c;
                        	tmInsertList.add(otm);
                        }
                    }
                }
            }
        }
        return tmInsertList;
    }
    
    /**
     * Used by the commitChanges method to create the list of Team Member records to be deleted.
     * @param teamType  String indicating the type of team. Options: 'Account' or 'Opportunity'.
     * @param tmDeleteMap  Account-to-Team Member insert map. Should be one of the Private Instance Variable delete maps.
     * @return tmDeleteList  List of compiled TeamMember records to be deleted by commitChanges.
     */
    private List<sObject> buildTeamMemberDeleteList(String teamType, Map<String, String> tmDeleteMap, Set<Id> objectIdsForDeletes) {
        List<sObject> tmDeleteList = new List<sObject>();
        if (!tmDeleteMap.isEmpty()) {
            if (teamType == 'Account') {
                List<AccountShare> accountShares = [SELECT Id, AccountId, UserOrGroupId FROM AccountShare WHERE AccountId IN :objectIdsForDeletes AND RowCause IN ('Manual', 'Team')];
                for(AccountShare share : accountShares) {
                    if (tmDeleteMap.containsKey(share.AccountId + '-' + share.UserOrGroupId)) {
                        tmDeleteList.add(share);
                    }
                }
            } else if (teamType == 'Opportunity') {
                List<OpportunityShare> opportunityShares = [SELECT Id, OpportunityId, UserOrGroupId FROM OpportunityShare WHERE OpportunityId IN :objectIdsForDeletes AND RowCause IN ('Manual', 'Team')];
                for(OpportunityShare share : opportunityShares) {
                    if (tmDeleteMap.containsKey(share.OpportunityId + '-' + share.UserOrGroupId)) {
                        tmDeleteList.add(share);
                    }
                }
            }
        }
        return tmDeleteList;
    }
    
    /**
     * Public API
     */ 
    
    /**
     * Used to store Account Team Member records to be inserted
     * @param userId  ID of the user to be added to the Account Team
     * @param accountId  ID of the account for the Account Team
     * @param role  String of the Account Team Member role. This should match a Role value in a Team Member Sharing record with a Team Type of 'Account'. 
     */
    public void addAccountTeamMember(Id userId, Id accountId, String role) {
        if (accountTeamMemberInsertMap.containsKey(role)) {
            accountTeamMemberInsertMap.get(role).add(new AccountTeamMember(UserId=userId, AccountId=accountId, TeamMemberRole=role));
        } else {
            accountTeamMemberInsertMap.put(role, new List<AccountTeamMember> { new AccountTeamMember(UserId=userId, AccountId=accountId, TeamMemberRole=role) });
        }
    }
    
    /**
     * Used to store Account Team Member records to be deleted
     * @param userId  ID of the user to be removed from the Account Team
     * @param accountId  ID of the account for the Account Team
     */
    public void removeAccountTeamMember(Id userId, Id accountId) {
        accountIdsForDeletes.add(accountId);
        String mapKey = accountId + '-' + userId;
        accountTeamMemberDeleteMap.put(mapKey, userId);
    }
    
    /**
     * Used to store Opportunity Team Member records to be inserted
     * @param userId  ID of the user to be added to the Opportunity Team
     * @param opportunityId  ID of the Opportunity for the Opportunity Team
     * @param role  String of the Opportunity Team Member role. This should match a Role value in a Team Member Sharing record with a Team Type of 'Opportunity'. 
     */
    public void addOpportunityTeamMember(Id userId, Id opportunityId, String role) {
        if (oppTeamMemberInsertMap.containsKey(role)) {
            oppTeamMemberInsertMap.get(role).add(new OpportunityTeamMember(UserId=userId, OpportunityId=opportunityId, TeamMemberRole=role));
        } else {
            oppTeamMemberInsertMap.put(role, new List<OpportunityTeamMember> { new OpportunityTeamMember(UserId=userId, OpportunityId=opportunityId, TeamMemberRole=role) });
        }
    }
    
    /**
     * Used to store Opportunity Team Member records to be deleted
     * @param userId  ID of the user to be removed from the Opportunity Team
     * @param opportunityId  ID of the Opportunity for the Opportunity Team
     */
    public void removeOpportunityTeamMember(Id userId, Id opportunityId) {
        oppIdsForDeletes.add(opportunityId);
        String mapKey = opportunityId + '-' + userId;
        oppTeamMemberDeleteMap.put(mapKey, userId);
    }
    
    /**
     * Used to commit and save all Team Member insert and delete transactions.
     * Should be called after any add or remove team member method calls
     */
    public void commitChanges() {
        Savepoint sp = Database.setSavePoint();
        try {
            List<AccountTeamMember> atmsToInsert = buildTeamMemberInsertList('Account', accountTeamMemberInsertMap);
            if (!atmsToInsert.isEmpty()) {
                insert atmsToInsert;
            }
            
            List<AccountShare> acctSharesToDelete = buildTeamMemberDeleteList('Account', accountTeamMemberDeleteMap, accountIdsForDeletes);
            if (!acctSharesToDelete.isEmpty()) {
                delete acctSharesToDelete;
            }
            
            List<OpportunityTeamMember> otmsToInsert = buildTeamMemberInsertList('Opportunity', oppTeamMemberInsertMap);
            if (!otmsToInsert.isEmpty()) {
                insert otmsToInsert;
            }
            
            List<OpportunityShare> oppSharesToDelete = buildTeamMemberDeleteList('Opportunity', oppTeamMemberDeleteMap, oppIdsForDeletes);
            if (!oppSharesToDelete.isEmpty()) {
                delete oppSharesToDelete;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }
}