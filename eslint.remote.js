import js from '@eslint/js';
import typescript from 'typescript-eslint';
import vue from 'eslint-plugin-vue';
import stylistic from '@stylistic/eslint-plugin';


export default [
    js.configs.recommended,
    stylistic.configs[ 'recommended-flat' ],
    ...typescript.configs.recommended.map( config => ( { ...config, files : [ '**/*.ts', '**/*.vue' ] } ) ),
    ...vue.configs[ 'flat/recommended' ],
    {
        ignores : [ '**/node_modules/', 'public/', '**/vendor/' ]
    },
    {
        rules : {
            '@stylistic/indent' : [ 'error', 4, { 'SwitchCase' : 1 } ],
            '@stylistic/no-extra-semi' : 'error',
            '@stylistic/no-multiple-empty-lines' : [ 'error', { 'max' : 2 } ],
            '@stylistic/quote-props' : [ 'error', 'consistent' ],
            '@stylistic/semi' : [ 'error', 'always' ],
            '@stylistic/space-in-parens' : [ 'error', 'always' ]
        }
    }
];
