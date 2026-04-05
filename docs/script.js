const fallbackRelease = {
  version: "1.5.1",
  generatedAt: "2026-04-05T10:30:00Z",
  artifacts: {
    pkg: {
      file: "SpoofTrap.pkg",
      sha256: "e7f4d821dc5503779814b526f8b09cfbdb2a28ad7c5aed768c154f9b3517ac82",
    },
    zip: {
      file: "SpoofTrap.zip",
      sha256: "524584d68f3c36fb6e6e5835bdddc82a98150a116b676e14da89ed4623bf2e4f",
    },
    dmg: {
      file: "SpoofTrap.dmg",
      sha256: "d1598d095b396c41dbbc3506433ca4ff0f24734e3f6951b3be85ef8b99bfdabf",
    },
  },
};

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

  document.getElementById("version-label").textContent = `v${version}`;
  document.getElementById("generated-at").textContent = generatedAt
    ? `Packaged on ${generatedAt}.`
    : "Packaged for macOS distribution.";

  const pkgLink = document.getElementById("pkg-link");
  const zipLink = document.getElementById("zip-link");
  const dmgLink = document.getElementById("dmg-link");

  pkgLink.href = `${distBase}/${pkg.file}`;
  zipLink.href = `${distBase}/${zip.file}`;
  dmgLink.href = `${distBase}/${dmg.file}`;

  document.getElementById("pkg-file").textContent = pkg.file;
  document.getElementById("zip-file").textContent = zip.file;
  document.getElementById("dmg-file").textContent = dmg.file;

  const pkgSha = document.getElementById("pkg-sha");
  const zipSha = document.getElementById("zip-sha");
  const dmgSha = document.getElementById("dmg-sha");

  if (pkgSha) {
    pkgSha.textContent = pkg.sha256;
  }

  if (zipSha) {
    zipSha.textContent = zip.sha256;
  }

  if (dmgSha) {
    dmgSha.textContent = dmg.sha256;
  }
}

async function resolveRelease() {
  const distBases = ["./dist", "../dist"];

  for (const distBase of distBases) {
    try {
      const response = await fetch(`${distBase}/latest.json`);
      if (!response.ok) {
        continue;
      }

      const release = await response.json();
      return { release, distBase };
    } catch {
      // Try the next candidate.
    }
  }

  return { release: fallbackRelease, distBase: "../dist" };
}

resolveRelease().then(({ release, distBase }) => {
  updateDownloadUi(release, distBase);
});
