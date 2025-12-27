#!/bin/bash
set -e

# 参数定义
BRANCH=$1      # reF1nd-main 或 reF1nd-dev
VERSION=$2     # v1.12.14
BINARY_DIR=$3  # Artifacts 存放路径 (例如 $(pwd)/artifacts)
REPO_TOKEN=$4  # 你的 Fine-grained PAT

REPO_NAME="cagedbird-repo"
REPO_URL="https://x-access-token:${REPO_TOKEN}@github.com/cagedbird043/cagedbird-pacman-repo.git"

# 处理版本号
RAW_VER="${VERSION#v}"
if [ "$BRANCH" == "reF1nd-main" ]; then
    PKGNAME="sing-box-ref1nd"
    CLEAN_VER="$RAW_VER"
else
    PKGNAME="sing-box-ref1nd-dev"
    CLEAN_VER="${RAW_VER//-/_}"
fi

# 2. 准备工作区并克隆仓库仓
mkdir -p arch_work
cd arch_work
git clone "$REPO_URL" repo_dest

for ARCH in "x86_64" "aarch64"; do
    echo "📦 Packaging for $ARCH..."
    
    # 寻找二进制压缩包
    if [ "$ARCH" == "x86_64" ]; then
        ART_DIR="$BINARY_DIR/bin-$BRANCH-linux-amd64v3"
        [ ! -d "$ART_DIR" ] && ART_DIR="$BINARY_DIR/bin-$BRANCH-linux-amd64"
    else
        ART_DIR="$BINARY_DIR/bin-$BRANCH-linux-arm64"
    fi

    TAR_PATH=$(find "$ART_DIR" -name "*.tar.gz" | head -n 1)
    [ ! -f "$TAR_PATH" ] && { echo "⚠️ Skip $ARCH"; continue; }

    # 准备构建目录
    BUILD_DIR="build_$ARCH"; mkdir -p "$BUILD_DIR"
    cp ../scripts/arch/PKGBUILD "$BUILD_DIR/PKGBUILD"
    
    # 核心：解压二进制到构建目录，改名为 sing-box-bin
    tar -xzf "$TAR_PATH" -O sing-box > "$BUILD_DIR/sing-box-bin"
    
    # 注入变量到 PKGBUILD
    sed -i "s/_PKGNAME_/$PKGNAME/g" "$BUILD_DIR/PKGBUILD"
    sed -i "s/_PKGVER_/$CLEAN_VER/g" "$BUILD_DIR/PKGBUILD"
    sed -i "s/_RAWVER_/$RAW_VER/g" "$BUILD_DIR/PKGBUILD"
    sed -i "s/_ARCH_OPTS_/$ARCH/g" "$BUILD_DIR/PKGBUILD"

    # 打包
    chmod -R 777 "$BUILD_DIR"
    cd "$BUILD_DIR"
    sudo -u nobody CARCH=$ARCH makepkg -f --nodeps
    
    # 入库
    cd ..
    mkdir -p "repo_dest/$ARCH"
    cp "$BUILD_DIR"/*.pkg.tar.zst "repo_dest/$ARCH/"
    cd "repo_dest/$ARCH"
    repo-add "$REPO_NAME.db.tar.zst" *.pkg.tar.zst
    cd ../..
done

# 5. 提交回库（增加重试逻辑）
cd repo_dest
git config user.name "CI-Bot"
git config user.email "ci@cagedbird.top"
git add .

# 检查是否有改动
if git diff --quiet && git diff --staged --quiet; then
    echo "No changes to commit"
else
    git commit -m "Update $PKGNAME to $VERSION"
    
    # 🎖️ 核心：使用循环进行重试，解决并发冲突
    MAX_RETRIES=5
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        # 尝试推送。如果失败，说明有竞争，先 pull --rebase 再试
        if git push origin main; then
            echo "✅ 成功入库！"
            break
        else
            echo "⚠️ 检测到并发冲突，正在尝试 Rebase 重试 ($((RETRY_COUNT+1))/$MAX_RETRIES)..."
            git pull --rebase origin main
            RETRY_COUNT=$((RETRY_COUNT+1))
        fi
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "❌ 经过 $MAX_RETRIES 次重试依然失败，请检查仓库权限或是否存在死锁。"
        exit 1
    fi
fi