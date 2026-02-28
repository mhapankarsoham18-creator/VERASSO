// @ts-nocheck — Runs in Supabase Deno Edge Runtime
import { createClient } from "@supabase/supabase-js"
import "edge-runtime"

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, x-client-info, apikey",
  "Content-Type": "application/json",
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: { ...CORS, "Access-Control-Allow-Methods": "POST, OPTIONS" } })
  }

  try {
    const { code, consume = false } = await req.json()

    if (!code) {
      return new Response(JSON.stringify({ is_valid: false, message: "No code provided" }), {
        status: 400, headers: CORS
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey)

    // Validate the code
    const { data: validationResult, error: validationError } = await supabaseClient
      .rpc('validate_invite_code', { p_code: code })
      .single()

    if (validationError) throw validationError

    const result = validationResult as { is_valid: boolean; message: string; metadata: any }

    // Consume the code if requested and valid
    if (result.is_valid && consume) {
      const { data: consumed, error: consumeError } = await supabaseClient
        .rpc('consume_invite_code', { p_code: code })

      if (consumeError || !consumed) {
        return new Response(JSON.stringify({
          is_valid: false,
          message: "Failed to consume invite code."
        }), { status: 400, headers: CORS })
      }
    }

    return new Response(JSON.stringify(result), { status: 200, headers: CORS })

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ is_valid: false, message: errorMessage }), {
      status: 400, headers: CORS
    })
  }
})
