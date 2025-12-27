#!/bin/bash
set -e

# 参数定义
BRANCH=$1      # reF1nd-main 或 reF1nd-dev
VERSION=$2     # v1.12.14
BINARY_DIR=$3  # Artifacts 存放路径 (例如 $(pwd)/artifacts)
REPO_TOKEN=$4  # 你的 Fine-grained PAT

REPO_NAME="cagedbird-repo"
REPO_URL="https://x-access-token:${REPO_TOKEN}@github.com/cagedbird043/cagedbird-pacman-repo.git"

# 1. 确定包名和版本 (Arch 不允许版本号带横杠)
if [ "$BRANCH" == "reF1nd-main" ]; then
    PKGNAME="sing-box-ref1nd"
    CLEAN_VER="${VERSION#v}"
else
    PKGNAME="sing-box-ref1nd-dev"
    CLEAN_VER="${VERSION#v}"
    CLEAN_VER="${CLEAN_VER//-/_}" # 1.13.0-alpha.34 -> 1.13.0_alpha.34
fi

# 2. 准备工作区并克隆仓库仓
mkdir -p arch_work
cd arch_work
git clone "$REPO_URL" repo_dest

# 3. 准备源码辅助文件 (从上游抓取 release 源码包)
wget -O source.tar.gz "https://github.com/SagerNet/sing-box/archive/${VERSION}.tar.gz"
mkdir -p src_aux
tar -xzf source.tar.gz -C src_aux --strip-components=1

# 4. 架构循环构建：x86_64 和 aarch64
ARCHS=("x86_64" "aarch64")
for ARCH in "${ARCHS[@]}"; do
    echo "📦 Packaging for $ARCH..."
    
    # 4.1 寻找对应的 Artifact 目录
    if [ "$ARCH" == "x86_64" ]; then
        # 统帅，我们优先拿 v3 版本，找不到再拿普通的
        ART_DIR="$BINARY_DIR/bin-$BRANCH-linux-amd64v3"
        [ ! -d "$ART_DIR" ] && ART_DIR="$BINARY_DIR/bin-$BRANCH-linux-amd64"
    else
        ART_DIR="$BINARY_DIR/bin-$BRANCH-linux-arm64"
    fi

    # 4.2 核心修复：从压缩包里提取二进制
    # 在这个目录下搜索 .tar.gz 文件
    TAR_PATH=$(find "$ART_DIR" -name "*.tar.gz" | head -n 1)
    
    if [ ! -f "$TAR_PATH" ]; then
        echo "⚠️ 跳过 $ARCH: 在 $ART_DIR 找不到压缩包"
        continue
    fi

    echo "📂 正在解压: $(basename "$TAR_PATH")"
    # 解压到当前构建目录，这会产生一个名为 sing-box 的二进制
    tar -xzf "$TAR_PATH" -C .
    BIN_SRC="./sing-box"

    # 4.3 准备 makepkg 目录
    BUILD_DIR="build_$ARCH"
    mkdir -p "$BUILD_DIR"
    cp ../scripts/arch/PKGBUILD "$BUILD_DIR/PKGBUILD"
    cp -r src_aux "$BUILD_DIR/"
    # 把刚才解压出来的二进制搬进去
    mv "$BIN_SRC" "$BUILD_DIR/sing-box-bin"
    
    # 注入变量
    sed -i "s/_PKGNAME_/$PKGNAME/g" "$BUILD_DIR/PKGBUILD"
    sed -i "s/_PKGVER_/$CLEAN_VER/g" "$BUILD_DIR/PKGBUILD"
    sed -i "s/_ARCH_OPTS_/$ARCH/g" "$BUILD_DIR/PKGBUILD"

    # 执行打包
    chmod -R 777 "$BUILD_DIR"
    cd "$BUILD_DIR"
    # --nodeps 是因为我们已经是二进制了，不需要 Go 依赖
    sudo -u nobody CARCH=$ARCH makepkg -f --nodeps
    
    # 更新仓库
    cd ..
    mkdir -p "repo_dest/$ARCH"
    cp "$BUILD_DIR"/*.pkg.tar.zst "repo_dest/$ARCH/"
    
    # 更新 Pacman 数据库
    cd "repo_dest/$ARCH"
    repo-add "$REPO_NAME.db.tar.zst" *.pkg.tar.zst
    cd ../..
done

# 5. 提交回仓库仓
cd repo_dest
git config user.name "CI-Bot"
git config user.email "ci@cagedbird.top"
git add .
# 只有有变化时才 commit，防止 CI 报错
git diff --quiet && git diff --staged --quiet || (git commit -m "Update $PKGNAME to $VERSION" && git push)