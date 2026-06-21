// The 3D hero is the centerpiece the owner explicitly wants animated, so
// it always plays (cycle + shatter + spin). Page-level motion still honours
// prefers-reduced-motion via the CSS media query in index.css.
// Flip this back to the matchMedia check to make the 3D respect it too.
export const REDUCED = false;
