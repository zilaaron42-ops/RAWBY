// Shimmer skeleton placeholders — reserve layout, avoid content jump.
export function Skeleton({ className = "" }: { className?: string }) {
  return (
    <div
      className={`relative overflow-hidden rounded-lg bg-chip ${className}`}
      aria-hidden="true"
    >
      <div className="absolute inset-0 -translate-x-full animate-shimmer bg-gradient-to-r from-transparent via-text-dim/15 to-transparent" />
    </div>
  );
}

export function SkeletonCard() {
  return (
    <div className="glass space-y-3 p-5">
      <Skeleton className="h-9 w-9 rounded-lg" />
      <Skeleton className="h-7 w-2/3" />
      <Skeleton className="h-3 w-1/2" />
    </div>
  );
}

export function SkeletonRow() {
  return (
    <div className="glass flex items-center gap-4 py-3">
      <Skeleton className="h-10 w-10 rounded-xl" />
      <Skeleton className="h-10 w-10 rounded-full" />
      <div className="flex-1 space-y-2">
        <Skeleton className="h-4 w-1/3" />
        <Skeleton className="h-3 w-1/4" />
      </div>
      <Skeleton className="h-6 w-10" />
    </div>
  );
}
