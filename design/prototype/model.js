/* Browser-only prototype model; shared by UI and structured automation. */
'use strict';
window.createPaybackModel = function ({ key, seeds }) {
  const clone = value => JSON.parse(JSON.stringify(value));
  const uid = () => globalThis.crypto?.randomUUID?.() || `pb-${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
  const currencies = ['CNY','USD','EUR','JPY','GBP','HKD','TWD','KRW','SGD','AUD','CAD','CHF'];
  const categories = ['computer','keyboard','tablet','audio','phone','coffee','box'];
  const today = () => { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`; };
  const fail = (code, details = {}) => ({ ok: false, error: { code, ...details } });
  function validateDevice(input) {
    if (!input || typeof input !== 'object' || Array.isArray(input)) return fail('INVALID_DEVICE');
    const fields = {};
    if (typeof input.id !== 'string' || !/^[a-zA-Z0-9_-]{1,100}$/.test(input.id)) fields.id = 'INVALID_ID';
    if (typeof input.name !== 'string' || !input.name.trim() || input.name.length > 120) fields.name = 'NAME_REQUIRED';
    for (const f of ['price','daily']) if (!(f === 'daily' && input[f] === null) && (typeof input[f] !== 'number' || !Number.isFinite(input[f]) || input[f] <= 0 || input[f] > 10000000 || Math.abs(input[f]*100-Math.round(input[f]*100)) > 0.000001)) fields[f] = 'INVALID_AMOUNT';
    if (typeof input.date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(input.date) || !Number.isFinite(Date.parse(input.date+'T00:00:00Z')) || new Date(input.date+'T00:00:00Z').toISOString().slice(0,10) !== input.date || input.date < '1900-01-01' || input.date > today()) fields.date = 'INVALID_DATE';
    if (!currencies.includes(input.currency)) fields.currency = 'INVALID_CURRENCY';
    if (!categories.includes(input.category)) fields.category = 'INVALID_CATEGORY';
    if (typeof input.note !== 'string' || input.note.length > 2000) fields.note = 'INVALID_NOTE';
    if (Object.keys(fields).length) return fail('VALIDATION_FAILED', { fields });
    return { ok: true, data: { id: input.id, name: input.name.trim(), price: input.price, daily: input.daily, date: input.date, currency: input.currency, category: input.category, note: input.note } };
  }
  function validateData(input) {
    if (!input || !Array.isArray(input.devices) || input.devices.length > 2000 || !Array.isArray(input.trash) || input.trash.length > 2000) return fail('INVALID_BACKUP');
    const ids = new Set(), devices = [], trash = [];
    for (const [source, target] of [[input.devices, devices], [input.trash, trash]]) {
      for (const item of source) { const result = validateDevice(item); if (!result.ok || ids.has(item.id)) return fail('INVALID_BACKUP'); ids.add(item.id); target.push(result.data); }
    }
    const p = input.preferences;
    if (!p || !currencies.includes(p.currency) || !['system','light','dark'].includes(p.theme) || !['system','zh-CN','en'].includes(p.language)) return fail('INVALID_BACKUP');
    return { ok: true, data: { devices, trash, preferences: { currency: p.currency, theme: p.theme, language: p.language } } };
  }
  let raw = null, stored = true, damaged = false;
  let state = { devices: clone(seeds), trash: [], preferences: { currency: 'CNY', theme: 'system', language: 'system' }, revision: 0 };
  try {
    raw = localStorage.getItem(key);
    if (raw) {
      const s = JSON.parse(raw);
      const normalized = s.preferences ? s : { devices: s.devices, trash: [], preferences: { currency: s.currency || 'CNY', theme: s.theme || 'system', language: 'system' }, revision: 0 };
      const checked = validateData(normalized);
      if (!checked.ok) throw new Error('invalid stored data');
      state = { ...checked.data, revision: Number.isSafeInteger(s.revision) ? s.revision : 0 };
    }
  } catch (e) { stored = false; damaged = raw !== null; }
  let busy = false, automation = false;
  const plans = new Map(), completed = new Map();
  function metrics(d) {
    const held = Math.max(1, Math.floor((Date.parse(today()+'T00:00:00Z')-Date.parse(d.date+'T00:00:00Z'))/86400000)+1);
    const target = d.daily ? Math.ceil(d.price/d.daily) : null;
    return { held, cost: d.price/held, target, remaining: target ? Math.max(0,target-held) : null, progress: target ? Math.min(100,held*d.daily/d.price*100) : null, extra: d.daily ? Math.max(0,held*d.daily-d.price) : 0 };
  }
  function snapshot() { return clone({ ...state, storage: { persistent: stored, damaged }, automationEnabled: automation }); }
  function preview(request) {
    if (!request || typeof request !== 'object') return fail('INVALID_REQUEST');
    const next = clone(state); let selectedId = null, effect = {};
    if (request.action === 'create') {
      if (next.devices.length >= 2000) return fail('LIMIT_REACHED');
      const checked = validateDevice({ ...request.device, id: uid() }); if (!checked.ok) return checked;
      next.devices.unshift(checked.data); selectedId = checked.data.id; effect = { action:'create', after:checked.data };
    } else if (request.action === 'update') {
      const index = next.devices.findIndex(d=>d.id===request.id); if (index<0) return fail('NOT_FOUND');
      if (!request.patch || typeof request.patch !== 'object' || Object.keys(request.patch).some(k=>!['name','price','daily','date','currency','category','note'].includes(k))) return fail('INVALID_REQUEST');
      const checked = validateDevice({ ...next.devices[index], ...request.patch, id:request.id }); if (!checked.ok) return checked;
      effect = { action:'update', before:next.devices[index], after:checked.data }; next.devices[index]=checked.data; selectedId=request.id;
    } else if (request.action === 'delete') {
      const index = next.devices.findIndex(d=>d.id===request.id); if (index<0) return fail('NOT_FOUND');
      if (next.trash.length >= 2000) return fail('LIMIT_REACHED');
      const [item]=next.devices.splice(index,1); next.trash.unshift(item); effect={ action:'delete', before:item, recoverable:true }; selectedId=next.devices[0]?.id||null;
    } else if (request.action === 'restore') {
      const index=next.trash.findIndex(d=>d.id===request.id); if(index<0)return fail('NOT_FOUND');
      if(next.devices.length>=2000)return fail('LIMIT_REACHED');
      const [item]=next.trash.splice(index,1);next.devices.unshift(item);selectedId=item.id;effect={action:'restore',after:item};
    } else if (request.action === 'preferences') {
      const p=request.preferences;
      if(!p||typeof p!=='object'||Object.keys(p).some(k=>!['currency','theme','language'].includes(k)))return fail('INVALID_REQUEST');
      const check=validateData({...next,preferences:{...next.preferences,...p}});if(!check.ok)return fail('INVALID_PREFERENCES');
      next.preferences=check.data.preferences;effect={action:'preferences',before:state.preferences,after:next.preferences};
    } else if (request.action === 'import') {
      const b=request.backup;
      if(!b||b.schema!=='payback.backup'||b.version!==1)return fail('INVALID_BACKUP');
      const checked=validateData(b.data);if(!checked.ok)return checked;
      next.devices=checked.data.devices;next.trash=checked.data.trash;next.preferences=checked.data.preferences;selectedId=next.devices[0]?.id||null;
      effect={action:'import',replaceCount:state.devices.length,importCount:next.devices.length,trashCount:next.trash.length,preferences:next.preferences};
    } else return fail('UNKNOWN_ACTION');
    if(plans.size>=100)plans.delete(plans.keys().next().value);
    const token=uid();plans.set(token,{next,selectedId,effect,revision:state.revision,expires:Date.now()+300000,allowDamaged:request.action==='import'});
    return {ok:true,data:{token,revision:state.revision,expiresAt:new Date(Date.now()+300000).toISOString(),effect:clone(effect)}};
  }
  function commit(token) {
    if(completed.has(token))return clone(completed.get(token));
    if(busy)return fail('BUSY');
    const p=plans.get(token);if(!p)return fail('INVALID_TOKEN');
    if(p.expires<Date.now()){plans.delete(token);return fail('EXPIRED_TOKEN')}
    if(p.revision!==state.revision)return fail('STALE_PREVIEW');
    if(damaged&&!p.allowDamaged)return fail('DAMAGED_STORAGE');
    try { const actual=localStorage.getItem(key); if(actual!==raw)return fail('EXTERNAL_CHANGE'); } catch(e) { stored=false; }
    state={...p.next,revision:state.revision+1};if(p.effect.action==='import')automation=false;let persisted=false;
    try { const encoded=JSON.stringify(state);localStorage.setItem(key,encoded);raw=encoded;stored=true;damaged=false;persisted=true; }catch(e){stored=false;}
    const result={ok:true,data:{revision:state.revision,selectedId:p.selectedId,persisted,effect:clone(p.effect)}};
    completed.set(token,result);if(completed.size>100)completed.delete(completed.keys().next().value);plans.delete(token);return clone(result);
  }
  const backup=()=>({schema:'payback.backup',version:1,createdAt:new Date().toISOString(),data:clone({devices:state.devices,trash:state.trash,preferences:state.preferences})});
  return { snapshot, metrics, today, uid, currencies, categories, validateDevice, preview, commit, backup, original:()=>raw, setBusy:v=>busy=Boolean(v), enableAutomation:v=>automation=Boolean(v), agentWriteEnabled:()=>automation };
};
