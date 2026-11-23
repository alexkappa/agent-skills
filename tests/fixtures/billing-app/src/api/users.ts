import { request } from "../lib/http";

export interface User {
  id: string;
  name: string;
}

// Task 3 from the plan: fetch users before invoices
export function listUsers(): Promise<User[]> {
  return request<User[]>("/users");
}
