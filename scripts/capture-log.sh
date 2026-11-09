#!/usr/bin/env bash
# 저장소 루트와 무관하게 실행할 수 있다. 명령의 stdout/stderr와 종료 코드를 기록한다.
set -u
if [ "$#" -lt 2 ]; then
    printf '사용법: bash scripts/capture-log.sh 이름 명령 [인자...]\n' >&2
    exit 2
fi
log_name=$1
shift
case "$log_name" in
    ''|*[!a-zA-Z0-9_-]*) printf '이름은 영문·숫자·밑줄·하이픈만 사용하세요.\n' >&2; exit 2 ;;
esac
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd) || exit 1
log_dir="$repo_dir/docs/logs"
mkdir -p "$log_dir" || exit 1
stamp=$(date -u +%Y%m%dT%H%M%SZ)
log_file=$(mktemp "$log_dir/${log_name}_${stamp}.log.XXXXXX") || exit 1
{
    printf 'started_at_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'working_directory: %s\n' "$PWD"
    printf 'command:'
    printf ' %q' "$@"
    printf '\n--- output (stdout + stderr) ---\n'
} > "$log_file" || exit 1
# set -e를 쓰지 않아 실패한 명령의 종료 코드까지 남긴다.
"$@" >> "$log_file" 2>&1
command_status=$?
{
    printf '\n--- end ---\n'
    printf 'finished_at_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'exit_code: %s\n' "$command_status"
} >> "$log_file" || exit 1
cat "$log_file"
printf '\n로그: %s\n' "$log_file"
exit "$command_status"
