// ============================================================
// CyclingHero — shows one cinematic 3D object at a time
// (vintage camera → clapperboard → typewriter) and swaps every
// `interval` ms with a scale/spin entrance + slow idle rotation.
// ============================================================
import { useEffect, useRef, useState, type ReactNode } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { VintageCamera } from "./models/VintageCamera";
import { Clapperboard } from "./models/Clapperboard";
import { Typewriter } from "./models/Typewriter";

const OBJECTS: { name: string; node: ReactNode }[] = [
  { name: "camera", node: <VintageCamera /> },
  { name: "clapper", node: <Clapperboard /> },
  { name: "typewriter", node: <Typewriter /> },
];

/** Wraps a model: pops/spins in on mount, then idles with a slow spin + float. */
function Entrance({ children }: { children: ReactNode }) {
  const group = useRef<THREE.Group>(null);
  const t = useRef(0);

  useFrame((state, dt) => {
    if (!group.current) return;
    t.current = Math.min(1, t.current + dt * 1.6);
    // easeOutBack-ish entrance
    const e = 1 - Math.pow(1 - t.current, 3);
    const s = e;
    group.current.scale.setScalar(s);
    // entrance spin settles, then slow idle spin
    const entrySpin = (1 - e) * Math.PI * 1.2;
    group.current.rotation.y = state.clock.elapsedTime * 0.3 + entrySpin;
    group.current.position.y = Math.sin(state.clock.elapsedTime * 0.8) * 0.12;
  });

  return <group ref={group} scale={0}>{children}</group>;
}

interface Props {
  interval?: number;
  scale?: number;
  /** Notifies parent of the active object name (for captions). */
  onChange?: (name: string) => void;
}

export { HERO_LABELS } from "./heroLabels";

export function CyclingHero({ interval = 6000, scale = 1, onChange }: Props) {
  const [idx, setIdx] = useState(0);

  useEffect(() => {
    onChange?.(OBJECTS[idx].name);
  }, [idx, onChange]);

  useEffect(() => {
    const id = setInterval(() => setIdx((i) => (i + 1) % OBJECTS.length), interval);
    return () => clearInterval(id);
  }, [interval]);

  return (
    <group scale={scale}>
      {/* key remounts Entrance so the pop-in replays each swap */}
      <Entrance key={idx}>{OBJECTS[idx].node}</Entrance>
    </group>
  );
}
