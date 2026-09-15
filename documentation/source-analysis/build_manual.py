"""Author the editable Word manual from reviewed chapters and unchanged screenshots."""
from pathlib import Path
from docx import Document
from docx.shared import Inches,Pt,RGBColor
from docx.enum.section import WD_SECTION_START,WD_ORIENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT,WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement,parse_xml
from docx.oxml.ns import qn
from docx.opc.constants import RELATIONSHIP_TYPE as RT
from PIL import Image
from xml.sax.saxutils import escape
import json,re,html,sys
from figures import FIGURES
R=Path(__file__).resolve().parents[2];OUT=R/'output/doc';OUT.mkdir(parents=True,exist_ok=True)
D=Document();D.core_properties.title='NTE Salesforce operations and reconstruction manual';D.core_properties.subject='Workflow architecture data model and implementation reference';D.core_properties.author='Mission Community project documentation';D.core_properties.keywords='NTE Salesforce Apex Lightning Web to Lead reconstruction'
styles=D.styles
for s in styles:
    if s.type==1:
        s.font.name='Arial';s.font.color.rgb=RGBColor(0,0,0)
        for rpr in s.element.findall(qn('w:rPr')):
            for tag in ['w:color','w:u']:
                for v in rpr.findall(qn(tag)):rpr.remove(v)
        s.font.color.rgb=RGBColor(0,0,0)
        for ppr in s.element.findall(qn('w:pPr')):
            for v in ppr.findall(qn('w:pBdr')):ppr.remove(v)
styles['Normal'].font.size=Pt(11)
styles['Normal'].paragraph_format.line_spacing=1.08
styles['Normal'].paragraph_format.space_after=Pt(7)
for name,size in [('Title',30),('Subtitle',15),('Heading 1',22),('Heading 2',15),('Heading 3',12)]:
    s=styles[name];s.font.size=Pt(size);s.font.color.rgb=RGBColor(0,0,0);s.font.bold=name!='Subtitle'
    s.paragraph_format.space_before=Pt(16 if name.startswith('Heading') else 0)
    s.paragraph_format.space_after=Pt(8)
    s.paragraph_format.keep_with_next=True
for name,size in [('Source',9),('Figure title',16),('Small',9),('Code block',9)]:
    if name not in styles:styles.add_style(name,1)
    s=styles[name];s.font.name='Arial' if name!='Code block' else 'Courier New';s.font.size=Pt(size);s.font.color.rgb=RGBColor(0,0,0);s.paragraph_format.space_after=Pt(6);s.paragraph_format.line_spacing=1.03
styles['Figure title'].font.bold=True;styles['Figure title'].paragraph_format.keep_with_next=True
styles['Figure title'].paragraph_format.space_before=Pt(0)
styles['Source'].paragraph_format.keep_with_next=True
styles['Code block'].paragraph_format.space_after=Pt(8)
def setup(s,land=False):
    s.orientation=WD_ORIENT.LANDSCAPE if land else WD_ORIENT.PORTRAIT
    s.page_width=Inches(11 if land else 8.5);s.page_height=Inches(8.5 if land else 11)
    s.left_margin=s.right_margin=Inches(.65 if not land else .5)
    s.top_margin=s.bottom_margin=Inches(.65 if not land else .43)
    s.header_distance=s.footer_distance=Inches(.25)
setup(D.sections[0])
def field(p,code,result=''):
    r=p.add_run();a=OxmlElement('w:fldChar');a.set(qn('w:fldCharType'),'begin');r._r.append(a)
    t=OxmlElement('w:instrText');t.set(qn('xml:space'),'preserve');t.text=' '+code+' ';r._r.append(t)
    a=OxmlElement('w:fldChar');a.set(qn('w:fldCharType'),'separate');r._r.append(a)
    p.add_run(result)
    r=p.add_run();a=OxmlElement('w:fldChar');a.set(qn('w:fldCharType'),'end');r._r.append(a)
def bookmark(p,name):
    global bid
    a=OxmlElement('w:bookmarkStart');a.set(qn('w:id'),str(bid));a.set(qn('w:name'),name)
    b=OxmlElement('w:bookmarkEnd');b.set(qn('w:id'),str(bid));p._p.insert(0,a);p._p.append(b);bid+=1
bid=1
def link(p,label,url=None,anchor=None,size=None):
    h=OxmlElement('w:hyperlink')
    if url:h.set(qn('r:id'),p.part.relate_to(url,RT.HYPERLINK,is_external=True))
    if anchor:h.set(qn('w:anchor'),anchor)
    r=OxmlElement('w:r');rp=OxmlElement('w:rPr');co=OxmlElement('w:color');co.set(qn('w:val'),'174C6B');rp.append(co)
    if size:sz=OxmlElement('w:sz');sz.set(qn('w:val'),str(int(size*2)));rp.append(sz)
    r.append(rp);t=OxmlElement('w:t');t.text=label;r.append(t);h.append(r);p._p.append(h)
def inline(p,txt,size=None,bold=False):
    txt=html.unescape(txt)
    # Preserve explicit breaks and normalise only Markdown delimiters.
    parts=re.split(r'(\[[^\]]+\]\(https?://[^\s)]+\)|https?://[^\s<>]+|`[^`]+`|\*\*[^*]+\*\*|<br\s*/?>)',txt)
    for v in parts:
        if not v:continue
        if re.fullmatch(r'<br\s*/?>',v):p.add_run().add_break();continue
        m=re.fullmatch(r'\[([^\]]+)\]\((https?://[^\s)]+)\)',v)
        if m:link(p,m.group(1),m.group(2),size=size);continue
        if v.startswith('http'):
            url=v.rstrip('.,;');link(p,url,url,size=size)
            if url!=v:p.add_run(v[len(url):])
            continue
        code=v.startswith('`')and v.endswith('`');b=v.startswith('**')and v.endswith('**')
        if code:v=v[1:-1]
        if b:v=v[2:-2]
        r=p.add_run(v);r.bold=bold or b
        if size:r.font.size=Pt(size)
        if code:r.font.name='Courier New';r.font.size=Pt((size or 11)-.5)
def para(t='',style=None):
    p=D.add_paragraph(style=style);inline(p,t);return p
def clear_para(p):
    p.paragraph_format.space_after=Pt(0);p.paragraph_format.space_before=Pt(0);p.paragraph_format.line_spacing=1
def table(headers,rows,width=None,ratios=None,small=False):
    n=len(headers);total=width or 7.2
    if ratios is None:
        ratios={2:[.38,.62],3:[.22,.34,.44],4:[.19,.29,.23,.29]}.get(n,[1/n]*n)
    T=D.add_table(rows=1,cols=n);T.alignment=WD_TABLE_ALIGNMENT.CENTER;T.autofit=False
    tblPr=T._tbl.tblPr;b=OxmlElement('w:tblBorders')
    for k in ['top','left','bottom','right','insideH','insideV']:
        a=OxmlElement('w:'+k);a.set(qn('w:val'),'single');a.set(qn('w:sz'),'4');a.set(qn('w:color'),'D9D9D9');b.append(a)
    tblPr.append(b)
    grid=T._tbl.tblGrid
    for g,r in zip(grid.gridCol_lst,ratios):g.set(qn('w:w'),str(int(total*r*1440)))
    for rownum,vals in enumerate([headers]+rows):
        row=T.rows[0] if rownum==0 else T.add_row()
        if rownum==0:
            rep=OxmlElement('w:tblHeader');row._tr.get_or_add_trPr().append(rep)
        if sum(len(str(x))for x in vals)<1900:row._tr.get_or_add_trPr().append(OxmlElement('w:cantSplit'))
        for i,(c,v) in enumerate(zip(row.cells,vals)):
            c.width=Inches(total*ratios[i]);c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            pr=c._tc.get_or_add_tcPr();m=OxmlElement('w:tcMar')
            for name,num in [('top',60 if not small else 28),('bottom',60 if not small else 28),('left',80),('right',80)]:
                e=OxmlElement('w:'+name);e.set(qn('w:w'),str(num));e.set(qn('w:type'),'dxa');m.append(e)
            pr.append(m);shade=OxmlElement('w:shd');shade.set(qn('w:fill'),'DDEAF0' if rownum==0 else ('FFFFFF'if rownum%2 else 'F7F9FA'));pr.append(shade)
            p=c.paragraphs[0];clear_para(p);p.paragraph_format.line_spacing=1.04
            inline(p,str(v),size=9.3 if small else 9.5,bold=rownum==0)
    p=D.add_paragraph();clear_para(p);p.paragraph_format.space_after=Pt(3);p.add_run().font.size=Pt(2)
    return T

head=D.sections[0].header.paragraphs[0];head.text='NTE Salesforce operations and reconstruction';head.style='Small';head.paragraph_format.space_after=Pt(0)
foot=D.sections[0].footer.paragraphs[0];foot.alignment=WD_ALIGN_PARAGRAPH.RIGHT;foot.style='Small';field(foot,'PAGE','1');foot.add_run(' / ');field(foot,'NUMPAGES','1')
D.sections[0].different_first_page_header_footer=True
para('NTE Salesforce operations and reconstruction manual','Title')
para('Mission Community and Mission Motorsport','Subtitle')
para('Workflow and implementation reference','Subtitle')
para('12 September 2026  |  MMUAT and maintained source baseline','Source')
para('For the administrators, developers and architects who operate, maintain or rebuild the National Transition Event Salesforce solution.')
para('Start with the illustrated operator workflow. The following chapters explain the data model, pricing, automation, code, public forms, emails and environment setup. Exact field definitions and mappings accompany the feature explanations; the matching source archive supplies the implementation and a file-by-file integrity manifest.')
para('This is internal project documentation. It describes the implementation observed on the baseline date, including the client-owned settings still needed for production. The separate issues register distinguishes defects, configuration dependencies and unresolved decisions.')
para('Included reference coverage','Heading 2')
table(['Area','Coverage'],[('Salesforce schema','342 fields across six record objects and two custom metadata types'),('Runtime code','12 implementation Apex classes, 301 methods and constructors, four LWCs'),('Intake and automation','Ten public forms, four flows, nineteen stored email templates'),('Operations','Nineteen labelled screenshots, nine reports and twenty-five list views')])
D.add_page_break()
para('Contents','Title')
chapters=sorted((R/'documentation/chapters').glob('*.md'))
anchors={}
for i,c in enumerate(chapters,1):
    heading=c.read_text().splitlines()[0].lstrip('# ');a='chapter_'+str(i);anchors[str(c)]=a
    p=D.add_paragraph();p.paragraph_format.space_after=Pt(10);p.paragraph_format.tab_stops.add_tab_stop(Inches(6.9),WD_ALIGN_PARAGRAPH.RIGHT)
    link(p,heading,anchor=a);p.add_run('\t');field(p,'PAGEREF '+a+' \\h','')
para('Use Word Navigation to jump to object, class, form and configuration headings. Search by an exact API name to locate its field or method reference. The PDF preserves headings and internal links.','Small')
para('Screenshots are numbered in reading order. The numbered circles are editable Word labels placed over the original, unchanged captures. The compact key below each image identifies its controls; the surrounding workflow explains their effects.','Small')

figcount=0;figure_records=[];diagramcount=0
pending_figures=[];pending_diagrams=[]
def section(land=False):
    s=D.add_section(WD_SECTION_START.NEW_PAGE);setup(s,land);s.different_first_page_header_footer=False
    p=D.paragraphs[-1];clear_para(p);p.paragraph_format.line_spacing=Pt(1)
    # Keep linked headers within the narrower portrait width.
    return s
def figure(key):
    global figcount
    figcount+=1;filename,label,labels=FIGURES[key];section(True)
    p=para('Figure '+str(figcount)+' '+label,'Figure title');bookmark(p,'figure_'+key)
    img=R/'documentation/screenshots'/filename;w,h=Image.open(img).size;width=9.05 if len(labels)>18 else 9.35;wp=width*72;scale=wp/w
    p=D.add_paragraph();clear_para(p);p.paragraph_format.space_after=Pt(5);p.paragraph_format.keep_with_next=True
    pic=p.add_run().add_picture(str(img),width=Inches(width));pic._inline.docPr.set('descr',label+'. Numbered controls are described in the key below.')
    for i,(x,y,desc) in enumerate(labels,1):
        # Native VML annotations leave the embedded screenshot bytes unmodified.
        xx=x*scale-11;yy=y*scale-11
        xml=f'''<w:pict xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:v="urn:schemas-microsoft-com:vml"><v:oval id="fig{figcount}label{i}" style="position:absolute;margin-left:{xx:.3f}pt;margin-top:{yy:.3f}pt;width:22pt;height:22pt;z-index:251659264;mso-position-horizontal-relative:column;mso-position-vertical-relative:paragraph" fillcolor="#B21F38" strokecolor="#FFFFFF" strokeweight="0.8pt"><v:textbox inset="0,0,0,0"><w:txbxContent><w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="exact"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:color w:val="FFFFFF"/><w:sz w:val="18"/><w:b/></w:rPr><w:t>{i}</w:t></w:r></w:p></w:txbxContent></v:textbox></v:oval></w:pict>'''
        p.add_run()._r.append(parse_xml(xml))
    # Short three-column key stays with its screenshot, while full operation detail is prose.
    lab=[str(i)+'  '+x[2] for i,x in enumerate(labels,1)]
    rows=[lab[i:i+3]+['']*(3-len(lab[i:i+3]))for i in range(0,len(lab),3)]
    table(['Control labels','Control labels','Control labels'],rows,width=9.35,ratios=[1/3]*3,small=True)
    figure_records.append({'number':figcount,'key':key,'source':str(img.relative_to(R)),'title':label,'labels':len(labels)})
def diagram(key):
    global diagramcount
    diagramcount+=1;land=key in ['system','data']
    section(land)
    names={'system':'System context','data':'Data relationships','conversion':'Conversion and booking email sequence','updates':'Supplementary submission sequence'}
    p=para('Diagram '+str(diagramcount)+' '+names[key],'Figure title');bookmark(p,'diagram_'+key)
    p=D.add_paragraph();pic=p.add_run().add_picture(str(R/'documentation/diagrams'/ (key+'.png')),width=Inches(9.35 if land else 7.2));pic._inline.docPr.set('descr',names[key]+'. The relationships and sequence are also explained in the architecture chapter.');p.paragraph_format.space_after=Pt(3)
    if key=='data':para('Cardinalities read from the first named endpoint to the second along each arrow. Lookup fields can be empty at schema level; service rules impose the documented source and Primary Contact invariants.','Small')

def plain_heading(t):return re.sub(r'\s+',' ',re.sub(r'[^\w ]',' ',t).replace('_',' ')).strip()
inserts=json.loads((R/'documentation/source-analysis/generated-inserts.json').read_text())
def parse(text,anchor=None):
    for token,replace in inserts.items():text=text.replace(token,replace)
    lines=text.splitlines();i=0;first=True
    while i<len(lines):
        line=lines[i].strip()
        if not line:i+=1;continue
        if line.startswith('[FIGURE:'):
            key=line[8:-1];pending_figures.append(key);p=D.add_paragraph(style='Small');link(p,'Figure '+str(len(pending_figures))+' '+FIGURES[key][1],anchor='figure_'+key);i+=1;continue
        if line.startswith('[DIAGRAM:'):
            key=line[9:-1];pending_diagrams.append(key);p=D.add_paragraph(style='Small');link(p,'See diagram '+str(len(pending_diagrams))+' in the architecture diagrams that follow',anchor='diagram_'+key);i+=1;continue
        if line.startswith('#'):
            level=len(line)-len(line.lstrip('#'));text=line[level:].strip();p=para(plain_heading(text),'Heading '+str(min(level,3)))
            if level==1:
                p.paragraph_format.page_break_before=True
                if anchor:bookmark(p,anchor)
            else:bookmark(p,'h_'+str(bid))
            i+=1;continue
        if line.startswith('```'):
            code=[];i+=1
            while i<len(lines)and not lines[i].strip().startswith('```'):code.append(lines[i]);i+=1
            p=para('\n'.join(code),'Code block');p.paragraph_format.keep_together=True;i+=1;continue
        if line.startswith('|'):
            raw=[]
            while i<len(lines)and lines[i].strip().startswith('|'):
                raw.append([x.strip()for x in lines[i].strip().strip('|').split('|')]);i+=1
            if len(raw)>=2:table(raw[0],raw[2:])
            continue
        if re.match(r'^[-*] ',line):para(line[2:],'List Bullet');i+=1;continue
        if re.match(r'^\d+\. ',line):para(re.sub(r'^\d+\. ','',line),'List Number');i+=1;continue
        parts=[line];i+=1
        while i<len(lines)and lines[i].strip()and not re.match(r'^(#|\||\[FIGURE:|\[DIAGRAM:|```|[-*] |\d+\. )',lines[i].strip()):parts.append(lines[i].strip());i+=1
        txt=' '.join(parts);para(txt,'Source' if txt.startswith('Source: ') else None)
for c in chapters:
    parse(c.read_text(),anchors[str(c)])
    if c.name.startswith('01-'):
        p=para('Workflow screen atlas','Heading 2')
        para('The following labelled captures accompany the operating instructions above. Use the figure links to move between an instruction and its screen. The shared Salesforce header controls are labelled once on the orientation screen; the later captures focus on the controls for that task.','Small')
        for key in pending_figures:figure(key)
        section(False)
    if c.name.startswith('02-'):
        for key in pending_diagrams:diagram(key)
# Remove unwanted inherited title/heading borders and theme colour everywhere.
for p in D.paragraphs:
    if p.style.name in ['Title','Subtitle','Heading 1','Heading 2','Heading 3','Figure title']:
        pp=p._p.get_or_add_pPr()
        for e in pp.findall(qn('w:pBdr')):pp.remove(e)
        for r in p.runs:r.font.color.rgb=RGBColor(0,0,0);r.font.underline=False
settings=D.settings.element;u=OxmlElement('w:updateFields');u.set(qn('w:val'),'true');settings.append(u)
path=OUT/'NTE_Salesforce_Operations_and_Reconstruction_Manual.docx';D.save(path)
(R/'documentation/source-analysis/figure-register.json').write_text(json.dumps(figure_records,indent=2))
print(json.dumps({'docx':str(path),'chapters':len(chapters),'figures':figcount,'diagrams':diagramcount,'tables':len(D.tables),'paragraphs':len(D.paragraphs)}))
