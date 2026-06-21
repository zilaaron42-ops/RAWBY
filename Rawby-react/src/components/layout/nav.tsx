// Nav item definitions (icons from the shared SVG set).
import type { IconName } from "../ui/Icon";

export interface NavItem {
  to: string;
  label: string;
  icon: IconName;
}

export const NAV_ITEMS: NavItem[] = [
  { to: "/", label: "Home", icon: "home" },
  { to: "/prompts", label: "Prompts", icon: "clapper" },
  { to: "/leaderboard", label: "Ranks", icon: "trophy" },
  { to: "/gear", label: "Gear", icon: "aperture" },
  { to: "/idea-bank", label: "Ideas", icon: "bulb" },
  { to: "/assistant", label: "Aurora", icon: "sparkles" },
];

export const SECONDARY_ITEMS: NavItem[] = [
  { to: "/profile", label: "Profile", icon: "user" },
  { to: "/settings", label: "Settings", icon: "settings" },
];

export const ADMIN_ITEM: NavItem = { to: "/admin", label: "Admin", icon: "shield" };
