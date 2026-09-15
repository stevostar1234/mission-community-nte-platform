trigger NTELeadConversionGuard on Lead (after update) { NTEConversionGuard.validate(Trigger.new, Trigger.oldMap); }
