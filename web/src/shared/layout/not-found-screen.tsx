import Link from 'next/link';
import { ArrowLeft, Compass } from 'lucide-react';
import { Button } from '@/shared/ui/button';
import { Brand } from './brand';

export function NotFoundScreen() {
  return (
    <div className="flex min-h-dvh flex-col">
      <div className="p-5 sm:p-6">
        <Link href="/" aria-label="Home">
          <Brand />
        </Link>
      </div>
      <div className="flex flex-1 items-center justify-center px-4 pb-20">
        <div className="max-w-md text-center">
          <div className="relative mx-auto mb-6 w-fit">
            <div className="absolute inset-0 scale-150 rounded-full bg-primary-soft blur-2xl" aria-hidden />
            <div className="relative flex size-16 items-center justify-center rounded-2xl border border-border bg-surface text-primary-strong shadow-card">
              <Compass className="size-7" />
            </div>
          </div>
          <p className="text-sm font-semibold tracking-wider text-accent-ink uppercase">404</p>
          <h1 className="mt-2 text-3xl font-semibold tracking-tight">Off the trail</h1>
          <p className="mt-3 text-[15px] text-muted">
            The page you&apos;re looking for doesn&apos;t exist or has moved. Let&apos;s get you back on route.
          </p>
          <Button asChild size="lg" className="mt-8">
            <Link href="/">
              <ArrowLeft /> Back to overview
            </Link>
          </Button>
        </div>
      </div>
    </div>
  );
}
