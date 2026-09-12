import {
  Navigate,
  Route,
  Routes,
} from "react-router-dom";

import LoginPage from "../features/auth/pages/LoginPage";
import AccountSwitcherPage from "../features/auth/pages/AccountSwitcherPage";
import ResetPasswordPage from "../features/auth/pages/ResetPasswordPage";
import SignupPage from "../features/auth/pages/SignupPage";
import LandingPage from "../features/auth/pages/LandingPage";
import FeedPage from "../features/feed/FeedPage";
import MessagesPage from "../features/messages/MessagesPage";
import ProfilePage from "../features/profile/ProfilePage";
import ProfileSetupPage from "../features/profile/pages/ProfileSetupPage";
import SearchPage from "../features/search/SearchPage";
import HoodsPage from "../features/hoods/HoodsPage";
import AuraPage from "../features/aura/AuraPage";
import NotificationsPage from "../features/notifications/NotificationsPage";
import SettingsPage from "../features/settings/SettingsPage";
import PremiumPage from "../features/premium/pages/PremiumPage";

import { useAuth } from "../features/auth/hooks/useAuth";
import { useProfile } from "../features/profile/hooks/useProfile";

function LoadingScreen() {
  return (
    <div className="min-h-screen bg-black text-white">
      <div className="mx-auto flex min-h-screen max-w-xl items-center justify-center px-6">
        <div className="w-full text-center">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black shadow-lg shadow-violet-600/20">O</div>
          <p className="mt-5 text-sm font-semibold text-zinc-200">Getting ORA ready</p>
          <div className="mx-auto mt-3 h-1.5 w-32 overflow-hidden rounded-full bg-zinc-900">
            <div className="h-full w-1/2 animate-pulse rounded-full bg-violet-600" />
          </div>
          <p className="mt-3 text-xs text-zinc-600">Checking your session and profile…</p>
        </div>
      </div>
    </div>
  );
}

/*
 * --------------------------------------------------
 * PUBLIC / AUTH ROUTE
 * --------------------------------------------------
 */

function PublicRoute({
  children,
}: {
  children: React.ReactNode;
}) {
  const {
    loading,
    isAuthenticated,
  } = useAuth();

  if (loading) {
    return <LoadingScreen />;
  }

  if (isAuthenticated) {
    return (
      <Navigate
        to="/"
        replace
      />
    );
  }

  return <>{children}</>;
}

/*
 * --------------------------------------------------
 * PROFILE SETUP ROUTE
 * --------------------------------------------------
 */

function ProfileSetupRoute() {
  const {
    loading: authLoading,
    isAuthenticated,
  } = useAuth();

  const {
    loading: profileLoading,
    hasProfile,
  } = useProfile();

  if (
    authLoading ||
    profileLoading
  ) {
    return <LoadingScreen />;
  }

  if (!isAuthenticated) {
    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }

  if (hasProfile) {
    return (
      <Navigate
        to="/"
        replace
      />
    );
  }

  return <ProfileSetupPage />;
}

/*
 * --------------------------------------------------
 * AUTHENTICATED ROUTE
 * --------------------------------------------------
 */

function AuthenticatedRoute({
  children,
}: {
  children: React.ReactNode;
}) {
  const {
    loading: authLoading,
    isAuthenticated,
  } = useAuth();

  const {
    loading: profileLoading,
    hasProfile,
  } = useProfile();

  if (
    authLoading ||
    profileLoading
  ) {
    return <LoadingScreen />;
  }

  if (!isAuthenticated) {
    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }

  if (!hasProfile) {
    return (
      <Navigate
        to="/setup-profile"
        replace
      />
    );
  }

  return <>{children}</>;
}

/*
 * --------------------------------------------------
 * HOME
 * --------------------------------------------------
 */

function RootRoute() {
  const { loading, isAuthenticated } = useAuth();

  if (loading) {
    return <LoadingScreen />;
  }

  if (!isAuthenticated) {
    return <LandingPage />;
  }

  return (
    <AuthenticatedRoute>
      <FeedPage />
    </AuthenticatedRoute>
  );
}

/*
 * --------------------------------------------------
 * MESSAGES
 * --------------------------------------------------
 */

function MessagesRoute() {
  return (
    <AuthenticatedRoute>
      <MessagesPage />
    </AuthenticatedRoute>
  );
}

/*
 * --------------------------------------------------
 * CURRENT USER PROFILE
 * --------------------------------------------------
 *
 * /profile
 *
 * ProfilePage detects that there is no
 * :username parameter and calls:
 *
 * profileService.getCurrentProfile()
 */

function CurrentProfileRoute() {
  return (
    <AuthenticatedRoute>
      <ProfilePage />
    </AuthenticatedRoute>
  );
}

/*
 * --------------------------------------------------
 * PUBLIC / OTHER USER PROFILE
 * --------------------------------------------------
 *
 * /profile/:username
 *
 * ProfilePage reads :username using
 * useParams() and calls:
 *
 * profileService.getProfileByUsername(username)
 */

function PublicProfileRoute() {
  return (
    <AuthenticatedRoute>
      <ProfilePage />
    </AuthenticatedRoute>
  );
}

/*
 * --------------------------------------------------
 * APP ROUTES
 * --------------------------------------------------
 */

function NotFoundPage() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center bg-black px-6 text-white">
      <div className="max-w-sm text-center">
        <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-600/10 text-violet-400 text-lg font-black">404</div>
        <h1 className="mt-5 text-xl font-bold">Page not found</h1>
        <p className="mt-2 text-sm leading-6 text-zinc-500">That ORA page does not exist or may have moved.</p>
        <a href="/" className="primary-button mt-5 inline-flex">Back home</a>
      </div>
    </main>
  );
}

export default function AppRoutes() {
  return (
    <Routes>
      {/* -------------------------------------------- */}
      {/* AUTHENTICATION */}
      {/* -------------------------------------------- */}

      <Route
        path="/login"
        element={
          <PublicRoute>
            <LoginPage />
          </PublicRoute>
        }
      />

      <Route
        path="/signup"
        element={
          <PublicRoute>
            <SignupPage />
          </PublicRoute>
        }
      />

      <Route path="/reset-password" element={<ResetPasswordPage />} />

      <Route
        path="/switch-account"
        element={<AccountSwitcherPage />}
      />

      <Route
        path="/add-account"
        element={<LoginPage allowExistingSession />}
      />

      {/* -------------------------------------------- */}
      {/* FIRST-TIME PROFILE SETUP */}
      {/* -------------------------------------------- */}

      <Route
        path="/setup-profile"
        element={
          <ProfileSetupRoute />
        }
      />

      {/* -------------------------------------------- */}
      {/* MAIN ORA APPLICATION */}
      {/* -------------------------------------------- */}

      <Route
        path="/"
        element={
          <RootRoute />
        }
      />

      {/* -------------------------------------------- */}
      {/* SEARCH */}
      {/* -------------------------------------------- */}

      <Route
        path="/search"
        element={
          <AuthenticatedRoute>
            <SearchPage />
          </AuthenticatedRoute>
        }
      />

      {/* -------------------------------------------- */}
      {/* NOTIFICATIONS */}
      {/* -------------------------------------------- */}

      <Route
        path="/notifications"
        element={
          <AuthenticatedRoute>
            <NotificationsPage />
          </AuthenticatedRoute>
        }
      />

      <Route
        path="/premium"
        element={
          <AuthenticatedRoute>
            <PremiumPage />
          </AuthenticatedRoute>
        }
      />

      <Route
        path="/premium/payment-complete"
        element={
          <AuthenticatedRoute>
            <PremiumPage />
          </AuthenticatedRoute>
        }
      />

      {/* -------------------------------------------- */}
      {/* SETTINGS */}
      {/* -------------------------------------------- */}

      <Route
        path="/settings"
        element={
          <AuthenticatedRoute>
            <SettingsPage />
          </AuthenticatedRoute>
        }
      />

      <Route
        path="/settings/profile"
        element={
          <AuthenticatedRoute>
            <SettingsPage />
          </AuthenticatedRoute>
        }
      />

      {/* -------------------------------------------- */}
      {/* HOODS */}
      {/* -------------------------------------------- */}

      <Route
        path="/hoods"
        element={
          <AuthenticatedRoute>
            <HoodsPage />
          </AuthenticatedRoute>
        }
      />

      <Route
        path="/hoods/:hoodId"
        element={
          <AuthenticatedRoute>
            <HoodsPage />
          </AuthenticatedRoute>
        }
      />

      {/* -------------------------------------------- */}
      {/* AURA */}
      {/* -------------------------------------------- */}

      <Route
        path="/aura"
        element={
          <AuthenticatedRoute>
            <AuraPage />
          </AuthenticatedRoute>
        }
      />

      {/* -------------------------------------------- */}
      {/* MESSAGES */}
      {/* -------------------------------------------- */}

      <Route
        path="/messages"
        element={
          <MessagesRoute />
        }
      />

      {/* -------------------------------------------- */}
      {/* CURRENT USER PROFILE */}
      {/* -------------------------------------------- */}

      <Route
        path="/profile"
        element={
          <CurrentProfileRoute />
        }
      />

      {/* -------------------------------------------- */}
      {/* OTHER USER / PUBLIC PROFILE */}
      {/* -------------------------------------------- */}

      <Route
        path="/profile/:username"
        element={
          <PublicProfileRoute />
        }
      />

      {/* -------------------------------------------- */}
      {/* UNKNOWN ROUTES */}
      {/* -------------------------------------------- */}

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
