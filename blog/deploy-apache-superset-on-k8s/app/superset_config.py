"""The override config file for Superset

This is a override of the default config for Superset.
Note that '/app/superset/config.py' is the default config file for Superset.
"""
import os
from typing import Any, Callable, Literal, TYPE_CHECKING, TypedDict

if "SUPERSET_HOME" in os.environ:
    DATA_DIR = os.environ["SUPERSET_HOME"]
else:
    DATA_DIR = os.path.expanduser("~/.superset")

# Your App secret key. Make sure you override it on superset_config.py
# or use `SUPERSET_SECRET_KEY` environment variable.
# Use a strong complex alphanumeric string and use a tool to help you generate
# a sufficiently random sequence, ex: openssl rand -base64 42"
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY") or CHANGE_ME_SECRET_KEY

# The SQLAlchemy connection string.
SQLALCHEMY_DATABASE_URI = (
    f"""sqlite:///{os.path.join(DATA_DIR, "superset.db")}?check_same_thread=false"""
)
# Try:
# SQLALCHEMY_DATABASE_URI = (
#     f"""{os.environ.get("SUPERSET_METADB_URI")}"""
# )
# use env like:
#     export SUPERSET_METADB_URI='sqlite:////app/superset_home/superset.db?check_same_thread=false'
#     export SUPERSET_METADB_URI='postgresql://superset:password@172.16.32.8:5432/superset

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True

# ---------------------------------------------------
# Roles config
# ---------------------------------------------------
# Grant public role the same set of permissions as for a selected builtin role.
# This is useful if one wants to enable anonymous users to view
# dashboards. Explicit grant on specific datasets is still required.
PUBLIC_ROLE_LIKE: str | None = 'Gamma'

# ---------------------------------------------------
# Feature flags
# ---------------------------------------------------
# Feature flags that are set by default go here. Their values can be
# overwritten by those specified under FEATURE_FLAGS in superset_config.py
# For example, DEFAULT_FEATURE_FLAGS = { 'FOO': True, 'BAR': False } here
# and FEATURE_FLAGS = { 'BAR': True, 'BAZ': True } in superset_config.py
# will result in combined feature flags of { 'FOO': True, 'BAR': True, 'BAZ': True }
DEFAULT_FEATURE_FLAGS: dict[str, bool] = {
    # Allow for javascript controls components
    # this enables programmers to customize certain charts (like the
    # geospatial ones) by inputting javascript in controls. This exposes
    # an XSS security vulnerability
    "ENABLE_JAVASCRIPT_CONTROLS": True,
    "VERSIONED_EXPORT": True,  # deprecated
    "EMBEDDED_SUPERSET": True,
}

# CORS Options
ENABLE_CORS = True
ALLOW_ORIGINS = ['http://192.168.101.129:8080','http://localhost:8080']
CORS_OPTIONS: dict[Any, Any] = {
    'supports_credentials': True,
    'allow_headers': ['*'],
    'resources':['*'],
    'origins': ALLOW_ORIGINS,
}

# If you want Talisman, how do you want it configured??
TALISMAN_CONFIG = {
    "content_security_policy": {
        "base-uri": ["'self'"],
        "default-src": ["'self'"],
        "frame-ancestors": ALLOW_ORIGINS,
        "img-src": ["'self'", "blob:", "data:"],
        "worker-src": ["'self'", "blob:"],
        "connect-src": [
            "'self'",
            "https://api.mapbox.com",
            "https://events.mapbox.com",
        ],
        "object-src": "'none'",
        "style-src": [
            "'self'",
            "'unsafe-inline'",
        ],
        "script-src": ["'self'", "'strict-dynamic'","'unsafe-eval'"],
    },
    "content_security_policy_nonce_in": ["script-src"],
    "force_https": False,
    "session_cookie_secure": False,
    "force_https_permanent": False,
    "frame_options": "ALLOWFROM",
    "frame_options_allow_from": "*",
}
