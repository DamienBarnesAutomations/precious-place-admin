import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig(({ mode }) => {
  // Load env file FIRST, before returning config
  const env = loadEnv(mode, process.cwd(), '')
  return {

  plugins: [
    vue(),
    tailwindcss(),
    {
      name: 'html-transform',
      transformIndexHtml(html) {
        return html.replace(
          /%(.*?)%/g,
          (match, p1) => env[p1] || match
        )
      }
    }
  ],
  server: {
    allowedHosts: [
      env.DOMAIN_OR_IP
    ],
    watch: {
      usePolling: true,
    },
    host: true, // Needed for Docker mapping
    port: 5173,
    hmr: {
      clientPort: 443, // Force the browser to look for HMR on the SSL port
    },
  },
  base: '/pos/'
}
})