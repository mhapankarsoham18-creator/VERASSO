// Backend Sync API Endpoints (Backend Code)
// Should be implemented with your backend framework (Node.js/Express, Python/FastAPI, etc.)

// Example Supabase PostgreSQL RLS Policies + Edge Functions
// This file documents the backend structure for Phase 1

// SUPABASE EDGE FUNCTION: api_v2_sync_delta
// 
// Handles incoming delta syncs from clients
// Performs conflict detection and merging
// Returns updated version vectors and resolution info

// Pseudo-TypeScript/JavaScript (Deno) Implementation:

/* 
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

interface DeltaSyncRequest {
  documentId: string;
  delta: {
    documentId: string;
    lastSyncedVersion: number;
    currentVersion: Record<string, number>;
    content: Record<string, unknown>;
    timestamp: number;
  };
  vectorClock: Record<string, number>;
}

interface DeltaSyncResponse {
  success: boolean;
  hasConflict: boolean;
  remoteVersion?: Record<string, number>;
  mergedContent?: Record<string, unknown>;
  resolutionStrategy?: string;
  error?: string;
}

serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    const userId = extractUserIdFromToken(authHeader);
    
    if (!userId) {
      return new Response("Unauthorized", { status: 401 });
    }

    const body = (await req.json()) as DeltaSyncRequest;
    const { documentId, delta, vectorClock } = body;

    // Get current server version of document
    const { data: serverDoc, error: docError } = await supabase
      .from("documents_v2")
      .select("*")
      .eq("id", documentId)
      .single();

    if (docError && docError.code !== "PGRST116") {
      throw docError;
    }

    // If document doesn't exist, create it
    if (!serverDoc) {
      const { error: insertError } = await supabase
        .from("documents_v2")
        .insert({
          id: documentId,
          user_id: userId,
          content: delta.content,
          vector_clock: vectorClock,
          version: 1,
          last_synced_at: new Date(),
        });

      if (insertError) throw insertError;

      return new Response(
        JSON.stringify({
          success: true,
          hasConflict: false,
        } as DeltaSyncResponse),
      );
    }

    // Check for conflicts using vector clocks
    const serverVersion = serverDoc.vector_clock as Record<string, number>;
    const hasConflict = isVectorClockConcurrent(vectorClock, serverVersion);

    if (hasConflict) {
      // Versions are concurrent - potential conflict
      const resolution = await resolveConflict(
        delta.content,
        serverDoc.content,
        userId,
        serverDoc.user_id,
        documentId,
      );

      if (resolution.success) {
        // Update document with resolved content
        const newVectorClock = mergeVectorClocks(vectorClock, serverVersion);
        newVectorClock[userId] = (newVectorClock[userId] || 0) + 1;

        const { error: updateError } = await supabase
          .from("documents_v2")
          .update({
            content: resolution.mergedContent,
            vector_clock: newVectorClock,
            version: (serverDoc.version || 0) + 1,
            last_synced_at: new Date(),
          })
          .eq("id", documentId);

        if (updateError) throw updateError;

        return new Response(
          JSON.stringify({
            success: true,
            hasConflict: true,
            remoteVersion: newVectorClock,
            mergedContent: resolution.mergedContent,
            resolutionStrategy: resolution.strategy,
          } as DeltaSyncResponse),
        );
      } else {
        // Cannot auto-resolve, return conflict info
        return new Response(
          JSON.stringify({
            success: false,
            hasConflict: true,
            remoteVersion: serverVersion,
            error: "Conflict requires manual resolution",
          } as DeltaSyncResponse),
          { status: 409 },
        );
      }
    } else {
      // No conflict, apply delta
      const newVectorClock = mergeVectorClocks(vectorClock, serverVersion);
      newVectorClock[userId] = (newVectorClock[userId] || 0) + 1;

      const { error: updateError } = await supabase
        .from("documents_v2")
        .update({
          content: delta.content,
          vector_clock: newVectorClock,
          version: (serverDoc.version || 0) + 1,
          last_synced_at: new Date(),
        })
        .eq("id", documentId);

      if (updateError) throw updateError;

      return new Response(
        JSON.stringify({
          success: true,
          hasConflict: false,
          remoteVersion: newVectorClock,
        } as DeltaSyncResponse),
      );
    }
  } catch (error) {
    console.error(error);
    return new Response(
      JSON.stringify({
        success: false,
        hasConflict: false,
        error: error instanceof Error ? error.message : "Unknown error",
      } as DeltaSyncResponse),
      { status: 500 },
    );
  }
});

function isVectorClockConcurrent(
  clock1: Record<string, number>,
  clock2: Record<string, number>,
): boolean {
  // Two clocks are concurrent if neither happens-before the other
  let clock1Before = false;
  let clock2Before = false;

  const allKeys = new Set([...Object.keys(clock1), ...Object.keys(clock2)]);

  for (const key of allKeys) {
    const val1 = clock1[key] || 0;
    const val2 = clock2[key] || 0;

    if (val1 < val2) clock1Before = true;
    if (val1 > val2) clock2Before = true;
  }

  // Concurrent if both have some component less than the other
  return clock1Before && clock2Before;
}

function mergeVectorClocks(
  clock1: Record<string, number>,
  clock2: Record<string, number>,
): Record<string, number> {
  const merged: Record<string, number> = {};
  const allKeys = new Set([...Object.keys(clock1), ...Object.keys(clock2)]);

  for (const key of allKeys) {
    merged[key] = Math.max(clock1[key] || 0, clock2[key] || 0);
  }

  return merged;
}

async function resolveConflict(
  localContent: Record<string, unknown>,
  remoteContent: Record<string, unknown>,
  localUserId: string,
  remoteUserId: string,
  documentId: string,
): Promise<{
  success: boolean;
  mergedContent?: Record<string, unknown>;
  strategy?: string;
}> {
  // Implement field-level merge strategy
  const merged: Record<string, unknown> = { ...remoteContent };

  // Add fields from local that don't conflict
  for (const key in localContent) {
    if (!(key in remoteContent)) {
      merged[key] = localContent[key];
    } else if (JSON.stringify(localContent[key]) === JSON.stringify(remoteContent[key])) {
      // Same value, keep it
      continue;
    } else {
      // Conflicting field - log for manual review
      await logConflict(documentId, localUserId, remoteUserId, key);
      // Keep remote version for now
    }
  }

  return {
    success: true,
    mergedContent: merged,
    strategy: "field-level-merge",
  };
}

async function logConflict(
  documentId: string,
  localUserId: string,
  remoteUserId: string,
  field: string,
): Promise<void> {
  // Log to conflicts table for monitoring/analysis
  await supabase.from("sync_conflicts").insert({
    document_id: documentId,
    local_user_id: localUserId,
    remote_user_id: remoteUserId,
    conflicting_field: field,
    detected_at: new Date(),
  });
}

function extractUserIdFromToken(authHeader?: string | null): string | null {
  if (!authHeader) return null;
  const token = authHeader.replace("Bearer ", "");
  // Verify JWT and extract user_id claim
  // This is simplified - use proper JWT verification in production
  try {
    const payload = JSON.parse(atob(token.split(".")[1]!));
    return payload.sub || payload.user_id || null;
  } catch {
    return null;
  }
}
*/

// SQL Schema for Backend (Supabase PostgreSQL)
// To be applied in supabase_updates_v51.sql

/*
-- Documents v2 table with vector clock support
CREATE TABLE IF NOT EXISTS public.documents_v2 (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  content JSONB NOT NULL DEFAULT '{}',
  vector_clock JSONB NOT NULL DEFAULT '{}',
  version INTEGER DEFAULT 1,
  last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sync conflicts tracking
CREATE TABLE IF NOT EXISTS public.sync_conflicts (
  id BIGSERIAL PRIMARY KEY,
  document_id TEXT REFERENCES public.documents_v2(id) ON DELETE CASCADE,
  local_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  remote_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  conflicting_field TEXT,
  detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sync metadata for tracking sync state
CREATE TABLE IF NOT EXISTS public.sync_metadata (
  id BIGSERIAL PRIMARY KEY,
  document_id TEXT UNIQUE REFERENCES public.documents_v2(id) ON DELETE CASCADE,
  last_synced_version INTEGER,
  last_synced_at TIMESTAMP WITH TIME ZONE,
  pending_operations_count INTEGER DEFAULT 0,
  is_synced BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Change log for audit trail
CREATE TABLE IF NOT EXISTS public.change_log (
  id BIGSERIAL PRIMARY KEY,
  document_id TEXT REFERENCES public.documents_v2(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  operation TEXT,
  timestamp BIGINT,
  vector_clock JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indices for performance
CREATE INDEX idx_documents_v2_user_id ON public.documents_v2(user_id);
CREATE INDEX idx_documents_v2_document_type ON public.documents_v2(document_type);
CREATE INDEX idx_sync_conflicts_document_id ON public.sync_conflicts(document_id);
CREATE INDEX idx_sync_metadata_document_id ON public.sync_metadata(document_id);
CREATE INDEX idx_change_log_document_id ON public.change_log(document_id);

-- RLS Policies
ALTER TABLE public.documents_v2 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own documents" 
  ON public.documents_v2 FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own documents" 
  ON public.documents_v2 FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create documents" 
  ON public.documents_v2 FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Sync conflicts are readable by relevant users
ALTER TABLE public.sync_conflicts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view conflicts for their documents" 
  ON public.sync_conflicts FOR SELECT 
  USING (
    local_user_id = auth.uid() OR 
    remote_user_id = auth.uid() OR
    document_id IN (
      SELECT id FROM public.documents_v2 
      WHERE user_id = auth.uid()
    )
  );
*/

// Flutter client integration example:
// 1. Create IndexDbSyncService instance
// 2. Create SmartSyncEngine with baseUrl pointing to your backend
// 3. Add ConflictDetectionService for advanced conflict handling
// 4. Wire up to UI to show sync progress and conflict prompts
