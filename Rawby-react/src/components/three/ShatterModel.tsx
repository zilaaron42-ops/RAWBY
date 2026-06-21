// ============================================================
// ShatterModel — wraps a procedural model and animates its pieces
// flying apart / coming together. mode="assemble" gathers the
// scattered pieces into place; mode="explode" blows them outward.
// onDone fires when the current transition finishes.
// Under reduced-motion it simply snaps to the assembled state.
// ============================================================
import { useEffect, useRef, type ReactNode } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { REDUCED } from "./reduced";

interface Piece {
  mesh: THREE.Mesh;
  basePos: THREE.Vector3;
  baseRot: THREE.Euler;
  dir: THREE.Vector3; // scatter offset at full explosion
  spin: THREE.Vector3; // extra rotation at full explosion
}

interface Props {
  children: ReactNode;
  mode: "assemble" | "explode";
  onDone?: () => void;
  speed?: number;
}

export function ShatterModel({ children, mode, onDone, speed = 2.2 }: Props) {
  const group = useRef<THREE.Group>(null);
  const pieces = useRef<Piece[]>([]);
  // p: 1 = fully assembled, 0 = fully exploded.
  const p = useRef(mode === "assemble" ? 0 : 1);
  const done = useRef(false);

  // Record each mesh's home transform + a random scatter vector once.
  useEffect(() => {
    if (!group.current) return;
    const arr: Piece[] = [];
    group.current.traverse((o) => {
      const m = o as THREE.Mesh;
      if (!m.isMesh) return;
      const dir = new THREE.Vector3(
        Math.random() - 0.5,
        Math.random() - 0.5,
        Math.random() - 0.5
      )
        .normalize()
        .multiplyScalar(0.7 + Math.random() * 0.9);
      arr.push({
        mesh: m,
        basePos: m.position.clone(),
        baseRot: m.rotation.clone(),
        dir,
        spin: new THREE.Vector3(
          (Math.random() - 0.5) * 5,
          (Math.random() - 0.5) * 5,
          (Math.random() - 0.5) * 5
        ),
      });
      const mat = m.material as THREE.MeshStandardMaterial | undefined;
      if (mat) mat.transparent = true;
    });
    pieces.current = arr;

    if (REDUCED) {
      p.current = 1; // snap assembled, no animation
      apply();
      done.current = true;
      onDone?.();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Re-arm when the mode flips on the same instance (idle -> explode).
  useEffect(() => {
    if (!REDUCED) done.current = false;
  }, [mode]);

  function apply() {
    const e = 1 - p.current; // explosion amount
    for (const pc of pieces.current) {
      pc.mesh.position.set(
        pc.basePos.x + pc.dir.x * e,
        pc.basePos.y + pc.dir.y * e,
        pc.basePos.z + pc.dir.z * e
      );
      pc.mesh.rotation.set(
        pc.baseRot.x + pc.spin.x * e,
        pc.baseRot.y + pc.spin.y * e,
        pc.baseRot.z + pc.spin.z * e
      );
      const mat = pc.mesh.material as THREE.MeshStandardMaterial | undefined;
      if (mat) mat.opacity = Math.max(0, Math.min(1, p.current * 1.4));
    }
  }

  useFrame((_, dt) => {
    if (REDUCED || done.current) return;
    const target = mode === "assemble" ? 1 : 0;
    if (mode === "assemble") p.current = Math.min(1, p.current + dt * speed);
    else p.current = Math.max(0, p.current - dt * speed);
    apply();
    if (p.current === target) {
      done.current = true;
      onDone?.();
    }
  });

  return <group ref={group}>{children}</group>;
}
