import tensorflow as tf

tflite_model_path = "/app/model.tflite"

interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input Details:")
for input_tensor in input_details:
    print(f"{input_tensor['name']}: {input_tensor['shape']}")

print("\nOutput Details:")
for output_tensor in output_details:
    print(f"{output_tensor['name']}: {output_tensor['shape']}")
