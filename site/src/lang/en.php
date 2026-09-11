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
    'comune.data_legale'       => '11 September 2026',
    'comune.scopri'            => 'Find out more &rarr;',
    'comune.in_lavorazione'    => 'In the works',
    'comune.in_arrivo'         => 'Coming soon',
    'comune.disponibile'       => 'Available',
    'comune.presto_play'       => 'Soon on Google Play',
    'comune.scarica_play'      => 'Get it on Google Play',

    // ── Navigation ──────────────────────────────────────────────────────────
    'nav.app'         => 'The apps',
    'nav.contatti'    => 'Contact',
    'nav.su_misura'   => 'Custom development',
    'nav.principale'  => 'Main',
    'nav.apri'        => 'Open the menu',
    'nav.chiudi'      => 'Close the menu',
    'nav.mostra_app'  => 'Show the apps',

    // ── Footer ──────────────────────────────────────────────────────────────
    'footer.blurb'       => 'Small Android apps that do one thing and do it well. Free in '
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
                          . 'Google LLC.',

    // ── The catalogue ───────────────────────────────────────────────────────
    'app.trashcan.prezzo'   => '€2.99',
    'app.trashcan.claim'    => 'What goes out tonight?',
    'app.trashcan.sommario' => 'Your town\'s waste collection calendar, with a reminder the '
                             . 'evening before. No more bin left behind.',

    'app.full-freezer.claim'    => 'What\'s in the freezer, and since when.',
    'app.full-freezer.sommario' => 'Your freezer inventory sorted by age, so the oldest '
                                 . 'thing in there is the next one you eat.',

    'app.scorte-calore.claim'    => 'How much pellet you actually have left.',
    'app.scorte-calore.sommario' => 'Average consumption, remaining range and the date to '
                                  . 'reorder. For pellets, heating oil, LPG and firewood.',

    'app.film-tracker.claim'    => 'A diary for your film rolls.',
    'app.film-tracker.sommario' => 'Stocks, frames, shutter speeds and apertures. For film '
                                 . 'photographers who don\'t want to lose their development '
                                 . 'notes.',

    // ── Home ────────────────────────────────────────────────────────────────
    'home.titolo'      => 'Small Android apps that do one thing',
    'home.descrizione' => 'SMP MicroApps: lightweight Android apps with no accounts and no '
                        . 'subscriptions. Free base version, Pro with a one-off purchase.',

    'home.eyebrow'      => 'Android apps',
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
                            . 'widget. Free, Pro for €2.99 one-off.',

    'trashcan.eyebrow'     => 'TrashCan · Android',
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
    'trashcan.problema.3.testo'  => 'Holidays, skipped rounds and extra collections: you '
                                  . 'mark the change on that single day and the reminder '
                                  . 'adjusts itself, without touching the rule.',

    'trashcan.funzioni.titolo' => 'What you get',
    'trashcan.funzioni.lede'   => 'Everything you need to get the bin right, and nothing '
                                . 'else.',
    'trashcan.funzioni.1.titolo' => 'The "Tonight" screen',
    'trashcan.funzioni.1.testo'  => 'Open the app and the first thing you see is what to put '
                                  . 'out tonight, large and colour-coded. Below it, the next '
                                  . 'collection and the following seven days.',
    'trashcan.funzioni.2.titolo' => 'The home screen widget',
    'trashcan.funzioni.2.testo'  => 'Narrow and vertical: the coloured header says what goes '
                                  . 'out tonight, with its icon; below, the next three days. '
                                  . 'Free, without opening the app.',
    'trashcan.funzioni.3.titolo' => 'A reminder on time',
    'trashcan.funzioni.3.testo'  => 'One notification at the time you choose, the evening '
                                  . 'before collection. Tap it and it opens that exact day.',
    'trashcan.funzioni.4.titolo' => 'Your own waste types',
    'trashcan.funzioni.4.testo'  => 'Every council has its own categories and its own names. '
                                  . 'Start from the ready-made types and rename them, change '
                                  . 'icon and colour, or create your own.',
    'trashcan.funzioni.5.titolo' => 'Backup and export',
    'trashcan.funzioni.5.testo'  => 'A single file holding the whole calendar: save it where '
                                  . 'you like, restore it on another phone, or pass it to a '
                                  . 'relative living on the same street.',
    'trashcan.funzioni.6.titolo' => 'English and Italian',
    'trashcan.funzioni.6.testo'  => 'The app follows your phone\'s language. So do the dates '
                                  . 'and the weekday names.',

    'trashcan.prezzi.titolo' => 'Free, then Pro if you need it',
    'trashcan.prezzi.lede'   => 'One purchase, no subscription, no renewal. Change phone and '
                              . 'you restore it from your Google account; if you changed '
                              . 'account too, there is a transfer code inside the app.',
    'trashcan.prezzi.base'      => 'Base',
    'trashcan.prezzi.gratis'    => 'Free',
    'trashcan.prezzi.pro'       => 'Pro',
    'trashcan.prezzi.unatantum' => 'one-off',
    'trashcan.prezzi.base.lista' => '<li>One collection calendar</li>'
        . '<li>Unlimited waste types and rules</li>'
        . '<li>Exceptions, skips and extra collections</li>'
        . '<li>Widget showing tonight\'s collection and the next three days</li>'
        . '<li>Calendar export and backup</li>'
        . '<li>No advertising</li>',
    'trashcan.prezzi.pro.lista' => '<li>Everything in the base version</li>'
        . '<li><strong>The reminders</strong>: the notification the evening before</li>'
        . '<li>A second reminder, for anyone who ignores the first</li>'
        . '<li>Multiple calendars: home, holiday house, your parents\'</li>'
        . '<li>The app colour, chosen by you out of ten</li>',

    'trashcan.privacy.titolo' => 'Your data stays yours',
    'trashcan.privacy.testo'  => 'TrashCan has no account, asks for no registration and '
                               . 'collects no usage analytics. The calendar, the waste types '
                               . 'and the reminders live in your phone\'s storage and are '
                               . 'never sent anywhere. The only thing that leaves the device '
                               . 'is the purchase check, because Google performs it.',
    'trashcan.privacy.link'   => 'Read the full privacy policy &rarr;',

    'trashcan.bug.titolo'  => 'Something wrong, or something missing?',
    'trashcan.bug.testo'   => 'Reports are read by one person, who is the same person who '
                            . 'writes the code. Tell me what happened and on which phone: it '
                            . 'is the fastest way to get it fixed.',
    'trashcan.bug.bottone' => 'Report a problem',

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
    'contatti.misura.testo'  => 'Android apps, business tools, automations and internal '
                              . 'utilities. Describe the problem and the context it comes '
                              . 'from: the first reply tells you whether it is feasible, on '
                              . 'what timescale and in what order of cost.',
    'contatti.bug.titolo'    => 'Reporting a problem',
    'contatti.bug.testo'     => 'Give me your phone model, your Android version and what you '
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
    'form.app.aiuto'   => 'For a bug report, add your phone model and Android version in the '
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
