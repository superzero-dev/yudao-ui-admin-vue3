# 定义变量
server := "8.141.16.19"
user := "root"
remote_path := "/apps/ruoyi-vue-pro/frontend"
local_dist := "dist"
timestamp := `date +%Y%m%d_%H%M%S`
archive_name := "dist_" + timestamp +".tar.gz"

# 默认任务
default:
    just --list

# 压缩 dist 文件夹
compress:
    @echo "🛠 Compressing {{local_dist}}..."
    @if [ ! -d "{{local_dist}}" ]; then \
        echo "❌ Error: {{local_dist}} directory not found!"; \
        exit 1; \
    fi
    tar -czvf {{archive_name}} {{local_dist}}
    @echo "✅ Compression complete: {{archive_name}}"
    @echo "📦 Archive size: $(du -h {{archive_name}} | cut -f1)"

# 上传到服务器
upload: compress
    @echo "🚀 Uploading {{archive_name}} to server..."
    scp {{archive_name}} {{user}}@{{server}}:{{remote_path}}/
    @echo "✅ Upload complete!"

# 在服务器解压并清理
extract-on-server: upload
    @echo "📦 Extracting on server..."
    ssh {{user}}@{{server}} \
        "cd {{remote_path}} && \
         mkdir -p {{timestamp}} && \
         tar -xzf {{archive_name}} -C {{timestamp}} && \
         rm -f {{archive_name}} && \
         ln -sfn {{timestamp}}/{{local_dist}} current && \
         echo '✅ Server extraction complete'"
    @echo "🔄 Syncing changes..."
    ssh {{user}}@{{server}} "sync"

# 清理本地临时文件
clean:
    @echo "🧹 Cleaning up..."
    rm -f dist_*.tar.gz
    @echo "✅ Local cleanup complete"

# 完整部署流程
deploy: compress upload extract-on-server clean
    @echo "🎉 Deployment completed successfully!"
    @echo "📁 Contents now at: {{user}}@{{server}}:{{remote_path}}/{{timestamp}}"
    @echo "🌐 Current symlink points to: {{remote_path}}/current"

# 显示帮助信息
help:
    @echo "Available commands:"
    @echo "  just compress         - 仅压缩 dist 文件夹"
    @echo "  just upload           - 仅上传（会自动先压缩）"
    @echo "  just extract-on-server - 在服务器解压"
    @echo "  just clean            - 删除本地压缩文件"
    @echo "  just deploy           - 完整部署流程（压缩+上传+服务器解压+清理）"