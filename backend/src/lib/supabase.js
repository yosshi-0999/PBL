import { createClient } from "@supabase/supabase-js";

let client;

// Supabase クライアントを返す。環境変数が未設定ならエラーにする。
// サーバー起動時ではなく最初に使うときに作るので、未設定でも /api/health などは動く。
export function getSupabase() {
  if (client) return client;

  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) {
    throw new Error("SUPABASE_URL と SUPABASE_PUBLISHABLE_KEY を backend/.env に設定してください");
  }

  client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return client;
}
