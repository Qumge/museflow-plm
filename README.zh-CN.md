[English](README.md) | [中文](README.zh-CN.md)

# MuseFlow

面向制造业工程团队的产品、零件与工艺文件管控系统。MuseFlow 是一个**自托管、
单租户**的 PLM（产品生命周期管理）系统：管理 CAD 图纸版本、零件、工艺文件与
BOM 发布，全部走一套工程审批流程——一家公司的数据，部署在你自己可控的基础
设施上。

它不是多租户 SaaS。所有登录用户看到的都是同一家公司的图纸，没有租户级的数据
隔离——这是有意为之的设计（详见下方[术语与定位](#术语与定位)）。

## 快速开始

前置依赖：Ruby 4.0.1、PostgreSQL、Redis，均需在本地运行。

```bash
bundle install
bin/rails db:setup   # 建库 + 载入 schema + 载入演示数据
bin/rails server
```

然后访问 **http://localhost:3000** —— 会看到落地页；用下方的
[演示账号](#注册说明与演示账号)登录即可进入系统。

如果本地 PostgreSQL 的账号密码不是默认的 `postgres`/无密码，把
`.env.example` 复制为 `.env`，在 `db:setup` 之前填好 `DB_USERNAME` /
`DB_PASSWORD` / `DB_HOST`。

## 管理什么

MuseFlow 围绕四条业务线组织。演示种子数据（`bin/rails db:setup`）会为每条
业务线各生成一条可用样例：

| 业务线 | 是什么 |
|---|---|
| **产品（Product）** | 顶层的制造装配体 |
| **零件（Part）** | 挂在产品或另一个零件下的组件/子装配 |
| **工艺文件（Process Document）** | 挂在产品或零件上的加工工艺说明 |
| **Bom单（BOM Release）** | 某个装配体已发布的物料清单 |

针对以上任一业务线上传的图纸，都走同一套审批流程：**草稿 → 申请 →
技术审批 → 流程审批 → 生效**，任意中间环节都可以**驳回**给提交人。

## 技术栈

Rails 7.1（Ruby 4.0.1）· PostgreSQL · Redis + Sidekiq（后台任务）·
Devise（认证）· CanCanCan（权限）· RailsAdmin（`/admin` 后台）·
Bootstrap 5 · ActiveStorage（默认本地磁盘，生产环境可用 Cloudflare R2）。

**依赖安全现状**：发布前的整改把 `bundle audit` 报出的 High/Critical 从
12 降到了 2。剩余 2 个都是 `puma` 的漏洞，修复需要跨大版本升级到 puma 7/8，
而这又会连带要求更新的 Rails 版本——本次未一并处理，留作后续。可自行运行
`bundle audit check` 查看当前状态。

## 部署

MuseFlow 目前还没有配套的 Dockerfile / `docker-compose.yml`——这是已知的
待办事项，因为本机没有 docker 环境无法实测其确实能跑起来，所以本次发布没
有提供未经验证的配置。现阶段请按部署任意 Rails 7 应用的方式来部署。

**Render（或类似的 PaaS）：**

- 构建命令：`bundle install && bin/rails assets:precompile`
- 启动命令：`bin/rails server`
- 准备好一个 PostgreSQL 与一个 Redis 实例，设置 `DB_USERNAME`、
  `DB_PASSWORD`、`DB_HOST`、`REDIS_URL`、`SECRET_KEY_BASE`。
- 首次部署时执行 `bin/rails db:migrate`（如果想要演示账号，再执行
  `db:seed`）。

**在 Render 一类文件系统临时的 PaaS 上存文件**：默认的 `local` 磁盘存储会在
下一次部署或重启后静默丢失所有已上传文件——不报错、不提示，数据库里的记录
还在，文件本身却已经不存在了。设置 `STORAGE_SERVICE=r2` 及四个 `R2_*`
环境变量（见 `.env.example`），改用 Cloudflare R2（S3 兼容）存储上传文件。

⚠️ **R2 bucket 必须配置 CORS 策略**，否则浏览器直传到 R2 会被当作跨域请求
拦截，每次上传都会卡在"上传中"，控制台报 CORS / preflight 错误。具体的
CORS 策略 JSON 见 `.env.example`，在 Cloudflare 控制台的
*R2 → 目标 bucket → Settings → CORS policy* 里添加。

## 注册说明与演示账号

自助注册**默认关闭**——MuseFlow 是单租户系统，一旦向公众开放
`/users/sign_up`，任何找到这个地址的人注册后都能登录看到这家公司的图纸。
设置 `ALLOW_REGISTRATION=true` 可以打开它（例如搭建一个公开的演示/评估环
境）；正式部署请保持关闭，改由 `/admin` 后台创建账号。

种子数据会创建四个演示账号，密码统一为 `password123`。登录用的是
**账号（login）**，不是邮箱：

| 账号 | 角色 | 能看到什么 |
|---|---|---|
| `admin` | 超级管理员 | 全部内容，以及 `/admin` 后台 |
| `devmgr` | 研发管理 | 技术审批环节 |
| `dev` | 研发 | 草稿、申请提交 |
| `proc` | 流程管理 | 流程审批环节 |

## 术语与定位

界面上使用的制造业术语，和底层 Rails 模型的类名并不总是一致——这是有意为
之并已文档化的差异，不是 bug。这是整改过程中一个明确的决定：**不**在项目
稳定化过程中重命名模型，避免为了名字好看而牵连出大量迁移脚本和代码引用的
改动。

| 模型名（代码里） | 界面 / 业务术语 |
|---|---|
| `Product` | 产品 |
| `Instance` | **零件（Part）** |
| `Technology` | **工艺文件（Process Document）** |
| `Matter` | **Bom单（BOM Release）** |

如果你在代码里看到 `Instance`，它在用户看到的每一处都叫"零件"。
`Technology`（工艺文件）、`Matter`（Bom单）同理。

## `/admin` 后台

`/admin` 是给系统管理员用的独立数据管理后台，基于
[RailsAdmin](https://github.com/railsadminteam/rails_admin) 构建。在这里
建用户、配角色权限、维护产品类型/物料属性/组织架构等基础数据。需要
`super_admin` 角色才能访问。

它的视觉风格和主应用刻意不同——它是一个通用的数据表格管理工具，不是重新设
计过的界面，因为工程师日常用的是主应用，只有管理员才会进入 `/admin`。这种
"两套皮"的观感是有意为之，不是没做完的界面。

## 贡献指南

见 [CONTRIBUTING.md](CONTRIBUTING.md)——如何跑测试、CI 会检查什么，以及
i18n 规则（任何面向用户的文案改动都必须同时更新
`config/locales/en/` 与 `config/locales/zh-CN/`）。

## License

[MIT](LICENSE) —— 见 LICENSE 文件。
