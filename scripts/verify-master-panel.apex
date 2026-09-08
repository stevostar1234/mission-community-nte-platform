String eventCode = 'NTE2027';
Map<String, Integer> queueCounts = new Map<String, Integer>();
NTE_MasterPanelController.DashboardResponse reconciliation = NTE_MasterPanelController.getDashboard(
    eventCode, 'ALL', null, 'INVOICE_REQUIRED', 25, 0
);
System.assertEquals(eventCode, reconciliation.selectedEventCode, 'The requested event filter must be retained.');
System.assertEquals('INVOICE_REQUIRED', reconciliation.selectedViewKey, 'The requested queue must be retained.');
System.assert(reconciliation.rows.size() <= 25, 'A Master Panel page cannot exceed its page size.');
for (NTE_MasterPanelController.DashboardRow row : reconciliation.rows) {
    System.assertEquals(eventCode, row.eventCode, 'Every row must honour the event filter.');
    System.assertNotEquals(null, row.recordUrl, 'Every row must provide record drill-down.');
}
System.assertEquals(4, reconciliation.summary.size(), 'Event Summary must contain its four required metrics.');
System.assertEquals(7, reconciliation.pipeline.size(), 'The event pipeline must contain seven stages.');
System.assertEquals(9, reconciliation.workQueues.size(), 'All operational queues must be available.');
for (NTE_MasterPanelController.WorkQueue queue : reconciliation.workQueues) {
    queueCounts.put(queue.key, queue.count);
}

Integer submitted = [
    SELECT COUNT() FROM Lead
    WHERE NTE_Event_Code__c = :eventCode
    AND Web_Form_Type__c IN (
        'Partner / Sponsor Expression of Interest', 'Exhibitor Expression of Interest',
        'Partner / Sponsor Application', 'Exhibitor Application', 'Guest Registration'
    )
];
Integer confirmed = [
    SELECT COUNT() FROM Opportunity
    WHERE NTE_Event_Code__c = :eventCode
    AND NTE_Source_Form_Type__c IN ('Partner / Sponsor Application', 'Exhibitor Application')
    AND StageName != 'Closed Lost'
];
Map<String, Integer> summaryCounts = new Map<String, Integer>();
for (NTE_MasterPanelController.SummaryMetric metric : reconciliation.summary) {
    summaryCounts.put(metric.key, metric.value);
}
System.assertEquals(submitted, summaryCounts.get('submitted'), 'Submitted total must reconcile to source Leads.');
System.assertEquals(confirmed, summaryCounts.get('confirmed'), 'Confirmed total must reconcile to source Opportunities.');
System.assertEquals(confirmed,
    summaryCounts.get('progress') + summaryCounts.get('complete'),
    'Every confirmed booking must be either in progress or complete.'
);

System.debug(LoggingLevel.INFO,
    'NTE MASTER PANEL VERIFIED | event=' + eventCode
    + ' | submitted=' + submitted
    + ' | confirmed=' + confirmed
    + ' | complete=' + summaryCounts.get('complete')
    + ' | queues=' + JSON.serialize(queueCounts)
);
