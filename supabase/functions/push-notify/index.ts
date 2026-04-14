// Supabase Edge Function: push-notify
// Triggered by a Database Webhook on INSERT into the `messages` table.
// Sends a generic FCM push to the receiver's device.
//
// Note: This function runs on the Supabase Deno runtime.
// IDE TypeScript errors about Deno modules are expected and can be ignored locally.

// deno-lint-ignore-file
// @ts-nocheck

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;

serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    if (!record) {
      return new Response("No record in payload", { status: 400 });
    }

    const senderId: string = record.sender_id;
    const conversationId: string = record.conversation_id;

    // Use the service role client to bypass RLS
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Find the receiver(s) in this conversation (everyone except sender)
    const { data: participants, error: partError } = await supabase
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", conversationId)
      .neq("user_id", senderId);

    if (partError || !participants || participants.length === 0) {
      return new Response("No recipients found", { status: 200 });
    }

    // 2. Get sender display name
    const { data: senderProfile } = await supabase
      .from("profiles")
      .select("display_name")
      .eq("id", senderId)
      .single();

    const senderName = senderProfile?.display_name ?? "Someone";

    // 3. For each participant, fetch their FCM token and send a push
    for (const participant of participants) {
      const { data: receiverProfile } = await supabase
        .from("profiles")
        .select("fcm_token")
        .eq("id", participant.user_id)
        .single();

      const fcmToken = receiverProfile?.fcm_token;
      if (!fcmToken) continue;

      // 4. Send FCM push — generic payload, no message content exposed
      await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `key=${FCM_SERVER_KEY}`,
        },
        body: JSON.stringify({
          to: fcmToken,
          notification: {
            title: "New Secure Message",
            body: `${senderName} sent you an encrypted message.`,
          },
          data: {
            conversation_id: conversationId,
            type: "new_message",
          },
        }),
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
    });
  }
});
