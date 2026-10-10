# Regole di offuscamento per la release.
#
# Il codice Dart non passa da R8: e' gia' compilato in AOT. Qui si protegge solo il poco
# Java/Kotlin che serve al runtime e che R8 non puo' vedere referenziato, perche' viene
# istanziato per nome dal sistema o per riflessione.
#
# ⚑ ONNX Runtime (JNI) NON sta qui: lo tiene android/consumer-rules.pro di packages/micro_ocr
# (F12.1.9), che arriva con il plugin a ogni app che lo usa.

# flutter_local_notifications (in micro_core) deserializza con Gson, per riflessione sui nomi
# dei campi. Spending Review non pianifica notifiche, ma la libreria c'e' (micro_core).
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# Drift e sqlite3 caricano la libreria nativa per nome.
-keep class com.tekartik.** { *; }
