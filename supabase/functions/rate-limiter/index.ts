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
    return new Response(null, { status: 204, headers: { ...CORS, "Access-Control-Allow-Methods": "GET, POST, OPTIONS" } })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    const authHeader = req.headers.get('Authorization')
    const supabaseClient = createClient(
      supabaseUrl,
      supabaseAnonKey,
      { global: { headers: { Authorization: authHeader || '' } } }
    )

    // Get User ID & IP
    const { data: userData } = await supabaseClient.auth.getUser()
    const user = userData.user
    const ip = req.headers.get('x-forwarded-for') || 'unknown'

    const url = new URL(req.url)
    const endpoint = url.searchParams.get('endpoint') || url.pathname

    // Call DB RPC
    const { data, error } = await supabaseClient.rpc('check_rate_limit', {
      p_user_id: user?.id || null,
      p_ip_address: ip,
      p_endpoint: endpoint
    })

    if (error) throw error

    if (data && typeof data === 'object' && 'blocked' in data && data.blocked) {
      return new Response(JSON.stringify(data), {
        status: 429,
        headers: {
          ...CORS,
          'Retry-After': (data as any).retry_after?.toString() || '60'
        }
      })
    }

    return new Response(JSON.stringify(data), { status: 200, headers: CORS })

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: errorMessage }), { status: 400, headers: CORS })
  }
})
