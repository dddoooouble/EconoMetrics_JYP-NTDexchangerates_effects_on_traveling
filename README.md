# EconoMetrics_JYP-NTDexchangerates_effects_on_traveling

## 研究主題

本專題研究日台匯率變動是否會影響日人來台觀光人數，主題為 **The Effect of the JPY/TWD Exchange Rate on Japanese Tourist Arrivals to Taiwan**。

這個倉庫目前保留本組最後整理後的版本，只放：

- 簡報
- 書面報告
- R 程式碼
- 讓 LaTeX 原始檔可以正常開啟的 `figures/` 與 `tables/` 支援檔

課堂用資料檔、參考文獻 PDF、答辯備忘稿等未一併放入這次的 GitHub 版本。

## 組員分工

- B12204033 地質三 施卲：Regression-analysis support, slide preparation, written-report preparation, figure and table preparation, oral-presentation support
- B13303042 經濟二 劉孟暉：Regression analysis, literature review, final review, oral-presentation support, error checking
- B11103009 經濟四 吳祐儀：Topic development, data preprocessing, main oral presentation
- B13303151 經濟二 葉禹辰：Topic development, data preprocessing
- B13303054 經濟二 邱薇臻：Topic development, data preprocessing
- B11303130 經濟四 陳碩錨：Topic development, data preprocessing

## 最終版檔案

- `Japan_Taiwan_Tourism_Beamer.pdf`
- `Japan_Taiwan_Tourism_Beamer.tex`
- `Japan_Taiwan_Tourism_Report.pdf`
- `Japan_Taiwan_Tourism_Report.tex`
- `run_models.R`
- `模型回歸.R`
- `generate_latex_tables.R`
- `figures/`
- `tables/`

其中：

- `Japan_Taiwan_Tourism_Report.tex` / `.pdf` 是目前最完整的書面報告定稿。
- `Japan_Taiwan_Tourism_Beamer.tex` / `.pdf` 是目前最完整的簡報定稿。
- `run_models.R` 是目前最完整的重跑分析腳本。
- `模型回歸.R` 是原始基礎回歸腳本。
- `generate_latex_tables.R` 是輔助輸出 LaTeX 表格的腳本。

## 簡報與報告大綱

1. 研究背景
2. 文獻回顧
3. 資料與變數
4. ADF 檢定與模型設定
5. 描述性證據
6. 回歸結果
7. 穩健性與詮釋
8. 結論

## 主要分析結果

- 靜態模型中，`Δln(FX_t)` 係數為 `-0.991`，HAC 標準誤為 `0.559`，在 `10%` 水準邊際顯著。
- 動態模型中，當期 `Δln(FX_t)` 係數為 `-1.032`，HAC 標準誤為 `0.536`，同樣只在 `10%` 左右邊際顯著。
- 動態模型的落後一期來台旅客人數係數為 `0.505`，在 `1%` 水準顯著，顯示觀光需求具有明顯持續性。
- `ln(JIPI_t)` 在動態模型中為正且在 `5%` 水準顯著，表示日本景氣條件對日人來台觀光有一定關聯。
- 模型 1 與模型 2 的調整後 `R^2` 分別為 `0.8805` 與 `0.9044`，動態模型整體配適度較高。
- 時間趨勢與月別虛擬變數是最穩定的解釋因素，代表長期成長與季節性比單月匯率波動更穩定。
- 匯率係數為負不代表因果關係已被證明，較合理的解讀是樣本期間內存在負向關聯，可能反映替代旅遊地、避險貨幣效果、遺漏變數或旅行規劃落差。

## 研究限制

- 樣本期間限制在 `2010-01` 到 `2019-12`，未納入疫情後結構變化。
- 因為 `FX` 與 `OilPrice` 採一階差分，模型主要反映短期效果，無法直接解釋長期彈性。
- 未完整控制機票價格、航班供給、假期、天災、競爭目的地價格與政策事件。
- Breusch-Godfrey 檢定在兩個模型中仍顯示殘差序列相關，因此推論依賴 Newey-West HAC 修正。
- 動態模型的最大 VIF 為 `9.75`，顯示部分落後變數之間存在較高共線性，個別係數解讀需要保守。
- 目前模型是關聯分析，不是具識別策略的因果推論設計。

## 重新執行方式

如果要在本地重跑回歸，請先把 `Data-t=1.xlsx` 放在專案根目錄，再執行：

```bash
Rscript run_models.R
```

如需重新編譯書面報告或簡報，建議使用 `xelatex`：

```bash
latexmk -xelatex Japan_Taiwan_Tourism_Report.tex
latexmk -xelatex Japan_Taiwan_Tourism_Beamer.tex
```

## 備註

本組最終工作流程是 **LaTeX + R scripts**。目前沒有另外獨立整理成最終版 `.Rmd`，因此這次 GitHub 版本以上傳實際使用的 `.R` 腳本為主。
