# Docker 部署指南

本项目支持通过 Docker 在多平台运行，包括 x86_64、ARM64 和 ARM32 架构。

## 支持的平台

- `linux/amd64` - x86_64 架构（常规服务器、PC）
- `linux/arm64` - ARM64 架构（树莓派 4、Apple Silicon、AWS Graviton）
- `linux/arm/v7` - ARM32 架构（树莓派 3 及更早版本）

## 快速开始

### 1. 准备配置文件

确保你已经配置好 `config.yaml` 文件：

```bash
cp config.example.yaml config.yaml
# 编辑 config.yaml，填入你的钱包私钥和参数
```

### 2. 使用 Docker Compose（推荐）

最简单的方式是使用 Docker Compose：

```bash
# 启动机器人
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止机器人
docker-compose down
```

### 3. 直接使用 Docker

```bash
# 构建镜像
docker build -t standx-maker-bot .

# 运行容器
docker run -d \
  --name standx-bot \
  --restart unless-stopped \
  -v $(pwd)/config.yaml:/app/config.yaml:ro \
  -v $(pwd)/logs:/app/logs \
  standx-maker-bot

# 查看日志
docker logs -f standx-bot

# 停止容器
docker stop standx-bot
docker rm standx-bot
```

## 多平台构建

如果你需要为不同平台构建镜像，可以使用提供的构建脚本：

```bash
# 赋予执行权限
chmod +x docker-build.sh

# 构建多平台镜像
./docker-build.sh
```

或者手动使用 Docker Buildx：

```bash
# 创建 builder
docker buildx create --name multiplatform-builder --use

# 构建多平台镜像
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t standx-maker-bot:latest \
  --load \
  .
```

## 运行多个机器人实例

如果你想同时运行多个机器人（不同账户或配置），编辑 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  standx-bot-1:
    build: .
    container_name: standx-bot-1
    restart: unless-stopped
    volumes:
      - ./config.yaml:/app/config.yaml:ro
      - ./logs:/app/logs

  standx-bot-2:
    build: .
    container_name: standx-bot-2
    restart: unless-stopped
    volumes:
      - ./config-bot2.yaml:/app/config.yaml:ro
      - ./logs:/app/logs
```

然后运行：

```bash
docker-compose up -d
```

## 查看日志

### 实时日志

```bash
# Docker Compose
docker-compose logs -f

# Docker
docker logs -f standx-bot
```

### 日志文件

日志文件会保存在 `./logs` 目录中：

- `latency_config.log` - API 延迟记录
- `reduce_config.log` - 减仓操作记录

## 更新机器人

```bash
# 停止容器
docker-compose down

# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build
```

## 环境变量

你可以通过环境变量覆盖某些配置：

```bash
docker run -d \
  -e TZ=Asia/Shanghai \
  -v $(pwd)/config.yaml:/app/config.yaml:ro \
  standx-maker-bot
```

## 故障排查

### 查看容器状态

```bash
docker ps -a
```

### 进入容器调试

```bash
docker exec -it standx-bot bash
```

### 检查配置文件

```bash
docker exec standx-bot cat /app/config.yaml
```

### 测试网络延迟

```bash
docker exec standx-bot python test_latency.py
```

## 资源限制

如果需要限制容器资源使用，可以在 `docker-compose.yml` 中添加：

```yaml
services:
  standx-bot:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## 安全建议

1. **不要将 `config.yaml` 提交到 Git**
   - 已在 `.gitignore` 和 `.dockerignore` 中排除

2. **使用只读挂载配置文件**
   - 注意 `:ro` 标志：`-v ./config.yaml:/app/config.yaml:ro`

3. **定期更新基础镜像**
   ```bash
   docker pull python:3.11-slim
   docker-compose build --no-cache
   ```

4. **使用非 root 用户运行**（可选）
   在 Dockerfile 中添加：
   ```dockerfile
   RUN useradd -m -u 1000 botuser
   USER botuser
   ```

## 性能优化

### 使用本地时区

```yaml
environment:
  - TZ=Asia/Shanghai
```

### 持久化日志

```yaml
volumes:
  - ./logs:/app/logs
```

### 网络模式

如果需要更好的网络性能：

```yaml
network_mode: host
```

注意：使用 `host` 模式会失去容器网络隔离。

## 监控和告警

配合 `monitor.py` 使用：

```bash
# 在宿主机运行监控脚本
python monitor.py config.yaml config-bot2.yaml
```

或者在单独的容器中运行：

```yaml
services:
  monitor:
    build: .
    container_name: standx-monitor
    command: python monitor.py config.yaml
    volumes:
      - ./config.yaml:/app/config.yaml:ro
      - ./.env:/app/.env:ro
```

## 常见问题

### Q: ARM 平台构建很慢？
A: 这是正常的，因为需要编译 C 扩展。可以使用预构建的镜像或在目标平台上直接构建。

### Q: 如何查看实时价格更新？
A: 使用 `docker logs -f standx-bot | grep "Price update"`

### Q: 容器重启后订单状态？
A: 程序启动时会自动同步交易所状态，无需担心。

### Q: 如何优雅停止？
A: 使用 `docker-compose down` 或 `docker stop standx-bot`，程序会自动撤销所有挂单。

## 技术支持

如有问题，请查看：
- 主 README.md
- GitHub Issues
- 作者 Twitter: [@frozenraspberry](https://x.com/frozenraspberry)
