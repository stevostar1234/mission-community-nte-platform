import { LightningElement, api, wire } from "lwc";
import getRelationships from "@salesforce/apex/NTERelatedOpportunityController.getRelationships";

const CURRENCY = new Intl.NumberFormat("en-GB", {
    style: "currency",
    currency: "GBP",
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
});

const DATE = new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric"
});

export default class NteRelatedOpportunities extends LightningElement {
    @api recordId;
    @api objectApiName;

    title = "NTE Relationships";
    emptyMessage = "No NTE relationships are available.";
    opportunities = [];
    contacts = [];
    account;
    errorMessage = "";
    isLoading = true;
    mode = "";

    @wire(getRelationships, { recordId: "$recordId", objectApiName: "$objectApiName" })
    wiredRelationships({ data, error }) {
        if (data) {
            this.title = data.title;
            this.emptyMessage = data.emptyMessage;
            this.mode = data.mode;
            this.account = data.account ? this.normalizeAccount(data.account) : null;
            this.opportunities = (data.opportunities || []).map((item) => this.normalizeOpportunity(item));
            this.contacts = (data.contacts || []).map((item) => this.normalizeContact(item));
            this.errorMessage = "";
            this.isLoading = false;
        } else if (error) {
            this.errorMessage = "NTE relationships could not be loaded.";
            this.isLoading = false;
        }
    }

    get showsOpportunities() {
        return this.mode === "opportunities";
    }

    get showsRelationships() {
        return this.mode === "relationships";
    }

    get objectApiNameIsContact() {
        return this.objectApiName === "Contact";
    }

    get hasOpportunities() {
        return this.opportunities.length > 0;
    }

    get hasContacts() {
        return this.contacts.length > 0;
    }

    get hasOpportunityRelationships() {
        return Boolean(this.account) || this.hasContacts;
    }

    normalizeOpportunity(item) {
        return {
            ...item,
            url: `/lightning/r/Opportunity/${item.id}/view`,
            amountText: item.amount == null ? "—" : CURRENCY.format(Number(item.amount)),
            closeDateText: item.closeDate ? DATE.format(new Date(`${item.closeDate}T12:00:00`)) : "—",
            contactText: item.primaryContact ? "Primary contact" : "Linked contact"
        };
    }

    normalizeAccount(item) {
        return {
            ...item,
            url: `/lightning/r/Account/${item.id}/view`
        };
    }

    normalizeContact(item) {
        return {
            ...item,
            url: `/lightning/r/Contact/${item.id}/view`,
            roleText: item.primaryContact ? "Primary contact" : item.role || "Linked contact",
            phoneText: item.phone || "—",
            emailText: item.email || "—",
            emailLink: item.email ? `mailto:${item.email}` : null
        };
    }
}
