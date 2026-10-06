<?php

/**
 * The bodies of the legal pages, in English.
 *
 * ☠ These are a translation of the Italian texts, not a separate document. **Italian
 * governs**: the company is Italian, the contract is governed by Italian law and the
 * references are to Italian statutes. Where a translation could be read as narrowing a
 * right, the Italian wording prevails, and the page says so.
 *
 * ☠ NOWDOC, not heredoc: nothing is interpolated, so a `$` stays a `$` and the
 * `{placeholder}` markers survive intact.
 */

declare(strict_types=1);

return [

'legale.note-legali.corpo' => <<<'HTML'
<div class="box">
  <p>
    This is a translation provided for convenience. The <a href="{url_it}">Italian version</a>
    is the governing text: the business is established in Italy and these notices implement
    Italian statutory duties.
  </p>
</div>

<h2>Website owner</h2>

<div class="scroll-x">
  <table>
    <tr><th>Business name</th><td>{denominazione}</td></tr>
    <tr><th>Owner</th><td>{titolare}</td></tr>
    <tr><th>Registered address</th><td>{indirizzo}, {cap} {citta} ({provincia}), {paese}</td></tr>
    <tr><th>VAT and tax number</th><td>{piva}</td></tr>
    <tr><th>Email</th><td><a href="mailto:{email}">{email}</a></td></tr>
    <tr><th>Certified email (PEC)</th><td><a href="mailto:{pec}">{pec}</a></td></tr>
    <tr><th>Website</th><td>{sito}</td></tr>
  </table>
</div>

<h2>What this website is</h2>

<p>
  This website presents the Android and iPhone applications developed and distributed by the owner named
  above, and provides a form for requesting support, reporting malfunctions and enquiring
  about custom software development services.
</p>

<p>
  This website <strong>is not a shop</strong>: no purchase contract is concluded here and no
  payment is taken here. The applications, and the additional features within them, are
  distributed and sold exclusively through Google Play, operated by Google Ireland Limited, and
  the App Store, operated by Apple Distribution International Ltd. Pricing, the right of
  withdrawal and the refund procedure for those purchases are governed by the terms of the store
  you bought from, as set out in the <a href="{url_termini}">terms of service</a>.
</p>

<h2>Intellectual property</h2>

<p>
  The text, graphics, logos, icons, application source code and every other item of content on
  this website belong to the owner unless stated otherwise, and are protected by copyright law.
  Reproduction, in whole or in part, without written permission is prohibited.
</p>

<p>
  Android, Google Play and the Google Play logo are trademarks of Google LLC. They are named
  here for descriptive purposes only and this implies no affiliation with, sponsorship by or
  endorsement from Google.
</p>

<p>
  Apple, iPhone and App Store are trademarks of Apple Inc., registered in the U.S. and other
  countries. The same applies: they are named for descriptive purposes only and this implies no
  relationship with Apple.
</p>

<h2>Reporting content</h2>

<p>
  To report content you believe infringes your rights, write to
  <a href="mailto:{email}">{email}</a> or, for communications with legal effect, to the
  certified mailbox <a href="mailto:{pec}">{pec}</a>. Reports are reviewed and, where founded,
  the content is removed without delay.
</p>

<h2>Governing law and jurisdiction</h2>

<p>
  The relationship with users of this website is governed by Italian law. For disputes with
  persons acting outside their trade or profession (consumers), the court of the consumer's
  place of residence or domicile has jurisdiction, where that is in Italy. In all other cases
  the courts of Viterbo, Italy, have exclusive jurisdiction.
</p>

<div class="box">
  <p>
    Information on the processing of personal data is in the <a href="{url_privacy}">privacy
    policy</a>. Information on cookies is in the <a href="{url_cookie}">cookie policy</a>.
  </p>
</div>
HTML,

'legale.privacy.corpo' => <<<'HTML'
<div class="box">
  <p>
    This is a translation provided for convenience. The <a href="{url_it}">Italian version</a>
    is the governing text. Nothing in this translation restricts any right granted to you by
    Regulation (EU) 2016/679.
  </p>
</div>

<div class="toc">
  <strong>In short</strong>
  <ol>
    <li>The apps work with no account and no registration.</li>
    <li>What you enter into the apps stays in your phone's storage.</li>
    <li>We use no analytics, profiling or advertising tools, neither on the site nor in the apps.</li>
    <li>The only data that leaves your phone concerns verifying the Pro purchase.</li>
    <li>The contact form collects only what you type into it.</li>
  </ol>
</div>

<h2>1. Data controller</h2>

<p>
  <strong>{denominazione}</strong>, {indirizzo}, {cap} {citta} ({provincia}), {paese} — VAT and
  tax number {piva}.
</p>
<p>
  To exercise your rights, or for any question about this policy, write to
  <a href="mailto:{email}">{email}</a> or, by certified email, to
  <a href="mailto:{pec}">{pec}</a>.
</p>
<p>
  No data protection officer has been appointed: none of the cases in which Article 37 of the
  Regulation makes one mandatory applies here.
</p>

<h2>2. Browsing this website</h2>

<h3>Connection data</h3>

<p>
  The server hosting this website records, as any web server does, the requests it receives: IP
  address, date and time, the address of the page requested, the outcome of the request, and
  the browser and operating system declared. This data is not linked to an identified user and
  is not used to build profiles.
</p>

<div class="scroll-x">
  <table>
    <tr><th>Purpose</th><td>Technical operation of the site, fault diagnosis, security and defence against abuse.</td></tr>
    <tr><th>Legal basis</th><td>The controller's legitimate interest in delivering and protecting the service (Art. 6(1)(f)).</td></tr>
    <tr><th>Retention</th><td>30 days at most, after which log files are deleted automatically.</td></tr>
  </table>
</div>

<h3>Language and cookies</h3>

<p>
  This site uses no profiling cookies, includes no analytics tools and loads no resource from
  third-party servers: fonts, stylesheets and images are all served from this same domain. Only
  two cookies are set, both technical: the one remembering your chosen language, and the
  session cookie on the contact page.
</p>

<p>
  On your first visit, if you have not yet chosen a language, the site reads the
  <code>Accept-Language</code> header sent by your browser in order to decide whether to show
  you the Italian or the English version. It is read on the spot, the value is not stored, and
  it is used for nothing else. See the <a href="{url_cookie}">cookie policy</a> for details.
</p>

<h2>3. Contact form</h2>

<p>
  When you submit the form we collect <strong>your name, email address, subject, the app you
  may have named, and the text of your message</strong>. There is no other field, and nothing
  is inferred or enriched from outside sources.
</p>

<div class="scroll-x">
  <table>
    <tr><th>Purpose</th><td>Replying to your request and, where needed, handling the report through to resolution.</td></tr>
    <tr><th>Legal basis</th><td>Consent, given by ticking the box before sending (Art. 6(1)(a)). For requests relating to an ongoing service, performance of pre-contractual or contractual measures (Art. 6(1)(b)).</td></tr>
    <tr><th>Provision</th><td>Optional, but without a name, an email address and a message there is no way to reply.</td></tr>
    <tr><th>Retention</th><td>24 months from the last exchange of messages, unless retention is required to comply with a legal obligation or to defend a legal claim.</td></tr>
  </table>
</div>

<p>
  Every message received is recorded on our server and, where the mailbox is configured,
  forwarded to the business address. We also record, for one hour, a value derived from your IP
  address through a hash function: it serves solely to limit repeated submissions from the same
  connection. The IP address itself is not retained in clear.
</p>

<h2>4. The applications</h2>

<h3>What stays on your phone</h3>

<p>
  SMP MicroApps applications <strong>require no registration and have no accounts</strong>.
  Everything you enter — in TrashCan's case: calendars, waste types, collection rules,
  exceptions, reminder times and preferences — is saved in a local database in your device's
  storage, protected by the app isolation Android and iOS provide. This data is never transmitted to
  us, we cannot see it and we cannot recover it for you: uninstall the app without having
  exported, and it is gone.
</p>

<p>
  Notifications are scheduled by the phone's operating system and their content passes through
  no server. We use no remote push notifications. The widget reads the same local data.
</p>

<p>
  The export function produces a file that <strong>you</strong> choose where to save or whom to
  send it to. At that point the data leaves the app because you asked it to, and from then on
  its processing depends on the service you chose to store or share it with.
</p>

<h3>Buying and verifying the Pro version</h3>

<p>
  The Pro version is purchased entirely on Google Play, if you use Android, or on the App
  Store, if you use iPhone. We neither receive nor process your payment data: the card, the
  billing details and the purchaser's identity stay with Google or Apple, which act as
  independent controllers. See
  <a href="https://policies.google.com/privacy" rel="noopener">Google's privacy policy</a> and
  <a href="https://www.apple.com/legal/privacy/" rel="noopener">Apple's</a>.
</p>

<p>
  <strong>On iPhone</strong> the app communicates with no server of ours: the phone itself
  verifies the purchase with Apple, and we receive nothing. What follows, up to and including
  the transfer code, applies to Android only.
</p>

<p>
  <strong>On Android</strong>, in order to recognise a valid purchase, and to stop one licence
  being reused on an unlimited number of devices, the app communicates with a server of ours.
  The data processed at that stage is:
</p>

<div class="scroll-x">
  <table>
    <tr>
      <th>Installation identifier</th>
      <td>A random code generated by the app on first launch. It is not derived from any device
        identifier, it is not the Android advertising ID, it cannot be traced back to you, and
        it changes if you uninstall and reinstall the app.</td>
    </tr>
    <tr>
      <th>Purchase token and order number</th>
      <td>Issued by Google Play at the moment of purchase. They are used to verify with Google
        that the purchase is real and has not been refunded.</td>
    </tr>
    <tr>
      <th>App identifier, product purchased, status and dates</th>
      <td>So we know what you are entitled to, and since when.</td>
    </tr>
    <tr>
      <th>App version and platform</th>
      <td>To diagnose problems tied to a specific version.</td>
    </tr>
  </table>
</div>

<div class="box">
  <p>
    <strong>We do not process your email address, your name, your Google account or your
    Apple ID.</strong>
    Our purchase records contain no data capable of identifying you: they contain a random code
    and the proof that a valid purchase corresponds to it.
  </p>
</div>

<div class="scroll-x">
  <table>
    <tr><th>Purpose</th><td>Verifying the purchase, delivering the features bought, handling refunds and revocations, preventing licence abuse.</td></tr>
    <tr><th>Legal basis</th><td>Performance of the contract for the supply of the digital content purchased (Art. 6(1)(b)) and legitimate interest in fraud prevention (Art. 6(1)(f)).</td></tr>
    <tr><th>Retention</th><td>For the duration of the licence, which is permanent, and for 10 years thereafter for accounting obligations and the defence of legal claims.</td></tr>
  </table>
</div>

<h3>Transfer code</h3>

<p>
  If you change both phone and Google account, the app can generate a temporary code to move
  the licence to the new device. The code is random, expires after seven days, can be used only
  once and is linked solely to the installation identifier. It contains and reveals no personal
  data.
</p>

<h3>No usage analytics</h3>

<p>
  The apps contain no analytics tools (Firebase Analytics, Crashlytics or equivalents), collect
  no statistics on how you use them, do not record the screens you open, and contain no
  advertising and no advertising identifiers.
</p>

<h2>5. Who we share data with</h2>

<p>
  Data is never sold, transferred or disclosed to third parties for commercial purposes. The
  following may access it, to the extent necessary to deliver the service:
</p>

<ul>
  <li><strong>The hosting provider</strong> of the website and of the licence server, acting as
    a processor under Article 28 of the Regulation. The servers are located in the European
    Union.</li>
  <li><strong>Google Ireland Limited</strong>, as an independent controller, for everything
    concerning distribution of the app and purchases on the Play Store.</li>
  <li><strong>Apple Distribution International Ltd</strong>, as an independent controller, for
    everything concerning distribution of the app and purchases on the App Store.</li>
  <li><strong>The email service provider</strong> through which messages sent from the contact
    form pass.</li>
  <li>Public authorities, where disclosure is required by law or by an order of the
    authorities.</li>
</ul>

<h2>6. Transfers outside the European Economic Area</h2>

<p>
  Processing normally takes place within the European Union. Verifying purchases involves a
  query to Google's or Apple's systems, which may process data in the United States as well: that transfer
  relies on the European Commission's adequacy decision on the EU-US Data Privacy Framework and,
  in the alternative, on the standard contractual clauses adopted by the Commission.
</p>

<h2>7. Automated decision-making</h2>

<p>
  We carry out no profiling and no automated decision-making producing legal effects concerning
  you or similarly significantly affecting you, within the meaning of Article 22 of the
  Regulation.
</p>

<h2>8. Your rights</h2>

<p>Within the limits of Articles 15 to 22 of the Regulation you have the right to:</p>

<ul>
  <li>know whether we process data concerning you and obtain a copy of it (access);</li>
  <li>have inaccurate data corrected and incomplete data completed (rectification);</li>
  <li>obtain erasure of the data, where no obligation to retain it applies;</li>
  <li>ask for processing to be restricted, pending a verification;</li>
  <li>object to processing based on legitimate interest;</li>
  <li>receive the data in a structured, machine-readable format (portability);</li>
  <li>withdraw your consent at any time, without affecting the lawfulness of processing carried
    out before the withdrawal.</li>
</ul>

<div class="box">
  <p>
    <strong>A practical limit, stated plainly.</strong> Our purchase records hold no data
    capable of identifying you: if you write asking for access or erasure, we cannot link your
    request to a row in that register unless you give us the installation identifier or the
    Google Play order number. This is the situation contemplated by Article 11 of the
    Regulation. Give us those references and we will proceed.
  </p>
</div>

<p>
  Requests should be sent to <a href="mailto:{email}">{email}</a>. We reply without undue delay
  and in any case within one month, extendable by two months in complex cases, with notice to
  you.
</p>

<h2>9. Complaint to a supervisory authority</h2>

<p>
  If you consider that the processing of your data infringes the Regulation you may lodge a
  complaint with the Italian <strong>Garante per la protezione dei dati personali</strong>,
  Piazza Venezia 11, 00187 Rome —
  <a href="https://www.garanteprivacy.it" rel="noopener">garanteprivacy.it</a> — or bring court
  proceedings. If you live in another EU Member State you may instead approach the supervisory
  authority of your own country.
</p>

<h2>10. Children</h2>

<p>
  Neither the apps nor the website are aimed specifically at children, and we do not knowingly
  collect data of children under fourteen. If you believe a child has sent us personal data
  through the contact form, write to us and we will delete it.
</p>

<h2>11. Changes</h2>

<p>
  This policy may be updated to reflect changes in the service or in the law. The version in
  force is always the one published at this address, with the date of last update shown at the
  top of the page. Substantial changes affecting consent-based processing will be communicated
  to you before they take effect.
</p>
HTML,

'legale.cookie.corpo' => <<<'HTML'
<div class="box">
  <p>
    This is a translation provided for convenience. The <a href="{url_it}">Italian version</a>
    is the governing text.
  </p>
</div>

<h2>1. What cookies are</h2>

<p>
  Cookies are small text files a website saves in a visitor's browser, to be read back on later
  visits. They serve to remember information between one page and the next. The same rules
  apply to equivalent technologies, such as browser local storage or tracking pixels.
</p>

<h2>2. The cookies on this site</h2>

<p>This site uses <strong>two cookies only</strong>, both technical and first-party.</p>

<div class="scroll-x">
  <table>
    <tr>
      <th>Name</th>
      <th>When it is set</th>
      <th>What it is for</th>
      <th>Lifetime</th>
    </tr>
    <tr>
      <td><code>ma_lang</code></td>
      <td>On every page</td>
      <td>Remembers whether you are reading the site in Italian or in English, so that on your
        next visit you need not choose again and are no longer redirected automatically.</td>
      <td>1 year</td>
    </tr>
    <tr>
      <td><code>smpmicroapps</code></td>
      <td>Only when you open the <a href="{url_contatti}">Contact</a> page</td>
      <td>Ties the form to your browser session, so we can check that a submission really came
        from this site's form and not from a third-party page submitting it without your
        knowledge. Without it the form would be open to CSRF attacks.</td>
      <td>Until you close the browser</td>
    </tr>
  </table>
</div>

<p>
  Both are technical cookies: one stores a preference you expressed, the other is strictly
  necessary to deliver a service you requested. Under Article 122 of the Italian Privacy Code
  and the Italian Data Protection Authority's guidelines of 10 June 2021 they
  <strong>require no prior consent</strong>, which is why this site shows no banner.
</p>

<h2>3. Automatic language selection</h2>

<p>
  On your first visit, for as long as the <code>ma_lang</code> cookie does not exist, the site
  reads the <code>Accept-Language</code> header your browser sends with every request, which
  reflects the language set in your system. If you prefer English you are taken to the English
  version; otherwise you stay on the Italian one. The header is read and immediately discarded:
  it is not stored, not logged and not used for anything else.
</p>

<p>
  You can change the choice at any time with the flag at the top right, and from then on your
  choice applies rather than your browser's.
</p>

<h2>4. What this site does not do</h2>

<ul>
  <li>It uses no profiling cookies and no advertising cookies.</li>
  <li>It uses no analytics tools, first-party or third-party.</li>
  <li>It loads no fonts, stylesheets, scripts or images from external servers: every resource is
    served from this same domain, so no third party receives your IP address when you visit
    these pages.</li>
  <li>It embeds no videos, maps, social buttons or widgets from other services.</li>
  <li>It does not track browsing across sites and takes part in no advertising network.</li>
</ul>

<div class="box">
  <p>
    Links leading away from this site, for instance those to the app's Google Play and App Store listings,
    lead to pages run by other parties, which apply their own cookie policies. Once you leave
    here, their rules apply.
  </p>
</div>

<h2>5. The applications</h2>

<p>
  SMP MicroApps applications are not web pages and use no cookies. App preferences are saved in
  the device's local storage and are readable neither by any other program nor by us.
</p>

<h2>6. Managing cookies from your browser</h2>

<p>
  Every browser lets you view, block or delete cookies from its privacy settings. If you block
  this site's technical cookies the pages remain readable, but two things happen: your chosen
  language is not remembered between visits, and <strong>the contact form stops working</strong>,
  because without the session cookie the anti-CSRF check cannot succeed and the submission is
  refused. In that case you can write directly to <a href="mailto:{email}">{email}</a>.
</p>

<h2>7. Controller</h2>

<p>
  {denominazione}, {indirizzo}, {cap} {citta} ({provincia}) — VAT and tax number {piva}. For
  information: <a href="mailto:{email}">{email}</a>. See also the
  <a href="{url_privacy}">privacy policy</a>.
</p>
HTML,

'legale.termini.corpo' => <<<'HTML'
<div class="box">
  <p>
    This is a translation provided for convenience. The <a href="{url_it}">Italian version</a>
    is the governing text, and prevails in the event of any discrepancy. Nothing here limits
    the statutory rights of consumers under Italian and EU law.
  </p>
</div>

<h2>1. Who we are, and what these terms cover</h2>

<p>
  These terms govern the use of the website {sito} and of the Android and iPhone applications distributed
  under the SMP MicroApps name by <strong>{denominazione}</strong>, {indirizzo}, {cap} {citta}
  ({provincia}), VAT and tax number {piva} (hereinafter "the supplier").
</p>

<p>
  By using the website or the applications you accept these terms. If you do not accept them, do
  not use the service and uninstall the application.
</p>

<h2>2. This website sells nothing</h2>

<p>
  This website is purely informational. The applications are downloaded and purchased on
  <strong>Google Play</strong> or the <strong>App Store</strong>, and the purchase contract is
  concluded between you and <strong>Google Ireland Limited</strong> or <strong>Apple
  Distribution International Ltd</strong>, acting as resellers. The supplier does not collect the
  price directly, does not issue the purchase receipt and has no access to your payment data.
</p>

<div class="box">
  <p>
    It follows that <strong>refunds, chargebacks and the right of withdrawal on a purchase are
    requested from the store you bought from</strong>: from Google Play under Google's procedures,
    from the App Store under Apple's (reportaproblem.apple.com). If you have a problem the store
    does not resolve, write to us anyway: we can act on the technical side
    and, where we are permitted to, chase the case.
  </p>
</div>

<h2>3. Software licence</h2>

<p>
  The applications are not sold to you: you are granted a <strong>personal, non-exclusive,
  non-transferable and non-sublicensable</strong> licence of indefinite duration, to install and
  use them on devices you own or control.
</p>

<p>Buying the Pro version unlocks additional features of the application. It is:</p>

<ul>
  <li><strong>a single purchase</strong>, not a subscription: it does not renew and does not
    expire;</li>
  <li><strong>tied to your Google Play account or your Apple ID</strong>, not to one handset:
    change device and you can restore it from the same account. A purchase made on Google Play
    does not carry over to iPhone, nor the other way round: they are two separate stores;</li>
  <li><strong>specific to one application</strong>: buying one app does not unlock the others in
    the catalogue.</li>
</ul>

<p>You may not:</p>

<ul>
  <li>decompile, disassemble or attempt to derive the source code, save within the mandatory
    limits of Article 64-quater of Italian Law 633/1941;</li>
  <li>modify the application, or distribute derivative or modified versions of it;</li>
  <li>resell, rent, lend or transfer the licence to third parties;</li>
  <li>circumvent the limitations of the free version or the licence checks, nor distribute tools
    or instructions enabling others to do so;</li>
  <li>use the applications for unlawful purposes or in breach of the rights of others.</li>
</ul>

<h2>4. The transfer code</h2>

<p>
  For cases where restoring through Google Play is not possible — typically a change of Google
  account — the Android applications offer a temporary code to move the licence to another device. It is
  a support tool, subject to limits of validity, number and frequency. Using the code to share
  the licence with third parties breaches clause 3 and entitles the supplier to revoke the
  licence.
</p>

<h2>5. Updates and continuity of service</h2>

<p>
  The supplier may update the applications to fix defects, to keep up with new Android and iOS versions
  or to improve how they work. The supplier may also modify, suspend or discontinue distribution
  of an application, giving notice where reasonably possible.
</p>

<p>
  The applications work <strong>without an internet connection</strong> for all of their core
  features: should the supplier's online services ever cease, that does not prevent you from
  continuing to use an app already installed and already unlocked. Licence verification exists to
  activate the Pro version, not to keep it running day to day.
</p>

<h2>6. Statutory guarantee of conformity</h2>

<p>
  For consumers, the statutory guarantee of conformity of digital content under Articles
  135-octies et seq. of the Italian Consumer Code (Legislative Decree 206/2005) remains
  unaffected. If the application does not conform to what is described, you are entitled to have
  conformity restored and, in the cases provided for, to a price reduction or termination of the
  contract, through the procedures of the store you bought from. No clause of these terms limits those rights.
</p>

<h2>7. Liability</h2>

<p>
  The supplier is liable at law for damage caused by wilful misconduct or gross negligence, and
  in every case in which the law admits no limitation. For the rest, the
  <a href="{url_responsabilita}">disclaimer</a> applies and forms an integral part of these
  terms.
</p>

<h2>8. Personal data</h2>

<p>
  The processing of personal data is described in the <a href="{url_privacy}">privacy policy</a>.
  The applications keep the data you enter in your device's storage: <strong>backing it up is
  your responsibility</strong>, and the apps provide an export function for precisely that.
</p>

<h2>9. Support</h2>

<p>
  Support is requested through the <a href="{url_contatti}">contact form</a> or by writing to
  <a href="mailto:{email}">{email}</a>. No contractually guaranteed response times apply; the
  stated aim is to reply within two working days.
</p>

<h2>10. Changes to these terms</h2>

<p>
  These terms may be amended. The version in force is the one published at this address, with the
  date of last update at the top of the page. Amendments do not apply retroactively to purchases
  already made, where they would alter their essential content to your detriment.
</p>

<h2>11. Governing law, jurisdiction and dispute resolution</h2>

<p>
  Italian law applies. For consumers, the court of the place of residence or domicile has
  jurisdiction; in all other cases the courts of Viterbo, Italy, have exclusive jurisdiction.
</p>

<p>
  Consumers may also use the European online dispute resolution platform at
  <a href="https://ec.europa.eu/consumers/odr" rel="noopener">ec.europa.eu/consumers/odr</a>, or
  the competent mediation bodies.
</p>
HTML,

'legale.responsabilita.corpo' => <<<'HTML'
<div class="box">
  <p>
    This is a translation provided for convenience. The <a href="{url_it}">Italian version</a>
    is the governing text.
  </p>
</div>

<h2>1. What the apps show depends on you and on your council</h2>

<p>
  The applications process the data <strong>you</strong> enter. In TrashCan's case, the waste
  collection calendar is not downloaded from any official source: you configure it yourself,
  based on what your local council or waste management operator has told you.
</p>

<div class="box">
  <p>
    <strong>It follows that the application cannot guarantee that collection will take place on
    the days shown.</strong> Calendars, public holidays, suspensions and one-off changes are
    decided by the competent body and can change without notice. In case of doubt, only the
    official communication of your council or operator governs. The supplier is not liable for
    fines, disruption or missed collections arising from a calendar configured incorrectly or
    left out of date.
  </p>
</div>

<h2>2. Notifications depend on the operating system</h2>

<p>
  Reminders are scheduled through the notification services of Android and iOS. Their timely delivery is not
  guaranteed by the application and may be prevented or delayed by factors the app does not
  control: power saving, battery optimisation, "do not disturb" mode, the system suspending the
  app, device restarts, manufacturer customisations or permissions being revoked.
</p>

<p>
  <strong>A reminder is a help, not a reliable alerting system.</strong> It must not be relied
  upon where a missed alert would have significant consequences.
</p>

<h2>3. Your data is on your device</h2>

<p>
  Everything you enter is saved in your phone's storage. We keep no copy of it and cannot
  recover it for you. Losing or breaking the device, uninstalling the app, clearing the app's
  data or performing a factory reset will cause <strong>permanent loss</strong> of what you
  entered.
</p>

<p>
  The applications provide an export function for precisely this reason. Making and keeping
  backups is the user's responsibility.
</p>

<h2>4. Freedom from defects</h2>

<p>
  The software is developed and tested with the professional diligence that can reasonably be
  expected, but no program is free of defects. The applications are supplied "as is" as regards
  fitness for particular purposes not expressly stated, without prejudice to the statutory
  guarantee of conformity owed to consumers, referred to in clause 6 of the
  <a href="{url_termini}">terms of service</a>.
</p>

<h2>5. Website content and external links</h2>

<p>
  The content of this website is informational and may be updated or changed at any time.
  Descriptions of features refer to the most recent version of the applications: an earlier
  version installed on your device may behave differently.
</p>

<p>
  Links to third-party sites are provided for convenience. The supplier does not control those
  sites and is not responsible for their content, their availability or the policies applied
  there.
</p>

<h2>6. Limits of this limitation</h2>

<p>Nothing above excludes or limits the supplier's liability:</p>

<ul>
  <li>for wilful misconduct or gross negligence, under Article 1229 of the Italian Civil Code;</li>
  <li>for death or personal injury caused by its conduct;</li>
  <li>in cases where the law, and in particular consumer protection law, admits no exclusion or
    limitation;</li>
  <li>for the statutory guarantee of conformity owed to consumers.</li>
</ul>

<p>
  Should any clause on this page be void or ineffective, the remaining clauses retain full
  effect.
</p>

<h2>7. Contact</h2>

<p>
  For any clarification: <a href="mailto:{email}">{email}</a> — {denominazione}, {indirizzo},
  {cap} {citta} ({provincia}).
</p>
HTML,

];
