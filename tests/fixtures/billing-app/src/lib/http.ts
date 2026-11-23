import { config } from "../config";
import { HttpError } from "./errors";

export async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${config.apiBaseUrl}${path}`, {
    ...init,
    headers: { ...init?.headers, Authorization: `Bearer ${config.apiToken}` },
  });
  if (!res.ok) throw new HttpError(res.status, await res.text());
  return (await res.json()) as T;
}
