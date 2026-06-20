// ============================================================
// Procedural vintage typewriter. Body wedge, platen roller,
// paper sheet, key grid. Carriage nudges + a key taps.
// ============================================================
import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

const BODY = "#1b1d20";
const BRASS = "#E8B647";
const PAPER = "#ECE7D8";

function Mat({ color, e = 0.06, metal = 0.5, rough = 0.5 }: { color: string; e?: number; metal?: number; rough?: number }) {
  return <meshStandardMaterial color={color} emissive={color} emissiveIntensity={e} metalness={metal} roughness={rough} />;
}

export function Typewriter() {
  const carriage = useRef<THREE.Group>(null);
  const paper = useRef<THREE.Mesh>(null);

  // 3 rows of keys.
  const keys = useMemo(() => {
    const arr: [number, number][] = [];
    const cols = 9;
    for (let r = 0; r < 3; r++)
      for (let c = 0; c < cols; c++)
        arr.push([(-cols / 2 + c + 0.5) * 0.2 + r * 0.06, -r * 0.16]);
    return arr;
  }, []);

  useFrame((state) => {
    const t = state.clock.elapsedTime;
    if (carriage.current) {
      // Carriage drifts left as you "type", returns with a ding.
      const phase = (t * 0.5) % 2;
      carriage.current.position.x = phase < 1.8 ? -phase * 0.25 : -(2 - phase) * 2.25;
    }
    if (paper.current) paper.current.rotation.x = -0.25 + Math.sin(t * 0.6) * 0.02;
  });

  return (
    <group rotation={[0.35, -0.5, 0]} position={[0, -0.1, 0]} scale={1.15}>
      {/* Base body (wedge) */}
      <mesh position={[0, -0.35, 0]}>
        <boxGeometry args={[2.2, 0.5, 1.5]} />
        <Mat color={BODY} />
      </mesh>
      <mesh position={[0, -0.05, 0.35]} rotation={[-0.45, 0, 0]}>
        <boxGeometry args={[2.2, 0.7, 0.9]} />
        <Mat color={BODY} />
      </mesh>

      {/* Brand plate */}
      <mesh position={[0, -0.18, 0.95]}>
        <boxGeometry args={[0.7, 0.16, 0.03]} />
        <Mat color={BRASS} e={0.4} metal={0.85} rough={0.2} />
      </mesh>

      {/* Carriage + platen roller + paper */}
      <group ref={carriage} position={[0, 0.35, -0.2]}>
        <mesh rotation={[0, 0, Math.PI / 2]}>
          <cylinderGeometry args={[0.22, 0.22, 2.0, 28]} />
          <Mat color={"#26292d"} metal={0.4} rough={0.6} />
        </mesh>
        {[-1.05, 1.05].map((x) => (
          <mesh key={x} position={[x, 0, 0]} rotation={[0, 0, Math.PI / 2]}>
            <cylinderGeometry args={[0.16, 0.16, 0.12, 20]} />
            <Mat color={BRASS} e={0.35} metal={0.9} rough={0.2} />
          </mesh>
        ))}
        <mesh ref={paper} position={[0, 0.35, -0.05]} rotation={[-0.25, 0, 0]}>
          <planeGeometry args={[1.5, 1.1]} />
          <meshStandardMaterial color={PAPER} emissive={PAPER} emissiveIntensity={0.25} roughness={0.9} side={THREE.DoubleSide} />
        </mesh>
      </group>

      {/* Type-bar fan hint */}
      <mesh position={[0, 0.05, 0.15]} rotation={[-0.6, 0, 0]}>
        <cylinderGeometry args={[0.5, 0.55, 0.1, 28, 1, true]} />
        <Mat color={"#26292d"} metal={0.6} rough={0.5} />
      </mesh>

      {/* Keys */}
      {keys.map(([x, z], i) => (
        <mesh key={i} position={[x, 0.02 + z * 0.25, 0.7 + z]}>
          <cylinderGeometry args={[0.075, 0.075, 0.06, 16]} />
          <meshStandardMaterial color={"#0f1113"} emissive={BRASS} emissiveIntensity={0.06} metalness={0.7} roughness={0.3} />
        </mesh>
      ))}
    </group>
  );
}
