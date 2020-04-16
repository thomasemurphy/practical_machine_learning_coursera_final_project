---
title: 'Classifying dumbbell lift error types using the Weight Lifting Exercises dataset'
output:
  html_document:
    keep_md: yes
    fig_caption: yes
  pdf_document: default
bibliography: har.bib
---

## Executive summary

This report describes the machine learning pipeline used to assess the technique with which a person lifts dumbbells. The [Weight Lifting Exercises dataset](http://web.archive.org/web/20161224072740/http:/groupware.les.inf.puc-rio.br/har) [@Velloso2013] was used for analysis and classification. The dataset consisted of 19,622 observations of 160 variables, consisting mostly of data from an accelerometer worn on the user's upper arm, forearm, and belt, as well as on the dumbbell itself. Each observation was tagged as either being the correct way to lift the dumbbell (Class A), or as one of four common technique error types (Classes B-D). Unnecessary covariates, for example timestamp, were discarded, and the dataset was split into training and testing subsets using a 3/4 split on Class. Missing values were then imputed using a generalized linear model. A principal component analysis was then used to shrink the number of remaining covariates from 152 to 30. The training set was then fed into a random forest classification algorithm, which predicted the Class of the testing set with 97% accuracy. The algorithm was then used to predict the Class of dumbbell lifting for a validation set of 20 observations for the Coursera Practical Machine Learning course final exam. All 20 of the observations were predicted correctly.

## Background on the dataset

The Weight Lifting Exercises Dataset was generated in an effort to classify "how well" a user performs an exercise activity, in this case, lifting a dumbbell. To collect the data, users wore three accelerometers: one on the upper arm, forearm, and belt. An accelerometer was also mounted on the dumbbell itself. The user was then instructed either to perform biceps curls correctly (tagged Class A), or with one of four technical errors: throwing the elbows to the front (Class B), lifting the dumbbell only halfway (Class C), lowering the dumbbell only halfway (Class D) and throwing the hips to the front (Class E). One column of the dataset is the Class, a tag applied by a human observer. Of the other 159 columns, 152 are either raw or processed accelerometer data, and the other 7 are miscellaneous variables like user name and timestamp.

## Data cleaning

The "training" and "testing" csv files were downloaded from the Human Activity Recognition web repository, and loaded into the R environment as dataframes. The "testing" dataframe was renamed "validation" as the classifications of that dataframe were unknown. The "training" dataframe was renamed "all_data" for later splitting between training and testing dataframes.

Columns that were deemed unnecessary, for example timestamp data and "window" data (unknown meaning) were stripped from the "all_data" and "validation" dataframes. The remaining columns, some of which were factor variables, were converted to numeric type.

## Imputing missing values

Complete cases (rows with no blank or NA values) consisted of only about 2% of the "all_data" dataframe. The remaining 98% of the observations had missing values for about 40% of the covariates. The complete cases were used to impute the missing values. For a covariate that was usually missing, a generalized linear model was trained to predict that covariate, using the other covariates that were always present. That model was then used to predict the values of the missing covariates for the incomplete cases.

## Preprocessing using Principal Component Analysis

A random forest classifier showed early promise for predicting the Class of the observation based on the other covariates. However, after stripping some unnecessary columns, there were still 152 covariates, which raised concern about the time required to train the random forest model. A Principal Component Analysis (PCA) was performed to shrink the number of covariates from 152 down to 30, while maintaining 94% of the variance in the data. The `preProcess` function in the caret package was used to perform the PCA.

## Model training and testing

A random forest classifier was selected based on the nature of the problem (classification into one of five classes) and early indication that a single regression tree would not have sufficient accuracy (about 40%). The seed was set to 110216 based on the date that the Chicago Cubs won the 2016 World Series, and the "all_data" principal components dataframe was split into a training and testing dataset with a 3/4 split based on Class.

The random forest ("rf") method of the "train" function within the caret package was trained to predict Class based on the other 30 principal components. Default settings were used for the rf method. Training the model on the 14,718-row, 31-column dataframe took about 40 minutes on a 2.8 GHz Quad-Core Intel Core i7 processor.

The Class of the testing dataframe was then predicted using the rf model. The overall accuracy of the classifier was 97%, which was deemed good.

## Model validation

The same pre-processing steps were applied to the 20-observation validation dataset. The random forest model was then used to predict the Class of these 20 observations. Feedback from the Coursera quiz confirmed that the Class of 20 out of 20 observations were predicted correctly. This 20/20 score is consistent with the 97% accuracy on the testing set.

## References

Thank you to the following people for letting us use your data!
