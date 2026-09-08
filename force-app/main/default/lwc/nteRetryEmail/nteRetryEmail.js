import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import retryDispatch from '@salesforce/apex/NTEEmailDispatchService.retryDispatch';
import retryApprovalEmail from '@salesforce/apex/NTEExhibitorApprovalEmailService.retryApprovalEmail';
import retryAcknowledgement from '@salesforce/apex/NTEUpdateSubmissionService.retryAcknowledgement';

export default class NteRetryEmail extends LightningElement {
    @api recordId;
    running = false;

    @api
    async invoke() {
        if (this.running) return;
        this.running = true;
        const recordId = this.recordId;
        try {
            let result;
            let successTitle = 'Email queued';
            if (recordId?.startsWith('006')) {
                result = await retryApprovalEmail({ opportunityId: recordId });
            } else if (recordId?.startsWith('00Q')) {
                const acknowledgement = await retryAcknowledgement({ leadId: recordId });
                result = { queuedCount: acknowledgement.success ? 1 : 0, message: acknowledgement.message };
                successTitle = 'Acknowledgement processed';
            } else {
                result = await retryDispatch({ dispatchId: recordId });
            }
            let refreshFailed = false;
            try {
                await notifyRecordUpdateAvailable([{ recordId }]);
            } catch (error) {
                refreshFailed = true;
            }
            this.dispatchEvent(new ShowToastEvent({
                title: result.queuedCount ? successTitle : 'Email needs attention',
                message: result.message + (refreshFailed ? ' Refresh the page to see the current status.' : ''),
                variant: result.queuedCount && !refreshFailed ? 'success' : 'warning'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Email could not be queued',
                message: error?.body?.message || error?.message || 'Check the email record and try again.',
                variant: 'error'
            }));
        } finally {
            this.running = false;
        }
    }
}
