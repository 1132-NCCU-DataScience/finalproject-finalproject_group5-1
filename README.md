[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/HR2Xz9sU)
# Group5 RideTime: Enhancing Bike Availability Through Statistical Modeling of Usage and Environmental Factors
YouBike in Taiwan faces operational challenges due to uneven bike distribution during peak hours, causing user dissatisfaction. This study uses historical data and predictive models, considering factors like temperature and humidity, to improve bike availability forecasts. Enhanced forecasting allows for better bike redistribution, increasing service reliability and ridership. Optimizing operations can offset over 16,000 tons of CO₂ annually, translating to NT$45 million in carbon credits, thus providing significant environmental and societal benefits.
# poster
results/this is IT.png

## Contributors
|組員|系級|學號|工作分配|
|-|-|-|-|
|林昱安|資科碩一|xxxxxxxxx|團隊的中流砥柱，一個人打十個| 
|陳子昊|資科博一|113761501|團隊的中流砥柱，一個人打十個|
|謝舜卿|教育碩一|xxxxxxxxx|團隊的中流砥柱，一個人打十個|
|楊智博|資科碩二|xxxxxxxxx|團隊的中流砥柱，一個人打十個|

## Quick start
Please provide an example command or a few commands to reproduce your analysis, such as the following R script:
```R
To run, simply run initial_code.py
```

## Folder organization and its related description
idea by Noble WS (2009) [A Quick Guide to Organizing Computational Biology Projects.](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424) PLoS Comput Biol 5(7): e1000424.

### docs
* Your presentation, 1132_DS-FP_groupID.ppt/pptx/pdf (i.e.,1132_DS-FP_group1.ppt), by **06.10**
* Any related document for the project, i.e.,
  * discussion log
  * software user guide


---

## Data Collection

This project integrates multiple data sources to predict bike availability in Taipei’s YouBike system. We collected real-time and historical YouBike station data from **Taipei City Open Data** and **Transport Data eXchange (TDX)**, providing minute-level bike availability and detailed station information. Additionally, we used **OpenWeather** data to obtain hourly records of **temperature** and **humidity**, allowing us to incorporate environmental factors into our models. The dataset spans a **30-day period** from April to May and includes over **5 million observations** of bike activity and **337k weather records**. To merge these sources effectively, we processed timestamps and matched each YouBike station to its nearest weather observation station using the **Haversine distance formula**.

---

## Data Processing

After initial collection, the data underwent several processing steps to ensure quality and consistency. We removed rows with missing values, reducing the dataset from over **5 million** to approximately **4.33 million** observations. We then extracted temporal features such as **hour**, **weekday**, and **date**. To better model cyclical patterns in bike usage, both **hour** and **weekday** were encoded using **sinusoidal (sin/cos) transformations**. In addition to time-based features, we included spatial features: **district** and **location name**, which were one-hot encoded to reflect local differences in bike demand. Exploratory analysis highlighted that bike availability varied by district, consistent with variations in land use and station density across Taipei.

---

## Feature Selection

We performed exploratory data analysis to inform our feature selection. Temporal usage patterns showed clear **hourly fluctuations** and differences between **weekdays and weekends**. Moreover, changes in **temperature** and **humidity** correlated with shifts in rental and return patterns — hotter and more humid days generally led to more bikes being rented but fewer being returned. However, individual feature correlations with availability were relatively low, suggesting that **multi-feature modeling** would be necessary. Based on these insights, we selected a set of **temporal (hour, weekday)**, **spatial (longitude, latitude, district, location type)**, and **environmental (temperature, humidity)** features to build our predictive models.

---

## Prediction

We framed the bike availability prediction as a **multi-class classification** task, where the goal is to predict the number of rentable and returnable bikes in intervals of **5-bike units**. We experimented with four **tree-based ensemble models** — **Random Forest**, **CatBoost**, **XGBoost**, and **LightGBM** — using spatial, temporal, climatological, and textual features as inputs. Our evaluation metric was **AUC (Area Under the Curve)**. Results showed that CatBoost consistently achieved the best performance across tasks. Ablation studies demonstrated that **spatial and temporal features alone** provided robust predictive power, though adding **location name** significantly improved results in low-data scenarios. These findings suggest that **tree-based models** are highly effective for operational forecasting in public bike systems, enabling better bike redistribution strategies and contributing to both **user satisfaction** and **environmental impact**.

---

## Impact

This work demonstrates the potential of **data-driven optimization** to improve the efficiency and sustainability of public bike-sharing systems. By enhancing operational forecasting, the models we developed can help increase user satisfaction, reduce operational costs, and contribute to substantial **CO₂ emission reductions** — supporting both **urban mobility** and **environmental goals**.


* Is the improvement significant?

## References
* Packages you use
* Related publications
