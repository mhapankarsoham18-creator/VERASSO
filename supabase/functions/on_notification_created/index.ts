// @ts-nocheck — Runs in Supabase Deno Edge Runtime
import { createClient } from "@supabase/supabase-js"
import { GoogleAuth } from "google-auth-library"
import "edge-runtime"

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, x-client-info, apikey",
  "Content-Type": "application/json",
}

async function getAccessToken(): Promise<string> {
    const serviceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") || "{}")
    if (!serviceAccount.project_id) {
        throw new Error("FCM_SERVICE_ACCOUNT not configured correctly")
    }
    const auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: "https://www.googleapis.com/auth/firebase.messaging",
    })
    const client = await auth.getClient()
    const token = await client.getAccessToken()
    return token.token || ""
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: { ...CORS, "Access-Control-Allow-Methods": "POST, OPTIONS" } })
  }

  try {
    const { record } = await req.json()

    if (!record || !record.user_id) {
      return new Response(JSON.stringify({ error: "Invalid record: missing user_id" }), { status: 400, headers: CORS })
    }

    // Get user profile (FCM token)
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    const supabaseClient = createClient(supabaseUrl, supabaseServiceRoleKey)

    const { data: profile, error: profileError } = await supabaseClient
      .from("profiles")
      .select("fcm_token")
      .eq("id", record.user_id)
      .single()

    if (profileError || !profile?.fcm_token) {
      return new Response(
        JSON.stringify({ success: false, reason: "No FCM token found for user", error: profileError }),
        { status: 200, headers: CORS }
      )
    }

    if (!FCM_SERVER_KEY) {
      return new Response(
        JSON.stringify({ error: "FCM_SERVER_KEY not configured" }),
        { status: 500, headers: CORS }
      )
    }

    // Prepare FCM payload (HTTP v1 structure)
    const serviceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") || "{}")
    const projectId = serviceAccount.project_id
    if (!projectId) throw new Error("Missing project_id in service account")

    const message = {
      message: {
        token: profile.fcm_token,
        notification: {
          title: record.title || "New Notification",
          body: record.message || record.content || "Check your app for updates",
        },
        data: record.metadata || {},
      }
    }

    const accessToken = await getAccessToken()

    // Send to FCM HTTP v1
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    })

    const result = await response.json()

    return new Response(
      JSON.stringify({ success: response.ok, fcm_response: result }),
      { status: response.ok ? 200 : response.status, headers: CORS }
    )

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: errorMessage }), { status: 500, headers: CORS })
  }
})
