// functions/index.js
const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const axios = require("axios");

// Firebase Admin 초기화
admin.initializeApp();

// 전역 옵션(리전/타임아웃/메모리 등)
setGlobalOptions({
  region: "asia-northeast3", // 서울 리전
  timeoutSeconds: 15,
  memory: "256MiB",
});

// ─────────── 네이버 로그인 ───────────
exports.naverLogin = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).send("POST only");
    const { accessToken } = req.body || {};
    if (!accessToken) return res.status(400).send("missing accessToken");

    // 네이버 사용자 정보 조회
    const me = await axios.get("https://openapi.naver.com/v1/nid/me", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    const profile = me.data?.response;
    if (!profile?.id) return res.status(401).send("invalid token");

    const uid = `naver:${profile.id}`;
    const customToken = await admin.auth().createCustomToken(uid, {
      provider: "naver",
      email: profile.email || null,
      name: profile.name || profile.nickname || null,
      picture: profile.profile_image || null,
    });

    return res.json({ firebaseToken: customToken });
  } catch (e) {
    console.error(e);
    return res.status(500).send(e.message || "server error");
  }
});

// ─────────── 카카오 로그인 ───────────
exports.kakaoLogin = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).send("POST only");
    const { accessToken } = req.body || {};
    if (!accessToken) return res.status(400).send("missing accessToken");

    const me = await axios.get("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    const id = me.data?.id;
    if (!id) return res.status(401).send("invalid token");

    const kakaoAccount = me.data?.kakao_account || {};
    const profile = kakaoAccount.profile || {};

    const uid = `kakao:${id}`;
    const customToken = await admin.auth().createCustomToken(uid, {
      provider: "kakao",
      email: kakaoAccount.email || null,
      name: profile.nickname || null,
      picture: profile.profile_image_url || null,
    });

    return res.json({ firebaseToken: customToken });
  } catch (e) {
    console.error(e);
    return res.status(500).send(e.message || "server error");
  }
});

// ─────────── 구글 로그인 ───────────
const { OAuth2Client } = require("google-auth-library");
const client = new OAuth2Client();

exports.googleLogin = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).send("POST only");
    const { idToken } = req.body || {};
    if (!idToken) return res.status(400).send("missing idToken");

    // 1) Google 토큰 검증
    const ticket = await client.verifyIdToken({
      idToken,
      audience: "800123758723-bqklphkptd2t5cpahu3kfocickl58rbp.apps.googleusercontent.com", // Firebase 콘솔에서 발급받은 웹 클라이언트 ID
    });
    const payload = ticket.getPayload();
    if (!payload?.sub) return res.status(401).send("invalid idToken");

    const uid = `google:${payload.sub}`;

    // 2) Firebase Custom Token 발급
    const customToken = await admin.auth().createCustomToken(uid, {
      provider: "google",
      email: payload.email || null,
      name: payload.name || null,
      picture: payload.picture || null,
    });

    return res.json({ firebaseToken: customToken });
  } catch (e) {
    console.error(e);
    return res.status(500).send(e.message || "server error");
  }
});