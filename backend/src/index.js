import express from "express";
import cors from "cors";
import tagsRouter from "./routes/tags.js";

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors({ origin: process.env.FRONTEND_ORIGIN || "http://localhost:3000" }));
app.use(express.json());

app.get("/api/health", (req, res) => {
  res.json({ status: "ok" });
});

app.use("/api/tags", tagsRouter);

// エラー時は中身をログに出し、クライアントには共通のメッセージだけ返す
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "サーバーでエラーが発生しました" });
});

app.listen(PORT, () => {
  console.log(`Backend listening on http://localhost:${PORT}`);
});
