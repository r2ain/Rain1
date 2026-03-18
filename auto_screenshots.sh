#!/bin/bash

# 自动重命名截图 + 转换为 PNG
# 用法: ./auto_screenshots.sh [插件包名]
# 例如: ./auto_screenshots.sh com.rain.raincall
# 不带参数则处理所有插件文件夹

SCREENSHOTS_DIR="assets/screenshots"

process_folder() {
    local folder="$1"
    local name=$(basename "$folder")
    
    # 找出所有图片文件（排除已经是 1-5.png 的）
    local files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$folder" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.heic" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.gif" \) -print0 | sort -z)

    if [ ${#files[@]} -eq 0 ]; then
        return
    fi

    echo "📂 处理: $name (${#files[@]} 张图片)"

    if [ ${#files[@]} -gt 5 ]; then
        echo "   ⚠️  超过5张图片，只处理前5张"
    fi

    # 先把现有文件移到临时名避免冲突
    for f in "${files[@]}"; do
        mv "$f" "${f}.tmp_rename"
    done

    # 重命名 + 转换
    local count=0
    for f in "${files[@]}"; do
        count=$((count + 1))
        if [ $count -gt 5 ]; then
            # 超出5张的删除临时文件
            rm -f "${f}.tmp_rename"
            continue
        fi

        local target="$folder/${count}.png"
        local ext="${f##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        if [ "$ext" = "png" ]; then
            # 已经是 PNG，直接重命名
            mv "${f}.tmp_rename" "$target"
            echo "   ✅ ${count}.png (重命名)"
        else
            # 用 sips 转换为 PNG（macOS 自带）
            sips -s format png "${f}.tmp_rename" --out "$target" >/dev/null 2>&1
            rm -f "${f}.tmp_rename"
            echo "   ✅ ${count}.png (从 ${ext} 转换)"
        fi
    done

    echo ""
}

# 主逻辑
cd "$(dirname "$0")"

if [ -n "$1" ]; then
    # 处理指定插件
    folder="$SCREENSHOTS_DIR/$1"
    if [ -d "$folder" ]; then
        process_folder "$folder"
    else
        echo "❌ 文件夹不存在: $folder"
        exit 1
    fi
else
    # 处理所有插件文件夹
    echo "🔍 扫描所有截图文件夹..."
    echo ""
    found=0
    for folder in "$SCREENSHOTS_DIR"/com.rain.*/; do
        [ -d "$folder" ] || continue
        process_folder "$folder"
        found=1
    done
    if [ $found -eq 0 ]; then
        echo "没有找到需要处理的图片"
    fi
fi

echo "🎉 完成！"
