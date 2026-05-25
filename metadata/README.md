# Pocket Mole Watch — 提审资料

## 目录结构

```
metadata/
├── app-icon.png               # App Store 图标 1024x1024
├── app-privacy.md             # App 隐私问卷答案
├── screenshots/
│   └── watch/
│       └── home.png           # 主截图
├── en-US/                     # 英文元数据
│   ├── name.txt               # App 名称
│   ├── subtitle.txt           # 副标题
│   ├── description.txt        # 完整描述
│   ├── keywords.txt           # 关键词
│   ├── promotional_text.txt   # 宣传文本
│   ├── release_notes.txt      # 更新说明
│   ├── privacy_policy_url.txt # 隐私政策 URL
│   ├── support_url.txt        # 技术支持 URL
│   └── review_notes.md        # 审核备注
└── zh-Hans/                   # 简体中文元数据
    ├── ...                    # (同上结构)
```

## 提审前请修改

⚠️ **URL 待替换**：`privacy_policy_url.txt` 和 `support_url.txt` 中的 `example.com` 需要替换为实际域名。

当前 `docs/` 目录下的页面（`privacy.html`、`index.html`）需要部署后才可访问。

## 其他已就绪项

- **隐私问卷**：参考 `app-privacy.md`，所有数据类型均为「否」
- **出口合规**：`Info.plist` 中已设置 `ITSAppUsesNonExemptEncryption = NO`
- **年龄分级**：无用户生成内容、无不适宜内容，建议 4+
- **App 图标**：已含 1024x1024 PNG

## App Store Connect 填写速查

| 字段 | 值 |
|---|---|
| Bundle ID | com.yangpan.pocketmole.watchkitapp |
| Apple Watch | WKWatchOnly = true（纯手表应用） |
| 加密 | 不含非豁免加密 |
| 分类 | 游戏 → 休闲 / 街机 |
| 价格 | 免费 |
| 年龄分级 | 4+ |
| 语言 | 英语、简体中文 |
