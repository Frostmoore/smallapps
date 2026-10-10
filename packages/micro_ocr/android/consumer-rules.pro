# micro_ocr: regole R8 applicate all'app che include il plugin.
# ☠ ONNX Runtime chiama le classi Java dal codice nativo (JNI) per nome: se R8 le rinomina o
# le toglie, l'OCR muore SOLO nella build di release (develop_microapps.md §10, F12.1.16 punto 12).
-keep class ai.onnxruntime.** { *; }
-keepclasseswithmembernames class * { native <methods>; }
