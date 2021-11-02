#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jun 24 13:05:56 2021

@author: sampark
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import RidgeCV, LassoCV
from sklearn.model_selection import cross_val_score
import xgboost as xgb

"""
Connect the test and training data from csv files
"""
filepath = "/Users/sampark/Documents/Work/Kaggle/housePrices/"
filename_train = "train.csv"
filename_test = "test.csv"

train = pd.read_csv(filepath + filename_train)
test = pd.read_csv(filepath + filename_test)

"""
create original copies of the data and take a look at the shape of the data
"""
train_og = train.copy()
test_og = test.copy()

train.head()
test.head()

train.shape
test.shape

"""
Combine training and test sets in order to process data before EDA and modeling
"""
data = pd.concat([train, test], keys=('x', 'y'))
data = data.drop(["Id"], axis = 1)

"""
Check for null values and remove columns with over 85% null values
"""
null_data = data.isnull().sum().sort_values(ascending=False)

null_percentage = (data.isnull().sum()/data.isnull().count()).sort_values(ascending=False)

missing_data = pd.concat([null_data, null_percentage], axis= 1, keys= ["Total", "Percentage"])

missing_data.head(20)

data = data.drop(["PoolQC", "MiscFeature", "Alley", "Fence", "FireplaceQu", "LotFrontage"],
                 axis = 1)

"""
Separate numerical and categorical variables and fill in null values with mean
and mode
"""
num_data = data._get_numeric_data().columns.tolist()

cat_data = set(data.columns) - set(num_data)

for col in num_data:
    data[col].fillna(data[col].mean(), inplace=True)
    
for col in cat_data:
    data[col].fillna(data[col].mode()[0], inplace=True)
    
data[num_data].isnull().sum()
data[cat_data].isnull().sum()

for i in cat_data:
    print(data[i].value_counts())
    
"""
Drop categorical columns with more than 80% of observations belonging to a single class
"""
data = data.drop(["LandSlope", "Condition2", "LandContour", "Street", "ExterCond",
                  "Condition1", "Functional", "Electrical", "CentralAir",
                  "Heating", "GarageQual", "RoofMatl", "BsmtCond", "PavedDrive",
                  "Utilities", "GarageCond", "BsmtFinType2"], axis= 1)

"""
EDA
"""
"""
Take a look at the distribution of SalePrice to check for normality. Since we can
see that there is skewness we can perform a log transformation to correct
"""
plt.figure(figsize=(12,10))

sns.set_style("darkgrid")
sns.histplot(data=train, x="SalePrice", bins=50, cbar=True)

train['SalePrice'] = np.log1p(train['SalePrice'])

sns.set_style("darkgrid")
sns.histplot(data=train, x="SalePrice", bins=50, cbar=True, color='black')

data['SalePrice'] = np.log1p(data['SalePrice'])

"""
Rank variables based on correlation with SalePrice and drop variables with correlation
below .1
"""
corr = train.corr()
corr_rank = corr["SalePrice"].sort_values(ascending = False)
corr_rank
data = data.drop(["PoolArea", "MoSold", "3SsnPorch", "BsmtFinSF2", "BsmtHalfBath",
                  "MiscVal", "LowQualFinSF", "YrSold", "OverallCond", "MSSubClass"],
                 axis = 1)

"""
Create correlation heatmap of variables with absolute correlation above 0.5
"""
top_features = corr.index[abs(corr["SalePrice"]>0.5)]
plt.figure(figsize = (9,9))
heat_map = sns.heatmap(data[top_features].corr(), annot=True, cmap="RdYlGn")
    
"""
Create scatterplots of 12 variables with the highest correlation to SalePrice
"""
corr_rank = corr_rank.drop(["SalePrice"])
sorted_corr = corr_rank.index.tolist()
fig, axes = plt.subplots(4, 3, figsize=(20,10), sharey= True)
fig.suptitle("Highest Correlation with Sale Price", fontsize= 20)
plt.subplots_adjust(hspace = 0.7, wspace=0.1)
for i,col in zip(range(12), sorted_corr):
    sns.scatterplot(y=data['SalePrice'], x=data[col],ax=axes[i//3][i%3])
    axes[i//3][i%3].set_title('SalesPrice with '+col)
    
"""
Remove outliers of numeric variables by setting limits based on interquartile range
"""
n_features = data.select_dtypes(exclude = ["object"]).columns
n_features
data_outliers = data[["LotArea", "MasVnrArea", "BsmtFinSF1", "BsmtUnfSF", "TotalBsmtSF",
                "1stFlrSF", "2ndFlrSF", "GrLivArea", "GarageArea", "WoodDeckSF",
                "OpenPorchSF"]]
def mod_outliers(data):
    df1 = data.copy()
    data = data[["LotArea", "MasVnrArea", "BsmtFinSF1", "BsmtUnfSF", "TotalBsmtSF",
                "1stFlrSF", "2ndFlrSF", "GrLivArea", "GarageArea", "WoodDeckSF",
                "OpenPorchSF"]]
    
    q1 = data.quantile(0.25)
    q3 = data.quantile(0.75)
    
    iqr = q3 - q1
    
    lower_bound = q1 - (1.5 * iqr)
    upper_bound = q3 + (1.5 * iqr)
    
    for col in data.columns:
        for i in range(0, len(data[col])):
            if data[col][i] < lower_bound[col]:
                data[col][i] = lower_bound[col]
                
            if data[col][i] > upper_bound[col]:
                data[col][i] = upper_bound[col]
                
    for col in data.columns:
        df1[col] = data[col]
        
    return(df1)

data = mod_outliers(data)
data_outliers = mod_outliers(data_outliers)
for i in data_outliers:
    sns.boxplot(x=data_outliers[i])
    plt.show()
    
"""
Convert categorical varialbes into dummy variables
"""
data = pd.get_dummies(data)

"""
Extract training and test sets after processing
"""
train = data.loc["x"]
test = data.loc["y"]
test = test.drop(["SalePrice"], axis = 1)

y = train["SalePrice"]
train_x = train.drop(["SalePrice"], axis = 1)
test_x = test

"""
Run machine learning algorithms and save final prediction for Kaggle submission
"""
def rmse_cv(model):
    rmse = np.sqrt(-cross_val_score(model, train_x, y, scoring = "neg_mean_squared_error",
                                    cv = 5))
    return(rmse)

lasso = LassoCV(alphas = [1, 0.1, 0.01, 0.001, 0.0001]).fit(train_x, y)
rmse_cv(lasso).mean()

ridge = RidgeCV(alphas = [0.05, 0.1, 0.3, 1, 5, 10, 15, 30, 50, 75]).fit(train_x, y)
rmse_cv(ridge).mean()

model_xgb = xgb.XGBRegressor(n_estimators = 360, max_depth = 2, learning_rate = 0.1)
model_xgb.fit(train_x, y)

lasso_preds = np.expm1(lasso.predict(test_x))
xgb_preds = np.expm1(model_xgb.predict(test_x))

preds = 0.7*lasso_preds + 0.3*xgb_preds

submission = pd.DataFrame({"id": test_og.Id, "SalePrice": preds})
submission.to_csv(filepath + "submission.csv", index = False)







