# Vérifier si le package ggplot2 est installé
if (!requireNamespace("ggplot2")) {
  # Installer le package ggplot2
  install.packages("ggplot2")
}
# Charger la bibliothèque ggplot2
library(ggplot2)

# Lire les données à partir du fichier CSV
latency_data <- read.csv("latency.csv", sep = ';')

wr_plot <- ggplot(latency_data, aes(x = block_size)) +
  geom_line(aes(y = write_latency_average, color = "Write"), linetype = "solid") +
  geom_point(aes(y = write_latency_average, color = "Write")) +
  geom_line(aes(y = read_latency_average, color = "Read"), linetype = "solid") +
  geom_point(aes(y = read_latency_average, color = "Read")) +
  labs(title = "Write and Read Latency Average vs Block Size",
       x = "Block Size (bytes)",
       y = "Latency Average (s)") +
  scale_color_manual(name = "Legend", values = c("Write" = "blue", "Read" = "red")) 
  
# Enregistrer le graphique
ggsave("write_and_read_latency_plot.png", wr_plot, width = 12, height = 6)
