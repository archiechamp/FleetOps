/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_FLEETOPS_MODE?: string;
  readonly VITE_CLERK_PUBLISHABLE_KEY?: string;
}

interface Window {
  __FLEETOPS_CONFIG__?: { mode?: string; publishableKey?: string };
}
