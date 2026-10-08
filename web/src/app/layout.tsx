import type { Metadata, Viewport } from 'next';
import { Geist_Mono, Plus_Jakarta_Sans } from 'next/font/google';
import { cookies } from 'next/headers';
import { QueryProvider } from '@/core/query/query-provider';
import { ThemeProvider } from '@/shared/layout/theme';
import { THEME_COOKIE, type Theme } from '@/shared/layout/theme-cookie';
import { Toaster } from '@/shared/layout/toaster';
import './globals.css';

// Same typeface as the Yatrix app, so the dashboard feels like part of it.
const jakarta = Plus_Jakarta_Sans({ variable: '--font-jakarta', subsets: ['latin'] });
const geistMono = Geist_Mono({ variable: '--font-geist-mono', subsets: ['latin'] });

export const metadata: Metadata = {
  title: { default: 'Yatrix Admin', template: '%s · Yatrix Admin' },
  description: 'Superadmin dashboard for the Yatrix community.',
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#F5F7F8' },
    { media: '(prefers-color-scheme: dark)', color: '#0E1518' },
  ],
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const theme: Theme = (await cookies()).get(THEME_COOKIE)?.value === 'dark' ? 'dark' : 'light';
  return (
    <html
      lang="en"
      className={`${jakarta.variable} ${geistMono.variable} ${theme === 'dark' ? 'dark' : ''} h-full antialiased`}
      style={{ colorScheme: theme }}
      suppressHydrationWarning
    >
      <body className="min-h-full">
        <ThemeProvider initial={theme}>
          <QueryProvider>
            {children}
            <Toaster />
          </QueryProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
