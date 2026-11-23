# Translate the shared dark OpenCode tokens into Pi's native theme roles.
def lookup($palette; $path; $refs):
  if ($path | length) == 0 then .
  else .[$path[0]] as $value
    | if ($value | type) == "string" and ($value | startswith("$")) then
        if $refs == 0 then error("too many theme token references: \($value)")
        else $palette | lookup($palette; ($value[1:] | split(".")) + $path[1:]; $refs - 1) end
      else $value | lookup($palette; $path[1:]; $refs) end
  end;

def color($palette; $token):
  ($palette | lookup($palette; $token | split("."); 16))
  | if type == "string" and test("^#([a-fA-F0-9]{3}|[a-fA-F0-9]{6})$") then .
    else error("invalid color at \($token): \(.)") end;

(.base * .dark) as $palette
| {
    "$schema": "https://pi.dev/schemas/theme.schema.json",
    name: "dotfiles-shared",
    appearance: "dark",
    colors: ({
      accent: "hue.accent.200",
      border: "border.base",
      borderAccent: "hue.interactive.200",
      borderMuted: "hue.neutral.500",
      success: "text.feedback.success.base",
      error: "text.feedback.error.base",
      warning: "text.feedback.warning.base",
      muted: "text.muted",
      dim: "text.muted",
      text: "text.base",
      thinkingText: "text.muted",
      scrollbarTrack: "border.base",
      scrollbarThumb: "scrollbar.base",
      selectedBg: "background.raised.max",
      userMessageBg: "background.raised.base",
      userMessageText: "text.base",
      customMessageBg: "background.raised.high",
      customMessageText: "text.base",
      customMessageLabel: "hue.accent.200",
      # Keep whole output cards neutral, like OpenCode. Diff and feedback text
      # still use their own colors.
      toolPendingBg: "background.raised.base",
      toolSuccessBg: "background.raised.base",
      toolErrorBg: "background.raised.base",
      toolTitle: "text.base",
      toolOutput: "text.base",
      mdHeading: "markdown.heading",
      mdLink: "markdown.link",
      mdLinkUrl: "markdown.linkText",
      mdCode: "markdown.code",
      mdCodeBlock: "markdown.codeBlock",
      mdCodeBlockBorder: "border.base",
      mdQuote: "markdown.blockQuote",
      mdQuoteBorder: "border.base",
      mdHr: "markdown.horizontalRule",
      mdListBullet: "markdown.listItem",
      toolDiffAdded: "diff.text.added",
      toolDiffRemoved: "diff.text.removed",
      toolDiffContext: "diff.text.context",
      syntaxComment: "syntax.comment",
      syntaxKeyword: "syntax.keyword",
      syntaxFunction: "syntax.function",
      syntaxVariable: "syntax.variable",
      syntaxString: "syntax.string",
      syntaxNumber: "syntax.number",
      syntaxType: "syntax.type",
      syntaxOperator: "syntax.operator",
      syntaxPunctuation: "syntax.punctuation",
      thinkingOff: "border.base",
      thinkingMinimal: "text.muted",
      thinkingLow: "markdown.linkText",
      thinkingMedium: "markdown.link",
      thinkingHigh: "markdown.heading",
      thinkingXhigh: "markdown.strong",
      bashMode: "text.feedback.warning.base"
    } | map_values(color($palette; .))),
    export: ({
      pageBg: "hue.neutral.800",
      cardBg: "background.raised.base",
      infoBg: "background.raised.high"
    } | map_values(color($palette; .)))
  }
