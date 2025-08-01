#Data 101 Project

#load libraries
library(rpart)
library(caret)
library(klaR)
library(rsample)
library(rpart.plot)
library(ggplot2)
library(corrplot)

#set seed for reproducibility
set.seed(123)
#read dataset
setwd("~/Desktop/Data 101")
pdf(file="Data101Project_output.pdf")
milk <- read.csv("milknew.csv")

#Quick overview of data
head(milk)
tail(milk)
str(milk)
summary(milk)
dim(milk)

#Omitting na data
na.omit(milk)

#converting data to numeric and factor
milk$pH <- as.numeric(milk$pH)
milk$Temprature <- as.numeric(milk$Temprature)
milk$Colour <- as.numeric(milk$Colour)

milk$Taste <- as.factor(milk$Taste)
milk$Odor <- as.factor(milk$Odor)
milk$Fat <- as.factor(milk$Fat)
milk$Turbidity <- as.factor(milk$Turbidity)

# For Grade, we specify an ordering (e.g., low < medium < high)
milk$Grade <- factor(milk$Grade, levels = c("low", "medium", "high"), ordered = TRUE)

#Correlation matrix
data_corr <- data.frame(
  pH = milk$pH,
  Temprature = milk$Temprature,
  Colour = milk$Colour,
  Taste = as.numeric(as.character(milk$Taste)),
  Odor = as.numeric(as.character(milk$Odor)),
  Fat = as.numeric(as.character(milk$Fat)),
  Turbidity = as.numeric(as.character(milk$Turbidity)),
  Grade = as.numeric(milk$Grade)
)

# Compute the correlation matrix
corr_matrix <- cor(data_corr)
print(corr_matrix)

# Plot the correlation matrix as a heat map
corrplot(corr_matrix, method = "color", addCoef.col = "black", tl.col = "black", number.cex = 0.7)

#Visualization of data
#Turbidity v Grade
mosaicplot(
  table(milk$Turbidity, milk$Grade),
  main  = "Mosaic Plot: Turbidity vs Grade",
  xlab  = "Turbidity",
  ylab  = "Grade",
  color = TRUE
)

#Fat v Grade
mosaicplot(
  table(milk$Fat, milk$Grade),
  main  = "Mosaic Plot: Fat Content vs Grade",
  xlab  = "Fat (0 = low, 1 = high)",
  ylab  = "Grade",
  color = TRUE
)

#Odor v Grade
mosaicplot(
  table(milk$Odor, milk$Grade),
  main  = "Mosaic Plot: Odor Presence vs Grade",
  xlab  = "Odor (0 = none, 1 = present)",
  ylab  = "Grade",
  color = TRUE
)

#Color v Grade
colour_bins_eq <- cut(
  milk$Colour,
  breaks = 4,
  include.lowest = TRUE
)
mosaicplot(
  table(colour_bins_eq, milk$Grade),
  main  = "Mosaic Plot: Colour (equal‐width bins) vs Grade",
  xlab  = "Colour Bin",
  ylab  = "Grade",
  color = TRUE
)

#Temperature v Grade
temp_bins <- cut(milk$Temprature,
                 breaks = quantile(milk$Temprature, probs = seq(0,1,0.25), na.rm=TRUE),
                 include.lowest = TRUE)

mosaicplot(table(temp_bins, milk$Grade),
           main = "Mosaic Plot: Temperature vs Grade",
           xlab = "Temperature (binned)",
           ylab = "Grade",
           color = TRUE)



#remove pH and Taste from dataset
milk <- milk[,-c(1, 3)]

#Create training and test data sets
milk_split <- initial_split(milk, prop=0.8)
milk_split
milk_training <- training(milk_split)
milk_test <- testing(milk_split)

prop.table(table(milk_training$Grade))
prop.table(table(milk_test$Grade))
#approximately same proportions in training and test data sets


# Build the rpart model without cross-validation
rpart_model <- rpart(Grade ~ ., data = milk_training, method = "class")
# Visualize the tree
rpart.plot(rpart_model, type = 2, extra = 104)
# Predict on training data
rpart_pred <- predict(rpart_model, milk_test, type = "class")
# Confusion matrix
rpart_cm <- table(Predicted = rpart_pred, Actual = milk_test$Grade)
caret::confusionMatrix(rpart_cm)

#rpart model with cross-validation
train_control <- trainControl(method="cv", number=5, savePredictions=TRUE)
rpart_cv <- train(Grade ~ ., data=milk_training, trControl=train_control, method="rpart", tuneLength=5)
print(rpart_cv)
rpart.plot(rpart_cv$finalModel)


#naive bayes model without cross-validation
nb_model <- NaiveBayes(Grade ~ ., data=milk_training)
#predict on test data set
pred <- predict(nb_model, milk_test)
tab <- table(pred$class, milk_test$Grade)
caret::confusionMatrix(tab)

#naive bayes model with cross-validation
train_control <- trainControl(method="cv", number=5, savePredictions=TRUE)
nb_cv <- train(Grade ~ ., data=milk_training, trControl=train_control, method="nb")
print(nb_cv)

dev.off()

