const M = (1n << 64n) - 1n;
const k0 = 0xc3a5c85c97cb3127n, k1 = 0xb492b66fbe98f273n, k2 = 0x9ae16a3b2f90404fn, kMul = 0x9ddfea08eb382d69n;
const m = x => x & M;
const rot = (v, s) => s === 0 ? v : m((v >> BigInt(s)) | (v << BigInt(64 - s)));
const smix = v => v ^ (v >> 47n);
const bswap = v => { let r = 0n; for (let i = 0; i < 8; i++) { r = (r << 8n) | (v & 0xffn); v >>= 8n; } return r; };
function h16(u, v, mul = kMul) { let a = m((u ^ v) * mul); a ^= a >> 47n; let b = m((v ^ a) * mul); b ^= b >> 47n; return m(b * mul); }
function cityHash64(buf) {
  const f64 = o => buf.readBigUInt64LE(o), f32 = o => BigInt(buf.readUInt32LE(o));
  let len = buf.length; const L = BigInt(len);
  if (len <= 16) {
    if (len >= 8) { const mul = m(k2 + L * 2n), a = m(f64(0) + k2), b = f64(len - 8); const c = m(rot(b, 37) * mul + a), d = m((rot(a, 25) + b) * mul); return h16(c, d, mul); }
    if (len >= 4) { const mul = m(k2 + L * 2n), a = f32(0); return h16(m(L + (a << 3n)), f32(len - 4), mul); }
    if (len > 0) { const a = BigInt(buf[0]), b = BigInt(buf[len >> 1]), c = BigInt(buf[len - 1]); const y = (a + (b << 8n)) & 0xffffffffn, z = L + (c << 2n); return m(smix(m(m(y * k2) ^ m(z * k0))) * k2); }
    return k2;
  }
  if (len <= 32) { const mul = m(k2 + L * 2n), a = m(f64(0) * k1), b = f64(8), c = m(f64(len - 8) * mul), d = m(f64(len - 16) * k2); return h16(m(rot(m(a + b), 43) + rot(c, 30) + d), m(a + rot(m(b + k2), 18) + c), mul); }
  if (len <= 64) {
    const mul = m(k2 + L * 2n); let a = m(f64(0) * k2), b = f64(8); const c = f64(len - 24), d = f64(len - 32), e = m(f64(16) * k2), f = m(f64(24) * 9n), g = f64(len - 8), h = m(f64(len - 16) * mul);
    const u = m(rot(m(a + g), 43) + m((rot(b, 30) + c) * 9n)), v = m(((m(a + g)) ^ d) + f + 1n), w = m(bswap(m((u + v) * mul)) + h), x = m(rot(m(e + f), 42) + c), y = m((bswap(m((v + w) * mul)) + g) * mul), z = m(e + f + c);
    a = m(bswap(m(m((x + z) * mul) + y)) + b); b = m(smix(m(m((z + a) * mul) + d + h)) * mul); return m(b + x);
  }
  const weak = (o, a, b) => { const w = f64(o), x = f64(o + 8), y = f64(o + 16), z = f64(o + 24); a = m(a + w); b = rot(m(b + a + z), 21); const c = a; a = m(a + x + y); b = m(b + rot(a, 44)); return [m(a + z), m(b + c)]; };
  let x = f64(len - 40), y = m(f64(len - 16) + f64(len - 56)), z = h16(m(f64(len - 48) + L), f64(len - 24));
  let v = weak(len - 64, L, z), w = weak(len - 32, m(y + k1), x);
  x = m(m(x * k1) + f64(0));
  let rem = (len - 1) & ~63, s = 0;
  do {
    x = m(rot(m(x + y + v[0] + f64(s + 8)), 37) * k1); y = m(rot(m(y + v[1] + f64(s + 48)), 42) * k1); x ^= w[1]; y = m(y + v[0] + f64(s + 40)); z = m(rot(m(z + w[0]), 33) * k1);
    v = weak(s, m(v[1] * k1), m(x + w[0])); w = weak(s + 32, m(z + w[1]), m(y + f64(s + 16)));
    [z, x] = [x, z]; s += 64; rem -= 64;
  } while (rem !== 0);
  return h16(m(h16(v[0], w[0]) + m(smix(y) * k1) + z), m(h16(v[1], w[1]) + x));
}
function ueTextKeyHash(str) {
  if (str === "") return 0;
  const h = cityHash64(Buffer.from(str, 'utf16le'));
  return Number((((h & 0xffffffffn) + ((h >> 32n) * 23n)) & 0xffffffffn));
}
module.exports = { cityHash64, ueTextKeyHash };
