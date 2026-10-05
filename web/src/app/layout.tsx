import type { Metadata, Viewport } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import { cookies } from 'next/headers';
import { QueryProvider } from '@/core/query/query-provider';
import { THEME_COOKIE, ThemeProvider, type Theme } from '@/shared/layout/theme';
import { Toaster } from '@/shared/layout/toaster';
import './globals.css';

const geistSans = Geist({ variable: '--font-geist-sans', subsets: ['latin'] });
const geistMono = Geist_Mono({ variable: '--font-geist-mono', subsets: ['latin'] });

export const metadata: Metadata = {
  title: { default: 'Ride Sangai Admin', template: '%s · Ride Sangai Admin' },
  description: 'Superadmin dashboard for the Ride Sangai community.',
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#F6F8F9' },
    { media: '(prefers-color-scheme: dark)', color: '#0E1518' },
  ],
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const theme: Theme = (await cookies()).get(THEME_COOKIE)?.value === 'dark' ? 'dark' : 'light';
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} ${theme === 'dark' ? 'dark' : ''} h-full antialiased`}
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
