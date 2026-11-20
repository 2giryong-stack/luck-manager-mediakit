#!/usr/bin/env bash
# 복대리 탐방 미디어킷 → GitHub Pages 배포/검증
# 사용: bash deploy.sh   (저장소가 이미 존재해야 함)
set -uo pipefail
OWNER="2giryong-stack"
REPO="luck-manager-mediakit"
SITE="https://${OWNER}.github.io/${REPO}/"
cd "$(dirname "$0")" || exit 1

echo "== 1. push =="
git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/${OWNER}/${REPO}.git"
git push -u origin main || { echo "PUSH_FAILED"; exit 1; }

echo "== 2. Pages 활성화 =="
gh api -X POST "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/" 2>&1 | head -3
if ! gh api "repos/${OWNER}/${REPO}/pages" --jq '.html_url' 2>/dev/null; then
  echo "PAGES_POST_FAILED (PUT 시도)"
  gh api -X PUT "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/" 2>&1 | head -3
fi

echo "== 3. 빌드 대기 =="
for i in $(seq 1 30); do
  st=$(gh api "repos/${OWNER}/${REPO}/pages/builds/latest" --jq '.status' 2>/dev/null || echo none)
  echo "  build: ${st}"
  [ "$st" = "built" ] && break
  sleep 10
done

echo "== 4. 접속 확인 =="
for i in $(seq 1 18); do
  code=$(curl -s -o /tmp/lm-site.html -w '%{http_code}' -L "${SITE}")
  echo "  http ${code}"
  [ "$code" = "200" ] && break
  sleep 10
done
echo "== 5. 내용 확인 =="
grep -o "복대리 탐방" /tmp/lm-site.html | head -1
grep -o "9,800" /tmp/lm-site.html | head -1
grep -o "bbbxks@naver.com" /tmp/lm-site.html | head -1
wc -c /tmp/lm-site.html
