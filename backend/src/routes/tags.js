import { Router } from "express";
import { getSupabase } from "../lib/supabase.js";

const TAG_TYPES = ["scene", "item", "style"];

const router = Router();

// GET /api/tags?type=scene
// システムタグの一覧を返す。type を指定するとその種類だけ返す。
// ユーザー独自タグはログイン機能ができてから返すようにする。
router.get("/", async (req, res) => {
  const { type } = req.query;
  if (type !== undefined && !TAG_TYPES.includes(type)) {
    return res.status(400).json({ error: `type は ${TAG_TYPES.join(" / ")} のどれかを指定してください` });
  }

  let query = getSupabase()
    .from("tags")
    .select("id, type, name, sort_order")
    .is("user_id", null)
    .order("type")
    .order("sort_order")
    .order("id");
  if (type) query = query.eq("type", type);

  const { data, error } = await query;
  if (error) throw error;

  res.json({ tags: data });
});

export default router;
