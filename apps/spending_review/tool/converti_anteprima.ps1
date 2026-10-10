# Converte il video grezzo del simulatore nel formato delle anteprime dell'App Store.
#
#   pwsh tool/converti_anteprima.ps1        (dalla cartella apps/spending_review)
#
# Legge store/video/anteprima_sr_<lingua>.mov (scritto da tool/anteprima_app_store.sh sul Mac
# e copiato qui) e scrive store/video/anteprima-886x1920-<lingua>.mp4.
#
# ☠ Formato di Apple per iPhone 6,5"/6,9" in verticale: 886x1920, 30 fps costanti, H.264, e
#   una traccia audio stereo AAC anche se muta: senza, App Store Connect rifiuta il file.
#   Il simulatore registra 1320x2868 a frame rate variabile: si scala a 886 di larghezza
#   (1925 di altezza) e si tagliano i 5 pixel in eccesso, ugualmente sopra e sotto.
foreach ($l in 'it', 'en') {
    ffmpeg -y -loglevel error -i "store/video/anteprima_sr_$l.mov" `
        -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" `
        -vf "scale=886:-2,crop=886:1920,fps=30,format=yuv420p" `
        -c:v libx264 -profile:v high -level 4.0 -preset slow -crf 18 `
        -c:a aac -b:a 256k -shortest -movflags +faststart `
        "store/video/anteprima-886x1920-$l.mp4"
    Write-Output "anteprima-886x1920-$l.mp4"
}
