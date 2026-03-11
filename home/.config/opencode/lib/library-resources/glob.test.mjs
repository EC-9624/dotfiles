import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import test from "node:test";

import { listRelativeFiles, matchesFullGlob } from "./glob.ts";

test("matches basename globs against nested files", () => {
  assert.equal(matchesFullGlob("docs/core/provider.mdx", "*.mdx"), true);
  assert.equal(matchesFullGlob("src/react/Provider.ts", "*.mdx"), false);
});

test("matches nested and brace glob patterns", () => {
  assert.equal(matchesFullGlob("docs/core/provider.mdx", "docs/**/*.mdx"), true);
  assert.equal(
    matchesFullGlob("docs/core/provider.mdx", "**/*.{md,mdx,ts,tsx}"),
    true
  );
  assert.equal(
    matchesFullGlob("src/react/Provider.ts", "**/*.{md,mdx,ts,tsx}"),
    true
  );
  assert.equal(matchesFullGlob("src/react/Provider.ts", "docs/**/*.mdx"), false);
});

test("lists relative files while excluding ignored directories", () => {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "resource-search-glob-"));

  try {
    fs.mkdirSync(path.join(tempRoot, "docs", "core"), { recursive: true });
    fs.mkdirSync(path.join(tempRoot, "node_modules", "pkg"), { recursive: true });
    fs.writeFileSync(path.join(tempRoot, "README.md"), "readme\n");
    fs.writeFileSync(path.join(tempRoot, "docs", "core", "provider.mdx"), "provider\n");
    fs.writeFileSync(path.join(tempRoot, "node_modules", "pkg", "index.js"), "ignored\n");

    assert.deepEqual(
      listRelativeFiles(tempRoot, new Set(["node_modules"]))
        .slice()
        .sort(),
      ["README.md", "docs/core/provider.mdx"]
    );
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
});
