# Aggiunge al target Runner i file `<lingua>.lproj/InfoPlist.strings` di un'app.
#
#   ruby tool/aggiungi_infoplist_strings.rb apps/full_freezer
#
# Servono per i testi dei permessi in italiano (fotocamera, microfono...): Info.plist ne
# contiene una lingua sola, e senza questi file un iPhone in italiano mostra la richiesta
# in inglese. Si fa con uno script perche' il Mac si guida da ssh e Xcode non si apre.
#
# ☠ I file devono stare in un **gruppo di varianti** chiamato InfoPlist.strings, non come
#   file sciolti: altrimenti finiscono entrambi nel pacchetto con lo stesso nome e uno
#   sovrascrive l'altro. E' idempotente: un secondo giro non duplica niente.

require 'xcodeproj'

cartella_app = ARGV[0] or abort 'manca la cartella dell app (es. apps/full_freezer)'
progetto = Xcodeproj::Project.open(File.join(cartella_app, 'ios', 'Runner.xcodeproj'))
runner = progetto.targets.find { |t| t.name == 'Runner' } or abort 'target Runner non trovato'
gruppo_runner = progetto.main_group.find_subpath('Runner', false) or abort 'gruppo Runner non trovato'

lingue = Dir.glob(File.join(cartella_app, 'ios', 'Runner', '*.lproj', 'InfoPlist.strings'))
            .map { |f| File.basename(File.dirname(f), '.lproj') }.sort
abort 'nessun InfoPlist.strings trovato' if lingue.empty?

varianti = gruppo_runner.children.find { |c| c.isa == 'PBXVariantGroup' && c.name == 'InfoPlist.strings' }
if varianti.nil?
  varianti = gruppo_runner.new_variant_group('InfoPlist.strings')
  runner.resources_build_phase.add_file_reference(varianti)
end

lingue.each do |lingua|
  percorso = "#{lingua}.lproj/InfoPlist.strings"
  next if varianti.children.any? { |c| c.path == percorso }

  ref = varianti.new_reference(percorso)
  ref.name = lingua
  ref.last_known_file_type = 'text.plist.strings'
  puts "#{percorso} aggiunto"
end

lingue.each { |l| progetto.root_object.known_regions |= [l] }
progetto.save
puts "fatto: #{lingue.join(', ')}"
