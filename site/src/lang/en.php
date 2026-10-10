<?php

/**
 * The English strings.
 *
 * ☠ This file and `it.php` must carry **the same keys**. `deploy/verifica_lingue.php`
 * checks it, and must be run after every change: a key missing here produces no error at
 * all, it produces an Italian sentence in the middle of an English page, and nobody reports
 * that.
 *
 * ☠ Values may contain HTML and are printed without escaping. Nothing that comes from a
 * user must ever end up in here.
 */

declare(strict_types=1);

return [

    // ── Shared ──────────────────────────────────────────────────────────────
    'comune.altra_lingua'      => 'Italiano',
    'comune.scegli_lingua'     => 'Choose a language',
    'comune.in_italiano'       => 'Leggi in italiano',
    'comune.in_inglese'        => 'Read in English',
    'comune.salta'             => 'Skip to content',
    'comune.aggiornato'        => 'Last updated: {data}',
    'comune.data_legale'       => '10 October 2026',
    'comune.scopri'            => 'Find out more &rarr;',
    'comune.in_lavorazione'    => 'In the works',
    'comune.su_app_store'   => 'Available on the App Store',
    'comune.su_google_play' => 'Available on Google Play',
    'comune.in_arrivo'         => 'Coming soon',
    'comune.disponibile'       => 'Available',
    'comune.presto_play'       => 'Soon on Google Play',
    'comune.scarica_play'      => 'Get it on Google Play',
    'comune.scarica_app_store' => 'Download on the App Store',
    'comune.presto_store'      => 'Soon on Google Play and the App Store',
    'comune.disponibile_ios_android' => 'Available on iOS and Android',
    'comune.disponibile_ios'     => 'Available on iOS',
    'comune.disponibile_android' => 'Available on Android',
    'comune.android_in_arrivo'   => 'Coming to Android.',
    'comune.ios_in_arrivo'       => 'Coming to iPhone.',
    'comune.cosa_sa_fare'        => 'What it does',
    'comune.schermate.titolo'    => 'What it looks like',
    'comune.schermate.lede'      => 'Real screenshots of the app, not mock-ups: what you see here is what you get on your phone.',
    'comune.promo.titolo'        => 'In a nutshell',
    'comune.promo.lede'          => 'The things that matter, one per picture.',
    'comune.piano.base'          => 'Basic',
    'comune.piano.gratis'        => 'Free',
    'comune.piano.pro'           => 'Pro',
    'comune.piano.unatantum'     => 'one-off, VAT included',
    'comune.privacy.link'        => 'Read the full privacy policy &rarr;',
    'comune.bug.titolo'          => 'Something wrong, or something missing?',
    'comune.bug.testo'           => 'Reports are read by one person, the same one who writes the code. Tell me what happened and on which phone: it\'s the fastest way to get it fixed.',
    'comune.bug.bottone'         => 'Report a problem',

    // ── Navigation ──────────────────────────────────────────────────────────
    'nav.app'         => 'The apps',
    'nav.contatti'    => 'Contact',
    'nav.su_misura'   => 'Custom development',
    'nav.principale'  => 'Main',
    'nav.apri'        => 'Open the menu',
    'nav.chiudi'      => 'Close the menu',
    'nav.mostra_app'  => 'Show the apps',

    // ── Footer ──────────────────────────────────────────────────────────────
    'footer.blurb'       => 'Small Android and iPhone apps that do one thing and do it well. Free in '
                          . 'the base version, unlocked with a one-off purchase. No '
                          . 'subscriptions.',
    'footer.app'         => 'The apps',
    'footer.legale'      => 'Legal',
    'footer.contatti'    => 'Contact',
    'footer.note'        => 'Legal notice',
    'footer.privacy'     => 'Privacy policy',
    'footer.cookie'      => 'Cookie policy',
    'footer.termini'     => 'Terms of service',
    'footer.responsabilita' => 'Disclaimer',
    'footer.segnala'     => 'Report a problem',
    'footer.diritti'     => 'All rights reserved. Android and Google Play are trademarks of '
                          . 'Google LLC. iPhone and App Store are trademarks of Apple Inc.',

    // ── The catalogue ───────────────────────────────────────────────────────
    'app.trashcan.prezzo'   => '€2.99',
    'app.trashcan.claim'    => 'What goes out tonight?',
    'app.trashcan.sommario' => 'Your town\'s waste collection calendar, with a reminder the '
                             . 'evening before. No more bin left behind.',

    'app.full-freezer.claim'    => 'What\'s in the freezer, and since when.',
    'app.full-freezer.sommario' => 'Your freezer inventory sorted by age, so the oldest '
                                 . 'thing in there is the next one you eat.',

    'app.scorte-calore.prezzo'     => '€2.99',
    'app.scorte-calore.claim'    => 'How much pellet you actually have left.',
    'app.scorte-calore.sommario' => 'Average consumption, remaining range and the date to '
                                  . 'reorder. For pellets, heating oil, LPG and firewood.',

    'app.film-tracker.claim'    => 'A diary for your film rolls.',
    'app.film-tracker.sommario' => 'Every roll from the camera to the contact sheet: film, '
                                 . 'developing, prints, costs and photos. And a QR label for the canister.',
    'app.film-tracker.prezzo'      => '€4.99',

    'app.qr-me.claim'    => 'Share it, and it\'s a QR.',
    'app.qr-me.sommario' => 'A link, some text or your home Wi-Fi become a big, bright QR code '
                          . 'for someone to scan. It reads QR codes too.',

    'app.spending-review.claim'    => 'What you\'re spending, while you shop.',
    'app.spending-review.sommario' => 'Point at the price tag and it adds up, with your budget always '
                                    . 'in sight. At the till, it checks the receipt.',

    'app.fair-share.claim'    => 'Who owes what, without doing the maths.',
    'app.fair-share.sommario' => 'Split the bill your way, even from the receipt, and keep track of a trip or a shared home.',

    'app.boomerang.claim'    => 'Lent things come back.',
    'app.boomerang.sommario' => 'Who has what and since when: what you lend and what you borrow, with a reminder.',

    'app.pin-drop.claim'    => 'Where did you leave it? It knows.',
    'app.pin-drop.sommario' => 'Your car, your bike, your sunbed: mark the spot with a photo and a note, and find it again.',

    'app.geo-note.claim'    => 'A reminder that fires in the right place.',
    'app.geo-note.sommario' => 'It reminds you when you arrive somewhere or leave: at the shop, at home, at the office.',

    'app.tldr.claim'    => 'Too long? It sums it up.',
    'app.tldr.sommario' => 'Share an article or some text and get a short summary to read at a glance.',

    'app.read-aloud.claim'    => 'Articles, to listen to.',
    'app.read-aloud.sommario' => 'Share an article and it reads it aloud while you drive, cook or walk.',

    'app.link-peek.claim'    => 'Where does that link go? Peek first.',
    'app.link-peek.sommario' => 'See where a short or suspicious link really leads before you open it, with the warning signs.',

    // ── Home ────────────────────────────────────────────────────────────────
    'home.titolo'      => 'Small Android and iPhone apps that do one thing',
    'home.descrizione' => 'SMP MicroApps: lightweight Android and iPhone apps with no accounts and no '
                        . 'subscriptions. Free base version, Pro with a one-off purchase.',

    'home.eyebrow'      => 'Android and iPhone apps',
    'home.hero.titolo'  => 'One thing.<br>Done well.',
    'home.hero.lede'    => 'Micro apps that answer one precise question and then get out of '
                         . 'the way. No account, no ads, no subscription: the base version '
                         . 'is free, and Pro is unlocked once and stays yours.',
    'home.hero.cta1'    => 'See the apps',
    'home.hero.cta2'    => 'Need an app built for you?',

    'home.catalogo.titolo'    => 'The catalogue',
    'home.catalogo.una'       => 'One is ready to download, the others are in the works.',
    'home.catalogo.molte'     => '{n} are ready to download, the others are in the works.',
    'home.catalogo.coda'      => 'They are listed here because they are coming, not because '
                               . 'they are finished.',

    'home.principi.titolo' => 'How we see it',
    'home.principi.lede'   => 'Three choices that hold for every app in the catalogue, with '
                            . 'no exceptions.',
    'home.principi.1.titolo' => 'You pay once',
    'home.principi.1.testo'  => 'No subscriptions. Pro is unlocked with a single purchase '
                              . 'and stays unlocked, even when you change phone. Nothing '
                              . 'expires.',
    'home.principi.2.titolo' => 'Your data stays on your phone',
    'home.principi.2.testo'  => 'No account to create, no profile, no usage analytics. What '
                              . 'you type into the app stays in the app, and you can export '
                              . 'it whenever you like.',
    'home.principi.3.titolo' => 'No advertising',
    'home.principi.3.testo'  => 'There is no room for a banner in an app that has to answer '
                              . 'a question in two seconds. Not even in the free version.',

    'home.cta.titolo' => 'Got an app in mind that doesn\'t exist yet?',
    'home.cta.testo'  => 'Custom software development: business tools, automations, mobile '
                       . 'apps and internal utilities. Tell me the problem and I\'ll tell '
                       . 'you whether and how it can be solved.',
    'home.cta.bottone' => 'Let\'s talk',

    // ── TrashCan page ───────────────────────────────────────────────────────
    'trashcan.titolo'      => 'TrashCan, the waste collection calendar',
    'trashcan.descrizione' => 'TrashCan reminds you the evening before what to put out. '
                            . 'Waste collection calendar with reminders and a home screen '
                            . 'widget, for Android and iPhone. Free, Pro for €2.99 one-off.',

    'trashcan.hero.titolo' => 'What goes out<br>tonight?',
    'trashcan.hero.lede'   => 'Your town\'s waste collection calendar, with a reminder the '
                            . 'evening before and a widget on your home screen. The right '
                            . 'bin, on the right night.',
    'trashcan.hero.cta'    => 'What it does',

    'trashcan.problema.titolo' => 'The problem never changes',
    'trashcan.problema.lede'   => 'The collection calendar is a sheet of paper stuck to the '
                                . 'fridge, or a council PDF nobody ever opens again. You '
                                . 'remember it the next morning, once the truck has gone. '
                                . 'TrashCan reminds you while you are still indoors.',
    'trashcan.problema.1.titolo' => 'Set it up once',
    'trashcan.problema.1.testo'  => 'A four-step wizard: pick your waste types, the days '
                                  . 'they are collected and the time of the reminder. Five '
                                  . 'minutes and you never think about it again.',
    'trashcan.problema.2.titolo' => 'It handles real calendars',
    'trashcan.problema.2.testo'  => 'Weekly, alternating weeks, every two weeks from a start '
                                  . 'date, monthly by position, or dates picked by hand. '
                                  . 'Even your council\'s odd rotation fits.',
    'trashcan.problema.3.titolo' => 'Exceptions don\'t catch you out',
    'trashcan.problema.3.testo'  => 'Holidays, skipped rounds and extra collections: pick '
                                  . 'the collection to change, even months ahead, and the '
                                  . 'calendar adjusts itself, without touching the rule.',

    'trashcan.funzioni.titolo' => 'What you get',
    'trashcan.funzioni.lede'   => 'Everything you need to get the bin right, and nothing '
                                . 'else.',
    'trashcan.funzioni.1.titolo' => 'The "Tonight" screen',
    'trashcan.funzioni.1.testo'  => 'Open the app and the first thing you see is what to put '
                                  . 'out tonight, large and colour-coded. Below it, the next '
                                  . 'collection and the following seven days.',
    'trashcan.funzioni.2.titolo' => 'The home screen widget',
    'trashcan.funzioni.2.testo'  => 'On Android and on iPhone: the coloured header says what '
                                  . 'goes out tonight, with its icon; below, the following '
                                  . 'days. It updates itself every evening, and it is free.',
    'trashcan.funzioni.3.titolo' => 'A reminder on time',
    'trashcan.funzioni.3.testo'  => 'With Pro, a notification at the time you choose, the '
                                  . 'evening before collection. If you are out at the first '
                                  . 'one, add a second.',
    'trashcan.funzioni.4.titolo' => 'Your own waste types',
    'trashcan.funzioni.4.testo'  => 'Every council has its own categories and its own names. '
                                  . 'Start from the ready-made types and rename them, change '
                                  . 'icon and colour, or create your own.',
    'trashcan.funzioni.5.titolo' => 'Sharing and backup',
    'trashcan.funzioni.5.testo'  => 'Send the calendar to a neighbour and they get the same '
                                  . 'days without typing them in, for free. With Pro you save '
                                  . 'everything to a file and take it to a new phone.',
    'trashcan.funzioni.6.titolo' => 'English and Italian',
    'trashcan.funzioni.6.testo'  => 'The app follows your phone\'s language. So do the dates '
                                  . 'and the weekday names.',

    'trashcan.prezzi.titolo' => 'Free, then Pro if you need it',
    'trashcan.prezzi.lede'   => 'One purchase, no subscription, no renewal. Change phone and '
                              . 'you restore it from your Google account or your Apple ID. '
                              . 'On Android, if you changed account too, there is a transfer '
                              . 'code inside the app.',
    'trashcan.prezzi.base'      => 'Base',
    'trashcan.prezzi.gratis'    => 'Free',
    'trashcan.prezzi.pro'       => 'Pro',
    'trashcan.prezzi.unatantum' => 'one-off. Local price and tax apply',
    'trashcan.prezzi.base.lista' => '<li>One collection calendar</li>'
        . '<li>Unlimited waste types and rules</li>'
        . '<li>Exceptions, skips and extra collections</li>'
        . '<li>Widget showing tonight\'s collection and the following days</li>'
        . '<li>Share the calendar with a neighbour</li>'
        . '<li>No advertising, no account</li>',
    'trashcan.prezzi.pro.lista' => '<li>Everything in the base version</li>'
        . '<li><strong>The reminders</strong>: the notification the evening before</li>'
        . '<li>A second reminder, for anyone who ignores the first</li>'
        . '<li>Multiple calendars: home, holiday house, your parents\'</li>'
        . '<li>Full backup to a file, for your new phone</li>'
        . '<li>The app colour, chosen by you out of ten</li>',

    'trashcan.privacy.titolo' => 'Your data stays yours',
    'trashcan.privacy.testo'  => 'TrashCan has no account, asks for no registration and '
                               . 'collects no usage analytics. The calendar, the waste types '
                               . 'and the reminders live in your phone\'s storage and are '
                               . 'never sent anywhere. The only thing that leaves the device '
                               . 'is the purchase check, because Google or Apple performs it.',
    'trashcan.privacy.link'   => 'Read the full privacy policy &rarr;',

    'trashcan.bug.titolo'  => 'Something wrong, or something missing?',
    'trashcan.bug.testo'   => 'Reports are read by one person, who is the same person who '
                            . 'writes the code. Tell me what happened and on which phone: it '
                            . 'is the fastest way to get it fixed.',
    'trashcan.bug.bottone' => 'Report a problem',

    'trashcan.img.testata'     => 'TrashCan: what goes out tonight? The widget tells you every evening.',
    'trashcan.schermate.titolo' => 'What it looks like',
    'trashcan.schermate.lede'   => 'Real screenshots of the app, not mock-ups: what you see here is '
                                 . 'what you get on your phone.',
    'trashcan.schermate.1'      => 'Tonight and the next seven days',
    'trashcan.schermate.2'      => 'The home screen widget',
    'trashcan.schermate.3'      => 'Collection days',
    'trashcan.schermate.4'      => 'The rule for one waste type',
    'trashcan.schermate.5'      => 'Waste types, with colours and icons',
    'trashcan.schermate.6'      => 'Pro, a single purchase',
    'trashcan.promo.titolo'     => 'In a nutshell',
    'trashcan.promo.lede'       => 'What matters, one picture at a time.',
    'trashcan.promo.02-widget'         => 'Always-visible widget: know what to put out without opening the app.',
    'trashcan.promo.03-promemoria'     => 'Never forget the bin: a reminder the evening before.',
    'trashcan.promo.04-calendari'      => 'Even complicated schedules: weekly, alternating, monthly or custom.',
    'trashcan.promo.05-festivi'        => 'Holidays? No problem: exceptions and changes in a moment.',
    'trashcan.promo.06-personalizza'   => 'Customise everything: categories, colours and icons.',
    'trashcan.promo.07-nessun-account' => 'No account: works offline, no ads.',
    'trashcan.promo.08-condividi'      => 'Share the calendar with your household or your neighbours.',
    'trashcan.promo.09-piu-calendari'  => 'Several calendars in one app: home, holiday home, parents.',
    'trashcan.promo.10-mai-piu'        => 'Never miss a collection again.',

    // ── Pagina Scorte Calore ─────────────────────────────────────────────────
    'scorte-calore.promo.02-riordina' => 'Reorder before you run cold, with the lead time you choose.',
    'scorte-calore.promo.03-widget' => 'The widget that counts the days, on your home screen.',
    'scorte-calore.promo.04-gpl' => 'LPG tanks too: read the gauge and the app turns it into litres.',
    'scorte-calore.promo.05-misure' => 'Bags, kilos, litres: measure your way, whenever.',
    'scorte-calore.promo.06-consumo' => 'It learns your usage and spots refills on its own.',
    'scorte-calore.promo.07-nessun-account' => 'No account, no ads: your data stays on your phone.',
    'scorte-calore.promo.08-costi' => 'What you spend each winter: purchases, costs and average price (Pro).',
    'scorte-calore.promo.09-fonti' => 'Stove and LPG tank together: every heat source (Pro).',
    'scorte-calore.promo.10-mai-piu' => 'Never cold again: your stock always under control.',
    'scorte-calore.titolo'             => 'Scorte Calore, how many days of heating you have left',
    'scorte-calore.descrizione'        => 'Scorte Calore works out how many days of pellets, LPG, heating oil or firewood you have left and when to reorder. Free, Pro €2.99 one-off.',
    'scorte-calore.hero.titolo'        => 'How many days<br>are left?',
    'scorte-calore.hero.lede'          => 'Pellets, LPG, heating oil or firewood: update your stock now and then with the number in front of you, and Scorte Calore tells you how many days of heating you have left and when to reorder.',
    'scorte-calore.img.testata'        => 'Scorte Calore: pellets, LPG, oil, firewood. How many days are left, and the right day to reorder.',
    'scorte-calore.schermate.1'        => 'Days left and the reorder date',
    'scorte-calore.schermate.2'        => 'Updating the stock, even from the LPG gauge',
    'scorte-calore.schermate.3'        => 'History and use between readings',
    'scorte-calore.schermate.4'        => 'Purchases and the winter\'s spending',
    'scorte-calore.schermate.5'        => 'Pro, a single purchase',
    'scorte-calore.problema.titolo'    => 'You notice when it\'s too late',
    'scorte-calore.problema.lede'      => 'Stock gets checked by eye: “there\'s enough for a while”. Then the stove stops on a Saturday night in January and the supplier delivers the week after. Scorte Calore does the maths for you, before you need it.',
    'scorte-calore.problema.1.titolo'  => 'Measure the way you already do',
    'scorte-calore.problema.1.testo'   => 'Bags of pellets left, litres in the oil tank, the percentage on your LPG tank gauge, cubic metres or quintals of firewood: type the number in front of you, in the unit you use.',
    'scorte-calore.problema.2.titolo'  => 'It learns your consumption',
    'scorte-calore.problema.2.testo'   => 'From your readings it works out your average use per day and spots refills by itself. Even with weeks between readings, the estimate holds up.',
    'scorte-calore.problema.3.titolo'  => 'It tells you when to order',
    'scorte-calore.problema.3.testo'   => 'The day your stock runs out and the day to reorder by, as many days ahead as you choose: as many as your supplier needs.',
    'scorte-calore.funzioni.titolo'    => 'What\'s inside',
    'scorte-calore.funzioni.lede'      => 'Everything you need to stay warm, and nothing else.',
    'scorte-calore.funzioni.1.titolo'  => 'The days, in big numbers',
    'scorte-calore.funzioni.1.testo'   => 'Open the app and see the days left, your average use per day, the reorder date and how much is left since the last refill.',
    'scorte-calore.funzioni.2.titolo'  => 'Your LPG tank',
    'scorte-calore.funzioni.2.testo'   => 'Read the percentage on the gauge and the app turns it into usable litres, knowing the tank is never filled beyond 80 per cent.',
    'scorte-calore.funzioni.3.titolo'  => 'The Home Screen widget',
    'scorte-calore.funzioni.3.testo'   => 'Days left and the reorder date on your Home Screen, without opening the app. The count goes down by itself every day, and it\'s free.',
    'scorte-calore.funzioni.4.titolo'  => 'A notification at the right time',
    'scorte-calore.funzioni.4.testo'   => 'With Pro, a notification on the day to reorder, and another one if the date passes and you haven\'t updated your stock.',
    'scorte-calore.funzioni.5.titolo'  => 'Winter against winter',
    'scorte-calore.funzioni.5.testo'   => 'With Pro, the full history with consumption charts, and your purchases: what you spend each winter and the average price per unit.',
    'scorte-calore.funzioni.6.titolo'  => 'In your phone\'s calendar',
    'scorte-calore.funzioni.6.testo'   => 'With Pro, the reorder date becomes an event in the calendar you choose. If the estimate changes the app points it out, and you move it with one tap.',
    'scorte-calore.prezzi.titolo'      => 'Free, then Pro if you need it',
    'scorte-calore.prezzi.lede'        => 'The free version already answers the question: how many days are left. Pro is a single purchase, no subscription, no renewal; if you change phone you restore it from the store, with the same account.',
    'scorte-calore.prezzi.base.lista'  => '<li>One heat source</li><li>Unlimited readings, the full estimate of consumption and days left</li><li>The reorder date, as many days ahead as you choose</li><li>The last 90 days of readings in the history</li><li>The Home Screen widget</li><li>Restoring from a backup</li><li>No ads, no account</li>',
    'scorte-calore.prezzi.pro.lista'   => '<li>Everything in the basic version</li><li><strong>Notifications</strong>: on the day to reorder, and if the date passes</li><li>Every heat source: the stove and the LPG tank, home and holiday home</li><li>Full history and consumption charts</li><li>Purchases and costs: each winter\'s spending and the average price</li><li>The reorder date in your phone\'s calendar</li><li>Spreadsheet export and full backup</li>',
    'scorte-calore.privacy.titolo'     => 'Your data stays yours',
    'scorte-calore.privacy.testo'      => 'Scorte Calore has no account, asks for no sign-up and collects no usage statistics. Heat sources, readings and purchases live in your phone\'s storage and are not sent anywhere. If you add the reorder date to your calendar, the event goes into the phone calendar you choose, and from there it follows that calendar. The only thing that leaves the device is the purchase check, because the store does it.',

    // ── Pagina Film Tracker ──────────────────────────────────────────────────
    'film-tracker.promo.02-in-macchina' => 'What\'s in the camera? In the camera, at the lab, in the archive.',
    'film-tracker.promo.03-provini' => 'A contact sheet for every roll, with zoom.',
    'film-tracker.promo.04-qr' => 'A QR code on the canister: scan it and the right roll opens.',
    'film-tracker.promo.05-pellicole' => 'Every film stock, plus your own.',
    'film-tracker.promo.06-tirato' => 'Pushed or pulled: the ISO you shot at, next to box speed.',
    'film-tracker.promo.07-nessun-account' => 'No account, no ads: your rolls stay on your phone.',
    'film-tracker.promo.08-costi' => 'What each roll costs you: film, developing, scans and prints (Pro).',
    'film-tracker.promo.09-pdf' => 'Your year in a printable PDF, with photos (Pro).',
    'film-tracker.promo.10-stampa' => 'From shot to print: lab or home developing.',
    'film-tracker.titolo'              => 'Film Tracker, the diary of your film rolls',
    'film-tracker.descrizione'         => 'Film Tracker follows every roll from the camera to the contact sheet: film, developing, prints, costs and photos, with a QR label for the canister. Free, Pro €4.99 one-off.',
    'film-tracker.hero.titolo'         => 'What\'s in<br>the camera?',
    'film-tracker.hero.lede'           => 'The diary of your film rolls: you always know what\'s in the camera, what\'s waiting at the lab and what\'s already in the archive, with the photos of every roll.',
    'film-tracker.img.testata'         => 'Film Tracker: the diary of your film rolls, from the camera to the contact sheet.',
    'film-tracker.schermate.1'         => 'In camera, at the lab, in the archive',
    'film-tracker.schermate.2'         => 'A roll\'s story, with dates and costs',
    'film-tracker.schermate.3'         => 'The archive as a contact sheet',
    'film-tracker.schermate.4'         => 'The QR label for the canister',
    'film-tracker.schermate.5'         => 'Your yearly statistics',
    'film-tracker.schermate.6'         => 'Pro, a single purchase',
    'film-tracker.problema.titolo'     => 'Which roll was that?',
    'film-tracker.problema.lede'       => 'Three finished rolls in the same drawer, one at the lab for weeks, and nobody remembers what ISO the one in the camera is being shot at. Film Tracker keeps the diary for you, from loading to contact sheet.',
    'film-tracker.problema.1.titolo'   => 'You load it, it follows it',
    'film-tracker.problema.1.testo'    => 'Pick the film from the catalogue (Kodak, Ilford, Fujifilm, Fomapan, Cinestill and more, plus your own), the camera and the ISO. From there the roll goes from finished to at the lab, developed, printed.',
    'film-tracker.problema.2.titolo'   => 'You always know where it is',
    'film-tracker.problema.2.testo'    => 'Three sections: in camera, with the days since you loaded it; at the lab, longest wait on top; and the archive, with the photos.',
    'film-tracker.problema.3.titolo'   => 'No more mixed-up rolls',
    'film-tracker.problema.3.testo'    => 'Every roll gets a QR label to print or photograph and stick on the canister. Scan it with the camera and the app opens on that roll.',
    'film-tracker.funzioni.titolo'     => 'What\'s inside',
    'film-tracker.funzioni.lede'       => 'Everything you need to keep track of your rolls, and nothing else.',
    'film-tracker.funzioni.1.titolo'   => 'The roll\'s timeline',
    'film-tracker.funzioni.1.testo'    => 'Dates and costs of every step: film, developing, scans, prints. And the roll\'s total cost, always in sight.',
    'film-tracker.funzioni.2.titolo'   => 'Developing and prints',
    'film-tracker.funzioni.2.testo'    => 'At the lab or at home, and as many print orders as you like, each with its date and cost.',
    'film-tracker.funzioni.3.titolo'   => 'Photos, for free',
    'film-tracker.funzioni.3.testo'    => 'Photos of the contact sheet, prints or scans, with zoom. The archive becomes a contact sheet with the pictures of every roll.',
    'film-tracker.funzioni.4.titolo'   => 'Pushed or pulled',
    'film-tracker.funzioni.4.testo'    => 'The ISO you shot at next to the box speed: when you take the roll to be developed, it\'s right there.',
    'film-tracker.funzioni.5.titolo'   => 'Your year in numbers',
    'film-tracker.funzioni.5.testo'    => 'With Pro, yearly statistics: rolls, spending on film, developing and prints, average cost per roll. And your year as a printable PDF, with the photos.',
    'film-tracker.funzioni.6.titolo'   => 'Dark, for the photos',
    'film-tracker.funzioni.6.testo'    => 'On a dark background photos keep their contrast. If you prefer light, there\'s the “light table” theme.',
    'film-tracker.prezzi.titolo'       => 'Free, then Pro if you need it',
    'film-tracker.prezzi.lede'         => 'In the free version rolls and photos are unlimited. Pro is a single purchase, no subscription, no renewal; if you change phone you restore it from the store, with the same account.',
    'film-tracker.prezzi.base.lista'   => '<li>Unlimited rolls</li><li>One camera</li><li>The film catalogue, plus your own</li><li>Developing, prints and costs of every roll</li><li>All the photos, with zoom</li><li>A QR label for every roll</li><li>Restoring from a backup</li><li>No ads, no account</li>',
    'film-tracker.prezzi.pro.lista'    => '<li>Everything in the basic version</li><li><strong>All your cameras</strong>, each with its own rolls</li><li>Yearly statistics: rolls and spending</li><li>Your year as a PDF, with the photos</li><li>Spreadsheet export</li><li>Full backup, photos included</li>',
    'film-tracker.privacy.titolo'      => 'Your data stays yours',
    'film-tracker.privacy.testo'       => 'Film Tracker has no account, asks for no sign-up and collects no usage statistics. Rolls, costs and photos live in your phone\'s storage and are not sent anywhere. The camera and photo library open only when you add a photo to a roll. The only thing that leaves the device is the purchase check, because the store does it.',

    // ── Contact ─────────────────────────────────────────────────────────────
    'contatti.titolo'      => 'Contact and custom development',
    'contatti.descrizione' => 'Write in about a bug report, a question on the apps, or to '
                            . 'have an application built for you.',
    'contatti.eyebrow'     => 'Let\'s talk',
    'contatti.h1'          => 'Write to me',
    'contatti.lede'        => 'Bug reports, questions about the apps and custom development '
                            . 'enquiries all arrive in the same place, and one person reads '
                            . 'them.',

    'contatti.misura.titolo' => 'Custom development',
    'contatti.misura.testo'  => 'Android and iPhone apps, business tools, automations and internal '
                              . 'utilities. Describe the problem and the context it comes '
                              . 'from: the first reply tells you whether it is feasible, on '
                              . 'what timescale and in what order of cost.',
    'contatti.bug.titolo'    => 'Reporting a problem',
    'contatti.bug.testo'     => 'Give me your phone model, your Android or iOS version and what you '
                              . 'were doing when it happened. With those three things a bug '
                              . 'reproduces in minutes; without them it often doesn\'t '
                              . 'reproduce at all.',
    'contatti.recapiti.titolo' => 'Direct contacts',
    'contatti.recapiti.pec'    => '(certified email)',

    // ── The form ────────────────────────────────────────────────────────────
    'form.titolo'      => 'The form',
    'form.nome'        => 'Name',
    'form.email'       => 'Email',
    'form.email.aiuto' => 'Only used to reply to you.',
    'form.argomento'   => 'Subject',
    'form.scegli'      => 'Choose…',
    'form.app'         => 'App concerned',
    'form.app.ph'      => 'TrashCan, or leave empty',
    'form.app.aiuto'   => 'For a bug report, add your phone model and Android or iOS version in the '
                        . 'message.',
    'form.messaggio'   => 'Message',
    'form.consenso'    => 'I have read the <a href="{privacy}">privacy policy</a> and I '
                        . 'consent to my data being processed in order to receive a reply to '
                        . 'this message.',
    'form.invia'       => 'Send the message',
    'form.obbligatori' => 'Fields marked with * are required. Data controller: '
                        . '{denominazione}.',
    'form.trappola'    => 'Do not fill in this field',

    'form.ok.titolo'   => 'Message received.',
    'form.ok.testo'    => 'I will reply to the address you gave, usually within two working '
                        . 'days.',
    'form.ok.salvato'  => 'The message has been recorded correctly.',
    'form.ko.titolo'   => 'The message was not sent.',

    'form.arg.bug'            => 'Bug report',
    'form.arg.personalizzato' => 'Custom development enquiry',
    'form.arg.app'            => 'Question about one of the apps',
    'form.arg.privacy'        => 'Privacy and personal data',
    'form.arg.altro'          => 'Something else',

    'form.err.sessione'  => 'This page has been open too long. Reload it and send the '
                          . 'message again.',
    'form.err.nome'      => 'Enter a name between 2 and 80 characters.',
    'form.err.email'     => 'Enter a valid email address: it is how I reply to you.',
    'form.err.argomento' => 'Pick one of the subjects offered.',
    'form.err.corto'     => 'Write a few more lines: under 20 characters there is no telling '
                          . 'what you need.',
    'form.err.lungo'     => 'The message is over 5,000 characters. Shorten it, or send the '
                          . 'rest by email.',
    'form.err.consenso'  => 'To receive a reply you must confirm that you have read the '
                          . 'privacy policy.',
    'form.err.limite'    => 'You have sent several messages in the past hour. Try again '
                          . 'later, or write directly to {email}.',
    'form.err.archivio'  => 'The message could not be recorded. Please write directly to '
                          . '{email}, so that nothing gets lost.',

    // ── Legal pages: headers ────────────────────────────────────────────────
    'legale.occhiello' => 'Legal',

    'legale.note-legali.titolo'      => 'Legal notice',
    'legale.note-legali.descrizione' => 'Identifying details of the owner of smpmicroapps.it and of '
                               . 'the SMP MicroApps applications.',
    'legale.note-legali.sommario'    => 'Who runs this website and the applications presented on it.',

    'legale.privacy.titolo'      => 'Privacy policy',
    'legale.privacy.descrizione' => 'How personal data is processed on smpmicroapps.it and '
                                  . 'in the SMP MicroApps applications.',
    'legale.privacy.sommario'    => 'What data we collect, why, for how long and what rights '
                                  . 'you have. Provided under Articles 13 and 14 of '
                                  . 'Regulation (EU) 2016/679.',

    'legale.cookie.titolo'      => 'Cookie policy',
    'legale.cookie.descrizione' => 'Which cookies smpmicroapps.it uses: technical cookies '
                                 . 'only, no profiling cookies and no third-party resources.',
    'legale.cookie.sommario'    => 'This website uses no profiling cookies and loads nothing '
                                 . 'from third-party servers.',

    'legale.termini.titolo'      => 'Terms of service',
    'legale.termini.descrizione' => 'Terms of use of the smpmicroapps.it website and licence '
                                  . 'for the SMP MicroApps applications.',
    'legale.termini.sommario'    => 'The rules for using the website and the licence under '
                                  . 'which the applications are granted to you.',

    'legale.responsabilita.titolo'      => 'Disclaimer',
    'legale.responsabilita.descrizione' => 'Limitations of liability regarding the use of '
                                         . 'the website and of the SMP MicroApps '
                                         . 'applications.',
    'legale.responsabilita.sommario'    => 'What we can guarantee, what we cannot, and why.',
];
