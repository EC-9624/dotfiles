const REGEX_META_PATTERN = /[\\^$.*+?()[\]{}|]/;
const WHITESPACE_PATTERN = /\s+/;
const SIMPLE_KEYWORD_PATTERN = /^[\p{L}\p{N}_./:-]+$/u;

const splitQueryTerms = (query: string): string[] => {
  return query.trim().split(WHITESPACE_PATTERN).filter(Boolean);
};

const escapeRegexLiteral = (value: string): string => {
  return value.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&");
};

export const isLikelyPlainKeywordList = (query: string): boolean => {
  if (REGEX_META_PATTERN.test(query)) {
    return false;
  }

  const terms = splitQueryTerms(query);
  if (terms.length < 3) {
    return false;
  }

  return terms.every((term) => SIMPLE_KEYWORD_PATTERN.test(term));
};

export const buildRegexOrSuggestion = (query: string): string => {
  return splitQueryTerms(query).map(escapeRegexLiteral).join("|");
};

export const formatNoMatchesMessage = (
  query: string,
  selectedName?: string
): string => {
  const baseMessage = `No matches found for "${query}"${
    selectedName ? ` in ${selectedName}` : ""
  }`;

  if (!isLikelyPlainKeywordList(query)) {
    return baseMessage;
  }

  return `${baseMessage}\n\nThis tool expects a regex pattern. For keyword OR, try: ${buildRegexOrSuggestion(
    query
  )}`;
};
