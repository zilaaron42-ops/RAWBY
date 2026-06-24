// ============================================================
// RAWBY — fixed full-bleed 3D background scene.
// Spinning film reel + dust motes + mouse parallax. Sits behind
// all content with radial amber/green glow gradients on top.
// Respects prefers-reduced-motion and degrades to a static gradient.
// ============================================================
import { Canvas, useThree, useFrame } from "@react-three/fiber";
import { Suspense, useRef } from "react";
import * as THREE from "three";
import { Particles } from "./Particles";
import { PaintOnce } from "./PaintOnce";
import { Env } from "./Env";
import { REDUCED } from "./reduced";

function Rig({ children }: { children: React.ReactNode }) {
  const group = useRef<THREE.Group>(null);
  const { pointer } = useThree();

  useFrame(() => {
    if (REDUCED || !group.current) return;
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

export function AuraScene() {
  return (
    <div className="fixed inset-0 -z-10">
      {(
        <Canvas
          camera={{ position: [0, 0, 6], fov: 45 }}
          dpr={[1, 1.6]}
          gl={{ antialias: true, alpha: true }}
          style={{ position: "absolute", inset: 0 }}
        >
          <Env intensity={0.3} />
          <ambientLight intensity={0.7} />
          <directionalLight position={[5, 5, 5]} intensity={1.3} color="#F3DCA2" />
          <pointLight position={[0, 1, -4]} intensity={1.4} color="#E8B647" />
          <Suspense fallback={null}>
            <Rig>
              <Particles count={170} />
              <PaintOnce />
            </Rig>
          </Suspense>
          <fog attach="fog" args={["#0A0B0D", 5, 12]} />
        </Canvas>
      )}

      {/* Deep filmic vignette — keeps the scene to a quiet glow at centre and
          sinks the edges to true black so content reads cleanly. */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(130% 105% at 50% 34%, transparent 38%, rgb(var(--bg) / 0.92) 100%)",
        }}
      />
    </div>
  );
}
