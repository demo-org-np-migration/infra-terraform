'use strict';

// Mock de un vendor externo. Node puro, sin dependencias, para que la imagen
// sea liviana y no dependa de npm install en el build. VENDOR selecciona qué
// vendor imitar; MODE es sandbox|live (hoy no cambia el comportamiento, solo
// viaja para que los logs digan de qué Deployment vino la respuesta).

const http = require('http');

const VENDOR = process.env.VENDOR || 'unknown';
const MODE = process.env.MODE || 'sandbox';
const PORT = parseInt(process.env.PORT || '8080', 10);

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
    });
    req.on('end', () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch (err) {
        reject(err);
      }
    });
    req.on('error', reject);
  });
}

function sendJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(payload);
}

function log(msg, extra) {
  console.log(
    JSON.stringify({
      level: 'info',
      msg,
      service: `vendor-mock-${VENDOR}`,
      env: MODE,
      ...extra,
    })
  );
}

// hash determinístico simple (no cripto, solo para dar resultados estables)
function stableFraction(seed) {
  let h = 0;
  for (let i = 0; i < seed.length; i++) {
    h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  }
  return (h % 1000) / 1000; // [0, 1)
}

const routes = {
  // Cardnet
  'POST /v1/cards/issue': async (body) => ({
    card_token: `tok_${stableFraction(body.account_id || 'x').toString(36).slice(2, 10)}`,
    pan_last4: String(1000 + Math.floor(stableFraction(JSON.stringify(body)) * 9000)).slice(0, 4),
    expiry: '12/29',
  }),
  'POST /v1/authorizations': async (body) => ({
    auth_code: `auth_${stableFraction(JSON.stringify(body)).toString(36).slice(2, 10)}`,
    status: stableFraction(JSON.stringify(body)) > 0.1 ? 'approved' : 'declined',
  }),

  // Sentinel
  'POST /v2/assess': async (body) => {
    const amount = parseFloat(body.amount || '0');
    let risk;
    if (amount > 100000) {
      risk = 0.9;
    } else {
      // determinístico en [0.1, 0.3) según el payload
      risk = 0.1 + stableFraction(JSON.stringify(body)) * 0.2;
    }
    return { risk: Number(risk.toFixed(3)), signals: risk > 0.5 ? ['high_amount'] : [] };
  },

  // Veridoc
  'POST /v1/verify': async (body) => {
    const f = stableFraction(body.customer_id || 'x');
    const result = f > 0.85 ? 'manual_review' : f > 0.5 ? 'approved' : 'approved';
    return { result, reference: `ver_${f.toString(36).slice(2, 10)}` };
  },

  // OpenFX
  'GET /v1/latest': async (_body, query) => ({
    base: query.base || 'USD',
    rates: { ARS: 1000.5, BRL: 5.4, MXN: 18.2, EUR: 0.92 },
    timestamp: new Date().toISOString(),
  }),

  // Mailgunner
  'POST /v3/messages': async (body) => ({
    id: `msg_${stableFraction(JSON.stringify(body)).toString(36).slice(2, 10)}`,
  }),

  // Pushly
  'POST /v1/push': async (body) => ({
    id: `push_${stableFraction(JSON.stringify(body)).toString(36).slice(2, 10)}`,
  }),
};

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === 'GET' && url.pathname === '/health') {
    return sendJson(res, 200, { status: 'ok' });
  }
  if (req.method === 'GET' && url.pathname === '/metrics') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    return res.end(`# HELP vendor_mock_up 1 if the mock is up\nvendor_mock_up{vendor="${VENDOR}",mode="${MODE}"} 1\n`);
  }

  const key = `${req.method} ${url.pathname}`;
  const handler = routes[key];

  if (!handler) {
    log('unhandled route', { path: url.pathname, method: req.method });
    return sendJson(res, 404, { error: { code: 'not_found', message: `no route for ${key}` } });
  }

  try {
    const body = await readBody(req);
    const query = Object.fromEntries(url.searchParams.entries());
    const result = await handler(body, query);
    log('handled', { path: url.pathname, method: req.method });
    return sendJson(res, 200, result);
  } catch (err) {
    log('error handling request', { error: String(err) });
    return sendJson(res, 400, { error: { code: 'bad_request', message: 'invalid body' } });
  }
});

server.listen(PORT, () => {
  log(`vendor-mock listening`, { vendor: VENDOR, mode: MODE, port: PORT });
});
