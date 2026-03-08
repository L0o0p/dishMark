# DishMark 设计系统

> 极简、冷静、略带 iOS 风格的移动应用设计系统  
> 适用于 Flutter 实现

---

## 目录

1. [设计原则](#设计原则)
2. [颜色系统](#颜色系统)
3. [排版系统](#排版系统)
4. [间距系统](#间距系统)
5. [圆角系统](#圆角系统)
6. [阴影系统](#阴影系统)
7. [组件规范](#组件规范)
8. [交互状态](#交互状态)

---

## 设计原则

| 原则 | 描述 |
|------|------|
| **清晰度** | 信息层级明确，避免视觉噪音 |
| **一致性** | 全应用保持统一的视觉语言 |
| **极简** | 去除不必要的装饰元素 |
| **可用性** | 优先保证可访问性和易用性 |
| **Flutter 友好** | 设计决策考虑 Flutter 实现成本 |

---

## 颜色系统

### 基础色板

#### 主色调

| 名称 | 变量名 | 值 | 用途 |
|------|--------|-----|------|
| Primary | `primary` | `#E6884D` | 主按钮、强调元素、选中状态 |
| Primary Dark | `primaryDark` | `#2A170B` | Primary 上的文字颜色 |

#### 辅助色

| 名称 | 变量名 | 值 | 用途 |
|------|--------|-----|------|
| Secondary | `secondary` | `#FFD7B8` | 次要强调、标签背景 |
| Surface Elevated | `surfaceElevated` | `#FFF7EE` | 浮层、高亮区域 |

#### 中性色

| 名称 | 变量名 | 值 | 用途 |
|------|--------|-----|------|
| Background | `background` | `#F4EFE8` | 页面背景 |
| Surface | `surface` | `#FFFBF7` | 卡片、容器背景 |
| Input Background | `inputBackground` | `#F5F5F5` | 输入框背景 |

#### 文字颜色

| 名称 | 变量名 | 值 | 用途 |
|------|--------|-----|------|
| Text Primary | `textPrimary` | `#3F332A` | 主标题、正文 |
| Text Secondary | `textSecondary` | `#7B6B5D` | 副标题、描述文字 |
| Text Placeholder | `textPlaceholder` | `#8A8A8A` | 占位符文字 |

#### 功能色

| 名称 | 变量名 | 值 | 用途 |
|------|--------|-----|------|
| Tag Background | `tagBackground` | `#E8DDD1` | 标签默认背景 |
| Tag Foreground | `tagForeground` | `#6F5F51` | 标签文字 |
| Outline | `outline` | `#DCCDBE` | 边框、分割线 |
| Danger | `danger` | `#B85E4A` | 删除、警告操作 |
| Success | `success` | `#4CAF50` | 成功状态 |

### 玻璃态效果（地图操作按钮）

| 名称 | 变量名 | 值 | 用途 |
|------|--------|-----|------|
| Glass Fill | `glassFill` | `#60FFFFFF` | 玻璃态填充 |
| Glass Fill Emphasized | `glassFillEmphasized` | `#FFFFFFFF` | 强调玻璃态填充 |
| Glass Border | `glassBorder` | `#40FFFFFF` | 玻璃态边框 |
| Glass Highlight Top | `glassHighlightTop` | `#52FFFFFF` | 顶部高光 |
| Glass Highlight Bottom | `glassHighlightBottom` | `#00FFFFFF` | 底部高光渐变 |

### 颜色使用示例

```dart
// 主按钮
Container(
  color: SoftPalette.primary,
  child: Text('确认', style: TextStyle(color: SoftPalette.primaryDark)),
)

// 卡片背景
Container(
  decoration: BoxDecoration(
    color: SoftPalette.surface,
    borderRadius: SoftRadius.card,
  ),
)

// 文字层级
Text('主标题', style: TextStyle(color: SoftPalette.textPrimary));
Text('副标题', style: TextStyle(color: SoftPalette.textSecondary));
Text('占位符', style: TextStyle(color: SoftPalette.textPlaceholder));
```

---

## 排版系统

### 字体栈

```dart
const List<String> fallbackFonts = <String>[
  'SF Pro Rounded',      // 首选：iOS 风格圆角字体
  'PingFang SC',         // 苹方（iOS 中文）
  'Hiragino Sans GB',    // 冬青黑体
  'Noto Sans CJK SC',    // 思源黑体
  'Source Han Sans SC',  // 思源黑体
  'Segoe UI',            // Windows 回退
  'sans-serif',          // 通用回退
];
```

### 字号规范

| 层级 | 名称 | 字号 | 字重 | 行高 | 字间距 | 用途 |
|------|------|------|------|------|--------|------|
| **Title Large** | `titleLarge` | 23sp | 700 | 1.2 | - | 页面主标题 |
| **Title Medium** | `titleMedium` | 18sp | 600 | 1.24 | - | 卡片标题、副标题 |
| **Body Large** | `bodyLarge` | 16sp | 500 | 1.45 | - | 主要正文内容 |
| **Body Medium** | `bodyMedium` | 14sp | 500 | 1.42 | - | 次要正文、列表项 |
| **Body Small** | `bodySmall` | 12sp | 500 | 1.35 | - | 辅助说明、时间戳 |
| **Label Large** | `labelLarge` | 14sp | 600 | - | 0.1px | 按钮文字、标签 |

### 排版使用示例

```dart
// 页面标题
Text(
  '我的收藏',
  style: Theme.of(context).textTheme.titleLarge,
)

// 卡片标题
Text(
  '餐厅名称',
  style: Theme.of(context).textTheme.titleMedium,
)

// 正文内容
Text(
  '这是一家很棒的餐厅，食物美味，服务周到。',
  style: Theme.of(context).textTheme.bodyLarge,
)

// 按钮文字
Text(
  '确认',
  style: Theme.of(context).textTheme.labelLarge,
)
```

---

## 间距系统

### 基础单位

基于 **4px** 作为基础单位，采用简单比例：

| 名称 | 值 | 用途 |
|------|-----|------|
| `spaceXxs` | 4px | 极小间距（图标与文字） |
| `spaceXs` | 8px | 小间距（紧凑元素间） |
| `spaceSm` | 12px | 中小间距 |
| `spaceMd` | 16px | 标准间距（卡片内边距） |
| `spaceLg` | 24px | 大间距（卡片间、页面边距） |
| `spaceXl` | 32px | 极大间距（区块分隔） |

### 间距使用场景

| 场景 | 间距值 | 示例 |
|------|--------|------|
| 图标与文字间距 | 4px | 按钮内图标与文字 |
| 紧凑列表项 | 8px | 列表项之间 |
| 卡片内边距 | 16px | 卡片内容与边缘 |
| 卡片外边距 | 16px | 卡片与页面边缘 |
| 区块分隔 | 24px | 不同内容区块之间 |
| 页面边距 | 16px | 页面左右边距 |

### 间距使用示例

```dart
// 卡片内边距
Padding(
  padding: const EdgeInsets.all(16.0), // spaceMd
  child: Column(
    children: [
      SizedBox(height: 8), // spaceXs
      Text('标题'),
      SizedBox(height: 12), // spaceSm
      Text('内容'),
    ],
  ),
)

// 列表项间距
ListView.separated(
  itemCount: 10,
  separatorBuilder: (_, __) => const SizedBox(height: 8),
  itemBuilder: (_, index) => ListItem(),
)
```

---

## 圆角系统

### 圆角规范

| 名称 | 变量名 | 值 | 用途 |
|------|--------|-----|------|
| Card | `card` | 24px | 标准卡片、对话框 |
| Large Card | `largeCard` | 30px | 大卡片、浮层 |
| Tag | `tag` | 999px | 标签、Chip（完全圆角） |
| Input | `input` | 20px | 输入框、搜索框 |
| Button | `button` | 14px | 按钮（SnackBar 等） |

### 圆角使用示例

```dart
// 卡片圆角
Container(
  decoration: BoxDecoration(
    color: SoftPalette.surface,
    borderRadius: SoftRadius.card, // 24px
  ),
)

// 标签圆角
Chip(
  shape: RoundedRectangleBorder(
    borderRadius: SoftRadius.tag, // 999px (完全圆角)
  ),
)

// 输入框圆角
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: SoftRadius.input, // 20px
    ),
  ),
)
```

---

## 阴影系统

### 阴影原则

- **仅使用微妙的阴影**，避免过度装饰
- **两层阴影**模拟真实光照效果
- **低透明度**保持视觉轻盈

### 阴影规范

| 名称 | 用途 | 阴影层 1 | 阴影层 2 |
|------|------|----------|----------|
| Floating | 浮动卡片 | `#12000000`, blur: 24, offset: (0, 10) | - |
| Map Action | 地图操作按钮 | `#14000000`, blur: 24, offset: (0, 12) | `#08000000`, blur: 8, offset: (0, 3) |

### 阴影使用示例

```dart
// 浮动卡片阴影
Container(
  decoration: BoxDecoration(
    color: SoftPalette.surface,
    borderRadius: SoftRadius.card,
    boxShadow: SoftShadow.floating,
  ),
)

// 地图操作按钮阴影
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    boxShadow: SoftShadow.mapAction,
  ),
)
```

---

## 组件规范

### 按钮 (Buttons)

#### 主按钮 (Primary Button)

| 属性 | 值 |
|------|-----|
| 背景色 | `primary` (#E6884D) |
| 文字颜色 | `primaryDark` (#2A170B) |
| 高度 | 48px |
| 圆角 | 14px |
| 内边距 | 水平 24px |
| 字重 | 600 |

```dart
SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: SoftPalette.primary,
      foregroundColor: SoftPalette.primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: const Text('确认'),
  ),
)
```

#### 次级按钮 (Secondary Button)

| 属性 | 值 |
|------|-----|
| 背景色 | `secondary` (#FFD7B8) |
| 文字颜色 | `textPrimary` (#3F332A) |
| 高度 | 48px |
| 圆角 | 14px |

#### 幽灵按钮 (Ghost Button)

| 属性 | 值 |
|------|-----|
| 背景色 | transparent |
| 文字颜色 | `primary` (#E6884D) |
| 边框 | 1px solid `primary` |
| 高度 | 48px |
| 圆角 | 14px |

---

### 卡片 (Cards)

#### 标准卡片

| 属性 | 值 |
|------|-----|
| 背景色 | `surface` (#FFFBF7) |
| 圆角 | 24px |
| 内边距 | 16px |
| 阴影 | `floating` |

```dart
Container(
  decoration: SoftDecorations.floatingCard(),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Text('标题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('内容描述', style: TextStyle(fontSize: 14, color: SoftPalette.textSecondary)),
      ],
    ),
  ),
)
```

#### 大卡片 (Large Card)

| 属性 | 值 |
|------|-----|
| 背景色 | `surface` |
| 圆角 | 30px |
| 内边距 | 24px |

---

### 列表项 (List Items)

| 属性 | 值 |
|------|-----|
| 高度 | 最小 72px |
| 内边距 | 水平 16px, 垂直 12px |
| 间距 | 8px (项与项之间) |
| 分割线 | `outline` with alpha 0.5 |

```dart
ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  title: Text('标题', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
  subtitle: Text('副标题', style: TextStyle(fontSize: 14, color: SoftPalette.textSecondary)),
  trailing: const Icon(Icons.chevron_right, color: SoftPalette.textSecondary),
)
```

---

### 输入框 (Input Fields)

| 属性 | 值 |
|------|-----|
| 背景色 | `inputBackground` (#F5F5F5) |
| 圆角 | 20px |
| 高度 | 48px |
| 内边距 | 水平 16px, 垂直 14px |
| 边框颜色（默认） | transparent |
| 边框颜色（聚焦） | `primary` (#E6884D), 1.2px |
| 占位符颜色 | `textPlaceholder` (#8A8A8A) |

```dart
TextField(
  decoration: InputDecoration(
    hintText: '请输入...',
    hintStyle: const TextStyle(color: SoftPalette.textPlaceholder),
    filled: true,
    fillColor: SoftPalette.inputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: SoftRadius.input,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: SoftRadius.input,
      borderSide: const BorderSide(color: SoftPalette.primary, width: 1.2),
    ),
  ),
)
```

---

### 对话框 (Modals/Dialogs)

| 属性 | 值 |
|------|-----|
| 背景色 | `surface` (#FFFBF7) |
| 圆角 | 24px |
| 内边距 | 24px |
| 标题字号 | 18sp, 600 |
| 内容字号 | 16sp, 500 |
| 按钮高度 | 48px |

---

### 标签 (Tags/Chips)

| 属性 | 值 |
|------|-----|
| 背景色（默认） | `tagBackground` (#E8DDD1) |
| 背景色（选中） | `secondary` (#FFD7B8) |
| 文字颜色 | `tagForeground` (#6F5F51) |
| 圆角 | 999px (完全圆角) |
| 高度 | 32px |
| 内边距 | 水平 12px |
| 字号 | 14sp, 600 |

---

## 交互状态

### 按钮状态

| 状态 | 描述 | 效果 |
|------|------|------|
| **Default** | 默认状态 | 正常显示 |
| **Hover** | 鼠标悬停（仅平板/桌面） | 亮度 +10% |
| **Pressed** | 按下状态 | 亮度 -10%, 缩放 0.98 |
| **Disabled** | 禁用状态 | 透明度 50%, 不可点击 |
| **Focused** | 键盘聚焦 | 显示聚焦边框 |

```dart
// 按钮状态示例
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: SoftPalette.primary,
    foregroundColor: SoftPalette.primaryDark,
  ).copyWith(
    disabledBackgroundColor: SoftPalette.primary.withValues(alpha: 0.5),
  ),
  onPressed: isEnabled ? () {} : null,
  child: const Text('确认'),
)
```

### 输入框状态

| 状态 | 描述 | 效果 |
|------|------|------|
| **Default** | 默认状态 | 无边框或透明边框 |
| **Hover** | 鼠标悬停 | 边框颜色 `outline` |
| **Focused** | 聚焦状态 | 边框颜色 `primary`, 1.2px |
| **Error** | 错误状态 | 边框颜色 `danger` |
| **Disabled** | 禁用状态 | 背景色变灰，不可编辑 |

### 卡片/列表项状态

| 状态 | 描述 | 效果 |
|------|------|------|
| **Default** | 默认状态 | 正常显示 |
| **Hover** | 鼠标悬停 | 亮度 +5% |
| **Pressed** | 按下/点击 | 亮度 -5%, 缩放 0.99 |

### 可点击区域最小尺寸

为确保可访问性，所有可点击元素的最小尺寸为：

- **最小尺寸**: 44x44px (iOS 标准)
- **推荐尺寸**: 48x48px

```dart
// 确保最小点击区域
InkWell(
  onTap: () {},
  child: const SizedBox(
    width: 48,
    height: 48,
    child: Icon(Icons.add),
  ),
)
```

---

## Flutter 实现参考

### 主题配置入口

```dart
// lib/theme/soft_spatial_theme.dart
class SoftSpatialTheme {
  static ThemeData build() {
    // ... 主题配置
  }
}
```

### 使用方式

```dart
// main.dart
void main() {
  runApp(
    MaterialApp(
      theme: SoftSpatialTheme.build(),
      home: const HomePage(),
    ),
  );
}

// 页面中使用
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: SoftPalette.background,
      appBar: AppBar(
        title: Text('标题', style: theme.textTheme.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 使用设计系统组件
          ],
        ),
      ),
    );
  }
}
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-03-07 | 初始版本，基于现有 `soft_spatial_theme.dart` 整理 |

---

## 附录：完整色板速查

```dart
// 主色
SoftPalette.primary           // #E6884D
SoftPalette.primaryDark       // #2A170B

// 辅助色
SoftPalette.secondary         // #FFD7B8
SoftPalette.surfaceElevated   // #FFF7EE

// 中性色
SoftPalette.background        // #F4EFE8
SoftPalette.surface           // #FFFBF7
SoftPalette.inputBackground   // #F5F5F5

// 文字色
SoftPalette.textPrimary       // #3F332A
SoftPalette.textSecondary     // #7B6B5D
SoftPalette.textPlaceholder   // #8A8A8A

// 功能色
SoftPalette.tagBackground     // #E8DDD1
SoftPalette.tagForeground     // #6F5F51
SoftPalette.outline           // #DCCDBE
SoftPalette.danger            // #B85E4A
SoftPalette.success           // #4CAF50
```
