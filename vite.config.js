import { defineConfig } from "vite";
import { fileURLToPath, URL } from "url";
import vue from "@vitejs/plugin-vue";
import svgLoader from 'vite-svg-loader'

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [vue(),svgLoader()],
    resolve: {
        alias: {
            "@": fileURLToPath(new URL("./src", import.meta.url)),
        },
    },
    css: {
        // cf. https://zenn-dev.translate.goog/tsuvic/scraps/950875d87d813a?_x_tr_sl=auto&_x_tr_tl=en&_x_tr_hl=fr&_x_tr_pto=wapp
        devSourcemap: true,
        loaderOptions: {
            sass: {
                additionalData: `
          @import "@/scss/_variables.scss";
        `,
            },
        },
    },
});
