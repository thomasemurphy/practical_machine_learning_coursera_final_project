library(caret)
library(dplyr)

make_NA_colname_vector <- function(dataframe, threshold){
  NA_colname_vector <- vector()
  for (colname in names(dataframe)){
    if (sum(is.na(dataframe[,colname]))/nrow(dataframe) > threshold){
      NA_colname_vector <- append(NA_colname_vector, colname)
    }
  }
  NA_colname_vector
}

preProcessDataframe <- function(dataframe, whichType="train"){
  dataframe[dataframe==""] <- NA
  dataframe <- dataframe %>% select(-X) %>% select(-contains("timestamp")) %>%
    select(-contains("window")) %>% select(-user_name)
  if (whichType=="train") {dataframe <- select(dataframe, -classe)}
  if (whichType=="val") {dataframe <- select(dataframe, -problem_id)}
  for (colname in names(dataframe)) {
    dataframe[,colname] <- as.numeric(dataframe[,colname])
  }
  dataframe
}

imputeMissing <- function(dataframe, validation=NULL){
  cci <- complete.cases(dataframe)
  if (!is.null(validation)) {cciv <- complete.cases(validation)}
  colnames_to_impute <- make_NA_colname_vector(dataframe, threshold=0.95)
  for (colname in colnames_to_impute) {
    training_outcome <- dataframe[cci,colname]
    training_df <- select(dataframe, -colnames_to_impute)[cci,]
    fit1 <- train(x=training_df, y=training_outcome, method="glm")
    dataframe[-cci, colname] <- predict(fit1, newdata=select(dataframe, -colnames_to_impute)[-cci,])
    if (!is.null(validation)){
      validation[, colname] <- predict(fit1, newdata=select(validation, -colnames_to_impute)[,])
    }
  }
  list(dataframe, validation)
}

# download.file("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv", destfile="training.csv")
# download.file("https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv", destfile="testing.csv")

all_data <- read.csv("training.csv")

validation <- read.csv("testing.csv")

clean_data <- preProcessDataframe(all_data)

clean_validation <- preProcessDataframe(validation, whichType="val")

df_imputed <- imputeMissing(clean_data, validation=clean_validation)

clean_data <- df_imputed[[1]]

clean_validation <- df_imputed[[2]]

clean_data <- cbind(clean_data, all_data$classe)[2:nrow(all_data),]
names(clean_data)[ncol(clean_data)] <- "classe"

clean_validation <- cbind(clean_validation, validation$problem_id)
names(clean_validation)[ncol(clean_validation)] <- "problem_id"

set.seed(110216)
inTrain = createDataPartition(clean_data$classe, p = 3/4)[[1]]
training = clean_data[inTrain,]
testing = clean_data[-inTrain,]

end_col_no <- ncol(training)

preProc <- preProcess(training[,-end_col_no], method="pca", pcaComp=30)
trainPC <- predict(preProc, training[,-end_col_no])
trainPC$classe <- training$classe
pc_rf_fit <- train(classe ~ ., method="rf", data=trainPC)

testPC <- predict(preProc, testing[,-end_col_no])
pc_predictions <- predict(pc_rf_fit, testPC)

confusionMatrix(testing$classe, pc_predictions)

# predict the validation set

validationPC <- predict(preProc, clean_validation[,-end_col_no])
validation_predictions <- predict(pc_rf_fit, validationPC)

for (i in 1:length(validation_predictions)){
  print(sprintf("%d: %s", i, validation_predictions[i]))
}
