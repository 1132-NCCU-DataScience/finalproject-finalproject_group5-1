import joblib
import os

# === Config ===
MODEL_DIR = 'website\\model'
OUTPUT_DIR = 'website\\model'

os.makedirs(OUTPUT_DIR, exist_ok=True)

# === List of Model Files ===
model_files = [f for f in os.listdir(MODEL_DIR) if f.endswith('_model.pkl')]

# === Convert Each Model ===
for model_file in model_files:
    model_name = model_file.replace('_model.pkl', '')
    print(f"Loading model: {model_name}")

    model = joblib.load(os.path.join(MODEL_DIR, model_file), mmap_mode='r')

    # Check if it's a MultiOutputClassifier
    if hasattr(model, "estimators_"):
        print(f"Model {model_name} is MultiOutputClassifier with {len(model.estimators_)} estimators.")

        # Save each estimator
        for i, estimator in enumerate(model.estimators_):
            cbm_output_path = os.path.join(OUTPUT_DIR, f"{model_name}_output{i}.cbm")
            estimator.save_model(cbm_output_path, format="cbm")
            print(f"Saved estimator {i} to: {cbm_output_path}")
    else:
        # Single model (not MultiOutputClassifier)
        cbm_output_path = os.path.join(OUTPUT_DIR, f"{model_name}.cbm")
        model.save_model(cbm_output_path, format="cbm")
        print(f"Saved {model_name} as CBM to: {cbm_output_path}")
