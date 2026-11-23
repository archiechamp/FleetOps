import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { App } from "./app/App";
import { ProductionApp } from "./app/ProductionApp";
import "./styles.css";

const container = document.getElementById("root");
if (container === null) {
  throw new Error("FleetOps root element is missing");
}

createRoot(container).render(
  <StrictMode>
    {import.meta.env.VITE_FLEETOPS_MODE === "production" ? <ProductionApp /> : <App />}
  </StrictMode>,
);
