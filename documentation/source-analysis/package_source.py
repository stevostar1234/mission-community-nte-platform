"""Package the reviewed implementation without auth caches, exports or QA intermediates."""
from pathlib import Path
import hashlib,json,re,zipfile

R=Path(__file__).resolve().parents[2]
inv=json.loads((R/'documentation/source-analysis/inventory.json').read_text())
selected=[]; excluded=[]
for x in inv['files']:
    p=Path(x['path']); reason=None
    if p.name=='.DS_Store':reason='Operating-system file'
    elif p.parts[0]=='_org-audit':reason='Historical local native snapshot'
    elif p.parts[0]=='audit' and p.suffix!='.md':reason='Historical raw evidence or media; dated narrative retained'
    if reason:excluded.append({'path':str(p),'reason':reason});continue
    data=(R/p).read_bytes()
    if hashlib.sha256(data).hexdigest()!=x['sha256']:raise RuntimeError('Reviewed source changed: '+str(p))
    selected.append((str(p),data))
for p in sorted((R/'documentation').rglob('*')):
    if p.is_file() and '__pycache__' not in p.parts and p.name not in ['source-bundle-manifest.json','document-qa.json','visual-review.json']:
        selected.append((str(p.relative_to(R)),p.read_bytes()))

readme='''# NTE Salesforce reconstruction source

This archive accompanies the 12 September 2026 NTE Salesforce Operations and Reconstruction Manual. Start with that manual's workflow, then follow Reconstruction and administration and its exact field, form, Flow, Apex and configuration references.

## Rebuild the supplied candidate

1. Extract the archive into an empty directory. Verify SHA256SUMS.txt before making changes.
2. Run `node scripts/build-metadata.js` from the extracted root. This regenerates the supplied metadata and email examples from their maintained generators.
3. Run the project-specific local checks listed in the manual. The recorded metadata-reports test harness failure is described in documentation/PROJECT_DOCUMENTATION_ISSUES.md.
4. Apply destination configuration and a target-preserving shared-picklist overlay as described in the manual. The source targets MMUAT; public Salesforce field IDs are organisation-specific. Supply client-owned final-pack, logo, sender and merchant settings at the documented points.
5. Validate the exact candidate against its authorised destination before release. Completed MMUAT fixtures and accepted sends must not be replayed as setup steps.

The archive is source, not an installed Salesforce org or a data migration. API credentials, authentication caches, raw native exports, Git internals and operating-system files are excluded. The configuration examples contain no API keys. Historical audit narratives are retained for decision context, and the current manual and issues register identify superseded statements. Dated proposal entries do not grant implementation approval.

## Documentation source

Markdown chapters, original screenshots, diagram definitions and the authoring scripts are under documentation. The Word and PDF are distributed alongside this archive. Python documentation tools require python-docx, Pillow and lxml; the document renderer additionally uses LibreOffice and Poppler. Source rebuilding itself requires Node and the standard-library Python maintenance scripts only.

SHA256SUMS.txt covers every archive member except itself. The source inventory and file-coverage.csv also account for reviewed files excluded from this distribution. Their historical hashes are evidence of the review baseline, not an instruction to restore excluded data.
'''
selected.append(('RECONSTRUCTION_README.md',readme.encode()))
selected.sort()
for path,data in selected:
    if Path(path).suffix in ['.js','.json','.py','.md','.xml','.html','.cls','.apex']:
        s=data.decode('utf-8',errors='ignore')
        if re.search(r'\b(?:sk_live|sk_test|rk_live|rk_test)_[A-Za-z0-9]{24,}\b',s):raise RuntimeError('Potential credential in '+path)
checks=''.join(hashlib.sha256(data).hexdigest()+'  '+path+'\n' for path,data in selected)
out=R/'output/doc/NTE_Salesforce_Reconstruction_Source.zip'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for path,data in selected:z.writestr(path,data)
    z.writestr('SHA256SUMS.txt',checks)
with zipfile.ZipFile(out) as z:
    assert z.testzip() is None
    for row in z.read('SHA256SUMS.txt').decode().splitlines():
        digest,path=row.split('  ',1);assert hashlib.sha256(z.read(path)).hexdigest()==digest
summary={'path':str(out),'files':len(selected)+1,'bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'excludedReviewedFiles':excluded,'archiveIntegrity':'All member SHA256 values verified'}
(R/'documentation/source-analysis/source-bundle-manifest.json').write_text(json.dumps(summary,indent=2))
print(json.dumps({k:v for k,v in summary.items() if k!='excludedReviewedFiles'},indent=2))
