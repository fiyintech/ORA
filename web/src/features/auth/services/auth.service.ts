import { supabase } from "../../../lib/supabase";
import type { LoginRequest } from "../types/auth";

export class AuthService {
  async login(data: LoginRequest) {
    return await supabase.auth.signInWithPassword({
      email: data.email,
      password: data.password,
    });
  }

  async signup(email: string, password: string) {
    return await supabase.auth.signUp({
      email,
      password,
    });
  }

  async resetPassword(email: string) {
    return await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });
  }

  async updatePassword(password: string) {
    return await supabase.auth.updateUser({ password });
  }

  async logout() {
    return await supabase.auth.signOut();
  }

  async deleteAccount(): Promise<void> {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error("You must be logged in to delete your account.");

    const { data, error } = await supabase.functions.invoke("delete-account", {
      body: { confirmation: "DELETE" },
      headers: { Authorization: `Bearer ${session.access_token}` },
    });
    if (error) throw error;
    if (!data?.success) throw new Error(data?.error || "Unable to delete your account.");
    await supabase.auth.signOut();
  }

  async session() {
    return await supabase.auth.getSession();
  }

  async user() {
    return await supabase.auth.getUser();
  }

  onAuthStateChange(
    callback: Parameters<typeof supabase.auth.onAuthStateChange>[0],
  ) {
    return supabase.auth.onAuthStateChange(callback);
  }
}

export const authService = new AuthService();
