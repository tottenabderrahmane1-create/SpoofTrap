const fallbackRelease = {
  version: "1.7.2",
  generatedAt: "2026-04-12T20:00:00Z",
  artifacts: {
    pkg: {
      file: "SpoofTrap.pkg",
      sha256: "94b6cb3ba046878f6a86380f74d555a51e196c0c9e1c4ab189811b7fd6cafa02",
    },
    zip: {
      file: "SpoofTrap.zip",
      sha256: "5c9dce5dad0a8099c883898319386305c4206e513dcecca702d71f9107c8779f",
    },
    dmg: {
      file: "SpoofTrap.dmg",
      sha256: "77b7ba809cd5bc56d4191f75734e0c977007f720dec98d09dabc9c3cda53e90e",
    },
  },
};

function truncateHash(full) {
  if (!full || full.length < 32) return full || "—";
  const groups = [full.slice(0, 8), full.slice(8, 16), full.slice(16, 24), full.slice(24, 32)];
  return `${groups.join("·")}…`;
}

function setText(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = value;
}

function updateDownloadUi(release, distBase) {
  const version = release?.version || fallbackRelease.version;
  const pkg = release?.artifacts?.pkg || fallbackRelease.artifacts.pkg;
  const zip = release?.artifacts?.zip || fallbackRelease.artifacts.zip;
  const dmg = release?.artifacts?.dmg || fallbackRelease.artifacts.dmg;
  const generatedAt = release?.generatedAt
    ? new Date(release.generatedAt).toLocaleString(undefined, {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    : null;

  setText("version-label", `v${version}`);
  setText(
    "generated-at",
    generatedAt ? `Packaged on ${generatedAt}.` : "Packaged for macOS distribution."
  );

  const pkgLink = document.getElementById("pkg-link");
  const zipLink = document.getElementById("zip-link");
  const dmgLink = document.getElementById("dmg-link");
  if (pkgLink) pkgLink.href = `${distBase}/${pkg.file}`;
  if (zipLink) zipLink.href = `${distBase}/${zip.file}`;
  if (dmgLink) dmgLink.href = `${distBase}/${dmg.file}`;

  setText("pkg-file", pkg.file);
  setText("zip-file", zip.file);
  setText("dmg-file", dmg.file);

  setText("pkg-sha", pkg.sha256);
  setText("zip-sha", zip.sha256);
  setText("dmg-sha", dmg.sha256);

  setText("dmg-hash-short", truncateHash(dmg.sha256));
  setText("pkg-hash-short", truncateHash(pkg.sha256));
  setText("zip-hash-short", truncateHash(zip.sha256));
}

async function resolveRelease() {
  const distBases = ["./dist", "../dist"];
  for (const distBase of distBases) {
    try {
      const response = await fetch(`${distBase}/latest.json`);
      if (!response.ok) continue;
      const release = await response.json();
      return { release, distBase };
    } catch {
      // try next
    }
  }
  return { release: fallbackRelease, distBase: "./dist" };
}

resolveRelease().then(({ release, distBase }) => {
  updateDownloadUi(release, distBase);
});

// ---------------------------------------------------------------------
// Download tabs
// ---------------------------------------------------------------------
function initDownloadTabs() {
  const tabs = document.querySelectorAll(".download-tab");
  if (!tabs.length) return;
  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      const target = tab.dataset.tab;
      tabs.forEach((t) => {
        const active = t === tab;
        t.classList.toggle("is-active", active);
        t.setAttribute("aria-selected", active ? "true" : "false");
      });
      document.querySelectorAll(".download-panel-v2").forEach((panel) => {
        const active = panel.dataset.tabPanel === target;
        panel.classList.toggle("is-active", active);
        if (active) {
          panel.removeAttribute("hidden");
        } else {
          panel.setAttribute("hidden", "");
        }
      });
    });
  });
}

// ---------------------------------------------------------------------
// SHA-256 copy buttons
// ---------------------------------------------------------------------
function initIntegrityCopy() {
  const buttons = document.querySelectorAll(".integrity-copy");
  buttons.forEach((btn) => {
    btn.addEventListener("click", async () => {
      const targetId = btn.dataset.hashTarget;
      const sourceEl = targetId ? document.getElementById(targetId) : null;
      const full = sourceEl ? sourceEl.textContent.trim() : "";
      if (!full) return;
      try {
        if (navigator.clipboard && navigator.clipboard.writeText) {
          await navigator.clipboard.writeText(full);
        } else {
          const temp = document.createElement("textarea");
          temp.value = full;
          temp.setAttribute("readonly", "");
          temp.style.position = "fixed";
          temp.style.opacity = "0";
          document.body.appendChild(temp);
          temp.select();
          document.execCommand("copy");
          document.body.removeChild(temp);
        }
        const original = btn.textContent;
        btn.textContent = "Copied";
        btn.classList.add("is-copied");
        setTimeout(() => {
          btn.textContent = original;
          btn.classList.remove("is-copied");
        }, 1400);
      } catch {
        // ignore — clipboard APIs can fail silently in some contexts
      }
    });
  });
}

// ---------------------------------------------------------------------
// "How it works" terminal + flow timeline
// ---------------------------------------------------------------------
const HIW_SCRIPT = [
  { type: "cmd",  prompt: "$", text: "spooftrap --launch roblox --preset stable" },
  { type: "info", tag: "[spoofdpi]", text: "binding 127.0.0.1:8881  ok" },
  { type: "info", tag: "[route]   ", text: "intercept dns · tls fragmenting · ttl-shift" },
  { type: "warn", tag: "[probe]   ", text: "gateway deep-inspect detected  → engaging bypass" },
  { type: "ok",   tag: "[ok]      ", text: "handshake success · rbxcdn.com:443 reachable" },
  { type: "info", tag: "[launch]  ", text: "spawning Roblox.app" },
  { type: "ok",   tag: "[ok]      ", text: "session live · dc=miami02" },
  { type: "dim",  tag: "[ready]   ", text: "you are playing. close this window to end." },
];

function initHiwTerminal() {
  const terminal = document.getElementById("hiw-terminal");
  if (!terminal) return;

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (reduceMotion) {
    terminal.innerHTML = HIW_SCRIPT.map((line) => renderCompleteLine(line)).join("");
    return;
  }

  let lineIndex = 0;
  let charIndex = 0;
  let typingTimer = null;
  let loopTimer = null;

  function renderCompleteLine(line) {
    if (line.type === "cmd") {
      return `<span class="hiw-line is-cmd"><span class="hiw-prompt">${line.prompt}</span>${escapeHtml(line.text)}</span>`;
    }
    return `<span class="hiw-line is-${line.type}"><span class="hiw-tag">${escapeHtml(line.tag)}</span> ${escapeHtml(line.text)}</span>`;
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function startTyping() {
    terminal.innerHTML = "";
    lineIndex = 0;
    charIndex = 0;
    typeNext();
  }

  function typeNext() {
    if (lineIndex >= HIW_SCRIPT.length) {
      loopTimer = setTimeout(startTyping, 4200);
      return;
    }

    const line = HIW_SCRIPT[lineIndex];
    const lineEl = ensureLineEl(lineIndex, line);
    const contentBody = line.type === "cmd" ? line.text : line.text;

    if (charIndex === 0) {
      // prep line content wrappers
      if (line.type === "cmd") {
        lineEl.innerHTML = `<span class="hiw-prompt">${line.prompt}</span><span class="hiw-body"></span><span class="hiw-caret">|</span>`;
      } else {
        lineEl.innerHTML = `<span class="hiw-tag">${escapeHtml(line.tag)}</span> <span class="hiw-body"></span><span class="hiw-caret">|</span>`;
      }
    }

    const body = lineEl.querySelector(".hiw-body");
    charIndex += 1;
    body.textContent = contentBody.slice(0, charIndex);

    if (charIndex >= contentBody.length) {
      // finalize — drop caret, move to next line after a beat
      const caret = lineEl.querySelector(".hiw-caret");
      if (caret) caret.remove();
      lineIndex += 1;
      charIndex = 0;
      const pause = line.type === "cmd" ? 420 : 280;
      typingTimer = setTimeout(typeNext, pause);
    } else {
      const jitter = 14 + Math.random() * 22;
      typingTimer = setTimeout(typeNext, jitter);
    }
  }

  function ensureLineEl(index, line) {
    let el = terminal.children[index];
    if (!el) {
      el = document.createElement("span");
      el.className = `hiw-line is-${line.type}`;
      terminal.appendChild(el);
    }
    return el;
  }

  // Pause animation when tab/section is offscreen (saves CPU)
  let running = false;
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting && !running) {
          running = true;
          startTyping();
        } else if (!entry.isIntersecting && running) {
          running = false;
          clearTimeout(typingTimer);
          clearTimeout(loopTimer);
        }
      });
    },
    { threshold: 0.15 }
  );
  observer.observe(terminal);
}

function initHiwFlow() {
  const rows = document.querySelectorAll("#hiw-flow .hiw-row");
  if (!rows.length) return;

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduceMotion) {
    rows.forEach((r) => r.classList.add("is-active"));
    return;
  }

  let current = 0;
  function tick() {
    rows.forEach((row, idx) => {
      row.classList.toggle("is-active", idx === current);
    });
    current = (current + 1) % rows.length;
  }
  tick();
  setInterval(tick, 2400);
}

// ---------------------------------------------------------------------
// Bootstrap
// ---------------------------------------------------------------------
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", boot);
} else {
  boot();
}

function boot() {
  initDownloadTabs();
  initIntegrityCopy();
  initHiwTerminal();
  initHiwFlow();
}
