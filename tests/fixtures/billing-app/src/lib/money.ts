export type Currency = "USD" | "EUR" | "GBP";

export interface Money {
  cents: number;
  currency: Currency;
}

const SYMBOLS: Record<Currency, string> = { USD: "$", EUR: "€", GBP: "£" };

export function parseMoney(text: string, currency: Currency): Money {
  const [whole, fraction = ""] = text.replace(/[^0-9.]/g, "").split(".");
  const cents = Number(whole) * 100 + Number(fraction.padEnd(2, "0").slice(0, 2));
  return { cents, currency };
}

export function formatMoney(money: Money): string {
  const units = (money.cents / 100).toFixed(2);
  return `${SYMBOLS[money.currency]}${units}`;
}

export function addMoney(a: Money, b: Money): Money {
  if (a.currency !== b.currency) throw new Error("Currency mismatch");
  return { cents: a.cents + b.cents, currency: a.currency };
}
