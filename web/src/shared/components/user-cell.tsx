import { Avatar } from '@/shared/ui/avatar';
import { cn } from '@/shared/lib/cn';

/** Avatar + name + secondary line, used across tables. */
export function UserCell({
  name,
  avatarUrl,
  secondary,
  size = 32,
  className,
  trailing,
}: {
  name: string;
  avatarUrl?: string | null;
  secondary?: React.ReactNode;
  size?: number;
  className?: string;
  trailing?: React.ReactNode;
}) {
  return (
    <div className={cn('flex min-w-0 items-center gap-3', className)}>
      <Avatar name={name} src={avatarUrl} size={size} />
      <div className="min-w-0">
        <div className="flex items-center gap-1.5">
          <span className="truncate font-medium text-foreground">{name}</span>
          {trailing}
        </div>
        {secondary && <div className="truncate text-xs text-muted">{secondary}</div>}
      </div>
    </div>
  );
}
