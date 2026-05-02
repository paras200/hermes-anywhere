#!/usr/bin/env python3
"""Quick browser chatbox using OpenRouter free models."""

import json
import os
from flask import Flask, request, Response, stream_with_context

app = Flask(__name__)

OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY")
if not OPENROUTER_API_KEY:
    raise SystemExit(
        "OPENROUTER_API_KEY not set. Export it in your shell or load via .env "
        "before running chatbox.py."
    )
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

DEFAULT_MODEL = "openai/gpt-oss-120b:free"

FREE_MODELS = [
    ("openai/gpt-oss-120b:free", "GPT-OSS 120B"),
    ("openai/gpt-oss-20b:free", "GPT-OSS 20B"),
    ("nvidia/nemotron-3-super-120b-a12b:free", "Nemotron 3 Super 120B"),
    ("google/gemma-3-12b-it:free", "Gemma 3 12B"),
    ("google/gemma-3-27b-it:free", "Gemma 3 27B"),
    ("google/gemma-4-31b-it:free", "Gemma 4 31B"),
    ("meta-llama/llama-3.3-70b-instruct:free", "Llama 3.3 70B"),
    ("nousresearch/hermes-3-llama-3.1-405b:free", "Hermes 3 405B"),
    ("qwen/qwen3-coder:free", "Qwen 3 Coder 480B"),
]

HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Hermes Chatbox</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         background: #1a1a2e; color: #e0e0e0; height: 100vh; display: flex;
         flex-direction: column; }
  .header { padding: 12px 20px; background: #16213e; border-bottom: 1px solid #0f3460;
            display: flex; align-items: center; gap: 12px; }
  .header h1 { font-size: 18px; color: #e94560; }
  .header select { background: #0f3460; color: #e0e0e0; border: 1px solid #533483;
                   padding: 6px 10px; border-radius: 6px; font-size: 13px; }
  .chat { flex: 1; overflow-y: auto; padding: 20px; display: flex;
          flex-direction: column; gap: 12px; }
  .msg { max-width: 80%; padding: 10px 14px; border-radius: 12px;
         line-height: 1.5; font-size: 14px; white-space: pre-wrap;
         word-wrap: break-word; transition: opacity 0.2s; }
  .msg.user { align-self: flex-end; background: #533483; color: #fff; }
  .msg.assistant { align-self: flex-start; background: #16213e;
                   border: 1px solid #0f3460; }
  .msg.error { align-self: flex-start; background: #2d1525;
               border: 1px solid #e94560; color: #ff8a a0; }
  .msg.error .error-title { color: #e94560; font-weight: 600;
                            margin-bottom: 4px; font-size: 13px; }
  .msg.error .error-detail { color: #ccc; font-size: 13px; }
  .msg.error .error-hint { color: #888; font-size: 12px; margin-top: 6px;
                           font-style: italic; }
  .msg.assistant code { background: #0f3460; padding: 2px 5px; border-radius: 3px;
                        font-size: 13px; }
  .msg.assistant pre { background: #0f3460; padding: 10px; border-radius: 6px;
                       overflow-x: auto; margin: 8px 0; }
  .msg.assistant pre code { background: none; padding: 0; }
  .thinking { align-self: flex-start; display: flex; align-items: center;
              gap: 8px; padding: 10px 14px; font-size: 13px; color: #888; }
  .thinking .dots { display: inline-flex; gap: 4px; }
  .thinking .dots span { width: 6px; height: 6px; border-radius: 50%;
                         background: #533483; animation: pulse 1.4s infinite ease-in-out; }
  .thinking .dots span:nth-child(2) { animation-delay: 0.2s; }
  .thinking .dots span:nth-child(3) { animation-delay: 0.4s; }
  @keyframes pulse {
    0%, 80%, 100% { opacity: 0.3; transform: scale(0.8); }
    40% { opacity: 1; transform: scale(1.2); }
  }
  .input-area { padding: 16px 20px; background: #16213e;
                border-top: 1px solid #0f3460; display: flex; gap: 10px; }
  .input-area textarea { flex: 1; background: #0f3460; color: #e0e0e0;
                         border: 1px solid #533483; border-radius: 8px;
                         padding: 10px 14px; font-size: 14px; resize: none;
                         font-family: inherit; outline: none; min-height: 44px;
                         max-height: 120px; }
  .input-area textarea:focus { border-color: #e94560; }
  .input-area button { background: #e94560; color: #fff; border: none;
                       border-radius: 8px; padding: 10px 20px; font-size: 14px;
                       cursor: pointer; font-weight: 600; }
  .input-area button:hover { background: #c73651; }
  .input-area button:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
</head>
<body>
<div class="header">
  <h1>Hermes Chatbox</h1>
  <select id="model">
    MODEL_OPTIONS
  </select>
</div>
<div class="chat" id="chat"></div>
<div class="input-area">
  <textarea id="input" placeholder="Type a message..." rows="1"
            onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();send()}"></textarea>
  <button id="sendBtn" onclick="send()">Send</button>
</div>
<script>
const chatEl = document.getElementById('chat');
const input = document.getElementById('input');
const sendBtn = document.getElementById('sendBtn');
let messages = [];

input.addEventListener('input', () => {
  input.style.height = 'auto';
  input.style.height = Math.min(input.scrollHeight, 120) + 'px';
});

function scrollBottom() { chatEl.scrollTop = chatEl.scrollHeight; }

function showThinking() {
  const div = document.createElement('div');
  div.className = 'thinking';
  div.id = 'thinking-indicator';
  div.innerHTML = '<div class="dots"><span></span><span></span><span></span></div> Thinking...';
  chatEl.appendChild(div);
  scrollBottom();
  return div;
}

function removeThinking() {
  const el = document.getElementById('thinking-indicator');
  if (el) el.remove();
}

function showError(errorMsg, detail, hint) {
  const div = document.createElement('div');
  div.className = 'msg error';
  let html = '<div class="error-title">' + escapeHtml(errorMsg) + '</div>';
  if (detail) html += '<div class="error-detail">' + escapeHtml(detail) + '</div>';
  if (hint) html += '<div class="error-hint">' + escapeHtml(hint) + '</div>';
  div.innerHTML = html;
  chatEl.appendChild(div);
  scrollBottom();
}

function parseError(raw) {
  try {
    const ej = JSON.parse(raw);
    if (ej.error) {
      const code = ej.error.code || '';
      const msg = ej.error.message || 'Unknown error';
      const provider = ej.error.metadata?.provider_name || '';
      if (code === 429) {
        return {
          title: 'Rate limited' + (provider ? ' (' + provider + ')' : ''),
          detail: 'This free model is temporarily unavailable due to high demand.',
          hint: 'Try switching to a different model from the dropdown, or wait a minute and retry.'
        };
      }
      return {
        title: (code ? '[' + code + '] ' : '') + msg,
        detail: provider ? 'Provider: ' + provider : '',
        hint: 'Try a different model or check your API key.'
      };
    }
  } catch {}
  return { title: 'Something went wrong', detail: raw.slice(0, 200), hint: 'Try again or switch models.' };
}

function escapeHtml(s) {
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}

async function send() {
  const text = input.value.trim();
  if (!text || sendBtn.disabled) return;

  messages.push({role: 'user', content: text});
  appendMsg('user', text);
  input.value = '';
  input.style.height = 'auto';
  sendBtn.disabled = true;

  const thinkingEl = showThinking();

  try {
    const res = await fetch('/chat', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        messages: messages,
        model: document.getElementById('model').value
      })
    });

    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let full = '';
    let assistantDiv = null;
    let gotError = false;
    let buf = '';

    while (true) {
      const {done, value} = await reader.read();
      if (done) break;
      buf += decoder.decode(value, {stream: true});
      const lines = buf.split('\\n');
      buf = lines.pop();

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith(':')) continue;

        // Non-SSE JSON error
        if (!trimmed.startsWith('data:') && trimmed.startsWith('{')) {
          try {
            const ej = JSON.parse(trimmed);
            if (ej.error) {
              removeThinking();
              const e = parseError(trimmed);
              showError(e.title, e.detail, e.hint);
              messages.pop();
              gotError = true;
              break;
            }
          } catch {}
        }
        if (!trimmed.startsWith('data: ')) continue;
        const data = trimmed.slice(6);
        if (data === '[DONE]') continue;

        try {
          const j = JSON.parse(data);
          if (j.error) {
            removeThinking();
            const e = parseError(data);
            showError(e.title, e.detail, e.hint);
            messages.pop();
            gotError = true;
            break;
          }
          const delta = j.choices?.[0]?.delta?.content;
          if (delta) {
            if (!assistantDiv) {
              removeThinking();
              assistantDiv = appendMsg('assistant', '');
            }
            full += delta;
            assistantDiv.textContent = full;
            scrollBottom();
          }
        } catch {}
      }
      if (gotError) break;
    }

    if (!gotError && !full) {
      removeThinking();
      showError('No response received', 'The model returned an empty response.', 'Try again or switch to a different model.');
      messages.pop();
    } else if (!gotError && full) {
      messages.push({role: 'assistant', content: full});
    }
  } catch (e) {
    removeThinking();
    showError('Connection error', e.message, 'Check that the chatbox server is running and try again.');
    messages.pop();
  } finally {
    removeThinking();
    sendBtn.disabled = false;
    input.focus();
    scrollBottom();
  }
}

function appendMsg(role, text) {
  const div = document.createElement('div');
  div.className = 'msg ' + role;
  div.textContent = text;
  chatEl.appendChild(div);
  scrollBottom();
  return div;
}

input.focus();
</script>
</body>
</html>"""


@app.route("/")
def index():
    options = "\n".join(
        f'    <option value="{slug}"{" selected" if slug == DEFAULT_MODEL else ""}>'
        f"{name}</option>"
        for slug, name in FREE_MODELS
    )
    return HTML.replace("MODEL_OPTIONS", options)


@app.route("/chat", methods=["POST"])
def chat():
    import requests

    body = request.json
    payload = {
        "model": body.get("model", DEFAULT_MODEL),
        "messages": body["messages"],
        "stream": True,
    }

    def generate():
        with requests.post(
            OPENROUTER_URL,
            headers={
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
            },
            json=payload,
            stream=True,
            timeout=60,
        ) as r:
            for line in r.iter_lines():
                if line:
                    yield line.decode() + "\n"

    return Response(
        stream_with_context(generate()),
        content_type="text/event-stream",
    )


if __name__ == "__main__":
    print("Chatbox running at http://localhost:5001")
    app.run(host="127.0.0.1", port=5001, debug=False)
