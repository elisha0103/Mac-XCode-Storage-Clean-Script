# xcode-cleanup.zsh

Xcode 개발 환경에서 쌓이는 캐시, 로그, DeviceSupport 파일을 한 번에 정리하는 자동화 스크립트입니다.

## 정리 대상

| 대상 | 경로 | 설명 |
|------|------|------|
| DerivedData | `~/Library/Developer/Xcode/DerivedData/` | 빌드 캐시 (재빌드 시 자동 생성) |
| Homebrew Cache | `brew cleanup` | 오래된 패키지 캐시 |
| Xcode Cache | `~/Library/Caches/com.apple.dt.Xcode/` | Xcode 내부 캐시 |
| CoreSimulator Logs | `~/Library/Logs/CoreSimulator/` | 시뮬레이터 로그 |
| iOS DeviceSupport | `~/Library/Developer/Xcode/iOS DeviceSupport/` | 실기기 디버깅 심볼 (선택 삭제) |

## 사용 방법

### 1. 스크립트 다운로드

```bash
# 저장소 클론 후 스크립트를 홈 디렉터리에 복사
cp xcode-cleanup.zsh ~/scripts/xcode-cleanup.zsh
```

또는 직접 `~/scripts/` 폴더에 저장합니다.

### 2. 실행 권한 부여

```bash
chmod +x ~/scripts/xcode-cleanup.zsh
```

### 3. 실행

```bash
~/scripts/xcode-cleanup.zsh
```

## 실행 흐름

```
Phase 1: 자동 정리 (확인 없이 즉시 실행)
  ├── [1/4] DerivedData 삭제
  ├── [2/4] Homebrew 캐시 정리
  ├── [3/4] Xcode 캐시 삭제
  └── [4/4] CoreSimulator 로그 삭제
       → 각 항목별 확보 용량 출력

Phase 2: iOS DeviceSupport 선택 삭제
  ├── 설치된 DeviceSupport 목록을 테이블로 출력
  ├── 삭제할 번호 입력
  │     • 번호 입력: 1,3,5 (콤마 구분)
  │     • all: 전체 삭제
  │     • none: 건너뛰기
  └── 선택 항목 삭제 후 확보 용량 출력

→ 최종 총 확보 용량 요약
```

## 실행 예시

```
🧹 Xcode/macOS 시스템 데이터 정리 시작
──────────────────────────────────────────────────

📦 [1/4] DerivedData
   삭제 전 용량: 3.42 GB
   ✅ 완료 — 3.42 GB 확보

📦 [2/4] Homebrew Cache
   삭제 전 용량: 512.00 MB
   ✅ 완료 — 512.00 MB 확보

📦 [3/4] Xcode Cache
   삭제 전 용량: 128.50 MB
   ✅ 완료 — 128.50 MB 확보

📦 [4/4] CoreSimulator Logs
   삭제 전 용량: 45.00 MB
   ✅ 완료 — 45.00 MB 확보

──────────────────────────────────────────────────
📊 Phase 1 완료 — 총 확보 용량: 4.09 GB
──────────────────────────────────────────────────

📱 iOS DeviceSupport 선택 삭제
──────────────────────────────────────────────────

  번호  디렉터리                                            용량
  ────  ──────────────────────────────────────────────────  ──────────
  [1]   16.4 (20E247) arm64e                                  2.80 GB
  [2]   17.0 (21A329) arm64e                                  3.10 GB
  [3]   17.5 (21F79) arm64e                                   3.20 GB

  전체 용량: 9.10 GB

삭제할 번호를 입력하세요 (콤마 구분, all=전체, none=건너뛰기):
> 1,2
   삭제 중: 16.4 (20E247) arm64e
   삭제 중: 17.0 (21A329) arm64e
✅ 선택 삭제 완료 — 5.90 GB 확보

──────────────────────────────────────────────────
🎉 정리 완료! 총 확보 용량: 9.99 GB
──────────────────────────────────────────────────
```

## 요구 사항

- macOS
- Zsh (macOS 기본 셸)
- Homebrew (미설치 시 해당 단계 건너뜀)

## 참고

- DerivedData 삭제 후 프로젝트를 처음 빌드하면 시간이 더 걸릴 수 있습니다 (자동 재생성).
- DeviceSupport는 현재 연결된 기기의 항목을 삭제하면 다음 연결 시 재다운로드됩니다. 더 이상 사용하지 않는 iOS 버전만 삭제하는 것을 권장합니다.
