"""Build exact, readable reference chapters from the frozen evidence model."""
from pathlib import Path
import json,re,collections,hashlib
from method_notes import NOTES
from field_notes import note_for
R=Path(__file__).resolve().parents[2]; O=R/'documentation/chapters'
J=json.loads((R/'documentation/source-analysis/inventory.json').read_text())
F=json.loads((R/'documentation/source-analysis/forms.json').read_text())
M=J['metadata']; MD={m['path']:m['definition'] for m in M}
def arr(x): return x if isinstance(x,list) else ([] if x is None else [x])
def flat(x):
    if isinstance(x,dict):return '; '.join(f'{k}={flat(v)}' for k,v in x.items())
    if isinstance(x,list):return '; '.join(flat(v) for v in x)
    return str(x)
def val(x):return str(next(iter(x.values()))) if isinstance(x,dict) and len(x)==1 else flat(x)
def cell(x):return str(x).replace('|','&#124;').replace('\n','<br>')
def table(headers,rows):
    return '\n| '+' | '.join(headers)+' |\n| '+' | '.join('---' for h in headers)+' |\n'+''.join('| '+' | '.join(cell(v) for v in row)+' |\n' for row in rows)+'\n'
def save(name,parts):(O/name).write_text('\n\n'.join(parts)+'\n')
def title(name):return name.replace('__mdt',' Configuration').replace('__c','').replace('_',' ')

# One reusable exact picklist catalogue avoids repeating long option sets on every object.
picksets={}; fieldpick={}
for m in M:
    if '/fields/' not in m['path']:continue
    d=m['definition'];vs=d.get('valueSet',{})
    if 'valueSetDefinition' not in vs:continue
    spec=vs['valueSetDefinition'];key=json.dumps(spec,sort_keys=True)
    if key not in picksets:picksets[key]={'id':f'PL{len(picksets)+1:02}','spec':spec,'uses':[]}
    obj=m['path'].split('/')[4];api=d['fullName'];picksets[key]['uses'].append(obj+'.'+api)
    fieldpick[(obj,api)]=picksets[key]['id']

forms_by_api=collections.defaultdict(list)
for f in F:
    for api in dict.fromkeys(x['api'] for x in f['fields']):forms_by_api[api].append(f['path'])
conversion=next(m['definition'] for m in M if m['path'].endswith('/NTE_Copy_Converted_Lead_to_Opportunity.flow-meta.xml'))
conversion_targets=collections.defaultdict(list)
for u in arr(conversion.get('recordUpdates')):
    for a in arr(u.get('inputAssignments')):
        ref=val(a['value'])
        if ref.startswith('$Record.') or ref.startswith('Priced_Application.'):
            conversion_targets[ref.split('.')[-1]].append(u['object']+'.'+a['field'])

object_notes={
'Lead':'One public submission, not one permanent participant. Main applications remain here until native conversion; EOI and guests remain Leads. Supplementary staff/vehicle Leads are temporary only after both applied data and accepted receipt; logo Leads remain as audit records. Applicant and internal email outcomes are independent. Form fields record submitted facts; pricing/audit fields are overwritten by their authoritative services. Volunteer fields share this object but use the distinct volunteer flow/source and do not enter NTE edition queues.',
'Opportunity':'One NTE event booking and its durable application snapshot. Initial commercial fields are copied by the conversion flow; subsequent preparation fields are changed by the supplementary service. Invoice/payment flags are independent for the base booking and later exhibitor staff top-up. Timestamps and By text record the action evidence. Approval and final-pack states describe email outcomes, not booking completion or actual payment processing.',
'Account':'The standard organisation identity can be reused across editions. Five custom fields are the latest NTE classification summary. A later conversion may replace those summaries; use related Opportunities for the event history. Core Account identity is selected through native conversion rather than overwritten by the supplementary service.',
'Contact':'The standard person identity can be reused across editions. Six custom fields summarise the latest NTE application/classification. OpportunityContactRole supplies each booking association and Primary choice. Event-day and billing contact details on the booking are descriptive fields and are not alternate email recipients.',
'NTE_Email_Dispatch__c':'One durable request/outcome per communication kind, run and source target. Its unique key makes queue/retry behaviour idempotent. It stores a reviewed recipient/content snapshot and later processing result. Invitation/final-pack outcomes synchronise selected source fields; reminders do not complete preparation. Booking-payment confirmation uses its fixed run identity.',
'NTE_Payment_Request__c':'One initial booking charge snapshot per Salesforce org and Opportunity. Amounts in minor units are integer pence; tax rate and net/gross values are saved with source identity, merchant/mode and stable Stripe resource/idempotency keys. Ready describes a verified request, not collected payment. Existing test resources are never relabelled as live resources.',
'NTE_Routing_Config__mdt':'Public custom metadata holding environment-specific owner and participant destinations. The code uses the Default record. Empty final-pack destinations deliberately make affected recipients ineligible; source field names alone do not provide the missing event information.',
'NTE_Stripe_Config__mdt':'Public custom metadata controlling activation, exact target org/merchant, environment, tax and optional scope. It contains no secret API key. The code uses Default; the two example JSON files serve the separate preflight helper, not runtime configuration.'}
rights={}
permission_names=['NTE_Management_User','NTE_Forms_Administration','Volunteer_Applications_User','NTE_Stripe_Test_Operator']
for m in M:
    if m['kind']=='permissionsets':
        api=Path(m['path']).name.split('.')[0]
        rights[api]={x['field']:('E' if x['editable']=='true' else 'R') for x in arr(m['definition'].get('fieldPermissions')) if x['readable']=='true'}

p=['# Salesforce data dictionary',f'This reference contains all {sum("/fields/" in m["path"] for m in M)} packaged custom field definitions across six record objects and two custom metadata types. Standard object behaviour is described where the project uses it; unrelated Salesforce standard fields are not added as filler. API names, type limits, defaults, formula text, picklist values and relationships below come directly from the frozen source metadata.',
'A field without a required declaration below is optional at schema level; public form and Apex validation can impose stronger conditional requirements. R means explicit readable-only field access, E means readable and editable, and a dash means this permission set does not grant the field. Other assigned permissions can still grant access. Permission order is Management User / Forms Administration / Volunteer Application User / Stripe Payment Operator. Formula fields remain calculated regardless of a form or caller. Picklist catalogue identifiers refer to the exact reusable sets later in this chapter.']
standard=[('Lead','Id, Company, FirstName, LastName, Email, Phone, MobilePhone, Title, Website, Salutation, Street, PostalCode','Applicant identity and public form standard HTTP mappings.'),('Lead','LeadSource, Status, OwnerId, CreatedDate, LastModifiedDate','Route discrimination, native review state, ownership and dashboard creation-date filtering.'),('Lead','IsConverted, ConvertedOpportunityId, ConvertedAccountId, ConvertedContactId','Exact native conversion outputs consumed by the after-save conversion flow; they are not guessed from latest related records.'),('Opportunity','Id, AccountId, Name, Amount, CloseDate, StageName, IsClosed, IsWon, RecordTypeId, OwnerId','Booking identity and native sales context. Amount is the initial booking total including VAT; stage/close date are native values, separate from payment and readiness flags.'),('OpportunityContactRole','OpportunityId, ContactId, IsPrimary, Role','Many booking/person associations, with exactly one usable Primary required by this code. The native schema alone does not guarantee that invariant.'),('Account and Contact','Id, Name, AccountId on Contact, Email/Phone where applicable, OwnerId','Reusable organisation/person identity and record navigation. Contact.AccountId does not substitute for its booking role.'),('Task','WhoId, WhatId, Subject, Description, Status, ActivityDate','Approval/legacy communication audit and ordinary activities. The controller discovers a closed Task status for compatibility.'),('User and RecordType','User.Username, Email, IsActive; RecordType.DeveloperName, SobjectType','Exact routing and NTE_Event_Opportunity discrimination.'),('EmailTemplate and Report','DeveloperName and Id','Runtime resolves portable developer names to destination-specific record IDs. Report IDs and template IDs are not hardcoded into the UI.')]
p+=['## Standard objects and fields used',table(['Object','Relevant standard fields','Project role'],standard)]
for obj in object_notes:
    fields=[m for m in M if '/objects/'+obj+'/fields/' in m['path']]
    p+=['## '+title(obj),f'API name: {obj}. {len(fields)} packaged fields. '+object_notes[obj]]
    objdef=next((m['definition'] for m in M if m['path'].endswith('/'+obj+'.object-meta.xml')),None)
    if objdef:p.append('Object settings: '+flat(objdef)+'.')
    rows=[];formula=[]
    for m in fields:
        d=m['definition'];api=d['fullName'];ft=d.get('type','');storage=ft
        if 'length'in d:storage+=f"({d['length']})"
        if 'precision'in d:storage+=f"({d['precision']},{d.get('scale','0')})"
        details=[storage,'required='+d.get('required','false')]
        for key in ['defaultValue','unique','externalId','caseSensitive','trackHistory','trackFeedHistory','visibleLines']:
            if key in d:details.append(key+'='+d[key])
        if (obj,api) in fieldpick:details.append('values '+fieldpick[(obj,api)]+', restricted='+d['valueSet'].get('restricted','unspecified'))
        if 'valueSetName'in d.get('valueSet',{}):details.append('shared values '+d['valueSet']['valueSetName'])
        if 'referenceTo'in d:details.append('lookup to '+flat(d['referenceTo'])+'; delete='+d.get('deleteConstraint','unspecified')+'; relationship='+d.get('relationshipName','')+'; label='+d.get('relationshipLabel',''))
        if 'formula'in d:details.append('formula below; blanks='+d.get('formulaTreatBlanksAs','unspecified'));formula.append((api,d))
        perms='/'.join(rights.get(n,{}).get(obj+'.'+api,'–') for n in permission_names)
        usage=[]
        if note_for(obj,api):usage.append(note_for(obj,api))
        if d.get('description'):usage.append(d['description'])
        if d.get('inlineHelpText'):usage.append('Help: '+d['inlineHelpText'])
        if obj=='Lead' and api in forms_by_api:usage.append('Submitted by: '+', '.join(forms_by_api[api]))
        if obj=='Lead' and api in conversion_targets:usage.append('Conversion destinations: '+', '.join(conversion_targets[api]))
        if obj=='Opportunity':
            src=[val(a['value']) for u in arr(conversion['recordUpdates']) if u['object']=='Opportunity' for a in arr(u.get('inputAssignments')) if a['field']==api]
            if src:usage.append('Conversion source: '+', '.join(src))
        if not usage:usage.append('Role: '+d.get('label',api)+'. See the object lifecycle and service rules for when this value changes.')
        rows.append((api+'<br>'+d.get('label',api)+'<br>'+'; '.join(details)+'<br>Field access '+perms,' '.join(usage)))
    p.append(table(['Field and exact definition','Meaning and data lineage'],rows))
    for api,d in formula:p+=['### '+title(api)+' formula','API name: '+obj+'.'+api+'.','```text\n'+d['formula']+'\n```']
    extras=[m for m in M if '/objects/'+obj+'/' in m['path'] and any('/'+t+'/' in m['path'] for t in ['validationRules','recordTypes','businessProcesses'])]
    for m in extras:
        d=m['definition'];p+=['### '+title(d.get('fullName',Path(m['path']).name)), 'Source: '+m['path']+'.']
        for k,v in d.items():
            if k=='errorConditionFormula':p+=['Validation formula:','```text\n'+v+'\n```']
            else:p.append(k+': '+flat(v).rstrip('.')+'.')
p+=['## Picklist value catalogue','The API value is the stored value. Unless a different label is shown, the displayed label is identical. Explicit inactive values and defaults are retained exactly. Consecutive numeric strings are expressed as an inclusive range only when every member is present with the same default/active treatment.']
for item in picksets.values():
    s=item['spec'];vs=arr(s.get('value'));p+=['### '+item['id']+' values','Used by: '+', '.join(item['uses'])+'. Sorted: '+s.get('sorted','unspecified')+'.']
    numeric=bool(vs) and all(str(v.get('fullName','')).isdigit() and v.get('label',v['fullName'])==v['fullName'] for v in vs)
    ns=[int(v['fullName']) for v in vs] if numeric else []
    if numeric and ns==list(range(min(ns),max(ns)+1)) and len({(v.get('default'),v.get('isActive')) for v in vs})==1:
        p.append(f"Every integer string from {min(ns)} through {max(ns)} inclusive, in ascending order. default={vs[0].get('default','unspecified')}; active={vs[0].get('isActive','not explicitly overridden')}.")
    else:
        p.append('; '.join(v['fullName']+((' → '+v['label']) if v.get('label',v['fullName'])!=v['fullName'] else '')+(' [default]' if v.get('default')=='true' else '')+(' [inactive]' if v.get('isActive')=='false' else '') for v in vs)+'.')
save('07-data-reference.md',p)

p=['# Flow and declarative automation reference','All four packaged flows are active after-save record-triggered flows. Their start criteria and assignments are reproduced here so an administrator can rebuild the same control flow. No Apex trigger source is present in this package. The order within a flow is explicit; ordering relative to unrelated target-org automation must be assessed in that target.']
for m in M:
    if m['kind']!='flows':continue
    d=m['definition'];s=d['start'];p+=['## '+d['label'],'API name: '+Path(m['path']).name.split('.')[0]+'. API version '+d['apiVersion']+'. Status '+d['status']+'.',d.get('description',''), 'Start: '+s['object']+' '+s['recordTriggerType']+'; '+s['triggerType']+'; changed-to-meet-criteria='+s.get('doesRequireRecordChangedToMeetCriteria','false')+'. Filter logic: '+s.get('filterLogic','AND')+'.']
    p.append(table(['Criterion','Field','Operator','Value'],[(i+1,x['field'],x['operator'],val(x['value'])) for i,x in enumerate(arr(s.get('filters')))]))
    nodes={}
    for typ in ['actionCalls','recordLookups','recordUpdates','assignments','decisions']:
        for n in arr(d.get(typ)):nodes[n['name']]=(typ,n)
    order=[];n=s.get('connector',{}).get('targetReference');seen=set()
    while n and n not in seen:
        seen.add(n);order.append(n);n=nodes.get(n,('',{}))[1].get('connector',{}).get('targetReference')
    p.append('Sequence: '+' → '.join(order)+'.')
    for name in order:
        typ,n=nodes[name];p+=['### '+title(name), 'Element type: '+typ+'. Label: '+n.get('label',name)+'.']
        if typ=='actionCalls':
            p.append('Apex action: '+n['actionName']+'. Transaction: '+n.get('flowTransactionModel','default')+'.')
            p.append(table(['Input','Value'],[(x['name'],val(x['value'])) for x in arr(n.get('inputParameters'))]))
            for x in arr(n.get('outputParameters')):p.append('Output '+x['name']+' → '+x['assignToReference']+'.')
        elif typ in ['recordLookups','recordUpdates']:
            p.append('Object: '+n['object']+'. Filters: '+'; '.join(x['field']+' '+x['operator']+' '+val(x['value']) for x in arr(n.get('filters')))+'.')
            if typ=='recordLookups':p.append('First record only='+n.get('getFirstRecordOnly','false')+'; store output automatically='+n.get('storeOutputAutomatically','false')+'.')
            else:p.append(table(['Destination field','Assigned value'],[(x['field'],val(x['value'])) for x in arr(n.get('inputAssignments'))]))
        else:p.append(flat(n))
    for v in arr(d.get('variables')):p.append('Flow variable: '+flat(v)+'.')
save('08-flow-reference.md',p)

p=['# Apex class and method reference',f'The {sum(not c["test"] for c in J["classes"])} implementation classes contain {sum(len(c["methods"]) for c in J["classes"] if not c["test"])} extracted methods and constructors, including inner queue workers and DTO constructors. Every entry identifies its source signature/line and project purpose. Overloads remain separate. The accompanying archive contains the exact bodies; the runtime chapter explains cross-class orchestration and transaction boundaries. Standard library calls are not separately catalogued.']
method_count=0
for c in J['classes']:
    if c['test']:continue
    p+=['## '+c['name'],c['declaration']+'. Source: '+c['path']+'.']
    # DTO/public property contracts, including invocable fields. Scope each property to its nearest nested class.
    props=[];scope=c['name']
    for line in c['source'].splitlines():
        cm=re.search(r'\bclass\s+(\w+)',line)
        if cm:scope=cm.group(1)
        for pm in re.finditer(r'(?:@AuraEnabled\s+)?public\s+(?!static\b|class\b|virtual\b|override\b)([\w<>,. \[\]]+)\s+(\w+)\s*(?:;|\{\s*get;)',line):
            props.append((scope,pm.group(2),pm.group(1).strip()))
    if props:p+=['Public data contracts: '+ '; '.join(f'{s}.{n}: {t}' for s,n,t in props)+'.']
    rows=[]
    for m in c['methods']:
        note=NOTES[(c['name'],m['name'])];method_count+=1
        rows.append((re.sub(r'\s+',' ',m['signature'])+'<br>Source line '+str(m['line']),note))
    p.append(table(['Method signature','Purpose and behaviour'],rows))
assert method_count==sum(len(c["methods"]) for c in J["classes"] if not c["test"])
p+=['## Apex test coverage by feature',f'These are the {sum(c["test"] for c in J["classes"])} packaged test classes. The named scenarios specify project invariants and provide examples for rebuilding behaviour. Fixture constructors, mocks and assertion helpers are omitted from the scenario list; they are retained in the source archive. No test class is a production trigger or scheduled job.']
for c in J['classes']:
    if not c['test']:continue
    names=[m['name'] for m in c['methods'] if (len(m['name'])>25 and not m['name'].startswith(('assert','populate','assign','create','configure','new'))) ]
    p+=['### '+c['name'],'Source: '+c['path']+'.','; '.join(re.sub(r'(?<!^)(?=[A-Z])',' ',n).replace(' A ',' a ') for n in names)+'.']
save('09-apex-reference.md',p)

# Form controls include exact names and validation attributes, not merely visible captions.
p=['# Form and Lightning component reference','The form specifications below include every Salesforce-mapped control, fixed hidden value, conditional requirement and option set extracted from the current HTML. Controls sharing one field are grouped; checkbox selections post semicolon-separated values. A missing HTML value attribute on an option means its text is the native submitted value. Numeric ranges are shortened only when the set is consecutive.']
def options_text(options):
    real=[o for o in options if o['value']!='']
    if not real:return ''
    nums=[int(o['value']) for o in real] if all(str(o['value']).isdigit() and o['label'].strip()==o['value'] for o in real) else []
    if nums and nums==list(range(min(nums),max(nums)+1)):return f'Options: every integer string {min(nums)} through {max(nums)} inclusive.'
    return 'Options: '+'; '.join(o['value']+((' → '+o['label']) if o['label']!=o['value'] else '') for o in real)+'.'
def attr_text(a):
    keys=['id','name','type','value','required','min','max','step','maxlength','pattern','data-required-when-visible','data-combine-fields','data-copy-value-from','data-checkbox-copy-from','data-switch-copy','data-switch-yes-fields','data-switch-no-fields','data-copy-when','data-code-consent','data-code-open','data-code-dialog','data-code-reader']
    return '; '.join(k+'='+('true' if a[k]=='' else a[k]) for k in keys if k in a)
for f in F:
    p+=['## '+f['path'].replace('.html','').replace('-',' '),'Source: '+f['path']+'. Form configuration: '+flat(f['attributes'])+'.','Section order: '+' → '.join(f['headings'])+'.']
    groups=collections.defaultdict(list)
    for x in f['fields']:groups[x['api']].append(x)
    rows=[]
    for api,entries in groups.items():
        descr=[]
        for x in entries:
            t=(x['label']+'. ' if x['label'] else '')+attr_text(x['attributes'])
            if x['conditions']:t+='; visible only when '+ ' AND '.join(a.get('data-conditional-for','')+' in '+a.get('data-conditional-value','Yes') for a in reversed(x['conditions']))
            ot=options_text(x['options'])
            if ot:t+='. '+ot
            descr.append(t)
        rows.append((api,'<br>'.join(descr)))
    p.append(table(['Salesforce Lead field','Control and exact input contract'],rows))
    logical=[]
    for x in f.get('logicalControls',[]):
        a=x['attributes'];desc=attr_text(a)
        # Capture all data attributes for derived/contact/submit controls.
        extra='; '.join(k+'='+v for k,v in a.items() if k.startswith('data-') and k not in desc)
        if extra:desc+='; '+extra
        if not desc and not x['label']:continue
        logical.append((x['label'] or a.get('id') or a.get('name') or a.get('type','Control'),desc+' '+options_text(x['options'])))
    if logical:p+=['Additional controls drive visibility, derived values, acknowledgements or submission without posting their own Salesforce field.',table(['Control','Behaviour attributes'],logical)]
    if f['requiredGroups']:p.append('Required checkbox groups: '+flat(f['requiredGroups'])+'.')

from lwc_notes import LWC_NOTES
for component in J['lwcs']:
    actual = {m['name'] for m in component['methods']}
    documented = set(LWC_NOTES[component['name']])
    assert actual == documented, (component['name'], actual - documented, documented - actual)
p+=['## Lightning component methods','All four bundles are listed below, including lifecycle methods, event handlers and derived getters. CSS controls responsive spacing, tables, state colours and dialog layout; it does not decide eligibility or prices. All server writes go through the Apex methods already documented.']
for c in J['lwcs']:
    d=MD['force-app/main/default/lwc/'+c['name']+'/'+c['name']+'.js-meta.xml']
    p+=['### '+c['name'],'Exposed='+d['isExposed']+'; API='+d['apiVersion']+'; targets='+flat(d['targets'])+'. '+('Target configuration: '+flat(d['targetConfigs'])+'.' if 'targetConfigs'in d else ''),'Apex imports: '+('; '.join(alias+' → '+method for alias,method in c['apex']) or 'none')+'.',table(['Method or getter and source line','Role'],[(m['signature']+'<br>Line '+str(m['line']),LWC_NOTES[c['name']][m['name']]) for m in c['methods']])]

engine_notes={
'setStatus':'Sets the form status text/type and error/success accessibility presentation.', 'configureShell':'Applies event/privacy/support/logo-destination configuration to shared page elements.', 'enableConditionalSections':'Enables/disables conditional sections and their nested required controls when the controlling answer changes.', 'configureFieldConstraints':'Applies standard/custom length limits and refreshed date boundaries.', 'enableCheckboxChoices':'Wires required checkbox-group validity.', 'validateCheckboxChoices':'Requires a selection in each active required checkbox group.', 'syncCombinedFields':'Builds hidden combined/copied/switch-derived values from their visible source controls.', 'eventCodeFromParts':'Returns the current year before April and following year from April onward.', 'pureDateParts':'Parses a calendar date without accepting impossible dates.', 'eventCodeFor':'Derives London-local year/month for the edition rollover.', 'resolveEventCode':'Uses a valid explicit override or derives the current edition.', 'bookingReference':'Generates a new reference in the supported NTE grammar using time/random identity.', 'populateSystemFields':'Populates edition/reference/version-related hidden controls.', 'setPricingField':'Writes a derived numeric/status field into the active form.', 'catalogPrice':'Accepts a finite nonnegative fixed catalogue price.', 'calculatePartnerPricing':'Sums validated selected package prices.', 'qualifiesForPowerDiscount':'Checks the same five category labels as Apex.', 'includedStaffForSpace':'Returns the two/four included-staff allowance from the exact space choice.', 'calculateExhibitorPricing':'Calculates space, allowed sockets and initial additional staff from whole valid counts.', 'eligibleCategoriesForSpace':'Returns the exact restricted-space eligible categories.', 'syncExhibitorEligibility':'Disables ineligible space choices and invalidates a stale selection.', 'setupPackageSummary':'Updates partner selected-package summary and hidden totals.', 'setupExhibitorEstimate':'Wires exhibitor category/space/staff/socket choices to derived estimate, allowance and invoice state.', 'nonBlankLines':'Returns nonempty roster lines.', 'setupStaffUpdates':'Keeps roster-derived counts and separate exhibitor top-up estimate in sync.', 'collectFields':'Collects only enabled selected/nonempty controls into API-name arrays.', 'hasBlankRequiredText':'Rejects whitespace-only required text that native required alone would accept.', 'normalizeBookingReferences':'Trims and uppercases supplied target references.', 'validateBookingReferences':'Enforces the reference grammar before POST.', 'validateFieldLengths':'Checks configured standard/custom text limits.', 'formatWebToLeadDate':'Formats ISO browser dates as configured DMY or supported output.', 'setRuleError':'Attaches a form-specific actionable custom-validity message.', 'validateCatalogPricing':'Rejects unknown/tampered pricing selections even if a hidden total looks valid.', 'exhibitorSpacePrice':'Resolves a selected exhibitor option through the actual catalogue.', 'packagePrice':'Reads and validates the selected package catalogue value.', 'validateStaffUpdate':'Checks audience, initial/top-up answer/count and roster consistency.', 'validateHeavyItems':'Requires complete mandatory and partially started optional item groups.', 'missingFieldIds':'Lists submitted custom API names missing their destination Web-to-Lead ID.', 'missingProductionConfig':'Checks the actual configured endpoint, org, return destination and required links.', 'resolveReturnUrl':'Resolves the form-specific or shared return page.', 'submitToSalesforce':'Builds and submits the hidden native POST with standard names/custom 00N IDs.', 'syncFormState':'Recomputes visibility, dates, references, derived values and prices immediately before validation.', 'clearRuleErrors':'Clears earlier custom validity so corrected input can be resubmitted.', 'restoreSubmitControls':'Restores controls after navigation interruption/back-forward restoration.', 'enableForms':'Orchestrates all pre-submit checks, review mode, duplicate-click protection and native submission.', 'setupCodeOfConduct':'Wires open/read-to-end/acknowledgement behaviour to the volunteer conduct reader.'}
source=(R/'assets/forms.js').read_text()
engine=[(m.group(1),source.count('\n',0,m.start())+1) for m in re.finditer(r'(?m)^  function (\w+)\(',source)]
assert all(n in engine_notes for n,l in engine)
p+=['## Shared public form engine functions', 'Source: assets/forms.js. Nested sync/validation closures belong to their named parent setup function.',table(['Function and line','Responsibility'],[(n+'<br>Line '+str(l),engine_notes[n]) for n,l in engine])]
save('10-client-reference.md',p)

p=['# Configuration and workspace reference','These definitions complete the reconstruction specification around the runtime services. Exact lists are retained where order or filters affect the user experience. Source paths identify the matching deployable metadata in the archive.']
for kind,heading in [('customMetadata','Runtime configuration records'),('namedCredentials','Named credentials'),('externalCredentials','External credentials'),('permissionsetgroups','Permission set group'),('permissionsets','Permission sets'),('applications','Lightning application'),('quickActions','Record actions'),('sharingRules','Sharing rule'),('duplicateRules','Duplicate rules'),('standardValueSets','Shared standard picklists')]:
    p+=['## '+heading]
    for m in M:
        if m['kind']!=kind:continue
        d=m['definition'];p+=['### '+title(Path(m['path']).name.split('.')[0]),'Source: '+m['path']+'.']
        if kind=='permissionsets':
            p.append('The complete custom field grants appear beside every field in the data dictionary.')
            rows=[(k,flat(v)) for k,v in d.items() if k!='fieldPermissions']
            p.append(table(['Setting','Value'],rows))
        elif kind=='standardValueSets':
            p.append('Sorted='+d.get('sorted','unspecified')+'.')
            p.append(table(['API value','Attributes'],[(x.get('fullName',''),flat({k:v for k,v in x.items() if k!='fullName'})) for x in arr(d.get('standardValue'))]))
        else:p.append(table(['Setting','Value'],[(k,flat(v)) for k,v in d.items()]))
p+=['## Reports','Native report filters apply to the report definition itself; navigating from a panel does not automatically replace every native report filter with the panel owner/time scope. The weekly report uses Last Update in the last seven days; other report date baselines and exact criteria follow.']
for m in M:
    if m['kind']!='reports':continue
    d=m['definition'];p+=['### '+re.sub(r'[^\w ]',' ',d.get('name',Path(m['path']).name.split('.')[0])).replace('_',' '),'Source: '+m['path']+'.']
    if 'reportType' not in d:p.append(flat(d));continue
    p.append(d.get('description',''))
    p.append(table(['Setting','Value'],[(k,flat(d[k])) for k in ['reportType','format','scope','filter','timeFrameFilter','groupingsDown','sortColumn','sortOrder','showDetails','showGrandTotal','showSubTotals'] if k in d]))
    p.append('Columns in order: '+'; '.join(x['field'] for x in arr(d['columns']))+'.')
p+=['## Native list views','These are all '+str(sum('/listViews/' in m['path'] for m in M))+' packaged views, including the three retained legacy separate top-up views. Native lists operate on their own scope; their existence does not add new Master Panel stages.']
for m in M:
    if '/listViews/'not in m['path']:continue
    d=m['definition'];p+=['### '+re.sub(r'[^\w ]',' ',d['label']).replace('_',' '),'Object '+m['path'].split('/')[4]+'. API '+d['fullName']+'. Scope '+d.get('filterScope','')+'.', 'Filter logic: '+d.get('booleanFilter','AND')+'. Criteria: '+flat(d.get('filters',[]))+'.','Columns: '+'; '.join(arr(d.get('columns')))+'.']
p+=['## Record pages and layouts','Dynamic Forms sections below list their actual field order by region. Standard highlights, tabs, related lists and activity components coexist with the custom relationship component. The NTE Management Home uses the supplied full-width Aura template; that template defines one region and no business logic.']
for m in M:
    if m['kind']not in ['flexipages','layouts','aura','tabs','contentassets','staticresources']:continue
    d=m['definition'];p+=['### '+title(Path(m['path']).name.split('.')[0]),'Source: '+m['path']+'.']
    if m['kind']=='flexipages':
        p.append('Page settings: '+flat({k:v for k,v in d.items() if k!='flexiPageRegions'})+'.')
        rows=[]
        for region in arr(d.get('flexiPageRegions')):
            items=[]
            for x in arr(region.get('itemInstances')):
                if 'fieldInstance'in x:items.append(x['fieldInstance']['fieldItem']+' ('+flat(x['fieldInstance'].get('fieldInstanceProperties',{}))+')')
                if 'componentInstance'in x:
                    c=x['componentInstance'];items.append(c['componentName']+': '+flat(c.get('componentInstanceProperties',{})))
            rows.append((region['name']+' / '+region['type'],'; '.join(items)))
        p.append(table(['Region','Fields and components in order'],rows))
    elif m['kind']=='layouts':
        for sec in arr(d.get('layoutSections')):
            p.append('Section '+sec.get('label','')+'; '+sec.get('style','')+'.')
            for i,col in enumerate(arr(sec.get('layoutColumns'))):p.append('Column '+str(i+1)+': '+flat(col)+'.')
        p.append('Other layout settings: '+flat({k:v for k,v in d.items() if k!='layoutSections'})+'.')
    else:p.append(flat(d))
save('11-config-reference.md',p)

# Replace concise chapter placeholders with generated exact tables.
price=next(c['source'] for c in J['classes'] if c['name']=='NTEPricingService')
def amap(name):
    body=re.search(name+r'\s*=\s*new Map<String, Decimal>\{([\s\S]*?)\};',price).group(1)
    return [(a,b) for a,b in re.findall(r"'([^']+)'\s*=>\s*([\d.]+)",body)]
catalogue='### Partner and sponsor catalogue\n'+table(['Exact package value','Net GBP'],amap('SPONSOR_PACKAGE_PRICES'))+'\n### Exhibitor space catalogue\n'+table(['Exact space value','Net GBP'],amap('EXHIBITOR_SPACE_PRICES'))+'\nDiscounted power categories: Charity - member of Cobseo; Charity - not a member of Cobseo; Government or Government Agency; Local Government or LG related; Employer - Blue Light & NHS.\n'
routes=[]
for f in F:
    fixed={x['api']:x['attributes'].get('value','derived') for x in f['fields'] if x['attributes'].get('type')=='hidden'}
    routes.append((f['path'],fixed.get('Web_Form_Type__c',''),fixed.get('Form_Version__c',fixed.get('Volunteer_Form_Version__c','')),f['attributes'].get('data-lead-source','')))
emailrows=[]
for m in M:
    if m['kind']!='email':continue
    d=m['definition'];bodypath=m['path'].replace('.email-meta.xml','.email');body=(R/bodypath).read_text();objs=sorted(set(re.findall(r'\{!(Lead|Contact|Opportunity)\.',body)))
    emailrows.append((Path(m['path']).name.split('.')[0],d.get('subject',''),d.get('description','')+' Merge context: '+', '.join(objs)+'.'))
generated={'[CATALOGUE]':catalogue,'[FORMS_OVERVIEW]':table(['Page','Form type','Version','Lead source'],routes),'[EMAIL_CATALOGUE]':table(['Template developer name','Subject','Use and merge context'],emailrows)}
(R/'documentation/source-analysis/generated-inserts.json').write_text(json.dumps(generated,indent=2,ensure_ascii=False))
coverage={'maintained_files':len(J['files']),'metadata_definitions':len(M),'field_definitions':sum('/fields/'in m['path']for m in M),'implementation_classes':12,'documented_methods_and_constructors':method_count,'test_classes':17,'lwc_bundles':len(J['lwcs']),'lwc_methods_getters':sum(len(c['methods'])for c in J['lwcs']),'form_routes':len(F),'form_mapped_controls':sum(len(f['fields'])for f in F),'form_engine_functions':len(engine),'flows':4,'email_templates':len(emailrows),'picklist_sets':len(picksets),'list_views':sum('/listViews/'in m['path']for m in M)}
(R/'documentation/source-analysis/coverage.json').write_text(json.dumps(coverage,indent=2))
print(json.dumps(coverage,indent=2))
