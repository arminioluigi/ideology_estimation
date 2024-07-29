# Load necessary libraries
library(stringr)
library(tidyverse)

# API token (replace with your actual token)
token= "token"

# Source external R script for API querying
source("query_CT_api.R")

# Set the sleep duration (in seconds) to manage API request rate
sleep=10


# Define the default time frame for data collection 
startDate="2023-04-29"

# Retrieve a list of all CT lists associated with the API key
query.string.lists <- paste0("https://api.crowdtangle.com/lists/?","&token=",token)
ct_lists=query_api_enpoint(query.string = query.string.lists)$result$list


# Filter lists by titles containing 'PolarVis'in the title
ct_lists

# Define specific IDs for PolarVis pages and groups
polarvis_pages=c(1788681)
polarvis_groups=c(1788682)

# Collect account data from PolarVis pages
# Initialize a dataframe to store account information
polarvis_accounts_pages=data.frame(id=as.numeric(),
                                   name=as.character(),
                                   handle=as.character(),
                                   profileImage=as.character(),
                                   subsriberCount=as.numeric(),
                                   url=as.character(),
                                   platform=as.character(),
                                   platformId=as.numeric(),
                                   accountType=as.character(),
                                   pageDescription=as.character(),
                                   pageCreatedDate=as.character(),
                                   pageCategory=as.character(),
                                   verified=as.character(),
                                   pageAdminTopCountry=as.character())

# Loop through each page ID to gather account data
for(i in seq_along(polarvis_pages)){
  
  
  query.string.ids <- paste0("https://api.crowdtangle.com/lists/",
                             polarvis_pages[i],
                             "/accounts/",
                             "?token=",token,"&count=100"
  )
  
  x = query_api_enpoint(query.string = query.string.ids)$result
  polarvis_accounts_pages=rbind(polarvis_accounts_pages,x$accounts)
  
  while(!(is.null(x$pagination$nextPage))){
    x = query_api_enpoint(query.string = x$pagination$nextPage)$result
    polarvis_accounts_pages=rbind(polarvis_accounts_pages,x$accounts)}
  
}

# The following section is commented out and can be activated if needed
# It is intended to collect account data from PolarVis groups

# polarvis_accounts_groups=data.frame(id=as.numeric(),
#                                    name=as.character(),
#                                    profileImage=as.character(),
#                                    subsriberCount=as.numeric(),
#                                    url=as.character(),
#                                    platform=as.character(),
#                                    platformId=as.numeric(),
#                                    accountType=as.character(),
#                                    pageCategory=as.character(),
#                                    verified=as.character())

# for(i in seq_along(polarvis_groups)){
#   
#   
#   query.string.ids <- paste0("https://api.crowdtangle.com/lists/",
#                              polarvis_groups[i],
#                              "/accounts/",
#                              "?token=",token,"&count=100"
#   )
#   
#   x = query_api_enpoint(query.string = query.string.ids)$result
#   polarvis_accounts_groups=rbind(polarvis_accounts_groups,x$accounts)
#   
#   while(!(is.null(x$pagination$nextPage))){
#     x = query_api_enpoint(query.string = x$pagination$nextPage)$result
#     polarvis_accounts_groups=rbind(polarvis_accounts_groups,x$accounts)
#   }
# }





#common_cols <- intersect(colnames(polarvis_accounts_groups), colnames(polarvis_accounts_pages))

# Combine account data from pages (and groups if applicable)
polarvis_accounts_df=bind_rows(
  #polarvis_accounts_groups %>% select({common_cols}), 
  polarvis_accounts_pages #%>% select({common_cols})
)

# Save the account data to a CSV file
write.csv(polarvis_accounts_pages,"polarvis_accounts_pages.csv")


# Extract the last 100 posts from the last month for each account
polarvis_accounts = polarvis_accounts_pages$platformId #only pages

# Initialize the loop for each account in polarvis_accounts
for(i in 1:length(polarvis_accounts)){
  query.string.posts <- paste0("https://api.crowdtangle.com/posts?",
                               "accounts=",polarvis_accounts[i],
                               "&startDate=", gsub(" ", "T", as.character(startDate)),
                               "&token=", token,
                               "&count=100"
  )
  
  
  posts=query_api_enpoint(query.string = query.string.posts)$result$posts
  
  if (!is_empty(posts)){break}
  Sys.sleep(time = sleep)
}
sp = i
print(paste0(i," out of ",length(polarvis_accounts)))

if("link" %in%names(posts)){
  posts = posts%>%select(link,type,date,account.name,account.platformId)
}

if(!("link" %in%names(posts))){
  if("expandedLinks" %in% names(posts)){
    posts = posts%>%select(link = expandedLinks,type,date,account.name,account.platformId)
    posts$link = unlist(posts$link)[2]
  }
}

for(i in sp:length(polarvis_accounts)){
  
  query.string.posts <- paste0("https://api.crowdtangle.com/posts?",
                               "accounts=",polarvis_accounts[i],
                               "&startDate=", gsub(" ", "T", as.character(startDate)),
                               "&token=", token,
                               "&count=100"
  )
  
  posts_t=query_api_enpoint(query.string = query.string.posts)$result$posts
  if(!is_empty(posts_t)){
    posts_t=as.data.frame(posts_t)
    if("link" %in% names(posts_t)){
      posts_t = posts_t%>%select(link,type,date,account.name,account.platformId)
    }
    
    if(!("link" %in%names(posts_t))){
      if("expandedLinks" %in% names(posts_t)){
        posts_t = posts_t%>%select(link = expandedLinks,type,date,account.name,account.platformId)
        posts_t$link = unlist(posts_t$link)[2]
      }
      if(!("expandedLinks" %in% names(posts_t))){next}
    }
    
    posts=rbind(posts,posts_t)
    
    
  }
  print(paste0(i," out of ",length(polarvis_accounts)))
  Sys.sleep(time = sleep)
  
}
#rm(posts_t)


# Initialize lists for storing messages and tracking failed accounts or accounts without posts
messages <- list()  # Initialize the data structure to store messages
failed_accounts <- c()  # Initialize a vector to store failed accounts
accounts_without_posts <- c()
messages <- list()
messages_presents <- list()

# Loop through each account to fetch and store posts
for (i in 1:length(polarvis_accounts)) {
  query.string.posts <- paste0("https://api.crowdtangle.com/posts?",
                               "accounts=", polarvis_accounts[i],
                               "&startDate=", gsub(" ", "T", as.character(startDate)),
                               "&token=", token,
                               "&count=100"
  )
  
  # Query the API and retrieve posts
  api_result <- query_api_enpoint(query.string.posts)
  
  if (is.atomic(api_result)) {
    messages[[polarvis_accounts[i]]] <- c(NA)
    failed_accounts <- c(failed_accounts, polarvis_accounts[i])
    print(paste0(i,"failed"))
    next  # Skip to the next iteration
  }
  
  if (!is_empty(api_result$result$posts)) {
    if ((!"message" %in% names(api_result$result$posts))) { # & ("description" %in% names(api_result$result$posts))
      messages[[polarvis_accounts[i]]] <- api_result$result$posts
    } else {
      messages_presents[[polarvis_accounts[i]]] <- api_result$result$posts
      print(paste("The 'message' column is present in posts", "."))
    }
  } else {
    messages[[polarvis_accounts[i]]] <- c(NA)
    print(paste("No posts found for account:", polarvis_accounts[i]))
    accounts_without_posts <- c(accounts_without_posts,polarvis_accounts[i])
  }
  print(paste0(i," out of ",length(polarvis_accounts)))
}


















### SAVING THE COLLECTED DATA
#### Specify the current date and create a list to store your data

# Get the current date
current_date <- Sys.Date()

# Create a list to store your data
data_to_save <- list(
  messages = messages,
  messages_presents = messages_presents,
  failed_accounts = failed_accounts,
  accounts_without_posts = accounts_without_posts,
  date_saved = current_date
)

# Specify file name and save data to an RDS file
filename <- paste0("messages_data_", format(current_date, "%Y%m%d"), ".rds")

# Save the data to a .rds file
saveRDS(data_to_save, file = filename)

# Print confirmation message for data saving
cat("Data saved to:", filename, "\n")



# Extract data from the saved RDS file
messages = data_to_save[["messages"]]
messages_presents = data_to_save[["messages_presents"]]
failed_accounts = data_to_save[["failed_accounts"]]
accounts_without_posts = data_to_save[["accounts_without_posts"]]

# Initialize empty dataframe for post details
postsofthepages <- data.frame(
  account.platformId = character(),
  account.name = character(),
  message = character(),
  description = character(),
  imageText = character(),
  date = character(),
  type = character(),
  account.pageDescription = character(),  # Change to account.pageDescription
  stringsAsFactors = FALSE
)

# Define a function to add rows to the post details dataframe
add_rows_to_dataframe <- function(df) {
  num_rows <- nrow(df)
  for (row_index in 1:num_rows) {
    account_id <- ifelse("account.platformId" %in% colnames(df), df[row_index, "account.platformId"], NA)
    account_name <- ifelse("account.name" %in% colnames(df), df[row_index, "account.name"], NA)
    message <- ifelse("message" %in% colnames(df), df[row_index, "message"], NA)
    description <- ifelse("description" %in% colnames(df), df[row_index, "description"], NA)
    image_text <- ifelse("imageText" %in% colnames(df), df[row_index, "imageText"], NA)
    date <- ifelse("date" %in% colnames(df), df[row_index, "date"], NA)
    type <- ifelse("type" %in% colnames(df), df[row_index, "type"], NA)
    account_page_description <- ifelse("account.pageDescription" %in% colnames(df), df[row_index, "account.pageDescription"], NA)  # Change to account.pageDescription
    
    new_row <- data.frame(
      account.platformId = account_id,
      account.name = account_name,
      message = message,
      description = description,
      imageText = image_text,
      date = date,
      type = type,
      account.pageDescription = account_page_description,  # Change to account.pageDescription
      stringsAsFactors = FALSE
    )
    
    postsofthepages <<- rbind(postsofthepages, new_row)
  }
}

# Iterate through the 'messages' list
for (i in 1:length(messages)) {
  if (!is.null(messages[[i]]) && is.data.frame(messages[[i]])) {
    add_rows_to_dataframe(messages[[i]])
  }
}

# Iterate through the 'messages_presents' list
for (i in 1:length(messages_presents)) {
  if (!is.null(messages_presents[[i]]) && is.data.frame(messages_presents[[i]])) {
    add_rows_to_dataframe(messages_presents[[i]])
  }
}


# Remove duplicate rows from postsofthepages if necessary
postsofthepages <- postsofthepages[!duplicated(postsofthepages), ]


# Filter rows based on specific criteria
filtered_df <- postsofthepages[
  # Keep rows that meet both conditions:
  # 1. Date before or on August 29, 2023
  as.Date(postsofthepages$date) <= as.Date("2023-08-29") &
    # 2. Have at least one non-NA value in message, description, or imageText columns
    (!is.na(postsofthepages$message) | !is.na(postsofthepages$description) | !is.na(postsofthepages$imageText)), ]


# Aggregate textual content for each post
filtered_df$textual_content <- apply(filtered_df[, c("message", "description", "imageText")], 1, function(row) {
  non_na_values <- na.omit(row)
  if (length(non_na_values) > 0) {
    paste(non_na_values, collapse = " ")
  } else {
    NA
  }
})



# Save filtered_df as CSV
csv_file <- "4_months_posts.csv"
write.csv(filtered_df, file = csv_file, row.names = FALSE)

# Save filtered_df as RDS
rds_file <- "4_months_posts.rds"
saveRDS(filtered_df, file = rds_file)

# Print confirmation messages
cat("filtered_df has been saved as", csv_file, "and", rds_file, "\n")


# Create an empty dataframe for links_users
links_users <- data.frame(account.platformId = character(),
                          link = character(),
                          date = character(),
                          type = character(),
                          stringsAsFactors = FALSE)

# Function to add rows to the links_users dataframe
add_links_to_dataframe <- function(df) {
  num_rows <- nrow(df)
  for (row_index in 1:num_rows) {
    account_id <- ifelse("account.platformId" %in% colnames(df), df[row_index, "account.platformId"], NA)
    
    # Initialize link, date, and type to NA
    link <- NA
    date <- NA
    type <- NA
    
    # Check if "link," "date," and "type" columns are present
    if ("link" %in% colnames(df)) {
      link <- df[row_index, "link"]
    }
    
    if ("expandedLinks" %in% colnames(df)) {
      expanded_links <- df[row_index, "expandedLinks"]
      
      # If expandedLinks is present, assign the value from the second element
      if (!is.null(expanded_links) && length(expanded_links) >= 2) {
        link <- as.character(unlist(expanded_links)[2])
      }
    }
    
    if ("date" %in% colnames(df)) {
      date <- df[row_index, "date"]
    }
    
    if ("type" %in% colnames(df)) {
      type <- df[row_index, "type"]
    }
    
    # Add a row for account.platformId, link, date, and type to links_users
    new_row <- data.frame(account.platformId = account_id,
                          link = link,
                          date = date,
                          type = type,
                          stringsAsFactors = FALSE)
    
    links_users <<- rbind(links_users, new_row)
  }
}

# Iterate through the 'messages' list
for (i in 1:length(messages)) {
  if (!is.null(messages[[i]]) && is.data.frame(messages[[i]])) {
    add_links_to_dataframe(messages[[i]])
  }
}

# Iterate through the 'messages_presents' list
for (i in 1:length(messages_presents)) {
  if (!is.null(messages_presents[[i]]) && is.data.frame(messages_presents[[i]])) {
    add_links_to_dataframe(messages_presents[[i]])
  }
}

# Remove duplicate rows if needed
links_users <- links_users[!duplicated(links_users), ]


# Save links_users as CSV
write.csv(links_users, "links_users.csv", row.names = FALSE)

# Save links_users as RDS
saveRDS(links_users, "links_users.rds")
