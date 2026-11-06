import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useHealthStore } from '../health'

describe('health store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('marks the stack healthy when every service responds', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ api: 'ok', database: 'ok' }),
      }),
    )

    const store = useHealthStore()
    await store.check()

    expect(store.allHealthy).toBe(true)
    expect(store.errorMessage).toBeNull()
    expect(fetch).toHaveBeenCalledWith('/api/health', {
      headers: { Accept: 'application/json' },
    })
  })

  it('keeps API healthy while exposing a database failure', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 503,
        json: () => Promise.resolve({ api: 'ok', database: 'error' }),
      }),
    )

    const store = useHealthStore()
    await store.check()

    expect(store.api).toBe('ok')
    expect(store.database).toBe('error')
    expect(store.errorMessage).toContain('503')
  })

  it('marks the API unavailable after a network error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('connection refused')))

    const store = useHealthStore()
    await store.check()

    expect(store.api).toBe('error')
    expect(store.database).toBe('error')
    expect(store.errorMessage).toBe('connection refused')
  })
})
