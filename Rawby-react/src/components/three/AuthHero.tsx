// Login/register 3D hero canvas — split out so it can be lazy-loaded
// (keeps `three` out of the initial paint path). Default export for React.lazy.
import { Canvas } from "@react-three/fiber";
import { Suspense } from "react";
import { CyclingHero } from "./CyclingHero";
import { Particles } from "./Particles";
import { PaintOnce } from "./PaintOnce";

export default function AuthHero({ onChange }: { onChange: (name: string) => void }) {
  return (
    <Canvas camera={{ position: [0, 0, 6], fov: 45 }} dpr={[1, 1.6]}>
      <ambientLight intensity={1.1} />
      <directionalLight position={[4, 6, 6]} intensity={2.4} color="#FFE9B0" />
      <pointLight position={[-5, -1, 4]} intensity={1.3} color="#6FA373" />
      {/* Warm amber rim/back light so the dark body reads against black */}
      <pointLight position={[0, 1.5, -4]} intensity={3} color="#E8B647" />
      <pointLight position={[3, 3, 2]} intensity={1.4} color="#F6DC9C" />
      <Suspense fallback={null}>
        <CyclingHero scale={1.25} interval={6000} onChange={onChange} />
        <Particles count={300} />
        <PaintOnce />
      </Suspense>
    </Canvas>
  );
}
