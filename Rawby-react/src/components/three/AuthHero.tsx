// Login/register 3D hero canvas — split out so it can be lazy-loaded
// (keeps `three` out of the initial paint path). Default export for React.lazy.
import { Canvas } from "@react-three/fiber";
import { Suspense } from "react";
import { CyclingHero } from "./CyclingHero";
import { Particles } from "./Particles";

export default function AuthHero({ onChange }: { onChange: (name: string) => void }) {
  return (
    <Canvas camera={{ position: [0, 0, 6], fov: 45 }} dpr={[1, 1.6]}>
      <ambientLight intensity={0.6} />
      <directionalLight position={[4, 5, 5]} intensity={1.3} color="#F6DC9C" />
      <pointLight position={[-4, -2, 3]} intensity={0.6} color="#6FA373" />
      <Suspense fallback={null}>
        <CyclingHero scale={1.05} interval={6000} onChange={onChange} />
        <Particles count={300} />
      </Suspense>
    </Canvas>
  );
}
