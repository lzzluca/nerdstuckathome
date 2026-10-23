import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://nerdstuckathome.com',
  // Strict CSP (no 'unsafe-inline' for styles): emit every stylesheet as a file
  // and highlight code with classes instead of inline style attributes.
  build: { inlineStylesheets: 'never' },
  markdown: { syntaxHighlight: 'prism' },
});
