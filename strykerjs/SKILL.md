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

| Score | Quality |
|-------|---------|
| < 60 % | Svakt – store testgap |
| 60–80 % | Moderat – forbedring trengs |
| 80–90 % | Godt |
| > 90 % | Sterkt testsuite |

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
  mutate: [
    'src/**/*.ts',
    '!src/**/*.test.ts',
    '!src/**/*.spec.ts',
  ],
};
export default config;
```

Nyttige tilvalg:

| Alternativ | Beskrivelse |
|-----------|-------------|
| `mutate` | Glob-mønster for filer som skal muteres (ekskluder testfiler) |
| `coverageAnalysis` | `perTest` (standard, rask) / `all` / `off` |
| `checkers: ['typescript']` | Forkast type-ugyldige mutanter tidlig |
| `thresholds` | `{ high: 90, low: 70, break: 60 }` – stopp CI under grense |
| `ignorePatterns` | Filer/mapper å ignorere (som `.gitignore`) |
| `concurrency` | Antall parallelle workers (standard: cpu-1) |
| `timeoutMS` | Millisekunder før en mutant tidsavbrytes (standard: 5000) |
| `disableTypeChecks` | `true` for raskere kjøring uten TypeScript-sjekk |

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

### 5. Fiks overlevende mutanter

For hvert overlevende mutant:

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
  thresholds: { high: 90, low: 70, break: 60 }, // avslutt med feil under 60 %
  reporters: ['html', 'clear-text', 'progress', 'dashboard'],
};
```

```yaml
# GitHub Actions eksempel
- name: Mutation testing
  run: npx stryker run
```

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
| Stryker støtter ikke stacken | Les [references/ai-agent-fallback.md](references/ai-agent-fallback.md) |
