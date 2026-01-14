# ==============================================================================
# Alfalfa Pedigree Network - Publication Ready Version (igraph)
# ==============================================================================

# 1. 加载必要的包 --------------------------------------------------------------
if (!requireNamespace("igraph", quietly = TRUE)) install.packages("igraph")
if (!requireNamespace("scales", quietly = TRUE)) install.packages("scales") # 用于坐标拉伸
library(igraph)
library(dplyr)
library(stringr)
library(scales)

# 2. 数据加载与深度清洗 --------------------------------------------------------
if (!exists("ped_data")) stop("错误：请先加载数据到变量 'ped_data'")

# 创建输出目录
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
out_dir <- paste0("Pedigree_Pub_", timestamp)
dir.create(out_dir)

df <- ped_data

# 统一列名
expected_cols <- c("ID", "Father", "Mother", "Generation", "Cross_Code", "Name")
if(ncol(df) >= 6) colnames(df)[1:6] <- expected_cols

# 清洗函数：去空格，转NA
clean_val <- function(x) {
  x <- as.character(x)
  x <- str_trim(x)
  x[x %in% c("Unknown", "unknown", "", " ", "NA", NA)] <- NA
  return(x)
}

df$ID     <- clean_val(df$ID)
df$Father <- clean_val(df$Father)
df$Mother <- clean_val(df$Mother)
df$Name   <- clean_val(df$Name)

# 移除空行
df <- df[!is.na(df$ID) & df$ID != "", ]

# 3. 构建节点与边 (Nodes & Edges) ----------------------------------------------
message("正在构建系谱网络...")

# (A) 节点表 (Nodes) - 包含所有出现的个体
all_ids <- unique(c(df$ID, na.omit(df$Father), na.omit(df$Mother)))
nodes <- data.frame(id = all_ids, stringsAsFactors = FALSE)

# 关联属性 (Name, Cross_Code)
# 注意：使用 left_join 确保 ID 匹配
nodes <- nodes %>%
  left_join(df %>% select(ID, Name, Cross_Code), by = c("id" = "ID"))

# (B) 关键：标签逻辑 (Label Logic)
# 优先用 Name，如果没有 Name (比如自动补全的祖先)，则尝试用 ID
# 再次清洗 Name，防止全是空格的情况
nodes$Name <- clean_val(nodes$Name)
nodes$Label <- ifelse(!is.na(nodes$Name), nodes$Name, nodes$id)

# 缺失的 Cross_Code 默认为 GP (基础亲本)
nodes$Cross_Code[is.na(nodes$Cross_Code)] <- "GP"

# (C) 边表 (Edges)
edges_father <- df %>% filter(!is.na(Father)) %>% select(Father, ID) %>% rename(from=Father, to=ID)
edges_mother <- df %>% filter(!is.na(Mother)) %>% select(Mother, ID) %>% rename(from=Mother, to=ID)
edges <- rbind(edges_father, edges_mother)

# 4. 创建图对象 (Graph Object) -------------------------------------------------
g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)

# 5. 样式设置 (Aesthetics for Publication) -------------------------------------

# (A) 颜色方案 (低饱和度，适合阅读)
color_map <- c(
  "GP" = "#E6AB02", # 赭黄 (基础)
  "IC" = "#66A61E", # 绿色 (系内)
  "BC" = "#7570B3", # 紫色 (回交)
  "SF" = "#E7298A", # 玫红 (自交)
  "OC" = "#A6761D"  # 褐色 (开放)
)
# 匹配颜色
V(g)$color <- color_map[V(g)$Cross_Code]
V(g)$color[is.na(V(g)$color)] <- "grey80" # 未知类型用浅灰

# (B) 节点样式 (微型化)
V(g)$frame.color <- NA         # 去除节点黑边，更清爽
V(g)$size <- 5                 # 【关键】节点调小 (原15 -> 5)

# (C) 标签样式 (Name)
V(g)$label <- V(g)$Label       # 确保显示 Name
V(g)$label.family <- "sans"    # 无衬线字体
V(g)$label.color <- "black"    # 黑色文字
# 动态字体大小：如果节点多，字体就小一点
font_size <- if(length(V(g)) > 50) 0.5 else 0.7
V(g)$label.cex <- font_size    
V(g)$label.dist <- 0.6         # 标签稍微偏离节点中心，防止盖住颜色点

# (D) 连线样式
E(g)$arrow.size <- 0.2         # 箭头极其微小，暗示方向即可
E(g)$edge.color <- "grey60"    # 浅灰色连线，不抢眼
E(g)$width <- 0.5              # 细线

# 6. 布局算法优化 (Layout Optimization) ----------------------------------------
message("正在计算优化布局...")

# 使用 Sugiyama 算法 (分层布局)
lay_obj <- layout_with_sugiyama(g, attributes = "all")
lay <- lay_obj$layout

# 【关键优化】: 拉伸布局以减少拥挤
# Sugiyama 默认通常是垂直很长，水平很窄。我们需要横向拉开。
# 旋转布局：通常 Sugiyama 是从上到下。
# 我们可以手动缩放坐标轴
lay[, 1] <- rescale(lay[, 1], to = c(-1, 1)) * 2  # 横向拉宽 2 倍
lay[, 2] <- rescale(lay[, 2], to = c(1, -1))      # 纵向归一化 (注意：1到-1是为了让祖先在上面)

# 7. 绘图与导出 ----------------------------------------------------------------
pdf_file <- file.path(out_dir, "Alfalfa_Pedigree_Pub.pdf")

message("正在导出...")

# 设置 PDF 画布：宽长高短，适合宽系谱图
# 如果觉得依然拥挤，可以尝试增加 width
pdf(pdf_file, width = 12, height = 8)

# 绘图
plot(g, 
     layout = lay, 
     # 调整边界，利用每一寸空间
     rescale = FALSE,  # 关闭自动缩放，使用我们自定义的拉伸坐标
     xlim = range(lay[,1]), 
     ylim = range(lay[,2]),
     margin = c(0,0,0,0), # 无边距
     main = "" # 去除标题，留给论文排版
)

# 添加图例 (精简版)
legend("topleft", 
       legend = names(color_map), 
       col = color_map, 
       pch = 19,       # 实心圆点
       pt.cex = 1.2, 
       bty = "n",      # 无边框
       cex = 0.8,
       title = "Breeding Type",
       inset = c(0.02, 0.02)
)

dev.off()

message(paste("出版级矢量图已生成:", pdf_file))
message("提示：如果依然觉得拥挤，请在代码中增加 'pdf(..., width = 15)' 的宽度值。")
