import { supabase } from "../../../lib/supabase";

export interface PremiumStatus {
  active: boolean;
  expiresAt: string | null;
  secondsRemaining: number;
}

export interface PaymentTransaction {
  id: string;
  reference: string;
  amount_kobo: number;
  currency: string;
  product_code: string;
  status: "pending" | "success" | "failed" | "abandoned";
  paid_at: string | null;
  created_at: string;
}

export const premiumService = {
  async getStatus(): Promise<PremiumStatus> {
    const { data, error } = await supabase
      .from("premium_entitlements")
      .select("expires_at")
      .gt("expires_at", new Date().toISOString())
      .order("expires_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    if (!data?.expires_at) return { active: false, expiresAt: null, secondsRemaining: 0 };

    const secondsRemaining = Math.max(0, Math.floor((new Date(data.expires_at).getTime() - Date.now()) / 1000));
    return { active: secondsRemaining > 0, expiresAt: data.expires_at, secondsRemaining };
  },

  async startPowerHour(): Promise<{ authorizationUrl: string; reference: string }> {
    const { data, error } = await supabase.functions.invoke("initialize-premium-payment", { body: {} });
    if (error) throw error;
    if (!data?.authorizationUrl || !data?.reference) throw new Error("Unable to start the payment.");
    return data;
  },

  async verifyPayment(reference: string): Promise<"success" | "pending" | "failed"> {
    const { data, error } = await supabase.functions.invoke("verify-premium-payment", {
      body: { reference },
    });
    if (error) throw error;
    return data?.status === "success" ? "success" : data?.status === "pending" ? "pending" : "failed";
  },

  async listPayments(): Promise<PaymentTransaction[]> {
    const { data, error } = await supabase
      .from("payment_transactions")
      .select("id, reference, amount_kobo, currency, product_code, status, paid_at, created_at")
      .order("created_at", { ascending: false })
      .limit(20);
    if (error) throw error;
    return (data ?? []) as PaymentTransaction[];
  },
};
