# 用 Agent 比较 BOM 版本

[English](capability.en.md) | [简体中文](capability.zh-CN.md)

比较两版 BOM CSV/XLSX，列出料号新增、删除、数量及规格变化、重复键，并保留原文件、工作表及行号。

完整流程见 [Qumge 工业文件任务指南](https://qumge.com/zh/docs/industrial)，包括实时可用状态、列映射、私有上传、费用授权和报告下载。无需安装本项目；需要持续管理业务记录与协作时，可以使用本项目的完整管理流程。

1. 让 Agent 在 Qumge 搜索 `compare BOM versions`，读取匹配的已上线契约与当前价格；没有匹配操作则停止。
2. 先用 [examples/industrial](../examples/industrial) 中的合成 CSV 样例，不含客户数据。
3. 使用调用方买家的 Qumge key，向 `POST https://qumge.com/v1/industrial/files` 上传每份文件。标识符按文本保留，显式映射表头；样例用英文字段，实际文件可以使用中文表头。
4. 取得费用授权后，将 file_id 传给 `museflow-bom-comparison` 的 `compare_bom` 操作。重试相同输入时复用幂等标识，轮询返回的平台任务 ID。
5. 使用同一买家 key 或已登录该买家账户的浏览器下载私有 Excel／JSON，并按来源行核查结果。

限制：UTF-8 CSV／XLSX，每份 512 KiB、2,000 行数据、32 列；多工作表 XLSX 需指定工作表。公式先导出为值，日期存成 ISO 文本。文件及报告 24 小时后过期。Qumge 不会把这两个操作的文件内容交给模型。上传需要你明确发起，自部署应用不会自动上传业务数据。

两版映射料号、数量及可选父级／规格／单位／说明。重复键单列，不随意配对。样例包含一个新增、一个删除、一个变化料号及一组重复键问题。此任务不分析 CAD 几何，不代替工程审批。

托管 Cap 的可用状态与价格独立于本 MIT 开源项目。合成样例和连通性检查不代表生产付费交付验证。
