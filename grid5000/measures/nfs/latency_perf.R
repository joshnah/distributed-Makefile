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
  geom_line(aes(y = write_latency_average, color = "Write"), linetype = "solid") +
  geom_point(aes(y = write_latency_average, color = "Write")) +
  geom_line(aes(y = read_latency_average, color = "Read"), linetype = "solid") +
  geom_point(aes(y = read_latency_average, color = "Read")) +
  labs(title = "Write and Read Latency Average vs Block Size",
       x = "Block Size (bytes)",
       y = "Latency Average (s)") +
  scale_color_manual(name = "Legend", values = c("Write" = "blue", "Read" = "red")) 

dir <- dirname(argument)
# Save the plot as a png file
ggsave(dir+"/nfs_latency_plot.png", wr_plot, width = 12, height = 6)
