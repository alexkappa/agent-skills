import { request } from "../lib/http";

export interface Payment {
  id: string;
  invoiceId: string;
  amountCents: number;
}

export class PaymentsClient {
  retrieveAll(): Promise<Payment[]> {
    return request<Payment[]>("/payments");
  }

  retrieveOne(id: string): Promise<Payment> {
    return request<Payment>(`/payments/${id}`);
  }
}
