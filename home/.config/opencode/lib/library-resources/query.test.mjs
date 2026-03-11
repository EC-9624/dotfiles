import assert from "node:assert/strict";
import test from "node:test";

import {
  buildRegexOrSuggestion,
  formatNoMatchesMessage,
  isLikelyPlainKeywordList,
} from "./query.ts";

test("detects likely plain keyword lists", () => {
  assert.equal(
    isLikelyPlainKeywordList("createStore default store Provider atom read write"),
    true
  );
  assert.equal(isLikelyPlainKeywordList("default store"), false);
  assert.equal(isLikelyPlainKeywordList("createStore|Provider|atom"), false);
});

test("builds escaped regex OR suggestions", () => {
  assert.equal(
    buildRegexOrSuggestion("createStore default store"),
    "createStore|default|store"
  );
  assert.equal(buildRegexOrSuggestion("foo.bar baz"), "foo\\.bar|baz");
});

test("adds regex guidance only for likely keyword lists", () => {
  assert.equal(
    formatNoMatchesMessage("createStore default store Provider", "jotai"),
    'No matches found for "createStore default store Provider" in jotai\n\nThis tool expects a regex pattern. For keyword OR, try: createStore|default|store|Provider'
  );
  assert.equal(
    formatNoMatchesMessage("default store", "jotai"),
    'No matches found for "default store" in jotai'
  );
});
