const fs = require('fs');
const { createCanvas } = require('canvas');

function hslToRgb(h, s, l, a = 1) {
  h /= 360; s /= 100; l /= 100;
  let r, g, b;
  if (s === 0) { r = g = b = l; }
  else {
    const hue2rgb = (p, q, t) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1/6) return p + (q - p) * 6 * t;
      if (t < 1/2) return q;
      if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
      return p;
    };
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, h + 1/3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1/3);
  }
  return `rgba(${Math.round(r*255)},${Math.round(g*255)},${Math.round(b*255)},${a})`;
}

function mapRange(v, imin, imax, omin, omax) {
  return ((v - imin) / (imax - imin)) * (omax - omin) + omin;
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y); ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r); ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h); ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r); ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

function drawStar(ctx, x, y, r1, r2, npoints, fillInner, fillOuter) {
  const angle = Math.PI / npoints;
  const halfAngle = angle / 2;
  ctx.fillStyle = fillOuter;
  ctx.beginPath();
  for (let a = -Math.PI / 2; a < Math.PI * 1.5; a += angle) {
    const sx = x + Math.cos(a) * r2, sy = y + Math.sin(a) * r2;
    a === -Math.PI / 2 ? ctx.moveTo(sx, sy) : ctx.lineTo(sx, sy);
    ctx.lineTo(x + Math.cos(a + halfAngle) * r1, y + Math.sin(a + halfAngle) * r1);
  }
  ctx.closePath(); ctx.fill();
  ctx.fillStyle = fillInner;
  ctx.beginPath();
  for (let a = -Math.PI / 2; a < Math.PI * 1.5; a += angle) {
    const sx = x + Math.cos(a) * r1, sy = y + Math.sin(a) * r1;
    a === -Math.PI / 2 ? ctx.moveTo(sx, sy) : ctx.lineTo(sx, sy);
    ctx.lineTo(x + Math.cos(a + halfAngle) * r2 * 0.55, y + Math.sin(a + halfAngle) * r2 * 0.55);
  }
  ctx.closePath(); ctx.fill();
}

function generateIcon(size, seed = 88888) {
  const canvas = createCanvas(size, size);
  const ctx = canvas.getContext('2d');
  const S = size / 1024; // scale factor
  const cx = size / 2, cy = size / 2;
  const baseHue = 330;

  // Seeded random
  let s = seed;
  function rnd() { s = (s * 9301 + 49297) % 233280; return s / 233280; }
  function noise(x, y) { return ((Math.sin(x*12.9898+y*78.233+seed*0.01)*43758.5453)%1+1)%1; }

  // === LAYER 1: Deep Space Background ===
  const bgGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, size * 0.75);
  bgGrad.addColorStop(0, '#2a1045'); bgGrad.addColorStop(0.4, '#1a0830');
  bgGrad.addColorStop(0.7, '#100520'); bgGrad.addColorStop(1, '#05000a');
  ctx.fillStyle = bgGrad; ctx.fillRect(0, 0, size, size);

  // === LAYER 2: Nebula Clouds ===
  for (let i = 0; i < 15; i++) {
    const nx = noise(i * 0.73, 0) * size, ny = noise(i * 0.73 + 500, 0) * size;
    const nr = noise(i * 0.73 + 1000, 0) * 300 * S + 120 * S;
    const nh = (baseHue + 20 + i * 8) % 360;
    const ng = ctx.createRadialGradient(nx, ny, 0, nx, ny, nr);
    ng.addColorStop(0, hslToRgb(nh, 70, 60, 0.12));
    ng.addColorStop(0.6, hslToRgb(nh+15, 65, 50, 0.06)); ng.addColorStop(1, hslToRgb(nh, 60, 40, 0));
    ctx.fillStyle = ng; ctx.beginPath(); ctx.arc(nx, ny, nr, 0, Math.PI*2); ctx.fill();
  }

  // === LAYER 3: Energy Rings (GAME ICON SIGNATURE) ===
  for (let ring = 0; ring < 3; ring++) {
    const rr = (220 + ring * 70) * S, ra = [0.35, 0.22, 0.12][ring];
    const rh = (baseHue + ring * 25) % 360;
    ctx.save(); ctx.translate(cx, cy); ctx.rotate((ring%2?1:-1)*0.15);
    for (let w = 24*S; w > 0; w -= 2*S) {
      ctx.strokeStyle = hslToRgb(rh, 80, 70, ra * (w/(24*S)));
      ctx.lineWidth = w; ctx.beginPath(); ctx.arc(0, 0, rr, 0, Math.PI*2); ctx.stroke();
    }
    ctx.restore();

    // Ring dashes
    const dc = 24 + ring * 8;
    for (let d = 0; d < dc; d++) {
      const ang = (Math.PI*2/dc)*d;
      ctx.strokeStyle = hslToRgb(baseHue+ring*30, 60, 90, 0.25-ring*0.06);
      ctx.lineWidth = 2*S; ctx.beginPath();
      ctx.moveTo(cx+Math.cos(ang)*(rr-10*S), cy+Math.sin(ang)*(rr-10*S));
      ctx.lineTo(cx+Math.cos(ang)*(rr+10*S), cy+Math.sin(ang)*(rr+10*S));
      ctx.stroke();
    }
  }

  // === LAYER 4: Core Glow Sphere ===
  const coreSize = 140 * S;
  for (let r = (coreSize+80*S); r > coreSize; r -= 3*S) {
    const alpha = mapRange(r, coreSize, coreSize+80*S, 0.55, 0);
    const cg = ctx.createRadialGradient(cx, cy-10*S, 0, cx, cy, r);
    cg.addColorStop(0, hslToRgb(baseHue,75,95,alpha)); cg.addColorStop(0.7, hslToRgb(baseHue+20,70,80,alpha*0.5));
    cg.addColorStop(1, hslToRgb(baseHue+40,60,60,0));
    ctx.fillStyle = cg; ctx.beginPath(); ctx.arc(cx,cy,r,0,Math.PI*2); ctx.fill();
  }
  // Inner bright core
  const ig = ctx.createRadialGradient(cx, cy-10*S, 0, cx, cy, coreSize*0.65);
  ig.addColorStop(0, hslToRgb(200,30,98,0.95)); ig.addColorStop(0.4, hslToRgb(210,35,92,0.7));
  ig.addColorStop(0.8, hslToRgb(baseHue+180,40,85,0.3)); ig.addColorStop(1, hslToRgb(baseHue+160,45,75,0));
  ctx.fillStyle = ig; ctx.beginPath(); ctx.arc(cx,cy,coreSize*0.65,0,Math.PI*2); ctx.fill();

  // === LAYER 5: Character Face ===
  drawCharacter(ctx, cx, cy-15*S, coreSize*0.88/S * S, baseHue, S);

  // === LAYER 6: Stars ===
  for (let i = 0; i < 250; i++) {
    const sx=rnd()*size, sy=rnd()*size, ss=(rnd()*3.5+0.5)*S, sb=rnd()*0.6+0.4;
    ctx.fillStyle=hslToRgb(45,10,99,sb); ctx.beginPath();ctx.arc(sx,sy,ss,0,Math.PI*2);ctx.fill();
    if(ss>2.2*S){ctx.fillStyle=hslToRgb(45,8,99,sb*0.35);ctx.beginPath();ctx.arc(sx,sy,ss*2.8,0,Math.PI*2);ctx.fill();}
    if(ss>2.8*S && rnd()>0.5){
      ctx.strokeStyle=hslToRgb(45,15,99,sb*0.7); ctx.lineWidth=S;
      ctx.beginPath();ctx.moveTo(sx-ss*4,sy);ctx.lineTo(sx+ss*4,sy);ctx.stroke();
      ctx.beginPath();ctx.moveTo(sx,sy-ss*4);ctx.lineTo(sx,sy+ss*4);ctx.stroke();
    }
  }

  // === LAYER 7: Floating Particles ===
  for (let i=0;i<180;i++){
    const ang=rnd()*Math.PI*2, dist=coreSize*0.6+rnd()*300*S;
    const px=cx+Math.cos(ang)*dist, py=cy+Math.sin(ang)*dist;
    const ps=(rnd()*6+1.5)*S, ph=(baseHue+rnd()*60-30)%360, pa=rnd()*0.6+0.25;
    const pg=ctx.createRadialGradient(px,py,0,px,py,ps*2.5);
    pg.addColorStop(0,hslToRgb(ph,90,95,pa)); pg.addColorStop(0.5,hslToRgb(ph,75,85,pa*0.4)); pg.addColorStop(1,hslToRgb(ph,60,70,0));
    ctx.fillStyle=pg; ctx.beginPath();ctx.arc(px,py,ps*2.5,0,Math.PI*2);ctx.fill();
    ctx.fillStyle=hslToRgb(ph,70,99,pa); ctx.beginPath();ctx.arc(px,py,ps*0.6,0,Math.PI*2);ctx.fill();
  }

  // === LAYER 8: Light Rays ===
  ctx.save(); ctx.globalCompositeOperation='lighter';
  for(let i=0;i<16;i++){
    const ang=(Math.PI*2/16)*i+(rnd()-0.5)*0.3, rl=(coreSize+180*S)+rnd()*80*S;
    const rg=ctx.createLinearGradient(cx,cy,cx+Math.cos(ang)*rl,cy+Math.sin(ang)*rl);
    rg.addColorStop(0,hslToRgb(baseHue,80,72,0.18)); rg.addColorStop(0.4,hslToRgb(baseHue+15,75,68,0.09));
    rg.addColorStop(1,hslToRgb(baseHue+30,70,62,0));
    ctx.fillStyle=rg; ctx.save(); ctx.translate(cx,cy); ctx.rotate(ang);
    ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(rl,-(12+i*1.5)*S); ctx.lineTo(rl,(12+i*1.5)*S); ctx.closePath(); ctx.fill();
    ctx.restore();
  }
  ctx.restore(); ctx.globalCompositeOperation='source-over';

  // === LAYER 9: Decorative Border ===
  const bw=size/2-24*S, cr=170*S;
  for(let i=0;i<3;i++){
    ctx.strokeStyle=hslToRgb((baseHue+i*18)%360,68,90,0.1-i*0.025);
    ctx.lineWidth=(4-i)*S;
    roundRect(ctx,cx-bw+10*S-i*3*S,cy-bw+10*S-i*3*S,(bw-10*S+i*3*S)*2,(bw-10*S+i*3*S)*2,cr-i*12*S);
    ctx.stroke();
  }

  // Corner accents
  const corners=[[cx-(bw-8*S),cy-(bw-8*S),0],[cx+(bw-8*S),cy-(bw-8*S),Math.PI/2],
                  [cx+(bw-8*S),cy+(bw-8*S),Math.PI],[cx-(bw-8*S),cy+(bw-8*S),Math.PI*1.5]];
  for(const c of corners){
    ctx.save(); ctx.translate(c[0],c[1]); ctx.rotate(c[2]);
    ctx.strokeStyle=hslToRgb(baseHue,68,93,0.48); ctx.lineWidth=3*S; ctx.lineCap='round';
    ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(48*S,0);ctx.stroke();
    ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(0,48*S);ctx.stroke();
    ctx.strokeStyle=hslToRgb(45,78,99,0.72); ctx.lineWidth=1.5*S;
    ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(48*S*0.68,0);ctx.stroke();
    ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(0,48*S*0.68);ctx.stroke();
    ctx.fillStyle=hslToRgb(45,80,99,0.85); ctx.beginPath();ctx.arc(0,0,3*S,0,Math.PI*2);ctx.fill();
    ctx.restore();
  }

  return canvas;
}

function drawCharacter(ctx, x, y, size, hue, S) {
  ctx.save(); ctx.translate(x, y);
  const sz = size; // already scaled

  // Hair back layer
  for(let i=4;i>=0;i--){
    const ha=0.28-i*0.05, hg=ctx.createRadialGradient(0,-sz*0.05,0,0,-sz*0.05,sz*(0.55+i*0.06));
    hg.addColorStop(0,hslToRgb(hue+340,58,92,ha)); hg.addColorStop(1,hslToRgb(hue+330,52,82,ha*0.5));
    ctx.fillStyle=hg; ctx.beginPath();ctx.ellipse(0,-sz*0.02,sz*(0.56+i*0.07),sz*(0.54+i*0.05),0,0,Math.PI*2);ctx.fill();
  }

  // Face
  const fg=ctx.createRadialGradient(-sz*0.06,-sz*0.08,0,0,sz*0.04,sz*0.32);
  fg.addColorStop(0,hslToRgb(hue+330,18,97,0.88)); fg.addColorStop(0.7,hslToRgb(hue+330,22,94,0.88));
  fg.addColorStop(1,hslToRgb(hue+320,26,89,0.85));
  ctx.fillStyle=fg; ctx.beginPath();ctx.ellipse(0,sz*0.03,sz*0.27,sz*0.33,0,0,Math.PI*2);ctx.fill();

  // Eyes
  const es=sz*0.165, ey=-sz*0.03, ew=sz*0.135, eh=sz*0.195;
  for(let e=0;e<2;e++){
    const ex=e?-es:es;
    const eg=ctx.createRadialGradient(ex,ey,0,ex,ey,ew*1.6);
    eg.addColorStop(0,hslToRgb(hue+270,75,93,0.32)); eg.addColorStop(0.6,hslToRgb(hue+260,70,88,0.14));
    eg.addColorStop(1,hslToRgb(hue+250,65,80,0));
    ctx.fillStyle=eg; ctx.beginPath();ctx.ellipse(ex,ey,ew*1.6,eh*1.6,0,0,Math.PI*2);ctx.fill();

    const em=ctx.createRadialGradient(ex-ew*0.15,ey-eh*0.15,0,ex,ey,eh);
    em.addColorStop(0,hslToRgb(hue+290,85,96,0.95)); em.addColorStop(0.3,hslToRgb(hue+275,88,94,0.92));
    em.addColorStop(0.7,hslToRgb(hue+260,86,91,0.9)); em.addColorStop(1,hslToRgb(hue+245,78,84,0.88));
    ctx.fillStyle=em; ctx.beginPath();ctx.ellipse(ex,ey,ew,eh,0,0,Math.PI*2);ctx.fill();

    const pg=ctx.createRadialGradient(ex,ey+2,0,ex,ey+2,ew*0.42);
    pg.addColorStop(0,hslToRgb(260,55,18,0.97)); pg.addColorStop(0.7,hslToRgb(265,60,14,0.95));
    pg.addColorStop(1,hslToRgb(270,65,10,0.9));
    ctx.fillStyle=pg; ctx.beginPath();ctx.ellipse(ex,ey+2,ew*0.42,eh*0.48,0,0,Math.PI*2);ctx.fill();

    ctx.fillStyle=hslToRgb(0,0,100,0.96); ctx.beginPath();
    ctx.ellipse(ex-ew*0.17,ey-eh*0.19,ew*0.29,eh*0.27,-0.3,0,Math.PI*2);ctx.fill();
    ctx.fillStyle=hslToRgb(0,0,100,0.72); ctx.beginPath();
    ctx.ellipse(ex+ew*0.13,ey+eh*0.19,ew*0.13,eh*0.12,0.3,0,Math.PI*2);ctx.fill();
    ctx.fillStyle=hslToRgb(0,0,100,0.5); ctx.beginPath();
    ctx.ellipse(ex-ew*0.05,ey+eh*0.28,ew*0.07,eh*0.06,0,0,Math.PI*2);ctx.fill();
  }

  // Blush
  const bgL=ctx.createRadialGradient(-es-sz*0.03,ey+sz*0.14,0,-es-sz*0.03,ey+sz*0.14,sz*0.06);
  bgL.addColorStop(0,hslToRgb(hue+340,55,85,0.32)); bgL.addColorStop(1,hslToRgb(hue+340,50,80,0));
  ctx.fillStyle=bgL; ctx.beginPath();ctx.ellipse(-es-sz*0.03,ey+sz*0.14,sz*0.095,sz*0.062,0,0,Math.PI*2);ctx.fill();
  const bgR=ctx.createRadialGradient(es+sz*0.03,ey+sz*0.14,0,es+sz*0.03,ey+sz*0.14,sz*0.06);
  bgR.addColorStop(0,hslToRgb(hue+340,55,85,0.32)); bgR.addColorStop(1,hslToRgb(hue+340,50,80,0));
  ctx.fillStyle=bgR; ctx.beginPath();ctx.ellipse(es+sz*0.03,ey+sz*0.14,sz*0.095,sz*0.062,0,0,Math.PI*2);ctx.fill();

  // Smile
  ctx.strokeStyle=hslToRgb(hue+330,48,72,0.58); ctx.lineWidth=sz*0.016; ctx.lineCap='round';
  ctx.beginPath();ctx.arc(0,ey+sz*0.21,sz*0.052,0.12,Math.PI-0.12);ctx.stroke();

  // Bangs
  ctx.fillStyle=hslToRgb(hue+346,56,93,0.78);
  [[-0.28,-0.22,-0.22,-0.39,-0.08,-0.44,-0.02,-0.28,-0.06,-0.17,-0.15,-0.11],
   [0.28,-0.22,0.22,-0.39,0.08,-0.44,0.02,-0.28,0.06,-0.17,0.15,-0.11]].forEach(b=>{
    ctx.beginPath(); ctx.moveTo(b[0]*sz,b[1]*sz);
    ctx.bezierCurveTo(b[2]*sz,b[3]*sz,b[4]*sz,b[5]*sz,b[6]*sz,b[7]*sz);
    ctx.bezierCurveTo(b[8]*sz,b[9]*sz,b[10]*sz,b[11]*sz,b[0]*sz,b[1]*sz); ctx.closePath(); ctx.fill();
  });
  ctx.beginPath(); ctx.moveTo(-0.06*sz,-0.28*sz);
  ctx.bezierCurveTo(-0.02*sz,-0.49*sz,0.02*sz,-0.49*sz,0.06*sz,-0.28*sz);
  ctx.bezierCurveTo(0.02*sz,-0.19*sz,-0.02*sz,-0.19*sz,-0.06*sz,-0.28*sz); ctx.closePath(); ctx.fill();

  // Side hair
  const shl=ctx.createRadialGradient(-sz*0.31,sz*0.06,0,-sz*0.31,sz*0.06,sz*0.18);
  shl.addColorStop(0,hslToRgb(hue+344,54,92,0.72)); shl.addColorStop(1,hslToRgb(hue+336,48,84,0.45));
  ctx.fillStyle=shl; ctx.beginPath();ctx.ellipse(-sz*0.32,sz*0.05,sz*0.145,sz*0.36,0.05,0,Math.PI*2);ctx.fill();
  const shr=ctx.createRadialGradient(sz*0.31,sz*0.06,0,sz*0.31,sz*0.06,sz*0.18);
  shr.addColorStop(0,hslToRgb(hue+344,54,92,0.72)); shr.addColorStop(1,hslToRgb(hue+336,48,84,0.45));
  ctx.fillStyle=shr; ctx.beginPath();ctx.ellipse(sz*0.32,sz*0.05,sz*0.145,sz*0.36,-0.05,0,Math.PI*2);ctx.fill();

  // Hair shine
  ctx.fillStyle=hslToRgb(0,0,100,0.16); ctx.beginPath();
  ctx.ellipse(-sz*0.14,-sz*0.17,sz*0.115,sz*0.175,-0.3,0,Math.PI*2);ctx.fill();
  ctx.beginPath();ctx.ellipse(sz*0.17,-sz*0.14,sz*0.08,sz*0.135,0.2,0,Math.PI*2);ctx.fill();

  // Star accessory
  ctx.save(); ctx.translate(sz*0.225,-sz*0.26);
  drawStar(ctx,0,0,sz*0.055,sz*0.118,5,hslToRgb(45,72,99,0.88),hslToRgb(0,0,100,0.38));
  ctx.restore(); ctx.restore();
}

// Generate all sizes
console.log('Generating game-style icons...');
for (const sz of [1024, 512, 192, 96, 72, 48]) {
  const canvas = generateIcon(sz, 88888);
  const buffer = canvas.toBuffer('image/png');
  const outPath = `/workspace/ohos_airi/game_icon_v2_${sz}.png`;
  fs.writeFileSync(outPath, buffer);
  console.log(`  ${outPath} (${buffer.length} bytes)`);
}
console.log('Done!');
