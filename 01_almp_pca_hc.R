# ===========================================================================
# EUI Workshop, 4 May 2026 — Hands-on
# PCA and hierarchical cluster modelling on the European ALMP policy mix
# Lukas Lehner, University of Edinburgh
# ===========================================================================
#
# Data: spending shares (% of total active labour market policy spending)
# across six ALMP categories for 28 European countries, averaged over
# 2018-2022. Source: OECD Labour Market Programmes database (DSD_LMP@DF_LMP),
# pulled via the OECD SDMX API. Re-run 00_fetch_oecd_lmp.R to refresh the CSV.
#
# Workflow: standardise -> PCA -> hierarchical clustering on PC scores.
# ---------------------------------------------------------------------------

# ---- 0. Packages -----------------------------------------------------------

# install.packages(c("tidyverse", "factoextra", "cluster"))
library(tidyverse)
library(factoextra)
library(cluster)

# ---- 1. Load data ----------------------------------------------------------

df <- read_csv("almp_data.csv")

# Move country codes to row names so PCA/clustering use them as labels
df_mat <- df |>
  column_to_rownames("country")

head(df_mat)
summary(df_mat)

# ---- 2. Standardise --------------------------------------------------------

X <- scale(df_mat)

# ---- 3. PCA ----------------------------------------------------------------

pca <- prcomp(X)
summary(pca)

# Scree plot — how many PCs to keep?
fviz_eig(pca, addlabels = TRUE) +
  labs(title = "Variance explained by PC")

# Biplot — countries and variable loadings together
fviz_pca_biplot(
  pca,
  repel       = TRUE,
  col.var     = "steelblue",
  col.ind     = "grey30",
  labelsize   = 3
) +
  labs(title = "PCA biplot — ALMP policy mix")

# Loadings as a table
round(pca$rotation[, 1:3], 2)

# Keep first three components for clustering
scores <- pca$x[, 1:3]

# ---- 4. Hierarchical clustering on PC scores -------------------------------

d  <- dist(scores, method = "euclidean")
hc <- hclust(d, method = "complete")  # try also "ward.D2", "average"

fviz_dend(
  hc,
  k         = 4,
  rect      = TRUE,
  cex       = 0.7,
  k_colors  = c("#1b9e77", "#d95f02", "#7570b3", "#e7298a"),
  main      = "Dendrogram — complete linkage on PC1–PC3"
)

clusters_hc <- cutree(hc, k = 4)
table(clusters_hc)

# ---- 5. Visualise the partition in PC space --------------------------------

cluster_df <- tibble(
  country = rownames(scores),
  PC1     = scores[, 1],
  PC2     = scores[, 2],
  cluster = factor(clusters_hc)
)

ggplot(cluster_df, aes(PC1, PC2, colour = cluster, label = country)) +
  geom_point(size = 3) +
  geom_text(vjust = -0.8, size = 3, show.legend = FALSE) +
  scale_colour_brewer(palette = "Dark2") +
  theme_minimal() +
  labs(title = "ALMP typology in PC1–PC2 space")

# ---- 6. Cluster means — what does each cluster look like? -----------------

cluster_means <- df_mat |>
  rownames_to_column("country") |>
  mutate(cluster = factor(clusters_hc)) |>
  pivot_longer(-c(country, cluster), names_to = "category", values_to = "share") |>
  group_by(cluster, category) |>
  summarise(mean_share = mean(share), .groups = "drop")

ggplot(cluster_means, aes(category, mean_share, fill = cluster)) +
  geom_col(position = "dodge") +
  scale_fill_brewer(palette = "Dark2") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Mean ALMP spending share, by cluster",
       x = NULL, y = "% of total ALMP spending")

# ===========================================================================
# Bonus tasks (last 10 minutes)
# ---------------------------------------------------------------------------
# 1. Re-run hclust() with method = "ward.D2". Does the partition change?
# 2. Try k = 3 and k = 5 with cutree(). Which is more interpretable?
# 3. Re-run prcomp() with scale. = FALSE (no standardisation). Which variable
#    now dominates PC1, and why?
# 4. Drop one country (e.g. NOR) and re-run end-to-end. How stable is the
#    typology?
# ===========================================================================
