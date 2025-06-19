from io import BytesIO

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
bird_labels = load_labels("label.csv")
genus_labels = load_labels("genus.csv")
family_labels = load_labels("family.csv")
order_labels = load_labels("order.csv")



def classify_bird(audio_data):
    # Load audio directly from raw bytes
    waveform, sr = librosa.load(BytesIO(audio_data), sr=32000, mono=True)

    target_length = 5 * 32000
    if len(waveform) < target_length:
        waveform = np.pad(waveform, (0, target_length - len(waveform)), mode='constant')
    else:
        waveform = waveform[:target_length]

    # Run inference
    waveform_batch = np.expand_dims(waveform, axis=0)
    model_outputs = model.infer_tf(waveform_batch)

    # Extract raw logits
    label_logits = model_outputs['label'].numpy()[0]
    label_probs = tf.nn.softmax(label_logits).numpy()
    top_1_index_label = np.argmax(label_probs)

    order_logits = model_outputs['order'].numpy()[0]
    order_probs = tf.nn.softmax(order_logits).numpy()
    top_1_index_order = np.argmax(order_probs)

    family_logits = model_outputs['family'].numpy()[0]
    family_probs = tf.nn.softmax(family_logits).numpy()
    top_1_index_family = np.argmax(family_probs)

    genus_logits = model_outputs['genus'].numpy()[0]
    genus_probs = tf.nn.softmax(genus_logits).numpy()
    top_1_index_genus = np.argmax(genus_probs)

    bird_genus = genus_labels.get(top_1_index_genus, "Unknown Bird")
    bird_family = family_labels.get(top_1_index_family, "Unknown Bird")
    bird_order = order_labels.get(top_1_index_order, "Unknown Bird")

    bird_name = bird_labels.get(top_1_index_label, "Unknown Bird")
    print(f"🦜 {bird_name} - probability: {label_probs[top_1_index_label]:.4f}")
    return bird_name, label_probs[top_1_index_label], bird_genus, bird_family, bird_order
