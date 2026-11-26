// Menyalin backend PHP ke dist/api setelah `vite build`,
// sehingga isi dist/ tinggal di-upload ke public_html.
import { cpSync, existsSync } from 'node:fs';
import { basename, join } from 'node:path';

const src = 'api';
const dest = join('dist', 'api');

if (!existsSync('dist')) {
  console.error('Folder dist/ belum ada. Jalankan vite build dulu.');
  process.exit(1);
}

// config.php berisi kredensial lokal: tidak ikut ke hasil build.
const skip = new Set(['config.php']);

cpSync(src, dest, {
  recursive: true,
  filter: (path) => !skip.has(basename(path)),
});

console.log('✓ api/ disalin ke dist/api (tanpa config.php)');
