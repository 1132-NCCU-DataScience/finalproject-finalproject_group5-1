import pandas as pd
import numpy as np

# === Config ===
INPUT_CSV = 'data\input_v2.csv'
OUTPUT_CSV = 'data\prediction_in.csv'

FIRST_WEEKDAY_OF_YEAR = 2  # 0 = Monday, 6 = Sunday
START_DAY = 152  # June 1
END_DAY = 182  # September 30
HOURS = list(range(24))  # Hours in day

# === Load data ===
df = pd.read_csv(INPUT_CSV)

# === Get unique latitude/longitude combinations ===
unique_lat_lon = df[['latitude', 'longitude']].drop_duplicates().reset_index(drop=True)

# === Compose grid ===
rows = []
record_id = 0

for _, row in unique_lat_lon.iterrows():
    lat = row['latitude']
    lon = row['longitude']
    
    for day in range(START_DAY, END_DAY + 1):  # day_of_year from 152 to 273
        weekday = (FIRST_WEEKDAY_OF_YEAR + day - 1) % 7
        
        for hour in HOURS:
            seconds_of_day = hour * 3600
            
            rows.append({
                'record_id': record_id,
                'latitude': lat,
                'longitude': lon,
                'day_of_year': day,
                'seconds_of_day': seconds_of_day,
                'hour': hour,
                'weekday': weekday
            })
            
            record_id += 1

# === Create DataFrame ===
output_df = pd.DataFrame(rows)

# === Save to CSV ===
output_df.to_csv(OUTPUT_CSV, index=False)

print(f"Generated {len(output_df)} rows in {OUTPUT_CSV}.")
