import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 8080,
    proxy: {
      '/api': {
        target: 'http://localhost:4000',
        changeOrigin: true,
        secure: false,
        ws: true,
        configure: (proxy, _options) => {
          proxy.on('error', (err, _req, _res) => {
            console.log('proxy error', err);
          });
          proxy.on('proxyReq', (proxyReq, _req, _res) => {
            console.log('Sending Request to the Target:', proxyReq.path);
          });
          proxy.on('proxyRes', (proxyRes, _req, _res) => {
            console.log('Received Response from the Target:', proxyRes.statusCode);
          });
        },
      }
    }
  }
});