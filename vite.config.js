import { defineConfig, loadEnv } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    root: 'frontend',
    // Ganti VITE_BASE di .env kalau aplikasi dipasang di subfolder, mis. /rewang/
    base: env.VITE_BASE || '/',
    envDir: '..',
    plugins: [svelte()],
    server: {
      port: 5173,
      proxy: {
        // Saat development, /api diteruskan ke PHP built-in server
        '/api': 'http://localhost:8000',
      },
    },
    build: {
      outDir: '../dist',
      emptyOutDir: true,
    },
  };
});
