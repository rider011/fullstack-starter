<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="site-shell">
    <header class="topbar">
      <RouterLink class="brand" to="/">
        <span class="brand-mark">FS</span>
        <span>Fullstack Starter</span>
      </RouterLink>
      <span class="environment">local development</span>
    </header>

    <RouterView />
  </div>
</template>

<style scoped>
.site-shell {
  min-height: 100vh;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: min(1120px, calc(100% - 2rem));
  margin: 0 auto;
  padding: 1.5rem 0;
  border-bottom: 1px solid var(--color-border);
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 0.75rem;
  color: var(--color-heading);
  font-weight: 700;
  letter-spacing: -0.02em;
}

.brand-mark {
  display: grid;
  place-items: center;
  width: 2rem;
  height: 2rem;
  border-radius: 0.65rem;
  color: #fff;
  background: #42b883;
  font-size: 0.75rem;
  letter-spacing: 0.05em;
}

.environment {
  color: var(--color-text);
  font-family: 'Cascadia Code', Consolas, monospace;
  font-size: 0.75rem;
}

@media (max-width: 560px) {
  .environment {
    display: none;
  }
}
</style>
