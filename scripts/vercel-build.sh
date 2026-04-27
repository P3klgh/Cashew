#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/flutter/bin:$PATH"
cd budget

flutter pub get

flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
