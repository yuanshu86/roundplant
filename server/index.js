import 'dotenv/config';
import express from 'express';
import multer from 'multer';

const app = express();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 }, // 单图上限 15MB
});

const API_KEY = process.env.PLANTNET_API_KEY;
const PROJECT = process.env.PLANTNET_PROJECT || 'all';
const BASE = process.env.PLANTNET_BASE || 'https://my-api.plantnet.org/v2/identify';
const PORT = process.env.PORT || 3000;

// 接收 APP 上传的图片，转发给 Pl@ntNet，返回简化结果
app.post('/api/identify', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: '缺少图片' });
  }
  if (!API_KEY) {
    return res.status(500).json({ success: false, error: '服务端未配置 PLANTNET_API_KEY' });
  }

  const organ = (req.body.organ || 'auto').toString();
  const url = `${BASE}/${PROJECT}?api-key=${API_KEY}&organs=${encodeURIComponent(organ)}`;

  try {
    const fd = new FormData();
    fd.append(
      'images',
      new Blob([req.file.buffer], { type: req.file.mimetype || 'image/jpeg' }),
      req.file.originalname || 'plant.jpg'
    );
    fd.append('organs', organ);

    const r = await fetch(url, { method: 'POST', body: fd });
    if (!r.ok) {
      const text = await r.text();
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
    res.status(500).json({ success: false, error: String(e) });
  }
});

app.get('/healthz', (_req, res) => res.json({ ok: true }));

app.listen(PORT, () => {
  console.log(`[roundplant-ai-proxy] listening on :${PORT}`);
  if (!API_KEY) console.warn('[WARN] PLANTNET_API_KEY 未设置，识别接口将不可用');
});
