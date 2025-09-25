#!/usr/bin/env bash
set -euo pipefail

# === 설정(원하면 수정) ===
REQUIRES_ANSIBLE=">=2.12,<2.18"   # 컬렉션 최소/최대 지원 Ansible 버전
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROLES_DIR="${ROOT_DIR}/roles"
COLL_META_DIR="${ROOT_DIR}/meta"
COLL_RUNTIME="${COLL_META_DIR}/runtime.yml"

echo "[info] project root: ${ROOT_DIR}"

# 0) 루트 README 없으면 생성
if [[ ! -f "${ROOT_DIR}/README.md" ]]; then
  cat > "${ROOT_DIR}/README.md" <<'EOF'
# infra_collection
DNS/NTP/WEB/DB 등 인프라 역할 모음 컬렉션임.
EOF
  echo "[ok] root README.md 생성"
fi

# 1) 컬렉션 meta/runtime.yml 준비
mkdir -p "${COLL_META_DIR}"
if [[ ! -f "${COLL_RUNTIME}" ]]; then
  cat > "${COLL_RUNTIME}" <<EOF
---
requires_ansible: "${REQUIRES_ANSIBLE}"
# action_groups: {}   # 필요 시 정의
# plugin_routing: {}  # 필요 시 정의
EOF
  echo "[ok] meta/runtime.yml 생성 (requires_ansible=${REQUIRES_ANSIBLE})"
else
  if ! grep -qE '^\s*requires_ansible:' "${COLL_RUNTIME}"; then
    # 파일은 있는데 키가 없으면 맨 윗줄에 추가
    tmpf="$(mktemp)"
    {
      echo "---"
      echo "requires_ansible: \"${REQUIRES_ANSIBLE}\""
      # 기존 내용 덮지 않음
      sed '1,1d' "${COLL_RUNTIME}" || true
    } > "${tmpf}"
    mv "${tmpf}" "${COLL_RUNTIME}"
    echo "[ok] meta/runtime.yml에 requires_ansible 키 추가 (${REQUIRES_ANSIBLE})"
  else
    echo "[skip] meta/runtime.yml 이미 존재 및 requires_ansible 발견"
  fi
fi

# 2) roles/* 에 README.md / meta/main.yml 보강
if [[ ! -d "${ROLES_DIR}" ]]; then
  echo "[warn] roles 디렉토리가 없음: ${ROLES_DIR} — 건너뜀"
else
  find "${ROLES_DIR}" -maxdepth 1 -mindepth 1 -type d | while read -r ROLE_PATH; do
    ROLE_NAME="$(basename "$ROLE_PATH")"
    META_DIR="${ROLE_PATH}/meta"
    META_FILE="${META_DIR}/main.yml"
    ROLE_README="${ROLE_PATH}/README.md"

    mkdir -p "${META_DIR}"

    if [[ ! -f "${ROLE_README}" ]]; then
      cat > "${ROLE_README}" <<EOF
# ${ROLE_NAME}
${ROLE_NAME} 역할 설명 문서임.
EOF
      echo "[ok] ${ROLE_NAME}/README.md 생성"
    else
      echo "[skip] ${ROLE_NAME}/README.md 존재"
    fi

    if [[ ! -f "${META_FILE}" ]]; then
      cat > "${META_FILE}" <<EOF
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
      echo "[ok] ${ROLE_NAME}/meta/main.yml 생성"
    else
      echo "[skip] ${ROLE_NAME}/meta/main.yml 존재"
    fi
  done
fi

echo "[done] 컬렉션/역할 구조 보정 완료"
echo "다음 실행:"
echo "  ansible-galaxy collection build"
echo "  # 생성된 tar.gz 확인 후"
echo "  ansible-galaxy collection publish <생성된-파일>.tar.gz"

