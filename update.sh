#!/bin/bash

# 1. 先清理掉旧的索引文件，防止冲突
echo "🧹 正在清理旧文件..."
rm Packages Packages.bz2

# 2. 扫描 debs 文件夹，生成新的“菜单” (Packages)
echo "📦 正在扫描插件生成新索引..."
dpkg-scanpackages -m ./debs > Packages
# 2.5 自动补回 SileoDepiction 链接
echo "🔗 正在添加 Sileo 详情页链接..."
for json in sileodepictions/com.rain.*.json; do
    pkgid=$(basename "$json" .json)
    if grep -q "^Package: $pkgid$" Packages; then
        # 找到该包最后一行(Name行)，在后面追加 SileoDepiction
        if ! grep -A100 "^Package: $pkgid$" Packages | grep -q "SileoDepiction"; then
            sed -i '' "/^Package: $pkgid$/,/^$/{
                /^Name:/{
                    a\\
SileoDepiction: https://rain1-d1l.pages.dev/sileodepictions/${pkgid}.json
                }
            }" Packages
        fi
    fi
done# 2.6 自动标注双架构版本 (Roothide/Rootless)
echo "🏷 正在标注双架构版本..."
dual_arch_pkgs=$(awk '/^Package:/{pkg=$2} /^Architecture: iphoneos-arm64e$/{e[pkg]=1} /^Architecture: iphoneos-arm64$/{a[pkg]=1} END{for(p in e) if(p in a) print p}' Packages)
for pkgid in $dual_arch_pkgs; do
    awk -v pkg="$pkgid" '
    /^Package:/ { cur_pkg=$2; cur_arch="" }
    /^Architecture:/ { cur_arch=$2 }
    /^Name:/ && cur_pkg==pkg {
        if (cur_arch=="iphoneos-arm64e") { print $0 " (Roothide)"; next }
        if (cur_arch=="iphoneos-arm64") { print $0 " (Rootless)"; next }
    }
    { print }
    ' Packages > Packages.tmp && mv Packages.tmp Packages
done
# 3. 把“菜单”压缩一下，方便手机下载 (Packages.bz2)
echo "🗜 正在压缩索引..."
bzip2 -k Packages

# 4. 把所有东西上传到 GitHub
echo "🚀 正在上传到云端..."
git add .
git commit -m "Auto update via script"
git push

echo "✅ 全部搞定！你的源已经更新了。"