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
  geom_point(size = 0.25, aes(y = w_lat_1, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_2, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_3, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_4, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_5, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_6, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_7, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_8, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_9, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_10, color = "Write")) +
  geom_point(size = 0.25, aes(y = w_lat_med, color = "Write_Med")) +
  geom_point(size = 0.25, aes(y = w_lat_min, color = "Write_Min")) +
  geom_point(size = 0.25, aes(y = w_lat_max, color = "Write_Max")) +
  geom_line(aes(y = w_lat_med, color = "Write_Med"), linetype = "solid") +
  geom_line(aes(y = w_lat_min, color = "Write_Min"), linetype = "solid") +
  geom_line(aes(y = w_lat_max, color = "Write_Max"), linetype = "solid") +
  geom_point(size = 0.25, aes(y = r_lat_1, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_2, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_3, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_4, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_5, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_6, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_7, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_8, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_9, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_10, color = "Read")) +
  geom_point(size = 0.25, aes(y = r_lat_med, color = "Read_Med")) +
  geom_point(size = 0.25, aes(y = r_lat_min, color = "Read_Min")) +
  geom_point(size = 0.25, aes(y = r_lat_max, color = "Read_Max")) +
  geom_line(aes(y = r_lat_med, color = "Read_Med"), linetype = "solid") +
  geom_line(aes(y = r_lat_min, color = "Read_Min"), linetype = "solid") +
  geom_line(aes(y = r_lat_max, color = "Read_Max"), linetype = "solid") +
  geom_line(aes(y = r_lat_med, color = "Read_Med"), linetype = "solid") +
	scale_x_continuous(breaks = unique(latency_data$block_size)) +
  scale_y_continuous(breaks = c(unique(latency_data$read_mediane), unique(latency_data$write_mediane))) +
  labs(title = "Write and Read Latency vs Block Size",
       x = "Block Size (bytes)",
       y = "Latency Mediane (s)") +
  theme(axis.text.x = element_text(size = 6),
      axis.text.y = element_text(size = 6),
      legend.text = element_text(size = 6),
      plot.title = element_text(size = 8),
      legend.title = element_text(size = 8),
      axis.title.x = element_text(size = 8),
      axis.title.y = element_text(size = 8)) +
  scale_color_manual(name = "Legend", values = c("Write" = "blue", "Read" = "red", "Write_Med" = "blue4", "Read_Med" = "red4","Write_Min" = "lightskyblue", "Read_Min" = "indianred1","Write_Max" = "royalblue4", "Read_Max" = "indianred4")) 

dir <- dirname(argument)
# Save the plot as a png file
ggsave(paste0(dir, "/nfs_latency_plot_med.png"), wr_plot, width = 6, height = 3)

