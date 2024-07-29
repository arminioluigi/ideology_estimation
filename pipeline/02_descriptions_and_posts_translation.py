# Import necessary libraries
import os
import numpy as np
import pandas as pd
from deep_translator import GoogleTranslator
import time
from requests.exceptions import SSLError

# Get the current working directory
os.getcwd()

# Change the current working directory to the specified path
#os.chdir("C:\\Users\\luia\\Documents\\poster2")


# Load the initial dataset of posts
polarvis_posts0 = pd.read_csv("polarvis_posts.csv",index_col=[0])


# Change the directory to a different location for further operations
os.chdir("C:\\Users\\luia\\Documents\\AFTER_SUMMER")

# Load the link sharing dataframe
polarvis_posts1 = pd.read_csv("links_users.csv",index_col=[0])


# Load another dataset containing posts with textual content
polarvis_posts = pd.read_csv("4_months_posts.csv",index_col=[0])


# Process and filter the dataset for embedding entities
entities_embedding = polarvis_posts
entities_embedding = entities_embedding.dropna(subset=['account.pageDescription'])
entities_embedding = entities_embedding.dropna(subset=['textual_content'])


entities_embedding = entities_embedding.groupby(['account.name', 'account.platformId']).first().reset_index()
entities_embedding = entities_embedding[['account.name', "account.platformId",'account.pageDescription']]
entities_embedding = entities_embedding.drop_duplicates()



#TRANSLATION OF PAGE DESCRIPTIONS
# Define a function to translate text using Google Translator

def translate_text(text, source_language, target_language):
    translator = GoogleTranslator(source=source_language, target=target_language)
    translated_text = translator.translate(text)
    return translated_text

# Translate page descriptions and append the translations to the dataframe
entities_translations = []
total_entities = len(entities_embedding)
progress_interval = 25

for i, text in enumerate(entities_embedding["account.pageDescription"], 1):
    try:
        translated_text = translate_text(text, "auto", "en")
        entities_translations.append(translated_text)
    except SSLError as e:
        print(f"Translation failed for element {i}: {text}")
        print(f"Error: {e}")
    
    if i % progress_interval == 0 or i == total_entities:
        progress = i / total_entities * 100
        print(f"Progress: {i}/{total_entities} ({progress:.2f}%)")

print("Translation completed!")


#Append translations of descriptions to the data
entities_embedding["account.pageDescription_translated"] = entities_translations

# Export the dataframe with translated descriptions to a CSV file
entities_embedding.to_csv("OUTPUT/translations/descriptions_with_translation.csv",index = False)



# Verify the results by loading the exported CSV file
pd.read_csv("OUTPUT/translations/descriptions_with_translation.csv")

# Further processing and filtering of the dataset
entities_embedding = polarvis_posts
entities_embedding = entities_embedding.dropna(subset=['account.pageDescription'])
entities_embedding = entities_embedding.dropna(subset=['textual_content'])


#entities_embedding = entities_embedding.groupby(['account.name', 'account.p.reset_index()latformId']).first().reset_index()
entities_embedding = entities_embedding.reset_index()
entities_embedding = entities_embedding[['account.name', "account.platformId",'textual_content']]
entities_embedding = entities_embedding.drop_duplicates()
# Rename the 'textual_content' column to 'message'
entities_embedding = entities_embedding.rename(columns={'textual_content': 'message'})

entities_embedding


# Count the number of cases where the length of the message exceeds a certain threshold
[len(x) for x in entities_embedding["message"] if len(x)>4999] #number of cases in which len>5000

# Define a function to translate a column in the dataframe
def translate_column(entities_embedding, column):
    translations = []
    total_entities = len(entities_embedding)
    progress_interval = 25
    max_retries = 3
    retry_delay = 5  # seconds

    for i, value in enumerate(entities_embedding[column], 1):
        value_cut = value[:4999] #cutting extreme cases in which len > 5000 to have the translator working
        retries = 0
        while retries < max_retries:
            try:
                translated_value = translate_text(value_cut, "auto", "en")
                translations.append(translated_value)
                break  # Translation successful, exit the retry loop
            except SSLError as e:
                print(f"Translation failed for element {i}: {value}")
                print(f"Error: {e}")
                retries += 1
                print(f"Retrying after {retry_delay} seconds...")
                time.sleep(retry_delay)
        else:
            print(f"Translation failed after {max_retries} retries for element {i}: {value}")
            break  # Max retries reached, exit the loop

        if i % progress_interval == 0 or i == total_entities:
            progress = i / total_entities * 100
            print(f"Progress: {i}/{total_entities} ({progress:.2f}%)")

    print(f"Translation of column '{column}' completed!")
    return translations


# Perform translation on the 'message' column
translations_messages = translate_column(entities_embedding,"message")

# Append the translated messages to the dataframe
entities_embedding["message_translated"] = translations_messages


# Export the dataframe with translated messages to a CSV file
entities_embedding.to_csv("OUTPUT/TRANSLATIONS/posts_messages_embedding_nonagg.csv",index = False)



# Verify the results by loading the exported CSV file
pd.read_csv("OUTPUT/TRANSLATIONS/posts_messages_embedding_nonagg.csv")