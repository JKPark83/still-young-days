#!/bin/bash
# PostToolUse hook (Edit|Write): .dart 파일이 바뀌면
#  1) dart format으로 자동 포맷
#  2) dart analyze를 돌려 문제가 있으면 exit 2로 Claude에게 알린다.
# 패키지 해석이 준비 안 된 상태(.dart_tool 없음)면 analyze는 건너뛴다(가짜 오류 방지).
export PATH="/opt/homebrew/bin:$HOME/development/flutter/bin:$PATH"

file_path=$(jq -r '.tool_input.file_path // empty')
[[ "$file_path" == *.dart && -f "$file_path" ]] || exit 0

dart format "$file_path" >/dev/null 2>&1

[[ -f "${CLAUDE_PROJECT_DIR:-.}/.dart_tool/package_config.json" ]] || exit 0

analyze_output=$(dart analyze "$file_path" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "dart analyze found issues in $file_path:" >&2
  echo "$analyze_output" >&2
  exit 2
fi
exit 0
