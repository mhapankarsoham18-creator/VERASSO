// @ts-nocheck — Runs in Supabase Deno Edge Runtime
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
    const { content } = await req.json()

    if (!content) {
      return new Response(JSON.stringify({ error: "No content provided" }), { status: 400, headers: CORS })
    }

    const apiKey = Deno.env.get('OPENAI_API_KEY')
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "OpenAI API Key not configured" }), { status: 500, headers: CORS })
    }

    const openaiResponse = await fetch('https://api.openai.com/v1/moderations', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({ input: content })
    })

    const moderationData = await openaiResponse.json()
    const result = moderationData.results[0]

    return new Response(JSON.stringify({
      flagged: result.flagged,
      categories: result.categories,
      scores: result.category_scores
    }), { status: 200, headers: CORS })

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: errorMessage }), { status: 500, headers: CORS })
  }
})
