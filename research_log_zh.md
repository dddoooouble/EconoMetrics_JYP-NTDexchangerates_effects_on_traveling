# 計量報告工作紀錄（中文）

## 1. 結論先說

有，這次的迴歸分析是依照你提供的**真實資料檔**去改、去跑、去產生表格的，不是我憑空編的。

本次實際估計使用的主資料檔是：

- [資料.xlsx](/Users/ss/Desktop/Inbox/EconoReport/資料.xlsx)

這個檔案已經整理好月資料與主要變數，我的 R 腳本是直接讀這份檔案來做回歸、摘要統計、穩健性檢查與表格輸出。

## 2. 我們實際使用了哪些資料

### 2.1 主要估計資料

使用檔案：

- [資料.xlsx](/Users/ss/Desktop/Inbox/EconoReport/資料.xlsx)

檔內主要欄位：

- `期間t`
- `Tourist`
- `新台幣USD/TWD`
- `日圓USD/JPY`
- `日圓兌新台幣JPY/NTD(FX)`
- `ln(FX)`
- `JIPI`
- `ln(JIPI)`
- `OilPrice`
- `ln(OilPrice)`
- `t`
- `Month1` 到 `Month11`

### 2.2 原始來源對應

你後來補充的來源，我已經納入報告敘述：

- 日本來台觀光人數：
  [交通部觀光署觀光統計資料庫](https://stat.taiwan.net.tw/inboundSearch)
- 日台匯率：
  [Investing.com JPY/TWD](https://uk.investing.com/currencies/jpy-twd)
- 布蘭特原油價格：
  [FRED POILBREUSDM](https://fred.stlouisfed.org/series/POILBREUSDM)
- 日本工業生產指數：
  [FRED JPNPRINTO01IXOBM](https://fred.stlouisfed.org/series/JPNPRINTO01IXOBM)

### 2.3 一個很重要的現實限制

雖然研究設計上你希望以 `2009–2019` 為主，這是合理的，我也照這個方向做；但目前提供給我的整理後資料實際起點是：

- `2009M10`

終點是：

- `2019M12`

所以**實際回歸樣本**是：

- `2009M10–2019M12`

這點我有在英文報告中明確寫出來，沒有假裝成完整 `2009M1–2019M12` 或 `2008–2019`。

## 3. 我們實際改了哪些檔案

### 3.1 分析腳本

- [run_analysis.R](/Users/ss/Desktop/Inbox/EconoReport/run_analysis.R)

這是本次最重要的重跑腳本，負責：

- 讀取 `資料.xlsx`
- 建立 `ln_tourist`
- 建立匯率與旅遊人數的落後期
- 跑主回歸與穩健性回歸
- 匯出 LaTeX 表格
- 匯出圖
- 產生假設檢定表、診斷表、ADF-style 檢查表

### 3.2 英文 LaTeX 主文

- [taiwan_japan_fx_tourism_report_en.tex](/Users/ss/Desktop/Inbox/EconoReport/taiwan_japan_fx_tourism_report_en.tex)

我對它做了這些主要修改：

- 重寫成更像正式 econometrics final paper 的結構
- 加入摘要統計、主回歸、robustness、diagnostic tests、spurious regression checks
- 把你後來補充的資料來源直接寫入 data section
- 把 `11 個月份 dummy`、`油價`、`日本工業生產指數` 的經濟直覺寫進去
- 把「金融海嘯」與「疫情」要拆開處理的原因寫進 methodology / data 討論
- 把 ScienceDirect 論文放進 literature review
- 把兩個 GitHub repo 改成 forecasting / method extension 參考，而不是主學術證據

### 3.3 自動產出的表格與圖

位於 `output/`：

- [summary_statistics.tex](/Users/ss/Desktop/Inbox/EconoReport/output/summary_statistics.tex)
- [correlation_matrix.tex](/Users/ss/Desktop/Inbox/EconoReport/output/correlation_matrix.tex)
- [regression_table.tex](/Users/ss/Desktop/Inbox/EconoReport/output/regression_table.tex)
- [stata_full_model.tex](/Users/ss/Desktop/Inbox/EconoReport/output/stata_full_model.tex)
- [stata_dynamic_model.tex](/Users/ss/Desktop/Inbox/EconoReport/output/stata_dynamic_model.tex)
- [robustness_table.tex](/Users/ss/Desktop/Inbox/EconoReport/output/robustness_table.tex)
- [hypothesis_tests.tex](/Users/ss/Desktop/Inbox/EconoReport/output/hypothesis_tests.tex)
- [diagnostic_tests.tex](/Users/ss/Desktop/Inbox/EconoReport/output/diagnostic_tests.tex)
- [adf_tests.tex](/Users/ss/Desktop/Inbox/EconoReport/output/adf_tests.tex)
- [tourism_fx_index.pdf](/Users/ss/Desktop/Inbox/EconoReport/output/tourism_fx_index.pdf)

### 3.4 最新 PDF

- [taiwan_japan_fx_tourism_report_en.pdf](/Users/ss/Desktop/Inbox/EconoReport/taiwan_japan_fx_tourism_report_en.pdf)

## 4. 我們實際跑了哪些模型

### 4.1 主模型

1. `Bivariate model`

- `ln(Tourist)` 對 `ln(FX)`

2. `Full model`

- `ln(Tourist)` 對：
  - `ln(FX)`
  - `ln(JIPI)`
  - `ln(OilPrice)`
  - `t`
  - `Month1` 到 `Month11`

3. `Dynamic model`

- 在 full-type specification 裡加入：
  - `ln_tourist_lag1`

### 4.2 穩健性模型

4. `Distributed lag model`

- 加入：
  - `ln(FX)`
  - `lnFX_lag1`
  - `lnFX_lag2`

5. `First-difference model`

- 用變動量：
  - `d_ln_tourist`
  - `d_ln_fx`
  - `d_ln_jipi`
  - `d_ln_oil`

## 5. 主要實證結果摘要

### 5.1 主回歸

#### Model (1) Bivariate

- 匯率係數：約 `-1.454`
- 顯著
- `R^2 ≈ 0.356`

這個結果方向反直覺，所以我沒有直接把它當成真實經濟效果，而是視為可能有遺漏變數或趨勢偏誤。

#### Model (2) Full model

- 匯率係數：約 `0.119`
- 不顯著
- `R^2 ≈ 0.891`

這代表一旦控制：

- 日本工業生產
- 油價
- 線性趨勢
- 11 個月份 dummy

之後，匯率效果就變弱很多。

#### Model (3) Dynamic model

- `ln_tourist_lag1 ≈ 0.816`
- 高度顯著

這表示旅遊人數有很強的持續性，前一期的旅遊量對本期影響很大。

### 5.2 穩健性結果

- 分配落後模型中：
  - 當期匯率、lag1、lag2 都不穩健
  - 累積匯率效果也不顯著
- 一階差分模型中：
  - 匯率變動也不顯著
  - 日本工業生產變動較有訊號

## 6. 我們做了哪些 hypothesis tests

我有另外做表，不只看單一係數：

- 匯率係數是否為 0
- 11 個月份 dummy 是否 jointly significant
- 匯率 + 季節 dummy 是否 jointly significant
- 日本工業生產與油價是否 jointly significant
- 油價係數是否為 0
- 落後匯率是否 jointly significant
- 動態模型中的 lagged tourist arrivals 是否有解釋力
- distributed lag 模型中匯率總效果是否為 0

目前結果大意：

- `月份效果` 很強，jointly significant
- `匯率單獨` 在完整模型中不顯著
- `lagged tourist arrivals` 很強
- `lagged FX terms` 不顯著
- `oil price` 有一些訊號，但不算非常穩

## 7. 我們做了哪些 reality check

這部分就是你說的 `reality check`，我整理成最重要幾條。

### 7.1 樣本 reality check

- 沒有假裝資料是 `2008–2019`
- 沒有假裝資料是完整 `2009–2019`
- 真正回歸樣本就是 `2009M10–2019M12`

### 7.2 資料 reality check

- 所有回歸都直接吃 `資料.xlsx`
- 沒有手動編 coefficient
- 沒有手動編 `R^2`
- 沒有手動編顯著性星號

### 7.3 模型 reality check

- 沒有把結果講成因果
- 報告用的是 `association` 的寫法
- 有加入季節 dummy，不是只跑一條超簡單時間序列
- 有加入油價與日本工業生產這兩個比較符合現實的控制變數

### 7.4 黑天鵝事件 reality check

我有把這件事明確分開處理：

- `COVID-19`
  - 是直接破壞邊境與跨境移動機制
  - 不能跟一般需求波動混為一談
- `金融海嘯`
  - 比較像景氣、所得、信心衝擊
  - 應該概念上和疫情分開

但因為目前資料從 `2009M10` 才開始，所以金融海嘯 dummy 的完整估計空間不夠，我有在報告裡誠實寫明。

### 7.5 假回歸 reality check

我有做：

- ADF-style unit-root checks
- residual stationarity checks

重點結果：

- `ln(FX)`、`ln(OilPrice)` 比較像有單根或趨勢型序列
- `ln_tourist` 與 `ln(JIPI)` 的 level behavior 較穩
- bivariate / full model 的 residual ADF-style 結果沒有顯示「一定是純粹假回歸」

但這不代表完全沒風險，因為：

- 序列相關仍然很強
- 異質變異存在
- 匯率係數在不同模型間不穩定

所以最後的報告結論是偏保守的。

### 7.6 診斷 reality check

我做了：

- Durbin-Watson
- Breusch-Godfrey
- Breusch-Pagan
- RESET

重點：

- 序列相關明顯存在
- 異質變異也存在
- 所以主表採用 `Newey-West standard errors`

這也是為什麼我沒有只給你最原始的 OLS 結果。

## 8. 哪些地方是「有做」，哪些是「概念上有寫但尚未真的估」

### 已經真的做了

- 真實資料回歸
- 季節 dummy
- 油價控制
- 日本工業生產控制
- dynamic model
- distributed lag
- first difference
- joint hypothesis tests
- diagnostic tests
- ADF-style 假回歸檢查
- Stata-like 表格

### 概念上有寫，但目前沒有真的完整估

- `2008–2019` 完整樣本
- 金融海嘯 dummy 的完整估計
- 真正的 `ARIMA/SARIMAX` 匯率預測延伸
- 航班數、票價、航空座位供給等更直接的運輸變數

## 9. 目前版本最誠實的說法

如果要一句話總結目前研究狀態，最準確的說法是：

> 我們已經根據真實月資料，完成一套正式的時間序列迴歸與穩健性分析；結果顯示季節性與動態持續性很重要，但匯率效果在控制趨勢、季節與總體條件後並不穩健。

## 10. 如果下一步要更強

最值得補的三件事：

1. 補到完整 `2009M1–2019M12` 或更早資料  
2. 加入更直接的航空供給變數  
3. 做真正的匯率 forecasting extension，例如 `ARIMA / SARIMAX`

