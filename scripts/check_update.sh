#!/bin/bash
set -e

UPSTREAM_REPO="SagerNet/sing-box"
FORK_REPO="reF1nd/sing-box"
FORK_BRANCH="reF1nd-main"

# 1. 抓取 Go 版本 (用于调度)
echo "go_version=1.23.4" >> "$GITHUB_OUTPUT"

# 2. 抓取上游真正的稳定版 Tag (排除 alpha/beta/rc)
# 通过 ls-remote 直接获取，不需要 clone 整个库
LATEST_STABLE_TAG=$(git ls-remote --tags "https://github.com/${UPSTREAM_REPO}.git" | \
    grep -Po 'refs/tags/\Kv[0-9]+\.[0-9]+\.[0-9]+$' | \
    sort -V | tail -n1)

if [ -z "$LATEST_STABLE_TAG" ]; then
    echo "Error: 无法获取上游 Tag"
    exit 1
fi

# 3. 获取 reF1nd 分支的最新 Commit 时间
LATEST_TIME=$(curl -sL "https://api.github.com/repos/${FORK_REPO}/commits?sha=${FORK_BRANCH}" | \
    jq -r '.[0].commit.committer.date' | xargs -I {} date -d '{}' '+%Y-%m-%d')

# 使用 tr 强行剔除可能存在的换行或回车符
CLEAN_TAG=$(echo "$LATEST_STABLE_TAG" | tr -d '\r\n ')
echo "latest_tag=${CLEAN_TAG}" >> "$GITHUB_OUTPUT"
echo "latest_time=${LATEST_TIME}" >> "$GITHUB_OUTPUT"

# 4. 判断逻辑
if [ -z "$GITHUB_REPOSITORY" ] || [ "$GITHUB_REPOSITORY" == "NONE" ]; then
    echo "needs_update=true" >> "$GITHUB_OUTPUT"
else
    # 检查自己仓库最新的 Release
    CURRENT_RELEASE=$(curl -sL "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/latest" | jq -r '.tag_name // "none"')
    if [ "$LATEST_STABLE_TAG" != "$CURRENT_RELEASE" ]; then
        echo "needs_update=true" >> "$GITHUB_OUTPUT"
    else
        echo "needs_update=false" >> "$GITHUB_OUTPUT"
    fi
fi