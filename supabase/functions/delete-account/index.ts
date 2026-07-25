// delete-account: removes the auth user; profiles/readings/usage/moderation rows
// cascade via foreign keys (§8). Settings → Delete Account calls this.

import { adminClient, json, userFromRequest } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  const user = await userFromRequest(req);
  if (!user) return json({ code: "unauthenticated" }, 401);

  const db = adminClient();
  const { error } = await db.auth.admin.deleteUser(user.id);
  if (error) {
    console.error("delete-account failed:", error.message);
    return json({ code: "server_error" }, 500);
  }

  return json({ status: "deleted" });
});
