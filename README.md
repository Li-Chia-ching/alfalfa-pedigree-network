# Alfalfa Pedigree Network Visualization

A modern, publication‑ready R pipeline for generating clean and informative pedigree network diagrams from alfalfa breeding data. Built with `igraph`, this tool transforms tabular pedigree records into a structured, visually refined directed graph optimized for academic papers and presentations.

**苜蓿系譜網絡可視化 – 出版級繪圖工具 (igraph)**

本儲存庫提供了一個 R 腳本管道，用於為苜蓿育種計畫生成清晰、符合出版品質的系譜網絡圖。基於 `igraph` 構建，該腳本將原始系譜資料（ID、父本、母本、世代、雜交代碼、名稱）轉換為有向圖，應用適合學術論文的精緻視覺風格，並輸出高解析度 PDF。

## Features

- **Automated Data Preparation**: Cleans raw pedigree data, handles missing parents, and standardizes columns.
- **Intelligent Labeling**: Displays cultivar names when available; uses IDs for unnamed ancestors.
- **Breeding‑Type Visual Encoding**: Distinct, low‑saturation colors for different cross types (GP, IC, BC, SF, OC).
- **Optimized Layout**: Uses the Sugiyama layered algorithm with axis stretching to reduce node overlap and improve readability.
- **Publication‑Ready Styling**:
  - Minimalist design: tiny nodes, thin edges, subtle arrows.
  - Adjustable label size based on graph density.
  - Sans‑serif fonts, black labels, no frame borders.
- **Self‑Contained Output**: Each run creates a timestamped folder with a high‑resolution PDF.

主要功能包括：
- **自動化資料清洗**：處理缺失/未知親本、去除空格、統一欄位名稱。
- **智能標籤**：優先使用「名稱」欄位，無名稱的祖先則以 ID 顯示。
- **育種類型顏色編碼**：可自訂的低飽和度配色，對應不同的雜交代碼（GP、IC、BC、SF、OC）。
- **優化佈局**：採用 Sugiyama 分層演算法，拉伸座標以減少節點擁擠、提升可讀性。
- **出版級樣式**：微小節點、細微箭頭、淺灰色連線、無襯線字體標籤及精簡圖例。
- **獨立輸出**：每次執行會建立帶時間戳記的資料夾，存放生成的 PDF。

本程式碼注重清晰度與可重現性，特別適合需要將複雜系譜關係可視化，並符合期刊投稿圖表格式的植物育種家與遺傳學研究人員使用。

## Dependencies

The script requires the following R packages:

| Package | Purpose | Installation |
|---------|---------|--------------|
| [`igraph`](https://igraph.org/r/) | Graph construction, layout algorithms, and visualization core. | `install.packages("igraph")` |
| [`dplyr`](https://dplyr.tidyverse.org/) | Data manipulation and joining for node/edge tables. | `install.packages("dplyr")` |
| [`stringr`](https://stringr.tidyverse.org/) | String cleaning and whitespace trimming. | `install.packages("stringr")` |
| [`scales`](https://scales.r-lib.org/) | Axis rescaling to stretch the layout for better spacing. | `install.packages("scales")` |

All packages are available on CRAN.

## Quick Start

1. **Prepare your data** as a dataframe (`ped_data`) with at least these columns (order‑sensitive):
   - `ID`, `Father`, `Mother`, `Generation`, `Cross_Code`, `Name`

2. **Run the script**:
   ```r
   source("alfalfa_pedigree_pub.R")
   ```

3. **Find the output** inside a newly created folder named `Pedigree_Pub_YYYYMMDD_HHMMSS/` containing `Alfalfa_Pedigree_Pub.pdf`.

## Customization

- **Colors**: Modify the `color_map` vector in section 5(A) to change breeding‑type colors.
- **Node size**: Adjust `V(g)$size` (currently 5).
- **PDF dimensions**: Change `width` and `height` in the `pdf()` call (currently 12×8 inches).
- **Layout stretching**: Tweak the multiplier in `lay[, 1] <- rescale(...) * 2` to control horizontal spread.

## Notes

- The script assumes your data is loaded into a variable named `ped_data`. Modify the loading step if needed.
- If the graph remains crowded, increase the `width` argument in the `pdf()` function (e.g., `width = 15`).
- The output PDF is vector‑based and can be directly imported into illustration software (Adobe Illustrator, Inkscape) for further refinements.

## License

MIT License. Feel free to adapt for other crops or pedigree structures.
