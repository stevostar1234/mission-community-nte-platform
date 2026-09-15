trigger NTEOpportunityConversionGuard on Opportunity (before update, after insert) {
    if (Trigger.isBefore) NTEBookingPriceService.applyAmountChanges(Trigger.new, Trigger.oldMap);
    else NTEConversionGuard.remember(Trigger.new);
}
