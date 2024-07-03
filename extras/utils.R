# Simplify lock file

library(jsonlite)

# Read the JSON file
json_file <- "renv.lock"
json_data <- fromJSON(here::here(json_file))

# Function to remove specific keys from a list
remove_keys <- function(lst, keys_to_remove) {
  lst[keys_to_remove] <- NULL
  return(lst)
}

# Specify the keys to remove
keys_to_remove <- c("Hash", "Requirements", "RemoteSha", "Remotes")

# Loop through each package and remove the specified keys
json_data$Packages <- lapply(json_data$Packages, function(package) {
  remove_keys(package, keys_to_remove)
})

# Convert the modified data back to JSON
modified_json <- toJSON(json_data, pretty = TRUE, auto_unbox = TRUE)

# Save the modified JSON to a file
write(modified_json, here::here("renv.lock"))
