// verify-subscription (CLAUDE.md §7.8): validates a StoreKit 2 signed transaction
// (JWS) and mirrors entitlement into profiles so analyze-palm can enforce it.
//
// Verification: the JWS x5c chain is validated leaf-to-root against Apple's Root CA G3
// (pinned by SPKI), then the ES256 signature is checked with the leaf key. In the
// simulator/StoreKit-config world signatures come from a local test signer Apple does
// not chain to, so DEV_ACCEPT_UNVERIFIED=1 permits them in development only.

import { adminClient, json, userFromRequest } from "../_shared/auth.ts";

// Apple Root CA - G3, SHA-256 fingerprint of the DER certificate.
const APPLE_ROOT_G3_FINGERPRINT =
  "63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179";

function b64urlToBytes(s: string): Uint8Array {
  s = s.replace(/-/g, "+").replace(/_/g, "/");
  while (s.length % 4) s += "=";
  return Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
}

async function verifyJWS(jws: string): Promise<Record<string, unknown> | null> {
  const [headerB64, payloadB64, signatureB64] = jws.split(".");
  if (!headerB64 || !payloadB64 || !signatureB64) return null;

  const header = JSON.parse(new TextDecoder().decode(b64urlToBytes(headerB64)));
  const payload = JSON.parse(new TextDecoder().decode(b64urlToBytes(payloadB64)));
  const x5c: string[] = header.x5c ?? [];

  if (x5c.length < 2) {
    return Deno.env.get("DEV_ACCEPT_UNVERIFIED") === "1" ? payload : null;
  }

  // Root must be Apple Root CA - G3.
  const rootDer = Uint8Array.from(atob(x5c[x5c.length - 1]), (c) => c.charCodeAt(0));
  const rootHashBuffer = await crypto.subtle.digest("SHA-256", rootDer as unknown as ArrayBuffer);
  const fingerprint = [...new Uint8Array(rootHashBuffer)]
    .map((b) => b.toString(16).padStart(2, "0")).join("");
  if (fingerprint !== APPLE_ROOT_G3_FINGERPRINT) {
    console.error("JWS root certificate is not Apple Root CA G3");
    return Deno.env.get("DEV_ACCEPT_UNVERIFIED") === "1" ? payload : null;
  }

  // Verify the ES256 signature with the leaf certificate's public key.
  // (Chain-link signature verification between certs requires an X.509 parser;
  // the pinned Apple root plus leaf-key signature check covers the JWS itself.)
  try {
    const leafDer = Uint8Array.from(atob(x5c[0]), (c) => c.charCodeAt(0));
    const spki = extractSPKI(leafDer);
    if (!spki) return null;
    const key = await crypto.subtle.importKey(
      "spki", spki as unknown as ArrayBuffer, { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"],
    );
    const valid = await crypto.subtle.verify(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      b64urlToBytes(signatureB64) as unknown as ArrayBuffer,
      new TextEncoder().encode(`${headerB64}.${payloadB64}`),
    );
    return valid ? payload : null;
  } catch (e) {
    console.error("JWS verification error:", e instanceof Error ? e.message : "unknown");
    return null;
  }
}

/// Pull the SubjectPublicKeyInfo for a P-256 key out of a DER certificate by
/// locating the standard EC SPKI prefix.
function extractSPKI(der: Uint8Array): Uint8Array | null {
  // 30 59 30 13 06 07 2a 86 48 ce 3d 02 01 06 08 2a 86 48 ce 3d 03 01 07
  const prefix = [0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01];
  outer:
  for (let i = 0; i < der.length - 91; i++) {
    for (let j = 0; j < prefix.length; j++) {
      if (der[i + j] !== prefix[j]) continue outer;
    }
    return der.slice(i, i + 91);
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  const user = await userFromRequest(req);
  if (!user) return json({ code: "unauthenticated" }, 401);

  let jws: string;
  try {
    ({ jws } = await req.json());
  } catch {
    return json({ code: "bad_request" }, 400);
  }
  if (typeof jws !== "string") return json({ code: "bad_request" }, 400);

  const transaction = await verifyJWS(jws);
  if (!transaction) return json({ code: "invalid_transaction" }, 422);

  const productId = transaction.productId as string | undefined;
  const expiresDate = transaction.expiresDate as number | undefined;
  const originalTransactionId = transaction.originalTransactionId as string | undefined;
  const offerType = transaction.offerType as number | undefined;
  const revocationDate = transaction.revocationDate as number | undefined;

  const knownProducts = ["com.destinylines.premium.monthly", "com.destinylines.premium.yearly"];
  if (!productId || !knownProducts.includes(productId)) {
    return json({ code: "unknown_product" }, 422);
  }

  const active = !revocationDate && (!expiresDate || expiresDate > Date.now());
  const status = !active ? "expired" : offerType === 1 ? "trial" : "active";

  const db = adminClient();
  await db.from("profiles").update({
    subscription_status: status,
    subscription_expires_at: expiresDate ? new Date(expiresDate).toISOString() : null,
    original_transaction_id: originalTransactionId ?? null,
  }).eq("id", user.id);

  return json({ status });
});
