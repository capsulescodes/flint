import { defineConfig } from 'vitepress';


export default defineConfig( {
  title : "Flint",
  titleTemplate : false,
  description : "Write code your way while ensuring remote consistency.",
  head : [
    [ 'link', { rel : "shortcut icon", href : "/assets/favicon.ico" } ],
  ],
  cleanUrls : true,
  themeConfig : {
    logo : '/assets/capsules-flint-logotype.png',
    nav : [
      { text : 'Documentation', link : '/markdown-examples' },
      { text : 'Flintable', link : 'https://flintable.com' }
    ],
    sidebar : [
      {
        text : 'Examples',
        items : [
          { text : 'Markdown Examples', link : '/markdown-examples' },
          { text : 'Runtime API Examples', link : '/api-examples' }
        ]
      }
    ],
    socialLinks : [
      { link : 'https://github.com/capsulescodes/flint', icon : 'github' }
    ]
  }
} )
