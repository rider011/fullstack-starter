<script setup lang="ts">
import { onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useHealthStore } from '@/stores/health'

const healthStore = useHealthStore()
const { api, database, checking, errorMessage, lastChecked } = storeToRefs(healthStore)

onMounted(() => {
  void healthStore.check()
})
</script>

<template>
  <main class="hero">
    <section class="intro">
      <p class="eyebrow">Vue 3 + NestJS + PostgreSQL</p>
      <h1>全栈开发基线已经就位。</h1>
      <p class="lead">
        这是一个用于验证本地开发链路的示例页。Vue 通过 Vite 代理访问 NestJS，NestJS
        再通过 Prisma 检查 PostgreSQL。
      </p>

      <button class="refresh" type="button" :disabled="checking" @click="healthStore.check">
        {{ checking ? '检测中…' : '重新检测' }}
      </button>
    </section>

    <section class="status-panel" aria-label="服务状态">
      <div class="status-row">
        <div>
          <span class="status-label">Frontend</span>
          <strong>Vue + Vite</strong>
        </div>
        <span class="badge ok">ready</span>
      </div>

      <div class="status-row">
        <div>
          <span class="status-label">API</span>
          <strong>NestJS</strong>
        </div>
        <span class="badge" :class="api">{{ api }}</span>
      </div>

      <div class="status-row">
        <div>
          <span class="status-label">Database</span>
          <strong>PostgreSQL 18</strong>
        </div>
        <span class="badge" :class="database">{{ database }}</span>
      </div>

      <p v-if="errorMessage" class="error-message">{{ errorMessage }}</p>
      <p class="checked-at">
        {{ lastChecked ? `最近检测：${lastChecked}` : '等待首次检测' }}
      </p>
    </section>
  </main>
</template>

<style scoped>
.hero {
  display: grid;
  grid-template-columns: minmax(0, 1.35fr) minmax(320px, 0.8fr);
  gap: 4rem;
  align-items: center;
  width: min(1120px, calc(100% - 2rem));
  min-height: calc(100vh - 82px);
  margin: 0 auto;
  padding: 4rem 0;
}

.intro {
  max-width: 680px;
}

.eyebrow {
  margin-bottom: 1.5rem;
  color: #42b883;
  font-family: 'Cascadia Code', Consolas, monospace;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

h1 {
  max-width: 620px;
  color: var(--color-heading);
  font-size: clamp(2.75rem, 7vw, 5.5rem);
  font-weight: 700;
  letter-spacing: -0.065em;
  line-height: 0.98;
}

.lead {
  max-width: 620px;
  margin-top: 2rem;
  color: var(--color-text);
  font-size: 1.05rem;
  line-height: 1.9;
}

.refresh {
  margin-top: 2rem;
  padding: 0.8rem 1.15rem;
  border: 0;
  border-radius: 0.7rem;
  color: #fff;
  background: #1f2937;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}

.refresh:hover:not(:disabled) {
  background: #42b883;
}

.refresh:disabled {
  cursor: wait;
  opacity: 0.65;
}

.status-panel {
  padding: 1.1rem 1.4rem 0.55rem;
  border: 1px solid var(--color-border);
  border-radius: 1.25rem;
  background: var(--color-background-soft);
  box-shadow: 0 24px 70px rgba(24, 24, 24, 0.08);
}

.status-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.1rem 0;
  border-bottom: 1px solid var(--color-border);
}

.status-row div {
  display: flex;
  flex-direction: column;
}

.status-label {
  color: var(--color-text);
  font-size: 0.72rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.status-row strong {
  color: var(--color-heading);
  font-size: 0.95rem;
}

.badge {
  min-width: 4.5rem;
  padding: 0.28rem 0.55rem;
  border-radius: 999px;
  font-family: 'Cascadia Code', Consolas, monospace;
  font-size: 0.68rem;
  text-align: center;
  text-transform: uppercase;
}

.badge.ok {
  color: #116c49;
  background: #d9f7ea;
}

.badge.error {
  color: #9f2f2f;
  background: #ffe5e5;
}

.badge.loading {
  color: #5d6472;
  background: #e8ebf0;
}

.error-message {
  margin-top: 1rem;
  color: #9f2f2f;
  font-size: 0.82rem;
}

.checked-at {
  padding: 1rem 0;
  color: var(--color-text);
  font-family: 'Cascadia Code', Consolas, monospace;
  font-size: 0.72rem;
}

@media (max-width: 860px) {
  .hero {
    grid-template-columns: 1fr;
    gap: 2.5rem;
    padding: 3rem 0;
  }
}
</style>
