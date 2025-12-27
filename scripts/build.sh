#!/bin/bash
set -e

GOOS=$1
GOARCH=$2
GOAMD64_LEVEL=$3
VERSION_TAG=$4

# 设置 Tags (包含 ref1nd 特色 tags)
BUILD_TAGS="with_gvisor,with_quic,with_dhcp,with_wireguard,with_utls,with_acme,with_clash_api,with_tailscale,with_ech"

export GOOS=$GOOS
export GOARCH=$GOARCH
export CGO_ENABLED=0

if [ "$GOARCH" == "amd64" ] && [ -n "$GOAMD64_LEVEL" ]; then
    export GOAMD64=$GOAMD64_LEVEL
fi

# 注入版本信息并编译
LDFLAGS="-s -w -X 'github.com/sagernet/sing-box/constant.Version=${VERSION_TAG}' -buildid="

OUTPUT_NAME="sing-box"
[ "$GOOS" == "windows" ] && OUTPUT_NAME="sing-box.exe"

echo "开始构建: $GOOS $GOARCH $GOAMD64_LEVEL"
go build -v -x -trimpath -tags "$BUILD_TAGS" -ldflags "$LDFLAGS" -o "$OUTPUT_NAME" ./cmd/sing-box 2>&1