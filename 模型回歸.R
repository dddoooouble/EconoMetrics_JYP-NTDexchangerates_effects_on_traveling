library(readxl)
Data_t_1 <- read_excel("Data-t=1.xlsx")

#ADFtest
library(tseries)
# 1. 檢定：來台旅客人數
adf.test(Data_t_1$`ln(Tourist)`)

# 2. 檢定：台日匯率
adf.test(Data_t_1$`d_ln(FX)`)

# 3. 檢定：日本工業生產指數
adf.test(Data_t_1$`ln(JIPI)`)

# 4. 檢定：原油價格
adf.test(Data_t_1$`d_ln(OilPrice)`)

#model01-------------------------------------------------------
model01 <- lm(`ln(Tourist)` ~ `d_ln(FX)` +  `ln(JIPI)` + `d_ln(OilPrice)` + t + 
                 Month1 + Month2 + Month3 + Month4 + Month5 + Month6 + 
                 Month7 + Month8 + Month9 + Month10 + Month11, 
               data = Data_t_1)
summary(model01)

#算VIF
library(car)
vif(model01)

#BGtest
library(lmtest)
library(sandwich)
bgtest(model01, order = 1)
#執行Newey-West HAC修正，重新檢視所有變數的顯著性
coeftest(model01, vcov = vcovHAC(model01))

#model02-------------------------------------------------------------
model02 <- lm(`ln(Tourist)` ~ `ln(Tourist-1)`+`d_ln(FX)` + `d_ln(FX-1)`+`d_ln(FX-2)` +
                 `ln(JIPI)` +`ln(JIPI-1)` + `ln(JIPI-2)`+ 
                 `d_ln(OilPrice)`  + `d_ln(OilPrice-1)` + `d_ln(OilPrice-2)`+ t
               +Month1 + Month2 + Month3 + Month4 + Month5 + Month6 + 
                 Month7 + Month8 + Month9 + Month10 + Month11, 
               data = Data_t_1)
summary(model02)

#算VIF
library(car)
vif(model02)

#BGtest
library(lmtest)
library(sandwich)
bgtest(model02, order = 1)
#執行Newey-West HAC修正，重新檢視所有變數的顯著性
coeftest(model02, vcov = vcovHAC(model02))

