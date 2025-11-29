CREATE TABLE IF NOT EXISTS katalog_produktow(
    ID_Produktu INTEGER NOT NULL,
    Nazwa_Produktu TEXT,
    Cena_Katalogowa DOUBLE PRECISION,
    Kategoria_Produktu TEXT
);

COPY katalog_produktow
FROM 'C:\Program Files\PostgreSQL\17\data\Dane\katalog_produktow.csv'
CSV HEADER;

CREATE TABLE IF NOT EXISTS raport_kwartalny_sprzedaz(
    Data_Transakcji DATE,
    ID_Produktu_Sprzedaz INTEGER NOT NULL,
    Region TEXT,
    Ilosc_Sprzedana SMALLINT,
    Cena_Jednostkowa_Transakcji DECIMAL,
    Wartosc_Sprzedazy DECIMAL
);

COPY raport_kwartalny_sprzedaz
FROM 'C:\Program Files\PostgreSQL\17\data\Dane\raport_kwartalny_sprzedaz.csv'
CSV HEADER;

/* 1. Połącz dane sprzedażowe z katalogiem produktów. Ile unikalnych transakcji z pliku
   raport_kwartalny_sprzedaz.csv nie ma swojego odpowiednika w katalog_produktow.csv na
   podstawie kolumn ID produktu?
 */

SELECT
    katalog_produktow.ID_Produktu,
    COUNT(*) AS Ilosc
FROM katalog_produktow
RIGHT OUTER JOIN raport_kwartalny_sprzedaz
    ON katalog_produktow.ID_Produktu = raport_kwartalny_sprzedaz.ID_Produktu_Sprzedaz
GROUP BY katalog_produktow.ID_Produktu
HAVING katalog_produktow.ID_Produktu IS NULL;


/* 2. Jaka jest całkowita wartość sprzedaży w całym raporcie
   (Wartosc_Sprzedazy z pliku raport_kwartalny_sprzedaz.csv),
   uwzględniając tylko te transakcje, dla których udało się
   znaleźć odpowiednik produktu w katalogu?
 */

SELECT
    ROUND(SUM(raport_kwartalny_sprzedaz.Wartosc_Sprzedazy), 2) as Calkowia_wartosc_sprzedazy
FROM katalog_produktow
RIGHT OUTER JOIN raport_kwartalny_sprzedaz
    ON katalog_produktow.ID_Produktu = raport_kwartalny_sprzedaz.ID_Produktu_Sprzedaz
 WHERE katalog_produktow.ID_Produktu IS NOT NULL;

/* 3a,b. Jaka jest "Nazwa_Produktu" (z katalogu), dla której średnia Cena_Jednostkowa_Transakcji
   (z raportu sprzedaży) najbardziej różni się procentowo od Cena_Katalogowa (z katalogu)?
 */

SELECT
    katalog_produktow.ID_Produktu,
    katalog_produktow.Nazwa_Produktu,
    ((ABS(AVG(raport_kwartalny_sprzedaz.Cena_Jednostkowa_Transakcji) - katalog_produktow.Cena_Katalogowa)) / AVG(raport_kwartalny_sprzedaz.Cena_Jednostkowa_Transakcji) * 100) as procentowa_roznica
FROM katalog_produktow
INNER JOIN raport_kwartalny_sprzedaz
    ON katalog_produktow.ID_Produktu = raport_kwartalny_sprzedaz.ID_Produktu_Sprzedaz
GROUP BY katalog_produktow.ID_Produktu, katalog_produktow.Nazwa_Produktu, katalog_produktow.Cena_Katalogowa
ORDER BY procentowa_roznica DESC;

/* 4. Ile wierszy w raporcie sprzedaży ma niezgodność między Wartosc_Sprzedazy
   a iloczynem Ilosc_Sprzedana * Cena_Jednostkowa_Transakcji?
 */

SELECT
    COUNT(*) AS Ilosc_niezgodnosci
FROM raport_kwartalny_sprzedaz
WHERE raport_kwartalny_sprzedaz.Wartosc_Sprzedazy !=
       (raport_kwartalny_sprzedaz.Ilosc_Sprzedana * raport_kwartalny_sprzedaz.Cena_Jednostkowa_Transakcji)

/* 5. W przypadku wykrytych niezgodności w pytaniu 4, która z dwóch wartości (A: Wartosc_Sprzedazy z
   pliku sprzedażowego, czy B: wynik Ilosc_Sprzedana * Cena_Jednostkowa_Transakcji wyliczona przez Ciebie)
   wydaje Ci się bardziej wiarygodna do raportowania?
 */

 /* ODP. B ponieważ wyliczona w ten sposob wartość sprzedaży nie będzie obarczona błędem. Wartość ta będzie wynikiem
    z działania mnożenia ilości przez wartość jednostkową. Wpisując Wartość sprzedaży "z palca" narażamy się
    na popełnienie błedu, co może skutkować np. błędnym wyliczeniem wartości całkowitej sprzedaży. Wtedy pojawia się
    rozbieżność wartości sprzedaży, która była wynikiem obliczeń i analiz ze środkami pieniężnymi księgowanymi na koncie
    bankowym fimry jako przychód ze sprzedaży.
  */


