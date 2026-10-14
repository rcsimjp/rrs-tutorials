import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'RoboCup Rescue Simulation',
  tagline: '災害救助エージェント開発チュートリアル',
  url: 'https://rcsimjp.github.io',
  baseUrl: '/rrs-tutorials/',
  organizationName: 'rcsimjp',
  projectName: 'rrs-tutorials',
  trailingSlash: true,
  onBrokenLinks: 'throw',
  i18n: {
    defaultLocale: 'ja',
    locales: ['ja'],
  },
  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: 'docs',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
        blog: false,
      } satisfies Preset.Options,
    ],
  ],
};

export default config;
