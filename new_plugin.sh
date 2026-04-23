#!/bin/bash

# ============================================================
# Rain 源 - 新插件一键配置脚本
# 用法: ./new_plugin.sh <deb文件名或包名>
# 例如: ./new_plugin.sh com.rain.rainmhz
#       ./new_plugin.sh com.rain.rainmhz_2.0-1-6_iphoneos-arm64.deb
# ============================================================

cd "$(dirname "$0")"

BASE_URL="https://rain1-d1l.pages.dev"

# --- 颜色预设（循环使用）---
COLORS=("#FF6B6B" "#4ECDC4" "#A78BFA" "#F59E0B" "#F97316" "#10B981" "#EF4444" "#8B5CF6" "#EC4899" "#3B82F6" "#14B8A6" "#6CC5D1" "#F472B6" "#34D399" "#FBBF24" "#818CF8")

# --- 从参数提取包名 ---
if [ -z "$1" ]; then
    echo "❌ 用法: ./new_plugin.sh <deb文件名或包名>"
    echo "   例如: ./new_plugin.sh com.rain.rainmhz"
    exit 1
fi

# 支持传入 .deb 文件名或纯包名
INPUT="$1"
if [[ "$INPUT" == *.deb ]]; then
    PKGID=$(echo "$INPUT" | sed 's/_.*//') 
else
    PKGID="$INPUT"
fi

echo ""
echo "🔧 Rain 源 - 新插件配置"
echo "========================"
echo "📦 包名: $PKGID"
echo ""

# --- 检查 deb 是否存在 ---
DEB_FILE=$(ls debs/${PKGID}*.deb 2>/dev/null | head -1)
if [ -z "$DEB_FILE" ]; then
    echo "⚠️  在 debs/ 里没找到 ${PKGID} 的 deb 文件"
    echo "   请先把 .deb 文件放到 debs/ 目录"
    read -p "   已放好了按回车继续，或 Ctrl+C 取消: "
    DEB_FILE=$(ls debs/${PKGID}*.deb 2>/dev/null | head -1)
    if [ -z "$DEB_FILE" ]; then
        echo "❌ 仍然找不到 deb 文件，退出"
        exit 1
    fi
fi

# --- 从 deb 提取版本号 ---
DEB_BASENAME=$(basename "$DEB_FILE")
VERSION=$(echo "$DEB_BASENAME" | sed "s/${PKGID}_//" | sed 's/_iphoneos.*//' | sed 's/\.deb$//')
if [ -z "$VERSION" ] || [ "$VERSION" = "$DEB_BASENAME" ]; then
    VERSION="1.0"
fi
DEB_SIZE=$(du -k "$DEB_FILE" | cut -f1)

echo "📄 Deb: $DEB_BASENAME"
echo "📌 版本: $VERSION"
echo "💾 大小: ${DEB_SIZE} KB"
echo ""

# --- 检查是否已有 depiction ---
if [ -f "sileodepictions/${PKGID}.json" ]; then
    echo "⚠️  sileodepictions/${PKGID}.json 已存在"
    read -p "   是否覆盖？(y/N): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "⏭  跳过 depiction 创建"
        SKIP_DEPICTION=1
    fi
fi

if [ -z "$SKIP_DEPICTION" ]; then
    # --- 收集插件信息 ---
    echo "📝 请输入插件信息（直接回车使用默认值）"
    echo ""
    
    read -p "   插件显示名称 (如 Rain的xxx): " DISPLAY_NAME
    if [ -z "$DISPLAY_NAME" ]; then
        DISPLAY_NAME="$PKGID"
    fi
    
    read -p "   简介 (一句话描述): " DESCRIPTION
    if [ -z "$DESCRIPTION" ]; then
        DESCRIPTION="${DISPLAY_NAME} - Rain出品的iOS插件"
    fi
    
    echo ""
    echo "   功能特点（每行一个，输入空行结束）:"
    FEATURES=""
    FEAT_COUNT=0
    EMOJIS=("🚀" "✨" "🔧" "📱" "🛡" "🎨" "⚡️" "🔒" "📊" "💬")
    while true; do
        read -p "   - " FEAT
        if [ -z "$FEAT" ]; then
            break
        fi
        EMOJI=${EMOJIS[$FEAT_COUNT]}
        if [ -z "$EMOJI" ]; then EMOJI="•"; fi
        if [ -n "$FEATURES" ]; then
            FEATURES="${FEATURES}\\n- ${EMOJI} ${FEAT}"
        else
            FEATURES="- ${EMOJI} ${FEAT}"
        fi
        FEAT_COUNT=$((FEAT_COUNT + 1))
    done
    if [ -z "$FEATURES" ]; then
        FEATURES="- 🚀 功能强大\\n- ⚙️ 简单易用\\n- 🔒 安全可靠"
    fi
    
    read -p "   系统兼容 (默认 iOS 15+): " IOS_COMPAT
    if [ -z "$IOS_COMPAT" ]; then
        IOS_COMPAT="iOS 15+"
    fi
    
    # 随机选颜色
    EXISTING_COUNT=$(ls sileodepictions/com.rain.*.json 2>/dev/null | wc -l | tr -d ' ')
    COLOR_INDEX=$((EXISTING_COUNT % ${#COLORS[@]}))
    DEFAULT_COLOR="${COLORS[$COLOR_INDEX]}"
    
    echo ""
    echo "   可选颜色: ${COLORS[*]}"
    read -p "   主题色 (默认 ${DEFAULT_COLOR}): " TINT_COLOR
    if [ -z "$TINT_COLOR" ]; then
        TINT_COLOR="$DEFAULT_COLOR"
    fi
    
    TODAY=$(date +%Y-%m-%d)
    
    # --- 生成 depiction JSON ---
    echo ""
    echo "📄 正在生成 Sileo Depiction..."
    
    cat > "sileodepictions/${PKGID}.json" << JSONEOF
{
  "minVersion": "0.1",
  "headerImage": "${BASE_URL}/assets/banners/${PKGID}.png",
  "tintColor": "${TINT_COLOR}",
  "class": "DepictionTabView",
  "tabs": [
    {
      "class": "DepictionStackView",
      "tabname": "详情",
      "views": [
        {
          "class": "DepictionHeaderView",
          "title": "${DISPLAY_NAME}",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionMarkdownView",
          "markdown": "## 简介\n\n${DESCRIPTION}",
          "useSpacing": true,
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionScreenshotsView",
          "itemCornerRadius": 12,
          "itemSize": "{160, 346}",
          "screenshots": [
            {
              "accessibilityText": "截图1",
              "url": "${BASE_URL}/assets/screenshots/${PKGID}/1.png?v=$(date +%Y%m%d)"
            },
            {
              "accessibilityText": "截图2",
              "url": "${BASE_URL}/assets/screenshots/${PKGID}/2.png?v=$(date +%Y%m%d)"
            },
            {
              "accessibilityText": "截图3",
              "url": "${BASE_URL}/assets/screenshots/${PKGID}/3.png?v=$(date +%Y%m%d)"
            },
            {
              "accessibilityText": "截图4",
              "url": "${BASE_URL}/assets/screenshots/${PKGID}/4.png?v=$(date +%Y%m%d)"
            },
            {
              "accessibilityText": "截图5",
              "url": "${BASE_URL}/assets/screenshots/${PKGID}/5.png?v=$(date +%Y%m%d)"
            }
          ]
        },
        {
          "class": "DepictionImageView",
          "URL": "${BASE_URL}/assets/common/gradient_line.png",
          "height": 2,
          "horizontalPadding": 0
        },
        {
          "class": "DepictionSpacerView",
          "spacing": 8
        },
        {
          "class": "DepictionHeaderView",
          "title": "功能特点",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionMarkdownView",
          "markdown": "$(echo "$FEATURES" | sed ':a;N;$!ba;s/\n/\\n/g')",
          "useSpacing": true,
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionImageView",
          "URL": "${BASE_URL}/assets/common/gradient_line.png",
          "height": 2,
          "horizontalPadding": 0
        },
        {
          "class": "DepictionSpacerView",
          "spacing": 8
        },
        {
          "class": "DepictionHeaderView",
          "title": "插件数据",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionTableTextView",
          "title": "版本",
          "text": "${VERSION}",
          "titleColor": "${TINT_COLOR}",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionTableTextView",
          "title": "更新时间",
          "text": "${TODAY}",
          "titleColor": "${TINT_COLOR}",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionTableTextView",
          "title": "大小",
          "text": "${DEB_SIZE} KB",
          "titleColor": "${TINT_COLOR}",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionTableTextView",
          "title": "系统兼容",
          "text": "${IOS_COMPAT}",
          "titleColor": "${TINT_COLOR}",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionImageView",
          "URL": "${BASE_URL}/assets/common/gradient_line.png",
          "height": 2,
          "horizontalPadding": 0
        },
        {
          "class": "DepictionSpacerView",
          "spacing": 8
        },
        {
          "class": "DepictionHeaderView",
          "title": "联系作者",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionTableButtonView",
          "title": "获取作者联系",
          "action": "https://m.tb.cn/h.itXQMBD?tk=jqBN5RBeSQh",
          "openExternal": true,
          "tintColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionImageView",
          "URL": "${BASE_URL}/assets/common/gradient_line.png",
          "height": 2,
          "horizontalPadding": 0
        },
        {
          "class": "DepictionSpacerView",
          "spacing": 8
        },
        {
          "class": "DepictionHeaderView",
          "title": "免责声明",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionMarkdownView",
          "markdown": "本插件仅供个人学习研究使用，请勿用于任何商业或非法用途。使用本插件所造成的一切后果由用户自行承担，作者不承担任何法律责任。",
          "useSpacing": true,
          "textColor": "#999999"
        },
        {
          "class": "DepictionSpacerView",
          "spacing": 16
        },
        {
          "class": "DepictionMarkdownView",
          "markdown": "© 2026 Rain Studio",
          "useSpacing": false,
          "textColor": "#BBBBBB",
          "alignment": 1
        }
      ]
    },
    {
      "class": "DepictionStackView",
      "tabname": "更新日志",
      "views": [
        {
          "class": "DepictionHeaderView",
          "title": "${VERSION}",
          "textColor": "${TINT_COLOR}"
        },
        {
          "class": "DepictionMarkdownView",
          "markdown": "- 🎉 版本发布",
          "useSpacing": true,
          "textColor": "${TINT_COLOR}"
        }
      ]
    }
  ]
}
JSONEOF
    
    echo "   ✅ sileodepictions/${PKGID}.json 已生成"
fi

# --- 创建截图文件夹 ---
if [ ! -d "assets/screenshots/${PKGID}" ]; then
    mkdir -p "assets/screenshots/${PKGID}"
    echo "📂 已创建截图文件夹: assets/screenshots/${PKGID}/"
else
    SHOT_COUNT=$(find "assets/screenshots/${PKGID}" -maxdepth 1 -name "*.png" | wc -l | tr -d ' ')
    echo "📂 截图文件夹已存在 (${SHOT_COUNT}/5 张截图)"
fi

# --- 创建 banner 文件夹 ---
mkdir -p "assets/banners"

# --- 重新生成 Packages 索引 ---
echo ""
echo "📦 正在重新生成 Packages 索引..."
rm -f Packages Packages.bz2
dpkg-scanpackages -m ./debs > Packages 2>/dev/null

# --- 自动添加 SileoDepiction ---
echo "🔗 正在添加 Sileo 详情页链接..."
for json in sileodepictions/com.rain.*.json; do
    pkgid=$(basename "$json" .json)
    if grep -q "^Package: $pkgid$" Packages; then
        if ! grep -A100 "^Package: $pkgid$" Packages | head -20 | grep -q "SileoDepiction"; then
            sed -i '' "/^Package: $pkgid$/,/^$/{
                /^Name:/{
                    a\\
SileoDepiction: ${BASE_URL}/sileodepictions/${pkgid}.json
                }
            }" Packages
        fi
    fi
done

# --- 压缩 ---
echo "🗜  正在压缩索引..."
bzip2 -k Packages

# --- 处理截图 ---
SHOT_DIR="assets/screenshots/${PKGID}"
SHOT_COUNT=$(find "$SHOT_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.heic" -o -iname "*.webp" \) 2>/dev/null | wc -l | tr -d ' ')
if [ "$SHOT_COUNT" -gt 0 ]; then
    echo "🖼  正在处理截图..."
    ./auto_screenshots.sh "$PKGID"
fi

# --- 推送到 GitHub ---
echo ""
read -p "🚀 是否推送到 GitHub？(Y/n): " DO_PUSH
if [ "$DO_PUSH" != "n" ] && [ "$DO_PUSH" != "N" ]; then
    git add .
    git commit -m "新增/更新插件: ${PKGID}"
    git push
    echo ""
    echo "✅ 全部完成！已推送到 GitHub"
else
    echo ""
    echo "✅ 本地配置完成（未推送）"
    echo "   稍后运行 ./update.sh 推送"
fi

echo ""
echo "📋 后续步骤："
SHOT_COUNT2=$(find "$SHOT_DIR" -maxdepth 1 -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SHOT_COUNT2" -lt 5 ]; then
    echo "   1. 放 5 张截图到 assets/screenshots/${PKGID}/"
    echo "   2. 运行 ./auto_screenshots.sh ${PKGID}"
    echo "   3. 运行 ./update.sh 推送"
fi
echo "   • Banner 图(可选): assets/banners/${PKGID}.png"
echo ""
