EUI Workshop — Day 1, hands-on
PCA and hierarchical cluster modelling on the European ALMP policy mix
==========================================================================

What is in this folder
----------------------
- 00_fetch_oecd_lmp.R   pulls the data from the OECD SDMX API and writes
                        almp_data.csv. Re-run any time to refresh.
- 01_almp_pca_hc.R      the analysis script you will run in the session.
- almp_data.csv         pre-cleaned data, 28 European countries × 6 ALMP
                        categories, 2018-2022 average.
- README.txt            this file.

Data source
-----------
OECD Labour Market Programmes database (DSD_LMP@DF_LMP), public expenditure
as % of GDP, averaged 2018-2022, then converted to country-level spending
shares (each row sums to 100). Active categories only:
    pes_admin            (LMP_10)  PES and administration
    training             (LMP_20)  training
    emp_incentives       (LMP_40)  hiring and employment incentives
    supported_emp        (LMP_50)  supported and sheltered employment
    direct_job_creation  (LMP_60)  direct job creation
    start_up_incentives  (LMP_70)  start-up incentives

Setup (do this once, before the session)
----------------------------------------
1. Open RStudio.
2. File > New Project > Existing Directory > pick this folder.
3. Install the packages:

       install.packages(c("tidyverse", "factoextra", "cluster"))

4. Open 01_almp_pca_hc.R. Run it line by line with Ctrl/Cmd + Enter.

If you also want to reproduce the data pull from scratch, run
00_fetch_oecd_lmp.R first. It rewrites almp_data.csv from the OECD API.

Note on compositional data
--------------------------
Shares that sum to a constant (100) induce mechanical correlations. For
published research consider log-ratio (Aitchison) transforms before PCA.
For this workshop we keep it simple.

If you get stuck
----------------
- "could not find function fviz_eig"
    -> factoextra not loaded: library(factoextra)
- "cannot open file 'almp_data.csv'"
    -> working directory is wrong: Session > Set Working Directory > To
       Source File Location.
- the dendrogram looks like a chain
    -> you used method="single" -- switch back to "complete" or "ward.D2"

Bonus tasks at the bottom of the script are open-ended. Work at your pace.
