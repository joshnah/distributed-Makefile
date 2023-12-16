# # Vérifier si le package ggplot2 est installé
# if (!requireNamespace("ggplot2")) {
#   # Installer le package ggplot2
#   install.packages("ggplot2")
# }
# Charger la bibliothèque ggplot2
library(ggplot2)

# Lire les données à partir du fichier CSV
latency_data <- read.csv("latency_3.csv", sep = ';')

# Tracer la courbe de latence moyenne en écriture
write_plot <- ggplot(latency_data, aes(x = block_size, y = write_latency_average)) +
  geom_line(color = "blue") +
  geom_point(color = "blue") +
  labs(title = "Write Latency Average vs Block Size",
       x = "Block Size (bytes)",
       y = "Write Latency Average (s)")

# Tracer la courbe de latence moyenne en lecture
read_plot <- ggplot(latency_data, aes(x = block_size, y = read_latency_average)) +
  geom_line(color = "red") +
  geom_point(color = "red") +
  labs(title = "Read Latency Average vs Block Size",
       x = "Block Size (bytes)",
       y = "Read Latency Average (s)")

# Afficher les deux graphiques côte à côte
library(gridExtra)
wr_plot <- grid.arrange(write_plot, read_plot, ncol = 2)

# Enregistrer le graphique
ggsave("output_plot.png", wr_plot, width = 12, height = 6)
