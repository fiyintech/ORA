import { BrowserRouter } from "react-router-dom";
import AppRoutes from "../routes";
import AppShell from "../components/layout/AppShell";
import "../styles/globals.css";
import { ThemeProvider } from "../context/ThemeContext";
import { PremiumProvider } from "../features/premium/PremiumContext";

export default function App() {
  return (
    <BrowserRouter>
      <ThemeProvider>
        <PremiumProvider>
          <AppShell>
            <AppRoutes />
          </AppShell>
        </PremiumProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
}
