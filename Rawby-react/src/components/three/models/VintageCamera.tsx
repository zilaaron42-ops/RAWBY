// ============================================================
// Procedural vintage hand-crank film camera (three primitives).
// Dark body + brass/amber trim, two film magazines, lens, crank.
// ============================================================
import { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

const BODY = "#17191c";
const BRASS = "#E8B647";
const BRASS_D = "#C9942C";
const GLASS = "#0b0d10";

function Mat({ color, e = 0.25, metal = 0.6, rough = 0.4 }: { color: string; e?: number; metal?: number; rough?: number }) {
  return <meshStandardMaterial color={color} emissive={color} emissiveIntensity={e} metalness={metal} roughness={rough} />;
}

export function VintageCamera() {
  const crank = useRef<THREE.Group>(null);
  useFrame((_, dt) => {
    if (crank.current) crank.current.rotation.z -= dt * 3; // hand crank spins
  });

  return (
    <group rotation={[0.1, -0.5, 0]} position={[0, -0.2, 0]}>
      {/* Body */}
      <mesh castShadow>
        <boxGeometry args={[1.7, 1.5, 1.1]} />
        <Mat color={BODY} e={0.05} metal={0.5} rough={0.55} />
      </mesh>
      {/* Brass edge frame */}
      <mesh>
        <boxGeometry args={[1.78, 0.12, 1.18]} />
        <Mat color={BRASS_D} e={0.2} />
      </mesh>
      <mesh position={[0, 0.69, 0]}>
        <boxGeometry args={[1.78, 0.12, 1.18]} />
        <Mat color={BRASS_D} e={0.2} />
      </mesh>

      {/* Two film magazines on top */}
      {[-0.45, 0.45].map((x) => (
        <group key={x} position={[x, 1.15, 0]} rotation={[Math.PI / 2, 0, 0]}>
          <mesh>
            <cylinderGeometry args={[0.42, 0.42, 0.42, 36]} />
            <Mat color={BODY} e={0.05} metal={0.4} rough={0.6} />
          </mesh>
          <mesh position={[0, 0.22, 0]}>
            <cylinderGeometry args={[0.12, 0.12, 0.1, 24]} />
            <Mat color={BRASS} e={0.4} metal={0.8} rough={0.25} />
          </mesh>
          <mesh position={[0, -0.22, 0]}>
            <torusGeometry args={[0.42, 0.04, 12, 36]} />
            <Mat color={BRASS} e={0.35} />
          </mesh>
        </group>
      ))}

      {/* Lens barrel (front +z) */}
      <group position={[0, -0.05, 0.7]} rotation={[Math.PI / 2, 0, 0]}>
        <mesh>
          <cylinderGeometry args={[0.42, 0.5, 0.7, 40]} />
          <Mat color={"#202327"} e={0.06} metal={0.7} rough={0.35} />
        </mesh>
        <mesh position={[0, 0.36, 0]}>
          <torusGeometry args={[0.42, 0.06, 16, 40]} />
          <Mat color={BRASS} e={0.45} metal={0.85} rough={0.2} />
        </mesh>
        <mesh position={[0, 0.4, 0]}>
          <cylinderGeometry args={[0.34, 0.34, 0.05, 40]} />
          <Mat color={GLASS} e={0.1} metal={0.95} rough={0.05} />
        </mesh>
      </group>

      {/* Viewfinder */}
      <mesh position={[0.7, 0.3, -0.2]} rotation={[0, 0, Math.PI / 2]}>
        <cylinderGeometry args={[0.12, 0.12, 0.3, 20]} />
        <Mat color={BRASS_D} e={0.25} />
      </mesh>

      {/* Hand crank on the side (-x) */}
      <group ref={crank} position={[-0.95, 0, 0.25]}>
        <mesh rotation={[0, 0, Math.PI / 2]}>
          <cylinderGeometry args={[0.05, 0.05, 0.2, 16]} />
          <Mat color={BRASS} e={0.4} metal={0.9} rough={0.2} />
        </mesh>
        <mesh position={[0, 0.32, 0]}>
          <boxGeometry args={[0.07, 0.66, 0.07]} />
          <Mat color={BRASS_D} e={0.25} />
        </mesh>
        <mesh position={[0, 0.6, 0]} rotation={[0, 0, Math.PI / 2]}>
          <cylinderGeometry args={[0.07, 0.07, 0.22, 16]} />
          <Mat color={BRASS} e={0.45} metal={0.9} rough={0.2} />
        </mesh>
      </group>

      {/* Tripod neck stub */}
      <mesh position={[0, -0.95, 0]}>
        <cylinderGeometry args={[0.18, 0.18, 0.4, 24]} />
        <Mat color={"#202327"} e={0.05} metal={0.6} rough={0.45} />
      </mesh>
    </group>
  );
}
