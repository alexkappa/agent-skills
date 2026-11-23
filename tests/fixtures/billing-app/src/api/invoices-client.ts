import { request } from "../lib/http";

export interface Invoice {
  id: string;
  userId: string;
  totalCents: number;
}

export class InvoicesClient {
  fetchAll(): Promise<Invoice[]> {
    return request<Invoice[]>("/invoices");
  }

  fetchOne(id: string): Promise<Invoice> {
    return request<Invoice>(`/invoices/${id}`);
  }
}
