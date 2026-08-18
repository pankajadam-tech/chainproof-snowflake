const pptxgen = require('pptxgenjs');
const fs = require('fs');
const path = require('path');
const {
  imageSizingContain,
  imageSizingCrop,
  safeOuterShadow,
  warnIfSlideHasOverlaps,
  warnIfSlideElementsOutOfBounds,
} = require('/home/oai/skills/slides/pptxgenjs_helpers');

const pptx = new pptxgen();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'ChainProof';
pptx.subject = 'Snowflake CoCo CLI Hackathon submission';
pptx.title = 'ChainProof - Metric Trust and Reconciliation for Supply-Chain AI';
pptx.company = 'ChainProof';
pptx.lang = 'en-US';
pptx.theme = {
  headFontFace: 'Inter Display',
  bodyFontFace: 'Inter',
  lang: 'en-US'
};
pptx.defineSlideMaster({
  title: 'CHAINPROOF_MASTER',
  background: { color: '071B2E' },
  objects: [
    { rect: { x: 0, y: 0, w: 13.333, h: 7.5, fill: { color: '071B2E' }, line: { color: '071B2E' } } },
    { shape: { type: pptx.ShapeType.ellipse, x: 11.25, y: -0.7, w: 2.9, h: 2.9, fill: { color: '0E3654', transparency: 40 }, line: { color: '0E3654', transparency: 100 } } },
    { shape: { type: pptx.ShapeType.ellipse, x: -0.9, y: 6.35, w: 3.2, h: 3.2, fill: { color: '0E3654', transparency: 45 }, line: { color: '0E3654', transparency: 100 } } },
    { text: { text: 'CHAINPROOF', options: { x: 0.55, y: 7.12, w: 1.7, h: 0.18, fontFace: 'Inter', fontSize: 7.5, color: '65829B', bold: true, charSpacing: 1.5, margin: 0 } } },
    { text: { text: 'Snowflake CoCo CLI Hackathon', options: { x: 2.25, y: 7.12, w: 2.25, h: 0.18, fontFace: 'Inter', fontSize: 7.5, color: '65829B', margin: 0 } } },
  ],
  slideNumber: { x: 12.35, y: 7.08, w: 0.4, h: 0.22, color: '65829B', fontFace: 'Inter', fontSize: 8, align: 'right' }
});

const C = {
  navy: '071B2E', navy2: '0D2941', navy3: '102F3C', blue: '2E75FF', cyan: '32D5FF',
  ice: 'EAF8FF', green: '34D399', amber: 'F5B84B', red: 'FF6B6B', white: 'FFFFFF',
  text: 'DCEBFA', muted: '89A5BE', line: '2A4963', purple: '9B8AFB', gray: '152C42'
};
const ROOT = path.resolve(__dirname, '../..');
const ARCH = path.resolve(ROOT, 'docs/assets/architecture');
const CONFIG_PATH = path.resolve(__dirname, 'deck_config.json');
const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));

function addTitle(slide, title, subtitle='') {
  slide.addText(title, { x: 0.65, y: 0.48, w: 11.8, h: 0.46, fontFace: 'Inter Display', fontSize: 26, bold: true, color: C.white, margin: 0 });
  if (subtitle) slide.addText(subtitle, { x: 0.65, y: 1.05, w: 11.7, h: 0.25, fontFace: 'Inter', fontSize: 11.5, color: C.muted, margin: 0 });
  slide.addShape(pptx.ShapeType.line, { x: 0.65, y: 1.4, w: 12.0, h: 0, line: { color: C.cyan, transparency: 12, width: 1.5 } });
}
function addPill(slide, text, x, y, w, color, opts={}) {
  slide.addShape(pptx.ShapeType.roundRect, { x, y, w, h: opts.h || 0.34, rectRadius: 0.08, fill: { color: C.navy2 }, line: { color, width: 1.2 }, shadow: safeOuterShadow('000000',0.15,45,1.2,0.7) });
  slide.addText(text, { x: x+0.08, y: y+0.07, w: w-0.16, h: (opts.h||0.34)-0.1, fontFace: 'Inter', fontSize: opts.fontSize||9.5, bold: true, color, align: 'center', valign: 'mid', margin: 0 });
}
function addMetricCard(slide, x, y, w, label, metric, value, color) {
  slide.addShape(pptx.ShapeType.roundRect, { x, y, w, h: 1.75, rectRadius: 0.12, fill: { color: C.navy2 }, line: { color, width: 1.5 }, shadow: safeOuterShadow('000000',0.22,45,2,1.2) });
  slide.addText(label, { x:x+0.16,y:y+0.18,w:w-0.32,h:0.28,fontSize:13,bold:true,color:C.white,align:'center',margin:0 });
  slide.addText(metric, { x:x+0.16,y:y+0.52,w:w-0.32,h:0.28,fontSize:8.8,color:C.muted,align:'center',margin:0 });
  slide.addText(value, { x:x+0.1,y:y+0.93,w:w-0.2,h:0.56,fontFace:'Inter Display',fontSize:34,bold:true,color,align:'center',margin:0 });
}
function addStep(slide, n, title, body, x, y, color) {
  slide.addShape(pptx.ShapeType.roundRect,{x,y,w:1.72,h:1.35,rectRadius:0.1,fill:{color:C.navy2},line:{color,width:1.4},shadow:safeOuterShadow('000000',0.18,45,1.5,0.8)});
  slide.addShape(pptx.ShapeType.ellipse,{x:x+0.12,y:y+0.12,w:0.35,h:0.35,fill:{color,transparency:80},line:{color,width:1.2}});
  slide.addText(String(n),{x:x+0.12,y:y+0.18,w:0.35,h:0.18,fontSize:10,bold:true,color,align:'center',margin:0});
  slide.addText(title,{x:x+0.52,y:y+0.14,w:1.05,h:0.28,fontSize:11,bold:true,color:C.white,margin:0});
  slide.addText(body,{x:x+0.14,y:y+0.58,w:1.44,h:0.56,fontSize:8.4,color:C.text,margin:0.02,breakLine:false,valign:'mid'});
}
function addArrow(slide, x, y, w, color=C.cyan) {
  slide.addShape(pptx.ShapeType.line,{x,y:y+0.16,w,h:0,line:{color,width:1.6,beginArrowType:'none',endArrowType:'triangle'}});
}
function addMockWindow(slide, x, y, w, h, title, variant='conflict') {
  slide.addShape(pptx.ShapeType.roundRect,{x,y,w,h,rectRadius:0.08,fill:{color:'F7FAFC'},line:{color:'B9C8D4',width:1},shadow:safeOuterShadow('000000',0.22,45,2.5,1.2)});
  slide.addShape(pptx.ShapeType.rect,{x:x+0.01,y:y+0.01,w:w-0.02,h:0.32,fill:{color:'E9EFF5'},line:{color:'E9EFF5'}});
  ['FF6B6B','F5B84B','34D399'].forEach((c,i)=>slide.addShape(pptx.ShapeType.ellipse,{x:x+0.13+i*0.18,y:y+0.11,w:0.08,h:0.08,fill:{color:c},line:{color:c}}));
  slide.addText(title,{x:x+0.92,y:y+0.08,w:w-1.08,h:0.16,fontSize:7.8,bold:true,color:'284359',margin:0});
  slide.addShape(pptx.ShapeType.rect,{x:x+0.12,y:y+0.46,w:1.15,h:h-0.6,fill:{color:'EEF4F8'},line:{color:'D7E3EC',width:0.6}});
  slide.addText('View as',{x:x+0.23,y:y+0.62,w:0.72,h:0.13,fontSize:6.5,bold:true,color:'5F7890',margin:0});
  slide.addShape(pptx.ShapeType.roundRect,{x:x+0.2,y:y+0.82,w:0.94,h:0.27,fill:{color:'FFFFFF'},line:{color:'B9C8D4',width:0.7}});
  slide.addText('Data Steward',{x:x+0.28,y:y+0.9,w:0.78,h:0.11,fontSize:6.5,color:'284359',margin:0});
  slide.addText('PO-5001',{x:x+0.23,y:y+1.24,w:0.72,h:0.13,fontSize:6.5,bold:true,color:'5F7890',margin:0});
  slide.addText('Demo stage',{x:x+0.23,y:y+1.62,w:0.72,h:0.13,fontSize:6.5,bold:true,color:'5F7890',margin:0});
  const cx=x+1.48, cw=w-1.66;
  if(variant==='conflict'){
    slide.addText('One KPI name. Three answers.',{x:cx,y:y+0.55,w:cw,h:0.3,fontSize:12,bold:true,color:'102F3C',margin:0});
    const vals=[['Planning','95%','2E75FF'],['Procurement','85%','16A876'],['Logistics','90%','C98A16']];
    vals.forEach((d,i)=>{
      const bx=cx+i*(cw/3)+0.02;
      slide.addShape(pptx.ShapeType.roundRect,{x:bx,y:y+1.02,w:cw/3-0.12,h:0.92,fill:{color:'FFFFFF'},line:{color:d[2],width:1}});
      slide.addText(d[0],{x:bx+0.04,y:y+1.17,w:cw/3-0.2,h:0.16,fontSize:6.8,bold:true,color:'284359',align:'center',margin:0});
      slide.addText(d[1],{x:bx+0.04,y:y+1.48,w:cw/3-0.2,h:0.27,fontSize:15,bold:true,color:d[2],align:'center',margin:0});
    });
    slide.addShape(pptx.ShapeType.roundRect,{x:cx,y:y+2.1,w:cw,h:0.47,fill:{color:'FFF1F1'},line:{color:'FF6B6B',width:1}});
    slide.addText('Metric conflict detected - no enterprise answer selected',{x:cx+0.1,y:y+2.25,w:cw-0.2,h:0.15,fontSize:7.4,bold:true,color:'B63A3A',align:'center',margin:0});
  } else if(variant==='trusted'){
    slide.addText('Trusted Enterprise Answer',{x:cx,y:y+0.55,w:cw,h:0.3,fontSize:12,bold:true,color:'102F3C',margin:0});
    slide.addShape(pptx.ShapeType.roundRect,{x:cx,y:y+1.02,w:cw,h:1.25,fill:{color:'ECFFF8'},line:{color:'34D399',width:1.3}});
    slide.addText('Enterprise Supplier Fill Rate',{x:cx+0.15,y:y+1.2,w:cw-0.3,h:0.22,fontSize:9.5,bold:true,color:'116B4B',align:'center',margin:0});
    slide.addText('85%',{x:cx+0.15,y:y+1.54,w:cw-0.3,h:0.43,fontSize:25,bold:true,color:'16A876',align:'center',margin:0});
    slide.addText('Version 1.0  |  Enterprise - Approved',{x:cx+0.15,y:y+2.0,w:cw-0.3,h:0.16,fontSize:7.1,color:'116B4B',align:'center',margin:0});
    slide.addText('85 accepted on time / 100 ordered',{x:cx,y:y+2.48,w:cw,h:0.2,fontSize:8,bold:true,color:'284359',align:'center',margin:0});
  } else if(variant==='ask'){
    slide.addText('Ask ChainProof',{x:cx,y:y+0.55,w:cw,h:0.3,fontSize:12,bold:true,color:'102F3C',margin:0});
    slide.addShape(pptx.ShapeType.roundRect,{x:cx,y:y+1.02,w:cw,h:0.52,fill:{color:'FFFFFF'},line:{color:'B9C8D4',width:0.8}});
    slide.addText('What is fill rate for PO-5001?',{x:cx+0.14,y:y+1.2,w:cw-0.28,h:0.17,fontSize:8,color:'284359',margin:0});
    slide.addShape(pptx.ShapeType.roundRect,{x:cx,y:y+1.72,w:cw,h:1.12,fill:{color:'ECFFF8'},line:{color:'34D399',width:1.1}});
    slide.addText('Interpreted as Enterprise Supplier Fill Rate v1.0',{x:cx+0.12,y:y+1.89,w:cw-0.24,h:0.17,fontSize:7.2,bold:true,color:'116B4B',align:'center',margin:0});
    slide.addText('85%',{x:cx+0.12,y:y+2.19,w:cw-0.24,h:0.4,fontSize:24,bold:true,color:'16A876',align:'center',margin:0});
  } else {
    slide.addText('Evidence-backed review',{x:cx,y:y+0.55,w:cw,h:0.3,fontSize:12,bold:true,color:'102F3C',margin:0});
    ['Supplier agreement','Carrier SLA','Quality policy','Governance policy'].forEach((t,i)=>{
      slide.addShape(pptx.ShapeType.roundRect,{x:cx,y:y+0.98+i*0.42,w:cw,h:0.32,fill:{color:'FFFFFF'},line:{color:['2E75FF','32D5FF','9B8AFB','34D399'][i],width:0.9}});
      slide.addText(t+'  [cited]',{x:cx+0.1,y:y+1.08+i*0.42,w:cw-0.2,h:0.12,fontSize:7.2,bold:true,color:'284359',margin:0});
    });
    slide.addText('Advisor cannot approve or write governance data',{x:cx,y:y+2.72,w:cw,h:0.16,fontSize:7.4,bold:true,color:'B63A3A',align:'center',margin:0});
  }
}

function configAsset(rel) {
  return path.resolve(__dirname, rel);
}
function hasUsableImage(pth) {
  try { return fs.statSync(pth).size > 10000; } catch (_) { return false; }
}
function addScreenshotFrame(slide, pth, x, y, w, h, label) {
  slide.addShape(pptx.ShapeType.roundRect,{x,y,w,h,rectRadius:0.08,fill:{color:'F7FAFC'},line:{color:'B9C8D4',width:1},shadow:safeOuterShadow('000000',0.22,45,2.5,1.2)});
  slide.addShape(pptx.ShapeType.rect,{x:x+0.01,y:y+0.01,w:w-0.02,h:0.32,fill:{color:'E9EFF5'},line:{color:'E9EFF5'}});
  ['FF6B6B','F5B84B','34D399'].forEach((c,i)=>slide.addShape(pptx.ShapeType.ellipse,{x:x+0.13+i*0.18,y:y+0.11,w:0.08,h:0.08,fill:{color:c},line:{color:c}}));
  slide.addText(label,{x:x+0.92,y:y+0.08,w:w-1.08,h:0.16,fontSize:7.8,bold:true,color:'284359',margin:0});
  slide.addImage({path:pth,...imageSizingContain(pth,x+0.11,y+0.42,w-0.22,h-0.54)});
}

function addNotes(slide, body, sources=[]) {
  const src = sources.length ? `\n\n[Sources]\n${sources.map(s=>'- '+s).join('\n')}` : '';
  slide.addNotes(body + src);
}
function finalize(slide) {
  warnIfSlideHasOverlaps(slide,pptx);
  warnIfSlideElementsOutOfBounds(slide,pptx);
}

// Slide 1
{
  const s=pptx.addSlide('CHAINPROOF_MASTER');
  s.background={color:C.navy};
  s.addImage({path:path.join(ARCH,'chainproof_logo.png'),...imageSizingContain(path.join(ARCH,'chainproof_logo.png'),0.7,0.65,1.15,1.15)});
  s.addText('ChainProof',{x:2.05,y:0.65,w:7.2,h:0.72,fontFace:'Inter Display',fontSize:34,bold:true,color:C.white,margin:0});
  s.addText('Metric Trust and Reconciliation for Supply-Chain AI',{x:2.08,y:1.38,w:8.05,h:0.36,fontSize:14.5,color:C.cyan,margin:0});
  s.addText('One KPI name. Three valid calculations. One governed enterprise answer.',{x:0.75,y:2.05,w:11.7,h:0.52,fontSize:21,bold:true,color:C.ice,align:'center',margin:0});
  addMetricCard(s,0.95,2.95,3.4,'Planning','Material Availability','95%',C.blue);
  addMetricCard(s,4.97,2.95,3.4,'Procurement','Accepted Supplier Fill','85%',C.green);
  addMetricCard(s,8.99,2.95,3.4,'Logistics','On-Time Arrival','90%',C.amber);
  s.addShape(pptx.ShapeType.downArrow,{x:5.85,y:4.93,w:1.65,h:0.72,fill:{color:C.cyan,transparency:5},line:{color:C.cyan,transparency:100}});
  s.addShape(pptx.ShapeType.roundRect,{x:4.28,y:5.72,w:4.78,h:0.95,fill:{color:C.navy3},line:{color:C.green,width:2},shadow:safeOuterShadow('000000',0.22,45,2,1)});
  s.addText('Enterprise Supplier Fill Rate v1.0  =  85%',{x:4.55,y:6.02,w:4.24,h:0.32,fontSize:18,bold:true,color:C.green,align:'center',margin:0});
  addPill(s,'Snowflake-native',10.4,0.72,1.65,C.cyan,{fontSize:8.5});
  addPill(s,'CoCo CLI-assisted',10.4,1.15,1.65,C.purple,{fontSize:8.5});
  addNotes(s,'Opening: Three teams report the same KPI name. Planning says 95%, Procurement says 85%, and Logistics says 90%. All three can be correct. ChainProof governs the enterprise definition before AI answers.');
  finalize(s);
}

// Slide 2
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'The business problem','Correct data and valid SQL can still produce the wrong business answer.');
  s.addImage({path:path.join(ARCH,'business_conflict_lifecycle.png'),...imageSizingContain(path.join(ARCH,'business_conflict_lifecycle.png'),0.75,1.66,7.1,4.0)});
  const items=[
    ['Executive inconsistency','Different teams publish incompatible KPIs under one label.'],
    ['Supplier disputes','Date and quality rules change accountability.'],
    ['AI risk','A copilot can confidently select the wrong definition.'],
    ['Manual reconciliation','Analysts repeatedly rebuild the same explanation.'],
  ];
  items.forEach((d,i)=>{
    const y=1.82+i*1.1;
    s.addShape(pptx.ShapeType.roundRect,{x:8.25,y,w:4.25,h:0.88,fill:{color:C.navy2},line:{color:[C.red,C.amber,C.cyan,C.purple][i],width:1.2}});
    s.addText(d[0],{x:8.48,y:y+0.16,w:3.75,h:0.22,fontSize:12,bold:true,color:C.white,margin:0});
    s.addText(d[1],{x:8.48,y:y+0.43,w:3.65,h:0.28,fontSize:8.7,color:C.text,margin:0});
  });
  s.addShape(pptx.ShapeType.roundRect,{x:8.25,y:6.15,w:4.25,h:0.62,fill:{color:'221E2F'},line:{color:C.red,width:1.2}});
  s.addText('Correct SQL + wrong metric meaning = confidently wrong AI',{x:8.45,y:6.35,w:3.85,h:0.18,fontSize:10.3,bold:true,color:C.red,align:'center',margin:0});
  addNotes(s,'Explain that the conflict is semantic, not merely malformed data. ChainProof treats the metric contract itself as governed data.');
  finalize(s);
}

// Slide 3
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'The ChainProof trust lifecycle','AI analytics begins only after the metric is governed.');
  const steps=[
    ['Detect','Find one label with competing calculations',C.red],
    ['Compare','Grain, numerator, denominator, dates',C.cyan],
    ['Assess impact','Translate rates into supplier, logistics, and production action',C.blue],
    ['Evidence','Attach agreement, SLA, and policy',C.purple],
    ['Approve','Human Data Steward decision',C.green],
    ['Publish','Only approved version reaches Semantic',C.amber],
    ['Verify','Cortex answer + visible evidence',C.cyan],
  ];
  steps.forEach((d,i)=>{
    const x=0.48+i*1.82;
    addStep(s,i+1,d[0],d[1],x,2.05,d[2]);
    if(i<steps.length-1) addArrow(s,x+1.735,2.56,0.07,C.cyan);
  });
  s.addShape(pptx.ShapeType.roundRect,{x:1.1,y:4.42,w:11.1,h:1.33,fill:{color:C.navy2},line:{color:C.green,width:1.5},shadow:safeOuterShadow('000000',0.2,45,2,1)});
  s.addText('Metric trust firewall',{x:1.38,y:4.72,w:2.65,h:0.3,fontSize:17,bold:true,color:C.green,margin:0});
  s.addText('A normal copilot answers the question. ChainProof first proves which definition it is allowed to use.',{x:4.15,y:4.64,w:7.55,h:0.5,fontSize:15,bold:true,color:C.white,margin:0.02,valign:'mid'});
  s.addText('USP: Semantic layers govern agreed metrics. ChainProof governs the disagreement that exists before agreement.',{x:1.25,y:6.25,w:10.85,h:0.38,fontSize:14.5,bold:true,color:C.cyan,align:'center',margin:0});
  addNotes(s,'Use this slide to position ChainProof as a metric trust control plane, not a dashboard or generic chatbot.');
  finalize(s);
}

// Slide 4
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'Human governance changes the answer','The AI consumes the Data Steward decision; it does not make it.');
  // before
  s.addShape(pptx.ShapeType.roundRect,{x:0.7,y:1.8,w:5.75,h:4.55,fill:{color:C.navy2},line:{color:C.red,width:1.5},shadow:safeOuterShadow('000000',0.2,45,2,1)});
  s.addText('BEFORE APPROVAL',{x:0.98,y:2.06,w:2.1,h:0.24,fontSize:13,bold:true,color:C.red,margin:0});
  [['Planning','95%',C.blue],['Procurement','85%',C.green],['Logistics','90%',C.amber]].forEach((d,i)=>{
    s.addText(d[0],{x:1.1,y:2.72+i*0.68,w:2.2,h:0.23,fontSize:12,color:C.white,margin:0});
    s.addText(d[1],{x:4.85,y:2.65+i*0.68,w:0.95,h:0.3,fontSize:18,bold:true,color:d[2],align:'right',margin:0});
    s.addShape(pptx.ShapeType.line,{x:1.1,y:3.05+i*0.68,w:4.7,h:0,line:{color:C.line,width:0.7}});
  });
  s.addShape(pptx.ShapeType.roundRect,{x:1.05,y:5.02,w:5.05,h:0.75,fill:{color:'2A1D27'},line:{color:C.red,width:1.1}});
  s.addText('Enterprise answer: NOT APPROVED',{x:1.28,y:5.26,w:4.58,h:0.2,fontSize:13,bold:true,color:C.red,align:'center',margin:0});
  // after
  s.addShape(pptx.ShapeType.roundRect,{x:6.88,y:1.8,w:5.75,h:4.55,fill:{color:C.navy2},line:{color:C.green,width:1.5},shadow:safeOuterShadow('000000',0.2,45,2,1)});
  s.addText('AFTER DATA STEWARD APPROVAL',{x:7.16,y:2.06,w:3.3,h:0.24,fontSize:13,bold:true,color:C.green,margin:0});
  s.addText('Enterprise Supplier Fill Rate',{x:7.35,y:2.78,w:4.85,h:0.34,fontSize:20,bold:true,color:C.white,align:'center',margin:0});
  s.addText('85%',{x:7.55,y:3.45,w:4.45,h:0.8,fontSize:48,bold:true,color:C.green,align:'center',margin:0});
  s.addText('Version 1.0  |  Enterprise - Approved',{x:7.35,y:4.35,w:4.85,h:0.28,fontSize:12,bold:true,color:C.cyan,align:'center',margin:0});
  s.addText('85 accepted on time / 100 ordered',{x:7.35,y:4.9,w:4.85,h:0.25,fontSize:13,color:C.text,align:'center',margin:0});
  s.addShape(pptx.ShapeType.roundRect,{x:7.68,y:5.4,w:4.2,h:0.52,fill:{color:'0F3A34'},line:{color:C.green,width:1}});
  s.addText('Approved → Active → Published',{x:7.9,y:5.58,w:3.75,h:0.18,fontSize:10.8,bold:true,color:C.green,align:'center',margin:0});
  s.addShape(pptx.ShapeType.chevron,{x:6.52,y:3.45,w:0.22,h:0.55,fill:{color:C.cyan},line:{color:C.cyan,transparency:100}});
  s.addText('“View as” demonstrates persona presentation under one learner role. It never changes permissions or formulas.',{x:1.0,y:6.7,w:11.35,h:0.3,fontSize:11,bold:true,color:C.muted,align:'center',margin:0});
  addNotes(s,'Explain View as in plain language: the account has one learner role, so the UI demonstrates what each persona would see. It is not impersonation or RBAC. The approval preview is session-only; the stored v1.0 approval exists in governance.');
  finalize(s);
}

// Slide 5
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'Judge-first product journey','The deployed app tells the business story before showing architecture.');
  const conflictShot=configAsset(config.screenshots.conflict);
  const trustedShot=configAsset(config.screenshots.trusted);
  if(hasUsableImage(conflictShot)) addScreenshotFrame(s,conflictShot,0.7,1.75,5.8,4.45,'Start Here - historical conflict');
  else addMockWindow(s,0.7,1.75,5.8,4.45,'Start Here - historical conflict','conflict');
  if(hasUsableImage(trustedShot)) addScreenshotFrame(s,trustedShot,6.83,1.75,5.8,4.45,'Trusted Enterprise Answer');
  else addMockWindow(s,6.83,1.75,5.8,4.45,'Trusted Enterprise Answer','trusted');
  s.addShape(pptx.ShapeType.chevron,{x:6.55,y:3.7,w:0.18,h:0.36,fill:{color:C.cyan},line:{color:C.cyan,transparency:100}});
  s.addText('Start with the bad state',{x:1.55,y:6.43,w:3.3,h:0.25,fontSize:12.5,bold:true,color:C.red,align:'center',margin:0});
  s.addText('End with the governed answer',{x:7.8,y:6.43,w:3.9,h:0.25,fontSize:12.5,bold:true,color:C.green,align:'center',margin:0});
  addNotes(s,'Replace these stylized mockups with final screenshots if desired: 01_conflict_scanner.png and 04_trusted_enterprise_v1.png. The deck remains understandable without them.');
  finalize(s);
}

// Slide 6
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'Snowflake-native architecture','Each layer has one responsibility and a deterministic validation gate.');
  s.addImage({path:path.join(ARCH,'snowflake_architecture.png'),...imageSizingContain(path.join(ARCH,'snowflake_architecture.png'),0.7,1.62,8.4,4.7)});
  const stack=[
    ['Semantic View','Only approved metrics are public',C.cyan],
    ['Cortex Analyst','Natural-language governed SQL',C.blue],
    ['Streamlit in Snowflake','No external app credential required',C.green],
    ['Evidence workflow','Citations + trusted boundary',C.purple],
    ['AUDIT','Release controls + limitations',C.amber],
  ];
  stack.forEach((d,i)=>{
    const y=1.72+i*0.92;
    s.addShape(pptx.ShapeType.roundRect,{x:9.35,y,w:3.18,h:0.68,fill:{color:C.navy2},line:{color:d[2],width:1.1}});
    s.addText(d[0],{x:9.57,y:y+0.13,w:1.08,h:0.2,fontSize:10.5,bold:true,color:d[2],margin:0});
    s.addText(d[1],{x:10.76,y:y+0.11,w:1.52,h:0.33,fontSize:7.8,color:C.text,margin:0});
  });
  s.addText('RAW → CORE → GOVERNANCE → SEMANTIC → APP → AUDIT',{x:1.1,y:6.55,w:11.2,h:0.3,fontSize:15,bold:true,color:C.ice,align:'center',margin:0});
  addNotes(s,'Walk left to right. Emphasize that Streamlit presents governed results and does not reimplement formulas in Python.',[
    'Hackathon workshop transcript supplied by participant: synthetic supply-chain data → Semantic Views → verified queries → agent/orchestration → analyst app.',
  ]);
  finalize(s);
}

// Slide 7
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'Trust controls around every AI answer','ChainProof does not trust generated SQL merely because it compiles.');
  const controls=[
    ['Question scope','PO-specific vs enterprise aggregate',C.blue],
    ['Read-only SQL','One SELECT/WITH statement only',C.green],
    ['Semantic boundary','No RAW, CORE, or GOVERNANCE access',C.cyan],
    ['Version passport','Name, scope, owner, version, formula',C.purple],
    ['Evidence trust','Citations; injection fixture excluded',C.amber],
    ['Human authority','Advisor cannot approve or write',C.red],
  ];
  controls.forEach((d,i)=>{
    const col=i%3,row=Math.floor(i/3); const x=0.75+col*4.18,y=1.8+row*2.08;
    s.addShape(pptx.ShapeType.roundRect,{x,y,w:3.72,h:1.58,fill:{color:C.navy2},line:{color:d[2],width:1.4},shadow:safeOuterShadow('000000',0.16,45,1.5,0.8)});
    s.addShape(pptx.ShapeType.ellipse,{x:x+0.18,y:y+0.18,w:0.48,h:0.48,fill:{color:d[2],transparency:78},line:{color:d[2],width:1.1}});
    s.addText(String(i+1),{x:x+0.18,y:y+0.31,w:0.48,h:0.15,fontSize:10,bold:true,color:d[2],align:'center',margin:0});
    s.addText(d[0],{x:x+0.82,y:y+0.18,w:2.45,h:0.25,fontSize:13,bold:true,color:C.white,margin:0});
    s.addText(d[1],{x:x+0.25,y:y+0.82,w:3.15,h:0.42,fontSize:9.4,color:C.text,align:'center',margin:0});
  });
  s.addShape(pptx.ShapeType.roundRect,{x:1.25,y:6.15,w:10.8,h:0.62,fill:{color:'0B2438'},line:{color:C.line,width:1}});
  s.addText('Fail visibly. Preserve the approved formula. Never fabricate a capability or answer.',{x:1.55,y:6.36,w:10.2,h:0.2,fontSize:12.5,bold:true,color:C.cyan,align:'center',margin:0});
  addNotes(s,'Highlight the scope defect that Part 8R fixed: PO-5001 must return 85%, while enterprise aggregate intentionally returns 288/555 = 51.9%.');
  finalize(s);
}

// Slide 8
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'Evidence and operational impact','The governed number is explainable and connected to a concrete business action.');
  const evidenceShot=configAsset(config.screenshots.evidence);
  if(hasUsableImage(evidenceShot)) addScreenshotFrame(s,evidenceShot,0.65,1.75,5.85,4.65,'Evidence-backed review');
  else addMockWindow(s,0.65,1.75,5.85,4.65,'Evidence-backed review','evidence');

  s.addShape(pptx.ShapeType.roundRect,{x:6.86,y:1.75,w:5.8,h:4.65,fill:{color:C.navy2},line:{color:C.amber,width:1.4},shadow:safeOuterShadow('000000',0.2,45,2,1)});
  s.addText('PO-5001 business impact',{x:7.15,y:2.02,w:5.2,h:0.3,fontSize:15,bold:true,color:C.white,align:'center',margin:0});
  s.addText('Enterprise Supplier Fill Rate',{x:7.15,y:2.42,w:5.2,h:0.22,fontSize:10.5,color:C.text,align:'center',margin:0});
  s.addText('85%',{x:7.25,y:2.86,w:2.15,h:0.64,fontSize:38,bold:true,color:C.amber,align:'center',margin:0});
  s.addText('against 90% threshold',{x:7.25,y:3.5,w:2.15,h:0.2,fontSize:9.2,color:C.text,align:'center',margin:0});
  s.addShape(pptx.ShapeType.roundRect,{x:9.72,y:2.78,w:2.3,h:0.9,fill:{color:'351D24'},line:{color:C.red,width:1.1}});
  s.addText('15 units',{x:9.9,y:2.98,w:1.94,h:0.28,fontSize:18,bold:true,color:C.red,align:'center',margin:0});
  s.addText('supplier shortfall',{x:9.9,y:3.33,w:1.94,h:0.16,fontSize:8.7,color:C.text,align:'center',margin:0});

  const impacts=[
    ['Procurement','15 acceptable units short by original PO date',C.red],
    ['Logistics','10 units arrived after carrier commitment',C.amber],
    ['Planning','5 usable batteries short; up to 5 laptops at risk',C.cyan],
  ];
  impacts.forEach((d,i)=>{
    const y=4.02+i*0.56;
    s.addShape(pptx.ShapeType.roundRect,{x:7.22,y,w:5.1,h:0.43,fill:{color:'0B2438'},line:{color:d[2],width:0.9}});
    s.addText(d[0],{x:7.4,y:y+0.12,w:1.08,h:0.14,fontSize:8.8,bold:true,color:d[2],margin:0});
    s.addText(d[1],{x:8.55,y:y+0.1,w:3.5,h:0.2,fontSize:8.2,color:C.text,margin:0});
  });
  s.addShape(pptx.ShapeType.roundRect,{x:7.22,y:5.84,w:5.1,h:0.38,fill:{color:'172A21'},line:{color:C.green,width:1}});
  s.addText('Action: supplier escalation + carrier follow-up + production mitigation',{x:7.42,y:5.96,w:4.7,h:0.14,fontSize:8.6,bold:true,color:C.green,align:'center',margin:0});
  s.addText('One governed metric, three clearly separated operational consequences.',{x:1.0,y:6.7,w:11.3,h:0.28,fontSize:12,bold:true,color:C.muted,align:'center',margin:0});
  addNotes(s,'Show that the evidence is cited and the operational consequences are separated by responsibility. Do not describe a hypothetical candidate metric in the main demo.');
  finalize(s);
}

// Slide 9
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'Technical execution and validation','A twelve-part build with deterministic gates, real account evidence, and truthful limitations.');
  const nums=[['12','controlled build parts',C.blue],['6','Snowflake schemas',C.cyan],['4','approved public metrics',C.green],['6','verified questions',C.purple],['1','deployed Streamlit app',C.amber]];
  nums.forEach((d,i)=>{
    const x=0.68+i*2.52;
    s.addShape(pptx.ShapeType.roundRect,{x,y:1.75,w:2.18,h:1.25,fill:{color:C.navy2},line:{color:d[2],width:1.2}});
    s.addText(d[0],{x:x+0.12,y:1.98,w:1.94,h:0.48,fontSize:30,bold:true,color:d[2],align:'center',margin:0});
    s.addText(d[1],{x:x+0.15,y:2.55,w:1.88,h:0.2,fontSize:8.6,bold:true,color:C.text,align:'center',margin:0});
  });
  const gates=[
    ['RAW','files, rows, edge cases'],['CORE','types, lineage, quality'],['GOVERNANCE','versions, approval, activation'],
    ['SEMANTIC','metrics, relationships, verified SQL'],['APP','scope, persona, evidence, SQL safety'],['AUDIT','release controls and limitations']
  ];
  gates.forEach((d,i)=>{
    const col=i%2,row=Math.floor(i/2),x=0.85+col*6.25,y=3.45+row*0.87;
    s.addShape(pptx.ShapeType.roundRect,{x,y,w:5.65,h:0.62,fill:{color:'0B2438'},line:{color:C.line,width:0.8}});
    s.addText(d[0],{x:x+0.18,y:y+0.18,w:1.2,h:0.18,fontSize:10.5,bold:true,color:[C.blue,C.cyan,C.purple,C.green,C.amber,C.red][i],margin:0});
    s.addText(d[1],{x:x+1.42,y:y+0.17,w:3.9,h:0.2,fontSize:9.2,color:C.text,margin:0});
  });
  s.addShape(pptx.ShapeType.roundRect,{x:0.85,y:6.22,w:12.0,h:0.55,fill:{color:'241F12'},line:{color:C.amber,width:1}});
  s.addText('Known limitation: official Analyst batch evaluation needs account-level task privileges. Live Cortex Analyst and deterministic tests passed.',{x:1.1,y:6.41,w:11.5,h:0.18,fontSize:10.2,bold:true,color:C.amber,align:'center',margin:0});
  addNotes(s,'Do not claim an official evaluation score. Explain that only the account-level batch automation was blocked; live Cortex Analyst questions and direct semantic tests work.',[
    'https://coco-cli.yourstory.com/hackathon - evaluation rubric: real-world relevance 30%, technical execution 40%, solution completeness 30%.',
  ]);
  finalize(s);
}

// Slide 10
{
  const s=pptx.addSlide('CHAINPROOF_MASTER'); addTitle(s,'Why ChainProof is different','It governs metric disagreement - the gap before a normal semantic layer can help.');
  const rows=[
    ['BI dashboard','Displays configured KPIs','Detects conflicting KPI meaning'],
    ['Data catalog','Documents names and owners','Executes formulas and compares impact'],
    ['Semantic layer','Publishes agreed definitions','Governs disagreement before agreement'],
    ['Generic AI copilot','Answers with available metadata','Refuses ambiguity until governed'],
    ['Metric store','Centralizes formulas','Preserves conflict, approval, activation, rollback'],
  ];
  s.addShape(pptx.ShapeType.roundRect,{x:0.72,y:1.7,w:11.9,h:4.8,fill:{color:C.navy2},line:{color:C.line,width:1}});
  s.addText('Category',{x:0.95,y:1.98,w:2.0,h:0.25,fontSize:11,bold:true,color:C.muted,margin:0});
  s.addText('Typical capability',{x:3.05,y:1.98,w:3.65,h:0.25,fontSize:11,bold:true,color:C.muted,margin:0});
  s.addText('ChainProof addition',{x:7.02,y:1.98,w:4.75,h:0.25,fontSize:11,bold:true,color:C.cyan,margin:0});
  s.addShape(pptx.ShapeType.line,{x:0.94,y:2.35,w:10.9,h:0,line:{color:C.cyan,width:1.2}});
  rows.forEach((r,i)=>{
    const y=2.55+i*0.72;
    s.addText(r[0],{x:0.95,y,w:1.9,h:0.22,fontSize:10.2,bold:true,color:C.white,margin:0});
    s.addText(r[1],{x:3.05,y,w:3.55,h:0.3,fontSize:9.2,color:C.text,margin:0});
    s.addText(r[2],{x:7.02,y,w:4.55,h:0.3,fontSize:9.2,bold:true,color:C.green,margin:0});
    if(i<rows.length-1) s.addShape(pptx.ShapeType.line,{x:0.95,y:y+0.48,w:10.8,h:0,line:{color:C.line,width:0.6}});
  });
  s.addText('Business value: fewer conflicting reports, faster reconciliation, stronger supplier accountability, and auditable AI answers.',{x:1.05,y:6.75,w:11.15,h:0.25,fontSize:12.3,bold:true,color:C.ice,align:'center',margin:0});
  addNotes(s,'Use the comparison to prevent judges from categorizing ChainProof as a dashboard, catalog, or generic chat interface.');
  finalize(s);
}

// Slide 11
{
  const s=pptx.addSlide('CHAINPROOF_MASTER');
  s.addImage({path:path.join(ARCH,'chainproof_logo.png'),...imageSizingContain(path.join(ARCH,'chainproof_logo.png'),0.75,0.8,1.25,1.25)});
  s.addText('ChainProof',{x:2.15,y:0.92,w:4.2,h:0.6,fontSize:31,bold:true,color:C.white,margin:0});
  s.addText('Prevents AI from confidently answering the wrong KPI.',{x:0.9,y:2.16,w:11.55,h:0.58,fontSize:25,bold:true,color:C.ice,align:'center',margin:0});
  s.addShape(pptx.ShapeType.roundRect,{x:1.2,y:3.05,w:10.95,h:1.38,fill:{color:C.navy2},line:{color:C.green,width:1.6},shadow:safeOuterShadow('000000',0.2,45,2,1)});
  s.addText('One KPI name. Three valid calculations. One governed enterprise answer.',{x:1.55,y:3.46,w:10.25,h:0.48,fontSize:20,bold:true,color:C.green,align:'center',margin:0});
  const links=[
    ['GitHub',config.github_url,C.cyan],
    ['Live app',config.app_url,C.green],
    ['Walkthrough',config.video_url,C.purple],
  ];
  links.forEach((d,i)=>{
    const y=5.05+i*0.48;
    s.addText(d[0],{x:2.05,y,w:1.4,h:0.2,fontSize:10.5,bold:true,color:d[2],margin:0});
    s.addText(d[1],{x:3.5,y,w:7.75,h:0.22,fontSize:9.4,color:C.text,margin:0,breakLine:false});
  });
  s.addText('Snowflake-native • CoCo CLI-assisted • Human governed • Evidence backed',{x:1.1,y:6.78,w:11.2,h:0.24,fontSize:11.5,bold:true,color:C.muted,align:'center',margin:0});
  addNotes(s,'Closing line: Semantic layers govern agreed metrics. ChainProof governs the disagreement that exists before agreement. The official submission expects a public repository, deployed prototype, and presentation.',[
    'Hackathon workshop transcript supplied by participant: public GitHub, deployed link, working prototype, and presentation are requested.',
    'https://coco-cli.yourstory.com/hackathon - end-to-end deployable system and evaluation rubric.'
  ]);
  finalize(s);
}

const outPath = path.resolve(ROOT, 'submission/ChainProof_Hackathon_Presentation.pptx');
pptx.writeFile({ fileName: outPath });
console.log(`Wrote ${outPath}`);
