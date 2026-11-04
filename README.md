# 2024 NTU CVSD Practice

國立臺灣大學 **Computer-Aided VLSI System Design（CVSD）** 的 2024 年課程練習紀錄，包含四份作業與橢圓曲線密碼處理器期末專題。內容涵蓋 Verilog／SystemVerilog RTL、測試平台、邏輯合成，以及部分實體設計與模擬產物。

## 專案內容

| 項目 | 主題 | 主要實作 | 規格 |
| --- | --- | --- | --- |
| HW1 | 定點數算術邏輯單元（ALU） | [alu.v](Homework/1/01_RTL/alu.v) | [作業說明](Homework/1/113-1_HW1_v2.pdf) |
| HW2 | 簡化 RISC-V CPU，含浮點運算相關設計 | [core.v](Homework/2/01_RTL/core.v) | [作業說明](Homework/2/1131_HW2_v2.pdf) |
| HW3 | 卷積與影像處理引擎，含 SRAM、Median／Sobel 等操作 | [core.v](Homework/3/01_RTL/core.v) | [作業說明](Homework/3/1131_hw3_v1.pdf) |
| HW4 | IoT Data Filtering，含 DES、CRC 與資料比較功能 | [IOTDF.v](Homework/4/01_RTL/IOTDF.v) | [作業說明](Homework/4/1131_hw4_v3.pdf) |
| Final | Ed25519 相關橢圓曲線純量乘法運算核心 | [ed25519.sv](Final/01_RTL/ed25519.sv) | [專題說明](Final/1131_final_note_v3.pdf) |

期末專題加速 EdDSA 所使用的橢圓曲線核心運算，並提供 [Python 參考模型](Final/ed25519.py)；介面與運算範圍請以專題規格為準。

## 目錄導覽

```text
.
├── Homework/
│   ├── 1/              # ALU 與測試資料
│   ├── 2/              # CPU 與測試平台
│   ├── 3/              # 影像處理、SRAM 與合成設定
│   └── 4/              # IoT 資料處理與功耗分析設定
└── Final/
    ├── 00_TESTBED/     # 測試平台與 patterns
    ├── 01_RTL/         # RTL 與模擬檔案清單
    ├── 02_SYN/         # Design Compiler 腳本與時序限制
    ├── 03_GATE/        # 閘級模擬設定
    ├── 04_APR/         # 實體設計資料與產物
    ├── 05_POST/        # 佈局後模擬設定
    └── ed25519.py      # 軟體參考模型
```

各作業包含的流程階段不同，請從對應目錄的檔案清單與說明文件開始。

## 環境需求

- Linux／Unix shell，以及可使用的 Synopsys VCS。
- 波形除錯使用 Verdi／FSDB；現有檔案清單引用課程工作站的 PLI 路徑。
- 合成使用 Synopsys Design Compiler；APR 與後續分析需要對應 EDA 工具、標準元件庫與 SRAM 模型。
- Python 3 可用於閱讀與執行軟體參考模型。

`/usr/cad/...` 與 `/home/raid...` 為原課程環境路徑，移至其他工作站時須調整。HW2 的浮點加減法亦引用 DesignWare 模擬模型。

## 快速開始：期末專題 RTL 模擬

先完成課程工具環境設定，再執行：

```bash
git clone https://github.com/SR88888/2024_NTU_CVSD_practice.git
cd 2024_NTU_CVSD_practice/Final/01_RTL

vcs -R -full64 -f rtl_sim.f +define+PAT0
```

- `rtl_sim.f` 指定 RTL、測試平台與模擬選項；相對路徑以 `Final/01_RTL` 為工作目錄。
- 更換 `PAT0` 可選擇其他測試索引，實際可用資料須配合 `00_TESTBED/pattern/tb_dat.sv`。
- [testbed.sv](Final/00_TESTBED/testbed.sv) 另保留 edge、random、combine patterns 的 include 選項；切換時須同步確認資料與測試索引。
- [01_run](Final/01_RTL/01_run) 收錄批次模擬命令。

## 合成與後續流程

期末專題可依 `01_RTL → 02_SYN → 03_GATE → 04_APR → 05_POST` 閱讀。合成腳本位於 [syn.tcl](Final/02_SYN/syn.tcl)，並載入同目錄的時序限制；執行前請確認 library 路徑與工具版本。

repository 中的既有 netlist、報告與 APR 資料是開發紀錄。重新執行後，請以當次測試結果、時序與面積報告評估修改。
