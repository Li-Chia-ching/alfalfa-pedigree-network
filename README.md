# README: Alfalfa Pedigree Network Visualization Tool

## Overview / 概述

This tool creates publication-ready pedigree network visualizations for alfalfa breeding programs. It generates clean, professional pedigree diagrams that clearly display parent-progeny relationships with minimal label overlap.

该工具为苜蓿育种程序创建可直接用于出版物的亲缘关系网络可视化。它能生成清晰、专业的系谱图，以最小的标签重叠清晰展示亲本-子代关系。

## Key Features / 核心功能

### 1. **Intelligent Label Placement / 智能标签放置**
- **Forces display of `Name` field** (falls back to `ID` only if `Name` is missing)
- **Labels placed directly below nodes** for maximum readability
- **Auto-adjusted font size** based on node count to prevent crowding

- **强制显示`Name`字段**（仅在`Name`缺失时才使用`ID`）
- **标签直接放在节点下方**，确保最佳可读性
- **基于节点数量自动调整字体大小**，防止拥挤

### 2. **Botanical Layout Conventions / 植物学布局规范**
- **Parents at top, progeny at bottom** (Generation values increase downward)
- **Wide horizontal stretching** to maximize label spacing
- **Within-generation node alignment** to create organized layers

- **亲本在上，子代在下**（代次值向下递增）
- **大幅水平拉伸**以最大化标签间距
- **同代次节点对齐**，形成有组织的层级

### 3. **Visual Design / 视觉设计**
- **Low-saturation botanical color scheme** suitable for publication
- **Node size indicates generation** (founders/larger, recent generations/smaller)
- **Clean lines with minimal visual clutter**

- **适合出版物的低饱和度植物学配色方案**
- **节点大小表示代次**（基础亲本较大，近期代次较小）
- **简洁线条，视觉干扰最小化**

## Data Requirements / 数据要求

### Required Columns / 必需列
- **`ID`**: Unique identifier for each individual
- **`Father`**: ID of the male parent (use `NA` for unknown)
- **`Mother`**: ID of the female parent (use `NA` for unknown)
- **`Generation`**: Generation number (e.g., "G0", "G1", "G2")
- **`Cross_Code`**: Breeding type code (GP, IC, BC, SF, OC)
- **`Name`**: Display name for each individual

### Data Cleaning / 数据清洗
The script automatically:
- Removes whitespace and standardizes missing values
- Handles "Unknown" and similar placeholders
- Ensures all parents are included as nodes even if not in original data

脚本自动：
- 删除空格并标准化缺失值
- 处理"Unknown"及类似占位符
- 确保所有亲本都作为节点包含，即使未出现在原始数据中

## Installation & Usage / 安装与使用

### 1. Load Required Packages / 加载必需包
```r
# Install if not already installed
install.packages(c("igraph", "dplyr", "stringr", "scales"))

# Load libraries
library(igraph)
library(dplyr)
library(stringr)
library(scales)
```

### 2. Prepare Your Data / 准备数据
```r
# Load your pedigree data
ped_data <- read.csv("your_pedigree_file.csv")  # or read.xlsx, etc.

# Ensure column names match expected format:
# Expected columns: ID, Father, Mother, Generation, Cross_Code, Name
```

### 3. Run the Script / 运行脚本
```r
# Source the script
source("alfalfa_pedigree_network.R")

# Or copy the entire script into your R session
```

## Output Files / 输出文件

The script generates two files in a timestamped directory:

脚本在带时间戳的目录中生成两个文件：

1. **`Alfalfa_Pedigree_Clean.pdf`** - High-resolution vector PDF for publication
   - **高分辨率矢量PDF文件**，适用于出版物

2. **Directory naming convention**: `Pedigree_FinalPlot_YYYYMMDD_HHMMSS/`
   - **目录命名规则**: `Pedigree_FinalPlot_年月日_时分秒/`

## Customization Options / 自定义选项

### Color Scheme / 配色方案
```r
# Modify the color_map variable to change colors:
color_map <- c(
  "GP" = "#4E79A7", # Foundation parents / 基础亲本
  "IC" = "#59A14F", # Inbred crosses / 系内杂交
  "BC" = "#E15759", # Backcrosses / 回交
  "SF" = "#F28E2B", # Selfing / 自交
  "OC" = "#B07AA1"  # Open crosses / 开放杂交
)
```

### Layout Adjustments / 布局调整
```r
# Adjust horizontal stretching (higher = more spread out)
ratio <- 2.5  # Current value / 当前值

# Modify node sizing formula:
V(g)$size <- 5 + (6 * (max_gen - gen_norm) / max_gen)
```

### Label Configuration / 标签配置
```r
# Change label positioning:
vertex.label.dist = 0.8,    # Distance from node / 标签与节点的距离
vertex.label.degree = -pi/2 # Label angle / 标签角度 (-90° = below)
```

## Troubleshooting / 故障排除

### Common Issues / 常见问题

| Issue / 问题 | Solution / 解决方案 |
|--------------|---------------------|
| **"Error: please load data to variable 'ped_data'"** | Ensure your data is loaded and named exactly `ped_data` |
| **Labels still overlapping** | Increase `plot_width` (currently auto-calculated) or decrease `base_cex` |
| **Graph looks too compressed** | Increase the `ratio` parameter in the layout stretching section |
| **Missing parents in visualization** | Check that parent IDs match exactly with child's Father/Mother values |
| **颜色显示不正确** | 检查Cross_Code列是否包含GP, IC, BC, SF, OC之外的值 |

## Advanced Features / 高级功能

### Generation Extraction / 代次提取
The script automatically extracts generation numbers from various formats:
- "G0", "G1", "G2" → 0, 1, 2
- "CG1", "CG2" → 1, 2
- Any string containing numbers

脚本自动从各种格式中提取代次数字：
- "G0", "G1", "G2" → 0, 1, 2
- "CG1", "CG2" → 1, 2
- 任何包含数字的字符串

### Intelligent Node Sizing / 智能节点大小调整
- Foundation parents (GP): Largest nodes (size = 10)
- Early generations: Medium-sized nodes
- Recent generations: Smaller nodes (minimum size = 5)

- 基础亲本(GP): 最大节点 (大小 = 10)
- 早期代次: 中等大小节点
- 近期代次: 较小节点 (最小大小 = 5)

## Example Output / 示例输出

A successful run will produce:
- A clean pedigree network with parents at the top
- All individuals labeled by their `Name` field
- Color-coded by breeding type
- Organized in generational layers

成功运行将生成：
- 亲本在顶部的清晰系谱网络
- 所有个体按其`Name`字段标记
- 按育种类型颜色编码
- 按代次层级组织

## Citation / 引用

If you use this tool in your research, please cite:
- **Tool**: "Alfalfa Pedigree Network Visualization Tool"
- **R packages**: Csardi & Nepusz (2006) for igraph; Wickham et al. (2023) for dplyr

如果您在研究中使用此工具，请引用：
- **工具**: "苜蓿系谱网络可视化工具"
- **R包**: Csardi & Nepusz (2006) 的igraph; Wickham et al. (2023) 的dplyr

## Contact & Support / 联系与支持

For questions, suggestions, or bug reports:
- Check the script comments for parameter explanations
- Review the data format requirements above
- Ensure all required columns are present and properly formatted

如有问题、建议或错误报告：
- 查看脚本注释中的参数解释
- 检查上述数据格式要求
- 确保所有必需列都存在且格式正确

---

**Last Updated**: 2025  
**Version**: Final Optimized Edition  
**Compatibility**: R 4.5.2, Windows/macOS/Linux
