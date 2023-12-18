# Check the number of arguments
if (length(commandArgs(trailingOnly = TRUE)) != 1) {
  stop("Usage: latency_perf.R \"<path/to/latency.csv>\"")
}

# Save the argument in a variable
argument <- commandArgs(trailingOnly = TRUE)[1]

# Load the ggplot2 package
library(ggplot2)

# Read the latency data from the csv file
latency_data <- read.csv(argument, sep = ';')

# Réorganisez les données pour les mettre dans un format long
data_long <- tidyr::gather(latency_data, key = "Measurement", value = "Value", -block_size)

# Convertissez les colonnes pertinentes en numérique
data_long$Value <- as.numeric(as.character(data_long$Value))

# Créez un boxplot
boxplot_plot <- ggplot(data_long, aes(x = as.factor(block_size), y = Value, fill = Measurement)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Boxplot des temps de latence", x = "Taille de bloc", y = "Temps de latence (ms)", fill = "Mesure")

# Affichez le graphique
dir <- dirname(argument)
# Save the plot as a png file
ggsave(paste0(dir, "/nfs_latency_boxplot_.png"), boxplot_plot, width = 6, height = 3)

