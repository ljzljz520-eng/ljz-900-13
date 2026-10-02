<template>
  <div class="summary-page">
    <header class="page-header">
      <h1 class="page-title">汇总看板</h1>
      <p class="page-desc">问题图与整改图按 #key 从小到大一一配对展示，点击图片可放大查看</p>
    </header>

    <section v-loading="loading" class="summary-section">
      <div v-if="summary.length === 0 && !loading" class="empty-state">
        <div class="empty-icon">
          <el-icon><DataAnalysis /></el-icon>
        </div>
        <p class="empty-text">暂无汇总数据</p>
        <p class="empty-hint">请在检查上传中创建记录</p>
      </div>

      <div v-for="item in summary" :key="item.user?.id" class="summary-card">
        <div class="summary-header">
          <div class="summary-user">
            <div class="user-avatar">{{ (item.user?.name || '员')[0] }}</div>
            <h2 class="summary-name">{{ item.user?.name }}</h2>
          </div>
          <div class="summary-stats">
            <div class="stat">
              <span class="stat-label">整改进度</span>
              <span class="stat-value" :class="item.progress >= 100 ? 'success' : 'primary'">
                {{ item.progress }}%
              </span>
              <span class="stat-detail">（{{ item.completed }}/{{ item.total }}）</span>
            </div>
            <div class="stat">
              <span class="stat-label">扣分合计</span>
              <span class="stat-value danger">-{{ item.total_score }}分</span>
            </div>
          </div>
        </div>
        <div class="summary-records">
          <div
            v-for="r in item.records"
            :key="r.id"
            class="record-item"
          >
            <div class="record-meta">
              <span class="record-seq">#{{ r.sequence_key }}</span>
              <span class="badge-name">{{ r.item_name_snapshot || r.item?.name }}</span>
              <span class="badge-score">-{{ (r.item_score_snapshot ?? r.item?.score) }}分</span>
              <el-tag v-if="r.status === 'completed'" type="success" size="small" class="record-tag">已完成</el-tag>
              <el-tag v-else type="warning" size="small" class="record-tag">待整改</el-tag>
            </div>
            <div class="record-time">
              <el-icon><Clock /></el-icon>
              <span>上传时间：{{ formatTime(r.created_at) }}</span>
            </div>
            <div class="record-images">
              <div class="record-img-wrap" @click="openPreview(r.issue_image)">
                <span class="img-label">问题</span>
                <img
                  :src="imageUrl(r.issue_image)"
                  alt="问题图"
                  @error="(e) => (e.target.style.display = 'none')"
                />
              </div>
              <div class="record-arrow">
                <el-icon v-if="r.status === 'completed'" class="text-success"><CircleCheck /></el-icon>
                <span v-else class="text-muted">→</span>
              </div>
              <div
                class="record-img-wrap"
                :class="{ pending: !r.fix_image }"
                @click="r.fix_image && openPreview(r.fix_image)"
              >
                <span class="img-label">整改</span>
                <img
                  v-if="r.fix_image"
                  :src="imageUrl(r.fix_image)"
                  alt="整改图"
                  @error="(e) => (e.target.style.display = 'none')"
                />
                <div v-else class="record-placeholder">
                  <el-icon class="placeholder-icon"><Camera /></el-icon>
                  <span>待整改</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <el-dialog v-model="previewVisible" title="图片预览" width="92%" class="preview-dialog" append-to-body>
      <img v-if="previewUrl" :src="previewUrl" alt="预览" class="preview-img" />
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Camera, CircleCheck, Clock, DataAnalysis } from '@element-plus/icons-vue'
import { api, apiBase } from '@/api/request'

const loading = ref(true)
const summary = ref([])
const previewVisible = ref(false)
const previewUrl = ref('')

function imageUrl(path) {
  if (!path) return ''
  const base = apiBase() || (typeof window !== 'undefined' ? window.location.origin : '')
  return path.startsWith('http') ? path : (base.replace(/\/$/, '') + path)
}

// created_at 形如 "2026-10-02 14:30:00"，格式化为 "2026-10-02 14:30"
function formatTime(t) {
  if (!t) return '—'
  const d = new Date(String(t).replace(' ', 'T'))
  if (Number.isNaN(d.getTime())) return String(t)
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function openPreview(path) {
  if (!path) return
  previewUrl.value = imageUrl(path)
  previewVisible.value = true
}

async function loadSummary() {
  loading.value = true
  try {
    const data = await api.getSummary()
    // 兜底：确保每组记录按 #key 从小到大排列（后端已按 sequence_key 升序返回）
    summary.value = (Array.isArray(data) ? data : []).map((u) => ({
      ...u,
      records: [...(u.records || [])].sort((a, b) => (a.sequence_key ?? 0) - (b.sequence_key ?? 0)),
    }))
  } catch (_) {
    summary.value = []
  } finally {
    loading.value = false
  }
}

onMounted(loadSummary)
</script>

<style scoped>
.summary-page {
  max-width: 1120px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
}

.page-title {
  font-size: 28px;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 8px;
  letter-spacing: -0.02em;
}

.page-desc {
  font-size: 15px;
  color: #64748b;
  margin: 0;
}

.summary-section {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.empty-state {
  background: white;
  border-radius: 16px;
  padding: 80px 40px;
  text-align: center;
  border: 2px dashed #e2e8f0;
}

.empty-icon {
  width: 80px;
  height: 80px;
  margin: 0 auto 24px;
  border-radius: 20px;
  background: #f1f5f9;
  color: #94a3b8;
  font-size: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.empty-text {
  font-size: 18px;
  font-weight: 500;
  color: #64748b;
  margin: 0 0 8px;
}

.empty-hint {
  font-size: 14px;
  color: #94a3b8;
  margin: 0;
}

.summary-card {
  background: white;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgb(0 0 0 / 0.06);
  border: 1px solid rgba(0, 0, 0, 0.04);
}

.summary-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 20px 24px;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-bottom: 1px solid #e2e8f0;
}

.summary-user {
  display: flex;
  align-items: center;
  gap: 14px;
}

.user-avatar {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: linear-gradient(135deg, #0ea5e9, #06b6d4);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 18px;
}

.summary-name {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.summary-stats {
  display: flex;
  gap: 32px;
}

.stat {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.stat-label {
  font-size: 13px;
  color: #64748b;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
}

.stat-value.primary {
  color: #0ea5e9;
}

.stat-value.success {
  color: #10b981;
}

.stat-value.danger {
  color: #ef4444;
}

.stat-detail {
  font-size: 13px;
  color: #94a3b8;
}

.summary-records {
  padding: 20px 24px;
  display: grid;
  gap: 20px;
  grid-template-columns: repeat(auto-fill, minmax(min(340px, 100%), 1fr));
}

.record-item {
  background: #fafbfc;
  border-radius: 12px;
  padding: 16px;
  border: 1px solid #e2e8f0;
  transition: box-shadow 0.2s;
}

.record-item:hover {
  box-shadow: 0 4px 12px rgb(0 0 0 / 0.06);
}

.record-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.record-seq {
  background: rgba(14, 165, 233, 0.12);
  color: #0ea5e9;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.badge-name {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
}

.badge-score {
  font-size: 13px;
  font-weight: 600;
  color: #ef4444;
  margin-left: 4px;
}

.record-time {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #94a3b8;
  margin: 0 0 10px;
}

.record-item-name {
  font-size: 13px;
  color: #64748b;
}

.img-label {
  position: absolute;
  top: 6px;
  left: 6px;
  background: rgba(0, 0, 0, 0.6);
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  z-index: 1;
}

.record-tag {
  margin-left: auto;
}

.record-images {
  display: flex;
  align-items: stretch;
  gap: 12px;
}

.record-img-wrap {
  position: relative;
  flex: 1;
  min-width: 0;
  border-radius: 8px;
  overflow: hidden;
  background: #e2e8f0;
  aspect-ratio: 4/3;
  cursor: zoom-in;
}

.record-img-wrap.pending {
  background: #f8fafc;
  border: 1.5px dashed #cbd5e1;
  cursor: default;
}

.record-img-wrap:first-of-type .img-label {
  background: rgba(239, 68, 68, 0.9);
}

.record-img-wrap:last-of-type .img-label {
  background: rgba(16, 185, 129, 0.9);
}

/* 待整改占位：标签置灰，覆盖上面的绿色 */
.record-img-wrap.pending .img-label {
  background: rgba(148, 163, 184, 0.9);
}

.record-img-wrap img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.record-arrow {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  font-size: 20px;
  color: #94a3b8;
}

.text-success {
  color: #10b981;
  font-size: 24px;
}

.text-muted {
  color: #94a3b8;
}

.record-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 13px;
  color: #94a3b8;
}

.placeholder-icon {
  font-size: 22px;
  color: #cbd5e1;
}

.preview-dialog :deep(.el-dialog) {
  max-width: 900px;
}

.preview-img {
  width: 100%;
  border-radius: 8px;
  display: block;
}

/* 手机适配：小屏下单列、收紧间距，保证图片对和文字清晰可读 */
@media (max-width: 768px) {
  .page-header {
    margin-bottom: 20px;
  }

  .page-title {
    font-size: 22px;
  }

  .page-desc {
    font-size: 13px;
  }

  .summary-section {
    gap: 16px;
  }

  .summary-header {
    padding: 14px 16px;
    gap: 12px;
  }

  .summary-name {
    font-size: 17px;
  }

  .user-avatar {
    width: 38px;
    height: 38px;
    font-size: 16px;
  }

  .summary-stats {
    gap: 20px;
  }

  .stat-value {
    font-size: 17px;
  }

  .summary-records {
    padding: 14px;
    gap: 14px;
    grid-template-columns: 1fr;
  }

  .record-item {
    padding: 12px;
  }

  .record-images {
    gap: 8px;
  }

  .record-arrow {
    font-size: 16px;
  }

  .text-success {
    font-size: 20px;
  }
}

@media (max-width: 400px) {
  .record-meta {
    gap: 6px;
  }

  .record-tag {
    margin-left: 0;
  }

  .record-images {
    gap: 6px;
  }
}
</style>
