const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const OUT = path.resolve(__dirname, '../../docs/assets/architecture');
fs.mkdirSync(OUT, { recursive: true });

const C = {
  navy: '#071B2E',
  navy2: '#0D2941',
  blue: '#2E75FF',
  cyan: '#32D5FF',
  ice: '#EAF8FF',
  green: '#34D399',
  amber: '#F5B84B',
  red: '#FF6B6B',
  white: '#FFFFFF',
  text: '#DCEBFA',
  muted: '#89A5BE',
  line: '#2A4963',
  purple: '#9B8AFB'
};

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
function txt(x,y,text,size=28,weight=500,fill=C.text,anchor='middle') {
  return `<text x="${x}" y="${y}" font-family="Inter, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}">${esc(text)}</text>`;
}
function multiline(x,y,lines,size=24,weight=500,fill=C.text,anchor='middle',gap=1.18) {
  return `<text x="${x}" y="${y}" font-family="Inter, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}">`+
    lines.map((l,i)=>`<tspan x="${x}" dy="${i===0?0:size*gap}">${esc(l)}</tspan>`).join('')+`</text>`;
}
function box(x,y,w,h,fill=C.navy2,stroke=C.line,r=24,sw=2) {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
}
function arrow(x1,y1,x2,y2,color=C.cyan,width=5) {
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-width="${width}" stroke-linecap="round" marker-end="url(#arrow)"/>`;
}
function base(title, subtitle='') {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${C.navy}"/><stop offset="1" stop-color="#0A2238"/></linearGradient>
    <linearGradient id="accent" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${C.blue}"/><stop offset="1" stop-color="${C.cyan}"/></linearGradient>
    <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur in="SourceAlpha" stdDeviation="8"/><feOffset dx="0" dy="8" result="off"/><feComponentTransfer><feFuncA type="linear" slope="0.24"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 Z" fill="${C.cyan}"/></marker>
  </defs>
  <rect width="1600" height="900" fill="url(#bg)"/>
  <circle cx="1440" cy="80" r="220" fill="#0E3654" opacity="0.35"/>
  <circle cx="130" cy="850" r="260" fill="#0E3654" opacity="0.30"/>
  ${txt(80,78,title,42,750,C.white,'start')}
  ${subtitle?txt(80,120,subtitle,22,450,C.muted,'start'):''}
  <rect x="80" y="142" width="1440" height="3" rx="2" fill="url(#accent)" opacity="0.8"/>
  `;
}
function end() { return `</svg>`; }

function logoSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${C.blue}"/><stop offset="1" stop-color="${C.cyan}"/></linearGradient></defs>
  <rect width="512" height="512" rx="116" fill="${C.navy}"/>
  <path d="M256 68 L388 116 V236 C388 332 330 404 256 444 C182 404 124 332 124 236 V116 Z" fill="none" stroke="url(#g)" stroke-width="26"/>
  <path d="M186 206 C186 162 222 126 266 126 H310 C354 126 390 162 390 206 C390 250 354 286 310 286 H267" fill="none" stroke="${C.white}" stroke-width="28" stroke-linecap="round"/>
  <path d="M326 306 C326 350 290 386 246 386 H202 C158 386 122 350 122 306 C122 262 158 226 202 226 H245" fill="none" stroke="${C.white}" stroke-width="28" stroke-linecap="round"/>
  <circle cx="256" cy="256" r="28" fill="${C.green}"/>
  </svg>`;
}

function businessConflict() {
  let s = base('One KPI name. Three valid calculations.', 'ChainProof governs the disagreement before AI answers.');
  const cards = [
    {x:100,label:'Planning',metric:'Material Availability',v:'95%',c:C.blue},
    {x:520,label:'Procurement',metric:'Accepted Supplier Fill',v:'85%',c:C.green},
    {x:940,label:'Logistics',metric:'On-Time Arrival',v:'90%',c:C.amber},
  ];
  cards.forEach(d=>{
    s += `<g filter="url(#shadow)">${box(d.x,210,360,220,'#0D2941',d.c,28,3)}${txt(d.x+180,258,d.label,26,650,C.white)}${txt(d.x+180,305,d.metric,19,450,C.muted)}${txt(d.x+180,410,d.v,72,800,d.c)}</g>`;
  });
  s += arrow(280,455,620,560);
  s += arrow(700,455,700,560);
  s += arrow(1120,455,780,560);
  s += `<g filter="url(#shadow)">${box(500,550,400,115,'#152C42',C.red,28,3)}${txt(700,596,'METRIC CONFLICT',28,800,C.red)}${txt(700,635,'Same label, different meaning',20,500,C.text)}</g>`;
  s += arrow(900,608,1085,608);
  s += `<g filter="url(#shadow)">${box(1095,535,400,150,'#102F3C',C.green,28,3)}${txt(1295,582,'Enterprise v1.0',25,700,C.white)}${txt(1295,650,'85%',66,800,C.green)}</g>`;
  s += `<rect x="100" y="750" width="1395" height="70" rx="22" fill="#0B2438" stroke="${C.line}"/>`;
  s += txt(797,795,'Detect → Compare → Assess impact → Evidence → Approve → Publish → Verify',28,650,C.ice);
  return s+end();
}

function snowflakeArchitecture() {
  let s = base('Snowflake-native trust architecture', 'Operational facts, metric governance, AI analytics, and audit remain separated.');
  const layers = [
    {x:70,w:190,t:'RAW',sub:'Source exports',c:'#4D8DFF'},
    {x:285,w:190,t:'CORE',sub:'Canonical entities',c:'#3AB8FF'},
    {x:500,w:230,t:'GOVERNANCE',sub:'Versions & approval',c:'#9B8AFB'},
    {x:755,w:210,t:'SEMANTIC',sub:'Approved metrics',c:'#31D6C4'},
    {x:990,w:190,t:'APP',sub:'Streamlit & evidence',c:'#34D399'},
    {x:1205,w:190,t:'AUDIT',sub:'Controls & limits',c:'#F5B84B'},
  ];
  layers.forEach((d,i)=>{
    s += `<g filter="url(#shadow)">${box(d.x,270,d.w,250,'#0C263B',d.c,26,3)}${txt(d.x+d.w/2,340,d.t,26,800,d.c)}${multiline(d.x+d.w/2,390,d.sub.split(' '),19,500,C.text)}
      <circle cx="${d.x+d.w/2}" cy="490" r="34" fill="${d.c}" opacity="0.18" stroke="${d.c}" stroke-width="2"/>
      ${txt(d.x+d.w/2,500,String(i+1),25,800,d.c)}</g>`;
    if(i<layers.length-1) s += arrow(d.x+d.w+8,395,layers[i+1].x-8,395,d.c,4);
  });
  // top tools
  const tools = [
    {x:470,t:'Cortex Analyst',c:C.cyan},
    {x:750,t:'Verified queries',c:C.purple},
    {x:1030,t:'Streamlit in Snowflake',c:C.green},
  ];
  tools.forEach(d=> s += `<g>${box(d.x,180,250,64,'#0B2438',d.c,18,2)}${txt(d.x+125,222,d.t,18,650,C.white)}</g>`);
  s += arrow(595,244,850,270,C.cyan,3);
  s += arrow(875,244,860,270,C.purple,3);
  s += arrow(1155,244,1085,270,C.green,3);
  s += `<rect x="155" y="625" width="1290" height="112" rx="28" fill="#0B2438" stroke="${C.line}"/>`;
  s += txt(800,674,'Core rule',22,650,C.cyan);
  s += txt(800,716,'Only an approved metric version may become a trusted AI answer.',30,750,C.white);
  return s+end();
}

function questionSequence() {
  let s = base('How one ambiguous question becomes a trusted answer', 'Every hop preserves scope, version, and evidence.');
  const xs=[110,385,660,935,1210];
  const actors=[
    ['User','What is fill rate','for PO-5001?'],
    ['Streamlit','Scope + SQL','safety gate'],
    ['Cortex Analyst','Natural language','to governed SQL'],
    ['Semantic View','Approved metric','v1.0'],
    ['CORE evidence','85 accepted','/ 100 ordered'],
  ];
  actors.forEach((a,i)=>{
    const c=[C.blue,C.green,C.cyan,C.purple,C.amber][i];
    s += `<g filter="url(#shadow)">${box(xs[i],205,210,130,'#0D2941',c,24,3)}${txt(xs[i]+105,250,a[0],21,750,c)}${txt(xs[i]+105,288,a[1],17,500,C.white)}${txt(xs[i]+105,314,a[2],17,500,C.white)}</g>`;
    s += `<line x1="${xs[i]+105}" y1="335" x2="${xs[i]+105}" y2="700" stroke="${C.line}" stroke-width="2" stroke-dasharray="8 8"/>`;
  });
  const rows=[
    {y:390,from:0,to:1,t:'Question + selected PO scope'},
    {y:460,from:1,to:2,t:'Semantic View + explicit interpretation'},
    {y:530,from:2,to:3,t:'Read-only generated SQL'},
    {y:600,from:3,to:4,t:'Resolve approved version and facts'},
    {y:670,from:4,to:0,t:'Enterprise v1.0 = 85% + evidence'},
  ];
  rows.forEach((r,idx)=>{
    const x1=xs[r.from]+105, x2=xs[r.to]+105;
    const color=idx===4?C.green:C.cyan;
    s += `<line x1="${x1}" y1="${r.y}" x2="${x2}" y2="${r.y}" stroke="${color}" stroke-width="4" marker-end="url(#arrow)"/>`;
    s += txt((x1+x2)/2,r.y-12,r.t,17,550,idx===4?C.green:C.text);
  });
  return s+end();
}

function metricLifecycle() {
  let s=base('Immutable metric lifecycle', 'Rollback changes activation history - it does not rewrite an approved version.');
  const stages=[
    {x:90,t:'Candidate',c:C.muted},
    {x:310,t:'Conflict',c:C.red},
    {x:530,t:'Reviewed',c:C.cyan},
    {x:750,t:'Approved',c:C.green},
    {x:970,t:'Active',c:C.blue},
    {x:1190,t:'Published',c:C.purple},
  ];
  stages.forEach((d,i)=>{
    s += `<g filter="url(#shadow)">${box(d.x,310,180,110,'#0D2941',d.c,24,3)}${txt(d.x+90,375,d.t,23,750,d.c)}</g>`;
    if(i<stages.length-1) s += arrow(d.x+185,365,stages[i+1].x-5,365,C.cyan,4);
  });
  s += `<g filter="url(#shadow)">${box(980,560,390,120,'#13283A',C.amber,24,3)}${txt(1175,604,'Withdraw / Reactivate',24,750,C.amber)}${txt(1175,646,'append a new activation event',19,500,C.white)}</g>`;
  s += `<path d="M1280 420 C1450 470 1450 540 1370 585" fill="none" stroke="${C.amber}" stroke-width="4" marker-end="url(#arrow)"/>`;
  s += `<path d="M980 620 C820 720 740 675 840 420" fill="none" stroke="${C.amber}" stroke-width="4" marker-end="url(#arrow)"/>`;
  s += `<rect x="220" y="735" width="1160" height="72" rx="24" fill="#0B2438" stroke="${C.line}"/>`;
  s += txt(800,780,'Metric identity stays stable. Versions and activation events remain auditable.',27,650,C.white);
  return s+end();
}

function evidenceWorkflow() {
  let s=base('Evidence-backed Data Steward review', 'Structured results and trusted policy passages meet in one review packet.');
  const left=[
    {y:210,t:'Governed metric result',sub:'Enterprise v1.0 = 85%',c:C.green},
    {y:350,t:'Supplier agreement',sub:'acceptable quantity + original date',c:C.blue},
    {y:490,t:'Carrier SLA',sub:'physical arrival commitment',c:C.cyan},
    {y:630,t:'Quality policy',sub:'accepted vs rejected quantity',c:C.purple},
  ];
  left.forEach(d=>{
    s += `<g>${box(90,d.y,390,95,'#0D2941',d.c,22,3)}${txt(285,d.y+38,d.t,21,700,d.c)}${txt(285,d.y+70,d.sub,17,450,C.white)}</g>`;
    s += arrow(485,d.y+47,690,450,d.c,4);
  });
  s += `<g filter="url(#shadow)">${box(690,330,390,245,'#102F3C',C.green,30,4)}${txt(885,390,'Data Steward',25,750,C.white)}${txt(885,430,'review packet',30,800,C.green)}${txt(885,485,'cited evidence',20,550,C.text)}${txt(885,520,'business impact',20,550,C.text)}${txt(885,555,'recommended contract',20,550,C.text)}</g>`;
  s += arrow(1085,452,1285,452,C.green,5);
  s += `<g filter="url(#shadow)">${box(1290,350,230,205,'#0D2941',C.amber,28,3)}${txt(1405,405,'Human decision',23,750,C.amber)}${txt(1405,455,'Approve',28,800,C.green)}${txt(1405,495,'Reject',22,650,C.red)}${txt(1405,530,'or request change',18,500,C.white)}</g>`;
  s += `<rect x="610" y="700" width="770" height="75" rx="22" fill="#0B2438" stroke="${C.red}"/>`;
  s += txt(995,747,'Untrusted document instructions are excluded from the trusted evidence source.',21,650,C.red);
  return s+end();
}

async function save(name, svg) {
  const svgPath=path.join(OUT, name+'.svg');
  const pngPath=path.join(OUT, name+'.png');
  fs.writeFileSync(svgPath, svg);
  await sharp(Buffer.from(svg)).png().toFile(pngPath);
  console.log('wrote', svgPath, pngPath);
}

(async()=>{
  await save('chainproof_logo', logoSvg());
  await save('business_conflict_lifecycle', businessConflict());
  await save('snowflake_architecture', snowflakeArchitecture());
  await save('question_sequence', questionSequence());
  await save('metric_version_lifecycle', metricLifecycle());
  await save('evidence_workflow', evidenceWorkflow());
})();
