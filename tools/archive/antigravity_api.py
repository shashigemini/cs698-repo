"""
Antigravity Local API Explorer
Based on the technique described by kaisergod47.

Reads conversations from the running Antigravity process via its local HTTP API.
Enumerates ALL conversations (not just the current workspace) by reading
cascade IDs from the local .pb files, then fetching steps via the API.

Usage:
  python antigravity_api.py list                  # List all conversations
  python antigravity_api.py read <cascade_id>     # Print one conversation
  python antigravity_api.py export [output_dir]   # Export all to .txt files
                                                  # (default: ./exported_conversations)

Dependencies: pip install psutil
"""

import json
import os
import re
import sys
import urllib.request

import psutil


# ---------------------------------------------------------------------------
# Server detection (uses psutil — no PowerShell)
# ---------------------------------------------------------------------------

def _find_language_server() -> psutil.Process:
    """Find the running Antigravity language server process."""
    for proc in psutil.process_iter(["name", "pid"]):
        try:
            if "language_server" in (proc.info["name"] or ""):
                return proc
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    raise RuntimeError(
        "Could not find language_server process. Is Antigravity running?"
    )


def get_server_info() -> tuple[str, int]:
    """Extract CSRF token and listening port via psutil (no shell)."""
    proc = _find_language_server()

    try:
        args = proc.cmdline()
    except (psutil.NoSuchProcess, psutil.AccessDenied) as e:
        raise RuntimeError(f"Cannot read process cmdline: {e}") from e

    token = None
    for i, arg in enumerate(args):
        if arg == "--csrf_token" and i + 1 < len(args):
            token = args[i + 1]
            break

    if not token:
        raise RuntimeError(
            f"Could not find --csrf_token in: {' '.join(args)[:200]}"
        )

    try:
        connections = proc.net_connections(kind="tcp")
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        connections = [
            c for c in psutil.net_connections(kind="tcp")
            if c.pid == proc.pid
        ]

    ports = [
        c.laddr.port
        for c in connections
        if c.status == psutil.CONN_LISTEN
    ]

    for p in ports:
        try:
            req = urllib.request.Request(
                f"http://localhost:{p}/exa.language_server_pb"
                ".LanguageServerService/GetAllCascadeTrajectories",
                data=b"{}",
                headers={
                    "Content-Type": "application/json",
                    "Connect-Protocol-Version": "1",
                    "X-Codeium-Csrf-Token": token,
                },
            )
            with urllib.request.urlopen(req, timeout=2) as resp:
                resp.read()
                return token, p
        except Exception:
            continue

    raise RuntimeError(f"Could not find working API port among: {ports}")


# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

def api_call(token: str, port: int, method: str, body: dict) -> dict:
    """Make a Connect RPC call to the Antigravity language server."""
    url = (
        f"http://localhost:{port}/exa.language_server_pb"
        f".LanguageServerService/{method}"
    )
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={
            "Content-Type": "application/json",
            "Connect-Protocol-Version": "1",
            "X-Codeium-Csrf-Token": token,
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


def get_all_cascade_ids() -> list[str]:
    """
    Return all cascade IDs by reading .pb filenames from the local data dir.
    This bypasses the workspace-scoping of GetAllCascadeTrajectories and
    returns ALL conversations regardless of which project they belong to.
    """
    # Resolve from the language server's --app_data_dir arg.
    # Antigravity stores conversations in ~/.gemini/<app_data_dir>/conversations/
    pb_dir = None
    try:
        proc = _find_language_server()
        args = proc.cmdline()
        for i, arg in enumerate(args):
            if arg == "--app_data_dir" and i + 1 < len(args):
                pb_dir = os.path.join(
                    os.path.expanduser("~"),
                    ".gemini", args[i + 1], "conversations",
                )
                break
    except Exception:
        pass

    if not pb_dir or not os.path.isdir(pb_dir):
        return []

    return [f[:-3] for f in sorted(os.listdir(pb_dir)) if f.endswith(".pb")]


def get_workspace_summaries(token: str, port: int) -> dict[str, dict]:
    """
    Return trajectory summaries from the API (workspace-scoped).
    Keyed by cascade_id. Each summary may include workspace info.
    """
    data = api_call(token, port, "GetAllCascadeTrajectories", {})
    return data.get("trajectorySummaries", {})


def fetch_steps(
    token: str, port: int, cascade_id: str, step_count: int | None = None
) -> list[dict]:
    """Fetch all steps for a conversation in batches."""
    steps: list[dict] = []
    batch = 50
    start = 0
    last_batch_ids = []

    while True:
        end = start + batch
        data = api_call(
            token, port,
            "GetCascadeTrajectorySteps",
            {"cascadeId": cascade_id, "startIndex": start, "endIndex": end},
        )
        batch_steps = data.get("steps", [])
        
        # If the API ignores pagination and returns the exact same steps, break
        current_batch_ids = [s.get("id") for s in batch_steps]
        if current_batch_ids == last_batch_ids:
            break
        last_batch_ids = current_batch_ids

        # Deduplicate just in case
        for s in batch_steps:
            if s not in steps:
                steps.append(s)

        if len(batch_steps) < batch:
            break
        if step_count is not None and len(steps) >= step_count:
            break
        start = end

    return steps


# ---------------------------------------------------------------------------
# Step text extraction
# ---------------------------------------------------------------------------

def extract_user_text(step: dict) -> str | None:
    """
    Extract the user's typed message from a USER_INPUT step.

    userResponse = the raw typed text (may include @[macro] references).
    items = expanded content sent to the model (file content, problems, etc.)
    """
    ui = step.get("userInput", {})
    typed = ui.get("userResponse", "").strip()
    return typed if typed else None


def extract_assistant_text(step: dict) -> str | None:
    """Extract assistant reply from a PLANNER_RESPONSE step."""
    pr = step.get("plannerResponse", {})
    for field in ("thinking", "text", "message"):
        text = pr.get(field, "").strip()
        if text:
            return text
    parts = [
        block.get("text", "").strip()
        for block in pr.get("content", [])
        if isinstance(block, dict) and block.get("text", "").strip()
    ]
    return "\n".join(parts) if parts else None


def extract_notify_text(step: dict) -> str | None:
    """Extract text from a NOTIFY_USER step."""
    nu = step.get("notifyUser", {})
    for field in ("notificationContent", "message", "text"):
        text = nu.get(field, "").strip()
        if text:
            return text
    return None


_STEP_HANDLERS: dict[str, tuple[str, object]] = {
    "CORTEX_STEP_TYPE_USER_INPUT": ("USER", extract_user_text),
    "CORTEX_STEP_TYPE_PLANNER_RESPONSE": ("ASSISTANT", extract_assistant_text),
    "CORTEX_STEP_TYPE_NOTIFY_USER": ("ASSISTANT", extract_notify_text),
}


def steps_to_text(steps: list[dict]) -> str:
    """Convert a list of steps to a readable conversation transcript."""
    lines: list[str] = []
    for step in steps:
        step_type = step.get("type", "")
        if step_type not in _STEP_HANDLERS:
            continue
        label, extractor = _STEP_HANDLERS[step_type]
        text = extractor(step)  # type: ignore[operator]
        if not text:
            continue
        timestamp = step.get("metadata", {}).get("createdAt", "")[:19]
        lines.append(f"[{label}] {timestamp}")
        lines.append(text)
        lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def _workspace_name(info: dict) -> str:
    """
    Derive a short folder name from the trajectory summary's workspace info.
    Uses the last segment of the workspace folder URI, e.g. 'cs698-repo'.
    Falls back to '_unknown' for conversations with no API metadata.
    """
    for ws in info.get("workspaces", []):
        uri = ws.get("workspaceFolderAbsoluteUri", "")
        name = uri.rstrip("/").rsplit("/", 1)[-1]
        name = re.sub(r"[^\w\-]", "_", name)
        if name:
            return name
    return "_unknown"


def list_conversations(token: str, port: int) -> None:
    """List all conversations (from .pb files + API metadata)."""
    summaries = get_workspace_summaries(token, port)
    all_ids = get_all_cascade_ids()
    if not all_ids:
        all_ids = list(summaries.keys())

    sorted_ids = sorted(
        all_ids,
        key=lambda cid: summaries.get(cid, {}).get("lastModifiedTime", ""),
        reverse=True,
    )

    print(f"\n{'CASCADE ID':<40} {'STEPS':>5}  {'LAST MODIFIED':<21}  SUMMARY")
    print("-" * 110)
    for cid in sorted_ids:
        info = summaries.get(cid, {})
        summary = info.get("summary", "(no metadata)")[:55]
        steps = info.get("stepCount", "?")
        modified = info.get("lastModifiedTime", "")[:19].replace("T", " ")
        print(f"{cid:<40} {str(steps):>5}  {modified:<21}  {summary}")

    total_api = len(summaries)
    total_all = len(all_ids)
    print(f"\nTotal: {total_all} conversations ({total_api} with API metadata)")


def read_conversation(token: str, port: int, cascade_id: str) -> None:
    """Print one conversation as a transcript."""
    summaries = get_workspace_summaries(token, port)
    info = summaries.get(cascade_id, {})
    step_count = info.get("stepCount")

    print(f"\n# {info.get('summary', cascade_id)}")
    if info:
        print(f"Created : {info.get('createdTime', '')[:19]}")
        print(f"Modified: {info.get('lastModifiedTime', '')[:19]}")
    print("=" * 80)

    steps = fetch_steps(token, port, cascade_id, step_count)
    transcript = steps_to_text(steps)
    print(transcript if transcript else "(no readable content)")


def export_all(
    token: str, port: int, output_dir: str = "exported_conversations"
) -> None:
    """Export every conversation to plain-text files grouped by workspace."""
    os.makedirs(output_dir, exist_ok=True)

    summaries = get_workspace_summaries(token, port)
    all_ids = get_all_cascade_ids()
    if not all_ids:
        all_ids = list(summaries.keys())

    sorted_ids = sorted(
        all_ids,
        key=lambda cid: summaries.get(cid, {}).get("lastModifiedTime", "0000"),
        reverse=True,
    )
    total = len(sorted_ids)
    print(f"Exporting {total} conversations to '{output_dir}/'...\n")

    workspace_counts: dict[str, int] = {}

    for idx, cascade_id in enumerate(sorted_ids, 1):
        info = summaries.get(cascade_id, {})
        title = info.get("summary", "unknown")
        step_count = info.get("stepCount")
        created = info.get("createdTime", "")[:10] or "0000-00-00"
        workspace = _workspace_name(info)
        workspace_counts[workspace] = workspace_counts.get(workspace, 0) + 1

        ws_dir = os.path.join(output_dir, workspace)
        os.makedirs(ws_dir, exist_ok=True)

        safe_title = re.sub(r"[^\w\s-]", "", title).strip()
        safe_title = re.sub(r"\s+", "_", safe_title)[:60]
        filename = f"{created}_{safe_title}_{cascade_id[:8]}.txt"
        filepath = os.path.join(ws_dir, filename)

        print(
            f"[{idx}/{total}] [{workspace}] {title[:45]}",
            end=" ... ", flush=True,
        )

        try:
            steps = fetch_steps(token, port, cascade_id, step_count)
            transcript = steps_to_text(steps)

            header = (
                f"CONVERSATION: {title}\n"
                f"CASCADE ID  : {cascade_id}\n"
                f"WORKSPACE   : {workspace}\n"
                f"CREATED     : {info.get('createdTime', '')[:19]}\n"
                f"MODIFIED    : {info.get('lastModifiedTime', '')[:19]}\n"
                f"STEPS       : {len(steps)}\n"
                f"{'=' * 80}\n\n"
            )

            with open(filepath, "w", encoding="utf-8") as f:
                f.write(header + (transcript or "(no readable content)"))

            user_count = transcript.count("\n[USER]")
            asst_count = transcript.count("\n[ASSISTANT]")
            print(f"OK ({user_count}u {asst_count}a)")
        except Exception as exc:
            print(f"ERROR: {exc}")

    print(f"\nDone. {os.path.abspath(output_dir)}/")
    print("\nWorkspace summary:")
    for ws, count in sorted(workspace_counts.items()):
        print(f"  {ws}/  ({count} conversations)")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    print("Detecting Antigravity server...")
    token, port = get_server_info()
    print(f"Connected: port {port}, token {token[:8]}...\n")

    args = sys.argv[1:]

    if not args or args[0] == "list":
        list_conversations(token, port)
    elif args[0] == "read" and len(args) > 1:
        read_conversation(token, port, args[1])
    elif args[0] == "export":
        out = args[1] if len(args) > 1 else "exported_conversations"
        export_all(token, port, out)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
