library(topicmodels)
library(lda)
library(slam)
library(stm)
library(ggplot2)
library(dplyr)
library(tidytext)
library(furrr) # try to make it faster
plan(multicore)
library(tm) # Framework for text mining
library(tidyverse) # Data preparation and pipes %>%
library(ggplot2) # For plotting word frequencies
library(wordcloud) # Wordclouds!
library(Rtsne)
library(rsvd)
library(geometry)
library(NLP)
library(ldatuning) 


# Clear up data in global environment
rm(list=ls())

# Load data from csv file
sentiments <- read.csv("sentiments.csv", , check.names = FALSE)

# Check for NAs
cat("\n")
sapply(sentiments, function(x) sum(is.na(x)))

cat("\n")

# Overview of original dataset
str(sentiments)
cat("\n")
sapply(sentiments, typeof)
cat("\n")


# cat(colnames(sentiments))


# Set the seed for reproducibility
set.seed(830)

# Sample 1000 rows from the original dataframe
sentiments_sample <- sentiments[sample(nrow(sentiments), 1000), ]

# Convert columns to appropriate formats
sentiments_sample$`Trading app` <- as.factor(sentiments_sample$`Trading app`)
sentiments_sample$Source <- as.factor(sentiments_sample$Source)
sentiments_sample$Comment <- as.character(sentiments_sample$Comment)
sentiments_sample$Sentiment <- as.factor(sentiments_sample$Sentiment)

# Double-check the format of each column
sapply(sentiments_sample, typeof)


# * default parameters
processed <- textProcessor(
  documents = sentiments_sample$Comment, # textual data
  metadata = sentiments_sample,          # Metadata (other columns)
  lowercase = TRUE,                      # Convert text to lowercase
  removestopwords = TRUE,                # Remove stopwords
  removenumbers = TRUE,                  # Remove numbers from the text
  removepunctuation = TRUE,              # Remove punctuation from the text
  stem = TRUE,                           # Apply stemming
  wordLengths = c(3, Inf),
  sparselevel = 1,           # Sparse level for removing rarely occurring words
  language = "en",                       # Language for stopwords
  verbose = TRUE,
  onlycharacter = TRUE,                  # Keep only alphabetic characters
  striphtml = FALSE,                     # Don't remove HTML tags
  customstopwords = NULL,                # No additional custom stopwords
  v1 = FALSE                       # Use newer version of textProcessor function
)

# Filter out terms that don’t appear in more than 10 documents
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 10)

docs <- out$documents
vocab <- out$vocab
meta <- out$meta

# Check levels of the factors in your metadata
cat("\n")
cat(levels(meta$`Trading app`))
cat("\n")
cat(levels(meta$Source))
cat("\n")


# Set seed for reproducibility
set.seed(831)

# Fit the STM model
system.time({
  First_STM <- stm(
    docs, vocab, 15,                          # Use 15 topics
    prevalence =~ `Trading app` + Sentiment,  # Replace 'publisher' with 'Trading App' and 'date' with 'Sentiment' or another continuous variable
    data = meta,                              # Use the metadata
    seed = 15,                                # Seed for STM model
    max.em.its = 5                            # Limit to 5 EM iterations (adjust as necessary)
  )
})

# Plot the first topic model
plot(First_STM)
cat("\n")

labels <- labelTopics(First_STM)
print(labels)
cat("\n")



# Set seed for reproducibility
set.seed(832)

# Fit the STM model
system.time({
  Second_STM <- stm(
    documents = out$documents,
    vocab = out$vocab,
    K = 18,  # Number of topics
    prevalence =~ `Trading app` + Sentiment,  # Adjust if necessary
    max.em.its = 75,
    data = out$meta,
    init.type = "Spectral",
    verbose = FALSE
  )
})

# Plot the second topic model
plot(Second_STM)
cat("\n")

labels <- labelTopics(Second_STM)
print(labels)
cat("\n")


# Set seed for reproducibility
set.seed(833)

# Perform the search for optimal number of topics from 10 to 30
system.time({
  findingk <- searchK(
    out$documents,
    out$vocab,
    K = 10:30,
    prevalence =~ `Trading app` + Sentiment,  # Adjust based on your metadata
    data = out$meta,
    verbose = FALSE
  )
})

# Plot the results
# Held-out likelihood plot
plot(findingk, type = "heldout", main = "Held-out Likelihood vs Number of Topics")

# Residuals plot
plot(findingk, type = "residuals", main = "Residuals vs Number of Topics")

# Semantic coherence plot
plot(findingk, type = "semcoh", main = "Semantic Coherence vs Number of Topics")

# Lower bound plot
plot(findingk, type = "bound", main = "Lower Bound vs Number of Topics")
