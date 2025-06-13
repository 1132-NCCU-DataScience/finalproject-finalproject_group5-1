import pandas as pd

# === Config ===
INPUT_CSV = 'data\input_v2.csv'
OUTPUT_CSV = 'unique_lat_lon.csv'

# === Load data ===
df = pd.read_csv(INPUT_CSV)

# === Extract latitude and longitude, drop duplicates ===
unique_lat_lon = df[['latitude', 'longitude']].drop_duplicates().reset_index(drop=True)

# === Save to CSV ===
unique_lat_lon.to_csv(OUTPUT_CSV, index=False)

print(f"Saved {len(unique_lat_lon)} unique latitude/longitude pairs to {OUTPUT_CSV}.")
