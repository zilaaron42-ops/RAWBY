// ============================================================
// Procedural clapperboard / slate. Striped clapper stick that
// snaps open + shut on a hinge.
// ============================================================
import { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

const SLATE = "#17191c";
const WHITE = "#ECECE6";
const BRASS = "#E8B647";

function Stripes({ y }: { y: number }) {
  // 8 alternating black/white diagonal-ish stripes along x.
  const n = 8;
  const w = 2.2 / n;
  return (
    <group position={[0, y, 0.07]}>
      {Array.from({ length: n }).map((_, i) => (
        <mesh key={i} position={[-1.1 + w / 2 + i * w, 0, 0]}>
          <boxGeometry args={[w * 0.96, 0.26, 0.04]} />
          <meshStandardMaterial
            color={i % 2 === 0 ? WHITE : SLATE}
            emissive={i % 2 === 0 ? WHITE : SLATE}
            emissiveIntensity={i % 2 === 0 ? 0.25 : 0.04}
            roughness={0.5}
          />
        </mesh>
      ))}
    </group>
  );
}

export function Clapperboard() {
  const clapper = useRef<THREE.Group>(null);

  useFrame((state) => {
    if (!clapper.current) return;
    // Snap: mostly closed, quick open then clap every ~3s.
    const t = state.clock.elapsedTime % 3;
    const open = t < 0.5 ? t * 0.9 : Math.max(0, 0.45 - (t - 0.5) * 4);
    clapper.current.rotation.z = open;
  });

  return (
    <group rotation={[0.15, -0.45, 0]} scale={1.05}>
      {/* Slate board */}
      <mesh position={[0, -0.35, 0]}>
        <boxGeometry args={[2.3, 1.6, 0.12]} />
        <meshStandardMaterial color={SLATE} emissive={SLATE} emissiveIntensity={0.05} roughness={0.6} metalness={0.3} />
      </mesh>
      {/* Info lines on slate */}
      {[-0.15, -0.55, -0.95].map((y, i) => (
        <mesh key={i} position={[0, y, 0.07]}>
          <boxGeometry args={[1.9, 0.05, 0.02]} />
          <meshStandardMaterial color={BRASS} emissive={BRASS} emissiveIntensity={0.3} />
        </mesh>
      ))}
      <Stripes y={-0.05} />

      {/* Hinged clapper stick (pivots from left top corner) */}
      <group ref={clapper} position={[-1.15, 0.55, 0]}>
        <group position={[1.15, 0, 0]}>
          <mesh>
            <boxGeometry args={[2.3, 0.3, 0.12]} />
            <meshStandardMaterial color={SLATE} emissive={SLATE} emissiveIntensity={0.05} roughness={0.6} metalness={0.3} />
          </mesh>
          <Stripes y={0} />
        </group>
      </group>

      {/* Hinge bolt */}
      <mesh position={[-1.15, 0.4, 0.1]}>
        <cylinderGeometry args={[0.07, 0.07, 0.18, 16]} />
        <meshStandardMaterial color={BRASS} emissive={BRASS} emissiveIntensity={0.45} metalness={0.9} roughness={0.2} />
      </mesh>
    </group>
  );
}
