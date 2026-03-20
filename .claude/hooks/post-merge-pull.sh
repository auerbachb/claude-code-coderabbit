#!/bin/bash
# Post-merge hook: pulls main in the root repo after a successful gh pr merge
# This keeps hardlinked rule files in ~/.claude/rules/ up to date
#
# Setup: Add this to ~/.claude/settings.json under "hooks":
#   {
#     "hooks": {
#       "PostToolUse": [{
#         "matcher": "Bash",
#         "hooks": [{
#           "type": "command",
#           "command": "<repo-root>/.claude/hooks/post-merge-pull.sh",
#           "timeout": 15
#         }]
#       }]
#     }
#   }

input=$(cat)

command=$(echo "$input" | jq -r '.tool_input.command')
exit_code=$(echo "$input" | jq -r '.tool_response.exitCode // .tool_response.stdout' 2>/dev/null)

# Only act on successful gh pr merge commands
if [[ "$command" == *"gh pr merge"* ]] && [[ "$exit_code" == "0" || "$command" == *"--squash"* ]]; then
  # Find the root repo (first entry from git worktree list)
  root_repo=$(cd "$(echo "$input" | jq -r '.cwd')" && git worktree list 2>/dev/null | head -1 | awk '{print $1}')

  if [[ -n "$root_repo" && -d "$root_repo/.git" ]]; then
    # Pull main in the root repo (not the worktree)
    git -C "$root_repo" pull origin main --ff-only 2>/dev/null
  fi
fi

exit 0
