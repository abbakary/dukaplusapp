/// Terms of Service content — EN / SW (mirrors web `termsOfService.ts`).

class TermsSection {
  final String id;
  final String titleEn;
  final String titleSw;
  final List<String> bodyEn;
  final List<String> bodySw;
  final bool highlight;

  const TermsSection({
    required this.id,
    required this.titleEn,
    required this.titleSw,
    required this.bodyEn,
    required this.bodySw,
    this.highlight = false,
  });

  String title(bool isSw) => isSw ? titleSw : titleEn;
  List<String> body(bool isSw) => isSw ? bodySw : bodyEn;
}

const termsLastUpdated = '2026-09-01';

const termsSections = <TermsSection>[
  TermsSection(
    id: 'intro',
    titleEn: 'Welcome to DukaMkononi',
    titleSw: 'Karibu DukaMkononi',
    bodyEn: [
      'These Terms of Service govern your use of the DukaMkononi cloud ERP platform operated by the Duka+ provider. By creating an account, you agree to these Terms.',
      'DukaMkononi helps Tanzanian businesses manage POS, inventory, customers, reports, and TRA-aligned receipt workflows. Ultimate TRA compliance remains your responsibility.',
    ],
    bodySw: [
      'Masharti haya yanasimamia matumizi yako ya jukwaa la DukaMkononi linaloendeshwa na mtoa huduma wa Duka+. Kwa kuunda akaunti, unakubali Masharti haya.',
      'DukaMkononi husaidia biashara za Tanzania kusimamia POS, stoo, wateja, ripoti, na risiti za TRA. Kufuata sheria za TRA bado ni wajibu wako.',
    ],
  ),
  TermsSection(
    id: 'tin',
    titleEn: 'TIN & Business Information',
    titleSw: 'TIN & Taarifa za Biashara',
    highlight: true,
    bodyEn: [
      'You must provide accurate TIN, business name, location, and licence details where applicable.',
      'You confirm you are authorised to register the business and that credentials belong to a legitimate entity.',
      'The Provider does not verify every TIN at registration and assumes you submit genuine information.',
    ],
    bodySw: [
      'Lazima utoe TIN sahihi, jina la biashara, mahali, na maelezo ya leseni inapohitajika.',
      'Unathibitisha una mamlaka ya kusajili biashara na kwamba nyaraka ni za chombo halali.',
      'Mtoa Huduma hahakiki kila TIN wakati wa usajili na anachukulia unawasilisha taarifa za kweli.',
    ],
  ),
  TermsSection(
    id: 'tra-efd',
    titleEn: 'TRA EFD & Fiscal Receipts',
    titleSw: 'TRA EFD & Risiti za Kodi',
    highlight: true,
    bodyEn: [
      'TRA EFD and VAT features assist common workflows but do not replace your legal obligation to register with TRA and file returns.',
      'You are solely responsible for correct tax settings, valid EFD serial numbers, and remitting VAT to TRA.',
      'The Provider is not a tax agent or TRA representative.',
    ],
    bodySw: [
      'Vipengele vya TRA EFD na VAT husaidia kazi za kawaida lakini havibadilishi wajibu wako wa kisheria wa kusajiliwa na TRA.',
      'Wewe pekee unawajibika kwa mipangilio sahihi ya kodi, namba za EFD, na kulipa VAT kwa TRA.',
      'Mtoa Huduma si wakala wa kodi wala mwakilishi wa TRA.',
    ],
  ),
  TermsSection(
    id: 'liability',
    titleEn: 'Client Responsibility',
    titleSw: 'Wajibu wa Mteja',
    highlight: true,
    bodyEn: [
      'You accept full responsibility for business data, tax declarations, TIN usage, and regulatory compliance.',
      'False or misleading TIN or licence information — you, not the Provider, bear all legal and financial consequences.',
      'The Provider may suspend accounts that appear fraudulent or misrepresent regulatory status.',
    ],
    bodySw: [
      'Unakubali wajibu kamili kwa data ya biashara, makaratasi ya kodi, matumizi ya TIN, na kufuata sheria.',
      'TIN au leseni za uongo — wewe, si Mtoa Huduma, unabeba matokeo yote ya kisheria na kifedha.',
      'Mtoa Huduma anaweza kusimamisha akaunti zinazoonekana za ulaghai au zisizo sahihi.',
    ],
  ),
  TermsSection(
    id: 'service',
    titleEn: 'Service & Billing',
    titleSw: 'Huduma & Malipo',
    bodyEn: [
      'Plans and pricing may change with notice. Continued use constitutes acceptance.',
      'We strive for availability but do not guarantee uninterrupted service.',
      'Terms may be updated on this page with a revised date.',
    ],
    bodySw: [
      'Mipango na bei vinaweza kubadilika kwa taarifa. Kuendelea kutumia ni kukubali.',
      'Tunajitahidi kuwa na upatikanaji lakini hatuhakikishi huduma isiyokatika.',
      'Masharti yanaweza kusasishwa kwenye ukurasa huu na tarehe mpya.',
    ],
  ),
];

String termsAcceptanceLabel(bool isSw) => isSw
    ? 'Nimesoma na nakubali Masharti ya Huduma, ikiwa ni pamoja na wajibu wangu wa TRA EFD na TIN.'
    : 'I have read and agree to the Terms of Service, including my TRA EFD and TIN responsibilities.';

String termsMustAcceptError(bool isSw) => isSw
    ? 'Lazima ukubali Masharti ya Huduma ili kuendelea.'
    : 'You must accept the Terms of Service to continue.';

String termsPageTitle(bool isSw) =>
    isSw ? 'Masharti ya Huduma' : 'Terms of Service';

String termsHeroSubtitle(bool isSw) => isSw
    ? 'Soma kuhusu TRA EFD, TIN, na wajibu wako. Mtoa huduma hatawajibika kwa taarifa za uongo.'
    : 'Read about TRA EFD, TIN, and your obligations. The provider is not liable for false information.';

String termsImportantReminder(bool isSw) => isSw
    ? 'Kwa kusajili, unathibitisha TIN na taarifa za TRA ni za kweli — wewe unawajibika kisheria, si DukaMkononi.'
    : 'By registering, you confirm TIN and TRA details are genuine — you are legally responsible, not DukaMkononi.';
