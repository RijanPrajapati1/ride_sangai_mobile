import { ContentHeader, ContentTabs } from '@/features/content';

export default function ContentLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <ContentHeader />
      <ContentTabs />
      {children}
    </>
  );
}
