import re
import requests
import sys
from typing import List, Optional

# ANSI escape codes for colors
RED = '\033[91m'
BLUE = '\033[94m'
GREEN = '\033[92m'
YELLOW = '\033[93m'
CYAN = '\033[96m'
RESET = '\033[0m'

def find_sensitive_data(content: str, patterns_with_colors: List[tuple[str, str]]) -> Optional[List[str]]:
    """
    Searches content for sensitive data using a list of (regex, color) tuples.

    Args:
        content: The string content to scan.
        patterns_with_colors: A list of tuples, where each tuple contains a
                             regular expression and its corresponding color code.

    Returns:
        A list of colored matching strings, or None if no matches are found.
    """
    colored_matches = []
    for pattern, color in patterns_with_colors:
        found_matches = re.findall(pattern, content, re.MULTILINE)
        if found_matches:
            for match in found_matches:
                if isinstance(match, tuple):
                    colored_matches.append(f"{color}{match[0]}{RESET}")
                else:
                    colored_matches.append(f"{color}{match}{RESET}")
    return colored_matches if colored_matches else None



def main():
    """
    Reads a list of URLs, scans for sensitive data with colored output.
    """
    if len(sys.argv) == 1:
        urls = [line.strip() for line in sys.stdin]
    else:
        urls = sys.argv[1:]

    patterns_with_colors = [
        # API Keys (Red)
        (r"(API_KEY|api_key|CLIENT_ID|client_id|consumerKey|consumer_key)\s*[:=]\s*['\"]?([a-zA-Z0-9_-]{10,})", RED),
        (r"(SECRET_KEY|secret_key|CLIENT_SECRET|clientSecret|consumerSecret|consumer_secret)\s*[:=]\s*['\"]?([a-zA-Z0-9_-]{20,})", RED),
        (r"[a-zA-Z0-9]{32}-[-a-zA-Z0-9]{36}", RED),  # UUID/GUID like keys
        (r"sk_live_([a-zA-Z0-9_]{20,})", RED),  # Stripe live secret key
        (r"pk_live_([a-zA-Z0-9_]{20,})", RED),  # Stripe live public key
        (r"AWS_ACCESS_KEY_ID\s*=\s*['\"]?([A-Z0-9]{16,})", RED),
        (r"AWS_SECRET_ACCESS_KEY\s*=\s*['\"]?([a-zA-Z0-9+/=]{40,})", RED),
        (r"google_api\s*key\s*[:=]\s*['\"]?([a-zA-Z0-9_-]+)", RED),
        (r"google_maps_api_key\s*=\s*['\"]?([a-zA-Z0-9_-]+)", RED),
        (r"reCAPTCHA_site_key\s*=\s*['\"]?(6L[a-zA-Z0-9_-]{37})", RED),
        (r"TWILIO_ACCOUNT_SID\s*=\s*['\"]?(AC[a-zA-Z0-9_]{32})", RED),
        (r"TWILIO_AUTH_TOKEN\s*=\s*['\"]?([a-zA-Z0-9_]{32})", RED),
        (r"TWILIO_APP_SID\s*=\s*['\"]?(AP[a-zA-Z0-9_]{32})", RED),
        (r"FACEBOOK_APP_ID\s*=\s*['\"]?([0-9]{10,})", RED),
        (r"FACEBOOK_APP_SECRET\s*=\s*['\"]?([a-zA-Z0-9]{32})", RED),
        (r"GITHUB_TOKEN\s*=\s*['\"]?(ghp_[a-zA-Z0-9]{36})", RED),
        (r"SLACK_BOT_TOKEN\s*=\s*['\"]?(xoxb-[a-zA-Z0-9-]+)", RED),
        (r"SLACK_APP_TOKEN\s*=\s*['\"]?(xapp-[a-zA-Z0-9-]+)", RED),
        (r"STRIPE_PUBLISHABLE_KEY\s*=\s*['\"]?(pk_(test|live)_[a-zA-Z0-9_]+)", RED),
        (r"STRIPE_SECRET_KEY\s*=\s*['\"]?(sk_(test|live)_[a-zA-Z0-9_]+)", RED),
        (r"SENTRY_DSN\s*=\s*['\"]?(https?://[^@]+@[^/]+/[0-9]+)", RED),

        # Tokens (Yellow)
        (r"(accessToken|access_token|authToken|auth_token)\s*[:=]\s*['\"]?([a-zA-Z0-9_-]{20,})", YELLOW),
        (r"jwtToken\s*[:=]\s*['\"]?([a-zA-Z0-9._-]+)", YELLOW),
        (r"bearerToken\s*[:=]\s*['\"]?([a-zA-Z0-9._-]+)", YELLOW),

        # API Endpoints (Blue)
        (r"(https?://[a-zA-Z0-9.-]+\.[a-z]{2,}(:[0-9]+)?[/a-zA-Z0-9_/.-]+)", BLUE),
        (r"(/[a-zA-Z0-9_/.-]+\.(json|xml|api))", BLUE),
        (r"wss?://[a-zA-Z0-9.-]+\.[a-z]{2,}(:[0-9]+)?/[a-zA-Z0-9_/.-]+", BLUE), # WebSocket URLs

        # URLs (Cyan) - Catching other potential URLs
        (r"https?://[a-zA-Z0-9.-]+\.[a-z]{2,}(:[0-9]+)?(/[\w.-]+)+/?", CYAN),

        # Email Addresses (Green) - Could be useful context
        (r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", GREEN),
    ]

    for url in urls:
        if not url:
            continue  # Skip empty URLs
        print(f"Scanning {url}")
        try:
            # Set a timeout to prevent indefinite hanging
            response = requests.get(url, timeout=10)
            response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
            content = response.text
        except requests.exceptions.RequestException as e:
            print(f"Error downloading {url}: {e}")
            continue # Continue to the next URL

        colored_matches = find_sensitive_data(content, patterns_with_colors)
        if colored_matches:
            for match in colored_matches:
                print(f"  {url}: {match}")
        else:
            print("  No hit")
    print("-" * 40)
    print("Finished processing URLs.")

if __name__ == "__main__":
    main()
