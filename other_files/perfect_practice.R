library(caret)
library(dplyr)
library(rattle)

make_NA_colname_vector <- function(dataframe, threshold){
  NA_colname_vector <- vector()
  for (colname in names(dataframe)){
    if (sum(is.na(dataframe[,colname]))/nrow(dataframe) > threshold){
      NA_colname_vector <- append(NA_colname_vector, colname)
    }
  }
  NA_colname_vector
}

make_blank_colname_vector <- function(dataframe, threshold){
  blank_colname_vector <- vector()
  for (colname in names(dataframe)){
    if (sum(dataframe[,colname]=="") / nrow(dataframe) > threshold){
      blank_colname_vector <- append(blank_colname_vector, colname)
    }
  }
  blank_colname_vector
}

calculate_accuracy <- function(predictions, actual){
  sum(predictions==actual) / length(actual)
  }

# download.file("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv",
#               destfile="training.csv")
# 
# download.file("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv",
#               destfile="testing.csv")

# validation <- read.csv("testing.csv")

training_all <- read.csv("training.csv")

training_all[training_all==""] <- NA

training_stripped <- training_all %>%
  select(-X) %>%
  select(-contains("timestamp")) %>%
  select(-contains("window")) %>%
  select(-user_name) %>%
  select(-classe)

for (colname in names(training_stripped)) {
  training_stripped[,colname] <- as.numeric(training_stripped[,colname])
}

cci <- complete.cases(training_stripped)

colnames_to_impute <- make_NA_colname_vector(dataframe=training_stripped, threshold=0.95)

for (colname in colnames_to_impute) {
  training_outcome <- training_stripped[cci,colname]
  training_df <- select(training_stripped, -colnames_to_impute)[cci,]
  myfit <- train(x=training_df, y=training_outcome, method="glm")
  training_stripped[-cci,colname] <- predict(myfit, newdata=select(training_stripped, -colnames_to_impute)[-cci,])
}

training_imputed <- cbind(training_stripped, training_all$classe)[2:nrow(training_all),]
names(training_imputed)[ncol(training_imputed)] <- "classe"

set.seed(110216)
inTrain = createDataPartition(training_imputed$classe, p = 3/4)[[1]]
training = training_imputed[inTrain,]
testing = training_imputed[-inTrain,]

preProc <- preProcess(training[,-153], method="pca", pcaComp=30)
trainPC <- predict(preProc, training[,-153])
trainPC$classe <- training$classe
pc_model_fit <- train(classe ~ ., method="rf", data=trainPC)

testPC <- predict(preProc, testing[,-153])
pc_predictions <- predict(pc_model_fit, testPC)
confusionMatrix(testing$classe, pc_predictions)

training_complete_cases <- training_stripped[complete.cases(training_stripped),]

for (colname in names(training_complete_cases)){
  training_complete_cases[,colname] <- as.numeric(as.character(training_complete_cases[,colname]))
}

training_incomplete_cases <- training_stripped[!complete.cases(training_stripped),]



for (colname in names(training_incomplete_cases)){
  training_incomplete_cases[,colname] <- as.numeric(training_incomplete_cases[,colname])
}


model_fit_list <- vector()
for (col in select(training_complete_cases, colnames_to_impute)){
  training_df <- cbind(col, select(training_complete_cases, -colnames_to_impute))
  model_fit <- train(col ~ ., method="glm", data=training_df)
  model_fit_list <- append(model_fit_list, c(model_fit))
}

count <- 1
for (col in select(training_incomplete_cases, colnames_to_impute)){
  prediction_df <- select(training_incomplete_cases, -colnames_to_impute)
  model_fit <- model_fit_list[count]
  col <- predict(model_fit, prediction_df)
  count <- count + 1
}



M <- abs(cor(training_complete[,-160]))
diag(M) <- 0
which(M > 0.8, arr=T)

NA_colname_vector <- make_NA_colname_vector(dataframe=training_all, threshold=0.95)
blank_colname_vector <- make_blank_colname_vector(dataframe=training_all, threshold=0.95)

training_all <- training_all %>%
  select(-NA_colname_vector) %>%
  select(-blank_colname_vector) %>%
  select(-X) %>%
  select(-contains("timestamp")) %>%
  select(-contains("window")) %>%
  select(-user_name)

# preProcess(training, method="pca", thresh=0.99)$numComp

preProc <- preProcess(training[,-53], method="pca", pcaComp=20)
trainPC <- predict(preProc, training[,-53])
trainPC$classe <- training$classe
pc_model_fit <- train(classe ~ ., method="rpart", data=trainPC)

testPC <- predict(preProc, testing[,-53])
pc_predictions <- predict(pc_model_fit, testPC)
confusionMatrix(testing$classe, pc_predictions)

fit1 <- train(classe~.,
              method="rpart",
              data=training)

rpart_predicted <- predict(fit1, newdata=testing[,-87])

confusionMatrix(testing$classe, rpart_predicted)

fancyRpartPlot(pc_model_fit$finalModel)


for (colname in names(training)){
  percent_blank <- sum(training[,colname] == "")/nrow(training)
  print(sprintf("%s: %.4f", colname, percent_blank))
}


# methods:
# rpart (recursive partitioning and regression trees - need to load the package, or part of caret?)
# glm (generalized linear model)
# rf (random forest)
# gbm (boosting)
# lda
# lasso
# svm (support vector machine - is its own command, not a method)
