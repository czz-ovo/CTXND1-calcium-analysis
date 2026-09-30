# Calcium Analysis at 20 Hz

MATLAB 钙信号分析工具：基于已生成的 20 Hz ΔF/F 数据，统计事件持续时间、峰值 amplitude 和观察到的半衰减时间，并按记录、鼠和组导出结果。

## 快速开始

1. 下载仓库 ZIP 并解压，或克隆仓库。
2. 在 MATLAB 中将当前文件夹切换至仓库根目录。
3. 准备输入 MAT 文件和 Excel 记录列表。
4. 运行 `run_combined_calcium_dFF`，依次选择 Excel 列表和结果输出目录。

建议 MATLAB R2019a 或更新版本；无需运行 msInitialization、CNMF-E 或启动并行池。本工具读取已有 dFF，不包含原始影像处理或 dFF 转换流程。版本兼容性仍需在实际 MATLAB 环境验证。

## 输入要求

每段记录对应一个 `ms_DFF_20Hz.mat`，其中必须包含 `ms` 变量：

| 字段 | 要求 |
|---|---|
| `ms.dFF` | 非空实数矩阵，行是帧、列是细胞 |
| `ms.F0` | 与 dFF 同尺寸；非有限值及非正值对应的样本被排除 |
| `ms.dFFInfo.Options.Fs` | `20` |
| `ms.dFFInfo.Method` | `'CNMFE_background_normalized'` |
| `ms.dFFValid` | 可选，有效样本掩码，与 dFF 同尺寸 |

Excel 第一个工作表从 A1 开始，列名为 `Folder | Group | Mouse`。每行一段记录，三列均需填写；Folder 可为直接包含 MAT 文件的文件夹路径或 MAT 完整路径。同组同鼠多段记录使用相同标签。

`examples/session_list_template.csv` 是占位模板：请替换路径和标签，并在 Excel 中另存为 `.xlsx` 后用于分析。

## 分析定义

- 采样率固定为 20 Hz；持续时间为 `(EndFrame - StartFrame + 1) / 20`。
- long event 使用 **大于等于阈值**：`E.DurationSeconds >= round(threshold*c.Fs)/c.Fs`，见 `private/dffaAnalyze.m`。
- 默认分别统计 ≥5、≥10、≥15、≥20、≥30 s，各档累计重叠。**200 帧恰好 10 s，计入 ≥10 s；199 帧为 9.95 s，不计入。**
- 绘图高亮默认也采用 ≥10 s。
- Amplitude 为当前 dFF 零点参考下的峰值；半衰减为最高峰后首次回落至半峰水平的观察时间，相邻采样点间线性插值。
- duration 表统计全部检测事件；amplitude 和半衰减统计受 `MinAmplitude` 筛选。

默认参数、缺失数据和截断事件处理、结果列含义详见 [完整分析说明](README_合并分析.md)。

## 入口与输出

| 入口 | 用途 |
|---|---|
| `run_combined_calcium_dFF.m` | amplitude、半衰减、duration 合并导出 |
| `run_long_calcium_dFF.m` | duration 阈值统计 |
| `run_amplitude_dFF.m` | amplitude 分析 |
| `run_plot_dFF.m` | 轨迹绘图 |

共享参数在 `dffAnalysisConfig.m` 中，入口脚本可覆盖参数。运行生成独立结果目录，包含细胞表、鼠/组汇总、逐事件 CSV、分析 MAT 和处理报告；请先检查 `processing_report.csv`。

跨记录未做细胞配准，同鼠多段记录的细胞数是细胞记录数之和。组内细胞平均值不等于各鼠等权平均；以动物为单位的统计应使用 MouseSummary。

## 验证

在 MATLAB 仓库根目录运行：

```matlab
test_calcium_analysis();
test_combined_calcium(true);
```

第二个入口已调用第一个测试，包含数值测试及 MAT/Excel、分组回读测试，会在临时目录保留结果。

本次整理统一移除了原文件名、函数名、调用和文档中的人名后缀，分析逻辑保持不变；未执行 MATLAB 测试。`VALIDATION_combined.json` 是原压缩包附带的历史验证记录，其中入口名称已同步更新；`SHA256.json` 已按当前文件重新生成，不包含校验清单自身。历史验证记录不是本次运行结果。

## 上传 GitHub

在 GitHub 新建空仓库（建议名 `calcium-analysis-20hz`），将本目录内容上传至仓库根目录，保留 `private/` 和 `examples/` 子目录；不要上传外层 ZIP 文件作为源码。

如使用 Git，在本目录执行以下命令，替换仓库地址：

```sh
git init
git add .
git commit -m "Initial calcium analysis release"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/calcium-analysis-20hz.git
git push -u origin main
```

`.gitignore` 已忽略原始 MAT、Excel、批量输出和本地临时文件。仓库提供示例路径模板，不附实验数据。

## 授权

本整理包未添加开源许可证。发布者应根据代码归属选择合适的 LICENSE；上传 GitHub 本身不授予他人开源使用许可。
