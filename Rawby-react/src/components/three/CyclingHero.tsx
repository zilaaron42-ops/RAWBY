// ============================================================
// CyclingHero — shows one cinematic 3D object at a time
// (vintage camera → clapperboard → typewriter). On each swap the
// current object EXPLODES apart, then the next ASSEMBLES from
// scattered pieces. Idle = slow spin + float.
// Under reduced-motion: a single static, assembled object.
// ============================================================
import { useEffect, useRef, useState, type ReactNode } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { VintageCamera } from "./models/VintageCamera";
import { Clapperboard } from "./models/Clapperboard";
import { Typewriter } from "./models/Typewriter";
import { ShatterModel } from "./ShatterModel";
import { REDUCED } from "./reduced";

const OBJECTS: { name: string; node: ReactNode }[] = [
  { name: "camera", node: <VintageCamera /> },
  { name: "clapper", node: <Clapperboard /> },
  { name: "typewriter", node: <Typewriter /> },
];

type Phase = "in" | "idle" | "out";

/** Idle slow spin + gentle float (skipped under reduced-motion). */
function Spinner({ children }: { children: ReactNode }) {
  const g = useRef<THREE.Group>(null);
  useFrame((state) => {
    if (REDUCED || !g.current) return;
    g.current.rotation.y = state.clock.elapsedTime * 0.25;
    g.current.position.y = Math.sin(state.clock.elapsedTime * 0.8) * 0.12;
  });
  return <group ref={g}>{children}</group>;
}

interface Props {
  interval?: number;
  scale?: number;
  onChange?: (name: string) => void;
}

export { HERO_LABELS } from "./heroLabels";

export function CyclingHero({ interval = 6000, scale = 1, onChange }: Props) {
  const [cur, setCur] = useState(0);
  const [phase, setPhase] = useState<Phase>(REDUCED ? "idle" : "in");

  useEffect(() => {
    onChange?.(OBJECTS[cur].name);
  }, [cur, onChange]);

  // Dwell timer: once idle, wait `interval`, then explode out.
  useEffect(() => {
    if (REDUCED || phase !== "idle") return;
    const t = setTimeout(() => setPhase("out"), interval);
    return () => clearTimeout(t);
  }, [phase, interval]);

  // Called by ShatterModel when a transition completes.
  function handleDone() {
    if (REDUCED) return;
    setPhase((ph) => {
      if (ph === "out") {
        setCur((c) => (c + 1) % OBJECTS.length);
        return "in";
      }
      if (ph === "in") return "idle";
      return ph;
    });
  }

  return (
    <group scale={scale}>
      <Spinner>
        {/* key = cur → remounts (assembles) when the object changes.
            Same instance flips mode in→idle→out without remounting. */}
        <ShatterModel
          key={cur}
          mode={phase === "out" ? "explode" : "assemble"}
          onDone={handleDone}
        >
          {OBJECTS[cur].node}
        </ShatterModel>
      </Spinner>
    </group>
  );
}
