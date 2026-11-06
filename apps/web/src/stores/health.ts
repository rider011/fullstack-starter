import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

export type ServiceState = 'loading' | 'ok' | 'error'

interface HealthResponse {
  api?: unknown
  database?: unknown
}

export const useHealthStore = defineStore('health', () => {
  const api = ref<ServiceState>('loading')
  const database = ref<ServiceState>('loading')
  const checking = ref(false)
  const errorMessage = ref<string | null>(null)
  const lastChecked = ref<string | null>(null)

  const allHealthy = computed(() => api.value === 'ok' && database.value === 'ok')

  async function check(): Promise<void> {
    checking.value = true
    api.value = 'loading'
    database.value = 'loading'
    errorMessage.value = null

    try {
      const response = await fetch('/api/health', {
        headers: { Accept: 'application/json' },
      })
      const payload = (await response.json()) as HealthResponse

      api.value = payload.api === 'ok' ? 'ok' : 'error'
      database.value = payload.database === 'ok' ? 'ok' : 'error'

      if (!response.ok) {
        errorMessage.value = `服务返回 HTTP ${response.status}，请检查数据库连接。`
      }
    } catch (error) {
      api.value = 'error'
      database.value = 'error'
      errorMessage.value =
        error instanceof Error ? error.message : '无法连接到 API，请确认后端已启动。'
    } finally {
      checking.value = false
      lastChecked.value = new Date().toLocaleTimeString('zh-CN', { hour12: false })
    }
  }

  return { api, database, checking, errorMessage, lastChecked, allHealthy, check }
})
