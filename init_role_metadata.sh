#!/usr/bin/env bash
set -euo pipefail

# 프로젝트 루트에서 실행: ansible_project/
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROLES_DIR="${ROOT_DIR}/roles"

if [[ ! -d "$ROLES_DIR" ]]; then
  echo "roles 디렉토리를 찾을 수 없음: $ROLES_DIR" >&2
  exit 1
fi

# 컬렉션 루트 README도 없으면 생성
if [[ ! -f "${ROOT_DIR}/README.md" ]]; then
  cat > "${ROOT_DIR}/README.md" <<'EOF'
# infra_collection
DNS/NTP/WEB/DB 등 인프라 역할 모음 컬렉션임.
EOF
  echo "[info] 루트 README.md 생성"
fi

# 역할 디렉토리 순회
find "$ROLES_DIR" -maxdepth 1 -mindepth 1 -type d | while read -r ROLE_PATH; do
  ROLE_NAME="$(basename "$ROLE_PATH")"
  META_DIR="${ROLE_PATH}/meta"
  META_FILE="${META_DIR}/main.yml"
  ROLE_README="${ROLE_PATH}/README.md"

  mkdir -p "$META_DIR"

  if [[ ! -f "$ROLE_README" ]]; then
    cat > "$ROLE_README" <<EOF
# ${ROLE_NAME}
${ROLE_NAME} 역할 설명 문서임.
EOF
    echo "[info] ${ROLE_NAME}/README.md 생성"
  fi

  if [[ ! -f "$META_FILE" ]]; then
    cat > "$META_FILE" <<EOF
---
galaxy_info:
  role_name: ${ROLE_NAME}
  author: Your Name
  description: "${ROLE_NAME} role"
  license: MIT
  min_ansible_version: "2.12"
  platforms:
    - name: EL
      versions: [8, 9]
dependencies: []
EOF
    echo "[info] ${ROLE_NAME}/meta/main.yml 생성"
  fi
done

echo "[done] 역할 README/meta 생성 완료"

