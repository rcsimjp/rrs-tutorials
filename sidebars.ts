import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'チュートリアル',
      collapsed: false,
      items: [
        'tutorial-1',
        'tutorial-2',
        'tutorial-3',
        'tutorial-4',
        'tutorial-5',
      ],
    },
    'development-environment',
    'development-resources',
  ],
};

export default sidebars;
