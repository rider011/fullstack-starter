# Fullstack Starter

一个可直接运行的 Vue 3 + NestJS + Prisma + PostgreSQL 全栈开发基线。

## 技术栈

- Vue 3、TypeScript、Vite、Vue Router、Pinia、Vitest
- NestJS 12、TypeScript、Vitest
- Prisma 7.10.1 + PostgreSQL 18
- npm Workspaces
- ESLint、Oxlint、Prettier、EditorConfig

## 环境要求

- Node.js 24.12 或更高版本（当前机器使用 Node.js 26）
- npm 11 或更高版本
- PostgreSQL 18，本地端口 `5432`
- VS Code 的 `Fullstack` 配置档案

## 首次启动

数据库初始化后，项目根目录已经存在被 Git 忽略的 `apps/api/.env`。若在其他机器重新搭建，请复制根目录的 `.env.example` 到 `apps/api/.env` 并填写真实密码。

```powershell
npm install
npm run db:generate
npm run db:migrate
npm run dev
```

访问地址：

- 前端：http://localhost:5173
- 健康检查：http://localhost:3000/api/health

Vite 会把 `/api` 请求代理到 NestJS，因此前端无需额外配置 API 地址。

## 常用命令

```powershell
npm run dev             # 同时启动前端和后端
npm run dev:web         # 只启动 Vue
npm run dev:api         # 只启动 NestJS
npm run build           # 构建所有工作区
npm run test            # 前后端单元测试
npm run test:e2e        # 使用本地 PostgreSQL 测试真实 API
npm run lint            # 检查并修复可自动修复的问题
npm run format          # 使用项目 Prettier 配置格式化
npm run db:generate     # 重新生成 Prisma Client
npm run db:migrate      # 创建并应用开发迁移
```

Prisma 7 必须使用同版本的 `prisma`、`@prisma/client` 和 `@prisma/adapter-pg`。npm 的 `latest` 标签目前指向 Prisma 8 RC，因此不要直接运行不带版本号的全局升级命令。

## 项目结构

```text
fullstack-starter/
├─ apps/
│  ├─ api/              # NestJS API、Prisma schema 和迁移
│  └─ web/              # Vue 应用
├─ scripts/             # PostgreSQL 初始化与恢复脚本
├─ .vscode/             # 工作区扩展、设置和调试配置
└─ package.json         # npm Workspaces 与统一命令
```

## 数据库

本地开发角色为 `fullstack_dev`，数据库为 `fullstack_dev`，不是 PostgreSQL 超级用户。该角色拥有 `CREATEDB`，用于 Prisma 创建临时 shadow database。

健康检查执行 `SELECT 1`；数据库不可用时接口返回 HTTP 503，前端状态卡会显示数据库错误。

## VS Code

打开项目时选择 `Fullstack` 配置档案。该档案包含：

- Vue Official
- ESLint
- Prettier
- Prisma
- EditorConfig

默认档案中的 C++、ROS、Java 和其他扩展不会被修改。
