#!/usr/bin/env python3
"""Safe connectivity check for the RESET NIGHT ChatGPT + Gemini team."""
import json
import os
import sys
import re
import urllib.error
import urllib.request

def request(url, headers=None, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers or {}, method="GET" if data is None else "POST")
    try:
        with urllib.request.urlopen(req, timeout=45) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")[:1200]
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc

def safe_error(exc):
    """Redact API credentials before writing provider errors to Actions logs."""
    message = str(exc)
    for name in ("OPENAI_API_KEY", "GEMINI_API_KEY"):
        secret = os.getenv(name)
        if secret:
            message = message.replace(secret, "[REDACTED]")
    message = re.sub(r"sk-[A-Za-z0-9_-]{8,}", "[REDACTED_OPENAI_KEY]", message)
    return message[:1200]

def openai_check():
    key = os.environ["OPENAI_API_KEY"]
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    models = request("https://api.openai.com/v1/models", headers)
    available = {item["id"] for item in models.get("data", [])}
    preferred = os.getenv("OPENAI_MODEL", "gpt-5-mini")
    candidates = [preferred, "gpt-5-mini", "gpt-4.1-mini"]
    model = next((name for name in candidates if name in available), None)
    if not model:
        raise RuntimeError("API anahtarı geçerli, ancak desteklenen varsayılan modeller bulunamadı. OPENAI_MODEL değişkenini kontrol edin.")
    result = request("https://api.openai.com/v1/responses", headers, {
        "model": model,
        "input": "Reply with exactly: OPENAI_CONNECTED",
        "max_output_tokens": 40
    })
    text = " ".join(
        part.get("text", "")
        for item in result.get("output", [])
        for part in item.get("content", [])
        if part.get("type") == "output_text"
    )
    if "OPENAI_CONNECTED" not in text:
        raise RuntimeError("OpenAI yanıt verdi ancak doğrulama metni eşleşmedi.")
    return model

def gemini_check():
    key = os.environ["GEMINI_API_KEY"]
    # Use the API-key header so the secret is not embedded in request URLs/logs.
    api_headers = {"x-goog-api-key": key}
    models_data = request(
        "https://generativelanguage.googleapis.com/v1beta/models",
        api_headers
    )
    models = models_data.get("models", [])
    usable = [
        item for item in models
        if "generateContent" in item.get("supportedGenerationMethods", [])
    ]

    preferred = os.getenv("GEMINI_MODEL", "").strip()
    # Prefer current Flash models, but dynamically use the model catalogue
    # instead of assuming a retired model ID remains available.
    def rank(item):
        name = item.get("name", "").split("/")[-1].lower()
        if name == preferred.lower():
            return (0, name)
        if "3.1" in name and "flash" in name:
            return (1, name)
        if "3.0" in name and "flash" in name:
            return (2, name)
        if "2.5" in name and "flash" in name:
            return (3, name)
        if "flash" in name:
            return (4, name)
        return (9, name)

    candidates = sorted(
        [item for item in usable if "flash" in item.get("name", "").lower()],
        key=rank
    )
    if not candidates:
        raise RuntimeError(
            "Gemini API anahtarı modelleri listeledi ancak generateContent "
            "destekleyen Flash modeli bulunamadı."
        )

    errors = []
    for item in candidates:
        model_path = item["name"]
        model = model_path.split("/")[-1]
        endpoint = (
            "https://generativelanguage.googleapis.com/v1beta/"
            f"{model_path}:generateContent"
        )
        try:
            result = request(endpoint, {
                **api_headers,
                "Content-Type": "application/json"
            }, {
                "contents": [{"parts": [{"text": "Reply with exactly: GEMINI_CONNECTED"}]}],
                "generationConfig": {"maxOutputTokens": 40, "temperature": 0}
            })
            text = " ".join(
                part.get("text", "")
                for candidate in result.get("candidates", [])
                for part in candidate.get("content", {}).get("parts", [])
            )
            if "GEMINI_CONNECTED" in text:
                return model
            errors.append(f"{model}: yanıt doğrulaması eşleşmedi")
        except Exception as exc:
            # A model can remain listed briefly after retirement. Try the
            # next supported Flash model instead of aborting the whole check.
            errors.append(f"{model}: {safe_error(exc)}")

    raise RuntimeError(
        "Listelenen Flash modellerinin hiçbiri test isteğini kabul etmedi. "
        + " | ".join(errors[:4])
    )

def main():
    missing = [name for name in ("OPENAI_API_KEY", "GEMINI_API_KEY") if not os.getenv(name)]
    if missing:
        print("Eksik GitHub Secrets: " + ", ".join(missing), file=sys.stderr)
        sys.exit(1)
    failures = []

    # Run both providers independently: one provider's quota/auth error must
    # never prevent checking the other provider.
    for provider, check in (("OPENAI", openai_check), ("GEMINI", gemini_check)):
        try:
            model = check()
            print(f"{provider}_OK model={model}")
        except Exception as exc:
            message = safe_error(exc)
            failures.append(provider)
            print(f"{provider}_FAILED: {message}", file=sys.stderr)

    if failures:
        print("CONNECTION_FAILED providers=" + ",".join(failures), file=sys.stderr)
        sys.exit(1)

    print("RESET_NIGHT_AI_TEAM_CONNECTION_OK")

if __name__ == "__main__":
    main()
