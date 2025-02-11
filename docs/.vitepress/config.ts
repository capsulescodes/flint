import { defineConfig, loadEnv } from 'vitepress';


export default async () =>
{
    const env = loadEnv( '', process.cwd() );

    return defineConfig( {
    base : '/docs/',
    title : "Flint",
    description : "Write code your way while ensuring remote consistency.",
    head : [
      [ 'link', { rel : "shortcut icon", href : "/favicon.ico" } ],
    ],
    titleTemplate : false,
    cleanUrls : true,
    themeConfig : {
      logo : '/flint-logotype.png',
      nav : [
        { text : 'Documentation', link : '/markdown-examples' },
        { text : 'Flintable', link : env.VITE_APP_URL, target : '_self' }
      ],
      sidebar : [
        {
          text : 'Examples',
          items : [
            { text : 'Hello Flintable World', link : '/markdown-examples' },
            { text : 'Another ', link : '/api-examples' }
          ]
        }
      ],
      socialLinks : [
        { link : 'https://github.com/capsulescodes/flint', icon : 'github' }
      ]
    }
  } )
}
