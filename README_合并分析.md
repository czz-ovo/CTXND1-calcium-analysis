# 20 Hz：半衰减时间、amplitude、duration 合并分析

运行 `run_combined_calcium_dFF.m`，依次选择 Excel 列表和输出目录。新旧代码请放在不同文件夹；运行新版入口会把新版路径加入 MATLAB 搜索路径首位。无需 msInitialization、CNMF-E 或并行池。仍使用之前生成的 `ms_DFF_20Hz.mat`，不重新计算 dFF。MATLAB 建议 R2019a 或更新版本。

## 输入 Excel

第一个工作表从 A1 开始：`Folder | Group | Mouse`，第二行起每行一段记录。

- A：直接含 `ms_DFF_20Hz.mat` 的完整文件夹路径，或该 MAT 文件的完整路径。
- **本次合并分析 B、C 都必填**，分别为组名与鼠名。之前只分析单记录时可留空；本次为了准确按鼠、按组合并，不自动猜测缺失名字。
- 同鼠多段记录使用相同组名、鼠名，路径分别填写。名称按原文字精确匹配，大小写不同视为不同标签；同组内不同动物必须使用不同鼠名。
- 同一 MAT 文件重复出现，只保留第一次成功读取的记录及其标签，并写入处理报告。

## 生成的文件

每次运行使用全新的 `combined_日期时间_唯一编号` 目录：

```
ALL_cells.xlsx                  所有组的细胞合并表
by_mouse/mouse_001.xlsx          每只鼠（同组同鼠名）的所有记录合并
by_group/group_001.xlsx          每组所有鼠、所有细胞合并
row_0002/events.csv              Excel 第 2 行记录的逐事件明细
row_0002/analysis_results.mat    该记录的完整分析数据
combined_results.mat            全部细胞表、汇总、参数、处理报告
processing_report.csv           成功、失败、重复记录报告
```

编号对应关系直接见各表 `MouseID / Mouse / GroupID / Group`；用编号命名避免鼠名含非法路径字符或文件名冲突。失败记录不进入合并；所有汇总工作簿附处理报告，请先检查。每张工作表同时保存 CSV 备份。超出 Excel 行数上限的表自动分为同名前缀的多个 sheet，CSV 和 MAT 保留全表。

主要 sheet：

| Sheet | 每行的含义 |
|---|---|
| Amplitude_HalfDecay | 一个细胞在一段记录中的 amplitude 和半衰减统计，同时含平均事件 duration |
| Duration | 一个细胞 × 一个 duration 阈值，含次数、时间占比、频率 |
| MouseSummary | 一只鼠 × 一个 duration 阈值，含细胞数及 amplitude/半衰减汇总 |
| GroupSummary | 一个组 × 一个 duration 阈值；每组工作簿和 ALL 工作簿有此表 |
| ProcessingReport | 相关输入记录的处理状态 |
| Settings | 半衰减定义、计数方式及整个批次的处理数量 |

各细胞表保留 `Mouse`、`Group`、`ExcelRow`、原 `Neuron`、`Source`、唯一 `CellUID`、`MouseCellIndex`、`GroupCellIndex`、`NumCellsInMouse`、`NumCellsInGroup`、`NumMiceInGroup`。`Neuron` 是原记录内细胞编号。`NumCells` 包括未检测到事件的细胞，`NumValidCells` 是有有效数据的细胞，`NumCellsWithHalfDecay...` 是具有对应有效半衰减结果的细胞数。

**跨记录没有做细胞配准**。同一只鼠有多段记录时，细胞数为细胞记录数之和，`CellUID` 仅防止编号混淆，不代表识别出了跨记录同一个细胞。组表是按细胞合并，并保留鼠名；组汇总的 `MeanCell...` 是细胞均值的平均值，不是各鼠等权平均值。进行以动物为单位的统计时应使用 MouseSummary，而不是把所有细胞当作独立动物。

## 半衰减时间定义与末尾事件

本版计算的是**观察到的半衰减时间**，不是指数拟合的 tau，也不是钙离子或指示剂本身的半衰期。

- 输入使用当前 `ms.dFF`，其归一化零点作为基线；`Amplitude = PeakDFF` 保持原版定义，`HalfDecayLevel = 0.5 × Amplitude`。
- 从事件内最高峰（并列时第一个峰）向后，寻找第一次降到该水平的时间。跨越水平的相邻采样点做线性插值，最后除以 20 Hz 得秒数。插值不代表提高原始采样分辨率。
- 检测使用原来的均值/标准差阈值。半峰值有时低于事件结束阈值，所以允许在检测事件结束后继续寻找回落；最晚到下一检测事件开始前、缺失数据前或分析窗口末尾。绝不跨越 NaN/Inf 或进入下一事件。
- 不新增平滑或指数拟合；默认 SmoothFrames=1。半衰减读取原 dFF，与 amplitude 峰值使用同一轨迹。复杂多峰或合并事件仍按全事件最高峰及第一次半峰回落计算，不可解释为孤立单峰动力学。
- 原 `AUCdecay_halfDecay.m` 使用全程均值 μ 作参考。本版为了与当前 amplitude 一致使用 dFF 零点，因此数值与旧脚本不是同一定义；`HalfDecayBaseline=0` 随逐事件表导出。此零点仍沿用原 dFF 转换的 CNMF-E 背景归一化定义，不会重新估计细胞静息荧光 F0。

| 选择 | 对应列后缀 | 哪些事件进入统计 |
|---|---|---|
| 包含末尾事件 | 无后缀 | 所有通过 amplitude 筛选的检测事件 |
| 排除末尾未回落结束事件 | ExclEndCut | 去掉仍在最后一个分析帧持续的事件，保留其余事件 |
| 仅完整事件 | Complete | 同时排除左端、右端截断，包括缺失数据边界 |

末尾事件**没有完全结束但已经回落到半峰值**：半衰减可观测，进入“包含末尾事件”均值。末尾事件**没有降到半峰值**：记 NaN，不参与均值，计入缺失数量。包含末尾事件并不意味着能为没有观测到半峰回落的事件补出一个数。Excel 中 NaN 可能显示为空白，MAT 中保留 NaN，绝不能用 0 填补。

`EndedByTraceEnd` 是在最后分析帧仍未结束；`EndedByRecordingEnd` 表示原记录结束，`EndedByAnalysisEnd` 表示设置有限 AnalysisSeconds 后分析窗口结束。`EndedByMissingData` 表示被缺失数据切断。ExclEndCut 只排除前两种末尾情况，其他截断仍可能保留；需要全部排除时使用 Complete。

## 常用结果列

| 列名 | 含义 / 单位 |
|---|---|
| MeanHalfDecaySeconds | 包含末尾事件的可观测半衰减均值，秒 |
| MeanHalfDecaySecondsExclEndCut | 排除末尾未结束事件后的可观测半衰减均值，秒 |
| MeanHalfDecaySecondsComplete | 仅完整事件的可观测半衰减均值，秒 |
| NumHalfDecayObserved / NumHalfDecayMissing | 可观测 / 不可观测半衰减事件数；另有 ExclEndCut、Complete 版本 |
| MeanAmplitude / MeanAmplitudeExclEndCut / MeanAmplitudeComplete | 三种事件选择的平均峰值 ΔF/F0，比值 |
| MeanAmplitudePercent / MeanAmplitudeExclEndCutPercent / MeanAmplitudeCompletePercent | 对应比值乘 100，单位 %，不要再乘 100 |
| MeanEventDurationSeconds及其ExclEndCut、Complete版本 | 通过 amplitude 筛选事件的平均 duration，秒 |
| ThresholdSeconds | duration 的累计阈值，默认 5、10、15、20、30 秒 |
| NumLongObserved / NumLongExclEndCut / NumLongComplete | 持续时间 ≥ 阈值的事件数，分别含末尾、排除末尾、仅完整 |
| LongPercent / LongPercentExclEndCut | 对应事件占有效记录时间的百分比 |
| CompleteLongFraction | 完整 long 事件的时间占比，比值，乘 100 为 % |

保留原 duration 定义 `(EndFrame-StartFrame+1)/20`，阈值为 **≥**，不同阈值累计重叠；不能把 ≥5 秒与 ≥10 秒的次数相加当作总事件数。筛选完整事件不会缩短时间占比的分母，分母始终为该细胞有效分析时间。观察到的未结束事件 duration 只代表已记录的时长下限。

amplitude 与半衰减使用 `PassAmplitude` 筛选；duration 阈值表保留原版逻辑，对全部检测事件统计，不因 MinAmplitude 改变。默认 MinAmplitude=0，通常一致；若提高该参数，两类结果的事件集合可能不同。

## 参数及验证

入口保留 `Fs=20`、`HighSigma=2`、`LowSigma=0`、`MinBelowSeconds=0.40`、`MergeGapSeconds=0.30`、`DurationSeconds=[5 10 15 20 30]`、`MinAmplitude=0`、`AnalysisSeconds=Inf`。

本包包含之前的绘图入口及统一纵向尺度代码，也可继续运行旧 long/amplitude 入口；本次新增合并导出应运行 `run_combined_calcium_dFF.m`。

MATLAB 验证入口：`test_combined_calcium(true)`，包含原 duration 边界、已知指数半衰减、缺失数据、下一事件截断、两种末尾事件、无事件/无效细胞、同鼠多记录、组内细胞数、重复/失败记录及 MAT/Excel 读写回读。测试会在临时目录保留示例结果。

交付时本机没有可用 MATLAB/Octave 执行环境；静态检查与独立数值参考结果见 VALIDATION_combined.json。MATLAB 集成测试已提供，但不冒充已执行。
