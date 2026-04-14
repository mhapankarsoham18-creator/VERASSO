#!/usr/bin/env python3
"""
geography_cs_builder.py — Generates fully interactive, pixel-retro HTML5
educational simulations for Geography (24) and Computer Science (15).
Each file is self-contained, offline-first, with no external dependencies.
"""
import os, textwrap

BASE = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.join(BASE, "assets", "simulations")

def w(subdir, fname, html):
    d = os.path.join(SIM, subdir)
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, fname)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f"  OK: {subdir}/{fname}")

HEAD = lambda title, accent: f"""<!DOCTYPE html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>{title}</title>
<style>
*{{margin:0;padding:0;box-sizing:border-box}}
body{{background:#0a0a1a;color:#fff;font-family:'Courier New',monospace;overflow:hidden;touch-action:none}}
canvas{{display:block;width:100vw;height:100vh}}
.hud{{position:absolute;top:8px;left:8px;background:rgba(0,0,0,.88);padding:8px 12px;border:2px solid {accent};color:{accent};z-index:10;font-size:11px;max-width:260px;line-height:1.5}}
.ctrl{{position:absolute;bottom:12px;left:50%;transform:translateX(-50%);display:flex;gap:6px;z-index:10;flex-wrap:wrap;justify-content:center}}
.ctrl button{{background:#111;color:{accent};border:1px solid {accent};padding:7px 12px;font-family:inherit;font-size:11px;cursor:pointer;border-radius:2px}}
.ctrl button:active,.ctrl button.a{{background:{accent};color:#000}}
.info{{position:absolute;top:8px;right:8px;background:rgba(0,0,0,.88);padding:8px 12px;border:2px solid {accent};color:#ccc;z-index:10;font-size:10px;max-width:200px;line-height:1.4}}
</style></head><body>
"""

FOOT = "\n</body></html>"

# ─────────────────────────────────────────────
# GEOGRAPHY SIMULATIONS
# ─────────────────────────────────────────────
print("GEOGRAPHY:")

# 1. Terrain Engine — Perlin noise heightmap, drag to rotate, scroll to zoom
w("geography", "terrain-viewer.html", HEAD("Terrain Engine", "#00bcd4") + """
<div class="hud"><b>TERRAIN ENGINE</b><br>Drag to rotate | Scroll to zoom<div id="info">Altitude: 0m</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="seed()">NEW SEED</button>
<button onclick="toggleWater()">TOGGLE WATER</button>
<button onclick="toggleGrid()">GRID</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,grid=[],cols=80,rows=60,cellW,cellH,rot=0,zoom=1,showWater=true,showGrid=false;
let dragX=0,dragY=0,dragging=false;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight;cellW=W/cols;cellH=H/rows}
addEventListener('resize',resize);resize();

// Simple value noise
function noise(x,y){let n=Math.sin(x*12.9898+y*78.233)*43758.5453;return n-Math.floor(n)}
function smoothNoise(x,y){
  let ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy;
  let a=noise(ix,iy),b=noise(ix+1,iy),c_=noise(ix,iy+1),d=noise(ix+1,iy+1);
  let u=fx*fx*(3-2*fx),v=fy*fy*(3-2*fy);
  return a*(1-u)*(1-v)+b*u*(1-v)+c_*(1-u)*v+d*u*v;
}
function fbm(x,y){let v=0,a=0.5,f=1;for(let i=0;i<6;i++){v+=a*smoothNoise(x*f,y*f);f*=2;a*=0.5}return v}

let seedX=Math.random()*100,seedY=Math.random()*100;
function generateTerrain(){
  grid=[];
  for(let r=0;r<rows;r++){grid[r]=[];for(let c_=0;c_<cols;c_++){grid[r][c_]=fbm(c_*0.05+seedX,r*0.05+seedY)}}
}
function seed(){seedX=Math.random()*100;seedY=Math.random()*100;generateTerrain()}
function toggleWater(){showWater=!showWater}
function toggleGrid(){showGrid=!showGrid}
generateTerrain();

function getColor(v){
  if(showWater&&v<0.35)return `rgb(20,60,${Math.floor(120+v*200)})`;
  if(v<0.4)return `rgb(${Math.floor(194+v*40)},${Math.floor(178+v*30)},130)`;
  if(v<0.55)return `rgb(${Math.floor(40+v*80)},${Math.floor(120+v*150)},${Math.floor(30+v*60)})`;
  if(v<0.7)return `rgb(${Math.floor(80+v*60)},${Math.floor(100+v*40)},${Math.floor(40+v*30)})`;
  if(v<0.85)return `rgb(${Math.floor(100+v*50)},${Math.floor(80+v*40)},${Math.floor(60+v*30)})`;
  return `rgb(${Math.floor(200+v*55)},${Math.floor(200+v*55)},${Math.floor(210+v*45)})`;
}

c.addEventListener('pointerdown',e=>{dragging=true;dragX=e.clientX;dragY=e.clientY});
c.addEventListener('pointermove',e=>{
  if(!dragging)return;
  rot+=(e.clientX-dragX)*0.003;
  dragX=e.clientX;dragY=e.clientY;
  let cr=Math.floor(e.clientY/cellH),cc=Math.floor(e.clientX/cellW);
  if(grid[cr]&&grid[cr][cc])document.getElementById('info').textContent='Altitude: '+Math.floor(grid[cr][cc]*8848)+'m';
});
c.addEventListener('pointerup',()=>dragging=false);
c.addEventListener('wheel',e=>{zoom=Math.max(0.5,Math.min(3,zoom-e.deltaY*0.001))});

function draw(){
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  for(let r=0;r<rows;r++){for(let cc=0;cc<cols;cc++){
    let dx=cc-cols/2,v=grid[r][cc];
    let px=(cols/2+dx*Math.cos(rot))*cellW*zoom+(W/2-cols/2*cellW*zoom);
    let py=r*cellH*zoom;
    x.fillStyle=getColor(v);
    x.fillRect(px,py,cellW*zoom+1,cellH*zoom+1);
    if(showGrid){x.strokeStyle='rgba(255,255,255,0.08)';x.strokeRect(px,py,cellW*zoom,cellH*zoom)}
  }}
  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 2. Plate Tectonics — Interactive divergent/convergent plate sim
w("geography", "plate-tectonics.html", HEAD("Plate Tectonics", "#FF5722") + """
<div class="hud"><b>PLATE TECTONICS</b><br>Drag plates to see effects<div id="info">Mode: Convergent</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="setMode('convergent')" class="a">CONVERGENT</button>
<button onclick="setMode('divergent')">DIVERGENT</button>
<button onclick="setMode('transform')">TRANSFORM</button>
<button onclick="reset()">RESET</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,mode='convergent',plateL,plateR,speed=0,mountains=[],lava=[];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight;reset()}
addEventListener('resize',resize);resize();

function reset(){
  plateL={x:W*0.1,w:W*0.35,y:H*0.5};
  plateR={x:W*0.55,w:W*0.35,y:H*0.5};
  speed=0;mountains=[];lava=[];
}
function setMode(m){mode=m;reset();
  document.getElementById('info').textContent='Mode: '+m.charAt(0).toUpperCase()+m.slice(1);
  document.querySelectorAll('.ctrl button').forEach(b=>b.classList.remove('a'));
  event.target.classList.add('a');
}

let dragging=null,dragOff=0;
c.addEventListener('pointerdown',e=>{
  if(e.clientX<W/2){dragging='L';dragOff=e.clientX-plateL.x}
  else{dragging='R';dragOff=e.clientX-plateR.x}
});
c.addEventListener('pointermove',e=>{
  if(!dragging)return;
  if(dragging==='L')plateL.x=e.clientX-dragOff;
  else plateR.x=e.clientX-dragOff;
});
c.addEventListener('pointerup',()=>dragging=null);

function draw(){
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  // Mantle
  let grad=x.createLinearGradient(0,H*0.5,0,H);
  grad.addColorStop(0,'#8B0000');grad.addColorStop(1,'#FF4500');
  x.fillStyle=grad;x.fillRect(0,H*0.55,W,H*0.45);

  // Plates
  x.fillStyle='#5D4037';x.fillRect(plateL.x,plateL.y-40,plateL.w,40);
  x.fillStyle='#4E342E';x.fillRect(plateL.x,plateL.y-80,plateL.w,40);
  x.fillStyle='#6D4C41';x.fillRect(plateR.x,plateR.y-40,plateR.w,40);
  x.fillStyle='#5D4037';x.fillRect(plateR.x,plateR.y-80,plateR.w,40);

  // Labels
  x.fillStyle='#fff';x.font='bold 14px Courier';x.textAlign='center';
  x.fillText('PLATE A',plateL.x+plateL.w/2,plateL.y-50);
  x.fillText('PLATE B',plateR.x+plateR.w/2,plateR.y-50);

  let gap=plateR.x-(plateL.x+plateL.w);

  // Convergent — mountains grow when plates touch
  if(mode==='convergent'&&gap<30){
    let h=Math.min(200,(30-gap)*3);
    for(let i=0;i<5;i++){
      let mx=plateL.x+plateL.w-10+i*12;
      x.fillStyle='#795548';
      x.beginPath();x.moveTo(mx-15,plateL.y-80);x.lineTo(mx,plateL.y-80-h*(1-i*0.15));x.lineTo(mx+15,plateL.y-80);x.fill();
      // Snow caps
      if(h>100){x.fillStyle='#fff';x.beginPath();x.moveTo(mx-5,plateL.y-80-h*(1-i*0.15)+20);x.lineTo(mx,plateL.y-80-h*(1-i*0.15));x.lineTo(mx+5,plateL.y-80-h*(1-i*0.15)+20);x.fill()}
    }
    x.fillStyle='#FF5722';x.font='12px Courier';x.textAlign='center';
    x.fillText('⬆ MOUNTAIN FORMATION',W/2,plateL.y-80-h-10);
  }

  // Divergent — magma rises in gap
  if(mode==='divergent'&&gap>20){
    x.fillStyle='#FF4500';x.fillRect(plateL.x+plateL.w,plateL.y-40,gap,40);
    for(let i=0;i<8;i++){
      let ly=plateL.y-40-Math.random()*gap*2;
      x.fillStyle=`rgba(255,${100+Math.random()*100},0,${0.5+Math.random()*0.5})`;
      x.fillRect(plateL.x+plateL.w+Math.random()*gap,ly,4,4);
    }
    x.fillStyle='#FF5722';x.font='12px Courier';x.textAlign='center';
    x.fillText('⬆ MAGMA RISING — NEW CRUST',W/2,plateL.y-100);
  }

  // Transform — earthquake waves
  if(mode==='transform'){
    x.strokeStyle='rgba(255,200,0,0.6)';x.lineWidth=2;
    let boundary=plateL.x+plateL.w;
    for(let i=0;i<10;i++){
      x.beginPath();
      x.arc(boundary,plateL.y-40,10+i*15+Math.sin(Date.now()*0.005)*5,0,Math.PI*2);
      x.stroke();
    }
    x.fillStyle='#FFAB00';x.font='12px Courier';x.textAlign='center';
    x.fillText('⚡ EARTHQUAKE ZONE',W/2,plateL.y-120);
  }

  // Arrows
  x.fillStyle='rgba(255,255,255,0.3)';x.font='24px Courier';
  if(mode==='convergent'){x.fillText('→',plateL.x+plateL.w/2,plateL.y+30);x.fillText('←',plateR.x+plateR.w/2,plateR.y+30)}
  if(mode==='divergent'){x.fillText('←',plateL.x+plateL.w/2,plateL.y+30);x.fillText('→',plateR.x+plateR.w/2,plateR.y+30)}
  if(mode==='transform'){x.fillText('↑',plateL.x+plateL.w/2,plateL.y+30);x.fillText('↓',plateR.x+plateR.w/2,plateR.y+30)}

  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 3. Erosion Simulator — particle-based water erosion with user-placed emitters
w("geography", "erosion-simulator.html", HEAD("Erosion Simulator", "#4FC3F7") + """
<div class="hud"><b>EROSION SIM</b><br>Tap to place water sources<br>Long-press to add rock<div id="info">Particles: 0</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="clearAll()">CLEAR</button>
<button onclick="toggleRain()">RAIN</button>
<button onclick="toggleErosion()">EROSION: ON</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,terrain=[],particles=[],sources=[],raining=false,erosionOn=true,cols=120,rows=80;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight;initTerrain()}
addEventListener('resize',resize);resize();

function initTerrain(){
  terrain=[];
  for(let r=0;r<rows;r++){terrain[r]=[];for(let cc=0;cc<cols;cc++){
    terrain[r][cc]=0.3+0.4*Math.sin(cc*0.08)*Math.cos(r*0.06)+Math.random()*0.1;
  }}
}
function clearAll(){initTerrain();particles=[];sources=[]}
function toggleRain(){raining=!raining}
function toggleErosion(){erosionOn=!erosionOn;event.target.textContent='EROSION: '+(erosionOn?'ON':'OFF')}

c.addEventListener('pointerdown',e=>{
  let cc=Math.floor(e.clientX/(W/cols)),rr=Math.floor(e.clientY/(H/rows));
  sources.push({c:cc,r:rr,life:300});
});

function step(){
  // Spawn from sources
  sources.forEach(s=>{
    if(Math.random()<0.3)particles.push({x:s.c+Math.random()*2-1,y:s.r,vx:0,vy:0.5,sed:0});
  });
  // Rain
  if(raining&&Math.random()<0.4)particles.push({x:Math.random()*cols,y:0,vx:0,vy:0.3,sed:0});

  // Move particles
  for(let i=particles.length-1;i>=0;i--){
    let p=particles[i];
    let cr=Math.floor(p.y),cc=Math.floor(p.x);
    if(cr<0||cr>=rows-1||cc<0||cc>=cols-1){particles.splice(i,1);continue}

    // Flow downhill
    let h=terrain[cr][cc],hR=cc<cols-1?terrain[cr][cc+1]:h,hL=cc>0?terrain[cr][cc-1]:h;
    let hD=cr<rows-1?terrain[cr+1][cc]:h;
    p.vx+=(hL-hR)*0.5;p.vy+=(h-hD)*0.3+0.1;
    p.vx*=0.9;p.vy*=0.9;
    p.x+=p.vx;p.y+=p.vy;

    // Erode
    if(erosionOn&&terrain[cr][cc]>0.05){terrain[cr][cc]-=0.002;p.sed+=0.002}
    // Deposit
    if(p.sed>0.01&&Math.abs(p.vy)<0.15){terrain[cr][cc]+=p.sed*0.5;p.sed*=0.5}

    if(p.y>rows||p.x<0||p.x>cols)particles.splice(i,1);
  }
  document.getElementById('info').textContent='Particles: '+particles.length;
}

function draw(){
  step();
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cw=W/cols,ch=H/rows;

  for(let r=0;r<rows;r++)for(let cc=0;cc<cols;cc++){
    let v=terrain[r][cc];
    if(v<0.25)x.fillStyle=`rgb(20,${Math.floor(50+v*200)},${Math.floor(80+v*300)})`;
    else if(v<0.5)x.fillStyle=`rgb(${Math.floor(100+v*100)},${Math.floor(140+v*120)},${Math.floor(60+v*60)})`;
    else x.fillStyle=`rgb(${Math.floor(120+v*80)},${Math.floor(100+v*60)},${Math.floor(60+v*40)})`;
    x.fillRect(cc*cw,r*ch,cw+1,ch+1);
  }

  // Water particles
  x.fillStyle='rgba(100,180,255,0.8)';
  particles.forEach(p=>{x.fillRect(p.x*cw,p.y*ch,3,3)});

  // Sources
  x.fillStyle='#4FC3F7';
  sources.forEach(s=>{x.fillRect(s.c*cw-4,s.r*ch-4,8,8)});

  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 4. Climate Zones — Interactive earth with labeled zones + explanations
w("geography", "climate-zones.html", HEAD("Climate Zones", "#FF9800") + """
<div class="hud"><b>CLIMATE ZONES</b><br>Tap a zone to learn about it</div>
<div class="info" id="detail">Select a climate zone to see details.</div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,selected=-1;
const zones=[
  {name:'ARCTIC',yStart:0,yEnd:0.1,color:'#B3E5FC',desc:'Extreme cold year-round. Permafrost, tundra vegetation. Avg temp below -10°C. Home to polar bears, seals.'},
  {name:'SUBARCTIC',yStart:0.1,yEnd:0.2,color:'#81D4FA',desc:'Long cold winters, short cool summers. Taiga/boreal forests. Avg -5°C to 5°C. Coniferous forests dominate.'},
  {name:'TEMPERATE',yStart:0.2,yEnd:0.35,color:'#AED581',desc:'Four distinct seasons. Moderate rainfall. Avg 5°C to 20°C. Deciduous forests, agriculture zones.'},
  {name:'SUBTROPICAL',yStart:0.35,yEnd:0.45,color:'#FFD54F',desc:'Hot humid summers, mild winters. Avg 15°C to 25°C. Diverse ecosystems, citrus farming regions.'},
  {name:'TROPICAL',yStart:0.45,yEnd:0.55,color:'#FF8A65',desc:'Hot and wet year-round. Avg 25°C to 30°C. Rainforests, highest biodiversity on Earth. >2000mm rain/year.'},
  {name:'SUBTROPICAL (S)',yStart:0.55,yEnd:0.65,color:'#FFD54F',desc:'Southern hemisphere subtropical. Similar to northern counterpart. Mediterranean climates common.'},
  {name:'TEMPERATE (S)',yStart:0.65,yEnd:0.8,color:'#AED581',desc:'Southern temperate zone. New Zealand, Patagonia. Oceanic influence moderates temperatures.'},
  {name:'SUBARCTIC (S)',yStart:0.8,yEnd:0.9,color:'#81D4FA',desc:'Sub-Antarctic zone. Very few landmasses. Strong winds, cold ocean currents.'},
  {name:'ANTARCTIC',yStart:0.9,yEnd:1.0,color:'#B3E5FC',desc:'Coldest place on Earth. Ice sheets up to 4km thick. Avg -50°C. Penguins, krill, research stations.'},
];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}
addEventListener('resize',resize);resize();

c.addEventListener('pointerdown',e=>{
  let ny=e.clientY/H;
  for(let i=0;i<zones.length;i++){
    if(ny>=zones[i].yStart&&ny<zones[i].yEnd){selected=i;break}
  }
  if(selected>=0)document.getElementById('detail').innerHTML='<b>'+zones[selected].name+'</b><br>'+zones[selected].desc;
});

function draw(){
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  zones.forEach((z,i)=>{
    let y1=z.yStart*H,y2=z.yEnd*H;
    x.fillStyle=i===selected?'rgba(255,255,255,0.15)':'rgba(0,0,0,0)';
    x.fillRect(0,y1,W,y2-y1);
    x.fillStyle=z.color;x.globalAlpha=0.5;x.fillRect(0,y1,W,y2-y1);x.globalAlpha=1;
    // Label
    x.fillStyle='#fff';x.font='bold 13px Courier';x.textAlign='center';
    x.fillText(z.name,W/2,y1+(y2-y1)/2+5);
    // Latitude lines
    x.strokeStyle='rgba(255,255,255,0.2)';x.setLineDash([4,4]);
    x.beginPath();x.moveTo(0,y1);x.lineTo(W,y1);x.stroke();x.setLineDash([]);
    // Latitude label
    let lat=Math.round(90-z.yStart*180);
    x.fillStyle='#888';x.font='10px Courier';x.textAlign='left';
    x.fillText(lat+'°',5,y1+12);
  });
  // Sun indicator
  let sunY=H*0.5+Math.sin(Date.now()*0.001)*H*0.1;
  x.fillStyle='#FFC107';x.beginPath();x.arc(W-30,sunY,12,0,Math.PI*2);x.fill();
  x.fillStyle='#fff';x.font='10px Courier';x.textAlign='right';x.fillText('☀ SUN',W-10,sunY-18);
  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 5. Solar System Scale — draggable planets with info cards
w("geography", "solar-system-scale.html", HEAD("Solar System Scale", "#7C4DFF") + """
<div class="hud"><b>SOLAR SYSTEM SCALE</b><br>Scroll/drag to explore distances<div id="info">Tap a planet for info</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="scaleMode='size'" class="a">SIZE SCALE</button>
<button onclick="scaleMode='dist'">DISTANCE SCALE</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,camX=0,scaleMode='size';
const planets=[
  {name:'Sun',r:40,dist:0,color:'#FFC107',info:'Star. Diameter: 1,391,000 km. Surface temp: 5,500°C. Mass: 333,000x Earth.'},
  {name:'Mercury',r:3,dist:80,color:'#9E9E9E',info:'Smallest planet. Diameter: 4,879 km. No atmosphere. Temp: -180°C to 430°C.'},
  {name:'Venus',r:6,dist:140,color:'#FFB74D',info:'Hottest planet (462°C). Diameter: 12,104 km. Dense CO₂ atmosphere. Rotates backwards.'},
  {name:'Earth',r:6.5,dist:200,color:'#42A5F5',info:'Our home. Diameter: 12,742 km. Only known planet with life. 71% water surface.'},
  {name:'Mars',r:4,dist:280,color:'#E53935',info:'Red Planet. Diameter: 6,779 km. Olympus Mons: tallest volcano (21.9 km). Thin CO₂ atmosphere.'},
  {name:'Jupiter',r:22,dist:500,color:'#FFB74D',info:'Largest planet. Diameter: 139,820 km. Great Red Spot storm. 79+ moons. Gas giant.'},
  {name:'Saturn',r:18,dist:750,color:'#FDD835',info:'Famous rings. Diameter: 116,460 km. Less dense than water! 82+ moons. Titan has lakes.'},
  {name:'Uranus',r:12,dist:1000,color:'#80DEEA',info:'Ice giant. Diameter: 50,724 km. Rotates on its side (98° tilt). Very cold: -224°C.'},
  {name:'Neptune',r:11,dist:1250,color:'#42A5F5',info:'Windiest planet (2,100 km/h). Diameter: 49,244 km. Deep blue color from methane.'},
];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}
addEventListener('resize',resize);resize();

let dragging=false,lastX=0;
c.addEventListener('pointerdown',e=>{
  dragging=true;lastX=e.clientX;
  // Check planet click
  planets.forEach(p=>{
    let px=p.dist*3-camX+80;
    if(Math.abs(e.clientX-px)<p.r+10&&Math.abs(e.clientY-H/2)<p.r+10){
      document.getElementById('info').innerHTML='<b>'+p.name+'</b><br>'+p.info;
    }
  });
});
c.addEventListener('pointermove',e=>{if(dragging){camX-=(e.clientX-lastX);lastX=e.clientX}});
c.addEventListener('pointerup',()=>dragging=false);
c.addEventListener('wheel',e=>{camX+=e.deltaY*2});

function draw(){
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  // Stars
  for(let i=0;i<60;i++){x.fillStyle='rgba(255,255,255,'+Math.random()*0.5+')';x.fillRect(Math.random()*W,Math.random()*H,2,2)}
  // Orbit line
  x.strokeStyle='rgba(255,255,255,0.1)';x.beginPath();x.moveTo(0,H/2);x.lineTo(W*5,H/2);x.stroke();

  planets.forEach(p=>{
    let px=p.dist*3-camX+80,py=H/2;
    if(px<-60||px>W+60)return;
    // Glow
    let grd=x.createRadialGradient(px,py,0,px,py,p.r*2);
    grd.addColorStop(0,p.color+'44');grd.addColorStop(1,'transparent');
    x.fillStyle=grd;x.fillRect(px-p.r*2,py-p.r*2,p.r*4,p.r*4);
    // Planet
    x.fillStyle=p.color;x.beginPath();x.arc(px,py,p.r,0,Math.PI*2);x.fill();
    // Saturn rings
    if(p.name==='Saturn'){x.strokeStyle=p.color+'88';x.lineWidth=3;x.beginPath();x.ellipse(px,py,p.r*1.8,p.r*0.4,0,0,Math.PI*2);x.stroke();x.lineWidth=1}
    // Label
    x.fillStyle='#ccc';x.font='10px Courier';x.textAlign='center';x.fillText(p.name,px,py+p.r+14);
  });
  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 6. Compass Navigation
w("geography", "compass-navigation.html", HEAD("Compass Navigation", "#FF5252") + """
<div class="hud"><b>COMPASS</b><br>Drag the red needle to navigate<div id="info">Bearing: 0° N</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,angle=0,target=Math.random()*360;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}
addEventListener('resize',resize);resize();

let dragging=false;
c.addEventListener('pointerdown',()=>dragging=true);
c.addEventListener('pointermove',e=>{
  if(!dragging)return;
  let cx=W/2,cy=H/2;
  angle=Math.atan2(e.clientY-cy,e.clientX-cx)+Math.PI/2;
  let deg=((angle*180/Math.PI)%360+360)%360;
  let dir='N';
  if(deg>22.5&&deg<=67.5)dir='NE';else if(deg>67.5&&deg<=112.5)dir='E';
  else if(deg>112.5&&deg<=157.5)dir='SE';else if(deg>157.5&&deg<=202.5)dir='S';
  else if(deg>202.5&&deg<=247.5)dir='SW';else if(deg>247.5&&deg<=292.5)dir='W';
  else if(deg>292.5&&deg<=337.5)dir='NW';
  document.getElementById('info').textContent='Bearing: '+Math.round(deg)+'° '+dir;
});
c.addEventListener('pointerup',()=>dragging=false);

function draw(){
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cx=W/2,cy=H/2,r=Math.min(W,H)*0.35;

  // Compass ring
  x.strokeStyle='#444';x.lineWidth=8;x.beginPath();x.arc(cx,cy,r,0,Math.PI*2);x.stroke();
  x.strokeStyle='#666';x.lineWidth=2;x.beginPath();x.arc(cx,cy,r+8,0,Math.PI*2);x.stroke();

  // Cardinal Points
  const dirs=['N','E','S','W'];
  dirs.forEach((d,i)=>{
    let a=-Math.PI/2+i*Math.PI/2;
    x.fillStyle=d==='N'?'#FF5252':'#ccc';x.font='bold 20px Courier';x.textAlign='center';
    x.fillText(d,cx+Math.cos(a)*(r+25),cy+Math.sin(a)*(r+25)+7);
  });

  // Tick marks
  for(let i=0;i<360;i+=10){
    let a=(i-90)*Math.PI/180,len=i%30===0?15:8;
    x.strokeStyle=i%90===0?'#FF5252':'#555';x.lineWidth=i%30===0?2:1;
    x.beginPath();x.moveTo(cx+Math.cos(a)*(r-len),cy+Math.sin(a)*(r-len));
    x.lineTo(cx+Math.cos(a)*r,cy+Math.sin(a)*r);x.stroke();
  }

  // Needle
  x.save();x.translate(cx,cy);x.rotate(angle);
  // Red (north)
  x.fillStyle='#FF5252';x.beginPath();x.moveTo(0,-r*0.75);x.lineTo(-8,0);x.lineTo(8,0);x.fill();
  // White (south)
  x.fillStyle='#ccc';x.beginPath();x.moveTo(0,r*0.75);x.lineTo(-8,0);x.lineTo(8,0);x.fill();
  // Center pin
  x.fillStyle='#888';x.beginPath();x.arc(0,0,6,0,Math.PI*2);x.fill();
  x.restore();

  // Target bearing indicator
  let tA=(target-90)*Math.PI/180;
  x.fillStyle='#76FF03';x.beginPath();
  x.arc(cx+Math.cos(tA)*(r-25),cy+Math.sin(tA)*(r-25),5,0,Math.PI*2);x.fill();
  x.fillStyle='#76FF03';x.font='10px Courier';x.textAlign='center';
  x.fillText('TARGET: '+Math.round(target)+'°',cx,cy+r+50);

  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 7. Time Zones — draggable slider
w("geography", "time-zones.html", HEAD("Time Zones", "#FFC107") + """
<div class="hud"><b>WORLD TIME ZONES</b><br>Drag the slider to change the hour<div id="info">UTC+0 | 12:00</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,utcOff=0;
const cities=[
  {name:'London',off:0},{name:'Paris',off:1},{name:'Cairo',off:2},{name:'Moscow',off:3},
  {name:'Dubai',off:4},{name:'Mumbai',off:5.5},{name:'Bangkok',off:7},{name:'Beijing',off:8},
  {name:'Tokyo',off:9},{name:'Sydney',off:11},{name:'Auckland',off:13},
  {name:'Anchorage',off:-9},{name:'Los Angeles',off:-8},{name:'Denver',off:-7},
  {name:'Chicago',off:-6},{name:'New York',off:-5},{name:'São Paulo',off:-3},
];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}
addEventListener('resize',resize);resize();

let dragging=false;
c.addEventListener('pointerdown',()=>dragging=true);
c.addEventListener('pointermove',e=>{
  if(!dragging)return;
  utcOff=Math.round(((e.clientX/W)*26-13)*2)/2; // -13 to +13 in 0.5 steps
  let h=12+utcOff;if(h<0)h+=24;if(h>=24)h-=24;
  let hStr=Math.floor(h).toString().padStart(2,'0')+':'+(h%1===0.5?'30':'00');
  document.getElementById('info').textContent='UTC'+(utcOff>=0?'+':'')+utcOff+' | '+hStr;
});
c.addEventListener('pointerup',()=>dragging=false);

function draw(){
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);

  // Day/night gradient
  let sunX=(utcOff+13)/26*W;
  let dayGrad=x.createLinearGradient(sunX-W*0.3,0,sunX+W*0.3,0);
  dayGrad.addColorStop(0,'rgba(255,200,50,0.05)');dayGrad.addColorStop(0.5,'rgba(255,200,50,0.15)');dayGrad.addColorStop(1,'rgba(255,200,50,0.05)');
  x.fillStyle=dayGrad;x.fillRect(0,0,W,H);

  // Time zone columns
  for(let i=-12;i<=13;i++){
    let lx=(i+13)/26*W;
    x.strokeStyle='rgba(255,255,255,0.1)';x.beginPath();x.moveTo(lx,40);x.lineTo(lx,H-60);x.stroke();
    x.fillStyle='#555';x.font='9px Courier';x.textAlign='center';
    x.fillText((i>=0?'+':'')+i,lx,35);
  }

  // Cities
  cities.forEach(city=>{
    let cx=(city.off+13)/26*W,cy=H*0.3+Math.random()*0;
    let localH=12+city.off;if(localH<0)localH+=24;if(localH>=24)localH-=24;
    let isDay=localH>=6&&localH<18;
    x.fillStyle=isDay?'#FFC107':'#5C6BC0';
    x.beginPath();x.arc(cx,H*0.45,6,0,Math.PI*2);x.fill();
    x.fillStyle='#fff';x.font='10px Courier';x.textAlign='center';
    x.fillText(city.name,cx,H*0.45+20);
    let hStr=Math.floor(localH).toString().padStart(2,'0')+':'+(localH%1===0.5?'30':'00');
    x.fillStyle=isDay?'#FFC107':'#7986CB';x.fillText(hStr,cx,H*0.45+32);
  });

  // Slider bar
  x.fillStyle='#333';x.fillRect(20,H-40,W-40,8);
  let knobX=(utcOff+13)/26*(W-40)+20;
  x.fillStyle='#FFC107';x.beginPath();x.arc(knobX,H-36,12,0,Math.PI*2);x.fill();
  x.fillStyle='#000';x.font='bold 9px Courier';x.textAlign='center';
  x.fillText((utcOff>=0?'+':'')+utcOff,knobX,H-33);

  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 8. Rock Cycle — interactive diagram puzzle
w("geography", "rock-cycle.html", HEAD("Rock Cycle", "#8D6E63") + """
<div class="hud"><b>ROCK CYCLE</b><br>Tap arrows to transform rocks<div id="info">Select a rock type</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,selected='';
const rocks=[
  {name:'IGNEOUS',x:0.5,y:0.15,color:'#E53935',desc:'Formed from cooled magma/lava. Examples: Granite, Basalt, Obsidian.'},
  {name:'SEDIMENTARY',x:0.15,y:0.7,color:'#FFB74D',desc:'Formed from compressed sediments over millions of years. Examples: Limestone, Sandstone, Shale.'},
  {name:'METAMORPHIC',x:0.85,y:0.7,color:'#7E57C2',desc:'Formed by heat & pressure transforming existing rocks. Examples: Marble, Slate, Quartzite.'},
  {name:'MAGMA',x:0.5,y:0.9,color:'#FF5722',desc:'Molten rock beneath Earth surface. Temperature: 700°C to 1300°C. Source of igneous rocks.'},
];
const arrows=[
  {from:'IGNEOUS',to:'SEDIMENTARY',label:'Weathering & Erosion',mx:0.25,my:0.35},
  {from:'SEDIMENTARY',to:'METAMORPHIC',label:'Heat & Pressure',mx:0.5,my:0.75},
  {from:'METAMORPHIC',to:'MAGMA',label:'Melting',mx:0.75,my:0.85},
  {from:'MAGMA',to:'IGNEOUS',label:'Cooling',mx:0.55,my:0.5},
  {from:'IGNEOUS',to:'METAMORPHIC',label:'Heat & Pressure',mx:0.75,my:0.35},
  {from:'SEDIMENTARY',to:'MAGMA',label:'Melting',mx:0.25,my:0.85},
];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}
addEventListener('resize',resize);resize();

c.addEventListener('pointerdown',e=>{
  rocks.forEach(r=>{
    let rx=r.x*W,ry=r.y*H;
    if(Math.abs(e.clientX-rx)<50&&Math.abs(e.clientY-ry)<30){
      selected=r.name;
      document.getElementById('info').innerHTML='<b>'+r.name+'</b><br>'+r.desc;
    }
  });
});

function draw(){
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);

  // Draw arrows
  arrows.forEach(a=>{
    let f=rocks.find(r=>r.name===a.from),t=rocks.find(r=>r.name===a.to);
    x.strokeStyle='rgba(255,255,255,0.3)';x.lineWidth=2;
    x.beginPath();x.moveTo(f.x*W,f.y*H);x.quadraticCurveTo(a.mx*W,a.my*H,t.x*W,t.y*H);x.stroke();
    x.fillStyle='#888';x.font='9px Courier';x.textAlign='center';
    x.fillText(a.label,a.mx*W,a.my*H);
  });

  // Draw rocks
  rocks.forEach(r=>{
    let rx=r.x*W,ry=r.y*H;
    let isSel=r.name===selected;
    // Glow
    if(isSel){x.shadowColor=r.color;x.shadowBlur=20}
    x.fillStyle=r.color;
    x.beginPath();x.ellipse(rx,ry,55,25,0,0,Math.PI*2);x.fill();
    x.shadowBlur=0;
    x.fillStyle='#fff';x.font='bold 12px Courier';x.textAlign='center';
    x.fillText(r.name,rx,ry+5);
  });

  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

# 9-23: Remaining geography sims (quick but functional)
for fname, title, accent, body_js in [
    ("earthquake-waves.html", "Seismic Waves", "#F44336", """
<div class="hud"><b>SEISMIC WAVES</b><br>Tap to create earthquake<div id="info">P-waves (blue) travel faster than S-waves (red)</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,waves=[];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
c.addEventListener('pointerdown',e=>{waves.push({x:e.clientX,y:e.clientY,rP:0,rS:0,t:0})});
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  // Earth layers
  x.fillStyle='#3E2723';x.fillRect(0,H*0.7,W,H*0.3);
  x.fillStyle='#4E342E';x.fillRect(0,H*0.5,W,H*0.2);
  x.fillStyle='#5D4037';x.fillRect(0,H*0.3,W,H*0.2);
  x.fillStyle='#2E7D32';x.fillRect(0,H*0.25,W,H*0.05);
  x.fillStyle='#fff';x.font='10px Courier';x.textAlign='right';
  x.fillText('CRUST',W-10,H*0.28);x.fillText('UPPER MANTLE',W-10,H*0.4);
  x.fillText('LOWER MANTLE',W-10,H*0.6);x.fillText('CORE',W-10,H*0.8);
  waves.forEach(w=>{w.rP+=4;w.rS+=2.5;w.t++;
    x.strokeStyle='rgba(66,165,245,'+(1-w.rP/500)+')';x.lineWidth=3;
    x.beginPath();x.arc(w.x,w.y,w.rP,0,Math.PI*2);x.stroke();
    x.strokeStyle='rgba(244,67,54,'+(1-w.rS/500)+')';
    x.beginPath();x.arc(w.x,w.y,w.rS,0,Math.PI*2);x.stroke();
  });
  waves=waves.filter(w=>w.rP<600);
  x.fillStyle='#fff';x.font='11px Courier';x.textAlign='left';
  x.fillText('🔵 P-WAVE (Primary, Compressional, Faster)',10,20);
  x.fillText('🔴 S-WAVE (Secondary, Shear, Slower)',10,35);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("biomes.html", "Biomes Explorer", "#4CAF50", """
<div class="hud"><b>BIOMES EXPLORER</b><br>Tap a biome tile to explore<div id="info">Select a biome</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,sel=-1;
const biomes=[
  {name:'TUNDRA',color:'#B3E5FC',temp:'-20°C to 0°C',rain:'<250mm',desc:'Permafrost, mosses, lichens. Arctic fox, snowy owl.',px:'❄'},
  {name:'TAIGA',color:'#2E7D32',temp:'-10°C to 15°C',rain:'300-900mm',desc:'Largest biome. Coniferous forests. Moose, wolves.',px:'🌲'},
  {name:'TEMPERATE FOREST',color:'#66BB6A',temp:'5°C to 20°C',rain:'750-1500mm',desc:'Four seasons. Deciduous trees. Deer, bears.',px:'🍂'},
  {name:'GRASSLAND',color:'#CDDC39',temp:'10°C to 30°C',rain:'250-750mm',desc:'Prairies, savannas. Bison, lions, elephants.',px:'🌾'},
  {name:'DESERT',color:'#FFB74D',temp:'20°C to 50°C',rain:'<250mm',desc:'Hot or cold. Cacti, camels, scorpions. 1/3 of land.',px:'🏜'},
  {name:'TROPICAL RAINFOREST',color:'#1B5E20',temp:'25°C to 30°C',rain:'>2000mm',desc:'Highest biodiversity. Jaguars, macaws, orchids.',px:'🌴'},
  {name:'SAVANNA',color:'#8BC34A',temp:'20°C to 30°C',rain:'500-1500mm',desc:'Wet/dry seasons. Grasslands with scattered trees.',px:'🦁'},
  {name:'OCEAN',color:'#0277BD',temp:'-2°C to 30°C',rain:'N/A',desc:'71% of Earth. Coral reefs, whales, plankton.',px:'🌊'},
];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
c.addEventListener('pointerdown',e=>{
  let cols=2,rows=4,cw=W/cols,ch=(H-80)/rows;
  let cc=Math.floor(e.clientX/cw),rr=Math.floor((e.clientY-40)/ch);
  let idx=rr*cols+cc;if(idx>=0&&idx<biomes.length){sel=idx;
    document.getElementById('info').innerHTML='<b>'+biomes[idx].name+'</b><br>Temp: '+biomes[idx].temp+'<br>Rain: '+biomes[idx].rain+'<br>'+biomes[idx].desc;
  }
});
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cols=2,rows=4,cw=W/cols,ch=(H-80)/rows;
  biomes.forEach((b,i)=>{
    let cc=i%cols,rr=Math.floor(i/cols);
    let bx=cc*cw+4,by=rr*ch+44;
    x.fillStyle=i===sel?b.color:b.color+'44';
    x.fillRect(bx,by,cw-8,ch-8);
    x.strokeStyle=i===sel?'#fff':b.color;x.lineWidth=2;x.strokeRect(bx,by,cw-8,ch-8);
    x.font='28px serif';x.textAlign='center';x.fillText(b.px,bx+cw/2-4,by+ch/2-5);
    x.fillStyle='#fff';x.font='bold 11px Courier';x.fillText(b.name,bx+cw/2-4,by+ch/2+18);
  });
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("continental-drift.html", "Continental Drift", "#795548", """
<div class="hud"><b>CONTINENTAL DRIFT</b><br>Use slider to travel through time<div id="info">250 Mya — Pangaea</div></div>
<canvas id="c"></canvas>
<div class="ctrl"><input type="range" id="slider" min="0" max="100" value="0" style="width:200px"></div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
const slider=document.getElementById('slider');
const continents=[
  {name:'N.America',baseX:0.25,baseY:0.35,driftX:-0.12,driftY:-0.05,w:80,h:50,color:'#4CAF50'},
  {name:'S.America',baseX:0.3,baseY:0.6,driftX:-0.08,driftY:0.05,w:50,h:70,color:'#8BC34A'},
  {name:'Africa',baseX:0.45,baseY:0.5,driftX:0.03,driftY:0.02,w:60,h:70,color:'#FF9800'},
  {name:'Europe',baseX:0.45,baseY:0.3,driftX:0.02,driftY:-0.05,w:50,h:35,color:'#2196F3'},
  {name:'Asia',baseX:0.55,baseY:0.3,driftX:0.1,driftY:-0.03,w:90,h:55,color:'#F44336'},
  {name:'Australia',baseX:0.6,baseY:0.7,driftX:0.15,driftY:0.08,w:50,h:35,color:'#9C27B0'},
  {name:'Antarctica',baseX:0.45,baseY:0.85,driftX:0.0,driftY:0.05,w:70,h:30,color:'#B3E5FC'},
];
const eras=['250 Mya — Pangaea','200 Mya — Laurasia/Gondwana','150 Mya — Jurassic','100 Mya — Cretaceous','50 Mya — Cenozoic','Present Day'];
slider.addEventListener('input',()=>{
  let i=Math.floor(slider.value/20);if(i>=eras.length)i=eras.length-1;
  document.getElementById('info').textContent=eras[i];
});
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  // Ocean
  x.fillStyle='#0D47A1';x.fillRect(0,0,W,H);
  let t=slider.value/100;
  continents.forEach(ct=>{
    let cx=(ct.baseX+ct.driftX*t)*W,cy=(ct.baseY+ct.driftY*t)*H;
    x.fillStyle=ct.color;
    x.beginPath();x.ellipse(cx,cy,ct.w*0.7,ct.h*0.5,0,0,Math.PI*2);x.fill();
    x.fillStyle='#fff';x.font='bold 10px Courier';x.textAlign='center';x.fillText(ct.name,cx,cy+4);
  });
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("river-delta.html", "River Delta Formation", "#26C6DA", """
<div class="hud"><b>RIVER DELTA</b><br>Watch sediment deposit at the river mouth<div id="info">Tap to add sediment flow</div></div>
<canvas id="c"></canvas>
<div class="ctrl"><button onclick="speed=speed===1?3:1">SPEED: 1x</button><button onclick="particles=[]">RESET</button></div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,particles=[],deposits=[],speed=1;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
c.addEventListener('pointerdown',e=>{for(let i=0;i<20;i++)particles.push({x:W*0.5,y:0,vx:(Math.random()-0.5)*2,vy:1+Math.random(),sed:0.8+Math.random()*0.5})});
function step(){
  for(let s=0;s<speed;s++){
    if(Math.random()<0.3)particles.push({x:W*0.5+(Math.random()-0.5)*40,y:0,vx:(Math.random()-0.5)*1.5,vy:1.5+Math.random(),sed:0.5+Math.random()*0.5});
    for(let i=particles.length-1;i>=0;i--){
      let p=particles[i];
      p.x+=p.vx;p.y+=p.vy;p.vy*=0.99;p.vx+=(Math.random()-0.5)*0.3;
      // Spread at delta mouth
      if(p.y>H*0.6){p.vx+=(Math.random()-0.5)*0.8;p.vy*=0.95}
      // Deposit
      if(p.y>H*0.65&&Math.random()<0.05){
        deposits.push({x:p.x,y:p.y,r:2+Math.random()*3,c:p.sed});
        particles.splice(i,1);continue;
      }
      if(p.y>H||p.x<0||p.x>W)particles.splice(i,1);
    }
  }
}
function draw(){step();
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  // Water
  x.fillStyle='#0D47A1';x.fillRect(0,H*0.6,W,H*0.4);
  // Land
  x.fillStyle='#3E2723';x.fillRect(0,0,W*0.4,H*0.65);x.fillRect(W*0.6,0,W*0.4,H*0.65);
  // River channel
  x.fillStyle='#1565C0';x.fillRect(W*0.45,0,W*0.1,H*0.6);
  // Deposits
  deposits.forEach(d=>{x.fillStyle=`rgb(${Math.floor(139+d.c*40)},${Math.floor(119+d.c*30)},${Math.floor(80+d.c*20)})`;x.beginPath();x.arc(d.x,d.y,d.r,0,Math.PI*2);x.fill()});
  // Particles
  x.fillStyle='rgba(121,85,72,0.8)';particles.forEach(p=>{x.fillRect(p.x-1,p.y-1,3,3)});
  x.fillStyle='#fff';x.font='10px Courier';x.textAlign='center';
  x.fillText('SEDIMENT PARTICLES: '+particles.length+' | DEPOSITS: '+deposits.length,W/2,H-15);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("glacial-movement.html", "Glacial Movement", "#B3E5FC", """
<div class="hud"><b>GLACIAL MOVEMENT</b><br>Learn how glaciers shape terrain<div id="info">Glaciers move 1m to 30m per day. They carve U-shaped valleys, transport boulders (erratics), and deposit moraines.</div></div>
<canvas id="c"></canvas>
<div class="ctrl"><button onclick="temp-=5">COOL -5°C</button><button onclick="temp+=5">WARM +5°C</button></div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,glacierLen=0.3,temp=-10;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function draw(){
  // Temperature affects glacier
  if(temp<0)glacierLen=Math.min(0.8,glacierLen+0.001);
  else glacierLen=Math.max(0.05,glacierLen-0.002);

  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  // Mountain
  x.fillStyle='#5D4037';
  x.beginPath();x.moveTo(0,H);x.lineTo(W*0.3,H*0.1);x.lineTo(W,H*0.6);x.lineTo(W,H);x.fill();
  // Glacier
  let gEnd=W*0.3+glacierLen*W*0.7;
  x.fillStyle='rgba(179,229,252,0.7)';
  x.beginPath();x.moveTo(W*0.3,H*0.1);
  x.quadraticCurveTo(W*0.3+glacierLen*W*0.3,H*0.3,gEnd,H*0.5+glacierLen*H*0.1);
  x.lineTo(gEnd,H*0.6+glacierLen*H*0.05);
  x.quadraticCurveTo(W*0.3+glacierLen*W*0.3,H*0.45,W*0.3,H*0.2);x.fill();
  // Moraine
  x.fillStyle='#795548';
  for(let i=0;i<15;i++){x.fillRect(gEnd-10+Math.random()*20,H*0.5+Math.random()*30+glacierLen*H*0.05,5+Math.random()*8,4+Math.random()*5)}
  // U-valley scar
  x.strokeStyle='rgba(255,255,255,0.15)';x.lineWidth=3;
  x.beginPath();x.moveTo(W*0.3,H*0.2);x.quadraticCurveTo(gEnd*0.8,H*0.55,gEnd+50,H*0.65);x.stroke();
  // Info
  x.fillStyle='#fff';x.font='bold 14px Courier';x.textAlign='left';
  x.fillText('TEMP: '+temp+'°C',15,H-60);
  x.fillText('GLACIER LENGTH: '+Math.round(glacierLen*100)+'%',15,H-40);
  x.fillStyle='#B3E5FC';x.font='11px Courier';
  x.fillText(temp<0?'❄ ADVANCING — Ice accumulation > melt':'☀ RETREATING — Melt > accumulation',15,H-20);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("wind-patterns.html", "Global Wind Patterns", "#81D4FA", """
<div class="hud"><b>GLOBAL WIND PATTERNS</b><br>Interactive wind circulation cells<div id="info">Coriolis effect deflects winds</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,particles=[];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight;initParticles()}addEventListener('resize',resize);resize();
function initParticles(){particles=[];for(let i=0;i<200;i++)particles.push({x:Math.random()*W,y:Math.random()*H,age:Math.random()*100})}
const cells=[
  {name:'Polar Easterlies',y1:0,y2:0.17,dx:-1,color:'#B3E5FC'},
  {name:'Westerlies',y1:0.17,y2:0.33,dx:1.5,color:'#64B5F6'},
  {name:'NE Trade Winds',y1:0.33,y2:0.5,dx:-1.2,color:'#42A5F5'},
  {name:'SE Trade Winds',y1:0.5,y2:0.67,dx:-1.2,color:'#42A5F5'},
  {name:'Westerlies (S)',y1:0.67,y2:0.83,dx:1.5,color:'#64B5F6'},
  {name:'Polar Easterlies (S)',y1:0.83,y2:1,dx:-1,color:'#B3E5FC'},
];
function getCell(y){let ny=y/H;for(let c of cells)if(ny>=c.y1&&ny<c.y2)return c;return cells[0]}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  // Zone backgrounds
  cells.forEach(cl=>{x.fillStyle=cl.color+'22';x.fillRect(0,cl.y1*H,W,(cl.y2-cl.y1)*H);
    x.fillStyle=cl.color;x.font='10px Courier';x.textAlign='center';x.fillText(cl.name,W/2,cl.y1*H+15);
    x.strokeStyle=cl.color+'44';x.setLineDash([4,4]);x.beginPath();x.moveTo(0,cl.y1*H);x.lineTo(W,cl.y1*H);x.stroke();x.setLineDash([])});
  // Particles
  particles.forEach(p=>{let cl=getCell(p.y);p.x+=cl.dx+Math.random()*0.5-0.25;p.y+=Math.random()*0.4-0.2;p.age++;
    if(p.x>W)p.x=0;if(p.x<0)p.x=W;if(p.y>H)p.y=0;if(p.y<0)p.y=H;
    let a=Math.max(0,1-p.age/100);x.fillStyle=`rgba(255,255,255,${a})`;x.fillRect(p.x,p.y,2,2);
    if(p.age>100){p.age=0;p.x=Math.random()*W;p.y=Math.random()*H}
  });
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("tidal-simulator.html", "Tidal Simulator", "#0288D1", """
<div class="hud"><b>TIDAL SIMULATOR</b><br>Watch tides change with Moon position<div id="info">Drag the moon to see tides change</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,moonAngle=0;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
let dragging=false;
c.addEventListener('pointerdown',()=>dragging=true);
c.addEventListener('pointermove',e=>{if(dragging)moonAngle=Math.atan2(e.clientY-H/2,e.clientX-W/2)});
c.addEventListener('pointerup',()=>dragging=false);
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cx=W/2,cy=H/2,er=Math.min(W,H)*0.15;
  // Stars
  for(let i=0;i<30;i++){x.fillStyle='rgba(255,255,255,0.3)';x.fillRect(Math.random()*W,Math.random()*H,1,1)}
  // Earth
  x.fillStyle='#1565C0';x.beginPath();x.arc(cx,cy,er,0,Math.PI*2);x.fill();
  x.fillStyle='#2E7D32';x.beginPath();x.arc(cx-er*0.2,cy-er*0.1,er*0.3,0,Math.PI*2);x.fill();
  // Tidal bulge
  let bulgeX=Math.cos(moonAngle)*er*0.3,bulgeY=Math.sin(moonAngle)*er*0.3;
  x.fillStyle='rgba(66,165,245,0.5)';
  x.beginPath();x.ellipse(cx+bulgeX,cy+bulgeY,er*1.25,er*0.9,moonAngle,0,Math.PI*2);x.fill();
  x.beginPath();x.ellipse(cx-bulgeX,cy-bulgeY,er*1.2,er*0.85,moonAngle,0,Math.PI*2);x.fill();
  // Moon
  let mr=Math.min(W,H)*0.35;
  let mx=cx+Math.cos(moonAngle)*mr,my=cy+Math.sin(moonAngle)*mr;
  x.fillStyle='#E0E0E0';x.beginPath();x.arc(mx,my,18,0,Math.PI*2);x.fill();
  x.fillStyle='#BDBDBD';x.beginPath();x.arc(mx-5,my-5,4,0,Math.PI*2);x.fill();
  x.fillText('MOON',mx,my+30);
  // Labels
  x.fillStyle='#fff';x.font='10px Courier';x.textAlign='center';
  x.fillText('EARTH',cx,cy+er+15);
  x.fillText('High Tide ↑',cx+bulgeX*2.5,cy+bulgeY*2.5);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("seasons.html", "Seasons Simulator", "#FFC107", """
<div class="hud"><b>SEASONS</b><br>Drag Earth around the Sun<div id="info">Earth's 23.5° axial tilt causes seasons</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,earthAngle=0;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
let dragging=false;
c.addEventListener('pointerdown',()=>dragging=true);
c.addEventListener('pointermove',e=>{if(dragging)earthAngle=Math.atan2(e.clientY-H/2,e.clientX-W/2)});
c.addEventListener('pointerup',()=>dragging=false);
function getSeason(){let d=((earthAngle*180/Math.PI)%360+360)%360;
  if(d<90)return'SUMMER (N) / WINTER (S)';if(d<180)return'AUTUMN (N) / SPRING (S)';
  if(d<270)return'WINTER (N) / SUMMER (S)';return'SPRING (N) / AUTUMN (S)'}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cx=W/2,cy=H/2,orb=Math.min(W,H)*0.3;
  // Orbit
  x.strokeStyle='rgba(255,255,255,0.15)';x.lineWidth=1;x.beginPath();x.arc(cx,cy,orb,0,Math.PI*2);x.stroke();
  // Sun
  x.fillStyle='#FFC107';x.beginPath();x.arc(cx,cy,25,0,Math.PI*2);x.fill();
  let grd=x.createRadialGradient(cx,cy,20,cx,cy,60);grd.addColorStop(0,'rgba(255,193,7,0.3)');grd.addColorStop(1,'transparent');
  x.fillStyle=grd;x.beginPath();x.arc(cx,cy,60,0,Math.PI*2);x.fill();
  // Earth
  let ex=cx+Math.cos(earthAngle)*orb,ey=cy+Math.sin(earthAngle)*orb;
  x.fillStyle='#1565C0';x.beginPath();x.arc(ex,ey,14,0,Math.PI*2);x.fill();
  // Tilt axis
  x.strokeStyle='#fff';x.lineWidth=1;x.save();x.translate(ex,ey);x.rotate(23.5*Math.PI/180);
  x.beginPath();x.moveTo(0,-22);x.lineTo(0,22);x.stroke();
  x.fillStyle='#E53935';x.fillRect(-2,-22,4,3);x.restore();
  // Season label
  x.fillStyle='#FFC107';x.font='bold 14px Courier';x.textAlign='center';
  x.fillText(getSeason(),W/2,H-30);
  x.fillStyle='#888';x.font='11px Courier';
  x.fillText('Drag Earth around the Sun',W/2,H-12);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("aurora.html", "Aurora Borealis", "#76FF03", """
<div class="hud"><b>AURORA BOREALIS</b><br>Solar particles hit Earth's magnetic field<div id="info">Watch charged particles create light</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
let particles=[];
for(let i=0;i<150;i++)particles.push({x:Math.random()*1.5*W-W*0.25,y:H*0.2+Math.random()*H*0.3,vy:Math.random()*0.5,h:Math.random()*120+90,a:Math.random()});
function draw(){x.fillStyle='rgba(5,5,20,0.1)';x.fillRect(0,0,W,H);
  // Stars
  if(Math.random()<0.05){x.fillStyle='#fff';x.fillRect(Math.random()*W,Math.random()*H*0.5,1,1)}
  // Aurora curtains
  particles.forEach(p=>{
    p.x+=Math.sin(Date.now()*0.001+p.y*0.01)*0.5;
    p.a=0.3+0.3*Math.sin(Date.now()*0.002+p.x*0.01);
    let grd=x.createLinearGradient(p.x,p.y,p.x,p.y+H*0.4);
    grd.addColorStop(0,`hsla(${p.h},80%,60%,${p.a})`);
    grd.addColorStop(0.5,`hsla(${p.h+30},70%,50%,${p.a*0.5})`);
    grd.addColorStop(1,'transparent');
    x.fillStyle=grd;x.fillRect(p.x,p.y,3,H*0.4);
  });
  // Ground
  x.fillStyle='#1a1a2e';x.fillRect(0,H*0.75,W,H*0.25);
  // Trees silhouette
  for(let i=0;i<20;i++){let tx=i*W/20;x.fillStyle='#0a0a15';
    x.beginPath();x.moveTo(tx,H*0.75);x.lineTo(tx+8,H*0.6+Math.random()*10);x.lineTo(tx+16,H*0.75);x.fill()}
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("latitude-longitude.html", "Latitude & Longitude", "#26A69A", """
<div class="hud"><b>LAT/LON GRID</b><br>Tap anywhere to get coordinates<div id="info">Tap the globe</div></div>
<canvas id="c"></canvas>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,markerLat=0,markerLon=0,hasMarker=false;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
c.addEventListener('pointerdown',e=>{
  let cx=W/2,cy=H/2,r=Math.min(W,H)*0.35;
  let dx=e.clientX-cx,dy=e.clientY-cy;
  if(dx*dx+dy*dy<r*r){
    markerLat=(-dy/r*90).toFixed(1);markerLon=(dx/r*180).toFixed(1);hasMarker=true;
    document.getElementById('info').textContent='Lat: '+markerLat+'° | Lon: '+markerLon+'°';
  }
});
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cx=W/2,cy=H/2,r=Math.min(W,H)*0.35;
  // Globe
  x.fillStyle='#0D47A1';x.beginPath();x.arc(cx,cy,r,0,Math.PI*2);x.fill();
  // Grid lines
  for(let lat=-80;lat<=80;lat+=20){
    let y=cy-lat/90*r;
    x.strokeStyle=lat===0?'#F44336':'rgba(255,255,255,0.15)';x.lineWidth=lat===0?2:1;
    let halfW=Math.sqrt(r*r-(lat/90*r)*(lat/90*r));
    x.beginPath();x.moveTo(cx-halfW,y);x.lineTo(cx+halfW,y);x.stroke();
    x.fillStyle='#888';x.font='8px Courier';x.textAlign='right';x.fillText(lat+'°',cx-halfW-5,y+3);
  }
  for(let lon=-160;lon<=160;lon+=40){
    let xp=cx+lon/180*r;
    x.strokeStyle=lon===0?'#4CAF50':'rgba(255,255,255,0.15)';x.lineWidth=lon===0?2:1;
    x.beginPath();x.ellipse(xp,cy,Math.abs(lon/180)*r*0.1+2,r,0,0,Math.PI*2);x.stroke();
  }
  // Equator/Prime meridian labels
  x.fillStyle='#F44336';x.font='10px Courier';x.textAlign='left';x.fillText('EQUATOR (0°)',cx+r+5,cy+3);
  x.fillStyle='#4CAF50';x.fillText('PRIME MERIDIAN',cx+3,cy-r-5);
  // Marker
  if(hasMarker){
    let mx=cx+markerLon/180*r,my=cy-markerLat/90*r;
    x.fillStyle='#FF5252';x.beginPath();x.arc(mx,my,5,0,Math.PI*2);x.fill();
    x.fillStyle='#fff';x.font='10px Courier';x.textAlign='center';
    x.fillText(markerLat+'°, '+markerLon+'°',mx,my-10);
  }
  requestAnimationFrame(draw)}draw();
</script>"""),
]:
    w("geography", fname, HEAD(title, accent) + body_js + FOOT)


# Keep existing ocean-currents, weather, water-cycle, volcano, population-density
# as they were already generated. Only overwrite the ones that were broken.

# ─────────────────────────────────────────────
# COMPUTER SCIENCE SIMULATIONS (Interactive)
# ─────────────────────────────────────────────
print("\nCOMPUTER SCIENCE:")

# 1. Binary Counter — fully interactive with keyboard and tap
w("cs", "binary-counter.html", HEAD("Binary Counter", "#00e676") + """
<div class="hud"><b>BINARY COUNTER</b><br>Tap bits to toggle | Tap number to increment<div id="info">DEC: 0 | HEX: 0x00 | OCT: 000</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="num=0;updateInfo()">RESET</button>
<button onclick="num=(num+1)%256;updateInfo()">+1</button>
<button onclick="num=(num-1+256)%256;updateInfo()">-1</button>
<button onclick="num=Math.floor(Math.random()*256);updateInfo()">RANDOM</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,num=0;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function updateInfo(){document.getElementById('info').textContent=
  'DEC: '+num+' | HEX: 0x'+num.toString(16).toUpperCase().padStart(2,'0')+' | OCT: '+num.toString(8).padStart(3,'0')}
c.addEventListener('pointerdown',e=>{
  let bw=W/10;
  for(let i=0;i<8;i++){
    let bx=W/2-4*bw+i*bw+bw*0.1,by=H*0.3;
    if(e.clientX>bx&&e.clientX<bx+bw*0.8&&e.clientY>by&&e.clientY<by+bw*0.8){
      num^=(1<<(7-i));num=((num%256)+256)%256;updateInfo();return;
    }
  }
  // Tap on decimal number to increment
  if(e.clientY>H*0.55&&e.clientY<H*0.8){num=(num+1)%256;updateInfo()}
});
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let bin=num.toString(2).padStart(8,'0'),bw=W/10;
  for(let i=0;i<8;i++){
    let bx=W/2-4*bw+i*bw+bw*0.1,by=H*0.3;
    // Bit box
    x.fillStyle=bin[i]==='1'?'#00e676':'#1a1a2e';x.fillRect(bx,by,bw*0.8,bw*0.8);
    x.strokeStyle='#00e676';x.lineWidth=2;x.strokeRect(bx,by,bw*0.8,bw*0.8);
    // Bit value
    x.fillStyle='#fff';x.font='bold '+Math.floor(bw*0.45)+'px Courier';x.textAlign='center';
    x.fillText(bin[i],bx+bw*0.4,by+bw*0.55);
    // Power of 2 label
    x.fillStyle='#555';x.font='10px Courier';x.fillText(Math.pow(2,7-i).toString(),bx+bw*0.4,by+bw+15);
    // Bit position
    x.fillStyle='#333';x.font='9px Courier';x.fillText('bit '+i,bx+bw*0.4,by-8);
  }
  // Decimal display
  x.fillStyle='#00e676';x.font='bold 52px Courier';x.textAlign='center';x.fillText(num.toString(),W/2,H*0.7);
  x.fillStyle='#666';x.font='12px Courier';x.fillText('Tap bits to toggle | Tap number to increment',W/2,H*0.9);
  requestAnimationFrame(draw)}draw();
</script>""" + FOOT)

# 2. Sorting Visualizer — user picks algorithm, watches step-by-step
w("cs", "sorting-visualizer.html", HEAD("Sorting Algorithms", "#FF9800") + """
<div class="hud"><b>SORTING VISUALIZER</b><br>Pick an algorithm and watch it sort<div id="info">Algorithm: Bubble Sort | Comparisons: 0</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="setAlgo('bubble')" class="a">BUBBLE</button>
<button onclick="setAlgo('selection')">SELECT</button>
<button onclick="setAlgo('insertion')">INSERT</button>
<button onclick="setAlgo('quick')">QUICK</button>
<button onclick="shuffle()">SHUFFLE</button>
<button onclick="startSort()">▶ SORT</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H;
let arr=[],n=40,algo='bubble',sorting=false,comps=0,swaps=[],highlight=[-1,-1];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function shuffle(){arr=[];for(let i=0;i<n;i++)arr.push(Math.random());sorting=false;comps=0;highlight=[-1,-1]}
shuffle();

function setAlgo(a){algo=a;document.querySelectorAll('.ctrl button').forEach(b=>b.classList.remove('a'));event.target.classList.add('a');shuffle()}

async function startSort(){
  if(sorting)return;sorting=true;comps=0;
  if(algo==='bubble')await bubbleSort();
  else if(algo==='selection')await selectionSort();
  else if(algo==='insertion')await insertionSort();
  else if(algo==='quick')await quickSort(0,arr.length-1);
  sorting=false;highlight=[-1,-1];
}

function delay(ms){return new Promise(r=>setTimeout(r,ms))}
async function swap(i,j){let t=arr[i];arr[i]=arr[j];arr[j]=t;highlight=[i,j];comps++;
  document.getElementById('info').textContent='Algorithm: '+algo.toUpperCase()+' | Comparisons: '+comps;await delay(30)}

async function bubbleSort(){for(let i=0;i<arr.length;i++)for(let j=0;j<arr.length-i-1;j++){comps++;highlight=[j,j+1];if(arr[j]>arr[j+1])await swap(j,j+1);else await delay(10)}}
async function selectionSort(){for(let i=0;i<arr.length;i++){let m=i;for(let j=i+1;j<arr.length;j++){comps++;highlight=[m,j];if(arr[j]<arr[m])m=j;await delay(10)}if(m!==i)await swap(i,m)}}
async function insertionSort(){for(let i=1;i<arr.length;i++){let j=i;while(j>0&&arr[j-1]>arr[j]){await swap(j-1,j);j--}}}
async function quickSort(lo,hi){if(lo>=hi)return;let p=await partition(lo,hi);await quickSort(lo,p-1);await quickSort(p+1,hi)}
async function partition(lo,hi){let pivot=arr[hi],i=lo;for(let j=lo;j<hi;j++){comps++;highlight=[j,hi];if(arr[j]<pivot){await swap(i,j);i++}else await delay(10)}await swap(i,hi);return i}

function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let bw=W/arr.length;
  arr.forEach((v,i)=>{
    let h=v*(H-100);
    x.fillStyle=i===highlight[0]?'#FF5252':i===highlight[1]?'#4CAF50':'#FF9800';
    x.fillRect(i*bw+1,H-60-h,bw-2,h);
  });
  requestAnimationFrame(draw)}draw();
</script>""" + FOOT)

# 3. Pathfinding A* — user draws maze, sets start/end
w("cs", "pathfinding.html", HEAD("Pathfinding A*", "#00BCD4") + """
<div class="hud"><b>A* PATHFINDING</b><br>Draw walls → Set start/end → Run<div id="info">Draw walls, then tap RUN</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="mode='wall'" class="a">DRAW WALL</button>
<button onclick="mode='start'">SET START</button>
<button onclick="mode='end'">SET END</button>
<button onclick="runAStar()">▶ RUN</button>
<button onclick="clearGrid()">CLEAR</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H;
let cols=30,rows=20,grid=[],mode='wall',startC=null,endC=null,path=[],visited=[];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function clearGrid(){grid=[];for(let r=0;r<rows;r++){grid[r]=[];for(let cc=0;cc<cols;cc++)grid[r][cc]=0}startC=null;endC=null;path=[];visited=[]}
clearGrid();

let drawing=false;
c.addEventListener('pointerdown',e=>{drawing=true;handleClick(e)});
c.addEventListener('pointermove',e=>{if(drawing&&mode==='wall')handleClick(e)});
c.addEventListener('pointerup',()=>drawing=false);

function handleClick(e){
  let cw=W/cols,ch=(H-80)/rows;
  let cc=Math.floor(e.clientX/cw),rr=Math.floor((e.clientY-40)/ch);
  if(rr<0||rr>=rows||cc<0||cc>=cols)return;
  if(mode==='wall')grid[rr][cc]=grid[rr][cc]?0:1;
  else if(mode==='start'){startC={r:rr,c:cc};grid[rr][cc]=0}
  else if(mode==='end'){endC={r:rr,c:cc};grid[rr][cc]=0}
}

async function runAStar(){
  if(!startC||!endC){document.getElementById('info').textContent='Set START and END first!';return}
  path=[];visited=[];
  let open=[{r:startC.r,c:startC.c,g:0,h:0,f:0,parent:null}];
  let closed=new Set();
  function h(r,cc){return Math.abs(r-endC.r)+Math.abs(cc-endC.c)}
  while(open.length>0){
    open.sort((a,b)=>a.f-b.f);let cur=open.shift();
    let key=cur.r+','+cur.c;if(closed.has(key))continue;closed.add(key);
    visited.push({r:cur.r,c:cur.c});
    if(cur.r===endC.r&&cur.c===endC.c){
      let n=cur;while(n){path.push({r:n.r,c:n.c});n=n.parent}
      document.getElementById('info').textContent='Path found! Length: '+path.length+' | Visited: '+visited.length;return;
    }
    for(let[dr,dc]of[[-1,0],[1,0],[0,-1],[0,1]]){
      let nr=cur.r+dr,nc=cur.c+dc;
      if(nr<0||nr>=rows||nc<0||nc>=cols||grid[nr][nc]===1||closed.has(nr+','+nc))continue;
      let g=cur.g+1,hv=h(nr,nc);
      open.push({r:nr,c:nc,g:g,h:hv,f:g+hv,parent:cur});
    }
    await new Promise(r=>setTimeout(r,20));
  }
  document.getElementById('info').textContent='No path found!';
}

function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cw=W/cols,ch=(H-80)/rows;
  for(let r=0;r<rows;r++)for(let cc=0;cc<cols;cc++){
    let bx=cc*cw,by=r*ch+40;
    if(grid[r][cc])x.fillStyle='#444';
    else x.fillStyle='#111';
    x.fillRect(bx+1,by+1,cw-2,ch-2);
  }
  visited.forEach(v=>{x.fillStyle='rgba(0,188,212,0.3)';x.fillRect(v.c*cw+1,v.r*ch+41,cw-2,ch-2)});
  path.forEach(p=>{x.fillStyle='#00e676';x.fillRect(p.c*cw+1,p.r*ch+41,cw-2,ch-2)});
  if(startC){x.fillStyle='#4CAF50';x.fillRect(startC.c*cw+1,startC.r*ch+41,cw-2,ch-2)}
  if(endC){x.fillStyle='#F44336';x.fillRect(endC.c*cw+1,endC.r*ch+41,cw-2,ch-2)}
  requestAnimationFrame(draw)}draw();
</script>""" + FOOT)

# 4. Logic Gates — breadboard wiring
w("cs", "logic-gates.html", HEAD("Logic Gates", "#FF5252") + """
<div class="hud"><b>LOGIC GATES</b><br>Toggle inputs (A/B) to see outputs<div id="info">Select a gate type</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="gate='AND'" class="a">AND</button>
<button onclick="gate='OR'">OR</button>
<button onclick="gate='XOR'">XOR</button>
<button onclick="gate='NOT'">NOT</button>
<button onclick="gate='NAND'">NAND</button>
<button onclick="gate='NOR'">NOR</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,gate='AND',inA=0,inB=0;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function getOutput(){
  if(gate==='AND')return inA&inB;if(gate==='OR')return inA|inB;
  if(gate==='XOR')return inA^inB;if(gate==='NOT')return inA?0:1;
  if(gate==='NAND')return(inA&inB)?0:1;if(gate==='NOR')return(inA|inB)?0:1;return 0;
}
c.addEventListener('pointerdown',e=>{
  // Toggle input A
  if(e.clientY>H*0.3&&e.clientY<H*0.45&&e.clientX<W*0.3)inA=inA?0:1;
  // Toggle input B
  if(e.clientY>H*0.55&&e.clientY<H*0.7&&e.clientX<W*0.3)inB=inB?0:1;
});
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let out=getOutput();
  // Input A
  x.fillStyle=inA?'#00e676':'#333';x.fillRect(W*0.05,H*0.3,W*0.18,H*0.12);
  x.strokeStyle='#00e676';x.strokeRect(W*0.05,H*0.3,W*0.18,H*0.12);
  x.fillStyle='#fff';x.font='bold 20px Courier';x.textAlign='center';
  x.fillText('A = '+inA,W*0.14,H*0.38);
  // Input B
  if(gate!=='NOT'){
    x.fillStyle=inB?'#00e676':'#333';x.fillRect(W*0.05,H*0.55,W*0.18,H*0.12);
    x.strokeStyle='#00e676';x.strokeRect(W*0.05,H*0.55,W*0.18,H*0.12);
    x.fillStyle='#fff';x.fillText('B = '+inB,W*0.14,H*0.63);
  }
  // Gate body
  x.fillStyle='#222';x.strokeStyle='#FF5252';x.lineWidth=3;
  x.fillRect(W*0.35,H*0.35,W*0.3,H*0.3);x.strokeRect(W*0.35,H*0.35,W*0.3,H*0.3);
  x.fillStyle='#FF5252';x.font='bold 28px Courier';x.fillText(gate,W*0.5,H*0.53);
  // Wires
  x.strokeStyle=inA?'#00e676':'#555';x.lineWidth=3;
  x.beginPath();x.moveTo(W*0.23,H*0.36);x.lineTo(W*0.35,H*0.45);x.stroke();
  if(gate!=='NOT'){x.strokeStyle=inB?'#00e676':'#555';
    x.beginPath();x.moveTo(W*0.23,H*0.61);x.lineTo(W*0.35,H*0.55);x.stroke()}
  // Output wire
  x.strokeStyle=out?'#00e676':'#555';
  x.beginPath();x.moveTo(W*0.65,H*0.5);x.lineTo(W*0.8,H*0.5);x.stroke();
  // Output LED
  x.fillStyle=out?'#00e676':'#333';x.beginPath();x.arc(W*0.85,H*0.5,20,0,Math.PI*2);x.fill();
  x.strokeStyle='#00e676';x.beginPath();x.arc(W*0.85,H*0.5,20,0,Math.PI*2);x.stroke();
  x.fillStyle='#fff';x.font='bold 16px Courier';x.fillText('OUT='+out,W*0.85,H*0.5+5);
  // Truth table
  x.fillStyle='#888';x.font='11px Courier';x.textAlign='left';
  let ty=H*0.78;x.fillText('TRUTH TABLE:',W*0.3,ty);
  if(gate==='NOT'){x.fillText('A=0 → 1',W*0.3,ty+15);x.fillText('A=1 → 0',W*0.3,ty+28)}
  else{
    let vals=[[0,0],[0,1],[1,0],[1,1]];
    vals.forEach((v,i)=>{let r;
      if(gate==='AND')r=v[0]&v[1];else if(gate==='OR')r=v[0]|v[1];
      else if(gate==='XOR')r=v[0]^v[1];else if(gate==='NAND')r=(v[0]&v[1])?0:1;else r=(v[0]|v[1])?0:1;
      x.fillText('A='+v[0]+' B='+v[1]+' → '+r,W*0.3,ty+15+i*14);
    });
  }
  document.getElementById('info').textContent=gate+' Gate | A='+inA+(gate==='NOT'?'':' B='+inB)+' → OUT='+out;
  requestAnimationFrame(draw)}draw();
</script>""" + FOOT)

# 5-14: Remaining CS sims
for fname, title, accent, body_js in [
    ("stack-queue.html", "Stack & Queue", "#7C4DFF", """
<div class="hud"><b>STACK & QUEUE</b><br>Push/Pop to see LIFO vs FIFO<div id="info">Stack (LIFO) | Queue (FIFO)</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="pushItem()">PUSH / ENQUEUE</button>
<button onclick="popStack()">POP (Stack)</button>
<button onclick="dequeue()">DEQUEUE (Queue)</button>
<button onclick="stack=[];queue=[]">CLEAR</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,stack=[],queue=[],counter=1;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function pushItem(){let v=counter++;stack.push(v);queue.push(v)}
function popStack(){stack.pop()}
function dequeue(){queue.shift()}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let hw=W/2-20;
  // Stack (left)
  x.fillStyle='#fff';x.font='bold 14px Courier';x.textAlign='center';
  x.fillText('STACK (LIFO)',hw/2+10,30);
  stack.forEach((v,i)=>{
    let y=H-80-i*35;if(y<50)return;
    x.fillStyle='#7C4DFF';x.fillRect(30,y,hw-20,30);
    x.fillStyle='#fff';x.font='bold 14px Courier';x.fillText(v.toString(),hw/2+10,y+20);
  });
  x.strokeStyle='#7C4DFF';x.strokeRect(30,50,hw-20,H-130);
  x.fillStyle='#555';x.fillText('← POP from top',hw/2+10,45);
  // Queue (right)
  x.fillStyle='#fff';x.fillText('QUEUE (FIFO)',W-hw/2-10,30);
  queue.forEach((v,i)=>{
    let y=50+i*35;if(y>H-80)return;
    x.fillStyle='#00BCD4';x.fillRect(W-hw+10,y,hw-20,30);
    x.fillStyle='#fff';x.font='bold 14px Courier';x.fillText(v.toString(),W-hw/2-10,y+20);
  });
  x.strokeStyle='#00BCD4';x.strokeRect(W-hw+10,50,hw-20,H-130);
  x.fillStyle='#555';x.fillText('DEQUEUE from front →',W-hw/2-10,H-65);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("binary-tree.html", "Binary Search Tree", "#4CAF50", """
<div class="hud"><b>BST VISUALIZER</b><br>Type a number and insert it<div id="info">Insert numbers to build the tree</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<input type="number" id="val" value="50" style="width:60px;background:#111;color:#4CAF50;border:1px solid #4CAF50;padding:6px;font-family:inherit">
<button onclick="insert(+document.getElementById('val').value)">INSERT</button>
<button onclick="root=null">CLEAR</button>
<button onclick="for(let i=0;i<5;i++)insert(Math.floor(Math.random()*100))">RANDOM 5</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,root=null;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
class Node{constructor(v){this.v=v;this.l=null;this.r=null}}
function insert(v){if(!root){root=new Node(v);return}let n=root;while(true){if(v<n.v){if(!n.l){n.l=new Node(v);return}n=n.l}else{if(!n.r){n.r=new Node(v);return}n=n.r}}}
function drawNode(node,cx,cy,spread,depth){
  if(!node)return;
  if(node.l){x.strokeStyle='#4CAF50';x.lineWidth=1;x.beginPath();x.moveTo(cx,cy);x.lineTo(cx-spread,cy+60);x.stroke();drawNode(node.l,cx-spread,cy+60,spread/2,depth+1)}
  if(node.r){x.strokeStyle='#4CAF50';x.lineWidth=1;x.beginPath();x.moveTo(cx,cy);x.lineTo(cx+spread,cy+60);x.stroke();drawNode(node.r,cx+spread,cy+60,spread/2,depth+1)}
  x.fillStyle='#111';x.beginPath();x.arc(cx,cy,18,0,Math.PI*2);x.fill();
  x.strokeStyle='#4CAF50';x.lineWidth=2;x.beginPath();x.arc(cx,cy,18,0,Math.PI*2);x.stroke();
  x.fillStyle='#fff';x.font='bold 12px Courier';x.textAlign='center';x.fillText(node.v.toString(),cx,cy+5);
}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);if(root)drawNode(root,W/2,60,W/5,0);requestAnimationFrame(draw)}draw();
</script>"""),
    ("cpu-pipeline.html", "CPU Pipeline", "#E91E63", """
<div class="hud"><b>CPU PIPELINE</b><br>Watch instructions flow through stages<div id="info">5-stage RISC pipeline</div></div>
<canvas id="c"></canvas>
<div class="ctrl"><button onclick="addInstr()">ADD INSTRUCTION</button><button onclick="instructions=[];tick=0">RESET</button></div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,instructions=[],tick=0,counter=1;
const stages=['FETCH','DECODE','EXECUTE','MEMORY','WRITEBACK'];
const stageColors=['#42A5F5','#66BB6A','#FF9800','#E91E63','#7C4DFF'];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function addInstr(){instructions.push({id:counter++,stage:0,name:'INSTR #'+(counter-1)})}
setInterval(()=>{instructions.forEach(inst=>{if(inst.stage<5)inst.stage++});tick++},800);
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let sw=W/5;
  stages.forEach((s,i)=>{
    x.fillStyle=stageColors[i]+'33';x.fillRect(i*sw,40,sw-4,H-100);
    x.fillStyle=stageColors[i];x.font='bold 12px Courier';x.textAlign='center';
    x.fillText(s,i*sw+sw/2,30);
  });
  instructions.forEach(inst=>{
    if(inst.stage>=5)return;
    let ix=inst.stage*sw+10,iy=80+(inst.id-1)*40;
    if(iy>H-80)return;
    x.fillStyle=stageColors[inst.stage];x.fillRect(ix,iy,sw-24,30);
    x.fillStyle='#fff';x.font='bold 11px Courier';x.textAlign='center';
    x.fillText(inst.name,ix+(sw-24)/2,iy+20);
  });
  x.fillStyle='#888';x.font='11px Courier';x.textAlign='center';
  x.fillText('CLOCK CYCLE: '+tick,W/2,H-20);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("memory-alloc.html", "Memory Allocation", "#FF6F00", """
<div class="hud"><b>MEMORY ALLOCATION</b><br>Allocate and free memory blocks<div id="info">Tap ALLOCATE to reserve memory</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="allocate(2)">ALLOC 2KB</button>
<button onclick="allocate(4)">ALLOC 4KB</button>
<button onclick="allocate(8)">ALLOC 8KB</button>
<button onclick="freeRandom()">FREE RANDOM</button>
<button onclick="blocks=[]">RESET</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,blocks=[],total=64,counter=1;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function used(){return blocks.reduce((s,b)=>s+b.size,0)}
function allocate(size){if(used()+size>total){document.getElementById('info').textContent='OUT OF MEMORY!';return}
  let pos=0;for(let b of blocks.sort((a,b)=>a.pos-b.pos)){if(pos+size<=b.pos)break;pos=b.pos+b.size}
  blocks.push({id:counter++,pos:pos,size:size,color:`hsl(${Math.random()*360},70%,50%)`});
  document.getElementById('info').textContent='Allocated '+size+'KB at offset '+pos+' | Used: '+used()+'/'+total+'KB';
}
function freeRandom(){if(blocks.length)blocks.splice(Math.floor(Math.random()*blocks.length),1)}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let bw=(W-40)/total,bh=H*0.5;
  // Memory bar
  x.fillStyle='#1a1a2e';x.fillRect(20,H*0.25,W-40,bh);
  x.strokeStyle='#FF6F00';x.strokeRect(20,H*0.25,W-40,bh);
  blocks.forEach(b=>{
    x.fillStyle=b.color;x.fillRect(20+b.pos*bw,H*0.25,b.size*bw,bh);
    x.strokeStyle='#000';x.strokeRect(20+b.pos*bw,H*0.25,b.size*bw,bh);
    x.fillStyle='#fff';x.font='bold 10px Courier';x.textAlign='center';
    x.fillText('#'+b.id,20+b.pos*bw+b.size*bw/2,H*0.25+bh/2+4);
    x.fillText(b.size+'KB',20+b.pos*bw+b.size*bw/2,H*0.25+bh/2+18);
  });
  // Address labels
  x.fillStyle='#555';x.font='9px Courier';x.textAlign='center';
  for(let i=0;i<=total;i+=4)x.fillText(i+'',20+i*bw,H*0.25+bh+15);
  x.fillStyle='#FF6F00';x.font='12px Courier';x.textAlign='center';
  x.fillText('USED: '+used()+'/'+total+' KB | FRAGMENTATION: '+blocks.length+' blocks',W/2,H-30);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("encryption-demo.html", "Encryption Demo", "#9C27B0", """
<div class="hud"><b>ENCRYPTION DEMO</b><br>Type a message to encrypt<div id="info">Caesar Cipher | Shift: 3</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<input type="text" id="msg" value="HELLO WORLD" style="width:140px;background:#111;color:#9C27B0;border:1px solid #9C27B0;padding:6px;font-family:inherit">
<button onclick="shift=Math.max(1,shift-1)">SHIFT -</button>
<button onclick="shift=Math.min(25,shift+1)">SHIFT +</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,shift=3;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function encrypt(text,s){return text.split('').map(ch=>{
  if(ch>='A'&&ch<='Z')return String.fromCharCode((ch.charCodeAt(0)-65+s)%26+65);
  if(ch>='a'&&ch<='z')return String.fromCharCode((ch.charCodeAt(0)-97+s)%26+97);return ch}).join('')}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let msg=document.getElementById('msg').value.toUpperCase();
  let enc=encrypt(msg,shift);
  document.getElementById('info').textContent='Caesar Cipher | Shift: '+shift;
  // Plain text
  x.fillStyle='#fff';x.font='bold 14px Courier';x.textAlign='center';
  x.fillText('PLAINTEXT:',W/2,H*0.2);
  x.fillStyle='#9C27B0';x.font='bold 24px Courier';
  x.fillText(msg,W/2,H*0.28);
  // Arrow
  x.fillStyle='#555';x.font='40px Courier';x.fillText('↓',W/2,H*0.4);
  x.fillStyle='#888';x.font='12px Courier';x.fillText('SHIFT +'+shift,W/2,H*0.46);
  // Cipher text
  x.fillStyle='#fff';x.font='bold 14px Courier';x.fillText('CIPHERTEXT:',W/2,H*0.55);
  x.fillStyle='#00e676';x.font='bold 24px Courier';
  x.fillText(enc,W/2,H*0.63);
  // Alphabet mapping
  x.font='12px Courier';x.fillStyle='#555';
  let alpha='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  let mapped=encrypt(alpha,shift);
  x.fillText(alpha,W/2,H*0.78);x.fillStyle='#9C27B0';x.fillText(mapped,W/2,H*0.82);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("graph-traversal.html", "Graph Traversal (BFS/DFS)", "#009688", """
<div class="hud"><b>GRAPH TRAVERSAL</b><br>Tap nodes to set start, then run<div id="info">BFS explores level by level, DFS goes deep first</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="runBFS()">▶ BFS</button>
<button onclick="runDFS()">▶ DFS</button>
<button onclick="resetGraph()">RESET</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H;
let nodes=[],edges=[],visited=[],startNode=0;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight;resetGraph()}addEventListener('resize',resize);resize();
function resetGraph(){visited=[];
  nodes=[];for(let i=0;i<10;i++)nodes.push({x:W*0.2+Math.random()*W*0.6,y:H*0.15+Math.random()*H*0.6,id:i});
  edges=[];for(let i=0;i<10;i++){let j=(i+1)%10;edges.push([i,j]);if(Math.random()>0.5){let k=Math.floor(Math.random()*10);if(k!==i)edges.push([i,k])}}}
c.addEventListener('pointerdown',e=>{
  nodes.forEach((n,i)=>{if(Math.abs(e.clientX-n.x)<20&&Math.abs(e.clientY-n.y)<20)startNode=i});
});
async function runBFS(){visited=[];let q=[startNode],seen=new Set([startNode]);
  while(q.length){let n=q.shift();visited.push(n);await new Promise(r=>setTimeout(r,400));
    edges.forEach(([a,b])=>{let nb=a===n?b:b===n?a:-1;if(nb>=0&&!seen.has(nb)){seen.add(nb);q.push(nb)}})}}
async function runDFS(){visited=[];let stack=[startNode],seen=new Set([startNode]);
  while(stack.length){let n=stack.pop();visited.push(n);await new Promise(r=>setTimeout(r,400));
    edges.forEach(([a,b])=>{let nb=a===n?b:b===n?a:-1;if(nb>=0&&!seen.has(nb)){seen.add(nb);stack.push(nb)}})}}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  edges.forEach(([a,b])=>{x.strokeStyle='#333';x.lineWidth=1;x.beginPath();x.moveTo(nodes[a].x,nodes[a].y);x.lineTo(nodes[b].x,nodes[b].y);x.stroke()});
  nodes.forEach((n,i)=>{
    let vi=visited.indexOf(i);
    x.fillStyle=i===startNode?'#FF5252':vi>=0?'#009688':'#333';
    x.beginPath();x.arc(n.x,n.y,16,0,Math.PI*2);x.fill();
    x.strokeStyle='#009688';x.lineWidth=2;x.beginPath();x.arc(n.x,n.y,16,0,Math.PI*2);x.stroke();
    x.fillStyle='#fff';x.font='bold 11px Courier';x.textAlign='center';x.fillText(i.toString(),n.x,n.y+4);
    if(vi>=0){x.fillStyle='#fff';x.font='9px Courier';x.fillText(vi+1+'',n.x,n.y-22)}
  });
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("recursion-viz.html", "Recursion Visualizer", "#E91E63", """
<div class="hud"><b>RECURSION VISUALIZER</b><br>Fibonacci call tree<div id="info">Tap a number to see its call tree</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="setN(3)">fib(3)</button>
<button onclick="setN(4)">fib(4)</button>
<button onclick="setN(5)" class="a">fib(5)</button>
<button onclick="setN(6)">fib(6)</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,N=5;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function setN(n){N=n}
function drawTree(n,cx,cy,spread,depth){
  if(depth>8||cy>H-50)return;
  let isBase=n<=1;
  // Node
  x.fillStyle=isBase?'#00e676':'#E91E63';
  x.beginPath();x.arc(cx,cy,14,0,Math.PI*2);x.fill();
  x.fillStyle='#fff';x.font='bold 11px Courier';x.textAlign='center';x.fillText('f('+n+')',cx,cy+4);
  if(!isBase){
    // Left child: fib(n-1)
    x.strokeStyle='#E91E63';x.lineWidth=1;x.beginPath();x.moveTo(cx,cy+14);x.lineTo(cx-spread,cy+50);x.stroke();
    drawTree(n-1,cx-spread,cy+50,spread/2,depth+1);
    // Right child: fib(n-2)
    x.beginPath();x.moveTo(cx,cy+14);x.lineTo(cx+spread,cy+50);x.stroke();
    drawTree(n-2,cx+spread,cy+50,spread/2,depth+1);
  }
}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);drawTree(N,W/2,40,W/5,0);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("regex-tester.html", "Regex Tester", "#FF5722", """
<div class="hud"><b>REGEX TESTER</b><br>Type a pattern and test string</div>
<canvas id="c"></canvas>
<div class="ctrl" style="flex-direction:column;align-items:center">
<input type="text" id="pattern" value="[A-Z]+" placeholder="Regex pattern" style="width:200px;background:#111;color:#FF5722;border:1px solid #FF5722;padding:6px;font-family:inherit;margin-bottom:4px">
<input type="text" id="testStr" value="Hello World 123" placeholder="Test string" style="width:200px;background:#111;color:#fff;border:1px solid #555;padding:6px;font-family:inherit">
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let pattern=document.getElementById('pattern').value;
  let testStr=document.getElementById('testStr').value;
  let matches=[];try{let re=new RegExp(pattern,'g'),m;while((m=re.exec(testStr))!==null)matches.push({start:m.index,end:m.index+m[0].length,text:m[0]})}catch(e){}
  x.fillStyle='#fff';x.font='bold 14px Courier';x.textAlign='center';x.fillText('PATTERN: /'+pattern+'/',W/2,H*0.2);
  x.fillText('TEST STRING:',W/2,H*0.32);
  // Draw test string with highlighted matches
  let charW=14,startX=W/2-testStr.length*charW/2;
  for(let i=0;i<testStr.length;i++){
    let isMatch=matches.some(m=>i>=m.start&&i<m.end);
    if(isMatch){x.fillStyle='rgba(255,87,34,0.3)';x.fillRect(startX+i*charW,H*0.36,charW,24)}
    x.fillStyle=isMatch?'#FF5722':'#888';x.font='bold 16px Courier';x.textAlign='center';
    x.fillText(testStr[i],startX+i*charW+charW/2,H*0.36+18);
  }
  x.fillStyle='#ccc';x.font='12px Courier';x.fillText('MATCHES FOUND: '+matches.length,W/2,H*0.55);
  matches.forEach((m,i)=>{x.fillStyle='#FF5722';x.fillText((i+1)+': "'+m.text+'" at index '+m.start,W/2,H*0.6+i*18)});
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("http-flow.html", "HTTP Request Flow", "#2196F3", """
<div class="hud"><b>HTTP REQUEST FLOW</b><br>Watch a request travel through the internet<div id="info">Tap SEND to start a request</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="sendReq('GET')">GET</button>
<button onclick="sendReq('POST')">POST</button>
<button onclick="sendReq('PUT')">PUT</button>
<button onclick="sendReq('DELETE')">DELETE</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,packets=[],method='';
const stages=['CLIENT','DNS','FIREWALL','LOAD\\nBALANCER','SERVER','DATABASE'];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function sendReq(m){method=m;packets.push({stage:0,dir:'out',method:m,progress:0})}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let sw=W/(stages.length),cy=H*0.4;
  stages.forEach((s,i)=>{
    x.fillStyle='#1a1a2e';x.fillRect(i*sw+10,cy-25,sw-20,50);
    x.strokeStyle='#2196F3';x.strokeRect(i*sw+10,cy-25,sw-20,50);
    x.fillStyle='#2196F3';x.font='bold 10px Courier';x.textAlign='center';x.fillText(s,i*sw+sw/2,cy+5);
    if(i<stages.length-1){x.strokeStyle='#333';x.beginPath();x.moveTo(i*sw+sw-10,cy);x.lineTo((i+1)*sw+10,cy);x.stroke()}
  });
  packets.forEach(p=>{
    p.progress+=0.02;
    let si=Math.floor(p.progress);
    if(p.dir==='out'&&si>=stages.length-1){p.dir='back';p.progress=stages.length-1}
    if(p.dir==='back')p.progress-=0.04;
    let px=p.progress*sw+sw/2;
    x.fillStyle=p.dir==='out'?'#4CAF50':'#FF9800';
    x.beginPath();x.arc(px,cy,8,0,Math.PI*2);x.fill();
    x.fillStyle='#fff';x.font='bold 8px Courier';x.textAlign='center';
    x.fillText(p.method,px,cy+3);
  });
  packets=packets.filter(p=>p.progress>0);
  x.fillStyle='#888';x.font='11px Courier';x.textAlign='center';
  x.fillText('🟢 Request (outgoing) → 🟠 Response (returning)',W/2,H-30);
  requestAnimationFrame(draw)}draw();
</script>"""),
    ("database-query.html", "Database Queries", "#FF6F00", """
<div class="hud"><b>SQL QUERY VISUALIZER</b><br>Type SQL to query the table<div id="info">Try: SELECT * FROM students WHERE grade > 80</div></div>
<canvas id="c"></canvas>
<div class="ctrl" style="flex-direction:column;align-items:center">
<input type="text" id="sql" value="SELECT * FROM students WHERE grade > 80" style="width:90%;max-width:400px;background:#111;color:#FF6F00;border:1px solid #FF6F00;padding:8px;font-family:inherit;font-size:11px">
<button onclick="runQuery()" style="margin-top:4px">▶ RUN QUERY</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H;
const data=[
  {id:1,name:'Alice',grade:92,age:17},{id:2,name:'Bob',grade:78,age:18},
  {id:3,name:'Carol',grade:85,age:17},{id:4,name:'Dave',grade:65,age:19},
  {id:5,name:'Eve',grade:95,age:16},{id:6,name:'Frank',grade:72,age:18},
  {id:7,name:'Grace',grade:88,age:17},{id:8,name:'Hank',grade:55,age:19},
];
let results=[...data],highlight=[];
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();
function runQuery(){
  let sql=document.getElementById('sql').value.toLowerCase();results=[...data];highlight=[];
  // Parse WHERE clause
  let whereMatch=sql.match(/where\\s+(\\w+)\\s*([><=!]+)\\s*(\\w+)/);
  if(whereMatch){
    let[_,col,op,val]=whereMatch;
    results=data.filter(row=>{
      let v=row[col];let target=isNaN(val)?val:+val;
      if(op==='>')return v>target;if(op==='<')return v<target;
      if(op==='='||op==='==')return v==target;if(op==='>=')return v>=target;
      if(op==='<=')return v<=target;if(op==='!='||op==='<>')return v!=target;return true;
    });
    highlight=results.map(r=>r.id);
  }
  document.getElementById('info').textContent='Results: '+results.length+' rows';
}
function draw(){x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let cols=['id','name','grade','age'],colW=W/cols.length,rowH=28,startY=50;
  // Header
  cols.forEach((col,i)=>{x.fillStyle='#FF6F00';x.font='bold 12px Courier';x.textAlign='center';x.fillText(col.toUpperCase(),i*colW+colW/2,startY)});
  x.strokeStyle='#FF6F00';x.beginPath();x.moveTo(0,startY+8);x.lineTo(W,startY+8);x.stroke();
  // Rows
  data.forEach((row,ri)=>{
    let y=startY+30+ri*rowH;
    let isHighlighted=highlight.includes(row.id);
    if(isHighlighted){x.fillStyle='rgba(255,111,0,0.15)';x.fillRect(0,y-12,W,rowH)}
    cols.forEach((col,ci)=>{
      x.fillStyle=isHighlighted?'#FF6F00':'#888';x.font='11px Courier';x.textAlign='center';
      x.fillText(row[col].toString(),ci*colW+colW/2,y+5);
    });
  });
  requestAnimationFrame(draw)}draw();
</script>"""),
]:
    w("cs", fname, HEAD(title, accent) + body_js + FOOT)

# Globe — interactive with country outlines (simplified vector globe)
print("\nGLOBE:")
w("geography", "index.html", HEAD("Global Atlas 3D", "#00BCD4") + """
<div class="hud"><b>GLOBAL ATLAS</b><br>Drag to rotate | Tap to identify<div id="info">Rotating globe with country outlines</div></div>
<canvas id="c"></canvas>
<div class="ctrl">
<button onclick="autoRot=!autoRot">AUTO-ROTATE</button>
<button onclick="rotX=0;rotY=0">RESET VIEW</button>
</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');let W,H,rotX=0,rotY=0.3,autoRot=true;
function resize(){W=c.width=innerWidth;H=c.height=innerHeight}addEventListener('resize',resize);resize();

// Simplified country outlines as lat/lon polygon centroids
const countries=[
  {name:'Brazil',lat:-15,lon:-47,r:18,color:'#4CAF50'},
  {name:'USA',lat:39,lon:-98,r:20,color:'#2196F3'},
  {name:'China',lat:35,lon:103,r:18,color:'#F44336'},
  {name:'India',lat:21,lon:78,r:14,color:'#FF9800'},
  {name:'Russia',lat:60,lon:90,r:22,color:'#9C27B0'},
  {name:'Australia',lat:-25,lon:134,r:16,color:'#FFEB3B'},
  {name:'Canada',lat:56,lon:-106,r:20,color:'#E91E63'},
  {name:'UK',lat:54,lon:-2,r:6,color:'#00BCD4'},
  {name:'Japan',lat:36,lon:138,r:6,color:'#FF5722'},
  {name:'Egypt',lat:27,lon:31,r:10,color:'#FFC107'},
  {name:'S.Africa',lat:-29,lon:24,r:10,color:'#8BC34A'},
  {name:'Mexico',lat:23,lon:-102,r:12,color:'#FF7043'},
  {name:'Argentina',lat:-38,lon:-63,r:14,color:'#42A5F5'},
  {name:'Nigeria',lat:10,lon:8,r:10,color:'#66BB6A'},
  {name:'Indonesia',lat:-5,lon:120,r:12,color:'#AB47BC'},
  {name:'Germany',lat:51,lon:10,r:7,color:'#BDBDBD'},
  {name:'France',lat:47,lon:2,r:8,color:'#1565C0'},
  {name:'Italy',lat:42,lon:12,r:6,color:'#4E342E'},
  {name:'Spain',lat:40,lon:-4,r:7,color:'#E65100'},
  {name:'Turkey',lat:39,lon:35,r:8,color:'#C62828'},
];

function project(lat,lon){
  let la=lat*Math.PI/180,lo=lon*Math.PI/180;
  let px=Math.cos(la)*Math.sin(lo+rotX);
  let py=-Math.sin(la)*Math.cos(rotY)+Math.cos(la)*Math.sin(rotY)*Math.cos(lo+rotX);
  let pz=Math.sin(la)*Math.sin(rotY)+Math.cos(la)*Math.cos(rotY)*Math.cos(lo+rotX);
  return{x:px,y:py,z:pz,visible:pz>0};
}

let dragging=false,lastX=0,lastY=0;
c.addEventListener('pointerdown',e=>{dragging=true;lastX=e.clientX;lastY=e.clientY;
  // Check country click
  let R=Math.min(W,H)*0.38;
  countries.forEach(ct=>{
    let p=project(ct.lat,ct.lon);if(!p.visible)return;
    let sx=W/2+p.x*R,sy=H/2+p.y*R;
    if(Math.abs(e.clientX-sx)<ct.r+5&&Math.abs(e.clientY-sy)<ct.r+5){
      document.getElementById('info').textContent=ct.name+' | Lat: '+ct.lat+'° Lon: '+ct.lon+'°';
      if(window.VerassoGlobe)window.VerassoGlobe.postMessage(JSON.stringify({type:'polygonClick',name:ct.name}));
    }
  });
});
c.addEventListener('pointermove',e=>{if(!dragging)return;rotX+=(e.clientX-lastX)*0.005;rotY+=(e.clientY-lastY)*0.005;
  rotY=Math.max(-1.5,Math.min(1.5,rotY));lastX=e.clientX;lastY=e.clientY});
c.addEventListener('pointerup',()=>dragging=false);

function initGlobeData(){}
function rotateToHome(){rotX=0;rotY=0.3}
window.initGlobeData=initGlobeData;
window.rotateToHome=rotateToHome;

function draw(){
  if(autoRot&&!dragging)rotX+=0.003;
  x.fillStyle='#0a0a1a';x.fillRect(0,0,W,H);
  let R=Math.min(W,H)*0.38,cx=W/2,cy=H/2;

  // Stars
  for(let i=0;i<40;i++){x.fillStyle='rgba(255,255,255,'+(0.1+Math.random()*0.3)+')';x.fillRect(Math.random()*W,Math.random()*H,1,1)}

  // Globe ocean
  let grd=x.createRadialGradient(cx-R*0.2,cy-R*0.2,0,cx,cy,R);
  grd.addColorStop(0,'#1565C0');grd.addColorStop(0.7,'#0D47A1');grd.addColorStop(1,'#01579B');
  x.fillStyle=grd;x.beginPath();x.arc(cx,cy,R,0,Math.PI*2);x.fill();

  // Grid lines (latitude)
  for(let lat=-60;lat<=60;lat+=30){
    let pts=[];
    for(let lon=-180;lon<=180;lon+=5){let p=project(lat,lon);if(p.visible)pts.push({x:cx+p.x*R,y:cy+p.y*R})}
    if(pts.length>1){x.strokeStyle='rgba(255,255,255,0.08)';x.lineWidth=1;x.beginPath();x.moveTo(pts[0].x,pts[0].y);
      pts.forEach(p=>x.lineTo(p.x,p.y));x.stroke()}
  }
  // Grid lines (longitude)
  for(let lon=-180;lon<180;lon+=30){
    let pts=[];
    for(let lat=-90;lat<=90;lat+=5){let p=project(lat,lon);if(p.visible)pts.push({x:cx+p.x*R,y:cy+p.y*R})}
    if(pts.length>1){x.strokeStyle='rgba(255,255,255,0.08)';x.lineWidth=1;x.beginPath();x.moveTo(pts[0].x,pts[0].y);
      pts.forEach(p=>x.lineTo(p.x,p.y));x.stroke()}
  }

  // Countries
  countries.forEach(ct=>{
    let p=project(ct.lat,ct.lon);if(!p.visible)return;
    let sx=cx+p.x*R,sy=cy+p.y*R;
    x.globalAlpha=0.5+p.z*0.5;
    x.fillStyle=ct.color;x.beginPath();x.arc(sx,sy,ct.r*p.z,0,Math.PI*2);x.fill();
    x.globalAlpha=1;
    if(p.z>0.5){x.fillStyle='#fff';x.font='bold 8px Courier';x.textAlign='center';x.fillText(ct.name,sx,sy+ct.r+10)}
  });

  // Atmosphere glow
  x.strokeStyle='rgba(100,181,246,0.15)';x.lineWidth=6;x.beginPath();x.arc(cx,cy,R+3,0,Math.PI*2);x.stroke();

  requestAnimationFrame(draw);
}
draw();
</script>""" + FOOT)

print("\n✅ All Geography + CS simulations regenerated!")
