import 'dotenv/config';
import express from 'express';
import multer from 'multer';
import crypto from 'node:crypto';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const app = express();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 }, // 单图上限 15MB
});

const API_KEY = process.env.PLANTNET_API_KEY;
const PROJECT = process.env.PLANTNET_PROJECT || 'all';
const BASE = process.env.PLANTNET_BASE || 'https://my-api.plantnet.org/v2/identify';
const PORT = process.env.PORT || 3000;

// ---- Cloudflare R2（头像存储）----
const R2_ENDPOINT = process.env.R2_ENDPOINT; // https://<account_id>.r2.cloudflarestorage.com
const R2_ACCESS_KEY_ID = process.env.R2_ACCESS_KEY_ID;
const R2_SECRET_ACCESS_KEY = process.env.R2_SECRET_ACCESS_KEY;
const R2_BUCKET = process.env.R2_BUCKET || 'circleplant-avatars';
const R2_PUBLIC_URL = process.env.R2_PUBLIC_URL || 'https://avatar.roundplant.com';

const r2 =
  R2_ENDPOINT && R2_ACCESS_KEY_ID && R2_SECRET_ACCESS_KEY
    ? new S3Client({
        region: 'auto',
        endpoint: R2_ENDPOINT,
        credentials: {
          accessKeyId: R2_ACCESS_KEY_ID,
          secretAccessKey: R2_SECRET_ACCESS_KEY,
        },
      })
    : null;

// 头像上传：收图 → 转存 R2 → 返回公开 URL（App 端已压到 512px，这里不再压缩）
app.post('/upload-avatar', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: '缺少图片' });
  }
  if (!r2) {
    return res.status(500).json({ success: false, error: '服务端未配置 R2 凭证' });
  }
  try {
    const key = `${crypto.randomUUID()}.jpg`;
    await r2.send(
      new PutObjectCommand({
        Bucket: R2_BUCKET,
        Key: key,
        Body: req.file.buffer,
        ContentType: req.file.mimetype || 'image/jpeg',
        CacheControl: 'public, max-age=31536000, immutable',
      })
    );
    res.json({ success: true, url: `${R2_PUBLIC_URL}/${key}` });
  } catch (e) {
    console.error('[R2 upload error]', e);
    res.status(500).json({ success: false, error: String(e) });
  }
});

// 接收 APP 上传的图片，转发给 Pl@ntNet，返回简化结果
app.post('/api/identify', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: '缺少图片' });
  }
  if (!API_KEY) {
    return res.status(500).json({ success: false, error: '服务端未配置 PLANTNET_API_KEY' });
  }

  const organ = (req.body.organ || 'auto').toString();
  const url = `${BASE}/${PROJECT}?api-key=${API_KEY}`;

  try {
    const fd = new FormData();
    fd.append(
      'images',
      new Blob([req.file.buffer], { type: req.file.mimetype || 'image/jpeg' }),
      req.file.originalname || 'plant.jpg'
    );
    fd.append('organs', organ);

    // Pl@ntNet 国际 API 偶尔很慢：30 秒超时快速失败，不再让 APP 干等
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 30000);
    let r;
    try {
      r = await fetch(url, { method: 'POST', body: fd, signal: controller.signal });
    } finally {
      clearTimeout(timer);
    }
    if (!r.ok) {
      const text = await r.text();
      console.error('[Pl@ntNet error]', r.status, text.slice(0, 500));
      return res
        .status(r.status)
        .json({ success: false, error: `Pl@ntNet ${r.status}`, detail: text.slice(0, 300) });
    }

    const data = await r.json();
    const results = (data.results || [])
      .slice(0, 5)
      .map((item) => ({
        name:
          (item.species?.commonNames && item.species.commonNames[0]) ||
          item.species?.scientificNameWithoutAuthor ||
          '未知植物',
        scientificName: item.species?.scientificNameWithoutAuthor || '',
        score: Math.round((item.score || 0) * 100) / 100,
        family: item.species?.family?.scientificName || '',
        commonNames: item.species?.commonNames || [],
      }));

    res.json({ success: true, results });
  } catch (e) {
    console.error('[Proxy exception]', e);
    // 超时（AbortError）给 APP 明确的"服务繁忙"而不是让前端干等
    if (e.name === 'AbortError') {
      return res
        .status(504)
        .json({ success: false, error: '识别服务繁忙，请稍后再试' });
    }
    res.status(500).json({ success: false, error: String(e) });
  }
});

// 天气代理：转发 Open-Meteo，根据天气码返回养护建议
app.get('/api/weather', async (req, res) => {
  const lat = req.query.lat || '39.9042'; // 默认北京
  const lon = req.query.lon || '116.4074';
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true`;

  try {
    const r = await fetch(url);
    if (!r.ok) {
      const text = await r.text();
      console.error('[Weather error]', r.status, text.slice(0, 200));
      return res.status(r.status).json({ success: false, error: `Open-Meteo ${r.status}` });
    }
    const data = await r.json();
    const cw = data.current_weather || {};
    const code = cw.weathercode ?? 0;
    const temp = cw.temperature ?? 0;
    res.json({ success: true, temp, weatherCode: code, suggestion: weatherSuggestion(code, temp) });
  } catch (e) {
    console.error('[Weather exception]', e);
    res.status(500).json({ success: false, error: String(e) });
  }
});

function weatherSuggestion(code, temp) {
  if (code >= 51 && code <= 67) return '🌧 雨天湿度大，建议减少浇水';
  if (code >= 71 && code <= 77) return '❄️ 天气寒冷，帮植物远离窗边';
  if (code >= 80 && code <= 82) return '🌦 阵雨刚过，观察土壤再浇水';
  if (code >= 95) return '⛈ 雷雨来袭，记得把植物搬进室内';
  if (temp > 32) return '☀️ 今天很热，早晚浇水更合适';
  if (temp < 5) return '🧊 天气很冷，减少浇水防冻伤';
  if (code <= 3) return '☀️ 今天阳光充足，适合浇水';
  return '🌤 天气不错，看看植物状态吧';
}

app.get('/healthz', (_req, res) => res.json({ ok: true }));

app.listen(PORT, () => {
  console.log(`[roundplant-ai-proxy] listening on :${PORT}`);
  if (!API_KEY) console.warn('[WARN] PLANTNET_API_KEY 未设置，识别接口将不可用');
});
