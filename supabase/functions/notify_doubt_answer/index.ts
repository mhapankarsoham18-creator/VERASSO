import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

// These environment variables will be injected directly by Supabase Edge Functions
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_SERVER_KEY = Deno.env.get("FIREBASE_SERVER_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

serve(async (req) => {
  try {
    // Basic auth check for webhook
    const url = new URL(req.url);
    if (url.searchParams.get("secret") !== Deno.env.get("WEBHOOK_SECRET")) {
      return new Response("Unauthorized", { status: 401 });
    }

    const payload = await req.json();
    
    // We only care about new answers hitting the database
    if (payload.type !== "INSERT" || payload.table !== "doubt_answers") {
      return new Response("Not an insert to doubt_answers", { status: 200 });
    }

    const record = payload.record;
    
    // 1. Fetch the original doubt to find its author
    const { data: doubt, error: doubtError } = await supabase
      .from('doubts')
      .select('author_id, title')
      .eq('id', record.doubt_id)
      .single();

    if (doubtError || !doubt) {
      console.error("Doubt not found:", doubtError);
      return new Response("Doubt not found", { status: 404 });
    }

    // Do not notify if they answered their own question
    if (doubt.author_id === record.author_id) {
      return new Response("Author answered own doubt", { status: 200 });
    }

    // 2. Fetch the author's FCM token
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token, display_name')
      .eq('id', doubt.author_id)
      .single();

    if (profileError || !profile || !profile.fcm_token) {
      console.log("No FCM token found for user", doubt.author_id);
      return new Response("No FCM token", { status: 200 });
    }

    // 3. Send Push via Firebase Cloud Messaging Server API (Legacy HTTP or HTTP v1)
    // Using Legacy for ease of setup; in prod consider migrating to v1
    const fcmRes = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${FIREBASE_SERVER_KEY}`
      },
      body: JSON.stringify({
        to: profile.fcm_token,
        notification: {
          title: "New Answer Received! 🧠",
          body: `Someone just answered your doubt: "${doubt.title}"`,
          sound: "default"
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          route: `/doubt_detail/${record.doubt_id}`
        }
      })
    });

    const fcmResult = await fcmRes.json();
    console.log("FCM send result:", fcmResult);

    return new Response(JSON.stringify({ success: true, fcmResult }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error processing webhook:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
