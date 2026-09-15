"""Extract the maintained project into a documentation evidence model. Read only."""
from pathlib import Path
import json, re, hashlib, collections
from xml.etree import ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'documentation/source-analysis'
BASE=ROOT/'force-app/main/default'
NS={'m':'http://soap.sforce.com/2006/04/metadata'}
def xmlvalue(e):
    if not len(e): return e.text or ''
    out={}
    for c in e:
        k=c.tag.split('}')[-1]; v=xmlvalue(c)
        if k in out:
            if not isinstance(out[k],list): out[k]=[out[k]]
            out[k].append(v)
        else: out[k]=v
    return out
def rel(p):return str(p.relative_to(ROOT))
allfiles=[]
for p in sorted(ROOT.rglob('*')):
    if not p.is_file() or any(x in p.relative_to(ROOT).parts for x in ['.git','.sf','tmp','documentation','output','node_modules']): continue
    allfiles.append({'path':rel(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
metadata=[]
for p in sorted(BASE.rglob('*.xml')):
    metadata.append({'path':rel(p),'kind':p.relative_to(BASE).parts[0],'definition':xmlvalue(ET.parse(p).getroot())})
classes=[]
# Mask strings and comments without changing positions, then balance method braces.
def mask(s):
    pat=r"//[^\n]*|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\""
    return re.sub(pat,lambda m:re.sub(r'[^\n]',' ',m.group()),s)
for p in sorted((BASE/'classes').glob('*.cls')):
    s=p.read_text(); masked=mask(s); methods=[]
    pattern=r'(?m)^\s*(?:@\w+(?:\([^)]*\))?\s*)*((?:(?:public|private|protected|global|static|override|virtual|abstract|webservice|testMethod)\s+)*(?:[\w.<>,\[\] ]+\s+)?(\w+)\s*\(([^;{}]*?)\)\s*)\{'
    for m in re.finditer(pattern,masked):
        name=m.group(2)
        if name in ['if','for','while','switch','catch']:continue
        start=m.end()-1; depth=1; end=start+1
        while end<len(masked) and depth:
            depth+= (masked[end]=='{')-(masked[end]=='}');end+=1
        begin=m.start()+len(m.group())-len(m.group().lstrip())
        signature=re.sub(r'^@\w+(?:\([^)]*\))?\s*','',s[begin:start].strip())
        if not re.search(r'\b(public|private|protected|global|static|void|String|Boolean|Decimal|Integer|List|Map|Set|Id|send|PricingResult)\b',signature) and name!=p.stem:continue
        body=s[start:end]
        methods.append({'name':name,'signature':signature,'line':s.count('\n',0,begin)+1,'endLine':s.count('\n',0,end)+1,'body':body})
    classes.append({'name':p.stem,'path':rel(p),'test':bool(re.search(r'@isTest',s,re.I)),'declaration':next((l for l in s.splitlines() if re.search(r'\bclass\b',l)),''),'methods':methods,'source':s})
lwcs=[]
for d in sorted((BASE/'lwc').iterdir()):
    js=(d/(d.name+'.js')).read_text();html=(d/(d.name+'.html')).read_text()
    methods=[{'name':m.group(2),'signature':m.group().strip().rstrip('{').strip(),'line':js.count('\n',0,m.start())+1} for m in re.finditer(r'(?m)^    ((?:async |get |set )?)(\w+)\([^\n]*\)\s*\{',js)]
    methods += [{'name':m.group(1),'signature':m.group().strip().rstrip('{').strip(),'line':js.count('\n',0,m.start())+1} for m in re.finditer(r'(?m)^    (\w+)\s*=\s*(?:async\s*)?\([^\n]*\)\s*=>\s*\{',js)]
    methods.sort(key=lambda m:m['line'])
    lwcs.append({'name':d.name,'methods':methods,'apex':re.findall(r'''import\s+(\w+)\s+from\s+["']@salesforce/apex/([^"']+)["']''',js),'handlers':sorted(set(re.findall(r'on\w+=\{(\w+)\}',html))),'js':js,'html':html})
result={'files':allfiles,'metadata':metadata,'classes':classes,'lwcs':lwcs}
(OUT/'inventory.json').write_text(json.dumps(result,indent=2,ensure_ascii=False))
counts=collections.Counter(x['kind'] for x in metadata)
summary={'files':len(allfiles),'metadata_files':len(metadata),'kinds':dict(counts),'classes':len(classes),'production_classes':sum(not c['test'] for c in classes),'production_methods':sum(len(c['methods']) for c in classes if not c['test']),'lwcs':len(lwcs),'fields':sum('/fields/' in m['path'] for m in metadata)}
(OUT/'summary.json').write_text(json.dumps(summary,indent=2))
for c in classes:
    if not c['test']:
        (OUT/(c['name']+'.methods.txt')).write_text('\n\n'.join(f"L{m['line']}: {m['signature']}\n{m['body']}" for m in c['methods']))
print(json.dumps(summary,indent=2))
print('\n'.join(f"{c['name']}: {len(c['methods'])} methods" for c in classes if not c['test']))
