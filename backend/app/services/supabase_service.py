from functools import lru_cache

from supabase import create_client


@lru_cache(maxsize=1)
def get_supabase_client(url, key):
    if not url or not key:
        raise RuntimeError(
            "Supabase is not configured. "
            "Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY."
        )

    return create_client(url, key)