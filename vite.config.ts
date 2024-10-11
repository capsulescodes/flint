import { defineConfig } from 'vite';


export default defineConfig( {
    build : {
        lib : {
            entry : {
                'dist/installer' : 'src/installer'
            },
            formats : [ 'es' ]
        },
        outDir : '',
        target : 'esnext'
    }
} );
