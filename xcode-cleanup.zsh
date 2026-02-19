#!/bin/zsh

# ============================================================
# Xcode/macOS 시스템 데이터 정리 자동화 스크립트
# ============================================================

# 외부 명령 절대경로 지정
DU=/usr/bin/du
RM=/bin/rm
BREW="${commands[brew]:-/opt/homebrew/bin/brew}"
[[ -x "$BREW" ]] || BREW="/usr/local/bin/brew"

# 색상 코드
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# 바이트를 사람이 읽기 쉬운 단위로 변환
human_readable() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        printf "%.2f GB" $(( bytes / 1073741824.0 ))
    elif (( bytes >= 1048576 )); then
        printf "%.2f MB" $(( bytes / 1048576.0 ))
    elif (( bytes >= 1024 )); then
        printf "%.2f KB" $(( bytes / 1024.0 ))
    else
        printf "%d B" $bytes
    fi
}

# 디렉터리 용량을 바이트로 계산
get_size_bytes() {
    local path="$1"
    if [[ -e "$path" ]]; then
        local raw
        raw=$($DU -sk "$path" 2>/dev/null)
        local kb=${raw%%[[:space:]]*}
        echo $(( kb * 1024 ))
    else
        echo 0
    fi
}

# 구분선 출력
print_separator() {
    echo "${CYAN}──────────────────────────────────────────────────${RESET}"
}

# ============================================================
# Phase 1: 자동 정리
# ============================================================

echo ""
echo "${BOLD}${CYAN}🧹 Xcode/macOS 시스템 데이터 정리 시작${RESET}"
print_separator

total_freed=0

cleanup_names=(
    "DerivedData"
    "Homebrew Cache"
    "Xcode Cache"
    "CoreSimulator Logs"
)
cleanup_paths=(
    "$HOME/Library/Developer/Xcode/DerivedData"
    "__brew__"
    "$HOME/Library/Caches/com.apple.dt.Xcode"
    "$HOME/Library/Logs/CoreSimulator"
)

for i in {1..4}; do
    name="${cleanup_names[$i]}"
    path="${cleanup_paths[$i]}"

    echo ""
    echo "${CYAN}📦 [$i/4] ${name}${RESET}"

    if [[ "$path" == "__brew__" ]]; then
        if [[ -x "$BREW" ]]; then
            brew_cache=$($BREW --cache 2>/dev/null)
            before_bytes=$(get_size_bytes "$brew_cache")
            echo "   삭제 전 용량: $(human_readable $before_bytes)"

            $BREW cleanup --prune=all 2>/dev/null

            after_bytes=$(get_size_bytes "$brew_cache")
            freed=$(( before_bytes - after_bytes ))
            if (( freed < 0 )); then freed=0; fi
            total_freed=$(( total_freed + freed ))
            echo "   ${GREEN}✅ 완료 — $(human_readable $freed) 확보${RESET}"
        else
            echo "   ${YELLOW}⚠️  Homebrew가 설치되어 있지 않습니다${RESET}"
        fi
    else
        if [[ -d "$path" ]]; then
            before_bytes=$(get_size_bytes "$path")
            echo "   삭제 전 용량: $(human_readable $before_bytes)"

            setopt localoptions nullglob
            $RM -rf "${path:?}"/* 2>/dev/null

            after_bytes=$(get_size_bytes "$path")
            freed=$(( before_bytes - after_bytes ))
            if (( freed < 0 )); then freed=0; fi
            total_freed=$(( total_freed + freed ))
            echo "   ${GREEN}✅ 완료 — $(human_readable $freed) 확보${RESET}"
        else
            echo "   ${YELLOW}⚠️  디렉터리가 존재하지 않습니다: ${path}${RESET}"
        fi
    fi
done

echo ""
print_separator
echo "${BOLD}${GREEN}📊 Phase 1 완료 — 총 확보 용량: $(human_readable $total_freed)${RESET}"
print_separator

# ============================================================
# Phase 2: iOS DeviceSupport 선택 삭제
# ============================================================

echo ""
echo "${BOLD}${CYAN}📱 iOS DeviceSupport 선택 삭제${RESET}"
print_separator

DS_DIR="$HOME/Library/Developer/Xcode/iOS DeviceSupport"

if [[ ! -d "$DS_DIR" ]]; then
    echo "${YELLOW}⚠️  iOS DeviceSupport 디렉터리가 존재하지 않습니다${RESET}"
    echo ""
    echo "${BOLD}${GREEN}🎉 정리 완료! 총 확보 용량: $(human_readable $total_freed)${RESET}"
    exit 0
fi

# DeviceSupport 항목 수집
entries=()
sizes=()
idx=0

for entry in "$DS_DIR"/*(N); do
    [[ -d "$entry" ]] || continue
    idx=$(( idx + 1 ))
    entries+=("$entry")
    size_bytes=$(get_size_bytes "$entry")
    sizes+=($size_bytes)
done

if (( idx == 0 )); then
    echo "${YELLOW}⚠️  DeviceSupport 항목이 없습니다${RESET}"
    echo ""
    echo "${BOLD}${GREEN}🎉 정리 완료! 총 확보 용량: $(human_readable $total_freed)${RESET}"
    exit 0
fi

# 테이블 출력
echo ""
printf "${BOLD}  %-4s  %-50s  %10s${RESET}\n" "번호" "디렉터리" "용량"
echo "  ────  ──────────────────────────────────────────────────  ──────────"

for i in {1..$idx}; do
    dirname="${entries[$i]:t}"
    size_hr=$(human_readable ${sizes[$i]})
    printf "  %-4s  %-50s  %10s\n" "[$i]" "$dirname" "$size_hr"
done

echo ""
ds_total=0
for s in "${sizes[@]}"; do
    ds_total=$(( ds_total + s ))
done
echo "${CYAN}  전체 용량: $(human_readable $ds_total)${RESET}"
echo ""

# 사용자 입력
echo "삭제할 번호를 입력하세요 (콤마 구분, ${BOLD}all${RESET}=전체, ${BOLD}none${RESET}=건너뛰기):"
printf "> "
read -r user_input

# 입력 처리
user_input=${user_input// /}

if [[ "$user_input" == "none" || -z "$user_input" ]]; then
    echo "${CYAN}ℹ️  DeviceSupport 삭제를 건너뜁니다${RESET}"
elif [[ "$user_input" == "all" ]]; then
    ds_freed=0
    for i in {1..$idx}; do
        echo "   삭제 중: ${entries[$i]:t}"
        $RM -rf "${entries[$i]}"
        ds_freed=$(( ds_freed + sizes[$i] ))
    done
    total_freed=$(( total_freed + ds_freed ))
    echo "${GREEN}✅ 전체 삭제 완료 — $(human_readable $ds_freed) 확보${RESET}"
else
    ds_freed=0
    IFS=',' read -rA nums <<< "$user_input"
    for num in "${nums[@]}"; do
        num=${num// /}
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= idx )); then
            echo "   삭제 중: ${entries[$num]:t}"
            $RM -rf "${entries[$num]}"
            ds_freed=$(( ds_freed + sizes[$num] ))
        else
            echo "   ${RED}❌ 잘못된 번호: $num (무시됨)${RESET}"
        fi
    done
    total_freed=$(( total_freed + ds_freed ))
    echo "${GREEN}✅ 선택 삭제 완료 — $(human_readable $ds_freed) 확보${RESET}"
fi

# 최종 요약
echo ""
print_separator
echo "${BOLD}${GREEN}🎉 정리 완료! 총 확보 용량: $(human_readable $total_freed)${RESET}"
print_separator
echo ""
