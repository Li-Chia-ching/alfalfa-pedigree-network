# ==============================================================================
# Alfalfa Pedigree Network - Final Optimized Edition
# 核心特征：强制显示Name，超宽布局防拥挤，亲本在顶部
# ==============================================================================

# 1. 加载包 --------------------------------------------------------------------
if (!requireNamespace("igraph", quietly = TRUE)) install.packages("igraph")
if (!requireNamespace("scales", quietly = TRUE)) install.packages("scales")
if (!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr")
library(igraph)
library(dplyr)
library(stringr)
library(scales)

# 2. 数据加载与清洗 ------------------------------------------------------------
if (!exists("ped_data")) stop("错误：请先加载数据到变量 'ped_data'")

# 创建输出目录
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
out_dir <- paste0("Pedigree_FinalPlot_", timestamp)
dir.create(out_dir)

df <- ped_data

# 统一列名
expected_cols <- c("ID", "Father", "Mother", "Generation", "Cross_Code", "Name")
if(ncol(df) >= 6) colnames(df)[1:6] <- expected_cols

# 清洗函数
clean_val <- function(x) {
  x <- as.character(x)
  x <- str_trim(x) # 去空格
  x[x %in% c("Unknown", "unknown", "", " ", "NA", NA)] <- NA
  return(x)
}

df$ID     <- clean_val(df$ID)
df$Father <- clean_val(df$Father)
df$Mother <- clean_val(df$Mother)
df$Name   <- clean_val(df$Name)

# 移除空行
df <- df[!is.na(df$ID) & df$ID != "", ]

# 3. 构建图数据 ----------------------------------------------------------------
message("正在构建系谱网络...")

# (A) 节点表
all_ids <- unique(c(df$ID, na.omit(df$Father), na.omit(df$Mother)))
nodes <- data.frame(id = all_ids, stringsAsFactors = FALSE)
nodes <- nodes %>% left_join(df %>% select(ID, Name, Cross_Code, Generation), by = c("id" = "ID"))

# (B) 标签逻辑 (强制使用 Name)
# 如果 Name 为空，才使用 ID；否则一律使用 Name
nodes$Name <- clean_val(nodes$Name)
nodes$Label <- ifelse(!is.na(nodes$Name), nodes$Name, nodes$id)

# 默认属性填充
nodes$Cross_Code[is.na(nodes$Cross_Code)] <- "GP"

# (C) 代次解析 (用于分层)
# 从 "G0", "G3", "CG1" 中提取数字
extract_gen <- function(x) {
  num <- as.numeric(str_extract(x, "\\d+"))
  if(is.na(num)) return(0) # 无法解析的默认为0
  return(num)
}
# 如果数据中有Generation列，使用它；否则全为0(依赖自动布局)
if("Generation" %in% colnames(nodes)) {
  nodes$Gen_Num <- sapply(nodes$Generation, extract_gen)
} else {
  nodes$Gen_Num <- 0
}

# (D) 边表
edges <- rbind(
  df %>% filter(!is.na(Father)) %>% select(Father, ID) %>% rename(from=Father, to=ID),
  df %>% filter(!is.na(Mother)) %>% select(Mother, ID) %>% rename(from=Mother, to=ID)
)

# 4. 创建图对象 ----------------------------------------------------------------
g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)

# 5. 视觉样式设置 --------------------------------------------------------------

# (A) 颜色 (植物学低饱和度)
color_map <- c(
  "GP" = "#4E79A7", # 基础亲本-蓝
  "IC" = "#59A14F", # 系内-绿
  "BC" = "#E15759", # 回交-红
  "SF" = "#F28E2B", # 自交-橙
  "OC" = "#B07AA1"  # 开放-紫
)
V(g)$color <- color_map[V(g)$Cross_Code]
V(g)$color[is.na(V(g)$color)] <- "grey80"

# (B) 节点 (微型化以防遮挡)
# 根据代次调整大小：G0(亲本)大，子代小
gen_norm <- nodes$Gen_Num - min(nodes$Gen_Num, na.rm=TRUE)
max_gen <- max(gen_norm, na.rm=TRUE)
if(max_gen > 0) {
  # 代次越小(亲本)，节点越大
  V(g)$size <- 5 + (6 * (max_gen - gen_norm) / max_gen)
} else {
  V(g)$size <- 6
}
# 基础亲本特权
V(g)$size[V(g)$Cross_Code == "GP"] <- 10
V(g)$frame.color <- NA # 无边框

# (C) 标签 (关键优化)
V(g)$label <- V(g)$Label
V(g)$label.family <- "sans"
V(g)$label.color <- "black"
# 字体大小：节点越多，字体越小，但有下限
base_cex <- if(length(V(g)) > 100) 0.5 else 0.6
V(g)$label.cex <- base_cex

# 6. 布局计算 (Sugiyama 分层 + 强力拉伸) ---------------------------------------
message("正在计算高清晰度布局...")

# 移除自交环计算布局(防止报错)
g_layout <- simplify(g, remove.multiple = FALSE, remove.loops = TRUE)

# 强制分层参数
lay_params <- list(graph = g_layout, hgap = 5, vgap = 5) # 增加间距参数
if(max_gen > 0) lay_params$layers <- nodes$Gen_Num

lay <- do.call(layout_with_sugiyama, lay_params)
coords <- lay$layout

# (A) 纵向翻转检测 (确保亲本在上)
# 检查代次与Y坐标的相关性。我们希望代次小(0)的Y值大(Top)。
# 如果代次与Y正相关(0在下)，则需要翻转。
if(max_gen > 0) {
  cor_y <- cor(coords[,2], nodes$Gen_Num, use = "complete.obs")
  if(!is.na(cor_y) && cor_y > 0) {
    coords[,2] <- -coords[,2] # 翻转
  }
} else {
  # 无代次信息时，Sugiyama通常把根放在顶部，无需操作
}

# (B) 横向强力拉伸 (解决拥挤的核心)
# 将 X 轴范围扩大到 Y 轴范围的 2-3 倍
ratio <- 2.5 
coords[,1] <- rescale(coords[,1], to = c(-ratio, ratio))
coords[,2] <- rescale(coords[,2], to = c(-1, 1))

# (C) 同代节点交错抖动 (防止重叠)
# 对每一层节点，按X坐标排序，重新均匀分布
if(max_gen > 0) {
  for(g_idx in unique(nodes$Gen_Num)) {
    idx <- which(nodes$Gen_Num == g_idx)
    if(length(idx) > 1) {
      # 获取当前层节点的索引
      layer_nodes <- idx
      # 获取它们当前的X坐标
      current_x <- coords[layer_nodes, 1]
      # 排序
      order_x <- order(current_x)
      # 在区间内均匀重布
      new_x <- seq(min(coords[,1]), max(coords[,1]), length.out = length(layer_nodes) + 2)
      new_x <- new_x[2:(length(new_x)-1)] # 去掉头尾，留边距
      # 赋值
      coords[layer_nodes[order_x], 1] <- new_x
    }
  }
}

# 7. 绘图与导出 ----------------------------------------------------------------
pdf_file <- file.path(out_dir, "Alfalfa_Pedigree_Clean.pdf")

# 自动计算画布宽度：节点越多，画布越宽
plot_width <- max(12, length(unique(nodes$Gen_Num)) * 2) 
if(length(V(g)) > 50) plot_width <- 16

pdf(pdf_file, width = plot_width, height = 10)

# 设置边距
par(mar = c(1, 1, 1, 1))

plot(g,
     layout = coords,
     rescale = FALSE, # 关键：禁止自动压缩
     xlim = range(coords[,1]) * 1.05,
     ylim = range(coords[,2]) * 1.05,
     
     # 标签位置：垂直排列 (竖排) 或者 旋转放置
     # 这里采用：在节点下方垂直放置，互不干扰
     vertex.label.dist = 0.8,    # 标签离节点远一点
     vertex.label.degree = -pi/2, # 纯垂直下方 (-90度方向)
     
     # 连线优化
     edge.arrow.size = 0.3,
     edge.color = "grey70",
     edge.curved = 0.3, # 增加曲线度，绕过中间节点
     
     main = "紫花苜蓿育种系谱图"
)

# 简单的代次指示
min_x <- min(coords[,1])
max_y <- max(coords[,2])
min_y <- min(coords[,2])
text(x = min_x, y = max_y, labels = "Parents (G0)", pos = 4, col = "grey50", cex = 0.8)
text(x = min_x, y = min_y, labels = "Progeny", pos = 4, col = "grey50", cex = 0.8)

# 图例
legend("topright", legend = names(color_map), col = color_map, pch = 19, pt.cex = 1.5, bty = "n", cex = 0.8)

dev.off()

message(paste("优化完成！高清PDF已保存至:", pdf_file))
message("提示：标签已强制设为Name，并位于节点正下方。")
