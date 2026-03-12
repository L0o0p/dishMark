# DishMark 分享卡片系统实现文档

## 1. 目标

当用户分享 DishMark 内容到微信、iMessage 等平台时，展示标准卡片：

- 标题：菜品/推荐语
- 描述：地点、口味、补充信息
- 封面图：动态生成的分享图
- 跳转：`https://dishmark.app/m/{id}`（支持 Universal Link + App Deep Link）

实现方式：

- 分享 URL
- OpenGraph Meta
- 动态生成分享图片

## 2. 系统架构

```text
Flutter App
    │
    ▼
Share URL: https://dishmark.app/m/{id}
    │
    ▼
Web Share Page (Next.js / Nest / static)
    ├── OG Meta
    └── Share Image API: /share/{id}.png
            │
            ▼
      Satori -> SVG -> Resvg -> PNG
```

## 3. URL 设计

- 分享页：`https://dishmark.app/m/{id}`
- 分享图：`https://dishmark.app/share/{id}.png`

Flutter 端使用统一服务生成链接：

- 文件：`lib/service/share_link_service.dart`
- 默认域名：`https://dishmark.app`
- 可通过 `--dart-define=SHARE_BASE_URL=...` 覆盖

## 4. Flutter 端当前实现

已完成：

1. 创建菜品后自动写入 `shareUrl`（`/m/{id}`）。
2. 编辑菜品时自动补齐历史数据的 `shareUrl`。
3. 分享面板内：
   - 微信会话/朋友圈：支持分享卡片图片。
   - 微信链接：使用 `shareUrl` 分享网页链接。
   - 系统分享（iMessage 等）：分享文案 + URL。
   - 复制：复制文案 + URL。

关键文件：

- `lib/service/share_link_service.dart`
- `lib/page/create_dish_mark.dart`
- `lib/page/dish_mark_detail.dart`
- `lib/widgets/share_card.dart`

## 5. Share Page HTML（服务端）

`/m/{id}` 页面应返回可抓取 HTML：

```html
<meta property="og:type" content="website">
<meta property="og:title" content="东京这家拉面值得排队">
<meta property="og:description" content="池袋 · 豚骨拉面">
<meta property="og:image" content="https://dishmark.app/share/abc123.png">
<meta property="og:url" content="https://dishmark.app/m/abc123">
<meta name="twitter:card" content="summary_large_image">
```

并在正文执行 Deep Link 跳转（带兜底逻辑）：

```js
window.location.href = "dishmark://moment/abc123";
```

## 6. 分享图服务（服务端）

推荐：

- Node.js
- `satori`
- `@resvg/resvg-js`

输出尺寸：

- `1200 x 630`

## 7. 微信抓取要求

- 必须 HTTPS
- 公网可访问
- 无登录拦截
- OG Meta 在服务端可直接返回

## 8. 缓存策略

微信存在缓存，建议：

- URL 版本号：`/m/{id}?v=2`
- 或响应头：`cache-control: no-cache`

## 9. MVP 实施顺序

1. Flutter 分享 URL（已完成）
2. `/m/{id}` Share Page（待实现）
3. OG Meta（待实现）
4. `/share/{id}.png` 图片 API（待实现）
5. Universal Link / Deep Link 全链路联调（待实现）
