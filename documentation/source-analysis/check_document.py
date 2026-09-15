"""Check final artefact structure, source coverage and rendered pagination."""
from pathlib import Path
import hashlib,json,re,zipfile
from lxml import etree
from pypdf import PdfReader
R=Path(__file__).resolve().parents[2]
out=R/'output/doc/NTE_Salesforce_Operations_and_Reconstruction_Manual.docx'
render=R/'tmp/project-documentation/render-release3'
pdf=render/(out.stem+'.pdf');pages=PdfReader(pdf).pages
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main','wp':'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing','v':'urn:schemas-microsoft-com:vml'}
with zipfile.ZipFile(out) as z:
    root=etree.fromstring(z.read('word/document.xml'));text='\n'.join(root.xpath('//w:t/text()',namespaces=ns))
    bookmarks=set(root.xpath('//w:bookmarkStart/@w:name',namespaces=ns));anchors=set(root.xpath('//w:hyperlink/@w:anchor',namespaces=ns))
    assert anchors<=bookmarks,anchors-bookmarks
    media={hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist() if n.startswith('word/media/')}
    screenshots=list((R/'documentation/screenshots').glob('*.png'))
    assert all(hashlib.sha256(p.read_bytes()).hexdigest() in media for p in screenshots)
    assert len(root.xpath('//wp:docPr[@descr]',namespaces=ns))==23
    assert not re.search(r'\[(?:FIGURE|DIAGRAM):|\[CATALOGUE\]|\[FORMS_OVERVIEW\]|\[EMAIL_CATALOGUE\]',text)
    inv=json.loads((R/'documentation/source-analysis/inventory.json').read_text())
    fields=[m['definition']['fullName'] for m in inv['metadata'] if '/fields/' in m['path']]
    assert all(f in text for f in fields)
    methods=[m for c in inv['classes'] if not c['test'] for m in c['methods']]
    assert all(m['name']+'(' in text for m in methods)
    assert all(x['name'] in text for x in inv['lwcs'])
    assert all(method in text for c in inv['lwcs'] for alias,method in c['apex'])
    assert all(m['name'] in text for c in inv['lwcs'] for m in c['methods'])
    labelcount=len(root.xpath('//v:oval',namespaces=ns))
index=[]
for i,p in enumerate(pages,1):
    t=p.extract_text();lines=t.splitlines();index.append({'page':i,'length':len(t),'start':lines[1:4]})
    assert (render/('page-'+str(i)+'.png')).exists()
    assert not re.search(r'Error!|Reference source not found|Bookmark not defined|�',t),i
    assert len(t)>65,('Possibly blank page',i,len(t))
assert 'Workflow' in pages[2].extract_text()
source_changes=[x['path'] for x in inv['files'] if hashlib.sha256((R/x['path']).read_bytes()).hexdigest()!=x['sha256']]
assert not source_changes,source_changes
summary={'docx':str(out),'pdf':str(pdf),'pages':len(pages),'originalScreenshotsEmbedded':len(screenshots),'editableNumberedLabels':labelcount,'diagrams':4,'fieldNamesPresent':len(fields),'implementationMethodEntriesPresent':len(methods),'lwcMethodGetterHandlerEntries':sum(len(c['methods']) for c in inv['lwcs']),'lwcApexImportsPresent':sum(len(c['apex']) for c in inv['lwcs']),'internalLinksValid':True,'originalSourceFilesChanged':source_changes,'visualReview':'See visual-review.json for page-by-page review completion'}
(R/'documentation/source-analysis/document-qa.json').write_text(json.dumps(summary,indent=2))
(R/'tmp/project-documentation/final-page-index.json').write_text(json.dumps(index,indent=2))
print(json.dumps(summary,indent=2))
