<template>
  <div class="summary-page">
    <header class="page-header">
      <h1 class="page-title">汇总看板</h1>
      <p class="page-desc">问题图与整改图一一配对展示，按 #key 从小到大排序；每组含检查项、扣分值与上传时间</p>
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
              <el-tag
                :type="r.status === 'completed' ? 'success' : 'warning'"
                size="small"
                class="record-tag"
                effect="light"
              >
                {{ r.status === 'completed' ? '已整改' : '待整改' }}
              </el-tag>
            </div>

            <div class="record-images">
              <div class="record-img-wrap issue">
                <span class="img-label">问题</span>
                <el-image
                  v-if="r.issue_image"
                  :src="imageUrl(r.issue_image)"
                  alt="问题图"
                  fit="cover"
                  class="record-img"
                  :preview-src-list="[imageUrl(r.issue_image)]"
                  preview-teleported
                  hide-on-click-modal
                >
                  <template #error>
                    <div class="img-error">图片加载失败</div>
                  </template>
                </el-image>
                <div v-else class="img-error">无问题图</div>
              </div>

              <div class="record-arrow" aria-hidden="true">
                <el-icon v-if="r.status === 'completed'" class="text-success"><CircleCheck /></el-icon>
                <span v-else class="text-muted">→</span>
              </div>

              <div class="record-img-wrap fix">
                <span class="img-label">整改</span>
                <el-image
                  v-if="r.fix_image"
                  :src="imageUrl(r.fix_image)"
                  alt="整改图"
                  fit="cover"
                  class="record-img"
                  :preview-src-list="[imageUrl(r.fix_image)]"
                  preview-teleported
                  hide-on-click-modal
                >
                  <template #error>
                    <div class="img-error">图片加载失败</div>
                  </template>
                </el-image>
                <div v-else class="record-placeholder">
                  <el-icon class="placeholder-icon"><PictureFilled /></el-icon>
                  <span>待整改</span>
                </div>
              </div>
            </div>

            <div class="record-footer">
              <span class="record-time">
                <el-icon><Clock /></el-icon>
                问题图上传：{{ formatTime(r.created_at) || '—' }}
              </span>
              <span v-if="r.fix_image" class="record-time fix-time">
                <el-icon><CircleCheck /></el-icon>
                整改图上传：{{ formatTime(r.fixed_at) || '—' }}
              </span>
              <span v-else class="record-time fix-time pending">
                <el-icon><PictureFilled /></el-icon>
                整改图：待整改
              </span>
              <span v-if="r.check_date" class="record-date">检查日期：{{ r.check_date }}</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { CircleCheck, Clock, DataAnalysis, PictureFilled } from '@element-plus/icons-vue'
import { api, apiBase } from '@/api/request'

const loading = ref(true)
const summary = ref([])

function imageUrl(path) {
  if (!path) return ''
  const base = apiBase() || (typeof window !== 'undefined' ? window.location.origin : '')
  return path.startsWith('http') ? path : (base.replace(/\/$/, '') + path)
}

// 兼容后端 datetime（"2026-10-02 09:30:00"）与 ISO 格式，输出 YYYY-MM-DD HH:mm
function formatTime(value) {
  if (!value) return ''
  let d
  if (typeof value === 'string') {
    d = new Date(value.includes('T') ? value : value.replace(' ', 'T'))
  } else {
    d = new Date(value)
  }
  if (Number.isNaN(d.getTime())) return ''
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}`
}

async function loadSummary() {
  loading.value = true
  try {
    const data = await api.getSummary()
    // 前端兜底：确保每位员工的记录都按 key 从小到大
    summary.value = (data || []).map((g) => ({
      ...g,
      records: [...(g.records || [])].sort(
        (a, b) => (Number(a.sequence_key) || 0) - (Number(b.sequence_key) || 0)
      ),
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
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
}

.record-item {
  background: #fafbfc;
  border-radius: 12px;
  padding: 16px;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-width: 0;
  transition: box-shadow 0.2s;
}

.record-item:hover {
  box-shadow: 0 4px 12px rgb(0 0 0 / 0.06);
}

.record-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.record-seq {
  background: rgba(14, 165, 233, 0.12);
  color: #0ea5e9;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}

.badge-name {
  font-size: 14px;
  font-weight: 600;
  color: #334155;
  min-width: 0;
}

.badge-score {
  font-size: 13px;
  font-weight: 700;
  color: #ef4444;
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
  flex: 1 1 0;
  min-width: 0;
  border-radius: 10px;
  overflow: hidden;
  background: #e2e8f0;
  aspect-ratio: 4/3;
}

.record-img-wrap.issue .img-label {
  background: rgba(239, 68, 68, 0.92);
}

.record-img-wrap.fix .img-label {
  background: rgba(16, 185, 129, 0.92);
}

.record-img {
  width: 100%;
  height: 100%;
  display: block;
  cursor: zoom-in;
}

.img-label {
  position: absolute;
  top: 6px;
  left: 6px;
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  z-index: 1;
  line-height: 1.4;
}

.img-error {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  color: #94a3b8;
  background: #f1f5f9;
}

.record-arrow {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #94a3b8;
  width: 20px;
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
  font-weight: 500;
  color: #b45309;
  background: repeating-linear-gradient(
    -45deg,
    #fffbeb,
    #fffbeb 10px,
    #fef3c7 10px,
    #fef3c7 20px
  );
}

.placeholder-icon {
  font-size: 22px;
  color: #f59e0b;
}

.record-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  flex-wrap: wrap;
  border-top: 1px dashed #e2e8f0;
  padding-top: 10px;
}

.record-time,
.record-date {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #64748b;
}

.record-time .el-icon {
  font-size: 13px;
  color: #94a3b8;
}

.record-time.fix-time {
  color: #047857;
}

.record-time.fix-time .el-icon {
  color: #10b981;
}

.record-time.fix-time.pending {
  color: #b45309;
}

.record-time.fix-time.pending .el-icon {
  color: #f59e0b;
}

/* ===== 手机端：整组纵向排列，问题图/整改图上下堆叠且保持足够大 ===== */
@media (max-width: 640px) {
  .summary-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 14px;
    padding: 16px;
  }

  .summary-stats {
    width: 100%;
    gap: 0;
    justify-content: space-between;
  }

  .summary-records {
    padding: 14px;
    grid-template-columns: 1fr;
    gap: 14px;
  }

  .record-item {
    padding: 14px;
  }

  .badge-name {
    font-size: 13px;
  }

  /* 问题 → 箭头 → 整改 改为上下布局，两张图占满整行宽度，手机上看得清 */
  .record-images {
    flex-direction: column;
    gap: 8px;
  }

  .record-arrow {
    width: auto;
    height: 20px;
    transform: rotate(90deg);
  }

  .record-img-wrap {
    aspect-ratio: 16/10;
  }

  .record-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}
</style>
