#Setting directory
setwd("C:/Users/luia/Documents/AFTER_SUMMER/OUTPUT/emb_output")

#loading data about posts
embeddings_posts <- readRDS("messages_embeddings.rds")




#Building a df of multidimensional embeddings per post
#Transforming embeddings_posts$ada_embedding in a dataframe
embedding_df <- data.frame(do.call(rbind, embeddings_posts$ada_embedding))

# Rename the columns if needed
colnames(embedding_df) <- paste0("embedding_", 1:ncol(embedding_df))

# Display the resulting data frame (sample of it)
View(embedding_df[1:4,])
#adding account name column
embedding_df$account_name <- embeddings_posts$account.name

embedding_df$account_platformId <- embeddings_posts$account.platformId

#saving the resulting data frame as a file
# Save the data frame as a CSV file
write.csv(embedding_df, file = "embeddings_per_post.csv", row.names = FALSE)



#loading data about descriptions
embeddings_descriptions <- readRDS("descriptions_embeddings.rds")

# Transforming embeddings_descriptions$bert_embedding into a dataframe
embedding_desc_df <- data.frame(do.call(rbind, embeddings_descriptions$ada_embedding))

# Rename the columns for clarity
colnames(embedding_desc_df) <- paste0("embedding_", 1:ncol(embedding_desc_df))

# Display the resulting data frame (sample of it)
View(embedding_desc_df[1:4,])

# Adding additional columns for descriptive metadata
embedding_desc_df$account_name <- embeddings_descriptions$account.name
embedding_desc_df$account_platformId <- embeddings_descriptions$account.platformId

# Saving the resulting data frame as a file
# Save the data frame as a CSV file for further analysis
write.csv(embedding_desc_df, file = "embeddings_per_description.csv", row.names = FALSE)
