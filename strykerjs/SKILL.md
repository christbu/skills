---
name: strykerjs
description: >
  Mutation testing for JavaScript and TypeScript projects using StrykerJS. Use when setting up
  mutation testing, running `stryker run`, interpreting surviving mutants, improving test quality,
  configuring stryker.config.mjs, or analysing mutation scores. Also covers the AI-agent manual
  mutation testing fallback for stacks StrykerJS does not support (e.g. Vitest browser mode).
  Triggers: "mutation testing", "stryker", "surviving mutants", "mutation score",
  "are my tests good enough", "test effectiveness", "would tests catch this bug".
---

# StrykerJS – Mutation Testing

Mutation testing answers: **"Would my tests catch this bug?"** by introducing small code changes
(mutants) and checking whether the test suite detects them.

- **Killed** – tests failed → good, tests caught the bug
- **Survived** – tests passed → gap, the bug would ship undetected
- **No coverage** – no test even ran this code
- **Timeout** – counts as detected (infinite loop introduced)

**Mutation score** = (Killed + Timeout) / Total × 100

> ⚠️ **Målet er ikke 100 % – målet er å drepe de kritiske mutantene.** En høy overordnet score med mange drepte LAV-prioritets-mutanter er mindre verdifull enn en lavere score der alle HØY-prioritets-mutanter er drept. Fokuser alltid på kritikalitet, ikke score.

| Score | Tolkning |
|-------|---------|
| < 60 % | Undersøk – kan indikere store gap i kritisk logikk |
| 60–80 % | Akseptabelt hvis alle HØY-prioritets-mutanter er drept |
| 80–90 % | Godt – men vurder om økt score faktisk gir verdi |
| > 90 % | Ikke nødvendigvis bedre – sjekk at testene tester noe meningsfylt |

---

## Hva er verdt å teste?

Mutasjonstesting skal avdekke **blokkerende bugs** – feil som hindrer brukeren fra å fullføre en oppgave eller som viser feil data. Still alltid spørsmålet: *Ville en bruker merket dette som et problem?*

| Blokkerende – test disse | Ikke-blokkerende – generer ikke mutanter |
|---|---|
| Betingelse som skjuler kritisk innhold | CSS-klasser og Tailwind-varianter |
| Valideringslogikk | Tekst og oversettelsesnøkler |
| API-kallhåndtering og feilhåndtering | Template-literals i JSX |
| Tilgangskontroll og rollelogikk | Ikonvarianter og farger |
| Datafiltrering og -transformasjon | Layout-forskjeller |
| Navigasjonslogikk | |

> Feil CSS-klasse er irriterende, men brukeren kan fortsatt fullføre oppgaven. Det er ikke dette mutasjonstesting skal fange.

---

## Kritikalitetsvurdering – prioriter rett

Stil dette spørsmålet for **hvert overlevende mutant** før du bestemmer om det krever en test:

```
1. Kan brukeren fullføre oppgaven sin hvis denne buggen slipper gjennom?
   → Nei: HØY prioritet – skriv test

2. Ser brukeren feil data eller manglende kritisk informasjon?
   → Ja: HØY prioritet – skriv test

3. Er dette styling, layout, tekst, ikonvarianter eller farger?
   → Ja: LAV prioritet – avvis, skriv IKKE test
   → Nei: MEDIUM prioritet – vurder nytten
```

### Eksempler – HØY prioritet (test alltid)

| Kode | Mutasjon | Konsekvens |
|------|----------|------------|
| `isAuthenticated && <Side />` | `!isAuthenticated` | Brukere uten tilgang ser siden |
| `status === 'AKTIV'` | `status !== 'AKTIV'` | Filter returnerer feil datasett |
| `await lagreSak(data)` | *fjernet* | Lagring skjer aldri – taus feil |
| `if (harFeil) return` | `if (!harFeil) return` | Feilhåndtering invertert |
| `rolle === 'DOMMER'` | `rolle !== 'DOMMER'` | Tilgangskontroll brytes |
| `items.filter(aktiv)` | *filter fjernet* | Alle items vises, inkl. inaktive |

### Eksempler – LAV prioritet (ignorer)

| Kode | Mutasjon | Konsekvens |
|------|----------|------------|
| `className="text-red-500"` | `""` | Annen farge – brukeren fullfører fortsatt |
| `<PlusIcon />` | *fjernet* | Ikon mangler – funksjonalitet intakt |
| `"Lagre og fortsett"` | `""` | Knapp-tekst tom – ikke en logikkfeil |
| `gap-4` i layout | `gap-0` | Layoutforskjell – ikke en blokkerende bug |

> **Tommelfingerregel:** Hvis en designkritikk er riktig tilbakemelding, er det ikke en mutasjonstestfeil.

### Aldri gjør dette

```ts
// ❌ Ikke legg Stryker-kommentarer i prodkode
return age >= 18; // Stryker disable next-line
```

```js
// ❌ Ikke ekskluder enkeltfiler via mutate-glob
mutate: ['!src/components/ThinWrapper.tsx']
```

Bruk heller `excludedMutations` i konfigurasjonen (se under) for å fjerne støy-mutantkategorier globalt.

---

## Velg tilnærming

**StrykerJS støtter stacken?** (Jest, Vitest Node-modus, Mocha, Jasmine, Karma, Angular)
→ Bruk [StrykerJS-arbeidsflyt](#strykerjs-arbeidsflyt) nedenfor.

**StrykerJS støtter ikke stacken?** (Vitest browser-modus, Playwright component tests, etc.)
→ Les [references/ai-agent-fallback.md](references/ai-agent-fallback.md) for manuell AI-agent-tilnærming.

---

## StrykerJS-arbeidsflyt

### 1. Installer

```bash
npm init stryker@latest
# eller med pnpm/yarn:
pnpm dlx stryker@latest init
```

Stryker initialiserer interaktivt og oppretter `stryker.config.mjs`.

### 2. Minimaloppsett (`stryker.config.mjs`)

```js
// @ts-check
/** @type {import('@stryker-mutator/api/core').PartialStrykerOptions} */
const config = {
  testRunner: 'vitest',           // jest | mocha | jasmine | karma | vitest
  coverageAnalysis: 'perTest',    // anbefalt: raskeste kjøring
  checkers: ['typescript'],       // forkast type-ugyldige mutanter tidlig
  excludedMutations: [
    'StringLiteral',              // CSS-klasser, tekst, oversettelsesnøkler
    'TemplateLiteral',            // template-strings i JSX
  ],
  mutate: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.test.{ts,tsx}',
    '!src/**/*.spec.{ts,tsx}',
  ],
  thresholds: { high: 80, low: 60, break: 0 }, // ikke bryt CI på lav score – fokuser på kritiske mutanter
};
export default config;
```

> ⚠️ `StringLiteral`-ekskluderingen stopper mutasjon av **alle** strenger – inkludert API-stier og forretningskritiske strenger. Hold slike strenger i egne `.ts`-filer (ikke inline i `.tsx`-komponentfiler) for å sikre at de testes separat.

Nyttige tilvalg:

| Alternativ | Beskrivelse |
|-----------|-------------|
| `mutate` | Glob-mønster for filer som skal muteres (ekskluder testfiler) |
| `coverageAnalysis` | `perTest` (standard, rask) / `all` / `off` |
| `checkers: ['typescript']` | Forkast type-ugyldige mutanter tidlig – reduserer støy |
| `excludedMutations` | Ekskluder mutantkategorier globalt (se under) |
| `thresholds` | `{ high: 80, low: 60, break: 60 }` – stopp CI under grense |
| `concurrency` | Antall parallelle workers (standard: cpu-1) |
| `timeoutMS` | Millisekunder før en mutant tidsavbrytes (standard: 5000) |

### 3. Kjør

```bash
npx stryker run
# kun spesifikke filer:
npx stryker run --mutate "src/utils/validation.ts"
# med sporingslogg ved problemer:
npx stryker run --logLevel trace
```

Stryker genererer også en interaktiv HTML-rapport i `reports/mutation/mutation.html`.

### 4. Tolk resultater

```
--------------|---------|----------|----------|----------|
File          | % score | # killed | # survived | # no cov |
--------------|---------|----------|----------|----------|
validation.ts |   82.6  |       19 |          3 |        1 |
utils.ts      |  100.0  |       12 |          0 |        0 |
```

Åpne HTML-rapporten for å se nøyaktig hvilken kodeendring som overlevde.

### 4b. Klassifiser overlevende mutanter etter kritikalitet

Før du skriver noen tester: gå gjennom listen med overlevende mutanter og sorter dem:

```
HØY  – logikk, tilgangskontroll, datafiltrering, feilhåndtering → test disse
MED  – beregninger og transformasjoner med begrenset konsekvens → vurder
LAV  – CSS, tekst, layout, ikoner, farger → avvis, skriv ikke test
```

Eksempel på klassifisert liste:
```
[HØY]  linje 42  rolle === 'ADMIN' → rolle !== 'ADMIN'   (tilgangskontroll)
[HØY]  linje 78  filter(aktiv) fjernet                   (vis alle items)
[MED]  linje 91  items.length > 0 → items.length >= 0    (tom-sjekk)
[LAV]  linje 15  "text-red-500" → ""                     (CSS-klasse)
[LAV]  linje 31  "Lagre" → ""                            (knapp-tekst)
```

**Regel:** Skriv kun tester for HØY og eventuelt MED. LAV-prioritets mutanter lukkes uten handling. Når alle HØY-prioritets-mutanter er drept, er jobben gjort – uavhengig av total mutation score.

### 5. Fiks overlevende mutanter

For hvert overlevende mutant med **HØY** eller **MED** prioritet:

1. **Identifiser** hva som ble mutert (se HTML-rapport eller terminalutskrift)
2. **Forstå** hvorfor testen ikke fanget det – testet den resultatet? Grenseverdien?
3. **Legg til** en presis test som ville ha mislyktes med mutasjonen

**Eksempel – grenseverdimutasjon overlevde:**
```ts
// Original: src/validation.ts:15
return age >= 18 && age <= 120;

// Mutasjon: >= → >  (overlevde!)
return age > 18 && age <= 120;
```
```ts
// Fiks – legg til grenseverditest:
it('godtar nøyaktig 18 år', () => {
  expect(isValidAge(18)).toBe(true); // ville feilet med > 18
});
```

**Eksempel – logisk operator overlevde:**
```ts
// Mutasjon: && → ||  (overlevde!)
return age >= 18 || age <= 120;
```
```ts
// Fiks – test med kun én betingelse oppfylt:
it('avviser alder under 18', () => {
  expect(isValidAge(15)).toBe(false); // ville bestått med ||
});
```

### 6. CI-integrasjon

```js
// stryker.config.mjs
const config = {
  // ...
  thresholds: { high: 80, low: 60, break: 0 }, // ikke bryt CI på lav score – fokuser på kritiske mutanter
  reporters: ['html', 'clear-text', 'progress', 'dashboard'],
};
```

```yaml
# GitHub Actions eksempel
- name: Mutation testing
  run: npx stryker run
```

---

## Tynn UI-komponent – hva du ikke trenger å teste

En **tynn komponent** kjennetegnes av:
- All logikk er delegert til en hook
- Filen inneholder kun JSX, `className`-strenger og prop-drilling
- Ingen beregnet tilstand – betingelser er direkte basert på props

Med `StringLiteral`- og `TemplateLiteral`-ekskludering genererer tynne komponenter **null eller svært få mutanter**. Stryker fokuserer naturlig på koden som faktisk inneholder logikk.

**Tynn komponent – Stryker genererer 0 mutanter etter ekskludering:**
```tsx
// tag.tsx – kun cva()-varianter og JSX, ingen logikk
export function SakstypeTag({ children, type }: ...) {
  return (
    <span className="inline-flex">
      <span className={tagVariants({ type })}>{children}</span>
    </span>
  );
}
```

**Komponent med logikk – disse mutantene ER kritiske:**
```tsx
// sak-icons.tsx – conditional rendering basert på data
// Feil betingelse → bruker ser ikke viktig informasjon
{siktedeTiltalteErUnder18 && <Tooltip>...</Tooltip>}
{prioritet === "VIKTIG" && <Tooltip>...</Tooltip>}
```

> **Arkitekturprinsipp:** Skill mellom logikk og presentasjon. Flytt betingelser, beregninger og datahenting til hooks – da vil komponenten naturlig bli tynn og stryker fokuserer på rett sted.

| Flytt til hook | Beholdes i komponent |
|---|---|
| `if`-betingelser basert på data | JSX-struktur |
| `filter()`, `map()`, `sort()` | `className`-sammensetning |
| API-kall og feilhåndtering | Prop-drilling |
| Tilstandslogikk | Tekst og labels |

---

## Vanlige mutasjonsoperatorer

Se [references/mutators.md](references/mutators.md) for fullstendig liste over alle StrykerJS-mutasjonsoperatorer med eksempler.

De viktigste å kjenne til:

| Kategori | Eksempel |
|----------|---------|
| Grenseverdi | `<` → `<=`, `>=` → `>` |
| Logisk operator | `&&` → `\|\|`, `\|\|` → `&&` |
| Aritmetikk | `+` → `-`, `*` → `/` |
| Betingelse | `if (cond)` → `if (true)` / `if (false)` |
| Blokk-sletting | Fjerner hele funksjonsblokken |
| Metodeuttrykk | `filter()` fjernet, `some()` → `every()` |

---

## Feilsøking

| Problem | Løsning |
|---------|---------|
| `No tests found` | Sjekk `mutate`-glob og testrunner-konfig |
| Svært treg kjøring | Aktiver `coverageAnalysis: 'perTest'`, øk `concurrency` |
| Type-feil i mutanter | Legg til `checkers: ['typescript']` for å forkaste disse |
| Mange CSS/tekst-mutanter | Legg til `excludedMutations: ['StringLiteral', 'TemplateLiteral']` |
| Stryker støtter ikke stacken | Les [references/ai-agent-fallback.md](references/ai-agent-fallback.md) |
