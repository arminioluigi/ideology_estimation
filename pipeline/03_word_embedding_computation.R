# Extracting links and processing embeddings from user-generated content

# Load required libraries
library(stringr)
library(tidyverse)
library(CooRnet)
library(dplyr)
library(readr)
library(googleLanguageR)
library("httr2")
library("Rtsne")
library("sf")
library("igraph")
library("ggplot2")
library("visNetwork")
library("ggridges")

###*
###*___1 - DATA LOADING___
###*

###* 1.1 Load page descriptions and posts (with translations)
descwithtrans <- read.csv("descriptions_with_translation.csv")
postswithtrans <- read.csv("posts_messages_embedding_nonagg.csv")

# Optional: Sampling users for testing purposes
# sample_account_names <- sample(descwithtrans$account.name, 7)
# filtered_descwithtrans <- descwithtrans %>%
#   filter(account.name %in% sample_account_names)
# filtered_postswithtrans <- postswithtrans %>%
#   filter(account.name %in% sample_account_names)

filtered_descwithtrans <- descwithtrans
filtered_postswithtrans <- postswithtrans

###* 1.2 Remove duplicate combinations of account and text

# For post messages
filtered_postswithtrans_unique <- unique(filtered_postswithtrans[c("account.platformId", "account.name", "message_translated")])
filtered_postswithtrans_unique <- filtered_postswithtrans %>%
  semi_join(filtered_postswithtrans_unique, by = c("account.platformId", "message_translated"))

# For page descriptions
filtered_descwithtrans_unique <- unique(filtered_descwithtrans[c("account.platformId", "account.name", "account.pageDescription")])
filtered_descwithtrans_unique <- filtered_descwithtrans %>%
  semi_join(filtered_descwithtrans_unique, by = c("account.platformId", "account.name", "account.pageDescription"))

# Change working directory
setwd("C:/Users/luia/Documents/AFTER_SUMMER/OUTPUT/emb_output")

###*___2 WORD EMBEDDINGS___

# 2.1 - Embedding for page descriptions
entities_embedding <- filtered_descwithtrans_unique
for (j in 1:nrow(entities_embedding)) {
  req <- request("https://api.openai.com/v1/embeddings")

  resp <- req %>%
    req_auth_bearer_token("sk-...") %>%
    req_body_json(list(input = entities_embedding$account.pageDescription_translated[j], model = "text-embedding-ada-002")) %>%
    req_perform()

  a <- resp %>% resp_body_json(simplifyVector = TRUE)
  entities_embedding$ada_embedding[j] <- a$data$embedding

  rm(req, resp, a)
  print(paste0(c(j,"of",nrow(entities_embedding))))
  Sys.sleep(.5)
}

# Save the resulting description embeddings
descriptions_embeddings <- entities_embedding
saveRDS(descriptions_embeddings,"descriptions_embeddings.rds")

# Dimensionality reduction using t-SNE
entities_embedding <- descriptions_embeddings
dimensions = 1
matrix <- t(do.call("cbind", entities_embedding$ada_embedding))
tsne_result <- Rtsne(matrix, dims = dimensions, perplexity = 10, seed = 42,
                     check_duplicates = F, max_iter = 1000, theta = 0,
                     verbose = TRUE, early_exaggeration = 4, learning_rate = 200)
vis_dims <- tsne_result$Y

row.names(matrix) <- entities_embedding$account.name

# Create a 1D coordinate data frame from embeddings
coordinates <- data.frame(name = rownames(matrix), score = vis_dims[, 1])
saveRDS(coordinates,"1dim_descriptions_coordinates.rds")
write.csv(coordinates,"descriptions_coordinates.csv")

# 2.2 - Embedding for posts
entities_embedding <- filtered_postswithtrans_unique

for (j in 1:nrow(entities_embedding)) {
  success <- FALSE
  while (!success) {
    tryCatch({
      req <- request("https://api.openai.com/v1/embeddings")
      resp <- req %>%
        req_auth_bearer_token("sk-...") %>%
        req_body_json(list(input = entities_embedding$message_translated[j], model = "text-embedding-ada-002")) %>%
        req_perform()

      a <- resp %>% resp_body_json(simplifyVector = TRUE)
      entities_embedding$ada_embedding[j] <- a$data$embedding

      rm(req, resp, a)
      print(paste0(c(j, "of", nrow(entities_embedding)), collapse = " "))
      success <- TRUE
    }, error = function(e) {
      cat("Error occurred. Retrying...\n")
      Sys.sleep(0.5)
    })
  }
}

# Save the resulting message embeddings
messages_embeddings <- entities_embedding
saveRDS(messages_embeddings, "messages_embeddings.rds")

# Dimensionality reduction using t-SNE
entities_embedding <- messages_embeddings
matrix <- t(do.call("cbind", entities_embedding$ada_embedding))
tsne_result <- Rtsne(matrix, dims = dimensions, perplexity = 10, seed = 42,
                     check_duplicates = F, max_iter = 1000, theta = 0,
                     verbose = TRUE, early_exaggeration = 4, learning_rate = 200)
vis_dims <- tsne_result$Y

row.names(matrix) <- entities_embedding$account.name

# Create a 1D coordinate data frame from embeddings
coordinates <- data.frame(name = rownames(matrix), score = vis_dims[, 1])
saveRDS(coordinates,"1dim_messages_coordinates.rds")
write.csv(coordinates,"posts_coordinates.csv")
