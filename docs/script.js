const fallbackRelease = {
  version: "1.6.1",
  generatedAt: "2026-03-29T14:00:00Z",
  artifacts: {
    pkg: {
      file: "SpoofTrap.pkg",
      sha256: "a930732fc372ff6c032d337e376c5d497f31813802ae52698b3d2ac7e3a66d7d",
    },
    zip: {
      file: "SpoofTrap.zip",
      sha256: "1682c780fda873d21b423a9d8b74baa2c112fefedcc9cfae5afdbe836aa79c1e",
    },
    dmg: {
      file: "SpoofTrap.dmg",
      sha256: "7b833c5cf0a82738a0a205a2e70a207818b3b135f0938f5800d1f09e1b4704b8",
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
