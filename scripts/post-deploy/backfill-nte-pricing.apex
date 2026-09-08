// Recalculate only NTE partner/sponsor and exhibitor application records.
// This script performs updates only; it does not create or delete records.
Set<Id> leadIds = new Map<Id, Lead>([
    SELECT Id
    FROM Lead
    WHERE Web_Form_Type__c IN ('Partner / Sponsor Application', 'Exhibitor Application')
]).keySet();
NTEPricingService.recalculateLeads(leadIds);

Set<Id> opportunityIds = new Map<Id, Opportunity>([
    SELECT Id
    FROM Opportunity
    WHERE NTE_Source_Form_Type__c IN ('Partner / Sponsor Application', 'Exhibitor Application')
]).keySet();
NTEPricingService.recalculateOpportunities(opportunityIds);

System.debug(LoggingLevel.INFO, 'NTE pricing backfill updated ' + leadIds.size() + ' Leads and ' + opportunityIds.size() + ' Opportunities.');
