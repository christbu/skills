# StrykerJS – Mutasjonsoperatorer

Fullstendig liste over mutasjonsoperatorer støttet av StrykerJS.

## Innholdsfortegnelse

1. [Aritmetiske operatorer](#aritmetiske-operatorer)
2. [Arraydeklasjoner](#arraydeklasjoner)
3. [Blokk-sletting](#blokk-sletting)
4. [Boolske literaler](#boolske-literaler)
5. [Betingede uttrykk](#betingede-uttrykk)
6. [Likhetsoperatorer](#likhetsoperatorer)
7. [Logiske operatorer](#logiske-operatorer)
8. [Metodeuttrykk](#metodeuttrykk)
9. [Objektliteraler](#objektliteraler)
10. [Valgfri kjeding](#valgfri-kjeding)
11. [Regulære uttrykk](#regulære-uttrykk)
12. [Strengliteraler](#strengliteraler)
13. [Unære operatorer](#unære-operatorer)
14. [Oppdateringsoperatorer](#oppdateringsoperatorer)

---

## Aritmetiske operatorer

| Original | Mutert til |
|----------|-----------|
| `a + b`  | `a - b`   |
| `a - b`  | `a + b`   |
| `a * b`  | `a / b`   |
| `a / b`  | `a * b`   |
| `a % b`  | `a * b`   |

> **Tip:** Unngå tester som bruker identitetsverdier (f.eks. `multiply(5, 1)`) – disse overlever `* → /`-mutasjoner.

---

## Arraydeklasjoner

| Original            | Mutert til    |
|---------------------|---------------|
| `new Array(1, 2, 3)` | `new Array()` |
| `[1, 2, 3]`         | `[]`          |

---

## Blokk-sletting

Fjerner hele innholdet i en funksjonsblokk:

```ts
// Original
function doSomething() {
  console.log('Hei');
}

// Mutert
function doSomething() {}
```

Dette er en av de sterkeste mutasjonene – overlever den betyr at funksjonens sideeffekter aldri verifiseres.

---

## Boolske literaler

| Original      | Mutert til    |
|---------------|---------------|
| `true`        | `false`       |
| `false`       | `true`        |
| `!(a == b)`   | `a == b`      |

---

## Betingede uttrykk

| Original               | Mutert til             |
|------------------------|------------------------|
| `if (a > b)`           | `if (true)`            |
| `if (a > b)`           | `if (false)`           |
| `while (a > b)`        | `while (false)`        |
| `for (...; i < 10; ...)` | `for (...; false; ...)` |
| `a > b ? 1 : 2`        | `true ? 1 : 2`         |
| `a > b ? 1 : 2`        | `false ? 1 : 2`        |

---

## Likhetsoperatorer

| Original  | Mutert til (grenseverdi) | Mutert til (negasjon) |
|-----------|--------------------------|-----------------------|
| `a < b`   | `a <= b`                 | `a >= b`              |
| `a <= b`  | `a < b`                  | `a > b`               |
| `a > b`   | `a >= b`                 | `a <= b`              |
| `a >= b`  | `a > b`                  | `a < b`               |
| `a == b`  | –                        | `a != b`              |
| `a != b`  | –                        | `a == b`              |
| `a === b` | –                        | `a !== b`             |
| `a !== b` | –                        | `a === b`             |

> **Grenseverdimutasjoner** (`<` → `<=`) overlever oftest. Sørg for tester med eksakte grenseverdier.

---

## Logiske operatorer

| Original  | Mutert til |
|-----------|-----------|
| `a && b`  | `a \|\| b` |
| `a \|\| b` | `a && b`  |
| `a ?? b`  | `a && b`  |

---

## Metodeuttrykk

| Original          | Mutert til        |
|-------------------|-------------------|
| `endsWith()`      | `startsWith()`    |
| `startsWith()`    | `endsWith()`      |
| `trim()`          | `trimEnd()`       |
| `trimEnd()`       | `trimStart()`     |
| `trimStart()`     | `trimEnd()`       |
| `toUpperCase()`   | `toLowerCase()`   |
| `toLowerCase()`   | `toUpperCase()`   |
| `some()`          | `every()`         |
| `every()`         | `some()`          |
| `min()`           | `max()`           |
| `max()`           | `min()`           |
| `filter()`        | *fjernet*         |
| `sort()`          | *fjernet*         |
| `reverse()`       | *fjernet*         |
| `slice()`         | *fjernet*         |
| `charAt()`        | *fjernet*         |
| `substr()`        | *fjernet*         |
| `substring()`     | *fjernet*         |

---

## Objektliteraler

| Original            | Mutert til |
|---------------------|------------|
| `{ foo: 'bar' }`    | `{}`       |

---

## Valgfri kjeding (StrykerJS-spesifikk)

| Original     | Mutert til  |
|--------------|-------------|
| `foo?.bar`   | `foo.bar`   |
| `foo?.[1]`   | `foo[1]`    |
| `foo?.()`    | `foo()`     |

---

## Regulære uttrykk

Stryker muterer regex automatisk via [weapon-regex](https://github.com/stryker-mutator/weapon-regex):

| Original   | Mutert til  |
|------------|-------------|
| `^abc`     | `abc`       |
| `abc$`     | `abc`       |
| `[abc]`    | `[^abc]`    |
| `[^abc]`   | `[abc]`     |
| `\d`       | `\D`        |
| `\s`       | `\S`        |
| `\w`       | `\W`        |
| `a?`       | `a`         |
| `a*`       | `a`         |
| `a+`       | `a`         |
| `(?=abc)`  | `(?!abc)`   |

---

## Strengliteraler

| Original            | Mutert til           |
|---------------------|----------------------|
| `"foo"` (ikke-tom)  | `""`                 |
| `""` (tom)          | `"Stryker was here!"` |
| `` `foo ${bar}` ``  | ` `` `               |

---

## Unære operatorer

| Original | Mutert til |
|----------|-----------|
| `+a`     | `-a`      |
| `-a`     | `+a`      |

---

## Oppdateringsoperatorer

| Original | Mutert til |
|----------|-----------|
| `a++`    | `a--`     |
| `a--`    | `a++`     |
| `++a`    | `--a`     |
| `--a`    | `++a`     |
