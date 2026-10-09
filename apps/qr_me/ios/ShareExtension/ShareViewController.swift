// Controller dell'estensione di condivisione delle MicroApps.
//
// Copiato in apps/<app>/ios/ShareExtension/ da tool/aggiungi_share_extension_ios.rb:
// l'originale vive in packages/micro_share/ios_template/ e si modifica li', non nelle app.
//
// ⚑ shouldAutoRedirect() -> true: nessuna schermata intermedia. L'estensione salva cio'
//   che e' stato condiviso nell'App Group (AppGroupId nell'Info.plist) e riapre subito
//   l'app con lo schema ShareMedia-<bundle id dell'app>; il resto lo fa la parte Dart
//   (RsiShareInbox in packages/micro_share).
//
// ☠ "No such module 'receive_sharing_intent'": il target dell'estensione non e' collegato
//   al prodotto Swift "receive-sharing-intent". Lo collega lo script; se manca, rilanciarlo.
import receive_sharing_intent

class ShareViewController: RSIShareViewController {

    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
