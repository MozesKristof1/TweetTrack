import tensorflow as tf
import numpy as np
import librosa
import os

def load_labels(labels_path):
    bird_labels = {}
    with open(labels_path, 'r') as f:
        for idx, line in enumerate(f.readlines()):
            bird_labels[idx] = line.strip()
    return bird_labels

# Load the model
SAVE_PATH = "saved_model/"
if os.path.exists(SAVE_PATH):
    print(f"✅ Loading model from {SAVE_PATH}...")
    model = tf.saved_model.load(SAVE_PATH)
    print(f"✅ Model loaded successfully!")
else:
    print(f"❌ Model not found at {SAVE_PATH}. Please ensure the model is copied to this location.")

# Load bird labels
LABELS_PATH = "label.csv"
bird_labels = load_labels(LABELS_PATH)

def classify_bird(audio_path):
    # Load and preprocess the audio
    waveform, sr = librosa.load(audio_path, sr=32000, mono=True)

    target_length = 5 * 32000
    if len(waveform) < target_length:
        waveform = np.pad(waveform, (0, target_length - len(waveform)), mode='constant')
    else:
        waveform = waveform[:target_length]

    # Run inference
    model_outputs = model.infer_tf(waveform[np.newaxis, :])

    # Extract raw logits
    label_logits = model_outputs['label'].numpy()[0]
    label_probs = tf.nn.softmax(label_logits).numpy()

    top_1_index = np.argmax(label_probs) + 1 

    print(f"\n🦜 **Best Predicted Bird**")
    bird_name = bird_labels.get(top_1_index, "Unknown Bird")
    print(f"🦜 {bird_name} - probability: {label_probs[top_1_index]:.4f}")

classify_bird("13 White-breasted Nuthatch Song.mp3")
