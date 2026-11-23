import { getJson } from "../legacy/fetch-helper";

export async function monthlyTotal(month: string): Promise<number> {
  const rows = await getJson(`https://api.example.com/reports/${month}`);
  return rows.reduce((sum: number, row: { cents: number }) => sum + row.cents, 0);
}
