// ============================================================
// RAWBY — fixed full-bleed 3D background scene.
// Spinning film reel + dust motes + mouse parallax. Sits behind
// all content with radial amber/green glow gradients on top.
// Respects prefers-reduced-motion and degrades to a static gradient.
// ============================================================
import { Canvas, useThree, useFrame } from "@react-three/fiber";
import { Suspense, useRef } from "react";
import * as THREE from "three";
import { CyclingHero } from "./CyclingHero";
import { Particles } from "./Particles";

function Rig({ children }: { children: React.ReactNode }) {
  const group = useRef<THREE.Group>(null);
  const { pointer } = useThree();

  useFrame(() => {
    if (!group.current) return;
    // Subtle parallax toward the cursor.
    group.current.rotation.y = THREE.MathUtils.lerp(
      group.current.rotation.y,
      pointer.x * 0.25,
      0.04
    );
    group.current.rotation.x = THREE.MathUtils.lerp(
      group.current.rotation.x,
      -pointer.y * 0.18,
      0.04
    );
  });

  return <group ref={group}>{children}</group>;
}

const reduced =
  typeof window !== "undefined" &&
  window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

export function AuraScene() {
  return (
    <div className="fixed inset-0 -z-10">
      {/* Radial glow gradients (always on, cheap) */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(60% 50% at 18% 12%, rgb(var(--glow) / 0.16), transparent 60%), radial-gradient(55% 45% at 85% 88%, rgba(90,138,94,0.14), transparent 60%)",
        }}
      />

      {!reduced && (
        <Canvas
          camera={{ position: [0, 0, 6], fov: 45 }}
          dpr={[1, 1.6]}
          gl={{ antialias: true, alpha: true }}
          style={{ position: "absolute", inset: 0 }}
        >
          <ambientLight intensity={0.5} />
          <directionalLight position={[5, 5, 5]} intensity={1.1} color="#F6DC9C" />
          <pointLight position={[-4, -2, 3]} intensity={0.6} color="#6FA373" />
          <Suspense fallback={null}>
            <Rig>
              {/* Cycling cinematic prop, parked off to the side, low-key */}
              <group position={[3.4, 0.2, -0.5]}>
                <CyclingHero scale={0.6} interval={7000} />
              </group>
              <Particles count={420} />
            </Rig>
          </Suspense>
          <fog attach="fog" args={["#0A0B0D", 6, 14]} />
        </Canvas>
      )}

      {/* Vignette to keep text legible over the scene */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(120% 100% at 50% 40%, transparent 40%, rgb(var(--scene-veil)) 100%)",
        }}
      />
    </div>
  );
}
