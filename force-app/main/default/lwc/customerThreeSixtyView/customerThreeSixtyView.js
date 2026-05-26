import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountData from '@salesforce/apex/BB_C360_Controller.getAccountData';
import userId from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_NAME from '@salesforce/schema/User.Name';


export default class CustomerThreeSixtyView extends LightningElement {

    @api recordId;

    @track _data;
    @track isLoading = true;
    @track _activeTab = 'dashboard';

    // ── Current user (RM name in header) ──────────────────────────────────
    @wire(getRecord, { recordId: userId, fields: [USER_NAME] })
    _currentUser;

    connectedCallback() {
        this._loadAccount();
    }

    _loadAccount() {
        if (!this.recordId) {
            this.isLoading = false;
            return;
        }
        getAccountData({ accountId: this.recordId })
            .then(data => {
                this._data = data;
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error loading account data',
                    message: error?.body?.message || 'An unexpected error occurred.',
                    variant: 'error'
                }));
            });
    }

    // ── Tab state ──────────────────────────────────────────────────────────
    get showDashboard() { return this._activeTab === 'dashboard'; }
    get showProducts()  { return this._activeTab === 'products'; }

    get dashboardTabClass() {
        return this._activeTab === 'dashboard'
            ? 'c360-nav-tab c360-nav-tab--active'
            : 'c360-nav-tab';
    }
    get productsTabClass() {
        return this._activeTab === 'products'
            ? 'c360-nav-tab c360-nav-tab--active'
            : 'c360-nav-tab';
    }

    handleDashboardTab() { this._activeTab = 'dashboard'; }
    handleProductsTab()  { this._activeTab = 'products'; }

    // ── Currency formatter (e.g. 42500000 → "R 42.5m") ───────────────────
    _fmt(value) {
        if (value == null) return '--';
        const abs = Math.abs(value);
        if (abs >= 1_000_000) return `R ${(value / 1_000_000).toFixed(1)}m`;
        if (abs >= 1_000)     return `R ${(value / 1_000).toFixed(0)}k`;
        return `R ${value.toFixed(0)}`;
    }

    // ── Derived display values ─────────────────────────────────────────────
    get accountName()     { return this._data?.accountName  || '--'; }
    get industry()        { return this._data?.industry     || '--'; }
    get vapm()            { return this._data?.vapm         || '--'; }
    get totalRevenue()    { return this._fmt(this._data?.totalRevenue); }
    get totalExposure()   { return this._fmt(this._data?.totalExposure); }
    get costToServe()         { return this._fmt(this._data?.costToServe); }
    get profitBeforeTax()     { return this._fmt(this._data?.profitBeforeTax); }
    get profitAfterTax()      { return this._fmt(this._data?.profitAfterTax); }
    get clientProfitability() { return this._fmt(this._data?.clientProfitability); }

    get ficaProgress() {
        return this._data?.ficaCifFlag ? '100%' : '--';
    }

    get ficaStatus() {
        if (!this._data) return '--';
        return this._data.ficaCifFlag ? 'Complete' : 'Breach Risk';
    }

    get ficaStatusClass() {
        if (!this._data) return 'c360-kpi-status';
        return this._data.ficaCifFlag
            ? 'c360-kpi-status c360-kpi-status--green'
            : 'c360-kpi-status c360-kpi-status--breach';
    }

    get tenureLabel() {
        const years = this._data?.lengthOfRelationship;
        if (years == null) return '--';
        return `${years} year${years === 1 ? '' : 's'}`;
    }

    // ── Header RM ─────────────────────────────────────────────────────────
    get rmName() {
        return getFieldValue(this._currentUser?.data, USER_NAME) || 'Relationship Manager';
    }

    get rmInitials() {
        const parts = this.rmName.split(' ').filter(Boolean);
        if (parts.length >= 2) return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
        return parts[0]?.[0]?.toUpperCase() || 'RM';
    }

}
