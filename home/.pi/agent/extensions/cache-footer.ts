import { unwatchFile, watchFile } from "node:fs";
import { homedir } from "node:os";
import { join, sep } from "node:path";
import {
  getAgentDir,
  SettingsManager,
  type ExtensionAPI,
  type ExtensionContext,
  type SessionEntry,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const separator = " · ";

function formatTokens(count: number): string {
  if (count < 1_000) return String(count);
  if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function getEntryUsage(entry: SessionEntry) {
  switch (entry.type) {
    case "usage":
    case "compaction":
    case "branch_summary":
      return entry.usage;
    case "message": {
      const { message } = entry;
      if (message.role === "assistant" || message.role === "toolResult") return message.usage;
      break;
    }
  }
  return undefined;
}

function summarize(entries: SessionEntry[]) {
  const totals = { input: 0, output: 0, read: 0, write: 0, cost: 0 };
  let hit: number | undefined;
  for (const entry of entries) {
    const usage = getEntryUsage(entry);
    if (!usage) continue;
    totals.input += usage.input;
    totals.output += usage.output;
    totals.read += usage.cacheRead;
    totals.write += usage.cacheWrite;
    totals.cost += usage.cost.total;
    // Totals cover the whole session, but hit rate uses the latest assistant response.
    if (entry.type === "message" && entry.message.role === "assistant") {
      const prompt = usage.input + usage.cacheRead + usage.cacheWrite;
      hit = prompt > 0 ? usage.cacheRead / prompt * 100 : undefined;
    }
  }
  return { ...totals, hit };
}

function renderStats(
  stats: ReturnType<typeof summarize>,
  context: ReturnType<ExtensionContext["getContextUsage"]>,
  ctx: ExtensionContext,
  autoCompact: boolean,
  theme: Theme,
): string {
  const { input, output, read, write, cost, hit } = stats;
  const tokens = [input ? `↑${formatTokens(input)}` : "", output ? `↓${formatTokens(output)}` : ""];
  const parts = [tokens.filter(Boolean).join(" ")];
  if (read) parts.push(`Cache read ${formatTokens(read)}`);
  if (write) parts.push(`Cache write ${formatTokens(write)}`);
  if ((read || write) && hit !== undefined) parts.push(`hit ${hit.toFixed(1)}%`);

  const { model, modelRegistry } = ctx;
  const subscribed = model && (model.provider === "kimi-coding" || (
    modelRegistry.isUsingOAuth(model) &&
    modelRegistry.getProvider(model.provider)?.auth.oauth?.isSubscription === true
  ));
  if (cost || subscribed) parts.push(`$${cost.toFixed(3)}${subscribed ? " (sub)" : ""}`);

  const percent = context?.percent;
  const percentText = percent === null ? "?" : `${(percent ?? 0).toFixed(1)}%`;
  const contextWindow = context?.contextWindow ?? model?.contextWindow ?? 0;
  const contextText = `${percentText}/${formatTokens(contextWindow)}${autoCompact ? " (auto)" : ""}`;
  const contextColor = (percent ?? 0) > 90 ? "error" : (percent ?? 0) > 70 ? "warning" : "muted";
  const statsText = parts.filter(Boolean).join(separator);
  return (statsText ? theme.fg("muted", statsText + separator) : "") + theme.fg(contextColor, contextText);
}

function layoutFooter(location: string, stats: string, model: string, width: number): string[] {
  const modelWidth = visibleWidth(model);
  const withModel = (line: string) => {
    const padding = width - visibleWidth(line) - modelWidth;
    return padding >= 2 ? line + " ".repeat(padding) + model : undefined;
  };
  const statsWithModel = withModel(stats);
  if (statsWithModel) return [truncateToWidth(location, width), statsWithModel];

  // Keep the stats on one row; move the model up if it can't fit beside them.
  return [withModel(location) ?? truncateToWidth(location, width), truncateToWidth(stats, width)];
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    ctx.ui.setFooter((tui, theme, footerData) => {
      const agentDir = getAgentDir();
      const projectTrusted = ctx.isProjectTrusted();
      const settings = SettingsManager.create(ctx.cwd, agentDir, { projectTrusted });
      const settingsFiles = [join(agentDir, "settings.json")];
      if (projectTrusted) settingsFiles.push(join(ctx.cwd, ".pi", "settings.json"));
      const refreshSettings = () => {
        void settings.reload().then(() => tui.requestRender()).catch(() => {});
      };
      for (const path of settingsFiles) watchFile(path, { interval: 1000, persistent: false }, refreshSettings);
      const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

      const session = ctx.sessionManager;
      let cached: {
        leaf: ReturnType<typeof session.getLeafId>;
        model: typeof ctx.model;
        stats: ReturnType<typeof summarize>;
        context: ReturnType<typeof ctx.getContextUsage>;
      } | undefined;
      const home = homedir();
      const cwd = session.getCwd();
      const displayCwd = cwd === home ? "~" : cwd.startsWith(home + sep) ? `~${cwd.slice(home.length)}` : cwd;

      return {
        dispose() {
          unsubscribe();
          for (const path of settingsFiles) unwatchFile(path, refreshSettings);
        },
        invalidate() {},
        render(width: number): string[] {
          const leaf = session.getLeafId();
          const model = ctx.model;
          if (!cached || cached.leaf !== leaf || cached.model !== model) {
            const stats = cached && cached.leaf === leaf ? cached.stats : summarize(session.getEntries());
            cached = { leaf, model, stats, context: ctx.getContextUsage() };
          }
          const statsLine = renderStats(cached.stats, cached.context, ctx, settings.getCompactionEnabled(), theme);

          const branch = footerData.getGitBranch();
          const name = session.getSessionName();
          const location = theme.fg("muted", displayCwd + (branch ? ` (${branch})` : "") + (name ? ` • ${name}` : ""));
          const modelText = (model?.id ?? "no-model") + (model?.reasoning ? ` • ${pi.getThinkingLevel()}` : "");
          const lines = layoutFooter(location, statsLine, theme.fg("muted", modelText), width);
          const statuses = [...footerData.getExtensionStatuses()]
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([, text]) => text.replace(/[\r\n\t]/g, " ").trim());
          if (statuses.length) lines.push(truncateToWidth(statuses.join(" "), width));
          return lines;
        },
      };
    });
  });
}
