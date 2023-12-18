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

# Plot the (read / write) latency average vs block size
wr_plot <- ggplot(latency_data, aes(x = block_size)) +
  geom_line(aes(y = write_latency_average, color = "Write_AV"), linetype = "solid") +
  geom_point(size = 0.25, aes(y = write_latency_1, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_2, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_3, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_4, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_5, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_6, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_7, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_8, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_9, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_10, color = "Write")) +
  geom_point(size = 0.25, aes(y = write_latency_average, color = "Write_AV")) +
  geom_line(aes(y = read_latency_average, color = "Read_AV"), linetype = "solid") +
  geom_point(size = 0.25, aes(y = read_latency_1, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_2, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_3, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_4, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_5, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_6, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_7, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_8, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_9, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_10, color = "Read")) +
  geom_point(size = 0.25, aes(y = read_latency_average, color = "Read_AV")) +
  scale_x_continuous(breaks = unique(latency_data$block_size)) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 6)) +
  labs(title = "Write and Read Latency Average vs Block Size",
       x = "Block Size (bytes)",
       y = "Latency Average (s)") +
  theme(axis.text.x = element_text(size = 6),
      axis.text.y = element_text(size = 6),
      legend.text = element_text(size = 6),
      plot.title = element_text(size = 8),
      legend.title = element_text(size = 8),
      axis.title.x = element_text(size = 8),
      axis.title.y = element_text(size = 8)) +
  scale_color_manual(name = "Legend", values = c("Write" = "blue", "Read" = "red", "Write_AV" = "blue4", "Read_AV" = "red4")) 

dir <- dirname(argument)
# Save the plot as a png file
ggsave(paste0(dir, "/nfs_latency_plot_detailled.png"), wr_plot, width = 6, height = 3)

