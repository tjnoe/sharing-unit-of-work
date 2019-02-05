# Sharing Unit of Work

UnitOfWork pattern class used for adding and removing AccountTeamMember and OpportunityTeamMember records dynamically in Salesforce.

## Usage

Use the Team Member Sharing custom metadata type to list any roles
and the roles' access levels for related objects. This will ensure
all Accout Team Members added have the correct access levels. 

Navigate to Setup --> Develop --> Custom Metadata Types --> Team Member Sharing.
Click Manage Records to add or edit any Team Member Sharing records. 

Create an new SharingUnitOfWork instance:
```
		SharingUnitOfWork uow = new SharingUnitOfWork();
```
Use the add and remove methods to store the AccountTeamMembers and
OpportunityTeamMembers to be inserted or removed:
```
		uow.addAccountTeamMember(userId, accountId, role);
		uow.removeAccountTeamMember(userId, accountId);
		uow.addOpportunityTeamMember(userId, opportunityId, role);
		uow.removeOpportunityTeamMember(userId, opportunityId);
```
Once all potential team member transactions have been stored,
use the commitChanges method to insert/remove team members
```
		uow.commitChanges();
```