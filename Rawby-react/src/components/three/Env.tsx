// Procedural image-based lighting (no asset downloads). Generates a soft
// studio environment via RoomEnvironment + PMREM so metal/brass surfaces
// reflect and read as premium instead of flat.
import { useEffect } from "react";
import { useThree } from "@react-three/fiber";
import * as THREE from "three";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";

export function Env({ intensity = 0.5 }: { intensity?: number }) {
  const { gl, scene } = useThree();
  useEffect(() => {
    const pmrem = new THREE.PMREMGenerator(gl);
    const rt = pmrem.fromScene(new RoomEnvironment(), 0.04);
    scene.environment = rt.texture;
    scene.environmentIntensity = intensity;
    return () => {
      rt.texture.dispose();
      pmrem.dispose();
      scene.environment = null;
    };
  }, [gl, scene, intensity]);
  return null;
}
