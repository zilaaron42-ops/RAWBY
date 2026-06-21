// ============================================================
// Vintage 16mm cine camera (Bolex-style), hand-built procedurally.
// Rounded gunmetal body, leather side panel, twin-lens turret with
// glassy front elements + knurled brass focus rings, viewfinder,
// film-magazine cover, hand crank. PBR materials reflect the scene
// environment for a real-metal read. Not a photo-scan — stylised real.
// ============================================================
import { useMemo, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { RoundedGeo } from "../RoundedGeo";
import { REDUCED } from "../reduced";

const GUNMETAL = "#24262b";
const BRASS = "#caa14a";
const BRASS_D = "#9c7a2e";
const GLASS = "#0a0d12";

function Metal(props: { color: string; metalness?: number; roughness?: number; emissive?: string; ei?: number }) {
  return (
    <meshStandardMaterial
      color={props.color}
      metalness={props.metalness ?? 0.6}
      roughness={props.roughness ?? 0.45}
      emissive={props.emissive ?? "#000000"}
      emissiveIntensity={props.ei ?? 0}
      envMapIntensity={1.1}
    />
  );
}

/** A lens: barrel + knurled brass ring + reflective glass element. */
function Lens({ z = 0, r = 0.42, len = 0.7 }: { z?: number; r?: number; len?: number }) {
  return (
    <group position={[0, 0, z]} rotation={[Math.PI / 2, 0, 0]}>
      <mesh>
        <cylinderGeometry args={[r, r * 1.12, len, 48]} />
        <Metal color="#1c1e22" metalness={0.8} roughness={0.3} />
      </mesh>
      {/* knurled focus ring */}
      <mesh position={[0, len * 0.18, 0]}>
        <cylinderGeometry args={[r * 1.06, r * 1.06, len * 0.22, 64]} />
        <Metal color={BRASS} metalness={0.95} roughness={0.32} />
      </mesh>
      {/* front bezel */}
      <mesh position={[0, len * 0.5, 0]}>
        <torusGeometry args={[r, 0.05, 20, 48]} />
        <Metal color={BRASS} metalness={0.96} roughness={0.16} />
      </mesh>
      {/* glass element — dark + mirror-smooth so it reflects the env */}
      <mesh position={[0, len * 0.52, 0]}>
        <cylinderGeometry args={[r * 0.84, r * 0.84, 0.04, 48]} />
        <meshStandardMaterial color={GLASS} metalness={1} roughness={0.04} envMapIntensity={1.6} />
      </mesh>
    </group>
  );
}

export function VintageCamera() {
  const crank = useRef<THREE.Group>(null);

  // Procedural leather texture for the side panel.
  const leather = useMemo(() => {
    const c = document.createElement("canvas");
    c.width = c.height = 128;
    const ctx = c.getContext("2d")!;
    ctx.fillStyle = "#3a2a1c";
    ctx.fillRect(0, 0, 128, 128);
    for (let i = 0; i < 2600; i++) {
      ctx.fillStyle = `rgba(0,0,0,${Math.random() * 0.18})`;
      ctx.fillRect(Math.random() * 128, Math.random() * 128, 2, 2);
    }
    for (let i = 0; i < 600; i++) {
      ctx.fillStyle = `rgba(120,90,60,${Math.random() * 0.12})`;
      ctx.fillRect(Math.random() * 128, Math.random() * 128, 1, 1);
    }
    const t = new THREE.CanvasTexture(c);
    t.wrapS = t.wrapT = THREE.RepeatWrapping;
    t.repeat.set(2, 2);
    return t;
  }, []);

  useFrame((_, dt) => {
    if (REDUCED || !crank.current) return;
    crank.current.rotation.z -= dt * 3;
  });

  return (
    <group rotation={[0.08, -0.55, 0]} position={[0, -0.1, 0]} scale={0.92}>
      {/* Body */}
      <mesh castShadow>
        <RoundedGeo args={[1.9, 1.45, 1.05]} radius={0.1} />
        <Metal color={GUNMETAL} metalness={0.55} roughness={0.5} />
      </mesh>

      {/* Leather front panel */}
      <mesh position={[0, -0.05, 0.54]}>
        <RoundedGeo args={[1.55, 1.0, 0.04]} radius={0.05} />
        <meshStandardMaterial map={leather} color="#5a4129" roughness={0.9} metalness={0.05} />
      </mesh>

      {/* Brass top + bottom trim plates */}
      <mesh position={[0, 0.74, 0]}>
        <RoundedGeo args={[1.86, 0.1, 1.02]} radius={0.04} />
        <Metal color={BRASS_D} metalness={0.92} roughness={0.28} />
      </mesh>
      <mesh position={[0, -0.74, 0]}>
        <RoundedGeo args={[1.86, 0.1, 1.02]} radius={0.04} />
        <Metal color={BRASS_D} metalness={0.92} roughness={0.28} />
      </mesh>

      {/* Lens turret (main + small secondary) */}
      <group position={[0.05, -0.02, 0.5]}>
        <Lens z={0.18} r={0.4} len={0.78} />
      </group>
      <group position={[-0.5, 0.32, 0.5]}>
        <Lens z={0.05} r={0.2} len={0.4} />
      </group>

      {/* Film magazine cover on top */}
      <group position={[0.15, 0.95, -0.05]} rotation={[Math.PI / 2, 0, 0]}>
        <mesh>
          <cylinderGeometry args={[0.5, 0.5, 0.34, 48]} />
          <Metal color={GUNMETAL} metalness={0.5} roughness={0.55} />
        </mesh>
        <mesh position={[0, 0.18, 0]}>
          <cylinderGeometry args={[0.12, 0.12, 0.08, 24]} />
          <Metal color={BRASS} metalness={0.95} roughness={0.2} />
        </mesh>
        <mesh position={[0, 0.175, 0]}>
          <torusGeometry args={[0.5, 0.03, 12, 48]} />
          <Metal color={BRASS} metalness={0.95} roughness={0.22} />
        </mesh>
      </group>

      {/* Viewfinder */}
      <mesh position={[0.78, 0.42, -0.1]} rotation={[0, 0, Math.PI / 2]}>
        <cylinderGeometry args={[0.13, 0.13, 0.4, 28]} />
        <Metal color="#1c1e22" metalness={0.7} roughness={0.35} />
      </mesh>
      <mesh position={[0.98, 0.42, -0.1]} rotation={[0, 0, Math.PI / 2]}>
        <torusGeometry args={[0.13, 0.03, 12, 28]} />
        <Metal color={BRASS} metalness={0.95} roughness={0.2} />
      </mesh>

      {/* Hand crank */}
      <group ref={crank} position={[-1.0, 0, 0.2]}>
        <mesh rotation={[0, 0, Math.PI / 2]}>
          <cylinderGeometry args={[0.06, 0.06, 0.22, 20]} />
          <Metal color={BRASS} metalness={0.95} roughness={0.18} />
        </mesh>
        <mesh position={[0, 0.3, 0]}>
          <boxGeometry args={[0.07, 0.6, 0.07]} />
          <Metal color={BRASS_D} metalness={0.9} roughness={0.3} />
        </mesh>
        <mesh position={[0, 0.56, 0]} rotation={[0, 0, Math.PI / 2]}>
          <cylinderGeometry args={[0.08, 0.08, 0.2, 20]} />
          <Metal color={BRASS} metalness={0.95} roughness={0.2} />
        </mesh>
      </group>

      {/* Tripod mount stub */}
      <mesh position={[0, -0.95, 0]}>
        <cylinderGeometry args={[0.2, 0.22, 0.34, 28]} />
        <Metal color="#1c1e22" metalness={0.6} roughness={0.45} />
      </mesh>
    </group>
  );
}
