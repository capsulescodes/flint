import { defineConfig, loadEnv } from 'vitepress';


export default async () =>
{
    const env = loadEnv( '', process.cwd() );

    return defineConfig( {
    base : '/docs/flint/',
    title : "Flint",
    description : "Write code your way while ensuring remote consistency.",
    head : [
      [ 'meta', { name : "title", content : env.VITE_APP_NAME ?? '' } ],
      [ 'meta', { name : "description", content : env.VITE_APP_DESCRIPTION ?? '' } ],
      [ 'meta', { name : "og:site_name", content : env.VITE_APP_NAME ?? '' } ],
      [ 'meta', { name : "og:type", content : 'website' } ],
      [ 'meta', { name : "og:url", content : env.VITE_APP_URL ?? '' } ],
      [ 'meta', { name : "og:title", content : env.VITE_APP_NAME ?? '' } ],
      [ 'meta', { name : "og:description", content : env.VITE_APP_DESCRIPTION ?? '' } ],
      [ 'meta', { name : "og:image", content : `${ env.VITE_APP_URL ?? '' }/assets/flintable-logotype-meta.png` } ]
    ],
    titleTemplate : false,
    srcDir : 'pages',
    themeConfig : {
      logo : '/flint-logotype.png',
      nav : [
        { text : 'Guide', link : '/guide/' },
        { text : 'Reference', link : '/reference/' },
        { text : 'Flintable', link : `${ env.VITE_APP_URL ?? '' }/docs/flintable`, target : '_self' },
        { text : env.VITE_APP_VERSION ?? '', link : env.VITE_APP_URL ?? '', target : '_self' }
      ],
      sidebar : {
        '/' : [
        {
          text : 'Introduction',
          collapsed : false,
          items : [
            { text : 'What is Flint?', link : '/guide/' },
            { text : 'Quick start', link : '/guide/quick-start' },
            { text : 'Configuration', link : '/guide/configuration' },
          ]
        },
        {
          text : 'Core Concepts',
          collapsed : false,
          items : [
            { text : 'How it Works', link : '/guide/core-concepts/how-it-works' },
            { text : 'Why Flint', link : '/guide/core-concepts/why-flint' },
            { text : 'Caveats', link : '/guide/core-concepts/caveats' },
          ]
        },
        {
          text : 'Usage',
          collapsed : false,
          items : [
            { text : 'Individual', link : '/guide/usage/individual' },
            { text : 'Team', link : '/guide/usage/team' },
            { text : 'Global', link : '/guide/usage/global' }
          ]
        },
        {
          text : 'Advanced Topics',
          collapsed : false,
          items : [
            { text : 'Wrapping Git', link : '/guide/advanced-topics/wrapping-git' },
            { text : 'Pseudo Git Hooks', link : '/guide/advanced-topics/pseudo-git-hooks' },
            { text : 'Custom formatters', link : '/guide/advanced-topics/custom-formatters' }
          ]
        } ],
        '/reference/' : [ {
            text : 'Reference',
            collapsed : false,
            items : [
              { text : 'Config', link : '/reference/configuration' },
              { text : 'CLI', link : '/reference/command-line-interface' },
              { text : 'Hooks', link : '/reference/hooks' }
            ]
        } ]
      },
      socialLinks : [
        { link : 'https://github.com/capsulescodes/flint', icon : 'github' }
      ]
    },
    cleanUrls : true
  } )
}
