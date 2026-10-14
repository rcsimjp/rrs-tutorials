import useBaseUrl from '@docusaurus/useBaseUrl';
import { Redirect } from '@docusaurus/router';

export default function Home(): JSX.Element {
  return <Redirect to={useBaseUrl('/docs/intro')} />;
}
