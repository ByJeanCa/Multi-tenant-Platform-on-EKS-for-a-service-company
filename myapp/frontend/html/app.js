function apiBase() {
  const cfg = window.__CONFIG__ || {};
  return (cfg.API_BASE_URL || "").replace(/\/+$/, "");
}

async function enqueue(email, payload) {
  const res = await fetch(`${apiBase()}/enqueue`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, payload }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`enqueue failed: ${res.status} ${text}`);
  }
  return res.json();
}

async function jobStatus(id) {
  const res = await fetch(`${apiBase()}/jobs/${encodeURIComponent(id)}`);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`status failed: ${res.status} ${text}`);
  }
  return res.json();
}

async function poll(id, onUpdate) {
  for (let i = 0; i < 30; i++) {
    const st = await jobStatus(id);
    onUpdate(st);
    if (["done", "failed"].includes(st.status)) return st;
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new Error("timeout polling job");
}

document.getElementById("send").addEventListener("click", async () => {
  const out = document.getElementById("out");
  const statusEl = document.getElementById("status");
  out.textContent = "";
  statusEl.textContent = "";

  try {
    const email = document.getElementById("email").value.trim();
    const payload = document.getElementById("payload").value;

    const data = await enqueue(email, payload);
    out.innerHTML = `job_id: <code>${data.id}</code>`;
    statusEl.textContent = "status: queued";

    await poll(data.id, (st) => {
      statusEl.textContent = `status: ${st.status} (celery_state=${st.celery_state})`;
    });
  } catch (e) {
    out.textContent = String(e);
  }
});