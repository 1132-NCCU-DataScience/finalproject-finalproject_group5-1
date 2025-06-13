import pandas as pd

# === Config ===
INFO_FILE = 'data/prediction_in.csv'  # your input file
PRED_FILE = 'inference_outputs/CatBoost_final.pkl_predictions.csv'

# === Load base info ===
df_info = pd.read_csv(INFO_FILE)

# === Load prediction CSV ===
df_pred = pd.read_csv(PRED_FILE)

# === Bin labels ===
total_bin_labels = [f'CatBoost_final.pkl_pred_{i}' for i in range(0, 17)]
rent_bin_labels  = [f'CatBoost_final.pkl_pred_{i}' for i in range(17, 34)]
return_bin_labels = [f'CatBoost_final.pkl_pred_{i}' for i in range(34, 51)]

# === Helper: map bin index to lower bound ===
def index_to_value(idx, step_size=5, n_bins=17):
    if idx == n_bins - 1:
        return 80
    else:
        return idx * step_size

# === Process total ===
one_hot_total = df_pred[total_bin_labels]
idx_total = one_hot_total.idxmax(axis=1).apply(lambda col: total_bin_labels.index(col))
df_pred['total'] = idx_total.apply(lambda idx: index_to_value(idx))

# === Process rent ===
one_hot_rent = df_pred[rent_bin_labels]
idx_rent = one_hot_rent.idxmax(axis=1).apply(lambda col: rent_bin_labels.index(col))
df_pred['rent'] = idx_rent.apply(lambda idx: index_to_value(idx))

# === Process return ===
one_hot_return = df_pred[return_bin_labels]
idx_return = one_hot_return.idxmax(axis=1).apply(lambda col: return_bin_labels.index(col))
df_pred['return'] = idx_return.apply(lambda idx: index_to_value(idx))

# === Build merged DataFrame ===
df_final = df_info.merge(df_pred[['record_id', 'total', 'rent', 'return']], on='record_id')

# === Save merged CSV ===
df_final.to_csv('merged_final_output.csv', index=False)

print('Done. Saved to merged_final_output.csv')
