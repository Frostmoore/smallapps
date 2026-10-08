# Regole di offuscamento per la release.
#
# Il codice Dart non passa da R8: e' gia' compilato in AOT. Qui si protegge solo il poco
# Java/Kotlin che serve al runtime e che R8 non puo' vedere referenziato, perche' viene
# istanziato per nome dal sistema o per riflessione.

# flutter_local_notifications (in micro_core) deserializza i dettagli delle notifiche pianificate con Gson,
# che lavora per riflessione sui nomi dei campi. Offuscarli fa perdere tutte le notifiche
# gia' pianificate al primo aggiornamento dell'app.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# Drift e sqlite3 caricano la libreria nativa per nome.
-keep class com.tekartik.** { *; }
