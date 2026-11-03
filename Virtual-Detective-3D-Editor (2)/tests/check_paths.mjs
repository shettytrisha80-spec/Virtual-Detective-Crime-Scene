import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
let count = 0;
for (const rel of ['project.godot','scenes/main.tscn','scripts/main.gd','scripts/case_data.gd']) {
 const text = fs.readFileSync(path.join(root,rel),'utf8');
 for (const match of text.matchAll(/res:\/\/([^"\r\n]+)/g)) {
  if (match[1].endsWith('/') || match[1].startsWith('tests/')) continue;
  if (!fs.existsSync(path.join(root,match[1]))) throw new Error(`Missing reference in ${rel}: ${match[1]}`);
  count++;
 }
}
for(const key of ['room','police','static','click','discover','drawer','phone','wrong','solved']) {
 const wav=fs.readFileSync(path.join(root,'audio',key+'.wav'));
 if(wav.toString('ascii',0,4)!=='RIFF' || wav.toString('ascii',8,12)!=='WAVE' || wav.readUInt16LE(22)!==1 || wav.readUInt16LE(34)!==16 || wav.readUInt32LE(40)!==wav.length-44) throw new Error('Invalid WAV: '+key);
 count++;
}
console.log(`PATH/AUDIO PASS: ${count} static references and dynamic audio resources valid.`);
