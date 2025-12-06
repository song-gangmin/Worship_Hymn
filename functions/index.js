const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https"); // 누락된 import 추가
const { onSchedule } = require("firebase-functions/v2/scheduler"); // 스케줄러 v2 import
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const nodemailer = require("nodemailer");
const { OAuth2Client } = require("google-auth-library");

// Firebase Admin 초기화
admin.initializeApp();

// 전역 옵션(리전/타임아웃/메모리 등)
setGlobalOptions({
  region: "asia-northeast3", // 서울 리전
  timeoutSeconds: 15,
  memory: "256MiB",
});

// Gmail 설정 변수 정의 (여기서 .value()를 호출하면 안 됨)
const gmailUser = defineString("GMAIL_USER");
const gmailPass = defineString("GMAIL_PASS");

// ---------------- Inquiry Mail ----------------
exports.sendInquiryMail = onDocumentCreated("inquiries/{inquiryId}", async (event) => {
  // 🔥 중요: transporter 생성을 함수 내부로 이동
  // .value()는 함수가 실행될 때만 호출 가능합니다.
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailUser.value(),
      pass: gmailPass.value(),
    },
  });

  const data = event.data.data();
  const title = data.title || "(제목 없음)";
  const content = data.content || "";
  const replyEmail = data.replyEmail || "(미입력)";

  const mailOptions = {
    from: `"예배찬송가 문의" <${gmailUser.value()}>`,
    to: "gbe0135@gmail.com",
    subject: `예배찬송가 문의[${title}]`,
    text: `
문의 제목: ${title}
문의 내용:
${content}
---------------------------
답변 받을 이메일 주소: ${replyEmail}
`,
    replyTo: replyEmail,
  };

  await transporter.sendMail(mailOptions);
  console.log("메일 전송 완료:", title);
});

// ---------------- Weekly Reset (V2 Schedule) ----------------
// 🔥 중요: functions.pubsub.schedule (v1) -> onSchedule (v2) 로 변경
exports.resetWeeklyCounts = onSchedule(
  {
    schedule: "0 0 * * 1", // 매주 월요일 00:00
    timeZone: "Asia/Seoul",
  },
  async (event) => {
    const statsRef = admin.firestore().collection("global_stats");
    const snapshots = await statsRef.get();

    const batch = admin.firestore().batch();
    snapshots.forEach((doc) => {
      batch.update(doc.ref, { weeklyCount: 0 });
    });

    await batch.commit();
    console.log("Weekly counts reset completed");
  }
);

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
const client = new OAuth2Client();

exports.googleLogin = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).send("POST only");

    const { idToken } = req.body || {};
    if (!idToken) return res.status(400).send("missing idToken");

    // 1) Google 토큰 검증
    const ticket = await client.verifyIdToken({
      idToken,
      audience: "800123758723-bqklphkptd2t5cpahu3kfocickl58rbp.apps.googleusercontent.com", // Firebase 콘솔 값 확인 필요
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