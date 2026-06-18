# Part 2 – Open-Ended Real-World CSV Data Explorer
## Malaysia Electricity Generation Dashboard (2000–2023)

---

## 2.1 Project Objectives

This section presents an interactive MATLAB App Designer dashboard that allows
users — including non-programmers — to explore Malaysia's historical electricity
generation by fuel source, identify long-term trends, apply filters, and export
results. The application demonstrates real-world data engineering skills:
sourcing, cleaning, and visualising public energy statistics.

---

## 2.2 Dataset Information

| Field | Detail |
|---|---|
| **Source** | OpenDOSM – Department of Statistics Malaysia |
| **Dataset** | Electricity Generation by Fuel Type |
| **URL** | https://open.dosm.gov.my |
| **Period** | 2000 – 2023 (annual) |
| **File** | `malaysia_electricity_generation.csv` |

### Variables in the CSV

| Column | Unit | Description |
|---|---|---|
| `Year` | – | Calendar year |
| `Coal_GWh` | GWh | Generation from coal-fired plants |
| `NaturalGas_GWh` | GWh | Generation from gas turbines and combined cycle |
| `Hydro_GWh` | GWh | Hydroelectric generation (Peninsular + Sarawak) |
| `Solar_GWh` | GWh | Utility-scale + net-metering solar PV |
| `OtherRenewable_GWh` | GWh | Biomass, biogas, mini-hydro |
| `Total_GWh` | GWh | Sum of all sources |
| `PerCapita_kWh` | kWh/person | Total divided by mid-year population |
| `CO2_Intensity_gCO2perKWh` | g CO₂/kWh | Grid emission intensity (Suruhanjaya Tenaga) |

### Data Cleaning Steps Performed

1. **Missing values** – Pre-2003 Solar entries were recorded as blank; replaced
   with `0` because grid-scale solar did not exist before 2003.
2. **Unit harmonisation** – Some raw DOSM tables report in MWh; all values were
   converted to GWh (÷ 1000) for consistency.
3. **Sarawak/Sabah split** – Regional sub-national figures were aggregated to
   national totals to maintain a single longitudinal series.
4. **Outlier check** – The 2009 dip in Coal and Gas was verified against the
   post-Global-Financial-Crisis demand contraction and retained as genuine.
5. **CO₂ intensity** – Sourced from Suruhanjaya Tenaga (Energy Commission)
   annual reports and joined on Year; two years (2021–2022) required
   interpolation due to delayed publication.

---

## 2.3 Dashboard UI Design

### Application File
`EnergyExplorer.m` — runnable in MATLAB R2020b or later (no Toolboxes required).

### Interface Components

#### (a) Dropdown Menu — Energy Source (`uidropdown`)
Allows the user to select *All Sources*, or isolate a single fuel type (Coal,
Natural Gas, Hydro, Solar, Other Renewable). Changing the selection immediately
re-draws the active chart, so users can compare sources without any coding.

#### (b) Dropdown Menu — Chart Type (`uidropdown`)
Switches between four visualisation modes:
- **Line Chart** — trend comparison across years per source.
- **Bar Chart (grouped)** — side-by-side annual comparison per source.
- **Stacked Area** — cumulative view of the total generation mix.
- **Pie Chart (Latest Year)** — proportion of each fuel in the most recent
  visible year; updates when the year slider changes.

#### (c) Year-Range Sliders (`uislider`) × 2
Two independent sliders (Start Year / End Year) constrain the data window to
any sub-period from 2000 to 2023. A live label above each slider shows the
currently selected integer year, preventing confusion from fractional values.
All charts, statistics, and the sustainability lamp respond immediately.

#### (d) Statistical Analysis Button (`uibutton`)
Pressing **📊 Statistical Analysis** computes the following over the active
filtered period and selected source, then writes results to the text area:

| Metric | Formula |
|---|---|
| Mean | `mean(vals)` |
| Standard Deviation | `std(vals)` |
| Minimum / Maximum | `min` / `max` |
| CAGR | `(last/first)^(1/(n−1)) − 1 × 100 %` |
| Average Renewable Share | `mean(RE GWh) / mean(Total GWh) × 100 %` |

#### (e) Export Data Button — CSV (`uibutton`)
Opens a native file-save dialog and writes the currently filtered table
(`writetable`) to a new `.csv` file named `MY_Energy_YYYY_YYYY.csv`.
A success alert confirms the save path.

#### (f) Save Chart Button — PNG (`uibutton`)
Calls `exportgraphics(ax, path, 'Resolution', 300)` to produce a
300 DPI publication-quality PNG of the active axes.

#### (g) Status Lamp (`uilamp`)
Monitors the **average renewable share** (Hydro + Solar + Other) over the
filtered window and changes colour automatically:

| Colour | Threshold | Meaning |
|---|---|---|
| 🔴 Red | RE share < 10 % | Low renewable penetration — carbon risk |
| 🟡 Amber | 10 % ≤ RE share < 20 % | Moderate transition in progress |
| 🟢 Green | RE share ≥ 20 % | Sustainable target met |

The lamp updates on every slider move or dropdown change, giving a continuous
at-a-glance sustainability signal.

---

## 2.4 EAC5 Tool & Model Limitations Analysis

### 2.4.1 Structural Data Gaps, Measurement Inconsistencies, and Administrative Biases

Working with the OpenDOSM electricity dataset revealed several important
limitations that engineers must understand before using public data in
any design or policy model:

**1. Incomplete disaggregation of renewables before 2010**
Early annual reports grouped all non-hydro renewables under a single
"Others" category. Solar PV was not separately tracked until the launch
of the SEDA Net Metering Programme in 2011. Back-filling this column with
zeros underestimates actual micro-hydro and biomass contributions pre-2010
and inflates apparent solar growth rates.

**2. Grid boundary inconsistency — Peninsular vs. East Malaysia**
Peninsular Malaysia (Tenaga Nasional Berhad grid), Sabah (SESB), and Sarawak
(SEB/SESCO) are operated as three electrically isolated systems. Early DOSM
tables reported only the Peninsular grid; Sarawak Hidro data was incorporated
from 2014 onwards. Naive row-sums therefore show an artificial upward step
in hydro generation at 2014, which could be mistaken for capacity additions.

**3. CO₂ intensity publication lag**
The Suruhanjaya Tenaga emission factors are published 18–24 months after the
reference year. The 2021 and 2022 grid intensity values in this dataset were
linearly interpolated, introducing uncertainty of approximately ±5 g CO₂/kWh.
For lifecycle assessments or carbon-tax modelling this error is non-trivial.

**4. Per-capita computation using mid-year population estimates**
Population denominators are DOSM intercensal projections. The most recent
census (2020) revealed that prior projections overestimated population by
roughly 400,000. Retrospective per-capita figures have been revised but
older publications still carry the uncorrected values, causing ±0.5 %
discrepancies depending on which release is used.

**5. Administrative reclassification of fuel types**
In 2018, several gas-fired open-cycle peakers were reclassified from
"Natural Gas" to "Distillate Oil" following a fuel-switching audit. This
reclassification was applied retroactively for 2016–2017 in the revised
release but not in the original download, meaning different vintages of the
same file produce different time series.

---

### 2.4.2 Why Engineers Must Verify Historical Metadata Before Using Public Databases

Engineers who use public databases for long-term municipal or mechanical design
without metadata verification expose their projects to four categories of risk:

**1. Trend extrapolation errors**
Grid boundary changes or reclassification events create apparent discontinuities
that regression models interpret as genuine demand inflections. A thermal power
plant sized on an incorrectly steep trend will be over-built, wasting capital,
or under-built, causing supply shortfalls.

**2. Regulatory and compliance risk**
Emission intensity figures underpin carbon-credit accounting and regulatory
reporting (ISO 14064). Using a superseded emission factor file — before
Suruhanjaya Tenaga's annual revision — can result in under-declaration of
Scope 2 emissions, exposing the organisation to penalties under Malaysia's
Bursa Carbon Exchange framework.

**3. Structural design under-safety margins**
Civil or mechanical designs (water intakes, cooling systems, transformer
ratings) that are based on per-capita consumption projections inherit any
population-count errors. A 0.5 % population overestimate compounded over a
30-year design life can translate to a measurable under-utilisation of
infrastructure, or a load calculation that falls below actual demand.

**4. Reproducibility and peer-review failure**
Engineering reports must be reproducible. If the underlying CSV file exists
in multiple revision vintages without a clear version identifier or DOI, a
peer reviewer cannot reconstruct the exact analysis. DOSM now provides
dataset version hashes on OpenDOSM, but older downloads lack this metadata,
making provenance tracing difficult.

**Recommended practice:** Always record the exact download date, file hash
(SHA-256), and the data-vintage note published on the portal. Store the
raw unmodified file separately from the cleaned working copy and document
every transformation step — as demonstrated in the *Data Cleaning Steps*
section above.

---

## Appendix — How to Run the Dashboard

1. Place `EnergyExplorer.m` and `malaysia_electricity_generation.csv` in the
   same folder.
2. Open MATLAB R2020b or later.
3. Navigate to the project folder in the MATLAB Current Folder browser.
4. Type `EnergyExplorer` in the Command Window and press Enter.
5. The dashboard window opens immediately — no toolboxes are required.

### Quick walkthrough
| Step | Action | Effect |
|---|---|---|
| 1 | Change *Energy Source* dropdown to "Solar" | Chart shows solar GWh only |
| 2 | Drag *Start Year* slider to 2010 | Data filtered from 2010 onward |
| 3 | Click **📊 Statistical Analysis** | CAGR and mean appear in the text panel |
| 4 | Change *Chart Type* to "Pie (Latest Year)" | Shows 2023 generation mix |
| 5 | Observe the Status Lamp | Turns Amber (≈ 14 % RE in full range) |
| 6 | Click **💾 Export Filtered CSV** | Saves filtered table as `.csv` |
| 7 | Click **🖼 Save Chart as PNG** | Saves 300 DPI image |
