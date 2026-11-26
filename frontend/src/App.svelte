<script>
  import { api } from './lib/api.js';

  let health = $state(null);
  let error = $state('');

  async function check() {
    error = '';
    health = null;
    try {
      health = await api.get('/health');
    } catch (e) {
      error = e.message;
    }
  }

  check();
</script>

<main>
  <h1>Rewang</h1>
  <p>Svelte + PHP + MySQL siap dipakai.</p>

  <section class="card">
    <h2>Status API</h2>
    {#if error}
      <p class="bad">API error: {error}</p>
    {:else if !health}
      <p>Memeriksa…</p>
    {:else}
      <p>API: <strong class="ok">{health.status}</strong></p>
      <p>
        Database:
        <strong class={health.database === 'connected' ? 'ok' : 'bad'}>{health.database}</strong>
      </p>
      <p class="muted">PHP {health.php}</p>
    {/if}
    <button onclick={check}>Cek ulang</button>
  </section>
</main>

<style>
  main {
    max-width: 640px;
    margin: 0 auto;
    padding: 2rem 1rem;
  }
  .card {
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 1rem 1.25rem;
  }
  .ok { color: var(--ok); }
  .bad { color: var(--bad); }
  .muted { color: var(--muted); font-size: 0.9rem; }
  button {
    padding: 0.5rem 1rem;
    border-radius: 6px;
    border: 1px solid var(--border);
    background: var(--surface);
    color: inherit;
    cursor: pointer;
  }
</style>
