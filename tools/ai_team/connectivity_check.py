#!/usr/bin/env python3
"""Safe connectivity check for the RESET NIGHT ChatGPT + Gemini team."""
import json
import os
import sys
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

def openai_check():
    key = os.environ["OPENAI_API_KEY"]
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    models = request("https://api.openai.com/v1/models", headers)
    available = {item["id"] for item in models.get("data", [])}
    preferred = os.getenv("OPENAI_MODEL", "gpt-6-astra")
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
    models_data = request(f"https://generativelanguage.googleapis.com/v1beta/models?key={key}")
    models = models_data.get("models", [])
    preferred = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    usable = [
        item for item in models
        if "generateContent" in item.get("supportedGenerationMethods", [])
    ]
    by_name = {item["name"].split("/")[-1]: item["name"] for item in usable}
    candidates = [preferred, "gemini-3.1-flash", "gemini-2.5-flash"]
    model = next((name for name in candidates if name in by_name), None)
    if not model:
        model = next((name.split("/")[-1] for name in by_name if "flash" in name.lower()), None)
    if not model:
        raise RuntimeError("Gemini anahtarı geçerli, ancak generateContent destekleyen Flash modeli bulunamadı.")
    endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    result = request(endpoint, {"Content-Type": "application/json"}, {
        "contents": [{"parts": [{"text": "Reply with exactly: GEMINI_CONNECTED"}]}],
        "generationConfig": {"maxOutputTokens": 40, "temperature": 0}
    })
    text = " ".join(
        part.get("text", "")
        for candidate in result.get("candidates", [])
        for part in candidate.get("content", {}).get("parts", [])
    )
    if "GEMINI_CONNECTED" not in text:
        raise RuntimeError("Gemini yanıt verdi ancak doğrulama metni eşleşmedi.")
    return model

def main():
    missing = [name for name in ("OPENAI_API_KEY", "GEMINI_API_KEY") if not os.getenv(name)]
    if missing:
        print("Eksik GitHub Secrets: " + ", ".join(missing), file=sys.stderr)
        sys.exit(1)
    try:
        openai_model = openai_check()
        print(f"OPENAI_OK model={openai_model}")
        gemini_model = gemini_check()
        print(f"GEMINI_OK model={gemini_model}")
        print("RESET_NIGHT_AI_TEAM_CONNECTION_OK")
    except Exception as exc:
        print(f"CONNECTION_FAILED: {exc}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
