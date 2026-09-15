from pathlib import Path
from lxml import html
import json,re,collections
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/source-analysis'
j=json.loads((OUT/'inventory.json').read_text())
forms=[]
for p in sorted(ROOT.glob('*.html')):
    tree=html.fromstring(p.read_text())
    for f in tree.xpath('//form[@data-web-to-lead]'):
        fields=[]
        for e in f.xpath('.//*[@data-sf-field]'):
            api=e.get('data-sf-field'); control_id=e.get('id')
            labels=tree.xpath('//label[@for=$id]',id=control_id) if control_id else []
            label=' '.join(' '.join(x.itertext()).split()) if (x:=next(iter(labels),None)) is not None else ''
            parent=e.getparent()
            if not label and parent is not None and parent.tag=='label':label=' '.join(' '.join(parent.itertext()).split())
            cond=[dict(x.attrib) for x in e.iterancestors() if x.get('data-conditional-for')]
            opts=[{'value':o.get('value') if o.get('value') is not None else ''.join(o.itertext()),'label':' '.join(o.itertext())} for o in e.xpath('.//option')]
            fields.append({'api':api,'label':label,'element':e.tag,'attributes':dict(e.attrib),'conditions':cond,'options':opts})
        logical=[]
        for e in f.xpath('.//input[not(@data-sf-field)]|.//select[not(@data-sf-field)]|.//textarea[not(@data-sf-field)]|.//button'):
            labels=tree.xpath('//label[@for=$id]',id=e.get('id',''))
            logical.append({'attributes':dict(e.attrib),'label':' '.join(' '.join(' '.join(x.itertext()) for x in labels).split()) or ' '.join(' '.join(e.itertext()).split()),'options':[{'value':o.get('value') if o.get('value') is not None else ''.join(o.itertext()),'label':' '.join(o.itertext())} for o in e.xpath('.//option')]})
        forms.append({'path':p.name,'attributes':dict(f.attrib),'fields':fields,'logicalControls':logical,'headings':[' '.join(e.itertext()) for e in f.xpath('.//h2|.//h3|.//legend')], 'requiredGroups':[dict(e.attrib) for e in f.xpath('.//*[@data-required-checkbox-group]')]})
(OUT/'forms.json').write_text(json.dumps(forms,indent=2,ensure_ascii=False))
summary=[]
for f in forms:
    summary.append(f"{f['path']} | {f['attributes']} | {len(f['fields'])} controls\nSections: {'; '.join(f['headings'])}\nFields: "+', '.join(dict.fromkeys(x['api'] for x in f['fields'])))
(OUT/'forms-summary.txt').write_text('\n\n'.join(summary))
# Exact deployable non-field definitions for reference chapters.
nonfields=[m for m in j['metadata'] if m['kind'] not in ['classes','lwc','email'] and '/fields/' not in m['path']]
(OUT/'configuration.json').write_text(json.dumps(nonfields,indent=2,ensure_ascii=False))
summary=[]
for c in j['classes']:
    if c['test']:continue
    summary.append(c['name']+'\n'+'\n'.join(f"{m['line']}: {m['signature']}" for m in c['methods']))
(OUT/'method-index.txt').write_text('\n\n'.join(summary))
print('Forms',len(forms),'configuration definitions',len(nonfields))
