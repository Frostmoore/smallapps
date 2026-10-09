# encoding: utf-8

# ☠ Da ssh il Mac non imposta LANG: Ruby legge i file come US-ASCII e il primo carattere
#   accentato di un Info.plist (i testi dei permessi) fa fallire `match?` con "invalid byte
#   sequence in US-ASCII" a meta' script (scoperto il 2026-10-09 sulla prima esecuzione).
#   Tutti i file che tocchiamo sono UTF-8: lo si dice una volta qui per tutto lo script.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
# Aggiunge al progetto Xcode di un'app il target dell'estensione di condivisione
# (Share Extension) che riceve testo, link e immagini dallo Share Sheet di iOS.
#
#   ruby tool/aggiungi_share_extension_ios.rb apps/qr_me ShareExtension group.com.smp.qrme
#
# Si lancia dalla radice del monorepo, sul Mac, dopo `flutter pub get` dell'app (serve il
# suo pubspec.lock). Lavora insieme a packages/micro_share (Dart) e copia i file
# dell'estensione da packages/micro_share/ios_template/. F17.1.8 di develop_microapps.md.
#
# ☠ Si fa con uno script e non a mano in Xcode perche' il Mac si guida da ssh, e perche'
#   F16, F18 e F19 vorranno la stessa estensione: questo passo deve costare un comando e
#   non mezz'ora di clic ripetuti a memoria. Modello: tool/aggiungi_widget_ios.rb.
#
# ☠ **E' idempotente**: se il target esiste gia' non lo ricrea, ma riallinea comunque
#   file, impostazioni, gruppo, schema URL, pacchetto Swift e ordine delle fasi. Un
#   progetto Xcode con due target omonimi non da' errore, costruisce, e produce un
#   pacchetto con due estensioni dentro che App Store Connect rifiuta a caricamento finito.
#
# ⚑ Cosa fa, nell'ordine:
#   1. crea il target :app_extension (stesso iOS minimo, stessa famiglia di dispositivi e
#      stesso team del Runner; bundle <bundle del Runner>.<nome>);
#   2. copia ShareViewController.swift e Info.plist dal modello di micro_share, crea
#      <nome>.entitlements con l'App Group, e tiene allineati i sorgenti del target;
#   3. collega Flutter/Generated.xcconfig anche all'estensione (versioni dal pubspec);
#   4. CUSTOM_GROUP_ID nei build settings di Runner ed estensione;
#   5. l'App Group anche in Runner.entitlements (creato e collegato se manca);
#   6. AppGroupId e lo schema ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER) nell'Info.plist del
#      Runner;
#   7. il prodotto Swift "receive-sharing-intent" collegato all'estensione;
#   8. l'estensione copiata nell'app, con la fase di copia PRIMA di "Thin Binary".

require 'fileutils'
require 'xcodeproj'
require 'yaml'

cartella_app = ARGV[0] or abort 'manca la cartella dell app (es. apps/qr_me)'
nome         = ARGV[1] or abort 'manca il nome del target (es. ShareExtension)'
gruppo       = ARGV[2] or abort 'manca l app group (es. group.com.smp.qrme)'

abort "l'app group deve iniziare con group. (ricevuto #{gruppo})" unless gruppo.start_with?('group.')

# ☠ La gemma xcodeproj deve conoscere i pacchetti Swift locali (XCLocalSwiftPackageReference,
#   dalla 1.23): con una versione piu' vecchia il progetto di un'app Flutter con Swift
#   Package Manager non si apre nemmeno, ma meglio dirlo chiaro che fallire a meta'.
unless defined?(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  abort 'la gemma xcodeproj e\' troppo vecchia: serve >= 1.23 (gem update xcodeproj)'
end

cartella_ios = File.join(cartella_app, 'ios')
percorso = File.join(cartella_ios, 'Runner.xcodeproj')
progetto = Xcodeproj::Project.open(percorso)
modello = File.expand_path('../packages/micro_share/ios_template', __dir__)
abort "modello dell'estensione non trovato in #{modello}" unless File.directory?(modello)

runner = progetto.targets.find { |t| t.name == 'Runner' } or abort 'target Runner non trovato'

# Valore effettivo di un'impostazione del Runner: quella del target se c'e', altrimenti
# quella del progetto.
#
# ☠ Nelle app Flutter IPHONEOS_DEPLOYMENT_TARGET, DEVELOPMENT_TEAM e spesso
#   TARGETED_DEVICE_FAMILY stanno a livello di PROGETTO, non del target Runner: leggerle
#   solo dal target (come faceva la prima versione dello script del widget) restituisce
#   nil, e l'estensione nasce con i valori di default di xcodeproj invece che con quelli
#   dell'app.
def impostazione(progetto, target, chiave, nome_config = nil)
  config = if nome_config
             target.build_configurations.find { |c| c.name == nome_config }
           else
             target.build_configurations.first
           end
  valore = config && config.build_settings[chiave]
  return valore unless valore.nil? || valore == ''

  di_progetto = progetto.build_configurations.find { |c| config && c.name == config.name } ||
                progetto.build_configurations.first
  valore = di_progetto && di_progetto.build_settings[chiave]
  valore == '' ? nil : valore
end

id_app = impostazione(progetto, runner, 'PRODUCT_BUNDLE_IDENTIFIER')
abort 'PRODUCT_BUNDLE_IDENTIFIER del Runner non trovato' if id_app.nil?
ios_minimo = impostazione(progetto, runner, 'IPHONEOS_DEPLOYMENT_TARGET')
abort 'IPHONEOS_DEPLOYMENT_TARGET non trovato ne\' nel Runner ne\' nel progetto' if ios_minimo.nil?
famiglia = impostazione(progetto, runner, 'TARGETED_DEVICE_FAMILY') || '1'
team = impostazione(progetto, runner, 'DEVELOPMENT_TEAM')

# ── 1. Il target ─────────────────────────────────────────────────────────────
estensione = progetto.targets.find { |t| t.name == nome }

if estensione.nil?
  # ⚑ La stessa soglia del Runner (il README del plugin lo chiede esplicitamente). Un'estensione
  #   che pretende un iOS piu' recente dell'app non si installa, e l'errore parla di firma
  #   invece che di versioni.
  estensione = progetto.new_target(:app_extension, nome, :ios, ios_minimo)
  puts "#{nome} creato"
end

estensione.build_configurations.each do |config|
  s = config.build_settings
  # ☠ Il bundle dell'estensione deve essere ESATTAMENTE <bundle dell'app>.<una parola>:
  #   RSIShareViewController ricava il bundle dell'app togliendo l'ultimo pezzo dopo il
  #   punto, e con quello costruisce lo schema ShareMedia-<bundle> per riaprirla. Con un
  #   punto in piu' l'estensione apre uno schema che nessuno ascolta, e non succede nulla.
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{id_app}.#{nome}"
  s['PRODUCT_NAME'] = nome
  s['INFOPLIST_FILE'] = "#{nome}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{nome}/#{nome}.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  # ⚑ Il team si scrive solo se il Runner ne ha uno: un DEVELOPMENT_TEAM vuoto sul target
  #   coprirebbe quello del progetto invece di ereditarlo.
  s['DEVELOPMENT_TEAM'] = team if team
  s['IPHONEOS_DEPLOYMENT_TARGET'] = ios_minimo
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = famiglia
  s['SKIP_INSTALL'] = 'YES'
  s['CUSTOM_GROUP_ID'] = gruppo
  # ⚑ Un'estensione e' un bundle dentro l'app: le sue librerie (compreso Flutter.framework,
  #   che il pacchetto Swift del plugin si porta dietro) si cercano nella cartella
  #   Frameworks dell'app che la contiene, due livelli piu' su.
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                  '@executable_path/../../Frameworks']
end

unless runner.dependencies.any? { |d| d.target == estensione }
  runner.add_dependency(estensione)
  puts "Runner ora dipende da #{nome}"
end

# ── 2. I file dell'estensione ───────────────────────────────────────────────
#
# ⚑ Il modello in packages/micro_share/ios_template/ e' l'originale: qui si copia sempre
#   sopra, cosi' una correzione fatta li' arriva a tutte le app rilanciando lo script.
#   Non modificare i file nella cartella dell'app: il giro dopo li riscrive.
cartella_target = File.join(cartella_ios, nome)
FileUtils.mkdir_p(cartella_target)
%w[ShareViewController.swift Info.plist].each do |file|
  sorgente = File.join(modello, file)
  destinazione = File.join(cartella_target, file)
  next if File.exist?(destinazione) && FileUtils.compare_file(sorgente, destinazione)

  FileUtils.cp(sorgente, destinazione)
  puts "#{nome}/#{file} copiato dal modello di micro_share"
end

ENTITLEMENTS_VUOTO = <<~PLIST.freeze
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  </dict>
  </plist>
PLIST

# Controlla che un plist sia ancora valido dopo una modifica fatta come testo.
def verifica_plist(file)
  if system('which plutil > /dev/null 2>&1')
    abort "#{file} non e' piu' un plist valido" unless system('plutil', '-lint', '-s', file)
  else
    Xcodeproj::Plist.read_from_path(file)
  end
end

# Inserisce un frammento XML prima dell'ultimo </dict> del file (quello radice).
#
# ⚑ I plist si modificano come testo e non rileggendoli e riscrivendoli con
#   Xcodeproj::Plist: la riscrittura butta via i commenti XML, e negli Info.plist delle
#   MicroApps i commenti spiegano le scelte (es. FlutterDeepLinkingEnabled).
def inserisci_in_radice(file, frammento)
  testo = File.read(file)
  indice = testo.rindex('</dict>') or abort "#{file}: </dict> radice non trovato"
  File.write(file, testo[0...indice] + frammento + testo[indice..])
end

# Mette l'App Group nell'elenco com.apple.security.application-groups di un file di
# entitlements, creandolo se manca. Restituisce true se ha cambiato qualcosa.
def aggiungi_gruppo(file, gruppo)
  File.write(file, ENTITLEMENTS_VUOTO) unless File.exist?(file)
  testo = File.read(file)
  return false if testo.include?("<string>#{gruppo}</string>")

  chiave = %r{(<key>com\.apple\.security\.application-groups</key>\s*<array>)}
  if testo.match?(chiave)
    File.write(file, testo.sub(chiave) { "#{Regexp.last_match(1)}\n\t\t<string>#{gruppo}</string>" })
  elsif testo.match?(%r{<key>com\.apple\.security\.application-groups</key>\s*<array\s*/>})
    File.write(file, testo.sub(%r{(<key>com\.apple\.security\.application-groups</key>\s*)<array\s*/>}) do
      "#{Regexp.last_match(1)}<array>\n\t\t<string>#{gruppo}</string>\n\t</array>"
    end)
  else
    inserisci_in_radice(file, "\t<key>com.apple.security.application-groups</key>\n" \
                              "\t<array>\n\t\t<string>#{gruppo}</string>\n\t</array>\n")
  end
  verifica_plist(file)
  true
end

file_entitlements = File.join(cartella_target, "#{nome}.entitlements")
puts "#{nome}.entitlements: aggiunto #{gruppo}" if aggiungi_gruppo(file_entitlements, gruppo)

gruppo_file = progetto.main_group.find_subpath(nome, true)
gruppo_file.set_source_tree('SOURCE_ROOT')
gruppo_file.set_path(nome)
['Info.plist', "#{nome}.entitlements"].each do |file|
  gruppo_file.new_reference(file) unless gruppo_file.files.any? { |r| r.path == file }
end

# Tutti i sorgenti Swift della cartella stanno nel target.
#
# ☠ Un file `.swift` aggiunto alla cartella ma non al target non da' errore di per se':
#   se nessuno lo usa viene semplicemente ignorato, e se qualcuno lo usa l'errore parla di
#   un simbolo sconosciuto invece che di un file dimenticato. Si allinea a ogni giro.
Dir.glob(File.join(cartella_target, '*.swift')).sort.each do |file|
  base = File.basename(file)
  presente = estensione.source_build_phase.files_references.any? { |r| r && r.path == base }
  next if presente

  riferimento = gruppo_file.files.find { |r| r.path == base } || gruppo_file.new_reference(base)
  estensione.add_file_references([riferimento])
  puts "#{base} aggiunto ai sorgenti di #{nome}"
end

# ── 3. Le versioni vengono dal pubspec, anche per l'estensione ──────────────
#
# ☠ **Senza questo l'app non si installa affatto**, e l'errore non nomina le versioni:
#   dice "Invalid placeholder attributes" e "Failed to create app extension placeholder".
#   L'Info.plist dell'estensione usa $(FLUTTER_BUILD_NAME) e $(FLUTTER_BUILD_NUMBER), che
#   vivono in Flutter/Generated.xcconfig: il Runner la eredita, l'estensione appena creata
#   no. Gia' pagata col widget di TrashCan (tool/aggiungi_widget_ios.rb).
estensione.build_configurations.each do |config|
  gemella = runner.build_configurations.find { |c| c.name == config.name }
  next if gemella.nil? || gemella.base_configuration_reference.nil?

  config.base_configuration_reference = gemella.base_configuration_reference
end

# ── 4. CUSTOM_GROUP_ID anche nel Runner ─────────────────────────────────────
#
# ⚑ Il plugin legge l'App Group dalla chiave AppGroupId dell'Info.plist, che vale
#   $(CUSTOM_GROUP_ID): senza il build setting sul Runner, la parte dell'app cerca la
#   condivisione in un gruppo vuoto e non trova niente, mentre l'estensione l'ha salvata.
runner.build_configurations.each do |config|
  config.build_settings['CUSTOM_GROUP_ID'] = gruppo
end

# ── 5. L'App Group anche nell'app ───────────────────────────────────────────
entitlements_runner = impostazione(progetto, runner, 'CODE_SIGN_ENTITLEMENTS') ||
                      'Runner/Runner.entitlements'
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] ||= entitlements_runner
end
file_runner = File.join(cartella_ios, entitlements_runner)
puts "#{entitlements_runner}: aggiunto #{gruppo}" if aggiungi_gruppo(file_runner, gruppo)

gruppo_runner = progetto.main_group.find_subpath(File.dirname(entitlements_runner), false)
base_runner = File.basename(entitlements_runner)
if gruppo_runner && gruppo_runner.files.none? { |r| r.path == base_runner }
  gruppo_runner.new_reference(base_runner)
end

# ── 6. Info.plist del Runner: AppGroupId e lo schema per essere riaperta ────
#
# ☠ Lo schema ShareMedia-<bundle> e' quello con cui l'estensione riapre l'app. Senza, la
#   condivisione viene salvata nell'App Group e l'app non si apre: l'utente vede lo
#   Share Sheet chiudersi e basta.
info_runner = File.join(cartella_ios, 'Runner', 'Info.plist')
testo = File.read(info_runner)

unless testo.include?('<key>AppGroupId</key>')
  inserisci_in_radice(info_runner, "\t<key>AppGroupId</key>\n\t<string>$(CUSTOM_GROUP_ID)</string>\n")
  puts 'Runner/Info.plist: aggiunto AppGroupId'
end

testo = File.read(info_runner)
unless testo.include?('ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)')
  schema = "\t\t<dict>\n" \
           "\t\t\t<key>CFBundleTypeRole</key>\n\t\t\t<string>Editor</string>\n" \
           "\t\t\t<key>CFBundleURLName</key>\n\t\t\t<string>ShareMedia</string>\n" \
           "\t\t\t<key>CFBundleURLSchemes</key>\n" \
           "\t\t\t<array>\n\t\t\t\t<string>ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)</string>\n\t\t\t</array>\n" \
           "\t\t</dict>\n"
  tipi = %r{(<key>CFBundleURLTypes</key>\s*<array>\s*?\n)}
  if testo.match?(tipi)
    # Ci sono gia' altri schemi (es. filmtracker://): si aggiunge il nostro in testa.
    File.write(info_runner, testo.sub(tipi) { Regexp.last_match(1) + schema })
  else
    inserisci_in_radice(info_runner, "\t<key>CFBundleURLTypes</key>\n\t<array>\n#{schema}\t</array>\n")
  end
  puts 'Runner/Info.plist: aggiunto lo schema ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)'
end
verifica_plist(info_runner)

# ☠ Con il deep link di Flutter acceso, l'URL ShareMedia-…:share arriva anche a go_router,
#   che cerca una rotta "share" e mostra «Non trovato» (F17.1.11 punto 6). Non si corregge
#   qui perche' e' una scelta dell'app, ma si avvisa.
unless File.read(info_runner).match?(%r{<key>FlutterDeepLinkingEnabled</key>\s*<false\s*/>})
  warn 'ATTENZIONE: FlutterDeepLinkingEnabled non e\' false in Runner/Info.plist: ' \
       'go_router ricevera\' anche lo schema ShareMedia e mostrera\' «Non trovato».'
end

# ── 7. Il modulo del plugin anche per l'estensione ──────────────────────────
#
# receive_sharing_intent 1.9 si distribuisce SOLO come pacchetto Swift (nessun podspec).
# Flutter lo collega al Runner attraverso FlutterGeneratedPluginSwiftPackage, ma
# all'estensione serve il solo prodotto "receive-sharing-intent" (contiene
# RSIShareViewController): e' il passo 5 del README del plugin, che in Xcode si fa da
# General → Frameworks and Libraries. Qui si replica cio' che fa il progetto d'esempio del
# plugin: un riferimento al pacchetto locale e la dipendenza dal prodotto.
#
# ☠ Il percorso contiene la VERSIONE del plugin: Flutter crea in
#   Flutter/ephemeral/Packages/.packages/ un collegamento chiamato come la cartella del
#   plugin nella pub cache (receive_sharing_intent-1.9.0), apposta perche' cambi a ogni
#   aggiornamento (flutter_tools, swift_package_manager.dart). Il progetto d'esempio del
#   plugin usa ".packages/receive_sharing_intent", che con questo Flutter non esiste.
#   => **Dopo ogni aggiornamento di receive_sharing_intent si rilancia lo script**, che
#   riallinea il percorso; altrimenti Xcode dice "Missing package product".
lock = File.join(cartella_app, 'pubspec.lock')
abort "#{lock} non trovato: lanciare prima flutter pub get nell'app" unless File.exist?(lock)
voce = (YAML.load_file(lock)['packages'] || {})['receive_sharing_intent'] or
  abort "receive_sharing_intent non e' nel pubspec.lock dell'app: manca micro_share fra le dipendenze?"

cartella_plugin = case voce['source']
                  when 'hosted' then "receive_sharing_intent-#{voce['version']}"
                  when 'path' then File.basename(voce['description']['path'].to_s)
                  else abort "receive_sharing_intent da sorgente #{voce['source']}: percorso non previsto"
                  end
percorso_pacchetto = "Flutter/ephemeral/Packages/.packages/#{cartella_plugin}"

riferimento = progetto.root_object.package_references.find do |r|
  r.isa == 'XCLocalSwiftPackageReference' &&
    r.relative_path.to_s.match?(%r{\.packages/receive_sharing_intent(-[^/]*)?\z})
end
if riferimento.nil?
  riferimento = progetto.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  riferimento.relative_path = percorso_pacchetto
  progetto.root_object.package_references << riferimento
  puts "pacchetto Swift locale #{percorso_pacchetto} aggiunto al progetto"
elsif riferimento.relative_path != percorso_pacchetto
  puts "pacchetto Swift: #{riferimento.relative_path} → #{percorso_pacchetto}"
  riferimento.relative_path = percorso_pacchetto
end

PRODOTTO = 'receive-sharing-intent'.freeze
dipendenza = estensione.package_product_dependencies.find { |d| d.product_name == PRODOTTO }
if dipendenza.nil?
  # ⚑ Senza l'attributo `package`, come nei progetti generati da Flutter e nell'esempio del
  #   plugin: per i pacchetti locali Xcode risolve il prodotto per nome.
  dipendenza = progetto.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dipendenza.product_name = PRODOTTO
  estensione.package_product_dependencies << dipendenza
  puts "#{nome} ora dipende dal prodotto Swift #{PRODOTTO}"
end
unless estensione.frameworks_build_phase.files.any? { |f| f.product_ref == dipendenza }
  file_build = progetto.new(Xcodeproj::Project::Object::PBXBuildFile)
  file_build.product_ref = dipendenza
  estensione.frameworks_build_phase.files << file_build
end

# ── 8. L'app deve contenere l'estensione ────────────────────────────────────
#
# ☠ Senza questa fase il target compila, il pacchetto si costruisce, e nello Share Sheet
#   l'app semplicemente non compare: l'estensione non e' mai stata copiata dentro l'app.
fase = runner.build_phases.find do |f|
  f.respond_to?(:symbol_dst_subfolder_spec) && f.symbol_dst_subfolder_spec == :plug_ins
end

if fase.nil?
  fase = progetto.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  fase.name = 'Embed Foundation Extensions'
  fase.symbol_dst_subfolder_spec = :plug_ins
  runner.build_phases << fase
end

# ⚑ Si controlla il prodotto e non "fase vuota": se l'app ha gia' un'altra estensione
#   (un widget) la fase esiste e non e' vuota, ma la nostra va aggiunta lo stesso.
unless fase.files_references.include?(estensione.product_reference)
  file_copia = fase.add_file_reference(estensione.product_reference)
  file_copia.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts "#{nome}.appex aggiunto a '#{fase.name}'"
end

# ☠ **La copia deve stare PRIMA di "Thin Binary"** (README del plugin, passo 7, e la
#   trappola gia' pagata col widget): lo script "Thin Binary" di Flutter lavora sul
#   pacchetto gia' assemblato; se l'estensione ci viene copiata dentro dopo, Xcode vede
#   l'appex come ingresso e uscita della stessa catena e si ferma con un errore di ciclo
#   fra le dipendenze che non nomina mai ne' l'estensione ne' l'ordine delle fasi.
indice_fase = runner.build_phases.index(fase)
indice_thin = runner.build_phases.index do |f|
  f.respond_to?(:name) && f.name == 'Thin Binary'
end

if indice_thin && indice_fase > indice_thin
  runner.build_phases.delete_at(indice_fase)
  runner.build_phases.insert(indice_thin, fase)
  puts "fase '#{fase.name}' spostata prima di 'Thin Binary'"
end

progetto.save
puts "fatto: #{nome} (#{id_app}.#{nome}), gruppo #{gruppo}, iOS #{ios_minimo}"
