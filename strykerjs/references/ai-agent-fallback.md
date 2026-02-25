# AI-agent manuell mutasjonstesting

Bruk denne tilnærmingen når StrykerJS **ikke støtter stacken din**, f.eks.:
- Vitest browser-modus (`browser.enabled: true`)
- Playwright component tests
- Custom testoppsett der Stryker ikke kan instrumentere koden

> Kilde/inspirasjon: [alexop.dev – Mutation Testing with AI Agents](https://alexop.dev/posts/mutation-testing-ai-agents-vitest-browser-mode/)
> og [Paul Hammond's opprinnelige skill](https://github.com/citypaul/.dotfiles/blob/main/claude/.claude/skills/mutation-testing/SKILL.md)

---

## Arbeidsflyt

Agenten utfører mutasjonstesting manuelt ved å følge denne flyten for hver mutasjon:

1. Les kildefilen og noter eksakt innhold
2. Appliser én mutasjon (rediger koden)
3. Kjør testsuiten: `pnpm test --run` (eller relevant kommando)
4. Registrer resultat: **DREPT** (test feilet) eller **OVERLEVDE** (test bestod)
5. Gjenopprett original kode umiddelbart
6. Gjenta for neste mutasjon

### Finn filer å mutere

```bash
# Endrede filer på branchen (fokuser på disse):
git diff main...HEAD --name-only | grep -E '\.(ts|js|tsx|jsx|vue)' | grep -v '\.test\.' | grep -v '\.spec\.'
```

---

## Mutasjonsoperatorer (prioritert rekkefølge)

### Prioritet 1 – Grenseverdier (overlever oftest)

| Original  | Mutasjon   |
|-----------|-----------|
| `<`       | `<=`      |
| `>`       | `>=`      |
| `<=`      | `<`       |
| `>=`      | `>`       |

### Prioritet 2 – Boolsk logikk

| Original      | Mutasjon       |
|---------------|---------------|
| `&&`          | `\|\|`        |
| `\|\|`        | `&&`          |
| `!betingelse` | `betingelse`  |

### Prioritet 3 – Returverdier

| Original           | Mutasjon          |
|--------------------|-------------------|
| `return x`         | `return null`     |
| `return true`      | `return false`    |
| `if (cond) return` | *fjern early exit* |

### Prioritet 4 – Aritmetikk

| Original | Mutasjon |
|----------|---------|
| `+`      | `-`     |
| `-`      | `+`     |
| `*`      | `/`     |

### Prioritet 5 – Fjern setninger

| Original              | Mutasjon  |
|-----------------------|----------|
| `array.push(x)`       | *fjernet* |
| `await save(x)`       | *fjernet* |
| `emit('hendelse')`    | *fjernet* |

---

## Viktige regler

1. **Gjenopprett alltid original kode** etter hver mutasjon
2. **Kjør tester umiddelbart** etter å ha applisert mutasjonen
3. **Én mutasjon om gangen** – ikke kombiner
4. **Fokuser på endret kode** – prioriter branch diff
5. **Vurder kritikalitet** – ikke alle overlevende mutanter krever en test (se under)

---

## Eksempel på kjøring

**Original kode** (`src/utils/validation.ts:15`):
```ts
export function isValidAge(age: number): boolean {
  return age >= 18 && age <= 120;
}
```

**Mutasjon 1** – Endre `>=` til `>`:
```ts
return age > 18 && age <= 120; // MUTERT
```
Kjør: `pnpm test --run`  
Resultat: Tester bestod → **OVERLEVDE** (trenger grenseverditest for `isValidAge(18)`)

**Gjenopprett original kode umiddelbart**

**Mutasjon 2** – Endre `&&` til `||`:
```ts
return age >= 18 || age <= 120; // MUTERT
```
Kjør: `pnpm test --run`  
Resultat: Tester feilet → **DREPT** ✓

---

## Rapportmal

Etter fullført mutasjonstesting, lever denne oppsummeringen:

```
## Mutasjonstestresultater

**Mål**: `src/features/innstillinger/utils.ts`
**Totale mutasjoner**: 13
**Drept**: 5
**Overlevde**: 8
**Score**: 38 %

### Overlevende mutanter – HØY prioritet (krever test)

| # | Plassering | Original | Mutert | Foreslått test |
|---|------------|----------|--------|----------------|
| 1 | linje 65   | `>= 0.5` | `> 0.4` | Test grenseverdi 0.5 |
| 2 | linje 28   | `if (error) return` | `if (!error) return` | Test feilhåndteringsvei |

### Overlevende mutanter – LAV prioritet (ingen handling)

| # | Plassering | Original | Mutert | Begrunnelse |
|---|------------|----------|--------|-------------|
| 3 | linje 26   | `=== 'dark'` | `!== 'dark'` | CSS-tema, ikke blokkerende |

### Drepte mutanter (tester er effektive)

- Linje 35: `+` → `-` drept av `calculation.test.ts`
- Linje 48: `true` → `false` drept av `validate.test.ts`
```

---

## Vanlige testsvakheter som avdekkes

### Kun happy path testes
```ts
// Svakt – bare suksesstilfelle
it('validerer', () => expect(validate(goodInput)).toBe(true));

// Sterkt – begge tilfeller
it('godtar gyldig input', () => expect(validate(goodInput)).toBe(true));
it('avviser ugyldig input', () => expect(validate(badInput)).toBe(false));
```

### Identitetsverdier i tester
```ts
// Svakt – mutasjon * → / overlever
expect(multiply(5, 1)).toBe(5);

// Sterkt – mutasjon oppdages
expect(multiply(5, 3)).toBe(15);
```

### Returverdi sjekkes ikke
```ts
// Svakt
it('prosesserer', () => { process(data); }); // ingen påstand!

// Sterkt
it('prosesserer', () => {
  const result = process(data);
  expect(result).toEqual(expected);
});
```

### Sideeffekter verifiseres ikke
```ts
// Svakt – emit kan fjernes uten at testen feiler
it('sender hendelse', () => { doAction(); });

// Sterkt
it('sender hendelse', () => {
  doAction();
  expect(emit).toHaveBeenCalledWith('hendelse');
});
```
