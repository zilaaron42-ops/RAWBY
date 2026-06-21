// Beveled box geometry helper — rounded edges read far less "toy" than
// hard-cornered boxes. Used by the procedural hero models.
import { useMemo } from "react";
import { RoundedBoxGeometry } from "three/examples/jsm/geometries/RoundedBoxGeometry.js";

export function RoundedGeo({
  args,
  radius = 0.06,
  segments = 4,
}: {
  args: [number, number, number];
  radius?: number;
  segments?: number;
}) {
  const geo = useMemo(
    () => new RoundedBoxGeometry(args[0], args[1], args[2], segments, radius),
    [args, radius, segments]
  );
  return <primitive object={geo} attach="geometry" />;
}
