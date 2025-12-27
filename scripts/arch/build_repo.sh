#!/bin/bash
set -e

# 参数传入
BRANCH=$1      # reF1nd-main 或 reF1nd-dev
VERSION=$2     # v1.12.14
BINARY_DIR=$3  # 下载下来的 Artifacts 目录

# 定义仓库信息
REPO_URL="https://${GH_TOKEN}@github.com/cagedbird043/cagedbird-pacman-repo.git"
REPO_NAME="cagedbird-repo"

# 1. 确定包名和版本
if [ "$BRANCH" == "reF1nd-main" ]; then
    PKGNAME="sing-box-ref1nd"
    CLEAN_VER="${VERSION#v}" # 去掉 v 前缀
else
    PKGNAME="sing-box-ref1nd-dev"
    CLEAN_VER="${VERSION#v}" 
    # Arch 版本号不允许带横杠，处理 alpha/beta
    # 例如 1.13.0-alpha.34 -> 1.13.0_alpha.34
    CLEAN_VER="${CLEAN_VER//-/_}"
fi

# 2. 准备工作区
mkdir -p arch_build
cd arch_build
git clone $REPO_URL repo_git

# 3. 准备辅助文件 (源码)
# 为了避免 PKGBUILD 下载源码失败，我们直接在这里下载并解压好，改名为 src_aux
# 这样 PKGBUILD 里就可以直接 cd 到 src_aux
wget -O source.tar.gz "https://github.com/SagerNet/sing-box/archive/${VERSION}.tar.gz"
mkdir -p src_aux
tar -xzf source.tar.gz -C src_aux --strip-components=1

# 4. 循环构建架构：x86_64 和 aarch64
ARCHS=("x86_64" "aarch64")

for ARCH in "${ARCHS[@]}"; do
    echo "📦 Packaging for $ARCH..."
    
    # 4.1 选择二进制
    # 策略：x86_64 优先用 v3 (兼容性好且快)，如果有特殊需求改成 v4
    #       aarch64 用 arm64
    if [ "$ARCH" == "x86_64" ]; then
        # 从 Artifacts 目录找: assets-reF1nd-main-linux-amd64v3
        BIN_SRC="$BINARY_DIR/assets-$BRANCH-linux-amd64v3/sing-box"
        [ ! -f "$BIN_SRC" ] && BIN_SRC="$BINARY_DIR/assets-$BRANCH-linux-amd64/sing-box" # 降级
    else
        BIN_SRC="$BINARY_DIR/assets-$BRANCH-linux-arm64/sing-box"
    fi

    if [ ! -f "$BIN_SRC" ]; then
        echo "⚠️ Skipping $ARCH: Binary not found at $BIN_SRC"
        continue
    fi
    
    # 4.2 准备构建目录
    BUILD_DIR="build_$ARCH"
    mkdir -p "$BUILD_DIR"
    cp ../scripts/arch/PKGBUILD.template "$BUILD_DIR/PKGBUILD"
    cp -r src_aux "$BUILD_DIR/"
    cp "$BIN_SRC" "$BUILD_DIR/sing-box-bin"
    chmod +x "$BUILD_DIR/sing-box-bin"

    # 4.3 替换 PKGBUILD 变量
    sed -i "s/_PKGNAME_/$PKGNAME/g" "$BUILD_DIR/PKGBUILD"
    sed -i "s/_PKGVER_/$CLEAN_VER/g" "$BUILD_DIR/PKGBUILD"
    
    # 4.4 调用 makepkg (使用 nobody 用户或 fakeroot)
    # 注意：在 Docker 容器里通常需要切用户
    cd "$BUILD_DIR"
    chown -R nobody .
    # -R: Repackage, -d: Skip deps check (we have binary), -f: Force
    sudo -u nobody CARCH=$ARCH makepkg -f --nodeps

    # 4.5 归档到仓库目录
    cd .. # 回到 arch_build
    mkdir -p "repo_git/$ARCH"
    cp "$BUILD_DIR"/*.pkg.tar.zst "repo_git/$ARCH/"
    
    # 4.6 更新数据库
    cd "repo_git/$ARCH"
    repo-add "$REPO_NAME.db.tar.zst" *.pkg.tar.zst
    
    # 回到根目录准备下一次循环
    cd ../..
done

# 5. 推送
cd repo_git
git config user.name "CI Bot"
git config user.email "ci@localhost"
git add .
git commit -m "Update $PKGNAME to $CLEAN_VER"
git push