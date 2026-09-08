import { LightningElement } from "lwc";
import getHomeDashboard from "@salesforce/apex/NTE_MasterPanelController.getHomeDashboard";

const CURRENCY_FORMATTER = new Intl.NumberFormat("en-GB", {
    style: "currency",
    currency: "GBP",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
});

const NUMBER_FORMATTER = new Intl.NumberFormat("en-GB", { maximumFractionDigits: 0 });

const HEADLINE_CONFIG = [
    { key: "applications", label: "Applications", aliases: ["applications", "application"] },
    {
        key: "confirmedApplications",
        label: "Approved applications",
        aliases: ["confirmedApplications", "confirmed", "approved"],
        highlighted: true
    },
    { key: "invoiced", label: "Invoiced", aliases: ["invoiced", "invoice"] },
    {
        key: "stillToCollect",
        label: "Still to collect",
        aliases: ["stillToCollect", "paymentRequired", "outstanding"]
    },
    { key: "paid", label: "Paid", aliases: ["paid", "completedPayments"] }
];

const STAGE_ICONS = {
    interest: "standard:contact_request",
    applications: "standard:lead",
    application: "standard:lead",
    approved: "standard:approval",
    finances: "standard:currency",
    finance: "standard:currency",
    updates: "standard:people",
    completed: "standard:task2"
};

const READINESS_CONFIG = [
    { key: "quoteRequired", label: "Quotes required", aliases: ["quoteRequired", "quotesRequired"] },
    { key: "invoiceRequired", label: "Invoice required", aliases: ["invoiceRequired", "invoicesRequired"] },
    { key: "paymentRequired", label: "Payment required", aliases: ["paymentRequired", "paymentsRequired"] },
    { key: "paid", label: "Payment confirmed", aliases: ["paid", "completedPayments"] }
];

export default class NteManagementHome extends LightningElement {
    selectedEventCode = "";
    eventOptions = [];
    refreshedAt = "—";
    headlineMetrics = [];
    pipelineRows = [];
    revenueReadiness = [];
    bookingMix = this.emptyBookingMix();
    pricingReviewNote = "";
    isLoading = false;
    errorMessage = "";
    hasDashboard = false;
    requestSequence = 0;
    refreshTimer;

    connectedCallback() {
        window.addEventListener("focus", this.handleWindowFocus);
        document.addEventListener("visibilitychange", this.handleVisibilityChange);
        this.loadDashboard();
    }

    disconnectedCallback() {
        window.removeEventListener("focus", this.handleWindowFocus);
        document.removeEventListener("visibilitychange", this.handleVisibilityChange);
        window.clearTimeout(this.refreshTimer);
        this.requestSequence++;
    }

    handleWindowFocus = () => {
        this.scheduleLiveRefresh();
    };

    handleVisibilityChange = () => {
        if (document.visibilityState === "visible") {
            this.scheduleLiveRefresh();
        }
    };

    scheduleLiveRefresh() {
        window.clearTimeout(this.refreshTimer);
        this.refreshTimer = window.setTimeout(() => {
            this.refreshTimer = undefined;
            this.loadDashboard();
        }, 150);
    }

    get controlsDisabled() {
        return this.isLoading || this.eventOptions.length === 0;
    }

    get showInitialLoading() {
        return this.isLoading && !this.hasDashboard;
    }

    handleEventChange(event) {
        const nextEventCode = event.detail.value;
        if (nextEventCode === this.selectedEventCode) {
            return;
        }
        this.selectedEventCode = nextEventCode;
        this.hasDashboard = false;
        this.loadDashboard();
    }

    handleRefresh() {
        this.loadDashboard();
    }

    async loadDashboard() {
        const requestId = ++this.requestSequence;
        this.isLoading = true;
        this.errorMessage = "";

        try {
            const response = await getHomeDashboard({ eventCode: this.selectedEventCode || null });
            if (requestId !== this.requestSequence) {
                return;
            }
            this.applyDashboard(this.parseResponse(response));
            this.hasDashboard = true;
        } catch (error) {
            if (requestId !== this.requestSequence) {
                return;
            }
            this.errorMessage = "We couldn’t load the event portfolio. Refresh to try again.";
            this.hasDashboard = false;
        } finally {
            if (requestId === this.requestSequence) {
                this.isLoading = false;
            }
        }
    }

    applyDashboard(payload) {
        const dashboard = payload || {};
        this.eventOptions = this.normalizeEventOptions(dashboard.eventOptions || dashboard.events || []);

        const returnedEventCode = dashboard.selectedEventCode || dashboard.eventCode || this.selectedEventCode;
        this.selectedEventCode = returnedEventCode || this.eventOptions[0]?.value || "";
        if (this.selectedEventCode && !this.eventOptions.some((option) => option.value === this.selectedEventCode)) {
            this.eventOptions = [{ label: this.selectedEventCode, value: this.selectedEventCode }, ...this.eventOptions];
        }

        this.refreshedAt = this.formatDateTime(dashboard.refreshedAt || dashboard.lastRefreshedAt || new Date());
        this.headlineMetrics = this.normalizeHeadline(dashboard.headlines || dashboard.headline || dashboard.headlineMetrics || {});
        this.pipelineRows = this.normalizePipeline(dashboard.pipeline || dashboard.pipelineRows || []);
        this.revenueReadiness = this.normalizeReadiness(dashboard.revenueReadiness || dashboard.financeReadiness || []);
        this.bookingMix = this.normalizeBookingMix(dashboard.bookingMix || {});

        const pricingReviewCount = this.toNumber(dashboard.pricingReviewCount);
        this.pricingReviewNote = pricingReviewCount > 0
            ? `${NUMBER_FORMATTER.format(pricingReviewCount)} ${pricingReviewCount === 1 ? "record needs" : "records need"} a pricing check.`
            : "";
    }

    parseResponse(response) {
        if (typeof response !== "string") {
            return response || {};
        }
        try {
            return JSON.parse(response);
        } catch (error) {
            throw new Error("The dashboard response could not be read.");
        }
    }

    normalizeEventOptions(options) {
        return (Array.isArray(options) ? options : [])
            .map((option) => {
                if (typeof option === "string") {
                    return { label: option, value: option };
                }
                const value = option?.value || option?.code || option?.eventCode;
                return value ? { label: option.label || option.name || value, value } : null;
            })
            .filter(Boolean);
    }

    normalizeHeadline(headline) {
        return HEADLINE_CONFIG.map((config, index) => {
            const normalizedAliases = config.aliases.map((alias) => this.toKey(alias));
            const source = Array.isArray(headline)
                ? headline.find((item) => normalizedAliases.includes(this.toKey(item?.key || item?.label))) || {}
                : this.firstObject(headline, config.aliases);
            const records = this.metricRecords(source);
            return {
                key: config.key,
                label: config.label,
                formattedValue: this.formatCurrency(this.metricValue(source)),
                recordText: `${NUMBER_FORMATTER.format(records)} ${records === 1 ? "record" : "records"}`,
                itemClass: config.highlighted ? "headline-item headline-item--highlighted" : "headline-item",
                dotClass: `metric-dot metric-dot--${config.key}`,
                showConnector: index < HEADLINE_CONFIG.length - 1
            };
        });
    }

    normalizePipeline(rows) {
        const sourceRows = Array.isArray(rows) ? rows : Object.keys(rows || {}).map((key) => ({ key, ...rows[key] }));
        const preparedRows = sourceRows.map((row, index) => {
            const label = row.label || row.stage || row.name || row.key || `Stage ${index + 1}`;
            const key = this.toKey(row.key || label, index);
            const exhibitorValue = this.toNumber(row.exhibitorValue ?? row.exhibitorAmount);
            const partnerValue = this.toNumber(row.partnerSponsorValue ?? row.partnerValue ?? row.sponsorValue ?? row.partnerSponsorAmount);
            const totalValue = this.toNumber(row.totalValue ?? row.value ?? row.amount) || exhibitorValue + partnerValue;
            return {
                key,
                label,
                records: this.toNumber(row.records ?? row.recordCount ?? row.count),
                exhibitorValue,
                partnerValue,
                totalValue,
                share: this.toNumber(row.share ?? row.sharePercentage ?? row.percentage ?? row.progress),
                iconName: row.iconName || STAGE_ICONS[key] || "standard:record",
                iconClass: `stage-icon stage-icon--${key}`
            };
        });

        const maxExhibitor = Math.max(...preparedRows.map((row) => row.exhibitorValue), 1);
        const maxPartner = Math.max(...preparedRows.map((row) => row.partnerValue), 1);
        const largestStageValue = Math.max(...preparedRows.map((row) => row.totalValue), 1);

        return preparedRows.map((row) => {
            const share = row.share || (row.totalValue / largestStageValue) * 100;
            return {
                ...row,
                formattedRecords: NUMBER_FORMATTER.format(row.records),
                formattedExhibitorValue: this.formatCurrency(row.exhibitorValue),
                formattedPartnerValue: this.formatCurrency(row.partnerValue),
                formattedTotalValue: this.formatCurrency(row.totalValue),
                formattedShare: `${Math.round(share)}%`,
                exhibitorWidthStyle: this.widthStyle((row.exhibitorValue / maxExhibitor) * 100),
                partnerWidthStyle: this.widthStyle((row.partnerValue / maxPartner) * 100),
                shareWidthStyle: this.widthStyle(share)
            };
        });
    }

    normalizeReadiness(readiness) {
        let prepared;
        if (Array.isArray(readiness)) {
            prepared = readiness.map((item, index) => this.normalizeReadinessItem(item, index));
        } else {
            prepared = READINESS_CONFIG.map((config, index) => {
                const source = this.firstObject(readiness, config.aliases);
                return this.normalizeReadinessItem({ key: config.key, label: config.label, ...source }, index);
            });
        }

        const totalValue = prepared.reduce((sum, item) => sum + item.value, 0);
        return prepared.map((item) => {
            const percentage = item.percentage || (totalValue > 0 ? (item.value / totalValue) * 100 : 0);
            return {
                ...item,
                formattedPercentage: `${Math.round(percentage)}%`,
                formattedValue: this.formatCurrency(item.value),
                widthStyle: this.widthStyle(percentage),
                segmentClass: `readiness-segment readiness-segment--${item.key}`,
                dotClass: `readiness-dot readiness-dot--${item.key}`
            };
        });
    }

    normalizeReadinessItem(item, index) {
        const label = item.label || item.name || `Status ${index + 1}`;
        const key = this.toKey(item.key || label, index);
        return {
            key,
            label,
            value: this.metricValue(item),
            percentage: this.toNumber(item.percentage ?? item.share ?? item.progress)
        };
    }

    normalizeBookingMix(bookingMix) {
        const exhibitor = this.bookingGroup(bookingMix.exhibitor || bookingMix.exhibitors || {});
        const partnerSponsor = this.bookingGroup(bookingMix.partnerSponsor || bookingMix.partner || bookingMix.sponsors || {});
        const totalRecords = exhibitor.records + partnerSponsor.records;
        const totalValue = exhibitor.value + partnerSponsor.value;
        return {
            exhibitor: this.presentBookingGroup(exhibitor, totalRecords, totalValue),
            partnerSponsor: this.presentBookingGroup(partnerSponsor, totalRecords, totalValue)
        };
    }

    bookingGroup(source) {
        const records = this.metricRecords(source);
        const value = this.metricValue(source);
        const average = this.toNumber(source.averageValue ?? source.average ?? source.avgValue) || (records > 0 ? value / records : 0);
        return { records, value, average };
    }

    presentBookingGroup(group, totalRecords, totalValue) {
        const recordPercentage = totalRecords > 0 ? Math.round((group.records / totalRecords) * 100) : 0;
        const valuePercentage = totalValue > 0 ? Math.round((group.value / totalValue) * 100) : 0;
        return {
            recordsText: `${NUMBER_FORMATTER.format(group.records)} (${recordPercentage}%)`,
            valueText: `${this.formatCurrency(group.value)} (${valuePercentage}%)`,
            averageText: this.formatCurrency(group.average)
        };
    }

    emptyBookingMix() {
        return {
            exhibitor: { recordsText: "0 (0%)", valueText: "£0 (0%)", averageText: "£0" },
            partnerSponsor: { recordsText: "0 (0%)", valueText: "£0 (0%)", averageText: "£0" }
        };
    }

    firstObject(parent, aliases) {
        for (const alias of aliases) {
            const value = parent?.[alias];
            if (value !== undefined && value !== null) {
                return typeof value === "object" ? value : { value };
            }
        }
        return {};
    }

    metricValue(source) {
        return this.toNumber(source?.value ?? source?.amount ?? source?.totalValue ?? source?.total);
    }

    metricRecords(source) {
        return this.toNumber(source?.records ?? source?.recordCount ?? source?.count);
    }

    toNumber(value) {
        if (typeof value === "number") {
            return Number.isFinite(value) ? value : 0;
        }
        if (typeof value !== "string") {
            return 0;
        }
        const parsed = Number(value.replace(/[^0-9.-]/g, ""));
        return Number.isFinite(parsed) ? parsed : 0;
    }

    toKey(value, index = 0) {
        const normalized = String(value || "").trim().replace(/([a-z])([A-Z])/g, "$1-$2").replace(/[^a-zA-Z0-9]+/g, "-").replace(/^-|-$/g, "").toLowerCase();
        return normalized || `item-${index}`;
    }

    widthStyle(value) {
        const percentage = Math.max(0, Math.min(100, this.toNumber(value)));
        return `width: ${percentage.toFixed(2)}%;`;
    }

    formatCurrency(value) {
        return CURRENCY_FORMATTER.format(this.toNumber(value));
    }

    formatDateTime(value) {
        const date = value instanceof Date ? value : new Date(value);
        if (Number.isNaN(date.getTime())) {
            return "—";
        }
        return new Intl.DateTimeFormat("en-GB", {
            day: "numeric",
            month: "short",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            hour12: false
        }).format(date);
    }
}
