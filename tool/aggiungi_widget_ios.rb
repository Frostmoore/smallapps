# Aggiunge al progetto Xcode di un'app il target dell'estensione WidgetKit.
#
#   ruby tool/aggiungi_widget_ios.rb apps/trashcan TrashcanWidget group.com.smp.trashcan
#
# ☠ Si fa con uno script e non a mano in Xcode perche' il Mac si guida da ssh, e perche'
#   il giorno in cui le altre tre app vorranno il widget questo passo deve costare un
#   comando e non mezz'ora di clic ripetuti a memoria.
#
# ☠ **E' idempotente**: se il target esiste gia' non lo ricrea, ma ricontrolla comunque
#   l'ordine delle fasi. Un progetto Xcode con due target omonimi non da' errore,
#   costruisce, e produce un pacchetto con due estensioni dentro che App Store Connect
#   rifiuta a caricamento finito.

require 'xcodeproj'

cartella_app = ARGV[0] or abort 'manca la cartella dell app (es. apps/trashcan)'
nome         = ARGV[1] or abort 'manca il nome del target (es. TrashcanWidget)'
gruppo       = ARGV[2] or abort 'manca l app group (es. group.com.smp.trashcan)'

percorso = File.join(cartella_app, 'ios', 'Runner.xcodeproj')
progetto = Xcodeproj::Project.open(percorso)

runner = progetto.targets.find { |t| t.name == 'Runner' } or abort 'target Runner non trovato'
id_app = runner.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
abort 'PRODUCT_BUNDLE_IDENTIFIER del Runner non trovato' if id_app.nil?

estensione = progetto.targets.find { |t| t.name == nome }

if estensione.nil?
  # ── Il target ─────────────────────────────────────────────────────────────
  estensione = progetto.new_target(
    :app_extension,
    nome,
    :ios,
    # ⚑ La stessa soglia del Runner. Un'estensione che pretende un iOS piu' recente
    #   dell'app non si installa, e l'errore parla di firma invece che di versioni.
    runner.build_configurations.first.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
  )

  gruppo_file = progetto.main_group.find_subpath(nome, true)
  gruppo_file.set_source_tree('SOURCE_ROOT')
  gruppo_file.set_path(nome)

  sorgente = gruppo_file.new_reference("#{nome}.swift")
  estensione.add_file_references([sorgente])
  gruppo_file.new_reference('Info.plist')
  gruppo_file.new_reference("#{nome}.entitlements")

  estensione.build_configurations.each do |config|
    s = config.build_settings
    s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{id_app}.#{nome}"
    s['PRODUCT_NAME'] = nome
    s['INFOPLIST_FILE'] = "#{nome}/Info.plist"
    s['CODE_SIGN_ENTITLEMENTS'] = "#{nome}/#{nome}.entitlements"
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['DEVELOPMENT_TEAM'] = runner.build_configurations.first.build_settings['DEVELOPMENT_TEAM']
    s['SWIFT_VERSION'] = '5.0'
    s['TARGETED_DEVICE_FAMILY'] = '1'
    s['SKIP_INSTALL'] = 'YES'
    # ⚑ Un'estensione e' un bundle dentro l'app: le sue librerie di sistema si cercano
    #   nella cartella Frameworks dell'app che la contiene, due livelli piu' su.
    s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                    '@executable_path/../../Frameworks']
  end

  runner.add_dependency(estensione)
  puts "#{nome} creato: bundle #{id_app}.#{nome}, gruppo #{gruppo}"
end

# ── Le versioni vengono dal pubspec, anche per l'estensione ─────────────────
#
# ☠ **Senza questo l'app non si installa affatto**, e l'errore non nomina le versioni:
#   dice "Invalid placeholder attributes" e "Failed to create app extension placeholder".
#   La causa e' che `Info.plist` dell'estensione usa `$(FLUTTER_BUILD_NAME)` e
#   `$(FLUTTER_BUILD_NUMBER)`, che vivono in `Flutter/Generated.xcconfig`: il Runner la
#   eredita, l'estensione appena creata no, quindi le due chiavi di versione restano
#   **vuote** e iOS rifiuta il pacchetto.
#
# ⚑ Si punta alla stessa configurazione del Runner invece di scrivere i numeri a mano:
#   cosi' app ed estensione non possono divergere, e il numero di build resta uno solo,
#   quello del `pubspec.yaml`.
estensione.build_configurations.each do |config|
  gemella = runner.build_configurations.find { |c| c.name == config.name }
  next if gemella.nil? || gemella.base_configuration_reference.nil?

  config.base_configuration_reference = gemella.base_configuration_reference
end

puts "#{nome}: configurazione di Flutter collegata"


# ── L'app deve contenere l'estensione ───────────────────────────────────────
#
# ☠ Senza questa fase il target compila, il pacchetto si costruisce, e sul telefono il
#   widget semplicemente non compare nell'elenco: l'estensione non e' mai stata copiata
#   dentro l'app.
fase = runner.build_phases.find do |f|
  f.respond_to?(:symbol_dst_subfolder_spec) && f.symbol_dst_subfolder_spec == :plug_ins
end

if fase.nil?
  fase = progetto.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  fase.name = 'Embed App Extensions'
  fase.symbol_dst_subfolder_spec = :plug_ins
  runner.build_phases << fase
end

if fase.files.empty?
  riferimento = fase.add_file_reference(estensione.product_reference)
  riferimento.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# ☠ **La copia deve stare PRIMA di "Thin Binary", e questo e' il motivo per cui il primo
#   tentativo falliva.** Lo script "Thin Binary" di Flutter lavora sul pacchetto gia'
#   assemblato; se l'estensione ci viene copiata dentro dopo, Xcode vede l'appex come
#   ingresso e uscita della stessa catena e si ferma con un errore di ciclo fra le
#   dipendenze, che non nomina mai ne' l'estensione ne' l'ordine delle fasi.
indice_fase = runner.build_phases.index(fase)
indice_thin = runner.build_phases.index do |f|
  f.respond_to?(:name) && f.name == 'Thin Binary'
end

if indice_thin && indice_fase > indice_thin
  runner.build_phases.delete_at(indice_fase)
  runner.build_phases.insert(indice_thin, fase)
  puts "fase 'Embed App Extensions' spostata prima di 'Thin Binary'"
end

# ── Il gruppo condiviso anche per l'app ─────────────────────────────────────
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

progetto.save
puts 'fatto'
