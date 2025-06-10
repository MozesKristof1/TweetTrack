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

# def frame_audio(
#       audio_array: np.ndarray,
#       window_size_s: float = 5.0,
#       hop_size_s: float = 5.0,
#       sample_rate = 32000,
#       ) -> np.ndarray:
    
#     if window_size_s is None or window_size_s < 0:
#         return audio_array[np.newaxis, :]
#     frame_length = int(window_size_s * sample_rate)
#     hop_length = int(hop_size_s * sample_rate)
#     framed_audio = tf.signal.frame(audio_array, frame_length, hop_length, pad_end=True)
#     return framed_audio


# def ensure_sample_rate(waveform, original_sample_rate,
#                        desired_sample_rate=32000):
#     """Resample waveform if required."""
#     if original_sample_rate != desired_sample_rate:
#         waveform = tf.convert_to_tensor(waveform, dtype=tf.float32)
#         waveform = tfio.audio.resample(waveform, original_sample_rate, desired_sample_rate)
#     return desired_sample_rate, waveform


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


# def classify_bird(audio_data):
#     # Load audio directly from raw bytes
#     waveform, original_sr = librosa.load(BytesIO(audio_data), sr=None, mono=True)
    
#     # Ensure correct sample rate
#     desired_sr = 32000
#     sr, waveform = ensure_sample_rate(waveform, original_sr, desired_sr)
    
#     # Frame the audio into 5-second windows with no hop
#     window_size_s = 5.0
#     hop_size_s = 5.0
    
#     # Pad or trim to ensure we have at least one full frame
#     # target_length = int(window_size_s * desired_sr)
#     # if len(waveform) < target_length:
#     #     waveform = np.pad(waveform, (0, target_length - len(waveform)), mode='constant')
#     # else:
#     #     waveform = waveform[:target_length]
    
#     # Frame the audio
#     framed_audio = frame_audio(waveform, window_size_s, hop_size_s, desired_sr)
    
#     # Run inference on first frame (could also process all frames and average results)
#     model_outputs = model.infer_tf(framed_audio[0:1])
    
#     # Extract raw logits
#     label_logits, embeddings = model_outputs['label'].numpy()[0]
#     label_probs = tf.nn.softmax(label_logits).numpy()
    
#     top_1_index = np.argmax(label_probs)
#     bird_name = bird_labels.get(top_1_index, "Unknown Bird")
#     print(f"🦜 {bird_name} - probability: {label_probs[top_1_index]:.4f}")
    
#     return bird_name, label_probs[top_1_index]