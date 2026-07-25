// Minimal AWS SigV4 presigner for Cloudflare R2 (S3-compatible), Web Crypto only.
// Presigned URLs expire in 5 minutes (CLAUDE.md §6.1.3).

const encoder = new TextEncoder();

async function hmac(key: ArrayBuffer | Uint8Array, data: string): Promise<ArrayBuffer> {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    key instanceof Uint8Array ? key as unknown as ArrayBuffer : key,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(data));
}

async function sha256Hex(data: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(data));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function toHex(buffer: ArrayBuffer): string {
  return [...new Uint8Array(buffer)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export interface R2Config {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
}

export function r2ConfigFromEnv(): R2Config {
  const accountId = Deno.env.get("R2_ACCOUNT_ID");
  const accessKeyId = Deno.env.get("R2_ACCESS_KEY_ID");
  const secretAccessKey = Deno.env.get("R2_SECRET_ACCESS_KEY");
  const bucket = Deno.env.get("R2_BUCKET");
  if (!accountId || !accessKeyId || !secretAccessKey || !bucket) {
    throw new Error("R2 secrets not configured");
  }
  return { accountId, accessKeyId, secretAccessKey, bucket };
}

/// Presign a GET/PUT/DELETE for `key`, valid for `expiresSeconds`.
export async function presignR2(
  config: R2Config,
  method: "GET" | "PUT" | "DELETE",
  key: string,
  expiresSeconds = 300,
): Promise<string> {
  const host = `${config.accountId}.r2.cloudflarestorage.com`;
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, ""); // YYYYMMDDTHHMMSSZ
  const dateStamp = amzDate.slice(0, 8);
  const region = "auto";
  const service = "s3";
  const scope = `${dateStamp}/${region}/${service}/aws4_request`;

  const canonicalUri = `/${config.bucket}/${key.split("/").map(encodeURIComponent).join("/")}`;
  const query = new URLSearchParams({
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": `${config.accessKeyId}/${scope}`,
    "X-Amz-Date": amzDate,
    "X-Amz-Expires": String(expiresSeconds),
    "X-Amz-SignedHeaders": "host",
  });
  // Canonical query must be sorted.
  const canonicalQuery = [...query.entries()]
    .sort(([a], [b]) => (a < b ? -1 : 1))
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join("&");

  const canonicalRequest = [
    method,
    canonicalUri,
    canonicalQuery,
    `host:${host}\n`,
    "host",
    "UNSIGNED-PAYLOAD",
  ].join("\n");

  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    scope,
    await sha256Hex(canonicalRequest),
  ].join("\n");

  let signingKey = await hmac(encoder.encode(`AWS4${config.secretAccessKey}`), dateStamp);
  signingKey = await hmac(signingKey, region);
  signingKey = await hmac(signingKey, service);
  signingKey = await hmac(signingKey, "aws4_request");
  const signature = toHex(await hmac(signingKey, stringToSign));

  return `https://${host}${canonicalUri}?${canonicalQuery}&X-Amz-Signature=${signature}`;
}

/// Delete an object immediately. Used by analyze-palm's finally block (§6.1.1).
export async function deleteR2Object(config: R2Config, key: string): Promise<void> {
  const url = await presignR2(config, "DELETE", key, 60);
  const response = await fetch(url, { method: "DELETE" });
  // 204 on success, 404 if already gone — both acceptable end states.
  if (!response.ok && response.status !== 404) {
    console.error(`R2 delete failed for key with status ${response.status}`);
  }
}
